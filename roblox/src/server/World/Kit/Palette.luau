-- Palette: colores, materiales y estilos arquitectónicos de Valmar.
-- Cambiar un color aquí lo cambia en toda la ciudad.

local Palette = {}

local rgb = Color3.fromRGB

Palette.Ground = {
	-- Verdes apagados, de clima mediterráneo (los verdes chillones hacen que todo parezca de juguete)
	Grass = rgb(104, 138, 70),
	Lawn = rgb(100, 146, 70),
	-- Asfalto oscuro y algo frío (el gris claro se veía plano y apagaba las marcas blancas; mojado,
	-- el oscuro refleja mejor las luces)
	Asphalt = rgb(46, 48, 53),
	Sidewalk = rgb(196, 192, 184),
	Curb = rgb(214, 211, 204),
	Marking = rgb(236, 236, 230),
	MarkingYellow = rgb(232, 196, 70),
	Plaza = rgb(214, 202, 182),
}

Palette.Nature = {
	Trunk = rgb(104, 78, 56),
	PalmTrunk = rgb(150, 122, 88),
	Leaves = { rgb(62, 98, 50), rgb(78, 112, 56), rgb(96, 124, 60), rgb(56, 88, 48), rgb(112, 130, 68), rgb(84, 106, 52) },
	Hedge = rgb(56, 92, 48),
	Flowers = { rgb(226, 72, 92), rgb(246, 196, 60), rgb(240, 240, 240), rgb(170, 90, 200), rgb(250, 130, 60) },
}

Palette.Street = {
	Metal = rgb(58, 62, 68),
	LampLight = rgb(255, 214, 160),
	Wood = rgb(132, 96, 66),
	Glass = rgb(160, 196, 214),
}

Palette.CarColors = {
	rgb(235, 235, 235), rgb(30, 30, 34), rgb(150, 155, 162), rgb(170, 30, 36),
	rgb(34, 70, 140), rgb(200, 190, 170), rgb(60, 90, 70), rgb(240, 200, 60),
}

-- Estilos de edificio. Wall: lista de colores posibles (se elige uno al azar).
export type Style = {
	Wall: { Color3 },
	WallMaterial: Enum.Material,
	Trim: Color3,
	TrimMaterial: Enum.Material,
	Glass: Color3,
	Bay: number, -- separación entre ventanas
	WindowW: number,
	WindowH: number,
	Lintels: boolean,
	Shutters: { Color3 }?,
	Balconies: "None" | "Iron" | "Glass",
	Roof: "Flat" | "Gable",
	Curtain: boolean?, -- plantas superiores con muro cortina de cristal (rascacielos)
	RoofColor: Color3?,
	RoofMaterial: Enum.Material?,
}

