-- BattlePassService: el pase de temporada (núcleo). TODO lo decide el servidor.
--   * Nivel y XP: la XP total se guarda (data.BattlePass.TotalXp) y el nivel se calcula de ella, así
--     que subir varios niveles de golpe es natural y no hay nivel/XP que se contradigan.
--   * Recompensas: pista gratis (todos) y premium (con el Game Pass de la temporada). Se reclaman una
--     vez: se apuntan en ClaimedFree / ClaimedPremium (conjuntos por nivel, ["5"] = true) ANTES de
--     entregar (dos peticiones seguidas no dan dos veces) y, si el sistema falla, se deshace.
--   * Premium: Game Pass oficial de Roblox. Se mira al entrar (UserOwnsGamePassAsync con reintentos y
--     caché) y al terminar la compra (PromptGamePassPurchaseFinished). Idempotente: comprarlo en el
--     nivel 30 entrega solo las premium del 1 al 30 (BattlePassConfig.AutoClaimRetroactiveOnPurchase).
--     GamePassId = 0 -> compra desactivada («Próximamente»).
--   * Remoto "BattlePass" (se crea al arrancar) con límite de peticiones. El cliente solo PIDE
--     (reclamar, comprar, equipar…); lo que mande de nivel, XP o premium se ignora.
--   * Modo pruebas (TesterService -> testerAction): simular premium (SOLO en memoria, nunca se guarda
--     como comprado), sumar XP, poner nivel y adelantar el reloj.
--   * Contrato para la interfaz: docs/pase-de-temporada.md («Contrato de la interfaz»).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BPConfig = require(ReplicatedStorage.Shared.BattlePass.Config)
local Catalog = require(ReplicatedStorage.Shared.BattlePass.Catalog)
local DataService = require(script.Parent.DataService)
local TesterService = require(script.Parent.TesterService)
local Season = require(script.Parent.BattlePassSeasonService)
local Rewards = require(script.Parent.BattlePassRewardService)
local Missions = require(script.Parent.SeasonMissionService)
local Telemetry = require(script.Parent.Parent.BattlePass.Telemetry)

local BattlePassService = {}

local remote: RemoteEvent? = nil
local notifyRemote: RemoteEvent? = nil
local simulated: { [Player]: boolean } = {} -- premium simulado (modo pruebas): SOLO en memoria
local rate: { [Player]: { Times: { number }, Last: number } } = {}
local pushQueued: { [Player]: boolean } = {}
local ownership: { [string]: { Owns: boolean, At: number } } = {} -- caché de UserOwnsGamePassAsync
local priceCache: { [number]: { Robux: number?, At: number } } = {}
local OWNERSHIP_CACHE = 300 -- segundos que vale un "no lo tiene" (un "sí" vale para siempre)

-- Textos de cada respuesta (para los avisos; la interfaz puede usar el código)
local MESSAGES = {
	Locked = "Todavía no has llegado a ese nivel.",
	PremiumLocked = "Esa recompensa es del Pase Premium.",
	AlreadyClaimed = "Ya la has reclamado.",
	SeasonClosed = "La temporada ha terminado: ya no se puede reclamar.",
	NotStarted = "La temporada todavía no ha empezado.",
	RetryLater = "No se ha podido entregar ahora. Inténtalo en un momento.",
	ComingSoon = "El Pase Premium estará disponible próximamente.",
	AlreadyPremium = "Ya tienes el Pase Premium de esta temporada.",
	BadRequest = "Petición no válida.",
	NotOwned = "Todavía no tienes eso.",
	DecorFull = ("Ya tienes %d objetos de decoración puestos: quita uno antes."):format(Rewards.MaxDecor),
	NotEnoughTokens = "No tienes fichas suficientes.",
	NoPerk = "Necesitas la comodidad «Cambio de misión diaria» del Pase Premium.",
	AlreadyRerolled = "Hoy ya has cambiado una misión.",
	NoData = "Tus datos todavía se están cargando.",
	Compensated = "Esa recompensa ya no existe: te damos una compensación.",
}
BattlePassService.Messages = MESSAGES

local function notify(player: Player, kind: string, text: string)
	if notifyRemote then
		notifyRemote:FireClient(player, kind, text)
	end
end

local function send(player: Player, kind: string, payload: any)
	if remote then
		remote:FireClient(player, kind, payload)
	end
