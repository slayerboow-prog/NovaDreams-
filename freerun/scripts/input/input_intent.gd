class_name InputIntent
extends RefCounted
## Intención del jugador en un frame de física. Es la única interfaz entre los
## dispositivos (táctil, teclado, mando, bots de test, futuro multijugador/replays)
## y el controlador del personaje.

var move := Vector2.ZERO        # x derecha, y adelante (espacio del stick), magnitud 0..1
var sprint := false
var jump_pressed := false       # flanco de bajada este frame
var jump_held := false
var action_pressed := false     # botón contextual: rodar / soltarse / agarrar
var action_held := false
var flick := Vector2.ZERO       # gesto rápido este frame (x derecha, y arriba). Cero si no hay
var tuck := false               # dedo/tecla de truco mantenido = agruparse (girar más rápido)
var camera_delta := Vector2.ZERO
var camera_recenter := false        # doble toque en la zona de cámara: detrás del atleta
var twist := 0.0                    # joystick GIRO (eje x): tirabuzón de cualquier mortal
var stick_twist := false            # el joystick derecho es el de GIRO (los mortales van en la rueda de SALTO)
var rot_flick := Vector2.ZERO       # inclinación brusca del joystick derecho (movimientos de suelo)
var respawn_pressed := false
var kick := false               # giro sobre el eje largo (360/540/720) o tirabuzón añadido
var vault_pressed := false      # botón VAULT (flanco)
var grab_pressed := false       # botón AGARRAR (flanco)
var grab_held := false
var rot := Vector2.ZERO         # joystick derecho analógico (x derecha, y arriba), magnitud 0..1
var skill_request := ""         # botonera: botón de un movimiento de suelo (rondada, flic-flac...)
var double_flip := false        # botonera: botón de doble mortal
var cork_request := false       # botonera: botón CORK (salta en cork o, en el aire, lo empieza; en un cork = ST)
var butterfly_request := false  # botonera: botón MARIPOSA (butterfly aunque no haya carrera)
var skill_hold := false         # botonera: botón de habilidad mantenido (PINO: sigue en el pino)
var pattern := {}               # modo gestos: patrón reconocido en el joystick dorado (GestureRecognizer)
var twist_loops: Array[int] = []  # modo gestos: círculos completados en el joystick morado (+1 horario)
var giro_sector := 99           # modo gestos: línea recta en el joystick morado (movimientos de suelo)
var giro := {}                  # modo gestos: trazo del joystick morado en el suelo (GestureRecognizer.recognize_giro)
var flip_press := 99            # botón de mortal pulsado (sector: -2 atrás · 2 adelante · 0/4 lateral)
var flip_held := false          # botón de mortal mantenido (carga del salto)

func clear_edges() -> void:
	pattern = {}
	twist_loops = []
	giro_sector = 99
	giro = {}
	flip_press = 99
	jump_pressed = false
	action_pressed = false
	flick = Vector2.ZERO
	camera_delta = Vector2.ZERO
	camera_recenter = false
	rot_flick = Vector2.ZERO
	respawn_pressed = false
	kick = false
	vault_pressed = false
	grab_pressed = false
	skill_request = ""
	double_flip = false
	cork_request = false
	butterfly_request = false

func copy_from(o: InputIntent) -> void:
	move = o.move; sprint = o.sprint; jump_pressed = o.jump_pressed; jump_held = o.jump_held
	action_pressed = o.action_pressed; action_held = o.action_held; flick = o.flick; tuck = o.tuck
	camera_delta = o.camera_delta; camera_recenter = o.camera_recenter; respawn_pressed = o.respawn_pressed; kick = o.kick; rot = o.rot
	vault_pressed = o.vault_pressed; grab_pressed = o.grab_pressed; grab_held = o.grab_held
	twist = o.twist; stick_twist = o.stick_twist; rot_flick = o.rot_flick
	skill_request = o.skill_request; double_flip = o.double_flip; cork_request = o.cork_request
	butterfly_request = o.butterfly_request; skill_hold = o.skill_hold
	pattern = o.pattern; twist_loops = o.twist_loops; giro_sector = o.giro_sector; giro = o.giro; flip_press = o.flip_press; flip_held = o.flip_held
