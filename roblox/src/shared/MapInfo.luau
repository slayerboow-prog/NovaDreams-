-- MapInfo: los distritos de Valmar y los tipos de lugares que salen en el mapa.
--
-- Los 6 distritos salen del plano de la ciudad (CityPlan): Centro (azul), Norte (verde), Oeste (rojo),
-- Este (morado), Universitario (celeste) y Sur (amarillo). Cada uno contiene barrios con nombre
-- (Valmar Centro, Los Pinos, Campus Valmar…), que son las zonas que usa la historia.
-- Los lugares (hospital, colegios, faro, puerto…) los publica el servidor en ReplicatedStorage.MapLandmarks
-- buscando en el mapa los modelos con estos nombres, así que el mapa se actualiza solo si la ciudad cambia.

local MapInfo = {}

export type District = {
	Id: string,
	Name: string, -- nombre del distrito en el mapa
	Theme: string,
	Icon: string,
	Color: Color3,
	Poly: { { number } }, -- polígono (X, Z del mundo)
	Center: Vector2, -- dónde va su etiqueta
}

local CityPlan = require(script.Parent.CityPlan)

-- Los 6 distritos del plano de la ciudad (CityPlan.Districts)
MapInfo.Districts = {} :: { District }
for _, d in CityPlan.Districts do
	local cx, cz = 0, 0
	for _, p in d.Poly do
		cx += p[1]
		cz += p[2]
	end
	table.insert(MapInfo.Districts, {
		Id = d.Id,
		Name = d.Name,
		Theme = d.Theme,
		Icon = d.Icon,
		Color = Color3.fromRGB(d.Color[1], d.Color[2], d.Color[3]),
		Poly = d.Poly,
		Center = Vector2.new(cx / #d.Poly, cz / #d.Poly),
	})
end

-- Límites del mapa grande (X, Z del mundo): toda la isla y el mar de alrededor
MapInfo.BoundsMin = Vector2.new(CityPlan.Bounds.MinX, CityPlan.Bounds.MinZ)
MapInfo.BoundsMax = Vector2.new(CityPlan.Bounds.MaxX, CityPlan.Bounds.MaxZ)

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
	{ Model = "TorreValmar", Icon = "🏙️", Name = "Torre de Valmar", Important = true },
	{ Model = "Ayuntamiento", Icon = "🏛️", Name = "Ayuntamiento", Important = true },
	{ Model = "EstacionCentral", Icon = "🚆", Name = "Estación Central", Important = true },
	{ Model = "EstacionAutobuses", Icon = "🚌", Name = "Estación de Autobuses", Important = true },
	{ Model = "Museo", Icon = "🖼️", Name = "Museo de Valmar", Important = true },
	{ Model = "Teatro", Icon = "🎭", Name = "Teatro Principal", Important = true },
	{ Model = "GranCentroComercial", Icon = "🛍️", Name = "Centro Comercial Valmar", Important = true },
	{ Model = "Feria", Icon = "🎡", Name = "Parque de Atracciones", Important = true },
	{ Model = "Camping", Icon = "⛺", Name = "Camping Valmar", Important = true },
	{ Model = "Marina", Icon = "⛵", Name = "Puerto Deportivo", Important = true },
	{ Model = "Supermercado", Icon = "🛒", Name = "Supermercado", Important = true },
} :: { Kind }

MapInfo.KindByModel = {} :: { [string]: Kind }
for _, kind in MapInfo.Kinds do
	MapInfo.KindByModel[kind.Model] = kind
end

-- Grupos de la leyenda (se pueden ocultar en el mapa grande)
MapInfo.Legend = {
	{ Name = "Salud y emergencias", Icon = "🏥", Models = { "Hospital", "CentroSalud", "Policia", "Bomberos" } },
	{ Name = "Estudios", Icon = "🏫", Models = { "Colegio", "Facultad", "Autoescuela" } },
	{ Name = "Tiendas y comida", Icon = "🛍️", Models = { "CentroComercial", "Supermercado", "Restaurante", "Gasolinera", "PlazaFinanciera" } },
	{ Name = "Ocio y naturaleza", Icon = "🌳", Models = { "Parque", "Estadio", "Playa", "Granja", "Recreativos", "Plaza", "Mirador", "Faro", "Puerto", "Feria", "Camping", "Marina", "Museo", "Teatro" } },
	{ Name = "Ciudad y transporte", Icon = "🏛️", Models = { "TorreValmar", "Ayuntamiento", "EstacionCentral", "EstacionAutobuses", "GranCentroComercial" } },
}

-- Distrito en el que cae una posición (o nil si es mar o montaña)
function MapInfo.districtAt(x: number, z: number): District?
	for _, d in MapInfo.Districts do
		if CityPlan.inside(d.Poly, x, z) then
			return d
		end
	end
	return nil
end

return MapInfo
