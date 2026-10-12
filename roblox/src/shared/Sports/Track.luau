-- Track (compartido): una recta de atletismo pintada sobre una pista o un campo del mapa, en
-- coordenadas de la recta: X a lo largo (salida en x = 0, meta en x = Length), Z a lo ancho (calles),
-- Y arriba. Y el modelo de la zancada: correr de verdad es pulsar Izquierda y Derecha alternando;
-- cuanto más rápido (y sin repetir pie), más velocidad; a tope se gasta el aliento.
-- Se prueba en scripts/test-atletismo.luau.

local Track = {}

export type Track = {
	Id: string,
	CFrame: CFrame, -- la línea de salida, en el centro de las calles (X = hacia la meta)
	Length: number,
	Lanes: number,
	LaneWidth: number,
}

function Track.new(cf: CFrame, length: number, lanes: number, laneWidth: number?, id: string?): Track
	return { Id = id or "Recta", CFrame = cf, Length = length, Lanes = lanes, LaneWidth = laneWidth or 3.2 }
end

-- Centro de la calle `lane` (1..Lanes), a ras de suelo, a la distancia x
function Track.lanePoint(t: Track, lane: number, x: number): Vector3
	local z = (lane - (t.Lanes + 1) / 2) * t.LaneWidth
	return Vector3.new(x, 0, z)
end

function Track.toLocal(t: Track, world: Vector3): Vector3
	return t.CFrame:PointToObjectSpace(world)
end
function Track.toWorld(t: Track, loc: Vector3): Vector3
	return t.CFrame:PointToWorldSpace(loc)
end
function Track.dirToWorld(t: Track, loc: Vector3): Vector3
	return t.CFrame:VectorToWorldSpace(loc)
end

-- Una recta encima de una pieza (campo, pista): a lo largo de su lado más largo, centrada
function Track.fromPart(part: any, lanes: number, maxLength: number?, id: string?): Track
	local size = part.Size
	local alongX = size.X >= size.Z
	local top = part.CFrame * CFrame.new(0, size.Y / 2, 0)
	local axis = if alongX then top.RightVector else top.LookVector
	axis = Vector3.new(axis.X, 0, axis.Z)
	axis = if axis.Magnitude > 1e-3 then axis.Unit else Vector3.new(1, 0, 0)
	local long = if alongX then size.X else size.Z
	local length = math.min(long - 10, maxLength or 70)
	local start = top.Position - axis * (length / 2)
	return Track.new(CFrame.fromMatrix(start, axis, Vector3.new(0, 1, 0)), length, lanes, 3.2, id)
end

---------------------------------------------------------------------
-- La zancada
---------------------------------------------------------------------

export type Stride = {
	Speed: number, -- velocidad ahora (studs/s)
	Last: string?, -- último pie ("L" / "R")
	Taps: { number }, -- tiempos de las últimas pulsaciones buenas
	Stamina: number, -- 0..1
	Stumble: number, -- hasta cuándo va a trompicones (repetiste pie)
}

Track.Stride = {
	Walk = 16, -- se multiplica por la escala de velocidad (la WalkSpeed del personaje / 16)
	Base = 0.45, -- sin pulsar nada se va parando hasta aquí (fracción de Walk) si ya corría
	PerHz = 0.17, -- cada pulsación por segundo suma esto (fracción de Walk)
	Max = 1.55, -- tope (fracción de Walk)
	Tired = 1.2, -- por encima de esto se gasta el aliento
	Drain = 0.22, -- aliento por segundo a tope
	Regen = 0.12,
	Window = 1.1, -- las pulsaciones de este último rato cuentan para la cadencia
}
local S = Track.Stride

function Track.newStride(): Stride
	return { Speed = 0, Last = nil, Taps = {}, Stamina = 1, Stumble = 0 }
end

-- Una pulsación de pie ("L" o "R") en el instante `now`. Repetir el mismo pie hace trastabillar.
function Track.tap(st: Stride, foot: string, now: number)
	if st.Last == foot then
		st.Stumble = now + 0.25
		st.Taps = {}
		return
	end
	st.Last = foot
	table.insert(st.Taps, now)
	while #st.Taps > 12 do
		table.remove(st.Taps, 1)
	end
end

-- Cadencia (pulsaciones buenas por segundo) en la ventana
function Track.cadence(st: Stride, now: number): number
	local n = 0
	for _, t in st.Taps do
		if now - t <= S.Window then
			n += 1
		end
	end
	return n / S.Window
end

-- Avanza la zancada dt segundos: devuelve la velocidad (studs/s). speedScale: WalkSpeed / 16
function Track.stepStride(st: Stride, now: number, dt: number, speedScale: number?): number
	local walk = S.Walk * (speedScale or 1)
	local hz = Track.cadence(st, now)
	local want = if hz > 0 then walk * math.min(S.Max, S.Base + hz * S.PerHz) else 0
	if st.Stamina <= 0.05 then
		want = math.min(want, walk * 0.95) -- sin aliento: ya no se puede esprintar
	end
	if now < st.Stumble then
		want *= 0.4
	end
	-- Acelera y frena con suavidad
	local rate = if want > st.Speed then 2.2 else 3
	st.Speed += (want - st.Speed) * math.min(1, dt * rate)
	if st.Speed > walk * S.Tired then
		st.Stamina = math.max(0, st.Stamina - S.Drain * dt)
	else
		st.Stamina = math.min(1, st.Stamina + S.Regen * dt)
	end
	return st.Speed
end

return Track
