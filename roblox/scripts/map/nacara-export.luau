-- Exporta la plaza de prueba de Nácara (World/NacaraBuilder + la gente de Services/NacaraService) para
-- una VISTA PREVIA aproximada con scripts/map/nacara_preview.py. NO es una captura del juego: el agua,
-- la niebla y la luz de Roblox se ven distintas (por eso el dueño hace las capturas de verdad en su
-- móvil: docs/mar/civilizacion-marina.md, «Fase 0 · Plaza de prueba»).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/map/nacara-export.luau SALIDA.json
--   python3 scripts/map/nacara_preview.py SALIDA.json docs/mar/nacara-prueba-vista-previa.png

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local L = require("../lib/ModuleLoader")

local out = process.args[1] or "nacara.json"

local Nacara = L.load("src/shared/Sea/Nacara")
local OceanBiomes = L.load("src/shared/Sea/OceanBiomes")

-- Terreno de mentira (la plaza se allana: el preview dibuja el suelo plano)
local fakeTerrain = {}
function fakeTerrain.FillBlock() end
function fakeTerrain.FillCylinder() end
function fakeTerrain.FillBall() end

-- Un personaje R15 de bloques con las piezas en su sitio (el de Roblox no existe en Lune)
local LAYOUT = {
	UpperTorso = { Vector3.new(2, 1.6, 1), Vector3.new(0, 0.6, 0), "Shirt" },
	LowerTorso = { Vector3.new(2, 0.4, 1), Vector3.new(0, -0.4, 0), "Pants" },
	Head = { Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 2.0, 0), "Skin" },
	LeftUpperArm = { Vector3.new(1, 1.17, 1), Vector3.new(-1.5, 0.8, 0), "Shirt" },
	RightUpperArm = { Vector3.new(1, 1.17, 1), Vector3.new(1.5, 0.8, 0), "Shirt" },
	LeftLowerArm = { Vector3.new(1, 1.05, 1), Vector3.new(-1.5, -0.3, 0), "Skin" },
	RightLowerArm = { Vector3.new(1, 1.05, 1), Vector3.new(1.5, -0.3, 0), "Skin" },
	LeftHand = { Vector3.new(1, 0.3, 1), Vector3.new(-1.5, -1.0, 0), "Skin" },
	RightHand = { Vector3.new(1, 0.3, 1), Vector3.new(1.5, -1.0, 0), "Skin" },
	LeftUpperLeg = { Vector3.new(1, 1.22, 1), Vector3.new(-0.5, -1.2, 0), "Pants" },
	RightUpperLeg = { Vector3.new(1, 1.22, 1), Vector3.new(0.5, -1.2, 0), "Pants" },
	LeftLowerLeg = { Vector3.new(1, 1.19, 1), Vector3.new(-0.5, -2.4, 0), "Pants" },
	RightLowerLeg = { Vector3.new(1, 1.19, 1), Vector3.new(0.5, -2.4, 0), "Pants" },
	LeftFoot = { Vector3.new(1, 0.3, 1), Vector3.new(-0.5, -3.1, 0), "Pants" },
	RightFoot = { Vector3.new(1, 0.3, 1), Vector3.new(0.5, -3.1, 0), "Pants" },
}
L.mock("src/server/World/Npc", {
	create = function(name, parent, cf, look)
		local m = roblox.Instance.new("Model")
		m.Name = name
		local root = roblox.Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 2, 1)
		root.CFrame = cf * CFrame.new(0, 3.2, 0)
		root.Transparency = 1
		root.Parent = m
		for n, spec in LAYOUT do
			local p = roblox.Instance.new("Part")
			p.Name = n
			p.Size = spec[1]
			p.CFrame = root.CFrame * CFrame.new(spec[2])
			p.Color = (look and look[spec[3]]) or Color3.fromRGB(200, 200, 200)
			p.Parent = m
		end
		local hair = roblox.Instance.new("Part")
		hair.Name = "Hair"
		hair.Size = Vector3.new(1.27, 0.43, 1.3)
		hair.CFrame = root.CFrame * CFrame.new(0, 2.45, 0.05)
		hair.Color = (look and look.Hair) or Color3.fromRGB(40, 30, 20)
		hair.Parent = m
		m.PrimaryPart = root
		m.Parent = parent
		return m
	end,
})
L.fakeClasses.ProximityPrompt = function()
	return { Triggered = { Connect = function() end } }
end
L.mock("src/server/Services/DialogueService", { play = function() return true end, bark = function() end })
L.services.Players = { GetPlayers = function() return {} end, PlayerRemoving = { Connect = function() end } }
rawset(L.services.ReplicatedStorage, "MapLandmarks", roblox.Instance.new("Folder"))

local NacaraService = L.load("src/server/Services/NacaraService")
NacaraService.setup(fakeTerrain)

local function color(c: Color3): { number }
	return { c.R, c.G, c.B }
end

local parts = {}
local lights = {}
for _, d in L.workspace:GetDescendants() do
	if d:IsA("BasePart") and d.Transparency < 0.99 then
		local shape = "Block"
		if d:IsA("WedgePart") then
			shape = "Wedge"
		elseif d:FindFirstChildOfClass("SpecialMesh") then
			shape = "Ellipsoid"
		elseif d:IsA("Part") then
			shape = d.Shape.Name
		end
		local cf = d.CFrame
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
		table.insert(parts, {
			Shape = shape,
			Pos = { x, y, z },
			Rot = { r00, r01, r02, r10, r11, r12, r20, r21, r22 },
			Size = { d.Size.X, d.Size.Y, d.Size.Z },
			Color = color(d.Color),
			Material = d.Material.Name,
			Transparency = d.Transparency,
		})
		local light = d:FindFirstChildOfClass("PointLight")
		if light then
			table.insert(lights, { Pos = { x, y, z }, Color = color(light.Color), Range = light.Range, Brightness = light.Brightness })
		end
	end
end

local center = Nacara.centerPosition()
local function looks(night: number)
	local base = OceanBiomes.look("Llanura", 38, nil, night)
	local lit = Nacara.lookNear(base, center + Vector3.new(0, 8, 0))
	return {
		Fog = color(lit.Fog),
		Water = color(lit.Water),
		Ambient = color(lit.Ambient),
		Tint = color(lit.Tint),
		Visibility = lit.Visibility,
		Glow = lit.Glow,
		Exposure = lit.Exposure,
	}
end

local spots = {}
for _, s in Nacara.PhotoSpots do
	local at = Nacara.toWorld(s.At[1], s.At[2], s.At[3])
	local look = Nacara.toWorld(s.Look[1], s.Look[2], s.Look[3])
	table.insert(spots, { Id = s.Id, Name = s.Name, At = { at.X, at.Y, at.Z }, Look = { look.X, look.Y, look.Z } })
end

fs.writeFile(out, serde.encode("json", {
	Parts = parts,
	Lights = lights,
	Center = { center.X, center.Y, center.Z },
	FloorY = Nacara.FloorY,
	Day = looks(0),
	Night = looks(1),
	Spots = spots,
	Dome = { Nacara.domeCenter().X, Nacara.domeCenter().Y, Nacara.domeCenter().Z, Nacara.Dome.Radius },
}))
print(("%d piezas y %d luces -> %s"):format(#parts, #lights, out))
