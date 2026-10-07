-- Prueba de los golpes que se ven siempre (Controllers/PunchAnim) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-punch.luau
--
-- Comprueba que:
--   * cada golpe empieza y acaba en la postura normal (el cuerpo no se queda torcido) y no hay ángulos locos
--   * cada golpe llega a su EXTENSIÓN MÁXIMA justo en su tiempo de impacto (Impact), apunta al frente
--     (o arriba / abajo) y llega bastante más lejos que en reposo, sobre un R15 estándar (scripts/lib/R15Rig)
--   * anticipación, giro de torso y cadera y paso adelante; la patada giratoria da la vuelta entera
--   * ni el puño ni el pie se meten en el cuerpo y las rodillas no se doblan al revés
--   * en un cuerpo de verdad (Motor6D y AnimationConstraint) el golpe mueve el brazo y al acabar TODAS
--     las articulaciones vuelven a su C0; encadenar dos golpes no da saltos; la congelación del
--     impacto se queda en la extensión máxima
--   * no lo pisa otra capa: la animación de andar (Transform) se apaga en las articulaciones del golpe
--     (PoseLayers) y ActorLife no escribe C0 mientras PunchAnim trabaja
--   * R6 (por si acaso): versión simple que también golpea hacia delante y vuelve
--   * la guardia sube los dos brazos delante de la cara

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local R15Rig = require("./lib/R15Rig")

local CFrame, Vector3, Instance, Enum = roblox.CFrame, roblox.Vector3, roblox.Instance, roblox.Enum

-- shared/Joints (articulaciones Motor6D o AnimationConstraint) y PoseLayers: lo que piden los módulos
local Joints = luau.load(fs.readFile("src/shared/Joints.luau"), { debugName = "Joints", environment = setmetatable({ CFrame = CFrame }, { __index = getfenv(1) }) })()
local Layers = luau.load(fs.readFile("src/client/Controllers/PoseLayers.luau"), { debugName = "PoseLayers", environment = setmetatable({ game = {} }, { __index = getfenv(1) }) })()
local POSE_LAYERS = { Name = "PoseLayers" }
local fakeGame = { GetService = function(_, name)
	return { Name = name, Shared = { Joints = Joints }, RenderStepped = { Connect = function() end }, GetPlayerFromCharacter = function()
		return nil -- (en la prueba todos los cuerpos son de NPC)
	end }
end }
local env = setmetatable({
	CFrame = CFrame,
	game = fakeGame,
	script = { Parent = { PoseLayers = POSE_LAYERS } },
	require = function(what)
		if what == POSE_LAYERS then
			return Layers
		end
		assert(what == Joints, "PunchAnim solo debería pedir Joints (y PoseLayers al arrancar)")
		return Joints
	end,
}, { __index = getfenv(1) })
local PunchAnim = luau.load(fs.readFile("src/client/Controllers/PunchAnim.luau"), { debugName = "PunchAnim", environment = env })()

local failures = 0
local function check(ok: any, what: string)
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
	return math.abs(x) + math.abs(y) + math.abs(z) + cf.Position.Magnitude
end
local function pitch(cf: CFrame?): number
	if not cf then
		return 0
	end
	local x = cf:ToEulerAnglesXYZ()
	return x
end
local function yaw(cf: CFrame?): number
	if not cf then
		return 0
	end
	local _, y = cf:ToEulerAnglesYXZ()
	return y
end

local function rest(pose): boolean
	for _, cf in pose do
		if amount(cf) > 1e-3 then
			return false
		end
	end
	return true
end

-- Sin ángulos locos (la raíz de la patada giratoria sí da la vuelta: es a propósito)
local function sane(move: string): boolean
	for i = 0, 40 do
		for name, cf in PunchAnim.pose(move, i / 40, {}) do
			if name ~= "Root" and amount(cf) > 3.2 then
				return false
			end
		end
	end
	return true
end

-- El momento de más fuerza de cada golpe (en una articulación)
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

-- Esqueleto R15 estándar con la postura del golpe en el instante t
local function solve(move: string, t: number)
	return R15Rig.solve(PunchAnim.pose(move, t, {}), PunchAnim._toJoint)
