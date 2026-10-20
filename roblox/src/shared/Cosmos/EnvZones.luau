-- EnvZones: QUÉ CIELO Y QUÉ LUZ toca según dónde está la cámara de cada jugador (cuentas puras;
-- docs/espacio-aaa/entorno.md). Lo pinta UN solo dueño en el cliente (Controllers/EnvDirector →
-- Controllers/DayLight): antes lo tocaban a la vez DayLight, la Grieta (SkyRift), el tiempo (Weather),
-- el espacio (SpaceClient), los planetas (PlanetClient) y la arena (AirCombatClient), cada uno con su
-- interruptor, y el último que hablaba ganaba: en el espacio se veía el cielo azul de Valmar con nubes
-- y bruma, y en Tefra el cielo de Valmar con la Grieta (vídeo del dueño en v117, docs/bugs/video-tefra).
--
-- Zonas (cada jugador la suya: cada uno puede estar en un sitio distinto):
--   "Valmar"      el suelo y el cielo de los aviones (hasta Layers.TransitionY): la luz de la hora, el
--                 tiempo, las nubes, la Grieta… (DayLight, con el aire limpio desde el avión: aerial).
--   "Transicion"  de TransitionY a SpaceY: se funde poco a poco hacia el espacio (Space 0 → 1).
--   "Espacio"     negro: sin bruma (Atmosphere fuera), sin nubes, sin Grieta, sin lluvia, sin el
--                 etalonaje de Valmar (ColorCorrection apagada), cielo de estrellas con la nebulosa
--                 (Sky «EspacioProfundo»), los 7 planetas (estrellas de lejos, esferas de cerca) y el
--                 sol con su brillo.
--   "Entrada"     entrando o saliendo de un planeta: del espacio al cielo del planeta (PlanetMix).
--   "Planeta"     en la superficie: el perfil propio del planeta (Tefra: cielo malva con ceniza y luz
--                 volcánica, Sky «CieloTefra»), nunca el de Valmar ni su Grieta.
--   "Arena"       la arena de pruebas del combate aéreo: su propio cielo (lo pone AirCombatClient).
--   "Submarino"   la cámara bajo el agua del mar de Valmar (o de un río o lago): la luz del mar de la
--                 zona y de la hondura (shared/Sea/OceanBiomes.look: bruma azul que deja ver lejos, más
--                 oscura y azul abajo, rayos de sol arriba, la bioluminiscencia brilla más abajo) y sin
--                 lluvia ni nieve. Lo cuenta Controllers/SeaBiome a EnvDirector (setSea); nadie más toca
--                 la luz del agua (antes SeaBiome se lo decía a DayLight por su cuenta).
--
-- La luz final = la de la hora (con tiempo y capas de la historia) → mezclada hacia el ESPACIO con peso
-- Space → mezclada hacia el PLANETA con peso PlanetMix (EnvZones.applyKey). Esta mezcla va la ÚLTIMA:
-- ninguna capa de la historia (la Grieta, una tormenta) vuelve a meter nubes o bruma en el espacio.
-- Los interruptores (cielo, bruma, nubes, Grieta, lluvia) tienen histéresis (EnvZones.flags): no
-- parpadean en el borde de una zona.

local Layers = require(script.Parent.Layers)
local PlanetBodies = require(script.Parent.PlanetBodies)

local EnvZones = {}

local rgb = Color3.fromRGB

-- La luz del espacio (nombres de shared/DayGrade). Sin aire: ni bruma ni nubes; sombras duras y casi
-- negras (no hay cielo que las rellene), el sol blanco y fuerte con su brillo, contraste alto.
EnvZones.Space = {
	Brightness = 2.4,
	Exposure = -0.22,
	Ambient = rgb(16, 18, 28),
	Outdoor = rgb(30, 34, 52),
	EnvDiffuse = 0.15,
	EnvSpecular = 0.7,
	Shadow = 0.04,
	SunTint = rgb(40, 36, 30),
	ShadeTint = rgb(0, 0, 8),
	Density = 0,
	Offset = 0,
	AtmColor = rgb(0, 0, 0),
	Decay = rgb(0, 0, 0),
	Glare = 0,
	Haze = 0,
	Tint = rgb(255, 255, 255),
	Saturation = 0.06,
	Contrast = 0.24,
	CCBright = 0,
	Bloom = 1.1,
	BloomSize = 30,
	Threshold = 1.2,
	Rays = 0.22, -- el brillo del sol (SunRays, si el nivel gráfico lo tiene)
	RaysSpread = 0.3,
	Cover = 0,
	CloudDensity = 0,
	Veil = 0,
	Overcast = 0,
}

