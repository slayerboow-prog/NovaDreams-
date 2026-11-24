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
var only := ""                         # --only=joystick : graba/prueba solo los trucos cuyo nombre lo contenga
var _frame_no := 0
var _label: Label

const SPOT := Vector3(0, 0.1, 27)

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture="):
			capture_dir = a.substr(10)
			DirAccess.make_dir_recursive_absolute(capture_dir)
		elif a.begins_with("--only="):
			only = a.substr(7)
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
	await trick("Sideflip", [Vector2(-1, 0)], true, "tap")   # con carrera: también encogido
	await trick("Aerial", [Vector2(-0.7, 0.7)], false, "tap")
	await trick("Gainer", [Vector2(0, -1)], true, "tap")
	await trick("Webster", [Vector2(0, 1)], true, "tap")
	await trick("Butterfly Kick", [Vector2(-0.7, 0.7)], true, "tap")
	await trick("Cheat Gainer", [Vector2(0, -1), Vector2(1, 0)], true, "tap")
	await trick("Cork", [Vector2(0.7, -0.7)], true, "tap")
	await trick("Cork 720", [Vector2(-0.7, -0.7), Vector2(-1, 0)], true, "tap")
	await trick("Double Backflip", [Vector2(0, -1), Vector2(0, -1)], false, "double")
	await trick("Double Cork", [Vector2(0.7, -0.7), Vector2(0.7, -0.7)], true, "double")
	# Nuevos: SALTO otra vez en el aire (Vector2.ZERO) = giro / tirabuzón completo
	await trick("360 Kick", [Vector2.ZERO], false, "tap")
	await trick("Back Full", [Vector2(0, -1), Vector2.ZERO], false, "tap")
	await trick("Gainer Full", [Vector2(0, -1), Vector2.ZERO], true, "tap")
	# DOBLE JOYSTICK: rueda SALTO/MORTALES (zona = salto + mortal, mantener = agrupado) y
	# joystick GIRO para el tirabuzón (toques reales, multitáctil). Vector2 = zona de la rueda
	# (la primera en el suelo, las siguientes en el aire); int = fotogramas de GIRO (+ derecha).
	await trick("Backflip", [Vector2(0, -1)], false, "stick")
	await trick("Frontflip", [Vector2(0, 1)], false, "stick")
	await trick("Sideflip", [Vector2(1, 0)], true, "stick")
	await trick("Sideflip", [Vector2(-1, 0)], false, "stick")
	await trick("Gainer", [Vector2(0, -1)], true, "stick")
	await trick("Webster", [Vector2(0, 1)], true, "stick")
	await trick("Cork", [Vector2(0, -1), 26], true, "stick")
	await trick("Cork 720", [Vector2(0, -1), 52], true, "stick")
	await trick("Front Full", [Vector2(0, 1), -26], false, "stick")
	await trick("Back Half", [Vector2(0, -1), 13], false, "stick")
	await trick("Backflip Hyper", [Vector2(0, -1), 5], false, "stick")
	await trick("Double Backflip", [Vector2(0, -1), Vector2(0, -1)], false, "stick")
	# TRICKING DE SUELO: joystick derecho sin SALTO (toques reales)
	await seq("Cartwheel", [["stick", Vector2(1, 0), 22], ["land"]], ["Cartwheel"])
	await seq("Round-off", [["stick", Vector2(0.7, -0.7), 22], ["land"]], ["Round-off"])
	await seq("Back Handspring", [["stick", Vector2(0, -1), 22], ["land"]], ["Back Handspring"])
	await seq("Front Handspring", [["stick", Vector2(0, 1), 22], ["land"]], ["Front Handspring"])
	await seq("Butterfly Kick (suelo)", [["run", true], ["wait", 40], ["stick", Vector2(-0.7, 0.7), 22], ["land"]], ["Butterfly Kick"])
	await seq("360 Kick (suelo)", [["stick", Vector2(0.7, 0.7), 22], ["land"]], ["360 Kick"])
	# COMBINACIONES (toques reales, multitáctil)
	await seq("Round-off → Backflip", [["stick", Vector2(0.7, -0.7), 22], ["rebound"], ["jumpwheel", Vector2(0, -1)], ["land"]], ["Round-off", "@back"])
	await seq("Round-off → Back Handspring → Backflip", [["stick", Vector2(0.7, -0.7), 22], ["rebound"], ["stick", Vector2(0, -1), 18], ["rebound"], ["jumpwheel", Vector2(0, -1)], ["land"]], ["Round-off", "Back Handspring", "@back"])
	await seq("Aerial → Butterfly Kick", [["stick", Vector2(-0.7, 0.7), 22], ["land"], ["run", true], ["wait", 30], ["stick", Vector2(-0.7, 0.7), 22], ["land"]], ["Aerial", "Butterfly Kick"])
	await seq("Gainer → Cork", [["run", true], ["wait", 45], ["jumpwheel", Vector2(0, -1)], ["land"], ["wait", 6], ["jumpwheel", Vector2(0, -1), 26], ["land"]], ["Gainer", "Cork"])
	await seq("Backflip + giro adicional (Back Full)", [["jumpwheel", Vector2(0, -1)], ["wait", 8], ["tapstick"], ["land"]], ["Back Full"])
	await seq("Cork 720 + aterrizaje controlado", [["run", true], ["wait", 45], ["jumpwheel", Vector2(0, -1), -52], ["land"]], ["Cork 720"])

	var failed := 0
	print("\n========== ACEPTACIÓN DE ACROBACIAS (ruta táctil real) ==========")
	for r in results:
		print(("  OK   " if r[1] else "  FAIL ") + r[0] + ("" if r[1] else "   -> " + r[2]))
		if not r[1]:
			failed += 1
	print("%d/%d criterios superados" % [results.size() - failed, results.size()])
	get_tree().quit(1 if failed > 0 else 0)

