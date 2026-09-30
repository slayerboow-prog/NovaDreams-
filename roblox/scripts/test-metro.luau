-- Prueba del metro en el mapa construido (World/Kit/MetroKit + MetroDetails), con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-metro.luau RealLifeSimulator.rbxl
--
-- Comprueba que:
--   * cada andén está girado como su línea (la vía del mapa coincide con el recorrido de los trenes)
--   * hay aseos, guardias, ratas, taquillas, puestos… repartidos por las estaciones y la galería
--   * nada sólido tapa los sitios por donde se pasa (tornos, escaleras, subir al tren, transbordos)
--   * cada estación tiene su boca de metro y se baja ANDANDO de la acera al vestíbulo de andenes:
--     siempre hay suelo debajo (sin huecos), nada sólido en medio y las escaleras mecánicas llevan

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Color3 = roblox.Vector3, roblox.CFrame, roblox.Color3

local path = process.args[1] or "RealLifeSimulator.rbxl"
local env = setmetatable({ Vector3 = Vector3, CFrame = CFrame, Color3 = Color3 }, { __index = getfenv(1) })
local Metro = luau.load(fs.readFile("src/shared/Metro.luau"), { debugName = "Metro", environment = env })()
local game = roblox.deserializePlace(fs.readFile(path))
local under = game:GetService("Workspace"):FindFirstChild("MetroSubterraneo", true)

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

print("Andenes alineados con las vías")
for _, line in Metro.Lines do
	for i, id in line.Stations do
		local st = under and under:FindFirstChild("Estacion_" .. line.Id .. "_" .. id)
		local bed = st and st:FindFirstChild("TrackBed")
		local center = Metro.center(id, line)
		local ok = false
		if bed then
			local dot = bed.CFrame.LookVector:Dot(Metro.direction(line, i))
			local off = (bed.CFrame.Position - Vector3.new(center.X, bed.CFrame.Position.Y, center.Z)).Magnitude
			ok = dot > 0.999 and off < 0.5
		end
		check(ok, ("%s %s: la vía del andén sigue la línea"):format(line.Id, id))
	end
end

print("Detalles del metro")
local tagged: { [string]: { any } } = {}
for _, d in (under :: any):GetDescendants() do
	if d:IsA("BasePart") then
		for _, t in d:GetTags() do
			tagged[t] = tagged[t] or {}
			table.insert(tagged[t], d)
		end
	end
end
local function count(tag: string): number
	return #(tagged[tag] or {})
end
local stations = 0
for _, line in Metro.Lines do
	stations += #line.Stations
end
check(count("MetroToilet") >= stations, "váteres en los aseos de las estaciones y de la galería")
check(count("MetroSink") >= 1 and count("MetroDryer") >= 1, "lavabos y secamanos")
check(count("MetroGuardPost") >= stations, "guardias (y limpiadores) en cada vestíbulo")
check(count("MetroRatNest") >= stations * 2, "ratas en las vías")
check(count("MetroLocker") >= 6 and count("MetroATM") >= 1 and count("MetroPhone") >= 1 and count("MetroBin") >= 1, "taquillas, cajeros, teléfonos y papeleras")
check(count("MetroFountain") == 1 and count("MetroPiano") == 1 and count("MetroStatue") == 1, "fuente, piano y estatua humana en la galería")
local shopsOk = true
for _, counter in tagged.MetroShop or {} do
	if not Metro.Shops[counter:GetAttribute("ShopId")] then
		shopsOk = false
		print("     tienda sin datos: " .. tostring(counter:GetAttribute("ShopId")))
	end
end
check(shopsOk, "todas las tiendas y puestos tienen su lista de productos")
local guardsOk = true
for _, post in tagged.MetroGuardPost or {} do
	if typeof(post:GetAttribute("A")) ~= "Vector3" or typeof(post:GetAttribute("B")) ~= "Vector3" then
		guardsOk = false
	end
