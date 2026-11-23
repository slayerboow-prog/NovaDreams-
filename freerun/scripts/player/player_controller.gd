class_name PlayerController
extends CharacterBody3D
## Núcleo de movimiento único para todas las disciplinas.
##
## Física cinemática propia (CharacterBody3D) con máquina de estados:
## suelo, aire, vault, wall run, wall climb, colgado, subida, rodar, caída y agua.
## El origen del nodo está en los pies. La rotación de acrobacias es solo visual
## (el colisionador siempre está de pie) y la gestiona TrickSystem.

signal move_performed(move_name: String, quality: float, info: Dictionary)
signal landed(result: Dictionary)
signal bailed(reason: String)
signal state_changed(old_state: int, new_state: int)
signal entered_water(result: Dictionary)
signal respawned

enum State { GROUND, AIR, VAULT, WALLRUN, WALLCLIMB, HANG, CLIMB_UP, ROLL, CRASH, SWIM }
const STATE_NAMES := ["Suelo", "Aire", "Vault", "Wall Run", "Wall Climb", "Colgado", "Subida", "Rodando", "Caída", "Agua"]

const CAPSULE_RADIUS := 0.3
const CAPSULE_HEIGHT := 1.8

var t: MoveTuning = MoveTuning.new()
var router: InputRouter
var intent := InputIntent.new()
var camera_yaw := 0.0                    # la cámara lo actualiza: el stick es relativo a cámara
var water_volumes: Array[AABB] = []      # los rellena el nivel

var state: int = State.AIR
var state_time := 0.0
var facing := Vector3.FORWARD
var tricks := TrickSystem.new()
var sensor: ObstacleSensor

var coyote := 0.0
var jump_buffer := 0.0
var roll_buffer := 0.0
var stun := 0.0
var ledge_cooldown := 0.0
var wall_cooldown := 0.0
var last_wall_normal := Vector3.ZERO
var air_kind := "fall"
var takeoff_y := 0.0
var peak_y := 0.0
var prev_velocity := Vector3.ZERO
var land_impact := 0.0                  # para la animación de recepción
var last_landing := {}
var context_hint := ""                  # texto del botón contextual

# Datos de la acción en curso
var vault := {}
var wall := {}
var hang := {}
var climb := {}
var roll_dir := Vector3.FORWARD

var spawn_transform := Transform3D.IDENTITY
var spawn_facing := Vector3.FORWARD

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(48.0)
	floor_constant_speed = true
	wall_min_slide_angle = deg_to_rad(10.0)
	safe_margin = 0.02
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = CAPSULE_RADIUS
	cap.height = CAPSULE_HEIGHT
	shape.shape = cap
	shape.position = Vector3(0, CAPSULE_HEIGHT * 0.5, 0)
	add_child(shape)
	sensor = ObstacleSensor.new(self)
	spawn_transform = global_transform

# ---------------------------------------------------------------- utilidades

func horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)

func speed() -> float:
	return horizontal_velocity().length()

func set_spawn(xform: Transform3D, dir: Vector3) -> void:
	spawn_transform = xform
	spawn_facing = dir.normalized()

func respawn() -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	facing = spawn_facing
	tricks.reset()
	stun = 0.0
	_set_state(State.AIR)
	air_kind = "fall"
	reset_physics_interpolation()
	respawned.emit()

## Dirección deseada en el mundo (relativa a la cámara) con magnitud 0..1.
func wish_dir() -> Vector3:
	var m := intent.move
	if m.length() < 0.08:
		return Vector3.ZERO
	var fwd := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	return (right * m.x + fwd * m.y).limit_length(1.0)

func _set_state(s: int) -> void:
	if s == state:
		return
	var old := state
	state = s
	state_time = 0.0
	state_changed.emit(old, s)

func _turn_facing(dir: Vector3, rate: float, dt: float) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	dir = dir.normalized()
	var ang := facing.signed_angle_to(dir, Vector3.UP)
	var step := clampf(ang, -rate * dt, rate * dt) if rate > 0.0 else ang
	facing = facing.rotated(Vector3.UP, step).normalized()

func _emit_move(name: String, quality := 1.0, info := {}) -> void:
	move_performed.emit(name, quality, info)

