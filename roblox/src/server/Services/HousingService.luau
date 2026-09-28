-- HousingService: la vida de las viviendas (encima de PropertyService, que lleva quién es el dueño).
--
--   * Vivienda al llegar: a cada jugador nuevo le toca un piso libre al azar de un bloque de pisos
--     (distrito, edificio, planta y puerta al azar entre los libres). Se queda con él para siempre
--     (DataStore, igual que al comprar: nunca a dos jugadores a la vez; si otro se adelanta, se
--     prueba con otro). No cuenta para el máximo de viviendas.
--   * Alquiler: se cobra cada día de juego mientras juegas. Si no llega el dinero, se apunta la deuda
--     y se avisa; al tercer impago seguido se pierde el contrato (las cosas no se pierden).
--   * Llaves: el dueño da y quita llaves (se guardan con la vivienda: valen aunque él no esté),
--     elige la privacidad (su grupo y los que tienen llave / solo los que tienen llave / cerrada) y
--     puede echar a las visitas.
--   * Timbre: si llamas a la casa de otro jugador sin llave, le llega el aviso con «Abrir» o «No
--     abrir». Si abre, la puerta queda abierta para ti un par de minutos.
--   * Vecinos con su vida (shared/Residents): si llamas y están trabajando o durmiendo, no abren.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Floors = require(ReplicatedStorage.Shared.Floors)
local Format = require(ReplicatedStorage.Shared.Format)
local Housing = require(ReplicatedStorage.Shared.Housing)
local Properties = require(ReplicatedStorage.Shared.Properties)
local Residents = require(ReplicatedStorage.Shared.Residents)
local DataService = require(script.Parent.DataService)
local InteriorService = require(script.Parent.InteriorService)
local PropertyService = require(script.Parent.PropertyService)

local HousingService = {}

HousingService.AutoAssign = true -- (las pruebas lo apagan para elegir ellas)
HousingService.StarterTries = 12
HousingService.BellSeconds = 30 -- lo que espera el timbre a que el dueño conteste

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent

type Bell = { Visitor: Player, Owner: Player, Building: InteriorService.Building, Floor: number, Letter: string?, Title: string, Until: number }
local bells: { [string]: Bell } = {}
local nextBell = 0

local function dayLength(): number
	return (Config.DayLengthMinutes or 20) * 60
end

local function unitOfEntry(entry: { [string]: any }): (InteriorService.Building?, number, string?)
	return InteriorService.byKey(entry.Key), entry.Floor, entry.Letter
end

---------------------------------------------------------------------
-- Vivienda al llegar
---------------------------------------------------------------------
function HousingService.assignStarter(player: Player, rng: Random?): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	data.Housing = data.Housing or {}
	if data.Housing.Assigned then
		return nil
	end
	-- (quien ya tiene una vivienda de antes no necesita otra)
	for _, entry in data.Properties or {} do
		if entry.Contract == "Inicial" then
			data.Housing.Assigned = true
			return entry
		end
	end
	local tries = 0
	for _, candidate in PropertyService.starterCandidates(rng) do
		if tries >= HousingService.StarterTries or not player.Parent then
			break
		end
		tries += 1
		if PropertyService.claimStarter(player, candidate.Building, candidate.Floor, candidate.Letter) then
			data.Housing.Assigned = true
			data.Housing.Home = data.Housing.Home or { Key = candidate.Building.Key, Floor = candidate.Floor, Letter = candidate.Letter }
			DataService.save(player)
			local sheet = PropertyService.sheetOf(candidate.Building, candidate.Floor, candidate.Letter)
			local title = PropertyService.titleOf(candidate.Building, candidate.Floor, candidate.Letter)
			Notify:FireClient(player, "Success", ("🏠 ¡Ya tienes casa en Valmar! %s%s. «Ir a casa» te lleva."):format(title, if sheet then (" (%s · %s)"):format(sheet.Id, Housing.describe(sheet)) else ""))
			return (data.Properties or {})[1]
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Alquiler
---------------------------------------------------------------------
-- Cobra lo que toque a un jugador (now: os.time(); se puede pasar en las pruebas)
function HousingService.collectRent(player: Player, now: number?)
	local data = DataService.get(player)
	if not data or not data.Properties then
		return
	end
	local t = now or os.time()
	for _, entry in table.clone(data.Properties) do
		if entry.Contract ~= "Alquiler" then
			continue
		end
		entry.RentDue = entry.RentDue or ((entry.Since or t) + dayLength())
		if t < entry.RentDue then
			continue
		end
		local rent = entry.Rent or 50
		local owed = rent + (entry.Debt or 0)
		local paid = (data.Money or 0) >= owed and DataService.spend(player, owed)
		local state, outcome = Housing.rentStep({ Debt = entry.Debt, Unpaid = entry.Unpaid }, rent, paid)
		entry.Debt, entry.Unpaid = state.Debt, state.Unpaid
		entry.RentDue += dayLength()
		if outcome == "Paid" then
			Notify:FireClient(player, "Info", ("🔑 Alquiler de %s pagado: %s."):format(entry.Title or "tu vivienda", Format.money(owed)))
		elseif outcome == "Warning" then
			Notify:FireClient(player, "Error", ("⚠️ No te llega para el alquiler de %s. Debes %s (aviso %d de %d)."):format(entry.Title or "tu vivienda", Format.money(state.Debt), state.Unpaid, Housing.MaxUnpaid))
		else
			local building, floor, letter = unitOfEntry(entry)
			if building then
				PropertyService.release(player, building, floor, letter)
			end
			data.Housing = data.Housing or {}
			data.Housing.Debt = (data.Housing.Debt or 0) + state.Debt
			Notify:FireClient(player, "Error", ("🔑 Has perdido el alquiler de %s tras %d impagos. Te quedan %s de deuda."):format(entry.Title or "la vivienda", Housing.MaxUnpaid, Format.money(state.Debt)))
		end
		DataService.save(player)
	end
