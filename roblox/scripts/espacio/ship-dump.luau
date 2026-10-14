-- Vuelca las piezas de la nave «Caza» (shared/AirCombat/ShipModel.specs) en JSON para dibujar su vista
-- previa (scripts/espacio/ship_preview.py).
--   lune run scripts/espacio/ship-dump.luau > /tmp/ship.json
local serde = require("@lune/serde")
local Vector3 = require("@lune/roblox").Vector3
local L = require("../lib/ModuleLoader")
local ShipModel = L.load("src/shared/AirCombat/ShipModel")
local out = {}
for _, p in ShipModel.specs("Caza") do
	if (p.Transparency or 0) < 0.99 then
		local cf = p.At
		local corners = {}
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local w = cf * Vector3.new(sx * p.Size.X / 2, sy * p.Size.Y / 2, sz * p.Size.Z / 2)
					table.insert(corners, { w.X, w.Y, w.Z })
				end
			end
		end
		table.insert(out, {
			Name = p.Name,
			Class = p.Class or "Part",
			Shape = p.Shape or "Block",
			Color = { math.floor(p.Color.R * 255), math.floor(p.Color.G * 255), math.floor(p.Color.B * 255) },
			Neon = p.Material == "Neon",
			Glass = p.Material == "Glass",
			Corners = corners,
			Center = { cf.Position.X, cf.Position.Y, cf.Position.Z },
		})
	end
end
print(serde.encode("json", out, false))