func time_to_ground() -> float:
	var gy := sensor.ground_below(global_position)
	var h := global_position.y - gy
	if gy == -INF or h > 60.0:
		return 1.2
	var vy := velocity.y
	var g := t.gravity
	var disc := vy * vy + 2.0 * g * maxf(h, 0.0)
	return (vy + sqrt(disc)) / g

# ---------------------------------------------------------------- bucle

func _physics_process(dt: float) -> void:
	if router:
		intent = router.intent
	state_time += dt
	ledge_cooldown = maxf(0.0, ledge_cooldown - dt)
	wall_cooldown = maxf(0.0, wall_cooldown - dt)
	stun = maxf(0.0, stun - dt)
	land_impact = move_toward(land_impact, 0.0, dt * 3.0)
	jump_buffer = t.jump_buffer_time if intent.jump_pressed else maxf(0.0, jump_buffer - dt)
	roll_buffer = t.roll_window if intent.action_pressed else maxf(0.0, roll_buffer - dt)
	if intent.respawn_pressed:
		respawn()
		return
	prev_velocity = velocity
	match state:
		State.GROUND: _state_ground(dt)
		State.AIR: _state_air(dt)
		State.VAULT: _state_vault(dt)
		State.WALLRUN: _state_wallrun(dt)
		State.WALLCLIMB: _state_wallclimb(dt)
		State.HANG: _state_hang(dt)
		State.CLIMB_UP: _state_climb_up(dt)
		State.ROLL: _state_roll(dt)
		State.CRASH: _state_crash(dt)
		State.SWIM: _state_swim(dt)
	_update_context_hint()
	if global_position.y < t.kill_y:
		bailed.emit("fall")
		respawn()

# ---------------------------------------------------------------- suelo

func _state_ground(dt: float) -> void:
	var wish := wish_dir()
	var mag := wish.length()
	var hv := horizontal_velocity()
	var spd := hv.length()
	if mag > 0.08:
		var target_speed := lerpf(t.walk_speed, t.run_speed, clampf((mag - 0.3) / 0.5, 0.0, 1.0))
		if intent.sprint or mag > 0.93:
			target_speed = t.sprint_speed
		if stun > 0.0:
			target_speed *= 0.35
		var desired := wish.normalized()
		var heading := hv / spd if spd > 0.4 else desired
		var ang := heading.signed_angle_to(desired, Vector3.UP)
		var turn_rate := lerpf(t.turn_rate_slow, t.turn_rate_fast, clampf(spd / t.sprint_speed, 0.0, 1.0))
		if absf(ang) > 2.3 and spd > t.run_speed * 0.75:
			spd = move_toward(spd, 0.0, t.skid_decel * dt)    # derrape antes de girar
			if spd < 2.0:
				heading = desired
		else:
			heading = heading.rotated(Vector3.UP, clampf(ang, -turn_rate * dt, turn_rate * dt))
			var acc := t.accel if spd < target_speed else t.overspeed_decel
			spd = move_toward(spd, target_speed, acc * dt)
		hv = heading * spd
	else:
		hv = hv.move_toward(Vector3.ZERO, t.decel * dt)
	velocity.x = hv.x
	velocity.z = hv.z
	velocity.y = -1.0
	if hv.length() > 0.3:
		_turn_facing(hv, t.facing_turn, dt)
	elif mag > 0.08:
		_turn_facing(wish, t.facing_turn, dt)

	if stun <= 0.0:
		if jump_buffer > 0.0:
			jump_buffer = 0.0
			if _try_vault():
				return
			if _try_wall_climb():
				return
			_do_jump("run" if spd > 3.0 else "stand")
			return
		if intent.flick != Vector2.ZERO:
			_do_jump("run" if spd > 3.0 else "stand")
			tricks.apply_flick(intent.flick)
			return
		if intent.action_pressed and spd > 3.0:
			_start_roll(false)
			return
	move_and_slide()
	if not is_on_floor():
		coyote = t.coyote_time
		_enter_air("fall")

func _do_jump(kind: String) -> void:
	var spd := speed()
	velocity.y = t.jump_velocity + spd * t.jump_speed_bonus
	_enter_air(kind)
	move_and_slide()

