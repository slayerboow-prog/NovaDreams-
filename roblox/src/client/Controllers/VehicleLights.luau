-- VehicleLights (cliente): pinta las luces de los vehículos que conducen los jugadores, en TODOS los
-- ordenadores, a partir de los atributos que pone el servidor (VehicleService, shared/VehicleControls):
--   * Faros (Headlight…): apagados = cristal sin brillo; cortas / largas = neón y el foco de verdad
--     (SpotLight: las largas llegan más lejos y más estrechas)
--   * Pilotos (Taillight, ThirdBrake): de posición con las luces puestas; al frenar, rojo intenso
--   * Marcha atrás (Reverse): blancos
--   * Intermitentes (IndicatorFront / IndicatorRear / Indicator): ámbar a 1,5 Hz en su lado (los cuatro
--     en emergencia)
-- Tu propio vehículo se pinta con lo que dice tu ordenador (VehicleLights.setLocal: sin esperar al
-- servidor, sin parpadeos). Solo se escribe una propiedad cuando cambia. El tráfico de la ciudad pinta
-- sus propios pilotos e intermitentes (Controllers/Traffic).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VehicleControls = require(ReplicatedStorage.Shared.VehicleControls)

local VehicleLights = {}

VehicleLights.TAG = "VehicleLamps" -- (lo pone VehicleService a los vehículos que conduce alguien)

local rgb = Color3.fromRGB
local TAIL_DIM, TAIL_BRAKE = rgb(150, 14, 22), rgb(255, 36, 44)
local IND_ON, IND_OFF = rgb(255, 160, 30), rgb(150, 90, 30)
local REVERSE_ON = rgb(245, 248, 255)
local HEAD_ON = rgb(255, 250, 235)
local NEON, PLASTIC = Enum.Material.Neon, Enum.Material.SmoothPlastic

type Lamp = { Part: BasePart, Color: Color3 }
type Entry = {
	Model: Model,
	Heads: { Lamp },
	Spots: { SpotLight },
	Tails: { Lamp },
	Reverse: { Lamp },
	Left: { Lamp },
	Right: { Lamp },
	Dirty: boolean,
	Shown: { [string]: any },
	Links: { RBXScriptConnection },
}

local entries: { [Model]: Entry } = {}
local localState: { [Model]: { [string]: any } } = {} -- tu vehículo: lo que dice tu ordenador

local HEADS = { Headlight = true, HeadlightRight = true, HeadlightSmall = true }
local TAILS = { Taillight = true, ThirdBrake = true }
local INDICATORS = { IndicatorFront = true, IndicatorRear = true, Indicator = true }

-- Busca las luces del modelo (y de qué lado va cada intermitente, visto desde el asiento)
local function scan(entry: Entry)
	local model = entry.Model
	entry.Heads, entry.Spots, entry.Tails, entry.Reverse, entry.Left, entry.Right = {}, {}, {}, {}, {}, {}
	entry.Shown = {}
	entry.Dirty = false
	local pivot = model.PrimaryPart and model.PrimaryPart.CFrame or model:GetPivot()
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local lamp = { Part = d, Color = d.Color }
			if HEADS[d.Name] then
				table.insert(entry.Heads, lamp)
			elseif TAILS[d.Name] then
				table.insert(entry.Tails, lamp)
			elseif d.Name == "Reverse" then
				table.insert(entry.Reverse, lamp)
			elseif INDICATORS[d.Name] then
				local x = pivot:PointToObjectSpace(d.Position).X
				table.insert(if x < 0 then entry.Left else entry.Right, lamp)
			end
		elseif d:IsA("SpotLight") and d.Parent and HEADS[d.Parent.Name] then
			table.insert(entry.Spots, d)
		end
	end
end

local function paint(list: { Lamp }, on: boolean, onColor: Color3?, offColor: Color3?, offMaterial: Enum.Material?)
	for _, lamp in list do
		local part = lamp.Part
		local material = if on then NEON else offMaterial or PLASTIC
		local color = if on then onColor or lamp.Color else offColor or lamp.Color
		if part.Material ~= material then
			part.Material = material
		end
		if part.Color ~= color then
			part.Color = color
		end
	end
end

