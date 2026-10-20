-- TefraService (servidor): la VIDA de Bastión Ceniza que no es de un oficio (docs/planetas/tefra-misiones.md):
--
--   * 🌡 CALOR (la desventaja de Tefra, shared/Cosmos/TefraHeat): un medidor por jugador mientras está a
--     pie en Tefra. Lo decide el servidor dos veces por segundo con dónde está (lava, barrio, refugio,
--     fuera de la muralla, el crisol o la colada de los oficios) y lo que lleva (traje refrigerado en la
--     mochila, gel térmico). Atributos del jugador: TefraCalor (0-100), TefraFase (Normal/Aviso/Peligro)
--     y HeatSlow (lo que te frena: NeedsService lo aplica al andar). En Peligro pierdes vida poco a poco
--     y, si sigue, te DERRIBA el calor: despiertas en el refugio más cercano, sin perder nada. Avisa a
--     la historia: HeatChanged { Phase } y, al bajar de Aviso o Peligro a Normal, HazardSurvived {
--     Hazard = "Calor" }.
--   * 🚨 BOMBARDEOS CON HORARIO (shared/Cosmos/TefraWar): dos al día de juego, iguales para todo el
--     servidor. Sirenas 60 s antes (aviso en pantalla, zonas rojas en el suelo y en el atributo de
--     workspace TefraWar, JSON, para el HUD), fuego (explosiones SIN daño: quien está en una zona y fuera
--     de un refugio queda «Derribado» y despierta en el refugio), y después escombros para los oficios
--     (TefraJobService), pan de sirena en la Panadería y HazardSurvived { Hazard = "Bombardeo" } para
--     quien lo pasó sin que le alcanzara. Nunca en mitad de una escena o una conversación.
--   * ⚒ LA FORJA DE BASTIÓN (shared/Cosmos/TefraCraft): «Fabricar» abre una conversación con las recetas
--     (y refinar la obsidiana de la bodega de tu nave). Avisa: ItemCrafted { Item }.
--   * 🍄 El invernadero (liquen térmico y setas, cada cierto tiempo) y el pan de sirena.
-- Los avisos del mundo son del tipo "Tefra" (World/TefraCityBuilder → PlanetWorld → PlanetService).
-- Nada se guarda aparte: lo de la mochila va a data.Items (InventoryService) y el tiempo pasado en
-- Tefra (ayuda de las primeras horas) a data.Story.Counters.TefraSegundos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Tefra = require(Shared.Cosmos.Tefra)
local TefraCity = require(Shared.Cosmos.TefraCity)
local TefraHeat = require(Shared.Cosmos.TefraHeat)
local TefraWar = require(Shared.Cosmos.TefraWar)
local TefraCraft = require(Shared.Cosmos.TefraCraft)
local Items = require(Shared.Items)
local GameClock = require(Shared.GameClock)

local StoryEvents = require(script.Parent.Parent.LifeStory.StoryEvents)

local TefraService = {}

TefraService.Tick = 0.5
TefraService.LiquenCooldown = 90
TefraService.PanSirenaSeconds = 300 -- tras un bombardeo, el pan se reparte durante este rato

local function service(name: string): any
	return require(script.Parent[name])
end

type HeatState = {
	Heat: number,
	Phase: string,
	Full: number, -- segundos con el medidor lleno
	GelUntil: number,
	WasHot: boolean, -- estuvo en Aviso o Peligro (para «sobrevivir al calor»)
	Slow: number,
}
local heat: { [Player]: HeatState } = {}
local liquenAt: { [Player]: number } = {}
local panRaid: { [Player]: string } = {}
local notify: RemoteEvent? = nil

-- (el reloj se puede cambiar en las pruebas: TefraService.Clock)
TefraService.Clock = os.clock
local function now(): number
	return TefraService.Clock()
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function dataOf(player: Player): { [string]: any }?
	local ok, data = pcall(function()
		return service("DataService").get(player)
	end)
	return if ok then data else nil
end

