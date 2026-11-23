class_name TouchControls
extends Control
## Controles táctiles híbridos (multitáctil). Modo por defecto: DOBLE JOYSTICK.
## - Joystick izquierdo (pulgar izquierdo): movimiento analógico; a fondo = sprint.
## - Joystick derecho (pulgar derecho): rotación del cuerpo. Inclinarlo arranca la acrobacia
##   en esa dirección; cuanto más se inclina hacia el giro, más se agrupa y más rápido gira;
##   soltarlo abre el cuerpo; tirar en contra frena y prepara el aterrizaje. Tocar sin
##   inclinar = GIRO (360 / tirabuzón). Volver a inclinar = otra vuelta o tirabuzón añadido.
## - AGRUPAR (pulgar izquierdo, en el aire): agrupado total mientras se mantiene.
## Otros modos (Ajustes): gestos sobre SALTO y cruceta de trucos.
## - Joystick dinámico a la izquierda (aparece donde apoyas el pulgar; a fondo = sprint).
## - SALTO: pulsa para saltar. Sin levantar el dedo, DESLÍZALO para hacer una acrobacia:
##     ↓ backflip · ↑ frontflip · ←/→ lateral · ↙/↘ cork · ↖/↗ butterfly kick
##   Mantener el dedo = agruparse (gira algo más rápido). Doble = deslizar dos veces igual. Soltar = abrirse y preparar el aterrizaje.
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
	var kick := false
	var rot := Vector2.ZERO

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
var _rot_vec := Vector2.ZERO          # joystick derecho (x derecha, y arriba)

const FLICK_TIME := 0.22              # en el suelo: un gesto rápido es acrobacia, lento es cámara
const FLICK_PX := 48.0
const PAD_LABELS := {0: "LATERAL", 1: "FRONT FULL", 2: "FRONT", 3: "AERIAL", 4: "LATERAL",
	-1: "CORK", -2: "BACK", -3: "CORK"}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Escala de los controles. El diseño está en unidades de una pantalla de 720 de alto
## (con canvas_items la altura virtual del juego siempre es ~720), así que los tamaños
## son proporcionales a la altura real del móvil: un SALTO de ~2,3 cm en un iPhone.
func _s() -> float:
	var s := Settings.control_scale * clampf(minf(size.y / 720.0, size.x / 1280.0), 0.6, 2.0)
	if stick_enabled():
		s = minf(s, size.x / 1100.0)          # joystick + SALTO + joystick deben caber a lo ancho
	return s

## Joystick izquierdo en reposo (dónde se dibuja; al tocar aparece bajo el pulgar).
func _joy_idle() -> Vector2:
	var s := _s()
	return Vector2(_mirror(JOY_R * s + 50.0 * s), size.y - JOY_R * s - 70.0 * s)

func _mirror(x: float) -> float:
	return x if not Settings.left_handed else size.x - x

## trick_controls: 0 doble joystick · 1 solo gestos · 2 solo cruceta · 3 gestos + cruceta
func gestures_enabled() -> bool:
	return Settings.trick_controls != 2

func pad_enabled() -> bool:
	return Settings.trick_controls >= 2

func stick_enabled() -> bool:
	return Settings.trick_controls == 0

# Distribución ergonómica para el pulgar derecho (arco alrededor de la esquina inferior):
#   SALTO grande en la esquina, cruceta de trucos a su izquierda, RODAR encima del salto.
# Las zonas de pulsación no se solapan (se comprueba en las pruebas).
const JUMP_R := 128.0
const PAD_R := 150.0
const ACTION_R := 66.0
const JOY_R := 118.0
# Doble joystick: joystick de rotación en la esquina inferior derecha, SALTO grande a su
# izquierda (abajo, donde el pulgar llega sin estirarse), RODAR encima, AGRUPAR a la izquierda.
const ROT_R := 138.0
const STICK_JUMP_R := 112.0
const TUCK_R := 76.0

func _jump_center() -> Vector2:
	var s := _s()
	if stick_enabled():
		return Vector2(_mirror(size.x - (500.0 if _narrow() else 540.0) * s), size.y - 140.0 * s)
	return Vector2(_mirror(size.x - 158.0 * s), size.y - 158.0 * s)

func _jump_radius() -> float:
	return (STICK_JUMP_R if stick_enabled() else JUMP_R) * _s()

func _rot_center() -> Vector2:
	var s := _s()
	return Vector2(_mirror(size.x - 205.0 * s), size.y - 215.0 * s)

