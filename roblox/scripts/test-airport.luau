-- Prueba del aeropuerto en el mapa construido, con Lune (sin Roblox).
--
-- Uso (desde la carpeta roblox/):
--   rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl
--   lune run scripts/test-airport.luau /tmp/x.rbxl
--
-- Comprueba que:
--   * están el Aeropuerto de Valmar, el Aeródromo de las Gaviotas y los dos aviones (siempre cargados,
--     con su suelo Root, sus asientos y marcados para soldarse al arrancar)
--   * la pista es plana y está despejada, y por donde ruedan los aviones no hay nada con lo que choquen
--   * nada del resto de la ciudad se mete en el aeropuerto (ni calles, ni casas, ni árboles)
--   * la terminal se recorre andando: de la parada del bus a los mostradores, por el control de
--     seguridad hasta las puertas, y de la sala de llegadas a la calle; y en la isla, de la llegada
--     al mostrador y a la puerta de embarque
--   * en el aire, los aviones pasan por encima de todo lo construido

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Color3, Enum = roblox.Vector3, roblox.CFrame, roblox.Color3, roblox.Enum

local placePath = process.args[1]
if not placePath then
	print("Uso: lune run scripts/test-airport.luau <mapa construido .rbxl>")
	process.exit(1)
end

local function load(path: string): any
	local env = setmetatable({ Vector3 = Vector3, CFrame = CFrame, Color3 = Color3, Enum = Enum, script = { Parent = {} } }, { __index = getfenv(1) })
	return luau.load(fs.readFile(path), { debugName = path, environment = env })()
end
local Airport = load("src/shared/Airport.luau")
local CityPlan = load("src/shared/CityPlan.luau")

local failures = 0
local function check(ok: boolean, what: string)
	print((if ok then "  ✅ " else "  ❌ ") .. what)
	if not ok then
		failures += 1
	end
end

print("▶ Leyendo el mapa…")
local game = roblox.deserializePlace(fs.readFile(placePath))
local town = game:GetService("Workspace"):FindFirstChild("Town")
assert(town, "el mapa no tiene la ciudad construida (Workspace.Town)")
local valmar = town:FindFirstChild(Airport.Places.Valmar.Model)
local gaviotas = town:FindFirstChild(Airport.Places.Gaviotas.Model)
local planesFolder = town:FindFirstChild("Aviones")

---------------------------------------------------------------------
print("▶ Aeropuerto, aeródromo y aviones")
check(valmar ~= nil and valmar:IsA("Model"), "está el Aeropuerto de Valmar (modelo «Aeropuerto», sale en el mapa)")
check(gaviotas ~= nil and gaviotas:IsA("Model"), "está el Aeródromo de las Gaviotas (modelo «Aerodromo»)")
local planesOk = planesFolder ~= nil
for _, spec in Airport.Planes do
	local m = planesFolder and planesFolder:FindFirstChild(spec.Id)
	local seats = 0
	for _, d in (if m then m:GetDescendants() else {}) do
		if d:IsA("Seat") then
			seats += 1
		end
	end
	local root = m and m:FindFirstChild("Root")
	local ok = m ~= nil and m:HasTag("Plane") and m:GetAttribute("PlaneId") == spec.Id and m:GetAttribute("NeedsWeld") == true
		and root ~= nil and root:IsA("BasePart") and seats == Airport.Kinds[spec.Kind].Seats and m.ModelStreamingMode == Enum.ModelStreamingMode.Persistent
	if ok then
		-- En su puerta al empezar
		local want = Airport.rootCFrame(spec.Kind, Airport.parkPose(Airport.Routes[spec.Routes[1]])).Position
		ok = (root.CFrame.Position - want).Magnitude < 0.5
	end
	if not ok then
		planesOk = false
		print("    (avión) " .. spec.Id)
	end
end
check(planesOk, "los dos aviones esperan en su puerta: siempre cargados, con su suelo, sus asientos y por soldar")
local tags = { FlightCheckIn = 0, FlightGate = 0, FlightArrival = 0, FlightBoard = 0 }
local travel = false
for _, d in town:GetDescendants() do
	for tag in tags do
		if d:HasTag(tag) then
			tags[tag] += 1
		end
	end
	if d:HasTag("TravelStop") and d:GetAttribute("Town") == Airport.Name then
		travel = true
	end
