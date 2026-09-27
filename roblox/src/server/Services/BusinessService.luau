-- BusinessService: negocios de los jugadores (reglas y cuentas en shared/Business).
--
--   * LOCALES EN VENTA: la planta baja de los edificios de comercio (al entrar, cartel "SE VENDE" en
--     el mostrador), las gasolineras (poste de la gasolinera) y los hoteles (recepción).
--   * Al comprarlo eliges el negocio (tienda de alimentación, frutería, panadería, restaurante,
--     cafetería, tienda de ropa; gasolinera; hotel) y abres. Es tuyo en todos los servidores.
--   * "Gestionar" (solo el dueño): caja, reputación, existencias (se ponen desde la mochila), precios,
--     pedidos al mayorista, nombre, cerrar/abrir y vender el local.
--   * "Comprar" (cualquiera): lo que hay a la venta, a los precios del dueño. El dinero va a la caja.
--   * "Cocina" (restaurantes y cafeterías): las recetas de platos de Farming (FarmService.openKitchen).
--   * Gasolineras: quien reposta en sus surtidores paga al precio del dueño (VehicleService.FuelSeller).
--     Hoteles: las reservas de habitación de los jugadores van a la caja (HotelService.RoomSold).
--   * Los vecinos (NPC) compran solos: Business.simulate cada minuto si el dueño está en este
--     servidor, y al volver a mirar el negocio (hasta 8 horas seguidas) si no está.
--
-- Guardado (DataStore "Negocios_v1"): una clave por local con su registro completo y la clave
-- "Index" con los locales que tienen dueño (tipo, nombre, dueño y si está abierto) para dibujar los
-- carteles en todos los servidores. En Studio sin API se guarda solo en este servidor.

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Business = require(ReplicatedStorage.Shared.Business)
local Items = require(ReplicatedStorage.Shared.Items)
local Format = require(ReplicatedStorage.Shared.Format)
local MapInfo = require(ReplicatedStorage.Shared.MapInfo)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Builder = require(script.Parent.Parent.World.Builder)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local InteriorService = require(script.Parent.InteriorService)
local FarmService = require(script.Parent.FarmService)
local VehicleService = require(script.Parent.VehicleService)
local HotelService = require(script.Parent.HotelService)

local BusinessService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent

BusinessService._clock = function(): number
	return os.time()
end
local function now(): number
	return BusinessService._clock()
end

type Record = Business.Record
type Entry = { Type: string?, Name: string?, Owner: number, OwnerName: string, Open: boolean }
type Premise = {
	Key: string,
	Kind: string, -- "Local" | "Gas" | "Hotel"
	Title: string,
	Building: any?, -- InteriorService.Building (locales)
	Model: Model?,
	Anchor: BasePart?, -- donde están los avisos (gasolineras y hoteles)
	Pumps: { [BasePart]: boolean },
	Door: Vector3,
	Out: Vector3,
	Sign: BasePart?,
}

local premises: { [string]: Premise } = {}
local byBuilding: { [number]: Premise } = {}
local byLobby: { [Model]: Premise } = {}
local index: { [string]: Entry } = {}
local indexAt = -math.huge
local records: { [string]: { Data: Record?, At: number } } = {}
local memory: { [string]: any } = {}
local store: DataStore? = nil
local lastRequest: { [Player]: number } = {}
local signFolder: Folder

local CACHE = 30 -- segundos que vale lo leído del DataStore
local INDEX_KEY = "Index"

---------------------------------------------------------------------
-- Guardado
---------------------------------------------------------------------
local function transformWith(fn: (any) -> (any, any)): ((any) -> any, () -> any)
	local result = nil
	local function transform(old: any): any
		local new, value = fn(old)
		result = value
		return new
	end
	return transform, function()
		return result
	end
end

-- Cambia una clave con cuidado de no pisar a otro servidor. fn(viejo) -> (nuevo o nil para no
-- guardar, resultado). Devuelve (guardado, resultado, nuevo valor).
local function update(key: string, fn: (any) -> (any, any)): (boolean, any, any)
	local transform, resultOf = transformWith(fn)
	if store then
		local ok, value = pcall(function()
			return (store :: DataStore):UpdateAsync(key, transform)
		end)
		if ok then
			return value ~= nil, resultOf(), value
		end
		warn("[Negocios] " .. tostring(value))
		if not RunService:IsStudio() then
			return false, nil, nil
		end
	end
	local new = transform(memory[key])
	if new ~= nil then
		memory[key] = new
		return true, resultOf(), new
	end
	return false, resultOf(), nil
end

local function read(key: string): any
	if store then
		local ok, value = pcall(function()
			return (store :: DataStore):GetAsync(key)
		end)
		if ok then
			return value
		end
	end
	return memory[key]
end

local function live(rec: any): Record?
	return if type(rec) == "table" and not rec.Free and type(rec.Owner) == "number" then rec else nil
end

local function cacheRecord(key: string, rec: any)
	records[key] = { Data = live(rec), At = os.clock() }
end

local function getRecord(key: string, fresh: boolean?): Record?
	local cached = records[key]
	if cached and not fresh and os.clock() - cached.At < CACHE then
		return cached.Data
	end
	local rec = live(read(key))
	cacheRecord(key, rec)
	return rec
end

-- Cambia el registro de un negocio. fn(rec) -> (guardar: boolean, resultado)
local function mutate(key: string, fn: (Record) -> (boolean, any)): (boolean, any, Record?)
	local saved, result, value = update(key, function(old)
		local rec = live(old)
		if not rec then
			return nil, nil
		end
		local keep, res = fn(rec)
		return if keep then rec else nil, res
	end)
	if saved then
		cacheRecord(key, value)
	end
	return saved, result, if saved then live(value) else getRecord(key)
end

---------------------------------------------------------------------
-- Índice (qué locales tienen dueño) y lo que se ve en la ciudad
---------------------------------------------------------------------
local applyIndex: (old: { [string]: Entry }) -> ()

local function setIndex(new: any)
	local old = index
	index = if type(new) == "table" then new else {}
	indexAt = os.clock()
	applyIndex(old)
end

local function loadIndex(fresh: boolean?)
	if not fresh and os.clock() - indexAt < 60 then
		return
	end
	setIndex(read(INDEX_KEY))
end

local function writeIndex(key: string, entry: Entry?, onlyIfFree: boolean?, onlyOwner: number?): boolean
	local saved, _, value = update(INDEX_KEY, function(old)
		local data = if type(old) == "table" then old else {}
		local current = data[key]
		if onlyIfFree and current then
			return nil, nil
		end
		if onlyOwner and (not current or current.Owner ~= onlyOwner) then
			return nil, nil
		end
		data[key] = entry
		return data, true
	end)
	if saved then
		setIndex(value)
	end
	return saved
end

