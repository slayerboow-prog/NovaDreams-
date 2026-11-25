extends Node
## Pruebas automáticas de gameplay. Ejecutar:
##   godot --headless --fixed-fps 60 res://tests/test_runner.tscn
## Un bot controla al personaje a través del mismo InputIntent que usan los controles
## reales, en el escenario real, y comprueba que cada mecánica funciona.

var game: Node
var player: PlayerController
var moves: Array[String] = []
var landings: Array = []
var bails: Array = []
var waters: Array = []
var results: Array = []
var _script: Callable
var _f := 0

func _ready() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.start_mode("freerun")
	player = game.player
	game.camera.set_process(false)
	player.camera_yaw = 0.0
	game.router.scripted = _drive
	Settings.trick_controls = 0             # las pruebas de doble joystick lo necesitan; la botonera se prueba aparte
	player.move_performed.connect(func(n, _q, _i): moves.append(n))
	player.landed.connect(func(r): landings.append(r))
	player.bailed.connect(func(r): bails.append(r))
	player.entered_water.connect(func(r): waters.append(r))
	await _run_all()
	var failed := 0
	print("\n================ RESULTADOS ================")
	for r in results:
		print(("  OK   " if r[1] else "  FAIL ") + r[0] + ("" if r[1] else "   -> " + r[2]))
		if not r[1]:
			failed += 1
	print("%d/%d pruebas superadas" % [results.size() - failed, results.size()])
	get_tree().quit(1 if failed > 0 else 0)

func _drive(intent: InputIntent, _frame: int) -> void:
	intent.move = Vector2.ZERO
	intent.sprint = false
	intent.jump_held = false
	intent.tuck = false
	intent.action_held = false
	intent.rot = Vector2.ZERO             # como el táctil: soltar el joystick lo devuelve al centro
	intent.twist = 0.0
	intent.stick_twist = false            # cada prueba de doble joystick lo activa explícitamente
	if _script.is_valid():
		_script.call(intent, _f)
	_f += 1

func check(name: String, ok: bool, detail := "") -> void:
	results.append([name, ok, detail])
	print(("[OK]   " if ok else "[FAIL] ") + name + ("" if ok else "  " + detail))

func place(pos: Vector3, facing: Vector3, assist := 2) -> void:
	Settings.rotation_assist = assist
	_script = Callable()
	player.set_spawn(Transform3D(Basis(), pos), facing)
	player.respawn()
	player.camera_yaw = atan2(-facing.x, -facing.z)
	moves.clear(); landings.clear(); bails.clear(); waters.clear()
	await frames(20)
	moves.clear(); landings.clear()

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

## Ejecuta un guion de entrada hasta que cond() sea cierta o pasen max_frames.
func run(script: Callable, max_frames: int, cond := Callable()) -> int:
	_f = 0
	_script = script
	for i in max_frames:
		await get_tree().physics_frame
		if cond.is_valid() and cond.call():
			_script = Callable()
			return i
	_script = Callable()
	return max_frames

func S(): return PlayerController.State

# ------------------------------------------------------------------ pruebas

func _run_all() -> void:
	await t_locomotion()
	await t_jump()
	await t_backflip()
	await t_frontflip_cork()
	await t_tuck_grab()
	await t_skin_body()
	await t_twist_wrap()
	await t_ground_flick_buffer()
	await t_overrotation_crash()
	await t_speed_vault()
	await t_kong_vault()
	await t_wall_run()
	await t_ledge_climb()
	await t_drop_hard_vs_roll()
	await t_reference_landings()
	await t_precision()
	await t_water()
	await t_touch()
	await t_dual_stick()
	await t_new_controls()
	await t_wheel_twist()
	await t_wheel_no_twist()
	await t_touch_layout()
	await t_ring_buttons()
	await t_salto_giro_sticks()
	await t_gesture_patterns()
	await t_human_model()
	await t_air_control()
	await t_one_foot_replay_cameras()
	await t_twist_layout_tuck()
	await t_chutada()
	await t_mocap_backflip()
	await t_landing_feel()
	await t_new_tricks()
	await t_gestures()
	await t_ground_skills()
	await t_chains()
	await t_cork_piru()
	await t_vault_variants()
	await t_vault_hands()
	await t_combo_logic()
	await t_flow()
	await t_camera()
	await t_spanish_names()
	await t_glyphs()
	await t_respawn_repeat()
	await t_modes()

func t_locomotion() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var st := {"max": 0.0, "early": 0.0}
	await run(func(i, f):
		i.move = Vector2(0, 1); i.sprint = true
		if f == 30: st.early = player.speed()
		st.max = maxf(st.max, player.speed()), 110)
	check("Carrera: velocidad acumulada (a 0,5 s aún no es sprint completo)", st.early > 5.5 and st.early < 8.6, "vel 0,5 s %.2f" % st.early)
	check("Carrera: alcanza sprint corriendo recto", st.max > 9.0 and player.momentum > 0.95, "vel max %.2f momentum %.2f" % [st.max, player.momentum])
	check("Carrera: sigue en el suelo", player.state == PlayerController.State.GROUND, PlayerController.STATE_NAMES[player.state])
	await run(func(i, f): i.move = Vector2(0, 0.6), 40)
	check("Carrera: desacelera a trote", player.speed() < 6.0 and player.speed() > 3.5, "vel %.2f" % player.speed())
	var f0 := player.facing
	await run(func(i, f): i.move = Vector2(1, 0), 40)
	check("Giro: cambia orientación", f0.angle_to(player.facing) > 1.0, "ángulo %.2f" % f0.angle_to(player.facing))
	await run(func(i, f): pass, 40)
	check("Frenado: se detiene", player.speed() < 0.2, "vel %.2f" % player.speed())
	check("Frenado: pierde la carrera acumulada", player.momentum < 0.3, "momentum %.2f" % player.momentum)
	# Desde parado hacia atrás: gira sobre sí mismo antes de acelerar (no sale disparado de espaldas)
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var pv := {"spd": 0.0, "ang": 0.0}
	await run(func(i, f):
		i.move = Vector2(0, -1)
		if f == 7:
			pv.spd = player.speed(); pv.ang = player.facing.angle_to(Vector3.BACK), 30)
	check("Giro sobre sí mismo: primero se orienta y luego acelera", pv.spd < 2.0 and player.facing.angle_to(Vector3.BACK) < 0.3 and player.speed() > 4.0,
		"a 0,12 s vel %.2f ang %.2f · final vel %.2f" % [pv.spd, pv.ang, player.speed()])

func t_jump() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var y0 := player.global_position.y
	var st := {"peak": y0, "left": false}
	var n := await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = true
		st.peak = maxf(st.peak, player.global_position.y)
		st.left = st.left or player.state == PlayerController.State.AIR, 120,
		func(): return st.left and player.state == PlayerController.State.GROUND)
	var peak: float = st.peak
	var left: bool = st.left
	check("Salto: despega y aterriza", left and player.state == PlayerController.State.GROUND, "estado %s" % PlayerController.STATE_NAMES[player.state])
	check("Salto: altura ~1.2-1.8 m", peak - y0 > 1.2 and peak - y0 < 1.8, "altura %.2f" % (peak - y0))
	check("Salto: aterrizaje registrado limpio", landings.size() > 0 and landings[-1].quality == "perfect", str(landings))
	check("Salto: tiempo de vuelo razonable", n > 30 and n < 60, "frames %d" % n)

func t_backflip() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = true
		i.flick = Vector2(0, -1) if f == 3 else Vector2.ZERO
		i.tuck = f >= 3 and f < 10, 120,
		func(): return player.state == PlayerController.State.GROUND and _f > 16)
	check("Backflip: reconocido", "Backflip" in moves, str(moves))
	check("Backflip: aterrizaje no fallido", landings.size() > 0 and landings[-1].quality != "crash", str(landings.map(func(l): return l.quality)))
	# Desde carrera = Gainer
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.move = Vector2(0, 1)
		i.jump_pressed = f == 30
		i.jump_held = f >= 30
		i.flick = Vector2(0, -1) if f == 33 else Vector2.ZERO, 140,
		func(): return _f > 40 and player.state == PlayerController.State.GROUND)
	check("Gainer: backflip en carrera", "Gainer" in moves, str(moves))

func t_frontflip_cork() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = true
		i.flick = Vector2(0, 1) if f == 2 else Vector2.ZERO, 120,
		func(): return player.state == PlayerController.State.GROUND and _f > 16)
	check("Frontflip: reconocido", "Frontflip" in moves, str(moves))
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.move = Vector2(0, 1); i.sprint = true
		i.jump_pressed = f == 30
		i.jump_held = f >= 30
		i.flick = Vector2(0.7, -0.7) if f == 32 else Vector2.ZERO
		i.tuck = f >= 32 and f < 40, 160,
		func(): return _f > 40 and player.state == PlayerController.State.GROUND)
	check("Cork: backflip + tirabuzón (gesto diagonal)", "Cork" in moves, str(moves) + " " + str(landings.map(func(l): return [l.quality, int(l.error)])))
	# Mortal lateral
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = true
		i.flick = Vector2(1, 0) if f == 2 else Vector2.ZERO, 120,
		func(): return player.state == PlayerController.State.GROUND and _f > 16)
	check("Sideflip: reconocido", "Sideflip" in moves, str(moves))

func t_ground_flick_buffer() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f): i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO, 30)
	check("Gesto en suelo sin salto: no salta (es cámara)", player.state == PlayerController.State.GROUND and moves.is_empty(),
		PlayerController.STATE_NAMES[player.state])
	await run(func(i, f):
		i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.jump_pressed = f == 8
		i.jump_held = f >= 8, 120,
		func(): return _f > 24 and player.state == PlayerController.State.GROUND)
	check("Gesto y salto en <0,25 s: backflip desde el despegue", "Backflip" in moves, str(moves))
	var fb: Feedback = game.get_node("Feedback")
	check("Audio: efectos sintetizados", fb.sounds.size() >= 9 and fb.sounds.step.data.size() > 1000, str(fb.sounds.keys()))

func t_overrotation_crash() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD, 0)  # modo Pro
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = true
		i.flick = Vector2(0, -1) if f == 2 else Vector2.ZERO
		i.tuck = f >= 2, 200,
		func(): return player.state == PlayerController.State.CRASH or (player.state == PlayerController.State.GROUND and _f > 16))
	check("Pro: girar de más penaliza (forzado o caída)", landings.size() > 0 and landings[-1].quality in ["sloppy", "crash"],
		"estado %s, landings %s" % [PlayerController.STATE_NAMES[player.state], str(landings.map(func(l): return [l.quality, int(l.error)]))])
	await run(func(i, f): pass, 120, func(): return player.state == PlayerController.State.GROUND)
	check("Caída: se levanta y recupera control", player.state == PlayerController.State.GROUND, PlayerController.STATE_NAMES[player.state])
	# Pro: soltar a tiempo = aterrizaje correcto
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD, 0)
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = true
		i.flick = Vector2(0, -1) if f == 2 else Vector2.ZERO
		i.tuck = f >= 2 and player.tricks.total_pitch < deg_to_rad(250), 200,
		func(): return player.state == PlayerController.State.CRASH or (player.state == PlayerController.State.GROUND and _f > 16))
	check("Pro: abrir a tiempo aterriza el backflip", "Backflip" in moves, str(moves) + str(landings.map(func(l): return [l.quality, int(l.error)])))

func _run_at_obstacle(start: Vector3, stick: float, sprint: bool, jump_z: float) -> void:
	await place(start, Vector3.FORWARD)
	var st := {"pressed": false}
	await run(func(i, f):
		i.move = Vector2(0, stick); i.sprint = sprint
		i.jump_pressed = not st.pressed and player.global_position.z <= jump_z
		st.pressed = st.pressed or i.jump_pressed, 200,
		func(): return st.pressed and _f > 16 and player.state == PlayerController.State.GROUND)

func t_speed_vault() -> void:
	await _run_at_obstacle(Vector3(0, 0.1, 2), 0.8, false, -4.85)
	check("Speed Vault: reconocido", "Speed Vault" in moves or "Step Vault" in moves, str(moves))
	check("Speed Vault: supera el muro", player.global_position.z < -6.5, "z %.2f" % player.global_position.z)
	check("Speed Vault: conserva velocidad", player.speed() > 4.5, "vel %.2f" % player.speed())

