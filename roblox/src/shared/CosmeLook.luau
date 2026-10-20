-- CosmeLook: el aspecto de Cosme, el vecino inventor (hoja de concepto del dueño:
-- docs/cosme/, «Cosme · el inventor loco»). Lo usan todos los sitios donde sale Cosme: su casa
-- (World/CosmeHouse/NPC, por Npc.create), los actores de las misiones (SceneService) y los de las
-- escenas (LifeStory/StageActors). Todos llegan aquí por Npc.dress con Costume = "Cosme" (Cast).
--
--   CosmeLook.dress(model, look)   viste un personaje R15: pelo de científico de punta (cuñas),
--                                  gafas de laboratorio con cristales verde azulado en la frente, bata
--                                  blanca algo sucia con bolígrafos en el bolsillo, camiseta negra con
--                                  colgante que brilla, pantalón cargo marrón con cinturón y hebilla,
--                                  botas negras con suela blanca, mochila de inventor con pantalla y
--                                  luces, aparato de muñeca en el antebrazo izquierdo y la pistola de
--                                  rayos retro (tubo morado) en la mano derecha.
--                                  Todo son piezas soldadas (Weld) a su parte del cuerpo: se mueven con
--                                  las animaciones, no chocan (CanCollide/CanQuery/CanTouch = false) y
--                                  no pesan (Massless).
--   CosmeLook.setFace(model, cara) "Grin" (sonrisa loca), "Skeptic" (escéptico), "Laugh" (riéndose) o
--                                  "Scared" (asustado). Con las imágenes subidas (shared/CosmeTextureIds,
--                                  scripts/upload-cosme.sh) es el Decal «face» de la cabeza; mientras no
--                                  estén, una cara dibujada con marcos (SurfaceGui) con los mismos rasgos.
--   CosmeLook.faceFor(emocion, mood, hablando)  qué cara toca: riéndose con los chistes (Laugh, Cheer,
--                                  Happy…), asustado en peligro (Mood Fear/Hurt/Nervous/Surprise o la
--                                  frase Scared/Surprised/Nervous) y escéptico en el resto de frases;
--                                  callado, su sonrisa loca de siempre.
--   CosmeLook.express(model, emocion, segundos)  pone la cara de una frase y vuelve a la de su Mood
--                                  (lo llaman Controllers/ActorLife.speak y la casa al hablarle).
--   CosmeLook.flap(model, abierta) la boca al hablar: el MISMO Decal con la imagen cosme_face_talk (o el
--                                  marco «Talk» de la cara dibujada). Lo llama ActorLife.
--   UNA SOLA BOCA: la cabeza por defecto de Roblox es dinámica (su cara con boca va pintada en la malla y
--   se mueve con FaceControls). setFace la limpia SIEMPRE antes (shared/FaceKit.cleanHead); antes salían
--   dos bocas (docs/personajes/cosme/revision/revision.md).
--
-- Reglas del dueño (propiedad intelectual): pelo plateado con un toque frío muy suave (no azul
-- saturado), cejas normales separadas, dientes normales (sonrisa limpia un poco torcida), nada de babas
-- ni moco verde, y el tubo de la pistola morado (nunca verde).

local FaceKit = require(script.Parent.FaceKit)

local CosmeLook = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rad = math.rad

CosmeLook.TAG = "CosmeLook"
CosmeLook.FOLDER = "CosmeLook"

CosmeLook.Colors = {
	Skin = rgb(240, 204, 168),
	Hair = rgb(226, 233, 241), -- plateado con un toque frío muy suave
	HairShade = rgb(196, 207, 220),
	Brow = rgb(214, 222, 232),
	Coat = rgb(238, 238, 232),
	CoatShade = rgb(214, 214, 206),
	Dirt = rgb(196, 186, 164),
	Scorch = rgb(120, 112, 104),
	Shirt = rgb(26, 27, 31),
	Pants = rgb(74, 55, 42),
	PantsDark = rgb(56, 41, 32),
	Belt = rgb(38, 30, 26),
	Steel = rgb(186, 190, 198),
	Boot = rgb(40, 41, 47),
	Sole = rgb(236, 236, 234),
	Strap = rgb(44, 46, 52),
	Brass = rgb(196, 148, 72),
	Copper = rgb(176, 98, 62),
	Lens = rgb(52, 214, 200), -- verde azulado
	Pendant = rgb(96, 196, 255),
	Pack = rgb(56, 60, 68),
	PackFrame = rgb(104, 110, 120),
	Screen = rgb(84, 222, 255),
	Led = rgb(255, 176, 60),
	LedRed = rgb(255, 80, 70),
	Wood = rgb(112, 68, 40),
	GunTube = rgb(178, 84, 255), -- morado (la regla del dueño: nunca verde)
	Pens = { rgb(40, 90, 200), rgb(200, 50, 60), rgb(30, 30, 34) },
}

CosmeLook.Faces = { "Grin", "Skeptic", "Laugh", "Scared" }
-- La boca abierta al hablar: NO es una cara más de su emoción, es el fotograma que se alterna con la de
-- ahora mientras dice una frase (CosmeLook.flap, desde Controllers/ActorLife). Siempre en el MISMO Decal
-- (o el mismo marco de la cara dibujada): nunca hay dos bocas.
CosmeLook.TALK = "Talk"
CosmeLook.FaceFiles = {
	Grin = "cosme_face_grin",
	Skeptic = "cosme_face_skeptic",
	Laugh = "cosme_face_laugh",
	Scared = "cosme_face_scared",
	Talk = "cosme_face_talk",
}
CosmeLook.ClothFiles = { Shirt = "cosme_shirt", Pants = "cosme_pants" }

local ids: { [string]: string }? = nil
local function textureIds(): { [string]: string }
	if ids == nil then
		local ok, found = pcall(function()
			return require(script.Parent.CosmeTextureIds)
		end)
		ids = if ok and type(found) == "table" then found else {}
	end
	return ids :: { [string]: string }
end

-- Para las pruebas: otra tabla de ids (nil vuelve a leer shared/CosmeTextureIds)
function CosmeLook._setIds(list: { [string]: string }?)
	ids = list
end

-- El id de imagen de una textura (o nil si aún no se ha subido)
function CosmeLook.textureId(name: string): string?
	local id = textureIds()[name]
	if type(id) ~= "string" or id == "" then
		return nil
	end
	local ok, image = pcall(function()
		return require(script.Parent.Images).of(id)
	end)
	return if ok and type(image) == "string" and image ~= "" then image else id
end

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------

type Ctx = { Model: Model, Folder: Instance, K: number, Count: number }

