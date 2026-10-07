-- UseMotion (cliente): la postura de cada jugador mientras usa un mueble (sentado, tumbado, en el
-- grifo, tecleando, tocando el piano…). Lo que hace lo dice su atributo UsePose (InteractService);
-- las posturas son las de UseAnim.
--
-- Es una capa de PoseLayers (la 25: después de Locomotion, antes de ReactMotion), así no se
-- acumula con las demás. Cada postura entra y sale mezclándose poco a poco (UseAnim.BlendIn /
-- BlendOut con curva suave): al sentarse, tumbarse o levantarse no hay tirones. Si cambia de
-- postura (del sillón al ordenador), la vieja se va mientras entra la nueva.
-- Se ve en todos los jugadores cercanos y en los personajes (NPCs del mapa y actores de tus escenas)
-- con el atributo UsePose y la etiqueta UsePoseNpc (World/Npc.setPose: sentados en una silla…).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Joints = require(game:GetService("ReplicatedStorage").Shared.Joints)

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
		-- (al aplicar el aspecto Roblox cambia las piezas y sus articulaciones: se vuelven a buscar)
		if Joints.stale(body.Joints, model) then
			body.Joints = Joints.collect(model, JOINTS)
		end
		return body
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return nil
	end
	body = {
		Model = model,
		Player = Players:GetPlayerFromCharacter(model),
		Joints = Joints.collect(model, JOINTS), -- Motor6D o AnimationConstraint (shared/Joints)
		Layers = {},
		Seed = math.random() * 10,
	}
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
	-- (un personaje con su tarea en las manos —leer en el banco, el móvil…— sigue con los brazos de la tarea)
	local armsBusy = body.Player == nil and UseAnim.armsBusy(body.Model:GetAttribute("Work"))
	for name, joint in body.Joints do
		local out = read(joint)
		for i, layer in body.Layers do
			local pose = poses[i]
			if pose then
				out = UseAnim.applyJoint(out, pose, name, UseAnim.ease(layer.Weight), armsBusy)
			end
		end
		write(joint, out)
	end
end

function UseMotion.init()
	local Layers = require(script.Parent.PoseLayers)
	local me = Players.LocalPlayer

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
			-- Personajes (NPCs del mapa, actores de tus escenas) sentados o usando algo: Npc.setPose
			local scenes = workspace:FindFirstChild("StoryScenes")
			local mine = scenes and scenes:FindFirstChild("Scene_" .. me.UserId)
			for _, model in CollectionService:GetTagged("UsePoseNpc") do
				if not model:IsA("Model") or not model.Parent then
					continue
				end
				-- (los de la escena de otro jugador no los ves)
				if scenes and model:IsDescendantOf(scenes) and not (mine and model:IsDescendantOf(mine)) then
					continue
				end
				local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (root.Position - from).Magnitude < ACTIVE_DISTANCE then
					local body = bodyOf(model)
					if body then
						table.insert(list, body)
					end
				end
			end
			-- Los que ya no tienen postura siguen hasta acabar de levantarse (se quitan solos al llegar a 0)
			for _, body in active do
				if not body.Player and #body.Layers > 0 and body.Model.Parent and not table.find(list, body) then
					table.insert(list, body)
				end
			end
			active = list
			task.wait(0.5)
		end
	end)

	-- Tu personaje empieza enseguida (sin esperar a la próxima vuelta)
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
