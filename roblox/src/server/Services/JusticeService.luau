-- JusticeService: juicios, condenas y prisión (reglas en shared/Justice).
--
-- Al detenerte (WantedService.arrest) se abre tu caso:
--   * Con un/a juez de servicio: te llevan al banquillo del Palacio de Justicia y el juez recibe
--     el caso en su panel (absolver, multa, o multa y prisión de 1 a 10 minutos). Cobra y suma
--     puntos por cada caso. Si no decide a tiempo, sentencia automática.
--   * Sin juez: sentencia automática según las estrellas.
-- En prisión (Centro Penitenciario): la condena corre con el reloj real (también desconectado,
-- porque se guarda la hora de salida). Si sales del recinto, te devuelven a tu celda. Trabajar en
-- la lavandería, la cocina o el patio reduce la condena. El/la Director/a de la prisión o el/la
-- Presidente/a del Tribunal pueden dejarte en libertad (comando LIBERAR a tu lado).
-- Cada condena queda en tus antecedentes (data.Record).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Justice = require(ReplicatedStorage.Shared.Justice)
local Format = require(ReplicatedStorage.Shared.Format)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)
local DataService = require(script.Parent.DataService)
local JobService = require(script.Parent.JobService)
local SceneService = require(script.Parent.SceneService)
local CareerService = require(script.Parent.CareerService)

local JusticeService = {}

type Case = { Id: number, Accused: Player, Judge: Player?, Stars: number, Crimes: { string }, Done: boolean }

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent
local cases: { [number]: Case } = {}
local nextCase = 0
local nextCell = 0
local workAt: { [Player]: number } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function tagged(tag: string): BasePart?
	local list = CollectionService:GetTagged(tag)
	return list[1]
end

local function insideBox(box: BasePart, position: Vector3): boolean
	local rel = box.CFrame:PointToObjectSpace(position)
	local half = box.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
end

local function anchor(player: Player, on: boolean)
	local root = rootOf(player)
	if root then
		root.Anchored = on
	end
end

function JusticeService.isJailed(player: Player): boolean
	return player:GetAttribute("JailUntil") ~= nil
end

---------------------------------------------------------------------
-- Prisión
---------------------------------------------------------------------
local function sendToCell(player: Player)
	local cellsList = CollectionService:GetTagged("PrisonCell")
	if #cellsList == 0 then
		return
	end
	nextCell = nextCell % #cellsList + 1
	local cell = cellsList[nextCell] :: BasePart
	SceneService.teleportTo(player, cell.Position)
end

local function release(player: Player, how: string?)
	local data = DataService.get(player)
	if data then
		data.Jail = nil
	end
	player:SetAttribute("JailUntil", nil)
	workAt[player] = nil
	local exit = tagged("PrisonExit")
	if exit and player.Parent then
		SceneService.teleportTo(player, exit.Position)
	end
	Remote:FireClient(player, "Released", { How = how })
	StoryEvents.emit(player, "Released", {})
end

function JusticeService.imprison(player: Player, seconds: number, reason: string?)
	local data = DataService.get(player)
	if not data or seconds <= 0 then
		return
	end
	local untilTime = os.time() + math.floor(seconds)
	data.Jail = { Until = untilTime, Reason = reason }
	player:SetAttribute("JailUntil", untilTime)
	if player:GetAttribute("Job") then
		JobService.quit(player, true)
	end
	sendToCell(player)
	StoryEvents.emit(player, "Imprisoned", { Seconds = seconds })
	-- Los funcionarios de servicio reciben al nuevo preso
	for _, guard in Players:GetPlayers() do
		if guard:GetAttribute("Job") == "Funcionario" then
			Notify:FireClient(guard, "Info", ("⛓ Ingresa en prisión: %s (%d min)"):format(player.DisplayName, math.ceil(seconds / 60)))
			CareerService.addPoints(guard, "Prisiones", "Inmate")
		end
	end
end

