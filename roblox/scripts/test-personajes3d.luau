-- Prueba de los personajes 3D propios (encargo «Modelos 3D propios»: scripts/personajes/personajes3d_blender.py,
-- shared/Personajes3DMallas, World/CharacterMeshLoader, Controllers/Personaje3DAnim) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-personajes3d.luau
--
-- Comprueba que:
--   * cada personaje es UNA malla con el esqueleto R15 de Roblox (los 15 huesos con los nombres de las
--     piezas, colgando como en el R15, cada uno en su articulación) más los huesos de la cara
--   * los triángulos y las texturas caben (héroes ≤ 12.000 y LOD ≤ 3.000, textura 1024; los demás
--     ≤ 8.000 / 2.000 y 512) y están todos los archivos (FBX y PNG)
--   * la revisión de moderación (scripts/audit/moderacion-mallas.py) dio 0 marcas en TODAS las mallas y
--     cada una tiene su «vista gris» de 6 lados (docs/personajes/3d/revision-gris/)
--   * sin ids, sin plantilla o con la malla retirada por la moderación el actor sigue con CastLook
--   * montado: las piezas del R15 se esconden, la malla va soldada a la raíz, cada hueso sabe a qué pieza
--     sigue y su desfase lo deja exactamente en su sitio, y desmontar lo deja como estaba
--   * UNA sola boca siempre (FaceKit.mouths): con cada expresión, al hablar, con Cosme y con el reparto
--   * los gestos se siguen viendo: al mover las piezas con una postura (saludar, señalar…), los huesos
--     van con ellas; y los nombres de articulación que usan los gestos existen en el esqueleto
--   * el juego lo usa: Npc.dress monta la malla, el servidor carga las plantillas, el cliente mueve los
--     huesos, y el script de subida revisa las mallas antes de pedir la clave

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("./lib/ModuleLoader")
local FakeRig = require("./lib/FakeRig")
local R15Rig = require("./lib/R15Rig")
local check = L.check

local CFrame, Vector3 = roblox.CFrame, roblox.Vector3

local Mallas = L.load("src/shared/Personajes3DMallas")
local FaceKit = L.load("src/shared/FaceKit")
local CastLook = L.load("src/shared/LifeStory/CastLook")
CastLook._setIds({})
local CosmeLook = L.load("src/shared/CosmeLook")
CosmeLook._setIds({})
local Loader = L.load("src/server/World/CharacterMeshLoader")
local Anim = L.load("src/client/Controllers/Personaje3DAnim")
Anim._setData(Mallas)

local function near(a: any, b: any, tol: number?): boolean
	return (a - b).Magnitude <= (tol or 1e-3)
end

local keys = {}
for key in Mallas.Models do
	table.insert(keys, key)
end
table.sort(keys)

---------------------------------------------------------------------
print("\n▶ El piloto")
---------------------------------------------------------------------
for _, key in { "Cosme", "Familia_Mama", "Familia_Papa", "Pip", "Abu_Rosa", "Abu_Tomas", "Lucia", "Nico" } do
	check(Mallas.Models[key] ~= nil, key .. " tiene modelo 3D")
end

---------------------------------------------------------------------
print("\n▶ Esqueleto R15 (nombres, padres y articulaciones)")
---------------------------------------------------------------------
-- Las articulaciones del R15 de bloques (lib/R15Rig) respecto a la raíz
local frames = R15Rig.solve({})
local jointAt: { [string]: any } = {}
local parentOf: { [string]: string } = { HumanoidRootPart = "Root" }
for _, def in R15Rig.Joints do
	local name, p0, p1, c0 = def[1], def[2], def[3], def[4]
	jointAt[p1] = (frames[p0] * c0).Position - frames.HumanoidRootPart.Position
	parentOf[p1] = p0
