-- Prueba de cómo se mueve cada edad (Controllers/AgeMotion) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-agemotion.luau
--
-- Con un personaje R15 de medidas normales comprueba que:
--   * el bebé gateando apoya manos y rodillas en el suelo, sin atravesarlo, con la espalda
--     horizontal y la cabeza levantada delante
--   * al gatear alterna brazo derecho con pierna izquierda
--   * los retoques de cada edad son suaves y el mayor va encorvado hacia delante
--   * a cualquier tamaño (bebé 0.45, niño 0.65…) el cuerpo baja lo justo

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local CFrame, Vector3, Enum = roblox.CFrame, roblox.Vector3, roblox.Enum

local fakeGame = { GetService = function(_, name)
	return { Name = name }
end }
local env = setmetatable({ CFrame = CFrame, Vector3 = Vector3, Enum = Enum, game = fakeGame, workspace = {} }, { __index = getfenv(1) })
local AgeMotion = luau.load(fs.readFile("src/client/Controllers/AgeMotion.luau"), { debugName = "AgeMotion", environment = env })()

local failures = 0
local function check(ok: boolean, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Un R15 normal (tamaño 1): piezas y articulaciones
local function rig(scale: number)
	local function v(x, y, z)
		return Vector3.new(x, y, z) * scale
	end
	local function c(x, y, z)
		return CFrame.new(x * scale, y * scale, z * scale)
	end
	return {
		Sizes = {
			LowerTorso = v(2, 0.4, 1), UpperTorso = v(2, 1.6, 1), Head = v(1.2, 1.2, 1.2),
			RightUpperArm = v(1, 1.169, 1), RightLowerArm = v(1, 1.052, 1), RightHand = v(1, 0.3, 1),
			LeftUpperArm = v(1, 1.169, 1), LeftLowerArm = v(1, 1.052, 1), LeftHand = v(1, 0.3, 1),
			RightUpperLeg = v(1, 1.217, 1), RightLowerLeg = v(1, 1.193, 1), RightFoot = v(1, 0.3, 1),
			LeftUpperLeg = v(1, 1.217, 1), LeftLowerLeg = v(1, 1.193, 1), LeftFoot = v(1, 0.3, 1),
		},
		Joints = {
			Root = { Part0 = "HumanoidRootPart", Part1 = "LowerTorso", C0 = c(0, 0, 0), C1 = c(0, -0.2, 0) },
			Waist = { Part0 = "LowerTorso", Part1 = "UpperTorso", C0 = c(0, 0.2, 0), C1 = c(0, -0.8, 0) },
			Neck = { Part0 = "UpperTorso", Part1 = "Head", C0 = c(0, 0.8, 0), C1 = c(0, -0.6, 0) },
			RightShoulder = { Part0 = "UpperTorso", Part1 = "RightUpperArm", C0 = c(1, 0.563, 0), C1 = c(-0.5, 0.392, 0) },
			LeftShoulder = { Part0 = "UpperTorso", Part1 = "LeftUpperArm", C0 = c(-1, 0.563, 0), C1 = c(0.5, 0.392, 0) },
			RightElbow = { Part0 = "RightUpperArm", Part1 = "RightLowerArm", C0 = c(0, -0.334, 0), C1 = c(0, 0.259, 0) },
			LeftElbow = { Part0 = "LeftUpperArm", Part1 = "LeftLowerArm", C0 = c(0, -0.334, 0), C1 = c(0, 0.259, 0) },
			RightWrist = { Part0 = "RightLowerArm", Part1 = "RightHand", C0 = c(0, -0.501, 0), C1 = c(0, 0.125, 0) },
			LeftWrist = { Part0 = "LeftLowerArm", Part1 = "LeftHand", C0 = c(0, -0.501, 0), C1 = c(0, 0.125, 0) },
			RightHip = { Part0 = "LowerTorso", Part1 = "RightUpperLeg", C0 = c(0.5, -0.2, 0), C1 = c(0, 0.42, 0) },
			LeftHip = { Part0 = "LowerTorso", Part1 = "LeftUpperLeg", C0 = c(-0.5, -0.2, 0), C1 = c(0, 0.42, 0) },
			RightKnee = { Part0 = "RightUpperLeg", Part1 = "RightLowerLeg", C0 = c(0, -0.4, 0), C1 = c(0, 0.35, 0) },
			LeftKnee = { Part0 = "LeftUpperLeg", Part1 = "LeftLowerLeg", C0 = c(0, -0.4, 0), C1 = c(0, 0.35, 0) },
			RightAnkle = { Part0 = "RightLowerLeg", Part1 = "RightFoot", C0 = c(0, -0.55, 0), C1 = c(0, 0.1, 0) },
			LeftAnkle = { Part0 = "LeftLowerLeg", Part1 = "LeftFoot", C0 = c(0, -0.55, 0), C1 = c(0, 0.1, 0) },
		},
	}
end

-- Dónde queda cada pieza con esas transformaciones
local function place(shape, transforms)
	local frames = { HumanoidRootPart = CFrame.new() }
	for _ = 1, 10 do
		for name, j in shape.Joints do
			if frames[j.Part0] and not frames[j.Part1] then
				frames[j.Part1] = frames[j.Part0] * j.C0 * (transforms[name] or CFrame.new()) * j.C1:Inverse()
			end
		end
	end
	return frames
end
local function bottom(shape, frames, part)
	local f, h = frames[part], shape.Sizes[part] / 2
	local low = math.huge
	for _, x in { -h.X, h.X } do
		for _, y in { -h.Y, h.Y } do
			for _, z in { -h.Z, h.Z } do
				low = math.min(low, (f * Vector3.new(x, y, z)).Y)
			end
		end
	end
	return low
end

for _, scale in { 1, 0.45, 0.65 } do
	print(("Gatear (tamaño %.2f)"):format(scale))
	local shape = rig(scale)
	local floor = AgeMotion.lowestPoint(shape, {}) -- de pie, los pies tocan el suelo
	local drop = floor - AgeMotion.lowestPoint(shape, AgeMotion.crawlPose(0, 0, 0))
	local pose = AgeMotion.crawlPose(0, 0, drop)
	local frames = place(shape, pose)
	local tol = 0.3 * scale
	check(math.abs(AgeMotion.lowestPoint(shape, pose) - floor) < 1e-3, "baja justo hasta el suelo")
	check(drop < 0, "el cuerpo baja al ponerse a gatas")
	local handsDown = math.abs(bottom(shape, frames, "RightHand") - floor) < tol and math.abs(bottom(shape, frames, "LeftHand") - floor) < tol
	local kneesDown = math.abs(bottom(shape, frames, "RightLowerLeg") - floor) < tol and math.abs(bottom(shape, frames, "LeftLowerLeg") - floor) < tol
	check(handsDown, "las dos manos apoyadas en el suelo")
	check(kneesDown, "las dos rodillas apoyadas en el suelo")
	local torso = frames.UpperTorso
	check(math.abs(torso.UpVector.Y) < 0.2, "la espalda en horizontal")
	check(torso.UpVector.Z < -0.9, "la cabeza hacia delante (no hacia atrás)")
	check(bottom(shape, frames, "Head") > floor + 0.1 * scale, "la cabeza no toca el suelo")
	check(frames.Head.LookVector.Y > -0.5, "mira al frente, no al suelo")
	-- Gateando: nada atraviesa el suelo y alterna brazo derecho con pierna izquierda
	local through, alternates = false, true
	for step = 0, 40 do
		local phase = step / 40 * math.pi * 2
		local p = AgeMotion.crawlPose(1, phase, drop)
		if AgeMotion.lowestPoint(shape, p) < floor - tol then
			through = true
		end
		local f = place(shape, p)
		if math.abs(math.sin(phase)) > 0.5 then
			local rightHandAhead = f.RightHand.Position.Z < f.LeftHand.Position.Z
			local leftKneeAhead = f.LeftLowerLeg.Position.Z < f.RightLowerLeg.Position.Z
			if rightHandAhead ~= leftKneeAhead then
				alternates = false
			end
		end
	end
	check(not through, "gateando no atraviesa el suelo")
	check(alternates, "brazo derecho con pierna izquierda, y al revés")
end

print("Cada edad")
check(AgeMotion.style("Adulto") == nil and AgeMotion.style("AdultoJoven") == nil, "los adultos se mueven como siempre")
check(AgeMotion.style(nil) == nil and AgeMotion.style(7) == nil, "sin edad no pasa nada")
local a = AgeMotion.scaled(CFrame.Angles(0.4, 0, 0), 0.5)
local ax, _, _ = a:ToEulerAnglesXYZ()
check(math.abs(ax - 0.2) < 1e-4, "reducir el balanceo a la mitad")
check(AgeMotion.scaled(CFrame.new(), 0.5) == CFrame.new(), "sin giro no cambia nada")
for _, stage in { "Bebe", "Nino", "Adolescente", "Mayor" } do
	local style = AgeMotion.style(stage)
	check(style ~= nil, stage .. " tiene su forma de moverse")
	if not style then
		continue
	end
	local sane, jumpy = true, false
	local last = {}
	for step = 0, 3000 do
		local t = step / 60
		local o = style.Offsets(t, (math.sin(t * 0.3) + 1) / 2, (t * 7) % (math.pi * 2))
		for joint, cf in o do
			local x, y, z = cf:ToEulerAnglesXYZ()
			if x ~= x or math.abs(x) > 1 or math.abs(y) > 1 or math.abs(z) > 1 then
				sane = false
			end
			if last[joint] and (last[joint].Position - cf.Position).Magnitude + math.abs(x - last[joint].X) + math.abs(z - last[joint].Z) > 0.1 then
				jumpy = true
			end
			last[joint] = { Position = cf.Position, X = x, Z = z }
		end
	end
	check(sane, stage .. ": giros pequeños")
	check(not jumpy, stage .. ": sin tirones")
end
do
	local shape = rig(1)
	local standing = place(shape, {})
	local old = place(shape, AgeMotion.style("Mayor").Offsets(0, 0, 0))
	check(old.Head.Position.Z < standing.Head.Position.Z - 0.2, "el mayor va encorvado hacia delante")
	check(old.Head.LookVector.Y > -0.25, "…pero mira al frente")
	local floor = AgeMotion.lowestPoint(shape, {})
	local ok = true
	for _, stage in { "Bebe", "Mayor" } do
		local low = AgeMotion.lowestPoint(shape, AgeMotion.style(stage).Offsets(0, 0, 0))
		if math.abs(low - floor) > 0.15 then
			ok = false
		end
	end
	check(ok, "de pie, los pies siguen en el suelo (ni flotan ni se hunden)")
end

print("")
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
