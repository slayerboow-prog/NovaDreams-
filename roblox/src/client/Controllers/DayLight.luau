-- DayLight (cliente): la luz del día pintada en el dispositivo de cada jugador, para que parezca real.
--
--   * 11 momentos del día (noche, antes del alba, amanecer, mañana dorada, mañana, mediodía, tarde,
--     hora dorada, puesta de sol, hora azul) con la luz, el cielo, la bruma, las nubes y el color de cada uno.
--     Entre uno y otro se pasa poco a poco.
--   * Cada día de juego trae más o menos nubes (igual para todos los jugadores del servidor).
--   * Los ojos se acostumbran: dentro de casa la imagen se aclara un poco, como una cámara de verdad.
--   * En las cinemáticas, enfoque de cine (el fondo se desenfoca un poco) y algo más de contraste.
--   * En dispositivos con calidad gráfica baja se quitan los efectos más caros (desenfoque, rayos de sol).
-- El reloj lo mueve el servidor (WorldService); aquí solo se lee Lighting.ClockTime.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DayLight = {}

local rgb = Color3.fromRGB
local UPDATE_EVERY = 0.1 -- segundos entre actualizaciones (10 veces por segundo es suficiente)

type Key = { [string]: any }

-- Cómo es la luz a cada hora. Los colores imitan la luz real de la costa mediterránea:
-- (De día la luz ambiente es baja y el sol fuerte: así las sombras tienen cuerpo y la ciudad no se ve plana.
--  La luz del cielo la pone EnvironmentDiffuse; la bruma es la justa para dar distancia sin lavar los colores.)
-- amaneceres rosados, mediodía blanco y limpio, atardeceres naranjas, hora azul y noche de luna.
local KEYS: { { Hour: number, Key: Key } } = {
	{ Hour = 0, Key = { -- noche de luna
		-- (más clara que antes: de noche se tiene que poder jugar y ver la ciudad, con luz de luna azulada)
		Ambient = rgb(62, 68, 94), Outdoor = rgb(104, 116, 160), Brightness = 1.25, Exposure = 0.12,
		EnvDiffuse = 0.55, EnvSpecular = 0.6, Shadow = 0.3,
		Density = 0.33, Offset = 0.1, AtmColor = rgb(60, 72, 102), Decay = rgb(22, 26, 44), Glare = 0, Haze = 1,
		Tint = rgb(206, 216, 255), Saturation = -0.1, Contrast = 0.06, CCBright = 0.03,
		Bloom = 0.9, BloomSize = 28, Threshold = 1.2, Rays = 0, RaysSpread = 0.5,
		Cover = 0.5, CloudDensity = 0.28, CloudColor = rgb(66, 74, 98),
	} },
	{ Hour = 4.9, Key = { -- antes del alba (azul)
		Ambient = rgb(64, 68, 94), Outdoor = rgb(110, 118, 160), Brightness = 1.3, Exposure = 0.1,
		EnvDiffuse = 0.5, EnvSpecular = 0.6, Shadow = 0.35,
		Density = 0.36, Offset = 0.1, AtmColor = rgb(110, 120, 162), Decay = rgb(60, 60, 96), Glare = 0, Haze = 1.5,
		Tint = rgb(206, 212, 252), Saturation = -0.08, Contrast = 0.1, CCBright = 0,
		Bloom = 0.7, BloomSize = 24, Threshold = 1.4, Rays = 0, RaysSpread = 0.6,
		Cover = 0.5, CloudDensity = 0.3, CloudColor = rgb(120, 126, 162),
	} },
	{ Hour = 6.0, Key = { -- amanecer
		Ambient = rgb(43, 34, 34), Outdoor = rgb(130, 98, 90), Brightness = 2, Exposure = 0.05,
		EnvDiffuse = 0.8, EnvSpecular = 0.9, Shadow = 0.25,
		Density = 0.38, Offset = 0.15, AtmColor = rgb(255, 190, 150), Decay = rgb(172, 102, 92), Glare = 0.6, Haze = 1.65,
		Tint = rgb(255, 226, 206), Saturation = 0.1, Contrast = 0.16, CCBright = 0,
		Bloom = 0.55, BloomSize = 26, Threshold = 1.7, Rays = 0.12, RaysSpread = 0.8,
		Cover = 0.5, CloudDensity = 0.34, CloudColor = rgb(255, 198, 170),
	} },
	{ Hour = 6.9, Key = { -- mañana dorada
		Ambient = rgb(36, 32, 31), Outdoor = rgb(115, 101, 91), Brightness = 2.7, Exposure = 0.1,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.18,
		Density = 0.32, Offset = 0.2, AtmColor = rgb(250, 216, 186), Decay = rgb(152, 122, 110), Glare = 0.35, Haze = 1.12,
		Tint = rgb(255, 238, 220), Saturation = 0.12, Contrast = 0.15, CCBright = 0,
		Bloom = 0.4, BloomSize = 22, Threshold = 2, Rays = 0.08, RaysSpread = 0.7,
		Cover = 0.45, CloudDensity = 0.32, CloudColor = rgb(255, 236, 222),
	} },
	{ Hour = 8.5, Key = { -- mañana
		Ambient = rgb(30, 31, 34), Outdoor = rgb(90, 92, 99), Brightness = 3.4, Exposure = 0.08,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.12,
		Density = 0.28, Offset = 0.25, AtmColor = rgb(200, 212, 228), Decay = rgb(100, 120, 146), Glare = 0.1, Haze = 0.78,
		Tint = rgb(255, 250, 245), Saturation = 0.1, Contrast = 0.14, CCBright = 0,
		Bloom = 0.3, BloomSize = 20, Threshold = 2.4, Rays = 0.05, RaysSpread = 0.6,
		Cover = 0.42, CloudDensity = 0.3, CloudColor = rgb(255, 255, 255),
	} },
	{ Hour = 12.5, Key = { -- mediodía
		Ambient = rgb(32, 32, 34), Outdoor = rgb(92, 94, 98), Brightness = 3.6, Exposure = 0,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.1,
		Density = 0.26, Offset = 0.25, AtmColor = rgb(199, 213, 230), Decay = rgb(106, 125, 150), Glare = 0, Haze = 0.6,
		Tint = rgb(255, 252, 248), Saturation = 0.08, Contrast = 0.14, CCBright = 0,
		Bloom = 0.25, BloomSize = 18, Threshold = 2.6, Rays = 0.04, RaysSpread = 0.5,
		Cover = 0.4, CloudDensity = 0.3, CloudColor = rgb(255, 255, 255),
	} },
	{ Hour = 15.5, Key = { -- tarde
		Ambient = rgb(32, 32, 33), Outdoor = rgb(95, 92, 94), Brightness = 3.4, Exposure = 0.05,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.12,
		Density = 0.27, Offset = 0.25, AtmColor = rgb(210, 214, 222), Decay = rgb(115, 120, 138), Glare = 0.1, Haze = 0.72,
		Tint = rgb(255, 248, 238), Saturation = 0.1, Contrast = 0.15, CCBright = 0,
		Bloom = 0.28, BloomSize = 20, Threshold = 2.4, Rays = 0.05, RaysSpread = 0.6,
		Cover = 0.42, CloudDensity = 0.31, CloudColor = rgb(255, 252, 246),
	} },
	{ Hour = 17.2, Key = { -- hora dorada
		Ambient = rgb(43, 35, 31), Outdoor = rgb(122, 99, 81), Brightness = 2.9, Exposure = 0.15,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.18,
		Density = 0.3, Offset = 0.2, AtmColor = rgb(255, 205, 160), Decay = rgb(170, 120, 96), Glare = 0.5, Haze = 1.26,
		Tint = rgb(255, 228, 196), Saturation = 0.18, Contrast = 0.17, CCBright = 0,
		Bloom = 0.45, BloomSize = 24, Threshold = 1.9, Rays = 0.12, RaysSpread = 0.8,
		Cover = 0.46, CloudDensity = 0.34, CloudColor = rgb(255, 222, 190),
	} },
	{ Hour = 18.0, Key = { -- puesta de sol
		Ambient = rgb(54, 37, 37), Outdoor = rgb(136, 88, 80), Brightness = 2, Exposure = 0.2,
		EnvDiffuse = 0.85, EnvSpecular = 0.9, Shadow = 0.25,
		Density = 0.36, Offset = 0.15, AtmColor = rgb(255, 160, 120), Decay = rgb(180, 90, 92), Glare = 0.9, Haze = 1.95,
		Tint = rgb(255, 210, 186), Saturation = 0.22, Contrast = 0.18, CCBright = 0,
		Bloom = 0.6, BloomSize = 28, Threshold = 1.6, Rays = 0.18, RaysSpread = 0.9,
		Cover = 0.5, CloudDensity = 0.38, CloudColor = rgb(255, 168, 140),
	} },
	{ Hour = 18.8, Key = { -- hora azul
		Ambient = rgb(44, 44, 64), Outdoor = rgb(86, 86, 122), Brightness = 1.1, Exposure = 0.05,
		EnvDiffuse = 0.55, EnvSpecular = 0.7, Shadow = 0.35,
		Density = 0.36, Offset = 0.12, AtmColor = rgb(120, 120, 172), Decay = rgb(70, 60, 112), Glare = 0.1, Haze = 1.8,
		Tint = rgb(216, 212, 255), Saturation = 0.02, Contrast = 0.14, CCBright = 0,
		Bloom = 0.8, BloomSize = 26, Threshold = 1.35, Rays = 0, RaysSpread = 0.6,
		Cover = 0.5, CloudDensity = 0.32, CloudColor = rgb(120, 116, 162),
	} },
	{ Hour = 19.9, Key = nil :: any }, -- se rellena abajo con la noche (vuelta al principio)
}
KEYS[#KEYS].Key = KEYS[1].Key

local function lerp(a: any, b: any, t: number): any
	if typeof(a) == "Color3" then
		return (a :: Color3):Lerp(b, t)
	end
	return a + (b - a) * t
end

-- Suaviza la mezcla entre dos momentos (sin cambios bruscos al pasar de uno a otro)
local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

local function sample(hour: number): Key
	for i = 1, #KEYS - 1 do
		local a, b = KEYS[i], KEYS[i + 1]
		if hour >= a.Hour and hour < b.Hour then
			local t = smooth((hour - a.Hour) / (b.Hour - a.Hour))
			local out = {}
			for name, value in a.Key do
				out[name] = lerp(value, b.Key[name], t)
			end
			return out
		end
	end
	return KEYS[1].Key -- de 19.9 a 24: noche
end

-- Nubes del día: cada día de juego es un poco distinto (igual para todo el servidor)
local function dailyClouds(day: number): number
	local x = math.sin(day * 12.9898) * 43758.5453
	return (x - math.floor(x) - 0.5) * 0.3 -- entre -0.15 y +0.15
end

---------------------------------------------------------------------

local effects: { [string]: Instance? } = {}
local indoor = 0 -- 0 = fuera, 1 = dentro (va cambiando poco a poco)
local cinematic = 0
local cinematicTarget = 0
local lowQuality = false

local function find(className: string): any
	local found = effects[className]
	if found and found.Parent then
		return found
	end
	found = if className == "Clouds" then workspace.Terrain:FindFirstChildOfClass("Clouds") else Lighting:FindFirstChildOfClass(className)
	effects[className] = found
	return found
end

local function readQuality()
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	-- "Automático" cuenta como calidad media; de 1 a 4, calidad baja
	lowQuality = ok and level ~= Enum.SavedQualitySetting.Automatic and level.Value <= 4
end

-- ¿Hay techo encima de la cámara? (para simular que los ojos se acostumbran dentro de casa)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function cameraIndoors(): boolean
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	rayParams.FilterDescendantsInstances = if character then { character } else {}
	local hit = workspace:Raycast(camera.CFrame.Position, Vector3.new(0, 60, 0), rayParams)
	-- Las copas de los árboles no cuentan como techo
	return hit ~= nil and hit.Instance.Transparency < 0.5 and hit.Material ~= Enum.Material.LeafyGrass and hit.Material ~= Enum.Material.Grass
end

local function apply(k: Key, dt: number)
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
		bloom.Intensity = k.Bloom * (1 - 0.3 * indoor)
		bloom.Size = k.BloomSize
		bloom.Threshold = k.Threshold
	end
	local rays = find("SunRaysEffect")
	if rays then
		rays.Enabled = not lowQuality
		rays.Intensity = k.Rays
		rays.Spread = k.RaysSpread
	end
	local dof = find("DepthOfFieldEffect")
	if dof then
		-- Un poco de desenfoque a lo lejos (como una cámara), más en las cinemáticas; nada dentro de casa
		dof.Enabled = not lowQuality
		dof.FarIntensity = (0.06 + 0.2 * cinematic) * (1 - indoor)
		dof.FocusDistance = 60 - 30 * cinematic
		dof.InFocusRadius = 140 - 90 * cinematic
		dof.NearIntensity = 0
	end
	local clouds = find("Clouds")
	if clouds then
		local day = workspace:GetAttribute("Day") or 1
		clouds.Cover = math.clamp(k.Cover + dailyClouds(day), 0.2, 0.8)
		clouds.Density = if lowQuality then k.CloudDensity * 0.6 else k.CloudDensity
		clouds.Color = k.CloudColor
	end
end

-- La luz calculada para una hora (la usan las pruebas)
DayLight.sample = sample

-- El tiempo (lluvia, nubes, nieve…) cambia la luz de la hora: Controllers/Weather pone aquí una función
-- que recibe la luz calculada y devuelve la luz con el tiempo aplicado.
local modifier: ((Key) -> Key)? = nil
function DayLight.setModifier(fn: ((Key) -> Key)?)
	modifier = fn
end

-- Las cinemáticas activan el "modo cine" (Controllers/Cinematics.luau)
function DayLight.setCinematic(on: boolean)
	cinematicTarget = if on then 1 else 0
end

function DayLight.init()
	readQuality()
	pcall(function()
		UserSettings():GetService("UserGameSettings"):GetPropertyChangedSignal("SavedQualityLevel"):Connect(readQuality)
	end)
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
			apply(k, since)
		end)
		since = 0
		if not ok then
			warn("[DayLight] " .. tostring(err))
		end
	end)
end

return DayLight
