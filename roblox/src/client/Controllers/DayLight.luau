-- DayLight (cliente): la luz del día pintada en el dispositivo de cada jugador, para que parezca real.
--
--   * 11 momentos del día (noche, antes del alba, amanecer, mañana dorada, mañana, mediodía, tarde,
--     hora dorada, puesta de sol, hora azul) con la luz, el cielo, la bruma, las nubes y el color de cada uno.
--     Entre uno y otro se pasa poco a poco.
--   * Cada día de juego trae más o menos nubes (igual para todos los jugadores del servidor); el viento
--     (según el tiempo) las hace pasar y el cielo se tapa y destapa un poco cada pocos minutos.
--   * Los ojos se acostumbran: dentro de casa la imagen se aclara un poco, como una cámara de verdad.
--   * En las cinemáticas, enfoque de cine (el fondo se desenfoca un poco) y algo más de contraste.
--   * Según el nivel gráfico (UI/Perf, shared/Graphics): Bajo sin sombras del sol, desenfoque ni rayos
--     de sol, con menos nube, niebla, reflejos y color; Medio con desenfoque solo en las cinemáticas;
--     Alto con todo, sombras más nítidas, más niebla y colores más vivos (esto último se nota también
--     en un móvil con la calidad de Roblox baja, que ya quita sombras y efectos por su cuenta).
--   * Las curvas de luz y color (y lo que cambia el tiempo) están en shared/DayGrade: sol cálido con
--     dirección (ColorShift_Top), sombras azuladas, bruma que azula lo lejano y etalonaje suave.
--   * Cielo de fotos (skybox) de día y de noche si el servidor lo ha cargado (shared/SkyChoice,
--     World/SkyLoader): se copian sus caras al Sky de Lighting; si no hay, el cielo de siempre.
--   * Bajo el agua es una ZONA más (EnvDirector → setZone, zona «Submarino» de shared/Cosmos/EnvZones):
--     su luz (EnvZones.underwaterKey: bruma azul del mar de la zona y la hondura) se mezcla con las de
--     las demás zonas; aquí solo se aplica, con el fondo algo desenfocado.
-- El reloj lo mueve el servidor (WorldService); aquí solo se lee Lighting.ClockTime, que es la HORA
-- DEL SOL (shared/DayCycle: atardece de 21:30 a 22:00 del juego). Las horas de DayGrade son del sol.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DayGrade = require(ReplicatedStorage.Shared.DayGrade)
local SkyChoice = require(ReplicatedStorage.Shared.SkyChoice)
local EnvZones = require(ReplicatedStorage.Shared.Cosmos.EnvZones)
local Perf = require(script.Parent.Parent.UI.Perf)
local RainVeil = require(script.Parent.RainVeil)

local DayLight = {}

local rgb = Color3.fromRGB
local UPDATE_EVERY = 0.1 -- segundos entre actualizaciones (10 veces por segundo es suficiente)

type Key = DayGrade.Key

-- Cómo es la luz a cada hora (y cómo la cambia el tiempo): shared/DayGrade
local sample = DayGrade.sample

-- Nubes del día: cada día de juego es un poco distinto (igual para todo el servidor)
local function dailyClouds(day: number): number
	local x = math.sin(day * 12.9898) * 43758.5453
	return (x - math.floor(x) - 0.5) * 0.2 -- entre -0.1 y +0.1 (nunca un cielo vacío de día)
end

-- Cielo de fotos: copia las 6 caras del Sky cargado (o las de siempre) al Sky de Lighting.
-- El sol, la luna y las estrellas no se tocan.
local originalFaces: { [string]: string }? = nil
local skyShown: string? = nil -- "Day" / "Night" / nil (= el de siempre)
-- Cielo especial encima del de la hora (Controllers/SkyExtras: tormenta, sueño, Grieta…): el nombre de
-- un Sky de SkyLibrary, "Original" (= el de siempre) o nil (= el de la hora)
local skyOverride: string? = nil
-- Los cielos que pone el TIEMPO (shared/SkyExtras.WeatherSkies): con ellos el velo de lluvia sigue
local WEATHER_SKIES: { [string]: boolean } = { Original = true }
pcall(function()
	for _, slot in require(ReplicatedStorage.Shared.SkyExtras).WeatherSkies do
		WEATHER_SKIES[slot] = true
	end
end)
function DayLight.setSkyOverride(slot: string?)
	skyOverride = slot
