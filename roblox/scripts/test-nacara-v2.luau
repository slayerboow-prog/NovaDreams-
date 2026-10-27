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
print("\n▶ El prototipo: Palacio Real y Plaza Central")
local Builder = L.load("src/server/World/NacaraV2Builder")
local plan = Builder.plan()
local maxParts = NacaraV2.ById.Palacio.Budget + NacaraV2.ById.Plaza.Budget
check(#plan > 60 and #plan <= maxParts, ("%d piezas (≤ %d)"):format(#plan, maxParts))
local swapped = {}
for _, row in UserMaterialChoice.Table do
	swapped[row.Material] = true
end
local allowed = {}
for _, m in Builder.Materials do
	allowed[m] = true
end
local badMat, lights, tooHigh, collide = {}, 0, 0, 0
local top = Nacara.FloorY + Nacara.MaxTop + 1.5
for _, s in plan do
	if swapped[s.Material] or not allowed[s.Material] then
		table.insert(badMat, s.Name .. ":" .. s.Material)
	end
	if s.Light then
		lights += 1
	end
	local cf, size = s.CFrame, s.Size
	if cf.Position.Y + size.Magnitude / 2 > top and s.Name ~= "Tubo" then
		-- (una cota alta por si la pieza está girada)
		local h = if s.Shape == "Cylinder" then size.X / 2 else size.Y / 2
		if cf.Position.Y + h > top then
			tooHigh += 1
		end
	end
	if s.Collide then
		collide += 1
	end
end
check(#badMat == 0, "solo SmoothPlastic, Glass, Neon y Fabric (nada de pizarra, mármol, adoquín… que se ven negros bajo el mar)" .. (if #badMat > 0 then ": " .. table.concat(badMat, ", ") else ""))
check(lights <= NacaraV2.MaxLights and lights >= 1, ("%d luces de verdad (≤ %d; el resto Neon, sin sombras)"):format(lights, NacaraV2.MaxLights))
check(tooHigh == 0, ("nada pasa de Nacara.MaxTop (%d studs sobre la plaza: los barcos pasan por encima)"):format(Nacara.MaxTop))
check(collide > 0 and collide <= 16, ("solo chocan la terraza, el tambor, la base de las agujas, el suelo del tubo y los carteles (%d piezas)"):format(collide))

-- Lo que ya hay en Nácara no se pisa (coordenadas de la plaza)
local function flat(s): (number, number)
	local p = s.CFrame.Position
	return p.X - Nacara.Center.X, p.Z - Nacara.Center.Z
end
local hits = {}
local function near(x: number, z: number, r: number, what: string)
	for _, s in plan do
		local px, pz = flat(s)
		local reach = math.max(s.Size.X, s.Size.Z) / 2
		if s.Name == "Tubo" or s.Name == "SueloTubo" or s.Name == "FranjaTubo" then
			reach = 5.5 -- (el tubo es largo: se mira su línea, abajo)
		end
		if s.Name ~= "Tubo" and s.Name ~= "SueloTubo" and s.Name ~= "FranjaTubo" and (px - x) ^ 2 + (pz - z) ^ 2 < (r + reach) ^ 2 then
			table.insert(hits, ("%s↔%s"):format(s.Name, what))
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
check(#hits == 0, "no pisa la Concha del Consejo, las perlas-farola, los tablones, los carteles, la persecución ni la plaza" .. (if #hits > 0 then ": " .. table.concat(hits, ", ") else ""))
-- El tubo: de la plaza (arco norte) al palacio, lejos de las perlas-farola
local a0, a1 = Nacara.toWorld(0, -50, 0), Nacara.toWorld(NacaraV2.PalaceAt.X, NacaraV2.PalaceAt.Z + NacaraV2.Palace.Terrace.R, 0)
local tubeHits = 0
for _, l in Civ.Lamps do
	local p = Nacara.toWorld(l.X, l.Z, 0)
	local ab = a1 - a0
	local t = math.clamp((p - a0):Dot(ab) / ab:Dot(ab), 0, 1)
	if (a0 + ab * t - p).Magnitude < 8 then
		tubeHits += 1
	end
end
check(tubeHits == 0, "el tubo de cristal no pasa por ninguna perla-farola")

-- Construirlo (como si el interruptor estuviera encendido) con un terreno de mentira
local fills = 0
Builder.build({ FillCylinder = function()
	fills += 1
end })
local holder = L.workspace:FindFirstChild("NacaraCiudad")
local m = holder and holder:FindFirstChild("Nacara_V2_Palacio")
local built, anchored, signs = 0, 0, 0
for _, d in (if m then m:GetDescendants() else {}) do
	if d:IsA("BasePart") then
		built += 1
		if d.Anchored then
			anchored += 1
		end
	elseif d:IsA("SurfaceGui") then
		signs += 1
	end
end
check(m ~= nil and built == #plan and anchored == built and fills == 2 and signs == 2, ("construido: %d piezas, todas ancladas, la isla (2 rellenos) y 2 carteles"):format(built))

L.finish("Nácara v2 (plano y prototipo)")
