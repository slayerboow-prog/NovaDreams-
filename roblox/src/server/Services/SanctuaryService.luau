-- SanctuaryService: el SANTUARIO DEL BOSQUE jugable (18-11-2026, el dueño: «el árbol no debe ser solo decorativo:
-- un guardián NPC, misiones, un punto de interacción, la activación del núcleo, una historia propia, recompensas y
-- conexión con mazmorras»). El santuario lo construye World/RegionLandmarks (etiqueta SantuarioBosque).
--
--   * El GUARDIÁN DEL ÁRBOL (Eldran, un viejo guardián de túnica azul) espera junto al altar del núcleo.
--   * La misión «EL SANTUARIO PERDIDO» (nivel 25+ para activar el núcleo):
--       1. Habla con el Guardián del Árbol
--       2. Despierta las 3 runas perdidas (los altares de la plaza: atributo RunaSantuario)
--       3. Derrota 10 bestias del Bosque Etéreo (BeastKilled con Region = BosqueEtereo)
--       4. Activa el núcleo del árbol (el altar a sus pies: atributo AltarNucleo; nivel 25)
--     Al terminar: dinero, experiencia, madera etérea, pociones y el título «Guardián del Bosque»; el núcleo late
--     para todos un rato y el guardián cuenta lo que hay bajo la Cueva Susurrante (la mazmorra que viene).
--   * El estado se guarda en data.Santuario = { Step, Runes = { [n] = true }, Kills, Done } y se publica en el
--     atributo SantuarioQuest (JSON: Title, Step, Count) para el panel de misiones (UI/Hud).

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DataService = require(script.Parent.DataService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local SanctuaryService = {}

SanctuaryService.Title = "El Santuario Perdido"
SanctuaryService.CoreLevel = 25
SanctuaryService.KillsNeeded = 10
SanctuaryService.Rewards = { Money = 6000, Xp = 2500, Items = { MaderaEterea = 5, PocionCuracion = 5, PocionEspiritu = 5 } }

local STEPS = {
	"Habla con el Guardián del Árbol",
	"Despierta las runas perdidas de los altares",
	"Derrota bestias del Bosque Etéreo",
	"Activa el núcleo del Árbol Ancestral (nivel 25)",
}

local Notify: RemoteEvent? = nil

local function tell(player: Player, kind: string, text: string)
	if Notify then
		Notify:FireClient(player, kind, text)
	end
end

local function service(name: string): any?
	local ok, mod = pcall(function()
		return require(script.Parent[name]) :: any
	end)
	return if ok then mod else nil
end

local function stateOf(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local s = data.Santuario
	if type(s) ~= "table" then
		s = { Step = 0, Runes = {}, Kills = 0, Done = false }
		data.Santuario = s
	end
	s.Runes = if type(s.Runes) == "table" then s.Runes else {}
	return s
end

local function runesDone(s: { [string]: any }): number
	local n = 0
	for _, v in s.Runes do
		if v then
			n += 1
		end
	end
	return n
end

function SanctuaryService.publish(player: Player)
	local s = stateOf(player)
	if not s then
		return
	end
	if s.Done or s.Step == 0 then
		player:SetAttribute("SantuarioQuest", nil)
		return
	end
	local count = if s.Step == 2 then ("%d / 3"):format(runesDone(s)) elseif s.Step == 3 then ("%d / %d"):format(s.Kills or 0, SanctuaryService.KillsNeeded) else "0 / 1"
	player:SetAttribute("SantuarioQuest", HttpService:JSONEncode({ Title = SanctuaryService.Title, Step = STEPS[s.Step] or "", Count = count }))
end

local function advance(player: Player, s: { [string]: any }, to: number, text: string?)
	s.Step = to
	SanctuaryService.publish(player)
	if text then
		tell(player, "Success", text)
	end
end

---------------------------------------------------------------------
-- El guardián
---------------------------------------------------------------------
local function talk(player: Player)
	local s = stateOf(player)
	local Dialogue = service("DialogueService")
	if not s or not Dialogue or (Dialogue.isBusy and Dialogue.isBusy(player)) then
		return
	end
	local lines
	if s.Done then
		lines = {
			{ S = "Narrador", T = "Eldran mira el núcleo, que late despacio dentro del tronco." },
			{ S = "Narrador", T = "«Bajo la Cueva Susurrante, las raíces llegan a algo que no es de este mundo. Cuando estés listo, baja. Pero no bajes solo.»" },
		}
	elseif s.Step == 0 then
		lines = {
			{ S = "Narrador", T = "Un anciano de túnica azul se apoya en un bastón junto al altar. Sus ojos brillan con la misma luz que el árbol." },
			{ S = "Narrador", T = "«Soy Eldran, el último guardián del Árbol. Mil años velando su sueño. Desde la Caída, el núcleo se apaga.»" },
			{ S = "Narrador", T = "«Tres runas lo mantenían despierto. Están en los altares de la plaza, frías. Despiértalas.»" },
			{ S = "Narrador", T = "«Y las bestias que la Grieta trajo muerden sus raíces. Ahuyéntalas. Después, pon la mano en el altar del núcleo.»" },
		}
		advance(player, s, 2, "📜 Misión: " .. SanctuaryService.Title)
	elseif s.Step == 2 then
		lines = { { S = "Narrador", T = ("«Las runas, guerrero. %d de 3 despiertas. Toca los altares de la plaza.»"):format(runesDone(s)) } }
	elseif s.Step == 3 then
		lines = { { S = "Narrador", T = ("«Las bestias siguen mordiendo las raíces. %d de %d. Sigue.»"):format(s.Kills or 0, SanctuaryService.KillsNeeded) } }
	else
		lines = { { S = "Narrador", T = "«Ya está todo listo. Pon la mano en el altar del núcleo, a los pies del árbol.»" } }
	end
	Dialogue.play(player, { Lines = lines }, {})
end

local function spawnGuardian(model: Instance)
	local cf = model:GetAttribute("Guardian")
	if typeof(cf) ~= "CFrame" then
		return
	end
	local okN, Npc = pcall(function()
		return require(script.Parent.Parent.World.Npc) :: any
	end)
	if not okN then
		return
	end
	local ok, npc = pcall(Npc.create, "GuardianDelArbol", model, cf, { Skin = Color3.fromRGB(230, 200, 170), Shirt = Color3.fromRGB(40, 70, 140), Pants = Color3.fromRGB(30, 50, 100) })
	if not ok or not npc then
		return
	end
	pcall(Npc.placeFeet, npc, cf)
	pcall(Npc.icon, npc, "❗")
	local root = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Hablar"
		prompt.ObjectText = "Eldran, Guardián del Árbol"
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
		prompt.Triggered:Connect(talk)
		-- el nombre encima
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(220, 40)
		gui.StudsOffset = Vector3.new(0, 4.2, 0)
		gui.MaxDistance = 120
		gui.Parent = root
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(150, 220, 255)
		label.TextStrokeTransparency = 0.4
		label.Text = "Eldran · Guardián del Árbol"
		label.Parent = gui
	end
end

---------------------------------------------------------------------
-- Las runas y el núcleo
---------------------------------------------------------------------
local function touchRune(player: Player, part: BasePart)
	local s = stateOf(player)
	local n = part:GetAttribute("RunaSantuario")
	if not s or type(n) ~= "number" then
		return
	end
	if s.Step ~= 2 then
		tell(player, "Info", if s.Step < 2 then "La runa está fría. Quizá el guardián sepa algo." else "Esta runa ya brilla.")
		return
	end
	if s.Runes[tostring(n)] then
		tell(player, "Info", "Esta runa ya está despierta.")
		return
	end
	s.Runes[tostring(n)] = true
	-- (la runa se enciende para quien la despierta: el cliente ve el brillo; aquí, una chispa para todos)
	part.Color = Color3.fromRGB(110, 210, 255)
	local done = runesDone(s)
	if done >= 3 then
		advance(player, s, 3, "✨ Las tres runas brillan. Ahora, ahuyenta a las bestias del Bosque Etéreo.")
	else
		SanctuaryService.publish(player)
		tell(player, "Success", ("✨ Runa despierta (%d / 3)"):format(done))
	end
end

local function pulseCore(core: BasePart)
	local model = core:FindFirstAncestorOfClass("Model")
	local tree = model and model.Parent and model.Parent:FindFirstChild("ArbolAncestral")
	local nucleo = tree and tree:FindFirstChild("Nucleo") :: BasePart?
	if nucleo then
		local big = TweenService:Create(nucleo, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), { Size = nucleo.Size * 2.2, Transparency = 0 })
		big:Play()
		local burst = Instance.new("ParticleEmitter")
		burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		burst.Color = ColorSequence.new(Color3.fromRGB(150, 230, 255))
		burst.LightEmission = 1
		burst.Size = NumberSequence.new(2, 0)
		burst.Speed = NumberRange.new(20, 50)
		burst.Lifetime = NumberRange.new(1, 2)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Parent = nucleo
		burst:Emit(120)
		task.delay(3, function()
			burst:Destroy()
		end)
	end
end

local function activateCore(player: Player, part: BasePart)
	local s = stateOf(player)
	if not s then
		return
	end
	if s.Done then
		tell(player, "Info", "El núcleo late tranquilo. El árbol te reconoce.")
		return
	end
	if s.Step ~= 4 then
		tell(player, "Info", "El altar no responde. Habla con el Guardián del Árbol.")
		return
	end
	if (tonumber(player:GetAttribute("Level")) or 1) < SanctuaryService.CoreLevel then
		tell(player, "Error", ("El núcleo te rechaza: necesitas nivel %d."):format(SanctuaryService.CoreLevel))
		return
	end
	s.Done = true
	s.Step = 5
	pulseCore(part)
	local R = SanctuaryService.Rewards
	DataService.addMoney(player, R.Money, true)
	local P = service("ProgressionService")
	if P and P.addXp then
		pcall(P.addXp, player, R.Xp, "Santuario")
	end
	local Inv = service("InventoryService")
	if Inv then
		for id, n in R.Items do
			pcall(Inv.add, player, id, n)
		end
	end
	player:SetAttribute("TituloGuardianBosque", true)
	SanctuaryService.publish(player)
	tell(player, "Success", ("🌳 ¡El Árbol Ancestral despierta! +%d € · +%d XP · madera etérea y pociones · título «Guardián del Bosque»"):format(R.Money, R.Xp))
end

local function onKill(player: Player, ev: { [string]: any })
	local s = stateOf(player)
	if not s or s.Step ~= 3 or ev.Region ~= "BosqueEtereo" then
		return
	end
	s.Kills = (tonumber(s.Kills) or 0) + 1
	if s.Kills >= SanctuaryService.KillsNeeded then
		advance(player, s, 4, "🌳 Las raíces respiran. Vuelve al santuario y activa el núcleo.")
	else
		SanctuaryService.publish(player)
	end
end

local function setup(model: Instance)
	if model:GetAttribute("SantuarioListo") then
		return
	end
	model:SetAttribute("SantuarioListo", true)
	spawnGuardian(model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and type(d:GetAttribute("RunaSantuario")) == "number" then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Despertar la runa"
			prompt.ObjectText = "Altar antiguo"
			prompt.HoldDuration = 1.2
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Parent = d
			prompt.Triggered:Connect(function(player)
				touchRune(player, d)
			end)
		elseif d:IsA("BasePart") and d:GetAttribute("AltarNucleo") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Activar el núcleo"
			prompt.ObjectText = "Altar del Árbol Ancestral"
			prompt.HoldDuration = 2
			prompt.MaxActivationDistance = 16
			prompt.RequiresLineOfSight = false
			prompt.Parent = d
			prompt.Triggered:Connect(function(player)
				activateCore(player, d)
			end)
		end
	end
end

function SanctuaryService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	StoryEvents.connect(function(player, name, payload)
		if name == "BeastKilled" then
			onKill(player, payload)
		end
	end)
	for _, m in CollectionService:GetTagged("SantuarioBosque") do
		task.spawn(setup, m)
	end
	CollectionService:GetInstanceAddedSignal("SantuarioBosque"):Connect(function(m)
		task.spawn(setup, m)
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			for _ = 1, 30 do
				task.wait(2)
				if not player.Parent then
					return
				end
				if DataService.get(player) then
					SanctuaryService.publish(player)
					return
				end
			end
		end)
	end)
end

-- (pruebas)
SanctuaryService._talk = talk
SanctuaryService._touchRune = touchRune
SanctuaryService._activateCore = activateCore
SanctuaryService._onKill = onKill
SanctuaryService._state = stateOf

return SanctuaryService
