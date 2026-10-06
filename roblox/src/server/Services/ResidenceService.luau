-- ResidenceService: la residencia universitaria del Campus Valmar.
--
--   * Algunos bloques del campus son residencias (InteriorService.residences): cada planta tiene
--     un pasillo con habitaciones, casi todas compartidas (dos camas y un compañero de cuarto) y
--     algunas individuales.
--   * Al llegar a la etapa de la universidad (AdultoJoven) te dan una habitación: con suerte (una
--     vez de cada cuatro) individual; si no, compartida. Siempre la misma para el mismo jugador.
--     Atributos: DormUnit ("clave del edificio#habitación") y DormTitle.
--   * Tu habitación tiene su nevera (FridgeService): allí guardas lo que compras en el supermercado.
--   * "Ir a casa" te lleva a tu habitación si no tienes otra vivienda.
--   * Solo si vas a la universidad (marca VaALaUniversidad de la historia): quien eligió trabajar
--     al acabar el instituto no tiene residencia.
--   * El cuarto de la historia (buildStorySet): una habitación compartida fija, con su cocinita, donde
--     pasan las misiones de la universidad (lugares HabitacionResidencia y CocinaResidencia: marcas
--     StoryArea). Está en el cielo como las demás salas, pero no se quita nunca; se entra desde la
--     puerta de la residencia ("Subir al cuarto") o con el salto de la misión, y se sale por su puerta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Floors = require(ReplicatedStorage.Shared.Floors)
local InteriorService = require(script.Parent.InteriorService)
local DataService = require(script.Parent.DataService)
local Interiors = require(script.Parent.Parent.World.Interiors)
local StoryMarks = require(script.Parent.Parent.World.Kit.StoryMarks)
local Builder = require(script.Parent.Parent.World.Builder)

local ResidenceService = {}

ResidenceService.Stages = { AdultoJoven = true } -- etapa de la universidad
ResidenceService.SingleChance = 4 -- una de cada cuatro, individual

type Room = { Building: InteriorService.Building, Floor: number, Letter: string, Id: string, Label: string, Single: boolean }

local function rooms(): ({ Room }, { Room })
	local singles, shared = {}, {}
	for _, building in InteriorService.residences() do
		for floor = 1, building.Floors - 1 do
			for _, unit in Floors.units(building.Key, building.Kind, building.Upper, floor) do
				local single = Floors.dormSingle(building.Key, unit.Id)
				local room = { Building = building, Floor = floor, Letter = unit.Letter, Id = unit.Id, Label = unit.Label, Single = single }
				table.insert(if single then singles else shared, room)
			end
		end
	end
	return singles, shared
end

