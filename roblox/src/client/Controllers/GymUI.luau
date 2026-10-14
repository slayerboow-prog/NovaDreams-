-- GymUI (cliente): el gimnasio.
--   * Recepción: entrada del día o abono mensual, lo que te queda y cómo vas de Fuerza y Forma.
--   * Entrenando: técnica de verdad. Cada repetición es MANTENER «Empujar» (Espacio, o A en el mando)
--     mientras sube la barra del recorrido y SOLTAR en la zona verde del final: antes es una
--     repetición a medias y pasarse es un tirón (fallo; cansa un poco). En el centro de la zona,
--     "¡Perfecto!" (sube más). Mientras empujas, la aguja de la postura se va de lado: corrígela con
--     A/D, las flechas o el joystick (con la espalda torcida no cuenta). El ritmo lo marca la máquina:
--     no se puede encadenar sin bajar el peso. La barra naranja es el esfuerzo: cada repetición gasta
--     y descansando se recupera. Cada serie completa sube la Fuerza o la Forma física. "Dejar" (Q o B).
--   * Móvil: «Empujar» (mantener) va en el hueco del Ataque y «Dejar» en el de Esquivar.

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
local Joystick = require(script.Parent.Joystick)

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
	HoldStart: number?, -- empujando desde este instante (nil = soltado)
	Fill: number, -- recorrido de la repetición (0..1, y más si te pasas)
	Balance: number, -- postura (-1..1; 0 = recto)
	Drift: number, -- hacia dónde se va el cuerpo en esta repetición
}
local session: Session? = nil

local panel: Frame
local title: TextLabel
local feedback: TextLabel
local stats: TextLabel
local zone: Frame
local cursor: Frame
local liftFill: Frame
local balanceNeedle: Frame
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

local rng = Random.new()

-- Empezar a empujar
local function press()
	local s = session
	if not s or s.HoldStart then
		return
	end
	s.HoldStart = os.clock()
	s.Fill = 0
	-- El cuerpo se va hacia un lado (más en las máquinas difíciles, las de zona estrecha)
	s.Drift = (if rng:NextNumber() < 0.5 then -1 else 1) * (0.3 + (1 - math.clamp(s.Zone / 0.4, 0, 1)) * 0.55)
end

-- Soltar: se juzga la repetición
local function release()
	local s = session
	if not s or not s.HoldStart then
		return
	end
	local now = os.clock()
	local fill = Gym.liftFill(now - (s.HoldStart :: number), s.Tempo)
	s.HoldStart = nil
	s.Fill = 0
	if fill < 0.15 then
		return -- (un toque sin querer: no cuenta)
	end
	if now - s.LastTap < Gym.minRepGap(s.Kind) then
		say("¡Más despacio! Baja el peso con control", C.Muted)
		return
	end
	s.LastTap = now
	local verdict, why = Gym.liftJudge(fill, s.Zone, s.Balance)
	if verdict == "Fallo" then
		say(if why == "Postura" then "✖ ¡La espalda torcida! Corrige la postura (A/D o el joystick)"
			elseif why == "Tiron" then "✖ ¡Tirón! Te has pasado: suelta en la zona verde"
			else "✖ ¡A medias! Empuja hasta la zona verde antes de soltar", C.Error)
		Remote:FireServer("Miss")
		return
	end
	Remote:FireServer("Rep", verdict)
	if why == "Postura" then
		say("✔ Vale, pero con la postura un poco torcida", GREEN)
	end
end

-- (compatibilidad) un toque suelto: empuja o suelta
local function tap()
	local s = session
	if s and s.HoldStart then
		release()
	else
		press()
	end
end

local function stop()
	if session then
		Remote:FireServer("Stop")
	end
end

