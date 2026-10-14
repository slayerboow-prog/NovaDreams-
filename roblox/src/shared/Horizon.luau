-- Horizon: las montañas que se ven a lo lejos (cuentas puras; las pinta client/Controllers/Horizon y
-- se prueban fuera de Roblox: scripts/test-graphics.luau).
--
--   * Las montañas de verdad (terreno, CityPlan.Mountains) quedan a miles de studs de la ciudad y la
--     carga por zonas (StreamingTargetRadius) no las trae hasta que te acercas: desde la calle no se
--     veían. Aquí cada una tiene una «silueta» (elipsoide de una pieza, algo más pequeña que el
--     terreno para quedar dentro de él) que solo se ve de lejos; al acercarte se esconde y ya está
--     el terreno de verdad.
--   * Sierra lejana al otro lado del mar (norte, noroeste y noreste), mucho más allá del agua y de
--     cualquier cosa jugable: capas de montañas azuladas por la bruma que dan profundidad al fondo.
--     Solo en los niveles gráficos Medio y Alto (Graphics.FarRange).
-- Las piezas no chocan, no se pueden tocar ni consultar y no echan sombra: solo se ven.

local CityPlan = require(script.Parent.CityPlan)

local Horizon = {}

local rgb = Color3.fromRGB

export type Piece = {
	Name: string,
	Center: Vector3, -- centro del elipsoide (la mitad de abajo queda bajo el suelo o el mar)
	Size: Vector3,
	Color: Color3,
	Material: Enum.Material,
	HideWithin: number?, -- se esconde si la cámara está a menos de esto (en horizontal) del centro
	Far: boolean, -- de la sierra lejana (solo Medio y Alto)
	Box: boolean?, -- losa (caja) en vez de elipsoide (suelo lejano)
	Aerial: boolean?, -- solo se ve desde el aire (cámara por encima de Horizon.AerialFrom)
}

-- A partir de qué distancia (horizontal, desde el borde de la montaña) se ve la silueta. La carga
-- por zonas trae el terreno a ~770 studs: por debajo de esto, ya está el de verdad.
Horizon.ShowBeyond = 900
Horizon.MaxSize = 2048
-- Margen mínimo entre el borde del mar (CityPlan.Bounds + 800) y la sierra lejana
Horizon.SeaMargin = 900

-- Silueta de una montaña del terreno: TerrainBuilder hace una bola de radio R con la cima a H; su
-- base (a Y = 0) mide sqrt(R² - (R - H)²). El elipsoide va un poco por dentro (90 % de ancho y
-- 85 % de alto) para no asomar por el terreno cuando los dos se ven a la vez.
function Horizon.mountainPieces(): { Piece }
	local out: { Piece } = {}
	for i, m in CityPlan.Mountains do
		local base = math.sqrt(math.max(m.R * m.R - (m.R - m.H) ^ 2, 1))
		local a, b = base * 0.9, m.H * 0.85
		table.insert(out, {
			Name = "Monte" .. i,
			Center = Vector3.new(m.X, 0, m.Z),
			Size = Vector3.new(a * 2, b * 2, a * 2),
			Color = rgb(78, 104, 64),
			Material = Enum.Material.Grass,
			HideWithin = base + Horizon.ShowBeyond,
			Far = false,
		})
		if m.Rock then
			local r = m.R * 0.42
			table.insert(out, {
				Name = "Cumbre" .. i,
				Center = Vector3.new(m.X, m.H * 0.62, m.Z),
				Size = Vector3.new(r * 1.3, m.H * 0.5, r * 1.3),
				Color = rgb(128, 122, 112),
				Material = Enum.Material.Rock,
				HideWithin = base + Horizon.ShowBeyond,
				Far = false,
			})
		end
	end
	return out
end

