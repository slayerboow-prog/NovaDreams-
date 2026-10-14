-- OceanBiomes: la tabla de datos de cada mundo líquido (hoy, el mar de Valmar). Nada de Roblox salvo
-- Color3: así la leen el servidor (World/OceanBuilder, Services/OceanService), el cliente (SeaBiome,
-- SeaLife, DiveHud) y las pruebas (scripts/test-mar.luau). docs/mar/diseno.md.
--
-- Cada mundo (Worlds[id]) trae:
--   Liquid         "Water" | "Lava" | "Ice" | "Acid": qué es el líquido (en Valmar, agua del terreno)
--   Surface        altura de la superficie (Y)
--   StudsPerMeter  escala (1 m = 3,57 studs: un avatar de Roblox mide ~5 studs ≈ 1,8 m)
--   Profile        el perfil de profundidad que usa Shared/Sea/Ocean (distancias a tierra y alturas)
--   Zones          las zonas («Vida marina» del HUD) con todo lo que las hace distintas:
--     Name, Short       nombre que ve el jugador
--     Materials         materiales del terreno del fondo { Floor, Rock } (World/OceanBuilder)
--     Flora             pesos de lo que planta SeaBiome en el fondo (Kelp, Coral, Seagrass, Rock,
--                       Glow, Bones, Vent, Sponge, Urchin, Shell, Amphora)
--     Fauna             pesos de lo que nada (SeaLife): Schools, Rays, Turtles, Jellies, Dolphins, Abyssal
--     Look              luz y niebla bajo el agua (DayLight.setUnderwaterLook): Fog (color de la bruma),
--                       Decay, Density, Tint, Exposure, Haze, Visibility (studs que se ven), Water (color
--                       del agua del terreno), Snow (motas: «nieve marina»)
--     TempSurface/TempDeep  °C arriba y en el fondo de la zona
--     Current           corriente de la zona (studs/s); las corrientes con sitio están en Ocean.Currents
--     Hazards           peligros: { Pressure = true, Megalodon = true, Kraken = true }
--     Loot              recursos que salen (Shared/Sea/Diving.Loot) con su peso

local OceanBiomes = {}

local rgb = Color3.fromRGB

OceanBiomes.Worlds = {}

