-- Shields: escudo y casco (vida) de las naves, los drones y las torretas del combate aéreo.
--
--   * El daño va primero al ESCUDO; lo que sobra, al CASCO. Los misiles atraviesan parte del escudo
--     (Pierce) y los láseres no.
--   * El escudo se regenera solo si pasan Delay segundos sin recibir nada (Regen por segundo).
--   * Casco a 0 = destruido: los enemigos estallan (explosión, trozos y restos en llamas; sin sangre) y la
--     nave del jugador también, y vuelve al punto de control con una nave nueva.
-- Cuentas puras (las prueba scripts/test-aircombat.luau).

local Shields = {}

export type Spec = { Hull: number, Shield: number, Delay: number, Regen: number }
export type State = {
	Hull: number,
	MaxHull: number,
	Shield: number,
	MaxShield: number,
	Delay: number,
	Regen: number,
	LastHit: number,
}
export type Result = { Shield: number, Hull: number, Broke: boolean, Destroyed: boolean }

-- Cuánto del daño de cada arma se salta el escudo
Shields.Pierce = { Laser = 0, Missile = 0.3, Ram = 1 }

Shields.Specs = {
	Caza = { Hull = 100, Shield = 60, Delay = 3, Regen = 18 }, -- la nave del jugador
	Dron = { Hull = 22, Shield = 0, Delay = 99, Regen = 0 },
	CazaEnemigo = { Hull = 45, Shield = 30, Delay = 4, Regen = 10 },
	Torreta = { Hull = 70, Shield = 20, Delay = 5, Regen = 6 },
	Interceptor = { Hull = 28, Shield = 12, Delay = 3, Regen = 8 }, -- (Interceptor pirata y Aguja de Varkun: frágiles)
	Pesada = { Hull = 160, Shield = 80, Delay = 5, Regen = 8 }, -- (cañonera de apoyo: dura)
} :: { [string]: Spec }

function Shields.new(spec: Spec | string, mult: number?): State
	local s: Spec = if type(spec) == "string" then Shields.Specs[spec] or Shields.Specs.Caza else spec
	local m = mult or 1
	return {
		Hull = s.Hull * m,
		MaxHull = s.Hull * m,
		Shield = s.Shield * m,
		MaxShield = s.Shield * m,
		Delay = s.Delay,
		Regen = s.Regen * m,
		LastHit = -math.huge,
	}
end

function Shields.destroyed(h: State): boolean
	return h.Hull <= 0
end

-- Aplica `amount` de daño del arma `kind` ("Laser" | "Missile" | "Ram") en el instante `now`
function Shields.apply(h: State, amount: number, now: number, kind: string?): Result
	local result: Result = { Shield = 0, Hull = 0, Broke = false, Destroyed = false }
	if h.Hull <= 0 or amount <= 0 or amount ~= amount then
		return result
	end
	h.LastHit = now
	local pierce = Shields.Pierce[kind or "Laser"] or 0
	local toHull = amount * pierce
	local toShield = amount - toHull
	if h.Shield > 0 then
		local absorbed = math.min(h.Shield, toShield)
		h.Shield -= absorbed
		result.Shield = absorbed
		toHull += toShield - absorbed
		if h.Shield <= 0 then
			h.Shield = 0
			result.Broke = true
		end
	else
		toHull += toShield
	end
	local taken = math.min(h.Hull, toHull)
	h.Hull -= taken
	result.Hull = taken
	if h.Hull <= 0 then
		h.Hull = 0
		result.Destroyed = true
	end
	return result
end

-- Regenera el escudo (si toca). Devuelve cuánto ha subido.
function Shields.regen(h: State, now: number, dt: number): number
	if h.Hull <= 0 or h.Shield >= h.MaxShield or now - h.LastHit < h.Delay then
		return 0
	end
	local before = h.Shield
	h.Shield = math.min(h.MaxShield, h.Shield + h.Regen * dt)
	return h.Shield - before
end

function Shields.reset(h: State)
	h.Hull = h.MaxHull
	h.Shield = h.MaxShield
	h.LastHit = -math.huge
end

-- 0..1 de cada barra (para el panel)
function Shields.fractions(h: State): (number, number)
	local hull = if h.MaxHull > 0 then h.Hull / h.MaxHull else 0
	local shield = if h.MaxShield > 0 then h.Shield / h.MaxShield else 0
	return shield, hull
end

return Shields
