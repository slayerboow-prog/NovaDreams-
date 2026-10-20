-- MeleeHit: puñetazos y patadas a la invasión (alienígenas de tierra, élites, el rey y las criaturas
-- hostiles; nunca las pacíficas ni la gente transformada que no ataca). Cuentas puras: las aplica el
-- servidor (Services/CombatService con InvasionService.meleeTargets) y las prueba scripts/test-combat.
--
--   * Alcance desde la posición del personaje EN EL SERVIDOR (nunca lo que diga el cliente): delante
--     (cono de Combat.FacingDot) y hasta Combat.Range más el ancho del alienígena (su caja: el modelo de
--     verdad, sin tamaños fijos) y un poco de margen por el lag (Slack). Además, el alienígena se mira
--     donde estaba hace tu ping (HitCheck.rewindTime) y vale cualquiera de las dos posiciones.
--   * Daño: el del golpe de siempre (Combat.moveDamage: Fuerza, gimnasio) por Scale, con tope; el rey
--     solo encaja KingFactor (se le tumba con armas, a puñetazos cuesta).
--   * Empujón: los pequeños se apartan un poco; los grandes casi nada; el rey, nada.

local MeleeHit = {}

MeleeHit.Scale = 3 -- daño contra la invasión = golpe de siempre × esto (un puñetazo ≈ 15, una patada fuerte ≈ 40)
MeleeHit.Max = 60 -- tope por golpe (un arma de fuego siempre pega más por segundo)
MeleeHit.KingFactor = 0.4 -- el rey encaja menos de los puñetazos
MeleeHit.Slack = 1.5 -- studs de margen (la red)
MeleeHit.Knock = { Grunt = 2.5, Ranged = 2.5, Heavy = 0.8, Elite = 1.2, King = 0, Creature = 2 }
MeleeHit.HeavyKnock = 1.8 -- un golpe fuerte empuja más

-- Radio (en planta) de un modelo por su caja (GetExtentsSize)
function MeleeHit.radiusOf(size: Vector3?): number
	if not size then
		return 1
	end
	return math.clamp(math.max(size.X, size.Z) / 2, 0.5, 30)
end

-- ¿Le llega el golpe? from/look: el que pega (look en planta); center/radius: el objetivo.
-- Devuelve (¿llega?, distancia al borde).
function MeleeHit.inReach(from: Vector3, look: Vector3, center: Vector3, radius: number, range: number, facingDot: number): (boolean, number)
	local offset = Vector3.new(center.X - from.X, 0, center.Z - from.Z)
	local distance = offset.Magnitude
	local edge = math.max(0, distance - radius)
	-- (en altura: no se pega a algo que está muy por encima o muy por debajo)
	if math.abs(center.Y - from.Y) > radius + 8 then
		return false, edge
	end
	if edge > range + MeleeHit.Slack then
		return false, edge
	end
	if distance <= radius + 0.5 then
		return true, edge -- (pegado o dentro de su caja: le da aunque esté a un lado)
	end
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 1e-3 then
		return false, edge
	end
	-- El cono se mide al lado más cercano de su caja: a uno grande se le da aunque su centro quede algo fuera
	local dir = offset.Unit
	local dot = flatLook.Unit:Dot(dir)
	local widen = math.clamp(radius / math.max(distance, 0.1), 0, 0.9)
	return dot >= facingDot - widen, edge
end

-- Daño de un golpe (base: Combat.moveDamage del golpe), ya escalado y con el del rey rebajado
function MeleeHit.amount(base: number, isKing: boolean?): number
	if type(base) ~= "number" or base ~= base or base <= 0 then
		return 0
	end
	local n = math.min(base * MeleeHit.Scale, MeleeHit.Max)
	if isKing then
		n *= MeleeHit.KingFactor
	end
	return math.max(1, math.floor(n + 0.5))
end

-- Cuánto se aparta (studs) al encajar el golpe
function MeleeHit.knock(kind: string?, heavy: boolean?): number
	local k = MeleeHit.Knock[kind or ""] or 1.5
	return if heavy then k * MeleeHit.HeavyKnock else k
end

return MeleeHit
