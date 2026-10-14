-- RaceClient (cliente): las carreras de verdad en tu pantalla (RaceService lleva la carrera).
--
-- CONTROLES: «Izq» y «Der» alternando, lo más rápido que puedas (en el ordenador, las flechas o A/D;
-- en el mando, LB/RB). Repetir el mismo pie te hace trastabillar. A tope se gasta el aliento (la barra).
-- Antes del «¡YA!» no pulses: salida nula. En el relevo, «Testigo» cuando tu compañero llega a la zona
-- amarilla. Mientras corres, el personaje va recto por su calle (el joystick no hace falta).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.UI.Theme)
local TouchLayout = require(script.Parent.Parent.UI.TouchLayout)
local TopStack = require(script.Parent.Parent.UI.TopStack)
local SportInput = require(script.Parent.SportInput)
local Track = require(ReplicatedStorage.Shared.Sports.Track)

local RaceClient = {}

local player = Players.LocalPlayer
local create = Theme.create
local rgb = Color3.fromRGB

local remote: RemoteEvent? = nil
local race: { [string]: any }? = nil
local stride = Track.newStride()
local phase = "Idle"
local running = false
local sentGo = false
local savedSpeed: number? = nil

local gui: ScreenGui
local board: Frame
local title: TextLabel
local info: TextLabel
local banner: TextLabel
local staminaBar: Frame
local bannerToken = 0

local function humanoid(): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function showBanner(text: string, color: Color3?, seconds: number?)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	TopStack.set(banner, true)
	Theme.pop(banner, 0.1)
	task.delay(seconds or 1.2, function()
		if bannerToken == token then
			TopStack.set(banner, false)
		end
	end)
end

local function build()
	gui = create("ScreenGui", { Name = "CarreraGui", ResetOnSpawn = false, DisplayOrder = 6, IgnoreGuiInset = true, Parent = player:WaitForChild("PlayerGui") })
	board = Theme.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 84), Size = UDim2.fromOffset(380, 78), Visible = false, Parent = gui })
	TopStack.register(board, TopStack.Priority.Mission, { Id = "Carreraboard" }) -- (arriba en el centro, sin pisar nada; nada en las escenas)
	title = Theme.label({ Size = UDim2.new(1, 0, 0, 28), Font = Theme.FontBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Parent = board })
	info = Theme.label({ Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 22), TextSize = 14, TextWrapped = true, TextColor3 = Theme.Colors.Gold, TextXAlignment = Enum.TextXAlignment.Center, Parent = board })
	local bar = create("Frame", { Position = UDim2.new(0.1, 0, 0, 56), Size = UDim2.new(0.8, 0, 0, 10), BackgroundColor3 = rgb(15, 20, 32), BorderSizePixel = 0, Parent = board }, { Theme.corner(5) })
	staminaBar = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(90, 220, 120), BorderSizePixel = 0, Parent = bar }, { Theme.corner(5) })
	banner = Theme.label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromOffset(600, 64), Font = Theme.FontBold, TextSize = 48, TextStrokeTransparency = 0.3, TextXAlignment = Enum.TextXAlignment.Center, Visible = false, Parent = gui })
	TopStack.register(banner, TopStack.Priority.Mission, { Id = "Carrerabanner" }) -- (arriba en el centro, sin pisar nada; nada en las escenas)
end

local function myRunner(): { [string]: any }?
	return race and race.Roster[race.You]
end

local function laneDirection(): Vector3
	local r = myRunner()
	local dir = if race and race.Mode == "Relevo" and r and r.Leg % 2 == 0 then -1 else 1
	local cf = race and race.Track.CFrame or CFrame.new()
	return cf:VectorToWorldSpace(Vector3.new(dir, 0, 0))
end

