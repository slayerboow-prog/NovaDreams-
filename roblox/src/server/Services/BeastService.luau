-- BeastService: las BESTIAS de los planetas, sus jefes escondidos y los alijos (datos en shared/Cosmos/Bestiary;
-- cómo son en World/Kit/BeastKit; lo que sueltan sirve para fabricar: shared/Crafting, Services/CraftingService).
--
--   * Las guaridas, la del jefe y los alijos los pone World/PlanetWorld al construir el planeta
--     (BeastService.buildWilds). Las bestias salen solo en las guaridas con alguien cerca (Bestiary.Active) y se
--     recogen cuando no queda nadie (Bestiary.Despawn): así no gastan nada en un planeta vacío.
--   * Cada bestia ronda su guarida; si ve a alguien a pie (Aggro) lo persigue hasta su correa (Leash) y le
--     muerde. El daño que te llega lo baja tu armadura (shared/Crafting.damageTaken). A 0 caes en combate y
--     te levantas a los pocos segundos con algo de vida (nada de hospital por una bestia).
--   * Se les pega con lo de siempre: golpes (CombatService → beastHit) y balas (WeaponService → applyHit →
--     beastHit). Llevan InvasionTarget = "Bestia:<n>" para que la puntería, los golpes y la policía las traten
--     como criaturas, y el atributo Bestia (la especie) para que el daño venga aquí y no a la invasión.
--   * Al caer, cada uno que le ha hecho daño de verdad (≥ 15 %, o el último golpe) se lleva su botín a la
--     mochila (Bestiary.loot) y su dinero. El jefe: un pisotón de área que avisa antes, aviso a todo el
--     planeta al caer y vuelve a los 20 minutos.
--   * Alijos: «Abrir alijo» una vez cada 20 horas por jugador (data.Crafting.Caches).
-- Todo lo decide el servidor; el cliente solo ve modelos y avisos.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Bestiary = require(ReplicatedStorage.Shared.Cosmos.Bestiary)
local PlanetRegistry = require(ReplicatedStorage.Shared.Cosmos.PlanetRegistry)
local Combat = require(ReplicatedStorage.Shared.Combat)
local Crafting = require(ReplicatedStorage.Shared.Crafting)
local Items = require(ReplicatedStorage.Shared.Items)

local BeastService = {}

BeastService.Tick = 0.2
BeastService.MaxPerPlanet = 60
BeastService.GetUpSeconds = 7
BeastService.BulletMul = 1.5 -- las armas de fuego contra las bestias (como con los enemigos de misión, algo menos)
BeastService.BossTakes = 0.7 -- el jefe encaja menos
BeastService.BiteCooldown = 1.4

type Beast = {
	N: number,
	Model: Model,
	Root: BasePart,
	Humanoid: Humanoid,
	Species: string,
	Sp: { [string]: any },
	Planet: string,
	S: any,
	Lair: { [string]: any },
	Home: Vector3,
	Hp: number,
	Max: number,
	Damage: { [Player]: number },
	Hit: number?,
	Reward: number?,
	Target: Player?,
	NextWander: number,
	NextBite: number,
	NextStomp: number,
	Dead: boolean,
	LastSeen: number,
	Announced: boolean?,
	Static: boolean?, -- (una esquirla de la Grieta: no se mueve ni muerde)
	Waves: { [number]: boolean }?,
	Tier: number?,
}

local beasts: { [Model]: Beast } = {}
local byLair: { [string]: { Beast } } = {}
local respawnAt: { [string]: { number } } = {} -- (por guarida: cuándo vuelve cada bestia que cayó)
local serial = 0
local built: { [string]: { S: any, Folder: Instance } } = {}
local warned: { [Player]: { [string]: boolean } } = {}
local Notify: RemoteEvent? = nil

local function now(): number
	return os.clock()
end

local function tell(player: Player, kind: string, text: string)
	if Notify then
		Notify:FireClient(player, kind, text)
	end
end

local function dataOf(player: Player): { [string]: any }?
	local ok, data = pcall(function()
		return (require(script.Parent.DataService) :: any).get(player)
	end)
	return if ok then data else nil
end

local function craftData(data: { [string]: any }): { [string]: any }
	data.Crafting = data.Crafting or {}
	local c = data.Crafting
	c.Caches = c.Caches or {}
	c.Kills = c.Kills or {}
	c.Bosses = c.Bosses or {}
	return c
end

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	return root, hum
end

-- ¿Se le puede atacar? (a pie, vivo, sin estar caído; ni en la nave ni en un vehículo)
local function huntable(player: Player): boolean
	if player:GetAttribute("Fallen") or player:GetAttribute("Dead") or player:GetAttribute("KO") then
		return false
	end
	local root, hum = rootOf(player)
	return root ~= nil and hum ~= nil and hum.Health > 0 and hum.SeatPart == nil
