-- Mapa del guion reescrito de Cole01_PrimerDia (lo lee scripts/audit/aplicar-reescritura.luau).
-- El guion sale de la exportación: sus 28 PASO son los 28 pasos del juego (y los «n.m», los hijos de
-- los Group), así que no hace falta Pasos. Aquí van las variables del guion → marcas del juego.
return {
	Prefijo = "Cole01",
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben", ["Andrés"] = "Andres" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	Variables = {
		ropa = { Choice = "Ropa" },
		asiento = { Choice = "Asiento" },
		gusto = { Choice = "Gusto" },
		acompanante = { Choice = "Acompanante" },
		grupo_recreo = { Choice = "GrupoRecreo", Valores = { Curiosos = "Estudiantes", curiosos = "Estudiantes" } },
		ayudaste_a_mateo = { Flag = "AyudasteAMateo" },
		ignoraste_a_mateo = { Flag = "IgnorasteAMateo" },
		lleva_cromo = { Flag = "LlevaCromo" },
		pase_a_dani = { Flag = "PaseADani" },
		fallaste_pase = { Flag = "FallastePase" },
		ensayo_espejo = { Flag = "EnsayoEspejo" },
		sabe_del_almacen = { Flag = "SabeDelAlmacen" },
		apuesta_alex = { Flag = "ApuestaAlex" },
		llegas_tarde = { Flag = "LlegasTarde" },
		llego_tarde = { Flag = "LlegasTarde" },
		["llego tarde"] = { If = { Flags = { "LlegasTarde" } } },
		["no llego tarde"] = { If = { NotFlags = { "LlegasTarde" } } },
		["el jugador tardo"] = { If = { Flags = { "LlegasTarde" } } },
		acierta = { If = { Flags = { "PaseADani" } } },
		falla = { If = { Flags = { "FallastePase" } } },
	},
	Informe = "Variables del guion → marcas que ya guarda Cole01: ropa = Choices.Ropa, asiento = Choices.Asiento, grupo_recreo = Choices.GrupoRecreo (los «Curiosos» del guion son la opción Estudiantes del juego), gusto = Choices.Gusto, acompañante = Choices.Acompanante, ayudaste_a_mateo = Flags.AyudasteAMateo (IgnorasteAMateo si no), lleva_cromo = Flags.LlevaCromo, pase_a_dani = Flags.PaseADani (FallastePase si fallas), llegó tarde = Flags.LlegasTarde, sabe_del_almacen = Flags.SabeDelAlmacen (hablar con Ramón en el gimnasio), apuesta_alex = Flags.ApuestaAlex, ensayo_espejo = Flags.EnsayoEspejo. Cole02 y siguientes las leen con esos mismos nombres.",
}
