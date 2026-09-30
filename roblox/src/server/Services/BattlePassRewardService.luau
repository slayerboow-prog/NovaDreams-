-- BattlePassRewardService: entrega las recompensas del pase con los sistemas de SIEMPRE del juego.
--   Money        -> DataService.addMoney (no cuenta como sueldo: ni Hacienda ni «ganado trabajando»)
--   CharacterXp  -> ProgressionService.addXp
--   Tickets      -> ArcadeService.addTickets
--   Vehicle      -> VehicleService.grant (el vehículo normal, mismas prestaciones)
--   VehicleSkin  -> acabado exclusivo (color/material) de un vehículo normal: VehicleService lo pinta al
--                   sacarlo (VehicleService.PaintFor). Mismas prestaciones. GrantsBase: da también el vehículo.
--   Wearable     -> ArcadeService.grantPrize (gafas, gorra)
--   Outfit       -> colores del aspecto de Valmar (AvatarService.OutfitFor)
--   HomeTheme / Decor -> tu vivienda de siempre (PropertyService.DecorateOwned): colores de suelo y
--                   paredes y hasta MAX_DECOR objetos. No crea casas nuevas ni toca el registro de dueños.
--   Boat         -> adaptador (todavía no hay barcos propios): se guarda como tuyo y, el día que exista
--                   Services/BoatService con grant(player, kind, def), se le pasa.
--   Emote / Title / Nameplate / PhoneTheme / HudSkin / Story / Perk -> colección (data.Cosmetics) +
--                   atributos del jugador para la interfaz.
--   Tokens       -> data.Cosmetics.Tokens
--   Bundle       -> cada cosa de dentro
--
-- Lo conseguido se guarda en data.Cosmetics (fuera del pase): al cambiar de temporada NO se borra.
-- Atributos (para la interfaz; los de título y placa los ven todos): BP_Title, BP_TitleColor,
-- BP_Nameplate, BP_PhoneTheme, BP_HudSkin, BP_Outfit, BP_HomeTheme, BP_Emotes (Ids separados por
-- comas), BP_Tokens.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.BattlePass.Catalog)
local DataService = require(script.Parent.DataService)
local BattlePassSeasonService = require(script.Parent.BattlePassSeasonService)

local BattlePassRewardService = {}

local MAX_DECOR = 6 -- objetos de decoración del pase a la vez en tu vivienda

-- Qué tipos se equipan y en qué hueco
local EQUIP_SLOT = {
	Title = "Title", Nameplate = "Nameplate", PhoneTheme = "PhoneTheme", HudSkin = "HudSkin",
	HomeTheme = "HomeTheme", Outfit = "Outfit", VehicleSkin = "VehicleSkin",
}
BattlePassRewardService.EquipSlot = EQUIP_SLOT
BattlePassRewardService.MaxDecor = MAX_DECOR

-- Servicios del juego, cargados al usarlos (así no hay dependencias circulares y, si uno falta, el
-- pase sigue funcionando)
local function service(name: string): any
	local ok, result = pcall(function()
		return require(script.Parent[name])
	end)
	return if ok then result else nil
end

local function cosmeticsOf(data: { [string]: any }): { [string]: any }
	BattlePassSeasonService.ensure(data)
	return data.Cosmetics
end

function BattlePassRewardService.owns(data: { [string]: any }, id: string): boolean
	local c = cosmeticsOf(data)
	return c.Owned[id] ~= nil
end

local function own(data: { [string]: any }, def: { [string]: any }, seasonId: string?)
	local c = cosmeticsOf(data)
	if not c.Owned[def.Id] then
		c.Owned[def.Id] = { Type = def.Type, Season = seasonId or def.Season or "", At = os.time() }
	end
end

---------------------------------------------------------------------
-- Atributos para la interfaz
---------------------------------------------------------------------

