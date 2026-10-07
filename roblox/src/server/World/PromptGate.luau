-- PromptGate (servidor): UNA pulsación, UNA acción. Si en el mismo instante llegan varios carteles de
-- un jugador (tres «Hablar» de la familia a 3 studs: Mamá, Papá y la abuela hablaban a la vez con un
-- solo toque), solo cuenta uno: el primero que llega (el del foco, el más cercano: el cliente solo
-- pulsa ese); los demás se descartan.
--
--   PromptGate.run(player, at, fn)  -- en el Triggered del cartel: at = dónde está el cartel
--
-- El primero se hace al momento; los que llegan detrás en el mismo momento (Gap) no cuentan.
-- Lo usan los carteles de hablar de la familia (BabyService) y de los actores de la historia
-- (SceneService). Se prueba en scripts/test-familyhome.luau.

local PromptGate = {}

PromptGate.Gap = 0.15 -- segundos en los que otro cartel del mismo jugador cuenta como la misma pulsación (llegan en el mismo paquete; dos toques de verdad van más separados)

local lastRun: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any

function PromptGate.run(player: any, at: Vector3?, fn: () -> ())
	local now = os.clock()
	if lastRun[player] and now - lastRun[player] < PromptGate.Gap then
		return -- (la misma pulsación ya hizo algo: este cartel no cuenta)
	end
	lastRun[player] = now
	local ok, err = pcall(fn)
	if not ok then
		warn("[PromptGate] " .. tostring(err))
	end
end

-- Dónde está un cartel (su pieza o su adjunto)
function PromptGate.positionOf(prompt: Instance): Vector3?
	local ok, at = pcall(function()
		local parent = prompt.Parent
		if parent and parent:IsA("BasePart") then
			return (parent :: BasePart).CFrame.Position
		elseif parent and parent:IsA("Attachment") then
			return (parent :: Attachment).WorldPosition
		end
		return nil
	end)
	return if ok then at else nil
end

return PromptGate
