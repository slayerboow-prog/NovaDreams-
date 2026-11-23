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
		func(): return _f > 10 and player.state == PlayerController.State.GROUND)
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
	check("Pro: sobre-rotar provoca caída", player.state == PlayerController.State.CRASH and bails.size() > 0,
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
		i.move = Vector2.ZERO if st.jumped else Vector2(0, 0.52)
		i.jump_pressed = not st.jumped and player.global_position.z <= -46.3
		st.jumped = st.jumped or i.jump_pressed
		i.jump_held = st.jumped, 200,
		func(): return st.jumped and player.state != PlayerController.State.AIR and _f > 3)
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
	jd.index = 2; jd.position = Vector2(200, 430); jd.relative = Vector2(0, -70)
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
