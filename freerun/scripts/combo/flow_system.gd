class_name FlowSystem
extends RefCounted
## Medidor FLOW (0-100): mide lo bien que fluye la línea, no cuántos mortales se hacen.
## Sube con: movimientos distintos, dificultad, uso del entorno (vaults, paredes, agarres,
## precisión), aterrizajes limpios/perfectos y continuidad sin pararse.
## Baja con: repetir el mismo movimiento, aterrizajes forzados o duros, pararse y caerse.
## Por encima de 60 da un pequeño extra (velocidad punta +6 %, salto +4 %, recuperación
## más rápida) que nunca permite nada físicamente imposible.

signal flow_changed(value: float)

const ENVIRONMENT := ["Speed Vault", "Lazy Vault", "Step Vault", "Kong Vault", "Dash Vault", "Double Kong",
	"Kash Vault", "Reverse Vault", "Thief Vault", "Turn Vault", "Wall Run", "Wall Jump", "Wall Climb", "Wall Kick", "Tic Tac", "Cat Leap",
	"Ledge Grab", "Climb Up", "Precision Jump", "Safety Roll", "Wall Flip", "Wall Gainer", "Step Up", "Mantle"]
## Movimientos de preparación que dan potencia al siguiente (cuentan como enlace si se encadenan)
const SETUPS := ["Round-off", "Back Handspring", "Macaco", "Hook Kick", "Raiz", "Touchdown Raiz", "Scoot",
	"Handstand Push-off", "Cartwheel"]
const BOOST_FROM := 60.0

var value := 0.0
var recent: Array[String] = []        # últimos movimientos (para detectar repeticiones)
var still_time := 0.0

func reset() -> void:
	value = 0.0
	recent.clear()
	still_time = 0.0
	flow_changed.emit(value)

## Extra que recibe el personaje: 0 por debajo de 60, 1 con el medidor lleno.
func boost() -> float:
	return clampf((value - BOOST_FROM) / (100.0 - BOOST_FROM), 0.0, 1.0)

func is_flowing() -> bool:
	return value >= BOOST_FROM

func _add(v: float) -> void:
	value = clampf(value + v, 0.0, 100.0)
	flow_changed.emit(value)

## Movimiento realizado. Devuelve lo que ha sumado (para pruebas y depuración).
func on_move(move_name: String, quality: float, info: Dictionary) -> float:
	if info.get("penalty", false):
		_add(-15.0)
		return -15.0
	if move_name in ["Roll", "Drop Landing", "Kip-up"]:
		return 0.0                      # recursos para continuar, no suman por sí solos
	var reps := recent.count(move_name)
	recent.append(move_name)
	if recent.size() > 6:
		recent.pop_front()
	var gain := 0.0
	if reps == 0:
		var diff := ComboSystem.difficulty_of(move_name, info)
		gain = 5.0 + 5.0 * clampf(diff, 0.3, 2.5)
		if move_name in ENVIRONMENT or move_name.begins_with("Kong") or move_name.begins_with("Dash"):
			gain += 4.0                 # aprovechar el entorno vale más que otro mortal en plano
		if info.get("chain", false):
			gain += 3.0                 # enlace con potencia (rondada → flic-flac → mortal...)
	elif reps == 1:
		gain = 1.0
	else:
		gain = -3.0 * (reps - 1)        # spam del mismo truco: el flow se corta
	if quality < 0.75 and gain > 0.0:
		gain *= 0.3
	still_time = 0.0
	_add(gain)
	return gain

func on_land(quality: String, had_trick: bool, hard: bool) -> void:
	if quality == "crash":
		_add(-value * 0.8)
		recent.clear()
		return
	if hard:
		_add(-12.0)
		return
	match quality:
		"perfect": _add(6.0 if had_trick else 1.5)
		"clean": _add(3.0 if had_trick else 0.5)
		"sloppy": _add(-12.0)

## Cada frame. moving: el atleta se desplaza o está ocupado (aire, pared, vault...).
func tick(dt: float, moving: bool) -> void:
	if value <= 0.0:
		return
	if moving:
		still_time = 0.0
		_add(-1.2 * dt)                 # se mantiene mientras la línea siga viva
	else:
		still_time += dt
		_add(-(4.0 if still_time < 0.8 else 16.0) * dt)
