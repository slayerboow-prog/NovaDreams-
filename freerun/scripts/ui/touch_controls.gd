class_name TouchControls
extends Control
## Controles táctiles híbridos (multitáctil):
## - Joystick dinámico a la izquierda (aparece donde apoyas el pulgar; a fondo = sprint).
## - SALTO: pulsa para saltar. Sin levantar el dedo, DESLÍZALO para hacer una acrobacia:
##     ↓ backflip · ↑ frontflip · ←/→ lateral · ↙/↘ cork · ↖/↗ butterfly kick
##   Mantener el dedo = agruparse (gira más rápido). Soltar = abrirse y preparar el aterrizaje.
## - Cruceta de acrobacias (8 direcciones con nombre): misma función con botones.
## - Zona derecha: en el suelo mueve la cámara; EN EL AIRE controla el cuerpo
##   (un deslizamiento = acrobacia), así cámara y acrobacias no se confunden.
## - Botón contextual (RODAR / SOLTAR) y reinicio.

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
var air_mode := false                 # lo actualiza el juego: el jugador está en el aire

var _fingers := {}                    # index -> datos del dedo
var _joy_base := Vector2.ZERO
var _joy_vec := Vector2.ZERO
var _pending := TouchFrame.new()
var _flash := {}
var _hint_time := 0.0
var _time := 0.0
var _last_flick := Vector2.ZERO

const FLICK_TIME := 0.22              # en el suelo: un gesto rápido es acrobacia, lento es cámara
const FLICK_PX := 48.0
const PAD_LABELS := {0: "LATERAL", 1: "BUTTERFLY", 2: "FRONT", 3: "BUTTERFLY", 4: "LATERAL",
	-1: "CORK", -2: "BACK", -3: "CORK"}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _s() -> float:
	return Settings.control_scale * clampf(size.y / 720.0, 0.6, 2.0)

func _mirror(x: float) -> float:
	return x if not Settings.left_handed else size.x - x

func gestures_enabled() -> bool:
	return Settings.trick_controls != 2

func pad_enabled() -> bool:
	return Settings.trick_controls != 1

func _jump_center() -> Vector2:
	var s := _s()
	return Vector2(_mirror(size.x - 128.0 * s), size.y - 128.0 * s)

func _jump_radius() -> float:
	return 84.0 * _s()

func _action_center() -> Vector2:
	var s := _s()
	return Vector2(_mirror(size.x - 300.0 * s), size.y - 84.0 * s)

func _action_radius() -> float:
	return 54.0 * _s()

func _pad_center() -> Vector2:
	var s := _s()
	return Vector2(_mirror(size.x - 300.0 * s), size.y - 300.0 * s)

func _pad_radius() -> float:
	return 92.0 * _s()

func _respawn_center() -> Vector2:
	var s := _s()
	return Vector2(_mirror(size.x - 56.0 * s), 128.0 * s)

func _is_move_side(p: Vector2) -> bool:
	return p.x < size.x * 0.42 if not Settings.left_handed else p.x > size.x * 0.58

func collect() -> TouchFrame:
	var f := _pending
	f.move = _joy_vec
	f.jump_held = false
	f.action_held = false
	f.tuck = false
	for fd in _fingers.values():
		match fd.role:
			"jump":
				f.jump_held = true
				f.tuck = f.tuck or fd.flicked
			"action":
				f.action_held = true
			"pad":
				f.tuck = true
			"gesture":
				f.tuck = f.tuck or fd.flicked
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

static func sector_of(v: Vector2) -> int:
	var sec := int(round(rad_to_deg(atan2(v.y, v.x)) / 45.0))
	return 4 if sec == -4 else sec

static func sector_dir(sec: int) -> Vector2:
	var a := deg_to_rad(sec * 45.0)
	return Vector2(cos(a), sin(a))

func _emit_flick(v: Vector2) -> void:
	# Se cuantiza a 8 direcciones para que el gesto sea fiable.
	var sec := sector_of(v)
	_pending.flick = sector_dir(sec)
	_last_flick = _pending.flick
	_flash["flick"] = 0.35
	_flash["sector"] = sec

func _flick_px() -> float:
	return FLICK_PX * _s() / maxf(Settings.gesture_sensitivity, 0.2)

