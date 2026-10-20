-- TefraJobService (servidor): los OFICIOS de Tefra (shared/Cosmos/TefraJobs; docs/planetas/tefra-misiones.md).
--
-- Reutiliza lo de siempre: el tablón «Trabajar» (JobService.setupBoard con Config.Jobs; aquí, como el
-- barista de CafeService, cada oficio es un «oficio con su propio sistema»: JobService.setHandler), los
-- atributos que pinta el HUD y el GPS (Job, TaskTarget, TaskText), el botón de dejar el trabajo
-- (JobService.quit), los minijuegos (MiniGameService: Timing), las conversaciones con opciones
-- (DialogueService: el puzle de los cables y los encargos con historia), la paga (DataService.addMoney,
-- con el VIP de MonetizationService), la energía (NeedsService), el aviso JobTaskDone a la historia y
-- la carrera guardada en data.Careers[IdDelOficio] = { Points, Tasks, Local = { Tefra = n } }.
--
-- Cada oficio es una pequeña máquina de fases (llegar a un sitio → minijuego o decisión → llevar algo):
--   TefraFundidor      Cargar (montón de mineral) → Crisol (temperatura) → Molde (colar)
--   TefraDesactivador  Detectar (el detector pita cerca) → Bomba (cables con pista + pulso firme) →
--                      Polvorin (llevar la carcasa). Fallar = «¡BUM!»: Derribado (TefraService.knockDown)
--   TefraBombero       Aviso (la colada) → Barreras (tres, contra reloj) → Enfriar (agua a presión)
--   TefraCorreo        Saca (estafeta) → Tunel (boca del túnel) → Entrega; las patrullas te ven a
--                      SeeRadius (de noche, en toque de queda, más lejos y paga más). Con los Papeles de
--                      Bastión (cadena «Papeles») la patrulla te deja seguir.
--   GalaxiaRescatista  Aviso (escombros; tras un bombardeo, en sus zonas y con paga extra) → Levantar →
--                      Hospital (Campus Nilda)
--   GalaxiaIngeniero   Bloques (patio de la Forja) → Muralla (el tramo dañado) → prueba de carga
-- El servidor comprueba las distancias (nunca se fía del cliente) y los tiempos mínimos (TefraJobs.allowed).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local GameClock = require(Shared.GameClock)
local Tefra = require(Shared.Cosmos.Tefra)
local TefraCity = require(Shared.Cosmos.TefraCity)
local TefraJobs = require(Shared.Cosmos.TefraJobs)
local Items = require(Shared.Items)

local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local TefraJobService = {}

TefraJobService.Tick = 0.25
TefraJobService.Reach = 7 -- studs (en planta) para «has llegado»
TefraJobService.CorreoGrace = 4 -- segundos al empezar cada tramo en los que la patrulla aún no mira

local function service(name: string): any
	return require(script.Parent[name])
end

type Shift = {
	JobId: string,
	Phase: string,
	Target: Vector3?,
	Text: string,
	Started: number, -- empezó este encargo (tiempo mínimo)
	PhaseAt: number,
	Busy: boolean, -- en un minijuego o una conversación
	Score: number?,
	Extra: number?,
	Data: { [string]: any },
	Carry: BasePart?,
	Visuals: { Instance },
}
local shifts: { [Player]: Shift } = {}
local history: { [Player]: { [string]: { number } } } = {}
local streaks: { [Player]: { Job: string, N: number } } = {}
local chispaTimes: { [Player]: { number } } = {}
local patrolParts: { BasePart } = {}
local folder: Instance? = nil
local notify: RemoteEvent? = nil
local random = Random.new()

-- (el reloj se puede cambiar en las pruebas: TefraJobService.Clock)
TefraJobService.Clock = os.clock
local function now(): number
	return TefraJobService.Clock()
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function dataOf(player: Player): { [string]: any }?
	local ok, data = pcall(function()
		return service("DataService").get(player)
	end)
	return if ok then data else nil
end

local function base(): number
	return Tefra.Origin.Y + Tefra.padY()
end

-- Un punto local de Tefra → posición del mundo (en la acera o, fuera de la muralla, en el suelo)
function TefraJobService.worldPoint(lx: number, lz: number, out: boolean?): Vector3
	local wx, wz = Tefra.Origin.X + lx, Tefra.Origin.Z + lz
	if out then
		return Vector3.new(wx, Tefra.groundAt(wx, wz) + 1, wz)
	end
	return Vector3.new(wx, base() + 1, wz)
end
local P = TefraJobService.worldPoint

local function visualsFolder(): Instance
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "OficiosTefra"
	local ok, root = pcall(function()
		return require(script.Parent.Parent.World.PlanetWorld).folder()
	end)
	f.Parent = if ok and root then root else workspace
	folder = f
	return f
