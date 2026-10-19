-- Ambient: la vida GRANDE y lejana del mar enorme (v120, vídeo de referencia del dueño), en reglas puras
-- (sin Roblox salvo Vector3). La dibuja Controllers/SeaAmbient, solo en tu pantalla; lo prueba test-mar.
-- docs/mar/diseno.md («Mar enorme»).
--
--   * Gigantes que pasan a lo lejos entre la bruma: ballenas, mantas gigantes y, muy de vez en cuando
--     en lo hondo, el leviatán (una serpiente marina larguísima y tranquila, con puntos de luz). Pasan
--     de largo en línea recta, sin chocar con nada y sin acercarse a ti: son paisaje, no enemigos.
--   * Campos de medusas que brillan (Ocean.JellyFields): muchas medusas rosas, cian y violetas que suben
--     y bajan despacio. Cada una se mueve con una cuenta (sin física): siempre en su campo.
--   * Topes (Caps): pocas piezas en el móvil; lo lejano se quita (Cull).

local Shared = game:GetService("ReplicatedStorage").Shared
local Ocean = require(Shared.Sea.Ocean)

local Ambient = {}

local V = Vector3.new
local sin, cos, sqrt, min, max = math.sin, math.cos, math.sqrt, math.min, math.max

-- Topes por aparato: medusas a la vez, gigantes a la vez y piezas en total de SeaAmbient
Ambient.Caps = {
	Mobile = { Jellies = 20, Giants = 1, Parts = 70, FieldReach = 220 },
	Desktop = { Jellies = 44, Giants = 2, Parts = 150, FieldReach = 320 },
}
Ambient.JellyParts = 2 -- campana y tentáculos (un trozo)
-- Cada cuánto (s) se intenta que pase un gigante
Ambient.Every = { Mobile = 22, Desktop = 14 }

-- Los gigantes: dónde salen (zonas), a qué distancia de ti pasan (studs), velocidad, tamaño y piezas
Ambient.Giants = {
	Whale = {
		Name = "Ballena",
		Zones = { Llanura = 3, Talud = 3, Catedrales = 2, Abismo = 2, Arrecife = 1, Kelp = 1, Orilla = 0 },
		Distance = { 120, 210 },
		Speed = 9,
		Length = 80,
		Height = 16, -- alto del cuerpo (para no meterse en el fondo ni asomar por la superficie)
		Parts = 8,
		MinWater = 40, -- agua (studs) que hace falta entre el fondo y la superficie
	},
	Manta = {
		Name = "Manta gigante",
		Zones = { Arrecife = 3, Llanura = 2, Talud = 2, Garganta = 2, Catedrales = 2, Kelp = 0, Orilla = 0 },
		Distance = { 60, 130 },
		Speed = 7,
		Length = 30,
		Height = 4,
		Parts = 4,
		MinWater = 20,
	},
	Leviathan = {
		Name = "Leviatán",
		Zones = { Abismo = 1, Catedrales = 1, Garganta = 1 },
		Distance = { 170, 260 },
		Speed = 12,
		Length = 220,
		Height = 14,
		Parts = 16,
		MinWater = 80,
	},
}
Ambient.GiantOrder = { "Whale", "Manta", "Leviathan" }

function Ambient.caps(mobile: boolean): { [string]: number }
	return if mobile then Ambient.Caps.Mobile else Ambient.Caps.Desktop
end

