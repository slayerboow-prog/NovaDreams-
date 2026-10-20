-- PlanetHazard: la DESVENTAJA de un planeta como un medidor genérico (docs/planetas/diseno-mundos.md §2.7,
-- «sistema común de Entorno»; marco común: docs/planetas/marco-planetas.md). Cuentas puras.
--
-- Un medidor de 0 a Max que solo existe en su planeta (calor en Tefra, toxinas en Miasma, sed en Siroco…):
--   * SUBE con las FUENTES (Bands: distancia → lo que sube por segundo; «junto a la lava», «en la niebla»),
--     por la ZONA (ZoneRate: barrio o bioma), por estar FUERA de día (Exposed) y por un ritmo de fondo
--     (Base: la sed sube siempre un poco).
--   * BAJA solo si no hay nada que lo suba (Recovery), y deprisa en un REFUGIO (ctx.Shelter).
--   * Tres fases: Normal (< Warn) → Aviso (vas más lento) → Peligro (≥ Danger: además pierdes vida poco a
--     poco). NUNCA se muere de golpe: lleno un rato (o con poca vida) te «Derriba» y despiertas a salvo.
--   * Contramedidas: EQUIPO (Gear: lo mejor que tengas en la mochila; Factor = lo que te llega), un
--     CONSUMIBLE (Consumable: baja Drop de golpe y durante Seconds casi no sube) y los refugios.
--   * Ayuda para quien empieza: las primeras NewbieSeconds en el planeta sube más despacio.
--
--   PlanetHazard.new(cfg) → H con rate(ctx), step(v, ctx, dt), phase(v), slow(phase), gearFactor(items),
--   knocked(v, fullSeconds, health), label(v). El calor de Tefra (shared/Cosmos/TefraHeat) es UNA
--   configuración de esto; Services/PlanetHazardService lo lleva para los planetas nuevos.
--
--   ctx = { Near = { [banda] = distancia | { distancias } }, Zone = id, Exposed = bool, Shelter = n,
--           Gear = factor (1 = nada), Boost = consumible activo, Newbie = bool }

local PlanetHazard = {}

export type Config = {
	Id: string, -- "Calor" | "Toxinas" | "Sed" …
	Name: string?, -- nombre para el medidor
	Icon: string?,
	Max: number?,
	Warn: number?,
	Danger: number?,
	KnockSeconds: number?,
	KnockHealth: number?,
	DangerDamage: number?,
	AfterKnock: number?,
	NewbieSeconds: number?,
	NewbieFactor: number?,
	Bands: { [string]: { { number } } }?, -- [fuente] = { { hasta, sube } } (de cerca a lejos)
	ZoneRate: { [string]: number }?,
	Exposed: number?,
	Base: number?, -- lo que sube siempre (la sed)
	Recovery: number?, -- lo que baja si nada lo sube
	Gear: { [string]: { Level: number, Factor: number } }?,
	Consumable: { Item: string, Drop: number, Seconds: number, Factor: number }?,
	Slow: { Aviso: number, Peligro: number }?,
	Labels: { Normal: string, Aviso: string, Peligro: string }?,
}

local function band(list: { { number } }, distance: number): number
	for _, b in list do
		if distance <= b[1] then
			return b[2]
		end
	end
	return 0
end
PlanetHazard.band = band

function PlanetHazard.new(cfg: Config): { [string]: any }
	local H: { [string]: any } = {}
	H.Config = cfg
	H.Id = cfg.Id
	H.Name = cfg.Name or cfg.Id
	H.Icon = cfg.Icon or "⚠"
	H.Max = cfg.Max or 100
	H.Warn = cfg.Warn or 60
	H.Danger = cfg.Danger or 85
	H.KnockSeconds = cfg.KnockSeconds or 6
	H.KnockHealth = cfg.KnockHealth or 20
	H.DangerDamage = cfg.DangerDamage or 2
	H.AfterKnock = cfg.AfterKnock or 35
	H.NewbieSeconds = cfg.NewbieSeconds or 2 * 3600
	H.NewbieFactor = cfg.NewbieFactor or 0.6
	H.Bands = cfg.Bands or {}
	H.ZoneRate = cfg.ZoneRate or {}
	H.Exposed = cfg.Exposed or 0
	H.Base = cfg.Base or 0
	H.Recovery = cfg.Recovery or 1.2
	H.Gear = cfg.Gear or {}
	H.Consumable = cfg.Consumable
	local slow = cfg.Slow or { Aviso = 0.86, Peligro = 0.72 }
	local labels = cfg.Labels or { Normal = H.Name, Aviso = "Cuidado: " .. H.Name, Peligro = "¡Peligro! " .. H.Name }

	-- Lo que sube (positivo) o baja (negativo) cada segundo
	function H.rate(ctx: { [string]: any }): number
		if ctx.Shelter and ctx.Shelter > 0 then
			return -ctx.Shelter
		end
		local gain = 0
		for source, d in ctx.Near or {} do
			local bands = H.Bands[source]
			if bands then
				if type(d) == "table" then
					for _, one in d do
						gain += band(bands, one)
					end
				else
					gain += band(bands, d)
				end
			end
		end
		gain += H.ZoneRate[ctx.Zone or ""] or 0
		if ctx.Exposed then
			gain += H.Exposed
		end
		gain += H.Base
		if gain <= 0 then
			return -H.Recovery
		end
		gain *= math.clamp(ctx.Gear or 1, 0, 1)
		if ctx.Boost and H.Consumable then
			gain *= H.Consumable.Factor
		end
		if ctx.Newbie then
			gain *= H.NewbieFactor
		end
		return gain
	end

	function H.step(value: number, ctx: { [string]: any }, dt: number): number
		return math.clamp(value + H.rate(ctx) * dt, 0, H.Max)
	end

	function H.phase(value: number): string
		if value >= H.Danger then
			return "Peligro"
		elseif value >= H.Warn then
			return "Aviso"
		end
		return "Normal"
	end

	function H.slow(phase: string): number
		if phase == "Peligro" then
			return slow.Peligro
		elseif phase == "Aviso" then
			return slow.Aviso
		end
		return 1
	end

	-- El mejor equipo de la mochila (items = { [id] = n }) → factor (1 = ninguno) y su id
	function H.gearFactor(items: { [string]: any }?): (number, string?)
		local best, which = 1, nil
		for id, g in H.Gear do
			if items and (tonumber(items[id]) or 0) > 0 and g.Factor < best then
				best, which = g.Factor, id
			end
		end
		return best, which
	end

	function H.knocked(value: number, fullSeconds: number, health: number?): boolean
		if value >= H.Max and fullSeconds >= H.KnockSeconds then
			return true
		end
		return value >= H.Danger and health ~= nil and health <= H.KnockHealth
	end

	function H.label(value: number): string
		return labels[H.phase(value)] or H.Name
	end

	return H
end

return PlanetHazard
