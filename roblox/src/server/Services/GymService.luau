-- GymService: los gimnasios de Valmar (edificios: World/Kit/GymKit; reglas: Shared/Gym).
--
-- ENTRAR: en la recepción ("Recepción") se paga la entrada del día o el abono mensual. Los niños
-- pagan la mitad; los bebés no pueden entrenar. La recepcionista (NPC) está siempre detrás del
-- mostrador.
--
-- ENTRENAR: cada máquina tiene "Entrenar". Te colocas en ella (la raíz queda anclada en su sitio y
-- cada cliente dibuja el ejercicio: GymMotion) y abajo sale la barra del ritmo (GymUI). Cada acierto
-- es una repetición; el servidor comprueba que no vayan más rápido de lo que se puede y que te
-- quede esfuerzo. Al completar una serie (Gym.SetReps) sube la Fuerza o la Forma física, gasta hambre
-- y energía, da experiencia (StoryEvents "GymSet") y el cuerpo se ensancha un poco (LifeService lee
-- el atributo GymStrength). "Dejar" (o saltar) te baja de la máquina.
--
-- SIN ENTRENAR: tras unos días de juego sin ir al gimnasio la Fuerza y la Forma bajan poco a poco.
--
-- GENTE: cuando hay algún jugador cerca, unos cuantos deportistas (NPC) entrenan en las máquinas
-- libres (se apartan si quieres usar la suya).
--
-- MONITOR/A DE GIMNASIO (tablón "Trabajar" dentro del gimnasio): los deportistas piden ayuda (🙋) y
-- el monitor les corrige la postura ("Ayudar"): cobra y cuenta para la historia (JobTaskDone). Los
-- jugadores que entrenan cerca de un monitor de turno ganan un 20 % más, y el monitor se lleva una
-- propina por cada serie.
--
-- Atributos para el cliente: GymStrength, GymCardio, GymSets, GymPassUntil, GymPassDays, GymPass
-- (jugador); Training (jugador, mientras entrena); GymExercise, GymMachine, GymRep (en el personaje o
-- el NPC que entrena, con la etiqueta GymTraining).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gym = require(ReplicatedStorage.Shared.Gym)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local OpeningHours = require(ReplicatedStorage.Shared.OpeningHours)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local JobService = require(script.Parent.JobService)
local RoleService = require(script.Parent.RoleService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local GymService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Gym :: RemoteEvent
local JOB = "MonitorGimnasio"
local LATENCY = 0.15 -- margen por el retraso de la red entre dos repeticiones
local NEAR_GYM = 150 -- a esta distancia de la recepción empiezan a entrenar los deportistas
local MONITOR_RANGE = 70 -- el monitor ayuda a los que entrenan en su gimnasio
local NPCS_PER_GYM = 3
local FOUNTAIN_COOLDOWN = 25
local MACHINE_RANGE = 10 -- más lejos de la máquina que esto: ya no estás en ella (te han teletransportado…)

type Session = {
	Machine: Model,
	Kind: string,
	Anchor: BasePart,
	Reps: number,
	Perfect: number,
	Effort: number,
	LastRep: number,
	LastAction: number,
	Sets: number,
}

type GymInfo = {
	Id: string,
	Name: string,
	Desk: BasePart,
	Machines: { Model },
	Npcs: { [Model]: { Machine: Model, Next: number, Count: number } },
	Request: Model?, -- deportista que pide ayuda al monitor
	RequestPrompt: ProximityPrompt?,
	NextRequest: number,
}

local sessions: { [Player]: Session } = {}
local occupant: { [Model]: any } = {} -- máquina -> jugador o NPC
local machineById: { [string]: Model } = {}
local gyms: { [string]: GymInfo } = {}
local monitors: { [Player]: boolean } = {}
local lastDrink: { [Player]: number } = {}
local warnedDecay: { [Player]: boolean } = {}
local npcFolder: Folder? = nil

-- Hora real (para abonos y días de juego) y reloj de la partida; se pueden cambiar en las pruebas
GymService._now = function(): number
	return os.time()
end
GymService._clock = function(): number
	return os.clock()
end
-- Hora del juego (la misma que usan las tiendas para abrir y cerrar)
GymService._hour = function(): number
	return OpeningHours.clock()
end

-- El gimnasio cierra de noche (como su monitora): nil si está abierto, o el aviso para el jugador
local function closedMessage(): string?
	local hours = OpeningHours.Places.Gym
	if OpeningHours.isOpen(hours, GymService._hour()) then
		return nil
	end
	return ("🔒 El gimnasio está cerrado: %s. Vuelve más tarde."):format(OpeningHours.label(hours))
end

local function daySeconds(): number
	return Gym.daySeconds(Config.DayLengthMinutes)
end

local function rootOf(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function stageOf(player: Player): string?
	return player:GetAttribute("LifeStage")
end

---------------------------------------------------------------------
-- Datos
---------------------------------------------------------------------
local function gymData(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local g = data.Gym
	if type(g) ~= "table" then
		g = {}
		data.Gym = g
	end
	for key, default in { Strength = 0, Cardio = 0, Sets = 0, PassUntil = 0, LastTrain = 0, DecayApplied = 0 } do
		if type(g[key]) ~= "number" then
			g[key] = default
		end
	end
	if type(g.PassKind) ~= "string" then
		g.PassKind = ""
	end
	g.Strength = math.clamp(g.Strength, 0, Gym.MaxStat)
	g.Cardio = math.clamp(g.Cardio, 0, Gym.MaxStat)
	return g
end
GymService.data = gymData

local function sync(player: Player)
	local g = gymData(player)
	if not g then
		return
	end
	local now = GymService._now()
	-- (con un decimal: el cuerpo cambia en cuanto se nota, sin mandar cambios por cada centésima)
	player:SetAttribute("GymStrength", math.floor(g.Strength * 10 + 0.5) / 10)
	player:SetAttribute("GymCardio", math.floor(g.Cardio * 10 + 0.5) / 10)
	player:SetAttribute("GymSets", g.Sets)
	player:SetAttribute("GymPassUntil", g.PassUntil)
	player:SetAttribute("GymPassDays", Gym.daysLeft(g.PassUntil, now, daySeconds()))
	player:SetAttribute("GymPass", if Gym.hasAccess(g, now) then g.PassKind else nil)
end

-- Pérdida suave si hace días (de juego) que no entrenas
local function applyDecay(player: Player)
	local g = gymData(player)
	if not g then
		return
	end
	local days = Gym.pendingDecayDays(g.LastTrain, GymService._now(), daySeconds(), g.DecayApplied)
	if days <= 0 then
		return
	end
	g.DecayApplied += days
	local before = g.Strength + g.Cardio
	g.Strength = Gym.decayed(g.Strength, days + Gym.DecayGraceDays)
	g.Cardio = Gym.decayed(g.Cardio, days + Gym.DecayGraceDays)
	sync(player)
	if before - (g.Strength + g.Cardio) >= 0.5 and not warnedDecay[player] then
		warnedDecay[player] = true
		Notify:FireClient(player, "Info", "💪 Hace días que no vas al gimnasio: pierdes un poco de forma. ¡Vuelve a entrenar!")
	end
end
GymService.applyDecay = applyDecay

---------------------------------------------------------------------
-- Entrenar
---------------------------------------------------------------------
local function machineDef(machine: Model): Gym.Machine?
	return Gym.Machines[machine:GetAttribute("Kind") or ""]
end

local function anchorOf(machine: Model): BasePart?
	local anchor = machine:FindFirstChild("GymAnchor")
	return if anchor and anchor:IsA("BasePart") then anchor else nil
end

-- Pies en el suelo de la máquina, mirando hacia donde se entrena
local function feetOf(anchor: BasePart): CFrame
	return anchor.CFrame * CFrame.new(0, -anchor.Size.Y / 2, 0)
end

local function liftOf(model: Model): number
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = rootOf(model)
	return (if humanoid then humanoid.HipHeight else 2) + (if root then root.Size.Y / 2 else 1)
end

local function setTraining(model: Model, kind: string?, machineId: string?)
	model:SetAttribute("GymExercise", kind)
	model:SetAttribute("GymMachine", machineId)
	model:SetAttribute("GymRep", if kind then 0 else nil)
	if kind then
		model:AddTag("GymTraining")
	else
		model:RemoveTag("GymTraining")
	end
end

local function gymOf(machine: Model): GymInfo?
	return gyms[machine:GetAttribute("GymId") or ""]
end

-- Quita un deportista (NPC) de su máquina
local function removeNpc(info: GymInfo, npc: Model)
	local entry = info.Npcs[npc]
	if entry then
		occupant[entry.Machine] = nil
	end
	info.Npcs[npc] = nil
	if info.Request == npc then
		info.Request = nil
		info.RequestPrompt = nil
	end
	npc:Destroy()
end

function GymService.stop(player: Player, silent: boolean?)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	if occupant[s.Machine] == player then
		occupant[s.Machine] = nil
	end
	player:SetAttribute("Training", nil)
	local character = player.Character
	if character then
		setTraining(character, nil, nil)
		local root = rootOf(character)
		if root and root.Parent then
			-- Solo te baja de la máquina si sigues en ella: si te han llevado a otro sitio, te quedas allí
			if s.Anchor.Parent and (root.Position - s.Anchor.Position).Magnitude <= MACHINE_RANGE then
				local exit = s.Machine:GetAttribute("Exit")
				local feet = if typeof(exit) == "Vector3" then CFrame.new(exit) * feetOf(s.Anchor).Rotation else feetOf(s.Anchor)
				root.CFrame = feet * CFrame.new(0, liftOf(character), 0)
			end
			root.Anchored = false
		end
	end
	Remote:FireClient(player, "Stop", { Sets = s.Sets })
	if not silent and s.Sets > 0 then
		local g = gymData(player)
		if g then
			Notify:FireClient(player, "Success", ("💪 ¡Buen entreno! %d serie%s · Fuerza %d · Forma %d"):format(s.Sets, if s.Sets == 1 then "" else "s", math.floor(g.Strength), math.floor(g.Cardio)))
		end
	end
end

local function start(player: Player, machine: Model)
	local def = machineDef(machine)
	local anchor = anchorOf(machine)
	local g = gymData(player)
	local data = DataService.get(player)
	if not def or not anchor or not g or not data then
		return
	end
	local current = sessions[player]
	if current then
		local same = current.Machine == machine
		GymService.stop(player, not same)
		if same then
			return
		end
	end
	local ok, why = Gym.canUse(def.Kind, stageOf(player))
	if not ok then
		Notify:FireClient(player, "Error", why or "No puedes usar esta máquina.")
		return
	end
	local closed = closedMessage()
	if closed then
		Notify:FireClient(player, "Error", closed)
		return
	end
	local who = occupant[machine]
	if who and who ~= player then
		if typeof(who) == "Instance" and who:IsA("Player") then
			Notify:FireClient(player, "Error", ("%s Esta máquina está ocupada: espera o prueba otra."):format(def.Icon))
			return
		end
		-- Un deportista (NPC): te la deja
		local info = gymOf(machine)
		if info and typeof(who) == "Instance" and who:IsA("Model") then
			removeNpc(info, who)
		end
	end
	local now = GymService._now()
	if not Gym.hasAccess(g, now) and not monitors[player] then
		Notify:FireClient(player, "Error", ("🎟️ Necesitas entrada para entrenar: pásate por la recepción (%s el día, %s el mes)."):format(Format.money(Gym.price("Dia", stageOf(player)) or 0), Format.money(Gym.price("Mes", stageOf(player)) or 0)))
		return
	end
	if (data.Energy or 100) < Gym.MinEnergy then
		Notify:FireClient(player, "Error", "😴 Estás demasiado cansado para entrenar. Descansa o duerme un poco.")
		return
	elseif (data.Hunger or 100) < Gym.MinHunger then
		Notify:FireClient(player, "Error", "🍔 Tienes demasiada hambre para entrenar. Come algo antes.")
		return
	end
	local character = player.Character
	local root = rootOf(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if player:GetAttribute("Riding") or player:GetAttribute("Sleeping") then
		Notify:FireClient(player, "Error", "Primero bájate de donde estás.")
		return
	end
	humanoid.Sit = false
	root.Anchored = true
	root.CFrame = feetOf(anchor) * CFrame.new(0, liftOf(character), 0)
	occupant[machine] = player
	local clock = GymService._clock()
	sessions[player] = {
		Machine = machine,
		Kind = def.Kind,
		Anchor = anchor,
		Reps = 0,
		Perfect = 0,
		Effort = Gym.EffortMax,
		LastRep = clock - 10,
		LastAction = clock - 10,
		Sets = 0,
	}
	player:SetAttribute("Training", def.Kind)
	setTraining(character, def.Kind, machine:GetAttribute("MachineId"))
	Remote:FireClient(player, "Start", {
		Kind = def.Kind,
		Name = def.Name,
		Icon = def.Icon,
		Stat = def.Stat,
		Loop = def.Loop,
		Tempo = def.Tempo,
		Zone = def.Zone,
		SetReps = Gym.SetReps,
		Effort = Gym.EffortMax,
		EffortCost = def.Effort,
		Strength = g.Strength,
		Cardio = g.Cardio,
	})
end
GymService.start = start

-- ¿Hay un monitor/a de turno cerca de este jugador? (devuelve el monitor)
local function monitorNear(player: Player): Player?
	local root = rootOf(player.Character)
	if not root then
		return nil
	end
	for monitor in monitors do
		local other = rootOf(monitor.Character)
		if monitor ~= player and other and (other.Position - root.Position).Magnitude <= MONITOR_RANGE then
			return monitor
		end
	end
	return nil
end

local function completeSet(player: Player, s: Session)
	local g = gymData(player)
	local def = Gym.Machines[s.Kind]
	if not g or not def then
		return
	end
	local quality = 1 + (Gym.PerfectBonus - 1) * (s.Perfect / Gym.SetReps)
	local monitor = monitorNear(player)
	if monitor then
		quality *= Gym.MonitorBonus
		-- La propina la paga quien entrena (antes salía de la nada: dinero infinito entre dos amigos)
		local tip = 2
		if DataService.spend(player, tip) then
			DataService.addMoney(monitor, tip, true)
			Notify:FireClient(monitor, "Money", ("+%s · propina de %s"):format(Format.money(tip), player.DisplayName or player.Name))
		end
	end
	local beforeStrength = g.Strength
	local ds, dc = Gym.setGains(s.Kind, g.Strength, g.Cardio, quality)
	g.Strength = math.min(Gym.MaxStat, g.Strength + ds)
	g.Cardio = math.min(Gym.MaxStat, g.Cardio + dc)
	g.Sets += 1
	g.LastTrain = GymService._now()
	g.DecayApplied = 0
	warnedDecay[player] = nil
	s.Sets += 1
	s.Reps = 0
	s.Perfect = 0
	local cost = Gym.SetCost[def.Stat] or Gym.SetCost.Fuerza
	NeedsService.change(player, -cost.Hunger, -cost.Energy)
	sync(player)
	StoryEvents.emit(player, "GymSet", { Kind = s.Kind, Strength = g.Strength, Cardio = g.Cardio })
	Remote:FireClient(player, "Set", {
		Sets = s.Sets,
		Strength = g.Strength,
		Cardio = g.Cardio,
		GainStrength = ds,
		GainCardio = dc,
		Monitor = monitor ~= nil,
	})
	-- Cada 10 puntos de Fuerza, un aviso (y el cuerpo se ensancha un poco más)
	if math.floor(g.Strength / 10) > math.floor(beforeStrength / 10) then
		Notify:FireClient(player, "Success", ("💪 ¡Se te nota! Fuerza %d: estás %s."):format(math.floor(g.Strength), Gym.level(g.Strength)))
	end
	local data = DataService.get(player)
	if data and ((data.Energy or 100) < Gym.MinEnergy or (data.Hunger or 100) < Gym.MinHunger) then
		GymService.stop(player)
		Notify:FireClient(player, "Error", "🥵 ¡Agotado! Come algo y descansa antes de seguir entrenando.")
	end
end

local function onRep(player: Player, quality: any)
	local s = sessions[player]
	local def = s and Gym.Machines[s.Kind]
	if not s or not def then
		return
	end
	local clock = GymService._clock()
	if clock - s.LastRep < Gym.minRepGap(s.Kind) - LATENCY then
		return -- más rápido de lo que se puede: no cuenta
	end
	s.LastAction = clock
	if s.Effort < def.Effort then
		Remote:FireClient(player, "Tired", { Effort = s.Effort })
		return
	end
	s.LastRep = clock
	s.Effort -= def.Effort
	s.Reps += 1
	if quality == "Perfecto" then
		s.Perfect += 1
	end
	local character = player.Character
	if character then
		character:SetAttribute("GymRep", (character:GetAttribute("GymRep") or 0) + 1)
	end
	Remote:FireClient(player, "Rep", { Reps = s.Reps, Effort = s.Effort, Quality = if quality == "Perfecto" then "Perfecto" else "Bien" })
	if s.Reps >= Gym.SetReps then
		completeSet(player, s)
	end
end

local function onMiss(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	s.LastAction = GymService._clock()
	s.Effort = math.max(0, s.Effort - Gym.MissEffort)
	Remote:FireClient(player, "Effort", { Effort = s.Effort })
end

-- El esfuerzo se recupera descansando
local function regen(dt: number)
	local clock = GymService._clock()
	for player, s in sessions do
		if s.Effort < Gym.EffortMax and clock - s.LastAction >= Gym.EffortRestDelay then
			local before = s.Effort
			s.Effort = math.min(Gym.EffortMax, s.Effort + Gym.EffortRegen * dt)
			if math.floor(s.Effort / 5) ~= math.floor(before / 5) or s.Effort >= Gym.EffortMax then
				Remote:FireClient(player, "Effort", { Effort = s.Effort })
			end
		end
	end
end
GymService._regen = regen

---------------------------------------------------------------------
-- Recepción: entrada del día y abono mensual
---------------------------------------------------------------------
local function receptionInfo(player: Player, info: GymInfo?): { [string]: any }
	local g = gymData(player)
	local now = GymService._now()
	local passes = {}
	for _, id in Gym.PassOrder do
		local pass = Gym.Passes[id]
		table.insert(passes, { Id = id, Name = pass.Name, Icon = pass.Icon, Days = pass.Days, Price = Gym.price(id, stageOf(player)) })
	end
	return {
		Gym = if info then info.Name else "Gimnasio",
		Passes = passes,
		Active = g ~= nil and Gym.hasAccess(g, now),
		Kind = if g then g.PassKind else "",
		DaysLeft = if g then Gym.daysLeft(g.PassUntil, now, daySeconds()) else 0,
		Strength = if g then g.Strength else 0,
		Cardio = if g then g.Cardio else 0,
		Sets = if g then g.Sets else 0,
		Baby = stageOf(player) == "Bebe",
	}
end

local function nearDesk(player: Player): GymInfo?
	local root = rootOf(player.Character)
	if not root then
		return nil
	end
	for _, info in gyms do
		if (info.Desk.Position - root.Position).Magnitude <= 20 then
			return info
		end
	end
	return nil
end

local function buy(player: Player, passId: any)
	if type(passId) ~= "string" or not Gym.Passes[passId] then
		return
	end
	local info = nearDesk(player)
	local g = gymData(player)
	if not info or not g then
		return
	end
	if stageOf(player) == "Bebe" then
		Notify:FireClient(player, "Error", "👶 Los bebés no pueden apuntarse al gimnasio.")
		return
	end
	local closed = closedMessage()
	if closed then
		Notify:FireClient(player, "Error", closed)
		return
	end
	local price = Gym.price(passId, stageOf(player)) or 0
	if not DataService.spend(player, price) then
		Notify:FireClient(player, "Error", ("No tienes dinero suficiente (%s)."):format(Format.money(price)))
		return
	end
	local pass = Gym.Passes[passId]
	g.PassUntil = Gym.extend(g.PassUntil, passId, GymService._now(), daySeconds())
	g.PassKind = passId
	sync(player)
	Notify:FireClient(player, "Success", ("%s %s: ¡a entrenar! Te quedan %d día%s de gimnasio."):format(pass.Icon, pass.Name, Gym.daysLeft(g.PassUntil, GymService._now(), daySeconds()), if Gym.daysLeft(g.PassUntil, GymService._now(), daySeconds()) == 1 then "" else "s"))
	StoryEvents.emit(player, "BoughtItem", { ShopId = "Gimnasio", Item = "Gym_" .. passId })
	Remote:FireClient(player, "Reception", receptionInfo(player, info))
end

---------------------------------------------------------------------
-- Deportistas (NPC) y monitor/a
---------------------------------------------------------------------
local SPORT_LOOKS = {
	{ Shirt = Color3.fromRGB(230, 110, 30), Pants = Color3.fromRGB(30, 30, 36) },
	{ Shirt = Color3.fromRGB(40, 120, 200), Pants = Color3.fromRGB(40, 40, 46) },
	{ Shirt = Color3.fromRGB(240, 240, 240), Pants = Color3.fromRGB(60, 60, 70) },
	{ Shirt = Color3.fromRGB(200, 40, 90), Pants = Color3.fromRGB(30, 30, 36) },
	{ Shirt = Color3.fromRGB(60, 160, 90), Pants = Color3.fromRGB(50, 50, 56) },
}

local function playerNear(position: Vector3, range: number): boolean
	for _, player in Players:GetPlayers() do
		local root = rootOf(player.Character)
		if root and (root.Position - position).Magnitude <= range then
			return true
		end
	end
	return false
end

local function spawnNpc(info: GymInfo)
	local free = {}
	for _, machine in info.Machines do
		local def = machineDef(machine)
		if not occupant[machine] and def and anchorOf(machine) then
			table.insert(free, machine)
		end
	end
	if #free == 0 then
		return
	end
	local machine = free[math.random(1, #free)]
	local anchor = anchorOf(machine) :: BasePart
	local kind = machine:GetAttribute("Kind")
	local npc = Npc.create("Deportista", npcFolder :: Folder, feetOf(anchor), SPORT_LOOKS[math.random(1, #SPORT_LOOKS)])
	setTraining(npc, kind, machine:GetAttribute("MachineId"))
	occupant[machine] = npc
	info.Npcs[npc] = { Machine = machine, Next = GymService._clock() + math.random() * 2, Count = 0 }
end

-- El deportista hace sus repeticiones (el cliente dibuja una por cada GymRep) y descansa entre series
local function npcTick(info: GymInfo)
	local clock = GymService._clock()
	for npc, entry in info.Npcs do
		if not npc.Parent then
			info.Npcs[npc] = nil
			occupant[entry.Machine] = nil
			continue
		end
		if clock >= entry.Next then
			local def = machineDef(entry.Machine)
			local tempo = if def then def.Tempo else 1.5
			npc:SetAttribute("GymRep", (npc:GetAttribute("GymRep") or 0) + 1)
			entry.Count += 1
			entry.Next = clock + tempo * 1.15 + (if entry.Count % Gym.SetReps == 0 then 4 + math.random() * 3 else 0)
		end
	end
end

local function clearRequest(info: GymInfo)
	if info.RequestPrompt then
		info.RequestPrompt:Destroy()
	end
	if info.Request and info.Request.Parent then
		Npc.icon(info.Request, nil)
	end
	info.Request = nil
	info.RequestPrompt = nil
end

local function help(monitor: Player, info: GymInfo, npc: Model)
	if not monitors[monitor] or info.Request ~= npc then
		return
	end
	local job = Config.Jobs[JOB]
	local pay = math.floor(job.Pay * MonetizationService.payMultiplier(monitor))
	clearRequest(info)
	DataService.addMoney(monitor, pay, true)
	local data = DataService.get(monitor)
	if data and data.Stats then
		data.Stats.TasksDone = (data.Stats.TasksDone or 0) + 1
	end
	NeedsService.change(monitor, 0, -job.EnergyCost)
	Notify:FireClient(monitor, "Money", ("+%s · postura corregida"):format(Format.money(pay)))
	StoryEvents.emit(monitor, "JobTaskDone", { JobId = JOB, Pay = pay })
	pcall(Npc.say, npc, "¡Gracias! Así mucho mejor 💪")
	task.delay(2.5, function()
		if npc.Parent then
			pcall(Npc.say, npc, nil)
		end
	end)
	info.NextRequest = GymService._clock() + 6 + math.random() * 6
	if not NeedsService.canWork(monitor) then
		GymService.quitJob(monitor, true)
		Notify:FireClient(monitor, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
	end
end

local function makeRequest(info: GymInfo)
	local list = {}
	for npc in info.Npcs do
		if npc.Parent then
			table.insert(list, npc)
		end
	end
	if #list == 0 then
		return
	end
	local npc = list[math.random(1, #list)]
	local root = rootOf(npc)
	if not root then
		return
	end
	info.Request = npc
	Npc.icon(npc, "🙋")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GymHelpPrompt"
	prompt.ActionText = "Ayudar"
	prompt.ObjectText = "🙋 Corregir la postura"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("JobOnly", JOB)
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		help(player, info, npc)
	end)
	info.RequestPrompt = prompt
end

local function nearestGym(position: Vector3): (GymInfo?, number)
	local best, bestD = nil, math.huge
	for _, info in gyms do
		local d = (info.Desk.Position - position).Magnitude
		if d < bestD then
			best, bestD = info, d
		end
	end
	return best, bestD
end

local function guideMonitor(player: Player)
	local root = rootOf(player.Character)
	if not root then
		return
	end
	local info, distance = nearestGym(root.Position)
	if not info then
		return
	end
	if distance > MONITOR_RANGE then
		player:SetAttribute("TaskTarget", info.Desk.Position)
		player:SetAttribute("TaskText", ("Ve al %s a ayudar a los que entrenan"):format(info.Name))
	elseif info.Request and rootOf(info.Request) then
		player:SetAttribute("TaskTarget", (rootOf(info.Request) :: BasePart).Position)
		player:SetAttribute("TaskText", "🙋 Alguien necesita ayuda con su ejercicio: corrígele la postura")
	else
		player:SetAttribute("TaskTarget", nil)
		player:SetAttribute("TaskText", "Pasea por el gimnasio: pronto alguien pedirá ayuda")
	end
end

function GymService.startJob(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	JobService.quit(player, true)
	monitors[player] = true
	RoleService.setOnDuty(player, JOB)
	player:SetAttribute("Job", JOB)
	Notify:FireClient(player, "Success", "¡Contratado como monitor/a de gimnasio! Ayuda a quien levante la mano (🙋). Además, entrenas gratis.")
	guideMonitor(player)
end

function GymService.quitJob(player: Player, silent: boolean?)
	if not monitors[player] then
		return
	end
	monitors[player] = nil
	RoleService.offDuty(player, JOB)
	if player:GetAttribute("Job") == JOB then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado tu turno de monitor/a.")
	end
end

-- Cada segundo: deportistas que aparecen y se van, peticiones de ayuda y guía del monitor
local function gymTick()
	local clock = GymService._clock()
	local anyMonitor = next(monitors) ~= nil
	for _, info in gyms do
		local near = playerNear(info.Desk.Position, NEAR_GYM)
		local count = 0
		for _ in info.Npcs do
			count += 1
		end
		if near and count < NPCS_PER_GYM then
			spawnNpc(info)
		elseif not near and count > 0 then
			clearRequest(info)
			for npc in table.clone(info.Npcs) do
				removeNpc(info, npc)
			end
		end
		npcTick(info)
		-- Peticiones de ayuda (solo si hay algún monitor de turno cerca)
		if info.Request and not info.Request.Parent then
			clearRequest(info)
		end
		if anyMonitor and not info.Request and clock >= info.NextRequest then
			local monitorHere = false
			for monitor in monitors do
				local root = rootOf(monitor.Character)
				if root and (root.Position - info.Desk.Position).Magnitude <= MONITOR_RANGE then
					monitorHere = true
				end
			end
			if monitorHere then
				makeRequest(info)
			end
		end
	end
	for monitor in monitors do
		guideMonitor(monitor)
	end
end
GymService._tick = gymTick

---------------------------------------------------------------------
-- Mapa
---------------------------------------------------------------------
local function prompt(parent: BasePart, action: string, object: string, hold: number, distance: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = distance or 7
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function setupMachine(machine: Instance)
	if not machine:IsA("Model") then
		return
	end
	local anchor = anchorOf(machine)
	local def = machineDef(machine)
	if not anchor or not def or anchor:FindFirstChild("GymPrompt") then
		return
	end
	machineById[machine:GetAttribute("MachineId") or ""] = machine
	local info = gymOf(machine)
	if info and not table.find(info.Machines, machine) then
		table.insert(info.Machines, machine)
	end
	local p = prompt(anchor, "Entrenar", ("%s %s"):format(def.Icon, def.Name), 0.2, 6)
	p.Name = "GymPrompt"
	-- Los bebés no ven ningún cartel; los niños, solo los de las máquinas ligeras
	p:SetAttribute("MinStage", if def.Light then "Nino" else "Adolescente")
	p.Triggered:Connect(function(player)
		start(player, machine)
	end)
end

local function setupDesk(desk: Instance)
	if not desk:IsA("BasePart") or desk:FindFirstChild("ReceptionPrompt") then
		return
	end
	local id = desk:GetAttribute("GymId") or desk:GetFullName()
	local info: GymInfo = gyms[id] or {
		Id = id,
		Name = desk:GetAttribute("GymName") or "Gimnasio",
		Desk = desk,
		Machines = {},
		Npcs = {},
		NextRequest = 0,
	}
	gyms[id] = info
	-- Las máquinas de este gimnasio que ya estén en el mapa
	for _, machine in CollectionService:GetTagged("GymMachine") do
		if machine:GetAttribute("GymId") == id and not table.find(info.Machines, machine) then
			table.insert(info.Machines, machine)
		end
	end
	local p = prompt(desk, "Recepción", "💪 " .. info.Name, 0.2, 10)
	p.Name = "ReceptionPrompt"
	p.Triggered:Connect(function(player)
		Remote:FireClient(player, "Reception", receptionInfo(player, info))
	end)
	local spot = desk:GetAttribute("StaffSpot")
	if typeof(spot) == "Vector3" then
		local ok, clerk = pcall(Npc.create, "Recepcionista", desk.Parent :: Instance, CFrame.new(Npc.feetAt(spot)) * desk.CFrame.Rotation, { Shirt = Color3.fromRGB(230, 110, 30), Pants = Color3.fromRGB(30, 30, 36) })
		if ok and clerk then
			pcall(Npc.work, clerk, "Type")
			pcall(Npc.icon, clerk, "💪")
		end
	end
end

local function setupFountain(fountain: Instance)
	if not fountain:IsA("BasePart") or fountain:FindFirstChild("DrinkPrompt") then
		return
	end
	local p = prompt(fountain, "Beber agua", "💧 Fuente", 0.3, 7)
	p.Name = "DrinkPrompt"
	p:SetAttribute("MinStage", "Nino")
	p.Triggered:Connect(function(player)
		local clock = GymService._clock()
		if clock - (lastDrink[player] or -math.huge) < FOUNTAIN_COOLDOWN then
			Notify:FireClient(player, "Info", "💧 Ya has bebido hace nada.")
			return
		end
		lastDrink[player] = clock
		NeedsService.change(player, 1, 4)
		Notify:FireClient(player, "Success", "💧 ¡Qué fresquita! Recuperas un poco de energía.")
	end)
end

function GymService.init()
	local folder = Instance.new("Folder")
	folder.Name = "Deportistas"
	folder.Parent = workspace
	npcFolder = folder
	-- Primero las recepciones (cada una es un gimnasio) y luego las máquinas
	for tag, fn in { GymReception = setupDesk } do
		for _, part in CollectionService:GetTagged(tag) do
			fn(part)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
	end
	for tag, fn in { GymMachine = setupMachine, GymFountain = setupFountain } do
		for _, part in CollectionService:GetTagged(tag) do
			fn(part)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
	end
	JobService.setHandler(JOB, { Start = GymService.startJob, Quit = GymService.quitJob })

	DataService.onLoaded(function(player)
		local g = gymData(player)
		-- Lo que ha estado desconectado no cuenta: ni se pierde forma ni caduca el abono
		-- (antes 24 h fuera eran 72 días de juego: la Fuerza caía de 80 a 20)
		if g and DataService.offlineSeconds then
			Gym.skipOffline(g, DataService.offlineSeconds(player))
		end
		applyDecay(player)
		sync(player)
		player.CharacterRemoving:Connect(function()
			GymService.stop(player, true)
		end)
	end)

	Remote.OnServerEvent:Connect(function(player, action, a)
		if action == "Rep" then
			onRep(player, a)
		elseif action == "Miss" then
			onMiss(player)
		elseif action == "Stop" then
			GymService.stop(player)
		elseif action == "Buy" then
			buy(player, a)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		GymService.stop(player, true)
		GymService.quitJob(player, true)
		lastDrink[player] = nil
		warnedDecay[player] = nil
	end)

	-- Esfuerzo (4 veces por segundo), gente y monitor (cada segundo), abonos y pérdida (cada minuto)
	task.spawn(function()
		local elapsed, slow = 0, 0
		while true do
			local dt = task.wait(0.25)
			local ok, err = pcall(function()
				regen(dt)
				-- Si se muere, se queda sin personaje o lo llevan lejos de la máquina (teletransporte), se
				-- acaba el entreno (y se suelta el anclaje, sin volver a la máquina)
				for player, s in sessions do
					local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					local root = rootOf(player.Character)
					if not humanoid or humanoid.Health <= 0 or not s.Machine.Parent then
						GymService.stop(player, true)
					elseif root and (root.Position - s.Anchor.Position).Magnitude > MACHINE_RANGE then
						GymService.stop(player, true)
					end
				end
				elapsed += dt
				slow += dt
				if elapsed >= 1 then
					elapsed = 0
					gymTick()
				end
				if slow >= 60 then
					slow = 0
					for _, player in Players:GetPlayers() do
						applyDecay(player)
						sync(player)
					end
				end
			end)
			if not ok then
				warn("[GymService] " .. tostring(err))
			end
		end
	end)
end

-- Para las pruebas
GymService._sessions = sessions
GymService._gyms = gyms
GymService._occupant = occupant
GymService._rep = onRep
GymService._miss = onMiss
GymService._buy = buy
GymService._complete = completeSet

return GymService
