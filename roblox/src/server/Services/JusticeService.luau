-- JusticeService: juicios, condenas y prisión (reglas en shared/Justice).
--
-- Al detenerte (WantedService.arrest) se abre tu caso:
--   * Con un/a juez de servicio: te llevan al banquillo del Palacio de Justicia y el juez recibe
--     el caso en su panel (absolver, multa, o multa y prisión de 1 a 10 minutos). Cobra y suma
--     puntos por cada caso. Si no decide a tiempo, sentencia automática.
--   * Sin juez: sentencia automática según las estrellas.
-- En prisión (Centro Penitenciario): la condena corre con el reloj real (también desconectado,
-- porque se guarda la hora de salida). Si sales del recinto, te devuelven a tu celda. Lo que se
-- puede hacer dentro (trabajos, deporte, estudios, túnel…) está en PrisonService. El/la Director/a de la prisión o el/la
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
local InteriorService = require(script.Parent.InteriorService)
local DialogueService = require(script.Parent.DialogueService)

local JusticeService = {}

type Case = { Id: number, Accused: Player, Judge: Player?, Stars: number, Crimes: { string }, Done: boolean, InCourt: boolean? }

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote: RemoteEvent
local cases: { [number]: Case } = {}
local nextCase = 0
local nextCell = 0

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

-- Cambia lo que queda de condena (negativo = menos). Devuelve los segundos que quedan.
function JusticeService.adjust(player: Player, seconds: number): number
	local data = DataService.get(player)
	local jail = data and data.Jail
	if type(jail) ~= "table" then
		return 0
	end
	jail.Until = math.max(os.time(), jail.Until + math.floor(seconds))
	player:SetAttribute("JailUntil", jail.Until)
	return jail.Until - os.time()
end

function JusticeService.jailData(player: Player): { [string]: any }?
	local data = DataService.get(player)
	return data and type(data.Jail) == "table" and data.Jail or nil
end

function JusticeService.isJailed(player: Player): boolean
	return player:GetAttribute("JailUntil") ~= nil
end

---------------------------------------------------------------------
-- Prisión
---------------------------------------------------------------------
function JusticeService.sendToCell(player: Player)
	local cellsList = CollectionService:GetTagged("PrisonCell")
	if #cellsList == 0 then
		return
	end
	nextCell = nextCell % #cellsList + 1
	local cell = cellsList[nextCell] :: BasePart
	SceneService.teleportTo(player, cell.Position)
end

function JusticeService.release(player: Player, how: string?)
	local data = DataService.get(player)
	if data then
		data.Jail = nil
	end
	player:SetAttribute("JailUntil", nil)
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
	data.Jail = { Until = untilTime, Reason = reason, Tunnel = 0, Course = 0 }
	player:SetAttribute("JailUntil", untilTime)
	if player:GetAttribute("Job") then
		JobService.quit(player, true)
	end
	JusticeService.sendToCell(player)
	StoryEvents.emit(player, "Imprisoned", { Seconds = seconds })
	-- Los funcionarios de servicio reciben al nuevo preso
	for _, guard in Players:GetPlayers() do
		if guard:GetAttribute("Job") == "Funcionario" then
			Notify:FireClient(guard, "Info", ("⛓ Ingresa en prisión: %s (%d min)"):format(player.DisplayName, math.ceil(seconds / 60)))
			CareerService.addPoints(guard, "Prisiones", "Inmate")
		end
	end
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

-- Lo que queda apuntado de una sentencia: la multa, los antecedentes y la condena en la partida
-- (data.Jail). Va aparte para que se guarde ya, aunque salgas del juego antes de ir a la celda.
local function charge(player: Player, fine: number, seconds: number, kind: string, judge: Player?, crimes: { string }): number
	local data = DataService.get(player)
	local paid = math.min(fine, if data then data.Money else 0)
	if paid > 0 then
		DataService.addMoney(player, -paid)
	end
	record(player, { Time = os.time(), Crimes = crimes, Fine = paid, Seconds = seconds, Verdict = kind, Judge = judge and judge.DisplayName })
	if data then
		data.Jail = if seconds > 0 then { Until = os.time() + math.floor(seconds), Reason = table.concat(crimes, ", "), Tunnel = 0, Course = 0 } else nil
	end
	return paid