var sampling := false
var phases := {}
var kinds := {}
var max_tuck := 0.0
var max_lead := 0.0
var max_split := 0.0
var max_scissor := 0.0
var max_arms := 0.0                    # brazos por encima de la cabeza (apoyo de manos)
var max_arch := 0.0                    # espalda arqueada (flic-flac, paloma)
var skill_phases := {}                 # fases con nombre de las habilidades de suelo
var hand_support := false              # hubo apoyo real de manos (IK clavado al suelo)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		if sampling:
			_sample()
		_capture()

## Lo que se VE en el cuerpo durante el vuelo: fase de la acrobacia y forma de piernas.
func _sample() -> void:
	var tr := player.tricks
	var rig: BodyRig = game.rig
	if player.state == PlayerController.State.SKILL:
		skill_phases[rig.last_phase] = true
		kinds[rig.last_kind] = true
		max_split = maxf(max_split, absf((rig.pose.hip_l as Vector3).z - (rig.pose.hip_r as Vector3).z))
		max_arms = maxf(max_arms, minf((rig.pose.shoulder_l as Vector3).x, (rig.pose.shoulder_r as Vector3).x))
		max_arch = maxf(max_arch, (rig.pose.spine as Vector3).x)
		for c in ["hl", "hr"]:
			if rig.contact_w[c] > 0.99:
				hand_support = true
		return
	if player.state != PlayerController.State.AIR or not tr.active:
		return
	phases[rig.last_phase] = true
	kinds[rig.last_kind] = true
	var hl: Vector3 = rig.pose.hip_l
	var hr: Vector3 = rig.pose.hip_r
	max_tuck = maxf(max_tuck, minf(hl.x, hr.x))
	max_lead = maxf(max_lead, maxf(hl.x, hr.x))
	max_split = maxf(max_split, absf(hl.z - hr.z))
	max_scissor = maxf(max_scissor, absf(hl.x - hr.x))
	max_arms = maxf(max_arms, minf((rig.pose.shoulder_l as Vector3).x, (rig.pose.shoulder_r as Vector3).x))
	max_arch = maxf(max_arch, (rig.pose.spine as Vector3).x)

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
		var up := Vector2(0, -100.0 * touch._s())
		_touch(0, base, true)
		_drag(0, base + up, up)
	else:
		_touch(0, base + Vector2(0, -100.0 * touch._s()), false)

