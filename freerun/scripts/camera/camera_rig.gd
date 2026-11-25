class_name CameraRig
extends Node3D
## Cámara de tercera persona para parkour.
##
## Principios (por orden de prioridad):
##  1. Precisión: la cámara nunca gira sola en el aire ni durante un truco (las trayectorias se
##     calculan con un encuadre estable); no hay zooms ni giros cinematográficos invasivos.
##  2. Visibilidad: el atleta siempre en pantalla y nunca tapado; la cámara no atraviesa paredes
##     (barrido con esfera desde el pecho del atleta). Si una pared la empuja demasiado cerca, sube
##     por encima en vez de meterse en la cabeza del personaje, y recupera la distancia despacio.
##  3. Fluidez: todo se mueve con muelles críticamente amortiguados (sin tirones ni rebotes):
##     posición, anticipación, distancia, campo de visión y alineado.
##
## Control: arrastrar en una zona libre (o stick derecho / ratón) gira la cámara; doble toque =
## detrás del atleta. Modo híbrido: respeta lo que muevas y después se alinea sola detrás del
## movimiento (solo en el suelo). Ajustes: distancia, altura y modo (híbrida / manual / automática).

var player: PlayerController
var router: InputRouter
var cam: Camera3D

## Ángulos de órbita (los controla el jugador; el alineado automático los mueve despacio)
var yaw := 0.0
var pitch := -0.30
var manual_timer := 10.0
var slowmo := 0.0                 # 0..1 durante la cámara lenta: el encuadre se cierra un poco

## Vista de juego: 0 normal · 1 POV (cámara de acción en la cabeza) · 2 dron
const VIEW_NAMES := ["NORMAL", "POV", "DRON"]
var view := 0
var rig: BodyRig
var alt_cam: Camera3D

# --- Parámetros (ajustados para móvil: suaves pero con respuesta inmediata al control) ---
const BASE_PITCH := -0.30
const PITCH_MIN := -1.05          # mirando hacia abajo (desde arriba)
const PITCH_MAX := 0.16           # mirando hacia arriba: poco (la cámara no baja al suelo)
const GROUND_CLEAR := 0.9         # altura mínima de la cámara sobre los pies del atleta
const BASE_FOV := 64.0
const BASE_LEN := 3.3
const FOCUS_H := 1.35             # altura del punto de mira sobre los pies (pecho/cabeza)
const COLL_RADIUS := 0.24         # radio de la esfera que barre el espacio cámara-atleta
const MIN_DIST := 1.25            # más cerca que esto: la cámara sube en vez de acercarse
const LEAD_TIME := 0.12           # anticipación (segundos de velocidad)
const LEAD_MAX := 0.5
const FOLLOW_HOLD := [1.2, INF, 0.6]   # segundos sin tocar la cámara antes de alinearse (híbrida, manual, automática)

# --- Estado interno (muelles) ---
var _focus := Vector3.ZERO
var _focus_vel := Vector3.ZERO
var _lead := Vector3.ZERO
var _lead_vel := Vector3.ZERO
var _ref_y := 0.0
var _ref_y_vel := 0.0
var _len := BASE_LEN
var _len_vel := 0.0
var _dist := BASE_LEN             # distancia real (tras colisiones)
var _dist_vel := 0.0
var _raise := 0.0                 # inclinación extra hacia abajo cuando una pared empuja la cámara
var _raise_vel := 0.0
var _auto_pitch_vel := 0.0
var _yaw_vel := 0.0
var _fov := BASE_FOV
var _fov_vel := 0.0
var _roll := 0.0
var _dip := 0.0
var _recenter := 0.0
var _was_air := false
var _drone := Vector3.ZERO
var _cam_pos := Vector3.INF
var _shape: SphereShape3D
var _query: PhysicsShapeQueryParameters3D
var _soft_query: PhysicsShapeQueryParameters3D

