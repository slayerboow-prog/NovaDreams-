-- BusUI (cliente): el panel de los pasajeros del autobús urbano.
--
--   [L2] → Puerto
--   Próxima parada: San Roque (metro)        [🔔 Bajar en la próxima]
--
-- Sentado en un asiento del autobús se ve la línea (con su color), hacia dónde va y la próxima
-- parada. "Bajar en la próxima" (botón, tecla G o el botón del racimo en el móvil) pide parada:
-- suena el timbre y en la siguiente parada se abre la puerta y bajas en la acera.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local HudLayout = require(script.Parent.Parent.UI.HudLayout)
local SoundFx = require(script.Parent.SoundFx)

local BusUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Bus", 10) :: RemoteEvent?

-- El autobús en el que vas sentado (o nil)
local function currentBus(): Model?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local bus = seat and seat.Name == "PassengerSeat" and seat.Parent
	if bus and bus:IsA("Model") and bus:GetAttribute("BusLine") then
		return bus
	end
	return nil
end

local function ring()
	-- "Din-don" del timbre de parada
	SoundFx.play("Aviso", 1, 1.35)
	task.delay(0.22, function()
		SoundFx.play("Aviso", 1, 1.05)
	end)
end

local pressedAt = 0

-- ¿Has pedido tú la parada? (el servidor lo marca en tu jugador: aunque otro pasajero ya la haya
-- pedido, tú también tienes que pedirla para bajarte)
local function mine(): boolean
	return player:GetAttribute("BusStopRequested") == true
end

local function request()
	local bus = currentBus()
	if not bus or not Remote then
		return
	end
	-- Siempre se avisa al servidor (con la puerta abierta en la parada: bajar ya)
	Remote:FireServer("Request")
	if not mine() and not bus:GetAttribute("DoorsOpen") then
		pressedAt = os.clock()
		-- (si otro ya la había pedido, el timbre ya sonó: no se repite)
		if not bus:GetAttribute("StopRequested") then
			ring()
		end
	end
end

-- Lo que ocupa en píxeles (izquierda, derecha) un hueco de HudLayout (en unidades del lienzo del HUD)
local function spanPx(p: any, hud: number, view: Vector2): (number, number)
	local w = view.X / hud
	local x = p.Position.X.Scale * w + p.Position.X.Offset - p.Anchor.X * p.Size.X
	return x * hud, (x + p.Size.X) * hud
end

-- Móvil: el panel va entre el joystick y los botones (antes, centrado, pisaba Correr en 667x375).
-- Devuelve el centro y el ancho que caben, en píxeles (nil fuera del móvil).
function BusUI.touchBand(view: Vector2): (number?, number?)
	if not Theme.isTouch() then
		return nil, nil
	end
	local layout = HudLayout.compute(view, { Touch = true })
	local hud = layout.Scale
	local left = 0
	local stick = layout.Items.Joystick
	if stick then
		local _, r = spanPx(stick, hud, view)
		left = r
	end
	local right = view.X
	for _, id in { "Correr", "Agacharse", "Extra1", "Extra2", "Contexto" } do
		local slot = layout.Slots[id]
		if slot then
			local l = spanPx(slot, hud, view)
			right = math.min(right, l)
		end
	end
	left, right = left + 8, right - 8
	return (left + right) / 2, math.max(120, right - left)
end

