-- MissionIndex: la lista de misiones episódicas (un archivo por misión en Misiones/).
-- Para añadir una misión: crear su archivo y añadirlo aquí. Un archivo puede devolver una misión
-- o una lista de misiones (consecuencias y secundarias pequeñas).
-- Formato y reglas de diseño: docs/historia/11-misiones-episodicas.md

local Misiones = script.Parent.Misiones

return {
	require(Misiones.Cole01_PrimerDia),
	require(Misiones.Cole02_Mochila),
	require(Misiones.Cole03_Grupo),
	require(Misiones.Cole04_Malotes),
	require(Misiones.Cole05_Venganza),
	require(Misiones.Cole06_Examen),
	require(Misiones.Cole07_Excursion),
	require(Misiones.Cole08_Torneo),
	require(Misiones.Cole09_Misterio),
	require(Misiones.Cole_Consecuencias),
}
