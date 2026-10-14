-- Institutions: los cuerpos e instituciones del Estado en los que se puede hacer carrera.
--
-- Cada institución tiene un oficio (JobId del tablón "Trabajar"), una escala de rangos y un jefe.
-- Se sube de rango con puntos de servicio (tareas, casos, detenciones…); cada rango cobra más.
-- El rango más alto (Comisario/a Jefe, Presidente/a del Tribunal, Director/a de la prisión,
-- General, Delegado/a de Hacienda) tiene poderes especiales en su institución.
--
-- Lo usan CareerService (servidor) y la interfaz (rango en tu ficha, avisos de ascenso).

local Institutions = {}

export type Rank = { Id: string, Name: string, Points: number, Bonus: number }
export type Institution = {
	Id: string,
	Name: string,
	Short: string,
	Icon: string,
	JobId: string,
	MinStage: string,
	Color: Color3,
	Ranks: { Rank },
	Chief: string, -- nombre del cargo de jefe (el rango más alto)
	Points: { [string]: number }, -- puntos de servicio por cada cosa que se hace
}

local rgb = Color3.fromRGB

local function ranks(list: { { any } }): { Rank }
	local out = {}
	for i, r in list do
		table.insert(out, { Id = r[1], Name = r[2], Points = r[3], Bonus = r[4] or (i - 1) * 0.15 })
	end
	return out
end

Institutions.List = {
	Policia = {
		Id = "Policia",
		Name = "Cuerpo de Policía de Valmar",
		Short = "Policía",
		Icon = "🚓",
		JobId = "Policia",
		MinStage = "AdultoJoven",
		Color = rgb(28, 60, 150),
		Ranks = ranks({
			{ "Agente", "Agente", 0 },
			{ "Oficial", "Oficial", 30 },
			{ "Subinspector", "Subinspector/a", 90 },
			{ "Inspector", "Inspector/a", 200 },
			{ "Comisario", "Comisario/a Jefe", 380 },
		}),
		Chief = "Comisario/a Jefe",
		Points = { Task = 3, Arrest = 8 },
	},
	Justicia = {
		Id = "Justicia",
		Name = "Juzgados de Valmar",
		Short = "Justicia",
		Icon = "⚖️",
		JobId = "Juez",
		MinStage = "Adulto",
		Color = rgb(90, 30, 40),
		Ranks = ranks({
			{ "Juez", "Juez/a", 0 },
			{ "Magistrado", "Magistrado/a", 40 },
			{ "MagistradoSuperior", "Magistrado/a del Tribunal Superior", 120 },
			{ "Presidente", "Presidente/a del Tribunal", 260 },
		}),
		Chief = "Presidente/a del Tribunal",
		Points = { Task = 2, Case = 8 },
	},
	Prisiones = {
		Id = "Prisiones",
		Name = "Instituciones Penitenciarias",
		Short = "Prisión",
		Icon = "⛓",
		JobId = "Funcionario",
		MinStage = "AdultoJoven",
		Color = rgb(70, 80, 70),
		Ranks = ranks({
			{ "Funcionario", "Funcionario/a de prisiones", 0 },
			{ "JefeServicio", "Jefe/a de servicio", 40 },
			{ "Subdirector", "Subdirector/a", 120 },
			{ "Director", "Director/a de la prisión", 240 },
		}),
		Chief = "Director/a de la prisión",
		Points = { Task = 3, Inmate = 4 },
	},
	Ejercito = {
		Id = "Ejercito",
		Name = "Ejército de Valmar",
		Short = "Ejército",
		Icon = "🎖",
		JobId = "Militar",
		MinStage = "AdultoJoven",
		Color = rgb(70, 90, 50),
		Ranks = ranks({
			{ "Soldado", "Soldado", 0 },
			{ "Cabo", "Cabo", 20 },
			{ "Sargento", "Sargento", 60 },
			{ "Teniente", "Teniente", 120 },
			{ "Capitan", "Capitán/a", 200 },
			{ "Comandante", "Comandante", 300 },
			{ "Coronel", "Coronel", 420 },
			{ "General", "General", 600 },
		}),
		Chief = "General",
		Points = { Task = 3 },
	},
	Hacienda = {
		Id = "Hacienda",
		Name = "Agencia Tributaria de Valmar",
		Short = "Hacienda",
		Icon = "🏛",
		JobId = "Hacienda",
		MinStage = "AdultoJoven",
		Color = rgb(30, 90, 110),
		Ranks = ranks({
			{ "Agente", "Agente tributario/a", 0 },
			{ "Tecnico", "Técnico/a de Hacienda", 40 },
			{ "Inspector", "Inspector/a de Hacienda", 120 },
			{ "Delegado", "Delegado/a de Hacienda", 250 },
		}),
		Chief = "Delegado/a de Hacienda",
		Points = { Task = 2, Declaration = 5, Inspection = 8 },
	},
}

-- La institución de un oficio (nil si el oficio no es de ninguna)
function Institutions.byJob(jobId: string?): Institution?
	for _, inst in Institutions.List do
		if inst.JobId == jobId then
			return inst
		end
	end
	return nil
end

-- Rango (índice y datos) que corresponde a unos puntos de servicio
function Institutions.rankFor(inst: Institution, points: number): (number, Rank)
	local index = 1
	for i, rank in inst.Ranks do
		if points >= rank.Points then
			index = i
		end
	end
	return index, inst.Ranks[index]
end

-- Puntos que faltan para el siguiente rango (nil si ya es el más alto)
function Institutions.toNext(inst: Institution, points: number): number?
	local index = Institutions.rankFor(inst, points)
	local nextRank = inst.Ranks[index + 1]
	return if nextRank then nextRank.Points - points else nil
end

-- ¿Es el rango más alto (el jefe)?
function Institutions.isTop(inst: Institution, points: number): boolean
	return Institutions.rankFor(inst, points) == #inst.Ranks
end

-- Sueldo con el plus del rango
function Institutions.pay(inst: Institution, points: number, base: number): number
	local _, rank = Institutions.rankFor(inst, points)
	return math.floor(base * (1 + rank.Bonus) + 0.5)
end

return Institutions
