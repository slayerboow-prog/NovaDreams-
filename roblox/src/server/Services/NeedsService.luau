-- NeedsService: hambre, energía y diversión. Bajan con el tiempo; se recuperan comiendo, durmiendo y
-- jugando. Los valores se envían al cliente como atributos del jugador ("Hunger", "Energy", "Fun").
--
-- 🎈 DIVERSIÓN (Config.Needs.Fun*, Config.Fun): baja despacio; la suben las cosas divertidas
-- (parques, columpios, pícnic, hoguera, deportes, feria, monopatín, karts, pesca, mascotas…).
-- Nunca castiga: por debajo de Config.Needs.FunLow el jugador está «aburrido» (atributo Bored: la
-- experiencia sube un poco más despacio, ProgressionService) y le llega un aviso amable de vez en cuando.
--   NeedsService.addFun(player, cantidad, motivo?) -> lo que ha subido de verdad
--     (con motivo, como mucho Config.Needs.FunReasonCap por minuto de esa actividad)
--   NeedsService.getFun(player) -> 0..100

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local TesterService = require(script.Parent.TesterService)

local NeedsService = {}

-- Reloj (las pruebas lo cambian)
NeedsService._clock = function(): number
	return os.clock()
end

local funWindow: { [Player]: { [string]: { At: number, Sum: number } } } = setmetatable({}, { __mode = "k" }) :: any
local lastHint: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local FUN_HINTS = {
	"🎈 Te aburres un poco. ¿Un rato en el parque? Columpios, pícnic o una pachanga.",
	"🎈 Te apetece algo divertido: saca a pasear a tu mascota o ve a pescar al lago.",
	"🎈 Un poco aburrido… De noche, la hoguera del lago y los malvaviscos animan a cualquiera.",
}

local TICK = 1 -- segundos entre actualizaciones
local MAX = Config.Needs.Max

local function clamp(value: number): number
	return math.clamp(value, 0, MAX)
end

local AIM_WALK = Weapons.Aim.WalkFactor

local function applyWalkSpeed(player: Player)
	local data = DataService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not humanoid then
		return
	end
	-- (Montado en un vehículo NO se toca: al vehículo lo mueve Controllers/Driving, no el andar. Antes
	-- se ponía la velocidad del vehículo y, si el personaje no llegaba a sentarse, corría a 80 a pie.)
	local tired = data.Hunger <= Config.Needs.LowThreshold or data.Energy <= Config.Needs.LowThreshold
	-- La velocidad base depende de la etapa de vida (LifeService); corriendo (ProgressionService) más
	-- rápido mientras dure la estamina (la Destreza suma); apuntando más despacio (WeaponService); con
	-- hambre o sueño se anda más lento, pero corriendo SIEMPRE se va más rápido que andando normal
	-- (Gameplay.walkSpeed)
	local speed = Gameplay.walkSpeed({
		Stage = player:GetAttribute("StageWalkSpeed") or Config.WalkSpeed,
		Sprinting = player:GetAttribute("Sprinting") == true,
		Destreza = player:GetAttribute("Stat_Destreza") or 0,
		Aiming = player:GetAttribute("Aiming") == true,
		Tired = tired,
		TiredWalk = Config.TiredWalkSpeed,
		AimFactor = AIM_WALK,
	})
	-- La velocidad que debe tener (el cliente la mira: si algo suyo la dejó pisada —una carrera que no
	-- acabó bien—, la vuelve a poner; Controllers/Character)
	player:SetAttribute("WalkTarget", math.floor(speed * 100 + 0.5) / 100)
	humanoid.WalkSpeed = speed
end

