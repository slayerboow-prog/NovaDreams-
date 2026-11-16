-- BeastKit (servidor): cómo SON las bestias de los planetas, sus guaridas, los alijos escondidos y los
-- Talleres donde se fabrica (datos en shared/Cosmos/Bestiary y shared/Crafting).
--
--   BeastKit.beast(species, id, opts?) → Model   una bestia con Humanoid (anda sola con MoveTo) y piezas
--                                       soldadas a su HumanoidRootPart; cuerpos: Cuadrupedo, Insecto, Serpiente,
--                                       Bipedo; con detalles (colmillos, cuernos, garras, melena, lo de su tierra)
--                                       y, si opts.Champion, campeona (más grande, corona dorada y chispas)
--   BeastKit.lair(parent, lair, cf)     la guarida (roca, hielo, coral, raíces o chatarra; la del jefe, más grande)
--   BeastKit.cache(parent, cache, cf)   un alijo (cofre con aviso «Abrir alijo», etiqueta «Alijo»)
--   BeastKit.bench(parent, cf, colors?) un Taller (yunque, mesa y caldero; aviso «Fabricar», etiqueta «Taller»)

local Builder = require(script.Parent.Parent.Builder)

local BeastKit = {}

local V3 = Vector3.new
local rgb = Color3.fromRGB

local function mat(name: string?): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name or "SmoothPlastic"]
	end)
	return if ok and m then m else Enum.Material.SmoothPlastic
end

