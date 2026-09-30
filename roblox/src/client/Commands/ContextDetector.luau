-- ContextDetector: qué tiene el jugador delante y en qué situación está, para que el menú de
-- comandos ofrezca lo que tiene sentido AHORA.
--
-- Todas las interacciones del mapa son ProximityPrompt (los pone el servidor). Aquí:
--   * se hace que todos los carteles cercanos estén disponibles a la vez (Exclusivity = AlwaysShow,
--     solo en este dispositivo), así el menú puede listarlos todos;
--   * se clasifica cada uno (persona, puerta, vehículo, tienda, colegio, objeto…) para darle icono;
--   * se elige el "foco": el cartel que dispara la tecla E / el botón del mando. Es el comando
--     seleccionado en el menú (o, si no hay ninguno, el más cercano). Los demás carteles que usan
--     la misma tecla se quedan sin tecla mientras tanto, para que E nunca haga dos cosas a la vez.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local MenuLogic = require(script.Parent.MenuLogic)

local ContextDetector = {}

export type Target = {
	Prompt: ProximityPrompt,
	Kind: string, -- "Npc", "Door", "Vehicle", "Shop", "School", "Item", "Seat", "Job", "Other"
	Icon: string,
	Label: string, -- lo que hace ("Hablar", "Entrar"…)
	Detail: string, -- con quién o con qué ("Marta", "Tienda"…)
	Distance: number,
}

local player = Players.LocalPlayer
local shown: { [ProximityPrompt]: boolean } = {}
local originalKeys: { [ProximityPrompt]: { Keyboard: Enum.KeyCode, Gamepad: Enum.KeyCode } } = {}
local focus: ProximityPrompt? = nil
local listeners: { () -> () } = {}
local lastOrder: { any } = {} -- el orden de la última vez (para que la lista no baile)

-- Nombre del icono de cada tipo (UI/Icons: imagen subida o emoji que se ve en todos los móviles)
local ICONS = {
	Npc = "hablar",
	Door = "puerta",
	Vehicle = "bici",
	Car = "coche",
	Shop = "tienda",
	School = "escuela",
	Item = "interactuar",
	Seat = "asiento",
	Food = "comida",
	Bed = "cama",
	Job = "trabajo",
	Other = "lugar",
}

-- Palabras que delatan qué es cada cosa (en el texto del cartel, sin tildes)
local KEYWORDS = {
	{ Kind = "Npc", Words = { "hablar", "saludar", "preguntar", "conversar" } },
	{ Kind = "Door", Words = { "entrar", "salir", "puerta", "abrir", "cerrar", "llamar", "ascensor" } },
	{ Kind = "Car", Words = { "conducir", "coche", "moto", "camion", "furgoneta", "taxi", "autobus" } },
	{ Kind = "Vehicle", Words = { "montar", "subir", "bici", "monopatin", "patinete", "bajar" } },
	{ Kind = "Shop", Words = { "comprar", "tienda", "pagar", "caja", "pedir", "vender", "taquilla" } },
	{ Kind = "School", Words = { "clase", "colegio", "cole", "instituto", "aula", "examen", "estudiar", "pupitre" } },
	{ Kind = "Food", Words = { "comer", "beber", "desayunar", "cenar", "cocinar", "comida", "fruta" } },
	{ Kind = "Bed", Words = { "dormir", "descansar", "cama" } },
	{ Kind = "Seat", Words = { "sentar", "silla", "banco" } },
	{ Kind = "Job", Words = { "trabajar", "turno", "repartir", "atender", "cobrar", "patrullar", "apagar" } },
	{ Kind = "Item", Words = { "coger", "recoger", "guardar", "usar", "abrir", "mirar", "examinar" } },
}

local ACCENTS = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n" }
local function plain(text: string): string
	local lower = string.lower(text)
	for accented, letter in ACCENTS do
		lower = string.gsub(lower, accented, letter)
	end
	return lower
end

local function adornee(prompt: ProximityPrompt): BasePart?
	local parent = prompt.Parent
	if parent and parent:IsA("BasePart") then
		return parent
	elseif parent and parent:IsA("Attachment") then
		return parent.Parent :: BasePart?
	elseif parent and parent:IsA("Model") then
		return parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function worldPosition(prompt: ProximityPrompt): Vector3?
	local parent = prompt.Parent
	if parent and parent:IsA("Attachment") then
		return parent.WorldPosition
	end
	local part = adornee(prompt)
	return part and part.Position
end

local function kindOf(prompt: ProximityPrompt): string
	-- Una persona: el cartel cuelga de un modelo con Humanoid
	local node: Instance? = prompt.Parent
	for _ = 1, 4 do
		if not node or node == workspace then
			break
		end
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return "Npc"
		end
		node = node.Parent
	end
	local text = plain(prompt.ActionText .. " " .. prompt.ObjectText)
	for _, rule in KEYWORDS do
		for _, word in rule.Words do
			if string.find(text, word, 1, true) then
				return rule.Kind
			end
		end
	end
	return "Other"
end

local function notify()
	for _, listener in listeners do
		task.spawn(listener)
	end
end

-- Llama a callback cuando cambia lo que hay alrededor (aparece o desaparece un cartel, cambia la edad…)
function ContextDetector.onChanged(callback: () -> ())
	table.insert(listeners, callback)
end

local function prepare(instance: Instance)
	if instance:IsA("ProximityPrompt") then
		-- Todos los carteles cercanos a la vez: el menú los lista y elige cuál va con la E
		instance.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	end
end