end

---------------------------------------------------------------------
-- Llaves, privacidad y visitas
---------------------------------------------------------------------
local function ownsUnit(player: Player, building: InteriorService.Building, floor: number, letter: string?): boolean
	local owner = PropertyService.ownerOf(building, floor, letter)
	return owner ~= nil and owner.UserId == player.UserId
end

local function keysPanel(player: Player, building: InteriorService.Building, floor: number, letter: string?)
	local owner = PropertyService.ownerOf(building, floor, letter)
	if not owner or owner.UserId ~= player.UserId then
		return
	end
	local keys = {}
	for id, name in owner.Access or {} do
		table.insert(keys, { UserId = tonumber(id), Name = name })
	end
	local others, visitors = {}, {}
	local here = building.Id .. ":" .. Floors.unitId(floor, letter)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			table.insert(others, { UserId = other.UserId, Name = other.DisplayName })
			if other:GetAttribute("InteriorKey") == here then
				table.insert(visitors, { UserId = other.UserId, Name = other.DisplayName })
			end
		end
	end
	local sheet = PropertyService.sheetOf(building, floor, letter)
	Remote:FireClient(player, "Keys", {
		Key = building.Key, Floor = floor, Letter = letter or "A",
		Title = PropertyService.titleOf(building, floor, letter), Id = sheet and sheet.Id,
		Privacy = owner.Privacy or "Grupo", Keys = keys, Players = others, Visitors = visitors,
	})
end

local function editAccess(player: Player, key: string, floor: number, letter: string?, fn: (any) -> ()): boolean
	local building = InteriorService.byKey(key)
	if not building or not ownsUnit(player, building, floor, letter) then
		return false
	end
	local ok = PropertyService.editOwner(building, floor, letter, player.UserId, fn)
	keysPanel(player, building, floor, letter)
	return ok
end

function HousingService.giveKey(player: Player, key: string, floor: number, letter: string?, target: Player): boolean
	if target == player then
		return false
	end
	local full = false
	local ok = editAccess(player, key, floor, letter, function(owner)
		owner.Access = owner.Access or {}
		local n = 0
		for _ in owner.Access do
			n += 1
		end
		if n >= Housing.MaxKeys and not owner.Access[tostring(target.UserId)] then
			full = true
			return
		end
		owner.Access[tostring(target.UserId)] = target.DisplayName
	end)
	if ok and not full then
		Notify:FireClient(player, "Success", ("🔑 Has dado una llave a %s."):format(target.DisplayName))
		Notify:FireClient(target, "Success", ("🔑 %s te ha dado una llave de su casa."):format(player.DisplayName))
	elseif full then
		Notify:FireClient(player, "Error", ("Ya has repartido %d llaves (el máximo)."):format(Housing.MaxKeys))
	end
	return ok and not full
end

function HousingService.takeKey(player: Player, key: string, floor: number, letter: string?, userId: number): boolean
	local ok = editAccess(player, key, floor, letter, function(owner)
		if owner.Access then
			owner.Access[tostring(userId)] = nil
		end
	end)
	if ok then
		Notify:FireClient(player, "Info", "🔑 Llave retirada.")
	end
	return ok
end

HousingService.PrivacyModes = { Grupo = true, Llaves = true, Cerrada = true }

function HousingService.setPrivacy(player: Player, key: string, floor: number, letter: string?, mode: string): boolean
	if not HousingService.PrivacyModes[mode] then
		return false
	end
	return editAccess(player, key, floor, letter, function(owner)
		owner.Privacy = mode
	end)
end

-- Echa a una visita que está dentro de tu casa (vuelve al pasillo)
function HousingService.kick(player: Player, key: string, floor: number, letter: string?, target: Player): boolean
	local building = InteriorService.byKey(key)
	if not building or not ownsUnit(player, building, floor, letter) or target == player then
		return false
	end
	local here = building.Id .. ":" .. Floors.unitId(floor, letter)
	if target:GetAttribute("InteriorKey") ~= here then
		return false
	end
	InteriorService.leave(target)
	Notify:FireClient(target, "Info", ("🚪 %s te ha pedido que te vayas."):format(player.DisplayName))
	keysPanel(player, building, floor, letter)
	return true
end

