-- StreetDress: calles más realistas en vivo, con los packs de la Tienda que eligió el dueño (qué va en
-- cada tipo de calle y por qué: shared/StreetLook).
--
-- Lo llama World/UserMaterials al arrancar el servidor, con los packs de materiales ya cargados y
-- ANTES de aclarar las piezas (así cada calle se aclara con su propio aspecto, una sola vez):
--   1. Carga además el pack «Realistic Packs» (13752145820: losas de hormigón y otro adoquín).
--   2. Pone en MaterialService los variants de cada aspecto (solo los que ya vienen sobre el material
--      bueno: a un variant de la Tienda no se le puede cambiar el BaseMaterial) y viste pieza a pieza
--      la calzada y la acera de cada calle (part.MaterialVariant). Si un variant no se puede poner,
--      esas piezas se quedan como estaban. Las marcas viales, los pasos de cebra, los bordillos, los
--      parches y las tapas no se tocan.
--   3. Carga el «Realistic road pack» (15004077857), borra sus scripts y usa SOLO las imágenes de sus
--      señales y alcantarillas (nada del cartel de City 17, el puente ni el GAZ-Volga):
--        * tapas «STORM DRAIN» y rejillas encima de las tapas y rejillas que ya pone Kit/StreetDetail
--          (no se duplican: misma posición, una lámina finísima con la imagen)
--        * STOP, paso de peatones y 30/20 en las bocas sin semáforo (Kit/Bocacalles), en la acera, lejos
--          de pasos de cebra, farolas, semáforos, paradas, bancos, árboles y puertas
--      Todo sin colisión salvo el poste de cada señal, con topes (StreetLook.Caps) y con etiquetas: en
--      el nivel gráfico Bajo el cliente lo esconde (Controllers/MaterialDetail).
-- Todo va en pcall y por tandas. Sin los packs no se hace nada.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StreetLook = require(ReplicatedStorage.Shared.StreetLook)
local Choice = require(ReplicatedStorage.Shared.UserMaterialChoice)

local StreetDress = {}

StreetDress.DetailTag = "PropDetail" -- tapas: imágenes baratas, se ven en todos los niveles gráficos
StreetDress.SignTag = "StreetSign" -- señales: se ven en todos los niveles (si un nivel las escondiera, también quitaría el choque del poste)
local FOLDER = "SenalesTrafico"

local V3 = Vector3.new

local function pause(i: number, every: number)
	if i % every == 0 and task then
		task.wait()
	end
end

-- ¿En qué carpeta de calles está? ("Streets", "MainRoads" o nil)
local function containerOf(part: Instance, root: Instance): string?
	local node = part.Parent
	while node and node ~= root do
		if StreetLook.Containers[node.Name] then
			return node.Name
		end
		node = node.Parent
	end
	return nil
end

---------------------------------------------------------------------
-- Variants
---------------------------------------------------------------------

-- Lo cargado: available[pack][nombre original] = BaseMaterial de verdad del variant
function StreetDress.available(service: Instance, library: Instance): { [string]: { [string]: string } }
	local out: { [string]: { [string]: string } } = {}
	local function add(item: Instance)
		if item:IsA("MaterialVariant") then
			local pack, name = item:GetAttribute("SourcePack"), item:GetAttribute("SourceName")
			if type(pack) == "string" and type(name) == "string" then
				out[pack] = out[pack] or {}
				out[pack][name] = (item :: any).BaseMaterial.Name
			end
		end
	end
	for _, item in service:GetChildren() do
		add(item)
	end
	for _, folder in library:GetChildren() do
		for _, item in folder:GetChildren() do
			add(item)
		end
	end
	return out
end

local function findVariant(service: Instance, library: Instance, pack: string, name: string): (Instance?, boolean)
	for _, item in service:GetChildren() do
		if item:GetAttribute("SourcePack") == pack and item:GetAttribute("SourceName") == name then
			return item, true
		end
	end
	local folder = library:FindFirstChild(pack)
	for _, item in if folder then folder:GetChildren() else {} do
		if item:GetAttribute("SourceName") == name then
			return item, false
		end
	end
	return nil, false
end

export type Resolved = { Name: string, Base: string, Pack: string, Source: string }

