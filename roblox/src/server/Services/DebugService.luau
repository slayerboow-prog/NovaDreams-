-- DebugService: herramientas de depuración SOLO para el dueño del juego.
--
-- Quién puede usarlas (lo decide siempre el servidor): en Studio, el creador del juego (o el dueño
-- del grupo si el juego es de un grupo) y quien esté en Config.Debug.DebugUserIds. Para cualquier
-- otro jugador no existen: los comandos no hacen nada y el panel no recibe datos.
--
-- Comandos (en el chat):
--   /debug mission         misiones activas: paso, tipo, objetivo, cuánto lleva sin avanzar
--   /debug npc             personajes cerca: los de tu escena (modo, sitio, si hablan) y los del mapa
--   /debug story           resumen de tu vida: etapa, edad, capítulo, decisiones, marcas, relaciones
--   /debug teleport <lugar> ir a un lugar de la historia (Locations: "AulaA", "PlazaCentro"…)
--   /debug resetmission [id] reinicia la misión (la seguida si no se dice cuál) desde el paso 1
--   /debug validate        pasa el validador de misiones y dice los errores
--   /debug hud             enseña / esconde el panel de depuración (también la tecla F8)
--   /debug log [categoría] los últimos avisos del registro ([MISSION], [NPC], [WATCHDOG]…)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Log = require(ReplicatedStorage.Shared.Log)
local LifeStory = ReplicatedStorage.Shared.LifeStory
local Locations = require(LifeStory.Locations)
local Validate = require(LifeStory.Validate)
local StoryState = require(LifeStory.StoryState)
local DataService = require(script.Parent.DataService)
local LifeStoryService = require(script.Parent.LifeStoryService)
local SceneService = require(script.Parent.SceneService)
local LocationService = require(script.Parent.LocationService)
local DialogueService = require(script.Parent.DialogueService)

local DebugService = {}

local Remote: RemoteEvent
local hudOn: { [Player]: boolean } = {}
local groupOwner: { [Player]: boolean } = {}

local function studio(): boolean
	local ok, result = pcall(function()
		return RunService:IsStudio()
	end)
	return ok and result == true
end

-- ¿Puede este jugador usar las herramientas de depuración?
function DebugService.allowed(player: Player): boolean
	if studio() then
		return true
	end
	local userId = player.UserId
	if type(userId) ~= "number" or userId <= 0 then
		return false
	end
	for _, id in (Config.Debug and Config.Debug.DebugUserIds) or {} do
		if id == userId then
			return true
		end
	end
	local creatorType = game.CreatorType
	if creatorType == Enum.CreatorType.User then
		return game.CreatorId ~= 0 and userId == game.CreatorId
	elseif creatorType == Enum.CreatorType.Group then
		return groupOwner[player] == true
	end
	return false
end

local function fmtPos(v: Vector3?): string
	return if v then ("(%d, %d, %d)"):format(math.round(v.X), math.round(v.Y), math.round(v.Z)) else "?"
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

---------------------------------------------------------------------
-- Lo que se ve (texto de los comandos y datos del panel)
---------------------------------------------------------------------

local function missionLines(player: Player): { string }
	local state = LifeStoryService.debugState(player)
	if not state then
		return { "Sin datos de la historia todavía." }
	end
	local lines = { ("Etapa %s · %s años · capítulo %s · seguida: %s"):format(tostring(state.Stage), tostring(state.Age), tostring(state.Chapter), tostring(state.Tracked)) }
	if state.Waiting then
		table.insert(lines, ("Esperando %s (%s)"):format(tostring(state.Waiting.QuestId), tostring(state.Waiting.Reason)))
	end
	local ids = {}
	for id in state.Active do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ids do
		local a = state.Active[id]
		table.insert(lines, ("• %s [%s] paso %d/%d %s%s%s · «%s» · %d s sin avanzar"):format(
			id, tostring(a.Kind), a.Step, a.Steps, tostring(a.Type),
			if a.Npc then " con " .. tostring(a.Npc) else "",
			if a.Place then " en " .. tostring(a.Place) else "",
			tostring(a.Text or ""), a.StalledFor or 0))
	end
	if #ids == 0 then
		table.insert(lines, "Ninguna misión activa.")
	end
	table.insert(lines, ("Ocupada: %s · conversación: %s"):format(tostring(state.Busy), tostring(state.InDialogue)))
	return lines
end