-- Una pieza soldada a `attach` (parte del cuerpo) en `offset` (relativo a esa parte)
local function piece(ctx: Ctx, attach: string, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: string?): BasePart?
	local to = ctx.Model:FindFirstChild(attach)
	if not to or not to:IsA("BasePart") then
		return nil
	end
	local p: BasePart
	if shape == "Wedge" then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		p = part
	end
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = size.X * size.Y * size.Z > 0.02
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = (to :: BasePart).CFrame * offset
	local w = Instance.new("Weld")
	w.Name = "CosmeWeld"
	w.Part0 = to :: BasePart
	w.Part1 = p
	w.C0 = offset
	w.C1 = CFrame.identity
	w.Parent = p
	p:SetAttribute("CosmeOn", attach)
	require(script.Parent.BodyPieces).mark(p, to :: BasePart) -- (etiqueta BodyPiece: shared/BodyPieces)
	p.Parent = ctx.Folder
	ctx.Count += 1
	return p
end

local function glow(p: BasePart?, color: Color3, range: number, brightness: number?)
	if not p then
		return
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness or 1.2
	light.Shadows = false
	light.Parent = p
end

-- Una púa de pelo: dos cuñas espalda con espalda (un diente triangular con grosor) que sale de `root`
-- hacia `dir`. Coordenadas en la cabeza (en tamaños de cabeza: s).
local function spike(ctx: Ctx, s: Vector3, root: Vector3, dir: Vector3, length: number, width: number, thick: number, color: Color3, twist: number?)
	local d = dir.Unit
	local radial = if root.Magnitude > 1e-3 then root.Unit else Vector3.yAxis
	local side = d:Cross(radial)
	if side.Magnitude < 0.2 then
		side = d:Cross(Vector3.yAxis)
		if side.Magnitude < 0.2 then
			side = d:Cross(Vector3.xAxis)
		end
	end
	side = side.Unit
	local L = length * s.Y
	local w = width * s.Y
	local t = thick * s.Y
	local origin = V(root.X * s.X, root.Y * s.Y, root.Z * s.Z)
	local center = origin + d * (L / 2 - 0.12 * s.Y)
	-- X = grosor (radial), Y = a lo largo de la púa, Z = anchura (tangente a la cabeza)
	local zAxis = side
	local xAxis = d:Cross(zAxis).Unit
	local frame = CFrame.fromMatrix(center, xAxis, d, zAxis) * A(0, rad(twist or 0), 0)
	piece(ctx, "Head", "HairSpike", V(t, L, w / 2), frame * C(0, 0, -w / 4), color, Enum.Material.SmoothPlastic, "Wedge")
	piece(ctx, "Head", "HairSpike", V(t, L, w / 2), frame * C(0, 0, w / 4) * A(0, math.pi, 0), color, Enum.Material.SmoothPlastic, "Wedge")
end

-- Las púas: { raíz (x, y, z en tamaños de cabeza), dirección, largo, ancho, sombra? }.
-- Peinado hacia atrás y hacia arriba, con mechones que se abren a los lados (silueta de científico).
local SPIKES: { { any } } = {
	-- delante, por encima de las gafas
	{ V(-0.28, 0.5, -0.22), V(-0.25, 1, 0.05), 0.72, 0.42 },
	{ V(0.0, 0.54, -0.26), V(0, 1, -0.08), 0.85, 0.46 },
	{ V(0.28, 0.5, -0.22), V(0.3, 1, 0.05), 0.72, 0.42 },
	-- coronilla (arriba y atrás)
	{ V(-0.36, 0.52, 0.08), V(-0.55, 1, 0.45), 0.95, 0.46 },
	{ V(0.0, 0.58, 0.08), V(0, 1, 0.55), 1.08, 0.5 },
	{ V(0.36, 0.52, 0.08), V(0.55, 1, 0.45), 0.95, 0.46 },
	-- detrás arriba
	{ V(-0.32, 0.42, 0.4), V(-0.35, 0.65, 1), 1.0, 0.46, true },
	{ V(0.0, 0.46, 0.44), V(0, 0.75, 1), 1.12, 0.5, true },
	{ V(0.32, 0.42, 0.4), V(0.35, 0.65, 1), 1.0, 0.46, true },
	-- detrás en medio
	{ V(-0.36, 0.12, 0.52), V(-0.45, 0.12, 1), 0.88, 0.44 },
	{ V(0.0, 0.14, 0.56), V(0, 0.05, 1), 0.95, 0.46 },
	{ V(0.36, 0.12, 0.52), V(0.45, 0.12, 1), 0.88, 0.44 },
	-- nuca
	{ V(-0.24, -0.2, 0.5), V(-0.25, -0.45, 1), 0.6, 0.38, true },
	{ V(0.24, -0.2, 0.5), V(0.25, -0.45, 1), 0.6, 0.38, true },
	-- a los lados, abiertos
	{ V(-0.52, 0.46, -0.08), V(-0.85, 0.9, -0.1), 0.72, 0.4 },
	{ V(0.52, 0.46, -0.08), V(0.85, 0.9, -0.1), 0.72, 0.4 },
	{ V(-0.55, 0.26, 0.08), V(-1, 0.45, 0.25), 0.8, 0.44 },
	{ V(0.55, 0.26, 0.08), V(1, 0.45, 0.25), 0.8, 0.44 },
	{ V(-0.55, 0.0, 0.18), V(-1, -0.05, 0.35), 0.72, 0.42, true },
	{ V(0.55, 0.0, 0.18), V(1, -0.05, 0.35), 0.72, 0.42, true },
	{ V(-0.5, -0.2, 0.28), V(-1, -0.45, 0.45), 0.52, 0.36 },
	{ V(0.5, -0.2, 0.28), V(1, -0.45, 0.45), 0.52, 0.36 },
}
CosmeLook.SpikeCount = #SPIKES

local function buildHair(ctx: Ctx, s: Vector3)
	local col = CosmeLook.Colors
	-- La base: casquete, nuca y lados (las púas salen de aquí)
	piece(ctx, "Head", "HairCap", V(s.X * 1.1, s.Y * 0.3, s.Z * 1.08), C(0, s.Y * 0.43, s.Z * 0.05), col.Hair, Enum.Material.SmoothPlastic)
	piece(ctx, "Head", "HairBack", V(s.X * 1.1, s.Y * 0.86, s.Z * 0.3), C(0, s.Y * 0.06, s.Z * 0.45), col.Hair, Enum.Material.SmoothPlastic)
	for _, side in { -1, 1 } do
		piece(ctx, "Head", "HairSide", V(s.X * 0.14, s.Y * 0.58, s.Z * 0.72), C(side * s.X * 0.53, s.Y * 0.14, s.Z * 0.12), col.Hair, Enum.Material.SmoothPlastic)
	end
	for i, sp in SPIKES do
		local shade = sp[5] == true
		spike(ctx, s, sp[1], sp[2], sp[3], sp[4], 0.3, if shade then col.HairShade else col.Hair, (i % 3 - 1) * 14)
	end
end