Palette.Styles = {
	-- Edificios clásicos del centro: piedra clara, balcones de hierro
	Clasico = {
		Wall = { rgb(236, 226, 206), rgb(226, 214, 190), rgb(240, 234, 222), rgb(214, 196, 170) },
		WallMaterial = Enum.Material.Plaster,
		Trim = rgb(246, 242, 232),
		TrimMaterial = Enum.Material.Limestone,
		Glass = rgb(52, 70, 84),
		Bay = 8,
		WindowW = 3.6,
		WindowH = 7,
		Lintels = true,
		Shutters = nil,
		Balconies = "Iron",
		Roof = "Flat",
	},
	-- Oficinas y comercios modernos: hormigón claro y ventanales
	Moderno = {
		Wall = { rgb(222, 222, 220), rgb(200, 202, 204), rgb(180, 184, 188) },
		WallMaterial = Enum.Material.Concrete,
		Trim = rgb(90, 94, 100),
		TrimMaterial = Enum.Material.Metal,
		Glass = rgb(66, 96, 112),
		Bay = 8,
		WindowW = 6.4,
		WindowH = 8,
		Lintels = false,
		Shutters = nil,
		Balconies = "Glass",
		Roof = "Flat",
	},
	-- Barrio popular mediterráneo: colores cálidos y contraventanas
	Popular = {
		Wall = { rgb(212, 132, 96), rgb(224, 176, 96), rgb(232, 160, 128), rgb(236, 214, 150), rgb(170, 196, 212), rgb(226, 196, 170) },
		WallMaterial = Enum.Material.Plaster,
		Trim = rgb(244, 238, 226),
		TrimMaterial = Enum.Material.Plaster,
		Glass = rgb(56, 70, 80),
		Bay = 8,
		WindowW = 3.4,
		WindowH = 6.5,
		Lintels = false,
		Shutters = { rgb(70, 112, 80), rgb(60, 92, 134), rgb(112, 78, 52) },
		Balconies = "Iron",
		Roof = "Flat",
	},
	-- Rascacielos de oficinas: muro cortina de cristal con líneas de planta
	Oficina = {
		Wall = { rgb(206, 210, 214), rgb(190, 194, 200), rgb(222, 222, 218) },
		WallMaterial = Enum.Material.Concrete,
		Trim = rgb(58, 62, 70),
		TrimMaterial = Enum.Material.Metal,
		Glass = rgb(78, 118, 148),
		Bay = 7,
		WindowW = 6,
		WindowH = 9,
		Lintels = false,
		Shutters = nil,
		Balconies = "None",
		Roof = "Flat",
		Curtain = true,
	},
	-- Casas: blanco o crema con tejado de teja
	Casa = {
		Wall = { rgb(244, 240, 232), rgb(240, 226, 200), rgb(230, 190, 160), rgb(236, 228, 210) },
		WallMaterial = Enum.Material.Plaster,
		Trim = rgb(250, 248, 244),
		TrimMaterial = Enum.Material.Plaster,
		Glass = rgb(60, 78, 90),
		Bay = 8,
		WindowW = 4,
		WindowH = 5.5,
		Lintels = false,
		Shutters = { rgb(70, 112, 80), rgb(60, 92, 134), rgb(120, 84, 56) },
		Balconies = "None",
		Roof = "Gable",
		RoofColor = rgb(176, 86, 56),
		RoofMaterial = Enum.Material.ClayRoofTiles,
	},
}

-- Estilos de Tefra (Bastión Ceniza, docs/planetas/tefra-ciudad.md): lo militar es de esquinas duras y
-- basalto; lo antiguo (el Tefra «redondo» de antes de la guerra) es de yeso suave en tonos malva y crema
Palette.Styles.TefraBunker = {
	Wall = { rgb(58, 54, 60), rgb(66, 62, 66), rgb(52, 50, 56) },
	WallMaterial = Enum.Material.Basalt,
	Trim = rgb(150, 92, 52),
	TrimMaterial = Enum.Material.CorrodedMetal,
	Glass = rgb(62, 46, 42),
	Bay = 14, -- (troneras: pocas ventanas, estrechas)
	WindowW = 2.4,
	WindowH = 2.2,
	Lintels = true,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}
Palette.Styles.TefraFabrica = {
	Wall = { rgb(74, 66, 64), rgb(86, 74, 70), rgb(64, 60, 62) },
	WallMaterial = Enum.Material.CorrodedMetal,
	Trim = rgb(40, 36, 38),
	TrimMaterial = Enum.Material.Metal,
	Glass = rgb(70, 50, 40),
	Bay = 12,
	WindowW = 4,
	WindowH = 3,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}
Palette.Styles.TefraCupula = {
	Wall = { rgb(214, 190, 200), rgb(226, 206, 196), rgb(200, 176, 192), rgb(232, 214, 206) },
	WallMaterial = Enum.Material.Plaster,
	Trim = rgb(176, 150, 162),
	TrimMaterial = Enum.Material.Limestone,
	Glass = rgb(90, 70, 84),
	Bay = 10,
	WindowW = 3.6,
	WindowH = 4.6,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}

-- Estilos de Miasma (Anclaje Siete, docs/planetas/diseno-mundos.md §3.6.7): metal claro y cristal con luz
-- turquesa en el Muelle; chapa remendada y violeta en Lastre; madera pintada de colores en las Góndolas
Palette.Styles.MiasmaCupula = {
	Wall = { rgb(176, 182, 196), rgb(164, 170, 186), rgb(190, 194, 206) },
	WallMaterial = Enum.Material.Metal,
	Trim = rgb(110, 230, 210),
	TrimMaterial = Enum.Material.Neon,
	Glass = rgb(60, 110, 110),
	Bay = 9,
	WindowW = 4.4,
	WindowH = 3.4,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}
