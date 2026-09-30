-- BoatService: barcos propios y el PUERTO DEPORTIVO (costa oeste, Town.Marina).
--
-- Cómo lo usa un jugador:
--   * En el muelle del puerto deportivo está la oficina «⚓ Barcos» (tag BoatMarina). Su cartel
--     «Barcos» abre un menú (DialogueService, el mismo de las conversaciones: va igual en PC, móvil
--     y mando) con tus barcos: «Sacar…», «Guardar…» y «Comprar lancha».
--   * Al sacarlo, el barco aparece en un amarre libre del pantalán de barcos propios (tag BoatSlip,
--     a la altura del agua y mirando al mar) y te sube al timón. Si todos los amarres están ocupados
--     (u otra cosa estorba), no sale.
--   * Se pilota como el coche (Controllers/Driving): flota, se mece y solo navega por el mar.
--     Llevas pasajeros («Subir a bordo»). Al bajarte junto a un pantalán sales a él; en alta mar
--     te quedas en cubierta y el barco queda fondeado («Pilotar» para seguir). Solo lo pilotas tú.
--   * Un barco en el agua a la vez. Para sacar otro, guarda el que tienes. El barco se retira solo
--     al guardarlo, al salir del juego, o si lleva IDLE_RETURN segundos sin nadie a bordo con su
--     dueño lejos (vuelve al puerto deportivo; sigue siendo tuyo).
--
-- Cómo se consiguen: la lancha se compra en el puerto deportivo (Boats.Info.Lancha.Price); la
-- «Gaviota» es la recompensa premium del nivel 35 del pase de temporada (BattlePassRewardService la
-- entrega con BoatService.grant). El modo pruebas («Todos los vehículos») da todos.
--
-- Datos guardados: data.Boats = { Lancha = true, Gaviota = true } (DataService.DEFAULT_DATA). Los
-- barcos del pase también se recuperan de data.Cosmetics.Owned (así siguen siendo tuyos después de
-- «Vida nueva», igual que todo lo del pase). Atributo para la interfaz: OwnedBoats = "Gaviota,Lancha".
-- Los barcos se conducen con VehicleService (VehicleService.launchAt): mismo asiento, mismos
-- pasajeros, mismo «Bajarse» y la misma vigilancia contra saltos imposibles.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Boats = require(ReplicatedStorage.Shared.Boats)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local DataService = require(script.Parent.DataService)
local VehicleService = require(script.Parent.VehicleService)
local TesterService = require(script.Parent.TesterService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local BoatService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

BoatService.MarinaRange = 40 -- a qué distancia de la oficina se puede sacar o guardar un barco
BoatService.SlipClearance = 9 -- un amarre está ocupado si hay un barco a menos de esto de su centro
BoatService.IdleReturn = 600 -- segundos sin nadie a bordo (y el dueño lejos) hasta que vuelve al puerto
BoatService.IdleNear = 300 -- «lejos» = a más de esto

-- Color de tu lancha (siempre el mismo para ti; la «Gaviota» es blanca)
local LANCHA_COLORS = {
	Color3.fromRGB(30, 90, 170), Color3.fromRGB(200, 50, 50), Color3.fromRGB(20, 140, 140), Color3.fromRGB(240, 170, 40),
}

type Afloat = { Model: Model, Kind: string, Since: number }
local afloat: { [Player]: Afloat } = {} -- el barco que tiene cada uno en el agua
local offices: { BasePart } = {}
local slips: { BasePart } = {}

local function service(name: string): any
	local ok, result = pcall(function()
		return require(script.Parent[name])
	end)
	return if ok then result else nil
end

local function nameOf(kind: string): string
	local vehicle = Gameplay.Vehicles[kind]
	return if vehicle then vehicle.Name else kind
end

local function iconOf(kind: string): string
	local vehicle = Gameplay.Vehicles[kind]
	return if vehicle then vehicle.Icon else "🚤"
end

-- Barco que da una recompensa del pase: su campo Boat o, si no, su Kind
local function boatOfReward(def: { [string]: any }?): string?
	if type(def) ~= "table" then
		return nil
	end
	local kind = def.Boat or def.Kind
	return if Boats.isBoat(kind) then kind else nil
end

-- Datos: data.Boats (y los barcos del pase que ya son tuyos, por si se perdieron con «Vida nueva»)
local function ensure(data: { [string]: any })
	if type(data.Boats) ~= "table" then
		data.Boats = {}
	end
	local cosmetics = data.Cosmetics
	if type(cosmetics) == "table" and type(cosmetics.Owned) == "table" then
		local ok, Catalog = pcall(function()
			return require(ReplicatedStorage.Shared.BattlePass.Catalog)
		end)
		for id, info in cosmetics.Owned do
			if type(info) == "table" and info.Type == "Boat" then
				local kind = boatOfReward(ok and Catalog.get(id) or nil)
				if kind then
					data.Boats[kind] = true
				end
			end
		end
	end
end

-- Tus barcos, en el orden del puerto deportivo
function BoatService.list(player: Player): { string }
	local data = DataService.get(player)
	local list = {}
	if not data then
		return list
	end
	ensure(data)
	for _, kind in Boats.Kinds do
		if data.Boats[kind] then
			table.insert(list, kind)
		end
	end
	return list
end

function BoatService.owns(player: Player, kind: string): boolean
	local data = DataService.get(player)
	if not data or not Boats.isBoat(kind) then
		return false
	end
	ensure(data)
	return data.Boats[kind] == true
end

-- El cliente lee OwnedBoats (y BoatOut: el barco que tienes en el agua)
function BoatService.sync(player: Player)
	if not DataService.get(player) then
		return
	end
	player:SetAttribute("OwnedBoats", table.concat(BoatService.list(player), ","))
	local out = afloat[player]
	player:SetAttribute("BoatOut", if out and out.Model.Parent then out.Kind else nil)
end

-- Da un barco (pase de temporada, modo pruebas). kind = tipo de barco (o el Kind de la recompensa;
-- def.Boat manda). Devuelve true si es tuyo (también si ya lo tenías) y false si no existe.
function BoatService.grant(player: Player, kind: any, def: { [string]: any }?): boolean
	local boat = boatOfReward(def) or (if Boats.isBoat(kind) then kind else nil)
	local data = DataService.get(player)
	if not boat or not data then
		return false
	end
	ensure(data)
	local new = not data.Boats[boat]
	data.Boats[boat] = true
	BoatService.sync(player)
	if new and player.Parent then
		Notify:FireClient(player, "Success", ("%s ¡%s es tuya! Sácala en el puerto deportivo (costa oeste)."):format(iconOf(boat), nameOf(boat)))
	end
	return true
end

-- Modo pruebas: todos los barcos. Devuelve cuántos nuevos.
function BoatService.grantAll(player: Player): number
	local data = DataService.get(player)
	if not data then
		return 0
	end
	ensure(data)
	local given = 0
	for _, kind in Boats.Kinds do
		if not data.Boats[kind] then
			data.Boats[kind] = true
			given += 1
		end
	end
	BoatService.sync(player)
	return given
end

-- ¿Está cerca de la oficina del puerto deportivo?
local function atMarina(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	for _, office in offices do
		if office.Parent and (office.Position - root.Position).Magnitude <= BoatService.MarinaRange then
			return true
		end
	end
	return false
end
BoatService.atMarina = atMarina

-- Comprar un barco en el puerto deportivo
function BoatService.buy(player: Player, kind: string): (boolean, string?)
	local info = Boats.Info[kind]
	local vehicle = Gameplay.Vehicles[kind]
	local data = DataService.get(player)
	if not info or not vehicle or not data or (info.Price or 0) <= 0 then
		return false, "NotForSale"
	end
	ensure(data)
	if data.Boats[kind] then
		Notify:FireClient(player, "Info", "Ya tienes " .. vehicle.Name .. ".")
		return false, "Owned"
	end
	if not atMarina(player) then
		return false, "Far"
	end
	if not (Stages.allows(player:GetAttribute("LifeStage"), "Ride", { Ride = info.Stage }) or TesterService.bypass(player)) then
		Notify:FireClient(player, "Error", "Tienes que ser mayor de edad para comprar un barco.")
		return false, "Stage"
	end
	if not DataService.spend(player, info.Price) then
		Notify:FireClient(player, "Error", "No tienes suficiente dinero (" .. Format.money(info.Price) .. ").")
		return false, "Money"
	end
	data.Boats[kind] = true
	BoatService.sync(player)
	Notify:FireClient(player, "Success", ("¡%s %s es tuya!"):format(vehicle.Icon, vehicle.Name))
	StoryEvents.emit(player, "VehicleBought", { Vehicle = kind })
	return true
end

-- ¿Está libre este amarre? Ningún barco en el agua cerca y nada sólido donde irá el casco
local function slipFree(slip: BasePart, kind: string, ignore: Model?): boolean
	for _, entry in afloat do
		local chassis = entry.Model.Parent and entry.Model.PrimaryPart
		if entry.Model ~= ignore and chassis then
			local d = Vector3.new(chassis.Position.X - slip.Position.X, 0, chassis.Position.Z - slip.Position.Z)
			if d.Magnitude < BoatService.SlipClearance then
				return false
			end
		end
	end
	local size = Gameplay.Vehicles[kind] and require(script.Parent.Parent.World.Kit.Rides).Spec[kind].Size or Vector3.new(7, 1, 20)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = { workspace.Terrain, slip }
	if ignore then
		table.insert(exclude, ignore)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(exclude, player.Character) -- (las personas se apartan: el amarre no es suyo)
		end
	end
	overlap.FilterDescendantsInstances = exclude
	overlap.RespectCanCollide = true
	overlap.MaxParts = 1
	local ok, parts = pcall(function()
		return workspace:GetPartBoundsInBox(slip.CFrame * CFrame.new(0, 1.5, 0), Vector3.new(size.X, 3, size.Z), overlap)
	end)
	return not ok or #parts == 0 -- (si la consulta falla, no se impide sacarlo)
end

-- El primer amarre libre (en orden), o nil
function BoatService.freeSlip(kind: string): BasePart?
	for _, slip in slips do
		if slip.Parent and slipFree(slip, kind, nil) then
			return slip
		end
	end
	return nil
end

-- Retira el barco que tiene en el agua (con quien vaya a bordo: cada uno se baja por su lado)
local function removeBoat(player: Player, reason: string?)
	local entry = afloat[player]
	if not entry then
		return false
	end
	afloat[player] = nil
	local model = entry.Model
	if model.Parent then
		-- Si lo lleva él, primero se baja (al pantalán si está al lado)
		if VehicleService.rideModel(player) == model then
			VehicleService.dismount(player, true)
		end
		VehicleService.emptyPassengers(model)
		pcall(function()
			model:Destroy()
		end)
	end
	if player.Parent then
		BoatService.sync(player)
		if reason then
			Notify:FireClient(player, "Info", reason)
		end
	end
	return true
end

-- Nombre en la popa (la «Gaviota»): «GAVIOTA» y el nombre de su dueño
local function paintName(player: Player, model: Model)
	local plate = model:FindFirstChild("NamePlate")
	if not plate or not plate:IsA("BasePart") then
		return
	end
	for _, child in plate:GetChildren() do
		if child:IsA("SurfaceGui") then
			child:Destroy()
		end
	end
	local Builder = require(script.Parent.Parent.World.Builder)
	Builder.sign(plate, "GAVIOTA · " .. string.upper(player.DisplayName), Enum.NormalId.Back, Color3.fromRGB(214, 172, 64))
end

-- Saca un barco tuyo en un amarre libre y te sube al timón. Devuelve (ok, motivo):
--   "NotOwned" · "Far" (lejos de la oficina) · "Busy" (no puede ahora) · "Out" (ya tiene uno en el
--   agua) · "Full" (amarres ocupados) · "Failed"
function BoatService.launch(player: Player, kind: string): (boolean, string?)
	if not BoatService.owns(player, kind) then
		Notify:FireClient(player, "Error", "Ese barco no es tuyo.")
		return false, "NotOwned"
	end
	if not atMarina(player) then
		Notify:FireClient(player, "Error", "Los barcos se sacan en el puerto deportivo (costa oeste).")
		return false, "Far"
	end
	local out = afloat[player]
	if out and out.Model.Parent then
		Notify:FireClient(player, "Error", ("Ya tienes %s en el agua. Guárdala antes de sacar otro barco."):format(nameOf(out.Kind)))
		return false, "Out"
	end
	afloat[player] = nil
	if not VehicleService.canSpawn(player) or not VehicleService.spawnAllowed(player) then
		return false, "Busy"
	end
	local slip = BoatService.freeSlip(kind)
	if not slip then
		Notify:FireClient(player, "Error", "Todos los amarres están ocupados. Prueba dentro de un momento.")
		return false, "Full"
	end
	local color = if kind == "Lancha" then LANCHA_COLORS[player.UserId % #LANCHA_COLORS + 1] else nil
	local model = VehicleService.launchAt(player, kind, slip.CFrame, {
		Color = color,
		Decorate = function(m: Model)
			paintName(player, m)
		end,
	})
	if not model then
		return false, "Failed"
	end
	VehicleService.spawnDone(player)
	model:SetAttribute("Boat", true)
	local entry: Afloat = { Model = model, Kind = kind, Since = os.clock() }
	afloat[player] = entry
	model.Destroying:Connect(function()
		if afloat[player] == entry then
			afloat[player] = nil
			if player.Parent then
				BoatService.sync(player)
			end
		end
	end)
	BoatService.sync(player)
	Notify:FireClient(player, "Success", ("%s ¡A navegar! Acelera y gira como en el coche. Para bajarte, salta o pulsa «Bajarse»."):format(iconOf(kind)))
	StoryEvents.emit(player, "BoatLaunched", { Boat = kind })
	return true
end

-- Guarda tu barco (vuelve al puerto deportivo esté donde esté)
function BoatService.store(player: Player): (boolean, string?)
	local out = afloat[player]
	if not out or not out.Model.Parent then
		afloat[player] = nil
		Notify:FireClient(player, "Info", "No tienes ningún barco en el agua.")
		return false, "None"
	end
	if not atMarina(player) then
		Notify:FireClient(player, "Error", "Tu barco se guarda desde la oficina del puerto deportivo.")
		return false, "Far"
	end
	local name = nameOf(out.Kind)
	removeBoat(player, nil)
	Notify:FireClient(player, "Success", ("⚓ %s guardada en el puerto deportivo."):format(name))
	return true
end

-- El barco que tiene en el agua (o nil)
function BoatService.afloat(player: Player): Model?
	local entry = afloat[player]
	return if entry and entry.Model.Parent then entry.Model else nil
end

---------------------------------------------------------------------
-- Menú de la oficina (DialogueService: pregunta con opciones)
---------------------------------------------------------------------

-- Las opciones del menú para este jugador: { { T = texto, Do = "Launch"|"Store"|"Buy"|"Close", Kind? } }
function BoatService.menu(player: Player): { { [string]: any } }
	local options = {}
	local out = BoatService.afloat(player)
	if out then
		local kind = afloat[player].Kind
		table.insert(options, { T = ("⚓ Guardar %s"):format(nameOf(kind)), Do = "Store" })
	end
	for _, kind in BoatService.list(player) do
		if not out then
			table.insert(options, { T = ("%s Sacar %s"):format(iconOf(kind), nameOf(kind)), Do = "Launch", Kind = kind })
		end
	end
	for _, kind in Boats.Kinds do
		local info = Boats.Info[kind]
		if (info.Price or 0) > 0 and not BoatService.owns(player, kind) then
			table.insert(options, { T = ("💶 Comprar %s (%s)"):format(string.lower(nameOf(kind)), Format.money(info.Price)), Do = "Buy", Kind = kind })
		end
	end
	table.insert(options, { T = "Nada, gracias", Do = "Close" })
	return options
end

-- Hace lo elegido en el menú
function BoatService.choose(player: Player, option: { [string]: any }?)
	if not option then
		return
	end
	if option.Do == "Launch" and type(option.Kind) == "string" then
		BoatService.launch(player, option.Kind)
	elseif option.Do == "Store" then
		BoatService.store(player)
	elseif option.Do == "Buy" and type(option.Kind) == "string" then
		if BoatService.buy(player, option.Kind) then
			BoatService.openMenu(player) -- (y ya puede sacarla)
		end
	end
end

function BoatService.openMenu(player: Player)
	local options = BoatService.menu(player)
	local owned = BoatService.list(player)
	local intro = if #owned == 0
		then "⚓ Puerto deportivo de Valmar. Aún no tienes barco: aquí se compran lanchas, y la «Gaviota» llega con el pase de temporada."
		else "⚓ Puerto deportivo de Valmar. Tus barcos salen del pantalán de amarres, justo aquí al lado."
	local DialogueService = service("DialogueService")
	local chosen: { [string]: any }? = nil
	local lines = { { S = "Narrador", T = intro }, { Ask = "¿Qué quieres hacer?", Options = {} } }
	for _, option in options do
		table.insert(lines[2].Options, { T = option.T, Effects = { BoatMenu = option } })
	end
	local context = {
		apply = function(effects: { [string]: any }?)
			if effects and effects.BoatMenu then
				chosen = effects.BoatMenu
			end
		end,
	}
	local started = DialogueService and DialogueService.play(player, { Lines = lines }, context, function()
		BoatService.choose(player, chosen)
	end)
	if not started then
		Notify:FireClient(player, "Info", "Termina lo que estás haciendo y vuelve a la oficina.")
	end
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------

local function setupOffice(part: Instance)
	if not part:IsA("BasePart") or table.find(offices, part) then
		return
	end
	table.insert(offices, part)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BoatPrompt"
	prompt.ActionText = "Barcos"
	prompt.ObjectText = "⚓ Puerto deportivo"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("InDialogue") then
			return
		end
		BoatService.openMenu(player)
	end)
end

local function addSlip(part: Instance)
	if not part:IsA("BasePart") or table.find(slips, part) then
		return
	end
	table.insert(slips, part)
	table.sort(slips, function(a, b)
		return (a:GetAttribute("Slip") or 0) < (b:GetAttribute("Slip") or 0)
	end)
end

-- Barcos abandonados: sin nadie a bordo y su dueño lejos durante IdleReturn -> vuelven al puerto
local function returnIdle()
	local now = os.clock()
	for player, entry in afloat do
		local model = entry.Model
		local chassis = model.PrimaryPart
		if not model.Parent or not chassis then
			afloat[player] = nil
			continue
		end
		local busy = model:GetAttribute("Driver") ~= nil
		for _, seat in model:GetChildren() do
			if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and seat.Occupant then
				busy = true
			end
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and (root.Position - chassis.Position).Magnitude < BoatService.IdleNear then
			busy = true
		end
		if busy then
			entry.Since = now
		elseif now - entry.Since >= BoatService.IdleReturn then
			removeBoat(player, ("⚓ Tu %s ha vuelto sola al puerto deportivo."):format(string.lower(nameOf(entry.Kind))))
		end
	end
end
BoatService.returnIdle = returnIdle

function BoatService.init()
	for _, part in CollectionService:GetTagged("BoatMarina") do
		setupOffice(part)
	end
	CollectionService:GetInstanceAddedSignal("BoatMarina"):Connect(setupOffice)
	for _, part in CollectionService:GetTagged("BoatSlip") do
		addSlip(part)
	end
	CollectionService:GetInstanceAddedSignal("BoatSlip"):Connect(addSlip)

	DataService.onLoaded(function(player)
		BoatService.sync(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		removeBoat(player, nil)
	end)
	task.spawn(function()
		while true do
			task.wait(30)
			local ok, err = pcall(returnIdle)
			if not ok then
				warn("[BoatService] " .. tostring(err))
			end
		end
	end)
end

return BoatService