end

---------------------------------------------------------------------
-- Estado del jugador
---------------------------------------------------------------------

local function premiumOf(player: Player, bp: { [string]: any }): boolean
	return bp.PremiumOwned == true or simulated[player] == true
end
function BattlePassService.isPremium(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil and type(data.BattlePass) == "table" and premiumOf(player, data.BattlePass)
end

local function refreshLevel(bp: { [string]: any }, season: Season.Season): (number, number, number)
	local level, into, need = Season.levelOf(season, bp.TotalXp)
	bp.Level = level
	return level, into, need
end

local function syncAttributes(player: Player, bp: { [string]: any })
	player:SetAttribute("BP_Season", bp.SeasonId)
	player:SetAttribute("BP_Level", bp.Level)
	player:SetAttribute("BP_Premium", premiumOf(player, bp))
	player:SetAttribute("BP_PremiumSimulated", if simulated[player] then true else nil)
end

-- Entrega lo alcanzado y sin reclamar de la temporada que se archiva (para que nada se pierda)
local function grantUnclaimed(player: Player, bp: { [string]: any }, old: Season.Season?)
	if not old or not BPConfig.AutoGrantUnclaimedOnArchive then
		return
	end
	local level = Season.levelOf(old, bp.TotalXp)
	for l = 1, level do
		for _, track in { "Free", "Premium" } do
			local set = if track == "Free" then bp.ClaimedFree else bp.ClaimedPremium
			if not set[tostring(l)] and (track == "Free" or bp.PremiumOwned) then
				set[tostring(l)] = true
				local ok, why = Rewards.grant(player, Season.reward(old, l, track), old.Id)
				if not ok and why ~= "Unknown" then
					set[tostring(l)] = nil
				end
			end
		end
	end
end

-- Deja listos los datos del pase (forma, cambio de temporada, nivel y misiones). Devuelve bp y temporada.
function BattlePassService.ensure(player: Player, data: { [string]: any }?): ({ [string]: any }?, Season.Season?)
	local d = data or DataService.get(player)
	if not d then
		return nil, nil
	end
	local bp = Season.ensure(d)
	local now = Season.now(player)
	local current = Season.current(now)
	local known = Season.byId(bp.SeasonId)
	if bp.SeasonId ~= "" and (Season.needsRollover(bp, now) or not known) then
		grantUnclaimed(player, bp, known)
		local oldName = if known then known.Name else bp.SeasonId
		bp = Season.archive(d, current.Id, now)
		Telemetry.count("SeasonArchived", nil, player)
		notify(player, "Info", ("🗂 La temporada «%s» ha terminado. Tu progreso queda en tu historial y todo lo que conseguiste sigue siendo tuyo. ¡Empieza «%s»!"):format(oldName, current.Name))
	elseif bp.SeasonId == "" then
		bp.SeasonId = current.Id
	end
	local season = Season.byId(bp.SeasonId) or current
	refreshLevel(bp, season)
	Missions.ensure(player, bp, season, now)
	return bp, season
end

---------------------------------------------------------------------
-- Estado para la interfaz
---------------------------------------------------------------------

local function stateOf(player: Player, bp: { [string]: any }, season: Season.Season, reward: { [string]: any }, now: number): string
	local set = if reward.Track == "Free" then bp.ClaimedFree else bp.ClaimedPremium
	if set[tostring(reward.Level)] then
		return "CLAIMED"
	elseif reward.Track == "Premium" and not premiumOf(player, bp) then
		return "PREMIUM_LOCKED"
	elseif bp.Level >= reward.Level and Season.claiming(season, now) then
		return "AVAILABLE"
	end
	return "LOCKED"
end

-- Vista previa para la interfaz (ViewportFrame): de qué es y con qué colores
local function previewOf(def: { [string]: any }): { [string]: any }?
	local base = def.Preview
	if def.Type == "Bundle" and not base then
		return nil
	end
	local p = if type(base) == "table" then table.clone(base) else { Kind = def.Type }
	p.Color = p.Color or def.Color
	p.Colors = p.Colors or def.Colors
	p.Material = p.Material or def.Material
	if def.Type == "VehicleSkin" or def.Type == "Decor" or (p.Kind == "Vehicle" and def.Type == "Bundle") then
		p.Model = "BattlePassPreviews/" .. def.Id -- (modelo ya montado en ReplicatedStorage, si existe)
	end
	if def.Type == "Emote" then
		p.AnimationId = def.AnimationId
		p.Speed = def.Speed
		p.Loop = def.Loop
	end
	return p
end

local function rewardView(player: Player, bp: { [string]: any }, season: Season.Season, def: { [string]: any }, now: number, cosmetics: { [string]: any }): { [string]: any }
	local rarity = BPConfig.Rarities[def.Rarity] or BPConfig.Rarities.Comun
	local view = {
		Id = def.Id,
		Level = def.Level,
		Track = def.Track,
		Type = def.Type,
		TypeName = BPConfig.TypeNames[def.Type] or def.Type,
		Name = def.Name,
		Description = def.Description,
		Icon = def.Icon,
		Rarity = def.Rarity,
		RarityName = rarity.Name,
		RarityColor = rarity.Color,
		Amount = def.Amount,
		Kind = def.Kind,
		State = stateOf(player, bp, season, def, now),
		Milestone = def.Level % 5 == 0,
		Preview = previewOf(def),
		Owned = cosmetics.Owned[def.Id] ~= nil,
	}
	if def.Type == "Boat" then
		view.Usable = Rewards.BoatAdapter.available()
		view.UsableText = if view.Usable then nil else "Llega con el puerto deportivo"
	end
	if def.Type == "Bundle" then
		local items = {}
		for _, item in def.Items or {} do
			table.insert(items, { Id = item.Id, Type = item.Type, TypeName = BPConfig.TypeNames[item.Type] or item.Type, Name = item.Name, Icon = item.Icon, Preview = previewOf(Catalog.get(item.Id) or item) })
		end
		view.Items = items
	end
	return view
end

local function priceOf(passId: number): number?
	if passId == 0 then
		return nil
	end
	local cached = priceCache[passId]
	if cached and os.clock() - cached.At < 600 then
		return cached.Robux
	end
	priceCache[passId] = { Robux = if cached then cached.Robux else nil, At = os.clock() }
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
		end)
		if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
			priceCache[passId] = { Robux = info.PriceInRobux, At = os.clock() }
		end
	end)
	return priceCache[passId].Robux
