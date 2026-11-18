-- AncientTree: el ÁRBOL ANCESTRAL, un árbol gigante de fantasía (17-11-2026, el dueño: «haz un árbol bonito y
-- ejemplar… gigante, de fantasía, con texturas»; su dibujo: docs/mapa/region-bosque-b.png). Se hace por código y
-- cada vez igual (semilla):
--
--   * Tronco enorme que se estrecha hacia arriba con curvas suaves, nervios de corteza retorcidos alrededor y la
--     textura de madera con veta (MaterialVariant «MaderaVeta» de World/Kit/MaterialLook; si no está, Wood).
--   * Raíces gruesas que salen del pie, se arquean y se hunden en el suelo, con musgo.
--   * Ramas que se abren en ramas más finas (tres niveles) y, en cada punta, masas de hojas (LeafyGrass) en varios
--     verdes; una copa enorme y redonda.
--   * Lo de fantasía: lianas de luz azul colgando, frutos que brillan, cristales en las raíces, un corazón de luz en
--     el tronco y luciérnagas en la copa.
-- AncientTree.build(parent, base, seed, scale) -> Model (base: CFrame en el suelo; scale 1 = unos 190 studs de alto)

local Builder = require(script.Parent.Parent.Builder)

local AncientTree = {}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local BARK = { rgb(150, 112, 80), rgb(136, 100, 72), rgb(164, 124, 88) }
local LEAVES = { rgb(58, 140, 74), rgb(76, 162, 84), rgb(48, 122, 70), rgb(92, 176, 96), rgb(62, 150, 110) }
local GLOW = rgb(110, 210, 255)

