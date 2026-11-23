class_name CameraRig
extends Node3D
## Cámara en tercera persona: seguimiento suave, control manual, auto-alineado con el
## movimiento, FOV y distancia según velocidad, inclinación en wall run y SpringArm
## para no atravesar paredes. No gira con las acrobacias (evita mareos).

var player: PlayerController
var router: InputRouter
var spring: SpringArm3D
var cam: Camera3D

var yaw := 0.0
var pitch := -0.32
var manual_timer := 10.0
var _pos := Vector3.ZERO
var _fov := 70.0
var _roll := 0.0
var _len := 3.0
var _orbit := 0.0            # giro cinematográfico suave durante acrobacias grandes
var _dip := 0.0

const BASE_PITCH := -0.32
const BASE_FOV := 64.0
const BASE_LEN := 3.0         # más cerca: el personaje ocupa más pantalla en el móvil

func setup(p: PlayerController, r: InputRouter) -> void:
	player = p
	router = r
	top_level = true
	spring = SpringArm3D.new()
	spring.spring_length = _len
	spring.margin = 0.15
	var sphere := SphereShape3D.new()
	sphere.radius = 0.22
	spring.shape = sphere
	spring.collision_mask = 1
	spring.add_excluded_object(p.get_rid())
	add_child(spring)
	cam = Camera3D.new()
	cam.fov = BASE_FOV
	cam.near = 0.08
	cam.far = 400.0
	spring.add_child(cam)
	cam.current = true
	snap()

func snap() -> void:
	yaw = atan2(-player.facing.x, -player.facing.z)
	_pos = player.global_position + Vector3.UP * 1.3
	global_position = _pos
	rotation = Vector3(pitch, yaw, 0)

func _process(dt: float) -> void:
	if player == null:
		return
	var S := PlayerController.State
	var cd := router.intent.camera_delta if router else Vector2.ZERO
	if cd.length() > 0.0001:
		yaw -= cd.x
		pitch -= cd.y * (-1.0 if Settings.invert_camera_y else 1.0)
		pitch = clampf(pitch, -1.25, 0.6)
		manual_timer = 0.0
	else:
		manual_timer += dt

	var ppos := player.get_global_transform_interpolated().origin
	var target := ppos + Vector3.UP * 1.3
	if player.state == S.CRASH:
		target.y -= 0.6
	if player.state == S.AIR:
		# En el salto la cámara sube menos que el personaje: se sigue viendo el suelo para aterrizar.
		var above := maxf(0.0, ppos.y - player.takeoff_y)
		target.y -= minf(above * 0.3, 0.9)
	# Pequeño hundimiento al recibir el impacto (sensación de peso)
	_dip = lerpf(_dip, player.land_impact * 0.14 if player.state == S.GROUND else 0.0, 1.0 - exp(-20.0 * dt))
	target.y -= _dip
	var hk := 1.0 - exp(-14.0 * dt)
	var vk := 1.0 - exp(-(11.0 if player.state in [S.AIR, S.VAULT] else 16.0) * dt)
	_pos.x = lerpf(_pos.x, target.x, hk)
	_pos.z = lerpf(_pos.z, target.z, hk)
	_pos.y = lerpf(_pos.y, target.y, vk)
	global_position = _pos

	# Auto-alineado detrás del movimiento cuando el jugador no toca la cámara.
	var spd := player.speed()
	var follow_states := [S.GROUND, S.WALLRUN, S.VAULT, S.ROLL, S.CLIMB_UP]
	if manual_timer > 1.2 and spd > 2.0 and player.state in follow_states:
		var hv := player.horizontal_velocity()
		var target_yaw := atan2(-hv.x, -hv.z)
		var diff := absf(angle_difference(yaw, target_yaw))
		if diff < 2.4:   # no dar la vuelta completa cuando el jugador corre hacia la cámara
			var rate := 1.2 * clampf(spd / 6.0, 0.3, 1.6)
			yaw = lerp_angle(yaw, target_yaw, 1.0 - exp(-rate * dt))
	if manual_timer > 2.0:
		pitch = lerpf(pitch, BASE_PITCH, 1.0 - exp(-1.0 * dt))

	var speed_t := clampf(spd / player.t.sprint_speed, 0.0, 1.3)
	# Plano cinematográfico en acrobacias grandes (dobles, tirabuzones): leve giro lateral y zoom.
	var tr := player.tricks
	var tricking := player.state == S.AIR and tr.active
	var big: bool = tricking and (tr.goal.get(tr.primary_axis(), 0) >= 2 or tr.dir.get("twist", 0) != 0 or (tr.tucked and tr.air_time > 0.25))
	# Mortales (eje de cabeceo): la cámara se abre un poco hacia el lado para ver el perfil del giro.
	var want_orbit := 0.0
	if tricking and tr.dir.get("pitch", 0) != 0:
		want_orbit = 0.42 if big else 0.3
	_orbit = lerpf(_orbit, want_orbit, 1.0 - exp(-(1.8 if want_orbit > 0.0 else 0.9) * dt))
	var fov_want := BASE_FOV + 8.0 * speed_t - (5.0 if big else 0.0)
	_fov = lerpf(_fov, fov_want, 1.0 - exp(-3.0 * dt))
	cam.fov = _fov
	var want_len := (BASE_LEN + 0.5 * speed_t + (0.35 if tricking else 0.0)) * Settings.camera_distance
	_len = lerpf(_len, want_len, 1.0 - exp(-3.0 * dt))
	spring.spring_length = _len
	var want_roll := 0.0
	if player.state == S.WALLRUN:
		want_roll = -0.07 * float(player.wall.get("side", 1.0))
	_roll = lerpf(_roll, want_roll, 1.0 - exp(-5.0 * dt))
	rotation = Vector3(pitch, yaw + _orbit, 0.0)
	cam.rotation = Vector3(0, 0, _roll)
	player.camera_yaw = yaw
