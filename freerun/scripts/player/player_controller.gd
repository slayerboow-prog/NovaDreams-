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

enum State { GROUND, AIR, VAULT, WALLRUN, WALLCLIMB, HANG, CLIMB_UP, ROLL, CRASH, SWIM, SKILL }
const STATE_NAMES := ["Suelo", "Aire", "Vault", "Wall Run", "Wall Climb", "Colgado", "Subida", "Rodando", "Caída", "Agua", "Habilidad"]

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
var takeoff_pos := Vector3.ZERO        # punto de despegue (distancia del Dive Kong)
var peak_y := 0.0
var prev_velocity := Vector3.ZERO
var land_impact := 0.0                  # para la animación de recepción
var flick_buffer := Vector2.ZERO        # gesto hecho en el suelo justo antes de saltar
var flick_timer := 0.0
var kick_timer := 0.0                   # botón GIRO pulsado justo antes de saltar
var last_landing := {}
var jump_load := 0.0                    # flexión previa al salto (anticipación)
var jump_load_kind := "stand"
var jump_load_total := 0.07             # duración de la flexión en curso (para la animación)
var jump_flip := "jump"                 # despegue propio del mortal pedido (TAKEOFF)
var takeoff_style := ""                 # se aplica en el impulso del salto
var pre_twist := 0.0                    # GIRO ya inclinado durante la flexión: el tirabuzón arranca en el despegue
var pre_twist_dir := 0.0
## Despegue de cada mortal: flexión (s), impulso vertical extra (m/s) y desplazamiento propio
## (m/s, + adelante) que solo se nota con poca velocidad (corriendo manda la carrera).
##   atrás: flexión profunda, brazos abajo-atrás y arriba; sale un poco hacia atrás
##   doble: flexión más profunda y salto más alto (necesita más tiempo de vuelo)
##   adelante: tronco delante, brazos atrás, proyecta hacia delante
##   aerial: zancada y barrido de brazos; avanza · butterfly: carga baja y girada
const TAKEOFF := {
	"jump": {"load": 0.07, "vy": 0.0, "fwd": 0.0},
	"back": {"load": 0.13, "vy": 0.0, "fwd": -0.9},
	"double_back": {"load": 0.17, "vy": 1.1, "fwd": -0.6},
	"front": {"load": 0.12, "vy": -0.2, "fwd": 1.3},
	"double_front": {"load": 0.16, "vy": 0.9, "fwd": 1.2},
	"side": {"load": 0.14, "vy": 0.0, "fwd": 0.0},
	"double_side": {"load": 0.17, "vy": 0.9, "fwd": 0.0},
	"aerial": {"load": 0.16, "vy": -0.4, "fwd": 1.6},
	"butterfly": {"load": 0.13, "vy": -0.3, "fwd": 0.4},
	"cork": {"load": 0.12, "vy": 0.45, "fwd": 0.0},
	"gainer": {"load": 0.14, "vy": 0.2, "fwd": 2.6},          # mortal atrás avanzando: empuje adelante
}
var land_quality := ""                  # último aterrizaje (para la animación de recepción)
var land_timer := 9.0                   # tiempo desde el último aterrizaje
var context_hint := ""                  # texto del botón contextual
var vault_buffer := 0.0                 # botón VAULT pulsado hace poco
var grab_buffer := 0.0                  # botón AGARRAR pulsado hace poco
var ground_pending := 0.22              # espera: joystick derecho en el suelo sin SALTO
var ground_wait := 0.0                  # = movimiento de suelo (rueda, rondada, flic-flac...)
var roundoff_timer := 0.0               # rebote tras una rondada: el siguiente salto sale más alto
var twist_lock := false                 # el joystick derecho hizo un movimiento de suelo: no gira hasta soltarlo
var side_turn := 0.0                    # > 0: girando el cuerpo de lado antes de un sideflip en carrera
var side_target := Vector3.ZERO
var momentum := 0.0                     # carrera acumulada 0..1: el sprint completo se gana corriendo
var flow_boost := 0.0                   # 0..1 lo fija el FlowSystem (algo más de velocidad y recuperación)
var gestures := GestureInterpreter.new() # flick, mantener, arco, cambio de dirección... del joystick derecho
var gesture_event := {}                 # evento de gesto de este frame
var chain := ChainSystem.new()          # ventana de enlace y potencia que deja el último movimiento
var chain_event := {}                   # gesto hecho DURANTE una habilidad: siguiente movimiento en cola
var chain_event_t := 0.0
var skill := {}                         # habilidad de suelo en curso (SkillLibrary)
var skill_serial := 0                   # cambia con cada habilidad (el rig reorienta sin giros raros)
var last_skill := {}                    # datos de la última habilidad (pruebas/HUD)
var double_buffer := 0.0                # botonera: se pidió doble mortal hace poco
var st_queued := false                  # CORK pulsado durante un cork: caer a un pie (ST); lo siguiente lo enlaza el jugador
var chutada_q := false                  # el cork pedido es una chutada (sin tirabuzón)
var chutada_t := 0.0
var cork_buffer := 0.0                  # botón CORK pulsado hace poco (se aplica en el despegue)
var butterfly_buffer := 0.0             # botón MARIPOSA pulsado hace poco
var cork_side := 1
# Modo gestos: patrones del joystick dorado y círculos del joystick morado
var vault_pref := ""                     # "kong": técnica pedida con el patrón de dos arcos
var vault_pref_t := 0.0
var keep_buf := ""                       # "vault" / "grab": el patrón sigue pidiendo esa acción un rato
var keep_t := 0.0                        # (da tiempo a llegar al obstáculo o a la pared)
var air_grab_t := 0.0                    # cat leap / agarre: agarrar en cuanto haya borde o pared en el aire
var palm_t := 0.0                        # palm flip: manos a la pared y mortal atrás enseguida
var wallflip_t := 0.0                    # wall flip: tras empezar a trepar, mortal atrás desde la pared
var wallrun_hold_t := 0.0                # wall run: el salto se mantiene para engancharse a la pared
var precision_t := 0.0                   # salto de precisión: clavar la recepción
var extra_twist_halves := 0              # aerial twist: medias vueltas de tirabuzón añadidas al mortal
var extra_twist_dir := 1
var extra_twist_t := 0.0
var cork_more := 0                       # cork 720: medias vueltas extra del cork
var cork_more_t := 0.0
var pending_twists: Array[int] = []      # círculos dibujados en el suelo: salen en el despegue
var pending_twists_t := 0.0
# Botones de mortal (estilo Madness): 1.ª pulsación carga el salto, 2.ª agrupa y gira, 3.ª abre
var mad_axis := 99                       # sector del mortal elegido (-2 atrás · 2 adelante · 0/4 lateral)
var mad_stage := 0                       # 0 nada · 1 cargando / en el aire sin girar · 2 agrupado · 3 abierto
var mad_charge := 0.0                    # carga extra del salto (s)
var mad_pre_extra := 0                  # pulsaciones de mortal extra antes de despegar (vueltas más)
var mad_twisted := false                # tirabuzón hecho con el cuerpo abierto desde la última agrupación
var one_foot_q := false                  # botón 1 PIE: la próxima recepción es a un pie
var one_foot_side := 1
const MAD_CHARGE_MAX := 0.12
const HOP_VY := 2.6                      # botón de mortal sin SALTO: saltito sin impulso
var twist_wait_t := 0.0                  # ventana para combinar el círculo con un mortal del dorado
const TWIST_WAIT := 0.4

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
	jump_load = 0.0
	mad_stage = 0; mad_axis = 99; mad_charge = 0.0; one_foot_q = false; mad_twisted = false; chutada_q = false; mad_pre_extra = 0
	keep_t = 0.0; air_grab_t = 0.0; wallflip_t = 0.0; wallrun_hold_t = 0.0; precision_t = 0.0
	extra_twist_t = 0.0; cork_more = 0; pending_twists.clear(); vault_pref = ""
	ground_wait = 0.0
	roundoff_timer = 0.0
	momentum = 0.0
	side_turn = 0.0
	skill = {}
	chain.link = {}
	chain_event = {}
	gestures.cancel()
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

## Gravedad en el aire. Durante una acrobacia el atleta "flota" algo más (impulso explosivo
## de piernas y brazos): da tiempo a ver cada fase sin acelerar ni ralentizar el giro.
func _air_gravity_base() -> float:
	if tricks.active and state == State.AIR:
		return t.gravity * t.trick_gravity_mult
	return t.gravity

