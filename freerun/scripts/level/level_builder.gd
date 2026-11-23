class_name LevelBuilder
extends RefCounted
## Construye el escenario urbano de pruebas: un mapa pequeño y denso donde se pueden
## probar todas las mecánicas (vaults, wall run, tic tac, trepar, bordes, precisión,
## caídas con rodamiento, acrobacias y saltos al agua).
## Devuelve puntos de aparición, volúmenes de agua y checkpoints para los modos.

const SHADER := preload("res://shaders/world_grid.gdshader")

const C_GROUND := Color(0.42, 0.43, 0.47)
const C_CONCRETE := Color(0.78, 0.76, 0.72)
const C_OBSTACLE := Color(0.95, 0.62, 0.25)
const C_WALL := Color(0.62, 0.66, 0.74)
const C_BRICK := Color(0.72, 0.42, 0.36)
const C_ROOF := Color(0.45, 0.5, 0.6)
const C_METAL := Color(0.3, 0.34, 0.4)
const C_CONTAINER_A := Color(0.2, 0.45, 0.75)
const C_CONTAINER_B := Color(0.8, 0.25, 0.22)
const C_GRASS := Color(0.36, 0.62, 0.3)
const C_TILE := Color(0.85, 0.9, 0.92)
const C_ACCENT := Color(0.98, 0.85, 0.2)

var root: Node3D
var _mats := {}
var info := {
	"spawns": {},
	"water": [] as Array[AABB],
	"checkpoints": [],
}

func build(parent: Node3D) -> Dictionary:
	root = Node3D.new()
	root.name = "Level"
	parent.add_child(root)
	_ground()
	_vault_lane()
	_wallrun_alley()
	_rooftops()
	_trick_pad()
	_pool()
	_dressing()
	info.spawns["freerun"] = [Vector3(0, 0.1, 6), Vector3.FORWARD]
	info.spawns["challenge"] = [Vector3(0, 0.1, 5), Vector3.FORWARD]
	info.spawns["tricking"] = [Vector3(0, 0.1, 16), Vector3.BACK]
	info.spawns["freestyle"] = [Vector3(3, 0.1, 6), Vector3.FORWARD]
	info.spawns["water"] = [Vector3(22, 3.05, 8.8), Vector3.BACK]
	info.spawns["water_high"] = [Vector3(17, 6.05, 8.8), Vector3.BACK]
	info.checkpoints = [Vector3(0, 1.4, -10), Vector3(0, 1.4, -24), Vector3(0, 4.4, -43),
		Vector3(0, 3.6, -49.6), Vector3(0, 1.4, -58)]
	return info

# ------------------------------------------------------------------ utilidades

func mat(c: Color) -> ShaderMaterial:
	var key := c.to_html()
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("albedo", c)
	_mats[key] = m
	return m

## Caja sólida (colisión + malla). pos = centro.
func box(pos: Vector3, size: Vector3, color: Color, yaw_deg := 0.0, collide := true) -> Node3D:
	var node: Node3D
	if collide:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		sb.add_child(cs)
		node = sb
	else:
		node = Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color)
	node.add_child(mi)
	node.position = pos
	node.rotation_degrees.y = yaw_deg
	root.add_child(node)
	return node

## Caja definida por sus límites mínimos y máximos.
func block(min_v: Vector3, max_v: Vector3, color: Color, collide := true) -> Node3D:
	return box((min_v + max_v) * 0.5, max_v - min_v, color, 0.0, collide)

## Rampa con colisión inclinada y escalones visuales (las escaleras usan rampa para la física).
func stairs(start: Vector3, dir: Vector3, run: float, rise: float, width: float, color: Color) -> void:
	var steps := int(round(rise / 0.3))
	var step_run := run / steps
	var side := Vector3.UP.cross(dir).normalized()
	for i in steps:
		var h := (i + 1) * rise / steps
		var c := start + dir * step_run * (i + 0.5) + Vector3.UP * h * 0.5
		var size := Vector3(width, h, step_run) if absf(dir.z) > 0.5 else Vector3(step_run, h, width)
		box(c, size, color, 0.0, false)
	var length := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(length, 0.2, width)
	cs.shape = shape
	sb.add_child(cs)
	root.add_child(sb)
	var mid := start + dir * run * 0.5 + Vector3.UP * rise * 0.5
	var yaw := atan2(-dir.z, dir.x)
	sb.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, angle)
	sb.position = mid - sb.basis.y * 0.08
	sb.collision_layer = 1
	sb.collision_mask = 0
	var _unused := side

func flat(pos: Vector3, size: Vector2, color: Color, y := 0.015) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = mat(color)
	mi.position = Vector3(pos.x, y, pos.z)
	root.add_child(mi)

# ------------------------------------------------------------------ zonas

