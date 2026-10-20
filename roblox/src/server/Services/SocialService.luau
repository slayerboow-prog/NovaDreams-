-- SocialService: grupos de jugadores y chat privado (lo que sale en el menú al tocar a un jugador).
--
-- GRUPO
--   * "Invitar al grupo": al otro le llega la invitación. Si acepta, entra en tu grupo (si no
--     tenías, se crea). Como mucho Social.MaxGroup jugadores. El primero es el líder.
--   * Cada grupo tiene su canal de chat. Si te vas del grupo (o del juego), sales del canal; si
--     queda uno solo, el grupo se deshace.
--
-- CHAT PRIVADO
--   * Se abre un canal de TextChatService solo para esos dos jugadores. Antes se pregunta a Roblox
--     (CanUsersDirectChatAsync) si pueden chatear en privado: respeta la edad y los ajustes de chat.
--   * Los mensajes los manda y filtra el propio chat de Roblox (TextChannel:SendAsync en el cliente).
--
-- Para el cliente: evento "Group" con los miembros (o nil) y atributos "GroupId" y "GroupLeader"
-- (UserId del líder) en cada jugador. PropertyService mira GroupLeader: con la privacidad «Grupo»
-- solo entran en tu casa los de tu grupo si el líder eres tú.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Social = require(ReplicatedStorage.Shared.Social)

local SocialService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Social :: RemoteEvent

type Group = { Id: number, Members: { Player }, Channel: Instance? }

local groups: { [number]: Group } = {}
local groupOf: { [Player]: Group } = {}
-- Invitaciones pendientes: a quién -> quién invita -> hasta cuándo (varias a la vez: antes la
-- segunda borraba la primera sin avisar)
local invites: { [Player]: { [Player]: number } } = {}
local lastAsk: { [Player]: number } = {}
local nextGroup = 0

local function nameOf(player: Player): string
	return player.DisplayName or player.Name
end

-- Evita que alguien mande peticiones sin parar
local function tooFast(player: Player): boolean
	local now = os.clock()
	if now - (lastAsk[player] or 0) < 0.5 then
		return true
	end
	lastAsk[player] = now
	return false
end

---------------------------------------------------------------------
-- Canales de chat (TextChatService). Todo con pcall: si falla, el grupo sigue funcionando.
---------------------------------------------------------------------

local function chatFolder(): Instance?
	local ok, folder = pcall(function()
		local service = game:GetService("TextChatService")
		local existing = service:FindFirstChild(Social.Folder)
		if existing then
			return existing
		end
		local f = Instance.new("Folder")
		f.Name = Social.Folder
		f.Parent = service
		return f
	end)
	return if ok then folder else nil
end

local function newChannel(name: string): Instance?
	local folder = chatFolder()
	if not folder then
		return nil
	end
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end
	local ok, channel = pcall(function()
		local c = Instance.new("TextChannel")
		c.Name = name
		c.Parent = folder
		return c
	end)
	return if ok then channel else nil
end

local function addToChannel(channel: Instance?, player: Player)
	if channel then
		task.spawn(pcall, function()
			(channel :: any):AddUserAsync(player.UserId)
		end)
	end
end

local function removeFromChannel(channel: Instance?, player: Player)
	if not channel then
		return
	end
	pcall(function()
		for _, source in channel:GetChildren() do
			if source:IsA("TextSource") and (source :: any).UserId == player.UserId then
				source:Destroy()
			end
		end
	end)
end

local function destroyChannel(channel: Instance?)
	if channel then
		pcall(channel.Destroy, channel)
	end
end

---------------------------------------------------------------------
-- Grupos
---------------------------------------------------------------------

local function groupData(group: Group): { any }
	local list = {}
	for i, member in group.Members do
		table.insert(list, { Name = nameOf(member), UserId = member.UserId, Leader = i == 1 })
	end
	return { Id = group.Id, Members = list, Max = Social.MaxGroup, Channel = Social.groupChannel(group.Id) }
end

local function publish(group: Group)
	local data = groupData(group)
	local leader = group.Members[1]
	for _, member in group.Members do
		member:SetAttribute("GroupId", group.Id)
		member:SetAttribute("GroupLeader", leader and leader.UserId)
		Remote:FireClient(member, "Group", data)
	end
end

local function forget(player: Player)
	if player.Parent then
		player:SetAttribute("GroupId", nil)
		player:SetAttribute("GroupLeader", nil)
		Remote:FireClient(player, "Group", nil)
	end
