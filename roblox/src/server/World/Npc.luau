-- Npc: personajes sencillos controlados por el servidor (clientes, camarero, barman…).
--   Npc.create(name, parent, cf, look?)  -> Model con HumanoidRootPart anclado (se mueve con tweens)
--   Npc.say(npc, text?)                  -> bocadillo de texto sobre la cabeza (nil lo oculta)
--   Npc.icon(npc, text?)                 -> icono pequeño sobre la cabeza (✋, ⏳, 😋…)
--   Npc.walkTo(npc, { Vector3 }, speed)  -> camina por esos puntos (espera hasta llegar)
--   Npc.sit(npc, seat) / Npc.stand(npc)  -> sentarse en una silla y levantarse
-- Usa el avatar por defecto de Roblox con colores al azar; si falla, un muñeco de bloques.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Npc = {}

local rgb = Color3.fromRGB
local SKINS = { rgb(255, 219, 172), rgb(241, 194, 125), rgb(224, 172, 105), rgb(198, 134, 66), rgb(141, 85, 36), rgb(92, 58, 30) }
local SHIRTS = { rgb(200, 60, 60), rgb(60, 110, 200), rgb(60, 160, 90), rgb(240, 200, 60), rgb(150, 80, 170), rgb(240, 240, 240), rgb(40, 40, 46), rgb(230, 120, 40) }
local PANTS = { rgb(40, 50, 80), rgb(30, 30, 34), rgb(110, 90, 70), rgb(80, 80, 90), rgb(60, 70, 110) }

export type Look = { Skin: Color3?, Shirt: Color3?, Pants: Color3? }

local function pick<T>(list: { T }): T
	return list[math.random(1, #list)]
end

-- Muñeco de bloques (por si no se puede crear el avatar de Roblox)
local function blockRig(look: Look): Model
	local m = Instance.new("Model")
	local function part(name: string, size: Vector3, offset: Vector3, color: Color3)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.CFrame = CFrame.new(offset)
		p.Parent = m
		return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), look.Shirt :: Color3)
	root.Transparency = 1
	part("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), look.Shirt :: Color3)
	part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), look.Skin :: Color3)
	for _, x in { -1.5, 1.5 } do
		part("Arm", Vector3.new(1, 2, 1), Vector3.new(x, 3, 0), look.Skin :: Color3)
	end
	for i, x in { -0.5, 0.5 } do
		part(if i == 1 then "LeftLeg" else "RightLeg", Vector3.new(1, 2, 1), Vector3.new(x, 1, 0), look.Pants :: Color3)
	end
	for _, p in m:GetChildren() do
		if p ~= root and p:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = 2
	humanoid.Parent = m
	m.PrimaryPart = root
	return m
end

function Npc.create(name: string, parent: Instance, cf: CFrame, look: Look?): Model
	local l: Look = {
		Skin = (look and look.Skin) or pick(SKINS),
		Shirt = (look and look.Shirt) or pick(SHIRTS),
		Pants = (look and look.Pants) or pick(PANTS),
	}
	local ok, model = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = l.Skin :: Color3
		desc.LeftArmColor = l.Skin :: Color3
		desc.RightArmColor = l.Skin :: Color3
		desc.TorsoColor = l.Shirt :: Color3
		desc.LeftLegColor = l.Pants :: Color3
		desc.RightLegColor = l.Pants :: Color3
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		model = blockRig(l)
	end
	model.Name = name
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanTouch = false
		end
	end
	root.Anchored = true
	model.PrimaryPart = root
	-- cf = pies en el suelo, mirando hacia donde mira cf
	root.CFrame = cf * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
	model.Parent = parent
	return model
end

