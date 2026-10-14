-- PlanetBodies: los 7 planetas como CUERPOS de verdad en el espacio encima de Valmar (cuentas puras;
-- docs/planetas.md). Planets.luau dice quiénes son (nombre, episodio, color, estado); aquí está DÓNDE
-- están, lo GRANDES que son y cómo se dibujan desde lejos y desde cerca.
--
--   * Cada planeta tiene su centro de verdad (Center) fuera de la columna del espacio (±7000), a unos
--     11 000 – 13 000 studs del eje de Valmar, y su radio (Radius, 2000 – 3000). Desde una estación
--     se ven ENORMES en el cielo; de muy lejos (desde Valmar de noche), como una estrella.
--   * Capas de cada planeta, de fuera a dentro:
--       Approach = Radius + ApproachDepth   aquí ya se puede volar fuera de la columna (Zone.bounds)
--       Entry    = Radius + EntryDepth      empieza la ENTRADA EN LA ATMÓSFERA (PlanetEntry)
--       Reloc    = Radius + RelocDepth      a esta altura la nave pasa (escondida en las nubes) a la
--                                           superficie del planeta (shared/Cosmos/Tefra)
--   * Dibujar (cliente): Roblox no deja piezas de más de 2048 studs y lo muy lejano se ve mal, así que
--     el planeta se dibuja como un «impostor»: una esfera más cerca de la cámara y más pequeña, con
--     el MISMO tamaño en pantalla (PlanetBodies.view). Lejos (menos de StarPx de radio en pantalla)
--     sale la estrella de siempre; al acercarte, la estrella se apaga y crece la esfera con su textura.

local PlanetBodies = {}

export type Body = {
	Id: string,
	Center: Vector3,
	Radius: number,
	Spin: number, -- °/s que gira la textura (lento)
	Tilt: number, -- grados de inclinación del eje
	Halo: Color3, -- color del aro de la atmósfera
	Ground: Color3, -- color de respaldo (sin textura subida)
	Band: Color3, -- segundo color de respaldo (nubes, casquetes)
	Clouds: boolean, -- tiene capa de nubes
}

local rgb = Color3.fromRGB

PlanetBodies.Hub = Vector3.new(0, 6200, 0) -- el centro del espacio (para colocar los planetas)
PlanetBodies.ApproachDepth = 2600
PlanetBodies.EntryDepth = 900
PlanetBodies.RelocDepth = 150
PlanetBodies.StarPx = 9 -- radio en pantalla (px) por debajo del cual se ve como estrella
PlanetBodies.BodyPx = 22 -- y por encima, solo la esfera (entre medias, las dos fundidas)
PlanetBodies.DrawMax = 1500 -- distancia máxima a la que se dibuja la esfera impostora
PlanetBodies.PartMax = 1000 -- radio máximo de la esfera impostora (piezas de Roblox ≤ 2048)
PlanetBodies.HaloScale = 1.25 -- el aro (imagen halo_atmosfera: el planeta ocupa el 80 % de su ancho)

-- (acimut desde -Z hacia +X en grados, distancia horizontal al eje, altura, radio)
local ORBITS = {
	Tefra = { 20, 11000, 7200, 2400, 0.6, 18, rgb(255, 190, 225), rgb(176, 150, 164), rgb(226, 220, 232), true },
	Siroco = { 70, 12500, 6400, 2800, 0.3, 8, rgb(255, 140, 80), rgb(196, 92, 48), rgb(232, 170, 104), false },
	Talasa = { 125, 12000, 7600, 2600, 0.5, 24, rgb(100, 240, 240), rgb(20, 110, 140), rgb(230, 245, 255), true },
	Nivalis = { 185, 11500, 8200, 2000, 0.25, 12, rgb(180, 215, 255), rgb(36, 52, 92), rgb(214, 232, 250), false },
	Umbria = { 240, 12000, 6000, 2700, 0.45, 15, rgb(150, 255, 140), rgb(36, 110, 48), rgb(220, 200, 110), true },
	Miasma = { 295, 13000, 7400, 3000, 0.9, 26, rgb(230, 160, 255), rgb(214, 130, 120), rgb(140, 80, 190), false },
	Vertice = { 340, 11800, 8400, 2200, 0.35, 5, rgb(255, 235, 130), rgb(214, 218, 228), rgb(255, 120, 200), false },
}
PlanetBodies.Order = { "Tefra", "Siroco", "Talasa", "Nivalis", "Umbria", "Miasma", "Vertice" }

PlanetBodies.List = {} :: { Body }
PlanetBodies.ById = {} :: { [string]: Body }
for _, id in PlanetBodies.Order do
	local o = ORBITS[id]
	local a = math.rad(o[1])
	local center = Vector3.new(math.sin(a) * o[2], o[3], -math.cos(a) * o[2])
	local b: Body = { Id = id, Center = center, Radius = o[4], Spin = o[5], Tilt = o[6], Halo = o[7], Ground = o[8], Band = o[9], Clouds = o[10] }
	table.insert(PlanetBodies.List, b)
	PlanetBodies.ById[id] = b
end

function PlanetBodies.entryRadius(b: Body): number
	return b.Radius + PlanetBodies.EntryDepth
end