OceanBiomes.Worlds.Valmar = {
	Id = "Valmar",
	Liquid = "Water",
	Surface = -2,
	StudsPerMeter = 3.57,
	-- Perfil (Shared/Sea/Ocean): distancias a tierra (studs) y alturas del fondo (Y)
	Profile = {
		CoastY = -14, -- junto a la costa, como siempre (playas, muelles, pantalanes)
		Coast = 60, -- hasta aquí no se toca nada
		ShelfEnd = 360, -- plataforma (arrecife, kelp, pradera)
		ShelfY = -48, -- ~13 m
		SlopeEnd = 820, -- talud
		PlainY = -132, -- ~37 m: llanura profunda
		Blend = 140, -- lo que tarda en pasar de -14 a lo de fuera alrededor de puertos e islas
	},
	-- El rectángulo que ocupa el mar (el sur se alarga 700 studs: el abismo no toca el borde)
	Area = { MinX = -5800, MaxX = 5800, MinZ = -5200, MaxZ = 5800 },
	SlabMaxZ = 5100, -- hasta aquí ya hay agua de -14 a -2 (TerrainBuilder); más al sur la pone OceanBuilder
	Zones = {
		Orilla = {
			Name = "Aguas de la orilla",
			Short = "Orilla",
			Materials = { Floor = "Sand", Rock = "Rock" },
			Flora = { Seagrass = 40, Rock = 20, Shell = 20, Urchin = 10, Amphora = 2 },
			Fauna = { Schools = 2, Rays = 0, Turtles = 0, Jellies = 1, Dolphins = 0, Abyssal = 0 },
			Look = { Fog = rgb(40, 150, 160), Decay = rgb(10, 70, 80), Density = 0.5, Tint = rgb(170, 230, 230), Exposure = 0, Haze = 2, Visibility = 140, Water = rgb(30, 120, 130), Snow = 0.2 },
			TempSurface = 22, TempDeep = 21,
			Current = 0,
			Hazards = {},
			Loot = { Concha = 70, Perla = 0 },
		},
		Arrecife = {
			Name = "Arrecife Escarlata",
			Short = "Arrecife",
			Materials = { Floor = "Sand", Rock = "Rock" },
			Flora = { Coral = 55, Seagrass = 12, Rock = 10, Sponge = 12, Urchin = 6, Shell = 8, Amphora = 1 },
			Fauna = { Schools = 4, Rays = 1, Turtles = 2, Jellies = 1, Dolphins = 0, Abyssal = 0 },
			Look = { Fog = rgb(30, 150, 175), Decay = rgb(8, 70, 95), Density = 0.42, Tint = rgb(185, 240, 245), Exposure = 0.05, Haze = 1.6, Visibility = 180, Water = rgb(25, 130, 150), Snow = 0.25 },
			TempSurface = 24, TempDeep = 21,
			Current = 0.5,
			Hazards = {},
			Loot = { Concha = 40, Perla = 6, Coral = 30 },
		},
		Kelp = {
			Name = "Laberinto de Kelp",
			Short = "Kelp",
			Materials = { Floor = "Mud", Rock = "Rock" },
			Flora = { Kelp = 70, Rock = 15, Urchin = 8, Shell = 5 },
			Fauna = { Schools = 3, Rays = 0, Turtles = 1, Jellies = 0, Dolphins = 0, Abyssal = 0 },
			Look = { Fog = rgb(40, 110, 85), Decay = rgb(14, 50, 32), Density = 0.62, Tint = rgb(175, 220, 185), Exposure = -0.08, Haze = 2.6, Visibility = 110, Water = rgb(35, 100, 80), Snow = 0.35 },
			TempSurface = 17, TempDeep = 14,
			Current = 1.4,
			Hazards = {},
			Loot = { Concha = 40, Perla = 3 },
		},
		Llanura = {
			Name = "Llanura Sumergida",
			Short = "Llanura",
			Materials = { Floor = "Sand", Rock = "Rock" },
			Flora = { Seagrass = 55, Rock = 12, Shell = 15, Sponge = 6, Amphora = 2 },
			Fauna = { Schools = 3, Rays = 2, Turtles = 1, Jellies = 1, Dolphins = 1, Abyssal = 0 },
			Look = { Fog = rgb(28, 120, 160), Decay = rgb(6, 50, 80), Density = 0.55, Tint = rgb(165, 220, 240), Exposure = -0.03, Haze = 2.2, Visibility = 150, Water = rgb(22, 105, 140), Snow = 0.4 },
			TempSurface = 20, TempDeep = 15,
			Current = 0.6,
			Hazards = {},
			Loot = { Concha = 50, Perla = 4 },
		},
		Talud = {
			Name = "Talud del Naufragio",
			Short = "Talud",
			Materials = { Floor = "Rock", Rock = "Basalt" },
			Flora = { Rock = 40, Sponge = 20, Coral = 10, Seagrass = 10, Urchin = 10, Amphora = 4 },
			Fauna = { Schools = 2, Rays = 2, Turtles = 0, Jellies = 1, Dolphins = 1, Abyssal = 0 },
			Look = { Fog = rgb(18, 80, 130), Decay = rgb(4, 30, 60), Density = 0.66, Tint = rgb(150, 200, 235), Exposure = -0.15, Haze = 2.8, Visibility = 120, Water = rgb(15, 80, 120), Snow = 0.6 },
			TempSurface = 19, TempDeep = 12,
			Current = 0.9,
			Hazards = { Pressure = true },
			Loot = { Concha = 25, Perla = 6, Doblon = 4 },
		},
		Garganta = {
			Name = "Garganta Negra",
			Short = "Garganta",
			Materials = { Floor = "Basalt", Rock = "Basalt" },
			Flora = { Rock = 40, Sponge = 20, Glow = 15, Urchin = 10, Bones = 3 },
			Fauna = { Schools = 1, Rays = 1, Turtles = 0, Jellies = 2, Dolphins = 0, Abyssal = 1 },
			Look = { Fog = rgb(10, 45, 80), Decay = rgb(2, 14, 34), Density = 0.75, Tint = rgb(120, 170, 220), Exposure = -0.3, Haze = 3.2, Visibility = 85, Water = rgb(10, 50, 85), Snow = 0.8 },
			TempSurface = 16, TempDeep = 9,
			Current = 2.2,
			Hazards = { Pressure = true },
			Loot = { Perla = 8, Bio = 10, Doblon = 3 },
		},
		Abismo = {
			Name = "Abismo Silente",
			Short = "Abismo",
			Materials = { Floor = "Mud", Rock = "Basalt" },
			Flora = { Glow = 40, Bones = 6, Vent = 6, Rock = 25, Sponge = 15 },
			Fauna = { Schools = 1, Rays = 0, Turtles = 0, Jellies = 3, Dolphins = 0, Abyssal = 3 },
			Look = { Fog = rgb(4, 18, 42), Decay = rgb(0, 4, 14), Density = 0.86, Tint = rgb(100, 140, 210), Exposure = -0.55, Haze = 3.8, Visibility = 60, Water = rgb(4, 22, 50), Snow = 1 },
			TempSurface = 12, TempDeep = 5,
			Current = 0.3,
			Hazards = { Pressure = true, Megalodon = true },
			Loot = { Bio = 30, Perla = 6, Doblon = 4 },
		},
		Sima = {
			Name = "Sima del Kraken",
			Short = "Sima",
			Materials = { Floor = "Basalt", Rock = "Basalt" },
			Flora = { Glow = 45, Vent = 15, Bones = 10, Rock = 30 },
			Fauna = { Schools = 0, Rays = 0, Turtles = 0, Jellies = 2, Dolphins = 0, Abyssal = 4 },
			Look = { Fog = rgb(10, 4, 30), Decay = rgb(2, 0, 8), Density = 0.92, Tint = rgb(130, 110, 200), Exposure = -0.75, Haze = 4.5, Visibility = 45, Water = rgb(8, 6, 32), Snow = 1 },
			TempSurface = 6, TempDeep = 4,
			Current = 0.4,
			Hazards = { Pressure = true, Kraken = true },
			Loot = { Bio = 40, Doblon = 6, Perla = 4 },
		},
	},
	ZoneOrder = { "Orilla", "Arrecife", "Kelp", "Llanura", "Talud", "Garganta", "Abismo", "Sima" },
	-- La luz baja con la profundidad (además de la zona): a esta profundidad (m) la exposición ha bajado
	-- DarkExposure y la bruma es DarkFog; los rayos de sol solo hasta RaysDepth
	Depth = { DarkAt = 120, DarkExposure = -0.6, DarkFog = rgb(2, 8, 22), RaysDepth = 25, GlowFrom = 30 },
}

