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
	"buoys": [],          # boyas de playa (trampolín): {"pos": centro, "node": malla}
	"sand": [] as Array[AABB],   # zonas de arena (recepciones más suaves)
	"foam": [] as Array[AABB],   # fosos de espuma del gimnasio (recepciones muy blandas)
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
	_park()
	_moves_plaza()
	_beach()
	_gym()
	info.spawns["freerun"] = [Vector3(0, 0.1, 6), Vector3.FORWARD]
	info.spawns["challenge"] = [Vector3(0, 0.1, 5), Vector3.FORWARD]
	info.spawns["tricking"] = [Vector3(0, 0.1, 16), Vector3.BACK]
	info.spawns["freestyle"] = [Vector3(3, 0.1, 6), Vector3.FORWARD]
	info.spawns["water"] = [Vector3(22, 3.05, 8.8), Vector3.BACK]
	info.spawns["water_high"] = [Vector3(17, 6.05, 8.8), Vector3.BACK]
	info.spawns["gym"] = [GYM_C + Vector3(0, 0.1, 11), Vector3.FORWARD]
	info.spawns["plaza"] = [Vector3(28, 0.1, -16), Vector3.FORWARD]
	info.spawns["park"] = [Vector3(30, 0.1, -38), Vector3.FORWARD]
	info.spawns["beach"] = [Vector3(125, 0.1, 12), Vector3.FORWARD]
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


# ------------------------------------------------------------------ parque

## Parque de obstáculos (x 19..43, z -40..-73): cuatro calles, cada una con alturas distintas,
## para practicar todos los movimientos. Se corre hacia -z (de cara al fondo del mapa).
func _park() -> void:
	flat(Vector3(31, 0, -56.5), Vector2(25, 34), Color(0.3, 0.32, 0.36))
	# Calle 1 (x 22): vaults. Barandilla baja (speed, lazy, reverse, turn), caja (kong, kash,
	# dash), caja larga (double kong), murete bajo (step, thief) y barandilla alta con postes.
	box(Vector3(22, 0.4, -44), Vector3(3.0, 0.8, 0.15), C_METAL)
	box(Vector3(22, 0.55, -50), Vector3(3.0, 1.1, 1.0), C_OBSTACLE)
	box(Vector3(22, 0.5, -57), Vector3(3.0, 1.0, 2.6), C_CONCRETE)
	box(Vector3(22, 0.3, -62.5), Vector3(3.0, 0.6, 0.5), C_OBSTACLE)
	box(Vector3(22, 1.0, -67), Vector3(3.0, 0.08, 0.08), C_ACCENT)
	for px in [20.6, 22.0, 23.4]:
		box(Vector3(px, 0.5, -67), Vector3(0.08, 1.0, 0.08), C_METAL)
	# Calle 2 (x 28,5): muros cada vez más altos: step up 0,7 · kong up 1,3 · climb up 1,9 ·
	# 2,6 (subida desde colgado) · 3,4 (escalada de pared y colgarse del borde)
	var hs := [0.7, 1.3, 1.9, 2.6, 3.4]
	for k in hs.size():
		var z0 := -44.0 - k * 6.0
		block(Vector3(27, 0, z0 - 2.0), Vector3(30, hs[k], z0), C_BRICK if k % 2 == 0 else C_ROOF)
		box(Vector3(28.5, hs[k] + 0.02, z0 - 0.15), Vector3(3.0, 0.04, 0.3), C_ACCENT, 0.0, false)
	# Calle 3 (x 35): precisiones entre pilares de alturas variadas y huecos de salto de longitud
	var pillars := [[-44.0, 0.8], [-46.4, 1.0], [-49.2, 1.4], [-52.0, 1.0], [-55.2, 0.6], [-58.0, 1.2]]
	for pl in pillars:
		box(Vector3(35, pl[1] * 0.5, pl[0]), Vector3(0.7, pl[1], 0.7), C_CONCRETE)
	block(Vector3(33.5, 0, -64), Vector3(36.5, 1.5, -61), C_ROOF)        # plataformas: hueco de 3 m
	block(Vector3(33.5, 0, -70), Vector3(36.5, 1.5, -67), C_ROOF)
	# Calle 4 (x 41): muro largo para wall run, muro corto para tic-tac junto a un obstáculo,
	# y pared con borde para cat leap desde la caja
	block(Vector3(42.3, 0, -62), Vector3(43.0, 4.5, -44), C_WALL)
	block(Vector3(38.6, 0, -67), Vector3(39.2, 2.6, -64), C_WALL)
	box(Vector3(40.6, 0.5, -66), Vector3(1.6, 1.0, 1.2), C_OBSTACLE)
	block(Vector3(39.5, 0, -73), Vector3(43.0, 2.8, -70.5), C_BRICK)
	block(Vector3(40.4, 0, -69.2), Vector3(42.2, 1.0, -68.0), C_OBSTACLE)
	# Torre de caídas (4,5 m) con escalera: dobles mortales y caídas con rodada
	block(Vector3(19.5, 0, -73.5), Vector3(24.5, 4.5, -70.2), C_ROOF)
	stairs(Vector3(31.5, 0, -71.8), Vector3.LEFT, 7.0, 4.5, 2.0, C_CONCRETE)

