-- Sequencer: el MOTOR DE ESCENAS de la historia (cuentas puras, sin servicios de Roblox).
--
-- Una escena («acontecimiento», shared/LifeStory/Happenings/*) es una línea de tiempo con PISTAS.
-- Cada pista es una lista de sucesos con At (segundo de la escena). Aquí se ordenan, se comprueban,
-- se calcula cuánto duran, qué toca entre dos instantes, qué hay que aplicar de golpe si el jugador
-- SALTA la escena y cómo corre el reloj con las ESPERAS (la escena se para hasta que pasa algo).
--
-- Quién hace cada pista (Side):
--   Servidor  Actors (aparecer, andar, mirar, emoción, gesto, irse), World (memoria del mundo)
--   Cliente   Camera, Shake, Fx, Sky, Sound, Music, Lines, Titles, Fade
--   Los dos   Wait (la escena se para: el servidor decide cuándo sigue; el cliente congela su reloj)
--
-- Reloj de la escena (el mismo en el servidor y en el cliente, con workspace:GetServerTimeNow()):
--   t = ahora − StartAt − Paused     (y mientras está parada, t se queda en el punto de la espera)
--
-- Las pruebas: scripts/test-scenes.luau.

local Sequencer = {}

export type Event = { At: number, Track: string, Data: { [string]: any }, Seq: number }
export type Timeline = {
	Id: string,
	Events: { Event },
	Duration: number,
	Waits: { Event },
	Shots: { { [string]: any } },
	Shakes: { { [string]: any } },
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
	Actors = "Server",
	World = "Server",
	Wait = "Both",
}
-- Orden dentro del mismo segundo: primero el mundo y los actores (para que la cámara ya los encuentre)
local ORDER = { World = 1, Actors = 2, Wait = 3, Camera = 4, Sky = 5, Fx = 6, Shake = 7, Sound = 8, Music = 9, Lines = 10, Titles = 11, Fade = 12 }

Sequencer.ActorOps = { Spawn = true, Use = true, Move = true, Look = true, Mood = true, Gesture = true, Say = true, Despawn = true, Face = true }
Sequencer.WaitKinds = { Seconds = true, Input = true, Near = true, Arrived = true }
Sequencer.MAX_WAIT = 120 -- una espera no dura más (si nadie hace nada, la escena sigue)

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
	elseif track == "Fade" then
		return data.Seconds or 0.5
	end
	return 0
end

-- Ordena las pistas en una sola línea de tiempo
function Sequencer.compile(id: string, def: { [string]: any }): Timeline
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
				if d.Spawn or d.Move or d.Despawn or d.Mood or d.Face then
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
	return timeline.Duration + extra
end

-- Las claves de actor que la escena crea (Spawn) o toma prestadas de tu misión (Use)
function Sequencer.actorKeys(def: { [string]: any }): { [string]: string }
	local keys = {}
	for _, d in (def.Tracks or {}).Actors or {} do
		if type(d.Spawn) == "table" and d.Spawn.Key then
			keys[d.Spawn.Key] = "Spawn"
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
--   Places = Locations.Places, Zones = { "Valmar Centro", … }, Cast = Cast.People
function Sequencer.validate(id: string, def: { [string]: any }, ctx: { [string]: any }?): { string }
	local c = ctx or {}
	local errors = {}
	local function err(fmt: string, ...)
		table.insert(errors, ("escena %s: " .. fmt):format(id, ...))
	end
	if type(def.Tracks) ~= "table" then
		err("sin pistas (Tracks)")
		return errors
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
		local kind, value = name:match("^(%a+):(.+)$")
		if kind == "Actor" and keys[value] then
			return
		elseif kind == "Fx" and fxKeys[value] then
			return
		end
		err("%s: ancla desconocida '%s'", where, name)
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
		if shot.Orbit then
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
			err("%s: plano sin tipo (From/Fixed/Orbit/Follow)", where)
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
		local who = line.Speaker
		if who ~= nil and who ~= "Narrador" and who ~= "Yo" and not keys[who] and not (c.Cast and c.Cast[who]) and c.Cast ~= nil then
			err("%s: quién habla '%s' no es un actor de la escena ni del reparto", where, tostring(who))
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
		if op == "Spawn" then
			if body.Npc == nil and body.Creature == nil then
				err("%s: Spawn sin Npc ni Creature", where)
			end
			if c.Cast and body.Npc and not c.Cast[body.Npc] then
				err("%s: Npc '%s' no está en el reparto", where, tostring(body.Npc))
			end
			if c.Creatures and body.Creature and not c.Creatures[body.Creature] then
				err("%s: criatura desconocida '%s'", where, tostring(body.Creature))
			end
			anchorName(where, body.Anchor or "Player")
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
			end
			if op == "Despawn" then
				spawned[key] = nil
			end
		end
		if op == "Spawn" and body.Mood and c.Moods and not c.Moods[body.Mood] then
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
	-- La duración tiene que cubrir lo último que pasa
	local timeline = Sequencer.compile(id, def)
	if def.Duration and def.Duration + 1e-6 < timeline.Duration then
		err("Duration (%s) es menor que la última pista (%.2f)", tostring(def.Duration), timeline.Duration)
	end
	return errors
end

return Sequencer
