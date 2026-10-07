-- Mapa del guion reescrito de Adu01_PrimerContrato (lo lee scripts/audit/aplicar-reescritura.luau).
-- Los PASO del guion llevan el número del paso del juego (21 pasos; el guion no tiene los 12-14, los
-- turnos de cada trabajo, que se quedan como estaban).
return {
	Prefijo = "Adu01",
	Pasos = {
		["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5", ["6"] = "6", ["7"] = "7", ["8"] = "8",
		["9"] = "9", ["10"] = "10", ["11"] = "11", ["15"] = "15", ["16"] = "16", ["17"] = "17", ["18"] = "18",
		["19"] = "19", ["20"] = "20", ["21"] = "21",
	},
	-- (cada jefe habla solo en su trabajo: la escena del primer turno es la misma para los tres)
	CondicionHablante = {
		Lola = { Choices = { Empleo = "Barista" } },
		Omar = { Choices = { Empleo = "Barista" } },
		Paco = { Choices = { Empleo = "Reponedor" } },
		Ernesto = { Choices = { Empleo = "Repartidor" } },
	},
	Variables = {
		["ruta medicina"] = { If = { Choices = { Estudios = "Medicina" } } },
		["ruta ingenieria"] = { If = { Choices = { Estudios = "Ingenieria" } } },
		["ruta derecho"] = { If = { Choices = { Estudios = "Derecho" } } },
		["ruta economia"] = { If = { Choices = { Estudios = "Economia" } } },
		["ruta barista"] = { If = { Choices = { Empleo = "Barista" } } },
		["ruta reponedor"] = { If = { Choices = { Empleo = "Reponedor" } } },
		["ruta repartidor"] = { If = { Choices = { Empleo = "Repartidor" } } },
		["llega tarde"] = { If = { Flags = { "LlegasTardeContrato" } } },
		["llego tarde a practicas"] = { If = { Flags = { "LlegasTardePracticas" } } },
	},
	Informe = "La mecánica es la de siempre: quedarte una casa libre (el sistema de casas de siempre: cartel «Se vende»), el primer día (en tu sitio de prácticas o con Lola, Paco o Ernesto), las cinemáticas Adu01_PrimerDia, Adu01_Firma, Adu01_PrimerTurno y Adu01_Buzon, el contrato, el primer caso o el turno de encargado/a, las facturas, el presupuesto con Ignacio en el banco y la llamada de casa. El sueldo y las facturas van por la economía de siempre (sin cambiar cantidades). Elegir entre tres casas o una pantalla de presupuesto nueva serían sistemas nuevos: se queda la versión del juego (pendiente).",
}
