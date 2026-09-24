-- Palette: colores, materiales y estilos arquitectónicos de Valmar.
-- Cambiar un color aquí lo cambia en toda la ciudad.

local Palette = {}

local rgb = Color3.fromRGB

Palette.Ground = {
	Grass = rgb(98, 146, 70),
	Lawn = rgb(106, 158, 76),
	Asphalt = rgb(52, 54, 58),
	Sidewalk = rgb(196, 192, 184),
	Curb = rgb(214, 211, 204),
	Marking = rgb(236, 236, 230),
	MarkingYellow = rgb(232, 196, 70),
	Plaza = rgb(214, 202, 182),
}

Palette.Nature = {
	Trunk = rgb(104, 78, 56),
	PalmTrunk = rgb(150, 122, 88),
	Leaves = { rgb(70, 124, 58), rgb(84, 138, 62), rgb(62, 110, 54), rgb(96, 146, 66) },
	Hedge = rgb(58, 104, 50),
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

function Palette.pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

return Palette
