class_name TouchControls
extends Control
## Controles táctiles híbridos (multitáctil). Modo por defecto: DOBLE JOYSTICK.
## - Joystick izquierdo (pulgar izquierdo): movimiento analógico; a fondo = sprint.
## - Joystick derecho (pulgar derecho): rotación del cuerpo. Inclinarlo arranca la acrobacia
##   en esa dirección; cuanto más se inclina hacia el giro, más se agrupa y más rápido gira;
##   soltarlo abre el cuerpo; tirar en contra frena y prepara el aterrizaje. Tocar sin
##   inclinar = GIRO (360 / tirabuzón). Volver a inclinar = otra vuelta o tirabuzón añadido.
## - Botones: SALTO, VAULT (superar obstáculos), AGARRAR (bordes y paredes; SOLTAR colgado)
##   y RODAR. En el suelo, el joystick derecho hace tricking de suelo (rueda, rondada,
##   flic-flac...). El reinicio está en el menú de pausa.
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
	var vault_pressed := false
	var grab_pressed := false
	var grab_held := false
	var camera_recenter := false
	var rot_flick := Vector2.ZERO
	var skill := ""
	var double := false
	var cork := false
	var butterfly := false
	var skill_hold := false

var grab_label := "AGARRAR"           # SOLTAR cuando está colgado
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
var _cam_tap_t := -9.0                # último toque en la zona de cámara (doble toque = recentrar)
var _cam_tap_p := Vector2.ZERO
var cam_used := false                 # ya se ha movido la cámara: la indicación se atenúa

const FLICK_TIME := 0.22              # en el suelo: un gesto rápido es acrobacia, lento es cámara
const FLICK_PX := 48.0
const PAD_LABELS := {0: "LATERAL", 1: "ADEL.+GIRO", 2: "ADELANTE", 3: "RUEDA AÉREA", 4: "LATERAL",
	-1: "SACACORCHOS", -2: "ATRÁS", -3: "SACACORCHOS"}

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

## trick_controls: 0 doble joystick · 1 solo gestos · 2 solo cruceta · 3 gestos + cruceta · 4 botonera
func gestures_enabled() -> bool:
	return Settings.trick_controls != 2 and Settings.trick_controls != 4

func pad_enabled() -> bool:
	return Settings.trick_controls in [2, 3]

## Joystick GIRO presente (doble joystick y botonera): los tirabuzones son solo suyos.
func stick_enabled() -> bool:
	return Settings.trick_controls == 0 or Settings.trick_controls == 4

## Botonera: SALTO grande abajo a la derecha y un arco de 3/4 de círculo con un botón por
## movimiento (mortales, movimientos de suelo y de parkour).
func ring_enabled() -> bool:
	return Settings.trick_controls == 4

## [rótulo, tipo, valor]. Tipos: flip (sector de la acrobacia), cork, piru, kick (patada 360),
## butterfly, skill (habilidad de suelo), change (CAMBIAR de página).
## Arco de 270° alrededor de SALTO con 8 botones GRANDES por página y CAMBIAR al final (abajo a la
## derecha). VAULT, AGARRAR y RODAR van aparte, en una fila encima del joystick GIRO.
const RING_FIXED := [["VAULT", "vault", ""], ["AGARRAR", "grab", ""], ["RODAR", "action", ""]]
const RING_CHANGE := ["CAMBIAR", "change", ""]
const RING_PAGES := [
	{"name": "MORTALES", "buttons": [
		["ATRÁS", "flip", -2], ["ADELANTE", "flip", 2], ["LATERAL\nIZQ.", "flip", 4], ["LATERAL\nDER.", "flip", 0],
		["CORK", "cork", -2], ["PIRU", "piru", -2], ["AERIAL /\nMARIPOSA", "flip", 3], ["PATADA\n360", "kick", 0]]},
	{"name": "SUELO", "buttons": [
		["RONDADA", "skill", "roundoff"], ["FLIC-FLAC", "skill", "bhs"], ["RUEDA", "skill", "cartwheel"],
		["PALOMA", "skill", "fhs"], ["MACACO", "skill", "macaco"], ["PINO", "skill", "handstand"],
		["ATRÁS", "flip", -2], ["CORK", "cork", -2]]},
	{"name": "TRICKING", "buttons": [
		["HOOK", "skill", "hook"], ["CRESCENT", "skill", "crescent"], ["CRESCENT\nINVERSA", "skill", "reverse_crescent"],
		["RAIZ", "skill", "raiz"], ["TD RAIZ", "skill", "td_raiz"], ["SCOOT", "skill", "scoot"],
		["MARIPOSA", "butterfly", 3], ["CORK", "cork", -2]]},
	{"name": "GIMNASIA", "buttons": [
		["BACK\nWALKOVER", "skill", "back_walkover"], ["FRONT\nWALKOVER", "skill", "front_walkover"],
		["VALDEZ", "skill", "valdez"], ["VOLTERETA\nAL PINO", "skill", "ber"], ["PINO", "skill", "handstand"],
		["RONDADA", "skill", "roundoff"], ["FLIC-FLAC", "skill", "bhs"], ["ATRÁS", "flip", -2]]},
]
var ring_page := 0
var _ring_anim := 0.0                 # giro animado de la rueda al cambiar de página (-1..1 → 0)

