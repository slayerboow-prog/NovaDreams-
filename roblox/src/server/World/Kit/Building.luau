-- Building: generador de edificios con estilo (plantas, ventanas, balcones,
-- contraventanas, cornisas, tejados, escaparates, toldos y carteles).
--
-- Convención: el CFrame del edificio está en el centro de su huella, a nivel
-- del suelo (Y = 0), y su LookVector apunta hacia la calle (la fachada).
-- La planta baja es un interior hueco y jugable; las plantas superiores son fachada.

local Builder = require(script.Parent.Parent.Builder)
local Palette = require(script.Parent.Palette)

local Building = {}

Building.FLOOR_TOP = 1.0 -- altura del suelo interior (igual que la acera)
local FT = Building.FLOOR_TOP
local T = 1 -- grosor de pared
local NIGHT_WINDOW_CHANCE = 0.4

export type Spec = {
	Name: string,
	Parent: Instance,
	CFrame: CFrame,
	Width: number,
	Depth: number,
	Floors: number, -- plantas totales (incluida la baja)
	Style: string, -- clave de Palette.Styles
	GroundFloor: "Shop" | "Lobby" | "House" | "Closed",
	GroundHeight: number?,
	FloorHeight: number?,
	WallColor: Color3?,
	Interior: boolean?, -- planta baja con luz y cristales transparentes
	WindowFaces: { [string]: boolean }?, -- caras con ventanas (por defecto todas)
	Balconies: boolean?,
	Sign: string?,
	SignColor: Color3?,
	Awning: Color3?,
	FloorMaterial: Enum.Material?,
	FloorColor: Color3?,
	LightColor: Color3?,
}

type Opening = { X: number, W: number, Bottom: number, Top: number, Kind: string }

type Ctx = {
	Model: Model,
	Style: Palette.Style,
	WallColor: Color3,
	ShutterColor: Color3?,
	GroundGlassTransparency: number,
}

---------------------------------------------------------------------
-- Piezas básicas
---------------------------------------------------------------------

local function wallPiece(ctx: Ctx, face: CFrame, cx: number, cy: number, w: number, h: number)
	if w < 0.05 or h < 0.05 then
		return
	end
	Builder.part({
		Name = "Wall",
		Size = Vector3.new(w, h, T),
		CFrame = face * CFrame.new(cx, cy, T / 2),
		Color = ctx.WallColor,
		Material = ctx.Style.WallMaterial,
		Parent = ctx.Model,
	})
end

local function trim(ctx: Ctx, face: CFrame, size: Vector3, x: number, y: number, z: number)
	Builder.decor({
		Name = "Trim",
		Size = size,
		CFrame = face * CFrame.new(x, y, z),
		Color = ctx.Style.Trim,
		Material = ctx.Style.TrimMaterial,
		Parent = ctx.Model,
	})
end

local function glass(ctx: Ctx, face: CFrame, o: Opening, transparency: number, nightChance: number)
	local h = o.Top - o.Bottom
	local color = if transparency > 0 then Color3.fromRGB(176, 206, 220) else ctx.Style.Glass
	local pane = Builder.part({
		Name = "Glass",
		Size = Vector3.new(o.W, h, 0.2),
		CFrame = face * CFrame.new(o.X, o.Bottom + h / 2, T * 0.55),
		Color = color,
		Material = Enum.Material.Glass,
		Transparency = transparency,
		Reflectance = 0.15,
		Parent = ctx.Model,
	})
	if math.random() < nightChance then
		pane:AddTag("NightWindow")
		pane:SetAttribute("DayColor", color)
	end
end