-- Mundos previstos para los planetas (no se construyen todavía: docs/mar/diseno.md §9). Cada uno
-- tendrá su propia entrada con Liquid, Profile y Zones como la de Valmar.
OceanBiomes.Planned = {
	Talasa = { Liquid = "Water", Note = "océano con islas flotantes y la ciudad submarina Abisalia" },
	Tefra = { Liquid = "Lava", Note = "lagos de lava: el «aire» es la refrigeración del traje" },
	Nivalis = { Liquid = "Ice", Note = "mares helados bajo una capa de hielo: agujeros para respirar" },
	Miasma = { Liquid = "Acid", Note = "lagos ácidos: el traje se gasta en lugar del aire" },
}

function OceanBiomes.world(id: string?): { [string]: any }
	return OceanBiomes.Worlds[id or "Valmar"] or OceanBiomes.Worlds.Valmar
end

function OceanBiomes.zone(id: string?, worldId: string?): { [string]: any }?
	if not id then
		return nil
	end
	return OceanBiomes.world(worldId).Zones[id]
end

-- Temperatura del agua (°C) a una profundidad (m) en una zona: termoclina (baja rápido los primeros
-- 40 m y luego despacio hacia la del fondo)
function OceanBiomes.temperature(zoneId: string?, meters: number, worldId: string?): number
	local z = OceanBiomes.zone(zoneId, worldId) or OceanBiomes.world(worldId).Zones.Llanura
	local deep = math.min(z.TempDeep, 4 + (z.TempSurface - 4) * math.exp(-math.max(meters, 0) / 40))
	local k = math.exp(-math.max(meters, 0) / 30)
	return deep + (z.TempSurface - deep) * k
end

-- La luz bajo el agua en una zona y a una profundidad (m): la de la zona, oscurecida con la hondura.
-- Devuelve una tabla para DayLight.setUnderwaterLook.
function OceanBiomes.look(zoneId: string?, meters: number, worldId: string?): { [string]: any }
	local w = OceanBiomes.world(worldId)
	local z = OceanBiomes.zone(zoneId, worldId) or w.Zones.Llanura
	local L = z.Look
	local dk = math.clamp(math.max(meters, 0) / w.Depth.DarkAt, 0, 1)
	return {
		Fog = L.Fog:Lerp(w.Depth.DarkFog, dk * 0.7),
		Decay = L.Decay:Lerp(rgb(0, 0, 0), dk * 0.6),
		Density = math.clamp(L.Density + 0.12 * dk, 0, 1),
		Tint = L.Tint:Lerp(rgb(90, 120, 190), dk * 0.5),
		Exposure = L.Exposure + w.Depth.DarkExposure * dk,
		Haze = L.Haze + 1.2 * dk,
		Visibility = math.max(30, L.Visibility * (1 - 0.5 * dk)),
		Water = L.Water:Lerp(rgb(2, 10, 26), dk * 0.6),
		Snow = math.clamp(L.Snow + dk * 0.5, 0, 1),
		Rays = math.clamp(1 - meters / w.Depth.RaysDepth, 0, 1),
		Glow = math.clamp((meters - w.Depth.GlowFrom) / 40, 0, 1),
	}
end

return OceanBiomes
