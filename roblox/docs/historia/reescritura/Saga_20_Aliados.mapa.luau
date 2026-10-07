-- Mapa del guion reescrito de Saga_20_Aliados (lo lee scripts/audit/aplicar-reescritura.luau).
-- 10 PASO = 3 pasos del juego con los subpasos de cada aliado (2.1 Iván y Candela, 2.2 Cronos, 2.3
-- Bigotes, 2.4 Rex, 2.5 el Ratón Pérez, 2.6 los gnomos, 2.7 tu yo malvado). Cada aliado solo aparece si
-- su marca real está puesta (el If de cada subpaso del juego, que no se toca): CronosAliado, Aliado_*
-- completadas, ConoceTuMalvado… La misión nunca bloquea: Iván y Candela siempre están.
return {
	Prefijo = "Saga_20",
	Hablantes = { ["Otro Yo"] = "TuMalvado", ["Otro yo"] = "TuMalvado", ["Tu otro yo"] = "TuMalvado" },
	Variables = {
		-- (el álbum de recuerdos sería un sistema nuevo: esas frases no salen)
		album_recuerdos_obtenido = { Nunca = true },
		["album recuerdos obtenido"] = { Nunca = true },
	},
	Informe = "La mecánica es la de siempre: la lista de Cosme, visitar a los aliados (vienen los que ayudaste: el If de cada subpaso usa las marcas reales —CronosAliado, AliadoBigotes/Rex/Perez/Gnomos/Malvado al visitarlos, las misiones de aliados completadas— y no se toca) y la reunión en el garaje. No hay una lista nueva «AliadosActivos»: cada aliado ya guarda su marca Aliado* al visitarle (y AliadosReunidos al final), que es lo que leen Saga_23 y Saga_24. La escena del garaje coloca a los aliados con su If (solo los que vienen). La Capitana Ñoz no es una visita del juego (pendiente: su nave en la reunión si noz_aliada). El álbum de fotos y el garaje como base de operaciones con rutinas de los aliados son sistemas nuevos: no se hacen (pendiente).",
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		-- (en la reunión solo habla quien vino: la marca Aliado* de cada uno)
		{ "Me ayudaste cuando no tenías por qué.", { Flags = { "AliadoBigotes" } } },
		{ "Las decisiones tienen memoria.", { Flags = { "AliadoCronos" } } },
		{ "Nunca olvidé lo que hiciste.", { Flags = { "AliadoRex" } } },
		{ "Supongo que esto es lo que hacen los buenos.", { Flags = { "AliadoMalvado" } } },
		{ "AliadosActivos = [", { Nunca = true } },
		{ "Esto permitirá que diferentes partidas produzcan grupos distintos.", { Nunca = true } },
	},
	-- (las frases del juego que recuerdan lo que viviste antes se quedan: la continuidad de la Saga)
	ConservarFrases = {
		{ Conversacion = "Compis", Marcas = { "EquipoRescate" }, Al = "final" },
		{ Conversacion = "Lista", Marcas = { "CosmeRecuerda" }, Tras = "He hecho una lista." },
		{ Conversacion = "Cronos", Marcas = { "CronosAliado", "CronosLimpio" }, Al = "final" },
		{ Conversacion = "Bigotes", Marcas = { "CancillerGatonia" }, Al = "final" },
		{ Conversacion = "Rex", Marcas = { "RexAbogado" }, Al = "final" },
		{ Conversacion = "Perez", Marcas = { "PatrullaRatones", "RataContratada" }, Al = "final" },
		{ Conversacion = "Malvado", Marcas = { "MalvadoAyudo", "MalvadoAprendeBondad" }, Al = "final" },
		{ Conversacion = "Reunion", Marcas = { "NaveEnElFinal" }, Tras = "A todos." },
	},
}