func t_kong_vault() -> void:
	await _run_at_obstacle(Vector3(0, 0.1, -8), 1.0, true, -12.9)
	check("Kong Vault: reconocido", "Kong Vault" in moves, str(moves))
	check("Kong Vault: supera la caja", player.global_position.z < -15.0, "z %.2f" % player.global_position.z)
	check("Kong Vault: conserva sprint", player.speed() > 7.0, "vel %.2f" % player.speed())
	check("Kong Vault: pasa el obstáculo (no se sube encima)", "Kong Vault" in moves and player.global_position.y < 0.3, "y %.2f %s" % [player.global_position.y, moves])
	# Obstáculo muy largo (solo para la prueba): el kong termina de pie encima
	var long_box := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = Vector3(2.0, 1.0, 4.0)
	col.shape = bs
	long_box.add_child(col)
	long_box.position = Vector3(-35, 0.5, 20)
	game.add_child(long_box)
	await frames(2)
	for mode in ["suelo", "plancha"]:
		await place(Vector3(-35, 0.1, 32), Vector3.FORWARD)
		var lb := {"p": false, "air": false, "kind": ""}
		await run(func(i, f):
			i.move = Vector2(0, 1.0); i.sprint = true
			i.jump_pressed = not lb.p and player.global_position.z <= (22.9 if mode == "suelo" else 25.0)
			lb.p = lb.p or i.jump_pressed
			if player.state == PlayerController.State.VAULT:
				lb.kind = player.vault.kind
			lb.air = lb.air or player.state != PlayerController.State.GROUND
			i.jump_held = true, 200,
			func(): return lb.air and player.state == PlayerController.State.GROUND and player.land_timer > 0.1 or (lb.kind != "" and player.state == PlayerController.State.GROUND and _f > 60))
		check("Obstáculo muy largo (%s): kong y queda de pie encima" % mode, lb.kind == "Kong Up" and player.global_position.y > 0.9,
			"%s y %.2f %s" % [lb.kind, player.global_position.y, moves])
	long_box.queue_free()
	await frames(2)
	# Kong → mortal atrás antes de caer: ATRÁS durante el kong = empuje de brazos y mortal
	await place(Vector3(0, 0.1, -8), Vector3.FORWARD)
	var kb := {"p": false}
	await run(func(i, f):
		i.move = Vector2(0, 1.0); i.sprint = true
		i.jump_pressed = not kb.p and player.global_position.z <= -12.9
		kb.p = kb.p or i.jump_pressed
		i.flick = Vector2(0, -1) if player.state == PlayerController.State.VAULT and player.state_time > 0.1 and player.state_time < 0.13 else Vector2.ZERO
		i.tuck = player.state == PlayerController.State.AIR and absf(player.tricks.total_pitch) < 4.5; i.jump_held = i.tuck, 240,
		func(): return kb.p and _f > 30 and player.state == PlayerController.State.GROUND)
	check("Kong → mortal atrás antes de caer", "Kong Vault" in moves and moves.size() >= 2 and landings.size() > 0 and landings[-1].quality in ["perfect", "clean"],
		"%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Dive Kong: saltar lejos del obstáculo; las manos llegan si la distancia y la altura dan
	var dives: Array[float] = []
	for jz in [-10.3, -7.6]:
		await place(Vector3(0, 0.1, -7.0), Vector3.FORWARD)
		var dk := {"p": false}
		await run(func(i, f):
			i.move = Vector2(0, 1.0); i.sprint = true
			i.jump_pressed = not dk.p and player.global_position.z <= jz
			dk.p = dk.p or i.jump_pressed
			dk.air = dk.get("air", false) or player.state != PlayerController.State.GROUND
			i.jump_held = true, 240,
			func(): return dk.get("air", false) and player.state == PlayerController.State.GROUND)
		check("Dive Kong: salta lejos del obstáculo, llega y pasa (%.1f m del muro)" % player.last_dive_kong,
			"Dive Kong" in moves and player.global_position.z < -15.0 and player.last_dive_kong > 2.0, "%s z %.2f d %.2f" % [moves, player.global_position.z, player.last_dive_kong])
		dives.append(player.last_dive_kong)
	check("Dive Kong: saltar desde más lejos = kong más largo (%.1f m → %.1f m)" % [dives[0], dives[1]], dives[1] > dives[0] + 2.0, str(dives))
	# Demasiado lejos: no llega (no hay kong; choca o cae antes del obstáculo)
	await place(Vector3(0, 0.1, -6.2), Vector3.FORWARD)
	var far := {"p": false}
	await run(func(i, f):
		i.move = Vector2(0, 1.0) if not far.p or player.state != PlayerController.State.GROUND else Vector2.ZERO
		i.sprint = true
		i.jump_pressed = not far.p and player.global_position.z <= -6.45
		far.p = far.p or i.jump_pressed
		i.jump_held = true, 200,
		func(): return far.p and _f > 30 and player.state != PlayerController.State.AIR)
	check("Dive Kong demasiado lejos: el personaje no llega", not ("Dive Kong" in moves) and not ("Kong Vault" in moves) and player.global_position.z > -15.0, "%s z %.2f" % [moves, player.global_position.z])

func t_wall_run() -> void:
	await place(Vector3(11.0, 0.1, 3), Vector3.FORWARD)
	var st := {"wr": false, "jumped": false}
	await run(func(i, f):
		i.move = Vector2(0, 1); i.sprint = true
		i.jump_held = f >= 25
		var on_wall := player.state == PlayerController.State.WALLRUN
		st.wr = st.wr or on_wall
		var kick: bool = on_wall and player.state_time > 0.35 and not st.jumped
		st.jumped = st.jumped or kick
		i.jump_pressed = f == 25 or kick, 220,
		func(): return st.jumped and player.state == PlayerController.State.GROUND)
	check("Wall Run: engancha a la pared", "Wall Run" in moves and st.wr, str(moves))
	check("Wall Run: salto de pared", "Wall Jump" in moves, str(moves))
	check("Wall Run: enlaza a la pared opuesta", moves.count("Wall Run") >= 2, str(moves))

func t_ledge_climb() -> void:
	await place(Vector3(0, 0.1, -34.5), Vector3.FORWARD)
	var st := {"climbed": false}
	await run(func(i, f):
		i.move = Vector2(0, 0.8)
		i.jump_pressed = (f == 18) or (player.state == PlayerController.State.HANG and player.state_time > 0.2 and not st.climbed)
		i.jump_held = true
		st.climbed = st.climbed or player.state == PlayerController.State.CLIMB_UP, 260,
		func(): return st.climbed and player.state == PlayerController.State.GROUND)
	var grabbed := "Ledge Grab" in moves or "Cat Leap" in moves or "Wall Climb" in moves
	check("Borde: se agarra o trepa", grabbed, str(moves))
	check("Borde: Climb Up", "Climb Up" in moves or "Mantle" in moves, str(moves))
	check("Borde: termina encima (y≈3)", player.global_position.y > 2.9, "y %.2f" % player.global_position.y)

func t_drop_hard_vs_roll() -> void:
	# Sin rodar desde la torre de 5,6 m: recepción dura
	await place(Vector3(-24.25, 5.75, -10.5), Vector3.FORWARD)
	await run(func(i, f): i.move = Vector2(0, 0.5), 200,
		func(): return landings.size() > 0)
	await frames(2)
	check("Caída 5,6 m sin rodar: recepción dura", "Hard Landing" in moves, str(moves) + str(landings.map(func(l): return [l.quality, l.impact])))
	await place(Vector3(-24.25, 5.75, -10.5), Vector3.FORWARD)
	await run(func(i, f):
		i.move = Vector2(0, 0.5)
		i.action_pressed = player.state == PlayerController.State.AIR and player.global_position.y < 1.2 and player.velocity.y < 0, 200,
		func(): return landings.size() > 0)
	await frames(2)
	check("Caída 5,6 m rodando: Safety Roll", "Safety Roll" in moves and not ("Hard Landing" in moves), str(moves))
	check("Safety Roll: conserva movimiento", player.state == PlayerController.State.ROLL or player.speed() > 2.0, "%s %.2f" % [PlayerController.STATE_NAMES[player.state], player.speed()])

func t_precision() -> void:
	await place(Vector3(0, 3.1, -44.5), Vector3.FORWARD)
	var st := {"jumped": false}
	await run(func(i, f):
		i.move = Vector2.ZERO if st.jumped else Vector2(0, 0.47)
		i.jump_pressed = not st.jumped and player.global_position.z <= -45.95
		st.jumped = st.jumped or i.jump_pressed
		st.air = st.get("air", false) or player.state == PlayerController.State.AIR
		i.jump_held = st.jumped, 200,
		func(): return st.get("air", false) and player.state != PlayerController.State.AIR)
	check("Precisión: aterriza en la viga", player.global_position.y > 2.6 and absf(player.global_position.z + 49.6) < 0.3,
		"pos %s" % str(player.global_position))
	check("Precisión: Precision Jump reconocido", "Precision Jump" in moves, str(moves))

func t_water() -> void:
	game.start_mode("water")
	player.camera_yaw = PI
	await place(Vector3(22, 3.1, 8.8), Vector3.BACK)
	var st := {"jumped": false}
	await run(func(i, f):
		i.move = Vector2.ZERO if st.jumped else Vector2(0, 0.7)
		i.jump_pressed = not st.jumped and player.global_position.z >= 11.0
		st.jumped = st.jumped or i.jump_pressed
		i.jump_held = st.jumped
		var go: bool = st.jumped and player.state == PlayerController.State.AIR and player.tricks.flicks == 0 and player.state_time > 0.05
		i.flick = Vector2(0, 1) if go else Vector2.ZERO, 240,
		func(): return waters.size() > 0)
	check("Agua: entra en la piscina", waters.size() > 0, "pos %s" % str(player.global_position))
	if waters.size() > 0:
		check("Agua: valora la entrada", waters[0].has("quality") and waters[0].trick.get("name", "") != "",
			str(waters[0]))
	game.start_mode("freerun")
	game.camera.set_process(false)

func t_touch() -> void:
	var touch: TouchControls = game.ui.touch
	var old_mode := Settings.trick_controls
	Settings.trick_controls = 1                     # modo gestos (la zona libre lanza trucos en el aire)
	touch.visible = true
	touch.size = Vector2(1280, 720)
	var jc := touch._jump_center()
	var ev := InputEventScreenTouch.new()
	ev.index = 0; ev.position = jc; ev.pressed = true
	touch._on_touch(ev)
	var fr := touch.collect()
	check("Táctil: botón de salto", fr.jump_pressed and fr.jump_held, "")
	ev.pressed = false
	touch._on_touch(ev)
	# Swipe rápido hacia abajo en la zona de gestos = backflip
	var g := InputEventScreenTouch.new()
	g.index = 1; g.position = Vector2(900, 250); g.pressed = true
	touch._on_touch(g)
	var d := InputEventScreenDrag.new()
	d.index = 1; d.position = Vector2(902, 340); d.relative = Vector2(2, 90)
	touch._on_drag(d)
	fr = touch.collect()
	check("Táctil: swipe abajo = backflip", fr.flick.y < -0.9 and fr.tuck, "flick %s tuck %s" % [fr.flick, fr.tuck])
	var d2 := InputEventScreenDrag.new()
	d2.index = 1; d2.position = Vector2(990, 345); d2.relative = Vector2(88, 5)
	touch._on_drag(d2)
	fr = touch.collect()
	check("Táctil: segundo gesto lateral = tirabuzón", fr.flick.x > 0.9, "flick %s" % fr.flick)
	g.pressed = false
	touch._on_touch(g)
	check("Táctil: soltar dedo = abrir (sin tuck)", not touch.collect().tuck, "")
	# Joystick
	var j := InputEventScreenTouch.new()
	j.index = 2; j.position = Vector2(200, 500); j.pressed = true
	touch._on_touch(j)
	var jd := InputEventScreenDrag.new()
	jd.index = 2; jd.position = Vector2(200, 400); jd.relative = Vector2(0, -100)
	touch._on_drag(jd)
	fr = touch.collect()
	check("Táctil: joystick adelante", fr.move.y > 0.9, "move %s" % fr.move)
	j.pressed = false
	touch._on_touch(j)
	# Arrastre lento = cámara
	var c := InputEventScreenTouch.new()
	c.index = 3; c.position = Vector2(800, 300); c.pressed = true
	touch._on_touch(c)
	touch._time += 0.3
	var cd := InputEventScreenDrag.new()
	cd.index = 3; cd.position = Vector2(830, 300); cd.relative = Vector2(30, 0)
	touch._on_drag(cd)
	fr = touch.collect()
	check("Táctil: arrastre lento = cámara", fr.camera_delta.x > 0.0 and fr.flick == Vector2.ZERO, "cam %s" % fr.camera_delta)
	c.pressed = false
	touch._on_touch(c)
	touch.visible = false
	Settings.trick_controls = old_mode

## Doble joystick: los dos pulgares a la vez, joystick derecho analógico, AGRUPAR y GIRO.
func t_dual_stick() -> void:
	var touch: TouchControls = game.ui.touch
	var old_mode := Settings.trick_controls
	Settings.trick_controls = 0
	touch.visible = true
	touch.size = Vector2(1560, 720)
	touch.collect()
	var tch := func(idx: int, pos: Vector2, pressed: bool) -> void:
		var e := InputEventScreenTouch.new()
		e.index = idx; e.position = pos; e.pressed = pressed
		touch._on_touch(e)
	var drg := func(idx: int, pos: Vector2) -> void:
		var e := InputEventScreenDrag.new()
		e.index = idx; e.position = pos; e.relative = Vector2(8, 8)
		touch._on_drag(e)
	var rc := touch._rot_center()
	var trav := touch._rot_travel()
	# Pulgar izquierdo corre, pulgar derecho inclina hacia abajo a la vez
	tch.call(0, Vector2(200, 520), true)
	drg.call(0, Vector2(200, 420))
	tch.call(1, rc, true)
	var fr := touch.collect()
	check("Doble joystick: tocar el joystick derecho no lanza truco", fr.flick == Vector2.ZERO and fr.rot == Vector2.ZERO, "flick %s" % fr.flick)
	drg.call(1, rc + Vector2(0, trav * 0.4))
	fr = touch.collect()
	var partial := fr.rot.y < -0.3 and fr.rot.y > -0.5 and fr.flick == Vector2.ZERO
	drg.call(1, rc + Vector2(0, trav))
	fr = touch.collect()
	check("Joystick GIRO: analógico y nunca lanza un mortal (solo aviso de suelo)", partial and fr.flick == Vector2.ZERO and fr.rot_flick.y < -0.9 and fr.rot.y < -0.95, "rot %s flick %s rot_flick %s" % [fr.rot, fr.flick, fr.rot_flick])
	check("Doble joystick: multitáctil (mover y rotar a la vez)", fr.move.y > 0.9 and fr.rot.length() > 0.9, "move %s rot %s" % [fr.move, fr.rot])
	# Mantener inclinado no repite el truco; deslizar a un lado sí (tirabuzón)
	drg.call(1, rc + Vector2(0, trav * 1.02))
	fr = touch.collect()
	var no_repeat := fr.flick == Vector2.ZERO
	drg.call(1, rc + Vector2(trav, 0))
	touch._time += 0.1
	drg.call(1, rc + Vector2(trav * 1.01, 0))
	fr = touch.collect()
	check("Joystick GIRO: mantener no repite; cambiar de dirección avisa (suelo)", no_repeat and fr.rot_flick.x > 0.9 and fr.flick == Vector2.ZERO, "rot_flick %s" % fr.rot_flick)
	# Volver al centro e inclinar otra vez = otra vuelta
	drg.call(1, rc + Vector2(0, trav * 0.1))
	drg.call(1, rc + Vector2(0, trav))
	fr = touch.collect()
	check("Joystick GIRO: volver a inclinar avisa otra vez", fr.rot_flick.y < -0.9, "rot_flick %s" % fr.rot_flick)
	tch.call(1, rc + Vector2(0, trav), false)
	fr = touch.collect()
	check("Doble joystick: soltar = vuelve al centro (abrir)", fr.rot == Vector2.ZERO and fr.move.y > 0.9, "rot %s" % fr.rot)
	# Toque sin inclinar = GIRO
	tch.call(1, rc, true)
	tch.call(1, rc, false)
	fr = touch.collect()
	check("Doble joystick: toque = GIRO", fr.kick and fr.flick == Vector2.ZERO, "")
	# Pulgar izquierdo corriendo + VAULT + joystick derecho a la vez; AGARRAR mantenido
	tch.call(2, touch._vault_center(), true)
	tch.call(1, rc, true)
	drg.call(1, rc + Vector2(0, -trav))
	fr = touch.collect()
	check("Botones: VAULT + joystick derecho + correr a la vez", fr.vault_pressed and fr.rot.y > 0.9 and fr.move.y > 0.9, "vault %s rot %s move %s" % [fr.vault_pressed, fr.rot, fr.move])
	tch.call(2, touch._vault_center(), false)
	tch.call(5, touch._grab_center(), true)
	fr = touch.collect()
	check("Botones: AGARRAR (pulsar y mantener) a la vez que el joystick derecho", fr.grab_pressed and fr.grab_held and fr.rot.y > 0.9, "")
	tch.call(5, touch._grab_center(), false)
	tch.call(1, rc, false)
	tch.call(0, Vector2(200, 420), false)
	tch.call(6, touch._action_center(), true)
	fr = touch.collect()
	check("Botones: RODAR", fr.action_pressed, "")
	tch.call(6, touch._action_center(), false)
	# Rueda SALTO / MORTALES: centro = SALTO; zonas = salto + mortal; mantener = agrupado
	var jc := touch._jump_center()
	var jr := touch._jump_radius()
	tch.call(7, jc, true)
	fr = touch.collect()
	check("Rueda: centro = SALTO sin mortal", fr.jump_pressed and fr.flick == Vector2.ZERO, "")
	tch.call(7, jc, false)
	var wheel_ok := true
	for w in [[Vector2(0, jr * 0.7), Vector2(0, -1)], [Vector2(0, -jr * 0.7), Vector2(0, 1)], [Vector2(jr * 0.7, 0), Vector2(1, 0)], [Vector2(-jr * 0.7, 0), Vector2(-1, 0)]]:
		tch.call(8, jc + w[0], true)
		fr = touch.collect()
		wheel_ok = wheel_ok and fr.jump_pressed and fr.flick.distance_to(w[1]) < 0.05 and fr.tuck
		fr = touch.collect()
		wheel_ok = wheel_ok and fr.tuck and fr.jump_held      # mantener = agrupado
		tch.call(8, jc + w[0], false)
		fr = touch.collect()
		wheel_ok = wheel_ok and not fr.tuck                  # soltar = abrirse
	check("Rueda: ATRÁS/ADELANTE/LATERAL saltan con su mortal, mantener agrupa, soltar abre", wheel_ok, "")
	touch.air_mode = true
	tch.call(8, jc + Vector2(0, jr * 0.7), true)
	fr = touch.collect()
	touch.air_mode = false
	tch.call(8, jc + Vector2(0, jr * 0.7), false)
	touch.collect()
	check("Rueda: en el aire suma el mortal sin volver a saltar", fr.flick.y < -0.9 and not fr.jump_pressed, "")
	# Zona libre en modo joystick = solo cámara (ni rápido ni en el aire lanza trucos)
	touch.air_mode = true
	tch.call(3, Vector2(820, 250), true)
	drg.call(3, Vector2(900, 330))
	fr = touch.collect()
	touch.air_mode = false
	check("Doble joystick: arrastrar fuera de los controles = cámara, nunca truco", fr.flick == Vector2.ZERO and fr.camera_delta.length() > 0.0, "cam %s flick %s" % [fr.camera_delta, fr.flick])
	tch.call(3, Vector2(900, 330), false)
	touch.collect()
	touch.visible = false
	Settings.trick_controls = old_mode
	# En el juego: joystick derecho controla la intensidad (más inclinado = gira más rápido)
	var rates := []
	for amount in [0.0, 1.0]:
		await place(Vector3(0, 0.1, 6), Vector3.FORWARD)
		await run(func(i, f):
			i.jump_pressed = f == 0
			i.jump_held = f < 3
			i.flick = Vector2(0, -1) if f == 6 else Vector2.ZERO
			i.rot = Vector2(0, -amount) if f >= 6 else Vector2.ZERO, 22)
		rates.append(absf(player.tricks.pitch_rate))
	check("Doble joystick: inclinar a fondo gira más rápido que soltar", rates[1] > rates[0] * 1.15, "%.1f vs %.1f rad/s" % [rates[1], rates[0]])
	# Tirar en contra frena
	await place(Vector3(0, 0.1, 6), Vector3.FORWARD)
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = f < 3
		i.flick = Vector2(0, -1) if f == 6 else Vector2.ZERO
		i.rot = Vector2(0, 1) if f >= 9 else Vector2.ZERO, 22)
	check("Doble joystick: tirar en contra frena el giro", absf(player.tricks.pitch_rate) < rates[0], "%.1f rad/s" % absf(player.tricks.pitch_rate))
	await run(func(i, f): i.rot = Vector2.ZERO, 90, func(): return player.state != PlayerController.State.AIR)

## Rueda de mortales + joystick GIRO (doble joystick): un solo joystick para los giros de
## todos los mortales, en cuartos de vuelta; cork; sideflip de lado en carrera.
func t_wheel_twist() -> void:
	# Mortal atrás parado + GIRO durante distintos tiempos → ¼ (Hyper), ½, 1 vuelta
	var res := {}
	for hold in [5, 13, 26]:
		await place(Vector3(-35, 0.1, 30), Vector3.FORWARD)
		await run(func(i, f):
			i.stick_twist = true
			i.jump_pressed = f == 0
			i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
			i.tuck = f < 25
			i.jump_held = f < 25
			i.twist = 1.0 if f >= 14 and f < 14 + hold else 0.0
			if f == 0: i.rot = Vector2.ZERO, 150,
			func(): return _f > 16 and player.state == PlayerController.State.GROUND)
		res[hold] = moves.duplicate()
	check("GIRO: un toque corto = ¼ de giro (Hyper)", "Backflip Hyper" in res[5], str(res[5]))
	check("GIRO: algo más = medio giro (Back Half)", "Back Half" in res[13], str(res[13]))
	check("GIRO: mantenerlo = tirabuzón completo (Piru)", "Piru" in res[26], str(res[26]))
	# El mismo joystick gira cualquier mortal: adelante y lateral
	for fl in [[Vector2(0, 1), "Front Full"], [Vector2(1, 0), "Sideflip Twist"]]:
		await place(Vector3(-35, 0.1, 30), Vector3.FORWARD)
		var flv: Vector2 = fl[0]
		await run(func(i, f):
			i.stick_twist = true
			i.jump_pressed = f == 0
			i.flick = flv if f == 0 else Vector2.ZERO
			i.tuck = f < 25; i.jump_held = f < 25
			i.twist = -1.0 if f >= 12 and f < 38 else 0.0, 150,
			func(): return _f > 16 and player.state == PlayerController.State.GROUND)
		check("GIRO: también en %s" % fl[1], fl[1] in moves, str(moves))
	# Cork: mortal atrás corriendo + vuelta completa de GIRO; Cork 720 con dos vueltas
	for c in [[26, "Piru"], [52, "Piru 720"]]:
		await place(Vector3(-35, 0.1, 40), Vector3.FORWARD)
		var hold: int = c[0]
		var st := {"t0": -1}
		await run(func(i, f):
			i.stick_twist = true
			i.move = Vector2(0, 1)
			var go: bool = f == 50
			i.jump_pressed = go
			i.flick = Vector2(0, -1) if go else Vector2.ZERO
			if go: st.t0 = f
			var since: int = f - st.t0 if st.t0 >= 0 else -1
			i.tuck = since >= 0 and since < 30; i.jump_held = i.tuck
			i.twist = 1.0 if since >= 10 and since < 10 + hold else 0.0
			if since > 20: i.move = Vector2.ZERO, 220,
			func(): return st.t0 >= 0 and _f > st.t0 + 10 and player.state in [PlayerController.State.GROUND, PlayerController.State.ROLL, PlayerController.State.CRASH])
		check("Rueda ATRÁS corriendo + GIRO (suelto) = %s" % c[1], c[1] in moves, str(moves))
	# Cork y rondada ya no se confunden: GIRO inclinado antes de saltar no hace rondada
	await place(Vector3(-35, 0.1, 40), Vector3.FORWARD)
	await run(func(i, f):
		i.stick_twist = true
		i.move = Vector2(0, 1)
		i.rot = Vector2(0.7, -0.7) if f >= 40 else Vector2.ZERO
		i.rot_flick = Vector2(0.7, -0.7) if f == 40 else Vector2.ZERO
		i.twist = i.rot.x
		i.jump_pressed = f == 46
		i.flick = Vector2(0, -1) if f == 46 else Vector2.ZERO
		i.tuck = f >= 46 and f < 76; i.jump_held = i.tuck
		if f > 92: i.rot = Vector2.ZERO; i.twist = 0.0, 220,
		func(): return _f > 60 and player.state in [PlayerController.State.GROUND, PlayerController.State.ROLL, PlayerController.State.CRASH])
	check("GIRO inclinado justo antes de ATRÁS: sale el piru, no la rondada", not "Round-off" in moves and moves.any(func(m): return m.begins_with("Piru")), str(moves))
	# Sideflip corriendo: se pone de lado antes de despegar y avanza girando, mirando al lado
	await place(Vector3(-35, 0.1, 40), Vector3.FORWARD)
	var sd := {"face": Vector3.ZERO, "vel": Vector3.ZERO, "z0": 0.0, "load_turned": false}
	await run(func(i, f):
		i.stick_twist = true
		i.move = Vector2(0, 1)
		i.jump_pressed = f == 50
		i.flick = Vector2(-1, 0) if f == 50 else Vector2.ZERO
		i.tuck = f >= 50 and f < 80; i.jump_held = i.tuck
		if player.jump_load > 0.0 and player.facing.angle_to(Vector3.FORWARD) > 0.6:
			sd.load_turned = true
		if f == 50: sd.z0 = player.global_position.z
		if player.state == PlayerController.State.AIR and player.tricks.air_time > 0.3 and sd.face == Vector3.ZERO:
			sd.face = player.facing; sd.vel = player.horizontal_velocity()
		if f > 60: i.move = Vector2(0, 0.3), 200,
		func(): return _f > 60 and player.state != PlayerController.State.AIR and sd.face != Vector3.ZERO)
	var side_ang := rad_to_deg(sd.face.angle_to(Vector3.FORWARD))
	check("Sideflip en carrera: gira el cuerpo de lado ya en la flexión previa", sd.load_turned, "")
	check("Sideflip en carrera: en el aire mira al lado (~90°) y avanza hacia delante", side_ang > 70.0 and side_ang < 110.0 and sd.vel.z < -3.0,
		"mira %.0f° · vel %s" % [side_ang, sd.vel])
	check("Sideflip en carrera: reconocido y su eje es la carrera (avanza)", "Sideflip" in moves and player.global_position.z < sd.z0 - 3.0, "%s dz %.1f" % [moves, player.global_position.z - sd.z0])