function PlanetBodies.relocRadius(b: Body): number
	return b.Radius + PlanetBodies.RelocDepth
end

function PlanetBodies.approachRadius(b: Body): number
	return b.Radius + PlanetBodies.ApproachDepth
end

-- El planeta en cuya zona de llegada estás (para dejar volar fuera de la columna), o nil
function PlanetBodies.approachAt(pos: Vector3, margin: number?): Body?
	for _, b in PlanetBodies.List do
		if (pos - b.Center).Magnitude <= PlanetBodies.approachRadius(b) + (margin or 0) then
			return b
		end
	end
	return nil
end

-- El planeta más cercano (su superficie) y la distancia a ella
function PlanetBodies.nearest(pos: Vector3): (Body, number)
	local best, bestD = PlanetBodies.List[1], math.huge
	for _, b in PlanetBodies.List do
		local d = (pos - b.Center).Magnitude - b.Radius
		if d < bestD then
			best, bestD = b, d
		end
	end
	return best, bestD
end

-- Altura sobre la superficie del planeta
function PlanetBodies.altitude(b: Body, pos: Vector3): number
	return (pos - b.Center).Magnitude - b.Radius
end

-- Dirección desde `from` hacia el planeta (unitaria)
function PlanetBodies.direction(b: Body, from: Vector3): Vector3
	local d = b.Center - from
	return if d.Magnitude > 1e-6 then d.Unit else Vector3.new(0, 1, 0)
end

-- Radio angular (rad) del planeta visto desde `from`
function PlanetBodies.angularRadius(b: Body, from: Vector3): number
	local d = (b.Center - from).Magnitude
	if d <= b.Radius then
		return math.pi / 2
	end
	return math.asin(b.Radius / d)
end

-- Radio en pantalla (px) para un campo de visión vertical (grados) y una altura de pantalla (px)
function PlanetBodies.screenRadius(angular: number, fovDeg: number, viewportY: number): number
	local half = math.rad(fovDeg) / 2
	return math.tan(math.min(angular, math.rad(89))) / math.tan(half) * viewportY / 2
end

export type View = {
	Dir: Vector3, -- hacia el centro del planeta
	Distance: number, -- distancia de verdad al centro
	Angular: number, -- radio angular (rad)
	DrawDistance: number, -- a qué distancia de la cámara va la esfera impostora
	DrawRadius: number, -- y su radio (mismo tamaño en pantalla que el planeta de verdad)
	Star: number, -- 0..1 cuánto se ve la estrella
	Body: number, -- 0..1 cuánto se ve la esfera
	Px: number, -- radio en pantalla (px)
}

-- Cómo se dibuja el planeta desde la cámara: dirección, esfera impostora y fundido estrella/esfera.
-- Mismo tamaño en pantalla: DrawRadius / DrawDistance = Radius / Distance (y la esfera nunca toca la
-- cámara: su borde cercano queda a DrawDistance · (1 − Radius/Distance) > 0).
function PlanetBodies.view(b: Body, cam: Vector3, fovDeg: number?, viewportY: number?): View
	local offset = b.Center - cam
	local dist = math.max(offset.Magnitude, b.Radius + 1)
	local dir = if offset.Magnitude > 1e-6 then offset.Unit else Vector3.new(0, 1, 0)
	local ratio = b.Radius / dist
	local drawDist = math.min(PlanetBodies.DrawMax, dist, PlanetBodies.PartMax * 0.98 / ratio)
	local drawRadius = drawDist * ratio
	local angular = math.asin(math.clamp(ratio, 0, 1))
	local px = PlanetBodies.screenRadius(angular, fovDeg or 70, viewportY or 720)
	local body = math.clamp((px - PlanetBodies.StarPx) / (PlanetBodies.BodyPx - PlanetBodies.StarPx), 0, 1)
	return {
		Dir = dir,
		Distance = dist,
		Angular = angular,
		DrawDistance = drawDist,
		DrawRadius = drawRadius,
		Star = 1 - body,
		Body = body,
		Px = px,
	}
end

-- ¿A qué planeta apunta el morro (desde `pos`)? El cono es el tamaño del planeta más un margen.
function PlanetBodies.aimed(pos: Vector3, look: Vector3, cone: number?): Body?
	local best, bestA = nil, math.huge
	for _, b in PlanetBodies.List do
		local dir = PlanetBodies.direction(b, pos)
		local a = math.acos(math.clamp(look.Unit:Dot(dir), -1, 1))
		local limit = PlanetBodies.angularRadius(b, pos) + (cone or math.rad(4))
		if a <= limit and a < bestA then
			best, bestA = b, a
		end
	end
	return best
end

-- Para los planetas CERRADOS (próximamente, o sin la Saga 1): hacia dónde apartar la nave si se mete
-- en su atmósfera (unitario, hacia fuera), o nil. open(id) dice si está abierto para ti.
function PlanetBodies.repel(pos: Vector3, open: ((string) -> boolean)?): Vector3?
	for _, b in PlanetBodies.List do
		local off = pos - b.Center
		if off.Magnitude < PlanetBodies.entryRadius(b) + 200 and not (open and open(b.Id)) then
			return if off.Magnitude > 1 then off.Unit else Vector3.new(0, 1, 0)
		end
	end
	return nil
end

return PlanetBodies