func setup(p: PlayerController, r: InputRouter) -> void:
	player = p
	router = r
	top_level = true
	cam = Camera3D.new()
	cam.fov = BASE_FOV
	cam.near = 0.08
	cam.far = 400.0
	cam.top_level = true
	add_child(cam)
	cam.current = true
	alt_cam = Camera3D.new()
	alt_cam.near = 0.05
	alt_cam.far = 400.0
	alt_cam.top_level = true
	add_child(alt_cam)
	_shape = SphereShape3D.new()
	_shape.radius = COLL_RADIUS
	_query = PhysicsShapeQueryParameters3D.new()
	_query.shape = _shape
	_query.collision_mask = 1
	_query.exclude = [p.get_rid()]
	var wide := SphereShape3D.new()
	wide.radius = 0.45
	_soft_query = PhysicsShapeQueryParameters3D.new()
	_soft_query.shape = wide
	_soft_query.collision_mask = 1
	_soft_query.exclude = [p.get_rid()]
	snap()

func cycle_view() -> void:
	set_view((view + 1) % VIEW_NAMES.size())

func set_view(v: int) -> void:
	view = v
	_drone = player.global_position + Vector3(0, 6, 6)
	if view == 0:
		cam.make_current()
	else:
		alt_cam.make_current()

## Coloca la cámara detrás del atleta al instante (inicio, reaparición, teletransporte).
func snap() -> void:
	yaw = atan2(-player.facing.x, -player.facing.z)
	pitch = _rest_pitch()
	var p := player.global_position
	_ref_y = p.y
	_focus = p + Vector3.UP * FOCUS_H
	_focus_vel = Vector3.ZERO
	_lead = Vector3.ZERO
	_lead_vel = Vector3.ZERO
	_len = BASE_LEN * Settings.camera_distance
	_dist = _len
	_dist_vel = 0.0
	_raise = 0.0
	_yaw_vel = 0.0
	_cam_pos = Vector3.INF
	global_position = _focus
	rotation = Vector3(pitch, yaw, 0)
	_place_camera(0.0)

func _process(dt: float) -> void:
	if player == null or dt <= 0.0:
		return
	var S := PlayerController.State
	var st := player.state
	var in_air := st == S.AIR
	_read_input(dt)
	_auto_align(dt, in_air)

	# --- Punto de mira: posición del atleta + anticipación, con el eje vertical tranquilo ---
	var ppos := player.get_global_transform_interpolated().origin
	if ppos.distance_to(_focus) > 9.0:
		snap()                                       # reaparición o teletransporte: sin barrido
		return
	var hv := player.horizontal_velocity()
	var lead_want := Vector3.ZERO
	if st in [S.GROUND, S.WALLRUN, S.VAULT, S.ROLL, S.SKILL]:
		lead_want = (hv * LEAD_TIME).limit_length(LEAD_MAX)
	elif in_air:
		lead_want = _lead                            # en el aire se congela: trayectoria estable
	var lr := _damp_v(_lead, lead_want, _lead_vel, 0.35, dt)
	_lead = lr[0]; _lead_vel = lr[1]
	# Vertical: en el suelo sigue al atleta; en el salto sube poco (se sigue viendo dónde caer) y
	# al caer más abajo de donde despegó le acompaña para no perderlo
	var ref_want := ppos.y
	var ref_smooth := 0.12
	if in_air:
		var t0 := player.takeoff_y
		if ppos.y >= t0:
			# Saltos muy altos (boya): nunca más de ~1 m por debajo del atleta, para no perderlo por arriba
			ref_want = maxf(t0 + (ppos.y - t0) * 0.35, ppos.y - 1.0)
			ref_smooth = 0.16
		else:
			# Cayendo más abajo de donde despegó: le acompaña de cerca (los pies no se salen)
			ref_want = ppos.y + minf((t0 - ppos.y) * 0.2, 0.3)
			ref_smooth = 0.07
	elif st in [S.HANG, S.WALLCLIMB, S.CLIMB_UP]:
		ref_smooth = 0.2
	var yr := _damp_f(_ref_y, ref_want, _ref_y_vel, ref_smooth, dt)
	_ref_y = yr[0]; _ref_y_vel = yr[1]
	_dip = lerpf(_dip, player.land_impact * 0.1 if st == S.GROUND else 0.0, 1.0 - exp(-18.0 * dt))
	var height := FOCUS_H + (Settings.camera_height - 1.0) * 0.6
	var focus_want := Vector3(ppos.x, _ref_y + height - _dip, ppos.z) + _lead
	if st == S.CRASH:
		focus_want.y -= 0.5
	var fr := _damp_v(_focus, focus_want, _focus_vel, 0.05 if not in_air else 0.13, dt)
	_focus = fr[0]; _focus_vel = fr[1]
	# En vertical ya va suavizado (_ref_y): sin un segundo retraso encima (al caer rápido el
	# atleta se saldría del cuadro)
	_focus.y = focus_want.y
	_focus_vel.y = 0.0
	global_position = _focus

	# --- Distancia y campo de visión: cambian poco y despacio (no alteran la percepción) ---
	var spd := player.speed()
	var speed_t := clampf(spd / player.t.sprint_speed, 0.0, 1.2)
	var len_want := (BASE_LEN + 0.3 * speed_t) * Settings.camera_distance
	if in_air and player.global_position.y - player.takeoff_y < -2.5:
		len_want += 0.4                              # caída grande: algo más de campo para el suelo
	var dr := _damp_f(_len, len_want, _len_vel, 0.5, dt)
	_len = dr[0]; _len_vel = dr[1]
	var fv := _damp_f(_fov, BASE_FOV + 6.0 * speed_t, _fov_vel, 0.6, dt)
	_fov = fv[0]; _fov_vel = fv[1]
	cam.fov = _fov - 9.0 * slowmo                    # cámara lenta: acercamiento suave al atleta
	_roll = lerpf(_roll, -0.05 * float(player.wall.get("side", 1.0)) if st == S.WALLRUN else 0.0, 1.0 - exp(-5.0 * dt))

	_place_camera(dt)
	player.camera_yaw = yaw
	if view == 1 and rig:
		Replay._pov(alt_cam, rig)                    # cámara de acción en la cabeza
	elif view == 2:
		# Dron: alto y detrás, sigue con algo de retraso y mira al atleta
		var want := ppos + Vector3(sin(yaw) * 6.5, 6.0, cos(yaw) * 6.5)
		_drone = _drone.lerp(want, 1.0 - exp(-2.2 * dt))
		alt_cam.global_position = _drone
		alt_cam.look_at(ppos + Vector3.UP * 0.9, Vector3.UP)
		alt_cam.fov = 58.0

