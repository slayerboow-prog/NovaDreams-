-- SeaV4Fx (cliente, v4 — solo con Config.Sea.V4; docs/mar/v4-objetivo.md): lo que da «calidad» y vida al
-- estar bajo el agua, en tu pantalla:
--   * Viñeta: los bordes de la pantalla algo más oscuros (cuatro marcos con degradado: sin imagen subida),
--     más con la hondura.
--   * Color según la hondura: cerca de la superficie, un tinte turquesa claro y algo más de saturación; abajo,
--     más contraste y azul (un ColorCorrection propio, «MarV4Color», que se suma al de la zona).
--   * Nubecillas de arena: al nadar pegado al fondo (a menos de 4 studs) y deprisa, salen de tus pies.
--   * Burbujas de las grietas del Gran Veril: unas pocas columnas cerca de ti (shared/Sea/DeepReef).
-- Barato: todo se decide 4 veces por segundo; las burbujas, como mucho 3 en el móvil y 6 en el ordenador.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ocean = require(ReplicatedStorage.Shared.Sea.Ocean)
local OceanBiomes = require(ReplicatedStorage.Shared.Sea.OceanBiomes)
local DeepReef = require(ReplicatedStorage.Shared.Sea.DeepReef)
local Perf = require(script.Parent.Parent.UI.Perf)

local SeaV4Fx = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local SURFACE = Ocean.Surface

SeaV4Fx.MaxVents = if Perf.mobile then 3 else 6
SeaV4Fx.PuffHeight = 4
SeaV4Fx.PuffSpeed = 5

-- (puras, en shared/Sea/OceanBiomes: las prueba scripts/test-mar.luau) Cuánta viñeta y qué color a una hondura
SeaV4Fx.vignette = OceanBiomes.v4Vignette
SeaV4Fx.grade = OceanBiomes.v4Grade

local gui: ScreenGui? = nil
local edges: { Frame } = {}
local function makeVignette(): ScreenGui
	local g = Instance.new("ScreenGui")
	g.Name = "MarV4Vineta"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = -5 -- (debajo del HUD)
	g.Enabled = false
	-- cuatro bandas con degradado de transparencia hacia el centro
	local specs = {
		{ UDim2.new(1, 0, 0.28, 0), UDim2.new(0, 0, 0, 0), 90 },
		{ UDim2.new(1, 0, 0.28, 0), UDim2.new(0, 0, 0.72, 0), -90 },
		{ UDim2.new(0.2, 0, 1, 0), UDim2.new(0, 0, 0, 0), 0 },
		{ UDim2.new(0.2, 0, 1, 0), UDim2.new(0.8, 0, 0, 0), 180 },
	}
	for _, sp in specs do
		local f = Instance.new("Frame")
		f.Size = sp[1]
		f.Position = sp[2]
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rgb(0, 8, 24)
		f.Active = false
		local grad = Instance.new("UIGradient")
		grad.Rotation = sp[3]
		grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		grad.Parent = f
		f.Parent = g
		table.insert(edges, f)
	end
	g.Parent = player:WaitForChild("PlayerGui")
	return g
end

local cc: ColorCorrectionEffect? = nil
local function grading(): ColorCorrectionEffect
	if cc and cc.Parent then
		return cc
	end
	local e = Instance.new("ColorCorrectionEffect")
	e.Name = "MarV4Color"
	e.Enabled = false
	e.Parent = Lighting
	cc = e
	return e
end

-- Nubecillas de arena (en los pies)
local puff: ParticleEmitter? = nil
local function makePuff(root: BasePart): ParticleEmitter
	local att = Instance.new("Attachment")
	att.Name = "MarV4Arena"
	att.Position = Vector3.new(0, -2.6, 0)
	att.Parent = root
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(rgb(214, 196, 156))
	e.LightInfluence = 0.6
	e.Rate = 0
	e.Lifetime = NumberRange.new(1.4, 2.4)
	e.Speed = NumberRange.new(0.6, 1.6)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, -0.4, 0)
	e.Drag = 2
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.4) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Parent = att
	return e
end

