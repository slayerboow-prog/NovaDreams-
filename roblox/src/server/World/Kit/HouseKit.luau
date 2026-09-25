-- HouseKit: casas unifamiliares con muchos detalles (las de los distritos y los barrios).
--
-- Estilos: Mediterranea, Ladrillo, Moderna, Rustica y Colonial (colores, tejado y carpintería).
--   Fachada: zócalo, esquinas de piedra (rústica y colonial), imposta entre plantas.
--   Tejado: a dos aguas de teja o pizarra con cumbrera, aleros, canalones y bajantes, chimenea
--           (o plano con peto en la moderna); a veces placas solares.
--   Puerta: marco, hoja con cuarterones, pomo, escalón, felpudo y farol.
--   Ventanas: marco, cristal, cruceta, alféizar, contraventanas y a veces jardinera con flores;
--             algunas se encienden de noche (NightWindow).
--   Extras: balcón con barandilla, porche, garaje con puerta seccional, aire acondicionado,
--           antena parabólica. Jardín: valla con cancela, buzón, cubos, farolillos y flores.
-- Convención: cf = centro de la planta a ras de suelo; la fachada (puerta) mira hacia -Z.

local Builder = require(script.Parent.Parent.Builder)
local Nature = require(script.Parent.Nature)

local HouseKit = {}

local rgb = Color3.fromRGB

type Style = {
	Walls: { Color3 },
	WallMaterial: Enum.Material,
	Roof: { Color3 },
	RoofMaterial: Enum.Material,
	Trim: Color3, -- marcos, alféizares, imposta
	Shutters: { Color3 }?,
	Quoins: boolean?,
	Flat: boolean?,
	Plinth: Color3,
}

HouseKit.Styles = {
	Mediterranea = {
		Walls = { rgb(246, 242, 232), rgb(250, 238, 210), rgb(240, 230, 214) },
		WallMaterial = Enum.Material.Plaster,
		Roof = { rgb(176, 84, 52), rgb(190, 100, 60), rgb(160, 76, 50) },
		RoofMaterial = Enum.Material.ClayRoofTiles,
		Trim = rgb(236, 230, 214),
		Shutters = { rgb(40, 110, 80), rgb(40, 90, 150), rgb(120, 70, 40) },
		Plinth = rgb(190, 176, 150),
	},
	Ladrillo = {
		Walls = { rgb(170, 90, 70), rgb(150, 80, 64), rgb(184, 110, 84) },
		WallMaterial = Enum.Material.Brick,
		Roof = { rgb(70, 74, 82), rgb(60, 62, 70), rgb(90, 70, 60) },
		RoofMaterial = Enum.Material.Slate,
		Trim = rgb(240, 238, 232),
		Plinth = rgb(120, 116, 110),
	},
	Moderna = {
		Walls = { rgb(242, 242, 240), rgb(226, 226, 222), rgb(214, 206, 194) },
		WallMaterial = Enum.Material.SmoothPlastic,
		Roof = { rgb(60, 62, 66) },
		RoofMaterial = Enum.Material.Concrete,
		Trim = rgb(50, 52, 56),
		Flat = true,
		Plinth = rgb(90, 92, 96),
	},
	Rustica = {
		Walls = { rgb(220, 200, 170), rgb(206, 186, 150), rgb(230, 214, 186) },
		WallMaterial = Enum.Material.Limestone,
		Roof = { rgb(140, 80, 56), rgb(120, 70, 50) },
		RoofMaterial = Enum.Material.ClayRoofTiles,
		Trim = rgb(120, 86, 56),
		Shutters = { rgb(110, 76, 48), rgb(90, 60, 40) },
		Quoins = true,
		Plinth = rgb(140, 130, 116),
	},
	Colonial = {
		Walls = { rgb(200, 216, 232), rgb(246, 226, 170), rgb(236, 206, 206), rgb(206, 226, 200) },
		WallMaterial = Enum.Material.WoodPlanks,
		Roof = { rgb(80, 84, 92), rgb(110, 60, 50) },
		RoofMaterial = Enum.Material.Slate,
		Trim = rgb(250, 250, 248),
		Shutters = { rgb(250, 250, 248), rgb(40, 60, 90) },
		Quoins = true,
		Plinth = rgb(200, 196, 190),
	},
}
HouseKit.StyleNames = { "Mediterranea", "Ladrillo", "Moderna", "Rustica", "Colonial" }

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

