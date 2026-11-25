class_name GestureRecognizer
extends RefCounted
## Reconocedor de trazos dibujados con el dedo dentro de los joysticks (modo gestos).
##
## Todo se calcula en unidades del radio del joystick (plantillas normalizadas: funciona igual
## con cualquier tamaño de control) y con el eje y hacia ARRIBA (arriba = adelante).
##
## Prioridades (para que un gesto simple no se confunda con uno complejo):
##   1. Toque (trazo muy corto)                       → salto
##   2. Línea recta en una dirección principal         → mortal básico (respuesta inmediata)
##   3. Trazo con bucles (el dedo se cruza)            → cork, cork 720, aerial twist, gainer
##   4. Plantillas (curvas, arcos, zigzags, ganchos)   → resto de acrobacias y parkour
## Las plantillas de parkour solo cuentan si el contexto lo permite (obstáculo, pared, borde);
## si no, se prueba la siguiente plantilla y, si ninguna vale, se informa de por qué.

# --- Umbrales (configurables) -------------------------------------------------------------
static var TAP_MAX := 0.28            # recorrido máximo de un toque (radios)
static var SIMPLE_MIN := 0.45         # longitud mínima de una línea simple
static var SIMPLE_STRAIGHT := 0.86    # rectitud mínima (cuerda / recorrido)
static var PRECISION_MAX_LEN := 1.1    # línea corta hacia arriba (salto de precisión): nunca se cambia por otra cosa
static var SIMPLE_TURN := 30.0        # giro total máximo de una línea simple (grados)
static var CARDINAL_HALF := 30.0      # ±grados alrededor de ↑ ↓ ← → que cuentan como simples
static var CLEAR_MIN := 0.42            # parecido mínimo si no hay ningún otro movimiento cerca
static var CLEAR_MARGIN := 0.15        # ventaja que debe sacar a la segunda forma (otro movimiento)
const CLEAR_IDS := ["kong", "double_kong"]     # formas tan características que se aceptan algo torcidas
static var MATCH_MIN := 0.5           # parecido mínimo con una plantilla (0..1)
static var LOOP_ANGLE := 320.0        # grados de giro para contar un círculo (joystick morado)
static var LOOP_MIN_LEN := 0.9        # recorrido mínimo de un círculo (radios): evita temblores
const N := 40                         # puntos tras remuestrear

## Nombres que se muestran al reconocer.
const NAMES := {
	"front": "MORTAL ADELANTE", "back": "MORTAL ATRÁS", "side": "MORTAL LATERAL",
	"aerial": "AERIAL", "aerial_twist": "AERIAL TWIST", "cork": "CORK", "cork720": "CORK 720", "chutada": "CHUTADA",
	"webster": "WEBSTER", "gainer": "GAINER",
	"vault": "VAULT", "kong": "KONG VAULT", "double_kong": "DOBLE KONG", "kash": "KASH VAULT",
	"thief": "THIEF VAULT", "turn": "TURN VAULT", "wall_run": "WALL RUN", "wall_flip": "WALL FLIP",
	"climb": "ESCALADA", "ledge_grab": "AGARRE DE BORDE", "cat_leap": "CAT LEAP",
	"precision": "SALTO DE PRECISIÓN", "roll": "RODAR", "wall_climb": "WALL CLIMB",
	"palm": "PALM FLIP", "speed": "PASAVALLAS", "reverse": "REVERSO",
}

## Variantes de plantilla que cuentan como otro movimiento (distintas formas de dibujar lo mismo)
const TEMPLATE_ALIAS := {"kong_v": "kong", "kong_d": "kong", "double_kong_d": "double_kong"}

## Contexto que necesita cada movimiento de parkour (lo comprueba el jugador).
const NEEDS := {
	"vault": "obstacle", "kong": "obstacle", "double_kong": "obstacle", "kash": "obstacle", "thief": "obstacle",
	"turn": "obstacle", "wall_run": "wall_any", "wall_flip": "wall_front",
	"climb": "wall_front", "wall_climb": "wall_front", "cat_leap": "wall_front",
	"ledge_grab": "ledge", "roll": "roll", "palm": "wall_front", "speed": "obstacle", "reverse": "obstacle",
}
const NEED_TEXT := {
	"obstacle": "no hay obstáculo delante", "wall_front": "no hay pared delante",
	"wall_any": "no hay pared al lado", "ledge": "no hay borde ni pared", "roll": "ve corriendo o en el aire",
}

