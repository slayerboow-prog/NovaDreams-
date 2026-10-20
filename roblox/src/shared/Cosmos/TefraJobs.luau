-- TefraJobs: los OFICIOS de Tefra (docs/planetas/diseno-mundos.md §2.1 y §3.1.9; docs/planetas/tefra-misiones.md).
-- Datos y cuentas puras: los usan Services/TefraJobService (el servidor lleva cada turno), World/
-- TefraCityBuilder (pone los tablones y los puntos) y las pruebas (scripts/test-tefra.luau).
--
-- Los cuatro oficios propios de Tefra (tablones «Trabajar» en la Oficina de trabajo de las Fundiciones):
--   🔥 Fundidor/a          cargar el crisol → controlar la temperatura (aguja) → colar en los moldes
--   💣 Desactivador/a      localizar la bomba con el detector → cortar el cable correcto (puzle con
--                          pista) y pulso firme → llevar la carcasa al polvorín. Si fallas: «¡BUM!»
--                          (Derribado, sin sangre ni daño: despiertas en el Campus Nilda)
--   🌋 Bombero/a de coladas  aviso → llegar → 3 barreras de basalto contra reloj → enfriar con agua
--   ✉ Correo de túnel      recoger la saca → bajar por una boca de túnel → entregar sin que te vea la
--                          patrulla (sigilo ligero; de noche, en toque de queda, paga más y ven más)
-- Y dos de los once oficios comunes de la galaxia con el toque de Tefra (Tablón de la Galaxia del Muelle):
--   ⛑ Rescatista           gente atrapada en escombros (más tras un bombardeo) → levantar → hospital
--   🧱 Ingeniero/a de obras  bloques de basalto de la Forja → reparar la Muralla → prueba de carga
--
-- Progreso: puntos de oficio en data.Careers[IdDelOficio] (la estructura de siempre de CareerService);
-- los comunes de la galaxia guardan además la experiencia de cada planeta (Local = { Tefra = n }).
-- Cinco rangos (Aprendiz → Maestro) que multiplican la paga (×1 … ×2,1). Contra trampas: tiempo
-- mínimo por encargo, tope por hora y la paga baja un poco si repites el mismo oficio muchas veces
-- seguidas. De cada 5 encargos, 1 trae una pequeña historia con una decisión.

local TefraCity = require(script.Parent.TefraCity)

local TefraJobs = {}

---------------------------------------------------------------------
-- Rangos (la carrera de la galaxia, §2.1)
---------------------------------------------------------------------
TefraJobs.Ranks = {
	{ Id = "Aprendiz", Name = "Aprendiz", Points = 0, Mult = 1.0 },
	{ Id = "Oficial", Name = "Oficial", Points = 12, Mult = 1.2 },
	{ Id = "Veterano", Name = "Veterano/a", Points = 36, Mult = 1.45 },
	{ Id = "Experto", Name = "Experto/a", Points = 100, Mult = 1.75 },
	{ Id = "Maestro", Name = "Maestro/a", Points = 220, Mult = 2.1 },
}

function TefraJobs.rankFor(points: number): (number, { [string]: any })
	local index = 1
	for i, r in TefraJobs.Ranks do
		if points >= r.Points then
			index = i
		end
	end
	return index, TefraJobs.Ranks[index]
end

---------------------------------------------------------------------
-- Los oficios
---------------------------------------------------------------------
export type Job = {
	Id: string,
	Name: string,
	Icon: string,
	Pay: number, -- paga base (rango 1) por encargo, en €
	MinSeconds: number, -- un encargo no se puede acabar antes
	Galaxy: boolean?, -- oficio común de la galaxia (la carrera es la misma en todos los planetas)
	Board: string, -- dónde está su tablón: "Oficina" o "Galaxia"
	Chispas: number?, -- (peligrosos) Chispas de estrella por encargo bien hecho (con tope por hora)
	Drop: { Item: string, Chance: number }?, -- material que a veces te llevas
	Desc: string,
}

