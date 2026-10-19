-- SafeSpot (servidor): mira el mundo de verdad para que nadie acabe bajo tierra, dentro de una pared
-- o de un modelo (el silo, un edificio…). Las cuentas están en Shared/SafeGround (con pruebas).
--
--   SafeSpot.groundAt(x, z, fromY)  Suelo de verdad bajo (x, z) desde fromY (sin agua)
--   SafeSpot.inTerrain(point)       ¿Ese punto está dentro de terreno macizo?
--   SafeSpot.free(feet)             ¿Cabe alguien de pie con los pies ahí? (nada sólido en el cuerpo)
--   SafeSpot.stuckAt(feet)          ¿De pie ahí quedaría atrapado? (dentro del terreno o de algo grande)
--   SafeSpot.find(center)           Pies en el sitio libre más cercano con suelo debajo (o nil)
--   SafeSpot.decorAt(feet, scale?)  ¿Hay decoración que SE VE (sin CanQuery: banco, seto, mueble) en el
--                                   cuerpo de quien se ponga ahí? (las consultas del motor no la ven)
--   SafeSpot.freeForActor(feet)     free y sin decoración en el cuerpo: dónde poner a un actor de escena
--   SafeSpot.findForActor(center)   find con freeForActor
--   SafeSpot.buried(character)      ¿Está enterrado o metido dentro de algo sólido?
--   SafeSpot.place(character, feet) Le pone de pie ahí (sin velocidad)
--   SafeSpot.release(character)     Le devuelve el poder andar (velocidad, salto, sin anclar…)
--   SafeSpot.rescue(player, home?)  Le saca al sitio libre más cercano (o a su casa / la entrada)
--
-- Todo va con pcall: si algo de Roblox falla, se da por bueno (nunca se teletransporta por un error).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraShots = require(ReplicatedStorage.Shared.CameraShots)
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

---------------------------------------------------------------------
-- Decoración que se ve pero no sale en las consultas (CanQuery = false: respaldos de bancos, setos,
-- macetas, patas y respaldos de muebles, toldos…). GetPartsInPart no la ve, así que los actores de las
-- escenas acababan metidos en un banco o en un sofá (auditoría de cinemáticas, «DentroDeAlgo»). Índice
-- ligero (rejilla de 32 studs con referencias), hecho una vez en segundo plano; la misma regla que la
-- cámara de las escenas (CameraShots.occluder).
---------------------------------------------------------------------
local DECOR_CELL = 32
local decorGrid: { [number]: { BasePart } } = {}
local decorBig: { BasePart } = {}
local decorState = "none" -- none | building | ready
local function decorKey(x: number, z: number): number
	return (x + 4096) * 8192 + (z + 4096)
end
local function decorAdd(d: Instance)
	if not d:IsA("BasePart") or d:IsA("Terrain") then
		return
	end
	local p = d :: BasePart
	if not CameraShots.occluder(p.Transparency, p.Size, p.CanQuery, p:GetAttribute("Collider") == true, CameraShots.ACTOR_DECOR) then
		return
	end
	local model = p:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return
	end
	if math.max(p.Size.X, p.Size.Z) > 64 then
		table.insert(decorBig, p)
		return
	end
	local k = decorKey(math.floor(p.Position.X / DECOR_CELL), math.floor(p.Position.Z / DECOR_CELL))
	local list = decorGrid[k]
	if not list then
		list = {}
		decorGrid[k] = list
	end
	table.insert(list, p)
end
function SafeSpot.indexDecor()
	if decorState ~= "none" then
		return
	end
	decorState = "building"
	task.spawn(function()
		local ok = pcall(function()
			local town = workspace:FindFirstChild("Town")
			for i, d in (if town then town else workspace):GetDescendants() do
				decorAdd(d)
				if i % 5000 == 0 then
					task.wait()
				end
			end
			workspace.DescendantAdded:Connect(function(d)
				if d:IsA("BasePart") then
					task.defer(decorAdd, d)
				end
			end)
		end)
		decorState = if ok then "ready" else "none"
	end)
end

local BODY = { 0.6, 1.5, 2.5, 3.5, 4.5, 5.1 } -- (alturas del cuerpo a escala 1, como la auditoría)
local function decorHit(p: BasePart, points: { Vector3 }): boolean
	if not p.Parent then
		return false
	end
	local cf, half = p.CFrame, p.Size / 2
	for _, point in points do
		local l = cf:PointToObjectSpace(point)
		if math.abs(l.X) < half.X - 0.1 and math.abs(l.Y) < half.Y - 0.1 and math.abs(l.Z) < half.Z - 0.1 then
			return true
		end
	end
	return false
end

function SafeSpot.decorAt(feet: Vector3, scale: number?): boolean
	if decorState == "none" then
		SafeSpot.indexDecor()
	end
	local ok, hit = pcall(function()
		local k = scale or 1
		local points = table.create(#BODY)
		for i, h in BODY do
			points[i] = feet + V(0, h * k, 0)
		end
		local cx, cz = math.floor(feet.X / DECOR_CELL), math.floor(feet.Z / DECOR_CELL)
		for x = cx - 1, cx + 1 do
			for z = cz - 1, cz + 1 do
				for _, p in decorGrid[decorKey(x, z)] or {} do
					if decorHit(p, points) then
						return true
					end
				end
			end
		end
		for _, p in decorBig do
			if decorHit(p, points) then
				return true
			end
		end
		return false
	end)
	return ok and hit == true
end

function SafeSpot.freeForActor(feet: Vector3): boolean
	return SafeSpot.free(feet) and not SafeSpot.decorAt(feet)
end

function SafeSpot.findForActor(center: Vector3, minY: number?): Vector3?
	return SafeGround.findSpot(center, { groundAt = SafeSpot.groundAt, free = SafeSpot.freeForActor }, minY)
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
