-- CityPlan: el plano de la ciudad de Valmar (una sola fuente para todo).
--
-- De aquí salen: el terreno (TerrainBuilder), las carreteras principales (Kit/Roads), dónde va cada
-- barrio (Region), el mapa del HUD (MapUI) y el cartel de "dónde estás".
-- Coordenadas en studs. X = este, Z = sur (el norte es -Z). Valmar Centro está en (0, 0).
--
--                         MONTES DE VALMAR (montañas, lago de montaña)
--              ┌──────── DISTRITO NORTE (residencial familiar) ────────┐
--   DISTRITO   │                                                        │  ~río~  DISTRITO ESTE
--   OESTE      │   ┌──────────── RONDA DE VALMAR ────────────┐          │   ~~    (comercio y ocio,
--  (costa,     │   │           DISTRITO CENTRO                │          │   ~~     Playa Dorada)
--   lujo,      │   │  (rascacielos, plaza, estadio, estación) │          │   ~~ ──────────────────
--   parque     │   └──────────────────────────────────────────┘          │   ~~    DISTRITO
--   natural)   └──────── DISTRITO SUR (industria, puerto) ───────────────┘   ~~    UNIVERSITARIO
--                                                                              ~~        · Isla del Faro

local CityPlan = {}

-- Contorno de la isla (polígono, en orden)
CityPlan.Coast = {
	{ -3000, -3500 }, { -2200, -3700 }, { -1500, -3750 }, { -700, -3950 }, { 0, -3800 }, { 800, -3900 },
	{ 1600, -3700 }, { 2600, -3350 }, { 3400, -2850 }, { 3700, -2500 }, { 3950, -2000 }, { 4050, -1500 },
	{ 4250, -1000 }, { 4200, 0 }, { 4350, 450 }, { 4000, 800 }, { 3850, 1600 }, { 3550, 2400 },
	{ 3200, 2650 }, { 2950, 3000 }, { 2500, 3200 }, { 2100, 3350 }, { 1500, 3250 }, { 900, 3450 },
	{ 0, 3550 }, { -1000, 3450 }, { -1500, 3350 }, { -1900, 3150 }, { -2700, 2650 }, { -3050, 2250 },
	{ -3350, 1950 }, { -3500, 1550 }, { -3900, 1350 }, { -3750, 1000 }, { -4050, 0 }, { -4150, -1000 },
	{ -3950, -2000 }, { -4050, -2400 }, { -3600, -2850 },
}

-- Costas con acantilado (sin playa): tramos del contorno por índice de punto
CityPlan.Cliffs = { { 1, 9 }, { 37, 39 } }

-- Islas pequeñas: centro y radio
CityPlan.Islands = {
	{ Name = "Isla del Faro", X = 4450, Z = 2650, R = 170 },
	{ Name = "Islote", X = -4450, Z = 1900, R = 110 },
	{ Name = "Isla de las Gaviotas", X = 2900, Z = -3950, R = 140 },
}

-- Río de Valmar: baja de las montañas y desemboca en el sur
CityPlan.River = {
	Width = 110,
	Points = { { 1500, -3000 }, { 1450, -2200 }, { 1600, -1500 }, { 1450, -800 }, { 1560, -100 }, { 1450, 700 }, { 1600, 1400 }, { 1450, 2200 }, { 1500, 3300 }, { 1500, 3700 } },
}

-- Lagos
CityPlan.Lakes = {
	{ Name = "Lago del Parque Natural", X = -2750, Z = -520, R = 290 },
	{ Name = "Lago de Montaña", X = -1500, Z = -2950, R = 170 },
}

-- Montañas y colinas: centro, radio y altura de la cima (studs sobre el suelo)
CityPlan.Mountains = {
	{ X = -2600, Z = -3150, R = 380, H = 180, Rock = true },
	{ X = -1850, Z = -3350, R = 300, H = 150 },
	{ X = -800, Z = -3250, R = 360, H = 200, Rock = true },
	{ X = 150, Z = -3350, R = 330, H = 170 },
	{ X = 900, Z = -3150, R = 300, H = 140, Rock = true },
	{ X = 2200, Z = -3050, R = 340, H = 160 },
	{ X = 2900, Z = -2700, R = 260, H = 120 },
	{ X = -3450, Z = -2450, R = 330, H = 160, Rock = true },
	{ X = -3650, Z = -1500, R = 220, H = 90 },
	-- Colinas suaves
	{ X = -2150, Z = -2600, R = 220, H = 55 },
	{ X = -3300, Z = 700, R = 200, H = 50 },
	{ X = 3400, Z = -2300, R = 180, H = 45 },
}