TefraJobs.Jobs = {
	TefraFundidor = {
		Id = "TefraFundidor", Name = "Fundidor/a", Icon = "🔥", Pay = 40, MinSeconds = 25, Board = "Oficina",
		Drop = { Item = "CuarzoMalva", Chance = 0.25 },
		Desc = "Funde mineral en las Fundiciones: carga el crisol, controla la temperatura y cuela en los moldes.",
	},
	TefraDesactivador = {
		Id = "TefraDesactivador", Name = "Desactivador/a de munición", Icon = "💣", Pay = 60, MinSeconds = 30, Board = "Oficina", Chispas = 1,
		Drop = { Item = "AzufreNegro", Chance = 0.3 },
		Desc = "Limpia bombas sin explotar: localízala con el detector, corta el cable correcto y llévala al polvorín.",
	},
	TefraBombero = {
		Id = "TefraBombero", Name = "Bombero/a de coladas", Icon = "🌋", Pay = 55, MinSeconds = 30, Board = "Oficina",
		Drop = { Item = "ObsidianaIgnea", Chance = 0.35 },
		Desc = "Desvía la lava que amenaza los barrios: tres barreras de basalto contra reloj y agua a presión.",
	},
	TefraCorreo = {
		Id = "TefraCorreo", Name = "Correo de túnel", Icon = "✉", Pay = 45, MinSeconds = 35, Board = "Oficina",
		Desc = "Lleva cartas por los túneles sin que te vea la patrulla. De noche, con el toque de queda, paga más.",
	},
	GalaxiaRescatista = {
		Id = "GalaxiaRescatista", Name = "Rescatista", Icon = "⛑", Pay = 60, MinSeconds = 25, Board = "Galaxia", Galaxy = true,
		Desc = "Saca a la gente atrapada en los escombros y llévala al Campus Nilda. Tras un bombardeo, paga extra.",
	},
	GalaxiaIngeniero = {
		Id = "GalaxiaIngeniero", Name = "Ingeniero/a de obras", Icon = "🧱", Pay = 70, MinSeconds = 25, Board = "Galaxia", Galaxy = true,
		Drop = { Item = "ObsidianaIgnea", Chance = 0.2 },
		Desc = "Repara la Muralla tras los bombardeos: bloques de basalto de la Forja, montarlos y la prueba de carga.",
	},
} :: { [string]: Job }

TefraJobs.Order = { "TefraFundidor", "TefraDesactivador", "TefraBombero", "TefraCorreo", "GalaxiaRescatista", "GalaxiaIngeniero" }

function TefraJobs.isTefraJob(id: any): boolean
	return type(id) == "string" and TefraJobs.Jobs[id] ~= nil
end

---------------------------------------------------------------------
-- Dónde se trabaja (local x, z de Tefra; Out = fuera de la muralla, en el suelo del planeta)
---------------------------------------------------------------------
-- Tablones «Trabajar»: los cuatro de Tefra en la acera de la Oficina de trabajo y los dos de la galaxia
-- junto a la plataforma del Muelle (el «Tablón de la Galaxia»)
TefraJobs.Boards = {
	TefraFundidor = { -93, 112 },
	TefraDesactivador = { -93, 124 },
	TefraBombero = { -93, 136 },
	TefraCorreo = { -93, 148 },
	GalaxiaRescatista = { 32, 52 },
	GalaxiaIngeniero = { 40, 52 },
}

-- Fundidor: las dos fundiciones (montón de mineral → crisol → moldes, dentro de su nave)
TefraJobs.Foundries = {
	{ Name = "Fundición Norte", Pile = { -352, 130 }, Crucible = { -320, 118 }, Molds = { -288, 130 } },
	{ Name = "Fundición Sur", Pile = { -352, 190 }, Crucible = { -320, 186 }, Molds = { -288, 190 } },
}

-- Desactivador: bombas sin explotar (el detector te lleva a la zona; de cerca, al sitio exacto)
TefraJobs.Bombs = {
	{ Name = "las cúpulas rotas del Ovillo", X = -300, Z = -108 },
	{ Name = "la Calle del Ovillo", X = -240, Z = -182 },
	{ Name = "la Ronda Oeste", X = -388, Z = -20 },
	{ Name = "la explanada de la pelota", X = -320, Z = 335 },
	{ Name = "la Avenida del Muelle", X = -62, Z = -200 },
	{ Name = "la explanada de los Pozos", X = 160, Z = 110 },
	{ Name = "junto a la Lanza", X = 45, Z = 300 },
	{ Name = "la Ronda Este", X = 228, Z = -60 },
	{ Name = "la tierra de nadie (Trincheras)", X = 430, Z = 120, Out = true },
	{ Name = "una trinchera del Este", X = 470, Z = 60, Out = true },
}
TefraJobs.Polvorin = { -320, 256 } -- el polvorín del Cuartel de la Muralla
TefraJobs.DetectRadius = 26 -- a esta distancia el detector pita y marca el sitio exacto
TefraJobs.BoomHome = { 96, 0 } -- si explota, despiertas en el Campus Nilda

