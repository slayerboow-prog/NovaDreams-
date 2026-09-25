-- Cinematics (cliente): reproduce las escenas de cámara de la historia (shared/LifeStory/Cinematics.luau).
-- Bandas negras de cine, cámara que viaja por los planos, subtítulos con voz, rótulos grandes,
-- música y un botón "Saltar". Mientras dura, se ocultan los menús y el personaje no se mueve.
-- Las posiciones (tu casa, tu ventanal, las zonas…) las manda el servidor ya resueltas.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Definitions = require(ReplicatedStorage.Shared.LifeStory.Cinematics)
local Strings = require(ReplicatedStorage.Shared.LifeStory.Strings)
local Theme = require(script.Parent.Parent.UI.Theme)
local StoryAudio = require(script.Parent.StoryAudio)
local DayLight = require(script.Parent.DayLight)

local C = Theme.Colors
local Cinematics = {}

local player = Players.LocalPlayer
local BAR = 0.11 -- alto de cada banda negra (proporción de la pantalla)

---------------------------------------------------------------------
-- Cámara
---------------------------------------------------------------------

local function ease(kind: string?, t: number): number
	t = math.clamp(t, 0, 1)
	if kind == "In" then
		return t * t
	elseif kind == "Out" then
		return 1 - (1 - t) * (1 - t)
	elseif kind == "Linear" then
		return t
	end
	return 0.5 - 0.5 * math.cos(math.pi * t)
end

local function point(anchors: { [string]: CFrame }, spec: { any }?): Vector3?
	if not spec then
		return nil
	end
	local anchor = anchors[spec[1]]
	if not anchor then
		return nil
	end
	local offset = spec[2] or Vector3.zero
	return if spec[3] then anchor:PointToWorldSpace(offset) else anchor.Position + offset
end

local function shotCFrame(anchors: { [string]: CFrame }, shot: { [string]: any }, u: number): CFrame?
	local a = ease(shot.Easing, u)
	if shot.Orbit then
		local anchor = anchors[shot.Orbit]
		if not anchor then
			return nil
		end
		local center = anchor.Position
		local angle = math.rad(shot.FromAngle + (shot.ToAngle - shot.FromAngle) * a)
		local position = center + Vector3.new(math.cos(angle) * shot.Radius, shot.Height, math.sin(angle) * shot.Radius)
		return CFrame.lookAt(position, center + Vector3.new(0, 1, 0))
	end
	local from, to = point(anchors, shot.From), point(anchors, shot.To)
	local look = point(anchors, shot.Look)
	local lookTo = point(anchors, shot.LookTo) or look
	if not from or not to or not look or not lookTo then
		return nil
	end
	local position = from:Lerp(to, a)
	local target = look:Lerp(lookTo, a)
	if (target - position).Magnitude < 0.01 then
		target += Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(position, target)
end

---------------------------------------------------------------------
-- Interfaz de la escena
---------------------------------------------------------------------

local function hideOtherGuis(except: ScreenGui): () -> ()
	local restored = {}
	for _, child in player:WaitForChild("PlayerGui"):GetChildren() do
		if child:IsA("ScreenGui") and child ~= except and child.Enabled then
			child.Enabled = false
			table.insert(restored, child)
		end
	end
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	return function()
		for _, gui in restored do
			gui.Enabled = true
		end
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)
	end
end

local function setControls(enabled: boolean)
	pcall(function()
		local module = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 2) :: any)
		local controls = module:GetControls()
		if enabled then
			controls:Enable()
		else
			controls:Disable()
		end
	end)
end

local function fadeLabel(label: TextLabel, visible: boolean, seconds: number)
	TweenService:Create(label, TweenInfo.new(seconds), {
		TextTransparency = if visible then 0 else 1,
		TextStrokeTransparency = if visible then 0.6 else 1,
	}):Play()
end

---------------------------------------------------------------------
-- Reproducir
---------------------------------------------------------------------

local playing = 0

-- ¿Se está viendo una escena? (los diálogos esperan a que termine)
function Cinematics.isPlaying(): boolean
	return playing > 0
end

