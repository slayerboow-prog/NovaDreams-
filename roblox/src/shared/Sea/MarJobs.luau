-- MarJobs: los OFICIOS del mar de la fase 1 (docs/mar/civilizacion-marina.md §4.2; recortado a dos por el
-- dueño). Datos y cuentas puras: los usan Services/MarJobService (el servidor lleva cada turno),
-- World/NacaraCityBuilder (tablones, bancales y perlas-farola) y scripts/test-hondario.luau.
--
--   🌿 Cultivador/a de algas (Corriente del Cultivo): sembrar en un bancal → quitar los caracoles (cesta de
--      Tomé) → cosechar en el mismo bancal → llevar las algas a la Lonja Honda (la cúpula de la plaza)
--   🔆 Farolero/a (Corriente de la Luz): cargar tres perlas-farola del paseo y volver al tablón. De noche
--      (18:00–8:00) paga más: es cuando hacen falta.
-- Las reglas de siempre (las de los oficios de Tefra y los planetas): mismo dinero (€), cinco rangos que
-- multiplican la paga, el servidor mira distancias y tiempos, tiempo mínimo por encargo, tope por hora y la
-- paga baja un poco si repites mucho lo mismo. La carrera se guarda en data.Careers[IdDelOficio].

local MarJobs = {}

MarJobs.Ranks = {
	{ Id = "Aprendiz", Name = "Aprendiz", Points = 0, Mult = 1.0 },
	{ Id = "Oficial", Name = "Oficial", Points = 10, Mult = 1.2 },
	{ Id = "Veterano", Name = "Veterano/a", Points = 30, Mult = 1.45 },
	{ Id = "Experto", Name = "Experto/a", Points = 80, Mult = 1.75 },
	{ Id = "Maestro", Name = "Maestro/a", Points = 180, Mult = 2.1 },
}

function MarJobs.rankFor(points: number): (number, { [string]: any })
	local index = 1
	for i, r in MarJobs.Ranks do
		if points >= r.Points then
			index = i
		end
	end
	return index, MarJobs.Ranks[index]
end

MarJobs.Jobs = {
	MarCultivador = {
		Id = "MarCultivador", Name = "Cultivador/a de algas", Icon = "🌿", Pay = 42, MinSeconds = 30, Current = "Cultivo",
		Desc = "Siembra en un bancal, quita los caracoles, cosecha y lleva las algas a la Lonja Honda.",
		-- fases: { Id, Texto, a dónde (Bed = el bancal del turno; Basket = la cesta de Tomé; Lonja = la cúpula), espera }
		Phases = {
			{ Id = "Sembrar", Text = "🌱 Siembra el bancal marcado", At = "Bed", Hold = 3 },
			{ Id = "Caracoles", Text = "🐌 Hay caracoles: llévalos a la cesta de Tomé", At = "Basket", Hold = 0 },
			{ Id = "Cosechar", Text = "🌿 Vuelve al bancal y cosecha", At = "Bed", Hold = 3 },
			{ Id = "Lonja", Text = "🧺 Lleva las algas a la Lonja Honda (la cúpula de la plaza)", At = "Lonja", Hold = 0 },
		},
	},
	MarFarolero = {
		Id = "MarFarolero", Name = "Farolero/a", Icon = "🔆", Pay = 48, MinSeconds = 30, Current = "Luz", Lamps = 3,
		Desc = "Carga tres perlas-farola del paseo antes de que lo hondo se acerque, y vuelve al tablón.",
	},
}
MarJobs.Order = { "MarCultivador", "MarFarolero" }

function MarJobs.isMarJob(id: any): boolean
	return type(id) == "string" and MarJobs.Jobs[id] ~= nil
end

-- ¿Es de noche para las perlas-farola? (hora del juego)
function MarJobs.night(hour: number): boolean
	return hour >= 18 or hour < 8
end

function MarJobs.streakFactor(streak: number): number
	if streak <= 8 then
		return 1
	end
	return math.max(0.7, 1 - (streak - 8) * 0.08)
end

-- La paga de un encargo (rango, racha y extra: 1,25 de noche para los faroleros)
function MarJobs.pay(jobId: string, points: number, streak: number, extra: number?): number
	local job = MarJobs.Jobs[jobId]
	if not job then
		return 0
	end
	local _, rank = MarJobs.rankFor(points)
	return math.floor(job.Pay * rank.Mult * MarJobs.streakFactor(streak) * (extra or 1) + 0.5)
end

-- Contra trampas: tiempo mínimo por encargo y tope por hora
MarJobs.MaxPerHour = 30
function MarJobs.allowed(jobId: string, history: { number }, started: number, now: number): (boolean, string?)
	local job = MarJobs.Jobs[jobId]
	if not job then
		return false, "Oficio desconocido"
	end
	if now - started < job.MinSeconds then
		return false, "Demasiado rápido"
	end
	local count = 0
	for _, t in history do
		if now - t < 3600 then
			count += 1
		end
	end
	if count >= MarJobs.MaxPerHour then
		return false, "Ya has hecho muchos encargos de este oficio en la última hora: descansa o prueba otro"
	end
	return true, nil
end

-- Tres perlas-farola distintas para un turno (seed: para que no salgan siempre las mismas)
function MarJobs.pickLamps(ids: { string }, n: number, seed: number): { string }
	local pool = table.clone(ids)
	local out = {}
	local s = math.floor(seed) % 2147483647
	for _ = 1, math.min(n, #pool) do
		s = (s * 1103515245 + 12345) % 2147483648
		local i = s % #pool + 1
		table.insert(out, table.remove(pool, i))
	end
	return out
end

return MarJobs
