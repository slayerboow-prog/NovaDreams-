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
--   }
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
}

ActorMoods.List = {
	Calm = { Pose = nil, Speed = 1, Tremble = 0, Bounce = 0, Pitch = 1, Label = "Tranquilo" },
	Fear = { Pose = "Scared", Speed = 1.35, Tremble = 0.7, Bounce = 0, Pitch = 1.15, Label = "Miedo" },
	Angry = { Pose = "Angry", Speed = 1.1, Gesture = nil, Tremble = 0.15, Bounce = 0, Pitch = 0.9, Label = "Enfado" },
	Surprise = { Pose = "Surprised", Speed = 1, Tremble = 0, Bounce = 0, Pitch = 1.1, Label = "Sorpresa" },
	Joy = { Pose = "Happy", Speed = 1.1, Gesture = "Cheer", Tremble = 0, Bounce = 0.6, Pitch = 1.08, Label = "Alegría" },
	Sad = { Pose = "Sad", Speed = 0.6, Tremble = 0, Bounce = 0, Pitch = 0.92, Label = "Tristeza" },
	Hurt = { Pose = "Hurt", Speed = 0.45, Tremble = 0.35, Bounce = 0, Pitch = 0.95, Label = "Herido" },
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

return ActorMoods
