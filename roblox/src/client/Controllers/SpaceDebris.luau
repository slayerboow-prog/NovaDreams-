-- SpaceDebris (cliente): unas pocas rocas y escombros CERCA de la cámara en el espacio, para dar
-- profundidad como en la referencia del dueño (docs/espacio-aaa/referencia-espacio-v121.png: asteroides
-- en primer plano abajo a la izquierda y por delante de la nave).
--
--   * Solo se VEN: cada jugador las suyas, dentro de la cámara, sin choque, sin consultas, sin sombra.
--     No son asteroides del juego (ni se minan ni se rompen: eso sigue en World/SpaceWorld,
--     Controllers/AsteroidFx, sin tocar). Se montan con el MISMO constructor que los de verdad
--     (shared/Cosmos/AsteroidBuild, con las mallas de Blender si están cargadas) para que se parezcan.
--   * Pocas (Count: 6 en el móvil, 10 en el ordenador; 0 en gráficos Bajo) y pequeñas (Radius), entre
--     Near y Far studs de la cámara, más por delante y por abajo que detrás. Giran despacio y derivan;
--     la que queda detrás o lejos vuelve a salir por delante (sin crear piezas nuevas).
--   * Solo en la zona «Espacio» (Controllers/EnvDirector.inSpace); en Valmar, la transición, un planeta
--     o la arena, escondidas.
-- La parte pura (dónde sale cada una) la prueban scripts/test-espacio-aaa.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SpaceDebris = {}

SpaceDebris.Count = { Touch = 6, Pc = 10, Low = 0 }
SpaceDebris.Near = 70
SpaceDebris.Far = 320
SpaceDebris.Radius = { 2.5, 9 }
SpaceDebris.Every = 1 / 30

-- Un sitio para la roca número i (puro: lo mismo con la misma semilla). look = hacia dónde mira la
-- cámara. Devuelve la posición relativa a la cámara (más por delante y por abajo, nunca encima de la mira).
function SpaceDebris.spot(i: number, seed: number, look: Vector3): Vector3
	local r = Random.new(seed * 7919 + i * 104729)
	local up = Vector3.new(0, 1, 0)
	local f = if look.Magnitude > 1e-6 then look.Unit else Vector3.new(0, 0, -1)
	local right = f:Cross(up)
	right = if right.Magnitude > 1e-4 then right.Unit else Vector3.new(1, 0, 0)
	local u = right:Cross(f).Unit
	-- (delante, a un lado y algo abajo: fuera del centro de la pantalla, donde va la mira)
	local side = if r:NextNumber() < 0.5 then -1 else 1
	local ahead = r:NextNumber(0.35, 1)
	local lateral = side * r:NextNumber(0.45, 1.1)
	local vertical = r:NextNumber(-0.75, 0.3)
	local dir = (f * ahead + right * lateral + u * vertical).Unit
	local dist = r:NextNumber(SpaceDebris.Near, SpaceDebris.Far)
	return dir * dist
end

-- ¿Hay que volver a ponerla por delante? (detrás de la cámara o muy lejos)
function SpaceDebris.stale(rel: Vector3, look: Vector3): boolean
	local d = rel.Magnitude
	return d > SpaceDebris.Far * 1.4 or d < 12 or rel:Dot(look) < -20
end

-- Cuántas según el nivel gráfico y el aparato
function SpaceDebris.count(tier: string?, touch: boolean): number
	if tier == "Low" then
		return SpaceDebris.Count.Low
	end
	return if touch then SpaceDebris.Count.Touch else SpaceDebris.Count.Pc
end

type Rock = { Model: Model, Pos: Vector3, Spin: Vector3, Rot: CFrame, Drift: Vector3, Seed: number }
local rocks: { Rock } = {}
local folder: Folder? = nil
local shown = false
local reseed = 0

local function build(n: number)
	local AsteroidBuild = require(ReplicatedStorage.Shared.Cosmos.AsteroidBuild)
	local meshes = ReplicatedStorage:FindFirstChild("AsteroideMallas")
	local f = Instance.new("Folder")
	f.Name = "EscombrosCercanos"
	folder = f
	local r = Random.new(2024)
	for i = 1, n do
		local radius = r:NextNumber(SpaceDebris.Radius[1], SpaceDebris.Radius[2])
		local ok, model = pcall(AsteroidBuild.make, "Escombro" .. i, radius, nil, if i % 3 == 0 then "Brasa" else "Hierro", CFrame.new(), { Meshes = meshes })
		if ok and model then
			for _, d in (model :: Model):GetDescendants() do
				if d:IsA("BasePart") then
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
					d.CastShadow = false
				end
			end
			-- (de lejos, sin el detalle fino: son pequeñas)
			pcall(AsteroidBuild.setDetail, model, false)
			model.Name = "Escombro" .. i
			model.Parent = f
			table.insert(rocks, {
				Model = model,
				Pos = Vector3.zero,
				Spin = Vector3.new(r:NextNumber(-0.4, 0.4), r:NextNumber(-0.4, 0.4), r:NextNumber(-0.4, 0.4)), -- rad/s
				Rot = CFrame.Angles(r:NextNumber(0, 6.28), r:NextNumber(0, 6.28), 0),
				Drift = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-1, 1), r:NextNumber(-1, 1)) * 2.5,
				Seed = i,
			})
		end
	end
end

local function place(rock: Rock, cam: CFrame)
	reseed += 1
	rock.Seed = reseed
	rock.Pos = cam.Position + SpaceDebris.spot(rock.Seed, 31, cam.LookVector)
end

local function setShown(on: boolean, cam: CFrame?)
	if on == shown then
		return
	end
	shown = on
	local f = folder
	if not f then
		return
	end
	if on then
		f.Parent = workspace.CurrentCamera
		for _, rock in rocks do
			if cam then
				place(rock, cam)
			end
		end
	else
		f.Parent = nil
	end
end

local function inSpace(): boolean
	local ok, yes = pcall(function()
		return require(script.Parent.EnvDirector).inSpace()
	end)
	return ok and yes == true
end

function SpaceDebris.update(dt: number)
	local camera = workspace.CurrentCamera
	local player = Players.LocalPlayer
	if not camera or not player then
		return
	end
	local want = inSpace() and player:GetAttribute("AirCombatWorld") ~= "Arena"
	if want and not folder then
		local tier = player:GetAttribute("GraphicsTier")
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		local n = SpaceDebris.count(if type(tier) == "string" then tier else nil, touch)
		if n <= 0 then
			return
		end
		build(n)
	end
	setShown(want, camera.CFrame)
	if not shown then
		return
	end
	local cam = camera.CFrame
	for _, rock in rocks do
		rock.Pos += rock.Drift * dt
		rock.Rot = rock.Rot * CFrame.Angles(rock.Spin.X * dt, rock.Spin.Y * dt, rock.Spin.Z * dt)
		if SpaceDebris.stale(rock.Pos - cam.Position, cam.LookVector) then
			place(rock, cam)
		end
		rock.Model:PivotTo(CFrame.new(rock.Pos) * rock.Rot)
	end
end

function SpaceDebris.init()
	local since = 0
	RunService.RenderStepped:Connect(function(dt)
		since += dt
		if since < SpaceDebris.Every then
			return
		end
		local step = since
		since = 0
		local ok, err = pcall(SpaceDebris.update, step)
		if not ok then
			warn("[SpaceDebris] " .. tostring(err))
		end
	end)
end

return SpaceDebris