end
-- Cielo que manda sobre todo lo demás (la arena del combate aéreo: Controllers/AirCombatClient). Una lista
-- de huecos de SkyLibrary por orden de preferencia ("Original" = el del archivo); nil = como siempre.
local forcedSky: { string }? = nil
function DayLight.forceSky(slots: { string }?)
	forcedSky = slots
end

-- La ZONA donde está la cámara (Controllers/EnvDirector, shared/Cosmos/EnvZones): Valmar, la transición,
-- el espacio o un planeta. Es el único dueño del cielo fuera de Valmar: su cielo manda sobre todos los
-- demás (también sobre forceSky), su luz se mezcla la ÚLTIMA (encima del tiempo y de las capas de la
-- historia) y dice si van la bruma, las nubes y el etalonaje de Valmar.
local zoneEnv: EnvZones.Env? = nil
local zoneFlags: EnvZones.Flags? = nil
local underwater = 0 -- 0 = fuera del agua, 1 = la cámara está bajo el agua (zona «Submarino»)
-- Cómo es el agua donde está la cámara (zona y profundidad: shared/Sea/OceanBiomes.look). nil = la bruma
-- de siempre (río, lagos o antes de saberlo).
local seaLook: { [string]: any }? = nil
local zoneAt = -math.huge -- cuándo dijo EnvDirector la zona por última vez
function DayLight.setZone(env: EnvZones.Env?, flags: EnvZones.Flags?)
	zoneEnv, zoneFlags = env, flags
	zoneAt = os.clock()
	underwater = if env then math.clamp(env.Under or 0, 0, 1) else 0
	seaLook = if env then env.SeaLook else nil
end

-- (v122, captura del dueño en la v121: en la órbita de Tefra el cielo era el de Valmar visto desde muy
-- alto —cenit azul marino y abajo una bruma azul clara lisa hasta el horizonte— y los planetas lejanos
-- salían desvaídos: es la bruma de Roblox, Atmosphere, con los colores de Valmar, que solo está si
-- DayLight cree que la cámara está en Valmar.) Si EnvDirector no ha dicho nada en StaleZone segundos
-- (se ha parado, no ha arrancado o su require se ha quedado esperando), DayLight mira la zona él solo
-- con la posición de la cámara: en el espacio nunca se queda la bruma ni el cielo de Valmar.
DayLight.StaleZone = 0.6
local ownEnv: EnvZones.Env? = nil
local ownFlags: EnvZones.Flags? = nil
function DayLight.fallbackZone(camPos: Vector3, dt: number): (EnvZones.Env, EnvZones.Flags)
	local target = EnvZones.resolve({ Pos = camPos, Arena = Players.LocalPlayer and Players.LocalPlayer:GetAttribute("AirCombatWorld") == "Arena" })
	ownEnv = EnvZones.approach(ownEnv, target, dt)
	ownFlags = EnvZones.flags(ownEnv :: EnvZones.Env, ownFlags)
	return ownEnv :: EnvZones.Env, ownFlags :: EnvZones.Flags
end
local function zoneFresh(): boolean
	return os.clock() - zoneAt <= DayLight.StaleZone
end
DayLight._zoneFresh = zoneFresh
function DayLight.zone(): (EnvZones.Env?, EnvZones.Flags?)
	return zoneEnv, zoneFlags
end
-- Estrellas del cielo de Roblox: muchas en el espacio (según el nivel gráfico), las de siempre fuera
local originalStars: { StarCount: number, Celestial: boolean }? = nil
local function updateStars(sky: Sky)
	local want = zoneFlags ~= nil and zoneFlags.Stars
	if want then
		if not originalStars then
			originalStars = { StarCount = sky.StarCount, Celestial = sky.CelestialBodiesShown }
		end
		local count = EnvZones.starCount(Perf.tierName())
		if sky.StarCount ~= count then
			sky.StarCount = count
		end
		if not sky.CelestialBodiesShown then
			sky.CelestialBodiesShown = true -- (el sol y su brillo)
		end
	elseif originalStars then
		sky.StarCount = originalStars.StarCount
		sky.CelestialBodiesShown = originalStars.Celestial
		originalStars = nil
	end
end

