-- Vuelca en JSON un grupo de asteroides del Cinturón de Hierro con la forma del juego
-- (shared/Cosmos/Asteroids.shape) para dibujarlos en Blender (scripts/espacio/asteroides_blender.py):
-- el antes (bolas), el después hecho con piezas (lo que se ve sin subir nada), la malla de Blender y
-- uno rompiéndose (trozos de Asteroids.split a los 0,8 s).
--   lune run scripts/espacio/asteroides-dump.luau > /tmp/asteroides.json
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local L = require("../lib/ModuleLoader")
local Asteroids = L.load("src/shared/Cosmos/Asteroids")
local Zone = L.load("src/shared/Cosmos/Zone")

local function cfList(cf: any): { number }
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return { x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 }
end

local function color(c: any): { number }
	return { c.R, c.G, c.B }
end

local function pieces(id: string, radius: number, ore: string, field: string, world: any, stage: number): { any }
	local out = {}
	local sh = Asteroids.shape(id, radius, ore, field)
	for _, p in sh.Pieces do
		local tr = p.Transparency
		if p.Role == "Crack" then
			tr = if (p.Stage or 9) <= stage then 0.1 else 1
		end
		if tr < 0.99 then
			table.insert(out, {
				K = p.Kind, Role = p.Role, Size = { p.Size.X, p.Size.Y, p.Size.Z }, CF = cfList(world * p.CFrame),
				Color = color(p.Color), Mat = p.Material.Name, Tr = tr,
			})
		end
	end
	return out, sh.Variant
end

-- El grupo: el asteroide con más vecinos cerca (y esos vecinos) del Cinturón de Hierro
local field = {}
for _, r in Zone.rocks() do
	if r.Field == "Hierro" then
		table.insert(field, r)
	end
end
local best, bestN = field[1], 0
for _, r in field do
	local n = 0
	for _, o in field do
		if (o.Center - r.Center).Magnitude < 420 then
			n += o.Radius
		end
	end
	if n > bestN then
		best, bestN = r, n
	end
end
local rocks = {}
local biggest = nil
for _, r in field do
	if (r.Center - best.Center).Magnitude < 420 then
		local world = CFrame.new(r.Center) * Asteroids.baseRotation(r.Id)
		local stage = if #rocks == 1 then 2 else 0 -- (uno dañado: grietas)
		local list, variant = pieces(r.Id, r.Radius, r.Ore, r.Field, world, stage)
		table.insert(rocks, {
			Id = r.Id, Radius = r.Radius, Ore = r.Ore, Center = { r.Center.X, r.Center.Y, r.Center.Z },
			CF = cfList(world), Variant = variant, Pieces = list, Stage = stage,
		})
		if not biggest or r.Radius > biggest.Radius then
			biggest = r
		end
	end
end
-- Rompiéndose: el más grande, 0,8 s después (trozos que salen) con sus vetas y grietas
local t0 = 100
local kids = Asteroids.split({ Id = biggest.Id, Field = biggest.Field, Center = biggest.Center, Radius = biggest.Radius, Ore = biggest.Ore }, 1, t0, nil, Vector3.new(0, 0, -300), 99)
local frags = {}
for _, k in kids do
	local t = t0 + 1.2
	local world = CFrame.new(Asteroids.posAt(k, t)) * Asteroids.rotAt(k, t)
	local list = pieces(k.Id, k.Radius, k.Ore, k.Field, world, 1)
	table.insert(frags, { Id = k.Id, Radius = k.Radius, Center = { Asteroids.posAt(k, t).X, Asteroids.posAt(k, t).Y, Asteroids.posAt(k, t).Z }, Pieces = list })
end
print(serde.encode("json", { Focus = { best.Center.X, best.Center.Y, best.Center.Z }, Rocks = rocks, Broken = biggest.Id, BrokenRadius = biggest.Radius, BrokenCenter = { biggest.Center.X, biggest.Center.Y, biggest.Center.Z }, Fragments = frags }))
