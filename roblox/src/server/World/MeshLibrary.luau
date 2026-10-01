-- MeshLibrary: vegetación con modelos 3D de verdad (MeshPart + SurfaceAppearance PBR) de los packs
-- OFICIALES de Roblox, que un servidor del juego sí puede cargar con InsertService:LoadAsset (los de
-- la comunidad dan "User is not authorized"; ver docs/modelos-tienda-contenido.md).
--
--   * Al arrancar el servidor (Main, en un hilo aparte) carga una vez el Forest Pack y el Landscaping
--     Pack (Duvall Drive), borra TODOS sus scripts, y guarda las plantillas en ServerStorage.MeshLibrary
--     por tipo: árbol de hoja ancha, árbol de calle, árbol joven, arbusto y flor (con su altura natural).
--   * Después cambia en vivo, en tandas, los árboles procedurales de la ciudad (Kit/Nature: modelos
--     "Tree" con Trunk/Branch/Root/Leaves; y los "Arbol" de las rotondas), los arbustos ("Bush") y las
--     flores de los parterres ("Flower" dentro de "FlowerBed") por una copia de una variante elegida
--     según su posición (el mismo sitio, el mismo árbol), escalada a su altura, apoyada en el suelo y
--     con un giro también según su posición.
--   * Colisión: las piezas Trunk del árbol original se quedan como choque INVISIBLE (mismo sitio y
--     tamaño que antes: los coches y los jugadores chocan igual). El tronco de malla (con sus ramas,
--     cuya caja es casi tan grande como la copa) y la copa no chocan ni se tocan ni bloquean rayos.
--   * La copa se llama "Leaves" y lleva la etiqueta Sway y el atributo Pivot (se mece con el viento,
--     Controllers/ObjectMotion). No lleva LeafDetail (no hay racimos de relleno que esconder) y es de
--     material Plastic: las estaciones (Controllers/Weather) solo repintan las hojas LeafyGrass, así que
--     no tocan las de malla (el SurfaceAppearance no se puede repintar) y no se rompe nada.
--   * Palmeras y cipreses se quedan procedurales (el Forest Pack no tiene; en Landscaping no hay nada
--     que encaje). Los setos también.
--   * Si la carga falla (o en Lune, donde no hay InsertService), no se cambia nada: se queda la ciudad
--     procedural tal cual.

local MeshLibrary = {}

MeshLibrary.Packs = {
	{ Name = "Forest", Id = 6432306802, Folder = "Forest Pack" },
	{ Name = "Landscaping", Id = 10840661513, Folder = "Landscaping Pack" },
}

-- Variantes por tipo (nombres tal cual vienen en los packs). Cada tipo tiene:
--   Names:  modelos que se usan (si hay dos con el mismo nombre se queda el que tiene copa)
--   Crown:  la plantilla tiene que tener copa (Leaf/Leaves/Flower) para valer
--   Trunk:  la plantilla tiene que tener tronco
MeshLibrary.Kinds = {
	-- Parques, jardines, campo: árboles de hoja ancha grandes
	Tree = {
		Names = { "BroadLeafTree_Var01", "DogwoodTree_Var01", "MapleLeafTreeVar01", "BeechwoodTree_Var03" },
		Crown = true,
		Trunk = true,
	},
	-- Calles y rotondas: copas más estrechas (no se meten en las fachadas)
	Street = {
		Names = { "BeechwoodTree_Var02", "BroadLeafTree_Var01", "BeechwoodTree_Var03" },
		Crown = true,
		Trunk = true,
	},
	-- Árboles bajitos (menos de 12 studs): árbol joven
	Young = {
		Names = { "BeechwoodSapling_Var01", "BeechwoodTree_Var02" },
		Crown = true,
		Trunk = true,
	},
	Bush = {
		Names = { "MountainLaurelBush_Var01", "RhododendronVar01", "RhododendronVar02", "Flowering_Shrub_04", "Flowering_Shrub_05" },
		Crown = false,
		Trunk = false,
	},
	Flower = {
		Names = {
			"WildFlower01", "Wildflower02", "WildFlower03", "WildFlower04", "Marigold_A", "Marigold_B",
			"Flower_Plant_A_Sm", "May_Night_Plant01", "Flowering_Shrub_01",
		},
		Crown = false,
		Trunk = false,
	},
}

