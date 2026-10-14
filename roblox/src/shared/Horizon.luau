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

-- ¿Se ve esta pieza con la cámara en `eye`?
function Horizon.visible(piece: Piece, eye: Vector3): boolean
	if not piece.HideWithin then
		return true
	end
	local dx, dz = eye.X - piece.Center.X, eye.Z - piece.Center.Z
	return dx * dx + dz * dz > piece.HideWithin * piece.HideWithin
end

return Horizon
