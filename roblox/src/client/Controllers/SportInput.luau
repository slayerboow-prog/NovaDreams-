-- SportInput (cliente): lo que comparten los controles de los deportes en el ordenador.
--
--   SportInput.onButton(input)  ¿este clic ha caído encima de un botón de la interfaz? (entonces es
--                                para el botón, no un chute/tiro: antes, al tocar «Partido 3 contra 3»
--                                del menú mientras cargabas, salía un tiro flojo)
--   SportInput.remote(name)     el remoto de un deporte, esperando lo que haga falta. Antes cada
--                                deporte esperaba 60 s y, si no llegaba, se rendía para siempre: en
--                                un servidor recién abierto (versión nueva publicada: todos pasan a
--                                uno nuevo) el servidor tarda más en arrancar sus servicios y el
--                                cliente se quedaba sin botón «Jugar» ni controles de deporte.
--   SportInput.watchPrompts()   los carteles «Jugar» de las pistas (World/SportPrompts) se apagan en
--                                tu pantalla mientras juegas a algo (atributos InSport / InMiniGame)

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SportInput = {}

function SportInput.onButton(input: InputObject): boolean
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return false
	end
	local gui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return false
	end
	local ok, found = pcall(function()
		local inset = GuiService:GetGuiInset()
		for _, offset in { Vector2.zero, inset } do
			local p = Vector2.new(input.Position.X, input.Position.Y) + offset
			for _, object in gui:GetGuiObjectsAtPosition(p.X, p.Y) do
				if object:IsA("GuiButton") and object.Visible and object.Active then
					return true
				end
			end
		end
		return false
	end)
	return ok and found == true
end

function SportInput.remote(name: string): Instance
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local found = remotes:FindFirstChild(name)
	while not found do
		found = remotes:WaitForChild(name, 30)
	end
	return found :: Instance
end

SportInput.PROMPT_TAG = "SportPrompt" -- (el mismo que World/SportPrompts en el servidor)

local watching = false
function SportInput.watchPrompts()
	if watching then
		return
	end
	watching = true
	local player = Players.LocalPlayer
	local function busy(): boolean
		return player:GetAttribute("InSport") ~= nil or player:GetAttribute("InMiniGame") ~= nil
	end
	local function apply(prompt: Instance)
		if prompt:IsA("ProximityPrompt") then
			prompt.Enabled = not busy() and prompt:GetAttribute("Off") ~= true
		end
	end
	local function applyAll()
		for _, prompt in CollectionService:GetTagged(SportInput.PROMPT_TAG) do
			pcall(apply, prompt)
		end
	end
	CollectionService:GetInstanceAddedSignal(SportInput.PROMPT_TAG):Connect(function(prompt)
		pcall(apply, prompt)
		pcall(function()
			prompt:GetAttributeChangedSignal("Off"):Connect(function()
				pcall(apply, prompt)
			end)
		end)
	end)
	for _, prompt in CollectionService:GetTagged(SportInput.PROMPT_TAG) do
		pcall(function()
			prompt:GetAttributeChangedSignal("Off"):Connect(function()
				pcall(apply, prompt)
			end)
		end)
	end
	player:GetAttributeChangedSignal("InSport"):Connect(applyAll)
	player:GetAttributeChangedSignal("InMiniGame"):Connect(applyAll)
	applyAll()
end

return SportInput