-- ¿Está a pie en Tefra? (no en la nave)
function TefraService.onFoot(player: Player): boolean
	if player:GetAttribute("Planeta") ~= Tefra.Id then
		return false
	end
	local root = rootOf(player)
	if not root or not Tefra.inRegion(root.Position) then
		return false
	end
	local ok, world = pcall(function()
		return service("AirCombatService").world(player)
	end)
	return not (ok and world ~= nil)
end

-- ¿En mitad de una escena o una conversación? (ni daño, ni derribos, ni avisos que tapen)
local function busy(player: Player): boolean
	return player:GetAttribute("InScene") == true or player:GetAttribute("InDialogue") == true or player:GetAttribute("InCinematic") == true
end

---------------------------------------------------------------------
-- Calor
---------------------------------------------------------------------
-- Lo que calienta junto a los oficios (crisoles siempre; coladas activas: TefraJobService.hotSpots)
local function hotSpots(): { Vector3 }
	local ok, list = pcall(function()
		return service("TefraJobService").hotSpots()
	end)
	return if ok and type(list) == "table" then list else {}
end

-- El contexto del calor para un jugador (lo que lee TefraHeat.rate)
function TefraService.heatContext(player: Player, position: Vector3, data: { [string]: any }?): TefraHeat.Context
	local lx, lz = Tefra.toLocal(position)
	local base = Tefra.Origin.Y + Tefra.padY()
	local inside = TefraCity.inside(lx, lz, TefraCity.Bank)
	local ctx: TefraHeat.Context = {}
	local lava = TefraHeat.lavaDistance(lx, lz)
	if TefraHeat.onBridge(lx, lz) then
		lava = math.max(lava, 10) -- (el puente va por encima de la lava)
	end
	ctx.Lava = lava
	local district = inside and TefraCity.districtAt(lx, lz)
	ctx.District = district and district.Id or nil
	ctx.Outside = not inside
	local clock = GameClock.hour()
	ctx.Day = clock >= 9 and clock < 19
	-- Refugio: dentro de la planta baja de un edificio refugio (no en el tejado)
	local _, shelter = TefraCity.shelterAt(lx, lz)
	if shelter and position.Y - base < 14 then
		ctx.Shelter = shelter.Cool
	end
	local hot = {}
	for _, p in hotSpots() do
		local d = Vector3.new(p.X - position.X, 0, p.Z - position.Z).Magnitude
		if d < 30 and math.abs(p.Y - position.Y) < 20 then
			table.insert(hot, d)
		end
	end
	ctx.Hot = hot
	local items = data and data.Items
	ctx.Suit = TefraHeat.suitFactor(items)
	local st = heat[player]
	ctx.Gel = st ~= nil and st.GelUntil > now()
	local counters = data and data.Story and data.Story.Counters
	ctx.Newbie = (tonumber(counters and counters.TefraSegundos) or 0) < TefraHeat.NewbieSeconds
	return ctx
end

local function setSlow(player: Player, st: HeatState, factor: number)
	if math.abs(st.Slow - factor) < 1e-3 then
		return
	end
	st.Slow = factor
	player:SetAttribute("HeatSlow", if factor < 1 then factor else nil)
	pcall(function()
		service("NeedsService").refreshSpeed(player)
	end)
end

local function clearHeat(player: Player)
	local st = heat[player]
	if st then
		setSlow(player, st, 1)
	end
	heat[player] = nil
	player:SetAttribute("TefraCalor", nil)
	player:SetAttribute("TefraFase", nil)
	player:SetAttribute("HeatSlow", nil)
end

