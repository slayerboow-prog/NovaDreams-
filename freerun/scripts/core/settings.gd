extends Node
## Ajustes del jugador (autoload "Settings"). Se guardan en user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

# Controles
var camera_sensitivity := 1.0
var gesture_sensitivity := 1.0
var control_scale := 1.0
var camera_distance := 1.0       # 0,75 cerca … 1,4 lejos
var camera_height := 1.0         # 0,7 baja … 1,5 alta (más cenital)
## Cámara: 0 híbrida (sigue al atleta, respeta lo que muevas), 1 manual, 2 automática
var camera_mode := 0
var control_opacity := 0.55
var left_handed := false          # intercambia joystick y botones
var force_touch_ui := false       # mostrar controles táctiles en escritorio
var invert_camera_y := false
## Acrobacias: 0 doble joystick (rueda) · 1 solo gestos · 2 solo cruceta · 3 gestos + cruceta
## · 4 BOTONERA (SALTO grande + arco de botones, uno por movimiento) — por defecto
var trick_controls := 5
var controls_version := 3         # sube cuando cambia el esquema por defecto

# Jugabilidad
## 0 = Pro (sin ayudas), 1 = Media, 2 = Alta. Afecta a la calibración de rotaciones y al "spotting".
var rotation_assist := 2

# Gráficos: 0 bajo, 1 medio, 2 alto
var graphics_preset := 1
var show_fps := false

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key in _keys():
		set(key, cfg.get_value("settings", key, get(key)))
	if int(cfg.get_value("settings", "controls_version", 0)) < 3:
		trick_controls = 5            # nuevo esquema por defecto: todo con gestos (SALTO + GIRO)
		controls_version = 3

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in _keys():
		cfg.set_value("settings", key, get(key))
	cfg.save(PATH)
	changed.emit()

func _keys() -> Array:
	return ["camera_sensitivity", "gesture_sensitivity", "control_scale", "camera_distance", "camera_height", "camera_mode", "control_opacity",
		"left_handed", "force_touch_ui", "invert_camera_y", "trick_controls", "controls_version", "rotation_assist", "graphics_preset", "show_fps"]

func assist_strength() -> float:
	return [0.0, 0.5, 1.0][clampi(rotation_assist, 0, 2)]
