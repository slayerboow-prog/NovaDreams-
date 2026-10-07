-- Prueba de la casa de Cosme (World/CosmeHouse) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-cosmehouse.luau [mapa.rbxl]
--   (con un mapa construido —rojo build + scripts/build-place.luau— mira también la casa de verdad)
--
-- Construye la casa entera en una carpeta (como scripts/build-place.luau) y comprueba:
--   * están todas las habitaciones del encargo (docs/historia/casa-cosme.md) y ninguna está vacía
--     (un mínimo de piezas dentro de cada una)
--   * están conectadas: el grafo de puntos de paso (puertas y escaleras de verdad) une todas las
--     plantas, cada habitación tiene su punto, y cada tramo se puede ANDAR (no atraviesa paredes,
--     muebles ni barandillas; las hojas de las puertas se abren y no cuentan)
--   * nada flota: cada pieza toca otra y, siguiendo lo que se toca, se llega al suelo; lo que flota a
--     propósito (portales, esferas magnéticas, hologramas…) lleva la etiqueta Anomaly
--   * todo está anclado (lo que se mueve lo mueve el cliente o el servidor con CFrame)
--   * los portales tienen profundidad (aros, capas de túnel a distintas profundidades, haces,
--     partículas y luz)
--   * están los avisos: puertas, telescopio, portal, habitación secreta, documentos, cajones, máquinas…
--   * la rutina de Cosme: cada franja de la hora del juego (08, 09, 11, 13, 15, 18, 21 y 01) tiene su
--     punto dentro de la casa, en su habitación, y se llega andando desde cualquier otra
--   * los sitios de la historia: la marca GarajeCosme (y las nuevas Cosme*) existen, con sitio libre
--     alrededor para los actores de las misiones; Locations las conoce
--   * presupuesto de piezas y de luces; lo pequeño se esconde en el nivel gráfico Bajo (CityDetail)
--   * el plano del dueño (docs/referencias/plano-casa-cosme.png, a escala ×2): cada habitación numerada
--     en su sitio (garaje a la derecha desde la calle, mirador de observación detrás, cúpula en el
--     tejado, torre de experimentos detrás a la derecha…)
--   * por fuera como el render: la torre redonda de dos tambores de cristal con el platillo, la
--     parabólica y la antena; la torre con el vórtice encima; el cartel «NO ENTRAR»; los coches del
--     kit FutureCar (curvos: elipsoides, ruedas con llanta, tiras de luz, pintura con reflejo)
--   * el garaje viejo ya no existe (Home.cosmeGarage, Blocks.cosmeGarage, ningún «TALLER DE COSME»)

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local check = L.check

local Vector3, CFrame = roblox.Vector3, L.CFrame
local Enum = roblox.Enum

local Layout = L.load("src/server/World/CosmeHouse/Layout")
local Build = L.load("src/server/World/CosmeHouse/Build")
local Builder = L.load("src/server/World/Builder")
local Kit = L.load("src/server/World/CosmeHouse/Kit")
local Locations = L.load("src/shared/LifeStory/Locations")

---------------------------------------------------------------------
print("\n▶ El plano (Layout)")
---------------------------------------------------------------------
local required = {
	"Jardin", "JardinTrasero", "Terraza", "JardinLateral", "Vestibulo", "Salon", "Despacho", "Comedor", "Escalera", "Cocina",
	"Aseo", "Laboratorio", "GarajeCosme", "Pasillo", "Dormitorio", "Biblioteca", "BanoArriba", "Experimentos", "Ordenadores",
	"Observacion", "TerrazaPrincipal", "TerrazaLateral", "Observatorio", "Azotea", "PanelesSolares", "TorreExperimentos",
	"PasilloSotano", "Portales", "Taller", "Almacen", "GarajeSotano", "Secreta",
}
local missing = {}
for _, id in required do
	if not Layout.room(id) then
		table.insert(missing, id)
	end
