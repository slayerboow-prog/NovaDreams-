class_name ComboSystem
extends RefCounted
## Flow: encadena movimientos en un combo con multiplicador progresivo.
## - Variedad: cada movimiento nuevo sube mucho el multiplicador.
## - Repetición: cada repetición dentro del combo vale la mitad que la anterior.
## - Continuidad: el combo se mantiene mientras sigas moviéndote; parado se acaba.
## - Velocidad: bonificación según la velocidad media del combo.
## - Aterrizajes: forzados restan multiplicador; una caída pierde todo el combo.

signal combo_changed(combo: ComboSystem)
signal combo_banked(points: int, summary: Dictionary)
signal combo_bailed(lost_points: int)

## Puntos base y dificultad de cada movimiento (los trucos aéreos usan su propia dificultad).
const MOVES := {
	"Speed Vault": [150, 1.0], "Lazy Vault": [130, 0.9], "Step Vault": [90, 0.6],
	"Kong Vault": [260, 1.4], "Thief Vault": [170, 1.0], "Turn Vault": [150, 0.9], "Dash Vault": [240, 1.3], "Step Up": [40, 0.3], "Climb Up": [120, 0.6],
	"Mantle": [80, 0.5], "Wall Run": [200, 1.2], "Wall Jump": [120, 0.8], "Wall Climb": [140, 0.8],
	"Wall Kick": [120, 0.8], "Tic Tac": [180, 1.1], "Cat Leap": [220, 1.2], "Ledge Grab": [90, 0.5],
	"Precision Jump": [250, 1.3], "Drop Landing": [120, 0.7], "Safety Roll": [180, 0.9],
	"Roll": [60, 0.3],
}
const TRICK_BASE := 300.0
const GRACE := 1.6                 # segundos de suelo sin acción antes de cerrar el combo

var active := false
var chain: Array[String] = []
var counts := {}
var points := 0.0
var multiplier := 1.0
var grace := 0.0
var speed_sum := 0.0
var speed_time := 0.0
var total_score := 0
var best_combo := 0
var last_bank := 0
var sloppy_count := 0

func reset_all() -> void:
	_clear()
	total_score = 0
	best_combo = 0
	last_bank = 0

func _clear() -> void:
	active = false
	chain.clear()
	counts.clear()
	points = 0.0
	multiplier = 1.0
	grace = 0.0
	speed_sum = 0.0
	speed_time = 0.0
	sloppy_count = 0

## Valor de un movimiento antes de multiplicadores.
static func base_points(move_name: String, info: Dictionary) -> float:
	if MOVES.has(move_name):
		return float(MOVES[move_name][0])
	var diff: float = info.get("difficulty", 1.0)
	return TRICK_BASE * pow(diff, 1.35)

static func difficulty_of(move_name: String, info: Dictionary) -> float:
	if MOVES.has(move_name):
		return float(MOVES[move_name][1])
	return info.get("difficulty", 1.0)

func add_move(move_name: String, quality := 1.0, info := {}) -> float:
	if info.get("penalty", false):
		penalize(0.75)
		return 0.0
	var n: int = counts.get(move_name, 0)
	counts[move_name] = n + 1
	var repeat_factor := pow(0.5, n)
	var pts := base_points(move_name, info) * quality * repeat_factor
	var diff := difficulty_of(move_name, info)
	if info.get("chain", false):
		multiplier += 0.15                          # enlace con transferencia de potencia
	if n == 0:
		multiplier += 0.25 + 0.35 * diff            # variedad
	else:
		multiplier += 0.05 * repeat_factor          # repetir casi no suma
	if quality < 0.75:
		sloppy_count += 1
		multiplier = maxf(1.0, multiplier - 0.4)
	points += pts
	chain.append(move_name)
	active = true
	grace = GRACE
	combo_changed.emit(self)
	return pts

func penalize(mult_loss: float) -> void:
	if not active:
		return
	multiplier = maxf(1.0, multiplier - mult_loss)
	sloppy_count += 1
	combo_changed.emit(self)

## Llamar cada frame. busy = en el aire, en pared, haciendo vault... (no consume tiempo).
func tick(dt: float, busy: bool, spd: float) -> void:
	if not active:
		return
	speed_sum += spd * dt
	speed_time += dt
	if busy:
		grace = maxf(grace, 0.6)
		return
	grace -= dt * (2.2 if spd < 2.0 else 1.0)
	if grace <= 0.0:
		bank()

func speed_bonus() -> float:
	if speed_time <= 0.0:
		return 0.0
	return clampf((speed_sum / speed_time - 4.0) / 10.0, 0.0, 0.5)

func variety_ratio() -> float:
	return float(counts.size()) / maxf(1.0, float(chain.size()))

func current_value() -> int:
	return int(points * multiplier * (1.0 + speed_bonus()))

func bank() -> int:
	if not active:
		return 0
	var continuity := 1.0 + 0.05 * maxf(0.0, chain.size() - 3)
	var value := int(points * multiplier * (1.0 + speed_bonus()) * minf(continuity, 1.75))
	var summary := {"chain": chain.duplicate(), "multiplier": multiplier, "speed_bonus": speed_bonus(),
		"variety": variety_ratio(), "moves": chain.size(), "unique": counts.size(), "continuity": continuity}
	total_score += value
	best_combo = maxi(best_combo, value)
	last_bank = value
	_clear()
	combo_banked.emit(value, summary)
	return value

func bail() -> void:
	if not active:
		return
	var lost := current_value()
	_clear()
	combo_bailed.emit(lost)
