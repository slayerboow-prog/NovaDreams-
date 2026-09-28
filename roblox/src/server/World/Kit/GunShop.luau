-- GunShop: las Armerías de Valmar (lo usan Districts para construirlas y WeaponService para
-- venderlas, sacarse la licencia y practicar).
--
--   GunShop.build(parent, cf, W, D, name)  el interior de la tienda (cf = centro del suelo, mirando
--        a la calle: -Z es la puerta). Deja:
--          GunShop         mostrador de cristal con pistolas y cajas de munición (StaffSpot = dónde
--                          se pone el dependiente; ShopName = nombre de la tienda)
--          GunLicence      ventanilla de LICENCIAS (tasa + test de seguridad)
--          JobBoard        tablón del oficio de armero/a (JobId = "Armero")
--          ShootingRange   volumen invisible de la galería de tiro del fondo: ahí disparar no es delito
--          RangeTarget     dianas de las calles de tiro (Lane = 1..3): marcan los impactos y la puntuación
--        y además: caja registradora, armero de pared con fusiles y escopetas, carteles, cámara de
--        seguridad, lámparas y suelo de tarima.
--   GunShop.bars(parent, cf, W, D)  rejas en el escaparate (por fuera, dejando libre la puerta)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.Parent.Builder)
local WeaponModel = require(script.Parent.WeaponModel)
local Weapons = require(ReplicatedStorage.Shared.Weapons)

local GunShop = {}

local rgb = Color3.fromRGB
local DARK = rgb(34, 34, 38)
local WOOD = rgb(92, 62, 40)
local STEEL = rgb(70, 72, 78)

-- Un arma de adorno (anclada) colocada en cf
local function display(parent: Instance, id: string, cf: CFrame)
	local w = Weapons.get(id)
	if not w then
		return
	end
	local model = WeaponModel.build(w, 1, true)
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.CFrame = cf * part.CFrame
		end
	end
	model.Name = "Expositor_" .. id
	model.Parent = parent
end

local function poster(parent: Instance, cf: CFrame, size: Vector3, text: string, color: Color3)
	local board = Builder.decor({ Name = "Cartel", Size = size, CFrame = cf, Color = color, Parent = parent })
	Builder.sign(board, text, Enum.NormalId.Front, Color3.new(1, 1, 1))
	return board
end

