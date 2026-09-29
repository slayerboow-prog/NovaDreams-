-- SpeechBubbles (cliente): bocadillos de cómic encima de cada personaje que habla.
--   * Cada personaje tiene SU bocadillo: si vuelve a hablar, la frase nueva sustituye a la anterior
--     (nunca dos suyos a la vez), y lo que dicen personajes distintos nunca se junta en una caja.
--   * Panel blanco redondeado con pico hacia la cabeza, el nombre pequeño arriba (si lo hay) y el
--     texto partido en líneas con un ancho máximo. Aparece y se va con un fundido; dura según lo largo.
--   * Se ve hasta ~60 studs, algo más pequeño cuanto más lejos y en pantallas pequeñas (móvil).
--   * Si varios hablan cerca, los bocadillos se apilan hacia arriba sin pisarse.
-- Lo usan todos los que hacen hablar a alguien:
--   * el servidor con Npc.say (remoto "Speech": { Speaker, Text, Name?, Seconds? }; sin Seconds, la
--     frase se queda hasta que la quita, con un tope),
--   * la familia, el cole y las frases sueltas de la historia (Controllers/Baby),
--   * las conversaciones (Controllers/DialogueUI), los choques ("¡Eh!", Controllers/Nudge), los
--     animales (Controllers/Wildlife), los peatones (Controllers/Ambient) y la gente de la calle (SoundFx).
-- Las cuentas (quién habla, cuánto dura, cómo se apilan) están en UI/BubbleLayout.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local BubbleLayout = require(script.Parent.BubbleLayout)

local SpeechBubbles = {}

local player = Players.LocalPlayer

local INK = Color3.fromRGB(24, 26, 32)
local PAPER = Color3.fromRGB(255, 255, 255)
local NAME_COLOR = Color3.fromRGB(40, 110, 200)
local FONT = Enum.Font.GothamMedium
local HEAR_DISTANCE = 100 -- las frases del servidor más lejos que esto ni se dibujan

type Visual = {
	Gui: BillboardGui,
	Panel: Frame,
	Stroke: UIStroke,
	Tail: Frame,
	NameLabel: TextLabel,
	TextLabel: TextLabel,
	W: number,
	H: number,
	Offset: number,
	Lift: number,
	OnScreen: boolean,
	TypeStart: number?,
	TypeSpeed: number?,
	Graphemes: number,
}

local book = BubbleLayout.book()
local visuals: { [Instance]: Visual } = {}
local listeners: { (Instance, string, string) -> () } = {}
local loop: RBXScriptConnection? = nil
local lastStep: number? = nil
local held: { [Instance]: boolean } = {} -- frases de conversación (las mueve DialogueUI, no ActorLife)

---------------------------------------------------------------------
-- Quién habla y dónde se pone el bocadillo
---------------------------------------------------------------------

-- La clave de cada personaje: el modelo (su cabeza cuenta como él) o la pieza suelta (un animal…)
function SpeechBubbles.keyOf(speaker: Instance?): Instance?
	if typeof(speaker) ~= "Instance" then
		return nil
	end
	local s = speaker :: Instance
	if s:IsA("Model") then
		return s
	end
	if s:IsA("BasePart") then
		local parent = s.Parent
		if s.Name == "Head" and parent and parent:IsA("Model") then
			return parent
		end
		return s
	end
	return nil
end

local function anchorOf(key: Instance): (BasePart?, number)
	if key:IsA("BasePart") then
		return key, key.Size.Y / 2 + 0.5
	end
	local head = key:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head, head.Size.Y / 2 + 0.55
	end
	local model = key :: Model
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if part then
		return part, part.Size.Y / 2 + 1.2
	end
	return nil, 0
end

---------------------------------------------------------------------
-- Dibujo
---------------------------------------------------------------------

local function measure(text: string, name: string?): (number, number)
	local inner = BubbleLayout.MaxWidth - BubbleLayout.PadX * 2
	local ok, bounds = pcall(function()
		return TextService:GetTextSize(text, BubbleLayout.TextSize, FONT, Vector2.new(inner, 2000))
	end)
	if ok and typeof(bounds) == "Vector2" and bounds.X > 0 then
		return BubbleLayout.sizeFor(bounds.X + 4, bounds.Y + 2, name)
	end
	return BubbleLayout.estimate(text, name)
