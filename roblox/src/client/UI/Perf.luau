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

-- En modo ligero se quitan (solo en esta pantalla) los detalles pequeños de la calle: jardineras,
-- mupis, motos aparcadas, terrazas… (etiqueta LiteDetail, Kit/StreetDetail). Van llegando con la
-- carga por zonas, así que se quitan también al llegar.
function Perf.stripDetails()
	if not Perf.lite then
		return
	end
	local CollectionService = game:GetService("CollectionService")
	local function strip(instance: Instance)
		task.defer(function()
			if instance.Parent then
				instance:Destroy()
			end
		end)
	end
	for _, m in CollectionService:GetTagged("LiteDetail") do
		strip(m)
	end
	CollectionService:GetInstanceAddedSignal("LiteDetail"):Connect(strip)
end

-- Cantidad ajustada (como mínimo `min`)
function Perf.count(n: number, min: number?): number
	return math.max(min or 1, math.floor(n * Perf.scale + 0.5))
end

return Perf
