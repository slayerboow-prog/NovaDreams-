-- GUION REESCRITO de Saga_08_MegaVerso (GENERADO: no se edita a mano).
-- Fuente: docs/historia/reescritura/Saga_08_MegaVerso.md · se regenera con: lune run scripts/audit/aplicar-reescritura.luau Saga_08_MegaVerso
-- Formato: shared/LifeStory/GuionOverlay.luau · informe: docs/historia/reescritura/Saga_08_MegaVerso.informe.md

local V = Vector3.new
local _ = V

return {
	Source = "docs/historia/reescritura/Saga_08_MegaVerso.md",
	Dialogues = {
		Folleto = {
			Lines = {
				{ S = "Narrador", T = "¿Tu mundo se rompe? MegaVerso lo une a otro más estable. Más seguridad. Más futuro." },
				{ S = "Narrador", T = "Letra pequeña: «El mundo fusionado pasa a ser propiedad del Consorcio y de su socio científico, el Dr. C.»." },
			},
		},
		Fuera = {
			Lines = {
				{ S = "Narrador", T = "Llegas a la plaza sin aliento. Detrás de ti, la puerta del Consorcio se cierra sola." },
				{ S = "Narrador", T = "En el cristal, el reflejo de un hombre con la cara de Cosme y una cicatriz sonríe un segundo y desaparece." },
				{ S = "Narrador", T = "Te llevas un folleto. Cosme tiene que verlo. Y tiene que contarte qué es el Ancla. Hoy." },
			},
		},
		Mapa = {
			Lines = {
				{
					S = "Narrador",
					T = "Un mapa del Distrito Central con tres marcas rojas: el parque, el patio de la Academia y la plaza. Los anclajes de la aguja. Todos tachados.",
				},
				{ S = "Narrador", T = "Y una marca dorada sobre tu casa. Con una etiqueta: «ANCLA»." },
				{ S = "AgenteGris2", T = "Visitante no autorizado detectado. Por favor, permanezca donde está.", To = "Yo" },
			},
		},
		Ordenador = {
			Lines = {
				{ S = "Narrador", T = "Un informe: «Proyecto Fusión. Valmar (dimensión principal) + Valmar (dimensión 66-B). Estado: bloqueado»." },
				{ S = "Narrador", T = "«Motivo del bloqueo: el Ancla. Fecha prevista de desbloqueo: ceremonia de rango de la Academia»." },
				{ S = "Yo", T = "La ceremonia de la Academia. Es la mía." },
			},
		},
		Recepcion = {
			Lines = {
				{
					Ask = "¿Qué le dices?",
					Options = {
						{
							T = "«Vengo a informarme. Mi familia quiere irse de Valmar.»",
							Effects = { Traits = { Curiosidad = 1 } },
							Then = { { S = "AgenteGris2", T = "Una decisión inteligente. Sírvase usted mismo los folletos. Un asesor le atenderá enseguida." } },
						},
						{
							T = "Enseñas la credencial de ayudante de Cosme",
							Effects = { Flags = { "EnseñasteCredencial" }, Traits = { Valentia = 1 } },
							Then = { { S = "AgenteGris2", T = "Laboratorio Cosme. …Un momento, por favor. Tengo que consultarlo. No se mueva de aquí." } },
						},
					},
				},
			},
		},
	},
	Scenes = {},
	Steps = { ["3"] = { Set = { Text = "Te han visto. Huye hasta la plaza del Distrito Financiero" } } },
}
