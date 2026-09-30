-- SeasonMissionService: misiones del pase de temporada (diarias, semanales, de temporada, de evento
-- y la historia de temporada por fases). Se cumplen JUGANDO NORMAL: escuchan los mismos avisos que
-- ya mandan los sistemas del juego (StoryEvents: JobTaskDone, RodeMetro, ZoneEntered…), que les pasa
-- BattlePassXPService. No hay que ir a ningún sitio especial ni pulsar nada para empezar.
--   * Diarias (3) y semanales (5): se eligen igual en todos los servidores a partir de la fecha (UTC)
--     y de la edad del personaje (a un niño no le tocan misiones de trabajo). Se renuevan a las 00:00
--     UTC y el lunes. Al completarse dan su XP sola (no hay que reclamarla).
--   * De temporada: a tu ritmo durante las 9 semanas.
--   * Historia «Se apaga el faro»: fases en orden (ir a un barrio, coger el metro, trabajar…) y una
--     decisión final. Al terminarla, un título de recuerdo.
--   * GPS: «Seguir» una misión con sitio (Place) pone el atributo SeasonTarget (TaskMarker lo dibuja).
--   * Comodidad premium «Cambio de misión diaria»: cambia 1 diaria al día (no da más XP).
-- Datos: data.BattlePass.Missions = { Daily, Weekly, Season, Story, Event, Tracked }.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local DataService = require(script.Parent.DataService)
local Season = require(script.Parent.BattlePassSeasonService)
local Rewards = require(script.Parent.BattlePassRewardService)
local SeasonMath = require(script.Parent.Parent.BattlePass.SeasonMath)
local Telemetry = require(script.Parent.Parent.BattlePass.Telemetry)

local SeasonMissionService = {}

local MAX_KM_PER_EVENT = 50 -- (un viaje no cuenta más de esto: por si llega un número raro)

-- El núcleo del pase (cargado al usarlo: él también nos carga a nosotros)
local function core(): any
	return require(script.Parent.BattlePassService)
end

