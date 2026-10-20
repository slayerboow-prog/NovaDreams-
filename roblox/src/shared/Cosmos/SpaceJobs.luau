-- SpaceJobs: los TRABAJOS ESPACIALES (cuentas puras; docs/universo/diseno-espacio.md §1). Los usan el
-- servidor (Services/SpaceJobService: tablón, atracar, derribos, recompensas) y las pruebas
-- (scripts/test-spacejobs.luau). El cliente no decide nada: solo elige opciones del menú con ficha.
--
--   * La carrera es UNA para toda la galaxia (docs/planetas/diseno-mundos.md §2.1): experiencia por
--     trabajo (Xp.Carga, Xp.Caza), 5 rangos con su paga (×1,0 … ×2,1) y reputación por bando.
--   * Contratos que cambian cada SlotSeconds: salen de una semilla (estación + franja), así todos los
--     servidores ofrecen los mismos y las pruebas se pueden repetir.
--   * Transportista: llevar carga de una estación a otra (tiempo mínimo, urgente con hora, frágil con
--     casco mínimo, peligrosa con rango). Si te derriban, se pierde.
--   * Cazarrecompensas: un objetivo con nombre en un sector; lo pone el servidor (planOf) y solo se cobra
--     si cae ESE enemigo, una vez.
--   * Mercenario: escoltar un convoy de cargueros de una estación a otra o defender una estación de
--     oleadas de piratas (cuentas del combate en shared/Cosmos/Mercenary). Se cobra según cuántos
--     cargueros llegan.
--   * Contra granjas y duplicados: id único por contrato (Done), MaxActive a la vez, HourCap por hora,
--     paga que baja al repetir el mismo tipo seguido, caducidad.
--
-- Estado guardado (data.Space.Jobs): { Xp, Rep, Active = { [id] = contrato }, Done = { [id] = t },
--   Log = { t… }, Last, Streak, Total }. `now` siempre es os.time() (segundos de reloj).

local Stations = require(script.Parent.Stations)
local Zone = require(script.Parent.Zone)

local SpaceJobs = {}

SpaceJobs.SlotSeconds = 600 -- el tablón cambia cada 10 min
SpaceJobs.OffersPerStation = 5
SpaceJobs.MaxActive = 3
SpaceJobs.HourCap = 12 -- contratos completados por hora como mucho
SpaceJobs.DoneKeep = 3 * 3600 -- cuánto se acuerda de los ya hechos (contra repetir el mismo)
SpaceJobs.StreakStep = 0.1 -- −10 % cada vez que repites el mismo tipo seguido
SpaceJobs.StreakFloor = 0.6
SpaceJobs.MinDeliver = 12 -- s mínimos de una entrega (despegar + cargar el salto cuántico + atracar)
SpaceJobs.DeliverSpeed = 1000 -- studs/s: más que el salto cuántico de media (rutas largas, más tiempo)
SpaceJobs.FragileHull = 0.6 -- casco mínimo (fracción) para que la carga frágil llegue entera
SpaceJobs.LatePay = 0.5
SpaceJobs.RespawnGap = 20 -- s antes de que un objetivo escapado vuelva a aparecer

SpaceJobs.Jobs = {
	Carga = { Id = "Carga", Name = "Transportista", Icon = "📦", Faction = "Gremio" },
	Caza = { Id = "Caza", Name = "Cazarrecompensas", Icon = "🎯", Faction = "Vigilancia" },
	Mercenario = { Id = "Mercenario", Name = "Mercenario", Icon = "🛡", Faction = "Liga" },
}
SpaceJobs.JobOrder = { "Carga", "Caza", "Mercenario" }

SpaceJobs.Factions = {
	Gremio = { Id = "Gremio", Name = "Gremio Libre de Cargueros" },
	Vigilancia = { Id = "Vigilancia", Name = "Vigilancia de Cénit" },
	Liga = { Id = "Liga", Name = "Liga de Estaciones" },
}
SpaceJobs.RepWin, SpaceJobs.RepFail, SpaceJobs.RepExpire = 2, -3, -1

