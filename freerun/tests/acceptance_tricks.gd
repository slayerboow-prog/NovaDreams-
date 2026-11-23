extends Node
## Pruebas de aceptación de acrobacias por la RUTA REAL DEL MÓVIL:
## eventos táctiles sobre los controles en pantalla (joystick + botón SALTO deslizando),
## sin atajos. Para cada truco se comprueba de principio a fin:
##   impulso · despegue · rotación completa visible · orientación final · aterrizaje
##   limpio · recuperación del control · seguir corriendo.
##
## headless:  godot --headless --fixed-fps 60 res://tests/acceptance_tricks.tscn
## vídeo:     xvfb-run godot --rendering-driver opengl3 --fixed-fps 30 res://tests/acceptance_tricks.tscn -- --capture=<dir>

var game: Node
var player: PlayerController
var touch: TouchControls
var results: Array = []
var moves: Array[String] = []
var landings: Array = []
var capture_dir := ""
var _frame_no := 0
var _label: Label

const SPOT := Vector3(0, 0.1, 27)

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture="):
			capture_dir = a.substr(10)
			DirAccess.make_dir_recursive_absolute(capture_dir)
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	Settings.force_touch_ui = true
	Settings.rotation_assist = 2
	game.start_mode("tricking")
	player = game.player
	touch = game.ui.touch
	touch.visible = true
	player.move_performed.connect(func(n, _q, _i): moves.append(n))
	player.landed.connect(func(r): landings.append(r))
	if capture_dir != "":
		_label = Label.new()
		_label.add_theme_font_size_override("font_size", 34)
		_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_label.add_theme_constant_override("outline_size", 8)
		_label.position = Vector2(30, 90)
		game.ui.add_child(_label)
	await frames(10)

	# nombre, gesto(s), carrera, regla de mantener, eje principal
	await trick("Backflip", [Vector2(0, -1)], false, "tap")
	await trick("Frontflip", [Vector2(0, 1)], false, "tap")
	await trick("Sideflip", [Vector2(1, 0)], false, "tap")
	await trick("Aerial", [Vector2(-1, 0)], true, "tap")
	await trick("Gainer", [Vector2(0, -1)], true, "tap")
	await trick("Webster", [Vector2(0, 1)], true, "tap")
	await trick("Butterfly Kick", [Vector2(0.7, 0.7)], true, "tap")
	await trick("Cheat Gainer", [Vector2(0, -1), Vector2(1, 0)], true, "tap")
	await trick("Cork", [Vector2(0.7, -0.7)], true, "tap")
	await trick("Cork 720", [Vector2(-0.7, -0.7), Vector2(-1, 0)], true, "tap")
	await trick("Double Backflip", [Vector2(0, -1)], false, "double")
	await trick("Double Cork", [Vector2(0.7, -0.7)], true, "double")

	var failed := 0
	print("\n========== ACEPTACIÓN DE ACROBACIAS (ruta táctil real) ==========")
	for r in results:
		print(("  OK   " if r[1] else "  FAIL ") + r[0] + ("" if r[1] else "   -> " + r[2]))
		if not r[1]:
			failed += 1
	print("%d/%d criterios superados" % [results.size() - failed, results.size()])
	get_tree().quit(1 if failed > 0 else 0)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		_capture()

func _capture() -> void:
	if capture_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_jpg(capture_dir.path_join("f_%05d.jpg" % _frame_no), 0.85)
	_frame_no += 1

func check(name: String, ok: bool, detail := "") -> void:
	results.append([name, ok, detail])

# ------------------------------------------------------------------ toques

