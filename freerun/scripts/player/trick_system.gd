class_name TrickSystem
extends RefCounted
## Control corporal en el aire.
##
## El cuerpo gira sobre cuatro ejes con velocidad angular propia:
##   pitch  mortal atrás (+) / adelante (-)        → Backflip, Frontflip, Gainer, Webster
##   roll   mortal lateral (cabeza a la derecha +)  → Sideflip, Aerial
##   twist  tirabuzón sobre el eje largo            → Cork, Cork 720, Cheat Gainer
##   spin   giro horizontal con el cuerpo tumbado   → Butterfly Kick
##
## El gesto elige la acrobacia y da el impulso inicial. Después el jugador controla el cuerpo:
##   MANTENER el dedo = agruparse → gira el doble de rápido (dobles, Cork 720...)
##   SOLTAR           = abrirse   → gira más despacio y, al acercarse a la vertical,
##                                   el cuerpo frena suavemente y prepara el aterrizaje.
## La ventana de "spotting" depende de la ayuda: Alta = amplia, Pro = casi nula
## (en Pro hay que soltar justo a tiempo o se aterriza torcido).

const AXES := ["pitch", "roll", "twist", "spin"]

var basis := Basis()                 # orientación del cuerpo relativa a la dirección de despegue
var rate := {}                       # rad/s con signo
var total := {}                      # ángulo acumulado con signo
var dir := {}                        # -1, 0, +1 (eje en uso)
var base := {}                       # velocidad "abierta" calibrada por eje
var settled := {}                    # eje frenado en vertical
var goal := {}                       # vueltas pedidas con gestos (no se abre antes de cumplirlas)
var active := false
var flicks := 0
var tucked := false
var tuck_amount := 0.0               # 0..1 suavizado (animación)
var spotting := false                # preparando el aterrizaje
var style := ""                      # back, front, side, cork, butterfly
var twist_period := TAU              # cork: vueltas completas; tirabuzón añadido: medias vueltas
var takeoff_kind := "run"            # run, stand, wall, vault, ledge
var takeoff_speed := 0.0
var air_time := 0.0
var max_height := 0.0
var _new_axes: Array[String] = []

# Compatibilidad con el resto del código
var pitch_rate: float:
	get: return rate.get("pitch", 0.0)
var roll_rate: float:
	get: return rate.get("roll", 0.0)
var twist_rate: float:
	get: return rate.get("twist", 0.0)
var total_pitch: float:
	get: return total.get("pitch", 0.0)
var total_roll: float:
	get: return total.get("roll", 0.0)
var total_twist: float:
	get: return total.get("twist", 0.0)
var total_spin: float:
	get: return total.get("spin", 0.0)

func _init() -> void:
	reset()

func reset(kind := "run", speed := 0.0) -> void:
	basis = Basis()
	for ax in AXES:
		rate[ax] = 0.0
		total[ax] = 0.0
		dir[ax] = 0
		base[ax] = 0.0
		settled[ax] = false
		goal[ax] = 0
	active = false
	flicks = 0
	tucked = false
	tuck_amount = 0.0
	spotting = false
	style = ""
	twist_period = TAU
	takeoff_kind = kind
	takeoff_speed = speed
	air_time = 0.0
	max_height = 0.0
	_new_axes.clear()

func has_rotation() -> bool:
	if not active:
		return false
	var s := 0.0
	for ax in AXES:
		s += absf(total[ax])
	return s > 0.3

func all_settled() -> bool:
	if not active:
		return true
	for ax in AXES:
		if dir[ax] != 0 and not settled[ax]:
			return false
	return true

func _start_axis(ax: String, s: int) -> void:
	dir[ax] = s
	settled[ax] = false
	goal[ax] = maxi(goal[ax], 1)
	if base[ax] == 0.0:
		_new_axes.append(ax)

