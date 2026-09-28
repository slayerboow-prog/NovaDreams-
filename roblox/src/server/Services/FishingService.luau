-- FishingService: la pesca y el oficio de pescador.
--
-- PESCAR (cualquiera con caña)
--   * En cualquier orilla: si tienes agua delante sale "🎣 Pescar aquí" (el agua se decide por el
--     sitio: lagos y río del plano de la ciudad; en el barco, alta mar; lo demás es mar).
--   * En un sitio de pesca (muelle del puerto, pantalanes de los lagos y del río, barco de pesca)
--     "Pescar". Se lanza el sedal y el corcho cae al agua. Cuando pica (el corcho se hunde) hay que
--     "¡Tirar!" enseguida: si tiras antes, se asusta; si tardas, se escapa.
--   * NIVELES: cada pez da experiencia. Los peces piden nivel, caña y a veces herramienta (nasa,
--     red, arpón, sonar). Si pica uno que no puedes sacar, rompe el sedal y te dice qué te falta.
--   * PELEA: los grandes hay que sacarlos a tirones (varios toques seguidos antes de que se suelten).
--   * BANCOS DE PECES: cada agua tiene un número de peces de cada especie; al pescar bajan y
--     vuelven a salir (tras unas capturas en esa agua o al cabo de un rato). Nunca se acaban.
--   * MONSTRUOS (Megalodón, Kraken): en alta mar, si hay bastantes pescadores preparados a la vez,
--     a veces pica uno. Todos los del barco tiran juntos; si lo sacáis, cada uno que ha ayudado se
--     lleva el trofeo.
--   * Las cañas, herramientas y el cebo se compran en la tienda de pesca del centro.
--   * El barco de pesca está fondeado en alta mar: se sube desde el amarre del puerto (gratis para
--     los pescadores de turno; los demás pagan el alquiler).
--
-- VENDER: en la pescadería de cualquier supermercado, "Vender pescado". Lo que el supermercado
-- vende se pone en su mostrador (si nadie pesca, no hay pescado); lo demás lo compra la lonja.
--
-- PESCADOR (tablón "Trabajar" en el puerto): te prestan una caña si no tienes, el supermercado te
-- paga más y cada venta cuenta para la historia (JobTaskDone con JobId "Pescador").
--
-- Para el cliente: atributos FishingLevel, FishingXp y FishingCaught (JSON { [pez] = número }).

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fishing = require(ReplicatedStorage.Shared.Fishing)
local SeaEvents = require(ReplicatedStorage.Shared.SeaEvents)
local CityPlan = require(ReplicatedStorage.Shared.CityPlan)
local Format = require(ReplicatedStorage.Shared.Format)
local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Npc = require(script.Parent.Parent.World.Npc)
local DataService = require(script.Parent.DataService)
local NeedsService = require(script.Parent.NeedsService)
local LifeService = require(script.Parent.LifeService)
local MonetizationService = require(script.Parent.MonetizationService)
local InventoryService = require(script.Parent.InventoryService)
local RoleService = require(script.Parent.RoleService)
local JobService = require(script.Parent.JobService)
local SupermarketService = require(script.Parent.SupermarketService)
local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local FishingService = {}

local Notify = ReplicatedStorage.Remotes.Notify :: RemoteEvent
local Remote = ReplicatedStorage.Remotes.Fishing :: RemoteEvent
local JOB = Fishing.Job
local WATER_Y = -2
local LATENCY = 0.4 -- margen por el retraso de la red al tirar

type State = {
	Spot: BasePart,
	Token: number,
	Phase: string, -- "Wait" | "Bite" | "Fight" | "Done"
	BiteAt: number,
	Water: string,
	Species: any?, -- lo que ha picado (nil = basura)
	Locked: boolean?,
	Need: number?,
	Got: number?,
	LastPull: number?,
	Window: number?,
}

-- Números al azar (con math.random: funciona igual en Roblox y en las pruebas)
local rng = {}
function rng.NextNumber(_self: any, min: number?, max: number?): number
	local lo, hi = min or 0, max or 1
	return lo + math.random() * (hi - lo)
end
function rng.NextInteger(_self: any, min: number, max: number): number
	return math.random(min, max)
end
local fishing: { [Player]: State } = {}
local spotOwner: { [BasePart]: Player } = {}
local onDuty: { [Player]: boolean } = {}
local lentRod: { [Player]: boolean } = {}
local nextToken = 0

-- Animación de la pesca que ven todos (SeaMotion en cada cliente): estado, cuándo empezó y el pez
local function serverNow(): number
	local ok, now = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return if ok and type(now) == "number" then now else os.clock()
end

local function anim(player: Player, state: string?, fishId: string?)
	player:SetAttribute("FishAnim", state)
	player:SetAttribute("FishAnimAt", if state then serverNow() else nil)
	player:SetAttribute("FishAnimFish", fishId)
end
FishingService.anim = anim

local RESULT_ANIM = { Catch = "Catch", Boss = "Heave", Full = "Lost", Early = "Lost", Late = "Lost", Junk = "Lost", Locked = "Lost", Escaped = "Lost" }

-- Manda un evento de la pesca al jugador y pone su animación
local function fire(player: Player, kind: string, data: any?)
	if kind == "Cast" then
		anim(player, "Cast")
	elseif kind == "Bite" then
		anim(player, "Bite")
	elseif kind == "Fight" or kind == "Pull" then
		anim(player, "Fight")
	elseif kind == "Result" and data then
		local species = if data.Kind == "Catch" then Fishing.byId[data.Id] else nil
		anim(player, RESULT_ANIM[data.Kind] or "Lost", if species then species.Id else nil)
	elseif kind == "Stop" then
		anim(player, "Reel")
		local at = player:GetAttribute("FishAnimAt")
		task.delay(1.3, function()
			if player.Parent and player:GetAttribute("FishAnim") == "Reel" and player:GetAttribute("FishAnimAt") == at then
				anim(player, nil)
			end
		end)
	end
	if data ~= nil then
		Remote:FireClient(player, kind, data)
	else
		Remote:FireClient(player, kind)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nameOf(player: Player): string
	return player.DisplayName or player.Name
end

