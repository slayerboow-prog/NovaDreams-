-- Conditions: comprueba si se cumplen los requisitos de un capítulo, una misión o un paso.
-- Es "puro" (no toca el juego): recibe una foto del jugador y del mundo y responde sí o no.
--
-- Requisitos posibles (todos opcionales):
--   Stage       = { Min = "Nino", Max = "Adolescente" }
--   Hours       = { From = 8, To = 14 }          hora del juego (admite de noche: From 22, To 6)
--   Weekdays    = { 1, 2, 3, 4, 5 }              1 = lunes ... 7 = domingo
--   Completed   = { "QuestA", ... }              misiones terminadas
--   NotCompleted= { "QuestB", ... }
--   Flags       = { "TieneBici", ... }           marcas que dejan otras misiones
--   NotFlags    = { ... }
--   Choices     = { EstudiosElegidos = "Medicina" }   decisiones tomadas antes
--   Discovered  = { "Colegio", ... }             lugares ya visitados
--   OnDuty      = "Profesor"                     (para misiones de profesión) el jugador está de servicio en ese rol
--   StageProgress = 0.5                          haber jugado la mitad de la etapa (Config.LifeStory.StageHours)

local Stages = require(script.Parent.Stages)
local GameClock = require(script.Parent.Parent.GameClock)

local Conditions = {}

export type Context = {
	Stage: string,
	ClockTime: number,
	Weekday: number,
	Completed: { [string]: any },
	Flags: { [string]: any },
	Choices: { [string]: { V: string } },
	Discovered: { [string]: any },
	Duties: { [string]: boolean }?,
	StageProgress: number?,
}

-- Devuelve true, o false y el motivo ("Stage", "Hours", "Weekdays", "Completed"...).
-- El motivo sirve para explicar al jugador por qué algo todavía no está disponible.
function Conditions.check(req: { [string]: any }?, ctx: Context): (boolean, string?)
	if not req then
		return true
	end
	if req.Stage and not Stages.inRange(ctx.Stage, req.Stage.Min, req.Stage.Max) then
		return false, "Stage"
	end
	for _, id in req.Completed or {} do
		if not ctx.Completed[id] then
			return false, "Completed"
		end
	end
	for _, id in req.NotCompleted or {} do
		if ctx.Completed[id] then
			return false, "NotCompleted"
		end
	end
	for _, flag in req.Flags or {} do
		if not ctx.Flags[flag] then
			return false, "Flags"
		end
	end
	for _, flag in req.NotFlags or {} do
		if ctx.Flags[flag] then
			return false, "NotFlags"
		end
	end
	for key, value in req.Choices or {} do
		local choice = ctx.Choices[key]
		if not choice or choice.V ~= value then
			return false, "Choices"
		end
	end
	for _, place in req.Discovered or {} do
		if not ctx.Discovered[place] then
			return false, "Discovered"
		end
	end
	if req.OnDuty and not (ctx.Duties and ctx.Duties[req.OnDuty]) then
		return false, "OnDuty"
	end
	if req.StageProgress and (ctx.StageProgress or 0) < req.StageProgress then
		return false, "StageProgress"
	end
	-- La hora y el día van al final: si solo falla esto, la misión está "a la espera" (no bloqueada)
	if req.Weekdays and not table.find(req.Weekdays, ctx.Weekday) then
		return false, "Weekdays"
	end
	if req.Hours and not GameClock.isBetween(req.Hours.From, req.Hours.To, ctx.ClockTime) then
		return false, "Hours"
	end
	return true
end

-- Los motivos que solo significan "espera un poco" (no hace falta hacer nada más)
function Conditions.isWaitOnly(reason: string?): boolean
	return reason == "Hours" or reason == "Weekdays"
end

return Conditions
