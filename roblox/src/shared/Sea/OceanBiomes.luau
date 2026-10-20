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
--                       Glow, LightTree, Bones, Vent, Sponge, Urchin, Shell, Amphora; y el arrecife
--                       costero de shared/Sea/ShoreDecor: CoralHead, Branch, Table, Fan, Anemone,
--                       Starfish, Crab)
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
			-- (v122, queja del dueño en la orilla: fondo marrón y plano con cubos negros) Arena blanca
			-- (Salt: el «Sand» del terreno lleva la arena de playa del dueño, marrón bajo el agua),
			-- con manchas de caliza y roca; arrecife costero con corales redondos, abanicos, anémonas,
			-- praderas altas, rocas con musgo, conchas, estrellas y cangrejos (shared/Sea/ShoreDecor)
			Materials = { Floor = "Salt", Rock = "Rock" },
			Flora = { Seagrass = 30, CoralHead = 14, Branch = 8, Fan = 6, Anemone = 8, Rock = 12, Shell = 12, Starfish = 8, Crab = 6, Urchin = 4, Amphora = 1 },
			Fauna = { Schools = 3, Rays = 0, Turtles = 0, Jellies = 1, Dolphins = 0, Abyssal = 0 },
			-- agua turquesa clara (se ve la arena y los corales), sin bruma marrón. (v124, captura v123: era un
			-- cian claro y plano —«campo de nieve»—; ahora turquesa más hondo, con más bruma con la distancia)
			Look = { Fog = rgb(34, 150, 176), Decay = rgb(8, 70, 100), Density = 0.36, Tint = rgb(160, 222, 232), Exposure = 0.02, Haze = 1.8, Visibility = 180, Water = rgb(28, 140, 166), Snow = 0.15 },
			TempSurface = 22, TempDeep = 21,
			Current = 0,
			Hazards = {},
			Loot = { Concha = 70, Perla = 0 },
		},
		-- Jardines de coral junto a las playas (v122, Ocean.ShoreReefs): a 3-4 m, a un paso de la arena
		Coral = {
			Name = "Jardín de coral",
			Short = "Coral",
			Materials = { Floor = "Salt", Rock = "Rock" },
			Flora = { CoralHead = 26, Branch = 18, Table = 8, Fan = 10, Anemone = 10, Seagrass = 10, Rock = 8, Shell = 6, Starfish = 4, Crab = 3, LightTree = 2 },
			Fauna = { Schools = 5, Rays = 1, Turtles = 1, Jellies = 1, Dolphins = 0, Abyssal = 0 },
			Look = { Fog = rgb(28, 142, 178), Decay = rgb(6, 62, 98), Density = 0.34, Tint = rgb(160, 224, 236), Exposure = 0.03, Haze = 1.7, Visibility = 200, Water = rgb(24, 134, 166), Snow = 0.15 },
			TempSurface = 23, TempDeep = 22,
			Current = 0.2,
			Hazards = {},
			Loot = { Concha = 50, Perla = 4, Coral = 30 },
		},
		-- La zona de referencia v2 (encargo del dueño tras la v123; shared/Sea/ReefZone, docs/mar/diseno-v2.md):
		-- el cañón que baja desde el jardín de coral de Playa Dorada. Agua turquesa con contraste: más azul
		-- y oscura según se baja (Density y Haze altos: la niebla da profundidad sin tapar las paredes)
		Canon = {
			Name = "Cañón de Dorada",
			Short = "Cañón",
			Materials = { Floor = "Salt", Rock = "Rock" },
			-- (el decorado lo pone World/ReefZoneBuilder con el kit del mar; SeaBiome no planta aquí)
			Flora = { CoralHead = 1 },
			Fauna = { Schools = 5, Rays = 1, Turtles = 1, Jellies = 1, Dolphins = 0, Abyssal = 0 },
			Look = { Fog = rgb(20, 116, 154), Decay = rgb(4, 40, 72), Density = 0.42, Tint = rgb(150, 214, 232), Exposure = -0.02, Haze = 2.0, Visibility = 200, Water = rgb(18, 108, 146), Snow = 0.3 },
			TempSurface = 23, TempDeep = 18,
			Current = 0.4,
			Hazards = {},
			Loot = { Concha = 40, Perla = 8, Coral = 30 },
		},
		Arrecife = {
			Name = "Arrecife Escarlata",
			Short = "Arrecife",
			Materials = { Floor = "Salt", Rock = "Rock" },
			Flora = { CoralHead = 22, Branch = 14, Table = 6, Fan = 8, Anemone = 6, Coral = 8, LightTree = 4, Seagrass = 10, Rock = 10, Sponge = 10, Urchin = 4, Shell = 6, Starfish = 3, Crab = 2, Amphora = 1 },
			Fauna = { Schools = 4, Rays = 1, Turtles = 2, Jellies = 1, Dolphins = 0, Abyssal = 0 },
			Look = { Fog = rgb(30, 150, 185), Decay = rgb(8, 70, 105), Density = 0.32, Tint = rgb(185, 240, 248), Exposure = 0.05, Haze = 1.8, Visibility = 230, Water = rgb(25, 130, 155), Snow = 0.25 },
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
			Look = { Fog = rgb(36, 118, 104), Decay = rgb(12, 52, 44), Density = 0.5, Tint = rgb(175, 225, 200), Exposure = -0.06, Haze = 2.4, Visibility = 140, Water = rgb(32, 102, 92), Snow = 0.35 },
			TempSurface = 17, TempDeep = 14,
			Current = 1.4,
			Hazards = {},
			Loot = { Concha = 40, Perla = 3 },
		},
		Llanura = {
			Name = "Llanura Sumergida",
			Short = "Llanura",
			Materials = { Floor = "Salt", Rock = "Rock" },
			Flora = { Seagrass = 50, Rock = 12, Shell = 12, Starfish = 4, CoralHead = 4, Anemone = 3, Sponge = 6, Amphora = 2 },
			Fauna = { Schools = 3, Rays = 2, Turtles = 1, Jellies = 1, Dolphins = 1, Abyssal = 0 },
			Look = { Fog = rgb(26, 118, 170), Decay = rgb(6, 50, 92), Density = 0.4, Tint = rgb(165, 220, 245), Exposure = -0.03, Haze = 2.2, Visibility = 200, Water = rgb(22, 105, 148), Snow = 0.4 },
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
			Look = { Fog = rgb(18, 86, 148), Decay = rgb(4, 32, 72), Density = 0.46, Tint = rgb(150, 205, 240), Exposure = -0.12, Haze = 2.6, Visibility = 180, Water = rgb(15, 82, 130), Snow = 0.6 },
			TempSurface = 19, TempDeep = 12,
			Current = 0.9,
			Hazards = { Pressure = true },
			Loot = { Concha = 25, Perla = 6, Doblon = 4 },
		},
		Garganta = {
			Name = "Garganta Negra",
			Short = "Garganta",
			Materials = { Floor = "Basalt", Rock = "Basalt" },
			Flora = { Rock = 36, Sponge = 18, Glow = 15, LightTree = 8, Urchin = 10, Bones = 3 },
			Fauna = { Schools = 1, Rays = 1, Turtles = 0, Jellies = 2, Dolphins = 0, Abyssal = 1 },
			Look = { Fog = rgb(12, 52, 104), Decay = rgb(2, 18, 46), Density = 0.56, Tint = rgb(125, 175, 230), Exposure = -0.24, Haze = 3, Visibility = 130, Water = rgb(10, 52, 96), Snow = 0.8 },
			TempSurface = 16, TempDeep = 9,
			Current = 2.2,
			Hazards = { Pressure = true },
			Loot = { Perla = 8, Bio = 10, Doblon = 3 },
		},
		Abismo = {
			Name = "Abismo Silente",
			Short = "Abismo",
			Materials = { Floor = "Mud", Rock = "Basalt" },
			Flora = { Glow = 34, LightTree = 16, Bones = 6, Vent = 6, Rock = 22, Sponge = 12 },
			Fauna = { Schools = 1, Rays = 0, Turtles = 0, Jellies = 3, Dolphins = 0, Abyssal = 3 },
			Look = { Fog = rgb(10, 42, 98), Decay = rgb(2, 12, 40), Density = 0.52, Tint = rgb(110, 160, 230), Exposure = -0.32, Haze = 3.2, Visibility = 140, Water = rgb(6, 34, 80), Snow = 1 },
			TempSurface = 12, TempDeep = 5,
			Current = 0.3,
			Hazards = { Pressure = true, Megalodon = true },
			Loot = { Bio = 30, Perla = 6, Doblon = 4 },
		},
		Catedrales = {
			Name = "Cañón de las Catedrales",
			Short = "Catedrales",
			Materials = { Floor = "Rock", Rock = "Basalt" },
			Flora = { LightTree = 30, Glow = 20, Rock = 20, Sponge = 15, Coral = 10, Bones = 3 },
			Fauna = { Schools = 3, Rays = 2, Turtles = 0, Jellies = 3, Dolphins = 0, Abyssal = 1 },
			Look = { Fog = rgb(16, 78, 132), Decay = rgb(4, 26, 64), Density = 0.44, Tint = rgb(150, 205, 245), Exposure = -0.12, Haze = 2.6, Visibility = 170, Water = rgb(12, 66, 118), Snow = 0.7 },
			TempSurface = 15, TempDeep = 8,
			Current = 0.5,
			Hazards = { Pressure = true },
			Loot = { Bio = 20, Perla = 8, Doblon = 8 },
		},
		Sima = {
			Name = "Sima del Kraken",
			Short = "Sima",
			Materials = { Floor = "Basalt", Rock = "Basalt" },
			Flora = { Glow = 45, Vent = 15, Bones = 10, Rock = 30 },
			Fauna = { Schools = 0, Rays = 0, Turtles = 0, Jellies = 2, Dolphins = 0, Abyssal = 4 },
			Look = { Fog = rgb(18, 12, 56), Decay = rgb(4, 2, 16), Density = 0.7, Tint = rgb(140, 120, 215), Exposure = -0.5, Haze = 4, Visibility = 80, Water = rgb(10, 8, 44), Snow = 1 },
			TempSurface = 6, TempDeep = 4,
			Current = 0.4,
			Hazards = { Pressure = true, Kraken = true },
			Loot = { Bio = 40, Doblon = 6, Perla = 4 },
		},
	},
	ZoneOrder = { "Orilla", "Coral", "Canon", "Arrecife", "Kelp", "Llanura", "Talud", "Garganta", "Catedrales", "Abismo", "Sima" },
	-- La luz baja con la profundidad (además de la zona): a esta profundidad (m) la exposición ha bajado
	-- DarkExposure y la bruma es DarkFog; los rayos de sol solo hasta RaysDepth
	Depth = { DarkAt = 140, DarkExposure = -0.45, DarkFog = rgb(6, 22, 58), RaysDepth = 32, GlowFrom = 22 },
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

