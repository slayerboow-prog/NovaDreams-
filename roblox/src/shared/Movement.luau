-- Movement: reglas de agacharse, tumbarse y saltar obstáculos (parkour). Funciones puras: las usan el
-- cliente (Controllers/Stances y Controllers/Parkour) y el servidor (ActionService valida la postura,
-- WantedService la usa para los testigos). Se prueban en scripts/test-parkour.luau.
--
--   Postura (atributo "Stance" del jugador): "Stand" de pie, "Crouch" agachado, "Prone" tumbado.
--   Obstáculos (classify): "Speed" (valla o barandilla: una mano y las piernas de lado),
--   "Kong" (muro bajo y ancho, corriendo: las dos manos y las piernas recogidas), "Climb" (muro de
--   4,5 a 7 studs, o bajo y ancho sin carrerilla: se sube y se baja por el otro lado) y "Ledge"
--   (un borde con sitio encima: se sube y se queda arriba).

local Movement = {}

local clamp, sqrt, acos, atan2 = math.clamp, math.sqrt, math.acos, math.atan2

---------------------------------------------------------------------
-- Posturas
---------------------------------------------------------------------
Movement.Stances = { Stand = true, Crouch = true, Prone = true }
-- Velocidad respecto a andar (Controllers/Locomotion la aplica; agachado nunca pasa de andar, aunque
-- lleves Shift pulsado: no hay "correr agachado")
Movement.Speed = { Stand = 1, Crouch = 0.45, Prone = 0.25 }
Movement.Witness = { Stand = 1, Crouch = 0.5, Prone = 0.5 } -- radio de los testigos (más discreto)
Movement.Transition = { Stand = 0.3, Crouch = 0.3, Prone = 0.45 } -- segundos para llegar a esa postura
Movement.HoldToProne = 0.5 -- mantener la tecla de agacharse este tiempo = tumbarse
Movement.MaxProneSlope = 25 -- grados: en cuestas más empinadas no se puede tumbar
-- Agachado, la cadera baja esta parte de lo que mide la pierna (cadera a tobillo): rodillas a ~95°,
-- muslo a ~50° (Stances lo usa a la vez para la HipHeight y para doblar las piernas: los pies no se
-- hunden ni flotan con ningún tamaño de personaje)
Movement.CrouchDepth = 0.34

function Movement.speedFactor(stance: any): number
	return Movement.Speed[stance] or 1
end

function Movement.witnessFactor(stance: any): number
	return Movement.Witness[stance] or 1
end

export type StanceContext = {
	Stage: string?,
	Crawling: boolean?,
	Riding: boolean?,
	Seated: boolean?,
	Swimming: boolean?,
	Dead: boolean?,
	KO: boolean?,
	Climbing: boolean?, -- en una escalera de mano (solo lo sabe el cliente)
	Ragdoll: boolean?, -- sin control del cuerpo (PlatformStand, caído)
	Busy: boolean?, -- en una escena, entrenando…: la postura la pone otro sistema
}

-- ¿Puede ponerse en esa postura ahora? (el servidor lo comprueba; de pie siempre se puede)
function Movement.allowed(stance: any, ctx: StanceContext): (boolean, string?)
	if type(stance) ~= "string" or not Movement.Stances[stance] then
		return false, "Postura desconocida"
	end
	if stance == "Stand" then
		return true, nil
	end
	-- (siempre con un porqué: el jugador nunca pulsa y no pasa nada sin saber la razón)
	if ctx.Dead then
		return false, "Ahora no te puedes agachar."
	elseif ctx.KO then
		return false, "💫 Estás aturdido: espera a recuperarte."
	elseif ctx.Ragdoll then
		return false, "Primero levántate del suelo."
	elseif ctx.Busy then
		return false, "Ahora no te puedes agachar (estás en una escena o entrenando)."
	elseif ctx.Stage == "Bebe" or ctx.Crawling then
		return false, "👶 Los bebés ya van a gatas."
	elseif ctx.Riding or ctx.Seated then
		return false, "🪑 Primero levántate o bájate del vehículo."
	elseif ctx.Swimming then
		return false, "🌊 En el agua no te puedes agachar."
	elseif ctx.Climbing then
		return false, "🪜 Primero baja de la escalera."
	end
	return true, nil
