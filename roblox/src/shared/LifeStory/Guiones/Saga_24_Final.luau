-- GUION REESCRITO de Saga_24_Final (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_24_Final.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_24_Final
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_24_Final.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_24_Final.md",
	Dialogues = {
		Final = {
			Lines = {
				{ S = "Cosimo", T = "Ya está. Ya no eres un Ancla. Eres… …una persona. Qué aburrido. Qué bien.", To = "Yo" },
				{ S = "Cosme", T = "Criatura.", To = "Yo" },
				{
					S = "Cosme",
					T = "Te lo digo ahora… Tengo todos los recuerdos. Y ninguno pendiente.",
					To = "Yo",
					Pause = 0.9,
					If = { Memories = { "CosmeRecuerda" } },
				},
				{ S = "Cosme", T = "Estoy orgulloso de ti.", To = "Yo", Pause = 0.9, If = { Memories = { "CosmeRecuerda" } } },
				{ S = "Cosme", T = "Te lo digo ahora… El cielo está limpio.", To = "Yo", If = { NotMemories = { "CosmeRecuerda" } } },
				{ S = "Cosme", T = "Estoy orgulloso de ti.", To = "Yo", Pause = 0.9, If = { NotMemories = { "CosmeRecuerda" } } },
				{ S = "Cosme", T = "Desde el microondas. Desde siempre.", To = "Yo", If = { Memories = { "ConociCosme" } } },
				{ S = "Cosme", T = "Desde siempre.", To = "Yo", If = { NotMemories = { "ConociCosme" } } },
				{
					Ask = "¿Qué le dices a Cosme?",
					Options = {
						{
							T = "«Gracias por cuidarme toda la vida.»",
							Effects = { Rel = { Cosme = 20 } },
							Then = {
								{ S = "Cosme", T = "No me des las gracias. Dame un abrazo. Rápido.", To = "Yo" },
								{ S = "Cosme", T = "Que viene Cósimo y no quiero que se ría. …Vale. Que se ría.", To = "Yo", Pause = 0.9 },
							},
						},
						{
							T = "«¿Y ahora qué inventamos?»",
							Effects = { Rel = { Cosme = 15 }, Traits = { Curiosidad = 2 } },
							Then = {
								{ S = "Cosme", T = "¡Esa es mi criatura! Tengo una idea.", To = "Yo" },
								{ S = "Cosme", T = "Así el pan ya está hecho mañana.", To = "Yo", Pause = 0.9 },
								{ S = "Cosimo", T = "No.", To = "Yo" },
								{ S = "Cosme", T = "¡Cósimo, trae el destornillador!", To = "Yo" },
								{ S = "Cosimo", T = "No. ¿Dónde está?", To = "Yo" },
							},
						},
					},
				},
				{ S = "Ivan", T = "Entonces… ¿Ya está? ¿Hemos salvado el universo?", To = "Yo" },
				{ S = "Ivan", T = "¡Zumo de mora para todos! ¡De día!", To = "Yo", Pause = 0.9 },
				{
					S = "Ivan",
					T = "Quedan treinta y nueve litros del zumo para el ejército. Nadie se va sin vaso.",
					To = "Yo",
					If = { Flags = { "AliadoCompis" } },
				},
				{ S = "Candela", T = "Reunir a todos. Terminado.", To = "Yo" },
				{ S = "Candela", T = "Es el mejor día de mi vida.", To = "Yo" },
				{ S = "Candela", T = "Tachado el último punto. Reunir a todos.", To = "Yo", If = { Flags = { "AliadosReunidos" } } },
				{ S = "Candela", T = "Es el mejor día de mi vida.", To = "Yo", Pause = 0.9, If = { Flags = { "AliadosReunidos" } } },
				{ S = "Cosimo", T = "Y el de los sellos llegó a la hora.", To = "Yo", If = { Flags = { "AliadoCronos" } } },
				{ S = "Cosimo", T = "Ahora sí que lo he visto todo.", To = "Yo", Pause = 0.9, If = { Flags = { "AliadoCronos" } } },
				{ S = "CazadorTiempo", T = "Estoy intentando disfrutarlo.", To = "Yo", If = { Flags = { "AliadoCronos" } } },
				{ S = "Pip", T = "Tengo una cosa para ti.", To = "Yo" },
				{ S = "Narrador", T = "Recibes la Aguja de Oro. Pero en Valmar…" },
				{ S = "Narrador", T = "…las cosas raras nunca se acaban del todo.", Pause = 0.9 },
			},
		},
		Garaje = {
			Lines = {
				{ S = "Cosme", T = "¡Esa pieza va al revés!", To = "Yo" },
				{ S = "Cosimo", T = "¡Va al revés porque la pusiste tú al revés aquella noche!", To = "Yo" },
				{ S = "Cosme", T = "¡Yo nunca pongo nada al revés!", To = "Yo" },
				{ S = "Cosimo", T = "Y no mires la barbilla.", To = "Yo", Pause = 1.8, If = { Flags = { "CosimoPerdonado" } } },
				{ S = "Cosimo", T = "Ya sé que sin perilla parezco un huevo. No puede.", To = "Yo", Pause = 0.9, If = { Flags = { "CosimoPerdonado" } } },
				{ S = "Cosimo", T = "Tengo una dimensión entera que arreglar.", To = "Yo", Pause = 0.9, If = { Flags = { "CosimoArregla66B" } } },
				{ S = "Cosme", T = "Te vendrá bien.", To = "Yo", If = { Flags = { "CosimoArregla66B" } } },
				{ S = "Cosimo", T = "No te emociones. Sigo siendo yo.", To = "Yo", If = { Flags = { "CosimoArregla66B" } } },
				{ S = "Pip", T = "Llevan así tres horas. Es precioso. Es como antes.", To = "Yo" },
				{ S = "Pip", T = "Tengo el aceite de los ojos alterado.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Las cuentas del Consorcio, cerradas.", To = "Yo", If = { Flags = { "ConsorcioCaido" } } },
				{ S = "DonEscamas", T = "Me encanta cuadrar un balance.", To = "Yo", Pause = 0.9, If = { Flags = { "ConsorcioCaido" } } },
				{ S = "Pip", T = "Mucho correo.", To = "Yo", Pause = 0.9, If = { Flags = { "FusionDetenida" } } },
				{ S = "Pip", T = "La Guardia Gatuna supervisó la batalla. Desde sus cajas. Éxito total.", To = "Yo", If = { Memories = { "GuardiaGatuna" } } },
				{ S = "Pip", T = "Rex manda su minuta: un jamón. Dice que es simbólico.", If = { Memories = { "AbogadoRex" } } },
				{ S = "Pip", T = "Ciento doce cables de MegaVerso mordidos. Récord.", To = "Yo", Pause = 0.9, If = { Memories = { "MuelaDelJuicio" } } },
				{ S = "Pip", T = "La Aduana del Tiempo felicita al agente Cronos. Llegó a la hora.", To = "Yo", If = { Memories = { "ExpedienteCronos" } } },
				{ S = "Pip", T = "Por primera vez en cuatrocientos años.", To = "Yo", Pause = 0.9, If = { Memories = { "ExpedienteCronos" } } },
				{ S = "Pip", T = "Récord de audiencia en trescientas galaxias.", To = "Yo", If = { Memories = { "TemporadaFinal" } } },
				{ S = "Pip", T = "Los gnomos llegaron cuando ya había acabado todo.", To = "Yo", Pause = 0.9, If = { Memories = { "ConsejoGnomos" } } },
				{ S = "Pip", T = "Dicen que era el plan.", To = "Yo", Pause = 0.9, If = { Memories = { "ConsejoGnomos" } } },
				{ S = "Pip", T = "Tu yo de la 66-B manda flores. Estas no muerden.", To = "Yo", If = { Memories = { "ClasesDeBondad" } } },
				{ S = "Cosme", T = "Después de lo del monte…", To = "Yo", If = { Memories = { "GranFusion" } } },
				{ S = "Cosme", T = "Criatura. Hay que coser el cielo desde los dos lados a la vez. Yo desde aquí. Y tú en el centro.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Porque eres el Ancla. Donde empezó todo.", To = "Yo" },
			},
		},
	},
	Scenes = {
		Saga_24_G2_Entra = {
			Light = true,
			Duration = 30.1,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = {
					{ At = 0, Use = { Key = "Cosimo", Npc = "Cosimo" } },
					{ At = 0, Use = { Key = "Ivan", Npc = "Ivan" } },
					{ At = 0, Use = { Key = "Candela", Npc = "Candela" } },
					{ At = 0, Use = { Key = "Cosme", Npc = "Cosme" } },
				},
				Dialogue = {
					{ At = 0.4, S = "Ivan", T = "Entonces… ¿Esto es oficialmente el final?", To = "Yo" },
					{ At = 4.1, S = "Candela", T = "Según mi lista, sí.", To = "Yo" },
					{ At = 6.6, S = "Ivan", T = "¿Y si no?", To = "Yo" },
					{ At = 9.1, S = "Candela", T = "Entonces hago otra lista.", To = "Yo" },
					{ At = 12.6, S = "Ivan", T = "Me tranquiliza muchísimo.", To = "Yo" },
					{ At = 15.2, S = "Cosimo", T = "Has envejecido.", To = "Yo" },
					{ At = 17.7, S = "Cosme", T = "Tú también.", To = "Yo" },
					{ At = 21.1, S = "Cosimo", T = "Yo tengo estilo.", To = "Yo" },
					{ At = 23.6, S = "Cosme", T = "Tienes una perilla.", To = "Yo" },
					{ At = 27, S = "Cosimo", T = "Tenía una perilla.", To = "Yo" },
				},
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Saga_24_G2_Entra" } } },
}