func time_to_ground() -> float:
	var gy := sensor.ground_below(global_position)
	var h := global_position.y - gy
	if gy == -INF or h > 60.0:
		return 1.2
	var vy := velocity.y
	var g := _air_gravity_base()
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
	# Las caídas grandes se absorben más despacio (recepción a cuatro apoyos)
	# Amortiguación de la recepción: dura ~0,35-0,5 s (las rodillas bajan y suben, no es un golpe seco)
	land_impact = move_toward(land_impact, 0.0, dt * (1.3 if float(last_landing.get("impact", 0.0)) > 9.0 else 1.7))
	land_timer += dt
	jump_buffer = t.jump_buffer_time if intent.jump_pressed else maxf(0.0, jump_buffer - dt)
	roll_buffer = t.roll_window if intent.action_pressed else maxf(0.0, roll_buffer - dt)
	if intent.flick != Vector2.ZERO:
		flick_buffer = intent.flick
		flick_timer = 0.25
	elif jump_load <= 0.0:
		flick_timer = maxf(0.0, flick_timer - dt)    # durante la flexión el gesto pedido se conserva
	kick_timer = 0.25 if intent.kick else maxf(0.0, kick_timer - dt)
	vault_buffer = 0.3 if intent.vault_pressed else maxf(0.0, vault_buffer - dt)
	grab_buffer = 0.3 if intent.grab_pressed else maxf(0.0, grab_buffer - dt)
	chain.tick(dt)
	roundoff_timer = chain.time_left()
	# Gestos del joystick derecho: solo cuentan los que empiezan en el suelo (o durante una
	# habilidad / tumbado). Un giro del aire que sigue inclinado al aterrizar no dispara nada.
	if intent.jump_pressed or intent.vault_pressed:
		gestures.cancel()
	var can_start := (state == State.GROUND and jump_load <= 0.0 and not intent.jump_held) or state == State.SKILL or state == State.CRASH
	gesture_event = gestures.update(intent.rot, dt, can_start)
	chain_event_t = maxf(0.0, chain_event_t - dt)
	if chain_event_t <= 0.0:
		chain_event = {}
	if not gesture_event.is_empty() and state == State.SKILL and gesture_event.type != "release":
		chain_event = gesture_event
		chain_event_t = 0.45
	# Botonera: botón de un movimiento de suelo (como un gesto: en una habilidad queda en cola)
	if intent.skill_request != "":
		var bev := {"type": "skill", "id": intent.skill_request}
		if state == State.SKILL:
			chain_event = bev
			chain_event_t = 0.45
		elif state == State.GROUND or state == State.CRASH:
			gesture_event = bev
	double_buffer = 0.25 if intent.double_flip else maxf(0.0, double_buffer - dt)
	if intent.butterfly_request:
		butterfly_buffer = 0.25
	elif jump_load <= 0.0:
		butterfly_buffer = maxf(0.0, butterfly_buffer - dt)
	if intent.cork_request:
		cork_buffer = 0.25
		cork_side = -1 if intent.move.x > 0.3 else 1     # el tirabuzón gira hacia donde empujas
	elif jump_load <= 0.0:
		cork_buffer = maxf(0.0, cork_buffer - dt)
	_tick_gestures(dt)
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
		State.SKILL: _state_skill(dt)
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
		var running := intent.sprint or mag > 0.93
		if running:
			# El sprint no es instantáneo: se acumula corriendo recto (y en flow se va algo más rápido).
			target_speed = lerpf(t.run_speed + 0.6, t.sprint_speed, momentum) * (1.0 + t.flow_speed_bonus * flow_boost)
		if stun > 0.0:
			target_speed *= 0.35
		var desired := wish.normalized()
		var heading := hv / spd if spd > 0.4 else desired
		var ang := heading.signed_angle_to(desired, Vector3.UP)
		# Arrancar hacia atrás desde parado: primero gira sobre sí mismo, luego acelera.
		var pivot := spd < 1.2 and absf(facing.signed_angle_to(desired, Vector3.UP)) > 1.7
		if running and absf(ang) < 0.6 and stun <= 0.0 and spd > t.run_speed * 0.8:
			momentum = minf(1.0, momentum + dt / t.momentum_build)
		elif absf(ang) > 1.2:
			momentum = maxf(0.0, momentum - dt * 1.6)    # giro cerrado: se pierde la carrera
		elif not running:
			momentum = maxf(0.0, momentum - dt * 0.5)
		var turn_rate := lerpf(t.turn_rate_slow, t.turn_rate_fast, clampf(spd / t.sprint_speed, 0.0, 1.0))
		if absf(ang) > 2.3 and spd > t.run_speed * 0.75:
			spd = move_toward(spd, 0.0, t.skid_decel * dt)    # derrape antes de girar
			if spd < 2.0:
				heading = desired
		else:
			heading = heading.rotated(Vector3.UP, clampf(ang, -turn_rate * dt, turn_rate * dt))
			# Arranque explosivo: acelera mucho al salir y menos cerca de la velocidad máxima.
			var acc := t.overspeed_decel
			if spd < target_speed:
				acc = lerpf(t.accel_start, t.accel, clampf(spd / t.sprint_speed, 0.0, 1.0))
				if pivot:
					acc *= 0.25
			spd = move_toward(spd, target_speed, acc * dt)
		hv = heading * spd
	elif jump_load <= 0.0 and not chain.active():   # flexión del salto o rebote de un enlace: conserva el impulso
		hv = hv.move_toward(Vector3.ZERO, t.decel * dt)
		momentum = maxf(0.0, momentum - dt * 2.5)
	velocity.x = hv.x
	velocity.z = hv.z
	velocity.y = -1.0
	if side_turn > 0.0 and jump_load > 0.0:
		# Sideflip en carrera: antes de despegar el atleta se pone de lado (eje del mortal
		# perpendicular a la carrera) y seguirá avanzando mientras gira, mirando al lado.
		_turn_facing(side_target, absf(facing.signed_angle_to(side_target, Vector3.UP)) / maxf(jump_load, dt), dt)
	elif hv.length() > 0.3 and (mag > 0.08 or not chain.active()):
		# Tras una rondada/flic-flac se sigue deslizando de espaldas: no se gira solo
		_turn_facing(hv, t.facing_turn, dt)
	elif mag > 0.08:
		_turn_facing(wish, t.facing_turn, dt)

	if jump_load > 0.0:
		# Flexión de piernas y brazos atrás antes de despegar (anticipación del salto).
		if jump_flip == "jump" and flick_timer > 0.0 and not chain.active():
			# El gesto llegó durante la flexión: se alarga a la del mortal pedido
			jump_flip = _flip_kind(horizontal_velocity().length())
			var extra: float = TAKEOFF[jump_flip].load - TAKEOFF["jump"].load
			jump_load += extra
			jump_load_total += extra
		jump_load -= dt
		if absf(intent.twist) >= 0.35:
			# El tirabuzón se inicia ya en el despegue (como en la realidad): cuenta el GIRO de la flexión
			pre_twist += dt
			pre_twist_dir = intent.twist
		if jump_load <= 0.0:
			_takeoff(jump_load_kind)
			return
	elif stun <= 0.0:
		# VAULT: supera el obstáculo con la técnica viable (variante = dirección del joystick derecho);
		# si es una pared alta, trepa. AGARRAR junto a una pared: escalada.
		if vault_buffer > 0.0 and (_try_vault() or _try_wall_climb()):
			vault_buffer = 0.0
			ground_wait = 0.0
			return
		if grab_buffer > 0.0 and _try_wall_climb():
			grab_buffer = 0.0
			return
		if not gesture_event.is_empty() and jump_buffer <= 0.0 and vault_buffer <= 0.0 and not _obstacle_ahead():
			if _ground_gesture(gesture_event):
				return
		if jump_buffer > 0.0:
			jump_buffer = 0.0
			if _try_vault():
				return
			if _try_wall_climb():
				return
			if cork_buffer > 0.0 and not chain.active() and t.jump_load_time > 0.0:
				# Cork quieto o con un paso: carga, patada de la pierna de atrás y despegue vertical
				cork_buffer = 0.0
				flick_timer = 0.0
				_start_skill("cork_swing", cork_side)
				return
			var kind := "run" if spd > 3.0 else "stand"
			_prepare_side_turn(spd)
			if side_turn <= 0.0 and not chain.active() and (land_impact > 0.3 or t.jump_load_time <= 0.0):
				# Rebote: las piernas ya vienen flexionadas del aterrizaje → enlace inmediato.
				_takeoff(kind)
				return
			# Cada mortal tiene su propio despegue (flexión, brazos, impulso). En un enlace la
			# recepción ya es la flexión: contacto corto de rebote (0,06 s).
			jump_flip = _flip_kind(spd)
			var load: float = TAKEOFF[jump_flip].load if t.jump_load_time > 0.0 else 0.0
			jump_load = maxf(load if not chain.active() else 0.06, 0.16 if side_turn > 0.0 else 0.0)
			jump_load_total = maxf(jump_load, 0.01)
			jump_load_kind = kind
		if intent.action_pressed and spd > 3.0:
			_start_roll(false)
			return
	move_and_slide()
	if not is_on_floor():
		if jump_load > 0.0:
			_takeoff(jump_load_kind)
			return
		coyote = t.coyote_time
		_enter_air("fall")

## Si el salto lleva un mortal lateral y el atleta corre: alarga un poco la flexión y gira el
## cuerpo de lado (el lado hacia el que gira el mortal mira en la dirección de la carrera).
func _prepare_side_turn(spd: float) -> void:
	side_turn = 0.0
	if flick_timer <= 0.0 or spd < 2.5:
		return
	var sec := TouchControls.sector_of(flick_buffer)
	if sec != 0 and sec != 4:
		return
	var hs := 1.0 if sec == 0 else -1.0
	var v := horizontal_velocity().normalized()
	side_target = Vector3.UP.cross(v) * hs
	side_turn = 1.0

## Modo gestos (dos joysticks): el joystick SALTO elige el mortal por ángulo y nunca añade giros.
func gesture_sticks() -> bool:
	return Settings.trick_controls == 5

func _apply_jump_flick(d: Vector2, allow_twist := true) -> void:
	if gesture_sticks():
		tricks.apply_salto(d)
	else:
		tricks.apply_flick(d, allow_twist)

## Qué mortal sale con este salto (zona/botón pulsado) para elegir su despegue.
func _flip_kind(spd: float) -> String:
	if cork_buffer > 0.0:
		return "cork"
	if mad_stage == 1 and mad_axis != 99:
		match mad_axis:
			2: return "front"
			-2: return "back"
			0, 4: return "side"
	if flick_timer <= 0.0:
		return "jump"
	var dbl := double_buffer > 0.0 or intent.double_flip
	if gesture_sticks():
		match TouchControls.sector_of(flick_buffer):
			2: return "front"
			1: return "front"
			3: return "aerial"
			0, 4: return "side"
			-2: return "back"
			-1, -3: return "gainer"
		return "jump"
	match TouchControls.sector_of(flick_buffer):
		-2, -1, -3: return "double_back" if dbl else "back"
		2, 1: return "double_front" if dbl else "front"
		0, 4: return "double_side" if dbl else "side"
		3: return "aerial"
	return "jump"

