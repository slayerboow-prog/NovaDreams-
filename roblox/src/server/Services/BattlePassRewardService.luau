-- BattlePassRewardService: entrega las recompensas del pase con los sistemas de SIEMPRE del juego.
--   Money        -> DataService.addMoney (no cuenta como sueldo: ni Hacienda ni «ganado trabajando»)
--   CharacterXp  -> ProgressionService.addXp
--   Tickets      -> ArcadeService.addTickets
--   Vehicle      -> VehicleService.grant (el vehículo normal, mismas prestaciones)
--   VehicleSkin  -> acabado exclusivo (color/material) de un vehículo normal: VehicleService lo pinta al
--                   sacarlo (VehicleService.PaintFor). Mismas prestaciones. GrantsBase: da también el vehículo.
--                   Con Model (los 13 premium de shared/PremiumVehicles), además sale con su propio
--                   diseño (VehicleService.ModelFor): sigue siendo un coche / una moto del juego.
--   Wearable     -> ArcadeService.grantPrize (gafas, gorra)
--   Outfit       -> colores del aspecto de Valmar (AvatarService.OutfitFor)
--   HomeTheme / Decor -> tu vivienda de siempre (PropertyService.DecorateOwned): colores de suelo y
--                   paredes y hasta MAX_DECOR objetos. No crea casas nuevas ni toca el registro de dueños.
--   Boat         -> BoatService.grant (barcos propios: se sacan en el puerto deportivo). Se guarda
--                   también en la colección (así sigue siendo tuyo después de «Vida nueva»).
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

local BPConfig = require(ReplicatedStorage.Shared.BattlePass.Config)
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

-- Lo equipado en ese hueco, solo si es tuyo, sigue en el catálogo y es de ese tipo (si no, nada)
local function equippedDef(c: { [string]: any }, slot: string): (string?, { [string]: any }?)
	local id = c.Equipped[slot]
	local def = Catalog.get(id)
	if def and def.Type == slot and c.Owned[id] ~= nil then
		return id, def
	end
	return nil, nil
end