-- La noche bajo el agua (v122: en la orilla de noche se veía barro marrón y gris). Luz de luna AZUL:
-- bruma y agua azul marino que dejan ver, ambiente azulado (Lighting.Ambient/OutdoorAmbient) que sube
-- lo bastante para ver el fondo, exposición algo más alta y etalonaje azul. La bioluminiscencia
-- (plancton y puntas de las anémonas) brilla también cerca de la orilla.
OceanBiomes.Night = {
	Fog = rgb(20, 56, 118),
	Decay = rgb(6, 22, 64),
	Tint = rgb(150, 188, 255),
	Water = rgb(22, 66, 132),
	Ambient = rgb(48, 82, 140),
	Outdoor = rgb(66, 108, 176),
	Exposure = 0.26,
	Glow = 0.55, -- bioluminiscencia mínima de noche, también a 1 m
}
-- De día, un toque turquesa en la luz que rellena las sombras (sin él la arena salía del color de la
-- luz de la calle: beis y gris)
OceanBiomes.DayFill = { Ambient = rgb(92, 160, 176), Outdoor = rgb(120, 190, 205), Mix = 0.3 }

-- La luz bajo el agua en una zona y a una profundidad (m): la de la zona, oscurecida con la hondura.
-- night (0..1, opcional: GameClock.darkness) la lleva a la luz de luna azul. Devuelve una tabla para
-- shared/Cosmos/EnvZones.underwaterKey (y el color del agua del terreno: Water).
function OceanBiomes.look(zoneId: string?, meters: number, worldId: string?, night: number?): { [string]: any }
	local w = OceanBiomes.world(worldId)
	local z = OceanBiomes.zone(zoneId, worldId) or w.Zones.Llanura
	local L = z.Look
	local dk = math.clamp(math.max(meters, 0) / w.Depth.DarkAt, 0, 1)
	local n = math.clamp(night or 0, 0, 1)
	local N, D = OceanBiomes.Night, OceanBiomes.DayFill
	local fog = L.Fog:Lerp(w.Depth.DarkFog, dk * 0.7)
	local decay = L.Decay:Lerp(rgb(0, 0, 0), dk * 0.6)
	local tint = L.Tint:Lerp(rgb(90, 120, 190), dk * 0.5)
	local water = L.Water:Lerp(rgb(2, 10, 26), dk * 0.6)
	local glow = math.clamp((meters - w.Depth.GlowFrom) / 40, 0, 1)
	return {
		Fog = fog:Lerp(N.Fog, n * 0.85),
		Decay = decay:Lerp(N.Decay, n * 0.85),
		Density = math.clamp(L.Density + 0.12 * dk, 0, 1),
		Tint = tint:Lerp(N.Tint, n * 0.8),
		Exposure = L.Exposure + w.Depth.DarkExposure * dk + N.Exposure * n,
		Haze = L.Haze + 1.2 * dk,
		Visibility = math.max(30, L.Visibility * (1 - 0.5 * dk) * (1 - 0.25 * n)),
		Water = water:Lerp(N.Water, n * 0.85),
		Snow = math.clamp(L.Snow + dk * 0.5, 0, 1),
		Rays = math.clamp(1 - meters / w.Depth.RaysDepth, 0, 1),
		Glow = math.max(glow, N.Glow * n),
		-- la luz que rellena (Lighting.Ambient/OutdoorAmbient) y cuánto manda sobre la de la hora
		Ambient = D.Ambient:Lerp(N.Ambient, n),
		Outdoor = D.Outdoor:Lerp(N.Outdoor, n),
		FillMix = D.Mix + (0.85 - D.Mix) * n,
		Night = n,
	}
end

return OceanBiomes
