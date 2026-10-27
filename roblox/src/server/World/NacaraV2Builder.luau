-- NacaraV2Builder (servidor): el PROTOTIPO de Nácara v2 (docs/mar/nacara-v2/diseno.md §6, fase 1): el Palacio
-- Real en su isla, al norte de la plaza, y la Plaza Central (la plaza de la fase 0, que no se toca: solo su borde
-- de luz y el cartel), unidas por un tubo de cristal. Los datos están en shared/Sea/NacaraV2.
--
-- SOLO si Config.Sea.NacaraV2 = true (apagado hasta que el dueño apruebe las vistas previas): lo llama
-- Services/SeaCivService.setup después de NacaraCityBuilder.
--
--   NacaraV2Builder.plan()         la lista de piezas (cuentas puras: la usan las pruebas y la vista previa)
--   NacaraV2Builder.build(terrain) la isla (terreno) y las piezas en workspace.NacaraCiudad.Nacara_V2_Palacio
--
-- Reglas (como NacaraCityBuilder y el bug del barrio negro de la v129): solo SmoothPlastic, Glass, Neon y Fabric
-- (nada que cambie World/UserMaterials), todo anclado, sin sombras, el decorado sin choques ni consultas (solo
-- chocan la terraza, el tambor y el suelo del tubo), NacaraV2.MaxLights luces de verdad y el presupuesto del
-- distrito (NacaraV2.ById.Palacio.Budget + Plaza.Budget). Modelo Atomic (StreamingEnabled).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)
local NacaraV2 = require(ReplicatedStorage.Shared.Sea.NacaraV2)

local NacaraV2Builder = {}

NacaraV2Builder.State = "None"
NacaraV2Builder.Stats = { Parts = 0, Lights = 0, Fills = 0 }
NacaraV2Builder.Materials = { "SmoothPlastic", "Glass", "Neon", "Fabric" }

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rad = math.rad
local cos, sin = math.cos, math.sin

local NACRE = rgb(236, 230, 244)
local NACRE_BLUE = rgb(206, 232, 244)
local PEARL_PINK = rgb(246, 214, 230)
local CYAN = rgb(110, 236, 255)
local GOLD = rgb(255, 214, 140)
local GLASS_TINT = rgb(150, 220, 255)
local CORAL = { rgb(255, 128, 160), rgb(255, 176, 96), rgb(184, 128, 255), rgb(120, 226, 255), rgb(140, 240, 180) }

export type Spec = {
	Name: string,
	Shape: string, -- "Block" | "Cylinder" | "Ball" (Ball con tamaños distintos = elipsoide: SpecialMesh)
	Size: Vector3,
	CFrame: CFrame,
	Color: Color3,
	Material: string,
	Transparency: number?,
	Collide: boolean?,
	Light: { Color: Color3, Range: number, Brightness: number }?,
	Sign: { Title: string, Sub: string? }?,
}

-- Un cilindro de pie (los Cylinder de Roblox van por el eje X)
local function upright(at: Vector3): CFrame
	return CF(at) * ANG(0, 0, rad(90))
end

