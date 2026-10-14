-- AirArena: las piezas del combate aéreo (la arena de pruebas, la nave del jugador y los enemigos).
--
--   AirArena.build()                 la arena (una sola vez; la llama AirCombatService al entrar el
--                                    primero, nunca al arrancar el servidor): meseta con agujas de roca,
--                                    anillos que marcan la subida al espacio, campo de asteroides y las
--                                    balizas de los puntos de control. Formas de shared/AirCombat/Arena.
--   AirArena.ship(cf, color?)        la nave del jugador: Root (invisible, la mueve el ordenador del piloto)
--                                    con las piezas soldadas y el asiento "ShipSeat"
--   AirArena.enemy(kind, cf)         un dron, un caza enemigo o una torreta (Root anclado; lo mueve el
--                                    servidor); la torreta lleva además su base quieta ("Base")
--
-- Sin marcas, logos ni nada real: formas sencillas, metal, cristal y luces de neón.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arena = require(ReplicatedStorage.Shared.AirCombat.Arena)

local AirArena = {}

AirArena.Name = "AirArena"

local rgb = Color3.fromRGB

local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.ClassName or "Part") :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "ClassName" and k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

local function persistentPerPlayer(model: Model)
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	end)
end

local built: Model? = nil

function AirArena.get(): Model?
	return if built and built.Parent then built else nil
end

function AirArena.build(): Model
	local existing = AirArena.get()
	if existing then
		return existing
	end
	local model = Instance.new("Model")
	model.Name = AirArena.Name
	persistentPerPlayer(model)
	local O = Arena.Origin
	-- La meseta (en baldosas: una pieza no puede pasar de 2048 studs)
	local tiles = 3
	local side = Arena.SlabHalf * 2 / tiles
	for i = 0, tiles - 1 do
		for j = 0, tiles - 1 do
			local x = -Arena.SlabHalf + side * (i + 0.5)
			local z = -Arena.SlabHalf + side * (j + 0.5)
			part({
				Name = "Meseta",
				Size = Vector3.new(side, 40, side),
				CFrame = CFrame.new(O + Vector3.new(x, Arena.GroundY - 20, z)),
				Material = Enum.Material.Sand,
				Color = if (i + j) % 2 == 0 then rgb(196, 160, 118) else rgb(186, 150, 110),
				CanCollide = true,
				Parent = model,
			})
		end
	end
	-- Agujas de roca (la caja de choque es la de Arena.rocks; la punta, más estrecha, va dentro)
	for i, box in Arena.rocks() do
		local tone = 0.85 + (i % 5) * 0.04
		local base = part({
			Name = "Roca",
			Size = Vector3.new(box.Size.X, box.Size.Y * 0.7, box.Size.Z),
			CFrame = CFrame.new(box.Center - Vector3.new(0, box.Size.Y * 0.15, 0)),
			Material = Enum.Material.Rock,
			Color = Color3.new(0.55 * tone, 0.42 * tone, 0.33 * tone),
			CanCollide = true,
			CastShadow = true,
			Parent = model,
		})
		base:SetAttribute("AirSolid", true)
		part({
			Name = "RocaPunta",
			Size = Vector3.new(box.Size.X * 0.65, box.Size.Y * 0.3, box.Size.Z * 0.65),
			CFrame = CFrame.new(box.Center + Vector3.new(0, box.Size.Y * 0.35, 0)) * CFrame.Angles(0, math.rad(17 * i), 0),
			Material = Enum.Material.Slate,
			Color = Color3.new(0.6 * tone, 0.47 * tone, 0.37 * tone),
			CanCollide = true,
			CastShadow = true,
			Parent = model,
		})
	end
	-- Anillos de la subida al espacio (encima del centro): se ven desde lejos
	for k, y in { Arena.SpaceY - 900, Arena.SpaceY - 450, Arena.SpaceY - 60 } do
		local center = O + Vector3.new(0, y, -200 + k * 60)
		local radius = 120
		for s = 1, 16 do
			local a = (s - 1) / 16 * math.pi * 2
			local p = center + Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
			part({
				Name = "AnilloEspacio",
				Size = Vector3.new(10, 48, 10),
				CFrame = CFrame.new(p) * CFrame.Angles(0, 0, a),
				Material = Enum.Material.Neon,
				Color = rgb(90, 200, 255),
				Transparency = 0.15,
				Parent = model,
			})
		end
	end
	-- Asteroides
	for i, ball in Arena.asteroids() do
		local tone = 0.7 + (i % 4) * 0.08
		local p = part({
			Name = "Asteroide",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * ball.Radius * 2,
			CFrame = CFrame.new(ball.Center) * CFrame.Angles(i, i * 0.7, i * 1.3),
			Material = if i % 3 == 0 then Enum.Material.Basalt else Enum.Material.Rock,
			Color = Color3.new(0.42 * tone, 0.4 * tone, 0.43 * tone),
			CanCollide = true,
			Parent = model,
		})
		p:SetAttribute("AirSolid", true)
		-- Un trozo pegado para que no parezca una bola perfecta
		part({
			Name = "AsteroideTrozo",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * ball.Radius * 1.1,
			CFrame = CFrame.new(ball.Center + Vector3.new(ball.Radius * 0.55, ball.Radius * 0.2, -ball.Radius * 0.3)),
			Material = Enum.Material.Rock,
			Color = Color3.new(0.36 * tone, 0.34 * tone, 0.37 * tone),
			Parent = model,
		})
	end
	-- Balizas de los puntos de control (donde reapareces)
	for _, section in { "Atmos", "Space" } do
		local cp = Arena.checkpoint(section)
		for s = 1, 12 do
			local a = (s - 1) / 12 * math.pi * 2
			part({
				Name = "Control" .. section,
				Size = Vector3.new(6, 6, 6),
				CFrame = cp * CFrame.new(math.cos(a) * 40, math.sin(a) * 40, 30),
				Material = Enum.Material.Neon,
				Color = if section == "Space" then rgb(190, 120, 255) else rgb(80, 255, 160),
				Transparency = 0.2,
				Parent = model,
			})
		end
	end
	model.Parent = workspace
	built = model
	return model
