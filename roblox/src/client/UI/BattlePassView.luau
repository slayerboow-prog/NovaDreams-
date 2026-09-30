-- BattlePassView: cuentas y textos de la interfaz del pase de temporada, sin tocar Roblox (solo lee
-- el estado que manda el servidor: ver «Forma de State» en docs/pase-de-temporada.md). Lo usan
-- UI/BattlePassUI y UI/BattlePassRewardCard, y lo prueba scripts/test-battlepassui.luau.
--
-- Aquí NO se decide nada: el estado de cada recompensa (BLOQUEADA, DISPONIBLE…) viene del servidor.

local BattlePassView = {}

local rgb = Color3.fromRGB

BattlePassView.Colors = {
	Claim = rgb(24, 104, 255), -- botón RECLAMAR (azul intenso, como lo elegido del HUD)
	ClaimGlow = rgb(110, 225, 255),
	Claimed = rgb(96, 214, 140),
	Locked = rgb(150, 170, 205),
	Premium = rgb(255, 204, 72),
	PremiumDark = rgb(64, 48, 14),
}

-- Estado -> texto, color y si se puede pulsar para reclamar
local STATES = {
	AVAILABLE = { Text = "RECLAMAR", Short = "DISPONIBLE", Claim = true },
	CLAIMED = { Text = "✔ RECLAMADA", Short = "RECLAMADA" },
	LOCKED = { Text = "🔒 BLOQUEADA", Short = "BLOQUEADA" },
	PREMIUM_LOCKED = { Text = "🔒 PREMIUM", Short = "PREMIUM BLOQUEADA" },
}

function BattlePassView.stateInfo(state: string?): { Text: string, Short: string, Claim: boolean?, Color: Color3 }
	local info = STATES[state or ""] or STATES.LOCKED
	local C = BattlePassView.Colors
	local color = if state == "AVAILABLE" then C.ClaimGlow elseif state == "CLAIMED" then C.Claimed elseif state == "PREMIUM_LOCKED" then C.Premium else C.Locked
	return { Text = info.Text, Short = info.Short, Claim = info.Claim, Color = color }
end

-- «01», «02»… «50»
function BattlePassView.levelText(level: number): string
	return ("%02d"):format(math.floor(level))
end

-- 12345 -> «12.345» (como el resto del juego en español)
function BattlePassView.number(n: number): string
	local text = tostring(math.floor(n))
	local sign = ""
	if text:sub(1, 1) == "-" then
		sign, text = "-", text:sub(2)
	end
	local out = text:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if out:sub(1, 1) == "." then
		out = out:sub(2)
	end
	return sign .. out
end

function BattlePassView.trackName(track: string?): string
	return if track == "Premium" then "PREMIUM" else "GRATIS"
end

-- Texto del tiempo que queda: «Quedan 23 días», «Empieza en 3 días», «Acabada: reclama hasta…»
function BattlePassView.timeLeft(season: { [string]: any }?): string
	if type(season) ~= "table" then
		return ""
	end
	local now = tonumber(season.Now) or 0
	local function days(until_: any): number
		return math.max(0, math.ceil(((tonumber(until_) or now) - now) / 86400))
	end
	local status = season.Status
	if status == "Upcoming" then
		local d = days(season.StartsAt)
		return if d <= 1 then "⏳ Empieza mañana" else ("⏳ Empieza en %d días"):format(d)
	elseif status == "Grace" then
		local d = days(season.ClaimUntil)
		return if d <= 1 then "⌛ Último día para reclamar" else ("⌛ Reclama hasta dentro de %d días"):format(d)
	elseif status == "Ended" then
		return "Temporada terminada"
	end
	local left = (tonumber(season.EndsAt) or now) - now
	if left < 86400 then
		local hours = math.max(1, math.ceil(left / 3600))
		return ("⏳ Quedan %d h"):format(hours)
	end
	local d = days(season.EndsAt)
	return if d == 1 then "⏳ Queda 1 día" else ("⏳ Quedan %d días"):format(d)
end

