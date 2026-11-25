class_name MoveTuning
extends Resource
## Todos los parámetros del núcleo de movimiento en un único sitio.
## Las cinco disciplinas comparten este mismo controlador y estos valores.

# Locomoción
@export var walk_speed := 2.6
@export var run_speed := 6.4
@export var sprint_speed := 9.4
@export var accel := 18.0              # aceleración cerca de la velocidad máxima
@export var accel_start := 38.0        # aceleración al arrancar (explosiva)
@export var overspeed_decel := 6.0      # pierde exceso de velocidad suavemente (conserva momentum)
@export var decel := 26.0
@export var skid_decel := 34.0
@export var turn_rate_slow := 13.0      # rad/s a baja velocidad
@export var turn_rate_fast := 3.6       # rad/s a sprint: más inercia
@export var facing_turn := 14.0
@export var momentum_build := 1.1       # s corriendo recto para pasar de carrera a sprint completo
@export var flow_speed_bonus := 0.06    # en flow máximo, +6 % de velocidad punta (nada imposible)

# Salto y aire
@export var gravity := 22.0
@export var trick_gravity_mult := 0.8  # en acrobacia: ~0,95 s de vuelo (menos flotante, más real)
@export var jump_velocity := 8.4
@export var jump_speed_bonus := 0.06    # salto ligeramente más alto cuanto más rápido
@export var low_jump_mult := 2.2        # soltar salto pronto = salto corto
@export var max_fall := 30.0
@export var air_accel := 7.0
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.14
@export var jump_load_time := 0.07     # flexión previa al despegue (anticipación visible)

# Aterrizajes
@export var perfect_angle := 14.0       # grados de error permitidos
@export var clean_angle := 30.0
@export var sloppy_angle := 58.0
@export var hard_impact := 13.5         # m/s de caída (~4 m): sin rodar = recepción dura
@export var crash_impact := 21.0        # m/s (~10 m): sin rodar = caída
@export var roll_window := 0.32
@export var roll_time := 0.55
@export var crash_time := 1.5
@export var stun_time := 0.45

# Vaults
@export var vault_min_speed := 2.2
@export var vault_min_height := 0.3
@export var vault_max_height := 1.35

# Paredes
@export var wallrun_min_speed := 5.0
@export var wallrun_max_time := 1.15
@export var wallrun_up_boost := 3.6
@export var wallrun_gravity := 0.3
@export var walljump_push := 5.5
@export var walljump_up := 7.6
@export var tictac_up := 7.4
@export var wallclimb_speed := 6.2
@export var wallclimb_time := 0.55
@export var climb_up_time := 0.6
@export var mantle_time := 0.45
@export var shimmy_speed := 1.6

# Acrobacias (rad/s)
@export var flip_rate_min := 6.0
@export var flip_rate_max := 13.0
@export var flip_rate_pro := 10.5
@export var twist_rate_min := 7.0
@export var twist_rate_max := 16.0
@export var twist_stick_rate := 14.0 # rad/s con el joystick GIRO a fondo (¼ ≈ 0,11 s, 1 vuelta ≈ 0,45 s, 2 ≈ 0,9 s); poco inclinado = más lento y preciso
@export var tuck_mult := 1.5         # agrupado del todo: gira un 50 % más rápido (se alcanza poco a poco)
@export var open_mult_pro := 0.55

@export var kill_y := -25.0