-- Te derriba el calor o la onda de una bomba: despiertas dentro del refugio más cercano, sin perder nada
function TefraService.knockDown(player: Player, why: string)
	local root = rootOf(player)
	if not root then
		return
	end
	local lx, lz = Tefra.toLocal(root.Position)
	local _, _, id = TefraCity.nearestShelter(lx, lz)
	local ix, iz = TefraCity.shelterInside(id)
	local base = Tefra.Origin.Y + Tefra.padY()
	local target = Tefra.toWorld(ix, iz, base + 3)
	local humanoid = humanoidOf(player)
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = math.max(humanoid.Health, humanoid.MaxHealth * 0.5)
	end
	local ok = pcall(function()
		service("SceneService").teleportTo(player, target, { Dip = true })
	end)
	if not ok then
		root.CFrame = CFrame.new(target)
	end
	local shelter = TefraCity.Shelters[id]
	toast(player, "Info", ("%s Despiertas en %s. No has perdido nada."):format(why, shelter and shelter.Name or "un refugio"))
end

local function stepHeat(player: Player, dt: number)
	if not TefraService.onFoot(player) then
		if heat[player] then
			clearHeat(player)
		end
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local data = dataOf(player)
	local st = heat[player]
	if not st then
		st = { Heat = 0, Phase = "Normal", Full = 0, GelUntil = 0, WasHot = false, Slow = 1 }
		heat[player] = st
	end
	-- (el tiempo en Tefra: la ayuda de las primeras horas)
	if data and type(data.Story) == "table" then
		data.Story.Counters = if type(data.Story.Counters) == "table" then data.Story.Counters else {}
		data.Story.Counters.TefraSegundos = (tonumber(data.Story.Counters.TefraSegundos) or 0) + dt
	end
	local ctx = TefraService.heatContext(player, root.Position, data)
	st.Heat = TefraHeat.step(st.Heat, ctx, dt)
	st.Full = if st.Heat >= TefraHeat.Max then st.Full + dt else 0
	local phase = TefraHeat.phase(st.Heat)
	if phase ~= st.Phase then
		local before = st.Phase
		st.Phase = phase
		StoryEvents.emit(player, "HeatChanged", { Phase = phase, From = before })
		if phase == "Normal" and st.WasHot then
			st.WasHot = false
			StoryEvents.emit(player, "HazardSurvived", { Hazard = "Calor" })
		end
		if phase ~= "Normal" then
			st.WasHot = true
			if not busy(player) then
				toast(player, if phase == "Peligro" then "Error" else "Info", if phase == "Peligro"
					then "🥵 ¡Demasiado calor! Pierdes vida: usa 🧴 gel térmico o métete en un refugio 🛡"
					else "🌡 Hace mucho calor: vas más lento. Aléjate de la lava o busca un refugio")
			end
		end
	end
	setSlow(player, st, TefraHeat.slow(phase))
	player:SetAttribute("TefraCalor", math.floor(st.Heat + 0.5))
	player:SetAttribute("TefraFase", phase)
	-- Peligro: pierdes vida despacio (nunca de golpe); con el medidor lleno un rato, te derriba
	if phase == "Peligro" and not busy(player) then
		local humanoid = humanoidOf(player)
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = math.max(TefraHeat.KnockHealth - 1, humanoid.Health - TefraHeat.DangerDamage * dt)
			if TefraHeat.knocked(st.Heat, st.Full, humanoid.Health) then
				st.Heat = TefraHeat.AfterKnock
				st.Full = 0
				TefraService.knockDown(player, "🥵 El calor te ha derribado.")
			end
		end
	end
end

-- El gel térmico (desde la mochila: InventoryService.onUse)
function TefraService.useGel(player: Player): boolean
	local Inventory = service("InventoryService")
	if Inventory.count(player, "GelTermico") <= 0 then
		return false
	end
	if player:GetAttribute("Planeta") ~= Tefra.Id then
		toast(player, "Info", "🧴 El gel térmico solo hace falta en Tefra. Guárdalo.")
		return false
	end
	Inventory.remove(player, "GelTermico", 1)
	local st = heat[player]
	if not st then
		st = { Heat = 0, Phase = "Normal", Full = 0, GelUntil = 0, WasHot = false, Slow = 1 }
		heat[player] = st
	end
	st.Heat = math.max(0, st.Heat - TefraHeat.GelDrop)
	st.GelUntil = now() + TefraHeat.GelSeconds
	player:SetAttribute("TefraCalor", math.floor(st.Heat + 0.5))
	toast(player, "Success", "🧴 Gel térmico: el calor baja y durante un minuto casi no sube")
	return true
