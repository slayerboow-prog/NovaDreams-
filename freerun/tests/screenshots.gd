extends Node
## Captura imágenes del juego en momentos clave (requiere ventana: xvfb-run).
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 res://tests/screenshots.tscn -- --out=<dir>

var game: Node
var player: PlayerController
var out := "user://shots"
var _script: Callable
var _f := 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await frames(30)
	await shot("01_menu")
	game.start_mode("freerun")
	player = game.player
	game.router.scripted = _drive
	await frames(30)
	await shot("02_spawn")
	# Carrera hacia la línea de vaults y Kong Vault
	_place(Vector3(0, 0.1, -8), Vector3.FORWARD)
	await frames(10)
	var st := {"pressed": false}
	_f = 0
	_script = func(i: InputIntent, f: int):
		i.move = Vector2(0, 1); i.sprint = true
		i.jump_pressed = not st.pressed and player.global_position.z <= -12.9
		st.pressed = st.pressed or i.jump_pressed
	await until(func(): return player.global_position.z < -10.5, 200)
	await shot("03_sprint")
	await until(func(): return player.state == PlayerController.State.VAULT and player.vault_progress() > 0.45, 200)
	await shot("04_kong_vault")
	# Backflip en zona abierta
	_script = Callable()
	_place(Vector3(-35, 0.1, 30), Vector3.FORWARD)
	await frames(20)
	_f = 0
	_script = func(i: InputIntent, f: int):
		i.jump_pressed = f == 0
		i.jump_held = true
		i.flick = Vector2(0, -1) if f == 3 else Vector2.ZERO
		i.tuck = f > 3 and f < 12
	await until(func(): return player.tricks.total_pitch > 2.6, 120)
	await shot("05_backflip")
	await until(func(): return player.state == PlayerController.State.GROUND, 120)
	await frames(3)
	await shot("06_landing")
	# Wall run
	_script = Callable()
	_place(Vector3(11.0, 0.1, 3), Vector3.FORWARD)
	await frames(20)
	_f = 0
	_script = func(i: InputIntent, f: int):
		i.move = Vector2(0, 1); i.sprint = true
		i.jump_pressed = f == 25
		i.jump_held = f >= 25
	await until(func(): return player.state == PlayerController.State.WALLRUN and player.state_time > 0.3, 200)
	await shot("07_wallrun")
	# Colgado del borde
	_script = Callable()
	_place(Vector3(0, 0.1, -34.5), Vector3.FORWARD)
	await frames(20)
	_f = 0
	_script = func(i: InputIntent, f: int):
		i.move = Vector2(0, 0.8)
		i.jump_pressed = f == 18
		i.jump_held = true
	await until(func(): return player.state == PlayerController.State.HANG and player.state_time > 0.3, 200)
	await shot("08_hang")
	# Controles táctiles visibles
	_script = Callable()
	Settings.force_touch_ui = true
	game.ui.show_hud(true)
	_place(Vector3(0, 0.1, 6), Vector3.FORWARD)
	await frames(30)
	await shot("09_touch_ui")
	get_tree().quit()

func _place(pos: Vector3, facing: Vector3) -> void:
	player.set_spawn(Transform3D(Basis(), pos), facing)
	player.respawn()
	game.camera.snap()

func _drive(intent: InputIntent, _frame: int) -> void:
	intent.move = Vector2.ZERO
	intent.sprint = false
	intent.jump_held = false
	intent.tuck = false
	if _script.is_valid():
		_script.call(intent, _f)
	_f += 1

func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func until(cond: Callable, max_frames: int) -> void:
	for i in max_frames:
		await get_tree().physics_frame
		if cond.call():
			return

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("captura ", name)
