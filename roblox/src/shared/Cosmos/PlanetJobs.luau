-- PlanetJobs: los OFICIOS de los planetas hechos con DATOS (marco común, docs/planetas/marco-planetas.md;
-- diseño: docs/planetas/diseno-mundos.md §2.1). Cuentas puras: los usan Services/PlanetJobService (lleva
-- cada turno), World/PlanetCityBuilder (pone el tablón «Trabajar») y las pruebas.
--
-- Mismas reglas que los oficios de Tefra (shared/Cosmos/TefraJobs, que van a mano): 5 rangos de la
-- galaxia (Aprendiz → Maestro, ×1 … ×2,1), puntos en data.Careers[IdDelOficio] (+ Local[planeta]),
-- tiempo mínimo por encargo, tope por hora, la paga baja si repites mucho, y Chispas con tope por hora.
--
-- Un oficio:
--   {
--     Id = "MiasmaFiltrador", Planet = "Miasma", Name, Icon, Desc, Pay (€ base, rango 1), MinSeconds,
--     Board = { lx, lz }, BoardFace = { dx, dz } (hacia dónde mira el tablón), PayText, Place,
--     EnergyCost, Drop = { Item, Chance }?, Chispas?, Hazard = número? (lo que sube el medidor del
--     planeta mientras trabajas: un filtro sucio, el sol de las Gradas…),
--     task = function(r, rankIndex, job) → { fases }   un encargo: la lista de fases, en orden
--   }
--   Fases:  { Kind = "Go", At = { lx, lz }, Text, Carry = Color3? }   ir a un sitio (llevando algo)
--           { Kind = "Game", Spec = { Game = "Timing", Title, Icon, Hint, Rounds, Need, Zone, Speed } }
--           { Kind = "Hold", Seconds, Text }                        quedarse un rato junto al sitio
-- PlanetJobs.register(jobs) apunta los oficios y su entrada en Config.Jobs (lo que enseña el tablón).

local TefraJobs = require(script.Parent.TefraJobs)

local PlanetJobs = {}

PlanetJobs.Ranks = TefraJobs.Ranks -- (la carrera es una sola en toda la galaxia)
PlanetJobs.rankFor = TefraJobs.rankFor
PlanetJobs.rng = TefraJobs.rng
PlanetJobs.pick = TefraJobs.pick
PlanetJobs.streakFactor = TefraJobs.streakFactor
PlanetJobs.points = TefraJobs.points
PlanetJobs.MaxPerHour = TefraJobs.MaxPerHour
PlanetJobs.ChispasPerHour = 10

PlanetJobs.Jobs = {} :: { [string]: { [string]: any } }
PlanetJobs.Order = {} :: { string }

local function config(): any
	local ok, Config = pcall(function()
		return require(script.Parent.Parent.Config)
	end)
	return if ok then Config else nil
end

-- Apunta los oficios de un planeta (y lo que enseña su tablón en Config.Jobs)
function PlanetJobs.register(jobs: { { [string]: any } })
	local Config = config()
	for _, job in jobs do
		if not PlanetJobs.Jobs[job.Id] then
			table.insert(PlanetJobs.Order, job.Id)
		end
		PlanetJobs.Jobs[job.Id] = job
		if Config and type(Config.Jobs) == "table" and Config.Jobs[job.Id] == nil then
			Config.Jobs[job.Id] = {
				DisplayName = ("%s (%s)"):format(job.Name, job.PlanetName or job.Planet),
				PayText = job.PayText or ("desde %d € por encargo"):format(job.Pay),
				Place = job.Place or job.Planet,
				Pay = job.Pay,
				EnergyCost = job.EnergyCost or 3,
				PickupText = "",
				DropoffText = "",
				CarryColor = job.CarryColor or Color3.fromRGB(150, 150, 150),
				CarrySize = job.CarrySize or Vector3.new(1.4, 1.2, 1.2),
			}
		end
	end
end

function PlanetJobs.isPlanetJob(id: any): boolean
	return type(id) == "string" and PlanetJobs.Jobs[id] ~= nil
end

function PlanetJobs.of(planet: string): { { [string]: any } }
	local out = {}
	for _, id in PlanetJobs.Order do
		local job = PlanetJobs.Jobs[id]
		if job.Planet == planet then
			table.insert(out, job)
		end
	end
	return out
end

function PlanetJobs.pay(jobId: string, points: number, score: number, streak: number, extra: number?): number
	local job = PlanetJobs.Jobs[jobId]
	if not job then
		return 0
	end
	local _, rank = PlanetJobs.rankFor(points)
	local quality = 0.6 + 0.4 * math.clamp(score, 0, 1)
	return math.floor(job.Pay * rank.Mult * quality * PlanetJobs.streakFactor(streak) * (extra or 1) + 0.5)
end

function PlanetJobs.allowed(jobId: string, history: { number }, started: number, now: number): (boolean, string?)
	local job = PlanetJobs.Jobs[jobId]
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
	if count >= PlanetJobs.MaxPerHour then
		return false, "Ya has hecho muchos encargos de este oficio en la última hora: descansa o prueba otro"
	end
	return true, nil
end

-- Un encargo (lista de fases), repetible con la semilla
function PlanetJobs.task(jobId: string, seed: number, rankIndex: number): { { [string]: any } }
	local job = PlanetJobs.Jobs[jobId]
	if not job or not job.task then
		return {}
	end
	return job.task(PlanetJobs.rng(seed), rankIndex, job)
end

-- La zona buena del minijuego se estrecha con el rango (encargos más difíciles, mejor paga)
function PlanetJobs.timing(title: string, icon: string, hint: string, rankIndex: number, extra: { [string]: any }?): { [string]: any }
	local spec = { Game = "Timing", Title = title, Icon = icon, Hint = hint, Rounds = 3, Need = 2, Zone = 0.26 - (rankIndex - 1) * 0.015, Speed = 1 + rankIndex * 0.05 }
	for k, v in extra or {} do
		spec[k] = v
	end
	return spec
end

return PlanetJobs
