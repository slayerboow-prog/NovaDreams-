-- Wanted: reglas del nivel de búsqueda (estrellas) — lo usan WantedService (servidor) y WantedUI.
--
--   * Hacer algo malo (pegar, dejar K.O., robar a alguien, atracar una tienda, agredir a la
--     policía) solo cuenta si alguien lo ve: la policía (jugadores de servicio o las patrullas)
--     o un testigo que llama (un personaje cercano; en la calle, a veces un transeúnte).
--   * Cada delito suma estrellas (máx. 5). Con más estrellas vienen más patrullas y, desde la
--     cuarta, helicópteros.
--   * Para librarte: que ningún policía te vea durante un rato (más largo cuantas más estrellas).
--   * Si te alcanzan (o te quedas K.O. con un agente cerca): detenido, multa y a la comisaría.

local Wanted = {}

Wanted.MaxStars = 5
Wanted.MinStage = "Adolescente" -- antes de esta edad no hay estrellas (solo un aviso)

-- Delitos: estrellas que suman y cómo se llaman
Wanted.Crimes = {
	Agresion = { Stars = 1, Text = "Agresión" },
	KO = { Stars = 1, Text = "Dejar K.O. a alguien" },
	Robo = { Stars = 1, Text = "Robo a una persona" },
	Atraco = { Stars = 2, Text = "Atraco a una tienda" },
	AgresionPolicia = { Stars = 2, Text = "Agresión a un agente" },
	Fuga = { Stars = 3, Text = "Fuga de prisión" },
	Homicidio = { Stars = 3, Text = "Homicidio" },
}

Wanted.PoliceSight = 90 -- studs a los que un agente (o un policía jugador) te ve
Wanted.HeliSight = 140 -- el helicóptero ve más lejos (si no te tapa un techo)
Wanted.WitnessRadius = 50 -- personajes que pueden verlo y llamar
Wanted.CallDelay = 3 -- lo que tarda un testigo en llamar
Wanted.StreetCallChance = 0.5 -- en la calle sin testigos a la vista, a veces llama un transeúnte
Wanted.StreetDistance = 40 -- "en la calle" = a menos de esto de una carretera

-- Patrullas según las estrellas: coches (2 agentes cada uno) y helicópteros
Wanted.Response = {
	[1] = { Cars = 1, Helis = 0 },
	[2] = { Cars = 2, Helis = 0 },
	[3] = { Cars = 3, Helis = 0 },
	[4] = { Cars = 3, Helis = 1 },
	[5] = { Cars = 4, Helis = 2 },
}
Wanted.OfficerSpeed = { 14, 15, 16, 17, 18 } -- a pie (andando tú vas a 16 y corriendo más)
Wanted.CarSpeed = 45
Wanted.CatchDistance = 4.5 -- a esta distancia un agente te está deteniendo…
Wanted.CatchSeconds = 1.2 -- …y si sigue así este tiempo, te detiene
Wanted.OfficerHealth = 40 -- los agentes se pueden tumbar a golpes (pero sube la búsqueda)
Wanted.Fine = 60 -- por estrella al detenerte
Wanted.ArrestReward = 25 -- por estrella, al policía (jugador) que te detiene

-- Robar a otra persona
Wanted.StealShare = 0.15
Wanted.StealMin, Wanted.StealMax = 5, 120
Wanted.StealCooldown = 30
Wanted.StealRange = 6

-- Atraco a una tienda
Wanted.HeistHold = 2.5
Wanted.HeistLoot = { 80, 220 }
Wanted.HeistCooldown = 300 -- la misma tienda no se puede volver a atracar hasta pasado esto

-- Estrellas después de un delito
function Wanted.starsAfter(current: number, crime: string): number
	local def = Wanted.Crimes[crime]
	if not def then
		return current
	end
	return math.clamp(current + def.Stars, 0, Wanted.MaxStars)
end

-- Tiempo sin que te vea la policía para librarte
function Wanted.evadeSeconds(stars: number): number
	if stars <= 0 then
		return 0
	end
	return 20 + 12 * stars
end

-- Cuántas patrullas vienen
function Wanted.response(stars: number): { Cars: number, Helis: number }
	return Wanted.Response[math.clamp(stars, 1, Wanted.MaxStars)] or { Cars = 0, Helis = 0 }
end

function Wanted.fine(stars: number): number
	return Wanted.Fine * math.max(stars, 1)
end

-- Cuánto dinero se lleva un ladrón de alguien que tiene "money"
function Wanted.stealAmount(money: number): number
	if money <= 0 then
		return 0
	end
	return math.min(money, math.clamp(math.floor(money * Wanted.StealShare), Wanted.StealMin, Wanted.StealMax))
end

return Wanted
