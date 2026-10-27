-- EstiloBloqueLoader: el estilo bloque «premium» del reparto (encargo del dueño, referencias en
-- docs/personajes/referencia/; documentación docs/personajes/estilo-bloque/README.md).
--
-- El actor sigue siendo el R15 de bloques de siempre (Humanoid, articulaciones, nombre, bocadillos,
-- interacciones, marcas y gestos de StageDirector y ActorLife, AgeMotion, Cinemateca…). Encima:
--   * ACCESORIOS propios (shared/EstiloBloque: una MeshPart por accesorio, hechos en Blender con
--     scripts/personajes/bloque_blender.py y subidos con scripts/upload-estilo-bloque.sh): cada uno
--     soldado a SU parte del R15 en su sitio (Offset desde el centro de la parte), como un sombrero de
--     Roblox: pelo y gafas en la cabeza, bata en el tronco, faldón en las piernas, botas en los pies…
--     Los de luz (Glow) en Neon. Los grandes llevan su versión lejana (…LOD, invisible; la pone de lejos
--     Controllers/EstiloBloqueLOD).
--   * La ROPA con textura (Shirt/Pants de sus plantillas); la que tenía (CastLook) se guarda en una
--     carpeta y vuelve al quitarlo.
--   * La CARA dibujada: la cabeza que se ve es el accesorio CabezaBloque (o la pantalla de Pip); la Head
--     del R15 queda invisible. Las caras de cada expresión van en atributos (CaraBloque_<expresión>) y
--     shared/FaceKit pone la que toca en el ÚNICO Decal «face» de esa pieza (una sola boca).
-- Sin ids, si falta un accesorio, si la moderación retiró alguna malla (World/MallasRetiradas) o si no
-- hay cara subida, ese personaje sigue con CastLook (nunca a medias).
--
--   EstiloBloqueLoader.keyFor(look) -> string?          la clave (Cosme, Familia_Mama, Abu_Rosa…)
--   EstiloBloqueLoader.prepare(ids, download, data, verify?) -> ({ [clave]: Folder }, { [clave]: string })
--   EstiloBloqueLoader.start() / template(clave) / _set(map) / _setData(d)
--   EstiloBloqueLoader.mount(model, clave) -> boolean   /  unmount(model)  /  request(model, clave)

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Retiradas = require(script.Parent.MallasRetiradas)

local EstiloBloqueLoader = {}

EstiloBloqueLoader.TAG = "EstiloBloque"
EstiloBloqueLoader.FOLDER = "EstiloBloque"
EstiloBloqueLoader.SAVED = "EstiloBloqueGuardado"
EstiloBloqueLoader.ATTR_KEY = "EstiloBloque"
EstiloBloqueLoader.Status = "sin empezar"

local templates: { [string]: Folder } = {}
local images: { [string]: { [string]: string } } = {} -- clave -> { Shirt, Pants, Cara_<e> } (ids de imagen)

local function Shared(): any
	return ReplicatedStorage:FindFirstChild("Shared")
end

local dataCache: any = nil
local function data(): any
	if dataCache == nil then
		local ok, m = pcall(function()
			return require(Shared().EstiloBloque)
		end)
		dataCache = if ok and type(m) == "table" then m else false
	end
	return dataCache or nil
end

function EstiloBloqueLoader._setData(d: any)
	dataCache = d
end

function EstiloBloqueLoader.hasIds(ids: any): boolean
	if type(ids) ~= "table" or type(ids.Modelos) ~= "table" then
		return false
	end
	for _, v in ids.Modelos do
		if Retiradas.idOf(v) then
			return true
		end
	end
	return false
end

function EstiloBloqueLoader.keyFor(look: { [string]: any }?): string?
	if type(look) ~= "table" then
		return nil
	end
	local d = data()
	if not d or type(d.Models) ~= "table" then
		return nil
	end
	local key: string? = nil
	if look.Costume == "Cosme" then
		key = "Cosme"
	elseif type(look.Id) == "string" then
		local ok, spec = pcall(function()
			return require(Shared().LifeStory.CastLook).spec(look.Id, look.Variant)
		end)
		key = if ok and spec then spec.Key else look.Id
	end
	return if key and d.Models[key] then key else nil
