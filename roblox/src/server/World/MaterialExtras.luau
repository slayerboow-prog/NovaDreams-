-- MaterialExtras: lo que queda de los packs de materiales y texturas que eligió el dueño y que NO son
-- MaterialVariant (por eso no los usan World/UserMaterials, HouseDress, InteriorDress ni StreetDress):
--
--   * Packs de texturas antiguas (`Texture` en las 6 caras de una loseta de muestra, sin PBR):
--       12433695725 Texture pack (realistic), 123159368741340 Realistic Materials Pack,
--       11877329379 Realistic Texture Pack, 3778526307 Custom Material Pack 1 y 856287704 Ultra HD
--       texture pack (2017). De cada loseta se coge su imagen y su categoría POR NOMBRE (la loseta,
--       su carpeta o su letrero): papel pintado, moqueta, techo o arena (Categories). Las demás
--       (ladrillo, teja, cristal, metal, paisaje…) no: ahí ya hay variants PBR, que se ven mejor.
--       Las imágenes de las categorías elegidas se pegan como lámina (`Texture` «U_Lamina») solo donde
--       una textura plana se ve bien (el papel pintado, la moqueta y las placas del techo son planos de
--       verdad) y solo en parte de las viviendas y locales (Share: variedad fija por sala), encima del
--       variant que ya puso World/InteriorDress. La lámina lleva la etiqueta TextureDetail
--       (shared/Graphics.DetailTags: es barata y se ve en todos los niveles gráficos, también en Bajo).
--   * La arena realista de la playa (9268236860): si su variant viene sobre Sand ya es el global de
--     shared/UserMaterialChoice (playa y terreno). Si viene sobre otro material, aquí se pone pieza a
--     pieza en la arena de la playa (pieza «Sand» de Kit/Civic, con la física de antes). Si solo trae
--     texturas, la arena de la playa lleva su lámina.
--   * Bronce PBR (12152263865): no son variants sino MeshPart con SurfaceAppearance (bronce limpio, de
--     estatua y gastado). Las placas de los cuadros del museo («Plaque») y la escultura de la plaza del
--     museo («Sculpture») llevan encima un bloque de bronce de su misma talla y giro; la pieza de antes
--     se queda (choca igual) invisible (PropShell / PropMesh: son pocas mallas y se ven en todos los
--     niveles gráficos, también en Bajo).
--
-- Siempre: fuera los scripts de los packs (algunos traen 60), fuera letreros y textos, nada con marca
-- (Banned), topes de piezas. Todo en pcall: si un pack no carga o falla, el juego sigue sin él.

local CollectionService = game:GetService("CollectionService")

local MaterialExtras = {}

MaterialExtras.TexturePacks = {
	{ Id = 12433695725, Short = "TexReal", Title = "Texture pack (realistic)" },
	{ Id = 123159368741340, Short = "TexMat", Title = "Realistic Materials Pack (losetas)" },
	{ Id = 11877329379, Short = "TexPack", Title = "Realistic Texture Pack" },
	{ Id = 3778526307, Short = "TexCustom", Title = "Custom Material Pack 1" },
	{ Id = 856287704, Short = "TexUHD", Title = "Ultra HD texture pack (2017)" },
	{ Id = 9268236860, Short = "Arena", Title = "Realistic sand texture" },
}
MaterialExtras.BronzeId = 12152263865

-- Categoría de una loseta por las palabras de sus nombres (minúsculas; la primera que encaje).
-- Avoid: palabras que la descartan (un «Carpet» de suelo de tablas, un «sand» de arenisca…).
MaterialExtras.Categories = {
	{ Key = "Papel", Words = { "wallpaper", "wall paper", "papel" } },
	{ Key = "Moqueta", Words = { "carpet", "rug", "moqueta" }, Avoid = { "wood" } },
	{ Key = "Techo", Words = { "ceiling", "interior roofing", "techo" } },
	{ Key = "Arena", Words = { "sand" }, Avoid = { "sandstone", "stone" } },
}

-- Nunca (marcas, cosas de otros juegos, sangre…): si un nombre lo lleva, la loseta no se usa
MaterialExtras.Banned = {
	"logo", "brand", "roblox", "coca", "pepsi", "nike", "adidas", "mcdonald", "starbucks", "bloxburg",
	"doors", "mimic", "scp", "blood", "gore", "swastika", "nazi", "decal",
}