-- Pone en MaterialService el variant de cada aspecto. Devuelve resolved[aspecto].
function StreetDress.resolve(service: Instance, library: Instance): { [string]: Resolved }
	local available = StreetDress.available(service, library)
	local out: { [string]: Resolved } = {}
	local keys = {}
	for key in StreetLook.Looks do
		table.insert(keys, key)
	end
	table.sort(keys) -- (orden fijo)
	for _, key in keys do
		local look = StreetLook.Looks[key]
		for _, cand in StreetLook.candidates(key, available) do
			local variant: any, already = findVariant(service, library, cand.Pack, cand.Name)
			if variant and variant.BaseMaterial.Name == cand.From then
				if not already then
					-- (solo es de las calles: se le puede cambiar la escala y el patrón)
					local moved = pcall(function()
						variant.Parent = service
					end)
					if moved and variant.Parent == service then
						if look.Studs then
							pcall(function()
								variant.StudsPerTile = look.Studs
							end)
						end
						if look.Pattern then
							pcall(function()
								variant.MaterialPattern = (Enum.MaterialPattern :: any)[look.Pattern]
							end)
						end
					end
				end
				if variant.Parent == service then
					out[key] = { Name = variant.Name, Base = cand.From, Pack = cand.Pack, Source = cand.Name }
					break
				end
			end
		end
	end
	return out
end

---------------------------------------------------------------------
-- Calzadas y aceras
---------------------------------------------------------------------

-- Viste una pieza. Si algo falla, la deja como estaba.
local function dressPart(part: BasePart, r: Resolved, whiten: number): boolean
	local material, physics, color = part.Material, part.CustomPhysicalProperties, part.Color
	local ok = pcall(function()
		if part.Material.Name ~= r.Base then
			if not StreetLook.canUse(part.Material.Name, r.Base) then
				error("material")
			end
			-- (misma física que antes: los coches agarran igual y nada pesa distinto)
			if part.CustomPhysicalProperties == nil then
				part.CustomPhysicalProperties = PhysicalProperties.new(part.Material)
			end
			part.Material = (Enum.Material :: any)[r.Base]
		end
		part.MaterialVariant = r.Name
		part.Color = Choice.whiten(color, whiten)
	end)
	if not ok then
		pcall(function()
			part.Material = material
			part.CustomPhysicalProperties = physics
			part.MaterialVariant = ""
			part.Color = color
		end)
	end
	return ok
end

-- Repasa root. Devuelve cuántas piezas vistió por aspecto.
function StreetDress.dress(root: Instance, resolved: { [string]: Resolved }, highways: { StreetLook.Line }?): { [string]: number }
	local counts: { [string]: number } = {}
	if next(resolved) == nil then
		return counts
	end
	for i, part in root:GetDescendants() do
		pause(i, 20000)
		if part:IsA("BasePart") and StreetLook.Names[part.Name] then
			local p = part.CFrame.Position
			local key = StreetLook.classify({
				Name = part.Name,
				Material = part.Material.Name,
				Variant = part.MaterialVariant,
				Container = containerOf(part, root),
				X = p.X,
				Z = p.Z,
			}, highways)
			local r = key and resolved[key]
			if r and dressPart(part, r, StreetLook.Looks[key :: string].Whiten) then
				counts[key :: string] = (counts[key :: string] or 0) + 1
			end
		end
	end
	return counts
end

---------------------------------------------------------------------
-- Señales y alcantarillas
---------------------------------------------------------------------

-- Imágenes del pack: kind -> Decal de plantilla (sin scripts; nada de lo prohibido)
function StreetDress.templates(asset: Instance): { [string]: Decal }
	for _, item in asset:GetDescendants() do
		if item:IsA("LuaSourceContainer") then
			item:Destroy()
		end
	end
	local out: { [string]: Decal } = {}
	for _, item in asset:GetDescendants() do
		if item:IsA("Decal") then
			local kind = StreetLook.decalKind((item :: any).Texture)
			local bad = false
			local node: Instance? = item
			while node and node ~= asset do
				if StreetLook.banned(node.Name) then
					bad = true
					break
				end
				node = node.Parent
			end
			if kind and not bad and not out[kind] then
				out[kind] = item :: any
			end
		end
	end
	return out
