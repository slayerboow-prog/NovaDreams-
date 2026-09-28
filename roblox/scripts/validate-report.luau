-- Informe del validador de misiones (errores y avisos), sin arrancar el juego.
-- Uso (desde roblox/): lune run scripts/validate-report.luau
local process = require("@lune/process")
local H = require("./lib/StoryHarness")
local report = H.loadModule(H.ROOT .. "/shared/LifeStory/Validate").report()
print(("Errores: %d"):format(#report.Errors))
for _, e in report.Errors do
	print("  ❌ " .. e)
end
print(("Avisos: %d"):format(#report.Warnings))
for _, w in report.Warnings do
	print("  ⚠️ " .. w)
end
local bad = {}
for id in report.BadQuests do
	table.insert(bad, id)
end
table.sort(bad)
print("Misiones que no se activarían: " .. (if #bad == 0 then "ninguna" else table.concat(bad, ", ")))
process.exit(if #report.Errors == 0 then 0 else 1)
