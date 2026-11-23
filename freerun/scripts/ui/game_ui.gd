class_name GameUI
extends CanvasLayer
## HUD de combo y puntuación, avisos, menú principal, pausa y ajustes.
## Construido por código con un tema propio (limpio, legible en pantallas pequeñas).

signal mode_selected(id: String)
signal resume_requested
signal restart_requested
signal menu_requested
signal extra_pressed

var game: Node
var touch: TouchControls

var hud: Control
var combo_chain: Label
var combo_value: Label
var combo_mult: Label
var status: Label
var mode_title: Label
var speed_label: Label
var fps_label: Label
var landing_label: Label
var popups: VBoxContainer
var pause_btn: Button
var extra_btn: Button
var help_label: Label
var rotate_overlay: Control
var trick_indicator: TrickIndicator

var main_menu: Control
var pause_menu: Control
var settings_panel: Control
var theme_res: Theme

var _landing_time := 0.0

const ACCENT := Color(0.15, 0.85, 0.78)
const BG := Color(0.06, 0.07, 0.1, 0.86)

func setup(g: Node) -> void:
	game = g
	layer = 10
	theme_res = _make_theme()
	touch = TouchControls.new()
	touch.name = "Touch"
	add_child(touch)
	_build_hud()
	_build_main_menu()
	_build_pause()
	_build_settings()
	_build_rotate_overlay()
	Settings.changed.connect(_apply_settings)
	_apply_settings()

## En móvil en vertical el juego no cabe: pedimos girar el teléfono.
func _build_rotate_overlay() -> void:
	rotate_overlay = ColorRect.new()
	(rotate_overlay as ColorRect).color = Color(0.04, 0.06, 0.09, 0.97)
	rotate_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var l := _label("Gira el móvil en horizontal\npara jugar", 44, ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	rotate_overlay.add_child(l)
	rotate_overlay.visible = false
	add_child(rotate_overlay)

func _process(_dt: float) -> void:
	if rotate_overlay:
		var vs := get_viewport().get_visible_rect().size
		var portrait := vs.y > vs.x * 1.05 and _touch_wanted()
		if rotate_overlay.visible != portrait:
			rotate_overlay.visible = portrait
			move_child(rotate_overlay, get_child_count() - 1)

func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.19, 0.95)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18; sb.content_margin_right = 18
	sb.content_margin_top = 10; sb.content_margin_bottom = 10
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.32, 0.34, 0.98)
	var pressed := sb.duplicate() as StyleBoxFlat
	pressed.bg_color = ACCENT.darkened(0.3)
	th.set_stylebox("normal", "Button", sb)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("focus", "Button", hover)
	th.set_color("font_color", "Button", Color(0.95, 0.97, 1))
	var panel := StyleBoxFlat.new()
	panel.bg_color = BG
	panel.set_corner_radius_all(20)
	panel.content_margin_left = 28; panel.content_margin_right = 28
	panel.content_margin_top = 22; panel.content_margin_bottom = 22
	th.set_stylebox("panel", "PanelContainer", panel)
	th.set_color("font_color", "Label", Color(0.95, 0.97, 1))
	th.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.7))
	th.set_constant("outline_size", "Label", 4)
	return th

