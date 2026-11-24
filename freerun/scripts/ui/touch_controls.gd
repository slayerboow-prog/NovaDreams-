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
	var pattern := {}                      # modo gestos: patrón reconocido en el joystick dorado
	var twist_loops: Array[int] = []       # modo gestos: círculos completados en el joystick morado
	var giro_sector := 99                  # modo gestos: línea recta en el joystick morado

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
## · 5 gestos con dos joysticks: SALTO (mortales por ángulo) y GIRO (suelo / tirabuzones), sin rueda de botones
func gestures_enabled() -> bool:
	return Settings.trick_controls not in [2, 4, 5]

func pad_enabled() -> bool:
	return Settings.trick_controls in [2, 3]

## Joystick GIRO presente (doble joystick y botonera): los tirabuzones son solo suyos.
func stick_enabled() -> bool:
	return Settings.trick_controls in [0, 4, 5]

## Botonera: SALTO grande abajo a la derecha y un arco de 3/4 de círculo con un botón por
## movimiento (mortales, movimientos de suelo y de parkour).
func ring_enabled() -> bool:
	return Settings.trick_controls in [4, 5]

## Botones de movimientos alrededor de SALTO (solo en la botonera; en el modo gestos no hay).
func ring_moves() -> bool:
	return Settings.trick_controls == 4

## [rótulo, tipo, valor]. Tipos: flip (sector de la acrobacia), cork, kick (patada 360),
## (sin botón PIRU: los tirabuzones se hacen solo con el joystick GIRO)
## butterfly, skill (habilidad de suelo), change (CAMBIAR de página).
## Arco de 270° alrededor de SALTO con 8 botones GRANDES por página y CAMBIAR al final (abajo a la
## derecha). VAULT, AGARRAR y RODAR van aparte, en una fila encima del joystick GIRO.
const RING_FIXED := [["VAULT", "vault", ""], ["AGARRAR", "grab", ""], ["RODAR", "action", ""]]
const RING_CHANGE := ["CAMBIAR", "change", ""]
const RING_PAGES := [
	{"name": "MORTALES", "buttons": [
		["ATRÁS", "flip", -2], ["ADELANTE", "flip", 2], ["LATERAL\nIZQ.", "flip", 4], ["LATERAL\nDER.", "flip", 0],
		["CORK", "cork", -2], ["AERIAL", "flip", 3], ["PATADA\n360", "kick", 0]]},
	{"name": "SUELO", "buttons": [
		["RONDADA", "skill", "roundoff"], ["FLIC-FLAC", "skill", "bhs"], ["RUEDA", "skill", "cartwheel"],
		["PALOMA", "skill", "fhs"], ["MACACO", "skill", "macaco"], ["PINO", "skill", "handstand"],
		["ATRÁS", "flip", -2], ["CORK", "cork", -2]]},
	{"name": "TRICKING", "buttons": [
		["HOOK", "skill", "hook"], ["CRESCENT", "skill", "crescent"], ["CRESCENT\nINVERSA", "skill", "reverse_crescent"],
		["RAIZ", "skill", "raiz"], ["TD RAIZ", "skill", "td_raiz"], ["MACACO", "skill", "macaco"],
		["PATADA\n360", "kick", 0], ["CORK", "cork", -2]]},
	{"name": "GIMNASIA", "buttons": [
		["BACK\nWALKOVER", "skill", "back_walkover"], ["FRONT\nWALKOVER", "skill", "front_walkover"],
		["VALDEZ", "skill", "valdez"], ["VOLTERETA\nAL PINO", "skill", "ber"], ["PINO", "skill", "handstand"],
		["RONDADA", "skill", "roundoff"], ["FLIC-FLAC", "skill", "bhs"], ["ATRÁS", "flip", -2]]},
]
## Modo gestos (tres joysticks: movimiento azul, tirabuzones morado, mortales dorado).
## Joystick dorado (SALTO): tocar = salto · línea recta = mortal básico (↑ adelante, ↓ atrás,
## ← → lateral) · patrones dibujados = acrobacias (aerial, aerial twist, cork, cork 720, webster,
## gainer) y parkour (vault, kong, wall run, wall flip, escalada, agarre, cat leap, precisión,
## rodar, wall climb), ver GestureRecognizer. El botón pequeño junto a SALTO cambia de página:
## en TRICKING y GIMNASIA las líneas rectas (8 direcciones) son habilidades de suelo.
## Joystick morado (GIRO): cada círculo = un tirabuzón (horario derecho, antihorario izquierdo;
## dos o tres seguidos = doble o triple; uno y otro al revés = combinado). En el suelo, una línea
## recta = rondada (↑), flic-flac (↓) o rueda (← →).
const SALTO_PAGES := [
	{"name": "MORTALES", "moves": {2: ["ADELANTE", "flip"], 0: ["LATERAL", "flip"], 4: ["LATERAL", "flip"], -2: ["ATRÁS", "flip"]}},
	{"name": "TRICKING", "moves": {2: ["CRESCENT", "skill", "crescent:1"], 1: ["HOOK", "skill", "hook:1"],
		3: ["CRESCENT INV.", "skill", "reverse_crescent:1"], 0: ["RAIZ", "skill", "raiz:1"], 4: ["RAIZ", "skill", "raiz:-1"],
		-1: ["TD RAIZ", "skill", "td_raiz:1"], -3: ["TD RAIZ", "skill", "td_raiz:-1"], -2: ["MACACO", "skill", "macaco:1"]}},
	{"name": "GIMNASIA", "moves": {2: ["PALOMA", "skill", "fhs:1"], 1: ["FRONT WALKOVER", "skill", "front_walkover:1"],
		3: ["PINO", "skill", "handstand:1"], -2: ["BACK WALKOVER", "skill", "back_walkover:1"],
		0: ["VALDEZ", "skill", "valdez:1"], 4: ["VALDEZ", "skill", "valdez:-1"], -1: ["VOLTERETA PINO", "skill", "ber:1"],
		-3: ["VOLTERETA PINO", "skill", "ber:1"]}},
]
var salto_page := 0
var context_provider: Callable          # () -> Dictionary: qué permite el entorno (PlayerController.gesture_context)
var _toasts := []                       # nombres de los movimientos reconocidos (encima del joystick)
var _trails := []                       # estelas de los trazos ya soltados (se desvanecen)
var _await_tap := {}                    # línea corta hacia arriba: si llega un toque es salto de precisión
var _jump_hold_until := 0.0             # el salto de un toque se mantiene un instante (altura normal)
const PRECISION_LEN := 0.6              # línea más corta que esto (radios) + toque = precisión
const PRECISION_WAIT := 0.3             # s para el toque del salto de precisión
signal gesture_recognized(info: Dictionary)