local function entryOf(rec: Record): Entry
	return { Type = rec.Type, Name = rec.Name, Owner = rec.Owner, OwnerName = rec.OwnerName, Open = rec.Open }
end

local function ownedKeys(player: Player): { string }
	local list = {}
	for key, entry in index do
		if entry.Owner == player.UserId and premises[key] then
			table.insert(list, key)
		end
	end
	table.sort(list)
	return list
end

local function displayName(entry: Entry?): string
	if not entry then
		return ""
	end
	local t = entry.Type and Business.Types[entry.Type]
	if not t then
		return ("Local de %s"):format(entry.OwnerName)
	end
	return ("%s %s"):format(t.Icon, entry.Name or t.Name)
end

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function nameOf(player: Player): string
	return if player.DisplayName and player.DisplayName ~= "" then player.DisplayName else player.Name
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isAdult(player: Player): boolean
	local stage = player:GetAttribute("LifeStage")
	return not (type(stage) == "string" and Stages.isValid(stage) and not Stages.inRange(stage, Business.MinStage, nil))
end

local function priceText(good: Business.Good, price: number): string
	if Business.priceStep(good) < 1 then
		return ("$%.2f"):format(price)
	end
	return Format.money(price)
end

local function unitText(good: Business.Good, n: number): string
	return if good.Unit then ("%d %s"):format(math.floor(n), good.Unit) else tostring(math.floor(n))
end

local function button(text: string, action: string, args: { any }, style: string?, disabled: boolean?): { [string]: any }
	return { Text = text, Action = action, Args = args, Style = style, Disabled = disabled }
end

local function send(player: Player, panel: { [string]: any })
	Remote:FireClient(player, "Panel", panel)
end

local function close(player: Player, id: string)
	Remote:FireClient(player, "Close", id)
end

-- ¿Está el jugador en el sitio del negocio? (dentro del local o junto a la gasolinera/recepción)
local function atPremise(player: Player, premise: Premise): boolean
	if premise.Building then
		local key = player:GetAttribute("InteriorKey")
		if key == premise.Building.Id .. ":0" then
			return true
		end
		local root = rootOf(player)
		return root ~= nil and (root.Position - premise.Door).Magnitude < 25
	end
	local root = rootOf(player)
	local anchor = premise.Anchor
	return root ~= nil and anchor ~= nil and (root.Position - anchor.Position).Magnitude < 30
end

---------------------------------------------------------------------
-- Ventanas
---------------------------------------------------------------------
local function premisePanel(player: Player, premise: Premise): { [string]: any }
	local info = Business.Premises[premise.Kind]
	local price = Business.premisePrice(premise.Kind, premise.Key)
	local owned = #ownedKeys(player)
	local money = DataService.get(player) and (DataService.get(player) :: any).Money or 0
	local types = {}
	for _, t in Business.typesFor(premise.Kind) do
		table.insert(types, t.Icon .. " " .. t.Name)
	end
	local reason = if not isAdult(player)
		then "Hay que ser mayor de edad"
		elseif owned >= Business.MaxOwned then ("Ya tienes %d negocios"):format(owned)
		elseif money < price then "No te llega el dinero"
		else nil
	return {
		Remote = "Business",
		Id = "Premise",
		Context = premise.Key,
		Title = ("%s %s en venta"):format(info.Icon, info.Name),
		Subtitle = premise.Title,
		Rows = {
			{
				Icon = "🏷️",
				Title = ("Precio: %s"):format(Format.money(price)),
				Text = ("Es tuyo en todos los servidores. Si algún día lo vendes, te devuelven %s."):format(Format.money(Business.sellBack(price))),
				Buttons = { button(if reason then "No puedes" else "Comprar", "BuyPremise", { premise.Key }, "Gold", reason ~= nil) },
			},
			{ Header = if reason then "⚠️ " .. reason .. "." else "Después eliges qué negocio abrir:" },
			{ Icon = info.Icon, Title = "Negocios posibles", Text = table.concat(types, " · ") },
		},
		Footer = "Los vecinos compran solos aunque no estés. Tú pones los productos y los precios.",
	}
end

local function setupPanel(player: Player, key: string): { [string]: any }
	local premise = premises[key]
	local rows = {}
	for _, t in Business.typesFor(premise.Kind) do
		local cats = {}
		for _, c in t.Categories do
			table.insert(cats, Business.Categories[c].Icon .. " " .. Business.Categories[c].Name)
		end
		table.insert(rows, {
			Icon = t.Icon,
			Title = ("%s · licencia %s"):format(t.Name, Format.money(t.License)),
			Text = ("Vende: %s. Gastos: %s/h.%s"):format(table.concat(cats, ", "), Format.money(t.Upkeep), if t.Kitchen then " Con cocina para hacer platos." else ""),
			Buttons = { button("Abrir", "Open", { key, t.Id }, "Accent") },
		})
	end
	return {
		Remote = "Business",
		Id = "Setup",
		Context = key,
		Title = "🏪 ¿Qué negocio quieres abrir?",
		Subtitle = premise.Title,
		Rows = rows,
		Footer = "La licencia se paga una vez. Después llena el negocio desde tu mochila o con pedidos al mayorista.",
	}
end

local function sellableFromBag(player: Player, bizType: Business.BizType): { string }
	local list = {}
	local data = DataService.get(player)
	for id, count in if data and data.Items then data.Items else {} do
		if type(count) == "number" and count > 0 and Business.canSell(bizType, id) and Business.Goods[id].Item == id then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

local function manageTabs(): { any }
	return {
		{ Id = "Resumen", Text = "📊 Resumen" },
		{ Id = "Existencias", Text = "📦 Existencias" },
		{ Id = "Precios", Text = "🏷️ Precios" },
		{ Id = "Mayorista", Text = "🚚 Mayorista" },
		{ Id = "Ajustes", Text = "⚙️ Ajustes" },
	}
end