end

---------------------------------------------------------------------
-- Construir guaridas, jefe y alijos (lo llama PlanetWorld al construir el planeta)
---------------------------------------------------------------------
function BeastService.buildWilds(S: any, folder: Instance): Instance?
	if not S or not Bestiary.ByPlanet[S.Id] then
		return nil
	end
	local existing = folder:FindFirstChild("Salvaje")
	if existing then
		return existing
	end
	local BeastKit = require(script.Parent.Parent.World.Kit.BeastKit) :: any
	local root = Instance.new("Folder")
	root.Name = "Salvaje"
	root.Parent = folder
	local O = S.Origin
	local places = Bestiary.places(S)
	local function cfAt(lx: number, lz: number, top: number?): CFrame
		local y = if top then O.Y + top else S.heightAt(O.X + lx, O.Z + lz)
		-- (mirando hacia el centro del planeta: la boca de la guarida da hacia donde viene la gente)
		local dir = Vector3.new(-lx, 0, -lz)
		local yaw = math.atan2(-dir.X, -dir.Z)
		return CFrame.new(O.X + lx, y, O.Z + lz) * CFrame.Angles(0, yaw + math.pi, 0)
	end
	local function islet(l: { [string]: any }, radius: number)
		if l.Islet then
			BeastKit.islet(root, cfAt(l.X, l.Z, l.Y), radius, (S.WaterY or 0) - 30)
		end
	end
	for _, lair in places.Lairs do
		islet(lair, 34)
		BeastKit.lair(root, lair, cfAt(lair.X, lair.Z, if lair.Islet then lair.Y else nil))
	end
	if places.Boss then
		islet(places.Boss, 60)
		BeastKit.lair(root, places.Boss, cfAt(places.Boss.X, places.Boss.Z, if places.Boss.Islet then places.Boss.Y else nil))
	end
	for _, c in places.Caches do
		islet(c, 10)
		BeastKit.cache(root, c, cfAt(c.X, c.Z, if c.Islet then c.Y else nil))
	end
	-- los carteles de cada zona de caza, junto a los senderos (donde empieza cada anillo)
	local trails = S.Trails
	local core = S.CoreHalf or S.Half
	if trails and not Bestiary.WaterLairs[S.Id] then
		local inner, outer = core * 0.74, S.Half - 440
		local rings = #Bestiary.Zones - 1
		local step = (outer - inner) / rings
		for k = 1, 4 do
			for tier = 1, #Bestiary.Zones do
				local rr = if tier == 1 then trails.R0 + 30 else inner + (tier - 2) * step + 20
				if rr < trails.R1 then
					local tx, tz = trails.point(k, rr)
					local a = trails.angleAt(k, rr)
					local sx, sz = tx + math.sin(a) * 14, tz - math.cos(a) * 14
					local z = Bestiary.Zones[tier]
					pcall(BeastKit.zoneSign, root, cfAt(sx, sz), ("%s · nv. %d"):format(z.Name, z.Level), tier)
				end
			end
		end
	end
	-- ruinas de antes de la Grieta, repartidas por las tierras salvajes
	do
		local r = Random.new((S.Seed or 7) * 131)
		local made = 0
		for _ = 1, 400 do
			if made >= 10 then
				break
			end
			local a = r:NextNumber(0, math.pi * 2)
			local rr = r:NextNumber(core * 0.8, S.Half - 460)
			local lx, lz = math.cos(a) * rr, math.sin(a) * rr
			if S.goodSpot(lx, lz, 0.35, 40) and not (trails and trails.at(lx, lz)) then
				made += 1
				pcall(BeastKit.ruin, root, cfAt(lx, lz), Bestiary.LairLook and Bestiary.LairLook[S.Id] or nil, made * 977 + math.floor(rr))
			end
		end
	end
	built[S.Id] = { S = S, Folder = folder }
	return root
end

---------------------------------------------------------------------
-- Sacar y recoger bestias
---------------------------------------------------------------------
local function beastFolder(planet: string): Instance
	local b = built[planet]
	local f = b and b.Folder:FindFirstChild("Bestias")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Bestias"
		f.Parent = if b then b.Folder else workspace
	end
	return f :: Instance
end

local function setHp(b: Beast)
	local hp = math.max(0, math.floor(b.Hp + 0.5))
	b.Model:SetAttribute("Hp", hp)
	b.Model:SetAttribute("EnemyHealth", hp)
end

