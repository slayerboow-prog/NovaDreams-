-- ReadingTime: cuánto se queda una frase en pantalla para que DÉ TIEMPO A LEERLA.
--
-- Un solo sitio con los números (antes cada pantalla tenía los suyos: 1,8 s, «#texto × 0,055»…, y las
-- frases cortas —«No.», «Tú.»— se iban antes de leerlas en el móvil):
--   segundos = clamp(BASE + letras / CHARS_PER_SECOND, MIN, MAX) + la pausa de la línea
-- Lo usan todas las pantallas que pasan las frases SOLAS:
--   * Sequencer (shared/LifeStory): la duración de cada frase del diálogo de una escena y el estirado
--     de la línea de tiempo cuando las frases con At fijo vienen demasiado juntas
--   * HappeningClient y Cinematics (cliente): el subtítulo de abajo y el bocadillo que lo acompaña
--   * DialogueUI (las conversaciones por turnos) no pasa sola: espera a que toques; solo usa TAP_GUARD
-- Módulo puro (sin servicios de Roblox): se prueba con Lune (scripts/test-scenes.luau).

local ReadingTime = {}

ReadingTime.MIN = 2.5 -- ninguna frase dura menos (aunque sea «No.»)
ReadingTime.BASE = 0.8 -- mirar el subtítulo y empezar a leer
ReadingTime.CHARS_PER_SECOND = 14 -- lectura cómoda de un jugador joven en el móvil
ReadingTime.MAX = 12 -- tope (una frase muy larga no se queda para siempre)
ReadingTime.MAX_PAUSE = 4 -- la pausa de una línea que se suma, como mucho
-- Subtítulos que llegan antes de que se haya leído el anterior (escenas con tiempos fijos): el nuevo
-- espera, como mucho este retraso acumulado (si no, se iría desfasando de las voces y los gestos)
ReadingTime.MAX_LAG = 6
-- Un toque no pasa una frase que lleva menos de esto en pantalla (un doble toque sin querer no se come
-- una frase entera)
ReadingTime.TAP_GUARD = 0.35

-- Letras que se leen: sin etiquetas de texto enriquecido (<b>, <font …>) ni espacios repetidos
function ReadingTime.chars(text: any): number
	if type(text) ~= "string" or text == "" then
		return 0
	end
	local clean = text:gsub("<[^<>]->", ""):gsub("%s+", " ")
	clean = clean:match("^%s*(.-)%s*$") or clean
	return utf8.len(clean) or #clean
end

-- La pausa escrita de una línea (Pause = n | { Before, After }), con tope
function ReadingTime.pauseOf(line: any): number
	if type(line) ~= "table" then
		return 0
	end
	local p = line.Pause
	local seconds = 0
	if type(p) == "number" then
		seconds = p
	elseif type(p) == "table" then
		seconds = (tonumber(p.Before or p[1]) or 0) + (tonumber(p.After or p[2]) or 0)
	end
	return math.clamp(seconds, 0, ReadingTime.MAX_PAUSE)
end

---------------------------------------------------------------------
-- Silencios dentro de una frase: «¡Agáchate! …Bueno. Ya da igual.»
---------------------------------------------------------------------
-- Una frase con «…» DESPUÉS de acabar otra (un punto, una exclamación o una interrogación y luego
-- «…») es un silencio del personaje: primero dice una cosa, se calla y luego sigue. Los subtítulos de
-- las escenas la enseñan a trozos (Controllers/HappeningClient) con BEAT segundos de silencio entre
-- uno y otro, como ya hacía la caja de las conversaciones (DialogueUI se para en «…»). Antes salía todo
-- de golpe y no parecía que nadie hablase así.
ReadingTime.BEAT = 0.9 -- el silencio de cada «…» en mitad de una frase
ReadingTime.MAX_BEATS = 3

