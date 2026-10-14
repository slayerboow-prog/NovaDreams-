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
check(S[4].Width < S[5].Width and S[5].Width < S[6].Width and S[6].Width < S[7].Width and S[7].Width >= 2000, "gran fractura → portal → colosal → evento final (tapa casi todo el cielo)")
-- Lo que se VE de cada etapa (la parte opaca de su textura dentro del marco), siempre más grande al abrirse
do
	local cover = { [2] = { 0.83, 0.64 }, [3] = { 0.79, 0.81 }, [4] = { 0.95, 0.94 }, [5] = { 0.69, 0.49 }, [6] = { 0.91, 0.89 }, [7] = { 0.92, 0.89 } }
	local areas, prev, grows = {}, 0, true
	for n = 2, 7 do
		local aspect = S[n].FrameAspect or Art.Stages[n].Aspect
		local w = S[n].Width * cover[n][1]
		local hgt = S[n].Width / aspect * cover[n][2]
		local area = w * hgt
		grows = grows and area > prev * 1.05
		prev = area
		table.insert(areas, ("%d: %dx%d"):format(n, math.floor(w), math.floor(hgt)))
	end
	check(grows, "cada etapa que se abre se ve más grande que la anterior (studs del agujero) · " .. table.concat(areas, " · "))
	check(S[5].Width * cover[5][1] > 900 and S[5].Width / S[5].FrameAspect * cover[5][2] > 450, "5: el portal es un agujero grande (no una raya fina)")
end
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
-- Prólogo «atascado» (el HUD dice «La grieta en el cielo» pero el prólogo sigue activo): no es el sueño
check(phase({ Prologo_Sueno = {}, Saga_02_Grieta = {} }, { Loco_N1_Cosme = 1 }) == "Crece" and Rift.stuckPrologue({ Active = { Prologo_Sueno = {} }, Completed = { Saga_01_Rasguno = 1 } }), "prólogo activo con misiones de después hechas: se hace como si no estuviera (Crece, no Sueno)")
check(not Rift.stuckPrologue({ Active = { Prologo_Sueno = {} }, Completed = {} }) and not Rift.stuckPrologue({ Active = {}, Completed = { Saga_02_Grieta = 1 } }), "un prólogo de verdad (sin nada después) sigue siendo el sueño")
local lifeSrc = fs.readFile("src/server/Services/LifeStoryService.luau")
check(lifeSrc:find("SkyRift.stuckPrologue(story)", 1, true) and lifeSrc:find("warn(", 1, true), "el servidor apunta en el registro el prólogo atascado")
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
check(iw == 1024 and ih == 512 and ict == 6, "rift_interior.png: 1024x512 con canal alfa (Roblox no pasa de 1024)")
local allPng = true
for _, name in Rift.TextureNames do
	local w, h, ct = png("textures/rift/" .. name .. ".png")
	if not w or ct ~= 6 or w > 1024 or h > 1024 or bit32.band(w, w - 1) ~= 0 or bit32.band(h, h - 1) ~= 0 then
		allPng = false
		print("    falta o mal: " .. name)
	end
