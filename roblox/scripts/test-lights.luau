-- Prueba de los semáforos (shared/TrafficSignals) y de cómo los respetan el tráfico
-- (client/Controllers/Traffic), los autobuses (BusService) y las patrullas (World/PoliceUnits),
-- con Lune, fuera de Roblox: una simulación sin cabeza de los cruces de la ciudad de verdad.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-lights.luau                (ciclo, cruces y simulación)
--   lune run scripts/test-lights.luau /tmp/x.rbxl     (además, los semáforos del mapa construido:
--       rojo build default.project.json -o /tmp/x.rbxl && lune run scripts/build-place.luau /tmp/x.rbxl)
--
-- Comprueba que:
--   * las fases nunca dan verde (ni ámbar) a las dos calles a la vez, hay un momento con las dos en
--     rojo, el ciclo sale solo de la hora (igual en todos los clientes y el servidor) y los peatones
--     solo cruzan cuando los coches de la calle que cruzan tienen rojo
--   * cada cruce de la cuadrícula es un nodo del grafo del tráfico con semáforo; (con el mapa) tiene
--     sus dos semáforos, uno para cada eje (así se ven desde todas las entradas), y se cargan enteros
--   * un coche que llega en rojo para antes de la línea (antes del paso de cebra) y sale en verde;
--     una cola de 3 no se monta; no entra si no hay sitio para salir; al girar a la izquierda cede
--     el paso al que viene de frente
--   * varios minutos de tráfico por la ciudad: nadie pasa la línea en rojo, nadie se monta en el de
--     delante y nunca hay coches de los dos ejes a la vez dentro de un cruce
--   * los autobuses y las patrullas (con la misma cuenta, TrafficSignals.gapAhead) tampoco pasan en
--     rojo; una patrulla con la sirena pasa, pero despacio

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

local TS = requireModule(sharedProxy.TrafficSignals)
local BusRoute = requireModule(sharedProxy.BusRoute)
local World = node("src/server/World", nil)
local Region = requireModule(World.Region)
local Roads = requireModule(World.Kit.Roads)

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
print("▶ Fases de los semáforos")
do
	local conflict, allRed, greenX, greenZ, walkBad = 0, 0, 0, 0, 0
	local n = 0
	for i = 0, TS.CYCLE * 2 * 20 - 1 do
		local t = 1000 + i / 20
		local x, z = TS.state("X", t), TS.state("Z", t)
		n += 1
		if x ~= "Red" and z ~= "Red" then
			conflict += 1
		end
		if x == "Red" and z == "Red" then
			allRed += 1
		end
		greenX += if x == "Green" then 1 else 0
		greenZ += if z == "Green" then 1 else 0
		-- Un peatón que camina a lo largo de X cruza la calle en Z: los coches en Z, en rojo
		if (TS.walk("X", t) and z ~= "Red") or (TS.walk("Z", t) and x ~= "Red") then
			walkBad += 1
		end
	end
	check(conflict == 0, "nunca hay verde ni ámbar en las dos calles a la vez")
	check(allRed > 0, ("hay un momento con las dos en rojo para vaciar el cruce (%.1f s por ciclo)"):format(allRed / 20 / 2))
	check(greenX == greenZ and greenX > 0, "las dos calles tienen el mismo tiempo de verde")
	check(walkBad == 0, "los peatones solo cruzan con los coches de la calle que cruzan en rojo")
	check(TS.state("X", 5) == TS.state("X", 5 + TS.CYCLE * 1000) and TS.state("Z", 20.3) == TS.state("Z", 20.3 + TS.CYCLE * 7), "el ciclo sale solo de la hora del servidor (igual para todos)")
	check(TS.mustStop("Red", 5, 30, 26) and not TS.mustStop("Red", -2, 30, 26), "en rojo para antes de la línea; si ya la ha pasado, sale del cruce")
	check(TS.mustStop("Yellow", 60, 30, 26) and not TS.mustStop("Yellow", 3, 40, 26) and not TS.mustStop("Green", 5, 30, 26), "en ámbar para si le da (lejos), si no, pasa")
