-- CastVoices: la voz de cada personaje (voz sintetizada de Roblox, AudioTextToSpeech).
--
-- Roblox solo tiene DOS voces en español: VoiceId "101" (hombre) y "102" (mujer). Lo que hace que
-- cada personaje suene distinto es el tono (Pitch, en SEMITONOS: de -12 a 12; 0 = la voz tal cual)
-- y la velocidad (Speed: de 0,5 a 2; 1 = normal). Ojo: Pitch NO es un multiplicador (1 = un semitono
-- más agudo, casi nada).
--   niños y niñas      +4 … +9 semitonos, un poco más deprisa
--   adolescentes       +1,5 … +3,5
--   adultos            -1,5 … +2
--   mayores            -2 … -4, más despacio
--   bichos y robots    lo que pida el personaje (muy agudo, muy grave, muy lento…)
--
-- CastVoices.resolve(quién, atributos) da { VoiceId, Pitch, Speed } para:
--   * un id del reparto (Cast.People): su voz de la tabla de abajo (la familia según la casa:
--     FamilyKey NPC.MAMA / NPC.PAPA, AbuKey NPC.ABU_ROSA / NPC.ABU_TOMAS; «Tú» según Gender);
--   * un perfil de Config.Audio.Voices.Speakers ("Narrador", "Profe", "Nino"…);
--   * cualquier otro nombre: una voz de adulto fija para ese nombre (siempre la misma).
-- CastVoices.speakable(texto) limpia lo que no se lee en voz alta (etiquetas, emojis, *acotaciones*)
-- y lo corta a 300 caracteres (el máximo de Roblox).

local Config = require(script.Parent.Parent.Config)

local CastVoices = {}

CastVoices.MALE = "101" -- Spanish male (lista de voces de Roblox, audio/objects)
CastVoices.FEMALE = "102" -- Spanish female
CastVoices.MAX_TEXT = 300

export type Voice = { VoiceId: string, Pitch: number, Speed: number }

