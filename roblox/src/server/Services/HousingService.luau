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
--   * Vida en el portal y en los pasillos: los vecinos suben a su casa y bajan de ella por la
--     escalera o en el ascensor de verdad (solo por plantas montadas).
--   * Encargos de los vecinos (shared/Errands): «Entrega en el 5ºB», «Busca a Carlos en su piso».

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Errands = require(ReplicatedStorage.Shared.Errands)
local Floors = require(ReplicatedStorage.Shared.Floors)
local Format = require(ReplicatedStorage.Shared.Format)
local Housing = require(ReplicatedStorage.Shared.Housing)
local Properties = require(ReplicatedStorage.Shared.Properties)
local Residents = require(ReplicatedStorage.Shared.Residents)
local DataService = require(script.Parent.DataService)
local InteriorService = require(script.Parent.InteriorService)
local PropertyService = require(script.Parent.PropertyService)
local Builder = require(script.Parent.Parent.World.Builder)

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
	-- Deuda de un alquiler que ya no tienes: se cobra poco a poco, con lo que tengas (antes se olvidaba)
	local old = data.Housing and data.Housing.Debt or 0
	if old > 0 and (data.Money or 0) > 0 then
		local pay = math.min(old, data.Money)
		if DataService.spend(player, pay) then
			data.Housing.Debt = old - pay
			Notify:FireClient(player, "Info", if data.Housing.Debt > 0
				then ("🔑 Pagas %s de la deuda del alquiler. Aún debes %s."):format(Format.money(pay), Format.money(data.Housing.Debt))
				else ("🔑 Has pagado toda la deuda del alquiler (%s)."):format(Format.money(pay)))
		end
	end
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
		-- Solo si sigue en la puerta (en ese rato se ha podido ir a otra planta, a la calle o a otra casa)
		if not InteriorService.atDoor(bell.Visitor, bell.Building, bell.Floor, bell.Letter) then
			Notify:FireClient(owner, "Info", ("🚪 %s ya no está en la puerta."):format(bell.Visitor.DisplayName))
			return true
		end
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
-- Vida en el portal: mientras hay alguien en la planta baja de un bloque, los vecinos entran y
-- salen, miran el buzón, esperan el ascensor (y se suben), bajan la basura o llega un repartidor.
-- Y los vecinos suben de verdad a su casa (por la escalera o en el ascensor de verdad) y bajan de
-- ella, pero solo por plantas montadas (±2 de algún jugador): si no, nadie los vería.
---------------------------------------------------------------------
local Npc = require(script.Parent.Parent.World.Npc)
local Tower = require(script.Parent.Parent.World.Tower)

HousingService.LobbyEvery = { 18, 40 } -- segundos entre escena y escena (al azar)
HousingService.LobbyLife = true -- (las pruebas la apagan para mandar ellas)
HousingService.MaxNpcs = 4 -- vecinos a la vez por edificio (móvil)
HousingService.SpawnClear = 5 -- ningún vecino aparece a menos de esto de un jugador
local lobbies: { [number]: { NextAt: number, Running: number } } = {}

local LINES = {
	Buzon = { "A ver qué hay hoy… facturas. Siempre facturas.", "¡Por fin ha llegado mi carta!", "Propaganda, propaganda… y más propaganda." },
	Sale = { "¡Buenos días! Me voy corriendo, que llego tarde.", "Hasta luego, vecino.", "Voy a por el pan, ¿necesitas algo?" },
	Basura = { "Bajo la basura, que ya huele.", "¿Hoy toca reciclaje o era mañana?" },
	Repartidor = { "¡Paquete para el %s! ¿Hay alguien?", "Traigo un pedido para el %s. Firme aquí, por favor." },
	Charla = { "¿Has visto que van a pintar el portal?", "El ascensor hace un ruido raro, ¿no?", "¡Qué calor hace hoy en la escalera!", "Mañana hay reunión de vecinos, no faltes." },
	Escalera = { "Uf, subo andando, que así hago ejercicio.", "El ascensor tarda mucho: por la escalera.", "Un escalón, otro escalón…" },
	Ascensor = { "¡Espere, espere, no cierre!", "Buenas. Voy a mi planta, gracias.", "A ver si hoy no se para entre plantas…" },
}

