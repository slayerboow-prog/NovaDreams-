-- RegionGuide: cada REGIÓN por dentro (17-11-2026, el dueño con sus dibujos: «así es como se vería cada distrito»,
-- docs/mapa/region-bosque-a.png y region-bosque-b.png). Datos puros: los usan Controllers/WorldMapUI (la vista de
-- la región: ficha, lugares, misiones y «Colocar destino») y World/RegionLandmarks (los lugares construidos de verdad
-- en las Tierras Exteriores).
--
--   * Lugares (Places): Id, Name, Kind, Level (nil = zona segura) y dónde: Off (grados desde el centro del sector de
--     la región) y T (0 = el borde del antiguo mar de Valmar … 1 = la costa de fuera; < 0, la tierra nueva de la
--     laguna). En el dibujo de la región, lo de arriba es lo lejano (T alto) y la derecha, más grados (Off > 0). Kind: "Santuario" (zona segura con Taller), "Cueva" (la entrada de una mazmorra), "Ruinas", "Arbol",
--     "Territorio" (manadas), "Campamento" (enemigos), "Cascada", "Portal" y "Jefe" (la guarida del jefe de zona).
--   * Boss = true: allí vive el jefe de la región (Bestiary.regionPlaces pone su guarida en ese lugar). Cada lugar con
--     Level tiene sus guaridas alrededor, de ese nivel (las áreas jugables del dibujo del dueño).
--   * Art: el dibujo de la región (shared/MapTextureIds.region_<id>) y dónde cae cada lugar en él (píxeles): con eso
--     se pone el mundo encima del dibujo (RegionGuide.fit: una afinidad por mínimos cuadrados).

local VR = require(script.Parent.ValmarRegions)

local RegionGuide = {}

RegionGuide.Icons = {
	Santuario = "🏛",
	Cueva = "🏰",
	Ruinas = "🏛",
	Arbol = "🌳",
	Territorio = "🐾",
	Campamento = "⚔",
	Cascada = "💧",
	Portal = "🌀",
	Jefe = "💀",
}