func _enter_air(kind: String) -> void:
	air_kind = kind
	takeoff_y = global_position.y
	peak_y = takeoff_y
	tricks.reset(kind if kind != "fall" else "run", speed())
	_set_state(State.AIR)

# ---------------------------------------------------------------- aire

func _state_air(dt: float) -> void:
	coyote = maxf(0.0, coyote - dt)
	if coyote > 0.0 and jump_buffer > 0.0 and air_kind == "fall":
		jump_buffer = 0.0
		_do_jump("run")
		return
	var wish := wish_dir()
	var hv := horizontal_velocity()
	if wish.length() > 0.08:
		var max_s := maxf(hv.length(), t.run_speed)
		hv += wish * t.air_accel * dt
		hv = hv.limit_length(max_s)
	velocity.x = hv.x
	velocity.z = hv.z
	var g := t.gravity
	if velocity.y > 0.0 and not intent.jump_held and not tricks.active and air_kind in ["run", "stand"]:
		g *= t.low_jump_mult
	velocity.y = maxf(velocity.y - g * dt, -t.max_fall)
	peak_y = maxf(peak_y, global_position.y)

	if intent.flick != Vector2.ZERO:
		tricks.apply_flick(intent.flick)
	tricks.step(dt, intent.tuck, time_to_ground(), Settings.assist_strength(), t)
	if not tricks.active and hv.length() > 1.0:
		_turn_facing(hv, 4.0, dt)

	var upright := tricks.upright_error() < deg_to_rad(45.0)
	if upright and not tricks.has_rotation():
		if _try_ledge():
			return
		if jump_buffer > 0.0 and _try_tic_tac():
			return
		if jump_buffer > 0.0 and _try_wall_climb():
			return
		if intent.jump_held and _try_wall_run():
			return

	move_and_slide()
	if _check_water():
		return
	if is_on_floor():
		_land()

func _check_water() -> bool:
	if water_volumes.is_empty():
		return false
	var p := global_position
	for box in water_volumes:
		if box.has_point(p + Vector3.UP * 0.05):
			_enter_water(box)
			return true
	return false

# ---------------------------------------------------------------- aterrizaje

func _land() -> void:
	var impact := -prev_velocity.y
	last_wall_normal = Vector3.ZERO
	var err := rad_to_deg(tricks.upright_error())
	var trick := tricks.evaluate() if tricks.has_rotation() else {}
	var quality := "perfect"
	if err > t.sloppy_angle:
		quality = "crash"
	elif err > t.clean_angle:
		quality = "sloppy"
	elif err > t.perfect_angle:
		quality = "clean"
	var rolled := roll_buffer > 0.0
	var hard := false
	if quality != "crash" and not rolled:
		if impact > t.crash_impact:
			quality = "crash"
		elif impact > t.hard_impact:
			hard = true
	var result := {"quality": quality, "error": err, "impact": impact, "trick": trick,
		"rolled": rolled, "hard": hard, "air_time": tricks.air_time,
		"drop": takeoff_y - global_position.y}
	last_landing = result
	if quality == "crash":
		landed.emit(result)
		_crash("landing")
		return
	# Los tirabuzones cambian hacia dónde mira el personaje al aterrizar.
	facing = facing.rotated(Vector3.UP, tricks.landing_yaw()).normalized()
	var qmult: float = {"perfect": 1.25, "clean": 1.0, "sloppy": 0.5}[quality]
	if not trick.is_empty():
		_emit_move(trick.name, qmult, trick)
	tricks.reset()
	land_impact = clampf(impact / 14.0, 0.15, 1.0)
	landed.emit(result)
	var hv := horizontal_velocity()
	if rolled and (impact > 7.0 or hv.length() > 3.0):
		if impact > t.hard_impact * 0.8:
			_emit_move("Safety Roll", 1.0, {"impact": impact})
		_set_state(State.GROUND)
		_start_roll(true)
		return
	_set_state(State.GROUND)
	if hard:
		stun = t.stun_time + 0.25
		velocity.x *= 0.3
		velocity.z *= 0.3
		_emit_move("Hard Landing", 0.0, {"penalty": true})
	elif quality == "sloppy":
		stun = t.stun_time
		velocity.x *= 0.55
		velocity.z *= 0.55
	else:
		if impact > 11.0:
			_emit_move("Drop Landing", qmult, {"impact": impact})
		if air_kind in ["run", "stand", "wall", "ledge", "vault"] and tricks.air_time >= 0.0 \
				and sensor.is_narrow_footing(global_position, facing):
			_emit_move("Precision Jump", qmult, {})