end
jointAt.HumanoidRootPart = Vector3.new(0, 0, 0)
for _, key in keys do
	local m = Mallas.Models[key]
	local byName = {}
	for _, b in m.Bones do
		byName[b.Name] = b
	end
	local okNames, okParents, okPos = true, true, true
	for _, part in Mallas.R15 do
		local b = byName[part]
		if not b then
			okNames = false
			print("    falta el hueso " .. part)
		elseif b.Parent ~= parentOf[part] then
			okParents = false
			print(("    %s cuelga de %s (debe ser %s)"):format(part, b.Parent, parentOf[part]))
		elseif not near(b.Pos, jointAt[part], 0.01) then
			okPos = false
			print(("    %s en %s (articulación %s)"):format(part, tostring(b.Pos), tostring(jointAt[part])))
		end
	end
	check(okNames, key .. ": los 15 huesos con los nombres de las piezas del R15 (+ HumanoidRootPart)")
	check(okParents, key .. ": cada hueso cuelga de su pieza de dentro, como en el R15")
	check(okPos, key .. ": cada hueso en su articulación del R15 (la malla se dobla donde se doblan las piezas)")
	local okFace = true
	for _, f in Mallas.FaceBones do
		if not byName[f] or byName[f].Parent ~= "Head" then
			okFace = false
		end
	end
	check(okFace, key .. ": huesos de la cara (FaceJaw, FaceMouthL/R, FaceBrowL/R, FaceLidL/R) en la cabeza")
	local okFollow = true
	for _, b in m.Bones do
		local f = Mallas.Follow[b.Name]
		if b.Name ~= "Root" and (not f or (f ~= "HumanoidRootPart" and not table.find(Mallas.R15, f))) then
			okFollow = false
		end
	end
	check(okFollow, key .. ": cada hueso sigue a una pieza del R15 (Follow)")
end

---------------------------------------------------------------------
print("\n▶ Triángulos, texturas y archivos")
---------------------------------------------------------------------
local function pngSize(path: string): (number, number)
	local data = fs.readFile(path)
	local function u32(i: number): number
		local a, b, c, d = string.byte(data, i, i + 3)
		return ((a * 256 + b) * 256 + c) * 256 + d
	end
	return u32(17), u32(21)
end
for _, key in keys do
	local m = Mallas.Models[key]
	local maxT, maxL, tex = if m.Hero then 12000 else 8000, if m.Hero then 3000 else 2000, if m.Hero then 1024 else 512
	check(m.MaxTris == maxT and m.Tris <= maxT, ("%s: %d triángulos (tope %d)"):format(key, m.Tris, maxT))
	check(m.MaxLodTris == maxL and m.LodTris <= maxL and m.LodTris < m.Tris, ("%s: LOD %d triángulos (tope %d)"):format(key, m.LodTris, maxL))
	check(m.TextureSize == tex, ("%s: textura de %d"):format(key, m.TextureSize))
	local fbx = "assets/personajes3d/" .. m.Asset .. ".fbx"
	check(fs.isFile(fbx), key .. ": " .. fbx)
	local okTex = true
	for _, t in { m.Textures.Color, m.Textures.Normal, m.Textures.Roughness } do
		local path = "assets/personajes3d/tex/" .. t .. ".png"
		if not fs.isFile(path) then
			okTex = false
			print("    falta " .. path)
		else
			local w, h = pngSize(path)
			if w ~= tex or h ~= tex then
				okTex = false
				print(("    %s mide %dx%d"):format(path, w, h))
			end
		end
	end
	check(okTex, key .. ": texturas color, normal y rugosidad de " .. tex .. " px")
end

