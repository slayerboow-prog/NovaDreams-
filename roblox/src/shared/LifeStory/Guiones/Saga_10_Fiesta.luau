-- GUION REESCRITO de Saga_10_Fiesta (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_10_Fiesta.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_10_Fiesta
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_10_Fiesta.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_10_Fiesta.md",
	Dialogues = {
		Amigos = {
			Lines = {
				{ S = "Sorel", T = "Mira esto. Música, comida gratis y una cola de doscientas personas para apuntarse a una «evacuación segura».", To = "Yo" },
				{ S = "Sorel", T = "Y esa pantalla: «Gran Fusión: faltan 90 días». La gente cree que es la fecha de salida de las naves.", To = "Yo" },
				{ S = "Sorel", T = "Mi vecina de antes se ha apuntado con sus tres hijos. No he sabido qué decirle.", To = "Yo" },
				{ S = "Yo", T = "No hay naves. Es la Fusión de las dos Valmar. Lo vi en su oficina." },
				{ S = "Sorel", T = "Entonces hay que pararlo. Dime qué hago. Te cubro.", To = "Yo" },
			},
		},
		Cabina = {
			Lines = {
				{ S = "Narrador", T = "La cabina emite un mensaje en bucle: «El Distrito Central no es segur{o/a}. El Consorcio sí»." },
				{ S = "Narrador", T = "Cambias la señal por la emisora de la Academia. Por los altavoces suena la voz de Kael: «Valmar no se abandona»." },
			},
		},
		Cuenta = {
			Lines = {
				{
					S = "Narrador",
					T = "Desconectas la cuenta atrás. Antes de apagarse, la pantalla muestra un segundo la cara de Cósimo: «Qué falta de educación».",
				},
			},
		},
		Final = {
			Lines = {
				{ S = "Nico", T = "La gente está devolviendo los billetes. Algunos están enfadados con nosotros. Otros, con ellos.", To = "Yo" },
				{ S = "Brenn", T = "Has hecho bien. Aunque mañana nos caiga una bronca de Kael por pelear en la plaza.", To = "Yo" },
				{ S = "Sorel", T = "Mi vecina me ha dado las gracias. No sabía de qué, pero me las ha dado.", To = "Yo" },
				{ S = "Sorel", T = "Oye. La ceremonia de rango de la Academia es dentro de poco. ¿Tiene algo que ver con esos números?", To = "Yo" },
				{ S = "Narrador", T = "No le contestas. Antes de apagarse, la cuenta atrás marcaba exactamente el día de la ceremonia." },
			},
		},
		Taquilla = {
			Lines = {
				{ S = "Narrador", T = "La máquina de inscripción guarda nombres, direcciones y fotos. Una lista larguísima." },
				{ S = "Narrador", T = "Borras la lista. La máquina pita y empieza a imprimir billetes en blanco." },
			},
		},
	},
	Scenes = {
		Saga_10_G3_Entra = {
			Light = true,
			Duration = 10,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "Sorel", Npc = "Sorel" } } },
				Dialogue = { { At = 0.4, S = "Sorel", T = "¡Nos han visto! Nico, Brenn, ¡ahora!", To = "Yo" } },
			},
		},
	},
	Steps = { ["2"] = { Effects = { Scene = "Saga_10_G3_Entra" } } },
}
