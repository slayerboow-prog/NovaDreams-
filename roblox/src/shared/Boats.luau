-- Boats: barcos propios (lancha y la lancha «Gaviota» del pase de temporada).
--
-- Los barcos son vehículos más (Gameplay.Vehicles con Boat = true, ocultos del menú «Vehículos»):
-- se conducen con los mismos mandos que el coche (Controllers/Driving), llevan pasajeros y los
-- mueve el ordenador de quien conduce. Solo se sacan y se guardan en el PUERTO DEPORTIVO (costa
-- oeste, BoatService) y solo navegan por el MAR: se paran en la orilla, en la arena, en los
-- pantalanes y contra los barcos amarrados.
--
-- Aquí va lo que usan a la vez el servidor (BoatService), el cliente (Driving) y las pruebas:
-- qué barcos hay, la altura del mar y si un punto es mar abierto.

-- (por ReplicatedStorage: así también lo cargan el constructor del mapa y las pruebas)
local Shared = game:GetService("ReplicatedStorage").Shared
local CityPlan = require(Shared.CityPlan)
local Airport = require(Shared.Airport)

local Boats = {}

-- Altura del agua del mar (TerrainBuilder: agua de Y = -14 a Y = -2). El barco flota con la
-- línea de flotación aquí.
Boats.SeaLevel = -2
-- Lo que se hunde el casco: si el fondo (o algo sólido) está más alto que SeaLevel - Draft, no pasa
Boats.Draft = 1.5
-- Hasta dónde se puede alejar de la costa (el agua del terreno llega a 800 studs de los bordes)
Boats.Margin = 700

-- Barcos que existen (el orden del menú del puerto deportivo). Price = 0: no se vende (solo del pase)
Boats.Kinds = { "Lancha", "Gaviota" }
Boats.Info = {
	Lancha = { Price = 7500, Stage = "AdultoJoven", Text = "Lancha de paseo con fueraborda. Piloto y tres pasajeros." },
	Gaviota = { Price = 0, Season = true, Text = "Lancha blanca y oro con cabina y tu nombre en la popa. Piloto y cuatro pasajeros. Del pase de temporada." },
}

-- ¿Es un barco?
function Boats.isBoat(kind: any): boolean
	return type(kind) == "string" and Boats.Info[kind] ~= nil
end

-- Pequeño balanceo sobre las olas (t en segundos): cuánto sube y baja, y cuánto cabecea y escora
-- (radianes). Parado se mece; en marcha, algo más.
function Boats.bob(t: number, speed: number): (number, number, number)
	local fast = math.clamp(math.abs(speed) / 50, 0, 1)
	local heave = math.sin(t * 1.3) * 0.18 + math.sin(t * 2.9) * 0.06 * (1 + fast)
	local pitch = math.sin(t * 1.1 + 0.7) * math.rad(1.2 + 1.5 * fast) - math.rad(3) * fast -- (la proa se levanta al acelerar)
	local roll = math.sin(t * 0.9 + 1.9) * math.rad(1.6)
	return heave, pitch, roll
end

-- ¿El punto (x, z) es tierra? La isla de Valmar (CityPlan.Coast), las islas pequeñas y la tierra
-- ganada al mar del aeropuerto. (Ríos y lagos quedan dentro de la isla: los barcos son de mar.)
function Boats.isLand(x: number, z: number): boolean
	if CityPlan.inside(CityPlan.Coast, x, z) then
		return true
	end
	for _, island in CityPlan.Islands do
		local dx, dz = x - island.X, z - island.Z
		if dx * dx + dz * dz < island.R * island.R then
			return true
		end
	end
	local land = Airport.Land
	if x > land.X0 and x < land.X1 and z > land.Z0 and z < land.Z1 then
		return true
	end
	return false
end

-- ¿Se puede navegar por (x, z)? Mar (no tierra) y sin salir del mapa
function Boats.isSea(x: number, z: number): boolean
	local b = CityPlan.Bounds
	if x < b.MinX - Boats.Margin or x > b.MaxX + Boats.Margin or z < b.MinZ - Boats.Margin or z > b.MaxZ + Boats.Margin then
		return false
	end
	return not Boats.isLand(x, z)
end

-- ¿Cabe el barco aquí? El centro, la proa y la popa (y las esquinas de la proa) tienen que ser mar.
-- position = centro a la altura del agua, forward = hacia dónde mira (plano), size = su base
function Boats.hullAtSea(position: Vector3, forward: Vector3, size: Vector3): boolean
	local flat = Vector3.new(forward.X, 0, forward.Z)
	flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, -1)
	local right = Vector3.new(-flat.Z, 0, flat.X)
	local half, side = size.Z / 2, size.X / 2
	for _, p in {
		position,
		position + flat * half,
		position - flat * half,
		position + flat * half * 0.7 + right * side,
		position + flat * half * 0.7 - right * side,
	} do
		if not Boats.isSea(p.X, p.Z) then
			return false
		end
	end
	return true
end

-- ¿Puede el barco pasar de `from` a `to`? (mira el sitio de llegada y el camino, en pasos de 4 studs:
-- a toda velocidad un fotograma no se salta la orilla)
function Boats.canMove(from: Vector3, to: Vector3, forward: Vector3, size: Vector3): boolean
	local d = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local steps = math.max(1, math.ceil(d.Magnitude / 4))
	for i = 1, steps do
		if not Boats.hullAtSea(from + d * (i / steps), forward, size) then
			return false
		end
	end
	return true
end

return Boats