end

-- Todo el estado del pase para la interfaz (ver el contrato en docs/pase-de-temporada.md)
function BattlePassService.snapshot(player: Player): { [string]: any }?
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not data or not bp or not season then
		return nil
	end
	local now = Season.now(player)
	local level, into, need = refreshLevel(bp, season)
	local status = Season.status(season, now)
	local cosmetics = data.Cosmetics
	local list = {}
	for _, def in season.Rewards do
		table.insert(list, rewardView(player, bp, season, def, now, cosmetics))
	end
	table.sort(list, function(a, b)
		if a.Level ~= b.Level then
			return a.Level < b.Level
		end
		return a.Track == "Free" and b.Track ~= "Free"
	end)
	local available = 0
	for _, view in list do
		if view.State == "AVAILABLE" then
			available += 1
		end
	end
	local events = {}
	for _, event in Season.activeEvents(season, now) do
		table.insert(events, { Id = event.Id, Name = event.Name, Icon = event.Icon, EndsAt = event.EndsAt, XpMultiplier = math.min(event.XpMultiplier or 1, BPConfig.MaxEventMultiplier) })
	end
	local history = {}
	for id, entry in data.SeasonArchive do
		if type(entry) == "table" then
			table.insert(history, { SeasonId = id, Name = entry.Name, Level = entry.Level, PremiumOwned = entry.PremiumOwned, ArchivedAt = entry.ArchivedAt })
		end
	end
	table.sort(history, function(a, b)
		return (a.ArchivedAt or 0) < (b.ArchivedAt or 0)
	end)
	local owned = {}
	for id, info in cosmetics.Owned do
		local def = Catalog.get(id)
		if def and type(info) == "table" then
			table.insert(owned, { Id = id, Type = def.Type, Name = def.Name, Icon = def.Icon, Rarity = def.Rarity, Season = info.Season, Kind = def.Kind })
		end
	end
	table.sort(owned, function(a, b)
		return a.Id < b.Id
	end)
	local shop = {}
	for _, item in season.TokenShop or {} do
		table.insert(shop, { Id = item.Id, Type = item.Type, TypeName = BPConfig.TypeNames[item.Type] or item.Type, Name = item.Name, Icon = item.Icon, Rarity = item.Rarity, Cost = item.Cost, Description = item.Description, Owned = cosmetics.Owned[item.Id] ~= nil, Preview = previewOf(item) })
	end
	local daily = bp.Daily
	local passId = tonumber(season.GamePassId) or 0
	return {
		Season = {
			Id = season.Id,
			Number = season.Number,
			Name = season.Name,
			Subtitle = season.Subtitle,
			Theme = season.Theme,
			StartsAt = season.StartsAt,
			EndsAt = season.EndsAt,
			ClaimUntil = season.EndsAt + BPConfig.ClaimGraceDays * 86400,
			Now = now,
			Status = status,
			MaxLevel = season.MaxLevel,
			Colors = season.Colors,
		},
		Premium = {
			Owned = premiumOf(player, bp),
			Purchased = bp.PremiumOwned == true,
			Simulated = simulated[player] == true,
			PurchaseEnabled = passId ~= 0 and status == "Active" and not bp.PremiumOwned,
			ComingSoon = passId == 0,
			GamePassId = passId,
			PriceRobux = priceOf(passId), -- (lo pone Roblox; nil mientras no se sepa)
			RewardCount = #season.Rewards,
		},
		Progress = {
			Level = level,
			Xp = into,
			XpForNext = need,
			TotalXp = bp.TotalXp,
			IsMax = level >= season.MaxLevel,
			Available = available,
			Tokens = cosmetics.Tokens,
			DailyXp = if daily.Day == Missions.dayKey(now) then daily.Xp or 0 else 0,
			DailyCap = BPConfig.DailyActivityCap,
			EventMultiplier = Season.eventMultiplier(season, now),
		},
		Rewards = list,
		Missions = Missions.snapshot(player, bp, season, now),
		Events = events,
		Equipped = {
			Title = cosmetics.Equipped.Title,
			Nameplate = cosmetics.Equipped.Nameplate,
			PhoneTheme = cosmetics.Equipped.PhoneTheme,
			HudSkin = cosmetics.Equipped.HudSkin,
			HomeTheme = cosmetics.Equipped.HomeTheme,
			Outfit = cosmetics.Equipped.Outfit,
			VehicleSkin = table.clone(cosmetics.Equipped.VehicleSkin),
			Decor = table.clone(cosmetics.Equipped.Decor),
		},
		Collection = owned,
		TokenShop = shop,
		History = history,
		Tester = if TesterService.isTester(player) then BattlePassService.testerState(player) else nil,
	}
