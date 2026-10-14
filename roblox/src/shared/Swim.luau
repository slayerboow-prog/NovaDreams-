-- Swim (compartido): las reglas de nadar y bucear, sin nada de Roblox (se prueban en
-- scripts/test-swim.luau). Las usan Controllers/Swimming (el control del cuerpo en el agua),
-- Controllers/AgeMotion (la postura), Controllers/DivingUI (aire y botones) y DivingService (aire).
--
-- Por qué existe: antes se sabía si estabas "bajo el agua" por la altura de la CABEZA. Pero la
-- postura de nadar tumba el cuerpo (la cabeza baja a la altura de la cadera), así que al nadar en la
-- superficie la cabeza quedaba "bajo el agua" → postura de bucear → el cuerpo se ponía de pie → la
-- cabeza salía → otra vez nadar… (el cuerpo daba vueltas y el aire subía y bajaba: 18 s, 20 s…).
-- Ahora todo se mide con el HumanoidRootPart (el centro del cuerpo, que la postura no mueve) y con
-- margen (histéresis) para que no cambie a cada momento. Además, la flotación la lleva el juego: en
-- la superficie te mantiene con la cabeza fuera; buceando, flotabilidad neutra (te quedas a la
-- profundidad a la que estás) y nunca te deja tumbado en el fondo.

local Swim = {}

Swim.Surface = -2 -- altura del agua (mar, río y lagos; igual que Fishing.Dive.Surface y Boats.SeaLevel)

-- Profundidades del centro del cuerpo (HumanoidRootPart) bajo la superficie, en studs de un adulto
-- (se multiplican por la escala del personaje)
Swim.FloatStill = 1.35 -- flotando quieto (de pie en el agua): hombros en la superficie, cabeza fuera
Swim.FloatSwim = 0.55 -- nadando a crol (tumbado): la espalda a ras de agua y la cabeza fuera
Swim.UnderDepth = 2.1 -- más hondo que esto: la cabeza está bajo el agua (se gasta el aire)
Swim.LeaveDepth = 1.6 -- y para volver a "fuera" hay que subir por encima de esto (margen)
Swim.FloorClear = 2.4 -- buceando, el centro del cuerpo no baja de esto sobre el fondo
Swim.Shallow = 4.2 -- agua con menos fondo que esto: se hace pie (andas por el fondo, sin nadar)

-- Velocidades verticales (studs/s)
Swim.DiveSpeed = 9 -- bajando (Bucear)
Swim.RiseSpeed = 10 -- subiendo (Subir)
Swim.FloatSpeed = 6 -- lo más rápido que te lleva la flotación a la superficie
Swim.Accel = 70 -- aceleración vertical máxima que aplica el control (studs/s², además de la gravedad): suave

Swim.CameraClear = 1.2 -- la cámara nunca baja de esto sobre el fondo

export type Mode = "Surface" | "Dive"

-- ¿La cabeza está bajo el agua? (con margen: `was` es lo que era antes)
function Swim.isUnderwater(rootY: number, scale: number, was: boolean?): boolean
	local depth = Swim.Surface - rootY
	local s = math.max(scale, 0.3)
	if was then
		return depth > Swim.LeaveDepth * s
	end
	return depth > Swim.UnderDepth * s
end

-- ¿Hay que nadar aquí? (hay agua y no se hace pie). floorY = nil: sin fondo cerca (alta mar)
function Swim.deepEnough(floorY: number?, scale: number): boolean
	if floorY == nil then
		return true
	end
	return Swim.Surface - floorY >= Swim.Shallow * math.max(scale, 0.3)
end

-- A qué profundidad flota el centro del cuerpo en la superficie (moving 0..1: quieto → nadando)
function Swim.floatY(scale: number, moving: number): number
	local k = math.clamp(moving, 0, 1)
	local depth = Swim.FloatStill + (Swim.FloatSwim - Swim.FloatStill) * k
	return Swim.Surface - depth * math.max(scale, 0.3)
end

export type Step = {
	Mode: Mode, -- lo que estaba haciendo
	RootY: number,
	FloorY: number?, -- el fondo debajo (sin contar el agua); nil si no hay
	Scale: number,
	Input: number, -- -1 bajar, 0 nada, 1 subir (botones, C/Espacio, LT/A)
	Moving: number, -- 0..1: cuánto avanza (para la altura de flotar)
}