func salto_pages_enabled() -> bool:
	return Settings.trick_controls == 5

## Botón pequeño para cambiar de página de SALTO (arriba a la izquierda de SALTO).
func salto_swap_center() -> Vector2:
	var v := Vector2(-1.6, -1.8) * RING_JUMP_R * _s()
	if Settings.left_handed:
		v.x = -v.x
	return _jump_center() + v

func salto_swap_radius() -> float:
	return 34.0 * _s()

func salto_turn(d := 1) -> void:
	salto_page = posmod(salto_page + d, SALTO_PAGES.size())
	_flash["salto_page"] = 1.2

var ring_page := 0
var _ring_anim := 0.0                 # giro animado de la rueda al cambiar de página (-1..1 → 0)

func ring_buttons() -> Array:
	if not ring_moves():
		return []
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
const RING_SLOTS := 9                # 8 botones + CAMBIAR

func _ring_center() -> Vector2:
	var s := _s()
	return Vector2(_mirror(size.x - 255.0 * s), size.y - 195.0 * s)

func ring_button_center(i: int, animated := false) -> Vector2:
	# CAMBIAR siempre en el último hueco (abajo a la derecha) aunque la página tenga menos
	# botones: los de la página se reparten por el resto del arco.
	var n := ring_buttons().size()
	var frac := 1.0
	if i < n - 1:
		frac = float(i) / float(maxi(n - 2, 1)) * float(RING_SLOTS - 2) / float(RING_SLOTS - 1)
	var a_deg := RING_A0 - RING_SPAN * frac
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
		# Modo gestos: el joystick de tirabuzones algo más arriba que el de mortales
		return Vector2(cx, size.y - (215.0 if salto_pages_enabled() else 150.0) * s)
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
				if salto_pages_enabled() and not fd.get("committed", false):
					pass                      # aún dibujando el patrón: no cuenta como salto mantenido
				elif fd.get("grab_hold", false):
					f.grab_held = true       # agarre de borde: el dedo mantenido sigue agarrado
				elif fd.get("skill_hold", false):
					f.skill_hold = true      # PINO dibujado desde SALTO: sigue en el pino mientras mantienes
				else:
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
	if _time < _jump_hold_until:
		f.jump_held = true
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
		var qb := quick_at(p)
		if qb >= 0:
			role = "quick"
			_flash["quick"] = qb
			_flash["quick_t"] = 0.25
			quick_action.emit(String(QUICK[qb][2]))
		elif rb >= 0:
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
		elif salto_pages_enabled() and p.distance_to(salto_swap_center()) < salto_swap_radius() * 1.15:
			role = "salto_swap"
			salto_turn(1)
		elif training and _train_button_at(p) >= 0:
			role = "train_btn"
			_train_button(_train_button_at(p))
		elif p.distance_to(_jump_center()) < hr.jump:
			role = "jump"
			if salto_pages_enabled():
				# Modo gestos: se dibuja el trazo y se reconoce al soltar (tocar = salto)
				info["path"] = [p]
				info["moved_t"] = _time
				if not _await_tap.is_empty() and _time - float(_await_tap.t) < PRECISION_WAIT:
					var pr: Dictionary = GestureRecognizer._result("precision", "pattern", 1.0, {}, {})
					_await_tap = {}
					info["committed"] = true
					_salto_execute(pr, info)
			else:
				_pending.jump_pressed = true
				info["jumped"] = true
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
		elif salto_pages_enabled() and p.distance_to(_rot_center()) < hr.rot:
			# Joystick morado: se dibujan círculos (cada vuelta = un tirabuzón) o una línea recta
			role = "twist"
			var lc := GestureRecognizer.LoopCounter.new(_rot_radius())
			lc.feed(p)
			info["lc"] = lc
			info["path"] = [p]
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
		elif f.role == "jump" and salto_pages_enabled():
			if not f.get("committed", false):
				(f.path as Array).append(p)
				_salto_execute(GestureRecognizer.recognize_salto(PackedVector2Array(f.path), _jump_radius(), _salto_opts()), f)
			_add_trail(f.path, Neon.GOLD)
		elif f.role == "twist":
			_twist_release(f, p)
		elif f.role == "jump" and not f.get("jumped", false) and not f.flicked:
			_pending.jump_pressed = true         # tocar SALTO sin dibujar = salto
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
			if salto_pages_enabled():
				var path: Array = f.path
				if e.position.distance_to(path[path.size() - 1]) > 1.5:
					path.append(e.position)
					f.moved_t = _time
			elif gestures_enabled():
				_swipe(f, e.position)
			elif ring_enabled():
				_jump_swipe(f, e.position)
		"twist":
			(f.path as Array).append(e.position)
			var ev: int = (f.lc as GestureRecognizer.LoopCounter).feed(e.position)
			if ev != 0:
				_pending.twist_loops.append(ev)
				_flash["twist_ok"] = 0.4
				_toast(GestureRecognizer.twist_name((f.lc as GestureRecognizer.LoopCounter).events), Neon.PURPLE, "purple")
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