function BusUI.init()
	-- (la pantalla se queda encendida: se enseña o se esconde el panel. Antes se encendía la pantalla
	-- cada 0,2 s y el panel volvía encima de las cinemáticas y del modo foto)
	local gui = Theme.create("ScreenGui", { Name = "BusGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	local panel = Theme.create("Frame", {
		Name = "BusPanel",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(520, 64),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.12,
		Visible = false,
		Parent = gui,
	}, { Theme.corner(12) })
	local camera = workspace.CurrentCamera
	local function placePanel()
		local center, width = BusUI.touchBand(camera.ViewportSize)
		local scale = gui:FindFirstChildOfClass("UIScale")
		local k = if scale and scale.Scale > 0 then scale.Scale else 1
		if center and width then
			panel.Position = UDim2.new(0, center / k, 1, -100)
			panel.Size = UDim2.fromOffset(math.min(520, math.floor(width / k)), 64)
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		task.defer(placePanel)
	end)
	local badge = Theme.create("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(52, 44),
		BackgroundColor3 = Color3.fromRGB(215, 45, 50),
		Parent = panel,
	}, { Theme.corner(8) })
	local badgeText = Theme.label({ Size = UDim2.fromScale(1, 1), Font = Theme.FontBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Parent = badge })
	-- (móvil: sin el botón del panel; para eso está «Bajar en la próxima» del racimo)
	local side = if Theme.isTouch() then 82 else 250
	local headsign = Theme.label({ Position = UDim2.fromOffset(72, 8), Size = UDim2.new(1, -side, 0, 24), Font = Theme.FontBold, TextSize = 17, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	local status = Theme.label({ Position = UDim2.fromOffset(72, 33), Size = UDim2.new(1, -side, 0, 22), TextSize = 14, TextColor3 = Theme.Colors.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = panel })
	local button = Theme.button({
		Name = "Request",
		Visible = not Theme.isTouch(),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(166, 44),
		Text = "🔔 Bajar en la próxima",
		TextSize = 14,
		Parent = panel,
	})
	button.Activated:Connect(request)
	placePanel()

	-- Móvil: botón del racimo (columna de contexto); ordenador y mando: tecla G
	TouchLayout.register({
		Id = "BajarBus",
		Icon = "timbre",
		Label = "Bajar en la próxima",
		Priority = 2,
		Key = "G",
		Visible = function()
			return currentBus() ~= nil
		end,
		Active = function()
			return currentBus() ~= nil and mine()
		end,
		Callback = request,
	})
	local bound = false
	local lastRequested = false
	local lastMine = false
	local lastBus: Model? = nil

	-- 5 veces por segundo basta
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.2 then
			return
		end
		elapsed = 0
		local bus = currentBus()
		if bus ~= lastBus then
			lastBus = bus
			TouchLayout.refresh()
			if bus and not bound then
				bound = true
				ContextActionService:BindAction("BusRequestStop", function(_, state)
					if state == Enum.UserInputState.Begin then
						request()
					end
					return Enum.ContextActionResult.Sink
				end, false, Enum.KeyCode.G)
			elseif not bus and bound then
				bound = false
				ContextActionService:UnbindAction("BusRequestStop")
			end
		end
		if not bus then
			panel.Visible = false
			lastRequested = false
			lastMine = false
			return
		end
		if not panel.Visible then
			placePanel()
		end
		panel.Visible = true
		local line = tostring(bus:GetAttribute("BusLine"))
		local color = bus:GetAttribute("LineColor")
		if typeof(color) == "Color3" then
			badge.BackgroundColor3 = color
		end
		Theme.setText(badgeText, line)
		Theme.setText(headsign, "→ " .. tostring(bus:GetAttribute("Headsign") or "…"))
		local requested = bus:GetAttribute("StopRequested") == true
		-- Otro pasajero ha pedido parada: también se oye el timbre
		if requested and not lastRequested then
			TouchLayout.refresh()
			if os.clock() - pressedAt > 1.5 then
				ring()
			end
		end
		lastRequested = requested
		-- Tu botón (y el del móvil) se ve pulsado solo si la has pedido tú
		local asked = mine()
		if asked ~= lastMine then
			lastMine = asked
			TouchLayout.refresh()
		end
		local current = bus:GetAttribute("CurrentStop")
		if current and bus:GetAttribute("DoorsOpen") then
			Theme.setText(status, ("🚏 Parada: %s · puertas abiertas"):format(current))
			Theme.setText(button, "⬇️ Bajar aquí")
		else
			local nextStop = tostring(bus:GetAttribute("NextStop") or "…")
			Theme.setText(status, if requested then ("🔔 Parada solicitada · próxima: %s"):format(nextStop) else ("Próxima parada: %s"):format(nextStop))
			Theme.setText(button, if asked then "🔔 Parada solicitada" else "🔔 Bajar en la próxima")
		end
	end)
end

return BusUI
