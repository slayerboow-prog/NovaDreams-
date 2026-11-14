-- DerelictClient (cliente): lo que se ve en los PECIOS de la Deriva (shared/Cosmos/Derelicts;
-- World/DerelictBuilder; Services/DerivaService).
--
--   * Linterna: mientras estás dentro (atributo EnPecio), una luz en tu pecho que alumbra hacia delante.
--   * Luces: las blancas de cada sala se encienden en TU pantalla según los fusibles que llevas
--     (atributo DerivaPower; la sala del fusible 1 con el 1, etc.; con los tres, todas). Las rojas de
--     emergencia, siempre.
--   * Barreras láser: se ven encendidas y apagadas con la misma cuenta que usa el servidor para el daño
--     (Derelicts.laserOn con la hora del servidor). Con la corriente restaurada, apagadas.
--   * La puerta del puente (campo rojo) desaparece en tu pantalla cuando ya tienes la corriente.
--   * Chispas del cuadro roto (aviso y descarga) y la baliza médica que parpadea.
-- Solo visual: el daño y los pasos los decide el servidor.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Derelicts = require(ReplicatedStorage.Shared.Cosmos.Derelicts)

local DerelictClient = {}

local player = Players.LocalPlayer
local flashlight: SpotLight? = nil
local shown = { Power = -1, Lasers = {} :: { [number]: boolean }, Spark = nil :: string?, Beacon = nil :: boolean? }

local function serverTime(): number
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(t) == "number" then t else os.clock()
end

local function setFlashlight(on: boolean)
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if on and root then
		if not flashlight or flashlight.Parent ~= root then
			local l = Instance.new("SpotLight")
			l.Name = "Linterna"
			l.Face = Enum.NormalId.Front
			l.Angle = 55
			l.Range = 38
			l.Brightness = 2.2
			l.Color = Color3.fromRGB(255, 244, 220)
			l.Shadows = true
			l.Parent = root
			flashlight = l
		end
	elseif flashlight then
		flashlight:Destroy()
		flashlight = nil
	end
end

local function applyPower(power: number)
	if shown.Power == power then
		return
	end
	shown.Power = power
	for _, lamp in CollectionService:GetTagged("PecioLuz") do
		local fuse = tonumber(lamp:GetAttribute("Fuse")) or 0
		local on = power >= 3 or (fuse > 0 and power >= fuse) or (fuse == 0 and power >= 1)
		local l = lamp:FindFirstChildOfClass("PointLight")
		if l then
			l.Enabled = on
		end
		if lamp:IsA("BasePart") then
			lamp.Transparency = if on then 0 else 0.6
		end
	end
	for _, led in CollectionService:GetTagged("PecioLed") do
		if led:IsA("BasePart") then
			local n = tonumber(led:GetAttribute("Fuse")) or 0
			led.Color = if power >= 3 or power >= n then Color3.fromRGB(80, 230, 110) else Color3.fromRGB(230, 60, 50)
		end
	end
	for _, door in CollectionService:GetTagged("PecioPuerta") do
		if door:IsA("BasePart") then
			door.LocalTransparencyModifier = if power >= 3 then 1 else 0
		end
	end
end

local function step()
	local inside = player:GetAttribute("EnPecio") ~= nil
	setFlashlight(inside)
	local power = tonumber(player:GetAttribute("DerivaPower")) or 0
	applyPower(if inside then power else 0)
	local d = Derelicts.Misericordia
	local t = serverTime()
	-- Láseres
	for i in d.Lasers do
		local on = Derelicts.laserOn(d, i, t) and not (inside and power >= 3)
		if shown.Lasers[i] ~= on then
			shown.Lasers[i] = on
			for _, beam in CollectionService:GetTagged("PecioLaser") do
				if beam:GetAttribute("Laser") == i and beam:IsA("BasePart") then
					beam.LocalTransparencyModifier = if on then 0 else 1
				end
			end
		end
	end
	-- Chispas
	local spark = Derelicts.sparkState(d, t)
	if spark ~= shown.Spark then
		shown.Spark = spark
		for _, panel in CollectionService:GetTagged("PecioChispas") do
			local pe = panel:FindFirstChild("Chispas", true)
			if pe and pe:IsA("ParticleEmitter") then
				if spark == "Warn" then
					pe:Emit(6)
				elseif spark == "Burst" then
					pe:Emit(60)
				end
			end
		end
	end
	-- Baliza médica: un destello cada 1,5 s
	local blink = (t % 1.5) < 0.35
	if blink ~= shown.Beacon then
		shown.Beacon = blink
		for _, b in CollectionService:GetTagged("PecioBaliza") do
			if b:IsA("BasePart") then
				b.Color = if blink then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(230, 60, 50)
				local l = b:FindFirstChildOfClass("PointLight")
				if l then
					l.Brightness = if blink then 4 else 1.5
				end
			end
		end
	end
end

function DerelictClient.init()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.08 then
			return
		end
		acc = 0
		local ok, err = pcall(step)
		if not ok then
			warn("[DerelictClient] " .. tostring(err))
		end
	end)
	-- (luces nuevas que llegan con la carga por zonas: se vuelven a mirar)
	CollectionService:GetInstanceAddedSignal("PecioLuz"):Connect(function()
		shown.Power = -1
	end)
	CollectionService:GetInstanceAddedSignal("PecioLaser"):Connect(function()
		table.clear(shown.Lasers)
	end)
end

return DerelictClient
