-- BattlePassSeasonService: la temporada del pase (cuál toca, su estado) y los datos de cada jugador.
--   * Temporada actual: la última de BattlePassConfig.Seasons que ya ha empezado (si ninguna, la
--     primera: «Próximamente»). Estado: Upcoming → Active → Grace (aún se reclama) → Ended.
--   * ensure(data): deja data.BattlePass / data.Cosmetics / data.SeasonArchive con la forma buena
--     (partidas viejas o rotas incluidas). Los valores por defecto están en DataService (DEFAULT_DATA).
--   * Cambio de temporada: el progreso de la anterior se ARCHIVA (data.SeasonArchive[SeasonId]) y se
--     empieza de cero. Lo conseguido NUNCA se borra: vive en data.Cosmetics (fuera del pase) y en los
--     sistemas de siempre (vehículos, dinero…). BattlePassService entrega antes lo que quedara sin reclamar.
--   * Reloj: now(player) = hora real UTC (+ un desfase SOLO en memoria para el modo pruebas).
--
-- Módulo "hoja": arriba solo carga datos compartidos (sin servicios), así lo pueden cargar todos.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BPConfig = require(ReplicatedStorage.Shared.BattlePass.Config)
local SeasonMath = require(script.Parent.Parent.BattlePass.SeasonMath)

local BattlePassSeasonService = {}

export type Season = { [string]: any }

local offsets: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any -- desfase del reloj (modo pruebas)
local baseClock: (() -> number)? = nil -- (pruebas: reloj fijo)

---------------------------------------------------------------------
-- Reloj y temporada
---------------------------------------------------------------------

function BattlePassSeasonService.now(player: Player?): number
	local base = if baseClock then baseClock() else os.time()
	return base + (if player then offsets[player] or 0 else 0)
end

-- (pruebas) reloj fijo para todo el servidor; nil = hora real
function BattlePassSeasonService.setClock(fn: (() -> number)?)
	baseClock = fn
end

-- (modo pruebas) adelanta el reloj de un jugador (solo en memoria; nunca se guarda)
function BattlePassSeasonService.shift(player: Player, seconds: number)
	offsets[player] = (offsets[player] or 0) + seconds
end
function BattlePassSeasonService.clearShift(player: Player)
	offsets[player] = nil
end

function BattlePassSeasonService.seasons(): { Season }
	return BPConfig.Seasons
end

function BattlePassSeasonService.byId(id: string?): Season?
	for _, season in BPConfig.Seasons do
		if season.Id == id then
			return season
		end
	end
	return nil
end

-- Temporada actual (la última que ya ha empezado; si ninguna, la primera)
function BattlePassSeasonService.current(now: number?): Season
	local t = now or BattlePassSeasonService.now()
	local found = nil
	for _, season in BPConfig.Seasons do
		if season.StartsAt <= t and (not found or season.StartsAt >= found.StartsAt) then
			found = season
		end
	end
	return found or BPConfig.Seasons[1]
end

function BattlePassSeasonService.status(season: Season, now: number?): string
	local t = now or BattlePassSeasonService.now()
	if t < season.StartsAt then
		return "Upcoming"
	elseif t < season.EndsAt then
		return "Active"
	elseif t < season.EndsAt + BPConfig.ClaimGraceDays * 86400 then
		return "Grace"
	end
	return "Ended"
end

-- ¿Se gana XP ahora? / ¿se puede reclamar ahora?
function BattlePassSeasonService.earning(season: Season, now: number?): boolean
	return BattlePassSeasonService.status(season, now) == "Active"
end
function BattlePassSeasonService.claiming(season: Season, now: number?): boolean
	local s = BattlePassSeasonService.status(season, now)
	return s == "Active" or s == "Grace"
end

-- Eventos de la temporada que están en marcha
function BattlePassSeasonService.activeEvents(season: Season, now: number?): { { [string]: any } }
	local t = now or BattlePassSeasonService.now()
	local list = {}
	for _, event in season.Events or {} do
		if t >= event.StartsAt and t < event.EndsAt then
			table.insert(list, event)
		end
	end
	return list
end

-- Multiplicador de XP de actividad por eventos (con tope de seguridad)
function BattlePassSeasonService.eventMultiplier(season: Season, now: number?): number
	local m = 1
	for _, event in BattlePassSeasonService.activeEvents(season, now) do
		m = math.max(m, tonumber(event.XpMultiplier) or 1)
	end
	return math.clamp(m, 1, BPConfig.MaxEventMultiplier)
end

---------------------------------------------------------------------
-- Curva de XP de una temporada
---------------------------------------------------------------------

function BattlePassSeasonService.levelOf(season: Season, totalXp: number): (number, number, number)
	return SeasonMath.levelFrom(season.Xp, season.MaxLevel, totalXp)
end