export type PlanetProfile = {
	Sky: { string }, -- huecos de SkyLibrary por orden de preferencia ("Original" = el del archivo)
	Clouds: boolean, -- nubes de Roblox (teñidas con su color)
	Mood: { [string]: any }, -- su luz (nombres de DayGrade)
}

-- Tefra: cielo malva con ceniza en el aire y luz volcánica (sol anaranjado bajo, sombras moradas,
-- bruma de ceniza). Su cielo de fotos es «CieloTefra» (con la luna Ovilla).
local TEFRA: PlanetProfile = {
	Sky = { "CieloTefra", "Original" },
	Clouds = true,
	Mood = {
		Brightness = 2.2,
		Exposure = 0.02,
		Ambient = rgb(92, 72, 90),
		Outdoor = rgb(146, 116, 146),
		EnvDiffuse = 0.7,
		EnvSpecular = 0.8,
		Shadow = 0.25,
		SunTint = rgb(110, 54, 34), -- luz volcánica: cálida en las caras que mira el sol
		ShadeTint = rgb(30, 16, 46),
		Density = 0.36,
		Offset = 0.15,
		AtmColor = rgb(214, 176, 200),
		Decay = rgb(124, 86, 112),
		Glare = 0.35,
		Haze = 2,
		Tint = rgb(255, 234, 244),
		Saturation = -0.04,
		Contrast = 0.14,
		CCBright = 0,
		Bloom = 0.7,
		BloomSize = 26,
		Threshold = 1.6,
		Rays = 0.05,
		RaysSpread = 0.6,
		Cover = 0.42,
		CloudDensity = 0.4,
		CloudColor = rgb(206, 186, 200), -- nubes de ceniza malva (nunca las blancas de Valmar)
		Veil = 0,
		Overcast = 0,
	},
}

-- El perfil de un planeta: Tefra a mano; los demás (aún «próximamente») con los colores de su cuerpo
-- (shared/Cosmos/PlanetBodies), para que nunca se vea el cielo de Valmar en ninguno.
local cache: { [string]: PlanetProfile } = { Tefra = TEFRA }
function EnvZones.planet(id: string?): PlanetProfile?
	if not id then
		return nil
	end
	local known = cache[id]
	if known then
		return known
	end
	local b = PlanetBodies.ById[id]
	if not b then
		return nil
	end
	local white = rgb(255, 255, 255)
	local profile: PlanetProfile = {
		Sky = { "Cielo" .. id, "Original" },
		Clouds = b.Clouds,
		Mood = {
			Brightness = 2.2,
			Exposure = 0,
			Ambient = b.Ground:Lerp(rgb(0, 0, 0), 0.6),
			Outdoor = b.Ground:Lerp(white, 0.2),
			Shadow = 0.25,
			SunTint = b.Halo:Lerp(rgb(0, 0, 0), 0.7),
			ShadeTint = b.Ground:Lerp(rgb(0, 0, 0), 0.85),
			Density = 0.34,
			Offset = 0.15,
			AtmColor = b.Halo:Lerp(white, 0.35),
			Decay = b.Ground,
			Glare = 0.3,
			Haze = 1.8,
			Tint = b.Halo:Lerp(white, 0.85),
			Saturation = 0,
			Contrast = 0.15,
			CCBright = 0,
			Cover = if b.Clouds then 0.45 else 0,
			CloudDensity = if b.Clouds then 0.4 else 0,
			CloudColor = b.Band,
			Veil = 0,
			Overcast = 0,
		},
	}
	cache[id] = profile
	return profile
end
EnvZones.Tefra = TEFRA

---------------------------------------------------------------------
-- Dónde estás
---------------------------------------------------------------------
-- Bajo el agua: { Under = 0..1 (cuánto está la cámara bajo el agua, ya suavizado), Look = la luz del
-- agua de OceanBiomes.look (nil = río, lago o sin saber aún: la bruma de siempre) }
export type Sea = { Under: number, Look: { [string]: any }? }