---------------------------------------------------------------------
print("\n▶ Revisión de moderación: 0 marcas y vista gris de cada malla")
---------------------------------------------------------------------
local REV = "docs/personajes/3d/revision-gris"
local report = REV .. "/informe.json"
check(fs.isFile(report), "hay informe de scripts/audit/moderacion-mallas.py --kits personajes3d (" .. report .. ")")
if fs.isFile(report) then
	local rows = serde.decode("json", fs.readFile(report))
	local seen = {}
	local flagged = 0
	for _, r in rows do
		seen[(r.asset or "") .. "/" .. (r.mesh or "")] = r.level
		if r.level ~= "ok" then
			flagged += 1
			print(("    %s · %s: %s %s"):format(tostring(r.file), tostring(r.mesh), tostring(r.level), tostring(r.why)))
		end
	end
	check(flagged == 0, "0 mallas marcadas (ninguna parece un tubo liso suelto)")
	local okAll, okGrey = true, true
	for _, key in keys do
		local m = Mallas.Models[key]
		for _, mesh in { "Cuerpo", "CuerpoLOD" } do
			if seen[m.Asset .. "/" .. mesh] ~= "ok" then
				okAll = false
				print("    sin revisar: " .. m.Asset .. " · " .. mesh)
			end
			if not fs.isFile(("%s/%s__%s.jpg"):format(REV, m.Asset, mesh)) then
				okGrey = false
				print(("    sin vista gris: %s__%s.jpg"):format(m.Asset, mesh))
			end
		end
	end
	check(okAll, "revisadas TODAS las mallas que se subirían (Cuerpo y CuerpoLOD de cada personaje)")
	check(okGrey, "cada malla tiene su vista gris de 6 lados")
	-- y nada más en el FBX: ninguna pieza suelta
	local okOnly = true
	for _, r in rows do
		if r.mesh ~= "Cuerpo" and r.mesh ~= "CuerpoLOD" then
			okOnly = false
			print("    malla suelta en el FBX: " .. tostring(r.file) .. " · " .. tostring(r.mesh))
		end
	end
	check(okOnly, "cada FBX lleva solo Cuerpo y CuerpoLOD (nunca una pieza del cuerpo suelta)")
end

---------------------------------------------------------------------
print("\n▶ Expresiones (una sola boca: la de la malla)")
---------------------------------------------------------------------
local faceSet = {}
for _, f in Mallas.FaceBones do
	faceSet[f] = true
end
local okExprBones = true
for name, pose in Mallas.Expressions do
	for bone in pose do
		if not faceSet[bone] then
			okExprBones = false
			print("    " .. name .. " mueve " .. bone)
		end
	end
end
check(okExprBones, "las expresiones solo mueven huesos de la cara")
for _, e in { "Neutral", "Happy", "Sad", "Angry", "Scared", "Talk", "Grin", "Skeptic", "Laugh" } do
	check(Mallas.Expressions[e] ~= nil, "expresión " .. e .. " (CastLook / CosmeLook)")
end
for _, key in keys do
	local okF = true
	for _, f in Mallas.Models[key].Faces do
		if not Mallas.Expressions[f] then
			okF = false
		end
	end
	check(okF, key .. ": sus caras existen")
end

---------------------------------------------------------------------
print("\n▶ Sin malla subida: CastLook de siempre")
---------------------------------------------------------------------
local tpl, why = Loader.prepare({ Modelos = {}, Texturas = {} }, function()
	return nil
end, Mallas)
check(next(tpl) == nil and why["*"] ~= nil, "sin ids: ninguna plantilla («" .. tostring(why["*"]) .. "»)")
check(Loader.keyFor({ Costume = "Cosme" }) == "Cosme", "keyFor: Cosme (Costume)")
check(Loader.keyFor({ Id = "Familia", Variant = "NPC.PAPA" }) == "Familia_Papa", "keyFor: Familia + NPC.PAPA = Familia_Papa")
check(Loader.keyFor({ Id = "Abu", Variant = "NPC.ABU_ROSA" }) == "Abu_Rosa", "keyFor: Abu + NPC.ABU_ROSA = Abu_Rosa")
check(Loader.keyFor({ Id = "Nico" }) == "Nico", "keyFor: Nico")
check(Loader.keyFor({ Id = "Sara" }) == nil, "keyFor: Sara (aún sin modelo 3D) = nil")
check(Loader.keyFor(nil) == nil and Loader.keyFor({}) == nil, "keyFor sin aspecto = nil")

