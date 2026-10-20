-- PlanetJobService (servidor): los OFICIOS de los planetas hechos con datos (marco común de los planetas,
-- docs/planetas/marco-planetas.md; datos y cuentas en shared/Cosmos/PlanetJobs). Tefra lleva los suyos a
-- mano (Services/TefraJobService); este servicio lleva los de los DEMÁS planetas.
--
-- Reutiliza lo de siempre, como TefraJobService: el tablón «Trabajar» (JobService.setHandler: cada oficio
-- tiene su propio sistema), los atributos que pinta el HUD y el GPS (Job, TaskTarget, TaskText, Rank), el
-- botón de dejar el trabajo, los minijuegos (MiniGameService), la paga (DataService.addMoney con el VIP de
-- MonetizationService), la energía (NeedsService), el aviso JobTaskDone a la historia y la carrera en
-- data.Careers[IdDelOficio] = { Points, Tasks, Local = { [planeta] = n } }.
--
-- Un encargo es la lista de fases que da el oficio (job.task): Go (ir a un sitio, a veces llevando algo),
-- Game (un minijuego: su nota sube la paga), Hold (quedarse un rato junto al sitio). Al acabar la última,
-- se cobra (con tiempo mínimo y tope por hora: PlanetJobs.allowed) y empieza el siguiente encargo. El
-- servidor comprueba las distancias (nunca se fía del cliente). Si sales del planeta, dejas el oficio.
-- API: start(player, jobId) · quit(player, silent?) · finish(player, jobId, score, opts) · shiftOf(player)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Items = require(Shared.Items)
local PlanetJobs = require(Shared.Cosmos.PlanetJobs)
local PlanetRegistry = require(Shared.Cosmos.PlanetRegistry)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local PlanetJobService = {}

PlanetJobService.Tick = 0.25
PlanetJobService.Reach = 7

type Shift = {
	JobId: string,
	Planet: string,
	Phases: { { [string]: any } },
	Index: number,
	Target: Vector3?,
	Text: string,
	Started: number,
	PhaseAt: number,
	Busy: boolean,
	Scores: { number },
	Seed: number,
	Carry: BasePart?,
	InGame: boolean?,
}
local shifts: { [Player]: Shift } = {}
local history: { [Player]: { [string]: { number } } } = {}
local streaks: { [Player]: { Job: string, N: number } } = {}
local chispaTimes: { [Player]: { number } } = {}
local notify: RemoteEvent? = nil
local random = Random.new()

PlanetJobService.Clock = os.clock
local function now(): number
	return PlanetJobService.Clock()
end

local function service(name: string): any
	return require(script.Parent[name])
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

-- Un punto local del planeta → posición del mundo (en el barrio o, Out, en el suelo del planeta)
function PlanetJobService.worldPoint(S: any, lx: number, lz: number, out: boolean?): Vector3
	local wx, wz = S.Origin.X + lx, S.Origin.Z + lz
	if out then
		return Vector3.new(wx, (S.groundAt(wx, wz)) + 1, wz)
	end
	return Vector3.new(wx, S.Origin.Y + S.padY() + 1, wz)
end

local function removeCarry(shift: Shift)
	if shift.Carry then
		pcall(function()
			(shift.Carry :: BasePart):Destroy()
		end)
		shift.Carry = nil
	end
end