local function buildGoggles(ctx: Ctx, s: Vector3)
	local col = CosmeLook.Colors
	-- La cinta alrededor de la cabeza (por delante, encima de las cejas)
	piece(ctx, "Head", "GoggleStrap", V(s.X * 1.07, s.Y * 0.13, s.Z * 1.07), C(0, s.Y * 0.3, 0), col.Strap, Enum.Material.Fabric)
	local tilt = A(rad(22), 0, 0) -- subidas a la frente
	local base = C(0, s.Y * 0.44, -s.Z * 0.52) * tilt
	for _, side in { -1, 1 } do
		local at = base * C(side * s.X * 0.23, 0, 0)
		local ring = A(0, rad(90), 0) -- cilindro mirando hacia delante
		piece(ctx, "Head", "GoggleCup", V(s.Z * 0.24, s.Y * 0.4, s.Y * 0.4), at * C(0, 0, -s.Z * 0.08) * ring, col.Strap, Enum.Material.SmoothPlastic, "Cylinder")
		piece(ctx, "Head", "GoggleRim", V(s.Z * 0.07, s.Y * 0.44, s.Y * 0.44), at * C(0, 0, -s.Z * 0.2) * ring, col.Brass, Enum.Material.Metal, "Cylinder")
		local lens = piece(ctx, "Head", "GoggleLens", V(s.Z * 0.04, s.Y * 0.31, s.Y * 0.31), at * C(0, 0, -s.Z * 0.235) * ring, col.Lens, Enum.Material.Neon, "Cylinder")
		if lens then
			lens.Transparency = 0.08
		end
		piece(ctx, "Head", "GoggleGlint", V(s.Z * 0.02, s.Y * 0.08, s.Y * 0.08), at * C(-s.X * 0.06, s.Y * 0.07, -s.Z * 0.255) * ring, rgb(235, 255, 252), Enum.Material.Neon, "Cylinder")
		-- remaches de los lados
		piece(ctx, "Head", "GoggleRivet", V(s.Y * 0.07, s.Y * 0.07, s.Y * 0.07), at * C(side * s.X * 0.2, 0, -s.Z * 0.12), col.Brass, Enum.Material.Metal, "Ball")
	end
	piece(ctx, "Head", "GoggleBridge", V(s.X * 0.1, s.Y * 0.07, s.Z * 0.1), base * C(0, 0, -s.Z * 0.12), col.Brass, Enum.Material.Metal)
end

local function buildCoat(ctx: Ctx, t: Vector3)
	local col = CosmeLook.Colors
	local k = ctx.K
	local front = -t.Z / 2
	-- La camiseta negra (la bata va abierta)
	piece(ctx, "UpperTorso", "Shirt", V(t.X * 0.44, t.Y * 0.98, 0.06 * k), C(0, -t.Y * 0.01, front - 0.01 * k), col.Shirt, Enum.Material.Fabric)
	-- Solapas y cantos de la bata
	for _, side in { -1, 1 } do
		piece(ctx, "UpperTorso", "Lapel", V(t.X * 0.15, t.Y * 0.62, 0.08 * k), C(side * t.X * 0.22, t.Y * 0.16, front - 0.03 * k) * A(0, 0, rad(side * 14)), col.Coat, Enum.Material.Fabric)
		piece(ctx, "UpperTorso", "CoatEdge", V(t.X * 0.08, t.Y * 0.5, 0.07 * k), C(side * t.X * 0.25, -t.Y * 0.24, front - 0.025 * k), col.CoatShade, Enum.Material.Fabric)
		-- cuello de la bata, levantado
		piece(ctx, "UpperTorso", "Collar", V(t.X * 0.3, t.Y * 0.2, t.Z * 0.16), C(side * t.X * 0.24, t.Y * 0.55, t.Z * 0.05) * A(rad(-12), 0, rad(-side * 8)), col.Coat, Enum.Material.Fabric)
		-- correas de la mochila por encima de los hombros
		piece(ctx, "UpperTorso", "PackStrap", V(t.X * 0.11, 0.06 * k, t.Z * 1.04), C(side * t.X * 0.3, t.Y / 2 + 0.015 * k, 0), col.Strap, Enum.Material.Fabric)
	end
	piece(ctx, "UpperTorso", "CollarBack", V(t.X * 0.62, t.Y * 0.22, t.Z * 0.14), C(0, t.Y * 0.55, t.Z * 0.42) * A(rad(-14), 0, 0), col.Coat, Enum.Material.Fabric)
	-- El colgante que brilla, con su cordón
	for _, side in { -1, 1 } do
		piece(ctx, "UpperTorso", "PendantCord", V(0.035 * k, t.Y * 0.32, 0.03 * k), C(side * t.X * 0.06, t.Y * 0.3, front - 0.05 * k) * A(0, 0, rad(-side * 20)), col.Strap)
	end
	piece(ctx, "UpperTorso", "PendantFrame", V(0.2 * k, 0.28 * k, 0.07 * k), C(0, t.Y * 0.05, front - 0.06 * k), col.Steel, Enum.Material.Metal)
	local gem = piece(ctx, "UpperTorso", "PendantGlow", V(0.12 * k, 0.19 * k, 0.05 * k), C(0, t.Y * 0.05, front - 0.09 * k), col.Pendant, Enum.Material.Neon)
	glow(gem, col.Pendant, 5, 1)
	-- Bolsillo del pecho (a su izquierda) con bolígrafos
	local pocket = C(-t.X * 0.37, -t.Y * 0.06, front - 0.035 * k)
	piece(ctx, "UpperTorso", "Pocket", V(t.X * 0.22, t.Y * 0.26, 0.05 * k), pocket, col.CoatShade, Enum.Material.Fabric)
	for i, color in col.Pens do
		local x = (i - 2) * t.X * 0.055
		piece(ctx, "UpperTorso", "Pen", V(0.06 * k, 0.3 * k, 0.06 * k), pocket * C(x, t.Y * 0.14, -0.02 * k) * A(0, 0, rad((i - 2) * 6)), color)
		piece(ctx, "UpperTorso", "PenClip", V(0.025 * k, 0.12 * k, 0.02 * k), pocket * C(x, t.Y * 0.1, -0.06 * k), col.Steel, Enum.Material.Metal)
	end
	-- Manchas y una quemadura (bata «algo sucia»)
	piece(ctx, "UpperTorso", "Stain", V(t.X * 0.12, t.Y * 0.1, 0.02 * k), C(t.X * 0.38, -t.Y * 0.3, front - 0.005 * k), col.Dirt)
	piece(ctx, "UpperTorso", "Scorch", V(t.X * 0.1, t.Y * 0.08, 0.02 * k), C(t.X * 0.3, t.Y * 0.25, front - 0.005 * k), col.Scorch)
	-- Mangas: puño y parche gris en el hombro
	for _, arm in { "Left", "Right" } do
		local ua = ctx.Model:FindFirstChild(arm .. "UpperArm") :: BasePart?
		local la = ctx.Model:FindFirstChild(arm .. "LowerArm") :: BasePart?
		if ua then
			local u = ua.Size
			piece(ctx, arm .. "UpperArm", "SleeveBand", V(u.X * 1.06, u.Y * 0.16, u.Z * 1.06), C(0, u.Y * 0.1, 0), col.CoatShade, Enum.Material.Fabric)
		end
		if la then
			local l = la.Size
			piece(ctx, arm .. "LowerArm", "Cuff", V(l.X * 1.1, l.Y * 0.22, l.Z * 1.1), C(0, -l.Y * 0.4, 0), col.Coat, Enum.Material.Fabric)
		end
	end
	piece(ctx, "RightUpperArm", "Stain", V(0.02 * k, 0.16 * k, 0.2 * k), C(0.51 * (ctx.Model:FindFirstChild("RightUpperArm") :: BasePart).Size.X, -0.15 * k, 0), col.Dirt)
	-- La bata por la cadera (abierta por delante: se ve el cinturón)
	local lower = ctx.Model:FindFirstChild("LowerTorso") :: BasePart?
	if lower then
		local l = lower.Size
		for _, side in { -1, 1 } do
			piece(ctx, "LowerTorso", "CoatHip", V(l.X * 0.36, l.Y * 1.04, l.Z * 1.08), C(side * l.X * 0.34, 0, 0), col.Coat, Enum.Material.Fabric)
		end
		piece(ctx, "LowerTorso", "CoatHipBack", V(l.X * 1.06, l.Y * 1.04, 0.07 * k), C(0, 0, l.Z / 2 + 0.03 * k), col.Coat, Enum.Material.Fabric)
		-- Cinturón y hebilla
		piece(ctx, "LowerTorso", "Belt", V(l.X * 0.4, l.Y * 0.5, 0.05 * k), C(0, l.Y * 0.18, -l.Z / 2 - 0.015 * k), col.Belt, Enum.Material.Leather)
		piece(ctx, "LowerTorso", "Buckle", V(0.3 * k, 0.2 * k, 0.05 * k), C(0, l.Y * 0.18, -l.Z / 2 - 0.045 * k), col.Steel, Enum.Material.Metal)
		piece(ctx, "LowerTorso", "BuckleHole", V(0.16 * k, 0.08 * k, 0.03 * k), C(0, l.Y * 0.18, -l.Z / 2 - 0.07 * k), col.Belt, Enum.Material.Metal)
	end
	-- Los faldones de la bata, en los muslos (se mueven con cada pierna: no atraviesan al andar)
	for _, leg in { "Left", "Right" } do
		local part = ctx.Model:FindFirstChild(leg .. "UpperLeg") :: BasePart?
		if part then
			local u = part.Size
			local out = if leg == "Right" then 1 else -1
			local len = u.Y * 1.28
			local y = -u.Y * 0.14
			piece(ctx, leg .. "UpperLeg", "CoatTail", V(0.07 * k, len, u.Z * 1.12), C(out * (u.X / 2 + 0.035 * k), y, 0), col.Coat, Enum.Material.Fabric)
			piece(ctx, leg .. "UpperLeg", "CoatTailBack", V(u.X * 1.1, len, 0.07 * k), C(out * u.X * 0.03, y, u.Z / 2 + 0.035 * k), col.Coat, Enum.Material.Fabric)
			piece(ctx, leg .. "UpperLeg", "CoatTailFront", V(u.X * 0.42, len, 0.07 * k), C(out * u.X * 0.32, y, -u.Z / 2 - 0.035 * k), col.Coat, Enum.Material.Fabric)
			piece(ctx, leg .. "UpperLeg", "CoatHem", V(u.X * 0.44, 0.05 * k, 0.08 * k), C(out * u.X * 0.32, y - len / 2 + 0.03 * k, -u.Z / 2 - 0.04 * k), col.Dirt, Enum.Material.Fabric)
		end
	end
	piece(ctx, "LeftUpperLeg", "Stain", V(0.08 * k, 0.2 * k, 0.02 * k), C(-0.25 * k, -0.5 * k, -0.6 * k), col.Dirt)
