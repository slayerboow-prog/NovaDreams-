-- DeepReef: el relieve GRANDE del mar v4 (docs/mar/v4-objetivo.md; solo con Config.Sea.V4).
--
-- El Gran Veril (shared/Sea/Ocean.verilAt) da la forma: la plataforma llana, la pared casi vertical y la fosa
-- de 60–85 m. Pero el fondo de Ocean se rellena en columnas de 16 studs (World/OceanBuilder): una pared así
-- sola sería un muro de cajas. Aquí, por parcelas de 48 studs a lo largo del veril, lo que la hace roca de
-- verdad:
--
--   * Respaldo: un bloque de roca detrás de la pared (de la fosa a 10 studs bajo la plataforma), para que las
--     cuevas y los salientes nunca dejen ver el vacío de debajo del fondo (OceanBuilder solo pone 14 studs).
--   * Contrafuertes y bultos: 2–3 bolas grandes (radio 9–16) medio metidas en la cara de la pared.
--   * Voladizos: en algunos tramos, una bola en el filo que sale hacia el mar: debajo queda una visera.
--   * Cuevas: bocas de agua (bolas de agua dentro de la roca de respaldo) a media altura.
--   * En la fosa: agujas de roca de 20–40 m (columnas de bolas que adelgazan), arcos de roca y peñascos.
--
-- Pura (sin Instance): la usan World/DeepReliefBuilder (servidor), las pruebas (scripts/test-mar.luau) y la
-- vista previa (scripts/map/orillas-export.luau). Op = el de shared/Sea/ShoreReef (Ball | Block).

local Shared = game:GetService("ReplicatedStorage").Shared
local Ocean = require(Shared.Sea.Ocean)

local DeepReef = {}

DeepReef.Cell = 48
DeepReef.Enabled = Ocean.V4 == true
DeepReef.Ceiling = Ocean.Surface - 9 -- (como ShoreReef: nada sube a menos de 2,5 m de la superficie)
DeepReef.SpireTop = -62 -- la punta de una aguja de la fosa, como mucho (≈ 17 m: no se choca un barco)

local floor, sqrt, min, max, pi = math.floor, math.sqrt, math.min, math.max, math.pi
local noise = Ocean.noise
local P = Ocean.World.Profile

local function hash(a: number, b: number, c: number): number
	local v = math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453
	return v - floor(v)
end
DeepReef.hash = hash

export type Op = { Shape: string, X: number, Y: number, Z: number, R: number?, Size: { number }?, Yaw: number?, Pitch: number?, Material: string }

-- La dirección hacia el mar (gradiente de la distancia a tierra)
local function seaward(x: number, z: number): (number, number)
	local e = 8
	local gx = Ocean.landDistance(x + e, z) - Ocean.landDistance(x - e, z)
	local gz = Ocean.landDistance(x, z + e) - Ocean.landDistance(x, z - e)
	local m = sqrt(gx * gx + gz * gz)
	if m < 1e-6 then
		return 0, 1
	end
	return gx / m, gz / m
end
DeepReef.seaward = seaward

export type Spot = {
	X: number,
	Z: number,
	D: number,
	M: number, -- peso del tramo de veril (0..1)
	U: number, -- distancia a la pared (negativo: en la plataforma)
	NX: number,
	NZ: number, -- hacia el mar
	WX: number,
	WZ: number, -- el pie de la pared más cercano (en el filo)
	Top: number, -- el alto de la plataforma en el filo
	Fosa: number, -- el fondo de la fosa
}

-- Lo que hay en el centro de una parcela de 48 studs (nil: ahí no hay veril)
function DeepReef.spot(ix: number, iz: number): Spot?
	if not DeepReef.Enabled then
		return nil
	end
	local C = DeepReef.Cell
	local x, z = (ix + 0.5) * C, (iz + 0.5) * C
	local d = Ocean.landDistance(x, z)
	if d < P.ShelfEnd - 30 or d > P.ShelfEnd + 420 then
		return nil
	end
	local m, u, _, fosa = Ocean.verilAt(x, z, d)
	if m < 0.35 then
		return nil
	end
	local s = Ocean.sample(x, z)
	if not s.Floor or s.Keep > 0.2 or s.Basin > 0.2 or s.Canyon > 0.05 or s.Cathedrals > 0.05 or s.Trench > 0.05 then
		return nil
	end
	local nx, nz = seaward(x, z)
	local wx, wz = x - nx * u, z - nz * u
	local top = Ocean.floorY(wx - nx * 10, wz - nz * 10) or P.ShelfY
	return { X = x, Z = z, D = d, M = m, U = u, NX = nx, NZ = nz, WX = wx, WZ = wz, Top = top, Fosa = fosa }
