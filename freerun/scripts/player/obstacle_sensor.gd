class_name ObstacleSensor
extends RefCounted
## Lectura del entorno con raycasts: obstáculos saltables (vaults), bordes (ledges),
## paredes laterales/frontales y anchura del apoyo (aterrizajes de precisión).
## Todas las consultas trabajan con la posición de los pies del personaje.

const WORLD_MASK := 1

var body: CharacterBody3D
var exclude: Array[RID] = []

func _init(b: CharacterBody3D) -> void:
	body = b
	exclude = [b.get_rid()]

func ray(from: Vector3, to: Vector3) -> Dictionary:
	var space := body.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, WORLD_MASK, exclude)
	return space.intersect_ray(q)

static func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

## Obstáculo bajo delante: devuelve distancia, altura, profundidad y suelo al otro lado.
func probe_vault(feet: Vector3, dir: Vector3, speed: float, max_h: float, min_h: float) -> Dictionary:
	var look := 0.55 + speed * 0.17
	var from := feet + Vector3.UP * 0.4
	var hit := ray(from, from + dir * look)
	# Barras sueltas (hueco por debajo): se buscan también más arriba, hasta la altura máxima
	for hy in [0.6, 0.75, 0.88, 1.0, 1.12, 1.25]:
		if not hit.is_empty() or hy > max_h:
			break
		from = feet + Vector3.UP * hy
		hit = ray(from, from + dir * look)
	if hit.is_empty():
		return {}
	var n: Vector3 = hit.normal
	if absf(n.y) > 0.35:
		return {}
	var into := -flat(n).normalized()
	var approach := dir.angle_to(into)
	if approach > deg_to_rad(58.0):
		return {}
	var dist := flat(hit.position - from).length()
	var probe: Vector3 = hit.position + into * 0.04      # vallas finas (6-10 cm): la parte de arriba está muy cerca
	var top_hit := ray(Vector3(probe.x, feet.y + max_h + 0.25, probe.z), Vector3(probe.x, feet.y + 0.2, probe.z))
	if top_hit.is_empty() or top_hit.normal.y < 0.7:
		return {}
	var top_y: float = top_hit.position.y
	var h := top_y - feet.y
	if h < min_h or h > max_h:
		return {}
	# Hueco por encima del obstáculo para pasar el cuerpo.
	var over_from := Vector3(feet.x, top_y + 0.75, feet.z)
	if not ray(over_from, over_from + dir * (dist + 0.8)).is_empty():
		return {}
	# Profundidad: avanzar sobre la parte superior hasta que deje de haber superficie.
	var depth := -1.0
	var k := 0.2
	var base: Vector3 = hit.position + into * 0.1          # (la profundidad se mide como siempre)
	while k <= 3.4:
		var p: Vector3 = Vector3(base.x, top_hit.position.y, base.z) + dir * k
		var d := ray(Vector3(p.x, top_y + 0.4, p.z), Vector3(p.x, top_y - 0.3, p.z))
		if d.is_empty():
			depth = k
			break
		k += 0.2
	var mount := depth < 0.0
	if mount:
		depth = 0.9
	# Espacio libre al otro lado a la altura del cuerpo.
	var far_point: Vector3 = top_hit.position + dir * (depth + 0.55)
	var land := ray(Vector3(far_point.x, top_y + 0.3, far_point.z), Vector3(far_point.x, top_y - 8.0, far_point.z))
	var land_y: float = land.position.y if not land.is_empty() else top_y - 8.0
	if not mount:
		var blocker := ray(Vector3(far_point.x, land_y + 0.6, far_point.z) - dir * 0.3,
			Vector3(far_point.x, land_y + 0.6, far_point.z) + dir * 0.35)
		if not blocker.is_empty():
			return {}
	return {"dist": dist, "height": h, "top_y": top_y, "depth": depth, "normal": n,
		"approach": approach, "land_y": land_y, "mount": mount, "edge": hit.position}

## Borde agarrable delante (para colgarse o subir directamente).
func probe_ledge(feet: Vector3, dir: Vector3) -> Dictionary:
	for hgt: float in [1.8, 1.3, 0.85]:
		var from := feet + Vector3.UP * hgt
		var hit := ray(from, from + dir * 0.75)
		if hit.is_empty():
			continue
		var n: Vector3 = hit.normal
		if absf(n.y) > 0.3:
			continue
		var into := -flat(n).normalized()
		var probe: Vector3 = hit.position + into * 0.18
		var top := ray(Vector3(probe.x, feet.y + 2.45, probe.z), Vector3(probe.x, feet.y + 0.45, probe.z))
		if top.is_empty() or top.normal.y < 0.75:
			return {}
		var top_y: float = top.position.y
		# Espacio para la cabeza/cuerpo sobre el borde.
		var head := Vector3(probe.x, top_y + 0.08, probe.z)
		if not ray(head, head + Vector3.UP * 0.9).is_empty():
			return {}
		var stand_from := Vector3(hit.position.x, top_y + 0.9, hit.position.z) + n * 0.1
		var can_stand := ray(stand_from, stand_from + into * 0.8).is_empty()
		return {"top_y": top_y, "rel": top_y - feet.y, "normal": flat(n).normalized(),
			"wall_point": hit.position, "can_stand": can_stand}
	return {}