end
for _, nest in tagged.MetroRatNest or {} do
	if typeof(nest:GetAttribute("A")) ~= "Vector3" or typeof(nest:GetAttribute("B")) ~= "Vector3" then
		guardsOk = false
	end
end
check(guardsOk, "guardias y ratas saben por dónde ir (A y B)")

print("Nada sólido tapa el paso")
local keys = {}
for _, tag in { "MetroBoard", "MetroExit", "MetroArrival", "MetroTransfer", "MetroHubArrival", "MetroAlight" } do
	for _, p in tagged[tag] or {} do
		table.insert(keys, { tag, p.CFrame.Position })
	end
end
for _, tag in { "MetroGate", "MetroGateExit" } do
	for _, g in tagged[tag] or {} do
		table.insert(keys, { tag .. " (al pasar)", g:GetAttribute("Through") })
	end
end
local blocked = 0
for _, p in (under :: any):GetDescendants() do
	if p:IsA("BasePart") and p.CanCollide and p.Transparency < 1 and #p:GetTags() == 0 or (p:IsA("BasePart") and p.CanCollide and p.Transparency < 1 and p:HasTag("MetroShop")) then
		for _, k in keys do
			local rel = p.CFrame:PointToObjectSpace(k[2])
			local h = p.Size / 2
			if math.abs(rel.X) < h.X + 0.5 and math.abs(rel.Y) < h.Y + 0.5 and math.abs(rel.Z) < h.Z + 0.5 then
				blocked += 1
				print(("     %s tapa %s"):format(p:GetFullName(), k[1]))
			end
		end
	end
end
check(blocked == 0, "tornos, escaleras, andenes y transbordos libres")

print("Bocas de metro que se bajan andando")
local metroRoot = game:GetService("Workspace"):FindFirstChild("Metro", true)
local bocas, belts, stepsModels = 0, 0, 0
for _, d in (metroRoot :: any):GetDescendants() do
	if d:IsA("Model") and d.Name == "BocaMetro" then
		bocas += 1
	elseif d:IsA("BasePart") and d:HasTag("MetroEscalator") then
		if typeof(d:GetAttribute("Velocity")) == "Vector3" and d:GetAttribute("Velocity").Magnitude > 1 then
			belts += 1
		end
	elseif d:IsA("Model") and d:HasTag("MetroEscalatorSteps") and (d:GetAttribute("Count") or 0) > 10 then
		stepsModels += 1
	end
end
local nStations = 0
for _ in Metro.Stations do
	nStations += 1
end
check(bocas == nStations, ("una boca de metro por estación (%d)"):format(bocas))
check(belts == nStations * 2 and stepsModels == nStations * 2, "dos escaleras mecánicas por boca (una baja y otra sube) con sus peldaños")
-- Taquilla con persona en el vestíbulo de cada boca (con sitio detrás para el taquillero/a)
local booths = {}
for _, d in (metroRoot :: any):GetDescendants() do
	if d:IsA("BasePart") and d:HasTag("MetroTicketBooth") and typeof(d:GetAttribute("StaffSpot")) == "Vector3" then
		booths[d:GetAttribute("Station")] = true
	end
end
local boothsOk = true
for id in Metro.Stations do
	if not booths[id] then
		boothsOk = false
		print("     sin taquilla: " .. id)
	end
end
check(boothsOk, "cada estación tiene su taquilla con persona")
-- Estaciones con personalidad: cada una (menos Plaza Mayor) con su azulejo, su mural y su cartel
local wallColors, themed, murals = {}, 0, true
for _, st in (under :: any):GetChildren() do
	local theme = st:GetAttribute("Theme")
	if theme then
		themed += 1
		local wall = st:FindFirstChild("FarWall")
		if wall then
			local c = wall.Color
			wallColors[("%d,%d,%d"):format(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))] = true
		end
		if not st:FindFirstChild("Mural") or not st:FindFirstChild("MuralArt") or not st:FindFirstChild("LobbyMural") then
			murals = false
			print("     sin mural: " .. st.Name)
		end
	end
