-- Subjects: asignaturas y carreras que se juegan en clase (colegio, instituto, universidad).
--
--   Subjects[id] = {
--     NameKey    nombre visible
--     Teacher    NPC que da la clase si no hay un profesor jugador de servicio (RoleService)
--     Generator  (opcional) las preguntas se crean con código: Aritmetica, Algebra, Calculo, Contabilidad
--     Circuit    (opcional) la clase es física: recorrer puntos de la pista a tiempo (Educación Física)
--   }
--   Las preguntas escritas a mano están en QuestionBank.luau (misma clave que la asignatura).
--
--   Degrees[id] = carrera universitaria: su facultad, sus asignaturas, dónde se hacen las prácticas
--   y el título que se consigue. Las misiones de la universidad usan "$Carrera.Asignatura1",
--   "$Carrera.Facultad"… y se resuelven con la carrera que eligió el jugador.

local Subjects = {}

export type Subject = { NameKey: string, Teacher: string, Generator: string?, Circuit: boolean? }

Subjects.List = {
	-- Primaria (Colegio)
	Matematicas = { NameKey = "SUBJECT.MATEMATICAS", Teacher = "NPC.PROFE_LUCIA", Generator = "Aritmetica" },
	Lengua = { NameKey = "SUBJECT.LENGUA", Teacher = "NPC.PROFE_LUCIA" },
	Ciencias = { NameKey = "SUBJECT.CIENCIAS", Teacher = "NPC.PROFE_LUCIA" },
	Musica = { NameKey = "SUBJECT.MUSICA", Teacher = "NPC.PROFE_MUSICA" },
	Arte = { NameKey = "SUBJECT.ARTE", Teacher = "NPC.PROFE_LUCIA" },
	Historia = { NameKey = "SUBJECT.HISTORIA", Teacher = "NPC.PROFE_LUCIA" },
	EducacionFisica = { NameKey = "SUBJECT.EDUCACION_FISICA", Teacher = "NPC.PROFE_DEPORTE", Circuit = true },

	-- Instituto
	MatematicasInstituto = { NameKey = "SUBJECT.MATEMATICAS", Teacher = "NPC.PROFE_INSTITUTO", Generator = "Algebra" },
	HistoriaInstituto = { NameKey = "SUBJECT.HISTORIA", Teacher = "NPC.PROFE_INSTITUTO" },
	Tecnologia = { NameKey = "SUBJECT.TECNOLOGIA", Teacher = "NPC.PROFE_INSTITUTO" },

	-- Universidad
	Anatomia = { NameKey = "SUBJECT.ANATOMIA", Teacher = "NPC.PROFE_MEDICINA" },
	Fisiologia = { NameKey = "SUBJECT.FISIOLOGIA", Teacher = "NPC.PROFE_MEDICINA" },
	Fisica = { NameKey = "SUBJECT.FISICA", Teacher = "NPC.PROFE_INGENIERIA" },
	Calculo = { NameKey = "SUBJECT.CALCULO", Teacher = "NPC.PROFE_INGENIERIA", Generator = "Calculo" },
	DerechoCivil = { NameKey = "SUBJECT.DERECHO_CIVIL", Teacher = "NPC.PROFE_DERECHO" },
	DerechoLaboral = { NameKey = "SUBJECT.DERECHO_LABORAL", Teacher = "NPC.PROFE_DERECHO" },
	Microeconomia = { NameKey = "SUBJECT.MICROECONOMIA", Teacher = "NPC.PROFE_ECONOMIA" },
	Contabilidad = { NameKey = "SUBJECT.CONTABILIDAD", Teacher = "NPC.PROFE_ECONOMIA", Generator = "Contabilidad" },

	-- Prácticas (casos de la profesión)
	PracticaMedicina = { NameKey = "SUBJECT.PRACTICA_MEDICINA", Teacher = "NPC.DR_BRAVO" },
	PracticaIngenieria = { NameKey = "SUBJECT.PRACTICA_INGENIERIA", Teacher = "NPC.TUTOR_TECNOVAL" },
	PracticaDerecho = { NameKey = "SUBJECT.PRACTICA_DERECHO", Teacher = "NPC.TUTOR_BUFETE" },
	PracticaEconomia = { NameKey = "SUBJECT.PRACTICA_ECONOMIA", Teacher = "NPC.TUTOR_BANCO" },
} :: { [string]: Subject }

Subjects.Degrees = {
	Medicina = {
		NameKey = "DEGREE.MEDICINA",
		Facultad = "FacultadMedicina",
		Asignatura1 = "Anatomia",
		Asignatura2 = "Fisiologia",
		Practica = "PracticaMedicina",
		LugarPracticas = "Hospital",
		Titulo = "Grado_Medicina",
	},
	Ingenieria = {
		NameKey = "DEGREE.INGENIERIA",
		Facultad = "FacultadIngenieria",
		Asignatura1 = "Fisica",
		Asignatura2 = "Calculo",
		Practica = "PracticaIngenieria",
		LugarPracticas = "OficinasFinanciero",
		Titulo = "Grado_Ingenieria",
	},
	Derecho = {
		NameKey = "DEGREE.DERECHO",
		Facultad = "FacultadDerecho",
		Asignatura1 = "DerechoCivil",
		Asignatura2 = "DerechoLaboral",
		Practica = "PracticaDerecho",
		LugarPracticas = "OficinasFinanciero",
		Titulo = "Grado_Derecho",
	},
	Economia = {
		NameKey = "DEGREE.ECONOMIA",
		Facultad = "FacultadEconomia",
		Asignatura1 = "Microeconomia",
		Asignatura2 = "Contabilidad",
		Practica = "PracticaEconomia",
		LugarPracticas = "Banco",
		Titulo = "Grado_Economia",
	},
} :: { [string]: { [string]: string } }

-- Cómo se juega cada tipo de sesión
Subjects.Modes = {
	Clase = { NameKey = "CLASS.MODE.CLASE", Questions = 8, Seconds = 14 },
	Estudio = { NameKey = "CLASS.MODE.ESTUDIO", Questions = 6, Seconds = 16 },
	Examen = { NameKey = "CLASS.MODE.EXAMEN", Questions = 10, Seconds = 14 },
	Practica = { NameKey = "CLASS.MODE.PRACTICA", Questions = 6, Seconds = 18 },
	Circuito = { NameKey = "CLASS.MODE.CIRCUITO", Points = 6, Seconds = 75 },
} :: { [string]: { [string]: any } }

-- "$Carrera.Asignatura1" -> "Anatomia" (según la carrera elegida). Devuelve el valor tal cual si no es una referencia.
function Subjects.resolve(value: any, degreeId: string?): any
	if type(value) ~= "string" or value:sub(1, 9) ~= "$Carrera." then
		return value
	end
	local degree = degreeId and Subjects.Degrees[degreeId]
	return degree and degree[value:sub(10)]
end

-- Nota de 0 a 10 -> texto ("Sobresaliente", "Notable"…)
function Subjects.gradeKey(grade: number): string
	if grade >= 9 then
		return "GRADE.SOBRESALIENTE"
	elseif grade >= 7 then
		return "GRADE.NOTABLE"
	elseif grade >= 6 then
		return "GRADE.BIEN"
	elseif grade >= 5 then
		return "GRADE.SUFICIENTE"
	end
	return "GRADE.INSUFICIENTE"
end

return Subjects
