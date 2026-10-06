-- Emotion: con qué gesto dice cada personaje su frase (para que los diálogos parezcan vivos).
--
-- Una línea de diálogo puede decirlo a mano con A = "…" (de "Actuar"):
--   { S = "Nico", T = "¡Hemos ganado!", A = "Cheer" }
-- Si no lo dice, se adivina por el texto ("jaja" → se ríe, "¡Hola" → saluda, "lo siento" → triste…).
--
-- Gestos con animación de cuerpo entero (se reproducen una vez):
--   Wave (saludar) · Cheer (celebrar) · Laugh (reírse) · Point (señalar) · Dance (bailar)
-- Posturas (el cliente mueve cabeza, hombros y brazos mientras habla):
--   Happy · Sad · Angry · Surprised · Thinking · Ask (pregunta: cabeza ladeada) · Shrug (encogerse de hombros)
--   · Nod (asentir) · No (negar con la cabeza) · Calm (hablar tranquilo, lo normal)
--   · ArmsCrossed (brazos cruzados) · HandsOnHips (brazos en jarra) · Facepalm (mano a la frente)
--   · Clap (aplaudir) · ThinkChin (mano en la barbilla) · WaveLite (saludo corto con la mano)
--   · Nervous (nervios: se toca las manos, mira alrededor) · Ashamed (vergüenza: baja la cabeza y
--     aparta la mirada). Las dos son también emociones que duran (ActorMoods: Nervous, Shame).
--
-- Además de su emoción, una línea puede llevar un gesto encima con G = "…" (una postura o una animación
-- de las de arriba): { S = "Abu", T = "Ay, este niño…", A = "Sad", G = "Facepalm" }. El servidor lo manda
-- como Gesture (DialogueService) y el cliente lo hace mientras dice la frase (ActorLife.speak).

local Emotion = {}

Emotion.Animated = { Wave = true, Cheer = true, Laugh = true, Point = true, Dance = true }
Emotion.Poses = {
	Happy = true,
	Sad = true,
	Angry = true,
	Surprised = true,
	Thinking = true,
	Ask = true,
	Shrug = true,
	Nod = true,
	No = true,
	Calm = true,
	ArmsCrossed = true,
	HandsOnHips = true,
	Facepalm = true,
	Clap = true,
	ThinkChin = true,
	WaveLite = true,
	Nervous = true,
	Ashamed = true,
}

function Emotion.valid(name: any): boolean
	return type(name) == "string" and (Emotion.Animated[name] == true or Emotion.Poses[name] == true)
end

