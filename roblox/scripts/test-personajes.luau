-- Prueba del pase de texturas del reparto (shared/LifeStory/CastLook, shared/FaceKit) FUERA de Roblox,
-- con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-personajes.luau
--
-- Comprueba que:
--   * TODO personaje de la historia (Cast, las dos variantes de la familia y los Hondarios de Nácara) tiene
--     ficha de aspecto: cara (expresiones con Neutral y Talk), ropa (estilos que existen) y su PNG en
--     assets/personajes; las criaturas van marcadas como tales y Cosme con su módulo propio
--   * SIN ids subidos no cambia nada (el aspecto de antes: colores lisos y la cara por defecto)
--   * CON ids: una sola cara y UNA sola boca (también con la cabeza dinámica por defecto de Roblox), en cada
--     expresión, hablando (boca abierta y cerrada) y al vestirlo dos veces; ropa clásica teñida con su
--     color, manga corta con antebrazo de piel, mechones en el pelo, nada repetido
--   * qué expresión toca con cada emoción y con el Mood de la escena
--   * el módulo de ids, el script de subida (Decal, grupos, revisión de moderación de mallas) y que todos
--     los sitios donde nace un personaje de la historia le pasan su id
--   * tamaños de las texturas para móvil (≤ 1024; caras 256/512; ropa 585x559) y ninguna malla nueva

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local FakeRig = require("./lib/FakeRig")
local check = L.check

local Color3 = roblox.Color3

local Cast = L.load("src/shared/LifeStory/Cast")
local CastLook = L.load("src/shared/LifeStory/CastLook")
local FaceKit = L.load("src/shared/FaceKit")

local function pngSize(path: string): (number, number)
	local b = fs.readFile(path)
	local function u32(i: number): number
		local a, c, d, e = string.byte(b, i, i + 3)
		return ((a * 256 + c) * 256 + d) * 256 + e
	end
	return u32(17), u32(21)
end

---------------------------------------------------------------------
print("\n▶ Cada personaje tiene su ficha")
---------------------------------------------------------------------
local all = CastLook.all()
local byKey = {}
local missingSpec, badFaces, badStyle, missingFiles = {}, {}, {}, {}
local seenIds = {}
for _, spec in all do
	seenIds[spec.Id] = true
	byKey[spec.Key] = spec
	if spec.Kind == "Creature" or spec.Kind == "Own" then
		continue
	end
	if not table.find(spec.Faces, "Neutral") or not table.find(spec.Faces, "Talk") or #spec.Faces < 3 then
		table.insert(badFaces, spec.Key)
	end
	for _, e in spec.Faces do
		local f = "assets/personajes/caras/" .. CastLook.faceFile(spec.Key, e) .. ".png"
		if not fs.isFile(f) then
			table.insert(missingFiles, f)
		end
	end
	if spec.Kind ~= "Hondario" then
		if not (spec.Shirt and CastLook.ShirtStyles[spec.Shirt]) or not (spec.Pants and CastLook.PantsStyles[spec.Pants]) then
			table.insert(badStyle, spec.Key)
		end
	end
end
for id in Cast.People do
	if not seenIds[id] or not CastLook.spec(id) then
		table.insert(missingSpec, id)
	end