## Arrastres del jugador (y doble toque = detrás del atleta).
func _read_input(dt: float) -> void:
	var cam_in := router.take_camera() if router else {"delta": Vector2.ZERO, "recenter": false}
	var cd: Vector2 = cam_in.delta
	if cd.length() > 0.0001:
		yaw -= cd.x
		# Arrastre casi horizontal = solo girar (el pulgar nunca va recto: sin inclinar por accidente);
		# en vertical, la mitad de sensibilidad
		var dy := cd.y if absf(cd.y) > absf(cd.x) * 0.45 else 0.0
		pitch -= dy * 0.55 * (-1.0 if Settings.invert_camera_y else 1.0)
		pitch = clampf(pitch, PITCH_MIN, PITCH_MAX)
		manual_timer = 0.0
		_recenter = 0.0
		_yaw_vel = 0.0
		_auto_pitch_vel = 0.0
	else:
		manual_timer += dt
	if cam_in.recenter:
		_recenter = 1.2

## Alineado automático: solo en el suelo (en el aire la cámara no gira: el jugador calcula la
## trayectoria con un encuadre fijo) y nunca da la vuelta cuando el atleta corre hacia la cámara.
func _auto_align(dt: float, in_air: bool) -> void:
	var S := PlayerController.State
	var behind := atan2(-player.facing.x, -player.facing.z)
	# Tras un tirabuzón que cambia hacia dónde mira: vuelve detrás al aterrizar, sin brusquedad
	if _was_air and not in_air and Settings.camera_mode != 1 and manual_timer > 0.6 \
			and not player.last_landing.get("trick", {}).is_empty() and absf(angle_difference(yaw, behind)) > 1.0:
		_recenter = 1.0
	_was_air = in_air
	if _recenter > 0.0:
		_recenter -= dt
		yaw = _damp_angle(yaw, behind, 0.22, dt)
		var pr := _damp_f(pitch, _rest_pitch(), _auto_pitch_vel, 0.3, dt)
		pitch = pr[0]; _auto_pitch_vel = pr[1]
		if absf(angle_difference(yaw, behind)) < 0.02:
			_recenter = 0.0
		return
	var hold: float = FOLLOW_HOLD[clampi(Settings.camera_mode, 0, 2)]
	var spd := player.speed()
	if manual_timer > hold and spd > 2.0 and player.state in [S.GROUND, S.WALLRUN, S.VAULT, S.ROLL, S.CLIMB_UP, S.SKILL]:
		var hv := player.horizontal_velocity()
		var target := atan2(-hv.x, -hv.z)
		var diff := absf(angle_difference(yaw, target))
		if diff < 2.4 and diff > 0.03:
			# Más rápido cuanto más corre (en sprint sigue las curvas; andando apenas se mueve)
			yaw = _damp_angle(yaw, target, lerpf(1.1, 0.4, clampf(spd / 9.0, 0.0, 1.0)), dt)
	else:
		_yaw_vel = 0.0
	if manual_timer > hold + 0.8:
		var want := _rest_pitch()
		if in_air and player.velocity.y < -2.0:
			want -= 0.1                              # cayendo: mira un poco más al suelo
		elif player.state in [S.HANG, S.WALLCLIMB]:
			want += 0.08
		var pr2 := _damp_f(pitch, want, _auto_pitch_vel, 0.8, dt)
		pitch = pr2[0]; _auto_pitch_vel = pr2[1]