-- La velocidad buena al acabar: la que dice el servidor (WalkTarget, NeedsService); si no, la de antes.
-- (La guardada podía ser la de ir corriendo o la de una carrera a medias: nunca se deja pisada.)
local function restoreSpeed()
	local h = humanoid()
	local target = player:GetAttribute("WalkTarget")
	if h then
		if type(target) == "number" and target > 0 then
			h.WalkSpeed = target
		elseif savedSpeed then
			h.WalkSpeed = savedSpeed
		end
	end
end

local function lockFeet(on: boolean)
	local h = humanoid()
	if not h then
		return
	end
	if on then
		savedSpeed = savedSpeed or h.WalkSpeed
		h.WalkSpeed = 0
	else
		restoreSpeed()
	end
end

local function finish()
	if race then
		race = nil
	end
	running = false
	sentGo = false
	phase = "Idle"
	TopStack.set(board, false)
	TouchLayout.setSport(false)
	TouchLayout.refresh()
	lockFeet(false)
	savedSpeed = nil
	-- (Controllers/Character ya puede vigilar la velocidad otra vez)
	player:SetAttribute("SpeedLock", nil)
end

local function tap(foot: string)
	if not race or not remote then
		return
	end
	if not running then
		-- Antes del disparo (o esperando el testigo): pulsar es salir
		if not sentGo and (phase == "Marks" or phase == "Set" or phase == "Run") then
			local r = myRunner()
			if r and (race.Mode ~= "Relevo" or r.Active) then
				sentGo = true
				remote:FireServer("Go")
			end
		end
		return
	end
	Track.tap(stride, foot, os.clock())
end

local function onEvent(e: { [string]: any })
	if not race then
		return
	end
	local kind = e.Kind
	if kind == "Marks" then
		phase = "Marks"
		running, sentGo = false, false
		stride = Track.newStride()
		lockFeet(true)
		showBanner("Preparados…", rgb(255, 255, 255), 1.4)
	elseif kind == "Set" then
		phase = "Set"
		showBanner("Listos…", rgb(255, 220, 90), 3)
	elseif kind == "Gun" then
		phase = "Run"
		showBanner("¡YA!", rgb(120, 240, 140), 0.8)
		pcall(function()
			require(script.Parent.SoundFx).play("PistolaSalida")
		end)
	elseif kind == "Go" and e.Id == race.You then
		running = true
		lockFeet(false)
		info.Text = ("Reacción: %.2f s"):format(e.Reaction or 0)
	elseif kind == "FalseStart" then
		showBanner(if e.Out then "Descalificado" else "¡Salida nula!", rgb(255, 120, 110), 1.6)
	elseif kind == "Exchange" then
		local r = race.Roster[e.To]
		if r then
			r.Active = true
		end
		if e.To == race.You then
			running = true
			stride = Track.newStride()
			lockFeet(false)
			showBanner(if e.Dropped then "¡Se te ha caído el testigo!" else "¡Testigo! ¡Corre!", if e.Dropped then rgb(255, 160, 110) else rgb(120, 240, 140), 1.2)
		end
	elseif kind == "Finish" then
		if e.Id == race.You or (race.Mode == "Relevo" and e.Team == 1 and e.Place) then
			if e.Id == race.You or race.Mode == "Relevo" then
				showBanner(("%dº · %.2f s"):format(e.Place, e.Time or 0), Theme.Colors.Gold, 2)
				running = false
			end
		end
	elseif kind == "Over" then
		running = false
		info.Text = if e.Disqualified then "Descalificado" elseif e.Place then ("Has llegado %dº de %d"):format(e.Place, e.Of or 0) else "Fin"
	end
end

local botX: { [string]: number } = {}

