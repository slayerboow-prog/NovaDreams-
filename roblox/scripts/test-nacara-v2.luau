-- Prueba de Nácara v2 (docs/mar/nacara-v2/diseno.md): el plano de los 16 barrios del mapa del dueño y el
-- PROTOTIPO del Palacio Real y la Plaza Central (World/NacaraV2Builder), FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-nacara-v2.luau
--
-- Comprueba:
--   * Está APAGADO (Config.Sea.NacaraV2 = false) hasta que el dueño apruebe: el juego no cambia
--   * El plano: los 16 barrios del mapa, sin islas que se pisen, dentro del radio de la ciudad, al norte del
--     borde del Cañón de las Catedrales, y la Plaza Central en la plaza de la fase 0
--   * El prototipo: dentro de su presupuesto, solo materiales que no cambia World/UserMaterials (el bug del
--     barrio negro), 2 luces como mucho, nada más alto que Nacara.MaxTop, sin tocar la Concha del Consejo, las
--     perlas-farola, los tablones, los carteles de la plaza ni el camino de la persecución

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check

local Nacara = L.load("src/shared/Sea/Nacara")
local Civ = L.load("src/shared/Sea/Civ")
local NacaraV2 = L.load("src/shared/Sea/NacaraV2")
local UserMaterialChoice = L.load("src/shared/UserMaterialChoice")

---------------------------------------------------------------------
print("▶ Apagado hasta que el dueño apruebe")
local config = fs.readFile("src/shared/Config.luau")
check(string.find(config, "NacaraV2 = false", 1, true) ~= nil and NacaraV2.On == false, "Config.Sea.NacaraV2 = false: el prototipo no se construye")
check(Civ.AreaById.Palacio == nil, "apagado, Civ no cambia (sin la isla del palacio)")
local civService = fs.readFile("src/server/Services/SeaCivService.luau")
check(string.find(civService, "if NacaraV2.On then", 1, true) ~= nil, "SeaCivService solo lo construye con el interruptor")

