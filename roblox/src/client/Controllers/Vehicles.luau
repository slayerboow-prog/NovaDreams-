-- Vehicles: menú "🚲 Vehículos" (comprar y sacar tu monopatín, bici, moto o coche)
-- y botón para bajarse (también con la tecla F).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)

local create = Theme.create
local C = Theme.Colors

local Vehicles = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Vehicle") :: RemoteEvent

local STAGE_TEXT = { Adolescente = "Desde adolescente", AdultoJoven = "Mayor de edad" }

local function has(attribute: string, key: string): boolean
	local list = player:GetAttribute(attribute)
	return typeof(list) == "string" and string.find("," .. list .. ",", "," .. key .. ",", 1, true) ~= nil
end

local function sorted(): { string }
	local list = {}
	for key in Gameplay.Vehicles do
		table.insert(list, key)
	end
	table.sort(list, function(a, b)
		return Gameplay.Vehicles[a].Order < Gameplay.Vehicles[b].Order
	end)
	return list
end

local refresh: (() -> ())? = nil

local function open()
	local window, content = Dialog.window("Vehicles", "🚲 Mis vehículos", Vector2.new(480, 420))
	local list = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local licenses = Theme.label({
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 14,
		TextColor3 = C.Muted,
		LayoutOrder = 0,
		Parent = list,
	})

	local rows = {}
	for i, key in sorted() do
		local vehicle = Gameplay.Vehicles[key]
		local row = Theme.panel({
			Size = UDim2.new(1, 0, 0, 70),
			BackgroundColor3 = C.PanelLight,
			BackgroundTransparency = 0,
			LayoutOrder = i,
			Parent = list,
		})
		Theme.padding(10).Parent = row
		Theme.label({ Size = UDim2.new(1, -130, 0, 24), Text = vehicle.Icon .. "  " .. vehicle.Name, Font = Theme.FontBold, TextSize = 18, Parent = row })
		local info = Theme.label({
			Size = UDim2.new(1, -130, 0, 22),
			Position = UDim2.fromOffset(0, 26),
			TextSize = 13,
			TextColor3 = C.Muted,
			TextWrapped = true,
			Parent = row,
		})
		local button = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.fromOffset(120, 40),
			Position = UDim2.fromScale(1, 0.5),
			TextSize = 15,
			Parent = row,
		})
		button.Activated:Connect(function()
			if has("OwnedVehicles", key) then
				if player:GetAttribute("Riding") == key then
					Remote:FireServer("Dismount")
				else
					Remote:FireServer("Spawn", key)
				end
				window:Destroy()
			else
				Remote:FireServer("Buy", key)
			end
		end)
		rows[key] = { Info = info, Button = button }
	end

	refresh = function()
		if not window.Parent then
			return
		end
		local a = if has("Licenses", "A") then "✅" else "❌"
		local b = if has("Licenses", "B") then "✅" else "❌"
		licenses.Text = ("Carnet de moto %s   ·   Carnet de coche %s   ·   Bici pública gratis en las paradas de bus"):format(a, b)
		for key, row in rows do
			local vehicle = Gameplay.Vehicles[key]
			local needs = STAGE_TEXT[vehicle.Stage] or vehicle.Stage
			if vehicle.License then
				needs ..= " · necesita " .. Gameplay.Licenses[vehicle.License].Name
			end
			row.Info.Text = ("Velocidad %d · %s"):format(vehicle.Speed, needs)
			if has("OwnedVehicles", key) then
				row.Button.Text = if player:GetAttribute("Riding") == key then "Bajarse" else "Montar"
				row.Button.BackgroundColor3 = Color3.fromRGB(0, 140, 200)
			else
				row.Button.Text = "Comprar " .. Format.money(vehicle.Price)
				row.Button.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
			end
		end
	end
	refresh()
end

local function dismount(_: string, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin and player:GetAttribute("Riding") then
		Remote:FireServer("Dismount")
	end
	return Enum.ContextActionResult.Pass
end

function Vehicles.init()
	Hud.addButton("🚲 Vehículos", Color3.fromRGB(0, 120, 170), 3, open)

	-- Botón grande para bajarse mientras vas montado
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("MainHud")
	local getOff = Theme.button({
		Name = "GetOff",
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(180, 46),
		Position = UDim2.new(0.5, 0, 1, -110),
		Text = "⬇ Bajarse (F)",
		BackgroundColor3 = Color3.fromRGB(150, 60, 40),
		Visible = false,
		Parent = gui,
	})
	getOff.Activated:Connect(function()
		Remote:FireServer("Dismount")
	end)
	local function update()
		getOff.Visible = player:GetAttribute("Riding") ~= nil
		if refresh then
			refresh()
		end
	end
	for _, attribute in { "Riding", "OwnedVehicles", "Licenses" } do
		player:GetAttributeChangedSignal(attribute):Connect(update)
	end
	update()
	ContextActionService:BindAction("Dismount", dismount, false, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
end

return Vehicles
