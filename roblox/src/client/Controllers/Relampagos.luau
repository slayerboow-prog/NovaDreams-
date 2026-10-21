-- Relampagos (cliente): los rayos de las tormentas de Valmar (v126, docs/clima/estaciones.md).
--
--   * CUÁNDO y DÓNDE cae cada rayo lo decide el servidor (WeatherService, atributo workspace "Rayo"):
--     todos los jugadores ven el mismo rayo a la vez. Cada uno lo dibuja desde donde está: un rayo
--     quebrado de la nube al suelo (lejos en el cielo, o cerca con su luz), el fogonazo del cielo
--     (Weather.setFlash: DayLight sube la luz un momento) y el trueno, que llega más tarde cuanto más
--     lejos cae (shared/Storm.thunderDelay: el sonido va a 343 m/s). Cerca, el «crac»; lejos, el retumbar.
--   * SIN PARPADEOS: el servidor no deja caer dos rayos con menos de Storm.MinGap s ni más de
--     Storm.MaxPerMinute por minuto, y aquí se vuelve a comprobar (Storm.allow). Cada fogonazo es un
--     destello suave (como mucho un rebote más flojo).
--   * Ajuste «⚡ Destellos de relámpago: no» (atributo LightningFlashes = false): ni fogonazo ni luz del
--     rayo; el rayo se ve tenue y el trueno suena igual.
--   * Solo en Valmar (EnvDirector.allows("Weather")): ni en el espacio, ni en los planetas, ni bajo el
--     mar. En el metro, solo el trueno apagado. Mientras una escena o la Grieta mandan en el cielo
--     (Weather.storyHold) o en una cinemática, ni rayo ni fogonazo (la escena tiene su cielo).
--   * Barato: un puñado de piezas que se reutilizan (como mucho 24), visibles un cuarto de segundo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Storm = require(ReplicatedStorage.Shared.Storm)
local Config = require(ReplicatedStorage.Shared.Config)
local Metro = require(ReplicatedStorage.Shared.Metro)
local Perf = require(script.Parent.Parent.UI.Perf)

local Relampagos = {}

local player = Players.LocalPlayer
local rgb = Color3.fromRGB

local POOL = 24 -- piezas del rayo como mucho (tronco y ramas)
local SHOW = 0.28 -- segundos que se ve el rayo
local CLOUD_Y = 760 -- altura de la panza de la nube
local DRAW_MAX = 1800 -- lo lejos que se dibuja como mucho (el trueno sí va con la distancia de verdad)

local folder: Folder? = nil
local pieces: { BasePart } = {}
local light: PointLight? = nil
local lightPart: BasePart? = nil
local history: { number } = {}
local lastN: number? = nil
local active: { At: number, Near: boolean, Safe: boolean, Until: number }? = nil
local thunderNear: Sound? = nil
local thunderFar: Sound? = nil

local function weather(): any
	return require(script.Parent.Weather)
end

local function envAllows(): boolean
	local ok, allowed = pcall(function()
		return require(script.Parent.EnvDirector).allows("Weather")
	end)
	return not ok or allowed ~= false
end

-- ¿Quiere destellos? (por defecto sí)
function Relampagos.flashesOn(): boolean
	return player:GetAttribute("LightningFlashes") ~= false
end

local function build()
	local f = Instance.new("Folder")
	f.Name = "Relampagos"
	f.Parent = workspace.CurrentCamera
	folder = f
	for i = 1, POOL do
		local p = Instance.new("Part")
		p.Name = "Rayo" .. i
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = rgb(222, 232, 255)
		p.Transparency = 1
		p.Size = Vector3.new(1, 1, 1)
		p.CFrame = CFrame.new(0, -1000, 0)
		p.Parent = f
		table.insert(pieces, p)
	end
	local lp = Instance.new("Part")
	lp.Name = "LuzRayo"
	lp.Anchored = true
	lp.CanCollide = false
	lp.CanQuery = false
	lp.CanTouch = false
	lp.Transparency = 1
	lp.Size = Vector3.new(1, 1, 1)
	lp.CFrame = CFrame.new(0, -1000, 0)
	lp.Parent = f
	lightPart = lp
	local l = Instance.new("PointLight")
	l.Color = rgb(206, 222, 255)
	l.Range = 60
	l.Brightness = 0
	l.Shadows = false
	l.Enabled = false
	l.Parent = lp
	light = l
	local W = weather()
	thunderNear = W.makeSound("ThunderNear", false)
	thunderFar = W.makeSound("ThunderFar", false)
end

local function hide()
	for _, p in pieces do
		if p.Transparency < 1 then
			p.Transparency = 1
			p.CFrame = CFrame.new(0, -1000, 0)
		end
	end
	if light then
		light.Enabled = false
	end
end

-- Pone una pieza entre dos puntos (un tramo del rayo)
local function segment(p: BasePart, a: Vector3, b: Vector3, width: number)
	local length = (b - a).Magnitude
	p.Size = Vector3.new(width, width, math.max(length, 0.5))
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
end