local function pick(list: { string }): string
	return list[math.random(1, #list)]
end

-- ¿Hay algún jugador a menos de `radius` studs (en planta, y a la misma altura más o menos)?
function HousingService.nearPlayer(at: Vector3, radius: number?): boolean
	local r0 = radius or HousingService.SpawnClear
	for _, other in Players:GetPlayers() do
		local r = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if r and r:IsA("BasePart") and (Vector3.new(r.Position.X, at.Y, r.Position.Z) - at).Magnitude < r0 and math.abs(r.Position.Y - at.Y) < 8 then
			return true
		end
	end
	return false
end
local taken = HousingService.nearPlayer

-- Los sitios de una planta montada de un bloque: puerta de la calle, ascensor, buzones, portero
local function floorSpots(inst: any, floor: number): { [string]: any }?
	local built = inst and inst.Tower and inst.Tower.Built[floor]
	if not built then
		return nil
	end
	local spots = {}
	for _, d in built.Model:GetDescendants() do
		if d:IsA("BasePart") then
			if d:HasTag("InteriorEntry") then
				spots.Door = d.Position
			elseif d:HasTag("InteriorElevator") then
				spots.Lift = d.Position
			elseif d.Name == "MailboxWall" then
				spots.Mail = d.Position
			elseif d.Name == "Intercom" then
				spots.Intercom = d.Position
			end
		end
	end
	if not spots.Lift then
		return nil
	end
	spots.Model = built.Model
	spots.Y = inst.Tower.Origin.Position.Y + floor * Floors.Height
	return spots
end

-- Los sitios del portal de un bloque (de su planta baja montada)
local function lobbySpots(building: InteriorService.Building): { [string]: any }?
	local spots = floorSpots(InteriorService.tower(building), 0)
	return if spots and spots.Door then spots else nil
end

local function feet(point: Vector3, floorY: number): Vector3
	return Vector3.new(point.X, floorY, point.Z)
end

-- Del edificio (coordenadas de la torre) al mundo
local function towerPoint(inst: any, p: Vector3): Vector3
	return (inst.Tower.Origin * CFrame.new(p)).Position
end

-- ¿Están montadas todas las plantas entre esas dos? (para ir por la escalera)
local function allBuilt(inst: any, a: number, b: number): boolean
	for f = math.min(a, b), math.max(a, b) do
		if not inst.Tower.Built[f] then
			return false
		end
	end
	return true
end

-- Delante de una puerta del pasillo (a la altura de los pies)
local function doorFeet(inst: any, floor: number, letter: string): Vector3?
	local cf = Tower.doorFront(inst.Tower.Plan, floor, letter)
	return if cf then towerPoint(inst, cf.Position - Vector3.new(0, 3, 0)) else nil
end

-- El rellano de una planta (a la altura de los pies)
local function landingFeet(inst: any, floor: number): Vector3
	return towerPoint(inst, Tower.landing(inst.Tower.Plan, floor).Position - Vector3.new(0, 3, 0))
end

-- Vecinos de verdad (con vecinos, no jugadores ni en venta) de las plantas montadas
local function neighborHomes(building: InteriorService.Building, inst: any): { { Floor: number, Letter: string, UnitKey: string } }
	local out = {}
	for floor in inst.Tower.Built do
		if floor >= 1 then
			for _, unit in Floors.units(building.Key, building.Kind, building.Upper, floor) do
				if unit.Kind == "Piso" and InteriorService.occupant(building, unit).Type == "Neighbor" then
					table.insert(out, { Floor = floor, Letter = unit.Letter, UnitKey = Properties.unitKey(building.Key, unit.Id) })
				end
			end
		end
	end
	table.sort(out, function(a, b)
		return a.UnitKey < b.UnitKey
	end)
	return out
end

-- Sube a otra planta por la escalera principal (andando por los escalones)
local function climb(npc: Model, inst: any, from: number, to: number): boolean
	if not allBuilt(inst, from, to) then
		return false
	end
	local route = {}
	for _, p in Tower.stairRoute(inst.Tower.Plan, from, to) do
		table.insert(route, towerPoint(inst, p))
	end
	pcall(Npc.say, npc, pick(LINES.Escalera), 3)
	Npc.walkTo(npc, route, 7)
	return npc.Parent ~= nil and allBuilt(inst, to, to)
end
HousingService.climb = climb

-- Espera al ascensor en esa planta, entra, lo manda a otra y viaja dentro (el servidor mueve la
-- cabina; el vecino va pegado al suelo de la cabina). Nunca con un jugador dentro de la cabina
-- (se lo llevaría) y solo a plantas montadas.
local function ride(npc: Model, inst: any, building: InteriorService.Building, from: number, to: number): boolean
	local lift = inst.Tower.Lift
	local spots = floorSpots(inst, from)
	if not lift or not spots or not inst.Tower.Built[to] or InteriorService.liftHasRiders(building) then
		return false
	end
	local floorY = spots.Y
	Npc.walkTo(npc, { feet(spots.Lift, floorY) })
	pcall(InteriorService.callLift, inst, from)
	local waited = 0
	while waited < 15 and npc.Parent and not (lift.Floor == from and lift.DoorsOpen and not lift.Busy) do
		waited += task.wait(0.25)
	end
	local cabin = lift.Cabin.Model:FindFirstChild("CabinFloor") :: BasePart?
	if not cabin or not npc.Parent or lift.Floor ~= from or not lift.DoorsOpen or InteriorService.liftHasRiders(building) or not inst.Tower.Built[to] then
		return false
	end
	pcall(Npc.say, npc, pick(LINES.Ascensor), 3)
	Npc.walkTo(npc, { feet(cabin.Position, floorY) + Vector3.new(0, 0, 0.8) })
	local root = npc.PrimaryPart
	if not root or not npc.Parent then
		return false
	end
	local offset = root.Position - cabin.Position
	pcall(InteriorService.callLift, inst, to)
	-- Va dentro mientras viaja (la cabina sube o baja por el hueco)
	local t0 = os.clock()
	while npc.Parent and os.clock() - t0 < 40 do
		root.CFrame = CFrame.new(cabin.Position + offset) * root.CFrame.Rotation
		if lift.Floor == to and not lift.Busy and lift.DoorsOpen then
			break
		end
		task.wait()
	end
	return npc.Parent ~= nil and lift.Floor == to and inst.Tower.Built[to] ~= nil
end
HousingService.ride = ride

-- Llega a su puerta y entra en su casa (la puerta se abre y se cierra)
local function goInside(npc: Model, inst: any, floor: number, letter: string)
	local at = doorFeet(inst, floor, letter)
	if not at or not inst.Tower.Built[floor] then
		return
	end
	Npc.walkTo(npc, { landingFeet(inst, floor), at })
	npc:SetAttribute("HomeReached", ("%d%s"):format(floor, letter))
	local ok, InteractService = pcall(function()
		return require(script.Parent.InteractService) :: any
	end)
	local built = inst.Tower.Built[floor]
	local door = built and built.Model:FindFirstChild("UnitDoor_" .. Floors.unitId(floor, letter))
	local panel = door and door:FindFirstChild("DoorPanel")
	if ok and InteractService and InteractService.swing and panel and panel:IsA("BasePart") then
		pcall(InteractService.swing, panel, true, 0.35)
		task.delay(2, function()
			if panel.Parent then
				pcall(InteractService.swing, panel, false, 0.4)
			end
		end)
	end
	task.wait(0.8)
end

-- De la planta `from` a la `to`: por la escalera o en el ascensor (lo que se pueda; si se puede
-- de las dos formas, al azar)
local function travel(npc: Model, inst: any, building: InteriorService.Building, from: number, to: number, how: string?): string?
	if from == to then
		return "Nada"
	end
	local canLift = inst.Tower.Lift ~= nil and inst.Tower.Built[to] ~= nil and not InteriorService.liftHasRiders(building)
	local canStairs = allBuilt(inst, from, to)
	local useLift = if how == "Ascensor" then canLift elseif how == "Escalera" then false else canLift and (not canStairs or math.random() < 0.5)
	if useLift and ride(npc, inst, building, from, to) then
		npc:SetAttribute("Travel", "Ascensor")
		return "Ascensor"
	end
	if canStairs and npc.Parent then
		-- (si el ascensor no ha venido, por la escalera desde donde esté)
		Npc.walkTo(npc, { landingFeet(inst, from) })
		if climb(npc, inst, from, to) then
			npc:SetAttribute("Travel", "Escalera")
			return "Escalera"
		end
	end
	return nil
end

local function running(building: InteriorService.Building): { NextAt: number, Running: number }
	local state = lobbies[building.Id] or { NextAt = os.clock() + 4, Running = 0 }
	lobbies[building.Id] = state
	return state
end

-- Crea el vecino (si no hay un jugador justo ahí ni demasiados vecinos) y le hace vivir su escena
local function spawnNeighbor(building: InteriorService.Building, name: string, parent: Instance, at: Vector3, kind: string, life: (Model) -> ()): Model?
	local state = running(building)
	if state.Running >= HousingService.MaxNpcs or taken(at) then
		return nil
	end
	local npc = Npc.create(name, parent, CFrame.new(at + Vector3.new(0, 3, 0)))
	npc:SetAttribute("LobbyNeighbor", kind)
	npc:SetAttribute("SpawnedAt", at)
	state.Running += 1
	task.spawn(function()
		local ok, err = pcall(life, npc)
		if not ok then
			warn("[Viviendas] portal: " .. tostring(err))
		end
		state.Running = math.max(0, state.Running - 1)
		if npc.Parent then
			npc:Destroy()
		end
	end)
	return npc
end

-- Una escena en el portal (kind: Llega, Sale, Buzon, Basura, Repartidor, Charla). Devuelve el vecino.
-- «Llega» y «Buzon»: si su casa está en una planta montada, sube a ella (escalera o ascensor) y entra.
function HousingService.lobbyScene(building: InteriorService.Building, kind: string?, how: string?): Model?
	local spots = lobbySpots(building)
	if not spots then
		return nil
	end
	local inst = InteriorService.tower(building) :: any
	local floorY = spots.Y
	local model = spots.Model :: any
	-- Un vecino de verdad del edificio (con su nombre): si puede ser, de una planta montada
	local homes = neighborHomes(building, inst)
	local home = if #homes > 0 then homes[math.random(1, #homes)] else nil
	local floor = if home then home.Floor else math.random(1, math.max(1, building.Floors - 1))
	local units = Floors.units(building.Key, building.Kind, building.Upper, floor)
	local unit = units[math.random(1, math.max(1, #units))]
	local person = Residents.person(if home then home.UnitKey else Properties.unitKey(building.Key, unit and unit.Id or tostring(floor)))
	local which = kind or ({ "Llega", "Sale", "Buzon", "Basura", "Repartidor", "Charla" })[math.random(1, 6)]
	local door, lift = feet(spots.Door, floorY), feet(spots.Lift, floorY)
	local mail = if spots.Mail then feet(spots.Mail, floorY) + Vector3.new(0, 0, -2.2) else nil
	local name = if which == "Repartidor" then "Repartidor" else person.Name
	local start = if which == "Sale" or which == "Basura" then lift else door
	-- Nunca aparece dentro de un jugador (se llega al portal justo por la puerta o el ascensor): si
	-- hay alguien ahí, sale por el otro sitio; si tampoco se puede, no hay escena
	if taken(start) then
		start = if start == door then lift else door
	end
	-- (a los buzones se va por debajo de la escalera, no a través del muro de en medio)
	local plan = inst.Tower.Plan
	local under = towerPoint(inst, Vector3.new(-plan.W / 2 + 2.3, 0, -5))
	local underBack = if mail then Vector3.new(under.X, floorY, mail.Z) else nil
	local landing = landingFeet(inst, 0)
	return spawnNeighbor(building, name, model, start, which, function(npc)
		local function say(text: string)
			pcall(Npc.say, npc, text, 4)
		end
		if which == "Llega" or which == "Buzon" then
			if mail and underBack then
				Npc.walkTo(npc, { landing, feet(under, floorY), underBack, mail })
				say(pick(LINES.Buzon))
				task.wait(3)
				Npc.walkTo(npc, { underBack, feet(under, floorY), landing })
			end
			-- A casa: sube de verdad a su planta (si está montada) y entra por su puerta
			if home and travel(npc, inst, building, 0, home.Floor, how) then
				goInside(npc, inst, home.Floor, home.Letter)
				return
			end
			Npc.walkTo(npc, { lift })
			-- Llama al ascensor y se sube cuando abre
			pcall(InteriorService.callLift, inst, 0)
			local waited = 0
			while waited < 12 and npc.Parent and not (inst.Tower.Lift and inst.Tower.Lift.Floor == 0 and inst.Tower.Lift.DoorsOpen) do
				waited += task.wait(0.5)
			end
			local cabin = inst.Tower.Lift and inst.Tower.Lift.Cabin.Model:FindFirstChild("CabinFloor")
			if cabin and npc.Parent then
				Npc.walkTo(npc, { feet(cabin.Position, floorY) })
				task.wait(1.5)
			end
		elseif which == "Sale" or which == "Basura" then
			if which == "Basura" then
				pcall(Npc.work, npc, "Tray")
			end
			say(pick(LINES[which]))
			Npc.walkTo(npc, { door })
		elseif which == "Repartidor" then
			pcall(Npc.work, npc, "Clipboard")
			local target = if spots.Intercom then feet(spots.Intercom, floorY) + Vector3.new(0, 0, 2) else lift
			Npc.walkTo(npc, { target })
			say((pick(LINES.Repartidor)):format(unit and unit.Label or "primero"))
			task.wait(5)
			Npc.walkTo(npc, { door })
		else -- Charla: dos vecinos junto a los buzones
			if taken(lift) then
				return
			end
			local other = Npc.create(Residents.person(Properties.unitKey(building.Key, "charla" .. floor)).Name, model, CFrame.new(lift + Vector3.new(0, 3, 0)))
			other:SetAttribute("LobbyNeighbor", "Charla")
			local meet = if underBack then feet(under, floorY) else (door + lift) / 2
			task.spawn(Npc.walkTo, other, { meet + Vector3.new(2, 0, 0) })
			Npc.walkTo(npc, { meet })
			for _ = 1, 3 do
				say(pick(LINES.Charla))
				task.wait(3.5)
			end
			task.spawn(Npc.walkTo, other, { lift })
			Npc.walkTo(npc, { door })
			task.delay(4, function()
				if other.Parent then
					other:Destroy()
				end
			end)
		end
	end)
end

-- Una escena en las plantas de arriba (con jugadores en ellas):
--   «Baja»: un vecino sale de su casa y baja (escalera o ascensor) a la calle o a la planta más
--   baja que esté montada. «Sube»: un vecino llega a su planta desde la planta montada más baja.
function HousingService.floorScene(building: InteriorService.Building, kind: string?, how: string?): Model?
	local inst = InteriorService.tower(building) :: any
	if not inst or not inst.Tower then
		return nil
	end
	local homes = neighborHomes(building, inst)
	if #homes == 0 then
		return nil
	end
	local lowest = math.huge
	for f in inst.Tower.Built do
		lowest = math.min(lowest, f)
	end
	-- (la planta más baja montada, sin huecos hasta cada casa)
	local which = kind or (if math.random() < 0.5 then "Baja" else "Sube")
	local candidates = {}
	for _, h in homes do
		if h.Floor > lowest then
			table.insert(candidates, h)
		end
	end
	if #candidates == 0 then
		return nil
	end
	local home = candidates[math.random(1, #candidates)]
	local person = Residents.person(home.UnitKey)
	local built = inst.Tower.Built[home.Floor]
	if which == "Baja" then
		local at = doorFeet(inst, home.Floor, home.Letter)
		if not at then
			return nil
		end
		return spawnNeighbor(building, person.Name, built.Model, at, "Baja", function(npc)
			pcall(Npc.say, npc, pick(LINES.Sale), 3)
			local target = if inst.Tower.Built[0] then 0 else lowest
			if travel(npc, inst, building, home.Floor, target, how) and target == 0 then
				local spots = floorSpots(inst, 0)
				if spots and spots.Door then
					Npc.walkTo(npc, { feet(spots.Door, spots.Y) })
				end
			end
		end)
	end
	-- Sube: aparece en el rellano de la planta más baja montada (como si viniera de abajo)
	local from = lowest
	local start = landingFeet(inst, from)
	local fromBuilt = inst.Tower.Built[from]
	return spawnNeighbor(building, person.Name, fromBuilt.Model, start, "Sube", function(npc)
		if travel(npc, inst, building, from, home.Floor, how) then
			goInside(npc, inst, home.Floor, home.Letter)
		end
	end)
end

local function stepLobbies()
	if not HousingService.LobbyLife then
		return
	end
	local active: { [number]: { [number]: boolean } } = {}
	for _, player in Players:GetPlayers() do
		local key = player:GetAttribute("InteriorKey")
		local id = type(key) == "string" and tonumber(string.match(key, "^(%d+):T$"))
		local at = player:GetAttribute("TowerFloor")
		if id and type(at) == "number" then
			active[id] = active[id] or {}
			active[id][at] = true
		end
	end
	for _, building in InteriorService.all() do
		local floors = active[building.Id]
		if not floors or building.Upper ~= "Piso" then
			continue
		end
		local state = running(building)
		if os.clock() >= state.NextAt then
			state.NextAt = os.clock() + math.random(HousingService.LobbyEvery[1], HousingService.LobbyEvery[2])
			if floors[0] then
				pcall(HousingService.lobbyScene, building)
			else
				pcall(HousingService.floorScene, building)
			end
		end
	end
end
HousingService.stepLobbies = stepLobbies

---------------------------------------------------------------------
-- Encargos de los vecinos (shared/Errands): de vez en cuando un vecino de tu edificio te llama a la
-- puerta de casa o te para en el portal y te pide un favor. «Entrega en el 5ºB»: recoges el
-- paquete en los buzones del portal y lo llevas a su puerta. «Busca a Carlos en su piso»: vas a su
-- puerta; si no está (trabajo, compra, durmiendo), vuelves más tarde. Los carteles («Recoger
-- paquete», «Entregar paquete», «Buscar a…») solo los ve quien tiene el encargo (OwnerUserId).
---------------------------------------------------------------------
type ActiveErrand = Errands.Errand & {
	Player: Player,
	Building: InteriorService.Building,
	HasPackage: boolean,
	Expires: number,
	Prompts: { [string]: ProximityPrompt },
}
local errands: { [Player]: ActiveErrand } = {}
local offers: { [Player]: { Token: string, Errand: Errands.Errand, Building: InteriorService.Building, Until: number } } = {}
local errandState: { [Player]: { LastAt: number?, Since: number?, Where: string? } } = {}
local nextOffer = 0

HousingService.errandClock = function(): number
	return os.clock()
end
local function errandNow(): number
	return HousingService.errandClock()
end

local function gameClock(): number
	return game:GetService("Lighting").ClockTime
end

-- Tu casa (la elegida o la primera) si está en un bloque de pisos: edificio, planta y letra
local function homeOf(player: Player): (InteriorService.Building?, number?, string?)
	local data = DataService.get(player)
	if not data then
		return nil, nil, nil
	end
	local chosen = data.Housing and data.Housing.Home
	local entry = chosen or (data.Properties or {})[1]
	if type(entry) ~= "table" or type(entry.Key) ~= "string" then
		return nil, nil, nil
	end
	local building = InteriorService.byKey(entry.Key)
	if not building or building.Upper ~= "Piso" or not InteriorService.isTower(building) then
		return nil, nil, nil
	end
	return building, entry.Floor, entry.Letter or "A"
end
HousingService.homeOf = homeOf

-- ¿Dónde está ahora respecto a su casa? "Casa" (dentro), "Portal" (planta baja de su edificio) o nil
local function errandSpot(player: Player): (string?, InteriorService.Building?)
	local building, floor, letter = homeOf(player)
	if not building or not floor then
		return nil, nil
	end
	local key = player:GetAttribute("InteriorKey")
	if key == building.Id .. ":" .. Floors.unitId(floor, letter) then
		return "Casa", building
	elseif key == building.Id .. ":T" and player:GetAttribute("TowerFloor") == 0 then
		return "Portal", building
	end
	return nil, nil
end
HousingService.errandSpot = errandSpot

-- Las viviendas de vecinos del edificio (las que pueden pedir o recibir un encargo)
local function errandHomes(building: InteriorService.Building): { Errands.Home }
	local out = {}
	for floor = 1, building.Floors - 1 do
		for _, unit in Floors.units(building.Key, building.Kind, building.Upper, floor) do
			if unit.Kind == "Piso" and InteriorService.occupant(building, unit).Type == "Neighbor" then
				table.insert(out, {
					Floor = floor, Letter = unit.Letter, Label = unit.Label,
					UnitKey = Properties.unitKey(building.Key, unit.Id), Id = PropertyService.idOf(building, floor, unit.Letter),
				})
			end
		end
	end
	return out
end

local function sendErrand(player: Player, errand: ActiveErrand?)
	if not Remote then
		return
	end
	if errand then
		Remote:FireClient(player, "Errand", { Title = Errands.title(errand), Goal = Errands.goalText(errand, errand.HasPackage), Id = errand.To.Id })
	else
		Remote:FireClient(player, "Errand", { Done = true })
	end
end

local function clearPrompts(errand: ActiveErrand)
	for _, prompt in errand.Prompts do
		if prompt.Parent then
			prompt:Destroy()
		end
	end
	table.clear(errand.Prompts)
end

-- Termina el encargo (bien o mal)
local function endErrand(player: Player, why: string?)
	local errand = errands[player]
	if not errand then
		return
	end
	errands[player] = nil
	clearPrompts(errand)
	errandState[player] = errandState[player] or {}
	errandState[player].LastAt = errandNow()
	if why and player.Parent then
		Notify:FireClient(player, "Info", why)
	end
	if player.Parent then
		sendErrand(player, nil)
	end
end
HousingService.endErrand = endErrand

local function rewardErrand(player: Player, errand: ActiveErrand)
	local reward = errand.Reward
	DataService.addMoney(player, reward.Money, true)
	local ok, Progression = pcall(function()
		return require(script.Parent.ProgressionService) :: any
	end)
	if ok and Progression and Progression.addXp then
		pcall(Progression.addXp, player, reward.Xp, "Encargo")
	end
	errands[player] = nil
	clearPrompts(errand)
	errandState[player] = errandState[player] or {}
	errandState[player].LastAt = errandNow()
	Notify:FireClient(player, "Success", ("✅ Encargo hecho: %s. %s de %s y +%d de experiencia."):format(Errands.title(errand), Format.money(reward.Money), errand.From.Name, reward.Xp))
	sendErrand(player, nil)
end

local attachErrand -- (se define más abajo)

-- Al usar un cartel del encargo
local function onErrandPrompt(player: Player, what: string)
	local errand = errands[player]
	if not errand then
		return
	end
	if what == "Mail" then
		if errand.Kind ~= "Entrega" or errand.HasPackage then
			return
		end
		errand.HasPackage = true
		local mail = errand.Prompts.Mail
		if mail and mail.Parent then
			mail:Destroy()
		end
		errand.Prompts.Mail = nil
		Notify:FireClient(player, "Success", Errands.goalText(errand, true))
		sendErrand(player, errand)
		attachErrand(errand)
	elseif what == "Door" then
		if errand.Kind == "Entrega" then
			if not errand.HasPackage then
				Notify:FireClient(player, "Info", "📦 Primero recoge el paquete en los buzones del portal.")
				return
			end
			Notify:FireClient(player, "Info", Errands.deliverText(errand, gameClock()))
			rewardErrand(player, errand)
		else
			local found, text = Errands.visit(errand, gameClock())
			Notify:FireClient(player, if found then "Success" else "Info", text)
			if found then
				rewardErrand(player, errand)
			end
		end
	end
end
HousingService.onErrandPrompt = onErrandPrompt

-- Pone los carteles del encargo en las plantas montadas (buzones del portal y la puerta del vecino)
attachErrand = function(errand: ActiveErrand)
	local inst = InteriorService.tower(errand.Building)
	if not inst or not inst.Tower then
		return
	end
	local player = errand.Player
	local function add(key: string, part: Instance, action: string, object: string)
		local prompt = errand.Prompts[key]
		if prompt and prompt.Parent == part then
			return
		end
		if prompt and prompt.Parent then
			prompt:Destroy()
		end
		local new = Builder.prompt(part, action, object, 0.3)
		new.Name = "ErrandPrompt"
		new.MaxActivationDistance = 7
		new.KeyboardKeyCode = Enum.KeyCode.F
		new:SetAttribute("OwnerUserId", player.UserId) -- (solo lo ve quien tiene el encargo: JobPrompts)
		new:SetAttribute("NoGesture", true)
		new.Triggered:Connect(function(who)
			if who == player then
				onErrandPrompt(player, key)
			end
		end)
		errand.Prompts[key] = new
	end
	-- Buzones del portal (si no hay buzones, el portero automático)
	local lobby = inst.Tower.Built[0]
	if errand.Kind == "Entrega" and not errand.HasPackage and lobby then
		local box = lobby.Model:FindFirstChild("MailboxWall", true) or lobby.Model:FindFirstChild("Intercom", true)
		if box then
			add("Mail", box, "Recoger paquete", ("📦 Buzones · paquete para el %s"):format(errand.To.Label))
		end
	end
	local target = inst.Tower.Built[errand.To.Floor]
	if target then
		local door = target.Model:FindFirstChild("UnitDoor_" .. Floors.unitId(errand.To.Floor, errand.To.Letter))
		local panel = door and door:FindFirstChild("DoorPanel")
		if panel then
			if errand.Kind == "Entrega" then
				add("Door", panel, "Entregar paquete", ("📦 %s · %s"):format(errand.To.Label, errand.To.Name))
			else
				add("Door", panel, ("Buscar a %s"):format(Errands.firstName(errand.To.Name)), ("🚪 %s · encargo"):format(errand.To.Label))
			end
		end
	end
end

-- Un vecino te pide un favor (via: "Casa" = te llama a la puerta, "Portal" = te para en el portal).
-- kind: forzar el tipo (Entrega o Visita). Devuelve la oferta (o nil si no hay a quién).
function HousingService.offerErrand(player: Player, building: InteriorService.Building, kind: string?, via: string?)
	if errands[player] or offers[player] then
		return nil
	end
	local errand = Errands.pick(errandHomes(building), { math.random(), math.random(), math.random() }, kind)
	if not errand then
		return nil
	end
	nextOffer += 1
	local token = "e" .. nextOffer
	local offer = { Token = token, Errand = errand, Building = building, Until = errandNow() + Errands.OfferSeconds }
	offers[player] = offer
	errandState[player] = errandState[player] or {}
	errandState[player].LastAt = errandNow()
	local how = if via == "Casa" then ("🔔 Llaman a tu puerta: es %s, del %s."):format(errand.From.Name, errand.From.Label) else ("👋 %s, del %s, te para en el portal."):format(errand.From.Name, errand.From.Label)
	Notify:FireClient(player, "Info", how)
	Remote:FireClient(player, "ErrandOffer", {
		Token = token, From = errand.From.Name, Title = Errands.title(errand), Text = Errands.offerText(errand),
		Money = errand.Reward.Money, Xp = errand.Reward.Xp,
	})
	return offer
end

-- Aceptar o no el encargo que te han ofrecido
function HousingService.answerErrand(player: Player, token: string, accept: boolean): boolean
	local offer = offers[player]
	if not offer or offer.Token ~= token then
		return false
	end
	offers[player] = nil
	if not accept or errandNow() > offer.Until then
		Notify:FireClient(player, "Info", ("🙂 %s: «Vale, no pasa nada. ¡Otro día!»"):format(Errands.firstName(offer.Errand.From.Name)))
		return false
	end
	local errand = offer.Errand :: any
	errand.Player = player
	errand.Building = offer.Building
	errand.HasPackage = false
	errand.Expires = errandNow() + Errands.Expire
	errand.Prompts = {}
	errands[player] = errand
	Notify:FireClient(player, "Success", ("📋 %s. %s"):format(Errands.title(errand), Errands.goalText(errand, false)))
	sendErrand(player, errand)
	attachErrand(errand)
	return true
end

function HousingService.errandOf(player: Player): ActiveErrand?
	return errands[player]
end

-- Cada rato: ofrecer encargos (solo en tu casa o en tu portal, y no a cada rato) y caducar los viejos
function HousingService.stepErrands(now: number?)
	local t = now or errandNow()
	for player, offer in offers do
		if t > offer.Until then
			offers[player] = nil
		end
	end
	for player, errand in errands do
		if t > errand.Expires then
			endErrand(player, ("⌛ Se acabó el tiempo del encargo: %s."):format(Errands.title(errand)))
		end
	end
	for _, player in Players:GetPlayers() do
		local where, building = errandSpot(player)
		local state = errandState[player] or {}
		errandState[player] = state
		if where ~= state.Where then
			state.Where = where
			state.Since = if where then t else nil
		end
		if where and building and Errands.shouldOffer({ Active = errands[player] ~= nil or offers[player] ~= nil, LastAt = state.LastAt, Since = state.Since }, t, math.random()) then
			HousingService.offerErrand(player, building, nil, where)
		end
	end
end

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
	-- Encargos: sus carteles vuelven a salir cada vez que se monta la planta
	InteriorService.onBuilt(function(inst)
		if inst.Unit == "T" then
			for _, errand in errands do
				if errand.Building == inst.Building then
					attachErrand(errand)
				end
			end
		end
	end)

	local last: { [Player]: number } = {}
	Remote.OnServerEvent:Connect(function(player, kind, a, b)
		if os.clock() - (last[player] or 0) < 0.25 then
			return
		end
		last[player] = os.clock()
		if kind == "Answer" and type(a) == "string" then
			HousingService.answer(player, a, b == true)
			return
		elseif kind == "ErrandAnswer" and type(a) == "string" then
			HousingService.answerErrand(player, a, b == true)
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
		local errand = errands[player]
		if errand then
			clearPrompts(errand)
		end
		errands[player], offers[player], errandState[player] = nil, nil, nil
		for token, bell in bells do
			if bell.Visitor == player or bell.Owner == player then
				bells[token] = nil
			end
		end
	end)

	DataService.onLoaded(function(player, data)
		data.Housing = data.Housing or {}
		-- El alquiler solo corre mientras juegas: se corre el próximo cobro el tiempo que estuvo fuera
		-- y, como mucho, queda UN pago pendiente ahora (antes se cobraban de golpe todos los días que
		-- estuvo desconectado y en un minuto perdía la casa). Sirve también para partidas viejas sin LastOnline.
		local away = if DataService.offlineSeconds then DataService.offlineSeconds(player) else 0
		local now = os.time()
		for _, entry in (if type(data.Properties) == "table" then data.Properties else {}) do
			if type(entry) == "table" and entry.Contract == "Alquiler" and type(entry.RentDue) == "number" then
				entry.RentDue = math.max(entry.RentDue + away, now)
			end
		end
		if HousingService.AutoAssign and not data.Housing.Assigned then
			task.spawn(HousingService.assignStarter, player)
		end
	end)
	-- Vida en los portales (solo donde hay alguien)
	task.spawn(function()
		while true do
			task.wait(3)
			pcall(stepLobbies)
			pcall(HousingService.stepErrands)
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
