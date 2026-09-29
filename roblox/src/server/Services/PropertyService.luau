-- PropertyService: casas y pisos del mapa que se compran, y los vecinos que viven en ellos.
-- (Reglas y precios en shared/Properties; los interiores los monta InteriorService.)
--
--   * Viviendas: cada casa y villa, y cada planta de los bloques de pisos (portal + ascensor).
--   * En más o menos la mitad viven vecinos: personajes del juego (los de la historia tienen su
--     casa: aquí vive Mateo, allí la profesora Lucía…) y otros vecinos con nombre. Al entrar te
--     saludan y puedes hablar con ellos.
--   * Las demás están en venta: dentro hay un cartel "SE VENDE" con el precio. Al comprarla es tuya
--     en todos los servidores (DataStore): nadie más puede comprarla. Máximo Properties.MaxOwned.
--   * En tu vivienda: cartel con tu nombre, "Vender" (te devuelven una parte) y "Ir a casa" del
--     teléfono te lleva a ella. Solo entráis tú y los de tu grupo.
--   * El ascensor dice quién vive en cada planta o si está en venta.
--   * En los bloques, cada planta tiene varias viviendas con su puerta en el pasillo (3ºA, 3ºB…:
--     shared/Floors). La A de cada planta es la de antes (una por planta), así nadie pierde la suya.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Properties = require(ReplicatedStorage.Shared.Properties)
local Housing = require(ReplicatedStorage.Shared.Housing)
local MapInfo = require(ReplicatedStorage.Shared.MapInfo)
local Floors = require(ReplicatedStorage.Shared.Floors)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Builder = require(script.Parent.Parent.World.Builder)
local Npc = require(script.Parent.Parent.World.Npc)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local InteriorService = require(script.Parent.InteriorService)

local PropertyService = {}

-- Kind: "Compra" (suya), "Alquiler" (paga cada día de juego) o "Inicial" (la que le tocó al llegar).
-- Access: quién tiene llave (UserId en texto -> nombre). Privacy: "Grupo" (su grupo y los que
-- tienen llave), "Llaves" (solo los que tienen llave) o "Cerrada" (nadie más).
type Owner = { UserId: number, Name: string, Price: number, Since: number, Kind: string?, Rent: number?, Access: { [string]: string }?, Privacy: string? }
type Registry = { [string]: Owner } -- planta (texto) -> dueño

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local store: DataStore? = nil
local registries: { [string]: { Data: Registry, At: number } } = {}
local memory: { [string]: Registry } = {} -- (Studio sin API: se guarda solo en este servidor)
local CACHE_SECONDS = 45

-- Personajes de la historia que tienen casa en la ciudad (los niños, con su familia)
local RESIDENTS = {
	"Lucia", "Ramon", "Marta", "Marisa", "Paula", "Julian", "Andres", "Nico", "Sara", "Omar", "Mateo", "Dani",
	"Bruno", "Ruben", "Hugo", "Alex", "Vega", "Iker", "Javier", "Carmen", "Leire", "Rayo", "Nerea", "Dario",
	"Paco", "Ernesto", "Nuria", "Tomas", "Ines", "Marcos", "Lola", "Sofia", "Irene", "Toni", "Beltran", "Luca",
	"Julia", "Pablo", "Adrian", "Carla", "Montse", "Ignacio", "Rocio", "Alba",
}
local castHomes: { [string]: string } = {} -- vivienda -> personaje

local GREETINGS = {
	"¡Hola, vecino! ¿Qué tal?",
	"Buenas. ¿Buscas a alguien?",
	"¡Anda, visita! Pasa, pasa.",
	"¿Vienes por lo del ruido de anoche? No fui yo, ¿eh?",
	"Hola. Si ves al portero, dile que el ascensor hace un ruido raro.",
	"¡Buenos días! Qué bien huele a café, ¿verdad?",
}
local TALK = {
	"Llevo aquí toda la vida. El barrio ha cambiado mucho.",
	"El del quinto pone la música altísima.",
	"Dicen que van a arreglar la calle este mes. A ver si es verdad.",
	"¿Has probado el café de la plaza? Está buenísimo.",
	"Mañana tengo que madrugar para trabajar. ¡Qué pereza!",
	"Si necesitas sal, aquí me tienes. Para eso están los vecinos.",
}

---------------------------------------------------------------------
-- Quién es el dueño (un registro por edificio en el DataStore)
---------------------------------------------------------------------
local function registry(buildingKey: string, fresh: boolean?): Registry
	local cached = registries[buildingKey]
	if cached and not fresh and os.clock() - cached.At < CACHE_SECONDS then
		return cached.Data
	end
	local data: Registry = memory[buildingKey] or {}
	if store then
		local ok, result = pcall(function()
			return (store :: DataStore):GetAsync(buildingKey)
		end)
		if ok then
			data = if type(result) == "table" then result else {}
		end
	end
	registries[buildingKey] = { Data = data, At = os.clock() }
	return data