## Plantillas de trazo (x derecha, y arriba; del primer al último punto). Cada una se prueba
## también reflejada (lado contrario), salvo las simétricas.
const TEMPLATES := {
	# Curva lateral que sube y baja sin cerrarse (arco plano hacia un lado)
	"aerial": [[-1.0, 0.0], [-0.85, 0.24], [-0.6, 0.42], [-0.3, 0.52], [0.0, 0.55], [0.3, 0.52], [0.6, 0.42], [0.85, 0.24], [1.0, 0.0]],
	# Sube hacia delante, cae por delante y termina con un pequeño retroceso (gancho)
	"webster": [[0.0, -1.0], [0.0, -0.3], [0.03, 0.35], [0.15, 0.78], [0.35, 0.95], [0.55, 0.82], [0.66, 0.45], [0.6, 0.12], [0.4, 0.02]],
	# U invertida: empieza abajo, sube, pasa por encima y baja al otro lado
	"vault": [[-0.55, -1.0], [-0.55, -0.2], [-0.5, 0.45], [-0.32, 0.85], [0.0, 1.0], [0.32, 0.85], [0.5, 0.45], [0.55, -0.2], [0.55, -1.0]],
	# Dos arcos seguidos (manos y luego piernas)
	# Monkey: una M en punta (sube, baja, sube, baja)
	"kong": [[-1.0, -1.0], [-0.5, 1.0], [0.0, -0.3], [0.5, 1.0], [1.0, -1.0]],
	# Variantes de la M (cuentan como kong): letra M con los lados rectos y M con el valle hondo
	"kong_v": [[-0.7, -1.0], [-0.7, 1.0], [0.0, -0.45], [0.7, 1.0], [0.7, -1.0]],
	"kong_d": [[-0.8, -1.0], [-0.4, 1.0], [0.0, -0.9], [0.4, 1.0], [0.8, -1.0]],
	# Doble monkey: tres picos
	"double_kong": [[-1.0, -1.0], [-0.67, 1.0], [-0.33, -0.3], [0.0, 1.0], [0.33, -0.3], [0.67, 1.0], [1.0, -1.0]],
	"double_kong_d": [[-0.9, -1.0], [-0.6, 1.0], [-0.3, -0.9], [0.0, 1.0], [0.3, -0.9], [0.6, 1.0], [0.9, -1.0]],
	# Kash vault: V que sube al final (como ✓)
	"kash": [[-0.55, 0.6], [0.0, -1.0], [0.65, 1.0]],
	# Thief vault: V y otra bajada (baja, sube, baja)
	"thief": [[-0.95, 0.6], [-0.45, -0.8], [0.1, 1.0], [0.8, -0.85]],
	# Turn vault: el reverso al revés, de arriba abajo rodeando por un lado
	"turn": [[0.0, 1.0], [0.45, 0.6], [0.62, 0.15], [0.6, -0.3], [0.4, -0.78], [0.0, -1.0]],
	# Diagonal hacia arriba que termina curvándose hacia delante
	"wall_run": [[-0.85, -1.0], [-0.45, -0.6], [-0.05, -0.2], [0.22, 0.1], [0.4, 0.42], [0.46, 0.72], [0.4, 0.98]],
	# Línea hacia arriba y semicírculo de vuelta (horquilla estrecha)
	"wall_flip": [[0.0, -1.0], [0.0, -0.1], [0.0, 0.55], [0.07, 0.86], [0.25, 1.0], [0.43, 0.86], [0.5, 0.55], [0.5, 0.05], [0.5, -0.45]],
	# Zigzag ascendente de tres tramos
	"climb": [[0.0, -1.0], [0.7, -0.33], [0.0, 0.33], [0.7, 1.0]],
	# Dos trazos ascendentes en zigzag
	"wall_climb": [[0.0, -1.0], [0.75, 0.0], [0.0, 1.0]],
	# Dos diagonales que convergen abajo (V) y una pequeña curva hacia dentro al final
	"cat_leap": [[-0.6, 0.8], [-0.3, 0.1], [0.0, -0.6], [0.3, 0.1], [0.6, 0.8], [0.56, 0.97], [0.44, 1.0]],
	# J ascendente: gancho abajo y subida recta (y mantener el dedo al final)
	"ledge_grab": [[-0.5, -0.45], [-0.44, -0.8], [-0.22, -1.0], [0.05, -0.97], [0.2, -0.75], [0.25, -0.35], [0.25, 0.3], [0.25, 1.0]],
	# Pasavallas (speed vault): sube y pasa de lado (Γ)
	"speed": [[0.0, -1.0], [0.0, -0.2], [0.0, 0.45], [0.08, 0.8], [0.35, 0.95], [0.7, 0.97], [1.0, 0.97]],
	# Reverso (reverse vault): de abajo arriba rodeando por un lado, la media vuelta
	"reverse": [[0.0, -1.0], [0.4, -0.78], [0.6, -0.3], [0.62, 0.15], [0.45, 0.6], [0.0, 1.0]],
	# Curva hacia abajo y hacia delante (la voltereta)
	"roll": [[0.0, 1.0], [0.35, 0.78], [0.55, 0.35], [0.58, -0.1], [0.42, -0.6], [0.0, -1.0]],
}
const SYMMETRIC := ["vault", "kong", "climb", "wall_climb"]

static var _cache := {}

# --- Utilidades geométricas -----------------------------------------------------------------

