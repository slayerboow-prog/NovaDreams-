-- PositionService: al salir del juego se guarda dónde estabas (posición exacta y hacia dónde mirabas)
-- y al volver a entrar apareces en ese mismo sitio, no en la plaza.
--
--  * Se apunta cada pocos segundos y justo antes de cada guardado (DataService.beforeSave),
--    así vale también si el móvil se desconecta de golpe.
--  * Los bebés no: siempre despiertan en su cuna (BabyService).
--  * Solo se apuntan sitios seguros: nadando, en un barco en el agua, cayendo o en el aire no (se
--    queda el último en tierra firme); dentro de un edificio, su puerta; en la cárcel, el de antes.
--  * Si debajo del punto guardado ya no hay suelo (el mapa ha cambiado) o es agua, a tu cama (si
--    has dormido en alguna); si no, a la entrada del juego.
--  * Al terminar pone el atributo "SpawnReady" en el jugador: la historia (LifeStoryService)
--    espera a eso para montar las escenas donde de verdad estás.
--  * Nunca se apunta ni se vuelve a un sitio bajo tierra o dentro de algo sólido (el silo de la
--    granja, una pared, un edificio): al cargar, una partida con un sitio así se arregla sola y se
--    busca el sitio libre más cercano con suelo (Shared/SafeGround + World/SafeSpot).
--  * Vigilante para TODOS: quien lleva más de 2 s enterrado o metido dentro de algo (o cae por
--    debajo del mapa) aparece en el suelo libre más cercano, o en su cama, o en la entrada.

local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local SafeGround = require(game:GetService("ReplicatedStorage").Shared.SafeGround)
local SafeSpot = require(script.Parent.Parent.World.SafeSpot)

local PositionService = {}

local RECORD_SECONDS = 3
local V = Vector3.new

local function valid(saved: any): boolean
	if type(saved) ~= "table" then
		return false
	end
	for _, key in { "X", "Y", "Z" } do
		local n = saved[key]
		if type(n) ~= "number" or n ~= n or math.abs(n) > 1e6 then
			return false
		end
	end
	return SafeGround.validSaved(saved, math.max(workspace.FallenPartsDestroyHeight + 20, SafeGround.SafeMinY))
end

-- ¿Es un buen sitio para volver a aparecer? En el agua (nadando, buceando, en un barco) o en el
-- aire (saltando, cayendo, en parapente…) no: se guarda el último sitio en tierra firme.
local function safeSpot(humanoid: Humanoid): boolean
	local ok, safe = pcall(function()
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Swimming or state == Enum.HumanoidStateType.Freefall
			or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Flying then
			return false
		end
		local floor = humanoid.FloorMaterial
		if floor == Enum.Material.Water then
			return false
		end
		local seat = humanoid.SeatPart
		if seat then
			-- En un vehículo: vale si está en tierra (no un barco en el agua ni un avión en el aire)
			return floor ~= Enum.Material.Air or seat.AssemblyLinearVelocity.Magnitude < 1
		end
		return floor ~= Enum.Material.Air
	end)
	return not ok or safe == true
end

-- Apunta en los datos dónde está ahora el jugador (si está vivo y en el mapa)
local function record(player: Player, data: { [string]: any })
	if not player:GetAttribute("SpawnReady") then
		return -- todavía no ha aparecido donde toca: no pisar lo guardado con la plaza
	end
	if data.Life and data.Life.Stage == "Bebe" then
		data.Position = nil
		return
	end
	if player:GetAttribute("InPrologue") then
		return -- en el sueño del prólogo: se guarda donde estaba antes de dormirse
	end
	if player:GetAttribute("JailUntil") ~= nil or player:GetAttribute("OnTrial") ~= nil then
		-- En la cárcel (o en un juicio): se queda el sitio de antes. Si al volver la condena sigue,
		-- JusticeService le lleva a su celda; si ya se ha cumplido, aparece en la calle, no en la celda.
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local position = root.Position
	-- Dentro de un edificio (sala de InteriorService): se guarda la puerta, en la calle
	local door = player:GetAttribute("InteriorDoor")
	-- Volando (FlightService): se guarda la sala de llegadas del vuelo, en el suelo
	local landing = player:GetAttribute("FlightLanding")
	if typeof(door) == "Vector3" then
		position = door
	elseif typeof(landing) == "Vector3" then
		position = landing
	elseif not safeSpot(humanoid) then
		return -- nadando, en un barco o en el aire: se queda el último sitio seguro que se apuntó
	elseif player:GetAttribute("StoryCaught") or SafeSpot.buried(character :: Model) then
		return -- en plena captura de una misión, o enterrado / dentro de algo: el último sitio bueno
	end
	local look = root.CFrame.LookVector
	local saved = { X = position.X, Y = position.Y, Z = position.Z, Yaw = math.atan2(-look.X, -look.Z) }
	if valid(saved) then
		data.Position = saved
	end
end

