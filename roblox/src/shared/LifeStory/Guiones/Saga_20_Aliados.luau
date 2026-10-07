-- GUION REESCRITO de Saga_20_Aliados (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_20_Aliados.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_20_Aliados
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_20_Aliados.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_20_Aliados.md",
	Dialogues = {
		Bigotes = {
			Effects = { Flags = { "AliadoBigotes", "DuqueDeGatonia" } },
			Lines = {
				{ S = "Bigotes", T = "Has vuelto.", To = "Yo" },
				{ S = "Bigotes", T = "Y tienes cara de necesitar un ejército.", To = "Yo", Pause = 0.9 },
				{ S = "Bigotes", T = "Un ejército no.", To = "Yo" },
				{ S = "Bigotes", T = "Pero puedo darte gatos.", To = "Yo", Pause = 0.9 },
				{ S = "Bigotes", T = "Le debemos una.", To = "Yo" },
				{ S = "Bigotes", T = "Y en Gatonia pagamos nuestras deudas.", To = "Yo" },
			},
		},
		Compis = {
			Lines = {
				{ S = "Ivan", T = "Sabía que volverías.", To = "Yo" },
				{ S = "Candela", T = "No.", To = "Yo" },
				{ S = "Candela", T = "Yo calculé que volvería.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Eso es lo mismo.", To = "Yo" },
				{ S = "Candela", T = "No.", To = "Yo" },
				{ S = "Cosme", T = "Necesitamos ayuda.", To = "Yo" },
				{ S = "Ivan", T = "¿Es peligroso?", To = "Yo" },
				{ S = "Cosme", T = "Bastante.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Entonces supongo que vamos.", To = "Yo" },
				{ S = "Candela", T = "Ya estaba preparada.", To = "Yo" },
			},
		},
		Cronos = {
			Effects = { Flags = { "AliadoCronos", "CronosAliado" } },
			Lines = {
				{ S = "CazadorTiempo", T = "El tiempo tiene una costumbre.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Siempre vuelve a pedir cuentas.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Entonces ha llegado la hora.", To = "Yo" },
				{ S = "CazadorTiempo", T = "No pienso dejar que Cósimo decida cuándo termina esta historia.", To = "Yo" },
			},
		},
		Lista = {
			Lines = {
				{ S = "Cosme", T = "El garaje está lleno de actividad.", To = "Yo" },
				{ S = "Cosme", T = "Llegas justo a tiempo.", To = "Yo" },
				{ S = "Cosme", T = "He hecho una lista.", To = "Yo" },
				{ S = "Pip", T = "La lista es considerablemente larga.", To = "Yo" },
				{ S = "Pip", T = "Está llena de nombres.", To = "Yo" },
				{ S = "Cosme", T = "La mitad no son humanos.", To = "Yo" },
				{ S = "Cosme", T = "Y uno es un gato.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Solo uno confirmado.", To = "Yo" },
				{ S = "Cosme", T = "No todos vendrán.", To = "Yo" },
				{ S = "Cosme", T = "Vendrán los que ayudaste.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Así funciona el universo.", To = "Yo" },
				{ S = "Cosme", T = "Lo que das, vuelve.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "A veces en forma de gato.", To = "Yo" },
				{ S = "Cosme", T = "Exactamente.", To = "Yo" },
			},
		},
		Malvado = {
			Effects = { Flags = { "AliadoMalvado", "ConoceTuMalvado" } },
			Lines = {
				{ S = "TuMalvado", T = "Sabía que vendrías.", To = "Yo" },
				{ S = "TuMalvado", T = "No sé por qué.", To = "Yo", Pause = 0.9 },
				{ S = "TuMalvado", T = "Supongo que porque yo también habría venido.", To = "Yo" },
				{ Ask = "¿Qué dices?", Options = { { T = "«Entonces ven con nosotros.»" }, { T = "«No tienes que hacerlo.»" } } },
				{ S = "TuMalvado", T = "Sí.", To = "Yo" },
				{ S = "TuMalvado", T = "Me apunto.", To = "Yo", Pause = 0.9 },
			},
		},
		Perez = {
			Lines = {
				{ S = "RatonPerez", T = "Me dijeron que había problemas.", To = "Yo" },
				{ S = "RatonPerez", T = "Y los problemas tienen dientes.", To = "Yo", Pause = 0.9 },
				{ S = "RatonPerez", T = "Así que vine preparad{o/a}.", To = "Yo" },
			},
		},
		Reunion = {
			Lines = {
				{ S = "Cosme", T = "Vaya.", To = "Yo" },
				{ S = "Cosme", T = "De verdad vinieron.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Te dijimos que sí.", To = "Yo" },
				{ S = "Candela", T = "Y además hemos llegado a tiempo.", To = "Yo" },
				{ S = "Cosme", T = "Los reuniste.", To = "Yo" },
				{ S = "Cosme", T = "A todos.", To = "Yo", Pause = 0.9 },
				{ S = "Bigotes", T = "Me ayudaste cuando no tenías por qué.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Las decisiones tienen memoria.", To = "Yo" },
				{ S = "Rex", T = "Nunca olvidé lo que hiciste.", To = "Yo" },
				{ S = "TuMalvado", T = "Supongo que esto es lo que hacen los buenos.", To = "Yo" },
				{ S = "DonEscamas", T = "Yo también tengo información.", To = "Yo" },
				{ S = "DonEscamas", T = "Tengo cuentas del MegaVerso.", To = "Yo" },
				{ S = "DonEscamas", T = "Y sé dónde esconden el dinero.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "¿Cómo sabes eso?", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Soy un pez.", To = "Yo" },
				{ S = "DonEscamas", T = "La gente habla delante de los peces.", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "También tengo algo más.", To = "Yo" },
				{ S = "DonEscamas", T = "El servidor central.", To = "Yo" },
				{ S = "Cosme", T = "¿El servidor?", To = "Yo" },
				{ S = "DonEscamas", T = "Si cae, cae el Consorcio.", To = "Yo" },
				{ S = "DonEscamas", T = "Y Cósimo pierde gran parte de su poder.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Entonces ya tenemos nuestro primer objetivo.", To = "Yo" },
				{ S = "Cosme", T = "Entramos.", To = "Yo" },
				{ S = "Ivan", T = "AliadosActivos = [", To = "Yo" },
				{ S = "Ivan", T = "Esto permitirá que diferentes partidas produzcan grupos distintos.", To = "Yo" },
				{ S = "Bigotes", T = "El día que Gatonia decidió devolverte el favor.", To = "Yo" },
			},
		},
		Rex = {
			Effects = { Flags = { "AliadoRex", "RexSeQueda" } },
			Lines = {
				{ S = "Rex", T = "¿Otra aventura?", To = "Yo" },
				{ S = "Rex", T = "Esta vez avisa antes de romper algo.", To = "Yo", Pause = 0.9 },
				{ S = "Rex", T = "Vale.", To = "Yo" },
				{ S = "Rex", T = "¿Cuándo salimos?", To = "Yo", Pause = 0.9 },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