## Botonera: SALTO es también un joystick de mortales básicos. Deslizar el dedo desde SALTO:
## adelante (arriba) = mortal adelante · a un lado = mortal lateral · atrás (abajo) = mortal atrás.
## Un solo mortal por toque; mantener el dedo después = agruparse y seguir girando.
func _jump_swipe(f: Dictionary, pos: Vector2) -> void:
	if f.flicked:
		return
	var disp: Vector2 = pos - f.anchor
	if disp.length() > _flick_px() * 0.8:
		var sec := sector_of(Vector2(disp.x, -disp.y))
		f.sector = sec
		f.flicked = true
		if salto_pages_enabled() and salto_page != 0:
			var mv: Array = SALTO_PAGES[salto_page].moves.get(sec, [])
			if mv.is_empty():
				return
			if air_mode:
				return                  # las habilidades de suelo no salen en el aire
			_pending.skill = String(mv[2])
			f["skill_hold"] = String(mv[2]).begins_with("handstand")
			_flash["jump_sec"] = sec
			_flash["jump_swipe"] = 0.35
			return
		_emit_flick(sector_dir(sec))
		_flash["jump_sec"] = sec
		_flash["jump_swipe"] = 0.35

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

# ---------------------------------------------------------------- modo gestos

func _salto_opts() -> Dictionary:
	var ctx := {}
	if context_provider.is_valid():
		ctx = context_provider.call()
	return {"ctx": ctx, "dirs8": salto_page != 0, "training": training}

## Ejecuta lo reconocido en el joystick dorado (al soltar, o antes si el dedo se para tras una línea).
func _salto_execute(res: Dictionary, f: Dictionary) -> void:
	var id := String(res.get("id", ""))
	var kind := String(res.get("kind", ""))
	if kind == "tap":
		_pending.jump_pressed = true
		_jump_hold_until = _time + 0.22
		_flash["jump"] = 0.15
		return
	if kind == "simple":
		var sec := int(res.sector)
		if salto_page != 0:
			var mv: Array = SALTO_PAGES[salto_page].moves.get(sec, [])
			if mv.is_empty():
				_toast("Sin movimiento en esa dirección", Color(1, 0.45, 0.4), "gold")
				return
			if air_mode:
				_toast("%s: solo en el suelo" % mv[0], Color(1, 0.45, 0.4), "gold")
				return
			_pending.skill = String(mv[2])
			f["skill_hold"] = String(mv[2]).begins_with("handstand")
			_flash["jump_sec"] = sec
			_flash["jump_swipe"] = 0.35
			_recognized({"id": String(mv[2]), "name": String(mv[0]), "kind": "skill"}, "gold")
			return
		if id == "front" and float(res.get("len", 1.0)) < PRECISION_LEN and not air_mode and not f.get("committed", false):
			_await_tap = {"t": _time, "res": res}     # ¿toque enseguida? = salto de precisión
			return
		_salto_flip(res)
		return
	if kind in ["pattern", "parkour"]:
		if not res.get("ok", false):
			_toast("%s: %s" % [res.get("name", id), res.get("reason", "")], Color(1, 0.45, 0.4), "gold")
			_train_check(res)
			return
		_pending.pattern = res
		_flash["gold_ok"] = 0.4
		_recognized(res, "gold")
		return
	_toast(String(res.get("reason", "")) if res.get("reason", "") != "" else "?", Color(1, 0.45, 0.4), "gold")

## Mortal básico (línea recta): salta (en el suelo) y empieza el mortal en esa dirección.
func _salto_flip(res: Dictionary) -> void:
	var sec := int(res.sector)
	if not air_mode:
		_pending.jump_pressed = true
	_emit_flick(sector_dir(sec))
	_flash["jump_sec"] = sec
	_flash["jump_swipe"] = 0.35
	_flash["gold_ok"] = 0.4
	var r := res.duplicate()
	if sec in [0, 4]:
		r["id"] = "side_r" if sec == 0 else "side_l"
		r["name"] = "LATERAL " + ("DERECHO" if sec == 0 else "IZQUIERDO")
	_recognized(r, "gold")

## Joystick morado soltado: si no hubo círculos, una línea recta es un movimiento de suelo.
func _twist_release(f: Dictionary, p: Vector2) -> void:
	var lc: GestureRecognizer.LoopCounter = f.lc
	(f.path as Array).append(p)
	_add_trail(f.path, Neon.PURPLE)
	if not lc.events.is_empty():
		var ids := {1: "twist_r", -1: "twist_l"}
		var tid: String = ids[lc.events[0]]
		var mixed := false
		for e in lc.events:
			if e != lc.events[0]:
				mixed = true
		if mixed:
			tid = "twist_combo"
		elif lc.events.size() == 2:
			tid = "twist_2"
		elif lc.events.size() >= 3:
			tid = "twist_3"
		_train_check({"id": tid, "name": GestureRecognizer.twist_name(lc.events)})
		gesture_recognized.emit({"id": tid, "name": GestureRecognizer.twist_name(lc.events), "joystick": "purple"})
		return
	var u := GestureRecognizer.to_units(PackedVector2Array(f.path), _rot_radius())
	var ch := u[u.size() - 1] - u[0] if u.size() > 1 else Vector2.ZERO
	var ln := GestureRecognizer.path_length(u)
	if ch.length() < 0.45 or ch.length() < ln * 0.75:
		return
	var sec := 2 if absf(ch.y) >= absf(ch.x) and ch.y > 0.0 else (-2 if absf(ch.y) >= absf(ch.x) else (0 if ch.x > 0.0 else 4))
	if air_mode:
		_toast("En el aire: dibuja círculos", Color(1, 0.45, 0.4), "purple")
		return
	_pending.giro_sector = sec
	_flash["twist_ok"] = 0.4
	var nm := {2: "RONDADA", -2: "FLIC-FLAC", 0: "RUEDA", 4: "RUEDA"}
	_toast(nm[sec], Neon.PURPLE, "purple")
	gesture_recognized.emit({"id": nm[sec], "name": nm[sec], "joystick": "purple"})

