-- NPC: Cosme vive en su casa y sigue su rutina con la hora del juego (docs/historia/casa-cosme.md,
-- punto 26; Layout.Routine): 08 cocina, 09 laboratorio, 11 ordenador, 13 cocina, 15 garaje,
-- 18 observatorio, 21 salón y 01 laboratorio secreto.
--
--   * Anda de un sitio a otro por los puntos de paso de la casa (Layout.path: pasillos, puertas y las
--     escaleras de verdad), nunca aparece de golpe. Por la noche, para entrar en la habitación
--     secreta, se abre la estantería y se cierra detrás de él.
--   * Es un personaje «fijo» del mundo (etiqueta StaticNpc, NpcId = "Cosme", World/Npc con el aspecto
--     del reparto: shared/LifeStory/Cast). Así sus misiones lo encuentran: si una escena de la
--     historia trae a Cosme, sale andando desde donde esté (SceneService.ambientStart) y este se
--     oculta solo para ese jugador mientras dure (Controllers/SceneClient).
--   * Se le puede hablar (aviso «Hablar»): dice algo de lo que está haciendo y cuenta para la historia
--     (QuestHooks.talked: «Talk» con Npc = "Cosme").

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(script.Parent.Layout)
local QuestHooks = require(script.Parent.QuestHooks)
local Builder = require(script.Parent.Parent.Builder)

local NPC = {}

local npc: Model? = nil
local site: CFrame = CFrame.identity
local at: string = "Cocina"
local goal: string? = nil
local busy = false
local slotHour = -1

local function world(name: string): Vector3
	return (site * CFrame.new(Layout.point(name))).Position
end

function NPC.model(): Model?
	return npc
end

function NPC.point(): string
	return at
end

-- Lo que toca a esta hora (Layout.slotAt)
function NPC.slot(clock: number): { [string]: any }
	return Layout.slotAt(clock)
end

local function walk(path: { string }, Npc: any, Interactions: any)
	local list = {}
	for i = 2, #path do
		table.insert(list, path[i])
	end
	-- A tramos: si el camino pasa por la estantería secreta, se abre antes y se cierra después
	local i = 1
	while i <= #list do
		local chunk = {}
		local name = list[i]
		while i <= #list do
			name = list[i]
			table.insert(chunk, world(name))
			i += 1
			if name == "Estanteria" or name == "SecretaEntrada" then
				break
			end
		end
		pcall(Npc.walkTo, npc, chunk, 7)
		at = name
		if (name == "Estanteria" or name == "SecretaEntrada") and Interactions and not Interactions.isSecretOpen() then
			Interactions.openSecret(true, 8)
			task.wait(1.5)
		end
	end
end

local function goTo(target: string, Npc: any, Interactions: any)
	if busy or not npc then
		return
	end
	local path = Layout.path(at, target)
	if not path then
		return
	end
	busy = true
	goal = target
	pcall(Npc.work, npc, nil)
	pcall(Npc.say, npc, nil)
	walk(path, Npc, Interactions)
	busy = false
	goal = nil
end

local function settle(slot: { [string]: any }, Npc: any)
	if not npc then
		return
	end
	pcall(Npc.work, npc, slot.Work)
	npc:SetAttribute("CosmeRoom", slot.Room)
	-- Mira hacia donde mira su sitio (el de la historia si lo hay, si no hacia el centro de la sala)
	local room = Layout.room(slot.Room)
	if room then
		local center = Vector3.new((room.X0 + room.X1) / 2, Layout.point(slot.Point).Y, (room.Z0 + room.Z1) / 2)
		local here = Layout.point(slot.Point)
		local look = (center - here)
		if look.Magnitude > 1 then
			pcall(Npc.faceSmooth, npc, (site * CFrame.new(here + look.Unit * 4)).Position, 0.6)
		end
	end
end

function NPC.start(houseModel: Model, Interactions: any)
	local site_ = houseModel:GetAttribute("Site")
	if typeof(site_) ~= "CFrame" then
		return
	end
	site = site_
	local Npc = require(script.Parent.Parent.Npc) :: any
	local Cast = require(ReplicatedStorage.Shared.LifeStory.Cast) :: any
	local person = Cast.People.Cosme or {}
	local slot = Layout.slotAt(Lighting.ClockTime)
	at = slot.Point
	slotHour = slot.Hour
	local start = site * CFrame.new(Layout.point(at))
	local ok, model = pcall(Npc.create, "Cosme", houseModel, start, {
		Skin = person.Skin,
		Shirt = person.Shirt,
		Pants = person.Pants,
		Hair = person.Hair,
		LongSleeves = person.LongSleeves,
	})
	if not ok or not model then
		warn("[CasaCosme] No se pudo crear a Cosme: " .. tostring(model))
		return
	end
	npc = model
	model:SetAttribute("NpcId", "Cosme")
	model:SetAttribute("Routine", true)
	CollectionService:AddTag(model, "StaticNpc")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = "Cosme"
	end
	settle(slot, Npc)
	-- Hablar con Cosme
	local root = model.PrimaryPart
	if root then
		local prompt = Builder.prompt(root, "Hablar", "🧪 Cosme", 0)
		prompt.MaxActivationDistance = 9
		prompt.Triggered:Connect(function(player)
			local s = Layout.slotAt(Lighting.ClockTime)
			local lines = s.Lines or { "¡Criatura!" }
			pcall(Npc.say, model, if busy then "¡Ahora no, criatura, que llego tarde a mí mismo!" else lines[math.random(1, #lines)], 5)
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and not busy then
				pcall(Npc.faceSmooth, model, hrp.Position, 0.4)
			end
			QuestHooks.talked(player, s.Room)
		end)
	end
	-- La rutina: cada pocos segundos mira la hora; si toca otro sitio, va andando
	task.spawn(function()
		while model.Parent do
			task.wait(3)
			local ok2, err = pcall(function()
				local s = Layout.slotAt(Lighting.ClockTime)
				if s.Hour ~= slotHour and not busy then
					slotHour = s.Hour
					goTo(s.Point, Npc, Interactions)
					settle(s, Npc)
				end
			end)
			if not ok2 then
				warn("[CasaCosme] Rutina: " .. tostring(err))
			end
		end
	end)
end

-- Para la prueba: adónde iría y por dónde, sin moverlo
function NPC.plan(from: string, clock: number): (string, { string }?)
	local s = Layout.slotAt(clock)
	return s.Point, Layout.path(from, s.Point)
end

local _ = goal
return NPC
