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
	await t_ground_flick_buffer()
	await t_overrotation_crash()
	await t_speed_vault()
	await t_kong_vault()
	await t_wall_run()
	await t_ledge_climb()
	await t_drop_hard_vs_roll()
	await t_precision()
	await t_water()
	await t_touch()
	await t_dual_stick()
	await t_new_controls()
	await t_touch_layout()
	await t_landing_feel()
	await t_new_tricks()
	await t_vault_variants()
	await t_combo_logic()
	await t_respawn_repeat()
	await t_modes()

func t_locomotion() -> void:
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var st := {"max": 0.0}
	await run(func(i, f):
		i.move = Vector2(0, 1); i.sprint = true
		st.max = maxf(st.max, player.speed()), 60)
	check("Carrera: alcanza sprint", st.max > 9.0, "vel max %.2f" % st.max)
	check("Carrera: sigue en el suelo", player.state == PlayerController.State.GROUND, PlayerController.STATE_NAMES[player.state])
	await run(func(i, f): i.move = Vector2(0, 0.6), 40)
	check("Carrera: desacelera a trote", player.speed() < 6.0 and player.speed() > 3.5, "vel %.2f" % player.speed())
	var f0 := player.facing
	await run(func(i, f): i.move = Vector2(1, 0), 40)
	check("Giro: cambia orientación", f0.angle_to(player.facing) > 1.0, "ángulo %.2f" % f0.angle_to(player.facing))
	await run(func(i, f): pass, 40)
	check("Frenado: se detiene", player.speed() < 0.2, "vel %.2f" % player.speed())

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
		func(): return player.state == PlayerController.State.GROUND and _f > 5)
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
		func(): return player.state == PlayerController.State.GROUND and _f > 5)
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
		func(): return player.state == PlayerController.State.GROUND and _f > 5)
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
		func(): return _f > 20 and player.state == PlayerController.State.GROUND)
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
		func(): return player.state == PlayerController.State.CRASH or (player.state == PlayerController.State.GROUND and _f > 5))
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
		func(): return player.state == PlayerController.State.CRASH or (player.state == PlayerController.State.GROUND and _f > 5))
	check("Pro: abrir a tiempo aterriza el backflip", "Backflip" in moves, str(moves) + str(landings.map(func(l): return [l.quality, int(l.error)])))

func _run_at_obstacle(start: Vector3, stick: float, sprint: bool, jump_z: float) -> void:
	await place(start, Vector3.FORWARD)
	var st := {"pressed": false}
	await run(func(i, f):
		i.move = Vector2(0, stick); i.sprint = sprint
		i.jump_pressed = not st.pressed and player.global_position.z <= jump_z
		st.pressed = st.pressed or i.jump_pressed, 200,
		func(): return st.pressed and _f > 5 and player.state == PlayerController.State.GROUND)

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
	check("Doble joystick: analógico (inclinación parcial sin truco, a fondo = backflip)", partial and fr.flick.y < -0.9 and fr.rot.y < -0.95, "rot %s flick %s" % [fr.rot, fr.flick])
	check("Doble joystick: multitáctil (mover y rotar a la vez)", fr.move.y > 0.9 and fr.rot.length() > 0.9, "move %s rot %s" % [fr.move, fr.rot])
	# Mantener inclinado no repite el truco; deslizar a un lado sí (tirabuzón)
	drg.call(1, rc + Vector2(0, trav * 1.02))
	fr = touch.collect()
	var no_repeat := fr.flick == Vector2.ZERO
	drg.call(1, rc + Vector2(trav, 0))
	touch._time += 0.1
	drg.call(1, rc + Vector2(trav * 1.01, 0))
	fr = touch.collect()
	check("Doble joystick: mantener no repite; cambiar de dirección añade (tirabuzón)", no_repeat and fr.flick.x > 0.9, "flick %s" % fr.flick)
	# Volver al centro e inclinar otra vez = otra vuelta
	drg.call(1, rc + Vector2(0, trav * 0.1))
	drg.call(1, rc + Vector2(0, trav))
	fr = touch.collect()
	check("Doble joystick: volver a inclinar = otra vuelta", fr.flick.y < -0.9, "flick %s" % fr.flick)
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
	check("Botones: VAULT + joystick derecho + correr a la vez", fr.vault_pressed and fr.flick.y > 0.9 and fr.move.y > 0.9, "vault %s flick %s move %s" % [fr.vault_pressed, fr.flick, fr.move])
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