-- Las caras de los cielos propios del espacio (shared/Cosmos/EspacioLook.Skies: «EspacioProfundo»,
-- «CieloTefra») sacadas AQUÍ de shared/Cosmos/EspacioTextureIds, pasadas por shared/Images (del id del
-- Decal al de su imagen en cuanto el servidor lo sabe). Así el cielo negro del espacio no depende de que
-- el servidor haya dejado su Sky en SkyLibrary con las caras buenas (en v120 se quedaba con los ids de
-- Decal, que no pintan nada, y en el espacio salía el cielo azul de serie: captura del dueño).
local function ownSkyFaces(slot: string): { [string]: string }?
	local ok, faces = pcall(function()
		local Cosmos = ReplicatedStorage.Shared.Cosmos
		local EspacioLook = require(Cosmos.EspacioLook)
		local prefix = EspacioLook.Skies[slot]
		if not prefix then
			return nil
		end
		local ids = require(Cosmos.EspacioTextureIds)
		local okImages, Images = pcall(function()
			return require(ReplicatedStorage.Shared.Images)
		end)
		if okImages and Images and Images.map then
			ids = Images.map(ids)
		end
		return EspacioLook.skyFaces(ids, prefix)
	end)
	return if ok then faces else nil
end
DayLight._ownSkyFaces = ownSkyFaces

-- Las caras de un hueco: las propias (si es un cielo del espacio) o las del Sky de SkyLibrary
local function facesOf(slot: string, library: Instance?): { [string]: string }?
	local own = ownSkyFaces(slot)
	if own then
		return own
	end
	local source = library and library:FindFirstChild(slot)
	if source and source:IsA("Sky") then
		local out = {}
		for _, face in SkyChoice.Faces do
			out[face] = (source :: any)[face]
		end
		return out
	end
	return nil
end

local function signature(faces: { [string]: string }?): string
	if not faces then
		return ""
	end
	local parts = {}
	for _, face in SkyChoice.Faces do
		table.insert(parts, tostring(faces[face]))
	end
	return table.concat(parts, "|")
end

local shownSignature = ""
local function updateSky(hour: number)
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		updateStars(sky)
	end
	local library = ReplicatedStorage:FindFirstChild(SkyChoice.Library)
	local zoneSlots = zoneFlags and zoneFlags.SkySlots
	if not sky or (not library and skyShown == nil and not zoneSlots) then
		return
	end
	local have = {}
	if library then
		for _, item in library:GetChildren() do
			if item:IsA("Sky") then
				have[item.Name] = true
			end
		end
	end
	local want: string? = SkyChoice.pick(hour, have)
	local forced: string? = nil
	-- (la zona primero: en el espacio, el de estrellas; en un planeta, el suyo. Nunca el de Valmar)
	for _, slot in zoneSlots or forcedSky or {} do
		if slot == "Original" or have[slot] or ownSkyFaces(slot) then
			forced = slot
			break
		end
	end
	if forced then
		want = if forced == "Original" then nil else forced
	elseif skyOverride == "Original" then
		want = nil
	elseif skyOverride and have[skyOverride] then
		want = skyOverride
	end
	local faces = if want then facesOf(want, library) else nil
	local sig = signature(faces)
	-- (también si el MISMO cielo cambia de caras: el id del Decal pasa a imagen cuando el servidor lo sabe)
	if want == skyShown and sig == shownSignature then
		return
	end
	if not originalFaces then
		local saved = {}
		for _, face in SkyChoice.Faces do
			saved[face] = (sky :: any)[face]
		end
		originalFaces = saved
	end
	for _, face in SkyChoice.Faces do
		(sky :: any)[face] = if faces then faces[face] else (originalFaces :: any)[face]
	end
	skyShown = want
	shownSignature = sig
end
DayLight._skyShown = function(): string?
	return skyShown
end

---------------------------------------------------------------------

local effects: { [string]: Instance? } = {}
local indoor = 0 -- 0 = fuera, 1 = dentro (va cambiando poco a poco)
local cinematic = 0
local cinematicTarget = 0
local focus: number? = nil -- enfoque de cámara de cine (distancia a lo que se mira); nil = el de siempre
local function find(className: string): any
	local found = effects[className]
	if found and found.Parent then
		return found
	end
	found = if className == "Clouds" then workspace.Terrain:FindFirstChildOfClass("Clouds") else Lighting:FindFirstChildOfClass(className)
	effects[className] = found
	return found
end

