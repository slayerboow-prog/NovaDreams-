-- HitCheck: los disparos a pie contra los alienígenas, decididos por el SERVIDOR con compensación de
-- lag (docs/invasion.md, «Pelear»). Cuentas puras (las prueba scripts/test-invasion y test-shooter).
--
-- El problema: el servidor mueve a los alienígenas (PivotTo) y a tu pantalla llegan un poco tarde (tu
-- ping + la interpolación de Roblox). Si el servidor comprueba el disparo con la posición de AHORA, a
-- un alienígena que corre de lado le fallas aunque en tu pantalla le dieras de lleno.
-- La solución (la de los shooters): el servidor guarda un poco de historia de cada alienígena (dónde
-- estaba hace 0,05 s, 0,1 s…) y, si el rayo de verdad no le da, prueba contra su posición de hace
-- `rewind` segundos (tu ping + la interpolación, con tope MaxRewind) con una cápsula algo generosa
-- (Tolerance). Sigue siendo el servidor quien decide: nunca a través de una pared (la cápsula tiene que
-- estar antes que lo que tapa el rayo), nunca más lejos del alcance y nunca hacia atrás.

local HitCheck = {}

HitCheck.MaxRewind = 0.4 -- segundos como mucho hacia atrás
HitCheck.Interp = 0.1 -- lo que retrasa Roblox lo que ves de los demás (interpolación)
HitCheck.Tolerance = 1.15 -- la cápsula de cada alienígena, un poco más gorda
HitCheck.Keep = 0.6 -- segundos de historia
HitCheck.Every = 0.05 -- cada cuánto se apunta una posición
HitCheck.HeadShare = 0.8 -- de esta altura para arriba (del alto) cuenta como cabeza

export type History = { T: { number }, P: { Vector3 } }

function HitCheck.newHistory(): History
	return { T = {}, P = {} }
end

-- Apunta dónde está (pies) en el momento t; tira lo de hace más de Keep
function HitCheck.push(h: History, t: number, pos: Vector3)
	local n = #h.T
	if n > 0 and t - h.T[n] < HitCheck.Every then
		h.P[n] = pos -- (muy seguido: se actualiza la última)
		h.T[n] = t
		return
	end
	table.insert(h.T, t)
	table.insert(h.P, pos)
	while #h.T > 2 and t - h.T[1] > HitCheck.Keep do
		table.remove(h.T, 1)
		table.remove(h.P, 1)
	end
end

-- Dónde estaba en el momento t (interpolando; fuera de la historia, el extremo más cercano)
function HitCheck.sample(h: History, t: number): Vector3?
	local n = #h.T
	if n == 0 then
		return nil
	end
	if t <= h.T[1] then
		return h.P[1]
	end
	if t >= h.T[n] then
		return h.P[n]
	end
	for i = n - 1, 1, -1 do
		local t0, t1 = h.T[i], h.T[i + 1]
		if t >= t0 and t <= t1 then
			local k = if t1 > t0 then (t - t0) / (t1 - t0) else 0
			return h.P[i]:Lerp(h.P[i + 1], k)
		end
	end
	return h.P[n]
end

-- Cuánto hay que ir hacia atrás para este jugador (ping en segundos)
function HitCheck.rewindTime(ping: number?): number
	local p = if type(ping) == "number" and ping == ping and ping >= 0 then ping else 0.1
	return math.clamp(p + HitCheck.Interp, 0, HitCheck.MaxRewind)
end

-- Rayo (origen, dirección unitaria, alcance) contra una cápsula (de a a b, radio r): distancia o nil
function HitCheck.rayCapsule(origin: Vector3, dir: Vector3, range: number, a: Vector3, b: Vector3, r: number): number?
	-- Distancia mínima entre el rayo y el segmento (método de los dos parámetros)
	local u = dir
	local v = b - a
	local w = origin - a
	local uu, uv, vv = u:Dot(u), u:Dot(v), v:Dot(v)
	local uw, vw = u:Dot(w), v:Dot(w)
	local den = uu * vv - uv * uv
	local sc, tc
	if den < 1e-8 then
		sc, tc = 0, if vv > 1e-8 then math.clamp(vw / vv, 0, 1) else 0
	else
		sc = (uv * vw - vv * uw) / den
		tc = (uu * vw - uv * uw) / den
		if tc < 0 then
			tc = 0
			sc = -uw / uu
		elseif tc > 1 then
			tc = 1
			sc = (uv - uw) / uu
		end
	end
	if sc < 0 then
		sc = 0
		tc = if vv > 1e-8 then math.clamp(vw / vv, 0, 1) else 0
	end
	local closest = (origin + u * sc) - (a + v * tc)
	local d2 = closest:Dot(closest)
	if d2 > r * r or sc > range then
		return nil
	end
	-- (entrada en la superficie: un poco antes del punto más cercano)
	return math.max(0, sc - math.sqrt(math.max(r * r - d2, 0)))
end

export type Candidate = { Id: string, Feet: Vector3, Height: number, Radius: number }

-- ¿A cuál le da el rayo? (el más cercano antes de `blocked`, lo que tapa el rayo de verdad)
-- Devuelve (candidato, distancia, ¿cabeza?)
function HitCheck.pick(origin: Vector3, dir: Vector3, range: number, list: { Candidate }, blocked: number?, tolerance: number?): (Candidate?, number?, boolean)
	if dir.Magnitude < 1e-6 then
		return nil, nil, false
	end
	local u = dir.Unit
	local tol = tolerance or HitCheck.Tolerance
	local best, bestD, head = nil, math.huge, false
	local wall = blocked or math.huge
	for _, c in list do
		local r = c.Radius * tol
		local a = c.Feet + Vector3.new(0, math.min(r, c.Height / 2), 0)
		local b = c.Feet + Vector3.new(0, math.max(c.Height - r, c.Height / 2), 0)
		local d = HitCheck.rayCapsule(origin, u, range, a, b, r)
		if d and d < bestD and d <= wall + 0.5 then
			best, bestD = c, d
			local at = origin + u * (d + r * 0.5)
			head = at.Y - c.Feet.Y >= c.Height * HitCheck.HeadShare
		end
	end
	return best, if best then bestD else nil, head
end

-- ¿Vale el punto que manda el cliente? (un número de verdad, delante y no absurdamente lejos)
function HitCheck.sane(origin: Vector3, target: any, range: number): boolean
	if typeof(target) ~= "Vector3" or target ~= target then
		return false
	end
	local d = (target - origin).Magnitude
	return d == d and d < (range + 60) * 4
end

return HitCheck
