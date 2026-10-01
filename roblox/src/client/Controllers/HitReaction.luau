-- HitReaction (cliente): lo que le pasa a TU personaje en la pelea (lo mueve tu dispositivo).
--
--   * Empujón: el golpe te empuja (un LinearVelocity corto en el suelo, como la voltereta) y, si te
--     derriba, sales volando sin control (PlatformStand), caes y te levantas al acabar.
--   * Lanzador: subes por los aires y, al llegar arriba, flotas un momento (una fuerza que quita casi
--     toda la gravedad) para que el combo siga en el aire. Al que lanza le pasa lo mismo: sube detrás.
--   * Contra la pared: si vuelas hacia una pared, te estampas (rebote, polvo, temblor) y se avisa al
--     servidor para que los demás lo vean.
--   * Impulso aéreo (poder de la Grieta): en el aire, otro salto con impulso (2 por salto).
-- Todo espera a que acabe la congelación del impacto (hitstop) y se quita solo.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Combat = require(game:GetService("ReplicatedStorage").Shared.Combat)
local CombatFx = require(script.Parent.CombatFx)
local CameraShake = require(script.Parent.CameraShake)

local HitReaction = {}

local player = Players.LocalPlayer
local floatUntil = 0
local floatForce: VectorForce? = nil
local floatConnection: RBXScriptConnection? = nil
local push: LinearVelocity? = nil
local pushConnection: RBXScriptConnection? = nil
local downToken = 0
local dashesLeft = Combat.AirDashes
local onWall: ((Vector3) -> ())? = nil

local function parts(): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function attachmentOf(root: BasePart): Attachment
	local a = root:FindFirstChild("RootAttachment") :: Attachment?
	if a then
		return a
	end
	local made = root:FindFirstChild("PeleaAttachment") :: Attachment?
	if not made then
		made = Instance.new("Attachment")
		made.Name = "PeleaAttachment"
		made.Parent = root
	end
	return made :: Attachment
end

-- Quien quiera enterarse de que te has estampado contra una pared (CombatController avisa al servidor)
function HitReaction.onWall(fn: (Vector3) -> ())
	onWall = fn
end

---------------------------------------------------------------------
-- Flotar en el aire (combo aéreo)
---------------------------------------------------------------------
local function stopFloat()
	if floatConnection then
		floatConnection:Disconnect()
		floatConnection = nil
	end
	if floatForce then
		floatForce:Destroy()
		floatForce = nil
	end
end

-- Flota `seconds` (empieza de verdad al dejar de subir rápido). Si ya flotaba, se alarga.
function HitReaction.float(seconds: number)
	local humanoid, root = parts()
	if not humanoid or not root then
		return
	end
	floatUntil = math.max(floatUntil, os.clock() + seconds)
	if floatConnection then
		return
	end
	local force = Instance.new("VectorForce")
	force.Name = "Flotar"
	force.Attachment0 = attachmentOf(root)
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	force.Force = Vector3.zero
	force.Parent = root
	floatForce = force
	floatConnection = RunService.Heartbeat:Connect(function(dt)
		if not root.Parent or os.clock() >= floatUntil or humanoid.Health <= 0 then
			stopFloat()
			return
		end
		local v = root.AssemblyLinearVelocity
		if humanoid.FloorMaterial ~= Enum.Material.Air and v.Y <= 0 then
			stopFloat()
			return
		end
		-- Subiendo rápido: gravedad normal; arriba: casi sin gravedad y frenando en horizontal
		if v.Y < 10 then
			force.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity * 0.8, 0)
			local k = 1 - math.min(1, 4 * dt)
			root.AssemblyLinearVelocity = Vector3.new(v.X * k, math.max(v.Y, -12), v.Z * k)
		else
			force.Force = Vector3.zero
		end
	end)
end

function HitReaction.isFloating(): boolean
	return floatConnection ~= nil
end

---------------------------------------------------------------------
-- Empujón en el suelo y vuelo
---------------------------------------------------------------------
local function stopPush()
	if pushConnection then
		pushConnection:Disconnect()
		pushConnection = nil
	end
	if push then
		push:Destroy()
		push = nil
	end
end

-- Empuja en horizontal (decrece hasta parar en `seconds`)
local function pushFlat(root: BasePart, velocity: Vector3, seconds: number)
	stopPush()
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	if flat.Magnitude < 1 then
		return
	end
	local lv = Instance.new("LinearVelocity")
	lv.Name = "Empujon"
	lv.Attachment0 = attachmentOf(root)
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	lv.PlaneVelocity = Vector2.new(flat.X, flat.Z)
	lv.MaxForce = 60000
	lv.Parent = root
	push = lv
	local started = os.clock()
	pushConnection = RunService.Heartbeat:Connect(function()
		local k = (os.clock() - started) / seconds
		if k >= 1 or not root.Parent then
			stopPush()
			return
		end
		local left = 1 - k * k
		lv.PlaneVelocity = Vector2.new(flat.X, flat.Z) * left
	end)
end

