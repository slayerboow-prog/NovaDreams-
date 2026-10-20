-- GUION REESCRITO de Saga_21_Consorcio (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_21_Consorcio.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_21_Consorcio
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_21_Consorcio.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_21_Consorcio.md",
	Dialogues = {
		Quiebra = {
			Lines = {
				{ S = "Ivan", T = "¿Planta del servidor?", To = "Yo", A = "Ask" },
				{ S = "Candela", T = "Subterráneo.", To = "Yo", A = "Happy" },
				{ S = "Ivan", T = "Claro. Porque siempre está debajo.", To = "Yo", A = "Nod" },
				{ S = "DonEscamas", T = "Es donde guardan las cosas importantes. Trátalo con cuidado.", To = "Yo", A = "Happy" },
				{ S = "DonEscamas", T = "Tiene información sensible.", To = "Yo", Pause = 0.9 },
				{ S = "Candela", T = "Aquí está.", To = "Yo", G = "Point", Pause = 0.9 },
				{ S = "Ivan", T = "¿Qué?", To = "Yo", A = "Surprised" },
				{ S = "Candela", T = "La financiación.", To = "Yo", A = "Nod" },
				{ S = "Candela", T = "Es lo que viste en su ordenador de la oficina.", To = "Yo", If = { Memories = { "ProyectoFusion" } } },
				{ S = "Candela", T = "Ahora tenemos los importes.", To = "Yo", Pause = 0.9, If = { Memories = { "ProyectoFusion" } } },
				{ S = "Ivan", T = "¿Todo esto para abrir una Grieta?", To = "Yo", A = "Ask" },
				{ S = "Candela", T = "Todo esto para controlar dos mundos.", To = "Yo", A = "Nod" },
				{ S = "Ivan", T = "Yo con este dinero habría comprado muchos zumos.", To = "Yo", A = "Happy" },
				{ S = "Candela", T = "Iván.", To = "Yo", A = "ThinkChin" },
				{ S = "Ivan", T = "Muchos.", To = "Yo", A = "Nod" },
				{ S = "DonEscamas", T = "Ahora. Solo hay que dejar que hagan su trabajo.", To = "Yo", A = "Nervous" },
				{ S = "Glub", T = "Agente Glub. Banco Galáctico.", To = "Yo" },
				{ S = "Glub", T = "Hemos recibido un chivatazo contable impecable.", To = "Yo" },
				{ S = "Glub", T = "Firmado por un tal D. Escamas.", To = "Yo" },
				{ S = "Glub", T = "Muy buena caligrafía para ser un pez.", To = "Yo", Pause = 0.9 },
				{ S = "Glub", T = "¿Nos conocemos? Usted leyó la letra pequeña.", To = "Yo", If = { Flags = { "DeudaGalactica" } } },
				{ S = "Glub", T = "MegaVerso S.A. queda intervenida. Cuentas congeladas. Otra. Activos bloqueados. Otra.", To = "Yo" },
				{ S = "Glub", T = "Operaciones suspendidas. Sellado. Sellado. Y sellado.", To = "Yo" },
				{ S = "Ivan", T = "¡Hemos arruinado una multinacional malvada!", To = "Yo", A = "ThinkChin" },
				{ S = "Ivan", T = "¡Con un pendrive con forma de pez!", To = "Yo" },
				{ S = "Ivan", T = "¡Esto hay que ponerlo en el currículum!", To = "Yo" },
				{ S = "Candela", T = "El equipo de rescate. Versión asalto.", To = "Yo", A = "Happy", If = { Memories = { "EquipoRescate" } } },
				{ S = "Candela", T = "Funciona igual de bien.", To = "Yo", If = { Memories = { "EquipoRescate" } } },
				{ S = "Candela", T = "Sin dinero, Cósimo solo tiene una opción.", To = "Yo" },
				{ S = "Candela", T = "Hacer la Fusión él solo. Y rápido. Viene a por el Ancla. Ahora sí.", To = "Yo", Pause = 0.9 },
			},
		},
		Servidor = {
			Lines = {
				{ S = "Candela", T = "Tres entradas. Dos guardias.", To = "Yo", A = "Nod" },
				{ S = "Candela", T = "Y una opción sencilla.", To = "Yo" },
				{ S = "Ivan", T = "¿Cuál?", To = "Yo", A = "Ask" },
				{ S = "Candela", T = "No llamar la atención.", To = "Yo", A = "No" },
				{ S = "Ivan", T = "Creo que ya hemos fallado.", To = "Yo", A = "Nod" },
				{ S = "Candela", T = "¿Y cómo sabes eso? Porque antes era parte del problema.", To = "Yo", A = "Ask", If = { Flags = { "GrisArrepentida" } } },
				{ S = "Candela", T = "Ahora quiero arreglarlo.", To = "Yo", Pause = 0.9, If = { Flags = { "GrisArrepentida" } } },
				{ S = "Candela", T = "Ya está.", To = "Yo", A = "Nod" },
				{ S = "Ivan", T = "¿Ya está?", To = "Yo", A = "Ask" },
				{ S = "Candela", T = "Ahora viene lo difícil.", To = "Yo", A = "ThinkChin" },
				{ S = "DonEscamas", T = "Servidor.", To = "Yo", A = "Nervous" },
			},
		},
	},
	Scenes = {},
	Steps = {},
}