export type Rank = { Name: string, Xp: number, Pay: number }
SpaceJobs.Ranks = {
	{ Name = "Aprendiz", Xp = 0, Pay = 1.0 },
	{ Name = "Oficial", Xp = 6, Pay = 1.2 },
	{ Name = "Veterano", Xp = 18, Pay = 1.45 },
	{ Name = "Experto", Xp = 40, Pay = 1.75 },
	{ Name = "Maestro", Xp = 80, Pay = 2.1 },
} :: { Rank }

-- Cargas (Transportista)
SpaceJobs.Cargo = {
	Suministros = { Id = "Suministros", Name = "Suministros", Pay = 260, Rank = 1, Xp = 1 },
	Medicinas = { Id = "Medicinas", Name = "Medicinas urgentes", Pay = 340, Rank = 1, Xp = 1, Urgent = 150 },
	Instrumentos = { Id = "Instrumentos", Name = "Instrumentos frágiles", Pay = 380, Rank = 1, Xp = 1, Fragile = true },
	Combustible = { Id = "Combustible", Name = "Combustible de salto", Pay = 520, Rank = 2, Xp = 2, Chispas = 1 },
}
SpaceJobs.CargoOrder = { "Suministros", "Medicinas", "Instrumentos", "Combustible" }
SpaceJobs.CargoExpire = 40 * 60

-- Recompensas (Cazarrecompensas): un nivel por sector
SpaceJobs.Bounty = {
	{ Level = 1, Sector = "Brasa", Pay = 350, Chispas = 1, Rank = 1, Escort = 0, Hull = 2.4 },
	{ Level = 2, Sector = "Ruta", Pay = 600, Chispas = 2, Rank = 2, Escort = 1, Hull = 3.0 },
	{ Level = 3, Sector = "Escarcha", Pay = 950, Chispas = 3, Rank = 3, Escort = 2, Hull = 3.8 },
}
SpaceJobs.BountyExpire = 45 * 60

-- Mercenario: escolta de convoy (nivel 1: 2 cargueros; nivel 2: 3) y defensa de estación
SpaceJobs.Merc = {
	Convoy = { { Level = 1, Pay = 420, Chispas = 1, Rank = 1, Xp = 1 }, { Level = 2, Pay = 700, Chispas = 2, Rank = 2, Xp = 2 } },
	Defensa = { { Level = 1, Pay = 450, Chispas = 1, Rank = 1, Xp = 1 }, { Level = 2, Pay = 750, Chispas = 2, Rank = 2, Xp = 2 } },
}
SpaceJobs.MercExpire = 40 * 60

local ALIAS = { "Rasca", "Tuerca", "La Polilla", "Garfio", "Sin Luces", "Mellado", "Zumbido", "Cometa Negro", "Lince", "Remiendo" }
local SURNAME = { "Ostrel", "Marrás", "Quill", "Davón", "Ébano", "Tarsi", "Vulmar", "Corzo", "Brénik", "Salitre" }
local CRIME = { "piratería en la Ruta", "robo de carga", "contrabando de cristal", "atacar una baliza", "fugarse de la Cénit", "asaltar cargueros del Gremio" }

export type Contract = {
	Id: string,
	Job: string, -- "Carga" | "Caza" | "Mercenario"
	Kind: string, -- tipo de carga, "Recompensa", "Convoy" o "Defensa"
	Title: string,
	Text: string,
	Station: string, -- dónde se coge
	To: string?, -- (carga) a qué estación
	Sector: string?, -- (recompensa) dónde se esconde
	Level: number?,
	Target: string?, -- (recompensa) nombre del objetivo
	Pay: number,
	Chispas: number,
	Rank: number, -- rango mínimo (1..5)
	Xp: number,
	MinSeconds: number?,
	Urgent: number?, -- s para llegar a tiempo (tras MinSeconds)
	Fragile: boolean?,
	Expire: number, -- s desde que se coge
	At: number?, -- (aceptado) os.time() al cogerlo
}