end

local function make(key: Instance, anchor: BasePart, offset: number): Visual
	local gui = Instance.new("BillboardGui")
	gui.Name = "SpeechBubble"
	gui.Adornee = anchor
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = BubbleLayout.MaxDistance
	gui.ResetOnSpawn = false
	gui.ClipsDescendants = false
	gui.Active = false
	gui.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	gui.Size = UDim2.fromOffset(BubbleLayout.MaxWidth, 200)

	local tail = Instance.new("Frame")
	tail.Name = "Tail"
	tail.AnchorPoint = Vector2.new(0.5, 0.5)
	tail.Rotation = 45
	tail.BackgroundColor3 = PAPER
	tail.BorderSizePixel = 0
	tail.ZIndex = 3
	tail.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.BackgroundColor3 = PAPER
	panel.BorderSizePixel = 0
	panel.ZIndex = 2
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = INK
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = panel

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Speaker"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = NAME_COLOR
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 4
	nameLabel.Parent = panel

	local label = Instance.new("TextLabel")
	label.Name = "Line"
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextColor3 = INK
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 4
	label.Parent = panel

	local ok = pcall(function()
		gui.Parent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
	end)
	if not ok then
		gui.Parent = nil
	end
	return {
		Gui = gui,
		Panel = panel,
		Stroke = stroke,
		Tail = tail,
		NameLabel = nameLabel,
		TextLabel = label,
		W = BubbleLayout.MaxWidth,
		H = 40,
		Offset = offset,
		Lift = 0,
		OnScreen = false,
		Graphemes = -1,
	}
end

local function drop(key: Instance)
	local v = visuals[key]
	held[key] = nil
	if v then
		visuals[key] = nil
		v.Gui:Destroy()
	end
end

-- Coloca todo según la escala (s), cuánto sube (lift) y la opacidad (a)
local function apply(v: Visual, hasName: boolean, s: number, lift: number, a: number)
	local w, h, tail = v.W * s, v.H * s, BubbleLayout.Tail * s
	local padX, padY = BubbleLayout.PadX * s, BubbleLayout.PadY * s
	local nameH = if hasName then (BubbleLayout.NameSize + 2) * s else 0
	-- La billboard está centrada en el punto de encima de la cabeza: el pico acaba en el centro
	v.Gui.Size = UDim2.fromOffset(math.ceil(w + 6), math.ceil(2 * (h + tail + lift + 4)))
	v.Panel.Size = UDim2.fromOffset(w, h)
	v.Panel.Position = UDim2.new(0.5, 0, 0.5, -tail - lift)
	v.Tail.Size = UDim2.fromOffset(tail * 1.5, tail * 1.5)
	v.Tail.Position = UDim2.new(0.5, 0, 0.5, -tail - lift)
	v.NameLabel.Visible = hasName
	v.NameLabel.Position = UDim2.fromOffset(padX, padY)
	v.NameLabel.Size = UDim2.new(1, -padX * 2, 0, BubbleLayout.NameSize * s)
	v.NameLabel.TextSize = math.max(8, math.floor(BubbleLayout.NameSize * s + 0.5))
	v.TextLabel.Position = UDim2.fromOffset(padX, padY + nameH)
	v.TextLabel.Size = UDim2.new(1, -padX * 2, 1, -(padY * 2 + nameH))
	v.TextLabel.TextSize = math.max(9, math.floor(BubbleLayout.TextSize * s + 0.5))
	local clear = 1 - a
	v.Panel.BackgroundTransparency = clear
	v.Tail.BackgroundTransparency = clear
	v.Stroke.Transparency = 1 - a * 0.55
	v.TextLabel.TextTransparency = clear
	v.NameLabel.TextTransparency = clear
end

