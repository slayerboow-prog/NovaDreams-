class_name TrickIndicator
extends Control
## Indicador de control corporal en el aire: nombre del truco en directo, vueltas,
## un dial con la orientación del cuerpo (zona verde = vertical para aterrizar)
## y la instrucción del momento (mantener para girar más / soltar para aterrizar).

var player: PlayerController
var _alpha := 0.0
var _last_name := ""
var _skill_alpha := 0.0
var _skill_text := ""
var _skill_phase := ""
var _skill_link := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(dt: float) -> void:
	_skill_alpha = move_toward(_skill_alpha, 1.0 if player != null and player.state == PlayerController.State.SKILL else 0.0, dt * 6.0)
	if player != null and player.state == PlayerController.State.SKILL:
		var smp := player.skill_sample()
		_skill_text = MoveNames.es(SkillLibrary.get_def(player.skill.id).name).to_upper()
		_skill_phase = String(smp.get("phase", ""))
		_skill_link = player.skill.get("linked", false)
	var show := player != null and player.state == PlayerController.State.AIR and player.tricks.active
	_alpha = move_toward(_alpha, 1.0 if show else 0.0, dt * (8.0 if show else 3.0))
	if show:
		_last_name = player.tricks.live_name()
	queue_redraw()

func _draw() -> void:
	if player == null:
		return
	if _skill_alpha > 0.01:
		# Habilidad de suelo: nombre, fase actual y aviso de la ventana de enlace
		var f := get_theme_default_font()
		var sx := size.x * 0.17
		_text(f, Vector2(sx, size.y * 0.2), _skill_text, 40, Color(1, 1, 1, _skill_alpha))
		_text(f, Vector2(sx, size.y * 0.2 + 40), _skill_phase, 22, Color(1, 0.85, 0.3, _skill_alpha))
		if _skill_link:
			_text(f, Vector2(sx, size.y * 0.2 + 74), "¡ENLAZA! rueda = mortal · joystick = siguiente", 20, Color(0.4, 1, 0.6, _skill_alpha))
	if _alpha <= 0.01:
		return
	var tr := player.tricks
	var font := get_theme_default_font()
	var cx := size.x * 0.17
	var top := size.y * 0.2
	var name := MoveNames.es(_last_name).to_upper()
	_text(font, Vector2(cx, top), name, 44, Color(1, 1, 1, _alpha))
	# Vueltas del eje principal
	var ax := tr.primary_axis()
	var ang: float = absf(tr.total.get(ax, 0.0))
	var turns := ang / TAU
	_text(font, Vector2(cx, top + 42), "%d°" % int(rad_to_deg(ang)), 24, Color(1, 0.85, 0.3, _alpha))
	# Dial
	var c := Vector2(cx, top + 120)
	var r := 46.0
	draw_circle(c, r + 6, Color(0, 0, 0, 0.35 * _alpha))
	draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.5 * _alpha), 3.0, true)
	var zone := deg_to_rad(lerpf(22.0, 60.0, Settings.assist_strength()))
	draw_arc(c, r, -PI * 0.5 - zone, -PI * 0.5 + zone, 16, Color(0.3, 1.0, 0.55, 0.9 * _alpha), 7.0, true)
	var up := tr.basis * Vector3.UP
	var a := 0.0
	match ax:
		"pitch": a = -tr.total.pitch
		"roll": a = tr.total.roll
		_: a = atan2(up.x, up.y)
	var needle := Vector2(sin(a), -cos(a)) * r
	var ok := tr.upright_error() < deg_to_rad(30.0)
	draw_line(c, c + needle, Color(0.3, 1, 0.55, _alpha) if ok else Color(1, 0.5, 0.3, _alpha), 5.0, true)
	draw_circle(c + needle, 8.0, Color(1, 1, 1, _alpha))
	# Instrucción
	var hint := ""
	if tr.spotting or tr.all_settled():
		hint = "ATERRIZANDO"
	elif tr.tucked:
		hint = "SUELTA para abrir y aterrizar"
	else:
		hint = "círculo en el morado = tirabuzón" if Settings.trick_controls == 5 else "inclina otra vez = otra vuelta"
	_text(font, Vector2(cx, c.y + r + 34), hint, 20, Color(0.85, 0.95, 1, _alpha))
	var _t := turns

func _text(font: Font, center: Vector2, text: String, fs: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string_outline(font, center + Vector2(-w * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.6 * color.a))
	draw_string(font, center + Vector2(-w * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