local function fillOpening(ctx: Ctx, face: CFrame, o: Opening)
	local h = o.Top - o.Bottom
	local style = ctx.Style
	if o.Kind == "Window" or o.Kind == "Balcony" or o.Kind == "GroundWindow" then
		local isGround = o.Kind == "GroundWindow"
		glass(ctx, face, o, if isGround then ctx.GroundGlassTransparency else 0, if isGround then 0 else NIGHT_WINDOW_CHANCE)
		if o.Kind ~= "Balcony" then
			trim(ctx, face, Vector3.new(o.W + 0.6, 0.3, 0.7), o.X, o.Bottom - 0.15, -0.15) -- alféizar
		end
		if style.Lintels then
			trim(ctx, face, Vector3.new(o.W + 0.8, 0.5, 0.35), o.X, o.Top + 0.25, -0.1) -- dintel
		end
		if ctx.ShutterColor then
			for _, side in { -1, 1 } do
				Builder.decor({
					Name = "Shutter",
					Size = Vector3.new(o.W / 2, h, 0.15),
					CFrame = face * CFrame.new(o.X + side * (o.W * 0.75 + 0.15), o.Bottom + h / 2, -0.08),
					Color = ctx.ShutterColor,
					Material = Enum.Material.Wood,
					Parent = ctx.Model,
				})
			end
		end
		if o.Kind == "Balcony" and style.Balconies ~= "None" then
			local bw = o.W + 2.4
			Builder.part({
				Name = "BalconySlab",
				Size = Vector3.new(bw, 0.4, 2.2),
				CFrame = face * CFrame.new(o.X, o.Bottom - 0.2, -1.1),
				Color = style.Trim,
				Material = style.TrimMaterial,
				Parent = ctx.Model,
			})
			local iron = style.Balconies == "Iron"
			Builder.decor({
				Name = "Railing",
				Size = Vector3.new(bw, 3, 0.1),
				CFrame = face * CFrame.new(o.X, o.Bottom + 1.5, -2.1),
				Color = if iron then Color3.fromRGB(40, 40, 44) else Color3.fromRGB(180, 210, 224),
				Material = if iron then Enum.Material.Metal else Enum.Material.Glass,
				Transparency = if iron then 0.6 else 0.6,
				Parent = ctx.Model,
			})
			Builder.decor({
				Name = "BottomRail",
				Size = Vector3.new(bw, 0.2, 0.2),
				CFrame = face * CFrame.new(o.X, o.Bottom + 0.3, -2.1),
				Color = Color3.fromRGB(34, 34, 38),
				Material = Enum.Material.Metal,
				Parent = ctx.Model,
			})
			Builder.decor({
				Name = "Handrail",
				Size = Vector3.new(bw + 0.2, 0.2, 0.25),
				CFrame = face * CFrame.new(o.X, o.Bottom + 3.05, -2.1),
				Color = Color3.fromRGB(34, 34, 38),
				Material = Enum.Material.Metal,
				Parent = ctx.Model,
			})
		end
	elseif o.Kind == "Shop" then
		-- Sin interior jugable: cristal reflectante en vez de ver una sala vacía
		-- Los escaparates se iluminan de noche (comercios abiertos)
		glass(ctx, face, o, if ctx.GroundGlassTransparency > 0 then 0.55 else 0, 1)
		trim(ctx, face, Vector3.new(o.W, 0.3, T + 0.3), o.X, o.Bottom - 0.15, T / 2 - 0.15)
	elseif o.Kind == "Door" or o.Kind == "FakeDoor" then
		for _, side in { -1, 1 } do
			trim(ctx, face, Vector3.new(0.5, h + 0.5, T + 0.4), o.X + side * (o.W / 2 + 0.25), o.Bottom + (h + 0.5) / 2, T / 2)
		end
		trim(ctx, face, Vector3.new(o.W + 1, 0.5, T + 0.4), o.X, o.Top + 0.25, T / 2)
		if o.Kind == "FakeDoor" then
			Builder.part({
				Name = "DoorPanel",
				Size = Vector3.new(o.W, h, 0.3),
				CFrame = face * CFrame.new(o.X, o.Bottom + h / 2, T * 0.6),
				Color = Color3.fromRGB(92, 64, 46),
				Material = Enum.Material.Wood,
				Parent = ctx.Model,
			})
		end
	end
end

