-- HuntContracts: los CONTRATOS DE CAZA del tablón (petición del dueño, 17-11-2026: misiones de caza de MMO).
-- Cuentas puras (las usan Services/HuntContractService, UI/Hud y scripts/test-contratos.luau).
--
--   * Cada día (UTC) el tablón ofrece Offers contratos para tu nivel, siempre los mismos ese día para ti:
--       - "Caza": matar Need bestias de UNA especie de una zona («Caza 16 lobos del bosque en Caza del Oeste»)
--       - "Zona": limpiar una zona (Need bestias cualesquiera de allí)
--       - "Jefe": derribar el jefe de una región (solo si ya te toca: nivel de la región − 5 o más)
--   * Zonas: los cuatro distritos de caza de la isla (shared/CityPlan, Region = "Farm_<Id>") y las ocho regiones
--     (shared/Cosmos/ValmarRegions, Region = su Id). Cada bestia lleva su Region (BeastService → BeastKilled).
--   * Como mucho MaxActive a la vez. Al completar uno se cobra solo: dinero, experiencia y pociones.

local CityPlan = require(script.Parent.CityPlan)
local VR = require(script.Parent.Cosmos.ValmarRegions)
local Bestiary = require(script.Parent.Cosmos.Bestiary)
local Gameplay = require(script.Parent.Gameplay)
local Format = require(script.Parent.Format)

local HuntContracts = {}

HuntContracts.Offers = 3
HuntContracts.MaxActive = 3

export type Zone = { Id: string, Name: string, Icon: string, Min: number, Max: number, Species: { string }, Boss: string? }
export type Contract = {
	Key: string, -- (el mismo contrato el mismo día: no se coge dos veces)
	Kind: string, -- "Caza" | "Zona" | "Jefe"
	Zone: string,
	Species: string?,
	Need: number,
	Have: number,
	Money: number,
	Xp: number,
	Potions: number,
}

-- Las zonas de caza, de menos a más nivel
local zones: { Zone }? = nil
function HuntContracts.zones(): { Zone }
	if zones then
		return zones
	end
	local list: { Zone } = {}
	for _, d in CityPlan.Districts do
		if d.Farm then
			table.insert(list, { Id = "Farm_" .. d.Id, Name = d.Name, Icon = d.Icon or "🐾", Min = d.Farm.Min, Max = d.Farm.Max, Species = d.Farm.Species })
		end
	end
	for _, r in VR.List do
		table.insert(list, { Id = r.Id, Name = r.Name, Icon = r.Icon, Min = r.MinLevel, Max = r.MaxLevel, Species = r.Species, Boss = r.Boss })
	end
	table.sort(list, function(a, b)
		return a.Min < b.Min
	end)
	zones = list
	return list
end

function HuntContracts.zone(id: string): Zone?
	for _, z in HuntContracts.zones() do
		if z.Id == id then
			return z
		end
	end
	return nil
end

-- Las zonas que tocan a ese nivel (la mejor primero); si ninguna, la más cercana por abajo
function HuntContracts.zonesFor(level: number): { Zone }
	local fit = {}
	for _, z in HuntContracts.zones() do
		if level >= z.Min - 2 and level <= z.Max + 4 then
			table.insert(fit, z)
		end
	end
	if #fit == 0 then
		local best: Zone? = nil
		for _, z in HuntContracts.zones() do
			if z.Min <= level then
				best = z
			end
		end
		table.insert(fit, best or HuntContracts.zones()[1])
	end
	-- (la que más se ajusta primero: tu nivel cerca del medio de su franja)
	table.sort(fit, function(a, b)
		return math.abs(level - (a.Min + a.Max) / 2) < math.abs(level - (b.Min + b.Max) / 2)
	end)
	return fit
end

-- El nombre de una especie en plural sencillo («lobos del bosque»)
local function plural(name: string): string
	local first, rest = string.match(name, "^(%S+)(.*)$")
	if not first then
		return name:lower()
	end
	first = first:lower()
	if string.match(first, "[aeiouáéó]$") then
		first ..= "s"
	elseif string.match(first, "z$") then
		first = string.sub(first, 1, -2) .. "ces"
	else
		first ..= "es"
	end
	-- (los adjetivos de detrás también: «Lobo gigante» → «lobos gigantes»; los «de …» se quedan)
	local tail = rest:lower()
	if tail ~= "" and not string.find(tail, "^%s+de ") and not string.find(tail, "^%s+del ") then
		tail = string.gsub(tail, "(%a+)$", function(w)
			if string.match(w, "[aeiou]$") then
				return w .. "s"
			end
			return w .. "es"
		end)
	end
	return first .. tail