func _recognized(res: Dictionary, joy: String) -> void:
	_toast(String(res.get("name", "")), Neon.GOLD if joy == "gold" else Neon.PURPLE, joy)
	_train_check(res)
	var info := res.duplicate()
	info["joystick"] = joy
	gesture_recognized.emit(info)

## Nombre del movimiento encima del joystick que lo reconoció (sin tapar al atleta).
func _toast(txt: String, col: Color, joy: String) -> void:
	if txt == "":
		return
	for t in _toasts:
		if t.joy == joy:
			_toasts.erase(t)
			break
	_toasts.append({"text": txt, "col": col, "joy": joy, "t": 1.1})

func _add_trail(path: Array, col: Color) -> void:
	if path.size() >= 2:
		_trails.append({"pts": PackedVector2Array(path), "col": col, "t": 0.45})
		if _trails.size() > 4:
			_trails.pop_front()

## Dedo parado en el joystick dorado tras una línea recta larga: el mortal sale ya (y mantener el
## dedo después = agruparse). J hacia arriba y dedo quieto = agarre de borde (mientras se mantiene).
func _gesture_rest_checks() -> void:
	for fd in _fingers.values():
		if fd.role != "jump" or fd.get("committed", false) or not fd.has("path"):
			continue
		var path: Array = fd.path
		if path.size() < 3 or fd.get("rest_checked", -1.0) == fd.moved_t:
			continue
		var rest: float = _time - float(fd.moved_t)
		if rest < 0.09:
			continue
		var res := GestureRecognizer.recognize_salto(PackedVector2Array(path), _jump_radius(), _salto_opts())
		if res.kind == "simple" and float(res.len) >= PRECISION_LEN:
			fd["committed"] = true
			fd["flicked"] = true
			_salto_execute(res, fd)
		elif res.get("id", "") == "ledge_grab" and res.get("ok", false):
			if rest < 0.15:
				continue
			fd["committed"] = true
			fd["grab_hold"] = true
			_salto_execute(res, fd)
		fd["rest_checked"] = fd.moved_t

# ---------------------------------------------------------------- práctica de gestos

## [id, nombre, joystick, cómo se dibuja]
const TRAIN := [
	["front", "MORTAL ADELANTE", "gold", "Desliza hacia arriba"],
	["back", "MORTAL ATRÁS", "gold", "Desliza hacia abajo"],
	["side_l", "LATERAL IZQUIERDO", "gold", "Desliza a la izquierda"],
	["side_r", "LATERAL DERECHO", "gold", "Desliza a la derecha"],
	["aerial", "AERIAL", "gold", "Arco lateral que sube y baja, sin cerrar"],
	["aerial_twist", "AERIAL TWIST", "gold", "Arco lateral y un círculo pequeño al final"],
	["cork", "CORK", "gold", "Diagonal hacia arriba y un círculo pequeño"],
	["cork720", "CORK 720", "gold", "Diagonal hacia arriba y dos círculos pequeños"],
	["webster", "WEBSTER", "gold", "Sube, cae por delante y retrocede un poco"],
	["gainer", "GAINER", "gold", "Baja (hacia atrás) y da una vuelta ovalada"],
	["twist_r", "TIRABUZÓN DERECHO", "purple", "Un círculo en sentido horario"],
	["twist_l", "TIRABUZÓN IZQUIERDO", "purple", "Un círculo en sentido antihorario"],
	["twist_2", "DOBLE TIRABUZÓN", "purple", "Dos círculos seguidos en el mismo sentido"],
	["twist_3", "TRIPLE TIRABUZÓN", "purple", "Tres círculos seguidos (necesita altura)"],
	["twist_combo", "TIRABUZÓN COMBINADO", "purple", "Un círculo horario y luego uno antihorario"],
	["vault", "VAULT", "gold", "U invertida: sube, pasa por encima y baja (obstáculo delante)"],
	["kong", "KONG VAULT", "gold", "Dos arcos seguidos (obstáculo con fondo y carrera)"],
	["wall_run", "WALL RUN", "gold", "Diagonal hacia arriba que se curva adelante (pared al lado)"],
	["wall_flip", "WALL FLIP", "gold", "Sube y vuelve en semicírculo (pared delante)"],
	["climb", "ESCALADA", "gold", "Zigzag hacia arriba de tres tramos (pared delante)"],
	["wall_climb", "WALL CLIMB", "gold", "Zigzag hacia arriba de dos tramos (pared delante)"],
	["ledge_grab", "AGARRE DE BORDE", "gold", "J hacia arriba y mantén el dedo"],
	["cat_leap", "CAT LEAP", "gold", "V y una curva pequeña hacia dentro (pared delante)"],
	["precision", "SALTO DE PRECISIÓN", "gold", "Línea corta hacia arriba y un toque"],
	["roll", "RODAR", "gold", "Curva hacia abajo y adelante (corriendo o en el aire)"],
]
var training := false
var train_i := 0
var train_done := {}
var train_last := {}                     # {"ok": bool, "text": String, "t": tiempo}

func toggle_training(on := not training) -> void:
	training = on
	train_last = {}
	queue_redraw()

func _train_check(res: Dictionary) -> void:
	if not training:
		return
	var want: String = TRAIN[train_i][0]
	var got := String(res.get("id", ""))
	if got == "side":
		got = "side_r" if int(res.get("side", 1)) > 0 else "side_l"
	var ok := got == want
	var txt := "¡Correcto! %s" % TRAIN[train_i][1] if ok else "Has hecho: %s" % String(res.get("name", got))
	if ok and not res.get("ok", true):
		txt += " (%s: aquí no se ejecuta)" % res.get("reason", "")
	train_last = {"ok": ok, "text": txt, "t": _time}
	if ok:
		train_done[want] = true