local function notify(player: Player, kind: string, text: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("Notify")
	if remote then
		(remote :: RemoteEvent):FireClient(player, kind, text)
	end
end

function SeasonMissionService.dayKey(now: number): number
	return SeasonMath.dayIndex(now)
end

---------------------------------------------------------------------
-- Qué misiones tocan
---------------------------------------------------------------------

local function stageOf(player: Player): string
	local stage = player:GetAttribute("LifeStage")
	return if type(stage) == "string" and Stages.isValid(stage) then stage else "Adulto"
end

local function eligible(pool: { { [string]: any } }, stage: string): { { [string]: any } }
	local list = {}
	for _, def in pool do
		if Stages.inRange(stage, def.MinStage or "Nino", def.MaxStage) then
			table.insert(list, def)
		end
	end
	return list
end

local function ids(list: { { [string]: any } }): { string }
	local out = {}
	for _, def in list do
		table.insert(out, def.Id)
	end
	return out
end

-- Busca una misión de la temporada por su Id (diaria, semanal, de temporada o de evento)
local function findDef(season: Season.Season, id: any): ({ [string]: any }?, string?)
	if type(id) ~= "string" then
		return nil, nil
	end
	local m = season.Missions or {}
	for _, kind in { "Daily", "Weekly", "Season" } do
		for _, def in m[kind] or {} do
			if def.Id == id then
				return def, kind
			end
		end
	end
	for _, event in season.Events or {} do
		if event.Mission and event.Mission.Id == id then
			return event.Mission, "Event"
		end
	end
	return nil, nil
end

local function sub(t: { [string]: any }, key: string): { [string]: any }
	if type(t[key]) ~= "table" then
		t[key] = {}
	end
	return t[key]
end

local function progOf(store: { [string]: any }, id: string): { [string]: any }
	local p = store[id]
	if type(p) ~= "table" then
		p = { P = 0, Done = false }
		store[id] = p
	end
	p.P = if type(p.P) == "number" and p.P == p.P then p.P else 0
	return p
end

-- Renueva diarias y semanales si ha cambiado el día / la semana
function SeasonMissionService.ensure(player: Player, bp: { [string]: any }, season: Season.Season, now: number)
	local m = bp.Missions
	local pools = season.Missions or {}
	local stage = stageOf(player)
	local daily = sub(m, "Daily")
	local day = SeasonMath.dayIndex(now)
	if daily.Key ~= day or type(daily.Ids) ~= "table" then
		m.Daily = {
			Key = day,
			Ids = ids(SeasonMath.pick(eligible(pools.Daily or {}, stage), pools.DailyCount or 3, season.Id .. ":D:" .. day)),
			Prog = {},
			Rerolls = 0,
		}
	end
	local weekly = sub(m, "Weekly")
	local week = SeasonMath.weekIndex(now)
	if weekly.Key ~= week or type(weekly.Ids) ~= "table" then
		m.Weekly = {
			Key = week,
			Ids = ids(SeasonMath.pick(eligible(pools.Weekly or {}, stage), pools.WeeklyCount or 5, season.Id .. ":W:" .. week)),
			Prog = {},
		}
	end
	sub(m.Daily, "Prog")
	sub(m.Weekly, "Prog")
	sub(m, "Season")
	sub(m, "Story")
	sub(m, "Event")
end

---------------------------------------------------------------------
-- Progreso
---------------------------------------------------------------------

local function matches(match: { [string]: any }?, payload: { [string]: any }): boolean
	if not match then
		return true
	end
	for key, want in match do
		local got = payload[key]
		if type(want) == "table" then
			if not table.find(want, got) then
				return false
			end
		elseif got ~= want then
			return false
		end
	end
	return true
end

local function listens(def: { [string]: any }, name: string, payload: { [string]: any }): boolean
	return type(def.Events) == "table" and table.find(def.Events, name) ~= nil and matches(def.Match, payload)
end

local function clearTarget(player: Player, bp: { [string]: any }, id: string)
	if bp.Missions.Tracked == id then
		bp.Missions.Tracked = nil
		player:SetAttribute("SeasonTarget", nil)
		player:SetAttribute("SeasonTargetName", nil)
	end
end

-- Suma el evento a una misión. Devuelve true si se acaba de completar.
local function advance(prog: { [string]: any }, def: { [string]: any }, name: string, payload: { [string]: any }): boolean
	if prog.Done then
		return false
	end
	local measure = def.Measure or "Count"
	if measure == "Km" then
		local km = tonumber(payload.Km) or 0
		if km ~= km or km <= 0 then
			return false
		end
		prog.P += math.min(km, MAX_KM_PER_EVENT)
	elseif measure == "Distinct" or measure == "DistinctEvent" then
		local value = if measure == "Distinct" then payload[def.DistinctField or ""] else name
		if value == nil then
			return false
		end
		local seen = if type(prog.Seen) == "table" then prog.Seen else {}
		prog.Seen = seen
		local key = tostring(value)
		if seen[key] then
			return false
		end
		seen[key] = true
		prog.P += 1
	else
		prog.P += 1
	end
	if prog.P >= def.Goal then
		prog.P = def.Goal
		prog.Done = true
		prog.Seen = nil -- (ya no hace falta guardarlo)
		return true
	end
	return false
end

local function completed(player: Player, bp: { [string]: any }, def: { [string]: any }, kind: string)
	local data = DataService.get(player)
	Telemetry.count("MissionDone", def.Id, player)
	clearTarget(player, bp, def.Id)
	local xp = math.max(0, math.floor(tonumber(def.Xp) or 0))
	if xp > 0 then
		core().addXp(player, xp, "Mission")
	end
	local tokens = math.max(0, math.floor(tonumber(def.Tokens) or 0))
	if tokens > 0 and data and type(data.Cosmetics) == "table" then
		data.Cosmetics.Tokens += tokens
		Rewards.sync(player)
	end
	local label = if kind == "Daily" then "Misión diaria" elseif kind == "Weekly" then "Misión semanal" elseif kind == "Event" then "Misión de evento" else "Misión de temporada"
	notify(player, "Success", ("✅ %s: «%s» · +%d XP de pase%s"):format(label, def.Title, xp, if tokens > 0 then (" · +%d 🪙"):format(tokens) else ""))
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("BattlePass")
	if remote then
		(remote :: RemoteEvent):FireClient(player, "MissionDone", { Id = def.Id, Kind = kind, Title = def.Title, Xp = xp, Tokens = tokens })
	end
end

-- Historia de temporada: fase actual de una cadena
local function storyState(bp: { [string]: any }, chain: { [string]: any }): { [string]: any }
	local store = bp.Missions.Story
	local st = store[chain.Id]
	if type(st) ~= "table" then
		st = { Phase = 1, P = 0, Done = false }
		store[chain.Id] = st
	end
	st.Phase = math.max(1, math.floor(tonumber(st.Phase) or 1))
	st.P = tonumber(st.P) or 0
	return st
end

local function finishStory(player: Player, bp: { [string]: any }, chain: { [string]: any }, st: { [string]: any }, season: Season.Season)
	st.Done = true
	Telemetry.count("StoryDone", chain.Id, player)
	if chain.Reward then
		Rewards.grant(player, chain.Reward, season.Id)
	end
	local data = DataService.get(player)
	local tokens = math.max(0, math.floor(tonumber(chain.Tokens) or 0))
	if tokens > 0 and data and type(data.Cosmetics) == "table" then
		data.Cosmetics.Tokens += tokens
		Rewards.sync(player)
	end
	notify(player, "Success", ("🗼 Historia de temporada completada: «%s»%s"):format(chain.Title, if chain.Reward then (" · título «%s»"):format(chain.Reward.Name) else ""))
end

-- Pasa a la siguiente fase (o termina la historia)
local function nextPhase(player: Player, bp: { [string]: any }, chain: { [string]: any }, st: { [string]: any }, season: Season.Season, xp: number)
	local phase = chain.Phases[st.Phase]
	clearTarget(player, bp, chain.Id)
	Telemetry.count("StoryPhase", chain.Id .. ":" .. tostring(phase and phase.Id), player)
	if xp > 0 then
		core().addXp(player, xp, "Mission")
	end
	st.Phase += 1
	st.P = 0
	st.Seen = nil
	local upcoming = chain.Phases[st.Phase]
	if upcoming then
		notify(player, "Info", ("🗼 %s · %s: %s"):format(chain.Title, upcoming.Title, upcoming.Text))
	else
		finishStory(player, bp, chain, st, season)
	end
end

-- Un evento del juego (lo pasa BattlePassXPService). Avanza todas las misiones que lo escuchan.
function SeasonMissionService.onEvent(player: Player, name: string, payload: { [string]: any }?)
	local data = DataService.get(player)
	if not data or type(name) ~= "string" then
		return
	end
	local body = if type(payload) == "table" then payload else {}
	local bp, season = core().ensure(player, data)
	if not bp or not season then
		return
	end
	local now = Season.now(player)
	if not Season.earning(season, now) then
		return
	end
	local m = bp.Missions
	local changed = false
	for _, pair in { { "Daily", m.Daily }, { "Weekly", m.Weekly } } do
		local kind, box = pair[1], pair[2]
		for _, id in box.Ids do
			local def = findDef(season, id)
			if def and listens(def, name, body) then
				changed = true
				if advance(progOf(box.Prog, id), def, name, body) then
					completed(player, bp, def, kind)
				end
			end
		end
	end
	for _, def in (season.Missions or {}).Season or {} do
		if listens(def, name, body) and Stages.inRange(stageOf(player), def.MinStage or "Bebe", def.MaxStage) then
			changed = true
			if advance(progOf(m.Season, def.Id), def, name, body) then
				completed(player, bp, def, "Season")
			end
		end
	end
	for _, event in Season.activeEvents(season, now) do
		local def = event.Mission
		if def and listens(def, name, body) then
			changed = true
			if advance(progOf(m.Event, def.Id), def, name, body) then
				completed(player, bp, def, "Event")
			end
		end
	end
	for _, chain in (season.Missions or {}).Story or {} do
		local st = storyState(bp, chain)
		local phase = not st.Done and chain.Phases[st.Phase]
		if phase and not phase.Choices and listens(phase, name, body) then
			changed = true
			local tmp = { P = st.P, Seen = st.Seen, Done = false }
			local done = advance(tmp, phase, name, body)
			st.P, st.Seen = tmp.P, tmp.Seen
			if done then
				nextPhase(player, bp, chain, st, season, math.max(0, math.floor(tonumber(phase.Xp) or 0)))
			end
		end
	end
	if changed then
		core().push(player)
	end
end

---------------------------------------------------------------------
-- Acciones del jugador
---------------------------------------------------------------------

-- Decisión de la historia de temporada (fase con Choices)
function SeasonMissionService.choose(player: Player, chainId: any, optionId: any): (boolean, string?)
	local data = DataService.get(player)
	local bp, season = core().ensure(player, data)
	if not bp or not season or type(chainId) ~= "string" or type(optionId) ~= "string" then
		return false, "BadRequest"
	end
	if not Season.earning(season, Season.now(player)) then
		return false, "SeasonClosed"
	end
	for _, chain in (season.Missions or {}).Story or {} do
		if chain.Id == chainId then
			local st = storyState(bp, chain)
			local phase = not st.Done and chain.Phases[st.Phase]
			if not phase or not phase.Choices then
				return false, "Locked"
			end
			for _, option in phase.Choices do
				if option.Id == optionId then
					st.Choice = optionId
					if option.Result then
						notify(player, "Info", "🗼 " .. option.Result)
					end
					nextPhase(player, bp, chain, st, season, math.max(0, math.floor(tonumber(option.Xp) or 0)))
					return true
				end
			end
			return false, "BadRequest"
		end
	end
	return false, "BadRequest"
end

-- Cambia una misión diaria sin hacer por otra (comodidad premium, 1 al día)
function SeasonMissionService.reroll(player: Player, missionId: any): (boolean, string?)
	local data = DataService.get(player)
	local bp, season = core().ensure(player, data)
	if not data or not bp or not season or type(missionId) ~= "string" then
		return false, "BadRequest"
	end
	if not (type(data.Cosmetics) == "table" and data.Cosmetics.Perks.RerollDaily) then
		return false, "NoPerk"
	end
	local daily = bp.Missions.Daily
	local at = table.find(daily.Ids, missionId)
	if not at then
		return false, "BadRequest"
	end
	if (daily.Rerolls or 0) >= 1 then
		return false, "AlreadyRerolled"
	end
	local prog = daily.Prog[missionId]
	if type(prog) == "table" and prog.Done then
		return false, "AlreadyClaimed"
	end
	local avoid = {}
	local pools = season.Missions or {}
	local pool = eligible(pools.Daily or {}, stageOf(player))
	for _, def in pool do
		if table.find(daily.Ids, def.Id) then
			avoid[def] = true
		end
	end
	local picked = SeasonMath.pick(pool, 1, season.Id .. ":D:" .. tostring(daily.Key) .. ":R:" .. missionId, avoid)
	if #picked == 0 then
		return false, "BadRequest"
	end
	daily.Ids[at] = picked[1].Id
	daily.Prog[missionId] = nil
	daily.Rerolls = (daily.Rerolls or 0) + 1
	clearTarget(player, bp, missionId)
	Telemetry.count("Reroll", nil, player)
	return true
end

-- Sigue una misión en el GPS (nil = dejar de seguir). Solo las que tienen sitio (Place).
function SeasonMissionService.track(player: Player, missionId: any): (boolean, string?)
	local data = DataService.get(player)
	local bp, season = core().ensure(player, data)
	if not bp or not season then
		return false, "NoData"
	end
	if missionId == nil then
		bp.Missions.Tracked = nil
		player:SetAttribute("SeasonTarget", nil)
		player:SetAttribute("SeasonTargetName", nil)
		return true
	end
	local def = findDef(season, missionId)
	local place = def and def.Place
	local title = def and def.Title
	if not def then
		for _, chain in (season.Missions or {}).Story or {} do
			if chain.Id == missionId then
				local st = storyState(bp, chain)
				local phase = chain.Phases[st.Phase]
				place = phase and phase.Place
				title = phase and phase.Title
			end
		end
	end
	if type(place) ~= "string" then
		return false, "NoPlace"
	end
	local ok, spot = pcall(function()
		return require(script.Parent.LocationService).resolve(player, place)
	end)
	if not ok or not spot then
		return false, "NoPlace"
	end
	bp.Missions.Tracked = missionId
	player:SetAttribute("SeasonTarget", spot.Position)
	player:SetAttribute("SeasonTargetName", title)
	return true
end

---------------------------------------------------------------------
-- Estado para la interfaz
---------------------------------------------------------------------

local function view(def: { [string]: any }, kind: string, prog: { [string]: any }?, tracked: any): { [string]: any }
	local p = if prog then prog.P or 0 else 0
	return {
		Id = def.Id,
		Kind = kind,
		Title = def.Title,
		Description = def.Description,
		Icon = def.Icon,
		Progress = if def.Measure == "Km" then math.floor(p * 10) / 10 else math.floor(p),
		Goal = def.Goal,
		Unit = if def.Measure == "Km" then "km" else nil,
		Xp = def.Xp,
		Tokens = def.Tokens,
		Done = prog ~= nil and prog.Done == true,
		Place = def.Place,
		Tracked = tracked == def.Id,
	}
end

function SeasonMissionService.snapshot(player: Player, bp: { [string]: any }, season: Season.Season, now: number): { [string]: any }
	local m = bp.Missions
	local data = DataService.get(player)
	local out = {
		Daily = { ResetsAt = SeasonMath.nextDayAt(now), List = {} },
		Weekly = { ResetsAt = SeasonMath.nextWeekAt(now), List = {} },
		Season = { List = {} },
		Event = { List = {} },
		Story = {},
		Tracked = m.Tracked,
		CanReroll = data ~= nil and type(data.Cosmetics) == "table" and data.Cosmetics.Perks.RerollDaily == true and (m.Daily.Rerolls or 0) < 1,
	}
	for _, id in m.Daily.Ids or {} do
		local def = findDef(season, id)
		if def then
			table.insert(out.Daily.List, view(def, "Daily", m.Daily.Prog[id], m.Tracked))
		end
	end
	for _, id in m.Weekly.Ids or {} do
		local def = findDef(season, id)
		if def then
			table.insert(out.Weekly.List, view(def, "Weekly", m.Weekly.Prog[id], m.Tracked))
		end
	end
	local stage = stageOf(player)
	for _, def in (season.Missions or {}).Season or {} do
		if Stages.inRange(stage, def.MinStage or "Bebe", def.MaxStage) then
			table.insert(out.Season.List, view(def, "Season", m.Season[def.Id], m.Tracked))
		end
	end
	for _, event in Season.activeEvents(season, now) do
		if event.Mission then
			local v = view(event.Mission, "Event", m.Event[event.Mission.Id], m.Tracked)
			v.EventName = event.Name
			v.EndsAt = event.EndsAt
			table.insert(out.Event.List, v)
		end
	end
	for _, chain in (season.Missions or {}).Story or {} do
		local st = storyState(bp, chain)
		local phase = chain.Phases[st.Phase]
		local current = nil
		if phase and not st.Done then
			local choices = nil
			if phase.Choices then
				choices = {}
				for _, option in phase.Choices do
					table.insert(choices, { Id = option.Id, Text = option.Text })
				end
			end
			current = { Id = phase.Id, Title = phase.Title, Text = phase.Text, Progress = math.floor(st.P), Goal = phase.Goal, Xp = phase.Xp, Place = phase.Place, Choices = choices }
		end
		table.insert(out.Story, {
			Id = chain.Id,
			Title = chain.Title,
			Icon = chain.Icon,
			Intro = chain.Intro,
			Phase = math.min(st.Phase, #chain.Phases),
			Phases = #chain.Phases,
			Current = current,
			Done = st.Done == true,
			Choice = st.Choice,
			Tracked = m.Tracked == chain.Id,
			Reward = if chain.Reward then { Id = chain.Reward.Id, Name = chain.Reward.Name, Icon = chain.Reward.Icon } else nil,
		})
	end
	return out
end

function SeasonMissionService.init()
	-- (los eventos llegan por BattlePassXPService; las acciones, por el remoto de BattlePassService)
end

return SeasonMissionService
