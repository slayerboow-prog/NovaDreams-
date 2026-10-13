-- Exporta a Cosme (shared/CosmeLook sobre un R15 de bloques) a JSON para dibujar la hoja de vista previa
-- (scripts/cosme/render.py). Dos posturas: «idle» (brazos caídos) y «hero» (pistola en alto y el
-- aparato de muñeca a la vista, como en la hoja de concepto).
--
-- Uso (desde roblox/):  lune run scripts/cosme/export.luau [salida.json]
-- (por defecto scripts/cosme/out/cosme.json; la carpeta out/ no se sube)

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local L = require("../lib/ModuleLoader")
local FakeRig = require("../lib/FakeRig")

local CFrame = roblox.CFrame
local rad = math.rad
local typeof = roblox.typeof or typeof

local CosmeLook = L.load("src/shared/CosmeLook")
local Cast = L.load("src/shared/LifeStory/Cast")

local POSES = {
	idle = {
		RightShoulder = CFrame.Angles(0, 0, rad(-4)),
		LeftShoulder = CFrame.Angles(0, 0, rad(4)),
	},
	hero = {
		-- la pistola en alto junto a la cabeza (apuntando arriba); el antebrazo izquierdo delante, con la
		-- pantalla del aparato hacia fuera
		RightShoulder = CFrame.Angles(rad(62), 0, rad(-8)),
		RightElbow = CFrame.Angles(rad(72), 0, 0),
		RightWrist = CFrame.Angles(rad(-44), 0, 0),
		LeftShoulder = CFrame.Angles(rad(48), rad(-12), rad(6)),
		LeftElbow = CFrame.Angles(rad(48), 0, 0),
		RightHip = CFrame.Angles(0, 0, rad(-4)),
		LeftHip = CFrame.Angles(rad(-6), 0, rad(5)),
		LeftKnee = CFrame.Angles(rad(-6), 0, 0),
	},
}

local function shapeOf(p: any): string
	if p.ClassName == "WedgePart" then
		return "Wedge"
	end
	if p:IsA("Part") then
		return p.Shape.Name
	end
	return "Block"
end

local function export(pose: { [string]: any }): { any }
	local model = FakeRig.build(L.Instance, pose)
	local person = Cast.People.Cosme
	CosmeLook.dress(model, { Skin = person.Skin, Hair = person.Hair })
	local frames = FakeRig.frames(pose)
	local list = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			-- dónde queda de verdad: la pieza del cuerpo con la postura y, si va soldada, su C0
			local cf = frames[p.Name]
			local weld = p:FindFirstChild("CosmeWeld")
			if weld then
				cf = frames[weld.Part0.Name] * weld.C0
			end
			if cf then
				local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
				table.insert(list, {
					Name = p.Name,
					Body = weld == nil,
					Shape = shapeOf(p),
					Pos = { x, y, z },
					Rot = { r00, r01, r02, r10, r11, r12, r20, r21, r22 },
					Size = { p.Size.X, p.Size.Y, p.Size.Z },
					Color = { math.floor(p.Color.R * 255 + 0.5), math.floor(p.Color.G * 255 + 0.5), math.floor(p.Color.B * 255 + 0.5) },
					Material = p.Material.Name,
					Transparency = p.Transparency,
				})
			end
		end
	end
	return list
end

local out = process.args[1] or "scripts/cosme/out/cosme.json"
local dir = out:match("^(.*)/[^/]+$")
if dir and not fs.isDir(dir) then
	fs.writeDir(dir)
end
local data = { Poses = {} }
for name, pose in POSES do
	data.Poses[name] = export(pose)
end
data.Skin = { math.floor(Cast.People.Cosme.Skin.R * 255 + 0.5), math.floor(Cast.People.Cosme.Skin.G * 255 + 0.5), math.floor(Cast.People.Cosme.Skin.B * 255 + 0.5) }
data.Colors = {}
for key, c in CosmeLook.Colors do
	if typeof(c) == "Color3" then
		data.Colors[key] = { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
	end
end
fs.writeFile(out, serde.encode("json", data))
print(("✅ %s: %d piezas (idle), %d (hero)"):format(out, #data.Poses.idle, #data.Poses.hero))