-- Dibuja un rayo: tronco quebrado de la nube al suelo y alguna rama
local function drawBolt(bottom: Vector3, near: boolean, seed: number, safe: boolean, distance: number)
	local rng = Random.new(seed)
	local function rand(): number
		return rng:NextNumber()
	end
	local tier = Perf.tierName()
	local segments = if tier == "Low" then 7 elseif near then 12 else 10
	local width = math.clamp(distance / 260, if near then 0.8 else 2, 7)
	local top = Vector3.new(bottom.X + (rand() - 0.5) * 120, CLOUD_Y, bottom.Z + (rand() - 0.5) * 120)
	local points = Storm.bolt(top, bottom, segments, 38 + distance * 0.01, rand)
	local used = 0
	local transparency = if safe then 0 else 0.55
	for i = 1, #points - 1 do
		used += 1
		local p = pieces[used]
		if not p then
			break
		end
		segment(p, points[i], points[i + 1], width)
		p.Transparency = transparency
	end
	-- Ramas (no en Bajo): salen del tronco hacia un lado y se apagan antes de llegar al suelo
	local branches = if tier == "Low" then 0 else (if near then 3 else 1)
	for _ = 1, branches do
		local from = points[math.clamp(2 + math.floor(rand() * (#points - 3)), 2, #points - 1)]
		local to = from + Vector3.new((rand() - 0.5) * 260, -(80 + rand() * 160), (rand() - 0.5) * 260)
		local twig = Storm.bolt(from, to, 4, 20, rand)
		for i = 1, #twig - 1 do
			used += 1
			local p = pieces[used]
			if not p then
				break
			end
			segment(p, twig[i], twig[i + 1], width * 0.5)
			p.Transparency = math.min(1, transparency + 0.25)
		end
	end
	for i = used + 1, #pieces do
		pieces[i].Transparency = 1
	end
	if lightPart and light then
		lightPart.CFrame = CFrame.new(bottom + Vector3.new(0, 25, 0))
		light.Range = if near then 60 else 0
		light.Enabled = near and safe
	end
end

local function playThunder(distance: number)
	local kind, volume = Storm.thunder(distance)
	local sound = if kind == "Near" then thunderNear or thunderFar else thunderFar or thunderNear
	if not sound then
		return
	end
	local okW, W = pcall(weather)
	local base = if okW then W.thunderVolume() else 0.6
	if base <= 0.001 then
		return
	end
	task.delay(Storm.thunderDelay(distance), function()
		sound.Volume = base * volume
		sound.PlaybackSpeed = 0.9 + math.random() * 0.2 -- (cada trueno un poco distinto)
		sound.TimePosition = 0
		sound:Play()
	end)
end

-- Llega un rayo del servidor (lo llaman la señal del atributo y las pruebas)
function Relampagos.onStrike(text: any)
	local strike = Storm.decode(text)
	if not strike then
		return
	end
	if lastN == nil or strike.N <= lastN then
		lastN = strike.N -- (el primero que se ve al entrar ya pasó: no se repite)
		return
	end
	lastN = strike.N
	local camera = workspace.CurrentCamera
	if not camera or not envAllows() then
		return
	end
	local at = camera.CFrame.Position
	local now = os.clock()
	if not Storm.allow(history, now) then
		return -- (aquí también: nunca más rayos de la cuenta)
	end
	Storm.record(history, now)
	local ground = Vector3.new(strike.X, 0, strike.Z)
	local flat = Vector3.new(at.X, 0, at.Z)
	local distance = math.max(80, (ground - flat).Magnitude)
	playThunder(distance)
	local underground = at.Y < Metro.Underground
	local okHold, held = pcall(function()
		return weather().storyHold()
	end)
	local scene = player:GetAttribute("InScene") == true or (okHold and type(held) == "number" and held > 0.5)
	if underground or scene then
		return -- (en el metro solo se oye; en una escena, su cielo)
	end
	-- Lo lejano se dibuja algo más cerca (si no, se perdería en la bruma), en la misma dirección
	local dir = if (ground - flat).Magnitude > 1 then (ground - flat).Unit else Vector3.xAxis
	local drawAt = flat + dir * math.clamp(distance, 250, DRAW_MAX)
	local safe = Relampagos.flashesOn()
	drawBolt(Vector3.new(drawAt.X, math.max(0, at.Y - 60), drawAt.Z), strike.Near, strike.Seed, safe, math.min(distance, DRAW_MAX))
	active = { At = now, Near = strike.Near, Safe = safe, Until = now + SHOW }
end

function Relampagos.init()
	Storm.configure(Config.Seasons and Config.Seasons.Lightning)
	build()
	lastN = (Storm.decode(workspace:GetAttribute("Rayo")) or { N = 0 }).N
	workspace:GetAttributeChangedSignal("Rayo"):Connect(function()
		local ok, err = pcall(Relampagos.onStrike, workspace:GetAttribute("Rayo"))
		if not ok then
			warn("[Relampagos] " .. tostring(err))
		end
	end)
	RunService.RenderStepped:Connect(function()
		local a = active
		if not a then
			return
		end
		local now = os.clock()
		local age = now - a.At
		local value = Storm.flash(age, a.Near, a.Safe)
		pcall(function()
			weather().setFlash(value * 0.85)
		end)
		if light and light.Enabled then
			light.Brightness = 8 * value
		end
		-- El rayo se apaga en su cuarto de segundo (se va aclarando)
		local fade = math.clamp((now - a.At) / SHOW, 0, 1)
		if fade >= 1 then
			hide()
		else
			local base = if a.Safe then 0 else 0.55
			for _, p in pieces do
				if p.Transparency < 1 then
					p.Transparency = math.min(0.99, base + fade * fade * (1 - base))
				end
			end
		end
		if age > Storm.FlashSeconds and fade >= 1 then
			active = nil
			pcall(function()
				weather().setFlash(0)
			end)
		end
	end)
end

return Relampagos
