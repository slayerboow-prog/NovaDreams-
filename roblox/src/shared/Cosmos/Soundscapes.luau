-- Soundscapes: QUÉ SUENA según la zona de la cámara (cuentas puras; docs/audio/zonas.md).
--
-- La zona la decide UN solo sitio: shared/Cosmos/EnvZones (la misma que pinta el cielo y la luz). Su
-- dueño en el cliente, Controllers/EnvDirector, pasa la zona por aquí y le da el resultado a
-- Controllers/StoryAudio (setZone: ambiente y música, con fundido cruzado) y a los bucles de Valmar
-- (Weather: pájaros, viento, lluvia y trueno; GameSfx: grillos y olas; SoundFx: el murmullo del centro),
-- que se escalan con Scape.Valmar (1 = en Valmar, 0 = fuera). Antes cada uno miraba solo la hora y el
-- tiempo de Valmar, y en el espacio seguían los pajaritos, el viento (¡más fuerte cuanto más alto!), el
-- tráfico de la calle (StoryAudio ponía «Calle» en cualquier sitio sin edificios) y la música de Valmar
-- (la de tu etapa). Informe del dueño en la v123.
--
-- Cada perfil: Ambience = tipo de Config.Audio.Ambience.Kinds (nil = el automático de Valmar: casa,
-- colegio, calle…), Music = lista de piezas de Config.Audio.Music por orden (nil = la de Valmar: la del
-- capítulo o la de tu etapa; más de una = se van turnando), Scale = volumen de la música, Mood = cómo
-- tiene que sonar (para la doc y las pruebas).
--
--   Soundscapes.resolve(env, ctx, prev)   la mezcla que toca ahora (Scape)
--   Soundscapes.latch(until, on, now)     la cola del combate (la música de combate no salta a cada rato)

local Soundscapes = {}

Soundscapes.Fade = 3 -- segundos del fundido cruzado al cambiar de zona (ambiente y música)
Soundscapes.CombatHold = 8 -- la música de combate se queda estos segundos tras el último peligro
Soundscapes.NacaraRadius = 260 -- a esta distancia (en planta) de la plaza de Nácara, bajo el agua, es Nácara

export type Profile = {
	Mood: string,
	Ambience: string?,
	Music: { string }?,
	Scale: number?,
}

export type PlanetProfile = {
	Mood: string,
	Ambience: string?,
	Music: { string }?,
	Scale: number?,
	Modes: { [string]: Profile }?,
}

-- Las zonas de EnvZones (y Nácara, que va dentro del mar de Valmar)
Soundscapes.Profiles = {
	Valmar = { Mood = "la ciudad de siempre: casa, colegio, calle, pájaros, grillos, olas y la música de tu etapa" },
	Transicion = { Mood = "subiendo: el viento de Valmar se va apagando y queda el zumbido de la nave", Ambience = "Transicion" },
	Espacio = { Mood = "espacio profundo: zumbido grave y la cabina, sin pájaros ni viento; música tranquila de crucero", Ambience = "Espacio", Music = { "EspacioCrucero", "EspacioDeriva" } },
	EspacioCerca = { Mood = "cerca de una estación: además, la radio lejana", Ambience = "EspacioCerca", Music = { "EspacioCrucero", "EspacioDeriva" } },
	EspacioEstacion = { Mood = "atracado en una estación: vestíbulo, radio y música cálida", Ambience = "EspacioEstacion", Music = { "EspacioEstacion" } },
	Combate = { Mood = "combate en el espacio (piratas, patrullas, la Rueca de Varkun): pulso tenso", Ambience = "Espacio", Music = { "EspacioCombate" } },
	Arena = { Mood = "arena de pruebas del combate aéreo: cabina, aire y pulso de combate", Ambience = "Arena", Music = { "EspacioCombate" }, Scale = 0.8 },
	Submarino = { Mood = "bajo el mar: rumor apagado, burbujas, ballenas lejos; música etérea muy bajita", Ambience = "Submarino", Music = { "Nacara" }, Scale = 0.5 },
	Nacara = { Mood = "Nácara: el mar apagado alrededor de la cúpula y música etérea", Ambience = "Nacara", Music = { "Nacara" } },
} :: { [string]: Profile }