## Controles definitivos: VAULT, AGARRAR, tricking de suelo con el joystick derecho, Kip-up.
func t_new_controls() -> void:
	# VAULT (sin SALTO) supera el obstáculo
	await place(Vector3(0, 0.1, 2), Vector3.FORWARD)
	var st := {"p": false}
	await run(func(i, f):
		i.move = Vector2(0, 0.8)
		i.vault_pressed = not st.p and player.global_position.z <= -4.85
		st.p = st.p or i.vault_pressed, 200,
		func(): return st.p and _f > 5 and player.state == PlayerController.State.GROUND)
	check("VAULT: botón propio supera el obstáculo", ("Speed Vault" in moves or "Step Vault" in moves) and player.global_position.z < -6.5, "%s z %.2f" % [moves, player.global_position.z])
	# VAULT + joystick derecho lateral = Reverse Vault
	await place(Vector3(0, 0.1, -8), Vector3.FORWARD)
	st.p = false
	await run(func(i, f):
		i.move = Vector2(0, 1.0); i.sprint = true
		i.rot = Vector2(1, 0) if player.global_position.z <= -12.0 else Vector2.ZERO
		i.vault_pressed = not st.p and player.global_position.z <= -12.9
		st.p = st.p or i.vault_pressed, 200,
		func(): return st.p and _f > 5 and player.state == PlayerController.State.GROUND)
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
	# Tricking de suelo con el joystick derecho (sin SALTO)
	for c in [[Vector2(1, 0), "Cartwheel"], [Vector2(0.7, -0.7), "Round-off"], [Vector2(0, -1), "Back Handspring"], [Vector2(0, 1), "Front Handspring"]]:
		await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
		var z0 := player.global_position.z
		var x0 := player.global_position.x
		var flew := {"v": false}
		await run(func(i, f):
			i.flick = c[0] if f == 0 else Vector2.ZERO
			i.rot = c[0] if f < 20 else Vector2.ZERO
			flew.v = flew.v or player.state == PlayerController.State.AIR, 160,
			func(): return flew.v and player.state == PlayerController.State.GROUND)
		var extra := true
		var info := ""
		match c[1]:
			"Cartwheel":
				extra = player.global_position.x - x0 > 0.8; info = "avanza de lado %.2f" % (player.global_position.x - x0)
			"Round-off":
				extra = player.facing.dot(Vector3.FORWARD) < -0.6; info = "cae mirando atrás %.2f" % player.facing.dot(Vector3.FORWARD)
			"Back Handspring":
				extra = player.global_position.z - z0 > 1.0; info = "viaja hacia atrás %.2f" % (player.global_position.z - z0)
			"Front Handspring":
				extra = z0 - player.global_position.z > 1.0; info = "viaja hacia delante %.2f" % (z0 - player.global_position.z)
		check("Suelo: joystick derecho %s = %s (aterriza bien, %s)" % [c[0], c[1], info],
			c[1] in moves and extra and landings.size() > 0 and landings[-1].quality in ["perfect", "clean"], "%s %s" % [moves, landings.map(func(l): return l.quality)])
	# Sin SALTO y sin mantener el joystick (gesto suelto) no hay movimiento de suelo
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	await run(func(i, f): i.flick = Vector2(1, 0) if f == 0 else Vector2.ZERO, 40)
	check("Suelo: un gesto suelto no dispara la rueda (hay que inclinar el joystick)", moves.is_empty() and player.state == PlayerController.State.GROUND, str(moves))
	# Round-off → Backflip: el rebote da más altura que un backflip parado
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var y_plain := player.global_position.y
	var peak := {"v": -99.0, "phase": 0}
	await run(func(i, f):
		i.jump_pressed = f == 2; i.jump_held = f >= 2 and f < 6
		i.flick = Vector2(0, -1) if f == 6 else Vector2.ZERO
		peak.v = maxf(peak.v, player.global_position.y), 120,
		func(): return _f > 10 and player.state == PlayerController.State.GROUND)
	var plain_h: float = peak.v - y_plain
	await place(Vector3(-35, 0.1, 35), Vector3.FORWARD)
	var y0 := player.global_position.y
	await run(func(i, f):
		i.flick = Vector2(0.7, -0.7) if f == 0 else Vector2.ZERO
		i.rot = Vector2(0.7, -0.7) if f < 20 else Vector2.ZERO, 160,
		func(): return player.roundoff_timer > 0.0)
	peak = {"v": -99.0}
	await run(func(i, f):
		i.jump_pressed = f == 0
		i.jump_held = f < 4
		i.flick = Vector2(0, -1) if f == 4 else Vector2.ZERO
		peak.v = maxf(peak.v, player.global_position.y), 160,
		func(): return _f > 10 and player.state == PlayerController.State.GROUND)
	var combo_h: float = peak.v - y0
	var back_after := moves.size() >= 2 and moves[0] == "Round-off" and (moves[1] in ["Backflip", "Gainer"])
	check("Combo Round-off → Backflip: enlaza y salta más alto (%.2f m vs %.2f m)" % [combo_h, plain_h], back_after and combo_h > plain_h * 1.15, str(moves))
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
	await run(func(i, f): i.jump_pressed = f == 25, 60, func(): return "Kip-up" in moves)
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
	for combo in [[0, Vector2(1560, 720)], [0, Vector2(1280, 720)], [0, Vector2(960, 720)], [3, Vector2(1560, 720)], [3, Vector2(1280, 720)], [3, Vector2(960, 720)]]:
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
		func(): return _f > 10 and player.state == PlayerController.State.GROUND)
	q = landings[-1].quality if landings.size() > 0 else "none"
	check("Back Full: mortal atrás + GIRO = tirabuzón completo", "Back Full" in moves and q in ["perfect", "clean"], str(moves) + " " + q)
	# Nombres según despegue y tirabuzones (tabla de trucos)
	var TS := TrickSystem
	var cases := [
		[TS.trick_name(1, 0, 0, 0, true, false, true, "back", "wall", "wallclimb"), "Wall Flip"],
		[TS.trick_name(1, 0, 0, 0, true, true, false, "back", "vault", "Kong Vault"), "Kong Gainer"],
		[TS.trick_name(1, 0, 0, 0, false, true, false, "front", "vault", "Dash Vault"), "Dash Bomb"],
		[TS.trick_name(1, 0, 0, 2, true, true, false, "back"), "Gainer Full"],
		[TS.trick_name(2, 0, 0, 2, true, false, false, "back"), "Full In"],
		[TS.trick_name(1, 0, 0, 4, true, false, false, "back"), "Double Full"],
		[TS.trick_name(1, 0, 0, 1, false, false, false, "front"), "Arabian"],
		[TS.trick_name(1, 0, 0, 2, false, false, false, "front"), "Front Full"],
		[TS.trick_name(0, 1, 0, 1, false, true, false, "side"), "Raiz"],
		[TS.trick_name(0, 0, 1, 2, false, true, false, "butterfly"), "Butterfly Twist"],
		[TS.trick_name(0, 0, 0, 4, false, true, false, "kick"), "Cheat 720"],
		[TS.trick_name(2, 0, 0, 4, true, true, false, "cork"), "Double Cork"],
	]
	var bad := cases.filter(func(c): return c[0] != c[1])
	check("Tabla de trucos: nombres de flips, twists, kicks y despegues", bad.is_empty(), str(bad))

## Variantes de vault elegidas con gesto justo antes de saltar.
func t_vault_variants() -> void:
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
