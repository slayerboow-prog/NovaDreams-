-- Ambient (servidor): publica en ReplicatedStorage lo que el cliente necesita para
-- simular tráfico y peatones por su cuenta (sin coste para el servidor):
--   ReplicatedStorage.Ambient.Roads -> una Configuration por tramo de calle:
--       A, B (Vector3: principio y fin, en cualquier ángulo) y Width (ancho de la calzada).
--       Las calles rectas de los barrios llevan además Axis, At, From, To.
--   ReplicatedStorage.Ambient.Cars  -> modelos de coche en el origen, mirando a -Z

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Props = require(script.Parent.Kit.Props)
local Palette = require(script.Parent.Kit.Palette)

local Ambient = {}

local CAR_VARIANTS = 8

function Ambient.publish(roads: { { [string]: any } }, segments: { { [string]: any } }?)
	local existing = ReplicatedStorage:FindFirstChild("Ambient")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Ambient"

	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Roads"
	roadFolder.Parent = folder
	local n = 0
	for _, road in roads do
		n += 1
		local config = Instance.new("Configuration")
		config.Name = "Road" .. n
		config:SetAttribute("Axis", road.Axis)
		config:SetAttribute("At", road.At)
		config:SetAttribute("From", road.From)
		config:SetAttribute("To", road.To)
		local a = if road.Axis == "X" then Vector3.new(road.From, 0, road.At) else Vector3.new(road.At, 0, road.From)
		local b = if road.Axis == "X" then Vector3.new(road.To, 0, road.At) else Vector3.new(road.At, 0, road.To)
		config:SetAttribute("A", a)
		config:SetAttribute("B", b)
		config:SetAttribute("Width", 24)
		config.Parent = roadFolder
	end
	-- Carreteras principales del plano (Ronda, avenidas, diagonales)
	for _, segment in segments or {} do
		n += 1
		local config = Instance.new("Configuration")
		config.Name = "Road" .. n
		config:SetAttribute("A", segment.A)
		config:SetAttribute("B", segment.B)
		config:SetAttribute("Width", segment.Width or 24)
		config:SetAttribute("Kind", segment.Kind)
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