-- ¿Hay techo encima de la cámara? (para simular que los ojos se acostumbran dentro de casa)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
-- Solo cuenta como techo lo que choca (brazos de farola, toldos, balcones y copas no chocan)
rayParams.RespectCanCollide = true
local function cameraIndoors(): boolean
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	rayParams.FilterDescendantsInstances = if character then { character } else {}
	local hit = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, 60, 0), rayParams)
	-- Las copas de los árboles no cuentan como techo
	return hit ~= nil and hit.Instance.Transparency < 0.5 and hit.Material ~= Enum.Material.LeafyGrass and hit.Material ~= Enum.Material.Grass
end

-- Cuánto «desde el aire» está la cámara (0 en el suelo, 1 a 600 studs de altura o más). Nunca bajo el
-- agua, con el cielo tapado o sin paisaje lejano (nivel Bajo).
function DayLight.aerial(tier: any, overcast: number): number
	if underwater > 0.01 or not tier.FarRange then
		return 0
	end
	local camera = workspace.CurrentCamera
	local y = if camera then camera.CFrame.Position.Y else 0
	local t = math.clamp((y - 80) / 520, 0, 1)
	return t * t * (3 - 2 * t) * (1 - math.clamp(overcast, 0, 1))
end

-- La bruma de Roblox (Atmosphere) se aparta de Lighting en el espacio y vuelve al bajar. TODAS las que
-- haya (y las que lleguen mientras estás arriba: el servidor o un efecto pueden poner otra): con una sola
-- en Lighting, Roblox pinta debajo del horizonte su color liso (el «suelo azul» de la v121) y vela lo
-- lejano (los planetas desvaídos).
local parkedAtmosphere: Instance? = nil -- (la primera: la que vuelve)
local parkedExtra: { Instance } = {}
local atmosphereOff = false
local function park(atmosphere: Instance)
	if atmosphere == parkedAtmosphere or table.find(parkedExtra, atmosphere) then
		return
	end
	if parkedAtmosphere == nil then
		parkedAtmosphere = atmosphere
	else
		table.insert(parkedExtra, atmosphere)
	end
	pcall(function()
		atmosphere.Parent = nil
	end)
	effects.Atmosphere = nil
end
local function setAtmosphereOn(on: boolean)
	atmosphereOff = not on
	if on then
		local parked = parkedAtmosphere
		if parked then
			parkedAtmosphere = nil
			if not Lighting:FindFirstChildOfClass("Atmosphere") then
				pcall(function()
					parked.Parent = Lighting
				end)
			end
			effects.Atmosphere = nil
		end
		-- (las de más no vuelven: con una basta)
		table.clear(parkedExtra)
	else
		for _, child in Lighting:GetChildren() do
			if child:IsA("Atmosphere") then
				park(child)
			end
		end
	end
end
DayLight.atmosphereParked = function(): boolean
	return parkedAtmosphere ~= nil
end
-- (una bruma que llega mientras estás en el espacio se aparta en el acto, sin esperar a la vuelta)
pcall(function()
	Lighting.ChildAdded:Connect(function(child)
		if atmosphereOff and child:IsA("Atmosphere") then
			task.defer(function()
				if atmosphereOff and child.Parent == Lighting then
					park(child)
				end
			end)
		end
	end)
end)

-- La niebla clásica (Lighting.FogColor / FogEnd) tampoco tiñe nada en el espacio: se guarda y vuelve
local savedFog: { Color: Color3, Start: number, End: number }? = nil
local function setSpaceFog(space: boolean)
	pcall(function()
		if space then
			if not savedFog then
				savedFog = { Color = Lighting.FogColor, Start = Lighting.FogStart, End = Lighting.FogEnd }
			end
			Lighting.FogColor = Color3.new(0, 0, 0)
			Lighting.FogEnd = 100000
			Lighting.FogStart = 100000
		elseif savedFog then
			Lighting.FogColor = savedFog.Color
			Lighting.FogStart = savedFog.Start
			Lighting.FogEnd = savedFog.End
			savedFog = nil
		end
	end)
end