-- La habitación de un jugador (siempre la misma: sale de su UserId)
function ResidenceService.roomFor(userId: number): Room?
	local singles, shared = rooms()
	local lucky = Floors.hash("suerte:" .. userId) % ResidenceService.SingleChance == 0
	local list = if lucky and #singles > 0 then singles elseif #shared > 0 then shared else singles
	if #list == 0 then
		return nil
	end
	return list[Floors.hash("habitacion:" .. userId) % #list + 1]
end

-- ¿Estudia en la universidad? (sin historia guardada —partidas antiguas o de prueba—, se da por hecho)
local function student(player: Player): boolean
	local data = DataService.get(player)
	if not data then
		return false -- (aún cargando: se vuelve a mirar cuando llegue su etapa)
	end
	local story = data.Story
	if type(story) ~= "table" then
		return true
	end
	return type(story.Flags) == "table" and story.Flags.VaALaUniversidad == true
end

function ResidenceService.assign(player: Player)
	local stage = player:GetAttribute("LifeStage")
	if type(stage) ~= "string" or not ResidenceService.Stages[stage] or not student(player) then
		player:SetAttribute("DormUnit", nil)
		player:SetAttribute("DormTitle", nil)
		return
	end
	local room = ResidenceService.roomFor(player.UserId)
	if not room then
		return
	end
	local key = room.Building.Key .. "#" .. room.Id
	if player:GetAttribute("DormUnit") == key then
		return
	end
	player:SetAttribute("DormUnit", key)
	player:SetAttribute("DormTitle", ("Residencia · %s (%s)"):format(room.Label, if room.Single then "individual" else "compartida"))
	local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
	Notify:FireClient(player, "Success", if room.Single
		then ("🛏 ¡Qué suerte! En la residencia te toca la %s, solo para ti."):format(room.Label)
		else ("🛏 En la residencia te toca la %s, compartida con otra persona."):format(room.Label))
end

-- "Ir a casa" a la habitación de la residencia (false si no tienes)
function ResidenceService.goHome(player: Player): boolean
	local key = player:GetAttribute("DormUnit")
	if type(key) ~= "string" then
		return false
	end
	local buildingKey, unitId = string.match(key, "^(.+)#(%w+)$")
	local building = buildingKey and InteriorService.byKey(buildingKey)
	local floor, letter = Floors.parseUnit(unitId or "")
	if not building or not floor then
		return false
	end
	InteriorService.goToUnit(player, building, floor, letter)
	return true
end

---------------------------------------------------------------------
-- El cuarto de la historia
---------------------------------------------------------------------

-- Fuera de la cuadrícula de salas de InteriorService (filas desde z = -6 * 220): nunca se pisan
ResidenceService.StorySetAt = CFrame.new(0, 6000, -1980)
ResidenceService.StoryKey = "Residencia:Historia" -- InteriorKey de quien está dentro (no es una sala de InteriorService)

local storySet: { Model: Model, Door: Vector3, Center: Vector3, Half: Vector3 }? = nil

local function inSet(position: Vector3): boolean
	local set = storySet
	if not set or not set.Model.Parent then
		return false
	end
	local rel = position - set.Center
	return math.abs(rel.X) <= set.Half.X and math.abs(rel.Z) <= set.Half.Z and math.abs(rel.Y) <= set.Half.Y
end

-- Quien llega dentro (por la puerta o con el salto de una misión) queda "dentro de un edificio": la
-- puerta de la calle es la de la residencia (InteriorService.leave, NearPlayer…)
local function markInside(player: Player)
	local set = storySet
	if set and player:GetAttribute("InteriorKey") == nil then
		player:SetAttribute("InteriorKey", ResidenceService.StoryKey)
		player:SetAttribute("InteriorDoor", set.Door)
	end
end

function ResidenceService.isInStorySet(player: Player): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and root:IsA("BasePart") and inSet(root.Position)
end

-- Monta el cuarto (una vez). Devuelve el modelo, o nil si aún no hay residencias.
function ResidenceService.buildStorySet(): Model?
	if storySet and storySet.Model.Parent then
		return storySet.Model
	end
	local building = InteriorService.residences()[1]
	if not building then
		return nil
	end
	local folder = workspace:FindFirstChild("ResidenceStorySet")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "ResidenceStorySet"
	local cf = ResidenceService.StorySetAt
	local r = Interiors.Dorm(folder, cf, { Seed = "residencia:historia", Single = false })
	r.Model.Name = "Interior_DormHistoria"
	-- (el compañero de cuarto de las salas normales no: aquí los compañeros son los de la historia)
	for _, d in r.Model:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("ClerkSpot") then
			d:Destroy()
		end
	end
	local W, D, H = r.W, r.D, r.H
	-- Marcas de la historia (hay que estar DENTRO): todo el cuarto, y la esquina de la cocinita
	StoryMarks.area(r.Model, "HabitacionResidencia", r.at(0, H / 2, 0), Vector3.new(W, H, D))
	StoryMarks.area(r.Model, "CocinaResidencia", r.at(-W / 2 + 5.5, H / 2, -D / 2 + 3.5), Vector3.new(11, H, 7))
	local out = if building.Out.Magnitude > 0.1 then building.Out.Unit else Vector3.new(0, 0, 1)
	local door = building.Door + out * 3
	-- Salir: a la calle, delante de la residencia
	local street = Builder.part({
		Name = "StorySetStreet",
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(door + Vector3.new(0, 3, 0)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = folder,
	})
	for _, d in r.Model:GetDescendants() do
		if d:IsA("BasePart") and d:HasTag("InteriorExit") then
			local prompt = Builder.prompt(d, "Salir", "🚪 A la calle", 0.2)
			prompt.MaxActivationDistance = 9
			prompt.Triggered:Connect(function(player)
				if ResidenceService.isInStorySet(player) then
					if player:GetAttribute("InteriorKey") == ResidenceService.StoryKey then
						InteriorService.leave(player)
					else
						InteriorService.placeAt(player, street)
					end
				end
			end)
		end
	end
	-- Entrar: desde la puerta de la residencia
	local entry = r.at(0, 3, -D / 2 + 4)
	local inside = Builder.part({
		Name = "StorySetEntry",
		Size = Vector3.new(2, 2, 2),
		CFrame = entry,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = folder,
	})
	local gate = Builder.part({
		Name = "StorySetDoor",
		Size = Vector3.new(3, 5, 1),
		CFrame = CFrame.lookAt(building.Door + Vector3.new(0, 3, 0) + out * 0.5, building.Door + Vector3.new(0, 3, 0) + out * 2),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = folder,
	})
	local up = Builder.prompt(gate, "Subir al cuarto", "🛏 Residencia · cuarto de la historia", 0.3)
	up.MaxActivationDistance = 9
	up.UIOffset = Vector2.new(0, 60) -- (debajo del "Entrar" de la puerta)
	up.Triggered:Connect(function(player)
		if player:GetAttribute("Dead") or player:GetAttribute("Teleporting") then
			return
		end
		InteriorService.placeAt(player, inside)
		player:SetAttribute("InteriorKey", ResidenceService.StoryKey)
		player:SetAttribute("InteriorDoor", door)
	end)
	folder.Parent = workspace
	storySet = {
		Model = r.Model,
		Door = door,
		Center = (cf * CFrame.new(0, H / 2, 0)).Position,
		Half = Vector3.new(W / 2 + 2, H / 2 + 4, D / 2 + 2),
	}
	return r.Model
end

function ResidenceService.init()
	local function watch(player: Player)
		player:GetAttributeChangedSignal("LifeStage"):Connect(function()
			ResidenceService.assign(player)
		end)
		task.defer(ResidenceService.assign, player)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	-- El cuarto de la historia, en cuanto InteriorService tenga las residencias
	task.spawn(function()
		for _ = 1, 120 do
			local ok, model = pcall(ResidenceService.buildStorySet)
			if not ok then
				warn("[Residencia] " .. tostring(model))
				return
			elseif model then
				break
			end
			task.wait(1)
		end
		while storySet do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				if ResidenceService.isInStorySet(player) then
					markInside(player)
				end
			end
		end
	end)
end

return ResidenceService