func _on_touch(e: InputEventScreenTouch) -> void:
	var p := e.position
	if e.pressed:
		var role := ""
		var info := {"start": p, "pos": p, "time": _time, "flicked": false, "anchor": p, "sector": 99}
		if p.distance_to(_jump_center()) < _jump_radius() * 1.2:
			role = "jump"
			_pending.jump_pressed = true
			_flash["jump"] = 0.15
		elif p.distance_to(_action_center()) < _action_radius() * 1.25:
			role = "action"
			_pending.action_pressed = true
			_flash["action"] = 0.15
		elif p.distance_to(_respawn_center()) < 40.0 * _s():
			role = "respawn"
			_pending.respawn_pressed = true
		elif pad_enabled() and p.distance_to(_pad_center()) < _pad_radius() * 1.15:
			role = "pad"
			var v := p - _pad_center()
			var sec := sector_of(Vector2(v.x, -v.y)) if v.length() > _pad_radius() * 0.18 else -2
			info.sector = sec
			_emit_flick(sector_dir(sec))
		elif _is_move_side(p):
			role = "move"
			_joy_base = p
			_joy_vec = Vector2.ZERO
		else:
			role = "gesture"
			_hint_time = 99.0
		info["role"] = role
		_fingers[e.index] = info
	else:
		var f: Dictionary = _fingers.get(e.index, {})
		if f.is_empty():
			return
		if f.role == "move":
			_joy_vec = Vector2.ZERO
		elif f.role == "gesture" and not f.flicked and gestures_enabled():
			# Gesto corto soltado antes del umbral de tiempo: también cuenta
			var disp: Vector2 = p - f.start
			if disp.length() > _flick_px() * 0.65 and (_time - f.time < FLICK_TIME or air_mode):
				_emit_flick(Vector2(disp.x, -disp.y))
		_fingers.erase(e.index)
	queue_redraw()

func _on_drag(e: InputEventScreenDrag) -> void:
	var f: Dictionary = _fingers.get(e.index, {})
	if f.is_empty():
		return
	f.pos = e.position
	match f.role:
		"move":
			var r := 72.0 * _s()
			var d: Vector2 = e.position - _joy_base
			if d.length() > r * 1.25:
				_joy_base = e.position - d.normalized() * r * 1.25
				d = e.position - _joy_base
			var v := d / r
			_joy_vec = Vector2(v.x, -v.y).limit_length(1.0)
		"jump":
			if gestures_enabled():
				_swipe(f, e.position)
		"pad":
			var v: Vector2 = e.position - _pad_center()
			if v.length() > _pad_radius() * 0.3:
				var sec := sector_of(Vector2(v.x, -v.y))
				if sec != f.sector:
					f.sector = sec
					_emit_flick(sector_dir(sec))
		"gesture":
			if not gestures_enabled():
				_pending.camera_delta += e.relative * 0.006 * Settings.camera_sensitivity
				return
			var disp: Vector2 = e.position - f.anchor
			if not f.flicked:
				var fast: bool = _time - f.time < FLICK_TIME
				if disp.length() > _flick_px() and (fast or air_mode):
					_swipe(f, e.position)
				elif not fast and not air_mode:
					f.role = "camera"
					_pending.camera_delta += e.relative * 0.006 * Settings.camera_sensitivity
			else:
				_swipe(f, e.position)
		"camera":
			_pending.camera_delta += e.relative * 0.006 * Settings.camera_sensitivity
	queue_redraw()

## Deslizamiento con el dedo apoyado: primer gesto = acrobacia; gestos siguientes = añadidos.
func _swipe(f: Dictionary, pos: Vector2) -> void:
	var disp: Vector2 = pos - f.anchor
	var thr := _flick_px() * (1.0 if not f.flicked else 1.15)
	if disp.length() > thr:
		var v := Vector2(disp.x, -disp.y)
		if not f.flicked or sector_of(v) != f.sector:
			_emit_flick(v)
			f.sector = sector_of(v)
		f.flicked = true
		f.anchor = pos

func _process(dt: float) -> void:
	if not visible:
		return
	_time += dt
	_hint_time += dt
	var vs := get_viewport_rect().size
	if size != vs:
		size = vs
	for k in _flash.keys():
		if k == "sector":
			continue
		_flash[k] -= dt
		if _flash[k] <= 0.0:
			_flash.erase(k)
	if not _flash.has("flick"):
		_flash.erase("sector")
	queue_redraw()

