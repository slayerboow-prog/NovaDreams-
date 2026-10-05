-- SceneClient (cliente): cada jugador ve SOLO su historia.
--   * Los actores y objetos de las misiones de otros jugadores (workspace.StoryScenes.Scene_<id>)
--     se vuelven invisibles y sin botones para ti.
--   * Si tu escena trae a un personaje que también existe fijo en el mundo (Nico en el patio,
--     tu familia en casa…), el fijo se oculta mientras dure tu escena: nunca ves a dos Nicos.
--   * Fundidos: los personajes de tu escena aparecen con un fundido suave, y los del colegio que
--     "saltan" a otro sitio porque no pueden ir andando (atributo Fade, SchoolService) se desvanecen
--     y reaparecen allí.
--   * Otros jugadores en plano (C-16): mientras ves una escena (InCinematic) o hablas con alguien
--     (InDialogue), los demás jugadores que entran en el encuadre desaparecen SOLO en tu pantalla, y
--     vuelven al acabar. Se quedan ocultos hasta el final (no parpadean al entrar y salir del plano).
--   * Latido (M-04): mientras tienes una escena en pantalla o esperando su turno, se avisa al servidor
--     cada segundo (Remotes.Scene, "Beat"). El servidor marca InScene y, si el latido se corta (se
--     cerró el juego, se colgó la pantalla), cierra la escena él solo.
--   * Interrupciones: al morir, al reaparecer o al irte a otro lugar (TeleportService), avisa a quien
--     se haya apuntado con SceneClient.onInterrupt (Cinematics corta la escena y lo devuelve todo).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SceneClient = {}

local player = Players.LocalPlayer

local function setHidden(root: Instance, hidden: boolean)
	local function apply(instance: Instance)
		if instance:IsA("BasePart") then
			instance.LocalTransparencyModifier = if hidden then 1 else 0
			if hidden then
				instance.CanQuery = false
			end
			-- Invisible para ti = tampoco choca contigo (antes era una pared invisible en la entrada del
			-- cole, y los acompañantes de otro jugador te empujaban). Solo en tu pantalla.
			if hidden and instance.CanCollide then
				instance:SetAttribute("SceneCollide", true)
				instance.CanCollide = false
			elseif not hidden and instance:GetAttribute("SceneCollide") then
				instance:SetAttribute("SceneCollide", nil)
				instance.CanCollide = true
			end
		elseif instance:IsA("Decal") then
			instance.LocalTransparencyModifier = if hidden then 1 else 0
		elseif instance:IsA("ProximityPrompt") then
			instance:SetAttribute("SceneHidden", if hidden then true else nil)
			instance.Enabled = not hidden and not instance:GetAttribute("GuardOff") -- (PromptGuard)
		elseif instance:IsA("Highlight") then
			instance.Enabled = not hidden
		elseif instance:IsA("Humanoid") then
			-- (los actores con nombre lo llevan en su cartel propio: Controllers/NameTags)
			local named = instance.Parent ~= nil and game:GetService("CollectionService"):HasTag(instance.Parent, "NamedActor")
			instance.DisplayDistanceType = if hidden or named then Enum.HumanoidDisplayDistanceType.None else Enum.HumanoidDisplayDistanceType.Viewer
		end
	end
	apply(root)
	for _, descendant in root:GetDescendants() do
		apply(descendant)
	end
end

local mine: Instance? = nil
local hiddenStatic: { [Instance]: boolean } = {}

-- Fundido de un personaje (solo en tu pantalla): de `from` a `to` de transparencia en `seconds`
local function fade(model: Instance, from: number, to: number, seconds: number, onDone: (() -> ())?)
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			table.insert(parts, d)
		end
	end
	local start = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local k = math.clamp((os.clock() - start) / seconds, 0, 1)
		local value = from + (to - from) * k
		if hiddenStatic[model] then
			value = 1 -- (oculto por tu escena mientras tanto: sigue oculto)
		end
		for _, p in parts do
			if p.Parent then
				(p :: any).LocalTransparencyModifier = value
			end
		end
		if k >= 1 or not model.Parent then
			connection:Disconnect()
			if onDone then
				onDone()
			end
		end
	end)
end

local watched: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function watchFade(npc: Instance)
	if watched[npc] then
		return -- (vuelve a aparecer en el mundo cada mañana: se escucha una sola vez)
	end
	watched[npc] = true
	npc:GetAttributeChangedSignal("Fade"):Connect(function()
		if hiddenStatic[npc] then
			return
		end
		-- Se desvanece, el servidor lo cambia de sitio, y reaparece
		fade(npc, 0, 1, 0.3, function()
			task.delay(0.1, function()
				if npc.Parent and not hiddenStatic[npc] then
					fade(npc, 1, 0, 0.4)
				end
			end)
		end)
	end)
end