func _rot_radius() -> float:
	return ROT_R * _s()

## Recorrido del joystick derecho hasta la inclinación máxima (configurable con la sensibilidad).
func _rot_travel() -> float:
	return ROT_R * 0.62 * _s() / maxf(Settings.gesture_sensitivity, 0.2)

func _tuck_center() -> Vector2:
	var s := _s()
	return Vector2(_mirror(400.0 * s), maxf(size.y - 430.0 * s, _tuck_radius() * 1.25 + 8.0))

func _tuck_radius() -> float:
	return TUCK_R * _s()

## Pantallas menos panorámicas que un móvil actual (16:9, tablets): la cruceta sube encima
## del SALTO para no tapar al personaje, y RODAR pasa a su izquierda.
func _narrow() -> bool:
	return size.x / maxf(size.y, 1.0) < 1.9

func _action_center() -> Vector2:
	var s := _s()
	if stick_enabled():
		return Vector2(_mirror(size.x - 470.0 * s), size.y - 420.0 * s)
	if _narrow():
		return Vector2(_mirror(size.x - 392.0 * s), size.y - 130.0 * s)
	# Encima del SALTO, ligeramente hacia dentro (a 234 unidades de su centro)
	return Vector2(_mirror(size.x - 216.0 * s), size.y - 385.0 * s)

func _action_radius() -> float:
	return ACTION_R * _s()

func _pad_center() -> Vector2:
	var s := _s()
	if _narrow():
		var hr := _pad_radius() * 1.08
		var jc := _jump_center()
		return Vector2(_mirror(size.x - maxf(215.0 * s, hr + 8.0)), jc.y - _jump_radius() * 1.12 - 6.0 - hr)
	return Vector2(_mirror(size.x - 510.0 * s), size.y - 205.0 * s)

func _pad_radius() -> float:
	if _narrow():
		var free := _jump_center().y - _jump_radius() * 1.12 - 14.0
		return minf(PAD_R * _s(), free * 0.5 / 1.08)
	return PAD_R * _s()

## Reinicio arriba, a la izquierda del botón de pausa (no se escala con el tamaño de
## controles: es un botón de uso ocasional y así nunca invade a los demás).
func _respawn_center() -> Vector2:
	var k := _s() / maxf(Settings.control_scale, 0.01)
	return Vector2(_mirror(size.x - (470.0 if _narrow() else 180.0) * k), 52.0 * k)

## Radios de pulsación (algo mayores que el dibujo para acertar con el pulgar sin mirar).
func hit_radii() -> Dictionary:
	return {"jump": _jump_radius() * 1.12, "action": _action_radius() * 1.2, "pad": _pad_radius() * 1.08,
		"respawn": 44.0 * _s() / maxf(Settings.control_scale, 0.01), "rot": _rot_radius() * 1.2,
		"tuck": _tuck_radius() * 1.25}

## Zonas táctiles activas en el modo actual (las pruebas comprueban que no se solapan).
func zones() -> Dictionary:
	var z := {"jump": _jump_center(), "action": _action_center(), "respawn": _respawn_center()}
	if pad_enabled():
		z["pad"] = _pad_center()
	if stick_enabled():
		z["rot"] = _rot_center()
		z["tuck"] = _tuck_center()
	return z

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
			"tuck":
				f.tuck = true
			"gesture":
				f.tuck = f.tuck or fd.flicked
	f.rot = _rot_vec
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

## 8 direcciones con las principales (↑ ↓ ← →) más anchas: 60° cada una, diagonales 30°.
## Así es difícil sacar un cork o un butterfly sin querer al buscar back/front/lateral.
const CARDINAL_HALF := 30.0
const REPEAT_GAP := 0.12             # s entre dos deslizamientos iguales para contar como doble