local function spawnAt(S: any, lair: { [string]: any }): Beast?
	local sp = Bestiary.Species[lair.Species]
	if not sp then
		return nil
	end
	local BeastKit = require(script.Parent.Parent.World.Kit.BeastKit) :: any
	serial += 1
	local model: Model = BeastKit.beast(sp, lair.Species)
	local O = S.Origin
	local a = math.random() * math.pi * 2
	local d = if lair.Boss then 4 else 6 + math.random() * (if lair.Islet then 8 else 12)
	local lx, lz = lair.X + math.cos(a) * d, lair.Z + math.sin(a) * d
	local ground = if lair.Islet then O.Y + lair.Y else S.heightAt(O.X + lx, O.Z + lz)
	local root = model.PrimaryPart :: BasePart
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	model:PivotTo(CFrame.new(O.X + lx, ground + hum.HipHeight + root.Size.Y / 2 + 0.5, O.Z + lz) * CFrame.Angles(0, math.random() * 6.28, 0))
	-- (zona de caza: cuanto más lejos de la ciudad, más nivel)
	local zone = Bestiary.zone(lair.Tier)
	local boss = sp.Boss == true
	local hp = math.floor(sp.Hp * (if boss then 1 else zone.Hp) + 0.5)
	model:SetAttribute("InvasionTarget", "Bestia:" .. serial)
	model:SetAttribute("Bestia", lair.Species)
	model:SetAttribute("BeastName", if boss then sp.Name else Bestiary.leveledName(sp.Name, lair.Tier))
	model:SetAttribute("Nivel", if boss then nil else zone.Level)
	model:SetAttribute("MaxHp", hp)
	model:SetAttribute("EnemyMaxHealth", hp)
	model:SetAttribute("Boss", sp.Boss == true)
	model.Parent = beastFolder(S.Id)
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	local b: Beast = {
		N = serial,
		Model = model,
		Root = root,
		Humanoid = hum,
		Species = lair.Species,
		Sp = sp,
		Planet = S.Id,
		S = S,
		Lair = lair,
		Home = Vector3.new(O.X + lair.X, ground, O.Z + lair.Z),
		Hp = hp,
		Max = hp,
		Damage = {},
		Hit = if boss then 1 else zone.Damage,
		Reward = if boss then 1 else zone.Reward,
		Target = nil,
		NextWander = now() + math.random() * 3,
		NextBite = 0,
		NextStomp = now() + 6,
		Dead = false,
		LastSeen = now(),
	}
	setHp(b)
	beasts[model] = b
	byLair[lair.Id] = byLair[lair.Id] or {}
	table.insert(byLair[lair.Id], b)
	return b
end

local function forget(b: Beast)
	beasts[b.Model] = nil
	local list = byLair[b.Lair.Id]
	if list then
		local i = table.find(list, b)
		if i then
			table.remove(list, i)
		end
	end
end

local function despawn(b: Beast)
	forget(b)
	if b.Model.Parent then
		b.Model:Destroy()
	end
end

-- ¿Hay alguien (a pie o en la nave) cerca de este punto?
local function playersNear(pos: Vector3, radius: number): boolean
	for _, p in Players:GetPlayers() do
		local root = rootOf(p)
		if root and (root.Position - pos).Magnitude <= radius then
			return true
		end
	end
	return false
end

local function aliveCount(planet: string): number
	local n = 0
	for _, b in beasts do
		if b.Planet == planet and not b.Dead then
			n += 1
		end
	end
	return n
end

---------------------------------------------------------------------
-- Esquirlas de la Grieta (shared/Cosmos/Bestiary.Shard): se rompen a golpes y sueltan oleadas
---------------------------------------------------------------------
local shardAt: { [string]: number } = {} -- (por esquirla: cuándo vuelve a caer)
local waveOf: { [string]: { [string]: any } } = {} -- (la «guarida» de las oleadas de cada esquirla)

local function spawnShard(S: any, shard: { [string]: any }): Beast?
	local BeastKit = require(script.Parent.Parent.World.Kit.BeastKit) :: any
	serial += 1
	local O = S.Origin
	local ground = if shard.Islet then O.Y + shard.Y else S.heightAt(O.X + shard.X, O.Z + shard.Z)
	local model: Model = BeastKit.shard(CFrame.new(O.X + shard.X, ground - 1, O.Z + shard.Z), shard.Tier)
	local zone = Bestiary.zone(shard.Tier)
	local sp = Bestiary.Shard
	local hp = math.floor(sp.Hp * zone.Hp + 0.5)
	model:SetAttribute("InvasionTarget", "Bestia:" .. serial)
	model:SetAttribute("Bestia", sp.Id)
	model:SetAttribute("BeastName", Bestiary.leveledName(sp.Name, shard.Tier))
	model:SetAttribute("Nivel", zone.Level)
	model:SetAttribute("MaxHp", hp)
	model:SetAttribute("EnemyMaxHealth", hp)
	model:SetAttribute("Boss", false)
	model:SetAttribute("Esquirla", true)
	model.Parent = beastFolder(S.Id)
	local root = model.PrimaryPart :: BasePart
	local b: Beast = {
		N = serial,
		Model = model,
		Root = root,
		Humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid,
		Species = sp.Id,
		Sp = sp,
		Planet = S.Id,
		S = S,
		Lair = shard,
		Home = Vector3.new(O.X + shard.X, ground, O.Z + shard.Z),
		Hp = hp,
		Max = hp,
		Damage = {},
		Hit = 0,
		Reward = zone.Reward,
		Target = nil,
		NextWander = math.huge,
		NextBite = math.huge,
		NextStomp = math.huge,
		Dead = false,
		LastSeen = now(),
		Static = true,
		Waves = {},
		Tier = shard.Tier,
	}
	setHp(b)
	beasts[model] = b
	byLair[shard.Id] = { b }
	return b
