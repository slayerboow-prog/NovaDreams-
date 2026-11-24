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

func clear_edges() -> void:
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

func copy_from(o: InputIntent) -> void:
	move = o.move; sprint = o.sprint; jump_pressed = o.jump_pressed; jump_held = o.jump_held
	action_pressed = o.action_pressed; action_held = o.action_held; flick = o.flick; tuck = o.tuck
	camera_delta = o.camera_delta; camera_recenter = o.camera_recenter; respawn_pressed = o.respawn_pressed; kick = o.kick; rot = o.rot
	vault_pressed = o.vault_pressed; grab_pressed = o.grab_pressed; grab_held = o.grab_held
	twist = o.twist; stick_twist = o.stick_twist; rot_flick = o.rot_flick
	skill_request = o.skill_request; double_flip = o.double_flip
