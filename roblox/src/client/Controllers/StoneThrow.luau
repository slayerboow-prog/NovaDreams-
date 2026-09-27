-- StoneThrow (cliente): coger piedras del suelo y lanzarlas.
--   * Tecla B (o botón 🥌 en móvil, Y en el mando): si no llevas piedra, coges una del suelo
--     (tierra, césped, arena o roca); si llevas, la lanzas hacia donde apuntas (el ratón en el
--     ordenador; el centro de la pantalla en móvil y mando).
--   * Dibuja las piedras que vuelan (las tuyas y las de los demás) siguiendo el mismo camino que
--     calcula el servidor (BreakService), así se ven suaves.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Breakables = require(ReplicatedStorage.Shared.Breakables)
local Hud = require(script.Parent.Parent.UI.Hud)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)

local StoneThrow = {}

local player = Players.LocalPlayer
local Remote: RemoteEvent
local ACTION = "Piedra"
local THROW_ANIM = { R15 = 507770453, R6 = 128853357 } -- brazo hacia delante (el gesto de señalar)

type Flying = { Part: BasePart, From: Vector3, Velocity: Vector3, Start: number, Gravity: number }
local flying: { [number]: Flying } = {}
local folder: Folder
local hinted = false

-- Hacia dónde apuntas: el ratón (ordenador) o el centro de la pantalla
local function aim(): Vector3
	local camera = workspace.CurrentCamera
	local point: Vector2
	if UserInputService.MouseEnabled and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter and not UserInputService.TouchEnabled then
		point = UserInputService:GetMouseLocation()
	else
		point = camera.ViewportSize / 2
	end
	local ray = camera:ViewportPointToRay(point.X, point.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance, folder, camera }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 250, params)
	return if hit then hit.Position else ray.Origin + ray.Direction * 250
end

local function throwGesture()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not humanoid or not animator then
		return
	end
	local animation = Instance.new("Animation")
	local r15 = humanoid.RigType == Enum.HumanoidRigType.R15
	animation.AnimationId = "rbxassetid://" .. (if r15 then THROW_ANIM.R15 else THROW_ANIM.R6)
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track:Play(0.05, 1, 1.6)
		task.delay(0.45, function()
			track:Stop(0.2)
		end)
	end
end

local function use(_, state: Enum.UserInputState)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if (player:GetAttribute("Stones") or 0) <= 0 then
		Remote:FireServer("Pick")
	else
		throwGesture()
		Remote:FireServer("Throw", aim())
	end
	return Enum.ContextActionResult.Sink
end

local function refreshButton()
	local count = player:GetAttribute("Stones") or 0
	local baby = player:GetAttribute("LifeStage") == "Bebe"
	if baby or TouchLayout.riding() then
		ContextActionService:UnbindAction(ACTION)
		return
	end
	ContextActionService:BindAction(ACTION, use, true, Enum.KeyCode.B, Enum.KeyCode.ButtonY)
	ContextActionService:SetTitle(ACTION, if count > 0 then ("🥌×%d"):format(count) else "🥌")
	TouchLayout.placeAction(ContextActionService, ACTION, "Piedra")
end

local function newStone(): BasePart
	local part = Instance.new("Part")
	part.Name = "PiedraVolando"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.7, 0.56, 0.7)
	part.Color = Color3.fromRGB(120, 116, 110)
	part.Material = Enum.Material.Slate
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = folder
	return part
end

function StoneThrow.init()
	Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Vandal") :: RemoteEvent
	folder = Instance.new("Folder")
	folder.Name = "Piedras"
	folder.Parent = workspace.CurrentCamera

	refreshButton()
	player:GetAttributeChangedSignal("LifeStage"):Connect(refreshButton)
	player:GetAttributeChangedSignal("Riding"):Connect(refreshButton)
	player:GetAttributeChangedSignal("Stones"):Connect(function()
		refreshButton()
		if (player:GetAttribute("Stones") or 0) > 0 and not hinted then
			hinted = true
			Hud.toast("Info", "🥌 Tienes una piedra: pulsa B (o 🥌) para lanzarla donde apuntes.")
		end
	end)

	Remote.OnClientEvent:Connect(function(action, id, a, b, c, d)
		if action == "Stone" then
			flying[id] = { Part = newStone(), From = a, Velocity = b, Start = c, Gravity = d }
		elseif action == "Hit" then
			local stone = flying[id]
			if stone then
				stone.Part:Destroy()
				flying[id] = nil
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		if next(flying) == nil then
			return
		end
		local now = workspace:GetServerTimeNow()
		for id, stone in flying do
			local t = now - stone.Start
			if t > 5 then
				stone.Part:Destroy()
				flying[id] = nil
			else
				local at = Breakables.positionAt(stone.From, stone.Velocity, stone.Gravity, math.max(0, t))
				stone.Part.CFrame = CFrame.new(at) * CFrame.Angles(t * 9, t * 6, 0)
			end
		end
	end)
end

return StoneThrow