## Coloca la cámara detrás del punto de mira evitando la geometría. Si una pared la empujaría a
## menos de MIN_DIST, prueba posiciones más altas (más cenitales) y se queda con la que más espacio
## deja: así nunca se mete en la cabeza del atleta ni queda atrapada detrás de una columna.
func _place_camera(dt: float) -> void:
	var from := _focus
	var chest := player.global_position + Vector3.UP * 1.1    # siempre libre (dentro de la cápsula)
	# Si el punto de mira quedara dentro de algo (techo bajo), se barre desde el pecho
	if _cast(chest, from) < 0.999:
		from = chest
	var need_raise := 0.0
	var swing := 0.0
	var free := _cast_dir(from, pitch - _raise, _len, yaw)
	if free < MIN_DIST * 1.6:
		# Algo detrás (pared baja, columna): primero solo subir por encima
		var best := free
		for k in [0.35, 0.7, 1.0]:
			var f2 := _cast_dir(from, pitch - k, _len, yaw)
			if f2 > best + 0.15:
				best = f2
				need_raise = k
			if best >= MIN_DIST * 1.5:
				break
		if best < MIN_DIST:
			# Atrapada (el atleta pegado a un muro mirando a la cámara): también girada a los lados;
			# se queda con la que más espacio deja, prefiriendo los cambios pequeños
			var best_score := best
			for k in [0.35, 0.7, 1.0]:
				for sy in [0.6, -0.6, 1.2, -1.2, 1.8, -1.8]:
					var f3 := _cast_dir(from, pitch - k, _len, yaw + sy)
					var score: float = f3 - 0.35 * absf(sy) - 0.25 * k
					if f3 > best + 0.15 and score > best_score:
						best = f3
						best_score = score
						need_raise = k
						swing = sy
	if dt <= 0.0 or free < 0.6:
		_raise = maxf(_raise, need_raise)            # casi dentro del atleta: sin esperar
		yaw += swing                                 # (la posición barre rápido hasta allí, abajo)
	else:
		var rr := _damp_f(_raise, need_raise, _raise_vel, 0.18 if need_raise > _raise else 0.8, dt)
		_raise = rr[0]; _raise_vel = rr[1]
		if swing != 0.0:
			yaw += swing * (1.0 - exp(-4.0 * dt))    # se desliza hacia el hueco libre
	var eff_pitch := clampf(pitch - _raise, -1.25, PITCH_MAX)
	# Nunca a ras de suelo: limita la inclinación para que la cámara quede por encima de los pies
	var feet_y := player.global_position.y if player.state != PlayerController.State.AIR else minf(player.global_position.y, player.takeoff_y)
	var room := (from.y - feet_y - GROUND_CLEAR) / maxf(_len, 0.5)
	eff_pitch = minf(eff_pitch, asin(clampf(room, -1.0, 1.0)))
	var hit := _cast_dir(from, eff_pitch, _len, yaw)
	# Barrido ancho: ve venir la pared antes de que se interponga y la cámara se acerca con
	# suavidad (en vez de saltar de golpe cuando el obstáculo cruza la línea de visión)
	var soft := minf(_cast_dir(from, eff_pitch, _len, yaw, _soft_query) + 0.35, _len)
	var want := minf(soft, hit)
	if dt <= 0.0:
		_dist = hit
		_dist_vel = 0.0
	else:
		var dd := _damp_f(_dist, want, _dist_vel, 0.16 if want < _dist else 0.45, dt)
		_dist = dd[0]; _dist_vel = dd[1]
	# Nunca dentro de la pared: el barrido fino manda
	if _dist > hit:
		_dist = hit
		_dist_vel = minf(_dist_vel, 0.0)
	var basis := Basis.from_euler(Vector3(eff_pitch, yaw, 0.0))
	var pos := from + basis * Vector3(0, 0, _dist)
	if dt > 0.0 and _cam_pos != Vector3.INF and _cam_pos.distance_to(pos) > 0.35:
		# Salto grande de posición (sale de detrás de un muro): barrido rápido en vez de corte,
		# sin atravesar nada (si el camino choca, se queda en el punto libre)
		var sweep := _cam_pos.lerp(pos, 1.0 - exp(-22.0 * dt))
		var fsw := _cast(from, sweep)
		pos = from + (sweep - from) * fsw
		basis = Basis.looking_at(from - pos, Vector3.UP) if from.distance_to(pos) > 0.05 else basis
	_cam_pos = pos
	cam.global_transform = Transform3D(basis, pos)
	cam.rotate_object_local(Vector3.FORWARD, _roll)
	rotation = Vector3(eff_pitch, yaw, 0.0)