local function billboard(npc: Model, name: string, offset: number, size: UDim2): TextLabel?
	local head = npc:FindFirstChild("Head") :: BasePart?
	if not head then
		return nil
	end
	local gui = head:FindFirstChild(name) :: BillboardGui?
	if not gui then
		local g = Instance.new("BillboardGui")
		g.Name = name
		g.Size = size
		g.StudsOffset = Vector3.new(0, offset, 0)
		g.MaxDistance = 70
		g.AlwaysOnTop = true
		g.Parent = head
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.new(1, 1, 1)
		label.BackgroundTransparency = if name == "Bubble" then 0.05 else 1
		label.TextColor3 = if name == "Bubble" then Color3.fromRGB(20, 20, 24) else Color3.new(1, 1, 1)
		label.TextStrokeTransparency = if name == "Bubble" then 1 else 0.3
		label.TextScaled = true
		label.TextWrapped = true
		label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		label.Parent = g
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = label
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 4)
		pad.PaddingBottom = UDim.new(0, 4)
		pad.Parent = label
		gui = g
	end
	return (gui :: BillboardGui):FindFirstChildOfClass("TextLabel")
end

-- Bocadillo de texto (nil lo oculta)
function Npc.say(npc: Model, text: string?)
	local label = billboard(npc, "Bubble", 3.4, UDim2.fromOffset(260, 70))
	if label then
		label.Text = text or ""
		label.Parent.Enabled = text ~= nil
	end
end

-- Icono pequeño sobre la cabeza (nil lo oculta)
function Npc.icon(npc: Model, text: string?)
	local label = billboard(npc, "Icon", 2.2, UDim2.fromOffset(46, 46))
	if label then
		label.Text = text or ""
		label.Parent.Enabled = text ~= nil
	end
end

-- Camina por los puntos (a la altura del suelo) mirando hacia donde va. Espera hasta llegar.
function Npc.walkTo(npc: Model, points: { Vector3 }, speed: number?)
	local root = npc.PrimaryPart
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or not npc.Parent then
		return
	end
	local height = humanoid.HipHeight + root.Size.Y / 2
	for _, point in points do
		if not npc.Parent then
			return
		end
		local target = point + Vector3.new(0, height, 0)
		local from = root.Position
		local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
		local distance = flat.Magnitude
		if distance > 0.1 then
			local facing = CFrame.new(from) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
			root.CFrame = facing
			local tween = TweenService:Create(root, TweenInfo.new(distance / (speed or 9), Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(target) * facing.Rotation,
			})
			tween:Play()
			tween.Completed:Wait()
		end
	end
end

-- Mira hacia un punto (sin moverse)
function Npc.face(npc: Model, point: Vector3)
	local root = npc.PrimaryPart
	if not root then
		return
	end
	local flat = Vector3.new(point.X - root.Position.X, 0, point.Z - root.Position.Z)
	if flat.Magnitude > 0.1 then
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.atan2(-flat.X, -flat.Z), 0)
	end
end

local LEG_JOINTS = { LeftHip = 90, RightHip = 90, LeftKnee = -90, RightKnee = -90 }

-- Se sienta en la silla (seat: la pieza del asiento, mirando hacia la mesa)
function Npc.sit(npc: Model, seat: BasePart)
	local root = npc.PrimaryPart
	if not root then
		return
	end
	for name, angle in LEG_JOINTS do
		local joint = npc:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") and not joint:GetAttribute("BaseC0") then
			joint:SetAttribute("BaseC0", joint.C0)
			joint.C0 = joint.C0 * CFrame.Angles(math.rad(angle), 0, 0)
		end
	end
	root.CFrame = seat.CFrame * CFrame.new(0, seat.Size.Y / 2 + 1.35, 0.4)
end

function Npc.stand(npc: Model, feet: Vector3?)
	for name in LEG_JOINTS do
		local joint = npc:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			local base = joint:GetAttribute("BaseC0")
			if typeof(base) == "CFrame" then
				joint.C0 = base
				joint:SetAttribute("BaseC0", nil)
			end
		end
	end
	local root = npc.PrimaryPart
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if root and humanoid and feet then
		root.CFrame = CFrame.new(feet + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)) * root.CFrame.Rotation
	end
end

return Npc
