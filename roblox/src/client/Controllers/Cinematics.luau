-- Cinematics (cliente): reproduce las escenas de cámara de la historia (shared/LifeStory/Cinematics.luau).
-- Bandas negras de cine, cámara que viaja por los planos, subtítulos con voz, rótulos grandes,
-- música y un botón "Saltar". Mientras dura, se ocultan los menús y el personaje no se mueve.
-- Las posiciones (tu casa, tu ventanal, las zonas…) las manda el servidor ya resueltas.
-- Si hay una conversación abierta, su cámara se aparta mientras dura la escena y retoma su plano al acabar
-- (los controles se cuentan en Controls; el atributo InCinematic avisa a las armas sin require).

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
local ActorLife = require(script.Parent.ActorLife)
local Controls = require(script.Parent.Controls)
local CineCamera = require(script.Parent.CineCamera)
local Emotion = require(ReplicatedStorage.Shared.LifeStory.Emotion)

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

local baseShotCFrame: (anchors: { [string]: CFrame }, shot: { [string]: any }, u: number) -> CFrame?

-- ¿Ese punto está dentro de una sala? (los interiores están muy arriba; o estás tú dentro y cerca)
local function indoors(center: Vector3): boolean
	if center.Y > 3000 then
		return true
	end
	if player:GetAttribute("InteriorKey") == nil then
		return false
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - center).Magnitude < 60
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

-- Cámara en mano: un temblor suave y orgánico (suma de senos a distintas velocidades)
local function handheld(amount: number, t: number): CFrame
	if amount <= 0 then
		return CFrame.identity
	end
	local a = amount * 0.02
	return CFrame.Angles(
		(math.sin(t * 1.3) + math.sin(t * 2.9 + 1.7) * 0.5) * a,
		(math.sin(t * 1.1 + 0.6) + math.sin(t * 2.3 + 2.1) * 0.5) * a,
		math.sin(t * 0.7 + 0.3) * a * 0.6
	)
end

-- El campo de visión del plano (Fov = 50, o { 60, 40 } para un zoom lento de 60 a 40)
local function shotFov(shot: { [string]: any }, u: number): number?
	local fov = shot.Fov
	if type(fov) == "number" then
		return fov
	elseif type(fov) == "table" then
		return fov[1] + (fov[2] - fov[1]) * ease(shot.Easing, u)
	end
	return nil
end

local function shotCFrame(anchors: { [string]: CFrame }, shot: { [string]: any }, u: number): CFrame?
	local cf = baseShotCFrame(anchors, shot, u)
	if not cf then
		return nil
	end
	if shot.Roll then
		cf *= CFrame.Angles(0, 0, math.rad(shot.Roll))
	end
	return cf * handheld(shot.Shake or 0, os.clock())
end

