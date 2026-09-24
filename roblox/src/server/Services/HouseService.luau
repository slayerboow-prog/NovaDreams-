-- HouseService: parcelas y casas.
--  * Cada jugador puede reclamar UNA parcela libre del servidor (gratis).
--  * El nivel de su casa (Config.HouseTiers) se guarda y se puede mejorar con dinero.
--  * Dentro hay cama (dormir = recuperar energía) y nevera (comida gratis con espera).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Builder = require(script.Parent.Parent.World.Builder)
local Building = require(script.Parent.Parent.World.Kit.Building)
local TownBuilder = require(script.Parent.Parent.World.TownBuilder)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local HouseService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent

type Plot = {
	Id: number,
	Model: Model,
	Origin: CFrame,
	SignLabel: TextLabel,
	Prompt: ProximityPrompt,
	Owner: Player?,
	House: Model?,
}
local plots: { [number]: Plot } = {}

local function plotOf(player: Player): Plot?
	local id = player:GetAttribute("PlotId")
	return if id then plots[id] else nil
end

---------------------------------------------------------------------
-- Construcción de la casa
---------------------------------------------------------------------

local WOOD = Color3.fromRGB(96, 66, 48)

local function furnish(model: Model, at: (number, number, number) -> CFrame, size: Vector3, plotId: number)
	-- "at" usa coordenadas interiores: y = 0 es el suelo, -Z es la fachada (puerta)
	local W, D = size.X, size.Z

	-- DORMITORIO: cama al fondo a la derecha
	local bedCf = at(W / 2 - 4.5, 0, D / 2 - 5.5)
	Builder.part({ Name = "BedFrame", Size = Vector3.new(6, 1.4, 8), CFrame = bedCf * CFrame.new(0, 0.7, 0), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	local mattress = Builder.part({
		Name = "Bed",
		Size = Vector3.new(5.6, 0.8, 7.6),
		CFrame = bedCf * CFrame.new(0, 1.8, 0),
		Color = Color3.fromRGB(238, 238, 242),
		Material = Enum.Material.Fabric,
		Tags = { "Bed" },
		Attributes = { PlotId = plotId },
		Parent = model,
	})
	Builder.decor({ Name = "Blanket", Size = Vector3.new(5.8, 0.3, 4.6), CFrame = bedCf * CFrame.new(0, 2.3, -1.4), Color = Color3.fromRGB(70, 110, 180), Material = Enum.Material.Fabric, Parent = model })
	Builder.decor({ Name = "Pillow", Size = Vector3.new(4, 0.6, 1.6), CFrame = bedCf * CFrame.new(0, 2.5, 2.8), Color = Color3.new(1, 1, 1), Material = Enum.Material.Fabric, Parent = model })
	Builder.part({ Name = "Headboard", Size = Vector3.new(6, 4, 0.5), CFrame = bedCf * CFrame.new(0, 2, 4.1), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	Builder.part({ Name = "Nightstand", Size = Vector3.new(2, 2.2, 2), CFrame = at(W / 2 - 9, 1.1, D / 2 - 2.2), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	local lamp = Builder.decor({ Name = "BedLamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = at(W / 2 - 9, 2.9, D / 2 - 2.2), Color = Color3.fromRGB(255, 236, 200), Material = Enum.Material.Neon, Parent = model })
	local lampLight = Instance.new("PointLight")
	lampLight.Range = 10
	lampLight.Brightness = 0.8
	lampLight.Color = Color3.fromRGB(255, 214, 160)
	lampLight.Parent = lamp

	local sleep = Builder.prompt(mattress, "Dormir", "Cama", 0.5)
	sleep.Triggered:Connect(function(player)
		HouseService.sleep(player, plotId)
	end)

	-- COCINA: nevera y encimera al fondo a la izquierda
	Builder.part({ Name = "FridgeBody", Size = Vector3.new(3.2, 7, 3), CFrame = at(-W / 2 + 2.6, 3.5, D / 2 - 2.5), Color = Color3.fromRGB(226, 229, 233), Material = Enum.Material.Metal, Parent = model })
	Builder.part({
		Name = "Fridge",
		Size = Vector3.new(0.3, 1.4, 0.3),
		CFrame = at(-W / 2 + 3.6, 4.2, D / 2 - 4.15),
		Color = Color3.fromRGB(90, 90, 96),
		Tags = { "FoodStand" },
		Attributes = { FoodId = "Nevera", PlotId = plotId },
		Parent = model,
	})
	Builder.part({ Name = "KitchenCounter", Size = Vector3.new(6, 3.6, 2.6), CFrame = at(-W / 2 + 7.4, 1.8, D / 2 - 2.3), Color = Color3.fromRGB(240, 238, 232), Material = Enum.Material.Plaster, Parent = model })
	Builder.decor({ Name = "Worktop", Size = Vector3.new(6.2, 0.3, 2.8), CFrame = at(-W / 2 + 7.4, 3.75, D / 2 - 2.3), Color = Color3.fromRGB(60, 62, 66), Material = Enum.Material.Granite, Parent = model })

	-- SALÓN: sofá mirando a la tele, alfombra y mesa baja
	local sofaCf = at(-W / 2 + 3, 0, -2) * CFrame.Angles(0, math.rad(-90), 0)
	local sofaColor = Color3.fromRGB(116, 128, 140)
	Builder.part({ Name = "SofaSeat", Size = Vector3.new(9, 1.6, 3.4), CFrame = sofaCf * CFrame.new(0, 1, 0), Color = sofaColor, Material = Enum.Material.Fabric, Parent = model })
	Builder.part({ Name = "SofaBack", Size = Vector3.new(9, 3, 1), CFrame = sofaCf * CFrame.new(0, 2.2, 1.6), Color = sofaColor, Material = Enum.Material.Fabric, Parent = model })
	for _, x in { -4.8, 4.8 } do
		Builder.part({ Name = "SofaArm", Size = Vector3.new(0.8, 2.4, 3.4), CFrame = sofaCf * CFrame.new(x, 1.6, 0), Color = sofaColor, Material = Enum.Material.Fabric, Parent = model })
	end
	Builder.decor({ Name = "Rug", Size = Vector3.new(6, 0.1, 8), CFrame = at(-W / 2 + 8.5, 0.05, -2), Color = Color3.fromRGB(176, 88, 68), Material = Enum.Material.Fabric, Parent = model })
	Builder.part({ Name = "CoffeeTable", Size = Vector3.new(2.5, 1.4, 4), CFrame = at(-W / 2 + 8, 0.7, -2), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	Builder.part({ Name = "TVStand", Size = Vector3.new(1.6, 2, 5), CFrame = at(2, 1, -2), Color = WOOD, Material = Enum.Material.Wood, Parent = model })
	Builder.decor({ Name = "TV", Size = Vector3.new(0.3, 3, 5), CFrame = at(2, 3.6, -2), Color = Color3.fromRGB(18, 18, 22), Material = Enum.Material.Glass, Parent = model })

	-- Planta junto a la entrada
	Builder.part({ Name = "Pot", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = at(W / 2 - 2, 0.8, -D / 2 + 2), Color = Color3.fromRGB(170, 90, 60), Material = Enum.Material.Plaster, Parent = model })
	Builder.decor({ Name = "Plant", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6), CFrame = at(W / 2 - 2, 2.6, -D / 2 + 2), Color = Color3.fromRGB(70, 124, 58), Material = Enum.Material.LeafyGrass, Parent = model })
end

local function buildHouse(plot: Plot, tier: number)
	if plot.House then
		plot.House:Destroy()
		plot.House = nil
	end
	local info = Config.HouseTiers[tier]
	local size = info.Size
	-- Colocamos la casa hacia el fondo de la parcela (50x50), dejando jardín delante
	local offsetZ = 25 - size.Z / 2 - 3
	local model, at = Building.build({
		Name = "House",
		Parent = plot.Model,
		CFrame = plot.Origin * CFrame.new(0, 0, offsetZ),
		Width = size.X,
		Depth = size.Z,
		Floors = if size.Y >= 16 then 2 else 1,
		Style = "Casa",
		GroundFloor = "House",
		WallColor = info.Color,
		FloorColor = Color3.fromRGB(176, 136, 98),
	})
	furnish(model, at, size, plot.Id)
	plot.House = model
end

local function refreshSign(plot: Plot)
	local owner = plot.Owner
	if not owner then
		plot.SignLabel.Text = "SE VENDE\nLibre"
		plot.Prompt.ActionText = "Reclamar casa"
		plot.Prompt.ObjectText = "Parcela " .. plot.Id .. " · Gratis"
		return
	end
	local data = DataService.get(owner)
	local tier = if data then data.HouseTier else 1
	local nextTier = Config.HouseTiers[tier + 1]
	plot.SignLabel.Text = ("%s\n%s"):format(owner.DisplayName, Config.HouseTiers[tier].Name)
	if nextTier then
		plot.Prompt.ActionText = "Mejorar a " .. nextTier.Name
		plot.Prompt.ObjectText = Format.money(nextTier.Price)
	else
		plot.Prompt.ActionText = "Casa al máximo"
		plot.Prompt.ObjectText = Config.HouseTiers[tier].Name
	end
end

---------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------

function HouseService.claim(player: Player, plot: Plot)
	local data = DataService.get(player)
	if not data then
		return
	end
	if plotOf(player) then
		Notify:FireClient(player, "Error", "Ya tienes una casa en este servidor.")
		return
	end
	plot.Owner = player
	player:SetAttribute("PlotId", plot.Id)
	buildHouse(plot, data.HouseTier)
	refreshSign(plot)
	Notify:FireClient(player, "Success", "¡Bienvenido a tu nueva casa! Pulsa 'Casa' para volver cuando quieras.")
	StoryEvents.emit(player, "HomeClaimed", { PlotId = plot.Id })
end

function HouseService.upgrade(player: Player, plot: Plot)
	local data = DataService.get(player)
	if not data then
		return
	end
	local nextTier = Config.HouseTiers[data.HouseTier + 1]
	if not nextTier then
		Notify:FireClient(player, "Info", "Tu casa ya es la mejor de la ciudad.")
		return
	end
	if not DataService.spend(player, nextTier.Price) then
		Notify:FireClient(player, "Error", ("Necesitas %s para mejorar tu casa."):format(Format.money(nextTier.Price)))
		return
	end
	data.HouseTier += 1
	buildHouse(plot, data.HouseTier)
	refreshSign(plot)
	Notify:FireClient(player, "Success", ("¡Enhorabuena! Ahora vives en: %s"):format(nextTier.Name))
end

function HouseService.release(player: Player)
	local plot = plotOf(player)
	if not plot then
		return
	end
	if plot.House then
		plot.House:Destroy()
	end
	plot.House = TownBuilder.showHouse(plot.Model, plot.Origin)
	plot.Owner = nil
	player:SetAttribute("PlotId", nil)
	refreshSign(plot)
end

function HouseService.sleep(player: Player, plotId: number)
	if player:GetAttribute("PlotId") ~= plotId then
		Notify:FireClient(player, "Error", "Esta cama no es tuya.")
		return
	end
	if player:GetAttribute("Sleeping") then
		return
	end
	player:SetAttribute("Sleeping", true)
	Notify:FireClient(player, "Sleep", "Zzz...")
	task.wait(Config.SleepSeconds)
	if player.Parent then
		player:SetAttribute("Sleeping", nil)
		NeedsService.change(player, 0, Config.Needs.Max)
		Notify:FireClient(player, "Success", "Has dormido genial. ¡Energía al máximo!")
		StoryEvents.emit(player, "Slept", {})
	end
end

function HouseService.goHome(player: Player)
	local plot = plotOf(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not plot then
		Notify:FireClient(player, "Error", "Aún no tienes casa. Busca un cartel de SE VENDE en la zona residencial.")
		return
	end
	if root then
		player.Character:PivotTo(plot.Origin * CFrame.new(0, 4, -23.5) * CFrame.Angles(0, math.pi, 0))
	end
end

---------------------------------------------------------------------

function HouseService.init()
	for _, model in CollectionService:GetTagged("Plot") do
		local id = model:GetAttribute("PlotId")
		local sign = model:FindFirstChild("PlotSign") :: BasePart
		local label = sign:FindFirstChild("Label", true) :: TextLabel
		local prompt = Builder.prompt(sign, "Reclamar casa", "", 0.5)
		local plot: Plot = {
			Id = id,
			Model = model,
			Origin = model:GetAttribute("Origin"),
			SignLabel = label,
			Prompt = prompt,
			House = model:FindFirstChild("House") :: Model?, -- casa de muestra "en venta"
		}
		plots[id] = plot
		refreshSign(plot)

		prompt.Triggered:Connect(function(player)
			if plot.Owner == nil then
				HouseService.claim(player, plot)
			elseif plot.Owner == player then
				HouseService.upgrade(player, plot)
			else
				Notify:FireClient(player, "Info", ("Esta es la casa de %s."):format(plot.Owner.DisplayName))
			end
		end)
	end

	local GoHome = ReplicatedStorage.Remotes.GoHome :: RemoteEvent
	GoHome.OnServerEvent:Connect(HouseService.goHome)

	Players.PlayerRemoving:Connect(HouseService.release)
end

return HouseService