function BattlePassRewardService.sync(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local c = cosmeticsOf(data)
	local eq = c.Equipped
	local title = Catalog.get(eq.Title)
	player:SetAttribute("BP_Title", if title then title.Text or title.Name else nil)
	player:SetAttribute("BP_TitleColor", if title and typeof(title.Color) == "Color3" then title.Color else nil)
	player:SetAttribute("BP_Nameplate", if Catalog.get(eq.Nameplate) then eq.Nameplate else nil)
	player:SetAttribute("BP_PhoneTheme", if Catalog.get(eq.PhoneTheme) then eq.PhoneTheme else nil)
	player:SetAttribute("BP_HudSkin", if Catalog.get(eq.HudSkin) then eq.HudSkin else nil)
	player:SetAttribute("BP_Outfit", if Catalog.get(eq.Outfit) then eq.Outfit else nil)
	player:SetAttribute("BP_HomeTheme", if Catalog.get(eq.HomeTheme) then eq.HomeTheme else nil)
	local emotes = {}
	for id, info in c.Owned do
		if type(info) == "table" and info.Type == "Emote" and Catalog.get(id) then
			table.insert(emotes, id)
		end
	end
	table.sort(emotes)
	player:SetAttribute("BP_Emotes", table.concat(emotes, ","))
	player:SetAttribute("BP_Tokens", c.Tokens)
end

---------------------------------------------------------------------
-- Adaptadores: el pase pide, cada sistema de siempre entrega
---------------------------------------------------------------------

-- Barcos: todavía no hay barcos propios en el juego. La recompensa se guarda como tuya y, cuando
-- exista Services/BoatService (con grant(player, kind, def) -> boolean), se entrega de verdad.
local BoatAdapter = {}
function BoatAdapter.available(): boolean
	local boats = service("BoatService")
	return boats ~= nil and type(boats.grant) == "function"
end
function BoatAdapter.grant(player: Player, def: { [string]: any }): boolean
	local boats = service("BoatService")
	if boats and type(boats.grant) == "function" then
		local ok, result = pcall(boats.grant, player, def.Kind, def)
		return ok and result ~= false
	end
	return true -- (guardado en la colección: se entregará cuando llegue el sistema de barcos)
end
BattlePassRewardService.BoatAdapter = BoatAdapter

local function applyOutfit(player: Player)
	local avatar = service("AvatarService")
	if avatar and avatar.apply and player.Character then
		pcall(avatar.apply, player)
	end
end

-- Equipa algo si ese hueco está vacío (lo primero que consigues se pone solo)
local function autoEquip(player: Player, data: { [string]: any }, def: { [string]: any })
	local c = cosmeticsOf(data)
	local slot = EQUIP_SLOT[def.Type]
	if slot == "VehicleSkin" then
		if def.Kind and not c.Equipped.VehicleSkin[def.Kind] then
			c.Equipped.VehicleSkin[def.Kind] = def.Id
		end
	elseif slot then
		if c.Equipped[slot] == nil then
			c.Equipped[slot] = def.Id
			if slot == "Outfit" then
				applyOutfit(player)
			end
		end
	elseif def.Type == "Decor" and #c.Equipped.Decor < MAX_DECOR and not table.find(c.Equipped.Decor, def.Id) then
		table.insert(c.Equipped.Decor, def.Id)
	end
end

local grantOne: (Player, { [string]: any }, { [string]: any }, string?) -> (boolean, string?)

-- Entrega una recompensa. Devuelve true si se entregó; si no, false y el motivo:
--   "NoData" (reintentar más tarde) · "Unknown" (tipo o contenido que ya no existe: dar compensación)
--   "Failed" (el sistema no pudo ahora: reintentar)
function grantOne(player: Player, data: { [string]: any }, def: { [string]: any }, seasonId: string?): (boolean, string?)
	local kind = def.Type
	local amount = math.floor(tonumber(def.Amount) or 0)
	if kind == "Money" then
		if amount <= 0 then
			return false, "Unknown"
		end
		return DataService.addMoney(player, amount), "Failed"
	elseif kind == "CharacterXp" then
		local progression = service("ProgressionService")
		if not progression or amount <= 0 then
			return false, if amount <= 0 then "Unknown" else "Failed"
		end
		progression.addXp(player, amount) -- (sin fuente: no tiene tope por minuto)
		return true
	elseif kind == "Tickets" then
		local arcade = service("ArcadeService")
		if not arcade or not arcade.addTickets or amount <= 0 then
			return false, if amount <= 0 then "Unknown" else "Failed"
		end
		return arcade.addTickets(player, amount), "Failed"
	elseif kind == "Tokens" then
		if amount <= 0 then
			return false, "Unknown"
		end
		local c = cosmeticsOf(data)
		c.Tokens += amount
		return true
	elseif kind == "Vehicle" then
		local vehicles = service("VehicleService")
		local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
		if type(def.Kind) ~= "string" or not Gameplay.Vehicles[def.Kind] then
			return false, "Unknown"
		end
		if not vehicles then
			return false, "Failed"
		end
		if not vehicles.grant(player, def.Kind) and def.Fallback then
			return grantOne(player, data, def.Fallback, seasonId) -- (ya lo tenía)
		end
		return true
	elseif kind == "VehicleSkin" then
		local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
		if type(def.Kind) ~= "string" or not Gameplay.Vehicles[def.Kind] or typeof(def.Color) ~= "Color3" then
			return false, "Unknown"
		end
		if def.GrantsBase then
			local vehicles = service("VehicleService")
			if not vehicles then
				return false, "Failed"
			end
			vehicles.grant(player, def.Kind) -- (false = ya lo tenía: da igual)
		end
		own(data, def, seasonId)
		autoEquip(player, data, def)
		return true
	elseif kind == "Boat" then
		own(data, def, seasonId)
		return BoatAdapter.grant(player, def), "Failed"
	elseif kind == "Wearable" then
		local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
		local prize = type(def.Kind) == "string" and Gameplay.Prizes[def.Kind]
		if not prize or prize.Kind ~= "Wear" then
			return false, "Unknown"
		end
		local arcade = service("ArcadeService")
		if not arcade or not arcade.grantPrize then
			return false, "Failed"
		end
		if not arcade.grantPrize(player, def.Kind) then
			-- Ya lo tenía: su compensación (si no tiene, se da por entregado)
			if def.Fallback then
				return grantOne(player, data, def.Fallback, seasonId)
			end
		end
		return true
	elseif kind == "Outfit" then
		if type(def.Colors) ~= "table" then
			return false, "Unknown"
		end
		own(data, def, seasonId)
		autoEquip(player, data, def)
		return true
	elseif kind == "Emote" or kind == "Story" then
		own(data, def, seasonId)
		return true
	elseif kind == "Title" or kind == "Nameplate" or kind == "PhoneTheme" or kind == "HudSkin" or kind == "HomeTheme" or kind == "Decor" then
		own(data, def, seasonId)
		autoEquip(player, data, def)
		return true
	elseif kind == "Perk" then
		if type(def.Perk) ~= "string" then
			return false, "Unknown"
		end
		own(data, def, seasonId)
		cosmeticsOf(data).Perks[def.Perk] = true
		return true
	elseif kind == "Bundle" then
		if type(def.Items) ~= "table" or #def.Items == 0 then
			return false, "Unknown"
		end
		for _, item in def.Items do
			local itemDef = Catalog.get(item.Id) or item
			local ok, why = grantOne(player, data, itemDef, seasonId)
			if not ok and why == "Failed" then
				return false, "Failed" -- (lo de dentro que sea colección no se duplica al reintentar)
			end
		end
		own(data, def, seasonId)
		return true
	end
	return false, "Unknown"
end

-- Entrega una recompensa (y, si ya no existe o no se puede dar nunca, su compensación).
-- Devuelve (entregada, motivo, ¿fue compensación?)
function BattlePassRewardService.grant(player: Player, def: { [string]: any }?, seasonId: string?): (boolean, string?, boolean?)
	local data = DataService.get(player)
	if not data then
		return false, "NoData"
	end
	if type(def) ~= "table" then
		def = nil
	end
	local ok, why = false, "Unknown"
	if def then
		local success, a, b = pcall(grantOne, player, data, def, seasonId)
		if success then
			ok, why = a, b
		else
			warn("[BattlePass] Error entregando " .. tostring(def.Id) .. ": " .. tostring(a))
			ok, why = false, "Failed"
		end
	end
	local compensated = false
	if not ok and why == "Unknown" then
		-- La recompensa ya no existe (o está rota): compensación para que nadie pierda nada
		warn(("[BattlePass] Recompensa %s no disponible: se da la compensación"):format(if def then tostring(def.Id) else "?"))
		local fallback = require(ReplicatedStorage.Shared.BattlePass.Config).MissingRewardFallback
		ok = grantOne(player, data, fallback, seasonId)
		why = if ok then nil else "Failed"
		compensated = ok
	end
	BattlePassRewardService.sync(player)
	return ok, if ok then nil else why, compensated
end

---------------------------------------------------------------------
-- Equipar
---------------------------------------------------------------------

-- Equipa (o quita, con id = nil) algo de tu colección. slot: Title, Nameplate, PhoneTheme, HudSkin,
-- HomeTheme, Outfit, VehicleSkin (con kind), Decor (id: pone o quita ese objeto).
function BattlePassRewardService.equip(player: Player, slot: any, id: any, kind: any): (boolean, string?)
	local data = DataService.get(player)
	if not data or type(slot) ~= "string" then
		return false, "BadRequest"
	end
	local c = cosmeticsOf(data)
	if id ~= nil and (type(id) ~= "string" or #id > 64) then
		return false, "BadRequest"
	end
	local def = if id then Catalog.get(id) else nil
	if id and (not def or not c.Owned[id]) then
		return false, "NotOwned"
	end
	if slot == "Decor" then
		if not def or def.Type ~= "Decor" then
			return false, "BadRequest"
		end
		local at = table.find(c.Equipped.Decor, id)
		if at then
			table.remove(c.Equipped.Decor, at)
		elseif #c.Equipped.Decor >= MAX_DECOR then
			return false, "DecorFull"
		else
			table.insert(c.Equipped.Decor, id)
		end
	elseif slot == "VehicleSkin" then
		local vehicleKind = if def then def.Kind else kind
		if type(vehicleKind) ~= "string" or (def and def.Type ~= "VehicleSkin") then
			return false, "BadRequest"
		end
		c.Equipped.VehicleSkin[vehicleKind] = id
	elseif EQUIP_SLOT[slot] then
		if def and def.Type ~= slot then
			return false, "BadRequest"
		end
		c.Equipped[slot] = id
		if slot == "Outfit" then
			applyOutfit(player)
		end
	else
		return false, "BadRequest"
	end
	BattlePassRewardService.sync(player)
	return true
end

---------------------------------------------------------------------
-- Ganchos en los sistemas de siempre
---------------------------------------------------------------------

-- Color del vehículo al sacarlo (VehicleService.mount): el acabado equipado para ese tipo
function BattlePassRewardService.paintFor(player: Player, kind: string): Color3?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local c = cosmeticsOf(data)
	local id = c.Equipped.VehicleSkin[kind]
	local def = id and c.Owned[id] and Catalog.get(id)
	return if def and typeof(def.Color) == "Color3" then def.Color else nil
end

-- Colores del conjunto equipado (AvatarService: se mezclan con el aspecto de Valmar)
function BattlePassRewardService.outfitFor(player: Player): { [string]: Color3 }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local c = cosmeticsOf(data)
	local id = c.Equipped.Outfit
	local def = id and c.Owned[id] and Catalog.get(id)
	return if def and type(def.Colors) == "table" then def.Colors else nil
end

local function material(name: any): Enum.Material?
	if type(name) ~= "string" then
		return nil
	end
	local ok, value = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok then value else nil
end

-- Monta un objeto de decoración sencillo (piezas básicas: no hace falta subir modelos)
function BattlePassRewardService.buildDecor(def: { [string]: any }, cf: CFrame, parent: Instance)
	local part = Instance.new("Part")
	part.Name = "BPDecor_" .. def.Id
	part.Anchored = true
	part.CanCollide = false
	part.Size = if typeof(def.Size) == "Vector3" then def.Size else Vector3.new(1, 1, 1)
	part.Color = if typeof(def.Color) == "Color3" then def.Color else Color3.new(1, 1, 1)
	part.Material = material(def.Material) or Enum.Material.SmoothPlastic
	local height = part.Size.Y
	local turn = CFrame.new()
	if def.Shape == "Ball" then
		part.Shape = Enum.PartType.Ball
	elseif def.Shape == "Plant" or def.Shape == "Trophy" or def.Shape == "Lighthouse" then
		-- (cilindro de pie: en Roblox el eje del cilindro es X)
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(height, part.Size.X, part.Size.Z)
		turn = CFrame.Angles(0, 0, math.pi / 2)
	end
	part.CFrame = cf * CFrame.new(0, (if def.Shape == "Rug" then 0.05 else height / 2), 0) * turn
	if def.Light then
		local light = Instance.new("PointLight")
		light.Range = 12
		light.Brightness = 0.8
		light.Color = part.Color
		light.Parent = part
	end
	part:SetAttribute("BattlePassDecor", def.Id)
	part.Parent = parent
end

-- Tema y decoración en la vivienda de un jugador (PropertyService.DecorateOwned, al montar la sala).
-- Solo si el dueño está conectado (sus datos están cargados).
function BattlePassRewardService.decorateHome(ownerUserId: number, inst: { [string]: any })
	local owner = Players:GetPlayerByUserId(ownerUserId)
	local data = owner and DataService.get(owner)
	local room = inst and inst.Room
	if not data or not room or not room.Model then
		return
	end
	local c = cosmeticsOf(data)
	local theme = c.Equipped.HomeTheme and c.Owned[c.Equipped.HomeTheme] and Catalog.get(c.Equipped.HomeTheme)
	if theme and theme.Type == "HomeTheme" then
		for _, part in room.Model:GetChildren() do
			if part:IsA("BasePart") then
				if part.Name == "Floor" and typeof(theme.Floor) == "Color3" then
					part.Color = theme.Floor
					part.Material = material(theme.FloorMaterial) or part.Material
				elseif string.sub(part.Name, 1, 4) == "Wall" and typeof(theme.Wall) == "Color3" then
					part.Color = theme.Wall
					part.Material = material(theme.WallMaterial) or part.Material
				end
			end
		end
	end
	-- Decoración: en fila junto a la pared del fondo
	if type(room.at) == "function" and type(room.W) == "number" and type(room.D) == "number" then
		local count = 0
		for _, id in c.Equipped.Decor do
			local def = c.Owned[id] and Catalog.get(id)
			if def and def.Type == "Decor" and count < MAX_DECOR then
				count += 1
				local x = -room.W / 2 + 2.5 + (count - 1) * math.max(3, (room.W - 5) / MAX_DECOR)
				pcall(BattlePassRewardService.buildDecor, def, room.at(x, 0, room.D / 2 - 1.8), room.Model)
			end
		end
	end
end

function BattlePassRewardService.init()
	-- Ganchos (si el servicio existe): pintar vehículos, ropa y vivienda con lo equipado
	local vehicles = service("VehicleService")
	if vehicles then
		vehicles.PaintFor = BattlePassRewardService.paintFor
	end
	local avatar = service("AvatarService")
	if avatar then
		avatar.OutfitFor = BattlePassRewardService.outfitFor
	end
	local property = service("PropertyService")
	if property then
		property.DecorateOwned = BattlePassRewardService.decorateHome
	end
	DataService.onLoaded(function(player)
		BattlePassRewardService.sync(player)
	end)
end

return BattlePassRewardService