func _label(text: String, size: int, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	# En móvil los textos se ven mucho más pequeños: se agrandan.
	var k := 1.3 if (DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_ios") or OS.has_feature("web_android")) else 1.0
	l.add_theme_font_size_override("font_size", int(size * k))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _button(text: String, cb: Callable, min_w := 320.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 58)
	b.pressed.connect(cb)
	b.focus_mode = Control.FOCUS_ALL
	return b

# ------------------------------------------------------------------ HUD

func _build_hud() -> void:
	hud = Control.new()
	hud.theme = theme_res
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	move_child(hud, 0)

	mode_title = _label("", 18, ACCENT)
	mode_title.position = Vector2(24, 14)
	hud.add_child(mode_title)
	status = _label("", 18)
	status.position = Vector2(24, 38)
	hud.add_child(status)

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.position.y = 62
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	combo_value = _label("", 40, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	combo_mult = _label("", 24, Color(1, 0.85, 0.25), HORIZONTAL_ALIGNMENT_CENTER)
	combo_chain = _label("", 19, Color(0.85, 0.95, 1), HORIZONTAL_ALIGNMENT_CENTER)
	combo_chain.custom_minimum_size.x = 900
	for l in [combo_value, combo_mult, combo_chain]:
		top.add_child(l)

	landing_label = _label("", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	landing_label.set_anchors_preset(Control.PRESET_CENTER)
	landing_label.position.y += 60
	landing_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud.add_child(landing_label)

	popups = VBoxContainer.new()
	popups.set_anchors_preset(Control.PRESET_CENTER)
	popups.grow_horizontal = Control.GROW_DIRECTION_BOTH
	popups.position.y -= 150
	popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(popups)

	speed_label = _label("", 16, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	speed_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	speed_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	speed_label.position.y -= 34
	hud.add_child(speed_label)

	fps_label = _label("", 14, Color(0.7, 1, 0.7))
	fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fps_label.position = Vector2(-200, 76)
	hud.add_child(fps_label)

	help_label = _label("WASD mover · Shift sprint · Espacio saltar (mantener: wall run) · Ctrl rodar\n" +
		"Flechas: acrobacias (↓ back · ↑ front · ←→ lateral · diagonal = tirabuzón; mantener = agruparse)\n" +
		"Ratón: cámara (clic para capturar) · R reaparecer · Esc pausa", 15, Color(1, 1, 1, 0.75))
	help_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help_label.position = Vector2(20, -80)
	hud.add_child(help_label)

	pause_btn = Button.new()
	pause_btn.text = "II"
	pause_btn.custom_minimum_size = Vector2(64, 56)
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.position = Vector2(-88, 14)
	pause_btn.pressed.connect(func(): game.set_paused(true))
	hud.add_child(pause_btn)

	extra_btn = Button.new()
	extra_btn.custom_minimum_size = Vector2(200, 52)
	extra_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	extra_btn.position = Vector2(-310, 16)
	extra_btn.pressed.connect(func(): extra_pressed.emit())
	extra_btn.visible = false
	hud.add_child(extra_btn)
	trick_indicator = TrickIndicator.new()
	trick_indicator.name = "TrickIndicator"
	hud.add_child(trick_indicator)
	hud.visible = false

func show_hud(v: bool) -> void:
	hud.visible = v
	touch.visible = v and (_touch_wanted())

func _touch_wanted() -> bool:
	return Settings.force_touch_ui or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

func update_hud(combo: ComboSystem, player: PlayerController, mode_status: String, mode_name: String, extra: String) -> void:
	mode_title.text = mode_name
	status.text = mode_status
	if combo.active:
		combo_value.text = str(combo.current_value())
		combo_mult.text = "x%.1f" % combo.multiplier + ("   +%d%% velocidad" % int(combo.speed_bonus() * 100) if combo.speed_bonus() > 0.01 else "")
		var tail := combo.chain.slice(maxi(0, combo.chain.size() - 5))
		combo_chain.text = ("… › " if combo.chain.size() > 5 else "") + " › ".join(tail)
	else:
		combo_value.text = ""
		combo_mult.text = ""
		combo_chain.text = ""
	speed_label.text = "%d km/h  ·  %s" % [int(player.speed() * 3.6), PlayerController.STATE_NAMES[player.state]]
	fps_label.visible = Settings.show_fps
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	touch.context_label = player.context_hint
	help_label.visible = not touch.visible
	extra_btn.visible = extra != ""
	extra_btn.text = extra
	if _landing_time > 0.0:
		_landing_time -= get_process_delta_time()
		landing_label.modulate.a = clampf(_landing_time / 0.4, 0.0, 1.0)

func show_landing(text: String, color: Color) -> void:
	landing_label.text = text
	landing_label.add_theme_color_override("font_color", color)
	landing_label.modulate.a = 1.0
	_landing_time = 1.1

func popup(text: String, color := Color.WHITE) -> void:
	var l := _label(text, 28, color, HORIZONTAL_ALIGNMENT_CENTER)
	popups.add_child(l)
	while popups.get_child_count() > 4:
		popups.get_child(0).queue_free()
		popups.remove_child(popups.get_child(0))
	var tw := l.create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

# ------------------------------------------------------------------ menús

func _centered_panel() -> Array:
	var root := Control.new()
	root.theme = theme_res
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	add_child(root)
	return [root, box]

func _build_main_menu() -> void:
	var r := _centered_panel()
	main_menu = r[0]
	var box: VBoxContainer = r[1]
	var title := _label("FREERUN", 64, ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)
	box.add_child(_label("Parkour · Freerunning · Tricking · Water Tricks", 18, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for id in GameModes.LIST:
		var inf := GameModes.info(id)
		var b := _button(inf.title, func(): mode_selected.emit(id), 330)
		b.tooltip_text = inf.desc
		b.custom_minimum_size.y = 64
		grid.add_child(b)
	grid.add_child(_button("Ajustes", func(): open_settings(), 330))
	box.add_child(_label("Elige una disciplina. Todas comparten el mismo sistema de movimiento.", 15, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER))

func _build_pause() -> void:
	var r := _centered_panel()
	pause_menu = r[0]
	var box: VBoxContainer = r[1]
	box.add_child(_label("PAUSA", 44, ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_button("Continuar", func(): resume_requested.emit()))
	box.add_child(_button("Reiniciar", func(): restart_requested.emit()))
	box.add_child(_button("Ajustes", func(): open_settings()))
	box.add_child(_button("Menú principal", func(): menu_requested.emit()))
	pause_menu.visible = false

func _slider(box: VBoxContainer, text: String, key: String, mn: float, mx: float, step: float) -> void:
	var row := HBoxContainer.new()
	var l := _label(text, 18)
	l.custom_minimum_size.x = 260
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = Settings.get(key)
	s.custom_minimum_size = Vector2(260, 40)
	var val := _label("%.2f" % s.value, 18)
	val.custom_minimum_size.x = 60
	s.value_changed.connect(func(v):
		Settings.set(key, v)
		val.text = "%.2f" % v)
	row.add_child(s)
	row.add_child(val)
	box.add_child(row)

func _option(box: VBoxContainer, text: String, key: String, options: Array) -> void:
	var row := HBoxContainer.new()
	var l := _label(text, 18)
	l.custom_minimum_size.x = 260
	row.add_child(l)
	var ob := OptionButton.new()
	for o in options:
		ob.add_item(o)
	ob.selected = int(Settings.get(key))
	ob.custom_minimum_size = Vector2(320, 44)
	ob.item_selected.connect(func(i): Settings.set(key, i))
	row.add_child(ob)
	box.add_child(row)

func _check(box: VBoxContainer, text: String, key: String) -> void:
	var cb := CheckButton.new()
	cb.text = text
	cb.button_pressed = bool(Settings.get(key))
	cb.toggled.connect(func(v): Settings.set(key, v))
	box.add_child(cb)

func _build_settings() -> void:
	var r := _centered_panel()
	settings_panel = r[0]
	var box: VBoxContainer = r[1]
	box.add_child(_label("AJUSTES", 40, ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	_option(box, "Ayuda de rotación", "rotation_assist", ["Pro (sin ayudas)", "Media", "Alta"])
	_option(box, "Controles de trucos", "trick_controls", ["Doble joystick", "Solo gestos", "Solo cruceta", "Gestos + cruceta"])
	_option(box, "Gráficos", "graphics_preset", ["Bajo", "Medio", "Alto"])
	_slider(box, "Sensibilidad cámara", "camera_sensitivity", 0.3, 2.5, 0.05)
	_slider(box, "Sensibilidad joystick/gestos", "gesture_sensitivity", 0.4, 2.0, 0.05)
	_slider(box, "Tamaño controles", "control_scale", 0.7, 1.4, 0.05)
	_slider(box, "Distancia cámara", "camera_distance", 0.75, 1.4, 0.05)
	_slider(box, "Opacidad controles", "control_opacity", 0.2, 1.0, 0.05)
	_check(box, "Modo zurdo (joystick a la derecha)", "left_handed")
	_check(box, "Invertir eje Y de cámara", "invert_camera_y")
	_check(box, "Forzar controles táctiles", "force_touch_ui")
	_check(box, "Mostrar FPS", "show_fps")
	box.add_child(_button("Guardar y volver", func():
		Settings.save_settings()
		settings_panel.visible = false))
	settings_panel.visible = false

func open_settings() -> void:
	settings_panel.visible = true
	move_child(settings_panel, get_child_count() - 1)

func show_main_menu(v: bool) -> void:
	main_menu.visible = v

func show_pause(v: bool) -> void:
	pause_menu.visible = v

func _apply_settings() -> void:
	if hud.visible:
		touch.visible = _touch_wanted()
	if game and game.has_method("apply_graphics"):
		game.apply_graphics()
