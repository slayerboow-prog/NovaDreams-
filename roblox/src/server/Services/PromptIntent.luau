-- PromptIntent (servidor): nada se usa sin que el jugador lo pida de verdad.
--
-- En el móvil (solo pantalla táctil) un cartel solo se activa desde el botón Interactuar / la burbuja
-- de Acciones / la tira (ContextDetector.trigger), y ese camino avisa ANTES al servidor de qué cartel
-- quiere usar (remoto "PromptIntent", "Use", prompt). Los carteles que llevan a algún sitio o te suben
-- a algo (subir a un vehículo, coger uno de alquiler, entrar o salir de una casa, ascensores, subir al
-- autobús, al tren, al metro, al avión o al barco) preguntan aquí: sin ese aviso reciente del mismo
-- jugador para ese cartel, el servidor no hace nada. Así ningún camino que no sea un toque de verdad
-- (una tecla fantasma, un mando, el cartel tocado al girar la cámara…) sube ni mete a nadie en ningún
-- sitio, aunque el cartel llegue a dispararse.
--
-- Con teclado, ratón o mando (E, clic, X) el motor dispara el cartel directamente y no hay aviso: a
-- esos jugadores no se les pide (su ordenador dice al entrar si es solo táctil: "Device"). Un tramposo
-- que diga que no es táctil solo se quita a sí mismo esta protección (no es una regla de seguridad: el
-- resto de comprobaciones —distancia, dueño, esperas— las sigue haciendo cada servicio).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PromptIntent = {}

PromptIntent.Window = 2.5 -- segundos que vale un aviso (más lo que haya que mantener el cartel)
PromptIntent.Grace = 0.5 -- si el disparo llega antes que el aviso (red), se le espera esto

type Intent = { Prompt: Instance?, At: number }
local intents: { [Player]: Intent } = {}
local started = false

-- ¿Vale este aviso para este cartel ahora? (función pura: scripts/test-autointeraccion)
-- state: { TouchOnly, IntentPrompt, IntentAt, Prompt, Hold, Now }
function PromptIntent.check(state: { [string]: any }): boolean
	if state.TouchOnly ~= true then
		return true -- teclado, ratón o mando: el motor solo dispara con su tecla
	end
	if type(state.IntentAt) ~= "number" or type(state.Now) ~= "number" then
		return false
	end
	-- (un cartel concreto: tiene que ser ese; sin cartel conocido, vale cualquier aviso reciente)
	if state.Prompt ~= nil and state.IntentPrompt ~= state.Prompt then
		return false
	end
	local hold = if type(state.Hold) == "number" then math.max(0, state.Hold) else 0
	local age = state.Now - state.IntentAt
	return age >= -0.05 and age <= PromptIntent.Window + hold
end

-- Apunta que el jugador ha pedido usar este cartel (lo llama el remoto; también las pruebas)
function PromptIntent.note(player: Player, prompt: Instance?, now: number?)
	intents[player] = { Prompt = prompt, At = now or os.clock() }
end

local function holdOf(prompt: Instance?): number
	if prompt and prompt:IsA("ProximityPrompt") then
		return (prompt :: ProximityPrompt).HoldDuration
	end
	return 0
end

local function valid(player: Player, prompt: Instance?): boolean
	local intent = intents[player]
	return PromptIntent.check({
		TouchOnly = player:GetAttribute("TouchOnly") == true,
		IntentPrompt = intent and intent.Prompt,
		IntentAt = intent and intent.At,
		Prompt = prompt,
		Hold = holdOf(prompt),
		Now = os.clock(),
	})
end

-- ¿Lo ha pedido de verdad? Se gasta el aviso (un toque, una vez). prompt: el cartel que se ha
-- disparado (nil: cualquier aviso reciente de ese jugador). Puede esperar un momento (Grace).
function PromptIntent.allows(player: Player, prompt: Instance?): boolean
	if player:GetAttribute("TouchOnly") ~= true then
		return true
	end
	local deadline = os.clock() + PromptIntent.Grace
	while not valid(player, prompt) do
		if os.clock() >= deadline or not player.Parent then
			return false
		end
		task.wait(0.05)
	end
	intents[player] = nil
	return true
end

-- Envuelve el manejador de un cartel: solo se ejecuta si el jugador lo ha pedido de verdad
function PromptIntent.gate(prompt: Instance?, handler: (Player, ...any) -> ()): (Player, ...any) -> ()
	return function(player: Player, ...)
		if PromptIntent.allows(player, prompt) then
			handler(player, ...)
		end
	end
end

function PromptIntent.init()
	if started then
		return
	end
	started = true
	local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then
		return
	end
	local remote = remotes:FindFirstChild("PromptIntent") :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = "PromptIntent"
		created.Parent = remotes
		remote = created
	end
	(remote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, kind: any, value: any)
		if kind == "Device" then
			player:SetAttribute("TouchOnly", if value == true then true else nil)
		elseif kind == "Use" then
			if typeof(value) == "Instance" and value:IsA("ProximityPrompt") then
				PromptIntent.note(player, value)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		intents[player] = nil
	end)
end

return PromptIntent