static func sector_of(v: Vector2) -> int:
	var ang := rad_to_deg(atan2(v.y, v.x))
	var card := roundf(ang / 90.0) * 90.0
	var sec: int
	if absf(ang - card) <= CARDINAL_HALF:
		sec = int(card / 45.0)
	else:
		sec = int(floorf(ang / 90.0) * 2.0) + 1
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
		var hr := hit_radii()
		if p.distance_to(_jump_center()) < hr.jump:
			role = "jump"
			_pending.jump_pressed = true
			_flash["jump"] = 0.15
		elif p.distance_to(_action_center()) < hr.action:
			role = "action"
			_pending.action_pressed = true
			_flash["action"] = 0.15
		elif p.distance_to(_respawn_center()) < hr.respawn:
			role = "respawn"
			_pending.respawn_pressed = true
		elif stick_enabled() and p.distance_to(_tuck_center()) < hr.tuck:
			role = "tuck"
			_flash["tuck"] = 0.15
		elif stick_enabled() and p.distance_to(_rot_center()) < hr.rot:
			# Joystick flotante: el origen es donde se apoya el pulgar (sin giro accidental al tocar)
			role = "rot"
			info["origin"] = p
			info["armed"] = true
			info["max"] = 0.0
			info["cand"] = 99
			info["cand_t"] = 0.0
			_rot_vec = Vector2.ZERO
		elif pad_enabled() and p.distance_to(_pad_center()) < hr.pad:
			role = "pad"
			var v := p - _pad_center()
			if v.length() < _pad_radius() * 0.3:
				# Centro = GIRO: patada giratoria 360/540/720, o tirabuzón completo durante un mortal
				_pending.kick = true
				_flash["kick"] = 0.35
			else:
				var sec := sector_of(Vector2(v.x, -v.y))
				info.sector = sec
				_emit_flick(sector_dir(sec))
		elif _is_move_side(p):
			role = "move"
			_joy_base = p
			_joy_vec = Vector2.ZERO
		else:
			role = "camera" if stick_enabled() else "gesture"
			_hint_time = 99.0
		info["role"] = role
		_fingers[e.index] = info
	else:
		var f: Dictionary = _fingers.get(e.index, {})
		if f.is_empty():
			return
		if f.role == "move":
			_joy_vec = Vector2.ZERO
		elif f.role == "rot":
			_rot_vec = Vector2.ZERO
			if f.max < 0.3 and _time - f.time < 0.3:
				_pending.kick = true             # toque sin inclinar = GIRO
				_flash["kick"] = 0.35
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
			var r := JOY_R * 0.8 * _s()
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
			pass   # la cruceta solo cuenta el toque: arrastrar el dedo no lanza trucos extra
		"rot":
			_rot_drag(f, e.position)
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

## Joystick derecho: vector analógico + eventos de truco al inclinarlo (umbral 0,55) o al
## cambiar de dirección manteniéndolo inclinado (tras 70 ms en la nueva dirección).
func _rot_drag(f: Dictionary, pos: Vector2) -> void:
	var d: Vector2 = pos - f.origin
	var trav := _rot_travel()
	if d.length() > trav * 1.35:
		f.origin = pos - d.normalized() * trav * 1.35   # el origen sigue al pulgar si se pasa
		d = pos - f.origin
	var v := Vector2(d.x, -d.y) / trav
	_rot_vec = v.limit_length(1.0)
	f.max = maxf(f.max, _rot_vec.length())
	var m := _rot_vec.length()
	if m < 0.3:
		f.armed = true
		f.cand = 99
		return
	if m < 0.55:
		return
	var sec := sector_of(_rot_vec)
	if f.armed:
		f.armed = false
		f.sector = sec
		f.cand = 99
		_emit_flick(sector_dir(sec))
	elif sec != f.sector:
		if f.cand != sec:
			f.cand = sec
			f.cand_t = _time
		elif _time - f.cand_t > 0.07:
			f.sector = sec
			f.cand = 99
			_emit_flick(sector_dir(sec))