end
local distinct = 0
for _ in wallColors do
	distinct += 1
end
check(themed == stations - 2 and murals, ("cada estación de calle tiene su mural y su cartel (%d)"):format(themed))
check(distinct >= nStations - 1, ("cada estación con su color de azulejo (%d distintos)"):format(distinct))
-- Recorrido andando: suelo debajo de cada paso y nada sólido a la altura del cuerpo
local solid = {}
for _, p in (metroRoot :: any):GetDescendants() do
	if p:IsA("BasePart") and p.CanCollide then
		table.insert(solid, p)
	end
end
local function inside(p: any, q: Vector3, pad: number): boolean
	local rel = p.CFrame:PointToObjectSpace(q)
	local h = p.Size / 2
	return math.abs(rel.X) <= h.X + pad and math.abs(rel.Y) <= h.Y + pad and math.abs(rel.Z) <= h.Z + pad
end
for id in Metro.Stations do
	local A = Metro.access(id)
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, q in A.Route do
		lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
		hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
	end
	local near = {}
	for _, p in solid do
		local c = p.CFrame.Position
		local r = p.Size.Magnitude / 2
		if c.X + r > lo.X - 2 and c.X - r < hi.X + 2 and c.Y + r > lo.Y - 2 and c.Y - r < hi.Y + 8 and c.Z + r > lo.Z - 2 and c.Z - r < hi.Z + 2 then
			table.insert(near, p)
		end
	end
	local gaps, blocks = 0, 0
	for k = 2, #A.Route do
		local a, b = A.Route[k - 1], A.Route[k]
		local n = math.max(1, math.ceil((b - a).Magnitude / 0.8))
		for i = 0, n do
			local q = a:Lerp(b, i / n)
			local floor, blocked = false, nil
			for _, p in near do
				if not floor and inside(p, q - Vector3.new(0, 0.25, 0), 0.02) then
					floor = true
				end
				if not blocked and inside(p, q + Vector3.new(0, 2.6, 0), 0) and inside(p, q + Vector3.new(0, 1.2, 0), 0) then
					blocked = p
				end
			end
			if not floor then
				gaps += 1
				if gaps <= 3 then
					print(("     %s: sin suelo en (%.1f, %.1f, %.1f)"):format(id, q.X, q.Y, q.Z))
				end
			end
			if blocked then
				blocks += 1
				if blocks <= 3 then
					print(("     %s: %s estorba en (%.1f, %.1f, %.1f)"):format(id, blocked:GetFullName(), q.X, q.Y, q.Z))
				end
			end
		end
	end
	check(gaps == 0 and blocks == 0, id .. ": de la acera al andén andando, sin huecos ni nada en medio")
end

print("Tornos: pasar y quedarse en el andén (niño, adulto con y sin billete, modo pruebas)")
-- Lo mismo que hace MetroService con los tornos (Metro.gatePass / gateSide / gatePromptAt / gateLanding)
-- sobre los tornos de verdad del mapa. Un "toque de Interactuar" pulsa el cartel que va primero en
-- COMANDOS: el de más prioridad (MenuLogic.byPriority) y, a igualdad, el más cercano, entre los que
-- llegan hasta ti (MaxActivationDistance de cada cartel, como en MetroService/MetroLifeService).
local MenuLogic = luau.load(fs.readFile("src/client/Commands/MenuLogic.luau"), { debugName = "MenuLogic", environment = env })()
local G = Metro.Gate
local function stationKey(p: any): string
	local node = p
	while node and not string.find(node.Name, "^Estacion_") do
		node = node.Parent
	end
	return if node then node.Name else "?"
end
type P = { Kind: string, Action: string, At: Vector3, Reach: number, Priority: number, Part: any }
local byStation: { [string]: { P } } = {}
local function add(p: any, entry: P)
	local key = stationKey(p)
	byStation[key] = byStation[key] or {}
	table.insert(byStation[key], entry)