func ring_buttons() -> Array:
	var out: Array = RING_PAGES[ring_page].buttons.duplicate()
	out.append(RING_CHANGE)
	return out

static func all_ring_labels() -> Array:
	var out := []
	for b in RING_FIXED: out.append(String(b[0]))
	out.append(String(RING_CHANGE[0]))
	for pg in RING_PAGES:
		out.append(String(pg.name))
		for b in pg.buttons: out.append(String(b[0]))
	return out

## Página donde está un botón (para las pruebas y la ayuda).
static func page_of(label: String) -> int:
	for i in RING_PAGES.size():
		for b in RING_PAGES[i].buttons:
			if String(b[0]).replace("\n", " ") == label:
				return i
	return -1

## Gira la rueda a otra página (+1 siguiente, -1 anterior).
func ring_turn(d: int) -> void:
	ring_page = posmod(ring_page + d, RING_PAGES.size())
	_ring_anim = float(d)
	_flash["page"] = 1.2

const RING_JUMP_R := 95.0
const RING_R := 205.0
const RING_BTN_R := 44.0
const RING_A0 := 225.0               # grados (matemáticos, y arriba): abajo a la izquierda
const RING_SPAN := 270.0
const PARK_R := 44.0                 # VAULT, AGARRAR, RODAR en la botonera

func _ring_center() -> Vector2:
	var s := _s()
	return Vector2(_mirror(size.x - 255.0 * s), size.y - 195.0 * s)

func ring_button_center(i: int, animated := false) -> Vector2:
	var n := ring_buttons().size()
	var a_deg := RING_A0 - RING_SPAN * float(i) / float(n - 1)
	if animated and i < n - 1:
		a_deg += _ring_anim * 40.0          # los botones de la página entran girando por el arco
	var ang := deg_to_rad(a_deg)
	var v := Vector2(cos(ang), -sin(ang)) * RING_R * _s()
	if Settings.left_handed:
		v.x = -v.x
	return _ring_center() + v

func ring_button_radius() -> float:
	return RING_BTN_R * _s()

func ring_button_at(p: Vector2) -> int:
	var best := -1
	var bd := ring_button_radius() * 1.06
	for i in ring_buttons().size():
		var d := p.distance_to(ring_button_center(i))
		if d < bd:
			bd = d
			best = i
	return best

## Botonera: VAULT (0), AGARRAR (1) y RODAR (2). Abajo, entre el joystick de movimiento y el
## GIRO (debajo de los pies del atleta, sin taparlo); si no caben ahí, en fila encima del GIRO.
func _park_center(i: int) -> Vector2:
	var s := _s()
	var rc := _rot_center()
	var r := PARK_R * s * 1.1
	var side := -1.0 if not Settings.left_handed else 1.0
	var joy_edge := (JOY_R * s + 50.0 * s) + JOY_R * s          # borde del joystick en reposo
	var first := absf(rc.x - _mirror(0.0)) - _rot_radius() * 1.08 - 12.0 * s - r
	var last := first - 2.0 * (2.0 * r + 10.0 * s)
	if last - r > joy_edge + 8.0 * s:
		var x := rc.x + side * (_rot_radius() * 1.08 + 12.0 * s + r + float(i) * (2.0 * r + 10.0 * s))
		return Vector2(x, size.y - r - 8.0 * s)
	var y := rc.y - _rot_radius() * 1.08 - 14.0 * s - r
	var dx := (float(i) - 1.0) * 104.0 * s - 40.0 * s
	if Settings.left_handed:
		dx = -dx
	return Vector2(rc.x + dx, y)

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
const STICK_JUMP_R := 128.0          # rueda SALTO / MORTALES (centro SALTO, 4 zonas de mortal)
const WHEEL_CORE := 0.42              # fracción del radio que ocupa el centro (SALTO)
const WHEEL_LABELS := {2: "ADELANTE", -2: "ATRÁS", 0: "LATERAL", 4: "LATERAL"}
const SMALL_R := 62.0                 # VAULT, AGARRAR, RODAR