-- Solo el servidor pone estos atributos (y solo con lo que tienes Y llevas equipado). Los pinta el
-- cliente: título y placa encima de la cabeza (Controllers/NameTags, los ven todos), tema del
-- teléfono y del HUD (UI/BattlePassCosmetics) y gestos del pase (Controllers/Actions).
function BattlePassRewardService.sync(player: Player)
	if not BattlePassSeasonService.activeFor(player) then
		return -- (pase apagado: ni atributos ni cosméticos a la vista; salvo a los testers)
	end
	local data = DataService.get(player)
	if not data then
		return
	end
	local c = cosmeticsOf(data)
	local _, title = equippedDef(c, "Title")
	player:SetAttribute("BP_Title", if title then title.Text or title.Name else nil)
	player:SetAttribute("BP_TitleColor", if title and typeof(title.Color) == "Color3" then title.Color else nil)
	player:SetAttribute("BP_Nameplate", (equippedDef(c, "Nameplate")))
	player:SetAttribute("BP_PhoneTheme", (equippedDef(c, "PhoneTheme")))
	player:SetAttribute("BP_HudSkin", (equippedDef(c, "HudSkin")))
	player:SetAttribute("BP_Outfit", (equippedDef(c, "Outfit")))
	player:SetAttribute("BP_HomeTheme", (equippedDef(c, "HomeTheme")))
	local emotes = {}
	for id, info in c.Owned do
		if type(info) == "table" and info.Type == "Emote" and Catalog.get(id) then
			table.insert(emotes, id)
		end
	end
	table.sort(emotes)
	player:SetAttribute("BP_Emotes", table.concat(emotes, ","))
	player:SetAttribute("BP_Tokens", c.Tokens)
	-- Vehículos premium tuyos (con su propio modelo) y cuál sale al sacar cada tipo: el menú
	-- «Mis vehículos» deja elegir entre ellos (VehicleService "Spawn" con el id)
	local models = {}
	for id, info in c.Owned do
		local def = type(info) == "table" and Catalog.get(id)
		if def and def.Type == "VehicleSkin" and type(def.Model) == "string" then
			table.insert(models, id)
		end
	end
	table.sort(models)
	player:SetAttribute("BP_VehicleModels", if #models > 0 then table.concat(models, ",") else nil)
	for _, kind in { "Coche", "Moto" } do
		local id = c.Equipped.VehicleSkin[kind]
		local def = id and c.Owned[id] and Catalog.get(id)
		player:SetAttribute("BP_VehicleModel_" .. kind, if def and type(def.Model) == "string" then id else nil)
	end
end

---------------------------------------------------------------------
-- Adaptadores: el pase pide, cada sistema de siempre entrega
---------------------------------------------------------------------

-- Barcos: BoatService.grant(player, kind, def) -> boolean (def.Boat dice qué barco es). El barco
-- aparece en el menú del puerto deportivo. (Si BoatService no cargara, queda en la colección y
-- BoatService lo recupera de data.Cosmetics al volver.)
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
		-- Lo primero se pone solo; y un vehículo premium nuevo (con su propio modelo) sustituye a un
		-- acabado que es solo color (el que paga un deportivo lo quiere ver al sacar el coche)
		local current = def.Kind and c.Equipped.VehicleSkin[def.Kind]
		local currentDef = current and Catalog.get(current)
		if def.Kind and (not current or (type(def.Model) == "string" and not (currentDef and type(currentDef.Model) == "string"))) then
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
		own(data, def, seasonId) -- (así vuelve después de «Vida nueva»: VehicleService lo recupera)
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
			return true
		end
		own(data, def, seasonId) -- (así vuelve después de «Vida nueva»: ArcadeService lo recupera)
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
			if id ~= nil and data.OwnAvatar == true then
				-- (quien se pone un conjunto lo quiere ver: deja el avatar propio de Roblox)
				data.OwnAvatar = false
				player:SetAttribute("OwnAvatar", false)
			end
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
	if not data or not BattlePassSeasonService.activeFor(player) then
		return nil
	end
	local c = cosmeticsOf(data)
	local id = c.Equipped.VehicleSkin[kind]
	local def = id and c.Owned[id] and Catalog.get(id)
	return if def and typeof(def.Color) == "Color3" then def.Color else nil
end

-- Modelo del vehículo al sacarlo (VehicleService.mount): el premium equipado para ese tipo (id de
-- shared/PremiumVehicles) y su color de detalle (Trim). nil = el modelo de siempre.
function BattlePassRewardService.modelFor(player: Player, kind: string): (string?, Color3?)
	local data = DataService.get(player)
	if not data or not BattlePassSeasonService.activeFor(player) then
		return nil, nil
	end
	local c = cosmeticsOf(data)
	local id = c.Equipped.VehicleSkin[kind]
	local def = id and c.Owned[id] and Catalog.get(id)
	if def and def.Kind == kind and type(def.Model) == "string" then
		return def.Model, if typeof(def.Trim) == "Color3" then def.Trim else nil
	end
	return nil, nil
end

-- Elige qué vehículo sale al sacar ese tipo («Mis vehículos»): id = un vehículo premium tuyo de ese
-- tipo, o "" / nil para el de siempre (vuelve el acabado de color que tengas de ese tipo, si hay).
function BattlePassRewardService.chooseVehicle(player: Player, kind: any, id: any): boolean
	local data = DataService.get(player)
	if not data or type(kind) ~= "string" or not BattlePassSeasonService.activeFor(player) then
		return false
	end
	local c = cosmeticsOf(data)
	if type(id) == "string" and id ~= "" then
		local def = Catalog.get(id)
		if not def or def.Type ~= "VehicleSkin" or def.Kind ~= kind or type(def.Model) ~= "string" or not c.Owned[id] then
			return false
		end
		c.Equipped.VehicleSkin[kind] = id
	else
		local plain = nil
		for owned in c.Owned do
			local def = Catalog.get(owned)
			if def and def.Type == "VehicleSkin" and def.Kind == kind and type(def.Model) ~= "string" and (not plain or owned < plain) then
				plain = owned
			end
		end
		c.Equipped.VehicleSkin[kind] = plain
	end
	BattlePassRewardService.sync(player)
	return true
end

-- Conjunto equipado (AvatarService): su definición del catálogo. Los 30 conjuntos de la hoja traen
-- Outfit (clave de shared/Outfits: los viste OutfitBuilder); todos traen Colors (aspecto de Valmar).
function BattlePassRewardService.outfitFor(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data or not BattlePassSeasonService.activeFor(player) then
		return nil
	end
	local c = cosmeticsOf(data)
	local id = c.Equipped.Outfit
	local def = id and c.Owned[id] and Catalog.get(id)
	return if def and def.Type == "Outfit" and type(def.Colors) == "table" then def else nil
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

-- Decoración del pase hecha con piezas básicas, pero con forma de verdad: maceta con hojas, estantería
-- con libros, trofeo con asas, farol con cristales y luz… Los materiales (madera, tela, metal, cristal,
-- barro, hierba) son los de Roblox, así que en la ciudad salen con las texturas realistas de
-- MaterialService (World/UserMaterials). Todo anclado y sin chocar; Size de la recompensa = su caja.
local V3, CFn, ANG = Vector3.new, CFrame.new, CFrame.Angles
local UPRIGHT = ANG(0, 0, math.pi / 2) -- (cilindro de pie: en Roblox el eje del cilindro es X)

local function shade(c: Color3, f: number): Color3
	return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end

local DECOR_SHAPES: { [string]: (piece: (string, Vector3, CFrame, Color3, Enum.Material, Enum.PartType?) -> BasePart, s: Vector3, color: Color3, def: { [string]: any }) -> () } = {
	-- Maceta de barro con tierra y un ramillete de hojas
	Plant = function(piece, s, color)
		local potH, potW = s.Y * 0.32, s.X * 0.75
		local terracotta = Color3.fromRGB(176, 98, 66)
		piece("Maceta", V3(potH, potW * 0.85, potW * 0.85), CFn(0, potH / 2, 0) * UPRIGHT, terracotta, Enum.Material.Concrete, Enum.PartType.Cylinder)
		piece("Borde", V3(potH * 0.18, potW, potW), CFn(0, potH - potH * 0.09, 0) * UPRIGHT, shade(terracotta, 0.9), Enum.Material.Concrete, Enum.PartType.Cylinder)
		piece("Tierra", V3(0.06, potW * 0.8, potW * 0.8), CFn(0, potH, 0) * UPRIGHT, Color3.fromRGB(70, 50, 34), Enum.Material.Ground, Enum.PartType.Cylinder)
		local top = s.Y - potH
		for i = 1, 3 do
			local a = (i - 1) * (2 * math.pi / 3)
			piece("Tallo", V3(0.08, top * 0.7, 0.08), CFn(math.cos(a) * 0.08, potH + top * 0.35, math.sin(a) * 0.08) * ANG(math.cos(a) * 0.12, 0, math.sin(a) * 0.12), Color3.fromRGB(80, 110, 50), Enum.Material.Wood)
		end
		for i = 1, 9 do
			local a = i * 2.4
			local r = s.X * (0.18 + 0.12 * (i % 3))
			local h = potH + top * (0.35 + 0.07 * (i % 5))
			local leaf = shade(color, 0.85 + 0.1 * (i % 3))
			-- (hoja = disco fino inclinado hacia fuera; las bolas de Roblox no se pueden aplastar)
			piece("Hoja", V3(0.05, s.X * 0.42, s.X * 0.42), CFn(math.cos(a) * r, h, math.sin(a) * r) * ANG(0, -a, 0) * ANG(0, 0, math.pi / 2 - 0.55), leaf, Enum.Material.LeafyGrass, Enum.PartType.Cylinder)
		end
		local crown = math.min(s.X * 0.6, top * 0.5)
		piece("Copa", V3(crown, crown, crown), CFn(0, potH + top * 0.7, 0), shade(color, 0.95), Enum.Material.LeafyGrass, Enum.PartType.Ball)
	end,

	-- Tres cojines de tela con ribete (dos tumbados y uno apoyado)
	Cushion = function(piece, s, color)
		local w, h = s.X * 0.62, s.Y * 0.45
		local trim = shade(color, 1.25)
		local function cushion(cf: CFrame, c: Color3)
			piece("Cojin", V3(w, h, w), cf, c, Enum.Material.Fabric)
			piece("Ribete", V3(w + 0.04, 0.05, w + 0.04), cf, trim, Enum.Material.Fabric)
			piece("Boton", V3(0.08, 0.12, 0.12), cf * CFn(0, h / 2, 0) * UPRIGHT, shade(c, 0.7), Enum.Material.Fabric, Enum.PartType.Cylinder)
		end
		cushion(CFn(-s.X * 0.18, h / 2, -s.Z * 0.12) * ANG(0, 0.25, 0), color)
		cushion(CFn(s.X * 0.2, h / 2, s.Z * 0.15) * ANG(0, -0.4, 0), shade(color, 0.85))
		cushion(CFn(0, h * 1.35, 0) * ANG(0.5, 0.1, 0), Color3.fromRGB(235, 228, 210))
	end,

	-- Estantería de madera con baldas, libros de colores y una cajita
	Shelf = function(piece, s, color, def)
		local t = 0.14
		local wood = color
		piece("Lado", V3(t, s.Y, s.Z), CFn(-s.X / 2 + t / 2, s.Y / 2, 0), wood, Enum.Material.Wood)
		piece("Lado", V3(t, s.Y, s.Z), CFn(s.X / 2 - t / 2, s.Y / 2, 0), wood, Enum.Material.Wood)
		piece("Fondo", V3(s.X, s.Y, 0.06), CFn(0, s.Y / 2, -s.Z / 2 + 0.03), shade(wood, 0.8), Enum.Material.WoodPlanks)
		local shelves = 4
		local inner = s.X - 2 * t
		local bookColors = { Color3.fromRGB(150, 40, 40), Color3.fromRGB(40, 70, 140), Color3.fromRGB(40, 110, 70), Color3.fromRGB(210, 170, 60), Color3.fromRGB(90, 60, 120), Color3.fromRGB(230, 225, 210) }
		local seed = #tostring(def.Id or "")
		for i = 0, shelves do
			local y = t / 2 + i * (s.Y - t) / shelves
			piece("Balda", V3(inner, t, s.Z - 0.06), CFn(0, y, 0.03), wood, Enum.Material.Wood)
			if i < shelves then
				local gap = (s.Y - t) / shelves - t
				local x = -inner / 2 + 0.08
				local n = 0
				while x < inner / 2 - 0.25 and n < 14 do
					n += 1
					local k = (seed + i * 7 + n * 3) % #bookColors + 1
					local bw = 0.12 + ((seed + n) % 3) * 0.05
					local bh = gap * (0.62 + ((n + i) % 4) * 0.08)
					if (n + i) % 6 == 5 then
						-- (un hueco con una cajita en vez de libros)
						piece("Caja", V3(0.45, gap * 0.35, s.Z * 0.6), CFn(x + 0.25, y + t / 2 + gap * 0.175, 0.05), Color3.fromRGB(200, 185, 150), Enum.Material.Cardboard)
						x += 0.6
					else
						piece("Libro", V3(bw, bh, s.Z * 0.72), CFn(x + bw / 2, y + t / 2 + bh / 2, 0.05) * ANG(0, 0, if n % 7 == 3 then 0.12 else 0), bookColors[k], Enum.Material.Fabric)
						x += bw + 0.02
					end
				end
			end
		end
	end,

	-- Alfombra de toalla de rayas con flecos en los extremos
	Rug = function(piece, s, color)
		local stripes = 7
		local w = s.X / stripes
		for i = 1, stripes do
			local c = if i % 2 == 1 then color else Color3.fromRGB(245, 242, 232)
			piece("Raya", V3(w, 0.05, s.Z), CFn(-s.X / 2 + w * (i - 0.5), 0.025, 0), c, Enum.Material.Fabric)
		end
		for side = -1, 1, 2 do
			for i = 0, 10 do
				local z = -s.Z / 2 + 0.1 + i * (s.Z - 0.2) / 10
				piece("Fleco", V3(0.3, 0.03, 0.05), CFn(side * (s.X / 2 + 0.15), 0.015, z), Color3.fromRGB(240, 236, 225), Enum.Material.Fabric)
			end
		end
	end,

	-- Farol de hierro con cristales y luz cálida
	Lamp = function(piece, s, color)
		local iron = Color3.fromRGB(40, 40, 44)
		piece("Base", V3(0.25, s.X * 0.8, s.X * 0.8), CFn(0, 0.125, 0) * UPRIGHT, iron, Enum.Material.Metal, Enum.PartType.Cylinder)
		local postH = s.Y * 0.62
		piece("Poste", V3(postH, 0.16, 0.16), CFn(0, postH / 2, 0) * UPRIGHT, iron, Enum.Material.Metal, Enum.PartType.Cylinder)
		local boxW, boxH = s.X * 0.6, s.Y * 0.26
		local y0 = postH
		piece("Suelo", V3(boxW + 0.1, 0.08, boxW + 0.1), CFn(0, y0, 0), iron, Enum.Material.Metal)
		for _, c in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
			piece("Barrote", V3(0.07, boxH, 0.07), CFn(c[1] * boxW / 2, y0 + boxH / 2, c[2] * boxW / 2), iron, Enum.Material.Metal)
		end
		local glass = piece("Cristal", V3(boxW - 0.04, boxH, boxW - 0.04), CFn(0, y0 + boxH / 2, 0), Color3.fromRGB(255, 245, 220), Enum.Material.Glass)
		glass.Transparency = 0.45
		local bulb = piece("Bombilla", V3(boxW * 0.35, boxW * 0.35, boxW * 0.35), CFn(0, y0 + boxH / 2, 0), color, Enum.Material.Neon, Enum.PartType.Ball)
		local light = Instance.new("PointLight")
		light.Range, light.Brightness, light.Color, light.Shadows = 14, 1.1, color, true
		light.Parent = bulb
		piece("Tejado", V3(boxW * 0.9, 0.12, boxW * 0.9), CFn(0, y0 + boxH + 0.06, 0), iron, Enum.Material.Metal)
		piece("Tejado", V3(boxW * 0.62, 0.14, boxW * 0.62), CFn(0, y0 + boxH + 0.18, 0) * ANG(0, math.pi / 4, 0), iron, Enum.Material.Metal)
		piece("Remate", V3(0.18, 0.18, 0.18), CFn(0, y0 + boxH + 0.34, 0), iron, Enum.Material.Metal, Enum.PartType.Ball)
	end,

	-- Copa de metal con asas sobre un pedestal de madera y su placa
	Trophy = function(piece, s, color)
		local wood = Color3.fromRGB(70, 42, 26)
		local baseH = s.Y * 0.18
		piece("Pedestal", V3(s.X * 0.8, baseH, s.Z * 0.8), CFn(0, baseH / 2, 0), wood, Enum.Material.Wood)
		piece("Pedestal", V3(s.X * 0.62, baseH * 0.5, s.Z * 0.62), CFn(0, baseH * 1.25, 0), shade(wood, 1.2), Enum.Material.Wood)
		piece("Placa", V3(s.X * 0.4, baseH * 0.45, 0.03), CFn(0, baseH / 2, -s.Z * 0.4 - 0.015), Color3.fromRGB(212, 175, 90), Enum.Material.Metal)
		local y = baseH * 1.5
		local stemH = s.Y * 0.22
		piece("Pie", V3(0.08, s.X * 0.35, s.X * 0.35), CFn(0, y + 0.04, 0) * UPRIGHT, color, Enum.Material.Metal, Enum.PartType.Cylinder)
		piece("Tallo", V3(stemH, 0.14, 0.14), CFn(0, y + stemH / 2, 0) * UPRIGHT, color, Enum.Material.Metal, Enum.PartType.Cylinder)
		piece("Nudo", V3(0.24, 0.24, 0.24), CFn(0, y + stemH * 0.55, 0), color, Enum.Material.Metal, Enum.PartType.Ball)
		local cupH = s.Y - y - stemH
		local cup = math.min(s.X * 0.62, cupH * 0.9)
		piece("Copa", V3(cup, cup, cup), CFn(0, y + stemH + cupH * 0.4, 0), color, Enum.Material.Metal, Enum.PartType.Ball)
		piece("Boca", V3(cupH * 0.35, s.X * 0.62, s.X * 0.62), CFn(0, y + stemH + cupH * 0.72, 0) * UPRIGHT, color, Enum.Material.Metal, Enum.PartType.Cylinder)
		for side = -1, 1, 2 do
			for k = 0, 4 do
				local a = -0.9 + k * 0.45
				local r = s.X * 0.22
				piece("Asa", V3(0.09, 0.09, 0.09), CFn(side * (s.X * 0.33 + math.cos(a) * r), y + stemH + cupH * 0.45 + math.sin(a) * r, 0), color, Enum.Material.Metal, Enum.PartType.Ball)
			end
		end
	end,

	-- Placa de metal grabada sobre una tabla de madera, con tornillos
	Poster = function(piece, s, color)
		local wood = Color3.fromRGB(96, 60, 36)
		piece("Tabla", V3(s.X, s.Y, s.Z * 0.6), CFn(0, s.Y / 2 + 0.6, 0), wood, Enum.Material.Wood)
		piece("Placa", V3(s.X * 0.8, s.Y * 0.72, 0.04), CFn(0, s.Y / 2 + 0.6, -s.Z * 0.3 - 0.02), color, Enum.Material.Metal)
		for i = 1, 3 do
			piece("Grabado", V3(s.X * (0.6 - i * 0.08), 0.05, 0.01), CFn(0, s.Y / 2 + 0.6 + s.Y * (0.18 - i * 0.12), -s.Z * 0.3 - 0.045), shade(color, 0.6), Enum.Material.Metal)
		end
		for _, c in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
			piece("Tornillo", V3(0.03, 0.08, 0.08), CFn(c[1] * s.X * 0.36, s.Y / 2 + 0.6 + c[2] * s.Y * 0.3, -s.Z * 0.3 - 0.05) * ANG(0, math.pi / 2, 0), Color3.fromRGB(150, 150, 155), Enum.Material.Metal, Enum.PartType.Cylinder)
		end
		piece("Atril", V3(0.1, 0.62, 0.1), CFn(0, 0.31, s.Z * 0.1), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
		piece("Atril", V3(s.X * 0.5, 0.06, s.Z * 2), CFn(0, 0.03, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
	end,

	-- Faro en miniatura: roca, torre de rayas rojas y blancas, balcón y linterna encendida
	Lighthouse = function(piece, s, color)
		local rock = Color3.fromRGB(110, 105, 100)
		piece("Roca", V3(s.Y * 0.1, s.X * 1.1, s.X * 1.1), CFn(0, s.Y * 0.05, 0) * UPRIGHT, rock, Enum.Material.Slate, Enum.PartType.Cylinder)
		piece("Roca", V3(s.X * 0.45, s.X * 0.45, s.X * 0.45), CFn(s.X * 0.35, s.Y * 0.06, s.X * 0.2), shade(rock, 0.85), Enum.Material.Slate, Enum.PartType.Ball)
		local towerH = s.Y * 0.62
		local y0 = s.Y * 0.08
		local bands = 5
		for i = 0, bands - 1 do
			local f = 1 - i * 0.07
			local c = if i % 2 == 0 then Color3.fromRGB(245, 245, 240) else Color3.fromRGB(190, 40, 40)
			piece("Torre", V3(towerH / bands, s.X * 0.62 * f, s.X * 0.62 * f), CFn(0, y0 + towerH / bands * (i + 0.5), 0) * UPRIGHT, c, Enum.Material.Concrete, Enum.PartType.Cylinder)
		end
		local y = y0 + towerH
		local dark = Color3.fromRGB(35, 38, 42)
		piece("Balcon", V3(0.08, s.X * 0.62, s.X * 0.62), CFn(0, y + 0.04, 0) * UPRIGHT, dark, Enum.Material.Metal, Enum.PartType.Cylinder)
		for k = 0, 7 do
			local a = k * math.pi / 4
			piece("Barandilla", V3(0.04, 0.22, 0.04), CFn(math.cos(a) * s.X * 0.29, y + 0.15, math.sin(a) * s.X * 0.29), dark, Enum.Material.Metal)
		end
		local lanternH = s.Y * 0.14
		local glass = piece("Linterna", V3(lanternH, s.X * 0.36, s.X * 0.36), CFn(0, y + 0.08 + lanternH / 2, 0) * UPRIGHT, Color3.fromRGB(255, 245, 210), Enum.Material.Glass, Enum.PartType.Cylinder)
		glass.Transparency = 0.35
		local bulb = piece("Luz", V3(lanternH * 0.6, lanternH * 0.6, lanternH * 0.6), CFn(0, y + 0.08 + lanternH / 2, 0), Color3.fromRGB(255, 230, 150), Enum.Material.Neon, Enum.PartType.Ball)
		local light = Instance.new("PointLight")
		light.Range, light.Brightness, light.Color, light.Shadows = 14, 1.2, Color3.fromRGB(255, 225, 160), true
		light.Parent = bulb
		local dome = s.X * 0.4
		piece("Cupula", V3(dome, dome, dome), CFn(0, y + 0.08 + lanternH, 0), Color3.fromRGB(170, 35, 35), Enum.Material.Metal, Enum.PartType.Ball)
	end,

	-- Globo terráqueo: bola azul con continentes, eje, meridiano y pie de madera
	Ball = function(piece, s, color)
		local wood = Color3.fromRGB(96, 60, 36)
		local brass = Color3.fromRGB(190, 150, 70)
		piece("Pie", V3(0.12, s.X * 0.6, s.X * 0.6), CFn(0, 0.06, 0) * UPRIGHT, wood, Enum.Material.Wood, Enum.PartType.Cylinder)
		piece("Columna", V3(s.Y * 0.2, 0.1, 0.1), CFn(0, 0.12 + s.Y * 0.1, 0) * UPRIGHT, brass, Enum.Material.Metal, Enum.PartType.Cylinder)
		local r = s.X * 0.4
		local cy = 0.12 + s.Y * 0.2 + r
		local tilt = ANG(0, 0, math.rad(23))
		local center = CFn(0, cy, 0) * tilt
		piece("Globo", V3(r * 2, r * 2, r * 2), center, color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		local land = Color3.fromRGB(90, 150, 80)
		for i = 1, 7 do
			local a, b = i * 1.7, math.sin(i * 2.3) * 0.9
			local dir = Vector3.new(math.cos(a) * math.cos(b), math.sin(b), math.sin(a) * math.cos(b))
			local pos = center * (dir * (r * 0.93))
			-- (disco pegado a la bola: el eje X del cilindro mira hacia fuera)
			local out = center.Rotation * dir
			piece("Continente", V3(0.05, r * 0.6, r * 0.6), CFrame.lookAt(pos, pos + out) * ANG(0, math.pi / 2, 0), land, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		end
		for k = 0, 10 do
			local a = -math.pi / 2 + k * math.pi / 10
			piece("Meridiano", V3(0.05, 0.12, 0.05), center * CFn(math.cos(a) * (r + 0.07), math.sin(a) * (r + 0.07), 0), brass, Enum.Material.Metal)
		end
		piece("Eje", V3(r * 2 + 0.3, 0.04, 0.04), center * UPRIGHT, brass, Enum.Material.Metal, Enum.PartType.Cylinder)
	end,
}

-- Monta una decoración del pase (un Model con sus piezas) sobre cf (= el suelo, mirando al frente)
function BattlePassRewardService.buildDecor(def: { [string]: any }, cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "BPDecor_" .. tostring(def.Id)
	local size = if typeof(def.Size) == "Vector3" then def.Size else Vector3.new(1, 1, 1)
	local color = if typeof(def.Color) == "Color3" then def.Color else Color3.new(1, 1, 1)
	local function piece(name: string, s: Vector3, local_: CFrame, c: Color3, mat: Enum.Material, shape: Enum.PartType?): BasePart
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.Size = Vector3.new(math.max(s.X, 0.05), math.max(s.Y, 0.05), math.max(s.Z, 0.05))
		part.Color = c
		part.Material = mat
		if shape then
			part.Shape = shape
		end
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CFrame = cf * local_
		part.Parent = model
		return part
	end
	local builder = DECOR_SHAPES[tostring(def.Shape)]
	local ok = builder ~= nil and pcall(builder, piece, size, color, def)
	if not ok then
		-- (forma desconocida o algo falló: una pieza sola, como antes)
		model:ClearAllChildren()
		local part = piece("Pieza", size, CFn(0, size.Y / 2, 0), color, material(def.Material) or Enum.Material.SmoothPlastic)
		if def.Light then
			local light = Instance.new("PointLight")
			light.Range, light.Brightness, light.Color = 12, 0.8, color
			light.Parent = part
		end
	end
	-- (el punto de apoyo es el suelo, derecho: así PivotTo y la caja no dependen del giro de una pieza)
	model.WorldPivot = cf
	model:SetAttribute("BattlePassDecor", def.Id)
	model.Parent = parent
	return model
end

-- Tema y decoración en la vivienda de un jugador (PropertyService.DecorateOwned, al montar la sala).
-- Solo si el dueño está conectado (sus datos están cargados).
function BattlePassRewardService.decorateHome(ownerUserId: number, inst: { [string]: any })
	if not BattlePassSeasonService.activeFor(Players:GetPlayerByUserId(ownerUserId)) then
		return -- (pase apagado: solo los testers)
	end
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

-- Ganchos (si el servicio existe): pintar vehículos, ropa y vivienda con lo equipado. Con el pase
-- apagado los pone BattlePassService.activate cuando entra un tester (y solo valen para los testers:
-- cada gancho mira activeFor).
local hooked = false
function BattlePassRewardService.installHooks()
	if hooked then
		return
	end
	hooked = true
	local vehicles = service("VehicleService")
	if vehicles then
		vehicles.PaintFor = BattlePassRewardService.paintFor
		vehicles.ModelFor = BattlePassRewardService.modelFor
		vehicles.ChooseModel = BattlePassRewardService.chooseVehicle
	end
	local avatar = service("AvatarService")
	if avatar then
		avatar.OutfitFor = BattlePassRewardService.outfitFor
	end
	local property = service("PropertyService")
	if property then
		property.DecorateOwned = BattlePassRewardService.decorateHome
	end
end

local initialized = false
function BattlePassRewardService.init()
	if require(ReplicatedStorage.Shared.BattlePass.Config).Enabled then
		BattlePassRewardService.installHooks()
	end
	if initialized then
		return
	end
	initialized = true
	-- (sync no hace nada a quien no tiene el pase: con el pase apagado, solo a los testers)
	DataService.onLoaded(function(player)
		BattlePassRewardService.sync(player)
	end)
end

return BattlePassRewardService
