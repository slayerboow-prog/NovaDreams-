-- MissionIndex: la lista de misiones episódicas (un archivo por misión en Misiones/).
-- Para añadir una misión: crear su archivo y añadirlo aquí. Un archivo puede devolver una misión
-- o una lista de misiones (consecuencias y secundarias pequeñas).
-- Formato y reglas de diseño: docs/historia/11-misiones-episodicas.md

local Misiones = script.Parent.Misiones

-- (18-11-2026, el dueño: «la historia es muy infantil; tiene que ser para chicos de 15 años para arriba») Las misiones
-- de la vida de antes del cambio a guerrero espacial (colegio, instituto, universidad, adulto, las «misiones locas»,
-- las rarezas, el metro, los aliados de la saga vieja) quedan RETIRADAS: siguen cargadas (las partidas viejas y las
-- pruebas no se rompen), pero ya no se ofrecen ni empiezan solas (Services/LifeStoryService: canOffer). También
-- la Saga de la Grieta de antes (con humor absurdo): la sustituye «La Grieta: Proyecto Umbral» (Misiones/Grieta_Umbral).
local function retire(entry: any): any
	local list = if type(entry) == "table" and entry.Id then { entry } else entry
	for _, quest in list do
		if type(quest) == "table" then
			quest.Retired = true
		end
	end
	return entry
end