## Controles definitivos: VAULT, AGARRAR, tricking de suelo con el joystick derecho, Kip-up.
func t_new_controls() -> void:
	# VAULT (sin SALTO) supera el obstáculo
	await place(Vector3(0, 0.1, 2), Vector3.FORWARD)
	var st := {"p": false}
	await run(func(i, f):
		i.move = Vector2(0, 0.8)
		i.vault_pressed = not st.p and player.global_position.z <= -4.85
		st.p = st.p or i.vault_pressed, 200,
		func(): return st.p and _f > 16 and player.state == PlayerController.State.GROUND)
	check("VAULT: botón propio supera el obstáculo", ("Speed Vault" in moves or "Step Vault" in moves) and player.global_position.z < -6.5, "%s z %.2f" % [moves, player.global_position.z])
	# VAULT + joystick derecho lateral = Reverse Vault
	await place(Vector3(0, 0.1, -8), Vector3.FORWARD)
	st.p = false
	await run(func(i, f):
		i.move = Vector2(0, 1.0); i.sprint = true
		i.rot = Vector2(1, 0) if player.global_position.z <= -12.0 else Vector2.ZERO
		i.vault_pressed = not st.p and player.global_position.z <= -12.9
		st.p = st.p or i.vault_pressed, 200,
		func(): return st.p and _f > 16 and player.state == PlayerController.State.GROUND)
	check("VAULT + joystick derecho →: Reverse Vault", "Reverse Vault" in moves, str(moves))
	# AGARRAR junto a una pared alta = trepar; colgado del borde, AGARRAR = SOLTAR
	await place(Vector3(0, 0.1, -34.5), Vector3.FORWARD)
	var hung := {"v": false}
	await run(func(i, f):
		i.move = Vector2(0, 0.8) if not hung.v else Vector2.ZERO
		i.grab_pressed = f == 14
		hung.v = hung.v or player.state == PlayerController.State.HANG, 160,
		func(): return hung.v)
	var grabbed := player.state == PlayerController.State.HANG and "Wall Climb" in moves
	await run(func(i, f): i.grab_pressed = f == 20, 40)
	check("AGARRAR: trepa la pared, se agarra al borde y AGARRAR otra vez lo suelta", grabbed and player.state != PlayerController.State.HANG, "%s %s" % [moves, PlayerController.STATE_NAMES[player.state]])
	# Tricking de suelo: ver t_ground_skills (habilidades con apoyo real y enlaces)
	# Sin SALTO y sin mantener el joystick (gesto suelto) no hay movimiento de suelo
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f): i.flick = Vector2(1, 0) if f == 0 else Vector2.ZERO, 40)
	check("Suelo: un gesto suelto no dispara la rueda (hay que inclinar el joystick)", moves.is_empty() and player.state == PlayerController.State.GROUND, str(moves))
	# Kong Vault → Frontflip: VAULT a sprint y joystick derecho ↑ durante el vault
	await place(Vector3(0, 0.1, -8), Vector3.FORWARD)
	st.p = false
	await run(func(i, f):
		i.move = Vector2(0, 1.0); i.sprint = true
		i.vault_pressed = not st.p and player.global_position.z <= -12.9
		st.p = st.p or i.vault_pressed
		i.flick = Vector2(0, 1) if player.state == PlayerController.State.VAULT and player.state_time > 0.1 and player.state_time < 0.13 else Vector2.ZERO, 220,
		func(): return st.p and _f > 30 and player.state == PlayerController.State.GROUND)
	check("Combo Kong Vault → Frontflip (Kong Front)", "Kong Vault" in moves and "Kong Front" in moves, str(moves))
	# Wall Run → Wall Flip: en la pared, joystick derecho ↓
	await place(Vector3(11.0, 0.1, 3), Vector3.FORWARD)
	var wst := {"done": false}
	await run(func(i, f):
		i.move = Vector2(0, 1); i.sprint = true
		i.jump_held = f >= 25
		i.jump_pressed = f == 25
		var go: bool = player.state == PlayerController.State.WALLRUN and player.state_time > 0.3 and not wst.done
		i.flick = Vector2(0, -1) if go else Vector2.ZERO
		wst.done = wst.done or go, 240,
		func(): return wst.done and player.state == PlayerController.State.GROUND)
	check("Combo Wall Run → Wall Flip (joystick ↓ en la pared)", "Wall Run" in moves and ("Wall Flip" in moves or "Wall Gainer" in moves), str(moves))
	# Kip-up tras una caída
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD, 0)
	await run(func(i, f):
		i.jump_pressed = f == 0; i.jump_held = true
		i.flick = Vector2(0, -1) if f == 2 else Vector2.ZERO
		i.tuck = f >= 2, 200, func(): return player.state == PlayerController.State.CRASH)
	var crashed := player.state == PlayerController.State.CRASH
	await run(func(i, f): i.jump_pressed = f == 25, 120, func(): return "Kip-up" in moves)
	check("Kip-up: SALTO tras una caída levanta al personaje", crashed and "Kip-up" in moves, "%s %s" % [crashed, moves])
	await run(func(i, f): pass, 90, func(): return player.state == PlayerController.State.GROUND)

func t_combo_logic() -> void:
	var a := ComboSystem.new()
	for m in ["Speed Vault", "Wall Run", "Kong Vault", "Tic Tac", "Precision Jump"]:
		a.add_move(m)
	var va := a.bank()
	var b := ComboSystem.new()
	for k in 5:
		b.add_move("Speed Vault")
	var vb := b.bank()
	check("Combo: variedad puntúa mucho más que repetir", va > vb * 4, "variado %d vs repetido %d" % [va, vb])
	var c := ComboSystem.new()
	c.add_move("Kong Vault")
	c.add_move("Backflip", 1.25, {"difficulty": 1.0})
	var before := c.current_value()
	c.bail()
	check("Combo: caída pierde el combo", c.total_score == 0 and before > 0, "")
	var d := ComboSystem.new()
	d.add_move("Wall Run")
	d.tick(0.5, true, 8.0)
	check("Combo: se mantiene en el aire", d.active, "")
	d.tick(3.0, false, 0.0)
	check("Combo: se cierra al quedarse parado", not d.active and d.total_score > 0, "")
	# Integración: un combo real del juego suma puntos
	var g: ComboSystem = game.combo
	g.reset_all()
	await _run_at_obstacle(Vector3(0, 0.1, 2), 0.8, false, -4.85)
	await run(func(i, f): pass, 160, func(): return not g.active)
	check("Combo en juego: el vault suma puntos al cerrarse", g.total_score > 0, "total %d" % g.total_score)

func t_flow() -> void:
	var fl := FlowSystem.new()
	for m in ["Speed Vault", "Wall Run", "Kong Vault", "Backflip", "Precision Jump"]:
		fl.on_move(m, 1.0, {"difficulty": 1.2})
		fl.on_land("clean", m == "Backflip", false)
	var varied := fl.value
	var sp := FlowSystem.new()
	for k in 8:
		sp.on_move("Backflip", 1.0, {"difficulty": 1.0})
		sp.on_land("clean", true, false)
	check("Flow: una línea variada sube mucho más que repetir el mismo mortal", varied > 55.0 and sp.value < 25.0, "variado %.0f · spam %.0f" % [varied, sp.value])
	var env := FlowSystem.new().on_move("Kong Vault", 1.0, {})
	var flat := FlowSystem.new().on_move("Sideflip", 1.0, {"difficulty": 1.0})
	check("Flow: aprovechar el entorno suma más que un truco en plano de dificultad parecida", env > flat, "kong %.1f · sideflip %.1f" % [env, flat])
	var c := FlowSystem.new()
	c.value = 80.0
	c.on_land("sloppy", true, false)
	var after_sloppy := c.value
	c.on_land("crash", true, false)
	check("Flow: forzado resta y caída lo pierde casi todo", after_sloppy < 70.0 and c.value < 15.0, "forzado %.0f · caída %.0f" % [after_sloppy, c.value])
	var d := FlowSystem.new()
	d.value = 70.0
	for k in 60: d.tick(1.0 / 60.0, true)
	var moving := d.value
	for k in 120: d.tick(1.0 / 60.0, false)
	check("Flow: se mantiene en movimiento y se apaga parado", moving > 68.0 and d.value < 50.0, "1 s moviéndose %.1f · 2 s parado %.1f" % [moving, d.value])
	var b := FlowSystem.new()
	b.value = 100.0
	check("Flow: extra pequeño y solo por encima de 60", b.boost() == 1.0 and FlowSystem.new().boost() == 0.0, "")
	# En juego: con flow lleno el sprint es algo más rápido, nunca exagerado
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var st := {"max": 0.0}
	await run(func(i, f):
		player.flow_boost = 1.0
		i.move = Vector2(0, 1); i.sprint = true
		st.max = maxf(st.max, player.speed()), 120)
	player.flow_boost = 0.0
	check("Flow en juego: sprint +6 % como máximo", st.max > player.t.sprint_speed * 1.03 and st.max < player.t.sprint_speed * 1.08, "vel %.2f" % st.max)
	# El juego conecta el flow: un vault real lo sube
	game.flow.reset()
	await _run_at_obstacle(Vector3(0, 0.1, 2), 0.8, false, -4.85)
	check("Flow en juego: el vault real lo sube y aparece en el HUD", game.flow.value > 5.0 and game.ui.flow_label.text.begins_with("FLOW"), "flow %.1f · %s" % [game.flow.value, game.ui.flow_label.text])

func t_spanish_names() -> void:
	var missing := []
	for pn in 4:
		for rn in 3:
			for sn in 3:
				for th in 7:
					for back in [true, false]:
						for mv in [true, false]:
							for wall in [true, false]:
								for st in ["", "cork", "aerial", "kick", "cartwheel", "roundoff", "bhs"]:
									for kind in ["", "vault", "ledge"]:
										var n: String = TrickSystem.trick_name(pn, rn, sn, th, back, mv, wall, st, kind, "Kong Vault" if kind == "vault" else "")
										if n != "" and MoveNames.es(n) == n and not n in missing:
											missing.append(n)
	for n in ["Speed Vault", "Lazy Vault", "Step Vault", "Kong Vault", "Dash Vault", "Wall Run", "Tic Tac", "Cat Leap",
			"Ledge Grab", "Precision Jump", "Safety Roll", "Roll", "Wall Jump", "Wall Climb", "Climb Up", "Mantle", "Step Up"]:
		if MoveNames.es(n) == n:
			missing.append(n)
	check("Nombres en español: todos los trucos y movimientos tienen traducción", missing.is_empty(), str(missing))
	check("Nombres en español: ejemplos", MoveNames.es("Backflip") == "Mortal atrás" and MoveNames.es("Round-off") == "Rondada" and MoveNames.es("Back Handspring") == "Flic-flac", "")

func t_camera() -> void:
	var touch: TouchControls = game.ui.touch
	var old_mode := Settings.trick_controls
	Settings.trick_controls = 0
	touch.visible = true
	touch.size = Vector2(1560, 720)
	touch.collect()
	var tch := func(idx: int, pos: Vector2, pressed: bool) -> void:
		var e := InputEventScreenTouch.new()
		e.index = idx; e.position = pos; e.pressed = pressed
		touch._on_touch(e)
	var drg := func(idx: int, pos: Vector2, rel: Vector2) -> void:
		var e := InputEventScreenDrag.new()
		e.index = idx; e.position = pos; e.relative = rel
		touch._on_drag(e)
	var hp := touch.camera_hint_pos()
	var free_spot := true
	for k in touch.zones():
		var r: float = touch.hit_radii()[k]
		if hp.distance_to(touch.zones()[k]) < r + 30.0:
			free_spot = false
	check("Cámara táctil: la indicación está en zona libre (no encima de botones)", free_spot and not touch._is_move_side(hp), "pos %s" % hp)
	# Correr con el pulgar izquierdo y girar la cámara con otro dedo a la vez
	tch.call(0, Vector2(200, 560), true)
	drg.call(0, Vector2(200, 460), Vector2(0, -100))
	tch.call(1, hp, true)
	drg.call(1, hp + Vector2(60, 0), Vector2(60, 0))
	var fr := touch.collect()
	check("Cámara táctil: arrastrar en zona libre gira la cámara mientras se corre", fr.camera_delta.x > 0.2 and fr.move.y > 0.9 and fr.flick == Vector2.ZERO, "cam %s move %s" % [fr.camera_delta, fr.move])
	tch.call(1, hp + Vector2(60, 0), false)
	tch.call(0, Vector2(200, 460), false)
	# Franja superior izquierda: también cámara (no arranca el joystick de movimiento)
	tch.call(2, Vector2(250, 80), true)
	drg.call(2, Vector2(300, 80), Vector2(50, 0))
	fr = touch.collect()
	check("Cámara táctil: franja superior izquierda = cámara", fr.camera_delta.x > 0.1 and fr.move == Vector2.ZERO, "cam %s move %s" % [fr.camera_delta, fr.move])
	tch.call(2, Vector2(300, 80), false)
	touch._time += 1.0
	tch.call(3, hp, true); tch.call(3, hp, false)
	touch._time += 0.15
	tch.call(3, hp + Vector2(10, 5), true); tch.call(3, hp, false)
	fr = touch.collect()
	check("Cámara táctil: doble toque = recentrar", fr.camera_recenter, "")
	touch.collect()
	Settings.trick_controls = old_mode
	touch.visible = false
	# Comportamiento de la cámara en juego
	var cam: CameraRig = game.camera
	game.router.take_camera()
	# Varios pasos de física sin fotograma entre medias (móvil con FPS bajos): nada se pierde
	await run(func(i, f): i.camera_delta = Vector2(0.1, 0) if f < 3 else Vector2.ZERO, 6)
	var acc: Dictionary = game.router.take_camera()
	check("Cámara: no pierde arrastres aunque la física dé varios pasos por fotograma", absf(acc.delta.x - 0.3) < 0.001, "acumulado %s (esperado 0.3)" % acc.delta)
	cam.set_process(true)
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	cam.snap()
	var behind := cam.yaw
	# El atleta corre siempre hacia el mismo punto del mundo (−Z), gire como gire la cámara.
	var north := func(i, f):
		var y := player.camera_yaw
		i.move = Vector2(sin(y), cos(y))
	await run(func(i, f): if f < 10: i.camera_delta = Vector2(0.15, 0), 20)
	var turned := absf(angle_difference(cam.yaw, behind))
	Settings.camera_mode = 0
	await run(north, 60)
	var held := absf(angle_difference(cam.yaw, behind))
	check("Cámara híbrida: el giro manual se respeta al correr (no lucha contra el jugador)", turned > 1.2 and held > 1.0, "girada %.2f · tras 1 s corriendo %.2f" % [turned, held])
	await run(north, 300)
	var follow := absf(angle_difference(cam.yaw, behind))
	check("Cámara híbrida: después vuelve sola detrás del movimiento", follow < 0.35, "desvío %.2f" % follow)
	await run(func(i, f): if f < 10: i.camera_delta = Vector2(0.15, 0), 20)
	await run(func(i, f): i.camera_recenter = f == 0, 40)
	var rec := absf(angle_difference(cam.yaw, atan2(-player.facing.x, -player.facing.z)))
	check("Cámara: recentrar la coloca detrás del atleta", rec < 0.1, "desvío %.2f" % rec)
	Settings.camera_mode = 1
	await run(func(i, f): if f < 10: i.camera_delta = Vector2(0.15, 0), 20)
	var m0 := cam.yaw
	await run(north, 240)
	check("Cámara manual: no se realinea sola", absf(angle_difference(cam.yaw, m0)) < 0.05 and absf(angle_difference(m0, behind)) > 1.0, "cambio %.3f" % absf(angle_difference(cam.yaw, m0)))
	Settings.camera_mode = 0
	var old_h := Settings.camera_height
	Settings.camera_height = 1.5
	await run(func(i, f): pass, 120)
	var high_y := cam.cam.global_position.y - player.global_position.y
	Settings.camera_height = 0.7
	await run(func(i, f): pass, 160)
	var low_y := cam.cam.global_position.y - player.global_position.y
	Settings.camera_height = old_h
	check("Cámara: la altura se puede ajustar", high_y > low_y + 0.6, "alta %.2f · baja %.2f" % [high_y, low_y])
	cam.set_process(false)
	player.camera_yaw = 0.0

func t_respawn_repeat() -> void:
	await place(Vector3(0, 0.1, 6), Vector3.FORWARD)
	await run(func(i, f): i.move = Vector2(0, 1), 50)
	var moved := player.global_position.distance_to(Vector3(0, 0, 6)) > 3.0
	await run(func(i, f): i.respawn_pressed = f == 0, 5)
	check("Repetir: reaparece en la salida", moved and player.global_position.distance_to(Vector3(0, 0.1, 6)) < 0.3,
		"pos %s" % str(player.global_position))
	await frames(20)
	await _run_at_obstacle(Vector3(0, 0.1, 2), 0.8, false, -4.85)
	check("Repetir: el recorrido vuelve a funcionar", "Speed Vault" in moves or "Step Vault" in moves, str(moves))

func t_modes() -> void:
	for id in GameModes.LIST:
		game.start_mode(id)
		await frames(10)
		check("Modo %s: arranca" % id, game.mode != null and game.mode.id == id and game.mode.status_text() != "", "")
	game.start_mode("challenge")
	game.camera.set_process(false)
	var ch = game.mode
	player.global_position = ch.checkpoints[0] - Vector3.UP * 0.9
	player.velocity = Vector3(0, 0, -3)
	await frames(3)
	check("Challenge: detecta checkpoint", ch.next >= 1, "next %d" % ch.next)

## Distribución táctil: botones grandes, sin solapes entre zonas y dentro de pantalla
## (iPhone 19,5:9, Android 16:9 y tablet 4:3, con tamaño normal y máximo).
func t_touch_layout() -> void:
	var touch: TouchControls = game.ui.touch
	var old_scale := Settings.control_scale
	var problems: Array[String] = []
	# Direcciones principales anchas (±30°), diagonales estrechas
	for pair in [[25.0, 0], [-28.0, 0], [35.0, 1], [62.0, 2], [118.0, 2], [125.0, 3], [178.0, 4], [-155.0, 4], [-140.0, -3], [-95.0, -2], [-50.0, -1]]:
		var v := Vector2.from_angle(deg_to_rad(pair[0]))
		if TouchControls.sector_of(v) != pair[1]:
			problems.append("sector %d° -> %d (esperado %d)" % [int(pair[0]), TouchControls.sector_of(v), pair[1]])
	var old_mode := Settings.trick_controls
	for combo in [[0, Vector2(1560, 720)], [0, Vector2(1280, 720)], [0, Vector2(960, 720)], [3, Vector2(1560, 720)], [3, Vector2(1280, 720)], [3, Vector2(960, 720)],
			[4, Vector2(1560, 720)], [4, Vector2(1542, 720)], [4, Vector2(1280, 720)], [4, Vector2(960, 720)]]:
		Settings.trick_controls = combo[0]
		var sz: Vector2 = combo[1]
		for sc in [1.0, 1.4]:
			Settings.control_scale = sc
			touch.size = sz
			var hr := touch.hit_radii()
			var zones := touch.zones()
			if touch.stick_enabled():
				zones["joy"] = touch._joy_idle()
				hr["joy"] = TouchControls.JOY_R * touch._s()
			var names := zones.keys()
			for i in names.size():
				var c: Vector2 = zones[names[i]]
				var r: float = hr[names[i]]
				if c.x - r < -4 or c.y - r < -4 or c.x + r > sz.x + 4 or c.y + r > sz.y + 4:
					problems.append("%s fuera %s x%.1f" % [names[i], sz, sc])
				for j in range(i + 1, names.size()):
					var c2: Vector2 = zones[names[j]]
					if c.distance_to(c2) < r + hr[names[j]]:
						problems.append("%s/%s solapan %s x%.1f modo %d" % [names[i], names[j], sz, sc, combo[0]])
	Settings.control_scale = 1.0
	touch.size = Vector2(1560, 720)
	Settings.trick_controls = 3
	var big: bool = touch._jump_radius() >= 120.0 and touch._pad_radius() >= 140.0
	Settings.trick_controls = 0
	var big_stick: bool = touch._jump_radius() >= 100.0 and touch._rot_radius() >= 135.0 and touch._small_radius() >= 60.0 \
		and touch.zones().size() == 5
	Settings.trick_controls = old_mode
	Settings.control_scale = old_scale
	check("Táctil: zonas sin solapes y dentro de pantalla (doble joystick y cruceta)", problems.is_empty(), str(problems))
	check("Táctil: SALTO y cruceta grandes (>=1/3 y >=2/5 de la altura)", big, "")
	check("Táctil: solo 2 joysticks + SALTO, VAULT, AGARRAR y RODAR, todos grandes", big_stick, str(touch.zones().keys()))