end
for _, g in tagged.MetroGate or {} do
	add(g, { Kind = "Gate", Action = "Pasar (billete)", At = Metro.gatePromptAt(g.CFrame.Position, g:GetAttribute("Through")), Reach = G.Reach, Priority = G.Priority, Part = g })
end
for _, g in tagged.MetroGateExit or {} do
	add(g, { Kind = "Exit", Action = "Salir", At = Metro.gatePromptAt(g.CFrame.Position, g:GetAttribute("Through")), Reach = G.ExitReach, Priority = G.Priority, Part = g })
end
for _, b in tagged.MetroBoard or {} do
	add(b, { Kind = "Board", Action = "Subir al metro", At = b.CFrame.Position, Reach = 7, Priority = G.Priority, Part = b })
end
for _, b in tagged.MetroIntercom or {} do
	add(b, { Kind = "SOS", Action = "Pulsar SOS", At = b.CFrame.Position, Reach = 6, Priority = Metro.AmbientPriority, Part = b })
end
for _, b in tagged.MetroBin or {} do
	add(b, { Kind = "Bin", Action = "Rebuscar", At = b.CFrame.Position, Reach = 7, Priority = Metro.AmbientPriority, Part = b })
end
for _, nest in tagged.MetroRatNest or {} do
	-- La rata corretea entre A y B (a ras de suelo): se prueba el tramo entero
	local a, b = nest:GetAttribute("A"), nest:GetAttribute("B")
	for i = 0, 10 do
		add(nest, { Kind = "Rat", Action = "Espantar", At = a:Lerp(b, i / 10) + Vector3.new(0, 0.35, 0), Reach = 7, Priority = Metro.AmbientPriority, Part = nest })
	end
end
-- El primero de COMANDOS desde una posición (o nil)
local function interact(key: string, at: Vector3): P?
	local list = {}
	for _, p in byStation[key] or {} do
		local d = (p.At - at).Magnitude
		if d <= p.Reach then
			table.insert(list, { P = p, Distance = d })
		end
	end
	table.sort(list, function(x, y)
		return x.Distance < y.Distance
	end)
	local ordered = MenuLogic.byPriority(list, function(t)
		return t.P.Priority
	end)
	return ordered[1] and ordered[1].P
end
local function reachable(key: string, at: Vector3, kind: string): boolean
	for _, p in byStation[key] or {} do
		if p.Kind == kind and (p.At - at).Magnitude <= p.Reach + 0.3 then
			return true
		end
	end
	return false
end
local function hasFloor(q: Vector3): boolean
	for _, p in (under :: any):GetDescendants() do
		if p:IsA("BasePart") and p.CanCollide and inside(p, q, 0.02) then
			return true
		end
	end
	return false
end
local glassOf: { [string]: any } = {}
for _, p in (under :: any):GetDescendants() do
	if p:IsA("BasePart") and p.Name == "GateGlass" then
		glassOf[stationKey(p)] = p
	end
end
local WHO = {
	{ Name = "niño", Who = { Stage = "Nino", Tickets = 0 }, Mode = "Gratis" },
	{ Name = "adulto con billete", Who = { Stage = "Adulto", Tickets = 1 }, Mode = "Billete" },
	{ Name = "adulto sin billete", Who = { Stage = "Adulto", Tickets = 0 }, Mode = nil },
	{ Name = "modo pruebas", Who = { Stage = "Adulto", Tickets = 0, Tester = true }, Mode = "Pruebas" },
	{ Name = "con abono", Who = { Stage = "Adulto", Tickets = 0, Pass = true }, Mode = "Abono" },
}
for _, case in WHO do
	check(Metro.gatePass(case.Who) == case.Mode, ("%s: %s"):format(case.Name, tostring(case.Mode or "no pasa")))