end

function TefraService.heatOf(player: Player): number
	local st = heat[player]
	return st and st.Heat or 0
end

---------------------------------------------------------------------
-- Bombardeos
---------------------------------------------------------------------
type Raid = { Key: string, State: string, Zones: { { [string]: any } }, FireAt: number, EndAt: number, AfterUntil: number, Hit: { [Player]: boolean }, Seen: { [Player]: boolean }, Shells: number }
local raid: Raid? = nil
local lastRaid: Raid? = nil
local doneRaids: { [string]: boolean } = {}
local markers: Instance? = nil

local function tefraPlayers(): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Planeta") == Tefra.Id then
			table.insert(out, p)
		end
	end
	return out
end

-- ¿Vive el planeta la tregua? (todos los que están en Tefra han vivido el alto el fuego)
local function tregua(list: { Player }): boolean
	if #list == 0 then
		return false
	end
	for _, p in list do
		local data = dataOf(p)
		local flags = data and data.Story and data.Story.Flags
		if not (flags and flags.TreguaTefra) then
			return false
		end
	end
	return true
end

local function publishRaid()
	if not raid then
		workspace:SetAttribute("TefraWar", nil)
		return
	end
	local zones = {}
	for _, z in raid.Zones do
		table.insert(zones, { Id = z.Id, Name = z.Name, X = z.X, Z = z.Z, R = z.R })
	end
	local okNow, serverNow = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	if not okNow or type(serverNow) ~= "number" then
		serverNow = os.time()
	end
	workspace:SetAttribute("TefraWar", HttpService:JSONEncode({
		State = raid.State,
		Zones = zones,
		FireAt = serverNow + (raid.FireAt - now()),
		EndAt = serverNow + (raid.EndAt - now()),
	}))
end

local function clearMarkers()
	if markers then
		markers:Destroy()
		markers = nil
	end
end

-- Zonas rojas en el suelo (las ve todo el mundo: es la ciudad entera la que se prepara)
local function showMarkers(zones: { { [string]: any } })
	clearMarkers()
	local folder = Instance.new("Folder")
	folder.Name = "ZonasBombardeo"
	local base = Tefra.Origin.Y + Tefra.padY()
	for _, z in zones do
		local disc = Instance.new("Part")
		disc.Name = "Zona_" .. z.Id
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.3, z.R * 2, z.R * 2)
		disc.CFrame = CFrame.new(Tefra.toWorld(z.X, z.Z, base + 1.15)) * CFrame.Angles(0, 0, math.pi / 2)
		disc.Anchored = true
		disc.CanCollide = false
		disc.CanQuery = false
		disc.CanTouch = false
		disc.CastShadow = false
		disc.Material = Enum.Material.Neon
		disc.Color = Color3.fromRGB(255, 60, 40)
		disc.Transparency = 0.7
		disc.Parent = folder
	end
	local ok, root = pcall(function()
		return require(script.Parent.Parent.World.PlanetWorld).folder()
	end)
	folder.Parent = if ok and root then root else workspace
	markers = folder
end

-- Una explosión SIN daño (BlastPressure y DestroyJointRadiusPercent a 0: solo se ve y se oye)
local function boom(position: Vector3)
	local e = Instance.new("Explosion")
	e.Position = position
	e.BlastRadius = 14
	e.BlastPressure = 0
	e.DestroyJointRadiusPercent = 0
	e.ExplosionType = Enum.ExplosionType.NoCraters
	e.Parent = markers or workspace
end

