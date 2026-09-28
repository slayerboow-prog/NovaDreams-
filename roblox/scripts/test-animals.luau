-- Prueba de cómo se mueven los animales (Controllers/AnimalPose) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-animals.luau
--
-- Comprueba que:
--   * de pie y andando, las patas tocan el suelo (ni flotan ni se hunden)
--   * los de cuatro patas andan en diagonal (delantera de un lado con trasera del otro)
--   * sentado o tumbado, el cuerpo baja hasta el suelo sin atravesarlo
--   * la vaca y la oveja llegan a la hierba al pastar; las aves, al picotear
--   * el pato mete la cabeza en el agua
--   * todo se mueve suave, sin tirones
--   * el susto (salto, cabeza y cola arriba, aleteo) da números normales y el animal vuelve al suelo
--   * los animales sueltos no van por la calzada: con las calles de verdad del mapa (Kit/Roads y las
--     de los barrios), ningún sitio al que deciden ir (ni al huir) cae en la calzada ni cruza la calle,
--     y las vacas, ovejas y gallinas no se alejan de su granja

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local env = setmetatable({
	CFrame = roblox.CFrame, Vector3 = roblox.Vector3, Color3 = roblox.Color3, Enum = roblox.Enum, Instance = roblox.Instance,
}, { __index = getfenv(1) })
local AnimalPose = luau.load(fs.readFile("src/client/Controllers/AnimalPose.luau"), { debugName = "AnimalPose", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Lo más bajo de una pieza colocada
local function bottom(frame, size)
	local h = size / 2
	local low = math.huge
	for _, x in { -h.X, h.X } do
		for _, y in { -h.Y, h.Y } do
			for _, z in { -h.Z, h.Z } do
				low = math.min(low, (frame * roblox.Vector3.new(x, y, z)).Y)
			end
		end
	end
	return low
end

local function posed(kind, setup, t)
	local pieces, info = AnimalPose.build(kind)
	local s = AnimalPose.newState(kind)
	s.Phase = 0
	setup(s)
	-- Dejar que las posturas lleguen (van suaves)
	for _ = 1, 240 do
		AnimalPose.step(s, 1 / 60, AnimalPose.WalkSpeed[kind] or 2, nil, false)
	end
	local out = {}
	AnimalPose.pose(pieces, info, s, t or 0, out)
	return pieces, info, s, out
end

-- Lo más bajo de las piezas con ese rol (o de todas)
local function lowest(pieces, out, filter)
	local low = math.huge
	for i, p in pieces do
		if not filter or filter(p) then
			low = math.min(low, bottom(out[i], p.Part.Size))
		end
	end
	return low
end
local function isLeg(p)
	return p.Role ~= nil and p.Role:sub(1, 3) == "Leg"
end
local function isHead(p)
	return p.Role == "Head"
end

local WALKERS = { "Perro", "Gato", "Vaca", "Oveja", "Gallina", "Paloma" }

print("De pie y andando")
for _, kind in WALKERS do
	local ground = -AnimalPose.Stand[kind]
	local pieces, _, _, out = posed(kind, function(s)
		s.Action = "stand"
	end)
	local feet = lowest(pieces, out, isLeg)
	check(math.abs(feet - ground) < 0.2, kind .. ": de pie, las patas tocan el suelo")
	local s2 = AnimalPose.newState(kind)
	local p2, info2 = AnimalPose.build(kind)
	s2.State = "walk"
	local through, floating = false, false
	for step = 0, 120 do
		AnimalPose.step(s2, 1 / 60, AnimalPose.WalkSpeed[kind], nil, false)
		local o = {}
		AnimalPose.pose(p2, info2, s2, step / 60, o)
		local low = lowest(p2, o, isLeg)
		if low < ground - 0.25 then
			through = true
		end
		if low > ground + 0.3 then
			floating = true
		end
	end
	check(not through and not floating, kind .. ": andando, pisa el suelo")
end

print("Andar en diagonal")
for _, kind in { "Perro", "Gato", "Vaca", "Oveja" } do
	local pieces, info = AnimalPose.build(kind)
	local s = AnimalPose.newState(kind)
	s.State = "walk"
	s.Stride = math.pi / 2 - 0.01 -- a mitad de paso
	s.Moving = 1
	local out = {}
	AnimalPose.pose(pieces, info, s, 0, out)
	local feet = {}
	for i, p in pieces do
		if isLeg(p) then
			local n = tonumber(p.Role:sub(4))
			feet[n] = (out[i] * roblox.CFrame.new(0, -p.Part.Size.Y / 2, 0)).Position.Z - p.Offset.Position.Z
		end
	end
	local diagonal = (feet[1] > 0) == (feet[4] > 0) and (feet[2] > 0) == (feet[3] > 0) and (feet[1] > 0) ~= (feet[2] > 0)
	check(diagonal, kind .. ": delantera izquierda con trasera derecha")
end

print("Sentarse, tumbarse, pastar, picotear")
for _, kind in { "Perro", "Gato" } do
	local ground = -AnimalPose.Stand[kind]
	local pieces, _, _, out = posed(kind, function(s)
		s.Action = "sit"
	end)
	local low = lowest(pieces, out)
	check(low > ground - 0.25 and low < ground + 0.25, kind .. ": sentado, apoyado en el suelo")
	local frontFeet = lowest(pieces, out, function(p)
		return p.Role == "Leg1" or p.Role == "Leg2"
	end)
	check(frontFeet < ground + 0.35, kind .. ": sentado, las patas delanteras en el suelo")
end
do
	local ground = -AnimalPose.Stand.Gato
	local pieces, _, _, out = posed("Gato", function(s)
		s.Action = "lie"
	end)
	local low = lowest(pieces, out)
	check(low > ground - 0.25 and low < ground + 0.25, "Gato: tumbado en el suelo")
end
for _, kind in { "Vaca", "Oveja" } do
	local ground = -AnimalPose.Stand[kind]
	local pieces, _, _, out = posed(kind, function(s)
		s.Action = "graze"
	end)
	local head = lowest(pieces, out, isHead)
	check(head < ground + 0.6 and head > ground - 0.3, kind .. ": al pastar, la boca llega a la hierba")
end
for _, kind in { "Gallina", "Paloma" } do
	local ground = -AnimalPose.Stand[kind]
	-- en lo más bajo del picotazo
	local pieces, _, _, out = posed(kind, function(s)
		s.Action = "peck"
	end, math.pi / 2 / 3)
	local head = lowest(pieces, out, isHead)
	check(head < ground + 0.45, kind .. ": al picotear, el pico llega al suelo")
end
do
	local pieces, _, _, out = posed("Pato", function(s)
		s.State = "float"
		s.Action = "dabble"
	end)
	local head = lowest(pieces, out, isHead)
	check(head < -AnimalPose.Stand.Pato - 0.1, "Pato: mete la cabeza en el agua")
end

print("Suave, sin tirones")
for _, kind in { "Perro", "Gato", "Vaca", "Oveja", "Gallina", "Paloma", "Pato", "Pajaro", "Mariposa" } do
	local pieces, info = AnimalPose.build(kind)
	local s = AnimalPose.newState(kind)
	local before = nil
	local jumpy = false
	local actions = AnimalPose.Actions[kind] or { "stand" }
	for step = 0, 1800 do
		local t = step / 60
		-- Cambia de cosa cada pocos segundos, como en el juego
		if step % 240 == 0 then
			s.State = if (step // 240) % 3 == 0 then "walk" else (if kind == "Pato" then "float" else "idle")
			s.Action = actions[(step // 240) % #actions + 1]
		end
		AnimalPose.step(s, 1 / 60, AnimalPose.WalkSpeed[kind] or 2, math.sin(t) * 0.5, step % 600 < 300)
		local out = {}
		AnimalPose.pose(pieces, info, s, t, out)
		if before then
			for i, cf in out do
				-- las alas aletean rápido a propósito
				local role = pieces[i].Role
				if role ~= "WingL" and role ~= "WingR" and (cf.Position - before[i].Position).Magnitude > 0.2 then
					jumpy = true
				end
			end
		end
		before = out
	end
	check(not jumpy, kind .. ": sin saltos de un fotograma al siguiente")
end


print("Susto al pasar a su lado")
for _, kind in { "Perro", "Gato", "Vaca", "Oveja", "Gallina", "Paloma", "Pato" } do
	local finite, peak = true, 0
	for i = 0, 50 do
		local r = AnimalPose.reaction(kind, 1 - i / 50)
		for _, v in r do
			if v ~= v or math.abs(v) > 3 then
				finite = false
			end
		end
		peak = math.max(peak, r.Hop)
	end
	local rest = AnimalPose.reaction(kind, 0)
	check(finite, kind .. ": el susto da números normales")
	check(peak > 0.2, kind .. (": pega un salto al asustarse (%.2f studs)"):format(peak))
	check(rest.Hop == 0 and rest.TailUp == 0 and rest.HeadPitch == 0, kind .. ": pasado el susto vuelve a como estaba")
	-- Durante el susto, las patas nunca se meten bajo el suelo y el cuerpo sube
	if kind ~= "Pato" then
		local pieces, info = AnimalPose.build(kind)
		local st = AnimalPose.newState(kind)
		st.Action = "stand"
		for _ = 1, 120 do
			AnimalPose.step(st, 1 / 60, 0, nil, false)
		end
		AnimalPose.startle(st)
		local through, highest = false, -math.huge
		for step = 1, 60 do
			AnimalPose.step(st, 1 / 60, 0, nil, false)
			local o = {}
			AnimalPose.pose(pieces, info, st, step / 60, o)
			local low = lowest(pieces, o, isLeg)
			if low < -AnimalPose.Stand[kind] - 0.25 then
				through = true
			end
			highest = math.max(highest, low)
		end
		check(not through, kind .. ": al asustarse no mete las patas en el suelo")
		check(highest > -AnimalPose.Stand[kind] + 0.15, kind .. ": se le ve saltar")
		check(st.Startle == 0, kind .. ": el susto se acaba solo")
	end
end

print("Por la acera, nunca por la calzada")
do
	-- Las calles de verdad del mapa (las mismas que publica el servidor en ReplicatedStorage.Ambient.Roads)
	local sharedProxy = setmetatable({}, { __index = function(_, name)
		return { __path = "src/shared/" .. name .. ".luau" }
	end })
	local fakeGame = { GetService = function(_, name)
		if name == "ReplicatedStorage" then
			return { Shared = sharedProxy }
		end
		return setmetatable({}, { __index = function() return nil end })
	end }
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
		local menv = setmetatable({
			script = target, require = requireModule, game = fakeGame, workspace = {},
			Instance = roblox.Instance, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, CFrame = roblox.CFrame,
			Color3 = roblox.Color3, Enum = roblox.Enum, UDim = roblox.UDim, UDim2 = roblox.UDim2, Font = roblox.Font,
			NumberRange = roblox.NumberRange, NumberSequence = roblox.NumberSequence, ColorSequence = roblox.ColorSequence,
		}, { __index = getfenv(1) })
		local result = luau.load(fs.readFile(path), { debugName = path, environment = menv })()
		cache[path] = result
		return result
	end
	local Walkable = requireModule(sharedProxy.Walkable)
	local CityPlan = requireModule(sharedProxy.CityPlan)
	local World = node("src/server/World", nil)
	local Roads = requireModule(World.Kit.Roads)
	local Region = requireModule(World.Region)
	local V3 = roblox.Vector3.new
	local list = {}
	for _, road in Region.roads() do
		local a = if road.Axis == "X" then V3(road.From, 0, road.At) else V3(road.At, 0, road.From)
		local b = if road.Axis == "X" then V3(road.To, 0, road.At) else V3(road.At, 0, road.To)
		table.insert(list, { A = a, B = b, Width = 24 })
	end
	for _, seg in Roads.segments() do
		table.insert(list, { A = seg.A, B = seg.B, Width = Roads.Kinds[seg.Kind].Road })
	end
	local index = Walkable.new(list, CityPlan.Roundabouts)
	check(index.Count == #list and index.Count > 150, ("se leen todas las calles (%d)"):format(index.Count))
	-- Calzada de verdad, calculada aparte (sin la rejilla de Walkable)
	local function onCarriageway(x: number, z: number): boolean
		for _, r in list do
			if CityPlan.segmentDistance(x, z, r.A.X, r.A.Z, r.B.X, r.B.Z) < r.Width / 2 then
				return true
			end
		end
		for _, c in CityPlan.Roundabouts do
			if math.sqrt((x - c[1]) ^ 2 + (z - c[2]) ^ 2) < Roads.ROUNDABOUT_R then
				return true
			end
		end
		return false
	end
	-- En medio de la calzada sí; en la acera, no
	local s0 = Roads.segments()[1]
	local mid = (s0.A + s0.B) / 2
	check(Walkable.onRoad(index, mid.X, mid.Z, 0), "el centro de una carretera es calzada")
	local r0 = Region.roads()[1]
	local u = (r0.From + r0.To) / 2
	local sx, sz = if r0.Axis == "X" then u else r0.At + 16, if r0.Axis == "X" then r0.At + 16 else u
	local walkPoint = not onCarriageway(sx, sz)
	check(not walkPoint or not Walkable.onRoad(index, sx, sz, 1.5), "la acera de una calle no es calzada")
	-- Muchos animales eligiendo sitio cerca de calles (aceras de toda la ciudad)
	-- (números al azar repetibles: Lune no trae Random)
	local seed = 12345
	local rng = {}
	function rng:NextNumber(): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
	function rng:NextInteger(a: number, b: number): number
		return math.min(b, a + math.floor(self:NextNumber() * (b - a + 1)))
	end
	local function rand(): number
		return rng:NextNumber()
	end
	local picked, bad, crossed = 0, 0, 0
	for i = 1, 1500 do
		local road = list[rng:NextInteger(1, #list)]
		local t = rng:NextNumber()
		local dir = (road.B - road.A)
		if dir.Magnitude < 1 then
			continue
		end
		local perp = V3(-dir.Unit.Z, 0, dir.Unit.X)
		local side = if i % 2 == 0 then 1 else -1
		local from = road.A + dir * t + perp * side * (road.Width / 2 + 3.5)
		if onCarriageway(from.X, from.Z) then
			continue -- (esa acera cae encima de otra calle: no vale como punto de partida)
		end
		for _ = 1, 4 do
			local x, z = Walkable.pick(index, from, 2, 12, from, nil, nil, rand, 1.5)
			if x and z then
				picked += 1
				if onCarriageway(x, z) then
					bad += 1
				end
				-- El camino recto hasta allí tampoco pisa la calzada
				for k = 0, 10 do
					local px, pz = from.X + (x - from.X) * k / 10, from.Z + (z - from.Z) * k / 10
					if onCarriageway(px, pz) then
						crossed += 1
						break
					end
				end
			end
		end
	end
	check(picked > 1000, ("los animales encuentran sitio en las aceras (%d sitios)"):format(picked))
	check(bad == 0, ("ningún sitio elegido cae en la calzada (%d mal)"):format(bad))
	check(crossed == 0, ("ningún camino cruza la calle (%d mal)"):format(crossed))
	-- Huir de ti: nunca hacia la calzada
	local fled, fledBad = 0, 0
	for i = 1, 600 do
		local road = list[rng:NextInteger(1, #list)]
		local dir = road.B - road.A
		if dir.Magnitude < 1 then
			continue
		end
		local perp = V3(-dir.Unit.Z, 0, dir.Unit.X)
		local side = if i % 2 == 0 then 1 else -1
		local pos = road.A + dir * rng:NextNumber() + perp * side * (road.Width / 2 + 3)
		if Walkable.onRoad(index, pos.X, pos.Z, 0.5) then
			continue
		end
		-- El jugador llega desde fuera de la calle (así huir "hacia delante" sería meterse en la calzada)
		local player = pos + perp * side * 2.5 + dir.Unit * (rng:NextNumber() - 0.5) * 3
		local target = Walkable.escape(index, pos, player, 6, 0.75)
		if target then
			fled += 1
			if onCarriageway(target.X, target.Z) then
				fledBad += 1
			end
		end
	end
	check(fled > 300, ("se apartan de ti (%d huidas)"):format(fled))
	check(fledBad == 0, ("al huir nunca se meten en la calzada (%d mal)"):format(fledBad))
	-- Granja: no se alejan de casa
	local home = V3(-2700, 0, -2200)
	local far = 0
	for _ = 1, 400 do
		local x, z = Walkable.pick(index, home + V3(rng:NextNumber() * 20 - 10, 0, rng:NextNumber() * 20 - 10), 2, 6, nil, home, 26, rand, 1.5)
		if x and z and math.sqrt((x - home.X) ^ 2 + (z - home.Z) ^ 2) > 26 then
			far += 1
		end
	end
	check(far == 0, "las vacas, ovejas y gallinas no se alejan de su granja")
end

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
