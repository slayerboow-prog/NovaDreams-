-- Prueba de agacharse, tumbarse y el parkour (shared/Movement, Controllers/Stances y Controllers/Parkour)
-- FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-parkour.luau
--
-- Comprueba que:
--   * cada obstáculo (alto, grueso, caída detrás, velocidad, edad) da el salto que toca, o ninguno
--   * el camino del salto empieza donde estás, acaba de pie en el sitio de caer, no da saltos, pasa
--     por encima del obstáculo y respeta el sitio de caer
--   * tumbado, el cuerpo queda paralelo a la cuesta
--   * agachado, los pies se quedan en el suelo bajo la cadera (IK) y la cadera baja lo que toca
--   * las velocidades de cada postura y las reglas de cuándo se puede (bebé, montado, nadando…)
--   * las posturas dan valores normales y empiezan y acaban en cero

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Enum = roblox.CFrame, roblox.Vector3, roblox.Enum

local Movement = luau.load(fs.readFile("src/shared/Movement.luau"), {
	debugName = "Movement",
	environment = setmetatable({ Vector3 = Vector3 }, { __index = getfenv(1) }),
})()

local function load(path: string): any
	local env = {
		CFrame = CFrame, Vector3 = Vector3, Enum = Enum, script = {}, workspace = {},
		game = { GetService = function(_, name)
			return { Name = name, Shared = { Movement = "Movement" } }
		end },
		RaycastParams = { new = function()
			return {}
		end },
		require = function(what)
			assert(what == "Movement", "solo debería pedir Movement al cargarse: " .. tostring(what))
			return Movement
		end,
	}
	return luau.load(fs.readFile(path), { debugName = path, environment = setmetatable(env, { __index = getfenv(1) }) })()
end
local Stances = load("src/client/Controllers/Stances.luau")
local Parkour = load("src/client/Controllers/Parkour.luau")
local Locomotion = luau.load(fs.readFile("src/client/Controllers/Locomotion.luau"), {
	debugName = "Locomotion",
	environment = setmetatable({ CFrame = CFrame, Vector3 = Vector3, Enum = Enum, script = {}, workspace = {} }, { __index = getfenv(1) }),
})()

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local function finite(x: number): boolean
	return x == x and math.abs(x) < math.huge
end

local function amount(pose): number
	local most = 0
	for _, cf in pose do
		local x, y, z = cf:ToEulerAnglesXYZ()
		most = math.max(most, math.abs(x), math.abs(y), math.abs(z), cf.Position.Magnitude)
	end
	return most
end

local function poseFinite(pose): boolean
	for _, cf in pose do
		local x, y, z = cf:ToEulerAnglesXYZ()
		for _, v in { x, y, z, cf.Position.X, cf.Position.Y, cf.Position.Z } do
			if not finite(v) then
				return false
			end
		end
	end
	return true
end

---------------------------------------------------------------------
print("\n▶ Qué salto toca")
local cases = {
	{ "Valla (3 studs, fina)", { Height = 3, Depth = 0.5, Clear = true, Drop = 0, Speed = 12 }, "Speed" },
	{ "Barandilla baja corriendo", { Height = 2, Depth = 0.3, Clear = true, Drop = 0, Speed = 24 }, "Speed" },
	{ "Muro bajo y ancho corriendo", { Height = 3, Depth = 3.5, Clear = true, Drop = 0, Speed = 22 }, "Kong" },
	{ "Muro bajo y ancho andando", { Height = 3, Depth = 3.5, Clear = true, Drop = 0, Speed = 8 }, "Climb" },
	{ "Muro de 6 studs", { Height = 6, Depth = 1, Clear = true, Drop = 0, Speed = 12 }, "Climb" },
	{ "Borde de 8 studs con sitio arriba", { Height = 8, Depth = math.huge, Speed = 10 }, "Ledge" },
	{ "Bordillo (1 stud)", { Height = 1, Depth = 5, Clear = true, Speed = 12 }, nil },
	{ "Pared altísima", { Height = 12, Depth = 1, Clear = true, Speed = 12 }, nil },
	{ "Valla sin sitio detrás", { Height = 3, Depth = 0.5, Clear = false, Drop = 0, Speed = 12 }, nil },
	{ "Valla con un precipicio detrás", { Height = 3, Depth = 0.5, Clear = true, Drop = 40, Speed = 12 }, nil },
	{ "Muro ancho con precipicio: se sube y se queda", { Height = 3, Depth = 3, Clear = true, Drop = 40, Speed = 12 }, "Ledge" },
	{ "Bebé ante una valla", { Height = 2, Depth = 0.4, Clear = true, Drop = 0, Speed = 8, Stage = "Bebe" }, nil },
	{ "Niño: nada de kong", { Height = 3, Depth = 3.5, Clear = true, Drop = 0, Speed = 22, Stage = "Nino" }, "Climb" },
	{ "Niño (tamaño 0,6) con una valla de 2", { Height = 2, Depth = 0.3, Clear = true, Drop = 0, Speed = 10, Stage = "Nino", Scale = 0.6 }, "Speed" },
	{ "Mayor ante un muro de 6: no", { Height = 6, Depth = 1, Clear = true, Drop = 0, Speed = 8, Stage = "Mayor" }, nil },
	{ "Mayor ante una valla alta: trepa", { Height = 4, Depth = 0.5, Clear = true, Drop = 0, Speed = 8, Stage = "Mayor" }, "Climb" },
}
for _, case in cases do
	local got = Movement.classify(case[2])
	check(got == case[3], ("%s → %s%s"):format(case[1], tostring(case[3]), if got ~= case[3] then " (sale " .. tostring(got) .. ")" else ""))
