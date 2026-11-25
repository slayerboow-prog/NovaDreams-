class_name GameModes
extends RefCounted
## Las cinco disciplinas. Todas usan el mismo PlayerController, el mismo ComboSystem
## y el mismo escenario; cada modo solo cambia reglas, objetivos y puntuación.

const LIST := ["freerun", "tricking", "water", "beach", "challenge", "freestyle"]

static func create(id: String) -> Base:
	match id:
		"tricking": return Tricking.new()
		"water": return Water.new()
		"challenge": return Challenge.new()
		"freestyle": return Freestyle.new()
		"beach": return Beach.new()
	return Freerun.new()

static func info(id: String) -> Dictionary:
	return {
		"freerun": {"title": "Freerunning", "desc": "Explora la ciudad y encadena vaults, wall runs y saltos."},
		"tricking": {"title": "Tricking", "desc": "Césped y espacio abierto para mortales, corks y combinaciones."},
		"water": {"title": "Water Tricks", "desc": "Salta desde el trampolín y entra limpio en el agua."},
		"challenge": {"title": "Parkour Challenge", "desc": "Contrarreloj por checkpoints. Supera tu fantasma."},
		"beach": {"title": "Playa", "desc": "Arena y una boya de barco: písala corriendo para salir disparado y hacer mortales."},
		"freestyle": {"title": "Freestyle Competition", "desc": "90 segundos. Variedad, fluidez y dificultad puntúan."},
	}.get(id, {})


class Base:
	extends RefCounted
	var id := "freerun"
	var game: Node
	var player: PlayerController
	var combo: ComboSystem
	var finished := false

	func setup(g: Node) -> void:
		game = g
		player = g.player
		combo = g.combo

	func spawn_key() -> String:
		return id

	func start() -> void:
		finished = false

	func stop() -> void:
		pass

	func on_move(_name: String, _q: float, _info: Dictionary) -> void:
		pass

	func on_land(_result: Dictionary) -> void:
		pass

	func on_water(_result: Dictionary) -> void:
		pass

	func on_respawn() -> void:
		pass

	func tick(_dt: float) -> void:
		pass

	func status_text() -> String:
		return ""

	func extra_button() -> String:
		return ""

	func on_extra_button() -> void:
		pass

	func record_key() -> String:
		return id + "_best_combo"

	func on_combo_banked(points: int) -> void:
		if SaveData.submit_record(record_key(), points):
			game.ui.popup("¡NUEVO RÉCORD DE COMBO!", Color(1, 0.85, 0.2))


class Freerun:
	extends Base
	func _init() -> void:
		id = "freerun"

	func status_text() -> String:
		return "Puntos %d   ·   Mejor combo %d" % [combo.total_score, int(SaveData.get_record(record_key(), 0))]


class Tricking:
	extends Base
	var learned := {}
	func _init() -> void:
		id = "tricking"

	func on_move(name: String, q: float, info: Dictionary) -> void:
		if info.has("flips") or info.has("twist_halves") or info.has("rolls"):
			if q >= 1.0 and not learned.has(name):
				learned[name] = true
				SaveData.add_stat("trick_" + name)
				game.ui.popup("Nuevo truco: " + name, Color(0.5, 1, 0.8))

	func status_text() -> String:
		return "Trucos aterrizados limpios: %d   ·   Puntos %d" % [learned.size(), combo.total_score]


class Water:
	extends Base
	var best := 0.0
	var last := 0.0
	var respawn_timer := -1.0
	var high := false
	func _init() -> void:
		id = "water"

	func spawn_key() -> String:
		return "water_high" if high else "water"

	func start() -> void:
		super.start()
		best = float(SaveData.get_record("water_best_dive", 0.0))

	func on_water(r: Dictionary) -> void:
		var trick: Dictionary = r.trick
		var difficulty: float = trick.get("difficulty", 0.0) if not trick.is_empty() else 0.0
		var execution: float = {"perfect": 1.0, "clean": 0.8, "sloppy": 0.5, "flat": 0.12}[r.quality]
		var base := 1.5 + difficulty * 2.2 + clampf(r.height, 0.0, 10.0) * 0.18 + clampf(r.air_time, 0.0, 2.0) * 0.8
		var score := snappedf(base * execution, 0.1)
		last = score
		var label: String = {"perfect": "ENTRADA PERFECTA", "clean": "Entrada limpia", "sloppy": "Entrada forzada", "flat": "¡PLANCHAZO!"}[r.quality]
		var name: String = trick.get("name", "Salto")
		game.ui.popup("%s  ·  %s  ·  %.1f pts" % [name, label, score],
			Color(0.5, 0.9, 1) if r.quality in ["perfect", "clean"] else Color(1, 0.6, 0.4))
		if SaveData.submit_record("water_best_dive", score):
			best = score
			game.ui.popup("¡Mejor salto!", Color(1, 0.85, 0.2))
		respawn_timer = 1.8

	func tick(dt: float) -> void:
		if respawn_timer > 0.0:
			respawn_timer -= dt
			if respawn_timer <= 0.0:
				game.respawn_player()

	func extra_button() -> String:
		return "Trampolín 6 m" if not high else "Trampolín 3 m"

	func on_extra_button() -> void:
		high = not high
		game.respawn_player()

	func status_text() -> String:
		return "Último salto %.1f   ·   Mejor %.1f   ·   Trampolín %s" % [last, best, "6 m" if high else "3 m"]