local function rng(seed: number): () -> number
	local s = math.max(1, math.floor(seed) % 2147483646)
	return function(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local barkVariant: string? = nil
local function bark(p: BasePart)
	if barkVariant == nil then
		local ms = game:GetService("MaterialService")
		barkVariant = if ms:FindFirstChild("MaderaVeta") then "MaderaVeta" else ""
	end
	if barkVariant ~= "" then
		pcall(function()
			p.MaterialVariant = barkVariant :: string
		end)
	end
end

-- Un trozo de madera de a a b (cilindro) con una bola en la unión para que no se vean cortes
local function limb(m: Instance, a: Vector3, b: Vector3, r: number, color: Color3, joint: boolean?)
	local d = b - a
	local len = d.Magnitude
	if len < 0.1 then
		return
	end
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	local p = Builder.part({ Name = "Madera", Shape = Enum.PartType.Cylinder, Size = V3(len + r * 0.4, r * 2, r * 2), CFrame = cf, Color = color, Material = M.Wood, Parent = m })
	bark(p)
	if joint ~= false then
		local j = Builder.part({ Name = "Nudo", Shape = Enum.PartType.Ball, Size = V3(r * 2.05, r * 2.05, r * 2.05), CFrame = CF(b), Color = color, Material = M.Wood, Parent = m })
		bark(j)
	end
end

local function glowPart(m: Instance, props: { [string]: any }): BasePart
	props.Material = M.Neon
	props.CanCollide = false
	props.CastShadow = false
	props.Parent = m
	return Builder.part(props)
end

---------------------------------------------------------------------
-- (18-11-2026) EL ÁRBOL DE MALLAS: modelado en Blender (scripts/arbol/arbol_blender.py), con sus texturas
-- (scripts/arbol/texturas.py) y subido con scripts/upload-arbol.sh (shared/ArbolAssetIds). Tronco con cuatro troncos
-- entrelazados, raíces que serpentean por el suelo, ramas, cuatro masas de copa y las vetas de energía. Si las
-- mallas no están (o no cargan), se hace el de piezas de abajo.
---------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function meshPart(id: string): MeshPart?
	local n = tonumber(string.match(id, "%d+"))
	if not n then
		return nil
	end
	local ok, inst = pcall(function()
		return (require(script.Parent.Parent.AssetLoader) :: any).download(n)
	end)
	if not ok or not inst then
		return nil
	end
	local mp = if inst:IsA("MeshPart") then inst else inst:FindFirstChildWhichIsA("MeshPart", true)
	return if mp then mp:Clone() else nil
end

function AncientTree.buildMesh(parent: Instance, base: CFrame, scale: number?): Model?
	local okI, ids = pcall(function()
		return require(ReplicatedStorage.Shared.ArbolAssetIds) :: any
	end)
	local okM, plan = pcall(function()
		return require(ReplicatedStorage.Shared.ArbolMalla) :: any
	end)
	if not okI or not okM or type(ids.Piezas) ~= "table" or next(ids.Piezas) == nil then
		return nil
	end
	local Images = require(ReplicatedStorage.Shared.Images) :: any
	local k = scale or 1
	local m = Builder.model("ArbolAncestral", parent)
	local got = 0
	for _, piece in plan.Pieces do
		local id = ids.Piezas[piece.Name]
		local mp = if type(id) == "string" then meshPart(id) else nil
		if mp then
			mp.Name = piece.Name
			mp.Anchored = true
			mp.Size = piece.Size * k
			-- (Roblox importa el FBX girado media vuelta: se endereza para que cada pieza caiga en su sitio)
			mp.CFrame = base * CF(piece.Center * k) * CFrame.Angles(0, math.pi, 0)
			pcall(function()
				(mp :: any).RenderFidelity = Enum.RenderFidelity.Automatic
			end)
			if piece.Material == "Neon" then
				mp.Material = M.Neon
				mp.Color = rgb(70, 205, 255)
				mp.Transparency = 0.08
				mp.CanCollide = false
				mp.CastShadow = false
			else
				mp.Material = if piece.Material == "Grass" then M.LeafyGrass else M.Wood
				mp.Color = if piece.Set == "hojas" then rgb(255, 255, 255) else rgb(255, 255, 255)
				mp.CanCollide = piece.Set ~= "hojas"
				local tex = piece.Set and ids.Texturas and ids.Texturas[piece.Set .. "_color"]
				if tex then
					local color = Images.of(tex)
					local okSA = pcall(function()
						local sa = Instance.new("SurfaceAppearance")
						sa.ColorMap = color
						local nrm = ids.Texturas[piece.Set .. "_normal"]
						if nrm then
							sa.NormalMap = Images.of(nrm)
						end
						sa.Parent = mp
					end)
					if not okSA then
						for _, d in mp:GetChildren() do
							if d:IsA("SurfaceAppearance") then
								d:Destroy()
							end
						end
						pcall(function()
							mp.TextureID = color
						end)
					end
				end
			end
			mp.Parent = m
			got += 1
		end
	end
	if got < 3 then
		m:Destroy()
		return nil
	end
	-- lo mágico de alrededor: el núcleo de luz en el tronco, cristales entre las raíces, luz y luciérnagas
	local function at(x: number, y: number, z: number): Vector3
		return (base * CF(x * k, y * k, z * k)).Position
	end
	local core = glowPart(m, { Name = "Nucleo", Shape = Enum.PartType.Ball, Size = V3(9, 9, 9) * k, CFrame = CF(at(0, 26, -30)), Color = GLOW, Transparency = 0.15 })
	core:SetAttribute("NucleoArbol", true)
	local cl = Instance.new("PointLight")
	cl.Color = GLOW
	cl.Range = 60
	cl.Brightness = 3
	cl.Shadows = false
	cl.Parent = core
	local r = rng(99)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + 0.2
		local c = glowPart(m, { Name = "Cristal", Size = V3(3, 9 + r() * 7, 3) * k, CFrame = CF(at(math.cos(a) * 62, 4, math.sin(a) * 62)) * CFrame.Angles(math.rad(10), a, math.rad(8)), Color = GLOW })
		if i % 3 == 0 then
			local l = Instance.new("PointLight")
			l.Color = GLOW
			l.Range = 26
			l.Brightness = 1.6
			l.Shadows = false
			l.Parent = c
		end
	end
	-- resplandor azul que sale del tronco y de las ramas maestras (como en la imagen del dueño)
	for i, y in { 20, 55, 90, 125 } do
		local a = i * 1.9
		local g = Builder.part({ Name = "LuzTronco", Size = V3(2, 2, 2), CFrame = CF(at(math.cos(a) * 40, y, math.sin(a) * 40)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = m })
		local l = Instance.new("PointLight")
		l.Color = GLOW
		l.Range = 55
		l.Brightness = 2.2
		l.Shadows = false
		l.Parent = g
	end
	local cloud = Builder.part({ Name = "Copa", Size = V3(340, 110, 340) * k, CFrame = CF(at(0, 255, 0)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = m })
	local fe = Instance.new("ParticleEmitter")
	fe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	fe.Color = ColorSequence.new(rgb(200, 255, 180), GLOW)
	fe.LightEmission = 1
	fe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1.8), NumberSequenceKeypoint.new(1, 0) })
	fe.Lifetime = NumberRange.new(3, 6)
	fe.Speed = NumberRange.new(0.5, 2)
	fe.SpreadAngle = Vector2.new(180, 180)
	fe.Rate = 22
	fe.Parent = cloud
	local motes = Builder.part({ Name = "Motas", Size = V3(150, 40, 150) * k, CFrame = CF(at(0, 30, 0)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = m })
	local me = fe:Clone()
	me.Rate = 14
	me.Color = ColorSequence.new(GLOW)
	me.Parent = motes
	-- (las vetas laten despacio: el cliente las anima con el atributo Latido)
	local venas = m:FindFirstChild("Venas")
	if venas then
		venas:SetAttribute("Latido", true)
	end
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	return m
end

function AncientTree.build(parent: Instance, base: CFrame, seed: number?, scale: number?): Model
	-- (el de mallas, si está; si no, el de piezas)
	local okMesh, meshTree = pcall(AncientTree.buildMesh, parent, base, scale)
	if okMesh and meshTree then
		return meshTree
	end
	local k = scale or 1
	local r = rng(seed or 4242)
	local m = Builder.model("ArbolAncestral", parent)
	local up = base.UpVector
	local function at(x: number, y: number, z: number): Vector3
		return (base * CF(x * k, y * k, z * k)).Position
	end
	local wood = BARK[1]

	-- 1) el tronco: 7 tramos que se estrechan y se curvan un poco
	local H = 150
	local nodes = {}
	local sway = r() * math.pi * 2
	for i = 0, 7 do
		local t = i / 7
		local off = math.sin(t * 2.6 + sway) * 6 * t
		table.insert(nodes, { P = at(off, t * H, math.cos(t * 2.1 + sway) * 5 * t), R = (30 - 15 * t) * k })
	end
	for i = 1, #nodes - 1 do
		limb(m, nodes[i].P, nodes[i + 1].P, nodes[i].R, BARK[1 + i % #BARK])
	end
	-- nervios de corteza retorcidos alrededor del tronco
	for rib = 0, 9 do
		local a0 = rib / 10 * math.pi * 2
		local prev: Vector3? = nil
		for i = 1, 6 do
			local t = (i - 1) / 7
			local n = nodes[i]
			local a = a0 + t * 1.4
			local p = n.P + (base - base.Position) * V3(math.cos(a) * n.R * 0.92, 0, math.sin(a) * n.R * 0.92)
			if prev then
				limb(m, prev, p, n.R * 0.22, BARK[2], false)
			end
			prev = p
		end
	end
	-- el corazón de luz en el tronco (como en el dibujo)
	local heart = glowPart(m, { Name = "Corazon", Size = V3(5 * k, 12 * k, 2 * k), CFrame = CFrame.new(at(0, 30, 0)) * (base - base.Position) * CF(0, 0, -24 * k) * CFrame.Angles(0, 0, math.rad(45)), Color = GLOW })
	local hl = Instance.new("PointLight")
	hl.Color = GLOW
	hl.Range = 50
	hl.Brightness = 3
	hl.Shadows = false
	hl.Parent = heart

	-- 2) las raíces: salen del pie, se arquean y se hunden
	for i = 0, 10 do
		local a = i / 11 * math.pi * 2 + r() * 0.3
		local dx, dz = math.cos(a), math.sin(a)
		local len = 75 + r() * 30
		-- (salen del tronco, suben un poco en arco y se hunden en la tierra: cinco tramos cada vez más finos)
		local pts = {
			at(dx * 14, 26, dz * 14),
			at(dx * len * 0.3, 22 + r() * 4, dz * len * 0.3),
			at(dx * len * 0.52, 16, dz * len * 0.52),
			at(dx * len * 0.74, 7, dz * len * 0.74),
			at(dx * len * 0.92, 0, dz * len * 0.92),
			at(dx * len * 1.02, -8, dz * len * 1.02),
		}
		local rads = { 15, 12, 9, 6.5, 4 }
		for q = 1, 5 do
			limb(m, pts[q], pts[q + 1], rads[q] * k, BARK[1 + q % #BARK])
		end
		local p1 = pts[2]
		-- musgo encima
		Builder.decor({ Name = "Musgo", Shape = Enum.PartType.Ball, Size = V3(10 * k, 4 * k, 10 * k), CFrame = CF(p1 + up * 8 * k), Color = rgb(70, 140, 70), Material = M.LeafyGrass, Parent = m })
		-- un cristal de luz entre raíz y raíz
		if i % 2 == 0 then
			local c = glowPart(m, { Name = "Cristal", Size = V3(3 * k, (8 + r() * 6) * k, 3 * k), CFrame = CF(at(math.cos(a + 0.28) * 34, 4, math.sin(a + 0.28) * 34)) * CFrame.Angles(math.rad(10), a, math.rad(8)), Color = GLOW })
			if i % 4 == 0 then
				local l = Instance.new("PointLight")
				l.Color = GLOW
				l.Range = 24
				l.Brightness = 1.6
				l.Shadows = false
				l.Parent = c
			end
		end
	end

	-- 3) las ramas (tres niveles) y las hojas en cada punta
	local tips: { Vector3 } = {}
	local function branch(from: Vector3, dir: Vector3, len: number, rad: number, depth: number)
		local to = from + dir * len
		limb(m, from, to, rad, BARK[1 + depth % #BARK])
		if depth <= 0 then
			table.insert(tips, to)
			return
		end
		local kids = if depth == 3 then 3 else 2 + (if r() > 0.5 then 1 else 0)
		for c = 1, kids do
			local spin = (c / kids) * math.pi * 2 + r()
			local side = (base - base.Position) * V3(math.cos(spin), 0, math.sin(spin))
			local nd = (dir * 0.55 + side * 0.55 + up * (0.35 + r() * 0.25)).Unit
			branch(to, nd, len * (0.62 + r() * 0.1), rad * 0.62, depth - 1)
		end
	end
	for i = 1, 7 do
		local n = nodes[math.clamp(4 + math.floor(i / 2), 4, 7)]
		local a = i / 7 * math.pi * 2 + r() * 0.4
		local side = (base - base.Position) * V3(math.cos(a), 0, math.sin(a))
		local dir = (side * 0.8 + up * (0.45 + r() * 0.2)).Unit
		branch(n.P, dir, (56 + r() * 14) * k, n.R * 0.55, 3)
	end
	table.insert(tips, nodes[#nodes].P + up * 10 * k)
	-- masas de hojas: cada punta, un racimo de bolas de varios verdes
	for i, tip in tips do
		local count = if i == #tips then 3 else 2
		for c = 1, count do
			local s = (16 + r() * 10) * k
			local o = V3((r() - 0.5) * 22, (r() - 0.3) * 12, (r() - 0.5) * 22) * k
			local leaf = Builder.part({ Name = "Hojas", Shape = Enum.PartType.Ball, Size = V3(s, s * 0.78, s), CFrame = CF(tip + o), Color = LEAVES[1 + (i + c) % #LEAVES], Material = M.LeafyGrass, CastShadow = c <= 2, CanCollide = false, Parent = m })
			local _ = leaf
		end
		-- frutos de luz y lianas colgando (en una de cada tres puntas)
		if i % 3 == 0 then
			local fruit = glowPart(m, { Name = "Fruto", Shape = Enum.PartType.Ball, Size = V3(3, 3, 3) * k, CFrame = CF(tip - up * 8 * k), Color = rgb(160, 230, 255) })
			if i % 6 == 0 then
				local l = Instance.new("PointLight")
				l.Color = GLOW
				l.Range = 30
				l.Brightness = 1.5
				l.Shadows = false
				l.Parent = fruit
			end
			local drop = (18 + r() * 26) * k
			glowPart(m, { Name = "Liana", Size = V3(0.6 * k, drop, 0.6 * k), CFrame = CF(tip - up * (drop / 2 + 4 * k)), Color = GLOW, Transparency = 0.15 })
		end
	end
	-- la COPA: una cúpula enorme de follaje (bolas apretadas sobre un elipsoide y por dentro), más clara arriba
	local top = nodes[#nodes].P
	local cc = top + up * 34 * k
	local RX, RY = 128, 46
	for q = 1, 170 do
		local a = r() * math.pi * 2
		-- (solo la mitad de arriba y un poco del borde: por debajo se ven el tronco y las ramas, como en el dibujo)
		local e = math.acos(1 - r() * 1.15)
		local shell = 0.75 + r() * 0.3
		local x = math.sin(e) * math.cos(a) * RX * shell
		local z = math.sin(e) * math.sin(a) * RX * shell
		local y = math.cos(e) * RY * shell - 4
		local s = (26 + r() * 20) * k
		local hgt = math.clamp((y + RY) / (RY * 2), 0, 1)
		local col = LEAVES[1 + q % #LEAVES]:Lerp(rgb(150, 210, 110), hgt * 0.35)
		Builder.part({ Name = "Follaje", Shape = Enum.PartType.Ball, Size = V3(s, s * 0.82, s), CFrame = CF(cc + (base - base.Position) * V3(x * k, y * k, z * k)), Color = col, Material = M.LeafyGrass, CastShadow = q % 3 == 0, CanCollide = false, Parent = m })
	end
	-- flores de luz por fuera de la copa
	for q = 1, 26 do
		local a = r() * math.pi * 2
		local e = math.acos(1 - r() * 1.1)
		local x = math.sin(e) * math.cos(a) * RX * 1.02
		local z = math.sin(e) * math.sin(a) * RX * 1.02
		local y = math.cos(e) * RY * 1.02 - 8
		glowPart(m, { Name = "Flor", Shape = Enum.PartType.Ball, Size = V3(3.4, 3.4, 3.4) * k, CFrame = CF(cc + (base - base.Position) * V3(x * k, y * k, z * k)), Color = if q % 2 == 0 then rgb(170, 230, 255) else rgb(255, 210, 240) })
	end
	-- luciérnagas en la copa
	local cloud = Builder.part({ Name = "Copa", Size = V3(220, 70, 220) * k, CFrame = CF(at(0, H + 40, 0)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = m })
	local fe = Instance.new("ParticleEmitter")
	fe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	fe.Color = ColorSequence.new(rgb(200, 255, 180), GLOW)
	fe.LightEmission = 1
	fe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1.4), NumberSequenceKeypoint.new(1, 0) })
	fe.Lifetime = NumberRange.new(3, 6)
	fe.Speed = NumberRange.new(0.5, 2)
	fe.SpreadAngle = Vector2.new(180, 180)
	fe.Rate = 18
	fe.Parent = cloud
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local _ = wood
	return m
end

return AncientTree