end

local function leave(player: Player, text: string?)
	local group = groupOf[player]
	if not group then
		return
	end
	groupOf[player] = nil
	local i = table.find(group.Members, player)
	if i then
		table.remove(group.Members, i)
	end
	removeFromChannel(group.Channel, player)
	forget(player)
	if #group.Members <= 1 then
		-- Solo queda uno: el grupo se deshace
		for _, member in group.Members do
			groupOf[member] = nil
			forget(member)
			Notify:FireClient(member, "Info", "👥 El grupo se ha deshecho.")
		end
		destroyChannel(group.Channel)
		groups[group.Id] = nil
		return
	end
	publish(group)
	for _, member in group.Members do
		Notify:FireClient(member, "Info", text or ("👥 %s ha salido del grupo."):format(nameOf(player)))
	end
end

local function join(group: Group, player: Player)
	groupOf[player] = group
	table.insert(group.Members, player)
	addToChannel(group.Channel, player)
end

-- Una invitación a la misma persona cada INVITE_GAP segundos, aunque diga que no (si no, se le
-- llena la pantalla de ventanas). Por UserId de quien invita y de quien recibe.
local INVITE_GAP = 30
local invitedAt: { [string]: number } = {}

-- Quita de una tabla "UserId>UserId" las parejas de ese jugador y las que ya pasaron su espera
-- (si no, en un servidor que dura mucho la tabla solo crece)
local function prunePairs(list: { [string]: number }, userId: number, gap: number)
	local id = tostring(userId)
	local now = os.clock()
	for pair, at in list do
		local a, b = string.match(pair, "^(%d+)>(%d+)$")
		if a == id or b == id or now - at >= gap then
			list[pair] = nil
		end
	end
end

local function onInvite(player: Player, userId: any)
	if typeof(userId) ~= "number" or tooFast(player) then
		return
	end
	local target = Players:GetPlayerByUserId(userId)
	if not target or target == player then
		return
	end
	local mine = groupOf[player]
	if mine and groupOf[target] == mine then
		Notify:FireClient(player, "Info", nameOf(target) .. " ya está en tu grupo.")
		return
	end
	if groupOf[target] then
		Notify:FireClient(player, "Info", nameOf(target) .. " ya está en otro grupo.")
		return
	end
	if mine and #mine.Members >= Social.MaxGroup then
		Notify:FireClient(player, "Error", ("Tu grupo está lleno (máximo %d)."):format(Social.MaxGroup))
		return
	end
	local pending = invites[target] and invites[target][player]
	if pending and os.clock() < pending then
		Notify:FireClient(player, "Info", "Ya le has invitado. Espera a que conteste.")
		return
	end
	local pair = player.UserId .. ">" .. target.UserId
	if os.clock() - (invitedAt[pair] or -math.huge) < INVITE_GAP then
		Notify:FireClient(player, "Info", ("Ya has invitado a %s hace poco. Espera un poco."):format(nameOf(target)))
		return
	end
	invitedAt[pair] = os.clock()
	invites[target] = invites[target] or {}
	invites[target][player] = os.clock() + Social.InviteSeconds
	Remote:FireClient(target, "GroupInvite", { Name = nameOf(player), UserId = player.UserId, Seconds = Social.InviteSeconds })
	Notify:FireClient(player, "Info", ("👥 Invitación enviada a %s."):format(nameOf(target)))
end

local function onAnswer(player: Player, userId: any, yes: any)
	if typeof(userId) ~= "number" then
		return
	end
	local mine = invites[player]
	local from = Players:GetPlayerByUserId(userId)
	local deadline = mine and from and mine[from]
	if not deadline then
		return
	end
	mine[from] = nil
	if next(mine) == nil then
		invites[player] = nil
	end
	if os.clock() > deadline or not from.Parent then
		Notify:FireClient(player, "Info", "La invitación ha caducado.")
		return
	end
	if yes ~= true then
		Notify:FireClient(from, "Info", nameOf(player) .. " no quiere unirse ahora.")
		return
	end
	invitedAt[from.UserId .. ">" .. player.UserId] = nil -- (ha aceptado: sin pausa para la próxima)
	local group = groupOf[from]
	if group and groupOf[player] == group then
		return
	end
	if group and #group.Members >= Social.MaxGroup then
		Notify:FireClient(player, "Error", "Ese grupo ya está lleno.")
		return
	end
	-- Si estabas en otro grupo, sales de él
	leave(player)
	if not group then
		nextGroup += 1
		group = { Id = nextGroup, Members = {}, Channel = newChannel(Social.groupChannel(nextGroup)) }
		groups[nextGroup] = group
		join(group, from)
	end
	join(group :: Group, player)
	publish(group :: Group)
	for _, member in (group :: Group).Members do
		if member ~= player then
			Notify:FireClient(member, "Success", ("👥 %s se ha unido al grupo."):format(nameOf(player)))
		end
	end
	Notify:FireClient(player, "Success", ("👥 Te has unido al grupo de %s."):format(nameOf(from)))
