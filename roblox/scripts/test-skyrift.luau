-- Prueba de la Grieta del cielo (shared/SkyRift y Controllers/SkyRift) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-skyrift.luau
--
-- Comprueba que:
--   * la forma: una raja principal dentada y larga en diagonal, de 6 a 14 ramas que nacen en la
--     principal y se estrechan hasta la punta, uniones brillantes; siempre la misma (semilla fija)
--   * las capas: núcleo claro (blanco-amarillo), fuego naranja/ámbar más ancho y halo verde-cian muy
--     ancho y transparente; el núcleo emite luz y pasa el umbral del resplandor
--   * abrirse: crece desde el centro, las ramas salen después, todo engorda; intensidad 0 = no se ve
--   * las fases de la saga (de la misión de Cosme al final) y que se abre/cierra poco a poco
--   * el nivel Bajo: sin halo ni partículas, y menos instancias (presupuesto del móvil)
--   * el cliente: lejos (en el cielo), sin colisión ni consultas, y sigue a la cámara

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local Rift = luau.load(fs.readFile("src/shared/SkyRift.luau"), { debugName = "SkyRift" })()

local function dist(a, b): number
	return math.sqrt((a.X - b.X) ^ 2 + (a.Y - b.Y) ^ 2)
end

---------------------------------------------------------------------
print("Forma (raja principal y ramas)")
---------------------------------------------------------------------
local shape = Rift.shape()
local main = shape.Main
local first, last = main.Points[1], main.Points[#main.Points]
check(#main.Points >= 12, ("la principal tiene muchos puntos (%d): dentada, no una barra"):format(#main.Points))
check(dist(first, last) > 1.6, "la principal es larga (cruza el cielo)")
local slope = math.deg(math.atan2(last.Y - first.Y, last.X - first.X))
check(slope > 15 and slope < 60, ("va en diagonal (%.0f°)"):format(slope))

-- Dentada: el zigzag se ve en los giros bruscos entre tramos (la curva de fondo es suave)
local turns = 0
for i = 2, #main.Points - 1 do
	local a, b, c = main.Points[i - 1], main.Points[i], main.Points[i + 1]
	local t1 = math.atan2(b.Y - a.Y, b.X - a.X)
	local t2 = math.atan2(c.Y - b.Y, c.X - b.X)
	local d = math.abs((t2 - t1 + math.pi) % (2 * math.pi) - math.pi)
	if d > math.rad(12) then
		turns += 1
	end
end
check(turns >= #main.Points / 3, ("borde dentado: %d giros bruscos entre tramos"):format(turns))

-- Más ancha en el centro que en las puntas
local mid = main.Widths[math.ceil(#main.Widths / 2)]
check(mid > main.Widths[1] * 3 and mid > main.Widths[#main.Widths] * 3, "la principal es más ancha en el centro y fina en las puntas")

check(#shape.Branches >= 6 and #shape.Branches <= 14, ("%d ramas (de 6 a 14)"):format(#shape.Branches))
local allBorn, allTaper, allThinner, allShort = true, true, true, true
for _, b in shape.Branches do
	-- Nace en un punto de la principal
	local born = false
	for _, p in main.Points do
		if dist(p, b.Points[1]) < 1e-6 then
			born = true
		end
	end
	allBorn = allBorn and born
	-- Se estrecha hasta la punta
	for i = 2, #b.Widths do
		if b.Widths[i] >= b.Widths[i - 1] then
			allTaper = false
		end
	end
	allTaper = allTaper and b.Widths[#b.Widths] < b.Widths[1] * 0.3
	allThinner = allThinner and b.Widths[1] < mid
	local reach = dist(b.Points[1], b.Points[#b.Points])
	allShort = allShort and reach > 0.02 and reach < 0.8
	allShort = allShort and #b.Points >= 3
end
check(allBorn, "cada rama nace en un punto de la principal")
check(allTaper, "cada rama se estrecha hasta acabar en punta")
check(allThinner, "las ramas son más finas que la principal")
check(allShort, "las ramas son laterales (más cortas que la principal)")
check(#shape.Joints >= 3 and #shape.Joints <= Rift.MaxJoints, ("%d uniones brillantes (como mucho %d)"):format(#shape.Joints, Rift.MaxJoints))

-- Determinista: la misma semilla, la misma grieta; otra semilla, otra
local again = Rift.shape()
local same = #again.Branches == #shape.Branches
for i, p in main.Points do
	same = same and math.abs(p.X - again.Main.Points[i].X) < 1e-12 and math.abs(p.Y - again.Main.Points[i].Y) < 1e-12
end
check(same, "determinista: con la semilla fija sale siempre la misma grieta")
local other = Rift.shape(99)
check(math.abs(other.Main.Points[5].Y - main.Points[5].Y) > 1e-6, "otra semilla, otra grieta")
for seed = 1, 60 do
	local s = Rift.shape(seed * 7919)
	if #s.Branches < 6 or #s.Branches > 14 then
		check(false, "semilla " .. seed .. ": ramas fuera de 6-14")
	end
end

---------------------------------------------------------------------
print("Capas de color")
---------------------------------------------------------------------
local L = Rift.Layers
local function lum(c)
	return 0.299 * c[1] + 0.587 * c[2] + 0.114 * c[3]
end
for _, key in { "Color", "Color2" } do
	local core, fire, halo = L.Core[key], L.Fire[key], L.Halo[key]
	check(core[1] >= 240 and core[2] >= 225 and core[3] >= 150 and lum(core) > 225, "núcleo claro, blanco-amarillo (" .. key .. ")")
	check(fire[1] >= 240 and fire[2] >= 110 and fire[2] <= 200 and fire[3] <= 90, "fuego naranja/ámbar (" .. key .. ")")
	check(halo[3] >= 180 and halo[2] >= 180 and halo[1] <= 120, "halo azul-cian/verde-cian (" .. key .. ")")
end
check(L.Core.WidthMul < L.Fire.WidthMul and L.Fire.WidthMul < L.Halo.WidthMul, "de dentro afuera, cada capa más ancha: núcleo < fuego < halo")
check(L.Halo.WidthMul >= 4, "el halo es muy ancho")
check(L.Core.Transparency < L.Fire.Transparency and L.Fire.Transparency < L.Halo.Transparency, "el núcleo opaco, el halo muy transparente")
check(L.Core.LightEmission == 1 and L.Core.Brightness > 2.6, "el núcleo emite luz y pasa el umbral del resplandor (Bloom)")
check(Rift.HaloTexture:find("^rbxasset://") ~= nil and Rift.SparkTexture:find("^rbxasset://") ~= nil, "texturas de Roblox (ninguna imagen de fuera)")

---------------------------------------------------------------------
print("Abrirse (fases de crecimiento) e intensidad")
---------------------------------------------------------------------
local function visibleLength(segs, path: number?): number
	local total = 0
	for _, s in segs do
		if s.Visible and (path == nil or s.Path == path) then
			total += dist(s.A, s.B)
		end
	end
	return total
end
local function visibleCount(segs, branchesOnly: boolean): number
	local n = 0
	for _, s in segs do
		if s.Visible and (not branchesOnly or s.Path > 0) then
			n += 1
		end
	end
	return n
end
local r0, r3, r6, r1 = Rift.reveal(shape, 0), Rift.reveal(shape, 0.3), Rift.reveal(shape, 0.6), Rift.reveal(shape, 1)
check(#r0 == #r1 and #r3 == #r1, "siempre los mismos tramos (el cliente crea uno por tramo)")
check(visibleCount(r0, false) == 0, "cerrada (0): no se ve nada")
check(visibleLength(r3, 0) < visibleLength(r6, 0) and visibleLength(r6, 0) < visibleLength(r1, 0), "la principal crece al abrirse")
check(visibleCount(r3, true) < visibleCount(r1, true), "las ramas van saliendo al abrirse")
check(visibleCount(r1, true) >= #shape.Branches, "abierta del todo: se ven todas las ramas")
-- Crece desde el centro: el punto medio se ve ya con poca apertura
local centre = Rift.reveal(shape, 0.1)
check(visibleCount(centre, false) > 0 and visibleLength(centre, 0) < visibleLength(r1, 0) * 0.2, "empieza a abrirse por el centro")
local wSmall, wBig = 0, 0
for i, s in r3 do
	if s.Visible and s.Path == 0 then
		wSmall = math.max(wSmall, s.W0)
		wBig = math.max(wBig, r1[i].W0)
	end
end
check(wSmall < wBig, "al abrirse, la raja engorda")
local h1 = Rift.halo(shape, 1)
local haloVisible = 0
for _, s in h1 do
	if s.Visible then
		haloVisible += 1
	end
end
check(haloVisible > 0 and #h1 < #r1, "halo en pocos tramos largos")

local t0 = Rift.layerLook("Core", 0, 1, 1)
check(t0 == 1, "intensidad 0: transparente del todo")
local tCoreHalf = Rift.layerLook("Core", 0.5, 1, 1)
local tCoreFull, bCoreFull = Rift.layerLook("Core", 1, 1, 1)
check(tCoreFull < tCoreHalf and tCoreHalf < 1, "más intensidad, más se ve")
local _, bDay = Rift.layerLook("Core", 1, 1, Rift.skyFactor(13))
check(bDay < bCoreFull and Rift.skyFactor(23) == 1 and Rift.skyFactor(13) < 0.7, "de noche se ve del todo; de día, menos")
local lo, hi = math.huge, -math.huge
for k = 1, 400 do
	local p = Rift.pulse(k * 0.037, k % 9)
	lo, hi = math.min(lo, p), math.max(hi, p)
end
check(hi - lo > 0.1 and lo > 0.65 and hi < 1.15, ("late y parpadea un poco (pulso %.2f-%.2f)"):format(lo, hi))

-- Se abre y se cierra poco a poco
local o, secs = 0, 0
while o < 1 and secs < 60 do
	o = Rift.approach(o, 1, 0.1)
	secs += 0.1
end
check(secs > 4 and secs < 15, ("se abre poco a poco (%.1f s de cerrada a abierta)"):format(secs))

---------------------------------------------------------------------
print("Fases de la saga")
---------------------------------------------------------------------
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
local ACT1 = { "Loco_N1_Cosme", "Saga_02_Grieta", "Saga_03_Pez", "Saga_04_Ventanilla", "Saga_05_Perdidas" }
check(phase() == "Ninguna", "sin saga: no hay grieta")
check(phase({ Prologo_Sueno = {} }) == "Sueno", "prólogo: la grieta del sueño (encima de la isla)")
check(Rift.phase("Sueno").Mode == "Dream" and Rift.phase("Crece").Mode == "Sky", "en el sueño, fija sobre la isla; en Valmar, en el cielo")
check(phase({ Loco_N1_Cosme = {} }) == "Ninguna", "mientras conoces a Cosme aún no está (sale al final)")
check(phase({}, done("Loco_N1_Cosme"), { GrietaVista = true }) == "Rasguno", "tras conocer a Cosme: un rasguño de luz")
check(phase({ Saga_02_Grieta = {} }, done("Loco_N1_Cosme")) == "Crece", "«La grieta en el cielo»: ha crecido")
check(phase({ Saga_05_Perdidas = {} }, done("Loco_N1_Cosme", "Saga_02_Grieta", "Saga_03_Pez", "Saga_04_Ventanilla")) == "Grande", "la noche de las cosas perdidas: más grande")
check(phase({ Saga_06_Coser = {} }, done(table.unpack(ACT1))) == "Abierta", "«Coser el cielo»: abierta del todo")
local c6 = done(table.unpack(ACT1))
c6.Saga_06_Coser = 1
check(phase({}, c6) == "Cosida", "cosida: solo una cicatriz")
check(phase({ Saga_07_Costuras = {} }, c6) == "Hilachas", "Acto II: las costuras se sueltan")
c6.Saga_12_Graduacion = 1
check(phase({ Saga_13_SinCosme = {} }, c6) == "Rota", "Acto III: la costura rota")
c6.Saga_18_Precio = 1
check(phase({ Saga_19_Recuerdos = {} }, c6) == "Inminente", "Acto IV: la Gran Fusión se acerca")
check(phase({ Saga_23_Fusion = {} }, c6) == "Fusion", "la batalla final: abierta del todo")
c6.Saga_23_Fusion = 1
check(phase({ Saga_24_Final = {} }, c6) == "Ultima", "la última costura: se va cerrando")
c6.Saga_24_Final = 1
check(phase({}, c6) == "Cerrada" and phase({}, {}, { SagaCompleta = true }) == "Cerrada", "fin de la saga: cerrada para siempre")
local P = Rift.Phases
check(P.Rasguno.Open < P.Crece.Open and P.Crece.Open < P.Grande.Open and P.Grande.Open < P.Abierta.Open, "Acto I: cada vez más abierta")
check(P.Rasguno.Intensity < P.Crece.Intensity and P.Crece.Intensity <= P.Abierta.Intensity, "Acto I: cada vez más intensa")
check(P.Cosida.Open < P.Hilachas.Open and P.Hilachas.Open < P.Rota.Open and P.Rota.Open < P.Fusion.Open, "se reabre por actos hasta la Gran Fusión")
check(P.Fusion.Sparks >= P.Abierta.Sparks and P.Cerrada.Intensity == 0 and P.Ninguna.Open == 0, "la Fusión, con más chispas; cerrada, nada")
for name, p in P do
	if p.Open < 0 or p.Open > 1 or p.Intensity < 0 or p.Intensity > 1 then
		check(false, name .. ": Open e Intensity entre 0 y 1")
	end
end

---------------------------------------------------------------------
print("Niveles gráficos (móvil)")
---------------------------------------------------------------------
local low, med, high = Rift.tierLook("Low"), Rift.tierLook("Medium"), Rift.tierLook("High")
check(not low.Halo and not low.Particles, "Bajo: sin halo ni partículas")
check(table.find(low.Layers, "Core") ~= nil and table.find(low.Layers, "Fire") ~= nil, "Bajo: la raja sigue siendo naranja con núcleo claro")
check(med.Halo and med.Particles and high.Halo and high.Particles, "Medio y Alto: con halo y partículas")
local bl, bh = Rift.budget(shape, "Low"), Rift.budget(shape, "High")
check(bl.Emitters == 0 and bl.Beams < bh.Beams, ("Bajo gasta menos (%d beams, 0 emisores; Alto: %d beams, %d emisores)"):format(bl.Beams, bh.Beams, bh.Emitters))
check(bh.Beams <= 140 and bh.Emitters <= 12, "presupuesto: como mucho 140 beams y 12 emisores")

---------------------------------------------------------------------
print("Cliente (Controllers/SkyRift)")
---------------------------------------------------------------------
local src = fs.readFile("src/client/Controllers/SkyRift.luau")
local sky = Rift.Placement.Sky
check(sky.Distance >= 300 and sky.Scale >= 200, ("en el cielo: a %d studs de la cámara"):format(sky.Distance))
local d = sky.Direction
local elev = math.deg(math.atan2(d[2], math.sqrt(d[1] ^ 2 + d[3] ^ 2)))
check(elev > 20 and elev < 60, ("a media altura en el cielo (%.0f° de elevación)"):format(elev))
check(src:find("CanCollide = false") and src:find("CanQuery = false") and src:find("CanTouch = false") and src:find("CastShadow = false"), "sin colisión, sin consultas, sin toques ni sombra")
check(src:find("camera.CFrame.Position") and src:find("BindToRenderStep"), "sigue a la cámara cada fotograma (no se puede alcanzar)")
check(src:find("LockedToPart = true"), "las partículas van con la grieta")
check(src:find("Segments = 1"), "beams de un solo tramo (baratos)")
check(src:find('GetAttribute%("SkyRift"%)'), "lee la fase del atributo SkyRift (lo publica el servidor)")
local service = fs.readFile("src/server/Services/LifeStoryService.luau")
check(service:find('SetAttribute%("SkyRift", SkyRift.phaseFor%(story%)%)'), "el servidor publica la fase según la historia")
local island = fs.readFile("src/server/World/Kit/DreamIsland.luau")
check(island:find("Vector3.new%(%-3400, 700, %-3400%)") and Rift.Placement.Dream.Center[1] == -3400 + 82, "la del sueño está encima de la isla (DreamIsland.Origin)")
check(not island:find('Name = "Grieta"'), "ya no está la barra de neón verde de antes")
local main = fs.readFile("src/client/Main.client.luau")
check(main:find("Controllers.SkyRift"), "Main.client arranca la Grieta")

print("")
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Grieta del cielo: todo correcto")
