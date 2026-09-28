-- Vehicles: menú "🚲 Vehículos" (comprar y sacar tu monopatín, patinete, bici, moto o coche)
-- (la conducción en sí está en Driving.luau)
-- y bajarse (tecla F / B del mando, botón "Bajarse" o "Levantarse"), conduciendo o de pasajero.
-- Bajarse funciona SIEMPRE a la primera: se lo pide al servidor y, sin esperarle, tu ordenador te
-- levanta ya (sin soldadura, de pie junto a la puerta de tu lado y con la cámara normal). Cuando el
-- servidor contesta ("Exited"), te deja exactamente donde toca. Durante un momento después, nada
-- te vuelve a sentar sin querer.
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
local Driving = require(script.Parent.Driving)

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
					Vehicles.exit()
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
		licenses.Text = ("Carnet de moto %s   ·   Carnet de coche %s   ·   Sin carnet también se conduce, pero si te ve la policía te para · Bici, monopatín y patinete gratis en las paradas de bus"):format(a, b)
		for key, row in rows do
			local vehicle = Gameplay.Vehicles[key]
			local needs = STAGE_TEXT[vehicle.Stage] or vehicle.Stage
			if vehicle.License then
				needs ..= " · pide " .. Gameplay.Licenses[vehicle.License].Name
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

local function body(): (Humanoid?, BasePart?)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid"), character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ¿Es el asiento de un vehículo (conductor o pasajero)?
local function vehicleSeat(seat: Instance?): boolean
	if not seat or not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
		return false
	end
	local model = seat:FindFirstAncestorOfClass("Model")
	return model ~= nil and model:GetAttribute("Drivable") == true
end

-- ¿Va dentro de un vehículo? (lo sepa el servidor o no)
local function inVehicle(): boolean
	local humanoid = body()
	return aboard() or (humanoid ~= nil and vehicleSeat(humanoid.SeatPart))
end
Vehicles.inVehicle = inVehicle

local exitingUntil = 0 -- hasta cuándo nada te vuelve a sentar

-- Levantarse del asiento en tu propio ordenador (que es quien mueve tu personaje): sin soldadura,
-- de pie y fuera de la carrocería. placed = donde te deja el servidor; si aún no ha contestado,
-- junto a la puerta de tu lado.
local function standUpLocally(placed: CFrame?)
	local humanoid, root = body()
	if not humanoid or not root then
		return
	end
	local seat = humanoid.SeatPart
	Driving.release()
	if not placed and seat and vehicleSeat(seat) then
		local side = seat:GetAttribute("Side")
		local sign = if typeof(side) == "number" and side ~= 0 then math.sign(side) else -1
		local model = seat:FindFirstAncestorOfClass("Model")
		local chassis = model and model.PrimaryPart
		local width = if chassis then chassis.Size.X else 6
		local right = Vector3.new(seat.CFrame.RightVector.X, 0, seat.CFrame.RightVector.Z)
		local look = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z)
		right = if right.Magnitude > 0.1 then right.Unit else Vector3.xAxis
		look = if look.Magnitude > 0.1 then look.Unit else -Vector3.zAxis
		local base = if chassis then chassis.Position else seat.Position
		local offset = seat.Position - base
		local spot = base + right * sign * (width / 2 + 2.5) + look * offset:Dot(look) + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + 0.5, 0)
		placed = CFrame.lookAt(spot, spot + look)
	end
	if seat then
		for _, child in seat:GetChildren() do
			if child.Name == "SeatWeld" then
				child:Destroy()
			end
		end
	end
	humanoid.Sit = false
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
	if placed then
		root.CFrame = placed
		root.AssemblyLinearVelocity = Vector3.zero
	end
	-- La cámara vuelve a tu personaje (RideCamera deja la distancia cómoda)
	local camera = workspace.CurrentCamera
	local subject = camera and camera.CameraSubject
	if camera and (subject == nil or subject:IsA("Seat") or subject:IsA("VehicleSeat")) then
		camera.CameraSubject = humanoid
	end
end

-- Bajarse: una pulsación siempre te saca (conduciendo o de pasajero, parado o en marcha, y
-- aunque el servidor tarde en contestar)
function Vehicles.exit()
	local humanoid = body()
	if not inVehicle() then
		-- Sentado en otra cosa (un banco, el metro…): levantarse como siempre
		if humanoid and humanoid.SeatPart then
			humanoid.Jump = true
		end
		return
	end
	exitingUntil = os.clock() + Gameplay.ExitCooldown
	Remote:FireServer("Dismount")
	if humanoid and vehicleSeat(humanoid.SeatPart) then
		standUpLocally(nil)
	else
		Driving.release()
	end
end

local function dismount(_: string, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin and inVehicle() then
		Vehicles.exit()
	end
	return Enum.ContextActionResult.Pass
end

-- Para el menú de comandos: bajarse del vehículo (o levantarse de cualquier asiento: banco, metro…)
function Vehicles.dismount()
	Vehicles.exit()
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

	-- Bajarse mientras vas montado o de pasajero: botón del racimo (móvil, donde a pie está Correr) o tecla F / B
	TouchLayout.register({
		Id = "Bajarse",
		Icon = "bajarse",
		Label = "Bajarse",
		Slot = "Correr",
		Priority = 4,
		Key = "F",
		Pad = "B",
		Visible = function()
			return inVehicle()
		end,
		Callback = function()
			Vehicles.exit()
		end,
	})
	-- El servidor te ha bajado: tu ordenador te deja ahí de pie (y nada te vuelve a sentar enseguida)
	Remote.OnClientEvent:Connect(function(kind, data)
		if kind ~= "Exited" then
			return
		end
		exitingUntil = os.clock() + Gameplay.ExitCooldown
		local humanoid = body()
		if humanoid and humanoid.SeatPart and vehicleSeat(humanoid.SeatPart) then
			local placed = type(data) == "table" and data.CFrame or nil
			standUpLocally(if typeof(placed) == "CFrame" then placed else nil)
		else
			Driving.release()
		end
		TouchLayout.refresh()
	end)
	-- Nada de volver a sentarse sin querer justo después de bajarse (si el servidor no te ha subido)
	local function watchSeat(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid then
			return
		end
		humanoid.Seated:Connect(function(active, seat)
			TouchLayout.refresh()
			if active and seat and vehicleSeat(seat) and os.clock() < exitingUntil then
				task.delay(0.25, function()
					if humanoid.SeatPart == seat and not aboard() then
						standUpLocally(nil)
					end
				end)
			end
		end)
	end
	if player.Character then
		task.spawn(watchSeat, player.Character)
	end
	player.CharacterAdded:Connect(watchSeat)
	local function update()
		TouchLayout.refresh()
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
