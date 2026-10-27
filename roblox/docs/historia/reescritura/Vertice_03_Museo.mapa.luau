-- Mapa del guion de Vertice_03_Museo (lo lee scripts/audit/aplicar-reescritura.luau).
-- 6 pasos: 1 Abril, 2 colarse (Escape), 3 la placa, el archivo y el terminal (Group de tres Use), 4 copiar el
-- archivo (minijuego), 5 la cuenta (Choice VerticeCuenta), 6 la salida con Abril.
return {
	Prefijo = "Vertice3",
	Pasos = {
		["1"] = 1,
		["2"] = "3.1",
		["3"] = "3.2",
		["4"] = "3.3",
		["5"] = 6,
	},
	Dialogos = { ["2"] = "Placa", ["3"] = "Archivo", ["4"] = "Terminal" },
	Variables = {
		cuenta_limpia = { Flag = "VerticeCuentaLimpia" },
		dinero_cuenta = { Flag = "VerticeDineroCuenta" },
	},
	Informe = "Saga 2 · Vértice. La mecánica es la de siempre: Abril, colarse en el Museo esquivando a la seguridad, los tres objetos del archivo, copiar los datos (minijuego), la decisión de la cuenta (VerticeCuenta: Money 300 si te la quedas) y la salida, con una frase distinta según lo que elegiste.",
}