end

local function buildLegs(ctx: Ctx)
	local col = CosmeLook.Colors
	local k = ctx.K
	for _, leg in { "Left", "Right" } do
		local out = if leg == "Right" then 1 else -1
		local lower = ctx.Model:FindFirstChild(leg .. "LowerLeg") :: BasePart?
		local foot = ctx.Model:FindFirstChild(leg .. "Foot") :: BasePart?
		if lower then
			local l = lower.Size
			-- bolsillo cargo y rodillera
			piece(ctx, leg .. "LowerLeg", "CargoPocket", V(0.07 * k, l.Y * 0.32, l.Z * 0.6), C(out * (l.X / 2 + 0.03 * k), l.Y * 0.12, 0), col.PantsDark, Enum.Material.Fabric)
			piece(ctx, leg .. "LowerLeg", "CargoFlap", V(0.08 * k, l.Y * 0.07, l.Z * 0.64), C(out * (l.X / 2 + 0.04 * k), l.Y * 0.28, 0), col.Pants, Enum.Material.Fabric)
			piece(ctx, leg .. "LowerLeg", "KneeStrap", V(l.X * 1.06, l.Y * 0.08, l.Z * 1.06), C(0, l.Y * 0.34, 0), col.PantsDark, Enum.Material.Fabric)
			-- caña de la bota
			piece(ctx, leg .. "LowerLeg", "BootShaft", V(l.X * 1.12, l.Y * 0.36, l.Z * 1.12), C(0, -l.Y * 0.33, 0), col.Boot, Enum.Material.Leather)
			piece(ctx, leg .. "LowerLeg", "BootCuff", V(l.X * 1.16, l.Y * 0.06, l.Z * 1.16), C(0, -l.Y * 0.15, 0), col.Strap, Enum.Material.Leather)
		end
		if foot then
			local f = foot.Size
			piece(ctx, leg .. "Foot", "Boot", V(f.X * 1.16, f.Y * 0.95, f.Z * 1.3), C(0, f.Y * 0.2, -f.Z * 0.12), col.Boot, Enum.Material.Leather)
			piece(ctx, leg .. "Foot", "BootToe", V(f.X * 1.1, f.Y * 0.6, f.Z * 0.3), C(0, f.Y * 0.05, -f.Z * 0.7), col.Boot, Enum.Material.Leather)
			-- suela blanca, gorda (a ras de la planta: no se hunde en el suelo)
			piece(ctx, leg .. "Foot", "BootSole", V(f.X * 1.22, f.Y * 0.5, f.Z * 1.42), C(0, -f.Y * 0.25, -f.Z * 0.14), col.Sole, Enum.Material.SmoothPlastic)
			piece(ctx, leg .. "Foot", "BootLace", V(f.X * 0.5, 0.04 * k, f.Z * 0.4), C(0, f.Y * 0.69, -f.Z * 0.4), col.Steel, Enum.Material.Fabric)
		end
	end
