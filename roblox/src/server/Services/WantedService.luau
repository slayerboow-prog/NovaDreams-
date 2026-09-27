-- WantedService: delitos, testigos y nivel de búsqueda (estrellas) — reglas en shared/Wanted.
--
-- Delitos que se detectan:
--   * Pegar a una persona (CombatService) y dejarla K.O.
--   * Robar dinero a otro jugador (comando ROBAR del menú, junto a él)
--   * Atracar una tienda (cartel "Atracar" en las tiendas, mantener pulsado)
--   * Agredir a un agente de policía
-- Un delito solo suma estrellas si alguien lo ve: la policía (patrullas o jugadores policía de
-- servicio), un testigo que llama o, en plena calle, a veces un transeúnte. En un atraco siempre
-- salta la alarma. Mientras te buscan: más estrellas = más patrullas (PoliceUnits). Si ningún
-- policía te ve durante Wanted.evadeSeconds, te libras. Si te alcanzan: detenido, multa y comisaría.
-- Un policía jugador de servicio también puede detenerte (comando DETENER, junto a ti).
-- Al detenerte pasas a disposición judicial (JusticeService): juicio o sentencia automática.
-- Las estrellas se guardan: salir del juego no borra la búsqueda.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Wanted = require(ReplicatedStorage.Shared.Wanted)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Npc = require(script.Parent.Parent.World.Npc)
local PoliceUnits = require(script.Parent.Parent.World.PoliceUnits)
local Roads = require(script.Parent.Parent.World.Kit.Roads)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local JusticeService = require(script.Parent.JusticeService)
local CareerService = require(script.Parent.CareerService)

local WantedService = {}

type State = { Stars: number, LastSeen: number, LastPosition: Vector3?, CatchSince: number?, StealAt: number, Arresting: boolean, Crimes: { string } }

local states: { [Player]: State } = {}
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

local function onDuty(player: Player): boolean
	return player:GetAttribute("Job") == "Policia"
end

local function setStars(player: Player, stars: number)
	local state = stateOf(player)
	state.Stars = stars
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
	for _, part in workspace:GetPartBoundsInRadius(position, Wanted.WitnessRadius, params) do
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
	if not player.Parent then
		return
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
	if not oldEnough(player) then
		Notify:FireClient(player, "Error", "¡Eso no se hace! Si fueras mayor, vendría la policía.")
		return
	end
	if player:GetAttribute("JailUntil") or player:GetAttribute("OnTrial") then
		return -- dentro de la cárcel (o en un juicio) no viene la policía
	end
	local at = position or (rootOf(player) and (rootOf(player) :: BasePart).Position)
	if not at then
		return
	end
	if crime == "AgresionPolicia" or policeSees(player, at) then
		report(player, crime, "Police")
		return
	end
	if options and options.Alarm then
		task.delay(Wanted.CallDelay, report, player, crime, "Alarm")
		return
	end
	local witness = witnessNear(player, at)
	if witness then
		Npc.say(witness, "📞 ¡Policía! ¡Rápido, venid!")
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
	if state.Stars <= 0 or state.Arresting then
		return
	end
	state.Arresting = true
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
	Remote:FireClient(player, "Busted", { Stars = stars, By = cop and cop.DisplayName })
	StoryEvents.emit(player, "Arrested", { Stars = stars })
	-- A disposición judicial: juicio (si hay juez de guardia) o sentencia automática
	JusticeService.process(player, stars, if #crimes > 0 then crimes else { "Resistencia a la autoridad" })
	task.delay(4, function()
		state.Arresting = false
		state.CatchSince = nil
	end)
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
		Notify:FireClient(thief, "Error", "Eres demasiado pequeño para eso.")
		return
	end
	if os.clock() - state.StealAt < Wanted.StealCooldown then
		Notify:FireClient(thief, "Error", "Espera un poco antes de volver a intentarlo.")
		return
	end
	if victim:GetAttribute("InDialogue") or victim:GetAttribute("LifeStage") == "Bebe" then
		return
	end
	state.StealAt = os.clock()
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
	prompt.KeyboardKeyCode = Enum.KeyCode.V
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
	prompt:SetAttribute("MinStage", Wanted.MinStage) -- (solo lo ven los mayores; JobPrompts)
	prompt.Parent = entrance
	prompt.Triggered:Connect(function(player)
		if not oldEnough(player) then
			return
		end
		local now = os.time()
		if (entrance:GetAttribute("RobbedUntil") or 0) > now then
			Notify:FireClient(player, "Error", "La caja está vacía: la acaban de atracar.")
			return
		end
		entrance:SetAttribute("RobbedUntil", now + Wanted.HeistCooldown)
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
	if not r or state.Arresting then
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
		end
	else
		state.CatchSince = nil
	end
	PoliceUnits.ensure(player, state.Stars)
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
		return
	end
	local victim = Players:GetPlayerByUserId(payload.Target)
	-- Un policía de servicio que reduce a alguien buscado no comete delito
	if victim and onDuty(player) and stateOf(victim).Stars > 0 then
		return
	end
	WantedService.crime(player, if payload.Killed then "Homicidio" elseif payload.KO then "KO" else "Agresion")
end

-- Sin estrellas (al morir)
function WantedService.clear(player: Player)
	setStars(player, 0)
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
			if a and b and (a.Position - b.Position).Magnitude <= 8 and stateOf(target).Stars > 0 then
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
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
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
