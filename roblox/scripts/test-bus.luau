-- Prueba de la red de autobuses urbanos (shared/BusLines) con Lune, fuera de Roblox.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-bus.luau                       (tiempos de llegada y recorridos)
--   lune run scripts/test-bus.luau RealLifeSimulator.rbxl  (además, las marquesinas del mapa construido)
--
-- Comprueba que:
--   * el tiempo de llegada (BusLines.eta) cuenta la distancia, las paradas intermedias y la espera,
--     y baja a medida que el autobús se acerca
--   * las líneas van por las calles de verdad, sin dar media vuelta, y cada parada está en su recorrido,
--     en la acera de la derecha, lejos de los cruces y nunca en la autovía
--   * hay entre 40 y 60 paradas, todos los distritos tienen parada, y hay paradas junto al hospital,
--     los colegios, las casas de Los Pinos, las estaciones de metro, la playa, el centro comercial y el puerto
--   * (con el mapa) cada parada tiene su marquesina con poste y panel, y nada sólido se le mete dentro

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Vector3, CFrame, Color3 = roblox.Vector3, roblox.CFrame, roblox.Color3

---------------------------------------------------------------------
-- Cargador: módulos de src/shared y de src/server/World (solo datos, sin construir nada)
---------------------------------------------------------------------
local sharedProxy = setmetatable({}, {
	__index = function(_, name)
		return { __path = "src/shared/" .. name .. ".luau" }
	end,
})
local fakeGame = {
	GetService = function(_, name)
		if name == "ReplicatedStorage" then
			return { Shared = sharedProxy }
		end
		return setmetatable({}, { __index = function() return nil end })
	end,
}
local cache = {}
local requireModule
-- Árbol de carpetas leído por adelantado (Lune no deja esperar dentro de __index)
local function node(path: string, parent: any?): any
	local self = { __path = path, Parent = parent }
	if fs.isDir(path) then
		for _, name in fs.readDir(path) do
			local child = path .. "/" .. name
			if fs.isDir(child) then
				self[name] = node(child, self)
			elseif name:match("%.luau$") then
				self[(name:gsub("%.luau$", ""))] = node(child, self)
			end
		end
	end
	return self
end
function requireModule(target: any): any
	local path = rawget(target, "__path")
	if cache[path] ~= nil then
		return cache[path]
	end
	local env = setmetatable({
		script = target,
		require = requireModule,
		game = fakeGame,
		workspace = {},
		Instance = roblox.Instance,
		Vector3 = Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrame,
		Color3 = Color3,
		Enum = roblox.Enum,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Font = roblox.Font,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		ColorSequence = roblox.ColorSequence,
	}, { __index = getfenv(1) })
	local result = luau.load(fs.readFile(path), { debugName = path, environment = env })()
	cache[path] = result
	return result
end

local BusLines = requireModule(sharedProxy.BusLines)
local CityPlan = requireModule(sharedProxy.CityPlan)
local World = node("src/server/World", nil)
local BusStops = requireModule(World.Kit.BusStops)

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

---------------------------------------------------------------------
print("▶ Tiempos de llegada")
local stopsS = { 0, 200, 400, 700 }
check(BusLines.eta(1000, 100, 400, stopsS, 10, 5) == 35, "300 studs a 10 studs/s y una parada intermedia de 5 s: 35 s")
check(BusLines.eta(1000, 900, 100, stopsS, 10, 5) == 25, "da la vuelta a la línea (pasa por la cabecera): 25 s")
check(BusLines.eta(1000, 400, 400, stopsS, 10, 5, 3) == 3, "parado en la parada: lo que le queda de espera")
check(BusLines.eta(1000, 401, 400, stopsS, 10, 5) > 100, "recién salido de la parada: le toca dar la vuelta entera")
local decreasing, last = true, math.huge
for s = 410, 1390, 20 do
	local e = BusLines.eta(1000, s % 1000, 400, stopsS, 10, 5)
	if e > last then
		decreasing = false
	end
	last = e