end

local function piece(shift: Shift?, props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "ClassName" and k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent or visualsFolder()
	if shift then
		table.insert(shift.Visuals, p)
	end
	return p
end

local function clearVisuals(shift: Shift)
	for _, v in shift.Visuals do
		pcall(function()
			v:Destroy()
		end)
	end
	table.clear(shift.Visuals)
end

local function removeCarry(shift: Shift)
	if shift.Carry then
		pcall(function()
			(shift.Carry :: BasePart):Destroy()
		end)
		shift.Carry = nil
	end
end

-- Algo en las manos (como JobService: caja, carcasa, bloque, carta…)
local function carry(player: Player, shift: Shift)
	removeCarry(shift)
	local root = rootOf(player)
	local job = Config.Jobs[shift.JobId]
	if not root or not job then
		return
	end
	pcall(function()
		local item = Instance.new("Part")
		item.Name = "CarriedItem"
		item.Size = job.CarrySize
		item.Color = job.CarryColor
		item.Material = Enum.Material.SmoothPlastic
		item.CanCollide = false
		item.CanQuery = false
		item.Massless = true
		item.CFrame = root.CFrame * CFrame.new(0, 0.45, -1.35)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = item
		weld.Parent = item
		item.Parent = player.Character
		shift.Carry = item
	end)
end

local function go(player: Player, shift: Shift, phase: string, target: Vector3, text: string)
	shift.Phase = phase
	shift.Target = target
	shift.Text = text
	shift.PhaseAt = now()
	player:SetAttribute("TaskTarget", target)
	player:SetAttribute("TaskText", text)
end

---------------------------------------------------------------------
-- Carrera (data.Careers)
---------------------------------------------------------------------
local function careerEntry(player: Player, jobId: string): { [string]: any }?
	local data = dataOf(player)
	if not data then
		return nil
	end
	data.Careers = if type(data.Careers) == "table" then data.Careers else {}
	local entry = data.Careers[jobId]
	if type(entry) ~= "table" then
		entry = { Points = 0 }
		data.Careers[jobId] = entry
	end
	entry.Points = tonumber(entry.Points) or 0
	entry.Tasks = tonumber(entry.Tasks) or 0
	return entry
end

function TefraJobService.points(player: Player, jobId: string): number
	local entry = careerEntry(player, jobId)
	return entry and entry.Points or 0
end

local function showRank(player: Player, jobId: string)
	local points = TefraJobService.points(player, jobId)
	local _, rank = TefraJobs.rankFor(points)
	player:SetAttribute("Career_" .. jobId, points)
	-- (CareerService quita el rango al cambiar de oficio: se pone otra vez justo después)
	task.delay(0.15, function()
		if player.Parent and player:GetAttribute("Job") == jobId then
			player:SetAttribute("Rank", rank.Name)
		end
	end)
end

---------------------------------------------------------------------
-- Cobrar un encargo
---------------------------------------------------------------------
-- Paga, progreso, materiales, Chispas y el aviso a la historia. Devuelve lo cobrado (0 si no cuenta).
-- opts = { Started = cuándo empezó el encargo, Extra = multiplicador (toque de queda, tras bombardeo) }
function TefraJobService.finish(player: Player, jobId: string, score: number, opts: { [string]: any }?): number
	local job = TefraJobs.Jobs[jobId]
	local entry = careerEntry(player, jobId)
	if not job or not entry then
		return 0
	end
	local o = opts or {}
	local t = now()
	history[player] = history[player] or {}
	local list = history[player][jobId] or {}
	history[player][jobId] = list
	local ok, why = TefraJobs.allowed(jobId, list, o.Started or (t - job.MinSeconds), t)
	if not ok then
		toast(player, "Error", "⏱ " .. tostring(why) .. ": este encargo no se paga.")
		return 0
	end
	table.insert(list, t)
	while #list > TefraJobs.MaxPerHour + 5 do
		table.remove(list, 1)
	end
	local st = streaks[player]
	if st and st.Job == jobId then
		st.N += 1
	else
		st = { Job = jobId, N = 1 }
		streaks[player] = st
	end
	local beforeRank = TefraJobs.rankFor(entry.Points)
	local pay = TefraJobs.pay(jobId, entry.Points, score, st.N, o.Extra)
	local mult = 1
	pcall(function()
		mult = service("MonetizationService").payMultiplier(player)
	end)
	pay = math.floor(pay * mult + 0.5)
	local Data = service("DataService")
	Data.addMoney(player, pay, true)
	local data = dataOf(player)
	if data and type(data.Stats) == "table" then
		data.Stats.TasksDone = (tonumber(data.Stats.TasksDone) or 0) + 1
	end
	pcall(function()
		service("NeedsService").change(player, 0, -((Config.Jobs[jobId] and Config.Jobs[jobId].EnergyCost) or 3))
	end)
	entry.Points += TefraJobs.points(score)
	entry.Tasks += 1
	if job.Galaxy then
		entry.Local = if type(entry.Local) == "table" then entry.Local else {}
		entry.Local.Tefra = (tonumber(entry.Local.Tefra) or 0) + 1
	end
	local afterRank, rank = TefraJobs.rankFor(entry.Points)
	toast(player, "Money", ("+%s · %s %s"):format(Format.money(pay), job.Icon, job.Name))
	if afterRank > beforeRank then
		toast(player, "Success", ("⭐ ¡Ascenso! Ahora eres %s de %s"):format(rank.Name, job.Name))
		StoryEvents.emit(player, "Promoted", { Institution = jobId, Rank = rank.Id })
	end
	-- Material del oficio, a veces
	if job.Drop and random:NextNumber() < job.Drop.Chance then
		pcall(function()
			service("InventoryService").add(player, job.Drop.Item, 1)
		end)
		local it = Items.get(job.Drop.Item)
		if it then
			toast(player, "Info", ("Te llevas %s %s"):format(it.Icon, it.Name))
		end
	end
	-- Chispas de los oficios peligrosos (con tope por hora)
	if job.Chispas and score > 0 then
		local times = chispaTimes[player] or {}
		chispaTimes[player] = times
		local recent = 0
		for _, ct in times do
			if t - ct < 3600 then
				recent += 1
			end
		end
		if recent < TefraJobs.ChispasPerHour then
			table.insert(times, t)
			pcall(function()
				local sp = service("SpaceService").spaceData(player)
				if sp then
					sp.Chispas = (tonumber(sp.Chispas) or 0) + job.Chispas
				end
			end)
		end
	end
	StoryEvents.emit(player, "JobTaskDone", { JobId = jobId, Pay = pay })
	if player:GetAttribute("Job") == jobId then
		showRank(player, jobId)
	end
	return pay
end

---------------------------------------------------------------------
-- Las fases de cada oficio
---------------------------------------------------------------------
local nextTask: (Player, Shift) -> ()

local function playGame(player: Player, shift: Shift, onResult: (number, boolean) -> ())
	local rankIndex = TefraJobs.rankFor(TefraJobService.points(player, shift.JobId))
	local spec = TefraJobs.gameSpec(shift.JobId, rankIndex)
	shift.Busy = true
	shift.Data.InGame = true
	local started = false
	pcall(function()
		started = service("MiniGameService").start(player, spec, function(result)
			shift.Busy = false
			shift.Data.InGame = nil
			if shifts[player] ~= shift then
				return
			end
			local rounds = spec.Rounds or 3
			local score = math.clamp((tonumber(result and result.Score) or 0) / rounds, 0, 1)
			onResult(score, result ~= nil and result.Won == true)
		end, function()
			-- (cortado: otra escena, una conversación… se repite al volver a pasar por el sitio)
			shift.Busy = false
			shift.Data.InGame = nil
			shift.PhaseAt = now()
		end)
	end)
	if not started then
		shift.Busy = false
		shift.Data.InGame = nil
		onResult(0.5, true) -- (nunca bloquear el oficio)
	end
end

-- Encargo terminado: cobrar, quizá una historia, y el siguiente
local function complete(player: Player, shift: Shift, score: number)
	removeCarry(shift)
	clearVisuals(shift)
	local pay = TefraJobService.finish(player, shift.JobId, score, { Started = shift.Started, Extra = shift.Extra })
	local entry = careerEntry(player, shift.JobId)
	local story = pay > 0 and entry and TefraJobs.storyFor(shift.JobId, entry.Tasks)
	local function after()
		if shifts[player] ~= shift then
			return
		end
		local okWork = true
		pcall(function()
			okWork = service("NeedsService").canWork(player)
		end)
		if not okWork then
			TefraJobService.quit(player, true)
			toast(player, "Error", "Te has quedado sin energía. Come algo o duerme antes de seguir trabajando.")
			return
		end
		nextTask(player, shift)
	end
	if not story then
		after()
		return
	end
	-- Encargo con historia: una pequeña decisión
	shift.Busy = true
	local options = {}
	for i, opt in story.Options do
		table.insert(options, { T = opt.T, Effects = { Pick = i } })
	end
	local lines = table.clone(story.Lines)
	table.insert(lines, { Ask = story.Ask, Options = options })
	local picked = nil
	local ok = pcall(function()
		service("DialogueService").play(player, { Lines = lines }, {
			apply = function(effects)
				if type(effects) == "table" and type(effects.Pick) == "number" then
					picked = story.Options[effects.Pick]
				end
			end,
		}, function()
			shift.Busy = false
			if picked then
				if picked.Money and picked.Money > 0 then
					service("DataService").addMoney(player, picked.Money, true)
				end
				if picked.Spend and picked.Spend > 0 then
					service("DataService").spend(player, picked.Spend)
				end
				for item, n in picked.Items or {} do
					service("InventoryService").add(player, item, n)
				end
				if picked.Says then
					toast(player, "Info", picked.Says)
				end
			end
			after()
		end, function()
			shift.Busy = false
			after()
		end)
	end)
	if not ok then
		shift.Busy = false
		after()
	end
end

-- Falla el encargo sin cobrar (y vuelve a empezar otro, sin perder nada)
local function fail(player: Player, shift: Shift, text: string, knock: boolean?)
	removeCarry(shift)
	clearVisuals(shift)
	streaks[player] = nil
	toast(player, "Error", text)
	if knock then
		pcall(function()
			service("TefraService").knockDown(player, "💥 ¡BUM! Te ha tirado al suelo la onda (Derribado, sin heridas).")
		end)
	end
	task.delay(if knock then 2.5 else 0.5, function()
		if shifts[player] == shift then
			nextTask(player, shift)
		end
	end)
end

local function pickRng(player: Player, shift: Shift): () -> number
	shift.Data.Seed = (shift.Data.Seed or (player.UserId % 9973) + 17) + 1
	return TefraJobs.rng(shift.Data.Seed * 131 + math.floor(os.clock() * 10) % 1000)
end

-- Fundidor
local function fundidorStart(player: Player, shift: Shift)
	local r = pickRng(player, shift)
	local f, i = TefraJobs.pick(TefraJobs.Foundries, r, shift.Data.Foundry)
	shift.Data.Foundry = i
	shift.Data.F = f
	go(player, shift, "Cargar", P(f.Pile[1], f.Pile[2]), ("🔥 Carga el mineral del montón de la %s"):format(f.Name))
end

-- Desactivador
local function desactivadorStart(player: Player, shift: Shift)
	local r = pickRng(player, shift)
	local b, i = TefraJobs.pick(TefraJobs.Bombs, r, shift.Data.Bomb)
	shift.Data.Bomb = i
	shift.Data.B = b
	-- El detector solo te lleva a la zona: el sitio exacto se ve al acercarte
	local a = r() * math.pi * 2
	local off = 12 + r() * 6
	go(player, shift, "Detectar", P(b.X + math.cos(a) * off, b.Z + math.sin(a) * off, b.Out), ("💣 El detector pita: hay una bomba sin explotar en %s"):format(b.Name))
end

-- Bombero
local function bomberoStart(player: Player, shift: Shift)
	local r = pickRng(player, shift)
	local c, i = TefraJobs.pick(TefraJobs.Coladas, r, shift.Data.Colada)
	shift.Data.Colada = i
	shift.Data.C = c
	shift.Data.Barrier = 0
	go(player, shift, "Aviso", P(c.X, c.Z), ("🌋 ¡Colada desbordada en %s! Corre antes de que llegue a las casas"):format(c.Name))
end

-- Correo
local function correoStart(player: Player, shift: Shift)
	local r = pickRng(player, shift)
	local m, i = TefraJobs.pick(TefraJobs.Mailboxes, r, shift.Data.Mail)
	shift.Data.Mail = i
	local night = TefraJobs.curfew(GameClock.hour())
	shift.Extra = if night then TefraJobs.CurfewBonus else nil
	go(player, shift, "Saca", P(m[1], m[2]), if night
		then "✉ Toque de queda: recoge la saca de cartas en la estafeta (paga ×1,5)"
		else "✉ Recoge la saca de cartas en la estafeta")
end

-- Rescatista: escombros (tras un bombardeo, en sus zonas)
local function rubbleSpot(r: () -> number): ({ [string]: any }, boolean)
	local recent = nil
	pcall(function()
		recent = service("TefraService").recentRaid()
	end)
	if recent and recent.Zones and #recent.Zones > 0 then
		local z = recent.Zones[math.clamp(1 + math.floor(r() * #recent.Zones), 1, #recent.Zones)]
		-- un punto de la zona donde se pueda estar (en la calle o en una manzana, sin edificio ni lava)
		for _ = 1, 12 do
			local a = r() * math.pi * 2
			local d = r() * z.R * 0.8
			local x, zz = z.X + math.cos(a) * d, z.Z + math.sin(a) * d
			if not TefraCity.inLava(x, zz) and TefraCity.buildingAt(x, zz, 3) == nil and TefraCity.inside(x, zz, -8) then
				return { Name = z.Name, X = x, Z = zz }, true
			end
		end
	end
	local spot = TefraJobs.pick(TefraJobs.Rubble, r)
	return spot, false
end

local function rescatistaStart(player: Player, shift: Shift)
	local r = pickRng(player, shift)
	local spot, afterRaid = rubbleSpot(r)
	shift.Data.R = spot
	shift.Extra = if afterRaid then 1.5 else nil
	go(player, shift, "Aviso", P(spot.X, spot.Z), ("⛑ Hay alguien atrapado entre los escombros en %s%s"):format(spot.Name, if afterRaid then " (tras el bombardeo: paga extra)" else ""))
end

local function ingenieroStart(player: Player, shift: Shift)
	local recent = nil
	pcall(function()
		recent = service("TefraService").recentRaid()
	end)
	shift.Extra = if recent then 1.5 else nil
	go(player, shift, "Bloques", P(TefraJobs.BlockYard[1], TefraJobs.BlockYard[2]), "🧱 Coge bloques de basalto en el patio de la Forja")
end

local STARTS = {
	TefraFundidor = fundidorStart,
	TefraDesactivador = desactivadorStart,
	TefraBombero = bomberoStart,
	TefraCorreo = correoStart,
	GalaxiaRescatista = rescatistaStart,
	GalaxiaIngeniero = ingenieroStart,
}

nextTask = function(player: Player, shift: Shift)
	shift.Started = now()
	shift.Busy = false
	shift.Extra = nil
	shift.Score = nil
	clearVisuals(shift)
	local start = STARTS[shift.JobId]
	if start then
		start(player, shift)
	end
end

-- El puzle de los cables (desactivador): una conversación con la pista y tres cables
local function cablePuzzle(player: Player, shift: Shift, onDone: (boolean) -> ())
	local puzzle = TefraJobs.cablePuzzle(math.floor(os.clock() * 1000) % 100000 + player.UserId)
	local options = {}
	for i, w in puzzle.Wires do
		table.insert(options, { T = ("Cortar el cable %s"):format(w), Effects = { Wire = i } })
	end
	local cut = nil
	shift.Busy = true
	local ok = pcall(function()
		service("DialogueService").play(player, {
			Staging = false,
			Lines = {
				{ S = "Narrador", T = ("La bomba tiene tres cables, de izquierda a derecha: %s, %s y %s."):format(puzzle.Wires[1], puzzle.Wires[2], puzzle.Wires[3]) },
				{ S = "Narrador", T = ("Grabado en la carcasa, la pista de los desactivadores: «%s»"):format(puzzle.Clue) },
				{ Ask = "¿Qué cable cortas?", Options = options },
			},
		}, {
			apply = function(effects)
				if type(effects) == "table" and type(effects.Wire) == "number" then
					cut = effects.Wire
				end
			end,
		}, function()
			shift.Busy = false
			onDone(cut == puzzle.Answer)
		end, function()
			shift.Busy = false
			shift.PhaseAt = now()
		end)
	end)
	if not ok then
		shift.Busy = false
		onDone(true)
	end
end

-- Una pieza que se ve mientras dura el encargo
local function bombModel(shift: Shift, at: Vector3)
	piece(shift, { Name = "BombaSinExplotar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 1.4, 1.4), CFrame = CFrame.new(at + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0.6, 0.2), Color = Color3.fromRGB(70, 76, 62), Material = Enum.Material.CorrodedMetal })
	local light = piece(shift, { Name = "Piloto", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(at + Vector3.new(0, 1.2, 0)), Color = Color3.fromRGB(255, 40, 40), Material = Enum.Material.Neon })
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 60, 40)
	pl.Range = 8
	pl.Brightness = 2
	pl.Parent = light
end

local function coladaModel(shift: Shift, at: Vector3)
	local blob = piece(shift, { Name = "Colada", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 2.2, 9), CFrame = CFrame.new(at), Color = Color3.fromRGB(255, 120, 30), Material = Enum.Material.Neon })
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 130, 40)
	pl.Range = 22
	pl.Brightness = 2.5
	pl.Parent = blob
	shift.Data.Hot = at
end

local function rubbleModel(shift: Shift, at: Vector3)
	for k = 0, 4 do
		piece(shift, { Name = "Escombro", Size = Vector3.new(2.4, 1.2 + (k % 2), 1.8), CFrame = CFrame.new(at + Vector3.new(math.cos(k * 1.7) * 2.2, 0.6, math.sin(k * 1.7) * 2.2)) * CFrame.Angles(0.3 * k, k, 0.2), Color = Color3.fromRGB(80, 72, 76), Material = Enum.Material.Basalt })
	end
end

-- Llegar al objetivo de la fase actual
local function arrive(player: Player, shift: Shift)
	local id, phase = shift.JobId, shift.Phase
	local d = shift.Data
	if id == "TefraFundidor" then
		local f = d.F
		if phase == "Cargar" then
			carry(player, shift)
			go(player, shift, "Crisol", P(f.Crucible[1], f.Crucible[2]), "🔥 Echa el mineral al crisol y controla la temperatura")
		elseif phase == "Crisol" then
			playGame(player, shift, function(score, won)
				shift.Score = if won then score else score * 0.5
				if not won then
					toast(player, "Info", "La colada sale con burbujas: valdrá menos. ¡A los moldes igualmente!")
				end
				go(player, shift, "Molde", P(f.Molds[1], f.Molds[2]), "🔥 Cuela el metal en los moldes")
			end)
		elseif phase == "Molde" then
			complete(player, shift, shift.Score or 0.5)
		end
	elseif id == "TefraDesactivador" then
		local b = d.B
		if phase == "Bomba" then
			cablePuzzle(player, shift, function(right)
				if shifts[player] ~= shift then
					return
				end
				if not right then
					fail(player, shift, "💥 ¡Cable equivocado! La bomba explota (sin heridas: solo el susto y la ceniza).", true)
					return
				end
				playGame(player, shift, function(score, won)
					if not won then
						fail(player, shift, "💥 ¡Te ha temblado el pulso! La bomba explota (sin heridas).", true)
						return
					end
					shift.Score = score
					clearVisuals(shift)
					carry(player, shift)
					go(player, shift, "Polvorin", P(TefraJobs.Polvorin[1], TefraJobs.Polvorin[2]), "💣 Lleva la carcasa vacía al polvorín del Cuartel de la Muralla")
				end)
			end)
		elseif phase == "Polvorin" then
			complete(player, shift, shift.Score or 0.5)
		end
	elseif id == "TefraBombero" then
		local c = d.C
		if phase == "Aviso" then
			coladaModel(shift, P(c.X, c.Z))
			d.Barrier = 1
			d.Deadline = now() + TefraJobs.BarrierSeconds
			local q = c.Barriers[1]
			go(player, shift, "Barreras", P(q[1], q[2]), ("🧱 Pon la barrera de basalto 1 de 3 (%d s)"):format(TefraJobs.BarrierSeconds))
		elseif phase == "Barreras" then
			local q = c.Barriers[d.Barrier]
			piece(shift, { Name = "Barrera", Size = Vector3.new(6, 3.2, 1.6), CFrame = CFrame.new(P(q[1], q[2]) + Vector3.new(0, 1.6, 0)), Color = Color3.fromRGB(46, 42, 48), Material = Enum.Material.Basalt, CanCollide = true })
			d.Barrier += 1
			if d.Barrier <= #c.Barriers then
				local nq = c.Barriers[d.Barrier]
				local left = math.max(0, math.ceil((d.Deadline or now()) - now()))
				go(player, shift, "Barreras", P(nq[1], nq[2]), ("🧱 Pon la barrera de basalto %d de %d (%d s)"):format(d.Barrier, #c.Barriers, left))
			else
				go(player, shift, "Enfriar", P(c.X, c.Z), "💦 Enfría la colada con agua a presión")
			end
		elseif phase == "Enfriar" then
			playGame(player, shift, function(score, won)
				d.Hot = nil
				complete(player, shift, if won then score else score * 0.6)
			end)
		end
	elseif id == "TefraCorreo" then
		if phase == "Saca" then
			carry(player, shift)
			local r = pickRng(player, shift)
			local t = TefraJobs.pick(TefraJobs.Tunnels, r)
			go(player, shift, "Tunel", P(t.X, t.Z), ("✉ Baja por %s sin que te vea la patrulla"):format(t.Name))
		elseif phase == "Tunel" then
			local r = pickRng(player, shift)
			local dest = TefraJobs.pick(TefraJobs.Deliveries, r)
			d.Dest = dest
			go(player, shift, "Entrega", P(dest.X, dest.Z), ("✉ Entrega las cartas en %s (evita las linternas de la patrulla)"):format(dest.Name))
		elseif phase == "Entrega" then
			complete(player, shift, 1)
		end
	elseif id == "GalaxiaRescatista" then
		local spot = d.R
		if phase == "Aviso" then
			rubbleModel(shift, P(spot.X, spot.Z))
			playGame(player, shift, function(score, won)
				shift.Score = if won then score else score * 0.6
				clearVisuals(shift)
				carry(player, shift)
				go(player, shift, "Hospital", P(TefraJobs.HospitalDoor[1], TefraJobs.HospitalDoor[2]), "⛑ Lleva a la persona rescatada al Campus Nilda")
			end)
		elseif phase == "Hospital" then
			complete(player, shift, shift.Score or 0.6)
		end
	elseif id == "GalaxiaIngeniero" then
		if phase == "Bloques" then
			carry(player, shift)
			local r = pickRng(player, shift)
			local w, i = TefraJobs.pick(TefraJobs.WallRepairs, r, d.Wall)
			d.Wall = i
			d.W = w
			go(player, shift, "Muralla", P(w.X, w.Z), ("🧱 Repara el tramo dañado de %s"):format(w.Name))
		elseif phase == "Muralla" then
			removeCarry(shift)
			playGame(player, shift, function(score, won)
				complete(player, shift, if won then score else score * 0.6)
			end)
		end
	end
end
TefraJobService._arrive = arrive

-- Patrullas del correo (linternas que van y vienen por su calle)
local function ensurePatrols()
	if #patrolParts > 0 and patrolParts[1].Parent then
		return
	end
	table.clear(patrolParts)
	for _, route in TefraJobs.Patrols do
		local p = piece(nil, { Name = "Patrulla", Size = Vector3.new(2, 5, 2), Color = Color3.fromRGB(60, 66, 56), Material = Enum.Material.Fabric, CFrame = CFrame.new(P(route.Points[1][1], route.Points[1][2]) + Vector3.new(0, 2.5, 0)) })
		local lamp = Instance.new("SpotLight")
		lamp.Color = Color3.fromRGB(255, 230, 170)
		lamp.Range = 18
		lamp.Angle = 70
		lamp.Brightness = 3
		lamp.Face = Enum.NormalId.Front
		lamp.Parent = p
		table.insert(patrolParts, p)
	end
end

local function movePatrols(t: number)
	for i, route in TefraJobs.Patrols do
		local p = patrolParts[i]
		if p and p.Parent then
			local x, z = TefraJobs.patrolAt(route, t)
			local x2, z2 = TefraJobs.patrolAt(route, t + 0.3)
			local at = P(x, z) + Vector3.new(0, 2.5, 0)
			local dir = Vector3.new(x2 - x, 0, z2 - z)
			p.CFrame = if dir.Magnitude > 1e-3 then CFrame.lookAt(at, at + dir) else CFrame.new(at)
		end
	end
end

local function removePatrols()
	for _, p in patrolParts do
		pcall(function()
			p:Destroy()
		end)
	end
	table.clear(patrolParts)
end

-- Lo que calienta cerca de los oficios (TefraService): los crisoles y las coladas activas
function TefraJobService.hotSpots(): { Vector3 }
	local out = {}
	for _, f in TefraJobs.Foundries do
		table.insert(out, P(f.Crucible[1], f.Crucible[2]))
	end
	for _, shift in shifts do
		if shift.Data.Hot then
			table.insert(out, shift.Data.Hot)
		end
	end
	return out
end

---------------------------------------------------------------------
-- Empezar y dejar el turno
---------------------------------------------------------------------
function TefraJobService.start(player: Player, jobId: string): boolean
	local job = TefraJobs.Jobs[jobId]
	if not job or not dataOf(player) then
		return false
	end
	if player:GetAttribute("Planeta") ~= Tefra.Id then
		toast(player, "Error", "Este oficio es de Tefra: el tablón está en Bastión Ceniza.")
		return false
	end
	local allowed = true
	pcall(function()
		allowed = service("LifeService").allows(player, "Work")
	end)
	if not allowed then
		return false
	end
	local canWork = true
	pcall(function()
		canWork = service("NeedsService").canWork(player)
	end)
	if not canWork then
		toast(player, "Error", "Te falta energía o tienes demasiada hambre para trabajar.")
		return false
	end
	-- Dejar el trabajo de antes (de Valmar o de Tefra) sin avisos
	if player:GetAttribute("Job") ~= nil then
		pcall(function()
			service("JobService").quit(player, true)
		end)
	end
	local old = shifts[player]
	if old then
		removeCarry(old)
		clearVisuals(old)
	end
	local shift: Shift = { JobId = jobId, Phase = "", Target = nil, Text = "", Started = now(), PhaseAt = now(), Busy = false, Data = {}, Visuals = {} }
	shifts[player] = shift
	player:SetAttribute("Job", jobId)
	nextTask(player, shift)
	showRank(player, jobId)
	local _, rank = TefraJobs.rankFor(TefraJobService.points(player, jobId))
	toast(player, "Success", ("%s ¡Ya trabajas de %s (%s)! Sigue la línea azul."):format(job.Icon, job.Name, rank.Name))
	if jobId == "TefraCorreo" then
		ensurePatrols()
	end
	return true
end

function TefraJobService.quit(player: Player, silent: boolean?)
	local shift = shifts[player]
	if not shift then
		return
	end
	shifts[player] = nil
	removeCarry(shift)
	clearVisuals(shift)
	if shift.Data.InGame then
		-- (solo el minijuego del oficio: uno de la historia sigue)
		pcall(function()
			service("MiniGameService").cancel(player, "Quit")
		end)
	end
	if TefraJobs.isTefraJob(player:GetAttribute("Job")) then
		player:SetAttribute("Job", nil)
		player:SetAttribute("Rank", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	if not silent then
		toast(player, "Info", "Has dejado el trabajo.")
	end
	local anyCorreo = false
	for _, s in shifts do
		anyCorreo = anyCorreo or s.JobId == "TefraCorreo"
	end
	if not anyCorreo then
		removePatrols()
	end
end

function TefraJobService.shiftOf(player: Player): Shift?
	return shifts[player]
end

-- Cada cuarto de segundo: llegadas, el reloj de las barreras y las patrullas del correo
function TefraJobService._tick()
	local t = now()
	if #patrolParts > 0 then
		movePatrols(t)
	end
	for player, shift in shifts do
		local ok, err = pcall(function()
			if not player.Parent then
				shifts[player] = nil
				return
			end
			-- Si se va de Tefra, deja el oficio
			if player:GetAttribute("Planeta") ~= Tefra.Id then
				TefraJobService.quit(player, true)
				toast(player, "Info", "Has dejado tu oficio de Tefra al salir del planeta.")
				return
			end
			if shift.Busy then
				return
			end
			local root = rootOf(player)
			if not root or not shift.Target then
				return
			end
			-- Bombero: las barreras tienen reloj
			if shift.JobId == "TefraBombero" and shift.Phase == "Barreras" and shift.Data.Deadline and t > shift.Data.Deadline then
				shift.Data.Hot = nil
				fail(player, shift, "🌋 La colada se ha comido el camino antes de cerrar las barreras. ¡Otra vez, más rápido!")
				return
			end
			-- Correo: las patrullas
			if shift.JobId == "TefraCorreo" and (shift.Phase == "Tunel" or shift.Phase == "Entrega") and t - shift.PhaseAt > TefraJobService.CorreoGrace then
				local lx, lz = Tefra.toLocal(root.Position)
				local seen = TefraJobs.seenBy(t, lx, lz, TefraJobs.curfew(GameClock.hour()))
				if seen then
					local Inventory = service("InventoryService")
					if Inventory.count(player, "PapelesTefra") > 0 then
						if not shift.Data.Waved then
							shift.Data.Waved = true
							toast(player, "Info", "🪪 «¿Papeles? …Pasa, pasa.» La patrulla mira tus papeles de Bastión y te deja seguir.")
						end
					else
						shift.Data.Waved = nil
						removeCarry(shift)
						service("DataService").spend(player, TefraJobs.CaughtFine)
						toast(player, "Error", ("🔦 ¡Alto! La patrulla de %s te ha visto: te requisa las cartas y te multa con %d €. Vuelve a la estafeta."):format(seen, TefraJobs.CaughtFine))
						streaks[player] = nil
						nextTask(player, shift)
						return
					end
				end
			end
			-- Desactivador: el detector marca el sitio exacto al acercarte
			if shift.JobId == "TefraDesactivador" and shift.Phase == "Detectar" then
				local b = shift.Data.B
				local exact = P(b.X, b.Z, b.Out)
				local off = root.Position - exact
				if Vector3.new(off.X, 0, off.Z).Magnitude <= TefraJobs.DetectRadius then
					bombModel(shift, exact)
					go(player, shift, "Bomba", exact, "💣 ¡Pi-pi-pi! Ahí está. Acércate y desactívala")
				end
				return
			end
			local offset = root.Position - shift.Target
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= TefraJobService.Reach and math.abs(offset.Y) < 14 then
				arrive(player, shift)
			end
		end)
		if not ok then
			warn("[TefraJobService] " .. tostring(err))
		end
	end
end

-- (pruebas)
TefraJobService._shifts = shifts
function TefraJobService._reset()
	for player in table.clone(shifts) do
		TefraJobService.quit(player, true)
	end
	table.clear(history)
	table.clear(streaks)
	table.clear(chispaTimes)
end

function TefraJobService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local JobService = service("JobService")
	for _, jobId in TefraJobs.Order do
		JobService.setHandler(jobId, {
			Start = function(player: Player)
				TefraJobService.start(player, jobId)
			end,
			Quit = function(player: Player, silent: boolean?)
				TefraJobService.quit(player, silent)
			end,
		})
	end
	Players.PlayerRemoving:Connect(function(player)
		TefraJobService.quit(player, true)
		history[player] = nil
		streaks[player] = nil
		chispaTimes[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(TefraJobService.Tick)
			TefraJobService._tick()
		end
	end)
end

return TefraJobService