-- Topes (rendimiento): no más de tantos de cada cosa; si hay más, se cambian antes los cercanos a
-- las calles y los del monte (Naturaleza, Campo) se quedan procedurales.
MeshLibrary.MaxTrees = 3000
MeshLibrary.MaxBushes = 1200
MeshLibrary.MaxFlowers = 2400
MeshLibrary.Batch = 20 -- cambios por tanda (luego task.wait: el servidor no se congela)
MeshLibrary.ShadowHeight = 9 -- lo que pasa de esta altura da sombra; lo pequeño, no
MeshLibrary.Remote = { Naturaleza = true, Campo = true } -- monte: lo último

export type Template = {
	Name: string,
	Model: Instance,
	Foot: Vector3, -- pie del tronco (o centro de la base) en el espacio de la plantilla
	Height: number,
	Width: number,
}
export type Library = { [string]: { Template } }

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

local function isCode(d: Instance): boolean
	local ok, yes = pcall(function()
		return d:IsA("LuaSourceContainer")
	end)
	if ok then
		return yes
	end
	return d.ClassName == "Script" or d.ClassName == "LocalScript" or d.ClassName == "ModuleScript"
end

-- Borra todos los scripts (Script, LocalScript, ModuleScript) que traiga lo cargado. Devuelve cuántos.
function MeshLibrary.stripScripts(root: Instance): number
	local doomed = {}
	for _, d in root:GetDescendants() do
		if isCode(d) then
			table.insert(doomed, d)
		end
	end
	for _, d in doomed do
		pcall(function()
			d:Destroy()
		end)
	end
	return #doomed
end

local function parts(root: Instance): { BasePart }
	local list = {}
	if root:IsA("BasePart") then
		table.insert(list, root)
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

-- Caja (alineada con los ejes) de unas piezas, teniendo en cuenta su giro
local function bounds(list: { BasePart }): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, p in list do
		local cf, s = p.CFrame, p.Size / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local e = Vector3.new(
			math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
			math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
			math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
		)
		local c = cf.Position
		lo = Vector3.new(math.min(lo.X, c.X - e.X), math.min(lo.Y, c.Y - e.Y), math.min(lo.Z, c.Z - e.Z))
		hi = Vector3.new(math.max(hi.X, c.X + e.X), math.max(hi.Y, c.Y + e.Y), math.max(hi.Z, c.Z + e.Z))
	end
	return lo, hi
end
MeshLibrary.bounds = bounds

local function role(name: string): string
	local lower = string.lower(name)
	if string.find(lower, "soil", 1, true) then
		return "Soil"
	elseif string.find(lower, "trunk", 1, true) then
		return "Trunk"
	elseif string.find(lower, "lea", 1, true) or string.find(lower, "flower", 1, true) then
		return "Crown" -- Leaf, Leaves, OuterLeaves, Flower
	end
	return "Other"
end
MeshLibrary.role = role

-- Número entre 0 y 1 que solo depende de la posición (y de "salt"): el mismo sitio, la misma elección
function MeshLibrary.hash(pos: Vector3, salt: number?): number
	local x = math.floor(pos.X * 4 + 0.5)
	local z = math.floor(pos.Z * 4 + 0.5)
	local h = (x * 73856093 + z * 19349663 + (salt or 0) * 83492791) % 2147483647
	h = (h * 16807) % 2147483647
	h = (h * 16807) % 2147483647
	return h / 2147483647
end

---------------------------------------------------------------------
-- Plantillas
---------------------------------------------------------------------

