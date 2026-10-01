-- FarmAnimals: los animales de granja de los campos de Valmar (cerdos, caballos, ovejas, cabras,
-- vacas y el toro), en sus cercados junto a la Carretera de Villaverde (entre la ciudad y Villaverde,
-- al sur de la carretera, junto a la boca de metro de Villaverde).
--
--   * Los cercados (vallas, comederos, abrevaderos, cuadra, charca de barro, pajar) los construye
--     server/World/Kit/AnimalKit con estos mismos datos; los animales los pinta cada jugador en su
--     dispositivo (Controllers/Wildlife + AnimalPose), solo cuando está cerca: pocos por cercado.
--   * Nunca salen de su cercado (FarmAnimals.pick / inside, con margen hasta la valla).
--   * Las ovejas van en rebaño (cerca unas de otras); el toro tiene su cercado para él solo.
--   * Caballos: en la cuadra hay un poste «Montar a caballo» (PetService): sale un caballo ensillado
--     que se lleva como los vehículos (Driving): al paso, al trote y al galope según la velocidad
--     (FarmAnimals.gait), con las patas animadas (Wildlife) y el jinete a horcajadas (RidePose).
--
-- Funciones puras: las prueba scripts/test-animals.luau.

local FarmAnimals = {}

export type Pen = {
	Id: string,
	Name: string,
	X0: number,
	X1: number,
	Z0: number, -- lado de la carretera (norte): ahí está la puerta
	Z1: number,
	Animals: { [string]: number },
	Order: { string },
	Feeder: { number }, -- { x, z } (comedero)
	Trough: { number }, -- { x, z } (abrevadero)
	Fence: string, -- "Madera" | "Fuerte" (toro)
	Mud: { number }?, -- { x, z, radio } (cerdos)
	Stable: boolean?, -- cuadra (caballos)
	Shelter: boolean?, -- cobertizo (ovejas y cabras)
}

FarmAnimals.GROUND_Y = -1 -- el terreno del campo (TerrainBuilder)
FarmAnimals.MARGIN = 2.5 -- distancia mínima del centro de un animal a la valla
FarmAnimals.FENCE_H = 4.2
FarmAnimals.SHOW_RADIUS = 220 -- se pintan si estás a menos de esto del cercado
FarmAnimals.ROAD_Z = -1850 -- la Carretera de Villaverde pasa por aquí (al norte de los cercados)

FarmAnimals.Pens = {
	{
		Id = "Vacas", Name = "Prado de las vacas", X0 = -2270, X1 = -2190, Z0 = -1790, Z1 = -1668,
		Animals = { Vaca = 4 }, Order = { "Vaca" }, Feeder = { -2255, -1700 }, Trough = { -2205, -1700 }, Fence = "Madera",
	},
	{
		Id = "Toro", Name = "Cercado del toro", X0 = -2178, X1 = -2136, Z0 = -1790, Z1 = -1748,
		Animals = { Toro = 1 }, Order = { "Toro" }, Feeder = { -2170, -1756 }, Trough = { -2144, -1756 }, Fence = "Fuerte",
	},
	{
		Id = "Rebano", Name = "Redil de ovejas y cabras", X0 = -2178, X1 = -2096, Z0 = -1736, Z1 = -1668,
		Animals = { Oveja = 5, Cabra = 3 }, Order = { "Oveja", "Cabra" }, Feeder = { -2168, -1676 }, Trough = { -2106, -1676 }, Fence = "Madera", Shelter = true,
	},
	{
		Id = "Cerdos", Name = "Pocilga", X0 = -2084, X1 = -2040, Z0 = -1790, Z1 = -1748,
		Animals = { Cerdo = 4 }, Order = { "Cerdo" }, Feeder = { -2076, -1754 }, Trough = { -2048, -1754 }, Fence = "Madera", Mud = { -2062, -1770, 7 },
	},
	{
		Id = "Caballos", Name = "Picadero", X0 = -2028, X1 = -1944, Z0 = -1790, Z1 = -1668,
		Animals = { Caballo = 3 }, Order = { "Caballo" }, Feeder = { -2018, -1676 }, Trough = { -1954, -1676 }, Fence = "Madera", Stable = true,
	},
} :: { Pen }

-- Poste para montar a caballo (junto a la puerta del picadero, por fuera)
FarmAnimals.HorseStation = { -1990, -1798 }
FarmAnimals.MAX_PER_PEN = 8 -- (prueba: pocos por grupo, por rendimiento)

function FarmAnimals.pen(id: string): Pen?
	for _, p in FarmAnimals.Pens do
		if p.Id == id then
			return p
		end
	end
	return nil
