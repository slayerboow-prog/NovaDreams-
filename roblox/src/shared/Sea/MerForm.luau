-- MerForm: las reglas PURAS del cuerpo hondario (docs/mar/civilizacion-marina.md §6, «El Don de la Marea»).
-- Sin nada de Roblox que cree cosas: lo usan Services/HondarioService (servidor: decide la forma, el aire y
-- la presión), Services/DivingService (el aire), Controllers/Swimming (nado más rápido), Controllers/MerForm
-- (la cola que se mueve y el HUD) y scripts/test-hondario.luau.
--
--   MerForm.form(s)          "Cola" | "Piernas": cola dentro del agua, piernas en tierra, en un barco, en
--                            una cúpula de aire o con «Quedarme en forma humana» encendido
--   MerForm.breath(s)        un segundo bajo el agua con branquias: el aire no baja nunca y la presión no
--                            hace daño hasta MerForm.Depth m (en los barrios de Nácara, nunca)
--   MerForm.swimSpeed(...)   la velocidad del nado con cola: +40 % y con aceleración suave (no de golpe)
--
-- Con el don (o en la «vida hondaria» del modo pruebas) se respira bajo el agua SIEMPRE, también en forma
-- humana: las branquias son tuyas. La forma humana solo cambia el aspecto y el nado (para bucear con un
-- amigo con tu traje de siempre).

local MerForm = {}

MerForm.Depth = 120 -- metros sin daño de presión con el don (156 m con la perla de presión: fase 3)
MerForm.SwimBoost = 1.4 -- +40 % nadando con cola
MerForm.SprintBoost = 1.25 -- Correr con cola (sobre lo anterior)
MerForm.Accel = 9 -- studs/s² al acelerar (suave)
MerForm.Decel = 16 -- studs/s² al soltar
MerForm.TurnBlend = 6 -- lo rápido que la dirección sigue a la del joystick (por segundo)
MerForm.BaseSpeed = 16 -- la de andar/nadar de un adulto (Config.WalkSpeed)
MerForm.FormGrace = 0.6 -- segundos que tiene que durar un cambio (sin parpadeos en la superficie)

export type FormState = {
	Gift: boolean, -- tiene el don (o la vida hondaria de pruebas)
	StayHuman: boolean?, -- «Quedarme en forma humana»
	Underwater: boolean?, -- el cuerpo está en el agua (DivingService.underwater o nadando)
	InAir: boolean?, -- dentro de una cúpula o una casa con aire
	Seated: boolean?, -- sentado (barco, vehículo)
	Dead: boolean?,
}

function MerForm.form(s: FormState): string
	if not s.Gift or s.StayHuman or s.Dead or s.Seated or s.InAir then
		return "Piernas"
	end
	return if s.Underwater then "Cola" else "Piernas"
end

-- Un segundo de aire con branquias. s = { Max, Meters, Safe (en un barrio de Nácara), Over }
-- Devuelve aire, daño, segundos pasado el límite y la presión ("Ok" | "Warn" | "Over")
function MerForm.breath(s: { [string]: any }): (number, number, number, string)
	local max = s.Max or 240
	local meters = s.Meters or 0
	if s.Safe or meters <= MerForm.Depth - 3 then
		return max, 0, 0, "Ok"
	end
	if meters <= MerForm.Depth then
		return max, 0, 0, "Warn"
	end
	-- (más hondo que el don: la presión aprieta como a los demás, pero el aire sigue lleno)
	local over = (s.Over or 0) + 1
	local damage = if over > 4 then 8 else 0
	return max, damage, over, "Over"
end

-- La velocidad del nado con cola: sube con Accel hasta el objetivo y baja con Decel al soltar.
--   current: la de ahora · moving: el joystick está pulsado · sprint: Correr · dt: segundos
function MerForm.targetSpeed(sprint: boolean?, base: number?): number
	local b = base or MerForm.BaseSpeed
	return b * MerForm.SwimBoost * (if sprint then MerForm.SprintBoost else 1)
end

function MerForm.swimSpeed(current: number, moving: boolean, sprint: boolean?, dt: number, base: number?): number
	local goal = if moving then MerForm.targetSpeed(sprint, base) else 0
	if current < goal then
		return math.min(goal, current + MerForm.Accel * dt)
	end
	return math.max(goal, current - MerForm.Decel * dt)
end

-- La onda de la cola (tramo i = 1..4, de la cadera a la aleta): más fuerte nadando deprisa
function MerForm.tailWave(t: number, i: number, speed: number): number
	local k = math.clamp(speed / 20, 0.25, 1)
	return math.sin(t * (2 + 3 * k) - i * 0.75) * (0.1 + i * 0.06) * (0.6 + 0.6 * k)
end

-- Lo que enseña el HUD (identidad)
function MerForm.label(form: string?, stayHuman: boolean?): string
	if stayHuman then
		return "🐚 Hondario · forma humana"
	end
	return if form == "Cola" then "🐚 Hondario · forma de cola" else "🐚 Hondario · piernas en tierra"
end

return MerForm