---------------------------------------------------------------------
-- Bestias
---------------------------------------------------------------------
-- Una pieza soldada a la raíz (offset en el espacio de la raíz: -Z es delante)
local function limb(model: Model, root: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = root.CFrame * offset
	p.Color = color
	p.Material = material
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
	return p
end

local function eye(model: Model, root: BasePart, offset: CFrame, s: number, glow: Color3)
	local e = limb(model, root, "Ojo", V3(s, s, s), offset, glow, Enum.Material.Neon, Enum.PartType.Ball)
	e.CastShadow = false
end

-- El tema de una especie por su nombre (cuernos de hielo, grietas de lava, púas de sombra…)
local function themeOf(id: string, sp: { [string]: any }): string?
	local function has(...: string): boolean
		for _, w in { ... } do
			if string.find(id, w) then
				return true
			end
		end
		return false
	end
	if has("Hielo", "Artico", "Escarcha", "Invierno", "Durmiente") then
		return "Hielo"
	elseif has("Magma", "Lava", "Volcan", "Salamandra", "Brasa", "Colada") then
		return "Lava"
	elseif has("Sombr", "Corrupto", "Vacio") then
		return "Sombra"
	elseif has("Piedra", "Ruinas", "Desierto", "Coloso", "Espectral") then
		return "Piedra"
	elseif has("Bosque", "Madera", "Ancestral", "Liana", "Corteza") then
		return "Bosque"
	end
	return nil
end

local IVORY = rgb(236, 228, 204)

-- Los detalles que hacen que una bestia no parezca una caja con patas: colmillos, cuernos, garras, melena,
-- placas o cristales de su tierra y, si es campeona, corona dorada y chispas
local function details(model: Model, root: BasePart, sp: { [string]: any }, id: string, k: number, champion: boolean)
	local C = sp.Colors
	local body, belly, glow = C.Body, C.Belly, C.Glow
	local m = mat(sp.Material)
	local shape = sp.Body
	local theme = themeOf(id, sp)
	local headPart = model:FindFirstChild("Cabeza") :: BasePart?
	local head = if headPart then root.CFrame:ToObjectSpace(headPart.CFrame) else CFrame.new(0, 0, -2 * k)
	local hs = if headPart then headPart.Size else Vector3.new(k, k, k)
	local function neon(p: BasePart)
		p.Material = Enum.Material.Neon
		p.CastShadow = false
	end
	-- colmillos
	if shape == "Cuadrupedo" or shape == "Serpiente" then
		for _, sx in { -1, 1 } do
			limb(model, root, "Colmillo", V3(0.16 * k, 0.45 * k, 0.16 * k), head * CFrame.new(sx * hs.X * 0.22, -hs.Y * 0.55, -hs.Z * 0.55) * CFrame.Angles(0, 0, sx * 0.15), IVORY, Enum.Material.SmoothPlastic)
		end
	end
	-- defensas de jabalí, oso, foca o cocodrilo
	if string.find(id, "Jabali") or string.find(id, "Foca") or string.find(id, "Oso") then
		for _, sx in { -1, 1 } do
			limb(model, root, "Defensa", V3(0.22 * k, 0.22 * k, 0.9 * k), head * CFrame.new(sx * hs.X * 0.38, -hs.Y * 0.3, -hs.Z * 0.7) * CFrame.Angles(math.rad(35), sx * 0.35, 0), IVORY, Enum.Material.SmoothPlastic)
		end
	end
	-- cuernos (o astas del ciervo)
	if string.find(id, "Ciervo") then
		for _, sx in { -1, 1 } do
			local base = head * CFrame.new(sx * hs.X * 0.3, hs.Y * 0.5, 0.1 * k)
			limb(model, root, "Asta", V3(0.2 * k, 1.6 * k, 0.2 * k), base * CFrame.new(0, 0.7 * k, 0) * CFrame.Angles(0, 0, sx * -0.35), belly, m)
			for j = 1, 3 do
				local p = limb(model, root, "Asta", V3(0.14 * k, 0.8 * k, 0.14 * k), base * CFrame.new(sx * (0.25 + j * 0.15) * k, (0.5 + j * 0.35) * k, -0.1 * k) * CFrame.Angles(0, 0, sx * -0.9), glow, m)
				neon(p)
			end
		end
	elseif theme == "Hielo" or theme == "Sombra" or theme == "Lava" or sp.Boss or sp.Arms then
		local hornColor = if theme == "Hielo" then rgb(200, 235, 255) elseif theme == "Lava" then rgb(40, 30, 28) else rgb(30, 24, 36)
		for _, sx in { -1, 1 } do
			local horn = if sp.Arms then V3(0.3 * k, 0.75 * k, 0.3 * k) else V3(0.25 * k, 1 * k, 0.25 * k)
			local h = limb(model, root, "Cuerno", horn, head * CFrame.new(sx * hs.X * 0.45, hs.Y * 0.6, 0.1 * k) * CFrame.Angles(math.rad(-30), 0, sx * (if sp.Arms then -1.0 else -0.7)), hornColor, if theme == "Hielo" then Enum.Material.Ice else m)
			if theme == "Lava" or theme == "Sombra" then
				local tip = limb(model, root, "Punta", V3(0.2 * k, 0.3 * k, 0.2 * k), root.CFrame:ToObjectSpace(h.CFrame) * CFrame.new(0, horn.Y / 2 + 0.1 * k, 0), glow, m)
				neon(tip)
			end
		end
	end
	-- garras en las patas
	for _, leg in model:GetChildren() do
		if leg:IsA("BasePart") and (leg.Name == "Pata" and shape == "Cuadrupedo" or leg.Name == "Pierna") then
			local rel = root.CFrame:ToObjectSpace(leg.CFrame)
			limb(model, root, "Garra", V3(leg.Size.X * 1.1, 0.22 * k, leg.Size.Z * 1.25), rel * CFrame.new(0, -leg.Size.Y / 2 + 0.1 * k, -0.12 * k), belly:Lerp(Color3.new(0, 0, 0), 0.35), m)
		end
	end
	-- melena de las rápidas (lobos, sabuesos, chacales)
	if shape == "Cuadrupedo" and (sp.Speed or 0) >= 20 then
		for i = 0, 3 do
			limb(model, root, "Melena", V3(1.1 * k - i * 0.12 * k, 0.5 * k, 0.5 * k), CFrame.new(0, 0.95 * k - i * 0.05 * k, -1.7 * k + i * 0.45 * k) * CFrame.Angles(math.rad(-25), 0, 0), body:Lerp(Color3.new(0, 0, 0), 0.25), m)
		end
	end
	-- antenas de los insectos
	if shape == "Insecto" then
		for _, sx in { -1, 1 } do
			limb(model, root, "Antena", V3(0.08 * k, 0.08 * k, 1.3 * k), head * CFrame.new(sx * hs.X * 0.25, hs.Y * 0.5, -hs.Z * 0.6) * CFrame.Angles(math.rad(35), sx * 0.3, 0), belly, m)
		end
		-- bandas que brillan en el abdomen
		local abd = model:FindFirstChild("Abdomen") :: BasePart?
		if abd then
			local rel = root.CFrame:ToObjectSpace(abd.CFrame)
			for j = -1, 1 do
				local band = limb(model, root, "Banda", V3(abd.Size.X * 1.02, abd.Size.Y * 0.18, 0.12 * k), rel * CFrame.new(0, abd.Size.Y * 0.35, j * abd.Size.Z * 0.28), glow, m)
				neon(band)
				band.Transparency = 0.25
			end
		end
	end
	-- aletas a lo largo de las serpientes
	if shape == "Serpiente" then
		for _, seg in model:GetChildren() do
			if seg:IsA("BasePart") and seg.Name == "Cuerpo" then
				local rel = root.CFrame:ToObjectSpace(seg.CFrame)
				limb(model, root, "Aleta", V3(0.12 * k, seg.Size.Y * 0.5, seg.Size.Z * 0.6), rel * CFrame.new(0, seg.Size.Y * 0.62, 0), glow:Lerp(body, 0.5), m)
			end
		end
	end
	-- hombreras y núcleo de los colosos
	if shape == "Bipedo" and sp.Arms then
		for _, arm in model:GetChildren() do
			if arm:IsA("BasePart") and arm.Name == "Brazo" then
				local rel = root.CFrame:ToObjectSpace(arm.CFrame)
				limb(model, root, "Hombrera", V3(arm.Size.X * 1.5, arm.Size.X * 0.7, arm.Size.Z * 1.5), rel * CFrame.new(0, arm.Size.Y / 2, 0), belly, m)
				if theme == "Piedra" or theme == "Bosque" then
					limb(model, root, "Musgo", V3(arm.Size.X * 1.4, 0.15 * k, arm.Size.Z * 1.2), rel * CFrame.new(0, arm.Size.Y / 2 + arm.Size.X * 0.36, 0), rgb(80, 130, 60), Enum.Material.Grass)
				end
			end
		end
		local core = limb(model, root, "Nucleo", V3(0.7 * k, 0.7 * k, 0.7 * k), CFrame.new(0, 0.3 * k, -0.82 * k), glow, m, Enum.PartType.Ball)
		neon(core)
	end
	-- lo de su tierra en el lomo
	local back = CFrame.new(0, root.Size.Y / 2, 0)
	if theme == "Lava" and shape == "Bipedo" then
		-- (de pie: grietas de lava que bajan por el pecho)
		for i = -1, 1, 2 do
			local crack = limb(model, root, "Grieta", V3(0.14 * k, root.Size.Y * 0.55, 0.1 * k), CFrame.new(i * root.Size.X * 0.3, -0.2 * k, -root.Size.Z / 2 - 0.02 * k) * CFrame.Angles(0, 0, i * 0.25), glow, m)
			neon(crack)
		end
	elseif theme == "Lava" then
		for i = -1, 1 do
			local crack = limb(model, root, "Grieta", V3(root.Size.X * 0.6, 0.12 * k, 0.18 * k), back * CFrame.new(0, 0.02 * k, i * root.Size.Z * 0.25) * CFrame.Angles(0, 0.3 * i, 0), glow, m)
			neon(crack)
		end
	elseif theme == "Hielo" then
		for i = -1, 1 do
			limb(model, root, "Cristal", V3(0.35 * k, 0.9 * k, 0.35 * k), back * CFrame.new((i % 2) * 0.3 * k, 0.4 * k, i * root.Size.Z * 0.25) * CFrame.Angles(math.rad(-15), 0, 0.2 * i), rgb(190, 235, 255), Enum.Material.Ice)
		end
	elseif theme == "Sombra" then
		local wisp = Instance.new("ParticleEmitter")
		wisp.Name = "Sombra"
		wisp.Color = ColorSequence.new(rgb(40, 0, 70), rgb(160, 90, 240))
		wisp.Transparency = NumberSequence.new(0.4, 1)
		wisp.Size = NumberSequence.new(k * 0.8, k * 1.6)
		wisp.Lifetime = NumberRange.new(0.8, 1.4)
		wisp.Rate = 6
		wisp.Speed = NumberRange.new(0.5, 1.5)
		wisp.LightEmission = 0.3
		wisp.Parent = root
	elseif theme == "Bosque" and shape ~= "Insecto" then
		limb(model, root, "Hojas", V3(root.Size.X * 0.7, 0.2 * k, root.Size.Z * 0.5), back * CFrame.new(0, 0.05 * k, 0), rgb(70, 140, 60), Enum.Material.Grass)
	end
	-- campeona: corona dorada que flota, luz y chispas
	if champion then
		local gold = rgb(255, 205, 70)
		local crown = head * CFrame.new(0, hs.Y * 0.5 + 1.3 * k, 0)
		for i = 1, 8 do
			local a = i / 8 * math.pi * 2
			local p = limb(model, root, "Corona", V3(0.13 * k, if i % 2 == 0 then 0.45 * k else 0.28 * k, 0.13 * k), crown * CFrame.new(math.cos(a) * 0.6 * k, 0, math.sin(a) * 0.6 * k), gold, m)
			neon(p)
		end
		local light = Instance.new("PointLight")
		light.Name = "Campeon"
		light.Color = gold
		light.Range = 16
		light.Brightness = 1.6
		light.Shadows = false
		light.Parent = root
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "Campeon"
		sparks.Color = ColorSequence.new(gold)
		sparks.LightEmission = 0.8
		sparks.Size = NumberSequence.new(0.35 * k, 0)
		sparks.Lifetime = NumberRange.new(0.6, 1.2)
		sparks.Rate = 10
		sparks.Speed = NumberRange.new(1, 3)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Parent = root
		-- y un borde dorado en el cuerpo
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") and (p.Name == "Tronco" or p.Name == "Abdomen" or p.Name == "Cabeza") then
				p.Color = p.Color:Lerp(gold, 0.3)
			end
		end
	end
end

function BeastKit.beast(sp: { [string]: any }, id: string, opts: { [string]: any }?): Model
	local champion = opts ~= nil and opts.Champion == true
	local k = sp.Size / 5 * (if champion then 1.25 else 1)
	local C = sp.Colors
	local body, belly, glow = C.Body, C.Belly, C.Glow
	local m = mat(sp.Material)
	local model = Instance.new("Model")
	model.Name = "Bestia_" .. id
	-- (llega entera al jugador, no a trozos: así su placa —Controllers/BeastPlates— sale siempre)
	pcall(function()
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local shape = sp.Body
	-- la raíz: la caja del tronco; las patas cuelgan por debajo (HipHeight)
	local rootSize, hip
	if shape == "Serpiente" then
		rootSize, hip = V3(1.6 * k, 1.4 * k, 3 * k), 0.4 * k
	elseif shape == "Insecto" then
		rootSize, hip = V3(2.6 * k, 1.2 * k, 3.2 * k), 1.1 * k
	elseif shape == "Bipedo" then
		rootSize, hip = V3(2 * k, 2.4 * k, 1.6 * k), 2.4 * k
	else
		rootSize, hip = V3(2 * k, 1.8 * k, 4 * k), 2 * k
	end
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.CollisionGroup = "Bestias"
	root.Size = rootSize
	root.Transparency = 1
	root.CanCollide = true
	root.CanTouch = false
	root.Anchored = false
	root.CFrame = CFrame.new(0, hip + rootSize.Y / 2, 0)
	root.Parent = model
	model.PrimaryPart = root
	local Y = -rootSize.Y / 2 -- (la parte de abajo del tronco)

	if shape == "Cuadrupedo" then
		limb(model, root, "Tronco", V3(2 * k, 1.8 * k, 4 * k), CFrame.new(), body, m)
		limb(model, root, "Barriga", V3(1.6 * k, 0.5 * k, 3.4 * k), CFrame.new(0, Y + 0.2 * k, 0), belly, m)
		local head = CFrame.new(0, 0.7 * k, -2.5 * k)
		limb(model, root, "Cabeza", V3(1.5 * k, 1.4 * k, 1.6 * k), head, body, m)
		limb(model, root, "Hocico", V3(0.9 * k, 0.7 * k, 1 * k), head * CFrame.new(0, -0.25 * k, -1.1 * k), belly, m)
		for _, sx in { -1, 1 } do
			eye(model, root, head * CFrame.new(sx * 0.42 * k, 0.25 * k, -0.8 * k), 0.32 * k, glow)
			limb(model, root, "Oreja", V3(0.3 * k, 0.7 * k, 0.4 * k), head * CFrame.new(sx * 0.5 * k, 0.9 * k, 0.2 * k) * CFrame.Angles(0, 0, sx * -0.3), body, m)
			for _, sz in { -1, 1 } do
				limb(model, root, "Pata", V3(0.55 * k, hip + 0.2 * k, 0.6 * k), CFrame.new(sx * 0.7 * k, Y - hip / 2 + 0.1 * k, sz * 1.4 * k), body, m)
			end
		end
		limb(model, root, "Cola", V3(0.4 * k, 0.4 * k, 2 * k), CFrame.new(0, 0.5 * k, 2.6 * k) * CFrame.Angles(math.rad(25), 0, 0), body, m)
		-- lomo con púas que brillan un poco (los jefes, más)
		for i = 0, (if sp.Boss then 5 else 2) do
			local p = limb(model, root, "Pua", V3(0.3 * k, 0.8 * k, 0.4 * k), CFrame.new(0, 1.2 * k, -1.2 * k + i * 0.6 * k) * CFrame.Angles(math.rad(-20), 0, 0), glow, Enum.Material.Neon)
			p.CastShadow = false
		end
	elseif shape == "Insecto" then
		local isScorpion = string.find(id, "Escorpion") ~= nil
		local flying = string.find(id, "Avispa") ~= nil or string.find(id, "Medusa") ~= nil or string.find(id, "Dron") ~= nil
		limb(model, root, "Abdomen", V3(2.4 * k, 1.1 * k, 2 * k), CFrame.new(0, 0.1 * k, 0.8 * k), body, m)
		limb(model, root, "Torax", V3(1.8 * k, 1 * k, 1.4 * k), CFrame.new(0, 0, -0.9 * k), belly, m)
		local head = CFrame.new(0, 0.1 * k, -1.9 * k)
		limb(model, root, "Cabeza", V3(1.2 * k, 0.9 * k, 0.9 * k), head, body, m)
		for _, sx in { -1, 1 } do
			eye(model, root, head * CFrame.new(sx * 0.35 * k, 0.2 * k, -0.45 * k), 0.3 * k, glow)
			limb(model, root, "Pinza", V3(0.3 * k, 0.3 * k, 1.1 * k), head * CFrame.new(sx * 0.4 * k, -0.2 * k, -0.8 * k) * CFrame.Angles(0, sx * 0.4, 0), belly, m)
			if flying then
				local wing = limb(model, root, "Ala", V3(2.6 * k, 0.1 * k, 1.2 * k), CFrame.new(sx * 1.5 * k, 0.7 * k, -0.4 * k) * CFrame.Angles(0, 0, sx * 0.25), glow, Enum.Material.Glass)
				wing.Transparency = 0.45
			else
				for i = -1, 1 do
					limb(model, root, "Pata", V3(2 * k, 0.25 * k, 0.25 * k), CFrame.new(sx * 1.4 * k, Y - 0.3 * k, i * 0.8 * k) * CFrame.Angles(0, 0, sx * -0.55), body, m)
				end
			end
		end
		if isScorpion then
			for i = 1, 4 do
				limb(model, root, "Cola", V3(0.6 * k, 0.6 * k, 0.9 * k), CFrame.new(0, 0.4 * k + i * 0.55 * k, 1.8 * k + i * 0.35 * k - (if i >= 3 then (i - 2) * 0.6 * k else 0)) * CFrame.Angles(math.rad(-30 * i), 0, 0), body, m)
			end
			local sting = limb(model, root, "Aguijon", V3(0.4 * k, 0.4 * k, 0.8 * k), CFrame.new(0, 2.9 * k, 2.1 * k) * CFrame.Angles(math.rad(-150), 0, 0), glow, Enum.Material.Neon)
			sting.CastShadow = false
		end
	elseif shape == "Serpiente" then
		local seg = 5
		for i = 0, seg - 1 do
			local s = (1 - i / (seg + 1)) * 1.5 * k
			limb(model, root, "Cuerpo", V3(s, s * 0.85, 1.8 * k), CFrame.new(math.sin(i * 1.1) * 0.6 * k, -0.1 * k, i * 1.6 * k - 0.5 * k), if i % 2 == 0 then body else belly, m)
		end
		local head = CFrame.new(0, 0.2 * k, -1.8 * k)
		limb(model, root, "Cabeza", V3(1.4 * k, 1 * k, 1.8 * k), head, body, m)
		for _, sx in { -1, 1 } do
			eye(model, root, head * CFrame.new(sx * 0.45 * k, 0.3 * k, -0.6 * k), 0.3 * k, glow)
		end
		local crest = limb(model, root, "Cresta", V3(0.2 * k, 0.8 * k, 1.6 * k), head * CFrame.new(0, 0.7 * k, 0.3 * k), glow, Enum.Material.Neon)
		crest.CastShadow = false
	else -- Bipedo
		local mech = string.find(id, "Recaudador") ~= nil or sp.Arms == true -- (de pie, con brazos y visor)
		limb(model, root, "Tronco", V3(2 * k, 2.4 * k, 1.6 * k), CFrame.new(), body, m)
		local head = CFrame.new(0, 1.8 * k, -0.3 * k)
		limb(model, root, "Cabeza", V3(1.2 * k, 1.1 * k, 1.2 * k), head, if mech then belly else body, m)
		if mech then
			local visor = limb(model, root, "Visor", V3(1 * k, 0.25 * k, 0.1 * k), head * CFrame.new(0, 0.1 * k, -0.62 * k), glow, Enum.Material.Neon)
			visor.CastShadow = false
		else
			limb(model, root, "Pico", V3(0.4 * k, 0.4 * k, 1 * k), head * CFrame.new(0, -0.1 * k, -0.9 * k), belly, m)
			for _, sx in { -1, 1 } do
				eye(model, root, head * CFrame.new(sx * 0.35 * k, 0.2 * k, -0.6 * k), 0.25 * k, glow)
			end
		end
		for _, sx in { -1, 1 } do
			limb(model, root, "Pierna", V3(0.6 * k, hip + 0.3 * k, 0.7 * k), CFrame.new(sx * 0.6 * k, Y - hip / 2 + 0.15 * k, 0), belly, m)
			if mech then
				limb(model, root, "Brazo", V3(0.8 * k, 2.4 * k, 0.8 * k), CFrame.new(sx * 1.5 * k, -0.3 * k, -0.2 * k), body, m)
				local claw = limb(model, root, "Garra", V3(0.9 * k, 0.6 * k, 1 * k), CFrame.new(sx * 1.5 * k, -1.7 * k, -0.4 * k), glow, Enum.Material.Neon)
				claw.CastShadow = false
			else
				limb(model, root, "Ala", V3(2.6 * k, 0.2 * k, 1.6 * k), CFrame.new(sx * 1.9 * k, 0.6 * k, 0.2 * k) * CFrame.Angles(0, 0, sx * -0.35), body, m)
			end
		end
	end
	details(model, root, sp, id, k, champion)
	if sp.Boss then
		-- (los jefes: un aura que se ve de lejos)
		local aura = Instance.new("PointLight")
		aura.Color = glow
		aura.Range = 30
		aura.Brightness = 2
		aura.Shadows = false
		aura.Parent = root
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = hip
	humanoid.WalkSpeed = sp.Speed
	humanoid.MaxHealth = 1e6
	humanoid.Health = 1e6
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model
	-- (no se sientan en asientos ni se suben a cosas)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	return model
end

---------------------------------------------------------------------
-- Guaridas
---------------------------------------------------------------------
local LOOK = {
	Roca = { Main = rgb(70, 62, 58), Second = rgb(46, 42, 40), Mat = Enum.Material.Basalt, Glow = rgb(255, 120, 50) },
	Arenisca = { Main = rgb(196, 140, 90), Second = rgb(156, 96, 62), Mat = Enum.Material.Sandstone, Glow = rgb(255, 170, 80) },
	Hielo = { Main = rgb(170, 210, 236), Second = rgb(120, 160, 200), Mat = Enum.Material.Ice, Glow = rgb(140, 220, 255) },
	Coral = { Main = rgb(230, 120, 150), Second = rgb(90, 170, 180), Mat = Enum.Material.Pebble, Glow = rgb(90, 255, 220) },
	Raices = { Main = rgb(86, 64, 44), Second = rgb(50, 80, 46), Mat = Enum.Material.Wood, Glow = rgb(170, 255, 120) },
	Chatarra = { Main = rgb(96, 88, 80), Second = rgb(60, 58, 56), Mat = Enum.Material.CorrodedMetal, Glow = rgb(200, 255, 110) },
}

local function sign(parent: Instance, at: Vector3, text: string, color: Color3, distance: number)
	local anchor = Builder.part({ Name = "Rotulo", Size = V3(1, 1, 1), CFrame = CFrame.new(at), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = parent })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(240, 40)
	gui.MaxDistance = distance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
	label.TextScaled = true
	label.Text = text
	label.Parent = gui
end

function BeastKit.lair(parent: Instance, lair: { [string]: any }, cf: CFrame): Model
	local L = LOOK[lair.Look] or LOOK.Roca
	local m = Builder.model("Guarida_" .. lair.Id, parent)
	m:SetAttribute("Lair", lair.Id)
	local boss = lair.Boss == true
	local R = if boss then 34 else 16
	local r = Random.new(#lair.Id * 97 + math.floor(lair.X))
	-- un anillo de rocas (o témpanos, corales, raíces, chatarra) alrededor de una boca oscura
	local n = if boss then 10 else 6
	for i = 1, n do
		local a = i / n * math.pi * 2 + r:NextNumber(-0.2, 0.2)
		local h = r:NextNumber(6, 14) * (if boss then 1.8 else 1)
		local w = r:NextNumber(4, 8) * (if boss then 1.5 else 1)
		local p = cf * CFrame.new(math.cos(a) * R, h / 2 - 1.5, math.sin(a) * R) * CFrame.Angles(r:NextNumber(-0.25, 0.25), r:NextNumber(0, 6.28), r:NextNumber(-0.25, 0.25))
		local look = lair.Look
		if look == "Hielo" or look == "Coral" then
			local spike = Builder.part({ Name = "Pico", Size = V3(w, h * 1.4, w * 0.8), CFrame = p, Color = if i % 2 == 0 then L.Main else L.Second, Material = L.Mat, Parent = m })
			if look == "Coral" then
				spike.Shape = Enum.PartType.Cylinder
				spike.Size = V3(h * 1.2, w * 0.7, w * 0.7)
				spike.CFrame = p * CFrame.Angles(0, 0, math.pi / 2)
			end
		elseif look == "Raices" then
			Builder.part({ Name = "Raiz", Size = V3(w * 0.5, w * 0.5, h * 1.6), CFrame = p * CFrame.Angles(math.rad(50), 0, 0), Color = L.Main, Material = L.Mat, Parent = m })
		else
			Builder.part({ Name = "Roca", Size = V3(w, h, w * 0.9), CFrame = p, Color = if i % 2 == 0 then L.Main else L.Second, Material = L.Mat, Parent = m })
		end
	end
	-- la boca de la guarida (un arco de roca con oscuridad dentro)
	local back = cf * CFrame.new(0, 0, R * 0.55)
	Builder.part({ Name = "Arco", Size = V3(R * 0.9, 3, 6), CFrame = back * CFrame.new(0, R * 0.55, 0), Color = L.Second, Material = L.Mat, Parent = m })
	for _, sx in { -1, 1 } do
		Builder.part({ Name = "Jamba", Size = V3(4, R * 0.6, 6), CFrame = back * CFrame.new(sx * R * 0.4, R * 0.3 - 1, 0), Color = L.Main, Material = L.Mat, Parent = m })
	end
	Builder.decor({ Name = "Oscuridad", Size = V3(R * 0.7, R * 0.55, 0.6), CFrame = back * CFrame.new(0, R * 0.27 - 1, 2), Color = rgb(6, 6, 8), Material = Enum.Material.SmoothPlastic, Parent = m })
	-- huesos y restos por el suelo (de bestias, no de personas)
	for i = 1, (if boss then 8 else 4) do
		local a = r:NextNumber(0, 6.28)
		local d = r:NextNumber(3, R * 0.8)
		Builder.decor({ Name = "Hueso", Size = V3(0.6, 0.6, r:NextNumber(2, 4)), CFrame = cf * CFrame.new(math.cos(a) * d, 0.3, math.sin(a) * d) * CFrame.Angles(0, r:NextNumber(0, 6.28), 0), Color = rgb(222, 214, 196), Material = Enum.Material.SmoothPlastic, Parent = m })
	end
	-- ojos que brillan en la oscuridad (para que se encuentre de noche)
	for _, sx in { -1, 1 } do
		local e = Builder.decor({ Name = "Brillo", Size = V3(0.6, 0.6, 0.6), Shape = Enum.PartType.Ball, CFrame = back * CFrame.new(sx * 1.4, R * 0.25, 1.6), Color = L.Glow, Material = Enum.Material.Neon, Parent = m })
		local l = Instance.new("PointLight")
		l.Color = L.Glow
		l.Range = 10
		l.Brightness = 0.8
		l.Shadows = false
		l.Parent = e
	end
	-- (las bestias atraviesan las rocas de su guarida —grupo «Guarida», Services/BeastService—; tú no)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Guarida"
		end
	end
	if boss then
		-- la del jefe: braseros y un aviso que solo se ve de cerca
		for i = 1, 4 do
			local a = i / 4 * math.pi * 2 + 0.4
			local p = cf * CFrame.new(math.cos(a) * R * 0.7, 0, math.sin(a) * R * 0.7)
			Builder.part({ Name = "Brasero", Size = V3(3, 5, 3), CFrame = p * CFrame.new(0, 2.5, 0), Color = L.Second, Material = L.Mat, Parent = m })
			local fire = Builder.decor({ Name = "Fuego", Size = V3(2.4, 1.4, 2.4), CFrame = p * CFrame.new(0, 5.6, 0), Color = L.Glow, Material = Enum.Material.Neon, Parent = m })
			local l = Instance.new("PointLight")
			l.Color = L.Glow
			l.Range = 26
			l.Brightness = 1.6
			l.Shadows = false
			l.Parent = fire
		end
		sign(m, (cf * CFrame.new(0, R * 0.9, R * 0.55)).Position, "⚠ " .. lair.Name, rgb(255, 120, 90), 90)
	else
		sign(m, (cf * CFrame.new(0, R * 0.75, R * 0.55)).Position, lair.Name, rgb(240, 230, 210), 55)
	end
	return m
end

-- Un arrecife de roca que sale del agua (guaridas y alijos de los planetas casi sin tierra: Tálasa)
function BeastKit.islet(parent: Instance, cf: CFrame, radius: number, bottom: number)
	local top = cf.Position.Y
	local h = math.max(6, top - bottom)
	local m = Builder.model("Arrecife", parent)
	Builder.part({ Name = "Roca", Shape = Enum.PartType.Cylinder, Size = V3(h, radius * 2, radius * 2), CFrame = CFrame.new(cf.Position - Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(96, 104, 100), Material = Enum.Material.Rock, Parent = m })
	Builder.part({ Name = "Arena", Shape = Enum.PartType.Cylinder, Size = V3(0.6, radius * 2 - 4, radius * 2 - 4), CFrame = CFrame.new(cf.Position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(214, 202, 170), Material = Enum.Material.Sand, Parent = m })
	local r = Random.new(math.floor(cf.Position.X + cf.Position.Z))
	for i = 1, math.max(3, math.floor(radius / 6)) do
		local a = r:NextNumber(0, 6.28)
		local d = r:NextNumber(radius * 0.7, radius * 0.95)
		Builder.part({ Name = "Pena", Size = V3(r:NextNumber(3, 7), r:NextNumber(3, 8), r:NextNumber(3, 7)), CFrame = CFrame.new(cf.Position + Vector3.new(math.cos(a) * d, 1, math.sin(a) * d)) * CFrame.Angles(r:NextNumber(-0.3, 0.3), r:NextNumber(0, 6.28), r:NextNumber(-0.3, 0.3)), Color = rgb(80, 88, 86), Material = Enum.Material.Rock, Parent = m })
	end
	return m
end

---------------------------------------------------------------------
-- Alijos y Talleres
---------------------------------------------------------------------
function BeastKit.cache(parent: Instance, cache: { [string]: any }, cf: CFrame): Model
	local m = Builder.model("Alijo_" .. cache.Id, parent)
	local box = Builder.part({ Name = "Cofre", Size = V3(3.4, 2, 2.2), CFrame = cf * CFrame.new(0, 1, 0), Color = rgb(96, 70, 44), Material = Enum.Material.WoodPlanks, Parent = m })
	Builder.part({ Name = "Tapa", Size = V3(3.6, 0.6, 2.4), CFrame = cf * CFrame.new(0, 2.3, 0), Color = rgb(70, 50, 32), Material = Enum.Material.WoodPlanks, Parent = m })
	for _, sx in { -1, 1 } do
		Builder.decor({ Name = "Herraje", Size = V3(0.3, 2.2, 2.4), CFrame = cf * CFrame.new(sx * 1.2, 1.2, 0), Color = rgb(150, 130, 70), Material = Enum.Material.Metal, Parent = m })
	end
	local glow = Builder.decor({ Name = "Brillo", Size = V3(0.6, 0.4, 0.2), CFrame = cf * CFrame.new(0, 1.6, -1.15), Color = rgb(255, 210, 110), Material = Enum.Material.Neon, Parent = m })
	local l = Instance.new("PointLight")
	l.Color = rgb(255, 210, 110)
	l.Range = 9
	l.Brightness = 0.7
	l.Shadows = false
	l.Parent = glow
	local prompt = Builder.prompt(box, "Abrir alijo", "Alijo escondido", 1.2)
	prompt:AddTag("Alijo")
	prompt:SetAttribute("Cache", cache.Id)
	prompt.MaxActivationDistance = 9
	return m
end

function BeastKit.bench(parent: Instance, cf: CFrame, colors: { [string]: Color3 }?): Model
	local c = colors or {}
	local m = Builder.model("Taller", parent)
	local wood = c.Trim or rgb(110, 80, 52)
	local metal = c.Metal or rgb(70, 70, 76)
	local table_ = Builder.part({ Name = "Mesa", Size = V3(6, 0.6, 3), CFrame = cf * CFrame.new(0, 3.2, 0), Color = wood, Material = Enum.Material.WoodPlanks, Parent = m })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			Builder.part({ Name = "Pata", Size = V3(0.5, 3, 0.5), CFrame = cf * CFrame.new(sx * 2.6, 1.5, sz * 1.2), Color = wood, Material = Enum.Material.Wood, Parent = m })
		end
	end
	Builder.decor({ Name = "Herramientas", Size = V3(2, 0.3, 0.8), CFrame = cf * CFrame.new(-1.2, 3.65, 0.4), Color = metal, Material = Enum.Material.Metal, Parent = m })
	-- el yunque y el caldero
	Builder.part({ Name = "Yunque", Size = V3(2.6, 1.4, 1.4), CFrame = cf * CFrame.new(4.6, 2.2, 0), Color = metal, Material = Enum.Material.Metal, Parent = m })
	Builder.part({ Name = "PieYunque", Size = V3(1.2, 1.6, 1.2), CFrame = cf * CFrame.new(4.6, 0.8, 0), Color = rgb(60, 50, 44), Material = Enum.Material.Wood, Parent = m })
	Builder.part({ Name = "Caldero", Shape = Enum.PartType.Cylinder, Size = V3(2.4, 3, 3), CFrame = cf * CFrame.new(-4.6, 1.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = rgb(40, 40, 44), Material = Enum.Material.Metal, Parent = m })
	local brew = Builder.decor({ Name = "Pocion", Shape = Enum.PartType.Cylinder, Size = V3(0.3, 2.6, 2.6), CFrame = cf * CFrame.new(-4.6, 2.45, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = c.Glow or rgb(120, 255, 160), Material = Enum.Material.Neon, Parent = m })
	local l = Instance.new("PointLight")
	l.Color = brew.Color
	l.Range = 10
	l.Brightness = 0.8
	l.Shadows = false
	l.Parent = brew
	local board = Builder.part({ Name = "Cartel", Size = V3(6, 1.6, 0.3), CFrame = cf * CFrame.new(0, 6.2, 1.4), Color = rgb(30, 28, 26), Material = Enum.Material.Wood, Parent = m })
	Builder.sign(board, "🛠 TALLER · FABRICAR", Enum.NormalId.Front, rgb(255, 220, 150), rgb(30, 28, 26))
	Builder.sign(board, "🛠 TALLER · FABRICAR", Enum.NormalId.Back, rgb(255, 220, 150), rgb(30, 28, 26))
	local prompt = Builder.prompt(table_, "Fabricar", "Taller (Mesa, Forja y Alquimia)", 0)
	prompt:AddTag("Taller")
	prompt.MaxActivationDistance = 12
	return m
end

-- Una ESQUIRLA DE LA GRIETA (shared/Cosmos/Bestiary.Shard): un cristal violeta enorme clavado en el suelo, con
-- trozos que flotan alrededor y luz. Lleva un Humanoid (para que los golpes y la puntería la encuentren), pero
-- no se mueve: su raíz está anclada. cf: el suelo, en el centro.
function BeastKit.shard(cf: CFrame, tier: number?): Model
	local t = math.clamp(tier or 1, 1, 4)
	local k = 0.85 + t * 0.15
	local m = Instance.new("Model")
	m.Name = "Esquirla"
	local glow = Color3.fromRGB(190, 140, 255)
	local deep = Color3.fromRGB(110, 60, 220)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = V3(7, 16, 7) * k
	root.CFrame = cf * CFrame.new(0, 8 * k, 0) * CFrame.Angles(0.12, 0.4, -0.08)
	root.Color = deep
	root.Material = Enum.Material.Glass
	root.Transparency = 0.15
	root.Anchored = true
	root.CanCollide = true
	root.Parent = m
	local core = Builder.decor({ Name = "Nucleo", Size = V3(3.2, 12, 3.2) * k, CFrame = root.CFrame, Color = glow, Material = Enum.Material.Neon, Parent = m })
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 34
	light.Brightness = 2.2
	light.Shadows = false
	light.Parent = core
	local r = Random.new(math.floor(cf.Position.X * 7 + cf.Position.Z))
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		local h = r:NextNumber(5, 9) * k
		Builder.decor({ Name = "Punta", Size = V3(2.2, h, 2.2) * 1, CFrame = cf * CFrame.new(math.cos(a) * 4.5 * k, h / 2 - 0.5, math.sin(a) * 4.5 * k) * CFrame.Angles(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5), Color = if i % 2 == 0 then deep else glow, Material = if i % 2 == 0 then Enum.Material.Glass else Enum.Material.Neon, Parent = m })
	end
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + 0.3
		Builder.decor({ Name = "Roca", Size = V3(1.6, 1.6, 1.6) * r:NextNumber(0.7, 1.4), CFrame = cf * CFrame.new(math.cos(a) * 8 * k, r:NextNumber(6, 14) * k, math.sin(a) * 8 * k) * CFrame.Angles(r:NextNumber(0, 6), r:NextNumber(0, 6), 0), Color = Color3.fromRGB(40, 32, 56), Material = Enum.Material.Basalt, Parent = m })
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Chispas"
	pe.Color = ColorSequence.new(glow)
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Rate = 8
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = core
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.MaxHealth = 1e6
	humanoid.Health = 1e6
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = m
	m.PrimaryPart = root
	return m
end

-- El CARTEL de una zona de caza, junto al sendero: poste, tabla con el nombre y el nivel, y una luz del color
-- de la zona (verde, amarillo, naranja, rojo)
BeastKit.ZoneColors = { Color3.fromRGB(110, 220, 120), Color3.fromRGB(240, 210, 80), Color3.fromRGB(255, 140, 60), Color3.fromRGB(240, 70, 70) }
function BeastKit.zoneSign(parent: Instance, cf: CFrame, text: string, tier: number): Model
	local m = Builder.model("CartelZona", parent)
	local color = BeastKit.ZoneColors[math.clamp(tier, 1, 4)]
	Builder.part({ Name = "Poste", Size = V3(0.8, 9, 0.8), CFrame = cf * CFrame.new(0, 4.5, 0), Color = Color3.fromRGB(70, 56, 44), Material = Enum.Material.Wood, Parent = m })
	local board = Builder.part({ Name = "Tabla", Size = V3(9, 3.2, 0.4), CFrame = cf * CFrame.new(0, 7.4, 0), Color = Color3.fromRGB(40, 34, 30), Material = Enum.Material.Wood, Parent = m })
	Builder.sign(board, text, Enum.NormalId.Front, color)
	Builder.sign(board, text, Enum.NormalId.Back, color)
	local lamp = Builder.decor({ Name = "Luz", Size = V3(9.2, 0.4, 0.5), CFrame = cf * CFrame.new(0, 9.2, 0), Color = color, Material = Enum.Material.Neon, Parent = m })
	local pl = Instance.new("PointLight")
	pl.Color = color
	pl.Range = 16
	pl.Brightness = 1.2
	pl.Shadows = false
	pl.Parent = lamp
	return m
end

-- RUINAS de antes de la Grieta: muros rotos, columnas caídas y una losa con una marca que brilla un poco
function BeastKit.ruin(parent: Instance, cf: CFrame, look: string?, seed: number): Model
	local L = LOOK[look or "Roca"] or LOOK.Roca
	local m = Builder.model("Ruina", parent)
	local r = Random.new(seed)
	Builder.part({ Name = "Losa", Size = V3(22, 1, 18), CFrame = cf * CFrame.new(0, 0, 0) * CFrame.Angles(r:NextNumber(-0.05, 0.05), 0, r:NextNumber(-0.05, 0.05)), Color = L.Second, Material = L.Mat, Parent = m })
	for i = 1, 3 do
		local h = r:NextNumber(4, 11)
		Builder.part({ Name = "Muro", Size = V3(r:NextNumber(5, 9), h, 1.6), CFrame = cf * CFrame.new(r:NextNumber(-8, 8), h / 2, (i - 2) * 6) * CFrame.Angles(0, r:NextNumber(-0.4, 0.4), r:NextNumber(-0.12, 0.12)), Color = L.Main, Material = L.Mat, Parent = m })
	end
	for i = 1, 2 do
		local h = r:NextNumber(6, 12)
		local fallen = i == 2
		local cfc = if fallen then cf * CFrame.new(r:NextNumber(-6, 6), 1.4, r:NextNumber(-6, 6)) * CFrame.Angles(0, r:NextNumber(0, 6), math.pi / 2) else cf * CFrame.new(r:NextNumber(-8, 8), h / 2, r:NextNumber(-7, 7))
		local col = Builder.part({ Name = "Columna", Shape = Enum.PartType.Cylinder, Size = V3(h, 2.4, 2.4), CFrame = cfc * (if fallen then CFrame.new() else CFrame.Angles(0, 0, math.pi / 2)), Color = L.Main, Material = L.Mat, Parent = m })
		col.Shape = Enum.PartType.Cylinder
	end
	local mark = Builder.decor({ Name = "Marca", Size = V3(4, 0.2, 4), CFrame = cf * CFrame.new(0, 0.6, 0), Color = Color3.fromRGB(170, 120, 255), Material = Enum.Material.Neon, Transparency = 0.3, Parent = m })
	local pl = Instance.new("PointLight")
	pl.Color = mark.Color
	pl.Range = 12
	pl.Brightness = 0.8
	pl.Shadows = false
	pl.Parent = mark
	return m
end

return BeastKit
