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
var respawn_pressed := false

func clear_edges() -> void:
	jump_pressed = false
	action_pressed = false
	flick = Vector2.ZERO
	camera_delta = Vector2.ZERO
	respawn_pressed = false

func copy_from(o: InputIntent) -> void:
	move = o.move; sprint = o.sprint; jump_pressed = o.jump_pressed; jump_held = o.jump_held
	action_pressed = o.action_pressed; action_held = o.action_held; flick = o.flick; tuck = o.tuck
	camera_delta = o.camera_delta; respawn_pressed = o.respawn_pressed
