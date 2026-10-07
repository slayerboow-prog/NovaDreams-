-- R15Rig (pruebas con Lune): un esqueleto R15 estándar de Roblox (piezas, tamaños, C0 y C1 de las
-- articulaciones del avatar de bloques a escala 1) y su cinemática directa: dónde queda cada pieza en
-- el mundo con una postura de Controllers/PunchAnim encima.
--
--   Part1 = Part0 * C0 * Transform * C1⁻¹   (Transform = identidad: sin animación de Roblox)
--
-- Lo usan scripts/test-punch.luau (que cada golpe llegue al máximo en su impacto, que apunte al
-- frente…) y scripts/audit/poses-golpes.luau (las hojas de dibujos desde 4 lados).

local roblox = require("@lune/roblox")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3

local R15Rig = {}

R15Rig.Sizes = {
	HumanoidRootPart = Vector3.new(2, 2, 1),
	LowerTorso = Vector3.new(2, 0.4, 1),
	UpperTorso = Vector3.new(2, 1.6, 1),
	Head = Vector3.new(1.2, 1.2, 1.2),
	RightUpperArm = Vector3.new(1, 1.17, 1),
	RightLowerArm = Vector3.new(1, 1.05, 1),
	RightHand = Vector3.new(1, 0.3, 1),
	LeftUpperArm = Vector3.new(1, 1.17, 1),
	LeftLowerArm = Vector3.new(1, 1.05, 1),
	LeftHand = Vector3.new(1, 0.3, 1),
	RightUpperLeg = Vector3.new(1, 1.22, 1),
	RightLowerLeg = Vector3.new(1, 1.19, 1),
	RightFoot = Vector3.new(1, 0.3, 1),
	LeftUpperLeg = Vector3.new(1, 1.22, 1),
	LeftLowerLeg = Vector3.new(1, 1.19, 1),
	LeftFoot = Vector3.new(1, 0.3, 1),
}

-- nombre = { pieza de dentro, pieza de fuera, C0, C1 } (en orden: cada pieza de dentro ya está puesta)
R15Rig.Joints = {
	{ "Root", "HumanoidRootPart", "LowerTorso", CFrame.new(0, -1, 0), CFrame.new(0, -0.2, 0) },
	{ "Waist", "LowerTorso", "UpperTorso", CFrame.new(0, 0.2, 0), CFrame.new(0, -0.8, 0) },
	{ "Neck", "UpperTorso", "Head", CFrame.new(0, 0.8, 0), CFrame.new(0, -0.6, 0) },
	{ "RightShoulder", "UpperTorso", "RightUpperArm", CFrame.new(1, 0.56, 0), CFrame.new(-0.5, 0.39, 0) },
	{ "LeftShoulder", "UpperTorso", "LeftUpperArm", CFrame.new(-1, 0.56, 0), CFrame.new(0.5, 0.39, 0) },
	{ "RightElbow", "RightUpperArm", "RightLowerArm", CFrame.new(0, -0.33, 0), CFrame.new(0, 0.26, 0) },
	{ "LeftElbow", "LeftUpperArm", "LeftLowerArm", CFrame.new(0, -0.33, 0), CFrame.new(0, 0.26, 0) },
	{ "RightWrist", "RightLowerArm", "RightHand", CFrame.new(0, -0.5, 0), CFrame.new(0, 0.12, 0) },
	{ "LeftWrist", "LeftLowerArm", "LeftHand", CFrame.new(0, -0.5, 0), CFrame.new(0, 0.12, 0) },
	{ "RightHip", "LowerTorso", "RightUpperLeg", CFrame.new(0.5, -0.2, 0), CFrame.new(0, 0.42, 0) },
	{ "LeftHip", "LowerTorso", "LeftUpperLeg", CFrame.new(-0.5, -0.2, 0), CFrame.new(0, 0.42, 0) },
	{ "RightKnee", "RightUpperLeg", "RightLowerLeg", CFrame.new(0, -0.41, 0), CFrame.new(0, 0.44, 0) },
	{ "LeftKnee", "LeftUpperLeg", "LeftLowerLeg", CFrame.new(0, -0.41, 0), CFrame.new(0, 0.44, 0) },
	{ "RightAnkle", "RightLowerLeg", "RightFoot", CFrame.new(0, -0.55, 0), CFrame.new(0, 0.1, 0) },
	{ "LeftAnkle", "LeftLowerLeg", "LeftFoot", CFrame.new(0, -0.55, 0), CFrame.new(0, 0.1, 0) },
}

-- Dónde queda cada pieza con la postura `pose` (desfase de C0 por articulación). `toJoint(c0, offset)`
-- es como PunchAnim aplica el desfase (PunchAnim._toJoint); si no se da, c0 * offset.
-- La raíz (HumanoidRootPart) está en `root` (por defecto, de pie a 3 studs del suelo mirando a -Z).
function R15Rig.solve(pose: { [string]: any }, toJoint: ((any, any, number) -> any)?, root: any?): { [string]: any }
	local frames = { HumanoidRootPart = root or CFrame.new(0, 3, 0) }
	for _, def in R15Rig.Joints do
		local name, p0, p1, c0, c1 = def[1], def[2], def[3], def[4], def[5]
		local offset = pose[name]
		local joint = if offset then (if toJoint then toJoint(c0, offset, 1) else c0 * offset) else c0
		frames[p1] = frames[p0] * joint * c1:Inverse()
	end
	return frames
end

-- El extremo de una pieza (la punta del puño o del pie: la cara de abajo en sus ejes)
function R15Rig.tip(frames: { [string]: any }, part: string): any
	local size = R15Rig.Sizes[part]
	return (frames[part] * CFrame.new(0, -size.Y / 2, 0)).Position
end

-- ¿El punto está dentro de la pieza (con un margen)?
function R15Rig.inside(frames: { [string]: any }, part: string, point: any, margin: number?): boolean
	local localPoint = frames[part]:PointToObjectSpace(point)
	local size = R15Rig.Sizes[part]
	local m = margin or 0
	return math.abs(localPoint.X) < size.X / 2 - m and math.abs(localPoint.Y) < size.Y / 2 - m and math.abs(localPoint.Z) < size.Z / 2 - m
end

return R15Rig
