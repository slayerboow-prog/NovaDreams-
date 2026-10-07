-- PromptGuard (cliente): que los carteles de "pulsa E" no vuelvan a abrir una conversación sin querer.
--
-- En el móvil, el mismo toque que pasa una línea de diálogo ("Toca para seguir"), mueve la cámara o
-- cierra la conversación podía caer encima del botón "Hablar" de un personaje y volver a empezar a
-- hablar con él, una y otra vez. Por eso:
--   * Durante una conversación o una cinemática, todos los carteles apagados (como antes)… y siguen
--     apagados un momento (Grace) DESPUÉS de cerrarse.
--   * K.O. o caído en el suelo (atributos KO / Fallen), todos los carteles apagados: no se sube a un
--     coche, al metro, al tren ni al autobús para escapar del remate o de la detención (el servidor
--     también lo rechaza: RideState.downed).
--   * Al hablar con alguien (un cartel de hablar), ese cartel se apaga un rato (TalkCooldown) y no vuelve
--     mientras esté su globo de diálogo en pantalla (Baby.isSaying) ni el segundo de después.
-- (El servidor tiene además sus propias esperas: SchoolService / LifeStoryService.Guard.)

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local PromptGuard = {}

PromptGuard.Grace = 1 -- segundos con los carteles apagados después de una conversación
PromptGuard.TalkCooldown = 3 -- segundos (mínimo) con el cartel de hablar apagado después de usarlo
PromptGuard.SayGrace = 1 -- …y hasta que pase esto desde que se fue el globo de diálogo

-- ¿Carteles apagados? (busy: conversación o cinemática; busyEndedAt: cuándo acabó la última)
function PromptGuard.locked(busy: boolean, busyEndedAt: number, now: number): boolean
	return busy or now - busyEndedAt < PromptGuard.Grace
end

-- ¿Está en el suelo? (K.O. o caído: se le apagan los carteles)
function PromptGuard.downed(who: any): boolean
	if who == nil then
		return false
	end
	local ok, down = pcall(function()
		return who:GetAttribute("KO") == true or who:GetAttribute("Fallen") ~= nil
	end)
	return ok and down == true
end

-- ¿Es un cartel de hablar con alguien? (cuelga de un personaje, o dice "Hablar")
function PromptGuard.isTalk(actionText: string?, onCharacter: boolean): boolean
	local text = string.lower(actionText or "")
	return onCharacter or string.find(text, "hablar", 1, true) ~= nil or string.find(text, "saludar", 1, true) ~= nil
end

-- ¿Puede volver a encenderse un cartel de hablar? (offUntil: fin de su espera; saying: hay globo)
function PromptGuard.release(offUntil: number, now: number, saying: boolean): boolean
	return now >= offUntil and not saying
end

local function onCharacter(prompt: ProximityPrompt): boolean
	local node: Instance? = prompt.Parent
	for _ = 1, 4 do
		if not node or node == workspace then
			return false
		end
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return true
		end
		node = node.Parent
	end
	return false
end

-- isBusy(): ¿conversación o cinemática? isSaying(grace): ¿globo de diálogo en pantalla?
function PromptGuard.init(isBusy: () -> boolean, isSaying: (number) -> boolean)
	local player = Players.LocalPlayer
	local busyEndedAt = -math.huge
	local off: { [ProximityPrompt]: number } = {}
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
		if who ~= player or not PromptGuard.isTalk(prompt.ActionText, onCharacter(prompt)) then
			return
		end
		off[prompt] = os.clock() + PromptGuard.TalkCooldown
		prompt:SetAttribute("GuardOff", true) -- (solo en esta pantalla)
		prompt.Enabled = false
	end)
	local nextCheck = 0
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local busy = isBusy() or PromptGuard.downed(player)
		if busy then
			busyEndedAt = now
		end
		local enabled = not PromptGuard.locked(busy, busyEndedAt, now)
		if ProximityPromptService.Enabled ~= enabled then
			ProximityPromptService.Enabled = enabled
		end
		if now < nextCheck then
			return
		end
		nextCheck = now + 0.2
		local saying = isSaying(PromptGuard.SayGrace)
		for prompt, untilAt in off do
			if not prompt.Parent then
				off[prompt] = nil
			elseif PromptGuard.release(untilAt, now, saying) then
				off[prompt] = nil
				prompt:SetAttribute("GuardOff", nil)
				-- (si tu escena oculta a ese personaje, su cartel sigue apagado: SceneClient)
				prompt.Enabled = not prompt:GetAttribute("SceneHidden")
			end
		end
	end)
end

return PromptGuard