func _takeoff(kind: String) -> void:
	jump_load = 0.0
	takeoff_style = jump_flip if jump_flip != "jump" else _flip_kind(speed())
	jump_flip = "jump"
	if side_turn > 0.0:
		facing = side_target          # despega ya de lado
		side_turn = 0.0
	# Destino del salto (para el enlace): mortal atrás/adelante/lateral, butterfly, giro o salto
	var target := "jump"
	if flick_timer > 0.0:
		target = ChainSystem.jump_target(TouchControls.sector_of(flick_buffer), speed())
	elif intent.rot.length() > 0.55 and not intent.stick_twist:
		target = ChainSystem.jump_target(TouchControls.sector_of(intent.rot), speed())
	elif kick_timer > 0.0:
		target = "kick"
	var lp := _link_for(target)
	_do_jump(kind, lp)
	if target == "jump" and not lp.is_empty():
		# Rebote limpio sin acrobacia (punch): "Round-off Rebound", "Back Handspring Rebound"...
		_emit_move(String(lp.name) + " Rebound", 1.0, {"difficulty": 0.4 + 0.3 * float(lp.timing), "chain": true})
	if butterfly_buffer > 0.0:
		# Botón MARIPOSA: el barrido de piernas da la rotación horizontal aunque no haya carrera
		tricks.takeoff_speed = maxf(tricks.takeoff_speed, 4.5)
		tricks.travel_speed = maxf(tricks.travel_speed, 4.5)
		butterfly_buffer = 0.0
	# Gesto hecho justo antes de saltar (o durante la flexión): el mortal arranca en el despegue.
	if flick_timer > 0.0:
		_apply_jump_flick(flick_buffer)
	elif intent.rot.length() > 0.55 and not intent.stick_twist:
		# Joystick derecho ya inclinado al pulsar SALTO: el mortal sale en el despegue
		tricks.apply_flick(TouchControls.sector_dir(TouchControls.sector_of(intent.rot)))
	if kick_timer > 0.0:
		tricks.apply_kick(_kick_dir())
	if double_buffer > 0.0 and flick_timer > 0.0:
		tricks.apply_flick(flick_buffer, false)       # botón DOBLE: otra vuelta pedida desde el despegue
		double_buffer = 0.0
	if cork_buffer > 0.0:
		if chutada_q:
			_make_chutada()
		else:
			_make_cork()
		cork_buffer = 0.0
	if pre_twist > 0.0 and intent.stick_twist:
		tricks.twist_input(pre_twist_dir, pre_twist, t)
	pre_twist = 0.0
	if mad_stage == 1 and tricks.active:
		mad_stage = 2                              # botón de mortal: sale agrupado y girando
		for i in mad_pre_extra:
			tricks.request_flip(true)              # pulsado varias veces antes de despegar: doble...
	mad_pre_extra = 0
	if extra_twist_t > 0.0 and tricks.active:
		tricks.add_twist_halves(extra_twist_halves, extra_twist_dir)      # aerial twist
	extra_twist_t = 0.0
	for ev in pending_twists:
		tricks.add_twist_turn(ev, time_to_ground(), t)                   # círculos dibujados antes de despegar
	pending_twists.clear()
	flick_timer = 0.0
	kick_timer = 0.0

## Cuánto empuja el jugador la rotación (0..1), o -1 si tira en contra para abrirse y frenar.
## AGRUPAR (o el dedo en SALTO) = agrupado total; el joystick derecho es analógico:
## inclinarlo hacia el sentido del giro agrupa poco a poco, soltarlo abre, en contra frena.
func trick_push() -> float:
	var p := 1.0 if intent.tuck else 0.0
	if gesture_sticks() and tricks.active and absf(intent.twist) >= 0.35 and not twist_lock:
		# Tirabuzón con el joystick GIRO: el cuerpo se estira (como en la realidad: estirado gana
		# giro sobre el eje largo y el mortal va más lento). Queda abierto hasta que vuelvas a
		# pulsar un botón de mortal, que lo agrupa otra vez.
		if mad_stage == 2:
			mad_stage = 3
		mad_twisted = true
		return -0.25
	if mad_stage == 2:
		return 1.0                # botón: agrupado y girando hasta la 3.ª pulsación
	if mad_stage == 3:
		return -0.6               # botón: abierto, frena y prepara el aterrizaje
	if intent.stick_twist:
		return p                  # rueda de SALTO mantenida = agrupado; el joystick derecho es el GIRO
	var r := intent.rot
	if not tricks.active or r.length() < 0.25:
		return p
	var along := 0.0
	match tricks.primary_axis():
		"pitch": along = -r.y * tricks.dir.pitch
		"roll": along = r.x * tricks.dir.roll
		"spin": along = r.length()
		"twist": along = absf(r.x)
	if along > 0.3:
		p = maxf(p, clampf((along - 0.3) / 0.55, 0.0, 1.0))
	elif along < -0.45 and p < 0.5:
		p = -1.0
	return p

## Sentido del giro: hacia donde empuja el joystick (por defecto, a la izquierda).
func _kick_dir() -> int:
	return -1 if intent.move.x > 0.3 else 1

func _do_jump(kind: String, link := {}) -> void:
	var spd := speed()
	velocity.y = t.jump_velocity + spd * t.jump_speed_bonus
	if flow_boost > 0.0:
		velocity.x *= 1.0 + 0.04 * flow_boost     # en flow el salto llega un poco más lejos
		velocity.z *= 1.0 + 0.04 * flow_boost
	# Enlace: el rebote de la recepción anterior (rondada, flic-flac...) se suma al impulso de
	# piernas. No es un multiplicador: sale de la velocidad de recepción y de la técnica.
	velocity.y += float(link.get("rebound_vy", 0.0))
	if mad_charge > 0.0:
		velocity.y += mad_charge / MAD_CHARGE_MAX * 1.2   # botón mantenido en la carga: más alto
		mad_charge = 0.0
	# Despegue propio del mortal: más alto para los dobles, hacia atrás/adelante según la técnica
	if TAKEOFF.has(takeoff_style):
		var tk: Dictionary = TAKEOFF[takeoff_style]
		velocity.y += float(tk.vy)
		var slow := 1.0 - clampf(spd / 5.0, 0.0, 1.0)
		# Mortal en el sitio: sin joystick el empuje de la técnica casi no desplaza (para caer donde
		# se despega o encima del mismo muro); con el joystick, desplaza. Gainer y aerial siempre avanzan.
		var aim := 1.0 if takeoff_style in ["gainer", "aerial", "butterfly"] else lerpf(0.15, 1.0, clampf(intent.move.length() / 0.6, 0.0, 1.0))
		velocity.x += facing.x * float(tk.fwd) * slow * aim
		velocity.z += facing.z * float(tk.fwd) * slow * aim
	takeoff_style = ""
	_enter_air(kind)
	if not link.is_empty():
		_apply_link_to_air(link)
	move_and_slide()

## Lo que hereda una acrobacia del movimiento anterior: el giro de un hook/raiz/scoot precarga
## el tirabuzón; el barrido de pierna (aerial, td raiz) da la rotación horizontal que
## convierte el salto en butterfly o en gainer aunque no haya carrera.
func _apply_link_to_air(link: Dictionary) -> void:
	tricks.takeoff_detail = String(link.from)
	tricks.linked = true
	var timing := float(link.get("timing", 1.0))
	match String(link.get("kind", "")):
		"giro":
			tricks.twist_boost = 1.0 + 0.3 * float(link.get("spin", 1.0)) * timing
			tricks.takeoff_speed = maxf(tricks.takeoff_speed, 4.5)
			tricks.travel_speed = maxf(tricks.travel_speed, 4.5)
		"barrido":
			tricks.takeoff_speed = maxf(tricks.takeoff_speed, 4.5)
			tricks.travel_speed = maxf(tricks.travel_speed, 4.5)
	if link.get("strong", false):
		# Entrada de potencia: más altura y el tirabuzón sale con mucha más inercia
		tricks.twist_boost = maxf(tricks.twist_boost, 1.35)
		velocity.y += 0.9
		tricks.takeoff_speed = maxf(tricks.takeoff_speed, 5.0)

## Consume el enlace abierto para `target` (habilidad o salto). {} si no hay o no es coherente.
func _link_for(target: String) -> Dictionary:
	if not chain.active():
		return {}
	var from := chain.from_id()
	if target == "jump":
		var table: Dictionary = ChainSystem.CHAINS.get(from, {})
		for k in table.keys():
			if table[k] == "rebote":
				var lp := chain.consume(k)
				lp.to = "jump"
				return lp
		chain.link = {}
		return {}
	return chain.consume(target)

