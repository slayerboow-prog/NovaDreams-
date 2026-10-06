-- (No es una misión.) Lo que comparten las misiones de la profesión y la vida adulta (paquete P8d):
--   * las condiciones de cada camino (carrera o trabajo del verano) y el reparto del jefe (JEFE);
--   * paso(id, actores): el paso que lanza una escena escrita a mano de Happenings/Adulto.
--
-- paso() es DEFENSIVO: si el grupo "Adulto" todavía no está en HappeningIndex (GROUPS), el paso se juega
-- como una conversación normal con las mismas frases de la escena (las del diálogo base: sin planos ni
-- variantes). Así la historia funciona igual antes y después de registrar el grupo.

local HappeningIndex = require(script.Parent.Parent.HappeningIndex)
local Escenas = require(script.Parent.Parent.Happenings.Adulto)

local V = Vector3.new

local C = {}

C.GRADUADO = { Flags = { "Graduado" } }
C.TRABAJA = { NotFlags = { "Graduado" } }
C.MED = { Flags = { "Graduado" }, Choices = { Estudios = "Medicina" } }
C.ING = { Flags = { "Graduado" }, Choices = { Estudios = "Ingenieria" } }
C.DER = { Flags = { "Graduado" }, Choices = { Estudios = "Derecho" } }
C.ECO = { Flags = { "Graduado" }, Choices = { Estudios = "Economia" } }
C.CAFE = { NotFlags = { "Graduado" }, Choices = { Empleo = "Barista" } }
C.SUPER = { NotFlags = { "Graduado" }, Choices = { Empleo = "Reponedor" } }
C.CORREOS = { NotFlags = { "Graduado" }, Choices = { Empleo = "Repartidor" } }

-- Tu jefe, en su sitio (el de tus prácticas o donde trabajaste en verano)
C.JEFE = {
	{ Npc = "Nuria", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = C.MED },
	{ Npc = "Sofia", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = C.ING },
	{ Npc = "Montse", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = C.DER },
	{ Npc = "Ignacio", Place = "$Carrera.LugarPracticas", Offset = V(0, 0, 5), If = C.ECO },
	{ Npc = "Lola", Place = "CafeteriaCentral", Offset = V(0, 0, 5), If = C.CAFE },
	{ Npc = "Paco", Place = "Supermercado", Offset = V(0, 0, 5), If = C.SUPER },
	{ Npc = "Ernesto", Place = "Correos", Offset = V(0, 0, 5), If = C.CORREOS },
}

-- Los pasos de llegar a tu trabajo (uno por camino; solo vale el tuyo)
function C.irAlTrabajo(texto: string, extra: { [string]: any }?): { { [string]: any } }
	local list = {
		{ Type = "Reach", Place = "$Carrera.LugarPracticas", Text = texto, If = C.GRADUADO, Actors = C.JEFE },
		{ Type = "Reach", Place = "CafeteriaCentral", Text = texto, If = C.CAFE, Actors = C.JEFE },
		{ Type = "Reach", Place = "Supermercado", Text = texto, If = C.SUPER, Actors = C.JEFE },
		{ Type = "Reach", Place = "Correos", Text = texto, If = C.CORREOS, Actors = C.JEFE },
	}
	for _, step in list do
		for k, v in extra or {} do
			step[k] = v
		end
	end
	return list
end

-- Lo que se queda de una frase de la escena al jugarla como conversación
local KEEP = { S = true, T = true, If = true, A = true, G = true }
-- Los Beat de las escenas (Sequencer) con su nombre en las conversaciones (StageDirector)
local BEAT = { Mirar = "Mira", Suelo = "Baja", Apartar = "Aparta", Pensar = "Piensa", Respirar = "Respira" }
local MAX_PAUSE = 1.5 -- (en conversación no hay plano de situación que esperar)
local NOT_IN_DIALOGUE = { Late = true, Items = true, Input = true } -- (condiciones solo de escena)

local function usable(cond: any): boolean
	if type(cond) ~= "table" then
		return cond == nil
	end
	for k in cond do
		if NOT_IN_DIALOGUE[k] then
			return false
		end
	end
	return true
end

-- Las frases de una escena como conversación de misión ({ Lines = … })
function C.lineas(id: string): { [string]: any }
	local def = Escenas[id]
	local lines = {}
	for _, raw in (def and def.Tracks and def.Tracks.Dialogue) or {} do
		if type(raw) == "table" and raw.IfNot == nil and usable(raw.If) then
			local line = {}
			for k, v in raw do
				if KEEP[k] then
					line[k] = v
				end
			end
			if type(raw.Beat) == "string" and BEAT[raw.Beat] then
				line.Beat = BEAT[raw.Beat]
			end
			if type(raw.Pause) == "number" and raw.Pause > 0 then
				line.Pause = math.min(raw.Pause, MAX_PAUSE)
			end
			table.insert(lines, line)
		end
	end
	return { Lines = lines }
end

-- ¿La escena está registrada (HappeningIndex)? Entonces es una escena de cine; si no, conversación.
function C.registrada(id: string): boolean
	return HappeningIndex.has(id)
end

function C.paso(id: string, actors: { any }?, extra: { [string]: any }?): { [string]: any }
	local step: { [string]: any }
	if HappeningIndex.has(id) then
		step = { Type = "Cinematic", Id = id, Actors = actors }
	else
		step = { Type = "Scene", Dialogue = C.lineas(id), Actors = actors }
	end
	for k, v in extra or {} do
		step[k] = v
	end
	return step
end

-- El montaje de etapa «adulto joven → adulto» de P7 (Happenings/Etapas: Joven_Adulto), si ya existe
function C.montaje(id: string): string?
	return if HappeningIndex.has(id) then id else nil
end

return C
