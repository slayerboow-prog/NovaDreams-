-- Breakables: qué se puede romper con una piedra y cómo vuela la piedra (cuentas puras, se prueban
-- fuera de Roblox: scripts/test-breakables.luau). Lo usan BreakService (servidor) y StoneThrow (cliente).
--
--   * Cristales: ventanas de casas y edificios, cristales de coches, de balcones… Solo los de tamaño
--     normal (una fachada entera de cristal o un escaparate de toda la manzana, no).
--   * Puertas: aguantan unos golpes y luego se caen.
--   * Piedras: se cogen del suelo de tierra, césped, arena o roca.
--   * Lo rompen las piedras, las balas de las armas de verdad (no las de agua ni de pintura), los
--     golpes fuertes y los vehículos a velocidad. Los escaparates y las franjas de ventanas grandes
--     se rompen por tramos (el trozo donde das), no enteros.
--   * Todo se arregla solo y rápido (cristal 20–30 s, puertas 30–45 s), nunca con alguien en el
--     hueco, y con un tope de cosas rotas a la vez (BreakService).

local Breakables = {}

Breakables.MaxStones = 3 -- piedras que puedes llevar a la vez
Breakables.ThrowSpeed = 90 -- studs por segundo
Breakables.GravityScale = 0.35 -- la piedra cae menos que con la gravedad del juego (que es muy fuerte)
Breakables.DoorHits = 12 -- pedradas que aguanta una puerta
Breakables.DoorHeal = 30 -- sin golpes durante este rato, la puerta se «recupera» (vuelve a aguantar todas)
Breakables.RepairSeconds = 20 -- lo roto se arregla solo pasado este rato (como poco; ver repairDelay)
Breakables.MaxArea = 60 -- cristal o puerta más grande que esto: no se rompe entero (por tramos, ver glassKind)

-- Cuándo se arregla solo cada cosa (segundos: de … a …)
Breakables.Repair = {
	Glass = { 20, 30 },
	Door = { 30, 45 },
}
Breakables.RepairRetry = 2 -- si hay alguien en el hueco, se vuelve a mirar pasado este rato
Breakables.FadeIn = 0.8 -- lo arreglado aparece poco a poco (segundos)

-- Puertas: aguante y lo que quita cada golpe (12 pedradas, 4 balazos, 5 patadas, 3 golpes fuertes;
-- un vehículo rápido la tira de una)
Breakables.DoorHealth = 100
Breakables.DoorDamage = {
	Stone = 9,
	Bullet = 26,
	Melee = 20,
	MeleeHeavy = 34,
}
Breakables.VehicleGlassSpeed = 12 -- studs/s: a partir de aquí un vehículo rompe el cristal
Breakables.VehicleDoorSpeed = 22 -- y a partir de aquí tira una puerta de golpe (más despacio, la daña)

-- Escaparates y franjas de ventanas grandes: se rompen por tramos de este ancho
Breakables.SegmentWidth = 6
Breakables.MaxSegments = 16
Breakables.BigGlass = { MaxLength = 140, MaxHeight = 12 }

-- Tope del servidor: cosas rotas a la vez (si se pasa, la más antigua se arregla ya), roturas por
-- jugador en una ventana de tiempo y trozos de cristal volando a la vez
Breakables.Budget = {
	MaxBroken = 80,
	PerPlayer = 14,
	Window = 6,
	MaxShards = 160,
}

local GLASS: { [string]: boolean } = {
	Glass = true,
	ShopGlass = true,
	BackGlass = true,
	BackWindows = true,
	SideWindows = true,
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
	ShopDoor = true,
}