-- Los planetas (superficie o entrando). Tefra tiene sus momentos; los demás (aún «próximamente») ya
-- tienen su perfil, para que suenen a algo suyo en cuanto abran (nunca a Valmar).
Soundscapes.Planets = {
	Tefra = {
		Mood = "Bastión Ceniza: rumor de lava, viento de ceniza, fundiciones lejos; tambores de guerra apagados",
		Ambience = "Tefra",
		Music = { "TefraGuerra" },
		Scale = 0.8,
		Modes = {
			Bombardeo = { Mood = "bombardeo de Ovilla: las sirenas y los tambores a tope", Ambience = "TefraBombardeo", Music = { "TefraGuerra" }, Scale = 1 },
			Refugio = { Mood = "dentro de un refugio: el bombardeo apagado fuera, música en calma", Ambience = "TefraRefugio", Music = { "TefraRefugio" } },
			Tregua = { Mood = "tras el alto el fuego: la ciudad respira, música en calma", Ambience = "Tefra", Music = { "TefraRefugio" } },
		},
	},
	Siroco = { Mood = "desierto de sal caliente (Puerto Calcina): viento seco y polvo, música cálida y lenta", Ambience = "Siroco", Music = { "TefraRefugio" } },
	Talasa = { Mood = "planeta océano (Abisalia): olas enormes, viento salado y música etérea", Ambience = "Talasa", Music = { "Nacara" } },
	Nivalis = { Mood = "hielo (Fortaleza Albor): viento frío y un silencio enorme; música clara y lenta (la del crucero)", Ambience = "Nivalis", Music = { "EspacioCrucero" } },
	Umbria = { Mood = "selva (Raíz Honda): insectos y aire húmedo; cuerdas lentas y piano (la de deriva)", Ambience = "Umbria", Music = { "EspacioDeriva" } },
	Miasma = { Mood = "gas tóxico (Anclaje Siete): zumbido de filtros y un drone inquietante; música tensa bajita", Ambience = "Miasma", Music = { "Tension" }, Scale = 0.6 },
	Vertice = { Mood = "ciudad dorada de máquinas (Distrito Cero): zumbido eléctrico, radio y música de estación", Ambience = "Vertice", Music = { "EspacioEstacion" } },
} :: { [string]: PlanetProfile }

-- Los bucles de Valmar (para las pruebas: ninguno puede sonar fuera de Valmar)
Soundscapes.ValmarLoops = { "Birds", "Wind", "Rain", "Thunder", "Grillos", "Olas", "Multitud", "AmbCalle", "AmbAire" }

export type Context = {
	Combat: boolean?, -- en combate (ya con su cola: Soundscapes.latch)
	Docked: boolean?, -- atracado en una estación (atributo SpaceStation)
	NearStation: boolean?, -- cerca de una estación (dentro de su zona segura)
	Shelter: boolean?, -- Tefra: dentro de un refugio
	Raid: string?, -- Tefra: el bombardeo (workspace.TefraWar.State: "Aviso" | "Fuego" | "Despues")
	Tregua: boolean?, -- Tefra: ya vivió el alto el fuego (memoria del mundo «Tefra.Tregua»)
	Nacara: boolean?, -- junto a Nácara, bajo el mar (o en su cúpula)
	Mode: string?, -- (otros planetas) su momento: Modes[Mode] del perfil (atributo PlanetaModo del jugador)
}

export type Scape = {
	Key: string, -- "Valmar", "Espacio", "Espacio:Combate", "Tefra:Refugio"…
	Zone: string, -- la zona de EnvZones
	Planet: string?,
	Mode: string?, -- "Combate", "Estacion", "Cerca", "Bombardeo", "Refugio", "Tregua"…
	Ambience: string?, -- tipo de Config.Audio.Ambience.Kinds (nil = el automático de Valmar)
	Music: { string }?, -- piezas de Config.Audio.Music (nil = la de Valmar)
	Scale: number, -- volumen de la música
	Valmar: number, -- 0..1: cuánto suenan los bucles de Valmar (pájaros, viento, grillos, olas, ciudad)
	SpaceMusic: boolean?, -- (histéresis de la transición: ya suena la del espacio)
	PlanetSound: boolean?, -- (histéresis de la entrada: ya suena la del planeta)
	Fade: number,
}

local function over(value: number, wasOn: boolean?, on: number, off: number): boolean
	return if wasOn then value > off else value > on
end

local function make(key: string, zone: string, p: Profile, valmar: number, extra: { [string]: any }?): Scape
	local s: Scape = {
		Key = key,
		Zone = zone,
		Ambience = p.Ambience,
		Music = p.Music,
		Scale = p.Scale or 1,
		Valmar = math.clamp(valmar, 0, 1),
		Fade = Soundscapes.Fade,
	}
	for k, v in extra or {} do
		(s :: any)[k] = v
	end
	return s
end

-- Un planeta (superficie o entrando), con los momentos de Tefra
local function planetScape(id: string, zone: string, ctx: Context): Scape?
	local p = Soundscapes.Planets[id]
	if not p then
		return nil
	end
	local mode: string? = nil
	-- (marco común: el momento que diga el planeta —tormenta, refugio sellado…—, ctx.Mode)
	if id ~= "Tefra" and zone == "Planeta" and ctx.Mode and p.Modes and p.Modes[ctx.Mode] then
		mode = ctx.Mode
	end
	if id == "Tefra" and zone == "Planeta" then
		local raid = ctx.Raid == "Aviso" or ctx.Raid == "Fuego"
		if ctx.Shelter then
			mode = "Refugio"
		elseif raid then
			mode = "Bombardeo"
		elseif ctx.Tregua then
			mode = "Tregua"
		end
	end
	local modes = p.Modes
	local chosen: Profile = if mode and modes and modes[mode] then modes[mode] else (p :: any)
	return make(if mode then id .. ":" .. mode else id, zone, chosen, 0, { Planet = id, Mode = mode, PlanetSound = true })
