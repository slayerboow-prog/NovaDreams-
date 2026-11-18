-- AshFall (cliente): Valmar después de la Caída (19-11-2026, el dueño: «no se ve post-apocalíptica»).
--
--   * Ceniza fina que cae despacio alrededor de la cámara (copos grises, algunos con brasa naranja),
--     solo en Valmar (EnvDirector.valmarAudio: 1 en Valmar, 0 en el espacio o en un planeta).
--   * Colores apagados: un ColorCorrectionEffect propio («Posguerra») que quita saturación y enfría la
--     imagen, mezclado con lo cerca que está la cámara de Valmar (sin cortes al salir o entrar).
--   * Cantidad de ceniza según el nivel gráfico (Perf): en los móviles flojos, poca.
--   Interruptor: Config.PostWar.AshFall.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local AshFall = {}

local RATE = { Bajo = 18, Medio = 40, Alto = 70 } -- copos por segundo según el nivel gráfico
local BOX = Vector3.new(90, 1, 90) -- el área de la que cae la ceniza, encima de la cámara
local HEIGHT = 28

local player = Players.LocalPlayer
local emitter: ParticleEmitter? = nil
local ember: ParticleEmitter? = nil
local anchor: BasePart? = nil
local grade: ColorCorrectionEffect? = nil
local weight = 0

local function tierRate(): number
	local ok, Perf = pcall(function()
		return require(script.Parent.Parent.UI.Perf) :: any
	end)
	local name = if ok and Perf.tierName then Perf.tierName() else "Medio"
	return RATE[name] or RATE.Medio
end

local function build()
	local part = Instance.new("Part")
	part.Name = "CenizaCayendo"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = BOX
	local ash = Instance.new("ParticleEmitter")
	ash.Name = "Ceniza"
	ash.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	ash.Color = ColorSequence.new(Color3.fromRGB(180, 176, 170), Color3.fromRGB(120, 116, 112))
	ash.LightEmission = 0
	ash.LightInfluence = 1
	ash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0.18) })
	ash.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.25), NumberSequenceKeypoint.new(0.85, 0.35), NumberSequenceKeypoint.new(1, 1) })
	ash.Lifetime = NumberRange.new(9, 13)
	ash.Speed = NumberRange.new(1.6, 3)
	ash.SpreadAngle = Vector2.new(25, 25)
	ash.EmissionDirection = Enum.NormalId.Bottom
	ash.Acceleration = Vector3.new(0.6, -0.4, 0.3) -- (deriva con el viento)
	ash.RotSpeed = NumberRange.new(-60, 60)
	ash.Rotation = NumberRange.new(0, 360)
	ash.Rate = 0
	ash.Parent = part
	local glow = Instance.new("ParticleEmitter")
	glow.Name = "Brasas"
	glow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	glow.Color = ColorSequence.new(Color3.fromRGB(255, 150, 70), Color3.fromRGB(200, 70, 30))
	glow.LightEmission = 0.8
	glow.Size = NumberSequence.new(0.08)
	glow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.2), NumberSequenceKeypoint.new(1, 1) })
	glow.Lifetime = NumberRange.new(6, 9)
	glow.Speed = NumberRange.new(1, 2)
	glow.EmissionDirection = Enum.NormalId.Bottom
	glow.Acceleration = Vector3.new(0.5, -0.2, 0.2)
	glow.Rate = 0
	glow.Parent = part
	part.Parent = workspace.CurrentCamera
	anchor, emitter, ember = part, ash, glow
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Posguerra"
	cc.Enabled = true
	cc.Parent = workspace.CurrentCamera -- (en la cámara: DayLight busca el suyo en Lighting y no se confunden)
	grade = cc
end

local function valmarWeight(): number
	local ok, Env = pcall(function()
		return require(script.Parent.EnvDirector) :: any
	end)
	if ok and Env.valmarAudio then
		local okW, w = pcall(Env.valmarAudio)
		if okW and type(w) == "number" then
			return math.clamp(w, 0, 1)
		end
	end
	return 1
end

function AshFall.init()
	local pw = Config.PostWar
	if type(pw) ~= "table" or not pw.AshFall then
		return
	end
	build()
	local base = tierRate()
	local lastTier = os.clock()
	RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		if not camera or not anchor then
			return
		end
		if anchor.Parent ~= camera then
			anchor.Parent = camera
		end
		if grade and grade.Parent ~= camera then
			grade.Parent = camera
		end
		local target = valmarWeight()
		weight += (target - weight) * math.clamp(dt * 1.5, 0, 1)
		local pos = camera.CFrame.Position
		anchor.CFrame = CFrame.new(pos + Vector3.new(0, HEIGHT, 0))
		if os.clock() - lastTier > 5 then
			lastTier = os.clock()
			base = tierRate()
		end
		local busyIndoors = player:GetAttribute("Interior") ~= nil -- (dentro de un edificio no cae ceniza)
		local k = if busyIndoors then 0 else weight
		;(emitter :: ParticleEmitter).Rate = base * k
		;(ember :: ParticleEmitter).Rate = base * 0.04 * k
		local g = grade :: ColorCorrectionEffect
		g.Saturation = -0.32 * weight
		g.Contrast = 0.06 * weight
		g.Brightness = -0.03 * weight
		g.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(226, 228, 236), weight)
	end)
end

return AshFall