# ---------------------------------------------------------------- vaults

func _try_vault() -> bool:
	var hv := horizontal_velocity()
	var spd := hv.length()
	if spd < t.vault_min_speed:
		return false
	var dir := hv / spd
	var info := sensor.probe_vault(global_position, dir, spd, t.vault_max_height, t.vault_min_height)
	if info.is_empty():
		return false
	var h: float = info.height
	var d: float = info.dist
	var depth: float = info.depth
	var kind := "Speed Vault"
	var ideal := Vector2(0.25, 1.3)
	var speed_mult := 1.0
	if info.mount:
		kind = "Step Up" if h < 0.75 else "Climb Up"
		ideal = Vector2(0.1, 1.2)
		speed_mult = 0.75
	elif rad_to_deg(info.approach) > 28.0:
		kind = "Lazy Vault"
		speed_mult = 0.9
	elif spd > t.run_speed + 1.2 and depth >= 0.75:
		kind = "Kong Vault"
		ideal = Vector2(0.7, 2.0)
		speed_mult = 1.08
	elif spd > t.run_speed + 1.2 and d > 1.1:
		kind = "Dash Vault"
		ideal = Vector2(1.0, 2.2)
	elif spd < 4.6 or h < 0.55:
		kind = "Step Vault"
		speed_mult = 0.85
		ideal = Vector2(0.15, 1.0)
	var timing := 1.0
	if d < ideal.x or d > ideal.y:
		timing = 0.6
		speed_mult *= 0.82
	var top_y: float = info.top_y
	var length := d + depth + 0.55
	if info.mount:
		length = d + 0.55
	var exit_speed := maxf(spd * speed_mult, 3.5)
	var duration := clampf(length / maxf(exit_speed, 4.0) * (1.25 if info.mount else 1.0), 0.28, 0.8)
	var y0 := global_position.y
	var y1 := top_y + 0.02 if info.mount else maxf(top_y - 0.35, info.land_y + 0.02)
	var peak := top_y + (0.0 if kind in ["Step Vault", "Step Up", "Climb Up"] else 0.14)
	if info.mount:
		peak = top_y + 0.12
	vault = {"kind": kind, "p0": global_position, "dir": dir, "length": length, "duration": duration,
		"y0": y0, "y1": y1, "ctrl": 2.0 * peak - 0.5 * (y0 + y1), "exit_speed": exit_speed,
		"mount": info.mount, "jump_queued": false, "flick": Vector2.ZERO, "top_y": top_y}
	facing = dir
	tricks.reset("vault", spd)
	_set_state(State.VAULT)
	_emit_move(kind, timing, {"timing": timing, "height": h})
	return true

func _vault_point(s: float) -> Vector3:
	var p0: Vector3 = vault.p0
	var horiz: Vector3 = p0 + vault.dir * vault.length * s
	var y: float = (1.0 - s) * (1.0 - s) * vault.y0 + 2.0 * s * (1.0 - s) * vault.ctrl + s * s * vault.y1
	return Vector3(horiz.x, y, horiz.z)

func vault_progress() -> float:
	return clampf(state_time / maxf(vault.get("duration", 1.0), 0.01), 0.0, 1.0) if state == State.VAULT else 0.0

func _state_vault(dt: float) -> void:
	var s := vault_progress()
	if jump_buffer > 0.0 and s > 0.55:
		vault.jump_queued = true
		jump_buffer = 0.0
	if intent.flick != Vector2.ZERO:
		vault.flick = intent.flick
	var prev := global_position
	var p := _vault_point(s)
	global_position = p
	velocity = (p - prev) / maxf(dt, 0.001)
	if s >= 1.0:
		var exit: Vector3 = vault.dir * vault.exit_speed
		velocity = Vector3(exit.x, 0.0 if vault.mount else -1.0, exit.z)
		if vault.mount:
			_set_state(State.GROUND)
			move_and_slide()
			if not is_on_floor():
				_enter_air("fall")
			return
		_enter_air("vault")
		if vault.jump_queued or vault.flick != Vector2.ZERO:
			velocity.y = t.jump_velocity * 0.95
			air_kind = "vault"
			tricks.reset("vault", vault.exit_speed)
			if vault.flick != Vector2.ZERO:
				tricks.apply_flick(vault.flick)