local function npcData(player: Player): { { [string]: any } }
	local list = {}
	for _, info in SceneService.debugActors(player) do
		info.Source = "Escena"
		table.insert(list, info)
	end
	local root = rootOf(player)
	if root then
		for _, model in CollectionService:GetTagged("StaticNpc") do
			if model:IsA("Model") and model.Parent then
				local pivot = model:GetPivot().Position
				local distance = (pivot - root.Position).Magnitude
				if distance < 45 then
					local humanoid = model:FindFirstChildOfClass("Humanoid")
					table.insert(list, {
						Source = "Mapa",
						Npc = tostring(model:GetAttribute("NpcId") or model:GetAttribute("StaffRole") or model.Name),
						Distance = math.round(distance),
						Target = if humanoid then fmtPos(humanoid.WalkToPoint) else "-",
						Moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1,
					})
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return (a.Distance or 0) < (b.Distance or 0)
	end)
	return list
end

local function npcLines(player: Player): { string }
	local lines = {}
	for _, info in npcData(player) do
		table.insert(lines, ("• [%s] %s · %s m · %s%s%s%s"):format(
			info.Source, tostring(info.Npc), tostring(info.Distance), tostring(info.Mode or (if info.Moving then "andando" else "quieto")),
			if info.Quest then " · " .. info.Quest else "",
			if info.Talking then " · hablando contigo" else "",
			if info.Target then " → " .. tostring(info.Target) else ""))
		if #lines >= 14 then
			break
		end
	end
	if #lines == 0 then
		table.insert(lines, "Nadie cerca.")
	end
	return lines
end