# ------------------------------------------------------------------ plaza de movimientos

## Plaza junto al parque (x 22..40, z -14..-33) con los obstáculos de los vídeos de referencia:
##   · muro bajo (0,8 m) para la PLANCHA BACK (parado delante + ATRÁS)
##   · plataforma de 1,6 m con escalera, valla en el borde norte (KONG GAINER desde parado,
##     saltando la valla y cayendo de altura) y borde este abierto (kong gainer apoyando las
##     manos en el borde corriendo)
##   · valla de 1 m a ras de suelo para el kong gainer corriendo
func _moves_plaza() -> void:
	flat(Vector3(31, 0, -23.5), Vector2(18, 19), Color(0.36, 0.34, 0.33))
	box(Vector3(24, 0.4, -27), Vector3(1.6, 0.8, 0.4), C_CONCRETE)              # muro bajo
	block(Vector3(30, 0, -31), Vector3(35, 1.6, -26), C_BRICK)                    # plataforma
	stairs(Vector3(32.5, 0, -21.5), Vector3.FORWARD, 4.5, 1.6, 2.0, C_CONCRETE)
	box(Vector3(32.5, 2.1, -30.95), Vector3(5.0, 0.06, 0.08), C_METAL)          # valla del borde (pasamanos)
	box(Vector3(32.5, 1.6 + 0.47, -30.95), Vector3(5.0, 0.94, 0.06), C_METAL, 0.0, true)
	for vx in [30.2, 32.5, 34.8]:
		box(Vector3(vx, 2.1 - 0.25, -30.95), Vector3(0.07, 0.5, 0.07), C_METAL, 0.0, false)
	box(Vector3(39, 0.5, -20), Vector3(3.0, 1.0, 0.1), C_METAL)                 # valla a ras de suelo
	box(Vector3(37.6, 0.5, -20), Vector3(0.08, 1.0, 0.08), C_ACCENT, 0.0, false)
	box(Vector3(40.4, 0.5, -20), Vector3(0.08, 1.0, 0.08), C_ACCENT, 0.0, false)

# ------------------------------------------------------------------ playa

const C_SAND := Color(0.84, 0.68, 0.42)
const BUOY_R := 1.14                 # boya grande (2,3 m de diámetro), medio enterrada
const BEACH_C := Vector3(125, 0, 0)    # centro de la playa (lejos de la ciudad)
const BEACH_HALF := 22.0

## Playa sencilla: un arenal y, en medio, una boya de barco medio enterrada que hace
## de trampolín (pisarla corriendo lanza mucho más alto para hacer mortales).
func _beach() -> void:
	var sand := block(BEACH_C + Vector3(-BEACH_HALF, -5, -BEACH_HALF), BEACH_C + Vector3(BEACH_HALF, 0, BEACH_HALF), C_SAND)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = C_SAND
	sm.roughness = 1.0
	for c in sand.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).material_override = sm
	info.sand.append(AABB(BEACH_C + Vector3(-BEACH_HALF, -1, -BEACH_HALF), Vector3(2 * BEACH_HALF, 3, 2 * BEACH_HALF)))
	_buoy(BEACH_C + Vector3(0, -0.45, 0))         # asoma ~0,7 m: se pisa corriendo

func _buoy(c: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = c
	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = BUOY_R
	col.shape = sh
	body.add_child(col)
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = BUOY_R
	sp.height = BUOY_R * 2.0
	mi.mesh = sp
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.86, 0.1, 0.09)
	m.roughness = 0.32
	mi.material_override = m
	body.add_child(mi)
	root.add_child(body)
	info.buoys.append({"pos": c, "node": mi, "r": BUOY_R})


# ------------------------------------------------------------------ gimnasio

