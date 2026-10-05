-- MapLegend: la leyenda del mapa por CATEGORÍAS (lo usan Controllers/MapUI y HomeMapService).
--
--   * Cada tipo de lugar (shared/MapInfo.Kinds) va en UNA categoría: «Gimnasios», «Supermercados»,
--     «Tiendas de ropa», «Gasolineras», «Restaurantes y bares»… Así un tipo que se repite (7 gimnasios,
--     12 bares) sale una sola vez en la leyenda, con su icono y cuántos hay: «🏋️ Gimnasios (7)».
--   * Tocar una categoría oculta (o muestra) TODOS sus lugares a la vez, en el mapa grande y en el
--     minimapa. Lo oculto se guarda con la partida (HomeMapService: atributo MapHidden, «Id,Id»).
--   * 🏠 Casa NO es una categoría: no se puede ocultar. Sale siempre, con cualquier filtro.
--
--   MapLegend.categoryOf(model)            -> la categoría de un tipo de lugar (o nil)
--   MapLegend.summary(models)              -> { { Category, Count } } de las categorías con algún lugar
--   MapLegend.title(category, count)       -> "🏋️ Gimnasios (7)"
--   MapLegend.visible(hidden, model)       -> ¿se ve un lugar de ese tipo?
--   MapLegend.toggle(hidden, id)           -> oculta o muestra una categoría (devuelve si queda oculta)
--   MapLegend.setAll(hidden, hide)         -> todas ocultas o todas a la vista
--   MapLegend.encode(hidden) / decode(text)
--   MapLegend.homeMarkers(familyPos, ownPos) -> los 🏠 de tus casas (siempre visibles)

local MapLegend = {}

export type Category = { Id: string, Name: string, Icon: string, Models: { string } }

MapLegend.Categories = {
	{ Id = "Gimnasios", Name = "Gimnasios", Icon = "🏋️", Models = { "GimnasioValmar", "LocalGimnasio" } },
	{ Id = "Supermercados", Name = "Supermercados", Icon = "🛒", Models = { "Supermercado", "LocalSuper" } },
	{ Id = "Ropa", Name = "Tiendas de ropa", Icon = "👕", Models = { "LocalRopa" } },
	{ Id = "Gasolineras", Name = "Gasolineras", Icon = "⛽", Models = { "Gasolinera" } },
	{ Id = "Restaurantes", Name = "Restaurantes y bares", Icon = "🍽️", Models = { "Restaurante", "LocalComida" } },
	{ Id = "CentrosComerciales", Name = "Centros comerciales", Icon = "🛍️", Models = { "CentroComercial", "GranCentroComercial" } },
	{ Id = "Tiendas", Name = "Otras tiendas", Icon = "🏪", Models = { "TiendaPesca", "Armeria" } },
	{ Id = "Hoteles", Name = "Hoteles", Icon = "🏨", Models = { "Hotel" } },
	{ Id = "Salud", Name = "Hospitales y salud", Icon = "🏥", Models = { "Hospital", "CentroSalud", "LocalFarmacia" } },
	{ Id = "Emergencias", Name = "Policía y bomberos", Icon = "🚓", Models = { "Policia", "Bomberos" } },
	{ Id = "Colegios", Name = "Colegios", Icon = "🏫", Models = { "Colegio" } },
	{ Id = "Universidad", Name = "Universidad y residencias", Icon = "🎓", Models = { "Facultad", "Residencia" } },
	{ Id = "Autoescuelas", Name = "Autoescuelas", Icon = "🚗", Models = { "Autoescuela" } },
	{ Id = "Parques", Name = "Parques", Icon = "🌳", Models = { "Parque" } },
	{ Id = "Ocio", Name = "Ocio y cultura", Icon = "🎭", Models = { "Estadio", "Recreativos", "Feria", "Museo", "Teatro", "Camping" } },
	{ Id = "Naturaleza", Name = "Naturaleza y animales", Icon = "🐾", Models = { "Playa", "Granja", "Mirador", "Faro", "Protectora", "CampoAnimales" } },
	{ Id = "Puertos", Name = "Puertos y pesca", Icon = "⚓", Models = { "Puerto", "Marina", "ZonaPesca" } },
	{ Id = "Bus", Name = "Paradas de bus", Icon = "🚏", Models = { "ParadaBus", "EstacionAutobuses" } },
	{ Id = "Tren", Name = "Metro y tren", Icon = "🚇", Models = { "BocaMetro", "EstacionCercanias", "EstacionCentral" } },
	{ Id = "Aeropuertos", Name = "Aeropuertos", Icon = "✈️", Models = { "Aeropuerto", "Aerodromo" } },
	{ Id = "Ciudad", Name = "Lugares de la ciudad", Icon = "🏛️", Models = { "Plaza", "PlazaFinanciera", "TorreValmar", "Ayuntamiento", "CasaCosme" } },
	{ Id = "Instituciones", Name = "Instituciones", Icon = "⚖️", Models = { "PalacioJusticia", "CentroPenitenciario", "CuartelEjercito", "AgenciaTributaria" } },
} :: { Category }