-- Burbujas de las grietas del veril: { [key] = { Part, Emitter } }
local vents: { [string]: BasePart } = {}
local function ventPart(at: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = "MarV4Burbujas"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(at)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(rgb(225, 245, 255))
	e.LightEmission = 0.3
	e.Rate = 9
	e.Lifetime = NumberRange.new(5, 8)
	e.Speed = NumberRange.new(3, 5)
	e.SpreadAngle = Vector2.new(8, 8)
	e.Acceleration = Vector3.new(0, 1.2, 0)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0.32) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.85, 0.4), NumberSequenceKeypoint.new(1, 1) })
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = p
	p.Parent = workspace
	return p
end

-- Las grietas con burbujas cerca de (x, z): en la cara de las parcelas de pared, a media altura (puras)
function SeaV4Fx.ventsNear(x: number, z: number, radius: number): { { Key: string, At: Vector3 } }
	local out = {}
	local C = DeepReef.Cell
	local r = math.ceil(radius / C)
	local cx, cz = math.floor(x / C), math.floor(z / C)
	for ix = cx - r, cx + r do
		for iz = cz - r, cz + r do
			if DeepReef.hash(ix, iz, 77) > 0.72 then
				local sp = DeepReef.spot(ix, iz)
				if sp and math.abs(sp.U) < C * 0.5 and sp.Top - sp.Fosa > 60 then
					local y = sp.Top - (sp.Top - sp.Fosa) * (0.3 + DeepReef.hash(ix, iz, 78) * 0.5)
					local at = Vector3.new(sp.WX + sp.NX * 3, y, sp.WZ + sp.NZ * 3)
					if (at.X - x) ^ 2 + (at.Z - z) ^ 2 < radius * radius then
						table.insert(out, { Key = ix .. ":" .. iz, At = at })
					end
				end
			end
		end
	end
	table.sort(out, function(a, b)
		return (a.At.X - x) ^ 2 + (a.At.Z - z) ^ 2 < (b.At.X - x) ^ 2 + (b.At.Z - z) ^ 2
	end)
	return out
end

function SeaV4Fx.init()
	if not Ocean.V4 then
		return
	end
	gui = makeVignette()
	local last = 0
	local under = false
	local meters = 0
	RunService.RenderStepped:Connect(function()
		local ok, err = pcall(function()
			local now = os.clock()
			local camera = workspace.CurrentCamera
			if not camera then
				return
			end
			local cam = camera.CFrame.Position
			if now - last > 0.25 then
				last = now
				local s = cam.Y < SURFACE and Ocean.sample(cam.X, cam.Z) or nil
				under = s ~= nil and s.Floor ~= nil and s.Zone ~= nil
				meters = math.max(0, Ocean.meters(cam.Y))
				-- viñeta y color
				if gui then
					gui.Enabled = under
					if under then
						local v = SeaV4Fx.vignette(meters)
						for _, f in edges do
							local grad = f:FindFirstChildOfClass("UIGradient")
							if grad then
								grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - v * 0.7), NumberSequenceKeypoint.new(1, 1) })
							end
						end
					end
				end
				local e = grading()
				e.Enabled = under
				if under then
					local tint, sat, contrast = SeaV4Fx.grade(meters)
					e.TintColor = tint
					e.Saturation = sat
					e.Contrast = contrast
				end
				-- burbujas de las grietas del veril (las más cercanas)
				local want = {}
				if under then
					for i, v in SeaV4Fx.ventsNear(cam.X, cam.Z, 160) do
						if i > SeaV4Fx.MaxVents then
							break
						end
						want[v.Key] = true
						if not vents[v.Key] then
							vents[v.Key] = ventPart(v.At)
						end
					end
				end
				for key, p in vents do
					if not want[key] then
						p:Destroy()
						vents[key] = nil
					end
				end
				-- nubecillas de arena al nadar pegado al fondo
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					if not puff or not puff.Parent then
						puff = makePuff(root)
					end
					local pos = root.Position
					local fy = if under then Ocean.floorY(pos.X, pos.Z) else nil
					local speed = root.AssemblyLinearVelocity.Magnitude
					local close = fy ~= nil and pos.Y - fy < SeaV4Fx.PuffHeight and pos.Y < SURFACE
					;(puff :: ParticleEmitter).Rate = if close and speed > SeaV4Fx.PuffSpeed then (if Perf.mobile then 6 else 12) else 0
				end
			end
		end)
		if not ok then
			warn("[SeaV4Fx] " .. tostring(err))
		end
	end)
end

return SeaV4Fx
