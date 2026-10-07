-- Mapa del guion reescrito de Cole12_UltimoDia (lo lee scripts/audit/aplicar-reescritura.luau).
-- Formato libre; sus 15 PASO son los 15 pasos del juego (con el paso 14 que se añadió antes: los datos
-- van por el número de paso de hoy y no cambian la estructura, así que la migración sigue igual).
-- REGLA del guion: ningún recuerdo que el jugador no vivió → cada frase de un recuerdo lleva la marca
-- que lo guarda; una condición que el juego no guarda deja la frase sin salir (nunca sale de más).
return {
	Prefijo = "Cole12",
	-- El PASO 15 es el montaje de cambio de etapa (Niño → Adolescente): tiene un diseño fijo que comprueba
	-- test-etapas, así que no se cambia (ver Informe)
	Pasos = { ["15"] = false },
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben", ["Andrés"] = "Andres" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	-- (lo que dicen ellos son recuerdos compartidos: solo si los viviste)
	CondicionHablante = { Mateo = { Flags = { "AyudasteAMateo" } }, Hugo = { Flags = { "HugoConElGrupo" } }, Iker = { Flags = { "IkerEnElGrupo" } } },
	-- Los recuerdos de cada sitio que el guion resume como «montaje según las marcas»: se quedan las frases
	-- del juego, cada una con la marca que la guarda (MochilaPerdida, DejasteMochila, SegundaOportunidad…)
	ConservarFrases = { "Rec_Pupitre", "Rec_Taquilla", "Rec_Campo", "Rec_Biblioteca", "Rec_Almacen", "Rec_Banco" },
	-- El reconocimiento del festival «según talento» (títulos sueltos Cantar/Chistes/Animar)
	SiTexto = {
		-- (notas de diseño del guion que no son frases de nadie: no salen)
		{ "Se reproduce el momento de los libros cayendo.", { Nunca = true } },
		{ "Y ahora empieza", { Choices = { Talento = "Cantar" } } },
		{ "chistes de matemáticas", { Choices = { Talento = "Chistes" } } },
		{ "animando a los demás", { Choices = { Talento = "Animar" } } },
	},
	PorTexto = { NombreGrupo = { "Los Imparables", "La Patrulla Valmar", "Los del Banco Azul", "Los Dinosaurios" } },
	Variables = {
		capsula = { Choice = "Capsula" },
		promesa = { Choice = "Promesa" },
		adios_bruno = { Choice = "AdiosBruno" },
		["foto lucia"] = { Choice = "FotoLucia" },
		grupo = { Choice = "NombreGrupo", Valores = { ["Los Imparables"] = "Los Imparables", ["La Patrulla Valmar"] = "La Patrulla Valmar", ["Los del Banco Azul"] = "Los del Banco Azul", ["Los Dinosaurios"] = "Los Dinosaurios", LosImparables = "Los Imparables", LaPatrullaValmar = "La Patrulla Valmar", LosDelBancoAzul = "Los del Banco Azul", LosDinosaurios = "Los Dinosaurios" } },
		["mateo esta"] = { If = { Flags = { "AyudasteAMateo" } } },
		["ayudaste a mateo"] = { If = { Flags = { "AyudasteAMateo" } } },
		["primer amigo"] = { If = { Flags = { "AyudasteAMateo" } } },
		["no ayudo a mateo"] = { If = { NotFlags = { "AyudasteAMateo" } } },
		["hugo esta en el grupo"] = { If = { Flags = { "HugoConElGrupo" } } },
		["no estuvo con hugo"] = { If = { NotFlags = { "HugoConElGrupo" } } },
		["iker esta en el grupo"] = { If = { Flags = { "IkerEnElGrupo" } } },
		["segunda oportunidad"] = { If = { Flags = { "IkerEnElGrupo" } } },
		["casi suspenso"] = { If = { Flags = { "SuspendisteExamen" } } },
		suspendio = { If = { Flags = { "SuspendisteExamen" } } },
		["secreto lucia"] = { If = { Flags = { "SecretoLucia" } } },
		["hablo con bruno anteriormente"] = { If = { Flags = { "Bruno_HablasteConEl" } } },
		["lo acuso injustamente"] = { If = { Flags = { "AcusasteABruno" } } },
		["gano el torneo"] = { If = { Flags = { "TorneoGanado" } } },
		perdio = { If = { Flags = { "TorneoPerdido" } } },
		["perdio el torneo"] = { If = { Flags = { "TorneoPerdido" } } },
		["fue capitan"] = { If = { Choices = { Capitan = "Yo" } } },
		["ayudo en el festival"] = { If = { Choices = { FestivalBruno = "Ayudar" } } },
		["no hizo el festival de teatro"] = { If = { NotChoices = { Festival = "Teatro" } } },
		["ruben perdonado"] = { If = { Flags = { "Ruben_Perdonado" } } },
		["ruben rival"] = { If = { Flags = { "Ruben_Rival" } } },
		["existe primer grupo"] = { If = {} },
		["los imparables"] = { If = { Choices = { NombreGrupo = "Los Imparables" } } },
		["la patrulla valmar"] = { If = { Choices = { NombreGrupo = "La Patrulla Valmar" } } },
		["los del banco azul"] = { If = { Choices = { NombreGrupo = "Los del Banco Azul" } } },
		["los dinosaurios"] = { If = { Choices = { NombreGrupo = "Los Dinosaurios" } } },
		corresponde = { If = {} },
	},
	Informe = "Se mantienen las variables de siempre: los recuerdos visitados (el Group del paso 5, al menos cuatro), la cápsula (Choices.Capsula de Cole09: Carta/Dibujo/Prediccion/Pregunta), el adiós a Bruno (Choices.AdiosBruno, con el llavero 13 de Ramón como hasta ahora) y la promesa (Choices.Promesa). Cada frase que recuerda algo va condicionada a la marca que lo guarda (AyudasteAMateo, HugoConElGrupo, IkerEnElGrupo, TorneoGanado/Perdido, SuspendisteExamen, SecretoLucia, AcusasteABruno, Bruno_HablasteConEl, Ruben_Perdonado/Rival, FotoLucia, NombreGrupo…); el grito final solo sale con el nombre de grupo que elegiste. El PASO 15 (la transición al instituto, Nino_AInstituto = el montaje Montaje_Nino_Adolescente) no se cambia: el montaje de etapa tiene un diseño fijo comprobado por test-etapas (duración, fotos vivas de lo vivido…). Los «recuerdos superpuestos» (el pasado sobre el presente) se quedan como plano + frase: el motor no tiene un filtro de recuerdo (pendiente). test-reescritura recorre combinaciones (Mateo sí/no, Hugo, Iker, torneo ganado/perdido, cada cápsula y cada nombre de grupo) y comprueba que no sale ningún recuerdo no vivido.",
}