-- Trabajo dentro de la prisión: reduce la condena
local function setupWork(station: Instance)
	if not station:IsA("BasePart") or station:FindFirstChild("PrisonWorkPrompt") then
		return
	end
	local work = station:GetAttribute("Work") or "Trabajar"
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PrisonWorkPrompt"
	prompt.ActionText = "Trabajar"
	prompt.ObjectText = "⛓ " .. work
	prompt.HoldDuration = 2.5
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("JailedOnly", true) -- (solo lo ven los presos; JobPrompts)
	prompt.Parent = station
	prompt.Triggered:Connect(function(player)
		local data = DataService.get(player)
		if not data or not data.Jail then
			return
		end
		if os.clock() - (workAt[player] or -math.huge) < Justice.WorkCooldown then
			Notify:FireClient(player, "Error", "Descansa un momento antes de seguir.")
			return
		end
		workAt[player] = os.clock()
		local remaining = Justice.afterWork(data.Jail.Until - os.time())
		data.Jail.Until = os.time() + remaining
		player:SetAttribute("JailUntil", data.Jail.Until)
		Notify:FireClient(player, "Success", ("⛓ %s: -%d s de condena"):format(work, Justice.WorkReduction))
	end)
end

---------------------------------------------------------------------
-- Sentencias y juicios
---------------------------------------------------------------------
local function record(player: Player, entry: { [string]: any })
	local data = DataService.get(player)
	if not data then
		return
	end
	data.Record = data.Record or {}
	table.insert(data.Record, entry)
	while #data.Record > Justice.RecordLimit do
		table.remove(data.Record, 1)
	end
	player:SetAttribute("Records", #data.Record)
end

local function sentence(player: Player, fine: number, seconds: number, kind: string, judge: Player?, crimes: { string })
	local data = DataService.get(player)
	local paid = math.min(fine, if data then data.Money else 0)
	if paid > 0 then
		DataService.addMoney(player, -paid)
	end
	record(player, { Time = os.time(), Crimes = crimes, Fine = paid, Seconds = seconds, Verdict = kind, Judge = judge and judge.DisplayName })
	Remote:FireClient(player, "Sentence", { Kind = kind, Fine = paid, Seconds = seconds, Judge = judge and judge.DisplayName })
	StoryEvents.emit(player, "Sentenced", { Kind = kind, Seconds = seconds })
	if seconds > 0 then
		JusticeService.imprison(player, seconds, table.concat(crimes, ", "))
	else
		-- Absuelto o solo multa: sale del juzgado (o de la comisaría) libre
		local exit = tagged("CourtDock")
		if exit and judge then
			SceneService.teleportTo(player, (exit.CFrame * CFrame.new(0, 0, -16)).Position)
		end
	end
end

local function closeCase(case: Case, kind: string, minutes: number?)
	if case.Done then
		return
	end
	case.Done = true
	cases[case.Id] = nil
	anchor(case.Accused, false)
	case.Accused:SetAttribute("OnTrial", nil)
	if not case.Accused.Parent then
		return
	end
	local fine, seconds
	if kind == "Auto" then
		fine, seconds = Justice.automatic(case.Stars)
	else
		fine, seconds = Justice.verdict(kind, case.Stars, minutes)
	end
	local judge = case.Judge
	if judge and judge.Parent and kind ~= "Auto" then
		DataService.addMoney(judge, Justice.JudgePay, true)
		Notify:FireClient(judge, "Money", ("⚖ Caso cerrado: +%s"):format(Format.money(Justice.JudgePay)))
		CareerService.addPoints(judge, "Justicia", "Case")
		StoryEvents.emit(judge, "JobTaskDone", { JobId = "Juez", Pay = Justice.JudgePay })
		Remote:FireClient(judge, "CaseClosed", { Id = case.Id })
	end
	sentence(case.Accused, fine, seconds, kind, if kind ~= "Auto" then judge else nil, case.Crimes)
end

-- Un/a juez de servicio libre (sin otro caso abierto)
local function freeJudge(except: Player): Player?
	for _, judge in Players:GetPlayers() do
		if judge ~= except and judge:GetAttribute("Job") == "Juez" then
			local busy = false
			for _, case in cases do
				if case.Judge == judge then
					busy = true
				end
			end
			if not busy then
				return judge
			end
		end
	end
	return nil
end

-- Lo llama WantedService al detener a alguien
function JusticeService.process(player: Player, stars: number, crimes: { string })
	local judge = freeJudge(player)
	if not judge then
		local fine, seconds = Justice.automatic(stars)
		Notify:FireClient(player, "Info", "⚖ No hay juez de guardia: sentencia automática.")
		task.delay(3, function()
			if player.Parent then
				sentence(player, fine, seconds, "Auto", nil, crimes)
			end
		end)
		return
	end
	nextCase += 1
	local case: Case = { Id = nextCase, Accused = player, Judge = judge, Stars = stars, Crimes = crimes, Done = false }
	cases[case.Id] = case
	player:SetAttribute("OnTrial", true)
	task.delay(3, function()
		-- Al juzgado: el acusado al banquillo y el juez al estrado
		local dock, bench = tagged("CourtDock"), tagged("CourtJudge")
		if dock and player.Parent then
			SceneService.teleportTo(player, dock.Position)
			task.wait(0.4)
			anchor(player, true)
		end
		if bench and judge.Parent then
			SceneService.teleportTo(judge, bench.Position)
		end
		Remote:FireClient(player, "Trial", { Judge = judge.DisplayName, Seconds = Justice.TrialSeconds })
		Remote:FireClient(judge, "Case", {
			Id = case.Id,
			Accused = player.DisplayName,
			Stars = stars,
			Crimes = crimes,
			Records = player:GetAttribute("Records") or 0,
			Seconds = Justice.TrialSeconds,
			MaxMinutes = Justice.MaxMinutes,
		})
	end)
	task.delay(3 + Justice.TrialSeconds, function()
		if not case.Done then
			if judge.Parent then
				Notify:FireClient(judge, "Error", "⚖ Se acabó el tiempo: el caso se resolvió con la sentencia automática.")
			end
			closeCase(case, "Auto")
		end
	end)
end

-- Libertad anticipada: el/la director/a de la prisión o el/la presidente/a del tribunal
local function grantRelease(boss: Player, target: any)
	if typeof(target) ~= "Instance" or not target:IsA("Player") or not JusticeService.isJailed(target) then
		return
	end
	local allowed = (boss:GetAttribute("Job") == "Funcionario" and CareerService.isChief(boss, "Prisiones"))
		or (boss:GetAttribute("Job") == "Juez" and CareerService.isChief(boss, "Justicia"))
	if not allowed then
		Notify:FireClient(boss, "Error", "Solo el/la Director/a de la prisión o el/la Presidente/a del Tribunal pueden hacerlo.")
		return
	end
	local a, b = rootOf(boss), rootOf(target)
	if not a or not b or (a.Position - b.Position).Magnitude > 10 then
		return
	end
	Notify:FireClient(boss, "Success", ("Has concedido la libertad a %s."):format(target.DisplayName))
	release(target, "Libertad concedida por " .. boss.DisplayName)
end

function JusticeService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Justice") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Justice"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player: Player, kind: any, a: any, b: any, c: any)
		if kind == "Verdict" and type(a) == "number" then
			local case = cases[a]
			if case and case.Judge == player and (b == "Absolver" or b == "Multa" or b == "Prision") then
				closeCase(case, b, if type(c) == "number" then c else nil)
			end
		elseif kind == "Release" then
			grantRelease(player, a)
		end
	end)

	for _, station in CollectionService:GetTagged("PrisonWork") do
		setupWork(station)
	end
	CollectionService:GetInstanceAddedSignal("PrisonWork"):Connect(setupWork)

	-- Al volver al juego con condena pendiente: a tu celda
	DataService.onLoaded(function(player, data)
		data.Record = data.Record or {}
		player:SetAttribute("Records", #data.Record)
		local jail = data.Jail
		if type(jail) ~= "table" or type(jail.Until) ~= "number" then
			data.Jail = nil
			return
		end
		player:SetAttribute("JailUntil", jail.Until)
		local deadline = os.clock() + 12
		while player.Parent and not player:GetAttribute("SpawnReady") and os.clock() < deadline do
			task.wait(0.2)
		end
		if player.Parent and os.time() < jail.Until then
			sendToCell(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		workAt[player] = nil
		for _, case in cases do
			if case.Accused == player then
				-- Se fue en mitad del juicio: sentencia automática (se guarda al salir)
				closeCase(case, "Auto")
			elseif case.Judge == player then
				case.Judge = nil
				closeCase(case, "Auto")
			end
		end
	end)

	-- Vigilancia de los presos: cumplir la condena o volver a la celda si salen del recinto
	task.spawn(function()
		while true do
			task.wait(1)
			local area = tagged("PrisonArea")
			for _, player in Players:GetPlayers() do
				local untilTime = player:GetAttribute("JailUntil")
				if type(untilTime) == "number" then
					if os.time() >= untilTime then
						Notify:FireClient(player, "Success", "🔓 Has cumplido tu condena. Eres libre.")
						release(player, "Condena cumplida")
					else
						local root = rootOf(player)
						if area and root and not insideBox(area, root.Position) and not player:GetAttribute("OnTrial") then
							Notify:FireClient(player, "Error", "⛓ No puedes salir de la prisión hasta cumplir tu condena.")
							sendToCell(player)
						end
					end
				end
			end
		end
	end)
end

return JusticeService