-- Sierra lejana: picos en arco al norte de la isla, en dos filas (la de atrás más alta y más
-- azulada por la distancia). Siempre la misma (semilla fija).
function Horizon.farPieces(): { Piece }
	local out: { Piece } = {}
	local b = CityPlan.Bounds
	local seaEdge = b.MinZ - 800 -- (TerrainBuilder: el mar llega hasta aquí)
	local seed = 7
	local function rnd(): number
		seed = (seed * 16807) % 2147483647
		return (seed - 1) / 2147483646
	end
	-- (Roblox no deja piezas de más de 2048 studs por lado: alto y ancho, con tope)
	local rows = {
		{ Z = seaEdge - Horizon.SeaMargin - 700, Count = 13, H = { 420, 700 }, W = { 700, 1000 }, Color = rgb(92, 112, 120) },
		{ Z = seaEdge - Horizon.SeaMargin - 2200, Count = 11, H = { 760, 1000 }, W = { 850, 1000 }, Color = rgb(118, 138, 158) },
	}
	for r, row in rows do
		local x0, x1 = b.MinX - 2500, b.MaxX + 2500
		for i = 1, row.Count do
			local t = (i - 0.5 + (rnd() - 0.5) * 0.6) / row.Count
			local x = x0 + (x1 - x0) * t
			-- Los extremos se curvan hacia el sur (arco que abraza el horizonte del norte), sin acercarse
			local bend = ((t - 0.5) * 2) ^ 2
			local h = row.H[1] + (row.H[2] - row.H[1]) * rnd()
			local w = row.W[1] + (row.W[2] - row.W[1]) * rnd()
			local depth = w * (0.8 + rnd() * 0.3)
			-- (el borde de delante nunca se acerca al mar más que SeaMargin)
			local z = math.min(row.Z + bend * 400 + (rnd() - 0.5) * 300, seaEdge - Horizon.SeaMargin - depth / 2)
			table.insert(out, {
				Name = ("Sierra%d_%d"):format(r, i),
				Center = Vector3.new(x, -40, z),
				Size = Vector3.new(w * 2, h * 2, depth),
				Color = row.Color:Lerp(rgb(70, 90, 80), rnd() * 0.25),
				Material = Enum.Material.Rock,
				HideWithin = nil,
				Far = true,
			})
		end
	end
	return out
end

---------------------------------------------------------------------
-- Paisaje lejano (v118, docs/paisaje/paisaje.md): la isla y el mar más allá de lo cargado
---------------------------------------------------------------------
-- La carga por zonas solo trae el terreno (y el agua) a unos 770 studs. Desde el avión, más allá no
-- había NADA: la bruma lo tapaba de azul pálido (la queja del dueño). Aquí, con el mapa del relieve
-- (shared/Relief, horneado con la ciudad):
--   * Suelo lejano: losas planas (sin choque ni sombra) por DEBAJO del terreno de verdad (Y = -2,4 en
--     tierra, bajo la superficie del agua en el mar): donde el terreno está cargado lo tapa él y no
--     hace falta esconderlas; más allá se ven la isla (verde, gris donde hay ciudad, arena en la costa)
--     y el mar (turquesa junto a la costa, azul hondo mar adentro). Solo DESDE EL AIRE (Aerial: la
--     cámara por encima de AerialFrom): a pie no se ven nunca (ni dentro del metro ni buceando).
--   * Lomas lejanas: un elipsoide por trozo de relieve (como las montañas de siempre), que se esconde
--     al acercarte (entonces ya está el terreno de verdad).
Horizon.AerialFrom = 50 -- studs de altura de la cámara desde los que se ve el suelo lejano
Horizon.HomeBox = 12000 -- solo con la cámara sobre Valmar (|x| y |z| menores que esto)
-- Sitios en el cielo donde no se pinta el suelo lejano: la isla del sueño del prólogo (World/Kit/DreamIsland,
-- a 700 studs sobre el mar del noroeste: es un sueño, sin el mundo debajo)
Horizon.Exclude = { { X = -3400, Z = -3400, R = 1200, MinY = 300 } }
Horizon.GroundCell = 128 -- lado de la rejilla del suelo lejano (luego se juntan en rectángulos)
Horizon.NearBox = 7168 -- hasta aquí (|x|, |z|) rejilla fina; más allá, mar en losas de 2048
Horizon.FarSea = 18432 -- hasta dónde llega el mar lejano
Horizon.HillCell = 192 -- trozo de relieve por silueta de loma
Horizon.HillMin = 10 -- altura media mínima para poner silueta
Horizon.Colors = {
	Green = rgb(72, 112, 48),
	City = rgb(150, 146, 140),
	Sand = rgb(214, 198, 158),
	Rock = rgb(116, 110, 98),
	Shallow = rgb(38, 148, 160),
	Water = rgb(26, 112, 140),
	Deep = rgb(16, 70, 112),
}
Horizon.GroundY = { Green = -2.4, City = -2.4, Sand = -2.4, Rock = -2.4, Shallow = -2.6, Water = -2.6, Deep = -2.8 }

