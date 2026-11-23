class_name TrickSystem
extends RefCounted
## Rotaciones aéreas controladas por el jugador.
##
## El cuerpo visual gira alrededor de su centro de masas con tres ejes locales:
##   pitch (mortal adelante/atrás), roll (mortal lateral) y twist (giro sobre el eje largo).
## Un gesto (flick) fija un objetivo de rotación (360°, 720°...). Con ayudas, la velocidad
## angular se calibra para llegar al objetivo justo al aterrizar y el cuerpo "abre" al
## completarlo. En modo Pro la velocidad es fija: mantener = agruparse (más rápido),
## soltar = abrirse (más lento) y el jugador decide cuándo frenar el giro.

var basis := Basis()            # orientación del cuerpo relativa a la dirección de despegue
var pitch_rate := 0.0           # + = hacia atrás (backflip)
var roll_rate := 0.0            # + = cabeza hacia la derecha
var twist_rate := 0.0
var total_pitch := 0.0
var total_roll := 0.0
var total_twist := 0.0
var target_pitch := 0.0
var target_roll := 0.0
var target_twist := 0.0
var active := false
var flicks := 0
var tucked := false
var takeoff_kind := "run"       # run, stand, wall, vault, ledge
var takeoff_speed := 0.0
var air_time := 0.0
var max_height := 0.0

func reset(kind := "run", speed := 0.0) -> void:
	basis = Basis()
	pitch_rate = 0.0; roll_rate = 0.0; twist_rate = 0.0
	total_pitch = 0.0; total_roll = 0.0; total_twist = 0.0
	target_pitch = 0.0; target_roll = 0.0; target_twist = 0.0
	active = false
	flicks = 0
	tucked = false
	takeoff_kind = kind
	takeoff_speed = speed
	air_time = 0.0
	max_height = 0.0

func has_rotation() -> bool:
	return active and (absf(total_pitch) + absf(total_roll) + absf(total_twist)) > 0.3

## Aplica un gesto. dir: x derecha, y arriba (abajo = backflip, arriba = frontflip,
## lateral = mortal lateral, diagonal = mortal con tirabuzón).
func apply_flick(dir: Vector2) -> void:
	if dir.length() < 0.1:
		return
	var ax := absf(dir.x)
	var ay := absf(dir.y)
	var vertical := ay > ax * 0.5
	var horizontal := ax > ay * 0.5
	var pitch_sign := 0.0
	var roll_sign := 0.0
	var twist_sign := 0.0
	if vertical:
		pitch_sign = 1.0 if dir.y < 0.0 else -1.0
	if horizontal:
		if vertical:
			twist_sign = signf(dir.x)
		else:
			roll_sign = signf(dir.x)

	var flipping := target_pitch != 0.0 or target_roll != 0.0
	if not flipping:
		if pitch_sign != 0.0:
			target_pitch = TAU * pitch_sign
		if roll_sign != 0.0:
			target_roll = TAU * roll_sign
		if twist_sign != 0.0:
			target_twist += TAU * twist_sign
	else:
		# Gestos durante un mortal: misma dirección = otra vuelta; lateral = añadir tirabuzón.
		if pitch_sign != 0.0 and target_pitch != 0.0 and signf(target_pitch) == pitch_sign:
			target_pitch += TAU * pitch_sign
		elif roll_sign != 0.0 and target_roll != 0.0 and signf(target_roll) == roll_sign and twist_sign == 0.0:
			target_roll += TAU * roll_sign
		var add_twist := twist_sign if twist_sign != 0.0 else (roll_sign if target_pitch != 0.0 else 0.0)
		if add_twist != 0.0:
			target_twist += TAU * add_twist
	flicks += 1
	active = true

