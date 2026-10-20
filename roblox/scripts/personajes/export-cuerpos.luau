-- Exporta el cuerpo de cada personaje del reparto TAL COMO lo viste el juego (World/Npc.dress sobre un
-- R15 de bloques con la cabeza dinámica de hoy) a JSON, para las vistas previas
-- (scripts/personajes/render.py). Lo que el juego pone con textura (ropa, cara) lo dibuja Python con las
-- PNG de assets/personajes; aquí van las piezas y sus colores, y qué ropa y cara pide CastLook.
--
-- Uso (desde roblox/):  lune run scripts/personajes/export-cuerpos.luau [salida.json]
-- (por defecto scripts/personajes/out/cuerpos.json; la carpeta out/ no se sube)

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")
local FakeRig = require("../lib/FakeRig")
local Color3 = require("@lune/roblox").Color3

L.services.Players = {
	GetPlayers = function()
		return {}
	end,
}
L.services.TweenService = {
	Create = function()
		return { Play = function() end }
	end,
}
L.mock("src/server/World/RoadGuard", {})

local Npc = L.load("src/server/World/Npc")
local Cast = L.load("src/shared/LifeStory/Cast")
local CastLook = L.load("src/shared/LifeStory/CastLook")

local function c255(c: any): { number }
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

local function shapeOf(p: any): string
	if p.ClassName == "WedgePart" then
		return "Wedge"
	end
	if p:IsA("Part") then
		return p.Shape.Name
	end
	return "Block"
end

local out = process.args[1] or "scripts/personajes/out/cuerpos.json"
local bodies = {}
math.randomseed(7)
for _, spec in CastLook.all() do
	if spec.Kind == "Creature" or spec.Kind == "Own" or spec.Kind == "Hondario" then
		continue
	end
	local person = Cast.People[spec.Id]
	local model = FakeRig.build(L.Instance, nil, nil, { DynamicHead = true })
	local variant = if spec.Key == "Familia_Papa" then "NPC.PAPA" elseif spec.Key == "Abu_Tomas" then "NPC.ABU_TOMAS" else nil
	Npc.dress(model, {
		Skin = person.Skin,
		Shirt = person.Shirt,
		Pants = person.Pants,
		Shoes = person.Shoes or Color3.fromRGB(240, 240, 240),
		Hair = person.Hair or (if spec.Key == "Abu_Tomas" or spec.Key == "Abu_Rosa" then Color3.fromRGB(200, 200, 205) else nil),
		LongHair = if spec.Key == "Familia_Mama" or spec.Key == "Abu_Rosa" then true elseif spec.Key == "Familia_Papa" or spec.Key == "Abu_Tomas" then false else person.LongHair == true,
		Backpack = person.Backpack,
		LongSleeves = person.LongSleeves == true,
		Id = spec.Id,
		Variant = variant,
	})
	local parts = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = p.CFrame:GetComponents()
			table.insert(parts, {
				Name = p.Name,
				Body = p.Parent == model and (p.Name ~= "Hair" and p.Name ~= "HairBack" and p.Name ~= "Fringe" and p.Name ~= "Collar" and p.Name ~= "SchoolBackpack"),
				Shape = shapeOf(p),
				Pos = { x, y, z },
				Rot = { r00, r01, r02, r10, r11, r12, r20, r21, r22 },
				Size = { p.Size.X, p.Size.Y, p.Size.Z },
				Color = c255(p.Color),
				Material = p.Material.Name,
				Transparency = p.Transparency,
			})
		end
	end
	bodies[spec.Key] = {
		Parts = parts,
		Scale = if person.Kid then 0.65 elseif person.Teen then 0.85 else 1,
		Shirt = model:GetAttribute("CastShirt"),
		Pants = model:GetAttribute("CastPants"),
		FaceKey = model:GetAttribute("CastFaceKey"),
		ShirtColor = c255(person.Shirt),
		PantsColor = c255(person.Pants),
		Skin = c255(person.Skin),
	}
end
fs.writeFile(out, serde.encode("json", bodies))
local n = 0
for _ in bodies do
	n += 1
end
print(("✅ %s: %d cuerpos"):format(out, n))