---------------------------------------------------------------------
print("\n▶ El plano de los 16 barrios")
check(#NacaraV2.Districts == 16, ("%d barrios (los 16 del mapa)"):format(#NacaraV2.Districts))
local plaza = NacaraV2.ById.Plaza
check(plaza.X == 0 and plaza.Z == 0, "la Plaza Central es la plaza de la fase 0 (no se mueve)")
local rx, rz = NacaraV2.fromReference(plaza.Px[1], plaza.Px[2])
check(math.sqrt(rx * rx + rz * rz) < 30, ("…y en el mapa del dueño cae ahí mismo (a %.0f studs)"):format(math.sqrt(rx * rx + rz * rz)))
local overlaps, far = {}, 0
for i, a in NacaraV2.Districts do
	if math.sqrt(a.X * a.X + a.Z * a.Z) + a.R > 560 then
		far += 1
	end
	for j = i + 1, #NacaraV2.Districts do
		local b = NacaraV2.Districts[j]
		local d = math.sqrt((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2)
		if d < a.R + b.R + 6 then
			table.insert(overlaps, ("%s-%s (%.0f)"):format(a.Id, b.Id, d))
		end
	end
end
check(#overlaps == 0, "las islas no se pisan (6 studs de agua entre ellas como poco)" .. (if #overlaps > 0 then ": " .. table.concat(overlaps, ", ") else ""))
check(far == 0, "todo cabe en 560 studs del centro (la ciudad ≈ 450 de radio, más sus islas)")
local south = 0
for _, d in NacaraV2.Districts do
	south = math.max(south, d.Z + d.R)
end
check(south < 290, ("lo más al sur llega a Z = %.0f: no cae por el borde del Cañón de las Catedrales (~280 al sur del centro)"):format(south))
for _, l in NacaraV2.Links do
	check(NacaraV2.ById[l[1]] and NacaraV2.ById[l[2]] and (l.Kind == "Tube" or l.Kind == "Walk"), ("enlace %s → %s (%s)"):format(l[1], l[2], tostring(l.Kind)))
end
local budget = 0
for _, d in NacaraV2.Districts do
	budget += d.Budget
end
check(budget <= 3600, ("presupuesto de la ciudad entera: %d piezas del servidor (≤ 3600)"):format(budget))

---------------------------------------------------------------------
print("\n▶ Los 16 barrios construidos (plan completo, el de las vistas previas)")
local Builder = L.load("src/server/World/NacaraV2Builder")
local MarKit = L.load("src/shared/Sea/MarKit")
local all = Builder.plan({ All = true })
local swapped = {}
for _, row in UserMaterialChoice.Table do
	swapped[row.Material] = true
end
local allowed = {}
for _, m in Builder.Materials do
	allowed[m] = true
end
local count, lightsBy, kitBy = {}, {}, {}
local badMat, tooHigh, glassCollide, links = {}, 0, 0, 0
local top = Nacara.FloorY + Nacara.MaxTop + 1.5
for _, s in all.Parts do
	count[s.District] = (count[s.District] or 0) + 1
	if string.find(s.District, "-", 1, true) then
		links += 1
	end
	if s.Light then
		lightsBy[s.District] = (lightsBy[s.District] or 0) + 1
	end
	if swapped[s.Material] or not allowed[s.Material] then
		table.insert(badMat, s.Name .. ":" .. s.Material)
	end
	local h = if s.Shape == "Cylinder" then s.Size.X / 2 else s.Size.Y / 2
	local limit = if s.District == "Palacio" then Nacara.FloorY + NacaraV2.PalaceMaxTop + 1.5 else top
	if s.Name ~= "Tubo" and s.CFrame.Position.Y + h > limit then
		tooHigh += 1
	end
	if s.Collide and (s.Material == "Glass" or s.Material == "Neon") then
		glassCollide += 1
	end
end
local kinds = 0
for _, k in all.Kit do
	kitBy[k.District] = (kitBy[k.District] or 0) + 1
	if MarKit.Pieces[k.Kind] then
		kinds += 1
	end
end
local over, noLight, sparse = {}, {}, {}
for _, d in NacaraV2.Districts do
	local n = count[d.Id] or 0
	if n > d.Budget then
		table.insert(over, ("%s %d/%d"):format(d.Id, n, d.Budget))
	end
	if (lightsBy[d.Id] or 0) > NacaraV2.MaxLights then
		table.insert(noLight, d.Id)
	end
	if n < 14 or (kitBy[d.Id] or 0) < 40 then
		table.insert(sparse, d.Id)
	end
end
check(#over == 0, "cada barrio dentro de su presupuesto de piezas" .. (if #over > 0 then ": " .. table.concat(over, ", ") else ""))
check(#sparse == 0, "cada barrio tiene su edificio y su isla con coral, kelp y luces vivas (≥ 40 mallas del kit)" .. (if #sparse > 0 then ": " .. table.concat(sparse, ", ") else ""))
check(#noLight == 0, ("como mucho %d luces de verdad por barrio (el resto Neon, sin sombras)"):format(NacaraV2.MaxLights))
check(#badMat == 0, "solo SmoothPlastic, Glass, Neon y Fabric (nada que los packs del dueño pongan negro bajo el mar)" .. (if #badMat > 0 then ": " .. table.concat(badMat, ", ", 1, math.min(#badMat, 5)) else ""))
check(tooHigh == 0, ("nada pasa de Nacara.MaxTop (%d studs sobre la plaza), salvo el Palacio, el hito (hasta %d)"):format(Nacara.MaxTop, NacaraV2.PalaceMaxTop))
check(-2 - (Nacara.FloorY + NacaraV2.PalaceMaxTop) >= 40, "la aguja del Palacio queda al menos 40 studs bajo la superficie (los barcos pasan por encima)")
check(glassCollide == 0, "el cristal y la luz no chocan (solo suelos, muros y bases)")
check(kinds == #all.Kit and #all.Kit <= NacaraV2.KitBudget, ("%d mallas del kit del mar (≤ %d), todas del kit"):format(#all.Kit, NacaraV2.KitBudget))
check(links > 0 and links <= NacaraV2.LinkBudget, ("tubos curvos y pasarelas: %d piezas (≤ %d)"):format(links, NacaraV2.LinkBudget))
check(#all.Parts <= 3600, ("la ciudad entera: %d piezas, %d mallas, %d rellenos de terreno"):format(#all.Parts, #all.Kit, #all.Terrain))

---------------------------------------------------------------------
print("\n▶ Lo que se construye al encenderlo (fase 1: Palacio Real y Plaza Central)")
local plan = Builder.plan()
local districts = {}
for _, s in plan.Parts do
	districts[s.District] = true
end
check(districts.Palacio and districts.Plaza and not districts.Residencias and not districts.Biblioteca, "solo el Palacio, la Plaza y su tubo (los barrios de la fase 2 y 3 esperan)")
-- Lo que ya hay en Nácara no se pisa (coordenadas de la plaza): ni las piezas ni las mallas del kit
local hits = {}
local function flatXZ(p: Vector3): (number, number)
	return p.X - Nacara.Center.X, p.Z - Nacara.Center.Z
end
local things = {}
for _, s in plan.Parts do
	if not string.find(s.District, "-", 1, true) then
		local x, z = flatXZ(s.CFrame.Position)
		table.insert(things, { X = x, Z = z, R = math.max(s.Size.X, s.Size.Z) / 2, Name = s.Name })
	end
end
for _, k in plan.Kit do
	table.insert(things, { X = k.X - Nacara.Center.X, Z = k.Z - Nacara.Center.Z, R = if k.Kind == "KelpGigante" then 3 else 1.5, Name = k.Kind })
end
local function near(x: number, z: number, r: number, what: string)
	for _, t in things do
		if (t.X - x) ^ 2 + (t.Z - z) ^ 2 < (r + t.R) ^ 2 then
			table.insert(hits, ("%s↔%s"):format(t.Name, what))
			return
		end
	end
end
near(Civ.AreaById.Consejo.X, Civ.AreaById.Consejo.Z, Civ.AreaById.Consejo.R, "Concha del Consejo")
for _, l in Civ.Lamps do
	near(l.X, l.Z, 3, l.Id)
end
for id, b in Civ.Boards do
	near(b.X, b.Z, 4, id)
end
for _, sg in Nacara.Signs do
	near(sg.X, sg.Z, 2, "cartel " .. sg.Id)
end
for _, p in Civ.Chase.Path do
	near(p[1], p[2], 4, "persecución")
end
for _, item in Nacara.Layout do
	if item.Id ~= "ArcoNorte" then
		near(item.X, item.Z, item.R, item.Id)
	end
end
for _, a in Civ.Areas do
	if a.Id ~= "Plaza" then
		near(a.X, a.Z, a.R, a.Name)
	end
end
check(#hits == 0, "no pisa la Concha del Consejo, las perlas-farola, los tablones, los carteles, la persecución, la plaza ni los barrios de la fase 1" .. (if #hits > 0 then ": " .. table.concat(hits, ", ") else ""))
local terrainHits = 0
for _, op in plan.Terrain do
	local x, z = flatXZ(op.Pos)
	if op.Op ~= "Cylinder" and op.District == "Plaza" and x * x + z * z < (Nacara.Clear + 2) ^ 2 then
		terrainHits += 1
	end
end
check(terrainHits == 0, "los peñascos de la Plaza Central quedan fuera de la plaza allanada")

-- Construirlo (como si el interruptor estuviera encendido) con un terreno de mentira
local fills = 0
local fake = {}
for _, name in { "FillCylinder", "FillBall", "FillBlock" } do
	fake[name] = function()
		fills += 1
	end
end
Builder.build(fake)
local holder = L.workspace:FindFirstChild("NacaraCiudad")
local built, anchored, signs = 0, 0, 0
for _, d in (if holder then holder:GetDescendants() else {}) do
	if d:IsA("BasePart") then
		built += 1
		if d.Anchored then
			anchored += 1
		end
	elseif d:IsA("SurfaceGui") then
		signs += 1
	end
end
check(holder ~= nil and holder:FindFirstChild("Nacara_V2_Palacio") ~= nil and built == #plan.Parts and anchored == built and fills == #plan.Terrain and signs == 2,
	("construido: %d piezas en modelos por barrio, todas ancladas, %d rellenos de terreno y 2 carteles"):format(built, fills))

L.finish("Nácara v2 (plano y prototipo)")