## Puntos de pantalla (y abajo, píxeles) → unidades del joystick (y arriba), origen en el inicio.
static func to_units(screen: PackedVector2Array, radius: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if screen.is_empty():
		return out
	var o := screen[0]
	var r := maxf(radius, 1.0)
	for p in screen:
		out.append(Vector2(p.x - o.x, o.y - p.y) / r)
	return out

static func path_length(pts: PackedVector2Array) -> float:
	var l := 0.0
	for i in range(1, pts.size()):
		l += pts[i - 1].distance_to(pts[i])
	return l

## Remuestreo a n puntos equidistantes a lo largo del trazo.
static func resample(pts: PackedVector2Array, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pts.is_empty():
		return out
	var total := path_length(pts)
	if pts.size() < 2 or total < 1e-6:
		for i in n:
			out.append(pts[0])
		return out
	var interval := total / float(n - 1)
	var src := pts.duplicate()
	out.append(src[0])
	var acc := 0.0
	var i := 1
	while i < src.size() and out.size() < n:
		var a := src[i - 1]
		var b := src[i]
		var d := a.distance_to(b)
		if d > 0.0 and acc + d >= interval:
			var q := a + (b - a) * ((interval - acc) / d)
			out.append(q)
			src.insert(i, q)
			acc = 0.0
		else:
			acc += d
		i += 1
	while out.size() < n:
		out.append(pts[pts.size() - 1])
	return out

## Giro total con signo (radianes; antihorario positivo) de un trazo remuestreado.
static func total_turning(rs: PackedVector2Array) -> float:
	var t := 0.0
	var prev := INF
	for i in range(1, rs.size()):
		var d := rs[i] - rs[i - 1]
		if d.length() < 1e-5:
			continue
		var h := d.angle()
		if prev != INF:
			t += wrapf(h - prev, -PI, PI)
		prev = h
	return t

## Centra en el centroide y escala uniformemente (conserva la proporción alto/ancho).
static func normalize(rs: PackedVector2Array) -> PackedVector2Array:
	var c := Vector2.ZERO
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in rs:
		c += p
		lo = lo.min(p)
		hi = hi.max(p)
	c /= maxf(rs.size(), 1)
	var s := maxf(maxf(hi.x - lo.x, hi.y - lo.y), 1e-5)
	var out := PackedVector2Array()
	for p in rs:
		out.append((p - c) / s)
	return out

## Suma de los giros sin signo (cuánto "zigzaguea" o se curva el trazo, en radianes).
static func abs_turning(rs: PackedVector2Array) -> float:
	var t := 0.0
	var prev := INF
	for i in range(1, rs.size()):
		var d := rs[i] - rs[i - 1]
		if d.length() < 1e-5:
			continue
		var h := d.angle()
		if prev != INF:
			t += absf(wrapf(h - prev, -PI, PI))
		prev = h
	return t

## Media móvil (el primer y último punto se conservan).
static func smooth(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() < 5:
		return pts
	var out := PackedVector2Array([pts[0]])
	for i in range(1, pts.size() - 1):
		var a := maxi(i - 1, 0)
		var b := mini(i + 1, pts.size() - 1)
		var c := Vector2.ZERO
		for k in range(a, b + 1):
			c += pts[k]
		out.append(c / float(b - a + 1))
	out.append(pts[pts.size() - 1])
	return out

static func _template_abs_turn(id: String) -> float:
	var key := id + "_abs"
	if not _cache.has(key):
		var raw := PackedVector2Array()
		for p in TEMPLATES[id]:
			raw.append(Vector2(float(p[0]), float(p[1])))
		_cache[key] = abs_turning(resample(raw, 20))
	return _cache[key]

static func _seg_cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var r := b - a
	var s := d - c
	var den := r.cross(s)
	if absf(den) < 1e-9:
		return false
	var t := (c - a).cross(s) / den
	var u := (c - a).cross(r) / den
	return t > 0.0 and t < 1.0 and u > 0.0 and u < 1.0

## Bucles del final del trazo (cork, aerial twist, gainer...): se recorre el trazo desde el final
## sumando el giro; cada ~330° en el mismo sentido es un círculo. Así un arco que gira en el mismo
## sentido que el círculo no se cuenta como otro círculo, y círculos imperfectos o sin cerrar del
## todo valen. Devuelve {"count", "start" (índice donde empiezan los bucles), "dir" (+1 horario)}.
static func loops(rs: PackedVector2Array) -> Dictionary:
	var acc := 0.0
	var prev := INF
	var count := 0
	var start := rs.size()
	var step := deg_to_rad(LOOP_ANGLE + 10.0)
	var k := rs.size() - 1
	var heads := []                       # [índice, giro acumulado] desde el final
	while k > 0:
		var d := rs[k] - rs[k - 1]
		if d.length() > 1e-5:
			var h := d.angle()
			if prev != INF:
				var dt := wrapf(prev - h, -PI, PI)
				if count > 0 and signf(dt) != signf(acc) and absf(dt) > deg_to_rad(100.0):
					break
				acc += dt
			prev = h
		heads.append([k, absf(acc)])
		if count < 4 and absf(acc) >= step * float(count + 1) - deg_to_rad(20.0):
			count += 1
		k -= 1
	var dir := 0
	if count > 0:
		dir = -1 if acc > 0.0 else 1
		# Los bucles empiezan donde se completan sus vueltas enteras (el trazo de antes es la entrada)
		var top := 0.0
		for hd in heads:
			top = maxf(top, float(hd[1]))
		var want := minf(TAU * float(count) - deg_to_rad(20.0), top - deg_to_rad(5.0))
		start = int(heads[heads.size() - 1][0])
		for hd in heads:
			if float(hd[1]) >= want:
				start = int(hd[0])
				break
	return {"count": count, "start": start, "dir": dir}

static func _prepared(id: String, mirrored: bool) -> PackedVector2Array:
	var key := id + ("_m" if mirrored else "")
	if _cache.has(key):
		return _cache[key]
	var raw := PackedVector2Array()
	for p in TEMPLATES[id]:
		raw.append(Vector2(-float(p[0]) if mirrored else float(p[0]), float(p[1])))
	var prep := normalize(resample(raw, N))
	_cache[key] = prep
	return prep

## Parecido 0..1 entre un trazo normalizado y una plantilla.
static func similarity(norm: PackedVector2Array, id: String, mirrored := false) -> float:
	var tp := _prepared(id, mirrored)
	var d := 0.0
	for i in N:
		d += norm[i].distance_to(tp[i])
	d /= float(N)
	return clampf(1.0 - d / 0.3, 0.0, 1.0)

## 8 direcciones (como TouchControls.sector_of): 2 ↑ · 1 ↗ · 0 → · -1 ↘ · -2 ↓ · -3 ↙ · 4 ← · 3 ↖
static func sector8(v: Vector2) -> int:
	var ang := rad_to_deg(v.angle())
	var card := roundf(ang / 90.0) * 90.0
	var sec: int
	if absf(ang - card) <= CARDINAL_HALF:
		sec = int(card / 45.0)
	else:
		sec = int(floorf(ang / 90.0) * 2.0) + 1
	return 4 if sec == -4 else sec

static func _cardinal(v: Vector2) -> int:
	var ang := rad_to_deg(v.angle())
	var card := roundf(ang / 90.0) * 90.0
	if absf(ang - card) > CARDINAL_HALF:
		return 99
	var sec := int(card / 45.0)
	return 4 if sec == -4 else sec

# --- Joystick dorado (mortales y parkour) -------------------------------------------------

## `pts` en píxeles de pantalla, `radius` = radio del joystick. Opciones:
##   ctx: {"obstacle", "wall_front", "wall_any", "ledge", "roll"} → bool (vacío = no se comprueba)
##   dirs8: las líneas diagonales también son simples (páginas de habilidades de SALTO)
## Resultado: {"id": "tap" | "" (nada) | movimiento, "kind": "simple"/"pattern"/"parkour",
##   "sector", "side" (+1 derecha / -1 izquierda), "loops", "twist" (+1 horario), "score",
##   "ok" (el contexto lo permite), "reason", "name", "len"}
static func recognize_salto(screen: PackedVector2Array, radius: float, opts := {}) -> Dictionary:
	var pts := smooth(to_units(screen, radius))
	if pts.size() < 2 or path_length(pts) < TAP_MAX:
		return {"id": "tap", "kind": "tap", "ok": true}
	var chord := pts[pts.size() - 1] - pts[0]
	var rs := resample(pts, N)
	# Rasgos sobre una versión gruesa del trazo (el temblor del dedo no cuenta como giro)
	var coarse := resample(pts, 16)
	var turn := total_turning(coarse)
	var straight := chord.length() / maxf(path_length(coarse), 1e-5)
	var abs_turn := abs_turning(resample(pts, 20))
	# 2. Línea recta
	if straight >= SIMPLE_STRAIGHT and absf(turn) < deg_to_rad(SIMPLE_TURN) and chord.length() >= SIMPLE_MIN:
		var sec := _cardinal(chord)
		if sec == 99 and opts.get("dirs8", false):
			sec = sector8(chord)
		if sec != 99:
			var sid := "front" if sec == 2 else ("back" if sec == -2 else ("side" if sec in [0, 4] else "dir"))
			if opts.get("prefer_templates", false) and chord.length() >= PRECISION_MAX_LEN:
				# Modo gestos: las líneas largas no hacen mortales (van en los botones); si el
				# trazo se parece mucho a un movimiento de parkour (wall run curvado), gana ese
				var tm := _match_templates(rs, abs_turn, opts, ["roll", "cat_leap"], [])
				if tm.get("ok", false) and float(tm.get("score", 0.0)) >= MATCH_MIN:
					return tm
			return _result(sid, "simple", 1.0, {"sector": sec, "side": 1 if chord.x >= 0.0 else -1, "len": chord.length()}, opts)
		if chord.y > 0.0 and straight >= 0.95 and absf(turn) < deg_to_rad(22.0):
			# Diagonal recta hacia arriba = CHUTADA (mortal chutado: patada como a un balón
			# y después un backflip normal, sin tirabuzón). Con un círculo al final sería un cork.
			return _result("chutada", "pattern", 1.0, {"side": 1 if chord.x >= 0.0 else -1, "len": chord.length()}, opts)
	# 3. Un círculo solo (todo el trazo redondo) = CAT LEAP
	var rs64 := resample(pts, 64)
	var sm := resample(smooth(smooth(pts)), 32)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in sm:
		lo = lo.min(q); hi = hi.max(q)
	var closes := sm[0].distance_to(sm[sm.size() - 1]) < 0.45 * maxf(hi.x - lo.x, hi.y - lo.y)
	if closes and absf(total_turning(sm)) >= deg_to_rad(290.0) and _roundness(sm) < 0.28:
		return _result("cat_leap", "parkour", 1.0, {"side": 1}, opts)
	# 4. Bucles (el dedo se cruza o cierra un círculo al final)
	var lp := loops(rs64)
	if int(lp.count) > 0:
		var pre := rs64.slice(0, maxi(int(lp.start), 1) + 1)
		var r := _loop_move(pre, int(lp.count), int(lp.dir))
		if not r.is_empty():
			return _result(String(r.id), "pattern", 1.0, r, opts)
		return {"id": "", "kind": "none", "ok": false, "reason": "círculos: van en el joystick morado (tirabuzones)"}
	# 4. Plantillas
	# Rodar ya no es un gesto (es automático al caer desde alto) y su forma es la del turn vault;
	# el cat leap es un círculo solo (ver arriba)
	return _match_templates(rs, abs_turn, opts, ["roll", "cat_leap"], [])

## Variación relativa de la distancia al centro (0 = círculo perfecto).
static func _roundness(pts: PackedVector2Array) -> float:
	if pts.size() < 6:
		return 1.0
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var m := 0.0
	for p in pts:
		m += p.distance_to(c)
	m /= float(pts.size())
	if m < 1e-4:
		return 1.0
	var v := 0.0
	for p in pts:
		v += pow(p.distance_to(c) - m, 2.0)
	return sqrt(v / float(pts.size())) / m

## Compara el trazo con las plantillas (sin las de `skip`; si `only` no está vacío, solo esas).
static func _match_templates(rs: PackedVector2Array, abs_turn: float, opts: Dictionary, skip: Array, only: Array) -> Dictionary:
	var norm := normalize(rs)
	var cands := []
	for id in TEMPLATES.keys():
		if id in skip or (not only.is_empty() and not (id in only)):
			continue
		var best := similarity(norm, id, false)
		var side := 1
		var m := similarity(norm, id, true)        # reflejada (en las simétricas: dibujada al revés)
		if m > best:
			best = m
			side = -1
		# Esquinas y curvas: un zigzag de tres tramos no es uno de dos, ni un arco doble uno simple
		best -= 0.22 * minf(absf(abs_turn - _template_abs_turn(id)) / PI, 1.5)
		cands.append([best, id, side])
	cands.sort_custom(func(a, b): return a[0] > b[0])
	var ctx: Dictionary = opts.get("ctx", {})
	var first_fail := {}
	# Trazo algo torcido pero sin duda posible (la mejor forma le saca ventaja clara a cualquier
	# otro movimiento): también vale, aunque no llegue al parecido mínimo
	var min_ok := MATCH_MIN
	if not cands.is_empty() and float(cands[0][0]) >= CLEAR_MIN and float(cands[0][0]) < MATCH_MIN:
		var top_id := String(TEMPLATE_ALIAS.get(cands[0][1], cands[0][1]))
		if not (top_id in CLEAR_IDS):
			top_id = ""                              # solo formas muy características (la M del kong)
		var second := 0.0
		for c2 in cands.slice(1):
			if String(TEMPLATE_ALIAS.get(c2[1], c2[1])) != top_id:
				second = float(c2[0])
				break
		if top_id != "" and float(cands[0][0]) - second >= CLEAR_MARGIN:
			min_ok = float(cands[0][0])
	for c in cands:
		if float(c[0]) < min_ok:
			break
		var cid := String(TEMPLATE_ALIAS.get(c[1], c[1]))
		var res := _result(cid, "parkour" if NEEDS.has(cid) else "pattern", float(c[0]), {"side": int(c[2])}, opts)
		if res.ok:
			return res
		if first_fail.is_empty():
			first_fail = res
	if not first_fail.is_empty():
		return first_fail
	return {"id": "", "kind": "none", "ok": false, "reason": "patrón no reconocido", "best": cands[0] if not cands.is_empty() else []}

## Trazo antes de los bucles: diagonal hacia arriba = cork · arco lateral = aerial twist ·
## hacia abajo (atrás) = gainer.
static func _loop_move(pre: PackedVector2Array, count: int, twist: int) -> Dictionary:
	var plen := path_length(pre)
	if pre.size() < 2 or plen < 0.3:
		return {}
	var ch := pre[pre.size() - 1] - pre[0]
	if ch.length() < 0.2:
		return {}
	var ang := rad_to_deg(ch.angle())
	var straight := ch.length() / maxf(plen, 1e-5)
	var top := -INF
	for p in pre:
		top = maxf(top, p.y)
	var bulge := top - maxf(pre[0].y, pre[pre.size() - 1].y)
	var side := 1 if ch.x >= 0.0 else -1
	var pturn := absf(total_turning(resample(pre, 16)))
	# Entrada curva (arco lateral) = aerial twist · entrada recta en diagonal hacia arriba = cork
	if pturn >= deg_to_rad(75.0) and bulge >= 0.08 * ch.length():
		return {"id": "aerial_twist", "side": side, "loops": count, "twist": twist}
	if absf(ang - 90.0) < 20.0 and straight >= 0.7:
		# Línea hacia arriba y un círculo: manos a la pared y mortal atrás (palm flip)
		return {"id": "palm", "side": side, "loops": count, "twist": twist}
	if ang >= 18.0 and ang <= 162.0 and straight >= 0.7 and absf(ang - 90.0) >= 12.0:
		return {"id": "cork720" if count >= 2 else "cork", "side": side, "loops": count, "twist": twist}
	if (absf(ang) <= 35.0 or absf(ang) >= 145.0) and bulge >= 0.12 * ch.length():
		return {"id": "aerial_twist", "side": side, "loops": count, "twist": twist}
	if ang <= -25.0 and ang >= -155.0:
		return {"id": "gainer", "side": side, "loops": count, "twist": twist}
	return {}

static func _result(id: String, kind: String, score: float, extra: Dictionary, opts: Dictionary) -> Dictionary:
	var r := {"id": id, "kind": kind, "score": score, "ok": true, "reason": "", "name": NAMES.get(id, id.to_upper()),
		"side": 1, "loops": 0, "twist": 0, "sector": 99, "len": 0.0}
	r.merge(extra, true)
	var ctx: Dictionary = opts.get("ctx", {})
	if NEEDS.has(id) and not ctx.is_empty() and not opts.get("training", false):
		var need: String = NEEDS[id]
		if not ctx.get(need, false):
			r.ok = false
			r.reason = NEED_TEXT.get(need, "no se puede ahora")
	return r

# --- Joystick morado (tirabuzones) --------------------------------------------------------

## Cuenta círculos mientras se dibujan: cada vuelta completa devuelve +1 (horario = tirabuzón
## derecho) o -1 (antihorario = izquierdo). Reconoce círculos imperfectos; los temblores y los
## trazos cortos no suman.
class LoopCounter:
	var radius := 100.0
	var acc := 0.0
	var heading := INF
	var last := Vector2.INF
	var since := 0.0
	var events: Array[int] = []
	var points := PackedVector2Array()

	func _init(r := 100.0) -> void:
		radius = maxf(r, 1.0)

	func feed(p: Vector2) -> int:
		points.append(p)
		if last == Vector2.INF:
			last = p
			return 0
		var d := p - last
		if d.length() < 0.05 * radius:
			return 0
		var h := atan2(-d.y, d.x)
		if heading != INF:
			var dh := wrapf(h - heading, -PI, PI)
			if absf(dh) > 2.5:
				acc = 0.0                    # vuelta atrás brusca (cambio de sentido): empieza otro círculo
				since = 0.0
			else:
				acc += dh
		heading = h
		since += d.length() / radius
		last = p
		if absf(acc) >= deg_to_rad(GestureRecognizer.LOOP_ANGLE) and since >= GestureRecognizer.LOOP_MIN_LEN:
			var s := signf(acc)
			acc -= s * TAU
			since = 0.0
			var ev := -1 if s > 0.0 else 1
			events.append(ev)
			return ev
		return 0

## Nombre de una secuencia de círculos del joystick morado.
static func twist_name(events: Array) -> String:
	if events.is_empty():
		return ""
	var mixed := false
	for e in events:
		if int(e) != int(events[0]):
			mixed = true
	if mixed:
		return "TIRABUZÓN COMBINADO"
	var side := "DERECHO" if int(events[0]) > 0 else "IZQUIERDO"
	match events.size():
		1: return "TIRABUZÓN " + side
		2: return "DOBLE TIRABUZÓN " + side
		_: return "TRIPLE TIRABUZÓN " + side

## Puntos de ejemplo de cada gesto (para la práctica y la ayuda), en unidades (y arriba).
static func preview_points(id: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	match id:
		"front": out = PackedVector2Array([Vector2(0, -0.8), Vector2(0, 0.8)])
		"back": out = PackedVector2Array([Vector2(0, 0.8), Vector2(0, -0.8)])
		"side_l": out = PackedVector2Array([Vector2(0.8, 0), Vector2(-0.8, 0)])
		"side_r": out = PackedVector2Array([Vector2(-0.8, 0), Vector2(0.8, 0)])
		"precision": out = PackedVector2Array([Vector2(0, -0.5), Vector2(0, 0.2)])
		"palm":
			out = PackedVector2Array([Vector2(0, -0.85), Vector2(0, 0.25)])
			_add_circles(out, Vector2(0, 0.25), 0.3, 1, -1)
		"chutada": out = PackedVector2Array([Vector2(-0.6, -0.65), Vector2(0.6, 0.65)])
		"cat_leap":
			out = PackedVector2Array([Vector2(0, -0.45)])
			_add_circles(out, Vector2(0, -0.45), 0.45, 1, 1)
		"cork", "cork720":
			out = PackedVector2Array([Vector2(-0.7, -0.8), Vector2(0.15, 0.2)])
			_add_circles(out, Vector2(0.15, 0.2), 0.3, 2 if id == "cork720" else 1, 1)
		"aerial_twist":
			for i in 9:
				var x := lerpf(-0.9, 0.6, i / 8.0)
				out.append(Vector2(x, 0.5 * sin(PI * (x + 0.9) / 1.5)))
			_add_circles(out, out[out.size() - 1], 0.25, 1, 1)
		"gainer":
			out = PackedVector2Array([Vector2(0, 0.8), Vector2(0.05, 0.0)])
			_add_circles(out, Vector2(0.05, 0.0), 0.4, 1, -1)
		"twist_r", "twist_l", "twist_2", "twist_3", "twist_combo":
			var n := 1
			if id == "twist_2": n = 2
			elif id == "twist_3": n = 3
			var d := -1 if id == "twist_l" else 1
			out.append(Vector2(0, 0.6))
			_add_circles(out, Vector2(0, 0.6), 0.6 - 0.1 * (n - 1), n, d)
			if id == "twist_combo":
				_add_circles(out, out[out.size() - 1], 0.4, 1, -1)
		_:
			if TEMPLATES.has(id):
				for p in TEMPLATES[id]:
					out.append(Vector2(float(p[0]), float(p[1])) * 0.85)
	return out

## Añade n círculos que empiezan y acaban en `from` (d = +1 horario), tangentes al trazo anterior.
static func _add_circles(out: PackedVector2Array, from: Vector2, r: float, n: int, d: int) -> void:
	var h := Vector2.RIGHT
	if out.size() >= 2:
		h = (out[out.size() - 1] - out[out.size() - 2]).normalized()
	var perp := h.rotated(-PI * 0.5 * float(d))           # el centro queda hacia donde gira
	var c := from + perp * r
	var a0 := (from - c).angle()
	for k in n:
		var rk := r * (1.0 - 0.12 * k)
		for i in range(1, 25):
			var a := a0 - float(d) * TAU * i / 24.0
			out.append(c + Vector2(cos(a), sin(a)) * rk)

# --- Joystick morado en el suelo (habilidades y entradas de potencia) -----------------------

const GIRO_NAMES := {
	"rondada": "RONDADA", "flicflac": "FLIC-FLAC", "rueda": "RUEDA", "td_raiz": "TOUCHDOWN RAIZ",
	"macaco": "MACACO", "scoot": "SCOOT", "scoot_power": "SCOOT FUERTE",
	"twist": "GIRO 360", "dive_kong": "DIVE KONG",
}
## Plantillas del morado (x derecha, y arriba). Se prueban también reflejadas (otro lado).
const GIRO_TEMPLATES := {
	# Arco por arriba = macaco
	"macaco": [[-0.8, -0.3], [-0.7, 0.15], [-0.4, 0.5], [0.0, 0.6], [0.4, 0.5], [0.7, 0.15], [0.8, -0.3]],
	# Ida y vuelta lateral (<): cambio de dirección = scoot
	"scoot": [[-0.8, 0.15], [-0.25, 0.08], [0.3, 0.0], [-0.25, -0.08], [-0.8, -0.15]],
	# Hoja abajo a la izquierda y barrido largo hacia arriba a la derecha = scoot fuerte
	"scoot_power": [[-0.1, -0.55], [-0.5, -0.72], [-0.85, -0.85], [-0.45, -0.97], [-0.05, -0.85], [0.28, -0.52],
		[0.47, -0.05], [0.53, 0.45], [0.5, 0.9]],
}

## Trazo del joystick morado soltado en el suelo. Devuelve {"id", "side" (+1 derecha), "loops",
## "dir" (+1 horario), "sector", "name"} o {"id": ""} si no es nada.
static func recognize_giro(screen: PackedVector2Array, radius: float) -> Dictionary:
	var pts := smooth(to_units(screen, radius))
	if pts.size() < 2 or path_length(pts) < TAP_MAX:
		return {"id": ""}
	var rs := resample(pts, 64)
	var loop := _loop_span(rs)
	if not loop.is_empty():
		var dir := int(loop.dir)
		return _giro_result("twist", dir, {"loops": int(loop.count), "dir": dir})
	var chord := pts[pts.size() - 1] - pts[0]
	var coarse := resample(pts, 16)
	var straight := chord.length() / maxf(path_length(coarse), 1e-5)
	if straight >= SIMPLE_STRAIGHT and absf(total_turning(coarse)) < deg_to_rad(SIMPLE_TURN) and chord.length() >= SIMPLE_MIN:
		var sec := sector8(chord)
		var side := 1 if chord.x >= 0.0 else -1
		match sec:
			2: return _giro_result("rondada", side, {"sector": sec})
			-2: return _giro_result("flicflac", side, {"sector": sec})
			0, 4: return _giro_result("rueda", side, {"sector": sec})
			1, 3: return _giro_result("dive_kong", side, {"sector": sec})    # diagonal arriba = Dive Kong
			_: return _giro_result("td_raiz", side, {"sector": sec})
	var norm := normalize(resample(pts, N))
	var abs_turn := abs_turning(resample(pts, 20))
	var best := ["", 0.0, 1]
	for id in GIRO_TEMPLATES.keys():
		for m in [false, true]:
			var sc := _sim_giro(norm, id, m) - 0.22 * minf(absf(abs_turn - _giro_abs_turn(id)) / PI, 1.5)
			if sc > float(best[1]):
				best = [id, sc, -1 if m else 1]
	if float(best[1]) >= MATCH_MIN:
		var gid2: String = best[0]
		var side2: int = best[2]
		if gid2 == "macaco":
			side2 = 1 if chord.x >= 0.0 else -1          # sentido del arco = lado del giro
		return _giro_result(gid2, side2, {"score": best[1]})
	return {"id": "", "reason": "gesto no reconocido"}

static func _giro_result(id: String, side: int, extra: Dictionary) -> Dictionary:
	var r := {"id": id, "side": side, "loops": 0, "dir": side, "sector": 99, "name": GIRO_NAMES.get(id, id.to_upper())}
	r.merge(extra, true)
	if id == "twist":
		r.name = "GIRO 360" if int(r.loops) <= 1 else "GIRO %d VUELTAS" % int(r.loops)
	return r

## Tramo con un círculo completo (giro acumulado ≥ ~330°) en cualquier parte del trazo.
static func _loop_span(rs: PackedVector2Array, need_deg := -1.0) -> Dictionary:
	var heads := [0.0]
	var prev := INF
	var acc := 0.0
	for i in range(1, rs.size()):
		var d := rs[i] - rs[i - 1]
		if d.length() > 1e-5:
			var h := d.angle()
			if prev != INF:
				var dt := wrapf(h - prev, -PI, PI)
				if absf(dt) > 2.5:
					dt = 0.0                 # pico (vuelta atrás) no cuenta como giro del círculo
				acc += dt
			prev = h
		heads.append(acc)
	var need := deg_to_rad(LOOP_ANGLE + 10.0 if need_deg < 0.0 else need_deg)
	# El círculo es la ventana MÁS CORTA que gira una vuelta entera (así la hoja del scoot, que
	# también gira, no se confunde con el principio del círculo)
	var win := []
	for i1 in range(1, heads.size()):
		for i0 in range(i1 - 1, -1, -1):
			if absf(float(heads[i1]) - float(heads[i0])) >= need:
				if win.is_empty() or i1 - i0 < int(win[1]) - int(win[0]):
					win = [i0, i1]
				break
	if win.is_empty():
		return {}
	var i0b: int = win[0]
	var e: int = win[1]
	var sgn := signf(float(heads[e]) - float(heads[i0b]))
	while e + 1 < heads.size() and (float(heads[e + 1]) - float(heads[e])) * sgn > deg_to_rad(4.0):
		e += 1
	var count := maxi(1, int(absf(float(heads[e]) - float(heads[i0b])) / TAU + 0.12))
	return {"i0": i0b, "i1": e, "count": count, "dir": -1 if sgn > 0.0 else 1}

static func _sim_giro(norm: PackedVector2Array, id: String, mirrored: bool) -> float:
	var key := "g_" + id + ("_m" if mirrored else "")
	if not _cache.has(key):
		var raw := PackedVector2Array()
		for p in GIRO_TEMPLATES[id]:
			raw.append(Vector2(-float(p[0]) if mirrored else float(p[0]), float(p[1])))
		_cache[key] = normalize(resample(raw, N))
	var tp: PackedVector2Array = _cache[key]
	var d := 0.0
	for i in N:
		d += norm[i].distance_to(tp[i])
	return clampf(1.0 - d / float(N) / 0.3, 0.0, 1.0)

static func _giro_abs_turn(id: String) -> float:
	var key := "g_" + id + "_abs"
	if not _cache.has(key):
		var raw := PackedVector2Array()
		for p in GIRO_TEMPLATES[id]:
			raw.append(Vector2(float(p[0]), float(p[1])))
		_cache[key] = abs_turning(resample(raw, 20))
	return _cache[key]

## Trazos de ejemplo del morado (práctica y pruebas), en unidades (y arriba).
static func giro_preview(id: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	match id:
		"g_rondada": out = PackedVector2Array([Vector2(0, -0.7), Vector2(0, 0.7)])
		"g_flicflac": out = PackedVector2Array([Vector2(0, 0.7), Vector2(0, -0.7)])
		"g_rueda": out = PackedVector2Array([Vector2(-0.7, 0), Vector2(0.7, 0)])
		"g_td_raiz": out = PackedVector2Array([Vector2(-0.55, 0.55), Vector2(0.55, -0.55)])
		_:
			var k := id.trim_prefix("g_")
			if GIRO_TEMPLATES.has(k):
				for p in GIRO_TEMPLATES[k]:
					out.append(Vector2(float(p[0]), float(p[1])))
	return out