end

-- Una oleada: bestias de la zona de la esquirla salen a su alrededor y van a por quien la está rompiendo
local function shardWave(b: Beast, index: number, attacker: Player?)
	local shard = b.Lair
	local wave = waveOf[shard.Id]
	if not wave then
		wave = { Id = shard.Id .. "_Oleada", Species = shard.Species, X = shard.X, Z = shard.Z, Y = shard.Y, Islet = shard.Islet, Tier = shard.Tier, Count = 0 }
		waveOf[shard.Id] = wave
	end
	local n = Bestiary.Shard.WaveSize[index] or 3
	for _ = 1, n do
		if aliveCount(b.Planet) >= BeastService.MaxPerPlanet + 16 then
			break
		end
		local nb = spawnAt(b.S, wave)
		if nb then
			nb.Target = attacker
		end
	end
	if attacker then
		tell(attacker, "Error", ("💎 ¡La esquirla se agrieta y suelta una oleada! (%d de %d)"):format(index, #Bestiary.Shard.Waves))
	end
end
BeastService.shardWave = shardWave

local function manageShards(S: any)
	local places = Bestiary.places(S)
	local O = S.Origin
	local t = now()
	for _, shard in places.Shards or {} do
		local pos = Vector3.new(O.X + shard.X, O.Y + shard.Y, O.Z + shard.Z)
		local list = byLair[shard.Id] or {}
		local alive = list[1] and not list[1].Dead
		if playersNear(pos, Bestiary.Active) then
			if alive then
				list[1].LastSeen = t
			elseif (shardAt[shard.Id] or 0) <= t then
				spawnShard(S, shard)
			end
		elseif alive and not playersNear(pos, Bestiary.Despawn) and t - list[1].LastSeen > 40 then
			despawn(list[1])
		end
		-- (las bestias de sus oleadas también se recogen si no queda nadie cerca)
		local wave = waveOf[shard.Id]
		local waveList = wave and byLair[wave.Id]
		if waveList and not playersNear(pos, Bestiary.Despawn) then
			for i = #waveList, 1, -1 do
				if not waveList[i].Dead and t - waveList[i].LastSeen > 40 then
					despawn(waveList[i])
				end
			end
		elseif waveList then
			for _, wb in waveList do
				wb.LastSeen = t
			end
		end
	end
end

local function manageLairs(S: any)
	local places = Bestiary.places(S)
	local O = S.Origin
	local all = table.clone(places.Lairs)
	if places.Boss then
		table.insert(all, places.Boss)
	end
	local t = now()
	for _, lair in all do
		local pos = Vector3.new(O.X + lair.X, O.Y + lair.Y, O.Z + lair.Z)
		local list = byLair[lair.Id] or {}
		if playersNear(pos, Bestiary.Active) then
			for _, b in list do
				b.LastSeen = t
			end
			-- (las que cayeron vuelven a su hora)
			local due = respawnAt[lair.Id] or {}
			local missing = lair.Count - #list
			local ready = 0
			for i = #due, 1, -1 do
				if due[i] <= t then
					table.remove(due, i)
				end
			end
			ready = missing - #due
			for _ = 1, math.max(0, ready) do
				if aliveCount(S.Id) >= BeastService.MaxPerPlanet then
					break
				end
				spawnAt(S, lair)
			end
		elseif not playersNear(pos, Bestiary.Despawn) then
			for i = #list, 1, -1 do
				local b = list[i]
				if not b.Dead and t - b.LastSeen > 40 then
					despawn(b)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Pelea
---------------------------------------------------------------------
local function buff(player: Player, name: string): number
	local untilT = player:GetAttribute("Buff" .. name .. "Hasta")
	if type(untilT) == "number" and untilT > workspace:GetServerTimeNow() then
		return tonumber(player:GetAttribute("Buff" .. name)) or 0
	end
	return 0
end
BeastService.buff = buff

-- Una bestia (o el pisotón del jefe) le hace daño a un jugador
local function hurt(b: Beast, player: Player, amount: number)
	local _, hum = rootOf(player)
	if not hum or hum.Health <= 0 then
		return
	end
	local data = dataOf(player)
	local dmg = Crafting.damageTaken(amount, Crafting.defenseOf(data and data.Items, data and data.Refine), buff(player, "Piedra") + buff(player, "Coraza"))
	if hum.Health - dmg > 1 then
		hum.Health -= dmg
		return
	end
	-- caes en combate y te levantas a los pocos segundos (la bestia se va a por otro o vuelve a su guarida)
	hum.Health = 1
	local DamageService = require(script.Parent.DamageService) :: any
	DamageService.fall(player, "Bestia")
	tell(player, "Error", ("💥 %s te ha tumbado. Te levantas en unos segundos: aléjate de su guarida."):format(b.Sp.Name))
	task.delay(BeastService.GetUpSeconds, function()
		if player.Parent and player:GetAttribute("Fallen") == "Bestia" then
			DamageService.getUp(player, false)
			local _, h = rootOf(player)
			if h and h.Health > 0 then
				h.Health = math.max(h.Health, h.MaxHealth * 0.4)
			end
		end
	end)
	if b.Target == player then
		b.Target = nil
	end
end

local function dustBurst(at: Vector3, color: Color3, big: boolean)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(at)
	p.Parent = workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, if big then 6 else 2), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.8, 1.6)
	pe.Speed = NumberRange.new(6, 18)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rate = 0
	pe.LightEmission = 0.6
	pe.Parent = p
	pe:Emit(if big then 120 else 40)
	task.delay(2.5, function()
		p:Destroy()
	end)