end
-- Hasta dónde llega la pieza que golpea: adelante, arriba o abajo (studs)
local function reach(move: string, t: number): number
	local def = PunchAnim.Moves[move]
	local frames = solve(move, t)
	local tip = R15Rig.tip(frames, def.Limb)
	local root = frames.HumanoidRootPart.Position
	if def.Reach == "Up" then
		return tip.Y - root.Y
	elseif def.Reach == "Down" then
		return root.Y - tip.Y
	elseif def.Reach == "Across" then
		return if def.Limb:sub(1, 4) == "Left" then tip.X else -tip.X -- barre hacia el otro lado
	end
	return root.Z - tip.Z
end

local ALL = { "Jab", "Cross", "Hook", "Knee", "Elbow", "Kick", "Uppercut", "SpinKick", "Slam", "Charged", "Blast" }

print("Golpes: empiezan y acaban en reposo, sin ángulos locos")
for _, move in ALL do
	local def = PunchAnim.Moves[move]
	check(def ~= nil and type(def.Impact) == "number" and def.Impact > 0 and def.Impact < 1 and type(def.Limb) == "string", move .. " existe, con su impacto y la pieza que golpea")
	check(rest(PunchAnim.pose(move, 0, {})) and rest(PunchAnim.pose(move, 1, {})), move .. " empieza y acaba en postura normal")
	check(sane(move), move .. " sin ángulos locos")
end

print("Extensión máxima en el impacto (R15 estándar)")
for _, move in ALL do
	local def = PunchAnim.Moves[move]
	local best, bestT = -math.huge, 0
	for i = 0, 80 do
		local value = reach(move, i / 80)
		if value > best then
			best, bestT = value, i / 80
		end
	end
	local atImpact = reach(move, def.Impact)
	local atRest = reach(move, 0)
	check(atImpact >= best - 0.03 * math.abs(best) - 0.02,
		("%s: llega al máximo en el impacto (t=%.2f, %.2f s): %.2f de %.2f (máximo en t=%.2f)"):format(move, def.Impact, def.Impact * def.Duration, atImpact, best, bestT))
	check(atImpact - atRest > 0.8, ("%s: en el impacto %s llega %.2f studs más que en reposo"):format(move, def.Limb, atImpact - atRest))
	check(def.Impact * def.Duration <= 0.35, ("%s: el impacto llega rápido (%.2f s)"):format(move, def.Impact * def.Duration))
	if def.Reach == "Forward" then
		local tip = R15Rig.tip(solve(move, def.Impact), def.Limb)
		check(math.abs(tip.X) < 1.6, ("%s: apunta al frente (x=%.2f)"):format(move, tip.X))
	end
	-- Ni dentro del cuerpo ni rodillas al revés en todo el golpe
	local inside, knees = nil, nil
	for i = 0, 40 do
		local frames = solve(move, i / 40)
		for _, part in { "RightHand", "LeftHand", "RightFoot", "LeftFoot" } do
			local tip = R15Rig.tip(frames, part)
			if R15Rig.inside(frames, "UpperTorso", tip, 0.15) or R15Rig.inside(frames, "Head", tip, 0.1) then
				inside = inside or ("%s en t=%.2f"):format(part, i / 40)
			end
		end
		for _, side in { "Right", "Left" } do
			if frames[side .. "UpperLeg"]:ToObjectSpace(frames[side .. "LowerLeg"]).LookVector.Y > 0.2 then
				knees = knees or ("%s en t=%.2f"):format(side, i / 40)
			end
		end
	end
	check(inside == nil, move .. ": el puño o el pie no se mete en el cuerpo" .. (if inside then " (" .. inside .. ")" else ""))
	check(knees == nil, move .. ": las rodillas no se doblan al revés" .. (if knees then " (" .. knees .. ")" else ""))
end

print("Anticipación, cuerpo y paso adelante")
for _, move in { "Jab", "Cross", "Hook", "Elbow", "Charged" } do
	local def = PunchAnim.Moves[move]
	local wind = yaw(PunchAnim.pose(move, def.Impact * 0.35, {}).Waist)
	local hit = yaw(PunchAnim.pose(move, def.Impact, {}).Waist)
	check(wind * hit < 0 and math.abs(hit) > 0.3, ("%s: primero el torso carga hacia el otro lado (%.2f → %.2f)"):format(move, wind, hit))
	local root = PunchAnim.pose(move, def.Impact, {}).Root
	check(root ~= nil and root.Position.Z < -0.3, ("%s: el cuerpo da un paso adelante (%.2f)"):format(move, if root then -root.Position.Z else 0))
