-- CalendarService: el día de TU vida (se guarda con la partida).
--
-- El reloj del mundo (WorldService: Lighting.ClockTime y el atributo "Day" de workspace) es del
-- servidor y lo comparten todos los jugadores. Antes cada servidor nuevo empezaba en «Lunes, 1 de
-- enero · Día 1»: al volver a entrar parecía que tu vida empezaba otra vez (y el día normal del cole,
-- LoopDay, se olvidaba). Ahora:
--   * data.Calendar = { Day = número de día de tu vida (1, 2, 3…), Clock = hora a la que lo dejaste }.
--   * Cada vez que en el servidor pasa un día (el reloj del mundo cruza medianoche, o se duerme),
--     tu día sube igual. Tu día está en el atributo "LifeDay" del jugador (HUD, historia).
--   * Si llegas a un servidor en el que no hay nadie más, el mundo continúa TU calendario: el día
--     (y la hora) del servidor pasan a ser los tuyos. Así el HUD, los horarios del cole, las tiendas
--     y el tiempo cuadran con donde lo dejaste. Si ya hay gente, el mundo no se toca (es de todos)
--     y tu día sigue contando desde el tuyo.
--   * No cambia lo que dura un día (Config.DayLengthMinutes).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

local CalendarService = {}

local seen: { [Player]: number } = {} -- día del servidor que ya se le ha contado

local function serverDay(): number
	local day = workspace:GetAttribute("Day")
	return if type(day) == "number" and day >= 1 then math.floor(day) else 1
end

local function calendarOf(data: { [string]: any }): { [string]: any }
	local cal = data.Calendar
	if type(cal) ~= "table" then
		cal = {}
		data.Calendar = cal
	end
	local day = tonumber(cal.Day)
	cal.Day = if day and day == day and day >= 1 and day < 1e7 then math.floor(day) else 1
	local clock = tonumber(cal.Clock)
	cal.Clock = if clock and clock == clock and clock >= 0 and clock < 24 then clock else nil
	return cal
end
CalendarService.calendarOf = calendarOf

-- Día de la vida de este jugador (o el del servidor si aún no ha cargado)
function CalendarService.dayOf(player: Player): number
	local day = player:GetAttribute("LifeDay")
	if type(day) == "number" and day >= 1 then
		return day
	end
	return serverDay()
end

-- ¿Está solo en el servidor? (nadie más con la partida cargada ni entrando)
local function alone(player: Player): boolean
	for _, other in Players:GetPlayers() do
		if other ~= player then
			return false
		end
	end
	for other in seen do
		if other ~= player and other.Parent then
			return false
		end
	end
	return true
end

-- Sube el día de cada jugador lo que haya avanzado el del servidor desde la última vez
local function credit(player: Player)
	local data = DataService.get(player)
	local last = seen[player]
	if not data or not last then
		return
	end
	local now = serverDay()
	if now > last then
		local cal = calendarOf(data)
		cal.Day += now - last
		player:SetAttribute("LifeDay", cal.Day)
	end
	seen[player] = now -- (si el día del servidor baja —otro calendario adoptado—, solo se resincroniza)
end

function CalendarService.onLoaded(player: Player, data: { [string]: any })
	local cal = calendarOf(data)
	if alone(player) then
		-- El mundo sigue tu calendario: tu día y la hora a la que lo dejaste
		workspace:SetAttribute("Day", cal.Day)
		if cal.Clock then
			Lighting.ClockTime = cal.Clock
		end
	end
	seen[player] = serverDay()
	player:SetAttribute("LifeDay", cal.Day)
end

function CalendarService.init()
	DataService.onLoaded(CalendarService.onLoaded)
	DataService.beforeSave(function(player, data)
		if seen[player] then
			credit(player)
			calendarOf(data).Clock = math.floor(Lighting.ClockTime * 100) / 100
		end
	end)
	workspace:GetAttributeChangedSignal("Day"):Connect(function()
		for player in seen do
			credit(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		-- (se olvida un rato después: el guardado de salida de DataService —con reintentos— todavía
		-- pasa por beforeSave y apunta su día y su hora)
		task.delay(60, function()
			if not player.Parent then
				seen[player] = nil
			end
		end)
	end)
end

return CalendarService