end
check(tags.FlightCheckIn == 3 and tags.FlightGate == 3 and tags.FlightArrival == 2 and tags.FlightBoard >= 3, ("mostradores, puertas, llegadas y paneles de salidas (%d, %d, %d, %d)"):format(tags.FlightCheckIn, tags.FlightGate, tags.FlightArrival, tags.FlightBoard))
check(travel, "parada del autobús interurbano en la terminal (se llega desde todas las ciudades)")

---------------------------------------------------------------------
-- Cajas de las piezas (alineadas con los ejes del mundo)
---------------------------------------------------------------------
type Box = { Part: any, Lo: Vector3, Hi: Vector3, Solid: boolean, Owner: string }
local function boxOf(d: any): (Vector3, Vector3)
	local c = { d.CFrame:GetComponents() }
	local s = d.Size
	local hx = (math.abs(c[4]) * s.X + math.abs(c[5]) * s.Y + math.abs(c[6]) * s.Z) / 2
	local hy = (math.abs(c[7]) * s.X + math.abs(c[8]) * s.Y + math.abs(c[9]) * s.Z) / 2
	local hz = (math.abs(c[10]) * s.X + math.abs(c[11]) * s.Y + math.abs(c[12]) * s.Z) / 2
	return Vector3.new(c[1] - hx, c[2] - hy, c[3] - hz), Vector3.new(c[1] + hx, c[2] + hy, c[3] + hz)
end
local L = Airport.Land
local gv = { X0 = Airport.Strip.X0 - 4, X1 = Airport.Strip.X1 + 4, Z0 = Airport.StripHut.Z - 16, Z1 = Airport.Strip.Z + Airport.Strip.Width / 2 + 4 }
local access = { X0 = Airport.Access.X - 20, X1 = Airport.Access.X + 20, Z0 = Airport.Access.Z0, Z1 = L.Z0 }
local function touches(lo: Vector3, hi: Vector3, r: { [string]: number }, margin: number): boolean
	return hi.X > r.X0 - margin and lo.X < r.X1 + margin and hi.Z > r.Z0 - margin and lo.Z < r.Z1 + margin
end

local CELL = 16
local grid: { [number]: { Box } } = {}
local function key(gx: number, gz: number): number
	return (gx + 4000) * 8000 + (gz + 4000)
end
local tall: { Box } = {} -- (todo lo alto de la ciudad, para los vuelos)
local intruders = {}
local function ownerOf(d: any): string
	if valmar and d:IsDescendantOf(valmar) then
		return "Valmar"
	elseif gaviotas and d:IsDescendantOf(gaviotas) then
		return "Gaviotas"
	elseif planesFolder and d:IsDescendantOf(planesFolder) then
		return "Avion"
	end
	return "Ciudad"
end
for _, d in town:GetDescendants() do
	if d:IsA("BasePart") and not d:HasTag("EditOnly") then
		local lo, hi = boxOf(d)
		local near = touches(lo, hi, L, 60) or touches(lo, hi, gv, 60) or touches(lo, hi, access, 30)
		if near or hi.Y > 60 then
			local owner = ownerOf(d)
			local b: Box = { Part = d, Lo = lo, Hi = hi, Solid = d.CanCollide, Owner = owner }
			if hi.Y > 60 and owner == "Ciudad" then
				table.insert(tall, b)
			end
			if near then
				for gx = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
					for gz = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
						local k = key(gx, gz)
						local list = grid[k]
						if not list then
							list = {}
							grid[k] = list
						end
						table.insert(list, b)
					end
				end
				-- Lo que no es del aeropuerto no puede estar dentro de él (con 0,05 de tolerancia: las
				-- calles de la ciudad acaban justo donde empieza la carretera del aeropuerto)
				if owner == "Ciudad" then
					local e = 0.05
					local inside = (hi.X > L.X0 + e and lo.X < L.X1 - e and hi.Z > L.Z0 + e and lo.Z < L.Z1 - e)
						or (hi.X > gv.X0 + e and lo.X < gv.X1 - e and hi.Z > gv.Z0 + e and lo.Z < gv.Z1 - e)
						or (hi.X > access.X0 + e and lo.X < access.X1 - e and hi.Z > access.Z0 + e and lo.Z < access.Z1 - e)
					if inside and hi.Y > -3 then
						table.insert(intruders, d:GetFullName())
					end
				end
			end
		end
	end
