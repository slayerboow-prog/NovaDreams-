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
--     de sol y con menos nube; Medio con desenfoque solo en las cinemáticas; Alto con todo.
--   * Las curvas de luz y color (y lo que cambia el tiempo) están en shared/DayGrade: sol cálido con
--     dirección (ColorShift_Top), sombras azuladas, bruma que azula lo lejano y etalonaje suave.
--   * Cielo de fotos (skybox) de día y de noche si el servidor lo ha cargado (shared/SkyChoice,
--     World/SkyLoader): se copian sus caras al Sky de Lighting; si no hay, el cielo de siempre.
--   * Bajo el agua (SeaBiome llama a setUnderwater): bruma verde azulada, colores apagados, menos
--     sol y el fondo desenfocado, como en el mar de verdad.
-- El reloj lo mueve el servidor (WorldService); aquí solo se lee Lighting.ClockTime.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DayGrade = require(ReplicatedStorage.Shared.DayGrade)
local SkyChoice = require(ReplicatedStorage.Shared.SkyChoice)
local Perf = require(script.Parent.Parent.UI.Perf)

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
local function updateSky(hour: number)
	local sky = Lighting:FindFirstChildOfClass("Sky")
	local library = ReplicatedStorage:FindFirstChild(SkyChoice.Library)
	if not sky or (not library and skyShown == nil) then
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
	local want = SkyChoice.pick(hour, have)
	if want == skyShown then
		return
	end
	if not originalFaces then
		local saved = {}
		for _, face in SkyChoice.Faces do
			saved[face] = (sky :: any)[face]
		end
		originalFaces = saved
	end
	local source: any = if want and library then library:FindFirstChild(want) else nil
	for _, face in SkyChoice.Faces do
		(sky :: any)[face] = if source then source[face] else (originalFaces :: any)[face]
	end
	skyShown = want
end

---------------------------------------------------------------------

local effects: { [string]: Instance? } = {}
local indoor = 0 -- 0 = fuera, 1 = dentro (va cambiando poco a poco)
local cinematic = 0
local cinematicTarget = 0
local focus: number? = nil -- enfoque de cámara de cine (distancia a lo que se mira); nil = el de siempre
local underwater = 0 -- 0 = fuera del agua, 1 = la cámara está bajo el agua (lo pone SeaBiome)

-- La luz bajo el agua: la de la hora, pero con bruma del mar, tono verde azulado y menos sol
local function underwaterKey(k: Key): Key
	local out = table.clone(k)
	out.Density = 0.62
	out.Offset = 1
	out.AtmColor = rgb(28, 108, 128):Lerp(k.AtmColor, 0.15)
	out.Decay = rgb(6, 38, 58)
	out.Glare = 0
	out.Haze = 2.6
	out.Tint = rgb(150, 215, 228):Lerp(k.Tint, 0.2)
	out.Saturation = k.Saturation - 0.05
	out.Contrast = k.Contrast + 0.08
	out.CCBright = k.CCBright - 0.03
	out.Exposure = k.Exposure - 0.1
	out.Bloom = k.Bloom * 0.5
	out.Rays = math.max(k.Rays, 0.12)
	out.RaysSpread = 0.9
	return out
end

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
	Lighting.EnvironmentSpecularScale = k.EnvSpecular
	Lighting.ShadowSoftness = k.Shadow
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

	local atmosphere = find("Atmosphere")
	if atmosphere then
		atmosphere.Density = k.Density
		atmosphere.Offset = k.Offset
		atmosphere.Color = k.AtmColor
		atmosphere.Decay = k.Decay
		atmosphere.Glare = k.Glare
		atmosphere.Haze = k.Haze
	end
	local cc = find("ColorCorrectionEffect")
	if cc then
		cc.TintColor = k.Tint
		cc.Saturation = k.Saturation + 0.04 * cinematic
		cc.Contrast = k.Contrast + 0.06 * cinematic
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
		dof.FarIntensity = 0.38 * underwater
		dof.FocusDistance = 14
		dof.InFocusRadius = 26
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
	if clouds then
		local day = workspace:GetAttribute("Day") or 1
		-- (además, el cielo «respira»: un poco más o menos tapado cada pocos minutos, nunca quieto)
		local drift = 0.035 * math.sin(os.clock() / 75) + 0.02 * math.sin(os.clock() / 31 + 1.3)
		clouds.Cover = math.clamp(k.Cover + dailyClouds(day) + drift, 0.35, 0.88)
		clouds.Density = k.CloudDensity * tier.Clouds
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

-- Cuánto está la cámara bajo el agua (0..1): lo pone SeaBiome
function DayLight.setUnderwater(value: number)
	underwater = math.clamp(value, 0, 1)
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
			local k = sample(Lighting.ClockTime)
			if modifier then
				k = modifier(k)
			end
			if underwater > 0.001 then
				k = DayGrade.mix(k, underwaterKey(k), underwater)
			end
			apply(k, since)
			updateSky(Lighting.ClockTime)
		end)
		since = 0
		if not ok then
			warn("[DayLight] " .. tostring(err))
		end
	end)
end

return DayLight