end

local function spaceScape(zone: string, ctx: Context, valmar: number, extra: { [string]: any }?): Scape
	local P = Soundscapes.Profiles
	if ctx.Combat then
		local s = make("Espacio:Combate", zone, P.Combate, valmar, extra)
		s.Mode = "Combate"
		if zone == "Transicion" then
			s.Ambience = "Transicion"
		end
		return s
	end
	if ctx.Docked then
		local s = make("Espacio:Estacion", zone, P.EspacioEstacion, valmar, extra)
		s.Mode = "Estacion"
		return s
	end
	if ctx.NearStation and zone ~= "Transicion" then
		local s = make("Espacio:Cerca", zone, P.EspacioCerca, valmar, extra)
		s.Mode = "Cerca"
		return s
	end
	local s = make("Espacio", zone, P.Espacio, valmar, extra)
	if zone == "Transicion" then
		s.Ambience = "Transicion"
	end
	return s
end

-- La mezcla que toca. env = la de EnvZones (ya suavizada: EnvDirector), ctx = lo que pasa alrededor,
-- prev = la de la vuelta anterior (para la histéresis: sin saltos en el borde de una zona).
function Soundscapes.resolve(env: { [string]: any }?, ctx: Context?, prev: Scape?): Scape
	local c: Context = ctx or {}
	local P = Soundscapes.Profiles
	if not env then
		return make("Valmar", "Valmar", P.Valmar, 1)
	end
	local zone = env.Zone or "Valmar"
	local space = math.clamp(env.Space or 0, 0, 1)
	if zone == "Arena" then
		local s = make("Arena", zone, P.Arena, 0)
		return s
	end
	-- Un planeta: en su superficie, o entrando con su cielo ya a medias (histéresis)
	local planet = env.Planet
	if planet and (zone == "Planeta" or zone == "Entrada") then
		local mix = env.PlanetMix or 0
		local inPlanet = zone == "Planeta" or over(mix, prev ~= nil and prev.PlanetSound == true and prev.Planet == planet, 0.55, 0.45)
		if inPlanet then
			local s = planetScape(planet, zone, c)
			if s then
				return s
			end
		end
		return spaceScape(zone, c, 0)
	end
	-- Nácara (en su cúpula de aire también: no es «bajo el agua» para la luz, pero suena a Nácara)
	if c.Nacara and (zone == "Valmar" or zone == "Submarino") then
		return make("Nacara", zone, P.Nacara, 0)
	end
	if zone == "Submarino" then
		return make("Submarino", zone, P.Submarino, 0)
	end
	if zone == "Espacio" then
		return spaceScape(zone, c, 0)
	end
	if zone == "Transicion" then
		-- El viento y los pájaros de Valmar se van apagando con la subida; la música de Valmar sigue hasta
		-- media subida y luego cruza a la del espacio (con histéresis)
		local valmar = 1 - space
		local spaceMusic = over(space, prev ~= nil and prev.SpaceMusic == true, 0.55, 0.45) or c.Combat == true
		if spaceMusic then
			return spaceScape(zone, c, valmar, { SpaceMusic = true })
		end
		local s = make("Transicion", zone, P.Transicion, valmar)
		return s
	end
	return make("Valmar", "Valmar", P.Valmar, 1)
end

-- Cola del combate: on = hay peligro ahora; until = hasta cuándo dura la música de combate. Devuelve si
-- sigue el combate y el nuevo «hasta».
function Soundscapes.latch(untilT: number?, on: boolean, now: number): (boolean, number?)
	if on then
		return true, now + Soundscapes.CombatHold
	end
	if untilT and now < untilT then
		return true, untilT
	end
	return false, nil
end

-- ¿Es la misma mezcla? (para no avisar a StoryAudio 10 veces por segundo)
function Soundscapes.same(a: Scape?, b: Scape?): boolean
	if a == nil or b == nil then
		return a == b
	end
	return a.Key == b.Key and a.Ambience == b.Ambience and a.Music == b.Music and math.abs(a.Scale - b.Scale) < 1e-3
end

-- Todos los perfiles, también los momentos de Tefra (para las pruebas y la doc)
function Soundscapes.allProfiles(): { [string]: Profile }
	local out: { [string]: Profile } = {}
	for k, p in Soundscapes.Profiles do
		out[k] = p
	end
	for id, p in Soundscapes.Planets do
		out[id] = p :: any
		for m, q in p.Modes or {} do
			out[id .. ":" .. m] = q
		end
	end
	return out
end

return Soundscapes