end
check(decreasing, "el tiempo baja siempre a medida que el autobús se acerca")
check(BusLines.formatEta(0, true) == "En parada" and BusLines.formatEta(12) == "Llegando" and BusLines.formatEta(170) == "3 min" and BusLines.formatEta(45) == "1 min", "textos del panel: En parada, Llegando, N min")
local board = { { Line = "L2", Headsign = "Valmar Norte", Seconds = 180, AtStop = false }, { Line = "L1", Headsign = "Playa Dorada", Seconds = 0, AtStop = true } }
local decoded = BusLines.decodeBoard(BusLines.encodeBoard(board))
check(#decoded == 2 and decoded[1].Line == "L2" and decoded[1].Seconds == 180 and decoded[2].AtStop == true and decoded[2].Headsign == "Playa Dorada", "el panel viaja en un texto y se lee igual")
check(BusLines.boardText(decoded[1]) == "L2 → Valmar Norte · 3 min" and BusLines.boardText(decoded[2]) == "L1 → Playa Dorada · En parada", "línea del panel: «L2 → Valmar Norte · 3 min»")

---------------------------------------------------------------------
print("▶ Líneas sobre las calles de Valmar")
local roads = BusStops.roads()
local t0 = os.clock()
local plan = BusLines.plan(roads)
print(("  (plan en %.2f s)"):format(os.clock() - t0))
check(#plan.Lines == #BusLines.Lines and #plan.Lines >= 5, ("hay %d líneas"):format(#plan.Lines))
check(#plan.Order >= 40 and #plan.Order <= 60, ("hay %d paradas (entre 40 y 60)"):format(#plan.Order))
local again = BusLines.plan(roads)
local same = #again.Order == #plan.Order
for _, id in plan.Order do
	same = same and again.Stops[id] ~= nil and (again.Stops[id].Center - plan.Stops[id].Center).Magnitude < 0.01
end
check(same, "el plan sale igual cada vez (servidor y mapa coinciden)")

-- Cruces: puntos donde se juntan o cortan calles
local junctions = {}
for i, r in roads do
	table.insert(junctions, r.A)
	table.insert(junctions, r.B)
	for j = i + 1, #roads do
		local o = roads[j]
		local rr, s = r.B - r.A, o.B - o.A
		local den = rr.X * s.Z - rr.Z * s.X
		if math.abs(den) > 1e-6 then
			local t = ((o.A.X - r.A.X) * s.Z - (o.A.Z - r.A.Z) * s.X) / den
			local u = ((o.A.X - r.A.X) * rr.Z - (o.A.Z - r.A.Z) * rr.X) / den
			if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
				table.insert(junctions, r.A + rr * t)
			end
		end
	end
end

for _, line in plan.Lines do
	local n = #line.Route
	local uturns = 0
	for i = 1, n do
		local a, b, c = line.Route[if i > 1 then i - 1 else n], line.Route[i], line.Route[i % n + 1]
		local d1, d2 = b - a, c - b
		if d1.Magnitude > 0.5 and d2.Magnitude > 0.5 and d1.Unit:Dot(d2.Unit) < -0.8 then
			uturns += 1
		end
	end
	local onRoute, rightSide, farFromJunction, sidewalk = true, true, true, true
	local maxGap = 0
	for k, s in line.Stops do
		local info = plan.Stops[s.Id]
		local p, dir = BusLines.pointAt(line, s.S)
		local lanePoint = info.Center + info.Right * BusLines.Lane
		onRoute = onRoute and (Vector3.new(p.X, 0, p.Z) - lanePoint).Magnitude < 2
		rightSide = rightSide and info.Right:Dot(Vector3.new(-dir.Z, 0, dir.X)) > 0.9
		local near = math.huge
		for _, q in junctions do
			near = math.min(near, (Vector3.new(q.X, 0, q.Z) - info.Center).Magnitude)
		end
		farFromJunction = farFromJunction and near >= 40
		sidewalk = sidewalk and info.Walk > 0
		local nextS = line.Stops[k % #line.Stops + 1].S
		maxGap = math.max(maxGap, (nextS - s.S) % line.Total)
	end
	check(uturns == 0, ("%s: sin medias vueltas (%d studs de recorrido)"):format(line.Id, math.floor(line.Total)))
	check(#line.Stops >= 8 and onRoute and rightSide, ("%s: sus %d paradas están en su recorrido, a la derecha"):format(line.Id, #line.Stops))
	check(farFromJunction and sidewalk, ("%s: paradas con acera y lejos de los cruces"):format(line.Id))
	check(maxGap < 3600, ("%s: nunca más de 3600 studs entre paradas (máx. %d)"):format(line.Id, math.floor(maxGap)))
	local every = line.Total / 40 / math.max(1, line.Buses) -- (a 40 studs/s, sin contar las paradas)
	check(line.Buses >= 2 and every < 240, ("%s: %d autobuses, pasa uno cada %.1f min"):format(line.Id, line.Buses, every / 60))
end

local districts = {}
for _, id in plan.Order do
	local c = plan.Stops[id].Center
	local d = CityPlan.districtAt(c.X, c.Z)
	if d then
		districts[d.Id] = true
	end
end
local allDistricts = true
for _, d in CityPlan.Districts do
	if not districts[d.Id] then
		allDistricts = false
		print("    (sin parada: " .. d.Name .. ")")
	end
end
check(allDistricts, "todos los distritos tienen parada")

local function stopNear(x: number, z: number, radius: number): boolean
	for _, id in plan.Order do
		local c = plan.Stops[id].Shelter
		if (Vector3.new(c.X, 0, c.Z) - Vector3.new(x, 0, z)).Magnitude < radius then
			return true
		end
	end
	return false
end
local places = {
	{ "Hospital (Valmar Norte)", -820, -2020 },
	{ "Colegio de Valmar Norte", -820, -1780 },
	{ "Colegio de Los Pinos", 580, -2020 },
	{ "Casas familiares de Los Pinos", 700, -2210 },
	{ "Colegio de San Roque", -530, 2370 },
	{ "Colegio de Villaverde", -2580, -1970 },
	{ "Colegio del Campus", 2770, 1610 },
	{ "Playa Dorada (la arena)", 3860, -900 },
	{ "Centro comercial de Los Pinos", 820, -1780 },
	{ "Puerto de mercancías", 700, 3300 },
	{ "Plaza Mayor", -100, -100 },
}
for _, station in { "Poniente", "PlazaMayor", "Levante", "PlayaDorada", "Norte", "SanRoque", "Puerto" } do
	local Metro = requireModule(sharedProxy.Metro)
	local st = Metro.Stations[station]
	table.insert(places, { "Metro " .. st.Name, st.Surface[1], st.Surface[2] })
end
for _, p in places do
	check(stopNear(p[2], p[3], 260), "parada cerca de: " .. p[1])
end

---------------------------------------------------------------------
print("▶ Subir y bajar del autobús")
do
	local svc = fs.readFile("src/server/Services/BusService.luau")
	check(svc:find("RideState.downed(player)", 1, true) ~= nil, "K.O., caído o muerto no se sube al autobús")
	local at = string.find(svc, "local function exitCFrame", 1, true) or 0
	local body = string.sub(svc, at, at + 2600)
	check(body:find("BusService.exitClear(", 1, true) ~= nil and body:find("-(HALF_W + 3)", 1, true) ~= nil and body:find("rear + 3", 1, true) ~= nil,
		"fuera de una parada se baja por la puerta si no hay pared; si no, por el otro lado o por detrás")
	check(svc:find("function BusService.exitClear", 1, true) ~= nil and svc:find("GetPartBoundsInBox(CFrame.new(to", 1, true) ~= nil, "se mira con un rayo y una caja que ahí no hay nada sólido")
end

---------------------------------------------------------------------
local placePath = process.args[1]
if placePath then
	print("▶ Marquesinas en el mapa construido (" .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local town = game:GetService("Workspace"):FindFirstChild("Town")
	local shelters, signs = {}, {}
	for _, d in town:GetDescendants() do
		if d:IsA("Model") and d.Name == "ParadaBus" then
			table.insert(shelters, d)
		elseif d:IsA("BasePart") and d.Name == "BusStopSign" then
			table.insert(signs, d)
		end
	end
	check(#shelters == #plan.Order, ("hay %d marquesinas (una por parada)"):format(#shelters))
	local complete = true
	local parts = 0
	for _, m in shelters do
		local sign = m:FindFirstChild("BusStopSign")
		complete = complete
			and sign ~= nil
			and m:FindFirstChild("EtaBoard") ~= nil
			and m:FindFirstChild("Roof") ~= nil
			and m:FindFirstChild("Seat") ~= nil
			and m:FindFirstChild("LineMap") ~= nil
			and m:FindFirstChild("AdPanel") ~= nil
			and typeof(sign:GetAttribute("StopPoint")) == "Vector3"
			and plan.Stops[sign:GetAttribute("StopId")] ~= nil
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				parts += 1
			end
		end
	end
	check(complete, "cada marquesina tiene techo, banco, anuncio, plano, panel de llegadas y poste con su parada")
	-- Las que se han corrido por la acera (por una farola, un árbol…): nunca más de 36 studs
	local moved, farthest = 0, 0
	for _, sign in signs do
		local info = plan.Stops[sign:GetAttribute("StopId")]
		local point = sign:GetAttribute("StopPoint")
		if info and typeof(point) == "Vector3" then
			local shift = (Vector3.new(point.X, 0, point.Z) - (info.Center + info.Right * BusLines.Lane)).Magnitude
			if shift > 0.5 then
				moved += 1
			end
			farthest = math.max(farthest, shift)
		end
	end
	check(farthest <= 36.5, ("%d marquesinas corridas por la acera para no pisar nada (máx. %d studs)"):format(moved, math.floor(farthest + 0.5)))
	check(parts <= #shelters * 14, ("pocas piezas: %d en total (%.1f por parada)"):format(parts, parts / math.max(1, #shelters)))
	-- Nada sólido (farolas, árboles, bancos…) metido dentro de una marquesina
	local boxes = {}
	for _, m in shelters do
		local body = m:FindFirstChild("BackGlass")
		local roof = m:FindFirstChild("Roof")
		if body and roof then
			local cf = roof.CFrame * CFrame.new(0, -8.3, -0.2) -- base de la marquesina (a ras de acera)
			table.insert(boxes, { Model = m, CFrame = cf })
		end
	end
	local clashes = 0
	for _, d in town:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.95 and d.CanCollide then
			local owner = d:FindFirstAncestorOfClass("Model")
			local p = d.CFrame.Position
			for _, b in boxes do
				if owner ~= b.Model and (p - b.CFrame.Position).Magnitude < 12 then
					local l = b.CFrame:PointToObjectSpace(p)
					if math.abs(l.X) < 5.8 and l.Y > 0.6 and l.Y < 8 and math.abs(l.Z) < 2 then
						clashes += 1
						print(("    (%s dentro de la marquesina %s)"):format(d:GetFullName(), b.Model:GetAttribute("StopId") or "?"))
					end
				end
			end
		end
	end
	check(clashes == 0, "ninguna pieza sólida se mete en una marquesina")
end

print(if failures == 0 then "\nTodo bien ✅" else ("\n%d fallos ❌"):format(failures))
process.exit(if failures == 0 then 0 else 1)