## Gesto en 8 direcciones (x derecha, y arriba):
##   ↓ backflip · ↑ frontflip · ←/→ lateral · ↙/↘ cork · ↖/↗ butterfly kick
## Durante un mortal: gesto lateral = añadir tirabuzón; misma dirección = otra vuelta.
func apply_flick(d: Vector2) -> void:
	if d.length() < 0.1:
		return
	var sector := int(round(rad_to_deg(atan2(d.y, d.x)) / 45.0))
	if sector == -4:
		sector = 4
	var horizontal := sector == 0 or sector == 4
	var hs := 1 if sector == 0 else -1
	var any := false
	for ax in AXES:
		if dir[ax] != 0:
			any = true
	if not any:
		match sector:
			-2:
				_start_axis("pitch", 1); style = "back"
			2:
				_start_axis("pitch", -1); style = "front"
			0, 4:
				_start_axis("roll", hs); style = "side"
			-1, -3:
				_start_axis("pitch", 1); _start_axis("twist", 1 if sector == -1 else -1); style = "cork"
			1, 3:
				_start_axis("spin", -1 if sector == 1 else 1); style = "butterfly"
	else:
		if horizontal and (dir.pitch != 0 or dir.spin != 0):
			if dir.twist == 0:
				_start_axis("twist", hs)
				twist_period = PI
			elif dir.twist == hs:
				base.twist = minf(base.twist * 2.0, 26.0)   # segundo gesto: tirabuzón doble
				goal.twist += 1
				settled.twist = false
			else:
				settled.twist = false
		elif sector in [-1, -3] and dir.pitch == 1 and dir.twist == 0:
			_start_axis("twist", 1 if sector == -1 else -1)
			style = "cork"
		else:
			# Misma dirección: otra vuelta con un empujón
			for ax in ["pitch", "roll", "spin"]:
				if dir[ax] != 0:
					settled[ax] = false
					goal[ax] += 1
					rate[ax] *= 1.3
	flicks += 1
	active = true

func step(dt: float, held: bool, time_left: float, assist: float, t: MoveTuning) -> void:
	air_time += dt
	tucked = held and active
	tuck_amount = move_toward(tuck_amount, 1.0 if tucked else 0.0, dt * 9.0)
	if not active:
		return
	time_left = maxf(time_left, 0.25)
	for ax in _new_axes:
		var period := TAU
		var lo := t.flip_rate_min
		var hi := t.flip_rate_max
		if ax == "twist":
			lo = t.twist_rate_min
			hi = t.twist_rate_max
		# Calibrado para completar la vuelta al ~80 % del vuelo: queda tiempo para abrirse.
		var cal := clampf(period / (time_left * 0.8), lo, hi)
		var pro := t.flip_rate_pro * (1.5 if ax == "twist" else 1.0)
		base[ax] = lerpf(pro, cal, assist)
		rate[ax] = dir[ax] * base[ax] * 0.7         # impulso inicial
	_new_axes.clear()

	var hold_mult := t.tuck_mult
	var open_mult := lerpf(t.open_mult_pro, 0.92, assist)
	spotting = false
	for ax in AXES:
		var s: int = dir[ax]
		if s == 0:
			continue
		var period := twist_period if ax == "twist" else TAU
		var window := deg_to_rad(lerpf(22.0, 70.0 if ax == "twist" else 120.0, assist))
		var prog: float = total[ax] * s
		var next_stop := (floorf(prog / period + 0.0001) + 1.0) * period
		var rem := next_stop - prog
		# Ayuda alta: si mantienes y ya no cabe otra vuelta completa, el cuerpo se abre solo.
		var cur_mag := maxf(absf(rate[ax]), 0.1)
		var force_spot := assist > 0.75 and held and time_left < (rem + period * 0.9) / cur_mag
		if settled[ax]:
			if held and not force_spot:
				settled[ax] = false
			else:
				rate[ax] = 0.0
				continue
		var goal_ok: bool = next_stop >= goal[ax] * period - 0.001
		var spot := (not held or force_spot) and rem < window and goal_ok
		if spot:
			spotting = true
			# Frenado suave hasta quedar exactamente en vertical
			var mag := minf(absf(rate[ax]), rem / 0.09 + 0.8)
			var adv := minf(maxf(mag, 1.5) * dt, rem)
			total[ax] += s * adv
			rate[ax] = s * mag
			if rem - adv <= 0.0005:
				total[ax] = s * next_stop
				rate[ax] = 0.0
				settled[ax] = true
		else:
			var want: float = base[ax] * (hold_mult if held else open_mult)
			var cur := move_toward(absf(rate[ax]), want, 65.0 * dt)
			rate[ax] = s * cur
			total[ax] += rate[ax] * dt
	_update_basis()