-- Puertas de cristal: se rompen como un cristal (de un golpe) aunque se llamen puerta
local GLASS_DOORS: { [string]: boolean } = {
	ShopDoor = true,
	AutoDoor = true,
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

-- ¿Qué clase de cristal es? "Pane" (se rompe entero), "Segmented" (escaparate o franja grande: se
-- rompe por tramos) o nil (no se rompe: fachadas enteras de cristal, neveras, cosas gruesas…).
-- Las puertas de cristal (ShopDoor) cuentan como "Pane".
function Breakables.glassKind(name: string, material: Enum.Material, size: Vector3): string?
	if material ~= Enum.Material.Glass and material ~= Enum.Material.Neon then
		return nil
	end
	local thin = math.min(size.X, size.Y, size.Z)
	if GLASS_DOORS[name] then
		return if thin <= 0.6 and Breakables.area(size) <= Breakables.MaxArea * 1.5 then "Pane" else nil
	end
	if not GLASS[name] or thin > 0.6 then
		return nil
	end
	if Breakables.area(size) <= Breakables.MaxArea then
		return "Pane"
	end
	local dims = { size.X, size.Y, size.Z }
	table.sort(dims)
	-- (el lado mayor es el largo; el mediano, el alto)
	if dims[3] <= Breakables.BigGlass.MaxLength and dims[2] <= Breakables.BigGlass.MaxHeight then
		return "Segmented"
	end
	return nil
end

-- Tramos de un cristal grande: en qué eje (local, X o Z: el largo en horizontal) se parte, cuántos
-- tramos y su ancho
function Breakables.segmentLayout(size: Vector3): (string, number, number)
	local axis, length = "X", size.X
	if size.Z > length then
		axis, length = "Z", size.Z
	end
	local n = math.clamp(math.ceil(length / Breakables.SegmentWidth), 1, Breakables.MaxSegments)
	return axis, n, length / n
end

-- Tramo (1..n) en el que cae una coordenada local (a lo largo del eje del largo)
function Breakables.segmentAt(coord: number, length: number, n: number): number
	local i = math.floor((coord + length / 2) / (length / n)) + 1
	return math.clamp(i, 1, n)
end

-- Tramos que toca algo de medio ancho `half` centrado en `coord` (un coche que entra)
function Breakables.segmentsAround(coord: number, half: number, length: number, n: number): { number }
	local a = Breakables.segmentAt(coord - half, length, n)
	local b = Breakables.segmentAt(coord + half, length, n)
	local list = {}
	for i = a, b do
		table.insert(list, i)
	end
	return list
end

-- ¿Qué rompe qué? source: "Stone", "Bullet", "Melee", "MeleeHeavy", "Vehicle"
-- Un cristal: todo menos un puñetazo flojo; con un vehículo, a partir de VehicleGlassSpeed.
function Breakables.breaksGlass(source: string, speed: number?): boolean
	if source == "Vehicle" then
		return (speed or 0) >= Breakables.VehicleGlassSpeed
	end
	return source == "Stone" or source == "Bullet" or source == "MeleeHeavy"
end

-- Lo que le quita a una puerta (un vehículo rápido, todo; despacio, según la velocidad)
function Breakables.doorDamageFrom(source: string, speed: number?): number
	if source == "Vehicle" then
		local v = speed or 0
		if v >= Breakables.VehicleDoorSpeed then
			return Breakables.DoorHealth
		end
		return if v >= Breakables.VehicleGlassSpeed * 0.5 then v * 2 else 0
	end
	return Breakables.DoorDamage[source] or 0
end

-- ¿Rompen cristales las balas de este arma? Solo las de verdad (Weapons Kind "Real")
function Breakables.bulletBreaks(weaponKind: string?): boolean
	return weaponKind == "Real"
end

-- Aguante de una puerta tras un golpe (si llevaba mucho sin golpes, se había «recuperado»)
function Breakables.doorHealthAfter(health: number, damage: number, sinceLast: number): number
	if sinceLast > Breakables.DoorHeal then
		health = Breakables.DoorHealth
	end
	return math.max(0, health - damage)
end

-- Cuánto se oscurece según el aguante que le queda (0 = como nueva)
function Breakables.doorShade(health: number): number
	return math.clamp(1 - health / Breakables.DoorHealth, 0, 1) * 0.45
end

-- Segundos hasta que se arregla (r: número al azar de 0 a 1)
function Breakables.repairDelay(kind: string, r: number): number
	local range = Breakables.Repair[kind] or Breakables.Repair.Glass
	return range[1] + (range[2] - range[1]) * math.clamp(r, 0, 1)
end

-- ¿Hay alguien en el hueco? (cf y size: la pieza en su sitio; points: posiciones de las personas).
-- margin: lo que se agranda la caja (más en el grosor: alguien justo delante también cuenta)
function Breakables.occupied(cf: CFrame, size: Vector3, points: { Vector3 }, margin: number?): boolean
	local m = margin or 1.5
	local half = size / 2
	local thinX = size.X <= size.Y and size.X <= size.Z
	local thinZ = not thinX and size.Z <= size.Y
	for _, p in points do
		local l = cf:PointToObjectSpace(p)
		local mx = if thinX then m + 1.5 else m
		local mz = if thinZ then m + 1.5 else m
		if math.abs(l.X) <= half.X + mx and math.abs(l.Y) <= half.Y + m + 2.5 and math.abs(l.Z) <= half.Z + mz then
			return true
		end
	end
	return false
end

-- Tope de roturas por jugador: history = momentos de sus últimas roturas (se limpia sola).
-- Devuelve true (y la apunta) si aún puede romper.
function Breakables.allow(history: { number }, now: number): boolean
	for i = #history, 1, -1 do
		if now - history[i] > Breakables.Budget.Window then
			table.remove(history, i)
		end
	end
	if #history >= Breakables.Budget.PerPlayer then
		return false
	end
	table.insert(history, now)
	return true
end

-- Romper cosas es vandalismo: «Daños» (1 estrella) solo si nadie te busca ya (en plena huida no
-- suma más), no con balas (eso ya es «Disparos en la vía pública») y como mucho cada VandalGap s.
-- (Que lo vea alguien —testigo o policía— y las reglas de edad o del modo pruebas las pone
-- WantedService.crime.)
Breakables.VandalGap = 90
function Breakables.vandalCrime(source: string, stars: number, sinceLast: number): string?
	if source == "Bullet" or stars > 0 or sinceLast < Breakables.VandalGap then
		return nil
	end
	return "Danos"
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

-- Cuánto se oscurece una puerta según las pedradas que lleva (se ve que se va estropeando)
function Breakables.doorDamage(hits: number): number
	return Breakables.doorShade(Breakables.DoorHealth - math.clamp(hits / Breakables.DoorHits, 0, 1) * Breakables.DoorHealth)
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