RegionGuide.List = {
	BosqueEtereo = {
		Description = "Un bosque misterioso lleno de vida y antiguos secretos.",
		Tip = "Explora la zona para descubrir lugares secretos y mazmorras.",
		Art = { Id = "region_bosque", W = 1024, H = 643 },
		Places = {
			{ Id = "Santuario", Name = "Santuario del Bosque", Kind = "Santuario", Off = 0, T = 0.57, Art = { 515, 250 } },
			{ Id = "Arbol", Name = "Árbol Ancestral", Boss = true, Kind = "Arbol", Level = 25, Off = 0, T = 0.755, Art = { 520, 110 } },
			{ Id = "Cueva", Name = "Cueva Susurrante", Kind = "Cueva", Level = 12, Off = -12, T = 0.735, Art = { 200, 125 } },
			{ Id = "Cascada", Name = "Cascada Mística", Kind = "Cascada", Level = 18, Off = 10, T = 0.82, Art = { 775, 60 } },
			{ Id = "Campamento", Name = "Campamento Salvaje", Kind = "Campamento", Level = 15, Off = -15.5, T = 0.54, Art = { 110, 270 } },
			{ Id = "Portal", Name = "Portal del Bosque", Kind = "Portal", Level = 25, Off = 16.5, T = 0.616, Art = { 940, 215 } },
			{ Id = "Pradera", Name = "Pradera Salvaje", Kind = "Territorio", Level = 10, Off = -15, T = 0.28, Art = { 120, 470 } },
			{ Id = "Ruinas", Name = "Ruinas Antiguas", Kind = "Ruinas", Level = 20, Off = 9.5, T = 0.28, Art = { 760, 470 } },
		},
	},
	LlanurasSalvajes = {
		Description = "Praderas sin dueño donde las manadas corren libres y los nómadas saquean.",
		Tip = "Las manadas se mueven juntas: no te alejes de los caminos de noche.",
		Places = {
			{ Id = "Santuario", Name = "Refugio Nómada", Kind = "Santuario", Off = 0, T = 0.3 },
			{ Id = "Pradera", Name = "Pradera de las Bestias", Kind = "Territorio", Level = 20, Off = -12, T = 0.1 },
			{ Id = "Campamento", Name = "Campamento de Saqueadores", Kind = "Campamento", Level = 25, Off = 14, T = 0.25 },
			{ Id = "Ruinas", Name = "Círculo de Piedras", Boss = true, Kind = "Ruinas", Level = 30, Off = -10, T = 0.55 },
			{ Id = "Cueva", Name = "Madriguera del Minotauro", Kind = "Cueva", Level = 35, Off = 12, T = 0.65 },
			{ Id = "Cascada", Name = "Paso del Río", Kind = "Cascada", Level = 22, Off = -16, T = 0.4 },
			{ Id = "Portal", Name = "Portal de las Llanuras", Kind = "Portal", Level = 35, Off = 16, T = 0.5 },
		},
	},
	PantanoMaldito = {
		Description = "Agua negra, niebla y algo que se mueve bajo el barro. Nadie cruza solo.",
		Tip = "El veneno del pantano se cura con pociones: lleva siempre unas cuantas.",
		Places = {
			{ Id = "Santuario", Name = "Choza del Ermitaño", Kind = "Santuario", Off = 0, T = 0.3 },
			{ Id = "Cienaga", Name = "Ciénaga Tóxica", Kind = "Territorio", Level = 40, Off = 12, T = 0.12 },
			{ Id = "Ruinas", Name = "Cementerio Hundido", Kind = "Ruinas", Level = 45, Off = -9, T = 0.5 },
			{ Id = "Cueva", Name = "Cueva del Nigromante", Kind = "Cueva", Level = 50, Off = 14, T = 0.6 },
			{ Id = "Campamento", Name = "Aldea de los Ahogados", Kind = "Campamento", Level = 48, Off = -15, T = 0.2 },
			{ Id = "Cascada", Name = "Charca Negra", Boss = true, Kind = "Cascada", Level = 55, Off = 8, T = 0.78 },
			{ Id = "Portal", Name = "Portal del Pantano", Kind = "Portal", Level = 55, Off = -16, T = 0.65 },
		},
	},
	DesiertoDorado = {
		Description = "Arena que brilla de noche sobre templos que nadie recuerda haber construido.",
		Tip = "Las tormentas de arena esconden a los escorpiones: mira el suelo.",
		Places = {
			{ Id = "Santuario", Name = "Oasis de la Caravana", Kind = "Santuario", Off = 0, T = 0.3 },
			{ Id = "Dunas", Name = "Dunas de los Escorpiones", Kind = "Territorio", Level = 50, Off = -12, T = 0.12 },
			{ Id = "Campamento", Name = "Campamento del Saqueo", Kind = "Campamento", Level = 55, Off = 14, T = 0.22 },
			{ Id = "Ruinas", Name = "Templo Enterrado", Boss = true, Kind = "Ruinas", Level = 58, Off = -10, T = 0.55 },
			{ Id = "Cueva", Name = "Tumbas de las Momias", Kind = "Cueva", Level = 60, Off = 12, T = 0.62 },
			{ Id = "Cascada", Name = "Pozo Seco", Kind = "Cascada", Level = 52, Off = 16, T = 0.45 },
			{ Id = "Portal", Name = "Arco de las Arenas", Kind = "Portal", Level = 65, Off = -16, T = 0.72 },
		},
	},
	RuinasAntiguas = {
		Description = "Una ciudad más vieja que Valmar. Sus muros tienen las marcas de la Grieta.",
		Tip = "Los espectros no se ven de lejos: avanza despacio entre las columnas.",
		Places = {
			{ Id = "Santuario", Name = "Atalaya de los Exploradores", Kind = "Santuario", Off = 0, T = 0.28 },
			{ Id = "Puerta", Name = "Puerta Rúnica", Kind = "Ruinas", Level = 60, Off = -12, T = 0.12 },
			{ Id = "Plaza", Name = "Plaza de los Caídos", Kind = "Territorio", Level = 65, Off = 12, T = 0.3 },
			{ Id = "Cueva", Name = "Catacumbas", Kind = "Cueva", Level = 70, Off = -14, T = 0.58 },
			{ Id = "Campamento", Name = "Coliseo Espectral", Boss = true, Kind = "Campamento", Level = 74, Off = 14, T = 0.62 },
			{ Id = "Cascada", Name = "Acueducto Roto", Kind = "Cascada", Level = 68, Off = 8, T = 0.8 },
			{ Id = "Portal", Name = "Portal de las Ruinas", Kind = "Portal", Level = 75, Off = -16, T = 0.75 },
		},
	},
	MontanasHeladas = {
		Description = "Nieva en pleno verano. Arriba vive algo con un ala del tamaño de un barco.",
		Tip = "El frío baja la vida poco a poco: busca hogueras y refugios.",
		Places = {
			{ Id = "Santuario", Name = "Refugio de Montaña", Kind = "Santuario", Off = 0, T = 0.28 },
			{ Id = "Lago", Name = "Lago Helado", Kind = "Cascada", Level = 70, Off = 12, T = 0.15 },
			{ Id = "Cueva", Name = "Cueva de Escarcha", Kind = "Cueva", Level = 75, Off = -12, T = 0.45 },
			{ Id = "Territorio", Name = "Paso de los Lobos Árticos", Kind = "Territorio", Level = 72, Off = -15, T = 0.15 },
			{ Id = "Campamento", Name = "Campamento Abandonado", Kind = "Campamento", Level = 80, Off = 14, T = 0.5 },
			{ Id = "Ruinas", Name = "Nido del Draco", Boss = true, Kind = "Ruinas", Level = 85, Off = 6, T = 0.75 },
			{ Id = "Portal", Name = "Portal del Glaciar", Kind = "Portal", Level = 85, Off = -16, T = 0.7 },
		},
	},
	TierrasOscuras = {
		Description = "Aquí la luz de la Grieta no llega: se la comen. Cosme prohibió cruzar el puente negro.",
		Tip = "La oscuridad esconde trampas: lleva la linterna encendida.",
		Places = {
			{ Id = "Santuario", Name = "Bastión de la Luz", Kind = "Santuario", Off = 0, T = 0.26 },
			{ Id = "Bosque", Name = "Bosque Negro", Kind = "Territorio", Level = 80, Off = 12, T = 0.12 },
			{ Id = "Ruinas", Name = "Catedral Corrupta", Kind = "Ruinas", Level = 85, Off = -12, T = 0.42 },
			{ Id = "Cueva", Name = "Abismo del Vacío", Kind = "Cueva", Level = 90, Off = 14, T = 0.6 },
			{ Id = "Campamento", Name = "Altar de Sombras", Boss = true, Kind = "Campamento", Level = 95, Off = -15, T = 0.65 },
			{ Id = "Cascada", Name = "Río de Ceniza", Kind = "Cascada", Level = 88, Off = 16, T = 0.35 },
			{ Id = "Portal", Name = "Portal del Vacío", Kind = "Portal", Level = 98, Off = 4, T = 0.82 },
		},
	},
	TierrasVolcanicas = {
		Description = "El volcán despertó el mismo día que el cielo se rajó. La tierra arde.",
		Tip = "La lava quema aunque no la toques: no te quedes quieto cerca de las grietas.",
		Places = {
			{ Id = "Santuario", Name = "Forja de los Valientes", Kind = "Santuario", Off = 0, T = 0.24 },
			{ Id = "Rios", Name = "Ríos de Lava", Kind = "Territorio", Level = 90, Off = -12, T = 0.12 },
			{ Id = "Campamento", Name = "Fortaleza Infernal", Kind = "Campamento", Level = 95, Off = 14, T = 0.35 },
			{ Id = "Cueva", Name = "Nido del Dragón Infernal", Kind = "Cueva", Level = 105, Off = -14, T = 0.6 },
			{ Id = "Ruinas", Name = "Templo de Ceniza", Kind = "Ruinas", Level = 98, Off = 12, T = 0.65 },
			{ Id = "Cascada", Name = "Cascada de Fuego", Kind = "Cascada", Level = 100, Off = 16, T = 0.15 },
			{ Id = "Portal", Name = "Corazón del Volcán", Boss = true, Kind = "Portal", Level = 110, Off = -4, T = 0.82 },
		},
	},
}

