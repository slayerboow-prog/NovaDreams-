-- ActorStaging: cómo ENTRAN, SALEN y a quién MIRAN los actores de las escenas de la historia.
-- Reglas puras (sin instancias): las usan el servidor (Services/SceneService: entradas, salidas,
-- saltos del jugador) y el cliente (Controllers/ActorLife: miradas en la conversación). Las prueba
-- scripts/test-actors.luau.
--
-- Campos nuevos (opcionales) de un actor de misión (Actors = { … }):
--   Enter = "Puerta"                              entra andando desde ese lugar hasta su sitio
--   Enter = { From = "Puerta", Walk = true,       (lo mismo, con más detalle)
--             Delay = 1.5, Index = n, Offset = V }    espera Delay segundos antes de echar a andar
--   Exit  = "PasilloCole"                         al dejar la escena se va andando hasta ese lugar
--   Exit  = { To = "Pasillo", Walk = true }       (lo mismo)
--   Exit  = "Fade" | { Fade = true }              se desvanece donde está
--   Exit  = "Stay" | { Stay = true }              se queda donde está hasta que te alejas (o un rato)
--   Mood  = "Nervios"                             emoción que dura (shared/LifeStory/ActorMoods)
-- Sin Exit: si está cerca de ti se va andando (a su sitio de siempre en el mapa si lo tiene cerca, o
-- unos pasos lejos de ti) y se desvanece al llegar; si está lejos, se desvanece. Nunca de golpe.
--
-- Línea de diálogo: To = "Sara" (a quién le habla; "Player" = a ti). Sin To, quien contesta a otro
-- personaje que le acaba de preguntar le mira a él; si solo comenta lo que dijo otro, le mira un
-- momento y luego te mira a ti.

local ActorStaging = {}

-- Salidas
ActorStaging.AwayDistance = 14 -- (sin sitio adonde ir) cuántos studs se aleja de ti antes de desvanecerse
ActorStaging.LeaveSeconds = 7 -- andando como mucho (sin destino); luego se desvanece igual
ActorStaging.LeaveToSeconds = 14 -- andando como mucho hasta un lugar (Exit.To)
ActorStaging.HomeRange = 60 -- su sitio de siempre en el mapa, si está a menos de esto, es adonde vuelve
ActorStaging.SeenDistance = 75 -- más lejos de ti no se ve el paseo: se desvanece directamente
ActorStaging.StaySeconds = 90 -- (Exit = "Stay") como mucho se queda esto
ActorStaging.StayFar = 45 -- (Exit = "Stay") se va cuando te alejas más de esto
ActorStaging.FadeSeconds = 0.6 -- lo que tarda en desvanecerse (cliente: ActorLife)
ActorStaging.Stagger = 0.3 -- si se van varios a la vez, cada uno sale un poco después del anterior
ActorStaging.StaggerMax = 1.2

-- Saltos del jugador
ActorStaging.DipMin = 8 -- un salto más corto que esto no necesita fundido (un ajuste de sitio)
ActorStaging.DipHold = 0.2 -- (cliente) negro antes de volver a ver
ActorStaging.DipIn = 0.55 -- (cliente) lo que tarda en volver la imagen
ActorStaging.DipMax = 3 -- (cliente) nunca se queda a negro más que esto

-- Miradas
ActorStaging.GroupRadius = 35 -- quien está a menos de esto de quien habla, le mira
ActorStaging.ReplyWindow = 10 -- segundos: contestar a la frase de otro (si no, ya es otra cosa)
ActorStaging.AckSeconds = 1.2 -- al comentar lo que dijo otro, le mira esto antes de mirarte a ti

local PLAYER_WORDS = { Player = true, Jugador = true, Tu = true, ["Tú"] = true, Me = true, Yo = true }

local function number(value: any, default: number): number
	return if type(value) == "number" and value == value then value else default
end

export type EnterPlan = { From: string, Walk: boolean, Delay: number, Index: number?, Offset: any? }
export type ExitPlan = { To: string?, Walk: boolean, Fade: boolean, Stay: boolean, Index: number?, Offset: any? }

-- La entrada de un actor (nil = aparece en su sitio con un fundido suave, como siempre)
function ActorStaging.enter(spec: { [string]: any }?): EnterPlan?
	local e = spec and spec.Enter
	if type(e) == "string" and e ~= "" then
		return { From = e, Walk = true, Delay = 0 }
	end
	if type(e) == "table" and type(e.From) == "string" and e.From ~= "" and e.Walk ~= false then
		return { From = e.From, Walk = true, Delay = math.clamp(number(e.Delay, 0), 0, 20), Index = e.Index, Offset = e.Offset }
	end
	return nil
end

