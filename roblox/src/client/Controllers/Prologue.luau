-- Prologue (cliente): la tarjeta de ayuda del prólogo jugable («El sueño», Misiones/Prologo_Sueno).
--   * Mientras el atributo InPrologue está puesto: abajo en el centro, qué hay que hacer ahora
--     ("Salta la valla de flores") y CÓMO se hace en este dispositivo (teclado o móvil), con el
--     paso ("Paso 3 de 7").
--   * Botón "Saltar prólogo" (dos toques, para no saltarlo sin querer): lo cierra el servidor.
--   * Paso "abre el mapa": avisa al servidor cuando el mapa grande está abierto.
-- No quita el control ni toca la cámara: las escenas (Cinematics) y las conversaciones (DialogueUI)
-- ya los devuelven solas. Aun así, al acabar el prólogo (o si algo falla) se comprueba que la cámara
-- y los controles no se hayan quedado bloqueados.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local Controls = require(script.Parent.Controls)
local Cinematics = require(script.Parent.Cinematics)
local MapUI = require(script.Parent.MapUI)

local create = Theme.create
local C = Theme.Colors

local Prologue = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent? = nil
local gui: ScreenGui? = nil
local card: Frame? = nil
local labels: { [string]: TextLabel } = {}
local skipButton: TextButton? = nil
local tracked: { [string]: any }? = nil
local skipArmed = 0 -- os.clock() del primer toque en "Saltar" (hay que tocar otra vez)
local lastMapPing = 0

-- ¿Móvil? (pantalla táctil sin teclado)
function Prologue.isTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- La ayuda que toca en este dispositivo
function Prologue.hintFor(hint: { [string]: any }?, touch: boolean): string
	if type(hint) ~= "table" then
		return ""
	end
	local line = if touch then (hint.Touch or hint.Pc) else (hint.Pc or hint.Touch)
	return if type(line) == "string" then line else ""
end

local function active(): boolean
	return player:GetAttribute("InPrologue") == true
end

-- Deja la cámara y los controles como deben estar fuera de una escena (por si algo se quedó a medias)
function Prologue.restore()
	if Cinematics.isOnScreen() or player:GetAttribute("InDialogue") then
		return -- la escena o la conversación los devuelven ellas al terminar
	end
	pcall(Controls.enable, "Prologo")
	pcall(Controls.enable, "Dialogo") -- (sin conversación abierta, nadie debe tener el control por ella)
	pcall(function()
		local camera = workspace.CurrentCamera
		if camera and camera.CameraType == Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Custom
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end
	end)
end

local function render()
	if not gui or not card then
		return
	end
	local show = active() and tracked ~= nil and tracked.QuestId == "Prologo_Sueno"
	-- (nunca encima de una escena de cine: antes la tarjeta del objetivo salía en mitad de ella)
	gui.Enabled = active() and not Cinematics.isOnScreen() and not player:GetAttribute("InCinematic")
	card.Visible = show
	if not show or not tracked then
		return
	end
	local step = if tracked.StepNum and tracked.StepTotal and tracked.StepNum > 0
		then " · " .. Strings.get("PROLOGUE.STEP", { n = tracked.StepNum, total = tracked.StepTotal })
		else ""
	labels.Banner.Text = Strings.get("PROLOGUE.BANNER") .. step
	labels.Goal.Text = Strings.get(tracked.TextKey or "")
	local hint = Prologue.hintFor(tracked.Hint, Prologue.isTouch())
	labels.Hint.Text = if hint ~= "" then (if Prologue.isTouch() then "👆 " else "⌨️ ") .. hint else ""
	labels.Hint.Visible = hint ~= ""
end

local function resetSkip()
	skipArmed = 0
	if skipButton then
		skipButton.Text = Strings.get("PROLOGUE.SKIP")
	end
end

local function askSkip()
	if not Remote then
		return
	end
	if os.clock() - skipArmed > 3 then
		skipArmed = os.clock()
		if skipButton then
			skipButton.Text = Strings.get("PROLOGUE.SKIP_SURE")
		end
		task.delay(3.2, function()
			if os.clock() - skipArmed >= 3 then
				resetSkip()
			end
		end)
		return
	end
	resetSkip()
	-- Se pide al servidor (y se repite un par de veces por si el toque se pierde)
	task.spawn(function()
		for _ = 1, 4 do
			if not active() or not Remote then
				break
			end
			Remote:FireServer("Prologue", "Skip")
			task.wait(1.2)
		end
	end)
end
Prologue.askSkip = askSkip

local function build()
	gui = create("ScreenGui", {
		Name = "PrologueHints",
		ResetOnSpawn = false,
		DisplayOrder = 9,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local touch = Prologue.isTouch()
	card = Theme.panel({
		Name = "HintCard",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, if touch then -96 else -84),
		Size = UDim2.new(0.5, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	local c = card :: Frame
	create("UISizeConstraint", { MinSize = Vector2.new(300, 0), MaxSize = Vector2.new(460, 400), Parent = c })
	Theme.padding(8).Parent = c
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = c })
	-- Fila de arriba: "✨ Prólogo · Paso 2 de 7" y el botón de saltar
	local top = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = 21, Parent = c })
	labels.Banner = Theme.label({ Size = UDim2.new(1, -128, 1, 0), TextSize = 12, TextColor3 = C.Gold, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 21, Parent = top })
	skipButton = Theme.button({
		Name = "Skip",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(124, 24),
		Text = Strings.get("PROLOGUE.SKIP"),
		TextSize = 12,
		ZIndex = 22,
		Parent = top,
	});
	(skipButton :: TextButton).Activated:Connect(askSkip)
	labels.Goal = Theme.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 17, Font = Theme.FontBold, TextWrapped = true, LayoutOrder = 2, ZIndex = 21, Parent = c })
	labels.Hint = Theme.label({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 14, TextColor3 = C.Accent, TextWrapped = true, LayoutOrder = 3, ZIndex = 21, Parent = c })
end

local function onPrologueChanged()
	if active() then
		resetSkip()
	else
		tracked = nil
		Prologue.restore()
	end
	render()
end

function Prologue.init()
	build()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LifeStory") :: RemoteEvent
	;(Remote :: RemoteEvent).OnClientEvent:Connect(function(kind: string, payload: any)
		if kind == "State" and type(payload) == "table" then
			tracked = payload.Tracked
			render()
		end
	end)
	player:GetAttributeChangedSignal("InCinematic"):Connect(function()
		render()
		task.delay(1.5, render) -- (cuando acaba de fundirse la escena)
	end)
	player:GetAttributeChangedSignal("InPrologue"):Connect(function()
		local ok, err = pcall(onPrologueChanged)
		if not ok then
			warn("[Prologue] " .. tostring(err))
			pcall(Prologue.restore)
		end
	end)
	-- Paso "abre el mapa": en cuanto el mapa grande está abierto, se avisa (una vez por segundo)
	task.spawn(function()
		while true do
			task.wait(0.4)
			if active() and tracked and tracked.Beat == "Map" and Remote then
				local ok, open = pcall(MapUI.isOpen)
				if ok and open and os.clock() - lastMapPing > 1 then
					lastMapPing = os.clock()
					Remote:FireServer("Prologue", "MapOpened")
				end
			end
		end
	end)
	onPrologueChanged()
end

return Prologue
