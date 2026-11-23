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
	var target := _base_pose()
	var tilt := Basis()
	var drop := 0.0
	var blend_speed := 14.0

	# Orientación horizontal
	var fwd := player.facing
	var yaw_target := atan2(-fwd.x, -fwd.z)
	_yaw = lerp_angle(_yaw, yaw_target, 1.0 - exp(-20.0 * dt))
	rotation.y = _yaw

	match st:
		PlayerController.State.GROUND:
			if spd > 0.3:
				_run_pose(target, spd, dt)
			else:
				_idle_pose(target)
			if player.stun > 0.0:
				drop = 0.18
				target.spine.x = -0.5
				target.hip_l.x = 0.9; target.hip_r.x = 0.7
				target.knee_l.x = -1.4; target.knee_r.x = -1.2
			var c := player.land_impact
			if c > 0.0:
				drop += 0.28 * c
				target.hip_l.x += 1.0 * c; target.hip_r.x += 1.0 * c
				target.knee_l.x -= 1.8 * c; target.knee_r.x -= 1.8 * c
				target.spine.x -= 0.5 * c
				target.shoulder_l.z -= 0.6 * c; target.shoulder_r.z += 0.6 * c
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
		PlayerController.State.CRASH:
			var s := clampf(player.state_time / 0.35, 0.0, 1.0)
			tilt = Basis(Vector3.RIGHT, -1.45 * s)
			drop = 0.78 * s
			target.shoulder_l.z = -1.3; target.shoulder_r.z = 1.2
			target.shoulder_l.x = 0.4; target.hip_l.x = 0.3; target.knee_l.x = -0.6
			target.hip_r.x = -0.1
			if player.state_time > player.t.crash_time - 0.4:
				var g := clampf((player.state_time - (player.t.crash_time - 0.4)) / 0.4, 0.0, 1.0)
				tilt = Basis(Vector3.RIGHT, -1.45 * (1.0 - g))
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
	body_drop = lerpf(body_drop, drop, 1.0 - exp(-18.0 * dt))
	_tilt = _tilt.slerp(tilt, 1.0 - exp(-22.0 * dt)) if st != PlayerController.State.ROLL and st != PlayerController.State.VAULT else tilt
	var trick_basis := player.tricks.basis if st in [PlayerController.State.AIR, PlayerController.State.SWIM] else Basis()
	pivot.basis = (trick_basis * _tilt).orthonormalized()
	pivot.position.y = COM_HEIGHT - body_drop

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
	p.hip_l.x = 0.7 + 0.3 * rising
	p.hip_r.x = 0.15
	p.knee_l.x = -1.1
	p.knee_r.x = -0.5 - 0.4 * maxf(0.0, -rising)
	p.shoulder_l.x = 0.6 + 1.0 * rising
	p.shoulder_r.x = -0.2 + 1.0 * rising
	p.shoulder_l.z = -0.7; p.shoulder_r.z = 0.7
	p.elbow_l.x = 0.5; p.elbow_r.x = 0.5
	p.spine.x = -0.15