-- Empieza un bombardeo (las sirenas). force = para el modo pruebas y las pruebas
function TefraService.startRaid(key: string?, slot: number?, warnSeconds: number?)
	if raid then
		return raid
	end
	local day = workspace:GetAttribute("Day") or 1
	local k = key or ("prueba:" .. tostring(os.clock()))
	local t = now()
	local warn = warnSeconds or TefraWar.WarnSeconds
	raid = {
		Key = k,
		State = "Aviso",
		Zones = TefraWar.pickZones(day, slot or 1),
		FireAt = t + warn,
		EndAt = t + warn + TefraWar.FireSeconds,
		AfterUntil = t + warn + TefraWar.FireSeconds + TefraWar.AfterSeconds,
		Hit = {},
		Seen = {},
		Shells = 0,
	}
	doneRaids[k] = true
	showMarkers(raid.Zones)
	publishRaid()
	for _, p in tefraPlayers() do
		raid.Seen[p] = true
		toast(p, "Error", TefraWar.warnText(raid.Zones, warn))
	end
	return raid
end

-- Lo que pasa en cada vuelta durante un bombardeo
local function stepRaid()
	local r = raid
	if not r then
		return
	end
	local t = now()
	if r.State == "Aviso" and t >= r.FireAt then
		r.State = "Fuego"
		publishRaid()
		for _, p in tefraPlayers() do
			r.Seen[p] = true
			toast(p, "Error", "💥 ¡Fuego de Ovilla! Quédate en el refugio hasta que paren")
		end
	end
	if r.State == "Fuego" then
		-- Proyectiles en las zonas y quien está al descubierto, derribado (una vez por bombardeo)
		local base = Tefra.Origin.Y + Tefra.padY()
		r.Shells += 1
		if r.Shells % 3 == 1 then -- (una cada vuelta y media por zona: se ve y no satura)
			for i, z in r.Zones do
				local shells = TefraWar.shells(z, r.Shells * 31 + i, 1)
				local s = shells[1]
				boom(Tefra.toWorld(s[1], s[2], base + 2))
			end
		end
		for _, p in tefraPlayers() do
			r.Seen[p] = true
			local root = rootOf(p)
			if root and not r.Hit[p] and TefraService.onFoot(p) and not busy(p) then
				local lx, lz = Tefra.toLocal(root.Position)
				local sheltered = TefraCity.shelterAt(lx, lz) ~= nil and root.Position.Y - base < 14
				if not sheltered and TefraWar.zoneAt(r.Zones, lx, lz) then
					r.Hit[p] = true
					TefraService.knockDown(p, "💥 Te ha alcanzado la onda de una bomba (Derribado, sin heridas).")
				end
			end
		end
		if t >= r.EndAt then
			r.State = "Despues"
			publishRaid()
			clearMarkers()
			for p in r.Seen do
				if p.Parent and not r.Hit[p] and p:GetAttribute("Planeta") == Tefra.Id then
					StoryEvents.emit(p, "HazardSurvived", { Hazard = "Bombardeo" })
					toast(p, "Success", "🕊 Han parado. Hay gente atrapada entre los escombros (rescatista, ingeniero: paga extra) y en la Panadería del Ovillo reparten pan de sirena")
				elseif p.Parent and r.Hit[p] then
					toast(p, "Info", "🕊 Han parado las bombas. En la Panadería del Ovillo reparten pan de sirena")
				end
			end
			lastRaid = r
		end
	end
	if r.State == "Despues" and t >= r.AfterUntil then
		raid = nil
		publishRaid()
	end
end

-- El último bombardeo que ya acabó (o el de ahora, si ya está en «después»): para los oficios
function TefraService.recentRaid(): Raid?
	if raid and raid.State == "Despues" then
		return raid
	end
	if lastRaid and now() < lastRaid.AfterUntil + TefraWar.AfterSeconds * 3 then
		return lastRaid
	end
	return nil
end

function TefraService.raidState(): string?
	return raid and raid.State or nil
end

