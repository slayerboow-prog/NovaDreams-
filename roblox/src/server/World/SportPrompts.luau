-- SportPrompts (servidor): los carteles «Jugar» de los deportes, para que empezar a jugar se vea.
--
-- Antes, para jugar al baloncesto o al fútbol había que pisar la pista y encontrar un botón pequeño
-- «Jugar» en la columna de la izquierda (en el móvil, debajo de la linterna): el dueño estaba en el
-- gimnasio del colegio, con los balones a los pies, y no supo cómo jugar. Ahora cada pista y cada
-- campo llevan carteles de proximidad (en el aro, en el centro y en los balones que hay en ellos):
--   * Ordenador: «[E] Jugar · Baloncesto» encima.
--   * Móvil: el botón grande del racimo pasa a «Jugar» con el icono del deporte (CommandMenu).
-- Se apagan solos (en tu pantalla) mientras juegas (SportInput.watchPrompts, cliente).
--
--   SportPrompts.folder(name)                          carpeta en workspace para los anclajes
--   SportPrompts.anchor(folder, name, position)        pieza invisible donde colgar un cartel
--   SportPrompts.attach(part, spec, onTriggered)       el cartel (uno por pieza y deporte: no se repite)
--
-- spec = { Sport = "Baloncesto", Action = "Jugar", Object = "Baloncesto", Distance = 10 }
-- onTriggered(player, part): lo pasa por PromptGate (una pulsación, una acción).

local CollectionService = game:GetService("CollectionService")

local PromptGate = require(script.Parent.PromptGate)

local SportPrompts = {}

SportPrompts.TAG = "SportPrompt" -- (los carteles llevan esta etiqueta y el atributo Sport)

function SportPrompts.folder(name: string): Folder
	local existing = workspace:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = workspace
	return f
end

function SportPrompts.anchor(folder: Instance, name: string, position: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(1, 1, 1)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = CFrame.new(position)
	p.Parent = folder
	return p
end

function SportPrompts.attach(part: BasePart, spec: { [string]: any }, onTriggered: (Player, BasePart) -> ()): ProximityPrompt
	local name = "Jugar" .. tostring(spec.Sport)
	local existing = part:FindFirstChild(name)
	if existing and existing:IsA("ProximityPrompt") then
		existing:Destroy() -- (un nuevo escaneo del mapa: el cartel se rehace con la pista de ahora)
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = spec.Action or "Jugar"
	prompt.ObjectText = spec.Object or tostring(spec.Sport)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = spec.Distance or 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("Sport", spec.Sport)
	prompt.Parent = part
	CollectionService:AddTag(prompt, SportPrompts.TAG)
	prompt.Triggered:Connect(function(player: Player)
		PromptGate.run(player, part.CFrame.Position, function()
			onTriggered(player, part)
		end)
	end)
	return prompt
end

return SportPrompts