end
local gatesOk, sideOk, stayOk, reachOk, stealOk, exitOk, floorOk = 0, 0, 0, 0, 0, 0, 0
local nGates, nExits = #(tagged.MetroGate or {}), #(tagged.MetroGateExit or {})
local shown = 0
local function fail(text: string)
	shown += 1
	if shown <= 12 then
		print("     " .. text)
	end
end
for _, g in tagged.MetroGate or {} do
	local key = stationKey(g)
	local through = g:GetAttribute("Through")
	local glass = glassOf[key]
	local dir = Metro.gateDirection(g.CFrame.Position, through)
	-- 1) Delante del torno (vestíbulo), el primer comando es "Pasar (billete)" (ni ratas ni SOS)
	local front = Metro.gatePromptAt(g.CFrame.Position, through) + Vector3.new(0, 1.3 - G.PromptHeight, 0) - dir * 0.5
	local first = interact(key, front)
	-- (y ni siquiera se ven al lado: ni ratas, ni interfono, ni papeleras, que en el móvil tapan el torno)
	local ambient = nil
	for _, kind in { "SOS", "Rat", "Bin" } do
		if reachable(key, front, kind) or reachable(key, Metro.gateLanding(g.CFrame.Position, through).Position, kind) then
			ambient = kind
		end
	end
	if first and first.Kind == "Gate" and not ambient then
		stealOk += 1
	else
		fail(("%s: delante del torno el primer comando es %s%s"):format(key, if first then first.Action else "nada", if ambient then " (y se ve " .. ambient .. ")" else ""))
	end
	-- 2) El torno le usa desde el vestíbulo; te deja al otro lado del cristal, con suelo y en el andén
	local landing = Metro.gateLanding(g.CFrame.Position, through)
	local sideGlass = glass and Metro.gateSide(g.CFrame.Position, through, glass.CFrame.Position) or math.huge
	if Metro.gateSide(g.CFrame.Position, through, front) < 0 and Metro.gateSide(g.CFrame.Position, through, landing.Position) > sideGlass + 1 then
		sideOk += 1
	else
		fail(key .. ": el torno no te deja al otro lado del cristal")
	end
	if hasFloor(through - Vector3.new(0, 3.25, 0)) then
		floorOk += 1
	else
		fail(key .. ": sin suelo donde te deja el torno")
	end
	if landing.LookVector:Dot(dir) > 0.99 then
		gatesOk += 1
	else
		fail(key .. ": te deja mirando al torno")
	end
	-- 3) Ya en el andén: el torno no llega ("Pasar (billete)" no sale) y un segundo toque de
	--    Interactuar no te devuelve al vestíbulo (ni "Salir" ni "Pasar" van primero)
	local again = interact(key, landing.Position)
	if not reachable(key, landing.Position, "Gate") and not reachable(key, landing.Position, "Exit") and not (again and (again.Kind == "Gate" or again.Kind == "Exit")) then
		stayOk += 1
	else
		fail(("%s: en el andén el primer comando es %s"):format(key, if again then again.Action else "nada"))
	end
	-- 4) Pegado al cristal por el lado del andén, "Pasar (billete)" tampoco llega
	local platformSide = g.CFrame.Position + dir * (sideGlass + 1) + Vector3.new(0, 1.3, 0)
	if not reachable(key, platformSide, "Gate") then
		reachOk += 1
	else
		fail(key .. ": 'Pasar (billete)' se ve desde el andén")
	end
end
for _, g in tagged.MetroGateExit or {} do
	local key = stationKey(g)
	local through = g:GetAttribute("Through")
	local glass = glassOf[key]
	local dir = Metro.gateDirection(g.CFrame.Position, through)
	local sideGlass = glass and Metro.gateSide(g.CFrame.Position, through, glass.CFrame.Position) or math.huge
	local lobbySide = g.CFrame.Position + dir * (sideGlass + 1) + Vector3.new(0, 1.3, 0)
	local landing = Metro.gateLanding(g.CFrame.Position, through).Position
	-- "Salir" solo desde el andén, y te deja en el vestíbulo con suelo
	if not reachable(key, lobbySide, "Exit") and Metro.gateSide(g.CFrame.Position, through, landing) > sideGlass + 1 and hasFloor(through - Vector3.new(0, 3.25, 0)) then
		exitOk += 1
	else
		fail(key .. ": el torno de salida se ve desde el vestíbulo o no te deja en él")
	end