-- Pared de una cara (tramo de altura h desde y0) con huecos rectangulares.
local function wallWithOpenings(ctx: Ctx, face: CFrame, L: number, y0: number, h: number, openings: { Opening })
	table.sort(openings, function(a, b)
		return a.X < b.X
	end)
	local cursor = -L / 2
	for _, o in openings do
		local left = o.X - o.W / 2
		wallPiece(ctx, face, (cursor + left) / 2, y0 + h / 2, left - cursor, h)
		wallPiece(ctx, face, o.X, (y0 + o.Bottom) / 2, o.W, o.Bottom - y0)
		wallPiece(ctx, face, o.X, (o.Top + y0 + h) / 2, o.W, y0 + h - o.Top)
		fillOpening(ctx, face, o)
		cursor = o.X + o.W / 2
	end
	wallPiece(ctx, face, (cursor + L / 2) / 2, y0 + h / 2, L / 2 - cursor, h)
end

-- Posiciones X de columnas de ventanas repartidas en una fachada
local function columns(L: number, bay: number, margin: number): { number }
	local n = math.floor((L - 2 * margin) / bay)
	local xs = {}
	for i = 0, n - 1 do
		table.insert(xs, -(n - 1) * bay / 2 + i * bay)
	end
	return xs
end

-- Ventanas a ambos lados de una puerta central
local function columnsAroundDoor(L: number, doorW: number, winW: number, bay: number): { number }
	local xs = {}
	local x = doorW / 2 + 2 + winW / 2
	while x + winW / 2 + 2 <= L / 2 do
		table.insert(xs, -x)
		table.insert(xs, x)
		x += bay
	end
	return xs
end

---------------------------------------------------------------------
-- Edificio completo
---------------------------------------------------------------------

