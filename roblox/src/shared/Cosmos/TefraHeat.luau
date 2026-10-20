-- TefraHeat: el CALOR de Tefra (la desventaja del planeta, docs/planetas/diseno-mundos.md §2.7 y §3.1.11).
-- Cuentas puras: las usa Services/TefraService (el servidor decide el calor de cada jugador) y las
-- pruebas (scripts/test-tefra.luau). El cliente solo enseña el medidor (Controllers/TefraHud).
--
-- Un medidor de 0 a 100 que solo existe en Tefra:
--   * SUBE junto a la lava (el foso, el Canal de la Forja, los pozos y los lagos de lava del planeta),
--     en las Fundiciones y los Pozos de Magma, fuera de la muralla de día, junto al crisol del fundidor y
--     junto a una colada (Hot: fuentes de calor de los oficios).
--   * BAJA solo cuando no hay nada que caliente, y deprisa dentro de un refugio (los baños termales
--     enfrían más que nadie).
--   * Tres fases: Normal (< 60) → Aviso (60-85: vas más lento y la pantalla ondula) → Peligro (≥ 85:
--     además pierdes vida poco a poco). NUNCA se muere de golpe: con el medidor lleno un rato (o con
--     poca vida) te «Derriba» el calor y despiertas en el refugio más cercano, sin perder nada.
--   * Contramedidas: el traje refrigerado (lo llevas si está en tu mochila: el mejor que tengas),
--     el gel térmico (baja 40 de golpe y durante un minuto el calor casi no sube) y los refugios.
--   * Ayuda para quien empieza: las primeras 2 horas en Tefra el calor sube más despacio.

local TefraCity = require(script.Parent.TefraCity)

local TefraHeat = {}

TefraHeat.Max = 100
TefraHeat.Warn = 60
TefraHeat.Danger = 85
TefraHeat.KnockSeconds = 6 -- con el medidor lleno tanto tiempo, te derriba el calor
TefraHeat.KnockHealth = 20 -- …o si te queda esta vida (de 100) en Peligro
TefraHeat.DangerDamage = 2 -- vida por segundo en Peligro
TefraHeat.AfterKnock = 35 -- el calor con el que despiertas en el refugio
TefraHeat.NewbieSeconds = 2 * 3600
TefraHeat.NewbieFactor = 0.6
TefraHeat.GelDrop = 40
TefraHeat.GelSeconds = 60
TefraHeat.GelFactor = 0.25

-- Trajes refrigerados (objetos de la mochila): cuánto del calor que sube te llega (el mejor gana)
TefraHeat.Suits = {
	TrajeRefrigerado2 = { Level = 2, Factor = 0.6 },
	TrajeRefrigerado3 = { Level = 3, Factor = 0.4 },
}

-- Lo que sube cada segundo según la distancia a la lava (studs)
TefraHeat.LavaBands = { { 6, 4 }, { 14, 2.2 }, { 26, 1 } }
TefraHeat.HotBands = { { 8, 3 }, { 16, 1.5 } } -- crisol, colada…
TefraHeat.DistrictHeat = { Fundiciones = 0.35, Pozos = 0.35 }
TefraHeat.OutsideDay = 0.25 -- fuera de la muralla, de día (de 9:00 a 19:00)
TefraHeat.Cooling = 1.2 -- lo que baja cada segundo si no hay nada que caliente

-- Lagos de lava del planeta (local x, z, radio): los mismos que shared/Cosmos/Tefra.LavaPools. Se
-- copian aquí para no necesitar Tefra (que ya depende de TefraCity); test-tefra comprueba que coinciden.
TefraHeat.Pools = {
	{ X = 820, Z = -760, R = 46 },
	{ X = -980, Z = -240, R = 34 },
	{ X = 160, Z = 880, R = 40 },
	{ X = -260, Z = 1040, R = 28 },
}

-- Distancia (studs, en planta) a la lava más cercana desde un punto local de Tefra
function TefraHeat.lavaDistance(lx: number, lz: number): number
	local best = math.huge
	local R = TefraCity.Rect
	-- El foso: entre WallThick y MoatOut fuera del borde de la ciudad
	local d = TefraCity.rectDistance(lx, lz)
	if d < TefraCity.WallThick then
		best = math.min(best, TefraCity.WallThick - d)
	elseif d > TefraCity.MoatOut then
		best = math.min(best, d - TefraCity.MoatOut)
	else
		best = 0
	end
	-- El Canal de la Forja (de lado a lado de la ciudad)
	local c = TefraCity.Canal
	if lx > R.X0 - TefraCity.MoatOut and lx < R.X1 + TefraCity.MoatOut then
		best = math.min(best, math.max(0, math.abs(lz - c.Z) - c.Half))
	end
	for _, w in TefraCity.Wells do
		best = math.min(best, math.max(0, math.sqrt((lx - w.X) ^ 2 + (lz - w.Z) ^ 2) - w.R))
	end
	for _, p in TefraHeat.Pools do
		best = math.min(best, math.max(0, math.sqrt((lx - p.X) ^ 2 + (lz - p.Z) ^ 2) - p.R))
	end
	return best