func _enter_air(kind: String) -> void:
	air_kind = kind
	takeoff_y = global_position.y
	takeoff_pos = global_position
	peak_y = takeoff_y
	# Velocidad de despegue hacia donde mira (gainer = mortal atrás avanzando) y total
	tricks.reset(kind if kind != "fall" else "run", horizontal_velocity().dot(facing))
	tricks.travel_speed = speed()
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
		# Control en el aire también durante los mortales: el joystick lleva el cuerpo hacia donde
		# apuntas (adelante, atrás o a un lado) para caer con precisión encima de otro muro
		var max_s := maxf(hv.length(), t.run_speed)
		var acc := t.air_accel * (1.35 if tricks.active else 1.0)
		hv += wish * acc * dt
		hv = hv.limit_length(max_s)
	velocity.x = hv.x
	velocity.z = hv.z
	var g := _air_gravity_base()
	if velocity.y > 0.0 and not intent.jump_held and intent.rot.length() < 0.3 and not tricks.active and air_kind in ["run", "stand"]:
		g *= t.low_jump_mult
	velocity.y = maxf(velocity.y - g * dt, -t.max_fall)
	peak_y = maxf(peak_y, global_position.y)

	if intent.cork_request:
		# Botón CORK en el aire: durante un cork = ST (caer a un pie, sin enlazar nada solo); si no hay
		# mortal (cayendo de una altura, desde el borde) empieza el cork justo en ese punto; durante
		# un mortal atrás le añade el tirabuzón del cork.
		if tricks.style == "cork":
			st_queued = true
		elif not tricks.active or tricks.style == "back":
			_make_cork()
	elif intent.flick != Vector2.ZERO:
		if intent.butterfly_request and not tricks.active:
			tricks.takeoff_speed = maxf(tricks.takeoff_speed, 4.5)
		_apply_jump_flick(intent.flick, not intent.stick_twist)
		if intent.double_flip:
			tricks.apply_flick(intent.flick, false)            # botón DOBLE en el aire: dos vueltas
		if extra_twist_t > 0.0 and tricks.active:
			tricks.add_twist_halves(extra_twist_halves, extra_twist_dir)   # aerial twist dibujado en el aire
			extra_twist_t = 0.0
	if intent.kick:
		tricks.apply_kick(_kick_dir())
	if twist_lock and absf(intent.twist) < 0.3:
		twist_lock = false
	tricks.twist_input(0.0 if twist_lock else intent.twist, dt, t)
	# Modo gestos: mantener pulsado el botón de mortal = sigue agrupado y girando mientras haya
	# altura; al soltar termina la vuelta en curso (o las pedidas) y se abre para caer
	tricks.keep_spinning = (intent.stick_twist and not gesture_sticks()) or (gesture_sticks() and mad_stage == 2 and intent.flip_held)
	tricks.auto_open = gesture_sticks() and mad_stage == 2
	tricks.layout_twist = gesture_sticks()
	tricks.step(dt, trick_push(), time_to_ground(), Settings.assist_strength(), t)
	if not tricks.active and hv.length() > 1.0:
		_turn_facing(hv, 4.0, dt)

	# Dive Kong: saltando hacia un obstáculo desde lejos, las manos solo llegan si la trayectoria
	# da para ello (distancia y altura). Si te quedas corto o bajo, no hay kong.
	if _try_dive_kong():
		return
	# AGARRAR / VAULT en el aire: agarrar el borde (o subirlo) aunque vengas de un giro,
	# si el cuerpo ya está casi vertical; si no hay borde, agarrarse a la pared.
	if (grab_buffer > 0.0 or vault_buffer > 0.0) and tricks.upright_error() < deg_to_rad(70.0):
		if _try_ledge():
			grab_buffer = 0.0
			vault_buffer = 0.0
			return
		if grab_buffer > 0.0 and _try_wall_climb():
			grab_buffer = 0.0
			return
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
	# Volver a pulsar SALTO en el aire (lejos de paredes): giro 360/540/720 o tirabuzón completo.
	# (Con doble joystick la rueda de SALTO nunca gira: los giros son solo del joystick GIRO.)
	if intent.jump_pressed and jump_buffer > 0.0 and air_kind != "fall" and not intent.stick_twist:
		tricks.apply_kick(_kick_dir())
		jump_buffer = 0.0

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
	mad_stage = 0; mad_twisted = false
	mad_axis = 99
	var prec := precision_t > 0.0
	precision_t = 0.0
	pending_twists.clear()
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
		momentum = 0.0
		landed.emit(result)
		_crash("landing")
		return
	# Los tirabuzones cambian hacia dónde mira el personaje al aterrizar.
	facing = facing.rotated(Vector3.UP, tricks.landing_yaw()).normalized()
	var qmult: float = {"perfect": 1.25, "clean": 1.0, "sloppy": 0.5}[quality]
	land_quality = "hard" if hard else quality
	land_timer = 0.0
	if not trick.is_empty():
		_emit_move(trick.name, qmult, trick)
	# Acrobacias preparatorias (aerial, patadas giratorias, butterfly): dejan una ventana de enlace
	if not trick.is_empty() and quality != "sloppy" and tricks.style in ["aerial", "kick", "butterfly"]:
		var hvl := horizontal_velocity()
		chain.open(tricks.style, String(trick.name), 0.42, {"rebound_vy": 0.5, "exit_speed": hvl.length(),
			"dir": hvl.normalized() if hvl.length() > 0.3 else facing, "spin": 1.0})
	var do_st := st_queued and quality in ["perfect", "clean"] and not hard and not trick.is_empty() and String(trick.name).contains("Cork")
	st_queued = false
	var do_one := one_foot_q and quality in ["perfect", "clean", "sloppy"] and not hard and not rolled and not do_st
	one_foot_q = false
	tricks.reset()
	land_impact = clampf(impact / 12.0, 0.3, 1.0)
	landed.emit(result)
	if do_st:
		# ST: cae a un pie tras el cork. El siguiente movimiento (otro cork, un mortal...) lo
		# enlaza el jugador en la ventana de la recepción: cada botón hace un único movimiento.
		_emit_move("ST", 1.0, {"difficulty": 0.8, "chain": true})
		_set_state(State.GROUND)
		one_foot_side = cork_side
		_start_skill("one_foot", cork_side)
		return
	if do_one:
		# Botón 1 PIE: cae sobre una pierna (alternando) y enlaza lo siguiente sin apoyar la otra
		_set_state(State.GROUND)
		one_foot_side = -one_foot_side
		_start_skill("one_foot", one_foot_side)
		return
	var hv := horizontal_velocity()
	if rolled and (impact > 7.0 or hv.length() > 3.0):
		if impact > t.hard_impact * 0.8:
			_emit_move("Safety Roll", 1.0, {"impact": impact})
		_set_state(State.GROUND)
		_start_roll(true)
		return
	_set_state(State.GROUND)
	if hard:
		stun = (t.stun_time + 0.25) * (1.0 - 0.3 * flow_boost)
		momentum *= 0.2
		velocity.x *= 0.3
		velocity.z *= 0.3
		_emit_move("Hard Landing", 0.0, {"penalty": true})
	elif quality == "sloppy":
		# Recepción torcida: tropieza, pierde velocidad y tarda en recuperar el control.
		stun = t.stun_time * (1.0 - 0.3 * flow_boost)
		momentum *= 0.5
		velocity.x *= 0.5
		velocity.z *= 0.5
	else:
		# Recepción buena: absorbe con las piernas. Perfecta: conserva (y premia) el impulso.
		var keep := 1.04 if quality == "perfect" else 0.9
		var hv2 := horizontal_velocity() * keep
		if hv2.length() > t.sprint_speed * 1.1:
			hv2 = hv2.normalized() * t.sprint_speed * 1.1
		velocity.x = hv2.x
		velocity.z = hv2.z
		if impact > 11.0:
			_emit_move("Drop Landing", qmult, {"impact": impact})
		var narrow := sensor.is_narrow_footing(global_position, facing)
		if air_kind in ["run", "stand", "wall", "ledge", "vault"] and tricks.air_time >= 0.0 and narrow:
			_emit_move("Precision Jump", qmult, {})
		elif prec and air_kind in ["run", "stand"] and not trick.size():
			_emit_move("Precision Jump", qmult, {})
		if prec:
			velocity.x *= 0.12                # salto de precisión: clava la recepción, sin pasos
			velocity.z *= 0.12

# ---------------------------------------------------------------- modo gestos

## Temporizadores de los patrones y lo dibujado este frame en los joysticks dorado y morado.
func _tick_gestures(dt: float) -> void:
	vault_pref_t = maxf(0.0, vault_pref_t - dt)
	if vault_pref_t <= 0.0:
		vault_pref = ""
	keep_t = maxf(0.0, keep_t - dt)
	if keep_t > 0.0:
		if keep_buf == "vault":
			vault_buffer = maxf(vault_buffer, 0.05)
		elif keep_buf == "grab":
			grab_buffer = maxf(grab_buffer, 0.05)
	air_grab_t = maxf(0.0, air_grab_t - dt)
	if air_grab_t > 0.0 and state == State.AIR:
		grab_buffer = maxf(grab_buffer, 0.05)
	palm_t = maxf(0.0, palm_t - dt)
	if palm_t > 0.0 and state == State.WALLCLIMB and state_time > 0.06:
		intent.flick = Vector2(0, -1)          # palm flip: empuje de manos y mortal atrás
	wallflip_t = maxf(0.0, wallflip_t - dt)
	if wallflip_t > 0.0 and state == State.WALLCLIMB and state_time > 0.1:
		intent.flick = Vector2(0, -1)          # wall flip: mortal atrás impulsándose en la pared
		wallflip_t = 0.0
	wallrun_hold_t = maxf(0.0, wallrun_hold_t - dt)
	if wallrun_hold_t > 0.0:
		intent.jump_held = true
	precision_t = maxf(0.0, precision_t - dt * (0.0 if state == State.AIR else 1.0))
	if jump_load <= 0.0:
		extra_twist_t = maxf(0.0, extra_twist_t - dt)
		pending_twists_t = maxf(0.0, pending_twists_t - dt)
		if pending_twists_t <= 0.0 and twist_wait_t <= 0.0:
			pending_twists.clear()
	cork_more_t = maxf(0.0, cork_more_t - dt)
	chutada_t = maxf(0.0, chutada_t - dt)
	if chutada_t <= 0.0 and state != State.SKILL:
		chutada_q = false
	if cork_more_t <= 0.0:
		cork_more = 0
	if not intent.pattern.is_empty():
		_apply_pattern(intent.pattern)
	if not intent.giro.is_empty():
		_apply_giro(intent.giro)
	_tick_flip_buttons(dt)
	if intent.one_foot:
		# 1 PIE en cualquier momento (también antes de saltar): la próxima recepción es a un pie
		one_foot_q = true
	if twist_wait_t > 0.0:
		twist_wait_t -= dt
		if twist_wait_t <= 0.0 and state == State.GROUND and not pending_twists.is_empty() and jump_load <= 0.0 and jump_buffer <= 0.0:
			jump_buffer = t.jump_buffer_time         # nadie pidió mortal: salto con giro de 360
	if not pending_twists.is_empty() and intent.flick != Vector2.ZERO and TouchControls.sector_of(intent.flick) == 2:
		flick_buffer = Vector2(-0.71, 0.71)          # círculo + SALTO ↑ = aerial twist
	if intent.giro_sector != 99:
		# Joystick morado en línea recta: rondada, flic-flac o rueda (en una habilidad, en cola)
		var gev := {"type": "flick", "sector": intent.giro_sector}
		if state == State.SKILL:
			chain_event = gev
			chain_event_t = 0.45
		elif state == State.GROUND or state == State.CRASH:
			gesture_event = gev
	for ev in intent.twist_loops:
		# Cada círculo del joystick morado = una vuelta de tirabuzón (si da tiempo en el aire)
		match state:
			State.AIR:
				tricks.add_twist_turn(ev, time_to_ground(), t)
			State.VAULT:
				var q: Array = vault.get("twists", [])
				q.append(ev)
				vault["twists"] = q
			State.GROUND:
				# Círculo en el suelo: espera un instante por si llega un mortal del dorado
				# (↑ aerial twist · ← → sideflip twist · ↓ piru); si no, salto con giro de 360
				pending_twists.append(ev)
				pending_twists_t = 1.0
				twist_wait_t = TWIST_WAIT