end

local function make(class: string, props: { [string]: any }, tag: string): BasePart
	local p = Instance.new(class) :: any
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p:AddTag(tag)
	p.Parent = props.Parent
	return p
end

local function decal(template: Decal, face: Enum.NormalId, parent: Instance): Decal
	local ok, d = pcall(function()
		return template:Clone()
	end)
	local out: any = if ok and d then d else Instance.new("Decal")
	if not (ok and d) then
		out.Texture = (template :: any).Texture
	end
	out.Face = face
	out.Parent = parent
	return out
end

-- CFrame en p mirando (Front) hacia dir
local function facing(p: Vector3, dir: Vector3): CFrame
	return CFrame.new(p) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
end

local function firstPosition(model: Instance): Vector3?
	if model:IsA("BasePart") then
		return model.CFrame.Position
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			return d.CFrame.Position
		end
	end
	return nil
end

-- Lo que hay en la calle y no se puede tapar (modelos y piezas por nombre; radio en studs)
StreetDress.ObstacleModels = {
	StreetLamp = 2, TrafficLight = 3, BusStop = 6, Bench = 3, NombreCalles = 2, Arbol = 3, Tree = 3, Papelera = 1.5,
}

-- Una sola pasada por la ciudad: tapas, rejillas, pasos de cebra y obstáculos
function StreetDress.scan(root: Instance): any
	local found = { Manholes = {}, Drains = {}, Crossings = {}, Mouths = {}, Obstacles = {} }
	for i, item in root:GetDescendants() do
		pause(i, 20000)
		local name = item.Name
		if item:IsA("BasePart") then
			if (name == "Manhole" or name == "Drain") and containerOf(item, root) == "Streets" then
				table.insert(if name == "Manhole" then found.Manholes else found.Drains, { Part = item, Position = item.CFrame.Position })
			elseif item:HasTag("BusStop") then
				table.insert(found.Obstacles, { Position = item.CFrame.Position, Radius = 6 })
			elseif (string.find(name, "Door", 1, true) or string.find(name, "Puerta", 1, true) or string.find(name, "Entrance", 1, true)) and item.CFrame.Position.Y < 20 then
				table.insert(found.Obstacles, { Position = item.CFrame.Position, Radius = 5 })
			end
		elseif item:IsA("Model") then
			if name == "PasoCebra" then
				local cr = StreetDress.crossingOf(item)
				if cr then
					table.insert(found.Crossings, cr)
					if item.Parent and item.Parent.Name == "PasosBocacalle" then
						table.insert(found.Mouths, cr)
					end
				end
			else
				local r = StreetDress.ObstacleModels[name] or (if item:HasTag("LiteDetail") or item:HasTag("BusStop") then 3 else nil)
				if r then
					local p = firstPosition(item)
					if p then
						table.insert(found.Obstacles, { Position = p, Radius = r })
					end
				end
			end
		end
	end
	return found
end

-- Paso de cebra (Kit/Bocacalles.crossing): centro, por dónde se cruza, largo y ancho, de sus piezas
function StreetDress.crossingOf(model: Instance): StreetLook.Crossing?
	local stripes, ramps = {}, {}
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			if p.Name == "Zebra" then
				table.insert(stripes, p)
			elseif p.Name == "KerbRamp" then
				table.insert(ramps, p)
			end
		end
	end
	if #stripes == 0 then
		return nil
	end
	local first = stripes[1]
	local w = first.CFrame.RightVector
	w = V3(w.X, 0, w.Z).Unit
	local o = V3(first.CFrame.Position.X, 0, first.CFrame.Position.Z)
	local lo, hi = math.huge, -math.huge
	for _, s in stripes do
		local q = s.CFrame.Position
		local a = (V3(q.X, 0, q.Z) - o):Dot(w)
		lo, hi = math.min(lo, a - 1.45), math.max(hi, a + 1.45)
	end
	for _, r in ramps do
		local q = r.CFrame.Position
		local a = (V3(q.X, 0, q.Z) - o):Dot(w)
		lo, hi = math.min(lo, a - 0.8), math.max(hi, a + 0.8)
	end
	return { Center = o + w * ((lo + hi) / 2), WalkDir = w, Length = hi - lo, Depth = first.Size.Z }