func _jump_center() -> Vector2:
	var s := _s()
	if ring_enabled():
		return _ring_center()
	if stick_enabled():
		return Vector2(_mirror(size.x - 300.0 * s), maxf(size.y - 430.0 * s, _jump_radius() * 1.03 + 8.0))
	return Vector2(_mirror(size.x - 158.0 * s), size.y - 158.0 * s)

func _jump_radius() -> float:
	if ring_enabled():
		return RING_JUMP_R * _s()
	return (STICK_JUMP_R if stick_enabled() else JUMP_R) * _s()

func _rot_center() -> Vector2:
	var s := _s()
	if ring_enabled():
		# Justo a la izquierda del arco de botones (sin invadir el joystick de movimiento)
		var off := (RING_R + RING_BTN_R * 1.06 + 112.0 * 1.08 + 14.0) * s
		var cx := _ring_center().x + (off if Settings.left_handed else -off)
		return Vector2(cx, size.y - 150.0 * s)
	return Vector2(_mirror(size.x - 520.0 * s), size.y - 195.0 * s)

func _rot_radius() -> float:
	return (112.0 if ring_enabled() else ROT_R) * _s()

## Recorrido del joystick derecho hasta la inclinación máxima (configurable con la sensibilidad).
func _rot_travel() -> float:
	return ROT_R * 0.62 * _s() / maxf(Settings.gesture_sensitivity, 0.2)

## Columna derecha (doble joystick): VAULT arriba, AGARRAR en medio, RODAR abajo.
## Se compacta con tamaños grandes para no invadir el botón de pausa ni salir de pantalla.
func _column_y(i: int) -> float:
	var s := _s()
	var hit := _small_radius() * 1.15
	var bottom := size.y - maxf(100.0 * s, hit + 8.0)
	var top_min := 80.0 + hit
	var step := minf(230.0 * s, (bottom - top_min) / 2.0)
	return bottom - step * (2 - i)

func _column_x() -> float:
	return _mirror(size.x - 82.0 * _s())

func _small_radius() -> float:
	return (PARK_R if ring_enabled() else SMALL_R) * _s()

func _vault_center() -> Vector2:
	if ring_enabled():
		return _park_center(0)
	return Vector2(_column_x(), _column_y(0))

func _grab_center() -> Vector2:
	if ring_enabled():
		return _park_center(1)
	return Vector2(_column_x(), _column_y(1))

## Pantallas menos panorámicas que un móvil actual (16:9, tablets): la cruceta sube encima
## del SALTO para no tapar al personaje, y RODAR pasa a su izquierda.
func _narrow() -> bool:
	return size.x / maxf(size.y, 1.0) < 1.9

func _action_center() -> Vector2:
	var s := _s()
	if ring_enabled():
		return _park_center(2)
	if stick_enabled():
		return Vector2(_column_x(), _column_y(2))
	if _narrow():
		return Vector2(_mirror(size.x - 392.0 * s), size.y - 130.0 * s)
	# Encima del SALTO, ligeramente hacia dentro (a 234 unidades de su centro)
	return Vector2(_mirror(size.x - 216.0 * s), size.y - 385.0 * s)

func _action_radius() -> float:
	if ring_enabled():
		return PARK_R * _s()
	return (SMALL_R if stick_enabled() else ACTION_R) * _s()

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