-- ¿Toca un bombardeo del horario? (cada vuelta)
local function scheduleRaid()
	if raid then
		return
	end
	local list = tefraPlayers()
	if #list == 0 then
		return
	end
	local clock = GameClock.hour()
	local day = workspace:GetAttribute("Day") or 1
	local lead = TefraWar.gameHours(TefraWar.WarnSeconds, Config.DayLengthMinutes)
	local key, slot, left = TefraWar.due(clock, day, lead, doneRaids, tregua(list))
	if key and slot and left then
		local seconds = left / lead * TefraWar.WarnSeconds
		TefraService.startRaid(key, slot, math.max(10, seconds))
	end
end

---------------------------------------------------------------------
-- La Forja, el invernadero y el pan de sirena (avisos del tipo "Tefra")
---------------------------------------------------------------------
local function itemName(id: string): string
	local item = Items.get(id)
	return if item then item.Icon .. " " .. item.Name else id
end

-- Fabricar una receta (o refinar). Devuelve ok y el texto para el jugador
function TefraService.craft(player: Player, id: string): (boolean, string)
	local data = dataOf(player)
	if not data then
		return false, "Ahora no se puede"
	end
	local Inventory = service("InventoryService")
	local Data = service("DataService")
	if id == "Refinar" then
		local sp = type(data.Space) == "table" and data.Space or nil
		local ore = sp and type(sp.Ore) == "table" and (tonumber(sp.Ore[TefraCraft.RefineOre]) or 0) or 0
		if ore <= 0 then
			return false, "No llevas obsidiana en la bodega de la nave (se mina a pie en Tefra: «Extraer»)"
		end
		if not Data.spend(player, TefraCraft.RefineCost) then
			return false, ("Refinar cuesta %d €"):format(TefraCraft.RefineCost)
		end
		sp.Ore[TefraCraft.RefineOre] = ore - 1
		Inventory.add(player, TefraCraft.RefineItem, 1)
		StoryEvents.emit(player, "ItemCrafted", { Item = TefraCraft.RefineItem, Refined = true })
		return true, "🔥 Refinas una pieza de obsidiana: " .. itemName(TefraCraft.RefineItem)
	end
	local recipe = TefraCraft.ById[id]
	if not recipe then
		return false, "Esa receta no existe"
	end
	local items = {}
	for item in recipe.Needs do
		items[item] = Inventory.count(player, item)
	end
	if recipe.Recipe then
		items[recipe.Recipe] = Inventory.count(player, recipe.Recipe)
	end
	local ok, why = TefraCraft.check(id, items, data.Money or 0)
	if not ok then
		local named = (why or ""):gsub("(%d+) (%a+)", function(n, item)
			return n .. " " .. (if Items.get(item) then Items.get(item).Name else item)
		end)
		return false, "⚒ " .. named
	end
	if recipe.Money > 0 and not Data.spend(player, recipe.Money) then
		return false, ("Te faltan %d €"):format(recipe.Money)
	end
	local spend, gain = TefraCraft.plan(id)
	for item, n in spend do
		Inventory.remove(player, item, n)
	end
	for item, n in gain do
		Inventory.add(player, item, n)
	end
	StoryEvents.emit(player, "ItemCrafted", { Item = id })
	return true, "⚒ Fabricado: " .. itemName(id)
end

local function forgeMenu(player: Player)
	local options = {}
	for _, r in TefraCraft.Recipes do
		local parts = {}
		local ids = {}
		for item in r.Needs do
			table.insert(ids, item)
		end
		table.sort(ids)
		for _, item in ids do
			local it = Items.get(item)
			table.insert(parts, ("%d %s"):format(r.Needs[item], if it then it.Name else item))
		end
		local text = ("%s · %s · %d €%s"):format(r.Name, table.concat(parts, ", "), r.Money, if r.Recipe then " (con receta)" else "")
		table.insert(options, { T = text, Effects = { Craft = r.Id } })
	end
	table.insert(options, { T = ("Refinar obsidiana de la nave (%d €)"):format(TefraCraft.RefineCost), Effects = { Craft = "Refinar" } })
	table.insert(options, { T = "Nada, gracias", Effects = { Craft = "Nada" } })
	local picked: string? = nil
	local dialogue = {
		Staging = false,
		Lines = {
			{ S = "Capataz", T = "Forja de Bastión. Aquí se funde, se refina y se cose lo que aguanta el calor. ¿Qué te hago?" },
			{ Ask = "¿Qué fabricas?", Options = options },
		},
	}
	local ok = pcall(function()
		service("DialogueService").play(player, dialogue, {
			apply = function(effects)
				if type(effects) == "table" and type(effects.Craft) == "string" then
					picked = effects.Craft
				end
			end,
		}, function()
			if picked and picked ~= "Nada" then
				local done, text = TefraService.craft(player, picked)
				toast(player, if done then "Success" else "Error", text)
			end
		end)
	end)
	if not ok then
		toast(player, "Error", "La Forja está ocupada. Prueba otra vez.")
	end
