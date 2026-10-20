-- Prueba del aspecto de Cosme (shared/CosmeLook) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-cosmelook.luau
--
-- Comprueba que:
--   * se viste un R15 entero: pelo de punta (cuñas), gafas, bata, camiseta y colgante, bolígrafos,
--     cinturón, pantalón cargo, botas con suela blanca, mochila, aparato de muñeca y pistola de rayos
--   * cada pieza va SOLDADA (Weld) a una parte del cuerpo y en su sitio (CFrame = parte * C0), no choca
--     (CanCollide, CanQuery y CanTouch apagados), no pesa (Massless) y no está anclada (se mueve con la
--     animación); nada queda lejos del cuerpo
--   * las reglas del dueño: pelo plateado con un toque frío suave (no azul saturado), tubo de la pistola
--     morado, ninguna pieza verde «de babas», cejas separadas y sin babas en las caras (las PNG)
--   * las 4 caras cambian (atributo CosmeFace, el marco que se ve o el Decal con ids) y la que toca:
--     risa en los chistes, miedo en peligro, escéptico al hablar, sonrisa loca callado
--   * Cosme sale así en todas partes: Cast (Costume), Npc.dress, su casa, SceneService, StageActors y el
--     cliente cambia la cara con cada frase (ActorLife.speak)
--   * las texturas están (assets/cosme) y scripts/upload-cosme.sh las sube y escribe CosmeTextureIds

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local FakeRig = require("./lib/FakeRig")
local check = L.check

local CFrame = roblox.CFrame

local CosmeLook = L.load("src/shared/CosmeLook")
-- Sin ids para las secciones de la cara dibujada (las imágenes ya están subidas en CosmeTextureIds)
CosmeLook._setIds({})
local Cast = L.load("src/shared/LifeStory/Cast")

local function parts(model: any): { any }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function named(model: any, name: string): { any }
	local list = {}
	for _, p in parts(model) do
		if p.Name == name then
			table.insert(list, p)
		end
	end
	return list
end

---------------------------------------------------------------------
print("\n▶ Vestir a Cosme")
---------------------------------------------------------------------
local person = Cast.People.Cosme
local model = FakeRig.build(L.Instance)
-- lo que deja Npc.dress a los demás (pelo de bloque, cuello): Cosme no lo lleva
for _, name in { "Hair", "HairBack", "Fringe", "Collar" } do
	local p = L.Instance.new("Part")
	p.Name = name
	p.Parent = model
end
local count = CosmeLook.dress(model, { Skin = person.Skin, Hair = person.Hair, Costume = "Cosme" })
local folder = model:FindFirstChild(CosmeLook.FOLDER)
check(folder ~= nil and count > 100, ("piezas de Cosme en su carpeta (%d)"):format(count))
check(model:FindFirstChild("Hair") == nil and model:FindFirstChild("Fringe") == nil and model:FindFirstChild("Collar") == nil, "sin el pelo de bloque ni el cuello de los demás NPC")
check(model:GetAttribute("Costume") == "Cosme", "marcado Costume = Cosme")

local required = {
	"HairCap", "HairSpike", "GoggleStrap", "GoggleLens", "GoggleRim", "Shirt", "Lapel", "PendantGlow", "Pocket", "Pen",
	"Belt", "Buckle", "CoatTail", "CoatTailBack", "CargoPocket", "BootShaft", "Boot", "BootSole", "Backpack", "PackScreen",
	"PackTube", "WristGadget", "WristScreen", "GunBody", "GunTube", "GunDish", "GunGrip",
}
local missing = {}
for _, name in required do
	if #named(model, name) == 0 then
		table.insert(missing, name)
	end