local function isBaby(player: Player): boolean
	local stage = player:GetAttribute("LifeStage")
	return type(stage) == "string" and Stages.isValid(stage) and not Stages.inRange(stage, "Nino", nil)
end

-- La mejor caña que tienes (o nil)
local function rodOf(player: Player): { [string]: any }?
	for _, id in Fishing.RodOrder do
		if InventoryService.count(player, id) > 0 then
			return Fishing.Rods[id]
		end
	end
	return nil
end

local function rodTier(player: Player): number
	local rod = rodOf(player)
	return if rod then rod.Tier else 0
end

local function toolsOf(player: Player): { [string]: boolean }
	local tools = {}
	for id in Fishing.Tools do
		if InventoryService.count(player, id) > 0 then
			tools[id] = true
		end
	end
	return tools
end

local function fishCount(player: Player): number
	local n = 0
	for _, s in Fishing.Species do
		n += InventoryService.count(player, s.Item)
	end
	for _, b in Fishing.Bosses do
		n += InventoryService.count(player, b.Item)
	end
	return n
end

---------------------------------------------------------------------
-- Nivel de pesca
---------------------------------------------------------------------

local function fishData(player: Player): { Xp: number, Caught: { [string]: number } }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	local fd = data.Fishing
	if type(fd) ~= "table" then
		fd = {}
		data.Fishing = fd
	end
	fd.Xp = if type(fd.Xp) == "number" then fd.Xp else 0
	fd.Caught = if type(fd.Caught) == "table" then fd.Caught else {}
	return fd
end

local function levelOf(player: Player): number
	local fd = fishData(player)
	return Fishing.levelFor(if fd then fd.Xp else 0)
end

local function syncLevel(player: Player)
	local fd = fishData(player)
	if not fd then
		return
	end
	player:SetAttribute("FishingLevel", Fishing.levelFor(fd.Xp))
	player:SetAttribute("FishingXp", fd.Xp)
	local ok, caught = pcall(HttpService.JSONEncode, HttpService, fd.Caught)
	if ok then
		player:SetAttribute("FishingCaught", caught)
	end
end

-- Qué te falta para sacarlo (lista vacía = puedes)
local function missingFor(player: Player, target: { [string]: any }): { string }
	return Fishing.missing(target, levelOf(player), rodTier(player), toolsOf(player))
end

local function canCatch(player: Player, target: { [string]: any }): boolean
	return #missingFor(player, target) == 0
end

-- Suma experiencia y avisa si subes de nivel (con lo nuevo que puedes pescar)
local function addXp(player: Player, xp: number, id: string?)
	local fd = fishData(player)
	if not fd then
		return
	end
	local before = Fishing.levelFor(fd.Xp)
	fd.Xp += xp
	if id then
		fd.Caught[id] = (fd.Caught[id] or 0) + 1
	end
	local after = Fishing.levelFor(fd.Xp)
	syncLevel(player)
	if after > before then
		local unlocked = {}
		for _, s in Fishing.Species do
			if s.Level > before and s.Level <= after then
				table.insert(unlocked, s.Icon .. " " .. s.Name)
			end
		end
		for _, id2 in Fishing.RodOrder do
			local rod = Fishing.Rods[id2]
			if rod.Level > before and rod.Level <= after then
				table.insert(unlocked, "tienda: " .. rod.Name)
			end
		end
		for _, id2 in Fishing.ToolOrder do
			local tool = Fishing.Tools[id2]
			if tool.Level > before and tool.Level <= after then
				table.insert(unlocked, "tienda: " .. tool.Name)
			end
		end
		local text = ("🎣 ¡Nivel de pesca %d!"):format(after)
		if #unlocked > 0 then
			text ..= " Nuevo: " .. table.concat(unlocked, ", ")
		end
		Notify:FireClient(player, "Success", text)
		Remote:FireClient(player, "LevelUp", { Level = after })
	end
end

---------------------------------------------------------------------
-- Bancos de peces (vuelven siempre)
---------------------------------------------------------------------

local pop: { [string]: { [string]: number } } = {}
local depleted: { [string]: { [string]: { Catches: number, Time: number } } } = {}
local catchesIn: { [string]: number } = {}
local lastRegen = os.clock()

for water in Fishing.Waters do
	pop[water] = {}
	depleted[water] = {}
	catchesIn[water] = 0
	for _, s in Fishing.Species do
		if s.Waters[water] then
			pop[water][s.Id] = s.Pop
		end
	end
end

local function shoalPercent(water: string): number
	local have, max = 0, 0
	for _, s in Fishing.Species do
		if s.Waters[water] then
			have += pop[water][s.Id] or 0
			max += s.Pop
		end
	end
	return if max > 0 then math.floor(have / max * 100 + 0.5) else 100
end

local function tellWater(water: string, text: string)
	for player, state in fishing do
		if state.Water == water then
			Notify:FireClient(player, "Info", text)
		end
	end
end

local function refill(water: string, id: string, announce: boolean)
	local s = Fishing.byId[id]
	if not s then
		return
	end
	pop[water][id] = s.Pop
	depleted[water][id] = nil
	if announce then
		tellWater(water, ("🐟 ¡Ha vuelto un banco de %s a %s!"):format(string.lower(s.Name), Fishing.Waters[water] or "el agua"))
	end
end

-- Mira si ya toca que vuelvan los peces agotados
local function checkRespawn(water: string)
	local now = os.clock()
	for id, at in depleted[water] do
		if catchesIn[water] - at.Catches >= Fishing.Respawn.AfterCatches or now - at.Time >= Fishing.Respawn.Seconds then
			refill(water, id, true)
		end
	end
	-- Red de seguridad: si no quedara nada de nada, vuelve todo
	local any = false
	for _, n in pop[water] do
		if n > 0 then
			any = true
			break
		end
	end
	if not any then
		for id in pop[water] do
			refill(water, id, false)
		end
		tellWater(water, "🐟 ¡Han llegado peces nuevos!")
	end
end

