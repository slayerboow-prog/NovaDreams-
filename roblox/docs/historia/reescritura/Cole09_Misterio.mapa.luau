-- Mapa del guion reescrito de Cole09_Misterio (lo lee scripts/audit/aplicar-reescritura.luau).
-- El guion viene en formato libre («PASO n · TÍTULO», planos en listas numeradas, diálogos «Nombre:» +
-- la frase en la línea siguiente). Sus 19 PASO son los 19 pasos del juego (con el paso 14, la escena
-- Cole09_LaFoto, que se añadió en la v95: los datos van por el número de paso de hoy y no cambian la
-- estructura, así que la migración de las partidas a medias sigue igual).
return {
	Prefijo = "Cole09",
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben" },
	Musica = { ["3"] = { "Comedia", "Tension" } },
	Variables = {
		entrar = { Choice = "Entrar" },
		candado = { Choice = "Candado" },
		foto_lucia = { Choice = "FotoLucia" },
		["foto lucia"] = { Choice = "FotoLucia" },
		capsula = { Choice = "Capsula" },
		["iker en el grupo"] = { If = { Flags = { "IkerEnElGrupo" } } },
		["iker esta en el grupo"] = { If = { Flags = { "IkerEnElGrupo" } } },
		["iker esta"] = { If = { Flags = { "IkerEnElGrupo" } } },
		iker = { If = { Flags = { "IkerEnElGrupo" } } },
		["ayudaste a mateo"] = { If = { Flags = { "AyudasteAMateo" } } },
		["hugo con el grupo"] = { If = { Flags = { "HugoConElGrupo" } } },
		["ramon esta"] = { If = { Choices = { Entrar = "Permiso" } } },
		permiso = { If = { Choices = { Entrar = "Permiso" } } },
		colarse = { If = { Choices = { Entrar = "Colarse" } } },
		["secreto lucia"] = { Flag = "SecretoLucia" },
		puerta_pasillo_vista = { Flag = "PuertaPasilloVista" },
	},
	Informe = "Se conservan las marcas de siempre: entrar = Choices.Entrar (Permiso/Colarse), el candado (Choices.Candado; 199813 es la buena, las otras tres te dejan probar otra vez), foto de Lucía = Choices.FotoLucia (Devolver/Clase/Secreto), Flags.SecretoLucia y la cápsula = Choices.Capsula (Carta/Dibujo/Prediccion/Pregunta), que lee Cole12; Flags.CapsulaDelTiempo sigue igual. Las marcas nuevas que propone el guion (cole09_sala_descubierta, cole09_foto_lucia, cole09_capsula_creada…) no se añaden: lo mismo ya se sabe con la misión completada y las decisiones anteriores. Vestir la sala (polvo, rayos de luz, partículas) no se hace: la sala vieja no tiene un decorado propio donde ponerlo barato (pendiente). El destello verde del tornillo al final solo tendría sentido para quien soñó el prólogo (Memories.SuenoGrieta); no hay un efecto del tornillo fuera del sueño, así que queda pendiente. Las direcciones del guion («DIRECCIÓN AAA», NPC que no se quedan congelados) son notas para quien monte la escena: los NPC ya tienen su vida (ActorLife).",
	-- (notas de diseño del guion que no son frases de nadie: no salen)
	SiTexto = {
		{ "¿Acabo de ver eso?", { Nunca = true } },
	},
}
