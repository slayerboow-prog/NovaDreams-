-- GUION REESCRITO de Saga_15_Reestreno (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_15_Reestreno.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_15_Reestreno
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_15_Reestreno.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_15_Reestreno.md",
	Dialogues = {
		Capitana = {
			Lines = {
				{ S = "Blorp", T = "¡Blorp! ¡Otra vez aquí!", To = "Yo", A = "Nod" },
				{
					S = "CapitanNoz",
					T = "¡La estrella! ¡Mi terrícola favorit{o/a}!",
					To = "Yo",
					Shot = "Reaccion:Ivan",
					A = "Nod",
					If = { Completed = { "Loco_U1_Monte" } },
				},
				{ S = "CapitanNoz", T = "Tu huida del monte fue nuestro episodio más visto.", To = "Yo", Pause = 0.9, If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "Trescientas galaxias lo repitieron.", To = "Yo", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "Blorp", T = "¡Blorp!", To = "Yo", A = "Happy", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "Ivan", T = "¿Eso es bueno?", To = "Yo", A = "Ask", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "Muchísimo. Aunque todavía tenemos una queja.", To = "Yo", A = "ThinkChin", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "Terrícola. Me dicen que buscas algo.", To = "Yo", If = { NotCompleted = { "Loco_U1_Monte" } } },
				{
					S = "CapitanNoz",
					T = "En mi nave hay cámaras en todas las dimensiones. Todo se graba. Todo.",
					To = "Yo",
					If = { NotCompleted = { "Loco_U1_Monte" } },
				},
				{ S = "CapitanNoz", T = "¿Buscas el laboratorio del de la perilla? Lo tengo. En alta definición.", To = "Yo" },
				{ S = "CapitanNoz", T = "Pero en televisión nada es gratis, cariño.", To = "Yo" },
				{ S = "CapitanNoz", T = "Quiero un episodio especial.", To = "Yo" },
				{ S = "CapitanNoz", T = "«Terrícola rescata a su vecino loco».", To = "Yo" },
				{ S = "Ivan", T = "¿Tenemos que actuar?", To = "Yo", A = "Ask" },
				{ S = "CapitanNoz", T = "No. Solo tenéis que ser vosotros mismos.", To = "Yo", A = "No" },
				{ S = "Candela", T = "Eso me preocupa más. Y queremos ver el guion antes. Plastificado.", To = "Yo", A = "Nod" },
				{ S = "CapitanNoz", T = "Me caes bien.", To = "Yo", A = "Happy" },
				{ S = "Candela", T = "Era la intención.", To = "Yo", A = "Nod" },
				{ S = "Blorp", T = "¡Blorp! ¡Yo hago de malo!", To = "Yo", A = "Nod" },
				{ S = "Blorp", T = "¡Siempre he querido hacer de malo!", To = "Yo" },
				{ S = "Blorp", T = "¡Tengo una perilla de pega!", To = "Yo" },
				{ S = "Ivan", T = "Está bastante bien.", To = "Yo", A = "Nod" },
				{ S = "Candela", T = "No le digas eso.", To = "Yo", A = "No" },
			},
		},
		Grabacion = {
			Lines = {
				{
					S = "CapitanNoz",
					T = "Toma. La grabación del laboratorio del doctor Cósimo.",
					To = "Yo",
					A = "ThinkChin",
					Effects = { Scene = "Saga_15_G3_Musica" },
				},
				{ S = "Ivan", T = "Está vivo.", To = "Yo", A = "ThinkChin", Pause = 0.9 },
				{ S = "Candela", T = "Está bien. Está dormido.", To = "Yo", A = "ThinkChin" },
				{ S = "Ivan", T = "Lleva zapatillas. Eso es buena señal.", To = "Yo", A = "Happy" },
				{ S = "Candela", T = "¿En qué sentido?", To = "Yo", A = "Ask" },
				{ S = "Ivan", T = "No lo sé. Pero me tranquiliza.", To = "Yo", A = "No" },
				{ S = "CapitanNoz", T = "La grabación es de esta noche.", To = "Yo", A = "Nod" },
				{ S = "CapitanNoz", T = "Eso significa que sigue allí. Podéis llegar.", To = "Yo", Pause = 0.9 },
				{ S = "Candela", T = "¿Y cómo?", To = "Yo", A = "Ask" },
				{ S = "CapitanNoz", T = "Tenéis las coordenadas.", To = "Yo", A = "Nod" },
				{ S = "CapitanNoz", T = "Y ahora tenéis los ojos. Solo falta entrar.", To = "Yo" },
				{ S = "Cosme", T = "Criatura…", To = "Yo", A = "ThinkChin" },
				{ S = "CapitanNoz", T = "Pase VIP. Cuando todo esto acabe, venid a la final de temporada. Traed al vecino.", To = "Yo", A = "Nod", Pause = 0.9 },
				{ S = "CapitanNoz", T = "Que salga en el último episodio.", To = "Yo" },
				{ S = "Narrador", T = "Recibes 🎫 Pase_VIP_Plató." },
				{ S = "Ivan", T = "¿Entonces vamos a entrar ahí?", To = "Yo", A = "Ask" },
				{ S = "Candela", T = "Sí.", To = "Yo", A = "Nod" },
				{ S = "Ivan", T = "¿Y tenemos un plan?", To = "Yo", A = "Ask" },
				{ S = "Candela", T = "Siempre.", To = "Yo", A = "Nod" },
				{ S = "Pip", T = "He recibido las imágenes.", To = "Yo", A = "ArmsCrossed" },
				{ S = "Pip", T = "He confirmado la ubicación. Mañana entramos.", To = "Yo", Pause = 0.9 },
				{ S = "Narrador", T = "«Viste a Cosme. Está vivo. Está atrapado bajo la universidad de la dimensión 66-B.»", Pause = 0.9 },
			},
		},
	},
	Scenes = {
		Saga_15_G2_Entra = {
			Light = true,
			Duration = 28.5,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "CapitanNoz", Npc = "CapitanNoz" } }, { At = 0, Use = { Key = "Blorp", Npc = "Blorp" } } },
				Dialogue = {
					{ At = 0.4, S = "Blorp", T = "¡Blorp!", To = "Yo", A = "ThinkChin" },
					{ At = 2.9, S = "CapitanNoz", T = "Más malvado.", To = "Yo", A = "Happy", Mood = "Joy" },
					{ At = 5.4, S = "Blorp", T = "¡BLORP!", To = "Yo", A = "Happy", Mood = "Joy" },
					{ At = 7.9, S = "CapitanNoz", T = "Perfecto. No tengo ni idea de qué está haciendo.", To = "Yo", A = "Nod" },
					{
						At = 12.1,
						S = "CapitanNoz",
						T = "¡Corten! Eres un talento natural. Bueno. Natural no. Pero talento.",
						To = "Yo",
						If = { Flags = { "Saga_15_P2_Gana" } },
					},
					{ At = 17.6, S = "Blorp", T = "¡Blorp!", To = "Yo", A = "Nod", If = { Flags = { "Saga_15_P2_Gana" } } },
					{
						At = 20.1,
						S = "CapitanNoz",
						T = "¡Corten! Se te ha trabado la frase cuatro veces. Da igual. Se guarda el guion. Tenemos episodio.",
						To = "Yo",
						A = "Happy",
						Mood = "Joy",
					},
				},
			},
		},
		Saga_15_G3_Musica = { Light = true, Duration = 74.6, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
	},
	Steps = {
		["1"] = { Effects = { Scene = "Saga_15_G2_Entra" } },
		["2"] = { Set = { Text = "completar correctamente el rodaje.", Win = { Flags = { "BuenRodaje", "Saga_15_P2_Gana" }, Traits = { Valentia = 1 } } } },
	},
}
