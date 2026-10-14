-- FlightStick: la PALANCA táctil de la nave (combate aéreo y espacio; Controllers/AirCombatClient) y
-- de los aviones que se pilotan (Controllers/Flying: tirar hacia ABAJO sube el morro, como un avión de
-- verdad; a los lados alabea y gira). La palanca solo da el vector: qué hace arriba o abajo lo decide
-- cada controlador (la nave: FlightStick.toInput; los aviones: Shared/Flight.stickInput).
--   * (aviones) FlightStick.setCue("Down", "TIRA HACIA ABAJO PARA DESPEGAR"): una flecha que late dentro
--     del aro hacia donde hay que arrastrar y el texto encima; setCue(nil) la quita.
--     FlightStick.setHintText(texto) cambia el «ARRASTRA PARA DIRIGIR» (nil: el de siempre).
--
-- Por qué una propia: antes la nave leía el joystick de andar (Controllers/Joystick). Ese joystick solo
-- existe si el cliente consigue poner DevTouchMovementMode = Scriptable; si no, se queda el joystick de
-- Roblox (invisible hasta tocar) y la nave NO lo leía (ni ControlModule:GetMoveVector): en el móvil del
-- dueño la nave no respondía al joystick. Esta palanca no depende del Humanoid, ni del PlayerModule, ni
-- de DevTouchMovementMode: lee los toques directamente (UserInputService).
--
--   * Dinámica: pon el pulgar en CUALQUIER sitio de la mitad izquierda (debajo de tu estado) y arrastra.
--     El aro aparece donde tocas; arriba sube el morro, abajo lo baja, a los lados gira (la nave se
--     inclina y se nivela sola). Al soltar, recto.
--   * En reposo se ve el aro abajo a la izquierda con «ARRASTRA PARA DIRIGIR» (para que se sepa).
--   * Sin inclinar el móvil (nada de giroscopio). Zona muerta pequeña y respuesta suave en el centro.
--   * Solo en pantallas táctiles; en el ordenador y con mando no aparece.
-- Las cuentas (vector, origen, zona) son puras: scripts/test-aircombat.luau las prueba.

local FlightStick = {}

FlightStick.Radius = 120 -- radio del aro (unidades del lienzo de HudLayout)
FlightStick.Deadzone = 0.08
FlightStick.Curve = 1.35 -- >1: más fino en el centro
FlightStick.Hint = "ARRASTRA PARA DIRIGIR"

---------------------------------------------------------------------
-- Cuentas (puras)
---------------------------------------------------------------------

-- Del dedo (desplazamiento en píxeles desde el centro del aro) al vector de la palanca (-1..1;
-- x a la derecha, y hacia ABAJO como la pantalla), con zona muerta y curva
function FlightStick.vector(offset: Vector2, radius: number, deadzone: number?, curve: number?): Vector2
	local dead = deadzone or FlightStick.Deadzone
	local raw = offset / math.max(radius, 1)
	local m = raw.Magnitude
	if m <= dead then
		return Vector2.zero
	end
	local k = math.clamp((math.min(m, 1) - dead) / (1 - dead), 0, 1) ^ (curve or FlightStick.Curve)
	return raw.Unit * k
end

-- De la palanca a los mandos de la nave: arriba sube el morro (Pitch +), derecha gira (Yaw +)
function FlightStick.toInput(v: Vector2): (number, number)
	return -v.Y, v.X
end

-- Dónde se pone el aro al tocar en `touch`: ahí mismo, pero sin salirse de la zona
function FlightStick.originFor(touch: Vector2, zonePos: Vector2, zoneSize: Vector2, radius: number): Vector2
	local lo = zonePos + Vector2.new(radius, radius)
	local hi = zonePos + zoneSize - Vector2.new(radius, radius)
	if hi.X < lo.X then
		hi = Vector2.new(lo.X, hi.Y)
	end
	if hi.Y < lo.Y then
		hi = Vector2.new(hi.X, lo.Y)
	end
	return Vector2.new(math.clamp(touch.X, lo.X, hi.X), math.clamp(touch.Y, lo.Y, hi.Y))
end

function FlightStick.inside(p: Vector2, pos: Vector2, size: Vector2): boolean
	return p.X >= pos.X and p.Y >= pos.Y and p.X <= pos.X + size.X and p.Y <= pos.Y + size.Y
end

---------------------------------------------------------------------
-- En pantalla
---------------------------------------------------------------------
local gui: ScreenGui? = nil
local zone: Frame? = nil
local ring: Frame? = nil
local knob: Frame? = nil
local hint: TextLabel? = nil
local idlePos: UDim2? = nil
local touch: InputObject? = nil
local origin = Vector2.zero -- (píxeles) centro del aro mientras se toca
local vector = Vector2.zero
local enabled = false
local touches = 0 -- (diagnóstico) cuántas veces se ha usado
local onFirst: (() -> ())? = nil
local cue: { [string]: any }? = nil -- (aviones) la flecha y el texto de la pista
local cueDir: string? = nil
local hintText: string? = nil