-- Pone al jugador donde lo dejó (solo al entrar, no al reaparecer tras caerse). Si ahí ya no hay
-- suelo, es agua o el sitio está bajo tierra o dentro de algo sólido (partidas rotas de antes de este
-- arreglo), al sitio libre más cercano; si no hay ninguno, a su cama; si no, la entrada del juego.
local function restore(player: Player, data: { [string]: any })
	local fixed = SafeGround.repairSaved(data, math.max(workspace.FallenPartsDestroyHeight + 20, SafeGround.SafeMinY))
	if #fixed > 0 then
		warn(("[PositionService] %s: sitio guardado roto (%s), se descarta"):format(player.Name, table.concat(fixed, ", ")))
	end
	local saved = data.Position
	if valid(saved) and not (data.Life and data.Life.Stage == "Bebe") then
		local character = player.Character or player.CharacterAdded:Wait()
		local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		task.wait(0.3) -- dejar que LifeService le dé su tamaño
		if root and root.Parent and player.Parent then
			local position = V(saved.X, saved.Y, saved.Z)
			pcall(function()
				player:RequestStreamAroundAsync(position, 5)
			end)
			-- El sitio libre más cercano con suelo de verdad (no agua, no bajo tierra, no dentro de
			-- una pared ni de un modelo; ni encima de un coche aparcado o de un personaje)
			local function landing(at: Vector3): Vector3?
				-- El suelo justo debajo (desde poco más arriba: dentro de un edificio daría con el techo)
				local y = SafeSpot.groundAt(at.X, at.Z, at.Y + 1, 40)
				local below = if y then V(at.X, y, at.Z) else nil
				if below and not SafeSpot.stuckAt(below) then
					return below
				end
				return SafeSpot.find(at)
			end
			local feet = landing(position)
			local bed = data.SpawnPoint
			if not feet and valid(bed) then
				position = V(bed.X, bed.Y, bed.Z)
				pcall(function()
					player:RequestStreamAroundAsync(position, 5)
				end)
				feet = landing(position)
			end
			if feet then
				SafeSpot.place(character, feet, saved.Yaw or 0)
				SafeSpot.release(character)
			else
				data.Position = nil -- (no hay donde: se queda en la entrada y no se vuelve a intentar)
			end
		end
	end
	if player.Parent then
		player:SetAttribute("SpawnReady", true)
	end
end

-- Vigilante anti-enterrados (todos los jugadores): bajo tierra o dentro de algo sólido más de
-- SafeGround.BuriedSeconds -> al suelo libre más cercano (o su cama, o la entrada)
local guard: { [Player]: { [string]: any } } = {}

local function exempt(player: Player, character: Model, humanoid: Humanoid?, root: BasePart): boolean
	if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart ~= nil or root.Anchored then
		return true -- muerto, sentado (coche, banco, autobús) o colocado a propósito por otro sistema
	end
	for _, attribute in { "Teleporting", "Dead", "KO", "Sleeping", "UsePose", "JailUntil", "OnTrial" } do
		if player:GetAttribute(attribute) ~= nil then
			return true
		end
	end
	return not player:GetAttribute("SpawnReady")
end

function PositionService.checkBuried(player: Player, now: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root then
		guard[player] = nil
		return false
	end
	local state = guard[player] or {}
	guard[player] = state
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local buried = not exempt(player, character, humanoid, root) and SafeSpot.buried(character)
	-- Cayendo por debajo de todo el mapa: sin esperar
	local seconds = if root.Position.Y < SafeGround.SafeMinY then 0 else SafeGround.BuriedSeconds
	if not SafeGround.track(state, buried, now, seconds) then
		return false
	end
	state.Since = nil
	local data = DataService.get(player)
	local bed = data and data.SpawnPoint
	local home = if valid(bed) then V(bed.X, bed.Y, bed.Z) else nil
	local was = root.Position
	local at = SafeSpot.rescue(player, home)
	warn(("[PositionService] %s estaba bajo tierra o dentro de algo (%.0f, %.0f, %.0f): rescatado a %s"):format(
		player.Name, was.X, was.Y, was.Z, tostring(at)))
	return true
end

function PositionService.init()
	DataService.onLoaded(function(player, data)
		restore(player, data)
	end)
	DataService.beforeSave(record)
	Players.PlayerRemoving:Connect(function(player)
		guard[player] = nil
	end)
	-- Al reaparecer (tras morir o caerse): si el sitio donde sale está enterrado, se arregla enseguida
	local function watchCharacter(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.delay(1, function()
				if player.Parent and player.Character == character and SafeSpot.buried(character) then
					local data = DataService.get(player)
					local bed = data and data.SpawnPoint
					SafeSpot.rescue(player, if valid(bed) then V(bed.X, bed.Y, bed.Z) else nil)
				end
			end)
		end)
	end
	Players.PlayerAdded:Connect(watchCharacter)
	for _, player in Players:GetPlayers() do
		watchCharacter(player)
	end
	task.spawn(function()
		while true do
			task.wait(SafeGround.CheckEvery)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(PositionService.checkBuried, player, now)
				if not ok then
					warn("[PositionService] vigilante: " .. tostring(err))
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(RECORD_SECONDS)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(function()
					local data = DataService.get(player)
					if data then
						record(player, data)
					end
				end)
				if not ok then
					warn("[PositionService] " .. tostring(err))
				end
			end
		end
	end)
end

return PositionService