## Pose de acrobacia en tres fases: preparación (despegue), ejecución y recepción.
func _trick_pose(p: Dictionary, tr: TrickSystem) -> void:
	var prep := clampf(1.0 - tr.air_time / 0.16, 0.0, 1.0)      # 1 al despegar → 0
	var landing_prep := tr.spotting or tr.all_settled()
	var tuck := tr.tuck_amount
	# Agrupado natural a mitad de cada vuelta (como un practicante real), aunque no se mantenga
	var ax := tr.primary_axis()
	if not landing_prep and tr.style in ["back", "front", "cork"]:
		var frac := fmod(absf(tr.total.get(ax, 0.0)), TAU) / TAU
		var natural := clampf(sin(PI * clampf(frac / 0.85, 0.0, 1.0)) * 1.4, 0.0, 1.0) * 0.85
		tuck = maxf(tuck, natural)
	match tr.style:
		"side":
			# Lateral / aerial: piernas abiertas en tijera, brazos fuera
			var aerial := tr.takeoff_speed > 4.0
			p.shoulder_l.z = -1.7; p.shoulder_r.z = 1.7
			p.shoulder_l.x = 0.3; p.shoulder_r.x = 0.3
			p.hip_l.z = -0.75 if aerial else -0.45; p.hip_r.z = 0.55 if aerial else 0.45
			p.hip_l.x = 0.5 * tuck; p.hip_r.x = 0.5 * tuck
			p.knee_l.x = -0.25 - 1.3 * tuck; p.knee_r.x = -0.25 - 1.3 * tuck
			p.spine.x = -0.25 * tuck
		"butterfly":
			# Butterfly kick: cuerpo tumbado, patada de tijera, brazos extendidos
			var ph := absf(tr.total_spin) * 2.0
			p.shoulder_l.z = -1.5; p.shoulder_r.z = 1.5
			p.shoulder_l.x = 0.4; p.shoulder_r.x = 0.4
			p.hip_l.x = -0.3 + 0.9 * sin(ph); p.hip_r.x = -0.3 - 0.9 * sin(ph)
			p.hip_l.z = -0.35; p.hip_r.z = 0.35
			p.knee_l.x = -0.25; p.knee_r.x = -0.25
			p.spine.x = 0.25
			p.neck.x = 0.35
		_:
			# Mortales atrás/adelante y corks: agrupado al mantener, carpado al soltar
			_tuck_pose(p, maxf(tuck, 0.0))
			var open := 1.0 - tuck
			if open > 0.0:
				p.hip_l.x = lerpf(p.hip_l.x, 1.35, open); p.hip_r.x = lerpf(p.hip_r.x, 1.35, open)
				p.knee_l.x = lerpf(p.knee_l.x, -0.4, open); p.knee_r.x = lerpf(p.knee_r.x, -0.4, open)
				p.shoulder_l.x = lerpf(p.shoulder_l.x, 1.6, open); p.shoulder_r.x = lerpf(p.shoulder_r.x, 1.6, open)
				p.elbow_l.x = lerpf(p.elbow_l.x, 0.3, open); p.elbow_r.x = lerpf(p.elbow_r.x, 0.3, open)
				p.spine.x = lerpf(p.spine.x, -0.35, open)
			if tr.dir.get("twist", 0) != 0 and not tr.settled.get("twist", false):
				# Tirabuzón: brazos cerrados al pecho, piernas juntas y rectas
				p.shoulder_l.x = 0.5; p.shoulder_r.x = 0.5
				p.shoulder_l.z = 0.45; p.shoulder_r.z = -0.45
				p.elbow_l.x = 2.3; p.elbow_r.x = 2.3
				p.hip_l.x = lerpf(p.hip_l.x, 0.2, 0.6); p.hip_r.x = lerpf(p.hip_r.x, 0.2, 0.6)
				p.knee_l.x = lerpf(p.knee_l.x, -0.15, 0.6); p.knee_r.x = lerpf(p.knee_r.x, -0.15, 0.6)
				p.hip_l.z = 0.08; p.hip_r.z = -0.08
	# Preparación: impulso de brazos y extensión de piernas al despegar
	if prep > 0.0:
		var arms := 2.9
		var spine := 0.25
		var neck := 0.3
		match tr.style:
			"front":
				arms = 2.6; spine = -0.3; neck = -0.35
			"side", "butterfly":
				arms = 1.4; spine = 0.0; neck = 0.0
		for k in ["shoulder_l", "shoulder_r"]:
			p[k].x = lerpf(p[k].x, arms, prep)
		p.elbow_l.x = lerpf(p.elbow_l.x, 0.15, prep); p.elbow_r.x = lerpf(p.elbow_r.x, 0.15, prep)
		p.spine.x = lerpf(p.spine.x, spine, prep)
		p.neck.x = lerpf(p.neck.x, neck, prep)
		for k in ["hip_l", "hip_r"]:
			p[k].x = lerpf(p[k].x, 0.05, prep)
		for k in ["knee_l", "knee_r"]:
			p[k].x = lerpf(p[k].x, -0.1, prep)
	# Recepción: piernas preparadas, brazos delante para equilibrar
	if landing_prep and tuck < 0.5:
		var k := 0.85
		p.hip_l.x = lerpf(p.hip_l.x, 0.55, k); p.hip_r.x = lerpf(p.hip_r.x, 0.45, k)
		p.knee_l.x = lerpf(p.knee_l.x, -0.75, k); p.knee_r.x = lerpf(p.knee_r.x, -0.65, k)
		p.hip_l.z = lerpf(p.hip_l.z, -0.08, k); p.hip_r.z = lerpf(p.hip_r.z, 0.08, k)
		p.shoulder_l.x = lerpf(p.shoulder_l.x, 1.1, k); p.shoulder_r.x = lerpf(p.shoulder_r.x, 1.1, k)
		p.shoulder_l.z = lerpf(p.shoulder_l.z, -0.7, k); p.shoulder_r.z = lerpf(p.shoulder_r.z, 0.7, k)
		p.elbow_l.x = lerpf(p.elbow_l.x, 0.4, k); p.elbow_r.x = lerpf(p.elbow_r.x, 0.4, k)
		p.spine.x = lerpf(p.spine.x, -0.2, k)
		p.neck.x = lerpf(p.neck.x, 0.1, k)

func _vault_pose(p: Dictionary) -> Basis:
	var s := player.vault_progress()
	var kind: String = player.vault.get("kind", "Speed Vault")
	var arc := sin(s * PI)
	match kind:
		"Kong Vault":
			_tuck_pose(p, arc)
			p.shoulder_l.x = lerpf(2.8, 0.3, s); p.shoulder_r.x = lerpf(2.8, 0.3, s)
			p.elbow_l.x = 0.2; p.elbow_r.x = 0.2
			return Basis(Vector3.RIGHT, -1.0 * arc)
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