# ---------------------------------------------------------------- paredes

func _try_wall_run() -> bool:
	if wall_cooldown > 0.0:
		return false
	var hv := horizontal_velocity()
	var spd := hv.length()
	if spd < t.wallrun_min_speed:
		return false
	var dir := hv / spd
	for side in [1.0, -1.0]:
		var hit := sensor.probe_side_wall(global_position, dir, side)
		if hit.is_empty():
			continue
		var n: Vector3 = ObstacleSensor.flat(hit.normal).normalized()
		if last_wall_normal.dot(n) > 0.9:
			continue   # misma pared que acabamos de dejar: hay que tocar suelo u otra pared
		if absf(dir.dot(n)) > 0.66:
			continue
		var tangent := (dir - n * dir.dot(n)).normalized()
		wall = {"normal": n, "side": side, "tangent": tangent, "speed": maxf(spd, t.wallrun_min_speed),
			"point": hit.position}
		velocity.y = maxf(velocity.y, t.wallrun_up_boost)
		facing = tangent
		last_wall_normal = n
		tricks.reset("wall", spd)
		_set_state(State.WALLRUN)
		_emit_move("Wall Run", 1.0, {})
		return true
	return false

func _state_wallrun(dt: float) -> void:
	var n: Vector3 = wall.normal
	var hit := sensor.probe_front_wall(global_position, -n, 1.1, 1.0)
	if hit.is_empty() or state_time > t.wallrun_max_time:
		wall_cooldown = 0.3
		_enter_air("wallrun_end")
		tricks.takeoff_kind = "wall"
		return
	n = ObstacleSensor.flat(hit.normal).normalized()
	wall.normal = n
	var tangent: Vector3 = wall.tangent
	tangent = (tangent - n * tangent.dot(n)).normalized()
	wall.tangent = tangent
	wall.speed = move_toward(wall.speed, t.wallrun_min_speed * 0.8, 1.6 * dt)
	var gscale := lerpf(t.wallrun_gravity, 1.1, clampf(state_time / t.wallrun_max_time, 0.0, 1.0))
	velocity.y -= t.gravity * gscale * dt
	var dist: float = hit.distance
	var stick := (dist - (CAPSULE_RADIUS + 0.04)) * 10.0
	var hv: Vector3 = tangent * wall.speed - n * stick
	velocity.x = hv.x
	velocity.z = hv.z
	facing = tangent
	if jump_buffer > 0.0 or intent.flick != Vector2.ZERO:
		jump_buffer = 0.0
		var out: Vector3 = tangent * wall.speed * 0.9 + n * t.walljump_push
		velocity = Vector3(out.x, t.walljump_up, out.z)
		facing = ObstacleSensor.flat(out).normalized()
		wall_cooldown = 0.25
		_enter_air("wall")
		_emit_move("Wall Jump", 1.0, {})
		if intent.flick != Vector2.ZERO:
			tricks.apply_flick(intent.flick)
		return
	if not intent.jump_held and state_time > 0.15:
		wall_cooldown = 0.3
		_enter_air("wallrun_end")
		return
	move_and_slide()
	if is_on_floor():
		_land()