-- Espera hasta que termina (o hasta que el jugador la salta)
function Cinematics.play(payload: { [string]: any })
	local def = Definitions[payload.Id]
	if not def then
		return
	end
	playing += 1
	local anchors = payload.Anchors or {}
	local names = payload.Names or {}
	local args = payload.Args or {}

	local gui = Theme.create("ScreenGui", {
		Name = "Cinematic",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 50,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local restoreGuis = hideOtherGuis(gui)
	setControls(false)

	-- Bandas de cine
	local top = Theme.create("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 0), Parent = gui })
	local bottom = Theme.create("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		Parent = gui,
	})
	TweenService:Create(top, TweenInfo.new(0.8), { Size = UDim2.fromScale(1, BAR) }):Play()
	TweenService:Create(bottom, TweenInfo.new(0.8), { Size = UDim2.fromScale(1, BAR) }):Play()

	-- Negro para fundidos
	local black = Theme.create("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = if def.FadeIn then 0 else 1,
		ZIndex = 10,
		Parent = gui,
	})
	if def.FadeIn then
		TweenService:Create(black, TweenInfo.new(1.6), { BackgroundTransparency = 1 }):Play()
	end

	-- Subtítulos (en la banda de abajo) y rótulos (en el centro)
	local caption = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 1 - BAR / 2),
		Size = UDim2.new(0.86, 0, BAR, -8),
		Text = "",
		TextSize = 20,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1,
		ZIndex = 5,
		Parent = gui,
	})
	local title = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.new(0.9, 0, 0, 60),
		Text = "",
		Font = Theme.FontBold,
		TextSize = 44,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.Text,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Parent = gui,
	})
	local subtitle = Theme.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.45, 34),
		Size = UDim2.new(0.8, 0, 0, 30),
		Text = "",
		TextSize = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.Gold,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Parent = gui,
	})

	local skipped = false
	local skip = Theme.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, BAR / 2, 0),
		Size = UDim2.fromOffset(120, 34),
		Text = Strings.get("CINE.SKIP"),
		TextSize = 15,
		ZIndex = 20,
		Parent = gui,
	})
	skip.Activated:Connect(function()
		skipped = true
	end)

	-- Audio y "modo cine" en la luz (fondo algo desenfocado, más contraste)
	DayLight.setCinematic(true)
	StoryAudio.cinematicStart(def.Music)
	StoryAudio.sting(def.Sting)

	-- Línea de tiempo: subtítulos y rótulos
	local events = {}
	for _, line in def.Lines or {} do
		table.insert(events, { At = line.At, Kind = "Line", Data = line })
	end
	for _, t in def.Titles or {} do
		table.insert(events, { At = t.At, Kind = "Title", Data = t })
	end
	table.sort(events, function(a, b)
		return a.At < b.At
	end)
	local nextEvent = 1
	local captionToken, titleToken = 0, 0

	local camera = workspace.CurrentCamera
	local previousType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local shots = def.Shots or {}
	local start = os.clock()
	local fadeOutStarted = false
	while not skipped do
		local elapsed = os.clock() - start
		if elapsed >= def.Duration then
			break
		end

		-- Plano actual
		local t = elapsed
		for _, shot in shots do
			if t <= shot.Duration then
				local cf = shotCFrame(anchors, shot, t / shot.Duration)
				if cf then
					camera.CFrame = cf
				end
				break
			end
			t -= shot.Duration
		end

		-- Subtítulos y rótulos que tocan ya
		while nextEvent <= #events and events[nextEvent].At <= elapsed do
			local event = events[nextEvent]
			nextEvent += 1
			if event.Kind == "Line" then
				local line = event.Data
				local speaker = line.Speaker and names[line.Speaker]
				local text = Strings.get(line.TextKey, args)
				caption.Text = if speaker then ('<font color="#FFC43C"><b>%s:</b></font> %s'):format(Strings.get(speaker), text) else text
				fadeLabel(caption, true, 0.3)
				StoryAudio.speak(line.Speaker or "Narrador", line.TextKey, args)
				captionToken += 1
				local token = captionToken
				task.delay(math.max(3, #text * 0.06), function()
					if token == captionToken then
						fadeLabel(caption, false, 0.4)
					end
				end)
			else
				local data = event.Data
				title.Text = Strings.get(data.TextKey, args)
				subtitle.Text = if data.SubKey then Strings.get(data.SubKey, args) else ""
				fadeLabel(title, true, 0.8)
				fadeLabel(subtitle, true, 0.8)
				titleToken += 1
				local token = titleToken
				task.delay(data.Duration or 3, function()
					if token == titleToken then
						fadeLabel(title, false, 0.8)
						fadeLabel(subtitle, false, 0.8)
					end
				end)
			end
		end

		-- Fundido a negro al final
		if def.FadeOut and not fadeOutStarted and elapsed >= def.Duration - 1.2 then
			fadeOutStarted = true
			TweenService:Create(black, TweenInfo.new(1.1), { BackgroundTransparency = 0 }):Play()
		end
		RunService.RenderStepped:Wait()
	end

	-- Volver al juego
	if def.FadeOut or skipped then
		TweenService:Create(black, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
		task.wait(0.35)
	end
	camera.CameraType = if previousType == Enum.CameraType.Scriptable then Enum.CameraType.Custom else previousType
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	restoreGuis()
	setControls(true)
	StoryAudio.cinematicEnd()
	DayLight.setCinematic(false)
	skip.Visible = false
	fadeLabel(caption, false, 0.3)
	fadeLabel(title, false, 0.3)
	fadeLabel(subtitle, false, 0.3)
	TweenService:Create(top, TweenInfo.new(0.6), { Size = UDim2.fromScale(1, 0) }):Play()
	TweenService:Create(bottom, TweenInfo.new(0.6), { Size = UDim2.fromScale(1, 0) }):Play()
	TweenService:Create(black, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	task.wait(0.8)
	gui:Destroy()
	playing = math.max(0, playing - 1)
end

return Cinematics