func _touch(idx: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = pos
	e.pressed = pressed
	touch._on_touch(e)

func _drag(idx: int, pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	e.relative = rel
	touch._on_drag(e)

func joystick(on: bool) -> void:
	var base := Vector2(200, touch.size.y - 200)
	if on:
		var up := Vector2(0, -90.0 * touch._s())
		_touch(0, base, true)
		_drag(0, base + up, up)
	else:
		_touch(0, base + Vector2(0, -90.0 * touch._s()), false)

# ------------------------------------------------------------------ truco

func trick(name: String, swipes: Array, running: bool, hold: String) -> void:
	if _label:
		_label.text = name.to_upper() + "   (SALTO + deslizar" + (" y mantener)" if hold == "double" else ")")
	player.set_spawn(Transform3D(Basis(), SPOT), Vector3.FORWARD)
	player.respawn()
	game.camera.snap()
	player.camera_yaw = 0.0
	await frames(15)
	moves.clear()
	landings.clear()
	if running:
		joystick(true)
		await frames(50)
	var speed_before := player.speed()
	var jc := touch._jump_center()
	_touch(1, jc, true)                                   # pulsa SALTO
	await frames(1)
	var y0 := player.global_position.y
	var pos := jc
	# Desliza el mismo dedo (primer gesto)
	var d0: Vector2 = swipes[0]
	for k in 4:
		var step := Vector2(d0.x, -d0.y).normalized() * 18.0 * touch._s()
		pos += step
		_drag(1, pos, step)
		await frames(1)
	# Gestos adicionales con el mismo dedo (tirabuzón)
	for si in range(1, swipes.size()):
		await frames(6)
		var dv: Vector2 = swipes[si]
		for k in 4:
			var step := Vector2(dv.x, -dv.y).normalized() * 20.0 * touch._s()
			pos += step
			_drag(1, pos, step)
			await frames(1)
	# Mantener o soltar
	var peak := y0
	var inverted := false
	var horizontal := false
	var max_rot := 0.0
	var released := hold == "tap"
	if released:
		_touch(1, pos, false)
	var left_ground := false
	for i in 150:
		await frames(1)
		var tr := player.tricks
		var up := tr.basis * Vector3.UP
		if up.dot(Vector3.UP) < -0.5:
			inverted = true
		if absf(up.dot(Vector3.UP)) < 0.45:
			horizontal = true
		max_rot = maxf(max_rot, maxf(absf(tr.total_pitch), maxf(absf(tr.total_roll), absf(tr.total_spin))))
		peak = maxf(peak, player.global_position.y)
		if player.state == PlayerController.State.AIR:
			left_ground = true
		if not released and absf(tr.total_pitch) > TAU * 2.0 - deg_to_rad(100):
			_touch(1, pos, false)                         # suelta para preparar el aterrizaje
			released = true
		if left_ground and player.state != PlayerController.State.AIR:
			break
	if not released:
		_touch(1, pos, false)
	var landed: Dictionary = landings[-1] if landings.size() > 0 else {}
	var q: String = landed.get("quality", "none")
	# Recupera el control y sigue corriendo
	if not running:
		joystick(true)
	await frames(40)
	var recovered := player.state in [PlayerController.State.GROUND, PlayerController.State.ROLL] and player.speed() > 3.0
	joystick(false)
	var need_rot := TAU * (2.0 if hold == "double" else 1.0) - deg_to_rad(10)
	var tag := "[%s] " % name
	check(tag + "despega con impulso (sube > 1 m)", left_ground and peak - y0 > 1.0, "altura %.2f" % (peak - y0))
	check(tag + "rotación completa (%d°)" % int(rad_to_deg(need_rot) + 10), max_rot >= need_rot, "%d°" % int(rad_to_deg(max_rot)))
	if name.begins_with("Butterfly"):
		check(tag + "cuerpo en horizontal visible", horizontal, "")
	else:
		check(tag + "pasa boca abajo (visible)", inverted, "")
	check(tag + "aterriza limpio y orientado", q in ["perfect", "clean"], "%s error %.0f°" % [q, landed.get("error", -1.0)])
	check(tag + "reconocido como " + name, name in moves, str(moves))
	check(tag + "recupera el control y sigue corriendo", recovered, "%s %.1f m/s" % [PlayerController.STATE_NAMES[player.state], player.speed()])
	if running:
		check(tag + "conserva impulso de la carrera", speed_before > 6.0, "%.1f" % speed_before)
	await frames(15)
