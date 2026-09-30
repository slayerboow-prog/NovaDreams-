-- BattlePassXPService: XP del pase por jugar normal. No toca los demás sistemas: escucha el «tablón de
-- anuncios» que ya existe (StoryEvents: JobTaskDone, LessonCompleted, RodeMetro, VehicleTrip,
-- ZoneEntered…) y las misiones completadas de la historia de vida (LifeStoryService.observe).
--   * Cuánta XP da cada cosa: BattlePassConfig.Sources (y JobXp por oficio).
--   * Anti-abuso: hueco mínimo entre dos eventos de la misma fuente (MinGap), tope diario por fuente
--     (Cap) y tope diario de toda la actividad (DailyActivityCap). Los topes se guardan con el día
--     (data.BattlePass.Daily) para que salir y entrar no los reinicie. Los eventos los manda siempre el
--     servidor: el cliente no puede inventarse ninguno.
--   * Explorar: cada barrio da XP la primera vez en ESTA temporada (data.BattlePass.Zones).
--   * Eventos de temporada: multiplican la XP de actividad (tope BattlePassConfig.MaxEventMultiplier).
--   * Cada evento también avanza las misiones (SeasonMissionService.onEvent).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BPConfig = require(ReplicatedStorage.Shared.BattlePass.Config)
local DataService = require(script.Parent.DataService)
local Season = require(script.Parent.BattlePassSeasonService)
local BattlePassService = require(script.Parent.BattlePassService)
local Missions = require(script.Parent.SeasonMissionService)
local SeasonMath = require(script.Parent.Parent.BattlePass.SeasonMath)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local BattlePassXPService = {}

-- Fuente de cada evento (Sources al revés)
local sourceOf: { [string]: string } = {}
for source, spec in BPConfig.Sources do
	for event in spec.Events do
		sourceOf[event] = source
	end
end

local lastAt: { [Player]: { [string]: number } } = {} -- último evento que contó, por fuente (os.clock)

-- XP base de un evento (antes de topes)
local function baseXp(source: string, name: string, payload: { [string]: any }): number
	local spec = BPConfig.Sources[source]
	local each = spec.Events[name] or 0
	if name == "JobTaskDone" then
		local job = payload.JobId
		each = if type(job) == "string" and BPConfig.JobXp[job] then BPConfig.JobXp[job] else each
	end
	if spec.PerKm then
		local km = tonumber(payload.Km) or 0
		if km ~= km or km <= 0 then
			return 0
		end
		return each * math.min(km, 50)
	end
	return each
end

-- Topes del día (se reinician solos al cambiar de día UTC)
local function dailyOf(bp: { [string]: any }, now: number): { [string]: any }
	local day = SeasonMath.dayIndex(now)
	local d = bp.Daily
	if d.Day ~= day then
		d.Day = day
		d.Xp = 0
		d.Sources = {}
	end
	d.Xp = tonumber(d.Xp) or 0
	if type(d.Sources) ~= "table" then
		d.Sources = {}
	end
	return d
end

-- XP de actividad por un evento del juego. Devuelve la XP que se ha sumado de verdad.
function BattlePassXPService.award(player: Player, name: string, payload: { [string]: any }): number
	local source = sourceOf[name]
	if not source or payload.NoXp then
		return 0
	end
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not bp or not season then
		return 0
	end
	local now = Season.now(player)
	if not Season.earning(season, now) then
		return 0
	end
	local spec = BPConfig.Sources[source]
	-- Explorar: solo la primera vez que entras en cada barrio esta temporada
	if spec.OnlyFirst then
		local zone = payload.Zone
		if type(zone) ~= "string" or bp.Zones[zone] then
			return 0
		end
	end
	-- Anti-spam: hueco mínimo entre dos eventos de esta fuente
	local mine = lastAt[player] or {}
	lastAt[player] = mine
	local clock = os.clock()
	if (spec.MinGap or 0) > 0 and mine[source] and clock - mine[source] < spec.MinGap then
		return 0
	end
	local amount = baseXp(source, name, payload) * Season.eventMultiplier(season, now)
	amount = math.floor(amount)
	if amount <= 0 then
		return 0
	end
	-- Topes del día: de la fuente y de toda la actividad
	local daily = dailyOf(bp, now)
	local used = tonumber(daily.Sources[source]) or 0
	local room = math.min(spec.Cap - used, BPConfig.DailyActivityCap - daily.Xp)
	local give = math.max(0, math.min(amount, room))
	if give <= 0 then
		return 0
	end
	mine[source] = clock
	local added = BattlePassService.addXp(player, give, source)
	if added > 0 then
		daily.Sources[source] = used + added
		daily.Xp += added
		if spec.OnlyFirst then
			bp.Zones[payload.Zone] = true -- (si hoy ya no cabía, cuenta otro día)
		end
	end
	return added
end

-- Un evento del juego: avanza misiones y da XP de actividad
function BattlePassXPService.onEvent(player: Player, name: string, payload: { [string]: any }?)
	if typeof(player) ~= "Instance" and type(player) ~= "table" then
		return
	end
	local body = if type(payload) == "table" then payload else {}
	local ok, err = pcall(Missions.onEvent, player, name, body)
	if not ok then
		warn("[BattlePassXP] misiones: " .. tostring(err))
	end
	local ok2, err2 = pcall(BattlePassXPService.award, player, name, body)
	if not ok2 then
		warn("[BattlePassXP] " .. tostring(err2))
	end
end

function BattlePassXPService.init()
	if not BPConfig.Enabled then
		return -- pase apagado: no se escucha nada
	end
	StoryEvents.connect(function(player, name, payload)
		BattlePassXPService.onEvent(player, name, payload)
	end)
	-- Misiones completadas de la historia de vida (no pasan por StoryEvents)
	pcall(function()
		require(script.Parent.LifeStoryService).observe(function(kind, player, questId)
			if kind == "QuestDone" then
				BattlePassXPService.onEvent(player, "QuestDone", { Quest = questId })
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAt[player] = nil
	end)
end

return BattlePassXPService