func _try_tic_tac() -> bool:
	var hv := horizontal_velocity()
	var spd := hv.length()
	if spd < 3.0 or wall_cooldown > 0.0:
		return false
	var dir := hv / spd
	var hit := sensor.probe_front_wall(global_position, dir, 1.0, 0.9)
	if hit.is_empty():
		# también se puede patear una pared que está ligeramente de lado
		for side in [1.0, -1.0]:
			var d2 := dir.rotated(Vector3.UP, -side * deg_to_rad(40.0))
			hit = sensor.probe_front_wall(global_position, d2, 0.95, 0.9)
			if not hit.is_empty():
				break
	if hit.is_empty():
		return false
	var n: Vector3 = ObstacleSensor.flat(hit.normal).normalized()
	var ang := rad_to_deg(dir.angle_to(-n))
	if ang < 18.0 or ang > 75.0:
		return false
	var reflected := dir - 2.0 * dir.dot(n) * n
	var tangent := (dir - n * dir.dot(n)).normalized()
	var out := (reflected * 0.45 + tangent * 0.55).normalized()
	velocity = out * spd * 0.95
	velocity.y = t.tictac_up
	facing = out
	jump_buffer = 0.0
	wall_cooldown = 0.2
	last_wall_normal = n
	_enter_air("wall")
	_emit_move("Tic Tac", 1.0, {})
	return true

func _try_wall_climb() -> bool:
	var hv := horizontal_velocity()
	var spd := hv.length()
	var dir := hv / spd if spd > 0.5 else facing
	var hit := sensor.probe_front_wall(global_position, dir, 0.85, 1.0)
	if hit.is_empty():
		return false
	var n: Vector3 = ObstacleSensor.flat(hit.normal).normalized()
	if dir.dot(-n) < 0.72:
		return false
	if spd < 2.0 and state == State.AIR:
		return false
	# Pared demasiado baja = es un obstáculo, no para trepar.
	if sensor.probe_front_wall(global_position, dir, 0.85, 1.9).is_empty():
		return false
	wall = {"normal": n, "speed": spd}
	velocity = Vector3(0.0, t.wallclimb_speed + minf(spd, t.sprint_speed) * 0.2, 0.0)
	facing = -n
	jump_buffer = 0.0
	tricks.reset("wall", 0.0)
	_set_state(State.WALLCLIMB)
	_emit_move("Wall Climb", 1.0, {})
	return true

func _state_wallclimb(dt: float) -> void:
	var n: Vector3 = wall.normal
	velocity.y -= t.gravity * 0.55 * dt
	var hit := sensor.probe_front_wall(global_position, -n, 0.9, 1.0)
	if not hit.is_empty():
		var stick: float = (hit.distance - (CAPSULE_RADIUS + 0.04)) * 10.0
		velocity.x = -n.x * stick
		velocity.z = -n.z * stick
	if _try_ledge(true):
		return
	if jump_buffer > 0.0 or intent.flick != Vector2.ZERO:
		jump_buffer = 0.0
		velocity = n * 4.6 + Vector3.UP * 7.2
		var wish := wish_dir()
		if wish.dot(n) > 0.4:
			facing = n                     # gira y sale de cara
		_enter_air("wall")
		_emit_move("Wall Kick", 1.0, {})
		if intent.flick != Vector2.ZERO:
			tricks.apply_flick(intent.flick)
		return
	if state_time > t.wallclimb_time or hit.is_empty() or velocity.y < -2.0:
		wall_cooldown = 0.25
		_enter_air("fall")
		return
	move_and_slide()

# ---------------------------------------------------------------- bordes

func _try_ledge(from_climb := false) -> bool:
	if ledge_cooldown > 0.0:
		return false
	if velocity.y > 4.5 and not from_climb:
		return false
	var hv := horizontal_velocity()
	var dir := facing
	if hv.length() > 1.0:
		dir = hv.normalized()
	var wish := wish_dir()
	var info := sensor.probe_ledge(global_position, dir)
	if info.is_empty() and wish.length() > 0.3:
		dir = wish.normalized()
		info = sensor.probe_ledge(global_position, dir)
	if info.is_empty():
		return false
	var n: Vector3 = info.normal
	if dir.dot(-n) < 0.5:
		return false
	var rel: float = info.rel
	var into := -n
	if rel <= 1.15 and info.can_stand:
		_start_climb(info, t.mantle_time, "Mantle")
		return true
	if rel > 1.15 and rel <= 2.35:
		var wp: Vector3 = info.wall_point
		hang = {"top_y": info.top_y, "normal": n, "wall_point": wp, "can_stand": info.can_stand}
		var grab_speed := hv.length()
		global_position = Vector3(wp.x, info.top_y - 2.0, wp.z) + n * (CAPSULE_RADIUS + 0.05)
		velocity = Vector3.ZERO
		facing = into
		tricks.reset("ledge", 0.0)
		_set_state(State.HANG)
		_emit_move("Cat Leap" if grab_speed > 3.5 and not from_climb else "Ledge Grab", 1.0, {})
		return true
	return false