## Radios de pulsación (algo mayores que el dibujo para acertar con el pulgar sin mirar).
func hit_radii() -> Dictionary:
	if ring_enabled():
		var hr := {"jump": _jump_radius() * 1.04, "rot": _rot_radius() * 1.08,
			"vault": PARK_R * _s() * 1.1, "grab": PARK_R * _s() * 1.1, "action": PARK_R * _s() * 1.1}
		for i in ring_buttons().size():
			hr["ring_%d" % i] = ring_button_radius() * 1.06
		return hr
	var small := 1.15 if stick_enabled() else 1.2
	return {"jump": _jump_radius() * (1.03 if stick_enabled() else 1.12), "action": _action_radius() * small, "pad": _pad_radius() * 1.08,
		"rot": _rot_radius() * 1.08, "vault": _small_radius() * 1.15, "grab": _small_radius() * 1.15}

## Zonas táctiles activas en el modo actual (las pruebas comprueban que no se solapan).
func zones() -> Dictionary:
	if ring_enabled():
		var zr := {"jump": _jump_center(), "rot": _rot_center(), "vault": _vault_center(), "grab": _grab_center(), "action": _action_center()}
		for i in ring_buttons().size():
			zr["ring_%d" % i] = ring_button_center(i)
		return zr
	var z := {"jump": _jump_center(), "action": _action_center()}
	if pad_enabled():
		z["pad"] = _pad_center()
	if stick_enabled():
		z["rot"] = _rot_center()
		z["vault"] = _vault_center()
		z["grab"] = _grab_center()
	return z

## Joystick izquierdo: mitad izquierda salvo la franja superior (que mueve la cámara).
func _is_move_side(p: Vector2) -> bool:
	if p.y < size.y * 0.3 and stick_enabled():
		return false
	return p.x < size.x * 0.42 if not Settings.left_handed else p.x > size.x * 0.58

## Zona libre (arriba, entre el centro y SALTO) donde se indica que arrastrar mueve la cámara.
func camera_hint_pos() -> Vector2:
	return Vector2(_mirror(size.x * 0.62), size.y * 0.3)

func collect() -> TouchFrame:
	var f := _pending
	f.move = _joy_vec
	f.jump_held = false
	f.action_held = false
	f.grab_held = false
	f.tuck = false
	for fd in _fingers.values():
		match fd.role:
			"jump":
				f.jump_held = true
				f.tuck = f.tuck or fd.flicked
			"flipw":
				f.jump_held = true
				f.tuck = true
			"ringflip":
				f.tuck = true            # mantener el botón del mortal = agrupado
			"ringskill":
				f.skill_hold = true      # mantener PINO = sigue en el pino
			"action":
				f.action_held = true
			"pad":
				f.tuck = true
			"grab":
				f.grab_held = true
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

