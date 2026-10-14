-- SafeSpot (servidor): mira el mundo de verdad para que nadie acabe bajo tierra, dentro de una pared
-- o de un modelo (el silo, un edificio…). Las cuentas están en Shared/SafeGround (con pruebas).
--
--   SafeSpot.groundAt(x, z, fromY)  Suelo de verdad bajo (x, z) desde fromY (sin agua)
--   SafeSpot.inTerrain(point)       ¿Ese punto está dentro de terreno macizo?
--   SafeSpot.free(feet)             ¿Cabe alguien de pie con los pies ahí? (nada sólido en el cuerpo)
--   SafeSpot.stuckAt(feet)          ¿De pie ahí quedaría atrapado? (dentro del terreno o de algo grande)
--   SafeSpot.find(center)           Pies en el sitio libre más cercano con suelo debajo (o nil)
--   SafeSpot.buried(character)      ¿Está enterrado o metido dentro de algo sólido?
--   SafeSpot.place(character, feet) Le pone de pie ahí (sin velocidad)
--   SafeSpot.release(character)     Le devuelve el poder andar (velocidad, salto, sin anclar…)
--   SafeSpot.rescue(player, home?)  Le saca al sitio libre más cercano (o a su casa / la entrada)
--
-- Todo va con pcall: si algo de Roblox falla, se da por bueno (nunca se teletransporta por un error).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ground = require(ReplicatedStorage.Shared.Ground)
local SafeGround = require(ReplicatedStorage.Shared.SafeGround)

local SafeSpot = {}

local V = Vector3.new

local function characters(): { Instance }
	local list = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	return list
end

function SafeSpot.groundAt(x: number, z: number, fromY: number, depth: number?): number?
	local ok, y = pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = characters()
		params.IgnoreWater = false
		local hit = Ground.cast(V(x, fromY, z), V(0, -(depth or 80), 0), params)
		if not hit or hit.Material == Enum.Material.Water then
			return nil
		end
		return hit.Position.Y
	end)
	return if ok then y else nil
end

function SafeSpot.inTerrain(point: Vector3): boolean
	local ok, solid = pcall(function()
		local terrain = workspace:FindFirstChildOfClass("Terrain")
		if not terrain then
			return false
		end
		-- El vóxel (de 4 studs) en el que cae el punto
		local base = V(math.floor(point.X / 4) * 4, math.floor(point.Y / 4) * 4, math.floor(point.Z / 4) * 4)
		local materials, occupancies = terrain:ReadVoxels(Region3.new(base, base + V(4, 4, 4)), 4)
		local m = materials[1][1][1]
		local o = occupancies[1][1][1]
		return o >= 0.5 and m ~= Enum.Material.Air and m ~= Enum.Material.Water
	end)
	return ok and solid == true
end

-- Una pieza de prueba (no está en el mundo): con ella se pregunta qué piezas tocan un hueco
local probe: Part? = nil
local function probePart(): Part
	if not probe then
		local p = Instance.new("Part")
		p.Name = "SafeSpotProbe"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		probe = p
	end
	return probe :: Part
end

-- ¿Hay algo sólido y fijo (anclado) en esa caja? (las piezas que no chocan no cuentan, ni los
-- personajes, ni lo que se mueve suelto: eso te empuja, no te entierra)
local function solidIn(cf: CFrame, size: Vector3, ignore: { Instance }?, minSize: number?): boolean
	local ok, solid = pcall(function()
		local p = probePart()
		p.Size = size
		p.CFrame = cf
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local list = characters()
		for _, i in ignore or {} do
			table.insert(list, i)
		end
		params.FilterDescendantsInstances = list
		params.RespectCanCollide = true
		for _, part in workspace:GetPartsInPart(p, params) do
			if part:IsA("BasePart") and not part:IsA("Terrain") and part.Anchored and part.CanCollide
				and (not minSize or part.Size.Magnitude >= minSize) then
				return true
			end
		end
		return false
	end)
	return ok and solid == true
end

function SafeSpot.free(feet: Vector3): boolean
	if SafeSpot.inTerrain(feet + V(0, 2.5, 0)) or SafeSpot.inTerrain(feet + V(0, 4.5, 0)) then
		return false
	end
	return not solidIn(CFrame.new(feet + V(0, 3, 0)), V(1.6, 3.6, 1))
