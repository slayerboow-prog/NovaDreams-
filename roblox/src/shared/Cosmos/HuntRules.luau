-- HuntRules: las reglas de la CAZA estilo MMO (petición del dueño: farmear y subir de nivel como en los MMORPG
-- clásicos, con nombres y números propios). Cuentas puras: las usan Services/BeastService (servidor),
-- Controllers/BeastPlates (cliente: el color del nombre) y scripts/test-cerebro-bestias.luau.
--
--   * Campeones: de vez en cuando una bestia sale CAMPEONA (★, dorada, más grande): más vida, pega más y da
--     el triple de experiencia y de botín. Los jefes y las esquirlas, nunca.
--   * Dificultad por colores (el nombre de la bestia): gris (te sobra nivel: casi no da nada), verde (fácil),
--     amarillo (justa), naranja (difícil) y rojo (peligro).
--   * Críticos: tus golpes y balas a las bestias a veces hacen un 75 % más (más a menudo con Suerte).
--   * Experiencia por bestia: según su vida, su nivel frente al tuyo y si es campeona.
--   * Botín por rareza: lo que casi nunca cae brilla más (luz de su color al caer la bestia).

local HuntRules = {}

local rgb = Color3.fromRGB

HuntRules.ChampionChance = 0.07
HuntRules.Champion = { Hp = 3, Damage = 1.5, Reward = 3, Xp = 3, Luck = 0.5, Size = 1.25, Color = rgb(255, 205, 70) }

-- ¿Sale campeona? (rand: function() -> 0..1)
function HuntRules.rollChampion(sp: { [string]: any }, rand: () -> number, static: boolean?): boolean
	if sp.Boss or static then
		return false
	end
	return rand() < HuntRules.ChampionChance
end

HuntRules.Con = {
	Gris = { Name = "Gris", Color = rgb(150, 150, 150), Text = "demasiado fácil" },
	Verde = { Name = "Verde", Color = rgb(90, 220, 100), Text = "fácil" },
	Amarillo = { Name = "Amarillo", Color = rgb(255, 225, 70), Text = "justa" },
	Naranja = { Name = "Naranja", Color = rgb(255, 150, 50), Text = "difícil" },
	Rojo = { Name = "Rojo", Color = rgb(255, 60, 60), Text = "peligro" },
}

-- El color de una bestia para ti
function HuntRules.con(playerLevel: number?, beastLevel: number?): { [string]: any }
	local p, b = tonumber(playerLevel) or 1, tonumber(beastLevel)
	if not b then
		return HuntRules.Con.Amarillo
	end
	local d = b - p
	if d <= -15 then
		return HuntRules.Con.Gris
	elseif d <= -5 then
		return HuntRules.Con.Verde
	elseif d < 5 then
		return HuntRules.Con.Amarillo
	elseif d < 10 then
		return HuntRules.Con.Naranja
	end
	return HuntRules.Con.Rojo
end

-- Experiencia del personaje por una bestia (fair: ValmarRegions.rewardFactor, 1 si no aplica)
function HuntRules.killXp(maxHp: number, boss: boolean?, champion: boolean?, playerLevel: number?, beastLevel: number?, fair: number?): number
	local base = math.max(1, math.floor(maxHp / 8 + 0.5)) * (if boss then 3 else 1)
	local p, b = tonumber(playerLevel), tonumber(beastLevel)
	local diff = 1
	if p and b and b > p then
		diff = 1 + math.min(0.5, (b - p) * 0.05) -- (más si es de más nivel que tú: hasta +50 %)
	end
	local xp = base * diff * (if champion then HuntRules.Champion.Xp else 1) * (fair or 1)
	return math.max(1, math.floor(xp + 0.5))
end

HuntRules.CritBase = 0.08
HuntRules.CritPerLuck = 0.004
HuntRules.CritMax = 0.35
HuntRules.CritMul = 1.75

-- ¿Crítico? (suerte: el atributo Suerte del personaje)
function HuntRules.crit(luck: number?, rand: () -> number): (boolean, number)
	local chance = math.min(HuntRules.CritMax, HuntRules.CritBase + (tonumber(luck) or 0) * HuntRules.CritPerLuck)
	if rand() < chance then
		return true, HuntRules.CritMul
	end
	return false, 1
end

HuntRules.Tiers = {
	{ Name = "Común", Max = 1, Color = rgb(235, 235, 235), Rank = 1 },
	{ Name = "Poco común", Max = 0.4, Color = rgb(90, 220, 100), Rank = 2 },
	{ Name = "Raro", Max = 0.15, Color = rgb(80, 150, 255), Rank = 3 },
	{ Name = "Épico", Max = 0.06, Color = rgb(190, 100, 255), Rank = 4 },
	{ Name = "Legendario", Max = 0.02, Color = rgb(255, 160, 40), Rank = 5 },
}

-- La rareza de algo que cae con esa probabilidad (0..1)
function HuntRules.tier(chance: number): { [string]: any }
	local best = HuntRules.Tiers[1]
	for _, t in HuntRules.Tiers do
		if chance <= t.Max then
			best = t
		end
	end
	return best
end

-- La rareza de lo mejor que ha soltado una especie (drops: { {id, min, max, prob} }; loot: { [id] = n })
function HuntRules.bestTier(drops: { any }?, loot: { [string]: number }): { [string]: any }
	local best = HuntRules.Tiers[1]
	for _, d in drops or {} do
		if loot[d[1]] and (tonumber(d[4]) or 1) <= 1 then
			local t = HuntRules.tier(tonumber(d[4]) or 1)
			if t.Rank > best.Rank then
				best = t
			end
		end
	end
	return best
end

return HuntRules