## Rueda de mortales: 4 zonas de 90° (↑ adelante, ↓ atrás, ← → lateral).
static func wheel_sector(v: Vector2) -> int:
	var card := int(roundf(rad_to_deg(atan2(v.y, v.x)) / 90.0)) * 2
	return 4 if card == -4 else card

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
		var rb := ring_button_at(p) if ring_enabled() else -1
		if rb >= 0:
			# Botonera: cada botón es un movimiento
			var bt: Array = ring_buttons()[rb]
			info.sector = rb
			_flash["ring"] = 0.3
			_flash["ring_i"] = rb
			match String(bt[1]):
				"flip", "flip2", "cork", "piru", "butterfly":
					role = "ringflip"
					if not air_mode:
						_pending.jump_pressed = true
					_emit_flick(sector_dir(int(bt[2])))
					_pending.double = bt[1] == "flip2"
					_pending.cork = bt[1] == "cork"
					_pending.kick = bt[1] == "piru"          # mortal atrás + tirabuzón de 360
					_pending.butterfly = bt[1] == "butterfly"
				"kick":
					role = "ringflip"
					if not air_mode:
						_pending.jump_pressed = true
					_pending.kick = true
				"change":
					role = "ringchange"
					info["turned"] = false
				"skill":
					role = "ringskill"
					_pending.skill = String(bt[2])
				"vault":
					role = "vault"
					_pending.vault_pressed = true
				"grab":
					role = "grab"
					_pending.grab_pressed = true
				"action":
					role = "action"
					_pending.action_pressed = true
		elif p.distance_to(_jump_center()) < hr.jump and stick_enabled() and not ring_enabled() \
				and p.distance_to(_jump_center()) > _jump_radius() * WHEEL_CORE:
			# Rueda: zona de mortal = salta y hace ese mortal (en el aire: lo empieza o suma otra
			# vuelta). Mantener el dedo = agruparse; soltar = abrirse.
			role = "flipw"
			var v := p - _jump_center()
			var sec := wheel_sector(Vector2(v.x, -v.y))
			info.sector = sec
			if not air_mode:
				_pending.jump_pressed = true
			_emit_flick(sector_dir(sec))
			_flash["wheel"] = 0.3
			_flash["wheel_sec"] = sec
		elif p.distance_to(_jump_center()) < hr.jump:
			role = "jump"
			_pending.jump_pressed = true
			_flash["jump"] = 0.15
		elif p.distance_to(_action_center()) < hr.action:
			role = "action"
			_pending.action_pressed = true
			_flash["action"] = 0.15
		elif stick_enabled() and p.distance_to(_vault_center()) < hr.vault:
			role = "vault"
			_pending.vault_pressed = true
			_flash["vault"] = 0.15
		elif stick_enabled() and p.distance_to(_grab_center()) < hr.grab:
			role = "grab"
			_pending.grab_pressed = true
			_flash["grab"] = 0.15
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
			if role == "camera":
				# Doble toque rápido en el mismo sitio = cámara detrás del atleta
				if _time - _cam_tap_t < 0.32 and p.distance_to(_cam_tap_p) < 70.0 * _s():
					_pending.camera_recenter = true
					_flash["recenter"] = 0.6
					_cam_tap_t = -9.0
				else:
					_cam_tap_t = _time
					_cam_tap_p = p
		info["role"] = role
		_fingers[e.index] = info
	else:
		var f: Dictionary = _fingers.get(e.index, {})
		if f.is_empty():
			return
		if f.role == "move":
			_joy_vec = Vector2.ZERO
		elif f.role == "ringchange":
			if not f.get("turned", false):
				ring_turn(1)                      # tocar CAMBIAR = siguiente página
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
		"ringchange":
			# Deslizar sobre CAMBIAR: arriba = siguiente página, abajo = anterior
			var dy: float = e.position.y - (f.start as Vector2).y
			if not f.get("turned", false) and absf(dy) > 34.0 * _s():
				ring_turn(1 if dy < 0.0 else -1)
				f["turned"] = true
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
			if e.position.distance_to(f.start) > 20.0:
				cam_used = true
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
	# Doble joystick: el joystick derecho es el GIRO (analógico); su inclinación brusca solo
	# cuenta para los movimientos de suelo, nunca lanza un mortal.
	if f.armed:
		f.armed = false
		f.sector = sec
		f.cand = 99
		_pending.rot_flick = sector_dir(sec)
	elif sec != f.sector:
		if f.cand != sec:
			f.cand = sec
			f.cand_t = _time
		elif _time - f.cand_t > 0.07:
			f.sector = sec
			f.cand = 99
			_pending.rot_flick = sector_dir(sec)

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
		if k == "sector" or k == "wheel_sec" or k == "ring_i":
			continue
		_flash[k] -= dt
		if _flash[k] <= 0.0:
			_flash.erase(k)
	if not _flash.has("flick"):
		_flash.erase("sector")
	if not _flash.has("wheel"):
		_flash.erase("wheel_sec")
	if not _flash.has("ring"):
		_flash.erase("ring_i")
	_ring_anim = move_toward(_ring_anim, 0.0, dt * 5.0)
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
	if ring_enabled():
		_draw_ring(font, s, a, white, dark, accent, jheld)
	elif stick_enabled():
		_draw_wheel(font, s, a, white, dark, accent)
	else:
		draw_circle(jc, _jump_radius(), accent if (jheld or _flash.has("jump")) else dark)
		draw_arc(jc, _jump_radius(), 0, TAU, 64, white, 4.0 * s, true)
		_label(font, jc + Vector2(0, -10 * s), "SALTO", 40 * s, white)
		if gestures_enabled():
			_label(font, jc + Vector2(0, 36 * s), "desliza = truco", 19 * s, Color(1, 1, 1, a + 0.15))
	if ring_enabled():
		# VAULT, AGARRAR y RODAR (fila encima del joystick GIRO)
		var heldp := {}
		for f in _fingers.values():
			heldp[f.role] = true
		for pk in [["vault", _vault_center(), "VAULT", Color(0.35, 0.65, 1.0, white.a)], ["grab", _grab_center(), grab_label, white],
				["action", _action_center(), "RODAR", Color(0.35, 0.95, 0.45, white.a)]]:
			draw_circle(pk[1], PARK_R * s, accent if (heldp.has(pk[0]) or _flash.has(pk[0])) else dark)
			draw_arc(pk[1], PARK_R * s, 0, TAU, 40, pk[3], 3.5 * s, true)
			_label(font, pk[1], pk[2], 16 * s, white)
		_draw_rot_stick(font, s, a, white, dark, accent)
		_draw_camera_hint(font, s, a)
		_draw_ring_hint(font, s)
		return
	# RODAR (y, en los modos clásicos, acción contextual)
	var ac := _action_center()
	var roll_ring := Color(0.35, 0.95, 0.45, white.a) if stick_enabled() else white
	draw_circle(ac, _action_radius(), accent if _flash.has("action") else dark)
	draw_arc(ac, _action_radius(), 0, TAU, 48, roll_ring, 4.0 * s, true)
	var alabel := "RODAR" if stick_enabled() else (context_label if context_label != "" else "RODAR")
	_label(font, ac, alabel, 22 * s, white)
	if stick_enabled():
		var held := {}
		for f in _fingers.values():
			held[f.role] = true
		var vc := _vault_center()
		draw_circle(vc, _small_radius(), accent if (held.has("vault") or _flash.has("vault")) else dark)
		draw_arc(vc, _small_radius(), 0, TAU, 48, Color(0.35, 0.65, 1.0, white.a), 4.0 * s, true)
		_label(font, vc, "VAULT", 22 * s, white)
		var gc := _grab_center()
		draw_circle(gc, _small_radius(), accent if (held.has("grab") or _flash.has("grab")) else dark)
		draw_arc(gc, _small_radius(), 0, TAU, 48, white, 4.0 * s, true)
		_label(font, gc, grab_label, 20 * s, white)
	# Cruceta de acrobacias
	if pad_enabled():
		_draw_pad(font, s, a, white, dark, accent)
	if stick_enabled():
		_draw_rot_stick(font, s, a, white, dark, accent)
		_draw_camera_hint(font, s, a)
	# Pista de gestos al principio
	if _hint_time < 9.0 and gestures_enabled():
		var hc := Vector2(size.x * 0.5, size.y * 0.16)
		var ha := clampf(1.0 - (_hint_time - 7.0) / 2.0, 0.0, 1.0)
		if stick_enabled():
			_label(font, hc, "Rueda de SALTO: ADELANTE · ATRÁS · LATERAL = mortales (mantén = agrupado)", 24 * s, Color(1, 1, 1, ha))
			_label(font, hc + Vector2(0, 36 * s), "Joystick GIRO durante el mortal = ¼ (híper), ½ o tirabuzón · en el suelo: soltar, mantener o arco", 24 * s, Color(1, 1, 1, ha))
			_label(font, hc + Vector2(0, 72 * s), "Biblioteca de movimientos y tutorial: menú de pausa", 24 * s, Color(1, 1, 1, ha))
			return
		_label(font, hc, "Pulsa SALTO y desliza: abajo mortal atrás, arriba adelante, lados lateral", 24 * s, Color(1, 1, 1, ha))
		_label(font, hc + Vector2(0, 36 * s), "Desliza dos veces igual = doble mortal; en la cruceta, toca dos veces", 24 * s, Color(1, 1, 1, ha))
		_label(font, hc + Vector2(0, 72 * s), "SALTO otra vez en el aire = giro 360 (o tirabuzón durante un mortal)", 24 * s, Color(1, 1, 1, ha))
	# Rastro del gesto
	if _flash.has("flick"):
		for f in _fingers.values():
			if f.role in ["gesture", "jump"]:
				draw_circle(f.pos, 40.0 * s, Color(accent, 0.45))

