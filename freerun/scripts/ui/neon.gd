class_name Neon
extends RefCounted
## Estilo visual "neón" de la interfaz táctil, dibujado por código (sin imágenes):
## botones con halo de color, cuerpo oscuro con brillo, aro luminoso e icono vectorial.

const NAVY := Color(0.035, 0.05, 0.12)
const GOLD := Color(1.0, 0.78, 0.25)
const BLUE := Color(0.25, 0.65, 1.0)
const PURPLE := Color(0.68, 0.38, 1.0)
const CYAN := Color(0.25, 0.92, 0.88)
const ORANGE := Color(1.0, 0.6, 0.22)
const GREEN := Color(0.35, 0.95, 0.5)

## Botón redondo con halo. `pressed` lo ilumina entero.
static func button(ci: CanvasItem, c: Vector2, r: float, col: Color, pressed: bool, alpha := 1.0) -> void:
	for i in 4:
		ci.draw_arc(c, r + (i + 1) * r * 0.06, 0, TAU, 48, Color(col, 0.13 * (4 - i) * alpha * (1.6 if pressed else 1.0)), r * 0.07, true)
	ci.draw_circle(c, r, Color(NAVY, 0.86 * alpha))
	ci.draw_circle(c + Vector2(0, -r * 0.1), r * 0.84, Color(col.r * 0.22 + 0.04, col.g * 0.22 + 0.05, col.b * 0.22 + 0.1, 0.7 * alpha))
	if pressed:
		ci.draw_circle(c, r, Color(col, 0.5 * alpha))
	ci.draw_arc(c, r, 0, TAU, 56, Color(col, alpha), maxf(2.5, r * 0.085), true)
	ci.draw_arc(c, r * 0.83, PI * 1.15, PI * 1.85, 20, Color(1, 1, 1, 0.22 * alpha), maxf(1.5, r * 0.04), true)

