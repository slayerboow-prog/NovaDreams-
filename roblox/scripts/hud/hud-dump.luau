-- Vuelca las zonas del HUD de vuelo (UI/ShipHudLayout) de la nave y del avión en JSON, para las
-- maquetas con los sprites (scripts/hud/hud_fidelidad.py).
--   lune run scripts/hud/hud-dump.luau > /tmp/hud.json
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")
local SHL = L.load("src/client/UI/ShipHudLayout")

local out = {}
for _, vehicle in { "Ship", "Plane" } do
	for _, case in { { 1920, 1080, false }, { 844, 390, true }, { 932, 430, true }, { 640, 360, true } } do
		local l = SHL.compute(roblox.Vector2.new(case[1], case[2]), {
			Touch = case[3],
			Inset = 58,
			Vehicle = vehicle,
			Buttons = if vehicle == "Plane" then SHL.PlaneButtonSlots else nil,
		})
		local zones = {}
		for name, r in l.Zones do
			zones[name] = { r.X, r.Y, r.W, r.H }
		end
		local buttons = {}
		for name, r in l.Buttons do
			buttons[name] = { r.X, r.Y, r.W, r.H }
		end
		table.insert(out, {
			Vehicle = vehicle,
			Size = { case[1], case[2] },
			Touch = case[3],
			Scale = l.Scale,
			Canvas = { l.Canvas.X, l.Canvas.Y },
			Zones = zones,
			Buttons = buttons,
			Stick = if l.Stick then { l.Stick.X, l.Stick.Y, l.Stick.W, l.Stick.H } else nil,
			Slot = l.SlotSize,
			Gap = l.SlotGap,
			Clashes = SHL.clashes(l),
		})
	end
end
print(serde.encode("json", out, false))
