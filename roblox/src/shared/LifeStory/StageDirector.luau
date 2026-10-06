-- StageDirector: la ESCENIFICACIÓN AUTOMÁTICA de las conversaciones (auditoría §6.1, paquete P5).
--
-- Las 294 escenas de conversación (pasos Scene) y las charlas (Talk) se escribieron como texto. No se
-- reescriben a mano: esta capa toma su Dialogue de siempre y le añade puesta en escena:
--   1. Entrada: quien está lejos se acerca unos pasos y se gira (lo pide el servidor: atributo
--      StageApproach del jugador; lo hace SceneService).
--   2. Plano general de situación (0,8 s) → planos de hombro o de dos según quién hable → plano de
--      reacción en las preguntas.
--   3. Todo el reparto mira a quien habla (atributos StageSpeaker/StageTo del jugador en el cliente;
--      ActorLife).
--   4. Pausas por la puntuación: «…» = 0,6 s, «.» al final de una frase = 0,3 s.
--   5. Salida suave de la cámara (DialogueUI).
--
-- Campos NUEVOS y OPCIONALES de cada línea (el formato viejo sigue valiendo igual):
--   Pause = 0.8 | { Before = 0.8, After = 0.5 }   silencio antes (y después) de la frase, en segundos
--   Beat  = "Respira" | "Mira" | "Piensa" | …  | 1.2   un tiempo de actuación ANTES de la frase: quien
--           habla respira, mira, piensa… sin texto (un número = segundos de silencio)
--   To    = "Sara" | "Yo"                       a quién le habla (mirada y plano de dos)
--   Shot  = "PrimerPlano:Mateo" | "Hombro:Yo>Nico" | "DosPlanos:Omar,Sara" | "General" | …
--           el plano que pide la línea (si no, lo elige el director)
-- Y de cada diálogo: Staging = false (sin escenificación: la cámara de siempre).
--
-- Acotaciones: «(susurrando) Si nos pillan…», «(al teléfono) ¿Qué tal…?», «(Omar levanta el pulgar)».
-- El paréntesis del principio se quita del texto y se convierte en ACCIÓN (gesto, mirada, voz baja,
-- teléfono, desde lejos). Si la línea entera es una acotación, el actor la hace y el texto queda como
-- subtítulo en cursiva (sin bocadillo).
--
-- Módulo puro (sin servicios de Roblox): lo usan DialogueService (servidor), DialogueUI y SpeechBubbles
-- (cliente) y Validate, y se prueba con Lune (scripts/test-stagedirector.luau).

local StageDirector = {}

---------------------------------------------------------------------
-- Tiempos
---------------------------------------------------------------------

StageDirector.ESTABLISH = 0.8 -- plano general de situación al empezar
StageDirector.ESTABLISH_MAX = 1.8 -- como mucho (si alguien se está acercando, se espera un poco más)
StageDirector.ELLIPSIS = 0.6 -- pausa en «…»
StageDirector.STOP = 0.3 -- pausa en el punto de final de frase
StageDirector.MAX_PAUSE = 4 -- ninguna pausa escrita pasa de esto (ni se queda colgada)
StageDirector.MAX_BEAT = 3
StageDirector.EXIT_SECONDS = 0.9 -- la cámara vuelve al juego en este rato
StageDirector.REACTION_SECONDS = 0.9 -- plano de reacción tras una pregunta

-- Entrada: quien está entre MIN y MAX studs se acerca hasta STOP (más lejos: no está en la escena)
StageDirector.APPROACH_MIN = 9
StageDirector.APPROACH_MAX = 60
StageDirector.APPROACH_STOP = 5

---------------------------------------------------------------------
-- Tiempos de actuación (Beat)
---------------------------------------------------------------------

