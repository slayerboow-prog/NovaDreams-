-- LoadingGate: pantalla de carga hasta que el servidor dice que TU partida está lista.
--
-- Por qué existe (v107/v108, móvil): al entrar en un servidor que aún arrancaba (o que se había quedado
-- a medias), el jugador veía y jugaba con los valores por defecto del cliente: «Nv. 1 · 0 € · Lunes, 1
-- de enero · Día 1», el reloj parado en las 8:00, la barra rápida vacía y sin misiones. Parecía que
-- había perdido la partida. Ahora, hasta que lleguen:
--   * workspace.ServerReady  (Main.server.luau: todos los pasos del arranque hechos, con o sin errores)
--   * player.DataLoaded      (DataService: su partida cargada del DataStore)
--   * player.StoryReady      (LifeStoryService: su historia mandada; se espera como mucho STORY_WAIT s)
-- se ve «CARGANDO TU PARTIDA…» a pantalla completa. Si tarda mucho, un botón «Volver a entrar»; si el
-- servidor no puede cargarla (DataError), el motivo (y el servidor le saca para que vuelva a entrar).

local Players = game:GetService("Players")

local LoadingGate = {}

LoadingGate.STORY_WAIT = 30 -- s máx. esperando a la historia una vez cargada la partida
LoadingGate.RETRY_AFTER = 75 -- s hasta enseñar «Volver a entrar»

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local open = false
local status: TextLabel? = nil
local retry: TextButton? = nil

function LoadingGate.isOpen(): boolean
	return open
end

-- ¿Qué falta? (nil = nada: a jugar)
function LoadingGate.missing(dataSince: number?, now: number): string?
	if workspace:GetAttribute("ServerReady") ~= true then
		return "Preparando la ciudad…"
	end
	if player:GetAttribute("DataLoaded") ~= true then
		return "Cargando tu partida…"
	end
	if player:GetAttribute("StoryReady") ~= true and (dataSince == nil or now - dataSince < LoadingGate.STORY_WAIT) then
		return "Preparando tu historia…"
	end
	return nil
end

local function build(): ScreenGui
	local screen = Instance.new("ScreenGui")
	screen.Name = "LoadingGate"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 1000
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(12, 18, 32)
	back.BackgroundTransparency = 0
	back.Active = true -- (los toques no pasan a lo de debajo)
	back.Parent = screen

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.44)
	title.Size = UDim2.new(0.9, 0, 0, 48)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 214, 102)
	title.Text = "CARGANDO TU PARTIDA…"
	title.Parent = back
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 40
	cap.Parent = title

	local line = Instance.new("TextLabel")
	line.Name = "Status"
	line.AnchorPoint = Vector2.new(0.5, 0)
	line.Position = UDim2.fromScale(0.5, 0.52)
	line.Size = UDim2.new(0.9, 0, 0, 56)
	line.BackgroundTransparency = 1
	line.Font = Enum.Font.Gotham
	line.TextSize = 20
	line.TextWrapped = true
	line.TextColor3 = Color3.fromRGB(225, 232, 245)
	line.Text = "Un momento…"
	line.Parent = back
	status = line

	local button = Instance.new("TextButton")
	button.Name = "Retry"
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Position = UDim2.fromScale(0.5, 0.64)
	button.Size = UDim2.fromOffset(240, 52)
	button.BackgroundColor3 = Color3.fromRGB(30, 140, 90)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 22
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "Volver a entrar"
	button.Visible = false
	button.Parent = back
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	button.Activated:Connect(function()
		button.Text = "Entrando…"
		pcall(function()
			game:GetService("TeleportService"):Teleport(game.PlaceId, player)
		end)
	end)
	retry = button
	return screen
end

local function close()
	open = false
	if gui then
		gui:Destroy()
		gui = nil
	end
end

function LoadingGate.init()
	local started = os.clock()
	local dataSince: number? = nil
	if LoadingGate.missing(nil, started) == nil then
		return -- (ya está todo: no hace falta pantalla)
	end
	open = true
	local screen = build()
	gui = screen
	local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
	screen.Parent = playerGui
	while open do
		local now = os.clock()
		if dataSince == nil and player:GetAttribute("DataLoaded") == true then
			dataSince = now
		end
		local want = LoadingGate.missing(dataSince, now)
		if not want then
			break
		end
		local problem = player:GetAttribute("DataError")
		if status then
			status.Text = if type(problem) == "string" then problem else want
		end
		if retry and (type(problem) == "string" or now - started >= LoadingGate.RETRY_AFTER) then
			retry.Visible = true
		end
		task.wait(0.5)
	end
	close()
end

return LoadingGate
