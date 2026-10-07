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

-- Lo que el pase te ha dado y vive FUERA de Cosmetics (en data.Vehicles y data.Prizes): los vehículos
-- (VehicleSkin con GrantsBase, como la Moto premium, y los de tipo Vehicle) y los premios para llevar
-- puestos (Wearable: gafas, gorra…). «Vida nueva» borra data.Vehicles y data.Prizes pero conserva
-- Cosmetics y BattlePass: VehicleService y ArcadeService los recuperan de aquí (como BoatService con
-- los barcos). Se mira Cosmetics.Owned y, para lo reclamado antes de que se apuntara ahí (Wearable /
-- Vehicle), los niveles reclamados de la temporada guardada en BattlePass.
--   Catalog.passBelongings(data) -> { Vehicles = { Moto = true }, Prizes = { Gafas = true } }
function Catalog.passBelongings(data: any): { Vehicles: { [string]: boolean }, Prizes: { [string]: boolean } }
	local out = { Vehicles = {}, Prizes = {} }
	if type(data) ~= "table" then
		return out
	end
	local function take(def: any, depth: number)
		if type(def) ~= "table" or depth > 3 then
			return
		end
		if (def.Type == "VehicleSkin" and def.GrantsBase) or def.Type == "Vehicle" then
			if type(def.Kind) == "string" then
				out.Vehicles[def.Kind] = true
			end
		elseif def.Type == "Wearable" then
			if type(def.Kind) == "string" then
				out.Prizes[def.Kind] = true
			end
		elseif def.Type == "Bundle" and type(def.Items) == "table" then
			for _, item in def.Items do
				take(type(item) == "table" and (index[item.Id] or item) or nil, depth + 1)
			end
		end
	end
	local cosmetics = data.Cosmetics
	if type(cosmetics) == "table" and type(cosmetics.Owned) == "table" then
		for id, info in cosmetics.Owned do
			if info then
				take(index[id], 0)
			end
		end
	end
	local bp = data.BattlePass
	if type(bp) == "table" and type(bp.SeasonId) == "string" then
		for _, season in BPConfig.Seasons do
			if season.Id == bp.SeasonId then
				for _, reward in season.Rewards or {} do
					local set = if reward.Track == "Free" then bp.ClaimedFree else bp.ClaimedPremium
					local def = index[reward.Id] or reward
					if type(set) == "table" and set[tostring(reward.Level)] and (def.Type == "Wearable" or def.Type == "Vehicle") then
						take(def, 0)
					end
				end
			end
		end
	end
	return out
end

-- Los vehículos premium del pase (shared/PremiumVehicles), en el orden de la hoja: cada modelo con su
-- pintura de siempre y, detrás, cada acabado especial del pase de ese modelo (el Aurora X «Faro de
-- Valmar» del nivel 50, con su color y detalles en oro). Lo usa el modo pruebas para sacarlos y darlos.
--   { Id, Name, Kind, Model, Rarity, Icon, Color: Color3, Trim: Color3?, RewardId: string? }
-- RewardId = la recompensa del catálogo que da ese vehículo (nil si ninguna lo da tal cual).
function Catalog.vehicles(): { { [string]: any } }
	local PremiumVehicles = require(script.Parent.Parent.PremiumVehicles)
	local out = {}
	for _, modelId in PremiumVehicles.List do
		local v = PremiumVehicles.get(modelId)
		if v then
			local base: { [string]: any } = {
				Id = modelId, Name = v.Name, Kind = v.Kind, Model = modelId, Rarity = v.Rarity,
				Icon = if v.Kind == "Moto" then "🏍️" else "🏎️",
				Color = Color3.fromRGB(v.Paint[1], v.Paint[2], v.Paint[3]),
			}
			local variants = {}
			for id, def in index do
				if def.Type == "VehicleSkin" and def.Model == modelId then
					if def.Name == v.Name and typeof(def.Trim) ~= "Color3" then
						base.RewardId = base.RewardId or id
					else
						table.insert(variants, {
							Id = id, Name = def.Name, Kind = v.Kind, Model = modelId, Rarity = def.Rarity or v.Rarity,
							Icon = def.Icon or base.Icon, Color = if typeof(def.Color) == "Color3" then def.Color else base.Color,
							Trim = if typeof(def.Trim) == "Color3" then def.Trim else nil, RewardId = id,
						})
					end
				end
			end
			table.sort(variants, function(a, b)
				return a.Id < b.Id
			end)
			table.insert(out, base)
			for _, variant in variants do
				table.insert(out, variant)
			end
		end
	end
	return out
end

return Catalog