return {
	require(Misiones.Prologo_Sueno), -- el prólogo jugable (apagado desde el 17-11-2026: Config.Prologue)
	require(Misiones.Academia), -- la Academia de Guerreros: el tutorial y las habilidades (el juego empieza aquí)
	require(Misiones.Guerrero), -- después del juramento: patrullas, el primer despegue, el primer planeta y el ascenso
	require(Misiones.Reconquista), -- la Reconquista: recuperar la tierra perdida, zona a zona, fuera de la empalizada
	require(Misiones.Asentamiento_Encargos), -- encargos del asentamiento: secundarias de la Valmar de después de la Caída
	require(Misiones.Grieta_Umbral), -- la Grieta: Proyecto Umbral (la historia principal después de la Reconquista)
	require(Misiones.Coalicion_Marea), -- Acto II «La Coalición»: la Marea Gris (Valmar) y Tefra (docs/historia/historia-principal-15h.md)
	require(Misiones.Coalicion_Mundos1), -- Acto II: Miasma, Siroco y Nivalis
	retire(require(Misiones.Cole01_PrimerDia)),
	retire(require(Misiones.Cole02_Mochila)),
	retire(require(Misiones.Cole03_Grupo)),
	retire(require(Misiones.Cole04_Malotes)),
	retire(require(Misiones.Cole05_Venganza)),
	retire(require(Misiones.Cole06_Examen)),
	retire(require(Misiones.Cole07_Excursion)),
	retire(require(Misiones.Cole08_Torneo)),
	retire(require(Misiones.Cole09_Misterio)),
	retire(require(Misiones.Cole10_Festival)),
	retire(require(Misiones.Cole11_Proyecto)),
	retire(require(Misiones.Cole12_UltimoDia)),
	retire(require(Misiones.Ins01_NuevoInstituto)),
	retire(require(Misiones.Ins02_Clubes)),
	retire(require(Misiones.Ins03_QueQuieresSer)),
	retire(require(Misiones.Pan1_MalasCompanias)),
	retire(require(Misiones.Pan2_LaNoche)),
	retire(require(Misiones.Pan3_Cruce)),
	retire(require(Misiones.Pan_Consecuencias)),
	retire(require(Misiones.Ins04_PrimerEmpleo)),
	retire(require(Misiones.Ins05_ElRumor)),
	retire(require(Misiones.Ins06_LaGranDecision)),
	retire(require(Misiones.Uni01_PrimerDia)),
	retire(require(Misiones.Uni_Vida)), -- la residencia y el ciclo de exámenes (misiones principales)
	retire(require(Misiones.Uni_Secundarias)), -- fiestas, acampada, playa, zumo de mora, cita, lugares abandonados…
	retire(require(Misiones.Uni02_ElProyecto)),
	retire(require(Misiones.Uni03_PrimerTrabajo)),
	retire(require(Misiones.Uni04_Practicas)),
	retire(require(Misiones.Uni05_PrimerPiso)),
	retire(require(Misiones.Uni06_Graduacion)),
	retire(require(Misiones.Adu01_PrimerContrato)),
	retire(require(Misiones.Adu02_Atardecer)),
	retire(require(Misiones.Adu03_Reencuentro)),
	retire(require(Misiones.Adu_Consecuencias)),
	retire(require(Misiones.Uni_Consecuencias)),
	retire(require(Misiones.Ins_Consecuencias)),
	retire(require(Misiones.Cole_Consecuencias)),
	-- Misiones locas (secundarias de cada etapa, con Cosme): docs/historia/12-misiones-locas.md
	retire(require(Misiones.Loco_Nino)),
	-- La Saga de la Grieta (historia principal canónica): docs/historia/13-saga-de-la-grieta.md
	retire(require(Misiones.Saga_Acto1)),
	retire(require(Misiones.Saga_Acto2)),
	retire(require(Misiones.Saga_Acto3)),
	retire(require(Misiones.Saga_Acto4)),
	-- Rarezas de la Grieta (secundarias cortas que dan los «Restos de la Grieta»)
	retire(require(Misiones.Rarezas)),
	retire(require(Misiones.Loco_Adolescente)),
	retire(require(Misiones.Loco_Uni)),
	retire(require(Misiones.Loco_Adulto)),
	-- Misiones de aliados: cada aliado de la saga vuelve antes del final (saga 20)
	retire(require(Misiones.Aliados)),
	-- Metro de Valmar: secundarias que se hacen viajando en metro
	retire(require(Misiones.Metro_Secundarias)),
	-- Invasión de la Grieta: lo que tu historia recuerda del evento global (docs/invasion.md)
	require(Misiones.Invasion),
	-- Saga 2 «Ragnarock» · Tefra: el episodio 1 «Ceniza en Bastión» y sus cadenas secundarias
	-- (solo en el planeta: Requires.Planet; docs/planetas/tefra-misiones.md)
	require(Misiones.Tefra_Episodio),
	require(Misiones.Tefra_Cadenas),
	-- Saga 2 · Miasma (Anclaje Siete) y Siroco (Puerto Calcina): su primera parte jugable (marco común de los
	-- planetas: docs/planetas/marco-planetas.md; solo en su planeta: Requires.Planet)
	require(Misiones.Miasma_Episodio),
	require(Misiones.Siroco_Episodio),
	-- Saga 2 · Nivalis (Fortaleza Albor): su primera parte jugable (docs/planetas/nivalis-umbria.md)
	require(Misiones.Nivalis_Episodio),
	-- Saga 2 · Tálasa (Abisalia): su primera parte jugable (docs/planetas/talasa-vertice.md)
	require(Misiones.Talasa_Episodio),
	-- Saga 2 · Vértice (Distrito Cero): su primera parte jugable (docs/planetas/talasa-vertice.md)
	require(Misiones.Vertice_Episodio),
	-- Saga 2 · Umbría (Raíz Honda): su primera parte jugable (docs/planetas/nivalis-umbria.md)
	require(Misiones.Umbria_Episodio),
	-- Saga 2 · los peligros del terreno: una secundaria por planeta que presenta su problema propio del suelo
	-- o del clima (arenas movedizas, hielo fino, rayos, ramas, paneles: shared/Cosmos/TerrainPerils)
	require(Misiones.Planetas_Peligros),
	-- Saga 2 · el prólogo del espacio «La costura negra» (Varkun, el Deshilador: docs/universo/diseno-espacio.md)
	retire(require(Misiones.Saga2_Prologo)),
	require(Misiones.Deriva_ActoI),
	-- El mar de los Hondarios · «La canción de lo hondo»: Prólogo y Acto I (fase 1; docs/mar/civilizacion-marina.md)
	require(Misiones.Mar_Acto1),
}