end

-- Pierna flexionada para bajar la cadera `drop` studs con los pies en su sitio (IK de dos huesos).
-- thigh = muslo (cadera a rodilla), shin = espinilla (rodilla a tobillo). Devuelve los ángulos X de
-- cadera (>0 muslo adelante), rodilla (<0 dobla) y tobillo (pie plano en el suelo).
function Movement.crouchLegs(drop: number, thigh: number, shin: number): (number, number, number)
	local full = thigh + shin
	local d = clamp(full - math.max(drop, 0), math.abs(thigh - shin) + 0.05, full)
	local cosKnee = clamp((thigh * thigh + shin * shin - d * d) / (2 * thigh * shin), -1, 1)
	local knee = math.pi - acos(cosKnee) -- cuánto se dobla (0 = recta)
	local cosHip = clamp((thigh * thigh + d * d - shin * shin) / (2 * thigh * d), -1, 1)
	local hip = acos(cosHip)
	return hip, -knee, knee - hip
end

-- Inclinación del cuerpo tumbado para seguir la cuesta: normal del suelo y hacia dónde mira.
-- pitch > 0: la cabeza sube (cuesta arriba delante); roll > 0: el lado derecho sube.
function Movement.slopeAngles(normal: Vector3, look: Vector3): (number, number)
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-4 or normal.Magnitude < 1e-4 then
		return 0, 0
	end
	local f = flat.Unit
	local r = f:Cross(Vector3.new(0, 1, 0))
	local n = normal.Unit
	return atan2(-n:Dot(f), n.Y), atan2(-n:Dot(r), n.Y)
end

-- Grados de la cuesta (0 = llano)
function Movement.slopeDegrees(normal: Vector3): number
	if normal.Magnitude < 1e-4 then
		return 90
	end
	return math.deg(acos(clamp(normal.Unit.Y, -1, 1)))
end

---------------------------------------------------------------------
-- Obstáculos
---------------------------------------------------------------------
export type Obstacle = {
	Height: number, -- de los pies a lo alto del obstáculo
	Depth: number, -- lo que mide de grueso en la dirección en que vas (math.huge = sigue: es un borde)
	Drop: number?, -- cuánto más bajo está el suelo del otro lado que tus pies (+ = más bajo)
	Clear: boolean?, -- hay sitio para caer del otro lado (y encima, para pasar)
	Speed: number?, -- velocidad al llegar (studs/s)
	Scale: number?, -- tamaño del personaje (niños más pequeños)
	Stage: string?,
}

Movement.KongSpeed = 17 -- corriendo a partir de esta velocidad, los muros anchos se saltan con las dos manos
Movement.MaxDrop = 14 -- del otro lado no se salta a un vacío más alto que esto
Movement.RollDrop = 5 -- cayendo más de esto, voltereta al aterrizar

-- Qué salto toca (nil = ninguno: salto normal)
function Movement.classify(o: Obstacle): string?
	local s = math.max(o.Scale or 1, 0.3)
	local h = o.Height / s
	local depth = o.Depth / s
	local stage = o.Stage
	if stage == "Bebe" or h < 1.5 or h > 9.5 then
		return nil
	end
	local over = depth < 5 -- se puede pasar al otro lado
	if over and (o.Clear == false or (o.Drop or 0) / s > Movement.MaxDrop) then
		-- No hay dónde caer: si arriba cabe, se sube y se queda; si no, nada
		over = false
		if depth < 1.5 then
			return nil
		end
	end
	local old = stage == "Mayor"
	local kid = stage == "Nino"
	if h <= 4.5 and over then
		if depth <= 2.5 then
			return if old and h > 3 then "Climb" else "Speed"
		end
		if (o.Speed or 0) >= Movement.KongSpeed and not old and not kid then
			return "Kong"
		end
		return "Climb"
	end
	if h <= 7 and over then
		return if old then nil else "Climb"
	end
	-- Un borde con sitio encima (o un muro alto): subir y quedarse arriba
	if not over and depth >= 1.5 and not (old and h > 5) then
		return "Ledge"
	end
	return nil
end