end
check(#missing == 0, ("todas las habitaciones del encargo están en el plano (%d; faltan: %s)"):format(#required, table.concat(missing, ", ")))
local levels = {}
for _, r in Layout.Rooms do
	levels[r.Level] = (levels[r.Level] or 0) + 1
end
check(levels.B and levels.G and levels.U and levels.A and levels.O, "hay sótano, planta baja, planta alta, tejado y exterior")

-- Grafo conectado
local names = {}
for name in Layout.Points do
	table.insert(names, name)
end
table.sort(names)
local unreachable = {}
for _, name in names do
	if name ~= "Entrada" and not Layout.path("Entrada", name) then
		table.insert(unreachable, name)
	end
end
check(#unreachable == 0, ("todos los puntos de paso se alcanzan desde la entrada (%d puntos; sin camino: %s)"):format(#names, table.concat(unreachable, ", ")))
for _, e in Layout.Edges do
	if not Layout.Points[e[1]] or not Layout.Points[e[2]] then
		check(false, "arista con un punto que no existe: " .. e[1] .. " - " .. e[2])
	end
end

local function roomOf(p: { number }): any
	for _, r in Layout.Rooms do
		local y0, y1 = Layout.levelRange(r.Level)
		if p[1] >= r.X0 and p[1] <= r.X1 and p[3] >= r.Z0 and p[3] <= r.Z1 and p[2] >= y0 - 0.6 and p[2] <= y1 then
			return r
		end
	end
	return nil
end
local roomsWithPoint = {}
for _, name in names do
	local r = roomOf(Layout.Points[name])
	if r then
		roomsWithPoint[r.Id] = true
	end
end
local lonely = {}
for _, r in Layout.Rooms do
	if not roomsWithPoint[r.Id] then
		table.insert(lonely, r.Id)
	end
end
check(#lonely == 0, "cada habitación tiene al menos un punto de paso (está conectada): " .. (if #lonely > 0 then "sin punto: " .. table.concat(lonely, ", ") else "todas"))
-- Las plantas se unen por escaleras de verdad (aristas con cambio de altura en tramos de escalera)
local climbs = 0
for _, e in Layout.Edges do
	local a, b = Layout.Points[e[1]], Layout.Points[e[2]]
	if math.abs(a[2] - b[2]) > 3 then
		climbs += 1
		local run = math.sqrt((a[1] - b[1]) ^ 2 + (a[3] - b[3]) ^ 2)
		if math.abs(a[2] - b[2]) / run > 0.65 then
			check(false, ("tramo demasiado empinado: %s - %s"):format(e[1], e[2]))
		end
	end
end
check(climbs >= 6, ("las plantas se unen con tramos de escalera de pendiente suave (%d tramos)"):format(climbs))
for name, s in Layout.Stairs do
	check(s.X1 - s.X0 >= 10 and math.abs(s.Rise) / s.Run <= 0.62, ("escalera %s: carriles de 6 de ancho y pendiente %.2f"):format(name, math.abs(s.Rise) / s.Run))
end

-- Rutina
print("\n▶ La rutina de Cosme")
local hours = {}
for _, slot in Layout.Routine do
	hours[slot.Hour] = slot
end
local wanted = { [8] = "Cocina", [9] = "Laboratorio", [11] = "Ordenadores", [13] = "Cocina", [15] = "GarajeCosme", [18] = "Observatorio", [21] = "Salon", [1] = "Secreta" }
for hour, room in wanted do
	local slot = hours[hour]
	local p = slot and Layout.Points[slot.Point]
	local r = p and roomOf(p)
	check(slot ~= nil and slot.Room == room and r ~= nil and r.Id == room, ("a las %02d:00 en %s (punto %s dentro de la habitación)"):format(hour, room, slot and slot.Point or "?"))
end
local allReach = true
for _, a in Layout.Routine do
	for _, b in Layout.Routine do
		if not Layout.path(a.Point, b.Point) then
			allReach = false
		end
	end
end
check(allReach, "de cada sitio de la rutina se llega andando a todos los demás")
check(Layout.slotAt(8.5).Room == "Cocina" and Layout.slotAt(0.5).Room == "Salon" and Layout.slotAt(23).Room == "Salon" and Layout.slotAt(2).Room == "Secreta", "la hora decide la franja (con la vuelta de medianoche)")
local plan = Layout.path("Cocina", "Secreta")
check(plan ~= nil and table.find(plan, "Estanteria") ~= nil and table.find(plan, "SotanoL2") ~= nil, "a la 01:00 baja al sótano por la escalera y entra por la estantería")

---------------------------------------------------------------------
print("\n▶ El plano del dueño (docs/referencias/plano-casa-cosme.png, a escala ×2)")
---------------------------------------------------------------------
-- Desde la calle (mirando la casa, hacia +Z local), la derecha es -X local: la cámara lo confirma
do
	local probe = Builder.facing(Vector3.new(0, 0, 0), Vector3.new(1, 0, 0))
	local street = probe * CFrame.new(0, 5, -80)
	local cam = CFrame.lookAt(street.Position, probe.Position + Vector3.new(0, 5, 0))
	local right = probe:VectorToWorldSpace(Vector3.new(-1, 0, 0))
	check(cam.RightVector:Dot(right) > 0.99, "desde la calle, -X local queda a la derecha (el garaje del plano)")
end
local function room(id: string): any
	return Layout.room(id) :: any
end
local function cx(r: any): number
	return (r.X0 + r.X1) / 2
end
local function cz(r: any): number
	return (r.Z0 + r.Z1) / 2
end
local numbers = {}
for _, r in Layout.Rooms do
	if r.Plan then
		numbers[r.Plan] = r.Id
	end
end
local missingNumbers = {}
for _, n in { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20 } do
	if not numbers[n] then
		table.insert(missingNumbers, tostring(n))
	end
end
check(#missingNumbers == 0, "están todas las habitaciones numeradas del plano (1-20; la 18, la antena, va con la torre)" .. (if #missingNumbers > 0 then ": faltan " .. table.concat(missingNumbers, ", ") else ""))
local H, Gar = Layout.House, Layout.Garage
check(H.X1 - Gar.X0 <= 96 and H.X1 - Gar.X0 >= 80 and H.Z1 - H.Z0 <= 80, ("huella de la casa a escala ×2 del plano (48 × 40 → 96 × 80): %d de frente"):format(H.X1 - Gar.X0))
check(Layout.CEIL.G - Layout.F0 >= 11 and Layout.CEIL.U - Layout.F1 >= 11 and Layout.CEIL.B - Layout.FB >= 11, "cada planta tiene al menos 11 de alto")
-- Planta baja
local vest, salon, cocina, comedor, lab = room("Vestibulo"), room("Salon"), room("Cocina"), room("Comedor"), room("Laboratorio")
check(Gar.X1 <= H.X0 and Gar.Z0 == H.Z0 and Gar.Z1 - Gar.Z0 > 30, "garaje (6) a la derecha, a lo largo del fondo de la planta baja")
check(vest.Z0 == H.Z0 and cx(vest) < cx(salon) and cx(vest) > Gar.X1, "vestíbulo (1) delante, entre el salón y el garaje, con la puerta a la calle")
check(salon.Z0 == H.Z0 and cx(salon) > (H.X0 + H.X1) / 2, "salón (2) delante a la izquierda")
check(cz(cocina) > cz(salon) and cx(cocina) > (H.X0 + H.X1) / 2 and cocina.Z1 == H.Z1, "cocina (3) detrás a la izquierda")
check(cz(comedor) > vest.Z1 - 1 and cz(comedor) < cz(lab), "comedor (3) en el centro")
check(lab.Z1 == H.Z1 and cz(lab) > cz(comedor) and cx(lab) < cx(cocina), "laboratorio de inventos (4) detrás, en el centro")
local core = Layout.Core
local w, d = H.X1 - Gar.X0, H.Z1 - H.Z0
check((core.X0 + core.X1) / 2 > Gar.X0 + w / 3 and (core.X0 + core.X1) / 2 < Gar.X0 + w * 2 / 3 and (core.Z0 + core.Z1) / 2 > H.Z0 + d / 3 and (core.Z0 + core.Z1) / 2 < H.Z0 + d * 2 / 3, "escalera (5) en el centro (sube y baja al sótano en el mismo núcleo)")
-- Planta alta
local dorm, exper, obsr, terr, lat = room("Dormitorio"), room("Experimentos"), room("Observacion"), room("TerrazaPrincipal"), room("TerrazaLateral")
check(cx(dorm) > cx(exper), "habitación de Cosme (7) a la izquierda y zona de experimentos (8) a la derecha")
check(Layout.Bay.Z >= H.Z1 and obsr.Z1 > H.Z1 and math.abs(Layout.Bay.X - (H.X0 + H.X1) / 2) < 12, "sala de observación (9): mirador semicircular de cristal DETRÁS, en el centro")
check(terr.Z1 <= Layout.Upper.Z0 and terr.Z0 <= H.Z0 + 1 and terr.X1 - terr.X0 > 40, "terraza principal (10) delante, encima del salón")
check(lat.X1 <= H.X0 and lat.Level == "U", "terraza lateral (11) a la derecha (en el tejado del garaje)")
-- Sótano
local gs, pt, tl, al = room("GarajeSotano"), room("Portales"), room("Taller"), room("Almacen")
check(gs.X1 <= pt.X0 and gs.X1 <= al.X1, "garaje del sótano (12) a la derecha")
check(cz(pt) < cz(tl) and pt.X0 >= gs.X1 and cx(pt) > cx(al), "portal (13) delante a la izquierda y taller (14) detrás a la izquierda")
check(cz(al) > cz(pt) and cx(al) < cx(tl) and cx(al) > cx(gs), "almacén (15) detrás, en el centro")
-- Tejado
local D, T = Layout.Dome, Layout.PortalTower
local sol, chillR = Layout.Solar, room("Azotea")
check(sol.X0 > D.X and (sol.X0 + sol.X1) / 2 > (H.X0 + H.X1) / 2, "paneles solares (16) a la izquierda del tejado")
check(math.abs(D.X - (H.X0 + H.X1) / 2) < 12 and D.Top > Layout.F2 + 8 and D.DiscR > D.R and D.UpperTop > D.Top, "cúpula de observación (19) en el centro: dos tambores y el platillo encima")
check(T.X < D.X and T.Z > D.Z and T.Z < H.Z1, "torre de experimentos (17) detrás a la derecha del tejado")
check(cx(chillR) < D.X and cz(chillR) < T.Z, "terraza chill (20) delante a la derecha del tejado")

---------------------------------------------------------------------
print("\n▶ Construir la casa")
---------------------------------------------------------------------
local site = Builder.facing(Vector3.new(390, 0, -2210), Vector3.new(1, 0, 0))
local folder = roblox.Instance.new("Folder")
local t0 = os.clock()
local ok, house = pcall(Build.build, folder, site)
check(ok, "se construye sin errores " .. (if ok then ("(%.1f s)"):format(os.clock() - t0) else tostring(house)))
if not ok then
	process.exit(1)
end
local parts = {}
for _, d in house:GetDescendants() do
	if d:IsA("BasePart") then
		table.insert(parts, d)
	end
end
print(("  · %d piezas"):format(#parts))
check(#parts >= 4000 and #parts <= 14000, ("presupuesto de piezas: %d (entre 4.000 y 14.000)"):format(#parts))
-- Los muebles y aparatos de la cocina chocan (el personaje no se mete dentro de la impresora de comida)
do
	local solidOk = true
	for _, name in { "ImpresoraComida", "NeveraPantalla", "CafeteraModificada", "MicroondasTemporal", "MesaCocina" } do
		local m = house:FindFirstChild(name, true)
		local any = false
		for _, d in (if m then m:GetDescendants() else {}) do
			if d:IsA("BasePart") and d.CanCollide then
				any = true
			end
		end
		if not any then
			solidOk = false
			print("    (no choca: " .. name .. ")")
		end
	end
	check(solidOk, "la impresora de comida, la nevera, la cafetera, el microondas y la mesa de la cocina chocan")
	local cars = 0
	for _, name in { "CocheExperimental", "CochePortales" } do
		local car = house:FindFirstChild(name, true)
		local box = car and car:FindFirstChild("CarHitbox")
		if box and box:IsA("BasePart") and box.CanCollide and box.Transparency == 1 then
			cars += 1
		end
	end
	check(cars == 2, "los coches del garaje no se atraviesan (caja invisible de su tamaño)")
	-- Leer (documentos y pantallas: abren un cartel a toda pantalla) pide mantener un momento: un roce
	-- o un toque que iba para otra cosa no abre nada
	local reads, quick = 0, 0
	for _, d in house:GetDescendants() do
		if d:IsA("ProximityPrompt") and (d:GetAttribute("CosmeAction") == "Doc" or d:GetAttribute("CosmeAction") == "Screen") then
			reads += 1
			if d.HoldDuration < Kit.ReadHold then
				quick += 1
			end
		end
	end
	check(reads > 10 and quick == 0, ("los %d carteles de «Leer» hay que mantenerlos un momento (ninguno se abre de un roce)"):format(reads))
	local fridge = house:FindFirstChild("NeveraPantalla", true)
	local body = fridge and fridge:FindFirstChild("Cuerpo")
	check(body and body:HasTag("Interact") and body:GetAttribute("Use") == "Fridge" and body:GetAttribute("FridgeOwner") == "Cosme", "la nevera de Cosme es una nevera de verdad (gratis si le conoces: FridgeService)")
end

local lights = 0
for _, d in house:GetDescendants() do
	if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
		lights += 1
	end
end
check(lights <= Kit.MaxLights + 12 and lights >= 40, ("luces con tope: %d (máx. %d + las de los muebles)"):format(lights, Kit.MaxLights))
local detail, decor = 0, 0
for _, p in parts do
	if not p.CanCollide then
		decor += 1
		if p:HasTag("CityDetail") then
			detail += 1
		end
	end
end
check(detail >= decor * 0.3, ("lo pequeño se esconde en el nivel Bajo (CityDetail): %d de %d piezas de adorno"):format(detail, decor))

local loose = 0
for _, p in parts do
	if not p.Anchored then
		loose += 1
	end
end
check(loose == 0, ("todo anclado (%d sueltas)"):format(loose))

-- Pasar a coordenadas locales de la parcela
local function localPos(p: Vector3): Vector3
	return site:PointToObjectSpace(p)
end

---------------------------------------------------------------------
print("\n▶ Ninguna habitación vacía")
---------------------------------------------------------------------
local isMark = function(p: any): boolean
	return p:HasTag("StorySpot") or p:HasTag("StoryArea") or p:HasTag("StoryProp") or p:HasTag("CosmeRoom")
end
local counts = {}
for _, p in parts do
	if not isMark(p) then
		local lp = localPos(p.CFrame.Position)
		for _, r in Layout.Rooms do
			local y0, y1 = Layout.levelRange(r.Level)
			if lp.X > r.X0 + 0.2 and lp.X < r.X1 - 0.2 and lp.Z > r.Z0 + 0.2 and lp.Z < r.Z1 - 0.2 and lp.Y > y0 and lp.Y < y1 then
				counts[r.Id] = (counts[r.Id] or 0) + 1
			end
		end
	end
end
for _, r in Layout.Rooms do
	local n = counts[r.Id] or 0
	check(n >= r.MinProps, ("%s: %d piezas (mín. %d)"):format(r.Name, n, r.MinProps))
end

---------------------------------------------------------------------
print("\n▶ Nada flota (todo toca algo que llega al suelo)")
---------------------------------------------------------------------
-- Caja de cada pieza (alineada con los ejes del mundo)
local boxes = {}
for i, p in parts do
	local cf, s = p.CFrame, p.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local ex = math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z
	local ey = math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z
	local ez = math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z
	local c = cf.Position
	boxes[i] = { c.X - ex, c.Y - ey, c.Z - ez, c.X + ex, c.Y + ey, c.Z + ez }
end
local CELL = 8
local grid: { [string]: { number } } = {}
for i, b in boxes do
	for gx = math.floor(b[1] / CELL), math.floor(b[4] / CELL) do
		for gz = math.floor(b[3] / CELL), math.floor(b[6] / CELL) do
			local key = gx .. ":" .. gz
			local list = grid[key]
			if not list then
				list = {}
				grid[key] = list
			end
			table.insert(list, i)
		end
	end
end
local TOL = 0.2
local function touch(a: { number }, b: { number }): boolean
	return a[1] <= b[4] + TOL and b[1] <= a[4] + TOL and a[2] <= b[5] + TOL and b[2] <= a[5] + TOL and a[3] <= b[6] + TOL and b[3] <= a[6] + TOL
end
local grounded = {}
local queue = {}
local groundY = Layout.FB - 1
for i, p in parts do
	if p.Name == "BlockGround" or boxes[i][2] <= groundY + 0.05 or boxes[i][2] <= 0.05 and boxes[i][5] >= -0.05 then
		grounded[i] = true
		table.insert(queue, i)
	end
end
local qi = 1
while qi <= #queue do
	local i = queue[qi]
	qi += 1
	local b = boxes[i]
	local seen = {}
	for gx = math.floor(b[1] / CELL), math.floor(b[4] / CELL) do
		for gz = math.floor(b[3] / CELL), math.floor(b[6] / CELL) do
			for _, j in grid[gx .. ":" .. gz] or {} do
				if not grounded[j] and not seen[j] then
					seen[j] = true
					if touch(b, boxes[j]) then
						grounded[j] = true
						table.insert(queue, j)
					end
				end
			end
		end
	end
end
local floating = {}
for i, p in parts do
	if not grounded[i] and not p:HasTag("Anomaly") and not isMark(p) then
		table.insert(floating, p)
	end
end
for k = 1, math.min(#floating, 12) do
	local p = floating[k]
	print(("    flota: %s (%s) en %s"):format(p:GetFullName():gsub("^.-CasaCosme%.", ""), p.Name, tostring(localPos(p.CFrame.Position))))
end
check(#floating == 0, ("ninguna pieza flota sin querer (%d flotando; %d anomalías a propósito)"):format(#floating, (function()
	local n = 0
	for _, p in parts do
		if p:HasTag("Anomaly") then
			n += 1
		end
	end
	return n
end)()))

---------------------------------------------------------------------
print("\n▶ Se puede andar por todos los tramos (puertas y escaleras de verdad)")
---------------------------------------------------------------------
-- Piezas que chocan (sin las hojas de las puertas ni la estantería secreta, que se abren)
local solid = {}
for i, p in parts do
	if p.CanCollide and p.Transparency < 1 and p:GetAttribute("Use") ~= "Door" and not p:HasTag("SecretDoor") and not p:IsA("Seat") then
		table.insert(solid, i)
	elseif p.CanCollide and p:IsA("Seat") and p.Transparency < 1 then
		table.insert(solid, i)
	end
end
local sgrid: { [string]: { number } } = {}
for _, i in solid do
	local b = boxes[i]
	for gx = math.floor(b[1] / 4), math.floor(b[4] / 4) do
		for gz = math.floor(b[3] / 4), math.floor(b[6] / 4) do
			local key = gx .. ":" .. gz
			sgrid[key] = sgrid[key] or {}
			table.insert(sgrid[key], i)
		end
	end
end
local function blockedAt(w: Vector3): BasePart?
	for _, i in sgrid[math.floor(w.X / 4) .. ":" .. math.floor(w.Z / 4)] or {} do
		local b = boxes[i]
		if w.X > b[1] and w.X < b[4] and w.Y > b[2] and w.Y < b[5] and w.Z > b[3] and w.Z < b[6] then
			local p = parts[i]
			local o = p.CFrame:PointToObjectSpace(w)
			local s = p.Size / 2
			if math.abs(o.X) < s.X - 0.02 and math.abs(o.Y) < s.Y - 0.02 and math.abs(o.Z) < s.Z - 0.02 then
				return p
			end
		end
	end
	return nil
end
local badEdges = 0
for _, e in Layout.Edges do
	local a, b = Layout.point(e[1]), Layout.point(e[2])
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = flat.Magnitude
	local side = if len > 0.01 then Vector3.new(-flat.Z, 0, flat.X).Unit else Vector3.new(1, 0, 0)
	local steps = math.max(2, math.ceil(len / 0.7))
	local hit: BasePart? = nil
	local hitAt = nil
	for k = 0, steps do
		local t = k / steps
		local feet = a:Lerp(b, t)
		for _, h in { 1.7, 4.3 } do
			for _, off in { -0.7, 0, 0.7 } do
				local w = site * CFrame.new(feet + side * off + Vector3.new(0, h, 0))
				local p = blockedAt(w.Position)
				if p then
					hit = p
					hitAt = feet
				end
			end
		end
		if hit then
			break
		end
	end
	if hit then
		badEdges += 1
		print(("    ❌ %s → %s: choca con %s (%s) en %s"):format(e[1], e[2], hit.Name, hit:GetFullName():gsub("^.-CasaCosme%.", ""), tostring(hitAt)))
	end
end
check(badEdges == 0, ("los %d tramos del grafo se pueden andar (anchura de persona) sin atravesar nada"):format(#Layout.Edges))
-- Y hay suelo debajo de cada punto de paso
local noFloor = {}
for _, name in names do
	local p = Layout.point(name)
	local found = false
	for _, i in sgrid[math.floor((site * CFrame.new(p)).Position.X / 4) .. ":" .. math.floor((site * CFrame.new(p)).Position.Z / 4)] or {} do
		local w = (site * CFrame.new(p - Vector3.new(0, 0.3, 0))).Position
		local b = boxes[i]
		if w.X >= b[1] and w.X <= b[4] and w.Z >= b[3] and w.Z <= b[6] and w.Y >= b[2] - 0.05 and w.Y <= b[5] + 0.05 then
			found = true
		end
	end
	if not found then
		table.insert(noFloor, name)
	end
end
check(#noFloor == 0, "hay suelo bajo cada punto de paso" .. (if #noFloor > 0 then ": falta en " .. table.concat(noFloor, ", ") else ""))

---------------------------------------------------------------------
print("\n▶ Los portales tienen profundidad")
---------------------------------------------------------------------
local portals = {}
for _, d in house:GetDescendants() do
	if d:IsA("Model") and d:HasTag("CosmePortal") then
		table.insert(portals, d)
	end
end
check(#portals >= 5, ("portales: %d (sala de portales, máquina, garaje, torre, salón, habitación secreta)"):format(#portals))
for _, portal in portals do
	local center = portal:GetAttribute("Center")
	local depths, beams, emitters, lights2, rings = {}, 0, 0, 0, 0
	for _, d in portal:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Layer") and typeof(center) == "CFrame" then
			depths[math.floor(center:PointToObjectSpace(d.CFrame.Position).Z * 4 + 0.5)] = true
		elseif d:IsA("Beam") then
			beams += 1
		elseif d:IsA("ParticleEmitter") then
			emitters += 1
		elseif d:IsA("PointLight") then
			lights2 += 1
		elseif d:IsA("BasePart") and (d.Name == "AroMetal" or d.Name == "AroNeon" or d.Name == "Segmento") then
			rings += 1
		end
	end
	local layers = 0
	for _ in depths do
		layers += 1
	end
	check(layers >= 5 and beams >= 2 and emitters >= 1 and rings >= 20, ("%s: %d capas de túnel a distinta profundidad, %d haces, %d emisores, %d luces, %d piezas de aro"):format(portal.Name, layers, beams, emitters, lights2, rings))
end

---------------------------------------------------------------------
print("\n▶ Avisos e interacciones")
---------------------------------------------------------------------
local actions, uses = {}, {}
local seats = 0
for _, d in house:GetDescendants() do
	if d:IsA("ProximityPrompt") then
		local a = d:GetAttribute("CosmeAction")
		if a then
			actions[a] = (actions[a] or 0) + 1
		end
	elseif d:IsA("BasePart") and d:HasTag("Interact") then
		local u = d:GetAttribute("Use")
		uses[u] = (uses[u] or 0) + 1
	end
	if d:IsA("Seat") then
		seats += 1
	end
end
local function n(t: any, k: string): number
	return t[k] or 0
end
check(n(uses, "Door") >= 12, ("puertas que se abren: %d"):format(n(uses, "Door")))
check(n(uses, "Light") >= 20, ("interruptores de luz: %d"):format(n(uses, "Light")))
check(n(uses, "Sit") >= 15 and seats >= 15, ("sitios para sentarse: %d avisos, %d asientos"):format(n(uses, "Sit"), seats))
check(n(uses, "Computer") >= 2 and n(uses, "Tap") >= 2 and n(uses, "Shower") >= 2 and n(uses, "Bed") >= 1 and n(uses, "Wardrobe") >= 1, "ordenadores, grifos, duchas, cama y armario de siempre (shared/Interact)")
check(n(actions, "Telescope") >= 1, "telescopio")
check(n(actions, "Portal") >= 1 and n(actions, "PortalDial") >= 1, "portal: activar y cambiar de destino")
check(n(actions, "SecretBook") == 5 and n(actions, "SecretButton") >= 1, ("habitación secreta: 5 libros (%d) y botón"):format(n(actions, "SecretBook")))
check(n(actions, "Doc") + n(actions, "Screen") >= 30, ("documentos y pantallas que se leen: %d"):format(n(actions, "Doc") + n(actions, "Screen")))
check(n(actions, "Drawer") >= 4 and n(actions, "Safe") >= 1, "cajones y caja fuerte")
check(n(actions, "Machine") >= 5 and n(actions, "Experiment") >= 6, ("máquinas (%d) y experimentos (%d)"):format(n(actions, "Machine"), n(actions, "Experiment")))
local robots, spins, fx = 0, 0, 0
for _, d in house:GetDescendants() do
	if d:HasTag("CosmeRobot") then
		robots += 1
	end
	if d:HasTag("CosmeSpin") then
		spins += 1
	end
	if d:IsA("ParticleEmitter") then
		fx += 1
		if d.Enabled then
			check(false, "partícula encendida desde el principio (solo cerca del jugador): " .. d:GetFullName())
		end
	end
end
check(robots >= 8, ("robots que se pasean: %d"):format(robots))
check(spins >= 15, ("cosas que giran (anillos, ventiladores, rotores): %d"):format(spins))
check(fx >= 30, ("emisores de partículas (apagados: solo cerca del jugador): %d"):format(fx))
local missingPrompt = 0
for _, d in house:GetDescendants() do
	if d:IsA("ProximityPrompt") and d:GetAttribute("CosmeAction") == "Doc" and (d:GetAttribute("Text") or "") == "" then
		missingPrompt += 1
	end
end
check(missingPrompt == 0, "cada documento tiene su texto")

---------------------------------------------------------------------
print("\n▶ Los sitios de la historia")
---------------------------------------------------------------------
local spots = {}
for _, d in house:GetDescendants() do
	if d:HasTag("StorySpot") then
		local id = d:GetAttribute("SpotId")
		spots[id] = (spots[id] or 0) + 1
	end
end
check(spots.GarajeCosme == 1, "la marca GarajeCosme (la de las 91 misiones) existe, una sola vez")
for id in Layout.Spots do
	local place = Locations.Places[id]
	check(spots[id] == 1 and place ~= nil and place.Tag == "StorySpot" and place.Attribute.SpotId == id, ("%s: marca en la casa y lugar en Locations"):format(id))
end
-- Alrededor de GarajeCosme hay sitio para los actores (los Offset de las misiones: hasta 5 studs)
local garageSpot
for _, d in house:GetDescendants() do
	if d:HasTag("StorySpot") and d:GetAttribute("SpotId") == "GarajeCosme" then
		garageSpot = d
	end
end
local crowded = {}
if garageSpot then
	for _, off in { Vector3.new(0, 0, 3), Vector3.new(3, 0, 2), Vector3.new(-3, 0, 0), Vector3.new(-3, 0, 1), Vector3.new(5, 0, 6), Vector3.new(-5, 0, 3), Vector3.new(0, 0, -4) } do
		local w = garageSpot.CFrame * CFrame.new(off.X, -0.5, off.Z)
		if blockedAt(w.Position) then
			table.insert(crowded, tostring(off))
		end
	end
	local lp = localPos(garageSpot.CFrame.Position)
	check(lp.Z < Layout.Garage.Z0 and lp.X > Layout.Garage.X0 and lp.X < Layout.Garage.X1, "GarajeCosme está delante del garaje, en la parcela")
end
check(#crowded == 0, "hay sitio libre alrededor de GarajeCosme para los actores de las misiones" .. (if #crowded > 0 then ": " .. table.concat(crowded, " ") else ""))
-- Las misiones que usan sitios de Cosme: todos existen en Locations
local used = {}
local function scan(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			scan(path)
		elseif name:match("%.luau$") then
			for place in fs.readFile(path):gmatch("Place = \"([%w_]+)\"") do
				if place:find("Cosme") then
					used[place] = true
				end
			end
			for place in fs.readFile(path):gmatch("\"Place:([%w_]+)\"") do
				if place:find("Cosme") then
					used[place] = true
				end
			end
		end
	end
end
scan("src/shared/LifeStory")
local unknown = {}
for place in used do
	if not Locations.Places[place] then
		table.insert(unknown, place)
	end
end
check(#unknown == 0, "todos los sitios de Cosme que usan las misiones existen en Locations" .. (if #unknown > 0 then ": faltan " .. table.concat(unknown, ", ") else ""))

---------------------------------------------------------------------
print("\n▶ Por fuera como el render, y el coche")
---------------------------------------------------------------------
local texts = {}
for _, d in house:GetDescendants() do
	if d:IsA("TextLabel") then
		table.insert(texts, string.upper(d.Text))
	end
end
local badText = {}
for _, t in texts do
	if t:find("TALLER DE COSME", 1, true) or t:find("¡LABORATORIO!", 1, true) then
		table.insert(badText, t)
	end
end
check(#badText == 0, "ningún cartel del garaje viejo («TALLER DE COSME», «NO ENTRAR ¡LABORATORIO!»)" .. (if #badText > 0 then ": " .. table.concat(badText, " | ") else ""))
local noEntrar = false
for _, t in texts do
	if t == "NO ENTRAR" then
		noEntrar = true
	end
end
check(noEntrar, "el cartel «NO ENTRAR» del tablón de madera")
local function find(name: string): Instance?
	return house:FindFirstChild(name, true)
end
local function countIn(root: Instance?, fn: (BasePart) -> boolean): number
	local n = 0
	if root then
		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") and fn(d) then
				n += 1
			end
		end
	end
	return n
end
local domeModel = find("CupulaObservacion")
local drums = 0
if domeModel then
	for _, name in { "TamborBajo", "TamborAlto" } do
		local drum = domeModel:FindFirstChild(name)
		if drum and countIn(drum, function(p)
			return p.Name == "WindowGlass"
		end) >= 16 then
			drums += 1
		end
	end
end
check(drums == 2, "torre redonda: dos tambores de cristal apilados")
check(domeModel ~= nil and domeModel:FindFirstChild("Platillo", true) ~= nil and domeModel:FindFirstChild("Parabolica", true) ~= nil and domeModel:FindFirstChild("Antena", true) ~= nil, "con el platillo, la parabólica y la antena encima")
local towerModel = find("TorrePortal")
local vortex = towerModel and towerModel:FindFirstChild("Vortice")
local vcenter = vortex and vortex:GetAttribute("Center")
check(vortex ~= nil and vortex:HasTag("CosmePortal") and typeof(vcenter) == "CFrame" and localPos((vcenter :: CFrame).Position).Y > Layout.F2 + 15, "torre de experimentos con el vórtice flotando encima, por encima de la cúpula baja")
check(countIn(towerModel, function(p)
	return p.Name == "TuboLuz" and p.Material == Enum.Material.Neon
end) >= 4, "la torre tiene tubos que brillan")
local FutureCar = L.load("src/server/World/Kit/FutureCar")
local cars = {}
for _, d in house:GetDescendants() do
	if d:IsA("Model") and FutureCar.is(d) then
		table.insert(cars, d)
	end
end
check(#cars >= 2, ("coches del kit FutureCar en la casa: %d (garaje y garaje de los portales)"):format(#cars))
for _, car in cars do
	local total, curved, wheels, strips, shiny, solidBody = 0, 0, 0, 0, 0, 0
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") then
			total += 1
			local mesh = d:FindFirstChildOfClass("SpecialMesh")
			if mesh and mesh.MeshType == Enum.MeshType.Sphere then
				curved += 1
			end
			if d:IsA("Part") and d.Shape == Enum.PartType.Cylinder then
				wheels += 1
			end
			if d.Material == Enum.Material.Neon and d.Transparency < 1 then
				strips += 1
			end
			if d.Reflectance > 0.1 then
				shiny += 1
			end
			if d.CanCollide and d.Name ~= "CarHitbox" and not d:IsA("Seat") then
				solidBody += 1
			end
		end
	end
	check(total >= 40 and curved >= 10 and wheels >= 12 and strips >= 8 and shiny >= 8 and solidBody == 0, ("%s: %d piezas, %d curvas (elipsoides), %d cilindros (ruedas y llantas), %d luces de neón, %d con reflejo"):format(car.Name, total, curved, wheels, strips, shiny))
end
local garageModel = house:FindFirstChild("GarajeCosme", true)
check(garageModel ~= nil and garageModel:FindFirstChild("PortalGaraje") ~= nil and garageModel:FindFirstChild("CocheExperimental") ~= nil and garageModel:FindFirstChild("BancoTrabajo") ~= nil, "garaje: portal redondo al fondo, el coche y el banco con monitores")

---------------------------------------------------------------------
print("\n▶ El garaje viejo ya no está")
---------------------------------------------------------------------
local home = fs.readFile("src/server/World/Kit/Home.luau")
local blocks = fs.readFile("src/server/World/Kit/Blocks.luau")
check(not home:find("cosmeGarage", 1, true) and not blocks:find("cosmeGarage", 1, true), "Home.cosmeGarage y Blocks.cosmeGarage quitados")
check(blocks:find("CosmeHouse.Build", 1, true) ~= nil, "la manzana de Cosme se construye con World/CosmeHouse")
local oldSign = {}
local function scanSrc(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			scanSrc(path)
		elseif name:match("%.luau$") and fs.readFile(path):upper():find("TALLER DE COSME", 1, true) then
			table.insert(oldSign, path)
		end
	end
end
scanSrc("src")
check(#oldSign == 0, "nadie construye ya el cartel «TALLER DE COSME»" .. (if #oldSign > 0 then ": " .. table.concat(oldSign, ", ") else ""))
local region = fs.readFile("src/server/World/Region.luau")
check(region:find("function Region.cosmeSite", 1, true) ~= nil and fs.readFile("src/server/World/TerrainBuilder.luau"):find("CosmeHouse.Exterior", 1, true) ~= nil, "la parcela sale de Region.cosmeSite y el terreno se vacía donde va el sótano")
check(fs.readFile("src/server/Main.server.luau"):find("CosmeHouse.Start", 1, true) ~= nil, "el servidor pone en marcha la casa (CosmeHouse/Start)")

-- Con un mapa construido (rojo build + scripts/build-place.luau): la casa de verdad del juego
local placePath = process.args[1]
if placePath then
	print("\n▶ El mapa construido (" .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local ws = game:GetService("Workspace")
	local houses, oldGarage, oldSign = {}, 0, {}
	for _, d in ws:GetDescendants() do
		if d:IsA("Model") and d.Name == "CasaCosme" then
			table.insert(houses, d)
		elseif d:IsA("Model") and d.Name == "GarajeCosme" and d:FindFirstChild("StorySpot_GarajeCosme") then
			oldGarage += 1
		elseif d:IsA("TextLabel") and string.upper(d.Text):find("TALLER DE COSME", 1, true) then
			table.insert(oldSign, d:GetFullName())
		end
	end
	check(#houses == 1, ("una sola casa de Cosme en el mapa (%d)"):format(#houses))
	check(oldGarage == 0 and #oldSign == 0, "ni rastro del garaje viejo en el mapa (ningún «TALLER DE COSME»)" .. (if #oldSign > 0 then ": " .. oldSign[1] else ""))
	local h = houses[1]
	if h then
		local cars = 0
		for _, d in h:GetDescendants() do
			if d:IsA("Model") and d:HasTag("FutureCar") then
				cars += 1
			end
		end
		check(h:FindFirstChild("CupulaObservacion", true) ~= nil and h:FindFirstChild("TorrePortal", true) ~= nil and cars >= 2, ("la casa del mapa trae la torre redonda, la torre del vórtice y los coches (%d)"):format(cars))
	end
end

print("")
if L.failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(L.failures))
	process.exit(1)
end
print("✅ La casa de Cosme está bien")