function GunShop.build(parent: Instance, cf: CFrame, W: number, D: number, name: string)
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	-- Suelo de tarima oscura en la tienda y de hormigón en la galería
	Builder.decor({ Name = "Tarima", Size = Vector3.new(W - 2, 0.1, D / 2), CFrame = at(0, 0.06, -D / 4 - 0.5), Color = rgb(96, 70, 50), Material = Enum.Material.WoodPlanks, Parent = parent })
	Builder.decor({ Name = "SueloGaleria", Size = Vector3.new(W - 2, 0.1, D / 2 - 1), CFrame = at(0, 0.06, D / 4), Color = rgb(120, 120, 124), Material = Enum.Material.Concrete, Parent = parent })

	-- Mostrador de cristal (a lo ancho, delante del dependiente)
	local counter = Builder.part({
		Name = "GunShopCounter",
		Size = Vector3.new(14, 3.2, 2.4),
		CFrame = at(4, 1.6, -4),
		Color = DARK,
		Material = Enum.Material.Metal,
		Tags = { "GunShop" },
		Attributes = { StaffSpot = at(4, 0.4, -1.8).Position, ShopName = name },
		Parent = parent,
	})
	Builder.decor({ Name = "Vitrina", Size = Vector3.new(14, 0.9, 2.4), CFrame = at(4, 3.65, -4), Color = rgb(200, 225, 240), Material = Enum.Material.Glass, Transparency = 0.6, Parent = parent })
	for i, id in { "Pistola", "Revolver", "PistolaAgua", "Taser" } do
		if id ~= "Taser" then
			display(parent, id, at(-1 + i * 3, 3.35, -4) * CFrame.Angles(0, math.rad(90), math.rad(90)))
		end
	end
	for i = 0, 4 do
		local box = Builder.decor({ Name = "CajaMunicion", Size = Vector3.new(0.9, 0.5, 0.6), CFrame = at(-2 + i * 1.4, 3.45, -3.3), Color = if i % 2 == 0 then rgb(200, 160, 40) else rgb(170, 40, 40), Parent = parent })
		local _ = box
	end
	-- Caja registradora
	Builder.decor({ Name = "Caja", Size = Vector3.new(1.6, 1, 1.2), CFrame = at(9.5, 3.7, -4), Color = rgb(40, 40, 44), Parent = parent })
	Builder.decor({ Name = "PantallaCaja", Size = Vector3.new(1.2, 0.8, 0.1), CFrame = at(9.5, 4.5, -4.3) * CFrame.Angles(math.rad(-15), 0, 0), Color = rgb(60, 200, 120), Material = Enum.Material.Neon, Parent = parent })

	-- Armero de pared con fusiles y escopetas (pared izquierda)
	local rackX = -W / 2 + 1.3
	Builder.decor({ Name = "Armero", Size = Vector3.new(0.5, 8, 12), CFrame = at(rackX - 0.4, 5, -10), Color = WOOD, Material = Enum.Material.Wood, Parent = parent })
	local longGuns = { "Fusil", "Escopeta", "Subfusil", "Francotirador", "Paintball", "Fusil" }
	for i, id in longGuns do
		-- De pie, con el cañón hacia arriba, mirando a la tienda
		display(parent, id, at(rackX + 0.2, 1.8, -15 + i * 1.8) * CFrame.Angles(math.rad(90), 0, 0) * CFrame.Angles(0, 0, math.rad(90)))
	end
	poster(parent, at(rackX + 0.2, 10, -10) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(10, 1.6, 0.2), "🔫 ARMAS LARGAS", rgb(120, 30, 30))

	-- Ventanilla de licencias (a la izquierda del mostrador)
	local desk = Builder.part({
		Name = "LicenceDesk",
		Size = Vector3.new(5, 3.4, 2),
		CFrame = at(-8, 1.7, -4),
		Color = rgb(60, 70, 90),
		Tags = { "GunLicence" },
		Parent = parent,
	})
	local _ = desk
	poster(parent, at(-8, 5.6, -4.9), Vector3.new(5, 1.4, 0.2), "🪪 LICENCIAS", rgb(30, 60, 120))

	-- Tablón del oficio (junto a la puerta)
	Builder.part({ Name = "JobBoard", Size = Vector3.new(4, 3, 0.3), CFrame = at(W / 2 - 2.5, 4.8, -D / 2 + 1.6) * CFrame.Angles(0, math.rad(180), 0), Color = rgb(34, 108, 196), Tags = { "JobBoard" }, Attributes = { JobId = "Armero" }, Parent = parent })

	-- Carteles, cámara de seguridad y lámparas
	poster(parent, at(W / 2 - 1.2, 8, -8) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(7, 2.6, 0.2), "SEGURIDAD ANTE TODO\nNunca apuntes a nadie", rgb(160, 110, 20))
	poster(parent, at(W / 2 - 1.2, 8, -14) * CFrame.Angles(0, math.rad(-90), 0), Vector3.new(5, 2.4, 0.2), "SOLO MAYORES\nCON LICENCIA", rgb(140, 30, 30))
	local camera = Builder.decor({ Name = "CamaraSeguridad", Size = Vector3.new(0.7, 0.6, 1.3), CFrame = at(W / 2 - 1.5, 13, -D / 2 + 2) * CFrame.Angles(math.rad(-25), math.rad(-135), 0), Color = rgb(230, 230, 232), Parent = parent })
	Builder.decor({ Name = "LedCamara", Size = Vector3.new(0.15, 0.15, 0.1), CFrame = camera.CFrame * CFrame.new(0.2, 0.2, -0.66), Color = rgb(255, 40, 40), Material = Enum.Material.Neon, Parent = parent })
	for _, z in { -12, -5, 4, 11 } do
		for _, x in { -W / 4, W / 4 } do
			local lamp = Builder.decor({ Name = "Lampara", Size = Vector3.new(4, 0.3, 0.8), CFrame = at(x, 14.2, z), Color = rgb(255, 246, 220), Material = Enum.Material.Neon, Parent = parent })
			if z == -5 or z == 11 then
				local light = Instance.new("PointLight")
				light.Range = 22
				light.Brightness = 0.8
				light.Shadows = false
				light.Parent = lamp
			end
		end
	end

	-- Galería de tiro al fondo: tabique con cristal, 3 calles con cabinas y dianas
	local rangeFront = 1
	Builder.part({ Name = "Tabique", Size = Vector3.new(W - 8, 4, 0.6), CFrame = at(4, 2, rangeFront), Color = rgb(90, 92, 98), Parent = parent })
	Builder.part({ Name = "CristalGaleria", Size = Vector3.new(W - 8, 6, 0.3), CFrame = at(4, 7, rangeFront), Color = rgb(190, 215, 230), Material = Enum.Material.Glass, Transparency = 0.55, Parent = parent })
	poster(parent, at(4, 11.3, rangeFront - 0.4) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(10, 1.6, 0.2), "🎯 GALERÍA DE TIRO", rgb(30, 110, 60))
	local volume = Builder.part({
		Name = "GaleriaDeTiro",
		Size = Vector3.new(W - 2, 12, D / 2 - rangeFront - 1),
		CFrame = at(0, 6, (rangeFront + D / 2) / 2),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Tags = { "ShootingRange" },
		Parent = parent,
	})
	local _ = volume
	local backstop = D / 2 - 1.2
	Builder.part({ Name = "Parabalas", Size = Vector3.new(W - 2, 12, 0.8), CFrame = at(0, 6, backstop), Color = rgb(40, 36, 34), Material = Enum.Material.Rubber, Parent = parent })
	for lane = 1, 3 do
		local x = (lane - 2) * 8
		-- Cabina: dos mamparas y una repisa
		Builder.part({ Name = "Mampara", Size = Vector3.new(0.3, 5, 3), CFrame = at(x - 3.8, 2.5, rangeFront + 2.5), Color = rgb(110, 112, 118), Parent = parent })
		Builder.part({ Name = "Repisa", Size = Vector3.new(6, 0.3, 1.2), CFrame = at(x, 3.2, rangeFront + 3.4), Color = WOOD, Material = Enum.Material.Wood, Parent = parent })
		Builder.decor({ Name = "Carril", Size = Vector3.new(0.2, 0.2, backstop - rangeFront - 4), CFrame = at(x, 12.5, (rangeFront + 4 + backstop) / 2), Color = STEEL, Material = Enum.Material.Metal, Parent = parent })
		-- Diana de papel colgada del carril
		local target = Builder.part({
			Name = "Diana",
			Size = Vector3.new(3, 4, 0.1),
			CFrame = at(x, 5.5, backstop - 2) * CFrame.Angles(0, math.rad(180), 0),
			Color = rgb(240, 236, 226),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Tags = { "RangeTarget" },
			Attributes = { Lane = lane, Score = 0, Shots = 0 },
			Parent = parent,
		})
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Aros"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		gui.LightInfluence = 0.3
		gui.Parent = target
		for ring = 5, 1, -1 do
			local frame = Instance.new("Frame")
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.fromScale(0.5, 0.45)
			frame.Size = UDim2.fromOffset(ring * 11, ring * 11)
			frame.BackgroundColor3 = if ring % 2 == 1 then Color3.new(0.1, 0.1, 0.1) else Color3.new(0.95, 0.95, 0.9)
			frame.BorderSizePixel = 0
			frame.Parent = gui
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = frame
		end
		local score = Instance.new("TextLabel")
		score.Name = "Puntos"
		score.AnchorPoint = Vector2.new(0.5, 1)
		score.Position = UDim2.fromScale(0.5, 1)
		score.Size = UDim2.new(1, 0, 0.16, 0)
		score.BackgroundTransparency = 1
		score.TextScaled = true
		score.TextColor3 = Color3.fromRGB(180, 20, 20)
		score.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
		score.Text = ("CALLE %d · 0 pts"):format(lane)
		score.Parent = gui
	end
end

-- Rejas en los escaparates (por fuera de la fachada, sin tapar la puerta del centro)
function GunShop.bars(parent: Instance, cf: CFrame, W: number, D: number)
	local z = -D / 2 - 0.45
	for x = -W / 2 + 1.5, W / 2 - 1.5, 1.2 do
		if math.abs(x) > 3.2 then
			Builder.decor({ Name = "Reja", Size = Vector3.new(0.14, 9, 0.14), CFrame = cf * CFrame.new(x, 5.8, z), Color = rgb(30, 30, 32), Material = Enum.Material.Metal, Parent = parent })
		end
	end
	for _, y in { 1.6, 10 } do
		for _, side in { -1, 1 } do
			local width = W / 2 - 4.5
			Builder.decor({ Name = "RejaH", Size = Vector3.new(width, 0.16, 0.16), CFrame = cf * CFrame.new(side * (3.5 + width / 2), y, z), Color = rgb(30, 30, 32), Material = Enum.Material.Metal, Parent = parent })
		end
	end
end

return GunShop
