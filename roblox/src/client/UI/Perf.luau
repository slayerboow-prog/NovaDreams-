-- Perf (cliente): modo ligero para móviles y ordenadores modestos, y nivel de calidad gráfica.
-- En móvil/tableta (pantalla táctil sin teclado) o con la calidad gráfica baja, hay menos coches,
-- gente, animales y sombras a la vez. La ciudad es la misma; solo se mueve menos cosa a la vez.
--
-- Nivel gráfico (Bajo / Medio / Alto, shared/Graphics): cuántas farolas dan luz, sombras, efectos de
-- imagen, nubes, charcos… Se elige al entrar según el dispositivo y, en «Auto», se ajusta con los fps
-- de verdad (Perf.startAuto). El jugador lo puede fijar en el menú (Perf.setChoice). Quien dependa
-- del nivel lee Perf.tier() / Perf.tierName() o se apunta a Perf.onTier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Graphics = require(ReplicatedStorage.Shared.Graphics)

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

---------------------------------------------------------------------
-- Nivel gráfico
---------------------------------------------------------------------

local detected: Graphics.TierName = Graphics.detect({ Mobile = Perf.mobile, Quality = q })
local choice: Graphics.Choice = "Auto"
local auto = Graphics.newAuto(detected)
local current: Graphics.TierName = detected
local listeners: { (Graphics.TierName) -> () } = {}

local function setCurrent(name: Graphics.TierName)
	if name == current then
		return
	end
	current = name
	pcall(function()
		game:GetService("Players").LocalPlayer:SetAttribute("GraphicsTier", name)
	end)
	for _, fn in listeners do
		task.spawn(fn, name)
	end
end

-- Nivel de ahora y sus presupuestos
function Perf.tierName(): Graphics.TierName
	return current
end
function Perf.tier(): Graphics.Tier
	return Graphics.tier(current)
end
function Perf.choice(): Graphics.Choice
	return choice
end
-- Avisa cuando cambia el nivel (el que elige el jugador o el automático)
function Perf.onTier(fn: (Graphics.TierName) -> ())
	table.insert(listeners, fn)
end

-- «Auto» o un nivel fijo (menú «✨ Gráficos»)
function Perf.setChoice(new: Graphics.Choice)
	choice = new
	if new == "Auto" then
		auto = Graphics.newAuto(detected)
		setCurrent(detected)
	else
		setCurrent(new :: Graphics.TierName)
	end
end

-- Texto del botón del menú
function Perf.choiceLabel(): string
	if choice == "Auto" then
		return ("✨ Gráficos: Auto (%s)"):format(Graphics.Labels[current])
	end
	return "✨ Gráficos: " .. Graphics.Labels[choice]
end

-- Mide los fps y, en «Auto», sube o baja de nivel (una sola vez, desde Main)
local autoStarted = false
function Perf.startAuto()
	if autoStarted then
		return
	end
	autoStarted = true
	local warmup = 8 -- (los primeros segundos cargan el mapa: no cuentan)
	RunService.Heartbeat:Connect(function(dt)
		if warmup > 0 then
			warmup -= dt
			return
		end
		if choice ~= "Auto" then
			return
		end
		local changed = Graphics.autoStep(auto, dt)
		if changed then
			setCurrent(changed)
		end
	end)
end

-- Cantidad ajustada (como mínimo `min`)
function Perf.count(n: number, min: number?): number
	return math.max(min or 1, math.floor(n * Perf.scale + 0.5))
end

return Perf