-- Bombero de coladas: coladas que se desbordan (con los tres sitios de las barreras)
TefraJobs.Coladas = {
	{ Name = "el Canal de la Forja, junto a las viviendas", X = -260, Z = 224, Barriers = { { -272, 224 }, { -260, 221 }, { -248, 224 } } },
	{ Name = "el Canal de la Forja, junto a los Pozos", X = 150, Z = 224, Barriers = { { 138, 224 }, { 150, 221 }, { 162, 224 } } },
	{ Name = "el Canal de la Forja, frente a las raciones", X = 60, Z = 256, Barriers = { { 48, 256 }, { 60, 259 }, { 72, 256 } } },
	{ Name = "el Pozo de Magma", X = 14, Z = 297, Barriers = { { 20, 306 }, { 9, 308 }, { 27, 297 } } },
	{ Name = "el final del canal, junto al cuartel", X = -380, Z = 253, Barriers = { { -392, 256 }, { -380, 258 }, { -368, 256 } } },
}
TefraJobs.BarrierSeconds = 90 -- tiempo para poner las tres barreras

-- Correo de túnel: estafetas (saca), bocas de túnel y destinos
TefraJobs.Mailboxes = { { -146, -95 }, { -96, 142 } }
TefraJobs.Tunnels = {
	{ Name = "la boca del túnel del Ovillo", X = -240, Z = 0 },
	{ Name = "la boca del túnel del Muelle", X = 0, Z = 82 },
	{ Name = "la boca del túnel del Mirador", X = 82, Z = -160 },
	{ Name = "la boca del túnel de las Fundiciones", X = -82, Z = 170 },
}
TefraJobs.Deliveries = {
	{ Name = "el Bloque del Refugio 1", X = -351, Z = -64 },
	{ Name = "el Bloque del Refugio 2", X = -289, Z = -64 },
	{ Name = "el Bloque del Refugio 3", X = -351, Z = 64 },
	{ Name = "el Campus Nilda", X = 96, Z = 0 },
	{ Name = "las viviendas obreras", X = -189, Z = 256 },
	{ Name = "las tiendas del Mirador", X = 125, Z = -194 },
	{ Name = "el reparto de raciones", X = 140, Z = 256 },
}
-- Las patrullas de la policía militar (ida y vuelta por una calle; 7 studs/s)
TefraJobs.Patrols = {
	{ Name = "Avenida del Muelle", Points = { { -80, -200 }, { -80, 200 } } },
	{ Name = "Calle de los Refugiados", Points = { { -380, 80 }, { 220, 80 } } },
	{ Name = "Calle de la Academia", Points = { { 80, -220 }, { 80, 360 } } },
	{ Name = "Calle de las Cúpulas", Points = { { -380, -80 }, { 220, -80 } } },
}
TefraJobs.PatrolSpeed = 7
TefraJobs.SeeRadius = 10
TefraJobs.SeeRadiusNight = 13
TefraJobs.CurfewFrom = 22
TefraJobs.CurfewTo = 6
TefraJobs.CurfewBonus = 1.5
TefraJobs.CaughtFine = 10

-- Rescatista: escombros (si hubo bombardeo, salen en sus zonas) y el hospital
TefraJobs.Rubble = {
	{ Name = "las cúpulas del Ovillo", X = -296, Z = -112 },
	{ Name = "la Ronda Norte", X = -150, Z = -228 },
	{ Name = "la explanada de la pelota", X = -300, Z = 330 },
	{ Name = "el patio de las Fundiciones", X = -210, Z = 165 },
	{ Name = "la Ronda Este", X = 230, Z = 300 },
}
TefraJobs.HospitalDoor = { 96, 0 }

