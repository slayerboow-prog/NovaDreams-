-- DayGrade: la luz y el color de cada hora del día y cómo los cambia el tiempo. Cuentas puras (las
-- pinta client/Controllers/DayLight; se prueban fuera de Roblox: scripts/test-graphics.luau).
--
--   * 11 momentos del día (noche, antes del alba, amanecer, mañana dorada, mañana, mediodía, tarde,
--     hora dorada, puesta de sol, hora azul) con la luz, el cielo, la bruma, las nubes y el «etalonaje»
--     (color de la imagen) de cada uno. Entre uno y otro se pasa poco a poco y sin saltos.
--   * La noche: luz de luna azulada que modela (sombras de luna) y un ambiente más bajo y neutro, con
--     contraste: así las farolas cálidas, las ventanas y los carteles destacan sobre el azul (antes la
--     noche era un azul marino plano, todo del mismo tono).
--   * El tiempo encima: lluvia y tormenta apagan el color y lo enfrían, quitan el resplandor del sol y
--     suben la bruma; con el suelo mojado los reflejos del entorno brillan más; la niebla cierra la
--     distancia; la nieve aclara y enfría. Con lluvia las nubes se hacen gruesas y oscuras.
--   * El viento (DayGrade.wind) mueve las nubes y las briznas del césped.

local DayGrade = {}

local rgb = Color3.fromRGB

export type Key = { [string]: any }