## Deslizamiento con el dedo apoyado: primer gesto = acrobacia; gestos siguientes = añadidos.
func _swipe(f: Dictionary, pos: Vector2) -> void:
	var disp: Vector2 = pos - f.anchor
	var thr := _flick_px() * (1.0 if not f.flicked else 1.15)
	if disp.length() > thr:
		var v := Vector2(disp.x, -disp.y)
		# Misma dirección otra vez (tras una pausa breve) = otra vuelta: doble mortal
		if not f.flicked or sector_of(v) != f.sector or _time - f.get("emit_t", 0.0) > REPEAT_GAP:
			_emit_flick(v)
			f.sector = sector_of(v)
			f["emit_t"] = _time
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
	var white := Color(1, 1, 1, minf(a + 0.3, 1.0))
	var dark := Color(0.05, 0.07, 0.1, a * 0.6)
	var accent := Color(0.15, 0.85, 0.78, minf(a + 0.2, 1.0))
	var font := get_theme_default_font()
	# Joystick
	var joy_active := false
	for f in _fingers.values():
		if f.role == "move":
			joy_active = true
	var jr := JOY_R * s
	var base := _joy_base if joy_active else _joy_idle()
	draw_circle(base, jr, dark)
	draw_arc(base, jr, 0, TAU, 56, white, 4.0 * s, true)
	var knob := base + Vector2(_joy_vec.x, -_joy_vec.y) * jr * 0.8
	draw_circle(knob, 48.0 * s, Color(1, 1, 1, a * (0.95 if joy_active else 0.55)))
	if _joy_vec.length() > 0.93:
		_label(font, base + Vector2(0, -jr - 26 * s), "SPRINT", 26 * s, accent)
	# Salto (con pista de deslizamiento)
	var jc := _jump_center()
	var jheld := false
	for f in _fingers.values():
		if f.role == "jump":
			jheld = true
	draw_circle(jc, _jump_radius(), accent if (jheld or _flash.has("jump")) else dark)
	draw_arc(jc, _jump_radius(), 0, TAU, 64, white, 4.0 * s, true)
	_label(font, jc + Vector2(0, -10 * s), "SALTO", 40 * s, white)
	if gestures_enabled():
		_label(font, jc + Vector2(0, 36 * s), "desliza = truco", 19 * s, Color(1, 1, 1, a + 0.15))
	# Acción contextual
	var ac := _action_center()
	draw_circle(ac, _action_radius(), accent if _flash.has("action") else dark)
	draw_arc(ac, _action_radius(), 0, TAU, 48, white, 3.0 * s, true)
	_label(font, ac, context_label if context_label != "" else "RODAR", 24 * s, white)
	# Reinicio
	var rc := _respawn_center()
	var rs := s / maxf(Settings.control_scale, 0.01)
	draw_circle(rc, 38.0 * rs, dark)
	var r := 16.0 * rs
	draw_arc(rc, r, -PI * 0.35, PI * 1.45, 24, white, 3.5 * s, true)
	var tip := rc + Vector2(cos(-PI * 0.35), sin(-PI * 0.35)) * r
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-8, -6) * rs, tip + Vector2(7, -7) * rs, tip + Vector2(1, 7) * rs]), white)
	# Cruceta de acrobacias
	if pad_enabled():
		_draw_pad(font, s, a, white, dark, accent)
	if stick_enabled():
		_draw_rot_stick(font, s, a, white, dark, accent)
		var tc := _tuck_center()
		var tuck_on := _flash.has("tuck")
		for f in _fingers.values():
			if f.role == "tuck":
				tuck_on = true
		draw_circle(tc, _tuck_radius(), accent if tuck_on else dark)
		draw_arc(tc, _tuck_radius(), 0, TAU, 48, white, 3.0 * s, true)
		_label(font, tc, "AGRUPAR", 21 * s, white)
	# Pista de gestos al principio
	if _hint_time < 9.0 and gestures_enabled():
		var hc := Vector2(size.x * 0.5, size.y * 0.16)
		var ha := clampf(1.0 - (_hint_time - 7.0) / 2.0, 0.0, 1.0)
		if stick_enabled():
			_label(font, hc, "SALTO y luego joystick derecho: abajo back, arriba front, lados sideflip", 24 * s, Color(1, 1, 1, ha))
			_label(font, hc + Vector2(0, 36 * s), "Más inclinado = más agrupado y más rápido; suelta para abrir; en contra frena", 24 * s, Color(1, 1, 1, ha))
			_label(font, hc + Vector2(0, 72 * s), "Inclina otra vez = otra vuelta · lado durante un mortal = tirabuzón · toque = GIRO", 24 * s, Color(1, 1, 1, ha))
			return
		_label(font, hc, "Pulsa SALTO y desliza: abajo back, arriba front, lados lateral", 24 * s, Color(1, 1, 1, ha))
		_label(font, hc + Vector2(0, 36 * s), "Desliza dos veces igual = doble mortal; en la cruceta, toca dos veces", 24 * s, Color(1, 1, 1, ha))
		_label(font, hc + Vector2(0, 72 * s), "SALTO otra vez en el aire = giro 360 (o tirabuzón durante un mortal)", 24 * s, Color(1, 1, 1, ha))
	# Rastro del gesto
	if _flash.has("flick"):
		for f in _fingers.values():
			if f.role in ["gesture", "jump"]:
				draw_circle(f.pos, 40.0 * s, Color(accent, 0.45))