end

-- Los puentes van por encima de la lava: sobre su calzada, la lava cuenta como si estuviera a 10 studs
function TefraHeat.onBridge(lx: number, lz: number): boolean
	return TefraCity.inLava(lx, lz) and TefraCity.streetDistance(lx, lz) <= TefraCity.RoadHalf
end

local function band(list: { { number } }, distance: number): number
	for _, b in list do
		if distance <= b[1] then
			return b[2]
		end
	end
	return 0
end

export type Context = {
	Lava: number?, -- distancia a la lava (studs)
	District: string?, -- barrio de Bastión Ceniza (TefraCity.districtAt)
	Outside: boolean?, -- fuera de la muralla
	Day: boolean?, -- de 9:00 a 19:00
	Hot: { number }?, -- distancias a las fuentes de calor de los oficios (crisol, colada…)
	Shelter: number?, -- dentro de un refugio: cuánto enfría por segundo
	Suit: number?, -- lo que te llega del calor con tu traje (1 = sin traje)
	Gel: boolean?, -- gel térmico activo
	Newbie: boolean?, -- primeras horas en Tefra
}

-- Lo que sube (positivo) o baja (negativo) el calor cada segundo
function TefraHeat.rate(ctx: Context): number
	if ctx.Shelter and ctx.Shelter > 0 then
		return -ctx.Shelter
	end
	local gain = 0
	if ctx.Lava then
		gain += band(TefraHeat.LavaBands, ctx.Lava)
	end
	for _, d in ctx.Hot or {} do
		gain += band(TefraHeat.HotBands, d)
	end
	gain += TefraHeat.DistrictHeat[ctx.District or ""] or 0
	if ctx.Outside and ctx.Day then
		gain += TefraHeat.OutsideDay
	end
	if gain <= 0 then
		return -TefraHeat.Cooling
	end
	gain *= math.clamp(ctx.Suit or 1, 0, 1)
	if ctx.Gel then
		gain *= TefraHeat.GelFactor
	end
	if ctx.Newbie then
		gain *= TefraHeat.NewbieFactor
	end
	return gain
end

function TefraHeat.step(heat: number, ctx: Context, dt: number): number
	return math.clamp(heat + TefraHeat.rate(ctx) * dt, 0, TefraHeat.Max)
end

function TefraHeat.phase(heat: number): string
	if heat >= TefraHeat.Danger then
		return "Peligro"
	elseif heat >= TefraHeat.Warn then
		return "Aviso"
	end
	return "Normal"
end

-- Cuánto de tu velocidad al andar te queda en cada fase
function TefraHeat.slow(phase: string): number
	if phase == "Peligro" then
		return 0.72
	elseif phase == "Aviso" then
		return 0.86
	end
	return 1
end

-- El mejor traje de la mochila (items = { [id] = n }) → factor (1 = ninguno) y su id
function TefraHeat.suitFactor(items: { [string]: any }?): (number, string?)
	local best, which = 1, nil
	for id, suit in TefraHeat.Suits do
		if items and (tonumber(items[id]) or 0) > 0 and suit.Factor < best then
			best, which = suit.Factor, id
		end
	end
	return best, which
end

-- ¿Hay que derribarte? (fase, segundos con el medidor lleno, vida que te queda)
function TefraHeat.knocked(heat: number, fullSeconds: number, health: number?): boolean
	if heat >= TefraHeat.Max and fullSeconds >= TefraHeat.KnockSeconds then
		return true
	end
	return heat >= TefraHeat.Danger and health ~= nil and health <= TefraHeat.KnockHealth
end

-- Lo que enseña el medidor (texto corto)
function TefraHeat.label(heat: number): string
	local phase = TefraHeat.phase(heat)
	if phase == "Peligro" then
		return "¡Demasiado calor! Busca sombra o un refugio"
	elseif phase == "Aviso" then
		return "Hace mucho calor"
	end
	return "Calor"
end

return TefraHeat