-- Dónde está un lugar en el mundo (x, z)
function RegionGuide.worldOf(regionId: string, place: { [string]: any }): (number, number)
	local reg = VR.ById[regionId]
	local bearing = reg.Bearing + (place.Off or 0)
	-- (T a lo largo del rumbo, desde el borde del antiguo mar: así toLocal es justo lo contrario)
	local dist = VR.rayBox(bearing, 0) + (place.T or 0.3) * VR.Frame.Width
	local a = math.rad(bearing)
	return math.sin(a) * dist, -math.cos(a) * dist
end

-- Todos los lugares de todas las regiones (con su región y su sitio en el mundo)
function RegionGuide.all(): { { [string]: any } }
	local out = {}
	for _, reg in VR.List do
		local g = RegionGuide.List[reg.Id]
		for _, p in (g and g.Places or {}) do
			local x, z = RegionGuide.worldOf(reg.Id, p)
			table.insert(out, { Region = reg.Id, Place = p, X = x, Z = z })
		end
	end
	return out
end

-- Del mundo a la región: (grados desde el centro del sector, T) — lo contrario de worldOf
function RegionGuide.toLocal(regionId: string, x: number, z: number): (number, number)
	local reg = VR.ById[regionId]
	local b = VR.bearing(x, z)
	local off = ((b - reg.Bearing + 540) % 360) - 180
	local edge = VR.rayBox(b, 0)
	local dist = math.sqrt(x * x + z * z)
	return off, (dist - edge) / VR.Frame.Width
end

-- El dibujo de una región: Off −20..20 de izquierda a derecha y T de 0,9 (arriba, lo lejano) a 0,05 (abajo)
RegionGuide.ArtOff, RegionGuide.ArtTop, RegionGuide.ArtBottom = 20, 0.9, 0.05
function RegionGuide.artOf(off: number, t: number, w: number, h: number): (number, number)
	local px = (0.5 + off / (RegionGuide.ArtOff * 2)) * w
	local py = (RegionGuide.ArtTop - t) / (RegionGuide.ArtTop - RegionGuide.ArtBottom) * h
	return math.clamp(px, 0, w), math.clamp(py, 0, h)
end

return RegionGuide
