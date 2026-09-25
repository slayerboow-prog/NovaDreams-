-- MapInfo: los distritos de Valmar y los tipos de lugares que salen en el mapa.
--
-- Cada ciudad de la región es un distrito con su color (como en el mapa ilustrado):
--   Norte (verde), Oeste (rojo), Centro (azul), Este (morado), Sur (amarillo), Universitario (celeste)
--   más el Financiero (naranja) y el campo de Villaverde (verde claro).
-- Los lugares (hospital, colegios, faro, puerto…) los publica el servidor en ReplicatedStorage.MapLandmarks
-- buscando en el mapa los modelos con estos nombres, así que el mapa se actualiza solo si la ciudad cambia.

local MapInfo = {}

export type District = {
	Town: string, -- nombre de la ciudad en el juego (no cambiar: lo usa la historia)
	Name: string, -- nombre del distrito en el mapa
	Theme: string,
	Icon: string,
	Color: Color3,
	Min: Vector2, -- rectángulo que ocupa (X, Z del mundo)
	Max: Vector2,
}

local rgb = Color3.fromRGB

local function area(cx: number, cz: number, half: number): (Vector2, Vector2)
	return Vector2.new(cx - half, cz - half), Vector2.new(cx + half, cz + half)
end

local function district(town: string, name: string, theme: string, icon: string, color: Color3, cx: number, cz: number, half: number?): District
	local min, max = area(cx, cz, half or 385)
	return { Town = town, Name = name, Theme = theme, Icon = icon, Color = color, Min = min, Max = max }
end

MapInfo.Districts = {
	{
		Town = "Valmar Centro",
		Name = "Distrito Centro",
		Theme = "El corazón de Valmar",
		Icon = "⛲",
		Color = rgb(50, 130, 255),
		Min = Vector2.new(-385, -200),
		Max = Vector2.new(385, 265),
	},
	district("Valmar Norte", "Distrito Norte", "Naturaleza y familia", "🌳", rgb(70, 190, 90), 0, -560, 375),
	district("San Roque", "Distrito Oeste", "Cultura y tradición", "🎭", rgb(230, 70, 70), -1250, 0),
	district("Playa Dorada", "Distrito Este", "Ocio, negocios y playa", "🎡", rgb(160, 90, 240), 1250, 0),
	district("Los Pinos", "Distrito Sur", "Comercio y hogares", "🛍", rgb(245, 190, 40), 0, 1100),
	district("Campus Valmar", "Distrito Universitario", "Estudios y juventud", "🎓", rgb(40, 200, 220), -1250, -1100),
	district("Distrito Financiero", "Distrito Financiero", "Oficinas y rascacielos", "🏦", rgb(250, 130, 40), -1250, 1100),
	district("Villaverde", "Villaverde", "Granjas y campo", "🚜", rgb(150, 200, 70), 1250, -1100),
	-- Barrios nuevos entre las ciudades (World/Kit/Barrios.luau)
	{ Town = "Zona Industrial", Name = "Zona Industrial", Theme = "Naves y puerto", Icon = "🏭", Color = rgb(150, 150, 165), Min = Vector2.new(1020, 390), Max = Vector2.new(1480, 1440) },
	{ Town = "Zona Industrial", Name = "Zona Industrial", Theme = "Naves y puerto", Icon = "🏭", Color = rgb(150, 150, 165), Min = Vector2.new(390, 670), Max = Vector2.new(1010, 1130) },
	{ Town = "Parque Empresarial", Name = "Parque Empresarial", Theme = "Oficinas", Icon = "🏢", Color = rgb(250, 160, 80), Min = Vector2.new(-850, 380), Max = Vector2.new(-430, 1440) },
	{ Town = "Las Huertas", Name = "Las Huertas", Theme = "Huertas y campo", Icon = "🥕", Color = rgb(170, 200, 90), Min = Vector2.new(430, -1440), Max = Vector2.new(850, -250) },
	{ Town = "Bosque Alto", Name = "Bosque Alto", Theme = "Urbanización", Icon = "🌲", Color = rgb(110, 170, 110), Min = Vector2.new(-850, -1440), Max = Vector2.new(-430, -250) },
	{ Town = "El Olivar", Name = "El Olivar", Theme = "Urbanización", Icon = "🏡", Color = rgb(120, 170, 230), Min = Vector2.new(-870, -380), Max = Vector2.new(-410, 380) },
	{ Town = "Mirasol", Name = "Mirasol", Theme = "Urbanización", Icon = "🏡", Color = rgb(120, 170, 230), Min = Vector2.new(410, -380), Max = Vector2.new(870, 380) },
	{ Town = "Las Acacias", Name = "Las Acacias", Theme = "Urbanización", Icon = "🏡", Color = rgb(240, 200, 90), Min = Vector2.new(-370, 290), Max = Vector2.new(370, 690) },
} :: { District }

