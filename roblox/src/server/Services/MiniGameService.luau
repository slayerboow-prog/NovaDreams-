-- MiniGameService: los minijuegos de las misiones (pase, canastas, partido de fútbol…).
--
--   Timing  barra de precisión: pulsa cuando la aguja está en la zona verde.
--           { Game = "Timing", Title, Icon, Rounds = 3, Need = 1, Speed = 1, Zone = 0.22, Shrink = 0 }
--           (Rounds = intentos; Need = aciertos para ganar; Shrink = cuánto se estrecha la zona al acertar)
--   Futbol  partido: jugadas de ataque (pase, regate, tiro) y de defensa (paradas).
--           { Game = "Futbol", Plays = 6, Rival = "Bruno", Position = "Delantero" }
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

type Session = { Token: number, Spec: Spec, Started: number, OnDone: (Result) -> () }

local sessions: { [Player]: Session } = {}
local nextToken = 0

MiniGameService.Games = {
	Timing = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Futbol = { MinSecondsPerRound = 0.8, MaxSeconds = 480 },
}

local function evaluate(spec: Spec, raw: any): Result
	raw = if type(raw) == "table" then raw else {}
	if spec.Game == "Futbol" then
		local plays = spec.Plays or 6
		local goals = math.clamp(math.floor(tonumber(raw.Goals) or 0), 0, plays)
		local against = math.clamp(math.floor(tonumber(raw.Against) or 0), 0, plays)
		return { Won = goals > against, Score = goals, Against = against, Detail = { Draw = goals == against } }
	end
	local rounds = spec.Rounds or 3
	local hits = math.clamp(math.floor(tonumber(raw.Hits) or 0), 0, rounds)
	return { Won = hits >= (spec.Need or 1), Score = hits }
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
		if kind ~= "Result" or not session or token ~= session.Token then
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
		finish(player, session, evaluate(spec, raw))
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return MiniGameService
