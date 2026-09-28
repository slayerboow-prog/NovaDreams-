-- Prueba: todos los scripts del juego compilan (sin errores de escritura) FUERA de Roblox, con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-compile.luau
--
-- Un solo error de escritura en un módulo del cliente hace que Main.client se pare al cargarlo y
-- el jugador se queda sin interfaz (ni botones, ni mapa, ni comandos). Esta prueba lo detecta.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local bad, total = 0, 0
local function walk(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			walk(path)
		elseif string.match(name, "%.luau$") then
			total += 1
			local ok, err = pcall(luau.compile, fs.readFile(path))
			if not ok then
				bad += 1
				print("  ❌ " .. path .. ": " .. tostring(err))
			end
		end
	end
end
walk("src")
print("")
if bad > 0 then
	print(string.format("❌ %d de %d archivos no compilan", bad, total))
	process.exit(1)
end
print(string.format("✅ Todo correcto (%d archivos compilan)", total))
