-- UseMotion (cliente): la postura de cada jugador mientras usa un mueble (sentado, tumbado, en el
-- grifo, tecleando, tocando el piano…). Lo que hace lo dice su atributo UsePose (InteractService);
-- las posturas son las de UseAnim.
--
-- Es una capa de PoseLayers (la 25: después de Locomotion, antes de ReactMotion), así no se
-- acumula con las demás. Cada postura entra y sale mezclándose poco a poco (UseAnim.BlendIn /
-- BlendOut con curva suave): al sentarse, tumbarse o levantarse no hay tirones. Si cambia de
-- postura (del sillón al ordenador), la vieja se va mientras entra la nueva.
-- Se ve en todos los jugadores cercanos (y en los personajes con el atributo UsePose).

local Players = game:GetService("Players")

local UseAnim = require(script.Parent.UseAnim)

local UseMotion = {}

local ACTIVE_DISTANCE = 90
local JOINTS = {
	"Root", "Waist", "Neck", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow", "RightWrist",
	"LeftWrist", "RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle",
}

type Layer = { Name: string, Start: number, Weight: number }
type Body = {
	Model: Model,
	Player: Player?,
	Joints: { [string]: any },
	Layers: { Layer },
	Seed: number,
}

local bodies: { [Model]: Body } = {}
local active: { Body } = {}

local function poseName(body: Body): string?
	local value = if body.Player then body.Player:GetAttribute("UsePose") else body.Model:GetAttribute("UsePose")
	return if UseAnim.get(value) then value else nil
end

local function sleeping(body: Body): boolean
	return body.Player ~= nil and body.Player:GetAttribute("Sleeping") == true
end

local function bodyOf(model: Model): Body?
	local body = bodies[model]
	if body then
		return body
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return nil
	end
	body = {
		Model = model,
		Player = Players:GetPlayerFromCharacter(model),
		Joints = {},
		Layers = {},
		Seed = math.random() * 10,
	}
	for _, name in JOINTS do
		local joint = model:FindFirstChild(name, true)
		if joint and (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then
			body.Joints[name] = joint
		end
	end
	bodies[model] = body
	model.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			bodies[model] = nil
		end
	end)
	return body
end

-- Un frame de un cuerpo: pesos de sus posturas y articulaciones
function UseMotion.stepBody(body: Body, dt: number, now: number, read: (any) -> CFrame, write: (any, CFrame) -> ())
	local current = poseName(body)
	local found = false
	for _, layer in body.Layers do
		if layer.Name == current then
			found = true
		end
	end
	if current and not found then
		table.insert(body.Layers, { Name = current, Start = now, Weight = 0 })
	end
	for i = #body.Layers, 1, -1 do
		local layer = body.Layers[i]
		layer.Weight = UseAnim.fade(layer.Weight, layer.Name == current, dt)
		if layer.Weight <= 0 and layer.Name ~= current then
			table.remove(body.Layers, i)
		end
	end
	if #body.Layers == 0 then
		return
	end
	local asleep = sleeping(body)
	local poses = {}
	for i, layer in body.Layers do
		poses[i] = UseAnim.pose(layer.Name, now - layer.Start, body.Seed, asleep)
	end
	for name, joint in body.Joints do
		local out = read(joint)
		for i, layer in body.Layers do
			local pose = poses[i]
			if pose then
				out = UseAnim.apply(out, pose, name, UseAnim.ease(layer.Weight))
			end
		end
		write(joint, out)
	end
end

function UseMotion.init()
	local Layers = require(script.Parent.PoseLayers)

	-- Quién está cerca y usando algo (cada medio segundo)
	task.spawn(function()
		while true do
			local camera = workspace.CurrentCamera
			local from = camera and camera.CFrame.Position or Vector3.zero
			local list = {}
			for _, other in Players:GetPlayers() do
				local character = other.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if character and root and (root.Position - from).Magnitude < ACTIVE_DISTANCE then
					local body = bodies[character]
					if other:GetAttribute("UsePose") or (body and #body.Layers > 0) then
						body = bodyOf(character)
						if body then
							table.insert(list, body)
						end
					end
				end
			end
			active = list
			task.wait(0.5)
		end
	end)

	-- Tu personaje empieza enseguida (sin esperar a la próxima vuelta)
	local me = Players.LocalPlayer
	me:GetAttributeChangedSignal("UsePose"):Connect(function()
		local character = me.Character
		local body = character and bodyOf(character)
		if body and not table.find(active, body) then
			table.insert(active, body)
		end
	end)

	Layers.add("UseMotion", 25, function(dt, now)
		for _, body in active do
			if body.Model.Parent then
				local ok, err = pcall(UseMotion.stepBody, body, dt, now, Layers.read, Layers.write)
				if not ok then
					warn("[UseMotion] " .. tostring(err))
					bodies[body.Model] = nil
				end
			end
		end
	end)
end

return UseMotion
