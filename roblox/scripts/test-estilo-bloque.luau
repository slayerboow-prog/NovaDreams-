-- Prueba del estilo bloque del reparto (encargo del dueño: scripts/personajes/bloque_blender.py,
-- shared/EstiloBloque, World/EstiloBloqueLoader, Controllers/EstiloBloqueLOD) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-estilo-bloque.luau
--
-- Comprueba que:
--   * el piloto (Cosme, Mamá, Papá, Abu Rosa, Abu Tomás, Pip, Profe Lucía y Nico) tiene sus accesorios,
--     cada uno en una parte del R15 que existe, y su cabeza de bloque para la cara
--   * caben en el móvil (≤ 10.000 triángulos de accesorios por personaje, texturas 1024/512) y están todos
--     los archivos (FBX, atlas, plantillas 585x559 y una cara de 512 por expresión)
--   * la revisión de moderación dio 0 marcas en TODAS las mallas y cada una tiene su vista gris
--   * cada personaje tiene un pelo (o gorra) propio, distinto del de Cosme y del de los demás
--   * sin ids, sin una pieza, con una malla retirada o sin la cara subida: CastLook de siempre
--   * montado: cada accesorio soldado a su parte en su sitio, la Head y el pelo de piezas escondidos, la
--     ropa nueva puesta (la vieja guardada) y UNA sola boca con cada expresión y al hablar; desmontar lo
--     deja como estaba
--   * el cliente cambia a la versión lejana de lejos, y el juego lo usa (Npc.dress, servidor, cliente,
--     script de subida con la revisión antes de la clave)

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("./lib/ModuleLoader")
local FakeRig = require("./lib/FakeRig")
local check = L.check

local CFrame, Vector3 = roblox.CFrame, roblox.Vector3

local Data = L.load("src/shared/EstiloBloque")
local FaceKit = L.load("src/shared/FaceKit")
local CastLook = L.load("src/shared/LifeStory/CastLook")
CastLook._setIds({})
local CosmeLook = L.load("src/shared/CosmeLook")
CosmeLook._setIds({})
L.services.CollectionService.HasTag = function(_, inst, tag)
	return inst:GetAttribute("__tag_" .. tag) == true
end
L.services.CollectionService.RemoveTag = function() end
local Loader = L.load("src/server/World/EstiloBloqueLoader")
local LOD = L.load("src/client/Controllers/EstiloBloqueLOD")

local PILOT = { "Cosme", "Familia_Mama", "Familia_Papa", "Abu_Rosa", "Abu_Tomas", "Pip", "Lucia", "Nico" }
local R15 = {
	"LowerTorso", "UpperTorso", "Head", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperLeg", "RightLowerLeg", "RightFoot", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
}

local function near(a: any, b: any, tol: number?): boolean
	return (a - b).Magnitude <= (tol or 1e-3)
end

