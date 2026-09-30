-- WantedService: delitos, testigos y nivel de búsqueda (estrellas) — reglas en shared/Wanted.
--
-- Delitos que se detectan:
--   * Pegar a una persona (CombatService) y dejarla K.O.
--   * Robar dinero a otro jugador (comando ROBAR del menú, junto a él)
--   * Atracar una tienda (cartel "Atracar" en las tiendas, mantener pulsado)
--   * Agredir a un agente de policía
--   * Disparar a una persona o disparar en plena calle (WeaponService; la policía de servicio
--     contra alguien buscado, no)
-- Un delito solo suma estrellas si alguien lo ve: la policía (patrullas o jugadores policía de
-- servicio), un testigo que llama o, en plena calle, a veces un transeúnte. En un atraco siempre
-- salta la alarma. Mientras te buscan: más estrellas = más patrullas (PoliceUnits). Si ningún
-- policía te ve durante Wanted.evadeSeconds, te libras. Si te alcanzan: detenido, multa y comisaría.
-- Un policía jugador de servicio también puede detenerte (comando DETENER, junto a ti).
-- Al detenerte pasas a disposición judicial (JusticeService): juicio o sentencia automática.
-- Si eres menor (niño o adolescente), no: la policía te lleva a casa con tu familia (ConductService).
--
-- Al volante (checkDrivers, cada medio segundo): conducir sin el carnet que toca, o siendo menor,
-- solo es delito si te ve la policía (una patrulla de ronda, agentes o un policía jugador de
-- servicio a menos de Wanted.DriveSight y sin nada en medio). Entonces: «¡Alto!», la patrulla
-- enciende la sirena y te sigue, y 1 estrella. Si Wanted.StopSeconds después sigues conduciendo,
-- huida (+1). Si paras, bajan los agentes y te detienen.
-- Lo que se sabe de ti también va a tu historial de comportamiento (ConductService).
-- Las estrellas se guardan: salir del juego no borra la búsqueda.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Wanted = require(ReplicatedStorage.Shared.Wanted)
local Movement = require(ReplicatedStorage.Shared.Movement)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Npc = require(script.Parent.Parent.World.Npc)
local PoliceUnits = require(script.Parent.Parent.World.PoliceUnits)
local Roads = require(script.Parent.Parent.World.Kit.Roads)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local TesterService = require(script.Parent.TesterService) -- (hoja: sin dependencias circulares)
local JusticeService = require(script.Parent.JusticeService)
local CareerService = require(script.Parent.CareerService)
local VehicleService = require(script.Parent.VehicleService)
local ConductService = require(script.Parent.ConductService)
local Conduct = require(ReplicatedStorage.Shared.Conduct)

local WantedService = {}

type Stop = { At: number, Crime: string, Fled: boolean }
type State = { Stars: number, LastSeen: number, LastPosition: Vector3?, CatchSince: number?, StealAt: number, Arresting: boolean, Crimes: { string }, Stop: Stop?, MisbehavedAt: number?, TesterAgeNoted: boolean?, NpcHits: { [Model]: number }? }

local states: { [Player]: State } = {}
-- Pausas contra el abuso: un atraco cada HEIST_GAP por jugador y a la misma víctima no se le roba
-- más de una vez cada VICTIM_GAP (antes se podía ir de tienda en tienda o robar sin parar)
local HEIST_GAP = 300
local VICTIM_GAP = 300
-- Disparar a un personaje (NPC): una denuncia por víctima como mucho cada tanto (una ráfaga no son 5★)
local NPC_HIT_GAP = 8
-- (por UserId: salir y volver a entrar no reinicia la pausa)
local heistAt: { [number]: number } = {}
local robbedAt: { [number]: { [number]: number } } = {}
local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent

local function stateOf(player: Player): State
	local state = states[player]
	if not state then
		state = { Stars = 0, LastSeen = 0, StealAt = -math.huge, Arresting = false, Crimes = {} }
		states[player] = state
	end
	return state
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function oldEnough(player: Player): boolean
	local stage = player:GetAttribute("LifeStage")
	return stage == nil or Stages.inRange(stage, Wanted.MinStage, nil)