end

---------------------------------------------------------------------
print("▶ Cruces con semáforo")
local street = Region.roads()
local roads = {}
for _, road in street do
	local a = if road.Axis == "X" then Vector3.new(road.From, 0, road.At) else Vector3.new(road.At, 0, road.From)
	local b = if road.Axis == "X" then Vector3.new(road.To, 0, road.At) else Vector3.new(road.At, 0, road.To)
	table.insert(roads, { A = a, B = b, Width = 24, Axis = road.Axis, At = road.At, From = road.From, To = road.To })
end
for _, s in Roads.segments() do
	table.insert(roads, { A = s.A, B = s.B, Width = Roads.Kinds[s.Kind].Road, Kind = s.Kind })
end
local crossings = TS.intersections(street)
local index = TS.index(crossings)
check(#crossings >= 100, ("%d cruces con semáforo en la cuadrícula de calles"):format(#crossings))
do
	local g = BusRoute.graph(roads, {})
	local matched = 0
	for _, c in crossings do
		for _, p in g.Nodes do
			if Vector3.new(p.X - c.X, 0, p.Z - c.Z).Magnitude < 6 then
				matched += 1
				break
			end
		end
	end
	check(matched == #crossings, ("cada cruce es un nodo del grafo del tráfico (%d de %d)"):format(matched, #crossings))
end

local placePath = process.args[1]
if placePath then
	print("  (mapa: " .. placePath .. ")")
	local game = roblox.deserializePlace(fs.readFile(placePath))
	local models = {}
	for _, d in game:GetService("Workspace"):GetDescendants() do
		if d:IsA("Model") and d:HasTag("TrafficLight") then
			table.insert(models, d)
		end
	end
	local byCrossing: { [Vector3]: { X: number, Z: number } } = {}
	local stray, atomic, complete = 0, 0, 0
	for _, m in models do
		local arm, box = m:FindFirstChild("Arm"), m:FindFirstChild("Box")
		local lamps = 0
		for _, c in m:GetChildren() do
			if c.Name == "Light" then
				lamps += 1
			end
		end
		if arm and box and lamps >= 3 then
			complete += 1
		end
		if m.ModelStreamingMode == roblox.Enum.ModelStreamingMode.Atomic then
			atomic += 1
		end
		if arm then
			local look = arm.CFrame.LookVector
			local axis = if math.abs(look.X) > math.abs(look.Z) then "Z" else "X" -- (como Traffic.addLight)
			local c = TS.near(index, arm.Position, 25)
			if c then
				byCrossing[c] = byCrossing[c] or { X = 0, Z = 0 }
				byCrossing[c][axis] += 1
			else
				stray += 1
			end
		end
	end
	local full = 0
	for _, c in crossings do
		local got = byCrossing[c]
		if got and got.X >= 1 and got.Z >= 1 then
			full += 1
		end
	end
	check(full == #crossings, ("cada cruce tiene semáforo para los dos ejes, con luces a los dos lados (%d de %d)"):format(full, #crossings))
	check(stray == 0, "ningún semáforo suelto lejos de un cruce")
	check(complete == #models, ("todos los semáforos tienen brazo, caja y luces (%d de %d)"):format(complete, #models))
	check(atomic == #models, "se cargan enteros en el cliente (Atomic: con StreamingEnabled llegaban sin luces)")
end

---------------------------------------------------------------------
-- El tráfico de verdad (Controllers/Traffic) con Roblox imitado
---------------------------------------------------------------------
local clock = 0 -- hora del servidor (y os.clock) de la simulación
local center = Vector3.new(0, 0, 0)

local function fakeInstance(props: { [string]: any }): any
	local attrs = props.Attrs or {}
	local obj = props
	function obj:GetAttribute(k)
		return attrs[k]
	end
	function obj:IsA(c)
		return c == obj.ClassName or (c == "BasePart" and obj.ClassName == "Part")
	end
	function obj:GetChildren()
		return obj.Children or {}
	end
	function obj:GetDescendants()
		return obj.Children or {}
	end
	function obj:FindFirstChild(name)
		for _, c in obj.Children or {} do
			if c.Name == name then
				return c
			end
		end
		return nil
	end
	obj.WaitForChild = obj.FindFirstChild
	return obj
end

local function template(name: string, kind: string?, size: Vector3): any
	local function build(): any
		local body = fakeInstance({ Name = "Body", ClassName = "Part", CFrame = CFrame.new(), Size = size, Transparency = 0 })
		local model = fakeInstance({ Name = name, ClassName = "Model", Children = { body }, Attrs = { Kind = kind } })
		function model:Clone()
			return build()
		end
		return model
	end
	return build()
end

local function loadTraffic(): any
	local configs = {}
	for i, r in roads do
		table.insert(configs, fakeInstance({ Name = "Road" .. i, ClassName = "Configuration", Attrs = { A = r.A, B = r.B, Width = r.Width, Kind = r.Kind, Axis = r.Axis, At = r.At, From = r.From, To = r.To } }))
	end
	local data = fakeInstance({
		Name = "Ambient",
		ClassName = "Folder",
		Children = {
			fakeInstance({ Name = "Roads", ClassName = "Folder", Children = configs }),
			fakeInstance({ Name = "Cars", ClassName = "Folder", Children = { template("Car1", nil, Vector3.new(6, 4, 13)), template("Car2", nil, Vector3.new(6, 4, 13)) } }),
			fakeInstance({ Name = "Riders", ClassName = "Folder", Children = { template("Moto", "Moto", Vector3.new(2, 4, 6)), template("Bici", "Bici", Vector3.new(2, 4, 5)) } }),
		},
	})
	local root = { Position = center }
	local character = { FindFirstChild = function(_, name)
		return if name == "HumanoidRootPart" then root else nil
	end }
	local localPlayer = { Character = character }
	local signalStub = { Connect = function() end }
	local services = {
		CollectionService = { GetTagged = function()
			return {}
		end, GetInstanceAddedSignal = function()
			return signalStub
		end },
		Lighting = { ClockTime = 12 },
		Players = { LocalPlayer = localPlayer, GetPlayers = function()
			return {}
		end },
		ReplicatedStorage = { Shared = sharedProxy },
	}
	local fakeWorkspace = {
		GetServerTimeNow = function()
			return clock
		end,
		BulkMoveTo = function() end,
		FindFirstChild = function()
			return nil
		end,
		GetAttribute = function()
			return nil
		end,
	}
	local uiProxy = { Perf = "Perf" }
	local path = "src/client/Controllers/Traffic.luau"
	local env = setmetatable({
		script = { Parent = { Parent = { UI = uiProxy }, Nudge = "Nudge" } },
		require = function(what)
			if what == "Perf" then
				return { count = function(n)
					return n
				end }
			elseif what == "Nudge" then
				return { say = function() end }
			end
			return requireModule(what)
		end,
		game = { GetService = function(_, name)
			return services[name] or {}
		end },
		workspace = fakeWorkspace,
		Instance = { new = function(class)
			return if class == "Folder" then {} else roblox.Instance.new(class)
		end },
		task = { spawn = function() end, wait = function() end },
		os = setmetatable({ clock = function()
			return clock
		end }, { __index = os }),
		Vector3 = Vector3,
		CFrame = CFrame,
		Color3 = Color3,
		Enum = roblox.Enum,
	}, { __index = getfenv(1) })
	local Traffic = luau.load(fs.readFile(path), { debugName = path, environment = env })()
	Traffic.init(data)
	return Traffic, root
end

math.randomseed(7)
local Traffic, playerRoot = loadTraffic()
local T = Traffic._test
local nodes, edges, lit = T.Nodes, T.Edges, T.LightNodes
local agents = Traffic._agents
local DT = 1 / 30

local litCount = 0
for _ in lit do
	litCount += 1
end
check(litCount == #crossings, ("el tráfico ve todos los cruces con semáforo (%d; antes, con StreamingEnabled, casi ninguno)"):format(litCount))

local function edgeOf(from: number, to: number): any
	for _, e in edges[from] do
		if e.To == to then
			return e
		end
	end
	return nil
end
local function axisOf(from: number, to: number): string
	return TS.axisOf(nodes[to] - nodes[from])
end
local function toLine(agent: any): number
	return T.EdgeLength(agent.From, agent.To) - TS.STOP_LINE - agent.S - agent.Length / 2
end
-- Primer instante (desde from) en que el eje tiene `state` al menos `need` segundos
local function timeWhen(axis: string, state: string, from: number, need: number): number
	local t = from
	while true do
		local ok = true
		for k = 0, need * 10 do
			if TS.state(axis, t + k / 10) ~= state then
				ok = false
				break
			end
		end
		if ok then
			return t
		end
		t += 0.1
	end
end

-- Un cruce con semáforo de 4 calles, con tramos largos: entrada (a → n), salida recta (n → b),
-- salida a la izquierda (n → l) y entrada de frente (o → n)
local scene
for id in lit do
	if #edges[id] == 4 then
		local p = nodes[id]
		for _, e in edges[id] do
			local a = e.To
			local d = (p - nodes[a]).Unit
			local straight, left, opposite = nil, nil, a
			for _, f in edges[id] do
				local d2 = (nodes[f.To] - p).Unit
				if d:Dot(d2) > 0.9 then
					straight = f.To
				elseif d.X * d2.Z - d.Z * d2.X < -0.9 then
					left = f.To
				end
			end
			if straight and left and e.Cost > 160 and T.EdgeLength(id, straight) > 160 and T.EdgeLength(id, left) > 100 then
				scene = { N = id, A = a, B = straight, Left = left }
				break
			end
		end
		if scene then
			break
		end
	end
end
check(scene ~= nil, "hay un cruce de 4 calles con semáforo para las pruebas")

-- Solo los coches de la escena (los demás, fuera)
local pool = {}
for _, a in agents do
	if a.Kind == "Car" then
		table.insert(pool, a)
	end
end
local function only(list: { any })
	for _, a in agents do
		T.SetActive(a, false)
	end
	table.clear(agents)
	for _, a in list do
		table.insert(agents, a)
	end
end
local function put(agent: any, from: number, to: number, nextNode: number, s: number, speed: number)
	agent.From, agent.To, agent.Next, agent.S = from, to, nextNode, s
	agent.Speed, agent.Cruise = speed, 30
	agent.Look, agent.StuckAt = nil, nil
	T.UpdateTurn(agent)
	T.SetActive(agent, true)
end
local function run(seconds: number, each: ((number) -> ())?)
	for i = 1, math.floor(seconds / DT) do
		clock += DT
		T.Step(DT, playerRoot.Position)
		if each then
			each(i)
		end
	end
end

if scene then
	local N, A, B = scene.N, scene.A, scene.B
	playerRoot.Position = nodes[N]
	local L = T.EdgeLength(A, N)
	local axis = axisOf(A, N)

	print("▶ Un coche llega en rojo")
	local car = pool[1]
	only({ car })
	clock = timeWhen(axis, "Red", 5000, 12)
	put(car, A, N, B, L - 130, 30)
	local crossedOnRed = false
	run(12, function()
		if car.To == N and toLine(car) <= -1 and TS.state(axis, clock) == "Red" then
			crossedOnRed = true
		end
	end)
	check(not crossedOnRed and car.To == N and toLine(car) > -1, ("para antes de la línea (a %.1f de la línea, a %.1f del centro del cruce)"):format(toLine(car), L - car.S - car.Length / 2))
	check(car.Speed < 0.5 and toLine(car) < 4, ("parado justo en la línea, antes del paso de cebra (velocidad %.1f)"):format(car.Speed))
	clock = timeWhen(axis, "Green", clock, 10)
	run(8)
	check(car.From == N or car.From == B, "en verde arranca y cruza")

	print("▶ Cola de 3 en rojo")
	local q = { pool[1], pool[2], pool[3] }
	only(q)
	clock = timeWhen(axis, "Red", clock, 14)
	put(q[1], A, N, B, L - 70, 28)
	put(q[2], A, N, B, L - 100, 28)
	put(q[3], A, N, B, L - 130, 28)
	local minGap, onRed = math.huge, false
	local function watch()
		for i = 1, 2 do
			local x, y = q[i], q[i + 1]
			if x.From == y.From and x.To == y.To then
				minGap = math.min(minGap, x.S - y.S - (x.Length + y.Length) / 2)
			end
		end
		for _, c in q do
			if c.To == N and c.From == A and toLine(c) <= -1 and TS.state(axis, clock) == "Red" then
				onRed = true
			end
		end
	end
	run(13, watch)
	check(minGap > 0.5, ("no se montan: el hueco más pequeño entre dos es %.1f studs"):format(minGap))
	check(not onRed and q[1].Speed < 0.5 and q[3].Speed < 0.5, "los 3 parados antes de la línea, en fila")
	clock = timeWhen(axis, "Green", clock, 12)
	run(12, watch)
	local through = 0
	for _, c in q do
		if c.From ~= A then
			through += 1
		end
	end
	check(minGap > 0.5 and through == 3, ("en verde salen los 3 sin tocarse (%d han cruzado)"):format(through))

	print("▶ No se queda dentro del cruce")
	local blocker, car2 = pool[4], pool[5]
	only({ blocker, car2 })
	clock = timeWhen(axis, "Green", clock + 40, 12)
	local after = nil
	for _, e in edges[B] do
		if e.To ~= N then
			after = e.To
		end
	end
	put(blocker, N, B, after or N, 16, 0)
	blocker.Cruise = 0
	put(car2, A, N, B, L - 90, 28)
	local entered = false
	run(10, function()
		blocker.Speed = 0
		if car2.To == N and toLine(car2) <= -1 then
			entered = true
		end
	end)
	check(not entered and car2.Speed < 0.5, ("con un coche parado a la salida espera en la línea (en verde) sin meterse (a %.1f)"):format(toLine(car2)))

	print("▶ Girar a la izquierda: cede el paso al que viene de frente")
	local turner, other = pool[6], pool[7]
	only({ turner, other })
	-- De frente: entra desde el otro lado (o → n) y sigue recto (n → a)
	clock = timeWhen(axis, "Green", clock + 40, 12)
	put(turner, A, N, scene.Left, L - 45, 20)
	put(other, B, N, A, T.EdgeLength(B, N) - 75, 30)
	check(turner.Turn == -1 and other.Turn == 0, "(uno gira a la izquierda y el otro va recto)")
	local turnerCrossedFirst = false
	local otherPassed = false
	run(8, function()
		if not otherPassed and other.To ~= N then
			otherPassed = true
		end
		if not otherPassed and turner.To == N and toLine(turner) <= -1 then
			turnerCrossedFirst = true
		end
	end)
	check(otherPassed and not turnerCrossedFirst, "espera a que pase el de frente y luego gira")
	check(turner.From == N or turner.To ~= N, "y después gira")
end

---------------------------------------------------------------------
print("▶ Minutos de tráfico por la ciudad")
do
	math.randomseed(11)
	local Traffic2, root2 = loadTraffic()
	local T2 = Traffic2._test
	local list = Traffic2._agents
	local places = { Vector3.new(-100, 0, -100), Vector3.new(700, 0, -2000), Vector3.new(-600, 0, 2300) }
	local onRed, overlaps, conflicts, crossingsSeen, amber = 0, 0, 0, 0, 0
	local maxStill = 0
	local prev: { [any]: { From: number, To: number, Line: number } } = {}
	local still: { [any]: number } = {}
	local worst = ""
	for _, place in places do
		root2.Position = place
		for _, a in list do
			T2.SetActive(a, false)
			prev[a] = nil
			still[a] = nil
		end
		for i = 1, math.floor(100 / DT) do
			clock += DT
			T2.Step(DT, place)
			if i < 60 then
				continue -- (que se coloquen)
			end
			local inBox: { [number]: { X: boolean?, Z: boolean? } } = {}
			for _, a in list do
				if not a.Active then
					prev[a] = nil
					continue
				end
				local L = T2.EdgeLength(a.From, a.To)
				local line = L - TS.STOP_LINE - a.S - a.Length / 2
				local p = prev[a]
				local ax = TS.axisOf(nodes[a.To] - nodes[a.From])
				if lit[a.To] and p and p.From == a.From and p.To == a.To and p.Line > -1 and line <= -1 then
					crossingsSeen += 1
					local st = TS.state(ax, clock)
					if st == "Red" then
						onRed += 1
						worst = ("%s a %.1f studs/s en el nodo %d"):format(a.Kind, a.Speed, a.To)
					elseif st == "Yellow" then
						amber += 1
					end
				end
				prev[a] = { From = a.From, To = a.To, Line = line }
				-- Dentro de la calzada del cruce (a menos de 12 del centro, entrando)
				if lit[a.To] and L - a.S < 12 + a.Length / 2 and L - a.S > -12 then
					inBox[a.To] = inBox[a.To] or {}
					inBox[a.To][ax] = true
				end
				if a.Speed < 0.5 then
					still[a] = (still[a] or 0) + DT
					maxStill = math.max(maxStill, still[a])
				else
					still[a] = 0
				end
			end
			for _, b in inBox do
				if b.X and b.Z then
					conflicts += 1
				end
			end
			-- Montados: dos en el mismo tramo y carril, más cerca que sus largos
			if i % 10 == 0 then
				for x = 1, #list do
					local a = list[x]
					if a.Active then
						for y = x + 1, #list do
							local b = list[y]
							if b.Active and b.From == a.From and b.To == a.To and a.Small == b.Small and math.abs(a.S - b.S) < (a.Length + b.Length) / 2 - 0.5 then
								overlaps += 1
							end
						end
					end
				end
			end
		end
	end
	print(("  (%d pasos de línea con semáforo: %d en ámbar; el que más tiempo lleva parado, %.0f s)"):format(crossingsSeen, amber, maxStill))
	check(crossingsSeen > 50, "el tráfico circula y cruza (no se queda atascado)")
	check(onRed == 0, ("nadie pasa la línea en rojo (%d)%s"):format(onRed, if worst ~= "" then " — p. ej. " .. worst else ""))
	check(overlaps == 0, ("nadie se monta en el de delante (%d)"):format(overlaps))
	check(conflicts == 0, ("nunca hay coches de las dos calles a la vez dentro del cruce (%d fotogramas)"):format(conflicts))
	check(maxStill < 90, "nadie se queda parado para siempre (sin bloqueos)")
end

---------------------------------------------------------------------
print("▶ Autobuses y patrullas (TrafficSignals.gapAhead, como BusService y PoliceUnits)")
local function busSource(path: string): string
	return fs.readFile(path)
end
check(string.find(busSource("src/server/Services/BusService.luau"), "TrafficSignals.gapAhead", 1, true) ~= nil and string.find(busSource("src/server/Services/BusService.luau"), "TrafficSignals.fromFolder", 1, true) ~= nil, "BusService para con TrafficSignals (todos los cruces de su calle)")
check(string.find(busSource("src/server/World/PoliceUnits.luau"), "TrafficSignals.gapAhead", 1, true) ~= nil, "PoliceUnits para con TrafficSignals")

-- Un vehículo que va y viene por una calle larga de la cuadrícula (con varios cruces), frenando con
-- la cuenta del servidor: objetivo = min(crucero, raíz(2·frenada·hueco))
local function drive(name: string, halfLen: number, cruise: number, accel: number, brake: number, siren: boolean): (number, number, number)
	local best, bestCount = nil, 0
	for _, r in street do
		local count = 0
		for _, c in crossings do
			local on = if r.Axis == "X" then math.abs(c.Z - r.At) < 1 and c.X > r.From and c.X < r.To else math.abs(c.X - r.At) < 1 and c.Z > r.From and c.Z < r.To
			if on then
				count += 1
			end
		end
		if count > bestCount then
			best, bestCount = r, count
		end
	end
	local r = best
	local dir = if r.Axis == "X" then Vector3.new(1, 0, 0) else Vector3.new(0, 0, 1)
	local s, sign, speed = r.From + 10, 1, 0
	local passedOnRed, passes, maxRedSpeed = 0, 0, 0
	local t0 = clock
	while clock - t0 < 300 do
		clock += DT
		local d = dir * sign
		local lane = Vector3.new(-d.Z, 0, d.X) * 6
		local pos = (if r.Axis == "X" then Vector3.new(s, 0, r.At) else Vector3.new(r.At, 0, s)) + lane
		local gap = TS.gapAhead(index, pos, d, halfLen, speed, brake, clock)
		if siren and gap < math.huge then
			gap = math.max(gap, 12 * 12 / (2 * brake) + 1.5)
		end
		local target = math.min(cruise, if gap == math.huge then math.huge else math.sqrt(2 * brake * math.max(gap - 1.5, 0)))
		speed = if speed < target then math.min(target, speed + accel * DT) else math.max(target, speed - brake * 2 * DT)
		local before = s
		s += sign * speed * DT
		-- ¿Ha pasado alguna línea de parada?
		for _, c in crossings do
			local along = if r.Axis == "X" then c.X else c.Z
			local off = if r.Axis == "X" then c.Z - r.At else c.X - r.At
			if math.abs(off) < 1 then
				local line = along - sign * (TS.STOP_LINE + halfLen) -- (donde está el centro al llegar el morro a la línea)
				if (before - line) * sign < 0 and (s - line) * sign >= 0 then
					passes += 1
					if TS.state(TS.axisOf(d), clock) == "Red" then
						passedOnRed += 1
						maxRedSpeed = math.max(maxRedSpeed, speed)
					end
				end
			end
		end
		-- (al final de la calle da la vuelta: parado)
		if s > r.To - 10 and sign > 0 then
			sign, speed = -1, 0
		elseif s < r.From + 10 and sign < 0 then
			sign, speed = 1, 0
		end
	end
	print(("  (%s: %d cruces pasados en 5 min por una calle con %d semáforos)"):format(name, passes, bestCount))
	return passedOnRed, passes, maxRedSpeed
end
do
	local red, passes = drive("autobús", 17, 40, 10, 9, false)
	check(passes > 10 and red == 0, ("los autobuses paran en rojo (%d en rojo de %d)"):format(red, passes))
	red, passes = drive("patrulla", 7, 24, 14, 26, false)
	check(passes > 10 and red == 0, ("las patrullas paran en rojo (%d en rojo de %d)"):format(red, passes))
	local sirenRed, _, sirenSpeed = drive("patrulla con sirena", 7, 24, 14, 26, true)
	check(sirenRed > 0 and sirenSpeed <= 13, ("con la sirena pasa en rojo, pero despacio (a %.1f studs/s como mucho)"):format(sirenSpeed))
end

---------------------------------------------------------------------
print("▶ Peatones (Traffic.mayCross)")
do
	local c = crossings[1]
	local bad = 0
	for k = 0, TS.CYCLE * 10 do
		clock = 9000 + k / 10
		for _, dir in { Vector3.new(1, 0, 0), Vector3.new(0, 0, 1) } do
			if Traffic.mayCross(c, dir) then
				local crossingAxis = if dir.X ~= 0 then "Z" else "X" -- (la calle que cruza)
				if TS.state(crossingAxis, clock) ~= "Red" then
					bad += 1
				end
			end
		end
	end
	check(bad == 0, "en un cruce con semáforo, solo cruzan con los coches de esa calle en rojo")
end

print()
if failures > 0 then
	print(("❌ %d comprobaciones fallan"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