-- Los modelos de primer nivel de un pack (dentro de carpetas, no dentro de otros modelos: el
-- RedwoodTreeLarge lleva dentro un DogwoodTree_Var01 y unos helechos que no cuentan)
local function topModels(root: Instance): { Instance }
	local list = {}
	local function walk(node: Instance)
		for _, child in node:GetChildren() do
			if child:IsA("Model") then
				table.insert(list, child)
			elseif child:IsA("Folder") then
				walk(child)
			end
		end
	end
	walk(root)
	return list
end

-- Deja una plantilla lista: sin scripts, sin la tierra de debajo, anclada y con sus medidas
local function makeTemplate(source: Instance, kind: string): Template?
	local spec = MeshLibrary.Kinds[kind]
	local copy = source:Clone()
	MeshLibrary.stripScripts(copy)
	local crown, trunk = 0, 0
	for _, p in parts(copy) do
		local r = role(p.Name)
		if r == "Soil" then
			p:Destroy()
		else
			if r == "Crown" then
				crown += 1
			elseif r == "Trunk" then
				trunk += 1
			end
			p.Anchored = true
		end
	end
	local list = parts(copy)
	if #list == 0 or (spec.Crown and crown == 0) or (spec.Trunk and trunk == 0) then
		copy:Destroy()
		return nil
	end
	local lo, hi = bounds(list)
	-- Pie: el centro de abajo del tronco (si hay), si no el de todo el modelo
	local trunkParts = {}
	for _, p in list do
		if role(p.Name) == "Trunk" then
			table.insert(trunkParts, p)
		end
	end
	local foot = Vector3.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
	if #trunkParts > 0 then
		local tlo, thi = bounds(trunkParts)
		foot = Vector3.new((tlo.X + thi.X) / 2, lo.Y, (tlo.Z + thi.Z) / 2)
	end
	copy.Name = source.Name
	copy:SetAttribute("Height", hi.Y - lo.Y)
	return {
		Name = source.Name,
		Model = copy,
		Foot = foot,
		Height = hi.Y - lo.Y,
		Width = math.max(hi.X - lo.X, hi.Z - lo.Z),
	}
end

-- Prepara la biblioteca a partir de lo que ha devuelto LoadAsset (uno o varios contenedores).
-- Borra los scripts de todo lo cargado. Devuelve { Tipo = { plantillas } } (listas vacías si no hay).
function MeshLibrary.prepare(roots: { Instance }): Library
	local byName: { [string]: { Instance } } = {}
	for _, root in roots do
		MeshLibrary.stripScripts(root)
		for _, m in topModels(root) do
			byName[m.Name] = byName[m.Name] or {}
			table.insert(byName[m.Name], m)
		end
	end
	local library: Library = {}
	for kind, spec in MeshLibrary.Kinds do
		local list = {}
		for _, name in spec.Names do
			-- Con nombres repetidos (BeechwoodTree_Var03 x2) vale el primero que sirva (el que tiene copa)
			for _, candidate in byName[name] or {} do
				local template = makeTemplate(candidate, kind)
				if template then
					table.insert(list, template)
					break
				end
			end
		end
		library[kind] = list
	end
	return library
end

function MeshLibrary.count(library: Library?): number
	local n = 0
	for _, list in library or {} do
		n += #list
	end
	return n
end