local function dressed(key: string): any
	local model = FakeRig.build(L.Instance)
	local m = Mallas.Models[key]
	local hum = L.Instance.new("Humanoid")
	hum.HipHeight = 2
	hum.Parent = model
	if key == "Cosme" then
		CosmeLook.dress(model, {})
	else
		CastLook.apply(model, m.Cast, m.Variant, {})
	end
	return model
end

Loader._set({})
local plain = dressed("Familia_Mama")
check(Loader.mount(plain, "Familia_Mama") == false, "sin plantilla: mount = false")
check(plain:FindFirstChild("Personaje3D") == nil and plain.Head.Transparency == 0, "…y el actor sigue igual (piezas visibles, sin malla)")
check((FaceKit.mouths(plain)) == 1, "…con una sola boca")

-- Un FBX de mentira, como lo da Roblox: MeshPart Cuerpo y CuerpoLOD con sus Bone (en su sitio)
local function fakeModel(key: string, meshId: string): any
	local m = Mallas.Models[key]
	local model = L.Instance.new("Model")
	for _, name in { "Cuerpo", "CuerpoLOD" } do
		local mp = L.Instance.new("MeshPart")
		mp.Name = name
		mp.MeshId = meshId
		local center = if name == "CuerpoLOD" then m.LodCenter else m.Center
		mp.CFrame = CFrame.new(center)
		mp.Parent = model
		local made = {}
		local pos = {}
		for _, b in m.Bones do
			pos[b.Name] = b.Pos
		end
		pos.Root = pos.Root or Vector3.new(0, -3, 0)
		for _, b in m.Bones do
			local bone = L.Instance.new("Bone")
			bone.Name = b.Name
			local parent = made[b.Parent]
			if parent then
				bone.CFrame = CFrame.new(b.Pos - pos[b.Parent])
				bone.Parent = parent
			else
				bone.CFrame = CFrame.new(b.Pos - center)
				bone.Parent = mp
			end
			made[b.Name] = bone
		end
	end
	return model
end

local ids = { Modelos = {}, Texturas = {} }
local idx = {}
for i, key in keys do
	idx[key] = i
	ids.Modelos[Mallas.Models[key].Asset] = "rbxassetid://" .. tostring(900000 + i)
end
local function download(id: number): any
	for i, key in keys do
		if 900000 + i == id then
			return fakeModel(key, "rbxassetid://" .. tostring(500000 + i))
		end
	end
	return nil
end
tpl, why = Loader.prepare(ids, download, Mallas)
local n = 0
for _ in tpl do
	n += 1
