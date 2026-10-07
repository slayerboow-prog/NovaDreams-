-- Mapa del guion reescrito de Adulto_PrimerSueldo (lo lee scripts/audit/aplicar-reescritura.luau).
-- El juego tiene UN paso: «Busca un cartel de SE BUSCA y trabaja (0/3)» (el tablón de trabajo de siempre,
-- con su sueldo por la economía de siempre). El guion lo convierte en entrevista + contrato + tres tareas +
-- sueldo + decisión de gasto: eso serían pasos y sistemas nuevos (entrevista, clasificar, la ruta de tres
-- entregas, la decisión de gasto, reputacion_laboral), así que la mecánica no cambia y del guion salen
-- las frases que caben al terminar el turno: Ernesto al acabar y Lola con tu primer sueldo.
return {
	Prefijo = "Adulto_Sueldo",
	Lineas = { ["1"] = { { 514, 565 }, { 676, 700 } } },
	Hablantes = { PROTAGONISTA = "Yo" },
	Variables = {
		-- (el juego no mide el desempeño del turno: sale la versión buena, que nunca bloquea)
		["buen desempeno"] = { If = {} },
		["desempeno medio"] = { Nunca = true },
		["desempeno bajo"] = { Nunca = true },
	},
	Informe = "La mecánica es la de siempre: un paso, «Busca un cartel de SE BUSCA y trabaja (0/3)», con el tablón de trabajo y el sueldo de siempre (una vez, por la economía del juego). El guion nuevo (entrevista con Ernesto en Correos, contrato, tres tareas —clasificar, una ruta con tres entregas, arreglar un error—, el primer sueldo y la decisión de en qué gastarlo) necesitaría pasos y sistemas nuevos: queda pendiente para el autor. Del guion salen las frases del final del turno (Ernesto) y las de Lola cuando le enseñas tu primer sueldo. El perro de Ernesto, que el guion llama «Bruno», sería «Trufa» para no confundirlo con Bruno (sus frases no salen en esta versión). reputacion_laboral no existe: no se crea. Sin referencias a la infancia. Adulto_ConoceLaRegion se desbloquea como ahora.",
}