-- Los carteles disponibles ahora mismo, del más cercano al más lejano
function ContextDetector.targets(): { Target }
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local from = root and root.Position
	local list: { Target } = {}
	local stale = {}
	for prompt in shown do
		local at = worldPosition(prompt)
		local distance = if from and at then (at - from).Magnitude else math.huge
		-- Solo lo que se puede usar de verdad: los carteles que se quedaron "a la vista" al apagarse los
		-- carteles en una conversación (sin aviso de que se ocultaban), los de personajes que tu escena
		-- oculta o los que ya están lejos no salen (antes salía "Hablar" con alguien lejano u oculto)
		local ok = MenuLogic.usable({
			Exists = prompt.Parent ~= nil and prompt:IsDescendantOf(workspace),
			Enabled = prompt.Enabled,
			ServiceEnabled = ProximityPromptService.Enabled,
			Distance = distance,
			Max = prompt.MaxActivationDistance,
		})
		if ok then
			local kind = kindOf(prompt)
			table.insert(list, {
				Prompt = prompt,
				Kind = kind,
				Icon = ICONS[kind] or ICONS.Other,
				Label = if prompt.ActionText ~= "" then prompt.ActionText else "Interactuar",
				Detail = prompt.ObjectText,
				Distance = distance,
			})
		elseif not prompt.Parent or distance > prompt.MaxActivationDistance + 30 then
			table.insert(stale, prompt)
		end
	end
	for _, prompt in stale do
		shown[prompt] = nil
	end
	-- Del más cercano al más lejano, sin bailar (MenuLogic.orderTargets)
	local ordered, keys = MenuLogic.orderTargets(lastOrder, list, function(target: Target)
		return target.Prompt
	end)
	lastOrder = keys
	-- Lo importante delante (tornos del metro antes que ratas o interfonos: atributo PromptPriority)
	return MenuLogic.byPriority(ordered, function(target: Target)
		local priority = target.Prompt:GetAttribute("PromptPriority")
		return if type(priority) == "number" then priority else 0
	end)
end

-- Todo lo que el menú necesita saber para decidir qué comandos enseñar
function ContextDetector.get(): { [string]: any }
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local targets = ContextDetector.targets()
	return {
		Targets = targets,
		Target = targets[1],
		Stage = player:GetAttribute("LifeStage"),
		Age = player:GetAttribute("AgeYears"),
		Job = player:GetAttribute("Job") or player:GetAttribute("Role"),
		Seated = humanoid ~= nil and humanoid.SeatPart ~= nil,
		Money = player:GetAttribute("Money"),
		Busy = player:GetAttribute("InDialogue") == true,
		Weapon = player:GetAttribute("Weapon"),
		Aiming = player:GetAttribute("Aiming") == true,
	}
end

-- El cartel que va con la E (y con el botón del mando). nil = el más cercano.
function ContextDetector.setFocus(prompt: ProximityPrompt?)
	if prompt == nil then
		local first = ContextDetector.targets()[1]
		prompt = first and first.Prompt
	end
	focus = prompt
	local focusKeys = prompt and originalKeys[prompt]
	for other, keys in originalKeys do
		if other.Parent then
			-- Solo pierden la tecla los que comparten tecla con el foco (el súper usa varias teclas a propósito)
			local clashKeyboard = other ~= prompt and focusKeys ~= nil and keys.Keyboard == focusKeys.Keyboard
			local clashGamepad = other ~= prompt and focusKeys ~= nil and keys.Gamepad == focusKeys.Gamepad
			other.KeyboardKeyCode = if clashKeyboard then Enum.KeyCode.Unknown else keys.Keyboard
			other.GamepadKeyCode = if clashGamepad then Enum.KeyCode.Unknown else keys.Gamepad
		end
	end
end

function ContextDetector.getFocus(): ProximityPrompt?
	return focus
end

-- Dispara un cartel como si se hubiera pulsado su tecla (mantiene pulsado si hace falta)
function ContextDetector.trigger(prompt: ProximityPrompt)
	-- (desde el menú o el botón Interactuar: nunca en una conversación, ni con carteles lejanos u ocultos)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local at = worldPosition(prompt)
	local ok = MenuLogic.usable({
		Exists = prompt.Parent ~= nil,
		Enabled = prompt.Enabled,
		ServiceEnabled = ProximityPromptService.Enabled,
		Busy = player:GetAttribute("InDialogue") == true,
		Distance = if root and at then (at - root.Position).Magnitude else nil,
		Max = prompt.MaxActivationDistance,
	})
	if not ok then
		return
	end
	prompt:InputHoldBegin()
	task.delay(prompt.HoldDuration + 0.05, function()
		prompt:InputHoldEnd()
	end)
end

function ContextDetector.icons(): { [string]: string }
	return ICONS
end

function ContextDetector.init()
	for _, instance in workspace:GetDescendants() do
		prepare(instance)
	end
	workspace.DescendantAdded:Connect(prepare)
	ProximityPromptService.PromptShown:Connect(function(prompt)
		shown[prompt] = true
		if not originalKeys[prompt] then
			originalKeys[prompt] = { Keyboard = prompt.KeyboardKeyCode, Gamepad = prompt.GamepadKeyCode }
		end
		notify()
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		shown[prompt] = nil
		-- Al alejarse, el cartel recupera su tecla de siempre
		local keys = originalKeys[prompt]
		if keys and prompt.Parent then
			prompt.KeyboardKeyCode = keys.Keyboard
			prompt.GamepadKeyCode = keys.Gamepad
		end
		originalKeys[prompt] = nil
		if focus == prompt then
			focus = nil
		end
		notify()
	end)
	for _, attribute in { "LifeStage", "InDialogue", "Job", "Role", "Weapon", "Aiming" } do
		player:GetAttributeChangedSignal(attribute):Connect(notify)
	end
end

return ContextDetector