func _train_panel_rect() -> Rect2:
	var s := _s()
	var w := minf(620.0 * s, size.x - 40.0)
	return Rect2(Vector2(size.x * 0.5 - w * 0.5, 64.0 * s), Vector2(w, 150.0 * s))

func _train_button_center(i: int) -> Vector2:
	var r := _train_panel_rect()
	var s := _s()
	match i:
		0: return r.position + Vector2(r.size.x - 118.0 * s, r.size.y - 26.0 * s)    # anterior
		1: return r.position + Vector2(r.size.x - 70.0 * s, r.size.y - 26.0 * s)     # siguiente
	return r.position + Vector2(r.size.x - 22.0 * s, 22.0 * s)                         # salir

func _train_button_at(p: Vector2) -> int:
	for i in 3:
		if p.distance_to(_train_button_center(i)) < 24.0 * _s():
			return i
	return -1

func _train_button(i: int) -> void:
	match i:
		0: train_i = posmod(train_i - 1, TRAIN.size())
		1: train_i = posmod(train_i + 1, TRAIN.size())
		2: toggle_training(false)
	train_last = {}

func _draw_training(font: Font, s: float) -> void:
	var r := _train_panel_rect()
	var item: Array = TRAIN[train_i]
	var col: Color = Neon.GOLD if item[2] == "gold" else Neon.PURPLE
	draw_rect(r, Color(Neon.NAVY, 0.86))
	draw_rect(r, Color(col, 0.9), false, 2.0 * s)
	# Ejemplo del trazo (punto = inicio, flecha = final)
	var box := Rect2(r.position + Vector2(10, 10) * s, Vector2(130, 130) * s)
	draw_rect(box, Color(1, 1, 1, 0.06))
	var pts := GestureRecognizer.preview_points(String(item[0]))
	if pts.size() >= 2:
		var c := box.get_center()
		var k := box.size.x * 0.42
		var poly := PackedVector2Array()
		for q in pts:
			poly.append(c + Vector2(q.x, -q.y) * k)
		draw_polyline(poly, Color(col, 0.35), 9.0 * s, true)
		draw_polyline(poly, col, 3.5 * s, true)
		draw_circle(poly[0], 6.0 * s, Color(1, 1, 1))
		var dv := (poly[poly.size() - 1] - poly[maxi(poly.size() - 3, 0)]).normalized()
		Neon._chevron(self, poly[poly.size() - 1], 9.0 * s, dv, Color(1, 1, 1), 3.0 * s)
		if item[0] == "precision":
			draw_arc(c + Vector2(0, -0.2) * k + Vector2(0, -0.35 * k), 9.0 * s, 0, TAU, 20, Color(1, 1, 1), 2.5 * s, true)
	var x0 := box.end.x + 14.0 * s
	var tx := x0 + (r.end.x - x0 - 130.0 * s) * 0.5
	_label(font, Vector2(tx, r.position.y + 20.0 * s), "PRÁCTICA DE GESTOS  %d/%d  ·  hechos %d" % [train_i + 1, TRAIN.size(), train_done.size()], 14 * s, Color(1, 1, 1, 0.8))
	_label(font, Vector2(tx, r.position.y + 50.0 * s), String(item[1]) + ("  ✓" if train_done.has(item[0]) else ""), 26 * s, col)
	_label(font, Vector2(tx, r.position.y + 82.0 * s), "Joystick %s: %s" % ["dorado" if item[2] == "gold" else "morado", item[3]], 14 * s, Color(1, 1, 1, 0.92))
	if not train_last.is_empty() and _time - float(train_last.t) < 2.5:
		_label(font, Vector2(tx, r.position.y + 112.0 * s), String(train_last.text), 15 * s, Color(0.45, 1, 0.55) if train_last.ok else Color(1, 0.5, 0.45))
	for i in 3:
		var bc := _train_button_center(i)
		Neon.button(self, bc, 20.0 * s, col if i < 2 else Color(1, 0.45, 0.4), false, 0.95)
		_label(font, bc, ["<", ">", "X"][i], 18 * s, Color(1, 1, 1))

func _draw_gesture_fx(font: Font, s: float) -> void:
	# Estela luminosa que sigue exactamente al dedo mientras dibuja
	for fd in _fingers.values():
		if fd.role in ["jump", "twist"] and fd.has("path") and salto_pages_enabled():
			var path: Array = fd.path
			if path.size() >= 2:
				var col: Color = Neon.GOLD if fd.role == "jump" else Neon.PURPLE
				var poly := PackedVector2Array(path)
				draw_polyline(poly, Color(col, 0.28), 16.0 * s, true)
				draw_polyline(poly, Color(col, 0.95), 5.0 * s, true)
				draw_circle(poly[poly.size() - 1], 9.0 * s, Color(1, 1, 1, 0.9))
	for tr in _trails:
		var a: float = clampf(float(tr.t) / 0.45, 0.0, 1.0)
		draw_polyline(tr.pts, Color(tr.col, 0.22 * a), 16.0 * s, true)
		draw_polyline(tr.pts, Color(tr.col, 0.8 * a), 5.0 * s, true)
	# Joystick iluminado y nombre del movimiento reconocido
	if _flash.has("gold_ok"):
		draw_arc(_jump_center(), _jump_radius() * 1.12, 0, TAU, 64, Color(Neon.GOLD, minf(1.0, _flash.gold_ok * 2.5)), 8.0 * s, true)
	if _flash.has("twist_ok"):
		draw_arc(_rot_center(), _rot_radius() * 1.1, 0, TAU, 64, Color(Neon.PURPLE, minf(1.0, _flash.twist_ok * 2.5)), 8.0 * s, true)
	for t in _toasts:
		var at: Vector2 = _jump_center() + Vector2(0, -_jump_radius() * 2.05) if t.joy == "gold" else _rot_center() + Vector2(0, -_rot_radius() * 1.75)
		var a2 := clampf(float(t.t) * 2.0, 0.0, 1.0)
		var fs := 22.0 * s if String(t.text).length() < 22 else 16.0 * s
		_pill(font, at + Vector2(0, -(1.1 - float(t.t)) * 18.0 * s), String(t.text), fs, t.col, a2, true)

