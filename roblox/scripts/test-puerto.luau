-- Prueba del PUERTO DE VALMAR (docs/mapa/puerto.md), con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-puerto.luau                 solo el plano (shared/Port/PuertoPlan, Boats)
--   lune run scripts/test-puerto.luau /tmp/x.rbxl     además, el puerto del mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl
--
-- Comprueba:
--   * la costa de la isla (CityPlan.Coast) es la de siempre y la dársena está dentro de la tierra del
--     puerto, abierta al mar; los muelles rodean el agua (cada cara de muelle tiene agua delante);
--   * los barcos (shared/Boats) entran en la dársena y no pasan por los muelles;
--   * (mapa) están todas las partes de un puerto de verdad: muelles, dársena, grúas pórtico, patio de
--     contenedores, buque, remolcadores, pesqueros, veleros, pantalanes, lonja, fábrica de hielo,
--     estación marítima con la barca, naves, vía de carga, oficinas, torre de control, control de
--     acceso, valla, torres de luz, dique con tetrápodos y baliza, bolardos, defensas, escaleras;
--   * el cartel «PUERTO DE VALMAR» está de pie (no tumbado en el suelo);
--   * los barcos están amarrados junto a un muelle o un pantalán, en el agua y sin meterse en el hormigón;
--   * nada del puerto pisa calles, la boca de metro, las paradas, la playa o el bosque, y nada ajeno
--     se mete en el puerto;
--   * pesca, barco de pesca, barca a la isla, tablón de pescadores, encargos, gente del sitio y mapa
--     encuentran su sitio;
--   * presupuesto de piezas y luces para el móvil.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3

local failures = 0
local function check(ok: boolean, what: string)
	print((if ok then "  ✅ " else "  ❌ ") .. what)
	if not ok then
		failures += 1
	end
end

local CityPlan = L.load("src/shared/CityPlan")
local Plan = L.load("src/shared/Port/PuertoPlan")
local Boats = L.load("src/shared/Boats")

---------------------------------------------------------------------
print("▶ Plano del puerto (shared/Port/PuertoPlan)")

-- La costa de siempre (la del puerto viejo): si alguien la toca, esta suma cambia
local sum, n = 0, 0
for i, p in CityPlan.Coast do
	sum += p[1] * (i % 7 + 1) + p[2] * (i % 5 + 2)
	n += 1
end
check(n == 39 and sum == 27450, ("la costa de la isla no ha cambiado (%d puntos, suma %d)"):format(n, sum))
check(CityPlan.Places.PuertoMercancias[1] == 700 and CityPlan.Places.PuertoMercancias[2] == 3300, "el puerto sigue en su sitio del plano (PuertoMercancias 700, 3300)")

local b = Plan.Basin
local insideN, outsideS = 0, 0
for x = b.X0 + 10, b.X1 - 10, 20 do
	if CityPlan.inside(CityPlan.Coast, x, b.Z0 + 5) then
		insideN += 1
	end
	if not CityPlan.inside(CityPlan.Coast, x, b.Z1 - 2) then
		outsideS += 1
	end
end
check(insideN >= 15 and outsideS >= 15, ("la dársena se excava en la tierra del puerto (%d) y se abre al mar por el sur (%d)"):format(insideN, outsideS))

local q = Plan.Quays
check(q.North.Z1 == b.Z0 and q.North.X0 <= b.X0 and q.North.X1 >= b.X1, "el muelle norte toca el agua en toda la dársena")
check(q.West.X1 == b.X0 and q.West.Z0 == b.Z0 and q.West.Z1 >= b.Z1, "el muelle oeste toca el agua de punta a punta")
check(q.East.X0 == b.X1 and q.East.Z0 == b.Z0 and q.East.Z1 >= b.Z1, "el muelle este toca el agua y sigue mar adentro hasta el dique")
check(Plan.Breakwater.X1 >= q.East.X1 and Plan.Breakwater.Z0 >= b.Z1, "el dique de abrigo sale del muelle este y cierra por el sur")

-- Lo que el puerto no pisa
local keepOk = true
for _, k in Plan.Keep do
	for _, r in Plan.Aprons do
		if Plan.overlaps(k.Rect, r) then
			keepOk = false
			print("    explanada sobre " .. k.Name)
		end
	end
	for _, r in q do
		if Plan.overlaps(k.Rect, r) then
			keepOk = false
			print("    muelle sobre " .. k.Name)
		end
	end
	if Plan.overlaps(k.Rect, b) then
		keepOk = false
	end