const C_WOOD := Color(0.8, 0.55, 0.3)
const C_WOOD_D := Color(0.64, 0.42, 0.23)
const C_GYM_FLOOR := Color(0.28, 0.28, 0.3)
const C_BAR := Color(0.16, 0.16, 0.18)
const GYM_C := Vector3(-130, 0, -15)     # centro del gimnasio (lejos de la ciudad, al oeste)

func _g(x: float, y: float, z: float) -> Vector3:
	return GYM_C + Vector3(x, y, z)

## Barra metálica entre dos puntos a una altura (con colisión, fina como un tubo).
func _bar(a: Vector3, b: Vector3, y: float) -> void:
	var mid := (a + b) * 0.5
	var d := b - a
	d.y = 0.0
	var yaw := rad_to_deg(atan2(d.x, d.z)) + 90.0
	box(Vector3(mid.x, y, mid.z), Vector3(d.length(), 0.06, 0.06), C_BAR, yaw)

## Poste fino para sujetar barras.
func _post(p: Vector3, h: float) -> void:
	box(Vector3(p.x, h * 0.5, p.z), Vector3(0.09, h, 0.09), C_BAR)

## Gimnasio de parkour (40 x 40 m, cubierto por paredes de 4,5 m): muros de madera de distintas
## alturas y fondos, muros escalonados, pilares, barras a tres alturas, plataforma con valla y
## borde abierto, muro alto para wall run / tic-tac y foso de espuma.
func _gym() -> void:
	block(_g(-20, -5, -20), _g(20, 0, 20), C_GYM_FLOOR)
	# Paredes del recinto
	block(_g(-20.6, 0, -20.6), _g(20.6, 4.5, -20), C_TILE)
	block(_g(-20.6, 0, 20), _g(20.6, 4.5, 20.6), C_TILE)
	block(_g(-20.6, 0, -20), _g(-20, 4.5, 20), C_TILE)
	block(_g(20, 0, -20), _g(20.6, 4.5, 20), C_TILE)
	# A · Calle de vaults (x -12): barra a 1 m · caja de kong 1,1 m · muro fino 1 m (plancha) ·
	# muro de 1,3 m con 2 m de fondo · muro bajo de 0,6 m
	_post(_g(-13.3, 0, 11), 1.0); _post(_g(-10.7, 0, 11), 1.0)
	_bar(_g(-13.3, 0, 11), _g(-10.7, 0, 11), 1.0)
	box(_g(-12, 0.55, 5), Vector3(2.6, 1.1, 1.0), C_WOOD)
	box(_g(-12, 0.5, -1), Vector3(2.6, 1.0, 0.3), C_WOOD_D)
	block(_g(-13.3, 0, -9), _g(-10.7, 1.3, -7), C_WOOD)
	box(_g(-12, 0.3, -14), Vector3(2.6, 0.6, 0.4), C_WOOD_D)
	# B · Muros escalonados (x -5): 0,7 · 1,3 · 1,9 · 2,5 · 3,2 m con huecos de 2 m
	var steps := [0.7, 1.3, 1.9, 2.5, 3.2]
	for k in steps.size():
		var z0 := 12.0 - k * 4.0
		block(_g(-6.2, 0, z0 - 2.0), _g(-3.8, steps[k], z0), C_WOOD if k % 2 == 0 else C_WOOD_D)
	# C · Pilares de precisión con barras entre ellos (x 3..11)
	var pillars := [[3.0, 12.0, 1.2], [7.0, 12.0, 1.6], [11.0, 12.0, 2.0], [3.0, 7.0, 2.4], [7.0, 7.0, 1.4], [11.0, 7.0, 1.8]]
	for pl in pillars:
		box(_g(pl[0], pl[2] * 0.5, pl[1]), Vector3(0.6, pl[2], 0.6), C_WOOD)
	_bar(_g(3.3, 0, 12), _g(6.7, 0, 12), 1.0)        # barra baja entre pilares
	_bar(_g(7.3, 0, 7), _g(10.7, 0, 7), 1.6)         # barra media
	_bar(_g(3, 0, 7.3), _g(3, 0, 11.7), 2.2)         # barra alta
	# D · Conjunto de barras sueltas a tres alturas (1 · 1,6 · 2,2 m)
	for bx in [14.0, 18.0]:
		_post(_g(bx, 0, 13), 2.3); _post(_g(bx, 0, 7), 2.3)
	for by in [1.0, 1.6, 2.2]:
		_bar(_g(14, 0, 13), _g(14, 0, 7), by)
	_bar(_g(18, 0, 13), _g(18, 0, 7), 1.3)
	_bar(_g(14, 0, 10), _g(18, 0, 10), 1.9)
	# E · Plataforma de 1,6 m con escalera, valla en el borde sur y borde este abierto
	block(_g(1, 0, -6), _g(7, 1.6, -1), C_WOOD)
	stairs(_g(4, 0, 3.5), Vector3.FORWARD, 4.5, 1.6, 2.0, C_WOOD_D)
	box(_g(4, 1.6 + 0.47, -5.95), Vector3(6.0, 0.94, 0.06), C_BAR)
	for vx in [1.2, 4.0, 6.8]:
		_post(_g(vx, 0, -5.95), 2.55)
	# F · Muro alto (3,5 m) para wall run y tic-tac, con una caja delante
	block(_g(-17, 0, -18), _g(-16.4, 3.5, -8), C_WOOD_D)
	box(_g(-14.5, 0.5, -15), Vector3(1.2, 1.0, 1.2), C_WOOD)
	# G · Foso de espuma con plataforma de salto de 2,4 m
	var foam_min := _g(10, 0, -18)
	var foam_max := _g(19, 0.6, -9)
	block(_g(9.6, 0, -18.4), _g(19.4, 0.5, -18), C_WOOD)      # borde del foso
	block(_g(9.6, 0, -9.4), _g(19.4, 0.5, -9), C_WOOD)
	block(_g(9.6, 0, -18), _g(10, 0.5, -9.4), C_WOOD)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 70:
		var c := Color(0.15, 0.45, 0.9) if k % 3 != 0 else Color(0.12, 0.12, 0.14)
		var p := Vector3(rng.randf_range(foam_min.x + 0.4, foam_max.x - 0.4), rng.randf_range(0.12, 0.45),
			rng.randf_range(foam_min.z + 0.4, foam_max.z - 0.4))
		box(p, Vector3(0.45, 0.4, 0.45), c, rng.randf_range(0, 90), false)
	info.foam.append(AABB(foam_min - Vector3(0, 1, 0), foam_max - foam_min + Vector3(0, 3, 0)))
	block(_g(5.5, 0, -18), _g(9.6, 2.4, -14), C_WOOD)          # plataforma de salto al foso
	stairs(_g(7.5, 0, -10.0), Vector3.FORWARD, 4.0, 2.4, 1.8, C_WOOD_D)
	# H · Barras bajas de equilibrio / precisión (0,5 m) y muros bajos sueltos
	for bz in [16.0, 14.0]:
		_post(_g(-2, 0, bz), 0.5); _post(_g(2, 0, bz), 0.5)
		_bar(_g(-2, 0, bz), _g(2, 0, bz), 0.5)
	box(_g(-16, 0.4, 14), Vector3(1.6, 0.8, 0.4), C_WOOD_D)
	box(_g(-16, 0.6, 8), Vector3(1.6, 1.2, 0.4), C_WOOD)
	# I · Muros enlazados (como en los gimnasios: un recorrido continuo de muros y torres):
	# muro largo de 1,2 m · torre de 2,2 m en la esquina · muro de 0,9 m que gira · escalón de 1,6 m
	block(_g(10, 0, -6), _g(18, 1.2, -5.6), C_WOOD)
	block(_g(18, 0, -6.4), _g(19.4, 2.2, -4.6), C_WOOD_D)
	block(_g(18.6, 0, -4.6), _g(19.0, 0.9, 3.0), C_WOOD)
	block(_g(12, 0, -5.6), _g(13.4, 1.6, -4.2), C_WOOD_D)
	block(_g(15, 0, -5.6), _g(15.8, 0.7, -4.8), C_WOOD)
	_post(_g(10, 0, -3.0), 2.0); _post(_g(10, 0, 1.0), 2.0)
	_bar(_g(10, 0, -3.0), _g(10, 0, 1.0), 2.0)          # barra alta junto a los muros
	# J · Pirámide de cajones cerca de la entrada (0,5 · 1,0 · 1,5 m)
	box(_g(9.5, 0.25, 16.5), Vector3(3.0, 0.5, 3.0), C_WOOD_D)
	box(_g(9.5, 0.75, 16.5), Vector3(2.0, 0.5, 2.0), C_WOOD)
	box(_g(9.5, 1.25, 16.5), Vector3(1.0, 0.5, 1.0), C_WOOD_D)
