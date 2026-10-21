-- MerForm (cliente): lo que se ve de los Hondarios JUGADORES (la vida hondaria del modo pruebas,
-- Services/HondarioService; docs/mar/civilizacion-marina.md §6).
--
--   * La cola se mueve: a cada personaje con cola (atributo SeaForm = "Cola", World/MerBody) se le da la
--     onda en sus cuatro tramos (Motor6D.Transform), más fuerte cuanto más rápido nada. Solo los cercanos
--     (Range) y como mucho Cap a la vez: barato en el móvil.
--   * Un chip PEQUEÑO en el borde izquierdo (nunca en el centro: v125.5, el dueño veía un panel grande fijo
--     en mitad de la pantalla en tierra): «🐚 Cola» / «🐚 Piernas» y, tocándolo, «Quedarme en forma humana»
--     (lo decide el servidor: remoto Hondario "StayHuman"; también «/hondario humana» y «/hondario cola»).
--     Solo para quien vive la vida hondaria, solo unos segundos después de cambiar de forma (AutoHide,
--     en tierra y en el agua: nunca se queda fijo), y nunca en conversaciones,
--     escenas, el prólogo, vehículos o sentado (MerForm.chipVisible, puro).
-- El aire, la presión y la forma los decide el servidor; aquí solo se pinta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MerRules = require(ReplicatedStorage.Shared.Sea.MerForm)
local Theme = require(script.Parent.Parent.UI.Theme)

local MerForm = {}

local player = Players.LocalPlayer
local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB

MerForm.Range = 120
MerForm.Cap = 8

local gui: ScreenGui? = nil
local chip: TextButton? = nil
local remote: RemoteEvent? = nil
local lastForm: string? = nil
local changedAt = -math.huge

MerForm.AutoHide = 4 -- segundos que se ve el chip después de cambiar de forma (en tierra y en el agua)
MerForm.ChipSize = Vector2.new(210, 40)
MerForm.ChipPos = UDim2.new(0, 12, 0.46, 0) -- borde izquierdo, entre el estado y los botones
MerForm.QuietAttributes = { "InDialogue", "InCinematic", "InScene", "InPrologue", "Riding", "Passenger", "Seated", "Dead" }

-- El texto del chip (puro: lo prueba test-hondario)
function MerForm.hudText(form: string?, stayHuman: boolean?, district: string?): string
	local line = MerRules.label(form, stayHuman)
	if district == "Nacara" then
		return line .. " · Nácara"
	elseif district == "Burbuja" then
		return line .. " · La Burbuja"
	end
	return line
end

function MerForm.chipText(form: string?, stayHuman: boolean?): string
	if stayHuman then
		return "🧍 Forma humana · tocar: cola"
	end
	return if form == "Cola" then "🐚 Cola · tocar: forma humana" else "🐚 Piernas · tocar: forma humana"
end

function MerForm.toggleText(stayHuman: boolean?): string
	return if stayHuman then "🐚 Volver a la forma automática" else "🧍 Quedarme en forma humana"
end

-- ¿Se ve el chip? s = { Hondario, SinceChange (s), Quiet }. Solo unos segundos después de cambiar de
-- forma (al entrar o salir del agua, o al tocarlo): nunca se queda fijo, ni en tierra ni nadando.
function MerForm.chipVisible(s: { [string]: any }): boolean
	if not s.Hondario or s.Quiet then
		return false
	end
	return (s.SinceChange or math.huge) < MerForm.AutoHide
end

local function build()
	local g = create("ScreenGui", { Name = "HondarioHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Parent = player:WaitForChild("PlayerGui") })
	local c = Theme.button({ Name = "HondarioChip", AnchorPoint = Vector2.new(0, 0.5), Position = MerForm.ChipPos, Size = UDim2.fromOffset(MerForm.ChipSize.X, MerForm.ChipSize.Y), Text = "🐚", TextSize = 15, TextColor3 = rgb(170, 245, 240), BackgroundColor3 = H.Navy, BackgroundTransparency = 0.35, Visible = false, Parent = g })
	c.Activated:Connect(function()
		if remote then
			remote:FireServer("StayHuman", not (player:GetAttribute("HondarioStayHuman") == true))
		end
	end)
	gui, chip = g, c
end

local function quiet(): boolean
	for _, attr in MerForm.QuietAttributes do
		if player:GetAttribute(attr) ~= nil and player:GetAttribute(attr) ~= false then
			return true
		end
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.SeatPart ~= nil
end

local function refreshHud()
	if not chip then
		return
	end
	local on = player:GetAttribute("Hondario") == true
	local character = player.Character
	local form = (character and character:GetAttribute("SeaForm")) or "Piernas"
	local stay = player:GetAttribute("HondarioStayHuman") == true
	local key = tostring(form) .. (if stay then "+humana" else "")
	if key ~= lastForm then
		lastForm = key
		changedAt = os.clock()
	end
	local show = MerForm.chipVisible({ Hondario = on, SinceChange = os.clock() - changedAt, Quiet = on and quiet() })
	local c = chip :: TextButton
	c.Visible = show
	if show then
		c.Text = MerForm.chipText(form, stay)
	end
end

-- La onda de las colas cercanas
local function animate(t: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local camPos = camera.CFrame.Position
	local n = 0
	for _, other in Players:GetPlayers() do
		if n >= MerForm.Cap then
			break
		end
		local character = other.Character
		if character and character:GetAttribute("SeaForm") == "Cola" then
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local folder = character:FindFirstChild("MerBody")
			if root and folder and (root.Position - camPos).Magnitude < MerForm.Range then
				n += 1
				local v = root.AssemblyLinearVelocity
				local speed = Vector3.new(v.X, 0, v.Z).Magnitude
				for i = 1, 4 do
					local seg = folder:FindFirstChild("Cola" .. i)
					local motor = seg and seg:FindFirstChild("ColaJunta" .. i)
					if motor and motor:IsA("Motor6D") then
						motor.Transform = CFrame.Angles(MerRules.tailWave(t, i, speed), 0, 0)
					end
				end
			end
		end
	end
end

function MerForm.init()
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Hondario", 30) :: RemoteEvent?
	build()
	for _, attr in { "Hondario", "HondarioStayHuman" } do
		player:GetAttributeChangedSignal(attr):Connect(refreshHud)
	end
	local clock, since = 0, 0
	RunService.RenderStepped:Connect(function(dt)
		clock += math.min(dt, 0.1)
		since += dt
		local ok, err = pcall(animate, clock)
		if not ok then
			warn("[MerForm] " .. tostring(err))
		end
		if since > 0.3 then
			since = 0
			pcall(refreshHud)
		end
	end)
	refreshHud()
	local _ = gui
end

return MerForm