function Building.build(spec: Spec): (Model, (number, number, number) -> CFrame)
	local style: Palette.Style = Palette.Styles[spec.Style] or Palette.Styles.Clasico
	local model = Builder.model(spec.Name, spec.Parent)
	local O = spec.CFrame
	local W, D = spec.Width, spec.Depth
	local floors = math.max(1, spec.Floors)
	local G = spec.GroundHeight or (if spec.GroundFloor == "Shop" then 15 elseif spec.GroundFloor == "House" then 11 else 13)
	local FH = spec.FloorHeight or (if spec.GroundFloor == "House" then 10 else 12)
	local Y1 = FT + G -- techo de la planta baja
	local top = Y1 + (floors - 1) * FH
	local interior = spec.Interior ~= false and spec.GroundFloor ~= "Closed"
	local windowFaces = spec.WindowFaces or { Front = true, Back = true, Left = true, Right = true }

	local ctx: Ctx = {
		Model = model,
		Style = style,
		WallColor = spec.WallColor or Palette.pick(style.Wall),
		ShutterColor = if style.Shutters then Palette.pick(style.Shutters) else nil,
		GroundGlassTransparency = if interior then 0.4 else 0,
	}

	local function at(x: number, y: number, z: number): CFrame
		return O * CFrame.new(x, FT + y, z)
	end

	local faces = {
		{ Name = "Front", CF = O * CFrame.new(0, 0, -D / 2), L = W, Full = W },
		{ Name = "Back", CF = O * CFrame.new(0, 0, D / 2) * CFrame.Angles(0, math.pi, 0), L = W, Full = W },
		{ Name = "Left", CF = O * CFrame.new(-W / 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), L = D - 2 * T, Full = D },
		{ Name = "Right", CF = O * CFrame.new(W / 2, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), L = D - 2 * T, Full = D },
	}

	-- Suelo interior
	Builder.part({
		Name = "Floor",
		Size = Vector3.new(W - 2 * T, FT, D - 2 * T),
		CFrame = O * CFrame.new(0, FT / 2, 0),
		Color = spec.FloorColor or Color3.fromRGB(176, 140, 104),
		Material = spec.FloorMaterial or Enum.Material.WoodPlanks,
		Parent = model,
	})

	for _, face in faces do
		local L = face.L
		local hasWindows = windowFaces[face.Name] == true
		local isFront = face.Name == "Front"

		-- Zócalo de piedra
		trim(ctx, face.CF, Vector3.new(L, FT, 0.3), 0, FT / 2, -0.15)

		-- PLANTA BAJA
		local ground: { Opening } = {}
		if isFront then
			local kind = spec.GroundFloor
			if kind == "Shop" then
				table.insert(ground, { X = 0, W = 8, Bottom = FT, Top = FT + 10, Kind = "Door" })
				local winW = L / 2 - 8
				if winW >= 4 then
					local wx = 4 + 2 + winW / 2
					for _, side in { -1, 1 } do
						table.insert(ground, { X = side * wx, W = winW, Bottom = FT + 1.2, Top = FT + G - 3.5, Kind = "Shop" })
					end
				end
			else
				local doorW = if kind == "House" then 5 else 8
				local doorH = if kind == "House" then 8 else 10
				table.insert(ground, {
					X = 0,
					W = doorW,
					Bottom = FT,
					Top = FT + doorH,
					Kind = if kind == "Closed" then "FakeDoor" else "Door",
				})
				for _, x in columnsAroundDoor(L, doorW, style.WindowW, style.Bay) do
					table.insert(ground, { X = x, W = style.WindowW, Bottom = FT + 3, Top = FT + 3 + math.min(style.WindowH, G - 4.5), Kind = "GroundWindow" })
				end
			end
		elseif hasWindows then
			for _, x in columns(L, style.Bay, 2.5) do
				table.insert(ground, { X = x, W = style.WindowW, Bottom = FT + 3, Top = FT + 3 + math.min(style.WindowH, G - 4.5), Kind = "GroundWindow" })
			end
		end

		if not hasWindows and not isFront then
			-- Cara ciega: una sola pieza de pared de arriba abajo
			wallPiece(ctx, face.CF, 0, top / 2, L, top)
		else
			wallWithOpenings(ctx, face.CF, L, 0, Y1, ground)

			-- PLANTAS SUPERIORES
			local wantBalconies = isFront and (if spec.Balconies ~= nil then spec.Balconies else style.Balconies ~= "None")
			for f = 1, floors - 1 do
				local yb = Y1 + (f - 1) * FH
				local openings: { Opening } = {}
				if hasWindows or isFront then
					for _, x in columns(L, style.Bay, 2.5) do
						local balcony = wantBalconies and (spec.Style ~= "Popular" or math.random() < 0.6)
						local winH = if balcony then math.min(style.WindowH + 1.5, FH - 2) else math.min(style.WindowH, FH - 4.5)
						local bottom = if balcony then yb + 0.4 else yb + 3
						table.insert(openings, { X = x, W = style.WindowW, Bottom = bottom, Top = bottom + winH, Kind = if balcony then "Balcony" else "Window" })
					end
				end
				wallWithOpenings(ctx, face.CF, L, yb, FH, openings)
				-- Imposta (línea entre plantas)
				trim(ctx, face.CF, Vector3.new(face.Full + 0.4, 0.6, 0.4), 0, yb, -0.2)
			end
		end
	end

	-- Techo de la planta baja y luz interior
	Builder.part({
		Name = "Ceiling",
		Size = Vector3.new(W - 2 * T, 1, D - 2 * T),
		CFrame = O * CFrame.new(0, Y1 - 0.5, 0),
		Color = Color3.fromRGB(244, 242, 236),
		Material = Enum.Material.Plaster,
		Parent = model,
	})
	if interior then
		local lamp = Builder.decor({
			Name = "CeilingLamp",
			Size = Vector3.new(3, 0.3, 3),
			CFrame = O * CFrame.new(0, Y1 - 1.15, 0),
			Color = Color3.fromRGB(255, 244, 222),
			Material = Enum.Material.Neon,
			Parent = model,
		})
		local light = Instance.new("PointLight")
		light.Range = math.min(60, math.max(W, D) * 0.8)
		light.Brightness = 1.1
		light.Color = spec.LightColor or Color3.fromRGB(255, 232, 200)
		light.Shadows = false
		light.Parent = lamp
	end

	-- CUBIERTA
	if style.Roof == "Gable" then
		local o = 1.2
		local rh = math.max(4, D * 0.28)
		local depth = D / 2 + o
		for _, side in { -1, 1 } do
			local cf = O * CFrame.new(0, top + rh / 2, side * depth / 2) * (if side > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.new())
			Builder.part({
				ClassName = "WedgePart",
				Name = "Roof",
				Size = Vector3.new(W + 2 * o, rh, depth),
				CFrame = cf,
				Color = style.RoofColor or Color3.fromRGB(176, 86, 56),
				Material = style.RoofMaterial or Enum.Material.ClayRoofTiles,
				Parent = model,
			})
			-- Hastiales (triángulos laterales del color de la pared)
			for _, xs in { -1, 1 } do
				Builder.decor({
					ClassName = "WedgePart",
					Name = "Gable",
					Size = Vector3.new(0.1, rh, depth),
					CFrame = cf * CFrame.new(xs * (W / 2 + o + 0.05), 0, 0),
					Color = ctx.WallColor,
					Material = style.WallMaterial,
					Parent = model,
				})
			end
		end
		Builder.part({
			Name = "Chimney",
			Size = Vector3.new(2, rh + 2, 2),
			CFrame = O * CFrame.new(W / 4, top + (rh + 2) / 2, D / 6),
			Color = ctx.WallColor,
			Material = style.WallMaterial,
			Parent = model,
		})
	else
		Builder.part({
			Name = "Roof",
			Size = Vector3.new(W, 1, D),
			CFrame = O * CFrame.new(0, top + 0.5, 0),
			Color = Color3.fromRGB(130, 128, 124),
			Material = Enum.Material.Concrete,
			Parent = model,
		})
		-- Cornisa / pretil
		for _, face in faces do
			local length = if face.Name == "Front" or face.Name == "Back" then W + 1.8 else D - 0.6
			trim(ctx, face.CF, Vector3.new(length, 2.4, 1.2), 0, top + 1.2, -0.3)
		end
		-- Máquinas en la azotea
		if W > 16 and D > 16 then
			for i = 1, math.random(1, 3) do
				Builder.decor({
					Name = "RoofUnit",
					Size = Vector3.new(3, 2, 2.5),
					CFrame = O * CFrame.new((i - 2) * 5, top + 2, D / 4),
					Color = Color3.fromRGB(190, 192, 196),
					Material = Enum.Material.Metal,
					Parent = model,
				})
			end
		end
	end

	-- Cartel y toldos (comercios)
	if spec.Sign then
		local signPart = Builder.decor({
			Name = "Sign",
			Size = Vector3.new(math.min(W * 0.6, 28), 2.6, 0.3),
			CFrame = O * CFrame.new(0, Y1 - 1.8, -D / 2 - 0.15),
			Color = spec.SignColor or Color3.fromRGB(30, 34, 46),
			Parent = model,
		})
		Builder.sign(signPart, spec.Sign, Enum.NormalId.Front)
	end
	if spec.Awning and spec.GroundFloor == "Shop" then
		local winW = W / 2 - 8
		if winW >= 4 then
			local wx = 6 + winW / 2
			for _, side in { -1, 1 } do
				Builder.decor({
					Name = "Awning",
					Size = Vector3.new(winW + 1, 0.2, 3.2),
					CFrame = O * CFrame.new(side * wx, FT + G - 4.0, -D / 2 - 1.5) * CFrame.Angles(math.rad(-18), 0, 0),
					Color = spec.Awning,
					Material = Enum.Material.Fabric,
					Parent = model,
				})
			end
		end
	end

	model.PrimaryPart = model:FindFirstChild("Floor") :: BasePart
	return model, at
end

return Building
