-- SkateService (servidor): los trucos del Skatepark de la Ribera (zona 10). Puntos y combos en
-- shared/SkateTricks; el sitio, en Kit/ZonasVerdes/Skatepark; los trucos los detecta el cliente
-- (Controllers/OcioClient: saltos al pasar el borde de una rampa, kickflip con su botón, giros y grind).
--
--   * Cada combo que cobras llega aquí (remoto Ocio: "Combo", { Tricks }) y el servidor vuelve a contar
--     los puntos (SkateTricks.sanitize + score): solo en monopatín, dentro del skatepark, y sin más
--     tiempo de aire o de grind del que ha pasado desde el combo anterior.
--   * Diversión por combo (con tope por minuto), algo de experiencia y tu mejor combo (data.Ocio.SkateBest).
--   * Reto de trucos (tag OcioSkateChallenge): «Empezar · Reto de trucos»: 60 s para hacer 6000 puntos;
--     si lo consigues, premio en dinero, diversión y experiencia.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkateTricks = require(ReplicatedStorage.Shared.SkateTricks)
local Sitios = require(ReplicatedStorage.Shared.OcioSitios)
local Format = require(ReplicatedStorage.Shared.Format)
local OcioFun = require(script.Parent.OcioFun)

local SkateService = {}

SkateService.MIN_GAP = 0.3 -- s mínimos entre dos combos
SkateService.KINDS = { Monopatin = true }

type State = { LastCombo: number, FunWindow: number, FunGiven: number, XpGiven: number, Challenge: { Until: number, Score: number }?, Best: number }
local states: { [Player]: State } = {}

local function service(name: string): any
	local ok, svc = pcall(function()
		return require((script.Parent :: any)[name])
	end)
	return if ok and type(svc) == "table" then svc else nil
end

local function now(): number
	return os.clock()
end

local function stateOf(player: Player): State
	local s = states[player]
	if not s then
		s = { LastCombo = now() - 5, FunWindow = now(), FunGiven = 0, XpGiven = 0, Challenge = nil, Best = 0 }
		states[player] = s
	end
	return s
end

function SkateService.riding(player: Player): boolean
	local Vehicles = service("VehicleService")
	local kind = Vehicles and Vehicles.ridingKind and Vehicles.ridingKind(player)
	return kind ~= nil and SkateService.KINDS[kind] == true
end