-- Cuánto dura cada salto (segundos), según la altura
function Movement.duration(kind: string, height: number, scale: number?): number
	local h = height / math.max(scale or 1, 0.3)
	if kind == "Speed" then
		return 0.5 + h * 0.03
	elseif kind == "Kong" then
		return 0.6
	elseif kind == "Climb" then
		return 0.75 + h * 0.07
	elseif kind == "Ledge" then
		return 0.45 + h * 0.06
	end
	return 0.5
end

-- Puntos por los que pasa la cadera (HumanoidRootPart) durante el salto:
--   from = donde empieza, edge = el borde cercano en lo alto del obstáculo, far = el borde lejano
--   (lo alto), land = donde acaba (ya de pie), rootHeight = altura de la cadera sobre los pies
function Movement.path(kind: string, from: Vector3, edge: Vector3, far: Vector3, land: Vector3, rootHeight: number): { Vector3 }
	local H = rootHeight
	local mid = (edge + far) / 2
	if kind == "Speed" then
		local apex = Vector3.new(mid.X, edge.Y + H * 0.62, mid.Z)
		return { from, apex, land }
	elseif kind == "Kong" then
		local apex = Vector3.new(mid.X, edge.Y + H * 0.55, mid.Z)
		return { from, apex, land }
	end
	-- Climb (pasar por encima) y Ledge (subir y quedarse): colgado del borde, sube por encima del borde
	-- (la cadera bien por encima: sin atravesar la esquina) y luego baja o se pone de pie arriba
	local toward = Vector3.new(far.X - edge.X, 0, far.Z - edge.Z)
	if toward.Magnitude < 1e-3 then
		toward = Vector3.new(land.X - edge.X, 0, land.Z - edge.Z)
	end
	toward = if toward.Magnitude > 1e-3 then toward.Unit else Vector3.zero
	local hang = Vector3.new(edge.X, edge.Y + H * 0.2, edge.Z) - toward * 0.9 -- colgado del borde
	local lip = Vector3.new(edge.X, edge.Y + H * 0.8, edge.Z) + toward * 0.5 -- rodilla arriba, encima del borde
	if kind == "Ledge" then
		return { from, hang, lip, land }
	end
	local points = { from, hang, lip }
	local rest = Vector3.new(far.X, edge.Y + H * 0.8, far.Z) - toward * 0.3 -- agachado encima, al otro borde
	if (rest - lip).Magnitude > 0.8 then
		table.insert(points, rest)
	end
	table.insert(points, land)
	return points
end

-- Posición en el camino (t 0..1). Pasa por todos los puntos, sin saltos ni esquinas (Catmull-Rom),
-- y cada tramo dura según lo largo que es (velocidad pareja).
function Movement.sample(points: { Vector3 }, t: number): Vector3
	local n = #points
	if n == 0 then
		return Vector3.zero
	elseif n == 1 then
		return points[1]
	end
	t = clamp(t, 0, 1)
	local lengths, total = {}, 0
	for i = 1, n - 1 do
		local l = math.max((points[i + 1] - points[i]).Magnitude, 1e-3)
		lengths[i] = l
		total += l
	end
	local goal = t * total
	local i = 1
	while i < n - 1 and goal > lengths[i] do
		goal -= lengths[i]
		i += 1
	end
	local u = clamp(goal / lengths[i], 0, 1)
	local p0 = points[math.max(i - 1, 1)]
	local p1 = points[i]
	local p2 = points[i + 1]
	local p3 = points[math.min(i + 2, n)]
	-- Tangentes (en los extremos, hacia el siguiente punto)
	local m1 = (p2 - p0) * 0.5
	local m2 = (p3 - p1) * 0.5
	local u2, u3 = u * u, u * u * u
	return p1 * (2 * u3 - 3 * u2 + 1) + m1 * (u3 - 2 * u2 + u) + p2 * (-2 * u3 + 3 * u2) + m2 * (u3 - u2)
end

-- Tiempo del salto: arranca con la velocidad que traías y se posa suave al final
function Movement.timeCurve(t: number): number
	local x = clamp(t, 0, 1)
	return x + 0.35 * x * x * (1 - x) -- (empieza a la velocidad de antes y acaba algo más despacio)
end

-- Distancia en el suelo (sin la altura) entre dos puntos
function Movement.flatDistance(a: Vector3, b: Vector3): number
	local d = a - b
	return sqrt(d.X * d.X + d.Z * d.Z)
end

return Movement