class Challenge:
	extends Base
	var checkpoints: Array = []
	var next := 0
	var time := 0.0
	var running := false
	var rings: Array[MeshInstance3D] = []
	var ghost_samples: Array = []
	var best_ghost: Array = []
	var ghost_node: MeshInstance3D
	var sample_timer := 0.0
	const RADIUS := 2.3
	const KEY := "challenge_city_time"

	func _init() -> void:
		id = "challenge"

	func start() -> void:
		super.start()
		checkpoints = game.level_info.checkpoints
		_build_rings()
		best_ghost = SaveData.ghosts.get(KEY, [])
		_reset_run()

	func stop() -> void:
		for r in rings:
			r.queue_free()
		rings.clear()
		if ghost_node:
			ghost_node.queue_free()
			ghost_node = null

	func _build_rings() -> void:
		for i in checkpoints.size():
			var mi := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = RADIUS - 0.18
			tm.outer_radius = RADIUS
			tm.rings = 32
			tm.ring_segments = 8
			mi.mesh = tm
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(1, 0.8, 0.2)
			mi.material_override = m
			mi.position = checkpoints[i]
			mi.rotation_degrees.x = 90.0
			game.add_child(mi)
			rings.append(mi)
		if true:
			ghost_node = MeshInstance3D.new()
			var cm := CapsuleMesh.new()
			cm.radius = 0.3
			cm.height = 1.8
			ghost_node.mesh = cm
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.7, 0.85, 1.0, 0.35)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ghost_node.material_override = gm
			ghost_node.visible = false
			game.add_child(ghost_node)

	func _reset_run() -> void:
		next = 0
		time = 0.0
		running = false
		ghost_samples.clear()
		sample_timer = 0.0
		_update_rings()

	func on_respawn() -> void:
		_reset_run()

	func _update_rings() -> void:
		for i in rings.size():
			var m: StandardMaterial3D = rings[i].material_override
			rings[i].visible = i >= next
			m.albedo_color = Color(0.2, 1.0, 0.6) if i == next else Color(1, 0.8, 0.2, 0.6)

	func tick(dt: float) -> void:
		if not running and next == 0 and player.speed() > 0.5:
			running = true
		if running:
			time += dt
			sample_timer -= dt
			if sample_timer <= 0.0:
				sample_timer = 0.05
				ghost_samples.append(player.global_position)
		if next < checkpoints.size():
			var cp: Vector3 = checkpoints[next]
			if (player.global_position + Vector3.UP * 0.9).distance_to(cp) < RADIUS:
				next += 1
				_update_rings()
				if next >= checkpoints.size():
					_finish()
				else:
					game.ui.popup("Checkpoint %d/%d  ·  %s" % [next, checkpoints.size(), format_time(time)], Color(0.6, 1, 0.8))
		# Fantasma del mejor recorrido
		if ghost_node and best_ghost.size() > 1 and running:
			var idx := int(time / 0.05)
			ghost_node.visible = idx < best_ghost.size()
			if ghost_node.visible:
				ghost_node.position = best_ghost[idx] + Vector3.UP * 0.9

	func _finish() -> void:
		running = false
		var best: float = SaveData.get_record(KEY, 0.0)
		if SaveData.submit_record(KEY, time, false):
			SaveData.ghosts[KEY] = ghost_samples.duplicate()
			best_ghost = SaveData.ghosts[KEY]
			SaveData.save()
			game.ui.popup("¡RÉCORD!  %s" % format_time(time), Color(1, 0.85, 0.2))
		else:
			game.ui.popup("Meta  %s  (récord %s)" % [format_time(time), format_time(best)], Color(0.7, 0.9, 1))
		game.ui.popup("Pulsa el botón de reinicio (R) para repetir", Color(1, 1, 1))

	static func format_time(t: float) -> String:
		return "%02d:%05.2f" % [int(t) / 60, fmod(t, 60.0)]

	func status_text() -> String:
		var best = SaveData.get_record(KEY, null)
		return "Tiempo %s   ·   Checkpoint %d/%d   ·   Récord %s" % [format_time(time), next, checkpoints.size(),
			format_time(best) if best != null else "--:--"]


class Freestyle:
	extends Base
	var time_left := 90.0
	const DURATION := 90.0
	const KEY := "freestyle_best"
	func _init() -> void:
		id = "freestyle"

	func start() -> void:
		super.start()
		time_left = DURATION
		combo.reset_all()

	func on_respawn() -> void:
		if finished:
			start()

	func tick(dt: float) -> void:
		if finished:
			return
		time_left -= dt
		if time_left <= 0.0:
			time_left = 0.0
			combo.bank()
			finished = true
			var score := combo.total_score
			if SaveData.submit_record(KEY, score):
				game.ui.popup("¡RÉCORD FREESTYLE!  %d" % score, Color(1, 0.85, 0.2))
			else:
				game.ui.popup("Tiempo  ·  %d puntos (récord %d)" % [score, int(SaveData.get_record(KEY, 0))], Color(0.7, 0.9, 1))
			game.ui.popup("Pulsa el botón de reinicio (R) para otra ronda", Color(1, 1, 1))

	func status_text() -> String:
		return "Tiempo %d s   ·   Puntos %d   ·   Récord %d" % [ceili(time_left), combo.total_score, int(SaveData.get_record(KEY, 0))]


class Beach:
	extends Base
	var launches := 0
	func _init() -> void:
		id = "beach"

	func on_move(name: String, _q: float, _info: Dictionary) -> void:
		if name == "Buoy Launch":
			launches += 1

	func status_text() -> String:
		return "Impulsos en la boya %d   ·   Puntos %d   ·   Mejor combo %d" % [launches, combo.total_score, int(SaveData.get_record(record_key(), 0))]
