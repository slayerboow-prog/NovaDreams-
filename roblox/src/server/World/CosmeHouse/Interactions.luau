-- Interactions (servidor): todo lo que se puede hacer en la casa de Cosme (docs/historia/casa-cosme.md,
-- punto 25). Avisos de proximidad normales (móvil, mando y teclado).
--
--   * Lo de siempre lo hace server/Services/InteractService (shared/Interact): puertas que se abren,
--     sillas, sofás y camas, interruptores de cada habitación, grifos, ducha, ordenadores, armario.
--     Aquí solo se le pide que monte sus avisos dentro de la casa (InteractService.setupWorld).
--   * Los avisos de la casa (atributo CosmeAction, Kit.prompt):
--       Doc / Screen   leer un documento o una pantalla (el cliente lo enseña: Controllers/CosmeHouseClient)
--       Drawer         abrir y cerrar un cajón (se desliza)
--       Safe           la caja fuerte (se abre y dentro hay una pista)
--       Experiment     experimentos: chispazos, portal que falla, cafetera, impresora de comida…
--       Machine        máquinas que se encienden (los anillos giran más, más luz y partículas)
--       Telescope      mirar por el telescopio (cámara en el ocular, en el cliente)
--       Portal         activar el portal gigante (secuencia: CosmeHouse/PortalSystem)
--       PortalDial     cambiar el destino del portal
--       SecretBook     sacar un libro de la estantería secreta (combinación FÍSICA, TIEMPO, LUNA)
--       SecretButton   el botón de dentro de la habitación secreta
--   * Cada cosa avisa a la historia (CosmeHouse/QuestHooks).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local QuestHooks = require(script.Parent.QuestHooks)
local PortalSystem = require(script.Parent.PortalSystem)
local SecretRoom = require(script.Parent.SecretRoom)

local Interactions = {}

local house: Model? = nil
local remote: RemoteEvent? = nil
local notify: RemoteEvent? = nil
local cooldown: { [Player]: { [Instance]: number } } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function say(player: Player, kind: string, text: string?)
	if notify and text and text ~= "" then
		notify:FireClient(player, kind, text)
	end
end

local function findIn(name: string?): Instance?
	if not house or type(name) ~= "string" then
		return nil
	end
	return house:FindFirstChild(name, true)
end

local function tween(part: BasePart, goal: CFrame, seconds: number)
	local ok = pcall(function()
		TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = goal }):Play()
	end)
	if not ok then
		part.CFrame = goal
	end
end

---------------------------------------------------------------------
-- La estantería secreta
---------------------------------------------------------------------
local secretOpen = false
local secretToken = 0
local pulled: { string } = {}
local discovered: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function shelf(): Model?
	return findIn("EstanteriaSecreta") :: Model?
end