-- Look: "To" (a quien le habla), "Down" (al suelo: vergüenza), "Away" (a otro lado: piensa)
StageDirector.Beats = {
	Respira = { Seconds = 0.9 },
	Silencio = { Seconds = 1.0 },
	Mira = { Seconds = 0.8, Look = "To" },
	Piensa = { Seconds = 1.2, Gesture = "ThinkChin", Look = "Away" },
	Suspira = { Seconds = 1.1, Gesture = "Sad" },
	Asiente = { Seconds = 0.8, Gesture = "Nod" },
	Niega = { Seconds = 0.8, Gesture = "No" },
	Sonrie = { Seconds = 0.8, Gesture = "Happy" },
	Baja = { Seconds = 1.0, Look = "Down" },
	Aparta = { Seconds = 1.0, Look = "Away" },
}

-- Un Beat de una línea → { Seconds, Gesture?, Look? } (nil si no lleva o no vale)
function StageDirector.beat(value: any): { [string]: any }?
	if type(value) == "number" then
		if value > 0 then
			return { Seconds = math.min(value, StageDirector.MAX_BEAT) }
		end
		return nil
	elseif type(value) == "string" then
		local def = StageDirector.Beats[value]
		if def then
			return { Seconds = def.Seconds, Gesture = def.Gesture, Look = def.Look, Name = value }
		end
	end
	return nil
end

-- Pausas escritas de una línea: (antes, después) en segundos, con tope
function StageDirector.pauseOf(line: { [string]: any }): (number, number)
	local p = line.Pause
	local before, after = 0, 0
	if type(p) == "number" then
		before = p
	elseif type(p) == "table" then
		before = if type(p.Before) == "number" then p.Before else 0
		after = if type(p.After) == "number" then p.After else 0
	end
	return math.clamp(before, 0, StageDirector.MAX_PAUSE), math.clamp(after, 0, StageDirector.MAX_PAUSE)
end

---------------------------------------------------------------------
-- Pausas por la puntuación (el texto se escribe letra a letra y se para en «…» y en los puntos)
---------------------------------------------------------------------

local ELLIPSIS_CHAR = utf8.char(0x2026) -- …

-- Lista de letras (graphemes ≈ caracteres UTF-8) de un texto
local function chars(text: string): { string }
	local list = {}
	local ok = pcall(function()
		for _, code in utf8.codes(text) do
			table.insert(list, utf8.char(code))
		end
	end)
	if not ok then
		list = {}
		for i = 1, #text do
			table.insert(list, text:sub(i, i))
		end
	end
	return list
end

local CLOSERS = { ["»"] = true, ['"'] = true, [")"] = true, ["”"] = true }

-- Pausas de un texto: { { At = letras escritas cuando se para, Seconds } } y la pausa del final
-- (tail: lo que se espera al acabar de escribir antes de seguir: «.» → 0,3; «…» → 0,6)
function StageDirector.pauses(text: string?): ({ { At: number, Seconds: number } }, number)
	local list = {}
	local tail = 0
	if type(text) ~= "string" or text == "" then
		return list, 0
	end
	local c = chars(text)
	local n = #c
	local i = 1
	while i <= n do
		local ch = c[i]
		local seconds, last = 0, i
		if ch == ELLIPSIS_CHAR then
			seconds = StageDirector.ELLIPSIS
		elseif ch == "." and c[i + 1] == "." and c[i + 2] == "." then
			seconds, last = StageDirector.ELLIPSIS, i + 2
		elseif ch == "." or ch == "!" or ch == "?" then
			-- Final de frase: el punto (o ! ?) seguido de espacio o del final (no 3.5, ni «¿¡» encadenados)
			local nextChar = c[i + 1]
			if nextChar == nil or nextChar == " " or CLOSERS[nextChar] then
				seconds = StageDirector.STOP
			end
		end
		if seconds > 0 then
			-- Las comillas o paréntesis que cierran se escriben antes de la pausa
			while c[last + 1] and CLOSERS[c[last + 1]] do
				last += 1
			end
			local rest = false
			for j = last + 1, n do
				if c[j] ~= " " then
					rest = true
					break
				end
			end
			if rest then
				table.insert(list, { At = last, Seconds = seconds })
			else
				tail = math.max(tail, seconds)
			end
			i = last + 1
		else
			i += 1
		end
	end
	return list, tail