local function managePanel(player: Player, key: string, rec: Record, tab: string?): { [string]: any }
	tab = tab or "Resumen"
	local bizType = Business.Types[rec.Type or ""]
	local rows = {}
	if not bizType then
		return setupPanel(player, key)
	end
	if tab == "Resumen" then
		table.insert(rows, {
			Icon = "💰",
			Title = ("Caja: %s"):format(Format.money(rec.Till)),
			Text = ("Ventas totales: %s (%d productos). Gastos: %s/h mientras está abierto."):format(Format.money(rec.Sales), rec.Units, Format.money(bizType.Upkeep)),
			Buttons = { button("Recoger caja", "Collect", { key }, "Gold", rec.Till < 1) },
		})
		table.insert(rows, {
			Icon = "⭐",
			Title = ("Reputación %s (%.1f)"):format(Business.stars(rec.Rep), rec.Rep),
			Text = "Sube con precios justos, muchos productos distintos y sin estanterías vacías. Más reputación, más clientes.",
			Buttons = {},
		})
		table.insert(rows, {
			Icon = if rec.Open then "🟢" else "🔴",
			Title = if rec.Open then "Abierto" else "Cerrado",
			Text = if rec.Open then "Los clientes compran solos (también si no estás, hasta 8 horas seguidas)." else "Cerrado no vende, pero tampoco tiene gastos.",
			Buttons = { button(if rec.Open then "Cerrar" else "Abrir", "Toggle", { key }, if rec.Open then "Danger" else "Green") },
		})
		local empty = 0
		for goodId, n in rec.Stock do
			if n <= 0 and Business.Goods[goodId] then
				empty += 1
			end
		end
		if empty > 0 then
			table.insert(rows, { Header = ("⚠️ %d %s agotados: repón en Existencias o en el Mayorista."):format(empty, if empty == 1 then "producto" else "productos") })
		end
		if #rec.Log > 0 then
			table.insert(rows, { Header = "📒 Últimos movimientos" })
			for i = #rec.Log, math.max(1, #rec.Log - 5), -1 do
				local line = rec.Log[i]
				table.insert(rows, { Icon = "•", Title = line.Text, Text = ("hace %s"):format(if now() - line.T < 60 then "un momento" else ("%d min"):format((now() - line.T) // 60)), Buttons = {} })
			end
		end
	elseif tab == "Existencias" then
		local bag = sellableFromBag(player, bizType)
		table.insert(rows, { Header = if #bag > 0 then "🎒 En tu mochila (se puede vender aquí)" else "🎒 No llevas nada que se venda en este negocio." })
		for _, id in bag do
			local good = Business.Goods[id]
			local have = InventoryService.count(player, id)
			table.insert(rows, {
				Icon = good.Icon,
				Title = ("%s ×%d"):format(good.Name, have),
				Text = ("En la tienda: %d · precio %s"):format(rec.Stock[id] or 0, priceText(good, Business.priceOf(rec, id))),
				Buttons = { button("Poner 1", "Stock", { key, id, 1 }), button("Poner todo", "Stock", { key, id, have }, "Accent") },
			})
		end
		table.insert(rows, { Header = "🏪 En la tienda" })
		local ids = {}
		for id, n in rec.Stock do
			if Business.Goods[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids)
		if #ids == 0 then
			table.insert(rows, { Header = "Vacío. Trae productos del campo o pide al mayorista." })
		end
		for _, id in ids do
			local good = Business.Goods[id]
			local n = rec.Stock[id] or 0
			table.insert(rows, {
				Icon = good.Icon,
				Title = ("%s · %s"):format(good.Name, unitText(good, n)),
				Text = if n <= 0 then "⚠️ Agotado" else ("Precio %s (normal %s)"):format(priceText(good, Business.priceOf(rec, id)), priceText(good, good.Ref)),
				Buttons = if good.Item then { button("Retirar", "Unstock", { key, id }, nil, n <= 0) } else {},
			})
		end
	elseif tab == "Precios" then
		table.insert(rows, { Header = "Más barato = más clientes y mejor reputación. Más caro = más margen." })
		local ids = {}
		for id in rec.Stock do
			if Business.Goods[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids)
		for _, id in ids do
			local good = Business.Goods[id]
			local price = Business.priceOf(rec, id)
			local ratio = price / good.Ref
			table.insert(rows, {
				Icon = good.Icon,
				Title = ("%s · %s%s"):format(good.Name, priceText(good, price), if good.Unit then "/" .. good.Unit else ""),
				Text = ("Normal %s · %s"):format(priceText(good, good.Ref), if ratio < 0.85 then "barato: vuela" elseif ratio > 1.3 then "caro: se vende poco" elseif ratio > 1.1 then "algo caro" else "precio justo"),
				Buttons = {
					button("− bajar", "Price", { key, id, -1 }),
					button("+ subir", "Price", { key, id, 1 }),
					button("Normal", "Price", { key, id, 0 }, "Accent"),
				},
			})
		end
		if #ids == 0 then
			table.insert(rows, { Header = "Primero pon productos a la venta (Existencias o Mayorista)." })
		end
	elseif tab == "Mayorista" then
		local list = Business.wholesaleFor(bizType)
		table.insert(rows, { Header = if #list > 0 then "🚚 El pedido llega al momento y se paga con tu dinero." else "El mayorista no tiene nada para este negocio: lo tuyo se hace en Valmar (campo, obrador y cocina)." })
		for _, good in list do
			local cost = math.ceil((good.Cost :: number) * (good.Lot :: number))
			table.insert(rows, {
				Icon = good.Icon,
				Title = ("%s · %s por %s"):format(good.Name, unitText(good, good.Lot :: number), Format.money(cost)),
				Text = ("Se vende a %s (normal). Tienes %s."):format(priceText(good, good.Ref), unitText(good, rec.Stock[good.Id] or 0)),
				Buttons = { button("Pedir", "Order", { key, good.Id, 1 }, "Accent"), button("Pedir ×5", "Order", { key, good.Id, 5 }) },
			})
		end
	elseif tab == "Ajustes" then
		table.insert(rows, {
			Icon = "✏️",
			Title = rec.Name or bizType.Name,
			Text = "Elige otro nombre para el cartel.",
			Buttons = { button("Cambiar nombre", "Rename", { key }, "Accent") },
		})
		local hasStock = false
		for _, n in rec.Stock do
			if n > 0 then
				hasStock = true
			end
		end
		table.insert(rows, {
			Icon = bizType.Icon,
			Title = ("Tipo: %s"):format(bizType.Name),
			Text = if hasStock then "Para cambiar de negocio, vacía antes las existencias." else "Puedes abrir otro tipo de negocio aquí (se paga su licencia).",
			Buttons = { button("Cambiar negocio", "Retype", { key }, nil, hasStock) },
		})
		table.insert(rows, {
			Icon = "🏷️",
			Title = ("Vender el local · te dan %s"):format(Format.money(Business.sellBack(rec.Paid))),
			Text = "Más lo que haya en la caja. Lo que quede en la tienda se pierde (retíralo antes).",
			Buttons = { button("Vender", "SellPremise", { key }, "Danger") },
		})
	end
	return {
		Remote = "Business",
		Id = "Manage",
		Context = key,
		Title = ("%s %s"):format(bizType.Icon, rec.Name or bizType.Name),
		Subtitle = ("%s · %s · %s"):format(rec.Title, Business.stars(rec.Rep), if rec.Open then "abierto" else "cerrado"),
		Tabs = manageTabs(),
		Tab = tab,
		Rows = rows,
	}
end

local function shopPanel(player: Player, key: string, rec: Record): { [string]: any }
	local bizType = Business.Types[rec.Type or ""]
	local rows = {}
	if not rec.Open then
		table.insert(rows, { Header = "🔴 Cerrado. Vuelve más tarde." })
	else
		local ids = {}
		for id, n in rec.Stock do
			local good = Business.Goods[id]
			if good and good.Item and n > 0 then
				table.insert(ids, id)
			end
		end
		table.sort(ids)
		if #ids == 0 then
			table.insert(rows, { Header = "Ahora mismo no queda nada a la venta. 😕" })
		end
		for _, id in ids do
			local good = Business.Goods[id]
			local item = Items.get(id)
			local price = Business.priceOf(rec, id)
			table.insert(rows, {
				Icon = good.Icon,
				Title = ("%s · %s"):format(good.Name, priceText(good, price)),
				Text = ("Quedan %d.%s"):format(rec.Stock[id], if item and item.Hunger then (" Quita el hambre (+%d)."):format(item.Hunger) else ""),
				Buttons = { button("Comprar", "Buy", { key, id, 1 }, "Accent"), button("Comprar 5", "Buy", { key, id, 5 }, nil, rec.Stock[id] < 5) },
			})
		end
	end
	local _ = player
	return {
		Remote = "Business",
		Id = "Shop",
		Context = key,
		Title = ("%s %s"):format(if bizType then bizType.Icon else "🏪", rec.Name or "Tienda"),
		Subtitle = ("De %s · %s"):format(rec.OwnerName, Business.stars(rec.Rep)),
		Rows = rows,
	}
end

---------------------------------------------------------------------
-- Ventas de los vecinos (NPC)
---------------------------------------------------------------------
local function simulate(key: string): (number, number)
	local units, money = 0, 0
	mutate(key, function(rec)
		local u, m, sold = Business.simulate(rec, now())
		units, money = u, m
		if u > 0 then
			local parts = {}
			for id, n in sold do
				local good = Business.Goods[id]
				table.insert(parts, ("%s×%s"):format(good.Icon, unitText(good, n)))
			end
			table.sort(parts)
			Business.log(rec, now(), ("Vecinos: %s (+%s)"):format(table.concat(parts, " "), Format.money(m)))
		end
		return true, nil
	end)
	return units, money
end

---------------------------------------------------------------------
-- Acciones del dueño
---------------------------------------------------------------------
local function ownRecord(player: Player, key: string, fresh: boolean?): Record?
	local rec = getRecord(key, fresh)
	if not rec or rec.Owner ~= player.UserId then
		Notify:FireClient(player, "Error", "Este negocio no es tuyo.")
		return nil
	end
	return rec
end

local function buyPremise(player: Player, key: string)
	local premise = premises[key]
	if not premise or not atPremise(player, premise) then
		return
	end
	if not isAdult(player) then
		Notify:FireClient(player, "Error", "Para tener un negocio hay que ser mayor de edad.")
		return
	end
	loadIndex(true)
	if index[key] then
		Notify:FireClient(player, "Error", "¡Vaya! Este local ya tiene dueño.")
		return
	end
	if #ownedKeys(player) >= Business.MaxOwned then
		Notify:FireClient(player, "Error", ("Ya tienes %d negocios (el máximo). Vende uno antes."):format(Business.MaxOwned))
		return
	end
	local price = Business.premisePrice(premise.Kind, key)
	if not DataService.spend(player, price) then
		Notify:FireClient(player, "Error", ("Necesitas %s."):format(Format.money(price)))
		return
	end
	local rec = Business.newRecord(key, premise.Kind, premise.Title, player.UserId, nameOf(player), price, now())
	if not writeIndex(key, entryOf(rec), true) then
		DataService.addMoney(player, price)
		Notify:FireClient(player, "Error", "¡Vaya! Alguien lo acaba de comprar.")
		return
	end
	update(key, function()
		return rec, nil
	end)
	cacheRecord(key, rec)
	DataService.save(player)
	Notify:FireClient(player, "Success", ("🔑 ¡Es tuyo! Has comprado %s por %s. Ahora elige qué negocio abrir."):format(premise.Title, Format.money(price)))
	StoryEvents.emit(player, "BusinessBought", { Key = key, Price = price })
	close(player, "Premise")
	send(player, setupPanel(player, key))
end

local function openBusiness(player: Player, key: string, typeId: string)
	local premise = premises[key]
	local bizType = Business.Types[typeId]
	local rec = ownRecord(player, key, true)
	if not premise or not bizType or not rec or bizType.Premise ~= premise.Kind then
		return
	end
	for _, n in rec.Stock do
		if n > 0 and rec.Type and rec.Type ~= typeId then
			Notify:FireClient(player, "Error", "Vacía las existencias antes de cambiar de negocio.")
			return
		end
	end
	if not DataService.spend(player, bizType.License) then
		Notify:FireClient(player, "Error", ("La licencia cuesta %s."):format(Format.money(bizType.License)))
		return
	end
	local saved, _, new = mutate(key, function(r)
		if r.Owner ~= player.UserId then
			return false, nil
		end
		r.Type = bizType.Id
		r.Name = Business.nameFor(bizType, 1, nameOf(player))
		r.Open = true
		r.LastSim = now()
		r.Stock = {}
		r.Prices = {}
		r.Carry = {}
		Business.log(r, now(), ("Abierto: %s"):format(bizType.Name))
		return true, nil
	end)
	if not saved or not new then
		DataService.addMoney(player, bizType.License)
		Notify:FireClient(player, "Error", "No se ha podido abrir ahora. Prueba otra vez.")
		return
	end
	writeIndex(key, entryOf(new), false, player.UserId)
	Notify:FireClient(player, "Success", ("%s ¡Has abierto %s! Pon productos a la venta en «Existencias» o pídelos al mayorista."):format(bizType.Icon, new.Name))
	StoryEvents.emit(player, "BusinessOpened", { Key = key, Type = bizType.Id })
	close(player, "Setup")
	send(player, managePanel(player, key, new, "Existencias"))
end

local function collect(player: Player, key: string)
	if not ownRecord(player, key) then
		return
	end
	local saved, amount, new = mutate(key, function(rec)
		if rec.Owner ~= player.UserId then
			return false, 0
		end
		Business.simulate(rec, now())
		local whole = math.floor(rec.Till)
		if whole < 1 then
			return false, 0
		end
		rec.Till -= whole
		Business.log(rec, now(), ("Caja recogida: %s"):format(Format.money(whole)))
		return true, whole
	end)
	if saved and amount and amount > 0 then
		DataService.addMoney(player, amount, true)
		Notify:FireClient(player, "Money", ("+%s · caja de %s"):format(Format.money(amount), if new then new.Name or "tu negocio" else "tu negocio"))
		StoryEvents.emit(player, "JobTaskDone", { JobId = "Empresario", Pay = amount })
	else
		Notify:FireClient(player, "Info", "La caja está vacía.")
	end
end

local function toggle(player: Player, key: string)
	local _, _, new = mutate(key, function(rec)
		if rec.Owner ~= player.UserId then
			return false, nil
		end
		Business.simulate(rec, now())
		rec.Open = not rec.Open
		Business.log(rec, now(), if rec.Open then "Abierto" else "Cerrado")
		return true, nil
	end)
	if new then
		writeIndex(key, entryOf(new), false, player.UserId)
		Notify:FireClient(player, "Info", if new.Open then "🟢 Abierto al público." else "🔴 Cerrado.")
	end
end

local function stock(player: Player, key: string, id: string, count: number)
	local rec = ownRecord(player, key)
	local bizType = rec and Business.Types[rec.Type or ""]
	local good = Business.Goods[id]
	if not rec or not bizType or not good or good.Item ~= id or not Business.canSell(bizType, id) then
		return
	end
	count = math.clamp(math.floor(count), 1, InventoryService.count(player, id))
	local room = Business.stockMax(good) - (rec.Stock[id] or 0)
	count = math.min(count, room)
	if count < 1 then
		Notify:FireClient(player, "Info", if room < 1 then "No caben más en la tienda." else "No llevas de eso.")
		return
	end
	if not InventoryService.remove(player, id, count) then
		return
	end
	local saved = mutate(key, function(r)
		if r.Owner ~= player.UserId then
			return false, nil
		end
		Business.simulate(r, now())
		r.Stock[id] = (r.Stock[id] or 0) + count
		return true, nil
	end)
	if not saved then
		InventoryService.add(player, id, count)
		Notify:FireClient(player, "Error", "No se ha podido guardar. Prueba otra vez.")
		return
	end
	Notify:FireClient(player, "Success", ("📦 +%d %s a la venta"):format(count, good.Name:lower()))
end

local function unstock(player: Player, key: string, id: string)
	local good = Business.Goods[id]
	if not good or not good.Item then
		return
	end
	local want = 0
	local rec = ownRecord(player, key, true)
	if not rec then
		return
	end
	want = rec.Stock[id] or 0
	-- Lo que cabe en la mochila
	local item = Items.get(id)
	local have = InventoryService.count(player, id)
	want = math.min(want, if item then item.Stack - have else 0)
	if want < 1 or not InventoryService.canAdd(player, id, want) then
		Notify:FireClient(player, "Error", "🎒 No te cabe en la mochila.")
		return
	end
	local saved, taken = mutate(key, function(r)
		if r.Owner ~= player.UserId then
			return false, 0
		end
		Business.simulate(r, now())
		local n = math.min(want, r.Stock[id] or 0)
		if n < 1 then
			return false, 0
		end
		r.Stock[id] -= n
		return true, n
	end)
	if saved and taken and taken > 0 then
		InventoryService.add(player, id, taken)
		Notify:FireClient(player, "Info", ("🎒 Has retirado %d %s"):format(taken, good.Name:lower()))
	end
end

local function setPrice(player: Player, key: string, id: string, dir: number)
	local good = Business.Goods[id]
	if not good then
		return
	end
	mutate(key, function(rec)
		if rec.Owner ~= player.UserId then
			return false, nil
		end
		Business.simulate(rec, now())
		local price = Business.priceOf(rec, id)
		local step = Business.priceStep(good)
		local new = if dir == 0 then good.Ref else Business.clampPrice(good, price + math.sign(dir) * step)
		rec.Prices[id] = new
		return true, nil
	end)
end

local function order(player: Player, key: string, id: string, lots: number)
	local good = Business.Goods[id]
	local rec = ownRecord(player, key, true)
	local bizType = rec and Business.Types[rec.Type or ""]
	if not rec or not bizType or not good or not good.Cost or not good.Lot or not Business.canSell(bizType, id) then
		return
	end
	lots = math.clamp(math.floor(lots), 1, 10)
	local units = (good.Lot :: number) * lots
	units = math.min(units, Business.stockMax(good) - (rec.Stock[id] or 0))
	if units < 1 then
		Notify:FireClient(player, "Info", "No cabe más en el almacén del negocio.")
		return
	end
	local cost = math.ceil((good.Cost :: number) * units)
	if not DataService.spend(player, cost) then
		Notify:FireClient(player, "Error", ("El pedido cuesta %s."):format(Format.money(cost)))
		return
	end
	local saved = mutate(key, function(r)
		if r.Owner ~= player.UserId then
			return false, nil
		end
		Business.simulate(r, now())
		r.Stock[id] = (r.Stock[id] or 0) + units
		Business.log(r, now(), ("Pedido al mayorista: %s %s (-%s)"):format(unitText(good, units), good.Name:lower(), Format.money(cost)))
		return true, nil
	end)
	if not saved then
		DataService.addMoney(player, cost)
		Notify:FireClient(player, "Error", "No se ha podido hacer el pedido. Prueba otra vez.")
		return
	end
	Notify:FireClient(player, "Success", ("🚚 Pedido recibido: %s %s (%s)"):format(unitText(good, units), good.Name:lower(), Format.money(cost)))
end

local function rename(player: Player, key: string)
	local _, _, new = mutate(key, function(rec)
		local bizType = Business.Types[rec.Type or ""]
		if rec.Owner ~= player.UserId or not bizType then
			return false, nil
		end
		local current = 1
		for i = 1, #bizType.Names do
			if Business.nameFor(bizType, i, rec.OwnerName) == rec.Name then
				current = i
			end
		end
		rec.Name = Business.nameFor(bizType, current + 1, rec.OwnerName)
		return true, nil
	end)
	if new then
		writeIndex(key, entryOf(new), false, player.UserId)
	end
end

local function sellPremise(player: Player, key: string)
	local rec = ownRecord(player, key, true)
	if not rec then
		return
	end
	local till = 0
	local saved = update(key, function(old)
		local r = live(old)
		if not r or r.Owner ~= player.UserId then
			return nil, nil
		end
		Business.simulate(r, now())
		till = math.floor(r.Till)
		return { Free = true, Key = key }, nil
	end)
	if not saved then
		Notify:FireClient(player, "Error", "No se ha podido vender ahora. Prueba otra vez.")
		return
	end
	cacheRecord(key, nil)
	writeIndex(key, nil, false, player.UserId)
	local amount = Business.sellBack(rec.Paid) + till
	DataService.addMoney(player, amount)
	DataService.save(player)
	close(player, "Manage")
	Notify:FireClient(player, "Success", ("🏷 Has vendido %s por %s (con lo que había en la caja)."):format(rec.Name or rec.Title, Format.money(amount)))
end

-- Un cliente compra en el mostrador
local function buy(player: Player, key: string, id: string, count: number)
	local good = Business.Goods[id]
	local premise = premises[key]
	if not good or not good.Item or not premise or not atPremise(player, premise) then
		return
	end
	count = math.clamp(math.floor(count), 1, 20)
	local rec = getRecord(key, true)
	if not rec or not rec.Open then
		Notify:FireClient(player, "Info", "Está cerrado.")
		return
	end
	if not InventoryService.canAdd(player, id, count) then
		Notify:FireClient(player, "Error", "🎒 No te cabe en la mochila.")
		return
	end
	local price = math.ceil(Business.priceOf(rec, id) * count)
	if not DataService.spend(player, price) then
		Notify:FireClient(player, "Error", ("Necesitas %s."):format(Format.money(price)))
		return
	end
	local saved, ok = mutate(key, function(r)
		Business.simulate(r, now())
		if r.Owner ~= rec.Owner or Business.priceOf(r, id) * count > price + 0.001 then
			return false, false
		end
		local sold = Business.sell(r, id, count)
		if sold and r.Owner ~= player.UserId then
			Business.log(r, now(), ("%s te ha comprado %d %s"):format(nameOf(player), count, good.Name:lower()))
		end
		return sold, sold
	end)
	if not saved or not ok then
		DataService.addMoney(player, price)
		Notify:FireClient(player, "Error", "Ya no queda. ¡Se te han adelantado!")
		return
	end
	InventoryService.add(player, id, count)
	Notify:FireClient(player, "Success", ("🛍️ +%d %s (%s)"):format(count, good.Name:lower(), Format.money(price)))
	local owner = Players:GetPlayerByUserId(rec.Owner)
	if owner and owner ~= player then
		Notify:FireClient(owner, "Money", ("🛍️ %s ha comprado en %s: +%s a la caja"):format(nameOf(player), rec.Name or "tu negocio", Format.money(price)))
	end
end

---------------------------------------------------------------------
-- Avisos (ProximityPrompt) de cada sitio
---------------------------------------------------------------------
local function onManage(player: Player, premise: Premise)
	local entry = index[premise.Key]
	if not entry then
		send(player, premisePanel(player, premise))
		return
	end
	if entry.Owner ~= player.UserId then
		Notify:FireClient(player, "Info", ("Este negocio es de %s."):format(entry.OwnerName))
		return
	end
	simulate(premise.Key)
	local rec = getRecord(premise.Key)
	if rec then
		send(player, managePanel(player, premise.Key, rec))
	end
end

local function onShop(player: Player, premise: Premise)
	local entry = index[premise.Key]
	if not entry then
		send(player, premisePanel(player, premise))
		return
	end
	if not entry.Type then
		Notify:FireClient(player, "Info", ("%s aún no ha abierto su negocio."):format(entry.OwnerName))
		return
	end
	simulate(premise.Key)
	local rec = getRecord(premise.Key)
	if rec then
		send(player, shopPanel(player, premise.Key, rec))
	end
end

local function onKitchen(player: Player, premise: Premise, part: BasePart)
	local entry = index[premise.Key]
	if not entry or entry.Owner ~= player.UserId then
		Notify:FireClient(player, "Info", "Solo el dueño o la dueña puede usar la cocina.")
		return
	end
	FarmService.openKitchen(player, part)
end

local function prompt(parent: Instance, action: string, object: string, key: Enum.KeyCode?, distance: number?): ProximityPrompt
	local p = Builder.prompt(parent, action, object, 0.2)
	p.MaxActivationDistance = distance or 10
	if key then
		p.KeyboardKeyCode = key
	end
	return p
end

-- Dentro del local (la sala se monta al entrar)
local function decorate(inst: any)
	local building = inst.Building
	if inst.Floor ~= 0 or building.Kind ~= "Local" then
		return
	end
	local premise = byBuilding[building.Id]
	-- (la caja y el mostrador pueden ir dentro del grupo "Checkout" de los muebles)
	local register = inst.Room.Model:FindFirstChild("Register", true) :: BasePart?
	local counter = inst.Room.Model:FindFirstChild("Counter", true) :: BasePart?
	if not premise or not register then
		return
	end
	local entry = index[premise.Key]
	local boardAt = register.Position + Vector3.new(0, 5.5, 0)
	local board = Builder.part({ Name = "CartelNegocio", Size = Vector3.new(10, 2.2, 0.3), CFrame = CFrame.lookAt(boardAt, boardAt + Vector3.new(0, 0, -1)), Color = Color3.fromRGB(30, 34, 44), CanCollide = false, CanQuery = false, Parent = inst.Room.Model })
	if not entry then
		board.Color = Color3.fromRGB(200, 40, 40)
		Builder.sign(board, ("SE VENDE · %s"):format(Format.money(Business.premisePrice("Local", premise.Key))), Enum.NormalId.Front)
		local p = prompt(register, "Ver el local", "🏬 Local en venta", Enum.KeyCode.E)
		p.Triggered:Connect(function(player)
			send(player, premisePanel(player, premise))
		end)
		return
	end
	local bizType = entry.Type and Business.Types[entry.Type]
	board.Color = if bizType then bizType.Color else Color3.fromRGB(80, 80, 90)
	Builder.sign(board, string.upper(displayName(entry)), Enum.NormalId.Front)
	local shop = prompt(register, "Comprar", displayName(entry), Enum.KeyCode.E)
	shop.Triggered:Connect(function(player)
		onShop(player, premise)
	end)
	local manage = prompt(register, "Gestionar", ("De %s"):format(entry.OwnerName), Enum.KeyCode.F, 8)
	manage.Triggered:Connect(function(player)
		onManage(player, premise)
	end)
	if bizType and bizType.Kitchen and counter then
		local kitchen = prompt(counter, "Cocina", "🍳 Hacer platos", Enum.KeyCode.R, 8)
		kitchen.Triggered:Connect(function(player)
			onKitchen(player, premise, counter)
		end)
	end
end

-- Cartel de la fachada (locales) o junto al poste/recepción (gasolineras y hoteles)
local function drawSign(premise: Premise)
	if premise.Sign then
		premise.Sign:Destroy()
		premise.Sign = nil
	end
	local entry = index[premise.Key]
	if not entry then
		return
	end
	local bizType = entry.Type and Business.Types[entry.Type]
	local height = if premise.Kind == "Local" then 9.5 else 8
	local at = premise.Door + Vector3.new(0, height, 0) + premise.Out * 0.9
	local board = Builder.part({
		Name = "CartelNegocio",
		Size = Vector3.new(16, 2.6, 0.4),
		CFrame = CFrame.lookAt(at, at + premise.Out),
		Color = if bizType then bizType.Color else Color3.fromRGB(80, 80, 90),
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = signFolder,
	})
	Builder.sign(board, string.upper(displayName(entry)), Enum.NormalId.Front, Color3.fromRGB(250, 245, 230))
	premise.Sign = board
end

local doorPrompts: { [number]: ProximityPrompt }? = nil
local function doorPrompt(buildingId: number): ProximityPrompt?
	if not doorPrompts then
		local map = {}
		for _, door in CollectionService:GetTagged("BuildingDoor") do
			local id = door:GetAttribute("BuildingId")
			local p = door:FindFirstChildOfClass("ProximityPrompt")
			if type(id) == "number" and p then
				map[id] = p
			end
		end
		doorPrompts = map
	end
	return (doorPrompts :: any)[buildingId]
end

local function applyPremise(premise: Premise)
	local entry = index[premise.Key]
	drawSign(premise)
	if premise.Building then
		local p = doorPrompt(premise.Building.Id)
		if p then
			p.ObjectText = if entry then displayName(entry) else premise.Building.Title .. " · local en venta"
		end
		-- La sala cambia: quien estuviera dentro sale a la calle y se rehace con lo nuevo
		for _, other in Players:GetPlayers() do
			if other:GetAttribute("InteriorKey") == premise.Building.Id .. ":0" then
				InteriorService.leave(other)
			end
		end
		InteriorService.reset(premise.Building, 0)
	elseif premise.Anchor then
		for _, p in premise.Anchor:GetChildren() do
			if p:IsA("ProximityPrompt") then
				if p.Name == "Manage" then
					p.ActionText = if entry then "Gestionar" else "Ver el negocio en venta"
					p.ObjectText = if entry then displayName(entry) else ("%s en venta · %s"):format(Business.Premises[premise.Kind].Name, Format.money(Business.premisePrice(premise.Kind, premise.Key)))
				elseif p.Name == "Shop" then
					p.Enabled = entry ~= nil and entry.Type ~= nil
					p.ObjectText = displayName(entry)
				end
			end
		end
	end
end

applyIndex = function(old: { [string]: Entry })
	for key, premise in premises do
		local a, b = old[key], index[key]
		local changed = (a == nil) ~= (b == nil)
		if a and b then
			changed = a.Type ~= b.Type or a.Name ~= b.Name or a.Owner ~= b.Owner or a.Open ~= b.Open
		end
		if changed then
			local ok, err = pcall(applyPremise, premise)
			if not ok then
				warn("[Negocios] " .. tostring(err))
			end
		end
	end
end

---------------------------------------------------------------------
-- Gasolineras y hoteles: repostar y reservar pagan al dueño
---------------------------------------------------------------------
local function premiseOfPump(pump: BasePart): Premise?
	for _, premise in premises do
		if premise.Pumps[pump] then
			return premise
		end
	end
	return nil
end

local fuelSeller = {
	-- Precio y litros que quedan (nil = gasolinera sin dueño o sin gasolina: precio normal)
	quote = function(pump: BasePart): (number?, number?)
		local premise = premiseOfPump(pump)
		local entry = premise and index[premise.Key]
		if not premise or not entry or entry.Type ~= "Gasolinera" or not entry.Open then
			return nil, nil
		end
		local rec = getRecord(premise.Key)
		local left = rec and rec.Stock.W_Gasolina or 0
		if not rec or left < 1 then
			return nil, nil
		end
		return Business.priceOf(rec, "W_Gasolina"), left
	end,
	sold = function(pump: BasePart, liters: number, paid: number)
		local premise = premiseOfPump(pump)
		if not premise then
			return
		end
		task.spawn(function()
			local _, _, rec = mutate(premise.Key, function(r)
				r.Stock.W_Gasolina = math.max(0, (r.Stock.W_Gasolina or 0) - liters)
				r.Till += paid
				r.Sales += paid
				r.Units += math.floor(liters)
				return true, nil
			end)
			local owner = rec and Players:GetPlayerByUserId(rec.Owner)
			if owner then
				Notify:FireClient(owner, "Money", ("⛽ Han repostado en %s: +%s a la caja"):format(rec.Name or "tu gasolinera", Format.money(paid)))
			end
		end)
	end,
}

local function onRoomSold(lobbyModel: Model, price: number, guest: Player)
	local premise = byLobby[lobbyModel]
	local entry = premise and index[premise.Key]
	if not premise or not entry or entry.Type ~= "Hotel" or not entry.Open then
		return
	end
	task.spawn(function()
		local _, _, rec = mutate(premise.Key, function(r)
			r.Till += price
			r.Sales += price
			r.Units += 1
			Business.log(r, now(), ("%s ha reservado habitación (+%s)"):format(nameOf(guest), Format.money(price)))
			return true, nil
		end)
		local owner = rec and Players:GetPlayerByUserId(rec.Owner)
		if owner and owner ~= guest then
			Notify:FireClient(owner, "Money", ("🏨 %s se aloja en %s: +%s a la caja"):format(nameOf(guest), rec.Name or "tu hotel", Format.money(price)))
		end
	end)
end

---------------------------------------------------------------------
-- Buscar los sitios en el mapa
---------------------------------------------------------------------
local function districtName(position: Vector3): string
	local d = MapInfo.districtAt(position.X, position.Z)
	return if d then d.Name else "Valmar"
end

local function roundKey(prefix: string, position: Vector3): string
	return ("%s:%d_%d"):format(prefix, math.floor(position.X + 0.5), math.floor(position.Z + 0.5))
end

local function addAnchorPremise(kind: string, key: string, model: Model, at: Vector3, out: Vector3, title: string): Premise
	local anchor = Builder.part({ Name = "Negocio", Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(at), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = signFolder })
	local premise: Premise = { Key = key, Kind = kind, Title = title, Building = nil, Model = model, Anchor = anchor, Pumps = {}, Door = at, Out = out, Sign = nil }
	local manage = prompt(anchor, "Ver el negocio en venta", title, Enum.KeyCode.F, 12)
	manage.Name = "Manage"
	manage.Triggered:Connect(function(player)
		onManage(player, premise)
	end)
	if kind == "Gas" then
		local shop = prompt(anchor, "Tienda", "", Enum.KeyCode.E, 12)
		shop.Name = "Shop"
		shop.Enabled = false
		shop.Triggered:Connect(function(player)
			onShop(player, premise)
		end)
	end
	premises[key] = premise
	return premise
end

local function findPremises()
	-- Locales: la planta baja de los edificios de comercio
	for _, building in InteriorService.all() do
		if building.Kind == "Local" and not building.Walkable then
			local key = "L:" .. building.Key
			local premise: Premise = {
				Key = key,
				Kind = "Local",
				Title = ("Local comercial · %s"):format(districtName(building.Door)),
				Building = building,
				Model = building.Model,
				Anchor = nil,
				Pumps = {},
				Door = building.Door,
				Out = building.Out,
				Sign = nil,
			}
			premises[key] = premise
			byBuilding[building.Id] = premise
		end
	end
	-- Gasolineras: el poste con el precio
	local town = workspace:FindFirstChild("Town")
	for _, model in if town then town:GetDescendants() else {} do
		if model:IsA("Model") and model.Name == "Gasolinera" then
			local pylon = model:FindFirstChild("Pylon") :: BasePart?
			local pumps = {}
			local center = Vector3.zero
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") and d:HasTag("FuelPump") then
					pumps[d] = true
					center += d.Position
				end
			end
			if pylon then
				local ground = pylon.Position - Vector3.new(0, pylon.Size.Y / 2, 0)
				local toward = Vector3.new(center.X - ground.X, 0, center.Z - ground.Z)
				local out = if toward.Magnitude > 0.1 then -toward.Unit else Vector3.new(0, 0, -1)
				local premise = addAnchorPremise("Gas", roundKey("G", pylon.Position), model, ground + Vector3.new(0, 3, 0) - out * 3, out, ("Gasolinera · %s"):format(districtName(pylon.Position)))
				premise.Pumps = pumps
			end
		end
	end
	-- Hoteles: detrás del mostrador de recepción
	for _, lobby in CollectionService:GetTagged("HotelLobby") do
		if lobby:IsA("Model") then
			local staff = lobby:GetAttribute("Staff")
			local door = lobby:GetAttribute("Door")
			if typeof(staff) == "Vector3" then
				local out = if typeof(door) == "Vector3" and (door - staff).Magnitude > 0.1 then Vector3.new(door.X - staff.X, 0, door.Z - staff.Z).Unit else Vector3.new(0, 0, -1)
				local name = lobby:GetAttribute("HotelName") or "Hotel"
				local premise = addAnchorPremise("Hotel", roundKey("H", staff), lobby, staff + Vector3.new(0, 1, 0), out, ("%s · %s"):format(tostring(name), districtName(staff)))
				premise.Door = if typeof(door) == "Vector3" then door + Vector3.new(0, 2, 0) else staff
				byLobby[lobby] = premise
			end
		end
	end
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------
function BusinessService.init()
	Remote = ReplicatedStorage.Remotes:FindFirstChild("Business") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Business"
		Remote.Parent = ReplicatedStorage.Remotes
	end
	signFolder = Instance.new("Folder")
	signFolder.Name = "Negocios"
	signFolder.Parent = workspace
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("Negocios_v1")
	end)
	store = if ok then result else nil

	findPremises()
	-- Todos los locales dicen en la puerta si están en venta
	for _, premise in premises do
		applyPremise(premise)
	end

	-- Dentro de los locales (encadenado con las viviendas de PropertyService)
	local previous = InteriorService.Hooks.Decorate
	InteriorService.Hooks.Decorate = function(inst)
		if previous then
			previous(inst)
		end
		decorate(inst)
	end
	VehicleService.FuelSeller = fuelSeller
	HotelService.RoomSold = onRoomSold

	loadIndex(true)

	Remote.OnServerEvent:Connect(function(player, action, key, a, b)
		local t = os.clock()
		if t - (lastRequest[player] or 0) < 0.15 then
			return
		end
		lastRequest[player] = t
		if type(action) ~= "string" or type(key) ~= "string" or not premises[key] then
			return
		end
		local premise = premises[key]
		if action == "Panel" then
			-- Pestañas: key es el Id de la ventana, a la pestaña, b la clave del negocio
			return
		end
		if action == "Buy" and type(a) == "string" and type(b) == "number" then
			buy(player, key, a, b)
			local rec = getRecord(key)
			if rec then
				send(player, shopPanel(player, key, rec))
			end
			return
		end
		if not atPremise(player, premise) and action ~= "Collect" then
			Notify:FireClient(player, "Info", "Tienes que estar en el negocio.")
			return
		end
		local tab = "Resumen"
		if action == "BuyPremise" then
			buyPremise(player, key)
			return
		elseif action == "Open" and type(a) == "string" then
			openBusiness(player, key, a)
			return
		elseif action == "Retype" then
			local rec = ownRecord(player, key, true)
			if rec then
				send(player, setupPanel(player, key))
			end
			return
		elseif action == "SellPremise" then
			sellPremise(player, key)
			return
		elseif action == "Collect" then
			collect(player, key)
		elseif action == "Toggle" then
			toggle(player, key)
		elseif action == "Stock" and type(a) == "string" and type(b) == "number" then
			stock(player, key, a, b)
			tab = "Existencias"
		elseif action == "Unstock" and type(a) == "string" then
			unstock(player, key, a)
			tab = "Existencias"
		elseif action == "Price" and type(a) == "string" and type(b) == "number" then
			setPrice(player, key, a, b)
			tab = "Precios"
		elseif action == "Order" and type(a) == "string" and type(b) == "number" then
			order(player, key, a, b)
			tab = "Mayorista"
		elseif action == "Rename" then
			rename(player, key)
			tab = "Ajustes"
		else
			return
		end
		local rec = getRecord(key)
		if rec and rec.Owner == player.UserId then
			send(player, managePanel(player, key, rec, tab))
		end
	end)
	-- Pestañas de las ventanas: ("Panel", idVentana, pestaña, clave)
	Remote.OnServerEvent:Connect(function(player, action, panelId, tab, key)
		if action ~= "Panel" or type(key) ~= "string" or not premises[key] then
			return
		end
		if panelId == "Manage" and type(tab) == "string" then
			local rec = getRecord(key)
			if rec and rec.Owner == player.UserId then
				send(player, managePanel(player, key, rec, tab))
			end
		end
	end)

	-- Al entrar: lo que han vendido tus negocios mientras no estabas
	local function welcome(player: Player)
		loadIndex()
		for _, key in ownedKeys(player) do
			local units, money = simulate(key)
			if units > 0 then
				local rec = getRecord(key)
				Notify:FireClient(player, "Money", ("🏪 Mientras no estabas, %s ha vendido %d productos (+%s a la caja)."):format(rec and rec.Name or "tu negocio", units, Format.money(money)))
			end
		end
	end
	DataService.onLoaded(function(player)
		task.spawn(welcome, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)

	-- Cada minuto: los vecinos compran en los negocios de los que están aquí; el índice se refresca
	task.spawn(function()
		while true do
			task.wait(60)
			local ok2, err = pcall(function()
				loadIndex(true)
				for _, player in Players:GetPlayers() do
					for _, key in ownedKeys(player) do
						local units, money = simulate(key)
						if units > 0 then
							local rec = getRecord(key)
							Notify:FireClient(player, "Money", ("🏪 %s: los vecinos han comprado %d (+%s a la caja)"):format(rec and rec.Name or "Tu negocio", units, Format.money(money)))
						end
					end
				end
			end)
			if not ok2 then
				warn("[Negocios] " .. tostring(err))
			end
		end
	end)

	local counts = { Local = 0, Gas = 0, Hotel = 0 }
	for _, premise in premises do
		counts[premise.Kind] += 1
	end
	print(("[Negocios] %d locales, %d gasolineras y %d hoteles"):format(counts.Local, counts.Gas, counts.Hotel))
end

-- Para las pruebas
BusinessService._premises = premises
BusinessService._index = function()
	return index
end
BusinessService._simulate = simulate
BusinessService._getRecord = getRecord

return BusinessService
