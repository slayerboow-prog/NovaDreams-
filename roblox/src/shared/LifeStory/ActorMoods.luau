-- ActorMoods: las EMOCIONES que duran (no solo mientras dicen una frase) de los actores de la historia
-- y de las criaturas. Datos puros: los usan el servidor (velocidad al andar, gesto al empezar) y el
-- cliente (postura: Controllers/ActorLife lee el atributo «Mood» del modelo).
--
--   Mood = {
--     Pose    postura de ActorLife que se queda puesta (Scared y Hurt son propias de las emociones)
--     Speed   multiplica la velocidad al andar (con miedo se corre; herido se arrastra)
--     Gesture animación al empezar a sentirla (una vez), si la hay (Emotion.Animated)
--     Tremble temblor del cuerpo (0..1): miedo, frío, estar herido
--     Bounce  saltitos (0..1): alegría
--     Pitch   tono de la voz (sonidos de criatura y bocadillos)
--     Face    textura de cara (Decal "face" de la cabeza) si se quiere cambiar; nil = la que tenga.
--             No hay caras en el proyecto: se deja preparado (ids rbxasset:// o rbxassetid://).
--     Cómo ACTÚA (natural y sin exagerar; lo lee ActorLife, también al escuchar):
--     Tempo   ritmo de los gestos y de la cabeza al hablar (1 = normal; alegría rápida, tristeza lenta)
--     Head    cabeza arriba (+) o abajo (-), en radianes, siempre poco
--     Open    postura abierta (+: hombros atrás, brazos sueltos) o cerrada (-: encogido, brazos pegados)
--     Gaze    cómo mira: nil (a quien habla) · "Down" (al suelo) · "Avoid" (aparta la vista) ·
--             "Around" (mira alrededor, inquieto) · "Hold" (sostiene la mirada)
--     Fidget  manos inquietas y cambiar el peso de pierna (0..1): nervios
--     Recoil  (studs) al empezar a sentirla da un paso atrás y se para: sorpresa
--   }
--
-- La tabla del encargo (cinematicas-encargo.md, «Animación por emoción»):
--   Alegría   Joy      sonrisa, postura abierta, movimientos rápidos
--   Tristeza  Sad      cabeza baja, movimientos lentos, postura cerrada
--   Enfado    Angry    movimientos bruscos, postura rígida, gestos fuertes
--   Sorpresa  Surprise retrocede y se para
--   Nervios   Nervous  mira alrededor, se toca las manos, cambia el peso de pierna
--   Vergüenza Shame    evita la mirada, baja la cabeza
-- Nombres en inglés (como Emotion) y alias en español para escribir las escenas cómodamente.

local ActorMoods = {}

export type Mood = {
	Pose: string?,
	Speed: number,
	Gesture: string?,
	Tremble: number,
	Bounce: number,
	Pitch: number,
	Face: string?,
	Label: string,
	Tempo: number?,
	Head: number?,
	Open: number?,
	Gaze: string?,
	Fidget: number?,
	Recoil: number?,
}

export type Acting = { Tempo: number, Head: number, Open: number, Gaze: string?, Fidget: number, Recoil: number }

ActorMoods.List = {
	Calm = { Pose = nil, Speed = 1, Tremble = 0, Bounce = 0, Pitch = 1, Label = "Tranquilo" },
	Fear = { Pose = "Scared", Speed = 1.35, Tremble = 0.7, Bounce = 0, Pitch = 1.15, Label = "Miedo", Tempo = 1.15, Head = -0.05, Open = -0.6, Gaze = "Around" },
	Angry = { Pose = "Angry", Speed = 1.1, Gesture = nil, Tremble = 0.15, Bounce = 0, Pitch = 0.9, Label = "Enfado", Tempo = 1.3, Head = -0.04, Open = 0.2, Gaze = "Hold" },
	Surprise = { Pose = "Surprised", Speed = 1, Tremble = 0, Bounce = 0, Pitch = 1.1, Label = "Sorpresa", Tempo = 1.1, Head = 0.06, Open = 0.3, Recoil = 1.1 },
	Joy = { Pose = "Happy", Speed = 1.1, Gesture = "Cheer", Tremble = 0, Bounce = 0.6, Pitch = 1.08, Label = "Alegría", Tempo = 1.2, Head = 0.05, Open = 0.6 },
	Sad = { Pose = "Sad", Speed = 0.6, Tremble = 0, Bounce = 0, Pitch = 0.92, Label = "Tristeza", Tempo = 0.65, Head = -0.14, Open = -0.5, Gaze = "Down" },
	Hurt = { Pose = "Hurt", Speed = 0.45, Tremble = 0.35, Bounce = 0, Pitch = 0.95, Label = "Herido", Tempo = 0.7, Head = -0.08, Open = -0.4 },
	Nervous = { Pose = "Nervous", Speed = 1.05, Tremble = 0.08, Bounce = 0, Pitch = 1.05, Label = "Nervios", Tempo = 1.15, Head = -0.03, Open = -0.3, Gaze = "Around", Fidget = 0.8 },
	Shame = { Pose = "Ashamed", Speed = 0.85, Tremble = 0, Bounce = 0, Pitch = 0.95, Label = "Vergüenza", Tempo = 0.8, Head = -0.2, Open = -0.6, Gaze = "Avoid" },
} :: { [string]: Mood }

-- Alias en español
ActorMoods.Alias = {
	Tranquilo = "Calm",
	Miedo = "Fear",
	Enfado = "Angry",
	Sorpresa = "Surprise",
	Alegria = "Joy",
	["Alegría"] = "Joy",
	Tristeza = "Sad",
	Herido = "Hurt",
	Nervios = "Nervous",
	Nervioso = "Nervous",
	Nerviosa = "Nervous",
	Verguenza = "Shame",
	["Vergüenza"] = "Shame",
	Avergonzado = "Shame",
	Avergonzada = "Shame",
	Alegre = "Joy",
	Triste = "Sad",
	Enfadado = "Angry",
	Enfadada = "Angry",
	Sorprendido = "Surprise",
	Sorprendida = "Surprise",
}

-- La emoción de una FRASE (Emotion: la postura con que se dice) -> la emoción que dura que le
-- corresponde, para actuar igual mientras habla (ritmo, cabeza, mirada)
ActorMoods.FromPose = {
	Happy = "Joy",
	Laugh = "Joy",
	Cheer = "Joy",
	Sad = "Sad",
	Angry = "Angry",
	Surprised = "Surprise",
	Nervous = "Nervous",
	Ashamed = "Shame",
	Scared = "Fear",
	Hurt = "Hurt",
}

-- Posturas nuevas que ActorLife entiende además de las de Emotion (las de las emociones)
ActorMoods.ExtraPoses = { Scared = true, Hurt = true }

-- Nombre canónico de una emoción (o nil si no existe)
function ActorMoods.name(mood: any): string?
	if type(mood) ~= "string" then
		return nil
	end
	if ActorMoods.List[mood] then
		return mood
	end
	return ActorMoods.Alias[mood]
end

function ActorMoods.get(mood: any): Mood?
	local name = ActorMoods.name(mood)
	return name and ActorMoods.List[name] or nil
end

function ActorMoods.valid(mood: any): boolean
	return ActorMoods.name(mood) ~= nil
end

-- Todas las emociones válidas (con alias) para comprobar las escenas
function ActorMoods.names(): { [string]: boolean }
	local set = {}
	for name in ActorMoods.List do
		set[name] = true
	end
	for alias in ActorMoods.Alias do
		set[alias] = true
	end
	return set
end

-- Velocidad al andar con esa emoción (base = la normal del actor)
function ActorMoods.walkSpeed(base: number, mood: any, run: boolean?): number
	local m = ActorMoods.get(mood)
	local k = if m then m.Speed else 1
	return base * k * (if run then 1.6 else 1)
end

-- Temblor del cuerpo en el instante t (radianes pequeños; 0 si no tiembla). Puro: lo prueba test-scenes.
function ActorMoods.tremble(mood: any, t: number, seed: number): number
	local m = ActorMoods.get(mood)
	if not m or m.Tremble <= 0 then
		return 0
	end
	return (math.sin(t * 31 + seed) * 0.6 + math.sin(t * 47 + seed * 2) * 0.4) * 0.025 * m.Tremble
end

-- Saltitos (studs hacia arriba) en el instante t
function ActorMoods.bounce(mood: any, t: number, seed: number): number
	local m = ActorMoods.get(mood)
	if not m or m.Bounce <= 0 then
		return 0
	end
	return math.abs(math.sin(t * 7 + seed)) * 0.12 * m.Bounce
end

-- Cómo actúa con esa emoción (con los valores por defecto puestos). mood: nombre, alias o nil.
local CALM_ACTING: Acting = { Tempo = 1, Head = 0, Open = 0, Gaze = nil, Fidget = 0, Recoil = 0 }
function ActorMoods.acting(mood: any): Acting
	local m = ActorMoods.get(mood)
	if not m then
		return CALM_ACTING
	end
	return {
		Tempo = m.Tempo or 1,
		Head = m.Head or 0,
		Open = m.Open or 0,
		Gaze = m.Gaze,
		Fidget = m.Fidget or 0,
		Recoil = m.Recoil or 0,
	}
end

-- La emoción que dura que corresponde a la postura de una frase (o nil)
function ActorMoods.fromPose(pose: any): string?
	return if type(pose) == "string" then ActorMoods.FromPose[pose] else nil
end

return ActorMoods