-- Aplica el estado (atributos o el de tu ordenador) a un vehículo
function VehicleLights.apply(entry: Entry, attrs: { [string]: any }, t: number)
	local lamps = VehicleControls.lamps(attrs, t)
	local shown = entry.Shown
	if shown.Head ~= lamps.Head then
		shown.Head = lamps.Head
		paint(entry.Heads, lamps.Head > 0, HEAD_ON)
		for _, spot in entry.Spots do
			spot.Enabled = lamps.Head > 0
			spot.Range = if lamps.Head == 2 then 85 else 50
			spot.Angle = if lamps.Head == 2 then 42 else 60
			spot.Brightness = if lamps.Head == 2 then 5 else 3.2
		end
	end
	if shown.Tail ~= lamps.Tail then
		shown.Tail = lamps.Tail
		for _, lamp in entry.Tails do
			local part = lamp.Part
			local material = if lamps.Tail == "Off" then PLASTIC else NEON
			local color = if lamps.Tail == "Brake" then TAIL_BRAKE else TAIL_DIM
			if part.Material ~= material then
				part.Material = material
			end
			if part.Color ~= color then
				part.Color = color
			end
		end
	end
	if shown.Reverse ~= lamps.Reverse then
		shown.Reverse = lamps.Reverse
		paint(entry.Reverse, lamps.Reverse, REVERSE_ON)
	end
	if shown.Left ~= lamps.Left then
		shown.Left = lamps.Left
		paint(entry.Left, lamps.Left, IND_ON, IND_OFF)
	end
	if shown.Right ~= lamps.Right then
		shown.Right = lamps.Right
		paint(entry.Right, lamps.Right, IND_ON, IND_OFF)
	end
end

local function attrsOf(model: Model): { [string]: any }
	return {
		Lights = model:GetAttribute("Lights"),
		Indicator = model:GetAttribute("Indicator"),
		Braking = model:GetAttribute("Braking"),
		Reversing = model:GetAttribute("Reversing"),
		Handbrake = model:GetAttribute("Handbrake"),
	}
end

local function track(model: Instance)
	if not model:IsA("Model") or entries[model] then
		return
	end
	local entry: Entry = { Model = model, Heads = {}, Spots = {}, Tails = {}, Reverse = {}, Left = {}, Right = {}, Dirty = true, Shown = {}, Links = {} }
	-- (al cambiar piezas, p. ej. el coche aparcado que pasa a la versión completa, se vuelven a buscar)
	local function dirty()
		entry.Dirty = true
	end
	table.insert(entry.Links, model.DescendantAdded:Connect(dirty))
	table.insert(entry.Links, model.DescendantRemoving:Connect(dirty))
	entries[model] = entry
end

local function untrack(model: Instance)
	local entry = entries[model :: Model]
	if entry then
		for _, link in entry.Links do
			link:Disconnect()
		end
		entries[model :: Model] = nil
	end
	localState[model :: Model] = nil
end

-- Tu vehículo (Driving): se pinta con tu estado, sin esperar al servidor. nil = vuelve a los atributos.
function VehicleLights.setLocal(model: Model, state: { [string]: any }?)
	localState[model] = state
	if state then
		track(model)
	end
end

function VehicleLights.step()
	local t = os.clock()
	for model, entry in entries do
		if not model.Parent then
			continue
		end
		if entry.Dirty then
			scan(entry)
		end
		VehicleLights.apply(entry, localState[model] or attrsOf(model), t)
	end
end

-- (pruebas) seguir un vehículo y ver lo que se sabe de él
VehicleLights.track = track
function VehicleLights._entry(model: Model): Entry?
	return entries[model]
end

function VehicleLights.init()
	for _, model in CollectionService:GetTagged(VehicleLights.TAG) do
		track(model)
	end
	CollectionService:GetInstanceAddedSignal(VehicleLights.TAG):Connect(track)
	CollectionService:GetInstanceRemovedSignal(VehicleLights.TAG):Connect(untrack)
	RunService.Heartbeat:Connect(function()
		local ok, err = pcall(VehicleLights.step)
		if not ok then
			warn("[VehicleLights] " .. tostring(err))
		end
	end)
end

return VehicleLights