-- Dónde va cada categoría: aspecto de shared/InteriorLook que ya lleva la pieza (por el nombre de la
-- copia de interior «U_In_<aspecto>_<n>»), caras, escala y qué parte de las salas la lleva.
MaterialExtras.Laminas = {
	Papel = { Looks = { "PapelPintado" }, Faces = "Wall", Studs = 6, Share = 0.5 },
	Moqueta = { Looks = { "Moqueta" }, Faces = "Top", Studs = 6, Share = 0.4 },
	Techo = { Looks = { "Placas" }, Faces = "Bottom", Studs = 8, Share = 0.35 },
}
MaterialExtras.SandStuds = 12
MaterialExtras.MaxLaminas = 6000 -- piezas con lámina como mucho (cada una, 1 o 2 Texture)
MaterialExtras.MaxBronze = 120
MaterialExtras.Batch = 4000

-- Bronce: qué pieza lleva qué bronce (palabras del nombre de la malla del pack, en orden)
MaterialExtras.BronzeTargets = {
	Plaque = { "clean", "bare", "statue" }, -- placas de los cuadros: bronce limpio, brillante
	Sculpture = { "statue", "bare", "clean" }, -- escultura: bronce de estatua (pátina)
}

---------------------------------------------------------------------
-- Cuentas puras
---------------------------------------------------------------------

local function has(text: string, words: { string }): boolean
	for _, word in words do
		if string.find(text, word, 1, true) then
			return true
		end
	end
	return false
end

function MaterialExtras.banned(names: { string }): boolean
	for _, name in names do
		if has(string.lower(name), MaterialExtras.Banned) then
			return true
		end
	end
	return false
end

-- Categoría por los nombres (de la loseta hacia fuera). nil = no se usa.
function MaterialExtras.categoryOf(names: { string }): string?
	if MaterialExtras.banned(names) then
		return nil
	end
	for _, name in names do
		local lower = string.lower(name)
		for _, cat in MaterialExtras.Categories do
			if has(lower, cat.Words) and not (cat.Avoid and has(lower, cat.Avoid)) then
				return cat.Key
			end
		end
	end
	return nil
end

-- Azar fijo (0..1) por semilla y sal
function MaterialExtras.hash(seed: string, salt: string): number
	local h = 5381
	local s = salt .. "|" .. seed
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483629
	end
	local v = math.sin(h * 0.000123 + 0.9) * 43758.5453
	return v - math.floor(v)
end

-- Categoría de lámina para una pieza vestida con este variant (nil = ninguna)
function MaterialExtras.laminaFor(variant: string): string?
	local look = string.match(variant, "^U_In_(.-)_%d+$")
	if not look then
		return nil
	end
	for key, lam in MaterialExtras.Laminas do
		if table.find(lam.Looks, look) then
			return key
		end
	end
	return nil
end

-- ¿Lleva lámina esta sala? y cuál de la lista (1..n)
function MaterialExtras.choose(key: string, seed: string, n: number): number?
	local lam = MaterialExtras.Laminas[key]
	if not lam or n < 1 or MaterialExtras.hash(seed, key) >= lam.Share then
		return nil
	end
	return math.clamp(math.floor(MaterialExtras.hash(seed, key .. "#") * n) + 1, 1, n)
end

-- Caras de una pared que dan a la sala: las dos grandes (las del eje más fino en planta)
function MaterialExtras.wallFaces(size: Vector3): { Enum.NormalId }
	if size.Z <= size.X then
		return { Enum.NormalId.Front, Enum.NormalId.Back }
	end
	return { Enum.NormalId.Left, Enum.NormalId.Right }
end

---------------------------------------------------------------------
-- Packs de texturas
---------------------------------------------------------------------

local function strip(asset: Instance)
	for _, item in asset:GetDescendants() do
		if item:IsA("LuaSourceContainer") then
			item:Destroy()
		end
	end
end

-- Nombres de la loseta hacia fuera (con el texto de sus letreros, que dicen la categoría)
local function namesOf(item: Instance, root: Instance): { string }
	local names = {}
	local node: Instance? = item
	while node and node ~= root do
		table.insert(names, node.Name)
		if node:IsA("BasePart") or node:IsA("Model") or node:IsA("Folder") then
			for _, child in node:GetChildren() do
				if child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
					for _, label in child:GetDescendants() do
						if label:IsA("TextLabel") then
							table.insert(names, (label :: any).Text)
						end
					end
				end
			end
		end
		node = node.Parent
	end
	return names
end