end

-- Manda el estado completo (juntando los cambios seguidos en uno)
function BattlePassService.push(player: Player, now: boolean?)
	if now then
		pushQueued[player] = nil
		local snap = BattlePassService.snapshot(player)
		if snap then
			send(player, "State", snap)
		end
		return
	end
	if pushQueued[player] then
		return
	end
	pushQueued[player] = true
	task.delay(BPConfig.PushEvery, function()
		if pushQueued[player] and player.Parent then
			BattlePassService.push(player, true)
		end
		pushQueued[player] = nil
	end)
end

---------------------------------------------------------------------
-- XP y niveles
---------------------------------------------------------------------

-- Suma XP del pase (lo llaman BattlePassXPService y SeasonMissionService; nunca el cliente).
-- force: el modo pruebas suma aunque la temporada no esté en marcha. Devuelve la XP sumada.
function BattlePassService.addXp(player: Player, amount: number, source: string?, force: boolean?): number
	local data = DataService.get(player)
	if not data or type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount == math.huge then
		return 0
	end
	local bp, season = BattlePassService.ensure(player, data)
	if not bp or not season then
		return 0
	end
	local now = Season.now(player)
	if not force and not Season.earning(season, now) then
		return 0
	end
	local give = math.floor(math.min(amount, 1e6))
	if give <= 0 then
		return 0
	end
	local before = bp.Level
	bp.TotalXp += give
	local level = refreshLevel(bp, season)
	-- Pasado el máximo: la XP de más da fichas (con tope por temporada)
	if level >= season.MaxLevel then
		local extra = bp.TotalXp - Season.totalFor(season, season.MaxLevel)
		local tokens = math.min(BPConfig.Tokens.MaxFromOverflow, math.floor(extra / BPConfig.Tokens.OverflowXpPerToken))
		if tokens > bp.OverflowTokens then
			local delta = tokens - bp.OverflowTokens
			bp.OverflowTokens = tokens
			data.Cosmetics.Tokens += delta
			notify(player, "Success", ("🪙 +%d ficha%s de temporada"):format(delta, if delta == 1 then "" else "s"))
			Rewards.sync(player)
		end
	end
	if level > before then
		local unlocked = {}
		for l = before + 1, level do
			for _, track in { "Free", "Premium" } do
				local def = Season.reward(season, l, track)
				if def then
					table.insert(unlocked, { Level = l, Track = track, Id = def.Id, Name = def.Name, Icon = def.Icon, Rarity = def.Rarity, Premium = track == "Premium", State = stateOf(player, bp, season, def, now) })
				end
			end
		end
		send(player, "Unlocked", { From = before, Level = level, Rewards = unlocked })
		notify(player, "Success", ("🎟 Pase de temporada: ¡nivel %d! Tienes recompensas para reclamar."):format(level))
		Telemetry.count("LevelUp", nil, player, level - before)
	end
	syncAttributes(player, bp)
	BattlePassService.push(player)
	return give
