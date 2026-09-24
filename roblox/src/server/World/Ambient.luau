-- Ambient (servidor): publica en ReplicatedStorage lo que el cliente necesita para
-- simular tráfico y peatones por su cuenta (sin coste para el servidor):
--   ReplicatedStorage.Ambient.Roads -> una Configuration por calle (Axis, At, From, To)
--   ReplicatedStorage.Ambient.Cars  -> modelos de coche en el origen, mirando a -Z

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Props = require(script.Parent.Kit.Props)
local Palette = require(script.Parent.Kit.Palette)

local Ambient = {}

local CAR_VARIANTS = 8

function Ambient.publish(roads: { { [string]: any } })
	local existing = ReplicatedStorage:FindFirstChild("Ambient")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Ambient"

	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Roads"
	roadFolder.Parent = folder
	for i, road in roads do
		local config = Instance.new("Configuration")
		config.Name = "Road" .. i
		config:SetAttribute("Axis", road.Axis)
		config:SetAttribute("At", road.At)
		config:SetAttribute("From", road.From)
		config:SetAttribute("To", road.To)
		config.Parent = roadFolder
	end

	local cars = Instance.new("Folder")
	cars.Name = "Cars"
	cars.Parent = folder
	for i = 1, CAR_VARIANTS do
		local color = Palette.CarColors[(i - 1) % #Palette.CarColors + 1]
		local car = Props.car(cars, CFrame.new(), color)
		if car then
			car.Name = "Car" .. i
		end
	end

	folder.Parent = ReplicatedStorage
end

return Ambient
