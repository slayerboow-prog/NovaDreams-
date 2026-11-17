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
				{ S = "Glub", T = "Agente Glub, del Banco Galáctico. Hemos recibido un informe contable impecable.", To = "Yo" },
				{ S = "Glub", T = "Firmado por un tal Escamas. Lleva años intentando que alguien le escuchara.", To = "Yo" },
				{
					S = "Glub",
					T = "Nos conocemos. Usted se negó a pagar una deuda que no era suya. Lo recuerdo.",
					To = "Yo",
					If = { Flags = { "DeudaGalactica" } },
				},
				{
					S = "Glub",
					T = "El Consorcio MegaVerso queda intervenido. Cuentas congeladas en todos los mundos.",
					To = "Yo",
					If = { Flags = { "DeudaGalactica" } },
				},
				{ S = "Glub", T = "El doctor Cósimo se queda sin financiación.", To = "Yo", If = { Flags = { "DeudaGalactica" } } },
				{
					S = "Brenn",
					T = "Hemos derribado a una corporación que compraba mundos. Con una memoria y una puerta de servicio.",
					To = "Yo",
					If = { Flags = { "DeudaGalactica" } },
				},
				{
					S = "Sorel",
					T = "Sin dinero, Cósimo solo tiene una salida: hacer la Fusión él solo. Y rápido.",
					To = "Yo",
					If = { Flags = { "DeudaGalactica" } },
				},
				{ S = "Sorel", T = "Viene a por el Ancla. Ahora sí.", To = "Yo", If = { Flags = { "DeudaGalactica" } } },
			},
		},
		Servidor = {
			Lines = {
				{ S = "Narrador", T = "Conectas la memoria de Escamas al servidor central. Las cuentas del Consorcio llenan todas las pantallas." },
				{ S = "Brenn", T = "Mundos comprados por debajo de su precio después de cada Caída. Decenas.", To = "Yo" },
				{ S = "Sorel", T = "Y una transferencia enorme: «Laboratorio Dr. Cósimo. Proyecto Fusión».", To = "Yo" },
				{ S = "Sorel", T = "Es lo que viste en su oficina. Ahora con las cifras.", To = "Yo", If = { Memories = { "ProyectoFusion" } } },
			},
		},
	},
	Scenes = {
		Saga_21_G1_Fin = {
			Light = true,
			Duration = 14.8,
			Anchors = { Sitio = "Player", Yo = "Player" },
			Tracks = {
				Actors = { { At = 0, Use = { Key = "AgenteGris2", Npc = "AgenteGris2" } }, { At = 0, Use = { Key = "Sorel", Npc = "Sorel" } } },
				Dialogue = {
					{ At = 0.4, S = "Sorel", T = "Seguridad del Consorcio en la entrada. Sin bajas si se puede. Con bajas si no queda otra.", To = "Yo" },
					{
						At = 7.6,
						S = "AgenteGris2",
						T = "Por la puerta de servicio. Yo os abro. Me lo debéis. Y yo os lo debo a vosotros.",
						To = "Yo",
						If = { Flags = { "GrisArrepentida" } },
					},
				},
			},
		},
	},
	Steps = { ["1"] = { Effects = { Scene = "Saga_21_G1_Fin" } } },
}