function BattlePassSeasonService.totalFor(season: Season, level: number): number
	return SeasonMath.totalFor(season.Xp, math.clamp(level, 1, season.MaxLevel))
end

-- Recompensa de un nivel y pista (nil si no existe)
function BattlePassSeasonService.reward(season: Season, level: number, track: string): { [string]: any }?
	for _, reward in season.Rewards do
		if reward.Level == level and reward.Track == track then
			return reward
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Datos guardados
---------------------------------------------------------------------

local function number(x: any, default: number): number
	return if type(x) == "number" and x == x and math.abs(x) ~= math.huge then x else default
end

local function tableAt(parent: { [string]: any }, key: string): { [string]: any }
	if type(parent[key]) ~= "table" then
		parent[key] = {}
	end
	return parent[key]
end

-- Pase vacío (una temporada nueva)
function BattlePassSeasonService.fresh(seasonId: string): { [string]: any }
	return {
		Version = 1,
		SeasonId = seasonId,
		TotalXp = 0,
		Level = 1,
		PremiumOwned = false,
		PremiumAt = 0,
		ClaimedFree = {},
		ClaimedPremium = {},
		OverflowTokens = 0,
		Missions = {},
		Daily = {},
		Zones = {},
		Shop = {},
	}
end

-- Deja los datos del pase con la forma buena. Devuelve data.BattlePass.
function BattlePassSeasonService.ensure(data: { [string]: any }): { [string]: any }
	local bp = data.BattlePass
	if type(bp) ~= "table" then
		bp = BattlePassSeasonService.fresh("")
		data.BattlePass = bp
	end
	bp.Version = number(bp.Version, 1)
	bp.SeasonId = if type(bp.SeasonId) == "string" then bp.SeasonId else ""
	bp.TotalXp = math.max(0, math.floor(number(bp.TotalXp, 0)))
	bp.Level = math.max(1, math.floor(number(bp.Level, 1)))
	bp.PremiumOwned = bp.PremiumOwned == true
	bp.PremiumAt = number(bp.PremiumAt, 0)
	bp.OverflowTokens = math.max(0, math.floor(number(bp.OverflowTokens, 0)))
	for _, key in { "ClaimedFree", "ClaimedPremium", "Missions", "Daily", "Zones", "Shop" } do
		tableAt(bp, key)
	end
	local cosmetics = tableAt(data, "Cosmetics")
	tableAt(cosmetics, "Owned")
	local equipped = tableAt(cosmetics, "Equipped")
	tableAt(equipped, "VehicleSkin")
	if type(equipped.Decor) ~= "table" then
		equipped.Decor = {}
	end
	tableAt(cosmetics, "Perks")
	cosmetics.Tokens = math.max(0, math.floor(number(cosmetics.Tokens, 0)))
	tableAt(data, "SeasonArchive")
	return bp
end

-- ¿Hay que archivar y empezar la temporada nueva? (el pase guardado es de otra temporada que ya no
-- es la actual y la actual ya ha empezado)
function BattlePassSeasonService.needsRollover(bp: { [string]: any }, now: number?): boolean
	local season = BattlePassSeasonService.current(now)
	if bp.SeasonId == "" or bp.SeasonId == season.Id then
		return false
	end
	return BattlePassSeasonService.status(season, now) ~= "Upcoming"
end

local function countSet(t: { [string]: any }): number
	local n = 0
	for _, v in t do
		if v then
			n += 1
		end
	end
	return n
end

-- Guarda el resumen del pase actual en data.SeasonArchive y empieza "newSeasonId" de cero.
-- (Lo conseguido está en data.Cosmetics y en los demás sistemas: aquí no se toca.)
function BattlePassSeasonService.archive(data: { [string]: any }, newSeasonId: string, now: number?)
	local bp = BattlePassSeasonService.ensure(data)
	if bp.SeasonId ~= "" and not data.SeasonArchive[bp.SeasonId] then
		local old = BattlePassSeasonService.byId(bp.SeasonId)
		local storyChoice = nil
		for _, st in (if type(bp.Missions.Story) == "table" then bp.Missions.Story else {}) do
			if type(st) == "table" and st.Choice then
				storyChoice = st.Choice
			end
		end
		data.SeasonArchive[bp.SeasonId] = {
			SeasonId = bp.SeasonId,
			Name = if old then old.Name else bp.SeasonId,
			Level = bp.Level,
			TotalXp = bp.TotalXp,
			PremiumOwned = bp.PremiumOwned,
			FreeClaimed = countSet(bp.ClaimedFree),
			PremiumClaimed = countSet(bp.ClaimedPremium),
			StoryChoice = storyChoice,
			ArchivedAt = now or os.time(),
		}
	end
	data.BattlePass = BattlePassSeasonService.fresh(newSeasonId)
	return data.BattlePass
end

function BattlePassSeasonService.init()
	-- (nada que arrancar: lo usan los demás servicios del pase)
end

return BattlePassSeasonService