end
check(#missing == 0, "están todas las piezas del concepto" .. (if #missing > 0 then " (faltan: " .. table.concat(missing, ", ") .. ")" else ""))
check(#named(model, "HairSpike") == CosmeLook.SpikeCount * 2, ("pelo de punta: %d púas de dos cuñas"):format(CosmeLook.SpikeCount))
check(#named(model, "Pen") == 3, "tres bolígrafos en el bolsillo")
check(#named(model, "BootSole") == 2 and #named(model, "CoatTail") == 2, "dos botas con suela y dos faldones")

---------------------------------------------------------------------
print("\n▶ Soldado, sin choques y en su sitio")
---------------------------------------------------------------------
local BODY = {}
for name in require("./lib/R15Rig").Sizes do
	BODY[name] = true
end
local bad = {}
local far = {}
local root = model:FindFirstChild("HumanoidRootPart")
for _, p in folder:GetChildren() do
	if not p:IsA("BasePart") then
		continue
	end
	local weld = p:FindFirstChild("CosmeWeld")
	local ok = weld ~= nil and weld:IsA("Weld") and weld.Part1 == p and weld.Part0 ~= nil and BODY[weld.Part0.Name] == true and weld.Part0.Parent == model
	ok = ok and not p.CanCollide and not p.CanQuery and not p.CanTouch and p.Massless and not p.Anchored
	if ok then
		local want = weld.Part0.CFrame * weld.C0
		ok = (want.Position - p.CFrame.Position).Magnitude < 1e-3
	end
	if not ok then
		table.insert(bad, p.Name)
	end
	if (p.CFrame.Position - root.CFrame.Position).Magnitude > 5 then
		table.insert(far, p.Name)
	end
end
check(#bad == 0, "todas soldadas a su parte del cuerpo, sin chocar ni pesar" .. (if #bad > 0 then " (mal: " .. table.concat(bad, ", ", 1, math.min(#bad, 6)) .. ")" else ""))
check(#far == 0, "ninguna pieza lejos del cuerpo" .. (if #far > 0 then " (" .. table.concat(far, ", ") .. ")" else ""))
local bodyCollide = false
for _, name in { "Head", "UpperTorso", "LeftFoot" } do
	local p = model:FindFirstChild(name)
	bodyCollide = bodyCollide or (p and p:FindFirstChildWhichIsA("Weld") ~= nil)
end
check(not bodyCollide, "el cuerpo sigue con sus Motor6D (las animaciones funcionan)")
local motors = 0
for _, d in model:GetDescendants() do
	if d:IsA("Motor6D") then
		motors += 1
	end
end
check(motors == 15, "las 15 articulaciones R15 intactas")

-- con una postura (brazos y piernas movidos) las piezas siguen a su parte: el C0 es relativo
local posed = FakeRig.frames({ RightShoulder = CFrame.Angles(1.2, 0, 0), RightElbow = CFrame.Angles(1, 0, 0), LeftHip = CFrame.Angles(-0.6, 0, 0) })
local tube = named(model, "GunTube")[1]
local tubeWeld = tube:FindFirstChild("CosmeWeld")
local tubeAt = posed[tubeWeld.Part0.Name] * tubeWeld.C0
check((tubeAt.Position - posed.RightHand.Position).Magnitude < 2.5, "la pistola va con la mano al levantar el brazo")

---------------------------------------------------------------------
print("\n▶ Reglas del dueño")
---------------------------------------------------------------------
local hair = named(model, "HairCap")[1].Color
local hr, hg, hb = hair.R * 255, hair.G * 255, hair.B * 255
check(hr > 205 and hb - hr < 25 and hb >= hr, ("pelo plateado con un toque frío suave (%d, %d, %d)"):format(hr, hg, hb))
check(person.Hair == hair or (math.abs(person.Hair.B - hair.B) < 0.05), "el reparto (Cast) lleva el mismo pelo")
local gun = tube.Color
check(gun.R > gun.G * 1.5 and gun.B > gun.G * 1.5, "el tubo de la pistola es morado (no verde)")
local greenGoo = {}
for _, p in folder:GetChildren() do
	if p:IsA("BasePart") and p.Name ~= "GoggleLens" and p.Name ~= "PackTube" then
		local c = p.Color
		if c.G > c.R * 1.4 and c.G > c.B * 1.15 then
			table.insert(greenGoo, p.Name)
		end
	end
end
check(#greenGoo == 0, "ninguna pieza verde «de babas» (solo los cristales verde azulado)" .. (if #greenGoo > 0 then " (" .. table.concat(greenGoo, ", ") .. ")" else ""))

---------------------------------------------------------------------
print("\n▶ Las 4 caras")
---------------------------------------------------------------------
local head = model:FindFirstChild("Head")
local function shown(): string?
	local gui = head:FindFirstChild("CosmeCara")
	if not gui or not gui.Enabled then
		return nil
	end
	local which = nil
	for _, f in gui:GetChildren() do
		if f:IsA("Frame") and f.Visible then
			if which then
				return "varias"
			end
			which = f.Name
		end
	end
	return which
end
check(model:GetAttribute("CosmeFace") == "Grin" and shown() == "Grin", "empieza con su sonrisa loca (cara dibujada sin ids)")
check(head:FindFirstChild("face").Transparency == 1, "la cara por defecto de Roblox, escondida")
local seen = {}
for _, name in CosmeLook.Faces do
	CosmeLook.setFace(model, name)
	seen[name] = model:GetAttribute("CosmeFace") == name and shown() == name
end
check(seen.Grin and seen.Skeptic and seen.Laugh and seen.Scared, "cambia entre las 4 caras (una sola a la vez)")
local gui = head:FindFirstChild("CosmeCara")
local frames = gui and #gui:GetChildren() or 0
CosmeLook.setFace(model, "Laugh")
check(#head:GetChildren() == #head:GetChildren() and gui and #gui:GetChildren() == frames, "cambiar de cara no crea más marcos")
local brows = 0
for _, d in gui:FindFirstChild("Grin"):GetDescendants() do
	if d.Name == "Ceja" then
		brows += 1
	end
end
check(brows == 2, "cejas separadas (dos), no una sola")

-- con las imágenes subidas: el Decal «face»
CosmeLook._setIds({ cosme_face_grin = "rbxassetid://101", cosme_face_skeptic = "rbxassetid://102", cosme_face_laugh = "rbxassetid://103", cosme_face_scared = "rbxassetid://104" })
local decal = head:FindFirstChild("face")
local textures = {}
for _, name in CosmeLook.Faces do
	CosmeLook.setFace(model, name)
	textures[name] = decal.Texture
end
check(textures.Grin == "rbxassetid://101" and textures.Scared == "rbxassetid://104" and decal.Transparency == 0, "con ids: el Decal «face» cambia de imagen")
check(not head:FindFirstChild("CosmeCara").Enabled, "con ids: la cara dibujada se apaga")
CosmeLook._setIds(nil)

check(CosmeLook.faceFor("Laugh", nil, true) == "Laugh" and CosmeLook.faceFor("Cheer", nil, true) == "Laugh", "se ríe con los chistes (Laugh, Cheer)")
check(CosmeLook.faceFor("Calm", "Fear", true) == "Scared" and CosmeLook.faceFor(nil, "Fear", false) == "Scared" and CosmeLook.faceFor("Surprised", nil, true) == "Scared", "asustado en peligro (Mood Fear, frase Surprised)")
check(CosmeLook.faceFor("Ask", nil, true) == "Skeptic" and CosmeLook.faceFor("Calm", nil, true) == "Skeptic" and CosmeLook.faceFor("Angry", nil, true) == "Skeptic", "escéptico en el resto de frases")
check(CosmeLook.faceFor(nil, nil, false) == "Grin", "callado: sonrisa loca")
model:SetAttribute("Mood", "Fear")
CosmeLook.rest(model)
check(model:GetAttribute("CosmeFace") == "Scared", "con Mood = Fear se queda asustado")
model:SetAttribute("Mood", nil)
CosmeLook.express(model, "Laugh", 1)
check(model:GetAttribute("CosmeFace") == "Laugh", "express: la cara de la frase al decirla")

---------------------------------------------------------------------
print("\n▶ Una sola boca (bug «Cosme tiene dos bocas»)")
---------------------------------------------------------------------
-- La cabeza que da Roblox hoy por defecto es dinámica: su cara (con boca) va pintada en la malla y se
-- mueve con FaceControls. Con la cara de Cosme encima salían dos bocas.
local FaceKit = L.load("src/shared/FaceKit")
local function mouthsOf(m: any): (number, string)
	local n, list = FaceKit.mouths(m)
	return n, table.concat(list, ", ")
end
for _, mode in { "dibujada", "imágenes" } do
	if mode == "imágenes" then
		CosmeLook._setIds({ cosme_face_grin = "rbxassetid://101", cosme_face_skeptic = "rbxassetid://102", cosme_face_laugh = "rbxassetid://103", cosme_face_scared = "rbxassetid://104", cosme_face_talk = "rbxassetid://105" })
	else
		CosmeLook._setIds({})
	end
	for _, dynamic in { true, false } do
		local rig = FakeRig.build(L.Instance, nil, nil, { DynamicHead = dynamic })
		local label = mode .. (if dynamic then ", cabeza dinámica" else ", cabeza clásica")
		CosmeLook.dress(rig, { Skin = person.Skin, Hair = person.Hair, Costume = "Cosme" })
		local h = rig:FindFirstChild("Head")
		check(h:FindFirstChildOfClass("FaceControls") == nil and h:FindFirstChildOfClass("SurfaceAppearance") == nil, label .. ": sin FaceControls ni SurfaceAppearance (no hay mandíbula de debajo)")
		check(not h:IsA("MeshPart") or h.TextureID == "", label .. ": la cara pintada en la malla, quitada")
		local n, list = mouthsOf(rig)
		check(n == 1, ("%s: callado, 1 boca (%d: %s)"):format(label, n, list))
		local okAll, worst = true, ""
		for _, name in CosmeLook.Faces do
			CosmeLook.setFace(rig, name)
			for _, open in { true, false, true } do
				CosmeLook.flap(rig, open)
				local k, l = mouthsOf(rig)
				if k ~= 1 then
					okAll = false
					worst = ("%s/%s: %d (%s)"):format(name, tostring(open), k, l)
				end
			end
			CosmeLook.flap(rig, false)
		end
		check(okAll, label .. ": cada emoción, hablando (boca abierta y cerrada), 1 boca" .. (if okAll then "" else " — " .. worst))
		local decals = 0
		for _, c in h:GetChildren() do
			if c:IsA("Decal") then
				decals += 1
			end
		end
		check(decals <= 1, ("%s: como mucho un Decal en la cabeza (%d)"):format(label, decals))
		-- la mandíbula de hablar: con imágenes cambia la imagen del MISMO Decal
		if mode == "imágenes" then
			CosmeLook.setFace(rig, "Skeptic")
			local d = h:FindFirstChild("face")
			CosmeLook.flap(rig, true)
			local opened = d.Texture
			CosmeLook.flap(rig, false)
			check(opened == "rbxassetid://105" and d.Texture == "rbxassetid://102" and h:FindFirstChild("face") == d, label .. ": hablar abre la boca en el mismo Decal y al callar vuelve a su cara")
		else
			CosmeLook.setFace(rig, "Grin")
			CosmeLook.flap(rig, true)
			local gui = h:FindFirstChild("CosmeCara")
			local talkShown = gui:FindFirstChild("Talk").Visible and not gui:FindFirstChild("Grin").Visible
			CosmeLook.flap(rig, false)
			check(talkShown and gui:FindFirstChild("Grin").Visible and not gui:FindFirstChild("Talk").Visible, label .. ": hablar cambia al marco «Talk» (sin sumar otro) y al callar vuelve")
		end
		-- vestirlo dos veces (reaparece en otra escena) no duplica nada
		CosmeLook.dress(rig, { Skin = person.Skin, Hair = person.Hair, Costume = "Cosme" })
		local n2, list2 = mouthsOf(rig)
		check(n2 == 1 and #h:GetChildren() == #h:GetChildren(), ("%s: vestido otra vez, sigue 1 boca (%d: %s)"):format(label, n2, list2))
	end
end
CosmeLook._setIds(nil)
-- Las imágenes reales: también la de hablar sube con upload-cosme.sh (sube las que aún no tienen id);
-- mientras no esté, no se mueve la boca pero nunca sale otra
check(CosmeLook.FaceFiles.Talk == "cosme_face_talk", "la cara de hablar tiene su archivo (cosme_face_talk)")
local life = fs.readFile("src/client/Controllers/ActorLife.luau")
check(life:find("CosmeLook.flap", 1, true) ~= nil and life:find("rig.Face = false", 1, true) ~= nil, "ActorLife: con cara propia mueve la boca con flap y NUNCA la mandíbula de una cabeza dinámica")

---------------------------------------------------------------------
print("\n▶ En todas partes")
---------------------------------------------------------------------
check(person.Costume == "Cosme", "Cast.People.Cosme.Costume = \"Cosme\"")
local npcSrc = fs.readFile("src/server/World/Npc.luau")
check(npcSrc:find('l.Costume == "Cosme"', 1, true) and npcSrc:find("CosmeLook).dress", 1, true), "Npc.dress lo viste con CosmeLook")
check(fs.readFile("src/server/World/CosmeHouse/NPC.luau"):find("Costume = person.Costume", 1, true), "su casa (CosmeHouse/NPC)")
check(fs.readFile("src/server/Services/SceneService.luau"):find("Costume = person.Costume", 1, true), "las misiones (SceneService)")
check(fs.readFile("src/server/LifeStory/StageActors.luau"):find("Costume = person.Costume", 1, true), "las escenas (StageActors)")
check(fs.readFile("src/client/Controllers/ActorLife.luau"):find("CosmeLook.express", 1, true), "el cliente cambia la cara con cada frase (ActorLife.speak)")

---------------------------------------------------------------------
print("\n▶ Texturas")
---------------------------------------------------------------------
local files = { "cosme_face_grin", "cosme_face_skeptic", "cosme_face_laugh", "cosme_face_scared", "cosme_face_talk", "cosme_shirt", "cosme_pants" }
local have = 0
for _, name in files do
	if fs.isFile("assets/cosme/" .. name .. ".png") then
		have += 1
	end
end
check(have == #files, ("las %d texturas en assets/cosme (scripts/cosme/gen.py)"):format(#files))
for name, file in CosmeLook.FaceFiles do
	check(table.find(files, file) ~= nil, "la cara " .. name .. " tiene su archivo")
end
local upload = fs.readFile("scripts/upload-cosme.sh")
check(upload:find("CosmeTextureIds.luau", 1, true) and upload:find('"assetType":"Decal"', 1, true) and upload:find("assets/cosme", 1, true), "upload-cosme.sh sube assets/cosme como Decal y escribe CosmeTextureIds")
check(fs.readFile("src/server/Main.server.luau"):find("CosmeTextureIds", 1, true), "el servidor pasa sus Decal a imagen (Images.resolve)")
check(fs.isFile("docs/cosme/cosme-hoja.png"), "la hoja de vista previa está en docs/cosme")

L.finish("test-cosmelook")
