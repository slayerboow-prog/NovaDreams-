-- Breakables: qué se puede romper con una piedra y cómo vuela la piedra (cuentas puras, se prueban
-- fuera de Roblox: scripts/test-breakables.luau). Lo usan BreakService (servidor) y StoneThrow (cliente).
--
--   * Cristales: ventanas de casas y edificios, cristales de coches, de balcones… Solo los de tamaño
--     normal (una fachada entera de cristal o un escaparate de toda la manzana, no).
--   * Puertas: aguantan unos golpes y luego se caen.
--   * Piedras: se cogen del suelo de tierra, césped, arena o roca.

local Breakables = {}

Breakables.MaxStones = 3 -- piedras que puedes llevar a la vez
Breakables.ThrowSpeed = 90 -- studs por segundo
Breakables.GravityScale = 0.35 -- la piedra cae menos que con la gravedad del juego (que es muy fuerte)
Breakables.DoorHits = 12 -- pedradas que aguanta una puerta
Breakables.DoorHeal = 30 -- sin golpes durante este rato, la puerta se «recupera» (vuelve a aguantar todas)
Breakables.RepairSeconds = 120 -- lo roto se arregla solo pasado este rato
Breakables.MaxArea = 60 -- cristal o puerta más grande que esto: no se rompe

local GLASS: { [string]: boolean } = {
	Glass = true,
	WindowGlass = true,
	Windows = true,
	Windshield = true,
	RearWindow = true,
	SideWindow = true,
	SideWindowFront = true,
	SideWindowRear = true,
	BalconyGlass = true,
	CabWindow = true,
	FrontGlass = true,
	UpperGlass = true,
}

local DOORS: { [string]: boolean } = {
	Door = true,
	DoorPanel = true,
	OldDoor = true,
	BackDoor = true,
}

-- Lo que se coge del suelo
local STONY: { [string]: boolean } = {
	Grass = true,
	LeafyGrass = true,
	Ground = true,
	Sand = true,
	Mud = true,
	Rock = true,
	Pebble = true,
	Slate = true,
	Sandstone = true,
	Basalt = true,
}

-- Superficie de la cara grande (las dos medidas mayores)
function Breakables.area(size: Vector3): number
	local dims = { size.X, size.Y, size.Z }
	table.sort(dims)
	return dims[2] * dims[3]
end

-- ¿Es un cristal que se rompe? (y fino: un bloque de cristal macizo, no). De noche las ventanas
-- encendidas son de neón (WorldService): también cuentan.
function Breakables.isGlass(name: string, material: Enum.Material, size: Vector3): boolean
	if not GLASS[name] or (material ~= Enum.Material.Glass and material ~= Enum.Material.Neon) then
		return false
	end
	local thin = math.min(size.X, size.Y, size.Z) <= 0.6
	return thin and Breakables.area(size) <= Breakables.MaxArea
end

function Breakables.isDoor(name: string, size: Vector3): boolean
	return DOORS[name] == true and Breakables.area(size) <= Breakables.MaxArea and math.min(size.X, size.Y, size.Z) <= 1
end

function Breakables.canPickFrom(material: Enum.Material): boolean
	return STONY[material.Name] == true
end

-- Velocidad para lanzar desde `from` y dar en `target` (con la gravedad de la piedra). Tiro tenso:
-- el ángulo más bajo que llega. Si está demasiado lejos, a 45° (lo más lejos que llega).
function Breakables.launch(from: Vector3, target: Vector3, speed: number, gravity: number): Vector3
	local delta = target - from
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local x = flat.Magnitude
	local y = delta.Y
	if x < 0.05 then
		return Vector3.new(0, if y >= 0 then speed else -speed, 0)
	end
	local dir = flat / x
	local v2 = speed * speed
	local disc = v2 * v2 - gravity * (gravity * x * x + 2 * y * v2)
	local angle: number
	if disc < 0 then
		angle = math.rad(45)
	else
		angle = math.atan((v2 - math.sqrt(disc)) / (gravity * x))
	end
	return dir * (speed * math.cos(angle)) + Vector3.new(0, speed * math.sin(angle), 0)
end

-- Dónde está la piedra al cabo de t segundos
function Breakables.positionAt(from: Vector3, velocity: Vector3, gravity: number, t: number): Vector3
	return from + velocity * t + Vector3.new(0, -0.5 * gravity * t * t, 0)
end

-- Cuánto se oscurece una puerta según los golpes que lleva (se ve que se va estropeando)
function Breakables.doorDamage(hits: number): number
	return math.clamp(hits / Breakables.DoorHits, 0, 1) * 0.45
end

-- ¿Cuántos golpes lleva? Si hace mucho del último, empieza de cero
function Breakables.doorHits(previous: number, sinceLast: number): number
	if sinceLast > Breakables.DoorHeal then
		return 1
	end
	return previous + 1
end

-- Trozos de cristal según lo grande que era la ventana
function Breakables.shards(size: Vector3): number
	return math.clamp(math.floor(Breakables.area(size) / 3), 5, 14)
end

return Breakables
