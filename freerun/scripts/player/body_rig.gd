class_name BodyRig
extends Node3D
## Personaje 3D estilizado construido por código (sin assets externos) y animado
## de forma procedural a partir del estado físico del PlayerController:
## ciclo de carrera ligado a la velocidad real, poses de vault, wall run, colgado,
## agrupado/abierto en acrobacias, recepción, rodar y caída.
## La rotación de acrobacias se aplica en `pivot` (centro de masas).

signal footstep(strength: float)

const COM_HEIGHT := 0.95

var player: PlayerController
var pivot: Node3D
var body: Node3D
var joints := {}
var pose := {}            # rotación actual por articulación
var phase := 0.0
var body_drop := 0.0
var _tilt := Basis()
var _yaw := 0.0
var _serial := -1
var _prev_spd := 0.0
var _accel := 0.0                 # aceleración suavizada (inclinación al arrancar/frenar)
# Apoyos (IK): punto del suelo donde está plantada cada mano/pie y peso del apoyo
var plants := {}
var contact_w := {"hl": 0.0, "hr": 0.0, "fl": 0.0, "fr": 0.0}
var ground_y := 0.0
var ik_enabled := true
const ARM_L1 := 0.29
const ARM_L2 := 0.28
const HAND_R := 0.055
const LEG_L1 := 0.43
const LEG_L2 := 0.45
const SOLE := 0.05

# Paleta de identidad propia: sudadera turquesa, pantalón carbón, zapatillas naranja.
const COL_HOODIE := Color(0.12, 0.72, 0.68)
const COL_HOODIE_DARK := Color(0.08, 0.5, 0.48)
const COL_PANTS := Color(0.16, 0.17, 0.21)
const COL_SKIN := Color(0.86, 0.66, 0.52)
const COL_SHOES := Color(1.0, 0.45, 0.15)
const COL_CAP := Color(0.95, 0.95, 0.92)

func setup(p: PlayerController) -> void:
	player = p
	pivot = Node3D.new()
	pivot.position.y = COM_HEIGHT
	add_child(pivot)
	body = Node3D.new()
	body.position.y = -COM_HEIGHT
	pivot.add_child(body)
	_build()