function SkateService.inPark(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	return Sitios.inside("Skate", character:GetPivot().Position, 10)
end

-- Un combo cobrado por el cliente. Devuelve los puntos que cuentan (0 si no vale).
function SkateService.combo(player: Player, raw: any): number
	if not SkateService.riding(player) or not SkateService.inPark(player) then
		return 0
	end
	local st = stateOf(player)
	local t = now()
	local since = t - st.LastCombo
	if since < SkateService.MIN_GAP then
		return 0
	end
	st.LastCombo = t
	local tricks = SkateTricks.sanitize(if type(raw) == "table" then raw.Tricks else nil, since)
	local _, mult, total = SkateTricks.score(tricks)
	if total <= 0 then
		return 0
	end
	-- Diversión con tope por minuto
	if t - st.FunWindow > 60 then
		st.FunWindow, st.FunGiven, st.XpGiven = t, 0, 0
	end
	local fun = math.min(SkateTricks.FunPerCombo + (if mult >= 3 then 1 else 0), SkateTricks.FunPerMinute - st.FunGiven)
	st.FunGiven += math.max(0, fun)
	-- Experiencia también con tope por minuto (antes, hasta 3 por combo cada 0,3 s)
	local xp = math.clamp(math.min(total // 600, 3, SkateTricks.XpPerMinute - st.XpGiven), 0, 3)
	st.XpGiven += xp
	OcioFun.reward(player, { Fun = math.max(0, fun), Xp = xp, Reason = "Skate", Event = "SkateCombo", Data = { Points = total, Mult = mult } })
	if st.Challenge then
		st.Challenge.Score += total
	end
	-- Mejor combo (de la sesión y guardado)
	if total > st.Best then
		st.Best = total
		local Data = service("DataService")
		local data = Data and Data.get(player)
		if data then
			data.Ocio = if type(data.Ocio) == "table" then data.Ocio else {}
			if total > (tonumber(data.Ocio.SkateBest) or 0) then
				data.Ocio.SkateBest = total
			end
		end
	end
	OcioFun.fire("SkateScore", { Total = total, Mult = mult, Challenge = if st.Challenge then st.Challenge.Score else nil, Goal = SkateTricks.Challenge.Goal }, player)
	return total
end

function SkateService.startChallenge(player: Player): boolean
	local st = stateOf(player)
	if st.Challenge then
		return false
	end
	if not SkateService.riding(player) then
		OcioFun.say(player, "Error", "🛹 Súbete a un monopatín (hay gratis en la entrada del skatepark) y vuelve a pulsar.")
		return false
	end
	local c = SkateTricks.Challenge
	st.Challenge = { Until = now() + c.Seconds, Score = 0 }
	st.LastCombo = now()
	OcioFun.fire("SkateChallenge", { Seconds = c.Seconds, Goal = c.Goal }, player)
	OcioFun.say(player, "Info", ("🛹 ¡Reto de trucos! %d puntos en %d s. Salta en las rampas, pulsa «Kickflip» en el aire y desliza por las barandillas."):format(c.Goal, c.Seconds))
	OcioFun.reward(player, { Event = "OcioPlayed", Data = { Activity = "Skate" } })
	return true
end

function SkateService.endChallenge(player: Player)
	local st = states[player]
	local ch = st and st.Challenge
	if not st or not ch then
		return
	end
	st.Challenge = nil
	local c = SkateTricks.Challenge
	local won = ch.Score >= c.Goal
	OcioFun.fire("SkateChallengeEnd", { Score = ch.Score, Goal = c.Goal, Won = won }, player)
	if won then
		OcioFun.reward(player, { Fun = c.Fun, Money = c.Prize, Xp = c.Xp, Reason = "Skate", Event = "SkateChallenge", Data = { Score = ch.Score, Won = true }, Text = ("🛹 ¡Reto superado! %d puntos"):format(ch.Score) })
		OcioFun.fire("Sound", { Name = "Logro" }, player)
	else
		OcioFun.reward(player, { Fun = 4, Reason = "Skate", Event = "SkateChallenge", Data = { Score = ch.Score, Won = false }, Text = ("🛹 Reto: %d de %d puntos. ¡Otra vez!"):format(ch.Score, c.Goal) })
	end
end

function SkateService.tick()
	local t = now()
	for player, st in states do
		if not player.Parent then
			states[player] = nil
		elseif st.Challenge and t >= st.Challenge.Until then
			SkateService.endChallenge(player)
		end
	end
end

function SkateService.state(player: Player): State
	return stateOf(player)
end

function SkateService.init()
	local remote = OcioFun.remote()
	if remote then
		remote.OnServerEvent:Connect(function(player, kind, data)
			if kind == "Combo" then
				local ok, err = pcall(SkateService.combo, player, data)
				if not ok then
					warn("[Skate] " .. tostring(err))
				end
			end
		end)
	end
	for _, board in CollectionService:GetTagged("OcioSkateChallenge") do
		if board:IsA("BasePart") then
			local p = Instance.new("ProximityPrompt")
			p.ActionText = "Empezar"
			p.ObjectText = ("🛹 Reto de trucos · premio %s"):format(Format.money(SkateTricks.Challenge.Prize))
			p.HoldDuration = 0.2
			p.MaxActivationDistance = 12
			p.RequiresLineOfSight = false
			p.Parent = board
			p.Triggered:Connect(function(player)
				SkateService.startChallenge(player)
			end)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			local ok, err = pcall(SkateService.tick)
			if not ok then
				warn("[Skate] " .. tostring(err))
			end
		end
	end)
end

return SkateService