## Joystick derecho de rotación: base con las 8 direcciones rotuladas y mando analógico.
func _draw_rot_stick(font: Font, s: float, a: float, white: Color, dark: Color, accent: Color) -> void:
	var rc := _rot_center()
	var rr := _rot_radius()
	var finger := {}
	for f in _fingers.values():
		if f.role == "rot":
			finger = f
	var base := rc
	if not finger.is_empty():
		base = finger.origin
	draw_circle(base, rr, Color(dark, dark.a * 0.85))
	# Sector activo resaltado
	var hot := 99
	if not finger.is_empty() and _rot_vec.length() > 0.55:
		hot = sector_of(_rot_vec)
	elif _flash.has("sector"):
		hot = _flash.sector
	for sec in [0, 1, 2, 3, 4, -1, -2, -3]:
		var half := (CARDINAL_HALF if sec % 2 == 0 else 45.0 - CARDINAL_HALF) - 2.0
		var c := -deg_to_rad(sec * 45.0)
		var pts := PackedVector2Array()
		for i in 7:
			var ang := c + deg_to_rad(lerpf(-half, half, i / 6.0))
			pts.append(base + Vector2(cos(ang), sin(ang)) * rr * 0.97)
		for i in 7:
			var ang := c + deg_to_rad(lerpf(half, -half, i / 6.0))
			pts.append(base + Vector2(cos(ang), sin(ang)) * rr * 0.72)
		draw_colored_polygon(pts, accent if sec == hot else Color(1, 1, 1, a * 0.12))
		var d := sector_dir(sec)
		var lbl: String = PAD_LABELS[sec]
		var fs := (13.0 if sec % 2 != 0 else 17.0)
		_label(font, base + Vector2(d.x, -d.y) * rr * 0.845, lbl, fs * s, white)
	draw_arc(base, rr, 0, TAU, 64, Color(white, white.a * 0.8), 3.0 * s, true)
	# Mando
	var knob := base + Vector2(_rot_vec.x, -_rot_vec.y) * _rot_travel()
	draw_circle(knob, 50.0 * s, Color(1, 1, 1, a * (0.95 if not finger.is_empty() else 0.5)) if not _flash.has("kick") else accent)
	_label(font, knob, "GIRO", 17 * s, Color(0.1, 0.12, 0.15, 0.9))

## Cruceta en 8 sectores grandes (cuñas): cualquier punto del sector cuenta, no solo el círculo.
func _draw_pad(font: Font, s: float, a: float, white: Color, dark: Color, accent: Color) -> void:
	var pc := _pad_center()
	var pr := _pad_radius()
	var active_sec := 99
	for f in _fingers.values():
		if f.role == "pad":
			active_sec = f.sector
	draw_circle(pc, pr, Color(dark, dark.a * 0.85))
	for sec in [0, 1, 2, 3, 4, -1, -2, -3]:
		var hot: bool = sec == active_sec or (_flash.has("sector") and _flash.sector == sec)
		# Cuña del sector (ángulo de pantalla: y hacia abajo)
		var half := (CARDINAL_HALF if sec % 2 == 0 else 45.0 - CARDINAL_HALF) - 2.0
		var a0 := -deg_to_rad(sec * 45.0) - deg_to_rad(half)
		var a1 := -deg_to_rad(sec * 45.0) + deg_to_rad(half)
		var pts := PackedVector2Array()
		var inner := pr * 0.3
		for i in 9:
			var ang := lerpf(a0, a1, i / 8.0)
			pts.append(pc + Vector2(cos(ang), sin(ang)) * pr * 0.97)
		for i in 9:
			var ang := lerpf(a1, a0, i / 8.0)
			pts.append(pc + Vector2(cos(ang), sin(ang)) * inner)
		draw_colored_polygon(pts, accent if hot else Color(1, 1, 1, a * 0.16))
		var d := sector_dir(sec)
		var lbl: String = PAD_LABELS[sec]
		var fs := (13.0 if lbl.length() > 5 else 16.0) if sec % 2 != 0 else (17.0 if lbl.length() > 5 else 20.0)
		_label(font, pc + Vector2(d.x, -d.y) * pr * 0.68, lbl, fs * s, white)
	draw_arc(pc, pr, 0, TAU, 64, Color(white, white.a * 0.8), 3.0 * s, true)
	draw_circle(pc, pr * 0.28, accent if _flash.has("kick") else Color(1, 1, 1, a * 0.22))
	_label(font, pc, "GIRO", 19 * s, Color(1, 1, 1, a + 0.25))

func _label(font: Font, center: Vector2, text: String, fsize: float, color: Color) -> void:
	var fs := int(fsize)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string_outline(font, center + Vector2(-w * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, int(fs * 0.18)), Color(0, 0, 0, color.a * 0.55))
	draw_string(font, center + Vector2(-w * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