end
check(n == #keys, ("con ids: %d plantillas (%d personajes)"):format(n, #keys))
check(tpl.Cosme and tpl.Cosme:FindFirstChild("Cuerpo") and tpl.Cosme.Cuerpo:FindFirstChildWhichIsA("Bone", true) ~= nil, "la plantilla lleva Cuerpo con sus huesos")
-- retirada por la moderación (World/MallasRetiradas): ESE personaje sigue con CastLook
local retiredDownload = function(id: number): any
	local mdl = download(id)
	if mdl and id == 900000 + idx.Cosme then
		mdl.Cuerpo.MeshId = "rbxassetid://136955064198663"
	end
	return mdl
end
local tpl2, why2 = Loader.prepare(ids, retiredDownload, Mallas)
check(tpl2.Cosme == nil and string.find(tostring(why2.Cosme), "retirada", 1, true) ~= nil, "malla retirada por la moderación: Cosme sin plantilla («" .. tostring(why2.Cosme) .. "»)")
check(tpl2.Nico ~= nil, "…los demás siguen con la suya")
local tpl3, why3 = Loader.prepare(ids, download, Mallas, function()
	return { [500000 + idx.Nico] = true }
end)
check(tpl3.Nico == nil and tpl3.Cosme ~= nil, "malla que no carga en el servidor (verify): ese personaje sin plantilla")

---------------------------------------------------------------------
print("\n▶ Montar: malla soldada, piezas escondidas, huesos en su sitio")
---------------------------------------------------------------------
Loader._set(tpl)
for _, key in keys do
	local m = Mallas.Models[key]
	local model = dressed(key)
	local ok = Loader.mount(model, key)
	check(ok, key .. ": mount = true")
	local folder = model:FindFirstChild("Personaje3D")
	local body = folder and folder:FindFirstChild("Cuerpo")
	check(body ~= nil and body:FindFirstChildOfClass("WeldConstraint") ~= nil and body:FindFirstChildOfClass("WeldConstraint").Part0 == model.HumanoidRootPart,
		key .. ": Cuerpo soldado a la raíz")
	local hiddenAll = true
	for _, part in Mallas.R15 do
		local p = model:FindFirstChild(part)
		if p and p.Transparency < 1 then
			hiddenAll = false
		end
	end
	check(hiddenAll, key .. ": las piezas del R15 no se ven (pero siguen: Humanoid, cabeza, articulaciones)")
	check(model:FindFirstChildOfClass("Humanoid") ~= nil and model:FindFirstChild("Head") ~= nil, key .. ": sigue teniendo Humanoid y Head (nombre, bocadillos, interacciones)")
	-- cada hueso: su pieza en reposo * desfase = su punto del manifest
	local rest = Loader.restFrames(model)
	local root = model.HumanoidRootPart.CFrame
	local okBones = true
	local count = 0
	for _, b in body:GetDescendants() do
		if b:IsA("Bone") and b.Name ~= "Root" then
			count += 1
			local follow = b:GetAttribute("Sigue")
			local off = b:GetAttribute("Desfase")
			local want
			for _, mb in m.Bones do
				if mb.Name == b.Name then
					want = root * mb.Pos
				end
			end
			if type(follow) ~= "string" or not off or not want or not near((rest[follow] * off).Position, want, 1e-3) then
				okBones = false
				print("    " .. b.Name .. " fuera de su sitio")
			end
		end
	end
	check(okBones and count >= 22, ("%s: %d huesos con su pieza (Sigue) y su desfase de reposo exacto"):format(key, count))
	check(model:GetAttribute("Personaje3D") == key and model:GetAttribute("Cara3D") == true, key .. ": atributos Personaje3D y Cara3D")
	-- una sola boca, con cada expresión y hablando
	local okMouth = true
	for _, face in m.Faces do
		if key == "Cosme" then
			CosmeLook.setFace(model, face)
		elseif face ~= "Talk" then
			model:SetAttribute("Mood", nil)
			CastLook.rest(model)
			FaceKit.express3D(model, face)
		end
		FaceKit.set(model, "rbxassetid://123") -- (aunque alguien intente poner una cara de Decal)
		FaceKit.flap(model, true)
		local nM, list = FaceKit.mouths(model)
		if nM ~= 1 then
			okMouth = false
			print("    " .. face .. ": " .. table.concat(list, ", "))
		end
		FaceKit.flap(model, false)
	end
	check(okMouth, key .. ": UNA sola boca con cada expresión y hablando (" .. table.concat(m.Faces, ", ") .. ")")
	if key == "Cosme" then
		CosmeLook.setFace(model, "Laugh")
		check(model:GetAttribute("Cara3DExpresion") == "Laugh", "Cosme: CosmeLook.setFace mueve la cara 3D (Laugh)")
	elseif key == "Familia_Mama" then
		FaceKit.flap(model, true)
		check(model:GetAttribute("Cara3DHabla") == true, "hablar abre la boca de la malla (Cara3DHabla)")
		FaceKit.flap(model, false)
		-- desmontar: como estaba
		Loader.unmount(model)
		local back = true
		for _, part in Mallas.R15 do
			local p = model:FindFirstChild(part)
			if p and part ~= "HumanoidRootPart" and p.Transparency ~= 0 then
				back = false
			end
		end
		check(back and model:FindFirstChild("Personaje3D") == nil and model:GetAttribute("Cara3D") == nil, "unmount: vuelven las piezas (CastLook) y se quita la malla")
		check((FaceKit.mouths(model)) == 1, "…con una sola boca")
	end
end

---------------------------------------------------------------------
print("\n▶ Los gestos mueven la malla (cliente: Personaje3DAnim)")
---------------------------------------------------------------------
local model = dressed("Cosme")
Loader.mount(model, "Cosme")
local rec = Anim.track(model)
check(rec ~= nil and #rec.BodyBones >= 22 and #rec.LodBones >= 22, "el cliente encuentra los huesos de Cuerpo y CuerpoLOD")
local written: { [string]: any } = {}
Anim._write = function(bone, cf)
	written[bone.Name] = cf
end
-- en reposo: cada hueso donde estaba
Anim.apply(rec, rec.BodyBones, 1)
local function boneRest(name: string): any
	for _, b in Mallas.Models.Cosme.Bones do
		if b.Name == name then
			return model.HumanoidRootPart.CFrame * b.Pos
		end
	end
	return nil
end
local okRest = true
for _, name in Mallas.R15 do
	if written[name] and not near(written[name].Position, boneRest(name), 1e-3) then
		okRest = false
	end
end
check(okRest, "en reposo, cada hueso queda en su sitio")
local gestures = {
	Saludar = { RightShoulder = CFrame.Angles(0, 0, math.rad(150)), RightElbow = CFrame.Angles(0, 0, math.rad(20)) },
	Senalar = { RightShoulder = CFrame.Angles(math.rad(85), 0, 0) },
	Andar = { RightHip = CFrame.Angles(math.rad(30), 0, 0), LeftHip = CFrame.Angles(math.rad(-30), 0, 0), RightKnee = CFrame.Angles(math.rad(-40), 0, 0), LeftShoulder = CFrame.Angles(math.rad(25), 0, 0) },
	Agacharse = { Waist = CFrame.Angles(math.rad(30), 0, 0), Neck = CFrame.Angles(math.rad(-15), 0, 0) },
}
for gname, pose in gestures do
	local f = R15Rig.solve(pose, nil, model.HumanoidRootPart.CFrame)
	for part, cf in f do
		local p = model:FindFirstChild(part)
		if p then
			p.CFrame = cf
		end
	end
	table.clear(written)
	Anim.apply(rec, rec.BodyBones, 1)
	local okG = true
	for _, br in rec.BodyBones do
		if not br.Face then
			local want = f[br.Part] * br.Offset
			if not written[br.Bone.Name] or not near(written[br.Bone.Name].Position, want.Position, 1e-3) then
				okG = false
			end
		end
	end
	check(okG, gname .. ": cada hueso va con su pieza")
end
-- saludar: la mano sube por encima de la cabeza
do
	local f = R15Rig.solve(gestures.Saludar, nil, model.HumanoidRootPart.CFrame)
	for part, cf in f do
		local p = model:FindFirstChild(part)
		if p then
			p.CFrame = cf
		end
	end
	table.clear(written)
	Anim.apply(rec, rec.BodyBones, 1)
	check(written.RightHand and written.RightHand.Position.Y > model.HumanoidRootPart.CFrame.Position.Y + 1.5, "saludar: el hueso de la mano derecha sube (por encima del pecho)")
end
-- la cara: expresión y hablar
model:SetAttribute("Cara3DExpresion", "Scared")
model:SetAttribute("Cara3DHabla", true)
local target = Anim.targetFace(model)
check(target.FaceJaw ~= nil and target.FaceJaw.Position.Y < Mallas.Expressions.Scared.FaceJaw.Position.Y - 0.05, "hablando con miedo: la mandíbula baja más (miedo + boca abierta)")
-- escalado (niños: Model:ScaleTo)
local cf1 = Anim.boneCFrame(CFrame.new(0, 3, 0), CFrame.new(0.5, 0.2, 0), 0.65, nil)
check(near(cf1.Position, Vector3.new(0.325, 3.13, 0), 1e-4), "con ScaleTo(0.65) el desfase se escala")

-- los nombres de articulación que usan los gestos y posturas existen en el R15 del esqueleto
local jointNames = {}
for _, def in R15Rig.Joints do
	jointNames[def[1]] = def[3]
end
local used = {}
for _, file in { "src/client/Controllers/ActorLife.luau", "src/client/Controllers/PoseLayers.luau", "src/client/Controllers/AgeMotion.luau", "src/client/Controllers/SeaMotion.luau", "src/client/Controllers/SimpleActing.luau" } do
	if fs.isFile(file) then
		for name in string.gmatch(fs.readFile(file), "\"(%u%a-)\"") do
			if string.find(name, "Shoulder$") or string.find(name, "Elbow$") or string.find(name, "Wrist$") or string.find(name, "Hip$")
				or string.find(name, "Knee$") or string.find(name, "Ankle$") or name == "Neck" or name == "Waist" then
				used[name] = true
			end
		end
	end
end
local okUsed, nUsed = true, 0
local follows = {}
for _, b in Mallas.Models.Cosme.Bones do
	follows[Mallas.Follow[b.Name] or ""] = true
end
for name in used do
	nUsed += 1
	local part = jointNames[name]
	if not part or not follows[part] then
		okUsed = false
		print("    articulación sin hueso: " .. name)
	end
end
check(okUsed and nUsed >= 8, ("las %d articulaciones de los gestos (ActorLife, PoseLayers, AgeMotion, SeaMotion…) mueven un hueso"):format(nUsed))

---------------------------------------------------------------------
print("\n▶ El juego lo usa")
---------------------------------------------------------------------
local npc = fs.readFile("src/server/World/Npc.luau")
check(string.find(npc, "Npc.mesh3D(model, l)", 1, true) ~= nil and string.find(npc, "CharacterMeshLoader", 1, true) ~= nil, "Npc.dress monta la malla 3D (Cosme y el reparto)")
check(string.find(fs.readFile("src/server/Main.server.luau"), "CharacterMeshLoader).start()", 1, true) ~= nil, "el servidor carga las plantillas al arrancar")
check(string.find(fs.readFile("src/client/Main.client.luau"), "Personaje3DAnim).init", 1, true) ~= nil, "el cliente mueve los huesos (Personaje3DAnim)")
local ids0 = L.load("src/shared/Personajes3DAssetIds")
check(type(ids0.Modelos) == "table" and type(ids0.Texturas) == "table", "shared/Personajes3DAssetIds (Modelos, Texturas)")
local up = fs.readFile("scripts/upload-personajes3d.sh")
local iCheck = string.find(up, "revisar_mallas \"${PENDIENTES[@]}\"", 1, true)
local iKey = string.find(up, "if [ -z \"${ROBLOX_API_KEY:-}\" ]", 1, true)
check(iCheck ~= nil and iKey ~= nil and iCheck < iKey, "upload-personajes3d.sh: la revisión de moderación va ANTES de la clave y de subir nada")
check(string.find(up, "echo \"$ROBLOX_API_KEY", 1, true) == nil and string.find(up, "set +x", 1, true) ~= nil, "upload-personajes3d.sh: nunca enseña la clave")
check(string.find(up, "image_of_decal", 1, true) ~= nil, "upload-personajes3d.sh: las texturas como Decal -> imagen")
local chk = fs.readFile("scripts/audit/moderacion-mallas.py")
check(string.find(chk, "\"personajes3d\": \"assets/personajes3d/*.fbx\"", 1, true) ~= nil and string.find(chk, "--vista-gris", 1, true) ~= nil, "moderacion-mallas.py revisa assets/personajes3d y hace la vista gris")

L.finish("test-personajes3d")