end

---------------------------------------------------------------------
-- Reclamar
---------------------------------------------------------------------

local function isLevel(x: any, max: number): boolean
	return type(x) == "number" and x == x and x == math.floor(x) and x >= 1 and x <= max
end

-- Reclama la recompensa de un nivel y pista. Devuelve (ok, código, definición).
function BattlePassService.claim(player: Player, track: any, level: any): (boolean, string?, { [string]: any }?)
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not bp or not season then
		return false, "NoData"
	end
	if (track ~= "Free" and track ~= "Premium") or not isLevel(level, season.MaxLevel) then
		return false, "BadRequest"
	end
	local now = Season.now(player)
	if not Season.claiming(season, now) then
		return false, if Season.status(season, now) == "Upcoming" then "NotStarted" else "SeasonClosed"
	end
	if bp.Level < level then
		return false, "Locked"
	end
	if track == "Premium" and not premiumOf(player, bp) then
		return false, "PremiumLocked"
	end
	local set = if track == "Free" then bp.ClaimedFree else bp.ClaimedPremium
	local key = tostring(level)
	if set[key] then
		return false, "AlreadyClaimed"
	end
	-- Se apunta ANTES de entregar: si llega otra petición mientras tanto, ya está reclamada
	-- (en premium simulado se apunta "T" para distinguirlo de una compra de verdad)
	set[key] = if track == "Premium" and not bp.PremiumOwned then "T" else true
	local def = Season.reward(season, level, track)
	local ok, why, compensated = Rewards.grant(player, def, season.Id)
	if not ok then
		set[key] = nil -- no se pudo: se podrá volver a reclamar
		return false, if why == "NoData" then "NoData" else "RetryLater"
	end
	Telemetry.count("RewardClaimed", if def then def.Id else "?", player)
	BattlePassService.push(player)
	return true, if compensated then "Compensated" else nil, def
end

-- Reclama todo lo disponible (pista gratis y, si tiene premium, la premium). Devuelve lo entregado.
function BattlePassService.claimAll(player: Player, onlyTrack: string?): { { [string]: any } }
	local given = {}
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not bp or not season then
		return given
	end
	for level = 1, bp.Level do
		for _, track in { "Free", "Premium" } do
			if (not onlyTrack or onlyTrack == track) and (track == "Free" or premiumOf(player, bp)) then
				local set = if track == "Free" then bp.ClaimedFree else bp.ClaimedPremium
				if not set[tostring(level)] then
					local ok, _, def = BattlePassService.claim(player, track, level)
					if ok then
						table.insert(given, { Level = level, Track = track, Id = if def then def.Id else nil, Name = if def then def.Name else nil, Icon = if def then def.Icon else nil })
					end
				end
			end
		end
	end
	return given
end

---------------------------------------------------------------------
-- Premium (Game Pass)
---------------------------------------------------------------------