end

-- Se le comunica la sentencia y se cumple (a la celda, o sale libre)
local function announce(player: Player, paid: number, seconds: number, kind: string, judge: Player?, crimes: { string }, inCourt: boolean?)
	Remote:FireClient(player, "Sentence", { Kind = kind, Fine = paid, Seconds = seconds, Judge = judge and judge.DisplayName })
	StoryEvents.emit(player, "Sentenced", { Kind = kind, Seconds = seconds })
	if seconds > 0 then
		JusticeService.imprison(player, seconds, table.concat(crimes, ", "))
	else
		-- Absuelto o solo multa: sale libre del juzgado a la calle, por su puerta (la sala está en el
		-- cielo: antes se quedaba dentro, y sin juez no se le movía). Sin juicio, sigue donde estaba.
		if inCourt and player:GetAttribute("InteriorKey") then
			InteriorService.leave(player)
		end
	end
end

local function sentence(player: Player, fine: number, seconds: number, kind: string, judge: Player?, crimes: { string }, inCourt: boolean?)
	announce(player, charge(player, fine, seconds, kind, judge, crimes), seconds, kind, judge, crimes, inCourt)
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
	-- Absolver no se paga (si no, un juez y un amigo buscado podrían hacer caja sin fin)
	if judge and judge.Parent and kind ~= "Auto" and kind ~= "Absolver" then
		DataService.addMoney(judge, Justice.JudgePay, true)
		Notify:FireClient(judge, "Money", ("⚖ Caso cerrado: +%s"):format(Format.money(Justice.JudgePay)))
		CareerService.addPoints(judge, "Justicia", "Case")
		StoryEvents.emit(judge, "JobTaskDone", { JobId = "Juez", Pay = Justice.JudgePay })
	end
	if judge and judge.Parent and kind ~= "Auto" then
		Remote:FireClient(judge, "CaseClosed", { Id = case.Id })
	end
	sentence(case.Accused, fine, seconds, kind, if kind ~= "Auto" then judge else nil, case.Crimes, case.InCourt)
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
	-- Si le detienen hablando, la conversación se corta (si no, se quedan los controles y la
	-- cámara bloqueados). La historia la trata como un corte: se repetirá al salir.
	pcall(DialogueService.cancel, player, "Arrested")
	local judge = freeJudge(player)
	if not judge then
		local fine, seconds = Justice.automatic(stars)
		Notify:FireClient(player, "Info", "⚖ No hay juez de guardia: sentencia automática.")
		-- Se apunta ya (si sales del juego en estos segundos, la condena se guarda igual);
		-- la espera es solo para que se vea la pantalla de detenido
		local paid = charge(player, fine, seconds, "Auto", nil, crimes)
		-- Mientras se tramita cuenta como "en juicio": así la historia (y lo demás) no lo mueve
		-- de sitio antes de que llegue a la celda
		player:SetAttribute("OnTrial", true)
		task.delay(3, function()
			player:SetAttribute("OnTrial", nil)
			if player.Parent then
				announce(player, paid, seconds, "Auto", nil, crimes)
			end
		end)
		return
	end
	nextCase += 1
	local case: Case = { Id = nextCase, Accused = player, Judge = judge, Stars = stars, Crimes = crimes, Done = false }
	cases[case.Id] = case
	player:SetAttribute("OnTrial", true)
	-- Mientras dura el juicio queda apuntada la condena automática: si te vas, se guarda con la
	-- partida (el veredicto del juez la cambia o la quita)
	local data = DataService.get(player)
	local _, provisional = Justice.automatic(stars)
	if data and provisional > 0 then
		data.Jail = { Until = os.time() + math.floor(provisional), Reason = table.concat(crimes, ", "), Tunnel = 0, Course = 0 }
	end
	task.delay(3, function()
		if case.Done then
			return -- (ya sentenciado: se fue el juez o el acusado)
		end
		-- Al juzgado: el acusado al banquillo y el juez al estrado
		local dock, bench = tagged("CourtDock"), tagged("CourtJudge")
		-- (con la llave y la puerta del juzgado: si no, "Salir" no sabe adónde y queda la de antes)
		if dock and player.Parent then
			case.InCourt = true
			InteriorService.placeAt(player, dock)
			task.wait(0.4)
			if case.Done then
				return
			end
			anchor(player, true)
		end
		if bench and judge.Parent then
			InteriorService.placeAt(judge, bench)
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

-- Si muere en pleno juicio, reaparece en el banquillo (sin pasar por el hospital ni pagar).
-- Devuelve true si se ocupa de él (está en juicio). Si aún no ha llegado a la sala, ya le lleva
-- allí el juicio en marcha.
function JusticeService.returnToDock(player: Player): boolean
	if not player:GetAttribute("OnTrial") then
		return false
	end
	for _, case in cases do
		if case.Accused == player and not case.Done then
			local dock = tagged("CourtDock")
			if case.InCourt and dock and player.Parent then
				InteriorService.placeAt(player, dock)
				task.delay(0.4, function()
					if not case.Done and player:GetAttribute("OnTrial") then
						anchor(player, true)
					end
				end)
			end
			return true
		end
	end
	return false -- (sentencia automática en trámite: no hay banquillo)
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
	JusticeService.release(target, "Libertad concedida por " .. boss.DisplayName)
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
			-- (minutos raros —NaN o infinito— no valen)
			local bad = type(c) == "number" and (c ~= c or math.abs(c) == math.huge)
			if case and case.Judge == player and not bad and (b == "Absolver" or b == "Multa" or b == "Prision") then
				closeCase(case, b, if type(c) == "number" then c else nil)
			end
		elseif kind == "Release" then
			grantRelease(player, a)
		end
	end)


	-- Al volver al juego con condena pendiente: a tu celda
	DataService.onLoaded(function(player, data)
		data.Record = data.Record or {}
		player:SetAttribute("Records", #data.Record)
		local jail = data.Jail
		if type(jail) ~= "table" or type(jail.Until) ~= "number" then
			data.Jail = nil
			return
		end
		-- La condena solo corre mientras juegas: se corre el tiempo que estuvo desconectado (antes
		-- salir del juego un rato era cumplirla entera)
		local away = if DataService.offlineSeconds then DataService.offlineSeconds(player) else 0
		if away > 0 then
			jail.Until += away
		end
		player:SetAttribute("JailUntil", jail.Until)
		local deadline = os.clock() + 12
		while player.Parent and not player:GetAttribute("SpawnReady") and os.clock() < deadline do
			task.wait(0.2)
		end
		if player.Parent and os.time() < jail.Until then
			JusticeService.sendToCell(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
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
				-- Un preso con error no para la vigilancia del resto
				local ok, err = pcall(function()
					local untilTime = player:GetAttribute("JailUntil")
					if type(untilTime) == "number" then
						if os.time() >= untilTime then
							Notify:FireClient(player, "Success", "🔓 Has cumplido tu condena. Eres libre.")
							JusticeService.release(player, "Condena cumplida")
						else
							local root = rootOf(player)
							if area and root and not insideBox(area, root.Position) and not player:GetAttribute("OnTrial") then
								Notify:FireClient(player, "Error", "⛓ No puedes salir de la prisión hasta cumplir tu condena.")
								JusticeService.sendToCell(player)
							end
						end
					end
				end)
				if not ok then
					warn("[JusticeService] " .. tostring(err))
				end
			end
		end
	end)
end

return JusticeService
