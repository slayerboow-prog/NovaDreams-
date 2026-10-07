-- Mapa del guion reescrito de Uni01_PrimerDia (lo lee scripts/audit/aplicar-reescritura.luau).
-- El guion es sobre todo un documento de diseño (8 PASO); el juego tiene 14 pasos: la despedida, el
-- autobús, el campus (Uni01_Campus), la matrícula (Estudios), secretaría, la facultad, Beltrán, la primera
-- clase, descubrir el campus, la comida (ComidaUni) y la noche con los mensajes (Uni01_Mensajes).
-- Lo que trae frases son los mensajes de Pip (PASO 6-7): van en una escena nueva justo después de los
-- mensajes del grupo (que se quedan como estaban). El resto ya lo cuenta el juego.
return {
	Prefijo = "Uni01",
	Pasos = { ["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false, ["6"] = "14", ["7"] = "14", ["8"] = false },
	Despues = { "14" },
	-- («preparado» es lo que dejó Cosme, no el jugador)
	SinGenero = { "Algo que dejó preparado antes de desaparecer." },
	Informe = "La mecánica es la de siempre (los 14 pasos del primer día). El guion nuevo es sobre todo un documento de diseño (NPC del campus, orientación, el aula 204 con un acceso cerrado…): eso ya lo cuentan el campus, secretaría, la facultad, Beltrán y la comida del juego, y no se crean pasos nuevos. Lo que sí trae frases son los mensajes de Pip sobre Cosme (PASO 6-7): salen en una escena nueva justo después de los mensajes del grupo (Uni01_Mensajes, que no cambia). Pendiente para el autor: la orientación con NPC dinámicos y ayudar a otro estudiante (ayudo_nuevo_estudiante) necesitarían pasos nuevos.",
}