end
HuntContracts.plural = plural

function HuntContracts.speciesName(sid: string?): string
	local sp = sid and Bestiary.Species[sid]
	return if sp then sp.Name else tostring(sid or "bestias")
end

-- Lo que da (según tu nivel y lo que cuesta)
-- (la experiencia, en trozos del nivel: shared/Gameplay.xpToNext; ~40 bestias de tu nivel valen un nivel entero)
function HuntContracts.reward(kind: string, need: number, level: number): (number, number, number)
	local lv = math.max(1, level)
	local perKill = 25 + lv * 4
	local nextXp = Gameplay.xpToNext(lv)
	if kind == "Jefe" then
		return math.floor(perKill * 40 / 10) * 10, math.floor(nextXp * 0.8), 3
	elseif kind == "Zona" then
		return math.floor(perKill * need * 0.9 / 10) * 10, math.floor(nextXp * need / 45), 2
	end
	return math.floor(perKill * need / 10) * 10, math.floor(nextXp * need / 40), 1
end

-- Azar repetible
local function rng(seed: number): () -> number
	local s = math.max(1, math.floor(seed) % 2147483646)
	return function(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

-- Los contratos de hoy para ese jugador y nivel
function HuntContracts.offers(level: number, userId: number, day: number): { Contract }
	local r = rng(day * 7919 + (userId % 100000) * 31 + level * 3)
	local fit = HuntContracts.zonesFor(level)
	local out: { Contract } = {}
	local function add(kind: string, z: Zone, species: string?, need: number)
		local money, xp, pots = HuntContracts.reward(kind, need, math.clamp(level, z.Min, z.Max + 4))
		table.insert(out, {
			Key = ("%d:%s:%s:%s"):format(day, kind, z.Id, species or "-"),
			Kind = kind,
			Zone = z.Id,
			Species = species,
			Need = need,
			Have = 0,
			Money = money,
			Xp = xp,
			Potions = pots,
		})
	end
	-- 1) una especie de la zona que mejor te va
	local z1 = fit[1]
	add("Caza", z1, z1.Species[1 + math.floor(r() * #z1.Species)], 10 + 4 * math.floor(r() * 3))
	-- 2) limpiar una zona (la segunda que te va, o la misma)
	local z2 = fit[2] or z1
	add("Zona", z2, nil, 20 + 5 * math.floor(r() * 3))
	-- 3) un jefe de región si ya te toca; si no, otra especie
	local boss: Zone? = nil
	for _, z in fit do
		if z.Boss and level >= z.Min - 5 then
			boss = z
			break
		end
	end
	if boss then
		add("Jefe", boss, boss.Boss, 1)
	else
		local z3 = fit[#fit]
		local sid = z3.Species[1 + math.floor(r() * #z3.Species)]
		if out[1].Species == sid and #z3.Species > 1 then
			sid = z3.Species[1 + (table.find(z3.Species, sid) :: number) % #z3.Species]
		end
		add("Caza", z3, sid, 12 + 4 * math.floor(r() * 3))
	end
	return out
end

-- ¿Esta bestia cuenta para el contrato? ev = { Species, Region, Boss }
function HuntContracts.matches(c: Contract, ev: { [string]: any }): boolean
	if ev.Planet ~= nil and ev.Planet ~= "Valmar" then
		return false
	end
	if c.Kind == "Jefe" then
		return ev.Boss == true and ev.Species == c.Species
	end
	if ev.Region ~= c.Zone then
		return false
	end
	if c.Kind == "Caza" then
		return ev.Species == c.Species
	end
	return true -- (Zona: cualquiera de allí)
end

-- El texto del contrato («Caza 14 lobos del bosque · Caza del Oeste»)
function HuntContracts.title(c: Contract): string
	local z = HuntContracts.zone(c.Zone)
	local where = if z then z.Name else c.Zone
	local icon = if z then z.Icon else "🐾"
	if c.Kind == "Jefe" then
		return ("👑 Derriba a %s · %s"):format(HuntContracts.speciesName(c.Species), where)
	elseif c.Kind == "Zona" then
		return ("%s Limpia %s: %d bestias"):format(icon, where, c.Need)
	end
	return ("%s Caza %d %s · %s"):format(icon, c.Need, plural(HuntContracts.speciesName(c.Species)), where)
end

function HuntContracts.rewardText(c: Contract): string
	return ("%s · %d XP · %d 🧪"):format(Format.money(c.Money), c.Xp, c.Potions)
end

-- El día de los contratos (cambian a medianoche UTC)
function HuntContracts.day(now: number?): number
	return math.floor((now or os.time()) / 86400)
end

return HuntContracts
