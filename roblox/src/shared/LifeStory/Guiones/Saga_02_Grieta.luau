-- GUION REESCRITO de Saga_02_Grieta (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_02_Grieta.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_02_Grieta
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_02_Grieta.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_02_Grieta.md",
	Dialogues = {
		Bigotes = {
			Lines = {
				{ S = "Bigotes", T = "Has vuelto. Bien. Tengo que decirte algo y no tengo mucho tiempo.", To = "Yo", If = { Flags = { "BigotesHabla" } } },
				{ S = "Bigotes", T = "No grites. Hablo dentro de tu cabeza. Nadie más me oye.", To = "Yo", If = { NotFlags = { "BigotesHabla" } } },
				{
					S = "Bigotes",
					T = "En mi mundo llamábamos a esa grieta «la puerta mal cerrada». Por ella entraron los que acabaron con nosotros.",
					To = "Yo",
					If = { NotFlags = { "BigotesHabla" } },
				},
				{ S = "Bigotes", T = "No eran bestias. Las bestias solo huían delante de ellos.", To = "Yo", If = { NotFlags = { "BigotesHabla" } } },
				{
					S = "Bigotes",
					T = "Esta noche he oído una voz al otro lado. Un hombre. Tranquil{o/a}. Educado.",
					To = "Yo",
					If = { NotFlags = { "BigotesHabla" } },
				},
				{ S = "Bigotes", T = "Decía tu nombre. Como quien repasa una lista.", To = "Yo", If = { NotFlags = { "BigotesHabla" } } },
			},
		},
		Calcetin = {
			Lines = {
				{ S = "Narrador", T = "En el cráter hay un trozo de armadura. No es de Valmar. Por dentro tiene una insignia y una fecha que no existe." },
				{ S = "Pip", T = "Aleación desconocida. Marcas de garras. Quien la llevaba no sobrevivió.", To = "Yo" },
				{ S = "Pip", T = "Al otro lado de la Grieta también hay una guerra.", To = "Yo" },
			},
		},
		Medidor = {
			Lines = {
				{
					S = "Pip",
					T = "Lectura de resonancia: cuatrocientos por encima de la base. La última vez que vimos algo así fue la noche de la Caída.",
					To = "Yo",
					A = "ArmsCrossed",
					Effects = { Scene = "Saga_02_G1_Musica" },
				},
				{ S = "Cosme", T = "Has venido. No se lo has contado a nadie. Bien.", To = "Yo", If = { Flags = { "SecretoCosme" } } },
				{
					S = "Cosme",
					T = "La Grieta ha crecido tres metros esta noche. Desde el suelo no se nota. Desde aquí, sí.",
					To = "Yo",
					If = { Flags = { "SecretoCosme" } },
				},
				{
					S = "Cosme",
					T = "Esta es Pip. La construí después de la Caída. Necesitaba a alguien que no se cansara de mirar el cielo.",
					To = "Yo",
					G = "Point",
					If = { Flags = { "SecretoCosme" } },
				},
				{ S = "Pip", T = "Y que no necesitara dormir. Él tampoco duerme, pero lo intenta.", To = "Yo", If = { Flags = { "SecretoCosme" } } },
				{
					S = "Cosme",
					T = "Ha caído algo. Tres impactos dentro del Distrito Central. Hay que recogerlo antes que la patrulla de la Academia.",
					To = "Yo",
					If = { Flags = { "SecretoCosme" } },
				},
				{ S = "Yo", T = "¿Por qué antes que ellos?", If = { Flags = { "SecretoCosme" } } },
				{
					S = "Cosme",
					T = "Porque lo guardarán en un almacén y dirán que no ha pasado nada. Como la otra vez.",
					To = "Yo",
					If = { Flags = { "SecretoCosme" } },
				},
				{ S = "Cosme", T = "Pip va contigo. Yo me quedo vigilando la lectura.", To = "Yo", If = { Flags = { "SecretoCosme" } } },
			},
		},
		Moneda = {
			Lines = {
				{ S = "Narrador", T = "Una placa de identificación, todavía caliente. Pone «66-B». Debajo hay una cara grabada." },
				{ S = "Narrador", T = "Es la cara de Cosme. Más vieja. Con una cicatriz en la mejilla y una sonrisa que Cosme no tiene." },
				{ S = "Pip", T = "Esto tiene que verlo él. Aunque preferiría que no lo viera.", To = "Yo" },
			},
		},
		Paraguas = {
			Lines = {
				{
					S = "Narrador",
					T = "En el patio de la Academia, un generador del tamaño de un puño flota a un metro del suelo. A su alrededor, la lluvia sube.",
				},
				{ S = "Narrador", T = "Unos cadetes de primer año lo miran sin atreverse a tocarlo." },
				{ S = "Pip", T = "Invierte la gravedad en un radio de dos metros. Si fuera más grande, podría levantar un edificio.", To = "Yo" },
				{ S = "Narrador", T = "Lo apagas. La lluvia vuelve a caer. Los cadetes se apartan para dejarte pasar." },
			},
		},
		Perilla = {
			Lines = {
				{
					S = "Cosme",
					T = "Armadura de otro mundo. Un generador de gravedad. Y… ¿qué más traes? Cósimo.",
					To = "Yo",
					Effects = { Scene = "Saga_02_G6_Musica" },
				},
				{ S = "Yo", T = "¿Quién es Cósimo?" },
				{ S = "Cosme", T = "Alguien con mi cara. De otra versión de este mundo, al otro lado de la Grieta.", To = "Yo" },
				{ S = "Cosme", T = "Mi hermana lo vio una vez en sus mediciones. Dos semanas después llegó la Caída.", To = "Yo" },
				{ S = "Cosme", T = "Quédate la placa. No quiero tenerla cerca.", To = "Yo" },
				{ S = "Pip", T = "(susurrando) No ha dormido desde que se abrió la Grieta. Si puede, vigílele.", To = "Yo" },
				{ S = "Pip", T = "Él lleva tiempo vigilándole a usted. Desde antes de que supiera su nombre.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_02_G1_Musica = { Light = true, Duration = 58.3, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
		Saga_02_G6_Musica = { Light = true, Duration = 39.7, Anchors = { Yo = "Player" }, Tracks = { Music = { { At = 0, Intensity = "Tension" } } } },
	},
	Steps = { ["5"] = { Set = { Text = "Lleva los restos al garaje de Cosme" } } },
}