end

-- Lámina con la imagen encima de una tapa o rejilla de Kit/StreetDetail
local function coverPlate(parent: Instance, part: BasePart, template: Decal, round: boolean)
	local size = if round then V3(part.Size.Y, 0.02, part.Size.Z) else V3(part.Size.X, 0.02, part.Size.Z)
	local cf = if round then CFrame.new(part.CFrame.Position) else part.CFrame
	local plate = make("Part", { Name = if round then "TapaAlcantarilla" else "RejillaImagen", Size = size, CFrame = cf + V3(0, 0.045, 0), Transparency = 1, Parent = parent }, StreetDress.DetailTag)
	decal(template, Enum.NormalId.Top, plate)
end

-- Una señal: poste (choca), respaldo metálico y la placa con la imagen del pack
function StreetDress.sign(parent: Instance, sign: StreetLook.Sign, template: Decal, walkTop: number): Model
	local m = Instance.new("Model")
	m.Name = "Senal" .. sign.Kind
	local base = V3(sign.Position.X, walkTop, sign.Position.Z)
	local top = StreetLook.SIGN_HEIGHT + StreetLook.SIGN_SIZE / 2
	local metal = Color3.fromRGB(150, 154, 160)
	local pole = make("Part", {
		Name = "SignPole",
		Shape = Enum.PartType.Cylinder,
		Size = V3(top, StreetLook.POLE, StreetLook.POLE),
		CFrame = CFrame.new(base + V3(0, top / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = metal,
		Material = Enum.Material.Metal,
		CanCollide = true,
		Parent = m,
	}, StreetDress.SignTag)
	pole:SetAttribute("Solid", true)
	local center = base + V3(0, StreetLook.SIGN_HEIGHT, 0)
	local f = sign.Facing
	local back = StreetLook.Backing[sign.Kind] or { Disc = false, Size = 2.2 }
	if back.Disc then
		make("Part", {
			Name = "SignBack",
			Shape = Enum.PartType.Cylinder,
			Size = V3(0.06, back.Size, back.Size),
			CFrame = facing(center + f * 0.17, f) * CFrame.Angles(0, math.rad(90), 0),
			Color = metal,
			Material = Enum.Material.Metal,
			Parent = m,
		}, StreetDress.SignTag)
	else
		make("Part", { Name = "SignBack", Size = V3(back.Size, back.Size, 0.06), CFrame = facing(center + f * 0.17, f), Color = metal, Material = Enum.Material.Metal, Parent = m }, StreetDress.SignTag)
	end
	local plate = make("Part", { Name = "SignFace", Size = V3(StreetLook.SIGN_SIZE, StreetLook.SIGN_SIZE, 0.04), CFrame = facing(center + f * 0.22, f), Transparency = 1, Parent = m }, StreetDress.SignTag)
	decal(template, Enum.NormalId.Front, plate)
	m.Parent = parent
	return m
end

-- ¿Qué acera hay en p? Rayo hacia abajo: "Streets"/"MainRoads" si cae en una acera; nil si no
function StreetDress.raycastProbe(root: Instance): (Vector3) -> (string?, number?)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { root }
	return function(p: Vector3): (string?, number?)
		local hit = workspace:Raycast(V3(p.X, 12, p.Z), V3(0, -20, 0), params)
		if hit and (hit.Instance.Name == "Sidewalk" or hit.Instance.Name == "RingSidewalk") and hit.Normal.Y > 0.9 then
			return containerOf(hit.Instance, root), hit.Position.Y
		end
		return nil
	end
end

-- Pone tapas y señales. probe se puede cambiar en las pruebas. Devuelve lo que ha puesto por tipo.
function StreetDress.details(root: Instance, templates: { [string]: Decal }, probe: ((Vector3) -> (string?, number?))?): { [string]: number }
	local counts: { [string]: number } = {}
	if next(templates) == nil then
		return counts
	end
	local found = StreetDress.scan(root)
	local folder = root:FindFirstChild(FOLDER) or Instance.new("Model")
	folder.Name = FOLDER
	folder.Parent = root
	-- Tapas y rejillas (encima de las de Kit/StreetDetail)
	local function safe(list: { any }): { any }
		local out = {}
		for _, item in list do
			if not StreetLook.inCrossing(item.Position, found.Crossings, 0.5) then
				table.insert(out, item)
			end
		end
		return out
	end
	for _, kind in { "Manhole", "Drain" } do
		local template = templates[kind]
		if template then
			local list = if kind == "Manhole" then found.Manholes else found.Drains
			for i, item in StreetLook.spread(safe(list), StreetLook.Caps[kind], if kind == "Manhole" then 11 else 12) do
				pause(i, 200)
				coverPlate(folder, item.Part, template, kind == "Manhole")
				counts[kind] = (counts[kind] or 0) + 1
			end
		end
	end
	-- Señales en las bocas sin semáforo
	local cells = StreetLook.grid(found.Obstacles)
	local probeFn = probe or StreetDress.raycastProbe(root)
	local function check(p: Vector3): string?
		return (probeFn(p))
	end
	local groups: { [string]: { any } } = {}
	for i, cr in found.Mouths do
		pause(i, 100)
		for _, s in StreetLook.mouthSigns(cr, check) do
			if templates[s.Kind] and StreetLook.clear(s.Position, StreetLook.near(cells, s.Position), found.Crossings, 1.2) then
				groups[s.Group] = groups[s.Group] or {}
				table.insert(groups[s.Group], s)
			end
		end
	end
	for group, list in groups do
		for i, s in StreetLook.spread(list, StreetLook.Caps[group] or 0, 13) do
			pause(i, 50)
			local _, y = probeFn(s.Position)
			StreetDress.sign(folder, s, templates[s.Kind], y or 1.0)
			counts[s.Kind] = (counts[s.Kind] or 0) + 1
		end
	end
	return counts
end

---------------------------------------------------------------------
-- Arranque (lo llama World/UserMaterials, en su hilo, antes de aclarar)
---------------------------------------------------------------------

-- library = ServerStorage.UserMaterials; loaded = lo que cargó por pack; load(id) = descarga.
-- unpack = UserMaterials.unpack. highways = World/Region.Highways (las dos calles grandes del centro).
function StreetDress.start(service: Instance, library: Instance, load: (number) -> Instance?, unpack: (Instance, string, Instance) -> any, root: Instance?, highways: { StreetLook.Line }?, probe: ((Vector3) -> (string?, number?))?)
	local town = root or workspace:FindFirstChild("Town")
	if not town then
		return
	end
	-- 1) Más variants (Realistic Packs)
	local extra = StreetLook.Packs.Variants
	local asset = load(extra.Id)
	if asset then
		local ok, err = pcall(unpack, asset, extra.Short, library)
		if not ok then
			warn("[StreetDress] " .. tostring(err))
		end
	end
	-- 2) Calzadas y aceras
	local ok, result = pcall(function()
		local resolved = StreetDress.resolve(service, library)
		return { resolved, StreetDress.dress(town, resolved, highways) }
	end)
	if ok then
		local list = {}
		for key, n in result[2] do
			table.insert(list, ("%s=%s (%d)"):format(key, result[1][key].Name, n))
		end
		table.sort(list)
		print("[StreetDress] calles: " .. (if #list > 0 then table.concat(list, ", ") else "ninguna"))
	else
		warn("[StreetDress] calles: " .. tostring(result))
	end
	-- 3) Señales y alcantarillas
	local road = StreetLook.Packs.Road
	local roadAsset = load(road.Id)
	if roadAsset then
		local ok2, counts = pcall(function()
			local templates = StreetDress.templates(roadAsset)
			return StreetDress.details(town, templates, probe)
		end)
		pcall(function()
			roadAsset:Destroy()
		end)
		if ok2 then
			local list = {}
			for kind, n in counts do
				table.insert(list, ("%s %d"):format(kind, n))
			end
			table.sort(list)
			print("[StreetDress] detalles: " .. (if #list > 0 then table.concat(list, ", ") else "ninguno"))
		else
			warn("[StreetDress] detalles: " .. tostring(counts))
		end
	end
end

return StreetDress
