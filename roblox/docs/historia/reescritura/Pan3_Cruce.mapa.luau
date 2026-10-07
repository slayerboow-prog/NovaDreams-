-- Mapa del guion reescrito de Pan3_Cruce (lo lee scripts/audit/aplicar-reescritura.luau).
-- 16 PASO = 16 pasos del juego (las tres ramas de Camino: el negocio del estadio, alejarse con Nerea y
-- Carmen, o salvar a Rayo con el taller de Tobías).
return {
	Prefijo = "Pan3",
	-- (la cinemática Pan3_Oferta se queda como está: lee lo que hiciste antes —el súper, Nerea, si te pillaron o mentiste en casa y la variante «Distantes»— con sus variantes; su texto nuevo (PASO 3) está fundido a mano en la escena)
	Pasos = { ["3"] = false },
	Variables = {
		["ruta a — negocio"] = { If = { Choices = { Camino = "Negocio" } } },
		["ruta negocio"] = { If = { Choices = { Camino = "Negocio" } } },
		["ruta alejarse"] = { If = { Choices = { Camino = "Alejarse" } } },
		["ruta salvar"] = { If = { Choices = { Camino = "Salvar" } } },
		["ruta salvar a rayo"] = { If = { Choices = { Camino = "Salvar" } } },
		["ruta camino delincuente"] = { If = { Flags = { "Camino_Delincuente" } } },
		["ruta camino trabajador + rebeldía alta"] = { If = { Flags = { "Camino_Trabajador" }, Traits = { Rebeldia = 3 } } },
		["ruta camino trabajador + rebeldia alta"] = { If = { Flags = { "Camino_Trabajador" }, Traits = { Rebeldia = 3 } } },
		["ruta camino trabajador + rebeldía baja"] = { If = { Flags = { "Camino_Trabajador" }, TraitsBelow = { Rebeldia = 3 } } },
		["ruta camino trabajador + rebeldia baja"] = { If = { Flags = { "Camino_Trabajador" }, TraitsBelow = { Rebeldia = 3 } } },
	},
	Informe = "La mecánica es la de siempre: Rayo solo en el parque y su oferta (Pan3_Oferta), Nerea en el patio, la decisión Camino y su rama (el negocio de camisetas falsas en el estadio, ir con Nerea a hablar con Carmen, o llevar a Rayo al taller de Tobías y volver a decírselo), la noche y el espejo. Las variantes van con lo que guarda el juego: la marca Hurto de Pan2, el recuerdo LaNoche, la relación con Rayo (Rel) y los caminos Camino_Delincuente / Camino_Trabajador con la Rebeldía.",
	-- (opciones de la elección y notas que se colaban como frases del jugador: no salen)
	SiTexto = {
		{ "Entrar en el negocio de Rayo: dinero fácil", { Nunca = true } },
		{ "Alejarte de la pandilla y ayudar a Nerea a salir", { Nunca = true } },
		{ "Intentar que Rayo lo deje", { Nunca = true } },
	},
}
