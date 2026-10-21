-- CharacterMeshLoader: monta los personajes 3D propios (una malla con esqueleto R15 por personaje, hecha
-- con scripts/personajes/personajes3d_blender.py y subida con scripts/upload-personajes3d.sh:
-- shared/Personajes3DAssetIds, datos en shared/Personajes3DMallas) sobre los actores de la historia.
-- Documentación: docs/personajes/3d/README.md.
--
-- Como World/AlienMeshLoader:
--   * En el SERVIDOR, al arrancar, en un hilo aparte: descarga cada Model (World/AssetLoader.download),
--     busca sus MeshPart Cuerpo y CuerpoLOD y comprueba que no usen una malla retirada por la moderación
--     (World/MallasRetiradas; en el servidor, también que carguen de verdad). Si falta algo, ESE personaje
--     sigue como estaba (CastLook: bloques con textura). Nunca lanza error.
--   * Texturas: SurfaceAppearance (color, normal, rugosidad) si se puede; si no, MeshPart.TextureID.
--
-- Montar (CharacterMeshLoader.mount, lo llama Npc.dress después de CastLook / CosmeLook):
--   * El actor sigue siendo el mismo R15: Humanoid, HumanoidRootPart, cabeza (nombre encima, bocadillos,
--     interacciones), articulaciones (andar, gestos de StageDirector y ActorLife, AgeMotion, SeaMotion…).
--     Sus piezas y la ropa de piezas se vuelven invisibles y encima va la malla («Personaje3D»: Cuerpo y
--     CuerpoLOD soldadas a la raíz). Cada Bone guarda a qué pieza sigue (atributo Sigue) y dónde está
--     respecto a ella en reposo (Desfase): el cliente (Controllers/Personaje3DAnim) pone cada hueso donde
--     está su pieza en cada fotograma, así todo lo que mueve las piezas mueve la malla.
--   * La cara: huesos Face* (FaceJaw, FaceMouthL/R, FaceBrowL/R, FaceLidL/R). shared/FaceKit (atributo
--     Cara3D) ya no pone Decal: guarda la expresión (Cara3DExpresion) y el cliente mueve esos huesos.
--     Una sola boca: la de la malla.
--   * Sin plantilla (sin ids, malla retirada, no cargó) devuelve false y el actor queda con CastLook.
--
--   CharacterMeshLoader.keyFor(look) -> string?       la clave del personaje (Cosme, Familia_Mama…)
--   CharacterMeshLoader.prepare(ids, download, mallas, verify?) -> ({ [clave]: Folder }, { [clave]: string })
--   CharacterMeshLoader.start() -> number              cuántos personajes 3D se han cargado
--   CharacterMeshLoader.template(clave) / _set(map)    (pruebas)
--   CharacterMeshLoader.restFrames(model) -> { [pieza]: CFrame }   las piezas en reposo (por las uniones)
--   CharacterMeshLoader.mount(model, clave) -> boolean
--   CharacterMeshLoader.unmount(model)                 vuelve a CastLook (lo de piezas visible otra vez)

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Retiradas = require(script.Parent.MallasRetiradas)

local CharacterMeshLoader = {}

CharacterMeshLoader.TAG = "Personaje3D"
CharacterMeshLoader.FOLDER = "Personaje3D"
CharacterMeshLoader.ATTR_KEY = "Personaje3D"
CharacterMeshLoader.PARTS = { "Cuerpo", "CuerpoLOD" }
CharacterMeshLoader.Status = "sin empezar"
CharacterMeshLoader.SOLE = 3.07 -- (R15 de bloques: de la raíz a la planta del pie, en reposo)