## Botones ATRÁS / ADELANTE / LATERAL (estilo Madness):
##   1.ª pulsación: salta y hace directamente el mortal, agrupado (en el aire, lo empieza ya);
##   agrupado sigue girando (dobles con altura).
##   2.ª: se abre y frena para aterrizar (otra pulsación vuelve a agrupar).
## El impulso (mantener para saltar más alto) es del botón SALTO.
## Con ayuda alta, si no abres, se abre solo cuando ya no cabe otra vuelta.
func _tick_flip_buttons(dt: float) -> void:
	if intent.jump_charge > 0.0 and state in [State.GROUND, State.SKILL, State.ROLL]:
		# SALTO mantenido antes de soltar: impulso, salto algo más alto
		mad_charge = clampf(intent.jump_charge, 0.0, 0.3) / 0.3 * MAD_CHARGE_MAX
	if intent.flip_press == 99:
		return
	var sec := intent.flip_press
	match state:
		State.GROUND, State.SKILL, State.ROLL:
			mad_axis = sec
			flick_buffer = TouchControls.sector_dir(sec)
			flick_timer = 0.25
			if jump_load > 0.0 or state == State.SKILL:
				# SALTO ya pulsado (flexión) o ventana de enlace: el mortal sale con ese despegue.
				# Otra pulsación antes de despegar = una vuelta más (doble)
				if mad_stage == 1:
					mad_pre_extra += 1
				mad_stage = 1
				if state == State.SKILL:
					jump_buffer = t.jump_buffer_time
				return
			# Sin SALTO: no hay impulso de piernas, solo un saltito. Sin altura, lo normal es no
			# completar el giro y no caer de pie (como en la realidad)
			flick_timer = 0.0
			velocity.y = HOP_VY
			_enter_air("stand")
			_apply_jump_flick(flick_buffer)
			mad_stage = 2
		State.AIR, State.VAULT:
			if mad_stage <= 1:
				if mad_axis == 99:
					mad_axis = sec               # cayendo de una altura: empieza el mortal ya
				var d := TouchControls.sector_dir(mad_axis)
				if state == State.VAULT:
					vault.flick = d
				else:
					_apply_jump_flick(d)
				mad_stage = 2
			elif state == State.AIR:
				# Cada pulsación más en el aire = una vuelta más, en cualquier momento del mortal
				# (dos pulsaciones = doble, tres = triple). Sigue agrupado hasta completarlas y
				# entonces se abre para caer. También tras un tirabuzón (front + ½ giro + ATRÁS).
				# Gira lo que haga falta hasta un tope físico: sin altura no se completa.
				mad_stage = 2
				tricks.request_flip(true)
				mad_twisted = false

## Joystick morado en el suelo (GestureRecognizer.recognize_giro): habilidades de suelo y
## entradas de potencia. En una habilidad quedan en cola para el enlace.
const GIRO_SKILLS := {"rondada": "roundoff", "flicflac": "bhs", "rueda": "cartwheel",
	"td_raiz": "td_raiz", "macaco": "macaco", "scoot": "scoot"}
func _apply_giro(g: Dictionary) -> void:
	var id := String(g.get("id", ""))
	var sd := 1 if int(g.get("side", 1)) >= 0 else -1
	if id == "twist":
		var tl: Array[int] = []
		for k in maxi(int(g.get("loops", 1)), 1):
			tl.append(int(g.get("dir", 1)))
		if state == State.GROUND:
			for e in tl:
				pending_twists.append(e)
			pending_twists_t = 1.0
			twist_wait_t = TWIST_WAIT
		elif state == State.AIR:
			for e in tl:
				tricks.add_twist_turn(e, time_to_ground(), t)
		elif state == State.SKILL:
			for e in tl:
				pending_twists.append(e)          # sale en el mortal que se enlace (rueda → piru)
			pending_twists_t = 1.5
		return
	if id == "rondada":
		sd = -1 if intent.move.x < -0.3 else 1
	var skill_id := String(GIRO_SKILLS.get(id, ""))
	var strong := id == "scoot_power"
	if strong:
		skill_id = "scoot"
	if skill_id == "":
		return
	if state == State.SKILL and not strong:
		chain_event = {"type": "skill", "id": "%s:%d" % [skill_id, sd]}
		chain_event_t = 0.45
	elif state in [State.GROUND, State.CRASH] and jump_load <= 0.0:
		gestures.cancel()
		_start_skill(skill_id, sd, -1.0, strong)

## Ejecuta un patrón reconocido en el joystick dorado (GestureRecognizer) con las mismas
## mecánicas que los botones: el jugador solo hace lo que es físicamente posible ahora.
func _apply_pattern(p: Dictionary) -> void:
	var id := String(p.get("id", ""))
	var air := state in [State.AIR, State.VAULT, State.WALLRUN, State.WALLCLIMB, State.HANG]
	match id:
		"webster", "gainer", "aerial", "aerial_twist":
			var d := Vector2(-0.71, 0.71)
			if id == "webster":
				d = Vector2(0.71, 0.71)
			elif id == "gainer":
				d = Vector2(0.71, -0.71)
			flick_buffer = d
			flick_timer = 0.25
			intent.flick = d
			if not air:
				jump_buffer = t.jump_buffer_time
			if id == "aerial_twist":
				extra_twist_halves = 2 * maxi(int(p.get("loops", 1)), 1)
				extra_twist_dir = 1 if int(p.get("twist", 1)) >= 0 else -1
				extra_twist_t = 0.6
		"chutada":
			# Mortal chutado: la patada de la pierna de atrás (lado del trazo) y después un backflip
			# normal, sin tirabuzón. GIRO durante el mortal lo convierte en cork.
			cork_side = 1 if int(p.get("side", 1)) >= 0 else -1
			cork_buffer = 0.25
			chutada_q = true
			chutada_t = 1.0
			if air:
				_make_chutada()
				cork_buffer = 0.0
			else:
				jump_buffer = t.jump_buffer_time
		"cork", "cork720":
			chutada_q = false
			cork_side = -1 if int(p.get("twist", 1)) > 0 else 1
			cork_buffer = 0.25
			intent.cork_request = true
			cork_more = 2 * maxi(int(p.get("loops", 1)) - 1, 0)
			cork_more_t = 2.5
			if not air:
				jump_buffer = t.jump_buffer_time
		"vault", "kong":
			vault_buffer = 0.3
			vault_pref = id
			vault_pref_t = 1.0
			keep_buf = "vault"
			keep_t = 0.9
		"wall_run":
			if not air:
				jump_buffer = t.jump_buffer_time
			wallrun_hold_t = 1.0
		"wall_flip":
			grab_buffer = 0.3
			keep_buf = "grab"
			keep_t = 0.9
			wallflip_t = 1.4
		"palm":
			grab_buffer = 0.3
			keep_buf = "grab"
			keep_t = 0.9
			palm_t = 1.4
		"speed", "reverse":
			vault_buffer = 0.3
			vault_pref = id
			vault_pref_t = 1.0
			keep_buf = "vault"
			keep_t = 0.9
		"climb", "wall_climb":
			grab_buffer = 0.3
			keep_buf = "grab"
			keep_t = 0.9
		"cat_leap":
			if not air:
				jump_buffer = t.jump_buffer_time
			air_grab_t = 1.2
		"ledge_grab":
			grab_buffer = 0.3
			keep_buf = "grab"
			keep_t = 0.7
			air_grab_t = 0.7
		"precision":
			if not air:
				jump_buffer = t.jump_buffer_time
			precision_t = 2.0
		"roll":
			roll_buffer = t.roll_window
			intent.action_pressed = true

