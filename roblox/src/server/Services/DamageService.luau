-- DamageService: TODO el daño por puntos pasa por aquí y lo decide el servidor.
--
--   DamageService.apply(attacker, target, amount, kind, part?, info?) -> Result
--     attacker: el jugador que hace daño (nil = un enemigo de misión que te atrapa)
--     target:   el modelo (o el jugador) que lo recibe
--     amount:   puntos (para "Bullet": Weapons.damageAt con cabeza/miembros/distancia; para el resto,
--               lo que diga shared/EnemyStats: botón de atacar, cuerpo a cuerpo, piedras, juguetes)
--     kind:     "Bullet" | "Toy" | "Attack" | "Gadget" | "Melee" | "MeleeHeavy" | "Power" | "Stone" | "Enemy"
--
--   * Enemigos de misión (MissionEnemy: cucarachas, Petra…): solo los daña su dueño, vivo y en pie;
--     el daño se calcula aquí (shared/EnemyStats) y lo apunta la misión (gancho enemyHit, que pone
--     LifeStoryService: la vida va en el progreso del paso y en los atributos EnemyHealth /
--     EnemyMaxHealth del modelo). A los 0 puntos el enemigo CAE y cuenta para la misión.
--   * Personas (jugadores, rivales de entrenamiento, agentes, paseantes): el camino de siempre,
--     CombatService.applyHit (K.O., rematar, muerte y hospital, delitos, zonas seguras).
--   * Tú, atrapado por un enemigo de misión (hurtPlayer): te quita su daño; a 0 caes en combate
--     (gancho playerFell de la misión: reintentar el paso).
-- Al que hace daño le llega el remoto "Damage" (números flotantes, destello y barra de vida en
-- Controllers/HealthBars). El cliente NUNCA aplica daño: este remoto no escucha nada del cliente.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyStats = require(ReplicatedStorage.Shared.EnemyStats)
local MissionCombat = require(ReplicatedStorage.Shared.MissionCombat)

local DamageService = {}

export type Result = { Hit: boolean, Amount: number, Down: boolean, Health: number?, Max: number?, Immune: boolean? }
export type Info = { Zone: string?, At: Vector3?, Weapon: string?, Direction: Vector3? }

-- Ganchos que pone LifeStoryService (los enemigos son de la misión)
--   enemyHit(attacker, model, kind, amount, info) -> (contado, daño hecho, vida, máx, caído, inmune)
DamageService.enemyHit = nil :: ((Player, Model, string, number, Info) -> (boolean, number?, number?, number?, boolean?, boolean?))?

local Remote: RemoteEvent? = nil
local NONE: Result = { Hit = false, Amount = 0, Down = false }

local function combatService(): any
	return require(script.Parent.CombatService)
end

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- ¿Puede hacer daño este jugador ahora? (vivo, sin estar K.O. ni caído)
local function canAttack(attacker: Player): boolean
	if attacker:GetAttribute("Dead") or attacker:GetAttribute("KO") or attacker:GetAttribute("Fallen") then
		return false
	end
	local character = attacker.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- Avisa al cliente del que pega (y solo a él: cada uno ve su combate)
local function tell(attacker: Player?, payload: { [string]: any })
	if attacker and Remote then
		Remote:FireClient(attacker, "Damage", payload)
	end
end

-- Avisa al que pega de un daño que ya ha aplicado la misión (el botón de atacar, el arma de la barra)
function DamageService.notify(attacker: Player, model: any, payload: { [string]: any })
	if typeof(model) ~= "Instance" then
		return
	end
	payload.Target = model
	tell(attacker, payload)
end

-- Daño a un enemigo de misión
local function hitEnemy(attacker: Player?, model: Model, amount: number, kind: string, info: Info): Result
	if not attacker or model:GetAttribute("Owner") ~= attacker.UserId or not canAttack(attacker) then
		return NONE -- (solo su dueño; los demás ni lo ven)
	end
	if model:GetAttribute("EnemyDown") then
		return NONE
	end
	local hook = DamageService.enemyHit
	if not hook then
		return NONE
	end
	local ok, counted, dealtRaw, health, max, down, immune = pcall(hook, attacker, model, kind, amount, info)
	if not ok then
		warn("[Daño] " .. tostring(counted))
		return NONE
	end
	if not counted then
		return NONE
	end
	local dealt = if finite(dealtRaw) then dealtRaw :: number else 0
	tell(attacker, {
		Target = model,
		Amount = dealt,
		Zone = info.Zone,
		At = info.At,
		Health = health,
		Max = max,
		Down = down == true,
		Immune = immune == true,
		Kind = kind,
	})
	return { Hit = true, Amount = dealt, Down = down == true, Health = health, Max = max, Immune = immune == true }