-- Activa el premium de la temporada actual (idempotente). Solo lo llama la compra de verdad.
function BattlePassService.grantPremium(player: Player, source: string?): boolean
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not bp or not season or bp.PremiumOwned then
		return false
	end
	bp.PremiumOwned = true
	bp.PremiumAt = os.time()
	bp.PremiumSource = source or "GamePass"
	Telemetry.count("Purchase", season.Id, player)
	local given = {}
	if BPConfig.AutoClaimRetroactiveOnPurchase then
		given = BattlePassService.claimAll(player, "Premium")
	end
	syncAttributes(player, bp)
	notify(player, "Success", ("🎟 ¡Ya tienes el Pase Premium de «%s»! %s"):format(season.Name,
		if #given > 0 then ("Te hemos entregado las %d recompensas premium de los niveles que ya tenías."):format(#given) else "Sube de nivel para conseguir sus recompensas."))
	send(player, "Premium", { Owned = true, Given = given })
	-- Guardado inmediato (como las compras con Robux de MonetizationService)
	task.spawn(function()
		pcall(DataService.save, player)
	end)
	BattlePassService.push(player)
	return true
end

-- ¿Tiene el Game Pass de la temporada actual? (con reintentos y caché). Si lo tiene, activa el premium.
function BattlePassService.checkOwnership(player: Player): boolean?
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not bp or not season then
		return nil
	end
	local passId = tonumber(season.GamePassId) or 0
	if passId == 0 then
		return false
	end
	if bp.PremiumOwned then
		return true
	end
	local key = player.UserId .. ":" .. passId
	local cached = ownership[key]
	if cached and (cached.Owns or os.clock() - cached.At < OWNERSHIP_CACHE) then
		if cached.Owns then
			BattlePassService.grantPremium(player, "GamePass")
		end
		return cached.Owns
	end
	for attempt = 1, BPConfig.OwnershipRetries do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok then
			ownership[key] = { Owns = owns == true, At = os.clock() }
			if owns == true then
				BattlePassService.grantPremium(player, "GamePass")
			end
			return owns == true
		end
		if not player.Parent then
			return nil
		end
		task.wait(attempt)
	end
	warn(("[BattlePass] No se pudo comprobar el Game Pass de %s (se volverá a mirar al volver a entrar)"):format(player.Name))
	return nil
end

-- Final de la compra (lo avisa Roblox en el servidor: no lo puede inventar el cliente)
function BattlePassService.onPurchaseFinished(player: Player, passId: number, purchased: boolean)
	if not purchased then
		return
	end
	local season = Season.current(Season.now(player))
	local id = tonumber(season.GamePassId) or 0
	if id == 0 or passId ~= id then
		return
	end
	ownership[player.UserId .. ":" .. id] = { Owns = true, At = os.clock() }
	if DataService.waitFor(player, 20) then
		BattlePassService.grantPremium(player, "GamePass")
	end
end

local function promptPurchase(player: Player): (boolean, string?)
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not bp or not season then
		return false, "NoData"
	end
	local passId = tonumber(season.GamePassId) or 0
	if passId == 0 then
		return false, "ComingSoon"
	end
	if bp.PremiumOwned then
		return false, "AlreadyPremium"
	end
	if Season.status(season, Season.now(player)) ~= "Active" then
		return false, "SeasonClosed"
	end
	Telemetry.count("PurchasePrompt", season.Id, player)
	local ok = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, passId)
	end)
	return ok, if ok then nil else "RetryLater"
end

---------------------------------------------------------------------
-- Tienda de fichas (solo cosméticos)
---------------------------------------------------------------------

function BattlePassService.buyToken(player: Player, itemId: any): (boolean, string?)
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not data or not bp or not season or type(itemId) ~= "string" then
		return false, "BadRequest"
	end
	local item = nil
	for _, entry in season.TokenShop or {} do
		if entry.Id == itemId then
			item = entry
		end
	end
	if not item then
		return false, "BadRequest"
	end
	if data.Cosmetics.Owned[itemId] then
		return false, "AlreadyClaimed"
	end
	local cost = math.max(0, math.floor(tonumber(item.Cost) or 0))
	if data.Cosmetics.Tokens < cost then
		return false, "NotEnoughTokens"
	end
	data.Cosmetics.Tokens -= cost
	local ok = Rewards.grant(player, Catalog.get(itemId) or item, season.Id)
	if not ok then
		data.Cosmetics.Tokens += cost
		return false, "RetryLater"
	end
	bp.Shop[itemId] = true
	Telemetry.count("TokenShop", itemId, player)
	BattlePassService.push(player)
	return true
