-- MiniGameService: los minijuegos de las misiones (pase, canastas, partido de fútbol…).
--
--   Timing  barra de precisión: pulsa cuando la aguja está en la zona verde.
--           { Game = "Timing", Title, Icon, Rounds = 3, Need = 1, Speed = 1, Zone = 0.22, Shrink = 0 }
--           (Rounds = intentos; Need = aciertos para ganar; Shrink = cuánto se estrecha la zona al acertar)
--   Futbol  partido: jugadas de ataque (pase, regate, tiro) y de defensa (paradas).
--           { Game = "Futbol", Plays = 6, Rival = "Bruno", Position = "Delantero" }
--   Penaltis, Pases  (y Futbol): se juegan DE VERDAD en el campo más cercano con FootballService
--           (balón, porteros y compañeros de la máquina; Sports/FootballStory dice qué campos lleva
--           cada paso). Si no hay campo cerca o el servicio no puede, se juega el panel de siempre:
--           Penaltis y Pases como Timing (Rounds, Need, Zone) y Futbol por jugadas.
--   Canastas, Baloncesto  igual, en la canasta más cercana con BasketService (Sports/BasketStory);
--           sin canasta cerca, como Timing.
--
-- El cliente (MiniGameUI) lo juega y manda el resultado; aquí se comprueba que sea posible
-- (tiempo mínimo, valores dentro de rango) y se decide si se ganó. Nunca bloquea la historia:
-- si el cliente no contesta, cuenta como no ganado.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MiniGameService = {}

local Remote: RemoteEvent

export type Spec = { [string]: any }
export type Result = { Won: boolean, Score: number, Against: number?, Detail: { [string]: any }? }

type Session = { Token: number, Spec: Spec, Started: number, OnDone: (Result) -> (), Sport: boolean? }

local sessions: { [Player]: Session } = {}
local nextToken = 0

MiniGameService.Games = {
	Timing = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Futbol = { MinSecondsPerRound = 0.8, MaxSeconds = 480 },
	Penaltis = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Pases = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Canastas = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Baloncesto = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
}

-- Los deportes de verdad: qué servicio juega cada uno (se carga al usarlo por primera vez)
local FootballStory = require(ReplicatedStorage.Shared.Sports.FootballStory)
local BasketStory = require(ReplicatedStorage.Shared.Sports.BasketStory)
local SPORTS: { [string]: { Story: any, Service: string } } = {}
for game in FootballStory.Games do
	SPORTS[game] = { Story = FootballStory, Service = "FootballService" }
end
for game in BasketStory.Games do
	SPORTS[game] = { Story = BasketStory, Service = "BasketService" }
end
local loaded: { [string]: any } = {}
local function sport(game: string?): (any, any)
	local entry = game and SPORTS[game]
	if not entry then
		return nil, nil
	end
	if loaded[entry.Service] == nil then
		local ok, svc = pcall(function()
			return require((script.Parent :: any)[entry.Service])
		end)
		loaded[entry.Service] = if ok and type(svc) == "table" then svc else false
	end
	return loaded[entry.Service] or nil, entry.Story
end

-- elapsed: segundos desde que empezó. El resultado lo manda el cliente: aquí al menos se comprueba
-- que sea posible (cada jugada da como mucho un gol, para uno u otro) y que haya dado tiempo a
-- jugar lo que dice haber jugado; si no, no cuenta como ganado.
-- Número limpio del cliente: sin NaN ni infinitos (0/0 pasa tonumber y math.clamp y llegaría a los datos)
local function safeNumber(x: any): number
	local n = tonumber(x) or 0
	if n ~= n or n == math.huge or n == -math.huge then
		n = 0
	end
	return n
end

