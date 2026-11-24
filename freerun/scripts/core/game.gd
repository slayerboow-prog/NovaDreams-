extends Node3D
## Punto de entrada. Monta entorno, escenario, personaje, cámara, entrada, combos,
## interfaz y el modo de juego activo.
##
## Argumentos de usuario (tras `--`):
##   --mode=<freerun|tricking|water|challenge|freestyle>  salta el menú
##   --touch                                               fuerza controles táctiles

var level_info := {}
var player: PlayerController
var rig: BodyRig
var camera: CameraRig
var replay: Replay
var router: InputRouter
var combo := ComboSystem.new()
var flow := FlowSystem.new()
var ui: GameUI
var mode: GameModes.Base
var sun: DirectionalLight3D
var env: WorldEnvironment
var in_menu := true
var paused := false
var _menu_orbit := 0.0

func _ready() -> void:
	_build_environment()
	level_info = LevelBuilder.new().build(self)

	router = InputRouter.new()
	router.name = "Input"
	add_child(router)

	player = PlayerController.new()
	player.name = "Player"
	add_child(player)
	player.router = router
	player.water_volumes = level_info.water
	rig = BodyRig.new()
	rig.name = "Rig"
	player.add_child(rig)
	rig.setup(player)

	var feedback := Feedback.new()
	feedback.name = "Feedback"
	add_child(feedback)
	feedback.setup(player, rig, combo)

	camera = CameraRig.new()
	camera.name = "CameraRig"
	add_child(camera)
	camera.setup(player, router)
	camera.rig = rig
	replay = Replay.new()
	replay.name = "Replay"
	add_child(replay)
	replay.setup(self)

	ui = GameUI.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	ui.setup(self)
	router.touch = ui.touch
	ui.touch.context_provider = player.gesture_context   # los patrones de parkour comprueban el entorno
	ui.trick_indicator.player = player

	player.move_performed.connect(_on_move)
	player.landed.connect(_on_landed)
	player.bailed.connect(_on_bailed)
	player.entered_water.connect(_on_water)
	player.respawned.connect(_on_respawned)
	combo.combo_banked.connect(_on_banked)
	combo.combo_bailed.connect(_on_combo_bailed)
	ui.mode_selected.connect(start_mode)
	ui.resume_requested.connect(func(): set_paused(false))
	ui.restart_requested.connect(func():
		set_paused(false)
		start_mode(mode.id if mode else "freerun"))
	ui.menu_requested.connect(func():
		set_paused(false)
		show_menu())
	ui.respawn_requested.connect(func():
		set_paused(false)
		player.respawn())
	ui.extra_pressed.connect(func():
		if mode: mode.on_extra_button())

	apply_graphics()
	var args := OS.get_cmdline_user_args()
	if "--touch" in args:
		Settings.force_touch_ui = true
	var start := ""
	for a in args:
		if a.begins_with("--mode="):
			start = a.substr(7)
	if start != "":
		start_mode(start)
	else:
		show_menu()

func _build_environment() -> void:
	env = WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.55, 0.88)
	sm.sky_horizon_color = Color(0.78, 0.84, 0.92)
	sm.ground_horizon_color = Color(0.7, 0.72, 0.75)
	sm.ground_bottom_color = Color(0.35, 0.36, 0.4)
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.58, 0.64, 0.76)
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_white = 6.0
	e.tonemap_exposure = 0.9
	e.fog_enabled = true
	e.fog_light_color = Color(0.75, 0.82, 0.9)
	e.fog_density = 0.0035
	e.fog_sky_affect = 0.0
	env.environment = e
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_blur = 1.0
	add_child(sun)

## Presets gráficos: escala de render, sombras y antialiasing.
func apply_graphics() -> void:
	if sun == null:
		return
	var p := Settings.graphics_preset
	var vp := get_viewport()
	match p:
		0:
			sun.shadow_enabled = false
			vp.scaling_3d_scale = 0.75
			vp.msaa_3d = Viewport.MSAA_DISABLED
			env.environment.fog_enabled = false
		1:
			sun.shadow_enabled = true
			sun.directional_shadow_max_distance = 35.0
			vp.scaling_3d_scale = 0.9
			vp.msaa_3d = Viewport.MSAA_DISABLED
			env.environment.fog_enabled = true
		_:
			sun.shadow_enabled = true
			sun.directional_shadow_max_distance = 60.0
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_2X
			env.environment.fog_enabled = true

var last_mode := ""

## Repetición de los últimos segundos (cámara libre, POV, dron, cámara lenta).
func start_replay() -> void:
	if replay.start():
		ui.show_replay(true)

func stop_replay() -> void:
	replay.stop()
	ui.show_replay(false)                   # modo que se estaba jugando (botón «Volver al juego» del menú)