end

local function buildBackpack(ctx: Ctx, t: Vector3)
	local col = CosmeLook.Colors
	local k = ctx.K
	local depth = t.Z * 0.56
	local cz = t.Z / 2 + depth / 2
	local w, h = t.X * 0.76, t.Y * 0.88
	local body = C(0, -t.Y * 0.03, cz)
	piece(ctx, "UpperTorso", "Backpack", V(w, h, depth), body, col.Pack, Enum.Material.Metal)
	-- marco de metal en las esquinas
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			piece(ctx, "UpperTorso", "PackRail", V(0.1 * k, h * 1.04, 0.1 * k), body * C(sx * w / 2, 0, sz * depth / 2), col.PackFrame, Enum.Material.Metal)
		end
		piece(ctx, "UpperTorso", "PackBar", V(w * 1.04, 0.1 * k, 0.1 * k), body * C(0, sx * h / 2, depth / 2), col.PackFrame, Enum.Material.Metal)
	end
	-- pantalla en la espalda y tubos de luz a los lados
	local back = body * C(0, h * 0.04, depth / 2)
	piece(ctx, "UpperTorso", "PackScreenFrame", V(w * 0.42, h * 0.5, 0.08 * k), back * C(0, 0, 0.03 * k), col.Strap, Enum.Material.Metal)
	local screen = piece(ctx, "UpperTorso", "PackScreen", V(w * 0.32, h * 0.4, 0.05 * k), back * C(0, 0, 0.06 * k), col.Screen, Enum.Material.Neon)
	glow(screen, col.Screen, 6, 1)
	for _, sx in { -1, 1 } do
		piece(ctx, "UpperTorso", "PackTube", V(h * 0.62, 0.14 * k, 0.14 * k), back * C(sx * w * 0.36, 0, 0.04 * k) * A(0, 0, rad(90)), col.Lens, Enum.Material.Neon, "Cylinder")
		for _, sy in { -1, 1 } do
			piece(ctx, "UpperTorso", "PackClamp", V(0.06 * k, 0.2 * k, 0.2 * k), back * C(sx * w * 0.36, sy * h * 0.33, 0.04 * k) * A(0, 0, rad(90)), col.Brass, Enum.Material.Metal, "Cylinder")
		end
	end
	-- lucecitas, una antena corta y un ventilador
	for i, color in { col.Led, col.LedRed, col.Screen } do
		piece(ctx, "UpperTorso", "PackLed", V(0.08 * k, 0.08 * k, 0.05 * k), back * C((i - 2) * w * 0.1, -h * 0.34, 0.04 * k), color, Enum.Material.Neon)
	end
	piece(ctx, "UpperTorso", "PackAntenna", V(0.05 * k, 0.5 * k, 0.05 * k), body * C(w * 0.36, h / 2 + 0.25 * k, depth * 0.2), col.Steel, Enum.Material.Metal)
	piece(ctx, "UpperTorso", "PackAntennaTip", V(0.1 * k, 0.1 * k, 0.1 * k), body * C(w * 0.36, h / 2 + 0.52 * k, depth * 0.2), col.LedRed, Enum.Material.Neon, "Ball")
	piece(ctx, "UpperTorso", "PackFan", V(0.06 * k, w * 0.34, w * 0.34), body * C(-w / 2 - 0.02 * k, h * 0.12, 0), col.Strap, Enum.Material.Metal, "Cylinder")
end

local function buildWrist(ctx: Ctx)
	local col = CosmeLook.Colors
	local k = ctx.K
	local arm = ctx.Model:FindFirstChild("LeftLowerArm") :: BasePart?
	if not arm then
		return
	end
	local a = arm.Size
	local at = C(0, -a.Y * 0.12, 0)
	piece(ctx, "LeftLowerArm", "WristGadget", V(a.X * 1.16, a.Y * 0.46, a.Z * 1.16), at, col.Pack, Enum.Material.Metal)
	piece(ctx, "LeftLowerArm", "WristBand", V(a.X * 1.2, a.Y * 0.08, a.Z * 1.2), at * C(0, a.Y * 0.2, 0), col.PackFrame, Enum.Material.Metal)
	-- la pantalla, por fuera del antebrazo izquierdo
	local face = at * C(-a.X * 0.58, 0, -a.Z * 0.04)
	piece(ctx, "LeftLowerArm", "WristScreenFrame", V(0.12 * k, a.Y * 0.4, a.Z * 0.8), face * C(-0.05 * k, 0, 0), col.Strap, Enum.Material.Metal)
	local screen = piece(ctx, "LeftLowerArm", "WristScreen", V(0.06 * k, a.Y * 0.3, a.Z * 0.62), face * C(-0.1 * k, 0, 0), col.Screen, Enum.Material.Neon)
	glow(screen, col.Screen, 4, 0.9)
	piece(ctx, "LeftLowerArm", "WristKnob", V(0.12 * k, 0.12 * k, 0.12 * k), at * C(0, 0, -a.Z * 0.62) * A(0, rad(90), 0), col.Brass, Enum.Material.Metal, "Cylinder")
	piece(ctx, "LeftLowerArm", "WristLed", V(0.07 * k, 0.07 * k, 0.07 * k), at * C(-a.X * 0.4, a.Y * 0.2, -a.Z * 0.58), col.Led, Enum.Material.Neon)
end