local function apply(k: Key, dt: number)
	local tier = Perf.tier()
	-- Adaptación de los ojos (entrar o salir de casa) y modo cine, poco a poco
	indoor += ((if cameraIndoors() then 1 else 0) - indoor) * math.min(1, dt * 1.5)
	cinematic += (cinematicTarget - cinematic) * math.min(1, dt * 2)

	Lighting.Ambient = k.Ambient
	Lighting.OutdoorAmbient = k.Outdoor
	Lighting.Brightness = k.Brightness
	Lighting.ExposureCompensation = k.Exposure + 0.35 * indoor
	Lighting.EnvironmentDiffuseScale = k.EnvDiffuse
	-- (por nivel: Bajo casi sin reflejos; Alto con sombras más nítidas. Se nota en segundos al cambiar)
	Lighting.EnvironmentSpecularScale = k.EnvSpecular * (tier.Specular or 1)
	Lighting.ShadowSoftness = math.clamp(k.Shadow * (tier.ShadowSharp or 1), 0, 1)
	-- Sol cálido en las caras que mira (y un toque azul en las contrarias): luz con dirección
	if k.SunTint then
		Lighting.ColorShift_Top = k.SunTint
	end
	if k.ShadeTint then
		Lighting.ColorShift_Bottom = k.ShadeTint
	end
	if Lighting.GlobalShadows ~= tier.GlobalShadows then
		Lighting.GlobalShadows = tier.GlobalShadows -- (nivel Bajo: sin sombras del sol, lo que más cuesta)
	end

	-- (en el espacio no hay aire: la bruma de Roblox fuera del todo, no solo a densidad 0 —con ella el
	-- cielo seguía azulado en el horizonte—. Se guarda y vuelve tal cual al bajar)
	setAtmosphereOn(zoneFlags == nil or zoneFlags.Atmosphere)
	setSpaceFog(zoneFlags ~= nil and not zoneFlags.Atmosphere)
	local atmosphere = find("Atmosphere")
	if atmosphere then
		-- (niebla del aire según el nivel: Alto más profunda, Bajo más plana; bajo el agua, la del mar)
		-- (con lluvia, la bruma del tiempo entra entera en todos los niveles: en Bajo se quedaba a la mitad
		-- y el cielo de lluvia seguía azul en el móvil)
		local overcast = k.Overcast or 0
		local haze = if underwater > 0.01 then 1 else DayGrade.lerp(tier.Haze or 1, math.max(tier.Haze or 1, 1), overcast)
		-- Desde el aire (avión, helicóptero, mirador alto) el aire se ve más limpio, como en la referencia
		-- del dueño (paisaje v118): la isla nítida y la bruma solo en el horizonte. Solo con el paisaje
		-- lejano puesto (Medio y Alto: shared/Horizon pinta la isla y el mar más allá de lo cargado);
		-- en Bajo la bruma tapa el borde de lo cargado.
		local aerial = DayLight.aerial(tier, overcast)
		atmosphere.Density = math.clamp(k.Density * haze * (1 - 0.3 * aerial), 0, 1)
		atmosphere.Offset = k.Offset
		atmosphere.Color = k.AtmColor
		atmosphere.Decay = k.Decay
		atmosphere.Glare = k.Glare * math.min(haze, 1.2)
		atmosphere.Haze = math.clamp(k.Haze * haze * (1 - 0.35 * aerial), 0, 10)
	end
	local cc = find("ColorCorrectionEffect")
	if cc then
		local ccOn = zoneFlags == nil or zoneFlags.ColorCorrection
		if cc.Enabled ~= ccOn then
			cc.Enabled = ccOn -- (el etalonaje de Valmar, fuera en el espacio)
		end
		cc.TintColor = k.Tint
		-- (el color del nivel: también se ve en un móvil con la calidad de Roblox baja)
		cc.Saturation = k.Saturation + (tier.Saturation or 0) + 0.04 * cinematic
		cc.Contrast = k.Contrast + (tier.Contrast or 0) + 0.06 * cinematic
		cc.Brightness = k.CCBright
	end
	local bloom = find("BloomEffect")
	if bloom then
		bloom.Intensity = k.Bloom * tier.Bloom * (1 - 0.3 * indoor)
		bloom.Size = k.BloomSize
		bloom.Threshold = k.Threshold
	end
	local rays = find("SunRaysEffect")
	if rays then
		rays.Enabled = tier.SunRays and k.Rays > 0.001
		rays.Intensity = k.Rays
		rays.Spread = k.RaysSpread
	end
	local dof = find("DepthOfFieldEffect")
	if dof and underwater > 0.01 and not focus then
		-- Bajo el agua lo lejano se ve borroso (también en nivel Medio: es parte de verse bajo el agua)
		dof.Enabled = tier.DepthOfField or tier.GlobalShadows
		-- (poco: el mar enorme se tiene que ver a lo lejos, con siluetas una detrás de otra)
		dof.FarIntensity = 0.2 * underwater
		dof.FocusDistance = 24
		dof.InFocusRadius = if seaLook then math.clamp(seaLook.Visibility * 0.4, 24, 80) else 30
		dof.NearIntensity = 0
	elseif dof then
		-- Nivel Alto: un toque de desenfoque muy lejano (como una cámara), más en las cinemáticas;
		-- nada dentro de casa. Nivel Medio: solo en cinemáticas y conversaciones. Bajo: nunca.
		local story = cinematic > 0.02 or focus ~= nil
		dof.Enabled = tier.DepthOfField or (story and tier.GlobalShadows)
		dof.FarIntensity = (0.05 + 0.2 * cinematic) * (1 - indoor)
		dof.FocusDistance = 80 - 50 * cinematic
		dof.InFocusRadius = 170 - 120 * cinematic
		dof.NearIntensity = 0
		if focus then
			-- Primer plano: lo enfocado nítido, el fondo desenfocado (como una cámara de cine)
			dof.FocusDistance = focus
			dof.InFocusRadius = math.max(3, focus * 0.45)
			dof.FarIntensity = math.max(dof.FarIntensity, 0.32 * (1 - 0.6 * indoor))
			dof.NearIntensity = 0.15
		end
	end
	local clouds = find("Clouds")
	local cloudsOn = zoneFlags == nil or zoneFlags.Clouds
	if clouds and clouds.Enabled ~= cloudsOn then
		clouds.Enabled = cloudsOn -- (en el espacio, ni una nube: su mínimo de cobertura es 0,35)
	end
	if clouds and cloudsOn then
		local day = workspace:GetAttribute("Day") or 1
		-- (además, el cielo «respira»: un poco más o menos tapado cada pocos minutos, nunca quieto)
		local drift = 0.035 * math.sin(os.clock() / 75) + 0.02 * math.sin(os.clock() / 31 + 1.3)
		-- (con lluvia el cielo se cierra del todo y las nubes no se recortan por el nivel gráfico)
		local overcast = k.Overcast or 0
		clouds.Cover = math.clamp(k.Cover + dailyClouds(day) * (1 - overcast) + drift, 0.35, 0.88 + 0.1 * overcast)
		clouds.Density = k.CloudDensity * DayGrade.lerp(tier.Clouds, 1, overcast)
		clouds.Color = k.CloudColor
	end
	-- Viento: las nubes van pasando (y las briznas del césped se mecen); más fuerte con tormenta
	local wind = DayGrade.wind(workspace:GetAttribute("Weather"), Lighting.ClockTime)
	pcall(function()
		if (workspace.GlobalWind - wind).Magnitude > 0.2 then
			workspace.GlobalWind = wind
		end
	end)