end

-- ¿Cuentan sus delitos como los de un mayor? Modo pruebas con «Sin requisitos»: la edad no cuenta
-- ni para llevar un arma de verdad ni para librarse de la policía (antes un niño tester podía
-- disparar con un subfusil y solo salía «Si fueras mayor, vendría la policía»).
local MINOR_LABEL = { Bebe = "un bebé", Nino = "un niño", Adolescente = "adolescente" }
local function answersAsAdult(player: Player): boolean
	return oldEnough(player) or TesterService.bypass(player)
end

local function onDuty(player: Player): boolean
	return player:GetAttribute("Job") == "Policia"
end

-- Preso, en un juicio o muerto: la policía no viene a por ti (ya está la justicia)
local function outOfReach(player: Player): boolean
	return player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil or player:GetAttribute("Dead") ~= nil
end

local function setStars(player: Player, stars: number)
	local state = stateOf(player)
	state.Stars = stars
	if stars <= 0 then
		state.Stop = nil -- (sin búsqueda, un nuevo «¡Alto!» vuelve a contar)
	end
	player:SetAttribute("Wanted", if stars > 0 then stars else nil)
	player:SetAttribute("WantedSearching", nil)
	local data = DataService.get(player)
	if data then
		data.Wanted = if stars > 0 then stars else nil
	end
	if stars > 0 then
		PoliceUnits.ensure(player, stars)
	else
		PoliceUnits.dismiss(player)
	end
end

---------------------------------------------------------------------
-- Testigos
---------------------------------------------------------------------

