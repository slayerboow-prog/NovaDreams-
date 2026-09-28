-- OpeningHours: a qué hora abre y cierra cada sitio que atiende al público (horas de juego).
-- Las tiendas, correos, la biblioteca o la autoescuela cierran de noche: su dependiente no está y
-- sale el cartel de CERRADO con la hora a la que abren. Hospital, policía, bomberos, hoteles y
-- vigilantes: 24 horas.
--   OpeningHours.forRole("Dependiente") -> { 9.5, 21.5 } (nil = siempre abierto)
--   OpeningHours.isOpen(horas, hora)    -> ¿está abierto a esa hora?
--   OpeningHours.label(horas)           -> "abre a las 9:30"

local OpeningHours = {}

OpeningHours.Roles = {
	Dependiente = { 9.5, 21.5 },
	Cajero = { 9, 22 }, -- supermercado
	Cajera = { 11, 24 }, -- hamburguesería
	Cocinero = { 11, 24 },
	Cocinera = { 11, 24 },
	Informadora = { 10, 22 }, -- centro comercial
	["Funcionaria de Correos"] = { 8.5, 20.5 },
	["Funcionario de Correos"] = { 8.5, 20.5 },
	Bibliotecaria = { 9, 21 },
	Conserje = { 8, 21 },
	["Encargado de premios"] = { 10, 24 },
	["Profesor de autoescuela"] = { 9, 20 },
	Monitora = { 7, 23 },
	Monitor = { 7, 23 },
	-- 24 horas (sin entrada): Recepcionista, Vigilante, Agente de guardia, Bombero, Bombera…
}

function OpeningHours.forRole(role: string?): { number }?
	return if role then OpeningHours.Roles[role] else nil
end

function OpeningHours.isOpen(hours: { number }?, clock: number): boolean
	if not hours then
		return true
	end
	local from, to = hours[1], hours[2]
	if from <= to then
		return clock >= from and clock < to
	end
	return clock >= from or clock < to
end

local function hhmm(hour: number): string
	local h = math.floor(hour) % 24
	local m = math.floor((hour - math.floor(hour)) * 60 + 0.5)
	return ("%d:%02d"):format(h, m)
end

function OpeningHours.label(hours: { number }): string
	return ("abre a las %s"):format(hhmm(hours[1]))
end

return OpeningHours