local function carry(player: Player, shift: Shift, color: Color3?)
	removeCarry(shift)
	local root = rootOf(player)
	local job = Config.Jobs[shift.JobId]
	if not root then
		return
	end
	pcall(function()
		local item = Instance.new("Part")
		item.Name = "CarriedItem"
		item.Size = (job and job.CarrySize) or Vector3.new(1.4, 1.2, 1.2)
		item.Color = color or (job and job.CarryColor) or Color3.fromRGB(150, 150, 150)
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

function PlanetJobService.points(player: Player, jobId: string): number
	local entry = careerEntry(player, jobId)
	return entry and entry.Points or 0
end

local function showRank(player: Player, jobId: string)
	local points = PlanetJobService.points(player, jobId)
	local _, rank = PlanetJobs.rankFor(points)
	player:SetAttribute("Career_" .. jobId, points)
	task.delay(0.15, function()
		if player.Parent and player:GetAttribute("Job") == jobId then
			player:SetAttribute("Rank", rank.Name)
		end
	end)
end

-- Cobrar un encargo: paga, progreso, material, Chispas y el aviso a la historia. Devuelve lo cobrado.
function PlanetJobService.finish(player: Player, jobId: string, score: number, opts: { [string]: any }?): number
	local job = PlanetJobs.Jobs[jobId]
	local entry = careerEntry(player, jobId)
	if not job or not entry then
		return 0
	end
	local o = opts or {}
	local t = now()
	history[player] = history[player] or {}
	local list = history[player][jobId] or {}
	history[player][jobId] = list
	local ok, why = PlanetJobs.allowed(jobId, list, o.Started or (t - job.MinSeconds), t)
	if not ok then
		toast(player, "Error", "⏱ " .. tostring(why) .. ": este encargo no se paga.")
		return 0
	end
	table.insert(list, t)
	while #list > PlanetJobs.MaxPerHour + 5 do
		table.remove(list, 1)
	end
	local st = streaks[player]
	if st and st.Job == jobId then
		st.N += 1
	else
		st = { Job = jobId, N = 1 }
		streaks[player] = st
	end
	local beforeRank = PlanetJobs.rankFor(entry.Points)
	local pay = PlanetJobs.pay(jobId, entry.Points, score, st.N, o.Extra)
	local mult = 1
	pcall(function()
		mult = service("MonetizationService").payMultiplier(player)
	end)
	pay = math.floor(pay * mult + 0.5)
	service("DataService").addMoney(player, pay, true)
	local data = dataOf(player)
	if data and type(data.Stats) == "table" then
		data.Stats.TasksDone = (tonumber(data.Stats.TasksDone) or 0) + 1
	end
	pcall(function()
		service("NeedsService").change(player, 0, -(job.EnergyCost or 3))
	end)
	entry.Points += PlanetJobs.points(score)
	entry.Tasks += 1
	entry.Local = if type(entry.Local) == "table" then entry.Local else {}
	entry.Local[job.Planet] = (tonumber(entry.Local[job.Planet]) or 0) + 1
	local afterRank, rank = PlanetJobs.rankFor(entry.Points)
	toast(player, "Money", ("+%s · %s %s"):format(Format.money(pay), job.Icon, job.Name))
	if afterRank > beforeRank then
		toast(player, "Success", ("⭐ ¡Ascenso! Ahora eres %s de %s"):format(rank.Name, job.Name))
		StoryEvents.emit(player, "Promoted", { Institution = jobId, Rank = rank.Id })
	end
	if job.Drop and random:NextNumber() < job.Drop.Chance then
		pcall(function()
			service("InventoryService").add(player, job.Drop.Item, 1)
		end)
		local it = Items.get(job.Drop.Item)
		if it then
			toast(player, "Info", ("Te llevas %s %s"):format(it.Icon, it.Name))
		end
	end
	if job.Chispas and score > 0 then
		local times = chispaTimes[player] or {}
		chispaTimes[player] = times
		local recent = 0
		for _, ct in times do
			if t - ct < 3600 then
				recent += 1
			end
		end
		if recent < PlanetJobs.ChispasPerHour then
			table.insert(times, t)
			pcall(function()
				local sp = service("SpaceService").spaceData(player)
				if sp then
					sp.Chispas = (tonumber(sp.Chispas) or 0) + job.Chispas
				end
			end)
		end
	end
	StoryEvents.emit(player, "JobTaskDone", { JobId = jobId, Pay = pay, Planet = job.Planet })
	if player:GetAttribute("Job") == jobId then
		showRank(player, jobId)
	end
	return pay
end

---------------------------------------------------------------------
-- Las fases
---------------------------------------------------------------------
local enter: (Player, Shift) -> ()

local function newTask(player: Player, shift: Shift)
	removeCarry(shift)
	shift.Seed += 1
	local rankIndex = PlanetJobs.rankFor(PlanetJobService.points(player, shift.JobId))
	shift.Phases = PlanetJobs.task(shift.JobId, shift.Seed * 131 + (player.UserId % 9973), rankIndex)
	shift.Index = 1
	shift.Scores = {}
	shift.Started = now()
	enter(player, shift)
end

local function complete(player: Player, shift: Shift)
	removeCarry(shift)
	local total, n = 0, 0
	for _, s in shift.Scores do
		total += s
		n += 1
	end
	local score = if n > 0 then total / n else 1
	PlanetJobService.finish(player, shift.JobId, score, { Started = shift.Started })
	local okWork = true
	pcall(function()
		okWork = service("NeedsService").canWork(player)
	end)
	if not okWork then
		PlanetJobService.quit(player, true)
		toast(player, "Error", "Te has quedado sin energía. Come algo o duerme antes de seguir trabajando.")
		return
	end
	task.delay(0.5, function()
		if shifts[player] == shift then
			newTask(player, shift)
		end
	end)
end

local function advance(player: Player, shift: Shift)
	shift.Index += 1
	if shift.Index > #shift.Phases then
		complete(player, shift)
	else
		enter(player, shift)
	end
end
PlanetJobService._advance = advance

local function playGame(player: Player, shift: Shift, spec: { [string]: any })
	shift.Busy = true
	shift.InGame = true
	local started = false
	pcall(function()
		started = service("MiniGameService").start(player, spec, function(result)
			shift.Busy = false
			shift.InGame = nil
			if shifts[player] ~= shift then
				return
			end
			local rounds = spec.Rounds or 3
			table.insert(shift.Scores, math.clamp((tonumber(result and result.Score) or 0) / rounds, 0, 1))
			advance(player, shift)
		end, function()
			-- (cortado: se repite al volver a pasar por el sitio)
			shift.Busy = false
			shift.InGame = nil
			shift.PhaseAt = now()
		end)
	end)
	if not started then
		shift.Busy = false
		shift.InGame = nil
		table.insert(shift.Scores, 0.5)
		advance(player, shift) -- (nunca bloquear el oficio)
	end
end

function enter(player: Player, shift: Shift)
	local S = PlanetRegistry.get(shift.Planet)
	local phase = shift.Phases[shift.Index]
	if not S or not phase then
		return
	end
	shift.PhaseAt = now()
	if phase.Kind == "Go" or phase.Kind == "Hold" then
		local at = phase.At or { 0, 0 }
		shift.Target = PlanetJobService.worldPoint(S, at[1], at[2], phase.Out)
		shift.Text = phase.Text or "Ve al sitio marcado"
		player:SetAttribute("TaskTarget", shift.Target)
		player:SetAttribute("TaskText", shift.Text)
		if phase.Carry then
			carry(player, shift, if typeof(phase.Carry) == "Color3" then phase.Carry else nil)
		end
		if phase.Drop then
			removeCarry(shift)
		end
	elseif phase.Kind == "Game" then
		-- (el minijuego empieza al llegar; si la fase es solo un minijuego, aquí mismo)
		shift.Text = phase.Text or (phase.Spec and phase.Spec.Title) or "¡Ahora!"
		player:SetAttribute("TaskText", shift.Text)
		playGame(player, shift, phase.Spec or PlanetJobs.timing("Trabajo", "⭐", "", 1))
	end
end

---------------------------------------------------------------------
-- Empezar y dejar el turno
---------------------------------------------------------------------
function PlanetJobService.start(player: Player, jobId: string): boolean
	local job = PlanetJobs.Jobs[jobId]
	if not job or not dataOf(player) then
		return false
	end
	if player:GetAttribute("Planeta") ~= job.Planet then
		toast(player, "Error", ("Este oficio es de %s: su tablón está allí."):format(job.PlanetName or job.Planet))
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
	if player:GetAttribute("Job") ~= nil then
		pcall(function()
			service("JobService").quit(player, true)
		end)
	end
	local old = shifts[player]
	if old then
		removeCarry(old)
	end
	local shift: Shift = { JobId = jobId, Planet = job.Planet, Phases = {}, Index = 1, Target = nil, Text = "", Started = now(), PhaseAt = now(), Busy = false, Scores = {}, Seed = (player.UserId % 977) + 3 }
	shifts[player] = shift
	player:SetAttribute("Job", jobId)
	newTask(player, shift)
	showRank(player, jobId)
	local _, rank = PlanetJobs.rankFor(PlanetJobService.points(player, jobId))
	toast(player, "Success", ("%s ¡Ya trabajas de %s (%s)! Sigue la línea azul."):format(job.Icon, job.Name, rank.Name))
	return true
end

function PlanetJobService.quit(player: Player, silent: boolean?)
	local shift = shifts[player]
	if not shift then
		return
	end
	shifts[player] = nil
	removeCarry(shift)
	if shift.InGame then
		pcall(function()
			service("MiniGameService").cancel(player, "Quit")
		end)
	end
	if PlanetJobs.isPlanetJob(player:GetAttribute("Job")) then
		player:SetAttribute("Job", nil)
		player:SetAttribute("Rank", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	if not silent then
		toast(player, "Info", "Has dejado el trabajo.")
	end
end

function PlanetJobService.shiftOf(player: Player): Shift?
	return shifts[player]
end

function PlanetJobService._tick()
	local t = now()
	for player, shift in shifts do
		local ok, err = pcall(function()
			if not player.Parent then
				shifts[player] = nil
				return
			end
			if player:GetAttribute("Planeta") ~= shift.Planet then
				PlanetJobService.quit(player, true)
				toast(player, "Info", "Has dejado tu oficio al salir del planeta.")
				return
			end
			if shift.Busy then
				return
			end
			local phase = shift.Phases[shift.Index]
			local root = rootOf(player)
			if not phase or not root or not shift.Target then
				return
			end
			local offset = root.Position - shift.Target
			local here = Vector3.new(offset.X, 0, offset.Z).Magnitude <= PlanetJobService.Reach and math.abs(offset.Y) < 14
			if phase.Kind == "Go" and here then
				if phase.Game then
					playGame(player, shift, phase.Game)
				else
					advance(player, shift)
				end
			elseif phase.Kind == "Hold" then
				if not here then
					shift.PhaseAt = t
				elseif t - shift.PhaseAt >= (phase.Seconds or 4) then
					advance(player, shift)
				end
			end
		end)
		if not ok then
			warn("[PlanetJobService] " .. tostring(err))
		end
	end
end

PlanetJobService._shifts = shifts
function PlanetJobService._reset()
	for player in table.clone(shifts) do
		PlanetJobService.quit(player, true)
	end
	table.clear(history)
	table.clear(streaks)
	table.clear(chispaTimes)
end

function PlanetJobService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	-- (cargar los planetas registra sus oficios: PlanetJobs.register desde cada módulo)
	PlanetRegistry.surfaces()
	local JobService = service("JobService")
	for _, jobId in PlanetJobs.Order do
		JobService.setHandler(jobId, {
			Start = function(player: Player)
				PlanetJobService.start(player, jobId)
			end,
			Quit = function(player: Player, silent: boolean?)
				PlanetJobService.quit(player, silent)
			end,
		})
	end
	Players.PlayerRemoving:Connect(function(player)
		PlanetJobService.quit(player, true)
		history[player] = nil
		streaks[player] = nil
		chispaTimes[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(PlanetJobService.Tick)
			PlanetJobService._tick()
		end
	end)
end

return PlanetJobService