## Sensación de aterrizaje: perfecto conserva el impulso, torcido lo pierde y tropieza.
func t_landing_feel() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f): i.move = Vector2(0, 1.0), 70)
	var v0 := player.speed()
	await run(func(i, f):
		i.move = Vector2(0, 1.0)
		i.jump_pressed = f == 0
		i.jump_held = true, 120,
		func(): return _f > 6 and player.state == PlayerController.State.GROUND)
	var q: String = landings[-1].quality if landings.size() > 0 else "none"
	check("Aterrizaje limpio: conserva la carrera", q in ["perfect", "clean"] and player.speed() > v0 * 0.85 and player.stun <= 0.0,
		"%s %.1f -> %.1f" % [q, v0, player.speed()])
	check("Aterrizaje: flexión de recepción visible", player.land_impact > 0.2, "%.2f" % player.land_impact)
	# Anticipación: el salto pasa por la flexión antes de despegar
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var st := {"load": false}
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = true
		st.load = st.load or player.jump_load > 0.0, 30,
		func(): return player.state == PlayerController.State.AIR)
	check("Salto con flexión previa (anticipación) y despegue", st.load and player.state == PlayerController.State.AIR, "")

## Trucos nuevos: patadas giratorias (SALTO otra vez en el aire / botón GIRO),
## mortales con tirabuzón completo y nombres según el despegue.
func t_new_tricks() -> void:
	# 360 Kick parado: salto y segundo toque de SALTO en el aire
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.jump_pressed = f == 0 or f == 9
		i.jump_held = f < 2 or (f >= 9 and f < 11), 120,
		func(): return _f > 12 and player.state == PlayerController.State.GROUND)
	var q: String = landings[-1].quality if landings.size() > 0 else "none"
	check("360 Kick: segundo toque de SALTO en el aire", "360 Kick" in moves and q in ["perfect", "clean"], str(moves) + " " + q)
	# 540: dos toques en el aire
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.jump_pressed = f == 0 or f == 10 or f == 16
		i.jump_held = f < 2, 120,
		func(): return _f > 16 and player.state == PlayerController.State.GROUND)
	q = landings[-1].quality if landings.size() > 0 else "none"
	check("540 Kick: dos toques en el aire (aterriza de espaldas)", "540 Kick" in moves and q in ["perfect", "clean"], str(moves) + " " + q)
	# Back Full: backflip + botón GIRO durante el mortal
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = true
		i.flick = Vector2(0, -1) if f == 2 else Vector2.ZERO
		i.kick = f == 8, 120,
		func(): return _f > 16 and player.state == PlayerController.State.GROUND)
	q = landings[-1].quality if landings.size() > 0 else "none"
	check("Piru: mortal atrás + GIRO = tirabuzón completo", "Piru" in moves and q in ["perfect", "clean"], str(moves) + " " + q)
	# Nombres según despegue y tirabuzones (tabla de trucos)
	var TS := TrickSystem
	var cases := [
		[TS.trick_name(1, 0, 0, 0, true, false, true, "back", "wall", "wallclimb"), "Wall Flip"],
		[TS.trick_name(1, 0, 0, 0, true, true, false, "back", "vault", "Kong Vault"), "Kong Gainer"],
		[TS.trick_name(1, 0, 0, 0, false, true, false, "front", "vault", "Dash Vault"), "Dash Bomb"],
		[TS.trick_name(1, 0, 0, 2, true, true, false, "back"), "Piru"],
		[TS.trick_name(2, 0, 0, 2, true, false, false, "back"), "Full In"],
		[TS.trick_name(1, 0, 0, 4, true, false, false, "back"), "Piru 720"],
		[TS.trick_name(1, 0, 0, 1, false, false, false, "front"), "Arabian"],
		[TS.trick_name(1, 0, 0, 2, false, false, false, "front"), "Front Full"],
		[TS.trick_name(0, 1, 0, 1, false, true, false, "side"), "Sideflip Half"],
		[TS.trick_name(0, 0, 1, 2, false, true, false, "butterfly"), "Butterfly Twist"],
		[TS.trick_name(0, 0, 0, 4, false, true, false, "kick"), "Cheat 720"],
		[TS.trick_name(2, 0, 0, 4, true, true, false, "cork"), "Double Cork"],
	]
	var bad := cases.filter(func(c): return c[0] != c[1])
	check("Tabla de trucos: nombres de flips, twists, kicks y despegues", bad.is_empty(), str(bad))

## Variantes de vault elegidas con gesto justo antes de saltar.
func t_vault_variants() -> void:
	# VAULT + joystick derecho en diagonal: paso de ladrón (↗) y paso con giro (↙)
	for v in [[Vector2(0.7, 0.7), "Thief Vault"], [Vector2(-0.7, -0.7), "Turn Vault"]]:
		await place(Vector3(0, 0.1, 2), Vector3.FORWARD)
		var st := {"pressed": false, "peak": -INF, "vault_t": 0.0}
		var rv: Vector2 = v[0]
		var keep_running: bool = v[1] == "Thief Vault"
		await run(func(i, f):
			# En el paso con giro el jugador suelta el joystick al acabar (queda de cara al obstáculo)
			i.move = Vector2(0, 0.8) if keep_running or st.vault_t == 0.0 or player.state == PlayerController.State.VAULT else Vector2.ZERO
			var go: bool = not st.pressed and player.global_position.z <= -4.85
			i.rot = rv if player.global_position.z <= -4.0 and not st.pressed else Vector2.ZERO
			i.vault_pressed = go
			st.pressed = st.pressed or go
			if player.state == PlayerController.State.VAULT:
				st.peak = maxf(st.peak, player.global_position.y)
				st.vault_t += 1.0 / 60.0, 200,
			func(): return st.pressed and player.state == PlayerController.State.GROUND and player.state_time > 0.15)
		var nm: String = v[1]
		check("%s: VAULT + joystick derecho en diagonal, lo supera" % nm, nm in moves and player.global_position.z < -6.0, "%s z %.2f" % [str(moves), player.global_position.z])
		if nm == "Thief Vault":
			check("Thief Vault: trayectoria rasante y conserva la carrera", st.peak < 1.25 and player.speed() > 3.5, "pico %.2f vel %.2f" % [st.peak, player.speed()])
		else:
			var to_wall := player.facing.dot(Vector3.BACK)
			check("Turn Vault: más lento, cae frenado y mirando al obstáculo", st.vault_t > 0.45 and player.speed() < 1.0 and to_wall > 0.9,
				"duración %.2f vel %.2f mira %.2f" % [st.vault_t, player.speed(), to_wall])
	# Thief en caja profunda no es viable: hace la técnica normal
	await place(Vector3(0, 0.1, -8), Vector3.FORWARD)
	var st2 := {"pressed": false}
	await run(func(i, f):
		i.move = Vector2(0, 1); i.sprint = true
		var go: bool = not st2.pressed and player.global_position.z <= -12.9
		i.rot = Vector2(0.7, 0.7) if player.global_position.z <= -12.0 and not st2.pressed else Vector2.ZERO
		i.vault_pressed = go
		st2.pressed = st2.pressed or go, 200,
		func(): return st2.pressed and player.state == PlayerController.State.GROUND and player.global_position.z < -15.0)
	check("Thief Vault: no se fuerza en un obstáculo profundo (sale Kong)", not "Thief Vault" in moves and "Kong Vault" in moves, str(moves))
	for v in [[Vector2(1, 0), "Reverse Vault", Vector3(0, 0.1, 2), 0.8, false, -4.85, -6.5],
			[Vector2(0, 1), "Double Kong", Vector3(0, 0.1, -8), 1.0, true, -12.9, -15.0],
			[Vector2(0, -1), "Kash Vault", Vector3(0, 0.1, -8), 1.0, true, -12.9, -15.0]]:
		await place(v[2], Vector3.FORWARD)
		var st := {"pressed": false}
		var jz: float = v[5]
		var stick: float = v[3]
		var spr: bool = v[4]
		var fl: Vector2 = v[0]
		await run(func(i, f):
			i.move = Vector2(0, stick); i.sprint = spr
			var go: bool = not st.pressed and player.global_position.z <= jz
			i.flick = fl if go else Vector2.ZERO
			i.jump_pressed = go
			st.pressed = st.pressed or go, 200,
			func(): return st.pressed and player.state == PlayerController.State.GROUND and player.global_position.z < v[6])
		check("%s: gesto + salto ante el obstáculo, lo supera" % v[1], v[1] in moves and player.global_position.z < v[6], "%s z %.2f" % [str(moves), player.global_position.z])

# ------------------------------------------------------------------ habilidades de suelo

## Intérprete de gestos: flick, mantener, diagonal, arco, cambio de dirección, doble, soltar.
func t_gestures() -> void:
	var feed := func(g: GestureInterpreter, seq: Array) -> Array:
		var evs := []
		for v in seq:
			var e: Dictionary = g.update(v, 1.0 / 60.0, true)
			if not e.is_empty():
				evs.append(e)
		return evs
	var rep := func(v: Vector2, n: int) -> Array:
		var a := []
		for k in n: a.append(v)
		return a
	var g := GestureInterpreter.new()
	var e: Array = feed.call(g, rep.call(Vector2(0, -1), 10) + rep.call(Vector2.ZERO, 10))
	check("Gestos: flick rápido ↓", e.size() == 1 and e[0].type == "flick" and e[0].sector == -2, str(e))
	g = GestureInterpreter.new()
	e = feed.call(g, rep.call(Vector2(0.7, 0.7), 10) + rep.call(Vector2.ZERO, 10))
	check("Gestos: diagonal ↗ reconocida", e.size() == 1 and e[0].sector == 1, str(e))
	g = GestureInterpreter.new()
	e = feed.call(g, rep.call(Vector2(0, 1), 40) + rep.call(Vector2.ZERO, 10))
	check("Gestos: dirección mantenida (hold) y liberación (release)", e.size() == 2 and e[0].type == "hold" and e[1].type == "release", str(e))
	g = GestureInterpreter.new()
	var arc := []
	for k in 16: arc.append(Vector2.from_angle(lerpf(0.0, PI, k / 15.0)))
	e = feed.call(g, arc + rep.call(Vector2.ZERO, 10))
	check("Gestos: arco por arriba antihorario", e.size() == 1 and e[0].type == "arc" and e[0].through == "top" and e[0].dir == 1, str(e))
	g = GestureInterpreter.new()
	arc = []
	for k in 16: arc.append(Vector2.from_angle(lerpf(PI, TAU, k / 15.0)))
	e = feed.call(g, arc + rep.call(Vector2.ZERO, 10))
	check("Gestos: arco por abajo", e.size() == 1 and e[0].type == "arc" and e[0].through == "bottom", str(e))
	g = GestureInterpreter.new()
	e = feed.call(g, rep.call(Vector2(-1, 0), 6) + [Vector2.ZERO] + rep.call(Vector2(1, 0), 6) + rep.call(Vector2.ZERO, 10))
	check("Gestos: cambio de dirección ← → (no dos flicks)", e.size() == 1 and e[0].type == "change" and e[0].to == 0, str(e))
	g = GestureInterpreter.new()
	e = feed.call(g, rep.call(Vector2(0, -1), 6) + rep.call(Vector2.ZERO, 8) + rep.call(Vector2(0, -1), 6) + rep.call(Vector2.ZERO, 10))
	check("Gestos: secuencia de dos flicks iguales = doble", e.size() == 2 and e[1].type == "double" and g.sequence().size() == 2, str(e))
	g = GestureInterpreter.new()
	e = []
	for k in 20:
		var ev: Dictionary = g.update(Vector2(0, -1) if k < 10 else Vector2.ZERO, 1.0 / 60.0, false)
		if not ev.is_empty(): e.append(ev)
	check("Gestos: un gesto que empieza en el aire no cuenta al aterrizar", e.is_empty(), str(e))

## Ejecuta una habilidad con su gesto y mide lo que se ve: apoyo real de manos (la mano queda
## clavada en el suelo), nada atraviesa el suelo, fases, desplazamiento y orientación final.
func skill_probe(gesture: Array, pre_run := 0) -> Dictionary:
	var rig: BodyRig = game.rig
	var r := {"ids": [], "phases": {}, "hand_frames": 0, "hand_drift": 0.0, "hand_gap": 0.0, "min_limb": 99.0,
		"start": player.global_position, "facing0": player.facing, "max_com": 0.0, "power": {}, "t0": -1, "dur": 0}
	await run(func(i, f):
		if f < pre_run or (pre_run > 0 and r.t0 < 0 and player.state == PlayerController.State.GROUND):
			i.move = Vector2(0, 1); i.sprint = true      # sigue corriendo mientras hace el gesto
		var k: int = f - pre_run
		match String(gesture[0]):
			"flick": i.rot = gesture[1] if k >= 0 and k < 10 else Vector2.ZERO
			"hold": i.rot = gesture[1] if k >= 0 and k < int(gesture[2]) else Vector2.ZERO
			"arc":
				if k >= 0 and k <= 15: i.rot = Vector2.from_angle(lerpf(gesture[1], gesture[2], k / 15.0))
			"change":
				if k >= 0 and k < 5: i.rot = gesture[1]
				elif k >= 6 and k < 11: i.rot = gesture[2]
			"roll":
				i.rot = gesture[1] if k >= 0 and k < 6 else Vector2.ZERO
				i.action_pressed = k == 2
		if player.state == PlayerController.State.SKILL:
			if r.t0 < 0: r.t0 = f
			r.dur = f - r.t0
			var id: String = player.skill.id
			if not r.ids.has(id): r.ids.append(id)
			r.phases[rig.last_phase] = true
			r.max_com = maxf(r.max_com, rig.pivot.position.y)
			if r.power.is_empty(): r.power = player.skill.power
			for c in ["hl", "hr"]:
				if rig.contact_w[c] >= 0.99 and rig.plants.has(c):
					r.hand_frames += 1
					var end := rig.limb_end(c)
					r.hand_drift = maxf(r.hand_drift, (end - (rig.plants[c] as Vector3)).length())
		for c in ["hl", "hr", "fl", "fr"]:
			var lim := rig.limb_end(c).y - rig.ground_y
			r.min_limb = minf(r.min_limb, lim), 320 + pre_run,
		func(): return r.t0 >= 0 and player.state == PlayerController.State.GROUND and _f > r.t0 + 5)
	r.end = player.global_position
	r.facing1 = player.facing
	return r

func t_ground_skills() -> void:
	# [nombre, gesto, carrera, desplazamiento esperado ("back","fwd","side","any"), mira atrás al final, apoyos de mano]
	var cases := [
		["Round-off", ["flick", Vector2(0.7, -0.7)], 50, "fwd", true, true],
		["Back Handspring", ["flick", Vector2(0, -1)], 0, "back", false, true],
		["Cartwheel", ["flick", Vector2(1, 0)], 0, "side", false, true],
	]
	for c in cases:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		var r: Dictionary = await skill_probe(c[1], c[2])
		var name: String = c[0]
		var tag := "Habilidad %s: " % name
		check(tag + "se ejecuta y se reconoce", name in moves, "%s ids %s" % [moves, r.ids])
		var d: Vector3 = r.end - r.start
		var f0: Vector3 = r.facing0
		var ok_dir := true
		match String(c[3]):
			"back": ok_dir = d.dot(f0) < -0.5
			"fwd": ok_dir = d.dot(f0) > 0.5
			"side": ok_dir = absf(d.dot(f0.cross(Vector3.UP))) > 0.5
		check(tag + "desplazamiento coherente (%s)" % c[3], ok_dir, "d %s" % d)
		if c[4]:
			check(tag + "sale mirando atrás (media vuelta)", (r.facing1 as Vector3).dot(f0) < -0.7, "%.2f" % (r.facing1 as Vector3).dot(f0))
		if c[5]:
			check(tag + "apoyo real de manos (mano clavada en el suelo, deriva < 8 cm)", r.hand_frames > 4 and r.hand_drift < 0.08,
				"frames %d deriva %.3f" % [r.hand_frames, r.hand_drift])
		check(tag + "manos y pies nunca atraviesan el suelo", r.min_limb > -0.02, "mín %.3f" % r.min_limb)
		check(tag + "fases visibles (%d)" % r.phases.size(), r.phases.size() >= 4, str(r.phases.keys()))
		check(tag + "termina de pie con control", player.state == PlayerController.State.GROUND, PlayerController.STATE_NAMES[player.state])
	# Flic-flac ≠ backflip: el backflip no apoya las manos
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var bf := {"hands": 0}
	await run(func(i, f):
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.tuck = f < 12; i.jump_held = f < 12
		if game.rig.contact_w.hl > 0.5 or game.rig.contact_w.hr > 0.5: bf.hands += 1, 120,
		func(): return _f > 16 and player.state == PlayerController.State.GROUND)
	check("Backflip sin apoyo de manos (el flic-flac sí apoya)", "Backflip" in moves and bf.hands == 0, "%s manos %d" % [moves, bf.hands])
	# Potencia: la rondada con carrera transforma la velocidad en recepción y rebote
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var fast: Dictionary = await skill_probe(["flick", Vector2(0.7, -0.7)], 60)
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var slow: Dictionary = await skill_probe(["flick", Vector2(0.7, -0.7)], 0)
	check("Potencia: rondada con carrera conserva más velocidad y rebote que parado",
		float(fast.power.exit_speed) > float(slow.power.exit_speed) + 1.0 and float(fast.power.rebound_vy) > float(slow.power.rebound_vy),
		"carrera %.2f m/s %.2f vy · parado %.2f m/s %.2f vy" % [fast.power.exit_speed, fast.power.rebound_vy, slow.power.exit_speed, slow.power.rebound_vy])
	check("Potencia: sin multiplicadores absurdos (rebote ≤ 3,2 m/s, salida ≤ sprint)",
		float(fast.power.rebound_vy) <= 3.2 and float(fast.power.exit_speed) <= player.t.sprint_speed, str(fast.power))
	# Kip-up desde el suelo con el joystick ↑ tras una caída
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD, 0)
	await run(func(i, f):
		i.jump_pressed = f == 0; i.jump_held = true
		i.flick = Vector2(0, -1) if f == 2 else Vector2.ZERO
		i.tuck = f >= 2, 200, func(): return player.state == PlayerController.State.CRASH)
	var kh := {"hands": 0}
	await run(func(i, f):
		i.rot = Vector2(0, 1) if f >= 25 and f < 33 else Vector2.ZERO
		if game.rig.contact_w.hl > 0.9: kh.hands += 1, 140, func(): return "Kip-up" in moves and player.state == PlayerController.State.GROUND)
	check("Kip-up: joystick ↑ tumbado, apoyo de manos junto a la cabeza y de pie", "Kip-up" in moves and kh.hands > 4, "%s manos %d" % [moves, kh.hands])