end

-- Cuántas letras se ven a los `elapsed` segundos de empezar a escribir (speed letras por segundo,
-- parándose en las pausas). total = letras del texto.
function StageDirector.revealed(elapsed: number, speed: number, total: number, pauses: { { At: number, Seconds: number } }?): number
	if speed <= 0 then
		return total
	end
	local t = math.max(0, elapsed)
	local shown = 0
	for _, p in pauses or {} do
		local at = math.min(p.At, total)
		if at > shown then
			local need = (at - shown) / speed
			if t < need then
				return math.min(total, shown + math.floor(t * speed))
			end
			t -= need
			shown = at
		end
		if t < p.Seconds then
			return shown
		end
		t -= p.Seconds
	end
	return math.min(total, shown + math.floor(t * speed))
end

-- Lo que tarda en escribirse entero (sin la pausa final)
function StageDirector.typingSeconds(text: string?, speed: number): number
	local list = StageDirector.pauses(text)
	local total = if type(text) == "string" then (utf8.len(text) or #text) else 0
	local seconds = total / math.max(speed, 1)
	for _, p in list do
		seconds += p.Seconds
	end
	return seconds
end

---------------------------------------------------------------------
-- Acotaciones: «(susurrando) …» → acción
---------------------------------------------------------------------

local function lower(s: string): string
	s = s:lower()
	for upper, low in { ["Á"] = "á", ["É"] = "é", ["Í"] = "í", ["Ó"] = "ó", ["Ú"] = "ú", ["Ñ"] = "ñ" } do
		s = s:gsub(upper, low)
	end
	return s
end

-- Lo que se reconoce en una acotación, por orden (la primera de cada tipo gana)
local REMOTE = {
	{ "al teléfono", "Telefono" },
	{ "por teléfono", "Telefono" },
	{ "mensaje", "Mensaje" },
	{ "por el comunicador", "Altavoz" },
	{ "por el altavoz", "Altavoz" },
	{ "por los altavoces", "Altavoz" },
	{ "en todas las pantallas", "Pantalla" },
	{ "en la cinta", "Cinta" },
}
StageDirector.RemoteIcons = { Telefono = "📱", Mensaje = "💬", Altavoz = "🔊", Pantalla = "📺", Cinta = "📼" }
local WHISPER = { "susurr", "bajito", "en voz baja", "flojito", "muy bajo" }
local FAR = { "desde lejos", "desde el fondo", "desde la puerta", "desde la grada", "desde el público", "desde atrás", "desde el mostrador", "desde la cocina", "por detrás", "desde detrás" }
local GAZE = {
	{ "sin mirarte", "Away" },
	{ "no te mira", "Away" },
	{ "sin levantar la vista", "Down" },
	{ "se pone rojo", "Down" },
	{ "se pone roja", "Down" },
	{ "sonrojad", "Down" },
	{ "a tu lado", "To" },
}
-- Gesto (Emotion) por palabras de la acotación
local GESTURES = {
	{ "llorando", "Sad" },
	{ "lagrimilla", "Sad" },
	{ "se ríe", "Laugh" },
	{ "riéndose", "Laugh" },
	{ "de la risa", "Laugh" },
	{ "aplaude", "Clap" },
	{ "guiña", "Happy" },
	{ "sonríe", "Happy" },
	{ "levanta el pulgar", "Nod" },
	{ "asiente", "Nod" },
	{ "se frota la cara", "Facepalm" },
	{ "sorprendid", "Surprised" },
	{ "entra corriendo", "Surprised" },
	{ "ofendid", "ArmsCrossed" },
	{ "pensativ", "ThinkChin" },
	{ "aprieta tu mano", "Sad" },
	{ "muy fuerte", "Cheer" },
	{ "saluda", "Wave" },
	{ "señala", "Point" },
}

-- Quita la acotación del principio de un texto. Devuelve (texto limpio, acotación?).
-- acotación = { Raw, Whole (la línea entera era la acotación), Remote?, Whisper?, Far?, Look?, Gesture? }
-- Solo se mira un paréntesis AL PRINCIPIO (lo de en medio es parte de la frase).
function StageDirector.direction(text: string?): (string, { [string]: any }?)
	if type(text) ~= "string" then
		return "", nil
	end
	local lead, inner, rest = text:match("^(%s*)%(([^()]*)%)%s*(.*)$")
	if not inner or lead == nil then
		return text, nil
	end
	local d: { [string]: any } = { Raw = inner }
	local s = lower(inner)
	for _, rule in REMOTE do
		if s:find(rule[1], 1, true) then
			d.Remote = rule[2]
			break
		end
	end
	for _, word in WHISPER do
		if s:find(word, 1, true) then
			d.Whisper = true
			break
		end
	end
	for _, word in FAR do
		if s:find(word, 1, true) then
			d.Far = true
			break
		end
	end
	for _, rule in GAZE do
		if s:find(rule[1], 1, true) then
			d.Look = rule[2]
			break
		end
	end
	for _, rule in GESTURES do
		if s:find(rule[1], 1, true) then
			d.Gesture = rule[2]
			break
		end
	end
	if rest == "" then
		-- La línea entera es una acotación: se queda como subtítulo (sin paréntesis) y el actor la hace
		d.Whole = true
		local caption = inner:gsub("^%s+", ""):gsub("%s+$", "")
		return caption, d
	end
	-- «(Rubén, bajito:) Buena suerte» → los dos puntos sobran
	return rest, d
end

---------------------------------------------------------------------
-- Token de género: «encargad{o/a}», «{él/ella}», «{bienvenido/bienvenida}»
---------------------------------------------------------------------

-- Género del jugador (atributo Gender: "M"/"F"; también "Chico"/"Chica", "male"/"female"). nil = no se sabe.
function StageDirector.gender(value: any): string?
	if type(value) ~= "string" then
		return nil
	end
	local v = lower(value)
	if v == "m" or v == "masculino" or v == "chico" or v == "male" or v == "hombre" or v == "o" then
		return "M"
	elseif v == "f" or v == "femenino" or v == "chica" or v == "female" or v == "mujer" or v == "a" then
		return "F"
	end
	return nil
end

-- Sustituye cada {masc/fem}. Sin género conocido: la forma corta con barra («encargado/a», «él/ella»).
function StageDirector.genderize(text: string, gender: string?): string
	if not text:find("{", 1, true) then
		return text
	end
	local result = text:gsub("{([^{}/]*)/([^{}/]*)}", function(masc: string, fem: string)
		if gender == "M" then
			return masc
		elseif gender == "F" then
			return fem
		end
		-- Sin saber: «encargad{o/a}» → «encargado/a»; «{él/ella}» → «él/ella»
		return masc .. "/" .. fem
	end)
	return result
end

---------------------------------------------------------------------
-- Planos
---------------------------------------------------------------------

-- Presets de plano (los mismos nombres que CameraShots.preset) y cuántos personajes piden
StageDirector.Shots = {
	General = { Min = 0, Max = 0 },
	Medio = { Min = 1, Max = 1 },
	PrimerPlano = { Min = 1, Max = 1 },
	PPP = { Min = 1, Max = 1 },
	Hombro = { Min = 2, Max = 2, Sep = ">" },
	DosPlanos = { Min = 2, Max = 2, Sep = "," },
	Lateral = { Min = 1, Max = 1 },
	Reaccion = { Min = 1, Max = 1 },
	Seguir = { Min = 1, Max = 1 },
	Inserto = { Min = 1, Max = 1, Object = true },
}

-- "Hombro:Yo>Nico" → { Kind = "Hombro", Who = { "Yo", "Nico" } }; nil + motivo si está mal escrito
function StageDirector.parseShot(spec: any): ({ Kind: string, Who: { string } }?, string?)
	if type(spec) ~= "string" or spec == "" then
		return nil, "el plano tiene que ser un texto"
	end
	local kind, args = spec:match("^(%a+):(.+)$")
	if not kind then
		kind, args = spec, nil
	end
	local def = StageDirector.Shots[kind]
	if not def then
		return nil, ("plano desconocido '%s'"):format(tostring(kind))
	end
	local who = {}
	if args then
		local sep = def.Sep or ","
		local start = 1
		while start <= #args + 1 do
			local stop = args:find(sep, start, true)
			local part = args:sub(start, (stop or #args + 1) - 1)
			local name = part:gsub("^%s+", ""):gsub("%s+$", "")
			if name ~= "" then
				table.insert(who, name)
			end
			if not stop then
				break
			end
			start = stop + 1
		end
	end
	if #who < def.Min or #who > def.Max then
		return nil, ("el plano %s pide %d personaje(s)"):format(kind, def.Min)
	end
	return { Kind = kind, Who = who }, nil
end

-- Estado del director durante una conversación
export type State = {
	Count: number, -- líneas encuadradas
	Last: string?, -- el último personaje (no el jugador) que habló
	Run: number, -- cuántas seguidas lleva el mismo
	Established: boolean,
}

function StageDirector.newState(): State
	return { Count = 0, Last = nil, Run = 0, Established = false }
end

local function isMe(id: any): boolean
	return id == "Yo" or id == "Player"
end

-- ¿Pregunta? (termina en «?», también «?»» o «?)»)
function StageDirector.isQuestion(text: string?): boolean
	if type(text) ~= "string" then
		return false
	end
	local s = text:gsub("%s+$", ""):gsub("[»\"”%)]+$", "")
	return s:sub(-1) == "?"
end

-- El plano de una línea (ya preparada por el servidor: Id, To, Shot, Me, Narrator, Direction).
-- Devuelve el preset ("Hombro:Yo>Nico"…) o nil (sin cámara: el narrador, una voz por teléfono…).
-- Actualiza el estado.
function StageDirector.shotFor(state: State, line: { [string]: any }): string?
	local id = line.Id
	local d = line.Direction or {}
	local explicit = if type(line.Shot) == "string" and StageDirector.parseShot(line.Shot) then line.Shot else nil
	if line.Narrator or (id == nil and not line.Me) then
		return explicit
	end
	if d.Remote then
		return explicit -- (habla por teléfono: no está en la escena)
	end
	state.Count += 1
	local shot: string? = explicit
	if line.Me or isMe(id) then
		if not shot then
			local other = if type(line.To) == "string" and not isMe(line.To) then line.To else state.Last
			shot = if other then ("Hombro:%s>Yo"):format(other) else "Medio:Yo"
		end
		return shot
	end
	if not shot then
		if d.Far then
			shot = "General"
		elseif d.Whisper then
			shot = "PPP:" .. id
		elseif type(line.To) == "string" and not isMe(line.To) and line.To ~= id then
			shot = ("DosPlanos:%s,%s"):format(id, line.To)
		elseif state.Last ~= id then
			shot = "Hombro:Yo>" .. id
		elseif state.Run % 2 == 1 then
			shot = "PrimerPlano:" .. id
		else
			shot = "Hombro:Yo>" .. id
		end
	end
	if state.Last == id then
		state.Run += 1
	else
		state.Last = id
		state.Run = 1
	end
	return shot
end

-- Plano de situación al empezar (una vez por conversación): "General" o nil si ya se hizo
function StageDirector.establish(state: State): string?
	if state.Established then
		return nil
	end
	state.Established = true
	return "General"
end

-- Plano de reacción tras una pregunta: a quien se le pregunta (To, o tú)
function StageDirector.reactionFor(line: { [string]: any }): string?
	if line.Narrator or line.Me or (line.Direction and line.Direction.Remote) then
		return nil
	end
	if not StageDirector.isQuestion(line.Text) then
		return nil
	end
	local to = if type(line.To) == "string" and line.To ~= line.Id then line.To else "Yo"
	return "Reaccion:" .. (if isMe(to) then "Yo" else to)
end

---------------------------------------------------------------------
-- Geometría de los planos (cuando CameraShots.preset no está o no sabe hacerlo)
---------------------------------------------------------------------

local function lookAt(at: Vector3, target: Vector3): CFrame
	local look = target - at
	if look.Magnitude < 1e-6 then
		return CFrame.new(at)
	end
	look = look.Unit
	local right = look:Cross(Vector3.yAxis)
	if right.Magnitude < 1e-6 then
		right = look:Cross(Vector3.zAxis)
	end
	right = right.Unit
	return CFrame.fromMatrix(at, right, right:Cross(look).Unit, -look)
end
StageDirector.lookAt = lookAt

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function key(id: string): string
	return if isMe(id) then "Yo" else id
end

-- Centro de todos (y lo más lejos que está alguien de él)
local function centerOf(positions: { [string]: Vector3 }): (Vector3?, number)
	local sum, n = Vector3.zero, 0
	for _, p in positions do
		sum += p
		n += 1
	end
	if n == 0 then
		return nil, 0
	end
	local center = sum / n
	local radius = 0
	for _, p in positions do
		radius = math.max(radius, flat(p - center).Magnitude)
	end
	return center, radius
end

-- Hacia dónde está "el otro" de X: el que se dice, o tú, o el centro del grupo
local function otherOf(positions: { [string]: Vector3 }, id: string, hint: string?): Vector3?
	if hint and positions[key(hint)] and key(hint) ~= key(id) then
		return positions[key(hint)]
	end
	if key(id) ~= "Yo" and positions.Yo then
		return positions.Yo
	end
	local best, bestDistance = nil, math.huge
	local me = positions[key(id)]
	for name, p in positions do
		if name ~= key(id) and me then
			local d = (p - me).Magnitude
			if d < bestDistance then
				best, bestDistance = p, d
			end
		end
	end
	return best
end

-- El plano en el mundo: (CFrame de la cámara, punto enfocado) o nil si falta alguien.
-- positions = cabeza de cada uno por id ("Yo" = el jugador; objetos por su id para Inserto).
-- opts.From = quién habla (para el plano de reacción: se ve desde su lado)
function StageDirector.frame(spec: string, positions: { [string]: Vector3 }, opts: { [string]: any }?): (CFrame?, Vector3?)
	local parsed = StageDirector.parseShot(spec)
	if not parsed then
		return nil, nil
	end
	local o = opts or {}
	local kind, who = parsed.Kind, parsed.Who
	local up = Vector3.yAxis
	if kind == "General" then
		local center, radius = centerOf(positions)
		if not center then
			return nil, nil
		end
		-- De lado al eje principal (tú → el primero que habla), alejado lo justo para que quepan todos
		local axis = if o.From and positions[key(o.From)] and positions.Yo then flat(positions[key(o.From)] - positions.Yo) else Vector3.new(0, 0, -1)
		if axis.Magnitude < 0.3 then
			axis = Vector3.new(0, 0, -1)
		end
		local side = axis.Unit:Cross(up)
		local distance = math.clamp(radius * 1.7 + 9, 10, 40)
		local at = center + side * distance + up * (2.5 + radius * 0.25) - axis.Unit * (distance * 0.25)
		return lookAt(at, center - up * 0.6), center
	end
	local a = positions[key(who[1])]
	if not a then
		return nil, nil
	end
	if kind == "Hombro" or kind == "DosPlanos" then
		local b = positions[key(who[2])]
		if not b then
			return nil, nil
		end
		local forward = flat(b - a)
		if forward.Magnitude < 0.3 then
			return nil, nil
		end
		local distance = forward.Magnitude
		forward = forward.Unit
		local right = forward:Cross(up)
		if kind == "Hombro" then
			-- Por encima del hombro de A, mirando a B
			return lookAt(a - forward * 4.5 + right * 1.8 + up * 0.9, b - up * 0.2), b
		end
		local middle = (a + b) / 2
		return lookAt(middle + right * (distance * 0.8 + 5) + up * 1.2, middle - up * 0.3), middle
	end
	if kind == "Inserto" then
		-- Un objeto: de cerca y desde arriba, desde tu lado
		local from = positions.Yo or (a + Vector3.new(0, 2, 6))
		local toward = flat(a - from)
		toward = if toward.Magnitude > 0.3 then toward.Unit else Vector3.new(0, 0, -1)
		return lookAt(a - toward * 3.2 + up * 2.2, a), a
	end
	local other = otherOf(positions, who[1], o.From)
	local toOther = if other then flat(other - a) else Vector3.new(0, 0, 1)
	toOther = if toOther.Magnitude > 0.3 then toOther.Unit else Vector3.new(0, 0, 1)
	local right = toOther:Cross(up)
	if kind == "PrimerPlano" or kind == "Reaccion" then
		-- De frente (desde el lado de con quien habla), un poco de lado, sitio arriba para el bocadillo
		return lookAt(a + toOther * 4.6 - right * 1.2 + up * 0.3, a + up * 0.5), a
	elseif kind == "PPP" then
		return lookAt(a + toOther * 2.8 - right * 0.7 + up * 0.15, a + up * 0.1), a
	elseif kind == "Medio" or kind == "Seguir" then
		return lookAt(a + toOther * 7.5 - right * 2 + up * 0.6, a - up * 0.6), a
	elseif kind == "Lateral" then
		return lookAt(a + right * 6 + up * 0.4, a - up * 0.3), a
	end
	return nil, nil
end

-- El plano usando CameraShots.preset (paquete P1) si existe; si no, o si falla, la geometría de aquí.
-- Devuelve (desde, hasta, segundos, foco): un plano puede ser un travelling (dolly) de desde a hasta.
-- cameraShots = el módulo CameraShots (o nil); clock = reloj para la cámara en mano.
function StageDirector.camera(spec: string, positions: { [string]: Vector3 }, cameraShots: any?, opts: { [string]: any }?): (CFrame?, CFrame?, number?, Vector3?)
	if cameraShots and type(cameraShots.preset) == "function" then
		local ok, a, b, c, d = pcall(function()
			-- Las anclas: cada personaje como CFrame en su cabeza (mirando a quien tiene delante)
			local actors: { [string]: CFrame } = {}
			for id, p in positions do
				local other = otherOf(positions, id, nil)
				actors[id] = if other and flat(other - p).Magnitude > 0.3 then lookAt(p, Vector3.new(other.X, p.Y, other.Z)) else CFrame.new(p)
			end
			actors.Player = actors.Yo
			local shot = cameraShots.preset(spec, actors)
			if typeof(shot) == "CFrame" then
				return shot, shot, 0, nil
			end
			if type(shot) ~= "table" then
				return nil
			end
			local function resolve(name: string): CFrame?
				if type(name) ~= "string" then
					return nil
				end
				local id = name:match("^Actor:(.+)$") or name
				if id == "Player" or id == "Yo" then
					return actors.Yo
				end
				return actors[id]
			end
			local from = cameraShots.cframe and cameraShots.cframe(shot, 0, resolve, 0, 0) or cameraShots.base(shot, 0, resolve)
			local to = cameraShots.cframe and cameraShots.cframe(shot, 1, resolve, 0, 0) or cameraShots.base(shot, 1, resolve)
			if not from or not to then
				return nil
			end
			return from, to, if (to.Position - from.Position).Magnitude > 0.05 then (shot.Duration or 0) else 0, nil
		end)
		if ok and a then
			local focus = d
			if not focus then
				local parsed = StageDirector.parseShot(spec)
				local first = parsed and parsed.Who[#parsed.Who]
				focus = (first and positions[key(first)]) or (centerOf(positions))
			end
			return a, b, c, focus
		end
	end
	local cf, focus = StageDirector.frame(spec, positions, opts)
	if not cf then
		return nil, nil, nil, nil
	end
	return cf, cf, 0, focus
end

---------------------------------------------------------------------
-- Reparto y entradas
---------------------------------------------------------------------

-- Quién habla en un diálogo (también dentro de las respuestas), en orden de aparición
function StageDirector.castOf(lines: { any }?): { string }
	local list, seen = {}, {}
	local function walk(list2: { any }?)
		for _, line in list2 or {} do
			if type(line) == "table" then
				local s = line.S
				if type(s) == "string" and s ~= "Yo" and s ~= "Narrador" and not seen[s] then
					seen[s] = true
					table.insert(list, s)
				end
				if type(line.To) == "string" and not isMe(line.To) and line.To ~= "Narrador" and not seen[line.To] then
					seen[line.To] = true
					table.insert(list, line.To)
				end
				for _, option in line.Options or {} do
					walk(option.Then)
				end
			end
		end
	end
	walk(lines)
	return list
end

-- Quién se acerca al empezar: los que están lejos pero en la escena (distances = studs al jugador)
function StageDirector.approach(distances: { [string]: number }): { string }
	local list = {}
	for id, d in distances do
		if d > StageDirector.APPROACH_MIN and d <= StageDirector.APPROACH_MAX then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

-- Dónde se para quien se acerca: a APPROACH_STOP studs del jugador, en la línea que les une
function StageDirector.approachSpot(actor: Vector3, player: Vector3): Vector3
	local offset = flat(actor - player)
	if offset.Magnitude < 0.5 then
		return actor
	end
	local goal = player + offset.Unit * StageDirector.APPROACH_STOP
	return Vector3.new(goal.X, actor.Y, goal.Z)
end

---------------------------------------------------------------------
-- Validación de los campos nuevos (Validate.luau)
---------------------------------------------------------------------

-- Problemas de una línea; known(id) = ¿existe ese personaje en el reparto?
function StageDirector.problems(line: { [string]: any }, known: ((string) -> boolean)?): { string }
	local out = {}
	local function knows(id: string): boolean
		return isMe(id) or (known == nil) or known(id)
	end
	local p = line.Pause
	if p ~= nil then
		if type(p) == "number" then
			if p < 0 or p > StageDirector.MAX_PAUSE then
				table.insert(out, ("Pause fuera de rango (0-%d s)"):format(StageDirector.MAX_PAUSE))
			end
		elseif type(p) == "table" then
			for field, value in p do
				if field ~= "Before" and field ~= "After" then
					table.insert(out, ("Pause con campo desconocido '%s' (Before/After)"):format(tostring(field)))
				elseif type(value) ~= "number" or value < 0 or value > StageDirector.MAX_PAUSE then
					table.insert(out, ("Pause.%s fuera de rango (0-%d s)"):format(field, StageDirector.MAX_PAUSE))
				end
			end
		else
			table.insert(out, "Pause tiene que ser un número o { Before, After }")
		end
	end
	local b = line.Beat
	if b ~= nil then
		if type(b) == "number" then
			if b <= 0 or b > StageDirector.MAX_BEAT then
				table.insert(out, ("Beat fuera de rango (0-%d s)"):format(StageDirector.MAX_BEAT))
			end
		elseif not StageDirector.beat(b) then
			table.insert(out, ("Beat desconocido '%s'"):format(tostring(b)))
		end
	end
	local to = line.To
	if to ~= nil then
		if type(to) ~= "string" or not knows(to) then
			table.insert(out, ("To = '%s' no está en el reparto"):format(tostring(to)))
		elseif to == line.S then
			table.insert(out, "To = quien habla (se habla a sí mismo)")
		end
	end
	local shot = line.Shot
	if shot ~= nil then
		local parsed, why = StageDirector.parseShot(shot)
		if not parsed then
			table.insert(out, ("Shot '%s': %s"):format(tostring(shot), why or "?"))
		elseif not StageDirector.Shots[parsed.Kind].Object then
			for _, id in parsed.Who do
				if not knows(id) then
					table.insert(out, ("Shot '%s': '%s' no está en el reparto"):format(shot, id))
				end
			end
		end
	end
	return out
end

return StageDirector
