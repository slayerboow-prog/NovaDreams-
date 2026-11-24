class_name GameUI
extends CanvasLayer
## HUD de combo y puntuación, avisos, menú principal, pausa y ajustes.
## Construido por código con un tema propio (limpio, legible en pantallas pequeñas).

signal mode_selected(id: String)
signal resume_requested
signal restart_requested
signal menu_requested
signal extra_pressed
signal respawn_requested

var game: Node
var touch: TouchControls

var hud: Control
var combo_chain: Label
var combo_value: Label
var score_banner: PanelContainer
var combo_mult: Label
var status: Label
var mode_title: Label
var speed_label: Label
var flow_bg: ColorRect
var flow_fill: ColorRect
var flow_label: Label
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
var library_panel: Control
var tutorial_label: Label
var theme_res: Theme

# Tutorial opcional (menú de pausa): cada paso avanza al detectar el movimiento real.
const TUTORIAL := [
	["Corre: inclina el joystick azul (a fondo = sprint)", ["@run"]],
	["Mueve la cámara: arrastra en una zona libre (doble toque = detrás del atleta)", ["@camera"]],
	["Toca el joystick dorado (SALTO)", ["@air"]],
	["Dorado: línea hacia abajo = Mortal atrás (deja el dedo quieto = agrupado)", ["Backflip", "Gainer"]],
	["Dorado: línea hacia arriba = Mortal adelante", ["Frontflip", "Webster"]],
	["Dorado: línea a un lado = Mortal lateral", ["Sideflip"]],
	["Dorado: arco lateral que sube y baja = Aerial", ["Aerial", "Double Aerial"]],
	["Dorado: diagonal hacia arriba y un círculo pequeño = Cork", ["Cork", "Cork 540", "Cork 720"]],
	["Dorado: hacia abajo y una vuelta ovalada = Gainer", ["Gainer", "Backflip"]],
	["Mortal atrás y, en el aire, un círculo en el joystick morado = Piru", ["Piru", "Piru 540", "Piru 720", "Cork", "Cork 720"]],
	["Morado en el suelo: línea a un lado = Rueda con apoyo de manos", ["Cartwheel"]],
	["Morado en el suelo: línea hacia abajo = Flic-flac", ["Back Handspring"]],
	["Morado: línea hacia arriba = Rondada y, al recibir (¡ENLAZA!), línea abajo en el dorado", ["@roundoff_back"]],
	["Morado: arco por abajo (∪) = Hook · arco por arriba (∩) = Macaco", ["Hook Kick", "Macaco"]],
	["Morado: círculo y en seguida línea abajo en el dorado = Piru", ["Piru", "Piru 540", "Piru 720"]],
	["Morado: un círculo y diagonal arriba = 360 + rueda fuerte (entrada de potencia)", ["3-Step 360", "Cartwheel"]],
	["Corre hacia un obstáculo y dibuja una U invertida en el dorado (o pulsa VAULT)", ["@vault"]],
	["Junto a una pared alta: zigzag hacia arriba en el dorado = Escalada", ["Wall Climb", "Ledge Grab", "Cat Leap", "Mantle"]],
	["Antes de caer desde alto: curva hacia abajo y adelante en el dorado = Rodar", ["Safety Roll", "Roll"]],
]
var tutorial_step := -1
var _last_move := ""
var _last_move_t := 0.0

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
	touch.quick_action.connect(_on_quick_action)
	_build_hud()
	_build_main_menu()
	_build_pause()
	_build_settings()
	_build_library()
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

	# Marcador de combo en un cartel neón (navy + aro dorado).
	score_banner = PanelContainer.new()
	var sbx := StyleBoxFlat.new()
	sbx.bg_color = Color(Neon.NAVY, 0.78)
	sbx.border_color = Color(Neon.GOLD, 0.9)
	sbx.set_border_width_all(3)
	sbx.set_corner_radius_all(22)
	sbx.shadow_color = Color(Neon.GOLD, 0.25)
	sbx.shadow_size = 10
	sbx.content_margin_left = 30; sbx.content_margin_right = 30
	sbx.content_margin_top = 6; sbx.content_margin_bottom = 8
	score_banner.add_theme_stylebox_override("panel", sbx)
	score_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	score_banner.position.y = 58
	score_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	score_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_banner.visible = false
	hud.add_child(score_banner)
	var top := VBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_banner.add_child(top)
	combo_value = _label("", 40, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	combo_mult = _label("", 24, Color(1, 0.85, 0.25), HORIZONTAL_ALIGNMENT_CENTER)
	combo_chain = _label("", 19, Color(0.85, 0.95, 1), HORIZONTAL_ALIGNMENT_CENTER)
	combo_chain.custom_minimum_size.x = 560
	for l in [combo_value, combo_mult, combo_chain]:
		top.add_child(l)

	landing_label = _label("", 34, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	landing_label.set_anchors_preset(Control.PRESET_CENTER)
	landing_label.position.y += 60
	landing_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud.add_child(landing_label)
	tutorial_label = _label("", 24, Color(1, 0.92, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tutorial_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tutorial_label.position.y = 118
	tutorial_label.add_theme_color_override("font_outline_color", Color.BLACK)
	tutorial_label.add_theme_constant_override("outline_size", 7)
	tutorial_label.visible = false
	hud.add_child(tutorial_label)

	popups = VBoxContainer.new()
	popups.set_anchors_preset(Control.PRESET_CENTER)
	popups.grow_horizontal = Control.GROW_DIRECTION_BOTH
	popups.position.y -= 150
	popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(popups)

	# Velocidad y estado: arriba a la izquierda, bajo la puntuación (abajo lo tapaban los botones)
	speed_label = _label("", 15, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT)
	speed_label.position = Vector2(24, 64)
	hud.add_child(speed_label)

	# Medidor FLOW (arriba al centro, fino para no tapar la acción)
	flow_bg = ColorRect.new()
	flow_bg.color = Color(0, 0, 0, 0.35)
	flow_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	flow_bg.size = Vector2(220, 8)
	flow_bg.position = Vector2(-110, 14)
	flow_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flow_bg)
	flow_fill = ColorRect.new()
	flow_fill.color = Color(0.2, 0.85, 0.78)
	flow_fill.size = Vector2(0, 8)
	flow_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow_bg.add_child(flow_fill)
	flow_label = _label("FLOW", 13, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	flow_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	flow_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	flow_label.position.y = 22
	hud.add_child(flow_label)

	fps_label = _label("", 14, Color(0.7, 1, 0.7))
	fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fps_label.position = Vector2(-200, 76)
	hud.add_child(fps_label)

	help_label = _label("WASD mover · Shift sprint · Espacio saltar (mantener: wall run) · Ctrl rodar\n" +
		"Flechas: acrobacias (abajo back · arriba front · lados lateral · diagonal = tirabuzón; mantener = agruparse)\n" +
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

func update_flow(v: float, flowing: bool) -> void:
	if flow_bg == null:
		return
	flow_fill.size.x = 220.0 * v / 100.0
	flow_fill.color = Color(1.0, 0.82, 0.3) if flowing else Color(0.2, 0.85, 0.78)
	flow_label.text = ("FLOW %d" % int(v)) + ("  ·  EN FLOW" if flowing else "")
	flow_bg.modulate.a = 1.0 if v > 0.5 else 0.45
	flow_label.modulate.a = 1.0 if v > 0.5 else 0.45

func update_hud(combo: ComboSystem, player: PlayerController, mode_status: String, mode_name: String, extra: String) -> void:
	mode_title.text = mode_name
	status.text = mode_status
	if combo.active:
		combo_value.text = str(combo.current_value())
		score_banner.visible = true
		combo_mult.text = "x%.1f" % combo.multiplier + ("   +%d%% velocidad" % int(combo.speed_bonus() * 100) if combo.speed_bonus() > 0.01 else "")
		var tail: Array = combo.chain.slice(maxi(0, combo.chain.size() - 5)).map(func(n): return MoveNames.es(n))
		combo_chain.text = ("… › " if combo.chain.size() > 5 else "") + " › ".join(tail)
	else:
		combo_value.text = ""
		score_banner.visible = false
		combo_mult.text = ""
		combo_chain.text = ""
	speed_label.text = "%d km/h  ·  %s" % [int(player.speed() * 3.6), PlayerController.STATE_NAMES[player.state]]
	fps_label.visible = Settings.show_fps
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	touch.context_label = player.context_hint
	touch.grab_label = "SOLTAR" if player.state == PlayerController.State.HANG else "AGARRAR"
	_tutorial_tick(player)
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
	var l := _label(MoveNames.safe(text), 28, color, HORIZONTAL_ALIGNMENT_CENTER)
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
	box.add_child(_button("Reaparecer", func(): respawn_requested.emit()))
	box.add_child(_button("Reiniciar", func(): restart_requested.emit()))
	box.add_child(_button("Movimientos", func(): open_library()))
	box.add_child(_button("Tutorial de controles", func(): start_tutorial()))
	box.add_child(_button("Práctica de gestos", func():
		resume_requested.emit()
		Settings.trick_controls = 5
		touch.toggle_training(true)))
	box.add_child(_button("Ajustes", func(): open_settings()))
	box.add_child(_button("Menú principal", func(): menu_requested.emit()))
	pause_menu.visible = false

## Biblioteca de movimientos: solo en el menú, nunca ocupa la pantalla de juego.
func _build_library() -> void:
	var r := _centered_panel()
	library_panel = r[0]
	var box: VBoxContainer = r[1]
	box.add_child(_label("MOVIMIENTOS", 36, ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1000, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size = Vector2(980, 0)
	text.add_theme_font_size_override("normal_font_size", 19)
	text.add_theme_font_size_override("bold_font_size", 20)
	text.text = MoveNames.safe(MoveLibrary.bbcode())
	scroll.add_child(text)
	box.add_child(_button("Volver", func(): library_panel.visible = false))
	library_panel.visible = false

func open_library() -> void:
	library_panel.visible = true
	move_child(library_panel, get_child_count() - 1)

## Accesos rápidos neón de la botonera (columna izquierda).
func _on_quick_action(id: String) -> void:
	match id:
		"library":
			game.set_paused(true)
			open_library()
		"tutorial":
			start_tutorial()
		"training":
			touch.toggle_training()
		"settings":
			game.set_paused(true)
			open_settings()
		"respawn":
			respawn_requested.emit()

func start_tutorial() -> void:
	tutorial_step = 0
	touch.cam_used = false
	var p: PlayerController = game.player
	if not p.move_performed.is_connected(_on_tutorial_move):
		p.move_performed.connect(_on_tutorial_move)
	resume_requested.emit()
	_refresh_tutorial()

func _refresh_tutorial() -> void:
	if tutorial_label == null:
		return
	tutorial_label.visible = tutorial_step >= 0
	if tutorial_step >= 0:
		tutorial_label.text = MoveNames.safe("TUTORIAL %d/%d   %s" % [tutorial_step + 1, TUTORIAL.size(), TUTORIAL[tutorial_step][0]])

func _tutorial_advance() -> void:
	tutorial_step += 1
	if tutorial_step >= TUTORIAL.size():
		tutorial_step = -1
		popup("¡Tutorial completado! Biblioteca completa en Pausa › Movimientos", ACCENT)
	else:
		popup("¡Bien!", ACCENT)
	_refresh_tutorial()

func _on_tutorial_move(move_name: String, _q: float, _i: Dictionary) -> void:
	var prev := _last_move
	var recent := Time.get_ticks_msec() / 1000.0 - _last_move_t < 2.0
	_last_move = move_name
	_last_move_t = Time.get_ticks_msec() / 1000.0
	if tutorial_step < 0:
		return
	var want: Array = TUTORIAL[tutorial_step][1]
	var ok := want.has(move_name)
	if want.has("@twist") and (_i.get("twist_quarters", 0) > 0):
		ok = true
	if want.has("@vault") and (move_name.contains("Vault") or move_name.contains("Kong")):
		ok = true
	if want.has("@roundoff_back") and move_name in ["Backflip", "Gainer"] and prev == "Round-off" and recent:
		ok = true
	if ok:
		_tutorial_advance()

func _tutorial_tick(player: PlayerController) -> void:
	if tutorial_step < 0:
		return
	var want: Array = TUTORIAL[tutorial_step][1]
	if want.has("@camera") and (touch.cam_used or not touch.visible):
		_tutorial_advance()
		return
	if (want.has("@run") and player.speed() > 5.0) or (want.has("@air") and player.state == PlayerController.State.AIR):
		_tutorial_advance()

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
	_option(box, "Controles de trucos", "trick_controls", ["Doble joystick (rueda)", "Solo gestos", "Solo cruceta", "Gestos + cruceta", "Botonera de botones", "Gestos: SALTO + GIRO (por defecto)"])
	_option(box, "Gráficos", "graphics_preset", ["Bajo", "Medio", "Alto"])
	_slider(box, "Sensibilidad cámara", "camera_sensitivity", 0.3, 2.5, 0.05)
	_slider(box, "Sensibilidad joystick/gestos", "gesture_sensitivity", 0.4, 2.0, 0.05)
	_slider(box, "Tamaño controles", "control_scale", 0.7, 1.4, 0.05)
	_option(box, "Cámara", "camera_mode", ["Híbrida (sigue y respeta lo que muevas)", "Manual", "Automática"])
	_slider(box, "Distancia cámara", "camera_distance", 0.75, 1.4, 0.05)
	_slider(box, "Altura cámara", "camera_height", 0.7, 1.5, 0.05)
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
