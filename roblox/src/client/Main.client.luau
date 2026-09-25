-- Punto de entrada del cliente: crea la interfaz y escucha los avisos del servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent.UI.Hud)
local Store = require(script.Parent.UI.Store)
local TaskMarker = require(script.Parent.Controllers.TaskMarker)
local Ambient = require(script.Parent.Controllers.Ambient)
local Weather = require(script.Parent.Controllers.Weather)
local Wildlife = require(script.Parent.Controllers.Wildlife)
local StoryAudio = require(script.Parent.Controllers.StoryAudio)
local DayLight = require(script.Parent.Controllers.DayLight)
local LifeStory = require(script.Parent.Controllers.LifeStory)
local Baby = require(script.Parent.Controllers.Baby)
local ClassUI = require(script.Parent.Controllers.ClassUI)
local MapUI = require(script.Parent.Controllers.MapUI)
local InventoryUI = require(script.Parent.Controllers.InventoryUI)
local DialogueUI = require(script.Parent.Controllers.DialogueUI)
local MiniGameUI = require(script.Parent.Controllers.MiniGameUI)
local SceneClient = require(script.Parent.Controllers.SceneClient)
local Vehicles = require(script.Parent.Controllers.Vehicles)
local Arcade = require(script.Parent.Controllers.Arcade)
local DrivingSchool = require(script.Parent.Controllers.DrivingSchool)
local Restaurant = require(script.Parent.Controllers.Restaurant)
local Character = require(script.Parent.Controllers.Character)
local Prompts = require(script.Parent.Controllers.Prompts)
local Cinematics = require(script.Parent.Controllers.Cinematics)
local NearShadows = require(script.Parent.Controllers.NearShadows)
local Actions = require(script.Parent.Controllers.Actions)

local gui = Hud.init(function()
	Store.open()
end)
Store.init(gui)
TaskMarker.init()
DayLight.init() -- luz realista según la hora (amanecer, mediodía, atardecer, noche)
StoryAudio.init() -- música, efectos y voces de la historia (botón 🔊)
task.spawn(LifeStory.init) -- historia de vida (tarjeta "Tu vida", momentos, decisiones)
task.spawn(Baby.init) -- tutorial de bebé (botón de levantarse, familia, vista de la ciudad)
task.spawn(ClassUI.init) -- clases y exámenes que se juegan
task.spawn(MapUI.init) -- minimapa y mapa grande (tecla M)
task.spawn(InventoryUI.init) -- mochila estilo Minecraft (barra rápida 1-9, tecla E)
task.spawn(DialogueUI.init) -- conversaciones de las misiones (con respuestas y cámara)
task.spawn(MiniGameUI.init) -- pase, canastas, partido de fútbol
task.spawn(SceneClient.init) -- cada uno ve solo los personajes de su historia
task.spawn(Ambient.init) -- tráfico y peatones
task.spawn(Weather.init) -- estaciones y tiempo: lluvia, tormenta, nieve, hojas de otoño
task.spawn(Wildlife.init) -- pájaros, palomas, mariposas, patos, perros, gatos y animales de granja
task.spawn(Vehicles.init) -- bicis, monopatines, motos y coches
task.spawn(Arcade.init) -- recreativos
task.spawn(DrivingSchool.init) -- autoescuela
task.spawn(Restaurant.init) -- trabajo de camarero y barman
task.spawn(Character.init) -- ficha del personaje (botón Personaje) y correr con Shift
task.spawn(NearShadows.init) -- sombras de las luces solo cerca de ti (mismo aspecto, mucho más fluido)
task.spawn(Prompts.init) -- carteles de "pulsa E" con el estilo de la interfaz
task.spawn(Actions.init) -- gestos y bailes (G), trepar muros bajos, linterna (L) y modo foto (P)

-- Botones de arriba a la derecha del HUD
Hud.setAction("Mochila", InventoryUI.toggle)
Hud.setAction("Mapa", MapUI.toggleBig)

-- Música on/off en el menú (sustituye al botón suelto 🔊)
local musicOn = true
Hud.addMenuToggle("🔊 Música: sí", 1, function()
	musicOn = not musicOn
	StoryAudio.setMuted(not musicOn)
	return if musicOn then "🔊 Música: sí" else "🔇 Música: no"
end)

-- La tarjeta "Tu vida" de la historia y el botón suelto de la música ya están en el HUD nuevo
-- (objetivos a la izquierda y menú): se ocultan para que no salgan repetidos.
task.spawn(function()
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	-- (se esconde el botón y no la pantalla entera: las cinemáticas vuelven a encender las pantallas)
	local audioGui = playerGui:WaitForChild("StoryAudio", 30)
	if audioGui then
		for _, child in audioGui:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = false
			end
		end
	end
	local story = playerGui:WaitForChild("LifeStory", 30)
	local dock = story and story:WaitForChild("LifeStoryDock", 30)
	if dock and dock:IsA("GuiObject") then
		dock.Visible = false
		dock:GetPropertyChangedSignal("Visible"):Connect(function()
			dock.Visible = false
		end)
	end
end)

local Notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent
Notify.OnClientEvent:Connect(function(kind: string, text: string)
	if kind == "Sleep" then
		Hud.sleep()
	elseif kind == "Travel" then
		Hud.fade(text, 2)
	else
		Hud.toast(kind, text)
	end
end)

-- Durante las cinemáticas y las conversaciones no se puede interactuar con nada:
-- se apagan los carteles de "pulsa E" (y el mapa grande se cierra)
local ProximityPromptService = game:GetService("ProximityPromptService")
local localPlayer = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local function coreGuis()
	-- Lo que el juego ya dibuja a su manera (las cinemáticas encienden todo lo de Roblox al acabar)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- mochila propia
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) -- tapaba los botones de arriba a la derecha
	end)
end
coreGuis()
-- El chat de Roblox, a la derecha a media altura (arriba a la izquierda tapaba la ficha y los objetivos)
pcall(function()
	local TextChatService = game:GetService("TextChatService")
	local window = TextChatService:WaitForChild("ChatWindowConfiguration", 10) :: any
	if window then
		window.HorizontalAlignment = Enum.HorizontalAlignment.Right
		window.VerticalAlignment = Enum.VerticalAlignment.Center
	end
end)

local wasBusy = false
game:GetService("RunService").Heartbeat:Connect(function()
	local cinematic = Cinematics.isPlaying()
	local busy = cinematic or localPlayer:GetAttribute("InDialogue") == true
	if busy ~= wasBusy then
		wasBusy = busy
		ProximityPromptService.Enabled = not busy
		TaskMarker.setHidden(busy)
		Hud.setBusy(busy)
		if busy and MapUI.isOpen() then
			MapUI.toggleBig()
		end
		if not busy then
			task.defer(coreGuis)
		end
	end
end)

-- De bebé sobran el minimapa, el tiempo y el botón de correr
local function babyMode()
	local baby = localPlayer:GetAttribute("LifeStage") == "Bebe"
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end
	for _, path in { { "MapUI", "Minimap" }, { "WeatherChip" }, { "SprintGui", "SprintButton" } } do
		local target = playerGui:FindFirstChild(path[1])
		if target and path[2] then
			target = target:FindFirstChild(path[2])
		end
		if target and target:IsA("GuiObject") then
			target.Visible = not baby
		elseif target and target:IsA("ScreenGui") then
			for _, child in target:GetChildren() do
				if child:IsA("GuiObject") then
					child.Visible = not baby
				end
			end
		end
	end
end
localPlayer:GetAttributeChangedSignal("LifeStage"):Connect(babyMode)
task.delay(3, babyMode)
task.delay(12, babyMode)