end

-- Suelda las piezas de un modelo a su Root (sin masa, sin choques: las mueve el Root)
local function weldAll(model: Model, root: BasePart)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			d.Anchored = false
			d.Massless = true
			d.CanCollide = false
			d.CanTouch = false
			pcall(function()
				d.CanQuery = false
			end)
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = d
			w.Parent = d
		end
	end
end

-- La nave del jugador: el morro hacia -Z, el centro del Root en el centro de la nave
function AirArena.ship(cf: CFrame, color: Color3?): Model
	local model = Instance.new("Model")
	model.Name = "Nave"
	persistentPerPlayer(model)
	local body = color or rgb(225, 232, 240)
	local trim = rgb(40, 120, 230)
	local root = part({ Name = "Root", Size = Vector3.new(4, 2, 8), CFrame = cf, Transparency = 1, Parent = model })
	model.PrimaryPart = root
	local function at(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): CFrame
		return cf * CFrame.new(x, y, z) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
	end
	part({ Name = "Casco", Size = Vector3.new(4.4, 2.2, 13), CFrame = at(0, 0, 0.5), Material = Enum.Material.Metal, Color = body, Parent = model })
	part({ ClassName = "WedgePart", Name = "Morro", Size = Vector3.new(4.4, 2.2, 5), CFrame = at(0, 0, -8.5, 0, math.pi, 0), Material = Enum.Material.Metal, Color = body, Parent = model })
	part({ Name = "Franja", Size = Vector3.new(4.5, 0.4, 13.2), CFrame = at(0, 0.3, 0.5), Material = Enum.Material.SmoothPlastic, Color = trim, Parent = model })
	for _, side in { -1, 1 } do
		part({ ClassName = "WedgePart", Name = "Ala", Size = Vector3.new(0.5, 6, 7), CFrame = at(side * 5, -0.4, 2.5, 0, 0, side * math.pi / 2), Material = Enum.Material.Metal, Color = body, Parent = model })
		part({ Name = "PuntaAla", Size = Vector3.new(0.6, 0.6, 3), CFrame = at(side * 8.2, -0.4, 4.2), Material = Enum.Material.Neon, Color = if side < 0 then rgb(255, 70, 70) else rgb(70, 255, 120), Parent = model })
		part({ Name = "Canon", Size = Vector3.new(0.5, 0.5, 4), CFrame = at(side * 2.6, -0.6, -5), Material = Enum.Material.Metal, Color = rgb(60, 64, 72), Parent = model })
		part({ Name = "Motor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 1.6, 1.6), CFrame = at(side * 1.2, 0, 7.4, 0, math.pi / 2, 0), Material = Enum.Material.Neon, Color = rgb(90, 210, 255), Parent = model })
	end
	part({ ClassName = "WedgePart", Name = "Deriva", Size = Vector3.new(0.4, 3, 4), CFrame = at(0, 2.4, 5.5), Material = Enum.Material.Metal, Color = trim, Parent = model })
	part({ Name = "Cabina", Shape = Enum.PartType.Ball, Size = Vector3.new(3.6, 3.6, 3.6), CFrame = at(0, 1.2, -2.6), Material = Enum.Material.Glass, Color = rgb(150, 210, 255), Transparency = 0.55, Parent = model })
	part({ ClassName = "Seat", Name = "ShipSeat", Size = Vector3.new(2, 0.4, 2), CFrame = at(0, 0.9, -0.6), Transparency = 1, Parent = model })
	weldAll(model, root)
	return model
end

-- Enemigos (Root anclado: el servidor lo mueve; el resto soldado)
function AirArena.enemy(kind: string, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = kind
	local root: BasePart
	local function at(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): CFrame
		return cf * CFrame.new(x, y, z) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
	end
	if kind == "Dron" then
		root = part({ Name = "Root", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), CFrame = cf, Material = Enum.Material.Metal, Color = rgb(70, 72, 82), Parent = model })
		part({ Name = "Ojo", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), CFrame = at(0, 0, -2.2), Material = Enum.Material.Neon, Color = rgb(255, 60, 60), Parent = model })
		part({ Name = "Aro", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 8, 8), CFrame = at(0, 0, 0, 0, 0, math.pi / 2), Material = Enum.Material.Neon, Color = rgb(255, 150, 40), Transparency = 0.3, Parent = model })
		for _, side in { -1, 1 } do
			part({ Name = "Antena", Size = Vector3.new(0.3, 2.4, 0.3), CFrame = at(side * 1.4, 2.6, 0.4), Material = Enum.Material.Metal, Color = rgb(40, 40, 46), Parent = model })
		end
	elseif kind == "Caza" then
		root = part({ Name = "Root", Size = Vector3.new(3.2, 1.8, 9), CFrame = cf, Material = Enum.Material.Metal, Color = rgb(70, 50, 96), Parent = model })
		part({ ClassName = "WedgePart", Name = "Morro", Size = Vector3.new(3.2, 1.8, 3.5), CFrame = at(0, 0, -6.2, 0, math.pi, 0), Material = Enum.Material.Metal, Color = rgb(70, 50, 96), Parent = model })
		part({ Name = "Alas", Size = Vector3.new(12, 0.4, 3), CFrame = at(0, -0.2, 1.5), Material = Enum.Material.Metal, Color = rgb(48, 34, 66), Parent = model })
		for _, side in { -1, 1 } do
			part({ Name = "Aleta", Size = Vector3.new(0.4, 3, 2.4), CFrame = at(side * 6, 1, 2), Material = Enum.Material.Neon, Color = rgb(255, 120, 30), Parent = model })
			part({ Name = "Motor", Size = Vector3.new(1, 1, 0.6), CFrame = at(side * 0.9, 0, 4.7), Material = Enum.Material.Neon, Color = rgb(255, 120, 30), Parent = model })
		end
		part({ Name = "Cabina", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = at(0, 1, -1.5), Material = Enum.Material.Glass, Color = rgb(255, 190, 120), Transparency = 0.4, Parent = model })
	else
		-- Torreta: base quieta (anclada aparte) y cabeza que gira (Root)
		local base = part({ Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 9, 9), CFrame = CFrame.new(cf.Position - Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = rgb(60, 62, 70), Parent = model })
		base:SetAttribute("Static", true)
		root = part({ Name = "Root", Shape = Enum.PartType.Ball, Size = Vector3.new(5.5, 5.5, 5.5), CFrame = cf, Material = Enum.Material.Metal, Color = rgb(90, 92, 104), Parent = model })
		for _, side in { -1, 1 } do
			part({ Name = "Canon", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 0.8, 0.8), CFrame = at(side * 1.1, 0, -4, 0, math.pi / 2, 0), Material = Enum.Material.Metal, Color = rgb(40, 40, 46), Parent = model })
		end
		part({ Name = "Luz", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = at(0, 1.6, -2.2), Material = Enum.Material.Neon, Color = rgb(255, 60, 60), Parent = model })
	end
	model.PrimaryPart = root
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root and not d:GetAttribute("Static") then
			d.Anchored = false
			d.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = d
			w.Parent = d
		end
	end
	return model
end

return AirArena
