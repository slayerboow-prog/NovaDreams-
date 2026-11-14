-- PlanetPerilClient (cliente): el empujón de los peligros del terreno de los planetas
-- (Services/PlanetPerilService, remoto «PlanetPeril»): la ráfaga de la tormenta de arena o de la
-- ventisca te arrastra de lado un momento, y el rayo o lo que cae te lanza un poco. Tu personaje lo
-- mueve tu cliente, por eso el empujón se aplica aquí. La cámara tiembla un poco.

local Players = game:GetService("Players")

local CameraShake = require(script.Parent.CameraShake)

local PlanetPerilClient = {}

local player = Players.LocalPlayer
local token = 0

local function push(velocity: Vector3)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or humanoid.Sit then
		return
	end
	token += 1
	local mine = token
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	if velocity.Y > 1 then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
	-- (un empujón corto con LinearVelocity en el plano: el Humanoid no lo frena de golpe)
	local attachment = root:FindFirstChild("PerilAttachment") :: Attachment?
	if not attachment then
		local created = Instance.new("Attachment")
		created.Name = "PerilAttachment"
		created.Parent = root
		attachment = created
	end
	local lv = Instance.new("LinearVelocity")
	lv.Name = "PerilEmpujon"
	lv.Attachment0 = attachment
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	lv.PlaneVelocity = Vector2.new(flat.X, flat.Z)
	lv.MaxForce = 60000
	lv.Parent = root
	if velocity.Y > 1 then
		root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, velocity.Y, root.AssemblyLinearVelocity.Z)
	end
	task.delay(0.35, function()
		if lv.Parent then
			lv:Destroy()
		end
		if mine ~= token then
			return
		end
	end)
end

function PlanetPerilClient.received(data: { [string]: any })
	if type(data) ~= "table" then
		return
	end
	if typeof(data.Push) == "Vector3" then
		push(data.Push)
	end
	local shake = tonumber(data.Shake)
	if shake and shake > 0 then
		pcall(CameraShake.shake, shake, 0.35)
	end
end

function PlanetPerilClient.init()
	local remote = require(script.Parent.Parent.UI.ServerWait).remote("PlanetPeril") :: RemoteEvent?
	if remote then
		remote.OnClientEvent:Connect(PlanetPerilClient.received)
	end
end

return PlanetPerilClient
