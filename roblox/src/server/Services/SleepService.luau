-- SleepService: dormir en una cama.
--
--   * Energía y estamina al máximo.
--   * La cama pasa a ser tu PUNTO DE REAPARICIÓN: si te caes, te quedas sin vida o vuelves a entrar al
--     juego, apareces ahí (se guarda con tus datos).
--   * De noche (desde las 18:00, o de madrugada antes de las 8:30), la noche pasa: te despiertas a las
--     8:30 del día siguiente. Si duermes a las 21:30, te levantas a las 8:30.
--     La hora es la misma para todo el servidor, así que la noche solo pasa cuando duermen todos los
--     jugadores (o si estás solo). Mientras tanto esperas en la cama unos segundos; si los demás siguen
--     despiertos, te levantas descansado pero la noche sigue.
--   * De día es una siesta: descansas del todo, pero no pasa el tiempo.
--
-- Camas que valen:
--   * La de tu casa (HouseService → SleepService.sleep).
--   * La de tu casa familiar (StoryProp PropId = "Cama" con el mismo HomeId que tu FamilyHomeId).
--   * Cualquier pieza con tag "PublicBed" (camas de la residencia, hoteles… las pone el mapa).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local ProgressionService = require(script.Parent.ProgressionService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local SleepService = {}

local Notify: RemoteEvent
local sleepers: { [Player]: boolean } = {} -- quién está en la cama esperando a que pase la noche
local beds: { [Player]: BasePart } = {} -- la cama en la que duerme cada uno (para ver si se ha levantado)
local lyingAt: { [Player]: Vector3 } = {} -- dónde estaba al acostarse
local spawnBeds: { [Player]: BasePart } = {} -- la cama de su punto de reaparición (si se borra, no vale)
-- Tumbados en la cama de un piso (InteractService): cuentan como dormidos mientras sigan en ella.
-- Así hay una sola regla de noche para todo el servidor (antes el piso tenía la suya, de 21:00 a 7:00)
local resting: { [Player]: () -> boolean } = {}

local BED_RANGE = 10 -- si te alejas más que esto de donde te acostaste, ya no estás durmiendo
local SKY_Y = 3000 -- por encima están las salas de los edificios: se rehacen y no son un sitio fijo

-- ¿Sigue tumbado en su cama? (la cama sigue ahí, está vivo y no se ha movido de donde se acostó:
-- ni andando ni teletransportado)
local function inBed(player: Player): boolean
	local bed = beds[player]
	local at = lyingAt[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return bed ~= nil
		and bed.Parent ~= nil
		and at ~= nil
		and root ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and (root.Position - at).Magnitude <= BED_RANGE
end

-- Se ha levantado (o ha muerto, o se ha ido): deja de contar como dormido, sin descanso
local function getUp(player: Player)
	sleepers[player] = nil
	beds[player] = nil
	lyingAt[player] = nil
	player:SetAttribute("Sleeping", nil)
end

local function isNight(clock: number): boolean
	return clock >= Config.SleepNightFrom or clock < Config.WakeClockTime
end

local function formatClock(clock: number): string
	local hours = math.floor(clock)
	return ("%d:%02d"):format(hours, math.floor((clock - hours) * 60 + 0.5))
end

-- ¿Quién cuenta para «que duerma todo el servidor»? (los bebés duermen en la cuna a su aire)
local function awakePlayers(): number
	local awake = 0
	for _, other in Players:GetPlayers() do
		-- Quien se ha ido de la cama ya no duerme: no puede hacer pasar la noche
		if sleepers[other] and not inBed(other) then
			getUp(other)
		end
		local still = resting[other]
		if still and not still() then
			resting[other] = nil
		end
		if not sleepers[other] and not resting[other] and other:GetAttribute("LifeStage") ~= "Bebe" and other.Character then
			awake += 1
		end
	end
	return awake
end

local function rest(player: Player)
	NeedsService.change(player, 0, Config.Needs.Max)
	ProgressionService.restoreStamina(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and humanoid.MaxHealth then
		humanoid.Health = humanoid.MaxHealth
	end
end

local function wake(player: Player, message: string)
	sleepers[player] = nil
	beds[player] = nil
	lyingAt[player] = nil
	player:SetAttribute("Sleeping", nil)
	if player.Parent then
		rest(player)
		Notify:FireClient(player, "Success", message)
		StoryEvents.emit(player, "Slept", {})
	end
end

-- Punto de reaparición: junto a la cama (encima, para no aparecer dentro de una pared)
local function setSpawn(player: Player, bed: BasePart)
	local data = DataService.get(player)
	if not data then
		return
	end
	-- Las camas de las misiones (se borran al acabar) y las de las salas del cielo (se rehacen) no
	-- sirven como punto fijo: reaparecerías en el aire
	local scenes = workspace:FindFirstChild("StoryScenes")
	if bed.Position.Y > SKY_Y or (scenes and bed:IsDescendantOf(scenes)) then
		return
	end
	spawnBeds[player] = bed
	local top = bed.Position + Vector3.new(0, bed.Size.Y / 2 + 3, 0)
	data.SpawnPoint = { X = math.round(top.X * 10) / 10, Y = math.round(top.Y * 10) / 10, Z = math.round(top.Z * 10) / 10 }
	player:SetAttribute("SpawnPoint", top)
end

-- Todos dormidos (o solo tú): amanece para todos
local function passNight()
	-- (se busca al usarlo: la cama del piso, InteractService, puede cargar este módulo muy pronto)
	local WorldService = require(script.Parent.WorldService) :: any
	local newDay = WorldService.skipTo(Config.WakeClockTime)
	local text = ("☀️ ¡Buenos días! Son las %s%s. Energía y estamina al máximo."):format(
		formatClock(Config.WakeClockTime),
		if newDay then " de un nuevo día" else ""
	)
	for sleeper in table.clone(sleepers) do
		wake(sleeper, text)
	end
	for other in table.clone(resting) do
		resting[other] = nil
		if other.Parent and Notify then
			Notify:FireClient(other, "Success", text)
		end
	end
end

-- La cama de un piso (InteractService): se tumba y cuenta como dormido mientras stillThere() sea
-- verdad. Si es de noche y ya duermen todos, pasa la noche (la misma regla que SleepService.sleep).
-- Devuelve true si ha pasado la noche.
function SleepService.restInBed(player: Player, stillThere: () -> boolean): boolean
	if player:GetAttribute("LifeStage") == "Bebe" then
		return false
	end
	resting[player] = stillThere
	if isNight(Lighting.ClockTime) and awakePlayers() == 0 then
		passNight()
		return true
	end
	return false
end

-- Se ha levantado de la cama del piso: ya no cuenta como dormido
function SleepService.leaveBed(player: Player)
	resting[player] = nil
end

function SleepService.sleep(player: Player, bed: BasePart)
	if player:GetAttribute("Sleeping") or player:GetAttribute("LifeStage") == "Bebe" then
		return
	end
	player:SetAttribute("Sleeping", true)
	local character = player.Character
	local startRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	beds[player] = bed
	lyingAt[player] = if startRoot then startRoot.Position else nil
	setSpawn(player, bed)
	Notify:FireClient(player, "Sleep", "Zzz...")
	-- Si muere o le cambia el personaje mientras duerme, se acaba el sueño al momento
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local died = humanoid and humanoid.Died:Connect(function()
		getUp(player)
	end)
	local removing = player.CharacterRemoving:Connect(function()
		getUp(player)
	end)
	local function cleanup()
		if died then
			died:Disconnect()
		end
		removing:Disconnect()
	end
	local waited = 0
	while waited < Config.SleepSeconds do
		local step = math.min(0.5, Config.SleepSeconds - waited)
		task.wait(step)
		waited += step
		if not player.Parent or beds[player] ~= bed or not inBed(player) then
			if beds[player] == bed then
				getUp(player)
			end
			cleanup()
			return
		end
	end
	if not player.Parent then
		cleanup()
		return
	end
	if not isNight(Lighting.ClockTime) then
		cleanup()
		wake(player, "😴 Siesta: energía y estamina al máximo. (De noche, desde las 18:00, dormir te lleva a la mañana siguiente.) Aparecerás aquí si reapareces.")
		return
	end
	sleepers[player] = true
	if awakePlayers() == 0 then
		cleanup()
		passNight()
		return
	end
	Notify:FireClient(player, "Info", ("Zzz… Esperando a que se acuesten los demás (%d despiertos). La hora es la misma para todo el servidor."):format(awakePlayers()))
	waited = 0
	while sleepers[player] and waited < Config.SleepWaitSeconds do
		task.wait(1)
		waited += 1
		if sleepers[player] and not inBed(player) then
			-- Se ha levantado: sigue despierto y la noche no pasa por él
			getUp(player)
		elseif sleepers[player] and awakePlayers() == 0 then
			cleanup()
			passNight()
			return
		end
	end
	cleanup()
	if sleepers[player] then
		wake(player, "Has descansado (energía y estamina al máximo), pero los demás siguen despiertos: la noche continúa.")
	end
end

-- ¿El punto guardado sigue valiendo? (datos viejos con camas del cielo, o la cama ya no está)
local function validSpawn(player: Player, point: any): boolean
	if type(point) ~= "table" or type(point.X) ~= "number" or type(point.Y) ~= "number" or type(point.Z) ~= "number" then
		return false
	end
	if point.X ~= point.X or point.Y ~= point.Y or point.Z ~= point.Z or point.Y > SKY_Y then
		return false
	end
	if point.Y < -400 then
		return false -- debajo del mapa (ahí Roblox borra al personaje)
	end
	local bed = spawnBeds[player]
	return not (bed and bed.Parent == nil) -- la cama de esta partida se ha borrado
end

-- Quita un punto de reaparición que ya no sirve (para no volver a intentarlo)
local function clearSpawn(player: Player)
	local data = DataService.get(player)
	if data then
		data.SpawnPoint = nil
	end
	spawnBeds[player] = nil
	player:SetAttribute("SpawnPoint", nil)
end

-- Al aparecer, a tu cama (si has dormido en alguna). Los bebés aparecen en su cuna (BabyService).
-- Si acabas de morir te lleva el hospital (HospitalService), y los presos van a su celda: aquí nada.
local function toSpawn(player: Player, character: Model)
	local data = DataService.get(player)
	local point = data and data.SpawnPoint
	if type(point) ~= "table" or player:GetAttribute("LifeStage") == "Bebe" then
		return
	end
	-- Al entrar en el juego manda la posición guardada (PositionService): la cama es para cuando
	-- reapareces después de morir. Mientras no hay "SpawnReady", este personaje es el de la entrada
	local saved = data and data.Position
	if not player:GetAttribute("SpawnReady") and type(saved) == "table" and type(saved.X) == "number" and type(saved.Y) == "number" and type(saved.Z) == "number" then
		return
	end
	-- Se mira ya, al aparecer: el hospital quita "Dead" en cuanto termina de llevarte
	if player:GetAttribute("Dead") or player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	task.wait(0.6) -- después de que LifeService ajuste el tamaño
	if player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil then
		return
	end
	if point.Y > SKY_Y or (spawnBeds[player] and spawnBeds[player].Parent == nil) then
		clearSpawn(player)
		return
	end
	if not validSpawn(player, point) then
		return
	end
	if root and character.Parent then
		character:PivotTo(CFrame.new(point.X, point.Y, point.Z))
	end
end

local function bedPrompt(part: BasePart, check: (Player) -> boolean)
	if part:FindFirstChild("SleepPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SleepPrompt"
	prompt.ActionText = "Dormir"
	prompt.ObjectText = "Cama"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		if check(player) then
			task.spawn(SleepService.sleep, player, part)
		else
			Notify:FireClient(player, "Error", "Esta cama no es tuya.")
		end
	end)
end

local function watchBed(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	if instance:HasTag("PublicBed") then
		bedPrompt(instance, function()
			return true
		end)
	elseif instance:GetAttribute("PropId") == "Cama" and instance:GetAttribute("HomeId") ~= nil then
		-- La cama de la casa familiar: solo para quien vive en esa casa
		bedPrompt(instance, function(player)
			return player:GetAttribute("FamilyHomeId") == instance:GetAttribute("HomeId")
		end)
	end
end

function SleepService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	for _, tag in { "StoryProp", "PublicBed" } do
		for _, instance in CollectionService:GetTagged(tag) do
			watchBed(instance)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(watchBed)
	end
	local function watchPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			toSpawn(player, character)
		end)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	DataService.onLoaded(function(player, data)
		local point = data.SpawnPoint
		if type(point) == "table" and type(point.Y) == "number" and point.Y > SKY_Y then
			-- Guardado antes de este arreglo con una cama del cielo: ya no vale
			data.SpawnPoint = nil
		elseif type(point) == "table" then
			player:SetAttribute("SpawnPoint", Vector3.new(point.X, point.Y, point.Z))
			if player.Character then
				task.spawn(toSpawn, player, player.Character)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		sleepers[player] = nil
		beds[player] = nil
		lyingAt[player] = nil
		spawnBeds[player] = nil
		resting[player] = nil
		-- Si se va el último despierto, los que esperaban en la cama ya pueden pasar la noche
		task.defer(function()
			if next(sleepers) and awakePlayers() == 0 then
				passNight()
			end
		end)
	end)
end

return SleepService
