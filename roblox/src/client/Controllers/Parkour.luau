-- Parkour (cliente): saltar vallas, muros bajos, bancos y capós, y trepar a bordes, con fluidez.
--
--   * Corriendo o andando hacia un obstáculo, al saltar (Espacio, A en el mando, el botón Saltar del
--     móvil) en lugar del salto normal se hace el que toca (Movement.classify):
--       Speed  valla o barandilla (1,5–4,5 studs, estrecha): una mano encima y las piernas de lado
--       Kong   muro bajo y ancho, con carrerilla: las dos manos delante y las piernas recogidas
--       Climb  muro de 4,5–7 studs (o bajo y ancho sin carrerilla): se agarra, sube y baja por detrás
--       Ledge  un borde con sitio encima (hasta 9,5): se agarra, sube y se queda arriba
--     También en el aire: saltando contra un muro o un borde, se agarra y sube (lo de "trepar muros
--     bajos" de antes). Con obstáculo delante, el botón Saltar del móvil dice "Saltar valla", "Trepar"…
--   * El cuerpo sigue un arco suave (Movement.path + Movement.sample, sin tirones) con la mano en lo
--     alto del obstáculo y las piernas recogidas; si del otro lado hay mucha caída, voltereta.
--   * Seguridad: se mira con rayos a la altura de rodillas, cintura y pecho, y desde arriba lo alto y
--     el sitio donde caer. Nunca contra una pared, a un vacío (> 14 studs), a través de una puerta
--     (carteles "Entrar") ni hacia dentro de una casa. No se hace montado, nadando, agachado, llevando
--     algo en brazos, de bebé; los niños no hacen el kong y los mayores solo trepan poco.
--   * Lo ven todos: el servidor pone el atributo "Vault" ("Tipo|inicio|duración") y cada pantalla dibuja
--     la postura. Mientras dura, tu jugador tiene "BusyMove" = true (las armas se bajan).
-- Es la capa 25 de PoseLayers (después de Locomotion, antes de ReactMotion). Las posturas son
-- funciones puras (Parkour.pose, Parkour.weight): scripts/test-parkour.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Movement = require(ReplicatedStorage.Shared.Movement)
local Joints = require(ReplicatedStorage.Shared.Joints)

local Parkour = {}

local angles = CFrame.Angles

---------------------------------------------------------------------
-- Posturas (fotogramas clave; entre ellos, curva suave). Ángulos {x, y, z} y, en Root, bajar {y=…}
---------------------------------------------------------------------
type Key = { T: number, Pose: { [string]: { number } } }

local function sym(x: number, z: number): ({ number }, { number })
	return { x, 0, z }, { x, 0, -z }
end

local S1R, S1L = sym(1.1, 0.25)
local KONG_PLANT_R, KONG_PLANT_L = sym(2.0, 0.15)
local KONG_OVER_R, KONG_OVER_L = sym(1.3, 0.2)
local KONG_OUT_R, KONG_OUT_L = sym(0.9, 0.4)
local REACH_R, REACH_L = sym(2.8, 0.2)
local PULL_R, PULL_L = sym(1.4, 0.3)
local TOP_R, TOP_L = sym(0.6, 0.3)
local DOWN_R, DOWN_L = sym(0.8, 0.5)

Parkour.Keys = {
	-- Una mano (la izquierda) en la valla y las piernas pasan por la derecha
	Speed = {
		{ T = 0, Pose = {} },
		{ T = 0.22, Pose = {
			Root = { -0.2, 0, 0 }, Neck = { 0.1, 0, 0 },
			LeftShoulder = { 1.1, 0, -0.2 }, LeftElbow = { 0.3, 0, 0 }, RightShoulder = { 0.6, 0, 0.5 },
			RightHip = { 0.6, 0, 0 }, RightKnee = { -0.8, 0, 0 }, LeftHip = { 0.3, 0, 0 }, LeftKnee = { -0.4, 0, 0 },
		} },
		{ T = 0.5, Pose = {
			Root = { -0.1, 0.35, 0.55 }, Waist = { 0, -0.2, -0.2 }, Neck = { 0.1, -0.3, 0 },
			LeftShoulder = { 0.7, 0, -0.1 }, LeftElbow = { 0.05, 0, 0 }, RightShoulder = { 0.4, 0, 1.2 }, RightElbow = { 0.4, 0, 0 },
			RightHip = { 1.3, 0, 0.3 }, LeftHip = { 1.2, 0, 0.2 }, RightKnee = { -1.2, 0, 0 }, LeftKnee = { -1.4, 0, 0 },
		} },
		{ T = 0.8, Pose = {
			Root = { -0.1, 0, 0 }, LeftShoulder = { 0.4, 0, -0.4 }, RightShoulder = { 0.5, 0, 0.5 },
			RightHip = { 0.5, 0, 0 }, RightKnee = { -0.4, 0, 0 }, LeftHip = { -0.2, 0, 0 }, LeftKnee = { -0.6, 0, 0 },
		} },
		{ T = 1, Pose = {} },
	},
	-- Las dos manos delante, el cuerpo por encima con las rodillas al pecho
	Kong = {
		{ T = 0, Pose = {} },
		{ T = 0.25, Pose = {
			Root = { -0.7, 0, 0 }, Waist = { -0.2, 0, 0 }, Neck = { 0.6, 0, 0 },
			RightShoulder = KONG_PLANT_R, LeftShoulder = KONG_PLANT_L, RightElbow = { 0.2, 0, 0 }, LeftElbow = { 0.2, 0, 0 },
			RightHip = { 0.4, 0, 0 }, LeftHip = { 0.4, 0, 0 }, RightKnee = { -0.3, 0, 0 }, LeftKnee = { -0.3, 0, 0 },
		} },
		{ T = 0.5, Pose = {
			Root = { -0.5, 0, 0 }, Neck = { 0.5, 0, 0 },
			RightShoulder = KONG_OVER_R, LeftShoulder = KONG_OVER_L, RightElbow = { 0.1, 0, 0 }, LeftElbow = { 0.1, 0, 0 },
			RightHip = { 1.7, 0, 0 }, LeftHip = { 1.7, 0, 0 }, RightKnee = { -2.0, 0, 0 }, LeftKnee = { -2.0, 0, 0 },
		} },
		{ T = 0.75, Pose = {
			Root = { -0.1, 0, 0 }, Neck = { 0.1, 0, 0 },
			RightShoulder = KONG_OUT_R, LeftShoulder = KONG_OUT_L,
			RightHip = { 0.9, 0, 0 }, LeftHip = { 0.9, 0, 0 }, RightKnee = { -0.4, 0, 0 }, LeftKnee = { -0.4, 0, 0 },
		} },
		{ T = 1, Pose = {} },
	},
	-- Agarrarse arriba, subir una pierna, agacharse encima y bajar por el otro lado
	Climb = {
		{ T = 0, Pose = {} },
		{ T = 0.2, Pose = {
			Root = { -0.1, 0, 0 }, Neck = { 0.3, 0, 0 },
			RightShoulder = REACH_R, LeftShoulder = REACH_L, RightElbow = { 0.3, 0, 0 }, LeftElbow = { 0.3, 0, 0 },
			RightHip = { 0.5, 0, 0 }, RightKnee = { -0.8, 0, 0 }, LeftHip = { 0.1, 0, 0 }, LeftKnee = { -0.3, 0, 0 },
		} },
		{ T = 0.45, Pose = {
			Root = { -0.2, 0, 0 }, Waist = { -0.4, 0, 0 }, Neck = { 0.2, 0, 0 },
			RightShoulder = PULL_R, LeftShoulder = PULL_L, RightElbow = { 1.9, 0, 0 }, LeftElbow = { 1.9, 0, 0 },
			RightHip = { 1.5, 0, 0 }, RightKnee = { -1.8, 0, 0 }, LeftHip = { 0.4, 0, 0 }, LeftKnee = { -0.6, 0, 0 },
		} },
		{ T = 0.65, Pose = {
			Waist = { -0.3, 0, 0 }, Neck = { 0.2, 0, 0 },
			RightShoulder = TOP_R, LeftShoulder = TOP_L, RightElbow = { 0.6, 0, 0 }, LeftElbow = { 0.6, 0, 0 },
			RightHip = { 1.3, 0, 0 }, LeftHip = { 1.3, 0, 0 }, RightKnee = { -1.8, 0, 0 }, LeftKnee = { -1.8, 0, 0 },
		} },
		{ T = 0.85, Pose = {
			Root = { -0.1, 0, 0 }, RightShoulder = DOWN_R, LeftShoulder = DOWN_L,
			RightHip = { 0.6, 0, 0 }, LeftHip = { 0.6, 0, 0 }, RightKnee = { -0.7, 0, 0 }, LeftKnee = { -0.7, 0, 0 },
		} },
		{ T = 1, Pose = {} },
	},
	-- Agarrarse al borde, subir y ponerse de pie arriba
	Ledge = {
		{ T = 0, Pose = {} },
		{ T = 0.25, Pose = {
			Root = { -0.1, 0, 0 }, Neck = { 0.3, 0, 0 },
			RightShoulder = REACH_R, LeftShoulder = REACH_L, RightElbow = { 0.3, 0, 0 }, LeftElbow = { 0.3, 0, 0 },
			RightHip = { 0.3, 0, 0 }, RightKnee = { -0.5, 0, 0 },
		} },
		{ T = 0.55, Pose = {
			Root = { -0.2, 0, 0 }, Waist = { -0.4, 0, 0 }, Neck = { 0.2, 0, 0 },
			RightShoulder = PULL_R, LeftShoulder = PULL_L, RightElbow = { 1.9, 0, 0 }, LeftElbow = { 1.9, 0, 0 },
			RightHip = { 1.5, 0, 0 }, RightKnee = { -1.8, 0, 0 }, LeftHip = { 0.4, 0, 0 }, LeftKnee = { -0.6, 0, 0 },
		} },
		{ T = 0.8, Pose = {
			Waist = { -0.2, 0, 0 }, RightShoulder = S1R, LeftShoulder = S1L,
			RightHip = { 0.9, 0, 0 }, LeftHip = { 0.9, 0, 0 }, RightKnee = { -1.2, 0, 0 }, LeftKnee = { -1.2, 0, 0 },
		} },
		{ T = 1, Pose = {} },
	},
} :: { [string]: { Key } }

local function ease(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function part(pose: { [string]: { number } }, name: string): { number }
	return pose[name] or { 0, 0, 0 }
end

-- Postura de un salto en el momento t (0..1): { articulación = CFrame } (cero al empezar y al acabar)
function Parkour.pose(kind: string, t: number): { [string]: CFrame }
	local keys = Parkour.Keys[kind]
	local out: { [string]: CFrame } = {}
	if not keys then
		return out
	end
	t = math.clamp(t, 0, 1)
	local a, b = keys[1], keys[#keys]
	for i = 1, #keys - 1 do
		if t >= keys[i].T and t <= keys[i + 1].T then
			a, b = keys[i], keys[i + 1]
			break
		end
	end
	local span = math.max(b.T - a.T, 1e-4)
	local u = ease((t - a.T) / span)
	local names = {}
	for name in a.Pose do
		names[name] = true
	end
	for name in b.Pose do
		names[name] = true
	end
	for name in names do
		local p, q = part(a.Pose, name), part(b.Pose, name)
		local x = p[1] + (q[1] - p[1]) * u
		local y = p[2] + (q[2] - p[2]) * u
		local z = p[3] + (q[3] - p[3]) * u
		out[name] = angles(x, y, z)
	end
	return out
end

-- Cuánto manda la postura del salto sobre la animación: entra en 0,08 s y sale en los últimos 0,12 s
function Parkour.weight(t: number, duration: number): number
	if t <= 0 or t >= 1 then
		return 0
	end
	local d = math.max(duration, 0.05)
	return ease(math.min(1, t * d / 0.08, (1 - t) * d / 0.12))
end

-- Texto del botón Saltar con cada obstáculo delante
Parkour.Labels = { Speed = "Saltar valla", Kong = "Saltar muro", Climb = "Trepar", Ledge = "Subir" }

-- "Tipo|inicio|duración" (atributo Vault) -> tipo, inicio, duración
function Parkour.parse(value: any): (string?, number?, number?)
	if type(value) ~= "string" then
		return nil, nil, nil
	end
	local kind, start, duration = string.match(value, "^(%a+)|([%d%.]+)|([%d%.]+)$")
	if not kind or not Parkour.Keys[kind] then
		return nil, nil, nil
	end
	return kind, tonumber(start), tonumber(duration)
end

---------------------------------------------------------------------
-- En Roblox
---------------------------------------------------------------------
local JOINTS = {
	Root = "LowerTorso", Waist = "UpperTorso", Neck = "Head",
	RightShoulder = "RightUpperArm", LeftShoulder = "LeftUpperArm", RightElbow = "RightLowerArm", LeftElbow = "LeftLowerArm",
	RightHip = "RightUpperLeg", LeftHip = "LeftUpperLeg", RightKnee = "RightLowerLeg", LeftKnee = "LeftLowerLeg",
}
local CLIMB_ANIM = { R15 = 507765644, R6 = 180436334 } -- (R6: sin posturas propias, la de trepar de Roblox)

type Playing = { Kind: string, Start: number, Duration: number, Joints: { [string]: any } } -- Motor6D o AnimationConstraint
local playing: { [Model]: Playing } = {}
local Layers: any, ReactMotion: any, Stances: any, Cinematics: any
local player: Player
local vaulting = false
local lastEnd = 0 -- cuándo acabó el último salto (para no engancharse otra vez al caer)

-- ¿Está saltando ese personaje (o el tuyo, sin argumento)?
function Parkour.isVaulting(model: Model?): boolean
	if model == nil then
		return vaulting
	end
	return playing[model] ~= nil
end

local function jointsOf(model: Model): { [string]: any }
	-- (Motor6D o AnimationConstraint, las articulaciones nuevas de Roblox: las dos tienen Transform)
	return Joints.collect(model, JOINTS)
end

local function startPose(model: Model, kind: string, start: number, duration: number)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	playing[model] = { Kind = kind, Start = start, Duration = duration, Joints = jointsOf(model) }
end

---------------------------------------------------------------------
-- Mirar qué hay delante
---------------------------------------------------------------------
export type Candidate = {
	Kind: string,
	Dir: Vector3,
	Edge: Vector3,
	Far: Vector3,
	Land: Vector3,
	Drop: number,
	Height: number,
	Speed: number,
	RootHeight: number,
}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = false
params.RespectCanCollide = true

local doorCache: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
-- ¿Es (o está en) una puerta o la fachada de algo con cartel "Entrar"?
local function doorLike(instance: Instance): boolean
	local cached = doorCache[instance]
	if cached ~= nil then
		return cached
	end
	local result = false
	local node: Instance? = instance
	for _ = 1, 3 do
		if not node or node == workspace then
			break
		end
		local name = string.lower(node.Name)
		if string.find(name, "door", 1, true) or string.find(name, "puerta", 1, true) or string.find(name, "gate", 1, true) then
			result = true
			break
		end
		for _, child in node:GetChildren() do
			if child:IsA("ProximityPrompt") then
				local text = string.lower(child.ActionText)
				if string.find(text, "entrar", 1, true) or string.find(text, "abrir", 1, true) then
					result = true
				end
			end
		end
		if result then
			break
		end
		node = node.Parent
	end
	doorCache[instance] = result
	return result
end

-- ¿Ese punto está dentro de una habitación de una casa (piezas con la etiqueta Room)?
local function insideRoom(position: Vector3): boolean
	local CollectionService = game:GetService("CollectionService")
	for _, room in CollectionService:GetTagged("Room") do
		if room:IsA("BasePart") then
			local p = room.CFrame:PointToObjectSpace(position)
			local h = room.Size / 2
			if math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y + 2 and math.abs(p.Z) <= h.Z then
				return true
			end
		end
	end
	return false
end

local HEAVY = { CarriedItem = true, CarriedPlate = true, CafeTray = true, PostParcel = true }

local function canParkour(humanoid: Humanoid, character: Model): boolean
	if vaulting or humanoid.Health <= 0 or humanoid.SeatPart or humanoid.Sit or humanoid.PlatformStand then
		return false
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Swimming or state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Dead then
		return false
	end
	if player:GetAttribute("LifeStage") == "Bebe" or player:GetAttribute("Crawling") or player:GetAttribute("KO")
		or player:GetAttribute("Riding") ~= nil or player:GetAttribute("Passenger") ~= nil or player:GetAttribute("InDialogue") then
		return false
	end
	if Stances and Stances.current() ~= "Stand" then
		return false
	end
	if Cinematics and Cinematics.isPlaying() then
		return false
	end
	for name in HEAVY do
		if character:FindFirstChild(name) then
			return false -- con las manos ocupadas no
		end
	end
	return true
end

-- Obstáculo delante (air = ya en el aire: solo agarrarse y subir)
local function evaluate(air: boolean): Candidate?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not humanoid or not root or not canParkour(humanoid, character) then
		return nil
	end
	local v = root.AssemblyLinearVelocity
	local flat = Vector3.new(v.X, 0, v.Z)
	local speed = flat.Magnitude
	local dir: Vector3
	local wish = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
	if wish.Magnitude > 0.3 then
		dir = wish.Unit
	elseif speed > 4 then
		dir = flat.Unit
	else
		return nil -- quieto: salto normal
	end
	local scale = math.max(character:GetScale(), 0.3)
	local H = humanoid.HipHeight + root.Size.Y / 2
	local feet = root.Position.Y - H
	params.FilterDescendantsInstances = { character, workspace.CurrentCamera :: Instance }
	local reach = (2.2 + math.min(speed, 24) * 0.1) * scale

	-- 1) Una cara delante, a la altura de las rodillas, la cintura o el pecho
	local wall: RaycastResult? = nil
	for _, h in { 1.0, 2.2, 3.6 } do
		local origin = Vector3.new(root.Position.X, feet + h * scale, root.Position.Z)
		local hit = workspace:Raycast(origin, dir * reach, params)
		if hit and math.abs(hit.Normal.Y) < 0.35 and (-hit.Normal):Dot(dir) > 0.55 then
			if not wall or (hit.Position - origin).Magnitude < (wall.Position - origin).Magnitude then
				wall = hit
			end
		end
	end
	if not wall then
		return nil
	end
	local instance = wall.Instance
	local model = instance:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return nil -- personas no
	end
	if instance.AssemblyLinearVelocity.Magnitude > 3 or doorLike(instance) then
		return nil -- nada que se mueva (coches en marcha) ni puertas
	end

	-- 2) Lo alto: desde arriba, justo pasada la cara
	local probe = wall.Position + dir * 0.3 * scale
	local up = feet + 10 * scale
	local above = Vector3.new(root.Position.X, up, root.Position.Z)
	if workspace:Raycast(above, Vector3.new(probe.X, up, probe.Z) - above, params) then
		return nil -- techo o muro altísimo
	end
	local top = workspace:Raycast(Vector3.new(probe.X, up, probe.Z), Vector3.new(0, feet - up + 0.3, 0), params)
	if not top or top.Normal.Y < 0.7 or top.Material == Enum.Material.Water then
		return nil
	end
	local topY = top.Position.Y
	local height = topY - feet
	-- Sitio encima para pasar el cuerpo
	if workspace:Raycast(top.Position + Vector3.new(0, 0.1, 0), Vector3.new(0, 3 * scale, 0), params) then
		return nil
	end

	-- 3) Grueso: se avanza por encima hasta que el suelo baja (o algo más alto lo corta)
	local depth = math.huge
	for step = 1, 12 do
		local d = step * 0.5 * scale
		local at = top.Position + dir * d
		if workspace:Raycast(top.Position + Vector3.new(0, 0.5 * scale, 0), dir * d, params) then
			depth = math.huge -- algo más alto encima: es un borde (se sube y ahí se queda)
			break
		end
		local hit = workspace:Raycast(at + Vector3.new(0, 1, 0), Vector3.new(0, -2, 0), params)
		if not hit or hit.Position.Y < topY - 0.8 then
			depth = d - 0.25 * scale
			break
		end
	end
	local far = top.Position + dir * (if depth < math.huge then depth else 0)

	-- 4) Dónde caer del otro lado
	local drop: number? = nil
	local clear = false
	local land: Vector3? = nil
	if depth < 5 * scale then
		local at = far + dir * (1.4 + speed * 0.06) * scale
		local down = workspace:Raycast(Vector3.new(at.X, topY + 1, at.Z), Vector3.new(0, -(Movement.MaxDrop * scale + height + 4), 0), params)
		if down and down.Normal.Y > 0.6 and down.Material ~= Enum.Material.Water then
			drop = feet - down.Position.Y
			land = Vector3.new(at.X, down.Position.Y + H, at.Z)
			local apex = Vector3.new(far.X, topY + H * 0.7, far.Z)
			clear = workspace:Raycast(top.Position + Vector3.new(0, H * 0.7, 0), apex - (top.Position + Vector3.new(0, H * 0.7, 0)), params) == nil
				and workspace:Raycast(apex, (land :: Vector3) - apex, params) == nil
				and workspace:Raycast(down.Position + Vector3.new(0, 0.2, 0), Vector3.new(0, 2 * H, 0), params) == nil
				and not insideRoom(land :: Vector3)
		end
	end
	local kind = Movement.classify({
		Height = height,
		Depth = depth,
		Drop = drop,
		Clear = clear,
		Speed = speed,
		Scale = scale,
		Stage = player:GetAttribute("LifeStage"),
	})
	if not kind then
		return nil
	end
	if air and (kind == "Speed" or kind == "Kong") then
		return nil -- en el aire, las vallas se pasan saltando
	end
	if kind == "Ledge" then
		-- Arriba, de pie un poco pasado el borde (y que quepa)
		local stand = top.Position + dir * math.min(1.2 * scale, if depth < math.huge then depth * 0.5 else 1.2 * scale)
		local floor = workspace:Raycast(stand + Vector3.new(0, 1, 0), Vector3.new(0, -2, 0), params)
		if not floor or workspace:Raycast(stand + Vector3.new(0, 0.2, 0), Vector3.new(0, 2 * H, 0), params) or insideRoom(stand) then
			return nil
		end
		land = Vector3.new(stand.X, floor.Position.Y + H, stand.Z)
		drop = feet - floor.Position.Y
	end
	if not land then
		return nil
	end
	return {
		Kind = kind,
		Dir = dir,
		Edge = top.Position,
		Far = far,
		Land = land,
		Drop = drop or 0,
		Height = height,
		Speed = speed,
		RootHeight = H,
	}