-- Pistas del texto (en minúsculas), por orden: la primera que encaja gana
local RULES: { { any } } = {
	{ "Facepalm", { "^¡otra vez no", "^otra vez no", "^¡qué desastre", "^qué desastre", "^¡qué vergüenza", "^qué vergüenza", "^¡ay, madre", "^ay, madre", "^¡no, por favor", "^¡en qué estaría pensando" } },
	{ "Laugh", { "jaja", "jeje", "jiji", "ja, ja", "qué risa" } },
	{ "WaveLite", { "^¡hey", "^hey,", "^hey!", "^¡ey,", "^¡ey!", "^ey," } },
	{ "Clap", { "aplauso", "^¡muy bien!", "^¡muy bien,", "^¡muy bien hecho", "^¡qué bien lo has hecho", "^¡fenomenal", "^¡perfecto!" } },
	{ "Wave", { "^¡hola", "^hola", "^¡eh!", "^¡eh,", "^¡buenos días", "^buenos días", "^¡buenas", "^buenas", "^¡adiós", "^adiós", "^¡hasta luego", "^hasta luego", "^¡hasta mañana", "^¡nos vemos" } },
	{ "Cheer", { "^¡bien", "^¡sí!", "^¡sí,", "^¡sííí", "^¡toma", "^¡lo hemos", "^¡lo has", "^¡lo conseguimos", "^¡enhorabuena", "^¡felicidades", "^¡genial", "^¡olé", "^¡bravo", "^¡hemos ganado", "^¡ganamos", "^¡gol" } },
	{ "Point", { "^mira", "^¡mira", "^allí", "^¡allí", "^ahí", "^¡ahí", "^por allí", "^es por ahí" } },
	{ "Ashamed", { "me da vergüenza", "me da mucha vergüenza", "qué corte", "culpa mía", "^me he equivocado", "^no debí", "^no tendría que haber" } },
	{ "Nervous", { "^es que…", "^es que...", "^em…", "^em...", "^ehm", "^eh…", "^eh...", "^uf…", "^uf...", "^no sé si es buena idea", "^no sé si esto", "^estoy nervios" } },
	{ "Sad", { "lo siento", "perdón", "perdona", "lo echo de menos", "la echo de menos", "le echo de menos", "me duele", "qué pena", "triste", "llorar", "lloro", "^…" } },
	{ "HandsOnHips", { "^¿se puede saber", "^¿qué horas son estas", "^¿qué haces aquí", "^¿dónde te habías metido", "^¿dónde estabas" } },
	{ "ArmsCrossed", { "^¡ni se te ocurra", "^ni se te ocurra", "^ya te lo dije", "^te lo dije", "^¡te lo dije", "^estoy esperando", "^¿y bien?", "^no pienso" } },
	{ "Angry", { "^¡basta", "^¡ya está bien", "^¡déjame", "^¡fuera", "^¡cállate", "^¡otra vez", "^¡no puede ser" } },
	{ "Surprised", { "^¡¿", "^¿¡", "^¡anda", "^¡hala", "^¡ostras", "^¡madre mía", "^¡no me lo puedo creer", "^¡vaya", "^¿en serio?", "^¡qué sorpresa", "^¿tú?" } },
	{ "No", { "^no, no", "^¡no!", "^no.", "^ni hablar", "^¡ni hablar", "^de eso nada" } },
	{ "Nod", { "^sí.", "^sí,", "^vale", "^claro", "^exacto", "^de acuerdo", "^eso es", "^muy bien", "^bien." } },
	{ "ThinkChin", { "^interesante", "^mmm, interesante", "^veamos", "^déjame que lo piense", "^me pregunto", "^curioso" } },
	{ "Thinking", { "^mmm", "^hmm", "^a ver", "^pues…", "^pues...", "^déjame pensar", "^no sé" } },
	{ "Shrug", { "^bueno, ", "^bah", "^qué más da", "^yo qué sé", "^ni idea" } },
}

-- Quita marcas de texto (<b>…) y deja minúsculas (con acentos: string.lower no toca los bytes UTF-8 de á/é/…)
local function plain(text: string): string
	local s = text:gsub("<[^>]*>", "")
	s = s:gsub("^%s+", "")
	s = s:gsub("^«", "")
	s = s:lower()
	for upper, lower in { ["Á"] = "á", ["É"] = "é", ["Í"] = "í", ["Ó"] = "ó", ["Ú"] = "ú", ["Ñ"] = "ñ" } do
		s = s:gsub(upper, lower)
	end
	return s
end

local function matches(s: string, pattern: string): boolean
	if pattern:sub(1, 1) == "^" then
		local body = pattern:sub(2)
		return s:sub(1, #body) == body
	end
	return s:find(pattern, 1, true) ~= nil
end

-- El gesto de encima de una línea (G = "Clap"…), si existe; nil si no lleva o no es válido
function Emotion.gesture(line: { [string]: any }): string?
	if line.S == nil or line.S == "Narrador" then
		return nil
	end
	return if Emotion.valid(line.G) then line.G else nil
end

-- El gesto de una línea { S, T, A? }. nil para el narrador.
function Emotion.of(line: { [string]: any }, text: string?): string?
	if line.S == nil or line.S == "Narrador" then
		return nil
	end
	if Emotion.valid(line.A) then
		return line.A
	end
	local s = plain(text or line.T or "")
	-- Tartamudea («Y-yo…», «N-no sé…»): nervios
	local first = s:match("^(%a)%-")
	if first and s:sub(3, 3) == first then
		return "Nervous"
	end
	for _, rule in RULES do
		for _, pattern in rule[2] do
			if matches(s, pattern) then
				return rule[1]
			end
		end
	end
	if s:sub(-1) == "?" or s:sub(-2) == "?»" then
		return "Ask"
	end
	local _, bangs = s:gsub("!", "")
	if bangs >= 2 then
		return "Happy"
	end
	return "Calm"
end

return Emotion
