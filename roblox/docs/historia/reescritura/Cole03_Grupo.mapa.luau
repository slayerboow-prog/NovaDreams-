-- Mapa del guion reescrito de Cole03_Grupo (lo lee scripts/audit/aplicar-reescritura.luau).
-- Sus 27 PASO son los 27 pasos del juego (sale de la exportación).
return {
	Prefijo = "Cole03",
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Álex"] = "Alex", ["Rubén"] = "Ruben" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	Variables = {
		invitacion = { Choice = "Invitacion" },
		posicion = { Choice = "Posicion" },
		permiso = { Choice = "Permiso" },
		sueno_infancia = { Choice = "SuenoInfancia" },
		nombre_grupo = { Choice = "NombreGrupo" },
		gato_colegio = { Choice = "GatoColegio" },
		-- el reto de canastas con Nico (paso 7, minijuego): una marca al ganarlo o perderlo
		["marca dos o mas"] = { Gana = "7" },
		["marca menos"] = { Pierde = "7" },
		-- el partido (paso 15): ganado / perdido
		["el protagonista marca"] = { If = { Flags = { "PartidoGanado" } } },
		["recibe un gol"] = { If = { Flags = { "PartidoPerdido" } } },
		["dinero suficiente"] = { If = { NotFlags = { "SinDinero" } } },
		["dinero insuficiente"] = { If = { Flags = { "SinDinero" } } },
	},
	Informe = "nombre_grupo y sueno_infancia ya se guardan como decisiones consultables (Choices.NombreGrupo, Choices.SuenoInfancia); el resto de la historia escribe el nombre con {grupo} (LifeStoryService lo rellena con el nombre elegido) y la profesión de adulto puede compararse con Choices.SuenoInfancia. La foto del grupo es la cinemática del paso 27 y el recuerdo «PrimerGrupo» de la misión (Memories): no hay un álbum de fotos aparte, así que «Foto_Grupo_Infancia» queda como ese recuerdo. Los nombres de grupo del guion se escriben igual que en el juego («Los Imparables»…). El minijuego del partido (Futbol) y el reto de canastas (Timing) ya existen y se usan tal cual; para las frases de «si marcas dos o más» se añade una marca al ganar/perder el reto (Cole03_P7_Gana / Cole03_P7_Pierde).",
}