end
Parkour.evaluate = evaluate

---------------------------------------------------------------------
-- Hacer el salto
---------------------------------------------------------------------
local remote: RemoteEvent? = nil

local function perform(c: Candidate)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not humanoid or not root then
		return
	end
	local RunService = game:GetService("RunService")
	vaulting = true
	player:SetAttribute("BusyMove", true)
	Stances.blockJump("Parkour", false)
	local scale = math.max(character:GetScale(), 0.3)
	local duration = Movement.duration(c.Kind, c.Height, scale)
	local points = Movement.path(c.Kind, root.Position, c.Edge, c.Far, c.Land, c.RootHeight)
	local facing = CFrame.lookAlong(Vector3.zero, c.Dir).Rotation
	local serverStart = workspace:GetServerTimeNow()
	if remote then
		remote:FireServer("Vault", { Kind = c.Kind, Duration = duration, Start = serverStart })
	end
	local start = os.clock()
	startPose(character, c.Kind, start, duration)
	-- R6: la animación de trepar de Roblox (no hay posturas propias)
	local track: AnimationTrack? = nil
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. CLIMB_ANIM.R6
			local ok, loaded = pcall(function()
				return animator:LoadAnimation(animation)
			end)
			if ok and loaded then
				track = loaded
				loaded.Priority = Enum.AnimationPriority.Action
				loaded:Play(0.15, 1, 1.4)
			end
		end
	end
	pcall(function()
		require(script.Parent.SoundFx).play("Trepar", 1, nil, root)
	end)
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Physics) -- el camino lo pone el salto (sin pelear con la física)
	local connection: RBXScriptConnection
	local function finish(ok: boolean)
		connection:Disconnect()
		vaulting = false
		lastEnd = os.clock()
		playing[character] = nil
		humanoid.AutoRotate = true
		if track then
			track:Stop(0.25)
		end
		task.delay(0.1, function()
			if not vaulting then
				player:SetAttribute("BusyMove", nil)
			end
		end)
		if not ok or humanoid.Health <= 0 then
			return
		end
		-- Sigue la carrera (salto de valla y kong) o se queda donde ha subido
		local keep = if c.Kind == "Speed" or c.Kind == "Kong" then c.Dir * math.max(c.Speed * 0.9, humanoid.WalkSpeed * 0.8) else Vector3.zero
		root.AssemblyLinearVelocity = keep
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		if c.Drop / scale > Movement.RollDrop then
			ReactMotion.play(character, "Roll")
		else
			ReactMotion.play(character, "Land", { Strength = if c.Kind == "Kong" or c.Kind == "Speed" then 0.3 else 0.45 })
		end
	end
	connection = RunService.Heartbeat:Connect(function()
		if not character.Parent or humanoid.Health <= 0 then
			finish(false)
			return
		end
		local t = math.clamp((os.clock() - start) / duration, 0, 1)
		local position = Movement.sample(points, Movement.timeCurve(t))
		root.CFrame = CFrame.new(position) * facing
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		if t >= 1 then
			finish(true)
		end
	end)
