-- WorldService: ciclo día/noche, farolas y efectos de iluminación para dar ambiente.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Npc = require(script.Parent.Parent.World.Npc)
local MapInfo = require(ReplicatedStorage.Shared.MapInfo)

-- Antes de llevar a alguien a otro sitio: que se levante del asiento en que vaya (coche, autobús,
-- metro). Si no, se llevaba el vehículo con él (un coche del metro acababa en la calle).
local function standUpBefore(character: Model?)
	local ok, who = pcall(function()
		return character and game:GetService("Players"):GetPlayerFromCharacter(character)
	end)
	if ok and who then
		pcall(function()
			require(script.Parent.VehicleService).standUp(who)
		end)
	end
end


local WorldService = {}

local day = 1 -- día absoluto (atributo "Day" de workspace)

local function ensure(className: string, props: { [string]: any })
	local instance = Lighting:FindFirstChildOfClass(className) or Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = Lighting
end

local function setupLighting()
	Lighting.ClockTime = Config.StartClockTime
	-- Los valores base vienen del archivo del juego (default.project.json); esto asegura que existen.
	-- La luz de cada hora (amanecer, mediodía, atardecer, noche) la pinta cada jugador en su dispositivo:
	-- client/Controllers/DayLight.luau (así va suave, no gasta red y se adapta a la calidad gráfica).
	ensure("Atmosphere", {})
	ensure("BloomEffect", {})
	ensure("SunRaysEffect", {})
	ensure("ColorCorrectionEffect", {})
	ensure("DepthOfFieldEffect", { FarIntensity = 0, NearIntensity = 0, InFocusRadius = 120, FocusDistance = 60 })
	ensure("Sky", { SunAngularSize = 14, MoonAngularSize = 9, StarCount = 3000 })
	-- Estilo de luz realista (propiedades recientes de Roblox: si no existen, no pasa nada)
	pcall(function()
		(Lighting :: any).LightingStyle = Enum.LightingStyle.Realistic
	end)
	pcall(function()
		(Lighting :: any).PrioritizeLightingQuality = false -- respeta la calidad gráfica de cada jugador
	end)
	-- Agua del mar de Playa Dorada: más transparente, con reflejos y olas suaves
	local terrain = workspace.Terrain
	terrain.WaterColor = Color3.fromRGB(28, 104, 124)
	terrain.WaterTransparency = 0.55
	terrain.WaterReflectance = 0.85
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 12
	-- Nubes de verdad (volumétricas); su cantidad y color los ajusta cada jugador según la hora
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.45
	clouds.Density = 0.3
	clouds.Parent = terrain
end

local NIGHT_WINDOW_COLOR = Color3.fromRGB(240, 180, 110)
local night = false
local windowOn: { [BasePart]: boolean } = {}

local function applyLamp(bulb: Instance)
	local light = bulb:FindFirstChildWhichIsA("Light")
	if light then
		light.Enabled = night
	end
	if bulb:IsA("BasePart") then
		bulb.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

-- Ventanas que se iluminan de noche (las marca el generador de edificios).
-- Cada una tiene su color (NightColor) y su horario (OnAt / OffAt; 25 = la 1 de la madrugada):
-- la ciudad se va encendiendo poco a poco al anochecer y apagando de madrugada, como una de verdad.
-- Hay más de 5.000: su horario y colores se leen una sola vez y se guardan en esta tabla, así la
-- revisión de cada segundo solo compara números (antes leía 2 o 3 atributos de cada ventana).
type WindowInfo = { OnAt: number, OffAt: number, NightColor: Color3, DayColor: Color3? }
local windows: { [BasePart]: WindowInfo } = {}

local function track(window: Instance): WindowInfo?
	if not window:IsA("BasePart") then
		return nil
	end
	local info = windows[window]
	if not info then
		local onAt, offAt = window:GetAttribute("OnAt"), window:GetAttribute("OffAt")
		local nightColor, dayColor = window:GetAttribute("NightColor"), window:GetAttribute("DayColor")
		info = {
			OnAt = if typeof(onAt) == "number" then onAt else Config.LampsOnAt,
			OffAt = if typeof(offAt) == "number" then offAt else (Config.LampsOffAt + 24),
			NightColor = if typeof(nightColor) == "Color3" then nightColor else NIGHT_WINDOW_COLOR,
			DayColor = if typeof(dayColor) == "Color3" then dayColor else nil,
		}
		windows[window] = info
	end
	return info
end

local function untrack(window: Instance)
	windows[window :: BasePart] = nil
	windowOn[window :: BasePart] = nil