func step(dt: float, tuck_held: bool, time_left: float, assist: float, t: MoveTuning) -> void:
	air_time += dt
	if not active:
		return
	tucked = tuck_held
	var open_mult := lerpf(t.open_mult_pro, 1.0, assist)
	var mult := t.tuck_mult if tuck_held else open_mult
	time_left = maxf(time_left, 0.12)
	pitch_rate = _axis_rate(target_pitch, total_pitch, time_left, assist, mult, t.flip_rate_min, t.flip_rate_max, t.flip_rate_pro)
	roll_rate = _axis_rate(target_roll, total_roll, time_left, assist, mult, t.flip_rate_min, t.flip_rate_max, t.flip_rate_pro)
	twist_rate = _axis_rate(target_twist, total_twist, time_left, assist, mult, t.twist_rate_min, t.twist_rate_max, t.flip_rate_pro * 1.6)
	var dp := pitch_rate * dt
	var dr := roll_rate * dt
	var dtw := twist_rate * dt
	total_pitch += dp
	total_roll += dr
	total_twist += dtw
	# Orientación compuesta desde los ángulos acumulados: mortal (pitch), lateral (roll) y
	# tirabuzón sobre el eje largo del cuerpo. Así 360° + 360° vuelve exactamente a vertical.
	basis = (Basis(Vector3.RIGHT, total_pitch) * Basis(Vector3.BACK, -total_roll) * Basis(Vector3.UP, total_twist)).orthonormalized()

func _axis_rate(target: float, total: float, time_left: float, assist: float, mult: float,
		rmin: float, rmax: float, rpro: float) -> float:
	if target == 0.0:
		return 0.0
	var s := signf(target)
	var remaining := (target - total) * s       # >0 si falta girar
	var pro := rpro * s * mult
	if remaining <= 0.0:
		# Objetivo completado: con ayudas el cuerpo se abre y deja de girar.
		return pro * (1.0 - assist)
	var needed := clampf(remaining / time_left, rmin, rmax) * s
	# Con agrupación se gira algo más rápido aunque haya ayudas (llega antes y queda margen).
	var assisted := needed * (mult if mult > 1.0 else 1.0)
	return lerpf(pro, assisted, assist)

## Ángulo entre el "arriba" del cuerpo y la vertical.
func upright_error() -> float:
	return (basis * Vector3.UP).angle_to(Vector3.UP)

## Giro horizontal resultante (tirabuzones) para reorientar al personaje al aterrizar.
func landing_yaw() -> float:
	var f := basis * Vector3.FORWARD
	f.y = 0.0
	if f.length() < 0.2:
		return 0.0
	return Vector3.FORWARD.signed_angle_to(f.normalized(), Vector3.UP)

## Identifica el truco realizado a partir de las rotaciones acumuladas.
func evaluate() -> Dictionary:
	var p := absf(total_pitch)
	var r := absf(total_roll)
	var tw := absf(total_twist)
	var pn := int(floor((p + deg_to_rad(45.0)) / TAU))
	var rn := int(floor((r + deg_to_rad(45.0)) / TAU))
	var th := int(floor((tw + deg_to_rad(40.0)) / PI))   # medias vueltas de tirabuzón
	var moving := takeoff_speed > 4.0
	var name := ""
	if pn >= 1:
		var back := total_pitch > 0.0
		if back:
			if th == 0:
				if takeoff_kind == "wall" and pn == 1:
					name = "Wall Flip"
				elif pn == 1:
					name = "Gainer" if moving else "Backflip"
				elif pn == 2:
					name = "Double Gainer" if moving else "Double Backflip"
				else:
					name = "Triple Backflip"
			elif th == 1:
				name = "Cheat Gainer" if moving else "Back Half"
			elif th <= 3:
				name = "Double Cork" if pn >= 2 else ("Cork" if th == 2 else "Cork 540")
			else:
				name = "Double Cork 1080" if pn >= 2 else "Cork 720"
		else:
			if th == 0:
				if pn == 1:
					name = "Webster" if moving else "Frontflip"
				else:
					name = "Double Front"
			elif th == 1:
				name = "Arabian"
			else:
				name = "Front Full" if th <= 3 else "Front Double Full"
	elif rn >= 1:
		if th >= 2:
			name = "Raiz Twist"
		elif th == 1:
			name = "Raiz"
		elif rn >= 2:
			name = "Double Aerial" if moving else "Double Sideflip"
		else:
			name = "Aerial" if moving else "Sideflip"
	elif th >= 2:
		name = "Butterfly Twist" if th < 4 else "Butterfly Twist 720"
	if name == "":
		return {}
	var difficulty := 1.0 + (pn - 1) * 1.6 + rn * 1.0 + th * 0.55
	if pn >= 1 and rn == 0:
		difficulty = 1.0 + (pn - 1) * 1.8 + th * 0.6
	if takeoff_kind == "wall":
		difficulty += 0.4
	return {"name": name, "difficulty": difficulty, "flips": pn, "rolls": rn, "twist_halves": th,
		"air_time": air_time}