-- Variante para un sitio: según la posición (y, si se da, que no sea mucho más ancha que lo que había)
function MeshLibrary.pick(library: Library, kind: string, pos: Vector3, aspect: number?): Template?
	local list = library[kind]
	if not list or #list == 0 then
		return nil
	end
	local fits = list
	if aspect then
		fits = {}
		for _, t in list do
			if t.Width / t.Height <= aspect * 1.4 then
				table.insert(fits, t)
			end
		end
		if #fits == 0 then
			fits = list
		end
	end
	return fits[math.floor(MeshLibrary.hash(pos, 1) * #fits) + 1]
end

---------------------------------------------------------------------
-- Copias colocadas
---------------------------------------------------------------------

local function setFlags(p: BasePart, collide: boolean, shadow: boolean)
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = collide
	p.CastShadow = shadow
	p.Anchored = true
	pcall(function()
		(p :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
end

-- Copia de la plantilla con el pie en "foot", girada "yaw", escalada a "factor".
-- Usa Model:ScaleTo si existe (Roblox); si no (Lune), escala las piezas a mano.
local function placeCopy(template: Template, foot: Vector3, yaw: number, factor: number): Instance
	local copy = template.Model:Clone()
	local origin = template.Foot
	local scaled = false
	if copy:IsA("Model") then
		scaled = pcall(function()
			local model = copy :: Model
			local pivot = model:GetPivot().Position
			model:ScaleTo(model:GetScale() * factor)
			origin = pivot + (template.Foot - pivot) * factor
		end)
	end
	local target = CFrame.new(foot) * CFrame.Angles(0, yaw, 0)
	local base = CFrame.new(origin)
	for _, p in parts(copy) do
		local rel = base:ToObjectSpace(p.CFrame)
		if not scaled then
			p.Size = p.Size * factor
			rel = CFrame.new(rel.Position * factor) * rel.Rotation
		end
		p.CFrame = target * rel
	end
	pcall(function()
		(copy :: any).PrimaryPart = nil
		;(copy :: any).WorldPivot = target
	end)
	return copy
end

local function copyStreaming(from: Instance, to: Instance)
	pcall(function()
		(to :: any).ModelStreamingMode = (from :: any).ModelStreamingMode
	end)
end

local function copyLabels(from: Instance, to: Instance)
	for key, value in from:GetAttributes() do
		if to:GetAttribute(key) == nil then
			to:SetAttribute(key, value)
		end
	end
	pcall(function()
		for _, tag in from:GetTags() do
			to:AddTag(tag)
		end
	end)
end

-- Datos de un árbol procedural: pie, altura, anchura y sus piezas de tronco
type TreeInfo = { Foot: Vector3, Height: number, Width: number, Trunks: { BasePart } }
function MeshLibrary.treeInfo(tree: Instance): TreeInfo?
	local list = parts(tree)
	if #list == 0 then
		return nil
	end
	local trunks = {}
	local lowest: BasePart? = nil
	local lowY = math.huge
	for _, p in list do
		if p.Name == "Trunk" then
			table.insert(trunks, p)
			local b0 = bounds({ p })
			if b0.Y < lowY then
				lowY, lowest = b0.Y, p
			end
		end
	end
	if not lowest then
		return nil
	end
	local lo, hi = bounds(list)
	local root = Vector3.new(lowest.CFrame.Position.X, lowY, lowest.CFrame.Position.Z)
	return { Foot = root, Height = hi.Y - lo.Y, Width = math.max(hi.X - lo.X, hi.Z - lo.Z), Trunks = trunks }
end

local function kindOfTree(tree: Instance, info: TreeInfo): string
	if info.Height < 12 then
		return "Young"
	end
	if tree.Name == "Arbol" then
		return "Street"
	end
	local node = tree.Parent
	for _ = 1, 4 do
		if not node then
			break
		end
		if node.Name == "Streets" or node.Name == "Rotonda" or node.Name == "MainRoads" then
			return "Street"
		end
		node = node.Parent
	end
	return "Tree"
end

-- Cambia un árbol procedural por uno de malla. Devuelve el nuevo (o nil si no hay plantillas o no
-- es un árbol que se pueda cambiar: entonces el original se queda como estaba).
function MeshLibrary.replaceTree(tree: Instance, library: Library): Instance?
	if not tree.Parent or tree:GetAttribute("MeshVariant") ~= nil then
		return nil
	end
	local info = MeshLibrary.treeInfo(tree)
	if not info or info.Height <= 0 then
		return nil
	end
	local kind = kindOfTree(tree, info)
	local template = MeshLibrary.pick(library, kind, info.Foot, info.Width / info.Height)
		or MeshLibrary.pick(library, "Tree", info.Foot, info.Width / info.Height)
	if not template then
		return nil
	end
	-- Altura del original con un poco de variación; sin pasar mucho de su anchura (no tapar fachadas)
	local height = info.Height * (0.92 + MeshLibrary.hash(info.Foot, 2) * 0.18)
	local factor = math.min(height / template.Height, info.Width * 1.3 / template.Width)
	factor = math.max(factor, height * 0.7 / template.Height)
	local yaw = MeshLibrary.hash(info.Foot, 3) * math.pi * 2
	-- (un pelín hundido: así las raíces de la malla no flotan en las cuestas)
	local copy = placeCopy(template, info.Foot - Vector3.new(0, 0.25, 0), yaw, factor)

	local model = Instance.new("Model")
	model.Name = tree.Name
	copyLabels(tree, model)
	model:SetAttribute("MeshVariant", template.Name)
	copyStreaming(tree, model)
	local top = info.Foot + Vector3.new(0, template.Height * factor * 0.45, 0)
	local shadow = template.Height * factor >= MeshLibrary.ShadowHeight
	for _, p in parts(copy) do
		local r = role(p.Name)
		if r == "Crown" then
			p.Name = "Leaves"
			setFlags(p, false, shadow)
			p:AddTag("Sway") -- la copa se mece con el viento (Controllers/ObjectMotion)
			p:SetAttribute("Pivot", top)
		else
			p.Name = if r == "Trunk" then "TrunkMesh" else p.Name
			setFlags(p, false, shadow)
		end
		p.Parent = model
	end
	copy:Destroy()
	-- El choque de siempre: las piezas Trunk del original, invisibles, en su sitio
	for _, t in info.Trunks do
		local collider = t:Clone()
		for _, child in collider:GetChildren() do
			child:Destroy()
		end
		collider.Name = "Trunk"
		collider.Transparency = 1
		collider.CastShadow = false
		collider.CanCollide = true
		collider.CanQuery = true
		collider.CanTouch = true
		collider.Anchored = true
		collider:SetAttribute("Collider", true)
		collider.Parent = model
	end
	model.Parent = tree.Parent
	tree:Destroy()
	return model
end

-- Arbusto (bola "Bush" de Kit/Nature) -> Model "Bush" de malla (sin choque, como antes)
function MeshLibrary.replaceBush(bush: BasePart, library: Library): Instance?
	if not bush.Parent then
		return nil
	end
	local lo, hi = bounds({ bush })
	local foot = Vector3.new(bush.CFrame.Position.X, lo.Y, bush.CFrame.Position.Z)
	local width = math.max(hi.X - lo.X, hi.Z - lo.Z)
	local template = MeshLibrary.pick(library, "Bush", foot)
	if not template then
		return nil
	end
	local height = (hi.Y - lo.Y) * (1.05 + MeshLibrary.hash(foot, 2) * 0.25)
	local factor = math.min(height / template.Height, width * 1.4 / template.Width)
	local copy = placeCopy(template, foot, MeshLibrary.hash(foot, 3) * math.pi * 2, factor)
	local model = Instance.new("Model")
	model.Name = "Bush" -- así el cliente sabe que es un arbusto (se aparta al pasar, ReactMotion)
	model:SetAttribute("MeshVariant", template.Name)
	for _, p in parts(copy) do
		setFlags(p, false, false)
		p.Parent = model
	end
	copy:Destroy()
	model.Parent = bush.Parent
	bush:Destroy()
	return model
end

-- Flor de un parterre (bolita "Flower") -> flor de malla, suelta en el parterre
function MeshLibrary.replaceFlower(flower: BasePart, library: Library): Instance?
	if not flower.Parent then
		return nil
	end
	local lo = bounds({ flower })
	local foot = Vector3.new(flower.CFrame.Position.X, lo.Y, flower.CFrame.Position.Z)
	local template = MeshLibrary.pick(library, "Flower", foot)
	if not template then
		return nil
	end
	local height = 1.1 + MeshLibrary.hash(foot, 2) * 0.6
	local copy = placeCopy(template, foot, MeshLibrary.hash(foot, 3) * math.pi * 2, height / template.Height)
	local first: Instance? = nil
	for _, p in parts(copy) do
		setFlags(p, false, false)
		p.Name = "Flower"
		p:SetAttribute("MeshVariant", template.Name)
		p.Parent = flower.Parent
		first = first or p
	end
	copy:Destroy()
	flower:Destroy()
	return first
end

---------------------------------------------------------------------
-- Qué se cambia y en qué orden
---------------------------------------------------------------------

type Segment = { A: Vector3, B: Vector3 }
local CELL = 64

-- Rejilla con puntos de las calles para saber rápido lo cerca que está algo de una calle
local function roadGrid(segments: { Segment }?): { [string]: { Vector3 } }
	local grid = {}
	for _, s in segments or {} do
		local a, b = s.A, s.B
		local length = (b - a).Magnitude
		local steps = math.max(1, math.ceil(length / 24))
		for i = 0, steps do
			local p = a:Lerp(b, i / steps)
			local key = math.floor(p.X / CELL) .. ":" .. math.floor(p.Z / CELL)
			grid[key] = grid[key] or {}
			table.insert(grid[key], p)
		end
	end
	return grid
end

local function roadDistance(grid: { [string]: { Vector3 } }, pos: Vector3): number
	local cx, cz = math.floor(pos.X / CELL), math.floor(pos.Z / CELL)
	local best = math.huge
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, p in grid[(cx + dx) .. ":" .. (cz + dz)] or {} do
				local d = Vector3.new(p.X - pos.X, 0, p.Z - pos.Z).Magnitude
				if d < best then
					best = d
				end
			end
		end
	end
	return best
end

local function isRemote(inst: Instance): boolean
	local node = inst.Parent
	for _ = 1, 4 do
		if not node then
			return false
		end
		if MeshLibrary.Remote[node.Name] then
			return true
		end
		node = node.Parent
	end
	return false
end

local function insideFlowerBed(part: Instance): boolean
	local parent = part.Parent
	return parent ~= nil and parent:IsA("Model") and parent.Name == "FlowerBed"
end

-- Busca lo que se puede cambiar y lo ordena: primero lo cercano a las calles, el monte al final.
-- Devuelve { Trees, Bushes, Flowers }, ya recortados a los topes.
function MeshLibrary.collect(roots: { Instance }, segments: { Segment }?)
	local grid = roadGrid(segments)
	local hasRoads = next(grid) ~= nil
	local trees, bushes, flowers = {}, {}, {}
	for _, root in roots do
		for _, d in root:GetDescendants() do
			if d:IsA("Model") and (d.Name == "Tree" or d.Name == "Arbol") and d:GetAttribute("MeshVariant") == nil then
				if d:FindFirstChild("Trunk") then
					table.insert(trees, d)
				end
			elseif d:IsA("BasePart") and d.Name == "Bush" and d:GetAttribute("MeshVariant") == nil then
				table.insert(bushes, d)
			elseif d:IsA("BasePart") and d.Name == "Flower" and d:GetAttribute("MeshVariant") == nil and insideFlowerBed(d) then
				table.insert(flowers, d)
			end
		end
	end
	local function order(list: { Instance }, max: number): { Instance }
		local score: { [Instance]: number } = {}
		for _, inst in list do
			local pos = if inst:IsA("BasePart")
				then (inst :: BasePart).CFrame.Position
				else (function()
					local lo, hi = bounds(parts(inst))
					return (lo + hi) / 2
				end)()
			local s = if hasRoads then math.min(roadDistance(grid, pos), 1000) else 0
			if isRemote(inst) then
				s += 2000
			end
			score[inst] = s
		end
		table.sort(list, function(a, b)
			return score[a] < score[b]
		end)
		while #list > max do
			table.remove(list)
		end
		return list
	end
	return {
		Trees = order(trees, MeshLibrary.MaxTrees),
		Bushes = order(bushes, MeshLibrary.MaxBushes),
		Flowers = order(flowers, MeshLibrary.MaxFlowers),
	}
end

-- Cambia todo lo que haga falta en tandas (task.wait entre tandas). Devuelve cuántos de cada.
function MeshLibrary.run(roots: { Instance }, library: Library, segments: { Segment }?)
	local done = { Trees = 0, Bushes = 0, Flowers = 0 }
	if MeshLibrary.count(library) == 0 then
		return done
	end
	local found = MeshLibrary.collect(roots, segments)
	local step = 0
	local function pace()
		step += 1
		if step % MeshLibrary.Batch == 0 then
			task.wait()
		end
	end
	for _, tree in found.Trees do
		local ok, result = pcall(MeshLibrary.replaceTree, tree, library)
		if ok and result then
			done.Trees += 1
		end
		pace()
	end
	for _, bush in found.Bushes do
		local ok, result = pcall(MeshLibrary.replaceBush, bush, library)
		if ok and result then
			done.Bushes += 1
		end
		pace()
	end
	for _, flower in found.Flowers do
		local ok, result = pcall(MeshLibrary.replaceFlower, flower, library)
		if ok and result then
			done.Flowers += 1
		end
		pace()
	end
	return done
end

---------------------------------------------------------------------
-- Arranque en el servidor
---------------------------------------------------------------------

-- Carga los packs (una vez) y deja las plantillas en ServerStorage.MeshLibrary. nil si no hay nada.
function MeshLibrary.load(): Library?
	local ok, result = pcall(function()
		local InsertService = game:GetService("InsertService")
		local ServerStorage = game:GetService("ServerStorage")
		local roots = {}
		for _, pack in MeshLibrary.Packs do
			local loaded, asset = pcall(function()
				return InsertService:LoadAsset(pack.Id)
			end)
			if loaded and asset then
				MeshLibrary.stripScripts(asset)
				table.insert(roots, asset)
			else
				warn(("[MeshLibrary] No se pudo cargar %s (%d): %s"):format(pack.Name, pack.Id, tostring(asset)))
			end
		end
		if #roots == 0 then
			return nil
		end
		local library = MeshLibrary.prepare(roots)
		-- Plantillas en ServerStorage (por tipo); lo cargado entero ya no hace falta
		local folder = ServerStorage:FindFirstChild("MeshLibrary") or Instance.new("Folder")
		folder.Name = "MeshLibrary"
		for kind, list in library do
			local sub = Instance.new("Folder")
			sub.Name = kind
			for _, t in list do
				t.Model.Parent = sub
			end
			sub.Parent = folder
		end
		folder.Parent = ServerStorage
		for _, root in roots do
			root:Destroy()
		end
		return library
	end)
	if not ok then
		warn("[MeshLibrary] " .. tostring(result))
		return nil
	end
	return result
end

-- Main: carga y cambia la vegetación de la ciudad (llamar en un hilo aparte: espera)
function MeshLibrary.start(segments: { Segment }?)
	local library = MeshLibrary.load()
	if not library or MeshLibrary.count(library) == 0 then
		warn("[MeshLibrary] Sin plantillas: se queda la vegetación procedural")
		return
	end
	local summary = {}
	for kind, list in library do
		table.insert(summary, ("%s=%d"):format(kind, #list))
	end
	table.sort(summary)
	local roots = {}
	for _, child in workspace:GetChildren() do
		if child:IsA("Model") or child:IsA("Folder") then
			table.insert(roots, child)
		end
	end
	local started = os.clock()
	local done = MeshLibrary.run(roots, library, segments)
	print(("[MeshLibrary] Plantillas: %s · cambiados %d árboles, %d arbustos y %d flores en %.1f s"):format(
		table.concat(summary, " "), done.Trees, done.Bushes, done.Flowers, os.clock() - started
	))
end

return MeshLibrary
