-- Residents: la vida de los vecinos que viven en cada vivienda (funciones puras).
--
--   * Cada vecino tiene nombre (el de shared/Properties.neighbors), edad, profesión, lugar de trabajo
--     y horario. La misma vivienda siempre tiene los mismos vecinos con la misma vida.
--   * Rutina de un día: se levanta, sale a trabajar, vuelve, compra y cena en casa. Los jubilados y
--     los estudiantes tienen la suya. Así, si llamas a su puerta a media mañana y está trabajando,
--     no contesta nadie; si llamas por la noche, está en casa.

local Properties = require(script.Parent.Properties)

local Residents = {}

export type Person = {
	Name: string,
	Age: number,
	Job: string,
	Work: string, -- dónde trabaja (o estudia)
	Wake: number, -- hora a la que se levanta
	Leave: number?, -- sale de casa (nil: no sale por la mañana)
	Back: number?, -- vuelve
	Errand: number?, -- hora de la compra (una hora fuera)
	Sleep: number, -- se acuesta
}

local JOBS = {
	{ Job = "Enfermera", Work = "el Hospital de Valmar", Leave = 7.5, Back = 16 },
	{ Job = "Médico", Work = "el Hospital de Valmar", Leave = 8, Back = 17 },
	{ Job = "Profesora", Work = "el colegio", Leave = 8, Back = 15.5 },
	{ Job = "Policía", Work = "la comisaría", Leave = 6.5, Back = 15 },
	{ Job = "Bombero", Work = "el parque de bomberos", Leave = 8, Back = 20 },
	{ Job = "Dependienta", Work = "el centro comercial", Leave = 9.5, Back = 18 },
	{ Job = "Cocinero", Work = "un restaurante del centro", Leave = 11, Back = 23 },
	{ Job = "Oficinista", Work = "una oficina de la Torre de Valmar", Leave = 8, Back = 18 },
	{ Job = "Mecánico", Work = "un taller del Sur", Leave = 7.5, Back = 17 },
	{ Job = "Cartera", Work = "Correos", Leave = 7, Back = 14 },
	{ Job = "Camarero", Work = "un bar de la plaza", Leave = 12, Back = 24 },
	{ Job = "Abogada", Work = "el Palacio de Justicia", Leave = 8.5, Back = 18.5 },
	{ Job = "Programador", Work = "casa (teletrabajo)", Leave = nil, Back = nil },
}
local STUDENT = { Job = "Estudiante", Work = "la Universidad", Leave = 8.5, Back = 14.5 }
local RETIRED = { Job = "Jubilado", Work = "el parque (paseando)", Leave = 10, Back = 12.5 }

-- La vida del vecino principal de una vivienda (el primero de Properties.neighbors)
function Residents.person(unitKey: string, index: number?): Person
	local names = Properties.neighbors(unitKey)
	local i = math.clamp(index or 1, 1, #names)
	local h = Properties.hash("vida:" .. unitKey .. ":" .. i)
	local age = 20 + h % 62 -- 20 a 81
	local job
	if age >= 67 then
		job = RETIRED
	elseif age <= 24 and h % 2 == 0 then
		job = STUDENT
	else
		job = JOBS[(h // 7) % #JOBS + 1]
	end
	local shift = ((h // 11) % 3 - 1) * 0.5 -- media hora antes o después
	return {
		Name = names[i],
		Age = age,
		Job = job.Job,
		Work = job.Work,
		Wake = (job.Leave and job.Leave - 1 or 8.5) + shift,
		Leave = job.Leave and job.Leave + shift or nil,
		Back = job.Back and job.Back + shift or nil,
		Errand = 18 + (h // 13) % 3, -- 18:00, 19:00 o 20:00
		Sleep = 23 + (h // 17) % 2,
	}
end

local function between(t: number, from: number, to: number): boolean
	from, to = from % 24, to % 24
	if from <= to then
		return t >= from and t < to
	end
	return t >= from or t < to
end

-- ¿Dónde está a esa hora? "Casa", "Trabajo", "Compra" o "Durmiendo" (en casa, pero no abre)
function Residents.where(person: Person, clock: number): string
	if person.Leave and person.Back and between(clock, person.Leave, person.Back) then
		return "Trabajo"
	end
	if person.Errand and between(clock, person.Errand, person.Errand + 1) then
		return "Compra"
	end
	if between(clock, person.Sleep, person.Wake) then
		return "Durmiendo"
	end
	return "Casa"
end

local function hhmm(hour: number): string
	local h = math.floor(hour) % 24
	local m = math.floor((hour - math.floor(hour)) * 60 + 0.5)
	return ("%d:%02d"):format(h, m)
end
Residents.hhmm = hhmm

-- Lo que te dicen (o lo que pasa) si llamas a su puerta a esa hora
function Residents.knockText(person: Person, clock: number): (boolean, string)
	local where = Residents.where(person, clock)
	if where == "Casa" then
		return true, ""
	elseif where == "Trabajo" then
		return false, ("No contesta nadie. %s (%s) está en %s hasta las %s."):format(person.Name, string.lower(person.Job), person.Work, hhmm(person.Back or 18))
	elseif where == "Compra" then
		return false, ("No contesta nadie. %s ha bajado a comprar; volverá sobre las %s."):format(person.Name, hhmm((person.Errand or 18) + 1))
	end
	return false, ("Se oye un «¡¿Quién llama a estas horas?!» y nada más. %s está durmiendo."):format(person.Name)
end

-- Una línea para el diario o una misión: «Carmen García, 29 años, enfermera en el Hospital de Valmar»
function Residents.describe(person: Person): string
	return ("%s, %d años, %s en %s"):format(person.Name, person.Age, string.lower(person.Job), person.Work)
end

return Residents