-- Ingeniero: los bloques (puerta de la Forja) y los tramos de Muralla que hay que reparar
TefraJobs.BlockYard = { -205, 96 }
TefraJobs.WallRepairs = {
	{ Name = "la Muralla Oeste (norte)", X = -412, Z = -150 },
	{ Name = "la Muralla Oeste (sur)", X = -412, Z = 160 },
	{ Name = "la Muralla Norte", X = 100, Z = -252 },
	{ Name = "la Muralla Este (sur)", X = 252, Z = 300 },
	{ Name = "la Muralla Este (norte)", X = 252, Z = -150 },
	{ Name = "la Muralla Sur", X = -300, Z = 412 },
}

-- Todos los puntos de los oficios (para comprobarlos: test-tefra / test-planetas)
function TefraJobs.allPoints(): { { [string]: any } }
	local out = {}
	local function add(kind: string, x: number, z: number, out_: boolean?)
		table.insert(out, { Kind = kind, X = x, Z = z, Out = out_ })
	end
	for id, p in TefraJobs.Boards do
		add("Tablón " .. id, p[1], p[2])
	end
	for _, f in TefraJobs.Foundries do
		add("Montón " .. f.Name, f.Pile[1], f.Pile[2])
		add("Crisol " .. f.Name, f.Crucible[1], f.Crucible[2])
		add("Moldes " .. f.Name, f.Molds[1], f.Molds[2])
	end
	for _, b in TefraJobs.Bombs do
		add("Bomba en " .. b.Name, b.X, b.Z, b.Out)
	end
	add("Polvorín", TefraJobs.Polvorin[1], TefraJobs.Polvorin[2])
	for _, c in TefraJobs.Coladas do
		for i, q in c.Barriers do
			add(("Barrera %d de %s"):format(i, c.Name), q[1], q[2])
		end
	end
	for _, m in TefraJobs.Mailboxes do
		add("Estafeta", m[1], m[2])
	end
	for _, t in TefraJobs.Tunnels do
		add(t.Name, t.X, t.Z)
	end
	for _, d in TefraJobs.Deliveries do
		add("Entrega en " .. d.Name, d.X, d.Z)
	end
	for _, r in TefraJobs.Rubble do
		add("Escombros en " .. r.Name, r.X, r.Z)
	end
	add("Hospital", TefraJobs.HospitalDoor[1], TefraJobs.HospitalDoor[2])
	add("Bloques de basalto", TefraJobs.BlockYard[1], TefraJobs.BlockYard[2])
	for _, w in TefraJobs.WallRepairs do
		add("Reparar " .. w.Name, w.X, w.Z)
	end
	return out
end

---------------------------------------------------------------------
-- Cuentas
---------------------------------------------------------------------
-- Números repetibles
function TefraJobs.rng(seed: number): () -> number
	local s = math.floor(math.abs(seed)) % 2147483647
	if s == 0 then
		s = 7
	end
	return function()
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

-- Elegir de una lista (evitando el último: avoid = índice)
function TefraJobs.pick(list: { any }, r: () -> number, avoid: number?): (any, number)
	local n = #list
	if n == 0 then
		return nil, 0
	end
	local i = math.clamp(1 + math.floor(r() * n), 1, n)
	if avoid and n > 1 and i == avoid then
		i = i % n + 1
	end
	return list[i], i
end

-- Paga de un encargo: base × rango × lo bien que salió × repetir mucho lo mismo × extra (toque de
-- queda, después de un bombardeo…). score = 0..1 (aciertos del minijuego); streak = encargos seguidos
-- del mismo oficio (contando este)
function TefraJobs.streakFactor(streak: number): number
	if streak <= 8 then
		return 1
	end
	return math.max(0.7, 1 - (streak - 8) * 0.08)
end

function TefraJobs.pay(jobId: string, points: number, score: number, streak: number, extra: number?): number
	local job = TefraJobs.Jobs[jobId]
	if not job then
		return 0
	end
	local _, rank = TefraJobs.rankFor(points)
	local quality = 0.6 + 0.4 * math.clamp(score, 0, 1)
	return math.floor(job.Pay * rank.Mult * quality * TefraJobs.streakFactor(streak) * (extra or 1) + 0.5)
end

-- Puntos de oficio por un encargo (uno; dos si salió perfecto)
function TefraJobs.points(score: number): number
	return if score >= 0.999 then 2 else 1
end