func show_menu() -> void:
	if mode:
		last_mode = mode.id
		mode.stop()
		mode = null
	in_menu = true
	combo.reset_all()
	flow.reset()
	ui.show_main_menu(true)
	ui.show_hud(false)
	router.enabled = false
	_place_player("freerun")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func start_mode(id: String) -> void:
	if mode:
		mode.stop()
	mode = GameModes.create(id)
	mode.setup(self)
	in_menu = false
	ui.show_main_menu(false)
	ui.show_hud(true)
	router.enabled = true
	combo.reset_all()
	flow.reset()
	_place_player(mode.spawn_key())
	mode.start()
	ui.popup(GameModes.info(id).get("title", id), Color(0.6, 1, 0.9))

func _place_player(key: String) -> void:
	var sp: Array = level_info.spawns.get(key, level_info.spawns.freerun)
	var dir: Vector3 = sp[1]
	var xf := Transform3D(Basis(), sp[0])
	player.set_spawn(xf, dir)
	player.respawn()
	camera.snap()

func respawn_player() -> void:
	if mode:
		_place_player(mode.spawn_key())

func set_paused(v: bool) -> void:
	if in_menu:
		return
	paused = v
	get_tree().paused = v
	ui.show_pause(v)
	if v:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE and not in_menu:
		set_paused(not paused)

func _process(dt: float) -> void:
	if in_menu:
		_menu_orbit += dt * 0.08
		camera.yaw = _menu_orbit
		camera.pitch = -0.25
		return
	var S := PlayerController.State
	ui.touch.air_mode = player.state in [S.AIR, S.WALLRUN, S.WALLCLIMB, S.HANG, S.VAULT]
	if mode:
		mode.tick(dt)
		ui.update_hud(combo, player, mode.status_text(), GameModes.info(mode.id).get("title", ""), mode.extra_button())

func _physics_process(dt: float) -> void:
	if in_menu:
		return
	var busy := player.state in [PlayerController.State.AIR, PlayerController.State.VAULT, PlayerController.State.WALLRUN,
		PlayerController.State.WALLCLIMB, PlayerController.State.HANG, PlayerController.State.CLIMB_UP, PlayerController.State.ROLL, PlayerController.State.SKILL]
	combo.tick(dt, busy, player.speed())
	flow.tick(dt, busy or player.speed() > 2.5)
	player.flow_boost = flow.boost()
	ui.update_flow(flow.value, flow.is_flowing())

# ------------------------------------------------------------------ eventos

func _on_move(name: String, quality: float, info: Dictionary) -> void:
	SaveData.add_stat("move_" + name)
	if info.get("dive", false):
		# Dive Kong: distancia del despegue al muro y récord personal (para ir alargándola)
		var dist := float(info.distance)
		var best := float(SaveData.get_record("dive_kong_m", 0.0))
		var rec := SaveData.submit_record("dive_kong_m", dist)
		ui.show_landing("%s  %.1f m%s" % [MoveNames.es(name).to_upper(), dist,
			"  ·  ¡RÉCORD!" if rec and best > 0.0 else "  (récord %.1f m)" % maxf(best, dist)], Color(1, 0.85, 0.3))
	combo.add_move(name, quality, info)
	flow.on_move(name, quality, info)
	if mode:
		mode.on_move(name, quality, info)

func _on_landed(result: Dictionary) -> void:
	var q: String = result.quality
	var trick: Dictionary = result.trick
	flow.on_land(q, not trick.is_empty(), result.hard)
	if not trick.is_empty() or q == "crash" or result.hard:
		match q:
			"perfect": ui.show_landing("PERFECTO", Color(0.4, 1, 0.7))
			"clean": ui.show_landing("LIMPIO", Color(0.8, 0.95, 1))
			"sloppy":
				ui.show_landing("FORZADO", Color(1, 0.75, 0.3))
				combo.penalize(0.5)
			"crash": ui.show_landing("¡CAÍDA!", Color(1, 0.35, 0.3))
		if result.hard and q != "crash":
			ui.show_landing("RECEPCIÓN DURA — rueda al caer (botón RODAR / Ctrl)", Color(1, 0.6, 0.3))
	if mode:
		mode.on_land(result)

func _on_bailed(_reason: String) -> void:
	combo.bail()
	flow.on_land("crash", false, false)
	SaveData.add_stat("bails")

func _on_water(result: Dictionary) -> void:
	if mode:
		mode.on_water(result)
	if mode == null or mode.id != "water":
		combo.bank()

func _on_respawned() -> void:
	if combo.active:
		combo.bank()
	if mode:
		mode.on_respawn()

func _on_banked(points: int, summary: Dictionary) -> void:
	if points <= 0:
		return
	var txt := "+%d" % points
	if summary.moves >= 3:
		txt += "   (%d movimientos, %d distintos)" % [summary.moves, summary.unique]
	ui.popup(txt, Color(1, 0.88, 0.3))
	if mode:
		mode.on_combo_banked(points)

func _on_combo_bailed(lost: int) -> void:
	if lost > 0:
		ui.popup("Combo perdido (-%d)" % lost, Color(1, 0.4, 0.35))