Palette.Styles.MiasmaLastre = {
	Wall = { rgb(96, 84, 110), rgb(110, 92, 96), rgb(86, 80, 100), rgb(120, 104, 90) },
	WallMaterial = Enum.Material.CorrodedMetal,
	Trim = rgb(180, 150, 230),
	TrimMaterial = Enum.Material.Metal,
	Glass = rgb(70, 90, 60),
	Bay = 8,
	WindowW = 2.8,
	WindowH = 2.6,
	Lintels = true,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}
Palette.Styles.MiasmaGondola = {
	Wall = { rgb(232, 170, 196), rgb(170, 200, 240), rgb(236, 214, 140), rgb(170, 220, 180) },
	WallMaterial = Enum.Material.WoodPlanks,
	Trim = rgb(250, 246, 236),
	TrimMaterial = Enum.Material.Wood,
	Glass = rgb(70, 90, 110),
	Bay = 7,
	WindowW = 3,
	WindowH = 3,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}

-- Estilos de Siroco (Puerto Calcina, §3.2.7): adobe rojo excavado en la roca, remendado con chapa y toldos;
-- los boxes de las carreras, de chapa pintada con franjas
Palette.Styles.SirocoAdobe = {
	Wall = { rgb(186, 104, 70), rgb(198, 120, 80), rgb(172, 96, 66), rgb(206, 138, 92) },
	WallMaterial = Enum.Material.Sandstone,
	Trim = rgb(232, 196, 150),
	TrimMaterial = Enum.Material.Plaster,
	Glass = rgb(60, 40, 34),
	Bay = 9,
	WindowW = 2.6,
	WindowH = 3,
	Lintels = true,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}
Palette.Styles.SirocoChatarra = {
	Wall = { rgb(140, 110, 92), rgb(120, 104, 96), rgb(150, 96, 70) },
	WallMaterial = Enum.Material.CorrodedMetal,
	Trim = rgb(70, 160, 170),
	TrimMaterial = Enum.Material.Metal,
	Glass = rgb(50, 44, 40),
	Bay = 10,
	WindowW = 3.6,
	WindowH = 3,
	Lintels = false,
	Shutters = nil,
	Balconies = "None",
	Roof = "Flat",
}

-- Temas por planeta: los mismos constructores de calles (Kit/Street, Kit/Props, Kit/StreetDetail)
-- con otros colores. Palette.withTheme cambia los valores EN SU SITIO (las tablas son las mismas que
-- los módulos ya guardaron) mientras corre fn y luego los devuelve. fn no debe ceder (task.wait): si no,
-- otra cosa de Valmar construida a la vez saldría con los colores de Tefra.
Palette.Themes = {
	Tefra = {
		Ground = {
			Asphalt = rgb(40, 36, 40), -- basalto fundido
			Sidewalk = rgb(92, 84, 90), -- losas de toba
			Curb = rgb(120, 110, 114),
			Marking = rgb(236, 150, 70), -- marcas naranjas (como la lava)
			MarkingYellow = rgb(255, 120, 40),
			Plaza = rgb(110, 98, 104),
			Grass = rgb(90, 80, 88),
			Lawn = rgb(90, 80, 88),
		},
		Street = {
			Metal = rgb(44, 40, 44),
			LampLight = rgb(255, 168, 96), -- luz de sodio, naranja
			Wood = rgb(84, 64, 54),
			Glass = rgb(200, 140, 110),
		},
	},
}

function Palette.withTheme<T>(name: string, fn: () -> T): T
	local theme = Palette.Themes[name]
	if not theme then
		return fn()
	end
	local saved = {}
	for group, values in theme do
		local target = (Palette :: any)[group]
		saved[group] = {}
		for key, value in values do
			saved[group][key] = target[key]
			target[key] = value
		end
	end
	local ok, result = pcall(fn)
	for group, values in saved do
		local target = (Palette :: any)[group]
		for key, value in values do
			target[key] = value
		end
	end
	if not ok then
		error(result, 0)
	end
	return result
end

function Palette.pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

return Palette
