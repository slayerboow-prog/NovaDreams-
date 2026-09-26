-- Perf (cliente): modo ligero para móviles y ordenadores modestos.
-- En móvil/tableta (pantalla táctil sin teclado) o con la calidad gráfica baja, hay menos coches,
-- gente, animales y sombras a la vez. La ciudad es la misma; solo se mueve menos cosa a la vez.

local UserInputService = game:GetService("UserInputService")

local Perf = {}

local function quality(): number?
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	if not ok or level == Enum.SavedQualitySetting.Automatic then
		return nil
	end
	return level.Value
end

-- Pantalla táctil sin teclado: móvil o tableta
Perf.mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local q = quality()
Perf.lite = Perf.mobile or (q ~= nil and q <= 3)
-- Cuánta vida en la calle (1 = todo; en modo ligero, la mitad)
Perf.scale = if Perf.lite then 0.5 else 1

-- Cantidad ajustada (como mínimo `min`)
function Perf.count(n: number, min: number?): number
	return math.max(min or 1, math.floor(n * Perf.scale + 0.5))
end

return Perf