end

-- La luz calculada para una hora (la usan las pruebas)
DayLight.sample = sample

-- El tiempo (lluvia, nubes, nieve…) cambia la luz de la hora: Controllers/Weather pone aquí una función
-- que recibe la luz calculada y devuelve la luz con el tiempo aplicado.
local modifier: ((Key) -> Key)? = nil
function DayLight.setModifier(fn: ((Key) -> Key)?)
	modifier = fn
end

-- Capas de cielo de la historia (shared/SkyMoods): cambios puntuales ENCIMA de la luz de la hora y del
-- tiempo (no rompen el ciclo del día). Las ponen y quitan las escenas (Controllers/HappeningClient,
-- StoryFx). Cada capa entra y sale con un fundido de `fade` segundos.
type Layer = { Mood: { [string]: any }, W: number, Target: number, Rate: number }
local layers: { [string]: Layer } = {}
-- weight (opcional, 0..1): hasta dónde entra la capa (la Grieta del cielo la sube según lo abierta que
-- esté); sin él, del todo.
function DayLight.pushLayer(id: string, mood: { [string]: any }, fade: number?, weight: number?)
	local layer = layers[id]
	local rate = 1 / math.max(fade or 1, 0.05)
	local target = math.clamp(weight or 1, 0, 1)
	if layer then
		layer.Mood, layer.Target, layer.Rate = mood, target, rate
	else
		layers[id] = { Mood = mood, W = 0, Target = target, Rate = rate }
	end