end

local ROCK = { "Rock", "Rock", "Slate", "Limestone" }
local DEEP = { "Basalt", "Slate", "Rock" }
local function pick(list: { string }, h: number): string
	return list[1 + floor(h * #list) % #list]
end

-- El relieve de una parcela (servidor)
DeepReef.Memo = nil :: { [string]: { Op } }?
function DeepReef.relief(ix: number, iz: number): { Op }
	local memo = DeepReef.Memo
	local key = ix .. "," .. iz
	if memo and memo[key] then
		return memo[key]
	end
	local ops: { Op } = {}
	local sp = DeepReef.spot(ix, iz)
	if sp then
		DeepReef.reliefAt(ops, ix, iz, sp)
	end
	if memo then
		memo[key] = ops
	end
	return ops
end

function DeepReef.reliefAt(ops: { Op }, ix: number, iz: number, sp: Spot)
	local C = DeepReef.Cell
	local V = Ocean.Veril
	local h1, h2, h3, h4 = hash(ix, iz, 1), hash(ix, iz, 2), hash(ix, iz, 3), hash(ix, iz, 4)
	local nx, nz = sp.NX, sp.NZ
	local tx, tz = -nz, nx -- a lo largo de la pared
	local yaw = math.atan2(nx, nz)
	local height = sp.Top - sp.Fosa
	if sp.U > -C * 0.6 and sp.U < V.Drop + C * 0.4 and height > 40 then
		-- 1) La parcela de la pared: respaldo, bultos, voladizo y cueva
		local back = 44
		local y0, y1 = sp.Fosa - 12, sp.Top - 10
		table.insert(ops, {
			Shape = "Block",
			X = sp.WX - nx * (back / 2 - 6),
			Y = (y0 + y1) / 2,
			Z = sp.WZ - nz * (back / 2 - 6),
			Size = { C + 10, y1 - y0, back },
			Yaw = yaw,
			Material = "Rock",
		})
		-- (ronda 2 de la vista previa: con 2–3 bultos la cara era una lámina lisa. 5–7, de 5 a 15 studs, más
		-- arriba que abajo —donde se ve—)
		for k = 1, 5 + floor(h1 * 3) do
			local r = 5 + hash(ix, iz, 10 + k) * 10
			local t = 0.06 + hash(ix, iz, 20 + k) ^ 1.4 * 0.8
			local along = (hash(ix, iz, 30 + k) - 0.5) * C
			local out = r * (0.3 + hash(ix, iz, 40 + k) * 0.25)
			table.insert(ops, {
				Shape = "Ball",
				X = sp.WX + tx * along + nx * out,
				Y = sp.Top - height * t,
				Z = sp.WZ + tz * along + nz * out,
				R = r,
				Material = pick(ROCK, hash(ix, iz, 50 + k)),
			})
		end
		-- el pie de la pared: un talud de derrubios (peñascos grandes)
		table.insert(ops, { Shape = "Ball", X = sp.WX + nx * (V.Drop * 0.8) + tx * (h2 - 0.5) * 30, Y = sp.Fosa - 2, Z = sp.WZ + nz * (V.Drop * 0.8) + tz * (h2 - 0.5) * 30, R = 10 + h3 * 6, Material = pick(DEEP, h4) })
		if h2 > 0.62 then
			-- voladizo: la roca del filo sale hacia el mar (debajo queda la visera, en sombra)
			-- (ronda 1 de la vista previa: con el centro alto salía una cúpula —un iglú— encima del filo. El centro va
			-- casi a la altura del filo y hacia fuera: asoma poco por arriba y deja la visera debajo)
			local r = 9 + h3 * 4
			table.insert(ops, { Shape = "Ball", X = sp.WX + nx * (r * 0.75) + tx * (h1 - 0.5) * 20, Y = min(sp.Top - r * 0.85, DeepReef.Ceiling - r), Z = sp.WZ + nz * (r * 0.75) + tz * (h1 - 0.5) * 20, R = r, Material = "Rock" })
		end
		if h3 > 0.7 and height > 90 then
			-- cueva: una boca a media altura que entra unos 20 studs en la roca de respaldo
			local y = sp.Top - height * (0.35 + h4 * 0.3)
			local along = (h1 - 0.5) * C * 0.5
			table.insert(ops, { Shape = "Ball", X = sp.WX + tx * along - nx * 3, Y = y, Z = sp.WZ + tz * along - nz * 3, R = 8 + h2 * 3, Material = "Water" })
			table.insert(ops, { Shape = "Ball", X = sp.WX + tx * along - nx * 13, Y = y + 1, Z = sp.WZ + tz * along - nz * 13, R = 6.5, Material = "Water" })
		end
	elseif sp.U >= V.Drop + C * 0.4 and sp.U < V.Drop + V.Width then
		-- 2) La fosa: agujas, arcos y peñascos
		local fy = Ocean.floorY(sp.X, sp.Z) or sp.Fosa
		if h1 < 0.14 then
			-- aguja: de 20 a 40 m, bolas que adelgazan (con un quiebro: no es un poste)
			local top = min(DeepReef.SpireTop, fy + 70 + h2 * 80)
			local n = 5 + floor(h3 * 3)
			local cx, cz = sp.X + (h4 - 0.5) * 16, sp.Z + (h2 - 0.5) * 16
			local lean = (h3 - 0.5) * 0.25
			for k = 0, n - 1 do
				local t = k / (n - 1)
				local r = 13 - t * 8.5
				local y = fy + (top - fy) * t
				table.insert(ops, { Shape = "Ball", X = cx + tx * lean * (y - fy) + (hash(ix, iz, 60 + k) - 0.5) * 4, Y = y, Z = cz + tz * lean * (y - fy) + (hash(ix, iz, 70 + k) - 0.5) * 4, R = r, Material = if t < 0.3 then "Basalt" elseif k % 2 == 0 then "Rock" else "Slate" })
			end
		elseif h1 < 0.2 then
			-- arco de roca: medio anillo de bolas a lo largo de la fosa
			local R = 22 + h2 * 12
			for k = 0, 10 do
				local a = pi * k / 10
				local x = sp.X + tx * math.cos(a) * R
				local z = sp.Z + tz * math.cos(a) * R
				table.insert(ops, { Shape = "Ball", X = x, Y = fy - 2 + math.sin(a) * R * 1.1, Z = z, R = 5.5 + (1 - math.sin(a)) * 3, Material = if k % 3 == 0 then "Slate" else "Rock" })
			end
		elseif h1 < 0.55 then
			for k = 1, 1 + floor(h2 * 2) do
				local r = 4 + hash(ix, iz, 80 + k) * 6
				table.insert(ops, { Shape = "Ball", X = sp.X + (hash(ix, iz, 82 + k) - 0.5) * 36, Y = fy - r * 0.4, Z = sp.Z + (hash(ix, iz, 84 + k) - 0.5) * 36, R = r, Material = pick(DEEP, hash(ix, iz, 86 + k)) })
			end
		end
	end
	-- nada por encima del techo (salvo el respaldo, que está por debajo de la plataforma)
	for i = #ops, 1, -1 do
		local op = ops[i]
		if op.Shape == "Ball" and op.Y + (op.R :: number) > DeepReef.Ceiling + 0.01 then
			op.Y = DeepReef.Ceiling - (op.R :: number)
		end
	end
