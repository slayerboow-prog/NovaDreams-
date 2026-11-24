class_name GestureInterpreter
extends RefCounted
## Intérprete de gestos del joystick derecho (movimientos de suelo y enlaces).
##
## Lee el joystick analógico cada frame de física y distingue:
##   flick     inclinar y soltar rápido (< HOLD)                → movimiento estándar
##   hold      dirección mantenida (≥ HOLD, se emite una vez)    → variante lenta / de potencia
##   release   soltar después de mantener                        → final del movimiento mantenido
##   arc       giro del joystick de ≥ 135° sin soltar            → patadas circulares (trayectoria de la pierna)
##   change    cambio de dirección: soltar e inclinar al lado opuesto enseguida → scoot (barrido)
##   double    dos flicks en la misma dirección seguidos         → secuencia (encadenar el mismo movimiento)
## La diagonal se distingue por el sector (8 direcciones, igual que el resto del juego).
## Un flick se confirma CONFIRM segundos después de soltar: así se puede reconocer un cambio
## de dirección sin confundirlo con dos movimientos sueltos.

const TILT := 0.5            # inclinación mínima para empezar un gesto
const RELEASE := 0.3         # por debajo: joystick suelto
const HOLD := 0.5            # s inclinado = dirección mantenida
const ARC := deg_to_rad(135.0)
const CONFIRM := 0.1         # s de espera tras soltar para distinguir flick / cambio de dirección
const CHANGE_GAP := 0.22     # s máximos entre soltar y volver a inclinar al lado opuesto
const DOUBLE_GAP := 0.4

var tilted := false
var tilt_time := 0.0
var start_sector := 99
var sector := 99             # sector actual mientras está inclinado
var swept := 0.0             # ángulo recorrido con signo (antihorario +)
var _last_ang := 0.0
var held_fired := false
var arc_fired := false
var void_gesture := false    # empezó cuando no se podía (en el aire, con SALTO...): se ignora
var _pending := {}           # flick esperando confirmación
var _pending_t := 0.0
var _since_release := 99.0
var _last_flick_sector := 99
var _last_flick_t := 99.0
var history: Array = []      # últimos eventos [tipo, sector, tiempo] (secuencias)
var _clock := 0.0

static func sector_of(v: Vector2) -> int:
	var s := int(round(rad_to_deg(atan2(v.y, v.x)) / 45.0))
	return 4 if s == -4 else s

## Llamar cada frame de física. `allow`: se puede empezar un gesto nuevo ahora.
## Devuelve el evento de este frame ({} si no hay).
func update(rot: Vector2, dt: float, allow := true) -> Dictionary:
	_clock += dt
	_since_release += dt
	_last_flick_t += dt
	var ev := {}
	var mag := rot.length()
	if not tilted:
		if mag >= TILT:
			var s := sector_of(rot)
			# Cambio de dirección: el flick anterior aún no confirmado iba al lado contrario
			if not _pending.is_empty() and _since_release < CHANGE_GAP and _opposite(int(_pending.sector), s):
				ev = {"type": "change", "from": int(_pending.sector), "to": s}
				_pending = {}
				void_gesture = true            # este segundo toque ya es parte del cambio
			else:
				void_gesture = not allow
			tilted = true
			tilt_time = 0.0
			start_sector = s
			sector = s
			swept = 0.0
			_last_ang = rot.angle()
			held_fired = false
			arc_fired = false
	else:
		if mag < RELEASE:
			tilted = false
			_since_release = 0.0
			if not void_gesture and not arc_fired:
				if held_fired:
					ev = {"type": "release", "sector": sector, "dur": tilt_time}
				else:
					_pending = {"type": "flick", "sector": sector, "dur": tilt_time}
					_pending_t = 0.0
		else:
			tilt_time += dt
			var a := rot.angle()
			swept += wrapf(a - _last_ang, -PI, PI)
			_last_ang = a
			sector = sector_of(rot)
			if not void_gesture and not arc_fired and absf(swept) >= ARC:
				arc_fired = true
				var mid := wrapf(rot.angle() - swept * 0.5, -PI, PI)
				ev = {"type": "arc", "dir": 1 if swept > 0.0 else -1, "through": "top" if sin(mid) > 0.0 else "bottom",
					"from": start_sector, "to": sector}
			elif not void_gesture and not held_fired and not arc_fired and tilt_time >= HOLD and absf(swept) < deg_to_rad(60.0):
				held_fired = true
				ev = {"type": "hold", "sector": sector}
	if ev.is_empty() and not _pending.is_empty():
		_pending_t += dt
		if _pending_t >= CONFIRM:
			ev = _pending
			_pending = {}
			if int(ev.sector) == _last_flick_sector and _last_flick_t < DOUBLE_GAP:
				ev = {"type": "double", "sector": int(ev.sector), "dur": ev.dur}
			_last_flick_sector = int(ev.sector)
			_last_flick_t = 0.0
	if not ev.is_empty():
		history.append([ev.type, ev.get("sector", ev.get("to", 99)), _clock])
		if history.size() > 6:
			history.pop_front()
	return ev

## Últimos sectores de flick en `window` segundos (secuencia de gestos).
func sequence(window := 0.8) -> Array:
	var out := []
	for h in history:
		if _clock - float(h[2]) <= window and h[0] in ["flick", "double"]:
			out.append(h[1])
	return out

## El gesto en curso deja de contar (se ha usado para otra cosa: SALTO, VAULT, un enlace...).
func cancel() -> void:
	if tilted:
		void_gesture = true
	_pending = {}

func busy() -> bool:
	return tilted and not void_gesture

static func _opposite(a: int, b: int) -> bool:
	var d := absi(a - b) % 8
	return mini(d, 8 - d) >= 3
