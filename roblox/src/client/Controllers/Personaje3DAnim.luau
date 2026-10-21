-- Personaje3DAnim (cliente): mueve la malla de los personajes 3D propios (World/CharacterMeshLoader,
-- etiqueta «Personaje3D») con su actor. No decide nada: solo se ve.
--
--   * Cada Bone de la malla (Cuerpo y CuerpoLOD) sigue a su pieza del R15 (atributo Sigue) con el desfase
--     que tenía en reposo (Desfase): bone.WorldCFrame = pieza.CFrame * Desfase, y Transform a cero. Así
--     todo lo que mueve las piezas —el Animator (andar, emotes), las capas de postura de PoseLayers,
--     los gestos de StageDirector y ActorLife, AgeMotion, SeaMotion…— mueve la malla igual. Con
--     Model:ScaleTo (niños) el desfase se escala con el modelo.
--   * La cara: los huesos Face* siguen a la cabeza con la pose de su expresión (atributo Cara3DExpresion,
--     shared/Personajes3DMallas.Expressions) y, al hablar (atributo local Cara3DHabla, FaceKit.flap), la
--     boca abierta encima. Las poses se mezclan suave (sin saltos).
--   * Versión lejana: de lejos se ve CuerpoLOD y solo se mueven sus huesos.
-- Topes: como mucho MaxAnimated personajes a la vez (los más cercanos) y nada más lejos de MaxDistance.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Personaje3DAnim = {}

Personaje3DAnim.TAG = "Personaje3D"
Personaje3DAnim.MaxAnimated = 24
Personaje3DAnim.MaxDistance = 260
Personaje3DAnim.LodDistance = 70
Personaje3DAnim.FaceSpeed = 14

type BoneRec = { Bone: Bone, Part: string, Offset: CFrame, Face: boolean }
type Rec = {
	Model: Model,
	Folder: Instance,
	Body: BasePart?,
	Lod: BasePart?,
	BodyBones: { BoneRec },
	LodBones: { BoneRec },
	Parts: { [string]: BasePart },
	Face: { [string]: CFrame },
	UsingLod: boolean,
}

local recs: { [Model]: Rec } = {}
local mallas: any = nil

local function data(): any
	if mallas == nil then
		local ok, m = pcall(function()
			return require(ReplicatedStorage.Shared.Personajes3DMallas)
		end)
		mallas = if ok then m else false
	end
	return mallas or nil
end

-- (pruebas) otros datos
function Personaje3DAnim._setData(m: any)
	mallas = m
end

local function bonesOf(part: BasePart?): { BoneRec }
	local list = {}
	if not part then
		return list
	end
	for _, b in part:GetDescendants() do
		if b:IsA("Bone") then
			local follow = b:GetAttribute("Sigue")
			local offset = b:GetAttribute("Desfase")
			if type(follow) == "string" and typeof(offset) == "CFrame" then
				table.insert(list, { Bone = b, Part = follow, Offset = offset, Face = string.sub(b.Name, 1, 4) == "Face" })
			end
		end
	end
	return list
end

function Personaje3DAnim.track(model: Model): Rec?
	local folder = model:FindFirstChild("Personaje3D")
	if not folder then
		return nil
	end
	local body = folder:FindFirstChild("Cuerpo") :: BasePart?
	local lod = folder:FindFirstChild("CuerpoLOD") :: BasePart?
	local rec: Rec = {
		Model = model,
		Folder = folder,
		Body = body,
		Lod = lod,
		BodyBones = bonesOf(body),
		LodBones = bonesOf(lod),
		Parts = {},
		Face = {},
		UsingLod = false,
	}
	if lod then
		lod.LocalTransparencyModifier = 1
	end
	recs[model] = rec
	return rec
end

local function part(rec: Rec, name: string): BasePart?
	local p = rec.Parts[name]
	if p and p.Parent == rec.Model then
		return p
	end
	local found = rec.Model:FindFirstChild(name)
	if found and found:IsA("BasePart") then
		rec.Parts[name] = found
		return found
	end
	return nil
end

-- La pose de la cara que toca ahora (expresión + boca abierta al hablar)
function Personaje3DAnim.targetFace(model: Model): { [string]: CFrame }
	local d = data()
	local out: { [string]: CFrame } = {}
	if not d or not d.Expressions then
		return out
	end
	local expr = model:GetAttribute("Cara3DExpresion")
	local pose = d.Expressions[if type(expr) == "string" then expr else "Neutral"] or {}
	for bone, cf in pose do
		out[bone] = cf
	end
	if model:GetAttribute("Cara3DHabla") == true then
		for bone, cf in d.Expressions.Talk or {} do
			out[bone] = (out[bone] or CFrame.identity) * cf
		end
	end
	return out