end
check(nGates > 0 and stealOk == nGates, ("delante de cada torno, Interactuar pulsa «Pasar (billete)» y no hay ratas, SOS ni papeleras al lado (%d/%d)"):format(stealOk, nGates))
check(sideOk == nGates and floorOk == nGates and gatesOk == nGates, ("el torno te deja en el andén, con suelo y mirando hacia delante (%d/%d)"):format(math.min(sideOk, floorOk, gatesOk), nGates))
check(stayOk == nGates, ("en el andén, ni «Pasar (billete)» ni «Salir» te devuelven con otro toque (%d/%d)"):format(stayOk, nGates))
check(reachOk == nGates, ("«Pasar (billete)» no se ve desde el andén (%d/%d)"):format(reachOk, nGates))
check(nExits > 0 and exitOk == nExits, ("«Salir» solo desde el andén y te deja en el vestíbulo (%d/%d)"):format(exitOk, nExits))
check(Metro.gateSide(Vector3.new(0, 0, 0), Vector3.new(-4, 0, 0), Vector3.new(3, 0, 0)) < 0 and Metro.gateSide(Vector3.new(0, 0, 0), Vector3.new(-4, 0, 0), Vector3.new(-4, 0, 0)) > 0, "desde el otro lado, el torno no hace nada (ni cobra ni te mueve)")
check(G.Grace >= 1.5, "tras cruzar un torno, un segundo toque no te devuelve (Metro.Gate.Grace)")