func _draw() -> void:
	var a := Settings.control_opacity
	var s := _s()
	var white := Color(1, 1, 1, minf(a + 0.25, 1.0))
	var dark := Color(0.05, 0.07, 0.1, a * 0.6)
	var accent := Color(0.15, 0.85, 0.78, minf(a + 0.2, 1.0))
	var font := get_theme_default_font()
	# Joystick
	var joy_active := false
	for f in _fingers.values():
		if f.role == "move":
			joy_active = true
	var base := _joy_base if joy_active else Vector2(_mirror(180.0 * s), size.y - 170.0 * s)
	draw_circle(base, 76.0 * s, dark)
	draw_arc(base, 76.0 * s, 0, TAU, 48, white, 3.0 * s, true)
	var knob := base + Vector2(_joy_vec.x, -_joy_vec.y) * 72.0 * s
	draw_circle(knob, 32.0 * s, Color(1, 1, 1, a * (0.95 if joy_active else 0.55)))
	if _joy_vec.length() > 0.93:
		_label(font, base + Vector2(0, -96 * s), "SPRINT", 18 * s, accent)
	# Salto (con pista de deslizamiento)
	var jc := _jump_center()
	var jheld := false
	for f in _fingers.values():
		if f.role == "jump":
			jheld = true
	draw_circle(jc, _jump_radius(), accent if (jheld or _flash.has("jump")) else dark)
	draw_arc(jc, _jump_radius(), 0, TAU, 56, white, 3.0 * s, true)
	_label(font, jc + Vector2(0, -6 * s), "SALTO", 26 * s, white)
	if gestures_enabled():
		_label(font, jc + Vector2(0, 26 * s), "desliza = truco", 13 * s, Color(1, 1, 1, a))
	# Acción contextual
	var ac := _action_center()
	draw_circle(ac, _action_radius(), accent if _flash.has("action") else dark)
	draw_arc(ac, _action_radius(), 0, TAU, 40, white, 2.5 * s, true)
	_label(font, ac, context_label if context_label != "" else "RODAR", 17 * s, white)
	# Reinicio
	var rc := _respawn_center()
	draw_circle(rc, 32.0 * s, dark)
	var r := 13.0 * s
	draw_arc(rc, r, -PI * 0.35, PI * 1.45, 24, white, 3.0 * s, true)
	var tip := rc + Vector2(cos(-PI * 0.35), sin(-PI * 0.35)) * r
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-7, -5) * s, tip + Vector2(6, -6) * s, tip + Vector2(1, 6) * s]), white)
	# Cruceta de acrobacias
	if pad_enabled():
		_draw_pad(font, s, a, white, dark, accent)
	# Pista de gestos al principio
	if _hint_time < 9.0 and gestures_enabled():
		var hc := Vector2(_mirror(size.x * 0.66), size.y * 0.3)
		var ha := clampf(1.0 - (_hint_time - 7.0) / 2.0, 0.0, 1.0)
		_label(font, hc, "Pulsa SALTO y desliza: ↓ back · ↑ front · ← → lateral · diagonales", 18 * s, Color(1, 1, 1, ha))
		_label(font, hc + Vector2(0, 30 * s), "Mantén el dedo para girar más · suelta para aterrizar", 18 * s, Color(1, 1, 1, ha))
	# Rastro del gesto
	if _flash.has("flick"):
		for f in _fingers.values():
			if f.role in ["gesture", "jump"]:
				draw_circle(f.pos, 28.0 * s, Color(accent, 0.45))

func _draw_pad(font: Font, s: float, a: float, white: Color, dark: Color, accent: Color) -> void:
	var pc := _pad_center()
	var pr := _pad_radius()
	var active_sec := 99
	for f in _fingers.values():
		if f.role == "pad":
			active_sec = f.sector
	draw_circle(pc, pr, Color(dark, dark.a * 0.8))
	draw_arc(pc, pr, 0, TAU, 56, Color(white, white.a * 0.7), 2.0 * s, true)
	for sec in [0, 1, 2, 3, 4, -1, -2, -3]:
		var d := sector_dir(sec)
		var p := pc + Vector2(d.x, -d.y) * pr * 0.66
		var hot: bool = sec == active_sec or (_flash.has("sector") and _flash.sector == sec)
		draw_circle(p, 25.0 * s, accent if hot else Color(1, 1, 1, a * 0.18))
		var arrow := pc + Vector2(d.x, -d.y) * pr * 0.66
		var lbl: String = PAD_LABELS[sec]
		var fs := 10.0 if lbl.length() > 5 else 12.0
		_label(font, arrow, lbl, fs * s, white)
	_label(font, pc, "TRUCOS", 13 * s, Color(1, 1, 1, a + 0.1))

func _label(font: Font, center: Vector2, text: String, fsize: float, color: Color) -> void:
	var fs := int(fsize)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, center + Vector2(-w * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