-- Cómo es la luz a cada hora. Los colores imitan la luz real de la costa mediterránea:
-- amaneceres rosados, mediodía blanco y limpio, atardeceres naranjas, hora azul y noche de luna.
-- (De día el sol es fuerte y la luz de fuera (Outdoor) baja: así las sombras tienen cuerpo y la ciudad no se
--  ve plana. Ambient (la luz de los interiores) no baja de día: si no, dentro de casa era más de noche que de
--  noche. La luz del cielo la pone EnvironmentDiffuse; la bruma es la justa para dar distancia.)
DayGrade.Keys = {
	{ Hour = 0, Key = { -- noche de luna
		-- La luna (Brightness) da la forma y las sombras; el ambiente de fuera es más bajo y menos azul
		-- que antes (104,116,160 lo aplanaba todo) y la exposición lo compensa: se ve bien y con contraste.
		-- Saturación neutra: las luces cálidas (farolas, ventanas) contrastan con el azul de la luna.
		Ambient = rgb(50, 54, 70), Outdoor = rgb(70, 80, 112), Brightness = 1.7, Exposure = 0.24,
		EnvDiffuse = 0.45, EnvSpecular = 0.8, Shadow = 0.35,
		Density = 0.27, Offset = 0.08, AtmColor = rgb(40, 50, 80), Decay = rgb(16, 20, 38), Glare = 0, Haze = 1.15,
		Tint = rgb(220, 228, 255), Saturation = 0.02, Contrast = 0.17, CCBright = 0.02,
		Bloom = 0.75, BloomSize = 26, Threshold = 1.4, Rays = 0, RaysSpread = 0.5,
		Cover = 0.46, CloudDensity = 0.26, CloudColor = rgb(52, 60, 86),
	} },
	{ Hour = 4.9, Key = { -- antes del alba (azul)
		Ambient = rgb(56, 58, 78), Outdoor = rgb(90, 96, 132), Brightness = 1.45, Exposure = 0.16,
		EnvDiffuse = 0.5, EnvSpecular = 0.7, Shadow = 0.35,
		Density = 0.33, Offset = 0.1, AtmColor = rgb(104, 114, 158), Decay = rgb(58, 58, 96), Glare = 0, Haze = 1.45,
		Tint = rgb(212, 218, 252), Saturation = 0, Contrast = 0.13, CCBright = 0,
		Bloom = 0.65, BloomSize = 24, Threshold = 1.45, Rays = 0, RaysSpread = 0.6,
		Cover = 0.5, CloudDensity = 0.32, CloudColor = rgb(124, 126, 170),
	} },
	{ Hour = 6.0, Key = { -- amanecer
		Ambient = rgb(46, 38, 38), Outdoor = rgb(132, 100, 92), Brightness = 2, Exposure = 0.08,
		EnvDiffuse = 0.8, EnvSpecular = 0.9, Shadow = 0.25,
		Density = 0.37, Offset = 0.15, AtmColor = rgb(255, 190, 150), Decay = rgb(172, 102, 92), Glare = 0.7, Haze = 1.6,
		Tint = rgb(255, 222, 198), Saturation = 0.14, Contrast = 0.17, CCBright = 0,
		Bloom = 0.55, BloomSize = 26, Threshold = 1.7, Rays = 0.14, RaysSpread = 0.8,
		Cover = 0.54, CloudDensity = 0.4, CloudColor = rgb(255, 188, 160),
	} },
	{ Hour = 6.9, Key = { -- mañana dorada
		Ambient = rgb(40, 35, 33), Outdoor = rgb(120, 102, 88), Brightness = 2.7, Exposure = 0.1,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.21,
		Density = 0.31, Offset = 0.2, AtmColor = rgb(250, 216, 186), Decay = rgb(152, 122, 110), Glare = 0.35, Haze = 1.1,
		Tint = rgb(255, 232, 208), Saturation = 0.16, Contrast = 0.17, CCBright = 0,
		Bloom = 0.4, BloomSize = 22, Threshold = 2, Rays = 0.09, RaysSpread = 0.7,
		Cover = 0.5, CloudDensity = 0.4, CloudColor = rgb(255, 228, 206),
	} },
	{ Hour = 8.5, Key = { -- mañana
		Ambient = rgb(62, 62, 66), Outdoor = rgb(90, 92, 99), Brightness = 3.4, Exposure = 0.08,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.19,
		Density = 0.28, Offset = 0.25, AtmColor = rgb(200, 212, 228), Decay = rgb(100, 120, 146), Glare = 0.1, Haze = 0.78,
		Tint = rgb(255, 250, 245), Saturation = 0.12, Contrast = 0.16, CCBright = 0,
		Bloom = 0.3, BloomSize = 20, Threshold = 2.4, Rays = 0.05, RaysSpread = 0.6,
		Cover = 0.47, CloudDensity = 0.4, CloudColor = rgb(255, 255, 255),
	} },
	{ Hour = 12.5, Key = { -- mediodía
		Ambient = rgb(62, 62, 66), Outdoor = rgb(92, 94, 98), Brightness = 3.6, Exposure = 0,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.18,
		Density = 0.26, Offset = 0.25, AtmColor = rgb(199, 213, 230), Decay = rgb(106, 125, 150), Glare = 0, Haze = 0.6,
		Tint = rgb(255, 252, 248), Saturation = 0.1, Contrast = 0.16, CCBright = 0,
		Bloom = 0.25, BloomSize = 18, Threshold = 2.6, Rays = 0.04, RaysSpread = 0.5,
		Cover = 0.45, CloudDensity = 0.4, CloudColor = rgb(255, 255, 255),
	} },
	{ Hour = 15.5, Key = { -- tarde
		Ambient = rgb(62, 62, 66), Outdoor = rgb(95, 92, 94), Brightness = 3.4, Exposure = 0.05,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.19,
		Density = 0.27, Offset = 0.25, AtmColor = rgb(210, 214, 222), Decay = rgb(115, 120, 138), Glare = 0.1, Haze = 0.72,
		Tint = rgb(255, 248, 238), Saturation = 0.12, Contrast = 0.17, CCBright = 0,
		Bloom = 0.28, BloomSize = 20, Threshold = 2.4, Rays = 0.05, RaysSpread = 0.6,
		Cover = 0.48, CloudDensity = 0.42, CloudColor = rgb(255, 252, 246),
	} },
	{ Hour = 17.2, Key = { -- hora dorada
		Ambient = rgb(46, 37, 32), Outdoor = rgb(132, 100, 76), Brightness = 3, Exposure = 0.14,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.22,
		Density = 0.3, Offset = 0.2, AtmColor = rgb(255, 198, 148), Decay = rgb(178, 116, 86), Glare = 0.65, Haze = 1.3,
		Tint = rgb(255, 220, 180), Saturation = 0.23, Contrast = 0.2, CCBright = 0,
		Bloom = 0.5, BloomSize = 24, Threshold = 1.85, Rays = 0.16, RaysSpread = 0.85,
		Cover = 0.53, CloudDensity = 0.45, CloudColor = rgb(255, 212, 172),
	} },
	{ Hour = 18.0, Key = { -- puesta de sol
		Ambient = rgb(54, 38, 38), Outdoor = rgb(136, 88, 80), Brightness = 2, Exposure = 0.2,
		EnvDiffuse = 0.85, EnvSpecular = 0.9, Shadow = 0.25,
		Density = 0.35, Offset = 0.15, AtmColor = rgb(255, 160, 120), Decay = rgb(180, 90, 92), Glare = 1, Haze = 1.9,
		Tint = rgb(255, 206, 176), Saturation = 0.24, Contrast = 0.19, CCBright = 0,
		Bloom = 0.6, BloomSize = 28, Threshold = 1.6, Rays = 0.2, RaysSpread = 0.9,
		Cover = 0.56, CloudDensity = 0.46, CloudColor = rgb(255, 150, 118),
	} },
	{ Hour = 18.8, Key = { -- hora azul
		Ambient = rgb(46, 46, 64), Outdoor = rgb(84, 86, 122), Brightness = 1.3, Exposure = 0.12,
		EnvDiffuse = 0.55, EnvSpecular = 0.75, Shadow = 0.35,
		Density = 0.33, Offset = 0.12, AtmColor = rgb(110, 112, 168), Decay = rgb(64, 56, 108), Glare = 0.1, Haze = 1.6,
		Tint = rgb(218, 214, 255), Saturation = 0.06, Contrast = 0.15, CCBright = 0,
		Bloom = 0.75, BloomSize = 26, Threshold = 1.4, Rays = 0, RaysSpread = 0.6,
		Cover = 0.5, CloudDensity = 0.34, CloudColor = rgb(118, 112, 162),
	} },
	{ Hour = 19.9, Key = nil :: any }, -- se rellena abajo con la noche (vuelta al principio)
}
local KEYS = DayGrade.Keys
KEYS[#KEYS].Key = KEYS[1].Key

function DayGrade.lerp(a: any, b: any, t: number): any
	if typeof(a) == "Color3" then
		return (a :: Color3):Lerp(b, t)
	end
	return a + (b - a) * t
end
local lerp = DayGrade.lerp

-- Suaviza la mezcla entre dos momentos (sin cambios bruscos al pasar de uno a otro)
local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

function DayGrade.sample(hour: number): Key
	hour = hour % 24
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
	return table.clone(KEYS[1].Key) -- de 19.9 a 24: noche
end

-- Mezcla dos luces enteras (bajo el agua, etc.)
function DayGrade.mix(a: Key, b: Key, t: number): Key
	local out = {}
	for name, value in a do
		out[name] = if b[name] ~= nil then lerp(value, b[name], t) else value
	end
	return out
end

-- ¿Cuánto es de noche? (0 = día, 1 = noche cerrada): sale del brillo de la hora
function DayGrade.nightness(k: Key): number
	return math.clamp((2.6 - (k.Brightness or 3)) / 0.9, 0, 1)
end

local function grey(c: Color3, amount: number): Color3
	local l = c.R * 0.3 + c.G * 0.59 + c.B * 0.11
	return c:Lerp(Color3.new(l, l, math.min(1, l * 1.04)), amount)
end

-- El tiempo encima de la luz de la hora.
--   info: Seasons.Weather[…] (Brightness, Saturation, Density, Cover, Rain, Snow, Lightning)
--   season: Seasons.Info[…] (Warm, Cold) o nil
--   flash: relámpago (0..1); wet: cuánto está mojado el suelo (0..1, workspace "Wet")
function DayGrade.weather(k: Key, info: { [string]: any }, season: { [string]: any }?, flash: number, wet: number): Key
	local out = table.clone(k)
	local rain = math.clamp(info.Rain or 0, 0, 1.7)
	local rainy = math.min(rain, 1)
	local cover = if info.Cover then info.Cover else 0
	-- Nubes tapando: menos sol (y sin rayos ni deslumbre), más bruma
	local overcast = math.clamp((cover - 0.5) / 0.45, 0, 1)
	out.Brightness = k.Brightness * (info.Brightness or 1) + flash * 4
	out.Exposure = k.Exposure + flash * 0.6
	out.Saturation = k.Saturation + (info.Saturation or 0)
	out.Density = math.clamp(k.Density + (info.Density or 0), 0, 0.8)
	out.Haze = k.Haze + 0.9 * overcast + 0.6 * rainy + (if (info.Density or 0) > 0.2 then 1.2 else 0)
	out.Glare = k.Glare * (1 - overcast)
	out.Rays = k.Rays * (1 - overcast)
	out.Shadow = math.min(1, k.Shadow + 0.45 * overcast) -- con el cielo tapado, sombras suaves
	out.AtmColor = grey(k.AtmColor, 0.55 * overcast)
	out.Decay = grey(k.Decay, 0.45 * overcast)
	if info.Cover then
		out.Cover = math.max(k.Cover, info.Cover)
		out.CloudColor = k.CloudColor:Lerp(rgb(110, 114, 124), rainy * 0.5 + (if info.Lightning then 0.2 else 0))
		-- Con lluvia las nubes son más gruesas (panza oscura); con tormenta, aún más
		out.CloudDensity = math.min(0.85, k.CloudDensity + 0.22 * rainy + (if info.Lightning then 0.12 else 0))
	end
	season = season or {}
	if season.Warm then
		out.Tint = k.Tint:Lerp(rgb(255, 236, 214), season.Warm)
	elseif season.Cold then
		out.Tint = k.Tint:Lerp(rgb(220, 232, 255), season.Cold)
	end
	if rainy > 0 then
		-- Lluvia: imagen fría, gris y algo menos contrastada (se nota la humedad)
		out.Tint = out.Tint:Lerp(rgb(208, 218, 236), 0.3 * rainy)
		out.Contrast = k.Contrast - 0.03 * rainy
	end
	if info.Snow then
		out.Tint = out.Tint:Lerp(rgb(232, 240, 255), 0.35)
		out.Exposure += 0.05
	end
	-- Suelo mojado: el asfalto refleja el cielo y las luces (más reflejo, menos luz difusa) y,
	-- de noche, las farolas resplandecen un poco más sobre el agua
	wet = math.clamp(wet or 0, 0, 1)
	out.EnvSpecular = math.min(1, k.EnvSpecular + 0.5 * wet)
	out.EnvDiffuse = k.EnvDiffuse * (1 - 0.15 * wet)
	out.Bloom = k.Bloom + 0.15 * wet * DayGrade.nightness(k)
	return out
end

-- Viento para las nubes (workspace.GlobalWind: las nubes van pasando; con el césped 3D, las briznas
-- se mecen). Fuerza según el tiempo y dirección que gira despacio a lo largo del día de juego.
local WIND = { Despejado = 6, Nublado = 10, Lluvia = 14, Nieve = 9, Tormenta = 26, Niebla = 2 }
function DayGrade.wind(weather: string?, hour: number): Vector3
	local speed = WIND[weather or "Despejado"] or 7
	local a = 0.6 + math.sin(hour / 24 * math.pi * 2) * 0.5 -- (sopla sobre todo del mar, del suroeste)
	return Vector3.new(math.cos(a) * speed, 0, math.sin(a) * speed)
end

return DayGrade
