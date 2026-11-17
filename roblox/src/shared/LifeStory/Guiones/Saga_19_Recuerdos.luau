-- GUION REESCRITO de Saga_19_Recuerdos (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_19_Recuerdos.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_19_Recuerdos
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_19_Recuerdos.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_19_Recuerdos.md",
	Dialogues = {
		Anclaje = {
			Lines = {
				{ S = "Narrador", T = "El anclaje del parque, el primero que clavaste. Todavía brilla un poco. Cosme lo toca." },
				{ S = "Cosme", T = "La aguja. La noche en que cerramos la Grieta. Tú clavaste esto.", To = "Yo" },
				{ S = "Cosme", T = "Y yo estaba tan orgulloso que no fui capaz de decírtelo.", To = "Yo" },
			},
		},
		Gallina = {
			Lines = {
				{ S = "Narrador", T = "La pared de la entrada de la Academia. Cientos de nombres grabados. Kael mandó añadir uno hace un año." },
				{ S = "Narrador", T = "Lía. Investigadora. No dejó a nadie atrás." },
				{ S = "Cosme", T = "…Lía.", To = "Yo" },
				{ S = "Cosme", T = "Mi hermana. Se llamaba Lía. Me enseñó a montar mi primer circuito y a no rendirme con el segundo.", To = "Yo" },
				{ S = "Cosme", T = "La noche de la Caída llamó por radio. Le dije que saliera de allí. No me hizo caso. Nunca me hacía caso.", To = "Yo" },
			},
		},
		Lista = {
			Lines = {
				{ S = "Pip", T = "He hecho una lista de los sitios que más le importaban al doctor. Es corta. Casi nunca salía.", To = "Yo" },
				{ S = "Pip", T = "En casi todos estaba usted.", To = "Yo" },
				{ S = "Cosme", T = "No recuerdo haber sido feliz en ningún sitio. Pero si tú lo dices, vamos.", To = "Yo" },
				{ S = "Cosme", T = "Sé tu nombre. Es lo único que tengo segur{o/a}. Empezaremos por ahí.", To = "Yo", If = { Memories = { "TuNombre" } } },
			},
		},
		Microondas = {
			Lines = {
				{ S = "Narrador", T = "Pip ha reparado el detector de resonancia. Al encenderlo, la pantalla se llena de líneas, como aquella primera noche." },
				{ S = "Cosme", T = "El núcleo, la bobina, el chip. Alguien vino a ayudarme sin preguntar nada.", To = "Yo" },
				{ S = "Cosme", T = "Eras tú. Llegaste tarde. Te dije que llegabas tarde.", To = "Yo" },
			},
		},
		Vuelve = {
			Lines = {
				{ S = "Cosme", T = "Me acuerdo. De todo. Del detector, de Escamas, de la Aduana, de la grabación, de la cápsula.", To = "Yo" },
				{
					S = "Cosme",
					T = "De la credencial. Le dije a la Academia que era un carné de biblioteca. No se lo creyó nadie.",
					To = "Yo",
					If = { Memories = { "AyudanteCosme" } },
				},
				{ S = "Cosme", T = "Y de que guardaste mi secreto. Nunca se lo contaste a nadie.", To = "Yo", If = { Flags = { "SecretoCosme" } } },
				{
					S = "Cosme",
					T = "Y de que fuiste a buscarme a otro mundo. Con dos cadetes, un androide y un desertor.",
					To = "Yo",
					If = { Memories = { "RescateCosme" } },
				},
				{ S = "Pip", T = "Bienvenid{o/a}, doctor. Esta vez de verdad.", To = "Yo", If = { Memories = { "RescateCosme" } } },
				{
					S = "Cosme",
					T = "Y me acuerdo de lo peor. De lo que Cósimo me sacó de la cabeza: cómo soltar el Ancla sin matarla.",
					To = "Yo",
					If = { Memories = { "RescateCosme" } },
				},
				{ S = "Cosme", T = "Ya lo sabe. Va a venir a por ti. Vamos a necesitar a todos.", To = "Yo", If = { Memories = { "RescateCosme" } } },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
