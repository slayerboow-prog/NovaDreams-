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

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