end
check(allPng, ("las %d texturas existen, con alfa, potencia de 2 y ≤ 1024"):format(#Rift.TextureNames))
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
-- (estas pruebas son las de la historia: sin el ciclo de demostración; el ciclo, más abajo)
local GameConfig = L.load("src/shared/Config")
local demoWas = GameConfig.SkyRift.DemoCycle
GameConfig.SkyRift.DemoCycle = false
local function fresh(ids: { [string]: string }?)
	L.mock("src/shared/RiftTextureIds", ids or {})
	L.reset(CONTROLLER)
	L.reset("src/shared/Images")
	attrs = {}
	onAttr = {}
	layers = {}
	stepFn = nil
	for _, c in ws:GetChildren() do
		if c.Name == "CieloGrieta" or c.Name == "CieloGrietaAntes" or c.Name == "GrietaEvento" or c.Name == "SirenasGrieta" then
			c:Destroy()
		end
	end
	L.reset("src/client/Controllers/RiftSirens")
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
	check(d > 380 and d < 1000, ("en el cielo, a escala más cerca para que la bruma no la lave (%d studs)"):format(math.floor(d)))
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
check(model and count(model, "Part") == 20 and count(model, "WedgePart") == 20 and count(model, "Highlight") == 0, "rocas 3D (bloque + cuña) sombreadas, sin Highlight (salían como polígonos planos azul claro)")
local biggest, darkOpaque = 0, true
for _, d in (model and model:GetDescendants() or {}) do
	if d.ClassName == "Part" or d.ClassName == "WedgePart" then
		biggest = math.max(biggest, d.Size.X, d.Size.Y, d.Size.Z)
		darkOpaque = darkOpaque and d.Transparency == 0 and d.Color.R < 0.25
	end
end
check(darkOpaque, "rocas oscuras y opacas")
check(biggest < 90, ("rocas de tamaño razonable (la mayor, %d studs)"):format(math.floor(biggest)))
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
---------------------------------------------------------------------
print("Se ve sin buscarla: delante de la cámara y aviso «¡Mira al cielo!»")
---------------------------------------------------------------------
-- Cono de visión de un móvil en horizontal (FieldOfView 70° en vertical, pantalla 16:9)
local FOV_V = math.rad(70)
local FOV_H = 2 * math.atan(math.tan(FOV_V / 2) * 16 / 9)
local function inView(cf: any, point: any): (boolean, number, number)
	local rel = cf:PointToObjectSpace(point)
	if rel.Z >= 0 then
		return false, 0, 0
	end
	local h = math.atan(math.abs(rel.X) / -rel.Z)
	local v = math.atan(rel.Y / -rel.Z)
	return h <= FOV_H / 2 and math.abs(v) <= FOV_V / 2, math.deg(h), math.deg(v)
end
check(Rift.Placement.Sky.Elevation >= 22 and Rift.Placement.Sky.Elevation <= 32, ("a %d° sobre el horizonte: encima de los edificios y dentro de la pantalla del móvil"):format(Rift.Placement.Sky.Elevation))
local ex, ey, ez = Rift.skyDirection(Rift.yawOf(1, 0))
check(ex > 0.8 and math.abs(ez) < 1e-6 and math.abs(math.deg(math.asin(ey)) - Rift.Placement.Sky.Elevation) < 0.01, "la dirección sigue el giro de la cámara (mirando a +X, la grieta a +X)")

-- Un jugador que mira al ESTE (no al norte, donde estaba siempre)
local playerGui = Instance.new("Folder")
playerGui.Name = "PlayerGui"
local lighting = L.services.Lighting
lighting.ClockTime = 14
Ctl = fresh()
localPlayer.FindFirstChildOfClass = function(_, className)
	return if className == "PlayerGui" then playerGui else nil
end
local east = roblox.CFrame.lookAt(roblox.Vector3.new(0, 20, 0), roblox.Vector3.new(100, 20, 0))
camera.CFrame = east
setPhase("Crece")
run(2)
local hintGui = playerGui:FindFirstChild("AvisoGrieta") -- (dura unos segundos: se mira ya)
local hintTextObj = hintGui and hintGui:FindFirstChild("Texto")
local hintText = if hintTextObj then hintTextObj.Text else ""
local hintArrowOk = hintGui and hintGui:FindFirstChild("Flecha") ~= nil
run(8)
part = ws:FindFirstChild("CieloGrieta") and ws.CieloGrieta:FindFirstChild("Grieta")
st = Ctl.debugState()
local seen, hdeg, vdeg = false, 0, 0
if part then
	seen, hdeg, vdeg = inView(east, part.CFrame.Position)
end
check(part and seen and vdeg > 15, ("«Crece» con la cámara mirando al este: la grieta sale en pantalla, por encima de los edificios (%.0f° a un lado, %.0f° arriba)"):format(hdeg, vdeg))
-- Con la cámara un poco hacia abajo (lo normal en el móvil), aún se ve su parte de abajo
local down = east * roblox.CFrame.Angles(math.rad(-10), 0, 0)
local lowEdge = if part then part.CFrame.Position - roblox.Vector3.new(0, Rift.stage(3).Width / Rift.Aspect * 0.3, 0) else roblox.Vector3.zero
check(part and (inView(down, lowEdge)), "con la cámara 10° hacia abajo, se sigue viendo")
-- Luego se queda fija: girar la cámara no la mueve de su lado del cielo
local before = part and (part.CFrame.Position - camera.CFrame.Position).Unit
camera.CFrame = roblox.CFrame.lookAt(roblox.Vector3.new(0, 20, 0), roblox.Vector3.new(0, 20, 100))
run(1)
local after = part and (part.CFrame.Position - camera.CFrame.Position).Unit
check(before and after and before:Dot(after) > 0.999, "después se queda fija en ese lado del cielo (no persigue a la cámara al girar)")
-- Aviso «¡Mira al cielo!» (la primera vez), con su flecha
st = Ctl.debugState()
check(st.Hints == 1 and st.HintKind == "First", ("la primera vez con grieta en el cielo: aviso «¡Mira al cielo!» (%s avisos)"):format(tostring(st.Hints)))
check(string.find(hintText, "Mira al cielo", 1, true) and hintArrowOk, "con el texto y una flecha hacia la grieta")
check(playerGui:FindFirstChild("AvisoGrieta") == nil, "el aviso dura poco")
run(20)
check(Ctl.debugState().Hints == 1, "y no se repite")
-- La primera noche en «Crece»: otro aviso (uno solo) y la grieta se pone delante de la cámara de ahora
local north = roblox.CFrame.lookAt(roblox.Vector3.new(0, 20, 0), roblox.Vector3.new(0, 20, -100))
camera.CFrame = north
lighting.ClockTime = 22
run(1)
st = Ctl.debugState()
local nightSeen = part and (inView(north, part.CFrame.Position))
check(st.Hints == 2 and st.HintKind == "Night" and nightSeen, "la primera noche en «Crece»: otro aviso y la grieta, delante")
run(30)
lighting.ClockTime = 23
run(5)
check(Ctl.debugState().Hints == 2, "cada aviso, una sola vez")
-- Las cuentas del aviso
local memo = {}
check(Rift.hintFor(memo, "Ninguna", 22) == nil and Rift.hintFor(memo, "Sueno", 22) == nil, "sin grieta en Valmar (o en el sueño): sin aviso")
check(Rift.hintFor(memo, "Rasguno", 12) == "First" and Rift.hintFor(memo, "Rasguno", 22) == nil and Rift.hintFor(memo, "Crece", 12) == nil and Rift.hintFor(memo, "Crece", 23) == "Night" and Rift.hintFor(memo, "Grande", 2) == nil, "Rasguño: el primero; la primera noche en Crece o más: el de la noche; luego, nada")
local memo2 = {}
check(Rift.hintFor(memo2, "Crece", 22) == "First" and Rift.hintFor(memo2, "Crece", 22) == nil, "si entra ya de noche en «Crece», un solo aviso")
localPlayer.FindFirstChildOfClass = nil
lighting.ClockTime = 14
camera.CFrame = roblox.CFrame.new(0, 20, 0)

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
print("De día se ve igual de fuerte y suena")
---------------------------------------------------------------------
check(Rift.dayBoost(12) > 1.6 and math.abs(Rift.dayBoost(23) - 1) < 1e-6, ("de día brilla más (x%.2f a mediodía, x1 de noche)"):format(Rift.dayBoost(12)))
for _, name in { "GrietaAzul", "GrietaFinal" } do
	local m = SkyMoods.List[name]
	check(m.Haze <= 1 and m.Density <= 0.25 and m.Exposure < -0.1 and m.Cover >= 0.7 and m.CloudColor.B > m.CloudColor.G, name .. ": poca bruma (no lava la grieta) y el cielo de día más oscuro y morado")
end
local prevHum, soundOk = 0, true
check(Rift.soundFor(1).Hum == 0 and Rift.soundFor(1).Roar == 0, "etapa 1: en silencio")
for n = 2, 7 do
	local snd = Rift.soundFor(n)
	soundOk = soundOk and snd.Hum > prevHum
	prevHum = snd.Hum
end
check(soundOk and Rift.soundFor(7).Hum >= 0.85 and Rift.soundFor(7).Roar >= 0.5, "el zumbido sube con la etapa; la 7, un rugido fuerte")
local noBuzz = true
for n = 1, 7 do
	noBuzz = noBuzz and (Rift.soundFor(n) :: any).Buzz == nil
end
check(noBuzz, "sin capa «Buzz» (el motor del patinete en bucle sonaba a alarma sin parar): solo zumbido grave, rugido y crepitar")
L.mock("src/shared/SoundIds", { viento = "rbxassetid://1", trueno = "rbxassetid://2" })
do
	local Cs = fresh()
	setPhase("Fusion")
	run(14)
	local snd = Cs.debugState().Sounds
	check(snd.Hum and snd.Hum > 0.5 and snd.Roar and snd.Roar > 0.3 and snd.Buzz == nil and snd.Crackle, ("7: suena (zumbido %.2f, rugido %.2f y crepitar; sin zumbido eléctrico)"):format(snd.Hum or -1, snd.Roar or -1))
	-- Las capas que suenan en bucle con la grieta: solo el zumbido (viento) y el rugido (trueno), nada de alarma
	local loops = {}
	for _, d in ws.CieloGrieta:GetDescendants() do
		if d.ClassName == "Sound" and d.Looped then
			table.insert(loops, d.Name .. "=" .. d.SoundId)
		end
	end
	table.sort(loops)
	check(table.concat(loops, ",") == "Rugido=rbxassetid://2,Zumbido=rbxassetid://1", "en bucle con la grieta, solo el zumbido grave y el rugido: " .. table.concat(loops, ", "))
	setPhase("Rasguno")
	run(25)
	snd = Cs.debugState().Sounds
	check(snd.Hum and snd.Hum < 0.35 and (snd.Roar or 0) == 0, ("2: un zumbido flojo (%.2f), sin rugido"):format(snd.Hum or -1))
	lighting.ClockTime = 12
	run(1)
	local g12 = ws.CieloGrieta.Grieta.Lienzo.Brightness
	lighting.ClockTime = 23
	run(1)
	local g23 = ws.CieloGrieta.Grieta.Lienzo.Brightness
	check(g12 > g23 * 1.3, ("el lienzo brilla más a mediodía (%.1f) que de noche (%.1f)"):format(g12, g23))
	lighting.ClockTime = 14
end
L.mock("src/shared/SoundIds", {})

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

---------------------------------------------------------------------
print("Ciclo de demostración (Config.SkyRift.DemoCycle): las 7 etapas en un día de juego")
---------------------------------------------------------------------
check(demoWas == true, "Config.SkyRift.DemoCycle está encendido (temporal, pruebas del dueño)")
check(GameConfig.DayLengthMinutes == 20, "el día sigue durando 20 minutos reales")
local schedule = Rift.demoSchedule()
local stagesSeen, seq, hours = {}, {}, 0
for _, slot in schedule do
	stagesSeen[slot.Stage] = true
	table.insert(seq, slot.Stage)
	hours += (slot.To - slot.From) % 24
end
local allSeven = true
for i = 1, 7 do
	allSeven = allSeven and stagesSeen[i] == true
end
check(allSeven and math.abs(hours - 24) < 1e-9 and #schedule == 16, "cubre las 7 etapas y las 24 horas del día (16 huecos)")
check(table.concat(seq, ",") == "1,2,3,4,5,6,7,4,1,2,3,4,5,6,7,4", "en orden 1→2→3→4→5→6→7 y luego se cierra 7→4→(1), dos veces al día: " .. table.concat(seq, ","))
local lines = {}
for _, slot in schedule do
	table.insert(lines, ("%02d:%02d %s(%d)"):format(math.floor(slot.From), math.floor((slot.From % 1) * 60 + 0.5), slot.Phase, slot.Stage))
end
check(true, "horario: " .. table.concat(lines, " · "))
-- Cada minuto del día, en su hueco
local okMinutes = true
for minute = 0, 24 * 60 - 1 do
	local h = minute / 60
	local name = Rift.demoPhase(h)
	local want
	for _, slot in schedule do
		local rel = (h - slot.From) % 24
		if rel < (slot.To - slot.From) % 24 - 1e-9 then
			want = slot.Phase
		end
	end
	if name ~= want then
		okMinutes = false
		print("    " .. h .. " " .. tostring(name) .. " ~= " .. tostring(want))
		break
	end
end
check(okMinutes, "cada minuto del día enseña la etapa de su hueco")
check(Rift.demoPhase(7.999) == "Cerrada" and Rift.demoPhase(8) == "Rasguno" and Rift.demoPhase(16.75) == "Fusion" and Rift.demoPhase(6.74) == "Ultima" and Rift.demoPhase(6.75) == "Cerrada" and Rift.demoPhase(0.5) == "Grande" and Rift.demoPhase(20.25) == "Cerrada" and Rift.demoPhase(21.99) == "Cerrada" and Rift.demoPhase(22) == "Rasguno", "los bordes: 8:00 ya es la 2, 16:45 la 7, 20:15 se cierra, 22:00 empieza otra vez, 6:45 vuelve a la 1")
check(Rift.demoPhase(8.5, 1) == "Crece" and Rift.demoPhase(8.5, -1) == "Cerrada" and Rift.demoPhase(19, 1) == "Cerrada", "el desfase del modo pruebas adelanta o atrasa etapas (y da la vuelta)")
-- Con el horario de verano (shared/DayCycle: pleno día de 08:00 a 21:30, noche cerrada de 22:00 a
-- 07:00): cada fase del ciclo, una vez de día y otra de noche; las que tienen grieta, a pleno día o en
-- noche cerrada TODO su hueco (ni al atardecer ni al amanecer)
local DayCycle = L.load("src/shared/DayCycle")
local seenAt: { [number]: { Day: number, Night: number } } = {}
local fullOk, fullBad = true, ""
for _, slot in schedule do
	local k = table.find(Rift.Demo.Slots, slot.Phase) :: number
	seenAt[k] = seenAt[k] or { Day = 0, Night = 0 }
	local len = (slot.To - slot.From) % 24
	local night = Rift.isNight(slot.From + len / 2)
	if night then
		seenAt[k].Night += 1
	else
		seenAt[k].Day += 1
	end
	if slot.Stage >= 2 then
		for minute = 0, math.floor(len * 60 + 0.5) - 1 do
			local d = DayCycle.darkness(slot.From + minute / 60)
			if d ~= (if night then 1 else 0) then
				fullOk = false
				fullBad = ("%s a las %.2f (oscuridad %.2f)"):format(slot.Phase, slot.From + minute / 60, d)
			end
		end
	end
end
local bothOk = true
for k = 1, 8 do
	bothOk = bothOk and seenAt[k] ~= nil and seenAt[k].Day == 1 and seenAt[k].Night == 1
end
check(bothOk, "cada etapa del ciclo se ve una vez de día y otra de noche")
check(fullOk, "las etapas con grieta caen enteras a pleno día o en noche cerrada " .. fullBad)
local nightStart, dayStart = Rift.demoPhase(DayCycle.NightFrom), Rift.demoPhase(DayCycle.DayFrom)
check(nightStart == "Rasguno" and dayStart == "Rasguno" and Rift.demoPhase(DayCycle.DuskFrom) == "Cerrada" and Rift.demoPhase(DayCycle.DawnFrom) == "Cerrada", "el ciclo de noche empieza a las 22:00 y el de día a las 8:00; al atardecer y al amanecer, cerrada")
local shortest = math.huge
for _, slot in schedule do
	shortest = math.min(shortest, (slot.To - slot.From) % 24)
end
check(math.abs(shortest - Rift.Demo.SlotHours) < 1e-9 and shortest / 24 * GameConfig.DayLengthMinutes * 60 > Rift.Live.Seconds * 3, ("cada etapa dura al menos %.2f min reales (más que la transición de %d s)"):format(shortest / 24 * GameConfig.DayLengthMinutes, Rift.Live.Seconds))

-- Con el ciclo apagado, la de la historia sin cambios; encendido, la de la hora (menos el sueño)
local stories = {
	{ Active = {}, Completed = {} },
	{ Active = { Prologo_Sueno = true }, Completed = {} },
	{ Completed = { Loco_N1_Cosme = true } },
	{ Active = { Saga_06_Coser = true }, Completed = {} },
	{ Completed = { Saga_06_Coser = true } },
	{ Completed = { Saga_12_Graduacion = true } },
	{ Active = { Saga_23_Fusion = true }, Completed = {} },
	{ Completed = { Saga_24_Final = true } },
}
local offOk, onOk = true, true
for _, story in stories do
	local p = Rift.phaseFor(story)
	for _, h in { 0, 7.5, 13, 19.2, 23.9 } do
		offOk = offOk and Rift.effectivePhase(p, h, false) == p
		local on = Rift.effectivePhase(p, h, true)
		onOk = onOk and on == (if p == "Sueno" then "Sueno" else Rift.demoPhase(h))
	end
end
check(offOk, "ciclo apagado: la fase de la historia (phaseFor) sin cambios a cualquier hora")
check(onOk, "ciclo encendido: la de la hora, para todos igual (el sueño del prólogo se queda)")
check(service:find('SetAttribute%("SkyRift", SkyRift.phaseFor%(story%)%)') ~= nil, "el servidor sigue publicando la de la historia (el ciclo lo aplica el cliente con la hora del servidor)")

-- Transiciones: una por cambio, al pasar el reloj
local tr = Rift.newTracker()
local fired: { any } = {}
local h = Rift.Demo.StartHour
local prevSlotName = nil
local changes = 0
for _ = 1, math.floor(48 / 0.01) do -- dos días, en pasos de 36 s de juego
	h = (h + 0.01) % 24
	local name = Rift.demoPhase(h)
	if prevSlotName and name ~= prevSlotName then
		changes += 1
	end
	prevSlotName = name
	local t = Rift.track(tr, name, true)
	if t then
		table.insert(fired, t)
	end
end
check(#fired == changes and changes == 32 and tr.Fired == 32, ("en dos días, una transición por cambio de etapa (%d cambios, %d transiciones)"):format(changes, #fired))
local kinds = {}
for i = 1, 8 do
	local t = fired[i]
	table.insert(kinds, ("%d→%d %s"):format(t.From, t.To, t.Kind))
end
check(table.concat(kinds, ", ") == "1→2 Abre, 2→3 Abre, 3→4 Abre, 4→5 Abre, 5→6 Abre, 6→7 Abre, 7→4 Cierra, 4→1 Cierra", "cada día: " .. table.concat(kinds, ", "))
local tr2 = Rift.newTracker()
check(Rift.track(tr2, "Grande", false) == nil and Rift.track(tr2, "Grande", true) == nil and Rift.track(tr2, "Grande", true) == nil, "al entrar (o hasta que llega tu historia) no salta nada: se ve la etapa de ahora")
check(Rift.track(tr2, "Abierta", true) ~= nil and Rift.track(tr2, "Rota", true) == nil, "misma etapa (Abierta → Rota): sin transición")
check(Rift.transitionFor("Sueno", "Grande") == nil and Rift.transitionFor("Grande", "Sueno") == nil, "del sueño o al sueño: sin transición (es otro sitio)")
-- La línea de tiempo
local Lv = Rift.Live
check(Lv.Seconds >= 10 and Lv.Seconds <= 20, ("dura %d s (entre 10 y 20)"):format(Lv.Seconds))
local a0, aB, aM, aF, aE = Rift.liveAt(0), Rift.liveAt(Lv.BuildUp - 0.01), Rift.liveAt(Lv.MorphAt + Lv.MorphSeconds), Rift.liveAt(Lv.FlashAt + 0.01), Rift.liveAt(Lv.Seconds)
check(a0.Build == 0 and aB.Build > 0.95 and not a0.Morphed and a0.Morph == 0, "se carga poco a poco antes de cambiar")
check(aM.Morph == 1 and aM.Morphed and aF.Flash > 0.95 and aE.Flash == 0, "luego cambia (de la vieja a la nueva) y estalla un destello")
check(aE.Done and aE.Build < 0.01, "y se calma al final")
local flashes, wasOn = 0, false
for i = 0, Lv.Seconds * 20 do
	local on = Rift.liveAt(i / 20).Flash > 0
	if on and not wasOn then
		flashes += 1
	end
	wasOn = on
end
check(flashes == 1, "un solo destello por transición")
local cL, cM = Rift.liveCounts("Low", "Abre", 5), Rift.liveCounts("Medium", "Abre", 5)
check(cL.Debris == 0 and cL.BurstBolts < cM.BurstBolts and cL.Sparks < cM.Sparks and cM.Debris > 0, "gráficos Bajo: sin rocas que se desprenden, menos rayos y chispas")
check(Rift.liveCounts("High", "Cierra", 4).Debris == 0, "al coserse no se desprenden rocas nuevas")

---------------------------------------------------------------------
print("Transición en directo en el cliente (sin cámara, sin interfaz, sin controles)")
---------------------------------------------------------------------
GameConfig.SkyRift.DemoCycle = true
tier = "Medium"
local shakes: { number } = {}
L.mock("src/client/Controllers/CameraShake", {
	shake = function(strength)
		table.insert(shakes, strength)
	end,
})
local pg2 = Instance.new("Folder")
pg2.Name = "PlayerGui"
localPlayer.FindFirstChildOfClass = function(_, className)
	return if className == "PlayerGui" then pg2 else nil
end
lighting.ClockTime = 8.75 -- (Rasguño)
camera.CFrame = roblox.CFrame.lookAt(roblox.Vector3.new(0, 20, 0), roblox.Vector3.new(0, 60, -100))
local camBefore = camera.CFrame
local camTypeBefore = camera.CameraType
local camFovBefore = camera.FieldOfView
Ctl = fresh()
run(12)
st = Ctl.debugState()
check(st.Demo and st.Stage == 2 and st.LiveCount == 0, "quien entra ve la etapa de esa hora (la 2 a las 8:45), sin transición")
local toasts: { string } = {}
local function watchToast()
	local g = pg2:FindFirstChild("AvisoGrieta")
	local tx = g and g:FindFirstChild("Texto")
	if tx and toasts[#toasts] ~= tx.Text then
		table.insert(toasts, tx.Text)
	end
end
local function runWatch(seconds: number, each: (() -> ())?)
	for _ = 1, math.floor(seconds * 20) do
		(stepFn :: (number) -> ())(0.05)
		watchToast()
		if each then
			each()
		end
	end
end
lighting.ClockTime = 9.76 -- (pasa a «Crece»)
runWatch(1)
st = Ctl.debugState()
check(st.Live and st.Live.From == 2 and st.Live.To == 3 and st.Live.Kind == "Abre" and st.LiveCount == 1, "al pasar las 9:45 empieza la transición 2 → 3")
check(st.Stage == 2 and not st.Live.Morphed, "primero se carga la de antes (aún la 2)")
local folderBefore = ws:FindFirstChild("CieloGrieta")
local boltsBefore = st.Bolts
runWatch(2)
check(Ctl.debugState().Bolts > boltsBefore or Ctl.debugState().Bolts >= Rift.liveCounts("Medium", "Abre", 3).BurstBolts, "con más rayos mientras se carga")
local sawGhost, sawRing, sawShock, sawDebris = false, false, false, false
runWatch(8.5, function()
	if ws:FindFirstChild("CieloGrietaAntes") then
		sawGhost = true
	end
	local ev = ws:FindFirstChild("GrietaEvento")
	if ev and ev:FindFirstChild("Onda") then
		sawRing = true
		local stroke = ev.Onda:FindFirstChild("Lienzo") and ev.Onda.Lienzo:FindFirstChild("Anillo") and ev.Onda.Lienzo.Anillo:FindFirstChildOfClass("UIStroke")
		if stroke and stroke.Transparency < 0.5 and ev.Onda.Size.X > 300 then
			sawShock = true
		end
	end
end)
st = Ctl.debugState()
check(st.Stage == 3 and st.Live and st.Live.Morphed, "después nace la 3 (la nueva) en directo")
check(sawGhost and folderBefore ~= nil, "y la de antes se apaga aparte (cruce de las dos)")
check(sawRing and sawShock, "con un destello y una onda expansiva en el cielo")
runWatch(8)
st = Ctl.debugState()
check(st.Live == nil and st.LiveCount == 1 and st.Stage == 3 and st.Open > 0.95, "al acabar: la 3, abierta del todo, y una sola transición")
check(ws:FindFirstChild("CieloGrietaAntes") == nil and ws:FindFirstChild("GrietaEvento") == nil, "no queda nada de la transición")
check(st.Bolts == Rift.counts(3, "Medium").Bolts, "y vuelven los rayos de la etapa")
check(#toasts == 1 and string.find(toasts[1], "grieta crece", 1, true) ~= nil, ("un solo aviso pequeño arriba: «%s»"):format(tostring(toasts[1])))
check(#shakes == 1 and shakes[1] <= 0.15, ("a pie, un temblor muy leve (%.2f)"):format(shakes[1] or -1))
check(camera.CFrame == camBefore and camera.CameraType == camTypeBefore and camera.FieldOfView == camFovBefore, "la cámara, sin tocar (ni tipo, ni sitio, ni campo de visión)")
check(attrs.InCinematic == nil and attrs.InScene == nil, "sin marcas de escena (InCinematic / InScene)")
local others = 0
for _, c in pg2:GetChildren() do
	if c.Name ~= "AvisoGrieta" then
		others += 1
	end
end
check(others == 0, "ninguna pantalla más que el aviso")
local ctlSrc = fs.readFile("src/client/Controllers/SkyRift.luau")
check(not ctlSrc:find("CameraType") and not ctlSrc:find("SceneGuis") and not ctlSrc:find("Controls") and not ctlSrc:find('SetAttribute%("In'), "el código de la grieta no toca la cámara, la interfaz ni los controles")

-- Al volante: sin temblor; en una escena: sin aviso (el cielo cambia igual)
attrs.Riding = "Coche"
shakes = {}
toasts = {}
lighting.ClockTime = 11.52 -- (3 → 4)
runWatch(18)
st = Ctl.debugState()
check(st.Stage == 4 and st.LiveCount == 2 and #shakes == 0, "al volante: el cielo cambia (3 → 4) pero sin temblor")
attrs.Riding = nil
attrs.InCinematic = true
toasts = {}
lighting.ClockTime = 13.27 -- (4 → 5)
runWatch(18)
st = Ctl.debugState()
check(st.Stage == 5 and st.LiveCount == 3 and #toasts == 0, "en plena escena: el cielo cambia (4 → 5) sin aviso encima")
attrs.InCinematic = nil
-- 6 → 7: la luz pasa poco a poco del azul al violeta (dos capas que se cruzan)
lighting.ClockTime = 15.02
runWatch(18)
local crossed = false
lighting.ClockTime = 16.77
runWatch(18, function()
	if layers.GrietaCieloAntes and layers.GrietaCieloAntes.Mood == SkyMoods.List.GrietaAzul and layers.GrietaCielo and layers.GrietaCielo.Mood == SkyMoods.List.GrietaFinal then
		crossed = true
	end
end)
st = Ctl.debugState()
check(st.Stage == 7 and st.LiveCount == 5 and crossed, "6 → 7: la luz pasa del azul al violeta poco a poco")
-- Se cierra: 7 → 4 y 4 → 1 (se cose y se encoge)
lighting.ClockTime = 18.52
local seam = false
runWatch(18, function()
	local g = ws:FindFirstChild("CieloGrietaAntes")
	local lienzo = g and g:FindFirstChild("Grieta") and g.Grieta:FindFirstChild("Lienzo")
	if lienzo and lienzo:FindFirstChild("Costura") and lienzo.Costura.BackgroundTransparency < 0.5 then
		seam = true
	end
end)
st = Ctl.debugState()
check(st.Stage == 4 and st.LiveCount == 6 and seam, "7 → 4: se cose (una costura de luz) y se encoge")
local shrank = false
local firstSize = nil
lighting.ClockTime = 20.27
runWatch(18, function()
	local g = ws:FindFirstChild("CieloGrietaAntes")
	local p = g and g:FindFirstChild("Grieta")
	if p then
		firstSize = firstSize or p.Size.Y
		if p.Size.Y < firstSize * 0.3 then
			shrank = true
		end
	end
end)
run(3)
st = Ctl.debugState()
check(st.Stage == 1 and st.LiveCount == 7 and shrank and ws:FindFirstChild("CieloGrieta") == nil, "4 → 1: se cierra del todo")
check(layers.GrietaCielo == nil, "y la luz vuelve a la normal")

-- Modo pruebas: siguiente etapa para todo el servidor (atributo de workspace)
ws:SetAttribute("SkyRiftDemoOffset", 1)
runWatch(1)
st = Ctl.debugState()
check(st.Live and st.Live.From == 1 and st.Live.To == 2 and st.LiveCount == 8, "«Siguiente etapa» del modo pruebas: transición en directo 1 → 2")
Ctl.finishLive()
check(Ctl.debugState().Live == nil and Ctl.debugState().Stage == 2, "y se puede acabar al momento")
ws:SetAttribute("SkyRiftDemoOffset", nil)
runWatch(20)

-- Gráficos Bajo: sin rocas que se desprenden
tier = "Low"
Ctl = fresh()
lighting.ClockTime = 12
run(3)
local debrisLow = 0
lighting.ClockTime = 13.26
runWatch(16, function()
	debrisLow = math.max(debrisLow, count(ws:FindFirstChild("GrietaEvento"), "Part", "Escombro") + count(ws:FindFirstChild("GrietaEvento"), "WedgePart", "Escombro"))
end)
check(Ctl.debugState().Stage == 5 and debrisLow == 0, "Bajo: la transición sin rocas 3D que se desprenden")
tier = "Medium"
Ctl = fresh()
lighting.ClockTime = 12
run(3)
local debrisMed = 0
lighting.ClockTime = 13.26
runWatch(16, function()
	debrisMed = math.max(debrisMed, count(ws:FindFirstChild("GrietaEvento"), "Part", "Escombro") + count(ws:FindFirstChild("GrietaEvento"), "WedgePart", "Escombro"))
end)
check(debrisMed == Rift.liveCounts("Medium", "Abre", 5).Debris, ("Medio: %d rocas que se desprenden"):format(debrisMed))

---------------------------------------------------------------------
print("Sirenas de la policía y los bomberos (solo en el cambio de etapa, y solo cerca)")
---------------------------------------------------------------------
;(function()
local SR = Rift.Sirens
check(Rift.sirenLevel(nil) == 0 and Rift.sirenLevel(-1) == 0, "sin transición: en silencio")
check(Rift.sirenLevel(0) == 0 and Rift.sirenLevel(SR.FadeIn / 2) > 0 and Rift.sirenLevel(SR.FadeIn / 2) < 1, "sube al empezar (sin golpe)")
check(Rift.sirenLevel(Lv.FlashAt) == 1 and Rift.sirenLevel(Lv.Seconds) == 1, "a tope en la carga, el cambio y el destello")
check(Rift.sirenLevel(Lv.Seconds + SR.Tail / 2) > 0 and Rift.sirenLevel(Lv.Seconds + SR.Tail / 2) < 1 and Rift.sirenLevel(Lv.Seconds + SR.Tail) == 0, ("y al acabar se apaga en %d s"):format(SR.Tail))
check(SR.Tail <= 6 and not Rift.sirenDone(Lv.Seconds) and Rift.sirenDone(Lv.Seconds + SR.Tail) and Rift.sirenDone(nil), "una cola corta y se acaba")
check(SR.MinDistance >= 20 and SR.MinDistance < SR.MaxDistance and SR.MaxDistance >= 150 and SR.MaxDistance <= 260, ("cerca se oye (a tope hasta %d studs) y lejos no (nada desde %d)"):format(SR.MinDistance, SR.MaxDistance))
check(table.find(SR.Tags, "PoliceStation") ~= nil and table.find(SR.Tags, "FireStation") ~= nil, "en las comisarías y en los parques de bomberos")
local anchorAt = Rift.sirenAnchor({
	{ CFrame = roblox.CFrame.new(100, 10, 50), Size = roblox.Vector3.new(44, 20, 30) },
	{ CFrame = roblox.CFrame.new(118, 18, 61) * roblox.CFrame.Angles(0, math.rad(90), 0), Size = roblox.Vector3.new(8, 36, 8) },
})
check(anchorAt and math.abs(anchorAt.Y - (36 + SR.Height)) < 0.01 and math.abs(anchorAt.X - 100) < 0.01 and math.abs(anchorAt.Z - 50) < 0.01, "la sirena va en el tejado (encima de la torre), en el centro del edificio")
check(Rift.sirenAnchor({}) == nil, "sin piezas, sin sitio")
-- El servidor publica el sitio en el modelo
local fakeStation = Instance.new("Model")
local wall = Instance.new("Part")
wall.Size = roblox.Vector3.new(44, 30, 30)
wall.CFrame = roblox.CFrame.new(-450, 15, 575)
wall.Parent = fakeStation
Rift.publishSirenAnchor(fakeStation)
check(fakeStation:GetAttribute("SirenAt") == roblox.Vector3.new(-450, 30 + SR.Height, 575), "el servidor publica dónde va (atributo SirenAt: llega aunque no hayan llegado las piezas)")
for _, path in { "src/server/Services/PoliceService.luau", "src/server/Services/FireService.luau" } do
	check(fs.readFile(path):find("publishSirenAnchor", 1, true) ~= nil, path:match("[^/]+$") .. ": publica la sirena de cada cuartel")
end
-- En el cliente, con una comisaría (sitio publicado) y un parque de bomberos (solo sus piezas)
local police = Instance.new("Model")
police.Name = "Edificio"
police:SetAttribute("SirenAt", roblox.Vector3.new(414, 50, -1970))
police.Parent = ws
local fire = Instance.new("Model")
fire.Name = "Bomberos"
local fireWall = Instance.new("Part")
fireWall.Size = roblox.Vector3.new(44, 28, 34)
fireWall.CFrame = roblox.CFrame.new(416, 14, -2069)
fireWall.Parent = fire
fire.Parent = ws
local taggedWas = L.services.CollectionService.GetTagged
L.services.CollectionService.GetTagged = function(_, tag)
	return if tag == "PoliceStation" then { police } elseif tag == "FireStation" then { fire } else {}
end
local function sirenSounds(): number
	local n = 0
	for _, d in ws:GetDescendants() do
		if d.ClassName == "Sound" and d.Name == "Sirena" then
			n += 1
		end
	end
	return n
end
lighting.ClockTime = 9 -- (Rasguño, sin cambio)
Ctl = fresh()
local quiet = true
for _ = 1, 30 * 20 do
	(stepFn :: (number) -> ())(0.05)
	quiet = quiet and sirenSounds() == 0 and not Ctl.debugState().Sirens.Active
end
check(quiet, "con la grieta en el cielo pero sin cambio de etapa: ninguna sirena (30 s)")
lighting.ClockTime = 9.76 -- (pasa a «Crece»: transición 2 → 3)
run(3)
st = Ctl.debugState()
local sr = st.Sirens
check(st.Live and sr and sr.Active and #sr.Sirens == 2 and sirenSounds() == 2, "al empezar la transición suenan las sirenas: una en la comisaría y otra en los bomberos")
local byKind = {}
for _, s in (sr and sr.Sirens or {}) do
	byKind[s.Kind] = s
end
local pol, fir = byKind.Policia, byKind.Bomberos
check(pol and (pol.Pos - roblox.Vector3.new(414, 50, -1970)).Magnitude < 0.01 and (pol.Part.CFrame.Position - pol.Pos).Magnitude < 0.01, "la de la comisaría, donde dice el servidor")
check(fir and (fir.Pos - roblox.Vector3.new(416, 28 + SR.Height, -2069)).Magnitude < 0.01, "la de los bomberos, en su tejado (con sus piezas)")
local all3d = true
for _, s in (sr and sr.Sirens or {}) do
	all3d = all3d and s.RollOff == roblox.Enum.RollOffMode.Linear and s.Min == SR.MinDistance and s.Max == SR.MaxDistance and s.Looped and s.Volume > 0.5
		and s.Part.Anchored and not s.Part.CanCollide and s.Part.Transparency == 1 and s.Sound.Parent == s.Part
		and s.Sound.SoundId == "rbxassetid://" .. SR.SoundId and math.abs(s.Sound.PlaybackSpeed - SR.Speed) < 1e-6
end
check(all3d, ("en 3D, en una pieza del mundo (invisible, sin colisión) y con caída lineal: a tope hasta %d studs, nada desde %d"):format(SR.MinDistance, SR.MaxDistance))
check(ws:FindFirstChild("CieloGrieta") and ws.CieloGrieta:FindFirstChild("Sirena", true) == nil, "la sirena no va en el cielo (2D en todas partes): va en los cuarteles")
run(Lv.Seconds - 3 - 0.5)
check(Ctl.debugState().Sirens.Level == 1, "a tope hasta el final de la transición")
run(1 + SR.Tail / 2)
st = Ctl.debugState()
check(st.Live == nil and st.Sirens.Active and st.Sirens.Level > 0 and st.Sirens.Level < 1, "acabada la transición, se van apagando")
run(SR.Tail)
st = Ctl.debugState()
check(not st.Sirens.Active and #st.Sirens.Sirens == 0 and sirenSounds() == 0 and ws:FindFirstChild("SirenasGrieta") == nil, "y al poco se paran y se quitan: no se quedan sonando")
quiet = true
for _ = 1, 40 * 20 do
	(stepFn :: (number) -> ())(0.05)
	quiet = quiet and sirenSounds() == 0
end
check(quiet and Ctl.debugState().Stage == 3, "con la etapa nueva ya en el cielo: en silencio (40 s)")
GameConfig.SkyRift.StationSirens = false
lighting.ClockTime = 11.51 -- (3 → 4)
run(4)
check(Ctl.debugState().Live and sirenSounds() == 0, "con Config.SkyRift.StationSirens = false, sin sirenas")
GameConfig.SkyRift.StationSirens = true
run(20)
L.services.CollectionService.GetTagged = taggedWas
police:Destroy()
fire:Destroy()
local sirensSrc = fs.readFile("src/client/Controllers/RiftSirens.luau")
check(sirensSrc:find('group("SFX")', 1, true) ~= nil and sirensSrc:find("SoundGroup = group", 1, true) ~= nil, "las sirenas, en 🔔 Efectos")
check(not ctlSrc:find("PatineteZumbido", 1, true) and not ctlSrc:find("ZumbidoElectrico", 1, true), "la grieta ya no usa el motor del patinete como capa de fondo")
end)()

-- Ciclo apagado: la hora no cambia nada; manda tu historia
GameConfig.SkyRift.DemoCycle = false
Ctl = fresh()
setPhase("Grande")
run(12)
lighting.ClockTime = 0.5
run(3)
st = Ctl.debugState()
check(not st.Demo and st.Stage == 4 and st.LiveCount == 0, "ciclo apagado: la de tu historia (Grande, la 4) aunque cambie la hora")
setPhase("Abierta")
run(1)
check(Ctl.debugState().LiveCount == 1, "y un cambio de la historia también se ve pasar en directo")
run(20)
GameConfig.SkyRift.DemoCycle = demoWas
localPlayer.FindFirstChildOfClass = nil

local testerSrc = fs.readFile("src/server/Services/TesterService.luau")
check(testerSrc:find('"RiftStep"') and testerSrc:find("SkyRiftDemoOffset"), "el modo pruebas (solo testers, lo decide el servidor) adelanta o atrasa la etapa")
local panelSrc = fs.readFile("src/client/UI/TesterPanel.luau")
check(panelSrc:find('"RiftStep", 1') and panelSrc:find('"RiftStep", %-1'), "panel de pruebas: «Siguiente etapa» y «Etapa anterior»")

L.finish("Grieta del cielo")