## Joystick derecho con toques reales: se apoya el pulgar en el centro y se inclina a fondo.
var stick_pos := Vector2.ZERO
func _stick_push(dir: Vector2) -> void:
	var rc := touch._rot_center()
	if stick_pos == Vector2.ZERO:
		_touch(2, rc, true)
		stick_pos = rc
	var target := rc + Vector2(dir.x, -dir.y).normalized() * touch._rot_travel()
	for k in 3:
		var np: Vector2 = stick_pos.lerp(target, 1.0 / (3 - k))
		_drag(2, np, np - stick_pos)
		stick_pos = np
		await frames(1)

func _stick_center() -> void:
	var rc := touch._rot_center()
	for k in 2:
		var np: Vector2 = stick_pos.lerp(rc, 1.0 / (2 - k))
		_drag(2, np, np - stick_pos)
		stick_pos = np
		await frames(1)

func _stick_release() -> void:
	_touch(2, stick_pos, false)
	stick_pos = Vector2.ZERO

## Secuencia de toques reales: movimientos de suelo y combinaciones.
##   ["stick", dir, frames]  inclinar el joystick derecho (sin SALTO) y soltarlo
##   ["jumpwheel", dir, giro?]  zona de la rueda de SALTO (+ fotogramas de joystick GIRO, + derecha)
##   ["jumpstick", dir, dir2?]  SALTO y joystick derecho (dir2: volver al centro y llevarlo a dir2)
##   ["tapstick"]  tocar el joystick derecho sin inclinar (GIRO)
##   ["land"]  esperar a aterrizar · ["rebound"] esperar al rebote de rondada/flic-flac
##   ["run", on] joystick izquierdo · ["wait", n]
func seq(name: String, steps: Array, expect: Array) -> void:
	var full := name + " · combo"
	if only != "" and not Array(only.split(",")).any(func(o): return full.contains(o)):
		return
	if _label:
		_label.text = name.to_upper() + "   (joystick derecho / combinación)"
	player.set_spawn(Transform3D(Basis(), SPOT), Vector3.FORWARD)
	player.respawn()
	game.camera.snap()
	player.camera_yaw = 0.0
	await frames(25)
	moves.clear()
	landings.clear()
	phases = {}; kinds = {}; skill_phases = {}; hand_support = false
	max_tuck = 0.0; max_lead = 0.0; max_split = 0.0; max_scissor = 0.0; max_arms = 0.0; max_arch = 0.0
	sampling = true
	var max_rot := 0.0
	var running := false
	var skill_done := {"n": 0}
	var on_move := func(_n, _q, info):
		if info.has("skill"):
			skill_done.n += 1
	player.move_performed.connect(on_move)
	for st in steps:
		match st[0]:
			"run":
				if st[1] and not running:
					joystick(true)
				elif not st[1] and running:
					joystick(false)
				running = st[1]
			"wait":
				await frames(st[1])
			"stick":
				await _stick_push(st[1])
				await frames(st[2])
				_stick_release()
			"tapstick":
				var rc := touch._rot_center()
				_touch(2, rc, true)
				await frames(1)
				_touch(2, rc, false)
			"jumpwheel":
				# Zona de la rueda (salto + mortal, mantenida = agrupado) y GIRO opcional (fotogramas)
				var jc2 := touch._jump_center()
				var wd: Vector2 = st[1]
				var wp := jc2 + Vector2(wd.x, -wd.y).normalized() * touch._jump_radius() * 0.7
				_touch(1, wp, true)
				await frames(8)
				if st.size() > 2:
					var tf: int = st[2]
					await _stick_push(Vector2(signf(tf), 0))
					await frames(absi(tf) - 3)
					_stick_release()
				await frames(12)
				_touch(1, wp, false)
			"jumpstick":
				var jc := touch._jump_center()
				_touch(1, jc, true)
				await frames(2)
				_touch(1, jc, false)
				await _stick_push(st[1])
				if st.size() > 2:
					await frames(5)
					await _stick_center()
					await _stick_push(st[2])
				await frames(8)
				_stick_release()
			"land", "rebound":
				# Espera a terminar el movimiento en curso (acrobacia aérea o habilidad de suelo);
				# "rebound" = hasta que se abre la ventana de enlace de la habilidad
				var busy := player.state in [PlayerController.State.AIR, PlayerController.State.SKILL]
				for i in 240:
					await frames(1)
					var tr := player.tricks
					for ax in ["pitch", "roll", "spin", "twist"]:
						max_rot = maxf(max_rot, absf(tr.total[ax]))
					if player.state in [PlayerController.State.AIR, PlayerController.State.SKILL]:
						busy = true
					if st[0] == "rebound" and player.state == PlayerController.State.SKILL and player.skill.get("linked", false):
						break
					if busy and player.state not in [PlayerController.State.AIR, PlayerController.State.SKILL]:
						break
	if running:
		joystick(false)
	sampling = false
	await frames(10)
	var tag := "[%s] " % name
	# Orden de los movimientos esperados en lo que se ha registrado
	var idx := 0
	for m in moves:
		if idx < expect.size():
			var e: String = expect[idx]
			if m == e or (e == "@back" and m in ["Backflip", "Gainer"]):
				idx += 1
	check(tag + "se ejecuta y se reconoce en orden: " + " → ".join(expect), idx == expect.size(), str(moves))
	player.move_performed.disconnect(on_move)
	# Recepciones: las aéreas limpias; las habilidades de suelo cuentan al recibir con los pies
	var clean: bool = landings.size() + int(skill_done.n) >= expect.size() and landings.all(func(l): return l.quality in ["perfect", "clean"])
	check(tag + "todas las recepciones limpias y enlazadas", clean, str(landings.map(func(l): return l.quality)))
	var shape_ok := true
	var shape_txt := ""
	match name:
		"Cartwheel":
			shape_ok = max_split > 1.5 and max_arms > 2.7; shape_txt = "manos al suelo y piernas en straddle %.2f/%.2f" % [max_arms, max_split]
		"Round-off":
			shape_ok = max_arms > 2.7 and kinds.has("roundoff") and hand_support; shape_txt = "apoyo de manos y piernas juntas %.2f" % max_arms
		"Back Handspring":
			shape_ok = max_arch > 0.6 and max_arms > 2.7; shape_txt = "cuerpo arqueado, brazos atrás-arriba %.2f/%.2f" % [max_arch, max_arms]
		"Front Handspring":
			shape_ok = max_arch > 0.35 and max_arms > 2.7; shape_txt = "vuelo extendido sobre las manos %.2f/%.2f" % [max_arch, max_arms]
		"Butterfly Kick (suelo)":
			shape_ok = max_scissor > 1.2; shape_txt = "patada de tijera %.2f" % max_scissor
	if shape_txt != "":
		check(tag + "forma corporal: " + shape_txt.split(" %")[0], shape_ok, shape_txt + " " + str(kinds.keys()))
		if skill_phases.size() > 0:
			check(tag + "fases con nombre visibles (%d) y apoyo real de manos" % skill_phases.size(),
				skill_phases.size() >= 5 and hand_support, str(skill_phases.keys()))
		else:
			var ph_ok := phases.has("impulso") and (phases.has("agrupado") or phases.has("agrupando")) and phases.has("apertura")
			check(tag + "fases visibles: impulso, forma, apertura", ph_ok, str(phases.keys()))
	check(tag + "termina de pie y con control", player.state in [PlayerController.State.GROUND, PlayerController.State.ROLL], PlayerController.STATE_NAMES[player.state])
	await frames(15)