-- «TEMPORADA 1 · LUCES DE VALMAR»
function BattlePassView.title(season: { [string]: any }?): string
	if type(season) ~= "table" then
		return "🏆 PASE DE TEMPORADA"
	end
	return ("🏆 TEMPORADA %s · %s"):format(tostring(season.Number or 1), string.upper(tostring(season.Name or "")))
end

-- Las recompensas de una pista, por nivel: { [nivel] = recompensa }
function BattlePassView.lane(state: { [string]: any }?, track: string): { [number]: { [string]: any } }
	local out = {}
	for _, reward in (state and state.Rewards) or {} do
		if reward.Track == track and type(reward.Level) == "number" then
			out[reward.Level] = reward
		end
	end
	return out
end

-- La recompensa de un nivel y pista
function BattlePassView.find(state: { [string]: any }?, track: string, level: number): { [string]: any }?
	for _, reward in (state and state.Rewards) or {} do
		if reward.Track == track and reward.Level == level then
			return reward
		end
	end
	return nil
end

-- Cuántas se pueden reclamar (en total o de una pista)
function BattlePassView.available(state: { [string]: any }?, track: string?): number
	local n = 0
	for _, reward in (state and state.Rewards) or {} do
		if reward.State == "AVAILABLE" and (track == nil or reward.Track == track) then
			n += 1
		end
	end
	return n
end

-- La recompensa que se enseña al abrir en una pista: la primera DISPONIBLE; si no hay, la del nivel
-- siguiente (lo próximo que vas a conseguir); en el máximo, la del último nivel.
function BattlePassView.defaultLevel(state: { [string]: any }?, track: string): number
	local lane = BattlePassView.lane(state, track)
	local max = (state and state.Season and state.Season.MaxLevel) or 50
	for level = 1, max do
		local reward = lane[level]
		if reward and reward.State == "AVAILABLE" then
			return level
		end
	end
	local level = (state and state.Progress and state.Progress.Level) or 1
	return math.clamp(level + 1, 1, max)
end

-- «Siguiente: Nivel 13 · Conjunto Playa Dorada · faltan 90 XP»
function BattlePassView.nextText(state: { [string]: any }?, track: string): string
	local progress = state and state.Progress
	if not progress then
		return ""
	end
	local max = (state.Season and state.Season.MaxLevel) or 50
	if progress.IsMax or (progress.Level or 1) >= max then
		return ("🏁 Nivel máximo. La XP de más te da fichas (🪙 %d)"):format(progress.Tokens or 0)
	end
	local nextLevel = (progress.Level or 1) + 1
	local reward = BattlePassView.find(state, track, nextLevel)
	local missing = math.max(0, (progress.XpForNext or 0) - (progress.Xp or 0))
	return ("Siguiente · Nivel %s · %s · faltan %s XP"):format(BattlePassView.levelText(nextLevel), if reward then tostring(reward.Name) else "—", BattlePassView.number(missing))
end

-- Línea de progreso de una misión: «3 / 5», «12,5 / 40 km», «✔ Hecha»
function BattlePassView.missionProgress(mission: { [string]: any }): string
	if mission.Done then
		return "✔ Hecha"
	end
	local unit = if mission.Unit then " " .. mission.Unit else ""
	local p = tonumber(mission.Progress) or 0
	local text = if p == math.floor(p) then tostring(p) else (("%.1f"):format(p):gsub("%.", ","))
	return ("%s / %s%s"):format(text, tostring(mission.Goal or 1), unit)
end

function BattlePassView.missionFraction(mission: { [string]: any }): number
	if mission.Done then
		return 1
	end
	local goal = math.max(1, tonumber(mission.Goal) or 1)
	return math.clamp((tonumber(mission.Progress) or 0) / goal, 0, 1)
end

-- «+150 XP» (y fichas si da)
function BattlePassView.missionReward(mission: { [string]: any }): string
	local text = ("+%s XP"):format(BattlePassView.number(tonumber(mission.Xp) or 0))
	if (tonumber(mission.Tokens) or 0) > 0 then
		text ..= (" · +%d 🪙"):format(mission.Tokens)
	end
	return text
end

