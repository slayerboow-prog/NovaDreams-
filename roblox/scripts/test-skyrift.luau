-- Prueba de la Grieta del cielo (shared/SkyRift, shared/SkyRiftArt y Controllers/SkyRift) FUERA de
-- Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-skyrift.luau
--
-- Comprueba que:
--   * las 7 etapas del dueño (scripts/rift/etapas.png) y cómo la saga las recorre: la grieta CRECE
--     (Rasguño 2 → Crece 3 → Grande 4 → Abierta 5 … Inminente 6 → Fusión 7), Cosida es una cicatriz
--   * las texturas (textures/rift/, scripts/rift/gen.py) existen, con alfa y el tamaño pedido; la
--     silueta (SkyRiftArt) es una rasgadura horizontal ancha y dentada con la galaxia dentro
--   * con y sin ids (RiftTextureIds): sin ids se dibuja por código; con ids, con las imágenes
--   * los rayos salen del borde hacia fuera/abajo y se regeneran con parpadeo; las rocas giran y
--     flotan; hay partículas; el ambiente se tiñe (azul; violeta en la 7) y se quita al cerrar
--   * el nivel Bajo: sin rocas 3D y la mitad de rayos y partículas; presupuesto de instancias
--   * el cliente de verdad (cargado con dobles de Roblox): plano lejano de cara a la cámara, sin
--     colisión, capas, rayos, rocas, partículas, ambiente, modo pruebas al instante

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local check = L.check

local Rift = L.load("src/shared/SkyRift")
local Art = L.load("src/shared/SkyRiftArt")
local SkyMoods = L.load("src/shared/SkyMoods")