## Qué permite el entorno ahora mismo (para validar los patrones de parkour antes de aceptarlos).
func gesture_context() -> Dictionary:
	var air := state in [State.AIR, State.WALLRUN, State.WALLCLIMB, State.HANG, State.VAULT]
	var hv := horizontal_velocity()
	var spd := hv.length()
	var dir := hv / spd if spd > 1.0 else facing
	var pos := global_position
	var obstacle := not sensor.probe_vault(pos, dir, maxf(spd, 6.0), t.vault_max_height, t.vault_min_height).is_empty()
	var wf := not sensor.probe_front_wall(pos, dir, 2.6, 1.0).is_empty() and not sensor.probe_front_wall(pos, dir, 2.6, 1.9).is_empty()
	var near := wf
	for sd in [1.0, -1.0]:
		if not sensor.probe_side_wall(pos, dir, sd, 1.6).is_empty():
			near = true
		if not sensor.probe_front_wall(pos, dir.rotated(Vector3.UP, sd * 0.7), 2.4, 1.0).is_empty():
			near = true
	return {"air": air, "obstacle": obstacle, "wall_front": wf or state in [State.WALLCLIMB, State.WALLRUN, State.HANG],
		"wall_any": near or state == State.WALLRUN, "ledge": air or wf or state == State.HANG, "roll": air or spd > 3.0}

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
	if not info.mount and depth > LONG_TOP:
		# Obstáculo muy largo: no se puede pasar entero por encima, se sube arriba
		info.mount = true
		depth = 0.9
	var kind := "Speed Vault"
	var ideal := Vector2(0.25, 1.3)
	var speed_mult := 1.0
	if info.mount and spd > t.run_speed + 1.2 and h >= 0.55:
		kind = "Kong Up"              # kong a precisión: cae de pie encima del obstáculo largo
		ideal = Vector2(0.5, 1.9)
		speed_mult = 0.8
	elif info.mount:
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
	# Patrón de dos arcos (modo gestos): Kong Vault si el obstáculo tiene fondo y hay carrera
	if vault_pref == "kong" and not info.mount and depth >= 0.5 and spd >= 3.5:
		kind = "Kong Vault"
		ideal = Vector2(0.6, 2.0)
		speed_mult = 1.05
	elif vault_pref == "speed" and not info.mount:
		kind = "Speed Vault"               # pasavallas: de lado con una mano
		ideal = Vector2(0.25, 1.3)
		speed_mult = 1.0
	elif vault_pref == "reverse" and not info.mount:
		kind = "Reverse Vault"             # reverso: entra de espaldas a una mano y media vuelta
		speed_mult = 0.92
	vault_pref = ""
	# Variantes elegidas con un gesto justo antes del vault (SALTO + deslizar o cruceta):
	#   lateral = Reverse Vault (giro de 360 sobre el obstáculo)
	#   arriba en caja de kong = Double Kong · abajo en caja de kong = Kash Vault
	#   ↖ ↗ en obstáculo estrecho = Thief Vault (paso de ladrón: piernas primero, una mano detrás)
	#   ↙ ↘ = Turn Vault (paso con giro: dos manos, media vuelta y cae mirando al obstáculo, frenado)
	var vdir := flick_buffer if flick_timer > 0.0 else (intent.rot if intent.rot.length() > 0.55 else Vector2.ZERO)
	if vdir != Vector2.ZERO and not info.mount:
		var sec := TouchControls.sector_of(vdir)
		if sec in [0, 4]:
			kind = "Reverse Vault"
			speed_mult = 0.92
		elif kind == "Kong Vault" and sec == 2 and depth >= 1.2:
			kind = "Double Kong"
			speed_mult = 1.1
		elif kind == "Kong Vault" and sec == -2:
			kind = "Kash Vault"
			speed_mult = 1.05
		elif sec in [1, 3] and depth < 0.9 and spd > 3.5:
			# Necesita obstáculo estrecho (las piernas pasan por delante de la mano de apoyo) y carrera
			kind = "Thief Vault"
			speed_mult = 0.95
			ideal = Vector2(0.5, 1.6)
		elif sec in [-1, -3] and depth < 1.2:
			kind = "Turn Vault"
			speed_mult = 0.0
			ideal = Vector2(0.1, 1.2)
		if kind in ["Reverse Vault", "Double Kong", "Kash Vault", "Thief Vault", "Turn Vault"]:
			flick_timer = 0.0
	var timing := 1.0
	if d < ideal.x or d > ideal.y:
		timing = 0.6
		speed_mult *= 0.82
	var top_y: float = info.top_y
	var length := d + depth + 0.85
	if info.mount:
		length = d + (0.95 if kind == "Kong Up" else 0.55)
	var exit_speed := maxf(spd * speed_mult, 3.5)
	var duration := clampf(length / maxf(exit_speed, 4.0) * (1.25 if info.mount else 1.0), 0.28, 0.8)
	if kind == "Turn Vault":
		# Apoyo en dos manos y media vuelta: más lento, el cuerpo queda pegado al obstáculo
		length = d + depth + 0.45
		exit_speed = 0.2
		duration = clampf(length / maxf(spd, 3.0) * 1.6, 0.5, 0.8)
	var y0 := global_position.y
	var y1 := top_y + 0.02 if info.mount else maxf(top_y - 0.35, info.land_y + 0.02)
	var peak := top_y + (0.0 if kind in ["Step Vault", "Step Up", "Climb Up"] else (0.3 if kind == "Double Kong" else 0.14))
	if kind == "Thief Vault":
		peak = top_y + 0.08          # trayectoria baja y rasante
	elif kind == "Turn Vault":
		peak = top_y + 0.32          # cadera alta sobre las manos para girar
	if info.mount:
		peak = top_y + (0.25 if kind == "Kong Up" else 0.12)
	var ctrl := 2.0 * peak - 0.5 * (y0 + y1)
	if not info.mount and kind not in ["Step Vault", "Turn Vault"]:
		ctrl = _clear_ctrl(ctrl, y0, y1, top_y, d, depth, length)
	vault = {"kind": kind, "p0": global_position, "dir": dir, "length": length, "duration": duration,
		"y0": y0, "y1": y1, "ctrl": ctrl, "exit_speed": exit_speed,
		"mount": info.mount, "jump_queued": false, "flick": Vector2.ZERO, "top_y": top_y,
		"front": d, "depth": depth}
	facing = dir
	tricks.reset("vault", spd)
	_set_state(State.VAULT)
	_emit_move(kind, timing, {"timing": timing, "height": h})
	return true

## DIVE KONG: en el aire (salto con carrera, sin acrobacia), si el obstáculo queda al alcance de
## los brazos (delante y con la parte de arriba entre los pies y la cabeza), se apoya en él en
## plancha y pasa por encima. La distancia se mide desde el despegue hasta el muro: cuanto más
## lejos, más puntos y récord personal. Si no llegas (caes antes o llegas demasiado bajo) no hay kong.
const DIVE_REACH := 0.85            # alcance horizontal de los brazos estirados (m)
const DIVE_MAX_ABOVE := 1.45        # la parte de arriba como mucho a la altura de las manos estiradas
const DIVE_MIN_ABOVE := -0.7        # pasando por encima: las manos aún llegan abajo hasta ~0,7 m

func _try_dive_kong() -> bool:
	if state != State.AIR or tricks.has_rotation() or air_kind not in ["run", "stand"]:
		return false
	var hv := horizontal_velocity()
	var spd := hv.length()
	if spd < t.vault_min_speed:
		return false
	var dir := hv / spd
	var pos := global_position
	# Parte de arriba del obstáculo justo delante (mirando hacia abajo y adelante): sirve tanto
	# subiendo (pies por debajo del borde) como bajando o pasando por encima (manos hacia abajo)
	var top_y := -INF
	for k in [0.35, 0.65, 0.95, 1.25]:
		var c: Vector3 = pos + dir * float(k)
		var hit := sensor.ray(c + Vector3.UP * (DIVE_MAX_ABOVE + 0.1), c - Vector3.UP * (DIVE_MIN_ABOVE * -1.0 + 0.1))
		if not hit.is_empty() and (hit.normal as Vector3).y > 0.7 and float(hit.position.y) > takeoff_y + 0.4:
			top_y = float(hit.position.y)
			break
	if top_y == -INF:
		return false
	var above := top_y - pos.y
	if above > DIVE_MAX_ABOVE or above < DIVE_MIN_ABOVE:
		return false              # demasiado bajo (no llegan las manos) o pasa muy por encima
	# Cara del obstáculo, profundidad y caída al otro lado (con unos "pies" virtuales bajo el borde)
	var info := sensor.probe_vault(Vector3(pos.x, top_y - 0.6, pos.z), dir, 3.0, 1.0, 0.3)
	if info.is_empty():
		return false
	var d: float = info.dist
	if d > DIVE_REACH:
		return false
	var mount: bool = info.mount
	var depth: float = info.depth
	if not mount and depth > LONG_TOP:
		mount = true                 # obstáculo muy largo: kong y de pie encima
		depth = 0.9
	var dist := Vector3(global_position.x - takeoff_pos.x, 0.0, global_position.z - takeoff_pos.z).length() + d
	if dist < 0.9:
		return false
	var kind := "Kong Up" if mount else "Dive Kong"
	# Técnica: manos a la altura buena (ni rozando con los pies ni con los brazos al límite)
	var timing := 1.0 if above > 0.25 and above < 1.15 else 0.7
	var length := d + (0.95 if mount else depth + 0.85)
	var exit_speed := maxf(spd * 1.04, 4.0)
	var duration := clampf(length / maxf(exit_speed, 4.0) * (1.15 if mount else 1.0), 0.3, 0.75)
	var y0 := global_position.y
	var y1: float = top_y + 0.02 if mount else maxf(top_y - 0.35, float(info.land_y) + 0.02)
	# La trayectoria sigue el vuelo que traía (misma velocidad vertical al apoyar las manos) y
	# la cadera pasa por encima del borde
	var ctrl := maxf(y0 + velocity.y * duration * 0.5, 2.0 * (top_y + 0.15 - 0.25 * (y0 + y1)))
	if not mount:
		ctrl = _clear_ctrl(ctrl, y0, y1, top_y, d, depth, length)
	vault = {"kind": kind, "p0": global_position, "dir": dir, "length": length, "duration": duration,
		"y0": y0, "y1": y1, "ctrl": ctrl, "exit_speed": exit_speed,
		"mount": mount, "jump_queued": false, "flick": Vector2.ZERO, "top_y": top_y,
		"front": d, "depth": depth, "distance": dist}
	facing = dir
	tricks.reset("vault", spd)
	_set_state(State.VAULT)
	last_dive_kong = dist
	_emit_move(kind, timing, {"timing": timing, "height": above, "distance": dist, "dive": true,
		"difficulty": 0.4 + 0.25 * dist})
	return true

