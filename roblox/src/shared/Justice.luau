-- Justice: reglas de los juicios y las condenas (JusticeService en el servidor, JusticeUI en el cliente).
--
-- Al detenerte (WantedService) se abre un caso con tus delitos y tus estrellas:
--   * Si hay un/a juez de servicio, te llevan al juzgado y hay juicio: el juez decide absolver,
--     solo multa, o multa y prisión (de 1 a MaxMinutes minutos).
--   * Si no hay juez (o no decide a tiempo), sentencia automática según las estrellas.
-- En prisión: la condena corre con el reloj real (también desconectado). Dentro hay mucho que hacer
-- (PrisonService): trabajar, estudiar, leer o reflexionar la reducen un poco; pelearse la alarga y
-- te manda a aislamiento. No se puede salir hasta cumplirla (salvo libertad o… un túnel).

local Justice = {}

Justice.TrialSeconds = 90 -- tiempo que tiene el juez para dictar sentencia
Justice.MaxMinutes = 30
Justice.FinePerStar = 60
Justice.WorkReduction = 10 -- segundos menos de condena por cada trabajo en prisión
Justice.WorkCooldown = 12 -- segundos entre trabajos
Justice.JudgePay = 40 -- por caso juzgado
Justice.RecordLimit = 20 -- antecedentes que se guardan

Justice.FightPenalty = 30 -- segundos más por pelearse dentro (y a aislamiento)
Justice.IsolationSeconds = 45
Justice.TunnelStep = 4 -- % de túnel por cada vez que cavas (25 veces para escapar)
Justice.TunnelPenalty = 60 -- segundos más si un funcionario encuentra tu túnel
Justice.CourseLessons = 6 -- lecciones para sacarse el graduado en prisión
Justice.CourseReduction = 90

-- Condena automática (sin juez): multa y segundos de prisión (de 4 a 12 minutos)
function Justice.automatic(stars: number): (number, number)
	local s = math.clamp(stars, 1, 5)
	return Justice.FinePerStar * s, 120 + 120 * s
end

-- Lo que decide el juez: "Absolver", "Multa" o "Prision" (minutes 1..MaxMinutes)
function Justice.verdict(kind: string, stars: number, minutes: number?): (number, number)
	local s = math.clamp(stars, 1, 5)
	if kind == "Absolver" then
		return 0, 0
	elseif kind == "Multa" then
		return Justice.FinePerStar * s, 0
	end
	local m = math.clamp(math.floor(minutes or 1), 1, Justice.MaxMinutes)
	return Justice.FinePerStar * s, m * 60
end

-- Condena que queda tras un trabajo en prisión (nunca por debajo de 0)
function Justice.afterWork(remaining: number): number
	return math.max(0, remaining - Justice.WorkReduction)
end

return Justice