## Flecha curva (arco con punta). ccw = sentido antihorario en pantalla.
static func _curved_arrow(ci: CanvasItem, c: Vector2, rad: float, a0: float, a1: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var a := lerpf(a0, a1, i / 16.0)
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	ci.draw_polyline(pts, col, w, true)
	var tip: Vector2 = pts[pts.size() - 1]
	var dirv: Vector2 = (tip - pts[pts.size() - 3]).normalized()
	var nrm := Vector2(-dirv.y, dirv.x)
	ci.draw_colored_polygon(PackedVector2Array([tip + dirv * w * 1.6, tip - dirv * w * 0.6 + nrm * w * 1.5, tip - dirv * w * 0.6 - nrm * w * 1.5]), col)

static func _chevron(ci: CanvasItem, c: Vector2, s: float, dirv: Vector2, col: Color, w: float) -> void:
	var n := Vector2(-dirv.y, dirv.x)
	ci.draw_polyline(PackedVector2Array([c - dirv * s * 0.5 + n * s, c + dirv * s * 0.5, c - dirv * s * 0.5 - n * s]), col, w, true)

## Iconos vectoriales (s = semitamaño).
static func icon(ci: CanvasItem, name: String, c: Vector2, s: float, col: Color) -> void:
	var w := maxf(2.0, s * 0.2)
	match name:
		"jump":
			_chevron(ci, c + Vector2(0, s * 0.35), s * 0.9, Vector2.UP, col, w * 1.3)
			_chevron(ci, c - Vector2(0, s * 0.45), s * 0.9, Vector2.UP, col, w * 1.3)
		"back":
			_curved_arrow(ci, c, s * 0.8, deg_to_rad(40), deg_to_rad(320), col, w)
		"front":
			_curved_arrow(ci, c, s * 0.8, deg_to_rad(140), deg_to_rad(-140), col, w)
		"side_l", "side_r":
			var sg := -1.0 if name == "side_l" else 1.0
			_curved_arrow(ci, c + Vector2(0, s * 0.3), s * 0.85, deg_to_rad(90 + 70 * sg), deg_to_rad(90 - 110 * sg), col, w)
		"cork":
			var pts := PackedVector2Array()
			for i in 28:
				var t := i / 27.0
				var a := t * TAU * 1.3
				pts.append(c + Vector2(cos(a), sin(a)) * s * lerpf(0.25, 0.9, t))
			ci.draw_polyline(pts, col, w, true)
			ci.draw_circle(pts[pts.size() - 1], w * 1.1, col)
		"piru":
			_curved_arrow(ci, c, s * 0.8, deg_to_rad(40), deg_to_rad(320), col, w)
			ci.draw_line(c + Vector2(-s * 0.35, -s * 0.1), c + Vector2(s * 0.35, s * 0.25), col, w, true)
		"butterfly":
			ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(-s, -s * 0.7), c + Vector2(-s * 0.85, s * 0.55)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(s, -s * 0.7), c + Vector2(s * 0.85, s * 0.55)]), col)
			ci.draw_line(c + Vector2(0, -s * 0.5), c + Vector2(0, s * 0.6), Color(NAVY, 0.9), w * 0.8, true)
		"kick":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.25, -s), c + Vector2(-s * 0.55, s * 0.15), c + Vector2(-s * 0.05, s * 0.15),
				c + Vector2(-s * 0.3, s), c + Vector2(s * 0.55, -s * 0.2), c + Vector2(s * 0.05, -s * 0.2)]), col)
		"wheel":
			ci.draw_arc(c, s * 0.8, 0, TAU, 28, col, w, true)
			for i in 4:
				var a := i * PI * 0.25
				ci.draw_line(c - Vector2(cos(a), sin(a)) * s * 0.8, c + Vector2(cos(a), sin(a)) * s * 0.8, col, w * 0.6, true)
		"hand":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.05), Vector2(s * 0.9, s * 0.75)), col)
			for i in 4:
				var x := -s * 0.36 + i * s * 0.24
				ci.draw_line(c + Vector2(x, 0), c + Vector2(x, -s * (0.75 if i in [1, 2] else 0.6)), col, w * 0.9, true)
			ci.draw_line(c + Vector2(-s * 0.45, s * 0.3), c + Vector2(-s * 0.85, -s * 0.05), col, w * 0.9, true)
		"spin":
			_curved_arrow(ci, c, s * 0.75, deg_to_rad(200), deg_to_rad(520), col, w)
			ci.draw_circle(c, w * 0.9, col)
		"run":
			_chevron(ci, c + Vector2(-s * 0.35, 0), s * 0.8, Vector2.RIGHT, col, w * 1.2)
			_chevron(ci, c + Vector2(s * 0.35, 0), s * 0.8, Vector2.RIGHT, col, w * 1.2)
		"grab":
			ci.draw_arc(c + Vector2(0, s * 0.1), s * 0.6, deg_to_rad(200), deg_to_rad(340), 16, col, w, true)
			ci.draw_line(c + Vector2(-s * 0.56, -s * 0.1), c + Vector2(-s * 0.56, s * 0.7), col, w, true)
			ci.draw_line(c + Vector2(s * 0.56, -s * 0.1), c + Vector2(s * 0.56, s * 0.7), col, w, true)
			ci.draw_line(c + Vector2(-s, -s * 0.75), c + Vector2(s, -s * 0.75), col, w * 1.2, true)
		"vault":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, s * 0.15), Vector2(s * 1.1, s * 0.6)), col)
			_curved_arrow(ci, c + Vector2(0, s * 0.2), s * 0.85, deg_to_rad(200), deg_to_rad(340), col, w * 0.9)
		"roll":
			_curved_arrow(ci, c, s * 0.7, deg_to_rad(-60), deg_to_rad(240), col, w)
			ci.draw_line(c + Vector2(-s, s * 0.9), c + Vector2(s, s * 0.9), col, w * 0.8, true)
		"swap":
			ci.draw_line(c + Vector2(-s * 0.8, -s * 0.3), c + Vector2(s * 0.8, -s * 0.3), col, w * 1.2, true)
			_chevron(ci, c + Vector2(s * 0.6, -s * 0.3), s * 0.5, Vector2.RIGHT, col, w * 1.2)
			ci.draw_line(c + Vector2(-s * 0.8, s * 0.35), c + Vector2(s * 0.8, s * 0.35), col, w * 1.2, true)
			_chevron(ci, c + Vector2(-s * 0.6, s * 0.35), s * 0.5, Vector2.LEFT, col, w * 1.2)
		"list":
			for i in 3:
				var y := (i - 1) * s * 0.55
				ci.draw_circle(c + Vector2(-s * 0.7, y), w * 0.8, col)
				ci.draw_line(c + Vector2(-s * 0.35, y), c + Vector2(s * 0.8, y), col, w, true)
		"star":
			var st := PackedVector2Array()
			for i in 10:
				var a := -PI * 0.5 + i * PI / 5.0
				st.append(c + Vector2(cos(a), sin(a)) * s * (0.95 if i % 2 == 0 else 0.42))
			ci.draw_colored_polygon(st, col)
		"gear":
			ci.draw_arc(c, s * 0.55, 0, TAU, 24, col, w * 1.3, true)
			for i in 8:
				var a := i * TAU / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * s * 0.6, c + Vector2(cos(a), sin(a)) * s * 0.95, col, w * 1.4, true)
		"respawn":
			_curved_arrow(ci, c, s * 0.75, deg_to_rad(-30), deg_to_rad(270), col, w)
		"crown":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, s * 0.5), c + Vector2(-s, -s * 0.4), c + Vector2(-s * 0.5, s * 0.05),
				c + Vector2(0, -s * 0.7), c + Vector2(s * 0.5, s * 0.05), c + Vector2(s, -s * 0.4), c + Vector2(s, s * 0.5)]), col)

## Icono de un botón de la botonera según su tipo y valor.
static func icon_for(kind: String, value) -> String:
	match kind:
		"flip":
			match int(value):
				-2: return "back"
				2: return "front"
				4: return "side_l"
				0: return "side_r"
				3: return "butterfly"
		"cork": return "cork"
		"piru": return "piru"
		"kick": return "kick"
		"butterfly": return "butterfly"
		"change": return "swap"
		"vault": return "vault"
		"grab": return "grab"
		"action": return "roll"
		"skill":
			match String(value):
				"roundoff", "cartwheel": return "wheel"
				"hook": return "kick"
				"raiz", "td_raiz": return "spin"
				"scoot": return "run"
				_: return "hand"
	return "star"

## Color de la familia de un botón.
static func color_for(kind: String, value) -> Color:
	match kind:
		"flip", "piru": return PURPLE
		"cork", "butterfly": return CYAN
		"kick": return ORANGE
		"change": return GOLD
		"vault": return BLUE
		"grab": return PURPLE
		"action": return GREEN
		"skill":
			match String(value):
				"hook", "raiz", "td_raiz", "scoot": return GREEN
				_: return ORANGE
	return BLUE
