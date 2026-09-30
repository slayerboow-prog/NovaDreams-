-- TesterPanel: panel «Modo pruebas» (solo para el dueño del juego y los testers de Config.Testers).
--
--   TesterPanel.toggle()  abre o cierra el panel (lo puede llamar un botón del menú)
--   TesterPanel.open() / TesterPanel.close() / TesterPanel.isTester()
--   Chat: /pruebas (lo atiende el servidor, TesterService, y le manda abrir el panel)
--
-- El cliente solo pide; quién es tester y lo que se hace lo decide SIEMPRE el servidor. A un jugador
-- normal el panel no se le abre (no tiene el atributo Tester y el servidor no le contesta).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Dialog = require(script.Parent.Dialog)

local create = Theme.create
local C = Theme.Colors
local H = Theme.Hud

local TesterPanel = {}

local player = Players.LocalPlayer
local NAME = "TesterPanel"
local ON = Color3.fromRGB(0, 150, 90)

local remote: RemoteEvent? = nil
local window: Frame? = nil
local state: { [string]: any }? = nil
local refreshers: { () -> () } = {}

local STAGE_NAMES = {
	Nino = "🧒 Niño",
	Adolescente = "🧑 Adolescente",
	AdultoJoven = "🎓 Universidad",
	Adulto = "💼 Adulto",
	Mayor = "👴 Mayor",
}

function TesterPanel.isTester(): boolean
	return player:GetAttribute("Tester") == true
end

local function send(kind: string, a: any?, b: any?)
	if remote then
		remote:FireServer(kind, a, b)
	end
end

function TesterPanel.close()
	if window and window.Parent then
		window:Destroy()
	end
	window = nil
	table.clear(refreshers)
end

function TesterPanel.isOpen(): boolean
	return window ~= nil and window.Parent ~= nil
end

-- Filo cian que brilla (como los paneles del HUD) sobre la ventana de Dialog
local function glow(frame: Frame)
	frame.BackgroundColor3 = H.Navy
	frame.BackgroundTransparency = 0.18
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = H.Glow
		stroke.Thickness = 2
		stroke.Transparency = 0.05
	end
	Theme.halo(frame, H.Glow, 8, 10)
end

