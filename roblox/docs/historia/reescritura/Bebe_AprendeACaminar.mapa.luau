-- Mapa del guion reescrito de Bebe_AprendeACaminar (lo lee scripts/audit/aplicar-reescritura.luau).
-- En el juego son 4 pasos: 1 levantarse (BabyStood), 2 dar cinco pasos (BabySteps), 3 llegar hasta Abu
-- (Talk Familia_Abu) y 4 la escena de los primeros pasos. El guion trae 9 PASO.
return {
	Prefijo = "Bebe_Caminar",
	Pasos = {
		["1"] = 1, -- despertar en la cuna (frases al levantarse: es el primer paso, no hay otro antes)
		["2"] = 1, -- «Aprende a moverte»
		["3"] = 2, -- uno, dos… (al dar los cinco pasos)
		["4"] = 2, -- el juguete que suena (no hay juguete jugable en este paso: frases al terminar)
		["5"] = 3, -- el pasillo enorme (frases al empezar a ir hacia Abu)
		["6"] = 3, -- la fotografía del salón
		["7"] = 4, -- la familia te descubre andando: la escena de los primeros pasos
		["8"] = 4, -- en brazos, «disfruta cada paso»
		["9"] = 4, -- la cámara sale por la ventana y el destello en el cielo
	},
	Lugares = { "Cuna", "HomeDormitorio", "HomeSalon", "PasilloColegio", "Ventanal", "CasaFamiliar", "FamiliaAbu", "FamiliaPadre" },
	Actores = { Familia = "FamiliaPadre", Abu = "FamiliaAbu" },
	Sujetos = {
		["Habitación"] = "Lugar:HomeDormitorio",
		Cuna = "Lugar:Cuna",
		["Móvil de bebé"] = "Lugar:Cuna",
		["Puerta de la habitación"] = "Lugar:HomeDormitorio",
		Pasillo = "Lugar:HomeSalon",
		["Salón"] = "Lugar:HomeSalon",
		["Fotografía familiar"] = "Lugar:HomeSalon",
		["Fotografía"] = "Lugar:HomeSalon",
		Juguete = "Lugar:HomeSalon",
		Ventana = "Lugar:Ventanal",
		Calle = "Lugar:Ventanal",
		Madre = "Familia",
		["Mano de la madre"] = "Familia",
	},
	Informe = "El guion cuenta que es MAMÁ quien te descubre andando; en el juego el paso 3 es llegar hasta Abu (su sitio en la casa) y la escena era con Abu. Se conserva la mecánica (ir hasta Abu) y la escena nueva es la del guion con «Familia» (Mamá o Papá según tu casa: el juego tiene Papá+Abu Rosa o Mamá+Abu Tomás). «Madre» del guion = Familia.",
}
