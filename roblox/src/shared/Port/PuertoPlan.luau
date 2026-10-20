-- PuertoPlan: el plano del PUERTO DE VALMAR (Distrito Sur, costa sur), en cuentas puras.
--
-- Una sola fuente para todo lo del puerto (docs/mapa/puerto.md):
--   * World/Kit/Puerto      construye el puerto con piezas (muelles, grúas, contenedores, barcos…)
--   * World/TerrainBuilder  excava la dársena (agua de verdad junto a los muelles)
--   * shared/Boats          la dársena es mar (los barcos entran), los muelles no
--   * Controllers/Wildlife  gaviotas sobre el puerto
--   * scripts/test-puerto   lo comprueba todo
--
-- Coordenadas del mundo en studs: X = este, Z = sur (el mar está al SUR). La costa (CityPlan.Coast)
-- NO cambia: la dársena se excava DENTRO de la tierra del puerto (la explanada de tierra que había),
-- y los diques (espigones) salen al mar sobre el fondo de siempre.
--
--             Calle del Puerto (Z = 3150) ─────────── boca de metro ──
--      Z 3176 ┌ valla ── naves ── CONTROL ── patio de contenedores ─┐ oficinas
--             │ (almacenes)       (aduana)   (5 filas × 2 bloques)   │ del puerto
--      Z 3262 │                  ═══ carril de las grúas (lado tierra) ══════
--      Z 3292 │ lonja · hielo    ═══ carril de las grúas (lado mar) ═════════
--      Z 3300 │ muelle   ┌──────────── MUELLE DE CONTENEDORES (buque) ─────┐ muelle
--             │ pesquero │ pantalán de pesca          DÁRSENA (agua)       │ este
--             │          │ pantalán deportivo                              │ (remolcadores)
--             │ estación │                                                 │
--             │ marítima └─ dique oeste (Z 3560)   bocana     ┌── dique de abrigo ──┘
--             │ (barca al faro)                       Z 3586 ─┴ tetrápodos · baliza

local Shared = game:GetService("ReplicatedStorage").Shared
local CityPlan = require(Shared.CityPlan)

local PuertoPlan = {}

export type Rect = { X0: number, X1: number, Z0: number, Z1: number }

local function rect(x0: number, x1: number, z0: number, z1: number): Rect
	return { X0 = x0, X1 = x1, Z0 = z0, Z1 = z1 }
end

-- Alturas
PuertoPlan.Ground = 1 -- cara de arriba de los muelles y de la explanada (= la acera: Street.WALK_TOP)
PuertoPlan.SeaLevel = -2 -- agua del mar (TerrainBuilder / Boats.SeaLevel)
PuertoPlan.BasinFloor = -20 -- fondo de la dársena dragada (el mar abierto del puerto sigue a -14)
PuertoPlan.WallBottom = -22 -- pie de los muros de los muelles (bajo el fondo)
PuertoPlan.BreakwaterTop = 3 -- el dique de abrigo es un poco más alto que los muelles
PuertoPlan.ParapetTop = 7 -- y tiene un espaldón (muro) hacia el mar

-- Todo el recinto del puerto (lo que es «el puerto»: no se plantan árboles ni se pone nada más)
PuertoPlan.Area = rect(310, 900, 3172, 3640)

-- La DÁRSENA: agua de verdad, excavada en la tierra del puerto y abierta al mar por el sur
PuertoPlan.Basin = rect(470, 850, 3300, 3560)

-- Los MUELLES (bloques de hormigón macizos, de WallBottom a Ground) que rodean la dársena
PuertoPlan.Quays = {
	North = rect(440, 880, 3288, 3300), -- muelle de contenedores (cara al agua en Z = 3300)
	West = rect(440, 470, 3300, 3560), -- muelle pesquero y dique oeste (cara al agua en X = 470)
	East = rect(850, 880, 3300, 3600), -- muelle este (cara al agua en X = 850), sigue mar adentro
}
-- Dique de abrigo: sale del muelle este hacia el oeste y cierra la bocana por el sur
PuertoPlan.Breakwater = rect(700, 884, 3586, 3612)
-- Baliza verde en la punta del dique (NO es el Faro de la Punta: ese está en Playa Dorada y está apagado)
PuertoPlan.Beacon = Vector3.new(712, PuertoPlan.BreakwaterTop, 3599)

-- Explanadas (losas de hormigón sobre la tierra, de Y = -1 a Ground)
PuertoPlan.Aprons = {
	rect(320, 760, 3176, 3288), -- explanada norte: naves, control, patio de contenedores y grúas
	rect(760, 880, 3205, 3288), -- explanada norte-este (al sur de la boca de metro): oficinas
	rect(320, 440, 3288, 3496), -- explanada oeste: lonja, fábrica de hielo y estación marítima
	rect(880, 896, 3288, 3448), -- franja del muelle este (hasta la playa)
}
-- Lo que el puerto NO toca (de los demás): la boca de metro, la calle y sus paradas, el bosque y la playa
PuertoPlan.Keep = {
	{ Name = "Boca de metro del Puerto", Rect = rect(760, 910, 3130, 3200) },
	{ Name = "Calle del Puerto", Rect = rect(0, 1140, 3130, 3171) },
	{ Name = "Bosque del oeste", Rect = rect(130, 305, 3260, 3390) },
	{ Name = "Playa del sur (palmeras)", Rect = rect(901, 1460, 3240, 3460) },
}

