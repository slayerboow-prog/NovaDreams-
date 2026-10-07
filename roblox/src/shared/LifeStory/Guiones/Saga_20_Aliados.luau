-- GUION REESCRITO de Saga_20_Aliados (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_20_Aliados.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_20_Aliados
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_20_Aliados.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_20_Aliados.md",
	Dialogues = {
		Bigotes = {
			Lines = {
				{ S = "Bigotes", T = "Has vuelto. Y tienes cara de necesitar un ejército. Un ejército no.", To = "Yo" },
				{ S = "Bigotes", T = "Pero puedo darte gatos. Le debemos una.", To = "Yo", Pause = 0.9 },
				{ S = "Bigotes", T = "Y en Gatonia pagamos nuestras deudas.", To = "Yo" },
				{
					S = "Bigotes",
					T = "Y la Guardia Gatuna también, Canciller. Cuarenta gatos, cuarenta cajas. Ya ensayan el maullido de desprecio.",
					If = { Completed = { "Aliado_Bigotes" }, Flags = { "CancillerGatonia" } },
				},
			},
		},
		Compis = {
			Lines = {
				{ S = "Ivan", T = "Sabía que volverías.", To = "Yo" },
				{ S = "Candela", T = "No. Yo calculé que volvería.", To = "Yo" },
				{ S = "Ivan", T = "Eso es lo mismo.", To = "Yo" },
				{ S = "Candela", T = "No.", To = "Yo" },
				{ S = "Cosme", T = "Necesitamos ayuda.", To = "Yo" },
				{ S = "Ivan", T = "¿Es peligroso?", To = "Yo" },
				{ S = "Cosme", T = "Bastante.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "Entonces supongo que vamos.", To = "Yo" },
				{ S = "Candela", T = "Ya estaba preparada.", To = "Yo" },
				{
					S = "Candela",
					T = "El equipo de rescate, reunido otra vez. Esta vez con plan plastificado desde el principio.",
					To = "Ivan",
					If = { Flags = { "EquipoRescate" } },
				},
			},
		},
		Cronos = {
			Lines = {
				{ S = "CazadorTiempo", T = "El tiempo tiene una costumbre.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Siempre vuelve a pedir cuentas.", To = "Yo" },
				{ S = "CazadorTiempo", T = "Entonces ha llegado la hora.", To = "Yo" },
				{ S = "CazadorTiempo", T = "No pienso dejar que Cósimo decida cuándo termina esta historia.", To = "Yo" },
				{
					S = "CazadorTiempo",
					T = "Desde que cambié de bando, tu nombre sale en todas las páginas importantes.",
					If = { Memories = { "CronosAliado" } },
				},
				{
					S = "CazadorTiempo",
					T = "Y gracias a tu firma, mi expediente está limpio. Iré de uniforme. Con todos los sellos. Y esta vez, a la hora.",
					If = { Completed = { "Aliado_Cronos" }, Flags = { "CronosLimpio" } },
				},
			},
		},
		Lista = {
			Lines = {
				{ S = "Cosme", T = "Llegas justo a tiempo. He hecho una lista.", To = "Yo" },
				{
					S = "Cosme",
					T = "Lista de aliados. La he hecho con mis recuerdos nuevos. Bueno, viejos. Bueno, recuperados.",
					If = { Flags = { "CosmeRecuerda" } },
				},
				{ S = "Pip", T = "La lista es considerablemente larga.", To = "Yo" },
				{ S = "Pip", T = "Está llena de nombres.", To = "Yo" },
				{ S = "Cosme", T = "La mitad no son humanos. Y uno es un gato.", To = "Yo" },
				{ S = "DonEscamas", T = "Solo uno confirmado.", To = "Yo" },
				{ S = "Cosme", T = "No todos vendrán. Vendrán los que ayudaste.", To = "Yo" },
				{ S = "Cosme", T = "Así funciona el universo. Lo que das, vuelve.", To = "Yo" },
				{ S = "DonEscamas", T = "A veces en forma de gato.", To = "Yo" },
				{ S = "Cosme", T = "Exactamente.", To = "Yo" },
			},
		},
		Malvado = {
			Lines = {
				{ S = "TuMalvado", T = "Sabía que vendrías. No sé por qué.", To = "Yo" },
				{ S = "TuMalvado", T = "Supongo que porque yo también habría venido.", To = "Yo" },
				{ Ask = "¿Qué dices?", Options = { { T = "«Entonces ven con nosotros.»" }, { T = "«No tienes que hacerlo.»" } } },
				{ S = "TuMalvado", T = "Sí. Me apunto.", To = "Yo" },
				{
					S = "TuMalvado",
					T = "Te enseñé la rejilla del laboratorio. Fue mi primera buena acción. Me gustó. Un poco.",
					If = { Flags = { "MalvadoAyudo" } },
				},
				{
					S = "TuMalvado",
					T = "Además, ya sé pedir perdón y dar las gracias. Lo practico todos los días delante del espejo. Me da un asco… pero funciona.",
					If = { Completed = { "Aliado_Malvado" }, Flags = { "MalvadoAprendeBondad" } },
				},
			},
		},
		Perez = {
			Lines = {
				{ S = "RatonPerez", T = "Me dijeron que había problemas.", To = "Yo" },
				{ S = "RatonPerez", T = "Y los problemas tienen dientes.", To = "Yo", Pause = 0.9 },
				{ S = "RatonPerez", T = "Así que vine preparad{o/a}.", To = "Yo" },
				{
					S = "RatonPerez",
					T = "¿Una batalla? Tengo vacaciones gracias a ti. Mi ayudante, la rata, cubre el turno.",
					If = { Flags = { "RataContratada" } },
				},
				{
					S = "RatonPerez",
					T = "Y el sindicato ya ha votado. La patrulla lleva una semana roendo cables de MegaVerso. Nos hemos guardado los mejores para el sábado.",
					If = { Completed = { "Aliado_Perez" }, Flags = { "PatrullaRatones" } },
				},
			},
		},
		Reunion = {
			Lines = {
				{ S = "Cosme", T = "Vaya. De verdad vinieron.", To = "Yo" },
				{ S = "Ivan", T = "Te dijimos que sí.", To = "Yo" },
				{ S = "Candela", T = "Y además hemos llegado a tiempo.", To = "Yo" },
				{ S = "Cosme", T = "Los reuniste. A todos.", To = "Yo" },
				{
					S = "Narrador",
					T = "Sobre el garaje pasa una nave con un cartel luminoso: «FINAL DE TEMPORADA · EN DIRECTO». La Capitana Ñoz saluda con las cuatro manos.",
					If = { Completed = { "Aliado_Noz" }, Flags = { "NaveEnElFinal" } },
				},
				{ S = "Bigotes", T = "Me ayudaste cuando no tenías por qué.", To = "Yo", If = { Flags = { "AliadoBigotes" } } },
				{ S = "CazadorTiempo", T = "Las decisiones tienen memoria.", To = "Yo", If = { Flags = { "AliadoCronos" } } },
				{ S = "Rex", T = "Nunca olvidé lo que hiciste.", To = "Yo", If = { Flags = { "AliadoRex" } } },
				{ S = "TuMalvado", T = "Supongo que esto es lo que hacen los buenos.", To = "Yo", If = { Flags = { "AliadoMalvado" } } },
				{ S = "DonEscamas", T = "Yo también tengo información.", To = "Yo" },
				{ S = "DonEscamas", T = "Tengo cuentas del MegaVerso.", To = "Yo" },
				{ S = "DonEscamas", T = "Y sé dónde esconden el dinero.", To = "Yo", Pause = 0.9 },
				{ S = "Ivan", T = "¿Cómo sabes eso?", To = "Yo", Pause = 0.9 },
				{ S = "DonEscamas", T = "Soy un pez. La gente habla delante de los peces.", To = "Yo" },
				{ S = "DonEscamas", T = "También tengo algo más. El servidor central.", To = "Yo" },
				{ S = "Cosme", T = "¿El servidor?", To = "Yo" },
				{ S = "DonEscamas", T = "Si cae, cae el Consorcio.", To = "Yo" },
				{ S = "DonEscamas", T = "Y Cósimo pierde gran parte de su poder.", To = "Yo", Pause = 0.9 },
				{ S = "Cosme", T = "Entonces ya tenemos nuestro primer objetivo. Entramos.", To = "Yo" },
			},
		},
		Rex = {
			Lines = {
				{ S = "Rex", T = "¿Otra aventura? Esta vez avisa antes de romper algo. Vale. ¿Cuándo salimos?", To = "Yo" },
				{
					S = "Rex",
					T = "Además, ya le ganamos un juicio al Consorcio. Si Cósimo protesta, le pongo una demanda. Y luego le muerdo. En ese orden.",
					If = { Completed = { "Aliado_Rex" }, Flags = { "RexAbogado" } },
				},
			},
		},
	},
	Scenes = {},
	Steps = {},
}
