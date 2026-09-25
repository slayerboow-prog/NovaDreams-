-- Schedules: horarios de los sitios con horario (colegio, instituto, universidad, oficina).
--
-- Una misión que te manda al colegio no aparece ni avanza fuera del horario del colegio:
--   * Si no ha empezado, espera a que abra (en el HUD: "Empieza a las 8:00").
--   * Si ya está en marcha y el siguiente paso es ir al colegio, se queda en pausa hasta que abra
--     (sin línea guía; en el HUD: "El colegio está cerrado · abre a las 8:00").
--   * Si ya estás dentro cuando cierra, puedes terminar lo que estabas haciendo.
-- Qué horario tiene cada lugar se deduce de Locations (el colegio "de tu casa", el instituto de
-- Campus Valmar, las facultades, las oficinas), así que no hace falta tocar cada misión.

local Locations = require(script.Parent.Locations)

local Schedules = {}

export type Window = { Id: string, Name: string, From: number, To: number }

Schedules.Windows = {
	Colegio = { Id = "Colegio", Name = "El colegio", From = 7.5, To = 16 },
	Instituto = { Id = "Instituto", Name = "El instituto", From = 7.5, To = 16 },
	Universidad = { Id = "Universidad", Name = "La universidad", From = 8, To = 21 },
	Oficina = { Id = "Oficina", Name = "La oficina", From = 8.5, To = 19 },
} :: { [string]: Window }

-- Días generados (DayPlans) y su horario
local DAY_PLANS = {
	SchoolDay = "Colegio",
	HighSchoolDay = "Instituto",
	UniversityDay = "Universidad",
}

local SCHOOL_TAGS = {
	SchoolEntrance = true, Classroom = true, MusicRoom = true, RecessArea = true, PEArea = true,
	Desk = true, TeacherSpot = true, Board = true,
}

-- Horario de un lugar (o nil si se puede ir a cualquier hora)
function Schedules.forPlace(placeId: string?): Window?
	local place = placeId and Locations.Places[placeId]
	if not place or place.Special then
		return nil
	end
	if place.Model == "Facultad" or place.Tag == "Library" then
		return Schedules.Windows.Universidad
	elseif place.Model == "Torres" then
		return Schedules.Windows.Oficina
	elseif place.Zone == "Campus Valmar" and (place.Model == "Colegio" or SCHOOL_TAGS[place.Tag or ""]) then
		return Schedules.Windows.Instituto
	elseif place.Zone == "Home" and place.Tag ~= "Shop" and place.Tag ~= "JobBoard" and place.Tag ~= "TravelStop" then
		-- "Home" = el colegio más cercano a tu casa (y todo lo que hay dentro: aulas, patio, gimnasio…)
		return Schedules.Windows.Colegio
	end
	return nil
end

-- Primer lugar con horario de una lista de pasos (mirando dentro de los grupos)
local function firstWindow(steps: { { [string]: any } }?): Window?
	for _, step in steps or {} do
		local window = Schedules.forPlace(step.Place)
		if window then
			return window
		end
		if step.Steps then
			local inner = firstWindow(step.Steps)
			if inner then
				return inner
			end
		end
	end
	return nil
end

-- Horario de una misión entera (para decidir si puede empezar)
function Schedules.forQuest(quest: { [string]: any }?): Window?
	if not quest then
		return nil
	end
	if quest.Schedule == false then
		return nil -- la misión pide no tener horario
	end
	if type(quest.Schedule) == "string" then
		return Schedules.Windows[quest.Schedule]
	end
	if quest.DayPlan and DAY_PLANS[quest.DayPlan] then
		return Schedules.Windows[DAY_PLANS[quest.DayPlan]]
	end
	return firstWindow(quest.Steps)
end

-- Horario del paso actual (si te manda a un sitio con horario)
function Schedules.forStep(step: { [string]: any }?, done: { [string]: boolean }?): Window?
	if not step then
		return nil
	end
	if step.Type == "Group" and step.Steps then
		for i, child in step.Steps do
			if not (done and done[tostring(i)]) then
				local window = Schedules.forPlace(child.Place)
				if window then
					return window
				end
			end
		end
		return nil
	end
	return Schedules.forPlace(step.Place)
end

-- ¿Está abierto a esta hora? (admite horarios que pasan la medianoche)
function Schedules.isOpen(window: Window?, clockTime: number): boolean
	if not window then
		return true
	end
	if window.From <= window.To then
		return clockTime >= window.From and clockTime < window.To
	end
	return clockTime >= window.From or clockTime < window.To
end

-- "8:00", "7:30"…
function Schedules.format(hour: number): string
	local h = math.floor(hour)
	local m = math.floor((hour - h) * 60 + 0.5)
	return ("%d:%02d"):format(h, m)
end

return Schedules