-- Un pez sale del agua
local function consume(water: string, species: any)
	local left = (pop[water][species.Id] or 0) - 1
	pop[water][species.Id] = math.max(0, left)
	catchesIn[water] += 1
	if left <= 0 and not depleted[water][species.Id] then
		depleted[water][species.Id] = { Catches = catchesIn[water], Time = os.clock() }
	end
	checkRespawn(water)
end

local function regenTick()
	local now = os.clock()
	local regen = now - lastRegen >= Fishing.Respawn.RegenSeconds
	if regen then
		lastRegen = now
	end
	for water in Fishing.Waters do
		if regen then
			for id, n in pop[water] do
				local s = Fishing.byId[id]
				if s and n < s.Pop and not depleted[water][id] then
					pop[water][id] = n + 1
				end
			end
		end
		checkRespawn(water)
	end
end

---------------------------------------------------------------------
-- Pescar
---------------------------------------------------------------------

local function stop(player: Player, silent: boolean?)
	local state = fishing[player]
	if not state then
		return
	end
	fishing[player] = nil
	if spotOwner[state.Spot] == player then
		spotOwner[state.Spot] = nil
	end
	if state.Spot:GetAttribute("Temporary") then
		state.Spot:Destroy() -- sitio improvisado ("Pescar aquí")
	end
	if player.Parent then
		fire(player, "Stop")
		if not silent then
			Notify:FireClient(player, "Info", "🎣 Recoges el sedal.")
		end
	end
end

local function bobberOf(spot: BasePart): Vector3
	local p = (spot.CFrame * CFrame.new(0, 0, -(spot:GetAttribute("CastDistance") or 10))).Position
	return Vector3.new(p.X, WATER_Y + 0.2, p.Z)
end

---------------------------------------------------------------------
-- Monstruos marinos (entre varios, en alta mar)
---------------------------------------------------------------------

type Boss = { Def: any, Hp: number, Until: number, Pulls: { [Player]: number }, Last: { [Player]: number }, Warned: { [Player]: boolean } }
local boss: Boss? = nil
local bossReadyAt = 0

local function altaMarFishers(): { Player }
	local list = {}
	for player, state in fishing do
		if state.Water == "AltaMar" and player.Parent then
			table.insert(list, player)
		end
	end
	return list
end

local function bossInfo(b: Boss, player: Player?): { [string]: any }
	local helpers = 0
	for _, n in b.Pulls do
		if n >= b.Def.MinPulls then
			helpers += 1
		end
	end
	return {
		Id = b.Def.Id,
		Name = b.Def.Name,
		Icon = b.Def.Icon,
		Desc = b.Def.Desc,
		Hp = math.max(0, b.Hp),
		Max = b.Def.Hp,
		Left = math.max(0, math.ceil(b.Until - os.clock())),
		MinPlayers = b.Def.MinPlayers,
		Helpers = helpers,
		Mine = if player then b.Pulls[player] or 0 else 0,
		CanHelp = if player then canCatch(player, b.Def) else nil,
		Missing = if player then missingFor(player, b.Def) else nil,
	}
end

local function bossBroadcast(kind: string)
	local b = boss
	if not b then
		return
	end
	for _, player in altaMarFishers() do
		Remote:FireClient(player, kind, bossInfo(b, player))
	end
	for player in b.Pulls do
		if player.Parent and not (fishing[player] and fishing[player].Water == "AltaMar") then
			Remote:FireClient(player, kind, bossInfo(b, player))
		end
	end
end