-- Qué gigante toca en una zona (r: 0..1 al azar). nil = ninguno (zona sin gigantes)
function Ambient.pickGiant(zone: string?, r: number): string?
	if not zone then
		return nil
	end
	local total = 0
	for _, id in Ambient.GiantOrder do
		total += Ambient.Giants[id].Zones[zone] or 0
	end
	if total <= 0 then
		return nil
	end
	local x = r * total
	for _, id in Ambient.GiantOrder do
		x -= Ambient.Giants[id].Zones[zone] or 0
		if x <= 0 then
			return id
		end
	end
	return Ambient.GiantOrder[#Ambient.GiantOrder]
end

-- El paso de un gigante: una recta que cruza por delante de ti a `Distance` studs, de un lado a otro,
-- siempre en el agua (entre el fondo más alto del camino + su alto y la superficie - su alto).
-- look: hacia dónde miras (para que pase por delante). r1..r3: 0..1 al azar. floorAt(x, z): el fondo.
-- Devuelve nil si ahí no cabe (poca agua).
export type Path = { Kind: string, From: Vector3, To: Vector3, Speed: number, Duration: number, Y: number }
function Ambient.path(kind: string, cam: Vector3, look: Vector3, r1: number, r2: number, r3: number, floorAt: ((number, number) -> number?)?): Path?
	local def = Ambient.Giants[kind]
	if not def then
		return nil
	end
	local floorFn = floorAt or Ocean.floorY
	local flat = V(look.X, 0, look.Z)
	if flat.Magnitude < 0.05 then
		flat = V(0, 0, -1)
	end
	flat = flat.Unit
	local side = V(-flat.Z, 0, flat.X)
	local d = def.Distance[1] + (def.Distance[2] - def.Distance[1]) * r1
	-- por delante (algo ladeado) y de un lado a otro
	local ahead = (flat * cos((r2 - 0.5) * 1.2) + side * sin((r2 - 0.5) * 1.2)).Unit
	local mid = V(cam.X, 0, cam.Z) + ahead * d
	local across = V(-ahead.Z, 0, ahead.X) * (if r3 > 0.5 then 1 else -1)
	local half = max(160, def.Length * 2)
	local from, to = mid - across * half, mid + across * half
	-- el fondo más alto del camino
	local highest = -math.huge
	for k = 0, 6 do
		local p = from:Lerp(to, k / 6)
		local f = floorFn(p.X, p.Z)
		if f == nil then
			return nil -- (pasa por tierra)
		end
		highest = max(highest, f)
	end
	-- (con el vaivén de Ambient.at: ±3)
	local top = Ocean.Surface - 6 - def.Height - 3
	local bottom = highest + def.Height + 8 + 3
	if top - bottom < def.MinWater * 0.25 or (Ocean.Surface - highest) < def.MinWater then
		return nil
	end
	-- a tu altura si se puede (se ve mejor), dentro de lo que cabe
	local y = math.clamp(cam.Y + (r1 - 0.5) * 30, bottom, top)
	from, to = V(from.X, y, from.Z), V(to.X, y, to.Z)
	return { Kind = kind, From = from, To = to, Speed = def.Speed, Duration = (to - from).Magnitude / def.Speed, Y = y }
end

-- Dónde está un gigante a los `t` segundos de su paso (y hacia dónde mira). Un vaivén suave arriba y abajo.
function Ambient.at(p: Path, t: number): (Vector3, Vector3)
	local k = math.clamp(t / p.Duration, 0, 1)
	local dir = (p.To - p.From).Unit
	local pos = p.From:Lerp(p.To, k) + V(0, sin(t * 0.25) * 2.5, 0)
	return pos, dir
end

-- ¿Se quita? (ya pasó, o se ha quedado muy lejos porque te has movido)
function Ambient.done(p: Path, t: number, cam: Vector3): boolean
	if t >= p.Duration then
		return true
	end
	local pos = Ambient.at(p, t)
	local def = Ambient.Giants[p.Kind]
	return (pos - cam).Magnitude > def.Distance[2] + def.Length * 2 + 200
end

---------------------------------------------------------------------
-- Campos de medusas
---------------------------------------------------------------------
-- Los campos al alcance (más cerca que reach del borde del campo), del más cercano al más lejano
function Ambient.fieldsNear(pos: Vector3, reach: number): { any }
	local list = {}
	for _, f in Ocean.JellyFields do
		local d = sqrt((pos.X - f.X) ^ 2 + (pos.Z - f.Z) ^ 2) - f.R
		if d < reach then
			table.insert(list, { Field = f, D = d })
		end
	end
	table.sort(list, function(a, b)
		return a.D < b.D
	end)
	local out = {}
	for _, e in list do
		table.insert(out, e.Field)
	end
	return out
end

local JELLY_COLORS = {
	Color3.fromRGB(255, 110, 200), -- rosa
	Color3.fromRGB(90, 230, 255), -- cian
	Color3.fromRGB(170, 110, 255), -- violeta
	Color3.fromRGB(120, 255, 210), -- verde agua
}
Ambient.JellyColors = JELLY_COLORS

-- La medusa número i de un campo: su sitio a los t segundos (sube y baja y se mece un poco alrededor de
-- su sitio), su tamaño y su color. Siempre dentro del campo y en el agua (entre el fondo + 6 y Top).
-- floorY: el fondo en su sitio (Ambient.jellyFloor; SeaAmbient lo guarda: Ocean.floorY cuesta).
function Ambient.jelly(field: any, i: number, t: number, floorY: number?): (Vector3, number, Color3)
	local h1, h2, h3, h4 = Ocean.hash(i, 1, 90), Ocean.hash(i, 2, 90), Ocean.hash(i, 3, 90), Ocean.hash(i, 4, 90)
	local a = h1 * math.pi * 2
	local r = sqrt(h2) * field.R * 0.92
	local x, z = field.X + cos(a) * r, field.Z + sin(a) * r
	local f = floorY or Ocean.floorY(x, z) or (field.Top - 60)
	local low = f + 6
	local high = min(field.Top, Ocean.Surface - 6)
	if high < low then
		high = low
	end
	local y = low + (high - low) * h3 + sin(t * (0.18 + 0.1 * h4) + h1 * 20) * 4
	y = math.clamp(y, low, high)
	local size = 1.6 + h4 * 3.4
	return V(x + sin(t * 0.07 + i) * 3, y, z + cos(t * 0.05 + i) * 3), size, JELLY_COLORS[1 + (i % #JELLY_COLORS)]
end

-- El fondo bajo la medusa i de un campo (no cambia: se calcula una vez)
function Ambient.jellyFloor(field: any, i: number): number
	local h1, h2 = Ocean.hash(i, 1, 90), Ocean.hash(i, 2, 90)
	local a, r = h1 * math.pi * 2, sqrt(h2) * field.R * 0.92
	return Ocean.floorY(field.X + cos(a) * r, field.Z + sin(a) * r) or (field.Top - 60)
end

-- Cuántas medusas de cada campo (los cercanos primero) caben en el tope
function Ambient.jellyPlan(pos: Vector3, mobile: boolean): { { Field: any, Count: number } }
	local caps = Ambient.caps(mobile)
	local left = caps.Jellies
	local plan = {}
	for _, f in Ambient.fieldsNear(pos, caps.FieldReach) do
		if left <= 0 then
			break
		end
		local want = math.clamp(math.floor(f.R / 8), 8, 30)
		local n = min(want, left)
		left -= n
		table.insert(plan, { Field = f, Count = n })
	end
	return plan
end

return Ambient
