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
	require(Misiones.Cole10_Festival),
	require(Misiones.Cole11_Proyecto),
	require(Misiones.Cole12_UltimoDia),
	require(Misiones.Ins01_NuevoInstituto),
	require(Misiones.Ins02_Clubes),
	require(Misiones.Ins03_QueQuieresSer),
	require(Misiones.Ins04_PrimerEmpleo),
	require(Misiones.Ins05_ElRumor),
	require(Misiones.Ins06_LaGranDecision),
	require(Misiones.Uni01_PrimerDia),
	require(Misiones.Uni02_ElProyecto),
	require(Misiones.Uni03_PrimerTrabajo),
	require(Misiones.Uni_Consecuencias),
	require(Misiones.Ins_Consecuencias),
	require(Misiones.Cole_Consecuencias),
}