end

-- Solo se toca la pieza cuando cambia de estado (encendida / apagada)
local function setWindow(window: BasePart, info: WindowInfo, on: boolean)
	if windowOn[window] == on then
		return
	end
	windowOn[window] = on
	window.Material = if on then Enum.Material.Neon else Enum.Material.Glass
	window.Color = if on then info.NightColor else (info.DayColor or window.Color)
	-- Las ventanas grandes (franjas de una planta entera, paneles de oficina) llevan "Soft": neón
	-- medio transparente, así se ven encendidas sin que la fachada entera deslumbre
	if window:GetAttribute("Soft") then
		window.Transparency = if on then 0.45 else 0
	end
end

local function shouldBeLit(info: WindowInfo, clock: number): boolean
	local t = if clock < 12 then clock + 24 else clock -- horas de la noche seguidas (1:00 = 25)
	return t >= info.OnAt and t < info.OffAt
end

local function applyWindow(window: Instance)
	local info = track(window)
	if info then
		setWindow(window :: BasePart, info, shouldBeLit(info, Lighting.ClockTime))
	end
end

local function updateWindows(clock: number)
	for window, info in windows do
		setWindow(window, info, shouldBeLit(info, clock))
	end
end

-- Luz del faro (se enciende con las farolas)
local function lighthouse(on: boolean)
	for _, lamp in CollectionService:GetTagged("FaroLuz") do
		for _, light in lamp:GetChildren() do
			if light:IsA("Light") then
				light.Enabled = on
			end
		end
		if lamp:IsA("BasePart") then
			lamp.Material = if on then Enum.Material.Neon else Enum.Material.Glass
		end
	end
end

-- Las farolas no se encienden todas a la vez (cada fotocélula tarda un poco distinto)
local carLightsHooked = false
local function setNight(on: boolean)
	night = on
	lighthouse(on)
	for _, bulb in CollectionService:GetTagged("StreetLamp") do
		task.delay(math.random() * 6, applyLamp, bulb)
	end
	-- Faros de los coches aparcados (CarLight): se encienden y apagan como las farolas. Los coches
	-- que aparecen luego (incidentes, etc.) salen ya con la luz que toca.
	for _, lamp in CollectionService:GetTagged("CarLight") do
		task.delay(math.random() * 6, applyLamp, lamp)
	end
	if not carLightsHooked then
		carLightsHooked = true
		CollectionService:GetInstanceAddedSignal("CarLight"):Connect(applyLamp)
	end
end

---------------------------------------------------------------------
-- Faro (luz giratoria de noche) y barca del puerto a la isla
---------------------------------------------------------------------
local function spinLighthouse()
	local angle = 0
	while true do
		local dt = task.wait(0.1)
		if night then
			angle = (angle + dt * math.pi / 4) % (math.pi * 2) -- una vuelta cada 8 segundos
			for _, lamp in CollectionService:GetTagged("FaroLuz") do
				if lamp:IsA("BasePart") then
					lamp.CFrame = CFrame.new(lamp.Position) * CFrame.Angles(0, angle, 0)
				end
			end
		end
	end
end