end

local function greenhouse(player: Player)
	local t = now()
	local last = liquenAt[player]
	if last and t - last < TefraService.LiquenCooldown then
		toast(player, "Info", ("🍄 Las setas y el liquen aún no han vuelto a salir. Vuelve en %d s."):format(math.ceil(TefraService.LiquenCooldown - (t - last))))
		return
	end
	liquenAt[player] = t
	local Inventory = service("InventoryService")
	Inventory.add(player, "LiquenTermico", 1)
	Inventory.add(player, "SetaCeniza", 1)
	toast(player, "Success", "🍂 Recoges liquen térmico y 🍄 una seta de ceniza (para el gel térmico de la Forja)")
end

local function sirenBread(player: Player)
	local r = TefraService.recentRaid()
	if not r or now() > r.EndAt + TefraService.PanSirenaSeconds then
		toast(player, "Info", "🥖 Ernesto: «El pan de sirena se reparte después de las bombas. Ojalá no tengas que volver a por él».")
		return
	end
	if panRaid[player] == r.Key then
		toast(player, "Info", "🥖 Ernesto: «Uno por persona. Que hay que llegar para todos».")
		return
	end
	panRaid[player] = r.Key
	service("InventoryService").add(player, "PanSirena", 1)
	toast(player, "Success", "🥖 Ernesto te da un pan de sirena, todavía caliente")
end

-- Un aviso del tipo "Tefra" (PlanetService lo manda aquí)
function TefraService.prompt(player: Player, id: string, pp: Instance?)
	if pp and pp:IsA("ProximityPrompt") then
		local root = rootOf(player)
		local parent = pp.Parent
		if root and parent and parent:IsA("BasePart") and (root.Position - parent.Position).Magnitude > 20 then
			return -- (lejos de verdad: no vale)
		end
	end
	if id == "Forja" then
		forgeMenu(player)
	elseif id == "Invernadero" then
		greenhouse(player)
	elseif id == "PanSirena" then
		sirenBread(player)
	end
end

---------------------------------------------------------------------
-- Bucle
---------------------------------------------------------------------
function TefraService._tick(dt: number)
	for _, p in Players:GetPlayers() do
		local ok, err = pcall(stepHeat, p, dt)
		if not ok then
			warn("[TefraService] calor: " .. tostring(err))
		end
	end
	for p in table.clone(heat) do
		if not p.Parent then
			heat[p] = nil
		end
	end
	local ok, err = pcall(function()
		scheduleRaid()
		stepRaid()
	end)
	if not ok then
		warn("[TefraService] bombardeo: " .. tostring(err))
	end
end

-- (pruebas)
TefraService._heat = heat
function TefraService._reset()
	table.clear(heat)
	table.clear(doneRaids)
	table.clear(panRaid)
	table.clear(liquenAt)
	raid = nil
	lastRaid = nil
	clearMarkers()
end

function TefraService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	-- El gel térmico se usa desde la mochila
	pcall(function()
		service("InventoryService").onUse("GelTermico", TefraService.useGel)
	end)
	Players.PlayerRemoving:Connect(function(player)
		heat[player] = nil
		liquenAt[player] = nil
		panRaid[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(TefraService.Tick)
			TefraService._tick(TefraService.Tick)
		end
	end)
end

return TefraService
