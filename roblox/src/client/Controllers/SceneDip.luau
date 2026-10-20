-- SceneDip (cliente): tapa los saltos del jugador de la historia con un fundido rápido. Nada de
-- cortes secos: «estás en el pasillo» → negro → «estás en tu pupitre».
--
-- El servidor (Services/SceneService.dip / teleport) sube el atributo SceneDip del jugador:
--   * sin SceneDipLead: el salto es ya → negro al instante, se recoloca la cámara detrás de ti y la
--     imagen vuelve poco a poco (ActorStaging.DipHold + DipIn);
--   * con SceneDipLead = s: primero se oscurece en s segundos (el salto llega al final) y luego vuelve.
-- Si ya hay una cinemática (InCinematic) no hace nada: la cinemática ya lo tapa con sus planos.
-- Siempre se quita sola (como mucho ActorStaging.DipMax segundos a negro), aunque mueras o reaparezcas.
-- No bloquea los controles (no hay nada que devolver). Lo arranca Controllers/ActorLife.init.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ActorStaging = require(ReplicatedStorage.Shared.LifeStory.ActorStaging)

local SceneDip = {}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local cover: Frame? = nil
local serial = 0
local started = false

local function ensureGui(): Frame?
	if cover and cover.Parent and gui and gui.Parent then
		return cover
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil
	end
	local screen = Instance.new("ScreenGui")
	screen.Name = "SceneDip"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 35 -- por encima del juego y del HUD; por debajo de conversaciones y cinemáticas
	screen.Enabled = false
	local frame = Instance.new("Frame")
	frame.Name = "Cover"
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Active = false
	frame.Parent = screen
	screen.Parent = playerGui
	gui, cover = screen, frame
	return frame
end

-- Opacidad de la pantalla (0 = se ve todo, 1 = negro)
local function setBlack(amount: number)
	local frame = ensureGui()
	if not frame or not gui then
		return
	end
	frame.BackgroundTransparency = 1 - math.clamp(amount, 0, 1)
	gui.Enabled = amount > 0.001
end

-- La cámara detrás de ti (si es la de siempre: si una conversación ya la lleva, no se toca)
local function reframe()
	pcall(function()
		local camera = workspace.CurrentCamera
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not camera or not root or camera.CameraType ~= Enum.CameraType.Custom then
			return
		end
		local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if look.Magnitude < 0.1 then
			return
		end
		look = look.Unit
		local focus = root.Position + Vector3.new(0, 1.5, 0)
		camera.CFrame = CFrame.lookAt(focus - look * 11 + Vector3.new(0, 3.5, 0), focus)
	end)
end

-- Anima la opacidad de `from` a `to` en `seconds` (se corta si empieza otro fundido)
local function animate(id: number, from: number, to: number, seconds: number): boolean
	local start = os.clock()
	while serial == id do
		local k = if seconds > 0 then math.clamp((os.clock() - start) / seconds, 0, 1) else 1
		local eased = k * k * (3 - 2 * k)
		setBlack(from + (to - from) * eased)
		if k >= 1 then
			return true
		end
		RunService.RenderStepped:Wait()
	end
	return false
end

-- Un fundido (lead: segundos hasta negro; 0 = negro ya)
function SceneDip.play(lead: number?)
	if player:GetAttribute("InCinematic") then
		return
	end
	serial += 1
	local id = serial
	task.spawn(function()
		pcall(function()
			local current = if cover then 1 - cover.BackgroundTransparency else 0
			if lead and lead > 0 then
				if not animate(id, current, 1, lead) then
					return
				end
			else
				setBlack(1)
			end
			-- El salto ya se ha hecho (o llega ahora): un instante a negro, la cámara detrás y vuelve
			task.wait(ActorStaging.DipHold)
			if serial ~= id then
				return
			end
			reframe()
			animate(id, 1, 0, ActorStaging.DipIn)
		end)
		if serial == id then
			setBlack(0) -- (pase lo que pase, la pantalla vuelve)
		end
	end)
	-- Seguro: nunca se queda a negro
	task.delay((lead or 0) + ActorStaging.DipMax, function()
		if serial == id then
			setBlack(0)
		end
	end)
end

function SceneDip.init()
	if started then
		return
	end
	started = true
	player:GetAttributeChangedSignal("SceneDip"):Connect(function()
		local lead = player:GetAttribute("SceneDipLead")
		SceneDip.play(if type(lead) == "number" then lead else nil)
	end)
	-- Al reaparecer, la pantalla limpia
	player.CharacterAdded:Connect(function()
		serial += 1
		setBlack(0)
	end)
end

return SceneDip