local ferryBusy: { [Player]: boolean } = {}
local function setupFerry(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	prompt.Triggered:Connect(function(player)
		local target = prompt:GetAttribute("Target")
		local character = player.Character
		if ferryBusy[player] or typeof(target) ~= "Vector3" or not character or player:GetAttribute("Riding") then
			return
		end
		ferryBusy[player] = true
		local notify = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Notify")
		if notify then
			(notify :: RemoteEvent):FireClient(player, "Travel", "⛵ " .. prompt.ActionText .. "...")
		end
		task.wait(0.8)
		if character.Parent then
			standUpBefore(character)
			character:PivotTo(CFrame.new(target))
		end
		ferryBusy[player] = nil
	end)
end

---------------------------------------------------------------------
-- Lugares del mapa: ReplicatedStorage.MapLandmarks (lo lee el mapa de cada jugador)
---------------------------------------------------------------------
local function publishLandmarks()
	local town = workspace:FindFirstChild("Town")
	if not town then
		return
	end
	type Found = { Kind: string, Position: Vector3, Count: number }
	local found: { Found } = {}
	for _, model in town:GetDescendants() do
		local kind = model:IsA("Model") and MapInfo.KindByModel[model.Name]
		if kind then
			local ok, cf = pcall(function()
				return (model :: Model):GetBoundingBox()
			end)
			if ok then
				local position = cf.Position
				-- Las playas y granjas son varias manzanas: se juntan en un solo punto
				local merged = false
				if kind.Merge then
					for _, other in found do
						if other.Kind == kind.Model and (other.Position - position).Magnitude < kind.Merge then
							other.Position = (other.Position * other.Count + position) / (other.Count + 1)
							other.Count += 1
							merged = true
							break
						end
					end
				end
				if not merged then
					table.insert(found, { Kind = kind.Model, Position = position, Count = 1 })
				end
			end
		end
	end
	local folder = ReplicatedStorage:FindFirstChild("MapLandmarks") or Instance.new("Folder")
	folder.Name = "MapLandmarks"
	folder:ClearAllChildren()
	for i, place in found do
		local config = Instance.new("Configuration")
		config.Name = place.Kind .. i
		config:SetAttribute("Kind", place.Kind)
		config:SetAttribute("Position", Vector3.new(place.Position.X, 0, place.Position.Z))
		local district = MapInfo.districtAt(place.Position.X, place.Position.Z)
		config:SetAttribute("District", if district then district.Name else "")
		config.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

---------------------------------------------------------------------
-- Dormir: si es de noche y todos los jugadores están durmiendo, se hace de día (7:00)
---------------------------------------------------------------------
local function isNight(clock: number): boolean
	return clock >= 21 or clock < 6.5
end

function WorldService.trySkipNight()
	if not isNight(Lighting.ClockTime) then
		return false
	end
	for _, other in Players:GetPlayers() do
		-- (los bebés no pueden dormir cuando quieren: no se les espera)
		if not other:GetAttribute("Sleeping") and other:GetAttribute("LifeStage") ~= "Bebe" then
			return false
		end
	end
	-- Con skipTo: si era antes de medianoche también sube el contador de días (poner ClockTime a
	-- mano no lo hacía, porque el reloj no ve la vuelta)
	WorldService.skipTo(7)
	return true
end

-- (Las camas de las casas familiares ya no tienen aquí su propio "Dormir": de eso se encarga
-- SleepService con la cama de la historia, "Cama". Había dos avisos en la misma cama y este no
-- guardaba dónde reaparecer y esperaba también a los bebés, que nunca duermen)

-- Trabajadores de la ciudad: una persona con su uniforme en cada edificio importante
-- (las posiciones las marca el mapa con piezas "WorkerSpot" y el oficio en Role)
-- Work: lo que hace mientras espera (Controllers/WorkAnim en el cliente)
local rgb = Color3.fromRGB
local UNIFORMS: { [string]: { Work: string, Look: Npc.Look, Icon: string, Lines: { string } } } = {
	["Médico"] = { Work = "Clipboard", Look = { Shirt = rgb(245, 245, 245), Pants = rgb(150, 200, 225), LongSleeves = true }, Icon = "🏥", Lines = { "¡Buenos días! ¿Todo bien?", "Recuerda beber agua.", "Hoy hay mucho trabajo en el hospital." } },
	["Enfermera"] = { Work = "Clipboard", Look = { Shirt = rgb(150, 200, 225), Pants = rgb(150, 200, 225) }, Icon = "💉", Lines = { "Si te encuentras mal, entra sin miedo.", "¡Hola! ¿Vienes a ver a alguien?" } },
	["Policía"] = { Work = "Traffic", Look = { Shirt = rgb(40, 60, 110), Pants = rgb(30, 35, 60), LongSleeves = true }, Icon = "👮", Lines = { "Todo tranquilo por aquí.", "Cruza siempre por el paso de cebra.", "¡Buen día, ciudadano!" } },
	["Guardia"] = { Work = "Guard", Look = { Shirt = rgb(55, 55, 60), Pants = rgb(35, 35, 40), LongSleeves = true }, Icon = "🛡️", Lines = { "Bienvenido.", "El horario está en la entrada." } },
	["Recepcionista"] = { Work = "Clipboard", Look = { Shirt = rgb(245, 245, 245), Pants = rgb(40, 40, 50) }, Icon = "🛎️", Lines = { "¡Bienvenido! ¿En qué puedo ayudarte?", "Que tengas una buena estancia." } },
	["Funcionario"] = { Work = "Clipboard", Look = { Shirt = rgb(200, 210, 225), Pants = rgb(50, 55, 70), LongSleeves = true }, Icon = "📋", Lines = { "Para los trámites, pide cita.", "¡Buenos días! El Ayuntamiento está abierto." } },
	["Revisor"] = { Work = "Count", Look = { Shirt = rgb(150, 30, 40), Pants = rgb(30, 30, 40), LongSleeves = true }, Icon = "🎫", Lines = { "Billetes, por favor.", "El próximo sale en diez minutos." } },
	["Taquillero"] = { Work = "Count", Look = { Shirt = rgb(90, 60, 110), Pants = rgb(40, 40, 50) }, Icon = "🎟️", Lines = { "¡Quedan entradas para hoy!", "¿Una entrada?" } },
	["Conductor"] = { Work = "Watch", Look = { Shirt = rgb(60, 120, 190), Pants = rgb(40, 45, 60) }, Icon = "🚌", Lines = { "Salgo hacia el centro en un rato.", "¡Sube, que nos vamos!" } },
	["Guía"] = { Work = "Present", Look = { Shirt = rgb(200, 150, 60), Pants = rgb(60, 50, 40) }, Icon = "🖼️", Lines = { "El museo tiene cuadros de toda la historia de Valmar.", "¿Te hago una visita guiada?" } },
	["Dependiente"] = { Work = "Fold", Look = { Shirt = rgb(40, 140, 110), Pants = rgb(40, 40, 50) }, Icon = "🛍️", Lines = { "¡Hoy hay rebajas!", "Pasa, pasa, que tenemos de todo." } },
	["Feriante"] = { Work = "Call", Look = { Shirt = rgb(230, 70, 70), Pants = rgb(250, 200, 60) }, Icon = "🎡", Lines = { "¡Pasen y vean!", "¡La noria es la mejor vista de Valmar!" } },
	["Monitor"] = { Work = "Clipboard", Look = { Shirt = rgb(90, 170, 80), Pants = rgb(120, 100, 70) }, Icon = "⛺", Lines = { "¡Bienvenido al camping!", "Esta noche hay fogata." } },
	["Conserje"] = { Work = "Sweep", Look = { Shirt = rgb(110, 110, 120), Pants = rgb(60, 60, 70), LongSleeves = true }, Icon = "🔑", Lines = { "¡No corras por los pasillos!", "Buenos días." } },
	["Jardinero"] = { Work = "Garden", Look = { Shirt = rgb(70, 140, 70), Pants = rgb(80, 70, 50) }, Icon = "🌻", Lines = { "Estas flores las he plantado yo.", "¡No pises el césped, que está recién regado!", "En primavera este parque es precioso." } },
	["Mecánico"] = { Work = "Hammer", Look = { Shirt = rgb(40, 70, 130), Pants = rgb(40, 70, 130), LongSleeves = true }, Icon = "🔧", Lines = { "¿Te hace un ruido raro el coche? Tráemelo.", "Cambiar una rueda es más fácil de lo que parece." } },
	["Obrero"] = { Work = "Hammer", Look = { Shirt = rgb(240, 150, 40), Pants = rgb(60, 60, 70) }, Icon = "👷", Lines = { "¡Cuidado, zona de obras!", "Esta nave estará lista en primavera." } },
	["Granjero"] = { Work = "Rake", Look = { Shirt = rgb(170, 60, 50), Pants = rgb(60, 80, 130) }, Icon = "🌾", Lines = { "Este año la cosecha viene buena.", "Las gallinas se levantan antes que yo." } },
	["Músico"] = { Work = "Guitar", Look = { Shirt = rgb(30, 30, 34), Pants = rgb(50, 60, 90) }, Icon = "🎸", Lines = { "¿Te sabes esta? ¡Canta conmigo!", "Toco aquí todas las tardes.", "Una moneda para el músico, que da suerte." } },
	["Limpiador"] = { Work = "Mop", Look = { Shirt = rgb(60, 150, 190), Pants = rgb(40, 60, 80) }, Icon = "🧹", Lines = { "Cuidado, que resbala.", "Una ciudad limpia es una ciudad feliz." } },
}
local MAX_WORKERS = 110

local function spawnWorkers()
	local folder = Instance.new("Folder")
	folder.Name = "Trabajadores"
	folder.Parent = workspace
	local count = 0
	for _, spot in CollectionService:GetTagged("WorkerSpot") do
		if count >= MAX_WORKERS then
			break
		end
		local role = spot:GetAttribute("Role")
		local uniform = UNIFORMS[role]
		if spot:IsA("BasePart") and uniform then
			count += 1
			local feet = spot.CFrame * CFrame.new(0, -spot.Size.Y / 2, 0)
			local npc = Npc.create(role, folder, feet, uniform.Look)
			Npc.icon(npc, uniform.Icon)
			Npc.work(npc, uniform.Work) -- barre, apunta, dirige el tráfico… (lo anima el cliente)
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Hablar"
			prompt.ObjectText = role
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = npc.PrimaryPart
			local talking = false
			prompt.Triggered:Connect(function(player)
				if talking then
					return
				end
				talking = true
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					Npc.face(npc, root.Position)
				end
				Npc.say(npc, uniform.Lines[math.random(1, #uniform.Lines)])
				task.delay(4, function()
					Npc.say(npc, nil)
					talking = false
				end)
			end)
		end
	end
end

-- Salta el reloj a una hora (dormir: la noche pasa y amanece). Si la hora es anterior a la actual,
-- es el día siguiente. Devuelve true si ha cambiado de día.
function WorldService.skipTo(clockTime: number): boolean
	local newDay = Lighting.ClockTime > clockTime
	if newDay then
		day += 1
		workspace:SetAttribute("Day", day)
	end
	Lighting.ClockTime = clockTime
	return newDay
end

function WorldService.init()
	setupLighting()
	publishLandmarks()
	for _, prompt in CollectionService:GetTagged("Ferry") do
		setupFerry(prompt)
	end
	CollectionService:GetInstanceAddedSignal("Ferry"):Connect(setupFerry)
	Players.PlayerRemoving:Connect(function(player)
		ferryBusy[player] = nil
	end)
	task.spawn(spinLighthouse)
	task.defer(spawnWorkers)

	workspace:SetAttribute("Day", day)
	local hoursPerSecond = 24 / (Config.DayLengthMinutes * 60)
	local lampsOn: boolean? = nil
	local windowTimer = 0

	-- Lo que se construya después (casas de jugadores) respeta la hora actual
	CollectionService:GetInstanceAddedSignal("StreetLamp"):Connect(applyLamp)
	CollectionService:GetInstanceAddedSignal("NightWindow"):Connect(applyWindow)
	CollectionService:GetInstanceRemovedSignal("NightWindow"):Connect(untrack)
	for _, window in CollectionService:GetTagged("NightWindow") do
		track(window)
	end

	-- Horario de clase: si hay niños o adolescentes en el servidor, el reloj va más despacio
	local SCHOOL = Config.SchoolDay
	local students, studentCheck = false, 0
	local function anyStudent(): boolean
		for _, p in Players:GetPlayers() do
			local stage = p:GetAttribute("LifeStage")
			if stage == "Nino" or stage == "Adolescente" then
				return true
			end
		end
		return false
	end

	-- La hora se lleva aquí con todos sus decimales: Lighting.ClockTime se guarda redondeada al
	-- segundo y, con el reloj lento del cole, cada fotograma avanza menos de un segundo de juego
	-- (si se leyera de Lighting, se quedaría parado para siempre en las 9:00).
	local exact = Lighting.ClockTime
	local written, clockTimer = exact, 0
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		-- Alguien la ha cambiado a propósito (dormir, viajar…): se sigue desde ahí
		if math.abs(Lighting.ClockTime - exact) > 0.02 then
			exact = Lighting.ClockTime
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		local previous = exact
		studentCheck -= dt
		if studentCheck <= 0 then
			studentCheck = 2
			students = anyStudent()
		end
		local speed = if students and previous >= SCHOOL.Start and previous < SCHOOL.End then SCHOOL.ClockSpeed else 1
		local clock = (previous + dt * hoursPerSecond * speed) % 24
		exact = clock
		-- Escribir Lighting.ClockTime en cada fotograma replica la propiedad a todos los jugadores
		-- 60 veces por segundo. Se escribe como mucho 4 veces por segundo (unos 18 s de juego: el sol
		-- no se ve saltar), o antes si la hora cambia de golpe; la hora exacta se sigue llevando aquí.
		clockTimer += dt
		if clockTimer >= 0.25 or math.abs(clock - written) > 0.01 then
			clockTimer = 0
			written = clock
			Lighting.ClockTime = clock
		end
		if clock < previous then
			day += 1
			workspace:SetAttribute("Day", day)
		end


		local shouldBeOn = clock >= Config.LampsOnAt or clock < Config.LampsOffAt
		if shouldBeOn ~= lampsOn then
			lampsOn = shouldBeOn
			setNight(shouldBeOn)
		end
		-- Las ventanas se revisan cada segundo real (poco más de un minuto de juego)
		windowTimer += dt
		if windowTimer >= 1 then
			windowTimer = 0
			updateWindows(clock)
		end
	end)
end

return WorldService