-- Tu casa: siempre en el mapa (no es una categoría y no se puede ocultar)
MapLegend.Home = { Icon = "🏠", Name = "Casa", Family = "Casa familiar" }

local byModel: { [string]: Category } = {}
local byId: { [string]: Category } = {}
for _, category in MapLegend.Categories do
	byId[category.Id] = category
	for _, model in category.Models do
		byModel[model] = category
	end
end
MapLegend.CategoryById = byId

function MapLegend.categoryOf(model: string): Category?
	return byModel[model]
end

-- Cuántos lugares hay de cada categoría (solo las que tienen alguno), en el orden de la leyenda.
-- models = el tipo (Model) de cada lugar del mapa, repetidos tantas veces como lugares haya
function MapLegend.summary(models: { string }): { { Category: Category, Count: number } }
	local counts: { [string]: number } = {}
	for _, model in models do
		local category = byModel[model]
		if category then
			counts[category.Id] = (counts[category.Id] or 0) + 1
		end
	end
	local out = {}
	for _, category in MapLegend.Categories do
		local n = counts[category.Id]
		if n and n > 0 then
			table.insert(out, { Category = category, Count = n })
		end
	end
	return out
end

function MapLegend.title(category: Category, count: number): string
	return ("%s %s (%d)"):format(category.Icon, category.Name, count)
end

-- ¿Se ve un lugar de este tipo? (los tipos sin categoría, siempre)
function MapLegend.visible(hidden: { [string]: boolean }, model: string): boolean
	local category = byModel[model]
	return category == nil or not hidden[category.Id]
end

-- Oculta o muestra una categoría entera. Devuelve true si queda oculta.
function MapLegend.toggle(hidden: { [string]: boolean }, id: string): boolean
	if not byId[id] then
		return false
	end
	if hidden[id] then
		hidden[id] = nil
		return false
	end
	hidden[id] = true
	return true
end

function MapLegend.setAll(hidden: { [string]: boolean }, hide: boolean)
	for _, category in MapLegend.Categories do
		hidden[category.Id] = if hide then true else nil
	end
end

-- Para guardar: "Gimnasios,Ropa" (solo categorías que existen, en orden)
function MapLegend.encode(hidden: { [string]: boolean }): string
	local list = {}
	for _, category in MapLegend.Categories do
		if hidden[category.Id] then
			table.insert(list, category.Id)
		end
	end
	return table.concat(list, ",")
end

function MapLegend.decode(text: any): { [string]: boolean }
	local hidden = {}
	if type(text) == "string" then
		for id in string.gmatch(text, "[^,]+") do
			if byId[id] then
				hidden[id] = true
			end
		end
	elseif type(text) == "table" then
		for id, value in text do
			if value == true and type(id) == "string" and byId[id] then
				hidden[id] = true
			end
		end
	end
	return hidden
end

-- Tus casas en el mapa. familyPos = la casa familiar (atributo FamilyHomePos); ownPos = la tuya
-- (OwnHomePos: la que compraste, la que te tocó o tu habitación de la residencia). Si tienes las
-- dos, la tuya es «Casa» y la de tu familia «Casa familiar»; si solo tienes una, es «Casa».
-- No dependen de ningún filtro: salen siempre.
export type HomeMarker = { Id: string, Icon: string, Name: string, Position: Vector3, Family: boolean }
function MapLegend.homeMarkers(familyPos: any, ownPos: any): { HomeMarker }
	local out: { HomeMarker } = {}
	local hasFamily = typeof(familyPos) == "Vector3"
	local hasOwn = typeof(ownPos) == "Vector3"
	if hasOwn then
		table.insert(out, { Id = "Casa", Icon = MapLegend.Home.Icon, Name = MapLegend.Home.Name, Position = ownPos, Family = false })
	end
	if hasFamily then
		local same = hasOwn and Vector3.new(familyPos.X - ownPos.X, 0, familyPos.Z - ownPos.Z).Magnitude < 30
		if not same then
			table.insert(out, {
				Id = if hasOwn then "CasaFamiliar" else "Casa",
				Icon = MapLegend.Home.Icon,
				Name = if hasOwn then MapLegend.Home.Family else MapLegend.Home.Name,
				Position = familyPos,
				Family = true,
			})
		end
	end
	return out
end

return MapLegend
