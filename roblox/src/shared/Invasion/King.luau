-- King: el dios o rey de la raza que invade (jefe final de una invasión con mala suerte). Cuentas
-- puras (scripts/test-invasion.luau); lo mueve y lo dibuja InvasionService (World/Kit/AlienModels).
--
--   * Enorme y muy duro: su vida crece con los jugadores que hay en Valmar (KING.Hp + PerPlayer por
--     cada uno de más, con tope).
--   * Tres FASES (100-66 %, 66-33 %, 33-0 %). En cada una tiene PUNTOS DÉBILES (cristales, núcleos,
--     engranajes, según la raza): mientras quede alguno, el cuerpo está blindado (solo le llega
--     Armored del daño). Rotos todos, queda AL DESCUBIERTO unos segundos (daño doble) y, si no cae la
--     fase, los puntos débiles vuelven a salir.
--   * Ataques de área con aviso (un círculo en el suelo que se llena antes de golpear): Onda (a su
--     alrededor), Lluvia (varios círculos sobre los jugadores) y Rayo (una franja). Más a menudo en
--     cada fase. Y llama a tropas (adds) al cambiar de fase.
--   * Al caer: aviso a todo el servidor, recompensa grande para quien haya ayudado (Loot.king) y
--     estalla en luz y trozos (nada de sangre).

local King = {}

King.Hp = 5200
King.PerPlayer = 2600
King.MaxHp = 22000
King.WeakPoints = 3
King.WeakHp = 420
King.Armored = 0.2 -- daño que le llega al cuerpo con puntos débiles
King.Exposed = 2 -- daño con el núcleo al descubierto
King.ExposedSeconds = 12
King.Phases = { 1, 0.66, 0.33 } -- (desde qué fracción de vida empieza cada fase)
King.Adds = { 3, 4, 5 } -- tropas que llama al empezar cada fase
King.AttackEvery = { 7, 5.5, 4 } -- s entre ataques de área (por fase)
King.Telegraph = 2.2 -- s de aviso antes de golpear
King.Attacks = {
	Onda = { Radius = 46, Damage = 28 },
	Lluvia = { Radius = 14, Damage = 22, Count = 4 },
	Rayo = { Width = 12, Length = 140, Damage = 26 },
}
King.Height = 46 -- (de alto, para los modelos y las marcas)
King.Radius = 16

export type State = {
	Race: string,
	Hp: number,
	MaxHp: number,
	Phase: number,
	Weak: { number }, -- vida de cada punto débil (0 = roto)
	ExposedUntil: number,
	NextAttack: number,
	AttackIndex: number,
	Dead: boolean,
}

function King.maxHp(players: number): number
	return math.min(King.Hp + King.PerPlayer * math.max(0, players - 1), King.MaxHp)
end

function King.new(race: string, players: number, now: number): State
	local hp = King.maxHp(players)
	local weak = {}
	for i = 1, King.WeakPoints do
		weak[i] = King.WeakHp
	end
	return { Race = race, Hp = hp, MaxHp = hp, Phase = 1, Weak = weak, ExposedUntil = 0, NextAttack = now + 6, AttackIndex = 0, Dead = false }
end

function King.weakLeft(s: State): number
	local n = 0
	for _, hp in s.Weak do
		if hp > 0 then
			n += 1
		end
	end
	return n
end

function King.exposed(s: State, now: number): boolean
	return now < s.ExposedUntil
end

-- La fase que toca con esta vida (1..3)
function King.phaseFor(hp: number, max: number): number
	local f = hp / math.max(max, 1)
	local phase = 1
	for i, from in King.Phases do
		if f <= from then
			phase = i
		end
	end
	return phase
end

export type Result = { Dealt: number, PhaseChanged: boolean?, Phase: number?, Exposed: boolean?, WeakBroken: number?, Dead: boolean? }

