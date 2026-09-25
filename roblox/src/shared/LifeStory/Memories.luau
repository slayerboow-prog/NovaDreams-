-- Memories: los grandes recuerdos de la vida del personaje. Las misiones los crean (Effects.Memory),
-- los NPC los citan ("¿Te acuerdas del partido?", condición Memories = { "PrimerPartido" }) y la
-- biografía y los flashbacks del último día de colegio los enseñan con este texto.

export type Memory = { Text: string, Icon: string }

local Memories: { [string]: Memory } = {
	PrimerDiaCole = { Text = "Tu primer día de colegio", Icon = "🏫" },
	PrimerAmigo = { Text = "Ayudaste a Mateo a recoger sus libros: tu primer amigo", Icon = "🤝" },
	SegundaOportunidad = { Text = "Te sentaste con Mateo cuando comía solo", Icon = "🥪" },
	MochilaPerdida = { Text = "El día que desapareció tu mochila", Icon = "🎒" },
	PrimerGrupo = { Text = "Cómo conociste a tu grupo de amigos", Icon = "👫" },
	PrimerPartido = { Text = "Tu primer partido de fútbol en el colegio", Icon = "⚽" },
	TardeEnElParque = { Text = "La tarde en el parque con tu grupo", Icon = "🌳" },
	SuenoDeMayor = { Text = "Lo que querías ser de mayor", Icon = "✨" },
	GatoDelCole = { Text = "Bigotes, el gato del colegio", Icon = "🐈" },
	ReencuentroRuben = { Text = "Cuando Rubén volvió a aparecer", Icon = "🔁" },
	LosMalotes = { Text = "La persecución por el colegio y lo que te contó Hugo", Icon = "🏃" },
	HugoAmigo = { Text = "Cuando Hugo dejó a Bruno y se vino con vosotros", Icon = "🏴‍☠️" },
	Detective = { Text = "Descubriste quién hacía las bromas del colegio", Icon = "🔍" },
	PrimerExamen = { Text = "Tu primer examen de verdad", Icon = "📝" },
	CasiSuspendo = { Text = "Aquel examen que casi suspendes (y cómo lo arreglaste)", Icon = "📚" },
	PrimeraExcursion = { Text = "La excursión a la granja de Villaverde", Icon = "🚌" },
	PrimerTorneo = { Text = "El torneo del colegio", Icon = "🏆" },
	MisterioColegio = { Text = "El misterio de la sala cerrada y la foto de Lucía", Icon = "🗝️" },
	ElFestival = { Text = "El festival de primavera del colegio", Icon = "🎉" },
	ProyectoFinal = { Text = "El proyecto final de Ciencias, delante de las familias", Icon = "🔬" },
	UltimoDiaCole = { Text = "Tu último día de primaria", Icon = "🎓" },
	PrimerDiaInstituto = { Text = "Tu primer día de instituto (y el «ascensor de alumnos»)", Icon = "🏢" },
	PrimerClub = { Text = "Cuando te apuntaste a tu primer club", Icon = "📌" },
	QueQuieresSer = { Text = "La semana de las profesiones", Icon = "🧭" },
	PrimerSueldo = { Text = "Tu primer trabajo de verano y tu primer sueldo", Icon = "💶" },
	ElRumor = { Text = "La foto de Omar, y cómo lo arreglasteis", Icon = "📱" },
	LaGranDecision = { Text = "La noche en que decidiste tu futuro", Icon = "🎓" },
	PrimerDiaUni = { Text = "Tu primer día en el campus (y el reloj de tu abuelo o abuela)", Icon = "🏛️" },
	ElProyectoUni = { Text = "El proyecto del grupo cuatro", Icon = "👥" },
	PrimerTrabajoUni = { Text = "Tu primer trabajo mientras estudiabas", Icon = "💼" },
}

return Memories