end
check(keepOk, "explanadas, muelles y dársena no pisan la calle, la boca de metro, la playa ni el bosque")

-- Barcos: la dársena es mar; los muelles y el puerto en tierra, no
local seaOk = Boats.isSea(660, 3420) and Boats.isSea(520, 3330) and Boats.isSea(800, 3540)
local landOk = not Boats.isSea(455, 3400) and not Boats.isSea(865, 3400) and not Boats.isSea(600, 3294) and not Boats.isSea(600, 3220) and not Boats.isSea(0, 0)
check(seaOk, "la dársena es mar para los barcos (entran hasta los muelles)")
check(landOk, "los muelles, el patio y el centro de Valmar siguen siendo tierra")
local route = true
local from, to = Vector3.new(600, Boats.SeaLevel, 3700), Vector3.new(600, Boats.SeaLevel, 3420)
check(Boats.canMove(from, to, Vector3.new(0, 0, -1), Vector3.new(6, 2, 16)), "un barco entra por la bocana hasta el pantalán")
route = Boats.canMove(Vector3.new(660, Boats.SeaLevel, 3420), Vector3.new(660, Boats.SeaLevel, 3250), Vector3.new(0, 0, -1), Vector3.new(6, 2, 16))
check(not route, "y se para en el muelle norte (no sube a tierra)")
check(Plan.coastZ(700) > 3460 and Plan.coastZ(700) < 3480, ("la costa en X = 700 está donde siempre (Z = %.0f)"):format(Plan.coastZ(700)))

