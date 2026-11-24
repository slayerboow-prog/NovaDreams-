class_name ChainSystem
extends RefCounted
## Encadenamiento de movimientos: al recibir con los pies tras una habilidad (rondada,
## flic-flac, macaco, raiz...) o una acrobacia preparatoria (aerial, patadas), se abre una
## ventana de enlace con la POTENCIA que deja ese movimiento: velocidad y dirección de salida,
## rebote vertical disponible y rotación (giro) acumulada.
##
## Si el siguiente movimiento sale dentro de la ventana y la transición es físicamente
## coherente (tabla CHAINS), hereda esa potencia: más altura del rebote, el giro que prepara
## un cork o un butterfly twist, la velocidad para un butterfly... El timing cuenta: el rebote
## completo solo está al principio de la ventana (cuando las piernas aún están cargadas).
##
## Destinos: identificadores de habilidad de suelo (bhs, roundoff...) o de salto:
##   flip_back · flip_front · flip_side · butterfly · aerial · kick

## from → {destino: tipo de transferencia}
##   rebote  el rebote vertical se suma al salto
##   giro    además precarga el tirabuzón (más velocidad de giro con el joystick GIRO)
##   barrido la pierna lanzada da la rotación horizontal de un butterfly / la entrada de un gainer
##   carrera conserva la velocidad de salida
const CHAINS := {
	"roundoff": {"flip_back": "rebote", "bhs": "rebote", "flip_side": "rebote"},
	"bhs": {"flip_back": "rebote", "bhs": "rebote"},
	"pushoff": {"flip_back": "rebote", "bhs": "rebote"},
	"macaco": {"bhs": "rebote", "flip_back": "rebote", "macaco": "carrera"},
	"cartwheel": {"flip_back": "rebote", "roundoff": "carrera"},
	"raiz": {"flip_back": "giro", "raiz": "giro", "td_raiz": "giro"},
	"td_raiz": {"butterfly": "giro", "flip_back": "giro", "kick": "giro"},
	"hook": {"flip_back": "giro", "kick": "giro"},
	"scoot": {"butterfly": "giro", "raiz": "giro", "td_raiz": "giro", "kick": "giro"},
	"aerial": {"butterfly": "barrido", "aerial": "carrera"},
	"kick": {"flip_back": "giro", "kick": "giro"},
	"butterfly": {"butterfly": "barrido", "flip_back": "giro"},
}

var link := {}             # enlace abierto: {from, name, time, window, power...}
var serial := 0            # cambia con cada enlace nuevo

func open(from: String, display_name: String, window: float, power: Dictionary) -> void:
	link = power.duplicate()
	link.from = from
	link.name = display_name
	link.window = window
	link.time = window
	serial += 1

func tick(dt: float) -> void:
	if link.is_empty():
		return
	link.time -= dt
	if link.time <= 0.0:
		link = {}

func active() -> bool:
	return not link.is_empty()

func time_left() -> float:
	return float(link.get("time", 0.0))

func from_id() -> String:
	return String(link.get("from", ""))

static func allowed(from: String, to: String) -> bool:
	return CHAINS.has(from) and CHAINS[from].has(to)

static func kind_of(from: String, to: String) -> String:
	return String(CHAINS.get(from, {}).get(to, ""))

## Consume el enlace para el movimiento `to`. Devuelve la potencia transferida
## ({} si no hay enlace o la transición no es coherente: el movimiento sale normal).
## timing: 1 al principio de la ventana (rebote completo) → 0,45 al final.
func consume(to: String) -> Dictionary:
	if link.is_empty():
		return {}
	var from := from_id()
	var out := {}
	if allowed(from, to):
		var elapsed := float(link.window) - float(link.time)
		var timing := clampf(1.0 - maxf(0.0, elapsed - 0.06) / maxf(float(link.window), 0.05) * 0.55, 0.45, 1.0)
		out = link.duplicate()
		out.kind = kind_of(from, to)
		out.timing = timing
		out.rebound_vy = float(link.get("rebound_vy", 0.0)) * timing
		out.to = to
	link = {}
	return out

## Destino de salto según la zona/gesto con el que se despega.
static func jump_target(sector: int, travel_speed: float) -> String:
	match sector:
		-2, -1, -3:
			return "flip_back"
		2, 1:
			return "flip_front"
		0, 4:
			return "flip_side"
		3:
			return "aerial"
	return "kick"