-- Gira la estantería sobre su bisagra (abierta: Swing grados hacia dentro de la habitación)
local function swingShelf(open: boolean)
	local m = shelf()
	if not m then
		return
	end
	local hinge = m:GetAttribute("Hinge")
	local swing = m:GetAttribute("Swing") or math.rad(-95)
	if typeof(hinge) ~= "CFrame" then
		return
	end
	local parts: { { Part: BasePart, Rel: CFrame } } = {}
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			local base = d:GetAttribute("ClosedCF")
			if typeof(base) ~= "CFrame" then
				base = d.CFrame
				d:SetAttribute("ClosedCF", base)
			end
			table.insert(parts, { Part = d, Rel = hinge:ToObjectSpace(base) })
		end
	end
	secretOpen = open
	m:SetAttribute("Open", open)
	secretToken += 1
	local token = secretToken
	local from = m:GetAttribute("Angle") or 0
	local to = if open then swing else 0
	task.spawn(function()
		local t0 = os.clock()
		local duration = 1.4
		while token == secretToken do
			local a = math.min(1, (os.clock() - t0) / duration)
			local k = a * a * (3 - 2 * a)
			local angle = from + (to - from) * k
			m:SetAttribute("Angle", angle)
			local frame = hinge * CFrame.Angles(0, angle, 0)
			for _, p in parts do
				p.Part.CFrame = frame * p.Rel
			end
			if a >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

function Interactions.openSecret(open: boolean, seconds: number?)
	swingShelf(open)
	if open and seconds then
		local token = secretToken
		task.delay(seconds, function()
			if token == secretToken and secretOpen then
				swingShelf(false)
			end
		end)
	end
end

function Interactions.isSecretOpen(): boolean
	return secretOpen
end

local function pullBook(player: Player, prompt: ProximityPrompt)
	local book = prompt:GetAttribute("Book")
	local part = prompt.Parent :: BasePart
	if type(book) ~= "string" or not part:IsA("BasePart") or secretOpen then
		return
	end
	-- El libro sale un poco y vuelve
	local base = part:GetAttribute("ClosedCF") or part.CFrame
	part:SetAttribute("ClosedCF", base)
	tween(part, (base :: CFrame) * CFrame.new(0.5, 0, 0), 0.25)
	task.delay(0.8, function()
		if not secretOpen then
			tween(part, base :: CFrame, 0.25)
		end
	end)
	table.insert(pulled, book)
	local combo = SecretRoom.Combination
	local n = #pulled
	if pulled[n] ~= combo[n] then
		pulled = {}
		say(player, "Info", "📕 Clic… Nada. Parece que el orden importa.")
		return
	end
	if n == #combo then
		pulled = {}
		say(player, "Success", "📚 ¡CLAC! La estantería gira sola… Hay una habitación detrás.")
		Interactions.openSecret(true, 40)
		if not discovered[player] then
			discovered[player] = true
			QuestHooks.used(player, "CosmeHabitacionSecreta", "SecretOpened", {})
		end
	else
		say(player, "Info", ("📕 Clic. (%d de %d)"):format(n, #combo))
	end
end

---------------------------------------------------------------------
-- Acciones
---------------------------------------------------------------------
local actions: { [string]: (Player, ProximityPrompt) -> () } = {}

local function showDoc(player: Player, prompt: ProximityPrompt, style: string)
	if remote then
		remote:FireClient(player, "Doc", {
			Title = prompt:GetAttribute("Title") or prompt.ObjectText,
			Text = prompt:GetAttribute("Text") or "",
			Style = style,
		})
	end
	QuestHooks.used(player, prompt:GetAttribute("PropId"), "DocumentRead", {})
end

actions.Doc = function(player, prompt)
	showDoc(player, prompt, "Paper")
end

actions.Screen = function(player, prompt)
	showDoc(player, prompt, "Screen")
end

actions.Drawer = function(player, prompt)
	local part = prompt.Parent
	if not part or not part:IsA("BasePart") then
		return
	end
	local base = part:GetAttribute("ClosedCF")
	if typeof(base) ~= "CFrame" then
		base = part.CFrame
		part:SetAttribute("ClosedCF", base)
	end
	local dir = part:GetAttribute("SlideDir")
	local slide = prompt:GetAttribute("Slide") or 1.4
	local offset = if typeof(dir) == "Vector3" then dir * slide else part.CFrame.LookVector * -slide
	local open = not part:GetAttribute("Open")
	part:SetAttribute("Open", open)
	local goal = if open then (base :: CFrame) + offset else base :: CFrame
	tween(part, goal, 0.35)
	-- Lo que va pegado (tiradores)
	if part.Parent then
		for _, d in part.Parent:GetChildren() do
			if d:IsA("BasePart") and d:GetAttribute("FollowDrawer") == part.Name then
				local hb = d:GetAttribute("ClosedCF")
				if typeof(hb) ~= "CFrame" then
					hb = d.CFrame
					d:SetAttribute("ClosedCF", hb)
				end
				tween(d, if open then (hb :: CFrame) + offset else hb :: CFrame, 0.35)
			end
		end
	end
	prompt.ActionText = if open then "Cerrar el cajón" else "Abrir el cajón"
	if open then
		say(player, "Info", prompt:GetAttribute("Text"))
		QuestHooks.used(player, prompt:GetAttribute("PropId"), nil)
	end
end

actions.Safe = function(player, prompt)
	local door = prompt.Parent
	if not door or not door:IsA("BasePart") then
		return
	end
	local hinge, closed = door:GetAttribute("Hinge"), door:GetAttribute("Closed")
	if typeof(hinge) == "CFrame" and typeof(closed) == "CFrame" then
		local open = not door:GetAttribute("Open")
		door:SetAttribute("Open", open)
		local angle = if open then (door:GetAttribute("Swing") or math.rad(-100)) else 0
		tween(door, hinge * CFrame.Angles(0, angle, 0) * hinge:ToObjectSpace(closed), 0.6)
		prompt.ActionText = if open then "Cerrar la caja fuerte" else "Abrir la caja fuerte"
		if not open then
			return
		end
	end
	showDoc(player, prompt, "Paper")
end

local function burst(target: Instance?, kind: string)
	if target then
		target:SetAttribute("BurstAt", now())
		target:SetAttribute("BurstKind", kind)
	end
end

actions.Experiment = function(player, prompt)
	local effect = prompt:GetAttribute("Effect") or "Zap"
	local target = findIn(prompt:GetAttribute("Target")) or prompt.Parent
	if effect == "MiniPortal" and target then
		target:SetAttribute("ShowUntil", now() + 6)
	elseif effect == "Float" and target then
		target:SetAttribute("BoostUntil", now() + 8)
	elseif effect == "Printer" and prompt.Parent and prompt.Parent:IsA("BasePart") then
		-- Sale una lasaña cuadrada (se va sola)
		local p = Instance.new("Part")
		p.Name = "LasanaImpresa"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = Vector3.new(1, 0.4, 1)
		p.Color = Color3.fromRGB(220, 120, 60)
		p.CFrame = prompt.Parent.CFrame * CFrame.new(0, -1.1, -1.6)
		p:AddTag("Anomaly")
		p.Parent = prompt.Parent.Parent
		game:GetService("Debris"):AddItem(p, 20)
	end
	burst(target, effect)
	say(player, "Info", prompt:GetAttribute("Text"))
	QuestHooks.used(player, prompt:GetAttribute("PropId"), "Experiment", { Effect = effect })
end

actions.Machine = function(player, prompt)
	local target = findIn(prompt:GetAttribute("Target")) or prompt.Parent
	if not target then
		return
	end
	local on = not target:GetAttribute("On")
	target:SetAttribute("On", on)
	burst(target, "Machine")
	prompt.ActionText = if on then "Apagar" else (prompt:GetAttribute("OnText") or "Encender")
	if on then
		say(player, "Info", prompt:GetAttribute("Text"))
		QuestHooks.used(player, prompt:GetAttribute("PropId"), "MachineOn", { Target = target.Name })
	end
end

actions.Telescope = function(player, prompt)
	local aim = prompt:GetAttribute("Aim")
	if remote and typeof(aim) == "CFrame" then
		remote:FireClient(player, "Telescope", { Aim = aim })
	end
	QuestHooks.used(player, prompt:GetAttribute("PropId"), "TelescopeUsed", {})
end

local function portalOf(prompt: ProximityPrompt): Model?
	local p = findIn(prompt:GetAttribute("Target"))
	return if p and p:IsA("Model") then p else nil
end

actions.Portal = function(player, prompt)
	local portal = portalOf(prompt)
	if not portal then
		return
	end
	local started = PortalSystem.activate(portal, function(dest)
		local handled = QuestHooks.portalPeak(player, dest.Id)
		if not handled then
			say(player, "Info", ("🌀 El portal se abre hacia «%s»… y se queda ahí, mirándote. (Cosme dice que aún no se puede cruzar.)"):format(dest.Name))
		end
	end)
	if started then
		say(player, "Info", "⚡ ¡Portal activándose! Agárrate a algo.")
		QuestHooks.used(player, prompt:GetAttribute("PropId"), nil)
	end
end

actions.PortalDial = function(player, prompt)
	local portal = portalOf(prompt)
	if not portal or portal:GetAttribute("Active") then
		return
	end
	local dest = PortalSystem.cycle(portal)
	say(player, "Info", "🧭 Destino: " .. dest.Name)
end

actions.SecretBook = function(player, prompt)
	pullBook(player, prompt)
end

actions.SecretButton = function(player, _prompt)
	Interactions.openSecret(not secretOpen, if secretOpen then nil else 40)
	say(player, "Info", if secretOpen then "🔴 La estantería se abre." else "🔴 La estantería se cierra.")
end

function Interactions.handle(player: Player, prompt: ProximityPrompt)
	local kind = prompt:GetAttribute("CosmeAction")
	local fn = type(kind) == "string" and actions[kind]
	if not fn then
		return
	end
	local mine = cooldown[player]
	if not mine then
		mine = setmetatable({}, { __mode = "k" }) :: any
		cooldown[player] = mine
	end
	local t = os.clock()
	if mine[prompt] and t - mine[prompt] < 0.8 then
		return
	end
	mine[prompt] = t
	local ok, err = pcall(fn, player, prompt)
	if not ok then
		warn("[CasaCosme] " .. tostring(err))
	end
end

function Interactions.connect(prompt: ProximityPrompt)
	if prompt:GetAttribute("Connected") then
		return
	end
	prompt:SetAttribute("Connected", true)
	prompt.Triggered:Connect(function(player)
		Interactions.handle(player, prompt)
	end)
end

function Interactions.start(model: Model)
	house = model
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
		local r = remotes:FindFirstChild("CosmeHouse")
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = "CosmeHouse"
			r.Parent = remotes
		end
		remote = r :: RemoteEvent
	end
	-- Muebles de siempre (puertas, sillas, luces…): InteractService
	pcall(function()
		local InteractService = require(script.Parent.Parent.Parent.Services.InteractService) :: any
		if InteractService.setupWorld then
			InteractService.setupWorld(model)
		end
	end)
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("CosmeAction") then
			Interactions.connect(d)
		end
	end
	model.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") and d:GetAttribute("CosmeAction") then
			Interactions.connect(d)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		cooldown[player] = nil
	end)
end

return Interactions