export type Input = {
	Pos: Vector3, -- la cámara
	Sea: Sea?, -- bajo el agua (Controllers/SeaBiome → EnvDirector.setSea)
	Arena: boolean?, -- en la arena de pruebas del combate aéreo
	Surface: string?, -- planeta cuya superficie tiene la cámara dentro (Tefra.inRegion)
	Entry: { Planet: string?, Mix: number, Climbing: boolean? }?, -- entrando o saliendo (PlanetEntry)
}

export type Env = {
	Zone: string, -- "Valmar" | "Submarino" | "Transicion" | "Espacio" | "Entrada" | "Planeta" | "Arena"
	Space: number, -- 0 = cielo de Valmar, 1 = espacio
	Planet: string?,
	PlanetMix: number, -- 0 = nada del planeta, 1 = solo el planeta
	Under: number?, -- 0..1 bajo el agua (solo en Valmar)
	SeaLook: { [string]: any }?, -- la luz del agua (OceanBiomes.look)
}

-- ¿Zona del espacio (la columna de Valmar o junto a un planeta)?
function EnvZones.inSpaceArea(pos: Vector3): boolean
	return Layers.inColumn(pos, 600) or PlanetBodies.approachAt(pos, 600) ~= nil
end

-- La zona que toca (sin suavizar)
function EnvZones.resolve(i: Input): Env
	if i.Arena then
		return { Zone = "Arena", Space = 0, Planet = nil, PlanetMix = 0 }
	end
	local entry = i.Entry
	if i.Surface then
		-- (subiendo desde la superficie, el cielo del planeta se va abriendo al negro: nunca menos de 0,3)
		local mix = if entry and entry.Climbing then math.clamp(math.max(entry.Mix, 0.3), 0, 1) else 1
		return { Zone = "Planeta", Space = 1, Planet = i.Surface, PlanetMix = mix }
	end
	local inArea = EnvZones.inSpaceArea(i.Pos)
	if entry and entry.Planet and inArea then
		return { Zone = "Entrada", Space = 1, Planet = entry.Planet, PlanetMix = math.clamp(entry.Mix, 0, 1) }
	end
	local space = if inArea then Layers.skyBlend(i.Pos.Y) else 0
	local zone = if space >= 0.999 then "Espacio" elseif space > 0.001 then "Transicion" else "Valmar"
	-- Bajo el agua (solo en Valmar: no hay mar en el espacio)
	local sea = i.Sea
	local under = if sea and zone == "Valmar" then math.clamp(sea.Under or 0, 0, 1) else 0
	if under > 0.5 then
		zone = "Submarino"
	end
	return { Zone = zone, Space = space, Planet = nil, PlanetMix = 0, Under = under, SeaLook = if under > 0 and sea then sea.Look else nil }
end

-- Suaviza el paso de una zona a otra (un salto de la nave a la superficie o un teletransporte no da un
-- fogonazo: como mucho Rate por segundo)
EnvZones.Rate = 1.6
local function toward(a: number, b: number, step: number): number
	if a < b then
		return math.min(b, a + step)
	end
	return math.max(b, a - step)
end
function EnvZones.approach(cur: Env?, target: Env, dt: number): Env
	if not cur or cur.Zone == "Arena" or target.Zone == "Arena" then
		return table.clone(target)
	end
	local step = EnvZones.Rate * math.max(dt, 0)
	local out = table.clone(target)
	out.Space = toward(cur.Space, target.Space, step)
	-- (el planeta se queda mientras se apaga: si no, el último trozo de la mezcla saltaba de golpe)
	if target.Planet == nil and cur.Planet ~= nil and cur.PlanetMix > 0 then
		out.Planet = cur.Planet
		out.PlanetMix = toward(cur.PlanetMix, 0, step)
	elseif target.Planet ~= nil and cur.Planet ~= nil and cur.Planet ~= target.Planet then
		out.PlanetMix = target.PlanetMix -- (otro planeta: sin mezcla rara entre los dos)
	else
		out.PlanetMix = toward(cur.PlanetMix, target.PlanetMix, step)
	end
	if out.PlanetMix <= 0 and target.Planet == nil then
		out.Planet = nil
	end
	-- (el nombre de la zona sigue a lo que se ve de verdad)
	if out.Planet and out.PlanetMix > 0 and target.Zone ~= "Planeta" and target.Zone ~= "Entrada" then
		out.Zone = "Entrada"
	elseif not out.Planet and target.Zone ~= "Arena" then
		out.Zone = if out.Space >= 0.999 then "Espacio" elseif out.Space > 0.001 then "Transicion" elseif target.Zone == "Submarino" then "Submarino" else "Valmar"
	end
	-- (bajo el agua no se suaviza aquí: SeaBiome ya lo hace al meter y sacar la cámara del agua)
	if out.Zone ~= "Valmar" and out.Zone ~= "Submarino" then
		out.Under, out.SeaLook = 0, nil
	end
	return out