-- La pistola de rayos: retro, de latón y cobre, con un tubo de cristal MORADO encima y un emisor de
-- platos en la boca. En la mano derecha, apuntando hacia delante (con el brazo caído).
local function buildRayGun(ctx: Ctx)
	local col = CosmeLook.Colors
	local k = ctx.K * 1.5 -- (del tamaño de la mano de bloques: si no, parecía de juguete)
	if not ctx.Model:FindFirstChild("RightHand") then
		return
	end
	local axis = A(0, rad(90), 0) -- cilindros a lo largo de -Z (hacia delante)
	local barrel = C(0, 0.12 * k, -0.42 * k)
	piece(ctx, "RightHand", "GunGrip", V(0.2 * k, 0.5 * k, 0.28 * k), C(0, -0.08 * k, 0.04 * k) * A(rad(-12), 0, 0), col.Wood, Enum.Material.Wood)
	piece(ctx, "RightHand", "GunBody", V(0.78 * k, 0.32 * k, 0.32 * k), barrel * axis, col.Brass, Enum.Material.Metal, "Cylinder")
	piece(ctx, "RightHand", "GunBack", V(0.14 * k, 0.4 * k, 0.4 * k), barrel * C(0, 0, 0.38 * k) * axis, col.Copper, Enum.Material.Metal, "Cylinder")
	for i = 0, 2 do
		piece(ctx, "RightHand", "GunRing", V(0.05 * k, 0.4 * k, 0.4 * k), barrel * C(0, 0, (0.18 - i * 0.16) * k) * axis, col.Copper, Enum.Material.Metal, "Cylinder")
	end
	-- emisor: dos platos y la punta que brilla
	piece(ctx, "RightHand", "GunNeck", V(0.22 * k, 0.16 * k, 0.16 * k), barrel * C(0, 0, -0.48 * k) * axis, col.Brass, Enum.Material.Metal, "Cylinder")
	piece(ctx, "RightHand", "GunDish", V(0.05 * k, 0.5 * k, 0.5 * k), barrel * C(0, 0, -0.58 * k) * axis, col.Copper, Enum.Material.Metal, "Cylinder")
	piece(ctx, "RightHand", "GunDish", V(0.05 * k, 0.36 * k, 0.36 * k), barrel * C(0, 0, -0.68 * k) * axis, col.Brass, Enum.Material.Metal, "Cylinder")
	local tip = piece(ctx, "RightHand", "GunTip", V(0.16 * k, 0.16 * k, 0.16 * k), barrel * C(0, 0, -0.76 * k), col.GunTube, Enum.Material.Neon, "Ball")
	glow(tip, col.GunTube, 4, 1)
	-- el tubo morado encima, en dos abrazaderas
	local tube = piece(ctx, "RightHand", "GunTube", V(0.56 * k, 0.15 * k, 0.15 * k), barrel * C(0, 0.24 * k, 0.02 * k) * axis, col.GunTube, Enum.Material.Neon, "Cylinder")
	glow(tube, col.GunTube, 5, 1.2)
	local glass = piece(ctx, "RightHand", "GunTubeGlass", V(0.6 * k, 0.21 * k, 0.21 * k), barrel * C(0, 0.24 * k, 0.02 * k) * axis, rgb(220, 200, 255), Enum.Material.Glass, "Cylinder")
	if glass then
		glass.Transparency = 0.6
	end
	for _, z in { -0.2, 0.24 } do
		piece(ctx, "RightHand", "GunClamp", V(0.06 * k, 0.26 * k, 0.26 * k), barrel * C(0, 0.24 * k, z * k) * axis, col.Copper, Enum.Material.Metal, "Cylinder")
		piece(ctx, "RightHand", "GunPost", V(0.06 * k, 0.12 * k, 0.06 * k), barrel * C(0, 0.14 * k, z * k), col.Copper, Enum.Material.Metal)
	end
	-- manómetro en el lado y aletas detrás
	piece(ctx, "RightHand", "GunGauge", V(0.05 * k, 0.16 * k, 0.16 * k), barrel * C(0.17 * k, 0, 0.1 * k), rgb(245, 238, 220), Enum.Material.SmoothPlastic, "Cylinder")
	piece(ctx, "RightHand", "GunGaugeNeedle", V(0.02 * k, 0.07 * k, 0.015 * k), barrel * C(0.2 * k, 0.015 * k, 0.1 * k) * A(rad(35), 0, 0), col.LedRed)
	for _, sx in { -1, 1 } do
		piece(ctx, "RightHand", "GunFin", V(0.04 * k, 0.22 * k, 0.26 * k), barrel * C(sx * 0.16 * k, 0.1 * k, 0.32 * k) * A(0, 0, rad(sx * 25)), col.Copper, Enum.Material.Metal, "Wedge")
	end
	piece(ctx, "RightHand", "GunTrigger", V(0.05 * k, 0.12 * k, 0.05 * k), C(0, 0.0, -0.2 * k), col.Steel, Enum.Material.Metal)
end

-- Quita lo que le hubiera puesto otro vestidor (pelo, cuello, mochila de colegio, ropa clásica…)
local function clear(model: Model)
	for _, d in model:GetChildren() do
		if d.Name == CosmeLook.FOLDER or d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			d:Destroy()
		elseif d:IsA("BasePart") and (d.Name == "Hair" or d.Name == "HairBack" or d.Name == "Fringe" or d.Name == "Collar" or d.Name == "SchoolBackpack") then
			d:Destroy()
		end
	end
end

local function paint(model: Model, names: { string }, color: Color3)
	for _, name in names do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
end

---------------------------------------------------------------------
-- Caras
---------------------------------------------------------------------

-- La cara dibujada (mientras no estén subidas las imágenes): ojos grandes con borde, pupilas, párpados,
-- cejas pobladas separadas y la boca. Medidas en escala de la cara (0..1).
type Eye = { Open: number, Pupil: Vector2?, PupilSize: number?, Lid: number?, Size: number? }
type FaceSpec = { Eyes: { Eye }, Brows: { { number } }, Mouth: { number }, Teeth: number, Tongue: boolean }

local FACE_SPECS: { [string]: FaceSpec } = {
	-- ojo izquierdo de la imagen = derecho de Cosme
	Grin = {
		Eyes = { { Open = 1, Pupil = Vector2.new(0.55, 0.52), PupilSize = 0.3 }, { Open = 1, Pupil = Vector2.new(0.45, 0.6), PupilSize = 0.3, Lid = 0.48 } },
		Brows = { { 0.32, 0.3, -10 }, { 0.68, 0.34, 14 } }, -- (x, y, giro)
		Mouth = { 0.52, 0.76, 0.5, 0.15, -4 }, -- (x, y, ancho, alto, giro)
		Teeth = 0.5,
		Tongue = false,
	},
	Skeptic = {
		Eyes = { { Open = 1, Pupil = Vector2.new(0.68, 0.6), PupilSize = 0.28, Lid = 0.5 }, { Open = 1, Pupil = Vector2.new(0.68, 0.62), PupilSize = 0.28, Lid = 0.56 } },
		Brows = { { 0.32, 0.27, -14 }, { 0.68, 0.36, 6 } },
		Mouth = { 0.56, 0.78, 0.3, 0.045, -7 },
		Teeth = 0,
		Tongue = false,
	},
	Laugh = {
		Eyes = { { Open = 0 }, { Open = 0 } },
		Brows = { { 0.32, 0.27, -8 }, { 0.68, 0.27, 8 } },
		Mouth = { 0.5, 0.76, 0.52, 0.24, 0 },
		Teeth = 0.32,
		Tongue = true,
	},
	Scared = {
		Eyes = { { Open = 1, Pupil = Vector2.new(0.5, 0.5), PupilSize = 0.16, Size = 0.32 }, { Open = 1, Pupil = Vector2.new(0.5, 0.5), PupilSize = 0.16, Size = 0.32 } },
		Brows = { { 0.31, 0.24, 16 }, { 0.69, 0.24, -16 } },
		Mouth = { 0.5, 0.8, 0.2, 0.15, 0 },
		Teeth = 0.25,
		Tongue = false,
	},
	-- hablando: los ojos de siempre y la boca abierta a media altura (se alterna con la de su emoción)
	Talk = {
		Eyes = { { Open = 1, Pupil = Vector2.new(0.55, 0.52), PupilSize = 0.3 }, { Open = 1, Pupil = Vector2.new(0.48, 0.58), PupilSize = 0.3, Lid = 0.4 } },
		Brows = { { 0.32, 0.29, -10 }, { 0.68, 0.32, 10 } },
		Mouth = { 0.51, 0.78, 0.34, 0.17, -3 },
		Teeth = 0.3,
		Tongue = true,
	},
}