end

---------------------------------------------------------------------

function Parkour.init()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	player = Players.LocalPlayer
	Layers = require(script.Parent.PoseLayers)
	ReactMotion = require(script.Parent.ReactMotion)
	Stances = require(script.Parent.Stances)
	Cinematics = require(script.Parent.Cinematics)
	local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Actions") :: RemoteEvent

	-- Los saltos de los demás (el servidor pone "Vault" en su jugador)
	local function watch(other: Player)
		if other == player then
			return
		end
		other:GetAttributeChangedSignal("Vault"):Connect(function()
			local kind, start, duration = Parkour.parse(other:GetAttribute("Vault"))
			local character = other.Character
			if kind and start and duration and character then
				-- (su posición llega un pelín tarde: la postura también)
				local elapsed = workspace:GetServerTimeNow() - start - 0.08
				if elapsed < duration then
					startPose(character, kind, os.clock() - math.max(elapsed, 0), duration)
				end
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, other in Players:GetPlayers() do
		watch(other)
	end

	-- Lo que hay delante: 10 veces por segundo (y el botón Saltar dice qué hará)
	local candidate: Candidate? = nil
	local shownLabel: string? = nil
	local wantJump = false
	UserInputService.JumpRequest:Connect(function()
		wantJump = true
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local grounded = humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
			local ok, result = pcall(evaluate, false)
			candidate = if ok and grounded then result else nil
			if not ok then
				warn("[Parkour] " .. tostring(result))
			end
			Stances.blockJump("Parkour", candidate ~= nil)
			local label = if candidate then Parkour.Labels[candidate.Kind] else nil
			if label ~= shownLabel then
				shownLabel = label
				TouchLayout.setLabel("Saltar", label)
			end
		end
	end)

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or vaulting then
			wantJump = false
			return
		end
		local jumping = wantJump or humanoid.Jump
		wantJump = false
		if candidate and jumping then
			-- Con un obstáculo delante, saltar = el salto de parkour (se vuelve a mirar ahora)
			humanoid.Jump = false
			local fresh = evaluate(false)
			candidate = nil
			if fresh then
				perform(fresh)
			else
				Stances.blockJump("Parkour", false)
				if Stances.current() == "Stand" then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
			return
		end
		-- En el aire contra un muro o un borde: agarrarse y subir
		local state = humanoid:GetState()
		if (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall) then
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and root.AssemblyLinearVelocity.Y > -12 and os.clock() - lastEnd > 0.5 then
				local ok, grab = pcall(evaluate, true)
				if ok and grab then
					perform(grab)
				end
			end
		end
	end)

	player.CharacterAdded:Connect(function()
		vaulting = false
		candidate = nil
		player:SetAttribute("BusyMove", nil)
	end)

	-- Las posturas (tu personaje y los demás)
	Layers.add("Parkour", 25, function()
		local now = os.clock()
		for model, entry in playing do
			local t = (now - entry.Start) / entry.Duration
			if not model.Parent or t >= 1 then
				if model ~= player.Character or not vaulting then
					playing[model] = nil
				end
				continue
			end
			if t < 0 then
				continue
			end
			local w = Parkour.weight(t, entry.Duration)
			local pose = Parkour.pose(entry.Kind, t)
			for name, joint in entry.Joints do
				local target = pose[name] or CFrame.identity
				Layers.write(joint, Layers.read(joint):Lerp(target, w))
			end
		end
	end)
end

return Parkour
