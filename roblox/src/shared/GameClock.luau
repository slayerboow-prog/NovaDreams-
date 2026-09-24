-- GameClock: el calendario del juego (hora, día, semana, mes y año).
-- WorldService mueve el reloj (Lighting.ClockTime) y cuenta los días (atributo "Day" de workspace).
-- Aquí solo se traduce eso a una fecha que entienden los demás sistemas: horarios del colegio,
-- tiendas, eventos, misiones...

local Config = require(script.Parent.Config)

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

-- La fecha actual del servidor (o la que ve el cliente, porque ClockTime y Day se replican).
function GameClock.now(): Date
	local Lighting = game:GetService("Lighting")
	local day = workspace:GetAttribute("Day") or 1
	return GameClock.fromDay(day, Lighting.ClockTime)
end

-- ¿Está la hora entre from y to? Funciona también de noche (from = 22, to = 6).
function GameClock.isBetween(from: number, to: number, clockTime: number): boolean
	if from <= to then
		return clockTime >= from and clockTime < to
	end
	return clockTime >= from or clockTime < to
end

return GameClock