end

function FarmAnimals.center(pen: Pen): (number, number)
	return (pen.X0 + pen.X1) / 2, (pen.Z0 + pen.Z1) / 2
end

-- ¿Este punto está dentro del cercado (con margen hasta la valla)?
function FarmAnimals.inside(pen: Pen, x: number, z: number, margin: number?): boolean
	local m = margin or 0
	return x >= pen.X0 + m and x <= pen.X1 - m and z >= pen.Z0 + m and z <= pen.Z1 - m
end

-- Lo mete dentro (por si acaso: un empujón, un susto)
function FarmAnimals.clamp(pen: Pen, x: number, z: number): (number, number)
	local m = FarmAnimals.MARGIN
	return math.clamp(x, pen.X0 + m, pen.X1 - m), math.clamp(z, pen.Z0 + m, pen.Z1 - m)
end

-- ¿Cae dentro de la charca de barro, el cobertizo o la cuadra? (ahí no se ponen a pastar)
local function blocked(pen: Pen, x: number, z: number): boolean
	if pen.Stable and x > pen.X1 - 22 and z > pen.Z1 - 16 then
		return true -- la cuadra (esquina del fondo)
	end
	if pen.Shelter and x < pen.X0 + 18 and z > pen.Z1 - 14 then
		return true -- el cobertizo
	end
	return false
end

-- Un sitio al que ir dentro del cercado. near = { x, z, radio } para no ir lejos (rebaño, paseo corto).
-- rand() -> 0..1
function FarmAnimals.pick(pen: Pen, rand: () -> number, near: { number }?): (number, number)
	local m = FarmAnimals.MARGIN
	for _ = 1, 12 do
		local x, z
		if near then
			local a = rand() * math.pi * 2
			local r = rand() * near[3]
			x, z = near[1] + math.cos(a) * r, near[2] + math.sin(a) * r
		else
			x, z = pen.X0 + m + rand() * (pen.X1 - pen.X0 - 2 * m), pen.Z0 + m + rand() * (pen.Z1 - pen.Z0 - 2 * m)
		end
		if FarmAnimals.inside(pen, x, z, m) and not blocked(pen, x, z) then
			return x, z
		end
	end
	return FarmAnimals.clamp(pen, FarmAnimals.center(pen))
end

-- Dónde está el rebaño (media de las ovejas y cabras): las ovejas no se separan mucho de él
function FarmAnimals.flockCenter(points: { { number } }): (number, number)
	local x, z = 0, 0
	for _, p in points do
		x += p[1]
		z += p[2]
	end
	local n = math.max(#points, 1)
	return x / n, z / n
end
FarmAnimals.FLOCK_RADIUS = 9

---------------------------------------------------------------------
-- Montar a caballo
---------------------------------------------------------------------
-- Aire según la velocidad (studs/s): al paso, al trote y al galope. Rate = lo deprisa que mueve las
-- patas (pasos por segundo); Lift = cuánto sube y baja el cuerpo
FarmAnimals.Gaits = {
	{ Name = "Parado", Max = 0.8, Rate = 0, Lift = 0 },
	{ Name = "Al paso", Max = 9, Rate = 1.6, Lift = 0.05 },
	{ Name = "Al trote", Max = 20, Rate = 2.6, Lift = 0.16 },
	{ Name = "Al galope", Max = math.huge, Rate = 3.4, Lift = 0.32 },
}
FarmAnimals.HORSE_SPEED = 36 -- velocidad máxima al galope

function FarmAnimals.gait(speed: number): { Name: string, Max: number, Rate: number, Lift: number }
	for _, g in FarmAnimals.Gaits do
		if speed < g.Max then
			return g
		end
	end
	return FarmAnimals.Gaits[#FarmAnimals.Gaits]
end

-- Cuánto gira cada pata (radianes) en el paso del caballo montado: al paso y al trote en diagonal
-- (delantera izq. con trasera dcha.); al galope, las delanteras juntas y luego las traseras
function FarmAnimals.legSwing(leg: number, phase: number, speed: number): number
	local g = FarmAnimals.gait(speed)
	if g.Rate == 0 then
		return 0
	end
	local amp = if g.Name == "Al galope" then 0.75 elseif g.Name == "Al trote" then 0.55 else 0.35
	local offset
	if g.Name == "Al galope" then
		offset = if leg <= 2 then 0 else math.pi * 0.6
		if leg == 2 or leg == 4 then
			offset += 0.35
		end
	else
		offset = if leg == 1 or leg == 4 then 0 else math.pi
	end
	return math.sin(phase + offset) * amp
end

return FarmAnimals
