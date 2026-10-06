-- Hoja de dibujos de los golpes (Controllers/PunchAnim) desde 4 lados, sin abrir Roblox.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/audit/poses-golpes.luau            -> scripts/audit/out/poses-golpes.json
--   python3 scripts/audit/dibujar-poses.py              -> scripts/audit/out/<golpe>.png
--
-- Coloca cada pieza de un R15 estándar (scripts/lib/R15Rig) con la postura real de cada golpe en
-- varios instantes (anticipación, impacto, retroceso) y avisa en la consola de lo que se vería mal:
-- un puño o un pie metido en el torso, un golpe que no llega al frente, una rodilla doblada al revés.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local R15Rig = require("../lib/R15Rig")

local CFrame = roblox.CFrame

local Joints = luau.load(fs.readFile("src/shared/Joints.luau"), { debugName = "Joints" })()
local fakeGame = { GetService = function(_, name)
	return { Name = name, Shared = { Joints = Joints } }
end }
local env = setmetatable({ CFrame = CFrame, game = fakeGame, require = function()
	return Joints
end }, { __index = getfenv(1) })
local PunchAnim = luau.load(fs.readFile("src/client/Controllers/PunchAnim.luau"), { debugName = "PunchAnim", environment = env })()

local ORDER = { "Jab", "Cross", "Hook", "Knee", "Elbow", "Kick", "Uppercut", "SpinKick", "Slam", "Charged", "Blast" }

local function partsOf(frames)
	local out = {}
	for name, cf in frames do
		local size = R15Rig.Sizes[name]
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
		table.insert(out, { name = name, pos = { x, y, z }, rot = { r00, r01, r02, r10, r11, r12, r20, r21, r22 }, size = { size.X, size.Y, size.Z } })
	end
	return out
end

local warnings = 0
local function warnIf(bad: boolean, text: string)
	if bad then
		warnings += 1
		print("  ⚠️  " .. text)
	end
end

local out = { moves = {} }
for _, name in ORDER do
	local def = PunchAnim.Moves[name]
	local impact = def.Impact
	local times = {
		{ "Anticipación", impact * 0.4 },
		{ "Impacto", impact },
		{ "Retroceso", impact + (1 - impact) * 0.6 },
	}
	local frames = {}
	for _, item in times do
		local pose = PunchAnim.pose(name, item[2], {})
		local solved = R15Rig.solve(pose, PunchAnim._toJoint)
		table.insert(frames, { label = item[1], t = item[2], parts = partsOf(solved) })
	end
	-- Comprobaciones a lo largo de todo el golpe
	for i = 0, 40 do
		local t = i / 40
		local solved = R15Rig.solve(PunchAnim.pose(name, t, {}), PunchAnim._toJoint)
		for _, hand in { "RightHand", "LeftHand", "RightFoot", "LeftFoot" } do
			local tip = R15Rig.tip(solved, hand)
			warnIf(R15Rig.inside(solved, "UpperTorso", tip, 0.15), ("%s t=%.2f: %s dentro del torso"):format(name, t, hand))
			warnIf(R15Rig.inside(solved, "Head", tip, 0.1), ("%s t=%.2f: %s dentro de la cabeza"):format(name, t, hand))
		end
		for _, side in { "Right", "Left" } do
			-- La rodilla nunca se dobla hacia delante: el pie va detrás de la línea del muslo
			local upper = solved[side .. "UpperLeg"]
			local lower = solved[side .. "LowerLeg"]
			local bend = upper:ToObjectSpace(lower).LookVector
			warnIf(bend.Y > 0.2, ("%s t=%.2f: la rodilla %s se dobla al revés"):format(name, t, side))
		end
	end
	-- En el impacto, la pieza que golpea va por delante del cuerpo (o arriba / abajo)
	local hit = R15Rig.solve(PunchAnim.pose(name, impact, {}), PunchAnim._toJoint)
	local tip = R15Rig.tip(hit, def.Limb)
	local root = hit.HumanoidRootPart.Position
	if def.Reach == "Forward" then
		local ahead = root.Z - tip.Z
		warnIf(ahead < 1.5, ("%s: en el impacto %s no llega al frente (%.2f studs)"):format(name, def.Limb, ahead))
		warnIf(math.abs(tip.X) > 1.6, ("%s: en el impacto %s se va de lado (x=%.2f)"):format(name, def.Limb, tip.X))
	end
	print(("%s: impacto t=%.2f (%.2f s) · %s en x=%.2f y=%.2f delante=%.2f"):format(name, impact, impact * def.Duration, def.Limb, tip.X, tip.Y - root.Y, root.Z - tip.Z))
	table.insert(out.moves, { name = name, duration = def.Duration, impact = impact, frames = frames })
end

if not pcall(fs.readDir, "scripts/audit/out") then
	fs.writeDir("scripts/audit/out")
end
fs.writeFile("scripts/audit/out/poses-golpes.json", serde.encode("json", out))
print(("%d avisos · scripts/audit/out/poses-golpes.json"):format(warnings))