local function bossEnd(win: boolean)
	local b = boss
	if not b then
		return
	end
	boss = nil
	bossReadyAt = os.clock() + Fishing.BossCooldown
	for player in b.Pulls do
		if player.Parent and player:GetAttribute("FishAnim") == "Heave" then
			anim(player, "Wait")
		end
	end
	local def = b.Def
	local helpers = {}
	for player, n in b.Pulls do
		if n >= def.MinPulls and player.Parent then
			table.insert(helpers, player)
		end
	end
	local text
	if win and #helpers >= def.MinPlayers then
		local kg = math.floor(rng:NextNumber(def.Kg[1], def.Kg[2]))
		text = ("🏆 ¡Lo habéis sacado entre %d! %s %s de %d kg"):format(#helpers, def.Icon, def.Name, kg)
		for _, player in helpers do
			if InventoryService.add(player, def.Item, 1) then
				Notify:FireClient(player, "Success", ("%s ¡Trofeo a la mochila: %s! (la lonja lo paga a %s)"):format(def.Icon, def.Name, Format.money(def.Price)))
			else
				DataService.addMoney(player, def.Price, true)
				Notify:FireClient(player, "Money", ("+%s · no te cabía el %s y la lonja te lo ha comprado"):format(Format.money(def.Price), def.Name))
			end
			addXp(player, def.Xp, def.Id)
			StoryEvents.emit(player, "CaughtFish", { Species = def.Id, Boss = true })
		end
	elseif win then
		text = ("%s ¡Se ha soltado! Hacían falta al menos %d pescadores tirando fuerte."):format(def.Icon, def.MinPlayers)
	else
		text = ("%s ¡El %s ha roto los sedales y se ha escapado al fondo!"):format(def.Icon, def.Name)
	end
	local told = {}
	for _, player in altaMarFishers() do
		told[player] = true
		Remote:FireClient(player, "BossEnd", { Win = win and #helpers >= def.MinPlayers, Text = text })
	end
	for player in b.Pulls do
		if player.Parent and not told[player] then
			Remote:FireClient(player, "BossEnd", { Win = win and #helpers >= def.MinPlayers, Text = text })
		end
	end
end

local function startBoss(def: any)
	if boss then
		return
	end
	local b: Boss = { Def = def, Hp = def.Hp, Until = os.clock() + def.Seconds, Pulls = {}, Last = {}, Warned = {} }
	boss = b
	bossBroadcast("Boss")
	task.spawn(function()
		while boss == b do
			task.wait(0.3)
			if boss ~= b then
				break
			end
			if os.clock() >= b.Until then
				bossEnd(false)
				break
			end
			bossBroadcast("BossHp")
		end
	end)
end

-- ¿Aparece un monstruo? (al picar en alta mar, si hay bastantes pescadores preparados)
local function maybeBoss(player: Player): boolean
	if boss or os.clock() < bossReadyAt then
		return false
	end
	local fishers = altaMarFishers()
	for _, id in Fishing.BossOrder do
		local def = Fishing.Bosses[id]
		if canCatch(player, def) then
			local ready = 0
			for _, other in fishers do
				if canCatch(other, def) then
					ready += 1
				end
			end
			if ready >= def.MinPlayers then
				if rng:NextNumber() < Fishing.BossChance then
					startBoss(def)
					return true
				end
			elseif rng:NextNumber() < 0.1 then
				Notify:FireClient(player, "Info", ("🌊 Algo gigantesco se mueve bajo el barco… Haced falta al menos %d pescadores preparados para el %s."):format(def.MinPlayers, def.Name))
			end
		end
	end
	return false
end

local function bossPull(player: Player)
	local b = boss
	if not b then
		return
	end
	local state = fishing[player]
	if not state or state.Water ~= "AltaMar" then
		return
	end
	if not canCatch(player, b.Def) then
		if not b.Warned[player] then
			b.Warned[player] = true
			Notify:FireClient(player, "Error", ("Tu equipo no aguanta al %s. Te falta: %s."):format(b.Def.Name, table.concat(missingFor(player, b.Def), ", ")))
		end
		return
	end
	local now = os.clock()
	if now - (b.Last[player] or 0) < Fishing.BossPullGap then
		return
	end
	b.Last[player] = now
	b.Pulls[player] = (b.Pulls[player] or 0) + 1
	anim(player, "Heave")
	b.Hp -= 1
	if b.Hp <= 0 then
		bossEnd(true)
	end
end

---------------------------------------------------------------------
-- Pescar
---------------------------------------------------------------------

local function cast(player: Player, spot: BasePart)
	local rod = rodOf(player)
	if not rod then
		Notify:FireClient(player, "Info", "Necesitas una caña de pescar. Cómprala en la tienda de pesca del centro 🎣")
		return
	end
	local state = fishing[player]
	if state and state.Spot ~= spot then
		stop(player, true)
		state = nil
	end
	if spotOwner[spot] and spotOwner[spot] ~= player then
		Notify:FireClient(player, "Info", "Aquí ya está pescando " .. nameOf(spotOwner[spot] :: Player) .. ".")
		return
	end
	if SeaEvents.oilAt(spot.Position) then
		Notify:FireClient(player, "Info", "🛢️ El agua está manchada de petróleo: aquí no pica nada. ¡Ayuda a limpiar la marea negra!")
		if spot:GetAttribute("Temporary") then
			spot:Destroy()
		end
		return
	end
	spotOwner[spot] = player
	local water = spot:GetAttribute("Water") or "Mar"
	if not Fishing.Waters[water] then
		water = "Mar"
	end
	-- Cuánto tardan en picar: caña, cebo y oficio
	local delay = rng:NextNumber(Fishing.BiteMin, Fishing.BiteMax) * rod.Bite
	local bait = InventoryService.count(player, Fishing.Bait.Id) > 0
	if bait then
		InventoryService.remove(player, Fishing.Bait.Id, 1)
		delay *= Fishing.Bait.Bite
	end
	if onDuty[player] then
		delay *= 0.85
	end
	nextToken += 1
	local token = nextToken
	fishing[player] = { Spot = spot, Token = token, Phase = "Wait", BiteAt = 0, Water = water }
	syncLevel(player)
	-- Mirando al agua
	local character = player.Character
	if character and not spot:GetAttribute("Temporary") then
		character:PivotTo(spot.CFrame * CFrame.new(0, 0.5, 0))
	end
	fire(player, "Cast", {
		Token = token,
		Bobber = bobberOf(spot),
		Water = Fishing.Waters[water] or "el agua",
		WaterId = water,
		Rod = rod.Name,
		Bait = bait,
		BaitLeft = InventoryService.count(player, Fishing.Bait.Id),
		Level = levelOf(player),
		Shoal = shoalPercent(water),
	})
	if boss and water == "AltaMar" then
		Remote:FireClient(player, "Boss", bossInfo(boss, player))
	end
	task.delay(delay, function()
		local now = fishing[player]
		if not now or now.Token ~= token or now.Phase ~= "Wait" then
			return
		end
		if water == "AltaMar" and maybeBoss(player) then
			now.Phase = "Done"
			fire(player, "Result", { Token = token, Kind = "Boss" })
			return
		end
		-- Lo que ha picado (según lo que queda en el agua; los que no puedes sacar pican menos)
		-- Con temporal en alta mar pican más peces raros
		local storm = if water == "AltaMar" and workspace:GetAttribute("SeaEvent") == "Temporal" then SeaEvents.Kinds.Temporal.RareBoost else 1
		local species, locked = Fishing.pick(water, (if rod then rod.Rare else 1) * storm, rng :: any, pop[water], function(sp)
			return canCatch(player, sp)
		end)
		now.Species = species
		now.Locked = locked
		now.Phase = "Bite"
		now.BiteAt = os.clock()
		local window = if species then species.Window else Fishing.Window
		now.Window = window
		local big = species ~= nil and (locked or Fishing.pullsFor(species, rodTier(player)) > 1)
		fire(player, "Bite", { Token = token, Window = window, Big = big })
		task.delay(window + LATENCY, function()
			local later = fishing[player]
			if later and later.Token == token and later.Phase == "Bite" then
				later.Phase = "Done"
				fire(player, "Result", { Token = token, Kind = "Late" })
			end
		end)
	end)
end

-- El pez sale del agua y va a la mochila
local function land(player: Player, state: State)
	local species = state.Species
	state.Phase = "Done"
	if not InventoryService.add(player, species.Item, 1) then
		fire(player, "Result", { Token = state.Token, Kind = "Full", Name = species.Name, Icon = species.Icon })
		return
	end
	consume(state.Water, species)
	local before = levelOf(player)
	addXp(player, species.Xp, species.Id)
	local kg = math.floor(rng:NextNumber(species.Kg[1], species.Kg[2]) * 100 + 0.5) / 100
	fire(player, "Result", {
		Token = state.Token,
		Kind = "Catch",
		Id = species.Id,
		Name = species.Name,
		Icon = species.Icon,
		Kg = kg,
		Rare = species.Rare == true,
		Rarity = species.Rarity,
		Price = species.Price,
		Xp = species.Xp,
		Level = levelOf(player),
		LevelUp = levelOf(player) > before,
		Shoal = shoalPercent(state.Water),
	})
	StoryEvents.emit(player, "CaughtFish", { Species = species.Id })
end

local function reel(player: Player, token: any)
	local state = fishing[player]
	if boss and state and state.Water == "AltaMar" and token == "Boss" then
		bossPull(player)
		return
	end
	if not state or state.Token ~= token then
		return
	end
	if state.Phase == "Wait" then
		state.Phase = "Done"
		fire(player, "Result", { Token = token, Kind = "Early" })
		return
	end
	if state.Phase == "Fight" then
		local now = os.clock()
		if now - (state.LastPull or 0) < 0.1 then
			return
		end
		state.LastPull = now
		state.Got = (state.Got or 0) + 1
		fire(player, "Pull", { Token = token, Got = state.Got, Need = state.Need })
		if (state.Got :: number) >= (state.Need :: number) then
			land(player, state)
		end
		return
	end
	if state.Phase ~= "Bite" then
		return
	end
	if os.clock() - state.BiteAt > (state.Window or Fishing.Window) + LATENCY then
		state.Phase = "Done"
		fire(player, "Result", { Token = token, Kind = "Late" })
		return
	end
	local species = state.Species
	if not species then
		state.Phase = "Done"
		local junk = Fishing.Junk[rng:NextInteger(1, #Fishing.Junk)]
		fire(player, "Result", { Token = token, Kind = "Junk", Name = junk.Name, Icon = junk.Icon })
		return
	end
	if state.Locked then
		-- Demasiado grande para ti: rompe el sedal y te dice qué te falta
		state.Phase = "Done"
		fire(player, "Result", { Token = token, Kind = "Locked", Name = species.Name, Icon = species.Icon, Missing = missingFor(player, species) })
		return
	end
	local need = Fishing.pullsFor(species, rodTier(player))
	if need <= 1 then
		land(player, state)
		return
	end
	-- Pelea: hay que seguir tirando antes de que se suelte
	state.Phase = "Fight"
	state.Need = need
	state.Got = 1
	state.LastPull = os.clock()
	local seconds = Fishing.fightSeconds(need)
	fire(player, "Fight", { Token = token, Need = need, Got = 1, Seconds = seconds, Name = species.Name, Icon = species.Icon, Rarity = species.Rarity })
	task.delay(seconds + LATENCY, function()
		local later = fishing[player]
		if later and later.Token == token and later.Phase == "Fight" then
			later.Phase = "Done"
			fire(player, "Result", { Token = token, Kind = "Escaped", Name = species.Name, Icon = species.Icon })
		end
	end)
end

---------------------------------------------------------------------
-- Pescar en cualquier agua ("Pescar aquí")
---------------------------------------------------------------------

-- Qué agua es según el sitio: lagos y río del plano de la ciudad; lo demás, mar
local function segmentDistance(p: Vector2, a: Vector2, b: Vector2): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

function FishingService.waterKind(position: Vector3): string
	local p = Vector2.new(position.X, position.Z)
	for _, lake in CityPlan.Lakes do
		if (p - Vector2.new(lake.X, lake.Z)).Magnitude < lake.R + 40 then
			return "Lago"
		end
	end
	local pts = CityPlan.River.Points
	for i = 1, #pts - 1 do
		if segmentDistance(p, Vector2.new(pts[i][1], pts[i][2]), Vector2.new(pts[i + 1][1], pts[i + 1][2])) < CityPlan.River.Width / 2 + 40 then
			return "Rio"
		end
	end
	return "Mar"
end

-- ¿Hay agua en ese punto? (terreno de agua; se puede cambiar en las pruebas)
function FishingService.isWater(point: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = false
	local hit = workspace:Raycast(Vector3.new(point.X, 12, point.Z), Vector3.new(0, -30, 0), params)
	return hit ~= nil and hit.Material == Enum.Material.Water
end

-- A qué distancia delante de ti hay agua (o nil)
local function waterAhead(root: BasePart): number?
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then
		return nil
	end
	flat = flat.Unit
	for _, d in { 6, 9, 12, 15 } do
		if FishingService.isWater(root.Position + flat * d) then
			return d + 2
		end
	end
	return nil
end

local function castHere(player: Player)
	if isBaby(player) then
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local distance = waterAhead(root)
	if not distance then
		Notify:FireClient(player, "Info", "Aquí no hay agua delante. Ponte mirando al agua, en la orilla.")
		return
	end
	if not rodOf(player) then
		Notify:FireClient(player, "Info", "Necesitas una caña de pescar. Cómprala en la tienda de pesca del centro 🎣")
		return
	end
	stop(player, true)
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z).Unit
	local spot = Instance.new("Part")
	spot.Name = "FishingSpotHere"
	spot.Size = Vector3.new(3, 5, 3)
	spot.Transparency = 1
	spot.Anchored = true
	spot.CanCollide = false
	spot.CanQuery = false
	spot.CanTouch = false
	spot.CFrame = CFrame.lookAt(root.Position - Vector3.new(0, 0.5, 0), root.Position - Vector3.new(0, 0.5, 0) + flat)
	-- En el barco de verdad (no vale haber vuelto nadando con el atributo puesto)
	local onBoat = false
	if player:GetAttribute("BoatReturn") ~= nil then
		for _, deck in CollectionService:GetTagged("FishingBoatDeck") do
			if deck:IsA("BasePart") and (deck.Position - root.Position).Magnitude < 40 then
				onBoat = true
			end
		end
	end
	spot:SetAttribute("Water", if onBoat then "AltaMar" else FishingService.waterKind(root.Position + flat * distance))
	spot:SetAttribute("CastDistance", distance)
	spot:SetAttribute("Temporary", true)
	spot.Parent = workspace
	cast(player, spot)
	if not fishing[player] then
		spot:Destroy()
	end
end

local function onSpot(player: Player, spot: BasePart)
	if isBaby(player) then
		Notify:FireClient(player, "Info", "Los bebés no pueden pescar.")
		return
	end
	local state = fishing[player]
	if state and state.Spot == spot and state.Phase ~= "Done" then
		stop(player)
		return
	end
	cast(player, spot)
end

---------------------------------------------------------------------
-- Tienda de pesca
---------------------------------------------------------------------

local function shopList(player: Player): { any }
	local level = levelOf(player)
	local list = {}
	for i = #Fishing.RodOrder, 1, -1 do
		local rod = Fishing.Rods[Fishing.RodOrder[i]]
		table.insert(list, { Id = rod.Id, Name = rod.Name, Icon = rod.Icon, Price = rod.Price, Desc = rod.Desc, Level = rod.Level, Locked = level < rod.Level, Owned = InventoryService.count(player, rod.Id) > 0 })
	end
	for _, id in Fishing.ToolOrder do
		local tool = Fishing.Tools[id]
		table.insert(list, { Id = tool.Id, Name = tool.Name, Icon = tool.Icon, Price = tool.Price, Desc = tool.Desc, Level = tool.Level, Locked = level < tool.Level, Owned = InventoryService.count(player, tool.Id) > 0 })
	end
	local bait = Fishing.Bait
	table.insert(list, { Id = bait.Id, Name = ("%s (x%d)"):format(bait.Name, bait.Pack), Icon = bait.Icon, Price = bait.Price, Desc = bait.Desc, Level = 1, Owned = false, Have = InventoryService.count(player, bait.Id) })
	return list
end

local function onBuy(player: Player, id: any)
	if typeof(id) ~= "string" then
		return
	end
	local gear = Fishing.Rods[id] or Fishing.Tools[id]
	local isBait = id == Fishing.Bait.Id
	if not gear and not isBait then
		return
	end
	local root = rootOf(player)
	local near = false
	for _, counter in CollectionService:GetTagged("FishingShopCounter") do
		if counter:IsA("BasePart") and root and (counter.Position - root.Position).Magnitude < 20 then
			near = true
		end
	end
	if not near then
		return
	end
	local price = if gear then gear.Price else Fishing.Bait.Price
	local count = if gear then 1 else Fishing.Bait.Pack
	if gear and InventoryService.count(player, gear.Id) > 0 then
		Notify:FireClient(player, "Info", "Ya tienes: " .. string.lower(gear.Name) .. ".")
		return
	end
	if gear and levelOf(player) < gear.Level then
		Notify:FireClient(player, "Info", ("🔒 %s pide nivel de pesca %d (tienes el %d). ¡Sigue pescando!"):format(gear.Name, gear.Level, levelOf(player)))
		return
	end
	if not InventoryService.canAdd(player, id, count) then
		Notify:FireClient(player, "Error", "No te cabe en la mochila.")
		return
	end
	if not DataService.spend(player, price) then
		Notify:FireClient(player, "Error", "No tienes dinero suficiente.")
		return
	end
	InventoryService.add(player, id, count)
	if Fishing.Rods[id] and lentRod[player] then
		lentRod[player] = nil -- ya tiene la suya: la prestada se queda (se devuelve al acabar el turno)
	end
	Notify:FireClient(player, "Success", ("🎣 Has comprado: %s."):format(if gear then gear.Name else ("%d de cebo"):format(count)))
	Remote:FireClient(player, "Shop", shopList(player))
end

---------------------------------------------------------------------
-- Barco de pesca
---------------------------------------------------------------------

local function first(tag: string): BasePart?
	for _, part in CollectionService:GetTagged(tag) do
		if part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function onDock(player: Player, dock: BasePart)
	if isBaby(player) then
		return
	end
	local deck = first("FishingBoatDeck")
	if not deck then
		return
	end
	if not onDuty[player] then
		if not DataService.spend(player, Fishing.BoatPrice) then
			Notify:FireClient(player, "Error", ("El barco cuesta %s y no tienes suficiente."):format(Format.money(Fishing.BoatPrice)))
			return
		end
		Notify:FireClient(player, "Info", ("⛴️ Alquiler del barco: %s. ¡Buena pesca en alta mar!"):format(Format.money(Fishing.BoatPrice)))
	else
		Notify:FireClient(player, "Info", "⛴️ ¡A faenar! En alta mar salen merluzas, gambas y hasta atunes.")
	end
	stop(player, true)
	local character = player.Character
	if character then
		character:PivotTo(deck.CFrame * CFrame.new(0, 3, 0))
	end
	player:SetAttribute("BoatReturn", dock.Position)
end

local function onReturn(player: Player)
	stop(player, true)
	local back = player:GetAttribute("BoatReturn")
	local dock = first("FishingBoatDock")
	local target = if typeof(back) == "Vector3" then back elseif dock then dock.Position else nil
	local character = player.Character
	if character and target then
		character:PivotTo(CFrame.new(target + Vector3.new(0, 1, -5)))
	end
	player:SetAttribute("BoatReturn", nil)
end

---------------------------------------------------------------------
-- Vender en la pescadería
---------------------------------------------------------------------

local function onSell(player: Player, counter: BasePart)
	if fishCount(player) == 0 then
		Notify:FireClient(player, "Info", "No llevas pescado. ¡Ve a pescar! 🎣")
		return
	end
	local total, sold, full = 0, 0, {}
	local bonus = if onDuty[player] then JOB.PayBonus * MonetizationService.payMultiplier(player) else 1
	for _, species in Fishing.Species do
		local have = InventoryService.count(player, species.Item)
		if have > 0 and species.Product then
			local n = math.min(have, SupermarketService.fishRoom(counter, species.Product))
			if n > 0 and InventoryService.remove(player, species.Item, n) then
				local put = SupermarketService.addFish(counter, species.Product, n)
				if put < n then
					InventoryService.add(player, species.Item, n - put) -- lo que no ha cabido, te lo quedas
				end
				sold += put
				total += math.floor(species.Price * put * bonus + 0.5)
			end
			if n < have then
				table.insert(full, species.Name)
			end
		elseif have > 0 and InventoryService.remove(player, species.Item, have) then
			-- La lonja compra todo lo que el supermercado no vende
			sold += have
			total += math.floor(species.Price * have * bonus + 0.5)
		end
	end
	for _, def in Fishing.Bosses do
		local have = InventoryService.count(player, def.Item)
		if have > 0 and InventoryService.remove(player, def.Item, have) then
			sold += have
			total += def.Price * have
		end
	end
	if sold == 0 then
		Notify:FireClient(player, "Info", "La pescadería está llena de eso ahora mismo. Prueba en otro supermercado.")
		return
	end
	DataService.addMoney(player, total, true)
	Notify:FireClient(player, "Money", ("+%s · has vendido %d %s a la pescadería"):format(Format.money(total), sold, if sold == 1 then "pieza" else "piezas"))
	if #full > 0 then
		Notify:FireClient(player, "Info", "No caben más de: " .. table.concat(full, ", ") .. ". Te los quedas (véndelos en otro supermercado).")
	end
	if onDuty[player] then
		local data = DataService.get(player)
		if data and data.Stats then
			data.Stats.TasksDone += 1
		end
		NeedsService.change(player, 0, -JOB.EnergyCost)
		StoryEvents.emit(player, "JobTaskDone", { JobId = "Pescador", Pay = total })
		if not NeedsService.canWork(player) then
			FishingService.quit(player, true)
			Notify:FireClient(player, "Error", "Estás agotado. Come algo o duerme antes de seguir trabajando.")
		end
	end
end

---------------------------------------------------------------------
-- Oficio de pescador
---------------------------------------------------------------------

local function nearestTagged(tag: string, from: Vector3): BasePart?
	local best, bestD = nil, math.huge
	for _, part in CollectionService:GetTagged(tag) do
		if part:IsA("BasePart") then
			local d = (part.Position - from).Magnitude
			if d < bestD then
				best, bestD = part, d
			end
		end
	end
	return best
end

local function guide(player: Player)
	local root = rootOf(player)
	if not root then
		return
	end
	if fishCount(player) >= JOB.CarryGoal then
		local counter = nearestTagged("SuperFish", root.Position)
		player:SetAttribute("TaskTarget", if counter then counter.Position else nil)
		player:SetAttribute("TaskText", ("Lleva el pescado (%d) a la pescadería del supermercado"):format(fishCount(player)))
	else
		local spot = if fishing[player] then fishing[player].Spot else nearestTagged("FishingSpot", root.Position)
		player:SetAttribute("TaskTarget", if spot then spot.Position else nil)
		player:SetAttribute("TaskText", ("Pesca (%d/%d) en el muelle, el río, los lagos o el barco"):format(fishCount(player), JOB.CarryGoal))
	end
end

function FishingService.start(player: Player)
	if not DataService.get(player) or not LifeService.allows(player, "Work") then
		return
	end
	if not NeedsService.canWork(player) then
		Notify:FireClient(player, "Error", "Estás demasiado cansado o hambriento para trabajar.")
		return
	end
	JobService.quit(player, true)
	onDuty[player] = true
	if not rodOf(player) and InventoryService.add(player, "CanaPescar", 1) then
		lentRod[player] = true
		Notify:FireClient(player, "Info", "🎣 Te prestan una caña de pescar mientras trabajas.")
	end
	RoleService.setOnDuty(player, "Pescador")
	player:SetAttribute("Job", "Pescador")
	Remote:FireClient(player, "JobStart")
	Notify:FireClient(player, "Success", "¡A pescar! Llena la mochila y vende el pescado en el supermercado. El barco de pesca te sale gratis.")
	guide(player)
end

function FishingService.quit(player: Player, silent: boolean?)
	if not onDuty[player] then
		return
	end
	onDuty[player] = nil
	if lentRod[player] then
		lentRod[player] = nil
		stop(player, true)
		-- Si ya no la tiene (la ha vendido o cambiado), se le cobra: así no se duplican cañas
		if not InventoryService.remove(player, "CanaPescar", 1) then
			local price = Fishing.Rods.CanaPescar.Price
			DataService.addMoney(player, -price)
			Notify:FireClient(player, "Error", ("🎣 No has devuelto la caña prestada: se te cobra (%s)."):format(Format.money(price)))
		end
	end
	RoleService.offDuty(player, "Pescador")
	if player:GetAttribute("Job") == "Pescador" then
		player:SetAttribute("Job", nil)
	end
	player:SetAttribute("TaskTarget", nil)
	player:SetAttribute("TaskText", nil)
	Remote:FireClient(player, "JobStop")
	if not silent then
		Notify:FireClient(player, "Info", "Has terminado tu jornada de pesca.")
	end
end

---------------------------------------------------------------------
-- Pescador NPC del puerto
---------------------------------------------------------------------

local npcModel: Model? = nil

local function refreshNpc()
	local spot = first("FishingNpcSpot")
	if not spot then
		return
	end
	local near = false
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		if root and (root.Position - spot.Position).Magnitude < 250 then
			near = true
			break
		end
	end
	if near and not npcModel then
		local folder = spot.Parent :: Instance
		npcModel = Npc.create("Npc_Pescador", folder, spot.CFrame * CFrame.new(0, 0.5, 0), { Shirt = Color3.fromRGB(230, 200, 60), Pants = Color3.fromRGB(40, 60, 90) })
		local rod = Instance.new("Part")
		rod.Name = "Rod"
		rod.Size = Vector3.new(0.15, 0.15, 8)
		rod.Anchored = true
		rod.CanCollide = false
		rod.CanQuery = false
		rod.Color = Color3.fromRGB(40, 40, 44)
		rod.CFrame = spot.CFrame * CFrame.new(0.9, 1.4, -3.6) * CFrame.Angles(math.rad(25), 0, 0)
		rod.Parent = npcModel
	elseif not near and npcModel then
		npcModel:Destroy()
		npcModel = nil
	end
end

-- Si ningún jugador pesca de turno, el pescador del puerto lleva un poco de pescado a un supermercado
local function npcDelivery()
	for _ in onDuty do
		return
	end
	local counters = CollectionService:GetTagged("SuperFish")
	if #counters == 0 then
		return
	end
	local counter = counters[rng:NextInteger(1, #counters)]
	for _ = 1, Fishing.NpcDeliveryCount do
		local species = Fishing.roll("Mar", 1, rng :: any)
		if species and species.Product then
			SupermarketService.addFish(counter, species.Product, 1)
		end
	end
end

---------------------------------------------------------------------

local function prompt(parent: BasePart, action: string, object: string, hold: number, distance: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = distance or 8
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function setupSpot(spot: Instance)
	if not spot:IsA("BasePart") or spot:FindFirstChild("FishPrompt") then
		return
	end
	local p = prompt(spot, "Pescar", "🎣 Sitio de pesca", 0.2, 7)
	p.Name = "FishPrompt"
	p.Triggered:Connect(function(player)
		onSpot(player, spot)
	end)
end

local function setupCounter(counter: Instance)
	if not counter:IsA("BasePart") or counter:FindFirstChild("SellPrompt") then
		return
	end
	local p = prompt(counter, "Vender pescado", "🐟 Pescadería", 0.5, 9)
	p.Name = "SellPrompt"
	p.Triggered:Connect(function(player)
		onSell(player, counter)
	end)
end

local function setupShop(counter: Instance)
	if not counter:IsA("BasePart") or counter:FindFirstChild("ShopPrompt") then
		return
	end
	local p = prompt(counter, "Comprar", "🎣 Tienda de pesca", 0.3, 10)
	p.Name = "ShopPrompt"
	p.Triggered:Connect(function(player)
		Remote:FireClient(player, "Shop", shopList(player))
	end)
	local spot = counter:GetAttribute("StaffSpot")
	if typeof(spot) == "Vector3" then
		local clerk = Npc.create("Npc_TenderoPesca", counter.Parent :: Instance, CFrame.lookAt(spot + Vector3.new(0, 3, 0), counter.Position * Vector3.new(1, 0, 1) + Vector3.new(0, spot.Y + 3, 0)), { Shirt = Color3.fromRGB(40, 110, 60), Pants = Color3.fromRGB(90, 70, 50) })
		local _ = clerk
	end
end

local function setupDock(dock: Instance)
	if not dock:IsA("BasePart") or dock:FindFirstChild("DockPrompt") then
		return
	end
	local p = prompt(dock, "Subir al barco de pesca", ("⛴️ Alta mar (%s; gratis para pescadores)"):format(Format.money(Fishing.BoatPrice)), 0.5, 10)
	p.Name = "DockPrompt"
	p.Triggered:Connect(function(player)
		onDock(player, dock)
	end)
end

local function setupReturn(board: Instance)
	if not board:IsA("BasePart") or board:FindFirstChild("ReturnPrompt") then
		return
	end
	local p = prompt(board, "Volver a puerto", "⛴️ Barco de pesca", 0.5, 10)
	p.Name = "ReturnPrompt"
	p.Triggered:Connect(onReturn)
end

function FishingService.init()
	for tag, fn in { FishingSpot = setupSpot, SuperFish = setupCounter, FishingShopCounter = setupShop, FishingBoatDock = setupDock, FishingBoatReturn = setupReturn } do
		for _, part in CollectionService:GetTagged(tag) do
			fn(part)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
	end
	JobService.setHandler("Pescador", { Start = FishingService.start, Quit = FishingService.quit })
	DataService.onLoaded(function(player)
		syncLevel(player)
	end)
	Remote.OnServerEvent:Connect(function(player, action, a)
		if action == "Reel" then
			reel(player, a)
		elseif action == "Again" then
			local state = fishing[player]
			if state and state.Phase == "Done" then
				cast(player, state.Spot)
			end
		elseif action == "Stop" then
			stop(player)
		elseif action == "Here" then
			castHere(player)
		elseif action == "Buy" then
			onBuy(player, a)
		elseif action == "Shop" then
			-- (la tienda se abre desde el mostrador; esto solo la refresca si sigues cerca)
			local root = rootOf(player)
			for _, counter in CollectionService:GetTagged("FishingShopCounter") do
				if counter:IsA("BasePart") and root and (counter.Position - root.Position).Magnitude < 20 then
					Remote:FireClient(player, "Shop", shopList(player))
					break
				end
			end
		end
	end)
	-- Al reaparecer (p. ej. tras morir) ya no estás en el barco
	local function watchBoat(player: Player)
		player.CharacterAdded:Connect(function()
			player:SetAttribute("BoatReturn", nil)
		end)
	end
	Players.PlayerAdded:Connect(watchBoat)
	for _, player in Players:GetPlayers() do
		watchBoat(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		stop(player, true)
		FishingService.quit(player, true)
		onDuty[player] = nil
		lentRod[player] = nil
	end)
	task.spawn(function()
		local sinceDelivery = 0
		while true do
			task.wait(1)
			local ok, err = pcall(function()
				-- Si te alejas del sitio, se recoge el sedal
				for player, state in fishing do
					local root = rootOf(player)
					if not root or (root.Position - state.Spot.Position).Magnitude > Fishing.MoveCancel then
						stop(player)
					end
				end
				for player in onDuty do
					guide(player)
				end
				regenTick()
				refreshNpc()
				sinceDelivery += 1
				if sinceDelivery >= Fishing.NpcDeliveryEvery then
					sinceDelivery = 0
					npcDelivery()
				end
			end)
			if not ok then
				warn("[FishingService] " .. tostring(err))
			end
		end
	end)
end

-- Para la pesca submarina (DivingService)
FishingService.levelOf = levelOf
FishingService.toolsOf = toolsOf
FishingService.addXp = addXp
FishingService.consume = consume
FishingService.pop = pop

-- Qué agua hay en un sitio: cerca del barco de pesca es alta mar
function FishingService.waterAt(position: Vector3): string
	local deck = first("FishingBoatDeck")
	if deck and (Vector2.new(deck.Position.X, deck.Position.Z) - Vector2.new(position.X, position.Z)).Magnitude < Fishing.Dive.BoatRadius then
		return "AltaMar"
	end
	return FishingService.waterKind(position)
end

-- Para las pruebas
FishingService._fishing = fishing
FishingService._pop = pop
FishingService._startBoss = startBoss
FishingService._cast = cast
FishingService._boss = function()
	return boss
end
FishingService._shoal = shoalPercent

return FishingService
