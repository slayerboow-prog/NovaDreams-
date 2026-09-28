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
	require(Misiones.Pan1_MalasCompanias),
	require(Misiones.Pan2_LaNoche),
	require(Misiones.Pan3_Cruce),
	require(Misiones.Pan_Consecuencias),
	require(Misiones.Ins04_PrimerEmpleo),
	require(Misiones.Ins05_ElRumor),
	require(Misiones.Ins06_LaGranDecision),
	require(Misiones.Uni01_PrimerDia),
	require(Misiones.Uni_Vida), -- la residencia y el ciclo de exámenes (misiones principales)
	require(Misiones.Uni_Secundarias), -- fiestas, acampada, playa, zumo de mora, cita, lugares abandonados…
	require(Misiones.Uni02_ElProyecto),
	require(Misiones.Uni03_PrimerTrabajo),
	require(Misiones.Uni04_Practicas),
	require(Misiones.Uni05_PrimerPiso),
	require(Misiones.Uni06_Graduacion),
	require(Misiones.Adu01_PrimerContrato),
	require(Misiones.Adu02_Atardecer),
	require(Misiones.Adu03_Reencuentro),
	require(Misiones.Adu_Consecuencias),
	require(Misiones.Uni_Consecuencias),
	require(Misiones.Ins_Consecuencias),
	require(Misiones.Cole_Consecuencias),
	-- Misiones locas (secundarias de cada etapa, con Cosme): docs/historia/12-misiones-locas.md
	require(Misiones.Loco_Nino),
	-- La Saga de la Grieta (historia principal canónica): docs/historia/13-saga-de-la-grieta.md
	require(Misiones.Saga_Acto1),
	require(Misiones.Saga_Acto2),
	require(Misiones.Saga_Acto3),
	require(Misiones.Saga_Acto4),
	require(Misiones.Loco_Adolescente),
	require(Misiones.Loco_Uni),
	require(Misiones.Loco_Adulto),
}