end

-- Guarda un cambio de dueño sin pisar a nadie (devuelve false si ya estaba comprada).
-- Con edit (y onlyIf = el dueño), cambia su ficha (llaves, privacidad…) sin cambiar de dueño.
local function claim(buildingKey: string, slot: string, owner: Owner?, onlyIf: number?, edit: ((Owner) -> ())?): boolean
	local okChange = false
	local function change(old: any): any
		okChange = false -- UpdateAsync puede repetir esta función: vale lo de la última vez
		local data = if type(old) == "table" then old else {}
		local current = data[slot]
		if edit then
			if not current or current.UserId ~= onlyIf then
				return nil
			end
			edit(current)
			okChange = true
			return data
		end
		if owner and current then
			return nil -- ya tiene dueño
		end
		if not owner and (not current or current.UserId ~= onlyIf) then
			return nil -- no es suya
		end
		data[slot] = owner
		okChange = true
		return data
	end
	local saved = false
	if store then
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(buildingKey, change)
		end)
		saved = ok
		if not ok then
			warn("[Viviendas] " .. tostring(err))
			if not RunService:IsStudio() then
				return false
			end
		end
	end
	if not saved then
		-- (Studio sin acceso a la API: solo en este servidor)
		memory[buildingKey] = change(memory[buildingKey]) or memory[buildingKey]
	end
	registries[buildingKey] = nil
	return okChange
end

---------------------------------------------------------------------
-- Viviendas
---------------------------------------------------------------------
-- Cada vivienda: el edificio, la planta y la letra de su puerta (A si no se dice)
local function slotOf(floor: number, letter: string?): string
	return Floors.unitId(floor, letter)
end

local function unitKind(building: InteriorService.Building, floor: number, letter: string?): string?
	if letter == "T" then
		return nil -- (escalera y pasillos)
	end
	if building.Kind == "Casa" or building.Kind == "Villa" then
		return if floor == 0 and (letter == nil or letter == "A") then building.Kind else nil
	end
	if building.Upper == "Piso" and floor >= 1 then
		if InteriorService.isTower(building) then
			local unit = InteriorService.unitOf(building, floor, letter)
			return if unit and unit.Kind == "Piso" then "Piso" else nil
		end
		return if letter == nil or letter == "A" then "Piso" else nil
	end
	return nil
end

local function ownerOf(building: InteriorService.Building, floor: number, letter: string?): Owner?
	return registry(building.Key)[slotOf(floor, letter)]
end

local function unitKeyOf(building: InteriorService.Building, floor: number, letter: string?): string
	return Properties.unitKey(building.Key, slotOf(floor, letter))
end

local function titleOf(building: InteriorService.Building, floor: number, letter: string?): string
	if floor == 0 then
		return building.Title
	end
	local unit = InteriorService.isTower(building) and InteriorService.unitOf(building, floor, letter)
	return if unit then ("%s · %s"):format(building.Title, unit.Label) else ("%s · planta %d"):format(building.Title, floor)
end

---------------------------------------------------------------------
-- La ficha de cada vivienda (shared/Housing): ID, tipo, precio y alquiler
---------------------------------------------------------------------
local buildingIndex: { [string]: { District: number, DistrictName: string?, Number: number } }? = nil

-- Cada edificio: su distrito (1-6, o 0 fuera de ellos) y su número dentro del distrito (fijo: por su clave)
local function indexOf(building: InteriorService.Building): { District: number, DistrictName: string?, Number: number }
	if not buildingIndex then
		local index = {}
		local byDistrict: { [number]: { InteriorService.Building } } = {}
		for _, b in InteriorService.all() do
			local d = 0
			local name = nil
			for i, district in MapInfo.Districts do
				local ok, inside = pcall(MapInfo.districtAt, b.Door.X, b.Door.Z)
				if ok and inside == district then
					d, name = i, district.Name
					break
				end
			end
			byDistrict[d] = byDistrict[d] or {}
			table.insert(byDistrict[d], b)
			index[b.Key] = { District = d, DistrictName = name, Number = 0 }
		end
		for _, list in byDistrict do
			table.sort(list, function(a, b)
				return a.Key < b.Key
			end)
			for i, b in list do
				index[b.Key].Number = i
			end
		end
		buildingIndex = index
	end
	return (buildingIndex :: any)[building.Key] or { District = 0, Number = 0 }