-- Contra trampas: ¿se puede cobrar este encargo? history = { tiempos (os.clock) de los encargos de
-- este oficio }, started = cuándo empezó, now = ahora. Tope: MaxPerHour encargos por hora.
TefraJobs.MaxPerHour = 30
function TefraJobs.allowed(jobId: string, history: { number }, started: number, now: number): (boolean, string?)
	local job = TefraJobs.Jobs[jobId]
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
	if count >= TefraJobs.MaxPerHour then
		return false, "Ya has hecho muchos encargos de este oficio en la última hora: descansa o prueba otro"
	end
	return true, nil
end

-- Las Chispas de los oficios peligrosos tienen tope por hora (§2.1: como mucho 40 por hora entre todo;
-- los oficios de Tefra se quedan en 10)
TefraJobs.ChispasPerHour = 10

-- ¿Toque de queda? (hora de Tefra)
function TefraJobs.curfew(clock: number): boolean
	return clock >= TefraJobs.CurfewFrom or clock < TefraJobs.CurfewTo
end

-- Dónde está una patrulla en el instante t (segundos): va y vuelve por su calle
function TefraJobs.patrolAt(route: { [string]: any }, t: number): (number, number)
	local pts = route.Points
	local total = 0
	local lens = {}
	for i = 1, #pts - 1 do
		local l = math.sqrt((pts[i + 1][1] - pts[i][1]) ^ 2 + (pts[i + 1][2] - pts[i][2]) ^ 2)
		lens[i] = l
		total += l
	end
	if total <= 0 then
		return pts[1][1], pts[1][2]
	end
	local d = (t * TefraJobs.PatrolSpeed) % (2 * total)
	if d > total then
		d = 2 * total - d
	end
	for i = 1, #pts - 1 do
		if d <= lens[i] or i == #pts - 1 then
			local k = if lens[i] > 0 then math.clamp(d / lens[i], 0, 1) else 0
			return pts[i][1] + (pts[i + 1][1] - pts[i][1]) * k, pts[i][2] + (pts[i + 1][2] - pts[i][2]) * k
		end
		d -= lens[i]
	end
	return pts[#pts][1], pts[#pts][2]
end

-- ¿Te ve alguna patrulla? (t = instante; night = toque de queda). Dentro de un refugio, no.
function TefraJobs.seenBy(t: number, lx: number, lz: number, night: boolean): string?
	if TefraCity.shelterAt(lx, lz) then
		return nil
	end
	local r = if night then TefraJobs.SeeRadiusNight else TefraJobs.SeeRadius
	for _, route in TefraJobs.Patrols do
		local px, pz = TefraJobs.patrolAt(route, t)
		if (px - lx) ^ 2 + (pz - lz) ^ 2 <= r * r then
			return route.Name
		end
	end
	return nil
end

---------------------------------------------------------------------
-- El puzle de los cables (desactivador): tres cables y una pista que lleva a uno solo
---------------------------------------------------------------------
TefraJobs.Colors = { "rojo", "azul", "amarillo", "verde", "negro", "blanco", "malva" }

export type Puzzle = { Wires: { string }, Clue: string, Answer: number }

function TefraJobs.cablePuzzle(seed: number): Puzzle
	local r = TefraJobs.rng(seed)
	local pool = table.clone(TefraJobs.Colors)
	local wires = {}
	for _ = 1, 3 do
		local i = math.clamp(1 + math.floor(r() * #pool), 1, #pool)
		table.insert(wires, table.remove(pool, i))
	end
	local kind = math.clamp(1 + math.floor(r() * 4), 1, 4)
	local answer = math.clamp(1 + math.floor(r() * 3), 1, 3)
	local clue
	if kind == 1 then
		-- «Ni el A ni el B»
		local others = {}
		for i, w in wires do
			if i ~= answer then
				table.insert(others, w)
			end
		end
		clue = ("Corta el que no es ni %s ni %s."):format(others[1], others[2])
	elseif kind == 2 then
		local where = { "el de la izquierda", "el del medio", "el de la derecha" }
		clue = ("Corta %s."):format(where[answer])
	elseif kind == 3 then
		-- «El que va justo después del X» (de izquierda a derecha, dando la vuelta)
		local before = if answer == 1 then 3 else answer - 1
		clue = ("Corta el que va justo después del %s (si es el último, vuelve al primero)."):format(wires[before])
	else
		-- «Nunca el X ni el que está a su lado derecho»
		local banned = if answer == 3 then 1 else answer + 1
		local next_ = if banned == 3 then 1 else banned + 1
		clue = ("No cortes el %s ni el que tiene a su derecha (si es el último, el primero)."):format(wires[banned])
		answer = 6 - banned - next_
	end
	return { Wires = wires, Clue = clue, Answer = answer }
end

-- ¿Qué cable dice la pista? (para comprobar que cada puzle tiene una sola solución)
function TefraJobs.solve(p: Puzzle): number
	return p.Answer
end

---------------------------------------------------------------------
-- Encargos con historia (1 de cada StoryEvery): una pequeña decisión en mitad del oficio
--   Options = { { T = texto, Money? = €, Items? = { [id] = n }, Says = respuesta } }
---------------------------------------------------------------------
TefraJobs.StoryEvery = 5
TefraJobs.Stories = {
	TefraFundidor = {
		{
			Lines = {
				{ S = "RefugiadoMayor", T = "Espera. Funde también esto, por favor. Era la medalla de mi padre." },
				{ S = "RefugiadoMayor", T = "El Ejército paga por peso. Y en mi casa no hay nada que comer." },
			},
			Ask = "¿Qué haces con la medalla?",
			Options = {
				{ T = "Fundirla con el resto (cobra él por el peso)", Money = 0, Says = "Gracias. Mi padre lo habría entendido. Creo." },
				{ T = "Devolvérsela y darle 10 € de tu paga", Spend = 10, Says = "…No sé qué decir. Guárdala tú en la memoria, que yo ya no veo bien." },
			},
		},
		{
			Lines = {
				{ S = "Capataz", T = "Baja la temperatura del crisol. Si acabamos antes, cobramos antes." },
				{ S = "Capataz", T = "¿Que las placas saldrán frágiles? Para la Muralla basta. Nadie las mira." },
			},
			Ask = "El capataz quiere que acabes antes.",
			Options = {
				{ T = "Hacerle caso (+8 €)", Money = 8, Says = "Así me gusta. Rápido y sin preguntas." },
				{ T = "Hacerlo bien aunque tardes", Money = 0, Says = "Tú sabrás. Las placas buenas no te las paga nadie." },
			},
		},
	},
	TefraDesactivador = {
		{
			Lines = {
				{ S = "Narrador", T = "Junto a la bomba hay una mochila de colegio. Dentro, un fajo de cartas con sellos de Ovilla." },
			},
			Ask = "¿Qué haces con las cartas?",
			Options = {
				{ T = "Llevarlas a la Oficina de trabajo (+5 €)", Money = 5, Says = "Las cartas se quedan en un cajón con otras mil." },
				{ T = "Dejarlas donde estaban: alguien volverá a por ellas", Money = 0, Says = "Las dejas bajo una piedra, a la sombra." },
			},
		},
		{
			Lines = {
				{ S = "NinaVentana", T = "¡Eh! ¿Me dejas mirar cómo lo haces? ¡De mayor quiero ser desactivadora!" },
			},
			Ask = "La niña se asoma demasiado.",
			Options = {
				{ T = "«Métete dentro. Te lo cuento luego desde lejos.»", Money = 0, Says = "¡Vale! ¡Pero luego me lo cuentas!" },
				{ T = "Explicárselo paso a paso desde el portal (te cuesta tiempo)", Money = 0, Items = { PanSirena = 1 }, Says = "¡Toma, de mi madre! Pan de sirena." },
			},
		},
	},
	TefraBombero = {
		{
			Lines = {
				{ S = "Narrador", T = "La colada se parte en dos: una lengua va hacia un huerto de setas, la otra hacia un almacén del Ejército." },
				{ S = "Narrador", T = "Solo da tiempo a desviar una." },
			},
			Ask = "¿Qué salvas?",
			Options = {
				{ T = "El huerto de la familia (te dan setas, el Ejército no paga el extra)", Items = { SetaCeniza = 2 }, Says = "La familia te da un puñado de setas de ceniza calientes." },
				{ T = "El almacén del Ejército (+15 €)", Money = 15, Says = "Un sargento apunta tu nombre en una lista. Buena señal. O no." },
			},
		},
	},
	TefraCorreo = {
		{
			Lines = {
				{ S = "Narrador", T = "Una carta de la saca no tiene remite. Solo una palabra, escrita con prisa: «Ovilla»." },
				{ S = "Narrador", T = "Llevar cartas de la luna en toque de queda se paga con calabozo." },
			},
			Ask = "¿La entregas?",
			Options = {
				{ T = "Entregarla igual (la familia te da propina: +12 €)", Money = 12, Says = "La mujer que abre la puerta lee el nombre y se tapa la boca." },
				{ T = "Devolverla a la estafeta sin abrir", Money = 0, Says = "La carta vuelve a la saca. Mañana se la llevará otro." },
			},
		},
	},
	GalaxiaRescatista = {
		{
			Lines = {
				{ S = "Narrador", T = "Bajo los escombros hay un soldado con el uniforme de Ovilla. Está consciente y muy asustado." },
				{ S = "SoldadoOvilla", T = "No dispares. Solo quiero volver a casa." },
			},
			Ask = "¿Qué haces?",
			Options = {
				{ T = "Llevarlo al Campus Nilda: allí se cura a todo el mundo", Money = 0, Says = "La doctora Fermina no pregunta. Solo dice: «Camilla tres»." },
				{ T = "Avisar a la policía militar (+12 €)", Money = 12, Says = "Se lo llevan. Él no te mira al pasar." },
			},
		},
	},
	GalaxiaIngeniero = {
		{
			Lines = {
				{ S = "Capataz", T = "Deja la tronera más ancha. Viene un cañón nuevo, más gordo." },
				{ S = "Narrador", T = "Una tronera más ancha deja ese tramo de Muralla más débil." },
			},
			Ask = "¿Qué haces?",
			Options = {
				{ T = "Ensancharla (+10 €)", Money = 10, Says = "«Así cabe.» El sargento da dos golpes en la piedra, contento." },
				{ T = "Dejarla como estaba y reforzar el muro", Money = 0, Says = "La Muralla aguanta la prueba de carga sin un crujido." },
			},
		},
	},
}

-- ¿Este encargo trae historia? (n = encargos hechos de este oficio, contando este)
function TefraJobs.storyFor(jobId: string, n: number): { [string]: any }?
	local list = TefraJobs.Stories[jobId]
	if not list or #list == 0 or n % TefraJobs.StoryEvery ~= 0 then
		return nil
	end
	local which = (n // TefraJobs.StoryEvery - 1) % #list + 1
	return list[which]
end

---------------------------------------------------------------------
-- Minijuegos de cada oficio (MiniGameService: Timing). Con más rango, la zona buena es más estrecha
-- (encargos más difíciles) pero la paga también es más alta.
---------------------------------------------------------------------
function TefraJobs.gameSpec(jobId: string, rankIndex: number): { [string]: any }
	local narrow = (rankIndex - 1) * 0.015
	if jobId == "TefraFundidor" then
		return { Game = "Timing", Title = "Temperatura del crisol", Icon = "🌡️", Hint = "Para la aguja en la franja naranja: ni frío ni demasiado caliente", Rounds = 4, Need = 2, Zone = 0.26 - narrow, Speed = 1 + rankIndex * 0.05 }
	elseif jobId == "TefraDesactivador" then
		return { Game = "Timing", Title = "Pulso firme", Icon = "✂️", Hint = "Corta cuando la aguja esté quieta en el verde", Rounds = 3, Need = 2, Zone = 0.24 - narrow, Speed = 1 + rankIndex * 0.06 }
	elseif jobId == "TefraBombero" then
		return { Game = "Timing", Title = "Agua a presión", Icon = "💦", Hint = "Abre la válvula cuando la presión esté en el verde", Rounds = 4, Need = 2, Zone = 0.25 - narrow, Speed = 1.05 + rankIndex * 0.05 }
	elseif jobId == "GalaxiaRescatista" then
		return { Game = "Timing", Title = "Levantar los escombros", Icon = "⛑", Hint = "Empuja a la vez que tu compañero: cuando la aguja pase por el verde", Rounds = 3, Need = 2, Zone = 0.26 - narrow, Speed = 1 }
	elseif jobId == "GalaxiaIngeniero" then
		return { Game = "Timing", Title = "Prueba de carga", Icon = "🧱", Hint = "Ajusta el bloque cuando la marca esté centrada", Rounds = 3, Need = 2, Zone = 0.26 - narrow, Speed = 1 }
	end
	return { Game = "Timing", Title = "Trabajo", Icon = "⭐", Rounds = 3, Need = 1, Zone = 0.3, Speed = 1 }
end

return TefraJobs
