-- Arena: el sitio de pruebas del combate aéreo y espacial, lejos de Valmar (cuentas puras).
--
-- Dónde: en el mismo lugar del juego, pero a ~34 000 studs de la ciudad (X = Z = 24 000) y por encima
-- (el suelo de la arena está a Y = 1200): nadie llega andando, en coche ni en avión (el aeroclub tiene su
-- límite en ±5600). La construye AirCombatService la PRIMERA vez que alguien entra (no al arrancar el
-- servidor) y solo la reciben quienes están dentro (ModelStreamingMode PersistentPerPlayer): a un
-- jugador normal no le cuesta nada. Ver docs/combate-aereo.md.
--
--   Atmósfera (abajo): una meseta enorme con agujas de roca; gravedad y suelo.
--   Espacio (arriba, Y >= SpaceY): campo de asteroides, sin gravedad, cielo negro con estrellas.
--   Se pasa de una a otra subiendo o bajando (o reapareciendo en su punto de control).
--
-- El cliente (predicción) y el servidor (comprobación) usan las MISMAS formas (cajas y esferas) para los
-- choques: lo que aquí es una roca, en el mundo es una pieza del mismo tamaño (World/AirArena).

local Arena = {}

Arena.Origin = Vector3.new(24000, 0, 24000)
Arena.GroundY = 1200 -- techo de la meseta
Arena.SpaceY = 3400 -- desde aquí, espacio
Arena.TopY = 6400 -- techo de la arena
Arena.Half = 1800 -- medio lado de la zona de vuelo (X y Z)
Arena.SlabHalf = 2100 -- medio lado de la meseta (algo más que la zona de vuelo)
Arena.Seed = 7

export type Box = { Center: Vector3, Size: Vector3 }
export type Ball = { Center: Vector3, Radius: number }

-- Números pseudoaleatorios repetibles (mismo mapa en el cliente, el servidor y las pruebas)
local function rng(seed: number): () -> number
	local s = seed % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

function Arena.checkpoint(section: string?): CFrame
	local O = Arena.Origin
	if section == "Space" then
		return CFrame.new(O + Vector3.new(0, 4600, 1350))
	end
	return CFrame.new(O + Vector3.new(0, Arena.GroundY + 240, 1350))
end

function Arena.center(section: string?): Vector3
	local O = Arena.Origin
	if section == "Space" then
		return O + Vector3.new(0, 4700, 0)
	end
	return O + Vector3.new(0, Arena.GroundY + 320, 0)
end

function Arena.modeAt(pos: Vector3): string
	return if pos.Y >= Arena.SpaceY then "Space" else "Atmos"
end

-- ¿Dentro de la arena (con margen)? Sirve para saber si alguien está jugando aquí
function Arena.contains(pos: Vector3, margin: number?): boolean
	local m = margin or 0
	local d = pos - Arena.Origin
	return math.abs(d.X) <= Arena.Half + m and math.abs(d.Z) <= Arena.Half + m and pos.Y >= Arena.GroundY - 300 - m and pos.Y <= Arena.TopY + m
end

-- Fuera de la zona de vuelo: hacia dónde volver (unitario); dentro, nil
function Arena.bounds(pos: Vector3): Vector3?
	local d = pos - Arena.Origin
	local back = Vector3.zero
	if d.X > Arena.Half then
		back += Vector3.new(-1, 0, 0)
	elseif d.X < -Arena.Half then
		back += Vector3.new(1, 0, 0)
	end
	if d.Z > Arena.Half then
		back += Vector3.new(0, 0, -1)
	elseif d.Z < -Arena.Half then
		back += Vector3.new(0, 0, 1)
	end
	if pos.Y > Arena.TopY then
		back += Vector3.new(0, -1, 0)
	end
	return if back.Magnitude > 0 then back.Unit else nil
end