end

---------------------------------------------------------------------
print("\n▶ Camino del salto")
local H = 3 -- cadera sobre los pies (adulto)
local function scenario(kind: string, height: number, depth: number, drop: number)
	local feet = 0
	local from = Vector3.new(0, feet + H, 0)
	local edge = Vector3.new(0, feet + height, -2)
	local far = edge + Vector3.new(0, 0, -depth)
	local landGround = feet - drop
	local land = if kind == "Ledge" then Vector3.new(0, feet + height + H, -3.2) else far + Vector3.new(0, 0, -2) + Vector3.new(0, landGround + H - (feet + height), 0)
	return Movement.path(kind, from, edge, far, land, H), from, edge, far, land
end
for _, def in { { "Speed", 3, 0.5, 0 }, { "Kong", 3, 3, 0 }, { "Climb", 6, 1, 0 }, { "Climb", 3, 3, 4 }, { "Ledge", 8, math.huge, 0 }, { "Speed", 3, 0.5, 6 } } do
	local kind, height, depth, drop = def[1], def[2], def[3], def[4]
	local points, from, edge, far, land = scenario(kind, height, if depth == math.huge then 0 else depth, drop)
	local name = ("%s (alto %d, caída %d)"):format(kind, height, drop)
	check((Movement.sample(points, 0) - from).Magnitude < 1e-6, name .. ": empieza donde estás")
	check((Movement.sample(points, 1) - land).Magnitude < 1e-6, name .. ": acaba de pie donde cae")
	local worst, prev, fine, overOk = 0, Movement.sample(points, 0), true, true
	local topY = edge.Y
	for i = 1, 400 do
		local u = Movement.timeCurve(i / 400)
		local p = Movement.sample(points, u)
		fine = fine and finite(p.X) and finite(p.Y) and finite(p.Z)
		worst = math.max(worst, (p - prev).Magnitude)
		prev = p
		-- Encima del obstáculo, la cadera va por encima de lo alto
		if kind ~= "Ledge" and p.Z < edge.Z - 0.2 and p.Z > far.Z + 0.2 then
			overOk = overOk and p.Y - H * 0.4 > topY
		end
	end
	check(fine, name .. ": valores normales")
	check(worst < 0.25, ("%s: sin saltos (paso más largo %.2f)"):format(name, worst))
	check(overOk, name .. ": pasa por encima (la cadera por encima de lo alto)")
	local highest = -math.huge
	for i = 0, 100 do
		highest = math.max(highest, Movement.sample(points, i / 100).Y)
	end
	check(highest > topY + H * 0.4, name .. ": el punto más alto está por encima del obstáculo")
end
local last = -1
local mono = true
for i = 0, 100 do
	local v = Movement.timeCurve(i / 100)
	mono = mono and v >= last - 1e-12 and v >= 0 and v <= 1
	last = v
end
check(mono and Movement.timeCurve(0) == 0 and Movement.timeCurve(1) == 1, "El tiempo del salto va de 0 a 1 sin volver atrás")
for _, kind in { "Speed", "Kong", "Climb", "Ledge" } do
	local d = Movement.duration(kind, 4, 1)
	check(d > 0.3 and d < 2, kind .. (": dura lo razonable (%.2f s)"):format(d))
end

