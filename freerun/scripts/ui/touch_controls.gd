class_name TouchControls
extends Control
## Controles táctiles híbridos:
## - Joystick dinámico (aparece donde apoyas el pulgar) en el lado izquierdo.
## - Botón SALTO grande y botón contextual (RODAR / SOLTAR) a la derecha.
## - El resto del lado derecho es zona de gestos:
##     · arrastre lento = cámara
##     · gesto rápido (flick) = acrobacia; mantener el dedo = agruparse (girar más rápido)
##     · otro gesto lateral durante el mortal = añadir tirabuzón
## Se puede invertir para zurdos, escalar y cambiar la opacidad (Settings).

class TouchFrame:
	var move := Vector2.ZERO
	var jump_pressed := false
	var jump_held := false
	var action_pressed := false
	var action_held := false
	var flick := Vector2.ZERO
	var tuck := false
	var camera_delta := Vector2.ZERO
	var respawn_pressed := false

var context_label := "RODAR"

var _fingers := {}           # index -> {role, start, pos, time, flicked, anchor}
var _joy_base := Vector2.ZERO
var _joy_vec := Vector2.ZERO
var _pending := TouchFrame.new()
var _jump_held := false
var _action_held := false
var _tuck_fingers := 0
var _flash := {}             # nombre -> tiempo de resaltado
var _hint_time := 6.0
var _time := 0.0

const FLICK_TIME := 0.2
const FLICK_PX := 55.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _s() -> float:
	return Settings.control_scale * clampf(size.y / 720.0, 0.6, 2.0)

func _jump_center() -> Vector2:
	var s := _s()
	var x := size.x - 130.0 * s if not Settings.left_handed else 130.0 * s
	return Vector2(x, size.y - 130.0 * s)

func _action_center() -> Vector2:
	var s := _s()
	var j := _jump_center()
	var dx := -150.0 * s if not Settings.left_handed else 150.0 * s
	return j + Vector2(dx, 40.0 * s)

func _respawn_center() -> Vector2:
	var s := _s()
	var j := _jump_center()
	return j + Vector2(0, -150.0 * s)

func _jump_radius() -> float:
	return 78.0 * _s()

func _action_radius() -> float:
	return 52.0 * _s()

func _is_move_side(p: Vector2) -> bool:
	return p.x < size.x * 0.42 if not Settings.left_handed else p.x > size.x * 0.58

func collect() -> TouchFrame:
	var f := _pending
	f.move = _joy_vec
	f.jump_held = _jump_held
	f.action_held = _action_held
	f.tuck = _tuck_fingers > 0
	_pending = TouchFrame.new()
	return f

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_on_touch(event)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_on_drag(event)
		get_viewport().set_input_as_handled()

func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		var p := e.position
		var role := ""
		if p.distance_to(_jump_center()) < _jump_radius() * 1.15:
			role = "jump"
			_jump_held = true
			_pending.jump_pressed = true
			_flash["jump"] = 0.15
		elif p.distance_to(_action_center()) < _action_radius() * 1.2:
			role = "action"
			_action_held = true
			_pending.action_pressed = true
			_flash["action"] = 0.15
		elif p.distance_to(_respawn_center()) < 34.0 * _s():
			role = "respawn"
			_pending.respawn_pressed = true
		elif _is_move_side(p):
			role = "move"
			_joy_base = p
			_joy_vec = Vector2.ZERO
		else:
			role = "gesture"
			_hint_time = 0.0
		_fingers[e.index] = {"role": role, "start": p, "pos": p, "time": _time, "flicked": false, "anchor": p}
	else:
		var f: Dictionary = _fingers.get(e.index, {})
		if f.is_empty():
			return
		match f.role:
			"jump": _jump_held = false
			"action": _action_held = false
			"move": _joy_vec = Vector2.ZERO
			"gesture":
				if f.flicked:
					_tuck_fingers = maxi(0, _tuck_fingers - 1)
				elif _time - f.time < FLICK_TIME:
					var disp: Vector2 = e.position - f.start
					if disp.length() > FLICK_PX * 0.6 * _flick_scale():
						_emit_flick(disp)
		_fingers.erase(e.index)
	queue_redraw()

func _flick_scale() -> float:
	return _s() / maxf(Settings.gesture_sensitivity, 0.2)

func _emit_flick(disp: Vector2) -> void:
	_pending.flick = Vector2(disp.x, -disp.y).normalized()
	_flash["flick"] = 0.25