end
check(yaw(PunchAnim.pose("Jab", 0.3, {}).Waist) > 0.3 and yaw(PunchAnim.pose("Cross", 0.3, {}).Waist) < -0.3, "Directo y cruzado: el torso gira hacia el lado contrario del brazo que pega")
check(math.abs(yaw(PunchAnim.pose("Jab", 0.3, {}).Neck) + yaw(PunchAnim.pose("Jab", 0.3, {}).Waist) + yaw(PunchAnim.pose("Jab", 0.3, {}).Root)) < 0.25, "Directo: la cabeza sigue mirando al frente")
local jab = peak("Jab", "RightShoulder")
check(jab > 1.3, ("Directo: el brazo derecho sale hacia delante (%.2f rad)"):format(jab))
check(amount(PunchAnim.pose("Jab", 0.3, {}).RightElbow) < 0.3, "Directo: en el golpe el brazo va casi estirado")
check(amount(PunchAnim.pose("Kick", 0.12, {}).RightKnee) > 0.4, "Patada: primero recoge la rodilla")
local upper = peak("Uppercut", "RightShoulder")
check(upper > 2, ("Lanzador: el puño sube hacia el cielo (%.2f rad)"):format(upper))
local slamUp = peak("Slam", "LeftShoulder")
check(slamUp > 2 and pitch(PunchAnim.pose("Slam", 0.75, {}).Waist) < 0, "Al suelo: los dos puños arriba y luego el cuerpo se echa hacia delante")
-- Patada giratoria: la cadera da casi una vuelta antes del impacto (la pierna derecha queda delante)
local spinAt = function(t)
	local look = PunchAnim.pose("SpinKick", t, {}).Root.LookVector
	return look
end
local half = spinAt(0.3)
check(half.Z > -0.2, "Patada giratoria: a media patada está de espaldas o de lado (da la vuelta)")
local spinTip = R15Rig.tip(solve("SpinKick", PunchAnim.Moves.SpinKick.Impact), "RightFoot")
check(-spinTip.Z > 2, ("Patada giratoria: en el impacto el pie derecho está delante (%.2f)"):format(-spinTip.Z))

-- Combat.Moves usa estas posturas
local Combat = luau.load(fs.readFile("src/shared/Combat.luau"), { debugName = "Combat" })()
local missing = {}
for name, move in Combat.Moves do
	if not PunchAnim.Moves[move.Anim] then
		table.insert(missing, name .. "→" .. move.Anim)
	end