local function coastDistance(x: number, z: number): number
	local coast = CityPlan.Coast
	local best = math.huge
	local j = #coast
	for i = 1, #coast do
		best = math.min(best, CityPlan.segmentDistance(x, z, coast[j][1], coast[j][2], coast[i][1], coast[i][2]))
		j = i
	end
	return best
end

-- Qué hay en una celda del suelo lejano
function Horizon.groundClass(field: any, x: number, z: number): string
	local Relief = require(script.Parent.Relief)
	local inside = CityPlan.inside(CityPlan.Coast, x, z)
	if not inside then
		for _, island in CityPlan.Islands do
			if (x - island.X) ^ 2 + (z - island.Z) ^ 2 < (island.R - 20) ^ 2 then
				return "Green"
			end
		end
		return if coastDistance(x, z) < 260 then "Shallow" else "Deep"
	end
	for _, lake in CityPlan.Lakes do
		if (x - lake.X) ^ 2 + (z - lake.Z) ^ 2 < lake.R * lake.R then
			return "Water"
		end
	end
	if CityPlan.riverDistance(x, z) < CityPlan.River.Width / 2 then
		return "Water"
	end
	if coastDistance(x, z) < 70 then
		return "Sand"
	end
	if field and Relief.height(field, x, z) > 170 then
		return "Rock"
	end
	if field and Relief.builtAt(field, x, z) > 0.45 then
		return "City"
	end
	return "Green"
end

-- Las losas del suelo lejano (rectángulos juntados por filas y columnas). pause (opcional): se llama
-- cada pocas filas (el cliente suelta el hilo: son unos 12.000 puntos que mirar)
function Horizon.groundPieces(field: any, pause: (() -> ())?): { Piece }
	local out: { Piece } = {}
	local C = Horizon.GroundCell
	local N = Horizon.NearBox
	local cols = math.floor(2 * N / C)
	-- 1) cada fila: tramos del mismo tipo (como mucho MaxSize de largo)
	local rows: { { { number } } } = {}
	local classes: { [number]: string } = {}
	local classIndex: { [string]: number } = {}
	for j = 0, cols - 1 do
		if pause and j % 6 == 5 then
			pause()
		end
		local z = -N + (j + 0.5) * C
		local runs = {}
		local start, current = 0, nil :: string?
		for i = 0, cols do
			local class = if i < cols then Horizon.groundClass(field, -N + (i + 0.5) * C, z) else nil
			if class ~= current or (i - start) * C >= Horizon.MaxSize then
				if current then
					local index = classIndex[current]
					if not index then
						index = #classes + 1
						classes[index] = current
						classIndex[current] = index
					end
					table.insert(runs, { start, i, index })
				end
				start, current = i, class
			end
		end
		rows[j + 1] = runs
	end
	-- 2) juntar en vertical los tramos iguales de filas seguidas
	local open: { [string]: { number } } = {}
	local function emit(r: { number })
		local class = classes[r[3]]
		local x0, x1 = -N + r[1] * C, -N + r[2] * C
		local z0, z1 = -N + r[4] * C, -N + r[5] * C
		table.insert(out, {
			Name = "Suelo" .. class,
			Center = Vector3.new((x0 + x1) / 2, Horizon.GroundY[class], (z0 + z1) / 2),
			Size = Vector3.new(x1 - x0, 1, z1 - z0),
			Color = Horizon.Colors[class],
			Material = Enum.Material.SmoothPlastic,
			HideWithin = nil,
			Far = true,
			Box = true,
			Aerial = true,
		})
	end
	for j, runs in rows do
		local nextOpen: { [string]: { number } } = {}
		for _, run in runs do
			local key = run[1] .. ":" .. run[2] .. ":" .. run[3]
			local o = open[key]
			if o and (j - o[4]) * C < Horizon.MaxSize then
				o[5] = j
				nextOpen[key] = o
				open[key] = nil
			else
				nextOpen[key] = { run[1], run[2], run[3], j - 1, j }
			end
		end
		for _, o in open do
			emit(o)
		end
		open = nextOpen
	end
	for _, o in open do
		emit(o)
	end
	-- 3) mar lejano alrededor, en losas grandes
	local S = Horizon.MaxSize
	for x = -Horizon.FarSea, Horizon.FarSea - S, S do
		for z = -Horizon.FarSea, Horizon.FarSea - S, S do
			local outside = x >= N or x + S <= -N or z >= N or z + S <= -N
			if outside then
				table.insert(out, {
					Name = "SueloDeep",
					Center = Vector3.new(x + S / 2, Horizon.GroundY.Deep, z + S / 2),
					Size = Vector3.new(S, 1, S),
					Color = Horizon.Colors.Deep,
					Material = Enum.Material.SmoothPlastic,
					HideWithin = nil,
					Far = true,
					Box = true,
					Aerial = true,
				})
			end
		end
	end
	return out
