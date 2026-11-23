extends Node
## Récords, estadísticas y progresión (autoload "SaveData"). Se guarda en user://save.cfg.
## Diseñado para crecer: logros, desbloqueos, ropa y ghosts se guardan en secciones propias.

const PATH := "user://save.cfg"

var records := {}       # clave -> valor (mejor puntuación, mejor tiempo...)
var stats := {}         # clave -> contador (movimientos realizados, caídas...)
var ghosts := {}        # clave de reto -> Array de muestras del mejor recorrido
var _dirty := false

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		records = cfg.get_value("data", "records", {})
		stats = cfg.get_value("data", "stats", {})
		ghosts = cfg.get_value("data", "ghosts", {})

## Guarda un récord si mejora. higher_is_better=false para tiempos.
func submit_record(key: String, value: float, higher_is_better := true) -> bool:
	var has := records.has(key)
	var better: bool = not has or (value > records[key] if higher_is_better else value < records[key])
	if better:
		records[key] = value
		_dirty = true
		save()
	return better

func get_record(key: String, default_value = null):
	return records.get(key, default_value)

func add_stat(key: String, amount := 1) -> void:
	stats[key] = stats.get(key, 0) + amount
	_dirty = true

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("data", "records", records)
	cfg.set_value("data", "stats", stats)
	cfg.set_value("data", "ghosts", ghosts)
	cfg.save(PATH)
	_dirty = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _dirty:
			save()