var last_dive_kong := 0.0

## Obstáculo más largo que esto (m): no se pasa entero por encima, el vault termina arriba.
const LONG_TOP := 2.2

## Trayectoria de un vault que PASA el obstáculo: los pies quedan por encima de la parte de
## arriba desde que la cadera pasa el borde de delante hasta que superan el borde de atrás
## (no "aterriza" encima). Devuelve el punto de control de la curva que lo cumple.
func _clear_ctrl(ctrl: float, y0: float, y1: float, top_y: float, front: float, depth: float, length: float) -> float:
	for pt in [[front + 0.3, top_y - 0.05], [front + depth + 0.25, top_y + 0.06]]:
		var se := clampf(float(pt[0]) / maxf(length, 0.01), 0.05, 0.95)
		var need := (float(pt[1]) - (1.0 - se) * (1.0 - se) * y0 - se * se * y1) / (2.0 * se * (1.0 - se))
		ctrl = maxf(ctrl, need)
	return ctrl

## Hay un obstáculo saltable justo delante: el joystick derecho elige la variante del vault
## en vez de hacer un movimiento de suelo.
func _obstacle_ahead() -> bool:
	var hv := horizontal_velocity()
	var spd := hv.length()
	if spd < t.vault_min_speed:
		return false
	return not sensor.probe_vault(global_position, hv / spd, spd, t.vault_max_height, t.vault_min_height).is_empty()

## Tricking de suelo con el joystick derecho (sin SALTO). El intérprete de gestos decide:
##   FLICK (inclinar y soltar)   ← → rueda · ↙ ↘ rondada · ↓ flic-flac · ↑ paloma
##                                ↗ patada 360 / tornado · ↖ aerial (parado) / butterfly (carrera)
##   MANTENER (0,5 s)             ↑ pino (soltar o SALTO = snap down)
##                                ← → raiz · ↖ ↗ touchdown raiz · ↙ ↘ macaco
##   ARCO por abajo               hook kick (gira hacia el sentido del arco)
##   CAMBIO DE DIRECCIÓN          scoot hacia el lado final
## Cada habilidad tiene fases, apoyos y potencia propios (SkillLibrary) y transfiere su
## impulso al siguiente movimiento si se enlaza en la recepción (ChainSystem).
func _ground_gesture(ev: Dictionary) -> bool:
	match String(ev.type):
		"skill":
			# Botón de la botonera. Lado (rueda, rondada, macaco): hacia donde empuja el joystick izquierdo
			var side := -1 if intent.move.x < -0.3 else 1
			var id := String(ev.id)
			if id.contains(":"):
				side = int(id.get_slice(":", 1))      # dirección dibujada en SALTO (izquierda/derecha)
				id = id.get_slice(":", 0)
			_start_skill(id, side)
			return true
		"flick", "double":
			if Settings.trick_controls >= 4:
				return _giro_flick(int(ev.sector))
			return _ground_flick(int(ev.sector))
		"hold":
			if gesture_sticks():
				return false        # modo gestos: esas habilidades están en las páginas de SALTO
			var sec := int(ev.sector)
			match sec:
				2: _start_skill("handstand", 1)
				1, 3: _start_skill("td_raiz", 1 if sec == 1 else -1)
				-1, -3: _start_skill("macaco", 1 if sec == -1 else -1)
				_: return false
			return true
		"arc":
			if Settings.trick_controls >= 4:
				# Botonera, joystick GIRO: semicírculo empezando abajo = scoot; empezando arriba =
				# macaco (el lado sale del sentido del giro del pulgar)
				var from := int(ev.from)
				var sd := 1 if int(ev.dir) > 0 else -1
				if from in [2, 1, 3]:
					_start_skill("macaco", -sd)
					return true
				return false
			return false              # (crescents y hook eliminados)
		"change":
			var to := int(ev.to)
			return false          # (scoot eliminado)
	return false

## Botonera, joystick GIRO en el suelo: ↑ rondada · ↓ flic-flac · ← → rueda lateral.
## (El lado de la rondada sale del joystick izquierdo.)
func _giro_flick(sec: int) -> bool:
	match sec:
		2, 1, 3:
			_start_skill("roundoff", -1 if intent.move.x < -0.3 else 1)
		-2, -1, -3:
			_start_skill("bhs", 1)
		0, 4:
			_start_skill("cartwheel", 1 if sec == 0 else -1)
		_:
			return false
	return true

func _ground_flick(sec: int) -> bool:
	match sec:
		0, 4:
			_start_skill("cartwheel", 1 if sec == 0 else -1)
		-1, -3:
			_start_skill("roundoff", 1 if sec == -1 else -1)
		-2:
			_start_skill("bhs", 1)
		1:
			# Patada giratoria en el aire (360 / tornado / cheat 360 si viene de una entrada)
			twist_lock = true
			jump_load = 0.0
			var lp := _link_for("kick")
			_do_jump("run" if speed() > 3.0 else "stand", lp)
			tricks.apply_kick(_kick_dir())
		3:
			twist_lock = true
			jump_load = 0.0
			var lp2 := _link_for(ChainSystem.jump_target(3, maxf(speed(), 4.6 if chain.active() else 0.0)))
			_do_jump("run" if speed() > 3.0 else "stand", lp2)
			tricks.apply_flick(Vector2(-0.7, 0.7))
		_:
			return false
	return true

# ---------------------------------------------------------------- habilidades de suelo

## strong: entrada de potencia (scoot fuerte): más recorrido y más rebote para lo que el jugador
## enlace después. Ninguna habilidad encadena otra sola: los combos se hacen movimiento a movimiento.
## Tricking de suelo desactivado mientras se rehacen sus animaciones (vuelven más adelante).
const DISABLED_SKILLS := ["macaco", "td_raiz", "scoot", "spin_entry", "handstand", "pushoff"]

func _start_skill(id: String, side: int, start_s := -1.0, strong := false) -> void:
	if id in DISABLED_SKILLS:
		return
	var d := SkillLibrary.get_def(id)
	twist_lock = true                  # el joystick sigue inclinado: no es un tirabuzón
	jump_load = 0.0
	ground_wait = 0.0
	flick_timer = 0.0
	chain_event = {}
	var lp := _link_for(id)
	var quality := float(lp.get("timing", 1.0)) if not lp.is_empty() else 1.0
	var pw := SkillLibrary.power(id, horizontal_velocity(), facing, side, quality)
	if not lp.is_empty():
		# Enlace coherente: la potencia de la recepción anterior se suma (pasada de tumbling)
		pw.rebound_vy = clampf(float(pw.rebound_vy) + float(lp.get("rebound_vy", 0.0)) * 0.35, 0.0, 3.2)
	if strong:
		pw.travel = float(pw.travel) * 1.3
		pw.exit_speed = float(pw.exit_speed) * 1.3
		pw.rebound_vy = minf(float(pw.rebound_vy) + 1.0, 3.6)
		pw.strong = true
	var s0 := start_s
	if s0 < 0.0:
		s0 = float(d.chain_start) if not lp.is_empty() else 0.0
	skill = {"id": id, "side": side, "s": s0, "dur": float(d.dur) * (0.92 if not lp.is_empty() else 1.0),
		"power": pw, "link": lp, "facing0": facing, "linked": false, "air": 0.0, "hold_t": 0.0, "strong": strong}
	skill_serial += 1
	last_skill = {"id": id, "power": pw, "linked_from": String(lp.get("from", "")), "timing": quality}
	_set_state(State.SKILL)

func skill_sample() -> Dictionary:
	if skill.is_empty():
		return {}
	return SkillLibrary.sample(skill.id, clampf(skill.s, 0.0, 1.0), skill.side)