end
check(#missingSpec == 0, ("los %d del reparto tienen ficha de aspecto"):format(#all) .. (if #missingSpec > 0 then " (faltan: " .. table.concat(missingSpec, ", ") .. ")" else ""))
check(#badFaces == 0, "cada persona: expresiones con Neutral y Talk (la boca al hablar)" .. (if #badFaces > 0 then " (mal: " .. table.concat(badFaces, ", ") .. ")" else ""))
check(#badStyle == 0, "cada persona: estilo de camiseta y de pantalón que existen" .. (if #badStyle > 0 then " (mal: " .. table.concat(badStyle, ", ") .. ")" else ""))
check(#missingFiles == 0, "todas las caras están dibujadas en assets/personajes/caras" .. (if #missingFiles > 0 then " (faltan " .. #missingFiles .. ", p. ej. " .. missingFiles[1] .. ")" else ""))
for style in CastLook.ShirtStyles do
	check(fs.isFile("assets/personajes/ropa/" .. CastLook.shirtFile(style) .. ".png"), "plantilla de camiseta: " .. style)
end
for style in CastLook.PantsStyles do
	check(fs.isFile("assets/personajes/ropa/" .. CastLook.pantsFile(style) .. ".png"), "plantilla de pantalón: " .. style)
end
check(fs.isFile("assets/personajes/pelo/" .. CastLook.HAIR_FILE .. ".png"), "los mechones del pelo")
check(CastLook.spec("Cosme").Kind == "Own", "Cosme va con su módulo propio (shared/CosmeLook)")
check(CastLook.spec("Familia", "NPC.PAPA").Key == "Familia_Papa" and CastLook.spec("Familia", "NPC.MAMA").Key == "Familia_Mama", "la familia: Mamá y Papá según la casa")
check(CastLook.spec("Abu", "NPC.ABU_TOMAS").Key == "Abu_Tomas" and CastLook.spec("Abu").Key == "Abu_Rosa", "Abu Rosa / Abu Tomás")
check(CastLook.spec("Nacara:Ilun") ~= nil and CastLook.spec("Nacara:Oriana") ~= nil and CastLook.spec("Nacara:Ilun").Kind == "Hondario", "los Hondarios de Nácara (Ilun, Oriana…)")
local mains = 0
for _, id in Cast.Principales do
	local s = CastLook.spec(id)
	if s and (s.Kind == "Own" or #s.Faces == #CastLook.Full) then
		mains += 1
	end
end
check(mains == #Cast.Principales, ("el reparto principal con todas las expresiones (%d/%d)"):format(mains, #Cast.Principales))
check(CastLook.spec("Pip").Kind == "Robot" and CastLook.spec("Varkun").Kind == "Mask" and CastLook.spec("NILDA").Kind == "Holo", "Pip (robot), Varkun (máscara de hilo) y NILDA (holograma) con su cara especial")
check(CastLook.spec("Alumno1").Key == CastLook.spec("Alumno3").Key, "los papeles sin nombre comparten caras (arquetipos)")

---------------------------------------------------------------------
print("\n▶ Sin ids subidos: como antes")
---------------------------------------------------------------------
CastLook._setIds({})
local rig = FakeRig.build(L.Instance, nil, nil, { DynamicHead = true })
local changed = CastLook.apply(rig, "Nico", nil, { Skin = Cast.People.Nico.Skin, Shirt = Cast.People.Nico.Shirt, Pants = Cast.People.Nico.Pants, Hair = Cast.People.Nico.Hair })
local head = rig:FindFirstChild("Head")
check(not changed and rig:FindFirstChildOfClass("Shirt") == nil and rig:FindFirstChildOfClass("Pants") == nil, "sin ids no se pone ropa de textura")
check(head:FindFirstChildOfClass("FaceControls") ~= nil and head.TextureID ~= "" and rig:GetAttribute("CastFace") == nil, "sin ids la cabeza se queda como estaba (su cara de siempre, una)")

---------------------------------------------------------------------
print("\n▶ Con ids: una sola cara, una sola boca")
---------------------------------------------------------------------
local fake = {}
local n = 100
for _, spec in all do
	for _, e in spec.Faces do
		n += 1
		fake[CastLook.faceFile(spec.Key, e)] = "rbxassetid://" .. n
	end
end
for style in CastLook.ShirtStyles do
	n += 1
	fake[CastLook.shirtFile(style)] = "rbxassetid://" .. n
end
for style in CastLook.PantsStyles do
	n += 1
	fake[CastLook.pantsFile(style)] = "rbxassetid://" .. n
end
fake[CastLook.HAIR_FILE] = "rbxassetid://99"
CastLook._setIds(fake)

local function dressed(id: string, variant: string?, dynamic: boolean): any
	local m = FakeRig.build(L.Instance, nil, nil, { DynamicHead = dynamic })
	local p = Cast.People[id] or {}
	for _, name in { "Hair", "HairBack", "Fringe" } do
		local part = L.Instance.new("Part")
		part.Name = name
		part.Parent = m
	end
	CastLook.apply(m, id, variant, { Skin = p.Skin, Shirt = p.Shirt, Pants = p.Pants, Hair = p.Hair })
	return m
end

local worst = {}
local count = 0
for _, spec in all do
	if spec.Kind == "Creature" or spec.Kind == "Own" then
		continue
	end
	local variant = if spec.Key == "Familia_Papa" then "NPC.PAPA" elseif spec.Key == "Abu_Tomas" then "NPC.ABU_TOMAS" else nil
	for _, dynamic in { true, false } do
		local m = dressed(spec.Id, variant, dynamic)
		count += 1
		local k, list = FaceKit.mouths(m)
		if k ~= 1 then
			table.insert(worst, ("%s: %d (%s)"):format(spec.Key, k, table.concat(list, ", ")))
		end
	end
end
check(#worst == 0, ("cada personaje vestido (cabeza dinámica y clásica, %d): 1 boca"):format(count) .. (if #worst > 0 then " — " .. table.concat(worst, "; ", 1, math.min(#worst, 4)) else ""))

local nico = dressed("Nico", nil, true)
local nh = nico:FindFirstChild("Head")
check(nh:FindFirstChildOfClass("FaceControls") == nil and nh.TextureID == "" and nh:FindFirstChildOfClass("SurfaceAppearance") == nil, "la cara de la cabeza dinámica se quita (ni FaceControls ni textura pintada)")
local faceIds = {}
for _, e in { "Neutral", "Happy", "Sad", "Angry", "Scared" } do
	nico:SetAttribute("CastFace", e)
	CastLook.refresh(nico)
	faceIds[e] = nh:FindFirstChild("face").Texture
	local k = FaceKit.mouths(nico)
	check(k == 1, "Nico " .. e .. ": 1 boca")
end
check(faceIds.Neutral ~= faceIds.Happy and faceIds.Sad ~= faceIds.Angry, "cada expresión es otra imagen")
-- hablar
nico:SetAttribute("CastFace", "Happy")
CastLook.refresh(nico)
local before = nh:FindFirstChild("face").Texture
FaceKit.flap(nico, true)
local opened = nh:FindFirstChild("face").Texture
local decals = 0
for _, c in nh:GetChildren() do
	if c:IsA("Decal") then
		decals += 1
	end
end
FaceKit.flap(nico, false)
check(opened == fake[CastLook.faceFile("Nico", "Talk")] and decals == 1 and FaceKit.mouths(nico) == 1, "hablando: la boca abierta es la imagen Talk en el MISMO Decal (uno solo)")
check(nh:FindFirstChild("face").Texture == before, "al callar vuelve a su expresión")
-- dos veces
CastLook.apply(nico, "Nico", nil, { Skin = Cast.People.Nico.Skin, Shirt = Cast.People.Nico.Shirt, Pants = Cast.People.Nico.Pants })
local shirts, pantsN, textures = 0, 0, 0
for _, c in nico:GetChildren() do
	if c:IsA("Shirt") then
		shirts += 1
	elseif c:IsA("Pants") then
		pantsN += 1
	end
end
for _, t in nico:FindFirstChild("Hair"):GetChildren() do
	if t:IsA("Texture") then
		textures += 1
	end
end
check(shirts == 1 and pantsN == 1 and FaceKit.mouths(nico) == 1 and textures == 5, ("vestido dos veces: 1 camiseta, 1 pantalón, 1 cara, mechones sin repetir (%d/%d/%d)"):format(shirts, pantsN, textures))
local shirt = nico:FindFirstChildOfClass("Shirt")
check(shirt.ShirtTemplate == fake[CastLook.shirtFile(CastLook.spec("Nico").Shirt)], "la camiseta lleva la plantilla de su estilo")
local tint = shirt.Color3
check(math.abs(tint.R - Cast.People.Nico.Shirt.R) < 0.01 and math.abs(tint.G - Cast.People.Nico.Shirt.G) < 0.01, "teñida con su color del reparto (Clothing.Color3)")
if CastLook.ShirtStyles[CastLook.spec("Nico").Shirt].Short then
	local arm = nico:FindFirstChild("LeftLowerArm")
	check((arm.Color.R - Cast.People.Nico.Skin.R) ^ 2 < 1e-4, "manga corta: el antebrazo es de piel")
end
local hairTex = nico:FindFirstChild("Hair"):FindFirstChildOfClass("Texture")
check(hairTex and hairTex.Texture == "rbxassetid://99", "mechones (Texture) en el pelo")

---------------------------------------------------------------------
print("\n▶ Qué expresión toca")
---------------------------------------------------------------------
check(CastLook.faceFor("Laugh") == "Happy" and CastLook.faceFor("Cheer") == "Happy", "risa → Happy")
check(CastLook.faceFor("Sad") == "Sad" and CastLook.faceFor("Facepalm") == "Sad", "tristeza → Sad")
check(CastLook.faceFor("Angry") == "Angry", "enfado → Angry")
check(CastLook.faceFor("Surprised") == "Scared" and CastLook.faceFor(nil, "Fear") == "Scared", "miedo/sorpresa → Scared")
check(CastLook.faceFor("Ask") == "Neutral" and CastLook.faceFor(nil, nil) == "Neutral", "lo demás → Neutral")
local sec = dressed("Paco", nil, true)
sec:SetAttribute("Mood", "Angry")
CastLook.rest(sec)
check(sec:GetAttribute("CastFace") == "Angry" and FaceKit.mouths(sec) == 1, "un secundario sin cara de enfado pone la neutra (1 boca)")
check(sec:FindFirstChild("Head"):FindFirstChild("face").Texture == fake[CastLook.faceFile(CastLook.spec("Paco").Key, "Neutral")], "…que es su imagen Neutral")
CastLook._setIds(nil)

---------------------------------------------------------------------
print("\n▶ Ids, subida y dónde se usa")
---------------------------------------------------------------------
local ids = L.load("src/shared/PersonajesTextureIds")
local shapeOk = type(ids) == "table"
for k, v in ids do
	shapeOk = shapeOk and type(k) == "string" and k:match("^pj_[a-z0-9_]+$") ~= nil and type(v) == "string" and v:match("^rbxassetid://%d+$") ~= nil
end
check(shapeOk, "PersonajesTextureIds: { pj_… = \"rbxassetid://…\" } (vacío hasta subirlas)")
local up = fs.readFile("scripts/upload-personajes.sh")
check(up:find("PersonajesTextureIds.luau", 1, true) and up:find('"assetType":"Decal"', 1, true) and up:find("--grupo", 1, true), "upload-personajes.sh sube como Decal, por grupos, y escribe PersonajesTextureIds")
check(up:find("revisar_mallas", 1, true) ~= nil and up:find("ROBLOX_API_KEY", 1, true) ~= nil and not up:find("echo \"$ROBLOX_API_KEY", 1, true), "…revisa la moderación si hay mallas y nunca enseña la clave")
check(fs.readFile("src/server/Main.server.luau"):find("PersonajesTextureIds", 1, true) ~= nil, "el servidor pasa los Decal a imagen y repinta a los que ya estén (Main.server)")
local sites = {
	{ "src/server/LifeStory/StageActors.luau", "Id = spec.Npc" },
	{ "src/server/Services/SceneService.luau", "Id = npc" },
	{ "src/server/Services/SchoolService.luau", "Id = if Cast.People[npcId]" },
	{ "src/server/Services/BabyService.luau", 'Id = if string.find(nameKey, "ABU")' },
	{ "src/server/Services/NacaraService.luau", 'Id = "Nacara:" .. person.Id' },
	{ "src/server/Services/SeaCivService.luau", 'Id = "Nacara:" .. person.Id' },
}
for _, s in sites do
	check(fs.readFile(s[1]):find(s[2], 1, true) ~= nil, "pasa el id del reparto: " .. s[1])
end
local npcSrc = fs.readFile("src/server/World/Npc.luau")
check(npcSrc:find("CastLook).apply", 1, true) ~= nil, "Npc.dress lo viste con CastLook cuando trae Id")
check(fs.readFile("src/client/Controllers/ActorLife.luau"):find("CastLook.express", 1, true) ~= nil, "ActorLife cambia la expresión con cada frase")

---------------------------------------------------------------------
print("\n▶ Móvil y moderación")
---------------------------------------------------------------------
local bigFace, badCloth, total = {}, {}, 0
for _, dir in { "caras", "ropa", "pelo" } do
	for _, f in fs.readDir("assets/personajes/" .. dir) do
		if f:match("%.png$") then
			total += #fs.readFile("assets/personajes/" .. dir .. "/" .. f)
			local w, h = pngSize("assets/personajes/" .. dir .. "/" .. f)
			if dir == "caras" and not ((w == 512 and h == 512) or (w == 256 and h == 256)) then
				table.insert(bigFace, f)
			elseif dir == "ropa" and not (w == 585 and h == 559) then
				table.insert(badCloth, f)
			elseif w > 1024 or h > 1024 then
				table.insert(bigFace, f)
			end
		end
	end
end
check(#bigFace == 0, "caras de 256/512 px y nada de más de 1024" .. (if #bigFace > 0 then " (" .. bigFace[1] .. ")" else ""))
check(#badCloth == 0, "plantillas de ropa de 585x559 (las de Roblox)")
check(total < 12 * 1024 * 1024, ("todas las texturas pesan poco (%.1f MB)"):format(total / 1048576))
local meshes = 0
for _, dir in { "caras", "ropa", "pelo" } do
	for _, f in fs.readDir("assets/personajes/" .. dir) do
		if f:lower():match("%.fbx$") or f:lower():match("%.obj$") then
			meshes += 1
		end
	end
end
check(meshes == 0, "ninguna malla nueva (solo imágenes de caras y ropa): nada que pueda marcar la moderación de mallas")
for _, f in { "reparto-saga1-antes.jpg", "reparto-saga1-despues.jpg", "reparto-saga2-antes.jpg", "reparto-saga2-despues.jpg", "caras-expresiones.jpg", "auditoria-texturas.md" } do
	check(fs.isFile("docs/personajes/" .. f), "docs/personajes/" .. f)
end

L.finish("test-personajes")
