-- MarJobService (servidor): los OFICIOS del mar de la fase 1 (shared/Sea/MarJobs; docs/mar/civilizacion-marina.md).
--
-- Como los oficios de Tefra (TefraJobService): el tablón «Trabajar» de siempre (JobService.setupBoard con
-- Config.Jobs; aquí cada oficio tiene su propio sistema: JobService.setHandler), los atributos que pintan el
-- HUD y el GPS (Job, TaskTarget, TaskText), el botón de dejar el trabajo (JobService.quit), la paga
-- (DataService.addMoney con el VIP de MonetizationService), la energía (NeedsService), la carrera en
-- data.Careers[IdDelOficio] = { Points, Tasks } y los avisos a la historia (JobTaskDone y MarJobDone).
--   🌿 MarCultivador  Sembrar (bancal) → Caracoles (cesta de Tomé) → Cosechar (el mismo bancal) → Lonja
--   🔆 MarFarolero    tres perlas-farola del paseo (se encienden al llegar) → volver al tablón
-- El servidor comprueba las llegadas (nunca se fía del cliente), el tiempo mínimo y el tope por hora.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local GameClock = require(Shared.GameClock)
local Nacara = require(Shared.Sea.Nacara)
local Civ = require(Shared.Sea.Civ)
local MarJobs = require(Shared.Sea.MarJobs)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local MarJobService = {}

MarJobService.Tick = 0.25
MarJobService.Reach = 8 -- studs en planta para «has llegado»
MarJobService.ReachY = 18 -- y en altura (se nada por encima)

local function service(name: string): any
	return require(script.Parent[name])
end

type Shift = { JobId: string, Phase: number, Target: Vector3?, Text: string, Started: number, ArrivedAt: number?, Data: { [string]: any } }
local shifts: { [Player]: Shift } = {}
local history: { [Player]: { [string]: { number } } } = {}
local streaks: { [Player]: { Job: string, N: number } } = {}
local notify: RemoteEvent? = nil

MarJobService.Clock = os.clock
local function now(): number
	return MarJobService.Clock()
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function dataOf(player: Player): { [string]: any }?
	return service("DataService").get(player)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Dónde está cada sitio del oficio (en el mundo)
function MarJobService.point(kind: string, shift: Shift?): Vector3
	if kind == "Bed" then
		local b = Civ.Beds[(shift and shift.Data.Bed) or 1]
		return Nacara.toWorld(b.X, b.Z, 2)
	elseif kind == "Basket" then
		return Nacara.toWorld(Civ.Basket.X, Civ.Basket.Z, 2)
	elseif kind == "Lonja" then
		return Nacara.domeCenter() + Vector3.new(0, 2, 0)
	elseif kind == "Board" then
		local b = Civ.Boards[(shift and shift.JobId) or "MarFarolero"]
		return Nacara.toWorld(b.X, b.Z, 2)
	end
	for _, l in Civ.Lamps do
		if l.Id == kind then
			return Nacara.toWorld(l.X, l.Z, 9)
		end
	end
	return Nacara.centerPosition()
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

function MarJobService.points(player: Player, jobId: string): number
	local entry = careerEntry(player, jobId)
	return entry and entry.Points or 0
end

local function publish(player: Player, shift: Shift)
	player:SetAttribute("TaskTarget", shift.Target)
	player:SetAttribute("TaskText", shift.Text)
end

local function go(player: Player, shift: Shift, target: Vector3, text: string)
	shift.Target = target
	shift.Text = text
	shift.ArrivedAt = nil
	publish(player, shift)
end