end
function DayLight.popLayer(id: string, fade: number?)
	local layer = layers[id]
	if layer then
		layer.Target = 0
		layer.Rate = 1 / math.max(fade or 1, 0.05)
	end
end
-- Las capas de cielo puestas ahora mismo (las tablas de shared/SkyMoods, de la más fuerte a la más
-- floja; solo las que ya se notan). Las usa Controllers/SkyExtras para cambiar también el cielo.
function DayLight.activeMoods(): { { [string]: any } }
	local list = {}
	for _, layer in layers do
		if layer.W > 0.25 and layer.Target > 0 then
			table.insert(list, layer)
		end
	end
	table.sort(list, function(a, b)
		return a.W > b.W
	end)
	local out = {}
	for _, layer in list do
		table.insert(out, layer.Mood)
	end
	return out
end
-- Todas las capas puestas y lo que pesan ahora ({ id = 0..1 }): Controllers/Weather aparta el tiempo
-- de Valmar mientras una escena o la Grieta fuerte mandan en el cielo
function DayLight.layerWeights(): { [string]: number }
	local out = {}
	for id, layer in layers do
		out[id] = layer.W
	end
	return out
end
function DayLight.layerWeight(id: string): number
	local layer = layers[id]
	return if layer then layer.W else 0
end
local function applyLayers(k: Key, dt: number): Key
	if next(layers) == nil then
		return k
	end
	local SkyMoods = require(ReplicatedStorage.Shared.SkyMoods)
	for id, layer in layers do
		local step = layer.Rate * dt
		layer.W = if layer.W < layer.Target then math.min(layer.Target, layer.W + step) else math.max(layer.Target, layer.W - step)
		if layer.W <= 0.001 and layer.Target <= 0 then
			layers[id] = nil
		else
			k = SkyMoods.apply(k, layer.Mood, layer.W, DayGrade.mix)
		end
	end
	return k
end

-- Las cinemáticas activan el "modo cine" (Controllers/Cinematics.luau)
function DayLight.setCinematic(on: boolean)
	cinematicTarget = if on then 1 else 0
end

-- Enfoque de cámara (studs hasta lo que se mira): los diálogos y las cinemáticas desenfocan el fondo
function DayLight.setFocus(distance: number?)
	focus = distance
end

function DayLight.init()
	-- La iluminación «Future» (luces con sombras, reflejos) va en el archivo del juego
	-- (default.project.json); desde un script no se puede cambiar: aquí solo se avisa si no está.
	if Lighting.Technology ~= Enum.Technology.Future then
		warn("[DayLight] Lighting.Technology no es Future: revisa default.project.json")
	end
	local since = UPDATE_EVERY
	RunService.RenderStepped:Connect(function(dt)
		since += dt
		if since < UPDATE_EVERY then
			return
		end
		local ok, err = pcall(function()
			-- (sin noticias de EnvDirector: la zona la mira DayLight con la cámara)
			if not zoneFresh() then
				local camera = workspace.CurrentCamera
				if camera then
					local env, flags = DayLight.fallbackZone(camera.CFrame.Position, since)
					if env.Zone == "Arena" then
						zoneEnv, zoneFlags = nil, nil
					else
						zoneEnv, zoneFlags = env, flags
					end
					underwater, seaLook = 0, nil
				end
			end
			local k = sample(Lighting.ClockTime)
			if modifier then
				k = modifier(k)
			end
			k = applyLayers(k, since)
			-- La zona va la última (también bajo el agua): en el espacio y en un planeta, nada de Valmar se
			-- cuela encima
			k = EnvZones.applyKey(k, zoneEnv)
			apply(k, since)
			updateSky(Lighting.ClockTime)
			-- Velo gris del cielo de lluvia (Controllers/RainVeil). Las capas de la historia y los cielos
			-- especiales (sueño, Grieta, lluvia de estrellas) mandan: si hay alguno, el velo se aparta.
			local veil = (k.Veil or 0) * (1 - underwater)
			local strongest = 0
			for _, layer in layers do
				strongest = math.max(strongest, layer.W)
			end
			veil *= 1 - strongest
			if skyOverride and not WEATHER_SKIES[skyOverride] then
				veil = 0
			end
			RainVeil.update(veil, k.VeilColor)
		end)
		since = 0
		if not ok then
			warn("[DayLight] " .. tostring(err))
		end
	end)
end

return DayLight
