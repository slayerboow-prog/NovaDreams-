-- Mapa del guion reescrito de Saga_04_Ventanilla (lo lee scripts/audit/aplicar-reescritura.luau).
-- El juego tiene 5 pasos (todos conversaciones): 1 el agente Cronos y la multa, 2 ventanilla de Correos,
-- 3 ventanilla del banco, 4 la comisaría (Inés y su sello) y 5 vuelta al garaje con el formulario.
-- El guion cuenta UNA ventanilla dimensional con su empleado (6 PASO): sus frases van a las ventanillas
-- del juego (el empleado = la funcionaria, que «está en todas las ventanillas») y el final, al garaje.
-- La multa de Cronos (paso 1) y la comisaría (paso 4, con su decisión) se quedan como estaban: el guion
-- no los tiene y la estructura de la misión no cambia.
return {
	Prefijo = "Saga_04",
	-- (el final del guion —llegan Cosme y Pip y se cierra la ventanilla— va con la ventanilla del banco; la
	-- vuelta al garaje con Cronos se queda: allí Cronos cuenta que «alguien del otro lado tira» de la Grieta
	-- hacia ti, la pista del Ancla que usa la saga)
	Pasos = { ["1"] = "2", ["2"] = "2", ["3"] = "3", ["4"] = "3", ["5"] = "3", ["6"] = "3" },
	Hablantes = { EMPLEADO = "Funcionaria", Empleado = "Funcionaria", ["TÚ"] = "Yo", ["Tú"] = "Yo", NPC = "@Vecino", ["Otro NPC"] = "@Vecino" },
	Variables = {
		-- («¿Conoce a un inventor llamado Cosme?» Sí: claro que le conoces)
		["sí"] = { If = {} },
		si = { If = {} },
	},
	Informe = "La estructura es la de siempre (5 conversaciones: la multa del agente Cronos, Correos, el banco, la comisaría y el garaje). El guion cuenta una sola ventanilla dimensional con un empleado: el empleado es la funcionaria del juego (la que «está en todas las ventanillas»), sus PASO 1-2 van a la ventanilla de Correos, y los PASO 3-6 (el problema, la ventanilla que se descontrola, llegan Cosme y Pip y se cierra) a la del banco. La multa de Cronos (paso 1), la comisaría de Inés (paso 4, con su decisión) y la vuelta al garaje con Cronos (paso 5: «alguien del otro lado tira de la Grieta hacia ti», la pista del Ancla que usa la saga) no están en el guion y se quedan como estaban. Pendiente para el autor: que el guion encaje con el agente Cronos y las tres ventanillas, o cambiar la misión (eso ya no es solo texto).",
}