end

function PropertyService.sheetOf(building: InteriorService.Building, floor: number, letter: string?): Housing.Sheet?
	local kind = unitKind(building, floor, letter)
	if not kind then
		return nil
	end
	local idx = indexOf(building)
	local doors = if InteriorService.isTower(building) then #Floors.units(building.Key, building.Kind, building.Upper, floor) else 1
	return Housing.sheet({
		District = idx.District, DistrictName = idx.DistrictName, Building = idx.Number, Floor = floor, Letter = letter,
		Kind = kind, UnitKey = unitKeyOf(building, floor, letter), Top = building.Floors - 1, Doors = doors,
	})
end

function PropertyService.idOf(building: InteriorService.Building, floor: number, letter: string?): string
	local idx = indexOf(building)
	return Housing.id(idx.District, idx.Number, floor, letter)
end

function PropertyService.priceOf(building: InteriorService.Building, floor: number, letter: string?): number
	local sheet = PropertyService.sheetOf(building, floor, letter)
	if sheet then
		return sheet.Price
	end
	return Properties.price(unitKind(building, floor, letter) or "Piso", floor, unitKeyOf(building, floor, letter))
end

-- Llaves que da el timbre (quien abre desde dentro): unidad -> UserId -> hasta cuándo
local tempAccess: { [string]: { [number]: number } } = {}

function PropertyService.grantTemp(building: InteriorService.Building, floor: number, letter: string?, userId: number, seconds: number?)
	local key = unitKeyOf(building, floor, letter)
	tempAccess[key] = tempAccess[key] or {}
	tempAccess[key][userId] = os.clock() + (seconds or Housing.TempAccessSeconds)
end

-- ¿Puede entrar (y usar la casa como invitado)? El dueño, los que tienen llave, los de su grupo
-- (si la privacidad lo deja) y a quien acaba de abrir desde el timbre
local function welcome(player: Player, building: InteriorService.Building, floor: number, letter: string?, owner: Owner): boolean
	if owner.UserId == player.UserId then
		return true
	end
	local privacy = owner.Privacy or "Grupo"
	if privacy == "Cerrada" then
		return false
	end
	local temp = tempAccess[unitKeyOf(building, floor, letter)]
	if temp and temp[player.UserId] and os.clock() < temp[player.UserId] then
		return true
	end
	if owner.Access and owner.Access[tostring(player.UserId)] then
		return true
	end
	if privacy == "Grupo" then
		local ownerPlayer = Players:GetPlayerByUserId(owner.UserId)
		local group = player:GetAttribute("GroupId")
		if ownerPlayer and group ~= nil and ownerPlayer:GetAttribute("GroupId") == group then
			return true
		end
	end
	return false
end

local function ownedList(player: Player): { { [string]: any } }
	local data = DataService.get(player)
	if not data then
		return {}
	end
	data.Properties = data.Properties or {}
	return data.Properties
end