end

local function scaleOf(model: Model): number
	local ok, s = pcall(function()
		return model:GetScale()
	end)
	local base = 1
	local folder = model:FindFirstChild("Personaje3D")
	if folder then
		local b = folder:GetAttribute("Escala")
		base = if type(b) == "number" and b > 0 then b else 1
	end
	return (if ok and type(s) == "number" then s else 1) / base
end

-- Escribe un hueso (las pruebas lo cambian para leer lo que se pondría)
function Personaje3DAnim._write(bone: Bone, cf: CFrame)
	bone.WorldCFrame = cf
	bone.Transform = CFrame.identity
end

-- Dónde va un hueso: su pieza ahora, por su desfase de reposo (escalado k); los de la cara, con su pose
function Personaje3DAnim.boneCFrame(partCF: CFrame, off: CFrame, k: number, pose: CFrame?): CFrame
	if pose then
		return partCF * CFrame.new((off.Position + pose.Position) * k) * pose.Rotation * off.Rotation
	elseif k ~= 1 then
		return partCF * CFrame.new(off.Position * k) * off.Rotation
	end
	return partCF * off
end

-- Pone los huesos de una malla (los de la cara con su pose) donde están sus piezas
function Personaje3DAnim.apply(rec: Rec, bones: { BoneRec }, k: number)
	for _, br in bones do
		local p = part(rec, br.Part)
		if not p then
			continue
		end
		local pose = if br.Face then (rec.Face[br.Bone.Name] or CFrame.identity) else nil
		Personaje3DAnim._write(br.Bone, Personaje3DAnim.boneCFrame(p.CFrame, br.Offset, k, pose))
	end
end

local function step(dt: number)
	local cam = workspace.CurrentCamera
	local eye = if cam then cam.CFrame.Position else Vector3.zero
	local list = {}
	for model, rec in recs do
		if not model.Parent or not rec.Folder.Parent then
			recs[model] = nil
			continue
		end
		local root = part(rec, "HumanoidRootPart")
		if root then
			local dist = (root.Position - eye).Magnitude
			if dist <= Personaje3DAnim.MaxDistance then
				table.insert(list, { rec, dist })
			end
		end
	end
	table.sort(list, function(a, b)
		return a[2] < b[2]
	end)
	local a = 1 - math.exp(-dt * Personaje3DAnim.FaceSpeed)
	for i, item in list do
		if i > Personaje3DAnim.MaxAnimated then
			break
		end
		local rec: Rec, dist = item[1], item[2]
		local far = dist > Personaje3DAnim.LodDistance and rec.Lod ~= nil
		if far ~= rec.UsingLod then
			rec.UsingLod = far
			if rec.Body then
				rec.Body.LocalTransparencyModifier = if far then 1 else 0
			end
			if rec.Lod then
				rec.Lod.LocalTransparencyModifier = if far then 0 else 1
			end
		end
		local target = Personaje3DAnim.targetFace(rec.Model)
		for _, name in { "FaceJaw", "FaceMouthL", "FaceMouthR", "FaceBrowL", "FaceBrowR", "FaceLidL", "FaceLidR" } do
			local cur = rec.Face[name] or CFrame.identity
			rec.Face[name] = cur:Lerp(target[name] or CFrame.identity, a)
		end
		local k = scaleOf(rec.Model)
		Personaje3DAnim.apply(rec, if far then rec.LodBones else rec.BodyBones, k)
	end
end

Personaje3DAnim._step = step
Personaje3DAnim._recs = recs

function Personaje3DAnim.init()
	local function add(model: Instance)
		if model:IsA("Model") then
			task.defer(function()
				pcall(Personaje3DAnim.track, model)
			end)
		end
	end
	for _, m in CollectionService:GetTagged(Personaje3DAnim.TAG) do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal(Personaje3DAnim.TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(Personaje3DAnim.TAG):Connect(function(m)
		recs[m :: Model] = nil
	end)
	local signal = (RunService :: any).PreRender or RunService.RenderStepped
	signal:Connect(function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[Personaje3DAnim] " .. tostring(err))
		end
	end)
end

return Personaje3DAnim
