-- GameClock: el calendario del juego (hora, día, semana, mes y año).
-- WorldService mueve el reloj y cuenta los días (atributo "Day" de workspace).
-- Aquí solo se traduce eso a una fecha que entienden los demás sistemas: horarios del colegio,
-- tiendas, eventos, misiones...
--
-- OJO: Lighting.ClockTime es la HORA DEL SOL, no la del juego (shared/DayCycle: el sol se pone de
-- 21:30 a 22:00 del juego). La hora del juego es GameClock.hour(); para cambiarla, GameClock.setHour.

local Config = require(script.Parent.Config)
local DayCycle = require(script.Parent.DayCycle)

local GameClock = {}

export type Date = {
	Day: number, -- día absoluto desde que arrancó el servidor (1, 2, 3...)
	Hour: number, -- 0..23
	Minute: number, -- 0..59
	ClockTime: number, -- hora con decimales (13.5 = 13:30)
	Weekday: number, -- 1 = lunes ... 7 = domingo
	Week: number, -- semana absoluta (1, 2, 3...)
	DayOfMonth: number, -- 1..DaysPerMonth
	Month: number, -- 1..MonthsPerYear
	Year: number, -- 1, 2, 3...
	TotalMinutes: number, -- minutos de juego desde el día 1 a las 00:00 (sirve para esperas)
}

-- Fecha a partir de un día absoluto y una hora con decimales. No toca el juego: se puede probar fuera de Roblox.
function GameClock.fromDay(day: number, clockTime: number): Date
	local cal = Config.Calendar
	local index = math.max(day, 1) - 1 -- días desde el día 1
	local hour = math.floor(clockTime) % 24
	local minute = math.floor((clockTime - math.floor(clockTime)) * 60)
	local daysPerYear = cal.DaysPerMonth * cal.MonthsPerYear
	return {
		Day = index + 1,
		Hour = hour,
		Minute = minute,
		ClockTime = clockTime,
		Weekday = index % cal.DaysPerWeek + 1,
		Week = index // cal.DaysPerWeek + 1,
		DayOfMonth = index % cal.DaysPerMonth + 1,
		Month = (index % daysPerYear) // cal.DaysPerMonth + 1,
		Year = index // daysPerYear + 1,
		TotalMinutes = index * 1440 + hour * 60 + minute,
	}
end

GameClock.DayCycle = DayCycle

-- ¿Lleva este Lighting la hora del sol (atributo SunMapped, lo pone WorldService)? Sin él (Studio
-- sin servidor, dobles de las pruebas), Lighting.ClockTime es directamente la hora del juego.
local function sunMapped(lighting: any): boolean
	local ok, value = pcall(function()
		return lighting:GetAttribute("SunMapped")
	end)
	return ok and value == true
end
GameClock.sunMapped = sunMapped

-- La hora del juego ahora mismo (13.5 = 13:30): la del HUD, las tiendas, el colegio, la historia
function GameClock.hour(lighting: any?): number
	local l = lighting or game:GetService("Lighting")
	local clock = tonumber(l.ClockTime) or 12
	if sunMapped(l) then
		return DayCycle.gameTime(clock)
	end
	return clock
end

-- Pone la hora del juego (solo el servidor: WorldService, CalendarService, dormir…): escribe en
-- Lighting.ClockTime la hora del sol que le toca
function GameClock.setHour(hour: number, lighting: any?)
	local l = lighting or game:GetService("Lighting")
	hour %= 24
	l.ClockTime = if sunMapped(l) then DayCycle.sunTime(hour) else hour
end

-- Lo oscuro que es ahora (0 = día, 1 = noche cerrada) y si van las farolas: la curva de DayCycle
function GameClock.darkness(hour: number?): number
	return DayCycle.darkness(hour or GameClock.hour())
end
function GameClock.lampsOn(hour: number?): boolean
	return DayCycle.lampsOn(hour or GameClock.hour())
end
function GameClock.isNight(hour: number?): boolean
	return DayCycle.isNight(hour or GameClock.hour())
end

-- La fecha actual del servidor (o la que ve el cliente, porque ClockTime y Day se replican).
function GameClock.now(): Date
	local day = workspace:GetAttribute("Day") or 1
	return GameClock.fromDay(day, GameClock.hour())
end

-- ¿Está la hora entre from y to? Funciona también de noche (from = 22, to = 6).
function GameClock.isBetween(from: number, to: number, clockTime: number): boolean
	if from <= to then
		return clockTime >= from and clockTime < to
	end
	return clockTime >= from or clockTime < to
end

return GameClock
