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
--
-- Cortar sin resultado (cancel): el juego se acaba del todo (servidor y cliente: el deporte recoge su
-- campo y el marcador se va) y el paso de la misión NO cuenta como jugado: onCancel(motivo) avisa a
-- quien lo empezó (LifeStoryService) para que el paso se pueda repetir luego. Se corta solo:
--   · "Escena": empieza una conversación o una escena de cámara (InDialogue / InScene) en mitad del
--     juego. Lo que pidió el dueño: «le pasé la pelota a Mateo, empecé otra misión y la de Mateo
--     sigue» (el marcador de los pases seguía arriba encima de la narración de la escena nueva).
--   · "Away": te fuiste del campo (el deporte lo da por abandonado): antes contaba como perdido y la
--     misión seguía por el camino de perder; ahora se repite al volver.
--   · y lo que pida quien lo empezó: "OtraMision" (sigues otra misión), "Died", "reset"…

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MiniGameService = {}

local Remote: RemoteEvent

export type Spec = { [string]: any }
export type Result = { Won: boolean, Score: number, Against: number?, Detail: { [string]: any }? }

type Session = {
	Token: number,
	Spec: Spec,
	Started: number,
	OnDone: (Result) -> (),
	OnCancel: ((string) -> ())?,
	Sport: boolean?,
	Clear: boolean?, -- (ya se vio sin conversación ni escena desde que empezó)
}

local sessions: { [Player]: Session } = {}
local nextToken = 0

MiniGameService.Games = {
	Timing = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Futbol = { MinSecondsPerRound = 0.8, MaxSeconds = 480 },
	Penaltis = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Pases = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Canastas = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Baloncesto = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Carrera = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Relevo = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
	Voley = { MinSecondsPerRound = 0.4, MaxSeconds = 240 },
}

-- Los deportes de verdad: qué servicio juega cada uno (se carga al usarlo por primera vez)
local FootballStory = require(ReplicatedStorage.Shared.Sports.FootballStory)
local BasketStory = require(ReplicatedStorage.Shared.Sports.BasketStory)
local RaceStory = require(ReplicatedStorage.Shared.Sports.RaceStory)
local VolleyStory = require(ReplicatedStorage.Shared.Sports.VolleyStory)
local SPORTS: { [string]: { Story: any, Service: string } } = {}
for game in FootballStory.Games do
	SPORTS[game] = { Story = FootballStory, Service = "FootballService" }
end
for game in BasketStory.Games do
	SPORTS[game] = { Story = BasketStory, Service = "BasketService" }
end
for game in RaceStory.Games do
	SPORTS[game] = { Story = RaceStory, Service = "RaceService" }
end
for game in VolleyStory.Games do
	SPORTS[game] = { Story = VolleyStory, Service = "VolleyService" }
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

-- Lo que juega ahora (o nil)
function MiniGameService.current(player: Player): Spec?
	local session = sessions[player]
	return session and session.Spec
end

-- Cortado sin resultado: quien lo empezó se entera (el paso se repetirá)
local function cancelled(session: Session, reason: string)
	local onCancel = session.OnCancel
	if onCancel then
		task.spawn(onCancel, reason)
	end
end

-- ¿Hay ahora una conversación o una escena de cámara? (InDialogue lo pone DialogueService e InScene
-- CinematicService; los dos llegan aquí)
local function inScene(player: Player): boolean
	local ok, value = pcall(function()
		return player:GetAttribute("InDialogue") == true or player:GetAttribute("InScene") == true
	end)
	return ok and value == true
end
MiniGameService.inScene = inScene

-- Empieza un minijuego; onDone recibe el resultado. Devuelve false si no se pudo. onCancel (opcional):
-- si se corta sin resultado (MiniGameService.cancel, una escena, te fuiste del campo), con el motivo.
function MiniGameService.start(player: Player, spec: Spec, onDone: (Result) -> (), onCancel: ((string) -> ())?): boolean
	local rules = MiniGameService.Games[spec.Game]
	if not rules or sessions[player] then
		return false
	end
	nextToken += 1
	local session: Session = { Token = nextToken, Spec = spec, Started = os.clock(), OnDone = onDone, OnCancel = onCancel, Clear = not inScene(player) }
	sessions[player] = session
	-- Fútbol de verdad, si hay campo; el resultado lo decide el servidor (no hace falta comprobarlo)
	local svc, SportStory = sport(spec.Game)
	if svc and SportStory and svc.startStory then
		session.Sport = true
		local ok, started = pcall(svc.startStory, player, spec, function(result: Result)
			-- Te fuiste del campo (o saliste del juego a medias): no cuenta como perdido, el paso se
			-- repite (el deporte ya ha recogido el campo). Si te has ido del servidor, da igual.
			local detail = result and result.Detail
			if detail and detail.Abandoned == true and onCancel and player.Parent ~= nil and sessions[player] == session then
				sessions[player] = nil
				cancelled(session, "Away")
				return
			end
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

-- Corta el minijuego sin resultado (no cuenta ni como ganado ni como perdido): el deporte recoge el
-- campo (y el marcador se va en tu pantalla) o el panel se cierra. reason: por qué (para onCancel).
function MiniGameService.cancel(player: Player, reason: string?)
	local session = sessions[player]
	if session then
		sessions[player] = nil
		if session.Sport then
			local svc = sport(session.Spec.Game)
			if svc and svc.cancelStory then
				pcall(svc.cancelStory, player)
			end
		elseif Remote then
			Remote:FireClient(player, "Cancel", { Token = session.Token })
		end
		cancelled(session, reason or "Cancel")
	end
end

-- Una pasada del vigilante: si en mitad de un juego empieza una conversación o una escena, el juego se
-- corta (solo si ya se vio sin ella desde que empezó: la escena que lo presentaba aún puede estar
-- cerrándose). Devuelve los jugadores a los que se les cortó.
function MiniGameService.watch(): { Player }
	local cut = {}
	for player, session in sessions do
		-- (solo los que saben repetirse: los que llevan onCancel, como los pasos de las misiones; los
		-- de la cárcel, sin él, siguen como siempre)
		if not session.OnCancel then
			continue
		end
		if inScene(player) then
			if session.Clear then
				table.insert(cut, player)
			end
		else
			session.Clear = true
		end
	end
	for _, player in cut do
		MiniGameService.cancel(player, "Escena")
	end
	return cut
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
	task.spawn(function()
		while true do
			task.wait(0.5)
			local ok, err = pcall(MiniGameService.watch)
			if not ok then
				warn("[MiniGame] " .. tostring(err))
			end
		end
	end)
end

return MiniGameService