-- Límites del mapa grande (X, Z del mundo): toda la región, el mar y la isla del faro
MapInfo.BoundsMin = Vector2.new(-1780, -1640)
MapInfo.BoundsMax = Vector2.new(2260, 1640)
MapInfo.CoastX = 1640 -- a partir de aquí, mar

-- Tipos de lugares. Model = nombre del modelo en el mapa.
-- Important = sale en la lista "Lugares importantes"; Merge = junta los que están cerca (playa, granjas)
export type Kind = { Model: string, Icon: string, Name: string, Important: boolean?, Merge: number? }

MapInfo.Kinds = {
	{ Model = "Plaza", Icon = "⛲", Name = "Plaza Mayor", Important = true },
	{ Model = "Hospital", Icon = "🏥", Name = "Hospital", Important = true },
	{ Model = "CentroSalud", Icon = "⚕️", Name = "Centro de salud" },
	{ Model = "Colegio", Icon = "🏫", Name = "Colegio" },
	{ Model = "Facultad", Icon = "🎓", Name = "Universidad", Important = true, Merge = 700 },
	{ Model = "Estadio", Icon = "🏟️", Name = "Estadio", Important = true },
	{ Model = "Parque", Icon = "🌳", Name = "Parque" },
	{ Model = "CentroComercial", Icon = "🛍️", Name = "Centro comercial" },
	{ Model = "Gasolinera", Icon = "⛽", Name = "Gasolinera" },
	{ Model = "Policia", Icon = "🚓", Name = "Policía" },
	{ Model = "Bomberos", Icon = "🚒", Name = "Bomberos" },
	{ Model = "Playa", Icon = "🏖️", Name = "Playa Dorada", Important = true, Merge = 900 },
	{ Model = "Granja", Icon = "🚜", Name = "Granjas", Important = true, Merge = 900 },
	{ Model = "PlazaFinanciera", Icon = "🏦", Name = "Plaza Financiera", Important = true },
	{ Model = "Restaurante", Icon = "🍽️", Name = "Restaurante", Important = true },
	{ Model = "Autoescuela", Icon = "🚗", Name = "Autoescuela" },
	{ Model = "Recreativos", Icon = "🕹️", Name = "Recreativos" },
	{ Model = "Puerto", Icon = "⚓", Name = "Puerto de Valmar", Important = true },
	{ Model = "Faro", Icon = "🗼", Name = "Isla del Faro", Important = true },
	{ Model = "Mirador", Icon = "🔭", Name = "Mirador", Important = true },
} :: { Kind }

MapInfo.KindByModel = {} :: { [string]: Kind }
for _, kind in MapInfo.Kinds do
	MapInfo.KindByModel[kind.Model] = kind
end

-- Grupos de la leyenda (se pueden ocultar en el mapa grande)
MapInfo.Legend = {
	{ Name = "Salud y emergencias", Icon = "🏥", Models = { "Hospital", "CentroSalud", "Policia", "Bomberos" } },
	{ Name = "Estudios", Icon = "🏫", Models = { "Colegio", "Facultad", "Autoescuela" } },
	{ Name = "Tiendas y comida", Icon = "🛍️", Models = { "CentroComercial", "Restaurante", "Gasolinera", "PlazaFinanciera" } },
	{ Name = "Ocio y naturaleza", Icon = "🌳", Models = { "Parque", "Estadio", "Playa", "Granja", "Recreativos", "Plaza", "Mirador", "Faro", "Puerto" } },
}

-- Distrito en el que cae una posición (o nil si es campo o mar)
function MapInfo.districtAt(x: number, z: number): District?
	for _, d in MapInfo.Districts do
		if x >= d.Min.X and x <= d.Max.X and z >= d.Min.Y and z <= d.Max.Y then
			return d
		end
	end
	return nil
end

function MapInfo.districtOfTown(town: string): District?
	for _, d in MapInfo.Districts do
		if d.Town == town then
			return d
		end
	end
	return nil
end

return MapInfo