end

---------------------------------------------------------------------
-- Modo pruebas (solo testers; lo llama TesterService)
---------------------------------------------------------------------

function BattlePassService.testerState(player: Player): { [string]: any }
	local data = DataService.get(player)
	local bp = data and type(data.BattlePass) == "table" and data.BattlePass
	return {
		SimulatedPremium = simulated[player] == true,
		RealPremium = bp and bp.PremiumOwned == true or false,
		Level = bp and bp.Level or 1,
		ClockShift = Season.now(player) - Season.now(),
	}
end

-- op = { Op = "Premium" | "AddXp" | "SetLevel" | "NextDay" | "NextWeek" | "ResetClock" | "Reset", Value = número }
function BattlePassService.testerAction(player: Player, op: any): (boolean, string?)
	if not TesterService.isTester(player) then
		return false, "BadRequest"
	end
	local spec = if type(op) == "table" then op else { Op = op }
	local kind, value = spec.Op, spec.Value
	local data = DataService.get(player)
	local bp, season = BattlePassService.ensure(player, data)
	if not data or not bp or not season or type(kind) ~= "string" then
		return false, "BadRequest"
	end
	local text
	if kind == "Premium" then
		simulated[player] = not simulated[player] or nil
		text = if simulated[player] then "🎟 Premium SIMULADO (solo en esta sesión: no cuenta como compra)" else "🎟 Premium simulado apagado"
	elseif kind == "AddXp" then
		local n = if type(value) == "number" and value == value then math.clamp(math.floor(value), 1, 100000) else 1000
		BattlePassService.addXp(player, n, "Tester", true)
		text = ("🎟 +%d XP de pase"):format(n)
	elseif kind == "SetLevel" then
		if not isLevel(value, season.MaxLevel) then
			return false, "BadRequest"
		end
		bp.TotalXp = Season.totalFor(season, value)
		refreshLevel(bp, season)
		text = ("🎟 Nivel de pase %d"):format(value)
	elseif kind == "NextDay" or kind == "NextWeek" then
		Season.shift(player, if kind == "NextDay" then 86400 else 7 * 86400)
		BattlePassService.ensure(player, data)
		text = "🕒 Reloj del pase adelantado (solo para ti y solo en esta sesión)"
	elseif kind == "ResetClock" then
		Season.clearShift(player)
		text = "🕒 Reloj del pase normal"
	elseif kind == "Reset" then
		local keepPremium, keepAt = bp.PremiumOwned, bp.PremiumAt
		data.BattlePass = Season.fresh(season.Id)
		data.BattlePass.PremiumOwned, data.BattlePass.PremiumAt = keepPremium, keepAt
		BattlePassService.ensure(player, data)
		text = "🎟 Pase reiniciado (se conserva la compra de verdad, si la hay)"
	else
		return false, "BadRequest"
	end
	local now = DataService.get(player)
	if now and now.BattlePass then
		syncAttributes(player, now.BattlePass)
	end
	notify(player, "Info", text)
	BattlePassService.push(player)
	return true
end

---------------------------------------------------------------------
-- Remoto
---------------------------------------------------------------------

-- ¿Se atiende esta petición? (ráfaga máxima y hueco mínimo entre dos)
function BattlePassService.allow(player: Player): boolean
	local now = os.clock()
	local r = rate[player]
	if not r then
		r = { Times = {}, Last = -math.huge }
		rate[player] = r
	end
	local limit = BPConfig.RateLimit
	if now - r.Last < limit.MinGap then
		return false
	end
	while #r.Times > 0 and now - r.Times[1] > limit.Window do
		table.remove(r.Times, 1)
	end
	if #r.Times >= limit.Burst then
		return false
	end
	table.insert(r.Times, now)
	r.Last = now
	return true
end

local function result(player: Player, action: string, ok: boolean, code: string?, extra: { [string]: any }?)
	local payload = extra or {}
	payload.Action = action
	payload.Ok = ok
	payload.Code = code
	payload.Message = if code then MESSAGES[code] else nil
	send(player, "Result", payload)
	if not ok and code and MESSAGES[code] and code ~= "BadRequest" then
		notify(player, "Error", MESSAGES[code])
	end
end

