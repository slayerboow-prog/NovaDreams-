-- DebugHud (cliente): panel de depuración del dueño del juego.
--   * F8 (o /debug hud en el chat) lo enseña o lo esconde.
--   * Enseña lo que manda el servidor cada segundo: misión, objetivo y paso, resumen de la vida,
--     etapa y edad, dónde estás, los personajes de alrededor (qué hacen, adónde van, si hablan
--     contigo), la conversación en curso y los últimos avisos del registro.
--   * Las respuestas de los comandos /debug salen aquí y en la consola (F9).
-- El permiso lo decide SIEMPRE el servidor (DebugService): a un jugador normal nunca le llegan
-- datos, así que aunque tuviera este panel no vería nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.UI.Theme)

local DebugHud = {}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local body: TextLabel? = nil
local lastText: { string } = {}

local function build()
	if gui then
		return
	end
	gui = Theme.create("ScreenGui", {
		Name = "DebugHud",
		ResetOnSpawn = false,
		DisplayOrder = 50,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local panel = Theme.create("Frame", {
		Position = UDim2.fromOffset(8, 60),
		Size = UDim2.new(0, 460, 0.8, 0),
		BackgroundColor3 = Color3.fromRGB(10, 12, 18),
		BackgroundTransparency = 0.25,
		Parent = gui,
	})
	Theme.padding(8).Parent = panel
	body = Theme.create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(220, 235, 220),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		RichText = false,
		Text = "",
		Parent = panel,
	})
end

local function section(out: { string }, title: string, lines: { string }?)
	table.insert(out, "── " .. title)
	for _, line in lines or {} do
		table.insert(out, line)
	end
end

local function render(payload: { [string]: any })
	build()
	local out = {}
	section(out, "MISIÓN", payload.Mission)
	section(out, "VIDA", payload.Story)
	section(out, "DÓNDE", { payload.Location })
	section(out, "CONVERSACIÓN", { payload.Dialogue })
	section(out, "PERSONAJES CERCA", payload.Npcs)
	section(out, "REGISTRO", payload.Log)
	if #lastText > 0 then
		section(out, "ÚLTIMO COMANDO", lastText)
	end
	if body then
		body.Text = table.concat(out, "\n")
	end
end

function DebugHud.init()
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Debug", 30) :: RemoteEvent?
	if not remote then
		return
	end
	remote.OnClientEvent:Connect(function(kind: string, payload: any)
		if kind == "Text" and type(payload) == "table" then
			lastText = payload.Lines or {}
			for _, line in lastText do
				print("[DEBUG] " .. tostring(line))
			end
		elseif kind == "Hud" then
			build()
			if gui then
				gui.Enabled = payload ~= false
			end
			if type(payload) == "table" then
				render(payload)
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.F8 then
			return
		end
		if player:GetAttribute("DebugAllowed") then
			remote:FireServer("Command", "/debug hud")
		end
	end)
end

return DebugHud