end

-- El pisotón del jefe: un anillo que avisa y, al segundo, daño a todos los que sigan dentro
local function stomp(b: Beast)
	local center = b.Root.Position - Vector3.new(0, b.Humanoid.HipHeight + b.Root.Size.Y / 2 - 0.3, 0)
	local radius = 22
	local ring = Instance.new("Part")
	ring.Name = "AvisoPisoton"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = b.Sp.Colors.Glow
	ring.Transparency = 0.55
	ring.Size = Vector3.new(0.3, 4, 4)
	ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.3, radius * 2, radius * 2) }):Play()
	task.delay(1.15, function()
		ring:Destroy()
		if b.Dead or not b.Model.Parent then
			return
		end
		dustBurst(center, b.Sp.Colors.Glow, true)
		for _, p in Players:GetPlayers() do
			local root = rootOf(p)
			if root and huntable(p) and (root.Position - center).Magnitude <= radius then
				hurt(b, p, b.Sp.Damage * (b.Hit or 1) * 1.6)
			end
		end
	end)
end

local function money(player: Player, amount: number)
	pcall(function()
		(require(script.Parent.DataService) :: any).addMoney(player, amount, true)
	end)
end

local function giveLoot(player: Player, b: Beast)
	local InventoryService = require(script.Parent.InventoryService) :: any
	local data0 = dataOf(player)
	local worn = Crafting.stats(data0 and data0.Items, data0 and data0.Refine)
	-- (la Suerte del personaje también ayuda: +1 % de botín raro por punto)
	local okP, Progression = pcall(require, script.Parent.ProgressionService)
	if okP then
		worn.Luck += ((Progression :: any).stat(player, "Suerte") or 0) * 0.01
	end
	local reward = b.Reward or 1
	local loot = if b.Static then Bestiary.shardLoot(b.Tier, b.Planet, math.random) else Bestiary.loot(b.Species, math.random, worn.Luck + (reward - 1) * 0.25)
	local parts = {}
	for id, n in loot do
		local ok = InventoryService.add(player, id, n)
		local item = Items.get(id)
		if ok then
			table.insert(parts, ("%s %d %s"):format(item and item.Icon or "📦", n, item and item.Name or id))
		end
	end
	local cash = math.floor((b.Sp.Money or 0) * reward + 0.5)
	if cash > 0 then
		money(player, cash)
	end
	local data = dataOf(player)
	if data then
		local c = craftData(data)
		c.Kills[b.Species] = (c.Kills[b.Species] or 0) + 1
		if b.Sp.Boss then
			c.Bosses[b.Species] = (c.Bosses[b.Species] or 0) + 1
		end
		-- nivel de cazador: experiencia por la bestia (más cuanto más aguanta)
		data.Hunter = if type(data.Hunter) == "table" then data.Hunter else { Xp = 0 }
		local before = Crafting.hunterLevel(data.Hunter.Xp)
		data.Hunter.Xp = (tonumber(data.Hunter.Xp) or 0) + Crafting.killXp(b.Max, b.Sp.Boss)
		local after = Crafting.hunterLevel(data.Hunter.Xp)
		player:SetAttribute("NivelCazador", after)
		-- y experiencia del personaje (sube su nivel y da puntos de atributos, como cualquier cosa de tu vida)
		if okP then
			pcall((Progression :: any).addXp, player, math.max(1, math.floor(Crafting.killXp(b.Max, b.Sp.Boss) / 2)), nil)
		end
		if after > before then
			tell(player, "Success", ("⭐ ¡Nivel de cazador %d! Tus golpes a las bestias hacen un %d %% más."):format(after, math.floor(Crafting.hunterBonus(data.Hunter.Xp) * 100 + 0.5)))
		end
	end
	-- el vigor de tus pendientes: recuperas vida cuando cae la bestia
	if worn.Vigor > 0 then
		local _, hum = rootOf(player)
		if hum and hum.Health > 0 then
			hum.Health = math.min(hum.MaxHealth, hum.Health + worn.Vigor)
		end
	end
	local text = ("%s %s cae. %s%s"):format(b.Sp.Icon or "🦴", b.Sp.Name, if #parts > 0 then "Botín: " .. table.concat(parts, ", ") else "", if cash > 0 then (" · +%d €"):format(cash) else "")
	tell(player, "Success", text)
end

local function die(b: Beast, killer: Player?)
	if b.Dead then
		return
	end
	b.Dead = true
	b.Model:SetAttribute("EnemyDown", true)
	b.Model:SetAttribute("InvasionTarget", nil)
	-- el botín: el que remata y todos los que le hicieron al menos un 15 % del daño
	local got: { [Player]: boolean } = {}
	if killer and killer.Parent then
		got[killer] = true
	end
	for p, dmg in b.Damage do
		if p.Parent and dmg >= b.Max * 0.15 then
			got[p] = true
		end
	end
	for p in got do
		giveLoot(p, b)
	end
	if b.Sp.Boss then
		for _, p in Players:GetPlayers() do
			if p:GetAttribute("Planeta") == b.Planet then
				tell(p, "Success", ("👑 ¡%s ha caído! Vuelve a su guarida dentro de un rato."):format(b.Sp.Name))
			end
		end
	end
	if b.Static then
		shardAt[b.Lair.Id] = now() + Bestiary.ShardRespawn
		for _, p in got do
			tell(p, "Success", "💎 ¡Has roto la esquirla de la Grieta! Volverá a caer otra dentro de un rato.")
		end
	end
	-- vuelve a su hora
	respawnAt[b.Lair.Id] = respawnAt[b.Lair.Id] or {}
	table.insert(respawnAt[b.Lair.Id], now() + (if b.Sp.Boss then Bestiary.BossRespawn else Bestiary.Respawn))
	forget(b)
	-- cae y se deshace en polvo (sin sangre)
	b.Humanoid:Move(Vector3.zero)
	b.Root.Anchored = true
	dustBurst(b.Root.Position, b.Sp.Colors.Body, b.Sp.Boss == true)
	for _, d in b.Model:GetDescendants() do
		if d:IsA("BasePart") and d ~= b.Root then
			TweenService:Create(d, TweenInfo.new(1.2), { Transparency = 1 }):Play()
		end
	end
	task.delay(1.4, function()
		if b.Model.Parent then
			b.Model:Destroy()
		end
	end)
end

-- Las bestias vivas a menos de `radius` de un punto (las habilidades de cazador: Services/HunterSkillService)
function BeastService.near(pos: Vector3, radius: number): { Model }
	local out: { Model } = {}
	for model, b in beasts do
		if not b.Dead and (b.Root.Position - pos).Magnitude <= radius then
			table.insert(out, model)
		end
	end
	return out
end

-- El daño a una bestia (CombatService.beastHit). Devuelve (contado, daño hecho, caída)
function BeastService.hit(attacker: Player?, model: Instance, amount: number, info: { [string]: any }?): (boolean, number, boolean)
	local node: Instance? = model
	local b: Beast? = nil
	while node and node ~= workspace do
		if node:IsA("Model") and beasts[node :: Model] then
			b = beasts[node :: Model]
			break
		end
		node = node.Parent
	end
	if not b or b.Dead or not attacker then
		return false, 0, false
	end
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return false, 0, false
	end
	local i = info or {}
	local n = amount
	if i.Melee or i.Heavy then
		-- golpes: tu mejor arma blanca y la poción de fuerza
		local data = dataOf(attacker)
		n *= 1 + Crafting.bladeOf(data and data.Items, data and data.Refine) + buff(attacker, "Fuerza") + buff(attacker, "Furia") + Crafting.hunterBonus(data and data.Hunter and data.Hunter.Xp)
		-- (el estilo de tu arma: el hacha pesa más, el cuchillo menos pero más seguido)
		if not i.Skill then
			n *= Combat.weaponStyle(attacker:GetAttribute("EstiloArma")).BeastMul
		end
	elseif i.Weapon then
		local data = dataOf(attacker)
		n *= BeastService.BulletMul * (1 + Crafting.gunBonus(data and data.Refine, i.Weapon) + Crafting.hunterBonus(data and data.Hunter and data.Hunter.Xp) + buff(attacker, "Punteria"))
	end
	if b.Sp.Boss then
		n *= BeastService.BossTakes
	end
	n = math.clamp(math.floor(n + 0.5), 1, 600)
	b.Hp -= n
	b.Damage[attacker] = (b.Damage[attacker] or 0) + n
	-- se enfada con quien le pega (si no está demasiado lejos de casa)
	b.Target = attacker
	setHp(b)
	if b.Static and b.Waves and b.Hp > 0 then
		for idx, th in Bestiary.Shard.Waves do
			if not b.Waves[idx] and b.Hp / b.Max <= th then
				b.Waves[idx] = true
				shardWave(b, idx, attacker)
			end
		end
	end
	if b.Hp <= 0 then
		die(b, attacker)
		return true, n, true
	end
	return true, n, false
end

---------------------------------------------------------------------
-- Cabeza de las bestias (cada BeastService.Tick)
---------------------------------------------------------------------
local function nearestTarget(b: Beast): (Player?, number)
	local best, bd = nil, math.huge
	for _, p in Players:GetPlayers() do
		if huntable(p) then
			local root = rootOf(p)
			if root then
				local d = (root.Position - b.Root.Position).Magnitude
				if d < b.Sp.Aggro and d < bd and (root.Position - b.Home).Magnitude < Bestiary.Leash + b.Sp.Aggro then
					best, bd = p, d
				end
			end
		end
	end
	return best, bd
end

local function think(b: Beast, t: number)
	if b.Dead or not b.Model.Parent then
		forget(b)
		return
	end
	if b.Static then
		return -- (una esquirla: ni se mueve ni muerde)
	end
	-- (si se cae o se atasca muy lejos, vuelve a su guarida)
	if b.Root.Position.Y < b.Home.Y - 40 or (b.Root.Position - b.Home).Magnitude > Bestiary.Leash * 2.5 then
		b.Model:PivotTo(CFrame.new(b.Home + Vector3.new(0, b.Humanoid.HipHeight + b.Root.Size.Y / 2 + 1, 0)))
		b.Target = nil
		return
	end
	local target = b.Target
	if target and (not target.Parent or not huntable(target)) then
		target = nil
	end
	local troot = target and rootOf(target)
	if troot and (troot.Position - b.Home).Magnitude > Bestiary.Leash + 30 then
		target, troot = nil, nil -- (demasiado lejos de su guarida: lo deja)
	end
	if not target then
		local p = nearestTarget(b)
		target = p
		troot = p and rootOf(p)
		if p and b.Sp.Boss and not b.Announced then
			b.Announced = true
			for _, q in Players:GetPlayers() do
				local r = rootOf(q)
				if r and (r.Position - b.Root.Position).Magnitude < 220 then
					tell(q, "Error", ("⚠ %s se ha despertado."):format(b.Sp.Name))
				end
			end
		end
	end
	b.Target = target
	if target and troot then
		local flat = Vector3.new(troot.Position.X - b.Root.Position.X, 0, troot.Position.Z - b.Root.Position.Z)
		local reach = b.Root.Size.Z * 0.5 + 4.5
		if flat.Magnitude > reach - 1 then
			b.Humanoid:MoveTo(troot.Position)
		else
			b.Humanoid:Move(Vector3.zero)
			-- mirar hacia él
			b.Root.CFrame = CFrame.new(b.Root.Position, b.Root.Position + flat)
		end
		if flat.Magnitude <= reach and t >= b.NextBite and math.abs(troot.Position.Y - b.Root.Position.Y) < 12 + b.Root.Size.Y then
			b.NextBite = t + BeastService.BiteCooldown
			hurt(b, target, b.Sp.Damage * (b.Hit or 1))
		end
		if b.Sp.Boss and t >= b.NextStomp and flat.Magnitude < 34 then
			b.NextStomp = t + 7
			stomp(b)
		end
	else
		b.Announced = if b.Sp.Boss then b.Announced else nil
		if t >= b.NextWander then
			b.NextWander = t + 3 + math.random() * 4
			local a = math.random() * math.pi * 2
			local d = math.random() * (if b.Sp.Boss then 10 elseif b.Lair.Islet then 12 else 26)
			b.Humanoid:MoveTo(b.Home + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d))
		end
		-- (curarse poco a poco en casa)
		if b.Hp < b.Max then
			b.Hp = math.min(b.Max, b.Hp + b.Max * 0.01)
			setHp(b)
		end
	end