local function storyLines(player: Player): { string }
	local data = DataService.get(player)
	if not data then
		return { "Sin datos." }
	end
	local s = StoryState.of(data)
	local lines = {
		("Etapa %s · %s años · capítulo %s"):format(tostring(s.stage()), tostring(s.age()), tostring(s.chapter())),
		("Misiones terminadas: %d · activas: %s"):format(s.completedCount(), table.concat(s.activeMissions(), ", ")),
		("Estudios: %s · trabajo: %s"):format(tostring(s.studies() or "-"), tostring(s.job() or "-")),
	}
	local choices = {}
	for key, value in s.decisions() do
		table.insert(choices, key .. "=" .. tostring(value))
	end
	table.sort(choices)
	table.insert(lines, "Decisiones: " .. (if #choices > 0 then table.concat(choices, ", ") else "-"))
	local flags = s.flags()
	table.sort(flags)
	table.insert(lines, "Marcas: " .. (if #flags > 0 then table.concat(flags, ", ", 1, math.min(#flags, 25)) else "-"))
	local rels = {}
	for npc, value in s.relationships() do
		table.insert(rels, ("%s %+d"):format(npc, value))
	end
	table.sort(rels)
	table.insert(lines, "Relaciones: " .. (if #rels > 0 then table.concat(rels, ", ") else "-"))
	return lines
end

local function hudPayload(player: Player): { [string]: any }
	local root = rootOf(player)
	local position = root and root.Position
	return {
		Mission = missionLines(player),
		Story = storyLines(player),
		Npcs = npcLines(player),
		Location = ("%s %s"):format(if position then LocationService.zoneAt(position) else "?", fmtPos(position)),
		Dialogue = ("conversación: %s · InDialogue: %s · habla con: %s"):format(
			tostring(DialogueService.isBusy(player)), tostring(player:GetAttribute("InDialogue")), tostring(player:GetAttribute("TalkingTo") or "-")),
		Log = Log.recent(8),
	}
end

---------------------------------------------------------------------
-- Comandos
---------------------------------------------------------------------

local function reply(player: Player, lines: { string })
	if Remote then
		Remote:FireClient(player, "Text", { Lines = lines })
	end
end

-- Atiende un comando. Devuelve lo que contesta (nil si no se atiende: jugador sin permiso o no es
-- un comando de depuración)
function DebugService.handle(player: Player, text: any): { string }?
	if type(text) ~= "string" or #text > 200 then
		return nil
	end
	local words = {}
	for word in text:gmatch("%S+") do
		table.insert(words, word)
	end
	if words[1] ~= "/debug" and words[1] ~= "/dbg" then
		return nil
	end
	if not DebugService.allowed(player) then
		return nil -- para los demás, estos comandos no existen
	end
	local command = (words[2] or "mission"):lower()
	local lines: { string }
	if command == "mission" then
		lines = missionLines(player)
	elseif command == "npc" then
		lines = npcLines(player)
	elseif command == "story" then
		lines = storyLines(player)
	elseif command == "teleport" or command == "tp" then
		local placeId = words[3]
		if not placeId or not Locations.Places[placeId] then
			lines = { "Lugar desconocido. Ejemplos: PlazaCentro, AulaA, Patio, Home, Playa" }
		else
			local spot = LocationService.resolve(player, placeId)
			if spot then
				SceneService.teleportTo(player, spot.Position)
				lines = { ("Teletransportado a %s %s"):format(placeId, fmtPos(spot.Position)) }
			else
				lines = { placeId .. " no está en el mapa (ni su plan B)" }
			end
		end
	elseif command == "resetmission" then
		local ok, message = LifeStoryService.resetQuest(player, words[3])
		lines = { if ok then "Misión reiniciada: " .. message else "No se pudo: " .. message }
	elseif command == "validate" then
		local report = Validate.report()
		lines = { ("Validador: %d errores, %d avisos"):format(#report.Errors, #report.Warnings) }
		for i = 1, math.min(10, #report.Errors) do
			table.insert(lines, "❌ " .. report.Errors[i])
		end
		for i = 1, math.min(5, #report.Warnings) do
			table.insert(lines, "⚠️ " .. report.Warnings[i])
		end
	elseif command == "hud" then
		hudOn[player] = not hudOn[player]
		Remote:FireClient(player, "Hud", if hudOn[player] then hudPayload(player) else false)
		lines = { "Panel de depuración " .. (if hudOn[player] then "visible" else "oculto") }
	elseif command == "log" then
		lines = Log.recent(15, if words[3] then words[3]:upper() else nil)
		if #lines == 0 then
			lines = { "(registro vacío)" }
		end
	else
		lines = { "Comandos: /debug mission | npc | story | teleport <lugar> | resetmission [id] | validate | hud | log [categoría]" }
	end
	Log.info("DEBUG", "%s: %s", player.Name, text)
	reply(player, lines)
	return lines
end

local function setup(player: Player)
	if game.CreatorType == Enum.CreatorType.Group then
		task.spawn(function()
			local ok, rank = pcall(function()
				return player:GetRankInGroup(game.CreatorId)
			end)
			groupOwner[player] = ok and rank == 255
			player:SetAttribute("DebugAllowed", if DebugService.allowed(player) then true else nil)
		end)
	end
	-- Solo informa al cliente para que escuche la tecla F8; los datos los manda siempre el servidor
	player:SetAttribute("DebugAllowed", if DebugService.allowed(player) then true else nil)
	pcall(function()
		player.Chatted:Connect(function(message)
			DebugService.handle(player, message)
		end)
	end)
end

function DebugService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("Debug") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "Debug"
		Remote.Parent = remotes
	end
	-- Desde el panel (o la tecla F8) el cliente manda el texto del comando; se valida igual
	local lastRemote: { [Player]: number } = {}
	Remote.OnServerEvent:Connect(function(player, kind, text)
		if kind ~= "Command" or os.clock() - (lastRemote[player] or 0) < 0.3 then
			return
		end
		lastRemote[player] = os.clock()
		DebugService.handle(player, text)
	end)
	-- Comando de chat de verdad (TextChatService): /debug …
	pcall(function()
		local TextChatService = game:GetService("TextChatService")
		local command = Instance.new("TextChatCommand")
		command.Name = "DebugCommand"
		command.PrimaryAlias = "/debug"
		command.SecondaryAlias = "/dbg"
		command.Triggered:Connect(function(source: TextSource, message: string)
			local player = Players:GetPlayerByUserId(source.UserId)
			if player then
				DebugService.handle(player, message)
			end
		end)
		command.Parent = TextChatService
	end)
	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		task.spawn(setup, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		hudOn[player] = nil
		groupOwner[player] = nil
		lastRemote[player] = nil
	end)
	-- El panel se actualiza cada segundo (solo para quien lo tiene abierto y tiene permiso)
	task.spawn(function()
		while true do
			task.wait(1)
			for player in hudOn do
				if player.Parent and DebugService.allowed(player) then
					local ok, payload = pcall(hudPayload, player)
					if ok then
						Remote:FireClient(player, "Hud", payload)
					end
				else
					hudOn[player] = nil
				end
			end
		end
	end)
end

return DebugService