local function close()
	session = nil
	panel.Visible = false
	TouchLayout.refresh()
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
		HoldStart = nil,
		Fill = 0,
		Balance = 0,
		Drift = 0,
	}
	panel.Visible = true
	TouchLayout.refresh()
	local from, to = Gym.liftZone(data.Zone)
	zone.Position = UDim2.fromScale(from / 1.2, 0)
	zone.Size = UDim2.fromScale((to - from) / 1.2, 1)
	say(("Mantén «Empujar» y suelta en la zona verde, con la postura recta · %s"):format(if data.Stat == "Cardio" then "sube tu Forma física" elseif data.Stat == "Mixto" then "Fuerza y Forma física" else "sube tu Fuerza"), C.Text)
	refresh()
	-- Espacio / A / R2: repetición.  Q / B: dejar la máquina. (Por encima de saltar)
	ContextActionService:BindActionAtPriority("GymTap", function(_, state)
		if state == Enum.UserInputState.Begin then
			press()
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			release()
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
	-- Pesas de verdad (barra, discos, mancuernas): el hierro que choca al acabar la repetición
	local IRON = { PressBanca = true, PressHombros = true, Prensa = true, Sentadilla = true, Mancuernas = true, Jalon = true }
	if IRON[s.Kind] then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		pcall(SoundFx.play, "PesasGolpe", { Volume = if data.Quality == "Perfecto" then 1 else 0.75, At = root })
	end
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
		Text = "En cada máquina, «Entrenar». Mantén «Empujar» (Espacio) y suelta en la zona verde del final, con la postura recta (A/D). Cada serie te hace más fuerte (y se nota en el cuerpo) o mejora tu forma física. Los niños pagan la mitad y usan las máquinas ligeras (cardio, esterillas, comba y saco).",
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
		Size = UDim2.fromOffset(500, 196),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(10).Parent = panel
	title = Theme.label({ Size = UDim2.new(1, 0, 0, 22), Text = "", Font = Theme.FontBold, TextSize = 17, Parent = panel })
	stats = Theme.label({ Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 16), Text = "", TextSize = 12, TextColor3 = C.Muted, Parent = panel })
	-- Barra del recorrido (0..1.2): se llena mientras empujas; la zona verde está al final
	local track = create("Frame", { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = rgb(10, 16, 30), BorderSizePixel = 0, Parent = panel }, { Theme.corner(6) })
	liftFill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = rgb(90, 120, 200), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = track }, { Theme.corner(6) })
	zone = create("Frame", { Position = UDim2.fromScale(0.6, 0), Size = UDim2.fromScale(0.2, 1), BackgroundColor3 = GREEN, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = track }, { Theme.corner(6) })
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundColor3 = rgb(120, 255, 150), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = zone }, { Theme.corner(6) })
	cursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 6, 1, 8), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, Parent = track }, { Theme.corner(3) })
	-- Postura: la aguja tiene que quedarse en el centro
	Theme.label({ Position = UDim2.fromOffset(0, 162), Size = UDim2.fromOffset(90, 14), Text = "🧍 Postura", TextSize = 12, TextColor3 = C.Muted, Parent = panel })
	local balanceTrack = create("Frame", { Position = UDim2.fromOffset(92, 163), Size = UDim2.new(1, -92, 0, 12), BackgroundColor3 = rgb(70, 30, 30), BorderSizePixel = 0, Parent = panel }, { Theme.corner(6) })
	create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.35, 1), BackgroundColor3 = GREEN, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = balanceTrack }, { Theme.corner(6) })
	balanceNeedle = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 6, 1, 6), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, Parent = balanceTrack }, { Theme.corner(3) })
	-- Esfuerzo
	Theme.label({ Position = UDim2.fromOffset(0, 70), Size = UDim2.fromOffset(90, 14), Text = "🥵 Esfuerzo", TextSize = 12, TextColor3 = C.Muted, Parent = panel })
	local effort = create("Frame", { Position = UDim2.fromOffset(92, 73), Size = UDim2.new(1, -92, 0, 8), BackgroundColor3 = rgb(10, 16, 30), BorderSizePixel = 0, Parent = panel }, { Theme.corner(4) })
	effortFill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = ORANGE, BorderSizePixel = 0, Parent = effort }, { Theme.corner(4) })
	feedback = Theme.label({ Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 0, 20), Text = "", TextSize = 14, TextWrapped = true, Parent = panel })
	-- (en el móvil no hay teclas: el texto va sin «(espacio)» ni «(Q)»)
	tapButton = Theme.button({ Position = UDim2.fromOffset(0, 110), Size = UDim2.new(0.7, 0, 0, 44), Text = if Theme.isTouch() then "💪 Empujar" else "💪 Empujar  (mantén Espacio)", TextSize = 20, BackgroundColor3 = rgb(200, 90, 30), Parent = panel })
	tapButton.MouseButton1Down:Connect(press)
	tapButton.MouseButton1Up:Connect(release)
	tapButton.MouseLeave:Connect(release)
	local _ = tap
	local stopButton = Theme.button({ Position = UDim2.new(0.72, 0, 0, 110), Size = UDim2.new(0.28, 0, 0, 44), Text = if Theme.isTouch() then "Dejar" else "Dejar (Q)", TextSize = 15, BackgroundColor3 = rgb(50, 52, 60), Parent = panel })
	stopButton.Activated:Connect(stop)

	-- Botones de acción (móvil: racimo de abajo a la derecha; ordenador y mando: pistas de teclas).
	-- Entrenando, "Empujar" (mantener) ocupa el hueco del Ataque y "Dejar" el de Esquivar (Priority más baja: ganan).
	local function training(): boolean
		return session ~= nil
	end
	TouchLayout.register({
		Id = "GymYa",
		Icon = "corazon",
		Label = "Empujar",
		Slot = "Ataque",
		Priority = 1,
		Key = "Espacio",
		Pad = "A",
		Visible = training,
		Callback = function() end,
		Hold = function(down: boolean)
			if down then
				press()
			else
				release()
			end
		end,
		Meter = function()
			local s = session
			return if s and s.HoldStart then math.clamp(s.Fill, 0, 1) else nil
		end,
	})
	TouchLayout.register({ Id = "GymDejar", Icon = "bajarse", Label = "Dejar", Slot = "Esquivar", Priority = 1, Key = "Q", Pad = "B", Visible = training, Callback = stop })
	if UserInputService.TouchEnabled then
		tapButton.Text = "💪 Empujar"
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

	-- Lo que pide el jugador para enderezarse (-1..1): A/D, flechas, joystick o stick del mando
	local function balanceInput(): number
		local x = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
			x -= 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
			x += 1
		end
		local ok, v = pcall(Joystick.moveVector)
		if ok and typeof(v) == "Vector3" and math.abs(v.X) > 0.15 then
			x += v.X
		end
		pcall(function()
			for _, state in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
				if state.KeyCode == Enum.KeyCode.Thumbstick1 and math.abs(state.Position.X) > 0.2 then
					x += state.Position.X
				end
			end
		end)
		return math.clamp(x, -1, 1)
	end

	-- El recorrido sube mientras empujas; la postura se tuerce y hay que corregirla
	RunService.RenderStepped:Connect(function(dt)
		local s = session
		if not s then
			return
		end
		if s.HoldStart then
			s.Fill = Gym.liftFill(os.clock() - (s.HoldStart :: number), s.Tempo)
			s.Balance = Gym.balanceStep(s.Balance, s.Drift, balanceInput(), dt)
			if s.Fill >= 1.15 then
				release() -- (te has pasado del todo: se suelta solo y es un tirón)
			end
		else
			s.Balance *= math.max(0, 1 - dt * 3) -- sin peso, el cuerpo vuelve a su sitio
		end
		local from, to = Gym.liftZone(s.Zone)
		liftFill.Size = UDim2.fromScale(math.clamp(s.Fill / 1.2, 0, 1), 1)
		cursor.Position = UDim2.fromScale(math.clamp(s.Fill / 1.2, 0, 1), 0.5)
		local inside = s.Fill >= from and s.Fill <= to + 0.08
		cursor.BackgroundColor3 = if inside then rgb(170, 255, 190) else rgb(255, 255, 255)
		balanceNeedle.Position = UDim2.fromScale(0.5 + s.Balance * 0.5, 0.5)
		balanceNeedle.BackgroundColor3 = if math.abs(s.Balance) < 0.35 then rgb(170, 255, 190) elseif math.abs(s.Balance) > 0.9 then rgb(255, 90, 80) else rgb(255, 220, 120)
	end)
end

return GymUI
