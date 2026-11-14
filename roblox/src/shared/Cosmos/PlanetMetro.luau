-- PlanetMetro: el PLANO de la ciudad grande de un planeta (la capital entera alrededor del barrio hecho a
-- mano). Cuentas puras y repetibles: lo usan shared/Cosmos/PlanetSurface y Tefra (el relieve bajo la ciudad,
-- el material de las calles, los choques de la nave, dónde no va mineral ni flora), World/PlanetMetroBuilder
-- (lo dibuja), Controllers/MapUI (el nombre del distrito) y las pruebas (scripts/test-planetmetro.luau).
-- Cómo es cada ciudad: shared/Cosmos/MetroStyles.
--
--   M = PlanetMetro.new(S, style)
--   M.shape(lx, lz, h, base) → h        (Ground) el relieve suavizado bajo la ciudad
--   M.streetAt(lx, lz) → (bool, avenida?) (Ground) calle pintada en el terreno
--   M.lots() → { Lot }                   parcelas: { Id, X, Z, W, D, FX, FZ, Kind, District, Floors, Height,
--                                        Base, Low, Top, Seed, Rect = { X0, X1, Z0, Z1 } (la parcela entera) }
--   M.bridges() → { { X0, X1, Z0, Z1, Y } } (Deck) las pasarelas entre plataformas
--   M.lamps() → { { X, Z, Y, FX, FZ } }    M.crowd() → { { X, Z, Y, FX, FZ, District } }
--   M.lotAt(lx, lz, margin?) → Lot?      M.solidTop(lx, lz, margin?) → altura local (o nil)
--   M.landingBlocked(lx, lz)             M.covers(lx, lz) (dentro de la ciudad, con margen: sin mineral)
--   M.districtAt(lx, lz) → distrito?     (nil dentro del barrio: ese lo cuenta su plano)
-- Coordenadas LOCALES del planeta (studs desde su Origin; X = este, Z = sur); alturas locales (sin Origin.Y).

local PlanetMetro = {}

local function smooth(e0: number, e1: number, x: number): number
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

local function rng(seed: number): () -> number
	local s = math.floor(seed) % 2147483647
	if s <= 0 then
		s += 2147483646
	end
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

-- Altura de una planta, y lo que mide cada tipo cuando no va por plantas
PlanetMetro.FloorH = 10
local TALL = { Torre = true, Rascacielos = true, Bloque = true }
local OPEN = { Plaza = true, Parque = true, Jardin = true, Mercado = true }

