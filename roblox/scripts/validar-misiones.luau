-- validar-misiones: solo el validador de la historia (shared/LifeStory/Validate), rápido (test-lifestory tarda
-- mucho). lune run scripts/validar-misiones.luau [filtro]
local process = require("@lune/process")
local H = require("./lib/StoryHarness")
local problems = H.loadModule(H.ROOT .. "/shared/LifeStory/Validate").run()
local filter = process.args[1]
local n = 0
for _, p in problems do
	local text = tostring(p)
	if not filter or string.find(text, filter, 1, true) then
		n += 1
		print("  ❌ " .. text)
	end
end
print(if n == 0 then "✅ Validate: sin errores" .. (if filter then " (" .. filter .. ")" else "") else ("❌ %d errores"):format(n))