## Distancia libre en la dirección de la órbita (giro y, inclinación p).
func _cast_dir(from: Vector3, p: float, length: float, y: float, q: PhysicsShapeQueryParameters3D = null) -> float:
	var dir := Basis.from_euler(Vector3(p, y, 0.0)) * Vector3(0, 0, 1)
	return length * _cast(from, from + dir * length, q)

## Fracción libre de un barrido con esfera de a hasta b (1 = sin obstáculos).
func _cast(a: Vector3, b: Vector3, q: PhysicsShapeQueryParameters3D = null) -> float:
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		return 1.0
	if q == null:
		q = _query
	q.transform = Transform3D(Basis(), a)
	q.motion = b - a
	var r := space.cast_motion(q)
	return float(r[0]) if r.size() > 0 else 1.0

## Inclinación de reposo según la altura elegida (más alta = algo más cenital).
func _rest_pitch() -> float:
	return BASE_PITCH - (Settings.camera_height - 1.0) * 0.35

# --- Muelles críticamente amortiguados (sin rebote: llegan suaves y no se pasan) ---

static func _damp_f(cur: float, target: float, vel: float, smooth: float, dt: float) -> Array:
	var omega := 2.0 / maxf(smooth, 0.0001)
	var x := omega * dt
	var e := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := cur - target
	var temp := (vel + omega * change) * dt
	return [target + (change + temp) * e, (vel - omega * temp) * e]

static func _damp_v(cur: Vector3, target: Vector3, vel: Vector3, smooth: float, dt: float) -> Array:
	var omega := 2.0 / maxf(smooth, 0.0001)
	var x := omega * dt
	var e := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := cur - target
	var temp := (vel + omega * change) * dt
	return [target + (change + temp) * e, (vel - omega * temp) * e]

func _damp_angle(cur: float, target: float, smooth: float, dt: float) -> float:
	var t2 := cur + angle_difference(cur, target)
	var r := _damp_f(cur, t2, _yaw_vel, smooth, dt)
	_yaw_vel = r[1]
	return r[0]
