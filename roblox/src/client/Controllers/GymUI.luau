-- GymUI (cliente): el gimnasio.
--   * Recepción: entrada del día o abono mensual, lo que te queda y cómo vas de Fuerza y Forma.
--   * Entrenando: abajo sale la barra del ritmo. El marcador va y viene: toca "¡YA!" (o Espacio, o
--     A en el mando) cuando pasa por la zona verde. En el centro es "¡Perfecto!" (sube más); fuera,
--     fallo (cansa un poco). La barra naranja es el esfuerzo: cada repetición gasta y descansando
--     se recupera. Cada serie completa sube la Fuerza o la Forma física. "Dejar" (Q o B) te baja.
--   * Móvil: el botón 💪 va en el hueco de golpear y el de dejar en el de correr (TouchLayout).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local Format = require(ReplicatedStorage.Shared.Format)
local Gym = require(ReplicatedStorage.Shared.Gym)
local SoundFx = require(script.Parent.SoundFx)

local GymUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gym") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local GREEN = rgb(60, 190, 100)
local ORANGE = rgb(240, 140, 40)

type Session = {
	Kind: string,
	Name: string,
	Icon: string,
	Tempo: number,
	Zone: number,
	SetReps: number,
	Reps: number,
	Sets: number,
	Effort: number,
	Started: number,
	LastTap: number,
	Strength: number,
	Cardio: number,
}
local session: Session? = nil

local panel: Frame
local title: TextLabel
local feedback: TextLabel
local stats: TextLabel
local zone: Frame
local cursor: Frame
local effortFill: Frame
local tapButton: TextButton

---------------------------------------------------------------------
-- Entrenar
---------------------------------------------------------------------
local function refresh()
	local s = session
	if not s then
		return
	end
	title.Text = ("%s %s · Serie %d · %d/%d"):format(s.Icon, s.Name, s.Sets + 1, s.Reps, s.SetReps)
	stats.Text = ("💪 Fuerza %.1f · 🏃 Forma física %.1f"):format(s.Strength, s.Cardio)
	effortFill.Size = UDim2.fromScale(math.clamp(s.Effort / Gym.EffortMax, 0, 1), 1)
	effortFill.BackgroundColor3 = if s.Effort < 25 then rgb(220, 70, 60) else ORANGE
end

local function say(text: string, color: Color3)
	feedback.Text = text
	feedback.TextColor3 = color
end

local function tap()
	local s = session
	if not s then
		return
	end
	local now = os.clock()
	if now - s.LastTap < Gym.minRepGap(s.Kind) then
		say("¡Más despacio! Sigue el ritmo", C.Muted)
		return
	end
	s.LastTap = now
	local verdict = Gym.judge(Gym.cursor(now - s.Started, s.Tempo), s.Zone)
	if verdict == "Fallo" then
		say("✖ ¡Fuera de ritmo! Espera a la zona verde", C.Error)
		Remote:FireServer("Miss")
		return
	end
	Remote:FireServer("Rep", verdict)
end

local function stop()
	if session then
		Remote:FireServer("Stop")
	end
end

local function close()
	session = nil
	panel.Visible = false
	ContextActionService:UnbindAction("GymTap")
	ContextActionService:UnbindAction("GymStop")
end