-- Los 6 distritos (polígonos). Town = zona de la historia que contiene (o nil)
CityPlan.Districts = {
	{ Id = "Centro", Name = "Distrito Centro", Theme = "El corazón de Valmar", Icon = "🏙️", Color = { 50, 130, 255 },
		Poly = { { -1330, -1330 }, { 1330, -1330 }, { 1380, 0 }, { 1330, 1330 }, { -1330, 1330 }, { -1380, 0 } } },
	{ Id = "Norte", Name = "Distrito Norte", Theme = "Residencial y vida familiar", Icon = "🏡", Color = { 70, 190, 90 },
		Poly = { { -1330, -1330 }, { 1330, -1330 }, { 1380, -2350 }, { 600, -2650 }, { -600, -2650 }, { -1450, -2400 } } },
	{ Id = "Oeste", Name = "Distrito Oeste", Theme = "Costa, lujo y naturaleza", Icon = "🌴", Color = { 230, 70, 70 },
		Poly = { { -1450, -2400 }, { -1380, 0 }, { -1400, 3050 }, { -2700, 2650 }, { -3350, 1950 }, { -3750, 1000 }, { -4050, 0 }, { -4150, -1000 }, { -3950, -2000 }, { -3300, -2600 }, { -2300, -2500 } } },
	{ Id = "Este", Name = "Distrito Este", Theme = "Comercio, ocio y playa", Icon = "🛍️", Color = { 160, 90, 240 },
		Poly = { { 1700, -2600 }, { 2600, -2550 }, { 3400, -2500 }, { 3950, -2000 }, { 4150, -1000 }, { 4200, -250 }, { 1700, -250 } } },
	{ Id = "Universitario", Name = "Distrito Universitario", Theme = "Estudios y juventud", Icon = "🎓", Color = { 40, 200, 220 },
		Poly = { { 1700, 250 }, { 4200, 250 }, { 4000, 800 }, { 3850, 1600 }, { 3550, 2400 }, { 2950, 3000 }, { 2100, 3300 }, { 1700, 3100 } } },
	{ Id = "Sur", Name = "Distrito Sur", Theme = "Industria, trabajo y puerto", Icon = "🏭", Color = { 245, 190, 40 },
		Poly = { { -1330, 1330 }, { 1330, 1330 }, { 1350, 3250 }, { 900, 3400 }, { 0, 3500 }, { -1000, 3400 }, { -1400, 3050 } } },
}

-- Dónde va cada zona de la historia (su cuadrícula de 720 × 720 studs, centrada aquí)
CityPlan.Towns = {
	["Valmar Centro"] = { 0, 0 }, -- (fijo: la historia lo busca en el origen)
	["Distrito Financiero"] = { 0, -800 },
	["Valmar Norte"] = { -700, -1900 },
	["Los Pinos"] = { 700, -1900 },
	["Villaverde"] = { -2700, -1850 },
	["Playa Dorada"] = { 3550, -1000 },
	["Campus Valmar"] = { 2650, 1300 },
	["San Roque"] = { -650, 2250 },
}

-- Carreteras principales. Kind: Autovia (la más ancha), Avenida, Calle.
-- Cada carretera es una línea de puntos; donde se cruzan se hace un cruce, y en los nodos
-- marcados en Roundabouts, una rotonda. Donde pasan sobre el río se construye un puente.
CityPlan.Roads = {
	-- Ronda de Valmar (anillo alrededor del centro)
	{ Name = "Ronda Norte", Kind = "Autovia", Points = { { -1250, -1250 }, { 1250, -1250 } } },
	{ Name = "Ronda Este", Kind = "Autovia", Points = { { 1250, -1250 }, { 1250, 1250 } } },
	{ Name = "Ronda Sur", Kind = "Autovia", Points = { { 1250, 1250 }, { -1250, 1250 } } },
	{ Name = "Ronda Oeste", Kind = "Autovia", Points = { { -1250, 1250 }, { -1250, -1250 } } },
	-- Avenidas radiales
	{ Name = "Avenida del Norte", Kind = "Avenida", Points = { { 0, -1250 }, { 0, -2750 } } },
	{ Name = "Avenida del Sur", Kind = "Avenida", Points = { { 0, 1250 }, { 0, 3150 } } },
	{ Name = "Avenida del Oeste", Kind = "Avenida", Points = { { -1250, 0 }, { -2300, 0 }, { -3500, 150 } } },
	{ Name = "Avenida del Este", Kind = "Avenida", Points = { { 1250, 0 }, { 2400, 0 }, { 3850, 0 } } },
	-- Diagonales entre distritos
	{ Name = "Carretera de Villaverde", Kind = "Avenida", Points = { { -1250, -1250 }, { -1900, -1850 }, { -2340, -1850 } } },
	{ Name = "Carretera de Levante", Kind = "Avenida", Points = { { 1250, -1250 }, { 1900, -1800 }, { 3310, -1800 }, { 3310, -1360 } } },
	{ Name = "Avenida Universitaria", Kind = "Avenida", Points = { { 1250, 1250 }, { 1900, 1300 }, { 2290, 1300 } } },
	-- Calles que unen cada barrio con la red principal
	{ Name = "Calle Mayor del Norte", Kind = "Calle", Points = { { -340, -1900 }, { 340, -1900 } } },
	{ Name = "Calle de las Torres Oeste", Kind = "Calle", Points = { { -1250, -800 }, { -360, -800 } } },
	{ Name = "Calle de las Torres Este", Kind = "Calle", Points = { { 360, -800 }, { 1250, -800 } } },
	{ Name = "Calle de la Playa", Kind = "Calle", Points = { { 3550, 0 }, { 3550, -640 } } },
	{ Name = "Calle de San Roque", Kind = "Calle", Points = { { -290, 2250 }, { 0, 2250 } } },
	{ Name = "Carretera de la Costa Oeste", Kind = "Avenida", Points = { { -1250, 1250 }, { -2000, 1900 }, { -2700, 2300 } } },
	-- Carreteras de la costa y del puerto
	{ Name = "Paseo de Poniente", Kind = "Calle", Points = { { -3500, 150 }, { -3550, -1100 }, { -3350, -1900 } } },
	{ Name = "Paseo de Levante", Kind = "Calle", Points = { { 3850, 0 }, { 3750, 900 }, { 3450, 1900 } } },
	{ Name = "Calle del Puerto", Kind = "Calle", Points = { { 0, 3150 }, { 1100, 3150 } } },
	{ Name = "Carretera de los Montes", Kind = "Calle", Points = { { 0, -2750 }, { -900, -2750 }, { -1400, -2650 } } },
}