func _start_climb(info: Dictionary, duration: float, name: String) -> void:
	var n: Vector3 = info.normal
	var wp: Vector3 = info.wall_point
	var target := Vector3(wp.x, info.top_y + 0.02, wp.z) - n * 0.45
	climb = {"from": global_position, "to": target, "duration": duration, "top_y": info.top_y, "normal": n}
	velocity = Vector3.ZERO
	facing = -n
	_set_state(State.CLIMB_UP)
	_emit_move(name, 1.0, {})

func _state_hang(dt: float) -> void:
	var n: Vector3 = hang.normal
	var tangent := n.cross(Vector3.UP).normalized()
	var wish := wish_dir()
	var lateral := wish.dot(tangent)
	if absf(lateral) > 0.3:
		var test_pos := global_position + tangent * signf(lateral) * 0.45
		var info := sensor.probe_ledge(test_pos, -n)
		if not info.is_empty() and absf(info.top_y - hang.top_y) < 0.35:
			global_position += tangent * lateral * t.shimmy_speed * dt
			hang.can_stand = info.can_stand
			hang.wall_point = info.wall_point
	if intent.flick != Vector2.ZERO or (jump_buffer > 0.0 and wish.dot(n) > 0.45):
		# Salto hacia atrás desde el borde (con mortal si hay gesto).
		jump_buffer = 0.0
		velocity = n * 5.0 + Vector3.UP * 6.8
		ledge_cooldown = 0.45
		_enter_air("ledge")
		tricks.takeoff_kind = "wall"
		_emit_move("Wall Jump", 1.0, {})
		if intent.flick != Vector2.ZERO:
			tricks.apply_flick(intent.flick)
		return
	if jump_buffer > 0.0 and state_time > 0.08:
		jump_buffer = 0.0
		if hang.can_stand:
			_start_climb({"normal": n, "wall_point": hang.wall_point, "top_y": hang.top_y}, t.climb_up_time, "Climb Up")
		else:
			velocity = Vector3.UP * 6.0
			ledge_cooldown = 0.25
			_enter_air("ledge")
		return
	if intent.action_pressed or (wish.dot(n) > 0.8 and intent.move.length() > 0.95 and state_time > 0.4):
		ledge_cooldown = 0.5
		velocity = n * 1.0
		_enter_air("fall")

func _state_climb_up(_dt: float) -> void:
	var dur: float = climb.duration
	var s := clampf(state_time / dur, 0.0, 1.0)
	var from: Vector3 = climb.from
	var to: Vector3 = climb.to
	var rise := clampf(s / 0.62, 0.0, 1.0)
	var fwd := clampf((s - 0.45) / 0.55, 0.0, 1.0)
	var y := lerpf(from.y, to.y, 1.0 - pow(1.0 - rise, 2.0))
	var xz := Vector3(from.x, 0, from.z).lerp(Vector3(to.x, 0, to.z), fwd * fwd * (3.0 - 2.0 * fwd))
	global_position = Vector3(xz.x, y, xz.z)
	velocity = Vector3.ZERO
	if s >= 1.0:
		var n: Vector3 = climb.normal
		velocity = -n * 2.5
		_set_state(State.GROUND)

# ---------------------------------------------------------------- rodar / caída

func _start_roll(from_landing: bool) -> void:
	var hv := horizontal_velocity()
	roll_dir = hv.normalized() if hv.length() > 0.5 else facing
	var spd := maxf(hv.length() * (0.97 if from_landing else 0.92), 3.6)
	velocity = Vector3(roll_dir.x * spd, -1.0, roll_dir.z * spd)
	facing = roll_dir
	roll_buffer = 0.0
	_set_state(State.ROLL)
	if not from_landing:
		_emit_move("Roll", 1.0, {})

