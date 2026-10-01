-- Prueba de los golpes que se ven siempre (Controllers/PunchAnim) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-punch.luau
--
-- Comprueba que:
--   * existen directo, cruzado y patada, y la guardia
--   * cada golpe empieza y acaba en la postura normal (el cuerpo no se queda torcido)
--   * en el momento del golpe se mueve de verdad lo que tiene que moverse: el brazo derecho en el
--     directo, el izquierdo en el cruzado y la pierna derecha en la patada
--   * la guardia sube los dos brazos delante de la cara
--   * no hay ángulos locos

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame = roblox.CFrame
-- shared/Joints (articulaciones Motor6D o AnimationConstraint): lo piden los módulos al cargarse
local Joints = luau.load(fs.readFile("src/shared/Joints.luau"), { debugName = "Joints", environment = setmetatable({ CFrame = roblox.CFrame }, { __index = getfenv(1) }) })()
local fakeGame = { GetService = function(_, name)
	return { Name = name, Shared = { Joints = Joints } }
end }
local env = setmetatable({ CFrame = CFrame, game = fakeGame, require = function(what)
	assert(what == Joints, "PunchAnim solo debería pedir Joints al cargarse")
	return Joints
end }, { __index = getfenv(1) })
local PunchAnim = luau.load(fs.readFile("src/client/Controllers/PunchAnim.luau"), { debugName = "PunchAnim", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Cuánto gira una articulación (radianes) respecto a no hacer nada
local function amount(cf: CFrame?): number
	if not cf then
		return 0
	end
	local x, y, z = cf:ToEulerAnglesXYZ()
	return math.abs(x) + math.abs(y) + math.abs(z)
end
local function pitch(cf: CFrame?): number
	if not cf then
		return 0
	end
	local x = cf:ToEulerAnglesXYZ()
	return x
end

local function rest(pose): boolean
	for _, cf in pose do
		if amount(cf) > 1e-3 then
			return false
		end
	end
	return true
end

local function sane(move: string): boolean
	for i = 0, 40 do
		for _, cf in PunchAnim.pose(move, i / 40, {}) do
			if amount(cf) > 3.2 then
				return false
			end
		end
	end
	return true
end

-- El momento de más fuerza de cada golpe
local function peak(move: string, joint: string): (number, number)
	local best, bestT = 0, 0
	for i = 0, 40 do
		local value = pitch(PunchAnim.pose(move, i / 40, {})[joint])
		if value > best then
			best, bestT = value, i / 40
		end
	end
	return best, bestT
end

print("Golpes")
for _, move in { "Jab", "Cross", "Kick" } do
	check(PunchAnim.Moves[move] ~= nil, move .. " existe")
	check(rest(PunchAnim.pose(move, 0, {})) and rest(PunchAnim.pose(move, 1, {})), move .. " empieza y acaba en postura normal")
	check(sane(move), move .. " sin ángulos locos")
end

local jab = peak("Jab", "RightShoulder")
check(jab > 1.3, ("Directo: el brazo derecho sale hacia delante (%.2f rad)"):format(jab))
check(amount(PunchAnim.pose("Jab", 0.45, {}).RightElbow) < 0.5, "Directo: en el golpe el brazo va casi estirado")
local cross = peak("Cross", "LeftShoulder")
check(cross > 1.3, ("Cruzado: el brazo izquierdo sale hacia delante (%.2f rad)"):format(cross))
local kick = peak("Kick", "RightHip")
check(kick > 1.2, ("Patada: la pierna derecha sube (%.2f rad)"):format(kick))
check(amount(PunchAnim.pose("Kick", 0.12, {}).RightKnee) > 0.4, "Patada: primero recoge la rodilla")

print("Combo largo, finales y poderes")
for _, move in { "Hook", "Knee", "Elbow", "Uppercut", "SpinKick", "Slam", "Charged", "Blast" } do
	check(PunchAnim.Moves[move] ~= nil, move .. " existe")
	check(rest(PunchAnim.pose(move, 0, {})) and rest(PunchAnim.pose(move, 1, {})), move .. " empieza y acaba en postura normal")
	check(sane(move), move .. " sin ángulos locos")
end
local upper = peak("Uppercut", "RightShoulder")
check(upper > 2, ("Lanzador: el puño sube hacia el cielo (%.2f rad)"):format(upper))
local knee = peak("Knee", "RightHip")
check(knee > 1.3, ("Rodillazo: la rodilla sube (%.2f rad)"):format(knee))
local slamUp = peak("Slam", "LeftShoulder")
check(slamUp > 2 and pitch(PunchAnim.pose("Slam", 0.75, {}).Waist) < 0, "Al suelo: los dos puños arriba y luego el cuerpo se echa hacia delante")
local spin = 0
for i = 0, 40 do
	local _, y = PunchAnim.pose("SpinKick", i / 40, {}).Waist:ToEulerAnglesYXZ()
	spin = math.max(spin, math.abs(y))
end
check(spin > 1, ("Patada giratoria: la cintura gira (%.2f rad)"):format(spin))
-- Combat.Moves usa estas posturas
local Combat = luau.load(fs.readFile("src/shared/Combat.luau"), { debugName = "Combat" })()
local missing = {}
for name, move in Combat.Moves do
	if not PunchAnim.Moves[move.Anim] then
		table.insert(missing, name .. "→" .. move.Anim)
	end
end
check(#missing == 0, "cada golpe de shared/Combat tiene su postura" .. (if #missing > 0 then ": " .. table.concat(missing, ", ") else ""))
for _, hold in { "Windup", "Charge", "Aim" } do
	check(PunchAnim.Holds[hold] ~= nil and not rest(PunchAnim.pose(nil, 0, { [hold] = 1 })) and rest(PunchAnim.pose(nil, 0, { [hold] = 0 })), "Postura mantenida " .. hold .. " (y sin ella, normal)")
end
check(type(PunchAnim.freeze) == "function", "Congelación del impacto (PunchAnim.freeze)")

print("Guardia")
local guard = PunchAnim.pose(nil, 0, { Guard = 1 })
check(pitch(guard.RightShoulder) > 1 and pitch(guard.LeftShoulder) > 1, "Los dos brazos suben")
check(pitch(guard.RightElbow) > 1.5 and pitch(guard.LeftElbow) > 1.5, "Los antebrazos se doblan delante de la cara")
check(rest(PunchAnim.pose(nil, 0, { Guard = 0 })), "Sin guardia, postura normal")
check(pitch(PunchAnim.pose("Jab", 0.45, { Guard = 1 }).RightShoulder) > 1.3, "Se puede pegar con la guardia puesta")

if failures > 0 then
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