-- La unión de cada pieza del R15 con su pieza de dentro (para la postura de reposo)
CharacterMeshLoader.JOINTS = {
	LowerTorso = { "Root", "HumanoidRootPart" },
	UpperTorso = { "Waist", "LowerTorso" },
	Head = { "Neck", "UpperTorso" },
	RightUpperArm = { "RightShoulder", "UpperTorso" },
	RightLowerArm = { "RightElbow", "RightUpperArm" },
	RightHand = { "RightWrist", "RightLowerArm" },
	LeftUpperArm = { "LeftShoulder", "UpperTorso" },
	LeftLowerArm = { "LeftElbow", "LeftUpperArm" },
	LeftHand = { "LeftWrist", "LeftLowerArm" },
	RightUpperLeg = { "RightHip", "LowerTorso" },
	RightLowerLeg = { "RightKnee", "RightUpperLeg" },
	RightFoot = { "RightAnkle", "RightLowerLeg" },
	LeftUpperLeg = { "LeftHip", "LowerTorso" },
	LeftLowerLeg = { "LeftKnee", "LeftUpperLeg" },
	LeftFoot = { "LeftAnkle", "LeftLowerLeg" },
}
CharacterMeshLoader.ORDER = {
	"LowerTorso", "UpperTorso", "Head", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm",
	"LeftHand", "RightUpperLeg", "RightLowerLeg", "RightFoot", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
}

local templates: { [string]: Folder } = {}

local function Shared(): any
	return ReplicatedStorage:FindFirstChild("Shared")
end

local mallasCache: any = nil
local function mallas(): any
	if mallasCache == nil then
		local ok, m = pcall(function()
			return require(Shared().Personajes3DMallas)
		end)
		mallasCache = if ok and type(m) == "table" then m else false
	end
	return mallasCache or nil
end

-- (pruebas) otros datos de las mallas
function CharacterMeshLoader._setMallas(m: any)
	mallasCache = m
end

local function idOf(value: any): number?
	return Retiradas.idOf(value)
end

function CharacterMeshLoader.hasIds(ids: any): boolean
	if type(ids) ~= "table" or type(ids.Modelos) ~= "table" then
		return false
	end
	for _, v in ids.Modelos do
		if idOf(v) then
			return true
		end
	end
	return false
end

-- La clave del personaje 3D para un aspecto de Npc.dress (nil si no tiene modelo 3D)
function CharacterMeshLoader.keyFor(look: { [string]: any }?): string?
	if type(look) ~= "table" then
		return nil
	end
	local m = mallas()
	if not m or type(m.Models) ~= "table" then
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
	return if key and m.Models[key] then key else nil
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

-- Los Bone del FBX: Roblox los deja en alguna pieza del Model; aquí van dentro de cada MeshPart
-- (Cuerpo y CuerpoLOD), en su sitio respecto a ella.
local function adoptBones(dst: BasePart, srcPart: BasePart, source: Instance?)
	if dst:FindFirstChildWhichIsA("Bone", true) or not source then
		return
	end
	for _, b in source:GetDescendants() do
		if b:IsA("Bone") and not (b.Parent and b.Parent:IsA("Bone")) then
			local holder = b.Parent
			local world = if holder and holder:IsA("BasePart") then holder.CFrame * b.CFrame else b.CFrame
			local c = b:Clone()
			c.CFrame = srcPart.CFrame:ToObjectSpace(world)
			c.Parent = dst
		end
	end
end