local function onStart(data: { [string]: any })
	session = {
		Kind = data.Kind,
		Name = data.Name,
		Icon = data.Icon,
		Tempo = data.Tempo,
		Zone = data.Zone,
		SetReps = data.SetReps,
		Reps = 0,
		Sets = 0,
		Effort = data.Effort,
		Started = os.clock(),
		LastTap = 0,
		Strength = data.Strength or 0,
		Cardio = data.Cardio or 0,
	}
	panel.Visible = true
	zone.Size = UDim2.fromScale(data.Zone, 1)
	say(("Toca ¡YA! cuando el marcador pase por la zona verde · %s"):format(if data.Stat == "Cardio" then "sube tu Forma física" elseif data.Stat == "Mixto" then "Fuerza y Forma física" else "sube tu Fuerza"), C.Text)
	refresh()
	-- Espacio / A / R2: repetición.  Q / B: dejar la máquina. (Por encima de saltar)
	ContextActionService:BindActionAtPriority("GymTap", function(_, state)
		if state == Enum.UserInputState.Begin then
			tap()
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonR2)
	ContextActionService:BindActionAtPriority("GymStop", function(_, state)
		if state == Enum.UserInputState.Begin then
			stop()
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
end

local function onRep(data: { [string]: any })
	local s = session
	if not s then
		return
	end
	s.Reps = data.Reps
	s.Effort = data.Effort
	if data.Quality == "Perfecto" then
		say("⭐ ¡Perfecto!", C.Gold)
		pcall(SoundFx.play, "Aviso", 0.6, 1.9)
	else
		say("✔ ¡Bien!", GREEN)
		pcall(SoundFx.play, "Clic", 0.7, 1.2)
	end
	refresh()
end

local function onSet(data: { [string]: any })
	local s = session
	if not s then
		return
	end
	s.Sets = data.Sets
	s.Reps = 0
	s.Strength = data.Strength
	s.Cardio = data.Cardio
	local parts = {}
	if (data.GainStrength or 0) > 0 then
		table.insert(parts, ("+%.1f de Fuerza"):format(data.GainStrength))
	end
	if (data.GainCardio or 0) > 0 then
		table.insert(parts, ("+%.1f de Forma física"):format(data.GainCardio))
	end
	say(("🎉 ¡Serie %d completada! %s%s"):format(data.Sets, table.concat(parts, " · "), if data.Monitor then " (con tu monitor/a)" else ""), C.Money)
	pcall(SoundFx.play, "Aviso", 1, 1.5)
	refresh()
end

---------------------------------------------------------------------
-- Recepción
---------------------------------------------------------------------
local function openReception(data: { [string]: any })
	local window, content, closeButton = Dialog.window("GymReception", "💪 " .. (data.Gym or "Gimnasio"), Vector2.new(470, 400))
	local list = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local status = if data.Baby then "👶 Los bebés no pueden entrenar: vuelve cuando seas mayor."
		elseif data.Active then ("✔ Tienes %s: te queda%s %d día%s de gimnasio."):format(if data.Kind == "Mes" then "el abono mensual" else "la entrada del día", if data.DaysLeft == 1 then "" else "n", data.DaysLeft, if data.DaysLeft == 1 then "" else "s")
		else "🎟️ Para entrenar necesitas la entrada del día o el abono mensual."
	Theme.label({ Size = UDim2.new(1, 0, 0, 40), Text = status, TextSize = 15, TextWrapped = true, TextColor3 = if data.Active then C.Money else C.Text, LayoutOrder = 1, Parent = list })
	Theme.label({
		Size = UDim2.new(1, 0, 0, 22),
		Text = ("💪 Fuerza %d (%s) · 🏃 Forma física %d · %d series"):format(math.floor(data.Strength or 0), Gym.level(data.Strength or 0), math.floor(data.Cardio or 0), data.Sets or 0),
		TextSize = 13,
		TextColor3 = C.Muted,
		LayoutOrder = 2,
		Parent = list,
	})
	for i, pass in data.Passes or {} do
		local row = create("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = rgb(20, 32, 56), BackgroundTransparency = 0.2, LayoutOrder = 10 + i, Parent = list }, { Theme.corner(10) })
		Theme.label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -140, 0, 26), Text = ("%s <b>%s</b> · %s"):format(pass.Icon, pass.Name, Format.money(pass.Price or 0)), RichText = true, TextSize = 16, Parent = row })
		Theme.label({ Position = UDim2.fromOffset(10, 32), Size = UDim2.new(1, -140, 0, 24), Text = if pass.Days == 1 then "Un día de juego para entrenar en cualquier gimnasio" else ("%d días de juego en cualquier gimnasio de Valmar"):format(pass.Days), TextSize = 12, TextColor3 = C.Muted, TextWrapped = true, Parent = row })
		local buy = Theme.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(110, 40),
			Text = if data.Baby then "🔒" elseif data.Active then "Ampliar" else "Pagar",
			TextSize = 15,
			BackgroundColor3 = if data.Baby then rgb(50, 52, 60) else C.Accent,
			Parent = row,
		})
		buy.Activated:Connect(function()
			if not data.Baby then
				Remote:FireServer("Buy", pass.Id)
			end
		end)
	end
	Theme.label({
		Size = UDim2.new(1, 0, 0, 70),
		Text = "En cada máquina, «Entrenar». Toca ¡YA! (Espacio) cuando el marcador pase por la zona verde. Cada serie te hace más fuerte (y se nota en el cuerpo) o mejora tu forma física. Los niños pagan la mitad y usan las máquinas ligeras (cardio, esterillas, comba y saco).",
		TextSize = 12,
		TextColor3 = C.Muted,
		TextWrapped = true,
		LayoutOrder = 50,
		Parent = list,
	})
	closeButton.Activated:Connect(function()
		window:Destroy()
	end)
end

---------------------------------------------------------------------