-- Imágenes de un pack por categoría (sin repetir). Borra el pack.
function MaterialExtras.harvest(asset: Instance): { [string]: { string } }
	strip(asset)
	local out: { [string]: { string } } = {}
	local seen: { [string]: boolean } = {}
	for _, item in asset:GetDescendants() do
		if item:IsA("Decal") then -- (Texture es un Decal)
			local okId, id = pcall(function()
				return (item :: any).Texture
			end)
			if okId and type(id) == "string" and id ~= "" and not seen[id] then
				local cat = MaterialExtras.categoryOf(namesOf(item, asset))
				if cat then
					seen[id] = true
					out[cat] = out[cat] or {}
					table.insert(out[cat], id)
				end
			end
		end
	end
	asset:Destroy()
	return out
end

---------------------------------------------------------------------
-- Láminas
---------------------------------------------------------------------

local function lamina(part: BasePart, id: string, face: Enum.NormalId, studs: number)
	local t = Instance.new("Texture")
	t.Name = "U_Lamina"
	t.Texture = id
	t.Face = face
	t.StudsPerTileU = studs
	t.StudsPerTileV = studs
	t.Parent = part
end

-- Pega la lámina de esa categoría a la pieza. Si algo falla, la deja como estaba.
function MaterialExtras.applyLamina(part: BasePart, key: string, id: string, studs: number?): boolean
	if part:GetAttribute("UserLamina") then
		return false
	end
	local lam = MaterialExtras.Laminas[key]
	local faces: { Enum.NormalId }
	if key == "Arena" then
		faces = { Enum.NormalId.Top }
	elseif not lam then
		return false
	elseif lam.Faces == "Wall" then
		faces = MaterialExtras.wallFaces(part.Size)
	else
		faces = { (Enum.NormalId :: any)[lam.Faces] }
	end
	local ok = pcall(function()
		for _, face in faces do
			lamina(part, id, face, studs or (lam and lam.Studs) or 6)
		end
		part:SetAttribute("UserLamina", id)
		CollectionService:AddTag(part, "TextureDetail")
	end)
	if not ok then
		pcall(function()
			for _, child in part:GetChildren() do
				if child:IsA("Texture") and child.Name == "U_Lamina" then
					child:Destroy()
				end
			end
			part:SetAttribute("UserLamina", nil)
		end)
	end
	return ok
end

-- Semilla de la sala o del edificio (la misma desde todas sus piezas)
local function seedOf(part: BasePart): string
	local node: Instance? = part.Parent
	while node and node ~= game do
		local key = node:GetAttribute("Key")
		if type(key) == "string" then
			return key
		end
		if string.match(node.Name, "^Interior_") then
			break
		end
		node = node.Parent
	end
	local p = part.CFrame.Position
	return ("%s@%d,%d"):format(if node then node.Name else "", math.floor(p.X / 60), math.floor(p.Z / 60))
end