## Enlaces con el joystick derecho y la rueda. Pasos:
##   [disparo, acción...]  disparo: "now" · "mid" (mitad de la habilidad) · "link" (ventana abierta)
##   acciones: ["flick", dir] ["hold", dir, n] ["arc", a0, a1] ["jump", dir, giro, doble]
func chain_run(steps: Array, pre_run := 0) -> Dictionary:
	var st := {"i": 0, "t0": -1, "peaks": [], "peak": -99.0, "air": false, "y0": player.global_position.y, "done_f": -1, "last_serial": -1, "last_chain": -1}
	await run(func(i, f):
		i.stick_twist = true
		if f < pre_run:
			i.move = Vector2(0, 1); i.sprint = true
			return
		if player.state == PlayerController.State.SKILL:
			st.started = true
		if pre_run > 0 and not st.get("started", false) and player.state == PlayerController.State.GROUND:
			i.move = Vector2(0, 1); i.sprint = true      # sigue corriendo hasta que sale la primera habilidad
		if player.state == PlayerController.State.AIR:
			st.air = true
			st.peak = maxf(st.peak, player.global_position.y - st.y0)
		elif st.air:
			st.air = false
			st.peaks.append(st.peak)
			st.peak = -99.0
		if st.i >= steps.size():
			return
		var step: Array = steps[st.i]
		if st.t0 < 0:
			var go := false
			match String(step[0]):
				"now": go = true
				"mid": go = player.state == PlayerController.State.SKILL and float(player.skill.s) > 0.45 and player.skill_serial != st.last_serial
				"link": go = (player.chain.active() and player.chain.serial != st.last_chain and int(player.chain.link.get("skill_serial", -1)) != st.last_serial) or (player.state == PlayerController.State.SKILL and player.skill.get("linked", false) and player.skill_serial != st.last_serial)
			if go:
				st.t0 = f
				st.trig_serial = player.skill_serial
				st.trig_chain = player.chain.serial
		if st.t0 < 0:
			return
		var k: int = f - st.t0
		var a: Array = step[1]
		var finished := false
		match String(a[0]):
			"flick":
				i.rot = a[1] if k < 8 else Vector2.ZERO
				finished = k >= 8
			"hold":
				i.rot = a[1] if k < int(a[2]) else Vector2.ZERO
				finished = k >= int(a[2])
			"arc":
				i.rot = Vector2.from_angle(lerpf(a[1], a[2], minf(k / 15.0, 1.0)))
				finished = k >= 16
			"twist":
				i.twist = float(a[1]) if k >= int(a[3]) and k < int(a[3]) + int(a[2]) else 0.0
				finished = k > 6 and player.state != PlayerController.State.AIR
			"jump":
				if k == 0: st.flew = false
				if player.state == PlayerController.State.AIR: st.flew = true
				i.jump_pressed = k == 0
				i.flick = a[1] if k == 0 else Vector2.ZERO
				var need := TAU * (2.0 if a.size() > 3 and a[3] else 1.0) - deg_to_rad(110)
				var tr := player.tricks
				var rot_now := maxf(absf(tr.total_pitch), maxf(absf(tr.total_roll), absf(tr.total_spin)))
				i.tuck = k < 70 and rot_now < need and (k < 12 or (a.size() > 3 and a[3]))
				i.jump_held = i.tuck
				if a.size() > 3 and a[3] and k == 16:
					i.flick = a[1]              # otra vuelta (zona de la rueda otra vez)
				var tf: int = a[2] if a.size() > 2 else 0
				i.twist = signf(tf) if tf != 0 and k >= 8 and k < 8 + absi(tf) else 0.0
				finished = k > 6 and st.get("flew", false) and player.state != PlayerController.State.AIR
		if finished:
			st.last_serial = st.trig_serial
			st.last_chain = st.trig_chain
			st.i += 1
			st.t0 = -1
			if st.i >= steps.size(): st.done_f = f, 700 + pre_run,
		func(): return st.done_f >= 0 and _f > st.done_f + 12 and player.state in [PlayerController.State.GROUND, PlayerController.State.ROLL, PlayerController.State.CRASH])
	return st

func t_chains() -> void:
	var D := Vector2(0, -1)
	var RO := Vector2(0.7, -0.7)
	var cases := [
		["Rondada → Backflip", [["now", ["flick", RO]], ["link", ["jump", D]]], 55, ["Round-off", "@back"]],
		["Rondada → Flic-flac → Backflip", [["now", ["flick", RO]], ["mid", ["flick", D]], ["link", ["jump", D]]], 55, ["Round-off", "Back Handspring", "@back"]],
		["Rondada → Flic-flac → Double Backflip", [["now", ["flick", RO]], ["mid", ["flick", D]], ["link", ["jump", D, 0, true]]], 55, ["Round-off", "Back Handspring", "@double"]],
		["Rondada → Flic-flac → Flic-flac → Double Backflip", [["now", ["flick", RO]], ["mid", ["flick", D]], ["mid", ["flick", D]], ["link", ["jump", D, 0, true]]], 55, ["Round-off", "Back Handspring", "Back Handspring", "@double"]],
		["Rondada → Flic-flac → Cork", [["now", ["flick", RO]], ["mid", ["flick", D]], ["link", ["jump", D, 26]]], 55, ["Round-off", "Back Handspring", "Cork"]],
		["Rondada → Flic-flac → Double Cork", [["now", ["flick", RO]], ["mid", ["flick", D]], ["link", ["jump", D, 26, true]]], 55, ["Round-off", "Back Handspring", "Double Cork"]],
		["Aerial → Aerial", [["now", ["flick", Vector2(-0.7, 0.7)]], ["link", ["flick", Vector2(-0.7, 0.7)]]], 0, ["Aerial", "Aerial"]],
		["Rueda → Backflip", [["now", ["flick", Vector2(1, 0)]], ["link", ["jump", D]]], 0, ["Cartwheel", "@back"]],
	]
	for c in cases:
		await place(Vector3(-35, 0.1, 40), Vector3.FORWARD)
		var st: Dictionary = await chain_run(c[1], c[2])
		_check_chain(c[0], c[3], st)
	# Rebote: la rondada da más altura al backflip que un backflip parado (sin multiplicar a lo loco)
	await place(Vector3(-35, 0.1, 40), Vector3.FORWARD)
	var plain: Dictionary = await chain_run([["now", ["jump", D]]], 0)
	await place(Vector3(-35, 0.1, 40), Vector3.FORWARD)
	var comb: Dictionary = await chain_run([["now", ["flick", RO]], ["link", ["jump", D]]], 55)
	var hp: float = plain.peaks[0] if plain.peaks.size() > 0 else 0.0
	var hc: float = comb.peaks[-1] if comb.peaks.size() > 0 else 0.0
	check("Transferencia: rondada → backflip sube más (%.2f m vs %.2f m) y menos de 1,8×" % [hc, hp], hc > hp * 1.15 and hc < hp * 1.8, "")
	# Timing: enlazar tarde rebota menos que en el momento de la recepción
	await place(Vector3(-35, 0.1, 40), Vector3.FORWARD)
	var tm := {"vy_early": 0.0}
	await run(func(i, f):
		i.rot = RO if f < 8 else Vector2.ZERO, 200, func(): return player.chain.active())
	var early: Dictionary = player.chain.link.duplicate()
	early.time = early.window
	var cs := ChainSystem.new()
	cs.link = early.duplicate()
	var e1 := cs.consume("flip_back")
	cs.link = early.duplicate(); cs.link.time = 0.05
	var e2 := cs.consume("flip_back")
	check("Timing de recepción: enlazar al momento rebota más que tarde", float(e1.get("rebound_vy", 0)) > float(e2.get("rebound_vy", 0)) * 1.3,
		"%.2f vs %.2f" % [e1.get("rebound_vy", 0), e2.get("rebound_vy", 0)])
	check("Transición incoherente no hereda potencia (rondada → paloma)", ChainSystem.new().consume("fhs").is_empty() and not ChainSystem.allowed("roundoff", "fhs"), "")

func _check_chain(name: String, expect: Array, st: Dictionary) -> void:
	var idx := 0
	for m in moves:
		if idx < expect.size():
			var e: String = expect[idx]
			var ok: bool = m == e or (e == "@back" and m in ["Backflip", "Gainer"]) \
				or (e == "@double" and m in ["Double Backflip", "Double Gainer"]) \
				or (e == "@btwist" and m.begins_with("Butterfly Twist"))
			if ok: idx += 1
	var clean := landings.all(func(l): return l.quality in ["perfect", "clean"])
	check("Enlace %s: se ejecuta en orden" % name, idx == expect.size(), str(moves))
	check("Enlace %s: recepciones limpias y termina de pie" % name, clean and player.state in [PlayerController.State.GROUND, PlayerController.State.ROLL],
		"%s %s" % [landings.map(func(l): return l.quality), PlayerController.STATE_NAMES[player.state]])

## Doble joystick: la rueda de SALTO solo hace saltos y mortales; los giros son del joystick GIRO.
func t_wheel_no_twist() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var tw := {"max": 0.0}
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0 or f == 20            # centro de SALTO otra vez en el aire
		i.flick = Vector2(0, -1) if f == 0 else (Vector2(1, 0) if f == 16 else Vector2.ZERO)   # zona LATERAL en el mortal
		i.tuck = f < 24; i.jump_held = i.tuck
		tw.max = maxf(tw.max, absf(player.tricks.total_twist)), 150,
		func(): return _f > 16 and player.state == PlayerController.State.GROUND)
	check("Rueda: en el aire no añade tirabuzón ni giro (solo el joystick GIRO gira)", "Backflip" in moves and tw.max < 0.05, "%s giro %.2f" % [moves, tw.max])
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0 or f == 10
		i.flick = Vector2.ZERO
		i.jump_held = f < 14, 120, func(): return _f > 16 and player.state == PlayerController.State.GROUND)
	check("Rueda: el centro pulsado otra vez en el aire no hace patada giratoria", moves.is_empty(), str(moves))

## Vaults: las manos se apoyan de verdad sobre el obstáculo (se clavan en la superficie).
func t_vault_hands() -> void:
	var rig: BodyRig = game.rig
	for c in [["Kong Vault", Vector3(0, 0.1, -8), -12.9, 1.0, true], ["Speed Vault", Vector3(0, 0.1, 2), -4.85, 0.8, false]]:
		await place(c[1], Vector3.FORWARD)
		var r := {"p": false, "frames": 0, "drift": 0.0, "below": 0.0}
		await run(func(i, f):
			i.move = Vector2(0, c[3]); i.sprint = c[4]
			i.vault_pressed = not r.p and player.global_position.z <= c[2]
			r.p = r.p or i.vault_pressed
			if player.state == PlayerController.State.VAULT:
				var top: float = player.vault.top_y
				for h in ["hl", "hr"]:
					if rig.contact_w[h] >= 0.99 and rig.plants.has(h):
						r.frames += 1
						var e := rig.limb_end(h)
						r.drift = maxf(r.drift, (e - (rig.plants[h] as Vector3)).length())
						r.below = minf(r.below, e.y - (top + BodyRig.HAND_R)), 220,
			func(): return r.p and _f > 16 and player.state == PlayerController.State.GROUND)
		check("%s: manos apoyadas sobre el obstáculo (deriva < 8 cm, %d fotogramas)" % [c[0], r.frames],
			c[0] in moves and r.frames >= 3 and r.drift < 0.08 and r.below > -0.03, "%s deriva %.3f bajo %.3f" % [moves, r.drift, r.below])