## Cámara: cualquier zona libre de la pantalla se arrastra para girarla. Se indica con un
## rótulo tenue (más visible hasta que se usa) y un anillo bajo el dedo mientras se arrastra.
func _draw_camera_hint(font: Font, s: float, a: float) -> void:
	var cam_finger := {}
	for f in _fingers.values():
		if f.role == "camera":
			cam_finger = f
	if not cam_finger.is_empty():
		draw_arc(cam_finger.pos, 46.0 * s, 0, TAU, 40, Color(1, 1, 1, 0.5), 3.0 * s, true)
		draw_line(cam_finger.start, cam_finger.pos, Color(1, 1, 1, 0.25), 3.0 * s, true)
	if _flash.has("recenter"):
		_label(font, camera_hint_pos(), "CÁMARA DETRÁS", 24 * s, Color(0.4, 1, 0.9, minf(1.0, _flash.recenter * 2.0)))
		return
	if _hint_time < 9.0 and gestures_enabled():
		return                         # no se superpone a la ayuda inicial
	var ha := (minf(a + 0.35, 1.0) if not cam_used else a * 0.45)
	var c := camera_hint_pos()
	var col := Color(1, 1, 1, ha)
	if not cam_used:
		# Fondo oscuro suave para que se lea sobre cielo o paredes claras
		var box := Rect2(c + Vector2(-175, -24) * s, Vector2(350, 62) * s)
		draw_rect(box, Color(0.05, 0.07, 0.1, 0.35 * ha))
	_label(font, c, "<   CÁMARA   >", 22 * s, col)
	_label(font, c + Vector2(0, 26 * s), "arrastra aquí · doble toque = detrás", 15 * s, col)

