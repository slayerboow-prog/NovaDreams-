-- HotelUI (cliente): los hoteles.
--   * En recepción: eliges el tipo de habitación (individual, doble o suite) y pagas.
--   * Al descansar: la pantalla se oscurece un momento.
--   * Recepcionista: panel con las entradas y salidas y el cuadro de habitaciones (libres y con
--     el nombre de quien está dentro). Tocas la habitación correcta para dar la llave o cobrar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Format = require(ReplicatedStorage.Shared.Format)

local HotelUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Hotel") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

---------------------------------------------------------------------
-- Reservar
---------------------------------------------------------------------
local function openMenu(menu: { [string]: any })
	local window, content, close = Dialog.window("HotelMenu", "🛎️ " .. tostring(menu.Hotel), Vector2.new(420, 300))
	Theme.label({
		Size = UDim2.new(1, 0, 0, 36),
		Text = "¿Qué habitación quiere?" .. (if menu.Staff then ("\nLe atiende %s."):format(menu.Staff) else ""),
		TextSize = 14,
		TextWrapped = true,
		Parent = content,
	})
	local list = create("Frame", { Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -42), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 6), Parent = list })
	for _, t in menu.Types do
		local full = t.Free <= 0
		local b = Theme.button({
			Size = UDim2.new(1, 0, 0, 46),
			Text = ("%s %s · %s   (%s)"):format(t.Icon, t.Name, Format.money(t.Price), if full then "completo" else ("%d libres"):format(t.Free)),
			TextSize = 15,
			BackgroundColor3 = if full then rgb(60, 60, 66) else C.Accent,
			Parent = list,
		})
		b.Activated:Connect(function()
			if not full then
				Remote:FireServer("Book", t.Id)
				window:Destroy()
			end
		end)
	end
	close.Activated:Connect(function()
		window:Destroy()
	end)
end

---------------------------------------------------------------------
-- Descansar
---------------------------------------------------------------------
local fade: Frame

local function rest(seconds: number)
	fade.Visible = true
	fade.BackgroundTransparency = 1
	TweenService:Create(fade, TweenInfo.new(0.6), { BackgroundTransparency = 0.05 }):Play()
	task.delay(math.max(0.8, seconds - 0.6), function()
		local t = TweenService:Create(fade, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
		t:Play()
		t.Completed:Wait()
		fade.Visible = false
	end)
end

---------------------------------------------------------------------
-- Panel del recepcionista
---------------------------------------------------------------------
local panel: Frame
local list: Frame

local function showWork(requests: { any }, rooms: { any })
	panel.Visible = true
	for _, child in list:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	if #requests == 0 then
		Theme.label({ Size = UDim2.new(1, 0, 0, 30), Text = "Nadie esperando. Quédate en el mostrador.", TextSize = 13, TextColor3 = C.Muted, TextWrapped = true, LayoutOrder = nextOrder(), Parent = list })
	end
	for i, r in requests do
		Theme.label({
			Size = UDim2.new(1, 0, 0, if i == 1 then 36 else 18),
			Text = ("%s%s <b>%s</b> (%d s) %s"):format(if i == 1 then "➡️ " else "", if r.Kind == "In" then "🧳" else "🔑", r.Name, r.Wait, r.Text),
			RichText = true,
			TextWrapped = true,
			TextSize = if i == 1 then 13 else 11,
			TextColor3 = if i == 1 then rgb(255, 230, 170) else C.Muted,
			LayoutOrder = nextOrder(),
			Parent = list,
		})
	end
	local first = requests[1]
	Theme.label({
		Size = UDim2.new(1, 0, 0, 18),
		Text = if not first then "Habitaciones:" elseif first.Kind == "In" then "Toca una habitación LIBRE del tipo que pide:" else "Toca SU habitación para cobrar la salida:",
		TextSize = 12,
		LayoutOrder = nextOrder(),
		Parent = list,
	})
	local grid = create("Frame", { Size = UDim2.new(1, 0, 0, 170), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = list })
	create("UIGridLayout", { CellSize = UDim2.fromOffset(88, 38), CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for k, room in rooms do
		local b = Theme.button({
			Text = ("%d %s\n%s"):format(room.Room, room.Icon, room.Guest or "libre"),
			TextSize = 11,
			TextWrapped = true,
			LayoutOrder = k,
			BackgroundColor3 = if room.Guest then rgb(120, 60, 50) else rgb(40, 110, 70),
			Parent = grid,
		})
		b.Activated:Connect(function()
			Remote:FireServer("Assign", room.Room)
		end)
	end
end

function HotelUI.init()
	local gui = create("ScreenGui", { Name = "HotelGui", ResetOnSpawn = false, DisplayOrder = 5, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	fade = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(6, 8, 20), BackgroundTransparency = 1, Visible = false, ZIndex = 50, Parent = gui })
	create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "😴 Zzz…", TextSize = 42, Font = Enum.Font.GothamBold, TextColor3 = rgb(230, 230, 255), ZIndex = 51, Parent = fade })
	panel = Theme.panel({
		Name = "Recepcion",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(300, 400),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "🛎️ Recepción", Font = Theme.FontBold, TextSize = 16, Parent = panel })
	list = create("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 1, -26), BackgroundTransparency = 1, Parent = panel })
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	Remote.OnClientEvent:Connect(function(action, a, b)
		if action == "Menu" then
			openMenu(a)
		elseif action == "Work" then
			showWork(a, b)
		elseif action == "Rest" then
			rest(a)
		elseif action == "Start" then
			panel.Visible = true
		elseif action == "Stop" then
			panel.Visible = false
		end
	end)
	player:GetAttributeChangedSignal("Job"):Connect(function()
		if player:GetAttribute("Job") ~= "Recepcionista" then
			panel.Visible = false
		end
	end)
end

return HotelUI