func _update_basis() -> void:
	var lean := 0.0
	if dir.spin != 0:
		var frac := fmod(absf(total.spin), TAU) / TAU
		lean = -1.35 * sin(PI * frac)
		if not settled.spin and absf(total.spin) > TAU - 0.05 and dir.twist != 0:
			lean = -1.35
	basis = (Basis(Vector3.UP, total.spin) * Basis(Vector3.RIGHT, total.pitch + lean)
		* Basis(Vector3.BACK, -total.roll) * Basis(Vector3.UP, total.twist)).orthonormalized()

## Ángulo entre el "arriba" del cuerpo y la vertical.
func upright_error() -> float:
	return (basis * Vector3.UP).angle_to(Vector3.UP)

## Giro horizontal resultante (tirabuzones/butterfly) para reorientar al aterrizar.
func landing_yaw() -> float:
	var f := basis * Vector3.FORWARD
	f.y = 0.0
	if f.length() < 0.2:
		return 0.0
	return Vector3.FORWARD.signed_angle_to(f.normalized(), Vector3.UP)

## Eje principal y su ángulo actual (para el indicador del HUD).
func primary_axis() -> String:
	if dir.pitch != 0: return "pitch"
	if dir.roll != 0: return "roll"
	if dir.spin != 0: return "spin"
	return "twist"

func counts() -> Dictionary:
	return {
		"pn": int(floor((absf(total.pitch) + deg_to_rad(50.0)) / TAU)),
		"rn": int(floor((absf(total.roll) + deg_to_rad(50.0)) / TAU)),
		"sn": int(floor((absf(total.spin) + deg_to_rad(50.0)) / TAU)),
		"th": int(floor((absf(total.twist) + deg_to_rad(40.0)) / PI)),
	}

static func trick_name(pn: int, rn: int, sn: int, th: int, back: bool, moving: bool, wall: bool) -> String:
	if pn >= 1:
		if back:
			if th == 0:
				if pn == 1:
					if wall: return "Wall Flip"
					return "Gainer" if moving else "Backflip"
				if pn == 2:
					return "Double Gainer" if moving else "Double Backflip"
				return "Triple Backflip"
			if th == 1:
				return "Cheat Gainer" if moving else "Back Half"
			if pn >= 2:
				return "Double Cork"
			if th >= 4:
				return "Cork 720"
			return "Cork" if th == 2 else "Cork 540"
		if th == 0:
			if pn == 1:
				return "Webster" if moving else "Frontflip"
			return "Double Front"
		return "Arabian" if th == 1 else "Front Full"
	if rn >= 1:
		if th >= 2: return "Aerial Twist"
		if th == 1: return "Raiz"
		if rn >= 2: return "Double Aerial" if moving else "Double Sideflip"
		return "Aerial" if moving else "Sideflip"
	if sn >= 1:
		if th >= 4: return "Butterfly Twist 720"
		if th >= 2: return "Butterfly Twist"
		return "Butterfly Kick" if sn == 1 else "Double Butterfly"
	return ""

## Identifica el truco realizado a partir de las rotaciones acumuladas.
func evaluate() -> Dictionary:
	var c := counts()
	var name := trick_name(c.pn, c.rn, c.sn, c.th, total.pitch > 0.0, takeoff_speed > 4.0, takeoff_kind == "wall")
	if name == "":
		return {}
	var difficulty: float = 1.0 + (c.pn - 1) * 1.8 + c.th * 0.6
	if c.pn == 0:
		difficulty = 0.9 + (c.rn + c.sn - 1) * 1.6 + c.th * 0.6
	if takeoff_speed > 4.0:
		difficulty += 0.15
	if takeoff_kind == "wall":
		difficulty += 0.4
	return {"name": name, "difficulty": difficulty, "flips": c.pn, "rolls": c.rn, "spins": c.sn,
		"twist_halves": c.th, "air_time": air_time}

## Nombre en directo para el HUD (lo que se está ejecutando ahora mismo).
func live_name() -> String:
	var e := evaluate()
	if not e.is_empty():
		return e.name
	match style:
		"back": return "Gainer" if takeoff_speed > 4.0 else "Backflip"
		"front": return "Webster" if takeoff_speed > 4.0 else "Frontflip"
		"side": return "Aerial" if takeoff_speed > 4.0 else "Sideflip"
		"cork": return "Cork"
		"butterfly": return "Butterfly Kick"
	return ""