# ------------------------------------------------------------------ truco

func trick(name: String, swipes: Array, running: bool, hold: String) -> void:
	var full := name + (" · joystick" if hold.begins_with("stick") else " · gesto")
	if only != "" and not Array(only.split(",")).any(func(o): return full.contains(o)):
		return
	if _label:
		_label.text = name.to_upper() + ("   (SALTO + joystick derecho)" if hold.begins_with("stick") else "   (SALTO + deslizar)")
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
	phases = {}; kinds = {}
	max_tuck = 0.0; max_lead = 0.0; max_split = 0.0; max_scissor = 0.0
	sampling = true
	var jc := touch._jump_center()
	var stick := hold.begins_with("stick")
	_touch(1, jc, true)                                   # pulsa SALTO
	await frames(1)
	var y0 := player.global_position.y
	var pos := jc
	# Desliza el mismo dedo (primer gesto)
	var d0: Vector2 = swipes[0]
	var twist_frames := 0
	if stick:
		# El dedo de SALTO se había apoyado en el centro: lo levanta y pulsa la zona de la rueda
		_touch(1, jc, false)
		pos = jc + Vector2(d0.x, -d0.y).normalized() * touch._jump_radius() * 0.7
		_touch(1, pos, true)                               # salta + mortal; mantener = agrupado
		for si in range(1, swipes.size()):
			if swipes[si] is int:
				twist_frames = swipes[si]
	elif d0 == Vector2.ZERO:
		_touch(1, pos, false)                             # salto sin truco; el giro llega con otro toque
		await frames(8)
		_touch(3, jc, true)
		await frames(1)
		_touch(3, jc, false)
	else:
		for k in 4:
			var step := Vector2(d0.x, -d0.y).normalized() * 18.0 * touch._s()
			pos += step
			_drag(1, pos, step)
			await frames(1)
	# Doble joystick: GIRO y zonas extra de la rueda se programan dentro del bucle de vuelo
	var extra_wedges: Array = []
	if stick:
		for si in range(1, swipes.size()):
			if swipes[si] is Vector2:
				extra_wedges.append(swipes[si])
	# Gestos adicionales con el mismo dedo (tirabuzón)
	for si in range(1 if not stick else swipes.size(), swipes.size()):
		await frames(6)
		var dv: Vector2 = swipes[si]
		if dv == Vector2.ZERO:
			_touch(3, jc, true)                           # segundo toque de SALTO (otro dedo)
			await frames(1)
			_touch(3, jc, false)
			continue
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
	if hold == "tap":
		_touch(1, pos, false)
	var need_rot := TAU * (2.0 if name.begins_with("Double") else 1.0) - deg_to_rad(10)
	var left_ground := false
	for i in 150:
		if stick:
			if twist_frames != 0 and i == 8:
				var rc := touch._rot_center()
				var tgt := rc + Vector2(signf(twist_frames), 0) * touch._rot_travel()
				_touch(2, rc, true)
				_drag(2, tgt, tgt - rc)
				stick_pos = tgt
			if twist_frames != 0 and i == 8 + absi(twist_frames):
				_stick_release()
			for wi in extra_wedges.size():
				var wv: Vector2 = extra_wedges[wi]
				var wp: Vector2 = jc + Vector2(wv.x, -wv.y).normalized() * touch._jump_radius() * 0.7
				if i == 18 + wi * 12:
					_touch(4, wp, true)
				if i == 20 + wi * 12:
					_touch(4, wp, false)
		await frames(1)
		var tr := player.tricks
		var up := tr.basis * Vector3.UP
		if up.dot(Vector3.UP) < -0.5:
			inverted = true
		if absf(up.dot(Vector3.UP)) < 0.45:
			horizontal = true
		max_rot = maxf(max_rot, maxf(absf(tr.total_pitch), maxf(absf(tr.total_roll), absf(tr.total_spin))))
		if name.ends_with("Kick") and not name.begins_with("Butterfly"):
			max_rot = maxf(max_rot, absf(tr.total_twist))
		peak = maxf(peak, player.global_position.y)
		if player.state == PlayerController.State.AIR:
			left_ground = true
		if stick and not released and max_rot > need_rot - deg_to_rad(110):
			_touch(1, pos, false)                         # suelta la rueda: abrirse y aterrizar
			released = true
		if not released and absf(tr.total_pitch) > TAU * 2.0 - deg_to_rad(100):
			_touch(1, pos, false)                         # suelta para preparar el aterrizaje
			released = true
		if stick_pos != Vector2.ZERO and max_rot > need_rot - deg_to_rad(110) and not stick:
			_stick_release()                              # suelta el joystick: abrir y aterrizar
		if left_ground and player.state != PlayerController.State.AIR:
			break
	if not released:
		_touch(1, pos, false)
	if stick_pos != Vector2.ZERO:
		_stick_release()
	sampling = false
	var landed: Dictionary = landings[-1] if landings.size() > 0 else {}
	var q: String = landed.get("quality", "none")
	# Recupera el control y sigue corriendo
	if not running:
		joystick(true)
	await frames(40)
	var recovered := player.state in [PlayerController.State.GROUND, PlayerController.State.ROLL] and player.speed() > 3.0
	joystick(false)
	var tag := "[%s%s] " % [name, " · joystick" if stick else ""]
	check(tag + "despega con impulso (sube > 1 m)", left_ground and peak - y0 > 1.0, "altura %.2f" % (peak - y0))
	check(tag + "rotación completa (%d°)" % int(rad_to_deg(need_rot) + 10), max_rot >= need_rot, "%d°" % int(rad_to_deg(max_rot)))
	if name == "360 Kick":
		check(tag + "gira en vertical (sin ponerse boca abajo)", not inverted, "")
	elif name.begins_with("Butterfly"):
		check(tag + "cuerpo en horizontal visible", horizontal, "")
	else:
		check(tag + "pasa boca abajo (visible)", inverted, "")
	var need_phases := ["impulso", "apertura"]
	if name == "360 Kick":
		need_phases = ["apertura"]
	var ph_ok := need_phases.all(func(x): return phases.has(x)) and (phases.has("agrupado") or phases.has("agrupando"))
	check(tag + "fases visibles: impulso, agrupación, apertura", ph_ok, str(phases.keys()))
	var shape_ok := false
	var shape_txt := ""
	match name:
		"Aerial":
			shape_ok = max_split > 1.5; shape_txt = "piernas abiertas en rueda %.2f" % max_split
		"Butterfly Kick":
			shape_ok = max_scissor > 1.2; shape_txt = "patada de tijera %.2f" % max_scissor
		"Sideflip":
			shape_ok = max_tuck > 2.4; shape_txt = "bola cerrada (cadera %.2f rad)" % max_tuck
		"360 Kick":
			shape_ok = max_split > 0.7 and kinds.has("kick"); shape_txt = "patada abierta en el giro %.2f" % max_split
		"Back Full", "Gainer Full":
			shape_ok = max_tuck > 0.9; shape_txt = "semiagrupado con brazos cerrados %.2f" % max_tuck
		"Gainer":
			shape_ok = max_lead > 2.2 and max_tuck > 1.5; shape_txt = "agrupado a una pierna %.2f/%.2f" % [max_lead, max_tuck]
		"Webster":
			shape_ok = max_lead > 2.2 and max_scissor > 1.0; shape_txt = "agrupado en tijera %.2f/%.2f" % [max_lead, max_scissor]
		"Cork", "Cork 720", "Double Cork", "Cheat Gainer", "Front Full", "Back Half", "Backflip Hyper":
			shape_ok = max_tuck > 0.9; shape_txt = "semiagrupado con brazos cerrados %.2f" % max_tuck
		_:
			shape_ok = max_tuck > 1.8; shape_txt = "agrupado real (cadera %.2f rad)" % max_tuck
	check(tag + "forma corporal: " + shape_txt.split(" %")[0].split(" (")[0], shape_ok, shape_txt + " " + str(kinds.keys()))
	check(tag + "aterriza limpio y orientado", q in ["perfect", "clean"], "%s error %.0f°" % [q, landed.get("error", -1.0)])
	check(tag + "reconocido como " + name, name in moves, str(moves))
	check(tag + "recupera el control y sigue corriendo", recovered, "%s %.1f m/s" % [PlayerController.STATE_NAMES[player.state], player.speed()])
	if running:
		check(tag + "conserva impulso de la carrera", speed_before > 6.0, "%.1f" % speed_before)
	await frames(15)