-- Una malla retirada por la moderación de Roblox (docs/bugs/moderacion/): ese objeto sigue con sus piezas
do
	local okM, PuertoMeshes = pcall(L.load, "src/server/World/PuertoMeshes")
	local okR, Retiradas = pcall(L.load, "src/server/World/MallasRetiradas")
	if okM and okR then
		local function mesh(id: number): any
			local mp = roblox.Instance.new("MeshPart")
			mp.MeshId = "rbxassetid://" .. id
			return mp
		end
		local templates = { Bolardo = mesh(next(Retiradas.Ids)), Tetrapodo = mesh(6001), GruaSTS = mesh(6002) }
		local okD, dropped = pcall(PuertoMeshes.drop, templates)
		check(okD and templates.Bolardo == nil and templates.Tetrapodo ~= nil and #dropped == 1, "PuertoMeshes: la malla retirada se quita (ese bolardo, con sus piezas) y no hay error")
		local okD2 = pcall(PuertoMeshes.drop, { Tetrapodo = mesh(6001) }, function()
			error("se rompe")
		end)
		check(okD2, "PuertoMeshes: si la comprobación se rompe, sigue sin error")
	else
		check(false, "World/PuertoMeshes y World/MallasRetiradas se cargan")
	end
end

---------------------------------------------------------------------
local placePath = process.args[1]
if not placePath then
	print(if failures == 0 then "\n✅ Plano del puerto bien (sin mapa construido)" else ("\n❌ %d fallos"):format(failures))
	process.exit(if failures == 0 then 0 else 1)
end

print("▶ Leyendo el mapa…")
local game = roblox.deserializePlace(fs.readFile(placePath))
local town = game:GetService("Workspace"):FindFirstChild("Town")
assert(town, "el mapa no tiene la ciudad construida (Workspace.Town)")
local puerto = town:FindFirstChild("Puerto")
local darsena = town:FindFirstChild("PuertoDarsena")
check(puerto ~= nil and puerto:IsA("Model") and darsena ~= nil, "están Town.Puerto (tierra) y Town.PuertoDarsena (agua)")
if not (puerto and darsena) then
	process.exit(1)
end

local function all(name: string, root: Instance?): { Instance }
	local out = {}
	for _, d in (root or town):GetDescendants() do
		if d.Name == name then
			table.insert(out, d)
		end
	end
	return out
end
local function both(name: string): { Instance }
	local out = all(name, puerto)
	for _, d in all(name, darsena) do
		table.insert(out, d)
	end
	return out
end
local function tagged(tag: string, root: Instance?): { Instance }
	local out = {}
	for _, d in (root or town):GetDescendants() do
		if d:HasTag(tag) then
			table.insert(out, d)
		end
	end
	return out
end

-- Caja (en planta) de una pieza girada
local function aabb(p: BasePart): (number, number, number, number, number, number)
	local cf, s = p.CFrame, p.Size / 2
	local x0, x1, y0, y1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge, math.huge, -math.huge
	for _, dx in { -1, 1 } do
		for _, dy in { -1, 1 } do
			for _, dz in { -1, 1 } do
				local w = cf * Vector3.new(dx * s.X, dy * s.Y, dz * s.Z)
				x0, x1 = math.min(x0, w.X), math.max(x1, w.X)
				y0, y1 = math.min(y0, w.Y), math.max(y1, w.Y)
				z0, z1 = math.min(z0, w.Z), math.max(z1, w.Z)
			end
		end
	end
	return x0, x1, y0, y1, z0, z1
end
local function modelBox(m: Instance): (number, number, number, number, number, number)
	local x0, x1, y0, y1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge, math.huge, -math.huge
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Cabo" then -- (los cabos de amarre llegan al muelle)
			local a, bb, c, dd, e, f = aabb(d)
			x0, x1, y0, y1, z0, z1 = math.min(x0, a), math.max(x1, bb), math.min(y0, c), math.max(y1, dd), math.min(z0, e), math.max(z1, f)
		end
	end
	return x0, x1, y0, y1, z0, z1
end

---------------------------------------------------------------------
print("▶ Lo que tiene un puerto de verdad")
local counts = {
	{ "GruaPortico", 3, "grúas pórtico de muelle (STS) con pluma de celosía" },
	{ "Buque", 1, "buque portacontenedores amarrado" },
	{ "Remolcador", 2, "remolcadores" },
	{ "Pesquero", 4, "pesqueros amarrados" },
	{ "Velero", 2, "veleros en el pantalán deportivo" },
	{ "BarcaIsla", 1, "barca de la Isla del Faro en su atraque" },
	{ "PantalanPesca", 1, "pantalán de pesca" },
	{ "PantalanDeportivo", 1, "pantalán deportivo" },
	{ "Lonja", 1, "lonja" },
	{ "FabricaHielo", 1, "fábrica de hielo" },
	{ "EstacionMaritima", 1, "estación marítima" },
	{ "Nave", 2, "naves (almacenes) con puertas enrollables" },
	{ "ViaDeCarga", 1, "vía de carga con vagones" },
	{ "OficinasPuerto", 1, "capitanía y oficinas" },
	{ "TorreControl", 1, "torre de control" },
	{ "ControlAcceso", 1, "control de acceso (aduana) con barreras" },
	{ "Valla", 1, "valla de la terminal" },
	{ "TorreLuz", 6, "torres de iluminación" },
	{ "Tetrapodo", 20, "tetrápodos en el dique" },
	{ "Baliza", 1, "baliza en la punta del dique" },
	{ "Bolardo", 40, "bolardos" },
	{ "Defensa", 15, "defensas de goma" },
	{ "Neumatico", 15, "neumáticos colgados" },
	{ "Cabo", 10, "cabos de amarre" },
	{ "Portacontenedores", 1, "pórtico apilador (straddle carrier)" },
	{ "Apiladora", 1, "grúa apiladora (reach stacker)" },
	{ "Camion", 2, "camiones portacontenedores" },
}
for _, c in counts do
	local found = #both(c[1])
	check(found >= c[2], ("%s: %d (mín. %d)"):format(c[3], found, c[2]))
end
local containers = #both("Contenedor")
check(containers >= 60, ("contenedores apilados de colores: %d"):format(containers))
local colors = {}
for _, p in both("Contenedor") do
	colors[(p :: BasePart).Color:ToHex()] = true
end
local nColors = 0
for _ in colors do
	nColors += 1
end
check(nColors >= 8, ("de colores variados (%d colores)"):format(nColors))
local ladders = 0
for _, p in darsena:GetDescendants() do
	if p:IsA("TrussPart") then
		ladders += 1
	end
end
check(ladders == #Plan.Ladders, ("escaleras para salir del agua: %d"):format(ladders))
local lightsOn = 0
for _, l in tagged("StreetLamp", puerto) do
	if l:FindFirstChildWhichIsA("Light") then
		lightsOn += 1
	end
end
for _, l in tagged("StreetLamp", darsena) do
	if l:FindFirstChildWhichIsA("Light") then
		lightsOn += 1
	end
end
check(lightsOn >= 6 and #tagged("StreetLamp", puerto) + #tagged("StreetLamp", darsena) >= 20, ("luces de noche: %d focos con luz de verdad"):format(lightsOn))
check(#tagged("NightWindow", puerto) + #tagged("NightWindow", darsena) >= 10, "ventanas que se encienden de noche")

-- El cartel del puerto, de pie
local standing, signs = 0, 0
for _, s in both("Sign") do
	local gui = s:FindFirstChildWhichIsA("SurfaceGui")
	local label = gui and gui:FindFirstChildWhichIsA("TextLabel")
	if label and string.find(string.upper(label.Text), "PUERTO DE VALMAR", 1, true) then
		signs += 1
		local up = (s :: BasePart).CFrame.UpVector
		local _, _, y0 = aabb(s :: BasePart)
		if up.Y > 0.99 and y0 > Plan.Ground + 2 then
			standing += 1
		end
	end
end
check(signs >= 2 and standing == signs, ("carteles «PUERTO DE VALMAR» de pie y en alto: %d de %d"):format(standing, signs))

---------------------------------------------------------------------
print("▶ Muelles y agua")
local north = darsena:FindFirstChild("MuelleNorte") :: BasePart?
local okTop = true
for _, name in { "MuelleNorte", "MuelleOeste", "MuelleEste" } do
	local p = darsena:FindFirstChild(name) :: BasePart?
	if not p then
		okTop = false
	else
		local _, _, y0, y1 = aabb(p)
		if math.abs(y1 - Plan.Ground) > 0.01 or y0 > Plan.BasinFloor then
			okTop = false
		end
	end
end
check(north ~= nil and okTop, "muelles de hormigón con muro vertical del fondo (Y = -22) a la explanada (Y = 1)")
-- Delante de cada cara de muelle, agua (dársena) y nada de hormigón
local faces = {
	{ "norte", function(t)
		return Vector3.new(b.X0 + t * (b.X1 - b.X0), 0, b.Z0 + 3)
	end },
	{ "oeste", function(t)
		return Vector3.new(b.X0 + 3, 0, b.Z0 + t * (b.Z1 - b.Z0))
	end },
	{ "este", function(t)
		return Vector3.new(b.X1 - 3, 0, b.Z0 + t * (b.Z1 - b.Z0))
	end },
}
for _, f in faces do
	local ok = true
	for i = 1, 19 do
		local p = f[2](i / 20)
		if not Plan.inBasin(p.X, p.Z) or Plan.onQuay(p.X, p.Z) or not Boats.isSea(p.X, p.Z) then
			ok = false
		end
	end
	check(ok, "cara " .. f[1] .. " de la dársena: agua navegable pegada al muro")
end

-- Relieve: dentro de la dársena no sale ninguna loma (el mapa horneado del relieve)
local Relief = L.load("src/shared/Relief")
local value = game:GetService("ReplicatedStorage"):FindFirstChild("ReliefMap")
local field = value and Relief.fromValue(value)
if field then
	local flat = true
	for x = b.X0 + 5, b.X1 - 5, 15 do
		for z = b.Z0 + 5, b.Z1 - 5, 15 do
			if Relief.height(field, x, z) > 0.05 then
				flat = false
			end
		end
	end
	check(flat, "el relieve no levanta lomas en la dársena ni en los muelles")
else
	print("  (sin el mapa del relieve en el archivo)")
end

---------------------------------------------------------------------
print("▶ Barcos amarrados en muelles y pantalanes")
local pontoonZ = {}
for _, pt in Plan.Pontoons do
	table.insert(pontoonZ, pt.Z)
end
local function nearBerth(cx: number, cz: number, x0: number, x1: number, z0: number, z1: number): boolean
	-- junto a una cara de muelle o a un pantalán (a menos de 6 studs del casco)
	if z0 - b.Z0 < 6 and z0 >= b.Z0 - 0.5 then
		return true
	end
	if x0 - b.X0 < 6 and x0 >= b.X0 - 0.5 then
		return true
	end
	if b.X1 - x1 < 6 and x1 <= b.X1 + 0.5 then
		return true
	end
	if x1 <= q.West.X0 + 0.5 and q.West.X0 - x1 < 6 then
		return true -- (la barca, por fuera del dique oeste)
	end
	for _, z in pontoonZ do
		if math.abs(cz - z) < 20 then
			return true
		end
	end
	return false
end
local boatsOk, boatsN = true, 0
for _, name in { "Buque", "Remolcador", "Pesquero", "Velero", "BarcaIsla" } do
	for _, m in all(name, darsena) do
		boatsN += 1
		local x0, x1, y0, _, z0, z1 = modelBox(m)
		local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
		local inWater = Boats.isSea(cx, cz) and y0 < Plan.SeaLevel
		local hitsQuay = false
		for _, r in q do
			if x0 < r.X1 - 0.6 and x1 > r.X0 + 0.6 and z0 < r.Z1 - 0.6 and z1 > r.Z0 + 0.6 then
				hitsQuay = true
			end
		end
		if not inWater or hitsQuay or not nearBerth(cx, cz, x0, x1, z0, z1) then
			boatsOk = false
			print(("    %s en (%.0f, %.0f): agua %s, muelle %s"):format(name, cx, cz, tostring(inWater), tostring(hitsQuay)))
		end
	end
end
check(boatsOk and boatsN >= 10, ("%d barcos: todos a flote, junto a un muelle o un pantalán y sin meterse en el hormigón"):format(boatsN))

---------------------------------------------------------------------
print("▶ Sin pisar a nadie")
local mine = {}
for _, d in puerto:GetDescendants() do
	mine[d] = true
end
for _, d in darsena:GetDescendants() do
	mine[d] = true
end
local area = Plan.Area
local intruders = {}
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") and not mine[d] and not d:HasTag("EditOnly") then
		local p = d.CFrame.Position
		local kept = false
		for _, k in Plan.Keep do
			if Plan.inRect(k.Rect, p.X, p.Z) then
				kept = true -- (la boca de metro y la calle son suyas)
			end
		end
		-- (bajo tierra va el metro: no cuenta)
		if not kept and p.Y > -4 and Plan.inRect(area, p.X, p.Z) and d.Size.Magnitude < 400 then
			local top = d.Parent and d.Parent.Name or "?"
			intruders[top] = (intruders[top] or 0) + 1
		end
	end
end
local list = {}
for k, v in intruders do
	table.insert(list, k .. " ×" .. v)
end
-- (lo de dentro del recinto que es del puerto de siempre: el barco de pesca de alta mar va en la dársena)
check(#list == 0, "nada ajeno dentro del recinto del puerto" .. (if #list > 0 then " (" .. table.concat(list, ", ") .. ")" else ""))
local overlapKeep = 0
for d in mine do
	if d:IsA("BasePart") then
		local x0, x1, _, _, z0, z1 = aabb(d)
		for _, k in Plan.Keep do
			if x0 < k.Rect.X1 and x1 > k.Rect.X0 and z0 < k.Rect.Z1 and z1 > k.Rect.Z0 then
				overlapKeep += 1
				if overlapKeep <= 5 then
					print(("    %s (%.0f..%.0f, %.0f..%.0f) pisa %s"):format(d:GetFullName(), x0, x1, z0, z1, k.Name))
				end
			end
		end
	end
end
check(overlapKeep == 0, "ninguna pieza del puerto pisa la calle, la boca de metro, la playa ni el bosque")
-- Calles y metro de verdad: ninguna pieza del puerto toca una calzada
local roads = {}
for _, folder in { "Streets", "MainRoads" } do
	local f = town:FindFirstChild(folder)
	if f then
		for _, d in f:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "Road" then
				local x0, x1, _, _, z0, z1 = aabb(d)
				if x1 > area.X0 - 50 and x0 < area.X1 + 50 and z1 > area.Z0 - 60 and z0 < area.Z1 then
					table.insert(roads, { x0, x1, z0, z1 })
				end
			end
		end
	end
end
local onRoad = 0
for d in mine do
	if d:IsA("BasePart") then
		local x0, x1, _, _, z0, z1 = aabb(d)
		for _, r in roads do
			if x0 < r[2] and x1 > r[1] and z0 < r[4] and z1 > r[3] then
				onRoad += 1
			end
		end
	end
end
check(#roads > 0 and onRoad == 0, ("nada del puerto sobre la calzada (%d tramos de calle cerca)"):format(#roads))

---------------------------------------------------------------------
print("▶ Juego: pesca, barcos, barca, trabajos, encargos, mapa")
local spots = tagged("FishingSpot", darsena)
local sea = 0
for _, s in spots do
	if s:GetAttribute("Water") == "Mar" then
		local p = (s :: BasePart).CFrame * Vector3.new(0, 0, -((s:GetAttribute("CastDistance") :: number?) or 10))
		if Boats.isSea(p.X, p.Z) and not Plan.onQuay(p.X, p.Z) then
			sea += 1
		end
	end
end
check(sea >= 8, ("sitios de pesca en el puerto: %d (el corcho cae al agua)"):format(sea))
check(#tagged("FishingNpcSpot", darsena) == 1, "el pescador del puerto tiene su sitio")
local docks = tagged("FishingBoatDock")
local dockOk = #docks == 1
if dockOk then
	local back = (docks[1] :: BasePart).CFrame.Position + Vector3.new(0, 1, -5)
	dockOk = Plan.onQuay(back.X, back.Z)
end
check(dockOk, "amarre del barco de pesca en el muelle pesquero (al volver, se aparece sobre el muelle)")
check(#tagged("FishingBoatDeck") == 1 and #tagged("FishingBoatReturn") == 1, "el barco de pesca de alta mar sigue (cubierta y vuelta a puerto)")
local ferryOut, ferryBack = nil, nil
for _, p in tagged("Ferry") do
	local target = p:GetAttribute("Target")
	if p:IsDescendantOf(puerto) then
		ferryOut = target
	elseif typeof(target) == "Vector3" and (target - Plan.FerryArrival).Magnitude < 0.01 then
		ferryBack = target
	end
end
local island = CityPlan.Islands[1]
check(typeof(ferryOut) == "Vector3" and ((ferryOut :: Vector3) - Vector3.new(island.X, 0, island.Z)).Magnitude < island.R, "la taquilla de la estación marítima lleva a la Isla del Faro")
check(ferryBack ~= nil and Plan.onQuay(Plan.FerryArrival.X, Plan.FerryArrival.Z), "y la barca de vuelta te deja en el muelle, junto a la rampa")
local boards = tagged("JobBoard", puerto)
local fisher = false
for _, bd in boards do
	if bd:GetAttribute("JobId") == "Pescador" then
		fisher = true
	end
end
check(fisher, "tablón de trabajo de pescador (Config.Jobs.Pescador.Place = «Puerto»)")
local _, _, py0 = modelBox(puerto)
check(py0 >= Plan.Ground - 2.5, ("el modelo «Puerto» empieza a ras de suelo (Y = %.1f): encargos y gente del sitio pisan la explanada"):format(py0))
local MapInfo = L.load("src/shared/MapInfo")
check(MapInfo.KindByModel.Puerto ~= nil, "sale en el mapa como «Puerto de Valmar»")
local px0, px1, _, _, pz0, pz1 = modelBox(puerto)
local mx, mz = (px0 + px1) / 2, (pz0 + pz1) / 2
check(CityPlan.inside(CityPlan.Districts[6].Poly, mx, mz), ("y está en el Distrito Sur (%.0f, %.0f)"):format(mx, mz))
local worldService = fs.readFile("src/server/Services/WorldService.luau")
local rolesOk = true
for _, w in all("WorkerSpot", puerto) do
	local role = w:GetAttribute("Role")
	if not string.find(worldService, '["' .. tostring(role) .. '"]', 1, true) then
		rolesOk = false
	end
end
check(#all("WorkerSpot", puerto) >= 4 and rolesOk, "trabajadores del puerto (estibadores, guardia, pescadera, marinero) con su uniforme")

---------------------------------------------------------------------
print("▶ Presupuesto (móvil)")
local parts, lights, models, atomic = 0, 0, 0, 0
for _, root in { puerto, darsena } do
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		elseif d:IsA("Light") then
			lights += 1
		elseif d:IsA("Model") then
			models += 1
			local ok, mode = pcall(function()
				return (d :: any).ModelStreamingMode
			end)
			if ok and mode == roblox.Enum.ModelStreamingMode.Atomic then
				atomic += 1
			end
		end
	end
end
print(("    %d piezas, %d luces, %d modelos (%d atómicos)"):format(parts, lights, models, atomic))
check(parts <= 2800, ("piezas del puerto: %d (máx. 2800)"):format(parts))
check(lights <= 16, ("luces de verdad: %d (máx. 16)"):format(lights))
check(atomic >= 10, "grúas, buque y edificios se cargan enteros (Atomic, sin medias grúas)")

print(if failures == 0 then "\n✅ Puerto de Valmar bien" else ("\n❌ %d fallos"):format(failures))
process.exit(if failures == 0 then 0 else 1)