print("Máquinas de billetes: el cartel no se ve desde la escalera de la calle")
do
	local sellers = {}
	for _, d in (metroRoot :: any):GetDescendants() do
		if d:IsA("BasePart") and (d:HasTag("MetroTicketMachine") or d:HasTag("MetroTicketBooth")) then
			table.insert(sellers, d)
		end
	end
	local withPrompt, leaks = 0, 0
	for _, d in sellers do
		if typeof(d:GetAttribute("PromptAt")) == "Vector3" then
			withPrompt += 1
		end
	end
	for id in Metro.Stations do
		local A = Metro.access(id)
		local lo, hi = A.Hall.Min, A.Hall.Max
		for k = 2, #A.Route do
			local a, b = A.Route[k - 1], A.Route[k]
			local n = math.max(1, math.ceil((b - a).Magnitude / 1))
			for i = 0, n do
				local q = a:Lerp(b, i / n)
				local inHall = q.X > lo.X - 0.5 and q.X < hi.X + 0.5 and q.Z > lo.Z - 0.5 and q.Z < hi.Z + 0.5 and q.Y > lo.Y - 1 and q.Y < hi.Y
				if not inHall then
					local root = q + Vector3.new(0, 2.5, 0)
					for _, d in sellers do
						local at = d:GetAttribute("PromptAt")
						if typeof(at) == "Vector3" and (at - root).Magnitude <= Metro.SellerReach + 0.3 then
							leaks += 1
							if leaks <= 4 then
								print(("     %s: «Comprar billete» se ve desde (%.1f, %.1f, %.1f), fuera del vestíbulo"):format(id, q.X, q.Y, q.Z))
							end
						end
					end
				end
			end
		end
	end
	check(#sellers > 0 and withPrompt == #sellers, ("cada máquina y taquilla tiene su cartel delante (%d/%d)"):format(withPrompt, #sellers))
	check(leaks == 0, "«Comprar billete» no se ve desde la escalera de la calle ni desde el pozo de las mecánicas")
end

print("Panel del tren: compacto y sin pisar nada (móvil y ordenador)")
do
	local layoutEnv = setmetatable({ Vector3 = Vector3, CFrame = CFrame, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2 }, { __index = getfenv(1) })
	local HudLayout = luau.load(fs.readFile("src/client/UI/HudLayout.luau"), { debugName = "HudLayout", environment = layoutEnv })()
	local sizes = { { 640, 360, true }, { 844, 390, true }, { 932, 430, true }, { 1024, 768, true }, { 1366, 768, false }, { 1920, 1080, false } }
	for _, size in sizes do
		local layout = HudLayout.compute(roblox.Vector2.new(size[1], size[2]), { Touch = size[3] })
		local ride = layout.Items.Ride
		local clashes = {}
		if not ride then
			table.insert(clashes, "sin Items.Ride")
		else
			local r = HudLayout.rect(ride, layout.Canvas)
			if r.X < 0 or r.Y < 0 or r.X + r.W > layout.Canvas.X or r.Y + r.H > layout.Canvas.Y then
				table.insert(clashes, "se sale de la pantalla")
			end
			-- (la tarjeta de primeros pasos se quita mientras vas en el tren: Guide.areaTaken)
			for name, p in layout.Items do
				if name ~= "Ride" and name ~= "Guide" and p.Size.X > 0 and p.Size.Y > 0 and HudLayout.overlaps(r, HudLayout.rect(p, layout.Canvas)) then
					table.insert(clashes, name)
				end
			end
			for name, p in layout.Slots do
				if HudLayout.overlaps(r, HudLayout.rect(p, layout.Canvas)) then
					table.insert(clashes, "botón " .. name)
				end
			end
		end
		check(#clashes == 0, ("%dx%d%s: el panel del tren no pisa nada%s"):format(size[1], size[2], if size[3] then " (móvil)" else "", if #clashes > 0 then " (" .. table.concat(clashes, ", ") .. ")" else ""))
	end
	local ui = fs.readFile("src/client/Controllers/MetroUI.luau")
	check(ui:find("layout.Items.Ride", 1, true) ~= nil and ui:find("HudLayout.scaleGui(rideGui)", 1, true) ~= nil, "el panel del tren va donde dice HudLayout (Items.Ride), a la escala del HUD")
	check(ui:find("boardPrompts(false)", 1, true) ~= nil and ui:find("boardPrompts(true)", 1, true) ~= nil, "dentro del tren no sale «Subir al metro»")
	check(ui:find("rideIncident", 1, true) ~= nil, "la incidencia de tu línea va dentro del panel del tren, en una línea pequeña")
	local guide = fs.readFile("src/client/Controllers/Guide.luau")
	check(guide:find("MetroRideGui", 1, true) ~= nil, "la tarjeta de primeros pasos se aparta mientras vas en el tren")
end

print("Bocas y vestíbulos: sin terreno asomando ni cosas raras flotando")
do
	local backs, glassPuddles, nStations = 0, 0, 0
	for _ in Metro.Stations do
		nStations += 1
	end
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "StairWallBack" and d.CanCollide then
				backs += 1
			elseif d.Name == "Puddle" and d.Material == roblox.Enum.Material.Glass then
				glassPuddles += 1
			end
		end
	end
	check(backs == nStations * 2, ("las paredes del hueco de la escalera llevan trasdós (el terreno no asoma) (%d/%d)"):format(backs, nStations * 2))
	local access = fs.readFile("src/server/World/Kit/MetroAccess.luau")
	check(access:find("W + MARGIN", 1, true) ~= nil and access:find("hi.X - lo.X + 1.4 + MARGIN", 1, true) ~= nil, "se vacía un cubo de terreno de margen alrededor de la escalera, el vestíbulo y el pozo")
	check(glassPuddles == 0, "los charcos no son de cristal (en el móvil se veían como óvalos blancos)")
	local life = fs.readFile("src/server/Services/MetroLifeService.luau")
	check(life:find('Npc.icon(npc, if cleaner', 1, true) == nil, "guardias y limpiadores sin 🛡️/🧽 flotando encima")
	local svc = fs.readFile("src/server/Services/MetroService.luau")
	check(svc:find('RIDER_ICONS[math.random(1, #RIDER_ICONS)], true)', 1, true) ~= nil and svc:find('Npc.icon, npc, "👮", true)', 1, true) ~= nil, "los iconos de los viajeros y de la policía del metro no flotan a través de las paredes")
end

print("Estaciones holgadas y enterradas: nada asoma por la calle ni por el terreno")
do
	-- La superficie más baja por encima de una estación: el césped del terreno (Y = -1; las calzadas y
	-- aceras van de 0 a 1). Todo lo de dentro (paredes, techos, carteles… y la cabeza de quien esté de pie
	-- dentro: NPC_TOP studs sobre el suelo) queda al menos 1 stud por debajo.
	local SURFACE, NPC_TOP = -1, 6.5
	local function top(p: any): number
		local c = { p.CFrame:GetComponents() }
		local sz = p.Size
		return c[2] + (math.abs(c[7]) * sz.X + math.abs(c[8]) * sz.Y + math.abs(c[9]) * sz.Z) / 2
	end
	local worst, worstName, parts = -math.huge, "", 0
	local function scan(root: any)
		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
				local t = top(d)
				if t > worst then
					worst, worstName = t, d:GetFullName()
				end
			end
		end
	end
	scan(under)
	for _, d in (metroRoot :: any):GetDescendants() do
		if d:IsA("Model") and (string.find(d.Name, "^Vestibulo_") or string.find(d.Name, "^Escaleras_")) then
			scan(d)
		end
	end
	check(parts > 0 and worst <= SURFACE - 1, ("nada de dentro de las estaciones llega a 1 stud de la superficie (lo más alto: %.1f, %s)"):format(worst, worstName))
	-- Dónde se pone de pie la gente del metro (guardias, limpiadores, taquilleros, viajeros, policía…)
	local spots, high = 0, 0
	local function spot(y: number, what: string)
		spots += 1
		if y + NPC_TOP > SURFACE - 1 then
			high += 1
			print(("     %s: una persona de pie ahí asomaría por la calle (%.1f)"):format(what, y + NPC_TOP))
		end
	end
	for _, d in (metroRoot :: any):GetDescendants() do
		if d:IsA("BasePart") then
			for _, attr in { "A", "B", "StaffSpot" } do
				local v = d:GetAttribute(attr)
				if typeof(v) == "Vector3" then
					spot(v.Y, d:GetFullName())
				end
			end
			if d:HasTag("MetroAlight") or d:HasTag("MetroStaff") or d:HasTag("MetroStatue") or d:HasTag("MetroArrival") then
				spot(d.CFrame.Position.Y - d.Size.Y / 2, d:GetFullName())
			end
		end
	end
	check(spots > 0 and high == 0, ("nadie de pie dentro de una estación asoma por la calle (%d sitios)"):format(spots))
	-- Holgura: escaleras de la calle anchas, vestíbulos altos
	local narrow = 0
	for id in Metro.Stations do
		local A = Metro.access(id)
		if A.Stair.Width < 8 or A.Hall.Max.Y - A.Hall.Min.Y < 10 then
			narrow += 1
		end
	end
	check(narrow == 0 and Metro.Lobby.Height >= 15 and Metro.Shaft.Stairs >= 4, ("escaleras de la calle de %d de ancho, vestíbulos de %d de alto y andenes con %d de techo"):format(Metro.StreetStairs.Width, Metro.HallHeight, Metro.Lobby.Height))
	check(Metro.HallY + Metro.HallHeight + 0.5 <= SURFACE - 3, "el techo del vestíbulo de la calle queda bajo las calzadas (que llegan hasta Y = -4)")
end

print(if failures == 0 then "\nTodo bien ✅" else ("\n%d fallos ❌"):format(failures))
process.exit(if failures == 0 then 0 else 1)