end

---------------------------------------------------------------------
-- Chat privado
---------------------------------------------------------------------

-- ¿Deja Roblox que estos dos chateen en privado? (edad, ajustes de chat…)
local function canDirectChat(a: Player, b: Player): boolean?
	local ok, allowed = pcall(function()
		return game:GetService("TextChatService"):CanUsersDirectChatAsync(a.UserId, { b.UserId })
	end)
	if not ok or typeof(allowed) ~= "table" then
		return nil
	end
	return table.find(allowed, b.UserId) ~= nil
end

local CHAT_NOTICE_GAP = 30
local chatNoticeAt: { [string]: number } = {}

local function onChat(player: Player, userId: any)
	if typeof(userId) ~= "number" or tooFast(player) then
		return
	end
	local target = Players:GetPlayerByUserId(userId)
	if not target or target == player then
		return
	end
	local can = canDirectChat(player, target)
	if can == nil then
		Notify:FireClient(player, "Error", "No se ha podido abrir el chat. Prueba otra vez en un momento.")
		return
	elseif can == false then
		Notify:FireClient(player, "Info", ("No puedes chatear en privado con %s (ajustes de chat de Roblox)."):format(nameOf(target)))
		return
	end
	local name = Social.privateChannel(player.UserId, target.UserId)
	local channel = newChannel(name)
	if not channel then
		Notify:FireClient(player, "Error", "No se ha podido abrir el chat.")
		return
	end
	pcall(function()
		(channel :: any).DirectChatRequester = player
	end)
	addToChannel(channel, player)
	addToChannel(channel, target)
	Remote:FireClient(player, "ChatOpen", { Channel = name, Title = "💬 " .. nameOf(target) })
	-- Al otro también le llega (antes no sabía que le escribías y no podía contestar). No le cambia
	-- el canal en el que escribe: le sale un aviso y el chat en su panel para contestar.
	-- (una vez cada CHAT_NOTICE_GAP segundos por pareja, para no llenarle la pantalla)
	local pair = player.UserId .. ">" .. target.UserId
	if os.clock() - (chatNoticeAt[pair] or -math.huge) >= CHAT_NOTICE_GAP then
		chatNoticeAt[pair] = os.clock()
		Remote:FireClient(target, "ChatIncoming", { Channel = name, Title = "💬 " .. nameOf(player), From = nameOf(player) })
	end
end

-- Quita los chats privados de alguien que se va
local function dropPrivateChats(player: Player)
	local folder = chatFolder()
	if not folder then
		return
	end
	local id = tostring(player.UserId)
	for _, channel in folder:GetChildren() do
		local name = channel.Name
		if name:sub(1, #Social.PrivatePrefix) == Social.PrivatePrefix then
			local a, b = name:match("_(%d+)_(%d+)$")
			if a == id or b == id then
				destroyChannel(channel)
			end
		end
	end
end

---------------------------------------------------------------------

function SocialService.init()
	Remote.OnServerEvent:Connect(function(player, action, a, b)
		if action == "Invite" then
			onInvite(player, a)
		elseif action == "Answer" then
			onAnswer(player, a, b)
		elseif action == "Leave" then
			leave(player)
		elseif action == "Chat" then
			onChat(player, a)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		leave(player, ("👥 %s se ha ido del juego."):format(nameOf(player)))
		invites[player] = nil
		for target, list in invites do
			list[player] = nil
			if next(list) == nil then
				invites[target] = nil
			end
		end
		lastAsk[player] = nil
		prunePairs(invitedAt, player.UserId, INVITE_GAP)
		prunePairs(chatNoticeAt, player.UserId, CHAT_NOTICE_GAP)
		dropPrivateChats(player)
	end)
end

-- Para las pruebas
SocialService._groupOf = groupOf

return SocialService