## Botonera (esquema por defecto): SALTO grande y arco de 3/4 de círculo con un botón por
## movimiento, abajo a la derecha; joystick de movimiento y joystick GIRO. Toques reales.
func t_ring_buttons() -> void:
	var touch: TouchControls = game.ui.touch
	var old_mode := Settings.trick_controls
	Settings.trick_controls = 4
	Settings.force_touch_ui = true
	touch.visible = true
	touch.size = Vector2(1542, 720)
	touch.ring_page = 0
	var n := touch.ring_buttons().size()
	# Geometría: arco de 270° alrededor del SALTO, abajo a la derecha
	var jc := touch._jump_center()
	var first := touch.ring_button_center(0)
	var last := touch.ring_button_center(n - 1)
	var top := touch.ring_button_center(n / 2)
	check("Botonera: SALTO abajo a la derecha y %d botones en 3/4 de círculo (con CAMBIAR)" % n,
		jc.x > touch.size.x * 0.7 and jc.y > touch.size.y * 0.55 and first.x < jc.x and first.y > jc.y and last.x > jc.x and last.y > jc.y and top.y < jc.y - 100,
		"salto %s primero %s último %s" % [jc, first, last])
	# Accesos rápidos neón: a la izquierda, sin pisar joystick, rueda ni fila de parkour
	var s := touch._s()
	var qok := true
	var qinfo := ""
	var others: Array = [[touch._joy_idle(), TouchControls.JOY_R * s], [jc, touch._jump_radius()],
		[touch._park_center(0), TouchControls.PARK_R * s], [touch._rot_center(), 60.0 * s]]
	for i in n:
		others.append([touch.ring_button_center(i), touch.ring_button_radius()])
	for qi in TouchControls.QUICK.size():
		var qc := touch.quick_center(qi)
		if qc.x > touch.size.x * 0.35 or qc.y < 0 or qc.y > touch.size.y:
			qok = false; qinfo += "fuera %d %s; " % [qi, qc]
		for o in others:
			if qc.distance_to(o[0]) < 32.0 * s + float(o[1]):
				qok = false; qinfo += "solapa %d con %s; " % [qi, o[0]]
		if touch.quick_at(qc) != qi:
			qok = false; qinfo += "no detecta %d; " % qi
	check("Botonera neón: %d accesos rápidos a la izquierda sin solapar controles" % TouchControls.QUICK.size(), qok, qinfo)
	var got: Array[String] = []
	var cb := func(id: String) -> void: got.append(id)
	touch.quick_action.connect(cb)
	var qe := InputEventScreenTouch.new()
	qe.index = 6
	var ri := TouchControls.QUICK.map(func(q): return q[2]).find("respawn")
	qe.position = touch.quick_center(ri)
	qe.pressed = true
	touch._on_touch(qe)
	qe.pressed = false
	touch._on_touch(qe)
	touch.quick_action.disconnect(cb)
	check("Botonera neón: tocar REAPARECER emite su acción", got == ["respawn"], str(got))
	var press := func(idx: int, on: bool) -> void:
		var e := InputEventScreenTouch.new()
		e.index = 5
		e.position = touch.ring_button_center(idx)
		e.pressed = on
		touch._on_touch(e)
	var find := func(label: String) -> int:
		# Busca el botón en la página actual; si no está, gira la rueda a su página
		for k in 2:
			var btns: Array = touch.ring_buttons()
			for i in btns.size():
				if String(btns[i][0]).replace("\n", " ") == label:
					return i
			touch.ring_page = maxi(TouchControls.page_of(label), 0)
		return -1
	game.router.scripted = Callable()            # entrada real: el táctil
	for c in [["ATRÁS", "Backflip"], ["ADELANTE", "Frontflip"], ["LATERAL DER.", "Sideflip"],
			["RONDADA", "Round-off"], ["FLIC-FLAC", "Back Handspring"], ["RUEDA", "Cartwheel"]]:
		var bi: int = find.call(c[0])
		player.set_spawn(Transform3D(Basis(), Vector3(-35, 0.1, 35)), Vector3.FORWARD)
		player.respawn()
		player.camera_yaw = 0.0
		await frames(20)
		moves.clear(); landings.clear()
		press.call(bi, true)
		var held := 0
		for k in 220:
			await get_tree().physics_frame
			var tr := player.tricks
			var need := TAU * (2.0 if c[1].begins_with("Double") else 1.0) - deg_to_rad(100)
			if held == 0 and (k > 40 or maxf(absf(tr.total_pitch), absf(tr.total_roll)) > need):
				press.call(bi, false)                  # suelta el botón: se abre y aterriza
				held = 1
			if k > 30 and player.state == PlayerController.State.GROUND:
				break
		if held == 0:
			press.call(bi, false)
		await frames(10)
		check("Botonera: botón %s = %s" % [c[0].replace("\n", " "), c[1]], c[1] in moves and landings.all(func(l): return l.quality in ["perfect", "clean"]),
			"%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Mantener el botón del mortal = sigue agrupado y girando (doble o lo que permita la altura)
	for c in [["ATRÁS", "Double Backflip", 0], ["ATRÁS", "Double Backflip", 1]]:
		player.set_spawn(Transform3D(Basis(), Vector3(-35, 0.1, 35)), Vector3.FORWARD)
		player.respawn()
		await frames(20)
		moves.clear(); landings.clear()
		var bi2: int = find.call(c[0])
		press.call(bi2, true)
		var rel := false
		for k in 240:
			await get_tree().physics_frame
			# caso 0: suelta tras la segunda vuelta · caso 1: no suelta nunca (se abre solo si no hay altura)
			if c[2] == 0 and not rel and absf(player.tricks.total_pitch) > TAU * 2.0 - deg_to_rad(100):
				press.call(bi2, false); rel = true
			if k > 30 and player.state == PlayerController.State.GROUND:
				break
		if not rel:
			press.call(bi2, false)
		await frames(10)
		var ok_land: bool = landings.size() > 0 and landings.all(func(l): return l.quality in ["perfect", "clean"])
		# En suelo plano la altura de un mortal real no da para dos vueltas: sale un mortal limpio
		# (los dobles salen con rebote de rondada/flic-flac o desde alturas)
		check("Botonera: mantener ATRÁS %s = gira lo que permite la altura y aterriza limpio" % ["y soltar" if c[2] == 0 else "sin soltar nunca"],
			moves.any(func(m): return m.contains("Backflip")) and ok_land, "%s %s" % [moves, landings.map(func(l): return [l.quality, int(l.error)])])
	# Enlace con botones: RONDADA → FLIC-FLAC (pulsado durante la rondada) → ATRÁS (en la recepción)
	player.set_spawn(Transform3D(Basis(), Vector3(-35, 0.1, 40)), Vector3.FORWARD)
	player.respawn()
	await frames(20)
	moves.clear(); landings.clear()
	var st := {"step": 0}
	for k in 400:
		if st.step == 0:
			press.call(find.call("RONDADA"), true); press.call(find.call("RONDADA"), false); st.step = 1
		elif st.step == 1 and player.state == PlayerController.State.SKILL and player.skill.id == "roundoff" and player.skill.s > 0.5:
			press.call(find.call("FLIC-FLAC"), true); press.call(find.call("FLIC-FLAC"), false); st.step = 2
		elif st.step == 2 and player.state == PlayerController.State.SKILL and player.skill.id == "bhs" and player.skill.get("linked", false):
			press.call(find.call("ATRÁS"), true); st.step = 3; st.t = k
		elif st.step == 3 and k - int(st.t) > 14:
			press.call(find.call("ATRÁS"), false); st.step = 4
		await get_tree().physics_frame
		if st.step == 4 and player.state == PlayerController.State.GROUND and k > 60:
			break
	check("Botonera: enlace RONDADA → FLIC-FLAC → ATRÁS con botones", moves.size() >= 3 and moves[0] == "Round-off" and moves[1] == "Back Handspring" and moves[2] in ["Backflip", "Gainer"], str(moves))
	# Páginas de la rueda: CAMBIAR (tocar = siguiente; deslizar arriba/abajo) y botones nuevos
	touch.ring_page = 0
	var cam: int = find.call("CAMBIAR")
	var cam_pos0 := touch.ring_button_center(cam)
	press.call(cam, true); press.call(cam, false)
	var p1 := touch.ring_page
	var cam2 := touch.ring_buttons().size() - 1
	check("Botonera: CAMBIAR queda en el mismo sitio en todas las páginas", touch.ring_button_center(cam2).distance_to(cam_pos0) < 1.0 and touch.ring_page == 1,
		"%s %s" % [touch.ring_button_center(cam2), cam_pos0])
	var e2 := InputEventScreenTouch.new(); e2.index = 6; e2.position = touch.ring_button_center(cam2); e2.pressed = true
	touch._on_touch(e2)
	var dr := InputEventScreenDrag.new(); dr.index = 6; dr.position = e2.position + Vector2(0, 80); dr.relative = Vector2(0, 80)
	touch._on_drag(dr)
	e2.pressed = false; e2.position = dr.position
	touch._on_touch(e2)
	check("Botonera: CAMBIAR gira la rueda (tocar = siguiente, deslizar abajo = anterior)", p1 == 1 and touch.ring_page == 0, "tras tocar %d, tras deslizar %d" % [p1, touch.ring_page])
	for c in [[0, "PATADA 360", "360 Kick"]]:
		touch.ring_page = c[0]
		player.set_spawn(Transform3D(Basis(), Vector3(-35, 0.1, 35)), Vector3.FORWARD)
		player.respawn()
		await frames(20)
		moves.clear(); landings.clear()
		var bi3: int = find.call(c[1])
		press.call(bi3, true)
		var rel3 := false
		for k in 260:
			await get_tree().physics_frame
			if not rel3 and (k > 30 or maxf(absf(player.tricks.total_pitch), absf(player.tricks.total_spin)) > TAU - deg_to_rad(100)):
				press.call(bi3, false); rel3 = true
			if k > 40 and player.state == PlayerController.State.GROUND and not moves.is_empty():
				break
		if not rel3:
			press.call(bi3, false)
		await frames(10)
		check("Botonera página %s: botón %s = %s" % [TouchControls.RING_PAGES[c[0]].name, c[1], c[2]], c[2] in moves, str(moves))
	touch.ring_page = 0
	touch.size = touch.get_viewport_rect().size
	game.router.scripted = _drive
	Settings.trick_controls = old_mode
	Settings.force_touch_ui = false

## La fuente del juego (la misma en el navegador del iPhone) debe tener todos los caracteres
## que se dibujan: botones, tutorial y biblioteca (sin cuadrados en lugar de flechas).
func t_glyphs() -> void:
	var font := ThemeDB.fallback_font
	var texts: Array[String] = []
	for lbl in TouchControls.all_ring_labels():
		texts.append(String(lbl))
	for st in GameUI.TUTORIAL:
		texts.append(MoveNames.safe(String(st[0])))
	var lib := MoveNames.safe(MoveLibrary.bbcode())
	var rx := RegEx.new()
	rx.compile("\\\\[[^\\\\]]*\\\\]")
	texts.append(rx.sub(lib, "", true))
	var missing := {}
	for t in texts:
		for i in t.length():
			var c := t.unicode_at(i)
			if c > 32 and c != 10 and not font.has_char(c):
				missing[String.chr(c)] = true
	check("Textos: la fuente tiene todos los caracteres (sin cuadrados en el móvil)", missing.is_empty(), str(missing.keys()))

## PIRU (mortal atrás + tirabuzón suelto) · CORK (botón CORK: salta en cork al momento o lo empieza en el aire,
## o el mismo giro dentro de un combo) · ST (caer a un pie y enlazar otro cork).
func t_cork_piru() -> void:
	# Piru: ATRÁS + una vuelta de GIRO, suelto
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.tuck = f < 14; i.jump_held = i.tuck
		i.twist = 1.0 if f >= 10 and f < 36 else 0.0, 160,
		func(): return _f > 16 and player.state == PlayerController.State.GROUND)
	check("Piru: mortal atrás con tirabuzón de 360 suelto = PIRU", "Piru" in moves, str(moves))
	# Cork con el botón CORK: salta en cork al momento
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.cork_request = f == 0
		i.tuck = f < 10; i.jump_held = i.tuck, 160,
		func(): return _f > 16 and player.state == PlayerController.State.GROUND)
	check("Cork: el botón CORK salta en cork al momento (sin pasos previos)", "Cork" in moves and landings.size() > 0 and landings[-1].quality in ["perfect", "clean"],
		"%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Cork quieto por fases: carga + patada (un apoyo) → despegue vertical → inversión →
	# tirabuzón con piernas juntas y brazos cerrados → apertura bajando la pierna de patada
	var rig: BodyRig = game.rig
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var y0 := player.global_position.y
	var ck := {"swing": false, "kick": 0.0, "early_twist": 0.0, "wrap": 0.0, "legs_gap": 9.0, "peak": 0.0, "pitch_at_twist": -1.0, "open_kick_first": false}
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.cork_request = f == 0
		if player.state == PlayerController.State.SKILL and player.skill.id == "cork_swing":
			ck.swing = true
		if player.state == PlayerController.State.AIR and player.tricks.style == "cork":
			var tr := player.tricks
			ck.peak = maxf(ck.peak, player.global_position.y - y0)
			var tw := absf(float(tr.total.twist))
			var pg := absf(float(tr.total.pitch))
			if pg < deg_to_rad(45.0):
				ck.early_twist = maxf(ck.early_twist, tw)
				ck.kick = maxf(ck.kick, (rig.pose.hip_r as Vector3).x)
			if ck.pitch_at_twist < 0.0 and tw > 0.05:
				ck.pitch_at_twist = rad_to_deg(pg)
			if tw > deg_to_rad(90.0) and tw < deg_to_rad(270.0):
				ck.wrap = maxf(ck.wrap, rig.wrap_w)
				ck.legs_gap = minf(ck.legs_gap, absf((rig.pose.hip_l as Vector3).x - (rig.pose.hip_r as Vector3).x) + absf((rig.pose.knee_l as Vector3).x))
			if tr.all_settled() and (rig.pose.hip_l as Vector3).x > (rig.pose.hip_r as Vector3).x + 0.2:
				ck.open_kick_first = true, 200,
		func(): return _f > 20 and player.state == PlayerController.State.GROUND)
	check("Cork quieto: carga y patada de la pierna de atrás antes de despegar (un solo apoyo)", ck.swing and ck.kick > 1.0, str(ck))
	check("Cork quieto: primero se invierte y luego gira (tirabuzón a partir de ~60°)", ck.early_twist < 0.05 and ck.pitch_at_twist > 50.0, str(ck))
	check("Cork quieto: gira con piernas juntas y brazos cerrados al pecho", ck.wrap > 0.6 and ck.legs_gap < 0.6, str(ck))
	check("Cork quieto: abre bajando primero la pierna de patada y recibe limpio", ck.open_kick_first and "Cork" in moves and landings[-1].quality in ["perfect", "clean"],
		"%s %s %s" % [ck, moves, landings.map(func(l): return l.quality)])
	# Cork desde una altura: cayendo del borde, CORK empieza el cork en ese punto
	await place(Vector3(-24.25, 5.75, -10.5), Vector3.FORWARD)
	var hc := {"pressed": false, "y": 0.0}
	await run(func(i, f):
		i.stick_twist = true
		i.move = Vector2(0, 0.5) if not hc.pressed else Vector2.ZERO
		if not hc.pressed and player.state == PlayerController.State.AIR and player.global_position.y < 5.3:
			i.cork_request = true
			hc.pressed = true
			hc.y = player.global_position.y, 240,
		func(): return hc.pressed and player.state != PlayerController.State.AIR)
	check("Cork desde una altura: se decide en el aire, en el punto que quieras (%.1f m)" % hc.y,
		"Cork" in moves, "%s %s" % [moves, landings.map(func(l): return [l.quality, int(l.error)])])
	# ST: CORK pulsado durante el cork = cae a un pie; el siguiente cork lo enlaza el jugador
	# (CORK + SALTO en la recepción). Nada se encadena solo.
	await place(Vector3(-35, 0.1, 40), Vector3.FORWARD)
	var st := {"pressed": false}
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.cork_request = f == 0
		if not st.pressed and player.state == PlayerController.State.AIR and player.tricks.air_time > 0.3:
			i.cork_request = true
			st.pressed = true
		if "ST" in moves and not st.get("solo", false):
			st.solo = true
			st.skill = player.skill.get("id", "") if player.state == PlayerController.State.SKILL else ""
			st.moves_at_st = moves.size()
		# Sin tocar nada tras el ST: no debe salir otro cork solo
		if st.get("solo", false) and not st.get("waited", false):
			st.wait = int(st.get("wait", 0)) + 1
			if st.wait > 20:
				st.waited = true
				st.alone = moves.count("Cork") == 1
		# Ahora el jugador enlaza otro cork a mano: CORK + SALTO en la ventana de la recepción
		if st.get("waited", false) and not st.get("linked", false):
			st.linked = true
			i.cork_request = true; i.jump_pressed = true; i.flick = Vector2(0, -1)
		, 520,
		func(): return st.get("linked", false) and moves.count("Cork") >= 2 and player.state == PlayerController.State.GROUND)
	check("ST: cae a un pie (One-Foot) y no lanza otro cork solo", st.get("alone", false) and st.get("skill", "") == "one_foot",
		"%s %s" % [moves, st])
	var order_ok := moves.size() >= 3 and moves[0] == "Cork" and moves[1] == "ST" and moves.count("Cork") >= 2
	check("ST: el siguiente cork se enlaza a mano (Cork › ST › Cork)", order_ok and landings.all(func(l): return l.quality in ["perfect", "clean"]),
		"%s %s" % [moves, landings.map(func(l): return l.quality)])