-- G: "M" hombre, "F" mujer, "P" según el jugador (Gender), "FK"/"AK" según la casa (familia, abu)
-- P: semitonos; S: velocidad
local PEOPLE: { [string]: { G: string, P: number, S: number } } = {
	-- Familia (la de tu casa)
	Familia = { G = "FK", P = 0, S = 1 }, -- (lo de verdad: FAMILY, abajo)
	Abu = { G = "AK", P = -2.5, S = 0.86 }, -- (lo de verdad: ABU, abajo)
	-- Colegio: adultos
	Lucia = { G = "F", P = 0.5, S = 0.98 }, -- tutora: frases cortas, humor seco
	Ramon = { G = "M", P = -2.5, S = 0.96 }, -- conserje bromista
	Marta = { G = "F", P = 2, S = 1 }, -- profe de música: habla cantando
	Marisa = { G = "F", P = -2, S = 0.82 }, -- bibliotecaria: susurros
	Paula = { G = "F", P = 1, S = 1.05 }, -- monitora de la granja
	Julian = { G = "M", P = -3.5, S = 0.82 }, -- granjero: habla poco
	Andres = { G = "M", P = 0, S = 1.12 }, -- Educación Física: entusiasmo
	-- Colegio: compañeros (niños)
	Nico = { G = "M", P = 5, S = 1.12 },
	Sara = { G = "F", P = 5, S = 1.18 }, -- habla rapidísimo
	Omar = { G = "M", P = 4.5, S = 0.98 }, -- tranquilo
	Mateo = { G = "M", P = 6, S = 0.94 }, -- tímido
	Dani = { G = "M", P = 8, S = 1.05 }, -- 5 años
	Bruno = { G = "M", P = 4, S = 1.04 }, -- fanfarrón
	Ruben = { G = "M", P = 5.5, S = 1.1 },
	Hugo = { G = "M", P = 6.5, S = 0.97 },
	Alex = { G = "F", P = 4, S = 1.08 },
	Vega = { G = "F", P = 6, S = 1 }, -- soñadora
	Iker = { G = "M", P = 5, S = 1.1 }, -- sabelotodo
	-- Instituto
	Javier = { G = "M", P = -1, S = 0.92 },
	Carmen = { G = "F", P = -0.5, S = 0.9 }, -- escucha más que habla
	Leire = { G = "F", P = 5, S = 1.02 },
	Rayo = { G = "M", P = 3.5, S = 1.06 },
	Nerea = { G = "F", P = 3.5, S = 1.05 },
	Veterano = { G = "M", P = 2, S = 1.04 },
	Delegada = { G = "F", P = 2, S = 1.02 },
	Dario = { G = "M", P = 4, S = 1.1 },
	-- Trabajos y ciudad
	Paco = { G = "M", P = -2, S = 0.95 }, -- gruñón
	Ernesto = { G = "M", P = -1.5, S = 1 },
	Nuria = { G = "F", P = 0, S = 1.1 }, -- rápida, cálida
	Tomas = { G = "M", P = -2.5, S = 0.92 }, -- Tobías, el mecánico
	Ines = { G = "F", P = -1, S = 1 },
	Marcos = { G = "M", P = 0.5, S = 1.08 },
	Lola = { G = "F", P = -1, S = 1.1 }, -- grita en la cocina
	Sofia = { G = "F", P = 1.5, S = 1.05 },
	Irene = { G = "F", P = 0.5, S = 1.08 },
	Toni = { G = "M", P = 0, S = 1.04 },
	-- Universidad y prácticas
	Beltran = { G = "F", P = -2, S = 0.9 }, -- profesora veterana
	Luca = { G = "M", P = 1, S = 1.05 },
	Julia = { G = "F", P = 1, S = 1.1 },
	Pablo = { G = "M", P = -0.5, S = 1 },
	Adrian = { G = "M", P = 0, S = 1.02 },
	Carla = { G = "F", P = 0, S = 1 },
	Montse = { G = "F", P = -1, S = 0.95 },
	Ignacio = { G = "M", P = -1, S = 0.96 },
	Vecino = { G = "M", P = -2.5, S = 1 },
	Paciente = { G = "M", P = -2.5, S = 0.88 },
	Rocio = { G = "F", P = 0.5, S = 1.1 }, -- siempre con prisa
	Alba = { G = "F", P = 6, S = 1.08 }, -- 9 años
	Alumno1 = { G = "M", P = 6, S = 1.06 },
	Alumno2 = { G = "F", P = 5, S = 1.06 },
	Alumno3 = { G = "M", P = 5, S = 1.03 },
	Alumno4 = { G = "F", P = 6, S = 1.09 },
	Mayor1 = { G = "M", P = 3, S = 1.04 },
	Mayor2 = { G = "F", P = 3, S = 1.03 },
	Madre = { G = "F", P = 0.5, S = 0.97 },
	Padre = { G = "M", P = -1, S = 1 },
	-- Misiones locas
	Cosme = { G = "M", P = -2, S = 1.18 }, -- inventor mayor que habla deprisa
	Pip = { G = "M", P = 3, S = 0.88 }, -- robot mayordomo, dramático
	Ivan = { G = "M", P = 0.5, S = 1.1 },
	Candela = { G = "F", P = 1, S = 1.08 },
	Portero = { G = "F", P = -3, S = 0.88 }, -- Doña Pilar
	DonPinzas = { G = "M", P = -5, S = 0.9 }, -- cangrejo abogado
	Tito = { G = "M", P = 0, S = 0.98 },
	Cosimo = { G = "M", P = -4, S = 0.92 }, -- el villano
	DonEscamas = { G = "M", P = 3, S = 1.25 }, -- habla demasiado
	AgenteGris1 = { G = "M", P = -1, S = 1.01 },
	AgenteGris2 = { G = "F", P = 0, S = 1.05 },
	Funcionaria = { G = "F", P = -1.5, S = 0.85 },
	CalcetinMonstruo = { G = "M", P = -6, S = 0.9 },
	Hilacha1 = { G = "F", P = 9, S = 1.25 },
	Hilacha2 = { G = "F", P = 6.5, S = 1.12 },
	RobotSeguridad = { G = "M", P = -3, S = 0.75 }, -- educado, lento
	DronCosimo1 = { G = "M", P = 9, S = 1.2 },
	DronCosimo2 = { G = "M", P = 10, S = 1.25 },
	DronCosimo3 = { G = "M", P = 6, S = 1.1 },
	GatoPolicia1 = { G = "M", P = 2, S = 0.95 },
	GatoPolicia2 = { G = "F", P = 1, S = 0.9 },
	Bigotes = { G = "M", P = -2, S = 0.8 }, -- emperador gato, solemne
	PalomaRobot1 = { G = "F", P = 8, S = 1.15 },
	PalomaRobot2 = { G = "F", P = 9, S = 1 },
	PalomaRobot3 = { G = "F", P = 5, S = 1.04 },
	Cucaracha1 = { G = "M", P = 5, S = 1.15 },
	Cucaracha2 = { G = "M", P = 7, S = 1.1 },
	Cucaracha3 = { G = "M", P = -1, S = 1.03 }, -- Sargento Patitas
	PolloGigante = { G = "F", P = 7, S = 1.16 },
	Clon1 = { G = "P", P = 5, S = 1.1 },
	Clon2 = { G = "P", P = 6, S = 1 },
	Clon3 = { G = "P", P = 4, S = 1.08 },
	RatonPerez = { G = "M", P = 4, S = 1.05 },
	RataLadrona = { G = "F", P = 5, S = 1.25 }, -- muy rápida
	TuFuturo = { G = "P", P = -1, S = 0.95 },
	TuMalvado = { G = "P", P = -3, S = 0.9 },
	Lapiz1 = { G = "M", P = 1, S = 1 },
	Lapiz2 = { G = "M", P = 2, S = 1.08 },
	Lapiz3 = { G = "F", P = -1, S = 0.9 },
	DJZumbido = { G = "M", P = 2, S = 1.15 },
	Fan1 = { G = "M", P = 2.5, S = 1 },
	Fan2 = { G = "F", P = 3, S = 1 },
	Fan3 = { G = "M", P = 1.5, S = 0.95 },
	Zoltan = { G = "M", P = -5, S = 0.82 }, -- máquina de los deseos
	Seguidor1 = { G = "M", P = 2.5, S = 1.08 },
	Seguidor2 = { G = "F", P = 2.5, S = 1.1 },
	Seguidor3 = { G = "M", P = -2, S = 0.98 },
	Zarg = { G = "M", P = -1, S = 1.1 },
	Blorp = { G = "M", P = 7, S = 1.15 },
	CapitanNoz = { G = "F", P = -2, S = 1 },
	Fermin = { G = "M", P = -2, S = 0.92 },
	Rex = { G = "M", P = -3, S = 1 },
	Evaluador = { G = "F", P = -4, S = 0.8 }, -- ser cósmico
	CazadorTiempo = { G = "M", P = -1.5, S = 0.95 },
	Impostor1 = { G = "M", P = 1, S = 0.9 },
	Impostor2 = { G = "F", P = 1.5, S = 0.87 },
	Cafetera1 = { G = "M", P = -2, S = 1.05 },
	Cafetera2 = { G = "F", P = 6, S = 1.3 }, -- muy nerviosa
	Cafetera3 = { G = "M", P = -3.5, S = 0.9 },
	Glub = { G = "M", P = -2, S = 0.97 },
	Plof = { G = "M", P = 4, S = 1.12 },
	Batidora = { G = "F", P = 5.5, S = 1.28 },
	Aspiradora = { G = "F", P = -1, S = 1.02 },
	Microondas = { G = "M", P = -3, S = 0.94 },
	Gnomo1 = { G = "M", P = -1, S = 1.06 },
	Gnomo2 = { G = "F", P = 3, S = 1.1 },
	Gnomo3 = { G = "M", P = -4, S = 0.85 },
	-- Tefra · Bastión Ceniza (Saga 2, episodio 1)
	DaliaRenn = { G = "F", P = -0.7, S = 1.04 }, -- seca, cansada
	GeneralCorvo = { G = "M", P = -3.2, S = 0.9 }, -- nunca levanta la voz
	TobiRenn = { G = "M", P = 0.3, S = 1.07 },
	DoctoraFermina = { G = "F", P = 0.8, S = 0.97 },
	MadreHollin = { G = "F", P = -3.3, S = 0.83 },
	Brasa = { G = "F", P = 6.8, S = 1.16 }, -- 12 años, deslenguada
	IngenieroOrsi = { G = "M", P = 1.2, S = 1.09 }, -- nervioso
	GaloPadre = { G = "M", P = -1.3, S = 0.99 },
	SargentoMurria = { G = "M", P = -2.2, S = 0.93 },
	ErnestoPanadero = { G = "M", P = -3.7, S = 0.81 },
	EscribanoLumo = { G = "M", P = -2.8, S = 0.84 },
	CapitanaFerra = { G = "F", P = -1.2, S = 1.01 },
	PoliciaMilitar1 = { G = "M", P = -0.4, S = 1.03 },
	PoliciaMilitar2 = { G = "M", P = 0.95, S = 1.06 },
	PoliciaMilitar3 = { G = "F", P = -0.3, S = 1.07 },
	SoldadoOvilla = { G = "M", P = 1.6, S = 1.04 },
	RefugiadoMayor = { G = "M", P = -3.4, S = 0.86 },
	Capataz = { G = "M", P = -1.8, S = 1.08 },
	NinaVentana = { G = "F", P = 7.4, S = 1.2 },
	-- El espacio (Saga 2): la voz del chip de Cosme y el Deshilador (faltaban: test-voices)
	NILDA = { G = "F", P = 1.7, S = 0.96 },
	Varkun = { G = "M", P = -4.6, S = 0.78 },
	-- Miasma · Anclaje Siete (Saga 2)
	MaraSolis = { G = "F", P = -1.1, S = 1.06 }, -- rápida, seca, de contrabandista
	ComandanteAndres = { G = "M", P = -2.4, S = 0.94 },
	LeoSolis = { G = "M", P = 2.6, S = 1.12 }, -- 15 años, impaciente
	AbuelaNiebla = { G = "F", P = -3.6, S = 0.8 },
	MaestroOlmo = { G = "M", P = -1.6, S = 0.9 }, -- untuoso, despacio
	BrumaTaller = { G = "F", P = -3, S = 0.9 },
	SenoraGarua = { G = "F", P = -2.6, S = 0.88 },
	RacionadoraPia = { G = "F", P = 0.6, S = 1.08 },
	SoldadoDominio1 = { G = "M", P = -1.3, S = 1.03 },
	SoldadoDominio2 = { G = "F", P = 0.2, S = 1.02 },
	-- Siroco · Puerto Calcina (Saga 2)
	RafaQuiroga = { G = "M", P = -1.9, S = 1.02 }, -- ronco, fanfarrón
	NinaQuiroga = { G = "F", P = 3.1, S = 1.14 }, -- 17 años, rápida
	LuzPozo = { G = "F", P = -0.9, S = 0.96 },
	TavoAguador = { G = "M", P = 0.4, S = 1.08 }, -- sonrisa en la voz
	CobradorHierro1 = { G = "M", P = -2.8, S = 0.92 },
	CobradorHierro2 = { G = "F", P = -0.6, S = 1.05 },
	MarisaDuna = { G = "F", P = -3.4, S = 0.82 },
	AbueloTornillo = { G = "M", P = -4, S = 0.8 },
	TiaCifra = { G = "F", P = 1.4, S = 1.1 },
	-- Nivalis · Fortaleza Albor (Saga 2): aquí se habla en susurros
	Tila = { G = "F", P = 3.6, S = 1.09 }, -- 16 años, lista y rápida
	MadreCopo = { G = "F", P = -3.9, S = 0.79 },
	BrisaSopa = { G = "F", P = -0.3, S = 0.99 },
	VecinoCarambano = { G = "M", P = 0.7, S = 1.12 }, -- nervioso
	GuardiaRegente1 = { G = "M", P = -3.1, S = 0.95 },
	GuardiaRegente2 = { G = "F", P = -1.5, S = 0.98 },
	PrincesaIlse = { G = "F", P = 0.9, S = 0.93 }, -- tranquila, firme
	-- Gente de las escenas que no está en el reparto
	Chispa = { G = "F", P = 9, S = 1.2 }, -- la criatura de la estrella
}
CastVoices.People = PEOPLE