local function scale(): number
	local ok, HudLayout = pcall(require, script.Parent.HudLayout)
	if ok then
		local s = HudLayout.scale()
		if type(s) == "number" and s > 0 then
			return s
		end
	end
	return 1
end

local function radiusPx(): number
	return FlightStick.Radius * scale()
end

local function release()
	touch = nil
	vector = Vector2.zero
	if ring and idlePos then
		ring.Position = idlePos
		ring.BackgroundTransparency = 0.55
	end
	if knob then
		knob.Position = UDim2.fromScale(0.5, 0.5)
	end
	if hint then
		hint.Visible = enabled and touches < 3 -- (tras usarla un par de veces ya se sabe)
	end
end

-- ¿Este toque cae encima de un botón (FUEGO, MISIL…)? Entonces no es la palanca
local function overButton(p: Vector2): boolean
	local ok, hit = pcall(function()
		local playerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if not playerGui then
			return false
		end
		for _, obj in playerGui:GetGuiObjectsAtPosition(p.X, p.Y) do
			if obj:IsA("GuiButton") and obj.Visible and not (gui and obj:IsDescendantOf(gui)) then
				return true
			end
		end
		return false
	end)
	return ok and hit == true
end

local function place(p: Vector2)
	local z, r, k = zone, ring, knob
	if not z or not r or not k then
		return
	end
	local s = scale()
	local local_ = (origin - z.AbsolutePosition) / s
	r.Position = UDim2.fromOffset(local_.X, local_.Y)
	local raw = (p - origin) / math.max(radiusPx(), 1)
	if raw.Magnitude > 1 then
		raw = raw.Unit
	end
	k.Position = UDim2.fromScale(0.5 + raw.X * 0.36, 0.5 + raw.Y * 0.36)
	vector = FlightStick.vector(p - origin, radiusPx())
end

local function began(input: InputObject)
	if not enabled or touch or input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local z = zone
	if not z then
		return
	end
	local p = Vector2.new(input.Position.X, input.Position.Y)
	if not FlightStick.inside(p, z.AbsolutePosition, z.AbsoluteSize) or overButton(p) then
		return
	end
	touch = input
	touches += 1
	if touches == 1 and onFirst then
		task.spawn(onFirst)
	end
	origin = FlightStick.originFor(p, z.AbsolutePosition, z.AbsoluteSize, radiusPx())
	if ring then
		ring.BackgroundTransparency = 0.3
	end
	if hint then
		hint.Visible = false
	end
	place(p)
end