-- Repasa root: láminas en las piezas que ya vistió InteriorDress. Devuelve cuántas por categoría.
MaterialExtras.used = 0
function MaterialExtras.dress(root: Instance, images: { [string]: { string } }, noYield: boolean?): { [string]: number }
	local counts: { [string]: number } = {}
	if next(images) == nil then
		return counts
	end
	local seeds: { [Instance]: string } = {}
	for i, part in root:GetDescendants() do
		if not noYield and i % MaterialExtras.Batch == 0 and task then
			task.wait()
		end
		if MaterialExtras.used >= MaterialExtras.MaxLaminas then
			break
		end
		if part:IsA("BasePart") and part.MaterialVariant ~= "" and not part:GetAttribute("UserLamina") then
			local key = MaterialExtras.laminaFor(part.MaterialVariant)
			local list = key and images[key]
			if list and #list > 0 then
				local parent = part.Parent :: Instance
				local seed = seeds[parent]
				if not seed then
					seed = seedOf(part)
					seeds[parent] = seed
				end
				local n = MaterialExtras.choose(key :: string, seed, #list)
				if n and MaterialExtras.applyLamina(part, key :: string, list[n]) then
					MaterialExtras.used += 1
					counts[key :: string] = (counts[key :: string] or 0) + 1
				end
			end
		end
	end
	return counts
end

---------------------------------------------------------------------
-- Arena de la playa
---------------------------------------------------------------------

-- Piezas de arena de la playa (Kit/Civic: «Sand», de Sand, en la calle)
local function beachParts(root: Instance): { BasePart }
	local out = {}
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "Sand" and part.Material == Enum.Material.Sand and part.CFrame.Position.Y < 2000 then
			table.insert(out, part)
		end
	end
	return out
end

-- La arena del dueño en la playa. Devuelve cuántas piezas y cómo ("variant", "lamina" o nil).
function MaterialExtras.beach(service: Instance, library: Instance, root: Instance, images: { string }?): (number, string?)
	local global = service:GetAttribute("UserOverride_Sand")
	if type(global) == "string" and string.sub(global, 1, 8) == "U_Arena_" then
		return 0, nil -- (ya es la arena de toda la ciudad y del terreno)
	end
	local parts = beachParts(root)
	if #parts == 0 then
		return 0, nil
	end
	-- Variant de la arena sobre otro material: pieza a pieza
	local folder = library:FindFirstChild("Arena")
	local variant: any = nil
	for _, item in if folder then folder:GetChildren() else {} do
		if item:IsA("MaterialVariant") then
			variant = item
			break
		end
	end
	if not variant then
		for _, item in service:GetChildren() do
			if item:IsA("MaterialVariant") and item:GetAttribute("SourcePack") == "Arena" then
				variant = item
				break
			end
		end
	end
	if variant then
		pcall(function()
			variant.Parent = service
		end)
	end
	if variant and variant.Parent == service then
		local count = 0
		for _, part in parts do
			local material, physics = part.Material, part.CustomPhysicalProperties
			local ok = pcall(function()
				if part.CustomPhysicalProperties == nil then
					part.CustomPhysicalProperties = PhysicalProperties.new(part.Material) -- (se pisa igual)
				end
				part.Material = variant.BaseMaterial
				part.MaterialVariant = variant.Name
			end)
			if ok then
				count += 1
			else
				pcall(function()
					part.Material = material
					part.CustomPhysicalProperties = physics
					part.MaterialVariant = ""
				end)
			end
		end
		return count, "variant"
	end
	-- Solo textura: lámina encima
	if images and #images > 0 then
		local count = 0
		for _, part in parts do
			if MaterialExtras.applyLamina(part, "Arena", images[1], MaterialExtras.SandStuds) then
				count += 1
			end
		end
		return count, "lamina"
	end
	return 0, nil
end

---------------------------------------------------------------------
-- Bronce
---------------------------------------------------------------------

-- Mallas de bronce del pack: nombre (minúsculas, con su carpeta) -> MeshPart. Prefiere los bloques.
function MaterialExtras.bronzeTemplates(asset: Instance): { { Key: string, Part: MeshPart } }
	strip(asset)
	local out = {}
	for _, item in asset:GetDescendants() do
		if item:IsA("MeshPart") and item:FindFirstChildWhichIsA("SurfaceAppearance") then
			local names = {}
			local node: Instance? = item
			while node and node ~= asset do
				table.insert(names, string.lower(node.Name))
				node = node.Parent
			end
			if not MaterialExtras.banned(names) then
				table.insert(out, { Key = table.concat(names, "/"), Part = item })
			end
		end
	end
	-- (los bloques antes que las esferas: las piezas que se cubren son cajas)
	table.sort(out, function(a, b)
		local ab, bb = string.find(a.Key, "sphere", 1, true) == nil, string.find(b.Key, "sphere", 1, true) == nil
		if ab ~= bb then
			return ab
		end
		return a.Key < b.Key
	end)
	for _, t in out do
		pcall(function()
			t.Part.Parent = nil
		end)
	end
	asset:Destroy()
	return out
end

function MaterialExtras.pickBronze(templates: { { Key: string, Part: MeshPart } }, target: string): MeshPart?
	local prefs = MaterialExtras.BronzeTargets[target]
	if not prefs or #templates == 0 then
		return nil
	end
	for _, word in prefs do
		for _, t in templates do
			if string.find(t.Key, word, 1, true) and not string.find(t.Key, "sphere", 1, true) then
				return t.Part
			end
		end
	end
	return templates[1].Part
end

MaterialExtras.bronzed = 0
-- Cubre de bronce una pieza (bloque de su talla y giro). La de antes se queda, invisible, para chocar.
function MaterialExtras.bronze(part: BasePart, template: MeshPart): boolean
	if part:GetAttribute("UserBronze") or MaterialExtras.bronzed >= MaterialExtras.MaxBronze then
		return false
	end
	local okClone, mesh = pcall(function()
		local m = template:Clone()
		for _, item in m:GetDescendants() do
			if item:IsA("LuaSourceContainer") then
				item:Destroy()
			end
		end
		m.Name = "Bronce"
		m.Anchored = true
		m.CanCollide = false
		m.CanQuery = false
		m.CanTouch = false
		m.Size = part.Size
		m.CFrame = part.CFrame
		m.Parent = part.Parent
		return m
	end)
	if not okClone or not mesh then
		return false
	end
	pcall(function()
		CollectionService:AddTag(mesh, "PropMesh") -- (barato: se ve en todos los niveles gráficos)
		CollectionService:AddTag(part, "PropShell") -- (la de antes, invisible en todos)
		part:SetAttribute("UserBronze", true)
		part.Transparency = 1
	end)
	MaterialExtras.bronzed += 1
	return true
end

function MaterialExtras.dressBronze(root: Instance, templates: { { Key: string, Part: MeshPart } }): number
	if #templates == 0 then
		return 0
	end
	local count = 0
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") and MaterialExtras.BronzeTargets[part.Name] and part.Transparency < 0.95 then
			local template = MaterialExtras.pickBronze(templates, part.Name)
			if template and MaterialExtras.bronze(part, template) then
				count += 1
			end
		end
	end
	return count
end

---------------------------------------------------------------------
-- Arranque (lo llama World/UserMaterials, en su hilo, después de InteriorDress)
---------------------------------------------------------------------

function MaterialExtras.start(service: Instance, library: Instance, load: ((number) -> Instance?)?, onBuilt: ((((any) -> ())) -> ())?, roots: { Instance }?)
	if not load then
		return nil
	end
	-- Imágenes de los packs de texturas
	local images: { [string]: { string } } = {}
	local packs = 0
	for _, pack in MaterialExtras.TexturePacks do
		local okLoad, asset = pcall(load, pack.Id)
		if okLoad and asset then
			local ok, found = pcall(MaterialExtras.harvest, asset)
			if ok then
				packs += 1
				for cat, list in found do
					images[cat] = images[cat] or {}
					for _, id in list do
						if not table.find(images[cat], id) then
							table.insert(images[cat], id)
						end
					end
				end
			else
				warn(("[MaterialExtras] %s: %s"):format(pack.Short, tostring(found)))
			end
		else
			warn(("[MaterialExtras] no carga %s (%d)"):format(pack.Title, pack.Id))
		end
	end
	-- Bronce
	local templates = {}
	do
		local okLoad, asset = pcall(load, MaterialExtras.BronzeId)
		if okLoad and asset then
			local ok, found = pcall(MaterialExtras.bronzeTemplates, asset)
			if ok then
				templates = found
			end
		else
			warn("[MaterialExtras] no carga el bronce PBR")
		end
	end
	local where = roots
	if not where then
		where = {}
		for _, name in { "Town", "Interiores" } do
			local folder = workspace:FindFirstChild(name)
			if folder then
				table.insert(where, folder)
			end
		end
	end
	local total: { [string]: number } = {}
	local beachCount, beachHow, bronzeCount = 0, nil, 0
	for _, root in where :: { Instance } do
		local ok, counts = pcall(MaterialExtras.dress, root, images)
		if ok then
			for k, n in counts do
				total[k] = (total[k] or 0) + n
			end
		else
			warn("[MaterialExtras] " .. tostring(counts))
		end
		local okBeach, n, how = pcall(MaterialExtras.beach, service, library, root, images.Arena)
		if okBeach and n > 0 then
			beachCount += n
			beachHow = how
		end
		local okBronze, b = pcall(MaterialExtras.dressBronze, root, templates)
		if okBronze then
			bronzeCount += b
		end
	end
	local list = {}
	for cat, ids in images do
		table.insert(list, ("%s %d img/%d piezas"):format(cat, #ids, total[cat] or 0))
	end
	table.sort(list)
	print(("[MaterialExtras] %d/%d packs de texturas: %s; arena de playa %d (%s); bronce %d (%d mallas)"):format(packs, #MaterialExtras.TexturePacks, if #list > 0 then table.concat(list, ", ") else "nada", beachCount, beachHow or "-", bronzeCount, #templates))
	-- Salas que se monten luego (después de InteriorDress, que se enganchó antes)
	local hook = onBuilt
	if not hook then
		local services = script and script.Parent and script.Parent.Parent and script.Parent.Parent:FindFirstChild("Services")
		local module = services and services:FindFirstChild("InteriorService")
		if module then
			local okReq, InteriorService = pcall(require, module :: any)
			if okReq and type(InteriorService) == "table" and type(InteriorService.onBuilt) == "function" then
				hook = InteriorService.onBuilt
			end
		end
	end
	if hook and (next(images) ~= nil or #templates > 0) then
		pcall(hook, function(inst: any)
			local model = inst and inst.Room and inst.Room.Model
			if model and model.Parent then
				pcall(MaterialExtras.dress, model, images, true)
				pcall(MaterialExtras.dressBronze, model, templates)
			end
		end)
	end
	return { Images = images, Templates = templates, Laminas = total, Beach = beachCount, Bronze = bronzeCount }
end

return MaterialExtras