local function dress(part: MeshPart, textures: { [string]: string }, model: any)
	pcall(function()
		(part :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.new(1, 1, 1)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
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

-- Prepara las plantillas: { [clave] = Folder con Cuerpo y CuerpoLOD } y por qué falló cada una.
-- download(id) -> Instance? (AssetLoader.download; un doble en las pruebas). verify(parts) -> { [id]: true }
-- (opcional): las mallas que no valen (MallasRetiradas). Sin verify, la lista de retiradas.
function CharacterMeshLoader.prepare(ids: any, download: (number) -> Instance?, data: any, verify: any?): ({ [string]: Folder }, { [string]: string })
	local out: { [string]: Folder } = {}
	local why: { [string]: string } = {}
	if not CharacterMeshLoader.hasIds(ids) then
		return out, { ["*"] = "sin ids (scripts/upload-personajes3d.sh no se ha lanzado todavía)" }
	end
	local textures = ids.Texturas or {}
	local found: { [string]: { Source: Instance, Parts: { [string]: MeshPart }, Model: any } } = {}
	local all: { Instance } = {}
	for key, model in (data and data.Models) or {} do
		local id = idOf(ids.Modelos[model.Asset or ""])
		if not id then
			why[key] = "sin id"
			continue
		end
		local ok, src = pcall(download, id)
		if not ok or typeof(src) ~= "Instance" then
			why[key] = "no se pudo cargar el Model " .. tostring(id)
			continue
		end
		local parts: { [string]: MeshPart } = {}
		for _, name in CharacterMeshLoader.PARTS do
			local mp = findPart(src, name)
			if mp then
				parts[name] = mp
				table.insert(all, mp)
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
		local body = f.Parts.Cuerpo
		local bodyId = if body then Retiradas.meshIdOf(body) else nil
		if not body then
			why[key] = "falta la malla Cuerpo"
			continue
		end
		if bodyId and bad[bodyId] then
			why[key] = "malla retirada o que no carga (" .. tostring(bodyId) .. ")"
			continue
		end
		local folder = Instance.new("Folder")
		folder.Name = CharacterMeshLoader.FOLDER
		for _, name in CharacterMeshLoader.PARTS do
			local mp = f.Parts[name]
			local mid = if mp then Retiradas.meshIdOf(mp) else nil
			if mp and not (mid and bad[mid]) then
				local c = mp:Clone()
				c.Name = name
				for _, d in c:GetChildren() do
					if not d:IsA("SurfaceAppearance") and not d:IsA("Bone") then
						d:Destroy()
					end
				end
				adoptBones(c, mp, f.Source)
				dress(c, textures, f.Model)
				c.Parent = folder
			end
		end
		folder:SetAttribute("Clave", key)
		out[key] = folder
	end
	return out, why
end

function CharacterMeshLoader.template(key: string): Folder?
	return templates[key]
end

-- (pruebas) poner o quitar plantillas a mano
function CharacterMeshLoader._set(map: { [string]: Folder }?)
	templates = map or {}
end

-- Dónde está cada pieza del R15 en reposo (sin animación: solo C0/C1 de sus uniones, Motor6D o
-- AnimationConstraint), a partir de la raíz. Si falta una unión, donde esté la pieza ahora.
function CharacterMeshLoader.restFrames(model: Model): { [string]: CFrame }
	local Joints = require(Shared().Joints)
	local frames: { [string]: CFrame } = {}
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return frames
	end
	frames.HumanoidRootPart = root.CFrame
	for _, name in CharacterMeshLoader.ORDER do
		local part = model:FindFirstChild(name)
		if not part or not part:IsA("BasePart") then
			continue
		end
		local def = CharacterMeshLoader.JOINTS[name]
		local joint = def and Joints.find(model, def[1], name)
		local inner = def and frames[def[2]]
		if joint and inner then
			frames[name] = inner * Joints.c0(joint) * Joints.c1(joint):Inverse()
		else
			frames[name] = part.CFrame
		end
	end
	return frames
end

local function boneWorld(part: BasePart, bone: Bone): CFrame
	local chain = {}
	local b: Instance? = bone
	while b and b:IsA("Bone") do
		table.insert(chain, 1, b)
		b = b.Parent
	end
	local cf = part.CFrame
	for _, x in chain do
		cf = cf * (x :: Bone).CFrame
	end
	return cf
end

local HIDE_ATTR = "P3DOculto"

local function hide(inst: Instance)
	if inst:GetAttribute(HIDE_ATTR) ~= nil then
		return
	end
	if inst:IsA("BasePart") then
		inst:SetAttribute(HIDE_ATTR, inst.Transparency)
		inst.Transparency = 1
	elseif inst:IsA("Decal") then -- (también Texture)
		inst:SetAttribute(HIDE_ATTR, inst.Transparency)
		inst.Transparency = 1
	elseif inst:IsA("SurfaceGui") then
		inst:SetAttribute(HIDE_ATTR, if inst.Enabled then 1 else 0)
		inst.Enabled = false
	end
end

local function show(inst: Instance)
	local v = inst:GetAttribute(HIDE_ATTR)
	if v == nil then
		return
	end
	inst:SetAttribute(HIDE_ATTR, nil)
	if inst:IsA("BasePart") or inst:IsA("Decal") then
		(inst :: any).Transparency = v
	elseif inst:IsA("SurfaceGui") then
		inst.Enabled = v == 1
	end
end

local watchers: { [Model]: RBXScriptConnection } = setmetatable({}, { __mode = "k" }) :: any

function CharacterMeshLoader.mounted(model: Model): boolean
	return model:FindFirstChild(CharacterMeshLoader.FOLDER) ~= nil and model:GetAttribute(CharacterMeshLoader.ATTR_KEY) ~= nil
end

-- Monta el personaje 3D `key` en el actor (un R15 ya vestido con CastLook/CosmeLook). false = sigue igual.
function CharacterMeshLoader.mount(model: Model, key: string?): boolean
	if not key or not model then
		return false
	end
	local tpl = templates[key]
	local data = mallas()
	local spec = data and data.Models and data.Models[key]
	if not tpl or not spec then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local head = model:FindFirstChild("Head")
	if not humanoid or not root or not root:IsA("BasePart") or not head or not head:IsA("BasePart") then
		return false
	end
	if CharacterMeshLoader.mounted(model) then
		return true
	end
	-- (a escala 1: el desfase de cada hueso se mide sin escalar; ScaleTo después lo escala todo)
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
		folder.Name = CharacterMeshLoader.FOLDER
		-- la raíz a la altura de las caderas de ESTE cuerpo (la malla supone 3 studs del suelo)
		local rest = CharacterMeshLoader.restFrames(model)
		-- La malla se hizo sobre el R15 de bloques: raíz a 3 studs (HipHeight 2) y la planta del pie a 3,07
		-- por debajo de la raíz. Si este cuerpo es más alto o más bajo, la malla baja o sube lo mismo.
		local adjust = Vector3.new(0, 3 - (humanoid.HipHeight + root.Size.Y / 2), 0)
		local foot = model:FindFirstChild("LeftFoot")
		if foot and foot:IsA("BasePart") and rest.LeftFoot then
			local sole = -root.CFrame:PointToObjectSpace(rest.LeftFoot.Position).Y + foot.Size.Y / 2
			adjust = Vector3.new(0, CharacterMeshLoader.SOLE - sole, 0)
		end
		local follow = data.Follow or {}
		local hidden = {}
		for _, d in model:GetDescendants() do
			if (d:IsA("BasePart") and d ~= root) or d:IsA("Decal") or d:IsA("SurfaceGui") then
				table.insert(hidden, d)
			end
		end
		for _, name in CharacterMeshLoader.PARTS do
			local mp = folder:FindFirstChild(name)
			if not mp or not mp:IsA("MeshPart") then
				continue
			end
			local center = if name == "CuerpoLOD" then spec.LodCenter else spec.Center
			mp.CFrame = root.CFrame * CFrame.new((center or Vector3.zero) - adjust)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = mp
			weld.Parent = mp
			mp:SetAttribute("Lod", name == "CuerpoLOD")
			for _, b in mp:GetDescendants() do
				if b:IsA("Bone") then
					local partName = follow[b.Name]
					local frame = partName and rest[partName]
					if frame then
						b:SetAttribute("Sigue", partName)
						b:SetAttribute("Desfase", frame:ToObjectSpace(boneWorld(mp, b)))
					end
				end
			end
		end
		folder:SetAttribute("Escala", 1)
		folder.Parent = model
		for _, d in hidden do
			hide(d)
		end
		local FaceKit = require(Shared().FaceKit)
		FaceKit.cleanHead(head)
		model:SetAttribute(CharacterMeshLoader.ATTR_KEY, key)
		model:SetAttribute(FaceKit.ATTR_3D, true)
		local faces = spec.Faces or {}
		local current = model:GetAttribute(FaceKit.ATTR_3D_EXPR)
		model:SetAttribute(FaceKit.ATTR_3D_EXPR, if type(current) == "string" then current else (faces[1] or "Neutral"))
		pcall(function()
			CollectionService:AddTag(model, CharacterMeshLoader.TAG)
		end)
		-- lo que se pegue luego al cuerpo (pelo de piezas, caras con Decal) tampoco se ve; los objetos
		-- que coge en la mano (accesorios de escena), sí
		pcall(function()
			watchers[model] = model.DescendantAdded:Connect(function(d)
				if d:IsDescendantOf(folder) then
					return
				end
				if (d:IsA("Decal") or d:IsA("SurfaceGui")) and d.Parent == head then
					hide(d)
				elseif d:IsA("BasePart") and CollectionService:HasTag(d, "BodyPiece") then
					hide(d)
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
		warn("[Personajes3D] " .. tostring(err))
		CharacterMeshLoader.unmount(model)
		return false
	end
	return true
end

function CharacterMeshLoader.unmount(model: Model)
	local f = model:FindFirstChild(CharacterMeshLoader.FOLDER)
	if f then
		f:Destroy()
	end
	if watchers[model] then
		watchers[model]:Disconnect()
		watchers[model] = nil
	end
	for _, d in model:GetDescendants() do
		show(d)
	end
	model:SetAttribute(CharacterMeshLoader.ATTR_KEY, nil)
	pcall(function()
		local FaceKit = require(Shared().FaceKit)
		model:SetAttribute(FaceKit.ATTR_3D, nil)
		model:SetAttribute(FaceKit.ATTR_3D_EXPR, nil)
	end)
	pcall(function()
		CollectionService:RemoveTag(model, CharacterMeshLoader.TAG)
	end)
end

-- Los actores que se vistieron antes de que acabara la descarga: se montan al terminar
local pending: { [Model]: string } = setmetatable({}, { __mode = "k" }) :: any

function CharacterMeshLoader.request(model: Model, key: string?): boolean
	if not key then
		return false
	end
	if CharacterMeshLoader.mount(model, key) then
		return true
	end
	if CharacterMeshLoader.Status == "cargando" or CharacterMeshLoader.Status == "sin empezar" then
		pending[model] = key
	end
	return false
end

function CharacterMeshLoader.start(): number
	CharacterMeshLoader.Status = "cargando"
	local ok, result = pcall(function()
		local S = Shared()
		local ids = require(S.Personajes3DAssetIds)
		if not CharacterMeshLoader.hasIds(ids) then
			return 0
		end
		local Images = require(S.Images)
		if ids.Texturas then
			pcall(Images.resolve, ids.Texturas)
			ids = { Modelos = ids.Modelos, Texturas = Images.map(ids.Texturas) }
		end
		local AssetLoader = require(script.Parent.AssetLoader)
		local create = Retiradas.realCreate(5)
		local verify = function(all)
			return Retiradas.bad(all, create)
		end
		local map, why = CharacterMeshLoader.prepare(ids, AssetLoader.download, mallas(), verify)
		local holder = Instance.new("Folder")
		holder.Name = "Personajes3D"
		local n = 0
		for _, f in map do
			f.Parent = holder
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
			warn("[Personajes3D] siguen con CastLook: " .. table.concat(list, ", "))
		end
		return n
	end)
	local n = if ok then result else 0
	CharacterMeshLoader.Status = if ok then (if n > 0 then ("malla: %d personajes"):format(n) else "CastLook: sin ids") else ("CastLook: " .. tostring(result))
	if not ok then
		warn("[Personajes3D] " .. tostring(result))
	end
	for model, key in pending do
		if model.Parent then
			pcall(CharacterMeshLoader.mount, model, key)
		end
	end
	table.clear(pending)
	pcall(function()
		workspace:SetAttribute("Personajes3D", CharacterMeshLoader.Status)
	end)
	return n
end

return CharacterMeshLoader
