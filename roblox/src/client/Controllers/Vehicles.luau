-- Vehicles: menú "🚲 Vehículos" (comprar y sacar tu monopatín, patinete, bici, moto o coche)
-- (la conducción en sí está en Driving.luau)
-- y botón para bajarse (también con la tecla F), conduciendo o de pasajero.
-- Mientras vas dentro de un vehículo no se ven sus propios carteles ("Subir de copiloto"…):
-- solo estorbarían en el menú de comandos.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)

local create = Theme.create
local C = Theme.Colors

local Vehicles = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Vehicle") :: RemoteEvent

local STAGE_TEXT = { Nino = "Desde niño", Adolescente = "Desde adolescente", AdultoJoven = "Mayor de edad" }

local function has(attribute: string, key: string): boolean
	local list = player:GetAttribute(attribute)
	return typeof(list) == "string" and string.find("," .. list .. ",", "," .. key .. ",", 1, true) ~= nil
end

local function sorted(): { string }
	local list = {}
	for key, vehicle in Gameplay.Vehicles do
		if not vehicle.Hidden then -- (el autobús no se compra)
			table.insert(list, key)
		end
	end
	table.sort(list, function(a, b)
		return Gameplay.Vehicles[a].Order < Gameplay.Vehicles[b].Order
	end)
	return list
end

local refresh: (() -> ())? = nil

-- Por qué no puedes comprarlo ahora (nil = sí puedes). Se enseña en la propia ventana: antes solo
-- salía un aviso arriba, tapado por la ventana, y parecía que el botón no hacía nada.
local function whyNot(vehicle: { [string]: any }): string?
	if not Stages.allows(player:GetAttribute("LifeStage"), "Ride", { Ride = vehicle.Stage }) then
		return "Aún no tienes edad (" .. (STAGE_TEXT[vehicle.Stage] or vehicle.Stage) .. ")"
	end
	local money = player:GetAttribute("Money")
	if typeof(money) == "number" and money < vehicle.Price then
		return "Te faltan " .. Format.money(vehicle.Price - money)
	end
	return nil
end

