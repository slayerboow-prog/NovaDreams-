-- Sequencer: el MOTOR DE ESCENAS de la historia (cuentas puras, sin servicios de Roblox).
--
-- Una escena («acontecimiento», shared/LifeStory/Happenings/*) es una línea de tiempo con PISTAS.
-- Cada pista es una lista de sucesos con At (segundo de la escena). Aquí se ordenan, se comprueban,
-- se calcula cuánto duran, qué toca entre dos instantes, qué hay que aplicar de golpe si el jugador
-- SALTA la escena y cómo corre el reloj con las ESPERAS (la escena se para hasta que pasa algo).
--
-- Quién hace cada pista (Side):
--   Servidor  Actors (aparecer, entrar andando, andar, mirar, emoción, gesto, irse), World (memoria del mundo)
--   Cliente   Camera, Shake, Fx, Sky, Sound, Music, Lines, Titles, Fade, Ambience, Light
--   Los dos   Wait (la escena se para: el servidor decide cuándo sigue; el cliente congela su reloj)
--             Dialogue (el cliente enseña la frase; el servidor gira las miradas hacia quien habla)
--
-- Reloj de la escena (el mismo en el servidor y en el cliente, con workspace:GetServerTimeNow()):
--   t = ahora − StartAt − Paused     (y mientras está parada, t se queda en el punto de la espera)
--
-- CINEMATIC_SCENE (docs/historia/auditoria-narrativa-cinematica.md §6.1). Todo lo nuevo es OPCIONAL: las
-- escenas viejas siguen igual.
--   Dialogue = { { S, T, To?, A?, G?, Mood?, Pause?, Beat?, Shot?, At?, Duration?, Alt?, If?, IfNot? } }
--       Diálogo en el mundo. Sin At, cada frase va detrás de la anterior (lo que tarda en leerse +
--       pausas). Pause = segundos de silencio antes (o { Before, After }). Beat = un gesto en esa pausa:
--       "Mirar" (a quien le habla), "Suelo" (vergüenza), "Apartar"/"Pensar" (mira a otro lado),
--       "Respirar" (solo la pausa) o un gesto (Wave, Point, Cheer, Laugh, Dance). Shot = plano con nombre
--       (CameraShots.preset) mientras dura la frase. To = a quién le habla (clave, "Yo" o ancla). Alt =
--       sale a la vez que la anterior (la alternativa de un If/IfNot).
--   Look = "Speaker" (por defecto con Dialogue) | false: todo el reparto mira a quien habla; quien habla
--       mira a To, o a quien habló antes, o a ti. Un Look suelto de un actor manda sobre esto hasta que
--       se le diga Look = { Key, At = "Speaker" }. Otros At: "Suelo", "Away" (y lo de siempre: "Yo",
--       un actor, un ancla).
--   Actors: Enter = { Key, Npc|Creature, From = ancla|P, To = P?, Anchor?, Offset?, Walk = true, Run? }
--       aparece en From y ANDA hasta su marca (To, o Anchor+Offset). Walk = false: aparece en la marca.
--       Exit = { Key, To = ancla|P?, Walk = true, Run? }: anda hasta To y se va (sin To, se va ya).
--   Camera: { At, Duration, Shot = "PrimerPlano:Lucia" } (planos con nombre; Reverse = al revés)
--   Ambience = { { At, Kind = "Escuela"|"Casa"|…|false, Fade? } }   capa de sonido ambiente (StoryAudio)
--   Light    = { { At, Preset = "InteriorCalido"|"Atardecer"|"Noche"|…|false, Fade?, Weight? } }
--   Music    = { { At, Play = cue } | { At, Intensity = "Nada|Descubrimiento|Intima|Tension|Resolucion|Tema" } }
--       Ambience, Light e Intensity se deshacen SIEMPRE al acabar, al saltar y al morir.
--   If / IfNot de cualquier suceso: además de { Input = "X" }, las Conditions de las misiones (Flags,
--       Rel, Memories, Choices…, más Late = true|false e Items = { Id = n }). Las resuelve el SERVIDOR al
--       empezar (Sequencer.resolve) y el cliente recibe el resultado: los dos ven lo mismo.
--   Variants = { { Name?, If = Conditions, Tracks = { pistas que sustituyen }, Duration?, Anchors?, … } }
--       la primera que se cumple sustituye esas pistas enteras (por relación, si llegaste tarde…).
--   Until = { Event = "Nombre", Match = { … }?, Timeout? }: la escena acaba cuando llega ese aviso de
--       StoryEvents (lo que faltaba se deja hecho); si se acaba antes, se queda en el último plano
--       esperándolo (como mucho Timeout o MAX_WAIT segundos).
--   OnSkip = { Inputs = { Cubrirse = true }, World = { [clave] = valor } }: al saltarla, qué se da por
--       hecho en las esperas que faltaban y qué más se apunta en la memoria del mundo.
--
-- Las pruebas: scripts/test-scenes.luau.

local CameraShots = require(script.Parent.Parent.CameraShots)

local Sequencer = {}

export type Event = { At: number, Track: string, Data: { [string]: any }, Seq: number }
export type Timeline = {
	Id: string,
	Events: { Event },
	Duration: number,
	Waits: { Event },
	Shots: { { [string]: any } },
	Shakes: { { [string]: any } },
	Def: { [string]: any }?,
}

Sequencer.Tracks = {
	Camera = "Client",
	Shake = "Client",
	Fx = "Client",
	Sky = "Client",
	Sound = "Client",
	Music = "Client",
	Lines = "Client",
	Titles = "Client",
	Fade = "Client",
	Ambience = "Client",
	Light = "Client",
	Actors = "Server",
	World = "Server",
	Wait = "Both",
	Dialogue = "Both",
}
-- Orden dentro del mismo segundo: primero el mundo y los actores (para que la cámara ya los encuentre)
local ORDER = {
	World = 1,
	Actors = 2,
	Wait = 3,
	Camera = 4,
	Sky = 5,
	Light = 5.5,
	Fx = 6,
	Shake = 7,
	Sound = 8,
	Ambience = 8.5,
	Music = 9,
	Lines = 10,
	Dialogue = 10.5,
	Titles = 11,
	Fade = 12,
}

Sequencer.ActorOps = { Spawn = true, Enter = true, Use = true, Move = true, Look = true, Mood = true, Gesture = true, Say = true, Despawn = true, Exit = true, Face = true }
Sequencer.WaitKinds = { Seconds = true, Input = true, Near = true, Arrived = true }
Sequencer.MAX_WAIT = 120 -- una espera no dura más (si nadie hace nada, la escena sigue)

-- Capas de ambiente que entiende StoryAudio.setAmbience (paquete de audio). Validate puede pasar otra
-- lista en ctx.Ambiences.
-- (los tipos de Config.Audio.Ambience.Kinds y sus alias más usados; "Auto" = el del sitio donde estás)
Sequencer.AmbienceKinds = {
	Auto = true,
	Calle = true,
	Parque = true,
	Casa = true,
	Colegio = true,
	Escuela = true,
	Instituto = true,
	Universidad = true,
	Hospital = true,
	Oficina = true,
	Tienda = true,
	Sala = true,
	Estacion = true,
	Nave = true,
	Ocio = true,
	Portal = true,
	Interior = true,
	Metro = true,
	Playa = true,
	Exterior = true,
}
-- Intensidades de música (StoryAudio.setIntensity)
Sequencer.Intensities = { Nada = true, Descubrimiento = true, Intima = true, Tension = true, Resolucion = true, Tema = true }
-- Requisitos que se pueden poner en If / IfNot / Variants (los de shared/LifeStory/Conditions + Late,
-- Items e Input)
Sequencer.ConditionKeys = {
	Stage = true,
	Hours = true,
	Weekdays = true,
	Completed = true,
	NotCompleted = true,
	Flags = true,
	NotFlags = true,
	Choices = true,
	NotChoices = true,
	Discovered = true,
	OnDuty = true,
	StageProgress = true,
	Rel = true,
	RelBelow = true,
	Traits = true,
	TraitsBelow = true,
	Memories = true,
	NotMemories = true,
	MemoriesAtLeast = true,
	MemoriesFewer = true,
	LastGradeBelow = true,
	LastGradeAtLeast = true,
	Season = true,
	Weather = true,
	World = true,
	NotWorld = true,
	Late = true,
	Items = true,
}
-- Gestos en la pausa de una frase (Beat)
Sequencer.Beats = {
	Mirar = "Look",
	Suelo = "Floor",
	Apartar = "Away",
	Pensar = "Away",
	Respirar = "Breath",
	Wave = "Wave",
	Point = "Point",
	Cheer = "Cheer",
	Laugh = "Laugh",
	Dance = "Dance",
	Saludar = "Wave",
	Senalar = "Point",
	Celebrar = "Cheer",
	Reir = "Laugh",
}
-- Miradas que no son un actor ni un ancla
Sequencer.LookSpecial = { Speaker = true, Suelo = true, Floor = true, Away = true, Apartar = true, Yo = true, Player = true }
Sequencer.LINE_GAP = 0.25 -- entre una frase y la siguiente
Sequencer.BEAT_PAUSE = 0.8 -- la pausa de un Beat si no se dice otra

-- Lo que se tarda en leer una frase (segundos)
function Sequencer.lineSeconds(text: any): number
	local s = if type(text) == "string" then text else ""
	local n = utf8.len(s) or #s
	return math.clamp(0.9 + n * 0.055, 1.8, 9)
end

-- Pausas de una frase: antes y después
function Sequencer.pausesOf(line: { [string]: any }): (number, number)
	local p = line.Pause
	local before, after = 0, 0
	if type(p) == "number" then
		before = math.max(p, 0)
	elseif type(p) == "table" then
		before = math.max(tonumber(p.Before or p[1]) or 0, 0)
		after = math.max(tonumber(p.After or p[2]) or 0, 0)
	end
	if line.Beat ~= nil and before == 0 then
		before = Sequencer.BEAT_PAUSE
	end
	local text = line.T or line.Text
	if type(text) == "string" and (text:sub(-3) == "…" or text:sub(-3) == "...") then
		after += 0.4 -- (los puntos suspensivos se quedan en el aire)
	end
	return before, after
end

-- Duración de un suceso (lo que ocupa en la línea de tiempo a partir de su At)
local function spanOf(track: string, data: { [string]: any }): number
	if track == "Camera" then
		return data.Duration or 1
	elseif track == "Shake" then
		return data.Seconds or 0.6
	elseif track == "Fx" or track == "Titles" then
		return data.Seconds or data.Duration or 0
	elseif track == "Lines" then
		return data.Duration or 0
	elseif track == "Dialogue" then
		return (tonumber(data.Duration) or 0) + (tonumber(data.After) or 0)
	elseif track == "Fade" then
		return data.Seconds or 0.5
	end
	return 0
end

---------------------------------------------------------------------
-- Variantes, condiciones y expansión (lo mismo en el servidor y en el cliente)
---------------------------------------------------------------------
-- La parte de Conditions de un If/IfNot (sin Input). nil si no tiene.
function Sequencer.conditionsOf(req: any): { [string]: any }?
	if type(req) ~= "table" then
		return nil
	end
	local out, any = {}, false
	for k, v in req do
		if k ~= "Input" then
			out[k] = v
			any = true
		end
	end
	return if any then out else nil
end

-- La escena con la variante `index` aplicada (sus pistas sustituyen a las de la escena)
function Sequencer.merge(def: { [string]: any }, index: number?): { [string]: any }
	local out = table.clone(def)
	out.Variants = nil
	local tracks = table.clone(def.Tracks or {})
	local variant = if index and type(def.Variants) == "table" then def.Variants[index] else nil
	if type(variant) == "table" then
		for name, list in variant.Tracks or {} do
			tracks[name] = list
		end
		for _, key in { "Duration", "Music", "Sting", "Intensity", "Until", "OnSkip", "Look", "FadeIn", "FadeOut", "Center" } do
			if variant[key] ~= nil then
				out[key] = variant[key]
			end
		end
		if type(variant.Anchors) == "table" then
			local anchors = table.clone(def.Anchors or {})
			for k, v in variant.Anchors do
				anchors[k] = v
			end
			out.Anchors = anchors
		end
		out.Variant = variant.Name or index
	end
	out.Tracks = tracks
	return out
end

-- El SERVIDOR elige al empezar: la primera variante que se cumple y, suceso a suceso, los If/IfNot con
-- condiciones. check(req) -> boolean (Conditions con el jugador). Devuelve lo que se manda al cliente:
--   { Variant = n?, Gates = { ["Pista#i"] = false|true } }
function Sequencer.resolve(def: { [string]: any }, check: (req: { [string]: any }) -> boolean): { [string]: any }
	local chosen: number? = nil
	for i, variant in (if type(def.Variants) == "table" then def.Variants else {}) do
		if type(variant) == "table" then
			local cond = Sequencer.conditionsOf(variant.If)
			if cond == nil or check(cond) then
				chosen = i
				break
			end
		end
	end
	local merged = Sequencer.merge(def, chosen)
	local gates = {}
	for track, list in merged.Tracks do
		if type(list) == "table" then
			for i, d in list do
				if type(d) == "table" then
					local yes, no = Sequencer.conditionsOf(d.If), Sequencer.conditionsOf(d.IfNot)
					if yes or no then
						gates[track .. "#" .. i] = (yes == nil or check(yes)) and (no == nil or not check(no))
					end
				end
			end
		end
	end
	return { Variant = chosen, Gates = gates }
end

-- Lo que hay que ESCRIBIR de verdad: variante aplicada, sucesos que no pasan sus condiciones quitados,
-- diálogo con sus tiempos (At, Duration, After), planos con nombre traducidos, Beats convertidos en
-- sucesos de actor. opts = lo que devolvió resolve (o nada: se queda todo).
function Sequencer.expand(def: { [string]: any }, opts: { [string]: any }?): { [string]: any }
	local o = opts or {}
	local out = Sequencer.merge(def, o.Variant)
	local tracks = out.Tracks
	local gates = if type(o.Gates) == "table" then o.Gates else nil
	if gates then
		for name, list in tracks do
			if type(list) == "table" and name ~= "Dialogue" then -- (el diálogo, abajo: cuenta los huecos)
				local kept = {}
				for i, d in list do
					if gates[name .. "#" .. i] ~= false then
						table.insert(kept, d)
					end
				end
				tracks[name] = kept
			end
		end
	end
	local keys = Sequencer.actorKeys(out)
	-- Cómo se llama cada nombre en los planos: anclas por su nombre, actores como "Actor:<clave>"
	local refs: { [string]: string } = { ["*"] = if type(out.Center) == "string" then out.Center else "Player" }
	for name in out.Anchors or {} do
		refs[name] = name
	end
	local camera = table.clone(if type(tracks.Camera) == "table" then tracks.Camera else {})
	local actors = table.clone(if type(tracks.Actors) == "table" then tracks.Actors else {})
	local hadCamera = type(tracks.Camera) == "table"
	-- Diálogo: tiempos, planos y Beats
	if type(tracks.Dialogue) == "table" then
		local lines = {}
		local cursor, prevStart, prevEnd = 0, 0, 0
		local keptPrevious = false -- ¿salió la frase de antes? (Alt solo se pega a ella si salió)
		for i, raw in tracks.Dialogue do
			if type(raw) ~= "table" or (gates and gates["Dialogue#" .. i] == false) then
				keptPrevious = false
				continue
			end
			local alt = raw.Alt == true and keptPrevious
			keptPrevious = true
			local line = table.clone(raw)
			line.S = raw.S or raw.Speaker
			line.T = raw.T or raw.Text or ""
			local before, after = Sequencer.pausesOf(raw)
			local seconds = tonumber(raw.Duration) or Sequencer.lineSeconds(line.T)
			local start: number
			if type(raw.At) == "number" then
				start = raw.At
			elseif alt then
				start = prevStart
			else
				start = cursor + before
			end
			line.At, line.Duration, line.After, line.Before, line.Index = start, seconds, after, before, i
			local lineEnd = start + seconds + after
			cursor = math.max(if alt then prevEnd else 0, lineEnd) + Sequencer.LINE_GAP
			prevStart, prevEnd = start, if alt then math.max(prevEnd, lineEnd) else lineEnd
			table.insert(lines, line)
			local beatAt = math.max(0, start - before)
			if raw.Shot ~= nil then
				table.insert(camera, CameraShots.expand({
					At = beatAt,
					Duration = math.max(seconds + after + before + Sequencer.LINE_GAP, 0.5),
					Shot = raw.Shot,
					If = raw.If,
					IfNot = raw.IfNot,
				}, refs))
			end
			local beat = if type(raw.Beat) == "string" then Sequencer.Beats[raw.Beat] else nil
			local who = line.S
			if beat and beat ~= "Breath" and type(who) == "string" and keys[who] then
				local event: { [string]: any } = { At = beatAt, If = raw.If, IfNot = raw.IfNot, Beat = true }
				if beat == "Look" then
					event.Look = { Key = who, At = raw.To or "Player", Beat = true }
				elseif beat == "Floor" then
					event.Look = { Key = who, At = "Suelo", Beat = true }
				elseif beat == "Away" then
					event.Look = { Key = who, At = "Away", Beat = true }
				else
					event.Gesture = { Key = who, Play = beat }
				end
				table.insert(actors, event)
			end
		end
		tracks.Dialogue = lines
	end
	-- Planos con nombre
	for i, shot in camera do
		camera[i] = CameraShots.expand(shot, refs)
	end
	if hadCamera or #camera > 0 then
		tracks.Camera = camera
	end
	if type(tracks.Actors) == "table" or #actors > 0 then
		tracks.Actors = actors
	end
	return out
end

-- ¿Escena LIGERA (sin cámara: solo efectos, sigues jugando)?
function Sequencer.isLight(def: { [string]: any }): boolean
	return def.Light == true or (def.Tracks or {}).Camera == nil
end

-- Ordena las pistas en una sola línea de tiempo. opts = { Variant, Gates } (Sequencer.resolve); la
-- escena ya expandida queda en timeline.Def.
function Sequencer.compile(id: string, source: { [string]: any }, opts: { [string]: any }?): Timeline
	local def = Sequencer.expand(source, opts)
	local events: { Event } = {}
	local seq = 0
	local last = 0
	for track, list in def.Tracks or {} do
		if Sequencer.Tracks[track] and type(list) == "table" then
			for _, data in list do
				seq += 1
				local at = tonumber(data.At) or 0
				table.insert(events, { At = at, Track = track, Data = data, Seq = seq })
				last = math.max(last, at + spanOf(track, data))
			end
		end
	end
	table.sort(events, function(a, b)
		if a.At ~= b.At then
			return a.At < b.At
		end
		local oa, ob = ORDER[a.Track] or 99, ORDER[b.Track] or 99
		if oa ~= ob then
			return oa < ob
		end
		return a.Seq < b.Seq
	end)
	local waits, shots, shakes = {}, {}, {}
	for _, e in events do
		if e.Track == "Wait" then
			table.insert(waits, e)
		elseif e.Track == "Camera" then
			table.insert(shots, e.Data)
		elseif e.Track == "Shake" then
			table.insert(shakes, e.Data)
		end
	end
	return {
		Id = id,
		Events = events,
		Duration = math.max(tonumber(def.Duration) or 0, last),
		Waits = waits,
		Shots = shots,
		Shakes = shakes,
		Def = def,
	}
end

-- ¿De qué lado es la pista? ("Client" | "Server" | "Both")
function Sequencer.sideOf(track: string): string?
	return Sequencer.Tracks[track]
end

-- Sucesos con from < At <= to (y At == 0 si from < 0: los del principio) del lado pedido
function Sequencer.due(timeline: Timeline, from: number, to: number, side: string?): { Event }
	local list = {}
	for _, e in timeline.Events do
		if e.At > from and e.At <= to then
			local s = Sequencer.Tracks[e.Track]
			if side == nil or s == side or s == "Both" then
				table.insert(list, e)
			end
		end
	end
	return list
end

-- La próxima espera después del segundo t (estricto: la que se acaba de cumplir no cuenta)
function Sequencer.nextWait(timeline: Timeline, after: number): Event?
	for _, e in timeline.Waits do
		if e.At > after then
			return e
		end
	end
	return nil
end

-- Reloj de la escena. run = { StartAt, Paused (segundos parada en total), PausedAt? (cuándo se paró) }
function Sequencer.sceneTime(run: { [string]: any }, now: number): number
	local reference = run.PausedAt or now
	return math.max(0, reference - (run.StartAt or now) - (run.Paused or 0))
end

-- Condición de un suceso según lo que hizo el jugador en las esperas (If / IfNot = { Input = "X" })
function Sequencer.passes(data: { [string]: any }, inputs: { [string]: any }?): boolean
	local results = inputs or {}
	if type(data.If) == "table" and data.If.Input ~= nil and not results[data.If.Input] then
		return false
	end
	if type(data.IfNot) == "table" and data.IfNot.Input ~= nil and results[data.IfNot.Input] then
		return false
	end
	return true
end

-- Al saltar la escena en el segundo t: lo que el SERVIDOR aún no ha hecho y debe dejar hecho (para que
-- las consecuencias sean las mismas que viéndola entera). En orden. Las apariciones se hacen, los
-- paseos se convierten en «ponerse ya en el destino», los gestos y frases sueltas se olvidan.
function Sequencer.skipPlan(timeline: Timeline, t: number, inputs: { [string]: any }?): { Event }
	local plan = {}
	for _, e in timeline.Events do
		if e.At > t and Sequencer.Tracks[e.Track] == "Server" and Sequencer.passes(e.Data, inputs) then
			if e.Track == "World" then
				table.insert(plan, e)
			elseif e.Track == "Actors" then
				local d = e.Data
				if d.Spawn or d.Enter or d.Move or d.Despawn or d.Exit or d.Mood or d.Face then
					table.insert(plan, e)
				end
			end
		end
	end
	return plan
end

-- Cuánto puede tardar como mucho (con todas las esperas a tope): para quien espera a que acabe
function Sequencer.maxDuration(timeline: Timeline): number
	local extra = 0
	for _, w in timeline.Waits do
		local d = w.Data
		extra += math.min(tonumber(d.Timeout or d.Seconds) or Sequencer.MAX_WAIT, Sequencer.MAX_WAIT)
	end
	local untilSpec = timeline.Def and timeline.Def.Until
	if type(untilSpec) == "table" then
		extra += Sequencer.untilTimeout(untilSpec)
	end
	return timeline.Duration + extra
end

-- Cuánto se espera como mucho el aviso de Until después del final
function Sequencer.untilTimeout(spec: { [string]: any }): number
	return math.clamp(tonumber(spec.Timeout) or Sequencer.MAX_WAIT, 0, Sequencer.MAX_WAIT)
end

-- Las claves de actor que la escena crea (Spawn) o toma prestadas de tu misión (Use)
function Sequencer.actorKeys(def: { [string]: any }): { [string]: string }
	local keys = {}
	for _, d in (def.Tracks or {}).Actors or {} do
		if type(d) ~= "table" then
			continue
		end
		if type(d.Spawn) == "table" and d.Spawn.Key then
			keys[d.Spawn.Key] = "Spawn"
		elseif type(d.Enter) == "table" and d.Enter.Key then
			keys[d.Enter.Key] = "Spawn"
		elseif type(d.Use) == "table" and d.Use.Key then
			keys[d.Use.Key] = "Use"
		end
	end
	return keys
end

---------------------------------------------------------------------
-- Comprobación de una escena (Validate y las pruebas)
---------------------------------------------------------------------
-- ctx (todo opcional): Fx = { [nombre]=true }, Moods = {…}, SkyMoods = {…}, Creatures = {…},
--   Places = Locations.Places, Zones = { "Valmar Centro", … }, Cast = Cast.People,
--   Events = EventCatalog.Names (Until), Ambiences = { [capa]=true }, Poses = { [postura]=true } (A),
--   Music = Config.Audio.Music (Play)
local validateBody -- (más abajo)

-- Comprueba un If / IfNot / Variants.If: Input y los requisitos de Conditions (más Late e Items)
local function checkConditions(where: string, req: any, c: { [string]: any }, err: (string, ...any) -> ())
	if req == nil then
		return
	end
	if type(req) ~= "table" then
		err("%s: condición mal escrita", where)
		return
	end
	for k, v in req do
		if k == "Input" then
			if type(v) ~= "string" then
				err("%s: Input debe ser un nombre", where)
			end
		elseif not Sequencer.ConditionKeys[k] then
			err("%s: condición desconocida '%s'", where, tostring(k))
		elseif k == "Late" and type(v) ~= "boolean" then
			err("%s: Late es true o false", where)
		elseif k == "Items" then
			if type(v) ~= "table" then
				err("%s: Items = { Objeto = cantidad }", where)
			else
				for item, n in v do
					if type(item) ~= "string" or type(n) ~= "number" then
						err("%s: Items = { Objeto = cantidad }", where)
					end
				end
			end
		elseif (k == "Rel" or k == "RelBelow") and type(v) == "table" and c.Cast then
			for npc in v do
				if not c.Cast[npc] then
					err("%s: %s de '%s', que no está en el reparto", where, k, tostring(npc))
				end
			end
		elseif (k == "Flags" or k == "NotFlags" or k == "Memories" or k == "NotMemories" or k == "Completed" or k == "NotCompleted") and type(v) ~= "table" then
			err("%s: %s es una lista", where, k)
		end
	end
end

function Sequencer.validate(id: string, def: { [string]: any }, ctx: { [string]: any }?): { string }
	local c = ctx or {}
	local errors = {}
	local base: { [string]: boolean } = {}
	local function collect(label: string?, source: { [string]: any }, record: boolean)
		for _, message in validateBody(source, c) do
			if record then
				base[message] = true
				table.insert(errors, ("escena %s: %s"):format(id, message))
			elseif not base[message] then
				base[message] = true
				table.insert(errors, ("escena %s (%s): %s"):format(id, label or "?", message))
			end
		end
	end
	if type(def.Tracks) ~= "table" then
		table.insert(errors, ("escena %s: sin pistas (Tracks)"):format(id))
		return errors
	end
	collect(nil, Sequencer.merge(def, nil), true)
	if def.Variants ~= nil then
		if type(def.Variants) ~= "table" then
			table.insert(errors, ("escena %s: Variants es una lista"):format(id))
		else
			for i, variant in def.Variants do
				local label = "variante " .. tostring(type(variant) == "table" and variant.Name or i)
				if type(variant) ~= "table" then
					table.insert(errors, ("escena %s: %s mal escrita"):format(id, label))
					continue
				end
				checkConditions(label .. ".If", variant.If, c, function(fmt, ...)
					table.insert(errors, ("escena %s: " .. fmt):format(id, ...))
				end)
				if variant.Tracks ~= nil and type(variant.Tracks) ~= "table" then
					table.insert(errors, ("escena %s: %s: Tracks mal escrito"):format(id, label))
				else
					collect(label, Sequencer.merge(def, i), false)
				end
			end
		end
	end
	return errors
end

function validateBody(def: { [string]: any }, c: { [string]: any }): { string }
	local errors = {}
	local function err(fmt: string, ...)
		table.insert(errors, fmt:format(...))
	end
	for track in def.Tracks do
		if not Sequencer.Tracks[track] then
			err("pista desconocida '%s'", tostring(track))
		end
	end
	-- Anclas
	local anchors = def.Anchors or {}
	for name, anchor in anchors do
		if type(anchor) == "table" then
			if c.Places and anchor.Place and not c.Places[anchor.Place] then
				err("ancla %s: lugar desconocido '%s'", name, tostring(anchor.Place))
			end
		elseif type(anchor) == "string" then
			local kind, value = anchor:match("^(%a+):(.+)$")
			local known = anchor == "Player" or anchor == "Rift" or kind == "Actor"
			if kind == "Place" then
				known = c.Places == nil or c.Places[value] ~= nil
			elseif kind == "Zone" then
				known = c.Zones == nil or table.find(c.Zones, value) ~= nil
			end
			if not known then
				err("ancla %s no válida '%s'", name, anchor)
			end
		else
			err("ancla %s de tipo raro", tostring(name))
		end
	end
	local keys = Sequencer.actorKeys(def)
	-- Un nombre de ancla vale si es un ancla, un actor de la escena, un efecto con Key o "Player"
	local fxKeys = {}
	for _, d in def.Tracks.Fx or {} do
		if d.Key then
			fxKeys[d.Key] = true
		end
	end
	local function anchorName(where: string, name: any)
		if type(name) ~= "string" then
			err("%s: ancla sin nombre", where)
			return
		end
		if name == "Player" or anchors[name] then
			return
		end
		local a, b = name:match("^Mid:(.+)|(.+)$")
		if not a then
			a, b = name:match("^Wide:(.+)|(.+)$")
		end
		if not a then
			a, b = name:match("^Toward:(.+)>(.+)$")
		end
		if a and b then
			anchorName(where, a)
			anchorName(where, b)
			return
		end
		local kind, value = name:match("^(%a+):(.+)$")
		if kind == "Actor" and keys[value] then
			return
		elseif kind == "Fx" and fxKeys[value] then
			return
		end
		err("%s: ancla desconocida '%s'", where, name)
	end
	-- Un nombre de personaje u objeto en un plano, una mirada o un To: "Yo", una clave, un ancla…
	local function who(where: string, name: any)
		if type(name) ~= "string" then
			err("%s: nombre mal escrito", where)
			return
		end
		if name == "Yo" or name == "Player" or anchors[name] or keys[name] then
			return
		end
		if name:match("^%a+:") then
			anchorName(where, name)
			return
		end
		err("%s: '%s' no es un actor de la escena ni un ancla", where, name)
	end
	local function shotName(where: string, spec: any)
		local kind, args = CameraShots.parsePreset(spec)
		local _, problem = CameraShots.preset(spec, nil)
		if problem then
			err("%s: %s", where, problem)
			return
		end
		local _ = kind
		for _, name in args do
			who(where, name)
		end
	end
	local function point(where: string, p: any)
		if p ~= nil then
			if type(p) ~= "table" then
				err("%s: punto mal escrito", where)
			else
				anchorName(where, p[1])
			end
		end
	end
	local function at(where: string, d: { [string]: any })
		if type(d.At) ~= "number" or d.At < 0 then
			err("%s: falta At (segundo)", where)
		end
	end
	for i, shot in def.Tracks.Camera or {} do
		local where = "Camera[" .. i .. "]"
		at(where, shot)
		if type(shot.Duration) ~= "number" or shot.Duration <= 0 then
			err("%s: falta Duration", where)
		end
		if shot.Shot ~= nil then
			shotName(where, shot.Shot)
		elseif shot.Orbit then
			anchorName(where, shot.Orbit)
		elseif shot.Follow then
			anchorName(where, shot.Follow)
			point(where, shot.Look)
		elseif shot.Fixed then
			point(where, shot.Fixed)
			point(where, shot.Look)
			if not shot.Look then
				err("%s: plano fijo sin Look", where)
			end
		elseif shot.From then
			point(where, shot.From)
			point(where, shot.To)
			point(where, shot.Look)
			point(where, shot.LookTo)
			if not shot.Look then
				err("%s: travelling sin Look", where)
			end
		else
			err("%s: plano sin tipo (From/Fixed/Orbit/Follow/Shot)", where)
		end
		if shot.Cut ~= nil and not ({ Cut = true, Dip = true, Fade = true, Flash = true })[shot.Cut] then
			err("%s: transición desconocida '%s'", where, tostring(shot.Cut))
		end
	end
	for i, s in def.Tracks.Shake or {} do
		at("Shake[" .. i .. "]", s)
	end
	for i, fx in def.Tracks.Fx or {} do
		local where = "Fx[" .. i .. "]"
		at(where, fx)
		if c.Fx and not c.Fx[fx.Play] then
			err("%s: efecto desconocido '%s'", where, tostring(fx.Play))
		end
		anchorName(where, fx.Anchor or "Player")
		if fx.To then
			point(where, fx.To)
		end
	end
	for i, sky in def.Tracks.Sky or {} do
		local where = "Sky[" .. i .. "]"
		at(where, sky)
		if sky.Mood ~= nil and sky.Mood ~= false and c.SkyMoods and not c.SkyMoods[sky.Mood] then
			err("%s: cielo desconocido '%s'", where, tostring(sky.Mood))
		end
	end
	for i, s in def.Tracks.Sound or {} do
		at("Sound[" .. i .. "]", s)
		if type(s.Play) ~= "string" then
			err("Sound[%d]: falta Play", i)
		end
		if s.Anchor then
			anchorName("Sound[" .. i .. "]", s.Anchor)
		end
	end
	for i, line in def.Tracks.Lines or {} do
		local where = "Lines[" .. i .. "]"
		at(where, line)
		if type(line.Text) ~= "string" or line.Text == "" then
			err("%s: frase vacía", where)
		end
		local speaker = line.Speaker
		if speaker ~= nil and speaker ~= "Narrador" and speaker ~= "Yo" and not keys[speaker] and not (c.Cast and c.Cast[speaker]) and c.Cast ~= nil then
			err("%s: quién habla '%s' no es un actor de la escena ni del reparto", where, tostring(speaker))
		end
		if line.Mood ~= nil and c.Moods and not c.Moods[line.Mood] then
			err("%s: emoción desconocida '%s'", where, tostring(line.Mood))
		end
	end
	for i, title in def.Tracks.Titles or {} do
		at("Titles[" .. i .. "]", title)
	end
	local spawned: { [string]: boolean } = {}
	local actorEvents = {}
	for i, d in def.Tracks.Actors or {} do
		table.insert(actorEvents, { I = i, D = d })
	end
	table.sort(actorEvents, function(a, b)
		return (a.D.At or 0) < (b.D.At or 0)
	end)
	for _, entry in actorEvents do
		local i, d = entry.I, entry.D
		local where = "Actors[" .. i .. "]"
		at(where, d)
		local op = nil
		for name in Sequencer.ActorOps do
			if d[name] ~= nil then
				if op then
					err("%s: dos órdenes en un suceso (%s y %s)", where, op, name)
				end
				op = name
			end
		end
		if not op then
			err("%s: sin orden (Spawn/Use/Move/Look/Mood/Gesture/Say/Despawn)", where)
			continue
		end
		local body = d[op]
		local key = type(body) == "table" and body.Key or nil
		if type(key) ~= "string" then
			err("%s: falta Key", where)
			continue
		end
		if op == "Spawn" or op == "Enter" then
			if body.Npc == nil and body.Creature == nil then
				err("%s: %s sin Npc ni Creature", where, op)
			end
			if c.Cast and body.Npc and not c.Cast[body.Npc] then
				err("%s: Npc '%s' no está en el reparto", where, tostring(body.Npc))
			end
			if c.Creatures and body.Creature and not c.Creatures[body.Creature] then
				err("%s: criatura desconocida '%s'", where, tostring(body.Creature))
			end
			anchorName(where, body.Anchor or "Player")
			if op == "Enter" then
				if body.From == nil then
					err("%s: Enter sin From (por dónde entra)", where)
				elseif type(body.From) == "string" then
					anchorName(where, body.From)
				else
					point(where, body.From)
				end
				if type(body.To) == "string" then
					anchorName(where, body.To)
				else
					point(where, body.To)
				end
				if body.Walk ~= nil and type(body.Walk) ~= "boolean" then
					err("%s: Walk es true o false", where)
				end
			end
			spawned[key] = true
		elseif op == "Use" then
			if c.Cast and not c.Cast[body.Npc or key] then
				err("%s: Use de '%s' que no está en el reparto", where, tostring(body.Npc or key))
			end
			spawned[key] = true
		else
			if not spawned[key] then
				err("%s: %s de '%s' antes de que aparezca (Spawn/Use)", where, op, key)
			end
			if op == "Move" then
				point(where, body.To)
				if body.To == nil then
					err("%s: Move sin To", where)
				end
			elseif op == "Mood" and c.Moods and body.Mood ~= nil and not c.Moods[body.Mood] then
				err("%s: emoción desconocida '%s'", where, tostring(body.Mood))
			elseif op == "Exit" then
				if type(body.To) == "string" then
					anchorName(where, body.To)
				elseif body.To ~= nil then
					point(where, body.To)
				end
			elseif op == "Look" then
				local target = body.At
				if target ~= nil and target ~= false and not Sequencer.LookSpecial[target] then
					who(where, target)
				end
			end
			if op == "Despawn" or op == "Exit" then
				spawned[key] = nil
			end
		end
		checkConditions(where .. ".If", d.If, c, err)
		checkConditions(where .. ".IfNot", d.IfNot, c, err)
		if (op == "Spawn" or op == "Enter") and body.Mood and c.Moods and not c.Moods[body.Mood] then
			err("%s: emoción desconocida '%s'", where, tostring(body.Mood))
		end
	end
	for i, w in def.Tracks.Wait or {} do
		local where = "Wait[" .. i .. "]"
		at(where, w)
		local kinds = 0
		for k in Sequencer.WaitKinds do
			if w[k] ~= nil then
				kinds += 1
			end
		end
		if kinds ~= 1 then
			err("%s: una espera necesita UNA condición (Seconds/Input/Near/Arrived)", where)
		end
		if w.Near then
			anchorName(where, w.Near[1])
		end
		if w.Arrived and not keys[w.Arrived] then
			err("%s: Arrived de un actor que no existe '%s'", where, tostring(w.Arrived))
		end
		if w.Input and type(w.Input) ~= "string" then
			err("%s: Input debe ser un nombre (el resultado)", where)
		end
	end
	for i, wv in def.Tracks.World or {} do
		at("World[" .. i .. "]", wv)
		if type(wv.Set) ~= "table" then
			err("World[%d]: falta Set = { [clave] = valor }", i)
		end
	end
	-- Diálogo (CINEMATIC_SCENE)
	for i, line in def.Tracks.Dialogue or {} do
		local where = "Dialogue[" .. i .. "]"
		if type(line) ~= "table" then
			err("%s: frase mal escrita", where)
			continue
		end
		if line.At ~= nil and (type(line.At) ~= "number" or line.At < 0) then
			err("%s: At mal escrito", where)
		end
		local text = line.T or line.Text
		if type(text) ~= "string" or text == "" then
			err("%s: frase vacía (T)", where)
		end
		local speaker = line.S or line.Speaker
		if type(speaker) ~= "string" then
			err("%s: falta quién habla (S)", where)
		elseif speaker ~= "Narrador" and speaker ~= "Yo" and not keys[speaker] and c.Cast ~= nil and not c.Cast[speaker] then
			err("%s: quién habla '%s' no es un actor de la escena ni del reparto", where, speaker)
		end
		if line.To ~= nil then
			who(where .. ".To", line.To)
		end
		if line.Mood ~= nil and c.Moods and not c.Moods[line.Mood] then
			err("%s: emoción desconocida '%s'", where, tostring(line.Mood))
		end
		if line.A ~= nil and (type(line.A) ~= "string" or (c.Poses and not c.Poses[line.A])) then
			err("%s: postura (A) desconocida '%s'", where, tostring(line.A))
		end
		if line.G ~= nil and type(line.G) ~= "string" then
			err("%s: gesto (G) mal escrito", where)
		end
		local pause = line.Pause
		if pause ~= nil then
			local ok = (type(pause) == "number" and pause >= 0)
				or (
					type(pause) == "table"
					and (pause.Before == nil or type(pause.Before) == "number")
					and (pause.After == nil or type(pause.After) == "number")
				)
			if not ok then
				err("%s: Pause = segundos o { Before, After }", where)
			end
		end
		if line.Beat ~= nil and not (type(line.Beat) == "string" and Sequencer.Beats[line.Beat]) then
			err("%s: Beat desconocido '%s'", where, tostring(line.Beat))
		end
		if line.Shot ~= nil then
			shotName(where .. ".Shot", line.Shot)
		end
		if line.Duration ~= nil and (type(line.Duration) ~= "number" or line.Duration <= 0) then
			err("%s: Duration mal escrita", where)
		end
		if line.Alt ~= nil and type(line.Alt) ~= "boolean" then
			err("%s: Alt es true o false", where)
		end
	end
	-- Ambiente, luz y música por intensidad
	local ambiences = c.Ambiences or Sequencer.AmbienceKinds
	for i, a in def.Tracks.Ambience or {} do
		local where = "Ambience[" .. i .. "]"
		at(where, a)
		if a.Kind ~= false and not (type(a.Kind) == "string" and ambiences[a.Kind]) then
			err("%s: ambiente desconocido '%s'", where, tostring(a.Kind))
		end
		if a.Fade ~= nil and type(a.Fade) ~= "number" then
			err("%s: Fade = segundos", where)
		end
	end
	for i, l in def.Tracks.Light or {} do
		local where = "Light[" .. i .. "]"
		at(where, l)
		if l.Preset ~= false and not CameraShots.light(l.Preset) then
			err("%s: luz desconocida '%s'", where, tostring(l.Preset))
		end
		if (l.Fade ~= nil and type(l.Fade) ~= "number") or (l.Weight ~= nil and type(l.Weight) ~= "number") then
			err("%s: Fade y Weight son números", where)
		end
	end
	for i, m in def.Tracks.Music or {} do
		local where = "Music[" .. i .. "]"
		at(where, m)
		if m.Intensity ~= nil then
			if not Sequencer.Intensities[m.Intensity] then
				err("%s: intensidad desconocida '%s'", where, tostring(m.Intensity))
			end
		elseif type(m.Play) ~= "string" then
			err("%s: falta Play (música) o Intensity", where)
		elseif c.Music and not c.Music[m.Play] then
			err("%s: música desconocida '%s'", where, m.Play)
		end
	end
	if def.Intensity ~= nil and not Sequencer.Intensities[def.Intensity] then
		err("intensidad desconocida '%s'", tostring(def.Intensity))
	end
	if def.Look ~= nil and def.Look ~= false and def.Look ~= "Speaker" then
		err('Look de la escena es "Speaker" o false')
	end
	if def.Center ~= nil then
		who("Center", def.Center)
	end
	-- Condiciones de cada suceso (las de Actors ya se miraron)
	for track, list in def.Tracks do
		if track ~= "Actors" and type(list) == "table" then
			for i, d in list do
				if type(d) == "table" then
					checkConditions(("%s[%d].If"):format(track, i), d.If, c, err)
					checkConditions(("%s[%d].IfNot"):format(track, i), d.IfNot, c, err)
				end
			end
		end
	end
	-- Condición de final y salto
	if def.Until ~= nil then
		local u = def.Until
		if type(u) ~= "table" or type(u.Event) ~= "string" then
			err('Until = { Event = "Nombre" }')
		else
			if c.Events and not c.Events[u.Event] then
				err("Until: aviso desconocido '%s' (EventCatalog)", u.Event)
			end
			if u.Timeout ~= nil and (type(u.Timeout) ~= "number" or u.Timeout < 0) then
				err("Until: Timeout = segundos")
			end
			if u.Match ~= nil and type(u.Match) ~= "table" then
				err("Until: Match = { campo = valor }")
			end
		end
	end
	if def.OnSkip ~= nil then
		local o = def.OnSkip
		if type(o) ~= "table" then
			err("OnSkip mal escrito")
		else
			for k in o do
				if k ~= "Inputs" and k ~= "World" then
					err("OnSkip: campo desconocido '%s' (Inputs, World)", tostring(k))
				end
			end
			if o.Inputs ~= nil then
				local fine = type(o.Inputs) == "table"
				for k, v in (if fine then o.Inputs else {}) do
					if type(k) ~= "string" or type(v) ~= "boolean" then
						fine = false
					end
				end
				if not fine then
					err("OnSkip.Inputs = { Nombre = true|false }")
				end
			end
			if o.World ~= nil and type(o.World) ~= "table" then
				err("OnSkip.World = { [clave] = valor }")
			end
		end
	end
	-- La duración tiene que cubrir lo último que pasa
	local timeline = Sequencer.compile("validate", def)
	if def.Duration and def.Duration + 1e-6 < timeline.Duration then
		err("Duration (%s) es menor que la última pista (%.2f)", tostring(def.Duration), timeline.Duration)
	end
	return errors
end

return Sequencer