-- La misión destacada: la que sigues; si no, la diaria sin hacer que va más avanzada; si no, una
-- semanal o de temporada sin hacer
function BattlePassView.spotlight(state: { [string]: any }?): { [string]: any }?
	local missions = state and state.Missions
	if type(missions) ~= "table" then
		return nil
	end
	local best, bestScore = nil, -1
	for _, group in { "Daily", "Event", "Weekly", "Season" } do
		for _, mission in (missions[group] and missions[group].List) or {} do
			if mission.Tracked and not mission.Done then
				return mission
			end
			if not mission.Done then
				local score = BattlePassView.missionFraction(mission) + (if group == "Daily" then 1 elseif group == "Event" then 0.8 else 0)
				if score > bestScore then
					best, bestScore = mission, score
				end
			end
		end
	end
	return best
end

-- Huecos que se pueden equipar según el tipo de recompensa (como Types.EquipSlot + Decor)
local EQUIP = {
	Title = "Title", Nameplate = "Nameplate", PhoneTheme = "PhoneTheme", HudSkin = "HudSkin",
	HomeTheme = "HomeTheme", Outfit = "Outfit", VehicleSkin = "VehicleSkin", Decor = "Decor",
}
function BattlePassView.equipSlot(reward: { [string]: any }?): string?
	return if reward then EQUIP[reward.Type or ""] else nil
end

-- ¿Está puesto ahora?
function BattlePassView.isEquipped(state: { [string]: any }?, reward: { [string]: any }): boolean
	local equipped = state and state.Equipped
	local slot = BattlePassView.equipSlot(reward)
	if not equipped or not slot then
		return false
	end
	if slot == "VehicleSkin" then
		return type(equipped.VehicleSkin) == "table" and reward.Kind ~= nil and equipped.VehicleSkin[reward.Kind] == reward.Id
	elseif slot == "Decor" then
		return type(equipped.Decor) == "table" and table.find(equipped.Decor, reward.Id) ~= nil
	end
	return equipped[slot] == reward.Id
end

-- Texto del botón de compra del premium (el servidor decide si se puede)
function BattlePassView.buyText(premium: { [string]: any }?): (string, boolean)
	if type(premium) ~= "table" then
		return "Próximamente", false
	end
	if premium.Owned then
		return "✔ Activo", false
	end
	if premium.ComingSoon then
		return "Próximamente", false
	end
	if not premium.PurchaseEnabled then
		return "No disponible", false
	end
	if type(premium.PriceRobux) == "number" then
		return ("Comprar · R$ %s"):format(BattlePassView.number(premium.PriceRobux)), true
	end
	return "Comprar", true
end

-- «PASE PREMIUM · Temporada 1 · 50 recompensas»
function BattlePassView.premiumLine(state: { [string]: any }?): string
	local season = state and state.Season
	local count = 0
	for _, reward in (state and state.Rewards) or {} do
		if reward.Track == "Premium" then
			count += 1
		end
	end
	if count == 0 then
		count = (state and state.Premium and state.Premium.RewardCount) or 50
	end
	return ("PASE PREMIUM · Temporada %s · %d recompensas"):format(tostring(season and season.Number or 1), count)
end

-- La recompensa estrella del premium (para «Vista previa»): la de más rareza y nivel más alto
function BattlePassView.premiumHighlight(state: { [string]: any }?): { [string]: any }?
	local order = { Comun = 1, Rara = 2, Epica = 3, Legendaria = 4 }
	local best = nil
	for _, reward in (state and state.Rewards) or {} do
		if reward.Track == "Premium" then
			if not best or (order[reward.Rarity] or 0) > (order[best.Rarity] or 0) or ((order[reward.Rarity] or 0) == (order[best.Rarity] or 0) and reward.Level > best.Level) then
				best = reward
			end
		end
	end
	return best
end

-- ¿Se enseña la fila del pase en COMANDOS? (encendido, con estado y temporada en marcha o en el
-- periodo para reclamar)
function BattlePassView.rowVisible(enabled: boolean, state: { [string]: any }?): boolean
	if not enabled or type(state) ~= "table" or type(state.Season) ~= "table" then
		return false
	end
	return state.Season.Status == "Active" or state.Season.Status == "Grace"
end

return BattlePassView