## Botonera: SALTO grande y el arco de botones (cada uno con su movimiento). Colores por familia:
## mortales (turquesa), suelo (naranja), parkour (azul/verde).
func _draw_ring(font: Font, s: float, a: float, white: Color, dark: Color, accent: Color, jheld: bool) -> void:
	var jc := _jump_center()
	var held := {}
	for f in _fingers.values():
		if f.role in ["ringflip", "ringskill", "vault", "grab", "action", "ringchange"]:
			held[int(f.get("sector", -1))] = true
	var flash_i: int = _flash.get("ring_i", -1)
	var br := ring_button_radius()
	var btns := ring_buttons()
	var page_a := clampf(1.0 - absf(_ring_anim), 0.0, 1.0)
	for i in btns.size():
		var bt: Array = btns[i]
		var c := ring_button_center(i, true)
		var hot: bool = held.has(i) or i == flash_i
		var ring_col := white
		match String(bt[1]):
			"flip", "flip2", "cork", "piru", "kick", "butterfly": ring_col = Color(0.35, 0.95, 0.9, white.a)
			"change": ring_col = Color(1.0, 0.9, 0.3, white.a)
			"skill": ring_col = Color(1.0, 0.62, 0.25, white.a)
			"vault": ring_col = Color(0.35, 0.65, 1.0, white.a)
			"action": ring_col = Color(0.35, 0.95, 0.45, white.a)
		draw_circle(c, br, accent if hot else dark)
		draw_arc(c, br, 0, TAU, 32, ring_col, 3.0 * s, true)
		var lbl := String(bt[0])
		if bt[1] == "grab":
			lbl = grab_label
		var lines := lbl.split("\n")
		var fs := (14.0 if lines.size() > 1 or lbl.length() > 8 else 17.0) * s
		for li in lines.size():
			_label(font, c + Vector2(0, (li - (lines.size() - 1) * 0.5) * fs * 1.05), lines[li], fs, white)
	draw_circle(jc, _jump_radius(), accent if (jheld or _flash.has("jump")) else dark)
	draw_arc(jc, _jump_radius(), 0, TAU, 64, white, 4.0 * s, true)
	_label(font, jc, "SALTO", 34 * s, white)
	# Página actual de la rueda (más visible justo después de cambiar)
	var pa := minf(1.0, 0.55 + float(_flash.get("page", 0.0)))
	var top := ring_button_center(int(btns.size() / 2))
	_label(font, top + Vector2(0, -ring_button_radius() - 18 * s), "%s  %d/%d" % [RING_PAGES[ring_page].name, ring_page + 1, RING_PAGES.size()], 20 * s, Color(1, 0.9, 0.3, pa))
	var _unused := page_a