---------------------------------------------------------------------
print("\n▶ El piloto y sus accesorios")
---------------------------------------------------------------------
for _, key in PILOT do
	local m = Data.Models[key]
	check(m ~= nil, key .. " tiene estilo bloque")
	if not m then
		continue
	end
	local okPart, hasFaceOn, sum = true, false, 0
	for _, a in m.Accessories do
		if not table.find(R15, a.Part) then
			okPart = false
			print("    " .. a.Name .. " en " .. tostring(a.Part))
		end
		if a.Name == m.FaceOn then
			hasFaceOn = true
		end
		sum += a.Tris
	end
	check(okPart, ("%s: %d accesorios, cada uno en una parte del R15"):format(key, #m.Accessories))
	check(hasFaceOn, key .. ": la cara va en un accesorio suyo (" .. m.FaceOn .. ")")
	check(sum == m.Tris and m.Tris <= 10000, ("%s: %d triángulos de accesorios (tope 10.000)"):format(key, m.Tris))
	check(m.TextureSize == (if m.Hero then 1024 else 512), key .. ": textura de " .. m.TextureSize)
	local faces = if key == "Cosme" then { "Grin", "Skeptic", "Laugh", "Scared", "Talk" } else { "Neutral", "Happy", "Sad", "Angry", "Scared", "Talk" }
	local okF = true
	for _, e in faces do
		if not m.Faces[e] then
			okF = false
		end
	end
	check(okF, key .. ": caras " .. table.concat(faces, ", "))
end

---------------------------------------------------------------------
print("\n▶ Archivos (FBX, atlas, ropa y caras)")
---------------------------------------------------------------------
local function pngSize(path: string): (number, number)
	local d = fs.readFile(path)
	local function u32(i: number): number
		local a, b, c, e = string.byte(d, i, i + 3)
		return ((a * 256 + b) * 256 + c) * 256 + e
	end
	return u32(17), u32(21)
end
local function pngOk(path: string, w: number, h: number): boolean
	if not fs.isFile(path) then
		print("    falta " .. path)
		return false
	end
	local a, b = pngSize(path)
	if a ~= w or b ~= h then
		print(("    %s mide %dx%d"):format(path, a, b))
		return false
	end
	return true
end
for _, key in PILOT do
	local m = Data.Models[key]
	if not m then
		continue
	end
	check(fs.isFile("assets/bloque/" .. m.Asset .. ".fbx"), key .. ": assets/bloque/" .. m.Asset .. ".fbx")
	local ok = true
	for _, t in { m.Textures.Color, m.Textures.Normal, m.Textures.Roughness } do
		ok = pngOk("assets/bloque/tex/" .. t .. ".png", m.TextureSize, m.TextureSize) and ok
	end
	ok = pngOk("assets/bloque/ropa/" .. m.Shirt .. ".png", 585, 559) and ok
	ok = pngOk("assets/bloque/ropa/" .. m.Pants .. ".png", 585, 559) and ok
	for _, f in m.Faces do
		ok = pngOk("assets/bloque/caras/" .. f .. ".png", 512, 512) and ok
	end
	check(ok, key .. ": atlas, plantillas Shirt/Pants (585x559) y caras (512)")
end

---------------------------------------------------------------------
print("\n▶ Moderación: 0 marcas y vista gris de cada malla")
---------------------------------------------------------------------
local REV = "docs/personajes/estilo-bloque/revision-gris"
check(fs.isFile(REV .. "/informe.json"), "informe de scripts/audit/moderacion-mallas.py --kits bloque")
if fs.isFile(REV .. "/informe.json") then
	local rows = serde.decode("json", fs.readFile(REV .. "/informe.json"))
	local seen, flagged = {}, 0
	for _, r in rows do
		seen[(r.asset or "") .. "/" .. (r.mesh or "")] = r.level
		if r.level ~= "ok" then
			flagged += 1
			print(("    %s · %s: %s %s"):format(tostring(r.file), tostring(r.mesh), tostring(r.level), tostring(r.why)))
		end
	end
	check(flagged == 0, "0 mallas marcadas")
	local okAll, okGrey, n = true, true, 0
	for _, key in PILOT do
		local m = Data.Models[key]
		if not m then
			continue
		end
		for _, a in m.Accessories do
			for _, mesh in { a.Name, a.Lod } do
				if mesh then
					n += 1
					if seen[m.Asset .. "/" .. mesh] ~= "ok" then
						okAll = false
						print("    sin revisar: " .. m.Asset .. " · " .. mesh)
					end
					if not fs.isFile(("%s/%s__%s.jpg"):format(REV, m.Asset, mesh)) then
						okGrey = false
					end
				end
			end
		end
	end
	check(okAll, ("revisadas las %d mallas que se subirían"):format(n))
	check(okGrey, "cada malla tiene su vista gris de 6 lados")
end

---------------------------------------------------------------------
print("\n▶ Cada uno con su pelo")
---------------------------------------------------------------------
local hairs = {}
for _, key in PILOT do
	local m = Data.Models[key]
	if not m or key == "Pip" then
		continue
	end
	for _, a in m.Accessories do
		if a.Name == "Pelo" then
			hairs[key] = a
		end
	end
end
local okHair = true
for k1, a in hairs do
	for k2, b in hairs do
		if k1 < k2 and near(a.Size, b.Size, 0.05) and a.Tris == b.Tris then
			okHair = false
			print("    mismo pelo: " .. k1 .. " y " .. k2)
		end
	end
end
check(okHair and hairs.Cosme ~= nil, "el pelo de cada uno es distinto del de los demás y del de Cosme")
local okBig = true
for k, a in hairs do
	if k ~= "Cosme" and a.Size.Magnitude >= hairs.Cosme.Size.Magnitude * 0.85 then
		okBig = false
	end
end
check(okBig, "nadie lleva la mata enorme de Cosme")

---------------------------------------------------------------------
print("\n▶ Sin subir (o retirado): CastLook de siempre")
---------------------------------------------------------------------
local tpl, why = Loader.prepare({ Modelos = {}, Texturas = {} }, function()
	return nil
end, Data)
check(next(tpl) == nil and why["*"] ~= nil, "sin ids: ninguna plantilla")
check(Loader.keyFor({ Costume = "Cosme" }) == "Cosme", "keyFor: Cosme")
check(Loader.keyFor({ Id = "Familia", Variant = "NPC.PAPA" }) == "Familia_Papa", "keyFor: Familia + NPC.PAPA")
check(Loader.keyFor({ Id = "Abu", Variant = "NPC.ABU_TOMAS" }) == "Abu_Tomas", "keyFor: Abu + NPC.ABU_TOMAS")
check(Loader.keyFor({ Id = "Sara" }) == nil, "keyFor: Sara (sin estilo bloque aún) = nil")

local keys = {}
for k in Data.Models do
	table.insert(keys, k)
end
table.sort(keys)
local idx = {}
local ids = { Modelos = {}, Texturas = {} }
for i, k in keys do
	idx[k] = i
	local m = Data.Models[k]
	ids.Modelos[m.Asset] = "rbxassetid://" .. tostring(900000 + i)
	for _, t in { m.Textures.Color, m.Textures.Normal, m.Textures.Roughness, m.Shirt, m.Pants } do
		ids.Texturas[t] = "rbxassetid://7" .. tostring(i)
	end
	for e, f in m.Faces do
		ids.Texturas[f] = "rbxassetid://8" .. tostring(i) .. string.byte(e)
	end
end
local function fakeModel(k: string, skip: string?, retired: string?): any
	local m = Data.Models[k]
	local model = L.Instance.new("Model")
	for _, a in m.Accessories do
		for _, name in { a.Name, a.Lod } do
			if name and name ~= skip then
				local mp = L.Instance.new("MeshPart")
				mp.Name = name
				mp.MeshId = if name == retired then "rbxassetid://136955064198663" else "rbxassetid://5" .. tostring(idx[k]) .. #name
				mp.Size = a.Size
				mp.Parent = model
			end
		end
	end
	return model
end
local function download(id: number, skip: string?, retired: string?): any
	for i, k in keys do
		if 900000 + i == id then
			return fakeModel(k, skip, retired)
		end
	end
	return nil
end
tpl, why = Loader.prepare(ids, download, Data)
local n = 0
for _ in tpl do
	n += 1
end
check(n == #keys, ("con todo subido: %d plantillas"):format(n))
local t2, w2 = Loader.prepare(ids, function(id)
	return download(id, if id == 900000 + idx.Cosme then "Gafas" else nil)
end, Data)
check(t2.Cosme == nil and string.find(tostring(w2.Cosme), "Gafas", 1, true) ~= nil, "falta un accesorio (Gafas): Cosme sigue con CastLook («" .. tostring(w2.Cosme) .. "»)")
local t3, w3 = Loader.prepare(ids, function(id)
	return download(id, nil, if id == 900000 + idx.Nico then "Pelo" else nil)
end, Data)
check(t3.Nico == nil and t3.Cosme ~= nil, "malla retirada por la moderación (World/MallasRetiradas): solo ese personaje sigue con CastLook")
local noFace = table.clone(ids.Texturas)
noFace[Data.Models.Pip.Faces.Neutral] = nil
local t4 = Loader.prepare({ Modelos = ids.Modelos, Texturas = noFace }, download, Data)
check(t4.Pip == nil, "sin la cara subida: sigue con CastLook (nunca sin cara)")

---------------------------------------------------------------------
print("\n▶ Montar: accesorios soldados, una sola boca, desmontar")
---------------------------------------------------------------------
local function dressed(k: string): any
	local model = FakeRig.build(L.Instance)
	local hum = model:FindFirstChildOfClass("Humanoid") or L.Instance.new("Humanoid")
	hum.HipHeight = 2
	hum.Parent = model
	-- lo que deja Npc.dress: pelo y cuello de piezas (BodyPiece), ropa clásica
	for _, name in { "Hair", "HairBack", "Fringe", "Collar" } do
		local p = L.Instance.new("Part")
		p.Name = name
		p:SetAttribute("__tag_BodyPiece", true)
		p.Parent = model
	end
	local shirt = L.Instance.new("Shirt")
	shirt.Name = "CastShirt"
	shirt.Parent = model
	local m = Data.Models[k]
	if k == "Cosme" then
		CosmeLook.dress(model, {})
	else
		CastLook.apply(model, m.Cast, m.Variant, {})
	end
	return model
end
Loader._set({})
local plain = dressed("Familia_Mama")
check(Loader.mount(plain, "Familia_Mama") == false and plain:FindFirstChild("EstiloBloque") == nil, "sin plantilla: mount = false y sigue igual")
check((FaceKit.mouths(plain)) == 1, "…con una sola boca")

tpl = Loader.prepare(ids, download, Data)
Loader._set(tpl)
for _, k in PILOT do
	local m = Data.Models[k]
	if not m then
		continue
	end
	local model = dressed(k)
	check(Loader.mount(model, k), k .. ": mount = true")
	if #L.warnings > 0 then print("    aviso: " .. L.warnings[#L.warnings]) end
	local folder = model:FindFirstChild("EstiloBloque")
	local okWeld, count = true, 0
	for _, a in m.Accessories do
		local mp = folder and folder:FindFirstChild(a.Name)
		local part = model:FindFirstChild(a.Part)
		local w = mp and mp:FindFirstChildOfClass("WeldConstraint")
		count += 1
		if not mp or not w or w.Part0 ~= part or w.Part1 ~= mp or not near(mp.CFrame.Position, (part.CFrame * CFrame.new(a.Offset)).Position) then
			okWeld = false
			print("    " .. a.Name .. " mal soldado")
		end
		if a.Glow and (mp.Material ~= roblox.Enum.Material.Neon) then
			okWeld = false
			print("    " .. a.Name .. " no es Neon")
		end
	end
	check(okWeld, ("%s: los %d accesorios soldados a su parte, en su sitio (los de luz en Neon)"):format(k, count))
	local okLod = true
	for _, a in m.Accessories do
		if a.Lod then
			local l = folder:FindFirstChild(a.Lod)
			if not l or l.Transparency ~= 1 or l:GetAttribute("LodDe") ~= a.Name then
				okLod = false
			end
		end
	end
	check(okLod, k .. ": las versiones lejanas, invisibles hasta que el cliente las pone")
	local hidden = model.Head.Transparency == 1
	for _, name in { "Hair", "HairBack", "Fringe", "Collar" } do
		local p = model:FindFirstChild(name)
		hidden = hidden and (p == nil or p.Transparency == 1)
	end
	local cl = model:FindFirstChild("CosmeLook")
	if cl then
		for _, p in cl:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency ~= 1 then
				hidden = false
			end
		end
	end
	check(hidden, k .. ": la Head del R15 y el pelo de piezas no se ven")
	local shirts = 0
	for _, c in model:GetChildren() do
		if c:IsA("Shirt") then
			shirts += 1
		end
	end
	check(model:FindFirstChild("BloqueCamisa") ~= nil and model:FindFirstChild("BloquePantalon") ~= nil and shirts == 1
		and (k == "Cosme" or model.EstiloBloqueGuardado:FindFirstChild("CastShirt") ~= nil), k .. ": ropa con textura puesta (la de antes, guardada)")
	local host = FaceKit.host(model)
	check(host ~= nil and host.Name == m.FaceOn and host:FindFirstChild("face") ~= nil, k .. ": la cara va en " .. m.FaceOn)
	local okMouth = true
	for e in m.Faces do
		if k == "Cosme" then
			CosmeLook.setFace(model, e)
		else
			FaceKit.expressBlock(model, e)
		end
		FaceKit.flap(model, true)
		local nm, list = FaceKit.mouths(model)
		if nm ~= 1 then
			okMouth = false
			print("    " .. e .. ": " .. table.concat(list, ", "))
		end
		FaceKit.flap(model, false)
	end
	check(okMouth, k .. ": UNA sola boca con cada expresión y hablando")
	if k == "Cosme" then
		CosmeLook.setFace(model, "Laugh")
		check(host.face.Texture == model:GetAttribute("CaraBloque_Laugh"), "Cosme: CosmeLook.setFace pone su cara dibujada (riéndose)")
		FaceKit.flap(model, true)
		check(host.face.Texture == model:GetAttribute("CaraBloque_Talk"), "Cosme: al hablar, la cara de hablar en el MISMO Decal")
		FaceKit.flap(model, false)
	end
	if k == "Familia_Mama" then
		model:SetAttribute("Mood", "Sad")
		CastLook.rest(model)
		check(host.face.Texture == model:GetAttribute("CaraBloque_Sad"), "Mamá: CastLook (emoción Triste) pone su cara dibujada triste")
		-- LOD del cliente
		local rec = LOD.track(model)
		check(rec ~= nil and #rec.Pairs >= 1, "el cliente encuentra las versiones lejanas")
		LOD.apply(rec, LOD.stateFor(120))
		check(rec.Pairs[1].Detail.Transparency == 1 and rec.Pairs[1].Lod.Transparency == 0, "de lejos: la versión lejana")
		LOD.apply(rec, LOD.stateFor(10))
		check(rec.Pairs[1].Detail.Transparency == 0 and rec.Pairs[1].Lod.Transparency == 1, "de cerca: la detallada")
		Loader.unmount(model)
		check(model:FindFirstChild("EstiloBloque") == nil and model.Head.Transparency == 0 and model:FindFirstChild("CastShirt") ~= nil
			and model:FindFirstChild("BloqueCamisa") == nil and model.Hair.Transparency == 0, "unmount: vuelve CastLook (cabeza, pelo de piezas y su ropa)")
		check((FaceKit.mouths(model)) == 1, "…con una sola boca")
	end
end

---------------------------------------------------------------------
print("\n▶ El juego lo usa")
---------------------------------------------------------------------
local npc = fs.readFile("src/server/World/Npc.luau")
check(string.find(npc, "Npc.estiloBloque(model, l)", 1, true) ~= nil and string.find(npc, "EstiloBloqueLoader", 1, true) ~= nil, "Npc.dress monta el estilo bloque (Cosme y el reparto)")
check(string.find(fs.readFile("src/server/Main.server.luau"), "EstiloBloqueLoader).start()", 1, true) ~= nil, "el servidor carga las plantillas al arrancar")
check(string.find(fs.readFile("src/client/Main.client.luau"), "EstiloBloqueLOD).init", 1, true) ~= nil, "el cliente pone las versiones lejanas")
check(L.load("src/shared/Config").EstiloBloque == true, "Config.EstiloBloque encendido (aprobado por el dueño: sale en la próxima publicación)")
check(string.find(fs.readFile("src/server/World/EstiloBloqueLoader.luau"), "EstiloBloque == false", 1, true) ~= nil or string.find(fs.readFile("src/server/World/EstiloBloqueLoader.luau"), "enabled == false", 1, true) ~= nil, "el cargador respeta Config.EstiloBloque")
local ids0 = L.load("src/shared/EstiloBloqueAssetIds")
check(type(ids0.Modelos) == "table" and type(ids0.Texturas) == "table", "shared/EstiloBloqueAssetIds")
local up = fs.readFile("scripts/upload-estilo-bloque.sh")
local iCheck = string.find(up, "revisar_mallas \"${PENDIENTES[@]}\"", 1, true)
local iKey = string.find(up, "if [ -z \"${ROBLOX_API_KEY:-}\" ]", 1, true)
check(iCheck ~= nil and iKey ~= nil and iCheck < iKey, "upload-estilo-bloque.sh: la revisión de moderación va antes de la clave")
check(string.find(up, "ropa/*.png", 1, true) ~= nil and string.find(up, "caras/*.png", 1, true) ~= nil and string.find(up, "image_of_decal", 1, true) ~= nil,
	"upload-estilo-bloque.sh: atlas, ropa y caras como Decal -> imagen")
check(string.find(fs.readFile("scripts/audit/moderacion-mallas.py"), "\"bloque\": \"assets/bloque/*.fbx\"", 1, true) ~= nil, "moderacion-mallas.py revisa assets/bloque")

L.finish("test-estilo-bloque")