function GymUI.init()
	local gui = create("ScreenGui", { Name = "GymGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	Theme.fit(gui)
	panel = Theme.panel({
		Name = "Gym",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(500, 176),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(10).Parent = panel
	title = Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "", Font = Theme.FontBold, TextSize = 17, Parent = panel })
	stats = Theme.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 16), Text = "", TextSize = 12, TextColor3 = C.Muted, Parent = panel })
	-- Barra del ritmo: zona verde en el centro y el marcador que va y viene
	local track = create("Frame", { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = rgb(10, 16, 30), BorderSizePixel = 0, Parent = panel }, { Theme.corner(6) })
	zone = create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.24, 1), BackgroundColor3 = GREEN, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = track }, { Theme.corner(6) })
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = rgb(120, 255, 150), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = zone }, { Theme.corner(6) })
	cursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 6, 1, 8), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, Parent = track }, { Theme.corner(3) })
	-- Esfuerzo
	Theme.label({ Position = UDim2.fromOffset(0, 70), Size = UDim2.fromOffset(90, 14), Text = "🥵 Esfuerzo", TextSize = 12, TextColor3 = C.Muted, Parent = panel })
	local effort = create("Frame", { Position = UDim2.fromOffset(92, 73), Size = UDim2.new(1, -92, 0, 8), BackgroundColor3 = rgb(10, 16, 30), BorderSizePixel = 0, Parent = panel }, { Theme.corner(4) })
	effortFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = ORANGE, BorderSizePixel = 0, Parent = effort }, { Theme.corner(4) })
	feedback = Theme.label({ Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 0, 20), Text = "", TextSize = 14, TextWrapped = true, Parent = panel })
	tapButton = Theme.button({ Position = UDim2.fromOffset(0, 110), Size = UDim2.new(0.7, 0, 0, 44), Text = "💪 ¡YA!  (Espacio)", TextSize = 20, BackgroundColor3 = rgb(200, 90, 30), Parent = panel })
	tapButton.Activated:Connect(tap)
	local stopButton = Theme.button({ Position = UDim2.new(0.72, 0, 0, 110), Size = UDim2.new(0.28, 0, 0, 44), Text = "Dejar (Q)", TextSize = 15, BackgroundColor3 = rgb(50, 52, 60), Parent = panel })
	stopButton.Activated:Connect(stop)

	-- Móvil: el botón grande junto al de saltar (en el hueco de golpear) y el de dejar
	if UserInputService.TouchEnabled then
		local touchGui = create("ScreenGui", { Name = "GymTouch", ResetOnSpawn = false, DisplayOrder = 4, Parent = player:WaitForChild("PlayerGui") })
		local big = Theme.button({ Name = "GymTap", Text = "💪", TextSize = 32, BackgroundColor3 = rgb(200, 90, 30), BackgroundTransparency = 0.15, Parent = touchGui })
		local small = Theme.button({ Name = "GymStop", Text = "✖", TextSize = 22, BackgroundTransparency = 0.3, Parent = touchGui })
		for _, button in { big, small } do
			local corner = button:FindFirstChildOfClass("UICorner")
			if corner then
				corner.CornerRadius = UDim.new(0.5, 0)
			end
		end
		TouchLayout.place(big, "Entrenar")
		TouchLayout.showWhen(big, "Gimnasio")
		TouchLayout.place(small, "Dejar")
		TouchLayout.showWhen(small, "Gimnasio")
		big.Activated:Connect(tap)
		small.Activated:Connect(stop)
		tapButton.Text = "💪 ¡YA!"
	end

	Remote.OnClientEvent:Connect(function(action, data)
		if action == "Start" then
			onStart(data)
		elseif action == "Rep" then
			onRep(data)
		elseif action == "Set" then
			onSet(data)
		elseif action == "Effort" then
			if session then
				session.Effort = data.Effort
				refresh()
			end
		elseif action == "Tired" then
			if session then
				session.Effort = data.Effort
				say("🥵 ¡Sin fuerzas! Descansa unos segundos (no toques) y sigue", C.Error)
				refresh()
			end
		elseif action == "Stop" then
			close()
		elseif action == "Reception" then
			openReception(data)
		end
	end)
	player.CharacterRemoving:Connect(close)

	-- El marcador va y viene
	RunService.RenderStepped:Connect(function()
		local s = session
		if not s then
			return
		end
		local position = Gym.cursor(os.clock() - s.Started, s.Tempo)
		cursor.Position = UDim2.fromScale(position, 0.5)
		local inside = Gym.judge(position, s.Zone) ~= "Fallo"
		cursor.BackgroundColor3 = if inside then rgb(170, 255, 190) else rgb(255, 255, 255)
	end)
end

return GymUI