func _state_skill(dt: float) -> void:
	var d := SkillLibrary.get_def(skill.id)
	var hold: bool = d.get("hold", false)
	skill.s = float(skill.s) + dt / float(skill.dur)
	if hold and skill.s >= 1.0:
		# Pino: se mantiene mientras el joystick siga inclinado. Soltar o SALTO = bajada del pino
		# (snap down: bloqueo de hombros y rebote).
		skill.s = 1.0
		skill.hold_t = float(skill.hold_t) + dt
		if jump_buffer > 0.0:
			jump_buffer = 0.0
			_finish_skill(false)
			_start_skill("pushoff", 1)
			return
		if (intent.rot.length() < 0.3 and not intent.skill_hold) or skill.hold_t > 5.0:
			var held := float(skill.hold_t)
			_finish_skill(false)
			_emit_move("Handstand", 1.0, {"difficulty": float(d.difficulty) + minf(held, 2.0) * 0.2})
			_start_skill("pushoff", 1)
			return
	var smp := skill_sample()
	var pw: Dictionary = skill.power
	var tdir: Vector3 = pw.dir
	if d.has("curve"):
		# Trayectoria curva (pasos en C de la entrada de cork)
		var u := clampf(float(skill.s), 0.0, 1.0)
		tdir = tdir.rotated(Vector3.UP, float(d.curve) * float(skill.side) * u * u * (3.0 - 2.0 * u))
	var hv: Vector3 = tdir * float(pw.travel) * float(smp.vel)
	var sw := float(smp.support)
	if sw > 0.0:
		# Manos apoyadas: el desplazamiento sale de pivotar sobre ellas
		var f0: Vector3 = skill.facing0
		var frame := Basis(Vector3.UP, atan2(-f0.x, -f0.z))
		var vs := frame * SkillLibrary.support_velocity(skill.id, float(skill.s), int(skill.side), float(skill.dur))
		hv = hv.lerp(vs, SkillLibrary._smooth(sw))
	velocity = Vector3(hv.x, -1.0, hv.z)
	move_and_slide()
	if not is_on_floor():
		skill.air = float(skill.air) + dt
		if float(skill.air) > 0.12:
			# El suelo se acaba (borde): sigue como caída con la orientación de un cuerpo de pie
			_finish_skill(false)
			_enter_air("fall")
			return
	else:
		skill.air = 0.0
	# Recepción con los pies: el movimiento cuenta y se abre la ventana de enlace
	if not skill.linked and skill.s >= float(d.link_at):
		skill.linked = true
		var lp: Dictionary = skill.link
		var chained := not lp.is_empty()
		_emit_move(String(d.name), 1.0, {"difficulty": float(d.difficulty) + (0.3 if chained else 0.0),
			"chain": chained, "skill": skill.id, "power": pw})
		var lpw: Dictionary = pw.duplicate()
		lpw.skill_serial = skill_serial
		chain.open(skill.id, String(d.name), float(d.window) * (0.7 + 0.3 * float(d.stability)), lpw)
	if not skill.linked and intent.jump_pressed:
		# SALTO un poco antes de recibir: queda en cola (con su zona de la rueda) para el rebote
		skill.jump_q = true
		skill.jump_flick = intent.flick
		skill.jump_double = intent.double_flip
	if skill.linked:
		if skill.get("jump_q", false):
			skill.jump_q = false
			jump_buffer = 0.1
			if skill.jump_flick != Vector2.ZERO:
				flick_buffer = skill.jump_flick
				flick_timer = 0.25
			if skill.get("jump_double", false):
				double_buffer = 0.25
		# Enlace en la recepción: SALTO (mortal con rebote) o un gesto (siguiente habilidad)
		if jump_buffer > 0.0:
			jump_buffer = 0.0
			_finish_skill(true)
			_set_state(State.GROUND)
			# Contacto corto de rebote: el gesto de la rueda/deslizar que llega ahora aún cuenta
			jump_load = 0.06
			jump_load_kind = "run" if speed() > 3.0 else "stand"
			return
		if not chain_event.is_empty():
			var ev := chain_event
			chain_event = {}
			_finish_skill(true)
			_set_state(State.GROUND)
			if _ground_gesture(ev):
				return
	if skill.s >= 1.0 and not hold:
		if d.get("cork_takeoff", false):
			var side := int(skill.side)
			var via := String(skill.id)
			_finish_skill(true)
			_cork_takeoff(side, via)
			return
		_finish_skill(true)
		_set_state(State.GROUND)

## CHUTADA (mortal chutado): patada como a un balón para despegar y después un backflip
## normal (agrupado, sobre su eje), sin tirabuzón. El GIRO durante el mortal lo convierte en cork (360, 540, 720...).
func _make_chutada() -> void:
	chutada_q = false
	if not tricks.active:
		tricks.apply_flick(Vector2(0, -1))
	tricks.style = "chutada"
	tricks.kick_side = cork_side
	tricks.linked = true

## Convierte el salto/caída actual en un CORK: mortal atrás fuera de eje con tirabuzón de 360 que
## arranca solo (el GIRO en el mismo sentido lo alarga a 540, 720...).
func _make_cork() -> void:
	if not tricks.active:
		tricks.apply_flick(Vector2(0, -1))
	tricks.style = "cork"
	tricks.linked = true
	tricks.twist_boost = 1.2
	if tricks.dir.get("twist", 0) == 0:
		tricks.apply_kick(cork_side)
	_cork_extra()

## Cork 720 dibujado (dos círculos al final del trazo): una vuelta más de tirabuzón.
func _cork_extra() -> void:
	if cork_more > 0:
		tricks.add_twist_halves(cork_more, int(tricks.dir.get("twist", cork_side)))
		cork_more = 0

## Despegue del CORK tras la entrada (tres pasos en C y patada al balón) o tras un ST: la patada
## da la inercia (salto algo más alto y la carrera de la curva) y el tirabuzón de 360 arranca solo;
## el joystick GIRO en el mismo sentido lo alarga (540, 720...).
func _cork_takeoff(side: int, via: String) -> void:
	cork_side = side
	jump_load = 0.0
	# Sin carrera la patada es la fuente principal de elevación: despegue vertical más alto
	velocity.y = t.jump_velocity + (1.0 if via == "cork_swing" else 0.6) + speed() * t.jump_speed_bonus
	_enter_air("run")
	tricks.takeoff_detail = via
	tricks.linked = true
	tricks.twist_boost = 1.25
	tricks.apply_flick(Vector2(0, -1))
	if chutada_q:
		_make_chutada()              # misma patada y despegue, sin tirabuzón
	else:
		tricks.style = "cork"
		tricks.apply_kick(side)
		_cork_extra()
	st_queued = false
	move_and_slide()

## Termina la habilidad: orientación de salida (media vuelta en rondada/raiz) y velocidad.
func _finish_skill(keep_speed: bool) -> void:
	if skill.is_empty():
		return
	var d := SkillLibrary.get_def(skill.id)
	var pw: Dictionary = skill.power
	facing = (skill.facing0 as Vector3).rotated(Vector3.UP, float(d.exit_yaw) * float(skill.side)).normalized()
	if keep_speed:
		var edir: Vector3 = pw.dir
		if d.has("curve"):
			edir = edir.rotated(Vector3.UP, float(d.curve) * float(skill.side))
		var v: Vector3 = edir * float(pw.exit_speed)
		velocity = Vector3(v.x, -1.0, v.z)
	last_skill.exit_speed = float(pw.exit_speed)
	skill = {}
	skill_serial += 1

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
	if intent.cork_request:
		vault.cork = true
	if intent.kick:
		vault.kick = true
	var prev := global_position
	var p := _vault_point(s)
	global_position = p
	velocity = (p - prev) / maxf(dt, 0.001)
	if s >= 1.0:
		var exit: Vector3 = vault.dir * vault.exit_speed
		if vault.kind == "Turn Vault":
			facing = -vault.dir          # termina de cara al obstáculo
			ledge_cooldown = 0.6         # no se vuelve a agarrar al borde que acaba de pasar
		velocity = Vector3(exit.x, 0.0 if vault.mount else -1.0, exit.z)
		if vault.mount:
			_set_state(State.GROUND)
			move_and_slide()
			if not is_on_floor():
				_enter_air("fall")
			return
		_enter_air("vault")
		var cork_q: bool = vault.get("cork", false)
		var kick_q: bool = vault.get("kick", false)
		var twq: Array = vault.get("twists", [])
		if vault.jump_queued or vault.flick != Vector2.ZERO or cork_q or kick_q or not twq.is_empty():
			# Empuje de brazos al salir del obstáculo: vuelo para un mortal antes de caer
			# (Kong → mortal atrás, Speed → lateral, Dive Kong → cork...)
			velocity.y = t.jump_velocity * (1.05 if String(vault.kind).contains("Kong") else 0.95)
			air_kind = "vault"
			tricks.reset("vault", vault.exit_speed)
			tricks.takeoff_detail = vault.kind
			if cork_q:
				_make_cork()
			elif vault.flick != Vector2.ZERO:
				_apply_jump_flick(vault.flick, not intent.stick_twist)
			if kick_q:
				tricks.apply_kick(_kick_dir())
			for ev in twq:
				tricks.add_twist_turn(int(ev), time_to_ground(), t)

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
		tricks.takeoff_detail = "wallrun"
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
	tricks.takeoff_detail = "tictac"
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
	if palm_t <= 0.0:
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
	if intent.flick == Vector2.ZERO and _try_ledge(true):
		return
	if jump_buffer > 0.0 or intent.flick != Vector2.ZERO:
		jump_buffer = 0.0
		var palm := palm_t > 0.0
		velocity = n * (3.4 if palm else 4.6) + Vector3.UP * (6.3 if palm else 7.2)
		var wish := wish_dir()
		if wish.dot(n) > 0.4 and not palm:
			facing = n                     # gira y sale de cara
		_enter_air("wall")
		tricks.takeoff_detail = "palm" if palm else "wallclimb"
		if not palm:
			_emit_move("Wall Kick", 1.0, {})
		palm_t = 0.0
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
	if intent.action_pressed or intent.grab_pressed or (wish.dot(n) > 0.8 and intent.move.length() > 0.95 and state_time > 0.4):
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
	# Kip-up: tumbado, SALTO o joystick derecho ↑ = levantarse de un golpe de riñones
	var kip_gesture := not gesture_event.is_empty() and int(gesture_event.get("sector", 99)) in [1, 2, 3]
	if state_time > 0.3 and is_on_floor() and (jump_buffer > 0.0 or kip_gesture):
		jump_buffer = 0.0
		gestures.cancel()
		velocity = Vector3.ZERO
		_start_skill("kipup", 1)
		return
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
		State.SKILL: context_hint = "ENLAZA" if skill.get("linked", false) else ""
		_: context_hint = ""