func _ground() -> void:
	# Suelo en piezas dejando el hueco de la piscina (x 16..28, z 10..26).
	block(Vector3(-45, -5, -75), Vector3(45, 0, 10), C_GROUND)
	block(Vector3(-45, -5, 10), Vector3(16, 0, 45), C_GROUND)
	block(Vector3(28, -5, 10), Vector3(45, 0, 45), C_GROUND)
	block(Vector3(16, -5, 26), Vector3(28, 0, 45), C_GROUND)
	# Muros perimetrales bajos para no salir del mapa corriendo
	block(Vector3(-45, 0, -75), Vector3(45, 1.2, -74), C_CONCRETE)
	block(Vector3(-45, 0, 44), Vector3(45, 1.2, 45), C_CONCRETE)
	block(Vector3(-45, 0, -75), Vector3(-44, 1.2, 45), C_CONCRETE)
	block(Vector3(44, 0, -75), Vector3(45, 1.2, 45), C_CONCRETE)

func _vault_lane() -> void:
	# Línea de vaults (eje -Z desde la salida)
	flat(Vector3(0, 0, -25), Vector2(5, 64), Color(0.33, 0.35, 0.4))
	box(Vector3(0, 0.45, -6), Vector3(3.5, 0.9, 0.35), C_OBSTACLE)           # Speed vault
	box(Vector3(0, 0.5, -14), Vector3(3.0, 1.0, 1.3), C_OBSTACLE)            # Kong vault
	box(Vector3(0, 0.28, -20), Vector3(3.0, 0.56, 0.5), C_OBSTACLE)          # Step vault
	box(Vector3(0, 0.52, -27), Vector3(3.5, 1.05, 0.15), C_METAL)            # Barandilla maciza
	box(Vector3(-1.85, 0.6, -27), Vector3(0.12, 1.2, 0.12), C_ACCENT)
	box(Vector3(1.85, 0.6, -27), Vector3(0.12, 1.2, 0.12), C_ACCENT)
	# Bloque alto: wall climb / cat leap / climb up
	block(Vector3(-3, 0, -46.5), Vector3(3, 3.0, -38), C_BRICK)
	box(Vector3(0, 3.02, -38.2), Vector3(6.0, 0.06, 0.4), C_ACCENT, 0.0, false)  # borde marcado
	# Viga de precisión y caída
	box(Vector3(0, 1.3, -49.6), Vector3(0.3, 2.6, 0.3), C_METAL)
	box(Vector3(0, 2.65, -49.6), Vector3(2.4, 0.1, 0.32), C_ACCENT)
	box(Vector3(-1.2, 1.3, -49.6), Vector3(0.2, 2.6, 0.2), C_METAL)
	box(Vector3(1.2, 1.3, -49.6), Vector3(0.2, 2.6, 0.2), C_METAL)
	# Muro inclinado para Tic Tac junto a la línea
	box(Vector3(-3.6, 1.6, -33), Vector3(0.4, 3.2, 4.0), C_WALL, 25.0)
	box(Vector3(3.2, 0.4, -33), Vector3(1.6, 0.8, 0.5), C_OBSTACLE)

func _wallrun_alley() -> void:
	# Callejón de wall run (paredes paralelas separadas 4,5 m)
	block(Vector3(9.5, 0, -30), Vector3(10.5, 4.5, 0), C_WALL)
	block(Vector3(15.0, 0, -30), Vector3(16.0, 4.5, 0), C_WALL)
	block(Vector3(9.5, 4.5, -30), Vector3(16.0, 4.7, -29), C_METAL, false)
	# Final del callejón: pared alta con borde para trepar
	block(Vector3(10.5, 0, -36), Vector3(15.0, 3.4, -32), C_BRICK)
	# Contenedores
	box(Vector3(6.5, 1.3, 9), Vector3(2.4, 2.6, 6.0), C_CONTAINER_A)
	box(Vector3(9.3, 1.3, 9), Vector3(2.4, 2.6, 6.0), C_CONTAINER_B)
	box(Vector3(7.9, 3.9, 9.5), Vector3(2.4, 2.6, 6.0), C_CONTAINER_A, 90.0)
	box(Vector3(4.6, 0.6, 12.5), Vector3(1.2, 1.2, 1.2), C_OBSTACLE)

