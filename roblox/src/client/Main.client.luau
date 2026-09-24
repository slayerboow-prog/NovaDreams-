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

local gui = Hud.init(function()
	Store.open()
end)
Store.init(gui)
TaskMarker.init()
DayLight.init() -- luz realista según la hora (amanecer, mediodía, atardecer, noche)
StoryAudio.init() -- música, efectos y voces de la historia (botón 🔊)
task.spawn(LifeStory.init) -- historia de vida (tarjeta "Tu vida", momentos, decisiones)
task.spawn(Baby.init) -- tutorial de bebé (botón de levantarse, familia, vista de la ciudad)
task.spawn(Ambient.init) -- tráfico y peatones

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
