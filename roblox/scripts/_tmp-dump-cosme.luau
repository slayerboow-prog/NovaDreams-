local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")
local Build = L.load("src/server/World/CosmeHouse/Build")
local folder = roblox.Instance.new("Folder")
local site = roblox.CFrame.new(0, 0, 0)
local house = Build.build(folder, site)
local out = {}
for _, d in house:GetDescendants() do
	if d:IsA("BasePart") and d.Transparency < 0.95 then
		local cf = d.CFrame
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local shape = "Block"
		if d:IsA("Part") then shape = d.Shape.Name end
		if d:FindFirstChildOfClass("SpecialMesh") then shape = "Ball" end
		if d:IsA("WedgePart") then shape = "Wedge" end
		table.insert(out, string.format("%s %.2f %.2f %.2f %.2f %.2f %.2f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d %d %d %.2f %s %s",
			shape, cf.Position.X, cf.Position.Y, cf.Position.Z, d.Size.X, d.Size.Y, d.Size.Z,
			r.X, r.Y, r.Z, u.X, u.Y, u.Z, l.X, l.Y, l.Z,
			math.floor(d.Color.R * 255), math.floor(d.Color.G * 255), math.floor(d.Color.B * 255), d.Transparency, d.Material.Name, d.Name))
	end
end
fs.writeFile(process and "x" or "/tmp/claude-0/-home-user-NovaDreams-/44a06df9-b4ba-5b6f-8b58-9ea4de9b91a2/scratchpad/parts.txt", table.concat(out, "\n"))
print(#out)
