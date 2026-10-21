-- MerForm (cliente): lo que se ve de los Hondarios JUGADORES (la vida hondaria del modo pruebas,
-- Services/HondarioService; docs/mar/civilizacion-marina.md §6).
--
--   * La cola se mueve: a cada personaje con cola (atributo SeaForm = "Cola", World/MerBody) se le da la
--     onda en sus cuatro tramos (Motor6D.Transform), más fuerte cuanto más rápido nada. Solo los cercanos
--     (Range) y como mucho Cap a la vez: barato en el móvil.
--   * Tu identidad en el HUD: un letrero arriba (TopStack, prioridad «World»: deja paso a la historia) con
--     «🐚 Hondario · forma de cola» (o «piernas en tierra»), tu barrio (Nácara, La Burbuja) y el botón
--     «🧍 Quedarme en forma humana» (lo decide el servidor: remoto Hondario "StayHuman").
-- El aire, la presión y la forma los decide el servidor; aquí solo se pinta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MerRules = require(ReplicatedStorage.Shared.Sea.MerForm)
local Theme = require(script.Parent.Parent.UI.Theme)
local TopStack = require(script.Parent.Parent.UI.TopStack)

local MerForm = {}

local player = Players.LocalPlayer
local create = Theme.create
local H = Theme.Hud
local rgb = Color3.fromRGB

MerForm.Range = 120
MerForm.Cap = 8

local gui: ScreenGui? = nil
local pill: Frame? = nil
local title: TextLabel? = nil
local toggle: TextButton? = nil
local remote: RemoteEvent? = nil

-- El texto del letrero (puro: lo prueba test-hondario)
function MerForm.hudText(form: string?, stayHuman: boolean?, district: string?): string
	local line = MerRules.label(form, stayHuman)
	if district == "Nacara" then
		return line .. " · Nácara"
	elseif district == "Burbuja" then
		return line .. " · La Burbuja"
	end
	return line
end

function MerForm.toggleText(stayHuman: boolean?): string
	return if stayHuman then "🐚 Volver a la forma automática" else "🧍 Quedarme en forma humana"
end

local function build()
	local g = create("ScreenGui", { Name = "HondarioHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2, Parent = player:WaitForChild("PlayerGui") })
	local p = Theme.hudPanel({ Name = "HondarioPill", Size = UDim2.fromOffset(330, 84), BackgroundColor3 = H.Navy, BackgroundTransparency = 0.25, CornerRadius = 16, Visible = false, Parent = g })
	title = create("TextLabel", { Name = "Title", Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(306, 26), BackgroundTransparency = 1, Font = Theme.FontBold, TextSize = 19, TextColor3 = rgb(160, 245, 240), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = "🐚 Hondario", Parent = p })
	toggle = Theme.button({ Name = "StayHuman", Position = UDim2.fromOffset(12, 36), Size = UDim2.fromOffset(306, 42), Text = MerForm.toggleText(false), TextSize = 17, Parent = p })
	;(toggle :: TextButton).Activated:Connect(function()
		if remote then
			remote:FireServer("StayHuman", not (player:GetAttribute("HondarioStayHuman") == true))
		end
	end)
	TopStack.register(p, TopStack.Priority.World, { Id = "HondarioPill" })
	gui, pill = g, p
end

local function refreshHud()
	if not pill then
		return
	end
	local on = player:GetAttribute("Hondario") == true
	-- Parche v125.6: el panel se quedaba fijo en pantalla; queda oculto (la forma se cambia desde /pruebas)
	TopStack.set(pill, false)
	if not on then
		return
	end
	local character = player.Character
	local form = character and character:GetAttribute("SeaForm") or "Piernas"
	local stay = player:GetAttribute("HondarioStayHuman") == true
	;(title :: TextLabel).Text = MerForm.hudText(form, stay, player:GetAttribute("HondarioSafe"))
	;(toggle :: TextButton).Text = MerForm.toggleText(stay)
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
	for _, attr in { "Hondario", "HondarioStayHuman", "HondarioSafe" } do
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