-- Los trozos que se van enseñando, ACUMULADOS (el último es la frase entera):
--   «¡Agáchate! …Bueno. Ya da igual.» -> { "¡Agáchate!", "¡Agáchate! …Bueno. Ya da igual." }
-- Una frase sin silencios devuelve { frase }. «Pues… no sé» (sin punto antes) no es un silencio.
function ReadingTime.beats(text: any): { string }
	if type(text) ~= "string" or text == "" then
		return { if type(text) == "string" then text else "" }
	end
	local parts = {}
	local from = 1
	while #parts < ReadingTime.MAX_BEATS do
		-- (fin de frase —. ! ? o una comilla de cierre— y espacios, y entonces «…». Las comillas « » y ” son
		-- de varios bytes: se buscan aparte, no dentro de un conjunto [ ])
		local s, e, cut = nil, nil, nil
		for _, pattern in { "[%.!%?\"]%s+…", "»%s+…", "”%s+…" } do
			local a, b = text:find(pattern, from)
			if a and (not s or a < s) then
				s, e = a, b
				local closer = text:sub(a):match("^([^%s]+)%s") or ""
				cut = a + #closer - 1
			end
		end
		if not s or not cut then
			break
		end
		local head = text:sub(1, cut):gsub("%s+$", "")
		if head ~= "" then
			table.insert(parts, head)
		end
		from = e + 1
	end
	table.insert(parts, text)
	return parts
end

-- Segundos que tiene que quedarse una frase para leerla (más `pause` segundos, si se pasa). Cada
-- silencio de la frase (ReadingTime.beats) suma BEAT: también hay que esperarlo.
function ReadingTime.seconds(text: any, pause: number?): number
	local n = ReadingTime.chars(text)
	local read = math.clamp(ReadingTime.BASE + n / ReadingTime.CHARS_PER_SECOND, ReadingTime.MIN, ReadingTime.MAX)
	local parts = ReadingTime.beats(text)
	local total = read + (#parts - 1) * ReadingTime.BEAT
	if #parts > 1 then
		-- (y que dé tiempo a leer el último trozo después de que salga)
		local times = ReadingTime.beatTimes(parts)
		local tail = math.max(0, n - ReadingTime.chars(parts[#parts - 1]))
		total = math.max(total, times[#times] + ReadingTime.BASE * 0.5 + tail / ReadingTime.CHARS_PER_SECOND + 0.6)
	end
	return total + math.clamp(tonumber(pause) or 0, 0, ReadingTime.MAX_PAUSE)
end

-- Cuándo sale cada trozo de la frase, en segundos desde que aparece el primero: lo que se tarda en leer
-- lo de antes y el silencio
function ReadingTime.beatTimes(parts: { string }): { number }
	local times = { 0 }
	for i = 2, #parts do
		-- (lo de antes ya está escrito: se tarda en leerlo y luego llega el silencio de cada «…»)
		local before = ReadingTime.chars(parts[i - 1])
		table.insert(times, ReadingTime.BASE * 0.5 + before / ReadingTime.CHARS_PER_SECOND + (i - 1) * ReadingTime.BEAT)
	end
	return times
end

-- Lo mismo para una línea { T | Text, Pause? }
function ReadingTime.ofLine(line: any): number
	if type(line) ~= "table" then
		return ReadingTime.MIN
	end
	return ReadingTime.seconds(line.T or line.Text, ReadingTime.pauseOf(line))
end

---------------------------------------------------------------------
-- Subtítulos seguidos: cada frase se queda al menos lo que se tarda en leerla
---------------------------------------------------------------------
export type Hold = { FreeAt: number }

function ReadingTime.newHold(): Hold
	return { FreeAt = -math.huge }
end

-- Una frase llega en `now` y se lee en `seconds`: cuándo sale (si la anterior aún se está leyendo,
-- espera a que acabe: se queda en pantalla «dentro» del plano siguiente) y hasta cuándo se ve.
function ReadingTime.schedule(hold: Hold, now: number, seconds: number): (number, number)
	local showAt = math.max(now, hold.FreeAt)
	if showAt - now > ReadingTime.MAX_LAG then
		showAt = now -- (demasiado retraso: la nueva corta a la anterior)
	end
	local hideAt = showAt + math.max(seconds, ReadingTime.MIN)
	hold.FreeAt = hideAt
	return showAt, hideAt
end

-- El jugador ha pasado de frase (o la escena salta): lo que esperaba sale ya
function ReadingTime.release(hold: Hold)
	hold.FreeAt = -math.huge
end

return ReadingTime