## Pared a un lado (side = +1 derecha, -1 izquierda).
func probe_side_wall(feet: Vector3, facing: Vector3, side: float, reach := 0.95) -> Dictionary:
	var right := facing.cross(Vector3.UP).normalized()
	var from := feet + Vector3.UP * 1.0
	var hit := ray(from, from + right * side * reach)
	if hit.is_empty() or absf(hit.normal.y) > 0.25:
		return {}
	# La pared debe tener altura suficiente para correr por ella.
	var high := feet + Vector3.UP * 1.9
	if ray(high, high + right * side * (reach + 0.1)).is_empty():
		return {}
	hit["distance"] = flat(hit.position - from).length()
	return hit

## Pared delante en la dirección dir.
func probe_front_wall(feet: Vector3, dir: Vector3, reach := 0.9, hgt := 1.0) -> Dictionary:
	var from := feet + Vector3.UP * hgt
	var hit := ray(from, from + dir * reach)
	if hit.is_empty() or absf(hit.normal.y) > 0.25:
		return {}
	hit["distance"] = flat(hit.position - from).length()
	return hit

## Altura del suelo bajo un punto (o -INF).
func ground_below(pos: Vector3, max_dist := 40.0) -> float:
	var hit := ray(pos + Vector3.UP * 0.1, pos - Vector3.UP * max_dist)
	return hit.position.y if not hit.is_empty() else -INF

## Apoyo estrecho (barandilla, bordillo, viga): los rayos laterales no encuentran suelo.
func is_narrow_footing(feet: Vector3, facing: Vector3) -> bool:
	var right := facing.cross(Vector3.UP).normalized()
	var misses := 0
	for off in [right * 0.38, -right * 0.38, facing * 0.42, -facing * 0.42]:
		var p: Vector3 = feet + off
		if ray(p + Vector3.UP * 0.2, p - Vector3.UP * 0.35).is_empty():
			misses += 1
	return misses >= 2

## Borde donde aterrizar al saltar hacia delante (salto de precisión o de longitud): recorre el
## suelo en la dirección del salto y devuelve el primer borde alcanzable, ya sea al otro lado de
## un hueco (muro, bordillo, otra plataforma) o la parte de arriba de un obstáculo más alto.
## {"pos": punto de recepción justo dentro del borde, "edge": distancia al borde, "dy": altura
## relativa}. Vacío si delante el suelo sigue llano o lo que hay no se puede alcanzar;
## {"blocked": d} si hay un obstáculo más alto antes de la distancia mínima.
func find_landing_edge(feet: Vector3, dir: Vector3, dmin: float, dmax: float, max_up: float, max_down: float) -> Dictionary:
	var d3 := flat(dir).normalized()
	if d3.length() < 0.1:
		return {}
	var top := feet.y + max_up + 0.4
	var h0 := feet.y
	var low := INF                                  # punto más bajo del hueco recorrido
	var deep := false                               # hueco sin fondo cercano
	var d := 0.3
	while d <= dmax + 0.001:
		var p := feet + d3 * d
		var gy := ground_below(Vector3(p.x, top, p.z), max_up + max_down + 2.0)
		var edge := {"pos": Vector3(p.x, gy, p.z) + d3 * 0.18, "edge": d, "dy": gy - h0}
		if gy == -INF or gy < h0 - max_down:
			deep = true
		elif gy > h0 + max_up:
			return {}                               # pared demasiado alta: no se salta encima
		elif gy > h0 + 0.25:
			if d >= dmin:
				return edge                         # obstáculo más alto: su borde delantero
			return {"blocked": d}                   # demasiado cerca para este salto
		elif gy < h0 - 0.3:
			# El suelo baja: hueco, calle más baja... o una plataforma más baja al otro lado
			if d >= dmin and (deep or (low != INF and gy > low + 0.3)):
				return edge
			low = minf(low, gy)
		elif (deep or low != INF) and d >= dmin:
			return edge                             # al otro lado del hueco, a la misma altura
		d += 0.1
	return {}