end

-- La función central: alguien (o algo) hace `amount` puntos de daño de tipo `kind` a `target`
function DamageService.apply(attacker: Player?, target: Instance?, amount: number?, kind: string, part: BasePart?, info: Info?): Result
	if typeof(target) ~= "Instance" then
		return NONE
	end
	local i: Info = info or {}
	if part and not i.Zone then
		local Weapons = require(ReplicatedStorage.Shared.Weapons)
		i.Zone = Weapons.zoneOf(part.Name)
	end
	local n = if finite(amount) then math.clamp(amount :: number, 0, EnemyStats.MaxPerHit) else 0
	local model: Instance? = target
	if target:IsA("Player") then
		model = (target :: Player).Character
	end
	if not model or not model:IsA("Model") then
		return NONE
	end
	if MissionCombat.isEnemy(model) then
		return hitEnemy(attacker, model :: Model, n, kind, i)
	end
	if kind == "Enemy" then
		local victim = Players:GetPlayerFromCharacter(model)
		if victim then
			local down = DamageService.hurtPlayer(victim, n)
			return { Hit = true, Amount = n, Down = down }
		end
		return NONE
	end
	if not attacker then
		return NONE
	end
	-- Personas: el camino de siempre (CombatService)
	local ok, result = pcall(combatService().applyHit, attacker, model, {
		Amount = n,
		Direction = i.Direction,
		Weapon = i.Weapon,
		Toy = kind == "Toy",
		At = i.At,
		Zone = i.Zone,
		Heavy = kind == "MeleeHeavy" or n >= 40,
	})
	if ok and type(result) == "table" then
		return { Hit = result.Hit == true, Amount = result.Amount or 0, Down = result.KO == true }
	end
	return NONE
end

---------------------------------------------------------------------
-- Tú, recibiendo daño de un enemigo de misión
---------------------------------------------------------------------

-- Lo que pasa si caes (lo pone LifeStoryService: reintentar el combate)
DamageService.playerFell = nil :: ((Player) -> ())?

-- Te quita `amount` puntos. Devuelve true si has caído en combate (te quedas con 1 de vida: caer no
-- es morir; la misión decide qué pasa: reintentar el paso)
function DamageService.hurtPlayer(victim: Player, amount: number): boolean
	if not finite(amount) or amount <= 0 or victim:GetAttribute("Fallen") or victim:GetAttribute("Dead") then
		return false
	end
	local character = victim.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local after = humanoid.Health - math.floor(amount + 0.5)
	if after > 0 then
		humanoid.Health = after
		return false
	end
	humanoid.Health = 1
	DamageService.fall(victim, "Mission")
	return true
end

-- Caído en combate: en el suelo (KO) con la pantalla «HAS CAÍDO EN COMBATE» (Controllers/DeathUI).
-- how = "Mission" (se reintenta el paso) o "Combat" (te levantas o te rematan: CombatService)
function DamageService.fall(victim: Player, how: string)
	victim:SetAttribute("Fallen", how)
	victim:SetAttribute("KO", true)
	local hook = DamageService.playerFell
	if how == "Mission" and hook then
		task.spawn(function()
			local ok, err = pcall(hook, victim)
			if not ok then
				warn("[Daño] " .. tostring(err))
			end
		end)
	end
end

-- Te levantas (reintentas el combate)
function DamageService.getUp(victim: Player, heal: boolean?)
	victim:SetAttribute("Fallen", nil)
	victim:SetAttribute("KO", nil)
	if heal then
		local character = victim.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = humanoid.MaxHealth
		end
	end
end

function DamageService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local found = remotes:FindFirstChild("Damage")
	if not found then
		found = Instance.new("RemoteEvent")
		found.Name = "Damage"
		found.Parent = remotes
	end
	Remote = found :: RemoteEvent
	-- (sin OnServerEvent: el cliente solo recibe; el daño lo deciden los servicios)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("Fallen", nil)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			player:SetAttribute("Fallen", nil)
		end)
	end
end

return DamageService