func _state_roll(dt: float) -> void:
	var hv := horizontal_velocity()
	var wish := wish_dir()
	if wish.length() > 0.1 and hv.length() > 0.5:
		hv = hv.rotated(Vector3.UP, clampf(hv.signed_angle_to(wish, Vector3.UP), -2.0 * dt, 2.0 * dt))
	hv = hv.move_toward(Vector3.ZERO, 2.0 * dt)
	velocity.x = hv.x
	velocity.z = hv.z
	velocity.y = -1.0
	facing = hv.normalized() if hv.length() > 0.5 else facing
	move_and_slide()
	if not is_on_floor() and state_time > 0.1:
		_enter_air("fall")
		return
	if state_time > t.roll_time:
		_set_state(State.GROUND)
	elif state_time > t.roll_time * 0.6 and jump_buffer > 0.0:
		jump_buffer = 0.0
		_set_state(State.GROUND)
		_do_jump("run")

func roll_progress() -> float:
	return clampf(state_time / t.roll_time, 0.0, 1.0) if state == State.ROLL else 0.0

func _crash(reason: String) -> void:
	tricks.reset()
	stun = 0.0
	_set_state(State.CRASH)
	bailed.emit(reason)

func _state_crash(dt: float) -> void:
	var hv := horizontal_velocity().move_toward(Vector3.ZERO, 12.0 * dt)
	velocity.x = hv.x
	velocity.z = hv.z
	velocity.y = maxf(velocity.y - t.gravity * dt, -t.max_fall)
	move_and_slide()
	if state_time > t.crash_time and is_on_floor():
		velocity = Vector3.ZERO
		_set_state(State.GROUND)
		stun = 0.2

# ---------------------------------------------------------------- agua

func _enter_water(box: AABB) -> void:
	var b := tricks.basis
	var up := b * Vector3.UP
	var vertical_err := minf(up.angle_to(Vector3.UP), up.angle_to(Vector3.DOWN))
	var head_first := up.dot(Vector3.DOWN) > 0.5
	var trick := tricks.evaluate() if tricks.has_rotation() else {}
	var entry_speed := -prev_velocity.y
	var height := peak_y - (box.position.y + box.size.y)
	var err_deg := rad_to_deg(vertical_err)
	var quality := "perfect" if err_deg < 12.0 else ("clean" if err_deg < 25.0 else ("sloppy" if err_deg < 50.0 else "flat"))
	var result := {"quality": quality, "error": err_deg, "head_first": head_first, "trick": trick,
		"entry_speed": entry_speed, "height": height, "air_time": tricks.air_time,
		"surface_y": box.position.y + box.size.y}
	if not trick.is_empty() and quality != "flat":
		var qmult: float = {"perfect": 1.3, "clean": 1.0, "sloppy": 0.55}[quality]
		_emit_move(trick.name, qmult, trick)
	entered_water.emit(result)
	velocity = Vector3(velocity.x * 0.2, maxf(velocity.y * 0.25, -3.0), velocity.z * 0.2)
	_set_state(State.SWIM)
	hang = {"surface": box.position.y + box.size.y}

func _state_swim(dt: float) -> void:
	var surface: float = hang.get("surface", global_position.y)
	var target_y := surface - 1.35
	velocity.y = lerpf(velocity.y, (target_y - global_position.y) * 3.0, 1.0 - exp(-3.0 * dt))
	var wish := wish_dir()
	var hv := horizontal_velocity().lerp(wish * 2.6, 1.0 - exp(-2.5 * dt))
	velocity.x = hv.x
	velocity.z = hv.z
	if hv.length() > 0.3:
		_turn_facing(hv, 4.0, dt)
	tricks.basis = tricks.basis.slerp(Basis(), 1.0 - exp(-6.0 * dt))
	move_and_slide()
	if state_time > 0.7 and jump_buffer > 0.0:
		# Salir del agua si hay borde cerca
		var info := sensor.probe_ledge(global_position, facing)
		if not info.is_empty():
			_start_climb(info, t.climb_up_time, "Climb Up")
			tricks.reset()

# ---------------------------------------------------------------- interfaz

func _update_context_hint() -> void:
	match state:
		State.HANG: context_hint = "SOLTAR"
		State.AIR: context_hint = "RODAR"
		State.GROUND: context_hint = "RODAR" if speed() > 3.0 else ""
		_: context_hint = ""