## Botonera: SALTO es un joystick de mortales básicos (deslizar ↑ adelante · ← → lateral ·
## ↓ atrás) y el joystick GIRO en el suelo hace ↑ rondada · ↓ flic-flac · ← → rueda ·
## semicírculo desde abajo = scoot · desde arriba = macaco.
func t_salto_giro_sticks() -> void:
	var touch: TouchControls = game.ui.touch
	var old_mode := Settings.trick_controls
	Settings.trick_controls = 5
	Settings.force_touch_ui = true
	touch.visible = true
	touch.size = Vector2(1542, 720)
	check("Modo gestos: sin rueda de botones de movimientos (todo con SALTO y GIRO)", touch.ring_buttons().is_empty(), str(touch.ring_buttons().size()))
	game.router.scripted = Callable()            # entrada real: el táctil
	# Botones de mortal estilo Madness: 1.ª pulsación = mortal directo (agrupado) · 2.ª = abre
	var tapb := func(i: int, idx := 11) -> void:
		var e := InputEventScreenTouch.new(); e.index = idx; e.position = touch.flip_button_center(i); e.pressed = true
		touch._on_touch(e)
		e.pressed = false; touch._on_touch(e)
	var tapj := func() -> void:
		var e := InputEventScreenTouch.new(); e.index = 14; e.position = touch._jump_center(); e.pressed = true
		touch._on_touch(e)
		e.pressed = false; touch._on_touch(e)
	for bc in [[0, "Backflip"], [1, "Frontflip"], [2, "Sideflip"]]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		moves.clear(); landings.clear()
		var st := {"stage": 0, "tucked": false}
		tapj.call()                                              # SALTO
		for k in 240:
			await get_tree().physics_frame
			var tp: float = maxf(absf(player.tricks.total_pitch), absf(player.tricks.total_roll))
			if st.stage == 0 and player.state == PlayerController.State.AIR:
				tapb.call(int(bc[0])); st.stage = 1                       # en el aire: mortal directo
			elif st.stage == 1 and tp > 0.3:
				st.tucked = player.mad_stage == 2
				st.stage = 2
			elif st.stage == 2 and tp > TAU - deg_to_rad(120):
				tapb.call(int(bc[0])); st.stage = 3                       # 2.ª: abre
			if k > 30 and player.state == PlayerController.State.GROUND and not moves.is_empty():
				break
		check("SALTO + botón %s: mortal directo agrupado y la 2.ª pulsación abre = %s limpio" % [TouchControls.FLIP_BTNS[bc[0]][0], bc[1]], bc[1] in moves and st.tucked
			and landings.size() > 0 and landings[-1].quality in ["perfect", "clean"] and st.stage == 3,
			"%s %s etapa %d agrupado %s" % [moves, landings.map(func(l): return l.quality), st.stage, st.tucked])
	# Sin SALTO: el botón solo da un saltito y el mortal no se completa (no cae de pie)
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	moves.clear(); landings.clear()
	tapb.call(0)
	var peak := {"y": 0.0}
	for k in 120:
		await get_tree().physics_frame
		peak.y = maxf(peak.y, player.global_position.y)
		if k > 10 and landings.size() > 0:
			break
	check("Botón de mortal sin SALTO: saltito sin impulso (%.2f m) y no cae limpio" % peak.y, peak.y < 0.6 and landings.size() > 0
		and not (landings[-1].quality in ["perfect", "clean"]), "%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Impulso en SALTO: mantenerlo antes de soltar = salto más alto
	var hgt := []
	for hold in [0.0, 0.3]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		var jc0 := touch._jump_center()
		var je := InputEventScreenTouch.new(); je.index = 13; je.position = jc0; je.pressed = true
		touch._on_touch(je)
		touch._time += hold
		je.pressed = false; touch._on_touch(je)
		var top := {"y": 0.0}
		for k in 90:
			await get_tree().physics_frame
			top.y = maxf(top.y, player.global_position.y)
		hgt.append(top.y)
	check("SALTO: mantenerlo antes de soltar da impulso (%.2f m frente a %.2f m)" % [hgt[1], hgt[0]], hgt[1] > hgt[0] + 0.1, str(hgt))
	# Botón ATRÁS + morado inclinado a la derecha en el aire = Piru (tirabuzón)
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	moves.clear(); landings.clear()
	tapj.call()
	var pst := {"stage": 0}
	await frames(1)
	var te := InputEventScreenTouch.new(); te.index = 12
	for k in 240:
		await get_tree().physics_frame
		if pst.stage == 0 and player.state == PlayerController.State.AIR and player.tricks.air_time > 0.06:
			pst.stage = 1
			tapb.call(0)
			touch.air_mode = true
			var rcc := touch._rot_center()
			te.position = rcc; te.pressed = true; touch._on_touch(te)
			var td := InputEventScreenDrag.new(); td.index = 12; td.position = rcc + Vector2(90, 0); touch._on_drag(td)
		elif pst.stage == 1 and absf(float(player.tricks.total.twist)) > TAU - 0.4:
			te.pressed = false; touch._on_touch(te); pst.stage = 2
		if k > 30 and player.state == PlayerController.State.GROUND and not moves.is_empty():
			break
	if pst.stage == 1:
		te.pressed = false; touch._on_touch(te)
	touch.air_mode = false
	check("Botón ATRÁS + morado inclinado en el aire = Piru", "Piru" in moves, "%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Tricking de suelo desactivado por ahora: el morado no lo ejecuta
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	touch.air_mode = false
	moves.clear()
	var rcd := touch._rot_center()
	var gpd := []
	for q in GestureRecognizer.resample(GestureRecognizer.giro_preview("g_macaco"), 40):
		gpd.append(rcd + Vector2(q.x, -q.y) * touch._rot_radius() * 0.8)
	var gde := InputEventScreenTouch.new(); gde.index = 9; gde.position = gpd[0]; gde.pressed = true
	touch._on_touch(gde)
	for k in range(1, gpd.size()):
		var gdd := InputEventScreenDrag.new(); gdd.index = 9; gdd.position = gpd[k]; touch._on_drag(gdd)
	gde.pressed = false; gde.position = gpd[gpd.size() - 1]; touch._on_touch(gde)
	for k in 90:
		await get_tree().physics_frame
	check("Tricking de suelo desactivado: el macaco dibujado no se ejecuta", not ("Macaco" in moves) and player.state != PlayerController.State.SKILL, str(moves))
	touch.salto_page = 0
	touch.salto_page = 0
	game.router.scripted = _drive
	# Joystick GIRO en el suelo
	for g in [["arriba", [Vector2(0, 1)], "Round-off"], ["abajo", [Vector2(0, -1)], "Back Handspring"], ["lado", [Vector2(1, 0)], "Cartwheel"],
			]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		moves.clear()
		var path: Array = g[1]
		await run(func(i, f):
			i.stick_twist = true
			var idx: int = int(f) / 3
			i.rot = path[idx] if idx < path.size() else Vector2.ZERO, 160,
			func(): return _f > 20 and g[2] in moves)
		check("GIRO %s = %s" % [g[0], g[2]], g[2] in moves, str(moves))
	Settings.trick_controls = old_mode

## Backflip de captura real (CMU): versión desbloqueable; por defecto se usa el clásico.
func t_mocap_backflip() -> void:
	var rig: BodyRig = game.rig
	check("Captura real del backflip cargada (%d fotogramas)" % (rig.mocap["back"].frame_count() if rig.mocap.has("back") else 0), rig.mocap.has("back"), "")
	var old_stats: int = int(SaveData.stats.get("move_Backflip", 0))
	var old_style := Settings.backflip_style
	for case in [["bloqueado: sale el clásico", 0, 1], ["desbloqueado y elegido: sale la captura real", 999, 1], ["desbloqueado pero clásico elegido", 999, 0]]:
		SaveData.stats["move_Backflip"] = int(case[1])
		Settings.backflip_style = int(case[2])
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		var used := {"v": false}
		await run(func(i, f):
			i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
			i.tuck = f > 3 and f < 26; i.jump_held = i.tuck
			used.v = used.v or rig.mocap_active == "back", 140,
			func(): return _f > 20 and player.state == PlayerController.State.GROUND and landings.size() > 0)
		var want: bool = int(case[1]) >= Settings.BACKFLIP_REAL_UNLOCK and int(case[2]) == 1
		check("Backflip %s" % case[0], used.v == want and "Backflip" in moves and landings[-1].quality in ["perfect", "clean"],
			"captura %s %s %s" % [used.v, moves, landings.map(func(l): return l.quality)])
	SaveData.stats["move_Backflip"] = old_stats
	Settings.backflip_style = old_style

## Botón 1 PIE (recepción a un pie y combos a un pie), repetición con cámara libre y cámaras.
func t_one_foot_replay_cameras() -> void:
	var old_mode := Settings.trick_controls
	Settings.trick_controls = 5
	# Mortal atrás + 1 PIE en el aire: cae a un pie; en la ventana, otro mortal atrás enlazado
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var st := {"stage": 0, "one": false, "linked": false}
	await run(func(i, f):
		i.stick_twist = true
		if st.stage == 0:
			i.jump_pressed = true; i.flick = Vector2(0, -1); i.tuck = true; i.jump_held = true
			st.stage = 1
		elif st.stage == 1:
			i.tuck = player.tricks.air_time < 0.35; i.jump_held = i.tuck
			if player.state == PlayerController.State.AIR and player.tricks.air_time > 0.2:
				i.one_foot = true
				st.stage = 2
		elif st.stage == 2:
			if player.state == PlayerController.State.SKILL and player.skill.get("id", "") == "one_foot":
				st.one = true
				if player.skill.get("linked", false):
					i.jump_pressed = true; i.flick = Vector2(0, -1); i.tuck = true; i.jump_held = true
					st.stage = 3
		else:
			i.tuck = player.tricks.air_time < 0.35; i.jump_held = i.tuck
		st.linked = st.linked or (st.stage == 3 and player.state == PlayerController.State.AIR and player.tricks.linked), 300,
		func(): return st.stage == 3 and _f > 60 and player.state == PlayerController.State.GROUND and moves.count("Backflip") + moves.count("Gainer") >= 2)
	check("Botón 1 PIE: cae a un pie y enlaza otro mortal sin apoyar el otro pie", st.one and "One-Foot Landing" in moves and st.linked
		and moves.count("Backflip") + moves.count("Gainer") >= 2, "%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Repetición: reproduce lo grabado y al salir el atleta vuelve a su sitio
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.tuck = f > 3 and f < 26; i.jump_held = i.tuck, 120,
		func(): return _f > 30 and player.state == PlayerController.State.GROUND)
	var live := player.global_position
	var rp: Replay = game.replay
	var started := rp.start()
	var ys := []
	for k in 50:
		await get_tree().process_frame
		ys.append(player.global_position.y)
	var moved: bool = ys.max() - ys.min() > 0.3
	var views_ok := true
	for v in 4:
		rp.view = v
		await get_tree().process_frame
		views_ok = views_ok and get_viewport().get_camera_3d() == rp.cam
	rp.view = 0
	rp.orbit(Vector2(60, 20))
	game.stop_replay()
	await frames(3)
	check("Repetición: reproduce el mortal grabado con cámara libre, POV, dron y seguir, y al salir todo vuelve", started and moved and views_ok
		and player.global_position.distance_to(live) < 0.05 and not rp.playing and player.is_physics_processing(), "start %s mov %s vistas %s" % [started, moved, views_ok])
	# Cámaras de juego: normal, POV (en la cabeza, delante de la cara) y dron (alto)
	var cr: CameraRig = game.camera
	var cam_proc := cr.is_processing()
	cr.set_process(true)                         # (las pruebas la tienen parada; en el juego siempre corre)
	cr.set_view(1)
	await frames(3)
	await get_tree().process_frame
	var head := (game.rig.joints["neck"] as Node3D).global_position
	var pov_ok: bool = get_viewport().get_camera_3d() == cr.alt_cam and cr.alt_cam.global_position.distance_to(head) < 0.45
	cr.set_view(2)
	for k in 90:
		await get_tree().process_frame
	var dron_ok: bool = cr.alt_cam.global_position.y > player.global_position.y + 4.0
	cr.set_view(0)
	await get_tree().process_frame
	cr.set_process(cam_proc)
	check("Cámaras de juego: POV en la cabeza y dron por encima (%.1f m)" % (cr.alt_cam.global_position.y - player.global_position.y), pov_ok and dron_ok and get_viewport().get_camera_3d() == cr.cam, "pov %s dron %s" % [pov_ok, dron_ok])
	check("Eliminados hook y raiz (no hay habilidad ni gesto)", not SkillLibrary.SKILLS.has("hook") and not SkillLibrary.SKILLS.has("raiz")
		and not GestureRecognizer.GIRO_TEMPLATES.has("hook"), "")
	Settings.trick_controls = old_mode

## Control en el aire durante los mortales: en el sitio sin joystick, o llevándolo con el joystick.
func t_air_control() -> void:
	for cc in [["sin joystick: cae casi en el mismo sitio", Vector2.ZERO, 0.0, 0.6], ["joystick adelante: avanza en el aire", Vector2(0, 1), 1.2, 99.0],
			["joystick atrás: retrocede en el aire", Vector2(0, -1), -99.0, -1.0]]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		var p0 := player.global_position
		var mv: Vector2 = cc[1]
		await run(func(i, f):
			i.stick_twist = true
			i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
			i.tuck = f > 3 and f < 26; i.jump_held = i.tuck
			if player.state == PlayerController.State.AIR:
				i.move = mv, 160,
			func(): return _f > 20 and player.state == PlayerController.State.GROUND and landings.size() > 0)
		var d := player.global_position - p0
		var fwd := -d.z                           # mira hacia -z
		var lat := absf(d.x)
		var ok: bool = "Backflip" in moves or "Gainer" in moves
		if float(cc[2]) == 0.0:
			ok = ok and Vector2(d.x, d.z).length() < float(cc[3])
		elif float(cc[2]) > 0.0:
			ok = ok and fwd > float(cc[2])
		else:
			ok = ok and fwd < float(cc[3])
		check("Mortal atrás %s (%.2f m adelante, %.2f m lateral)" % [cc[0], fwd, lat], ok and landings[-1].quality in ["perfect", "clean"], "%s %s" % [moves, landings.map(func(l): return l.quality)])

## Atleta realista: el modelo carga y sus huesos siguen a las articulaciones (mismas animaciones).
func t_human_model() -> void:
	var rig: BodyRig = game.rig
	check("Atleta realista cargado (malla con esqueleto)", rig.human != null and rig.human.skeleton != null and rig.human.skeleton.get_bone_count() > 40, "")
	if rig.human == null:
		return
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var worst := {"d": 1.0}
	var sk := rig.human.skeleton
	await run(func(i, f):
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.tuck = f > 2 and f < 25; i.jump_held = i.tuck
		for pr in [["shoulder_l", "elbow_l", "upperarm_l", "lowerarm_l"], ["hip_r", "knee_r", "thigh_r", "calf_r"]]:
			var a: Vector3 = (rig.joints[pr[0]] as Node3D).global_position
			var b: Vector3 = (rig.joints[pr[1]] as Node3D).global_position
			var ba := (sk.global_transform * sk.get_bone_global_pose(sk.find_bone(pr[2]))).origin
			var bb := (sk.global_transform * sk.get_bone_global_pose(sk.find_bone(pr[3]))).origin
			worst.d = minf(worst.d, (b - a).normalized().dot((bb - ba).normalized())), 120,
		func(): return _f > 20 and player.state == PlayerController.State.GROUND)
	check("Atleta realista: brazos y piernas siguen a la animación durante un mortal (alineación mínima %.3f)" % worst.d, worst.d > 0.97, "")

## Trazo de ejemplo de un gesto (GestureRecognizer.preview_points) en píxeles de pantalla.
func _gpts(id: String, center: Vector2, r: float, mirror := false, n := 40) -> Array:
	var out := []
	for q in GestureRecognizer.resample(GestureRecognizer.preview_points(id), n):
		out.append(center + Vector2(-q.x if mirror else q.x, -q.y) * r)
	return out

## Círculos dibujados con el dedo (d = +1 horario en pantalla), algo ovalados y temblorosos.
func _circle_pts(center: Vector2, r: float, turns: float, d: int, squash := 1.0, wobble := 0.0) -> Array:
	var out := []
	var n := int(36 * turns)
	for i in n + 1:
		var a := -PI * 0.5 + float(d) * TAU * float(i) / 36.0
		var rr := r * (1.0 + wobble * sin(float(i) * 1.7))
		out.append(center + Vector2(cos(a) * rr, sin(a) * rr * squash))
	return out

## Dibuja un trazo con un dedo (pulsar, arrastrar por los puntos y, si release, soltar).
func _draw_on(touch: TouchControls, idx: int, pts: Array, release := true) -> void:
	var e := InputEventScreenTouch.new(); e.index = idx; e.position = pts[0]; e.pressed = true
	touch._on_touch(e)
	for k in range(1, pts.size()):
		var d := InputEventScreenDrag.new(); d.index = idx; d.position = pts[k]; d.relative = pts[k] - pts[k - 1]
		touch._on_drag(d)
	if release:
		e.pressed = false; e.position = pts[pts.size() - 1]
		touch._on_touch(e)

func _loop_events(pts: Array) -> Array:
	var lc := GestureRecognizer.LoopCounter.new(110.0)
	for p in pts:
		lc.feed(p)
	return lc.events

## Sistema de gestos de los tres joysticks: reconocimiento de patrones (dorado), círculos
## (morado), contexto físico, multitáctil y práctica de gestos.
func t_gesture_patterns() -> void:
	# --- Reconocedor: trazos imperfectos (escala, proporción, giro y temblor distintos) ---
	var rng := RandomNumberGenerator.new(); rng.seed = 11
	var expect := {"front": "front", "back": "back", "side_l": "side", "side_r": "side", "cork": "cork", "cork720": "cork720",
		"aerial_twist": "aerial_twist", "gainer": "gainer"}
	for id in GestureRecognizer.TEMPLATES.keys():
		expect[id] = id
	var worst := {"id": "", "rate": 1.0}
	var tot := {"ok": 0, "n": 0}
	for id in expect.keys():
		var ok := 0
		for n in 30:
			var sc := rng.randf_range(0.8, 1.25); var ax := rng.randf_range(0.85, 1.15); var rot := deg_to_rad(rng.randf_range(-8, 8))
			var mirror := n % 2 == 1
			var wob := Vector2(rng.randf_range(-0.03, 0.03), rng.randf_range(-0.03, 0.03))
			var scr := PackedVector2Array()
			var k := 0
			for q in GestureRecognizer.resample(GestureRecognizer.preview_points(id), rng.randi_range(25, 60)):
				var v := Vector2((-q.x if mirror else q.x) * ax, q.y).rotated(rot) * sc + wob * sin(float(k) * 0.4)
				k += 1
				scr.append(Vector2(600, 400) + Vector2(v.x, -v.y) * 95.0)
			if String(GestureRecognizer.recognize_salto(scr, 95.0, {}).id) == expect[id]:
				ok += 1
		tot.ok += ok; tot.n += 30
		if ok / 30.0 < worst.rate:
			worst = {"id": id, "rate": ok / 30.0}
	check("Joystick dorado: %d/%d trazos imperfectos bien reconocidos (peor: %s %d%%)" % [tot.ok, tot.n, worst.id, int(worst.rate * 100.0)],
		tot.ok >= tot.n * 0.95 and worst.rate >= 0.8, "")
	var tiny := PackedVector2Array([Vector2(600, 400), Vector2(604, 402), Vector2(601, 405), Vector2(603, 401)])
	check("Joystick dorado: un toque o un temblor = salto (no acrobacia)", GestureRecognizer.recognize_salto(tiny, 95.0).id == "tap", "")
	var circ := GestureRecognizer.recognize_salto(PackedVector2Array(_circle_pts(Vector2(600, 400), 60, 1.0, 1)), 95.0)
	check("Joystick dorado: un círculo solo no es ningún mortal (los círculos son del morado)", circ.id == "", str(circ))
	# Garabatos al azar (movimientos accidentales): pocos deben pasar por un patrón
	var hits := 0
	for n in 60:
		var scr := PackedVector2Array([Vector2(600, 400)])
		var dirv := Vector2.RIGHT.rotated(rng.randf() * TAU)
		for k in 14:
			dirv = dirv.rotated(rng.randf_range(-1.6, 1.6))
			scr.append(scr[scr.size() - 1] + dirv * rng.randf_range(10, 30))
		var r := GestureRecognizer.recognize_salto(scr, 95.0)
		if r.kind in ["pattern", "parkour"]:
			hits += 1
	check("Garabatos al azar: %d de 60 se toman por un patrón complejo" % hits, hits <= 15, "")
	# --- Joystick morado: círculos = tirabuzones ---
	var c0 := Vector2(800, 450)
	check("Morado: círculo horario = tirabuzón derecho", _loop_events(_circle_pts(c0, 55, 1.05, 1)) == [1], str(_loop_events(_circle_pts(c0, 55, 1.05, 1))))
	check("Morado: círculo antihorario = tirabuzón izquierdo", _loop_events(_circle_pts(c0, 55, 1.05, -1)) == [-1], "")
	check("Morado: dos círculos = doble tirabuzón", _loop_events(_circle_pts(c0, 50, 2.05, 1)) == [1, 1], str(_loop_events(_circle_pts(c0, 50, 2.05, 1))))
	check("Morado: tres círculos = triple tirabuzón", _loop_events(_circle_pts(c0, 45, 3.05, -1)) == [-1, -1, -1], str(_loop_events(_circle_pts(c0, 45, 3.05, -1))))
	var combo := _circle_pts(c0, 50, 1.0, 1) + _circle_pts(c0, 50, 1.05, -1)
	check("Morado: círculo horario y otro antihorario = combinado", _loop_events(combo) == [1, -1], str(_loop_events(combo)))
	check("Morado: círculo imperfecto (ovalado y tembloroso) también cuenta", _loop_events(_circle_pts(c0, 60, 1.05, 1, 0.6, 0.12)) == [1], "")
	check("Morado: tres cuartos de círculo no cuentan", _loop_events(_circle_pts(c0, 55, 0.75, 1)).is_empty(), "")
	var jit := []
	for k in 40:
		jit.append(c0 + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)))
	check("Morado: un temblor del dedo no es un tirabuzón", _loop_events(jit).is_empty(), str(_loop_events(jit)))
	var gname := GestureRecognizer.twist_name([1, -1])
	check("Morado: nombre del combinado", gname == "TIRABUZÓN COMBINADO", gname)
	# Tirabuzón combinado en el sistema de acrobacias: una vuelta a un lado y otra al otro
	var ts := TrickSystem.new()
	ts.reset("stand", 0.0)
	var a1 := ts.add_twist_turn(1, 3.0, player.t)
	var a2 := ts.add_twist_turn(-1, 3.0, player.t)
	var flipped := {"v": false}
	for k in 300:
		ts.step(1.0 / 60.0, 0.0, 3.0 - k / 60.0, 1.0, player.t)
		flipped.v = flipped.v or (ts.dir.twist == -1)
	var ev := ts.evaluate()
	check("Tirabuzón combinado: gira a un lado, cambia de sentido y suma dos vueltas", a1 and a2 and flipped.v and int(ev.get("twist_halves", 0)) == 4 and String(ev.get("name", "")).contains("Combinado"), str(ev))
	ts.reset("stand", 0.0)
	var fits := 0
	for k in 5:
		if ts.add_twist_turn(1, 0.6, player.t):
			fits += 1
	check("Tirabuzones: solo se aceptan las vueltas que caben en el tiempo de vuelo (%d de 5 en 0,6 s)" % fits, fits >= 1 and fits < 5, "")

	# --- Patrones ejecutados por el atleta (mismas mecánicas que los botones) ---
	var mode_before := Settings.trick_controls
	Settings.trick_controls = 5
	for pc in [[{"id": "cork", "loops": 1, "twist": 1}, ["Cork"]], [{"id": "cork720", "loops": 2, "twist": 1}, ["Cork 720"]],
			[{"id": "aerial_twist", "loops": 1, "twist": 1}, ["Aerial Twist"]], [{"id": "webster"}, ["Webster", "Frontflip"]],
			[{"id": "gainer", "loops": 1}, ["Gainer", "Backflip"]], [{"id": "aerial"}, ["Aerial"]]]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		var pat: Dictionary = pc[0]
		await run(func(i, f):
			i.stick_twist = true
			if f == 0:
				i.pattern = pat, 240,
			func(): return _f > 30 and player.state == PlayerController.State.GROUND and not moves.is_empty())
		var hit := false
		for m in pc[1]:
			hit = hit or m in moves
		check("Patrón %s = %s" % [String(pat.id).to_upper(), pc[1][0]], hit and landings.size() > 0 and landings[-1].quality in ["perfect", "clean"],
			"%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Círculo en el suelo = salto con giro de 360; durante un mortal = tirabuzón añadido
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.stick_twist = true
		if f == 0:
			i.twist_loops.append(1), 160,
		func(): return _f > 30 and player.state == PlayerController.State.GROUND)
	check("Círculo morado en el suelo = giro de 360 en el aire", "360 Kick" in moves, str(moves))
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		if f == 14:
			i.twist_loops.append(1), 200,
		func(): return _f > 30 and player.state == PlayerController.State.GROUND)
	check("Mortal atrás + círculo morado = Piru (tirabuzón completo) y aterriza", "Piru" in moves and landings.size() > 0 and landings[-1].quality in ["perfect", "clean"],
		"%s %s" % [moves, landings.map(func(l): return l.quality)])
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		if f == 8:
			i.twist_loops.append_array([1, 1, 1]), 200,
		func(): return _f > 30 and player.state == PlayerController.State.GROUND)
	check("Tres círculos en un mortal en el suelo: hace los que caben y no se estrella", landings.size() > 0 and landings[-1].quality != "crash",
		"%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Parkour: patrones con obstáculo / pared
	var park := func(start: Vector3, stick: float, sprint: bool, pat: Dictionary, at_z: float) -> void:
		await place(start, Vector3.FORWARD)
		var st := {"p": false, "f": 0}
		await run(func(i, f):
			i.move = Vector2(0, stick); i.sprint = sprint
			if not st.p and player.global_position.z <= at_z:
				i.pattern = pat
				st.p = true
				st.f = f, 300,
			func(): return st.p and _f > st.f + 70 and player.state in [PlayerController.State.GROUND, PlayerController.State.HANG])
	await park.call(Vector3(0, 0.1, -8), 1.0, true, {"id": "kong"}, -11.0)
	check("Patrón KONG (dos arcos) con obstáculo = Kong Vault", "Kong Vault" in moves, str(moves))
	await park.call(Vector3(0, 0.1, 2), 0.8, false, {"id": "vault"}, -4.0)
	check("Patrón VAULT (U invertida) con obstáculo = vault", moves.any(func(m): return String(m).ends_with("Vault")), str(moves))
	await park.call(Vector3(0, 0.1, -34.5), 0.8, false, {"id": "climb"}, -34.0)
	check("Patrón ESCALADA junto a la pared = Wall Climb", "Wall Climb" in moves, str(moves))
	await park.call(Vector3(0, 0.1, -34.5), 0.8, false, {"id": "palm", "loops": 1}, -34.0)
	check("Patrón PALM FLIP junto a la pared = manos a la pared y mortal atrás", "Palm Flip" in moves and not ("Wall Climb" in moves), str(moves))
	await park.call(Vector3(0, 0.1, 2), 0.8, false, {"id": "speed"}, -4.0)
	check("Patrón PASAVALLAS con obstáculo = Speed Vault", "Speed Vault" in moves, str(moves))
	await park.call(Vector3(0, 0.1, 2), 0.8, false, {"id": "reverse"}, -4.0)
	check("Patrón REVERSO con obstáculo = Reverse Vault", "Reverse Vault" in moves, str(moves))
	await park.call(Vector3(0, 0.1, -34.5), 0.8, false, {"id": "wall_flip"}, -34.0)
	check("Patrón WALL FLIP junto a la pared = trepa y mortal atrás desde la pared", "Wall Climb" in moves and ("Wall Flip" in moves or "Wall Gainer" in moves), str(moves))
	await park.call(Vector3(11.0, 0.1, 3), 1.0, true, {"id": "wall_run"}, 1.0)
	check("Patrón WALL RUN con pared al lado = Wall Run", "Wall Run" in moves, str(moves))
	await park.call(Vector3(0, 0.1, -32.0), 0.9, false, {"id": "cat_leap"}, -33.4)
	check("Patrón CAT LEAP hacia la pared = se agarra", "Cat Leap" in moves or "Ledge Grab" in moves or "Wall Climb" in moves, str(moves))
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var pv := {"v": 9.0}
	await run(func(i, f):
		i.move = Vector2(0, 0.7)
		if f == 25:
			i.pattern = {"id": "precision"}, 200,
		func(): return landings.size() > 0 and _f > 30)
	pv.v = player.speed()
	check("Patrón PRECISIÓN = salta y clava la recepción (%.1f m/s al caer)" % pv.v, "Precision Jump" in moves and pv.v < 1.0, str(moves))
	await place(Vector3(-35, 2.9, 35), Vector3.FORWARD)
	await run(func(i, f):
		i.move = Vector2(0, 0.6)
		if f == 3:
			i.pattern = {"id": "roll"}, 160,
		func(): return landings.size() > 0 and _f > 40)
	check("Patrón RODAR en el aire = voltereta al aterrizar", "Safety Roll" in moves or "Roll" in moves, str(moves))
	# Contexto: sin obstáculo ni pared, el patrón de parkour no se ejecuta y dice por qué
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var ctx := player.gesture_context()
	var vres := GestureRecognizer.recognize_salto(PackedVector2Array(_gpts("vault", Vector2(600, 400), 90)), 95.0, {"ctx": ctx})
	check("Sin obstáculo delante, la U invertida no hace un vault (y explica el motivo)", vres.id != "vault" or (not vres.ok and vres.reason != ""), str(vres))
	var wres := GestureRecognizer.recognize_salto(PackedVector2Array(_gpts("climb", Vector2(600, 400), 90)), 95.0, {"ctx": ctx})
	check("Sin pared, el zigzag de escalada no se ejecuta (motivo: %s)" % wres.get("reason", ""), not wres.ok, str(wres))

	# --- Táctil real: los tres joysticks ---
	var touch: TouchControls = game.ui.touch
	var old_mode := mode_before
	Settings.trick_controls = 5
	Settings.force_touch_ui = true
	touch.visible = true
	touch.size = Vector2(1542, 720)
	touch.salto_page = 0
	game.router.scripted = Callable()
	var jc := touch._jump_center()
	var jr := touch._jump_radius()
	var rc := touch._rot_center()
	check("Joystick morado algo más arriba que el dorado (y a su izquierda)", rc.y < jc.y and rc.x < jc.x, "%s %s" % [rc, jc])
	for tc in [["cork", "Cork"], ["webster", "Webster"], ["aerial", "Aerial"]]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		touch.air_mode = false
		jc = touch._jump_center(); jr = touch._jump_radius()
		_draw_on(touch, 7, _gpts(tc[0], jc, jr * 0.9))
		for k in 240:
			await get_tree().physics_frame
			if k > 30 and player.state == PlayerController.State.GROUND and not moves.is_empty():
				break
		check("Táctil: dibujar %s en el joystick dorado = %s" % [tc[0].to_upper(), tc[1]], tc[1] in moves or (tc[1] == "Webster" and "Frontflip" in moves), str(moves))
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	rc = touch._rot_center()
	_draw_on(touch, 8, _circle_pts(rc + Vector2(0, -20), 45, 1.08, 1))
	for k in 150:
		await get_tree().physics_frame
		if k > 30 and player.state == PlayerController.State.GROUND and not moves.is_empty():
			break
	check("Táctil: círculo en el joystick morado (suelo) = giro de 360", "360 Kick" in moves, str(moves))
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	rc = touch._rot_center()
	_draw_on(touch, 8, [rc, rc + Vector2(0, -40), rc + Vector2(0, -90)])
	for k in 120:
		await get_tree().physics_frame
		if "Round-off" in moves:
			break
	check("Táctil: línea hacia arriba en el morado (suelo) = rondada", "Round-off" in moves, str(moves))
	# Multitáctil: correr, mortal y tirabuzón a la vez, cada dedo en su joystick
	game.router.enabled = false
	touch.collect()
	jc = touch._jump_center(); jr = touch._jump_radius(); rc = touch._rot_center()
	var mv0 := touch._joy_idle()
	var em := InputEventScreenTouch.new(); em.index = 1; em.position = mv0; em.pressed = true
	touch._on_touch(em)
	var dm := InputEventScreenDrag.new(); dm.index = 1; dm.position = mv0 + Vector2(0, -90); dm.relative = Vector2(0, -90)
	touch._on_drag(dm)
	var bt := InputEventScreenTouch.new(); bt.index = 2; bt.position = touch.flip_button_center(0); bt.pressed = true
	touch._on_touch(bt)
	touch.air_mode = true                        # el tirabuzón se hace en el aire inclinando el morado
	_draw_on(touch, 3, [rc, rc + Vector2(-40, 0), rc + Vector2(-90, 0)], false)
	var fr := touch.collect()
	touch.air_mode = false
	check("Multitáctil: joystick azul, botón de mortal y morado a la vez (correr + mortal + tirabuzón)",
		fr.move.y > 0.5 and fr.flip_press == -2 and fr.rot.x < -0.5, "move %s botón %d giro %s" % [fr.move, fr.flip_press, fr.rot])
	bt.pressed = false; touch._on_touch(bt)
	var e3 := InputEventScreenTouch.new(); e3.index = 3; e3.position = rc; e3.pressed = false
	touch._on_touch(e3)
	em.pressed = false; touch._on_touch(em)
	# Un dedo que empieza en el morado no activa el dorado aunque pase por encima
	_draw_on(touch, 4, [rc, (rc + jc) * 0.5, jc, jc + Vector2(0, -80)])
	var fr2 := touch.collect()
	check("Un dedo que empieza en un joystick no activa otro", fr2.flick == Vector2.ZERO and fr2.pattern.is_empty() and not fr2.jump_pressed, "flick %s %s" % [fr2.flick, fr2.pattern])
	# Salto de precisión: línea corta hacia arriba y un toque
	_draw_on(touch, 2, [jc, jc + Vector2(0, -26), jc + Vector2(0, -52)])
	touch._time += 0.1
	_draw_on(touch, 2, [jc])
	var fr3 := touch.collect()
	check("Táctil: línea corta + toque = salto de precisión", String(fr3.pattern.get("id", "")) == "precision", str(fr3.pattern))
	# Práctica de gestos
	touch.toggle_training(true)
	touch.train_i = TouchControls.TRAIN.map(func(x): return x[0]).find("cork")
	_draw_on(touch, 2, _gpts("cork", jc, jr * 0.9))
	var okc: bool = touch.train_done.has("cork") and touch.train_last.ok
	touch.train_i = TouchControls.TRAIN.map(func(x): return x[0]).find("webster")
	_draw_on(touch, 2, [jc, jc + Vector2(0, -45), jc + Vector2(0, -95)])
	check("Práctica: el gesto pedido se marca como hecho y uno distinto se avisa", okc and not touch.train_last.ok and not touch.train_done.has("webster"), str(touch.train_last))
	var ids := TouchControls.TRAIN.map(func(x): return x[0])
	var missing := []
	for need in ["aerial", "aerial_twist", "cork", "cork720", "webster", "gainer", "palm", "speed", "reverse",
			"vault", "kong", "wall_run", "wall_flip", "climb", "ledge_grab", "cat_leap", "precision", "roll", "wall_climb",
			]:
		if not need in ids:
			missing.append(need)
	check("Práctica: están todos los gestos pedidos (%d)" % ids.size(), missing.is_empty(), str(missing))
	touch.toggle_training(false)
	game.router.enabled = true
	collect_cleanup(touch)
	game.router.scripted = _drive
	Settings.trick_controls = old_mode

func collect_cleanup(touch: TouchControls) -> void:
	touch._fingers.clear()
	touch._await_tap = {}
	touch.collect()

## Como en el vídeo de referencia: una caída grande se recibe a cuatro apoyos (manos al suelo)
## y, tras recibir, los brazos se abren a los lados para equilibrarse.
func t_reference_landings() -> void:
	var rig: BodyRig = game.rig
	await place(Vector3(-35, 2.9, 35), Vector3.FORWARD)
	var r := {"hands": 0, "gap": 9.0, "arms_out": 0.0, "imp": 0.0}
	await run(func(i, f):
		if landings.size() > 0:
			r.imp = landings[-1].impact
			if rig.contact_w.hl > 0.9 and rig.contact_w.hr > 0.9:
				r.hands += 1
				r.gap = minf(r.gap, maxf(rig.limb_end("hl").y, rig.limb_end("hr").y) - rig.ground_y)
			r.arms_out = maxf(r.arms_out, absf((rig.pose.shoulder_l as Vector3).z)), 120,
		func(): return landings.size() > 0 and player.land_timer > 1.0)
	check("Caída grande (%.1f m/s): recepción a cuatro apoyos con las manos en el suelo" % r.imp,
		r.imp > 9.0 and r.hands >= 5 and r.gap < 0.1 and landings[-1].quality in ["perfect", "clean"], "frames %d hueco %.2f %s" % [r.hands, r.gap, landings.map(func(l): return l.quality)])
	check("Tras recibir, brazos abiertos a los lados para equilibrarse", r.arms_out > 0.8, "%.2f" % r.arms_out)

## Cuerpo con piel: una sola malla continua (tronco, brazos y piernas) cuyo esqueleto sigue a las
## articulaciones en todo momento (también en pleno mortal, con la IK de las manos).
func t_skin_body() -> void:
	var rig: BodyRig = game.rig
	check("Personaje: cuerpo continuo con piel y esqueleto de 11 huesos", rig.skin_body != null and rig.skin_body.skeleton.get_bone_count() == 11
		and rig.skin_body.mesh_instance.mesh.get_surface_count() == 1, "")
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var worst := {"d": 0.0}
	await run(func(i, f):
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.tuck = f > 2 and f < 25; i.jump_held = i.tuck
		var sk: Skeleton3D = rig.skin_body.skeleton
		for n in ["shoulder_l", "elbow_l", "elbow_r", "knee_l", "knee_r", "neck"]:
			var bi := sk.find_bone(n)
			var bt: Transform3D = sk.global_transform * sk.get_bone_global_pose(bi)
			var jt: Transform3D = (rig.joints[n] as Node3D).global_transform
			worst.d = maxf(worst.d, bt.origin.distance_to(jt.origin) + (bt.basis.y - jt.basis.y).length()), 120,
		func(): return _f > 20 and player.state == PlayerController.State.GROUND)
	check("Personaje: la piel sigue a las articulaciones durante un mortal (desvío %.4f)" % worst.d, worst.d < 0.01, str(worst))

## Agrupado real: en los mortales agrupados las manos agarran las espinillas.
func t_tuck_grab() -> void:
	var rig: BodyRig = game.rig
	for c in [["Backflip", Vector2(0, -1)], ["Frontflip", Vector2(0, 1)], ["Sideflip", Vector2(1, 0)]]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		var r := {"frames": 0, "best": 9.0}
		await run(func(i, f):
			i.stick_twist = true
			i.jump_pressed = f == 0; i.flick = c[1] if f == 0 else Vector2.ZERO
			i.tuck = f < 40; i.jump_held = i.tuck
			if player.state == PlayerController.State.AIR and rig.grab_w > 0.95:
				var d := maxf(rig.limb_end("hl").distance_to(rig.shin_grip("l")), rig.limb_end("hr").distance_to(rig.shin_grip("r")))
				r.best = minf(r.best, d)
				if d < 0.05: r.frames += 1, 160,
			func(): return _f > 16 and player.state == PlayerController.State.GROUND)
		check("Agrupado real en %s: las manos agarran las espinillas (%d fotogramas)" % [c[0], r.frames],
			c[0] in moves and r.frames >= 6, "%s mejor %.3f" % [moves, r.best])

## Tirabuzón real: mientras gira, los brazos se cruzan pegados al pecho.
func t_twist_wrap() -> void:
	var rig: BodyRig = game.rig
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var r := {"frames": 0, "best": 9.0}
	await run(func(i, f):
		i.stick_twist = true
		i.jump_pressed = f == 0; i.flick = Vector2(0, -1) if f == 0 else Vector2.ZERO
		i.tuck = f < 12; i.jump_held = i.tuck
		i.twist = 1.0 if f >= 10 and f < 36 else 0.0
		if player.state == PlayerController.State.AIR and rig.wrap_w > 0.95:
			var d := maxf(rig.limb_end("hl").distance_to(rig.chest_grip("l")), rig.limb_end("hr").distance_to(rig.chest_grip("r")))
			r.best = minf(r.best, d)
			if d < 0.05: r.frames += 1, 160,
		func(): return _f > 16 and player.state == PlayerController.State.GROUND)
	check("Tirabuzón (Piru): brazos cruzados pegados al pecho mientras gira (%d fotogramas)" % r.frames,
		"Piru" in moves and r.frames >= 6, "%s mejor %.3f" % [moves, r.best])


## GIRO = tirabuzón con el cuerpo estirado (nunca acelera el mortal); botón de mortal = agruparse.
## Tras un tirabuzón, volver a pulsar un mortal pide otra vuelta (front + ½ giro + ATRÁS = doble).
## 1 PIE pulsado antes de saltar también vale.
func t_twist_layout_tuck() -> void:
	var touch: TouchControls = game.ui.touch
	var old_mode := Settings.trick_controls
	Settings.trick_controls = 5
	Settings.force_touch_ui = true
	touch.visible = true
	touch.size = Vector2(1542, 720)
	game.router.scripted = Callable()
	var tap := func(pos: Vector2, idx: int) -> void:
		var e := InputEventScreenTouch.new(); e.index = idx; e.position = pos; e.pressed = true
		touch._on_touch(e)
		e.pressed = false; touch._on_touch(e)
	var hold_jump := func(t: float) -> void:
		var e := InputEventScreenTouch.new(); e.index = 14; e.position = touch._jump_center(); e.pressed = true
		touch._on_touch(e); touch._time += t
		e.pressed = false; touch._on_touch(e)
	for cs in ["piru_largo", "doble_front_back"]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		moves.clear(); landings.clear()
		hold_jump.call(0.3)
		var st := {"stage": 0, "maxp": 0.0, "maxt": 0.0, "layout": true}
		var te := InputEventScreenTouch.new(); te.index = 12
		for k in 300:
			await get_tree().physics_frame
			st.maxp = maxf(st.maxp, absf(player.tricks.total_pitch)); st.maxt = maxf(st.maxt, absf(player.tricks.total_twist))
			if st.stage == 0 and player.state == PlayerController.State.AIR:
				tap.call(touch.flip_button_center(0 if cs == "piru_largo" else 1), 11); st.stage = 1
			elif st.stage == 1 and player.tricks.air_time > (0.08 if cs == "piru_largo" else 0.12):
				touch.air_mode = true
				var rc := touch._rot_center()
				te.position = rc; te.pressed = true; touch._on_touch(te)
				var td := InputEventScreenDrag.new(); td.index = 12; td.position = rc + Vector2(90, 0); touch._on_drag(td)
				st.stage = 2
			elif st.stage == 2:
				if player.tricks.air_time > 0.35 and player.tricks.tuck_amount > 0.2:
					st.layout = false                     # girando con GIRO debe ir estirado
				var stop := 99.0 if cs == "piru_largo" else PI - 0.25
				if absf(player.tricks.total_twist) > stop or player.time_to_ground() < 0.15:
					te.pressed = false; touch._on_touch(te); touch.air_mode = false; st.stage = 3
					if cs == "doble_front_back":
						tap.call(touch.flip_button_center(0), 11)
			if st.stage >= 3 and player.state == PlayerController.State.GROUND:
				break
		if st.stage == 2:
			te.pressed = false; touch._on_touch(te); touch.air_mode = false
		var clean: bool = landings.size() > 0 and landings[-1].quality in ["perfect", "clean"]
		if cs == "piru_largo":
			check("GIRO mantenido en un backflip: más tirabuzón (%d°) y el mortal no se dobla (%d°), estirado" % [rad_to_deg(st.maxt), rad_to_deg(st.maxp)],
				st.maxt > deg_to_rad(500) and st.maxp < deg_to_rad(400) and st.layout and clean, "%s %s" % [moves, st])
		else:
			check("Front + medio tirabuzón + ATRÁS = doble mortal (%d° mortal, %d° giro)" % [rad_to_deg(st.maxp), rad_to_deg(st.maxt)],
				st.maxp > deg_to_rad(700) and absf(st.maxt - PI) < 0.3 and clean, "%s %s" % [moves, st])
	# 1 PIE pulsado antes de saltar: la recepción es a un pie y enlaza otro mortal
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	moves.clear(); landings.clear()
	tap.call(touch.one_foot_center(), 15)
	await frames(2)
	hold_jump.call(0.0)
	var o := {"stage": 0}
	for k in 300:
		await get_tree().physics_frame
		if o.stage == 0 and player.state == PlayerController.State.AIR:
			tap.call(touch.flip_button_center(0), 11); o.stage = 1
		elif o.stage == 1 and player.state == PlayerController.State.SKILL and player.skill.get("id", "") == "one_foot" and player.skill.get("linked", false):
			tap.call(touch.flip_button_center(0), 11); o.stage = 2
		if o.stage == 2 and k > 60 and player.state == PlayerController.State.GROUND and moves.count("Backflip") >= 2:
			break
	check("1 PIE pulsado antes de saltar: cae a un pie y enlaza otro mortal", "One-Foot Landing" in moves and moves.count("Backflip") >= 2,
		"%s %s" % [moves, landings.map(func(l): return l.quality)])
	touch.air_mode = false
	Settings.trick_controls = old_mode
	game.router.scripted = _drive


## CHUTADA (mortal chutado): diagonal recta hacia arriba en el joystick dorado = patada como a un
## balón y después un backflip normal, sin tirabuzón. Con GIRO durante el mortal pasa a cork.
func t_chutada() -> void:
	var g := GestureRecognizer.recognize_salto(PackedVector2Array([Vector2(0, 0), Vector2(40, -40), Vector2(80, -80)]), 100.0)
	check("Gesto: diagonal recta hacia arriba = CHUTADA", String(g.get("id", "")) == "chutada", str(g))
	var touch: TouchControls = game.ui.touch
	var old_mode := Settings.trick_controls
	Settings.trick_controls = 5
	Settings.force_touch_ui = true
	touch.visible = true
	touch.size = Vector2(1542, 720)
	game.router.scripted = Callable()
	for with_giro in [false, true]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		moves.clear(); landings.clear()
		touch.air_mode = false
		await _draw_on(touch, 16, _gpts("chutada", touch._jump_center(), touch._jump_radius() * 0.9))
		var st := {"stage": 0, "tw": 0.0, "style": ""}
		var te := InputEventScreenTouch.new(); te.index = 12
		for k in 300:
			await get_tree().physics_frame
			st.tw = maxf(st.tw, absf(player.tricks.total_twist))
			if player.state == PlayerController.State.AIR and st.style == "":
				st.style = player.tricks.style
			if with_giro and st.stage == 0 and player.state == PlayerController.State.AIR and player.tricks.air_time > 0.1:
				touch.air_mode = true
				var rc := touch._rot_center()
				te.position = rc; te.pressed = true; touch._on_touch(te)
				var td := InputEventScreenDrag.new(); td.index = 12; td.position = rc + Vector2(90, 0); touch._on_drag(td)
				st.stage = 1
			elif st.stage == 1 and (absf(player.tricks.total_twist) > TAU - 0.5 or player.time_to_ground() < 0.12):
				te.pressed = false; touch._on_touch(te); touch.air_mode = false; st.stage = 2
			if k > 20 and player.state == PlayerController.State.GROUND and not moves.is_empty():
				break
		if st.stage == 1:
			te.pressed = false; touch._on_touch(te)
		touch.air_mode = false
		var clean: bool = landings.size() > 0 and landings[-1].quality in ["perfect", "clean"]
		if not with_giro:
			check("Chutada: patada y mortal atrás sin tirabuzón (%s)" % str(moves), "Chutada" in moves and st.tw < 0.3 and st.style == "chutada" and clean,
				"%s %s %s" % [moves, landings.map(func(l): return l.quality), st])
		else:
			check("Chutada + GIRO = Cork (%s)" % str(moves), moves.any(func(m): return String(m).begins_with("Cork")) and clean,
				"%s %s %s" % [moves, landings.map(func(l): return l.quality), st])
	Settings.trick_controls = old_mode
	game.router.scripted = _drive
