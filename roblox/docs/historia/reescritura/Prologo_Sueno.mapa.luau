-- Mapa del guion reescrito de Prologo_Sueno (lo lee scripts/audit/aplicar-reescritura.luau).
-- Los 9 PASO del guion son los 9 pasos del juego, en el mismo orden (no hace falta Pasos).
return {
	Prefijo = "Prologo",
	Sujetos = {
		-- La isla del sueño es «Valmar» en el sueño: los planos generales van sobre ella
		Valmar = "Grande:PrologoInicio",
		Ciudad = "Grande:PrologoInicio",
		Entorno = "Grande:PrologoInicio",
		Camino = "Lugar:PrologoCamino",
		["Garaje"] = "Lugar:PrologoPuerta",
		["Garaje de Cosme"] = "Lugar:PrologoPuerta",
		["Camino al garaje"] = "Lugar:PrologoPuerta",
		Silueta = "Cosme",
		Tornillo = "Lugar:PrologoTornillo",
		["Tornillo brillante"] = "Lugar:PrologoTornillo",
	},
	-- El cierre conserva los tres rótulos que explican los tipos de misión (tutorial)
	Rotulos = { ["9"] = "Prologo_Cierre" },
	Informe = "Nota: en el juego el paso 8 del prólogo es «Abre el mapa de Valmar» (enseña la tecla M); el guion lo escribió como «abrir la puerta del garaje». Se conserva el paso del mapa (es el tutorial del control) y las frases del PASO 8 suenan al llegar a la puerta (al cumplir el paso 7).",
}
