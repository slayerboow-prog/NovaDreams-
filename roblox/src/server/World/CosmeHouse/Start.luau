-- Start: pone en marcha la casa de Cosme al arrancar el servidor (lo llama server/Main después de los
-- servicios): avisos y muebles (Interactions), la rutina de Cosme (NPC) y la historia (QuestHooks).
--
-- Si el archivo del juego se construyó antes de la casa nueva (todavía trae el garaje viejo
-- «GarajeCosme» suelto y casas en la manzana), se quita lo viejo y se construye aquí la casa.

local Build = require(script.Parent.Build)
local Interactions = require(script.Parent.Interactions)
local NPC = require(script.Parent.NPC)

local Start = {}

local function findHouse(): Model?
	local town = workspace:FindFirstChild("Town")
	local found = town and town:FindFirstChild(Build.Name, true)
	return if found and found:IsA("Model") then found else nil
end

-- Archivo viejo: fuera el garaje de antes (con su marca GarajeCosme) y lo que ocupe la parcela
local function upgradeOldPlace(): Model?
	local Region = require(script.Parent.Parent.Region) :: any
	local site = Region.cosmeSite and Region.cosmeSite()
	local town = workspace:FindFirstChild("Town")
	if not site or not town then
		return nil
	end
	local center = site.CFrame.Position
	local half = site.Half
	local function inside(p: Vector3): boolean
		return math.abs(p.X - center.X) < half and math.abs(p.Z - center.Z) < half
	end
	local parent: Instance = town
	for _, d in town:GetDescendants() do
		if d:IsA("Model") and d.Name == "GarajeCosme" and d:FindFirstChild("StorySpot_GarajeCosme") then
			d:Destroy()
		end
	end
	for _, d in town:GetDescendants() do
		if d:IsA("Model") and d.Name == "Vivienda" and d.Parent then
			local ok, pivot = pcall(function()
				return d:GetPivot().Position
			end)
			if ok and inside(pivot) then
				parent = d.Parent :: Instance
				d:Destroy()
			end
		elseif d:IsA("BasePart") and d.Name == "BlockGround" and inside(d.Position) and d.Size.X > 90 then
			d:Destroy()
		end
	end
	return Build.build(parent, site.CFrame)
end

function Start.start()
	local house = findHouse()
	if not house then
		local ok, built = pcall(upgradeOldPlace)
		if ok then
			house = built
		else
			warn("[CasaCosme] " .. tostring(built))
		end
	end
	if not house then
		return
	end
	local ok, err = pcall(Interactions.start, house)
	if not ok then
		warn("[CasaCosme] Interactions: " .. tostring(err))
	end
	task.spawn(function()
		local ok2, err2 = pcall(NPC.start, house, Interactions)
		if not ok2 then
			warn("[CasaCosme] NPC: " .. tostring(err2))
		end
	end)
end

return Start
