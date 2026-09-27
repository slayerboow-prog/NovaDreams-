-- Prueba de los botones táctiles del móvil (UI/TouchLayout) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-touchlayout.luau
--
-- En pantallas de móvil típicas (y de tableta) comprueba que los botones que se ven a la vez
-- (a pie, o conduciendo) no se pisan entre ellos, ni al botón de saltar de Roblox, ni a la barra
-- rápida del centro, y que no se salen de la pantalla.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

-- Roblox de mentira: solo lo que usa TouchLayout
local view = { X = 844, Y = 390 }
local fakeUDim2 = {}
function fakeUDim2.new(sx, ox, sy, oy)
	return { sx = sx, ox = ox, sy = sy, oy = oy }
end
local env = {
	game = { GetService = function() return { LocalPlayer = {} } end },
	workspace = { CurrentCamera = { ViewportSize = view } },
	UDim2 = fakeUDim2,
	Vector2 = { new = function(x, y) return { X = x, Y = y } end },
	math = math, table = table, string = string, ipairs = ipairs, pairs = pairs, type = type,
}
local TouchLayout = luau.load(fs.readFile("src/client/UI/TouchLayout.luau"), { debugName = "TouchLayout", environment = env })()

local MODES = {
	["a pie"] = { "Golpear", "Defender", "Correr", "Piedra", "Linterna", "Foto" },
	["conduciendo"] = { "Claxon", "Bajarse", "Sirena", "Acelerar", "Frenar", "FrenoMano" },
}
local HOTBAR_HALF = 160 -- media barra rápida (centrada abajo), aprox.
local HOTBAR_H = 50

for _, screen in { { 844, 390 }, { 667, 375 }, { 926, 428 }, { 1024, 768 }, { 1366, 1024 } } do
	view.X, view.Y = screen[1], screen[2]
	print(("▶ Pantalla %dx%d"):format(view.X, view.Y))
	local small = math.min(view.X, view.Y) <= 500
	local jump = if small then { x = 60, y = 55, r = 35 } else { x = 110, y = 150, r = 60 }
	for mode, names in MODES do
		local circles = {}
		for _, name in names do
			local slot = TouchLayout.slot(name)
			-- centro medido desde abajo a la derecha
			table.insert(circles, { name = name, x = -slot.Position.ox, y = -slot.Position.oy, r = slot.Size / 2 })
		end
		local clash = {}
		for i, a in circles do
			for j = i + 1, #circles do
				local b = circles[j]
				if math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) < a.r + b.r + 2 then
					table.insert(clash, a.name .. "/" .. b.name)
				end
			end
			if math.sqrt((a.x - jump.x) ^ 2 + (a.y - jump.y) ^ 2) < a.r + jump.r + 2 then
				table.insert(clash, a.name .. "/Saltar")
			end
			if a.y - a.r < 0 or a.x - a.r < 0 or a.y + a.r > view.Y or a.x + a.r > view.X then
				table.insert(clash, a.name .. " fuera")
			end
			-- barra rápida: de view.X/2 - HOTBAR_HALF a view.X/2 + HOTBAR_HALF, abajo
			local left = view.X / 2 - HOTBAR_HALF
			if a.y - a.r < HOTBAR_H and view.X - a.x - a.r < view.X / 2 + HOTBAR_HALF and view.X - a.x + a.r > left then
				table.insert(clash, a.name .. "/barra")
			end
		end
		check(#clash == 0, ("Botones %s sin pisarse%s"):format(mode, if #clash > 0 then " (" .. table.concat(clash, ", ") .. ")" else ""))
	end
end

print()
if failures == 0 then
	print("✅ Todo correcto")
else
	print(("❌ %d fallos"):format(failures))
	process.exit(1)
end
