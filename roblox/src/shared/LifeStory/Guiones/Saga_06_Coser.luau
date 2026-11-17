-- GUION REESCRITO de Saga_06_Coser (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_06_Coser.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_06_Coser
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_06_Coser.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_06_Coser.md",
	Dialogues = {
		Anclaje = {
			Lines = { { S = "Narrador", T = "El último. Al clavarlo, las farolas de la plaza parpadean a la vez. Algo, al otro lado, se ha dado cuenta." } },
		},
		Plan = {
			Lines = {
				{ S = "Cosme", T = "La aguja. La diseñó Lía. Yo solo la he terminado.", To = "Yo" },
				{
					S = "Cosme",
					T = "Tres anclajes en tres puntos del Distrito Central. Forman un triángulo. La aguja, en el centro, cierra la Grieta.",
					To = "Yo",
				},
				{ S = "Cosme", T = "No para siempre. El tiempo suficiente para entender cómo la abrieron.", To = "Yo" },
				{ S = "Cosme", T = "He calculado sus rondas. Hay huecos. Pequeños.", To = "Yo", If = { Flags = { "ConoceConsorcio" } } },
				{
					Ask = "Antes de salir, le preguntas a Cosme:",
					Options = {
						{
							T = "«¿Quién es Cósimo de verdad?»",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = {
								{
									S = "Cosme",
									T = "Soy yo. Otra versión de mí, en un mundo donde Lía murió antes y él no tuvo a nadie que le frenara.",
									A = "Sad",
									Beat = "Aparta",
								},
								{ S = "Cosme", T = "Allí él construyó la máquina. Aquí la construyó Lía. Las dos se tocaron la noche de la Caída.", Pause = 0.6 },
								{ S = "Cosme", T = "Llevo dos años preguntándome si yo habría hecho lo mismo.", Shot = "PrimerPlano:Cosme", A = "Sad" },
							},
						},
						{
							T = "«¿Por qué la Grieta tira hacia mí?»",
							Effects = { Traits = { Valentia = 1 } },
							Then = {
								{ S = "Cosme", T = "…Tengo una teoría. No me gusta. Prefiero estar seguro antes de decírtela.", Beat = "Piensa" },
								{ S = "Cosme", T = "Y sí: tiene que ver con lo que Escamas llama el Ancla.", If = { Flags = { "OyoAncla" } } },
								{ S = "Cosme", T = "Te lo contaré cuando esto esté cerrado. Te doy mi palabra." },
							},
						},
					},
				},
			},
		},
		Voz = {
			Lines = {
				{ S = "Cosme", T = "Cerrada. Lía, está cerrada.", To = "Yo" },
				{ S = "Narrador", T = "Del último punto de la costura sale una voz. Tranquila. Educada. Con la misma voz que Cosme, pero más vieja." },
				{ S = "Cosimo", T = "Buen trabajo, Cosme. Ella habría estado orgullosa. Lástima que no pueda verlo.", To = "Yo" },
				{ S = "Cosimo", T = "Y tú. Por fin. Hace dos años que te busco.", To = "Yo" },
				{ S = "Cosimo", T = "La noche de la Caída estabas en el Sur. La Grieta te atravesó y no te mató. ¿Nunca te lo has preguntado?", To = "Yo" },
				{ S = "Cosimo", T = "Eres el Ancla. Mientras sigas en ese mundo, no puedo abrirlo del todo.", To = "Yo" },
				{ S = "Cosimo", T = "Nos veremos pronto. Las costuras siempre ceden.", To = "Yo" },
				{ S = "Pip", T = "Señor. Tiene que contárselo todo.", To = "Yo" },
				{ S = "Cosme", T = "Lo sé, Pip. Pronto.", To = "Yo" },
				{ S = "Cosme", T = "Quédate la aguja. Ella habría querido que la tuviera alguien que pueda usarla.", To = "Yo" },
				{ S = "Narrador", T = "FIN DEL ACTO I. La Grieta está cerrada. Por ahora." },
			},
		},
	},
	Scenes = {
		Saga_06_G3_Entra = {
			Light = true,
			Duration = 14.6,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Pip", Npc = "Pip" } } },
				Dialogue = {
					{ At = 0.4, S = "Narrador", T = "Los dos agentes grises cruzan el patio sin prisa. Sonríen a la vez." },
					{ At = 6, S = "Pip", T = "Van a por la aguja. Si la tocan, se acabó. Apágueles el comunicador: es lo que les une al otro lado.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["2"] = { Effects = { Scene = "Saga_06_G3_Entra" } } },
}
