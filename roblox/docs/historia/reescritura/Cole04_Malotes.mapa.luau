-- Mapa del guion reescrito de Cole04_Malotes (lo lee scripts/audit/aplicar-reescritura.luau).
-- Sus 24 PASO son los 24 pasos del juego (sale de la exportación).
return {
	Prefijo = "Cole04",
	Hablantes = { ["Mamá/Papá"] = "Familia", ["Profe Lucía"] = "Lucia", ["Ramón"] = "Ramon", ["Álex"] = "Alex", ["Rubén"] = "Ruben" },
	Variables = {
		malotes = { Choice = "Malotes" },
		nombre_grupo = { Choice = "NombreGrupo" },
		lleva_cromo = { Flag = "LlevaCromo" },
		ayudaste_a_mateo = { Flag = "AyudasteAMateo" },
		sabe_libro_hugo = { Flag = "SabeLibroHugo" },
		descubrio_libro_hugo = { Flag = "SabeLibroHugo" },
		-- (después de Cole03 el grupo siempre tiene nombre: no hace falta condición)
		["existe nombre_grupo"] = { If = {} },
		-- el objeto robado es el del inventario: el cromo si lo llevabas; si no, la foto del grupo
		["objeto = cromo"] = { If = { Flags = { "ObjetoCromo" } } },
		["el jugador llevaba el cromo"] = { If = { Flags = { "ObjetoCromo" } } },
		["llevaba la fotografia"] = { If = { NotFlags = { "ObjetoCromo" } } },
		["objeto = fotografia"] = { If = { NotFlags = { "ObjetoCromo" } } },
		["objeto = foto"] = { If = { NotFlags = { "ObjetoCromo" } } },
		-- la persecución (Chase) no guarda si tardas: esas frases no tienen condición que mirar
		["el jugador tarda"] = { If = { Flags = { "Cole04_HugoTeSaca" } } },
	},
	Informe = "El objeto robado es el mismo del inventario: el cromo (Flags.ObjetoCromo, que el juego pone al quitarte el CromoSuerte de Cole01) o, si no lo llevabas, la foto del grupo de Cole03; las frases del guion «si objeto = cromo/fotografía» miran esa marca y el juego lo devuelve con sus Effects de siempre (no se duplica). sabe_libro_hugo = Flags.SabeLibroHugo de Cole02. La marca PistaHugo (lo que te cuenta Mateo) se sigue guardando, pero el guion nuevo no la lee. La persecución de Hugo (Chase, con el atajo del aula de música) y esconderse de Ramón (Use Escondite) se juegan igual. «Si el jugador tarda» en alcanzar a Hugo: la persecución no guarda ese dato, así que esas frases solo saldrían con una marca que hoy no pone nadie (pendiente: que el paso Chase marque si se tardó).",
}
