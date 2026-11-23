class_name CameraRig
extends Node3D
## Cámara híbrida en tercera persona:
## - Control manual: arrastrar en cualquier zona libre de la pantalla (o stick derecho del mando /
##   ratón). Doble toque = se coloca detrás del atleta.
## - Seguimiento: se alinea sola detrás del movimiento, pero respeta lo que muevas a mano
##   (Ajustes → Cámara: Híbrida, Manual o Automática).
## - Anticipación: mira un poco hacia donde va el atleta.
## - Acrobacias: se abre de lado en los mortales (no gira con el cuerpo: evita mareos) y,
##   tras un tirabuzón, vuelve suavemente detrás del atleta.
## - SpringArm para no atravesar paredes; distancia y altura configurables.

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
var _lead := Vector3.ZERO     # anticipación hacia donde se mueve el atleta
var _recenter := 0.0          # > 0: volviendo detrás del atleta (doble toque o tras un tirabuzón)
var _was_air := false

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
	var cam_in := router.take_camera() if router else {"delta": Vector2.ZERO, "recenter": false}
	var cd: Vector2 = cam_in.delta
	if cd.length() > 0.0001:
		yaw -= cd.x
		pitch -= cd.y * (-1.0 if Settings.invert_camera_y else 1.0)
		pitch = clampf(pitch, -1.25, 0.6)
		manual_timer = 0.0
		_recenter = 0.0
	else:
		manual_timer += dt
	if cam_in.recenter:
		_recenter = 1.2
	# Tras un tirabuzón (cambia hacia dónde mira) la cámara vuelve detrás sin que haya que tocarla.
	var in_air := player.state == S.AIR
	if _was_air and not in_air and Settings.camera_mode != 1 and manual_timer > 0.6 \
			and not player.last_landing.get("trick", {}).is_empty() \
			and absf(angle_difference(yaw, atan2(-player.facing.x, -player.facing.z))) > 1.0:
		_recenter = 0.9
	_was_air = in_air
	if _recenter > 0.0:
		_recenter -= dt
		var behind := atan2(-player.facing.x, -player.facing.z)
		yaw = lerp_angle(yaw, behind, 1.0 - exp(-7.0 * dt))
		pitch = lerpf(pitch, _rest_pitch(), 1.0 - exp(-5.0 * dt))
		if absf(angle_difference(yaw, behind)) < 0.02:
			_recenter = 0.0

	var ppos := player.get_global_transform_interpolated().origin
	var target := ppos + Vector3.UP * (1.3 + (Settings.camera_height - 1.0) * 0.6)
	# Anticipación: el encuadre se adelanta un poco hacia donde corre el atleta.
	var lead_want := player.horizontal_velocity() * 0.07
	if player.state in [S.CRASH, S.HANG, S.WALLCLIMB]:
		lead_want = Vector3.ZERO
	_lead = _lead.lerp(lead_want.limit_length(0.7), 1.0 - exp(-3.0 * dt))
	target += _lead
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
	var hold: float = [2.5, INF, 0.8][clampi(Settings.camera_mode, 0, 2)]   # híbrida, manual, automática
	if manual_timer > hold and _recenter <= 0.0 and spd > 2.0 and player.state in follow_states:
		var hv := player.horizontal_velocity()
		var target_yaw := atan2(-hv.x, -hv.z)
		var diff := absf(angle_difference(yaw, target_yaw))
		if diff < 2.4:   # no dar la vuelta completa cuando el jugador corre hacia la cámara
			var rate := 1.2 * clampf(spd / 6.0, 0.3, 1.6)
			yaw = lerp_angle(yaw, target_yaw, 1.0 - exp(-rate * dt))
	if manual_timer > hold + 0.8:
		pitch = lerpf(pitch, _rest_pitch(), 1.0 - exp(-1.0 * dt))

	var speed_t := clampf(spd / player.t.sprint_speed, 0.0, 1.3)
	# Plano cinematográfico en acrobacias grandes (dobles, tirabuzones): leve giro lateral y zoom.
	var tr := player.tricks
	var tricking := player.state == S.AIR and tr.active
	var big: bool = tricking and (tr.goal.get(tr.primary_axis(), 0) >= 2 or tr.dir.get("twist", 0) != 0 or (tr.tucked and tr.air_time > 0.25))
	# Mortales (eje de cabeceo): la cámara se abre un poco hacia el lado para ver el perfil del giro.
	var want_orbit := 0.0
	# Desde justo detrás el agrupado de un mortal adelante/atrás no se distingue: ~35-40° de lado
	# se ve el perfil (rodillas al pecho). Gira rápido al despegar y vuelve despacio al caer.
	if tricking and tr.dir.get("pitch", 0) != 0 and manual_timer > 0.5:
		want_orbit = 0.7 if big else 0.62
	_orbit = lerpf(_orbit, want_orbit, 1.0 - exp(-(3.2 if want_orbit > 0.0 else 0.9) * dt))
	var fov_want := BASE_FOV + 8.0 * speed_t - (5.0 if big else 0.0)
	_fov = lerpf(_fov, fov_want, 1.0 - exp(-3.0 * dt))
	cam.fov = _fov
	var want_len := (BASE_LEN + 0.5 * speed_t - (0.35 if tricking else 0.0)) * Settings.camera_distance   # en acrobacia, más cerca: se ve el cuerpo
	_len = lerpf(_len, want_len, 1.0 - exp(-3.0 * dt))
	spring.spring_length = _len
	var want_roll := 0.0
	if player.state == S.WALLRUN:
		want_roll = -0.07 * float(player.wall.get("side", 1.0))
	_roll = lerpf(_roll, want_roll, 1.0 - exp(-5.0 * dt))
	rotation = Vector3(pitch, yaw + _orbit, 0.0)
	cam.rotation = Vector3(0, 0, _roll)
	player.camera_yaw = yaw

## Inclinación de reposo según la altura elegida (más alta = algo más cenital).
func _rest_pitch() -> float:
	return BASE_PITCH - (Settings.camera_height - 1.0) * 0.35