-- La salida de un actor (siempre hay una: nadie desaparece de golpe)
function ActorStaging.exit(spec: { [string]: any }?): ExitPlan
	local x = spec and spec.Exit
	if x == "Fade" or x == false then
		return { Walk = false, Fade = true, Stay = false }
	elseif x == "Stay" then
		return { Walk = false, Fade = false, Stay = true }
	elseif type(x) == "string" and x ~= "" then
		return { To = x, Walk = true, Fade = false, Stay = false }
	elseif type(x) == "table" then
		if x.Fade == true or (x.Walk == false and x.Stay ~= true) then
			return { Walk = false, Fade = true, Stay = false }
		elseif x.Stay == true then
			return { Walk = false, Fade = false, Stay = true }
		elseif type(x.To) == "string" and x.To ~= "" then
			return { To = x.To, Walk = true, Fade = false, Stay = false, Index = x.Index, Offset = x.Offset }
		end
	end
	return { Walk = true, Fade = false, Stay = false }
end

-- ¿Son válidos Enter / Exit? (para el validador). Devuelve el mensaje de error o nil.
function ActorStaging.check(spec: { [string]: any }): string?
	local e = spec.Enter
	if e ~= nil and type(e) ~= "string" and not (type(e) == "table" and type(e.From) == "string") then
		return "Enter tiene que ser un lugar o { From = lugar }"
	end
	local x = spec.Exit
	if x ~= nil and x ~= false and type(x) ~= "string" and not (type(x) == "table" and (type(x.To) == "string" or x.Fade == true or x.Stay == true or x.Walk == false)) then
		return "Exit tiene que ser un lugar, \"Fade\", \"Stay\" o { To = lugar }"
	end
	return nil
end

-- Los lugares que nombran Enter / Exit (para comprobar que existen)
function ActorStaging.places(spec: { [string]: any }): { string }
	local list = {}
	local e = ActorStaging.enter(spec)
	if e then
		table.insert(list, e.From)
	end
	local x = ActorStaging.exit(spec)
	if x.To then
		table.insert(list, x.To)
	end
	return list
end

-- Cómo se va de verdad, según dónde estás tú:
--   "Fade"   se desvanece donde está      "WalkTo" anda hasta Exit.To y se desvanece
--   "Home"   vuelve a su sitio del mapa    "Away"   se aleja unos pasos de ti y se desvanece
--   "Stay"   se queda hasta que te alejas
-- ctx = { Distance = studs hasta ti (nil: no estás), Mode = su modo, HasHome = tiene sitio cerca,
--         Relocate = (va a aparecer en otro sitio lejano: se desvanece), Seated = está sentado }
function ActorStaging.exitMode(plan: ExitPlan, ctx: { [string]: any }): string
	local mode = ctx.Mode
	if mode == "Hunt" or mode == "Flee" or ctx.Enemy then
		return "Fade" -- (enemigos y fugitivos: no se pasean después)
	end
	if ctx.Relocate or plan.Fade then
		return "Fade"
	end
	local distance = ctx.Distance
	if type(distance) ~= "number" or distance > ActorStaging.SeenDistance then
		return "Fade" -- no lo ves: no hace falta el paseo
	end
	if plan.Stay then
		return "Stay"
	end
	if plan.To then
		return "WalkTo"
	end
	if ctx.HasHome then
		return "Home"
	end
	return "Away"
end

-- Cuánto espera antes de irse el n-ésimo de los que se van a la vez (no se mueven todos a la vez)
function ActorStaging.stagger(index: number): number
	return math.min(ActorStaging.StaggerMax, math.max(0, index - 1) * ActorStaging.Stagger)
end

-- Cuánto anda como mucho
function ActorStaging.leaveSeconds(mode: string): number
	return if mode == "WalkTo" or mode == "Home" then ActorStaging.LeaveToSeconds else ActorStaging.LeaveSeconds
end

-- Adónde se aleja (sin destino): en la dirección de ti hacia él, un poco abierta (cada uno hacia
-- un lado, según `index`), a AwayDistance studs de donde está
function ActorStaging.awayPoint(actorPos: Vector3, playerPos: Vector3?, index: number?): Vector3
	local dir = if playerPos then Vector3.new(actorPos.X - playerPos.X, 0, actorPos.Z - playerPos.Z) else Vector3.new(0, 0, 0)
	if dir.Magnitude < 0.5 then
		dir = Vector3.new(1, 0, 0)
	end
	dir = dir.Unit
	local i = index or 1
	local angle = (if i % 2 == 0 then 1 else -1) * math.rad(math.min(35, 12 * math.ceil(i / 2)))
	local c, s = math.cos(angle), math.sin(angle)
	local turned = Vector3.new(dir.X * c - dir.Z * s, 0, dir.X * s + dir.Z * c)
	return actorPos + turned * ActorStaging.AwayDistance