---------------------------------------------------------------------
print("\n▶ Tumbado en una cuesta")
local function proneAxis(pitch: number, roll: number): Vector3
	local rotation = CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll) * CFrame.Angles(-math.pi / 2, 0, 0)
	return rotation:VectorToWorldSpace(Vector3.new(0, 1, 0)) -- de los pies a la cabeza
end
local function sideAxis(pitch: number, roll: number): Vector3
	local rotation = CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll) * CFrame.Angles(-math.pi / 2, 0, 0)
	return rotation:VectorToWorldSpace(Vector3.new(1, 0, 0))
end
local look = Vector3.new(0, 0, -1)
local p0, r0 = Movement.slopeAngles(Vector3.new(0, 1, 0), look)
check(math.abs(p0) < 1e-9 and math.abs(r0) < 1e-9, "En llano, recto")
local slope = math.rad(15)
local upAhead = Vector3.new(0, math.cos(slope), math.sin(slope)) -- cuesta arriba hacia delante (-Z)
local pitch, roll = Movement.slopeAngles(upAhead, look)
check(pitch > 0 and math.abs(roll) < 1e-6, "Cuesta arriba delante: la cabeza sube")
check(math.abs(proneAxis(pitch, roll):Dot(upAhead)) < 1e-6, "El cuerpo queda paralelo a la cuesta (hacia delante)")
local upRight = Vector3.new(-math.sin(slope), math.cos(slope), 0) -- sube hacia la derecha (+X)
local p2, r2 = Movement.slopeAngles(upRight, look)
check(r2 > 0 and math.abs(p2) < 1e-6, "Cuesta que sube a la derecha: el lado derecho sube")
check(math.abs(sideAxis(p2, r2):Dot(upRight)) < 1e-6, "Y de lado también queda paralelo")
local both = Vector3.new(-0.2, 1, 0.25).Unit
local p3, r3 = Movement.slopeAngles(both, look)
check(math.abs(proneAxis(p3, r3):Dot(both)) < 0.02, "En diagonal, casi paralelo")
check(Movement.slopeDegrees(Vector3.new(0, 1, 0)) < 1e-6 and math.abs(Movement.slopeDegrees(upAhead) - 15) < 1e-3, "Grados de la cuesta")

---------------------------------------------------------------------
print("\n▶ Agachado: pies en el suelo")
for _, legs in { { 1.2, 1.2 }, { 1.1, 1.35 }, { 0.7, 0.8 } } do
	local thigh, shin = legs[1], legs[2]
	for _, drop in { 0, 0.3, 0.7 } do
		local hip, knee, ankle = Movement.crouchLegs(drop, thigh, shin)
		-- muslo y espinilla (x>0 hacia delante = -Z)
		local a1 = hip
		local a2 = hip + knee
		local y = -(thigh * math.cos(a1) + shin * math.cos(a2))
		local z = -(thigh * math.sin(a1) + shin * math.sin(a2))
		local name = ("pierna %.1f+%.2f, bajar %.1f"):format(thigh, shin, drop)
		check(math.abs(-y - (thigh + shin - drop)) < 1e-4, name .. ": la cadera baja justo eso")
		check(math.abs(z) < 1e-4, name .. ": el pie sigue debajo")
		check(math.abs(a2 + ankle) < 1e-6, name .. ": el pie plano")
		check(knee <= 0 and finite(hip) and finite(ankle), name .. ": la rodilla dobla hacia atrás")
	end
end

---------------------------------------------------------------------
print("\n▶ Velocidades y reglas")
check(Movement.speedFactor("Stand") == 1 and Movement.speedFactor("Crouch") == 0.55 and Movement.speedFactor("Prone") == 0.25, "De pie 100 %, agachado 55 %, tumbado 25 %")
check(Movement.speedFactor(nil) == 1 and Movement.speedFactor("Volando") == 1, "Sin postura, como de pie")
check(Stances.blendSpeed(0, 0) == 1 and Stances.blendSpeed(1, 0) == 0.55 and Stances.blendSpeed(1, 1) == 0.25, "La velocidad sigue la postura")
local okBlend, prevSpeed = true, 2
for i = 0, 20 do
	local s = Stances.blendSpeed(i / 20, 0)
	okBlend = okBlend and s <= prevSpeed and s >= 0.25 and s <= 1
	prevSpeed = s