local function build(parent: Instance)
	local Theme = require(script.Parent.Theme)
	local HudLayout = require(script.Parent.HudLayout)
	local Icons = require(script.Parent.Icons)
	local create = Theme.create
	local rgb = Color3.fromRGB
	gui = create("ScreenGui", { Name = "FlightStickGui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 4, Enabled = false, Parent = parent })
	HudLayout.scaleGui(gui :: ScreenGui)
	zone = create("Frame", { Name = "Zona", BackgroundTransparency = 1, Parent = gui })
	local d = FlightStick.Radius * 2
	ring = create("Frame", {
		Name = "Palanca",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(d, d),
		BackgroundColor3 = rgb(10, 24, 48),
		BackgroundTransparency = 0.55,
		Parent = zone,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(70, 130, 200), rgb(8, 18, 40)) }),
		create("UIStroke", { Name = "Edge", Color = rgb(120, 230, 255), Thickness = 3, Transparency = 0.1 }),
	})
	-- (con los dibujos del HUD: aro con brillo alrededor, como la referencia; UI/HudArt)
	pcall(function()
		require(script.Parent.HudArt).image(ring :: Frame, "aro_widget", { Name = "AroArte", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.14, 1.14), ImageColor3 = rgb(130, 220, 255), ZIndex = 0 })
	end)
	-- Aro interior y cruz fina (para saber dónde está el centro)
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = ring }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = rgb(120, 230, 255), Thickness = 1.5, Transparency = 0.55 }),
	})
	for _, line in { { UDim2.fromScale(0.9, 0), UDim2.fromOffset(0, 2) }, { UDim2.fromOffset(2, 0), UDim2.fromScale(0, 0.9) } } do
		create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = line[1] + line[2], BackgroundColor3 = rgb(120, 230, 255), BackgroundTransparency = 0.75, BorderSizePixel = 0, Parent = ring })
	end
	-- Flechas: ▲ sube el morro, ▼ lo baja, ◀ ▶ gira
	for _, arrow in { { 0.5, 0.07, -90 }, { 0.5, 0.93, 90 }, { 0.07, 0.5, 180 }, { 0.93, 0.5, 0 } } do
		Icons.chevron({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(arrow[1], arrow[2]),
			Size = UDim2.fromScale(0.09, 0.09),
			Rotation = arrow[3],
			Color = rgb(200, 240, 255),
			Thickness = 3,
			Parent = ring,
		})
	end
	knob = create("Frame", {
		Name = "Pomo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.4, 0.4),
		BackgroundColor3 = rgb(255, 255, 255),
		BackgroundTransparency = 0.15,
		Parent = ring,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(190, 240, 255), rgb(40, 120, 190)) }),
		create("UIStroke", { Color = rgb(220, 250, 255), Thickness = 2 }),
	})
	hint = Theme.label({
		Name = "Ayuda",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 6),
		Size = UDim2.fromOffset(320, 30),
		Text = hintText or FlightStick.Hint,
		TextSize = 24,
		Font = Theme.FontBold,
		TextColor3 = rgb(200, 240, 255),
		TextStrokeTransparency = 0.35,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = ring,
	})
	HudLayout.onChanged(function(layout)
		local zp = layout.Items.FlightZone
		local sp = layout.Items.FlightStick
		if zp and zone then
			HudLayout.apply(zone, zp)
		end
		if sp and zp and ring then
			-- (dentro de la zona: el aro en reposo, relativo a ella)
			local zr = HudLayout.rect(zp, layout.Canvas)
			local sr = HudLayout.rect(sp, layout.Canvas)
			idlePos = UDim2.fromOffset(sr.X + sr.W / 2 - zr.X, sr.Y + sr.H / 2 - zr.Y)
			if not touch then
				ring.Position = idlePos
			end
		end
	end)
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(began)
	UserInputService.InputChanged:Connect(function(input)
		if input == touch then
			place(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == touch then
			release()
		end
	end)
	UserInputService.TouchEnded:Connect(function(input)
		if input == touch then
			release()
		end
	end)
	release()
end

-- (aviones) La pista: flecha que late hacia donde arrastrar ("Down" | "Up" | "Left" | "Right") y un texto
-- encima del aro. nil la quita. Puro en lo que guarda (FlightStick.cue()); lo de la pantalla, si hay aro.
local CUE_POS = { Down = { 0.5, 0.8, 0 }, Up = { 0.5, 0.2, 180 }, Left = { 0.2, 0.5, 90 }, Right = { 0.8, 0.5, -90 } }
function FlightStick.setCue(dir: string?, text: string?)
	if dir ~= nil and CUE_POS[dir] == nil then
		dir = nil
	end
	cueDir = dir
	local r = ring
	if not r then
		return
	end
	if not cue then
		local ok = pcall(function()
			local Theme = require(script.Parent.Theme)
			local rgb = Color3.fromRGB
			local arrow = Theme.label({
				Name = "PistaFlecha",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.42, 0.42),
				Text = "▼",
				TextScaled = true,
				Font = Theme.FontBold,
				TextColor3 = rgb(255, 180, 60),
				TextStrokeTransparency = 0.2,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 6,
				Visible = false,
				Parent = r,
			})
			local label = Theme.label({
				Name = "PistaTexto",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 0, -10),
				Size = UDim2.fromOffset(460, 34),
				Text = "",
				TextSize = 26,
				Font = Theme.FontBold,
				TextColor3 = rgb(255, 210, 120),
				TextStrokeTransparency = 0.15,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 6,
				Visible = false,
				Parent = r,
			})
			cue = { Arrow = arrow, Label = label }
			-- (late: se ve aunque el pulgar esté encima)
			pcall(function()
				local TweenService = game:GetService("TweenService")
				local tween = TweenService:Create(arrow, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.55 })
				tween:Play()
			end)
		end)
		if not ok then
			return
		end
	end
	local c = cue :: { [string]: any }
	local p = if dir then CUE_POS[dir] else nil
	c.Arrow.Visible = p ~= nil
	c.Label.Visible = p ~= nil and text ~= nil and text ~= ""
	if p then
		c.Arrow.Position = UDim2.fromScale(p[1], p[2])
		c.Arrow.Rotation = p[3]
		c.Label.Text = text or ""
	end
end

function FlightStick.cue(): string?
	return cueDir
end

-- (aviones) El texto de debajo del aro en reposo (nil: «ARRASTRA PARA DIRIGIR»)
function FlightStick.setHintText(text: string?)
	hintText = text
	if hint then
		hint.Text = text or FlightStick.Hint
	end
end

-- Se crea una vez (solo en pantallas táctiles). Devuelve si hay palanca.
function FlightStick.init(parent: Instance, firstUse: (() -> ())?): boolean
	if firstUse then
		onFirst = firstUse
	end
	if gui then
		return true
	end
	local ok, err = pcall(build, parent)
	if not ok then
		warn("[AirCombat] No se pudo crear la palanca táctil: " .. tostring(err))
		gui = nil
		return false
	end
	return true
end

function FlightStick.available(): boolean
	return gui ~= nil and gui.Parent ~= nil
end

function FlightStick.setEnabled(on: boolean)
	enabled = on
	if gui then
		gui.Enabled = on
	end
	release()
end

-- Lo que pide la palanca ahora (-1..1; y hacia abajo)
function FlightStick.read(): Vector2
	return if enabled then vector else Vector2.zero
end

function FlightStick.touching(): boolean
	return touch ~= nil
end

-- (diagnóstico y pruebas)
function FlightStick._state(): { [string]: any }
	return { Gui = gui, Zone = zone, Ring = ring, Knob = knob, Enabled = enabled, Touches = touches, Vector = vector }
end
FlightStick._began = began
FlightStick._release = release

return FlightStick