-- El modo y la velocidad vertical que quiere el control este momento.
--   Surface: flota con la cabeza fuera (sube suave si estabas hondo: al caer al agua, al soltar Subir).
--   Dive:    solo si pulsas Bucear. Sin tocar nada, flotabilidad neutra (te quedas a esa profundidad).
--            Subir te lleva hacia arriba; al llegar arriba vuelves a Surface.
--   Nunca bajas más que FloorClear sobre el fondo: no te quedas tumbado en la arena.
function Swim.step(s: Step): (Mode, number)
	local scale = math.max(s.Scale, 0.3)
	local mode = s.Mode
	local input = math.clamp(s.Input, -1, 1)
	local float = Swim.floatY(scale, s.Moving)
	if input < 0 then
		mode = "Dive"
	elseif mode == "Dive" and input >= 0 and s.RootY >= float - 0.25 * scale then
		mode = "Surface" -- has llegado arriba
	end
	local vy: number
	if mode == "Surface" then
		-- Muelle suave hacia la altura de flotar (y más rápido si pulsas Subir)
		vy = math.clamp((float - s.RootY) * 4, -Swim.FloatSpeed, if input > 0 then Swim.RiseSpeed else Swim.FloatSpeed)
	elseif input > 0 then
		vy = Swim.RiseSpeed
	elseif input < 0 then
		vy = -Swim.DiveSpeed
	else
		vy = 0 -- flotabilidad neutra
	end
	-- El fondo: no bajar más que FloorClear (y si ya estás más bajo, subir despacio hasta ahí)
	if s.FloorY then
		local lowest = s.FloorY + Swim.FloorClear * scale
		if lowest > float then
			-- Poco fondo para bucear: solo flotar
			lowest = float
			mode = "Surface"
		end
		local guard = (lowest - s.RootY) * 5
		if s.RootY < lowest + 1.5 * scale and vy < guard then
			vy = math.min(guard, Swim.FloatSpeed)
		end
	end
	-- No salir del agua volando: arriba del todo se para (salvo que saltes: eso lo hace Roblox)
	if s.RootY > float and vy > 0 then
		vy = math.min(vy, (float - s.RootY) * 4 + 0.5)
	end
	return mode, vy
end

-- La cámara no se mete en el fondo: si está por debajo de floorY + CameraClear, se acerca al
-- personaje (por la misma línea, así sigue mirándolo) hasta quedar encima; si ni así, sube.
-- Devuelve la posición corregida (o la misma si no hace falta).
function Swim.cameraPosition(camera: Vector3, focus: Vector3, floorY: number?): Vector3
	if floorY == nil then
		return camera
	end
	local minY = floorY + Swim.CameraClear
	if camera.Y >= minY then
		return camera
	end
	if focus.Y > minY + 0.05 then
		local k = (minY - camera.Y) / (focus.Y - camera.Y)
		return camera + (focus - camera) * math.clamp(k, 0, 1)
	end
	return Vector3.new(camera.X, minY, camera.Z)
end

-- La cámara y la superficie del agua: justo en la superficie la imagen se parte en dos (media
-- pantalla dentro, media fuera). Flotando (Surface) la cámara va siempre por encima del agua; buceando
-- (Dive) no se queda en la franja de la superficie. Devuelve la altura corregida.
Swim.CameraBand = 0.45
function Swim.cameraY(y: number, mode: Mode?): number
	local band = Swim.CameraBand
	if mode == "Surface" then
		return math.max(y, Swim.Surface + band)
	elseif mode == "Dive" and math.abs(y - Swim.Surface) < band then
		return if y >= Swim.Surface then Swim.Surface + band else Swim.Surface - band
	end
	return y
end

-- Botones del racimo táctil que sobran nadando (pelear, armas, gestos y agacharse)
Swim.HiddenButtons = {
	Ataque = true,
	Defender = true,
	Esquivar = true,
	Fijar = true,
	Disparar = true,
	DispararIzq = true, -- (el segundo Disparar, junto al joystick)
	Apuntar = true,
	Recargar = true,
	Gestos = true,
	Agacharse = true,
	-- (la pelea con el estilo de combos: CombatController)
	Fuerte = true,
	Cargar = true,
	Poder = true,
	CambiarPoder = true,
	Definitiva = true,
}

return Swim