-- La familia de tu casa (Family.Pairs): Mamá o Papá, Abu Rosa o Abu Tomás
local FAMILY = {
	["NPC.MAMA"] = { G = "F", P = 0.5, S = 1.06 }, -- cariño con prisas
	["NPC.PAPA"] = { G = "M", P = -0.5, S = 1.02 },
	["NPC.ABU_ROSA"] = { G = "F", P = -2.5, S = 0.86 },
	["NPC.ABU_TOMAS"] = { G = "M", P = -3, S = 0.84 },
}
CastVoices.Family = FAMILY

local function speakers(): { [string]: any }
	return (Config.Audio and Config.Audio.Voices and Config.Audio.Voices.Speakers) or {}
end

local function clampVoice(voiceId: string, pitch: number, speed: number): Voice
	return { VoiceId = voiceId, Pitch = math.clamp(pitch, -12, 12), Speed = math.clamp(speed, 0.5, 2) }
end

local function genderOf(value: any): string?
	if type(value) ~= "string" then
		return nil
	end
	local v = string.lower(value)
	if v == "m" or v == "male" or v == "masculino" or v == "chico" or v == "hombre" then
		return "M"
	elseif v == "f" or v == "female" or v == "femenino" or v == "chica" or v == "mujer" then
		return "F"
	end
	return nil