---------------------------------------------------------------------
print("Las 7 etapas y las fases de la saga")
---------------------------------------------------------------------
check(#Rift.Stages == 7, "7 etapas (como la imagen del dueño)")
local names = {}
for i, st in Rift.Stages do
	names[i] = st.Name
end
check(names[1] == "Cielo normal" and names[2] == "Primera anomalía" and names[5] == "Portal dimensional" and names[7] == "Evento final", "con sus nombres: " .. table.concat(names, " · "))
local S = Rift.Stages
check(S[2].Width < S[3].Width and S[3].Width < S[4].Width, "de la anomalía a la gran fractura, cada vez más grande")
check(S[5].Width < S[6].Width and S[6].Width < S[7].Width and S[7].Width >= 2000, "portal → colosal → evento final (tapa casi todo el cielo)")
check(S[2].Star and S[2].Bolts == 0 and S[2].Rocks == 0, "2: solo el destello violeta y una raya fina (sin rayos ni rocas)")
check(S[3].Bolts > 0 and S[3].Rocks == 0 and S[3].Ambient > 0, "3: rayos y el cielo empieza a oscurecerse (aún sin rocas)")
check(S[4].Rocks > 0 and S[4].Draw.Fill and S[4].Draw.Roll ~= 0, "4: rocas, interior oscuro y en diagonal")
check(S[5].Draw.Cosmos and S[6].Draw.Cosmos and S[7].Draw.Backdrop, "5-7: el espacio dentro (galaxia, planeta, estrellas); 7: casi todo el cielo")
check(S[7].Mood == "GrietaFinal" and S[7].Ambient == 1, "7: la luz de toda la ciudad, violeta")
local grows = true
for i = 3, 7 do
	grows = grows and S[i].Ambient >= S[i - 1].Ambient and S[i].Bolts >= S[i - 1].Bolts
end
check(grows, "cuanto más avanzada la etapa, más ambiente teñido y más rayos")

local function phase(active, completed, flags)
	return Rift.phaseFor({ Active = active or {}, Completed = completed or {}, Flags = flags or {} })
end
local function done(...)
	local t = {}
	for _, id in { ... } do
		t[id] = 1
	end
	return t
end
local P = Rift.Phases
local function stageOf(name)
	return P[name].Stage
end
local ACT1 = { "Loco_N1_Cosme", "Saga_02_Grieta", "Saga_03_Pez", "Saga_04_Ventanilla", "Saga_05_Perdidas" }
check(phase() == "Ninguna" and stageOf("Ninguna") == 1, "sin saga: cielo normal (etapa 1)")
check(phase({ Prologo_Sueno = {} }) == "Sueno" and P.Sueno.Mode == "Dream", "prólogo: la grieta del sueño (encima de la isla)")
check(phase({ Loco_N1_Cosme = {} }) == "Ninguna", "mientras conoces a Cosme aún no está (sale al final)")
check(phase({}, done("Loco_N1_Cosme"), { GrietaVista = true }) == "Rasguno" and stageOf("Rasguno") == 2, "tras conocer a Cosme: la primera anomalía (etapa 2)")
check(phase({ Saga_02_Grieta = {} }, done("Loco_N1_Cosme")) == "Crece" and stageOf("Crece") == 3, "«La grieta en el cielo»: la grieta crece (etapa 3)")
check(phase({ Saga_05_Perdidas = {} }, done("Loco_N1_Cosme", "Saga_02_Grieta", "Saga_03_Pez", "Saga_04_Ventanilla")) == "Grande" and stageOf("Grande") == 4, "la noche de las cosas perdidas: gran fractura (etapa 4)")
check(phase({ Saga_06_Coser = {} }, done(table.unpack(ACT1))) == "Abierta" and stageOf("Abierta") == 5, "«Coser el cielo»: el portal abierto del todo (etapa 5, la referencia)")
local c6 = done(table.unpack(ACT1))
c6.Saga_06_Coser = 1
check(phase({}, c6) == "Cosida" and stageOf("Cosida") == 2 and P.Cosida.Intensity < 0.5, "cosida: solo una cicatriz (la raya fina, apagada)")
check(phase({ Saga_07_Costuras = {} }, c6) == "Hilachas" and stageOf("Hilachas") == 3, "Acto II: las costuras se sueltan (etapa 3)")
c6.Saga_12_Graduacion = 1
check(phase({ Saga_13_SinCosme = {} }, c6) == "Rota" and stageOf("Rota") == 5, "Acto III: la costura se rompe y vuelve el portal (etapa 5)")
c6.Saga_18_Precio = 1
check(phase({ Saga_19_Recuerdos = {} }, c6) == "Inminente" and stageOf("Inminente") == 6, "Acto IV: la Gran Fusión se acerca (grieta colosal, etapa 6)")
check(phase({ Saga_23_Fusion = {} }, c6) == "Fusion" and stageOf("Fusion") == 7, "la batalla final: el evento final (etapa 7)")
c6.Saga_23_Fusion = 1
check(phase({ Saga_24_Final = {} }, c6) == "Ultima" and stageOf("Ultima") < 7, "la última costura: se va cerrando")
c6.Saga_24_Final = 1
check(phase({}, c6) == "Cerrada" and stageOf("Cerrada") == 1 and phase({}, {}, { SagaCompleta = true }) == "Cerrada", "fin de la saga: cerrada para siempre")
check(stageOf("Rasguno") < stageOf("Crece") and stageOf("Crece") < stageOf("Grande") and stageOf("Grande") < stageOf("Abierta"), "Acto I: crece etapa a etapa (2 → 3 → 4 → 5)")
check(stageOf("Hilachas") < stageOf("Rota") and stageOf("Rota") < stageOf("Inminente") and stageOf("Inminente") < stageOf("Fusion"), "de la cicatriz a la Gran Fusión vuelve a crecer hasta la 7")
for name, p in P do
	if p.Open < 0 or p.Open > 1 or p.Intensity < 0 or p.Intensity > 1 or p.Stage < 1 or p.Stage > 7 then
		check(false, name .. ": Open, Intensity y Stage en su rango")
	end
end
check(#Rift.StagePreview == 7, "modo pruebas: una fase de ejemplo por etapa")
local okPreview = true
for i, name in Rift.StagePreview do
	okPreview = okPreview and P[name] and P[name].Stage == i
end
check(okPreview, "cada botón de etapa enseña esa etapa")
local o, secs = 0, 0
while o < 1 and secs < 60 do
	o = Rift.approach(o, 1, 0.1)
	secs += 0.1
end
check(secs > 4 and secs < 15, ("al nacer una etapa crece poco a poco (%.1f s)"):format(secs))
local w0, h0 = Rift.size(0.05)
local w1, h1 = Rift.size(1)
check(w1 == 1 and h1 == 1 and h0 < 0.1 and w0 < 0.5, "al nacer es pequeña y fina; crecida, el marco entero")

---------------------------------------------------------------------
print("Texturas (textures/rift) y silueta (SkyRiftArt)")
---------------------------------------------------------------------
-- PNG: ancho, alto y tipo de color (6 = RGBA) de la cabecera
local function png(path: string): (number?, number?, number?)
	if not fs.isFile(path) then
		return nil
	end
	local data = fs.readFile(path)
	local function u32(i)
		local a, b, c, d = string.byte(data, i, i + 3)
		return ((a * 256 + b) * 256 + c) * 256 + d
	end
	return u32(17), u32(21), string.byte(data, 26)
end
local iw, ih, ict = png("textures/rift/rift_interior.png")
check(iw == 2048 and ih == 1024 and ict == 6, "rift_interior.png: 2048x1024 con canal alfa")
local allPng = true
for _, name in Rift.TextureNames do
	local w, h, ct = png("textures/rift/" .. name .. ".png")
	if not w or ct ~= 6 or w > 2048 or h > 2048 then
		allPng = false
		print("    falta o mal: " .. name)
	end
end
check(allPng, ("las %d texturas existen, con alfa"):format(#Rift.TextureNames))
local previews = 0
for i = 1, 7 do
	if fs.isFile(("textures/rift/preview-%d.png"):format(i)) then
		previews += 1
	end
end
check(fs.isFile("textures/rift/preview.png") and previews == 7, "vistas previas: preview.png y preview-1..7.png")
check(fs.isFile("scripts/rift/gen.py") and fs.isFile("scripts/rift/referencia.png") and fs.isFile("scripts/rift/etapas.png"), "se rehacen con scripts/rift/gen.py desde las imágenes del dueño")

local umin, umax, vmin, vmax = 1, 0, 1, 0
for _, p in Art.Rim do
	umin, umax = math.min(umin, p[1]), math.max(umax, p[1])
	vmin, vmax = math.min(vmin, p[2]), math.max(vmax, p[2])
end
local ratio = (umax - umin) * Rift.Aspect / (vmax - vmin)
check(#Art.Rim >= 40 and ratio > 2.2, ("la rasgadura es horizontal y ancha (%d puntos de borde, %.1f veces más ancha que alta)"):format(#Art.Rim, ratio))
check(umax - umin > 0.6, ("ocupa gran parte del marco (%.0f %% del ancho)"):format((umax - umin) * 100))
local turns = 0
for i = 2, #Art.Rim - 1 do
	local a, b, c = Art.Rim[i - 1], Art.Rim[i], Art.Rim[i + 1]
	local t1 = math.atan2(b[2] - a[2], b[1] - a[1])
	local t2 = math.atan2(c[2] - b[2], c[1] - b[1])
	if math.abs((t2 - t1 + math.pi) % (2 * math.pi) - math.pi) > math.rad(25) then
		turns += 1
	end
end
check(turns > #Art.Rim / 3, ("bordes rotos y dentados (%d picos)"):format(turns))
check(Rift.inside(Art, Art.Galaxy[1], Art.Galaxy[2]) and Art.Planet[1] < Art.Galaxy[1], "la galaxia dentro, el planeta a su izquierda")
check(#Art.Columns >= 40, "relleno por columnas (para dibujarla sin textura)")
local stagesArt = true
for n = 2, 7 do
	local a = Art.Stages[n]
	stagesArt = stagesArt and a ~= nil and table.find(Rift.TextureNames, a.Texture) ~= nil and a.Aspect > 0.5 and a.Aspect < 3
end
check(stagesArt, "cada etapa 2-7 tiene su textura y su marco")
check(Art.Stages[6].Galaxy and Art.Stages[7].Galaxy and Art.Stages[5].Galaxy, "las etapas 5-7 tienen galaxia que gira")
check(Art.Stages[2].Star ~= nil, "la 2 sabe dónde está su destello")

-- Con y sin ids
check(Rift.textures({}, 5, Art) == nil, "sin ids (aún no subidas): se dibuja por código")
local fullIds = {}
for i, name in Rift.TextureNames do
	fullIds[name] = "rbxassetid://" .. (1000 + i)
end
local t5 = Rift.textures(fullIds, 5, Art)
check(t5 and t5.Main == fullIds.rift_interior and t5.Glow == fullIds.rift_glow and t5.Rays == fullIds.rift_rays and t5.Galaxy == fullIds.rift_galaxy and #t5.Bolts == 4, "etapa 5 con ids: interior, halo, rayos, galaxia y 4 rayos")
local t3 = Rift.textures(fullIds, 3, Art)
check(t3 and t3.Main == fullIds.rift_s3 and t3.Glow == nil and math.abs(t3.Aspect - Art.Stages[3].Aspect) < 1e-9, "etapa 3 con ids: su propia textura y su proporción")
check(Rift.textures({ rift_interior = "rbxassetid://5" }, 3, Art) == nil, "si falta la de esa etapa, por código")
local mapped = Rift.textures(fullIds, 7, Art, function(id)
	return id .. "0"
end)
check(mapped and mapped.Main == fullIds.rift_s7 .. "0", "pasa por Images.of (del Decal a su imagen)")
check(Rift.textures({ rift_interior = "nada" }, 5, Art) == nil, "un id raro no cuenta")

---------------------------------------------------------------------
print("Rayos, rocas y ambiente (cuentas)")
---------------------------------------------------------------------
local r = Rift.rng(5)
local cu, cv = Rift.centroid(Art)
local okBolts, downish, lifeOk = true, 0, true
for _ = 1, 300 do
	local b = Rift.newBolt(Art.Rim, r)
	local fromRim = false
	for _, p in Art.Rim do
		if p[1] == b.U and p[2] == b.V then
			fromRim = true
		end
	end
	okBolts = okBolts and fromRim and b.Length > 0.05 and b.Length < 0.3 and b.Texture >= 1 and b.Texture <= 4
	lifeOk = lifeOk and b.Life >= 0.1 and b.Life <= 0.6
	-- hacia fuera: alejándose del centro
	local ex, ey = b.U + math.cos(b.Angle) * 0.05, b.V + math.sin(b.Angle) * 0.05
	if math.sin(b.Angle) > 0 then
		downish += 1
	end
	if (ex - cu) ^ 2 + ((ey - cv) * 2) ^ 2 < (b.U - cu) ^ 2 + ((b.V - cv) * 2) ^ 2 - 0.02 then
		okBolts = false
	end
end
check(okBolts, "cada rayo sale de un punto del borde hacia fuera")
check(lifeOk, "y dura entre 0,1 y 0,6 s (luego se regenera)")
check(downish > 150, ("más bien hacia abajo (%d de 300)"):format(downish))
local main, branch = Rift.boltPath(42, 7)
check(#main == 8 and main[1][1] == 0 and main[#main][1] == 1 and #branch == 4, "sin textura: rayo quebrado de 7 tramos con una rama")
local rocks = Rift.rocks(24)
local again = Rift.rocks(24)
check(#rocks == 24 and rocks[5].Orbit == again[5].Orbit, "rocas: siempre las mismas (semilla fija)")
local x0, y0 = Rift.rockAt(rocks[1], 0, 1)
local x1, y1 = Rift.rockAt(rocks[1], 30, 1)
check(math.abs(x1 - x0) + math.abs(y1 - y0) > 1e-3, "las rocas se mueven (órbita lenta)")
local bigRocks = 0
for _, rk in rocks do
	if rk.Size > 0.03 then
		bigRocks += 1
	end
end
check(bigRocks >= 2 and bigRocks < 12, "unas pocas grandes y muchas pequeñas")
check(Rift.ambientWeight(1, 1, 1) == 0 and Rift.ambientWeight(7, 1, 1) == 1 and Rift.ambientWeight(5, 1, 1) > 0.6, "ambiente: nada sin grieta, mucho con el portal, del todo en la 7")
check(Rift.ambientWeight(5, 0, 1) == 0 and Rift.ambientWeight(5, 1, 0) == 0, "y se quita al cerrarse")
local azul, final = SkyMoods.List.GrietaAzul, SkyMoods.List.GrietaFinal
check(azul and azul.CloudColor.B > azul.CloudColor.G and azul.AtmColor.B > azul.AtmColor.R, "GrietaAzul: nubes y bruma azul/morado")
check(final and final.Tint.B > final.Tint.G and final.Outdoor.R > final.Outdoor.G and final.Outdoor.B > final.Outdoor.G, "GrietaFinal: la ciudad violeta")

---------------------------------------------------------------------
print("Niveles gráficos y presupuesto")
---------------------------------------------------------------------
local low, med, high = Rift.tierLook("Low"), Rift.tierLook("Medium"), Rift.tierLook("High")
check(low.Rocks == 0 and high.Rocks >= 15 and high.Rocks <= 30, "Bajo: sin rocas 3D; Alto: 15-30 rocas")
check(low.Bolts <= high.Bolts / 2 + 1 and low.Emitters <= high.Emitters / 2 + 1, "Bajo: la mitad de rayos y partículas")
check(not low.Halo and med.Halo, "Bajo: sin resplandor aditivo")
for stage = 2, 7 do
	local bh, bl = Rift.budget(Art, stage, "High", true), Rift.budget(Art, stage, "Low", true)
	local ph = Rift.budget(Art, stage, "High", false)
	if bh.Parts > 75 or bh.Gui > 40 or ph.Gui > 520 or bh.Emitters > 8 or bl.Parts > 1 or bl.Gui > bh.Gui then
		check(false, ("presupuesto de la etapa %d (con textura: %d piezas, %d gui; sin: %d gui)"):format(stage, bh.Parts, bh.Gui, ph.Gui))
	end
end
local b5 = Rift.budget(Art, 5, "High", true)
local p5 = Rift.budget(Art, 5, "High", false)
check(true, ("presupuesto (etapa 5, Alto): con textura %d piezas, %d gui, %d beams, %d emisores; sin textura %d gui"):format(b5.Parts, b5.Gui, b5.Beams, b5.Emitters, p5.Gui))
check(Rift.budget(Art, 1, "High", false).Parts == 0, "etapa 1: nada")

---------------------------------------------------------------------
print("Cliente de verdad (Controllers/SkyRift con dobles de Roblox)")
---------------------------------------------------------------------
local Instance = roblox.Instance
local dm = Instance.new("DataModel")
local ws = dm:GetService("Workspace")
local camera = Instance.new("Camera")
camera.Parent = ws
ws.CurrentCamera = camera
camera.CFrame = roblox.CFrame.new(0, 20, 0)
L.workspace = ws

local attrs: { [string]: any } = {}
local onAttr: { () -> () } = {}
local localPlayer = {
	Name = "Prueba",
	GetAttribute = function(_, k)
		return attrs[k]
	end,
	GetAttributeChangedSignal = function(_, _k)
		return {
			Connect = function(_, fn)
				table.insert(onAttr, fn)
			end,
		}
	end,
}
local function setPhase(name: string)
	attrs.SkyRift = name
	for _, fn in onAttr do
		fn()
	end
end
local stepFn: ((number) -> ())? = nil
L.services.Players = { LocalPlayer = localPlayer }
L.services.Lighting = { ClockTime = 14 }
L.services.RunService.BindToRenderStep = function(_, _name, _prio, fn)
	stepFn = fn
end
-- ReplicatedStorage.Shared con FindFirstChild (los ids se cambian con L.mock)
local sharedNode = L.services.ReplicatedStorage.Shared
local shared = setmetatable({
	FindFirstChild = function(_, name)
		if name == "RiftTextureIds" or name == "SoundIds" then
			return sharedNode[name]
		end
		return if fs.isFile("src/shared/" .. name .. ".luau") then sharedNode[name] else nil
	end,
}, { __index = function(_, k)
	return sharedNode[k]
end })
L.services.ReplicatedStorage = {
	Shared = shared,
	FindFirstChild = function()
		return nil
	end,
}
L.mock("src/shared/SoundIds", {}) -- (sin sonidos: el doble no los reproduce)
local layers: { [string]: any } = {}
local pops = 0
L.mock("src/client/Controllers/DayLight", {
	pushLayer = function(id, mood, _fade, weight)
		layers[id] = { Mood = mood, W = weight }
	end,
	popLayer = function(id)
		layers[id] = nil
		pops += 1
	end,
})
local tier = "Medium"
L.mock("src/client/UI/Perf", {
	tierName = function()
		return tier
	end,
	onTier = function() end,
})

local CONTROLLER = "src/client/Controllers/SkyRift"
local function fresh(ids: { [string]: string }?)
	L.mock("src/shared/RiftTextureIds", ids or {})
	L.reset(CONTROLLER)
	L.reset("src/shared/Images")
	attrs = {}
	onAttr = {}
	layers = {}
	stepFn = nil
	for _, c in ws:GetChildren() do
		if c.Name == "CieloGrieta" then
			c:Destroy()
		end
	end
	local C = L.load(CONTROLLER)
	C.init()
	return C
end
local function run(seconds: number)
	local fn = stepFn :: (number) -> ()
	for _ = 1, math.floor(seconds * 20) do
		fn(0.05)
	end
end
local function count(root: Instance?, className: string, namePrefix: string?): number
	local n = 0
	if not root then
		return 0
	end
	for _, d in root:GetDescendants() do
		if d.ClassName == className and (not namePrefix or string.sub(d.Name, 1, #namePrefix) == namePrefix) then
			n += 1
		end
	end
	return n
end

-- Sin texturas (lo de ahora): Abierta, como la jugarías
local Ctl = fresh()
check(stepFn ~= nil, "se engancha al render (después de la cámara)")
setPhase("Abierta")
run(14)
local folder = ws:FindFirstChild("CieloGrieta")
local part = folder and folder:FindFirstChild("Grieta")
local st = Ctl.debugState()
check(folder ~= nil and st.Stage == 5 and st.Open > 0.99, "«Abierta»: la etapa 5 se abre del todo en unos segundos")
check(part and part.CanCollide == false and part.CanQuery == false and part.CanTouch == false and part.CastShadow == false and part.Transparency == 1, "plano sin colisión, sin consultas ni sombra")
if part then
	local camPos = camera.CFrame.Position
	local toCam = (camPos - part.CFrame.Position).Unit
	local d = (part.CFrame.Position - camPos).Magnitude
	check(part.CFrame.LookVector:Dot(toCam) > 0.99, "siempre de frente a la cámara (no se deforma)")
	check(d > 600 and d < 1500, ("lejos, en el cielo (%d studs)"):format(math.floor(d)))
	check((part.CFrame.Position - camPos).Unit.Y > 0.4, "por encima del horizonte")
	camera.CFrame = roblox.CFrame.new(300, 50, -200)
	run(0.1)
	local d2 = (part.CFrame.Position - camera.CFrame.Position).Magnitude
	check(math.abs(d2 - d) < 1, "sigue a la cámara (no se puede alcanzar)")
end
local gui = part and part:FindFirstChild("Lienzo")
check(gui and gui.LightInfluence == 0 and gui.Brightness > 1.2 and gui.Face.Name == "Front", "lienzo (SurfaceGui) sin luz del mundo y con brillo > 1 (resplandece con el Bloom)")
check(st.Textured == false and count(gui, "Frame", "Columna") >= 40 and count(gui, "Frame", "Borde") >= 40, "sin texturas: relleno oscuro por columnas y borde eléctrico")
check(count(gui, "Frame", "Planeta") == 1 and count(gui, "Frame", "Galaxia") > 20 and count(gui, "Frame", "Estrella") > 10, "con planeta, galaxia y estrellas")
check(st.Bolts == 14 and st.Rocks == 20 and st.Emitters == 6, ("Medio: %d rayos, %d rocas, %d emisores"):format(st.Bolts, st.Rocks, st.Emitters))
local model = folder and folder:FindFirstChild("Rocas")
local hl = model and model:FindFirstChild("BordeAzul")
check(model and count(model, "Part") == 20 and count(model, "WedgePart") == 20 and hl and hl.ClassName == "Highlight", "rocas 3D (bloque + cuña) con borde azul (un solo Highlight)")
local rock = model and model:FindFirstChild("Roca1")
local rockCF = rock and rock.CFrame
run(2)
check(rock and rockCF and (rock.CFrame.Position - rockCF.Position).Magnitude > 0.01, "las rocas flotan y giran")
check(rock and rock.CanCollide == false and rock.CastShadow == false and (rock.Material == roblox.Enum.Material.Rock or rock.Material == roblox.Enum.Material.Basalt), "rocas de roca/basalto, sin colisión ni sombra")
local emit = count(part, "ParticleEmitter")
local someRate = 0
for _, d in (part and part:GetDescendants() or {}) do
	if d.ClassName == "ParticleEmitter" then
		someRate = math.max(someRate, d.Rate)
	end
end
check(emit == 6 and someRate > 0, "chispas y polvo de energía en el borde")
check(count(part, "Beam") == 2, "resplandor aditivo (2 Beams)")
-- Los rayos se regeneran: una posición distinta cada poco
local seen, changes, last = {}, 0, nil
for _ = 1, 100 do
	run(0.05)
	local first = gui and gui:FindFirstChild("RayoTramo")
	if first then
		local key = tostring(first.Position)
		if key ~= last then
			changes += 1
			last = key
		end
		seen[key] = true
	end
end
check(changes >= 6, ("los rayos se regeneran (cambian %d veces en 5 s)"):format(changes))
local lit = 0
for _, d in (gui and gui:GetDescendants() or {}) do
	if d.Name == "RayoTramo" and d.BackgroundTransparency < 0.9 then
		lit += 1
	end
end
check(lit > 0, "y parpadean encendidos")
check(layers.GrietaCielo and layers.GrietaCielo.Mood == SkyMoods.List.GrietaAzul and layers.GrietaCielo.W > 0.6, "el ambiente se tiñe de azul/morado (DayLight)")
local descendants = #folder:GetDescendants()
check(descendants < 900, ("presupuesto sin texturas: %d instancias"):format(descendants))

-- Cerrar: se apaga y se quita el tinte
setPhase("Cerrada")
run(12)
check(Ctl.debugState().Stage == 1 and ws:FindFirstChild("CieloGrieta") == nil, "«Cerrada»: se apaga y desaparece")
check(layers.GrietaCielo == nil and pops > 0, "y el tinte del ambiente se quita")

-- Modo pruebas: cada etapa al instante
Ctl.previewStage(7)
run(0.5)
st = Ctl.debugState()
folder = ws:FindFirstChild("CieloGrieta")
check(st.Stage == 7 and st.Open == 1 and folder ~= nil, "modo pruebas: la 7 al instante")
check(layers.GrietaCielo and layers.GrietaCielo.Mood == SkyMoods.List.GrietaFinal and layers.GrietaCielo.W > 0.9, "7: toda la ciudad violeta")
check(count(folder, "Frame", "Fondo") == 3, "7: casi todo el cielo es espacio")
Ctl.previewStage(2)
run(0.2)
folder = ws:FindFirstChild("CieloGrieta")
st = Ctl.debugState()
check(st.Stage == 2 and st.Rocks == 0 and st.Bolts == 0 and count(folder, "Frame", "Destello") >= 2, "2: el destello violeta, sin rocas ni rayos")
part = folder and folder:FindFirstChild("Grieta")
check(part and part.Size.X < 400, "2: pequeña")
Ctl.previewStage(4)
run(0.2)
part = ws:FindFirstChild("CieloGrieta") and ws.CieloGrieta:FindFirstChild("Grieta")
check(part and math.abs(part.CFrame.RightVector.Y) > 0.3, "4 sin textura: la fractura va en diagonal")
check(Ctl.debugState().Rocks > 0, "4: empiezan a flotar rocas")
Ctl.preview(nil)
run(12)
check(Ctl.debugState().Stage == 1, "«La de mi historia» vuelve a la tuya (aquí, ninguna)")

-- Nivel Bajo
tier = "Low"
Ctl = fresh()
setPhase("Abierta")
run(14)
folder = ws:FindFirstChild("CieloGrieta")
st = Ctl.debugState()
check(st.Rocks == 0 and folder and folder:FindFirstChild("Rocas") == nil, "Bajo: sin rocas 3D")
check(st.Bolts == 7 and st.Emitters == 3, ("Bajo: la mitad de rayos (%d) y partículas (%d)"):format(st.Bolts, st.Emitters))
check(count(folder, "Beam") == 0, "Bajo: sin resplandor aditivo")

-- Con texturas subidas
tier = "High"
Ctl = fresh(fullIds)
setPhase("Abierta")
run(14)
folder = ws:FindFirstChild("CieloGrieta")
gui = folder and folder.Grieta:FindFirstChild("Lienzo")
st = Ctl.debugState()
local interior = gui and gui:FindFirstChild("Interior")
check(st.Textured and interior and interior.ClassName == "ImageLabel" and interior.Image == fullIds.rift_interior, "con ids: la textura del interior")
check(gui and gui:FindFirstChild("Halo") and gui:FindFirstChild("Rayos") and gui:FindFirstChild("Galaxia"), "y las capas de halo, rayos del borde y galaxia")
check(gui and gui.Halo.ZIndex < interior.ZIndex and interior.ZIndex < gui.Galaxia.ZIndex and gui.Galaxia.ZIndex < gui.Rayos.ZIndex, "en orden: halo, interior, galaxia, rayos")
check(count(gui, "Frame", "Columna") == 0 and count(gui, "ImageLabel", "Rayo") >= 16, "sin el dibujo por código; los rayos, con su textura")
local rot0 = gui and gui.Galaxia.Rotation
run(3)
check(gui and gui.Galaxia.Rotation ~= rot0, "la galaxia gira despacio")
check(st.Rocks == 28 and #folder:GetDescendants() < 200, ("Alto con texturas: 28 rocas y %d instancias"):format(#folder:GetDescendants()))
Ctl.previewStage(3)
run(0.2)
gui = ws.CieloGrieta.Grieta:FindFirstChild("Lienzo")
check(gui and gui:FindFirstChild("Interior") and gui.Interior.Image == fullIds.rift_s3, "cada etapa con su textura (3: la fractura)")

---------------------------------------------------------------------
print("Lo que la rodea")
---------------------------------------------------------------------
local src = fs.readFile("src/client/Controllers/SkyRift.luau")
check(src:find('GetAttribute%("SkyRift"%)'), "lee la fase del atributo SkyRift (lo publica el servidor)")
local service = fs.readFile("src/server/Services/LifeStoryService.luau")
check(service:find('SetAttribute%("SkyRift", SkyRift.phaseFor%(story%)%)'), "el servidor publica la fase según la historia")
local island = fs.readFile("src/server/World/Kit/DreamIsland.luau")
check(island:find("Vector3.new%(%-3400, 700, %-3400%)") and Rift.Placement.Dream.Center[1] == -3400 + 82, "la del sueño está encima de la isla (DreamIsland.Origin)")
local mainClient = fs.readFile("src/client/Main.client.luau")
check(mainClient:find("Controllers.SkyRift"), "Main.client arranca la Grieta")
local server = fs.readFile("src/server/Main.server.luau")
check(server:find("Images.resolve%(require%(Shared.RiftTextureIds%)%)"), "el servidor pasa los Decal de la grieta a imagen (shared/Images)")
local tester = fs.readFile("src/client/UI/TesterPanel.luau")
check(tester:find("previewStage") and tester:find("7 · Evento final") and tester:find("5 · Portal"), "panel de pruebas: las 7 etapas una a una")
local upload = fs.readFile("scripts/upload-rift.sh")
check(upload:find("RiftTextureIds.luau") and upload:find('"assetType":"Decal"') and upload:find("textures/rift"), "scripts/upload-rift.sh sube textures/rift como Decal y escribe RiftTextureIds")

L.finish("Grieta del cielo")