func _on_drag(e: InputEventScreenDrag) -> void:
	var f: Dictionary = _fingers.get(e.index, {})
	if f.is_empty():
		return
	f.pos = e.position
	match f.role:
		"move":
			var r := 70.0 * _s()
			var d: Vector2 = e.position - _joy_base
			if d.length() > r * 1.25:
				_joy_base = e.position - d.normalized() * r * 1.25   # la base sigue al pulgar
				d = e.position - _joy_base
			var v := d / r
			_joy_vec = Vector2(v.x, -v.y).limit_length(1.0)
		"gesture":
			var disp: Vector2 = e.position - f.anchor
			var thr := FLICK_PX * _flick_scale()
			if not f.flicked:
				if disp.length() > thr and _time - f.time < FLICK_TIME:
					_emit_flick(disp)
					f.flicked = true
					f.anchor = e.position
					_tuck_fingers += 1
				elif _time - f.time >= FLICK_TIME:
					_pending.camera_delta += e.relative * 0.006 * Settings.camera_sensitivity
					f.role = "camera"
			else:
				# Segundo gesto con el mismo dedo (añadir vuelta o tirabuzón)
				if disp.length() > thr * 1.1:
					_emit_flick(disp)
					f.anchor = e.position
		"camera":
			_pending.camera_delta += e.relative * 0.006 * Settings.camera_sensitivity
	queue_redraw()

func _process(dt: float) -> void:
	if not visible:
		return
	_time += dt
	_hint_time += dt
	var vs := get_viewport_rect().size
	if size != vs:
		size = vs
	for k in _flash.keys():
		_flash[k] -= dt
		if _flash[k] <= 0.0:
			_flash.erase(k)
	queue_redraw()

func _draw() -> void:
	var a := Settings.control_opacity
	var s := _s()
	var white := Color(1, 1, 1, a)
	var dark := Color(0.05, 0.07, 0.1, a * 0.55)
	var accent := Color(0.15, 0.85, 0.78, a + 0.15)
	var font := get_theme_default_font()
	# Joystick
	var joy_active := false
	for f in _fingers.values():
		if f.role == "move":
			joy_active = true
	var base := _joy_base if joy_active else Vector2(170.0 * s if not Settings.left_handed else size.x - 170.0 * s, size.y - 160.0 * s)
	draw_circle(base, 72.0 * s, dark)
	draw_arc(base, 72.0 * s, 0, TAU, 48, white, 2.5 * s, true)
	var knob := base + Vector2(_joy_vec.x, -_joy_vec.y) * 70.0 * s
	draw_circle(knob, 30.0 * s, Color(1, 1, 1, a * (0.9 if joy_active else 0.5)))
	# Salto
	var jc := _jump_center()
	var jflash: bool = _flash.has("jump") or _jump_held
	draw_circle(jc, _jump_radius(), accent if jflash else dark)
	draw_arc(jc, _jump_radius(), 0, TAU, 48, white, 3.0 * s, true)
	_label(font, jc, "SALTO", 22 * s, white)
	# Acción contextual
	var ac := _action_center()
	var aflash: bool = _flash.has("action") or _action_held
	draw_circle(ac, _action_radius(), accent if aflash else dark)
	draw_arc(ac, _action_radius(), 0, TAU, 40, white, 2.5 * s, true)
	_label(font, ac, context_label if context_label != "" else "·", 15 * s, white)
	# Reaparecer
	var rc := _respawn_center()
	draw_circle(rc, 30.0 * s, dark)
	_label(font, rc, "↺", 26 * s, white)
	# Pista de gestos
	if _hint_time < 6.0:
		var hx := size.x * 0.68 if not Settings.left_handed else size.x * 0.32
		var hc := Vector2(hx, size.y * 0.35)
		var ha := a * clampf(1.0 - (_hint_time - 4.0) / 2.0, 0.0, 1.0)
		_label(font, hc, "Desliza rápido: acrobacia  ·  Mantén: agrúpate  ·  Arrastra: cámara", 16 * s, Color(1, 1, 1, ha))
	if _flash.has("flick"):
		for f in _fingers.values():
			if f.role == "gesture":
				draw_circle(f.pos, 26.0 * s, Color(accent, 0.5))

func _label(font: Font, center: Vector2, text: String, fsize: float, color: Color) -> void:
	var fs := int(fsize)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, center + Vector2(-w * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