end

---------------------------------------------------------------------
-- Alijos
---------------------------------------------------------------------
local function openCache(player: Player, cacheId: string)
	local planet = string.match(cacheId, "^(%a+)_A%d+$")
	local S = planet and PlanetRegistry.get(planet)
	if not S then
		return
	end
	local found = nil
	for _, c in Bestiary.places(S).Caches do
		if c.Id == cacheId then
			found = c
		end
	end
	local root = rootOf(player)
	if not found or not root then
		return
	end
	local O = S.Origin
	if (root.Position - Vector3.new(O.X + found.X, root.Position.Y, O.Z + found.Z)).Magnitude > 16 then
		return
	end
	local data = dataOf(player)
	if not data then
		return
	end
	local c = craftData(data)
	local last = tonumber(c.Caches[cacheId])
	local t = os.time()
	if last and t - last < Bestiary.CacheCooldown then
		local h = math.ceil((Bestiary.CacheCooldown - (t - last)) / 3600)
		tell(player, "Info", ("📦 Ya lo has vaciado. Alguien lo vuelve a llenar en unas %d h."):format(h))
		return
	end
	c.Caches[cacheId] = t
	local InventoryService = require(script.Parent.InventoryService) :: any
	local loot, cash = Bestiary.cacheLoot(S.Id, math.random)
	if Crafting.gear("Ganzua") and (data.Items and (data.Items.Ganzua or 0) > 0) then
		cash *= 2
	end
	local parts = {}
	for id, n in loot do
		if InventoryService.add(player, id, n) then
			local item = Items.get(id)
			table.insert(parts, ("%s %d %s"):format(item and item.Icon or "📦", n, item and item.Name or id))
		end
	end
	money(player, cash)
	tell(player, "Success", ("📦 Alijo: %s · +%d €"):format(table.concat(parts, ", "), cash))