local function evaluate(spec: Spec, raw: any, elapsed: number): Result
	raw = if type(raw) == "table" then raw else {}
	local rules = MiniGameService.Games[spec.Game]
	if spec.Game == "Futbol" then
		local plays = spec.Plays or 6
		local goals = math.clamp(math.floor(safeNumber(raw.Goals)), 0, plays)
		local against = math.clamp(math.floor(safeNumber(raw.Against)), 0, plays)
		if goals + against > plays then
			return { Won = false, Score = 0, Against = plays, Detail = { Draw = false } }
		end
		-- (el tiempo mínimo del partido ya se mira al recibir el resultado)
		return { Won = goals > against, Score = goals, Against = against, Detail = { Draw = goals == against } }
	end
	local rounds = spec.Rounds or 3
	local hits = math.clamp(math.floor(safeNumber(raw.Hits)), 0, rounds)
	-- Cada acierto es una ronda jugada: tiene que haber dado tiempo a jugarlas
	local played = elapsed >= rules.MinSecondsPerRound * math.max(hits, 1)
	return { Won = played and hits >= (spec.Need or 1), Score = hits }
end

local function finish(player: Player, session: Session, result: Result)
	if sessions[player] ~= session then
		return
	end
	sessions[player] = nil
	task.spawn(session.OnDone, result)
end

function MiniGameService.isRunning(player: Player): boolean
	return sessions[player] ~= nil
end

-- Empieza un minijuego; onDone recibe el resultado. Devuelve false si no se pudo.
function MiniGameService.start(player: Player, spec: Spec, onDone: (Result) -> ()): boolean
	local rules = MiniGameService.Games[spec.Game]
	if not rules or sessions[player] then
		return false
	end
	nextToken += 1
	local session: Session = { Token = nextToken, Spec = spec, Started = os.clock(), OnDone = onDone }
	sessions[player] = session
	-- Fútbol de verdad, si hay campo; el resultado lo decide el servidor (no hace falta comprobarlo)
	local svc, SportStory = sport(spec.Game)
	if svc and SportStory and svc.startStory then
		session.Sport = true
		local ok, started = pcall(svc.startStory, player, spec, function(result: Result)
			finish(player, session, result)
		end)
		if ok and started then
			task.delay(SportStory.maxSeconds(spec), function()
				if sessions[player] == session then
					pcall(svc.stopStory, player) -- (lo que haya ahora: la historia nunca se queda parada)
					if sessions[player] == session then
						finish(player, session, SportStory.result(spec, nil, false))
					end
				end
			end)
			return true
		end
		if not ok then
			warn("[MiniGame] Fútbol de verdad: " .. tostring(started))
		end
		session.Sport = false
	end
	Remote:FireClient(player, "Start", { Token = session.Token, Spec = spec })
	task.delay(rules.MaxSeconds, function()
		if sessions[player] == session then
			finish(player, session, { Won = false, Score = 0 })
		end
	end)
	return true
end

function MiniGameService.cancel(player: Player)
	local session = sessions[player]
	if session then
		sessions[player] = nil
		if session.Sport then
			local svc = sport(session.Spec.Game)
			if svc and svc.cancelStory then
				pcall(svc.cancelStory, player)
			end
			return
		end
		Remote:FireClient(player, "Cancel", { Token = session.Token })
	end
end

function MiniGameService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remote = remotes:FindFirstChild("MiniGame") :: RemoteEvent
	if not Remote then
		Remote = Instance.new("RemoteEvent")
		Remote.Name = "MiniGame"
		Remote.Parent = remotes
	end
	Remote.OnServerEvent:Connect(function(player, kind, token, raw)
		local session = sessions[player]
		if kind ~= "Result" or not session or token ~= session.Token or session.Sport then
			return
		end
		local spec = session.Spec
		local rules = MiniGameService.Games[spec.Game]
		local rounds = spec.Rounds or spec.Plays or 3
		-- Demasiado rápido para haberlo jugado: no cuenta como ganado (pero la historia sigue)
		if os.clock() - session.Started < rules.MinSecondsPerRound * rounds * 0.5 then
			finish(player, session, { Won = false, Score = 0 })
			return
		end
		finish(player, session, evaluate(spec, raw, os.clock() - session.Started))
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return MiniGameService
