-- Hangar: app «✈️ Hangar» del ValPhone. Comprar barcos y aviones y desplegarlos donde estés
-- (Services/HangarService): el barco sale en el agua más cercana y el avión en un sitio llano a tu lado.
-- Los aviones aterrizan en cualquier suelo firme del planeta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Boats = require(ReplicatedStorage.Shared.Boats)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local Hud = require(script.Parent.Parent.UI.Hud)

local create = Theme.create
local C = Theme.Colors

local Hangar = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent? = nil

-- Lo que hay en el hangar (el precio de los aviones lo pone el servidor: AviationService.Prices)
local PLANES = {
	{ Kind = "Avioneta", Icon = "🛩️", Name = "Avioneta", Price = 25000, Text = "Ala alta, despega en muy poco. Piloto y pasajeros. Pide licencia de piloto." },
	{ Kind = "Avion", Icon = "✈️", Name = "Avión de línea", Price = 90000, Text = "Reactor grande y rápido. Pide licencia y 3 aterrizajes suaves en avioneta." },
}

local function has(attribute: string, key: string): boolean
	local list = player:GetAttribute(attribute)
	return typeof(list) == "string" and string.find("," .. list .. ",", "," .. key .. ",", 1, true) ~= nil
end

local function send(action: string, kind: string?)
	if not Remote then
		Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Hangar", 5) :: RemoteEvent?
	end
	if Remote then
		Remote:FireServer(action, kind)
	end
end

local function open()
	local window, content = Dialog.window("Hangar", "✈️ Hangar · barcos y aviones", Vector2.new(500, 560))
	local list = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	create("UIPadding", { PaddingRight = UDim.new(0, 10), Parent = list })
	Theme.label({
		Size = UDim2.new(1, -8, 0, 40),
		Text = "Despliega desde aquí, estés donde estés: el barco sale en el agua más cercana y el avión en un sitio llano a tu lado. Puedes aterrizar en cualquier suelo firme.",
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = C.Muted,
		LayoutOrder = 0,
		Parent = list,
	})

	local rows: { { Kind: string, Info: TextLabel, Button: TextButton, Plane: boolean, Price: number, Season: boolean? } } = {}
	local function row(order: number, icon: string, name: string, text: string, kind: string, plane: boolean, price: number, season: boolean?)
		local panel = Theme.panel({
			Size = UDim2.new(1, -8, 0, 78),
			BackgroundColor3 = C.PanelLight,
			BackgroundTransparency = 0,
			LayoutOrder = order,
			Parent = list,
		})
		Theme.padding(10).Parent = panel
		Theme.label({ Size = UDim2.new(1, -140, 0, 24), Text = icon .. "  " .. name, Font = Theme.FontBold, TextSize = 18, Parent = panel })
		local info = Theme.label({
			Size = UDim2.new(1, -140, 0, 34),
			Position = UDim2.fromOffset(0, 26),
			Text = text,
			TextSize = 12,
			TextColor3 = C.Muted,
			TextWrapped = true,
			Parent = panel,
		})
		local button = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.fromOffset(124, 44),
			Position = UDim2.fromScale(1, 0.5),
			TextSize = 13,
			TextWrapped = true,
			Parent = panel,
		})
		local entry = { Kind = kind, Info = info, Button = button, Plane = plane, Price = price, Season = season }
		table.insert(rows, entry)
		button.Activated:Connect(function()
			local owned = has(if plane then "OwnedPlanes" else "OwnedBoats", kind)
			if owned then
				send("Deploy", kind)
				window:Destroy()
			elseif season then
				info.Text = "🏆 Se consigue en el pase de temporada."
			else
				local money = player:GetAttribute("Money")
				if typeof(money) == "number" and money < price then
					info.Text = "⚠️ Te faltan " .. Format.money(price - money)
					info.TextColor3 = Color3.fromRGB(255, 120, 100)
					return
				end
				button.Text = "Comprando…"
				send("Buy", kind)
			end
		end)
	end

	Theme.label({ Size = UDim2.new(1, -8, 0, 22), Text = "⚓ Barcos", Font = Theme.FontBold, TextSize = 16, LayoutOrder = 1, Parent = list })
	for i, kind in Boats.Kinds do
		local info = Boats.Info[kind]
		local vehicle = Gameplay.Vehicles[kind]
		row(1 + i, vehicle and vehicle.Icon or "🚤", vehicle and vehicle.Name or kind, info.Text, kind, false, info.Price or 0, info.Season)
	end
	Theme.label({ Size = UDim2.new(1, -8, 0, 22), Text = "✈️ Aviones", Font = Theme.FontBold, TextSize = 16, LayoutOrder = 20, Parent = list })
	for i, p in PLANES do
		row(20 + i, p.Icon, p.Name, p.Text, p.Kind, true, p.Price)
	end
	local store = Theme.button({
		Size = UDim2.new(1, -8, 0, 44),
		Text = "📦 Guardar lo que tengo desplegado",
		TextSize = 15,
		BackgroundColor3 = Color3.fromRGB(110, 110, 120),
		LayoutOrder = 40,
		Parent = list,
	})
	store.Activated:Connect(function()
		send("Store")
		window:Destroy()
	end)

	local function refresh()
		if not window.Parent then
			return
		end
		for _, r in rows do
			local owned = has(if r.Plane then "OwnedPlanes" else "OwnedBoats", r.Kind)
			if owned then
				local out = player:GetAttribute(if r.Plane then "PlaneOut" else "BoatOut") == r.Kind
				r.Button.Text = if out then "Desplegar aquí" else "Desplegar"
				r.Button.BackgroundColor3 = Color3.fromRGB(0, 140, 200)
				if r.Plane and r.Kind == "Avioneta" and player:GetAttribute("PilotLicense") ~= true then
					r.Info.Text = "Es tuya. Para pilotarla: licencia en el aeroclub del aeropuerto."
				elseif r.Plane and r.Kind == "Avion" and player:GetAttribute("JetReady") ~= true then
					r.Info.Text = "Es tuyo. Para pilotarlo: licencia y 3 aterrizajes suaves en avioneta."
				end
			elseif r.Season then
				r.Button.Text = "Del pase"
				r.Button.BackgroundColor3 = Color3.fromRGB(110, 110, 120)
			else
				r.Button.Text = "Comprar " .. Format.money(r.Price)
				local money = player:GetAttribute("Money")
				r.Button.BackgroundColor3 = if typeof(money) == "number" and money < r.Price then Color3.fromRGB(110, 110, 120) else Color3.fromRGB(0, 150, 80)
			end
		end
	end
	refresh()
	local conns = {}
	for _, attr in { "OwnedPlanes", "OwnedBoats", "PlaneOut", "BoatOut", "Money", "PilotLicense", "JetReady" } do
		table.insert(conns, player:GetAttributeChangedSignal(attr):Connect(refresh))
	end
	window.Destroying:Connect(function()
		for _, c in conns do
			c:Disconnect()
		end
	end)
end
Hangar.open = open

function Hangar.init()
	Hud.addButton("✈️ Hangar", Color3.fromRGB(20, 110, 190), 4, open)
end

return Hangar
