-- Vuelca las zonas del HUD de los aviones (UI/ShipHudLayout con las opciones del avión: 5 ranuras y los
-- botones MOTOR +, MOTOR − y FRENOS) en JSON para dibujar las maquetas (scripts/avion/plane_hud_mockup.py).
--   lune run scripts/avion/plane-hud-dump.luau > /tmp/plane-layout.json
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local L = require("../lib/ModuleLoader")
local SHL = L.load("src/client/UI/ShipHudLayout")

local out = {}
for _, case in { { 1920, 1080, false }, { 932, 430, true }, { 844, 390, true }, { 640, 360, true } } do
	local l = SHL.compute(roblox.Vector2.new(case[1], case[2]), { Touch = case[3], Inset = 58, Vehicle = "Plane", Buttons = SHL.PlaneButtonSlots })
	local zones = {}
	for name, r in l.Zones do
		zones[name] = { r.X, r.Y, r.W, r.H }
	end
	local buttons = {}
	for name, r in l.Buttons do
		buttons[name] = { r.X, r.Y, r.W, r.H }
	end
	table.insert(out, {
		Size = { case[1], case[2] },
		Touch = case[3],
		Scale = l.Scale,
		Canvas = { l.Canvas.X, l.Canvas.Y },
		Zones = zones,
		Buttons = buttons,
		Stick = if l.Stick then { l.Stick.X, l.Stick.Y, l.Stick.W, l.Stick.H } else nil,
		Slot = l.SlotSize,
		Gap = l.SlotGap,
		Vehicle = "Plane",
		Clashes = SHL.clashes(l),
	})
end
print(serde.encode("json", out, false))