function baseShotCFrame(anchors: { [string]: CFrame }, shot: { [string]: any }, u: number): CFrame?
	local a = ease(shot.Easing, u)
	if shot.Orbit then
		local anchor = anchors[shot.Orbit]
		if not anchor then
			return nil
		end
		local center = anchor.Position
		local angle = math.rad(shot.FromAngle + (shot.ToAngle - shot.FromAngle) * a)
		local radius = shot.Radius
		if indoors(center) then
			radius = math.min(radius, CineCamera.InteriorRadius) -- en una sala no cabe un plano de 12 studs
		end
		local target = center + Vector3.new(0, shot.LookHeight or 1, 0)
		local position = center + Vector3.new(math.cos(angle) * radius, shot.Height, math.sin(angle) * radius)
		-- Sin atravesar paredes: si hay un muro entre el centro y la cámara, se acerca
		position = CineCamera.clamp(target, position)
		if (target - position).Magnitude < 0.05 then
			target += Vector3.new(0, 0, -1)
		end
		return CFrame.lookAt(position, target)
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
	-- Lo de Roblox: se apunta cómo estaba cada cosa y se deja luego igual (antes se encendía todo,
	-- también la mochila y la lista de jugadores que el juego tiene apagadas)
	local core: { [Enum.CoreGuiType]: boolean } = {}
	pcall(function()
		for _, kind in Enum.CoreGuiType:GetEnumItems() do
			if kind ~= Enum.CoreGuiType.All then
				local ok, enabled = pcall(function()
					return StarterGui:GetCoreGuiEnabled(kind)
				end)
				if ok and type(enabled) == "boolean" then
					core[kind] = enabled
				end
			end
		end
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	return function()
		for _, gui in restored do
			gui.Enabled = true
		end
		for kind, enabled in core do
			pcall(function()
				StarterGui:SetCoreGuiEnabled(kind, enabled)
			end)
		end
	end
end

local function setControls(enabled: boolean)
	if enabled then
		Controls.enable("Cinematica")
	else
		Controls.disable("Cinematica")
	end
end

-- ¿Ha cargado ya el suelo bajo ese punto? (el mapa se carga por trozos alrededor de la cámara)
local areaParams = RaycastParams.new()
areaParams.FilterType = Enum.RaycastFilterType.Exclude
local function areaLoaded(position: Vector3): boolean
	local ok, hit = pcall(function()
		areaParams.FilterDescendantsInstances = if player.Character then { player.Character } else {}
		return workspace:Raycast(position + Vector3.new(0, 40, 0), Vector3.new(0, -400, 0), areaParams)
	end)
	return not ok or hit ~= nil
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
local pending = 0 -- escenas que ya han llegado pero esperan su turno (cola de momentos de LifeStory)

local function setPlaying(delta: number)
	playing = math.max(0, playing + delta)
	-- Para quien no puede requerir este módulo (las armas): mientras hay escena, no se apunta
	player:SetAttribute("InCinematic", if playing > 0 then true else nil)
	-- Sin nombres ni iconos flotantes encima de nadie durante la escena
	CineCamera.quietLabels("Cinematica", playing > 0)
end

-- ¿Se está viendo una escena, o hay una esperando? (los diálogos esperan a que termine)
function Cinematics.isPlaying(): boolean
	return playing > 0 or pending > 0
end

-- ¿Hay una escena en pantalla AHORA? (sin contar las que esperan su turno en la cola)
function Cinematics.isOnScreen(): boolean
	return playing > 0
end

-- Apunta una escena que acaba de llegar y aún no empieza; devuelve cómo soltarla (al acabar)
function Cinematics.hold(): () -> ()
	pending += 1
	local released = false
	return function()
		if not released then
			released = true
			pending = math.max(0, pending - 1)
		end
	end
end

-- Lo que hay que deshacer si una escena falla a medias (si no, la interfaz se quedaba escondida)
type Cleanup = { Restore: (() -> ())?, Gui: Instance?, Counted: boolean }

-- Espera hasta que termina (o hasta que el jugador la salta)
local function playImpl(payload: { [string]: any }, cleanup: Cleanup)
	local def = Definitions[payload.Id]
	if not def then
		return
	end
	setPlaying(1)
	cleanup.Counted = true
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
	cleanup.Restore, cleanup.Gui = restoreGuis, gui
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
		TextScaled = true, -- en el móvil la banda es baja: la frase se encoge para no salirse
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTransparency = 1,
		ZIndex = 5,
		Parent = gui,
	})
	Theme.create("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 12, Parent = caption })
	-- El rótulo y su subtítulo van en columna: si el título ocupa dos líneas, el subtítulo baja
	local titleBlock = Theme.create("Frame", {
		Name = "TitleBlock",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.47),
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = gui,
	})
	Theme.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = titleBlock,
	})
	local title = Theme.label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Text = "",
		Font = Theme.FontBold,
		TextSize = 44,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.Text,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Parent = titleBlock,
	})
	-- En pantallas pequeñas el rótulo grande no cabe: se reduce
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
	if viewport and viewport.X < 900 then
		title.TextSize = 32
	end
	local subtitle = Theme.label({
		Size = UDim2.new(0.9, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Text = "",
		TextSize = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.Gold,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		ZIndex = 6,
		Parent = titleBlock,
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
	for _, a in def.Anims or {} do
		table.insert(events, { At = a.At, Kind = "Anim", Data = a })
	end
	table.sort(events, function(a, b)
		return a.At < b.At
	end)
	local nextEvent = 1
	local captionToken, titleToken = 0, 0

	local camera = workspace.CurrentCamera
	local previousFov = camera.FieldOfView
	local previousCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable

	-- Quién hace un gesto: "Player" (tú), "Todos" (todos los de tu escena) o alguien del reparto
	local function actorsFor(who: string?): { Model }
		if who == "Player" then
			return if player.Character then { player.Character } else {}
		elseif who == "Todos" then
			local list = ActorLife.cast()
			if player.Character then
				table.insert(list, player.Character)
			end
			return list
		elseif who then
			local model = ActorLife.find(who)
			return if model then { model } else {}
		end
		return {}
	end

	local shots = def.Shots or {}

	-- Si el mapa aún no ha cargado donde empieza el primer plano (se carga por trozos), la
	-- pantalla sigue en negro un momento en vez de enseñar el vacío
	local first = shots[1] and shotCFrame(anchors, shots[1], 0)
	if first and not areaLoaded(first.Position) then
		black.BackgroundTransparency = 0
		local waited = 0
		while waited < 2.5 and not skipped and not areaLoaded(first.Position) do
			waited += task.wait(0.1)
		end
		TweenService:Create(black, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	end

	local start = os.clock()
	local fadeOutStarted = false
	local currentShot: { [string]: any }? = nil
	while not skipped do
		local elapsed = os.clock() - start
		if elapsed >= def.Duration then
			break
		end

		-- Plano actual
		local t = elapsed
		for _, shot in shots do
			if t <= shot.Duration then
				local u = t / shot.Duration
				if currentShot ~= shot then
					currentShot = shot
					if shot.Dip then
						-- Fundido rápido a negro entre planos
						black.BackgroundTransparency = 0
						TweenService:Create(black, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
					end
				end
				local cf = shotCFrame(anchors, shot, u)
				if cf then
					camera.CFrame = cf
					-- Enfoque: lo que mira el plano, nítido; el fondo, desenfocado
					local lookAt = if shot.Orbit then anchors[shot.Orbit] and anchors[shot.Orbit].Position else nil
					if not lookAt then
						lookAt = point(anchors, shot.Look)
					end
					DayLight.setFocus(if lookAt and shot.Focus ~= false then (lookAt - cf.Position).Magnitude else nil)
				end
				camera.FieldOfView = shotFov(shot, u) or previousFov
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
				-- Si quien habla está en la escena, habla con el cuerpo
				local who = line.Speaker and line.Speaker ~= "Narrador" and ActorLife.find(line.Speaker)
				if who then
					ActorLife.speak(who, line.A or Emotion.of({ S = line.Speaker, T = text }, text), math.max(2, #text * 0.05))
				end
				captionToken += 1
				local token = captionToken
				task.delay(math.max(3, #text * 0.06), function()
					if token == captionToken then
						fadeLabel(caption, false, 0.4)
					end
				end)
			elseif event.Kind == "Anim" then
				local data = event.Data
				for _, model in actorsFor(data.Who) do
					ActorLife.play(model, data.Play, data.Duration)
				end
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
	StoryAudio.stopVoice() -- (si se salta, la frase a medias no sigue sonando)
	if def.FadeOut or skipped then
		TweenService:Create(black, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
		task.wait(0.35)
	end
	camera.FieldOfView = previousFov
	DayLight.setFocus(nil)
	-- La cámara vuelve donde estaba (o detrás de ti). Si hay una conversación abierta con su plano,
	-- en el fotograma siguiente lo retoma ella (DialogueUI)
	CineCamera.restore(previousCFrame)
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
	setPlaying(-1)
	cleanup.Counted = false
end

function Cinematics.play(payload: { [string]: any })
	local cleanup: Cleanup = { Counted = false }
	local ok, err = pcall(playImpl, payload, cleanup)
	if ok then
		return
	end
	warn("[Cinematics] La escena falló; se devuelve la interfaz: " .. tostring(err))
	-- Pase lo que pase: vuelven la interfaz, los controles y la cámara
	if cleanup.Restore then
		pcall(cleanup.Restore)
	end
	pcall(setControls, true)
	pcall(StoryAudio.stopVoice)
	pcall(function()
		CineCamera.restore(nil)
		DayLight.setFocus(nil)
		DayLight.setCinematic(false)
		StoryAudio.cinematicEnd()
	end)
	if cleanup.Gui then
		pcall(function()
			(cleanup.Gui :: Instance):Destroy()
		end)
	end
	if cleanup.Counted then
		setPlaying(-1)
	end
end

return Cinematics