end

-- Siluetas de las lomas del relieve (elipsoides), para verlas de lejos
function Horizon.reliefPieces(field: any): { Piece }
	local out: { Piece } = {}
	if not field then
		return out
	end
	local Relief = require(script.Parent.Relief)
	local H = Horizon.HillCell
	local x1 = field.MinX + (field.NX - 1) * field.Cell
	local z1 = field.MinZ + (field.NZ - 1) * field.Cell
	for z = field.MinZ, z1 - H, H do
		for x = field.MinX, x1 - H, H do
			local sum, top = 0, 0
			for a = 0, 3 do
				for b = 0, 3 do
					local h = Relief.height(field, x + (a + 0.5) * H / 4, z + (b + 0.5) * H / 4)
					sum += h
					top = math.max(top, h)
				end
			end
			local mean = sum / 16
			if mean >= Horizon.HillMin then
				local h = (mean + top) / 2
				local cx, cz = x + H / 2, z + H / 2
				table.insert(out, {
					Name = "Loma",
					Center = Vector3.new(cx, Relief.Base - 2, cz),
					Size = Vector3.new(H * 1.55, math.min(h * 2 * 0.92, Horizon.MaxSize), H * 1.55),
					Color = if h > 170 then rgb(112, 112, 100) else rgb(64, 100, 46):Lerp(rgb(52, 80, 42), math.clamp(h / 200, 0, 1)),
					Material = Enum.Material.SmoothPlastic,
					HideWithin = Horizon.ShowBeyond - 200 + H,
					Far = true,
				})
			end
		end
	end
	return out
end

-- ¿Se ve esta pieza con la cámara en `eye`?
-- noAerial: nada de suelo lejano (dentro de un interior: las salas flotan en el cielo)
function Horizon.visible(piece: Piece, eye: Vector3, noAerial: boolean?): boolean
	if piece.Aerial and (noAerial or eye.Y < Horizon.AerialFrom or math.abs(eye.X) > Horizon.HomeBox or math.abs(eye.Z) > Horizon.HomeBox) then
		return false -- (a pie, o lejos de Valmar: la arena del combate aéreo, Tefra…)
	end
	if piece.Aerial then
		for _, e in Horizon.Exclude do
			if eye.Y > e.MinY and (eye.X - e.X) ^ 2 + (eye.Z - e.Z) ^ 2 < e.R * e.R then
				return false
			end
		end
	end
	if not piece.HideWithin then
		return true
	end
	local dx, dz = eye.X - piece.Center.X, eye.Z - piece.Center.Z
	return dx * dx + dz * dz > piece.HideWithin * piece.HideWithin
end

return Horizon