export type Options = {
	Style: string?,
	Floors: number?,
	Garage: boolean?,
	Porch: boolean?,
	Balcony: boolean?,
	Yard: boolean?, -- valla, buzón y cubos delante (por defecto sí)
	Name: string?,
}

function HouseKit.build(parent: Instance, cf: CFrame, w: number, d: number, options: Options?): Model
	local opts = options or {}
	local styleName = opts.Style or pick(HouseKit.StyleNames)
	local style: Style = HouseKit.Styles[styleName] or HouseKit.Styles.Mediterranea
	local floors = opts.Floors or math.random(1, 2)
	local FH = 10 -- altura de cada planta
	local h = floors * FH
	local wall = pick(style.Walls)
	local roofColor = pick(style.Roof)
	local shutter = if style.Shutters then pick(style.Shutters) else nil
	local glass = rgb(70, 96, 120)

	local m = Builder.model(opts.Name or "Casa", parent)
	m:SetAttribute("Style", styleName)

	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local function solid(name: string, size: Vector3, c: CFrame, color: Color3, material: Enum.Material?): BasePart
		return Builder.part({ Name = name, Size = size, CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = m })
	end
	local function bit(name: string, size: Vector3, c: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
		return Builder.decor({ Name = name, Size = size, CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0, Parent = m })
	end
	local function cyl(name: string, length: number, diameter: number, c: CFrame, color: Color3, material: Enum.Material?): BasePart
		return Builder.decor({ Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, diameter, diameter), CFrame = c, Color = color, Material = material or Enum.Material.SmoothPlastic, Parent = m })
	end

	---------------------------------------------------------------------
	-- Volumen, zócalo, esquinas e impostas
	---------------------------------------------------------------------
	solid("Body", Vector3.new(w, h, d), at(0, h / 2, 0), wall, style.WallMaterial)
	bit("Plinth", Vector3.new(w + 0.3, 1.4, d + 0.3), at(0, 0.7, 0), style.Plinth, Enum.Material.Concrete)
	if style.Quoins then
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				bit("Quoin", Vector3.new(1.2, h - 1.4, 1.2), at(sx * (w / 2 - 0.45), (h + 1.4) / 2, sz * (d / 2 - 0.45)), style.Trim, Enum.Material.Limestone)
			end
		end
	end
	for f = 1, floors - 1 do
		bit("FloorBand", Vector3.new(w + 0.4, 0.5, d + 0.4), at(0, f * FH, 0), style.Trim)
	end
	if styleName == "Moderna" then
		-- Paño de madera en la fachada
		bit("Cladding", Vector3.new(w * 0.32, h - 1.4, 0.3), at(w / 2 - w * 0.16, (h + 1.4) / 2, -d / 2 - 0.1), rgb(160, 110, 70), Enum.Material.WoodPlanks)
	end

	---------------------------------------------------------------------
	-- Tejado
	---------------------------------------------------------------------
	local flat = style.Flat
	if flat then
		solid("Roof", Vector3.new(w + 0.4, 0.6, d + 0.4), at(0, h + 0.3, 0), roofColor, style.RoofMaterial)
		for _, sz in { -1, 1 } do
			bit("Parapet", Vector3.new(w + 0.4, 1.2, 0.4), at(0, h + 1.2, sz * (d / 2)), wall, style.WallMaterial)
		end
		for _, sx in { -1, 1 } do
			bit("Parapet", Vector3.new(0.4, 1.2, d + 0.4), at(sx * (w / 2), h + 1.2, 0), wall, style.WallMaterial)
		end
	else
		local rh = math.min(w, d) * 0.32
		local over = 0.9 -- alero
		Builder.part({ ClassName = "WedgePart", Name = "Roof", Size = Vector3.new(w + 1.4, rh, d / 2 + over), CFrame = at(0, h + rh / 2, -d / 4 - over / 2), Color = roofColor, Material = style.RoofMaterial, Parent = m })
		Builder.part({ ClassName = "WedgePart", Name = "Roof", Size = Vector3.new(w + 1.4, rh, d / 2 + over), CFrame = at(0, h + rh / 2, d / 4 + over / 2) * CFrame.Angles(0, math.pi, 0), Color = roofColor, Material = style.RoofMaterial, Parent = m })
		bit("Ridge", Vector3.new(w + 1.6, 0.5, 0.8), at(0, h + rh + 0.1, 0), roofColor:Lerp(Color3.new(0, 0, 0), 0.25), style.RoofMaterial)
		-- Aleros, canalones y bajantes (delante y detrás)
		for _, sz in { -1, 1 } do
			bit("Fascia", Vector3.new(w + 1.4, 0.45, 0.25), at(0, h + 0.15, sz * (d / 2 + over)), style.Trim)
			cyl("Gutter", w + 1.4, 0.45, at(0, h - 0.05, sz * (d / 2 + over + 0.25)), rgb(200, 200, 204), Enum.Material.Metal)
			for _, sx in { -1, 1 } do
				cyl("Downpipe", h, 0.3, at(sx * (w / 2 + 0.3), h / 2, sz * (d / 2 + 0.4)) * CFrame.Angles(0, 0, math.rad(90)), rgb(200, 200, 204), Enum.Material.Metal)
			end
		end
		if math.random() < 0.55 then
			solid("Chimney", Vector3.new(2, rh + 2.4, 2), at(w / 3, h + rh * 0.6 + 0.6, d / 6), rgb(150, 100, 80), Enum.Material.Brick)
			bit("ChimneyCap", Vector3.new(2.6, 0.4, 2.6), at(w / 3, h + rh * 1.1 + 1.8, d / 6), rgb(90, 90, 94), Enum.Material.Concrete)
		end
		if math.random() < 0.3 then
			-- Placas solares en el faldón de atrás
			local slope = math.atan2(rh, d / 2 + over)
			bit("SolarPanel", Vector3.new(w * 0.5, 0.15, d * 0.28), at(-w / 8, h + rh * 0.5 + 0.2, d / 4) * CFrame.Angles(slope, 0, 0), rgb(30, 40, 70), Enum.Material.Glass)
		end
	end

	---------------------------------------------------------------------
	-- Ventanas
	---------------------------------------------------------------------
	-- face = CFrame en la superficie del muro, mirando hacia fuera (-Z local = hacia fuera)
	local function window(face: CFrame, x: number, y: number, ww: number, wh: number, detailed: boolean)
		local c = face * CFrame.new(x, y + wh / 2, 0)
		bit("WindowFrame", Vector3.new(ww + 0.5, wh + 0.5, 0.2), c * CFrame.new(0, 0, -0.1), style.Trim)
		local pane = bit("WindowGlass", Vector3.new(ww, wh, 0.12), c * CFrame.new(0, 0, -0.22), glass, Enum.Material.Glass, 0.1)
		bit("Sill", Vector3.new(ww + 0.9, 0.3, 0.6), c * CFrame.new(0, -wh / 2 - 0.3, -0.3), style.Trim)
		if not detailed then
			return
		end
		bit("MullionV", Vector3.new(0.18, wh, 0.1), c * CFrame.new(0, 0, -0.3), style.Trim)
		bit("MullionH", Vector3.new(ww, 0.18, 0.1), c * CFrame.new(0, wh * 0.15, -0.3), style.Trim)
		if shutter then
			for _, s in { -1, 1 } do
				bit("Shutter", Vector3.new(ww / 2, wh + 0.3, 0.15), c * CFrame.new(s * (ww * 0.75 + 0.4), 0, -0.15), shutter, Enum.Material.WoodPlanks)
			end
		end
		if math.random() < 0.3 then
			bit("FlowerBox", Vector3.new(ww, 0.6, 0.7), c * CFrame.new(0, -wh / 2 - 0.75, -0.55), rgb(150, 100, 60), Enum.Material.Wood)
			bit("Flowers", Vector3.new(ww - 0.2, 0.5, 0.5), c * CFrame.new(0, -wh / 2 - 0.25, -0.55), pick({ rgb(220, 50, 70), rgb(240, 120, 170), rgb(250, 200, 60) }), Enum.Material.Grass)
		end
		-- Por la noche, algunas ventanas tienen la luz encendida
		if math.random() < 0.45 then
			pane:AddTag("NightWindow")
			pane:SetAttribute("DayColor", glass)
			pane:SetAttribute("NightColor", rgb(255, 214, 150))
			pane:SetAttribute("OnAt", 18.5 + math.random() * 1.5)
			pane:SetAttribute("OffAt", 22.5 + math.random() * 2)
		end
	end

	local front = at(0, 0, -d / 2)
	local back = at(0, 0, d / 2) * CFrame.Angles(0, math.pi, 0)
	local left = at(-w / 2, 0, 0) * CFrame.Angles(0, math.rad(-90), 0)
	local right = at(w / 2, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
	local bigWindows = styleName == "Moderna"
	local doorX = -w / 5
	for f = 1, floors do
		local y = (f - 1) * FH + 2.8
		if f == 1 then
			-- planta baja: una ventana grande al otro lado de la puerta
			window(front, w / 4, y, if bigWindows then w * 0.4 else 4.4, if bigWindows then 6 else 4.6, true)
		else
			for _, x in { -w / 4, w / 4 } do
				window(front, x, y, if bigWindows then w * 0.3 else 3.6, 4.4, true)
			end
		end
		window(back, 0, y, 4, 4.4, false)
		window(left, 0, y, 3.6, 4.4, false)
		window(right, 0, y, 3.6, 4.4, false)
	end

	---------------------------------------------------------------------
	-- Puerta de entrada
	---------------------------------------------------------------------
	local door = front * CFrame.new(doorX, 0, 0)
	bit("DoorFrame", Vector3.new(4.6, 8.2, 0.25), door * CFrame.new(0, 4.1, -0.12), style.Trim)
	local doorColor = if shutter then shutter else pick({ rgb(90, 60, 40), rgb(40, 50, 60), rgb(150, 40, 40) })
	solid("Door", Vector3.new(3.8, 7.4, 0.3), door * CFrame.new(0, 3.9, -0.25), doorColor, Enum.Material.Wood)
	for _, y in { 2.2, 5.4 } do
		bit("DoorPanel", Vector3.new(2.6, 2.4, 0.08), door * CFrame.new(0, y, -0.44), doorColor:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Wood)
	end
	bit("DoorKnob", Vector3.new(0.3, 0.3, 0.3), door * CFrame.new(1.3, 3.8, -0.5), rgb(210, 180, 90), Enum.Material.Metal)
	bit("Step", Vector3.new(5.4, 0.5, 2), door * CFrame.new(0, 0.25, -1), rgb(200, 196, 188), Enum.Material.Concrete)
	bit("Doormat", Vector3.new(3, 0.06, 1.3), door * CFrame.new(0, 0.53, -1.1), rgb(120, 90, 60), Enum.Material.Fabric)
	local lamp = bit("WallLamp", Vector3.new(0.5, 0.8, 0.5), door * CFrame.new(-2.9, 6.4, -0.4), rgb(255, 226, 170), Enum.Material.Neon)
	lamp:AddTag("NightWindow") -- farol: se enciende de noche
	lamp:SetAttribute("DayColor", rgb(230, 226, 214))
	lamp:SetAttribute("NightColor", rgb(255, 214, 150))
	lamp:SetAttribute("OnAt", 19)
	lamp:SetAttribute("OffAt", 23.5)
	bit("HouseNumber", Vector3.new(1, 0.7, 0.08), door * CFrame.new(2.9, 6.4, -0.12), rgb(40, 40, 44))

	---------------------------------------------------------------------
	-- Balcón, porche, garaje y extras
	---------------------------------------------------------------------
	if floors >= 2 and (opts.Balcony or (opts.Balcony == nil and math.random() < 0.45)) then
		local b = front * CFrame.new(w / 4, FH, -1.4)
		bit("Balcony", Vector3.new(5.6, 0.4, 2.8), b, style.Trim, Enum.Material.Concrete)
		if styleName == "Moderna" then
			bit("BalconyGlass", Vector3.new(5.6, 2.4, 0.12), b * CFrame.new(0, 1.4, -1.35), rgb(180, 210, 225), Enum.Material.Glass, 0.5)
		else
			bit("Railing", Vector3.new(5.6, 0.2, 0.2), b * CFrame.new(0, 2.6, -1.35), rgb(40, 40, 44), Enum.Material.Metal)
			for k = -2, 2 do
				bit("Baluster", Vector3.new(0.12, 2.4, 0.12), b * CFrame.new(k * 1.35, 1.4, -1.35), rgb(40, 40, 44), Enum.Material.Metal)
			end
		end
	end
	if opts.Porch or (opts.Porch == nil and not flat and math.random() < 0.35) then
		local p = front * CFrame.new(doorX, 0, -3)
		bit("PorchRoof", Vector3.new(7, 0.5, 5), p * CFrame.new(0, 8.6, 0.5), roofColor, style.RoofMaterial)
		for _, x in { -3.1, 3.1 } do
			bit("PorchPost", Vector3.new(0.5, 8.4, 0.5), p * CFrame.new(x, 4.2, -1.6), style.Trim, Enum.Material.Wood)
		end
	end
	if opts.Garage or (opts.Garage == nil and math.random() < 0.4) then
		local g = at(w / 2 + 6.5, 0, -d * 0.1)
		solid("Garage", Vector3.new(12, 9, d * 0.7), g * CFrame.new(0, 4.5, 0), wall, style.WallMaterial)
		bit("GarageRoof", Vector3.new(12.6, 0.6, d * 0.7 + 0.6), g * CFrame.new(0, 9.3, 0), roofColor, style.RoofMaterial)
		local gd = g * CFrame.new(0, 0, -d * 0.35)
		bit("GarageDoor", Vector3.new(10, 7.4, 0.25), gd * CFrame.new(0, 3.9, -0.12), rgb(226, 226, 222), Enum.Material.Metal)
		for k = 1, 4 do
			bit("GarageLine", Vector3.new(10, 0.1, 0.05), gd * CFrame.new(0, k * 1.5, -0.27), rgb(170, 170, 170))
		end
		bit("Drive", Vector3.new(10, 0.2, 14), gd * CFrame.new(0, 0.1, -7), rgb(170, 168, 164), Enum.Material.Pavement)
	end
	if math.random() < 0.4 then
		-- Aire acondicionado en un lateral
		local ac = right * CFrame.new(d / 5, 3.5, -0.8)
		bit("ACUnit", Vector3.new(2.4, 1.8, 1.2), ac, rgb(236, 236, 234), Enum.Material.Metal)
		bit("ACGrille", Vector3.new(1.4, 1.4, 0.05), ac * CFrame.new(-0.3, 0, -0.62), rgb(110, 112, 116), Enum.Material.DiamondPlate)
	end
	if math.random() < 0.25 then
		local dish = right * CFrame.new(-d / 5, h - 1.5, -0.6)
		cyl("Dish", 0.2, 2, dish * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(20)), rgb(236, 236, 236))
		bit("DishArm", Vector3.new(0.12, 0.12, 1), dish * CFrame.new(0, 0, -0.5), rgb(120, 120, 124), Enum.Material.Metal)
	end

	---------------------------------------------------------------------
	-- Jardín delantero: camino, valla con cancela, buzón, cubos, farolillos y flores
	---------------------------------------------------------------------
	if opts.Yard ~= false then
		local yard = 10 -- de la fachada a la valla
		bit("Path", Vector3.new(3.4, 0.2, yard), front * CFrame.new(doorX, 0.1, -yard / 2 - 1), rgb(206, 196, 178), Enum.Material.Pavement)
		local fenceColor = if styleName == "Colonial" or styleName == "Mediterranea" then rgb(245, 245, 242) else rgb(60, 60, 64)
		for _, span in { { -w / 2 - 1, doorX - 2 }, { doorX + 2, w / 2 + 1 } } do
			local len = span[2] - span[1]
			if len > 1 then
				local mid = (span[1] + span[2]) / 2
				local fc = front * CFrame.new(mid, 0, -yard - 1)
				bit("FenceRail", Vector3.new(len, 0.25, 0.2), fc * CFrame.new(0, 2.6, 0), fenceColor, Enum.Material.Wood)
				bit("FenceRail", Vector3.new(len, 0.25, 0.2), fc * CFrame.new(0, 1.2, 0), fenceColor, Enum.Material.Wood)
				bit("FencePickets", Vector3.new(len, 2.8, 0.1), fc * CFrame.new(0, 1.6, 0.12), fenceColor, Enum.Material.WoodPlanks)
			end
		end
		for _, x in { doorX - 2, doorX + 2 } do
			bit("GatePost", Vector3.new(0.5, 3.4, 0.5), front * CFrame.new(x, 1.7, -yard - 1), fenceColor, Enum.Material.Wood)
		end
		-- Buzón
		local mailbox = front * CFrame.new(doorX + 3.6, 0, -yard - 1.8)
		bit("MailboxPost", Vector3.new(0.3, 3.2, 0.3), mailbox * CFrame.new(0, 1.6, 0), rgb(60, 60, 64), Enum.Material.Metal)
		bit("Mailbox", Vector3.new(1.1, 0.9, 1.5), mailbox * CFrame.new(0, 3.5, 0), pick({ rgb(200, 40, 40), rgb(40, 60, 120), rgb(40, 40, 44) }), Enum.Material.Metal)
		-- Cubos de basura junto a la valla
		for k, color in { rgb(40, 110, 60), rgb(60, 60, 64) } do
			bit("Bin", Vector3.new(1.4, 2.4, 1.4), front * CFrame.new(-w / 2 + 1.2 + (k - 1) * 1.6, 1.2, -yard + 0.2), color, Enum.Material.Plastic)
		end
		-- Farolillos del camino y flores
		if math.random() < 0.5 then
			for _, z in { -3.5, -7.5 } do
				local post = front * CFrame.new(doorX - 2.2, 0, z)
				bit("GardenLight", Vector3.new(0.3, 1.4, 0.3), post * CFrame.new(0, 0.7, 0), rgb(40, 40, 44), Enum.Material.Metal)
				bit("GardenLamp", Vector3.new(0.5, 0.4, 0.5), post * CFrame.new(0, 1.55, 0), rgb(255, 230, 170), Enum.Material.Neon)
			end
		end
		Nature.flowerBed(m, front * CFrame.new(w / 4, 0, -2.2), math.min(w * 0.4, 8), 2)
		if math.random() < 0.6 then
			Nature.bush(m, (front * CFrame.new(w / 2 - 1.5, 0, -4)).Position)
		end
	end
	return m
end

return HouseKit