end

---------------------------------------------------------------------
-- Interruptores (con histéresis: sin parpadeos en el borde)
---------------------------------------------------------------------
export type Flags = {
	Sky: string, -- "Valmar" | "Espacio" | "Planeta" | "Arena"
	SkySlots: { string }?, -- lo que se pide a DayLight (nil = el de la hora)
	Atmosphere: boolean, -- la bruma de Roblox (Atmosphere) puesta
	Clouds: boolean, -- las nubes de Roblox puestas
	ColorCorrection: boolean, -- el etalonaje de Valmar puesto
	Rift: boolean, -- la Grieta del cielo de Valmar se puede ver
	Weather: boolean, -- lluvia, nieve, tormenta de Valmar
	ValmarSky: boolean, -- la luna 3D, las estrellas fugaces y el cielo especial de Valmar
	Stars: boolean, -- campo de estrellas denso (StarCount alto)
	Underwater: boolean, -- la cámara bajo el agua (luz del mar; sin lluvia ni nieve)
}

EnvZones.SpaceSky = { "EspacioProfundo", "Night", "Original" }

local function over(value: number, wasOn: boolean?, on: number, off: number): boolean
	return if wasOn then value > off else value > on
end

function EnvZones.flags(env: Env, prev: Flags?): Flags
	if env.Zone == "Arena" then
		return { Sky = "Arena", SkySlots = nil, Atmosphere = true, Clouds = true, ColorCorrection = true, Rift = false, Weather = false, ValmarSky = false, Stars = false, Underwater = false }
	end
	local p = prev or ({} :: any)
	local planet = EnvZones.planet(env.Planet)
	local planetSky = planet ~= nil and over(env.PlanetMix, p.Sky == "Planeta", 0.55, 0.45)
	local spaceSky = not planetSky and over(env.Space, p.Sky == "Espacio", 0.6, 0.5)
	local fullSpace = not planetSky and env.PlanetMix < 0.05 and over(env.Space, p.Atmosphere == false, 0.95, 0.9)
	local clouds
	if planetSky then
		clouds = (planet :: PlanetProfile).Clouds
	else
		clouds = not over(env.Space, p.Clouds == false, 0.55, 0.45) and env.PlanetMix < 0.5
	end
	local valmar = env.Planet == nil or env.PlanetMix <= 0.02
	local underwater = valmar and over(env.Under or 0, p.Underwater == true, 0.55, 0.45)
	return {
		Sky = if planetSky then "Planeta" elseif spaceSky then "Espacio" else "Valmar",
		SkySlots = if planetSky then (planet :: PlanetProfile).Sky elseif spaceSky then EnvZones.SpaceSky else nil,
		Atmosphere = not fullSpace,
		Clouds = clouds,
		ColorCorrection = not fullSpace,
		Rift = valmar and not over(env.Space, p.Rift == false, 0.35, 0.25),
		Weather = valmar and not underwater and not over(env.Space, p.Weather == false, 0.08, 0.04),
		ValmarSky = valmar and not over(env.Space, p.ValmarSky == false, 0.5, 0.4),
		Stars = spaceSky or (planetSky == false and env.Space > 0.5),
		Underwater = underwater,
	}
end

-- Estrellas del cielo de Roblox (Sky.StarCount) en el espacio, según el nivel gráfico
EnvZones.StarCount = { Low = 1500, Medium = 3000, High = 5000 }
function EnvZones.starCount(tier: string?): number
	return EnvZones.StarCount[tier or "Medium"] or EnvZones.StarCount.Medium
end

---------------------------------------------------------------------
-- La luz final
---------------------------------------------------------------------
local function mixInto(k: { [string]: any }, mood: { [string]: any }, t: number): { [string]: any }
	if t <= 0.0005 then
		return k
	end
	t = math.clamp(t, 0, 1)
	local out = table.clone(k)
	for name, value in k do
		local w = mood[name]
		if w ~= nil then
			if type(value) == "number" and type(w) == "number" then
				out[name] = value + (w - value) * t
			elseif typeof(value) == "Color3" and typeof(w) == "Color3" then
				out[name] = (value :: Color3):Lerp(w, t)
			end
		end
	end
	return out