func _process(dt: float) -> void:
	if not visible:
		return
	_time += dt
	if salto_pages_enabled():
		_gesture_rest_checks()
		if not _await_tap.is_empty() and _time - float(_await_tap.t) >= PRECISION_WAIT:
			var res: Dictionary = _await_tap.res
			_await_tap = {}
			_salto_flip(res)                 # no hubo toque: era un mortal adelante
	for t in _toasts.duplicate():
		t.t -= dt
		if t.t <= 0.0:
			_toasts.erase(t)
	for tr in _trails.duplicate():
		tr.t -= dt
		if tr.t <= 0.0:
			_trails.erase(tr)
	_hint_time += dt
	var vs := get_viewport_rect().size
	if size != vs:
		size = vs
	if _flash.has("quick_t"):
		_flash["quick_t"] -= dt
		if _flash["quick_t"] <= 0.0:
			_flash.erase("quick_t"); _flash.erase("quick")
	for k in _flash.keys():
		if k in ["sector", "wheel_sec", "ring_i", "quick", "quick_t", "jump_sec"]:
			continue
		_flash[k] -= dt
		if _flash[k] <= 0.0:
			_flash.erase(k)
	if not _flash.has("flick"):
		_flash.erase("sector")
	if not _flash.has("wheel"):
		_flash.erase("wheel_sec")
	if not _flash.has("jump_swipe"):
		_flash.erase("jump_sec")
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
	if ring_enabled():
		_draw_neon_joy(font, s, a, base, joy_active)
		_draw_quick(font, s, a)
	else:
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
		var alp := clampf(a + 0.35, 0.5, 1.0)
		for pk in [["vault", _vault_center(), "VAULT", Neon.BLUE], ["grab", _grab_center(), grab_label, Neon.PURPLE],
				["action", _action_center(), "RODAR", Neon.GREEN]]:
			var pr := PARK_R * s
			Neon.button(self, pk[1], pr, pk[3], heldp.has(pk[0]) or _flash.has(pk[0]), alp)
			Neon.icon(self, Neon.icon_for(pk[0], ""), pk[1] + Vector2(0, -pr * 0.2), pr * 0.36, Color(1, 1, 1, alp))
			_label(font, pk[1] + Vector2(0, pr * 0.42), pk[2], 13 * s, Color(1, 1, 1, alp))
		_draw_rot_stick(font, s, a, white, dark, accent)
		_draw_camera_hint(font, s, a)
		_draw_ring_hint(font, s)
		if salto_pages_enabled():
			_draw_gesture_fx(font, s)
			if training:
				_draw_training(font, s)
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
		if f.role in ["ringflip", "ringskill", "ringchange"]:
			held[int(f.get("sector", -1))] = true
	var flash_i: int = _flash.get("ring_i", -1)
	var br := ring_button_radius()
	var btns := ring_buttons()
	var al := clampf(a + 0.35, 0.5, 1.0)
	for i in btns.size():
		var bt: Array = btns[i]
		var c := ring_button_center(i, true)
		var hot: bool = held.has(i) or i == flash_i
		var col: Color = Neon.color_for(String(bt[1]), bt[2])
		Neon.button(self, c, br, col, hot, al)
		Neon.icon(self, Neon.icon_for(String(bt[1]), bt[2]), c + Vector2(0, -br * 0.22), br * 0.36, Color(1, 1, 1, al))
		var lines := String(bt[0]).split("\n")
		var fs := (11.0 if lines.size() > 1 or String(bt[0]).length() > 8 else 13.0) * s
		for li in lines.size():
			_label(font, c + Vector2(0, br * 0.38 + (li - (lines.size() - 1) * 0.5) * fs * 1.0), lines[li], fs, Color(1, 1, 1, al))
	# SALTO: aro dorado, corona y doble flecha
	var jr := _jump_radius()
	var jhot := jheld or _flash.has("jump")
	for k in 3:
		draw_arc(jc, jr * (1.1 + k * 0.07), 0, TAU, 64, Color(Neon.GOLD, 0.18 * (3 - k) * al), jr * 0.06, true)
	Neon.button(self, jc, jr, Neon.BLUE, jhot, al)
	draw_arc(jc, jr * 1.02, 0, TAU, 72, Color(Neon.GOLD, al), jr * 0.1, true)
	Neon.icon(self, "crown", jc + Vector2(0, -jr * 1.12), jr * 0.26, Color(Neon.GOLD, al))
	Neon.icon(self, "jump", jc + Vector2(0, -jr * 0.22), jr * 0.32, Color(1, 1, 1, al))
	_label(font, jc + Vector2(0, jr * 0.36), "SALTO", 30 * s, Color(1, 1, 1, al))
	# Deslizar desde SALTO: ↑ mortal adelante · ← → lateral · ↓ atrás (marcas en el borde)
	var js: int = int(_flash.get("jump_sec", 99))
	for d in [[2, Vector2.UP], [0, Vector2.RIGHT], [4, Vector2.LEFT], [-2, Vector2.DOWN],
			[1, Vector2(0.71, -0.71)], [3, Vector2(-0.71, -0.71)], [-1, Vector2(0.71, 0.71)], [-3, Vector2(-0.71, 0.71)]]:
		var hot2: bool = js == int(d[0])
		var dv: Vector2 = d[1]
		Neon._chevron(self, jc + dv * jr * 0.8, jr * (0.11 if hot2 else 0.08), dv,
			Color(Neon.GOLD, al) if hot2 else Color(1, 1, 1, 0.55 * al), jr * (0.05 if hot2 else 0.035))
	if salto_pages_enabled():
		_draw_salto_page(font, s, al, jc, jr)
	# Página actual de la rueda (más visible justo después de cambiar)
	if btns.is_empty():
		return
	var pa := minf(1.0, 0.55 + float(_flash.get("page", 0.0)))
	var top := ring_button_center(int(btns.size() / 2))
	_label(font, top + Vector2(0, -br - 20 * s), "%s  %d/%d" % [RING_PAGES[ring_page].name, ring_page + 1, RING_PAGES.size()], 20 * s, Color(Neon.GOLD, pa))