---------------------------------------------------------------------
-- Estado guardado
---------------------------------------------------------------------
-- Rellena lo que falte (partidas de antes); devuelve la misma tabla
function SpaceJobs.ensure(jobs: any): { [string]: any }
	local j = if type(jobs) == "table" then jobs else {}
	for _, key in { "Xp", "Rep", "Active", "Done", "Log" } do
		if type(j[key]) ~= "table" then
			j[key] = {}
		end
	end
	for id in SpaceJobs.Jobs do
		j.Xp[id] = math.max(0, math.floor(tonumber(j.Xp[id]) or 0))
	end
	for id in SpaceJobs.Factions do
		j.Rep[id] = math.clamp(math.floor(tonumber(j.Rep[id]) or 0), -100, 100)
	end
	j.Streak = math.max(0, math.floor(tonumber(j.Streak) or 0))
	j.Total = math.max(0, math.floor(tonumber(j.Total) or 0))
	if type(j.Last) ~= "string" then
		j.Last = nil
	end
	return j
end

-- Rango (1..5) con esa experiencia
function SpaceJobs.rankOf(xp: number): (number, Rank)
	local idx = 1
	for i, r in SpaceJobs.Ranks do
		if xp >= r.Xp then
			idx = i
		end
	end
	return idx, SpaceJobs.Ranks[idx]
end

-- Experiencia que falta para el siguiente rango (nil en Maestro)
function SpaceJobs.toNext(xp: number): number?
	local idx = SpaceJobs.rankOf(xp)
	local nextRank = SpaceJobs.Ranks[idx + 1]
	return if nextRank then nextRank.Xp - xp else nil
end

