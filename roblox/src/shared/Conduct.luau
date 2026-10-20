-- Conduct: el historial de buen o mal comportamiento («chico o chica malo») — lo usan
-- ConductService (servidor) y la ficha del personaje (cliente).
--
--   * Cada cosa mala que sabe alguien (la policía, un testigo, tu familia) suma puntos al historial:
--     conducir sin carnet, pelearse, romper cristales, disparar, robar…
--   * Portarse bien lo va borrando: cada día de juego sin nada nuevo, un punto menos.
--   * Si eres menor (niño o adolescente), además se entera tu familia: te llaman al móvil, se
--     enfadan (baja la relación con tus padres), sube tu Rebeldía y te castigan (sin paga y a casa
--     antes de la noche). Si la policía te detiene, no vas a juicio: te llevan a casa.
-- Los antecedentes penales de los adultos (condenas) siguen en data.Record (JusticeService).

local Conduct = {}

-- Puntos de cada cosa (las claves son las de los delitos de shared/Wanted, y alguna más)
Conduct.Points = {
	SinCarnet = 2,
	MenorVolante = 3,
	Huida = 3,
	Agresion = 2,
	KO = 3,
	Robo = 3,
	Atraco = 5,
	AgresionPolicia = 4,
	Fuga = 5,
	Homicidio = 10,
	Disparo = 5,
	Disparos = 3,
	Vandalismo = 2,
	Detenido = 2, -- la policía te ha llevado a casa
}
Conduct.DefaultPoints = 2

-- Cómo se cuenta cada cosa en el historial (los delitos ya tienen su texto en shared/Wanted)
Conduct.Texts = {
	Vandalismo = "Romper cristales o puertas",
	Detenido = "La policía te trajo a casa",
}

Conduct.LogLimit = 30 -- entradas que se guardan
Conduct.CalmMinutes = 20 -- cada tantos minutos reales sin nada nuevo, un punto menos (≈ un día de juego)

-- Tu familia (solo si eres menor)
Conduct.Family = {
	Rel = -6, -- relación con tus padres (-100..100) por cada cosa
	RelArrest = -10, -- más si te trae la policía a casa
	Affinity = -1, -- confianza (0..5)
	Rebeldia = 1, -- rasgo de la historia
	GroundedMinutes = 10, -- castigo (minutos reales) por cada cosa…
	GroundedMax = 45, -- …con un máximo
	Allowance = { Nino = 5, Adolescente = 10 }, -- la paga (cada día de juego, si no estás castigado)
	CurfewFrom = 21, -- castigado: a casa antes de esta hora…
	CurfewTo = 7, -- …y hasta esta
}

-- Lo que te dicen tus padres por el móvil cuando se enteran ({crimen} = lo que has hecho)
Conduct.Calls = {
	"📱 {familia}: ¡Nos ha llamado la policía! ¿{crimen}? Vuelve a casa ahora mismo.",
	"📱 {familia}: Me acaban de contar lo que has hecho. Esta noche hablamos. Estás castigado/a.",
	"📱 {familia}: ¿Otra vez? ¡Qué disgusto! Sin paga hasta nuevo aviso.",
}

-- La charla en casa cuando te trae la policía (S = quién habla, como en los diálogos de la historia)
Conduct.HomeScene = {
	{ S = "Narrador", T = "El coche patrulla se para delante de casa. {familia} ya te espera en la puerta." },
	{ S = "Familia", T = "Gracias, agentes. Ya nos encargamos nosotros." },
	{ S = "Familia", T = "¿Cómo que «{crimen}»? ¿Pero tú en qué estabas pensando? ¡Podías haberte hecho daño… o hacérselo a alguien!" },
	{ S = "Familia", T = "Estás castigado/a: sin paga y a casa antes de que se haga de noche. Y ya hablaremos de esto." },
}

-- Niveles del historial (de menos a más puntos)
Conduct.Levels = {
	{ Min = 0, Icon = "😇", Name = "Un angelito" },
	{ Min = 1, Icon = "🙂", Name = "Buen chico o buena chica" },
	{ Min = 5, Icon = "😬", Name = "Un poco trasto" },
	{ Min = 12, Icon = "😈", Name = "Chico malo o chica mala" },
	{ Min = 25, Icon = "🚨", Name = "La oveja negra del barrio" },
}

function Conduct.pointsOf(kind: string): number
	return Conduct.Points[kind] or Conduct.DefaultPoints
end

function Conduct.level(points: number): { Min: number, Icon: string, Name: string }
	local best = Conduct.Levels[1]
	for _, level in Conduct.Levels do
		if points >= level.Min then
			best = level
		end
	end
	return best
end

function Conduct.isMinor(stage: string?): boolean
	return stage == "Bebe" or stage == "Nino" or stage == "Adolescente"
end

-- Minutos de castigo que quedan después de una cosa más (se suman, con un máximo)
function Conduct.groundedAfter(currentMinutes: number): number
	local f = Conduct.Family
	return math.min(f.GroundedMax, math.max(0, currentMinutes) + f.GroundedMinutes)
end

-- ¿Es hora de estar en casa (castigado)?
function Conduct.curfew(clockTime: number): boolean
	local f = Conduct.Family
	return clockTime >= f.CurfewFrom or clockTime < f.CurfewTo
end

-- Puntos después de portarse bien un rato (nunca por debajo de 0)
function Conduct.calmed(points: number, calmSteps: number): number
	return math.max(0, points - math.max(0, math.floor(calmSteps)))
end

return Conduct
