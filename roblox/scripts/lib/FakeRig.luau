-- FakeRig (pruebas con Lune): un personaje R15 de bloques como el que crea
-- Players:CreateHumanoidModelFromDescription (que Lune no tiene): las 15 piezas con sus tamaños
-- (lib/R15Rig), puestas con una postura opcional, sus Motor6D, el Humanoid y el Decal «face» de la cabeza.
--
--   local FakeRig = require("./lib/FakeRig")
--   local model = FakeRig.build(Instance, { RightShoulder = CFrame.Angles(1, 0, 0) })
--   FakeRig.frames(pose)  -> { [pieza] = CFrame } (dónde queda cada pieza)

local roblox = require("@lune/roblox")
local R15Rig = require("./R15Rig")

local FakeRig = {}

function FakeRig.frames(pose: { [string]: any }?, root: any?): { [string]: any }
	return R15Rig.solve(pose or {}, nil, root)
end

-- Instance: el Instance que usan los módulos (L.Instance o roblox.Instance)
function FakeRig.build(Instance: any, pose: { [string]: any }?, root: any?): any
	local frames = FakeRig.frames(pose, root)
	local model = Instance.new("Model")
	model.Name = "Rig"
	local parts = {}
	for name, size in R15Rig.Sizes do
		local p = Instance.new(if name == "HumanoidRootPart" or name == "Head" then "Part" else "MeshPart")
		p.Name = name
		p.Size = size
		p.CFrame = frames[name]
		p.Color = roblox.Color3.fromRGB(163, 162, 165)
		if name == "HumanoidRootPart" then
			p.Transparency = 1
			p.Anchored = true
		end
		p.Parent = model
		parts[name] = p
	end
	for _, def in R15Rig.Joints do
		local m = Instance.new("Motor6D")
		m.Name = def[1]
		m.Part0 = parts[def[2]]
		m.Part1 = parts[def[3]]
		m.C0 = def[4]
		m.C1 = def[5]
		m.Parent = parts[def[3]]
	end
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = parts.Head
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = parts.HumanoidRootPart
	return model
end

return FakeRig