---------------------------------------------------------------------
-- Timbre
---------------------------------------------------------------------
local function ring(visitor: Player, building: InteriorService.Building, floor: number, letter: string?): boolean
	local owner = PropertyService.ownerOf(building, floor, letter)
	if not owner then
		return false
	end
	local ownerPlayer = Players:GetPlayerByUserId(owner.UserId)
	local title = PropertyService.titleOf(building, floor, letter)
	if not ownerPlayer then
		Notify:FireClient(visitor, "Info", ("🔔 Ding, dong… Es la casa de %s. No hay nadie."):format(owner.Name))
		return true
	end
	-- (un timbre a la vez por visita y casa)
	for _, bell in bells do
		if bell.Visitor == visitor and bell.Owner == ownerPlayer and os.clock() < bell.Until then
			Notify:FireClient(visitor, "Info", "🔔 Ya has llamado. Espera a que te abran.")
			return true
		end
	end
	nextBell += 1
	local token = tostring(nextBell)
	bells[token] = { Visitor = visitor, Owner = ownerPlayer, Building = building, Floor = floor, Letter = letter, Title = title, Until = os.clock() + HousingService.BellSeconds }
	Remote:FireClient(ownerPlayer, "Doorbell", { Token = token, From = visitor.DisplayName, Title = title })
	Notify:FireClient(visitor, "Info", ("🔔 Ding, dong… Has llamado a casa de %s. Espera a que te abran."):format(owner.Name))
	task.delay(HousingService.BellSeconds, function()
		if bells[token] then
			bells[token] = nil
			if visitor.Parent then
				Notify:FireClient(visitor, "Info", "🔔 No abre nadie.")
			end
		end
	end)
	return true
end
HousingService.ring = ring

function HousingService.answer(owner: Player, token: string, open: boolean): boolean
	local bell = bells[token]
	if not bell or bell.Owner ~= owner then
		return false
	end
	bells[token] = nil
	if not bell.Visitor.Parent then
		return false
	end
	if open then
		PropertyService.grantTemp(bell.Building, bell.Floor, bell.Letter, bell.Visitor.UserId)
		Notify:FireClient(bell.Visitor, "Success", ("🚪 %s te abre la puerta. ¡Pasa!"):format(owner.DisplayName))
		-- (entra solo: como si le abrieran desde dentro)
		pcall(InteriorService.goToUnit, bell.Visitor, bell.Building, bell.Floor, bell.Letter)
	else
		Notify:FireClient(bell.Visitor, "Info", ("🚪 %s no puede abrirte ahora."):format(owner.DisplayName))
	end
	return true
end

---------------------------------------------------------------------
-- Vecinos con horario
---------------------------------------------------------------------
local function neighborAnswer(building: InteriorService.Building, unit: any, clock: number): (boolean, string?)
	local person = Residents.person(Properties.unitKey(building.Key, unit.Id))
	local home, text = Residents.knockText(person, clock)
	return home, text
end
HousingService.neighborAnswer = neighborAnswer

---------------------------------------------------------------------
function HousingService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Housing") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Housing"
		Remote.Parent = remotes
	end
	InteriorService.Hooks.Doorbell = ring
	InteriorService.Hooks.NeighborAnswer = neighborAnswer
	PropertyService.OnKeysPanel = keysPanel

	local last: { [Player]: number } = {}
	Remote.OnServerEvent:Connect(function(player, kind, a, b)
		if os.clock() - (last[player] or 0) < 0.25 then
			return
		end
		last[player] = os.clock()
		if kind == "Answer" and type(a) == "string" then
			HousingService.answer(player, a, b == true)
			return
		end
		-- El resto, sobre una vivienda suya: a = { Key, Floor, Letter }
		if type(a) ~= "table" or type(a.Key) ~= "string" or type(a.Floor) ~= "number" or a.Floor ~= a.Floor then
			return
		end
		local letter = if type(a.Letter) == "string" and #a.Letter <= 2 then a.Letter else nil
		local target = if type(b) == "number" then Players:GetPlayerByUserId(b) else nil
		if kind == "GiveKey" and target then
			HousingService.giveKey(player, a.Key, a.Floor, letter, target)
		elseif kind == "TakeKey" and type(b) == "number" then
			HousingService.takeKey(player, a.Key, a.Floor, letter, b)
		elseif kind == "Privacy" and type(b) == "string" then
			HousingService.setPrivacy(player, a.Key, a.Floor, letter, b)
		elseif kind == "Kick" and target then
			HousingService.kick(player, a.Key, a.Floor, letter, target)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
		for token, bell in bells do
			if bell.Visitor == player or bell.Owner == player then
				bells[token] = nil
			end
		end
	end)

	DataService.onLoaded(function(player, data)
		data.Housing = data.Housing or {}
		if HousingService.AutoAssign and not data.Housing.Assigned then
			task.spawn(HousingService.assignStarter, player)
		end
	end)
	-- Cobro del alquiler (cada día de juego, mientras juegas)
	task.spawn(function()
		while true do
			task.wait(20)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(HousingService.collectRent, player)
				if not ok then
					warn("[Viviendas] " .. tostring(err))
				end
			end
		end
	end)
end

return HousingService