local orphanFor = 0
local function step(dt: number)
	if not race then
		orphanFor = 0
		return
	end
	-- Vigilante: el servidor ya no te tiene en una carrera (InSport) y el «End» no llegó: se cierra
	-- aquí también, para que la zancada no se quede mandando en tu velocidad
	if player:GetAttribute("InSport") ~= "Carrera" then
		orphanFor += dt
		if orphanFor > 3 then
			orphanFor = 0
			finish()
			return
		end
	else
		orphanFor = 0
	end
	local h = humanoid()
	-- Tu zancada
	if running and h then
		local speed = Track.stepStride(stride, os.clock(), dt, race.SpeedScale or 1, race.Water == true)
		h.WalkSpeed = math.max(speed, 0.01)
		h:Move(laneDirection(), false)
		staminaBar.Size = UDim2.fromScale(math.clamp(stride.Stamina, 0, 1), 1)
		staminaBar.BackgroundColor3 = if stride.Stamina < 0.25 then rgb(240, 90, 70) else rgb(90, 220, 120)
	elseif h and (phase == "Marks" or phase == "Set") then
		h:Move(Vector3.zero, false)
	end
	-- Las máquinas: suaves hacia donde dice el servidor
	local t = race.Track
	for id, r in race.Roster do
		if r.Human or not r.Model or not r.Model.PrimaryPart then
			continue
		end
		local target = r.TargetX or 0
		local x = botX[id] or target
		x += (target - x) * math.min(1, dt * 10)
		botX[id] = x
		local dir = if race.Mode == "Relevo" and r.Leg % 2 == 0 then -1 else 1
		local along = if dir > 0 then x else t.Length - x
		local laneZ = (r.Lane - (t.Lanes + 1) / 2) * t.LaneWidth
		local feet = t.CFrame:PointToWorldSpace(Vector3.new(along, 0, laneZ))
		local up = (r.Model:GetAttribute("FootOffset") :: number?) or 3
		if race.Water then
			-- Nadando: tumbado a ras de agua, con un vaivén de brazada
			local at = feet + Vector3.new(0, 0.1 + math.sin(os.clock() * 8 + r.Lane) * 0.15, 0)
			r.Model.PrimaryPart.CFrame = CFrame.lookAt(at, at + t.CFrame:VectorToWorldSpace(Vector3.new(dir, 0, 0))) * CFrame.Angles(-math.pi / 2, 0, math.sin(os.clock() * 8 + r.Lane) * 0.3)
		else
			local at = feet + Vector3.new(0, up, 0)
			r.Model.PrimaryPart.CFrame = CFrame.lookAt(at, at + t.CFrame:VectorToWorldSpace(Vector3.new(dir, 0, 0)))
		end
	end
end

local function inRace(): boolean
	return race ~= nil
end