---------------------------------------------------------------------
-- El tablón: contratos de cada estación (semilla = estación + franja)
---------------------------------------------------------------------
local function rng(seed: number): () -> number
	local s = math.floor(seed) % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function pick<T>(list: { T }, r: () -> number): T
	return list[math.floor(r() * #list) + 1]
end

local function stationIndex(id: string): number
	for i, s in Stations.List do
		if s.Id == id then
			return i
		end
	end
	return 0
end

local function sectorById(id: string): Zone.Sector?
	for _, s in Zone.Sectors do
		if s.Id == id then
			return s
		end
	end
	return nil
end
SpaceJobs.sectorById = sectorById

-- Segundos mínimos de una entrega entre dos estaciones
function SpaceJobs.minSeconds(from: string, to: string): number
	local a, b = Stations.ById[from], Stations.ById[to]
	if not a or not b then
		return SpaceJobs.MinDeliver
	end
	return math.max(SpaceJobs.MinDeliver, math.ceil((a.Dock - b.Dock).Magnitude / SpaceJobs.DeliverSpeed))
end

function SpaceJobs.slot(now: number): number
	return math.floor(now / SpaceJobs.SlotSeconds)
end

local function cargoContract(id: string, station: string, r: () -> number): Contract?
	local others = {}
	for _, s in Stations.List do
		if s.Id ~= station then
			table.insert(others, s.Id)
		end
	end
	if #others == 0 then
		return nil
	end
	local to = pick(others, r)
	local def = SpaceJobs.Cargo[pick(SpaceJobs.CargoOrder, r)]
	local toName = Stations.ById[to].Name
	local text = ("Lleva %s a la %s sin que te derriben."):format(string.lower(def.Name), toName)
	if def.Urgent then
		text ..= " Hay hora de entrega: tarde, cobras la mitad."
	elseif def.Fragile then
		text ..= (" Atraca con el casco al %d %% o más o se rompe."):format(math.floor(SpaceJobs.FragileHull * 100))
	end
	local min = SpaceJobs.minSeconds(station, to)
	return {
		Id = id,
		Job = "Carga",
		Kind = def.Id,
		Title = ("%s → %s"):format(def.Name, toName),
		Text = text,
		Station = station,
		To = to,
		Pay = def.Pay,
		Chispas = def.Chispas or 0,
		Rank = def.Rank,
		Xp = def.Xp,
		MinSeconds = min,
		Urgent = if def.Urgent then min + def.Urgent else nil,
		Fragile = def.Fragile,
		Expire = SpaceJobs.CargoExpire,
	}
end

local function bountyContract(id: string, station: string, r: () -> number): Contract
	local b = SpaceJobs.Bounty[math.floor(r() * #SpaceJobs.Bounty) + 1]
	local sector = sectorById(b.Sector)
	local name = ("«%s» %s"):format(pick(ALIAS, r), pick(SURNAME, r))
	local sectorName = if sector then sector.Name else b.Sector
	return {
		Id = id,
		Job = "Caza",
		Kind = "Recompensa",
		Title = ("Se busca: %s"):format(name),
		Text = ("Buscado por %s. Se esconde en el %s (nivel %d)%s. Derríbalo."):format(pick(CRIME, r), sectorName, b.Level, if b.Escort > 0 then (" con %d de escolta"):format(b.Escort) else ""),
		Station = station,
		Sector = b.Sector,
		Level = b.Level,
		Target = name,
		Pay = b.Pay,
		Chispas = b.Chispas,
		Rank = b.Rank,
		Xp = b.Level,
		Expire = SpaceJobs.BountyExpire,
	}
end

local function mercContract(id: string, station: string, r: () -> number): Contract?
	local convoy = r() < 0.55
	local tier = if r() < 0.6 then 1 else 2
	local st = Stations.ById[station]
	if convoy then
		local others = {}
		for _, s in Stations.List do
			if s.Id ~= station then
				table.insert(others, s.Id)
			end
		end
		if #others == 0 then
			return nil
		end
		local to = pick(others, r)
		local def = SpaceJobs.Merc.Convoy[tier]
		local ships = if tier == 1 then 2 else 3
		return {
			Id = id,
			Job = "Mercenario",
			Kind = "Convoy",
			Title = ("Escolta: convoy a la %s"):format(Stations.ById[to].Name),
			Text = ("%d cargueros salen del muelle de la %s hacia la %s y los piratas los esperan. No te alejes: si te vas, el convoy te espera, pero no para siempre. Tienen que llegar al menos %d."):format(ships, st.Name, Stations.ById[to].Name, if tier == 1 then 1 else 2),
			Station = station,
			To = to,
			Level = tier,
			Pay = def.Pay,
			Chispas = def.Chispas,
			Rank = def.Rank,
			Xp = def.Xp,
			Expire = SpaceJobs.MercExpire,
		}
	end
	local def = SpaceJobs.Merc.Defensa[tier]
	return {
		Id = id,
		Job = "Mercenario",
		Kind = "Defensa",
		Title = ("Defensa de la %s"):format(st.Name),
		Text = ("Los piratas van a atacar la %s. Sal con la nave: al acercarte empiezan 3 oleadas por fuera de la zona segura. Que la estación aguante."):format(st.Name),
		Station = station,
		Level = tier,
		Pay = def.Pay,
		Chispas = def.Chispas,
		Rank = def.Rank,
		Xp = def.Xp,
		Expire = SpaceJobs.MercExpire,
	}
end

-- Los contratos que ofrece una estación ahora (los mismos para todos en esa franja)
function SpaceJobs.offers(station: string, now: number): { Contract }
	local idx = stationIndex(station)
	if idx == 0 then
		return {}
	end
	local slot = SpaceJobs.slot(now)
	local r = rng(slot * 7919 + idx * 104729 + 17)
	local out = {}
	-- Alba (Gremio) tira a cargas; Cénit (Vigilancia), a recompensas; las dos tienen de las dos
	local cargoFirst = idx % 2 == 1
	for i = 1, SpaceJobs.OffersPerStation do
		local id = ("C%d-%s-%d"):format(slot, station, i)
		local wantCargo = if i <= 2 then cargoFirst else not cargoFirst
		local c = if i == 5 then mercContract(id, station, r) elseif wantCargo then cargoContract(id, station, r) else bountyContract(id, station, r)
		if c then
			table.insert(out, c)
		end
	end
	return out
end

-- Un contrato de la oferta actual de esa estación por su id (nil si ya no está)
function SpaceJobs.offerById(station: string, id: string, now: number): Contract?
	for _, c in SpaceJobs.offers(station, now) do
		if c.Id == id then
			return c
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Coger un contrato
---------------------------------------------------------------------
local function trimLog(jobs: { [string]: any }, now: number)
	local keep = {}
	for _, t in jobs.Log do
		if type(t) == "number" and now - t < 3600 then
			table.insert(keep, t)
		end
	end
	jobs.Log = keep
end

function SpaceJobs.activeCount(jobs: { [string]: any }): number
	local n = 0
	for _, c in jobs.Active do
		if type(c) == "table" then
			n += 1
		end
	end
	return n
end

-- ¿Se puede coger? (motivo si no: "Unknown", "Active", "Done", "Full", "Rank", "Hour", "Station")
function SpaceJobs.canAccept(jobs: { [string]: any }, c: Contract?, station: string?, now: number): (boolean, string?)
	if not c or not SpaceJobs.Jobs[c.Job] then
		return false, "Unknown"
	end
	if jobs.Active[c.Id] then
		return false, "Active"
	end
	if jobs.Done[c.Id] then
		return false, "Done"
	end
	if c.Station ~= station then
		return false, "Station"
	end
	if SpaceJobs.activeCount(jobs) >= SpaceJobs.MaxActive then
		return false, "Full"
	end
	if SpaceJobs.rankOf(jobs.Xp[c.Job] or 0) < c.Rank then
		return false, "Rank"
	end
	trimLog(jobs, now)
	if #jobs.Log >= SpaceJobs.HourCap then
		return false, "Hour"
	end
	return true, nil
end

SpaceJobs.Why = {
	Unknown = "Ese contrato ya no está en el tablón",
	Active = "Ya lo tienes",
	Done = "Ese contrato ya está hecho",
	Station = "Ese contrato se coge en otra estación",
	Full = ("Como mucho %d contratos a la vez"):format(SpaceJobs.MaxActive),
	Rank = "Te falta rango para ese contrato",
	Hour = "Has hecho muchos contratos esta hora: descansa un poco",
}

function SpaceJobs.accept(jobs: { [string]: any }, c: Contract, station: string?, now: number): (boolean, string?)
	local ok, why = SpaceJobs.canAccept(jobs, c, station, now)
	if not ok then
		return false, why
	end
	local copy = table.clone(c)
	copy.At = now
	jobs.Active[c.Id] = copy
	return true, nil
end

---------------------------------------------------------------------
-- Cobrar, fallar, caducar
---------------------------------------------------------------------
-- Lo que se cobra (dinero, Chispas): rango × reputación × repetir lo mismo × (tarde: la mitad)
function SpaceJobs.payFor(jobs: { [string]: any }, c: Contract, late: boolean?, mult: number?): (number, number)
	local _, rank = SpaceJobs.rankOf(jobs.Xp[c.Job] or 0)
	local job = SpaceJobs.Jobs[c.Job]
	local rep = if job then jobs.Rep[job.Faction] or 0 else 0
	local repMul = 1 + math.clamp(rep, -100, 100) / 1000
	local same = if jobs.Last == c.Job .. ":" .. c.Kind then jobs.Streak else 0
	local streakMul = math.max(SpaceJobs.StreakFloor, 1 - SpaceJobs.StreakStep * same)
	local money = c.Pay * rank.Pay * repMul * streakMul * (if late then SpaceJobs.LatePay else 1) * math.clamp(mult or 1, 0, 1)
	return math.max(0, math.floor(money + 0.5)), if late then 0 else c.Chispas
end

local function addRep(jobs: { [string]: any }, c: Contract, delta: number)
	local job = SpaceJobs.Jobs[c.Job]
	if job then
		jobs.Rep[job.Faction] = math.clamp((jobs.Rep[job.Faction] or 0) + delta, -100, 100)
	end
end

-- Completa un contrato activo UNA vez: lo quita, lo apunta y sube carrera y reputación. Devuelve
-- (dinero, Chispas) o nil si no estaba activo (ya cobrado, inventado…).
function SpaceJobs.complete(jobs: { [string]: any }, id: string, now: number, late: boolean?, mult: number?): (number?, number?, Contract?)
	local c = jobs.Active[id]
	if type(c) ~= "table" or jobs.Done[id] then
		return nil, nil, nil
	end
	local money, chispas = SpaceJobs.payFor(jobs, c, late, mult)
	jobs.Active[id] = nil
	jobs.Done[id] = now
	local key = c.Job .. ":" .. c.Kind
	jobs.Streak = if jobs.Last == key then jobs.Streak + 1 else 0
	jobs.Last = key
	jobs.Xp[c.Job] = (jobs.Xp[c.Job] or 0) + (c.Xp or 1)
	jobs.Total += 1
	addRep(jobs, c, SpaceJobs.RepWin)
	trimLog(jobs, now)
	table.insert(jobs.Log, now)
	return money, chispas, c
end

-- Falla un contrato activo (se quita y baja la reputación). Devuelve el contrato o nil.
function SpaceJobs.fail(jobs: { [string]: any }, id: string, rep: number?): Contract?
	local c = jobs.Active[id]
	if type(c) ~= "table" then
		return nil
	end
	jobs.Active[id] = nil
	addRep(jobs, c, rep or SpaceJobs.RepFail)
	return c
end

-- Quita los caducados (−1 de reputación) y olvida los hechos viejos. Devuelve los caducados.
function SpaceJobs.expire(jobs: { [string]: any }, now: number): { Contract }
	local out = {}
	for id, c in table.clone(jobs.Active) do
		if type(c) ~= "table" then
			jobs.Active[id] = nil
		elseif now - (tonumber(c.At) or now) > (tonumber(c.Expire) or SpaceJobs.CargoExpire) then
			table.insert(out, SpaceJobs.fail(jobs, id, SpaceJobs.RepExpire) :: Contract)
		end
	end
	for id, t in table.clone(jobs.Done) do
		if type(t) ~= "number" or now - t > SpaceJobs.DoneKeep then
			jobs.Done[id] = nil
		end
	end
	trimLog(jobs, now)
	return out
end

---------------------------------------------------------------------
-- Sucesos
---------------------------------------------------------------------
export type DockResult = { Id: string, Contract: Contract, Result: string } -- "Done" | "Late" | "Broken" | "Early"

-- Atracar en `station`: las cargas que van ahí. hullFrac = casco de la nave (0..1) al atracar.
-- No cambia nada: dice qué toca (el servidor cobra con complete o falla con fail).
function SpaceJobs.dockResults(jobs: { [string]: any }, station: string, now: number, hullFrac: number): { DockResult }
	local out = {}
	for id, c in jobs.Active do
		if type(c) == "table" and c.Job == "Carga" and c.To == station then
			local since = now - (tonumber(c.At) or now)
			local result = "Done"
			if since < (c.MinSeconds or SpaceJobs.MinDeliver) then
				result = "Early"
			elseif c.Fragile and hullFrac < SpaceJobs.FragileHull then
				result = "Broken"
			elseif c.Urgent and since > c.Urgent then
				result = "Late"
			end
			table.insert(out, { Id = id, Contract = c, Result = result })
		end
	end
	table.sort(out, function(a, b)
		return a.Id < b.Id
	end)
	return out
end

-- Las cargas activas (se pierden si te derriban)
function SpaceJobs.cargoIds(jobs: { [string]: any }): { string }
	local out = {}
	for id, c in jobs.Active do
		if type(c) == "table" and c.Job == "Carga" then
			table.insert(out, id)
		end
	end
	table.sort(out)
	return out
end

-- Los contratos de mercenario activos
function SpaceJobs.mercIds(jobs: { [string]: any }): { string }
	local out = {}
	for id, c in jobs.Active do
		if type(c) == "table" and c.Job == "Mercenario" then
			table.insert(out, id)
		end
	end
	table.sort(out)
	return out
end

-- Las recompensas activas cuyo objetivo se esconde en ese sector
function SpaceJobs.bountiesIn(jobs: { [string]: any }, sectorId: string?): { Contract }
	local out = {}
	if not sectorId then
		return out
	end
	for _, c in jobs.Active do
		if type(c) == "table" and c.Job == "Caza" and c.Sector == sectorId then
			table.insert(out, c)
		end
	end
	table.sort(out, function(a, b)
		return a.Id < b.Id
	end)
	return out
end

-- Qué pone el servidor para una recompensa: el objetivo (un caza reforzado) y su escolta
function SpaceJobs.planOf(c: Contract): { Kind: string, Scale: { [string]: number }, Escort: number }
	local level = math.clamp(math.floor(tonumber(c.Level) or 1), 1, #SpaceJobs.Bounty)
	local b = SpaceJobs.Bounty[level]
	return {
		Kind = "Caza",
		Scale = { Hull = b.Hull, Damage = 1 + 0.1 * level, Fire = 1 + 0.05 * level, Speed = 1 + 0.03 * level, Level = level + 2 },
		Escort = b.Escort,
	}
end

---------------------------------------------------------------------
-- Para el HUD y los menús
---------------------------------------------------------------------
-- Filas de misión del HUD de la nave: { Id, Title, Progress, Target, TargetName }
function SpaceJobs.targets(jobs: { [string]: any }, now: number): { { [string]: any } }
	local out = {}
	local ids = {}
	for id, c in jobs.Active do
		if type(c) == "table" then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	for _, id in ids do
		local c = jobs.Active[id]
		if c.Job == "Carga" then
			local st = Stations.ById[c.To]
			local since = now - (tonumber(c.At) or now)
			local progress = "Entregar"
			if c.Urgent then
				local left = math.max(0, c.Urgent - since)
				progress = ("Entregar · %d:%02d"):format(left // 60, left % 60)
			end
			table.insert(out, { Id = id, Title = ("📦 %s"):format(c.Title), Progress = progress, Target = st and st.Dock, TargetName = st and st.Name })
		elseif c.Job == "Mercenario" then
			-- (sin arrancar: al muelle de salida; en marcha, lo pone SpaceJobService con el convoy de verdad)
			local st = Stations.ById[c.Station]
			table.insert(out, { Id = id, Title = ("🛡 %s"):format(c.Title), Progress = if c.Kind == "Convoy" then "Ve al muelle de salida" else "Acércate a la estación", Target = st and (if c.Kind == "Convoy" then st.Dock else st.Center), TargetName = st and st.Name })
		elseif c.Job == "Caza" then
			local sector = sectorById(c.Sector or "")
			table.insert(out, { Id = id, Title = ("🎯 %s"):format(c.Target or c.Title), Progress = ("Nivel %d"):format(c.Level or 1), Target = sector and sector.Center, TargetName = sector and sector.Name })
		end
	end
	return out
end

-- «Transportista: Oficial (7/18) · Gremio +4»
function SpaceJobs.careerText(jobs: { [string]: any }, jobId: string): string
	local job = SpaceJobs.Jobs[jobId]
	local xp = jobs.Xp[jobId] or 0
	local _, rank = SpaceJobs.rankOf(xp)
	local left = SpaceJobs.toNext(xp)
	local rep = jobs.Rep[job.Faction] or 0
	return ("%s %s: %s (%s) · %s %s%d"):format(job.Icon, job.Name, rank.Name, if left then ("%d/%d"):format(xp, xp + left) else "máximo", SpaceJobs.Factions[job.Faction].Name, if rep >= 0 then "+" else "", rep)
end

return SpaceJobs