-- Daño a un punto débil (índice) o al cuerpo (weak = nil). Devuelve lo que ha pasado.
function King.damage(s: State, amount: number, weak: number?, now: number): Result
	if s.Dead or amount <= 0 then
		return { Dealt = 0 }
	end
	if weak then
		local hp = s.Weak[weak]
		if not hp or hp <= 0 then
			return { Dealt = 0 }
		end
		local dealt = math.min(hp, amount)
		s.Weak[weak] = hp - dealt
		local out: Result = { Dealt = dealt }
		if s.Weak[weak] <= 0 then
			out.WeakBroken = weak
			if King.weakLeft(s) == 0 then
				s.ExposedUntil = now + King.ExposedSeconds
				out.Exposed = true
			end
		end
		return out
	end
	local k = if King.exposed(s, now) then King.Exposed elseif King.weakLeft(s) > 0 then King.Armored else 1
	local dealt = math.min(s.Hp, amount * k)
	s.Hp -= dealt
	local out: Result = { Dealt = dealt }
	if s.Hp <= 0 then
		s.Dead = true
		out.Dead = true
		return out
	end
	local phase = King.phaseFor(s.Hp, s.MaxHp)
	if phase > s.Phase then
		s.Phase = phase
		out.PhaseChanged = true
		out.Phase = phase
		-- (nueva fase: los puntos débiles vuelven a salir y se acaba el descubierto)
		for i = 1, King.WeakPoints do
			s.Weak[i] = King.WeakHp * (1 + 0.25 * (phase - 1))
		end
		s.ExposedUntil = 0
	end
	return out
end

-- Al acabar el descubierto sin cambiar de fase, los puntos débiles vuelven (a media vida)
function King.tick(s: State, now: number): boolean
	if s.Dead then
		return false
	end
	if s.ExposedUntil > 0 and now >= s.ExposedUntil and King.weakLeft(s) == 0 then
		s.ExposedUntil = 0
		for i = 1, King.WeakPoints do
			s.Weak[i] = King.WeakHp * 0.5
		end
		return true
	end
	return false
end

-- ¿Toca un ataque de área? Devuelve su nombre (en ciclo: Onda → Lluvia → Rayo)
function King.nextAttack(s: State, now: number): string?
	if s.Dead or now < s.NextAttack then
		return nil
	end
	s.NextAttack = now + King.AttackEvery[s.Phase] + King.Telegraph
	s.AttackIndex += 1
	local order = { "Onda", "Lluvia", "Rayo" }
	local pick = order[(s.AttackIndex - 1) % #order + 1]
	if s.Phase == 1 and pick == "Rayo" then
		pick = "Onda" -- (en la primera fase, sin rayo)
	end
	return pick
end

-- ¿Le pilla un ataque de área a alguien en `pos`? (center = dónde golpea; dir = hacia dónde, para el rayo)
function King.hits(attack: string, center: Vector3, pos: Vector3, dir: Vector3?): boolean
	local A = King.Attacks[attack]
	if not A then
		return false
	end
	local d = Vector3.new(pos.X - center.X, 0, pos.Z - center.Z)
	if attack == "Rayo" then
		local fwd = dir and Vector3.new(dir.X, 0, dir.Z) or Vector3.new(0, 0, -1)
		fwd = if fwd.Magnitude > 0.01 then fwd.Unit else Vector3.new(0, 0, -1)
		local along = d:Dot(fwd)
		local side = math.abs(d:Dot(Vector3.new(-fwd.Z, 0, fwd.X)))
		return along >= 0 and along <= A.Length and side <= A.Width / 2
	end
	return d.Magnitude <= A.Radius
end

-- Para el panel: "Fase 2 · blindado (2 puntos débiles)" / "¡AL DESCUBIERTO!"
function King.status(s: State, now: number): string
	if s.Dead then
		return "Derrotado"
	end
	if King.exposed(s, now) then
		return ("Fase %d · ¡AL DESCUBIERTO!"):format(s.Phase)
	end
	local w = King.weakLeft(s)
	if w > 0 then
		return ("Fase %d · blindado: rompe sus %d puntos débiles"):format(s.Phase, w)
	end
	return ("Fase %d"):format(s.Phase)
end

return King