local function step()
	local now = os.clock()
	for _, key in BubbleLayout.sweep(book, now) do
		drop(key)
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local eye = camera.CFrame.Position
	local viewportHeight = camera.ViewportSize.Y
	local items = {}
	local state: { [Instance]: { S: number, A: number } } = {}
	for key, entry in book.Entries do
		local anchor, offset = anchorOf(key)
		if not key.Parent or not anchor then
			book.Entries[key] = nil
			drop(key)
			continue
		end
		local v = visuals[key]
		if not v or not v.Gui.Parent then
			if v then
				v.Gui:Destroy()
			end
			v = make(key, anchor, offset)
			visuals[key] = v
		end
		local vv = v :: Visual
		if vv.Gui.Adornee ~= anchor then
			vv.Gui.Adornee = anchor
		end
		if vv.Offset ~= offset then
			vv.Offset = offset
			vv.Gui.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
		end
		local point = anchor.Position + Vector3.new(0, offset, 0)
		local distance = (point - eye).Magnitude
		vv.OnScreen = false
		if distance > BubbleLayout.MaxDistance then
			vv.Gui.Enabled = false
			continue
		end
		local a, pop = BubbleLayout.alpha(entry, now)
		local s = BubbleLayout.scale(distance, viewportHeight) * pop
		local screen, visible = camera:WorldToViewportPoint(point)
		if visible and screen.Z > 0 then
			table.insert(items, { Id = key, X = screen.X, Y = screen.Y, W = vv.W * s, H = (vv.H + BubbleLayout.Tail) * s, Depth = distance })
		else
			vv.Gui.Enabled = false
		end
		state[key] = { S = s, A = a }
	end
	-- Solo los más cercanos (una plaza llena de gente no se llena de bocadillos)
	table.sort(items, function(x, y)
		return x.Depth < y.Depth
	end)
	while #items > BubbleLayout.MaxVisible do
		local extra = table.remove(items) :: any
		visuals[extra.Id].Gui.Enabled = false
	end
	local lifts = BubbleLayout.stack(items)
	local dt = math.min(0.1, now - (lastStep or now))
	lastStep = now
	for _, item in items do
		local key = item.Id
		local v = visuals[key]
		local entry = book.Entries[key]
		local st = state[key]
		v.Gui.Enabled = true
		v.OnScreen = true
		local target = lifts[key] or 0
		v.Lift = if math.abs(target - v.Lift) < 0.5 then target else v.Lift + (target - v.Lift) * math.min(1, dt * 14)
		apply(v, entry.Name ~= nil and entry.Name ~= "", st.S, v.Lift, st.A)
		-- Escribiéndose letra a letra (conversaciones)
		local shown = -1
		if v.TypeStart and v.TypeSpeed then
			shown = math.floor((now - v.TypeStart) * v.TypeSpeed)
			if shown >= (utf8.len(entry.Text) or #entry.Text) then
				shown = -1
				v.TypeStart = nil
			end
		end
		if shown ~= v.Graphemes then
			v.Graphemes = shown
			v.TextLabel.MaxVisibleGraphemes = shown
		end
	end
	if next(book.Entries) == nil and loop then
		loop:Disconnect()
		loop = nil
		lastStep = nil
	end
end

local function ensureLoop()
	if not loop then
		loop = RunService.RenderStepped:Connect(function()
			local ok, err = pcall(step)
			if not ok then
				warn("[SpeechBubbles] " .. tostring(err))
			end
		end)
	end
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------

-- Alguien dice algo. speaker: su modelo, su cabeza o una pieza (un animal).
-- opts: Name (nombre pequeño arriba), Seconds (duración; si no, según lo largo),
--       Sticky (hasta que se quite, con tope), Hold (hasta que se quite, sin tope),
--       Typing (letras por segundo: se escribe poco a poco), NameColor, Source ("Server"/"Local").
-- Devuelve si se ha podido poner (false si el personaje no está en tu mundo).
function SpeechBubbles.show(speaker: Instance?, text: string, opts: { [string]: any }?): boolean
	local key = SpeechBubbles.keyOf(speaker)
	if not key or not key.Parent or text == nil or text == "" then
		return false
	end
	local anchor, offset = anchorOf(key)
	if not anchor then
		return false
	end
	local o = opts or {}
	local now = os.clock()
	local entry, changed = BubbleLayout.put(book, key, text, now, {
		Name = o.Name,
		Seconds = if o.Hold then math.huge else o.Seconds,
		Sticky = o.Sticky,
	})
	held[key] = if o.Hold then true else nil
	local v = visuals[key]
	if not v or not v.Gui.Parent then
		v = make(key, anchor, offset)
		visuals[key] = v
	end
	local vv = v :: Visual
	if changed or vv.TextLabel.Text ~= text then
		vv.W, vv.H = measure(text, entry.Name)
		vv.TextLabel.Text = text
	end
	vv.NameLabel.Text = entry.Name or ""
	vv.NameLabel.TextColor3 = o.NameColor or NAME_COLOR
	if o.Typing and changed then
		vv.TypeStart, vv.TypeSpeed = now, o.Typing
		vv.Graphemes = 0
		vv.TextLabel.MaxVisibleGraphemes = 0
	elseif changed then
		vv.TypeStart = nil
	end
	ensureLoop()
	for _, fn in listeners do
		task.spawn(pcall, fn, key, text, o.Source or "Local")
	end
	return true
end

-- Se calla (su bocadillo se va con un fundido)
function SpeechBubbles.hide(speaker: Instance?)
	local key = SpeechBubbles.keyOf(speaker)
	if key then
		BubbleLayout.quiet(book, key, os.clock())
	end
end

-- Termina de escribir de golpe la frase que se estaba escribiendo
function SpeechBubbles.reveal(speaker: Instance?)
	local key = SpeechBubbles.keyOf(speaker)
	local v = key and visuals[key]
	if v then
		v.TypeStart = nil
		v.Graphemes = -1
		v.TextLabel.MaxVisibleGraphemes = -1
	end
end

-- ¿Tiene ahora un bocadillo? (ActorLife: si habla, gesticula; las líneas de conversación no cuentan,
-- ahí ya dice DialogueUI cuándo habla)
function SpeechBubbles.isSpeaking(speaker: Instance?): boolean
	local key = SpeechBubbles.keyOf(speaker)
	return key ~= nil and not held[key] and BubbleLayout.speaking(book, key, os.clock())
end

-- ¿Se está viendo su bocadillo en tu pantalla?
function SpeechBubbles.isOnScreen(speaker: Instance?): boolean
	local key = SpeechBubbles.keyOf(speaker)
	local v = key and visuals[key]
	return v ~= nil and v.OnScreen and v.Gui.Enabled
end

-- ¿Hay algún bocadillo? (en pantalla o a punto de irse)
function SpeechBubbles.count(): number
	local n = 0
	for _ in book.Entries do
		n += 1
	end
	return n
end

-- Avisa cada vez que alguien dice algo (SoundFx pone la voz): fn(personaje, texto, origen)
function SpeechBubbles.onSpoken(fn: (Instance, string, string) -> ())
	table.insert(listeners, fn)
end

-- ¿Está cerca de la cámara? (las frases del servidor de gente lejana no se dibujan)
local function near(key: Instance): boolean
	local anchor = anchorOf(key)
	local camera = workspace.CurrentCamera
	if not anchor or not camera then
		return false
	end
	return (anchor.Position - camera.CFrame.Position).Magnitude < HEAR_DISTANCE
end

function SpeechBubbles.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:WaitForChild("Speech", 60) :: RemoteEvent?
	if not remote then
		warn("[SpeechBubbles] Falta el remoto Speech")
		return
	end
	remote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then
			return
		end
		local key = SpeechBubbles.keyOf(payload.Speaker)
		if not key then
			return -- no está en tu mundo (lejos, sin cargar)
		end
		local text = payload.Text
		if type(text) ~= "string" or text == "" then
			SpeechBubbles.hide(key)
			return
		end
		local seconds = tonumber(payload.Seconds)
		-- Frase con duración: solo si está cerca. Sin duración (se queda): siempre, por si te acercas
		if seconds and not near(key) then
			return
		end
		-- Durante una escena de cámara (cinemática), la calle calla: sus frases sueltas no se pisan
		-- con la escena
		if seconds and game:GetService("Players").LocalPlayer:GetAttribute("InCinematic") then
			return
		end
		SpeechBubbles.show(key, text, {
			Name = if type(payload.Name) == "string" then payload.Name else nil,
			Seconds = seconds,
			Sticky = seconds == nil,
			Source = "Server",
		})
	end)
end

return SpeechBubbles