end

-- ¿Quien se ponga de pie ahí queda ATRAPADO? (el centro del cuerpo dentro del terreno o de algo
-- grande y macizo: el silo, la pared de un edificio). Más suave que free: un pupitre, los barrotes
-- de una cuna o una silla al lado no cuentan (ahí te quieren poner las escenas)
function SafeSpot.stuckAt(feet: Vector3): boolean
	if SafeSpot.inTerrain(feet + V(0, 3, 0)) then
		return true
	end
	return solidIn(CFrame.new(feet + V(0, 3, 0)), V(0.6, 1, 0.6), nil, 10)
end

function SafeSpot.find(center: Vector3, minY: number?): Vector3?
	return SafeGround.findSpot(center, { groundAt = SafeSpot.groundAt, free = SafeSpot.free }, minY)
end

-- ¿Está enterrado? (el centro del cuerpo dentro de terreno macizo o de una pieza fija, o debajo
-- de todo el mapa)
function SafeSpot.buried(character: Model): boolean
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local p = root.Position
	if p.Y < SafeGround.SafeMinY then
		return true
	end
	if SafeSpot.inTerrain(p) and SafeSpot.inTerrain(p + V(0, 1.5, 0)) then
		return true
	end
	return solidIn(root.CFrame, V(0.6, 1, 0.6), { character })
end

-- Altura de la raíz sobre los pies (personajes de cualquier tamaño)
local function rootLift(character: Model): number
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
		return humanoid.HipHeight + root.Size.Y / 2 + 0.2
	end
	return 3
end

function SafeSpot.place(character: Model, feet: Vector3, yaw: number?)
	pcall(function()
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local rotation = if yaw then CFrame.Angles(0, yaw, 0) elseif root then root.CFrame.Rotation else CFrame.identity
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		character:PivotTo(CFrame.new(feet + V(0, rootLift(character), 0)) * rotation)
	end)
end

-- Que pueda volver a andar: nada anclado, de pie, con su velocidad y su salto
function SafeSpot.release(character: Model)
	pcall(function()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		for _, d in character:GetChildren() do
			if d:IsA("BasePart") and d.Anchored then
				d.Anchored = false
			end
		end
		if humanoid then
			local base = character:GetAttribute("BaseWalkSpeed")
			local changes = SafeGround.restoreHumanoid({
				WalkSpeed = humanoid.WalkSpeed,
				JumpPower = humanoid.JumpPower,
				JumpHeight = humanoid.JumpHeight,
				UseJumpPower = humanoid.UseJumpPower,
				PlatformStand = humanoid.PlatformStand,
				Sit = humanoid.Sit and humanoid.SeatPart == nil,
			}, { WalkSpeed = if type(base) == "number" and base >= 1 then base else nil })
			for key, value in changes do
				(humanoid :: any)[key] = value
			end
			if humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding or humanoid:GetState() == Enum.HumanoidStateType.Physics then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end)
end

-- La entrada del juego (SpawnLocation), por si no hay nada mejor
local spawnCache: BasePart? = nil
local function gameSpawn(): Vector3?
	if not spawnCache or not spawnCache.Parent then
		local ok, found = pcall(function()
			return workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		end)
		spawnCache = if ok then found else nil
	end
	return if spawnCache then spawnCache.Position + V(0, spawnCache.Size.Y / 2, 0) else nil
end

-- Le saca de donde está atascado: al sitio libre más cercano (por encima si está enterrado); si no
-- hay, a "home" (su cama, su casa) y si no, a la entrada del juego. Devuelve dónde le ha puesto.
function SafeSpot.rescue(player: Player, home: Vector3?): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root then
		return nil
	end
	local from = root.Position
	local feet = if from.Y > SafeGround.SafeMinY then SafeSpot.find(from) else nil
	if not feet and home then
		feet = SafeSpot.find(home) or home
	end
	if not feet then
		local entrance = gameSpawn()
		feet = if entrance then (SafeSpot.find(entrance) or entrance) else nil
	end
	if not feet then
		return nil
	end
	pcall(function()
		player:RequestStreamAroundAsync(feet, 3)
	end)
	SafeSpot.place(character, feet)
	SafeSpot.release(character)
	return feet
end

return SafeSpot
