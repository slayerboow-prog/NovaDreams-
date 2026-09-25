-- Punto de entrada del cliente: crea la interfaz y escucha los avisos del servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent.UI.Hud)
local Store = require(script.Parent.UI.Store)
local TaskMarker = require(script.Parent.Controllers.TaskMarker)
local Ambient = require(script.Parent.Controllers.Ambient)
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
task.spawn(Vehicles.init) -- bicis, monopatines, motos y coches
task.spawn(Arcade.init) -- recreativos
task.spawn(DrivingSchool.init) -- autoescuela
task.spawn(Restaurant.init) -- trabajo de camarero y barman

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