-- Los personajes fijos que ahora mismo están en tu escena se ocultan
local function refreshStatic()
	local inScene: { [string]: boolean } = {}
	if mine then
		for _, model in mine:GetChildren() do
			local id = model:GetAttribute("NpcId")
			if id then
				inScene[id] = true
			end
		end
	end
	for _, npc in CollectionService:GetTagged("StaticNpc") do
		local hide = inScene[npc:GetAttribute("NpcId") or ""] == true
		if hide ~= (hiddenStatic[npc] == true) then
			setHidden(npc, hide)
			hiddenStatic[npc] = if hide then true else nil
		end
	end
end

local function watchScene(folder: Instance)
	if not folder:IsA("Folder") then
		return
	end
	local owner = folder:GetAttribute("Owner")
	if owner == player.UserId then
		mine = folder
		folder.ChildAdded:Connect(function(child)
			task.defer(refreshStatic)
			if child:IsA("Model") and child:GetAttribute("NpcId") then
				-- Tu escena trae a alguien: aparece con un fundido (no de golpe)
				task.defer(fade, child, 1, 0, 0.45)
			end
		end)
		folder.ChildRemoved:Connect(function()
			task.defer(refreshStatic)
		end)
		refreshStatic()
		return
	end
	-- Escena de otro jugador: todo invisible para ti, también lo que se añada después
	setHidden(folder, true)
	folder.DescendantAdded:Connect(function(descendant)
		task.defer(setHidden, descendant, true)
	end)
end

---------------------------------------------------------------------
-- Otros jugadores en plano (solo en tu pantalla)
---------------------------------------------------------------------

SceneClient.ShotRadius = 160 -- en una escena de cámara (planos generales)
SceneClient.DialogueRadius = 50 -- en una conversación (planos cortos)
SceneClient.HideEvery = 0.15

local othersHolders: { [string]: boolean } = {}
type Hidden = { Parts: { [Instance]: boolean }, Guis: { [BillboardGui]: boolean }, Added: RBXScriptConnection? }
local hiddenOthers: { [Instance]: Hidden } = {}

-- ¿Ese punto sale en el plano? (pura geometría: delante de la cámara, dentro del ángulo de visión
-- con un margen para el cuerpo, y a menos de `radius`)
function SceneClient.inShot(camera: CFrame, fov: number, aspect: number, point: Vector3, radius: number): boolean
	local offset = point - camera.Position
	local distance = offset.Magnitude
	if distance > radius then
		return false
	end
	if distance < 4 then
		return true -- (pegado a la cámara: tapa el plano aunque esté de lado)
	end
	local localPoint = camera:PointToObjectSpace(point)
	local depth = -localPoint.Z
	if depth <= 0 then
		return false -- detrás de la cámara
	end
	local margin = 3 -- medio cuerpo: con un brazo dentro ya se ve
	local halfV = math.tan(math.rad(fov) / 2)
	local halfH = halfV * math.max(aspect, 0.1)
	return math.abs(localPoint.X) <= depth * halfH + margin and math.abs(localPoint.Y) <= depth * halfV + margin
end

local function hideInstance(entry: Hidden, d: Instance)
	if d:IsA("BasePart") or d:IsA("Decal") then
		if (d :: any).LocalTransparencyModifier < 1 then
			(d :: any).LocalTransparencyModifier = 1
			entry.Parts[d] = true
		end
	elseif d:IsA("BillboardGui") and d.Name ~= "Bubble" and d.Name ~= "Icon" then
		-- (Bubble e Icon los calla CineCamera.quietLabels; aquí los demás carteles del jugador)
		if d.Enabled then
			d.Enabled = false
			entry.Guis[d] = true
		end
	end
end

local function hideOther(character: Instance)
	if hiddenOthers[character] then
		return
	end
	local entry: Hidden = { Parts = {}, Guis = {} }
	hiddenOthers[character] = entry
	for _, d in character:GetDescendants() do
		hideInstance(entry, d)
	end
	-- Lo que se ponga mientras tanto (una herramienta, un sombrero), también oculto
	local ok, connection = pcall(function()
		return character.DescendantAdded:Connect(function(d)
			if hiddenOthers[character] == entry then
				task.defer(hideInstance, entry, d)
			end
		end)
	end)
	entry.Added = if ok then connection else nil
end

local function showOther(character: Instance)
	local entry = hiddenOthers[character]
	if not entry then
		return
	end
	hiddenOthers[character] = nil
	if entry.Added then
		entry.Added:Disconnect()
	end
	for part in entry.Parts do
		if part.Parent and (part :: any).LocalTransparencyModifier >= 1 then
			(part :: any).LocalTransparencyModifier = 0
		end
	end
	for gui in entry.Guis do
		if gui.Parent and not gui.Enabled then
			gui.Enabled = true
		end
	end
end

-- Radio de ocultar ahora mismo (nil = no hay escena ni conversación: no se oculta a nadie)
local function hideRadius(): number?
	if next(othersHolders) ~= nil or player:GetAttribute("InCinematic") == true then
		return SceneClient.ShotRadius
	elseif player:GetAttribute("InDialogue") == true then
		return SceneClient.DialogueRadius
	end
	return nil
