-- Prueba de las reacciones del cuerpo (Controllers/ReactMotion) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-react.luau
--
-- Comprueba que:
--   * existen los golpes (directo, cruzado, gancho), las reacciones al recibir y los choques
--     (patada al balón, tropiezo), los gestos de acciones (alcanzar, coger, comer, beber, lanzar,
--     pescar, aterrizar) y las posturas mantenidas (guardia, arena, arbusto, charco, linterna, caña)
--   * cada animación empieza y acaba en la postura normal (no deja el cuerpo torcido)
--   * a mitad de animación el cuerpo se mueve de verdad y sin ángulos locos
--   * solo se tocan articulaciones de un R15
--   * combine junta varias cosas a la vez (pegar mientras se pisa un charco)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Enum = roblox.CFrame, roblox.Vector3, roblox.Enum

local fakeGame = { GetService = function(_, name)
	return { Name = name }
end }
local env = setmetatable({ CFrame = CFrame, Vector3 = Vector3, Color3 = roblox.Color3, Enum = Enum, game = fakeGame, workspace = {}, script = {}, RaycastParams = { new = function() return {} end } }, { __index = getfenv(1) })
local ReactMotion = luau.load(fs.readFile("src/client/Controllers/ReactMotion.luau"), { debugName = "ReactMotion", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local JOINTS = {
	Root = true, Waist = true, Neck = true, RightShoulder = true, LeftShoulder = true, RightElbow = true,
	LeftElbow = true, RightHip = true, LeftHip = true, RightKnee = true, LeftKnee = true,
}

-- Cuánto se aparta una postura de la normal (el mayor ángulo o desplazamiento)
local function amount(pose): number
	local most = 0
	for _, cf in pose do
		local x, y, z = cf:ToEulerAnglesXYZ()
		most = math.max(most, math.abs(x), math.abs(y), math.abs(z), cf.Position.Magnitude)
	end
	return most
end

local function sane(pose): (boolean, string?)
	for name, cf in pose do
		if not JOINTS[name] then
			return false, "articulación desconocida " .. tostring(name)
		end
		local x, y, z = cf:ToEulerAnglesXYZ()
		for _, a in { x, y, z, cf.Position.X, cf.Position.Y, cf.Position.Z } do
			if a ~= a or math.abs(a) > math.pi then
				return false, name .. " tiene un valor raro"
			end
		end
	end
	return true
end

print("\n▶ Golpes y choques")
local KINDS = { "Jab", "Cross", "Hook", "HitLight", "HitHeavy", "BlockHit", "Kick", "Trip", "Reach", "PickUp", "Eat", "Drink", "Throw", "Cast", "Reel", "Land", "Stumble", "Roll" }
for _, name in KINDS do
	local kind = ReactMotion.Kinds[name]
	if not kind then
		check(false, name .. " existe")
		continue
	end
	local okAll, why = true, nil
	local peak = 0
	for i = 0, 40 do
		local pose = kind.Pose(i / 40, { Side = if i % 2 == 0 then 1 else -1 })
		local ok, reason = sane(pose)
		if not ok then
			okAll, why = false, reason
		end
		peak = math.max(peak, amount(pose))
	end
	local ends = math.max(amount(kind.Pose(0, {})), amount(kind.Pose(1, {})))
	check(okAll, name .. ": ángulos normales" .. (if why then " (" .. why .. ")" else ""))
	check(ends < 0.02, string.format("%s: empieza y acaba en la postura normal (%.3f)", name, ends))
	check(peak > 0.3, string.format("%s: el cuerpo se mueve de verdad (%.2f rad)", name, peak))
	check(kind.Duration > 0.15 and kind.Duration < 1.5, name .. ": dura lo razonable")
end

-- El directo es con la derecha y el cruzado con la izquierda
local jab = ReactMotion.Kinds.Jab.Pose(0.35, {})
local cross = ReactMotion.Kinds.Cross.Pose(0.35, {})
local function forward(pose, joint)
	local cf = pose[joint]
	return if cf then (select(1, cf:ToEulerAnglesXYZ())) else 0
end
check(forward(jab, "RightShoulder") > forward(jab, "LeftShoulder"), "El directo lanza el brazo derecho")
check(forward(cross, "LeftShoulder") > forward(cross, "RightShoulder"), "El cruzado lanza el brazo izquierdo")
-- El golpe recibido por un lado gira la cabeza al contrario que por el otro
local left = ReactMotion.Kinds.HitLight.Pose(0.3, { Side = 1 })
local right = ReactMotion.Kinds.HitLight.Pose(0.3, { Side = -1 })
local function yaw(pose)
	local cf = pose.Neck or pose.Waist
	if not cf then
		return 0
	end
	local _, y, z = cf:ToEulerAnglesXYZ()
	return y + z
end
check(yaw(left) * yaw(right) < 0, "Un golpe por la izquierda y otro por la derecha mueven la cabeza a lados distintos")
-- La patada es con la pierna
check(forward(ReactMotion.Kinds.Kick.Pose(0.4, {}), "RightHip") > 0.3, "La patada al balón levanta la pierna derecha")

print("\n▶ Posturas mantenidas")
for _, name in { "Guard", "Sand", "Bush", "Splash", "Flashlight", "Rod" } do
	local hold = ReactMotion.Holds[name]
	if not hold then
		check(false, name .. " existe")
		continue
	end
	local okAll, peak = true, 0
	for i = 0, 16 do
		local pose = hold(1, i / 16 * math.pi * 2)
		okAll = okAll and (sane(pose))
		peak = math.max(peak, amount(pose))
	end
	check(okAll, name .. ": ángulos normales")
	check(peak > 0.15, name .. ": se nota")
	check(amount(hold(0, 1)) < 0.001, name .. ": con peso 0 no hace nada")
end

print("\n▶ Varias cosas a la vez")
local both = ReactMotion.combine({ { Kind = "Jab", T = 0.35, Opts = {} } }, { Splash = 1 }, 1.2)
check(both.RightShoulder ~= nil and both.RightHip ~= nil, "Pegar mientras pisas un charco mueve brazos y piernas")
check((sane(both)), "La mezcla sigue siendo normal")
local none = ReactMotion.combine({}, {}, 0)
check(amount(none) < 0.001, "Sin nada, el cuerpo queda como estaba")
local done = ReactMotion.combine({ { Kind = "Hook", T = 1.5, Opts = {} } }, { Guard = 0 }, 0)
check(amount(done) < 0.001, "Una animación ya terminada no se aplica")

print("")
if failures > 0 then
	print(string.format("❌ %d comprobaciones fallidas", failures))
	process.exit(1)
end
print("✅ Todo correcto")
