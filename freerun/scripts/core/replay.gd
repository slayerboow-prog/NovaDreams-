class_name Replay
extends Node
## Repetición: graba siempre los últimos segundos del atleta (posición, orientación y todas las
## articulaciones ya resueltas con la IK) y los reproduce con cámara libre, POV o dron, a cámara
## lenta si se quiere, para ver y grabar con el móvil un buen combo.

const MAX_T := 15.0               # segundos guardados
const VIEWS := ["LIBRE", "POV", "DRON", "SEGUIR"]

var game: Node
var rig: BodyRig
var player: PlayerController
var frames: Array = []            # {"t", "p", "r", "pv", "b", "j": Array[Transform3D], "g"}
var playing := false
var paused := false
var speed := 1.0
var play_t := 0.0
var view := 0
var cam: Camera3D
# Cámara libre: órbita alrededor del atleta
var orbit_yaw := 0.0
var orbit_pitch := -0.35
var orbit_dist := 4.0
var _clock := 0.0
var _joint_names: Array = []
var _live := {}
var _drone_pos := Vector3.ZERO
var _prev_cam: Camera3D

signal changed

func setup(g: Node) -> void:
	game = g
	rig = g.rig
	player = g.player
	_joint_names = rig.joints.keys()
	cam = Camera3D.new()
	cam.name = "ReplayCamera"
	cam.near = 0.05
	cam.far = 400.0
	cam.fov = 62.0
	add_child(cam)

func duration() -> float:
	if frames.size() < 2:
		return 0.0
	return float(frames[-1].t) - float(frames[0].t)

func progress() -> float:
	var d := duration()
	return 0.0 if d <= 0.0 else clampf((play_t - float(frames[0].t)) / d, 0.0, 1.0)

func seek(f: float) -> void:
	if frames.size() < 2:
		return
	play_t = float(frames[0].t) + clampf(f, 0.0, 1.0) * duration()
	_apply_at(play_t)

func _process(dt: float) -> void:
	if playing:
		if not paused:
			play_t += dt * speed
			if play_t >= float(frames[-1].t):
				play_t = float(frames[-1].t)
				paused = true            # al final se queda parado (INICIO para volver a verlo)
				changed.emit()
		_apply_at(play_t)
		_update_camera(dt)
		return
	if game.in_menu or game.paused or rig == null:
		return
	_clock += dt
	frames.append(_capture())
	while frames.size() > 2 and float(frames[0].t) < _clock - MAX_T:
		frames.pop_front()

func _capture() -> Dictionary:
	var js: Array[Transform3D] = []
	for n in _joint_names:
		js.append((rig.joints[n] as Node3D).transform)
	return {"t": _clock, "p": player.global_transform, "r": rig.transform, "pv": rig.pivot.transform,
		"b": rig.body.transform, "j": js, "g": rig.grab_w}

func can_start() -> bool:
	return duration() > 0.5

func start() -> bool:
	if playing or not can_start():
		return false
	_live = _capture()
	playing = true
	paused = false
	speed = 1.0
	play_t = float(frames[0].t)
	player.set_physics_process(false)
	rig.set_process(false)
	game.router.enabled = false
	game.camera.set_process(false)
	_prev_cam = get_viewport().get_camera_3d()
	var yaw0: float = game.camera.yaw
	orbit_yaw = yaw0 + 0.6
	orbit_pitch = -0.3
	orbit_dist = 4.2
	_drone_pos = player.global_position + Vector3(0, 6, 6)
	cam.make_current()
	_apply_at(play_t)
	changed.emit()
	return true

func stop() -> void:
	if not playing:
		return
	playing = false
	_apply(_live)
	player.set_physics_process(true)
	rig.set_process(true)
	game.router.enabled = true
	game.camera.set_process(true)
	if _prev_cam and is_instance_valid(_prev_cam):
		_prev_cam.make_current()
	changed.emit()

func toggle_pause() -> void:
	if not playing:
		return
	if paused and play_t >= float(frames[-1].t) - 0.001:
		play_t = float(frames[0].t)
	paused = not paused
	changed.emit()

func restart() -> void:
	play_t = float(frames[0].t)
	paused = false
	changed.emit()

func cycle_speed() -> void:
	speed = {1.0: 0.5, 0.5: 0.25, 0.25: 1.0}.get(speed, 1.0)
	changed.emit()

func cycle_view() -> void:
	view = (view + 1) % VIEWS.size()
	changed.emit()