## Etiqueta con fondo oscuro y borde de color (legible sobre cualquier fondo).
func _pill(font: Font, pos: Vector2, txt: String, fs: float, border: Color, al: float, hot := false) -> void:
	var s := _s()
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs)).x
	var rect := Rect2(pos - Vector2(tw * 0.5 + 7 * s, fs * 0.72), Vector2(tw + 14 * s, fs * 1.44))
	draw_rect(rect, Color(Neon.NAVY, 0.78 * al))
	draw_rect(rect, Color(border, 0.9 * al), false, 1.5 * s)
	_label(font, pos, txt, fs, Color(Neon.GOLD, al) if hot else Color(1, 1, 1, al))

## Movimientos de la página de SALTO alrededor del botón y botón de cambiar página.
func _draw_salto_page(font: Font, s: float, al: float, jc: Vector2, jr: float) -> void:
	var pg: Dictionary = SALTO_PAGES[salto_page]
	var js: int = int(_flash.get("jump_sec", 99))
	var done := {}
	for sec in pg.moves.keys():
		var mv: Array = pg.moves[sec]
		var dv := sector_dir(int(sec))
		var pos := jc + Vector2(dv.x, -dv.y) * jr * 1.45
		var hot := js == int(sec)
		var txt := String(mv[0])
		_pill(font, pos, txt, (15.0 if txt.length() < 10 else 12.5) * s, Neon.GOLD if hot else Neon.PURPLE, al, hot)
	var sc := salto_swap_center()
	var sr := salto_swap_radius()
	Neon.button(self, sc, sr, Neon.GOLD, _flash.has("salto_page"), al)
	Neon.icon(self, "swap", sc + Vector2(0, -sr * 0.2), sr * 0.4, Color(1, 1, 1, al))
	_label(font, sc + Vector2(0, sr * 0.45), "%d/%d" % [salto_page + 1, SALTO_PAGES.size()], 11 * s, Color(1, 1, 1, al))
	var pa := minf(1.0, 0.6 + float(_flash.get("salto_page", 0.0)))
	_label(font, sc + Vector2(0, -sr - 16 * s), pg.name, 18 * s, Color(Neon.GOLD, pa))

## Accesos rápidos (botonera): columna a la izquierda si cabe sobre el joystick; si no, fila arriba.
const QUICK := [["MOVIMIENTOS", "list", "library"], ["PRÁCTICA", "hand", "training"], ["TUTORIAL", "star", "tutorial"], ["AJUSTES", "gear", "settings"], ["REAPARECER", "respawn", "respawn"]]
signal quick_action(id: String)
const QUICK_R := 27.0

func quick_center(i: int) -> Vector2:
	var s := _s()
	var r := QUICK_R * s
	var joy_top := _joy_idle().y - JOY_R * s
	var y0 := 128.0 * s
	var step := 60.0 * s
	if y0 + step * float(QUICK.size() - 1) + r * 1.15 < joy_top - 8.0:
		return Vector2(_mirror(56.0 * s), y0 + step * float(i))
	return Vector2(_mirror(56.0 * s + float(i) * 80.0 * s), 130.0 * s)

func quick_at(p: Vector2) -> int:
	if not ring_enabled():
		return -1
	for i in QUICK.size():
		if p.distance_to(quick_center(i)) < QUICK_R * _s() * 1.15:
			return i
	return -1

