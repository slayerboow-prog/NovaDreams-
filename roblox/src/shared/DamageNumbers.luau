-- DamageNumbers: los números de daño que ve el jugador cuando le da a la invasión (alienígenas, rey,
-- criaturas hostiles y naves). UN solo sistema para todo: puñetazos y patadas, cada arma, el cañón de la
-- avioneta y el láser de la nave. El número lo manda el servidor SOLO a quien ha hecho el daño
-- (InvasionService: "Dmg" por el remoto de la invasión) con el daño de verdad: el cliente nunca se
-- inventa un número. Lo pinta Controllers/DamagePops. Cuentas puras (scripts/test-hud, test-shooter).
--
--   * Color por tipo: normal blanco, crítico/cabeza amarillo, cuerpo a cuerpo naranja, escudo (los
--     puntos débiles acorazados del rey) cian.
--   * Tamaño un poco mayor cuanto más daño (y al tumbarlo).
--   * Ráfagas: los golpes al MISMO objetivo y del mismo tipo seguidos (a menos de MergeWindow del
--     anterior) se suman en un solo número que crece (no una lluvia de números).
--   * Tope de números a la vez (menos en el móvil): si no cabe, se quita el más viejo.
--   * Suben y se desvanecen en Life segundos, con contorno para que se lean sobre cualquier fondo.
--   * Respetan el ajuste «🔢 Números de daño: Sí/No» (ShooterPrefs.Numbers, Sí por defecto).

local DamageNumbers = {}

DamageNumbers.Life = 0.8 -- segundos que dura cada número (sube y se desvanece)
DamageNumbers.Rise = 2.6 -- studs que sube
DamageNumbers.MergeWindow = 0.15 -- golpes a menos de esto del anterior (mismo objetivo y tipo): se suman
DamageNumbers.MergeDistance = 6 -- sin objetivo conocido: se suman si caen así de cerca
DamageNumbers.MaxPhone = 5
DamageNumbers.MaxDesktop = 10
DamageNumbers.MaxDistance = 260 -- más lejos no se pinta

DamageNumbers.Kinds = { "Normal", "Crit", "Melee", "Shield" }
DamageNumbers.Colors = {
	Normal = { 255, 255, 255 },
	Crit = { 255, 220, 60 },
	Melee = { 255, 150, 60 },
	Shield = { 90, 225, 255 },
}
DamageNumbers.Stroke = { 20, 16, 24 } -- contorno oscuro (se lee sobre el cielo y sobre la nieve)

-- El tipo de número de un golpe: escudo > crítico (cabeza) > cuerpo a cuerpo > normal
function DamageNumbers.kindOf(info: { Melee: boolean?, Head: boolean?, Crit: boolean?, Shield: boolean? }): string
	if info.Shield then
		return "Shield"
	elseif info.Head or info.Crit then
		return "Crit"
	elseif info.Melee then
		return "Melee"
	end
	return "Normal"
end

function DamageNumbers.valid(kind: any): boolean
	return type(kind) == "string" and DamageNumbers.Colors[kind] ~= nil
end

-- Escala del texto (1 = normal): crece despacio con el daño y un poco más al tumbarlo
function DamageNumbers.scale(amount: number, kill: boolean?): number
	local a = math.max(1, amount)
	local s = 1 + math.clamp(math.log(a / 15, 10) * 0.45, -0.15, 0.55)
	if kill then
		s += 0.15
	end
	return math.clamp(s, 0.85, 1.7)
end

function DamageNumbers.text(amount: number): string
	return tostring(math.max(1, math.floor(amount + 0.5)))
end

function DamageNumbers.cap(phone: boolean): number
	return if phone then DamageNumbers.MaxPhone else DamageNumbers.MaxDesktop
end

export type Entry = { Id: number, Target: any?, At: Vector3, Amount: number, Kind: string, Kill: boolean, Born: number, Last: number }
export type State = { List: { Entry }, Serial: number }

function DamageNumbers.new(): State
	return { List = {}, Serial = 0 }
end

-- Quita los que ya se han desvanecido
function DamageNumbers.prune(state: State, now: number)
	for i = #state.List, 1, -1 do
		if now - state.List[i].Born > DamageNumbers.Life then
			table.remove(state.List, i)
		end
	end
end

-- Un golpe confirmado. Devuelve (el número que hay que pintar, ¿se ha sumado a uno que ya estaba?,
-- el que se ha quitado para hacer sitio o nil).
function DamageNumbers.push(state: State, now: number, hit: { At: Vector3, Amount: number, Kind: string?, Kill: boolean?, Target: any? }, phone: boolean): (Entry?, boolean, Entry?)
	local amount = tonumber(hit.Amount) or 0
	if amount <= 0 or amount ~= amount or typeof(hit.At) ~= "Vector3" then
		return nil, false, nil
	end
	local kind = if DamageNumbers.valid(hit.Kind) then hit.Kind :: string else "Normal"
	DamageNumbers.prune(state, now)
	for _, e in state.List do
		local same = if hit.Target ~= nil and e.Target ~= nil then e.Target == hit.Target else (e.At - hit.At).Magnitude <= DamageNumbers.MergeDistance
		if same and e.Kind == kind and now - e.Last <= DamageNumbers.MergeWindow then
			e.Amount += amount
			e.Last = now
			e.Born = now -- (vuelve a empezar a subir: se ve crecer el número)
			e.At = hit.At
			e.Kill = e.Kill or hit.Kill == true
			return e, true, nil
		end
	end
	local evicted: Entry? = nil
	if #state.List >= DamageNumbers.cap(phone) then
		local oldest, at = nil, 0
		for i, e in state.List do
			if not oldest or e.Born < oldest.Born then
				oldest, at = e, i
			end
		end
		evicted = oldest
		table.remove(state.List, at)
	end
	state.Serial += 1
	local e: Entry = { Id = state.Serial, Target = hit.Target, At = hit.At, Amount = amount, Kind = kind, Kill = hit.Kill == true, Born = now, Last = now }
	table.insert(state.List, e)
	return e, false, evicted
end

return DamageNumbers