local function notify(player: Player, kind: string, text: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("Notify")
	if remote then
		(remote :: RemoteEvent):FireClient(player, kind, text)
	end
end

-- Partidas viejas o rotas: sin diversión (o con algo que no es un número) empiezan llenas
local function funOf(data: { [string]: any }): number
	local fun = tonumber(data.Fun)
	if fun == nil or fun ~= fun then
		fun = MAX
	end
	data.Fun = clamp(fun :: number)
	return data.Fun
end

local function sync(player: Player, data: { [string]: any })
	-- Redondeamos para no mandar un cambio de atributo por cada décima
	player:SetAttribute("Hunger", math.floor(data.Hunger + 0.5))
	player:SetAttribute("Energy", math.floor(data.Energy + 0.5))
	local fun = funOf(data)
	player:SetAttribute("Fun", math.floor(fun + 0.5))
	local bored = fun < Config.Needs.FunLow
	if bored ~= (player:GetAttribute("Bored") == true) then
		player:SetAttribute("Bored", if bored then true else nil)
		if bored then
			-- Aviso amable (como mucho uno cada FunHintEvery segundos)
			local now = NeedsService._clock()
			if not lastHint[player] or now - lastHint[player] >= Config.Needs.FunHintEvery then
				lastHint[player] = now
				notify(player, "Info", FUN_HINTS[math.floor(now) % #FUN_HINTS + 1])
			end
		end
	end
	applyWalkSpeed(player)
end

-- Suma (o resta) hambre, energía y (si se dice) diversión.
function NeedsService.change(player: Player, hunger: number, energy: number, fun: number?)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.Hunger = clamp(data.Hunger + hunger)
	data.Energy = clamp(data.Energy + energy)
	if fun then
		data.Fun = clamp(funOf(data) + fun)
	end
	sync(player, data)
end

-- 🎈 Sube la diversión. `reason` (opcional: "Swing", "Kart", "Skate", "Feria"…) limita lo que da una
-- misma actividad a Config.Needs.FunReasonCap por minuto. Devuelve lo que ha subido de verdad.
-- Con una cantidad negativa baja (sin límite). La usan los parques, la hoguera, los deportes, la feria…
function NeedsService.addFun(player: Player, amount: number, reason: string?): number
	local data = DataService.get(player)
	if not data or type(amount) ~= "number" or amount ~= amount or amount == 0 then
		return 0
	end
	if amount > 0 and reason then
		local now = NeedsService._clock()
		local windows = funWindow[player]
		if not windows then
			windows = {}
			funWindow[player] = windows
		end
		local w = windows[reason]
		if not w or now - w.At >= 60 then
			w = { At = now, Sum = 0 }
			windows[reason] = w
		end
		amount = math.min(amount, math.max(0, Config.Needs.FunReasonCap - w.Sum))
		w.Sum += amount
		if amount <= 0 then
			return 0
		end
	end
	local before = funOf(data)
	data.Fun = clamp(before + amount)
	sync(player, data)
	return data.Fun - before
end

function NeedsService.getFun(player: Player): number
	local data = DataService.get(player)
	return if data then funOf(data) else MAX
end

-- ¿Aburrido? (diversión por debajo de Config.Needs.FunLow)
function NeedsService.isBored(player: Player): boolean
	return NeedsService.getFun(player) < Config.Needs.FunLow
end

-- Un paso del reloj de las necesidades (cada TICK segundos; las pruebas lo llaman a mano)
function NeedsService.step(player: Player, seconds: number)
	local data = DataService.get(player)
	if not data or player:GetAttribute("Sleeping") then
		return
	end
	local multiplier = MonetizationService.needsMultiplier(player)
	data.Hunger = clamp(data.Hunger - Config.Needs.HungerPerMinute / 60 * seconds * multiplier)
	-- Sentado en un banco se descansa: la energía sube un poco en vez de bajar
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat and seat.Parent and seat.Parent:HasTag("Bench") then
		data.Energy = clamp(data.Energy + 3 / 60 * seconds)
	else
		data.Energy = clamp(data.Energy - Config.Needs.EnergyPerMinute / 60 * seconds * multiplier)
	end
	-- La diversión baja despacio (sin Metabolismo Pro: no es algo que se compre)
	data.Fun = clamp(funOf(data) - Config.Needs.FunPerMinute / 60 * seconds)
	sync(player, data)
end

-- Vuelve a calcular la velocidad al momento (al empezar o dejar de correr)
function NeedsService.refreshSpeed(player: Player)
	applyWalkSpeed(player)
end

function NeedsService.canWork(player: Player): boolean
	local data = DataService.get(player)
	if data ~= nil and TesterService.bypass(player) then
		return true -- (modo pruebas: se trabaja aunque falte energía o haya hambre)
	end
	return data ~= nil
		and data.Hunger > Config.Needs.CantWorkThreshold
		and data.Energy > Config.Needs.CantWorkThreshold
end

function NeedsService.init()
	DataService.onLoaded(function(player, data)
		sync(player, data)
		player.CharacterAdded:Connect(function()
			task.defer(applyWalkSpeed, player)
		end)
		if player.Character then
			applyWalkSpeed(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				-- Un jugador con error no para las necesidades del resto
				local ok, err = pcall(NeedsService.step, player, TICK)
				if not ok then
					warn("[NeedsService] " .. tostring(err))
				end
			end
		end
	end)
end

return NeedsService