-- Las piezas del prototipo (sin crear nada)
function NacaraV2Builder.plan(): { Spec }
	local out: { Spec } = {}
	local function add(s: Spec)
		table.insert(out, s)
	end
	local P = NacaraV2.Palace
	local at = NacaraV2.PalaceAt
	local top = Nacara.FloorY + P.Island -- la cara de arriba de la isla
	local c = V(Nacara.Center.X + at.X, top, Nacara.Center.Z + at.Z)
	local tr = P.Terrace.R

	-- La terraza de la isla (se anda), con el borde de luz por debajo
	add({ Name = "Terraza", Shape = "Cylinder", Size = V(1.2, tr * 2, tr * 2), CFrame = upright(c + V(0, 0.6, 0)), Color = NACRE, Material = "SmoothPlastic", Collide = true })
	add({ Name = "BordeTerraza", Shape = "Cylinder", Size = V(0.5, tr * 2 + 1.4, tr * 2 + 1.4), CFrame = upright(c + V(0, 0.25, 0)), Color = CYAN, Material = "Neon" })
	-- El tambor de nácar y sus dos franjas de luz
	local dr, dh = P.Drum.R, P.Drum.H
	local floor = c.Y + 1.2
	add({ Name = "Tambor", Shape = "Cylinder", Size = V(dh, dr * 2, dr * 2), CFrame = upright(V(c.X, floor + dh / 2, c.Z)), Color = NACRE_BLUE, Material = "SmoothPlastic", Collide = true })
	for _, y in { 2.6, dh - 1.2 } do
		add({ Name = "FranjaTambor", Shape = "Cylinder", Size = V(0.6, dr * 2 + 0.6, dr * 2 + 0.6), CFrame = upright(V(c.X, floor + y, c.Z)), Color = CYAN, Material = "Neon" })
	end
	-- Cuatro puertas en arco (norte, este, sur, oeste): marco de luz y hoja de cristal
	for k = 0, 3 do
		local yaw = k * math.pi / 2
		local face = CF(c.X, floor, c.Z) * ANG(0, yaw, 0) * CF(0, 0, -(dr + 0.15))
		add({ Name = "Puerta", Shape = "Block", Size = V(4.6, 7, 0.3), CFrame = face * CF(0, 3.5, 0), Color = rgb(40, 90, 130), Material = "Glass", Transparency = 0.35 })
		for s = -1, 1, 2 do
			add({ Name = "Jamba", Shape = "Block", Size = V(0.5, 7.4, 0.5), CFrame = face * CF(s * 2.55, 3.7, -0.1), Color = GOLD, Material = "Neon" })
		end
		add({ Name = "Dintel", Shape = "Block", Size = V(5.6, 0.5, 0.5), CFrame = face * CF(0, 7.6, -0.1), Color = GOLD, Material = "Neon" })
	end
	-- La cúpula de cristal (media elipse: la mitad de abajo queda dentro del tambor) y su anillo de arriba
	local domeY = floor + dh
	add({ Name = "Cupula", Shape = "Ball", Size = V(P.Dome.R * 2, P.Dome.H * 2, P.Dome.R * 2), CFrame = CF(c.X, domeY, c.Z), Color = GLASS_TINT, Material = "Glass", Transparency = 0.5 })
	add({ Name = "AnilloCupula", Shape = "Cylinder", Size = V(0.8, P.Dome.R * 2 + 1, P.Dome.R * 2 + 1), CFrame = upright(V(c.X, domeY + 0.3, c.Z)), Color = GOLD, Material = "Neon" })
	-- El corazón de luz: columna y perla (una de las dos luces de verdad)
	add({ Name = "ColumnaLuz", Shape = "Cylinder", Size = V(P.Dome.H + dh - 2, 4, 4), CFrame = upright(V(c.X, floor + (P.Dome.H + dh - 2) / 2, c.Z)), Color = CYAN, Material = "Neon", Transparency = 0.15 })
	add({ Name = "PerlaCorazon", Shape = "Ball", Size = V(7, 7, 7), CFrame = CF(c.X, domeY + 4, c.Z), Color = rgb(220, 250, 255), Material = "Neon",
		Light = { Color = CYAN, Range = 56, Brightness = 1.6 } })
	-- La aguja mayor, encima de la cúpula
	local crownTop = Nacara.FloorY + P.Crown
	local base = domeY + P.Dome.H - 1.5
	local segs = { { 2.4, 0.42, NACRE }, { 1.6, 0.33, PEARL_PINK }, { 0.8, 0.25, NACRE } }
	local y = base
	for _, s in segs do
		local h = (crownTop - base) * s[2]
		add({ Name = "AgujaMayor", Shape = "Cylinder", Size = V(h, s[1] * 2, s[1] * 2), CFrame = upright(V(c.X, y + h / 2, c.Z)), Color = s[3], Material = "SmoothPlastic" })
		y += h
	end
	add({ Name = "PuntaMayor", Shape = "Ball", Size = V(2.6, 2.6, 2.6), CFrame = CF(c.X, crownTop, c.Z), Color = GOLD, Material = "Neon" })
	-- Las agujas de alrededor (en la terraza): tres tramos que se estrechan y una perla de luz
	for k = 1, P.Spires.Count do
		local a = (k - 0.5) / P.Spires.Count * math.pi * 2
		local h = if k % 2 == 0 then P.Spires.High else P.Spires.Low
		local px, pz = c.X + cos(a) * P.Spires.Ring, c.Z + sin(a) * P.Spires.Ring
		local yy = c.Y + 1.2
		for i, s in { { 2.4, 0.5, NACRE }, { 1.7, 0.32, if k % 2 == 0 then PEARL_PINK else NACRE_BLUE }, { 0.9, 0.18, NACRE } } do
			local hh = h * s[2]
			add({ Name = "Aguja", Shape = "Cylinder", Size = V(hh, s[1] * 2, s[1] * 2), CFrame = upright(V(px, yy + hh / 2, pz)), Color = s[3], Material = "SmoothPlastic", Collide = i == 1 })
			yy += hh
		end
		add({ Name = "PerlaAguja", Shape = "Ball", Size = V(1.8, 1.8, 1.8), CFrame = CF(px, yy + 0.6, pz), Color = if k % 2 == 0 then GOLD else CYAN, Material = "Neon" })
	end
	-- Corales de colores al borde de la isla (tres ramas por grupo; sin choques)
	for k = 1, 12 do
		local a = k / 12 * math.pi * 2 + 0.13
		local r = tr + 4 + (k % 3) * 1.5
		local px, pz = c.X + cos(a) * r, c.Z + sin(a) * r
		local col = CORAL[1 + k % #CORAL]
		for b = 0, 2 do
			local h = 3 + ((k + b) % 3) * 1.2
			local lean = ANG(rad(-14 + b * 14), a, rad(10 - b * 8))
			add({ Name = "Coral", Shape = "Cylinder", Size = V(h, 0.9, 0.9), CFrame = CF(px, c.Y + h / 2 - 0.4, pz) * lean * ANG(0, 0, rad(90)), Color = col, Material = if b == 1 then "Neon" else "SmoothPlastic" })
		end
	end
	-- El tubo de cristal de la plaza (arco norte) al palacio (borde sur de la terraza): suelo, tubo y dos
	-- franjas de luz a lo largo (la segunda luz de verdad, en medio)
	local a0 = Nacara.toWorld(0, -50, 0.6)
	local a1 = V(c.X, c.Y + 1.2, c.Z + tr - 0.5)
	local d = a1 - a0
	local len = d.Magnitude
	local along = CFrame.lookAt((a0 + a1) / 2, a1)
	add({ Name = "SueloTubo", Shape = "Block", Size = V(5, 0.6, len), CFrame = along, Color = NACRE, Material = "SmoothPlastic", Collide = true })
	add({ Name = "Tubo", Shape = "Cylinder", Size = V(len, 11, 11), CFrame = along * CF(0, 4.6, 0) * ANG(0, rad(90), 0), Color = GLASS_TINT, Material = "Glass", Transparency = 0.72 })
	for s = -1, 1, 2 do
		add({ Name = "FranjaTubo", Shape = "Block", Size = V(0.35, 0.35, len), CFrame = along * CF(s * 3.6, 8.6, 0), Color = CYAN, Material = "Neon",
			Light = if s == 1 then { Color = CYAN, Range = 26, Brightness = 1 } else nil })
	end
	for _, e in { a0, a1 } do
		local f = CFrame.lookAt(e, e + d.Unit)
		for s = -1, 1, 2 do
			add({ Name = "PortalTubo", Shape = "Block", Size = V(0.6, 9, 0.6), CFrame = f * CF(s * 5.2, 4.5, 0), Color = GOLD, Material = "Neon" })
		end
		add({ Name = "PortalTubo", Shape = "Block", Size = V(11, 0.6, 0.6), CFrame = f * CF(0, 9.2, 0), Color = GOLD, Material = "Neon" })
	end
	-- La Plaza Central: el borde de luz de su isla (cuatro arcos con huecos en los arcos de entrada) y los carteles
	local rim = NacaraV2.PlazaRim
	for k = 0, 39 do
		local deg = k * 9 + 4.5
		local gap = false
		for _, g in rim.Gaps do
			if math.abs(((deg - g + 180) % 360) - 180) < 12 then
				gap = true
			end
		end
		if not gap then
			local a = rad(deg)
			local p = Nacara.toWorld(math.sin(a) * rim.R, -math.cos(a) * rim.R, 0.2)
			add({ Name = "BordePlaza", Shape = "Block", Size = V(8.6, 0.4, 0.8), CFrame = CF(p) * ANG(0, -a, 0), Color = CYAN, Material = "Neon", Transparency = 0.2 })
		end
	end
	local function signAt(pos: Vector3, toward: Vector3, title: string, sub: string)
		local dir = (toward - pos) * V(1, 0, 1)
		local cf = CFrame.lookAt(pos, pos + dir.Unit)
		add({ Name = "PosteCartel", Shape = "Cylinder", Size = V(6, 0.5, 0.5), CFrame = upright(pos + V(0, 3, 0)), Color = NACRE, Material = "SmoothPlastic" })
		add({ Name = "Cartel", Shape = "Block", Size = V(9, 3, 0.3), CFrame = cf * CF(0, 6.8, 0), Color = rgb(18, 34, 62), Material = "SmoothPlastic", Collide = true, Sign = { Title = title, Sub = sub } })
		add({ Name = "MarcoCartel", Shape = "Block", Size = V(9.6, 0.28, 0.36), CFrame = cf * CF(0, 8.45, 0), Color = GOLD, Material = "Neon" })
	end
	signAt(Nacara.toWorld(22, -56, 0), Nacara.toWorld(22, 0, 0), "PLAZA CENTRAL", "Nácara · la fuente de luz")
	signAt(V(c.X - 9, c.Y + 1.2, c.Z + tr - 3), V(c.X - 9, c.Y, c.Z + 80), "PALACIO REAL", "Sala del Consejo al oeste")
	return out
end

---------------------------------------------------------------------

local function folder(): Instance
	local f = workspace:FindFirstChild("NacaraCiudad")
	if not f then
		f = Instance.new("Folder")
		f.Name = "NacaraCiudad"
		f.Parent = workspace
	end
	return f :: Instance
end

local function label(board: BasePart, title: string, sub: string?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, if sub then 0.58 else 1)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = rgb(255, 240, 200)
	t.Parent = gui
	if sub then
		local s = Instance.new("TextLabel")
		s.Position = UDim2.fromScale(0.04, 0.6)
		s.Size = UDim2.fromScale(0.92, 0.34)
		s.BackgroundTransparency = 1
		s.Text = sub
		s.TextScaled = true
		s.Font = Enum.Font.Gotham
		s.TextColor3 = rgb(150, 230, 245)
		s.Parent = gui
	end
	gui.Parent = board
end

local function make(parent: Instance, s: Spec): BasePart
	local p = Instance.new("Part")
	p.Name = s.Name
	p.Anchored = true
	p.Size = s.Size
	p.CFrame = s.CFrame
	p.Color = s.Color
	p.Material = (Enum.Material :: any)[s.Material]
	if s.Shape == "Ball" and (math.abs(s.Size.X - s.Size.Y) > 0.01 or math.abs(s.Size.X - s.Size.Z) > 0.01) then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	elseif s.Shape ~= "Block" then
		p.Shape = (Enum.PartType :: any)[s.Shape]
	end
	p.CanCollide = s.Collide == true
	p.CanQuery = s.Collide == true
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = s.Transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if s.Light and NacaraV2Builder.Stats.Lights < NacaraV2.MaxLights then
		NacaraV2Builder.Stats.Lights += 1
		local l = Instance.new("PointLight")
		l.Color = s.Light.Color
		l.Range = s.Light.Range
		l.Brightness = s.Light.Brightness
		l.Shadows = false
		l.Parent = p
	end
	if s.Sign then
		label(p, s.Sign.Title, s.Sign.Sub)
	end
	p.Parent = parent
	return p
end

-- La isla: roca de basalto bajo la terraza (hasta el fondo) y una capa de grano blanco encima
function NacaraV2Builder.island(terrain: any)
	local P = NacaraV2.Palace
	local at = NacaraV2.PalaceAt
	local r = NacaraV2.ById.Palacio.R
	local top = Nacara.FloorY + P.Island
	local c = V(Nacara.Center.X + at.X, 0, Nacara.Center.Z + at.Z)
	local depth = 18
	terrain:FillCylinder(CF(c.X, top - depth / 2 - 1, c.Z), depth, r, Enum.Material.Basalt)
	terrain:FillCylinder(CF(c.X, top - 1.5, c.Z), 3, r - 3, Enum.Material.Salt)
	NacaraV2Builder.Stats.Fills += 2
end

function NacaraV2Builder.build(terrain: any?)
	if NacaraV2Builder.State ~= "None" then
		return
	end
	NacaraV2Builder.State = "Building"
	local ok, err = pcall(NacaraV2Builder.island, terrain or workspace.Terrain)
	if not ok then
		warn("[NacaraV2Builder] isla: " .. tostring(err))
	end
	local m = Instance.new("Model")
	m.Name = "Nacara_V2_Palacio"
	pcall(function()
		(m :: any).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end)
	local budget = NacaraV2.ById.Palacio.Budget + NacaraV2.ById.Plaza.Budget
	for _, s in NacaraV2Builder.plan() do
		if NacaraV2Builder.Stats.Parts >= budget then
			break
		end
		NacaraV2Builder.Stats.Parts += 1
		make(m, s)
	end
	m.Parent = folder()
	NacaraV2Builder.State = "Ready"
	print(("[NacaraV2Builder] prototipo de Nácara v2 (Palacio Real y Plaza Central): %d piezas, %d luces"):format(NacaraV2Builder.Stats.Parts, NacaraV2Builder.Stats.Lights))
end

function NacaraV2Builder._reset()
	NacaraV2Builder.State = "None"
	NacaraV2Builder.Stats = { Parts = 0, Lights = 0, Fills = 0 }
end

return NacaraV2Builder