-- Mira si vas a estamparte contra una pared mientras vuelas (hasta `seconds`)
local function watchWall(root: BasePart, seconds: number)
	local character = player.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character :: Instance }
	local started = os.clock()
	local connection: RBXScriptConnection? = nil
	connection = RunService.Heartbeat:Connect(function(dt)
		if os.clock() - started > seconds or not root.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end
		local v = root.AssemblyLinearVelocity
		local flat = Vector3.new(v.X, 0, v.Z)
		if push then
			flat = Vector3.new(push.PlaneVelocity.X, 0, push.PlaneVelocity.Y)
		end
		if flat.Magnitude < 18 then
			return
		end
		local ok, hit = pcall(function()
			return workspace:Raycast(root.Position, flat.Unit * (flat.Magnitude * dt + 2), params)
		end)
		if ok and hit and math.abs(hit.Normal.Y) < 0.5 and hit.Instance.CanCollide then
			if connection then
				connection:Disconnect()
			end
			stopPush()
			root.AssemblyLinearVelocity = hit.Normal * 10 + Vector3.new(0, 6, 0)
			CombatFx.wall(hit.Position)
			CameraShake.shake(1.3, 0.35)
			if onWall then
				pcall(onWall, hit.Position)
			end
		end
	end)
end

-- Derribado: sin control `seconds` y te levantas (si no estás K.O.: eso lo lleva CombatController)
local function knockDown(humanoid: Humanoid, seconds: number)
	downToken += 1
	local token = downToken
	humanoid.PlatformStand = true
	task.delay(seconds, function()
		if token ~= downToken or not humanoid.Parent then
			return
		end
		if player:GetAttribute("KO") then
			return
		end
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)
end

-- Te ha dado un golpe (datos del "Hit" del servidor)
function HitReaction.received(data: { [string]: any })
	local humanoid, root = parts()
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end
	local knockback = tonumber(data.Knockback) or 0
	local lift = tonumber(data.Lift) or 0
	local dir = if typeof(data.Direction) == "Vector3" then data.Direction else Vector3.zero
	local function go()
		if not root.Parent then
			return
		end
		if data.Down then
			stopFloat()
			knockDown(humanoid, data.Down)
			root.AssemblyLinearVelocity = dir * knockback + Vector3.new(0, lift, 0)
		elseif data.Air then
			stopPush()
			root.AssemblyLinearVelocity = Vector3.new(dir.X * knockback, math.max(lift, root.AssemblyLinearVelocity.Y), dir.Z * knockback)
			HitReaction.float(data.Air)
		elseif knockback > 0 then
			pushFlat(root, dir * knockback, if knockback > 20 then 0.35 else 0.15)
			if lift ~= 0 then
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(v.X, lift, v.Z)
			end
		end
		if data.Wall and knockback > 18 then
			watchWall(root, 0.9)
		end
	end
	local stop = tonumber(data.Hitstop) or 0
	if stop > 0 then
		task.delay(stop, go)
	else
		go()
	end
end

-- Has lanzado a alguien (o le sigues pegando en el aire): subes detrás y flotas
function HitReaction.follow(data: { [string]: any })
	local humanoid, root = parts()
	if not humanoid or not root then
		return
	end
	local air = tonumber(data.Air) or 0
	if air <= 0 then
		return
	end
	local function go()
		if data.Launch then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X * 0.3, (tonumber(data.Lift) or 50) * 0.95, v.Z * 0.3)
		end
		HitReaction.float(air)
	end
	local stop = tonumber(data.Hitstop) or 0
	if stop > 0 then
		task.delay(stop, go)
	else
		go()
	end
end

---------------------------------------------------------------------
-- Impulso aéreo
---------------------------------------------------------------------

-- ¿Está en el aire?
function HitReaction.airborne(): boolean
	local humanoid = parts()
	return humanoid ~= nil and humanoid.FloorMaterial == Enum.Material.Air
end

-- Otro salto en el aire hacia `dir` (horizontal). Devuelve si lo ha dado.
function HitReaction.airDash(dir: Vector3): boolean
	local humanoid, root = parts()
	if not humanoid or not root or humanoid.FloorMaterial ~= Enum.Material.Air or dashesLeft <= 0 or humanoid.PlatformStand then
		return false
	end
	dashesLeft -= 1
	local flat = Vector3.new(dir.X, 0, dir.Z)
	flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.zero
	root.AssemblyLinearVelocity = Vector3.new(flat.X * 38, 46, flat.Z * 38)
	CombatFx.dash(player.Character, if flat.Magnitude > 0 then flat else Vector3.new(0, 1, 0))
	return true
end

function HitReaction.reset()
	stopFloat()
	stopPush()
	downToken += 1
	floatUntil = 0
	dashesLeft = Combat.AirDashes
end

function HitReaction.init()
	local function watch(character: Model)
		HitReaction.reset()
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.StateChanged:Connect(function(_, new)
				if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
					dashesLeft = Combat.AirDashes
				end
			end)
		end
	end
	if player.Character then
		task.spawn(watch, player.Character)
	end
	player.CharacterAdded:Connect(watch)
end

return HitReaction
