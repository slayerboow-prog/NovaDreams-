-- GUION REESCRITO de Ins06_LaGranDecision (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Ins06_LaGranDecision.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Ins06_LaGranDecision
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Ins06_LaGranDecision.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Ins06_LaGranDecision.md",
	Dialogues = {
		Carmen = {
			Lines = {
				{ S = "Carmen", T = "¿Te acuerdas de la semana de las profesiones?", To = "Yo" },
				{ S = "Carmen", T = "Tengo tu cuaderno aquí.", To = "Yo" },
				{ S = "Carmen", T = "Último curso. Vamos a ver qué te ronda la cabeza.", To = "Yo", If = { NotMemories = { "QueQuieresSer" } } },
				{ S = "Carmen", T = "En primero saliste de mi despacho con más dudas que antes.", To = "Yo", If = { Choices = { Orientacion = "Dudas" } } },
				{ S = "Carmen", T = "Te dije que era buena señal.", To = "Yo", Pause = 0.9, If = { Choices = { Orientacion = "Dudas" } } },
				{ S = "Carmen", T = "Te vi con la doctora Nuria.", To = "Yo", If = { Flags = { "Interes_Medicina" } } },
				{ S = "Carmen", T = "Dijiste que te veías en un hospital.", To = "Yo", If = { Flags = { "Interes_Medicina" } } },
				{ S = "Carmen", T = "Sofía todavía habla de tu puente de palillos.", To = "Yo", If = { Flags = { "Interes_Ingenieria" } } },
				{ S = "Carmen", T = "Eso es ingeniería pura.", To = "Yo", If = { Flags = { "Interes_Ingenieria" } } },
				{
					S = "Carmen",
					T = "Inés dijo que escuchabas a las dos partes. Eso es derecho. O policía. O mediación.",
					To = "Yo",
					If = { Flags = { "Interes_Derecho" } },
				},
				{
					S = "Carmen",
					T = "Marcos todavía habla de tu idea de las bicicletas. Economía, empresa… Lo llevas dentro.",
					To = "Yo",
					If = { Flags = { "Interes_Economia" } },
				},
				{ S = "Carmen", T = "Tobías, Lola, Irene, Toni…", To = "Yo", If = { Flags = { "Interes_Oficio" } } },
				{
					S = "Carmen",
					T = "Hay profesiones que se aprenden trabajando. No son menos. Son otro camino.",
					To = "Yo",
					Pause = 0.9,
					If = { Flags = { "Interes_Oficio" } },
				},
				{ S = "Carmen", T = "Y tu primer trabajo de verano.", To = "Yo", If = { Memories = { "PrimerSueldo" } } },
				{ S = "Carmen", T = "Eso también dice mucho de ti.", To = "Yo", Pause = 0.9, If = { Memories = { "PrimerSueldo" } } },
				{ S = "Carmen", T = "Sé lo del estadio. Y lo de Rayo.", To = "Yo", If = { Flags = { "Camino_Delincuente" } } },
				{ S = "Carmen", T = "No te voy a sermonear.", To = "Yo", If = { Flags = { "Camino_Delincuente" } } },
				{ S = "Carmen", T = "Solo te digo una cosa.", To = "Yo", Pause = 0.9, If = { Flags = { "Camino_Delincuente" } } },
				{ S = "Carmen", T = "Todavía puedes elegir otro camino. Siempre se puede.", To = "Yo" },
				{ S = "Carmen", T = "Y sé que saliste de algo difícil hace unos años.", To = "Yo", If = { Flags = { "Redimido" } } },
				{ S = "Carmen", T = "Eso dice más de ti que cualquier nota.", To = "Yo", Pause = 0.9, If = { Flags = { "Redimido" } } },
				{ S = "Carmen", T = "Pero voy a decirte lo mismo que hace años.", To = "Yo" },
				{ S = "Carmen", T = "No tienes que acertar. Tienes que elegir. Y si te equivocas… Se cambia.", To = "Yo", Pause = 0.9 },
				{ S = "Carmen", T = "Nadie se queda donde empieza. Ni siquiera yo.", To = "Yo" },
				{ S = "Carmen", T = "Empecé estudiando química. Mírame.", To = "Yo" },
			},
		},
		Decidido = {
			Lines = {
				{ S = "Familia", T = "¿A la universidad? Y a vivir en la residencia.", To = "Yo", If = { Choices = { Futuro = "Universidad" } } },
				{ S = "Familia", T = "Te voy a echar de menos.", To = "Yo", If = { Choices = { Futuro = "Universidad" } } },
				{ S = "Familia", T = "Y a tu ropa sucia, no tanto.", To = "Yo", Pause = 0.9, If = { Choices = { Futuro = "Universidad" } } },
				{ S = "Familia", T = "Allí tendrás que hacerte la compra. La comida. La cama. Todo.", To = "Yo" },
				{ S = "Familia", T = "Mañana te enseño a hacer una tortilla. Por si acaso. Por si acaso, dos.", To = "Yo" },
				{ S = "Familia", T = "Con tu nota puedes elegir cualquier carrera. Cualquiera.", To = "Yo", If = { Choices = { Futuro = "Universidad" } } },
				{ S = "Familia", T = "Piénsalo bien antes de matricularte.", To = "Yo", If = { Choices = { Futuro = "Universidad" } } },
				{ S = "Familia", T = "¿Trabajar ya? Es una decisión valiente.", To = "Yo" },
				{ S = "Familia", T = "Y si algún día quieres estudiar…", To = "Yo", Pause = 0.9 },
				{ S = "Familia", T = "Siempre estás a tiempo.", To = "Yo" },
				{
					S = "Familia",
					T = "Y quien te contrató aquel verano siempre dice que eres de fiar. Algo de eso habrá.",
					To = "Yo",
					If = { Flags = { "EmpiezaATrabajar" } },
				},
				{ S = "Abu", T = "Sea lo que sea… Lo has elegido tú.", To = "Yo" },
				{ S = "Abu", T = "Eso es lo que importa.", To = "Yo" },
			},
		},
		Nervios = {
			Lines = {
				{ S = "Omar", T = "Me lo he aprendido todo.", To = "Yo" },
				{ S = "Omar", T = "Y lo he olvidado todo en el pasillo. ¿Es normal?", To = "Yo", Pause = 0.9 },
				{ S = "Javier", T = "Es normal. Respirad. Nadie es su nota.", To = "Yo" },
				{ S = "Javier", T = "Pero hoy, por si acaso… Haced buena letra.", To = "Yo", Pause = 0.9 },
			},
		},
		Plan_Bruno = {
			Lines = {
				{ S = "Bruno", T = "¿Yo? Policía. No te rías.", To = "Yo" },
				{ S = "Bruno", T = "Inés dice que se me da bien conseguir que la gente me haga caso.", To = "Yo" },
				{ S = "Bruno", T = "Y que ahora sé cuándo usarlo. Y cuándo no.", To = "Yo", Pause = 0.9 },
				{ S = "Bruno", T = "Eso lo aprendí con vosotros.", To = "Yo" },
				{ S = "Bruno", T = "No se lo digas a nadie.", To = "Yo", Pause = 0.9 },
				{
					S = "Bruno",
					T = "Me creíste cuando todos decían que la foto era mía. Eso no se me olvida.",
					To = "Yo",
					If = { Choices = { Bruno = "Confiar" } },
				},
				{ S = "Bruno", T = "También por gente como Rayo.", To = "Yo", If = { Flags = { "Camino_Delincuente" } } },
				{ S = "Bruno", T = "Y como tú últimamente. No te lo tomes a mal.", To = "Yo", Pause = 0.9, If = { Flags = { "Camino_Delincuente" } } },
				{
					S = "Bruno",
					T = "Quiero ser el policía que te habría gustado encontrarte.",
					To = "Yo",
					Pause = 0.9,
					If = { Flags = { "Camino_Delincuente" } },
				},
			},
		},
		Plan_Hugo = {
			Lines = {
				{ S = "Hugo", T = "Periodismo. O escribir novelas. O las dos cosas.", To = "Yo" },
				{ S = "Hugo", T = "Mi primera novela será de piratas. La segunda, también.", To = "Yo" },
				{
					S = "Hugo",
					T = "Mi primer reportaje de verdad fue el de los murales de Vega. Contigo. Lo tengo enmarcado.",
					To = "Yo",
					If = { Choices = { Reportaje = "Permiso" } },
				},
				{ S = "Hugo", T = "«El artista misterioso».", To = "Yo", If = { Choices = { Reportaje = "Anonimo" } } },
				{ S = "Hugo", T = "Todavía nadie sabe que era Vega.", To = "Yo", Pause = 0.9, If = { Choices = { Reportaje = "Anonimo" } } },
				{ S = "Hugo", T = "Eso también es periodismo. Saber callar.", To = "Yo", If = { Choices = { Reportaje = "Anonimo" } } },
				{ S = "Hugo", T = "Lo de publicar el nombre de Vega…", To = "Yo", If = { Choices = { Reportaje = "Nombre" } } },
				{ S = "Hugo", T = "Tenías razón en que era verdad. Pero aprendí algo.", To = "Yo", Pause = 0.9, If = { Choices = { Reportaje = "Nombre" } } },
				{ S = "Hugo", T = "La verdad también duele.", To = "Yo" },
			},
		},
		Plan_Iker = {
			Lines = {
				{ S = "Iker", T = "Estadística. Obviamente. Según mis cálculos…", To = "Yo" },
				{ S = "Iker", T = "Hay un noventa y dos por ciento de probabilidades de que me encante.", To = "Yo" },
			},
		},
		Plan_Leire = {
			Lines = {
				{ S = "Leire", T = "Comunicación audiovisual.", To = "Yo" },
				{ S = "Leire", T = "En otra ciudad, probablemente.", To = "Yo", Pause = 0.9 },
				{ S = "Leire", T = "Mi tío dice que tengo que irme para volver con otra mirada.", To = "Yo" },
				{ S = "Leire", T = "Cuando llegué pensé que aquí no tendría a nadie. Ahora me cuesta irme. Qué rabia.", To = "Yo" },
			},
		},
		Plan_Mateo = {
			Lines = {
				{ S = "Mateo", T = "Ingeniería. Mi padre es fontanero.", To = "Yo" },
				{ S = "Mateo", T = "Siempre dice que hay que entender cómo funcionan las cosas.", To = "Yo", Pause = 0.9 },
				{ S = "Mateo", T = "Pues quiero entenderlas todas. Nunca te lo he dicho…", To = "Yo" },
				{ S = "Mateo", T = "El primer día, cuando me ayudaste con los libros… Todo empezó ahí.", To = "Yo", Pause = 0.9 },
			},
		},
		Plan_Nico = {
			Lines = {
				{ S = "Nico", T = "Me han llamado para las pruebas del club de Altamar. Juvenil. Si no sale…", To = "Yo" },
				{ S = "Nico", T = "Estudio para ser entrenador.", To = "Yo" },
				{ S = "Nico", T = "Y aquel sábado viniste a mi cumple en vez de ir al club.", To = "Yo", If = { Choices = { Sabado = "Cumple" } } },
				{ S = "Nico", T = "Eso tampoco se me olvida.", To = "Yo", If = { Choices = { Sabado = "Cumple" } } },
				{ S = "Nico", T = "Oye… Nunca te lo he dicho bien.", To = "Yo", If = { Choices = { HablasNico = "Privado" } } },
				{ S = "Nico", T = "Gracias por lo de Omar.", To = "Yo", If = { Choices = { HablasNico = "Privado" } } },
				{ S = "Nico", T = "Por decírmelo a la cara.", To = "Yo", Pause = 0.9, If = { Choices = { HablasNico = "Privado" } } },
				{
					S = "Nico",
					T = "Y aquel día… Cuando soltaste la bolsa de camisetas.",
					To = "Yo",
					If = { Choices = { Camino = "Negocio" }, Flags = { "Redimido" }, Memories = { "ElCruce" } },
				},
				{
					S = "Nico",
					T = "Ese día supe que seguías siendo tú.",
					To = "Yo",
					If = { Choices = { Camino = "Negocio" }, Flags = { "Redimido" }, Memories = { "ElCruce" } },
				},
			},
		},
		Plan_Omar = {
			Lines = {
				{ S = "Omar", T = "Cocina. FP de cocina. Lola dice que si termino, me coge.", To = "Yo" },
				{ S = "Omar", T = "Voy a hacer la mejor tortilla de Valmar.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Lola dice que eso es imposible.", To = "Yo", Pause = 0.9 },
				{ S = "Omar", T = "Da un poco de miedo, ¿sabes? Que se acabe esto.", To = "Yo" },
				{ S = "Omar", T = "Pero me llevo la pulsera.", To = "Yo" },
			},
		},
		Plan_Sara = {
			Lines = {
				{ S = "Sara", T = "Biología. Después, doctorado.", To = "Yo" },
				{ S = "Sara", T = "Después, descubrir una especie nueva de hongo. Y ponerle mi nombre. Lo tengo calculado.", To = "Yo", Pause = 0.9 },
				{
					S = "Sara",
					T = "¿Te acuerdas del primer día? Mira alrededor. Y aun así me perdí.",
					To = "Yo",
					If = { Memories = { "PrimerDiaInstituto" } },
				},
				{ S = "Sara", T = "¿Y tú? No me digas «no sé». Bueno… Si no lo sabes, dilo. Es un dato válido.", To = "Yo" },
			},
		},
		PuertasAbiertas = {
			Lines = {
				{ S = "Sofia", T = "¡Anda! ¡La persona de los triángulos!", To = "Yo", If = { Flags = { "Interes_Ingenieria" } } },
				{ S = "Sofia", T = "Bienvenid{o/a} a la jornada de puertas abiertas.", To = "Yo", Pause = 0.9, If = { Flags = { "Interes_Ingenieria" } } },
				{
					S = "Sofia",
					T = "¡Bienvenidos! Aquí están las facultades de Medicina, Ingeniería, Derecho y Economía.",
					To = "Yo",
					If = { NotFlags = { "Interes_Ingenieria" } },
				},
				{ S = "Sara", T = "Aquí vamos a estar el año que viene. O no. Pero da igual. Hoy da gusto.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Ins06_G17_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Javier", Npc = "Javier" } } },
				Dialogue = {
					{ At = 0.4, S = "Javier", T = "Una segunda oportunidad no es volver al principio.", To = "Yo" },
					{ At = 5.2, S = "Javier", T = "Es volver sabiendo más.", To = "Yo" },
				},
			},
		},
		Ins06_G23_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = { Dialogue = { { At = 0.4, S = "Yo", T = "Ir a la universidad Empezar a trabajar ya" } } },
		},
		Ins06_G2_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Sara", Npc = "Sara" } } },
				Dialogue = { { At = 0.4, S = "Sara", T = "Ya estás aquí. Último curso. Qué raro.", To = "Yo" } },
			},
		},
		Ins06_G4_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Carmen", Npc = "Carmen" } } },
				Dialogue = { { At = 0.4, S = "Carmen", T = "Pasa. Último curso. Qué rápido.", To = "Yo" } },
			},
		},
	},
	Steps = {
		["1"] = { Effects = { Scene = "Ins06_G2_Entra" } },
		["16"] = { Effects = { Scene = "Ins06_G17_Entra" } },
		["22"] = { Effects = { Scene = "Ins06_G23_Entra" } },
		["3"] = { Effects = { Scene = "Ins06_G4_Entra" } },
	},
}