-- Muelle de contenedores: el buque, las grúas y sus carriles
PuertoPlan.Ship = { X = 640, Z = 3321, Length = 230, Beam = 34, Deck = 7, Keel = -12 } -- proa al oeste
PuertoPlan.Cranes = { 575, 645, 715 } -- X de cada grúa pórtico (STS)
PuertoPlan.CraneRails = { Sea = 3292, Land = 3262, X0 = 470, X1 = 840 }
PuertoPlan.CraneSpan = 22 -- entre las patas de una grúa (a lo largo del muelle)
PuertoPlan.CraneHeight = 36 -- altura de la viga del pórtico
PuertoPlan.Boom = { Y = 46, Back = 3232, Out = 3372 } -- pluma: de Z = 3232 (contrapluma) a 3372 (sobre el agua)

-- Patio de contenedores (dos bloques de 5 filas)
PuertoPlan.Yard = rect(480, 750, 3192, 3256)
PuertoPlan.YardBlocks = { rect(486, 608, 3196, 3236), rect(622, 744, 3196, 3236) }
PuertoPlan.Container = { Long = 34, Short = 17, Wide = 6.8, High = 7.2 } -- 40 y 20 pies (escala del juego)

-- Control de acceso (aduana) con barreras: entrada desde la Calle del Puerto
PuertoPlan.Gate = { X = 495, Z0 = 3172, Z1 = 3200, LaneIn = 484, LaneOut = 506 }

-- Pantalanes (flotantes, a ras de agua) del muelle pesquero y deportivo
PuertoPlan.FloatTop = -0.8 -- cara de arriba de un pantalán flotante
PuertoPlan.Pontoons = {
	{ Name = "PantalanPesca", Z = 3420, X0 = 470, X1 = 584, Kind = "Pesca" },
	{ Name = "PantalanDeportivo", Z = 3490, X0 = 470, X1 = 566, Kind = "Recreo" },
}

-- Estación marítima (barca a la Isla del Faro): sala de espera en tierra y rampa al barco por el oeste
PuertoPlan.FerryHall = rect(336, 410, 3446, 3480)
PuertoPlan.FerryBerth = Vector3.new(432, PuertoPlan.SeaLevel, 3532) -- el barco, amarrado al oeste del dique oeste
PuertoPlan.FerryArrival = Vector3.new(455, PuertoPlan.Ground + 3, 3522) -- donde te deja la barca al volver

-- Escaleras de gato en los muros de la dársena (para salir del agua): {x, z, normal hacia el agua}
PuertoPlan.Ladders = {
	{ 500, 3300.9, 0, 1 }, { 790, 3300.9, 0, 1 },
	{ 470.9, 3370, 1, 0 }, { 470.9, 3455, 1, 0 }, { 470.9, 3540, 1, 0 },
	{ 849.1, 3360, -1, 0 }, { 849.1, 3470, -1, 0 }, { 849.1, 3550, -1, 0 },
}

-- Barco de pesca (FishingKit.boat): fondeado mar adentro, donde siempre (alta mar)
PuertoPlan.FishingBoat = Vector3.new(640, 0, 3716)

-- Centro y radio (gaviotas, mapa…)
PuertoPlan.Center = Vector3.new(610, 0, 3380)
PuertoPlan.Radius = 330

---------------------------------------------------------------------
-- Cuentas
---------------------------------------------------------------------

function PuertoPlan.inRect(r: Rect, x: number, z: number, margin: number?): boolean
	local m = margin or 0
	return x > r.X0 - m and x < r.X1 + m and z > r.Z0 - m and z < r.Z1 + m
end

function PuertoPlan.overlaps(a: Rect, b: Rect): boolean
	return a.X0 < b.X1 and b.X0 < a.X1 and a.Z0 < b.Z1 and b.Z0 < a.Z1
end

-- ¿Es agua de la dársena (dentro de la isla, pero mar para los barcos)?
function PuertoPlan.inBasin(x: number, z: number): boolean
	return PuertoPlan.inRect(PuertoPlan.Basin, x, z)
end

-- ¿Es un muelle o el dique (sólido)?
function PuertoPlan.onQuay(x: number, z: number): boolean
	for _, q in PuertoPlan.Quays do
		if PuertoPlan.inRect(q, x, z) then
			return true
		end
	end
	return PuertoPlan.inRect(PuertoPlan.Breakwater, x, z)
end

-- ¿Cerca del puerto? (gaviotas)
function PuertoPlan.near(x: number, z: number, extra: number?): boolean
	local dx, dz = x - PuertoPlan.Center.X, z - PuertoPlan.Center.Z
	local r = PuertoPlan.Radius + (extra or 0)
	return dx * dx + dz * dz < r * r
end

-- Z de la costa (CityPlan.Coast) en esta X, en el tramo sur del puerto (la orilla más al sur)
function PuertoPlan.coastZ(x: number): number
	local best = -math.huge
	local pts = CityPlan.Coast
	for i = 1, #pts do
		local a, b = pts[i], pts[i % #pts + 1]
		if (a[1] - x) * (b[1] - x) <= 0 and a[1] ~= b[1] then
			local z = a[2] + (x - a[1]) / (b[1] - a[1]) * (b[2] - a[2])
			if z > best and z > 3000 then
				best = z
			end
		end
	end
	return best
end

return PuertoPlan
