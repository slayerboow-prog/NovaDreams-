-- TouchLayout (cliente): dónde va cada botón táctil de la derecha, alrededor del botón de saltar
-- de Roblox. Todos se colocan aquí para que no se tapen entre ellos ni con el menú de comandos:
--
--     [📷]  [🛡]  [👊]          🪨 (piedras) encima de 🛡
--     [🔦]  [🏃]  [saltar]      📯/🔔 (claxon) en el sitio de 👊: conduciendo no se pelea
--
-- El menú de comandos del móvil va a la izquierda de este grupo (TouchLayout.clusterWidth).
-- Los tamaños siguen al botón de saltar: 70 px en móviles y 120 px en tabletas.

local TouchLayout = {}

type Slot = { X: number, Y: number, Size: number } -- centro, en píxeles desde abajo a la derecha

local camera = workspace.CurrentCamera
local slots: { [string]: Slot } = {}
local width = 0
local placed: { [GuiObject]: string } = {}
local changed = Instance.new("BindableEvent")
TouchLayout.Changed = changed.Event

local function compute()
	local view = camera.ViewportSize
	-- Igual que el botón de saltar de Roblox (TouchJump)
	local small = math.min(view.X, view.Y) <= 500
	local jump = if small then 70 else 120
	local right = if small then 25 else 50
	local bottom = if small then 20 else 90
	local u = jump / 70
	local gap = 12 * u

	local jx, jy = right + jump / 2, bottom + jump / 2
	local punch = { X = jx, Y = jy + jump / 2 + gap + 33 * u, Size = 66 * u }
	local sprint = { X = jx + jump / 2 + gap + 29 * u, Y = jy, Size = 58 * u }
	local guard = { X = sprint.X, Y = punch.Y, Size = 54 * u }
	local side = sprint.X + 29 * u + gap + 22 * u
	slots = {
		Punch = punch,
		Sprint = sprint,
		Guard = guard,
		Flashlight = { X = side, Y = jy, Size = 44 * u },
		Photo = { X = side, Y = punch.Y, Size = 44 * u },
		Stone = { X = guard.X, Y = guard.Y + 27 * u + gap + 28 * u, Size = if small then 50 else 70 },
		Horn = { X = punch.X, Y = punch.Y, Size = if small then 50 else 70 },
	}
	width = side + 22 * u + gap
end

local function apply(object: GuiObject, name: string)
	local slot = slots[name]
	object.AnchorPoint = Vector2.new(0.5, 0.5)
	object.Size = UDim2.fromOffset(slot.Size, slot.Size)
	object.Position = UDim2.new(1, -slot.X, 1, -slot.Y)
	if object:IsA("TextButton") then
		object.TextSize = math.floor(slot.Size * 0.45)
	end
end

-- Coloca un botón redondo en su sitio (y lo recoloca si cambia el tamaño de la pantalla)
function TouchLayout.place(object: GuiObject, name: string)
	placed[object] = name
	apply(object, name)
	object.Destroying:Connect(function()
		placed[object] = nil
	end)
end

-- Posición para ContextActionService:SetPosition (esquina de arriba a la izquierda del botón)
function TouchLayout.casPosition(name: string): UDim2
	local slot = slots[name]
	return UDim2.new(1, -slot.X - slot.Size / 2, 1, -slot.Y - slot.Size / 2)
end

-- Ancho que ocupa el grupo de botones desde el borde derecho (px)
function TouchLayout.clusterWidth(): number
	return width
end

compute()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	compute()
	for object, name in placed do
		apply(object, name)
	end
	changed:Fire()
end)

return TouchLayout