-- ¿Lo ve un policía? (jugadores policía de servicio o patrullas de otros)
local function policeSees(offender: Player, position: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	for _, cop in Players:GetPlayers() do
		local r = rootOf(cop)
		if cop ~= offender and onDuty(cop) and r and (r.Position - position).Magnitude <= Wanted.PoliceSight then
			if not workspace:Raycast(r.Position, position - r.Position, params) then
				Notify:FireClient(cop, "Info", ("🚨 Has visto un delito: %s"):format(offender.DisplayName))
				return true
			end
		end
	end
	return PoliceUnits.sees(offender) or PoliceUnits.anyNear(position, Wanted.PoliceSight, offender)
end

-- Un personaje cercano que lo ha visto (para que llame)
local function witnessNear(offender: Player, position: Vector3): Model?
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { offender.Character :: Instance }
	local best, bestDistance = nil, math.huge
	-- Agachado o tumbado se te ve menos: los testigos tienen que estar más cerca
	local radius = Wanted.WitnessRadius * Movement.witnessFactor(offender:GetAttribute("Stance"))
	for _, part in workspace:GetPartBoundsInRadius(position, radius, params) do
		local model = part.Parent
		if model and model:IsA("Model") and part.Name == "HumanoidRootPart" and not Players:GetPlayerFromCharacter(model) and not model:GetAttribute("Officer") then
			local distance = (part.Position - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = model, distance
			end
		end
	end
	return best
end

local function nearRoad(position: Vector3): boolean
	local flat = Vector3.new(position.X, 0, position.Z)
	for _, segment in Roads.segments() do
		local a, b = Vector3.new(segment.A.X, 0, segment.A.Z), Vector3.new(segment.B.X, 0, segment.B.Z)
		local along = b - a
		if along.Magnitude > 1 then
			local t = math.clamp((flat - a):Dot(along.Unit), 0, along.Magnitude)
			if (flat - (a + along.Unit * t)).Magnitude <= Wanted.StreetDistance then
				return true
			end
		end
	end
	return false
end

-- Suma estrellas por un delito ya denunciado
local function report(player: Player, crime: string, how: string)
	if not player.Parent or outOfReach(player) then
		return -- (el aviso llega tarde: ya estás preso, en un juicio o muerto)
	end
	local state = stateOf(player)
	local before = state.Stars
	local stars = Wanted.starsAfter(before, crime)
	table.insert(state.Crimes, Wanted.Crimes[crime].Text)
	state.LastSeen = os.clock()
	local r = rootOf(player)
	state.LastPosition = r and r.Position
	setStars(player, stars)
	PoliceUnits.setTarget(player, state.LastPosition)
	Remote:FireClient(player, "Crime", { Crime = Wanted.Crimes[crime].Text, How = how, Stars = stars, Before = before })
	StoryEvents.emit(player, "Crime", { Crime = crime, Stars = stars })
end

-- Algo malo: ¿lo ha visto alguien? Si sí, a la policía (ahora o cuando llame el testigo)
-- options.Alarm = true: siempre llega el aviso (la alarma de una tienda)
function WantedService.crime(player: Player, crime: string, position: Vector3?, options: { [string]: any }?)
	if not Wanted.Crimes[crime] or not player.Parent then
		return
	end
	local at = position or (rootOf(player) and (rootOf(player) :: BasePart).Position)
	if not Wanted.appliesTo(crime, answersAsAdult(player)) then
		Notify:FireClient(player, "Error", "¡Eso no se hace! Si fueras mayor, vendría la policía.")
		-- Si alguien lo ha visto, tu familia se entera (historial de comportamiento)
		local state = stateOf(player)
		if at and os.clock() - (state.MisbehavedAt or -math.huge) > 20 and (witnessNear(player, at) or PoliceUnits.anyNear(at, Wanted.PoliceSight, player)) then
			state.MisbehavedAt = os.clock()
			StoryEvents.emit(player, "Misbehaved", { Crime = crime })
		end
		return
	end
	if player:GetAttribute("JailUntil") or player:GetAttribute("OnTrial") then
		return -- dentro de la cárcel (o en un juicio) no viene la policía
	end
	if not at then
		return
	end
	if not oldEnough(player) and not Wanted.appliesTo(crime, false) then
		-- (solo llega aquí un tester menor con «Sin requisitos»: se le explica una vez)
		local state = stateOf(player)
		if not state.TesterAgeNoted then
			state.TesterAgeNoted = true
			Notify:FireClient(player, "Info", ("🧪 Modo pruebas: aunque eres %s, con «Sin requisitos» tus delitos cuentan como los de un adulto (viene la policía)."):format(MINOR_LABEL[player:GetAttribute("LifeStage")] or "menor"))
		end
	end
	if crime == "AgresionPolicia" or policeSees(player, at) then
		report(player, crime, "Police")
		return
	end
	if options and options.Alarm then
		task.delay(Wanted.CallDelay, report, player, crime, "Alarm")
		return
	end
	-- La víctima (un personaje al que le han disparado) siempre llama; si no, el testigo más cercano
	local victim = options and options.Witness
	local witness = if typeof(victim) == "Instance" and victim.Parent then victim else witnessNear(player, at)
	if witness then
		-- (la víctima primero se queja del disparo: llama un momento después)
		local called = witness
		task.delay(if witness == victim then 1.5 else 0, function()
			if called.Parent then
				Npc.say(called, "📞 ¡Policía! ¡Rápido, venid!")
			end
		end)
		task.delay(Wanted.CallDelay, function()
			if witness.Parent then
				Npc.say(witness, nil)
			end
			report(player, crime, "Witness")
		end)
	elseif nearRoad(at) and math.random() < Wanted.StreetCallChance then
		task.delay(Wanted.CallDelay + 2, report, player, crime, "Passerby")
	end
end

---------------------------------------------------------------------
-- Detención
---------------------------------------------------------------------
function WantedService.arrest(player: Player, cop: Player?)
	local state = stateOf(player)
	if state.Stars <= 0 or state.Arresting or outOfReach(player) then
		return
	end
	state.Arresting = true
	-- Se programa antes de nada: aunque algo de abajo falle, la detención nunca se queda "a medias" para siempre
	task.delay(4, function()
		state.Arresting = false
		state.CatchSince = nil
	end)
	local stars = state.Stars
	local crimes = state.Crimes
	state.Crimes = {}
	if cop then
		DataService.addMoney(cop, Wanted.ArrestReward * stars, true)
		Notify:FireClient(cop, "Success", ("🚔 Has detenido a %s: +%s"):format(player.DisplayName, Format.money(Wanted.ArrestReward * stars)))
		StoryEvents.emit(cop, "JobTaskDone", { JobId = "Policia" })
		CareerService.addPoints(cop, "Policia", "Arrest")
	end
	setStars(player, 0)
	local minor = Conduct.isMinor(player:GetAttribute("LifeStage"))
	Remote:FireClient(player, "Busted", { Stars = stars, By = cop and cop.DisplayName, Minor = minor, Crimes = crimes })
	StoryEvents.emit(player, "Arrested", { Stars = stars, Minor = minor })
	-- Del vehículo, abajo (y el vehículo se queda parado)
	pcall(VehicleService.exitAny, player, true)
	if minor then
		-- Un niño o un adolescente no va a juicio: a casa con su familia
		ConductService.takeHome(player, crimes)
	else
		-- A disposición judicial: juicio (si hay juez de guardia) o sentencia automática
		JusticeService.process(player, stars, if #crimes > 0 then crimes else { "Resistencia a la autoridad" })
	end
end

---------------------------------------------------------------------
-- Robar a una persona
---------------------------------------------------------------------
local function steal(thief: Player, victim: any)
	if typeof(victim) ~= "Instance" or not victim:IsA("Player") or victim == thief then
		return
	end
	local state = stateOf(thief)
	local tr, vr = rootOf(thief), rootOf(victim)
	if not tr or not vr or (tr.Position - vr.Position).Magnitude > Wanted.StealRange then
		return
	end
	if not oldEnough(thief) then
		Notify:FireClient(thief, "Error", "Aún no tienes edad para esto.")
		return
	end
	if os.clock() - state.StealAt < Wanted.StealCooldown then
		Notify:FireClient(thief, "Error", "Espera un poco antes de volver a intentarlo.")
		return
	end
	if victim:GetAttribute("InDialogue") or victim:GetAttribute("LifeStage") == "Bebe" then
		return
	end
	-- Los dos en el mismo sitio (misma casa o edificio, o los dos en la calle): acercarse
	-- teletransportándose a otro interior no vale
	if thief:GetAttribute("InteriorKey") ~= victim:GetAttribute("InteriorKey") then
		return
	end
	-- Recién aparecido, sentado (en un vehículo o una silla) o en una zona segura: no se le roba
	local CombatService = require(script.Parent.CombatService) :: any
	local WeaponService = require(script.Parent.WeaponService) :: any
	if CombatService.isProtected(victim) or WeaponService.safeSpot(vr.Position) or WeaponService.safeSpot(tr.Position) then
		Notify:FireClient(thief, "Error", "Aquí no puedes robar.")
		return
	end
	local mine = robbedAt[thief.UserId]
	if mine and os.clock() - (mine[victim.UserId] or -math.huge) < VICTIM_GAP then
		Notify:FireClient(thief, "Error", "A esta persona ya le has robado hace poco.")
		return
	end
	-- En la cárcel o en un juicio no se roba (dentro no viene la policía: saldría gratis)
	if thief:GetAttribute("JailUntil") or thief:GetAttribute("OnTrial") or victim:GetAttribute("JailUntil") or victim:GetAttribute("OnTrial") then
		Notify:FireClient(thief, "Error", "Aquí no puedes robar.")
		return
	end
	state.StealAt = os.clock()
	robbedAt[thief.UserId] = robbedAt[thief.UserId] or {}
	robbedAt[thief.UserId][victim.UserId] = os.clock()
	local data = DataService.get(victim)
	local amount = Wanted.stealAmount(if data then data.Money else 0)
	if amount <= 0 then
		Notify:FireClient(thief, "Info", victim.DisplayName .. " no lleva dinero encima.")
	else
		DataService.addMoney(victim, -amount)
		DataService.addMoney(thief, amount)
		Notify:FireClient(thief, "Success", ("💸 Le has quitado %s a %s"):format(Format.money(amount), victim.DisplayName))
		Notify:FireClient(victim, "Error", ("💸 ¡%s te ha robado %s!"):format(thief.DisplayName, Format.money(amount)))
	end
	WantedService.crime(thief, "Robo", tr.Position)
end

---------------------------------------------------------------------
-- Atracar tiendas
---------------------------------------------------------------------
local function setupHeist(entrance: Instance)
	if not entrance:IsA("BasePart") or entrance:FindFirstChild("HeistPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HeistPrompt"
	prompt.ActionText = "Atracar"
	prompt.ObjectText = "🔫 Caja de la tienda"
	prompt.HoldDuration = Wanted.HeistHold
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	-- Teclas libres: V es fijar objetivo y el Y del mando, tirar piedras. Y no la usa nada; X del
	-- mando es la de siempre de los carteles (el menú de comandos reparte si coincide con otro)
	prompt.KeyboardKeyCode = Enum.KeyCode.Y
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt:SetAttribute("MinStage", Wanted.MinStage) -- (solo lo ven los mayores; JobPrompts)
	prompt.Parent = entrance
	prompt.Triggered:Connect(function(player)
		if not oldEnough(player) or outOfReach(player) then
			return
		end
		-- Con la policía ya detrás no se encadenan atracos, y cada jugador tiene su pausa
		-- (si no, se iba de tienda en tienda vaciando cajas)
		if stateOf(player).Stars >= 1 then
			Notify:FireClient(player, "Error", "Te está buscando la policía: no es momento de atracar.")
			return
		end
		if os.clock() - (heistAt[player.UserId] or -math.huge) < HEIST_GAP then
			Notify:FireClient(player, "Error", "Demasiado pronto para otro atraco: espera un rato.")
			return
		end
		local now = os.time()
		if (entrance:GetAttribute("RobbedUntil") or 0) > now then
			Notify:FireClient(player, "Error", "La caja está vacía: la acaban de atracar.")
			return
		end
		entrance:SetAttribute("RobbedUntil", now + Wanted.HeistCooldown)
		heistAt[player.UserId] = os.clock()
		local loot = math.random(Wanted.HeistLoot[1], Wanted.HeistLoot[2])
		DataService.addMoney(player, loot)
		Notify:FireClient(player, "Success", ("💰 Te llevas %s de la caja… ¡ha saltado la alarma!"):format(Format.money(loot)))
		Remote:FireAllClients("Alarm", entrance)
		WantedService.crime(player, "Atraco", entrance.Position, { Alarm = true })
	end)
end

---------------------------------------------------------------------
-- Vigilancia: ¿te ven?, ¿te alcanzan?, ¿te has librado?
---------------------------------------------------------------------
local function watchWanted(player: Player, state: State)
	local r = rootOf(player)
	if not r or state.Arresting or outOfReach(player) then
		return
	end
	local now = os.clock()
	if player:GetAttribute("InteriorKey") then
		-- Escondido dentro de un edificio: la policía espera en la puerta (no te ve)
		local door = player:GetAttribute("InteriorDoor")
		state.LastPosition = if typeof(door) == "Vector3" then door else state.LastPosition
		player:SetAttribute("WantedSearching", true)
		PoliceUnits.setTarget(player, state.LastPosition)
		if now - state.LastSeen > Wanted.evadeSeconds(state.Stars) then
			setStars(player, 0)
			state.Crimes = {}
			Remote:FireClient(player, "Evaded", {})
		end
		return
	end
	if PoliceUnits.sees(player) then
		state.LastSeen = now
		state.LastPosition = r.Position
		PoliceUnits.setTarget(player, r.Position)
		player:SetAttribute("WantedSearching", nil)
	else
		-- Te buscan donde te vieron por última vez; las estrellas parpadean
		player:SetAttribute("WantedSearching", true)
		PoliceUnits.setTarget(player, state.LastPosition)
		if now - state.LastSeen > Wanted.evadeSeconds(state.Stars) then
			setStars(player, 0)
			state.Crimes = {}
			Remote:FireClient(player, "Evaded", {})
			StoryEvents.emit(player, "EvadedPolice", {})
			return
		end
	end
	-- Te alcanzan: un agente pegado a ti un momento (o estás K.O. con uno cerca)
	local close = PoliceUnits.officersNear(player, r.Position, Wanted.CatchDistance) > 0
	local knocked = player:GetAttribute("KO") == true and PoliceUnits.officersNear(player, r.Position, 10) > 0
	if close or knocked then
		state.CatchSince = state.CatchSince or now
		if knocked or now - state.CatchSince >= Wanted.CatchSeconds then
			WantedService.arrest(player, nil)
			return -- (ya sin estrellas: no hace falta patrulla)
		end
	else
		state.CatchSince = nil
	end
	PoliceUnits.ensure(player, state.Stars)
end

---------------------------------------------------------------------
-- Al volante sin carnet (o siendo menor): solo si te ve la policía
---------------------------------------------------------------------

-- ¿Ve la policía a quien conduce? Un policía jugador de servicio, una patrulla de ronda o los
-- agentes y coches de cualquier persecución. Devuelve también la patrulla de ronda que le vio.
local function policeSeesDriver(player: Player): (boolean, any)
	local r = rootOf(player)
	if not r then
		return false, nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	local rides = workspace:FindFirstChild("Rides")
	if rides then
		table.insert(ignore, rides) -- (a quien va en coche se le ve por las ventanillas)
	end
	params.FilterDescendantsInstances = ignore
	for _, cop in Players:GetPlayers() do
		local c = rootOf(cop)
		if cop ~= player and onDuty(cop) and c and (c.Position - r.Position).Magnitude <= Wanted.DriveSight then
			if not workspace:Raycast(c.Position, r.Position - c.Position, params) then
				Notify:FireClient(cop, "Info", ("🚨 %s conduce sin carnet delante de ti"):format(player.DisplayName))
				return true, nil
			end
		end
	end
	return PoliceUnits.seesDriver(player, Wanted.DriveSight)
end
WantedService.policeSeesDriver = policeSeesDriver

local function checkDriver(player: Player, state: State)
	local offence = VehicleService.drivingOffence(player)
	if not offence or state.Arresting or player:GetAttribute("JailUntil") or player:GetAttribute("OnTrial") then
		return
	end
	local now = os.clock()
	local stop = state.Stop
	if not stop then
		local seen, patrol = policeSeesDriver(player)
		if seen then
			state.Stop = { At = now, Crime = offence, Fled = false }
			PoliceUnits.pullOver(player, patrol)
			Notify:FireClient(player, "Error", "🚨 ¡Alto! ¡Policía! Para el vehículo y bájate.")
			report(player, offence, "Police")
		end
	elseif not stop.Fled and now - stop.At >= Wanted.StopSeconds and VehicleService.rideSpeed(player) >= Wanted.StopSpeed then
		-- Le han dado el «¡Alto!» y sigue conduciendo: huida
		stop.Fled = true
		report(player, "Huida", "Police")
	end
end

-- Repaso de todos los que van al volante (lo hace el bucle cada medio segundo; las pruebas lo llaman)
function WantedService.checkDrivers()
	for _, player in Players:GetPlayers() do
		if player.Parent and VehicleService.ridingKind(player) then
			local ok, err = pcall(checkDriver, player, stateOf(player))
			if not ok then
				warn("[Wanted] " .. tostring(err))
			end
		end
	end
end

---------------------------------------------------------------------
-- Lo que hace CombatService (golpes) -> delitos
---------------------------------------------------------------------
local function onStoryEvent(player: Player, name: string, payload: { [string]: any })
	if name ~= "HitSomeone" then
		return
	end
	local model = payload.Model
	if typeof(model) == "Instance" and model:GetAttribute("Officer") then
		WantedService.crime(player, "AgresionPolicia")
		return
	end
	if not payload.Target then
		-- Disparar (o dar con el táser) a un personaje de la calle también es delito: antes solo
		-- contaba si la víctima era un jugador, y a los NPC se les podía acribillar sin que nadie
		-- llamase. La víctima llama a la policía (una denuncia por víctima cada NPC_HIT_GAP).
		local w = Weapons.get(payload.Weapon)
		if w and w.Kind ~= "Toy" and typeof(model) == "Instance" and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
			if onDuty(player) and model:GetAttribute("Suspect") then
				return -- (la policía de servicio reduciendo al sospechoso de su aviso)
			end
			local state = stateOf(player)
			state.NpcHits = state.NpcHits or {}
			local hits = state.NpcHits :: { [Model]: number }
			local now = os.clock()
			if now - (hits[model] or -math.huge) < NPC_HIT_GAP then
				return
			end
			for other, at in hits do
				if now - at >= NPC_HIT_GAP then
					hits[other] = nil
				end
			end
			hits[model] = now
			local root = model:FindFirstChild("HumanoidRootPart")
			local at = if root and root:IsA("BasePart") then root.Position else nil
			local r = rootOf(player)
			WantedService.crime(player, if w.Kind == "Taser" then "Agresion" else "Disparo", if r then r.Position else at, { Witness = model })
		end
		return
	end
	local victim = Players:GetPlayerByUserId(payload.Target)
	-- Un policía de servicio que reduce a alguien buscado no comete delito
	if victim and onDuty(player) and stateOf(victim).Stars > 0 then
		return
	end
	if payload.Weapon then
		WantedService.crime(player, if payload.Killed then "Homicidio" else "Disparo")
		return
	end
	WantedService.crime(player, if payload.Killed then "Homicidio" elseif payload.KO then "KO" else "Agresion")
end

-- Sin estrellas
function WantedService.clear(player: Player)
	setStars(player, 0)
end

-- ¿Es policía de servicio? (disparar a alguien buscado no es delito para ellos)
function WantedService.onDuty(player: Player): boolean
	return onDuty(player)
end

function WantedService.stars(player: Player): number
	return stateOf(player).Stars
end

function WantedService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Wanted") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Wanted"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player: Player, kind: any, target: any)
		if kind == "Steal" then
			steal(player, target)
		elseif kind == "Arrest" and onDuty(player) and typeof(target) == "Instance" and target:IsA("Player") and target ~= player then
			local a, b = rootOf(player), rootOf(target)
			-- Mismo sitio (misma casa o edificio, o los dos fuera): no vale teletransportarse al lado
			local sameSpot = player:GetAttribute("InteriorKey") == target:GetAttribute("InteriorKey")
			if a and b and sameSpot and (a.Position - b.Position).Magnitude <= 8 and stateOf(target).Stars > 0 then
				WantedService.arrest(target, player)
			end
		end
	end)

	PoliceUnits.init()
	StoryEvents.connect(onStoryEvent)
	for _, entrance in CollectionService:GetTagged("Shop") do
		setupHeist(entrance)
	end
	CollectionService:GetInstanceAddedSignal("Shop"):Connect(setupHeist)

	-- La búsqueda se guarda con la partida: al volver sigues buscado
	DataService.onLoaded(function(player, data)
		local stars = tonumber(data.Wanted) or 0
		if stars > 0 then
			local state = stateOf(player)
			state.LastSeen = os.clock()
			task.delay(6, function()
				if player.Parent then
					local r = rootOf(player)
					state.LastPosition = r and r.Position
					setStars(player, math.clamp(stars, 1, Wanted.MaxStars))
				end
			end)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		PoliceUnits.dismiss(player)
		states[player] = nil
		-- (las esperas van por UserId para que salir y entrar no las reinicie; las ya cumplidas se borran)
		local now = os.clock()
		for id, at in heistAt do
			if now - at >= HEIST_GAP then
				heistAt[id] = nil
			end
		end
		for thief, victims in robbedAt do
			for victim, at in victims do
				if now - at >= VICTIM_GAP then
					victims[victim] = nil
				end
			end
			if next(victims) == nil then
				robbedAt[thief] = nil
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			WantedService.checkDrivers()
			for player, state in states do
				if state.Stars > 0 and player.Parent then
					local ok, err = pcall(watchWanted, player, state)
					if not ok then
						warn("[Wanted] " .. tostring(err))
					end
				end
			end
		end
	end)
end

return WantedService
