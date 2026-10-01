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
--   * De día, «ambiente de cine»: sol cálido con dirección (ColorShift), sombras azuladas, bruma que
--     aclara y azula lo lejano (perspectiva aérea), colores algo apagados y algo más de contraste.

local DayGrade = {}

local rgb = Color3.fromRGB

export type Key = { [string]: any }

-- Cómo es la luz a cada hora. Los colores imitan la luz real de la costa mediterránea:
-- amaneceres rosados, mediodía limpio, atardeceres naranjas, hora azul y noche de luna.
--
-- «Ambiente de cine» (v82, queja del dueño: «todo sigue viéndose cutre», cielo de dibujo y luz plana):
--   * Luz del sol cálida y con dirección: SunTint (Lighting.ColorShift_Top, lo que se suma en las caras
--     que mira el sol) y ShadeTint (ColorShift_Bottom, un poco de azul en las caras contrarias).
--   * Sombras con cuerpo: la luz de fuera (Outdoor) baja y algo azulada, como el cielo que las rellena;
--     Brightness y Exposure un poco por debajo de antes para que a mediodía no se queme todo a blanco.
--   * Perspectiva aérea: bruma más densa (Density/Haze) que aclara, apaga y azula lo lejano (sierra,
--     edificios del fondo); lo cercano sigue nítido. Más espesa al amanecer y al atardecer.
--   * Etalonaje suave: de día saturación algo NEGATIVA (la paleta de césped, tejados y coches era chillona)
--     y algo más de contraste; la hora dorada recupera color. Resplandor contenido y rayos de sol sutiles.
--   * Cielo con nubes de verdad: más cobertura y cuerpo de día (ya no hay cielo azul vacío a mediodía).
-- Ambient (la luz de los interiores) no baja de día: si no, dentro de casa era más de noche que de noche.
DayGrade.Keys = {
	{ Hour = 0, Key = { -- noche de luna
		-- La luna (Brightness) da la forma y las sombras; el ambiente de fuera es bajo y no muy azul
		-- (104,116,160 lo aplanaba todo) y la exposición lo compensa: se ve bien y con contraste.
		-- Saturación neutra: las luces cálidas (farolas, ventanas) contrastan con el azul de la luna.
		Ambient = rgb(50, 54, 70), Outdoor = rgb(70, 80, 112), Brightness = 1.7, Exposure = 0.24,
		EnvDiffuse = 0.45, EnvSpecular = 0.8, Shadow = 0.35, SunTint = rgb(0, 6, 18), ShadeTint = rgb(0, 0, 6),
		Density = 0.3, Offset = 0.08, AtmColor = rgb(40, 50, 80), Decay = rgb(16, 20, 38), Glare = 0, Haze = 1.3,
		Tint = rgb(220, 228, 255), Saturation = 0.02, Contrast = 0.17, CCBright = 0.02,
		Bloom = 0.75, BloomSize = 26, Threshold = 1.4, Rays = 0, RaysSpread = 0.5,
		Cover = 0.46, CloudDensity = 0.3, CloudColor = rgb(52, 60, 86),
	} },
	{ Hour = 4.9, Key = { -- antes del alba (azul)
		Ambient = rgb(56, 58, 78), Outdoor = rgb(90, 96, 132), Brightness = 1.45, Exposure = 0.16,
		EnvDiffuse = 0.5, EnvSpecular = 0.7, Shadow = 0.35, SunTint = rgb(4, 8, 24), ShadeTint = rgb(0, 2, 10),
		Density = 0.36, Offset = 0.1, AtmColor = rgb(104, 114, 158), Decay = rgb(58, 58, 96), Glare = 0, Haze = 1.7,
		Tint = rgb(212, 218, 252), Saturation = 0, Contrast = 0.14, CCBright = 0,
		Bloom = 0.65, BloomSize = 24, Threshold = 1.45, Rays = 0, RaysSpread = 0.6,
		Cover = 0.52, CloudDensity = 0.36, CloudColor = rgb(124, 126, 170),
	} },
	{ Hour = 6.0, Key = { -- amanecer
		Ambient = rgb(46, 38, 38), Outdoor = rgb(116, 94, 96), Brightness = 2, Exposure = 0.08,
		EnvDiffuse = 0.85, EnvSpecular = 0.95, Shadow = 0.24, SunTint = rgb(96, 50, 28), ShadeTint = rgb(4, 6, 20),
		Density = 0.4, Offset = 0.15, AtmColor = rgb(255, 190, 152), Decay = rgb(164, 104, 104), Glare = 0.7, Haze = 2,
		Tint = rgb(255, 224, 202), Saturation = 0.08, Contrast = 0.19, CCBright = 0,
		Bloom = 0.5, BloomSize = 26, Threshold = 1.75, Rays = 0.12, RaysSpread = 0.8,
		Cover = 0.58, CloudDensity = 0.46, CloudColor = rgb(255, 188, 160),
	} },
	{ Hour = 6.9, Key = { -- mañana dorada
		Ambient = rgb(42, 37, 35), Outdoor = rgb(100, 94, 100), Brightness = 2.7, Exposure = 0.04,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.2, SunTint = rgb(88, 54, 24), ShadeTint = rgb(6, 10, 24),
		Density = 0.37, Offset = 0.18, AtmColor = rgb(246, 214, 188), Decay = rgb(140, 124, 124), Glare = 0.4, Haze = 1.7,
		Tint = rgb(255, 234, 212), Saturation = 0.05, Contrast = 0.2, CCBright = 0,
		Bloom = 0.36, BloomSize = 22, Threshold = 2.05, Rays = 0.08, RaysSpread = 0.7,
		Cover = 0.58, CloudDensity = 0.48, CloudColor = rgb(255, 230, 210),
	} },
	{ Hour = 8.5, Key = { -- mañana
		Ambient = rgb(58, 58, 64), Outdoor = rgb(74, 80, 96), Brightness = 3.2, Exposure = -0.05,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.18, SunTint = rgb(46, 32, 14), ShadeTint = rgb(8, 12, 24),
		Density = 0.35, Offset = 0.22, AtmColor = rgb(198, 211, 228), Decay = rgb(94, 113, 142), Glare = 0.18, Haze = 1.4,
		Tint = rgb(255, 250, 242), Saturation = -0.05, Contrast = 0.2, CCBright = 0,
		Bloom = 0.26, BloomSize = 20, Threshold = 2.45, Rays = 0.04, RaysSpread = 0.5,
		Cover = 0.58, CloudDensity = 0.5, CloudColor = rgb(252, 251, 248),
	} },
	{ Hour = 12.5, Key = { -- mediodía
		-- Sol alto y fuerte pero sin quemar (Brightness 3,1 y exposición -0,1), sombras azuladas
		-- (Outdoor 70,77,94: antes 92,94,98, casi tan claras como lo soleado) y bruma que azula lo lejano.
		Ambient = rgb(56, 57, 62), Outdoor = rgb(70, 77, 94), Brightness = 3.1, Exposure = -0.1,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.18, SunTint = rgb(40, 30, 16), ShadeTint = rgb(8, 12, 26),
		Density = 0.36, Offset = 0.2, AtmColor = rgb(200, 212, 228), Decay = rgb(96, 116, 146), Glare = 0.15, Haze = 1.5,
		Tint = rgb(255, 250, 244), Saturation = -0.08, Contrast = 0.21, CCBright = 0,
		Bloom = 0.22, BloomSize = 18, Threshold = 2.6, Rays = 0.03, RaysSpread = 0.45,
		Cover = 0.6, CloudDensity = 0.52, CloudColor = rgb(250, 250, 248),
	} },
	{ Hour = 15.5, Key = { -- tarde
		Ambient = rgb(57, 57, 62), Outdoor = rgb(76, 78, 92), Brightness = 3.1, Exposure = -0.06,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.18, SunTint = rgb(58, 38, 18), ShadeTint = rgb(8, 12, 24),
		Density = 0.36, Offset = 0.2, AtmColor = rgb(208, 212, 224), Decay = rgb(104, 114, 136), Glare = 0.2, Haze = 1.55,
		Tint = rgb(255, 246, 234), Saturation = -0.05, Contrast = 0.21, CCBright = 0,
		Bloom = 0.26, BloomSize = 20, Threshold = 2.45, Rays = 0.04, RaysSpread = 0.55,
		Cover = 0.6, CloudDensity = 0.52, CloudColor = rgb(252, 248, 240),
	} },
	{ Hour = 17.2, Key = { -- hora dorada
		Ambient = rgb(46, 38, 34), Outdoor = rgb(122, 94, 76), Brightness = 2.9, Exposure = 0.06,
		EnvDiffuse = 1, EnvSpecular = 1, Shadow = 0.21, SunTint = rgb(120, 62, 22), ShadeTint = rgb(6, 8, 24),
		Density = 0.37, Offset = 0.18, AtmColor = rgb(255, 196, 150), Decay = rgb(168, 112, 92), Glare = 0.6, Haze = 1.9,
		Tint = rgb(255, 222, 186), Saturation = 0.09, Contrast = 0.23, CCBright = 0,
		Bloom = 0.42, BloomSize = 24, Threshold = 1.9, Rays = 0.12, RaysSpread = 0.8,
		Cover = 0.6, CloudDensity = 0.5, CloudColor = rgb(255, 206, 166),
	} },
	{ Hour = 18.0, Key = { -- puesta de sol
		Ambient = rgb(54, 38, 38), Outdoor = rgb(124, 84, 80), Brightness = 2, Exposure = 0.16,
		EnvDiffuse = 0.85, EnvSpecular = 0.9, Shadow = 0.25, SunTint = rgb(128, 52, 30), ShadeTint = rgb(6, 6, 24),
		Density = 0.39, Offset = 0.15, AtmColor = rgb(255, 162, 124), Decay = rgb(172, 90, 96), Glare = 0.9, Haze = 2.2,
		Tint = rgb(255, 210, 182), Saturation = 0.1, Contrast = 0.22, CCBright = 0,
		Bloom = 0.55, BloomSize = 28, Threshold = 1.65, Rays = 0.16, RaysSpread = 0.9,
		Cover = 0.6, CloudDensity = 0.5, CloudColor = rgb(255, 150, 118),
	} },
	{ Hour = 18.8, Key = { -- hora azul
		Ambient = rgb(46, 46, 64), Outdoor = rgb(84, 86, 122), Brightness = 1.3, Exposure = 0.12,
		EnvDiffuse = 0.55, EnvSpecular = 0.75, Shadow = 0.35, SunTint = rgb(10, 10, 30), ShadeTint = rgb(0, 2, 12),
		Density = 0.36, Offset = 0.12, AtmColor = rgb(110, 112, 168), Decay = rgb(64, 56, 108), Glare = 0.1, Haze = 1.8,
		Tint = rgb(218, 214, 255), Saturation = 0.02, Contrast = 0.16, CCBright = 0,
		Bloom = 0.75, BloomSize = 26, Threshold = 1.4, Rays = 0, RaysSpread = 0.6,
		Cover = 0.54, CloudDensity = 0.38, CloudColor = rgb(118, 112, 162),
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
	-- (con tormenta no se llega a blanco y negro: tope de -0,3)
	out.Saturation = math.max(-0.3, k.Saturation + (info.Saturation or 0))
	out.Density = math.clamp(k.Density + (info.Density or 0), 0, 0.8)
	out.Haze = k.Haze + 0.9 * overcast + 0.6 * rainy + (if (info.Density or 0) > 0.2 then 1.2 else 0)
	out.Glare = k.Glare * (1 - overcast)
	out.Rays = k.Rays * (1 - overcast)
	out.Shadow = math.min(1, k.Shadow + 0.45 * overcast) -- con el cielo tapado, sombras suaves
	-- Con el sol tapado no hay luz cálida directa ni sombras azuladas: luz gris y difusa
	local black = Color3.new(0, 0, 0)
	if k.SunTint then
		out.SunTint = k.SunTint:Lerp(black, math.min(1, 0.85 * overcast + 0.5 * rainy))
	end
	if k.ShadeTint then
		out.ShadeTint = k.ShadeTint:Lerp(black, 0.7 * overcast)
	end
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