end
check(okBlend and Stances.blendSpeed(5, -3) == 0.55, "Y cambia suave, sin salirse (pesos fuera de 0..1 se recortan)")
check(Movement.witnessFactor("Crouch") == 0.5 and Movement.witnessFactor("Stand") == 1, "Agachado, los testigos tienen que estar a la mitad de distancia")
local normal = { Stage = "Adulto" }
check(Movement.allowed("Crouch", normal) and Movement.allowed("Prone", normal), "Un adulto a pie se agacha y se tumba")
check(Movement.allowed("Stand", { Riding = true, Dead = true }), "Ponerse de pie siempre vale")
check(not Movement.allowed("Crouch", { Stage = "Bebe" }), "Los bebés no (ya gatean)")
check(not Movement.allowed("Crouch", { Stage = "Adulto", Riding = true }), "Montado no")
check(not Movement.allowed("Prone", { Stage = "Adulto", Seated = true }), "Sentado no")
check(not Movement.allowed("Prone", { Stage = "Adulto", Swimming = true }), "Nadando no")
check(not Movement.allowed("Volar", normal) and not Movement.allowed(nil, normal), "Una postura inventada no vale")

---------------------------------------------------------------------
print("\n▶ Posturas")
check(amount(Stances.crouchPose(0, 0, 0, 0, 0, 0)) < 1e-9, "Agachado con peso 0 no hace nada")
local hip, knee, ankle = Movement.crouchLegs(0.75, 1.2, 1.2)
local crouch = Stances.crouchPose(1, hip, knee, ankle, 1, 1.3)
check(poseFinite(crouch) and amount(crouch) > 0.3 and amount(crouch) < math.pi, "Agachado: valores normales y se nota")
local fineProne = true
for i = 0, 16 do
	local pose = Stances.pronePose(i % 2, i / 16 * math.pi * 2, 0.2, -0.1, -0.8)
	fineProne = fineProne and poseFinite(pose)
end
check(fineProne, "Tumbado (quieto y arrastrándose): valores normales")
local lying = Stances.pronePose(0, 0, 0, 0, 0)
check(math.abs(lying.Root.UpVector.Y) < 1e-6, "Tumbado: el cuerpo en horizontal")
check(lying.Root.UpVector.Z < -0.99, "Tumbado: la cabeza hacia delante")
local a = Stances.pronePose(1, math.pi / 2, 0, 0, 0)
local b = Stances.pronePose(1, -math.pi / 2, 0, 0, 0)
local ax = select(1, a.RightShoulder:ToEulerAnglesXYZ())
local bx = select(1, b.RightShoulder:ToEulerAnglesXYZ())
check(math.abs(ax - bx) > 0.3, "Arrastrándose, los brazos se alternan")
for kind, keys in Parkour.Keys do
	local sorted = keys[1].T == 0 and keys[#keys].T == 1
	for i = 2, #keys do
		sorted = sorted and keys[i].T > keys[i - 1].T
	end
	check(sorted, kind .. ": fotogramas en orden, de 0 a 1")
	check(amount(Parkour.pose(kind, 0)) < 1e-6 and amount(Parkour.pose(kind, 1)) < 1e-6, kind .. ": empieza y acaba en cero")
	local peak, fineAll = 0, true
	for i = 0, 50 do
		local pose = Parkour.pose(kind, i / 50)
		fineAll = fineAll and poseFinite(pose)
		peak = math.max(peak, amount(pose))
	end
	check(fineAll and peak > 0.5 and peak < math.pi, (kind .. ": valores normales y se mueve (%.2f rad)"):format(peak))
end
local okWeight = Parkour.weight(0, 0.6) == 0 and Parkour.weight(1, 0.6) == 0
for i = 0, 50 do
	local w = Parkour.weight(i / 50, 0.6)
	okWeight = okWeight and w >= 0 and w <= 1
end
check(okWeight and Parkour.weight(0.5, 0.6) == 1, "El peso del salto entra y sale (0 en los extremos, 1 en medio)")
local kind, start, duration = Parkour.parse("Kong|1234.500|0.60")
check(kind == "Kong" and start == 1234.5 and duration == 0.6, "El atributo Vault se lee bien")
check(Parkour.parse("Volar|1|1") == nil and Parkour.parse(nil) == nil and Parkour.parse("Kong|x|1") == nil, "Y uno raro se ignora")

---------------------------------------------------------------------
print("\n▶ Caer corriendo")
check(Locomotion.landing(120, 20) == "Roll", "Desde muy alto corriendo: voltereta")
check(Locomotion.landing(120, 2) == "Stumble", "Desde muy alto parado: traspiés")
check(Locomotion.landing(50, 20) == "Land", "Un salto normal corriendo: solo se agacha un poco")

print("")
if failures > 0 then
	print(("❌ %d fallo(s)"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