-- Rotondas (en estos puntos)
CityPlan.Roundabouts = {
	{ -1250, -1250 }, { 1250, -1250 }, { 1250, 1250 }, { -1250, 1250 },
	{ 0, -1250 }, { 0, 1250 }, { -1250, 0 }, { 1250, 0 },
	{ -2300, 0 }, { 2400, 0 }, { 0, -2750 }, { 0, 3150 },
}

-- Lugares especiales fuera de las cuadrículas (para Landmarks y el mapa)
CityPlan.Places = {
	Faro = { 4450, 2650 },
	PuertoMercancias = { 700, 3300 },
	Marina = { -3650, 1300 },
	Mirador = { 0, -3000 },
	Camping = { -2400, -900 },
}

CityPlan.Bounds = { MinX = -5000, MaxX = 5000, MinZ = -4400, MaxZ = 4300 }

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------

-- ¿El punto (x, z) está dentro del polígono?
function CityPlan.inside(poly: { { number } }, x: number, z: number): boolean
	local inside = false
	local j = #poly
	for i = 1, #poly do
		local xi, zi = poly[i][1], poly[i][2]
		local xj, zj = poly[j][1], poly[j][2]
		if (zi > z) ~= (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- Tramos (x0, x1) de una fila horizontal Z que caen dentro del polígono
function CityPlan.spans(poly: { { number } }, z: number): { { number } }
	local xs = {}
	local j = #poly
	for i = 1, #poly do
		local xi, zi = poly[i][1], poly[i][2]
		local xj, zj = poly[j][1], poly[j][2]
		if (zi > z) ~= (zj > z) then
			table.insert(xs, xi + (z - zi) / (zj - zi) * (xj - xi))
		end
		j = i
	end
	table.sort(xs)
	local spans = {}
	for k = 1, #xs - 1, 2 do
		table.insert(spans, { xs[k], xs[k + 1] })
	end
	return spans
end

-- Distancia de un punto a un segmento
function CityPlan.segmentDistance(x: number, z: number, ax: number, az: number, bx: number, bz: number): number
	local dx, dz = bx - ax, bz - az
	local len2 = dx * dx + dz * dz
	local t = if len2 > 0 then math.clamp(((x - ax) * dx + (z - az) * dz) / len2, 0, 1) else 0
	local px, pz = ax + t * dx, az + t * dz
	return math.sqrt((x - px) ^ 2 + (z - pz) ^ 2)
end

-- Distancia al río (al centro del cauce)
function CityPlan.riverDistance(x: number, z: number): number
	local best = math.huge
	local pts = CityPlan.River.Points
	for i = 1, #pts - 1 do
		best = math.min(best, CityPlan.segmentDistance(x, z, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2]))
	end
	return best
end

function CityPlan.districtAt(x: number, z: number): { [string]: any }?
	for _, d in CityPlan.Districts do
		if CityPlan.inside(d.Poly, x, z) then
			return d
		end
	end
	return nil
end

return CityPlan