-- Atiende una petición del cliente. Todo lo que manda se comprueba; lo que no se entiende se ignora.
function BattlePassService.handle(player: Player, action: any, a: any, b: any, c: any)
	if type(action) ~= "string" or not DataService.get(player) then
		return
	end
	if action == "Get" then
		Telemetry.count("Open", nil, player)
		BattlePassService.push(player, true)
	elseif action == "Claim" then
		local ok, code, def = BattlePassService.claim(player, a, b)
		result(player, action, ok, code, { Track = a, Level = b, Reward = if def then { Id = def.Id, Name = def.Name, Icon = def.Icon, Rarity = def.Rarity } else nil })
		if ok then
			notify(player, "Success", ("🎁 ¡Recompensa: %s!"):format(if def then def.Name else "compensación"))
		end
	elseif action == "ClaimAll" then
		local given = BattlePassService.claimAll(player)
		result(player, action, #given > 0, if #given > 0 then nil else "Locked", { Given = given })
		if #given > 0 then
			notify(player, "Success", ("🎁 %d recompensa%s reclamada%s"):format(#given, if #given == 1 then "" else "s", if #given == 1 then "" else "s"))
		end
	elseif action == "Buy" then
		local ok, code = promptPurchase(player)
		result(player, action, ok, code)
	elseif action == "Equip" then
		local ok, code = Rewards.equip(player, a, b, c)
		result(player, action, ok, code, { Slot = a, Id = b })
		BattlePassService.push(player)
	elseif action == "Track" then
		local ok, code = Missions.track(player, a)
		result(player, action, ok, code, { Mission = a })
	elseif action == "Reroll" then
		local ok, code = Missions.reroll(player, a)
		result(player, action, ok, code, { Mission = a })
		BattlePassService.push(player)
	elseif action == "StoryChoice" then
		local ok, code = Missions.choose(player, a, b)
		result(player, action, ok, code, { Story = a, Choice = b })
		BattlePassService.push(player)
	elseif action == "BuyToken" then
		local ok, code = BattlePassService.buyToken(player, a)
		result(player, action, ok, code, { Item = a })
	end
end

---------------------------------------------------------------------
-- Vistas previas 3D (modelos listos en ReplicatedStorage > BattlePassPreviews)
---------------------------------------------------------------------

local function buildPreviews()
	local folder = Instance.new("Folder")
	folder.Name = "BattlePassPreviews"
	local Rides = require(script.Parent.Parent.World.Kit.Rides)
	for _, def in Catalog.all() do
		if def.Type == "VehicleSkin" and typeof(def.Color) == "Color3" then
			pcall(function()
				local model = Rides.build(def.Kind, nil, CFrame.new(), def.Color)
				model.Name = def.Id
				model:SetAttribute("RewardId", def.Id)
				model.Parent = folder
			end)
		end
	end
	folder.Parent = ReplicatedStorage
end

function BattlePassService.init()
	Telemetry.configure(BPConfig.Telemetry)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notifyRemote = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local existing = remotes:FindFirstChild(BPConfig.RemoteName) :: RemoteEvent?
	if not existing then
		local created = Instance.new("RemoteEvent")
		created.Name = BPConfig.RemoteName
		created.Parent = remotes
		existing = created
	end
	remote = existing
	;(existing :: RemoteEvent).OnServerEvent:Connect(function(player, action, a, b, c)
		if not BattlePassService.allow(player) then
			return -- (demasiadas peticiones: se ignoran en silencio)
		end
		local ok, err = pcall(BattlePassService.handle, player, action, a, b, c)
		if not ok then
			warn("[BattlePassService] " .. tostring(err))
		end
	end)

	DataService.onLoaded(function(player, data)
		local ok, err = pcall(function()
			local bp = BattlePassService.ensure(player, data)
			if bp then
				syncAttributes(player, bp)
			end
		end)
		if not ok then
			warn("[BattlePassService] " .. tostring(err))
		end
		task.spawn(function()
			pcall(BattlePassService.checkOwnership, player)
		end)
	end)

	pcall(function()
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
			BattlePassService.onPurchaseFinished(player, passId, purchased)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		simulated[player] = nil
		rate[player] = nil
		pushQueued[player] = nil
		Season.clearShift(player)
	end)

	task.spawn(function()
		local ok, err = pcall(buildPreviews)
		if not ok then
			warn("[BattlePassService] Vistas previas: " .. tostring(err))
		end
	end)
end

return BattlePassService
