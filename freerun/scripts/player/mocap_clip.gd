class_name MocapClip
extends RefCounted
## Clip de captura de movimiento real (CMU Graphics Lab Motion Capture Database) convertido al
## esqueleto del BodyRig con tools/mocap/cmu_to_clip.py. Cada fotograma trae la rotación local de
## las articulaciones, el giro acumulado de la cadera (para sincronizar con el giro del mortal en
## el juego) y el descenso de cadera. `takeoff` y `land` marcan cuando los pies dejan y vuelven
## a tocar el suelo en la captura.

var joints: Array[String] = []
var rots: Array = []              # por fotograma: Array[Quaternion] en el orden de `joints`
var pitch := PackedFloat32Array()
var drop := PackedFloat32Array()
var takeoff := 0
var land := 0

static var _cache := {}

static func load_clip(path: String) -> MocapClip:
	if _cache.has(path):
		return _cache[path]
	if not FileAccess.file_exists(path):
		return null
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY or not data.has("frames"):
		return null
	var c := MocapClip.new()
	c.takeoff = int(data.takeoff)
	c.land = int(data.land)
	var fr: Array = data.frames
	for k in (fr[0].j as Dictionary).keys():
		c.joints.append(String(k))
	var best := -INF
	for f in fr:
		var qs: Array[Quaternion] = []
		for k in c.joints:
			var q: Array = f.j[k]
			qs.append(Quaternion(q[0], q[1], q[2], q[3]).normalized())
		c.rots.append(qs)
		best = maxf(best, float(f.pitch))     # giro monótono (para buscar por ángulo)
		c.pitch.append(best)
		c.drop.append(float(f.get("drop", 0.0)))
	_cache[path] = c
	return c

func frame_count() -> int:
	return rots.size()

## Pose (rotaciones de las articulaciones en Euler YXZ, como Node3D.rotation) en un fotograma
## fraccionario.
func pose_at(f: float) -> Dictionary:
	var n := rots.size()
	var fc := clampf(f, 0.0, float(n - 1))
	var i := int(floor(fc))
	var j := mini(i + 1, n - 1)
	var w := fc - float(i)
	var a: Array = rots[i]
	var b: Array = rots[j]
	var out := {}
	for k in joints.size():
		var q: Quaternion = (a[k] as Quaternion).slerp(b[k], w)
		out[joints[k]] = canonical_euler(Basis(q).get_euler())
	return out

## El mismo giro en Euler YXZ tiene dos formas: (x, y, z) y (π - x, y + π, z + π). Se usa la de
## giros laterales pequeños, para que el muelle de la pose no dé la vuelta larga (brazos y piernas
## girando de golpe entre fotogramas).
static func canonical_euler(e: Vector3) -> Vector3:
	var alt := Vector3(wrapf(PI - e.x, -PI, PI), wrapf(e.y + PI, -PI, PI), wrapf(e.z + PI, -PI, PI))
	if absf(alt.y) + absf(alt.z) < absf(e.y) + absf(e.z):
		return alt
	return e

func drop_at(f: float) -> float:
	var n := drop.size()
	var fc := clampf(f, 0.0, float(n - 1))
	var i := int(floor(fc))
	return lerpf(drop[i], drop[mini(i + 1, n - 1)], fc - float(i))

## Fotograma del vuelo en el que la cadera de la captura lleva el giro `progress` (0 = despegue,
## 1 = aterrizaje): así la forma del cuerpo (agrupar, abrir) va con el giro real del mortal.
func flight_frame(progress: float) -> float:
	var p0 := pitch[takeoff]
	var p1 := pitch[land]
	var target := lerpf(p0, p1, clampf(progress, 0.0, 1.0))
	var lo := takeoff
	var hi := land
	while hi - lo > 1:
		var mid := (lo + hi) / 2
		if pitch[mid] <= target:
			lo = mid
		else:
			hi = mid
	var span := pitch[hi] - pitch[lo]
	return float(lo) + (0.0 if span <= 1e-5 else clampf((target - pitch[lo]) / span, 0.0, 1.0))