end
check(#missing == 0, "cada golpe de shared/Combat tiene su postura" .. (if #missing > 0 then ": " .. table.concat(missing, ", ") else ""))
-- El siguiente golpe del combo (la pausa del servidor) llega cuando el anterior ya ha pegado
local early = {}
for name, move in Combat.Moves do
	local def = PunchAnim.Moves[move.Anim]
	if def and move.Recovery < def.Impact * def.Duration then
		table.insert(early, name)
	end
end
check(#early == 0, "ningún golpe se corta antes de su impacto al encadenar" .. (if #early > 0 then ": " .. table.concat(early, ", ") else ""))
for _, hold in { "Windup", "Charge", "Aim" } do
	check(PunchAnim.Holds[hold] ~= nil and not rest(PunchAnim.pose(nil, 0, { [hold] = 1 })) and rest(PunchAnim.pose(nil, 0, { [hold] = 0 })), "Postura mantenida " .. hold .. " (y sin ella, normal)")
end

print("Guardia")
local guard = PunchAnim.pose(nil, 0, { Guard = 1 })
check(pitch(guard.RightShoulder) > 0.8 and pitch(guard.LeftShoulder) > 0.8, "Los dos brazos suben")
check(pitch(guard.RightElbow) > 1.5 and pitch(guard.LeftElbow) > 1.5, "Los antebrazos se doblan delante de la cara")
check(rest(PunchAnim.pose(nil, 0, { Guard = 0 })), "Sin guardia, postura normal")
check(reach("Jab", 0.3) > 2 and pitch(PunchAnim.pose("Jab", 0.3, { Guard = 1 }).RightShoulder) > 1, "Se puede pegar con la guardia puesta")

print("Fundido al encadenar (función pura)")
local a, b = PunchAnim.pose("Jab", 0.5, {}), PunchAnim.pose("Cross", 0.1, {})
local full = PunchAnim.blend(a, b, 1)
check(amount(full.RightShoulder:ToObjectSpace(a.RightShoulder * (b.RightShoulder or CFrame.identity))) < 1e-4, "con f = 1 sigue entero lo de antes")
check(PunchAnim.blend(a, b, 0) == b, "con f = 0 solo queda el golpe nuevo")

---------------------------------------------------------------------
-- En un cuerpo de verdad (Lune): R15 con Motor6D o con AnimationConstraint, y R6
---------------------------------------------------------------------
local function joint(kind: string, name: string, part0: any, part1: any, c0: CFrame, c1: CFrame): any
	if kind ~= "AnimationConstraint" then
		local m = Instance.new("Motor6D")
		m.Name, m.Part0, m.Part1, m.C0, m.C1 = name, part0, part1, c0, c1
		m.Transform = CFrame.identity
		m.Parent = if name == "RootJoint" then part0 else part1
		return m
	end
	local a0 = Instance.new("Attachment")
	a0.Name, a0.CFrame, a0.Parent = name .. "RigAttachment", c0, part0
	local a1 = Instance.new("Attachment")
	a1.Name, a1.CFrame, a1.Parent = name .. "RigAttachment", c1, part1
	local m = Instance.new("AnimationConstraint")
	m.Name, m.Attachment0, m.Attachment1 = name, a0, a1
	m.Transform = CFrame.identity
	m.Parent = part1
	return m
end

local function r15(kind: string): any
	local model = Instance.new("Model")
	for name, size in R15Rig.Sizes do
		local p = Instance.new("Part")
		p.Name, p.Size, p.Parent = name, size, model
	end
	model:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(0, 3, 0)
	for _, def in R15Rig.Joints do
		joint(kind, def[1], model:FindFirstChild(def[2]), model:FindFirstChild(def[3]), def[4], def[5])
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.Parent = model
	model.Parent = Instance.new("Folder")
	return model
end

-- R6 con sus C0 girados de verdad
local R6 = {
	{ "RootJoint", "HumanoidRootPart", "Torso", CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	{ "Neck", "Torso", "Head", CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
	{ "Right Shoulder", "Torso", "Right Arm", CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	{ "Left Shoulder", "Torso", "Left Arm", CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
	{ "Right Hip", "Torso", "Right Leg", CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	{ "Left Hip", "Torso", "Left Leg", CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
}
local function r6(): any
	local model = Instance.new("Model")
	for name, size in { HumanoidRootPart = Vector3.new(2, 2, 1), Torso = Vector3.new(2, 2, 1), Head = Vector3.new(2, 1, 1), ["Right Arm"] = Vector3.new(1, 2, 1), ["Left Arm"] = Vector3.new(1, 2, 1), ["Right Leg"] = Vector3.new(1, 2, 1), ["Left Leg"] = Vector3.new(1, 2, 1) } do
		local p = Instance.new("Part")
		p.Name, p.Size, p.Parent = name, size, model
	end
	model:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(0, 3, 0)
	for _, def in R6 do
		joint("Motor6D", def[1], model:FindFirstChild(def[2]), model:FindFirstChild(def[3]), def[4], def[5])
	end
	model.Parent = Instance.new("Folder")
	return model
end

-- Dónde queda cada pieza (Part1 = Part0 * C0 * Transform * C1⁻¹)
local function world(model: any): { [string]: CFrame }
	local frames = { HumanoidRootPart = model:FindFirstChild("HumanoidRootPart").CFrame }
	for _ = 1, 10 do
		for _, d in model:GetDescendants() do
			if Joints.isJoint(d) then
				local p0, p1 = Joints.part0(d), Joints.part1(d)
				if p0 and p1 and frames[p0.Name] and not frames[p1.Name] then
					frames[p1.Name] = frames[p0.Name] * Joints.c0(d) * d.Transform * Joints.c1(d):Inverse()
				end
			end
		end
	end
	return frames
end
local function c0s(model: any): { [any]: CFrame }
	local out = {}
	for _, d in model:GetDescendants() do
		if Joints.isJoint(d) then
			out[d] = Joints.c0(d)
		end
	end
	return out
end
local function allBack(before: { [any]: CFrame }): boolean
	for j, cf in before do
		local now = Joints.c0(j)
		if (now.Position - cf.Position).Magnitude > 1e-4 or now.LookVector:Dot(cf.LookVector) < 0.99999 or now.UpVector:Dot(cf.UpVector) < 0.99999 then
			return false
		end
	end
	return true
end
-- Pon el golpe en curso en el instante t (fracción) sin esperar
local function at(model: any, t: number)
	local body = PunchAnim._bodyOf(model)
	body.Start = os.clock() - body.Duration * t
	body.FreezeAt = nil
	PunchAnim._step(1 / 60)
end

PunchAnim._dampLayer() -- (la capa que apaga la animación de andar)
local swing = CFrame.Angles(-0.8, 0, 0.3) -- lo que pondría la animación de correr en el brazo
local walkers = {}
Layers.add("AndarDePrueba", 20, function()
	for _, model in walkers do
		for _, d in model:GetDescendants() do
			if d.Name == "RightShoulder" and Joints.isJoint(d) then
				Layers.write(d, swing)
			end
		end
	end
end)

for _, kind in { "Motor6D", "AnimationConstraint" } do
	print("Cuerpo R15 con " .. kind)
	local model = r15(kind)
	table.insert(walkers, model)
	local original = c0s(model)
	local before = world(model)
	for _, move in ALL do
		check(PunchAnim.play(model, move), ("%s: %s se puede dar"):format(kind, move))
		local def = PunchAnim.Moves[move]
		at(model, def.Impact)
		local hit = world(model)
		local tip = (hit[def.Limb] * CFrame.new(0, -R15Rig.Sizes[def.Limb].Y / 2, 0)).Position
		local expected = R15Rig.tip(solve(move, def.Impact), def.Limb)
		check((tip - expected).Magnitude < 0.05, ("%s: %s en el impacto, %s donde dice la postura (%.3f)"):format(kind, move, def.Limb, (tip - expected).Magnitude))
		at(model, 3)
		check(allBack(original), ("%s: tras %s todas las articulaciones vuelven a su C0"):format(kind, move))
	end
	check((world(model).RightHand.Position - before.RightHand.Position).Magnitude < 1e-3, kind .. ": al acabar el brazo vuelve a su sitio")

	-- Encadenar: el cruzado empieza con el directo a medias, sin salto
	PunchAnim.play(model, "Jab")
	at(model, 0.6)
	local mid = world(model).RightHand.Position
	PunchAnim.play(model, "Cross")
	PunchAnim._step(1 / 60)
	check((world(model).RightHand.Position - mid).Magnitude < 0.25, ("%s: encadenar no da saltos (%.2f)"):format(kind, (world(model).RightHand.Position - mid).Magnitude))
	at(model, 3)
	PunchAnim._bodyOf(model).From = nil
	PunchAnim._step(1 / 60)
	check(not PunchAnim.busy(model) and allBack(original), kind .. ": tras el fundido todo vuelve a su C0 y PunchAnim lo suelta")

	-- Congelación del impacto: si llega tarde, vuelve a la extensión máxima y se queda
	PunchAnim.play(model, "Jab")
	local body = PunchAnim._bodyOf(model)
	body.Start = os.clock() - body.Duration * 0.8
	check(PunchAnim.freeze(model, 0.2), kind .. ": se puede congelar")
	PunchAnim._step(1 / 60)
	local frozen = world(model)
	local fTip = (frozen.RightHand * CFrame.new(0, -R15Rig.Sizes.RightHand.Y / 2, 0)).Position
	check((fTip - R15Rig.tip(solve("Jab", PunchAnim.Moves.Jab.Impact), "RightHand")).Magnitude < 0.05, kind .. ": congelado en la extensión máxima del directo")
	check(PunchAnim.untilImpact(model) == 0, kind .. ": congelado, el impacto ya ha llegado")
	at(model, 3)
	-- Antes del impacto: espera a llegar
	PunchAnim.play(model, "Kick")
	check(PunchAnim.untilImpact(model) > 0.15, ("%s: al empezar la patada falta %.2f s para el impacto"):format(kind, PunchAnim.untilImpact(model)))
	at(model, 3)

	-- Otra capa no lo pisa: la animación de correr en el brazo se apaga durante el golpe
	PunchAnim.play(model, "Jab")
	at(model, 0.3)
	Layers.step(1 / 60, os.clock())
	local shoulder = Joints.find(model, "RightShoulder")
	check(amount(shoulder.Transform) < 0.05, ("%s: durante el golpe el brazo no se balancea con la animación de andar (%.3f)"):format(kind, amount(shoulder.Transform)))
	at(model, 3)
	Layers.step(1 / 60, os.clock())
	check(amount(shoulder.Transform:ToObjectSpace(swing)) < 1e-3, kind .. ": al acabar, la animación de andar vuelve a mover el brazo")
	check(not PunchAnim.busy(model), kind .. ": al acabar PunchAnim deja el cuerpo")
	PunchAnim.hold(model, "Guard", true)
	PunchAnim._step(1 / 60)
	check(PunchAnim.busy(model), kind .. ": con la guardia puesta PunchAnim lleva el cuerpo (ActorLife no escribe)")
	PunchAnim.hold(model, "Guard", false)
	for _ = 1, 120 do
		PunchAnim._step(1 / 60)
	end
	check(allBack(original) and not PunchAnim.busy(model), kind .. ": sin guardia, todo en su sitio")
	-- Se pierde el «apagar» de la guardia de un NPC: caduca sola (no se queda busy para siempre)
	PunchAnim.hold(model, "Guard", true)
	PunchAnim._step(1 / 60)
	model:SetAttribute("Blocking", true)
	PunchAnim._bodyOf(model).WantAt.Guard = os.clock() - PunchAnim.HoldExpiry - 1
	PunchAnim._step(1 / 60)
	check(PunchAnim._bodyOf(model).Want.Guard == true, kind .. ": la guardia de un NPC que sigue con Blocking no caduca")
	model:SetAttribute("Blocking", nil)
	PunchAnim._bodyOf(model).WantAt.Guard = os.clock() - PunchAnim.HoldExpiry - 1
	for _ = 1, 120 do
		PunchAnim._step(1 / 60)
	end
	check(allBack(original) and not PunchAnim.busy(model), ("%s: sin refresco en %d s, la guardia de un NPC se apaga sola y PunchAnim lo suelta"):format(kind, PunchAnim.HoldExpiry))
end

print("Cuerpo R6 (versión simple)")
do
	local model = r6()
	local original = c0s(model)
	local before = world(model)
	check(PunchAnim.play(model, "Jab"), "R6: el directo se puede dar")
	at(model, PunchAnim.Moves.Jab.Impact)
	local arm = world(model)["Right Arm"]
	local fist = (arm * CFrame.new(0, -1, 0)).Position
	check(fist.Z < before["Right Arm"].Position.Z - 1.2, ("R6: el puño sale hacia delante (%.2f)"):format(before["Right Arm"].Position.Z - fist.Z))
	check(fist.Y > 2.5, ("R6: a la altura del pecho (y=%.2f)"):format(fist.Y))
	at(model, 3)
	check(allBack(original), "R6: al acabar todo vuelve a su C0")
end

print("ActorLife no pisa los golpes")
local life = fs.readFile("src/client/Controllers/ActorLife.luau")
local applyAt = life:find("Joints.setC0(J.Neck", 1, true)
local busyAt = life:find("if punchBusy(rig.Model) then", 1, true)
check(busyAt ~= nil and applyAt ~= nil and busyAt < applyAt, "ActorLife deja de escribir C0 mientras PunchAnim trabaja")
check(life:find("if blocking or punchBusy(rig.Model) then", 1, true) ~= nil and life:find("if not joints.Neck or punchBusy(model) then", 1, true) ~= nil, "ActorLife no toma como postura base (Base = C0) la de un cuerpo que PunchAnim está moviendo")
local fx = fs.readFile("src/client/Controllers/CombatFx.luau")
check(fx:find("function CombatFx.swoosh", 1, true) ~= nil and fx:find("Trail", 1, true) ~= nil, "CombatFx: estela del golpe")
local ctrl = fs.readFile("src/client/Controllers/CombatController.luau")
check(ctrl:find("CombatFx.swoosh(character, anim)", 1, true) ~= nil and ctrl:find("PunchAnim.untilImpact(attacker)", 1, true) ~= nil, "CombatController: estela en cada golpe y lo que se ve del golpe, en el impacto")

if failures > 0 then
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
print("✅ Todo correcto")