end

local function findPart(inst: Instance?, name: string): MeshPart?
	if not inst then
		return nil
	end
	if inst:IsA("MeshPart") and inst.Name == name then
		return inst
	end
	local found = inst:FindFirstChild(name, true)
	return if found and found:IsA("MeshPart") then found else nil
end

local function dress(part: MeshPart, spec: any, model: any, textures: { [string]: string })
	pcall(function()
		(part :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = (spec.Tris or 0) > 60 and not spec.Glow
	if spec.Glow then
		for _, d in part:GetChildren() do
			if d:IsA("SurfaceAppearance") then
				d:Destroy()
			end
		end
		part.Material = Enum.Material.Neon
		part.Color = spec.Glow
		return
	end
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.new(1, 1, 1)
	if part:FindFirstChildOfClass("SurfaceAppearance") then
		return
	end
	local t = model.Textures or {}
	local color = textures[t.Color or ""]
	if not color then
		return
	end
	local ok = pcall(function()
		local sa = Instance.new("SurfaceAppearance")
		sa.ColorMap = color
		if textures[t.Normal or ""] then
			sa.NormalMap = textures[t.Normal]
		end
		if textures[t.Roughness or ""] then
			sa.RoughnessMap = textures[t.Roughness]
		end
		sa.Parent = part
	end)
	if not ok then
		for _, d in part:GetChildren() do
			if d:IsA("SurfaceAppearance") then
				d:Destroy()
			end
		end
		pcall(function()
			(part :: any).TextureID = color
		end)
	end
end

-- Plantillas: { [clave] = Folder con una MeshPart por accesorio (y sus LOD) } y por qué falló cada una
function EstiloBloqueLoader.prepare(ids: any, download: (number) -> Instance?, d: any, verify: any?): ({ [string]: Folder }, { [string]: string })
	local out: { [string]: Folder } = {}
	local why: { [string]: string } = {}
	table.clear(images)
	if not EstiloBloqueLoader.hasIds(ids) then
		return out, { ["*"] = "sin ids (scripts/upload-estilo-bloque.sh no se ha lanzado todavía)" }
	end
	local textures = ids.Texturas or {}
	type Found = { Source: Instance, Parts: { [string]: MeshPart }, Model: any }
	local found: { [string]: Found } = {}
	local all: { Instance } = {}
	for key, model in (d and d.Models) or {} do
		local id = Retiradas.idOf(ids.Modelos[model.Asset or ""])
		if not id then
			why[key] = "sin id"
			continue
		end
		-- la cara por defecto tiene que estar subida (si no, no hay cara: sigue CastLook)
		local first = model.Faces and (model.Faces.Neutral or model.Faces.Grin)
		if not first or not textures[first] then
			why[key] = "sin la cara subida"
			continue
		end
		local ok, src = pcall(download, id)
		if not ok or typeof(src) ~= "Instance" then
			why[key] = "no se pudo cargar el Model " .. tostring(id)
			continue
		end
		local parts: { [string]: MeshPart } = {}
		for _, a in model.Accessories do
			for _, name in { a.Name, a.Lod } do
				if name then
					local mp = findPart(src, name)
					if mp then
						parts[name] = mp
						table.insert(all, mp)
					end
				end
			end
		end
		found[key] = { Source = src, Parts = parts, Model = model }
	end
	local bad: { [number]: boolean } = {}
	local okV, res = pcall(function()
		if verify then
			return verify(all)
		end
		return Retiradas.bad(all)
	end)
	if okV and type(res) == "table" then
		bad = res
	end
	for key, f in found do
		local missing = {}
		local folder = Instance.new("Folder")
		folder.Name = EstiloBloqueLoader.FOLDER
		for _, a in f.Model.Accessories do
			local mp = f.Parts[a.Name]
			local mid = if mp then Retiradas.meshIdOf(mp) else nil
			if not mp or (mid and bad[mid]) then
				table.insert(missing, a.Name)
				continue
			end
			local c = mp:Clone()
			c.Name = a.Name
			for _, ch in c:GetChildren() do
				if not ch:IsA("SurfaceAppearance") then
					ch:Destroy()
				end
			end
			dress(c, a, f.Model, textures)
			c.Parent = folder
			local lp = a.Lod and f.Parts[a.Lod]
			local lid = if lp then Retiradas.meshIdOf(lp) else nil
			if lp and not (lid and bad[lid]) then
				local l = lp:Clone()
				l.Name = a.Lod
				for _, ch in l:GetChildren() do
					if not ch:IsA("SurfaceAppearance") then
						ch:Destroy()
					end
				end
				dress(l, a, f.Model, textures)
				l:SetAttribute("LodDe", a.Name)
				l.Parent = folder
			end
		end
		if #missing > 0 then
			folder:Destroy()
			why[key] = "faltan o están retirados: " .. table.concat(missing, ", ")
			continue
		end
		local img = {}
		img.Shirt = textures[f.Model.Shirt or ""]
		img.Pants = textures[f.Model.Pants or ""]
		for e, name in f.Model.Faces or {} do
			if textures[name] then
				img["Cara_" .. e] = textures[name]
			end
		end
		images[key] = img
		folder:SetAttribute("Clave", key)
		out[key] = folder
	end
	return out, why
end

function EstiloBloqueLoader.template(key: string): Folder?
	return templates[key]
end

function EstiloBloqueLoader._set(map: { [string]: Folder }?, imgs: { [string]: { [string]: string } }?)
	templates = map or {}
	if imgs then
		images = imgs
	end
end

local HIDE = "EBOculto"

local function hide(inst: Instance)
	if inst:GetAttribute(HIDE) ~= nil then
		return
	end
	if inst:IsA("BasePart") or inst:IsA("Decal") then
		inst:SetAttribute(HIDE, (inst :: any).Transparency)
		;(inst :: any).Transparency = 1
	elseif inst:IsA("SurfaceGui") then
		inst:SetAttribute(HIDE, if inst.Enabled then 1 else 0)
		inst.Enabled = false
	end
end

local function show(inst: Instance)
	local v = inst:GetAttribute(HIDE)
	if v == nil then
		return
	end
	inst:SetAttribute(HIDE, nil)
	if inst:IsA("BasePart") or inst:IsA("Decal") then
		(inst :: any).Transparency = v
	elseif inst:IsA("SurfaceGui") then
		inst.Enabled = v == 1
	end
end

-- ¿Es ropa o pelo de piezas del aspecto de antes (Npc.dress, CosmeLook)? Se esconde: lo sustituyen los
-- accesorios. Las partes del R15 (salvo la cabeza) y lo que coge en la mano siguen.
local R15 = {
	HumanoidRootPart = true, LowerTorso = true, UpperTorso = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
}
local function oldPiece(inst: Instance, model: Model): boolean
	if not inst:IsA("BasePart") then
		return false
	end
	if CollectionService:HasTag(inst, "BodyPiece") then
		return true
	end
	local p = inst.Parent
	while p and p ~= model do
		if p.Name == "CosmeLook" or p:IsA("Accessory") then
			return true
		end
		p = p.Parent
	end
	return false
end

local watchers: { [Model]: RBXScriptConnection } = setmetatable({}, { __mode = "k" }) :: any

function EstiloBloqueLoader.mounted(model: Model): boolean
	return model:FindFirstChild(EstiloBloqueLoader.FOLDER) ~= nil
end

function EstiloBloqueLoader.mount(model: Model, key: string?): boolean
	if not key or not model then
		return false
	end
	local tpl = templates[key]
	local d = data()
	local spec = d and d.Models and d.Models[key]
	local img = images[key]
	if not tpl or not spec or not img then
		return false
	end
	if EstiloBloqueLoader.mounted(model) then
		return true
	end
	local head = model:FindFirstChild("Head")
	if not model:FindFirstChildOfClass("Humanoid") or not head or not head:IsA("BasePart") then
		return false
	end
	local scale = 1
	pcall(function()
		scale = model:GetScale()
	end)
	if math.abs(scale - 1) > 1e-3 then
		pcall(function()
			model:ScaleTo(1)
		end)
	end
	local ok, err = pcall(function()
		local folder = tpl:Clone()
		folder.Name = EstiloBloqueLoader.FOLDER
		-- lo de antes que se esconde: la Head (la cara va en la cabeza de bloque), sus caras, y el pelo y
		-- la ropa de piezas
		hide(head)
		for _, ch in head:GetDescendants() do
			hide(ch)
		end
		for _, inst in model:GetDescendants() do
			if oldPiece(inst, model) then
				hide(inst)
				for _, ch in inst:GetDescendants() do
					hide(ch)
				end
			end
		end
		-- los accesorios, cada uno soldado a su parte
		local byName = {}
		for _, a in spec.Accessories do
			byName[a.Name] = a
		end
		for _, mp in folder:GetChildren() do
			if not mp:IsA("BasePart") then
				continue
			end
			local base = mp:GetAttribute("LodDe")
			local a = byName[if type(base) == "string" then base else mp.Name]
			local part = a and model:FindFirstChild(a.Part)
			if not a or not part or not part:IsA("BasePart") then
				mp:Destroy()
				continue
			end
			mp.CFrame = part.CFrame * CFrame.new(a.Offset)
			local w = Instance.new("WeldConstraint")
			w.Part0 = part
			w.Part1 = mp
			w.Parent = mp
			if type(base) == "string" then
				mp.Transparency = 1 -- (la versión lejana: la enseña el cliente de lejos)
			end
		end
		folder.Parent = model
		-- ropa: la de antes, guardada; la nueva, si está subida
		local saved = model:FindFirstChild(EstiloBloqueLoader.SAVED) or Instance.new("Folder")
		saved.Name = EstiloBloqueLoader.SAVED
		saved.Parent = model
		for _, c in model:GetChildren() do
			if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") then
				c.Parent = saved
			end
		end
		if img.Shirt then
			local s = Instance.new("Shirt")
			s.Name = "BloqueCamisa"
			s.ShirtTemplate = img.Shirt
			s.Parent = model
		end
		if img.Pants then
			local p = Instance.new("Pants")
			p.Name = "BloquePantalon"
			p.PantsTemplate = img.Pants
			p.Parent = model
		end
		for _, n in { "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm" } do
			local p = model:FindFirstChild(n)
			if p and p:IsA("BasePart") then
				p.Color = spec.Skin
			end
		end
		-- la cara: en la cabeza de bloque, la de cada expresión en atributos
		for e in spec.Faces or {} do
			model:SetAttribute("CaraBloque_" .. e, img["Cara_" .. e])
		end
		local first = spec.Faces and (if spec.Faces.Neutral then "Neutral" else "Grin")
		model:SetAttribute("CaraBloque_Defecto", first and img["Cara_" .. first])
		model:SetAttribute("CaraEn", spec.FaceOn or "CabezaBloque")
		model:SetAttribute(EstiloBloqueLoader.ATTR_KEY, key)
		local FaceKit = require(Shared().FaceKit)
		local current = model:GetAttribute("CosmeFace") or model:GetAttribute("CastFace")
		FaceKit.expressBlock(model, if type(current) == "string" then current else first)
		pcall(function()
			CollectionService:AddTag(model, EstiloBloqueLoader.TAG)
		end)
		-- lo que se pegue luego a la cabeza o como pieza del aspecto viejo tampoco se ve
		pcall(function()
			watchers[model] = model.DescendantAdded:Connect(function(x)
				if x:IsDescendantOf(folder) then
					return
				end
				if x:IsDescendantOf(head) or oldPiece(x, model) then
					hide(x)
				end
			end)
		end)
	end)
	if math.abs(scale - 1) > 1e-3 then
		pcall(function()
			model:ScaleTo(scale)
		end)
	end
	if not ok then
		warn("[EstiloBloque] " .. tostring(err))
		EstiloBloqueLoader.unmount(model)
		return false
	end
	return true
end

function EstiloBloqueLoader.unmount(model: Model)
	local f = model:FindFirstChild(EstiloBloqueLoader.FOLDER)
	if f then
		f:Destroy()
	end
	if watchers[model] then
		watchers[model]:Disconnect()
		watchers[model] = nil
	end
	for _, n in { "BloqueCamisa", "BloquePantalon" } do
		local c = model:FindFirstChild(n)
		if c then
			c:Destroy()
		end
	end
	local saved = model:FindFirstChild(EstiloBloqueLoader.SAVED)
	if saved then
		for _, c in saved:GetChildren() do
			c.Parent = model
		end
		saved:Destroy()
	end
	for _, dsc in model:GetDescendants() do
		show(dsc)
	end
	for _, a in { "CaraEn", "CaraBloque_Defecto", EstiloBloqueLoader.ATTR_KEY } do
		model:SetAttribute(a, nil)
	end
	for name in model:GetAttributes() do
		if string.sub(name, 1, 11) == "CaraBloque_" then
			model:SetAttribute(name, nil)
		end
	end
	pcall(function()
		CollectionService:RemoveTag(model, EstiloBloqueLoader.TAG)
	end)
end

local pending: { [Model]: string } = setmetatable({}, { __mode = "k" }) :: any

-- Montar ya o, si las plantillas aún se están cargando, en cuanto acaben
function EstiloBloqueLoader.request(model: Model, key: string?): boolean
	if not key then
		return false
	end
	if EstiloBloqueLoader.mount(model, key) then
		return true
	end
	if EstiloBloqueLoader.Status == "cargando" or EstiloBloqueLoader.Status == "sin empezar" then
		pending[model] = key
	end
	return false
end

function EstiloBloqueLoader.start(): number
	local okCfg, enabled = pcall(function()
		return require(Shared().Config).EstiloBloque
	end)
	if okCfg and enabled == false then
		EstiloBloqueLoader.Status = "apagado (Config.EstiloBloque)"
		return 0
	end
	EstiloBloqueLoader.Status = "cargando"
	local ok, result = pcall(function()
		local S = Shared()
		local ids = require(S.EstiloBloqueAssetIds)
		if not EstiloBloqueLoader.hasIds(ids) then
			return 0
		end
		local Images = require(S.Images)
		if ids.Texturas then
			pcall(Images.resolve, ids.Texturas)
			ids = { Modelos = ids.Modelos, Texturas = Images.map(ids.Texturas) }
		end
		local AssetLoader = require(script.Parent.AssetLoader)
		local create = Retiradas.realCreate(5)
		local map, why = EstiloBloqueLoader.prepare(ids, AssetLoader.download, data(), function(all)
			return Retiradas.bad(all, create)
		end)
		local holder = Instance.new("Folder")
		holder.Name = "EstiloBloque"
		local n = 0
		for key, f in map do
			local c = f
			c.Name = key
			c.Parent = holder
			n += 1
		end
		holder.Parent = game:GetService("ServerStorage")
		templates = map
		local list = {}
		for key, reason in why do
			if #list < 6 then
				table.insert(list, key .. " (" .. tostring(reason) .. ")")
			end
		end
		if #list > 0 then
			warn("[EstiloBloque] siguen con CastLook: " .. table.concat(list, ", "))
		end
		return n
	end)
	local n = if ok then result else 0
	EstiloBloqueLoader.Status = if ok then (if n > 0 then ("bloque: %d personajes"):format(n) else "CastLook: sin ids") else ("CastLook: " .. tostring(result))
	if not ok then
		warn("[EstiloBloque] " .. tostring(result))
	end
	for model, key in pending do
		if model.Parent then
			pcall(EstiloBloqueLoader.mount, model, key)
		end
	end
	table.clear(pending)
	pcall(function()
		workspace:SetAttribute("EstiloBloque", EstiloBloqueLoader.Status)
	end)
	return n
end

return EstiloBloqueLoader