func _rooftops() -> void:
	# Escalera hacia la primera azotea
	stairs(Vector3(-5.6, 0, -2), Vector3.LEFT, 3.6, 2.4, 4.0, C_CONCRETE)
	block(Vector3(-14, 0, -6), Vector3(-9.2, 2.4, 2), C_ROOF)
	block(Vector3(-14, 2.4, 1.8), Vector3(-9.2, 2.75, 2), C_METAL)       # pretil
	block(Vector3(-20, 0, -6), Vector3(-16.5, 3.4, 2), C_ROOF)
	block(Vector3(-26, 0, -6), Vector3(-22.5, 2.2, 2), C_ROOF)
	block(Vector3(-25.6, 2.2, -5.8), Vector3(-23.0, 3.3, -4.0), C_METAL)   # equipo de aire acondicionado
	block(Vector3(-26, 0, -12), Vector3(-22.5, 5.6, -6), C_BRICK)          # torre para caídas y dobles
	box(Vector3(-24.25, 5.62, -6.2), Vector3(3.5, 0.05, 0.4), C_ACCENT, 0.0, false)
	# Andamio: plataformas finas a distintas alturas
	for i in 3:
		var y := 1.4 + i * 1.3
		block(Vector3(-32, y - 0.12, -4 + i * 3.2), Vector3(-29, y, -2 + i * 3.2), C_METAL)
		for cx in [-31.9, -29.1]:
			box(Vector3(cx, y * 0.5, -3 + i * 3.2), Vector3(0.1, y, 0.1), C_METAL)
	# Muros bajos dispersos en la plaza
	box(Vector3(-6, 0.45, 10), Vector3(4, 0.9, 0.4), C_CONCRETE, 30.0)
	box(Vector3(-10, 0.55, 14), Vector3(1.4, 1.1, 1.4), C_OBSTACLE)
	box(Vector3(-14, 0.35, 10), Vector3(5, 0.7, 0.4), C_CONCRETE)

func _trick_pad() -> void:
	# Zona de tricking: césped y una caja para saltar
	flat(Vector3(0, 0, 21), Vector2(16, 14), C_GRASS, 0.02)
	box(Vector3(5.5, 0.75, 24), Vector3(3, 1.5, 3), C_OBSTACLE)
	box(Vector3(-5.5, 1.0, 25), Vector3(3, 2.0, 2.5), C_CONCRETE)

func _pool() -> void:
	# Piscina 12 x 16 m, 4 m de profundidad, agua a -0,3
	block(Vector3(16, -5, 10), Vector3(28, -4, 26), C_TILE)
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 16)
	water.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.15, 0.55, 0.85, 0.72)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.08
	wm.metallic_specular = 0.8
	water.material_override = wm
	water.position = Vector3(22, -0.3, 18)
	root.add_child(water)
	# Paredes interiores claras
	for r in [[Vector3(16, -4, 10), Vector3(16.05, 0, 26)], [Vector3(27.95, -4, 10), Vector3(28, 0, 26)],
			[Vector3(16, -4, 10), Vector3(28, 0, 10.05)], [Vector3(16, -4, 25.95), Vector3(28, 0, 26)]]:
		block(r[0], r[1], C_TILE, false)
	info.water.append(AABB(Vector3(16, -4, 10), Vector3(12, 3.7, 16)))
	# Trampolines de 3 m y 6 m
	block(Vector3(21, 0, 7.6), Vector3(23, 3.0, 9.4), C_CONCRETE)
	box(Vector3(22, 2.95, 10.4), Vector3(1.0, 0.1, 2.2), C_TILE)
	block(Vector3(16, 0, 7.6), Vector3(18, 6.0, 9.4), C_CONCRETE)
	box(Vector3(17, 5.95, 10.4), Vector3(1.0, 0.1, 2.2), C_TILE)
	# Cajas para subir al trampolín de 3 m
	block(Vector3(23, 0, 7.8), Vector3(24.4, 1.2, 9.2), C_OBSTACLE)
	block(Vector3(24.4, 0, 7.8), Vector3(25.8, 2.1, 9.2), C_OBSTACLE)
	# Borde de la piscina
	for r in [[Vector3(15.6, 0, 9.6), Vector3(28.4, 0.12, 10)], [Vector3(15.6, 0, 26), Vector3(28.4, 0.12, 26.4)],
			[Vector3(15.6, 0, 10), Vector3(16, 0.12, 26)], [Vector3(28, 0, 10), Vector3(28.4, 0.12, 26)]]:
		block(r[0], r[1], C_CONCRETE, false)

func _dressing() -> void:
	# Edificios de fondo (sin colisión) para dar contexto urbano
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var palette := [Color(0.62, 0.66, 0.74), Color(0.74, 0.68, 0.6), Color(0.55, 0.6, 0.68), Color(0.78, 0.55, 0.45)]
	for i in 26:
		var a := float(i) / 26.0 * TAU
		var r := rng.randf_range(62.0, 80.0)
		var w := rng.randf_range(8, 16)
		var h := rng.randf_range(12, 34)
		box(Vector3(cos(a) * r, h * 0.5 - 0.5, sin(a) * r - 15.0), Vector3(w, h, w), palette[i % palette.size()],
			rad_to_deg(-a), false)
	# Árboles simples alrededor del césped
	for p in [Vector3(-8.5, 0, 17), Vector3(-8.5, 0, 25), Vector3(9, 0, 27), Vector3(-2, 0, 29)]:
		box(p + Vector3(0, 1.0, 0), Vector3(0.3, 2.0, 0.3), Color(0.4, 0.28, 0.2), 0.0, true)
		var crown := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.3
		sm.height = 2.4
		sm.radial_segments = 10
		sm.rings = 6
		crown.mesh = sm
		crown.material_override = mat(Color(0.25, 0.5, 0.28))
		crown.position = p + Vector3(0, 2.8, 0)
		root.add_child(crown)