func _mat(c: Color, rough := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _joint(name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.name = name
	j.position = pos
	parent.add_child(j)
	joints[name] = j
	pose[name] = Vector3.ZERO
	return j

func _capsule(parent: Node3D, radius: float, length: float, color: Color, offset := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(length, radius * 2.0)
	m.radial_segments = 10
	m.rings = 3
	mi.mesh = m
	mi.material_override = _mat(color)
	mi.position = offset
	parent.add_child(mi)
	return mi

func _box(parent: Node3D, size: Vector3, color: Color, offset := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = _mat(color)
	mi.position = offset
	parent.add_child(mi)
	return mi

func _build() -> void:
	var pelvis := _joint("pelvis", body, Vector3(0, 0.95, 0))
	_box(pelvis, Vector3(0.32, 0.16, 0.2), COL_PANTS)
	var spine := _joint("spine", pelvis, Vector3(0, 0.06, 0))
	_capsule(spine, 0.18, 0.56, COL_HOODIE, Vector3(0, 0.26, 0))
	_box(spine, Vector3(0.3, 0.12, 0.16), COL_HOODIE_DARK, Vector3(0, 0.06, 0.0))      # bolsillo/cintura
	_box(spine, Vector3(0.22, 0.26, 0.08), COL_HOODIE_DARK, Vector3(0, 0.34, 0.14))    # capucha a la espalda
	var neck := _joint("neck", spine, Vector3(0, 0.54, 0))
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.13
	hm.height = 0.27
	hm.radial_segments = 14
	hm.rings = 8
	head.mesh = hm
	head.material_override = _mat(COL_SKIN, 0.6)
	head.position = Vector3(0, 0.14, 0)
	neck.add_child(head)
	# Gorra con visera hacia delante (lectura clara de la orientación)
	_box(neck, Vector3(0.27, 0.08, 0.27), COL_CAP, Vector3(0, 0.235, 0.0))
	_box(neck, Vector3(0.22, 0.025, 0.14), COL_CAP, Vector3(0, 0.2, -0.17))
	# Brazos
	for side in [["l", -1.0], ["r", 1.0]]:
		var s: String = side[0]
		var x: float = side[1]
		var sh := _joint("shoulder_" + s, spine, Vector3(0.23 * x, 0.47, 0))
		_capsule(sh, 0.065, 0.32, COL_HOODIE, Vector3(0, -0.15, 0))
		var el := _joint("elbow_" + s, sh, Vector3(0, -0.29, 0))
		_capsule(el, 0.055, 0.28, COL_HOODIE, Vector3(0, -0.12, 0))
		var hand := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.055
		sm.height = 0.11
		hand.mesh = sm
		hand.material_override = _mat(COL_SKIN, 0.6)
		hand.position = Vector3(0, -0.28, 0)
		el.add_child(hand)
	# Piernas
	for side in [["l", -1.0], ["r", 1.0]]:
		var s: String = side[0]
		var x: float = side[1]
		var hip := _joint("hip_" + s, pelvis, Vector3(0.1 * x, -0.02, 0))
		_capsule(hip, 0.085, 0.45, COL_PANTS, Vector3(0, -0.21, 0))
		var knee := _joint("knee_" + s, hip, Vector3(0, -0.43, 0))
		_capsule(knee, 0.07, 0.42, COL_PANTS, Vector3(0, -0.2, 0))
		_box(knee, Vector3(0.12, 0.09, 0.27), COL_SHOES, Vector3(0, -0.45, -0.05))
	for mi in find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

# ------------------------------------------------------------------ animación

func _base_pose() -> Dictionary:
	var d := {}
	for k in joints.keys():
		d[k] = Vector3.ZERO
	return d

func _process(dt: float) -> void:
	if player == null:
		return
	var st := player.state
	var spd := player.speed()
	if dt > 0.0:
		_accel = lerpf(_accel, (spd - _prev_spd) / dt, 1.0 - exp(-8.0 * dt))
	_prev_spd = spd
	var target := _base_pose()
	var tilt := Basis()
	var drop := 0.0
	var blend_speed := 14.0

	# Orientación horizontal
	var fwd := player.facing
	var yaw_target := atan2(-fwd.x, -fwd.z)
	if player.skill_serial != _serial:
		# Empieza o termina una habilidad: la orientación de salida ya va incluida en su giro
		# (rondada, raiz...), así que se reorienta de golpe en vez de dar una vuelta extra.
		_serial = player.skill_serial
		_yaw = yaw_target
		if st != PlayerController.State.SKILL:
			_tilt = Basis()
	_yaw = lerp_angle(_yaw, yaw_target, 1.0 - exp(-20.0 * dt))
	rotation.y = _yaw
	var smp := {}

	match st:
		PlayerController.State.GROUND:
			if spd > 0.3:
				_run_pose(target, spd, dt)
				# Naturalidad: el tronco se inclina al acelerar y se echa atrás al frenar, y cada
				# zancada sube y baja un poco el cuerpo (más cuanto más rápido)
				var amt := clampf(spd / 9.0, 0.0, 1.0)
				target.spine.x -= clampf(_accel * 0.035, -0.35, 0.4)
				drop += 0.045 * amt * (0.5 - 0.5 * cos(phase * 2.0))
			else:
				_idle_pose(target)
			if player.stun > 0.0:
				drop = 0.18
				target.spine.x = -0.5
				target.hip_l.x = 0.9; target.hip_r.x = 0.7
				target.knee_l.x = -1.4; target.knee_r.x = -1.2
			if player.jump_load > 0.0:
				drop = _load_pose(target)
				blend_speed = 34.0
			var c := player.land_impact
			if c > 0.0:
				# Recepción: piernas y tronco absorben el impacto (más profunda cuanto más fuerte).
				drop += 0.34 * c
				target.hip_l.x += 1.15 * c; target.hip_r.x += 1.1 * c
				target.knee_l.x -= 2.0 * c; target.knee_r.x -= 1.95 * c
				target.spine.x -= 0.6 * c
				target.neck.x += 0.25 * c
				match player.land_quality:
					"perfect":
						# Clavada: brazos delante, quieto y firme
						target.shoulder_l.x += 1.3 * c; target.shoulder_r.x += 1.3 * c
						target.shoulder_l.z -= 0.25 * c; target.shoulder_r.z += 0.25 * c
					"clean":
						target.shoulder_l.x += 0.9 * c; target.shoulder_r.x += 0.9 * c
						target.shoulder_l.z -= 0.7 * c; target.shoulder_r.z += 0.7 * c
					_:
						# Torcida o dura: brazos buscando el equilibrio y tronco desplazado
						var w := sin(player.land_timer * 22.0)
						target.shoulder_l.x += (1.6 + 0.8 * w) * c; target.shoulder_r.x += (0.4 - 0.8 * w) * c
						target.shoulder_l.z -= 1.1 * c; target.shoulder_r.z += 1.1 * c
						target.spine.z = 0.25 * w * c
						target.spine.x -= 0.3 * c
		PlayerController.State.AIR:
			_air_pose(target)
			blend_speed = 22.0
		PlayerController.State.VAULT:
			tilt = _vault_pose(target)
			blend_speed = 20.0
		PlayerController.State.WALLRUN:
			_run_pose(target, maxf(spd, 6.0) * 1.15, dt)
			var side: float = player.wall.get("side", 1.0)
			tilt = Basis(Vector3.BACK, 0.42 * side)
			target.shoulder_l.z -= 0.5; target.shoulder_r.z += 0.5
		PlayerController.State.WALLCLIMB:
			phase += dt * 14.0
			target.hip_l.x = 0.9 + sin(phase) * 0.6; target.hip_r.x = 0.9 - sin(phase) * 0.6
			target.knee_l.x = -1.3; target.knee_r.x = -1.3
			target.shoulder_l.x = 2.6 - sin(phase) * 0.4; target.shoulder_r.x = 2.6 + sin(phase) * 0.4
			target.spine.x = 0.1
		PlayerController.State.HANG:
			var sw := sin(Time.get_ticks_msec() * 0.003) * 0.12
			target.shoulder_l.x = 3.0; target.shoulder_r.x = 3.0
			target.shoulder_l.z = -0.15; target.shoulder_r.z = 0.15
			target.elbow_l.x = 0.25; target.elbow_r.x = 0.25
			target.hip_l.x = 0.25 + sw; target.hip_r.x = 0.1 + sw
			target.knee_l.x = -0.35; target.knee_r.x = -0.2
		PlayerController.State.CLIMB_UP:
			var s := clampf(player.state_time / maxf(player.climb.get("duration", 0.4), 0.01), 0.0, 1.0)
			target.shoulder_l.x = lerpf(3.0, 0.4, s); target.shoulder_r.x = lerpf(3.0, 0.4, s)
			target.elbow_l.x = sin(s * PI) * 1.6; target.elbow_r.x = sin(s * PI) * 1.6
			target.hip_l.x = sin(s * PI) * 1.7; target.hip_r.x = sin(s * PI) * 0.6
			target.knee_l.x = -sin(s * PI) * 2.0; target.knee_r.x = -sin(s * PI) * 1.0
			target.spine.x = -sin(s * PI) * 0.6
			blend_speed = 22.0
		PlayerController.State.ROLL:
			_tuck_pose(target, 1.0)
			var s := player.roll_progress()
			tilt = Basis(Vector3.RIGHT, -TAU * _ease_in_out(s))
			drop = sin(s * PI) * 0.45
			blend_speed = 25.0
		PlayerController.State.SKILL:
			smp = player.skill_sample()
			if not smp.is_empty():
				_apply(target, smp.pose, 1.0)
				tilt = smp.basis
				drop = COM_HEIGHT - float(smp.com)
				last_phase = String(smp.phase)
				last_kind = String(player.skill.get("id", ""))
			blend_speed = 30.0
		PlayerController.State.CRASH:
			# Cae de espaldas (desde ahí sale el kip-up)
			var s := clampf(player.state_time / 0.35, 0.0, 1.0)
			tilt = Basis(Vector3.RIGHT, 1.45 * s)
			drop = 0.78 * s
			target.shoulder_l.z = -1.3; target.shoulder_r.z = 1.2
			target.shoulder_l.x = 0.4; target.hip_l.x = 0.3; target.knee_l.x = -0.6
			target.hip_r.x = -0.1
			if player.state_time > player.t.crash_time - 0.4:
				var g := clampf((player.state_time - (player.t.crash_time - 0.4)) / 0.4, 0.0, 1.0)
				tilt = Basis(Vector3.RIGHT, 1.45 * (1.0 - g))
				drop = 0.78 * (1.0 - g)
		PlayerController.State.SWIM:
			phase += dt * 4.0
			target.shoulder_l.x = 1.6 + sin(phase) * 1.2; target.shoulder_r.x = 1.6 - sin(phase) * 1.2
			target.hip_l.x = sin(phase * 1.3) * 0.4; target.hip_r.x = -sin(phase * 1.3) * 0.4
			tilt = Basis(Vector3.RIGHT, -0.9 if player.speed() > 0.6 else -0.2)

	# Mezcla suave hacia la pose objetivo
	var k := 1.0 - exp(-blend_speed * dt)
	for name in joints.keys():
		pose[name] = (pose[name] as Vector3).lerp(target[name], k)
		(joints[name] as Node3D).rotation = pose[name]
	var direct := st in [PlayerController.State.ROLL, PlayerController.State.VAULT, PlayerController.State.SKILL]
	body_drop = drop if st == PlayerController.State.SKILL else lerpf(body_drop, drop, 1.0 - exp(-18.0 * dt))
	_tilt = tilt if direct else _tilt.slerp(tilt, 1.0 - exp(-22.0 * dt))
	var trick_basis := player.tricks.basis if st in [PlayerController.State.AIR, PlayerController.State.SWIM] else Basis()
	pivot.basis = (trick_basis * _tilt).orthonormalized()
	pivot.position.y = COM_HEIGHT - body_drop
	if st == PlayerController.State.VAULT:
		_vault_support()
	else:
		_solve_contacts(smp.get("contacts", {}), dt)

## Apoyos de manos de cada vault sobre el obstáculo: [mano, desde, hasta, avance sobre el
## obstáculo (0 = borde de delante, 1 = borde de detrás), lateral]. La mano se clava en la
## superficie de arriba y el cuerpo se coloca con los hombros a la longitud del brazo.
const VAULT_HANDS := {
	"Kong Vault": [["hl", 0.28, 0.55, 0.25, -0.17], ["hr", 0.28, 0.55, 0.25, 0.17]],
	"Double Kong": [["hl", 0.18, 0.38, 0.15, -0.17], ["hr", 0.18, 0.38, 0.15, 0.17],
		["hl", 0.55, 0.74, 0.85, -0.17], ["hr", 0.55, 0.74, 0.85, 0.17]],
	"Kash Vault": [["hl", 0.22, 0.45, 0.25, -0.17], ["hr", 0.22, 0.45, 0.25, 0.17]],
	"Speed Vault": [["hl", 0.3, 0.58, 0.45, -0.12]],
	"Lazy Vault": [["hl", 0.25, 0.52, 0.35, -0.15], ["hr", 0.48, 0.74, 0.7, 0.1]],
	"Step Vault": [["hr", 0.22, 0.55, 0.3, 0.15]],
	"Thief Vault": [["hr", 0.35, 0.66, 0.2, 0.15]],
	"Turn Vault": [["hl", 0.25, 0.85, 0.5, -0.2], ["hr", 0.25, 0.85, 0.5, 0.2]],
	"Reverse Vault": [["hl", 0.3, 0.65, 0.45, -0.1]],
}
const VAULT_SHOULDER_H := 0.5

func _vault_support() -> void:
	var v: Dictionary = player.vault
	var defs: Array = VAULT_HANDS.get(v.get("kind", ""), [])
	var s := player.vault_progress()
	var dir: Vector3 = v.get("dir", player.facing)
	var right := dir.cross(Vector3.UP).normalized()
	var p0: Vector3 = v.get("p0", player.global_position)
	var top: float = v.get("top_y", 0.0)
	var front: float = v.get("front", 0.5)
	var depth: float = v.get("depth", 0.6)
	var contacts := {}
	var targets := {}
	var body_w := 0.0
	for h in defs:
		var x0: float = h[1]
		var x1: float = h[2]
		var ramp := 0.05
		var w := 0.0
		if s >= x0 and s <= x1: w = 1.0
		elif s < x0 and s > x0 - ramp: w = (s - (x0 - ramp)) / ramp
		elif s > x1 and s < x1 + ramp: w = 1.0 - (s - x1) / ramp
		# El cuerpo entra y sale del apoyo de forma gradual (sin saltos de la pose)
		var bw := 0.0
		var br := 0.18
		if s >= x0 and s <= x1: bw = 1.0
		elif s < x0 and s > x0 - br: bw = _smooth((s - (x0 - br)) / br)
		elif s > x1 and s < x1 + br: bw = _smooth(1.0 - (s - x1) / br)
		body_w = maxf(body_w, bw)
		if bw > 0.0 and not targets.has(h[0] + "_body"):
			targets[h[0] + "_body"] = true
		if w > contacts.get(h[0], 0.0) or (bw > 0.0 and not targets.has(h[0])):
			contacts[h[0]] = w
			# Punto de apoyo: donde está el cuerpo a mitad del apoyo, dentro de la superficie
			var along: float = float(v.get("length", 1.0)) * (x0 + x1) * 0.5
			along = clampf(lerpf(along, front + depth * float(h[3]), 0.35), front + 0.08, front + maxf(depth - 0.08, 0.1))
			var pt := p0 + dir * along + right * float(h[4])
			targets[h[0]] = Vector3(pt.x, top + HAND_R, pt.z)
	# El cuerpo se apoya en los brazos: se desplaza para que los hombros queden sobre las manos
	var sum_w := 0.0
	var delta := Vector3.ZERO
	for c in contacts.keys():
		var sh := (joints["shoulder_" + c.substr(1, 1)] as Node3D).global_position
		var want: Vector3 = targets[c] + Vector3.UP * VAULT_SHOULDER_H
		delta += want - sh
		sum_w += 1.0
	if sum_w > 0.0:
		delta = (delta / sum_w).limit_length(0.7) * body_w
		pivot.global_position += delta
	var ik := {}
	for c in contacts.keys():
		if float(contacts[c]) > 0.0:
			ik[c] = contacts[c]
	_solve_contacts({}, 0.0, ik, targets)

# ------------------------------------------------------------------ apoyos (IK)

## Apoyos reales: una mano/pie apoyado se fija en un punto del suelo y el brazo/pierna se
## resuelve con IK de dos huesos mientras el cuerpo gira por encima. Además, ninguna mano ni
## pie puede quedar por debajo del suelo en ningún estado.
func _solve_contacts(contacts: Dictionary, _dt: float, extra := {}, extra_targets := {}) -> void:
	if not ik_enabled:
		return
	var gy := player.sensor.ground_below(player.global_position + Vector3.UP * 0.5)
	ground_y = gy if gy != -INF else player.global_position.y - 100.0
	for c in extra.keys():
		# Apoyos fuera del suelo (manos sobre un obstáculo): punto fijado por el movimiento
		contact_w[c] = extra[c]
		plants[c] = extra_targets[c]
		_limb_ik(c, extra_targets[c], float(extra[c]))
	for c in ["hl", "hr", "fl", "fr"]:
		if extra.has(c):
			continue
		var w: float = contacts.get(c, 0.0)
		contact_w[c] = w
		var end := limb_end(c)
		if w > 0.0:
			if not plants.has(c):
				var lift := HAND_R if c.begins_with("h") else SOLE
				var pt := end
				if c.begins_with("h"):
					# La mano se apoya delante del hombro, en la dirección a la que apunta el brazo
					var sh := (joints["shoulder_" + c.substr(1, 1)] as Node3D).global_position
					var off := Vector2(end.x - sh.x, end.z - sh.z).limit_length(0.22)
					pt = Vector3(sh.x + off.x, 0.0, sh.z + off.y)
				plants[c] = Vector3(pt.x, ground_y + lift, pt.z)
			if c.begins_with("f"):
				# Pie apoyado: sigue la horizontal del cuerpo pero baja hasta el suelo
				plants[c] = Vector3(end.x, ground_y + SOLE, end.z)
			_limb_ik(c, plants[c], w)
		else:
			plants.erase(c)
		# Nunca por debajo del suelo
		end = limb_end(c)
		var floor_y := ground_y + (HAND_R if c.begins_with("h") else SOLE * 0.6)
		if end.y < floor_y:
			_limb_ik(c, Vector3(end.x, floor_y, end.z), 1.0)

## Posición en el mundo del extremo (centro de la mano / suela) de cada miembro.
func limb_end(c: String) -> Vector3:
	match c:
		"hl": return (joints.elbow_l as Node3D).global_transform * Vector3(0, -ARM_L2, 0)
		"hr": return (joints.elbow_r as Node3D).global_transform * Vector3(0, -ARM_L2, 0)
		"fl": return (joints.knee_l as Node3D).global_transform * Vector3(0, -LEG_L2, 0)
		"fr": return (joints.knee_r as Node3D).global_transform * Vector3(0, -LEG_L2, 0)
	return Vector3.ZERO

func _limb_ik(c: String, target: Vector3, w: float) -> void:
	var side := "l" if c.ends_with("l") else "r"
	if c.begins_with("h"):
		var spine: Node3D = joints.spine
		# El codo apunta hacia atrás del tronco (el antebrazo se flexiona hacia delante)
		_ik(joints["shoulder_" + side], joints["elbow_" + side], target, ARM_L1, ARM_L2, spine.global_basis.z, 1.0, w)
	else:
		var pelvis: Node3D = joints.pelvis
		# La rodilla apunta hacia delante (la pierna se flexiona hacia atrás)
		_ik(joints["hip_" + side], joints["knee_" + side], target, LEG_L1, LEG_L2, -pelvis.global_basis.z, -1.0, w)

## IK analítico de dos huesos. bend_sign +1: el segundo hueso se dobla hacia -Z local (codo);
## -1: hacia +Z (rodilla). El resultado se mezcla con la pose (peso w).
func _ik(upper: Node3D, lower: Node3D, target: Vector3, l1: float, l2: float, pole: Vector3, bend_sign: float, w: float) -> void:
	var parent := upper.get_parent() as Node3D
	var pg := parent.global_transform
	var root := pg * upper.position
	var v := target - root
	if v.length() < 0.0001:
		return
	var dir := v.normalized()
	var d := clampf(v.length(), 0.05, (l1 + l2) * 0.999)
	var a := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	var bend := PI - acos(clampf((l1 * l1 + l2 * l2 - d * d) / (2.0 * l1 * l2), -1.0, 1.0))
	var p := pole - dir * pole.dot(dir)
	if p.length() < 0.001:
		p = pg.basis.x - dir * pg.basis.x.dot(dir)
	p = p.normalized()
	var u := (dir * cos(a) + p * sin(a)).normalized()
	var y := -u
	var z := (p - u * p.dot(u)).normalized() * bend_sign
	var x := y.cross(z).normalized()
	var local := pg.basis.orthonormalized().inverse() * Basis(x, y, z)
	upper.basis = upper.basis.orthonormalized().slerp(local.orthonormalized(), clampf(w, 0.0, 1.0))
	var lr := lower.rotation
	lower.rotation = Vector3(lerpf(lr.x, bend * bend_sign, w), lr.y * (1.0 - w), lr.z * (1.0 - w))

func _ease_in_out(s: float) -> float:
	return s * s * (3.0 - 2.0 * s)

func _idle_pose(p: Dictionary) -> void:
	var b := sin(Time.get_ticks_msec() * 0.0025)
	p.spine.x = 0.02 * b
	p.shoulder_l.z = -0.12; p.shoulder_r.z = 0.12
	p.elbow_l.x = 0.15; p.elbow_r.x = 0.15
	p.hip_l.x = 0.05; p.hip_r.x = 0.05
	p.knee_l.x = -0.08; p.knee_r.x = -0.08

func _run_pose(p: Dictionary, spd: float, dt: float) -> void:
	var step_len := 0.55 + 0.085 * spd
	var prev_half := floori(phase / PI)
	phase += TAU * spd / (2.0 * step_len) * dt
	if floori(phase / PI) != prev_half:
		footstep.emit(clampf(spd / 9.0, 0.2, 1.0))
	var amt := clampf(spd / 9.0, 0.0, 1.0)
	var amp := 0.35 + 0.65 * amt
	var s := sin(phase)
	p.hip_l.x = s * amp + 0.15 * amt
	p.hip_r.x = -s * amp + 0.15 * amt
	p.knee_l.x = -(0.25 + (0.6 + 0.9 * amt) * maxf(0.0, -cos(phase)))
	p.knee_r.x = -(0.25 + (0.6 + 0.9 * amt) * maxf(0.0, cos(phase)))
	p.shoulder_l.x = -s * (0.4 + 0.7 * amt)
	p.shoulder_r.x = s * (0.4 + 0.7 * amt)
	p.shoulder_l.z = -0.12; p.shoulder_r.z = 0.12
	p.elbow_l.x = 0.6 + 0.9 * amt; p.elbow_r.x = 0.6 + 0.9 * amt
	p.spine.x = -0.06 - 0.3 * amt
	p.spine.y = s * 0.12 * amt
	p.neck.x = 0.15 * amt

func _tuck_pose(p: Dictionary, amount: float) -> void:
	p.spine.x = -0.7 * amount
	p.neck.x = -0.35 * amount
	p.hip_l.x = 2.45 * amount; p.hip_r.x = 2.35 * amount
	p.knee_l.x = -2.55 * amount; p.knee_r.x = -2.5 * amount
	p.hip_l.z = -0.12 * amount; p.hip_r.z = 0.12 * amount
	p.shoulder_l.x = 1.3 * amount; p.shoulder_r.x = 1.3 * amount
	p.shoulder_l.z = -0.25 * amount; p.shoulder_r.z = 0.25 * amount
	p.elbow_l.x = 1.7 * amount; p.elbow_r.x = 1.7 * amount

func _air_pose(p: Dictionary) -> void:
	var tr := player.tricks
	if tr.active:
		_trick_pose(p, tr)
		return
	var vy := player.velocity.y
	var rising := clampf(vy / 8.0, -1.0, 1.0)
	# Despegue sin truco: extensión explosiva y brazos arriba; después piernas preparadas.
	var imp := clampf(1.0 - tr.air_time / 0.14, 0.0, 1.0)
	p.hip_l.x = 0.7 + 0.3 * rising
	p.hip_r.x = 0.15
	p.knee_l.x = -1.1
	p.knee_r.x = -0.5 - 0.4 * maxf(0.0, -rising)
	p.shoulder_l.x = 0.6 + 1.0 * rising
	p.shoulder_r.x = -0.2 + 1.0 * rising
	p.shoulder_l.z = -0.7; p.shoulder_r.z = 0.7
	p.elbow_l.x = 0.5; p.elbow_r.x = 0.5
	p.spine.x = -0.15
	if imp > 0.0:
		_apply(p, {"hip_l": Vector3(-0.1, 0, 0), "hip_r": Vector3(0.2, 0, 0), "knee_l": Vector3(-0.1, 0, 0),
			"knee_r": Vector3(-0.3, 0, 0), "shoulder_l": Vector3(2.4, 0, -0.3), "shoulder_r": Vector3(2.4, 0, 0.3),
			"spine": Vector3(0.1, 0, 0)}, imp)
	var ttg := player.time_to_ground()
	if vy < 0.0 and ttg < 0.25:
		_apply(p, RECEPTION, clampf(1.0 - ttg / 0.25, 0.0, 1.0) * 0.8)

## Variante visual de la acrobacia en curso (cada truco tiene su propia ejecución).
func trick_kind(tr: TrickSystem) -> String:
	var moving := tr.takeoff_speed > 4.0
	var twisting: bool = tr.dir.get("twist", 0) != 0
	match tr.style:
		"back":
			if twisting:
				return "twist"
			return "gainer" if moving else "back"
		"front":
			if twisting:
				return "twist"
			return "webster" if moving else "front"
		"side":
			if twisting:
				return "twist"
			return "side"   # lateral siempre encogido (rodillas al pecho)
		"aerial":
			return "twist" if twisting else "aerial"   # rueda sin manos: piernas abiertas
		"cork":
			return "cork"
		"butterfly":
			return "butterfly"
		"kick":
			return "kick"
		"cartwheel", "roundoff", "bhs", "fhs":
			return tr.style
	return "back"

const V0 := Vector3.ZERO

## Fase 2 · IMPULSO: extensión explosiva al despegar (distinta en cada truco).
func _impulse_pose(kind: String, rs: float) -> Dictionary:
	match kind:
		"front":
			return {"spine": Vector3(-0.35, 0, 0), "neck": Vector3(-0.35, 0, 0),
				"shoulder_l": Vector3(2.75, 0, -0.2), "shoulder_r": Vector3(2.75, 0, 0.2),
				"elbow_l": Vector3(0.15, 0, 0), "elbow_r": Vector3(0.15, 0, 0),
				"hip_l": Vector3(0.1, 0, 0), "hip_r": Vector3(0.1, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)}
		"webster":
			return {"spine": Vector3(-0.75, 0, 0), "neck": Vector3(-0.3, 0, 0),
				"shoulder_l": Vector3(0.5, 0, -0.35), "shoulder_r": Vector3(0.5, 0, 0.35),
				"elbow_l": Vector3(0.3, 0, 0), "elbow_r": Vector3(0.3, 0, 0),
				"hip_l": Vector3(-0.95, 0, 0), "knee_l": Vector3(-0.25, 0, 0),      # pierna de atrás patea arriba
				"hip_r": Vector3(0.55, 0, 0), "knee_r": Vector3(-0.4, 0, 0)}
		"side":
			return {"spine": Vector3(0.1, 0, 0.25 * rs), "neck": Vector3(0.1, 0, 0.2 * rs),
				"shoulder_l": Vector3(2.5, 0, -0.25 + 0.35 * rs), "shoulder_r": Vector3(2.5, 0, 0.25 + 0.35 * rs),
				"elbow_l": Vector3(0.2, 0, 0), "elbow_r": Vector3(0.2, 0, 0),
				"hip_l": Vector3(-0.05, 0, 0), "hip_r": Vector3(-0.05, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)}
		"aerial":
			# Tronco tumbado hacia delante, brazos lanzados abajo y atrás, pierna de atrás arriba
			return {"spine": Vector3(-1.05, 0.35 * rs, 0), "neck": Vector3(0.45, 0, 0),
				"shoulder_l": Vector3(-0.5, 0, -0.5), "shoulder_r": Vector3(-0.5, 0, 0.5),
				"elbow_l": Vector3(0.4, 0, 0), "elbow_r": Vector3(0.4, 0, 0),
				"hip_l": Vector3(-0.9, 0, -0.3), "knee_l": Vector3(-0.15, 0, 0),
				"hip_r": Vector3(0.35, 0, 0.1), "knee_r": Vector3(-0.2, 0, 0)}
		"gainer":
			return {"spine": Vector3(0.3, 0, 0), "neck": Vector3(0.4, 0, 0),
				"shoulder_l": Vector3(2.9, 0, -0.25), "shoulder_r": Vector3(2.9, 0, 0.25),
				"elbow_l": Vector3(0.1, 0, 0), "elbow_r": Vector3(0.1, 0, 0),
				"hip_r": Vector3(1.6, 0, 0), "knee_r": Vector3(-0.35, 0, 0),         # pierna libre lanzada arriba
				"hip_l": Vector3(-0.2, 0, 0), "knee_l": Vector3(-0.05, 0, 0)}
		"cork", "twist":
			return {"spine": Vector3(0.2, 0.55 * rs, 0), "neck": Vector3(0.3, 0.3 * rs, 0),
				"shoulder_l": Vector3(2.5, 0, -0.7), "shoulder_r": Vector3(1.7, 0, 0.9),
				"elbow_l": Vector3(0.2, 0, 0), "elbow_r": Vector3(0.6, 0, 0),
				"hip_l": Vector3(-0.1, 0, 0), "hip_r": Vector3(0.4, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.5, 0, 0)}
		"kick":
			# Patada giratoria: brazos lanzados hacia el giro, pierna de impulso empujando
			return {"spine": Vector3(-0.15, 0.6 * rs, 0), "neck": Vector3(0.1, 0.4 * rs, 0),
				"shoulder_l": Vector3(1.6, 0, -1.0), "shoulder_r": Vector3(1.2, 0, 1.2),
				"elbow_l": Vector3(0.6, 0, 0), "elbow_r": Vector3(0.6, 0, 0),
				"hip_l": Vector3(-0.1, 0, 0), "knee_l": Vector3(-0.1, 0, 0),
				"hip_r": Vector3(1.2, 0, 0), "knee_r": Vector3(-1.5, 0, 0)}
		"butterfly":
			return {"spine": Vector3(-0.75, 0.6 * rs, 0), "neck": Vector3(0.4, 0, 0),
				"shoulder_l": Vector3(1.5, 0, -1.0), "shoulder_r": Vector3(1.5, 0, 1.0),
				"elbow_l": Vector3(0.5, 0, 0), "elbow_r": Vector3(0.5, 0, 0),
				"hip_l": Vector3(-0.85, 0, -0.2), "knee_l": Vector3(-0.15, 0, 0),
				"hip_r": Vector3(0.3, 0, 0), "knee_r": Vector3(-0.3, 0, 0)}
		"cartwheel", "roundoff":
			# Zancada de entrada: pierna delantera flexionada, brazos arriba, tronco cayendo de lado
			var lean := 0.35 if kind == "cartwheel" else 0.6
			return {"spine": Vector3(-lean, 0, 0.35 * rs), "neck": Vector3(0.2, 0, 0.2 * rs),
				"shoulder_l": Vector3(2.95, 0, -0.15), "shoulder_r": Vector3(2.95, 0, 0.15),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_r": Vector3(0.75, 0, 0), "knee_r": Vector3(-0.7, 0, 0),
				"hip_l": Vector3(-0.45, 0, 0), "knee_l": Vector3(-0.05, 0, 0)}
		"bhs":
			# Flic-flac: tras sentarse, extensión explosiva con brazos atrás-arriba y cabeza atrás
			return {"spine": Vector3(0.5, 0, 0), "neck": Vector3(0.6, 0, 0),
				"shoulder_l": Vector3(3.05, 0, -0.2), "shoulder_r": Vector3(3.05, 0, 0.2),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(-0.3, 0, 0), "hip_r": Vector3(-0.3, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)}
		"fhs":
			# Paloma: tronco lanzado adelante buscando el suelo con las manos, pierna de atrás pateando
			return {"spine": Vector3(-0.75, 0, 0), "neck": Vector3(-0.15, 0, 0),
				"shoulder_l": Vector3(2.9, 0, -0.15), "shoulder_r": Vector3(2.9, 0, 0.15),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(-0.8, 0, 0), "knee_l": Vector3(-0.1, 0, 0),
				"hip_r": Vector3(0.55, 0, 0), "knee_r": Vector3(-0.45, 0, 0)}
	# Backflip: brazos arriba, pecho y cabeza atrás, piernas estiradas empujando el suelo
	return {"spine": Vector3(0.3, 0, 0), "neck": Vector3(0.45, 0, 0),
		"shoulder_l": Vector3(2.95, 0, -0.25), "shoulder_r": Vector3(2.95, 0, 0.25),
		"elbow_l": Vector3(0.1, 0, 0), "elbow_r": Vector3(0.1, 0, 0),
		"hip_l": Vector3(-0.15, 0, 0), "hip_r": Vector3(-0.15, 0, 0), "knee_l": Vector3(-0.05, 0, 0), "knee_r": Vector3(-0.05, 0, 0)}

## Fases 3-4 · AGRUPACIÓN y ROTACIÓN: forma del cuerpo durante el giro.
func _gather_pose(kind: String, rs: float, ph: float) -> Dictionary:
	match kind:
		"front":
			# Agrupado cerrado, cabeza metida, manos abrazando las espinillas
			return {"spine": Vector3(-1.0, 0, 0), "neck": Vector3(-0.65, 0, 0),
				"hip_l": Vector3(2.55, 0, -0.08), "hip_r": Vector3(2.5, 0, 0.08), "knee_l": Vector3(-2.65, 0, 0), "knee_r": Vector3(-2.6, 0, 0),
				"shoulder_l": Vector3(0.75, 0, 0.12), "shoulder_r": Vector3(0.75, 0, -0.12),
				"elbow_l": Vector3(1.75, 0, 0), "elbow_r": Vector3(1.75, 0, 0)}
		"webster":
			# Mortal adelante a una pierna: tijera, la pierna de atrás llega tarde
			return {"spine": Vector3(-0.9, 0, 0), "neck": Vector3(-0.5, 0, 0),
				"hip_r": Vector3(2.45, 0, 0.05), "knee_r": Vector3(-2.55, 0, 0),
				"hip_l": Vector3(0.6, 0, -0.05), "knee_l": Vector3(-1.9, 0, 0),
				"shoulder_l": Vector3(0.9, 0, 0.1), "shoulder_r": Vector3(0.9, 0, -0.1),
				"elbow_l": Vector3(1.5, 0, 0), "elbow_r": Vector3(1.5, 0, 0)}
		"side":
			# Sideflip real: bola cerrada. Rodillas al pecho, talones a los glúteos, manos
			# agarrando las rodillas y cabeza metida; la pierna de atrás sube primero.
			return {"spine": Vector3(-0.85, 0, 0.15 * rs), "neck": Vector3(-0.4, 0, 0.2 * rs),
				"hip_l": Vector3(2.7, 0, 0.1 * rs), "hip_r": Vector3(2.65, 0, 0.1 * rs),
				"knee_l": Vector3(-2.75, 0, 0), "knee_r": Vector3(-2.75, 0, 0),
				"shoulder_l": Vector3(1.15, 0, 0.18), "shoulder_r": Vector3(1.15, 0, -0.18),
				"elbow_l": Vector3(1.05, 0, 0), "elbow_r": Vector3(1.05, 0, 0)}
		"aerial":
			# Rueda sin manos: tronco carpado, piernas abiertas en el plano del giro, brazos pegados
			return {"spine": Vector3(-1.1, 0, 0), "neck": Vector3(0.45, 0, 0),
				"hip_l": Vector3(0.15, 0, -1.05), "hip_r": Vector3(0.3, 0, 0.9),
				"knee_l": Vector3(-0.2, 0, 0), "knee_r": Vector3(-0.35, 0, 0),
				"shoulder_l": Vector3(0.45, 0, 0.45), "shoulder_r": Vector3(0.45, 0, -0.45),
				"elbow_l": Vector3(1.95, 0, 0), "elbow_r": Vector3(1.95, 0, 0)}
		"gainer":
			# Mortal atrás a una pierna: la pierna libre agrupa primero, la de impulso llega después
			return {"spine": Vector3(-0.5, 0, 0), "neck": Vector3(0.2, 0, 0),
				"hip_r": Vector3(2.5, 0, 0.08), "knee_r": Vector3(-2.6, 0, 0),
				"hip_l": Vector3(1.7, 0, -0.1), "knee_l": Vector3(-2.0, 0, 0),
				"shoulder_l": Vector3(1.1, 0, -0.15), "shoulder_r": Vector3(1.1, 0, 0.15),
				"elbow_l": Vector3(1.2, 0, 0), "elbow_r": Vector3(1.2, 0, 0)}
		"cork":
			# Tirabuzón fuera de eje: brazos cruzados al pecho, piernas juntas semiagrupadas
			return {"spine": Vector3(-0.3, 0, 0), "neck": Vector3(0.2, 0, 0),
				"hip_l": Vector3(1.45, 0, 0.06), "hip_r": Vector3(1.55, 0, -0.06),
				"knee_l": Vector3(-1.75, 0, 0), "knee_r": Vector3(-1.85, 0, 0),
				"shoulder_l": Vector3(0.6, 0, 0.6), "shoulder_r": Vector3(0.6, 0, -0.6),
				"elbow_l": Vector3(2.35, 0, 0), "elbow_r": Vector3(2.35, 0, 0)}
		"twist":
			# Mortal con tirabuzón añadido: cuerpo más largo, brazos cerrados para girar rápido
			return {"spine": Vector3(-0.2, 0, 0), "neck": Vector3(0.1, 0, 0),
				"hip_l": Vector3(1.15, 0, 0.06), "hip_r": Vector3(1.2, 0, -0.06),
				"knee_l": Vector3(-1.35, 0, 0), "knee_r": Vector3(-1.4, 0, 0),
				"shoulder_l": Vector3(0.55, 0, 0.6), "shoulder_r": Vector3(0.55, 0, -0.6),
				"elbow_l": Vector3(2.35, 0, 0), "elbow_r": Vector3(2.35, 0, 0)}
		"kick":
			# Giro vertical con brazos cerrados; a mitad de vuelta sale la patada (pierna extendida)
			var kf := sin(ph * 0.5)
			var kick := clampf(kf * 1.4, 0.0, 1.0)
			return {"spine": Vector3(-0.2 - 0.3 * kick, 0, 0.35 * kick * rs), "neck": Vector3(0.15, 0, 0),
				"shoulder_l": Vector3(0.6, 0, 0.55), "shoulder_r": Vector3(0.6, 0, -0.55),
				"elbow_l": Vector3(2.2, 0, 0), "elbow_r": Vector3(2.2, 0, 0),
				"hip_l": Vector3(0.3 + 1.2 * kick, 0, -0.9 * kick), "knee_l": Vector3(-1.2 + 1.05 * kick, 0, 0),
				"hip_r": Vector3(0.9 - 0.5 * kick, 0, 0.05), "knee_r": Vector3(-1.4 + 0.6 * kick, 0, 0)}
		"butterfly":
			# Cuerpo tumbado, patada de tijera continua, brazos a la altura del hombro y flexionados
			var k := sin(ph)
			return {"spine": Vector3(0.15, 0.25 * k, 0), "neck": Vector3(0.4, 0, 0),
				"hip_l": Vector3(-0.15 + 1.05 * k, 0, -0.3), "hip_r": Vector3(-0.15 - 1.05 * k, 0, 0.3),
				"knee_l": Vector3(-0.15 - 0.3 * maxf(0.0, -k), 0, 0), "knee_r": Vector3(-0.15 - 0.3 * maxf(0.0, k), 0, 0),
				"shoulder_l": Vector3(1.35 + 0.35 * k, 0, -0.75), "shoulder_r": Vector3(1.35 - 0.35 * k, 0, 0.75),
				"elbow_l": Vector3(1.1, 0, 0), "elbow_r": Vector3(1.1, 0, 0)}
		"cartwheel":
			# Rueda con apoyo: brazos estirados por encima de la cabeza (al suelo), cuerpo recto
			# en el plano del giro, piernas en straddle amplio
			return {"spine": Vector3(0.0, 0, 0), "neck": Vector3(0.3, 0, 0),
				"shoulder_l": Vector3(3.05, 0, -0.2), "shoulder_r": Vector3(3.05, 0, 0.2),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(0.05, 0, -1.15), "hip_r": Vector3(0.05, 0, 1.15),
				"knee_l": Vector3(-0.05, 0, 0), "knee_r": Vector3(-0.05, 0, 0)}
		"roundoff":
			# Rondada: en la vertical las piernas se juntan y la cadera carpa para el golpe al suelo
			return {"spine": Vector3(-0.35, 0, 0), "neck": Vector3(0.35, 0, 0),
				"shoulder_l": Vector3(3.0, 0, -0.15), "shoulder_r": Vector3(3.0, 0, 0.15),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(0.6, 0, -0.08), "hip_r": Vector3(0.6, 0, 0.08),
				"knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)}
		"bhs":
			# Puente en el aire: espalda arqueada, cabeza atrás buscando las manos, piernas juntas
			return {"spine": Vector3(0.75, 0, 0), "neck": Vector3(0.7, 0, 0),
				"shoulder_l": Vector3(3.05, 0, -0.18), "shoulder_r": Vector3(3.05, 0, 0.18),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(-0.45, 0, -0.04), "hip_r": Vector3(-0.45, 0, 0.04),
				"knee_l": Vector3(-0.15, 0, 0), "knee_r": Vector3(-0.15, 0, 0)}
		"fhs":
			# Vuelo extendido y arqueado sobre las manos, piernas ligeramente separadas
			return {"spine": Vector3(0.45, 0, 0), "neck": Vector3(0.6, 0, 0),
				"shoulder_l": Vector3(3.05, 0, -0.18), "shoulder_r": Vector3(3.05, 0, 0.18),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(-0.5, 0, 0), "hip_r": Vector3(-0.15, 0, 0),
				"knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.15, 0, 0)}
	# Backflip: rodillas al pecho, manos a las espinillas, cabeza neutra mirando atrás
	return {"spine": Vector3(-0.6, 0, 0), "neck": Vector3(0.15, 0, 0),
		"hip_l": Vector3(2.5, 0, -0.1), "hip_r": Vector3(2.45, 0, 0.1), "knee_l": Vector3(-2.6, 0, 0), "knee_r": Vector3(-2.55, 0, 0),
		"shoulder_l": Vector3(1.0, 0, -0.12), "shoulder_r": Vector3(1.0, 0, 0.12),
		"elbow_l": Vector3(1.35, 0, 0), "elbow_r": Vector3(1.35, 0, 0)}

## Fase 5 · APERTURA: el cuerpo se alarga (frena el giro) y las piernas buscan el suelo.
const OPEN_POSE := {"spine": Vector3(-0.12, 0, 0), "neck": Vector3(0.12, 0, 0),
	"hip_l": Vector3(0.45, 0, -0.06), "hip_r": Vector3(0.4, 0, 0.06), "knee_l": Vector3(-0.45, 0, 0), "knee_r": Vector3(-0.4, 0, 0),
	"shoulder_l": Vector3(1.75, 0, -0.45), "shoulder_r": Vector3(1.75, 0, 0.45),
	"elbow_l": Vector3(0.35, 0, 0), "elbow_r": Vector3(0.35, 0, 0)}

## Fase 6 · RECEPCIÓN: piernas flexionadas listas para absorber, brazos delante para equilibrar.
const RECEPTION := {"spine": Vector3(-0.3, 0, 0), "neck": Vector3(0.15, 0, 0),
	"hip_l": Vector3(0.8, 0, -0.08), "hip_r": Vector3(0.7, 0, 0.08), "knee_l": Vector3(-1.1, 0, 0), "knee_r": Vector3(-1.0, 0, 0),
	"shoulder_l": Vector3(1.3, 0, -0.55), "shoulder_r": Vector3(1.3, 0, 0.55),
	"elbow_l": Vector3(0.5, 0, 0), "elbow_r": Vector3(0.5, 0, 0)}

func _apply(p: Dictionary, vals: Dictionary, w: float) -> void:
	if w <= 0.0:
		return
	w = minf(w, 1.0)
	for k in vals.keys():
		p[k] = (p[k] as Vector3).lerp(vals[k], w)

func _smooth(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

## Pose de acrobacia por fases: impulso → agrupación → rotación → apertura → recepción.
## Las fases salen del estado físico real del giro (no de una animación fija).
var last_phase := ""          # para pruebas/depuración: fase visible actual
var last_kind := ""

func _trick_pose(p: Dictionary, tr: TrickSystem) -> void:
	var kind := trick_kind(tr)
	var ax := tr.primary_axis()
	var s: int = tr.dir.get(ax, 1)
	var rs := float(tr.dir.get("roll", 0)) if kind in ["side", "aerial", "cartwheel", "roundoff"] else float(tr.dir.get("twist", 0))
	if rs == 0.0:
		rs = float(tr.dir.get("spin", 1))
	var period := tr.twist_period if ax == "twist" else TAU
	var prog: float = absf(tr.total.get(ax, 0.0))
	var goal_turns := maxi(int(tr.goal.get(ax, 1)), 1)
	# Agrupación: empieza en cuanto termina el impulso; manteniendo el dedo es inmediata y más cerrada.
	var early := kind in ["side", "back", "front", "gainer", "cartwheel", "roundoff", "bhs", "fhs"]
	var gather := _smooth((tr.air_time - (0.03 if early else 0.06)) / (0.07 if tr.tucked or early else 0.1))
	# Apertura: al acercarse la última vuelta pedida (sin mantener) el cuerpo se alarga y frena.
	var open := 0.0
	if tr.all_settled():
		open = 1.0
	elif tr.spotting or not tr.tucked:
		var next_stop := (floorf(prog / period + 0.0001) + 1.0) * period
		if next_stop >= goal_turns * period - 0.001 or tr.spotting:
			# Se abre solo en el último tramo de la vuelta (~290°-330°): agrupado durante casi todo el giro
			open = _smooth((period * 0.2 - (next_stop - prog)) / (period * 0.11))
	var imp := _smooth(1.0 - tr.air_time / (0.1 if early else 0.13))
	var ttg := player.time_to_ground()
	var rec := 0.0
	if open >= 0.99 and player.velocity.y < 0.0:
		rec = _smooth(1.0 - ttg / 0.24)

	var ph := absf(tr.total_spin) * 2.0 + tr.air_time * 9.0
	if kind == "kick":
		ph = absf(tr.total_twist)
	var g := _gather_pose(kind, rs, ph)
	# Base abierta → agrupado → impulso (inicio) → recepción (final)
	_apply(p, OPEN_POSE, 1.0)
	if kind == "butterfly":
		_apply(p, g, 1.0 - open * 0.6)       # la tijera sigue hasta casi aterrizar
	else:
		_apply(p, g, gather * (1.0 - open))
		# Vuelta ya completada pero queda vuelo: el atleta no se queda tieso, mantiene las
		# rodillas recogidas (medio agrupado) y solo extiende las piernas al buscar el suelo.
		if open > 0.0 and kind in ["back", "front", "side", "gainer", "webster", "twist", "cork"]:
			var compact := clampf((ttg - 0.22) / 0.2, 0.0, 1.0)
			_apply(p, g, gather * open * 0.55 * compact)
	_apply(p, _impulse_pose(kind, rs), imp)
	_apply(p, RECEPTION, rec)
	last_kind = kind
	if imp > 0.5:
		last_phase = "impulso"
	elif rec > 0.3:
		last_phase = "recepcion"
	elif open > 0.5:
		last_phase = "apertura"
	elif gather > 0.6:
		last_phase = "agrupado"
	else:
		last_phase = "agrupando"

## Fase 1 · PREPARACIÓN (en el suelo, antes de despegar): flexión de piernas, brazos atrás.
## Cada mortal tiene su preparación: contramovimiento de piernas y balanceo de brazos que
## empieza atrás/abajo y se lanza hacia arriba justo antes de despegar (p = progreso 0..1).
func _load_pose(p: Dictionary) -> float:
	var f := player.flick_buffer if player.flick_timer > 0.0 else Vector2.ZERO
	var sec := TouchControls.sector_of(f) if f != Vector2.ZERO else 99
	var kind := player.jump_flip
	var prog := clampf(1.0 - player.jump_load / maxf(player.jump_load_total, 0.01), 0.0, 1.0)
	var down := _smooth(prog / 0.65)                    # bajada (flexión)
	var swing := _smooth((prog - 0.6) / 0.4)            # brazos lanzados arriba al final
	var depth := 1.0
	if kind.begins_with("double"):
		depth = 1.2
	elif kind == "jump":
		depth = 0.75
	var arm_x := lerpf(lerpf(0.3, -1.15, down), 2.2, swing)
	var vals := {"spine": Vector3(-0.42 * down * depth, 0, 0), "neck": Vector3(0.2, 0, 0),
		"hip_l": Vector3(1.1 * down * depth, 0, -0.06), "hip_r": Vector3(1.05 * down * depth, 0, 0.06),
		"knee_l": Vector3(-1.8 * down * depth, 0, 0), "knee_r": Vector3(-1.75 * down * depth, 0, 0),
		"shoulder_l": Vector3(arm_x, 0, -0.18), "shoulder_r": Vector3(arm_x, 0, 0.18),
		"elbow_l": Vector3(0.35, 0, 0), "elbow_r": Vector3(0.35, 0, 0)}
	var side := 1.0 if sec in [0, 1, -1] else -1.0
	match kind:
		"front", "double_front":
			# Pecho delante y brazos muy atrás arriba: se proyecta adelante
			vals.spine = Vector3(-0.7 * down, 0, 0)
			vals.neck = Vector3(-0.1, 0, 0)
			var fx := lerpf(lerpf(0.4, -1.5, down), 2.6, swing)
			vals.shoulder_l = Vector3(fx, 0, -0.15); vals.shoulder_r = Vector3(fx, 0, 0.15)
		"side", "double_side":
			# Tronco cargado girado hacia el lado del giro, un brazo cruza y el otro abre
			vals.spine = Vector3(-0.5 * down, 0.55 * side * down, 0.15 * side * down)
			vals.shoulder_l = Vector3(lerpf(-0.4, 2.3, swing), 0, lerpf(-0.9, -0.3, swing))
			vals.shoulder_r = Vector3(lerpf(0.9, 2.3, swing), 0, lerpf(0.4, 0.3, swing))
		"aerial":
			# Zancada: pierna delantera flexionada, la de atrás estirada, tronco que cae y brazos barriendo
			vals.spine = Vector3(-0.85 * down, 0.2 * down, 0)
			vals.hip_r = Vector3(0.95 * down, 0, 0.05); vals.knee_r = Vector3(-1.0 * down, 0, 0)
			vals.hip_l = Vector3(-0.45 * down, 0, -0.05); vals.knee_l = Vector3(-0.15 * down, 0, 0)
			var ax := lerpf(lerpf(2.4, 0.4, down), -0.6, swing)
			vals.shoulder_l = Vector3(ax, 0, -0.5); vals.shoulder_r = Vector3(ax, 0, 0.5)
		"butterfly":
			# Carga baja y girada, brazos lanzados hacia el lado del giro
			vals.spine = Vector3(-0.9 * down, 0.6 * down, 0)
			vals.shoulder_l = Vector3(lerpf(0.4, 1.4, swing), 0, lerpf(-1.2, -0.6, swing))
			vals.shoulder_r = Vector3(lerpf(0.4, 1.4, swing), 0, lerpf(1.2, 0.6, swing))
		_:
			if sec in [-1, -3]:
				vals.spine.y = 0.35 * side * down       # cork: carga ligeramente girada
	_apply(p, vals, 1.0)
	return (0.24 * depth) * down
func _vault_pose(p: Dictionary) -> Basis:
	var s := player.vault_progress()
	var kind: String = player.vault.get("kind", "Speed Vault")
	var arc := sin(s * PI)
	match kind:
		"Kong Vault":
			_tuck_pose(p, arc)
			p.shoulder_l.x = lerpf(2.8, 0.3, s); p.shoulder_r.x = lerpf(2.8, 0.3, s)
			p.elbow_l.x = 0.2; p.elbow_r.x = 0.2
			# Tronco casi horizontal: hombros sobre las manos, cadera alta y piernas pasando entre los brazos
			return Basis(Vector3.RIGHT, -1.4 * arc)
		"Double Kong":
			# Dos apoyos de manos: dos arcos de agrupado sobre el obstáculo
			var a2 := absf(sin(s * TAU))
			_tuck_pose(p, a2)
			p.shoulder_l.x = 2.6 - 1.2 * a2; p.shoulder_r.x = 2.6 - 1.2 * a2
			p.elbow_l.x = 0.2; p.elbow_r.x = 0.2
			return Basis(Vector3.RIGHT, -0.9 * a2)
		"Kash Vault":
			# Kong al principio, dash (piernas delante) al final
			if s < 0.5:
				_tuck_pose(p, sin(s * TAU) * 0.9)
				p.shoulder_l.x = 2.7; p.shoulder_r.x = 2.7
				return Basis(Vector3.RIGHT, -0.9 * sin(s * TAU))
			var k2 := sin((s - 0.5) * TAU)
			p.hip_l.x = 1.5 * k2; p.hip_r.x = 1.4 * k2
			p.knee_l.x = -0.2; p.knee_r.x = -0.3
			p.shoulder_l.x = -0.6 * k2; p.shoulder_r.x = -0.6 * k2
			return Basis(Vector3.RIGHT, 0.5 * k2)
		"Reverse Vault":
			# Giro completo de espaldas sobre el obstáculo, apoyando una mano
			p.hip_l.x = 1.0 * arc; p.hip_r.x = 0.8 * arc
			p.knee_l.x = -0.9 * arc; p.knee_r.x = -1.1 * arc
			p.shoulder_r.x = 1.2 * arc; p.shoulder_r.z = 0.6 * arc
			p.shoulder_l.z = -1.0 * arc
			p.spine.x = -0.3 * arc
			return Basis(Vector3.UP, -TAU * _ease_in_out(s)) * Basis(Vector3.BACK, 0.35 * arc)
		"Thief Vault":
			arc = clampf(sin(s * PI) * 1.7, 0.0, 1.0)    # la postura se forma ya al despegar
			# Piernas primero, juntas y rasantes; una mano atrás sobre el obstáculo, la otra delante
			# para equilibrar; tronco algo girado hacia la mano de apoyo
			p.hip_l.x = 1.35 * arc; p.hip_r.x = 1.2 * arc
			p.knee_l.x = -0.35 * arc; p.knee_r.x = -0.5 * arc
			p.shoulder_r.x = -0.9 * arc; p.shoulder_r.z = 0.35 * arc
			p.shoulder_l.x = 1.3 * arc; p.shoulder_l.z = -0.4 * arc
			p.spine.x = 0.2 * arc
			return Basis(Vector3.UP, 0.45 * arc) * Basis(Vector3.RIGHT, 0.32 * arc)
		"Turn Vault":
			# Dos manos sobre el obstáculo, cadera arriba y piernas recogidas a un lado mientras el
			# cuerpo gira media vuelta; cae mirando al obstáculo
			arc = clampf(sin(s * PI) * 1.7, 0.0, 1.0)
			var turn := _ease_in_out(clampf((s - 0.15) / 0.7, 0.0, 1.0))
			p.shoulder_l.x = 1.25; p.shoulder_r.x = 1.25
			p.elbow_l.x = 0.15; p.elbow_r.x = 0.15
			p.hip_l.x = 1.3 * arc; p.hip_r.x = 1.15 * arc
			p.knee_l.x = -1.5 * arc; p.knee_r.x = -1.3 * arc
			p.spine.x = -0.35 * arc
			return Basis(Vector3.UP, PI * turn) * Basis(Vector3.RIGHT, -0.55 * arc) * Basis(Vector3.BACK, 0.35 * arc)
		"Dash Vault":
			p.hip_l.x = 1.5 * arc; p.hip_r.x = 1.4 * arc
			p.knee_l.x = -0.2; p.knee_r.x = -0.3
			p.shoulder_l.x = -0.7 * arc; p.shoulder_r.x = -0.7 * arc
			return Basis(Vector3.RIGHT, 0.6 * arc)
		"Step Vault", "Step Up", "Climb Up":
			p.hip_r.x = 1.6 * arc; p.knee_r.x = -1.9 * arc
			p.hip_l.x = 0.6 * arc; p.knee_l.x = -0.9 * arc
			p.shoulder_l.x = 1.0 * arc; p.shoulder_r.x = 0.6 * arc
			p.spine.x = -0.35 * arc
			return Basis()
		_:
			# Speed / Lazy vault: cuerpo de lado, mano de apoyo abajo, piernas por encima
			p.hip_l.x = 1.3 * arc; p.hip_r.x = 1.1 * arc
			p.knee_l.x = -0.35 * arc; p.knee_r.x = -0.6 * arc
			p.shoulder_l.z = -0.2 * arc; p.shoulder_r.z = 1.4 * arc
			p.shoulder_l.x = 0.4 * arc
			var roll := 0.85 if kind == "Speed Vault" else 1.05
			return Basis(Vector3.BACK, roll * arc) * Basis(Vector3.UP, (0.5 if kind == "Lazy Vault" else 0.2) * arc)