## Cámara libre: arrastrar = girar alrededor del atleta (y subir/bajar); zoom con +/-.
func orbit(delta: Vector2) -> void:
	orbit_yaw -= delta.x * 0.008
	orbit_pitch = clampf(orbit_pitch - delta.y * 0.006, -1.35, 0.5)
	if view != 0:
		view = 0
		changed.emit()

func zoom(f: float) -> void:
	orbit_dist = clampf(orbit_dist * f, 1.2, 14.0)

func _apply_at(t: float) -> void:
	if frames.is_empty():
		return
	var i := 0
	var lo := 0
	var hi := frames.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if float(frames[mid].t) <= t:
			lo = mid
		else:
			hi = mid
	i = lo
	var a: Dictionary = frames[i]
	var b: Dictionary = frames[mini(i + 1, frames.size() - 1)]
	var span := float(b.t) - float(a.t)
	var w := 0.0 if span <= 0.0 else clampf((t - float(a.t)) / span, 0.0, 1.0)
	_apply(_lerp_frame(a, b, w))

func _lerp_frame(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	if w <= 0.0:
		return a
	var js: Array[Transform3D] = []
	for k in a.j.size():
		js.append((a.j[k] as Transform3D).interpolate_with(b.j[k], w))
	return {"t": lerpf(a.t, b.t, w), "p": (a.p as Transform3D).interpolate_with(b.p, w), "r": (a.r as Transform3D).interpolate_with(b.r, w),
		"pv": (a.pv as Transform3D).interpolate_with(b.pv, w), "b": (a.b as Transform3D).interpolate_with(b.b, w), "j": js,
		"g": lerpf(a.g, b.g, w)}

func _apply(f: Dictionary) -> void:
	if f.is_empty():
		return
	player.global_transform = f.p
	player.reset_physics_interpolation()
	rig.transform = f.r
	rig.pivot.transform = f.pv
	rig.body.transform = f.b
	for k in _joint_names.size():
		(rig.joints[_joint_names[k]] as Node3D).transform = f.j[k]
	if rig.skin_body:
		rig.skin_body.sync()
	if rig.human:
		rig.human.sync(float(f.g))

func _update_camera(dt: float) -> void:
	var focus := (rig.joints["pelvis"] as Node3D).global_position
	match VIEWS[view]:
		"LIBRE":
			var dir := Vector3(sin(orbit_yaw) * cos(orbit_pitch), -sin(orbit_pitch), cos(orbit_yaw) * cos(orbit_pitch))
			cam.global_position = focus + dir * orbit_dist
			cam.look_at(focus, Vector3.UP)
			cam.fov = 62.0
		"POV":
			_pov(cam, rig)
		"DRON":
			var want := focus + Vector3(sin(orbit_yaw) * 6.5, 6.0, cos(orbit_yaw) * 6.5)
			_drone_pos = _drone_pos.lerp(want, 1.0 - exp(-2.0 * dt))
			cam.global_position = _drone_pos
			cam.look_at(focus, Vector3.UP)
			cam.fov = 58.0
		"SEGUIR":
			var fwd: Vector3 = -(rig.body.global_basis.z)
			fwd.y = 0.0
			if fwd.length() < 0.1:
				fwd = Vector3.FORWARD
			var want2 := focus - fwd.normalized() * 3.2 + Vector3.UP * 1.0
			cam.global_position = cam.global_position.lerp(want2, 1.0 - exp(-6.0 * dt))
			cam.look_at(focus + Vector3.UP * 0.2, Vector3.UP)
			cam.fov = 64.0

## Cámara de acción en la cabeza (tipo GoPro): delante de la cara, mirando hacia donde mira la cabeza.
static func _pov(c: Camera3D, r: BodyRig) -> void:
	var neck: Node3D = r.joints["neck"]
	var g := neck.global_transform.orthonormalized()
	var eye := g * Vector3(0, 0.17, -0.2)
	if r.human and r.human.skeleton:
		# Atleta realista: a la altura de los ojos de su cabeza, por delante de la frente y el pelo
		var sk := r.human.skeleton
		var hb := sk.find_bone("head")
		if hb >= 0:
			var hp := (sk.global_transform * sk.get_bone_global_pose(hb)).origin
			eye = hp + g.basis.y * 0.08 - g.basis.z * 0.2
	c.global_transform = Transform3D(g.basis, eye)
	c.fov = 96.0
