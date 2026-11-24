class_name InputRouter
extends Node
## Combina teclado, ratón, mando y controles táctiles en un InputIntent por frame de física.
## Se ejecuta antes que el jugador (process_physics_priority negativo).
## Los tests asignan `scripted` para controlar al personaje con un bot.

var intent := InputIntent.new()
var touch: TouchControls
var scripted: Callable          # func(intent: InputIntent, frame: int) -> void
var frame := 0
var enabled := true

var _mouse_delta := Vector2.ZERO
var _prev_pad_trick := Vector2.ZERO

func _ready() -> void:
	process_physics_priority = -100
	_setup_actions()

static func _add_key(action: String, keys: Array, pad_buttons: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in pad_buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		InputMap.action_add_event(action, j)

static func _add_axis(action: String, axis: int, value: float) -> void:
	var j := InputEventJoypadMotion.new()
	j.axis = axis
	j.axis_value = value
	InputMap.action_add_event(action, j)

func _setup_actions() -> void:
	if InputMap.has_action("move_forward"):
		return
	_add_key("move_forward", [KEY_W])
	_add_key("move_back", [KEY_S])
	_add_key("move_left", [KEY_A])
	_add_key("move_right", [KEY_D])
	_add_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_key("sprint", [KEY_SHIFT], [JOY_BUTTON_LEFT_STICK])
	_add_key("jump", [KEY_SPACE], [JOY_BUTTON_A])
	_add_key("action", [KEY_CTRL, KEY_C, KEY_F], [JOY_BUTTON_B])
	_add_key("trick_up", [KEY_UP, KEY_I], [JOY_BUTTON_Y])
	_add_key("trick_down", [KEY_DOWN, KEY_K], [JOY_BUTTON_X])
	_add_key("trick_left", [KEY_LEFT, KEY_J], [JOY_BUTTON_LEFT_SHOULDER])
	_add_key("trick_right", [KEY_RIGHT, KEY_L], [JOY_BUTTON_RIGHT_SHOULDER])
	_add_key("cam_left", [KEY_Q])
	_add_key("cam_right", [KEY_E])
	_add_key("respawn", [KEY_R], [JOY_BUTTON_BACK])
	_add_key("vault", [KEY_V], [JOY_BUTTON_RIGHT_STICK])
	_add_key("grab", [KEY_G], [JOY_BUTTON_DPAD_UP])
	_add_key("cam_recenter", [KEY_T], [JOY_BUTTON_LEFT_STICK])
	_add_key("twist_left", [KEY_U])
	_add_key("twist_right", [KEY_O])
	_add_axis("twist_left", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_axis("twist_right", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_axis("cam_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_axis("cam_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_key("cam_up", [])
	_add_key("cam_down", [])
	_add_axis("cam_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_axis("cam_down", JOY_AXIS_RIGHT_Y, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += event.relative
	elif event is InputEventMouseButton and event.pressed and not _touch_active():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not DisplayServer.get_name() == "headless":
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _touch_active() -> bool:
	return touch != null and touch.visible

## Giro de cámara acumulado entre fotogramas. La física puede ejecutar varios pasos por
## fotograma (móvil a 30-40 FPS): sin acumular, el segundo paso borraba el arrastre del
## primero y la cámara no giraba. La cámara lo consume en su _process.
var _cam_accum := Vector2.ZERO
var _cam_recenter := false

func take_camera() -> Dictionary:
	var out := {"delta": _cam_accum, "recenter": _cam_recenter}
	_cam_accum = Vector2.ZERO
	_cam_recenter = false
	return out

func _physics_process(dt: float) -> void:
	_read_intent(dt)
	_cam_accum += intent.camera_delta
	_cam_recenter = _cam_recenter or intent.camera_recenter

func _read_intent(_dt: float) -> void:
	frame += 1
	intent.clear_edges()
	if scripted.is_valid():
		scripted.call(intent, frame)
		return
	if not enabled:
		intent.move = Vector2.ZERO
		intent.jump_held = false
		intent.tuck = false
		intent.rot = Vector2.ZERO
		intent.grab_held = false
		intent.action_held = false
		_mouse_delta = Vector2.ZERO
		return

	# --- Teclado / mando ---
	var mv := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	intent.sprint = Input.is_action_pressed("sprint")
	intent.jump_pressed = Input.is_action_just_pressed("jump")
	intent.jump_held = Input.is_action_pressed("jump")
	intent.action_pressed = Input.is_action_just_pressed("action")
	intent.action_held = Input.is_action_pressed("action")
	intent.respawn_pressed = Input.is_action_just_pressed("respawn")
	intent.vault_pressed = Input.is_action_just_pressed("vault")
	intent.grab_pressed = Input.is_action_just_pressed("grab")
	intent.grab_held = Input.is_action_pressed("grab")

	var trick_vec := Vector2(
		Input.get_action_strength("trick_right") - Input.get_action_strength("trick_left"),
		Input.get_action_strength("trick_up") - Input.get_action_strength("trick_down"))
	var any_trick_pressed := Input.is_action_just_pressed("trick_up") or Input.is_action_just_pressed("trick_down") \
		or Input.is_action_just_pressed("trick_left") or Input.is_action_just_pressed("trick_right")
	if any_trick_pressed and trick_vec.length() > 0.1:
		intent.flick = trick_vec.normalized()
	intent.tuck = trick_vec.length() > 0.1
	intent.rot = trick_vec.limit_length(1.0)
	intent.twist = Input.get_action_strength("twist_right") - Input.get_action_strength("twist_left")
	intent.stick_twist = false

	var sens := Settings.camera_sensitivity
	var cam := _mouse_delta * 0.0032 * sens
	_mouse_delta = Vector2.ZERO
	var pad_cam := Vector2(Input.get_action_strength("cam_right") - Input.get_action_strength("cam_left"),
		Input.get_action_strength("cam_down") - Input.get_action_strength("cam_up"))
	cam += pad_cam * 0.045 * sens
	intent.camera_delta = cam
	intent.camera_recenter = Input.is_action_just_pressed("cam_recenter")

	# --- Táctil ---
	if touch and touch.visible:
		var t := touch.collect()
		if t.move.length() > 0.01:
			mv = t.move
		intent.jump_pressed = intent.jump_pressed or t.jump_pressed
		intent.jump_held = intent.jump_held or t.jump_held
		intent.action_pressed = intent.action_pressed or t.action_pressed
		intent.action_held = intent.action_held or t.action_held
		if t.flick != Vector2.ZERO:
			intent.flick = t.flick
		intent.tuck = intent.tuck or t.tuck
		intent.camera_delta += t.camera_delta
		intent.camera_recenter = intent.camera_recenter or t.camera_recenter
		intent.respawn_pressed = intent.respawn_pressed or t.respawn_pressed
		intent.kick = intent.kick or t.kick
		intent.vault_pressed = intent.vault_pressed or t.vault_pressed
		intent.grab_pressed = intent.grab_pressed or t.grab_pressed
		intent.grab_held = intent.grab_held or t.grab_held
		if t.rot.length() > 0.01:
			intent.rot = t.rot
		if t.skill != "":
			intent.skill_request = t.skill
		intent.double_flip = intent.double_flip or t.double
		intent.cork_request = intent.cork_request or t.cork
		intent.butterfly_request = intent.butterfly_request or t.butterfly
		intent.skill_hold = t.skill_hold
		if not t.pattern.is_empty():
			intent.pattern = t.pattern
		intent.twist_loops = t.twist_loops
		intent.giro_sector = t.giro_sector
		if not t.giro.is_empty():
			intent.giro = t.giro
		if t.flip_press != 99:
			intent.flip_press = t.flip_press
		intent.flip_held = t.flip_held
		intent.one_foot = intent.one_foot or t.one_foot
		intent.jump_charge = maxf(intent.jump_charge, t.jump_charge)
		if touch.stick_enabled():
			# Doble joystick: los mortales van en la rueda de SALTO y el joystick derecho es el GIRO
			intent.stick_twist = true
			if absf(t.rot.x) > absf(intent.twist):
				intent.twist = t.rot.x
			intent.rot_flick = t.rot_flick
	intent.move = mv.limit_length(1.0)