end
EnvZones.mixInto = mixInto

-- La luz bajo el agua (antes en DayLight): la de la hora, con la bruma del mar, tono azul verdoso y menos
-- sol. En el mar, la de la zona y la hondura (OceanBiomes.look): bruma azul que deja ver lejos (mar
-- enorme, v120), más oscura y azul abajo; los rayos de sol solo arriba; abajo la bioluminiscencia
-- brilla más (Bloom). look = nil: río, lago o sin saber aún.
function EnvZones.underwaterKey(k: { [string]: any }, look: { [string]: any }?): { [string]: any }
	local out = table.clone(k)
	local atm = k.AtmColor or rgb(28, 108, 128)
	local tint = k.Tint or rgb(255, 255, 255)
	out.Density = 0.62
	out.Offset = 1
	out.AtmColor = rgb(28, 108, 128):Lerp(atm, 0.15)
	out.Decay = rgb(6, 38, 58)
	out.Glare = 0
	out.Haze = 2.6
	out.Tint = rgb(150, 215, 228):Lerp(tint, 0.2)
	out.Saturation = (k.Saturation or 0) - 0.05
	out.Contrast = (k.Contrast or 0) + 0.08
	out.CCBright = (k.CCBright or 0) - 0.03
	out.Exposure = (k.Exposure or 0) - 0.1
	out.Bloom = (k.Bloom or 0.5) * 0.5
	out.Rays = math.max(k.Rays or 0, 0.12)
	out.RaysSpread = 0.9
	if look then
		local glow = look.Glow or 0
		out.Density = look.Density
		out.AtmColor = look.Fog:Lerp(atm, 0.08)
		out.Decay = look.Decay
		out.Haze = look.Haze
		out.Tint = look.Tint:Lerp(tint, 0.12)
		out.Exposure = (k.Exposure or 0) - 0.1 + look.Exposure
		out.Rays = math.max(k.Rays or 0, 0.12) * (look.Rays or 1)
		-- (abajo, la bioluminiscencia toma el relevo: brilla más y más contraste)
		out.Bloom = (k.Bloom or 0.5) * (0.55 + 1.1 * glow)
		out.Threshold = math.max(0.8, (k.Threshold or 1.4) - 0.5 * glow)
		out.Saturation = (k.Saturation or 0) + 0.04 * glow
		out.Contrast = (k.Contrast or 0) + 0.08 + 0.06 * glow
		-- (v122, orilla de noche marrón: la luz que rellena las sombras era la de la calle a esa hora,
		-- gris y cálida sobre la arena. Bajo el agua va hacia el turquesa de día y el azul de luna de
		-- noche; el etalonaje de la zona manda casi entero, sin el blanco cálido de la hora)
		local fill = look.FillMix or 0
		if fill > 0 and typeof(look.Ambient) == "Color3" and typeof(look.Outdoor) == "Color3" then
			out.Ambient = (k.Ambient or look.Ambient):Lerp(look.Ambient, fill)
			out.Outdoor = (k.Outdoor or look.Outdoor):Lerp(look.Outdoor, fill)
		end
		local night = math.clamp(look.Night or 0, 0, 1)
		out.Tint = look.Tint:Lerp(tint, 0.12 - 0.08 * night)
		if night > 0 then
			out.SunTint = (k.SunTint or rgb(0, 8, 26)):Lerp(rgb(0, 8, 26), night)
		end
		out.Saturation = (k.Saturation or 0) + 0.04 * glow + 0.06 + 0.02 * night
	end
	return out
end

-- La luz de la hora (con todo lo de Valmar ya puesto) → la de la zona. Va la última.
function EnvZones.applyKey(k: { [string]: any }, env: Env?): { [string]: any }
	if not env or env.Zone == "Arena" then
		return k
	end
	local under = env.Under or 0
	if under > 0.001 then
		k = mixInto(k, EnvZones.underwaterKey(k, env.SeaLook), under)
	end
	local out = mixInto(k, EnvZones.Space, env.Space)
	local planet = EnvZones.planet(env.Planet)
	if planet and env.PlanetMix > 0 then
		out = mixInto(out, planet.Mood, env.PlanetMix)
	end
	return out
end

return EnvZones