func _draw_ring_hint(font: Font, s: float) -> void:
	if _hint_time >= 9.0:
		return
	var hc := Vector2(size.x * 0.5, size.y * 0.16)
	var ha := clampf(1.0 - (_hint_time - 7.0) / 2.0, 0.0, 1.0)
	_label(font, hc, "Cada botón del arco es un movimiento. Mantén el botón del mortal = sigue girando (doble, triple...)", 22 * s, Color(1, 1, 1, ha))
	_label(font, hc + Vector2(0, 34 * s), "CAMBIAR (tocar o deslizar arriba/abajo) gira la rueda: MORTALES · SUELO · TRICKING · GIMNASIA", 22 * s, Color(1, 1, 1, ha))

## Rueda SALTO / MORTALES: centro SALTO y 4 zonas (ADELANTE, ATRÁS, LATERAL ← →).
func _draw_wheel(font: Font, s: float, a: float, white: Color, dark: Color, accent: Color) -> void:
	var jc := _jump_center()
	var r := _jump_radius()
	var held_sec := 99
	var core_held := false
	for f in _fingers.values():
		if f.role == "flipw":
			held_sec = f.sector
		elif f.role == "jump":
			core_held = true
	if held_sec == 99 and _flash.has("wheel"):
		held_sec = _flash.get("wheel_sec", 99)
	draw_circle(jc, r, Color(dark, dark.a * 0.85))
	for sec in [2, -2, 0, 4]:
		var c := -deg_to_rad(sec * 45.0)
		var pts := PackedVector2Array()
		for i in 9:
			var ang := c + deg_to_rad(lerpf(-43.0, 43.0, i / 8.0))
			pts.append(jc + Vector2(cos(ang), sin(ang)) * r * 0.97)
		for i in 9:
			var ang := c + deg_to_rad(lerpf(43.0, -43.0, i / 8.0))
			pts.append(jc + Vector2(cos(ang), sin(ang)) * r * (WHEEL_CORE + 0.03))
		draw_colored_polygon(pts, accent if sec == held_sec else Color(1, 1, 1, a * 0.14))
		var d := sector_dir(sec)
		var lbl: String = WHEEL_LABELS[sec]
		_label(font, jc + Vector2(d.x, -d.y) * r * 0.71, lbl, (15.0 if sec % 4 == 0 else 17.0) * s, white)
	draw_arc(jc, r, 0, TAU, 64, white, 4.0 * s, true)
	draw_circle(jc, r * WHEEL_CORE, accent if (core_held or _flash.has("jump")) else Color(dark, minf(dark.a + 0.25, 1.0)))
	draw_arc(jc, r * WHEEL_CORE, 0, TAU, 48, Color(white, white.a * 0.8), 3.0 * s, true)
	_label(font, jc, "SALTO", 20 * s, white)

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
	# Joystick GIRO: mitades izquierda / derecha = sentido del tirabuzón (analógico).
	for side in [1, -1]:
		var hot: bool = not finger.is_empty() and _rot_vec.x * side > 0.35
		var c := 0.0 if side == 1 else PI
		var pts := PackedVector2Array()
		for i in 9:
			var ang := c + deg_to_rad(lerpf(-60.0, 60.0, i / 8.0))
			pts.append(base + Vector2(cos(ang), sin(ang)) * rr * 0.97)
		for i in 9:
			var ang := c + deg_to_rad(lerpf(60.0, -60.0, i / 8.0))
			pts.append(base + Vector2(cos(ang), sin(ang)) * rr * 0.7)
		draw_colored_polygon(pts, accent if hot else Color(1, 1, 1, a * 0.13))
		_label(font, base + Vector2(side * rr * 0.84, 0), "GIRO" if side == 1 else "GIRO", 15 * s, white)
	_label(font, base + Vector2(0, -rr * 0.82), "¼ · ½ · 1", 14 * s, Color(1, 1, 1, white.a * 0.8))
	if not ring_enabled():
		_label(font, base + Vector2(0, rr + 18 * s), "suelo: soltar · mantener · arco", 13 * s, Color(1, 1, 1, white.a * 0.75))
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