local function frame(parent: Instance, name: string, color: Color3, pos: UDim2, size: UDim2, round: number?, stroke: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = pos
	f.Size = size
	if round then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(round, 0)
		c.Parent = f
	end
	if stroke then
		local s = Instance.new("UIStroke")
		s.Thickness = stroke
		s.Color = rgb(30, 22, 20)
		s.Parent = f
	end
	f.Parent = parent
	return f
end

local function drawOne(gui: Instance, name: string, skin: Color3)
	local spec = FACE_SPECS[name]
	local root = Instance.new("Frame")
	root.Name = name
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Visible = false
	root.Parent = gui
	local col = CosmeLook.Colors
	for i, eye in spec.Eyes do
		local x = if i == 1 then 0.33 else 0.67
		local size = eye.Size or 0.27
		if eye.Open <= 0 then
			-- ojos cerrados de risa: arcos hacia arriba (^ ^)
			local arc = frame(root, "OjoCerrado", rgb(30, 22, 20), UDim2.fromScale(x, 0.5), UDim2.fromScale(size * 0.9, 0.035), 1)
			arc.Rotation = if i == 1 then -14 else 14
			local arc2 = frame(root, "OjoCerrado", rgb(30, 22, 20), UDim2.fromScale(x + (if i == 1 then 0.06 else -0.06), 0.5), UDim2.fromScale(size * 0.5, 0.035), 1)
			arc2.Rotation = if i == 1 then 18 else -18
		else
			local white = frame(root, "Ojo", rgb(252, 252, 248), UDim2.fromScale(x, 0.5), UDim2.fromScale(size, size), 0.5, 3)
			local p = eye.Pupil or Vector2.new(0.5, 0.5)
			local ps = eye.PupilSize or 0.3
			frame(white, "Pupila", rgb(20, 16, 16), UDim2.fromScale(p.X, p.Y), UDim2.fromScale(ps, ps), 0.5)
			frame(white, "Brillo", rgb(255, 255, 255), UDim2.fromScale(p.X - ps * 0.2, p.Y - ps * 0.22), UDim2.fromScale(ps * 0.3, ps * 0.3), 0.5)
			if eye.Lid then
				local lidH = eye.Lid
				local lid = frame(root, "Parpado", skin, UDim2.fromScale(x, 0.5 - size / 2 + size * lidH / 2 - 0.01), UDim2.fromScale(size * 1.12, size * lidH + 0.02))
				lid.ZIndex = 2
				local line = frame(root, "LineaParpado", rgb(30, 22, 20), UDim2.fromScale(x, 0.5 - size / 2 + size * lidH), UDim2.fromScale(size * 1.04, 0.03), 1)
				line.ZIndex = 3
			end
		end
		-- ojeras (arruguitas de científico)
		frame(root, "Ojera", skin:Lerp(rgb(150, 100, 80), 0.45), UDim2.fromScale(x, 0.5 + size / 2 + 0.035), UDim2.fromScale(size * 0.6, 0.018), 1)
	end
	for _, b in spec.Brows do
		local brow = frame(root, "Ceja", col.Brow, UDim2.fromScale(b[1], b[2]), UDim2.fromScale(0.26, 0.07), 0.4, 2)
		brow.Rotation = b[3]
		brow.ZIndex = 4
	end
	frame(root, "Nariz", skin:Lerp(rgb(160, 100, 80), 0.35), UDim2.fromScale(0.5, 0.63), UDim2.fromScale(0.07, 0.05), 0.5)
	local m = spec.Mouth
	local mouth = frame(root, "Boca", rgb(96, 28, 34), UDim2.fromScale(m[1], m[2]), UDim2.fromScale(m[3], m[4]), if m[4] > 0.1 then 0.45 else 0.5, 3)
	mouth.Rotation = m[5]
	mouth.ClipsDescendants = true
	if spec.Teeth > 0 then
		-- dientes normales: una fila limpia, alguno un poco torcido
		local teeth = frame(mouth, "Dientes", rgb(250, 248, 240), UDim2.new(0.5, 0, spec.Teeth / 2, 0), UDim2.fromScale(0.92, spec.Teeth))
		for j = 1, 5 do
			local gap = frame(teeth, "Separa", rgb(200, 196, 186), UDim2.fromScale(j / 6, 0.5), UDim2.fromScale(0.012, 0.9))
			gap.Rotation = if j == 2 then 8 elseif j == 4 then -6 else 0
		end
	end
	if spec.Tongue then
		frame(mouth, "Lengua", rgb(226, 98, 104), UDim2.fromScale(0.5, 0.85), UDim2.fromScale(0.55, 0.4), 0.5)
	end
end



-- Las 4 caras dibujadas en un SurfaceGui de la cabeza (se enseña una: Visible). Se hace una vez (en el
-- servidor, así la ven todos); cambiar de cara solo cambia qué marco se ve, también en el cliente.
local function faceGui(head: BasePart): SurfaceGui
	local found = head:FindFirstChild("CosmeCara")
	if found and found:IsA("SurfaceGui") then
		return found
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "CosmeCara"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(240, 240)
	gui.LightInfluence = 1
	for _, name in CosmeLook.Faces do
		drawOne(gui, name, head.Color)
	end
	drawOne(gui, CosmeLook.TALK, head.Color)
	gui.Parent = head
	return gui
end

-- Pone una de las 4 caras ("Grin", "Skeptic", "Laugh", "Scared")
function CosmeLook.setFace(model: Model, name: string)
	if not FACE_SPECS[name] then
		name = "Grin"
	end
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	model:SetAttribute("CosmeFace", name)
	-- La cabeza por defecto de Roblox es dinámica: trae su propia cara (con boca) pintada en la malla y
	-- FaceControls. Fuera SIEMPRE antes de poner la de Cosme: si no, dos bocas (shared/FaceKit).
	FaceKit.cleanHead(head)
	local id = CosmeLook.textureId(CosmeLook.FaceFiles[name])
	if id then
		FaceKit.set(model, id, CosmeLook.textureId(CosmeLook.FaceFiles[CosmeLook.TALK]))
		local gui = head:FindFirstChild("CosmeCara")
		if gui and gui:IsA("SurfaceGui") then
			gui.Enabled = false
		end
	else
		model:SetAttribute(FaceKit.ATTR_IMAGE, nil)
		model:SetAttribute(FaceKit.ATTR_TALK, nil)
		local decal = head:FindFirstChild(FaceKit.DECAL)
		if decal and decal:IsA("Decal") then
			decal.Transparency = 1 -- (la cara por defecto de Roblox no: la de Cosme va dibujada)
		end
		local gui = faceGui(head)
		gui.Enabled = true
		for _, child in gui:GetChildren() do
			if child:IsA("Frame") then
				child.Visible = child.Name == name
			end
		end
	end
end

-- Boca abierta o cerrada mientras habla (Controllers/ActorLife). Con las imágenes cambia la imagen del
-- MISMO Decal; con la cara dibujada, el marco «Talk» sustituye al de su emoción. Solo en la pantalla de
-- quien lo llama; al cerrar vuelve exactamente a la cara de su emoción.
function CosmeLook.flap(model: Model, open: boolean)
	if FaceKit.flap(model, open) then
		return
	end
	local head = model:FindFirstChild("Head")
	local gui = head and head:FindFirstChild("CosmeCara")
	if not gui or not gui:IsA("SurfaceGui") or not gui.Enabled then
		return
	end
	local current = model:GetAttribute("CosmeFace")
	local show = if open then CosmeLook.TALK elseif type(current) == "string" then current else "Grin"
	for _, child in gui:GetChildren() do
		if child:IsA("Frame") then
			child.Visible = child.Name == show
		end
	end
end

local LAUGH = { Laugh = true, Cheer = true, Happy = true, Dance = true, Clap = true }
local FEAR = { Scared = true, Surprised = true, Nervous = true, Hurt = true }
local FEAR_MOOD = { Fear = true, Hurt = true, Nervous = true, Surprise = true }
local SKEPTIC_MOOD = { Angry = true, Sad = true, Shame = true }

-- Qué cara toca. emotion: la de la frase (shared/LifeStory/Emotion); mood: la que dura (ActorMoods);
-- speaking: si está diciendo una frase ahora.
function CosmeLook.faceFor(emotion: string?, mood: string?, speaking: boolean?): string
	if emotion and LAUGH[emotion] then
		return "Laugh"
	end
	if (emotion and FEAR[emotion]) or (mood and FEAR_MOOD[mood]) then
		return "Scared"
	end
	if speaking then
		return "Skeptic"
	end
	if mood and SKEPTIC_MOOD[mood] then
		return "Skeptic"
	end
	if mood == "Joy" then
		return "Laugh"
	end
	return "Grin"
end

-- La cara de base (sin frase): la de su emoción que dura
function CosmeLook.rest(model: Model)
	local mood = model:GetAttribute("Mood")
	CosmeLook.setFace(model, CosmeLook.faceFor(nil, if type(mood) == "string" then mood else nil, false))
end

-- La cara de una frase durante `seconds`; luego vuelve a la de base
function CosmeLook.express(model: Model?, emotion: string?, seconds: number?)
	if not model or model:GetAttribute("CosmeFace") == nil then
		return
	end
	local mood = model:GetAttribute("Mood")
	CosmeLook.setFace(model, CosmeLook.faceFor(emotion, if type(mood) == "string" then mood else nil, true))
	local token = (tonumber(model:GetAttribute("CosmeFaceToken")) or 0) + 1
	model:SetAttribute("CosmeFaceToken", token)
	task.delay(math.max(1, seconds or 3) + 0.3, function()
		if model.Parent and model:GetAttribute("CosmeFaceToken") == token then
			CosmeLook.rest(model)
		end
	end)
end

---------------------------------------------------------------------
-- Vestir
---------------------------------------------------------------------

local SKIN_PARTS = { "Head", "LeftHand", "RightHand" }
local COAT_PARTS = { "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" }
local PANTS_PARTS = { "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }
local FEET = { "LeftFoot", "RightFoot" }

-- Viste a Cosme. look (opcional): { Skin, Hair } del reparto (Cast.People.Cosme)
function CosmeLook.dress(model: Model, look: { [string]: any }?): number
	local l = look or {}
	local col = CosmeLook.Colors
	clear(model)
	local skin = if typeof(l.Skin) == "Color3" then l.Skin else col.Skin
	paint(model, SKIN_PARTS, skin)
	paint(model, COAT_PARTS, col.Coat)
	paint(model, PANTS_PARTS, col.Pants)
	paint(model, FEET, col.Boot)
	local folder = Instance.new("Folder")
	folder.Name = CosmeLook.FOLDER
	folder.Parent = model
	local torso = model:FindFirstChild("UpperTorso") :: BasePart?
	local ctx: Ctx = { Model = model, Folder = folder, K = if torso then torso.Size.X / 2 else 1, Count = 0 }
	local head = model:FindFirstChild("Head") :: BasePart?
	if head then
		buildHair(ctx, head.Size)
		buildGoggles(ctx, head.Size)
	end
	if torso then
		buildCoat(ctx, torso.Size)
		buildBackpack(ctx, torso.Size)
	end
	buildLegs(ctx)
	buildWrist(ctx)
	buildRayGun(ctx)
	-- Ropa clásica (bata con manchas, pantalón cargo) si ya están subidas sus plantillas
	local shirtId = CosmeLook.textureId(CosmeLook.ClothFiles.Shirt)
	local pantsId = CosmeLook.textureId(CosmeLook.ClothFiles.Pants)
	if shirtId then
		local shirt = Instance.new("Shirt")
		shirt.Name = "CosmeShirt"
		shirt.ShirtTemplate = shirtId
		shirt.Parent = model
	end
	if pantsId then
		local pants = Instance.new("Pants")
		pants.Name = "CosmePants"
		pants.PantsTemplate = pantsId
		pants.Parent = model
	end
	model:SetAttribute("Costume", "Cosme")
	pcall(function()
		game:GetService("CollectionService"):AddTag(model, CosmeLook.TAG)
	end)
	model:SetAttribute("CosmeFace", nil)
	CosmeLook.rest(model)
	-- Con miedo, asustado; enfadado o triste, escéptico (la emoción que pone la escena: atributo Mood)
	pcall(function()
		model:GetAttributeChangedSignal("Mood"):Connect(function()
			CosmeLook.rest(model)
		end)
	end)
	return ctx.Count
end

-- Vuelve a poner la cara y la ropa clásica con los ids de ahora (cuando el servidor acaba de pasar los
-- ids de Decal a imagen: shared/Images, Main.server)
function CosmeLook.refresh(model: Model)
	local face = model:GetAttribute("CosmeFace")
	CosmeLook.setFace(model, if type(face) == "string" then face else "Grin")
	local shirtId = CosmeLook.textureId(CosmeLook.ClothFiles.Shirt)
	local pantsId = CosmeLook.textureId(CosmeLook.ClothFiles.Pants)
	local shirt = model:FindFirstChild("CosmeShirt")
	if shirtId and shirt and shirt:IsA("Shirt") then
		shirt.ShirtTemplate = shirtId
	end
	local pants = model:FindFirstChild("CosmePants")
	if pantsId and pants and pants:IsA("Pants") then
		pants.PantsTemplate = pantsId
	end
end

return CosmeLook
