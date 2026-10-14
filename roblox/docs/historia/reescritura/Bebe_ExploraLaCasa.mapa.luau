-- Mapa del guion reescrito de Bebe_ExploraLaCasa (lo lee scripts/audit/aplicar-reescritura.luau).
-- En el juego: 1 = Group (1.1 ir a la cocina, 1.2 mirar la tele, 1.3 jugar con los bloques) y
-- 2 = pedir el biberón a tu familia en la cocina (Talk Familia_Padre).
return {
	Prefijo = "Bebe_Casa",
	Pasos = {
		["1"] = "1.1", -- (la entrada del Group no tiene «antes»: sus frases suenan al llegar a la cocina)
		["1.1"] = "1.1",
		["1.2"] = "1.2",
		["1.3"] = "1.3",
		["2"] = 2,
	},
	Lugares = { "HomeSalon", "HomeCocina", "HomeDormitorio", "FamiliaPadre" },
	Actores = { Familia = "FamiliaPadre" },
	Hablantes = { ["Mamá/Papá"] = "Familia" },
	Sujetos = {
		["Mamá/Papá"] = "Familia",
		["Salón"] = "Lugar:HomeSalon",
		["Televisión"] = "Lugar:HomeSalon",
		["Mando a distancia"] = "Lugar:HomeSalon",
		Cocina = "Lugar:HomeCocina",
		Mesa = "Lugar:HomeCocina",
		Frutero = "Lugar:HomeCocina",
		["Biberón"] = "Familia",
		["Habitación"] = "Lugar:HomeDormitorio",
		Bloques = "Lugar:HomeDormitorio",
	},
	Informe = "FLAG DE MEMORIA: «Bebe_ExploraLaCasa_Completada» ya lo guarda el juego (misión completada); los lugares descubiertos y el vínculo familiar no tienen un sistema propio (la relación con la familia ya sube al hablar con ella); el recuerdo «LaCasa» no existe en Memories y no se inventa.",
}