end
local function at(x: number, z: number): { Box }
	local out = {}
	for _, b in grid[key(math.floor(x / CELL), math.floor(z / CELL))] or {} do
		if x >= b.Lo.X and x <= b.Hi.X and z >= b.Lo.Z and z <= b.Hi.Z then
			table.insert(out, b)
		end
	end
	return out
end

---------------------------------------------------------------------
print("▶ Nada de la ciudad dentro del aeropuerto")
for i = 1, math.min(8, #intruders) do
	print("    " .. intruders[i])
end
check(#intruders == 0, ("ninguna calle, casa, árbol ni farola de la ciudad se mete en el aeropuerto ni en el aeródromo (%d)"):format(#intruders))
-- Tampoco se cruzan con las calles y manzanas del plano (Region/Districts se construyen del plano)
check(CityPlan.inside(CityPlan.Coast, L.X0 + 10, L.Z1 - 10) == false and CityPlan.inside(CityPlan.Coast, L.X0 + 10, L.Z0 + 10) == false, "el aeropuerto está en tierra ganada al mar (fuera de la costa de la isla)")
local isl
for _, island in CityPlan.Islands do
	if island.Name == "Isla de las Gaviotas" then
		isl = island
	end
end
local fits = isl ~= nil
for _, p in { { gv.X0, gv.Z0 }, { gv.X1, gv.Z0 }, { gv.X0, gv.Z1 }, { gv.X1, gv.Z1 } } do
	if isl and math.sqrt((p[1] - isl.X) ^ 2 + (p[2] - isl.Z) ^ 2) > isl.R - 30 then
		fits = false
	end
end
check(fits, "el aeródromo cabe entero en la hierba de la Isla de las Gaviotas")

---------------------------------------------------------------------
print("▶ Pista plana y despejada")
local R = Airport.Runway
local G = Airport.GROUND
local flat, clear, count = true, true, 0
for x = R.X0 + 1, R.X1 - 1, 7 do
	for z = R.Z - R.Width / 2 + 1, R.Z + R.Width / 2 - 1, 4 do
		count += 1
		local top = -math.huge
		for _, b in at(x, z) do
			if b.Solid and b.Owner ~= "Avion" then
				if b.Hi.Y > G + 0.01 and b.Lo.Y < G + 30 then
					clear = false
					print(("    (algo en la pista) %s en (%.0f, %.0f)"):format(b.Part.Name, x, z))
				end
				top = math.max(top, b.Hi.Y)
			end
		end
		if math.abs(top - G) > 0.01 then
			flat = false
		end
	end
end
check(flat, ("la pista es plana: asfalto a Y = %.1f en %d puntos (%d studs de largo)"):format(G, count, R.X1 - R.X0))
check(clear, "no hay nada sólido encima de la pista (luces y marcas no chocan)")
check(R.X1 - R.X0 >= 600 and R.X1 - R.X0 <= 1000, "la pista mide entre 600 y 1000 studs")
-- Por donde ruedan los aviones (con la mitad de su envergadura a cada lado) no hay nada con lo que chocar
local hits = {}
for id, route in Airport.Routes do
	local span = Airport.Kinds[route.Kind].Span / 2
	local t = 0
	while t <= route.Total do
		local cf = Airport.pose(route, t)
		local p = cf.Position
		if p.Y < G + 0.5 then
			for v = -span, span, 3 do
				local q = cf * Vector3.new(v, 0, 0)
				for _, b in at(q.X, q.Z) do
					if b.Solid and b.Owner ~= "Avion" and b.Hi.Y > G + 0.6 and b.Lo.Y < G + 14 then
						hits[b.Part:GetFullName()] = id
					end
				end
			end
		end
		t += 0.5
	end
end
local nHits = 0
for name, id in hits do
	nHits += 1
	if nHits <= 6 then
		print(("    (%s) %s"):format(id, name))
	end
end
check(nHits == 0, "al rodar (pista, calle de rodaje, plataforma) los aviones no chocan con nada")

---------------------------------------------------------------------
print("▶ Se recorre andando")
-- Camina de un punto a otro: el suelo sólido bajo los pies (subiendo como mucho un escalón) y nada
-- sólido a la altura del cuerpo
local function walk(points: { Vector3 }, what: string)
	local feet: number? = 1.2 -- (todos los caminos empiezan a ras de suelo)
	local problem: string? = nil
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local n = math.max(1, math.ceil((b - a).Magnitude))
		for k = 0, n do
			local p = a:Lerp(b, k / n)
			local ground: number? = nil
			local list = at(p.X, p.Z)
			for _, box in list do
				if box.Solid and box.Owner ~= "Avion" and box.Hi.Y <= (feet or 1.2) + 1.3 then
					ground = if ground then math.max(ground, box.Hi.Y) else box.Hi.Y
				end
			end
			if not ground then
				problem = ("sin suelo en (%.0f, %.0f)"):format(p.X, p.Z)
				break
			end
			if feet and ground < feet - 3 then
				problem = ("un hueco en (%.0f, %.0f)"):format(p.X, p.Z)
				break
			end
			for _, box in list do
				if box.Solid and box.Lo.Y < ground + 5 and box.Hi.Y > ground + 1.3 then
					problem = ("choca con %s en (%.0f, %.0f)"):format(box.Part.Name, p.X, p.Z)
					break
				end
			end
			if problem then
				break
			end
			feet = ground
		end
		if problem then
			break
		end
	end
	if problem then
		print("    " .. problem)
	end
	check(problem == nil, what)
end
local V = function(x: number, z: number): Vector3
	return Vector3.new(x, 0, z)
end
walk({ V(-2850, 3042), V(-2780, 3042), V(-2780, 3070), V(-2966, 3078) }, "de la parada del autobús a los mostradores de facturación")
walk({ V(-2966, 3078), V(-2850, 3078), V(-2850, 3112), V(-2900, 3120), V(-2900, 3135) }, "de los mostradores, por el arco de seguridad, a la puerta 1")
walk({ V(-2850, 3112), V(-2850, 3115), V(-2790, 3115), V(-2780, 3135) }, "y a la puerta 2 (avioneta)")
walk({ V(-2800, 3115), V(-2730, 3115), V(-2730, 3095), V(-2745, 3088) }, "de las puertas a la sala de llegadas (salida de llegadas)")
walk({ V(-2745, 3088), V(-2780, 3070), V(-2780, 3042), V(-2650, 3042), V(-2391, 3020), V(-2391, 2700), V(-2391, 2640) }, "de la sala de llegadas a la calle por la carretera del aeropuerto")
walk({ V(-2780, 3071), V(-2727, 3071) }, "de la entrada a la barra de la cafetería")
walk({ V(-2850, 3042), V(-2965, 3042) }, "por la acera de la terminal hasta la parada de taxis")
walk({ V(2979, -4019), V(2975, -4028), V(2975, -4033) }, "en la isla: de la llegada al mostrador del aeródromo")
walk({ V(2979, -4019), V(2991, -3978) }, "en la isla: de la llegada a la puerta de embarque")

---------------------------------------------------------------------
print("▶ En el aire, por encima de todo")
local low = {}
for id, route in Airport.Routes do
	local t = 0
	while t <= route.Total do
		local p = Airport.pose(route, t).Position
		if p.Y > 20 then
			for _, b in tall do
				if p.X > b.Lo.X - 30 and p.X < b.Hi.X + 30 and p.Z > b.Lo.Z - 30 and p.Z < b.Hi.Z + 30 and b.Hi.Y > p.Y - 40 then
					low[b.Part:GetFullName()] = ("%s t=%.0f"):format(id, t)
				end
			end
		end
		t += 1
	end
end
local nLow = 0
for name, where in low do
	nLow += 1
	if nLow <= 6 then
		print(("    (%s) %s"):format(where, name))
	end
end
check(nLow == 0, "los aviones vuelan a más de 40 studs por encima de edificios, torres y grúas")

print("")
if failures == 0 then
	print("✅ Aeropuerto: todo correcto")
	process.exit(0)
end
print(("❌ %d comprobaciones fallidas"):format(failures))
process.exit(1)