local rocksCache: { Box }? = nil
-- Agujas de roca de la meseta (cajas; la primera de cada una es la grande y encima puede ir una torreta)
function Arena.rocks(): { Box }
	if rocksCache then
		return rocksCache
	end
	local r = rng(Arena.Seed * 101)
	local out: { Box } = {}
	local O = Arena.Origin
	local tries = 0
	while #out < 26 and tries < 400 do
		tries += 1
		local x = (r() * 2 - 1) * 1550
		local z = (r() * 2 - 1) * 1550
		local w = 50 + r() * 90
		local d = 50 + r() * 90
		local h = 90 + r() * 360
		-- (nada en el pasillo de salida del punto de control ni en el centro, donde salen los enemigos)
		local lane = math.abs(x) < 220 and z > 700
		local middle = math.abs(x) < 260 and math.abs(z) < 260
		if not lane and not middle then
			local clear = true
			for _, b in out do
				local dx, dz = math.abs(b.Center.X - O.X - x), math.abs(b.Center.Z - O.Z - z)
				if dx < (b.Size.X + w) * 0.5 + 60 and dz < (b.Size.Z + d) * 0.5 + 60 then
					clear = false
					break
				end
			end
			if clear then
				table.insert(out, { Center = O + Vector3.new(x, Arena.GroundY + h * 0.5, z), Size = Vector3.new(w, h, d) })
			end
		end
	end
	rocksCache = out
	return out
end

local asteroidsCache: { Ball }? = nil
function Arena.asteroids(): { Ball }
	if asteroidsCache then
		return asteroidsCache
	end
	local r = rng(Arena.Seed * 977)
	local out: { Ball } = {}
	local O = Arena.Origin
	local cp = Arena.checkpoint("Space").Position
	local center = Arena.center("Space")
	local tries = 0
	while #out < 40 and tries < 600 do
		tries += 1
		local radius = 14 + r() ^ 2 * 70
		local p = O + Vector3.new((r() * 2 - 1) * 1600, 3750 + r() * 2300, (r() * 2 - 1) * 1600)
		local ok = (p - cp).Magnitude > 320 + radius and (p - center).Magnitude > 220 + radius
		if ok then
			for _, b in out do
				if (b.Center - p).Magnitude < b.Radius + radius + 40 then
					ok = false
					break
				end
			end
		end
		if ok then
			table.insert(out, { Center = p, Radius = radius })
		end
	end
	asteroidsCache = out
	return out
end

-- Sitios para las torretas: encima de las rocas más altas (atmósfera) o de los asteroides más grandes
function Arena.turretSpots(section: string?): { Vector3 }
	local out = {}
	if section == "Space" then
		local list = table.clone(Arena.asteroids())
		table.sort(list, function(a, b)
			return a.Radius > b.Radius
		end)
		for i = 1, math.min(6, #list) do
			table.insert(out, list[i].Center + Vector3.new(0, list[i].Radius + 4, 0))
		end
	else
		local list = table.clone(Arena.rocks())
		table.sort(list, function(a, b)
			return a.Size.Y > b.Size.Y
		end)
		for i = 1, math.min(6, #list) do
			local b = list[i]
			table.insert(out, b.Center + Vector3.new(0, b.Size.Y * 0.5 + 5, 0))
		end
	end
	return out
end

local function boxHit(b: Box, pos: Vector3, radius: number): boolean
	local h = b.Size * 0.5
	local c = b.Center
	local q = Vector3.new(math.clamp(pos.X, c.X - h.X, c.X + h.X), math.clamp(pos.Y, c.Y - h.Y, c.Y + h.Y), math.clamp(pos.Z, c.Z - h.Z, c.Z + h.Z))
	return (q - pos).Magnitude <= radius
end

-- ¿Toca algo sólido una esfera en `pos`? Devuelve qué ("el suelo", "una roca", "un asteroide") o nil
function Arena.collide(pos: Vector3, radius: number): string?
	if pos.Y < Arena.SpaceY then
		local d = pos - Arena.Origin
		if pos.Y - radius <= Arena.GroundY and math.abs(d.X) <= Arena.SlabHalf and math.abs(d.Z) <= Arena.SlabHalf then
			return "el suelo"
		end
		if pos.Y - radius <= Arena.GroundY + 460 then
			for _, b in Arena.rocks() do
				if boxHit(b, pos, radius) then
					return "una roca"
				end
			end
		end
	end
	if pos.Y + radius >= 3650 then
		for _, a in Arena.asteroids() do
			if (a.Center - pos).Magnitude <= a.Radius + radius then
				return "un asteroide"
			end
		end
	end
	return nil
end

-- ¿Choca un proyectil que va de a a b? (se mira por pasos: los proyectiles van rápido)
function Arena.segmentBlocked(a: Vector3, b: Vector3): boolean
	local len = (b - a).Magnitude
	local steps = math.clamp(math.ceil(len / 20), 1, 40)
	for i = 1, steps do
		if Arena.collide(a:Lerp(b, i / steps), 0.5) then
			return true
		end
	end
	return false
end

return Arena
