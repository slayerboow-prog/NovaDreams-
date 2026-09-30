-- Catalog: índice de TODO lo que el pase puede dar, de todas las temporadas, por su Id
-- (recompensas de nivel, lo que va dentro de un conjunto, el premio de la historia y la tienda de fichas).
-- Sirve para saber qué es algo que un jugador tiene guardado (data.Cosmetics.Owned) aunque sea de
-- una temporada vieja, y a la interfaz para pintar títulos, placas y temas equipados.
--
--   Catalog.get("S1_P50_Car")  -> la definición (con .Season = "S1") o nil si ya no existe

local BPConfig = require(script.Parent.Config)

local Catalog = {}

local index: { [string]: { [string]: any } } = {}

local function put(def: { [string]: any }, seasonId: string, parent: string?)
	if type(def) ~= "table" or type(def.Id) ~= "string" then
		return
	end
	local entry = table.clone(def)
	entry.Season = seasonId
	entry.Parent = parent
	index[def.Id] = entry
	if def.Type == "Bundle" and type(def.Items) == "table" then
		for _, item in def.Items do
			if type(item) == "table" then
				local copy = table.clone(item)
				copy.Rarity = copy.Rarity or def.Rarity
				copy.Description = copy.Description or def.Description
				put(copy, seasonId, def.Id)
			end
		end
	end
end

for _, season in BPConfig.Seasons do
	for _, reward in season.Rewards or {} do
		put(reward, season.Id)
	end
	for _, story in (season.Missions and season.Missions.Story) or {} do
		if story.Reward then
			put(story.Reward, season.Id)
		end
	end
	for _, item in season.TokenShop or {} do
		put(item, season.Id)
	end
end

function Catalog.get(id: any): { [string]: any }?
	return if type(id) == "string" then index[id] else nil
end

function Catalog.all(): { [string]: { [string]: any } }
	return index
end

return Catalog