function PlanetMetro.new(S: any, st: { [string]: any }): { [string]: any }
	local M: { [string]: any } = { Name = st.Name, Mode = st.Mode or "Ground", Style = st, Districts = st.Districts, Radius = st.Radius }
	local City = S.City
	local R = st.Radius or 900
	local seed = st.Seed or 7
	local G = st.Block or 140
	local W = st.Street or 20
	local P = st.Lot or 50
	local av = st.Avenue
	local deck = M.Mode == "Deck"
	local cityMargin = (if City then (City.Blend or 100) else 0) + P * 0.75
	local avoid = st.Avoid or {}

	---------------------------------------------------------------------
	-- El contorno (un cuadrado redondeado con el borde irregular)
	---------------------------------------------------------------------
	function M.edge(lx: number, lz: number): number
		local d = math.sqrt(lx * lx + lz * lz)
		local sq = math.max(math.abs(lx), math.abs(lz))
		local wobble = 0.9 + 0.1 * math.noise(lx / 420, lz / 420, seed + 0.37)
		return (d * 0.5 + sq * 0.5) / (R * wobble)
	end
	function M.inside(lx: number, lz: number, margin: number?): boolean
		return M.edge(lx, lz) <= 1 - (margin or 0) / R
	end
	-- (para el mineral y la flora: ni dentro de la ciudad ni pegados a ella)
	function M.covers(lx: number, lz: number): boolean
		if M.edge(lx, lz) > 1 + 70 / R then
			return false
		end
		if not deck then
			return true
		end
		-- (en plataformas: solo donde hay plataforma o pasarela cerca; los islotes y picos libres siguen libres)
		for _, o in { { 0, 0 }, { 14, 0 }, { -14, 0 }, { 0, 14 }, { 0, -14 } } do
			if M.walkable(lx + o[1], lz + o[2]) then
				return true
			end
		end
		return false
	end

	---------------------------------------------------------------------
	-- Las calles: distancia al borde de la calle más cercana (≤ 0: en la calle)
	---------------------------------------------------------------------
	local function halfW(k: number): (number, boolean)
		if av and k % av.Every == 0 then
			return av.Width / 2, true
		end
		return W / 2, false
	end
	local function lineAt(k: number, other: number, axis: number): number
		if st.Layout == "Zoco" then
			-- (calles torcidas: cada línea serpentea un poco a lo largo de la otra coordenada)
			return k * G + G * 0.22 * math.noise(k * 1.73 + axis * 9.1, other / 260, seed + 0.11)
		end
		return k * G
	end
	local function gridDist(v: number, other: number, axis: number): (number, boolean)
		local k0 = math.floor(v / G + 0.5)
		local best, isAv = math.huge, false
		for k = k0 - 1, k0 + 1 do
			local hw, a = halfW(k)
			local d = math.abs(v - lineAt(k, other, axis)) - hw
			if d < best then
				best, isAv = d, a
			end
		end
		return best, isAv
	end
	function M.streetDist(lx: number, lz: number): (number, boolean)
		if st.Layout == "Rings" then
			local d = math.sqrt(lx * lx + lz * lz)
			local k = math.max(1, math.floor(d / G + 0.5))
			local ring = math.abs(d - k * G) - (if k % 2 == 0 then W * 0.7 else W / 2)
			local rays = st.Rays or 8
			local step = math.pi * 2 / rays
			local a = math.atan2(lz, lx)
			local ra = math.floor(a / step + 0.5) * step
			local ray = if d > G * 0.5 then d * math.abs(math.sin(a - ra)) - W * 0.6 else math.huge
			if ray < ring then
				return ray, true
			end
			return ring, k % 2 == 0
		end
		local dx, ax = gridDist(lx, lz, 0)
		local dz, az = gridDist(lz, lx, 1)
		if dx < dz then
			return dx, ax
		end
		return dz, az
	end

	---------------------------------------------------------------------
	-- Distritos (el más cercano a su centro)
	---------------------------------------------------------------------
	local function districtOf(lx: number, lz: number): ({ [string]: any }, number)
		local best, bi, bd = M.Districts[1], 1, math.huge
		for i, d in M.Districts do
			local dd = (lx - d.X) ^ 2 + (lz - d.Z) ^ 2
			if dd < bd then
				best, bi, bd = d, i, dd
			end
		end
		return best, bi
	end
	M.districtOf = districtOf
	function M.districtAt(lx: number, lz: number): { [string]: any }?
		if not M.inside(lx, lz, -40) then
			return nil
		end
		if City and City.inside(lx, lz, 0) then
			return nil
		end
		return (districtOf(lx, lz))
	end

	---------------------------------------------------------------------
	-- El relieve bajo la ciudad (Ground): el terreno se queda, pero mucho más suave
	---------------------------------------------------------------------
	local soften = st.Soften or 0.25
	function M.weight(lx: number, lz: number): number
		return smooth(1.06, 0.9, M.edge(lx, lz))
	end
	function M.shape(lx: number, lz: number, h: number, base: number): number
		if deck or soften >= 1 then
			return h
		end
		local w = M.weight(lx, lz)
		if w <= 0 then
			return h
		end
		-- (los lagos y los sitios que se respetan se quedan como son: ni se rellenan ni se aplanan)
		for _, l in S.Lakes or {} do
			local d = math.sqrt((lx - l.X) ^ 2 + (lz - l.Z) ^ 2)
			if d < l.R * 2 then
				w *= smooth(l.R * 1.2, l.R * 2, d)
			end
		end
		for _, a in avoid do
			local d = math.sqrt((lx - a.X) ^ 2 + (lz - a.Z) ^ 2)
			if d < a.R * 1.3 then
				w *= smooth(a.R * 0.8, a.R * 1.3, d)
			end
		end
		if w <= 0 then
			return h
		end
		local soft = base + (h - base) * soften
		return h + (soft - h) * w
	end
	-- (la altura del suelo de la ciudad fuera del barrio: el relieve suavizado)
	local function groundY(lx: number, lz: number): number
		return M.shape(lx, lz, S.rawHeight(lx, lz), S.padY())
	end
	M.groundY = groundY
	local deckY = S.padY() + (st.DeckY or 0)
	M.DeckY = deckY

	---------------------------------------------------------------------
	-- ¿Se puede construir aquí? (fuera del barrio, de los puntos de interés, de lagos y del agua)
	---------------------------------------------------------------------
	local function clearOf(lx: number, lz: number, pad: number, noCity: boolean?): boolean
		if math.max(math.abs(lx), math.abs(lz)) > S.Half * 0.74 then
			return false
		end
		if not noCity and City and City.inside(lx, lz, cityMargin + pad) then
			return false
		end
		for _, p in S.POIs or {} do
			if math.sqrt((lx - p.X) ^ 2 + (lz - p.Z) ^ 2) < (p.Flat or 0) * 2.6 + 14 + pad then
				return false
			end
		end
		for _, l in S.Lakes or {} do
			if math.sqrt((lx - l.X) ^ 2 + (lz - l.Z) ^ 2) < l.R * 1.55 + pad then
				return false
			end
		end
		for _, a in avoid do
			if math.sqrt((lx - a.X) ^ 2 + (lz - a.Z) ^ 2) < a.R + pad then
				return false
			end
		end
		return true
	end
	M.clearOf = clearOf

	-- (en plataformas: el terreno tiene que quedar por debajo; en tierra: nada de agua)
	local function groundOk(lx: number, lz: number): boolean
		local raw = S.rawHeight(lx, lz)
		if deck then
			return raw < deckY - (st.DeckClear or 6)
		end
		return groundY(lx, lz) > (S.WaterY or 0) + 2.5
	end

	---------------------------------------------------------------------
	-- Las parcelas (se calculan la primera vez que alguien las pide)
	---------------------------------------------------------------------
	local lotsCache: { { [string]: any } }? = nil
	local bucket: { [number]: { { [string]: any } } } = {}
	local BUCKET = 64
	local function bkey(bx: number, bz: number): number
		return (bx + 1000) * 4096 + (bz + 1000)
	end
	local lampList: { { [string]: number } } = {}
	local crowdList: { { [string]: any } } = {}

	local function pickKind(d: { [string]: any }, r: () -> number): string
		if r() < (d.Plaza or 0.05) then
			return if r() < 0.6 then "Plaza" else "Parque"
		end
		local total = 0
		local keys = {}
		for k, w in d.Mix do
			table.insert(keys, k)
			total += w
		end
		table.sort(keys) -- (orden fijo: el mismo plano en el servidor, el cliente y las pruebas)
		local roll = r() * total
		for _, k in keys do
			roll -= d.Mix[k]
			if roll <= 0 then
				return k
			end
		end
		return keys[#keys]
	end

	local function addLot(x0: number, x1: number, z0: number, z1: number, fx: number, fz: number, n: number)
		local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
		local lw, ld = x1 - x0, z1 - z0
		-- todo el solar tiene que estar dentro, libre y (en tierra) seco
		local corners = { { x0, z0 }, { x1, z0 }, { x0, z1 }, { x1, z1 }, { cx, cz } }
		for _, c in corners do
			if not M.inside(c[1], c[2], 6) or not clearOf(c[1], c[2], 0) or not groundOk(c[1], c[2]) then
				return
			end
		end
		local d, di = districtOf(cx, cz)
		local r = rng(seed * 7919 + n * 104729 + 17)
		r()
		local kind = pickKind(d, r)
		-- (a lo ancho de la fachada y hacia dentro)
		local along = if fx ~= 0 then ld else lw
		local inward = if fx ~= 0 then lw else ld
		local gap = if deck then 4 else 3
		local wA, dI = along - gap * 2, inward - gap * 2
		if TALL[kind] then
			wA *= 0.72 + r() * 0.24
			dI *= 0.7 + r() * 0.26
		elseif kind == "Casa" then
			wA *= 0.74 + r() * 0.22
			dI *= 0.68 + r() * 0.24
		elseif kind == "Choza" then
			wA *= 0.6 + r() * 0.2
			dI *= 0.6 + r() * 0.2
		elseif kind == "Cupula" or kind == "TorreViento" or kind == "Mastil" or kind == "Arbol" or kind == "Globo" then
			local s = math.min(wA, dI) * (0.7 + r() * 0.2)
			wA, dI = s, s
		elseif not OPEN[kind] then
			wA *= 0.88 + r() * 0.12
			dI *= 0.84 + r() * 0.16
		end
		local floors = d.Floors[1] + math.floor(r() * (d.Floors[2] - d.Floors[1] + 1))
		if st.Downtown and TALL[kind] then
			local k = 1 - math.clamp(math.sqrt(cx * cx + cz * cz) / R, 0, 1)
			floors = math.min(st.MaxFloors or 48, math.floor(floors * (1 + st.Downtown * k * k) + 0.5))
		end
		local height
		if kind == "Plaza" or kind == "Parque" then
			height = 1
		elseif kind == "Mercado" then
			height = 9
		elseif kind == "Jardin" then
			height = 8
		elseif kind == "Arbol" then
			height = 70 + r() * 50
		elseif kind == "Mastil" then
			height = 40 + floors * 10 + r() * 20
		elseif kind == "Globo" then
			height = 14
		elseif kind == "Casa" or kind == "Choza" then
			floors = math.min(floors, 2)
			height = floors * PlanetMetro.FloorH + 6
		elseif kind == "Cupula" then
			height = floors * PlanetMetro.FloorH + math.min(wA, dI) * 0.5
		elseif kind == "TorreViento" then
			height = floors * PlanetMetro.FloorH + 18
		elseif kind == "Nave" or kind == "Bunker" or kind == "Chatarra" then
			floors = math.min(floors, 2)
			height = floors * PlanetMetro.FloorH + 4
		else
			height = floors * PlanetMetro.FloorH + 2
		end
		local w = if fx ~= 0 then dI else wA
		local dd = if fx ~= 0 then wA else dI
		-- la base: en tierra, el punto más alto del solar (nunca enterrado; los cimientos bajan al más bajo)
		local base, low
		if deck then
			base, low = deckY, deckY - 2
		else
			base, low = -math.huge, math.huge
			for _, c in { { cx - w / 2, cz - dd / 2 }, { cx + w / 2, cz - dd / 2 }, { cx - w / 2, cz + dd / 2 }, { cx + w / 2, cz + dd / 2 }, { cx, cz } } do
				local g = groundY(c[1], c[2])
				base = math.max(base, g)
				low = math.min(low, g)
			end
			base += 0.4
		end
		local lot = {
			Id = ("%sM%d"):format(S.Prefix or (S.Id .. "_"), n),
			X = cx,
			Z = cz,
			W = w,
			D = dd,
			FX = fx,
			FZ = fz,
			Kind = kind,
			District = d.Id,
			DistrictIndex = di,
			Floors = floors,
			Height = height,
			Base = base,
			Low = low,
			Top = base + height,
			Seed = seed * 131 + n * 977,
			Rect = { X0 = x0, X1 = x1, Z0 = z0, Z1 = z1 },
		}
		table.insert(lotsCache :: any, lot)
		-- (para buscarla deprisa por posición)
		for bx = math.floor(x0 / BUCKET), math.floor(x1 / BUCKET) do
			for bz = math.floor(z0 / BUCKET), math.floor(z1 / BUCKET) do
				local key = bkey(bx, bz)
				local list = bucket[key]
				if not list then
					list = {}
					bucket[key] = list
				end
				table.insert(list, lot)
			end
		end
		-- farola en la acera (una de cada dos fachadas, más o menos)
		if r() < (st.LampChance or 0.5) then
			local half = if fx ~= 0 then lw / 2 else ld / 2
			local side = (r() - 0.5) * (if fx ~= 0 then ld else lw) * 0.6
			local lx = cx + fx * (half + 2) + (if fx ~= 0 then 0 else side)
			local lz = cz + fz * (half + 2) + (if fz ~= 0 then 0 else side)
			local y = if deck then deckY else groundY(lx, lz)
			table.insert(lampList, { X = lx, Z = lz, Y = y, FX = fx, FZ = fz })
		end
		-- gente: en plazas, parques y mercados (y alguno en la puerta de los demás)
		if OPEN[kind] then
			for i = 1, 3 do
				local a = i * 2.1 + r()
				local px, pz = cx + math.cos(a) * lw * 0.25, cz + math.sin(a) * ld * 0.25
				table.insert(crowdList, { X = px, Z = pz, Y = if deck then deckY else groundY(px, pz), FX = cx, FZ = cz, District = d.Id, Work = if kind == "Mercado" then "Market" else nil })
			end
		elseif r() < 0.18 then
			local px, pz = cx + fx * (dI / 2 + 4), cz + fz * (dI / 2 + 4)
			if fx == 0 then
				px = cx + (r() - 0.5) * wA * 0.5
			else
				pz = cz + (r() - 0.5) * wA * 0.5
			end
			table.insert(crowdList, { X = px, Z = pz, Y = if deck then deckY else groundY(px, pz), FX = px + fx * 4, FZ = pz + fz * 4, District = d.Id })
		end
	end

	local function buildLots()
		lotsCache = {}
		local n = 0
		if st.Layout == "Grid" then
			-- Cuadrícula: cada manzana se parte en solares que dan a sus calles
			local kMax = math.ceil(R / G) + 1
			for kx = -kMax, kMax - 1 do
				local hx0 = halfW(kx)
				local hx1 = halfW(kx + 1)
				local bx0, bx1 = kx * G + hx0, (kx + 1) * G - hx1
				local nx = math.max(1, math.floor((bx1 - bx0) / P + 0.6))
				for kz = -kMax, kMax - 1 do
					local hz0 = halfW(kz)
					local hz1 = halfW(kz + 1)
					local bz0, bz1 = kz * G + hz0, (kz + 1) * G - hz1
					local nz = math.max(1, math.floor((bz1 - bz0) / P + 0.6))
					local sw, sd = (bx1 - bx0) / nx, (bz1 - bz0) / nz
					for i = 1, nx do
						for j = 1, nz do
							local edgeW, edgeE, edgeN, edgeS = i == 1, i == nx, j == 1, j == nz
							if edgeW or edgeE or edgeN or edgeS then
								n += 1
								-- fachada: a la calle que toca (en las esquinas, la más ancha, o la de delante)
								local fx, fz = 0, 0
								if edgeS then
									fz = 1
								elseif edgeN then
									fz = -1
								elseif edgeE then
									fx = 1
								else
									fx = -1
								end
								if (edgeE or edgeW) and (edgeN or edgeS) then
									local zAv = select(2, halfW(if edgeS then kz + 1 else kz))
									local xAv = select(2, halfW(if edgeE then kx + 1 else kx))
									if xAv and not zAv then
										fx, fz = if edgeE then 1 else -1, 0
									end
								end
								local x0 = bx0 + (i - 1) * sw
								local z0 = bz0 + (j - 1) * sd
								addLot(x0, x0 + sw, z0, z0 + sd, fx, fz, n)
							end
						end
					end
				end
			end
		else
			-- Zoco y anillos: solares en una rejilla fina (medio solar de paso) donde no pasa ninguna calle,
			-- sin pisarse entre ellos
			local half = P / 2
			local hs = P / 2
			local used: { [number]: boolean } = {}
			local function ck(a: number, b: number): number
				return (a + 2000) * 8192 + (b + 2000)
			end
			local kMax = math.ceil(R / hs) + 1
			for i = -kMax, kMax do
				for j = -kMax, kMax do
					if not (used[ck(i - 1, j - 1)] or used[ck(i, j - 1)] or used[ck(i - 1, j)] or used[ck(i, j)]) then
						local cx, cz = i * hs, j * hs
						local free = true
						for _, o in { { 0, 0 }, { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 }, { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
							if M.streetDist(cx + o[1] * (half - 1), cz + o[2] * (half - 1)) < 1.5 then
								free = false
								break
							end
						end
						if free then
							-- fachada: hacia la calle más cercana
							local best, fx, fz = math.huge, 0, 1
							for _, dir in { { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } } do
								local d = M.streetDist(cx + dir[1] * (half + W * 0.6), cz + dir[2] * (half + W * 0.6))
								if d < best then
									best, fx, fz = d, dir[1], dir[2]
								end
							end
							n += 1
							local before = #(lotsCache :: any)
							addLot(cx - half, cx + half, cz - half, cz + half, fx, fz, n)
							if #(lotsCache :: any) > before then
								used[ck(i - 1, j - 1)] = true
								used[ck(i, j - 1)] = true
								used[ck(i - 1, j)] = true
								used[ck(i, j)] = true
							end
						end
					end
				end
			end
		end
	end

	function M.lots(): { { [string]: any } }
		if not lotsCache then
			buildLots()
		end
		return lotsCache :: any
	end
	function M.lamps(): { { [string]: number } }
		M.lots()
		return lampList
	end
	function M.crowd(): { { [string]: any } }
		M.lots()
		return crowdList
	end

	-- La parcela cuyo EDIFICIO está en (lx, lz) (con margen)
	function M.lotAt(lx: number, lz: number, margin: number?): { [string]: any }?
		M.lots()
		local m = margin or 0
		local list = bucket[bkey(math.floor(lx / BUCKET), math.floor(lz / BUCKET))]
		if not list then
			return nil
		end
		for _, lot in list do
			if math.abs(lx - lot.X) <= lot.W / 2 + m and math.abs(lz - lot.Z) <= lot.D / 2 + m then
				return lot
			end
		end
		return nil
	end
	-- La parcela (el solar entero, no solo el edificio) en (lx, lz)
	function M.plotAt(lx: number, lz: number): { [string]: any }?
		M.lots()
		local list = bucket[bkey(math.floor(lx / BUCKET), math.floor(lz / BUCKET))]
		for _, lot in list or {} do
			local r = lot.Rect
			if lx >= r.X0 and lx <= r.X1 and lz >= r.Z0 and lz <= r.Z1 then
				return lot
			end
		end
		return nil
	end

	-- Lo más alto que hay en (lx, lz): el edificio (las plataformas no cuentan: la nave no choca con ellas). Altura local.
	function M.solidTop(lx: number, lz: number, margin: number?): number?
		if not M.inside(lx, lz, -40) then
			return nil
		end
		local lot = M.lotAt(lx, lz, margin)
		if lot and lot.Kind ~= "Plaza" and lot.Kind ~= "Parque" then
			return lot.Top
		end
		return nil
	end
	function M.landingBlocked(lx: number, lz: number): boolean
		if not M.inside(lx, lz, -20) then
			return false
		end
		local lot = M.lotAt(lx, lz, 6)
		return lot ~= nil and lot.Kind ~= "Plaza" and lot.Kind ~= "Parque"
	end

	---------------------------------------------------------------------
	-- Calles pintadas en el terreno (Ground)
	---------------------------------------------------------------------
	function M.streetAt(lx: number, lz: number): (boolean, boolean)
		if deck or not M.inside(lx, lz, -4) then
			return false, false
		end
		local d, isAv = M.streetDist(lx, lz)
		if d > 0 then
			return false, false
		end
		if City and City.inside(lx, lz, (City.Blend or 100) * 0.5) then
			return false, false
		end
		if not clearOf(lx, lz, -20, true) then
			return false, false
		end
		return true, isAv
	end

	---------------------------------------------------------------------
	-- Pasarelas (Deck): una por tramo de calle entre cruces; entran en el barrio hasta tocar un suelo
	---------------------------------------------------------------------
	local bridgeCache: { { [string]: number } }? = nil
	function M.bridges(): { { [string]: number } }
		if bridgeCache then
			return bridgeCache
		end
		local out: { { [string]: number } } = {}
		bridgeCache = out
		if not deck then
			return out
		end
		local kMax = math.ceil(R / G) + 1
		local function segOk(x: number, z: number): boolean
			if not M.inside(x, z, 4) or not groundOk(x, z) then
				return false
			end
			if City and City.inside(x, z, 0) then
				return false
			end
			return clearOf(x, z, -10, true)
		end
		for axis = 0, 1 do
			for k = -kMax, kMax do
				local hw = halfW(k)
				for j = -kMax, kMax - 1 do
					local a, b = j * G - hw, (j + 1) * G + hw
					local line = k * G
					local mx, mz = if axis == 0 then line else (a + b) / 2, if axis == 0 then (a + b) / 2 else line
					local ok = segOk(mx, mz)
					if ok then
						for _, t in { 0.1, 0.9 } do
							local u = a + (b - a) * t
							local px, pz = if axis == 0 then line else u, if axis == 0 then u else line
							if not groundOk(px, pz) or not M.inside(px, pz, 0) then
								ok = false
							end
						end
					end
					if ok then
						-- (cerca del barrio: la pasarela se alarga hasta su borde para no dejar huecos)
						if City then
							for _, endSign in { -1, 1 } do
								local reach = 0
								for step = 1, 12 do
									local u = (if endSign < 0 then a else b) + endSign * step * 10
									local px, pz = if axis == 0 then line else u, if axis == 0 then u else line
									if City.inside(px, pz, 0) then
										-- dentro del barrio: hasta tocar uno de sus suelos (o 60 studs como mucho)
										local into = 0
										while into < 60 and not (City.floorAt and City.floorAt(px, pz)) do
											into += 6
											px, pz = if axis == 0 then line else px + endSign * 6, if axis == 0 then pz + endSign * 6 else line
										end
										reach = step * 10 + into
										break
									end
									if not groundOk(px, pz) then
										break
									end
								end
								if reach > 0 then
									if endSign < 0 then
										a -= reach
									else
										b += reach
									end
								end
							end
						end
						if axis == 0 then
							table.insert(out, { X0 = line - hw, X1 = line + hw, Z0 = a, Z1 = b, Y = deckY })
						else
							table.insert(out, { X0 = a, X1 = b, Z0 = line - hw, Z1 = line + hw, Y = deckY })
						end
					end
				end
			end
		end
		return out
	end
	function M.bridgeAt(lx: number, lz: number): { [string]: number }?
		for _, b in M.bridges() do
			if lx >= b.X0 and lx <= b.X1 and lz >= b.Z0 and lz <= b.Z1 then
				return b
			end
		end
		return nil
	end

	-- El sitio seguro más cercano (Deck: quien se cae a la niebla sale a la pasarela o plataforma más cercana)
	function M.rescueSpot(lx: number, lz: number): (number, number)
		local bx, bz, bd = 0, 0, math.huge
		for _, b in M.bridges() do
			local px = math.clamp(lx, b.X0 + 2, b.X1 - 2)
			local pz = math.clamp(lz, b.Z0 + 2, b.Z1 - 2)
			local d = (px - lx) ^ 2 + (pz - lz) ^ 2
			if d < bd then
				bx, bz, bd = px, pz, d
			end
		end
		for _, lot in M.lots() do
			if lot.Kind == "Plaza" or lot.Kind == "Parque" then
				local d = (lot.X - lx) ^ 2 + (lot.Z - lz) ^ 2
				if d < bd then
					bx, bz, bd = lot.X, lot.Z, d
				end
			end
		end
		return bx, bz
	end

	-- ¿Se anda por aquí? (Deck: plataforma o pasarela)
	function M.walkable(lx: number, lz: number): boolean
		if not deck then
			return M.inside(lx, lz, 0)
		end
		return M.plotAt(lx, lz) ~= nil or M.bridgeAt(lx, lz) ~= nil
	end

	-- Recuento por tipo (pruebas y el resumen del servidor)
	function M.count(): { [string]: number }
		local c: { [string]: number } = {}
		for _, lot in M.lots() do
			c[lot.Kind] = (c[lot.Kind] or 0) + 1
		end
		return c
	end

	return M
end

return PlanetMetro
