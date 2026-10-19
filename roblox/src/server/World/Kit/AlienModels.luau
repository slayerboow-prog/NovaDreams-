-- AlienModels: los modelos de la «Invasión de la Grieta» hechos con piezas (docs/invasion.md):
-- tropas de tierra (4 tipos por raza), naves (caza, dron, nave de desembarco, explorador), el rey de
-- cada raza (enorme, con puntos débiles), las criaturas en que se transforma la gente, la baliza
-- nodriza y el avión de la evacuación. Diseños originales y fáciles de leer de un vistazo: cada raza
-- tiene su forma (Races.Style) y sus colores (Races.Palette).
--
--   * Todo anclado y sin colisiones (lo mueve el servidor con PivotTo); el raíz es el PrimaryPart.
--   * Pocas piezas (topes para el móvil): tropa ≤ 18, nave ≤ 18, nave de desembarco ≤ 24, rey ≤ 45.
--   * Las tropas llevan Humanoid (las armas de Valmar buscan un Humanoid para hacer daño: WeaponService)
--     con la vida escondida (la lleva InvasionService) y sin nombre encima.
--   * Nada de sangre: al caer estallan en trozos, chispas y luz (los efectos los pone el cliente).
--
-- v2 (docs/invasion.md, «Alienígenas v2»): si World/AlienMeshLoader ha cargado la malla de Blender de
-- ese modelo (shared/Invasion/AlienMallas), se monta con ella: un raíz invisible anclado (el mismo
-- tamaño y nombre que antes: lo mueve el servidor con PivotTo) y los segmentos (MeshPart sin anclar,
-- sin masa ni colisión) unidos con Motor6D en sus pivotes; el cliente los anima (Controllers/AlienAnim)
-- y cambia a la versión lejana (LOD). Si no hay malla, los de piezas de siempre (el respaldo).

local AlienModels = {}

-- ¿De dónde salen las plantillas de malla? (World/AlienMeshLoader; las pruebas ponen un doble)
AlienModels.meshSource = function(id: string): Folder?
	local ok, loader = pcall(function()
		return require(script.Parent.Parent.AlienMeshLoader)
	end)
	if ok and loader then
		return loader.template(id)
	end
	return nil
end

local rgb = Color3.fromRGB
local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles

local function col(t: { number }, k: number?): Color3
	local f = k or 1
	return rgb(math.clamp(t[1] * f, 0, 255), math.clamp(t[2] * f, 0, 255), math.clamp(t[3] * f, 0, 255))
end

type Builder = { Model: Model, Root: BasePart, Count: number }

local function newModel(name: string, rootSize: Vector3): Builder
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = rootSize
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true
	root.CanTouch = false
	root.CFrame = CFrame.identity
	root.Parent = model
	model.PrimaryPart = root
	return { Model = model, Root = root, Count = 1 }
end