local function open()
	local window, content = Dialog.window("Vehicles", "🚲 Mis vehículos", Vector2.new(480, 520))
	local list = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local licenses = Theme.label({
		Size = UDim2.new(1, 0, 0, 36),
		TextSize = 13,
		TextWrapped = true,
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
				local reason = whyNot(vehicle)
				if reason then
					info.Text = "⚠️ " .. reason
					info.TextColor3 = Color3.fromRGB(255, 120, 100)
					return
				end
				button.Text = "Comprando…"
				Remote:FireServer("Buy", key)
				-- Si el servidor no contesta (sin cambios en 3 s) se deja el botón como estaba
				task.delay(3, function()
					if refresh and button.Parent and button.Text == "Comprando…" then
						refresh()
					end
				end)
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
		licenses.Text = ("Carnet de moto %s   ·   Carnet de coche %s   ·   Bici, monopatín y patinete gratis en las paradas de bus · Los coches aparcados de la calle también se pueden conducir"):format(a, b)
		for key, row in rows do
			local vehicle = Gameplay.Vehicles[key]
			local needs = STAGE_TEXT[vehicle.Stage] or vehicle.Stage
			if vehicle.License then
				needs ..= " · necesita " .. Gameplay.Licenses[vehicle.License].Name
			end
			row.Info.Text = ("Velocidad %d · %s"):format(vehicle.Speed, needs)
			row.Info.TextColor3 = C.Muted
			if has("OwnedVehicles", key) then
				row.Button.Text = if player:GetAttribute("Riding") == key then "Bajarse" else "Montar"
				row.Button.BackgroundColor3 = Color3.fromRGB(0, 140, 200)
			else
				row.Button.Text = "Comprar " .. Format.money(vehicle.Price)
				row.Button.BackgroundColor3 = if whyNot(vehicle) then Color3.fromRGB(110, 110, 120) else Color3.fromRGB(0, 150, 80)
			end
		end
	end
	refresh()
end

local function aboard(): boolean
	return player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil
end

local function dismount(_: string, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin and aboard() then
		Remote:FireServer("Dismount")
	end
	return Enum.ContextActionResult.Pass
end

-- Para el menú de comandos: bajarse del vehículo (o levantarse de cualquier asiento: banco, metro…)
function Vehicles.dismount()
	if aboard() then
		Remote:FireServer("Dismount")
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.SeatPart then
		humanoid.Jump = true
	end
end
Vehicles.open = open

-- Los carteles del vehículo en el que vas se apagan en tu pantalla (y vuelven al bajarte)
local hiddenPrompts: { [ProximityPrompt]: boolean } = {}
local function hidePromptsOf(model: Instance?)
	for prompt in hiddenPrompts do
		local parent = prompt.Parent
		if parent then
			-- (como los deja el servidor: el asiento libre, o el volante si nadie conduce)
			if prompt.Name == "SeatPrompt" and parent:IsA("Seat") then
				prompt.Enabled = parent.Occupant == nil
			else
				local vehicle = prompt:FindFirstAncestorOfClass("Model")
				prompt.Enabled = vehicle == nil or vehicle:GetAttribute("Driver") == nil
			end
		end
	end
	table.clear(hiddenPrompts)
	if not model then
		return
	end
	for _, prompt in model:GetDescendants() do
		-- (el de conducir se le deja al pasajero: si el coche es suyo, se puede pasar al volante)
		local mine = prompt.Name == "SeatPrompt" or (prompt.Name == "DrivePrompt" and player:GetAttribute("Riding") ~= nil)
		if prompt:IsA("ProximityPrompt") and mine and prompt.Enabled then
			prompt.Enabled = false
			hiddenPrompts[prompt] = true
		end
	end
end

function Vehicles.init()
	Hud.addButton("🚲 Vehículos", Color3.fromRGB(0, 120, 170), 3, open)

	-- Botón para bajarse mientras vas montado: en el ordenador, grande abajo a la derecha; en el
	-- móvil, redondo en el arco del botón de saltar (donde a pie está el de correr)
	local touch = game:GetService("UserInputService").TouchEnabled
	local gui = if touch
		then Theme.create("ScreenGui", { Name = "GetOffGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
		else player:WaitForChild("PlayerGui"):WaitForChild("MainHud")
	local getOff = Theme.button({
		Name = "GetOff",
		AnchorPoint = Vector2.new(1, 1),
		Size = UDim2.fromOffset(180, 46),
		Position = UDim2.new(1, -24, 1, -176), -- abajo a la derecha, encima del cartel de "dónde estás"
		Text = if touch then "⬇" else "⬇ Bajarse (F)",
		TextSize = if touch then 26 else nil,
		BackgroundColor3 = Color3.fromRGB(150, 60, 40),
		Visible = false,
		Parent = gui,
	})
	if touch then
		local corner = getOff:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0.5, 0)
		end
		TouchLayout.place(getOff, "Bajarse")
	end
	getOff.Activated:Connect(function()
		Remote:FireServer("Dismount")
	end)
	local function update()
		getOff.Visible = aboard()
		-- Los carteles de tu propio vehículo, fuera mientras vas dentro
		task.defer(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local seat = humanoid and humanoid.SeatPart
			local model = seat and seat:FindFirstAncestorOfClass("Model")
			hidePromptsOf(if aboard() and model and model:GetAttribute("Drivable") then model else nil)
		end)
		if refresh then
			refresh()
		end
	end
	for _, attribute in { "Riding", "Passenger", "OwnedVehicles", "Licenses", "Money", "LifeStage" } do
		player:GetAttributeChangedSignal(attribute):Connect(update)
	end
	update()
	ContextActionService:BindAction("Dismount", dismount, false, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
end

return Vehicles