local function build()
	local frame, content = Dialog.window(NAME, "🧪 Modo pruebas", Vector2.new(500, 600))
	window = frame
	table.clear(refreshers)
	glow(frame)
	frame.Destroying:Connect(function()
		if window == frame then
			window = nil
			table.clear(refreshers)
		end
	end)

	local list = create("ScrollingFrame", {
		Name = "List",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = if Theme.isTouch() then 8 else 5,
		ScrollBarImageColor3 = H.Glow,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	create("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = list })

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local function section(text: string): TextLabel
		return Theme.label({
			Size = UDim2.new(1, 0, 0, 26),
			Text = text,
			Font = Theme.FontBold,
			TextSize = 16,
			TextColor3 = H.Glow,
			LayoutOrder = nextOrder(),
			Parent = list,
		})
	end
	local function note(text: string)
		Theme.label({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = text,
			TextSize = 13,
			TextColor3 = C.Muted,
			TextWrapped = true,
			LayoutOrder = nextOrder(),
			Parent = list,
		})
	end
	local function button(parent: Instance, text: string, onClick: () -> (), layoutOrder: number?): TextButton
		local b = Theme.button({
			Size = UDim2.new(1, 0, 0, 46),
			Text = text,
			TextSize = 16,
			TextWrapped = true,
			BackgroundColor3 = H.NavyLight,
			LayoutOrder = layoutOrder or nextOrder(),
			Parent = parent,
		})
		Theme.touchText(b, 16)
		b.Activated:Connect(onClick)
		return b
	end
	-- Rejilla de botones de dos columnas (táctil: botones grandes)
	local function grid(): Frame
		local g = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
			Parent = list,
		})
		create("UIGridLayout", {
			CellSize = UDim2.new(0.5, -4, 0, 46),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = g,
		})
		return g
	end
	local function toggle(key: string, label: string)
		local b = button(list, "", function()
			send("Toggle", key)
		end)
		local function refresh()
			local on = state ~= nil and state[key] == true
			b.Text = ("%s: %s"):format(label, if on then "SÍ" else "NO")
			b.BackgroundColor3 = if on then ON else H.NavyLight
		end
		refresh()
		table.insert(refreshers, refresh)
	end

	section("INTERRUPTORES")
	toggle("Money", "💰 Dinero infinito")
	toggle("Bypass", "🔓 Sin requisitos (oficios, carnets, edad)")
	note("Con el dinero infinito, al apagarlo vuelves a tener el dinero de antes.")

	section("DESBLOQUEAR")
	button(list, "🔓 Desbloquear todo", function()
		send("Action", "UnlockAll")
	end)
	local unlock = grid()
	for i, item in {
		{ "Weapons", "🔫 Todas las armas" },
		{ "Licences", "🪪 Todos los carnets" },
		{ "Vehicles", "🚗 Todos los vehículos" },
		{ "MaxLevel", "⭐ Nivel máximo" },
	} do
		button(unlock, item[2], function()
			send("Action", item[1])
		end, i)
	end

	section("PERSONAJE")
	local body = grid()
	button(body, "❤ Rellenar energía, hambre y salud", function()
		send("Action", "Refill")
	end, 1)
	button(body, "🚔 Quitar búsqueda policial", function()
		send("Action", "ClearWanted")
	end, 2)

	local stageTitle = section("CAMBIAR ETAPA DE VIDA")
	local function refreshStage()
		local current = state and state.Stage
		stageTitle.Text = "CAMBIAR ETAPA DE VIDA · ahora: " .. (STAGE_NAMES[current or ""] or tostring(current or "-"))
	end
	refreshStage()
	table.insert(refreshers, refreshStage)
	local stages = grid()
	for i, stage in (state and state.Stages) or {} do
		button(stages, STAGE_NAMES[stage] or stage, function()
			send("Action", "Stage", stage)
		end, i)
	end
	note("Cambia la edad y el capítulo de tu historia (las misiones en marcha pueden quedar a medias).")

	section("TELETRANSPORTE")
	local places = grid()
	for i, place in (state and state.Places) or {} do
		button(places, tostring(place.Name), function()
			send("Action", "Teleport", place.Id)
		end, i)
	end

	section("HORA DEL DÍA")
	local hours = grid()
	for i, hour in (state and state.Hours) or {} do
		button(hours, ("🕒 %d:00"):format(hour), function()
			send("Action", "Hour", hour)
		end, i)
	end
	note("La hora cambia para todo el servidor.")
end

local function refreshAll()
	for _, refresh in refreshers do
		local ok, err = pcall(refresh)
		if not ok then
			warn("[TesterPanel] " .. tostring(err))
		end
	end
end

-- Pide abrir el panel: el servidor comprueba que eres tester y contesta con el estado ("Open")
function TesterPanel.open()
	if not TesterPanel.isTester() then
		return
	end
	send("Open")
end

function TesterPanel.toggle()
	if TesterPanel.isOpen() then
		TesterPanel.close()
	else
		TesterPanel.open()
	end
end

function TesterPanel.init()
	Dialog.registerBig(NAME, TesterPanel.close)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 60)
		local found = remotes and remotes:WaitForChild("Tester", 60)
		if not found or not found:IsA("RemoteEvent") then
			return
		end
		remote = found
		found.OnClientEvent:Connect(function(kind: string, payload: any)
			if type(payload) ~= "table" then
				return
			end
			if kind == "Open" then
				state = payload
							build()
			elseif kind == "State" then
				state = payload
				if TesterPanel.isOpen() then
					refreshAll()
				end
			end
		end)
	end)
	-- Si deja de ser tester (no debería pasar), se cierra
	player:GetAttributeChangedSignal("Tester"):Connect(function()
		if not TesterPanel.isTester() then
			TesterPanel.close()
		end
	end)
end

return TesterPanel