func _draw_quick(font: Font, s: float, a: float) -> void:
	var al := clampf(a + 0.3, 0.45, 0.95)
	for i in QUICK.size():
		var c := quick_center(i)
		var r := QUICK_R * s
		var hot: bool = int(_flash.get("quick", -1)) == i
		var qcols: Array[Color] = [Neon.GOLD, Neon.GREEN, Neon.CYAN, Neon.PURPLE, Neon.BLUE]
		Neon.button(self, c, r, qcols[i], hot, al)
		Neon.icon(self, QUICK[i][1], c + Vector2(0, -r * 0.18), r * 0.38, Color(1, 1, 1, al))
		if quick_center(1).x == quick_center(0).x:
			# Columna: el texto va a la derecha del botón (izquierda en modo zurdo)
			var fs := int(13.0 * s)
			var tw := font.get_string_size(QUICK[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var dx := r * 1.3 if not Settings.left_handed else -r * 1.3 - tw
			_label(font, c + Vector2(dx + tw * 0.5, 0), QUICK[i][0], 13.0 * s, Color(1, 1, 1, al * 0.9))
		else:
			_label(font, c + Vector2(0, r * 0.5), QUICK[i][0], 9.0 * s, Color(1, 1, 1, al))

## Joystick de movimiento en estilo neón (con las cuatro flechas).
func _draw_neon_joy(font: Font, s: float, a: float, base: Vector2, active: bool) -> void:
	var jr := JOY_R * s
	var al := clampf(a + 0.35, 0.5, 1.0)
	for k in 3:
		draw_arc(base, jr * (1.04 + k * 0.05), 0, TAU, 64, Color(Neon.BLUE, 0.16 * (3 - k) * al), jr * 0.05, true)
	draw_circle(base, jr, Color(Neon.NAVY, 0.7 * al))
	draw_arc(base, jr, 0, TAU, 64, Color(Neon.BLUE, al), jr * 0.05, true)
	draw_arc(base, jr * 0.72, 0, TAU, 48, Color(Neon.BLUE, 0.35 * al), jr * 0.02, true)
	for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		Neon._chevron(self, base + d * jr * 0.8, jr * 0.12, d, Color(1, 1, 1, 0.8 * al), jr * 0.04)
	var knob := base + Vector2(_joy_vec.x, -_joy_vec.y) * jr * 0.8
	draw_circle(knob, 46.0 * s, Color(0.75, 0.8, 0.9, (0.95 if active else 0.7) * al))
	draw_circle(knob + Vector2(-8, -10) * s, 30.0 * s, Color(1, 1, 1, 0.25 * al))
	if _joy_vec.length() > 0.93:
		_label(font, base + Vector2(0, -jr - 26 * s), "SPRINT", 26 * s, Color(Neon.CYAN, al))

func _draw_ring_hint(font: Font, s: float) -> void:
	if _hint_time >= 9.0:
		return
	var hc := Vector2(size.x * 0.5, size.y * 0.16)
	var ha := clampf(1.0 - (_hint_time - 7.0) / 2.0, 0.0, 1.0)
	if salto_pages_enabled():
		_label(font, hc, "Dorado: línea = mortal · dibuja patrones = cork, aerial, webster, gainer, vault, kong...", 22 * s, Color(1, 1, 1, ha))
		_label(font, hc + Vector2(0, 34 * s), "Morado: cada círculo = un tirabuzón · en el suelo, línea = rondada, flic-flac o rueda", 22 * s, Color(1, 1, 1, ha))
		_label(font, hc + Vector2(0, 68 * s), "Todos los patrones, con dibujo de ejemplo: botón PRÁCTICA", 20 * s, Color(1, 1, 1, ha * 0.9))
		return
	_label(font, hc, "Dibuja una dirección desde SALTO: cada página (botón dorado junto a SALTO) tiene 8 movimientos", 22 * s, Color(1, 1, 1, ha))
	_label(font, hc + Vector2(0, 34 * s), "GIRO en el suelo: arriba rondada · abajo flic-flac · lado rueda · semicírculo desde arriba macaco", 22 * s, Color(1, 1, 1, ha))
	_label(font, hc + Vector2(0, 68 * s), "Mantén el dedo tras deslizar = sigue girando · en el aire, GIRO = tirabuzones", 20 * s, Color(1, 1, 1, ha * 0.9))

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
		if f.role == "rot" or f.role == "twist":
			finger = f
	var base := rc
	if not finger.is_empty() and finger.has("origin"):
		base = finger.origin
	var neon := ring_enabled()
	var al := clampf(a + 0.35, 0.5, 1.0)
	if neon:
		for k in 3:
			draw_arc(base, rr * (1.04 + k * 0.05), 0, TAU, 64, Color(Neon.PURPLE, 0.16 * (3 - k) * al), rr * 0.05, true)
		draw_circle(base, rr, Color(Neon.NAVY, 0.7 * al))
	else:
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
		var idle := Color(Neon.PURPLE, 0.16 * al) if neon else Color(1, 1, 1, a * 0.13)
		draw_colored_polygon(pts, (Color(Neon.PURPLE, 0.7 * al) if neon else accent) if hot else idle)
		if neon:
			Neon._curved_arrow(self, base, rr * 0.84, deg_to_rad(-35.0 if side == 1 else 215.0), deg_to_rad(35.0 if side == 1 else 145.0), Color(1, 1, 1, 0.85 * al), maxf(2.0, rr * 0.035))
		else:
			_label(font, base + Vector2(side * rr * 0.84, 0), "GIRO", 15 * s, white)
	if ring_enabled() and not air_mode:
		# En el suelo el GIRO hace movimientos: ↑ rondada · ↓ flic-flac · ← → rueda ·
		# semicírculo desde arriba = macaco
		var la := clampf(a + 0.35, 0.5, 1.0)
		_pill(font, base + Vector2(0, -rr - 14 * s), "RONDADA", 14 * s, Neon.PURPLE, la)
		_pill(font, base + Vector2(0, rr + 14 * s), "FLIC-FLAC", 14 * s, Neon.PURPLE, la)
		_pill(font, base + Vector2(-rr - 30 * s, 0), "RUEDA", 13 * s, Neon.PURPLE, la)
		_pill(font, base + Vector2(rr + 30 * s, 0), "RUEDA", 13 * s, Neon.PURPLE, la)
		if not salto_pages_enabled():
			_pill(font, base + Vector2(rr * 0.78, -rr * 0.86), "MACACO arco", 11 * s, Neon.PURPLE, la)
	else:
		_label(font, base + Vector2(0, -rr * 0.82), "¼ · ½ · 1", 14 * s, Color(1, 1, 1, white.a * 0.8))
	if not ring_enabled():
		_label(font, base + Vector2(0, rr + 18 * s), "suelo: soltar · mantener · arco", 13 * s, Color(1, 1, 1, white.a * 0.75))
	if salto_pages_enabled():
		var la2 := clampf(a + 0.35, 0.5, 1.0)
		_label(font, base + Vector2(0, -rr - (40.0 if not air_mode else 14.0) * s), "TIRABUZONES: dibuja círculos", 13 * s, Color(Neon.PURPLE.lightened(0.35), la2))
	draw_arc(base, rr, 0, TAU, 64, Color(Neon.PURPLE, al) if neon else Color(white, white.a * 0.8), (rr * 0.05) if neon else 3.0 * s, true)
	# Mando (modo gestos: sigue al dedo dentro del joystick)
	var knob := base + Vector2(_rot_vec.x, -_rot_vec.y) * _rot_travel()
	if not finger.is_empty() and finger.role == "twist":
		knob = base + (finger.pos - base).limit_length(rr * 0.6)
	if neon:
		Neon.button(self, knob, 50.0 * s, Neon.PURPLE, not finger.is_empty() or _flash.has("kick"), al)
		Neon.icon(self, "spin", knob + Vector2(0, -12 * s), 15 * s, Color(1, 1, 1, al))
		_label(font, knob + Vector2(0, 20 * s), "GIRO", 15 * s, Color(1, 1, 1, al))
	else:
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
