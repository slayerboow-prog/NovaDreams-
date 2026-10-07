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
				{ S = "Blorp", T = "¡Blorp! ¡Otra vez aquí!", To = "Yo" },
				{
					S = "CapitanNoz",
					T = "¡La estrella! ¡Mi terrícola favorit{o/a}!",
					To = "Yo",
					Shot = "Reaccion:Ivan",
					If = { Completed = { "Loco_U1_Monte" } },
				},
				{ S = "CapitanNoz", T = "Tu huida del monte fue nuestro episodio más visto.", To = "Yo", Pause = 0.9, If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "Trescientas galaxias lo repitieron.", To = "Yo", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "Blorp", T = "¡Blorp!", To = "Yo", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "Ivan", T = "¿Eso es bueno?", To = "Yo", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "Muchísimo. Aunque todavía tenemos una queja.", To = "Yo", If = { Completed = { "Loco_U1_Monte" } } },
				{ S = "CapitanNoz", T = "Terrícola. Me dicen que buscas algo.", To = "Yo", If = { NotCompleted = { "Loco_U1_Monte" } } },
				{
					S = "CapitanNoz",
					T = "En mi nave hay cámaras en todas las dimensiones. Todo se graba. Todo.",
					To = "Yo",
					If = { NotCompleted = { "Loco_U1_Monte" } },
				},
				{ S = "CapitanNoz", T = "Ñoz cambia completamente su expresión.", To = "Yo", Pause = 0.9 },
				{ S = "CapitanNoz", T = "¿Buscas el laboratorio del de la perilla? Ñoz sonríe. Lo tengo. En alta definición.", To = "Yo" },
				{ S = "CapitanNoz", T = "Pero en televisión nada es gratis, cariño.", To = "Yo" },
				{ S = "CapitanNoz", T = "Quiero un episodio especial.", To = "Yo" },
				{ S = "CapitanNoz", T = "«Terrícola rescata a su vecino loco».", To = "Yo" },
				{ S = "Ivan", T = "¿Tenemos que actuar?", To = "Yo" },
				{ S = "CapitanNoz", T = "No. Solo tenéis que ser vosotros mismos.", To = "Yo" },
				{ S = "Candela", T = "Eso me preocupa más. Ñoz sonríe.", To = "Yo" },
				{ S = "Candela", T = "Y queremos ver el guion antes. Plastificado.", To = "Yo" },
				{ S = "Candela", T = "Ñoz se queda mirándola.", To = "Yo" },
				{ S = "CapitanNoz", T = "Me caes bien.", To = "Yo" },
				{ S = "Candela", T = "Era la intención.", To = "Yo" },
				{ S = "Blorp", T = "¡Blorp! ¡Yo hago de malo!", To = "Yo" },
				{ S = "Blorp", T = "¡Siempre he querido hacer de malo!", To = "Yo" },
				{ S = "Blorp", T = "¡Tengo una perilla de pega!", To = "Yo" },
				{ S = "Ivan", T = "Está bastante bien.", To = "Yo" },
				{ S = "Candela", T = "No le digas eso.", To = "Yo" },
			},
		},
		Grabacion = {
			Lines = {
				{ S = "CapitanNoz", T = "Toma. La grabación del laboratorio del doctor Cósimo.", To = "Yo", Effects = { Scene = "Saga_15_G3_Musica" } },
				{ S = "Ivan", T = "Está vivo.", To = "Yo", Pause = 0.9 },
				{ S = "Candela", T = "Está bien. Está dormido.", To = "Yo" },
				{ S = "Ivan", T = "Lleva zapatillas. Eso es buena señal.", To = "Yo" },
				{ S = "Candela", T = "¿En qué sentido?", To = "Yo" },
				{ S = "Ivan", T = "No lo sé. Pero me tranquiliza.", To = "Yo" },
				{ S = "CapitanNoz", T = "La grabación es de esta noche.", To = "Yo" },
				{ S = "CapitanNoz", T = "Eso significa que sigue allí. Podéis llegar.", To = "Yo", Pause = 0.9 },
				{ S = "Candela", T = "¿Y cómo? Ñoz señala la pantalla.", To = "Yo" },
				{ S = "CapitanNoz", T = "Tenéis las coordenadas.", To = "Yo" },
				{ S = "CapitanNoz", T = "Y ahora tenéis los ojos. Solo falta entrar.", To = "Yo" },
				{ S = "Cosme", T = "Criatura…", To = "Yo" },
				{ S = "CapitanNoz", T = "Pase VIP. Cuando todo esto acabe, venid a la final de temporada. Traed al vecino.", To = "Yo", Pause = 0.9 },
				{ S = "CapitanNoz", T = "Que salga en el último episodio.", To = "Yo" },
				{ S = "Narrador", T = "Recibes 🎫 Pase_VIP_Plató." },
				{ S = "Ivan", T = "¿Entonces vamos a entrar ahí?", To = "Yo" },
				{ S = "Candela", T = "Sí.", To = "Yo" },
				{ S = "Ivan", T = "¿Y tenemos un plan?", To = "Yo" },
				{ S = "Candela", T = "Siempre.", To = "Yo" },
				{ S = "Pip", T = "He recibido las imágenes.", To = "Yo" },
				{ S = "Pip", T = "He confirmado la ubicación. Mañana entramos.", To = "Yo", Pause = 0.9 },
				{ S = "Narrador", T = "«Viste a Cosme. Está vivo. Está atrapado bajo la universidad de la dimensión 66-B.»", Pause = 0.9 },
			},
		},
	},
	Scenes = {
		Saga_15_G2_Entra = {
			Light = true,
			Duration = 32.2,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "CapitanNoz", Npc = "CapitanNoz" } }, { At = 0, Use = { Key = "Blorp", Npc = "Blorp" } } },
				Dialogue = {
					{ At = 0.4, S = "Blorp", T = "¡Blorp!", To = "Yo" },
					{ At = 2.9, S = "CapitanNoz", T = "Más malvado.", To = "Yo" },
					{ At = 5.4, S = "Blorp", T = "¡BLORP!", To = "Yo" },
					{ At = 7.9, S = "CapitanNoz", T = "Perfecto. No tengo ni idea de qué está haciendo.", To = "Yo" },
					{
						At = 12.1,
						S = "CapitanNoz",
						T = "¡Corten! Eres un talento natural. Bueno. Natural no. Pero talento.",
						To = "Yo",
						If = { Flags = { "Saga_15_P2_Gana" } },
					},
					{ At = 17.6, S = "Blorp", T = "¡Blorp!", To = "Yo", If = { Flags = { "Saga_15_P2_Gana" } } },
					{
						At = 20.1,
						S = "CapitanNoz",
						T = "¡Corten! Se te ha trabado la frase cuatro veces. Da igual. Se guarda el guion. Tenemos episodio.",
						To = "Yo",
					},
					{ At = 27.8, S = "CapitanNoz", T = "Pero la misión continúa exactamente igual.", To = "Yo" },
				},
			},
		},
		Saga_15_G3_Musica = { Light = true, Duration = 75.2, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
	},
	Steps = {
		["1"] = { Effects = { Scene = "Saga_15_G2_Entra" } },
		["2"] = { Set = { Text = "completar correctamente el rodaje.", Win = { Flags = { "BuenRodaje", "Saga_15_P2_Gana" }, Traits = { Valentia = 1 } } } },
	},
}