end

---------------------------------------------------------------------
-- Lo que crece en el veril (cliente: Controllers/SeaBiome, con las mallas del kit)
---------------------------------------------------------------------
-- Item = el de shared/Sea/ShoreReef y además:
--   Wall = true   va en la CARA de la pared: Y es su alto y (NX, NZ) mira al mar. SeaBiome busca la roca con
--                 un rayo horizontal hacia la pared a ese alto y lo planta allí, creciendo hacia fuera
--   Y             (en la fosa también: el alto aproximado, para el LOD)
export type Item = { Piece: string, X: number, Z: number, H: number, Yaw: number, Tint: { number }?, Small: boolean, Sway: boolean, Lift: number, Wall: boolean?, Y: number?, NX: number?, NZ: number? }

-- Colores de la pared (los de un veril de verdad: gorgonias rojas y naranjas, esponjas de barril, corales
-- negros y amarillos; más hondo, más fríos y lo que brilla)
local FAN = { { 214, 74, 52 }, { 236, 128, 48 }, { 200, 58, 96 }, { 240, 186, 70 }, { 168, 72, 160 } }
local SPONGE = { { 196, 110, 60 }, { 150, 70, 120 }, { 214, 160, 70 }, { 120, 90, 160 } }
local CORAL = { { 236, 150, 90 }, { 120, 186, 200 }, { 222, 96, 120 }, { 180, 210, 120 }, { 246, 206, 120 } }
local COOL = { { 90, 150, 210 }, { 130, 110, 200 }, { 70, 180, 190 }, { 160, 130, 220 } }
local GLOW = { { 70, 230, 255 }, { 150, 110, 255 }, { 80, 255, 190 }, { 255, 110, 220 } }
local function tint(list: { { number } }, h: number): { number }
	return list[1 + floor(h * #list) % #list]
end

local SWAY = { Abanico = true, CoralBlando = true, AnemonaLuz = true, AlgaAncha = true }
local SMALL = { Estrella = true, Erizo = true, AnemonaLuz = true, Concha = true }

function DeepReef.decor(ix: number, iz: number, density: number?): { Item }
	local items: { Item } = {}
	local sp = DeepReef.spot(ix, iz)
	if not sp then
		return items
	end
	local C = DeepReef.Cell
	local V = Ocean.Veril
	local k = density or 1
	local nx, nz = sp.NX, sp.NZ
	local tx, tz = -nz, nx
	local height = sp.Top - sp.Fosa
	local function put(piece: string, x: number, z: number, h: number, t: { number }?, extra: { [string]: any }?)
		local it: Item = {
			Piece = piece,
			X = x,
			Z = z,
			H = h,
			Yaw = hash(x, z, 90) * pi * 2,
			Tint = t,
			Small = SMALL[piece] == true,
			Sway = SWAY[piece] == true,
			Lift = 0,
		}
		if extra then
			for key, v in extra do
				(it :: any)[key] = v
			end
		end
		table.insert(items, it)
	end
	if sp.U > -C * 0.6 and sp.U < V.Drop + C * 0.4 and height > 40 then
		-- la cara de la pared: gorgonias GRANDES de frente al azul, esponjas de barril, corales en repisa
		-- (ronda 2: la pared se veía casi desnuda: el doble, sobre todo en los 60 studs de arriba)
		local n = floor((44 + hash(ix, iz, 200) * 24) * k + 0.5)
		for i = 1, n do
			local a = hash(ix, iz, 201 + i)
			local t = 0.03 + hash(ix, iz, 300 + i) ^ 1.8 * 0.92 -- (más arriba, donde hay luz)
			local y = sp.Top - height * t
			local along = (hash(ix, iz, 400 + i) - 0.5) * C
			local x, z = sp.WX + tx * along + nx * 30, sp.WZ + tz * along + nz * 30
			local deep = y < -110
			local piece, h, col
			if y < -150 and a > 0.62 then
				-- (ronda 1: abajo, al pie, casi nada se veía: más de lo que brilla)
				piece, h, col = if a > 0.8 then "SetaLuz" else "AnemonaLuz", 1.4 + hash(ix, iz, 560 + i) * 2.2, tint(GLOW, hash(ix, iz, 561 + i))
			elseif a < 0.34 then
				piece, h, col = "Abanico", 4 + hash(ix, iz, 500 + i) * 7, tint(if deep then COOL else FAN, hash(ix, iz, 501 + i))
			elseif a < 0.56 then
				piece, h, col = "Esponjas", 2.5 + hash(ix, iz, 510 + i) * 5, tint(SPONGE, hash(ix, iz, 511 + i))
			elseif a < 0.74 then
				piece, h, col = "CoralMesa", 2 + hash(ix, iz, 520 + i) * 4, tint(if deep then COOL else CORAL, hash(ix, iz, 521 + i))
			elseif a < 0.86 then
				piece, h, col = "CoralBlando", 2 + hash(ix, iz, 530 + i) * 3, tint(if deep then COOL else CORAL, hash(ix, iz, 531 + i))
			elseif deep or a < 0.93 then
				piece, h, col = if deep then "SetaLuz" else "AnemonaLuz", 1.2 + hash(ix, iz, 540 + i) * 1.6, tint(GLOW, hash(ix, iz, 541 + i))
			else
				piece, h, col = "CoralCerebro", 1.8 + hash(ix, iz, 550 + i) * 1.6, tint(CORAL, hash(ix, iz, 551 + i))
			end
			put(piece, x, z, h, col, { Wall = true, Y = y, NX = nx, NZ = nz })
		end
		-- encima del filo: el borde del arrecife, abanicos y corales mirando al azul
		for i = 1, floor((6 + hash(ix, iz, 600) * 5) * k + 0.5) do
			local along = (hash(ix, iz, 601 + i) - 0.5) * C
			local back = 2 + hash(ix, iz, 620 + i) * 14
			local x, z = sp.WX + tx * along - nx * back, sp.WZ + tz * along - nz * back
			local r = hash(ix, iz, 640 + i)
			local piece = if r < 0.4 then "Abanico" elseif r < 0.65 then "Esponjas" elseif r < 0.85 then "CoralCerebro" else "CoralPilar"
			local h = if piece == "Abanico" then 4 + r * 5 elseif piece == "CoralPilar" then 4 + r * 4 else 2 + r * 2.4
			put(piece, x, z, h, tint(if piece == "Abanico" then FAN elseif piece == "Esponjas" then SPONGE else CORAL, hash(ix, iz, 660 + i)), { Y = sp.Top })
		end
	elseif sp.U >= V.Drop + C * 0.4 and sp.U < V.Drop + V.Width then
		-- el fondo de la fosa: poca luz, setas y anémonas que brillan, esponjas y rocas
		local fy = Ocean.floorY(sp.X, sp.Z) or sp.Fosa
		for i = 1, floor((8 + hash(ix, iz, 700) * 8) * k + 0.5) do
			local x, z = sp.X + (hash(ix, iz, 701 + i) - 0.5) * C, sp.Z + (hash(ix, iz, 721 + i) - 0.5) * C
			local r = hash(ix, iz, 741 + i)
			local piece = if r < 0.3 then "SetaLuz" elseif r < 0.5 then "AnemonaLuz" elseif r < 0.7 then "Esponjas" elseif r < 0.85 then "Canto" else "RocaPorosa"
			local h = if piece == "SetaLuz" then 1.4 + r * 3 elseif piece == "AnemonaLuz" then 1 + r * 1.2 elseif piece == "Esponjas" then 2 + r * 3 else 1.5 + r * 3
			put(piece, x, z, h, if piece == "SetaLuz" or piece == "AnemonaLuz" then tint(GLOW, r) elseif piece == "Esponjas" then tint(SPONGE, r) else nil, { Y = fy })
		end
	end
	return items
end

-- ¿Se ve? (como ShoreReef.visible, pero la distancia cuenta el alto: en la pared, lo de 60 studs más abajo
-- está lejos aunque esté justo debajo)
DeepReef.Radius = { Mobile = 130, Desktop = 190 }
DeepReef.SmallDistance = { Mobile = 40, Desktop = 64 }
function DeepReef.visible(item: Item, distance: number, mobile: boolean): boolean
	local key = if mobile then "Mobile" else "Desktop"
	if item.Small then
		return distance <= DeepReef.SmallDistance[key]
	end
	if item.H < 2.5 then
		return distance <= DeepReef.Radius[key] * 0.55
	end
	return distance <= DeepReef.Radius[key]
end

-- Las parcelas que pueden tener veril: llama a fn(ix, iz) en cada una (el servidor y las pruebas)
function DeepReef.eachCell(fn: (number, number) -> (), yield: (() -> ())?)
	if not DeepReef.Enabled then
		return
	end
	local C = DeepReef.Cell
	local BIG = C * 4
	local a = Ocean.Area
	for bx = a.MinX, a.MaxX - 1, BIG do
		for bz = a.MinZ, a.MaxZ - 1, BIG do
			local d = Ocean.landDistance(bx + BIG / 2, bz + BIG / 2)
			if d > P.ShelfEnd - 30 - BIG and d < P.ShelfEnd + 420 + BIG then
				local ix0, iz0 = floor(bx / C), floor(bz / C)
				for ix = ix0, ix0 + 3 do
					for iz = iz0, iz0 + 3 do
						fn(ix, iz)
					end
				end
				if yield then
					yield()
				end
			end
		end
	end
end

return DeepReef
