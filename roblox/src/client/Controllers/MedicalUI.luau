-- MedicalUI (cliente): el panel del médico/a de guardia.
--   * Quién es el paciente y qué le pasa (lo que cuenta).
--   * Botones de las pruebas (temperatura, auscultar, garganta, tensión, palpar) con su resultado.
--   * Con dos pruebas o más, los diagnósticos posibles para elegir.
--   * En el botiquín, la lista de medicinas para coger la buena.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.UI.Theme)
local Dialog = require(script.Parent.Parent.UI.Dialog)

local MedicalUI = {}

local player = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Medical") :: RemoteEvent
local create = Theme.create
local C = Theme.Colors
local rgb = Color3.fromRGB

local panel: Frame
local content: Frame

local PHASE = {
	Call = "Llama al siguiente paciente en el escritorio de tu consulta.",
	Examine = "Explora al paciente junto a la camilla y elige el diagnóstico.",
	Treat = "¡Bien visto! Coge la medicina en el botiquín.",
	Apply = "Aplica el tratamiento en la camilla.",
}

local function clear()
	for _, child in content:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function line(text: string, order: number, size: number?, color: Color3?, height: number?)
	return Theme.label({
		Size = UDim2.new(1, 0, 0, height or 18),
		Text = text,
		RichText = true,
		TextSize = size or 13,
		TextWrapped = true,
		TextColor3 = color or C.Text,
		LayoutOrder = order,
		Parent = content,
	})
end

local function showCase(case: { [string]: any })
	panel.Visible = true
	clear()
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	line(("<b>🩺 Consulta %d</b> · %d esperando"):format(case.Room, case.Waiting), nextOrder(), 15)
	line(PHASE[case.Phase] or "", nextOrder(), 12, C.Muted, 30)
	if case.Patient then
		line(("👤 <b>%s</b>: «%s»"):format(case.Patient, case.Says or ""), nextOrder(), 13, rgb(255, 230, 170), 34)
	end
	if case.Phase == "Examine" then
		for _, exam in case.Exams do
			local row = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = content })
			local button = Theme.button({ Size = UDim2.new(0.42, 0, 1, -2), Text = exam.Icon .. " " .. exam.Name, TextSize = 12, Parent = row })
			Theme.label({
				Position = UDim2.new(0.44, 0, 0, 0),
				Size = UDim2.new(0.56, 0, 1, 0),
				Text = exam.Result or "—",
				TextSize = 12,
				TextWrapped = true,
				TextColor3 = if exam.Result then rgb(160, 230, 255) else C.Muted,
				Parent = row,
			})
			button.Activated:Connect(function()
				Remote:FireServer("Exam", exam.Id)
			end)
		end
		if case.Options then
			line("<b>¿Qué tiene?</b>", nextOrder(), 13)
			for _, option in case.Options do
				local b = Theme.button({ Size = UDim2.new(1, 0, 0, 28), Text = option.Name, TextSize = 13, LayoutOrder = nextOrder(), BackgroundColor3 = rgb(40, 90, 150), Parent = content })
				b.Activated:Connect(function()
					Remote:FireServer("Diagnose", option.Id)
				end)
			end
		else
			line("Haz al menos dos pruebas para diagnosticar.", nextOrder(), 12, C.Muted)
		end
	elseif case.Medicine then
		line("💊 Llevas: <b>" .. case.Medicine .. "</b>", nextOrder(), 13)
	end
	local height = 0
	for _, child in content:GetChildren() do
		if child:IsA("GuiObject") then
			height += child.Size.Y.Offset + 4
		end
	end
	panel.Size = UDim2.fromOffset(330, math.min(520, height + 20))
end

local function showMeds(list: { any })
	local window, body, close = Dialog.window("MedicalMeds", "💊 Botiquín", Vector2.new(380, 120 + #list * 38))
	local holder = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = body })
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	for i, med in list do
		local b = Theme.button({ Size = UDim2.new(1, 0, 0, 32), Text = med.Icon .. " " .. med.Name, TextSize = 14, LayoutOrder = i, Parent = holder })
		b.Activated:Connect(function()
			Remote:FireServer("Medicine", med.Id)
			window:Destroy()
		end)
	end
	close.Activated:Connect(function()
		window:Destroy()
	end)
end

function MedicalUI.init()
	local gui = create("ScreenGui", { Name = "MedicalGui", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
	panel = Theme.panel({
		Name = "Doctor",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.55, 0),
		Size = UDim2.fromOffset(330, 200),
		Visible = false,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	content = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = panel })
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	Remote.OnClientEvent:Connect(function(action, payload)
		if action == "Case" then
			showCase(payload)
		elseif action == "Meds" then
			showMeds(payload)
		elseif action == "Start" then
			panel.Visible = true
		elseif action == "Stop" then
			panel.Visible = false
			Dialog.close("MedicalMeds")
		end
	end)
	player:GetAttributeChangedSignal("Job"):Connect(function()
		if player:GetAttribute("Job") ~= "Medico" then
			panel.Visible = false
		end
	end)
end

return MedicalUI