end

-- Un número fijo para un nombre (la voz de quien no está en la tabla es siempre la misma)
local function hash(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 2147483647
	end
	return h
end

-- Voz de quien no está en la tabla: hombre o mujer y un tono de adulto, fijos para ese nombre
function CastVoices.generic(name: string): Voice
	local h = hash(name)
	local voiceId = if h % 2 == 0 then CastVoices.MALE else CastVoices.FEMALE
	local pitch = ((h // 2) % 7 - 3) * 0.5 -- -1,5 … +1,5
	local speed = 0.94 + ((h // 14) % 5) * 0.03 -- 0,94 … 1,06
	return clampVoice(voiceId, pitch, speed)
end

-- Los compañeros de clase crecen contigo (SceneService: niños en el colegio, adolescentes en el
-- instituto, adultos después): su voz se hace más grave con tu etapa (LifeStage)
local GROWS = {
	Nico = true, Sara = true, Omar = true, Mateo = true, Dani = true, Bruno = true, Ruben = true,
	Hugo = true, Alex = true, Vega = true, Iker = true, Leire = true, Rayo = true, Nerea = true,
	Dario = true, Alba = true, Alumno1 = true, Alumno2 = true, Alumno3 = true, Alumno4 = true,
}
CastVoices.Grows = GROWS
local GROW_DROP = { Adolescente = 2.5, AdultoJoven = 4.5, Adulto = 5, Mayor = 6.5 }

local function fromEntry(entry: { G: string, P: number, S: number }, attrs: { [string]: any }?, id: string?): Voice
	local g = entry.G
	if g == "P" then
		g = genderOf(attrs and (attrs.Gender or attrs.genero)) or "M"
	end
	local pitch = entry.P
	if id and GROWS[id] and attrs then
		local drop = GROW_DROP[attrs.LifeStage or ""]
		if drop then
			pitch -= drop
			if attrs.LifeStage ~= "Adolescente" then
				pitch = math.min(pitch, 2) -- (de mayores, voz de adulto)
			end
		end
	end
	return clampVoice(if g == "F" then CastVoices.FEMALE else CastVoices.MALE, pitch, entry.S)
end

-- La voz de quien habla. who: id del reparto, perfil de Speakers o un nombre cualquiera.
-- attrs: FamilyKey, AbuKey, Gender y LifeStage del jugador (la familia, «tú» y los compañeros que crecen).
function CastVoices.resolve(who: string?, attrs: { [string]: any }?): Voice
	local profiles = speakers()
	if type(who) ~= "string" or who == "" then
		who = "Narrador"
	end
	local id = who :: string
	if id == "Familia" or id == "Abu" then
		local key = attrs and attrs[if id == "Familia" then "FamilyKey" else "AbuKey"]
		local entry = FAMILY[key or ""] or FAMILY[if id == "Familia" then "NPC.PAPA" else "NPC.ABU_ROSA"]
		return fromEntry(entry, attrs)
	end
	local entry = PEOPLE[id]
	if entry then
		return fromEntry(entry, attrs, id)
	end
	local profile = profiles[id]
	if type(profile) == "table" then
		local voiceId = if type(profile.VoiceId) == "string" and profile.VoiceId ~= "" then profile.VoiceId else CastVoices.FEMALE
		return clampVoice(voiceId, tonumber(profile.Pitch) or 0, tonumber(profile.Speed) or 1)
	end
	return CastVoices.generic(id)
end

-- ¿Este perfil o personaje tiene voz conocida? (para las pruebas)
function CastVoices.known(who: string): boolean
	return PEOPLE[who] ~= nil or who == "Familia" or who == "Abu" or speakers()[who] ~= nil
end

-- Clave de una voz (para reutilizar el audio ya generado)
function CastVoices.key(text: string, voice: Voice): string
	return ("%s|%.2f|%.2f|%s"):format(voice.VoiceId, voice.Pitch, voice.Speed, text)
end

-- Lo que se lee en voz alta: sin etiquetas de texto enriquecido, sin *acotaciones*, sin la acotación
-- del principio entre paréntesis, sin emojis; como mucho 300 caracteres (se corta en una frase o en un
-- espacio). nil si no queda nada que decir.
function CastVoices.speakable(text: any): string?
	if type(text) ~= "string" then
		return nil
	end
	local s = text
	s = string.gsub(s, "<[^<>]->", "") -- <i>, <b>, <font …>
	s = string.gsub(s, "%*[^%*]*%*", " ") -- *hace una reverencia*
	s = string.gsub(s, "^%s*%b()%s*", "") -- (susurrando) …
	s = string.gsub(s, "%s*%b()", "") -- … (Vuelves a la cima.): una acotación en medio o al final tampoco se lee
	s = string.gsub(s, "^%s*%u[%u ]*%u:%s*", "") -- TODOS: «¡…!» (el coro lo dice el narrador: no lee «todos»)
	s = string.gsub(s, "&lt;", "<")
	s = string.gsub(s, "&gt;", ">")
	s = string.gsub(s, "&amp;", "&")
	-- Emojis y símbolos (los caracteres de 4 bytes y los de los bloques de símbolos, flechas y dingbats)
	local ok, cleaned = pcall(function()
		local out = {}
		for _, code in utf8.codes(s) do
			local symbol = code >= 0x1F000 or (code >= 0x2190 and code <= 0x2BFF) or code == 0xFE0F or code == 0x200D
			if not symbol then
				table.insert(out, utf8.char(code))
			end
		end
		return table.concat(out)
	end)
	if ok then
		s = cleaned
	end
	s = string.gsub(s, "%s+", " ")
	s = string.gsub(s, "^ ", "")
	s = string.gsub(s, " $", "")
	if not string.find(s, "%w") then
		return nil
	end
	if #s > CastVoices.MAX_TEXT then
		local cut = string.sub(s, 1, CastVoices.MAX_TEXT)
		-- (que no se quede a medias una letra con tilde: se vuelve atrás hasta un carácter completo)
		while #cut > 0 and not utf8.len(cut) do
			cut = string.sub(cut, 1, #cut - 1)
		end
		local lastStop = 0
		for i = #cut, 1, -1 do
			local c = string.sub(cut, i, i)
			if c == "." or c == "!" or c == "?" then
				lastStop = i
				break
			end
		end
		if lastStop > CastVoices.MAX_TEXT * 0.5 then
			cut = string.sub(cut, 1, lastStop)
		else
			local space = string.find(cut, " [^ ]*$")
			if space and space > CastVoices.MAX_TEXT * 0.5 then
				cut = string.sub(cut, 1, space - 1)
			end
		end
		s = cut
	end
	return s
end

return CastVoices