end

-- Una pasada: oculta a los que están en plano; sin escena, enseña a todos. Devuelve cuántos hay ocultos.
function SceneClient.refreshOthers(): number
	local radius = hideRadius()
	local camera = workspace.CurrentCamera
	if not radius or not camera then
		for character in hiddenOthers do
			showOther(character)
		end
		return 0
	end
	local cf = camera.CFrame
	local viewport = camera.ViewportSize
	local aspect = if viewport and viewport.Y > 0 then viewport.X / viewport.Y else 16 / 9
	local alive: { [Instance]: boolean } = {}
	for _, other in Players:GetPlayers() do
		local character = other ~= player and other.Character
		if character then
			alive[character] = true
			local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
			if not hiddenOthers[character] and root and root:IsA("BasePart") and SceneClient.inShot(cf, camera.FieldOfView, aspect, root.Position, radius) then
				hideOther(character)
			end
		end
	end
	local count = 0
	for character in hiddenOthers do
		if not alive[character] or not character.Parent then
			showOther(character) -- (se fue del juego o reapareció con otro cuerpo)
		else
			count += 1
		end
	end
	return count
end

-- Para quien quiera ocultar a los demás sin InCinematic/InDialogue (un motivo, como Controls)
function SceneClient.hideOthers(reason: string, on: boolean)
	othersHolders[reason] = if on then true else nil
	SceneClient.refreshOthers()
end

-- ¿Está ese personaje oculto por estar en tu plano?
function SceneClient.isHiddenOther(character: Instance): boolean
	return hiddenOthers[character] ~= nil
end

local function watchOthers()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < SceneClient.HideEvery then
			return
		end
		acc = 0
		if hideRadius() == nil and next(hiddenOthers) == nil then
			return -- (lo normal: nada que hacer)
		end
		local ok, err = pcall(SceneClient.refreshOthers)
		if not ok then
			warn("[SceneClient] " .. tostring(err))
		end
	end)
end

---------------------------------------------------------------------
-- Latido al servidor e interrupciones
---------------------------------------------------------------------

SceneClient.BeatSeconds = 1
local busyChecks: { () -> boolean } = {}

-- Quien enseña escenas dice cómo saber si tiene una (en pantalla o esperando): mientras alguna diga
-- que sí, o esté puesto InCinematic, hay latido
function SceneClient.watchBusy(check: () -> boolean)
	table.insert(busyChecks, check)
end

function SceneClient.isBusy(): boolean
	if player:GetAttribute("InCinematic") == true then
		return true
	end
	for _, check in busyChecks do
		local ok, busy = pcall(check)
		if ok and busy then
			return true
		end
	end
	return false
end

local function sceneRemote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("Scene")
	return if remote and remote:IsA("RemoteEvent") then remote else nil
end

local function beatLoop()
	while true do
		task.wait(SceneClient.BeatSeconds)
		if SceneClient.isBusy() then
			local remote = sceneRemote()
			if remote then
				pcall(remote.FireServer, remote, "Beat")
			end
		end
	end
end

local interruptListeners: { (reason: string) -> () } = {}

-- fn(reason) se llama al morir ("Muerte"), al reaparecer ("Reaparecer") o al irte a otro lugar
-- del juego ("Teletransporte")
function SceneClient.onInterrupt(fn: (reason: string) -> ())
	table.insert(interruptListeners, fn)
end

function SceneClient.interrupt(reason: string)
	for _, fn in interruptListeners do
		task.spawn(function()
			local ok, err = pcall(fn, reason)
			if not ok then
				warn("[SceneClient] " .. tostring(err))
			end
		end)
	end
end

local function watchLife()
	local function onCharacter(character: Model)
		local ok, humanoid = pcall(function()
			return character:WaitForChild("Humanoid", 10)
		end)
		if ok and humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(function()
				SceneClient.interrupt("Muerte")
			end)
		end
	end
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		SceneClient.interrupt("Reaparecer")
		task.spawn(onCharacter, character)
	end)
	pcall(function()
		player.OnTeleport:Connect(function(state)
			if state == Enum.TeleportState.Started then
				SceneClient.interrupt("Teletransporte")
			end
		end)
	end)
end

local started = false
function SceneClient.start()
	if started then
		return
	end
	started = true
	pcall(watchOthers)
	pcall(watchLife)
	task.spawn(beatLoop)
end

function SceneClient.init()
	SceneClient.start()
	local scenes = workspace:WaitForChild("StoryScenes", 60)
	if not scenes then
		return
	end
	for _, folder in scenes:GetChildren() do
		watchScene(folder)
	end
	scenes.ChildAdded:Connect(watchScene)
	for _, npc in CollectionService:GetTagged("StaticNpc") do
		watchFade(npc)
	end
	CollectionService:GetInstanceAddedSignal("StaticNpc"):Connect(function(npc)
		watchFade(npc)
		task.defer(refreshStatic)
	end)
end

return SceneClient