function RaceClient.init()
	build()
	remote = SportInput.remote("Carrera") :: RemoteEvent?
	local stateRemote: any = SportInput.remote("CarreraState")
	if not remote then
		return
	end
	remote.OnClientEvent:Connect(function(kind: string, data: any)
		local ok, err = pcall(function()
			if kind == "Session" then
				race = data
				for _, id in data.Order do
					local r = data.Roster[id]
					r.Active = data.Mode ~= "Relevo" or r.Leg == 1
				end
				botX = {}
				TopStack.set(board, true)
				title.Text = ("%s %s"):format(data.Icon or "🏃", data.Title or "Carrera")
				info.Text = if data.Water then "Alterna «Izq» y «Der» (brazadas) y «Respirar» cada pocas brazadas" elseif data.Mode == "Relevo" then "Corres la última posta: «Testigo» cuando llegue tu compañero" else "Alterna «Izq» y «Der» muy rápido. ¡No salgas antes del disparo!"
				TouchLayout.setSport(true)
				TouchLayout.refresh()
				-- En carrera la velocidad la lleva la zancada (no el vigilante de Controllers/Character)
				player:SetAttribute("SpeedLock", true)
			elseif kind == "Event" then
				onEvent(data)
			elseif kind == "End" then
				finish()
			elseif kind == "Error" then
				showBanner(data.Text or "", rgb(255, 200, 120), 2.5)
			end
		end)
		if not ok then
			warn("[Carrera] " .. tostring(err))
		end
	end)
	if stateRemote then
		(stateRemote :: any).OnClientEvent:Connect(function(snap)
			if race and type(snap) == "table" then
				phase = snap.Ph or phase
				for i, row in snap.P do
					local id = race.Order[i]
					local r = id and race.Roster[id]
					if r then
						r.TargetX = row[1]
						r.Active = row[2]
					end
				end
			end
		end)
	end
	TouchLayout.register({ Id = "CarIzq", Icon = "izquierda", Label = "Izq", SportSlot = "Defender", Priority = 1, Key = "←", Pad = "LB", Visible = inRace, Callback = function()
		tap("L")
	end })
	TouchLayout.register({ Id = "CarDer", Icon = "derecha", Label = "Der", SportSlot = "Ataque", Priority = 1, Key = "→", Pad = "RB", Visible = inRace, Callback = function()
		tap("R")
	end })
	TouchLayout.register({ Id = "CarTestigo", Icon = "interactuar", Label = "Testigo", SportSlot = "Esquivar", Priority = 1, Key = "Espacio", Pad = "A",
		Visible = function(): boolean
			return race ~= nil and race.Mode == "Relevo"
		end,
		Callback = function()
			if remote and race then
				remote:FireServer("Take")
			end
		end,
	})
	-- Nadando: respirar cada pocas brazadas (el botón se enciende cuando te falta el aire)
	TouchLayout.register({ Id = "CarRespirar", Icon = "nube", Label = "Respirar", SportSlot = "Esquivar", Priority = 1, Key = "Espacio", Pad = "A",
		Visible = function(): boolean
			return race ~= nil and race.Water == true
		end,
		Active = function(): boolean
			return race ~= nil and Track.needsAir(stride)
		end,
		Callback = function()
			Track.breathe(stride, os.clock())
		end,
	})
	-- Fuera de una carrera: «Carrera» en el agua (natación)
	TouchLayout.register({ Id = "CarNadar", Icon = "correr", Label = "Carrera", Priority = 10,
		Visible = function(): boolean
			return race == nil and player:GetAttribute("SwimMode") ~= nil and player:GetAttribute("InSport") == nil
		end,
		Callback = function()
			if remote then
				remote:FireServer("Pickup", { Kind = "Natacion" })
			end
		end,
	})
	ContextActionService:BindActionAtPriority("CarreraInput", function(_, state, input)
		if not race or state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		local k = input.KeyCode
		if k == Enum.KeyCode.Left or k == Enum.KeyCode.A or k == Enum.KeyCode.ButtonL1 then
			tap("L")
		elseif k == Enum.KeyCode.Right or k == Enum.KeyCode.D or k == Enum.KeyCode.ButtonR1 then
			tap("R")
		elseif k == Enum.KeyCode.Space or k == Enum.KeyCode.ButtonA then
			if race.Mode == "Relevo" and remote then
				remote:FireServer("Take")
			elseif race.Water then
				Track.breathe(stride, os.clock())
			else
				return Enum.ContextActionResult.Pass
			end
		else
			return Enum.ContextActionResult.Pass
		end
		return Enum.ContextActionResult.Sink
	end, false, 3200, Enum.KeyCode.Left, Enum.KeyCode.A, Enum.KeyCode.ButtonL1, Enum.KeyCode.Right, Enum.KeyCode.D, Enum.KeyCode.ButtonR1, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	RunService:BindToRenderStep("CarreraMove", Enum.RenderPriority.Input.Value + 1, function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[Carrera] " .. tostring(err))
		end
	end)
	player.CharacterAdded:Connect(function()
		savedSpeed = nil
		-- Personaje nuevo a mitad de carrera: la carrera de esta pantalla se acaba (el servidor la cierra)
		if race then
			pcall(finish)
		end
		player:SetAttribute("SpeedLock", nil)
	end)
end

return RaceClient