end

-- Aviso al acercarte a la guarida del jefe (una vez por sesión y planeta)
local function proximityHints()
	for _, p in Players:GetPlayers() do
		local root = rootOf(p)
		if root then
			for id, b in built do
				local boss = Bestiary.places(b.S).Boss
				if boss then
					local O = b.S.Origin
					local d = (root.Position - Vector3.new(O.X + boss.X, root.Position.Y, O.Z + boss.Z)).Magnitude
					warned[p] = warned[p] or {}
					if d < 160 and not warned[p][id] then
						warned[p][id] = true
						tell(p, "Error", "🌫 Algo enorme duerme cerca. El suelo tiembla un poco cada vez que respira…")
					end
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------
local acc, hintAcc = 0, 0
function BeastService._step(dt: number)
	acc += dt
	hintAcc += dt
	if acc < BeastService.Tick then
		return
	end
	acc = 0
	local t = now()
	for _, b in built do
		manageLairs(b.S)
		local okS, errS = pcall(manageShards, b.S)
		if not okS then
			warn("[BeastService] esquirlas: " .. tostring(errS))
		end
	end
	for _, b in beasts do
		local ok, err = pcall(think, b, t)
		if not ok then
			warn("[BeastService] " .. tostring(err))
		end
	end
	if hintAcc > 1 then
		hintAcc = 0
		proximityHints()
	end
end

function BeastService.init()
	-- las bestias atraviesan las rocas de sus guaridas (si no, el jefe se queda encerrado en la suya)
	pcall(function()
		local PhysicsService = game:GetService("PhysicsService")
		for _, g in { "Bestias", "Guarida" } do
			if not PhysicsService:IsCollisionGroupRegistered(g) then
				PhysicsService:RegisterCollisionGroup(g)
			end
		end
		PhysicsService:CollisionGroupSetCollidable("Bestias", "Guarida", false)
	end)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent
	local okCombat, CombatService = pcall(require, script.Parent.CombatService)
	if okCombat and CombatService then
		(CombatService :: any).beastHit = BeastService.hit
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if CollectionService:HasTag(prompt, "Alijo") then
			local id = prompt:GetAttribute("Cache")
			if type(id) == "string" then
				openCache(player, id)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		warned[p] = nil
		for _, b in beasts do
			b.Damage[p] = nil
			if b.Target == p then
				b.Target = nil
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		BeastService._step(dt)
	end)
end

-- (pruebas)
BeastService._beasts = beasts
BeastService._built = built
BeastService._spawn = spawnAt
BeastService._open = openCache

return BeastService