local function add(b: Builder, name: string, size: Vector3, at: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, transparency: number?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = at
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = size.Magnitude > 6
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = b.Model
	b.Count += 1
	return p
end

local function light(p: BasePart, color: Color3, range: number, brightness: number?)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1.5
	l.Shadows = false
	l.Parent = p
end

local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local M = Enum.Material

-- Materiales de cada estilo
local STYLE = {
	Cristal = { Body = M.Glass, Trim = M.Metal, BodyAlpha = 0.15 },
	Membrana = { Body = M.SmoothPlastic, Trim = M.Fabric, BodyAlpha = 0 },
	Chatarra = { Body = M.CorrodedMetal, Trim = M.Metal, BodyAlpha = 0 },
	Luz = { Body = M.ForceField, Trim = M.SmoothPlastic, BodyAlpha = 0.1 },
	Niebla = { Body = M.Slate, Trim = M.SmoothPlastic, BodyAlpha = 0 },
}

AlienModels.Heights = { Grunt = 6, Heavy = 9, Ranged = 7, Elite = 11 }

local function mallas(): any
	local ok, m = pcall(function()
		return require(game:GetService("ReplicatedStorage").Shared.Invasion.AlienMallas)
	end)
	return if ok then m else nil
end

-- Monta un modelo de malla (v2) o devuelve nil (sin plantilla o sin datos: el de piezas).
-- id = "<Raza>_<Tipo>"; rootSize y rootName como el de piezas; scale (el rey: KingScale).
function AlienModels.mesh(id: string, rootSize: Vector3, rootName: string, scale: number?): Model?
	local spec = mallas()
	local m = spec and spec.Models and spec.Models[id]
	local tpl = m and AlienModels.meshSource(id)
	if not m or not tpl then
		return nil
	end
	local k = scale or 1
	local b = newModel(id, rootSize)
	b.Root.Name = rootName
	-- (el raíz es una caja invisible del tamaño del modelo: que no tape la cabeza a las balas; dan los
	-- segmentos, y la cabeza cuenta como cabeza)
	b.Root.CanQuery = false
	local mains: { [string]: BasePart } = {}
	local centers: { [string]: Vector3 } = {}
	local made: { { Part: BasePart, Spec: any } } = {}
	-- La pieza que lleva la articulación de cada segmento: la principal (Body, Head…) o, si el segmento
	-- solo brilla (el halo, una cola de luz), su pieza de brillo
	local lead: { [string]: string } = {}
	for _, p in m.Parts do
		if not p.Lod and (lead[p.Joint] == nil or (not p.Glow and p.Name == p.Joint)) then
			lead[p.Joint] = p.Name
		end
	end
	for _, p in m.Parts do
		local src = tpl:FindFirstChild(p.Name)
		if not src or not src:IsA("BasePart") then
			if not p.Glow and not p.Lod then
				b.Model:Destroy()
				return nil -- (una plantilla a medias: mejor el de piezas)
			end
			continue
		end
		local part = src:Clone()
		part.Size = p.Size * k
		part.CFrame = CFrame.new(p.Center * k)
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.Massless = true
		part.CanQuery = not p.Lod
		part.CastShadow = not p.Glow and not p.Lod
		if p.Lod then
			part:SetAttribute("Lod", true)
		end
		part.Parent = b.Model
		b.Count += 1
		table.insert(made, { Part = part, Spec = p })
		if not p.Lod and lead[p.Joint] == p.Name then
			mains[p.Joint] = part
			centers[p.Joint] = p.Center * k
		end
	end
	-- Articulaciones: Motor6D de su padre (o del raíz) a cada segmento, en su pivote
	for _, e in made do
		local p = e.Spec
		if p.Lod or lead[p.Joint] ~= p.Name then
			continue
		end
		local parent = mains[p.Parent] or b.Root
		local parentCenter = if mains[p.Parent] then centers[p.Parent] else Vector3.zero
		local pivot = p.Pivot * k
		local joint = Instance.new("Motor6D")
		joint.Name = p.Joint
		joint.Part0 = parent
		joint.Part1 = e.Part
		joint.C0 = CFrame.new(pivot - parentCenter)
		joint.C1 = CFrame.new(pivot - p.Center * k)
		joint.Parent = e.Part
	end
	-- El brillo y la versión lejana van pegados a su segmento (o al raíz)
	for _, e in made do
		local p = e.Spec
		if not p.Lod and lead[p.Joint] == p.Name then
			continue
		end
		local to = if p.Lod then b.Root else (mains[p.Joint] or b.Root)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = to
		weld.Part1 = e.Part
		weld.Parent = e.Part
	end
	b.Model:SetAttribute("Mesh", true)
	b.Model:SetAttribute("Gait", m.Gait)
	b.Model:SetAttribute("MeshHeight", (m.Height or rootSize.Y) * k)
	b.Model:SetAttribute("Parts", b.Count)
	return b.Model
end

---------------------------------------------------------------------
-- Tropas de tierra
---------------------------------------------------------------------
-- race: shared/Invasion/Races (Palette, Style). kind: Grunt | Heavy | Ranged | Elite. scale: 1 (5 = el rey)
local function troopHumanoid(model: Model)
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.MaxHealth = 1000
	humanoid.Health = 1000
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model
end

function AlienModels.ground(race: { [string]: any }, kind: string, scale: number?, meshKind: string?): Model
	local k = scale or 1
	local h = (AlienModels.Heights[kind] or 6) * k
	local mesh = AlienModels.mesh(race.Id .. "_" .. (meshKind or kind), V(2 * k, h, 2 * k), "HumanoidRootPart", k)
	if mesh then
		mesh.Name = race.Id .. "_" .. kind
		troopHumanoid(mesh)
		return mesh
	end
	local b = newModel(race.Id .. "_" .. kind, V(2 * k, h, 2 * k))
	local P = race.Palette
	local body, trim, glow = col(P.Body), col(P.Trim), col(P.Glow)
	local st = STYLE[race.Style] or STYLE.Cristal
	local wide = if kind == "Heavy" then 1.45 elseif kind == "Elite" then 1.2 else 1
	local y0 = -h / 2 -- (los pies)
	local top = y0 + h -- (lo más alto del cuerpo: ahí va la corona de la élite)
	if race.Style == "Cristal" then
		-- Trípode de cristal: tres patas finas, un cuerpo de prisma inclinado y una «cabeza» que brilla
		for i = 0, 2 do
			local a = i / 3 * math.pi * 2
			add(b, "Pata", V(0.5 * k, h * 0.5, 0.5 * k), C(math.cos(a) * 0.9 * k * wide, y0 + h * 0.25, math.sin(a) * 0.9 * k * wide) * A(math.sin(a) * 0.35, 0, -math.cos(a) * 0.35), trim, st.Trim)
		end
		add(b, "Torso", V(2.2 * k * wide, h * 0.42, 2.2 * k * wide), C(0, y0 + h * 0.62, 0) * A(0, math.rad(45), math.rad(12)), body, st.Body, nil, st.BodyAlpha)
		local head = add(b, "Head", V(1.1 * k, 1.6 * k, 1.1 * k), C(0, y0 + h * 0.93, 0) * A(0, math.rad(45), 0), glow, M.Neon)
		light(head, glow, 10 * k)
		add(b, "Hombrera", V(0.6 * k, 1.4 * k, 0.6 * k), C(1.3 * k * wide, y0 + h * 0.78, 0) * A(0, 0, math.rad(-30)), body, st.Body, nil, st.BodyAlpha)
		add(b, "Hombrera", V(0.6 * k, 1.4 * k, 0.6 * k), C(-1.3 * k * wide, y0 + h * 0.78, 0) * A(0, 0, math.rad(30)), body, st.Body, nil, st.BodyAlpha)
	elseif race.Style == "Membrana" then
		-- Una bola de membrana con tentáculos debajo y un ojo grande que brilla
		local r = 2.6 * k * wide
		add(b, "Torso", V(r, r, r), C(0, y0 + h * 0.6, 0), body, st.Body, BALL)
		top = y0 + h * 0.6 + r / 2
		local eye = add(b, "Head", V(r * 0.45, r * 0.45, r * 0.45), C(0, y0 + h * 0.66, -r * 0.38), glow, M.Neon, BALL)
		light(eye, glow, 9 * k)
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2 + 0.4
			add(b, "Tentaculo", V(h * 0.45, 0.45 * k, 0.45 * k), C(math.cos(a) * 0.8 * k, y0 + h * 0.22, math.sin(a) * 0.8 * k) * A(0, -a, math.rad(70)), trim, st.Trim, CYL)
		end
		add(b, "Manchas", V(r * 0.3, r * 0.3, r * 0.3), C(r * 0.32, y0 + h * 0.75, 0), glow, M.Neon, BALL, 0.3)
	elseif race.Style == "Chatarra" then
		-- Autómata de chatarra: patas de pistón, cajón de remaches, visera amarilla y una antena
		add(b, "Pierna", V(0.8 * k, h * 0.4, 0.8 * k), C(0.7 * k * wide, y0 + h * 0.2, 0), trim, st.Trim)
		add(b, "Pierna", V(0.8 * k, h * 0.4, 0.8 * k), C(-0.7 * k * wide, y0 + h * 0.2, 0), trim, st.Trim)
		add(b, "Torso", V(2.4 * k * wide, h * 0.38, 1.6 * k), C(0, y0 + h * 0.6, 0), body, st.Body)
		add(b, "Head", V(1.4 * k, 1.1 * k, 1.3 * k), C(0, y0 + h * 0.86, 0), trim, st.Trim)
		top = y0 + h * 0.86 + 0.55 * k
		local visor = add(b, "Visera", V(1.2 * k, 0.3 * k, 0.1 * k), C(0, y0 + h * 0.87, -0.66 * k), glow, M.Neon)
		light(visor, glow, 9 * k)
		add(b, "Antena", V(0.15 * k, 1.6 * k, 0.15 * k), C(0.4 * k, y0 + h * 0.86 + 1.3 * k, 0), trim, st.Trim)
		add(b, "Brazo", V(0.6 * k, h * 0.35, 0.6 * k), C(1.6 * k * wide, y0 + h * 0.55, 0), trim, st.Trim)
		add(b, "Brazo", V(0.6 * k, h * 0.35, 0.6 * k), C(-1.6 * k * wide, y0 + h * 0.55, 0), trim, st.Trim)
	elseif race.Style == "Luz" then
		-- Ser de luz: un núcleo que brilla dentro de un halo, un aro que gira (el cliente) y esquirlas
		local r = 2.2 * k * wide
		local core = add(b, "Head", V(r * 0.6, r * 0.6, r * 0.6), C(0, y0 + h * 0.7, 0), glow, M.Neon, BALL)
		light(core, glow, 14 * k, 2.2)
		add(b, "Torso", V(r, r * 1.5, r), C(0, y0 + h * 0.6, 0), body, st.Body, BALL, st.BodyAlpha)
		top = y0 + h * 0.6 + r * 0.75
		add(b, "Aro", V(0.25 * k, r * 1.7, r * 1.7), C(0, y0 + h * 0.6, 0) * A(0, 0, math.rad(90)), trim, M.Neon, CYL, 0.2)
		add(b, "Estela", V(1.4 * k * wide, h * 0.36, 1.4 * k * wide), C(0, y0 + h * 0.2, 0) * A(0, math.rad(45), 0), body, st.Body, nil, 0.35)
		add(b, "Chispa", V(0.6 * k, 0.6 * k, 0.6 * k), C(0, y0 + h * 0.05, 0), glow, M.Neon, BALL)
	else
		-- Niebla: caparazón de pizarra, aletas y un farolillo colgado de una antena
		local r = 2.6 * k * wide
		add(b, "Torso", V(r, r * 0.75, r * 1.1), C(0, y0 + h * 0.55, 0), body, st.Body, BALL)
		add(b, "Aleta", V(0.3 * k, r * 0.7, r * 0.6), C(r * 0.48, y0 + h * 0.6, 0) * A(0, 0, math.rad(-35)), trim, st.Trim)
		add(b, "Aleta", V(0.3 * k, r * 0.7, r * 0.6), C(-r * 0.48, y0 + h * 0.6, 0) * A(0, 0, math.rad(35)), trim, st.Trim)
		add(b, "Pierna", V(0.7 * k, h * 0.35, 0.7 * k), C(0.6 * k, y0 + h * 0.17, 0), trim, st.Trim)
		add(b, "Pierna", V(0.7 * k, h * 0.35, 0.7 * k), C(-0.6 * k, y0 + h * 0.17, 0), trim, st.Trim)
		add(b, "Tallo", V(0.15 * k, 1.8 * k, 0.15 * k), C(0, y0 + h * 0.85, -r * 0.2), trim, st.Trim)
		local lamp = add(b, "Head", V(0.8 * k, 0.8 * k, 0.8 * k), C(0, y0 + h * 0.97, -r * 0.35), glow, M.Neon, BALL)
		top = y0 + h * 0.55 + r * 0.375
		light(lamp, glow, 10 * k)
	end
	-- Por tipo: el tirador lleva un cañón largo; la élite, una corona de púas que brillan
	if kind == "Ranged" or kind == "Elite" then
		add(b, "Arma", V(0.35 * k, 0.35 * k, h * 0.45), C(1.1 * k * wide, y0 + h * 0.62, -h * 0.18), trim, M.Metal)
		add(b, "Boca", V(0.45 * k, 0.45 * k, 0.3 * k), C(1.1 * k * wide, y0 + h * 0.62, -h * 0.42), glow, M.Neon)
	end
	if kind == "Elite" then
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			add(b, "Pua", V(0.3 * k, 1.4 * k, 0.3 * k), C(math.cos(a) * 0.7 * k, top + 0.4 * k, math.sin(a) * 0.7 * k) * A(math.sin(a) * 0.4, 0, -math.cos(a) * 0.4), glow, M.Neon)
		end
	end
	troopHumanoid(b.Model)
	b.Model:SetAttribute("Parts", b.Count)
	return b.Model
end

---------------------------------------------------------------------
-- Naves
---------------------------------------------------------------------
-- kind: Fighter | Drone | Dropship | Scout. Morro hacia -Z.
function AlienModels.ship(race: { [string]: any }, kind: string): Model
	local P = race.Palette
	local body, trim, glow = col(P.Body), col(P.Trim), col(P.Glow)
	local st = STYLE[race.Style] or STYLE.Cristal
	local size = if kind == "Dropship" then 3 elseif kind == "Drone" then 0.55 elseif kind == "Scout" then 0.8 else 1
	-- v2: la malla (el explorador es el caza un poco más pequeño, con su antena)
	local mesh = AlienModels.mesh(race.Id .. "_" .. (if kind == "Scout" then "Fighter" else kind), V(4 * size, 3 * size, 6 * size), "Root", if kind == "Scout" then 0.8 else 1)
	if mesh then
		mesh.Name = race.Id .. "_" .. kind
		local root = mesh.PrimaryPart :: BasePart
		if kind == "Dropship" then
			local beam = Instance.new("Part")
			beam.Name = "Haz"
			beam.Shape = BALL
			beam.Size = V(15, 15, 15)
			beam.CFrame = root.CFrame * C(0, -15, 0)
			beam.Color = col(race.Palette.Glow)
			beam.Material = M.Neon
			beam.Transparency = 0.85
			beam.Anchored, beam.CanCollide, beam.CanTouch, beam.CanQuery = true, false, false, false
			beam.Parent = mesh
		end
		if kind == "Scout" then
			local antenna = Instance.new("Part")
			antenna.Name = "Antena"
			antenna.Size = V(0.2, 6, 0.2)
			antenna.CFrame = root.CFrame * C(0, 3, 0)
			antenna.Color = col(race.Palette.Glow)
			antenna.Material = M.Neon
			antenna.Anchored, antenna.CanCollide, antenna.CanTouch = true, false, false
			antenna.Parent = mesh
		end
		local core = mesh:FindFirstChild("BodyBrillo")
		if core and core:IsA("BasePart") then
			light(core, col(race.Palette.Glow), 16 * size)
		end
		return mesh
	end
	local b = newModel(race.Id .. "_" .. kind, V(4 * size, 3 * size, 6 * size))
	b.Root.Name = "Root"
	local s = size
	if race.Style == "Cristal" then
		add(b, "Casco", V(5 * s, 1.4 * s, 9 * s), C(0, 0, 0) * A(0, math.rad(45), 0), body, st.Body, nil, st.BodyAlpha)
		add(b, "Quilla", V(1.2 * s, 3 * s, 7 * s), C(0, 0.4 * s, 0), trim, st.Trim)
		local core = add(b, "Nucleo", V(1.6 * s, 1.6 * s, 1.6 * s), C(0, 0.9 * s, 0) * A(math.rad(45), math.rad(45), 0), glow, M.Neon)
		light(core, glow, 16 * s)
		add(b, "Ala", V(9 * s, 0.4 * s, 2.4 * s), C(0, -0.2 * s, 1.5 * s), body, st.Body, nil, st.BodyAlpha)
	elseif race.Style == "Membrana" then
		-- Medusa: campana y tentáculos que cuelgan
		add(b, "Campana", V(7 * s, 4 * s, 7 * s), C(0, 0.6 * s, 0), body, st.Body, BALL)
		local eye = add(b, "Nucleo", V(2.2 * s, 2.2 * s, 2.2 * s), C(0, 0.4 * s, -2.6 * s), glow, M.Neon, BALL)
		light(eye, glow, 14 * s)
		for i = 0, (if kind == "Drone" then 2 else 4) do
			local a = i / 5 * math.pi * 2
			add(b, "Tentaculo", V(5 * s, 0.4 * s, 0.4 * s), C(math.cos(a) * 1.8 * s, -2.8 * s, math.sin(a) * 1.8 * s) * A(0, 0, math.rad(90)), trim, st.Trim, CYL)
		end
	elseif race.Style == "Chatarra" then
		-- Disco sierra: disco con dientes y una cabina cuadrada
		add(b, "Disco", V(1.2 * s, 9 * s, 9 * s), C(0, 0, 0) * A(0, 0, math.rad(90)), body, st.Body, CYL)
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			add(b, "Diente", V(1.2 * s, 0.8 * s, 1.6 * s), C(math.cos(a) * 4.6 * s, 0, math.sin(a) * 4.6 * s) * A(0, -a, 0), trim, st.Trim)
		end
		local eye = add(b, "Nucleo", V(2.2 * s, 1.3 * s, 2.2 * s), C(0, 1.2 * s, 0), glow, M.Neon)
		light(eye, glow, 14 * s)
	elseif race.Style == "Luz" then
		-- Luna creciente de luz
		add(b, "Casco", V(1.2 * s, 8 * s, 8 * s), C(0, 0, 0) * A(0, 0, math.rad(90)), body, st.Body, CYL, st.BodyAlpha)
		add(b, "Hueco", V(1.4 * s, 6.5 * s, 6.5 * s), C(0, 0, -2.2 * s) * A(0, 0, math.rad(90)), trim, M.SmoothPlastic, CYL, 0.6)
		local core = add(b, "Nucleo", V(2 * s, 2 * s, 2 * s), C(0, 0, 1.8 * s), glow, M.Neon, BALL)
		light(core, glow, 18 * s, 2)
	else
		-- Raya de niebla: un ala plana con cola larga
		add(b, "Casco", V(10 * s, 0.9 * s, 6 * s), C(0, 0, 0), body, st.Body, BALL)
		add(b, "Cola", V(0.6 * s, 0.6 * s, 7 * s), C(0, 0, 5.5 * s), trim, st.Trim)
		local eye = add(b, "Nucleo", V(1.6 * s, 0.8 * s, 1.6 * s), C(0, 0.5 * s, -1.6 * s), glow, M.Neon, BALL)
		light(eye, glow, 14 * s)
	end
	if kind == "Fighter" or kind == "Scout" then
		add(b, "Motor", V(1 * s, 1 * s, 1.2 * s), C(1.6 * s, 0, 3.6 * s), glow, M.Neon)
		add(b, "Motor", V(1 * s, 1 * s, 1.2 * s), C(-1.6 * s, 0, 3.6 * s), glow, M.Neon)
	end
	if kind == "Dropship" then
		-- Patas de aterrizaje y la rampa
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2 + math.pi / 4
			add(b, "Pata", V(0.8 * s, 4 * s, 0.8 * s), C(math.cos(a) * 3.4 * s, -2.6 * s, math.sin(a) * 3.4 * s), trim, M.Metal)
		end
		add(b, "Rampa", V(3 * s, 0.4 * s, 3.4 * s), C(0, -2.2 * s, -3.4 * s), trim, M.Metal)
		local beam = add(b, "Haz", V(5 * s, 5 * s, 5 * s), C(0, -5 * s, 0), glow, M.Neon, BALL, 0.85)
		beam.Name = "Haz"
	end
	if kind == "Scout" then
		add(b, "Antena", V(0.2, 6, 0.2), C(0, 3, 0), glow, M.Neon)
	end
	b.Model:SetAttribute("Parts", b.Count)
	return b.Model
end

---------------------------------------------------------------------
-- El rey (o dios) de la raza: una tropa de élite enorme con 3 puntos débiles que brillan
---------------------------------------------------------------------
AlienModels.KingScale = 4.2
function AlienModels.king(race: { [string]: any }): (Model, { BasePart })
	local model = AlienModels.ground(race, "Elite", AlienModels.KingScale, "King")
	model.Name = race.Id .. "_Rey"
	local root = model.PrimaryPart :: BasePart
	local h = root.Size.Y
	local glow = col(race.Palette.Glow)
	local weak = {}
	local spots = { V(h * 0.22, h * 0.15, -h * 0.12), V(-h * 0.22, h * 0.15, -h * 0.12), V(0, h * 0.36, h * 0.12) }
	for i, off in spots do
		local p = Instance.new("Part")
		p.Name = "PuntoDebil" .. i
		p.Shape = BALL
		p.Size = V(4.5, 4.5, 4.5)
		p.Material = M.Neon
		p.Color = glow
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CFrame = root.CFrame * C(off)
		p:SetAttribute("WeakPoint", i)
		light(p, glow, 18, 2.5)
		p.Parent = model
		table.insert(weak, p)
	end
	if model:GetAttribute("Mesh") then
		return model, weak -- (la malla del rey ya lleva su manto: Cape)
	end
	-- Una capa (el manto del rey) y una corona más grande
	local cape = Instance.new("Part")
	cape.Name = "Manto"
	cape.Size = V(h * 0.26, h * 0.42, 0.5)
	cape.CFrame = root.CFrame * C(0, h * 0.12, h * 0.1) * A(math.rad(-8), 0, 0)
	cape.Color = col(race.Palette.Trim, 0.8)
	cape.Material = M.Fabric
	cape.Anchored, cape.CanCollide, cape.CanTouch = true, false, false
	cape.Parent = model
	return model, weak
end

---------------------------------------------------------------------
-- Criaturas (la gente transformada): Animal = a cuatro patas; si no, de pie
---------------------------------------------------------------------
function AlienModels.creature(race: { [string]: any }, creature: { [string]: any }): Model
	local P = race.Palette
	local body, trim, glow = col(P.Body, 1.1), col(P.Trim), col(P.Glow)
	local st = STYLE[race.Style] or STYLE.Cristal
	local animal = creature.Animal == true
	-- v2: la malla de la criatura (los pies, a media altura del raíz)
	local spec = mallas()
	local m = spec and spec.Models and spec.Models[race.Id .. "_" .. creature.Id]
	if m then
		local h = m.Height or 3
		local mesh = AlienModels.mesh(race.Id .. "_" .. creature.Id, V(2, h, 2), "Root", 1)
		if mesh then
			mesh.Name = creature.Id
			mesh:SetAttribute("FeetOffset", h / 2)
			return mesh
		end
	end
	local b = newModel(creature.Id, if animal then V(2, 2.4, 3) else V(2, 5, 1.4))
	b.Root.Name = "Root"
	if animal then
		add(b, "Cuerpo", V(1.8, 1.4, 3), C(0, 0.3, 0), body, st.Body, nil, st.BodyAlpha)
		add(b, "Cabeza", V(1.2, 1.1, 1.2), C(0, 0.9, -1.8), body, st.Body, nil, st.BodyAlpha)
		local eye = add(b, "Ojos", V(1, 0.25, 0.2), C(0, 1.05, -2.42), glow, M.Neon)
		light(eye, glow, 6, 1)
		for _, x in { -0.6, 0.6 } do
			for _, z in { -1, 1 } do
				add(b, "Pata", V(0.4, 1.2, 0.4), C(x, -0.6, z), trim, st.Trim)
			end
		end
		add(b, "Cola", V(0.3, 0.3, 1.4), C(0, 0.6, 2) * A(math.rad(-30), 0, 0), glow, M.Neon)
	else
		add(b, "Cuerpo", V(1.8, 2.2, 1.1), C(0, 0.6, 0), body, st.Body, nil, st.BodyAlpha)
		add(b, "Cabeza", V(1.3, 1.3, 1.3), C(0, 2.4, 0), body, st.Body, BALL, st.BodyAlpha)
		local eye = add(b, "Ojos", V(0.9, 0.25, 0.2), C(0, 2.5, -0.62), glow, M.Neon)
		light(eye, glow, 6, 1)
		add(b, "Pierna", V(0.6, 2, 0.6), C(0.45, -1.4, 0), trim, st.Trim)
		add(b, "Pierna", V(0.6, 2, 0.6), C(-0.45, -1.4, 0), trim, st.Trim)
		add(b, "Brazo", V(0.45, 2, 0.45), C(1.2, 0.5, 0), body, st.Body, nil, st.BodyAlpha)
		add(b, "Brazo", V(0.45, 2, 0.45), C(-1.2, 0.5, 0), body, st.Body, nil, st.BodyAlpha)
	end
	-- (del raíz a los pies: para ponerla en el suelo, InvasionService)
	b.Model:SetAttribute("FeetOffset", if animal then 1.2 else 2.4)
	if creature.Hostile then
		add(b, "Puas", V(0.3, 0.8, 0.3), C(0, if animal then 1.2 else 3.2, 0), glow, M.Neon)
	end
	b.Model:SetAttribute("Parts", b.Count)
	return b.Model
end

---------------------------------------------------------------------
-- La baliza nodriza (misión «La baliza nodriza»): una aguja que brilla con 3 pilones de escudo
---------------------------------------------------------------------
function AlienModels.beacon(race: { [string]: any }): (Model, { BasePart })
	local P = race.Palette
	local b = newModel("BalizaNodriza", V(12, 60, 12))
	b.Root.Name = "Root"
	add(b, "Aguja", V(6, 60, 6), C(0, 0, 0) * A(0, math.rad(45), 0), col(P.Body), STYLE[race.Style].Body)
	local core = add(b, "Nucleo", V(14, 14, 14), C(0, 0, 0), col(P.Glow), M.Neon, BALL, 0.2)
	light(core, col(P.Glow), 60, 3)
	local pylons = {}
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2
		local p = add(b, "Pilon" .. (i + 1), V(5, 5, 5), C(math.cos(a) * 26, -8, math.sin(a) * 26), col(P.Glow), M.Neon, BALL)
		p:SetAttribute("Pylon", i + 1)
		table.insert(pylons, p)
	end
	return b.Model, pylons
end

---------------------------------------------------------------------
-- El avión de la evacuación (EC-VLA de la misión «Corredor de evacuación»): un reactor sencillo
---------------------------------------------------------------------
function AlienModels.evacJet(): Model
	local b = newModel("VueloEvacuacion", V(6, 6, 10))
	b.Root.Name = "Root"
	local white, blue = rgb(240, 242, 245), rgb(30, 80, 170)
	add(b, "Fuselaje", V(60, 7, 7), C(0, 0, 0) * A(0, math.rad(90), 0), white, M.SmoothPlastic, CYL)
	add(b, "Morro", V(7, 7, 7), C(0, 0, -30), white, M.SmoothPlastic, BALL)
	add(b, "Ala", V(62, 1, 12), C(0, -1.5, 2), white, M.SmoothPlastic)
	add(b, "Deriva", V(1, 12, 8), C(0, 6, 26), blue, M.SmoothPlastic)
	add(b, "Estabilizador", V(22, 0.8, 5), C(0, 1, 27), white, M.SmoothPlastic)
	add(b, "Franja", V(7.2, 1.2, 50), C(0, 0.8, 0), blue, M.SmoothPlastic)
	add(b, "Motor", V(7, 3.4, 3.4), C(12, -3, 0) * A(0, math.rad(90), 0), rgb(180, 184, 190), M.Metal, CYL)
	add(b, "Motor", V(7, 3.4, 3.4), C(-12, -3, 0) * A(0, math.rad(90), 0), rgb(180, 184, 190), M.Metal, CYL)
	return b.Model
end

---------------------------------------------------------------------
-- Destrozos (lo que rompen los alienígenas en una zona): marca quemada, cascotes y chispas.
-- Se quita al repararlo («Reparar») o solo con el tiempo (Transform.Recovery)
---------------------------------------------------------------------
function AlienModels.damage(at: Vector3, seed: number): Model
	local b = newModel("Destrozo", V(10, 1, 10))
	b.Root.Name = "Root"
	b.Root.CFrame = C(at)
	add(b, "Quemado", V(0.2, 12, 12), C(at + V(0, 0.08, 0)) * A(0, 0, math.rad(90)), rgb(28, 26, 30), M.Slate, CYL, 0.15)
	local r = Random.new(seed)
	for i = 1, 5 do
		local s = r:NextNumber(1, 2.6)
		add(b, "Cascote", V(s, s * 0.7, s * 1.2), C(at + V(r:NextNumber(-4.5, 4.5), s * 0.3, r:NextNumber(-4.5, 4.5))) * A(r:NextNumber(0, 1), r:NextNumber(0, 6), r:NextNumber(0, 1)), rgb(110, 105, 100), M.Concrete)
	end
	local ember = add(b, "Ascuas", V(1.4, 0.4, 1.4), C(at + V(0, 0.3, 0)), rgb(255, 120, 40), M.Neon, nil, 0.2)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Rate = 4
	smoke.Lifetime = NumberRange.new(2.5, 4)
	smoke.Speed = NumberRange.new(2, 4)
	smoke.Size = NumberSequence.new(1.5, 5)
	smoke.Transparency = NumberSequence.new(0.5, 1)
	smoke.Color = ColorSequence.new(rgb(70, 70, 75))
	smoke.Parent = ember
	return b.Model
end

-- Cono del cordón policial
function AlienModels.cone(at: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = "ConoCordon"
	p.Size = V(1.2, 2.2, 1.2)
	p.CFrame = C(at + V(0, 1.1, 0))
	p.Color = rgb(255, 120, 20)
	p.Material = M.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	return p
end

return AlienModels