-- Un encargo nuevo (el primero o el siguiente)
local function nextTask(player: Player, shift: Shift)
	shift.Started = now()
	shift.Phase = 1
	shift.Data = {}
	if shift.JobId == "MarCultivador" then
		shift.Data.Bed = math.random(1, #Civ.Beds)
		local phase = MarJobs.Jobs.MarCultivador.Phases[1]
		go(player, shift, MarJobService.point(phase.At, shift), phase.Text)
	else
		local ids = {}
		for _, l in Civ.Lamps do
			table.insert(ids, l.Id)
		end
		shift.Data.Lamps = MarJobs.pickLamps(ids, MarJobs.Jobs.MarFarolero.Lamps, os.time() + player.UserId)
		go(player, shift, MarJobService.point(shift.Data.Lamps[1]), ("🔆 Carga la perla-farola marcada (1/%d)"):format(#shift.Data.Lamps))
	end
end

-- Cobrar un encargo. Devuelve lo cobrado (0 si no cuenta)
function MarJobService.finish(player: Player, jobId: string, started: number, extra: number?): number
	local job = MarJobs.Jobs[jobId]
	local entry = careerEntry(player, jobId)
	if not job or not entry then
		return 0
	end
	local t = now()
	history[player] = history[player] or {}
	local list = history[player][jobId] or {}
	history[player][jobId] = list
	local ok, why = MarJobs.allowed(jobId, list, started, t)
	if not ok then
		toast(player, "Error", "⏱ " .. tostring(why) .. ": este encargo no se paga.")
		return 0
	end
	table.insert(list, t)
	while #list > MarJobs.MaxPerHour + 5 do
		table.remove(list, 1)
	end
	local st = streaks[player]
	if st and st.Job == jobId then
		st.N += 1
	else
		st = { Job = jobId, N = 1 }
		streaks[player] = st
	end
	local before = MarJobs.rankFor(entry.Points)
	local pay = MarJobs.pay(jobId, entry.Points, st.N, extra)
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
		service("NeedsService").change(player, 0, -((Config.Jobs[jobId] and Config.Jobs[jobId].EnergyCost) or 3))
	end)
	entry.Points += 1
	entry.Tasks += 1
	local after, rank = MarJobs.rankFor(entry.Points)
	player:SetAttribute("Career_" .. jobId, entry.Points)
	toast(player, "Money", ("+%s · %s %s"):format(Format.money(pay), job.Icon, job.Name))
	if after > before then
		toast(player, "Success", ("⭐ ¡Ascenso! Ahora eres %s de %s"):format(rank.Name, job.Name))
		StoryEvents.emit(player, "Promoted", { Institution = jobId, Rank = rank.Id })
	end
	pcall(function()
		service("SeaCivService").addRep(player, "Consejo", 1)
	end)
	StoryEvents.emit(player, "JobTaskDone", { JobId = jobId, Pay = pay })
	StoryEvents.emit(player, "MarJobDone", { JobId = jobId, Any = true })
	return pay
end

-- Has llegado al sitio de la fase (lo comprueba el tick)
local function arrive(player: Player, shift: Shift)
	if shift.JobId == "MarCultivador" then
		local phases = MarJobs.Jobs.MarCultivador.Phases
		local phase = phases[shift.Phase]
		if phase.Hold > 0 then
			shift.ArrivedAt = shift.ArrivedAt or now()
			if now() - shift.ArrivedAt < phase.Hold then
				player:SetAttribute("TaskText", phase.Text .. " · quédate un momento…")
				return
			end
		end
		if shift.Phase >= #phases then
			MarJobService.finish(player, shift.JobId, shift.Started)
			nextTask(player, shift)
			return
		end
		shift.Phase += 1
		local nextPhase = phases[shift.Phase]
		go(player, shift, MarJobService.point(nextPhase.At, shift), nextPhase.Text)
	else
		local lamps = shift.Data.Lamps
		if shift.Phase <= #lamps then
			shift.Data.Lit = (shift.Data.Lit or 0) + 1
			toast(player, "Info", ("🔆 Perla-farola cargada (%d/%d)"):format(shift.Data.Lit, #lamps))
			shift.Phase += 1
			if shift.Phase <= #lamps then
				go(player, shift, MarJobService.point(lamps[shift.Phase]), ("🔆 Carga la perla-farola marcada (%d/%d)"):format(shift.Phase, #lamps))
			else
				go(player, shift, MarJobService.point("Board", shift), "🔆 Vuelve al tablón de los faroleros a cobrar")
			end
			return
		end
		local hour = 12
		pcall(function()
			hour = GameClock.hour()
		end)
		local extra = if MarJobs.night(hour) then 1.25 else 1
		MarJobService.finish(player, shift.JobId, shift.Started, extra)
		nextTask(player, shift)
	end
end
MarJobService._arrive = arrive

---------------------------------------------------------------------
-- Empezar y dejar el turno
---------------------------------------------------------------------
function MarJobService.start(player: Player, jobId: string): boolean
	local job = MarJobs.Jobs[jobId]
	if not job or not dataOf(player) then
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
	local shift: Shift = { JobId = jobId, Phase = 1, Text = "", Started = now(), Data = {} }
	shifts[player] = shift
	player:SetAttribute("Job", jobId)
	nextTask(player, shift)
	local points = MarJobService.points(player, jobId)
	local _, rank = MarJobs.rankFor(points)
	player:SetAttribute("Career_" .. jobId, points)
	task.delay(0.15, function()
		if player.Parent and player:GetAttribute("Job") == jobId then
			player:SetAttribute("Rank", rank.Name)
		end
	end)
	toast(player, "Success", ("%s ¡Ya trabajas de %s (%s)! Sigue la línea azul."):format(job.Icon, job.Name, rank.Name))
	return true
end

function MarJobService.quit(player: Player, silent: boolean?)
	if not shifts[player] then
		return
	end
	shifts[player] = nil
	if MarJobs.isMarJob(player:GetAttribute("Job")) then
		player:SetAttribute("Job", nil)
		player:SetAttribute("Rank", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	if not silent then
		toast(player, "Info", "Has dejado el trabajo.")
	end
end

function MarJobService.shiftOf(player: Player): Shift?
	return shifts[player]
end

function MarJobService._tick()
	for player, shift in shifts do
		local ok, err = pcall(function()
			if not player.Parent then
				shifts[player] = nil
				return
			end
			local root = rootOf(player)
			if not root or not shift.Target then
				return
			end
			local offset = root.CFrame.Position - shift.Target
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= MarJobService.Reach and math.abs(offset.Y) < MarJobService.ReachY then
				arrive(player, shift)
			else
				shift.ArrivedAt = nil
			end
		end)
		if not ok then
			warn("[MarJobService] " .. tostring(err))
		end
	end
end

function MarJobService._reset()
	table.clear(shifts)
	table.clear(history)
	table.clear(streaks)
end

function MarJobService.init()
	notify = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Notify") :: RemoteEvent?
	local JobService = service("JobService")
	for _, jobId in MarJobs.Order do
		JobService.setHandler(jobId, {
			Start = function(player: Player)
				MarJobService.start(player, jobId)
			end,
			Quit = function(player: Player, silent: boolean?)
				MarJobService.quit(player, silent)
			end,
		})
	end
	Players.PlayerRemoving:Connect(function(player)
		MarJobService.quit(player, true)
		history[player] = nil
		streaks[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(MarJobService.Tick)
			MarJobService._tick()
		end
	end)
end

return MarJobService
