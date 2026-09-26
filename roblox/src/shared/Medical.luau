-- Medical: las consultas del hospital (oficio de médico/a, MedicalService).
--
-- El médico explora al paciente (cada prueba da un resultado), elige el diagnóstico entre varias
-- opciones, coge la medicina del botiquín y aplica el tratamiento.

local Medical = {}

Medical.Exams = {
	{ Id = "Temperatura", Name = "Tomar la temperatura", Icon = "🌡️" },
	{ Id = "Auscultar", Name = "Auscultar", Icon = "🩺" },
	{ Id = "Garganta", Name = "Mirar la garganta", Icon = "👄" },
	{ Id = "Tension", Name = "Tomar la tensión", Icon = "💓" },
	{ Id = "Palpar", Name = "Explorar (palpar)", Icon = "✋" },
}

Medical.Medicines = {
	{ Id = "Paracetamol", Name = "Paracetamol", Icon = "💊" },
	{ Id = "Jarabe", Name = "Jarabe para la tos y los mocos", Icon = "🧴" },
	{ Id = "Antibiotico", Name = "Antibiótico", Icon = "💊" },
	{ Id = "Suero", Name = "Suero oral", Icon = "🥤" },
	{ Id = "Venda", Name = "Venda y hielo", Icon = "🩹" },
	{ Id = "Antihistaminico", Name = "Antihistamínico", Icon = "🌼" },
	{ Id = "Tension", Name = "Pastillas para la tensión", Icon = "💓" },
	{ Id = "Inhalador", Name = "Inhalador", Icon = "💨" },
}

local NORMAL = {
	Temperatura = "36,6 ºC: normal",
	Auscultar = "Pulmones limpios, corazón normal",
	Garganta = "Normal",
	Tension = "120/80: normal",
	Palpar = "Nada raro",
}

local function ailment(id: string, name: string, says: { string }, medicine: string, findings: { [string]: string })
	local results = table.clone(NORMAL)
	for k, v in findings do
		results[k] = v
	end
	return { Id = id, Name = name, Says = says, Medicine = medicine, Results = results }
end

Medical.Ailments = {
	ailment("Gripe", "Gripe", { "Me duele todo el cuerpo y estoy ardiendo.", "Desde ayer tengo escalofríos y no me tengo en pie." }, "Paracetamol", {
		Temperatura = "39,2 ºC: fiebre alta",
		Auscultar = "Algo de mucosidad, nada grave",
		Garganta = "Un poco roja",
		Palpar = "Dolor muscular por todo el cuerpo",
	}),
	ailment("Resfriado", "Resfriado común", { "Tengo mocos y no paro de estornudar.", "Estoy muy congestionado, no respiro por la nariz." }, "Jarabe", {
		Temperatura = "37,1 ºC: casi normal",
		Garganta = "Algo irritada",
	}),
	ailment("Faringitis", "Faringitis", { "Me duele muchísimo al tragar.", "Tengo la garganta fatal, no puedo ni beber agua." }, "Antibiotico", {
		Temperatura = "38,4 ºC: fiebre",
		Garganta = "Muy roja, con placas blancas",
		Palpar = "Ganglios del cuello inflamados",
	}),
	ailment("Gastroenteritis", "Gastroenteritis", { "Llevo dos días con el estómago fatal.", "Todo lo que como me sienta mal." }, "Suero", {
		Temperatura = "37,8 ºC: febrícula",
		Tension = "100/60: un poco baja",
		Palpar = "Tripa sensible, con ruidos",
	}),
	ailment("Esguince", "Esguince de tobillo", { "Me torcí el tobillo jugando al fútbol.", "Pisé mal bajando la escalera y ahora no puedo apoyar el pie." }, "Venda", {
		Palpar = "Tobillo hinchado, duele al moverlo",
	}),
	ailment("Alergia", "Alergia", { "Me pica todo y tengo los ojos llorosos.", "Me han salido ronchas después de comer marisco." }, "Antihistaminico", {
		Auscultar = "Algún pitido muy leve",
		Palpar = "Ronchas rojas en brazos y cuello",
	}),
	ailment("Hipertension", "Tensión alta", { "Me duele mucho la cabeza y me mareo.", "Noto el corazón como si me fuera a saltar." }, "Tension", {
		Tension = "170/100: muy alta",
	}),
	ailment("Bronquitis", "Bronquitis", { "No paro de toser, sobre todo por la noche.", "Me cuesta respirar cuando subo escaleras." }, "Inhalador", {
		Temperatura = "38,0 ºC: fiebre",
		Auscultar = "Pitidos y ruidos en los pulmones",
		Garganta = "Algo roja",
	}),
}

Medical.byId = {}
for _, a in Medical.Ailments do
	Medical.byId[a.Id] = a
end
Medical.medicineById = {}
for _, m in Medical.Medicines do
	Medical.medicineById[m.Id] = m
end

Medical.Job = {
	Name = "Médico/a",
	Icon = "🩺",
	PerPatient = 15, -- por cada paciente atendido
	RightDiagnosis = 15, -- extra si el diagnóstico es correcto
	DegreeMultiplier = 1.5, -- con el título de Medicina se cobra más
	EnergyCost = 3,
	MinStage = "AdultoJoven",
}
Medical.MaxWaiting = 4 -- pacientes NPC esperando a la vez
Medical.QuickVisitPrice = 5 -- consulta rápida con el médico NPC (si no hay médico jugador)

return Medical