end

-- ¿Un salto del jugador necesita fundido? (de un sitio a otro lejano: sí; un ajuste: no)
function ActorStaging.needsDip(from: Vector3?, to: Vector3): boolean
	if not from then
		return false
	end
	return (to - from).Magnitude >= ActorStaging.DipMin
end

---------------------------------------------------------------------
-- Escenas lejos de ti (auditoría visual de las cinemáticas): un paso Reach a un sitio grande (el
-- parque, la playa, el campus) se cumple al llegar a su BORDE, pero los actores de la escena que viene
-- detrás están en su centro, a 80-120 studs. La conversación salía sin nadie en plano (quien habla no
-- se acerca desde tan lejos) y las escenas del motor hacían planos de hombro desde la otra punta del
-- parque. Ahora, si quien lleva la escena está más lejos que esto, se te acerca con un fundido a negro.
---------------------------------------------------------------------
ActorStaging.GatherScene = 60 -- conversación (StageDirector.APPROACH_MAX: de más lejos no se acerca)
ActorStaging.GatherCinematic = 30 -- escena del motor (sus planos son de pocos studs)
ActorStaging.GatherStop = 6 -- a cuánto de quien lleva la escena te quedas

-- Quién lleva la escena: el primero que habla (speakers, en orden) que tiene un sitio en el mapa; si
-- nadie, el primer actor con sitio que no pasea. Devuelve su línea de Actors (o nil).
function ActorStaging.lead(actors: { any }?, speakers: { string }?): { [string]: any }?
	local placed = {}
	for _, spec in actors or {} do
		if type(spec) == "table" and type(spec.Npc) == "string" and type(spec.Place) == "string" and spec.Mode ~= "Follow" then
			placed[spec.Npc] = placed[spec.Npc] or spec
		end
	end
	for _, id in speakers or {} do
		if placed[id] then
			return placed[id]
		end
	end
	for _, spec in actors or {} do
		if type(spec) == "table" and placed[spec.Npc] == spec and spec.Mode ~= "Wander" and spec.Mode ~= "Flee" and spec.Mode ~= "Hunt" then
			return spec
		end
	end
	return nil
end

-- Adónde llevar al jugador (me) para una escena cuyo protagonista está en `lead`: nil si ya está
-- cerca. kind = "Scene" | "Cinematic". El punto queda entre los dos, a GatherStop de él.
function ActorStaging.gatherSpot(me: Vector3, lead: Vector3, kind: string): Vector3?
	local limit = if kind == "Cinematic" then ActorStaging.GatherCinematic else ActorStaging.GatherScene
	local offset = Vector3.new(me.X - lead.X, 0, me.Z - lead.Z)
	if offset.Magnitude <= limit then
		return nil
	end
	local dir = if offset.Magnitude > 0.5 then offset.Unit else Vector3.new(0, 0, 1)
	return lead + dir * ActorStaging.GatherStop
end

-- ¿Habla a quién? to (de la línea): "Player"/"Jugador" = a ti; otro texto = ese personaje.
function ActorStaging.isPlayer(to: any): boolean
	return type(to) == "string" and PLAYER_WORDS[to] == true
end

-- A quién mira quien habla. Genérico (ids o modelos):
--   line = { Speaker, To?, Question? }       la frase de ahora
--   prev = { Speaker, Question?, IsPlayer?, Since } la anterior (o nil)
-- Devuelve (target, ack, ackSeconds): target = "Player" o el personaje; ack = a quién mira un momento
-- al empezar (el que acaba de hablar), o nil.
function ActorStaging.addressee(line: { [string]: any }, prev: { [string]: any }?): (any, any?, number)
	local to = line.To
	if to ~= nil and to ~= "" then
		if ActorStaging.isPlayer(to) then
			return "Player", nil, 0
		end
		return to, nil, 0
	end
	if prev and prev.Speaker ~= nil and prev.Speaker ~= line.Speaker and not prev.IsPlayer and number(prev.Since, math.huge) <= ActorStaging.ReplyWindow then
		if prev.Question then
			return prev.Speaker, nil, 0 -- contesta a quien le ha preguntado
		end
		return "Player", prev.Speaker, ActorStaging.AckSeconds -- comenta lo que dijo el otro y te mira
	end
	return "Player", nil, 0
end

-- ¿Es una pregunta? (por la emoción con que se dice o por el texto)
function ActorStaging.isQuestion(emotion: any, text: any): boolean
	if emotion == "Ask" then
		return true
	end
	if type(text) == "string" then
		local s = text:gsub("%s+$", ""):gsub("»$", "")
		return s:sub(-1) == "?"
	end
	return false
end

return ActorStaging