local function syncAttributes(player: Player)
	local list = ownedList(player)
	local titles = {}
	for _, entry in list do
		table.insert(titles, entry.Title or "Vivienda")
	end
	player:SetAttribute("Properties", #list)
	player:SetAttribute("Homes", if #titles > 0 then table.concat(titles, "\n") else nil)
end

-- Cuántas cuentan para el máximo (la que te tocó al llegar no cuenta)
local function countedHomes(list: { { [string]: any } }): number
	local n = 0
	for _, entry in list do
		if entry.Contract ~= "Inicial" then
			n += 1
		end
	end
	return n
end

-- mode: "Compra" (por defecto) o "Alquiler" (se paga el primer día y luego cada día de juego)
local function buy(player: Player, building: InteriorService.Building, floor: number, letter: string?, mode: string?)
	local kind = unitKind(building, floor, letter)
	if not kind then
		return
	end
	local renting = mode == "Alquiler"
	local unit = unitKeyOf(building, floor, letter)
	local stage = player:GetAttribute("LifeStage")
	if stage and not Stages.inRange(stage, Properties.MinStage, nil) then
		Notify:FireClient(player, "Error", ("Para %s una vivienda hay que ser mayor de edad."):format(if renting then "alquilar" else "comprar"))
		return
	end
	if Properties.isNeighborHome(unit) then
		Notify:FireClient(player, "Error", "Aquí ya vive alguien: no está en venta.")
		return
	end
	local list = ownedList(player)
	if countedHomes(list) >= Properties.MaxOwned then
		Notify:FireClient(player, "Error", ("Ya tienes %d viviendas (el máximo). Deja una antes."):format(countedHomes(list)))
		return
	end
	local price = PropertyService.priceOf(building, floor, letter)
	local rent = Housing.rent(price)
	local pay = if renting then rent else price
	local data = DataService.get(player)
	if not data or data.Money < pay then
		Notify:FireClient(player, "Error", ("Necesitas %s para %s."):format(Format.money(pay), if renting then "el primer día de alquiler" else "comprarla"))
		return
	end
	-- Primero se aparta el dinero, luego se registra (si alguien se adelantó, se devuelve)
	if not DataService.spend(player, pay) then
		return
	end
	local owner: Owner = { UserId = player.UserId, Name = player.DisplayName, Price = if renting then 0 else price, Since = os.time(), Kind = if renting then "Alquiler" else "Compra", Rent = if renting then rent else nil }
	if not claim(building.Key, slotOf(floor, letter), owner) then
		DataService.addMoney(player, pay)
		Notify:FireClient(player, "Error", ("¡Vaya! Alguien la acaba de %s."):format(if renting then "alquilar" else "comprar"))
		return
	end
	-- Se ha ido (o ha empezado una vida nueva) mientras se registraba: su partida ya no es esta y no
	-- se apuntaría en ella. Se deshace la compra para que la vivienda no se quede con un dueño que
	-- no la tiene en su lista (el dinero vuelve si su guardado de salida aún no ha terminado)
	if DataService.get(player) ~= data or not player.Parent then
		claim(building.Key, slotOf(floor, letter), nil, player.UserId)
		DataService.addMoney(player, pay)
		return
	end
	table.insert(list, {
		Key = building.Key, Floor = floor, Letter = letter or "A", Kind = kind, Title = titleOf(building, floor, letter),
		Price = if renting then 0 else price, Contract = if renting then "Alquiler" else "Compra", Rent = if renting then rent else nil,
		Id = PropertyService.idOf(building, floor, letter), Since = os.time(),
	})
	-- La nueva pasa a ser "su casa" («Ir a casa»)
	data.Housing = data.Housing or {}
	data.Housing.Home = { Key = building.Key, Floor = floor, Letter = letter or "A" }
	syncAttributes(player)
	DataService.save(player)
	if renting then
		Notify:FireClient(player, "Success", ("🔑 Has alquilado %s: %s al día (el primero ya está pagado)."):format(titleOf(building, floor, letter), Format.money(rent)))
	else
		Notify:FireClient(player, "Success", ("🏠 ¡Enhorabuena! Has comprado %s por %s."):format(titleOf(building, floor, letter), Format.money(price)))
	end
	StoryEvents.emit(player, "HomeClaimed", { Property = unit, Price = pay, Contract = if renting then "Alquiler" else "Compra" })
	-- La sala cambia: fuera el cartel de se vende
	-- Quien estuviera visitándola sale a la calle; la sala se rehace con el cartel del dueño
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("InteriorKey") == building.Id .. ":" .. slotOf(floor, letter) then
			InteriorService.leave(other)
		end
	end
	InteriorService.reset(building, floor, letter)
	-- (sin mirar si está ocupado: si estaba de visita dentro, reset lo ha sacado al rellano y tiene
	-- que volver a entrar pase lo que pase)
	InteriorService.goToUnit(player, building, floor, letter, true)
end

local function sell(player: Player, building: InteriorService.Building, floor: number, letter: string?)
	local list = ownedList(player)
	for i, entry in list do
		if entry.Key == building.Key and entry.Floor == floor and (entry.Letter or "A") == (letter or "A") then
			if not claim(building.Key, slotOf(floor, letter), nil, player.UserId) then
				Notify:FireClient(player, "Error", "No se ha podido vender ahora. Prueba otra vez.")
				return
			end
			table.remove(list, i)
			if entry.Contract == "Alquiler" or entry.Contract == "Inicial" then
				-- (no es suya del todo: se deja, sin cobrar nada; la deuda del alquiler se queda y se te
				-- sigue cobrando, HousingService.collectRent)
				local data = DataService.get(player)
				if data and (entry.Debt or 0) > 0 then
					data.Housing = data.Housing or {}
					data.Housing.Debt = (data.Housing.Debt or 0) + entry.Debt
				end
				syncAttributes(player)
				DataService.save(player)
				Notify:FireClient(player, "Info", ("🔑 Has dejado %s."):format(entry.Title or "la vivienda"))
			else
				local amount = Properties.sellPrice(entry.Price or Properties.price(entry.Kind, floor, unitKeyOf(building, floor, letter)))
				DataService.addMoney(player, amount)
				syncAttributes(player)
				DataService.save(player)
				Notify:FireClient(player, "Success", ("🏷 Has vendido %s por %s."):format(entry.Title or "tu vivienda", Format.money(amount)))
			end
			-- Vuelve a estar en venta: la sala se rehace (y quien siga dentro sale a la calle)
			for _, other in Players:GetPlayers() do
				if other:GetAttribute("InteriorKey") == building.Id .. ":" .. slotOf(floor, letter) then
					InteriorService.leave(other)
				end
			end
			InteriorService.reset(building, floor, letter)
			return
		end
	end
end

---------------------------------------------------------------------
-- Vecinos dentro de las viviendas
---------------------------------------------------------------------
local function castLook(id: string): ({ [string]: any }?, string?)
	local person = Cast.People[id]
	if type(person) ~= "table" then
		return nil, nil
	end
	local look = { Skin = person.Skin, Shirt = person.Shirt, Pants = person.Pants, Shoes = person.Shoes, Hair = person.Hair, LongHair = person.LongHair, LongSleeves = person.LongSleeves }
	-- (el nombre puede ser una clave de textos: "NPC.NICO" -> "Nico")
	local name = person.Name
	if string.sub(name, 1, 4) == "NPC." then
		name = Strings.get(name)
	end
	return look, name
end

local function resident(inst: InteriorService.Instance_, name: string, spot: CFrame, look: { [string]: any }?, scale: number?, seat: BasePart?)
	local model = Npc.create(name, inst.Room.Model, spot, look)
	if scale and scale ~= 1 then
		pcall(function()
			model:ScaleTo(scale)
		end)
	end
	if seat then
		-- Sentado en el sofá (el asiento queda ocupado: nadie más se sienta encima)
		seat:SetAttribute("Taken", true)
		pcall(Npc.sit, model, seat)
	end
	model:SetAttribute("Resident", true)
	local root = model.PrimaryPart
	if root then
		local prompt = Builder.prompt(root, "Hablar", "🙂 " .. name, 0)
		prompt.MaxActivationDistance = 8
		prompt.Triggered:Connect(function()
			Npc.say(model, TALK[math.random(1, #TALK)])
			task.delay(4, function()
				if model.Parent then
					Npc.say(model, nil)
				end
			end)
		end)
	end
	return model
end

-- Carteles dentro de la vivienda (junto a la entrada)
local function signAt(inst: InteriorService.Instance_, text: string, color: Color3, offsetX: number): BasePart
	local r = inst.Room
	local part = Builder.part({
		Name = "PropertySign",
		Size = Vector3.new(7, 3.4, 0.4),
		-- (las viviendas dicen dónde caben sin tapar muebles; si no, junto a la entrada)
		CFrame = if r.SignAt then r.SignAt(if offsetX < 0 then -1 else 1) else r.at(offsetX, 4.5, -r.D / 2 + 6),
		Color = color,
		CanCollide = false,
		Parent = r.Model,
	})
	Builder.sign(part, text, Enum.NormalId.Front)
	Builder.sign(part, text, Enum.NormalId.Back)
	return part
end

local function decorate(inst: InteriorService.Instance_)
	local building, floor, letter = inst.Building, inst.Floor, inst.Unit
	local r = inst.Room
	-- (el portero de los portales está en el vestíbulo del edificio: World/Tower)
	local kind = unitKind(building, floor, letter)
	if not kind then
		return
	end
	local unit = unitKeyOf(building, floor, letter)
	local owner = ownerOf(building, floor, letter)
	if owner then
		local contract = owner.Kind or "Compra"
		local sheet = PropertyService.sheetOf(building, floor, letter)
		local head = if contract == "Alquiler" then "🔑 ALQUILADA POR " elseif contract == "Inicial" then "🏠 PISO DE " else "🏠 CASA DE "
		signAt(inst, head .. string.upper(owner.Name) .. (if sheet then "\n" .. sheet.Id else ""), Color3.fromRGB(40, 90, 150), -8)
		local leaving = contract ~= "Compra"
		local sellSign = signAt(inst, if leaving then "DEJAR" else "VENDER", Color3.fromRGB(120, 60, 40), 8)
		local prompt = Builder.prompt(sellSign, if leaving then "Dejar la vivienda" else "Vender la vivienda", if leaving then "🔑 Devuelves las llaves" else ("🏷 Te dan %s"):format(Format.money(Properties.sellPrice(owner.Price))), 2)
		prompt:SetAttribute("OwnerUserId", owner.UserId) -- (solo lo ve el dueño; JobPrompts)
		prompt:SetAttribute("JobOnly", nil)
		prompt.Triggered:Connect(function(player)
			if player.UserId == owner.UserId then
				sell(player, building, floor, letter)
			end
		end)
		-- Llaves: dar y quitar acceso, privacidad y echar visitas (HousingService)
		local keys = Builder.prompt(sellSign, "Llaves y visitas", "🔑 Quién puede entrar", 0.3)
		keys.KeyboardKeyCode = Enum.KeyCode.F
		keys:SetAttribute("OwnerUserId", owner.UserId)
		keys.Triggered:Connect(function(player)
			if player.UserId == owner.UserId and PropertyService.OnKeysPanel then
				PropertyService.OnKeysPanel(player, building, floor, letter)
			end
		end)
		return
	end
	if Properties.isNeighborHome(unit) then
		-- Vecinos: un personaje de la historia (si esta es su casa) o vecinos con nombre
		local castId = castHomes[unit]
		-- (sitios libres que deja la sala: salón, comedor, junto a la ventana)
		local spots = if #r.Spots > 0
			then r.Spots
			else {
				r.at(r.W * 0.2, 0, -r.D * 0.02 - 2) * CFrame.Angles(0, math.pi, 0),
				r.at(-r.W * 0.22, 0, -r.D * 0.2 - 3),
				r.at(-r.W * 0.1, 0, -r.D * 0.3),
			}
		local names = Properties.neighbors(unit)
		-- Uno de ellos, a veces, sentado en el sofá
		local sofaSeat: BasePart? = nil
		if Properties.hash("sofa:" .. unit) % 2 == 0 then
			for _, d in r.Model:GetDescendants() do
				if d:IsA("Seat") and d.Parent and d.Parent.Name == "Sofa" then
					sofaSeat = d
					break
				end
			end
		end
		if castId then
			local look, name = castLook(castId)
			local person = Cast.People[castId]
			local scale = if person and person.Kid then 0.65 elseif person and person.Teen then 0.85 else 1
			resident(inst, name or castId, spots[1], look, scale, if scale == 1 then sofaSeat else nil)
			if person and (person.Kid or person.Teen) then
				resident(inst, names[1], spots[2], nil) -- vive con su familia
			end
			signAt(inst, "🏠 AQUÍ VIVE " .. string.upper(name or castId), Color3.fromRGB(60, 110, 70), -8)
		else
			for i, name in names do
				resident(inst, name, spots[i] or spots[1], nil, nil, if i == 1 then sofaSeat else nil)
			end
			signAt(inst, "🏠 FAMILIA " .. string.upper(string.match(names[1], "%s(.+)$") or names[1]), Color3.fromRGB(60, 110, 70), -8)
		end
		return
	end
	-- En venta o en alquiler (con su ficha: tipo, habitaciones, metros…)
	local price = PropertyService.priceOf(building, floor, letter)
	local sheet = PropertyService.sheetOf(building, floor, letter)
	local rent = Housing.rent(price)
	local info = if sheet then "\n" .. Housing.describe(sheet) .. "\n" .. sheet.Id else ""
	local sale = signAt(inst, ("SE VENDE · %s\nSE ALQUILA · %s/día%s"):format(Format.money(price), Format.money(rent), info), Color3.fromRGB(180, 40, 40), -8)
	local prompt = Builder.prompt(sale, "Comprar vivienda", ("🏷 %s · %s"):format(titleOf(building, floor, letter), Format.money(price)), 1.5)
	prompt.MaxActivationDistance = 10
	prompt.Triggered:Connect(function(player)
		buy(player, building, floor, letter)
	end)
	local rentPrompt = Builder.prompt(sale, "Alquilar vivienda", ("🔑 %s al día"):format(Format.money(rent)), 1)
	rentPrompt.KeyboardKeyCode = Enum.KeyCode.R
	rentPrompt.MaxActivationDistance = 10
	rentPrompt.Triggered:Connect(function(player)
		buy(player, building, floor, letter, "Alquiler")
	end)
end

-- Al entrar: saludo de los vecinos y aviso de quién vive
local function onEnter(player: Player, inst: InteriorService.Instance_)
	for _, model in inst.Room.Model:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("Resident") then
			Npc.say(model, GREETINGS[math.random(1, #GREETINGS)])
			task.delay(4, function()
				if model.Parent then
					Npc.say(model, nil)
				end
			end)
			break
		end
	end
	local kind = unitKind(inst.Building, inst.Floor, inst.Unit)
	local unit = unitKeyOf(inst.Building, inst.Floor, inst.Unit)
	if kind and not ownerOf(inst.Building, inst.Floor, inst.Unit) and not Properties.isNeighborHome(unit) then
		local price = PropertyService.priceOf(inst.Building, inst.Floor, inst.Unit)
		Notify:FireClient(player, "Info", ("🏷 En venta: %s · o en alquiler: %s al día"):format(Format.money(price), Format.money(Housing.rent(price))))
	end
end

-- Solo entran el dueño y los de su grupo; en las de los vecinos y las que se venden, cualquiera
local function gate(player: Player, building: InteriorService.Building, floor: number, letter: string?): (boolean, string?)
	if not unitKind(building, floor, letter) then
		return true
	end
	local owner = ownerOf(building, floor, letter)
	if not owner or welcome(player, building, floor, letter, owner) then
		return true
	end
	return false, ("🔒 Es la casa de %s."):format(owner.Name)
end

-- Qué pone el ascensor en cada planta
local function labels(building: InteriorService.Building): { [number]: string }
	local out = {}
	if building.Upper ~= "Piso" then
		return out
	end
	local reg = registry(building.Key)
	for floor = 1, building.Floors - 1 do
		-- Cada planta: quién tiene casa (jugadores) y cuántas hay en venta
		local owners, forSale, total = {}, 0, 0
		for _, u in Floors.units(building.Key, building.Kind, building.Upper, floor) do
			total += 1
			local owner = reg[u.Id]
			if owner then
				table.insert(owners, owner.Name)
			elseif not Properties.isNeighborHome(Properties.unitKey(building.Key, u.Id)) then
				forSale += 1
			end
		end
		if #owners > 0 then
			out[floor] = "👤 " .. table.concat(owners, ", ")
		elseif forSale > 0 then
			out[floor] = ("🏷 %d en venta"):format(forSale)
		else
			out[floor] = ("🙂 %d vecinos"):format(total)
		end
	end
	return out
end

-- Qué es esa sala para ese jugador (lo usa InteractService con los muebles; shared/Interact):
-- "Owner" (suya), "Guest" (de alguien de su grupo), "Stranger" (de otro jugador), "Neighbor"
-- (viven vecinos), "ForSale" (en venta) o "Public" (no es una vivienda)
function PropertyService.access(player: Player, building: InteriorService.Building, floor: number, letter: string?): string
	if not unitKind(building, floor, letter) then
		return "Public"
	end
	local owner = ownerOf(building, floor, letter)
	if owner then
		if owner.UserId == player.UserId then
			return "Owner"
		end
		return if welcome(player, building, floor, letter, owner) then "Guest" else "Stranger"
	end
	if Properties.isNeighborHome(unitKeyOf(building, floor, letter)) then
		return "Neighbor"
	end
	return "ForSale"
end

-- ¿Tiene dueño esa vivienda? (UserId y nombre, o nil)
function PropertyService.ownerOf(building: InteriorService.Building, floor: number, letter: string?): Owner?
	if not unitKind(building, floor, letter) then
		return nil
	end
	return ownerOf(building, floor, letter)
end

-- Quién vive detrás de una puerta del pasillo (la placa y el cartel de la puerta: InteriorService)
local function occupant(building: InteriorService.Building, unit: any): { Type: string, Name: string?, UserId: number? }
	local floor, letter = Floors.parseUnit(unit.Id)
	if not floor then
		return { Type = "ForSale" }
	end
	local owner = ownerOf(building, floor, letter)
	if owner then
		return { Type = "Owner", Name = owner.Name, UserId = owner.UserId }
	end
	local key = unitKeyOf(building, floor, letter)
	if Properties.isNeighborHome(key) then
		local castId = castHomes[key]
		local _, castName = castLook(castId or "")
		if castName then
			return { Type = "Neighbor", Name = castName }
		end
		local first = Properties.neighbors(key)[1]
		return { Type = "Neighbor", Name = "Fam. " .. (string.match(first, "%s(.+)$") or first) }
	end
	return { Type = "ForSale" }
end
PropertyService.occupant = occupant

-- "Ir a casa": a tu vivienda (la primera que compraste)
function PropertyService.goHome(player: Player): boolean
	local list = ownedList(player)
	-- La que eligió como casa (HousingService); si no, la primera
	local data = DataService.get(player)
	local chosen = data and data.Housing and data.Housing.Home
	local home = list[1]
	for _, entry in list do
		if chosen and entry.Key == chosen.Key and entry.Floor == chosen.Floor and (entry.Letter or "A") == (chosen.Letter or "A") then
			home = entry
		end
	end
	if not home then
		return false
	end
	local building = InteriorService.byKey(home.Key)
	if not building then
		return false
	end
	InteriorService.goToUnit(player, building, home.Floor, home.Letter)
	return true
end

function PropertyService.list(player: Player): { { [string]: any } }
	return ownedList(player)
end

---------------------------------------------------------------------
-- Para HousingService: llaves, privacidad, vivienda inicial y fin del alquiler
---------------------------------------------------------------------
-- Cambia la ficha del dueño (llaves, privacidad) en el registro de todos los servidores
function PropertyService.editOwner(building: InteriorService.Building, floor: number, letter: string?, userId: number, edit: (Owner) -> ()): boolean
	return claim(building.Key, slotOf(floor, letter), nil, userId, edit)
end

-- Viviendas libres (ni de vecinos ni de nadie) de los bloques de pisos, para repartir al llegar.
-- En orden aleatorio; el registro de cada edificio se consulta al intentar quedársela.
function PropertyService.starterCandidates(rng: Random?): { { Building: InteriorService.Building, Floor: number, Letter: string } }
	local out = {}
	for _, building in InteriorService.all() do
		if building.Upper == "Piso" and InteriorService.isTower(building) and not building.Residence then
			for floor = 1, building.Floors - 1 do
				for _, u in Floors.units(building.Key, building.Kind, building.Upper, floor) do
					if u.Kind == "Piso" and not Properties.isNeighborHome(Properties.unitKey(building.Key, u.Id)) then
						table.insert(out, { Building = building, Floor = floor, Letter = u.Letter })
					end
				end
			end
		end
	end
	for i = #out, 2, -1 do
		local j = if rng then rng:NextInteger(1, i) else math.random(1, i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

-- Se queda con una vivienda libre como "Inicial" (sin pagar). false si otro se adelantó.
function PropertyService.claimStarter(player: Player, building: InteriorService.Building, floor: number, letter: string?): boolean
	if ownerOf(building, floor, letter) then
		return false
	end
	local owner: Owner = { UserId = player.UserId, Name = player.DisplayName, Price = 0, Since = os.time(), Kind = "Inicial" }
	if not claim(building.Key, slotOf(floor, letter), owner) then
		return false
	end
	local list = ownedList(player)
	table.insert(list, 1, {
		Key = building.Key, Floor = floor, Letter = letter or "A", Kind = unitKind(building, floor, letter) or "Piso",
		Title = titleOf(building, floor, letter), Price = 0, Contract = "Inicial", Id = PropertyService.idOf(building, floor, letter), Since = os.time(),
	})
	syncAttributes(player)
	InteriorService.reset(building, floor, letter)
	return true
end

-- Pierde la vivienda (fin del alquiler por impago): se libera y sale de su lista
function PropertyService.release(player: Player, building: InteriorService.Building, floor: number, letter: string?): boolean
	local list = ownedList(player)
	for i, entry in list do
		if entry.Key == building.Key and entry.Floor == floor and (entry.Letter or "A") == (letter or "A") then
			claim(building.Key, slotOf(floor, letter), nil, player.UserId)
			table.remove(list, i)
			syncAttributes(player)
			for _, other in Players:GetPlayers() do
				if other:GetAttribute("InteriorKey") == building.Id .. ":" .. slotOf(floor, letter) then
					InteriorService.leave(other)
				end
			end
			InteriorService.reset(building, floor, letter)
			return true
		end
	end
	return false
end

PropertyService.buy = buy
PropertyService.titleOf = titleOf

-- A cada personaje de la historia, una vivienda de vecinos (siempre la misma)
local function assignCastHomes()
	local units: { string } = {}
	for _, building in InteriorService.all() do
		if building.Kind == "Casa" then
			table.insert(units, Properties.unitKey(building.Key, 0))
		elseif building.Upper == "Piso" then
			for floor = 1, math.min(building.Floors - 1, 6) do
				for _, u in Floors.units(building.Key, building.Kind, building.Upper, floor) do
					table.insert(units, Properties.unitKey(building.Key, u.Id))
				end
			end
		end
	end
	local homes = {}
	for _, unit in units do
		if Properties.isNeighborHome(unit) then
			table.insert(homes, unit)
		end
	end
	table.sort(homes, function(a, b)
		return Properties.hash(a) < Properties.hash(b)
	end)
	for i, id in RESIDENTS do
		local unit = homes[i]
		if unit and Cast.People[id] then
			castHomes[unit] = id
		end
	end
end

function PropertyService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("Viviendas_v1")
	end)
	store = if ok then result else nil
	if not ok then
		warn("[Viviendas] Sin DataStore: las compras solo duran en este servidor.")
	end
	InteriorService.Hooks.Gate = gate
	InteriorService.Hooks.Decorate = decorate
	InteriorService.Hooks.Enter = onEnter
	InteriorService.Hooks.Labels = labels
	InteriorService.Hooks.Occupant = occupant
	assignCastHomes()
	DataService.onLoaded(function(player)
		syncAttributes(player)
	end)
end

return PropertyService
