class_name TrickSystem
extends RefCounted
## Control corporal en el aire.
##
## El cuerpo gira sobre cuatro ejes con velocidad angular propia:
##   pitch  mortal atrás (+) / adelante (-)        → Backflip, Frontflip, Gainer, Webster
##   roll   mortal lateral (cabeza a la derecha +)  → Sideflip (siempre encogido)
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
var takeoff_detail := ""             # vault concreto (Kong Vault...) o pared (wallrun, wallclimb, tictac)
var takeoff_speed := 0.0
var air_time := 0.0
var max_height := 0.0
var _new_axes: Array[String] = []
var _recal: Array[String] = []       # ejes con más vueltas pedidas: recalibrar velocidad
var drive := 0.0                     # -1 frenar/abrir · 0 neutro · +1 empujar/agrupar (joystick, botón)
var twist_manual := false            # tirabuzón controlado con el joystick GIRO (en cuartos de vuelta)
var twist_hold := false              # el joystick GIRO está inclinado ahora mismo
var tuck_time := 0.0                 # tiempo agrupado (lateral agrupado = sideflip; abierto = aerial)
var travel_speed := 0.0              # velocidad horizontal total al despegar (takeoff_speed = hacia delante)
var twist_boost := 1.0               # giro heredado de un enlace (hook, raiz, scoot → cork / b-twist)
var linked := false                  # sale de un enlace (rondada, flic-flac, hook...)
## Botonera / rueda: mientras se mantiene el botón del mortal el cuerpo sigue agrupado y
## girando (doble, triple... lo que permita la altura). Con ayuda se abre solo si ya no queda
## altura para otra vuelta completa.
var keep_spinning := false
const QUARTER := PI * 0.5

## Fracción del vuelo en la que cada acrobacia completa su vuelta SIN agruparse. Agrupado
## (hasta ×tuck_mult, de forma progresiva) termina antes y queda tiempo para abrirse.
## Cada truco tiene su ritmo: el backflip es explosivo, el butterfly es amplio y lento.
const CORK_TWIST_AT := 1.05          # ~60° de inversión antes de cerrar el tirabuzón del cork
const CORK_TILT := 0.38               # inclinación del eje del cork (~22°)
const COMPLETE_AT := {"back": 0.76, "front": 0.78, "side": 0.76, "aerial": 0.76, "cork": 0.78,
	"butterfly": 0.72, "kick": 0.64,
	# Suelo: el giro dura casi todo el vuelo (apoyo de manos, sin agrupar)
	"cartwheel": 0.8, "roundoff": 0.78, "bhs": 0.72, "fhs": 0.74}

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
	drive = 0.0
	twist_period = TAU
	takeoff_kind = kind
	takeoff_detail = ""
	takeoff_speed = speed
	air_time = 0.0
	max_height = 0.0
	_new_axes.clear()
	_recal.clear()
	twist_manual = false
	twist_hold = false
	tuck_time = 0.0
	travel_speed = absf(speed)
	twist_boost = 1.0
	linked = false

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

## Gesto / joystick derecho en 8 direcciones (x derecha, y arriba):
##   ↓ backflip · ↑ frontflip · ←/→ sideflip (encogido) · ↙/↘ mortal atrás + tirabuzón (cork)
##   ↗ mortal adelante + tirabuzón (Front Full) · ↖ adelante + giro lateral: Aerial (parado)
##   o Butterfly Kick (con carrera)
## Durante un mortal: gesto lateral = añadir tirabuzón; misma dirección = otra vuelta.
## allow_twist = false (doble joystick): la rueda de SALTO solo hace mortales; los tirabuzones
## son exclusivamente del joystick GIRO.
func apply_flick(d: Vector2, allow_twist := true) -> void:
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
			1:
				_start_axis("pitch", -1); _start_axis("twist", 1); twist_period = PI
				goal.twist = 2; style = "front"
			3:
				if takeoff_speed > 4.0:
					_start_axis("spin", 1); style = "butterfly"
				else:
					_start_axis("roll", -1); style = "aerial"
	else:
		if not allow_twist and horizontal and dir.roll == 0:
			return                           # zona LATERAL durante un mortal adelante/atrás: no gira
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
					if not _recal.has(ax):
						_recal.append(ax)
	flicks += 1
	active = true

## Joystick SALTO (modo gestos): solo mortales, nunca tirabuzones. Por ángulo (x derecha, y arriba):
##   ↑ mortal adelante (webster con carrera) · ↗ ↖ aerial hacia ese lado (butterfly con carrera)
##   ← → mortal lateral · ↓ mortal atrás · ↘ ↙ gainer (mortal atrás avanzando)
## Durante un mortal, la misma dirección = otra vuelta; otra dirección no cambia el giro.
func apply_salto(d: Vector2) -> void:
	if d.length() < 0.1:
		return
	var sector := int(round(rad_to_deg(atan2(d.y, d.x)) / 45.0))
	if sector == -4:
		sector = 4
	var any := false
	for ax in AXES:
		if dir[ax] != 0:
			any = true
	if any:
		var ax := primary_axis()
		var same: bool = (ax == "pitch" and ((sector in [-2, -1, -3] and dir.pitch == 1) or (sector == 2 and dir.pitch == -1))) \
			or (ax == "roll" and sector in [0, 4, 1, 3]) or (ax == "spin" and sector in [1, 3])
		if same and ax != "twist":
			settled[ax] = false
			goal[ax] += 1
			if not _recal.has(ax):
				_recal.append(ax)
			flicks += 1
		return
	match sector:
		2:
			_start_axis("pitch", -1); style = "front"
		1, 3:
			var sd := 1 if sector == 1 else -1
			if takeoff_speed > 4.0:
				_start_axis("spin", -sd); style = "butterfly"
			else:
				_start_axis("roll", sd); style = "aerial"
		0, 4:
			_start_axis("roll", 1 if sector == 0 else -1); style = "side"
		-2:
			_start_axis("pitch", 1); style = "back"
		-1, -3:
			_start_axis("pitch", 1); style = "back"
			takeoff_speed = maxf(takeoff_speed, 4.5)      # gainer: mortal atrás avanzando
	flicks += 1
	active = true

## Movimientos de suelo (joystick derecho sin SALTO): rueda, rondada, flic-flac, paloma.
func start_ground(kind: String, side: int) -> void:
	match kind:
		"cartwheel":
			_start_axis("roll", side)
		"roundoff":
			_start_axis("roll", side)
			_start_axis("twist", side)
			twist_period = PI
			goal.twist = 1                    # media vuelta: cae mirando hacia atrás
		"bhs":
			_start_axis("pitch", 1)
		"fhs":
			_start_axis("pitch", -1)
	style = kind
	flicks += 1
	active = true

## Giro sobre el eje largo con el cuerpo vertical (patadas giratorias 360/540/720...).
## Sin acrobacia en curso: empieza un giro de 360 (cada toque más suma media vuelta).
## Durante un mortal: añade un tirabuzón completo (Back Full, Front Full, Gainer Full...).
func apply_kick(d := 1) -> void:
	var any := false
	for ax in AXES:
		if dir[ax] != 0:
			any = true
	if not any:
		style = "kick"
		twist_period = PI
		_start_axis("twist", d)
		goal.twist = 2
	elif dir.twist == 0:
		twist_period = PI
		_start_axis("twist", d)
		goal.twist = 2
	else:
		goal.twist += 1
		settled.twist = false
		if not _recal.has("twist"):
			_recal.append("twist")
	flicks += 1
	active = true

## Joystick GIRO (eje x, -1..1): tirabuzón sobre el eje largo para CUALQUIER mortal.
## Mantenerlo inclinado gira (más inclinado = más rápido); al soltarlo el giro termina en el
## cuarto de vuelta más cercano: ¼ (hyper), ½, ¾, 1 (full), 1½, 2... Sin mortal = pirueta.
func twist_input(x: float, dt: float, t: MoveTuning) -> void:
	var mag := absf(x)
	if mag < 0.35:
		twist_hold = false
		return
	var s := 1 if x > 0.0 else -1
	if not twist_manual:
		if dir.twist != 0 and not settled.twist:
			if s != dir.twist or style != "cork":
				return                   # ya hay un giro automático en curso (rondada, patada)
			# Cork: el GIRO en el mismo sentido toma el control del tirabuzón de la patada (540, 720...)
		twist_manual = true
		dir.twist = s
		settled.twist = false
		if style == "":
			style = "kick"               # giro sin mortal: pirueta / patada giratoria
		active = true
	elif s != dir.twist and absf(total.twist) < 0.3:
		dir.twist = s                    # cambio de idea al principio: cambia el sentido
	# Mortal atrás con carrera + tirabuzón = Cork (eje inclinado)
	# Mortal atrás + tirabuzón: suelto es un PIRU; dentro de un combo (tras TD Raiz, raiz, hook,
	# scoot, rondada/flic-flac... o la entrada de cork) es un CORK.
	if style == "back" and linked and takeoff_kind in ["run", "stand"]:
		style = "cork"
	twist_hold = true
	settled.twist = false
	var r := t.twist_stick_rate * lerpf(0.45, 1.0, clampf((mag - 0.35) / 0.6, 0.0, 1.0)) * twist_boost
	rate.twist = dir.twist * r
	total.twist += rate.twist * dt

## Cuartos de vuelta de tirabuzón completados (con el joystick GIRO).
func twist_quarters() -> int:
	return int(floor((absf(total.twist) + deg_to_rad(25.0)) / QUARTER))

## `push`: 0..1 cuánto se agrupa/empuja el jugador (botón AGRUPAR, dedo en SALTO, joystick
## derecho inclinado hacia el giro); negativo = tirar en contra: abrirse y frenar.
func step(dt: float, push: float, time_left: float, assist: float, t: MoveTuning) -> void:
	air_time += dt
	drive = clampf(push, -1.0, 1.0)
	var held := drive > 0.5
	tucked = held and active
	# Agrupación progresiva: el cuerpo tarda ~0,25 s en cerrarse del todo (y se abre algo más rápido)
	var tuck_target := maxf(drive, 0.0) if active else 0.0
	tuck_amount = move_toward(tuck_amount, tuck_target, dt * (4.0 if tuck_target > tuck_amount else 6.0))
	if not active:
		return
	if drive > 0.5:
		tuck_time += dt
	time_left = maxf(time_left, 0.25)
	for ax in _new_axes:
		var period := TAU
		var lo := t.flip_rate_min
		var hi := t.flip_rate_max
		if ax == "twist":
			lo = t.twist_rate_min
			hi = t.twist_rate_max
		# Calibrado por truco (COMPLETE_AT): una vuelta visible, ni borrón ni cámara lenta.
		var frac: float = COMPLETE_AT.get(style, 0.8)
		var cal := clampf(period / (time_left * frac), lo, hi)
		var pro := t.flip_rate_pro * (1.5 if ax == "twist" else 1.0)
		base[ax] = lerpf(pro, cal, assist)
		rate[ax] = dir[ax] * base[ax] * 0.7         # impulso inicial
	_new_axes.clear()
	# Más vueltas pedidas en el aire: acelera lo justo para completarlas antes de aterrizar
	for ax in _recal:
		var per := twist_period if ax == "twist" else TAU
		var left: float = goal[ax] * per - absf(total[ax])
		var need := left / maxf(time_left * 0.75, 0.05)
		var cap := (t.twist_rate_max if ax == "twist" else t.flip_rate_max) * 1.6
		base[ax] = clampf(maxf(base[ax], need), 0.0, cap)
		rate[ax] = dir[ax] * maxf(absf(rate[ax]), base[ax] * 0.9)
	_recal.clear()

	var open_mult := lerpf(t.open_mult_pro, 1.0, assist)
	if drive < -0.4:
		open_mult *= 0.8                     # tirar en contra: cuerpo extendido, gira más despacio
	spotting = false
	for ax in AXES:
		var s: int = dir[ax]
		if s == 0:
			continue
		if ax == "twist" and twist_manual:
			_step_manual_twist(dt)
			continue
		if ax == "twist" and style == "cork" and not settled.twist:
			# Cork: primero sube la cadera y los hombros van atrás (inversión, como un cheat gainer);
			# el tirabuzón se cierra después, rápido, y termina antes de abrirse para aterrizar.
			var pg := absf(total.pitch)
			if pg < CORK_TWIST_AT and absf(total.twist) < 0.01:
				rate.twist = 0.0
				continue
			var tleft: float = goal.twist * twist_period - absf(total.twist)
			var pleft := maxf(maxf(goal.pitch, 1) * TAU * 0.84 - pg, 0.4)
			var tt := minf(pleft / maxf(absf(rate.pitch), 2.5), time_left * 0.8)
			base.twist = clampf(tleft / maxf(tt, 0.08), base.twist, t.twist_rate_max * 1.8)
		var period := twist_period if ax == "twist" else TAU
		var window := deg_to_rad(lerpf(22.0, 70.0 if ax == "twist" else 120.0, assist) * (1.4 if drive < -0.4 else 1.0))
		var prog: float = total[ax] * s
		var next_stop := (floorf(prog / period + 0.0001) + 1.0) * period
		var rem := next_stop - prog
		# Ayuda alta: al completar las vueltas pedidas el cuerpo se abre aunque sigas agrupado
		# (más vueltas se piden de forma explícita: volver a inclinar / deslizar otra vez).
		# Sin ayuda completa (pro/media) agruparse sigue girando: abrirse a tiempo es cosa tuya.
		var force_spot := held and assist > 0.75 and not keep_spinning
		if keep_spinning and held and ax != "twist":
			# ¿Cabe otra vuelta entera después de esta (agrupándose al máximo)? Si cabe, se pide
			# al acercarse al final de la vuelta; si no, con ayuda se abre ya para aterrizar.
			var cap := t.flip_rate_max * 1.6
			var can_more := time_left > (rem + period) / cap + 0.16
			if can_more and next_stop >= goal[ax] * period - 0.001 and rem < deg_to_rad(40.0):
				goal[ax] += 1
				if not _recal.has(ax):
					_recal.append(ax)
			elif not can_more and assist > 0.25:
				force_spot = true
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
			var want: float = base[ax] * lerpf(open_mult, t.tuck_mult, tuck_amount)
			var cur := move_toward(absf(rate[ax]), want, 65.0 * dt)
			rate[ax] = s * cur
			total[ax] += rate[ax] * dt
	_update_basis()

## Tirabuzón del joystick GIRO: mientras está inclinado ya giró en twist_input; al soltarlo
## termina suavemente en el cuarto de vuelta más cercano (puede corregir unos grados atrás).
func _step_manual_twist(dt: float) -> void:
	if twist_hold or settled.twist:
		if settled.twist:
			rate.twist = 0.0
		return
	var target := roundf(total.twist / QUARTER) * QUARTER
	var spd := maxf(absf(rate.twist) * 0.9, 5.0)
	total.twist = move_toward(total.twist, target, spd * dt)
	rate.twist = signf(target - total.twist) * spd if absf(target - total.twist) > 0.0001 else 0.0
	if absf(total.twist - target) < 0.0001:
		total.twist = target
		rate.twist = 0.0
		settled.twist = true
		if absf(target) < 0.01:
			dir.twist = 0                # toque accidental: sin tirabuzón
			twist_manual = false

func _update_basis() -> void:
	var lean := 0.0
	if dir.spin != 0:
		var frac := fmod(absf(total.spin), TAU) / TAU
		lean = -1.35 * sin(PI * frac)
		if not settled.spin and absf(total.spin) > TAU - 0.05 and dir.twist != 0:
			lean = -1.35
	# Cork: eje fuera de vertical (el cuerpo se inclina hacia el giro durante la inversión)
	var tilt := 0.0
	if style == "cork" and dir.twist != 0:
		var fr := clampf(absf(total.pitch) / (TAU * maxf(goal.pitch, 1)), 0.0, 1.0)
		tilt = CORK_TILT * float(dir.twist) * sin(PI * fr)
	basis = (Basis(Vector3.UP, total.spin) * Basis(Vector3.BACK, tilt) * Basis(Vector3.RIGHT, total.pitch + lean)
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

static func trick_name(pn: int, rn: int, sn: int, th: int, back: bool, moving: bool, wall: bool,
		st := "", kind := "", detail := "") -> String:
	var cork := st == "cork" and th >= 2         # cork = mortal atrás en carrera con tirabuzón completo
	var vaulted := kind == "vault"
	match st:
		"cartwheel":
			if rn >= 1: return "Cartwheel" if th == 0 else "Cartwheel Twist"
		"roundoff":
			if rn >= 1: return "Round-off"
		"bhs":
			if pn >= 1: return "Back Handspring" if th < 2 else "Back Handspring Full"
		"fhs":
			if pn >= 1: return "Front Handspring"
	if pn >= 1:
		if back:
			if th == 0:
				if pn == 1:
					if wall:
						return "Wall Flip" if detail in ["wallclimb", ""] else "Wall Gainer"
					if vaulted:
						if detail.begins_with("Kong") or detail in ["Double Kong", "Kash Vault"]:
							return "Kong Gainer"
						if detail == "Dash Vault": return "Dash Gainer"
						return "Vault Gainer"
					if kind == "ledge": return "Ledge Backflip"
					if detail in ["crescent", "reverse_crescent"]: return "Swing Gainer"
					return "Gainer" if moving else "Backflip"
				if pn == 2:
					return "Double Gainer" if moving else "Double Backflip"
				return "Triple Backflip"
			if cork:
				if pn >= 3: return "Triple Cork"
				if pn == 2: return "Double Cork"
				if th >= 6: return "Cork 1080"
				if th >= 4: return "Cork 720"
				return "Cork" if th <= 2 else "Cork 540"
			if wall:
				return "Wall Full" if th >= 2 else "Wall Half"
			if pn >= 2:
				return "Double Full" if th >= 4 else "Full In"
			match th:
				1: return "Cheat Gainer" if moving else "Back Half"
				2: return "Piru"                 # mortal atrás con tirabuzón de 360
				3: return "Piru 540"
				4, 5: return "Piru 720"
				_: return "Piru 1080"
		if th == 0:
			if pn == 1:
				if wall: return "Wall Front"
				if vaulted:
					return "Dash Bomb" if detail == "Dash Vault" else "Kong Front"
				return "Webster" if moving else "Frontflip"
			return "Double Front" if pn == 2 else "Triple Front"
		if pn >= 2: return "Double Arabian"
		match th:
			1: return "Arabian"
			2: return "Front Full"
			3: return "Rudi"
			_: return "Front Double Full"
	if rn >= 1:
		if st == "aerial" and th == 0:
			return "Double Aerial" if rn >= 2 else "Aerial"
		if th >= 4: return "Aerial Double Twist"
		if th >= 2: return "Aerial Twist"
		if th == 1: return "Raiz"
		if rn >= 2: return "Double Sideflip"
		if wall: return "Wall Sideflip"
		return "Sideflip"
	if sn >= 1:
		if th >= 4: return "Butterfly Twist 720"
		if th >= 2: return "Butterfly Twist"
		return "Butterfly Kick" if sn == 1 else "Double Butterfly"
	if st == "kick":
		match th:
			0, 1: return ""
			2:
				if detail in ["scoot", "crescent", "reverse_crescent", "hook", "td_raiz"]:
					return "Cheat 360 Kick"
				return "Tornado Kick" if moving else "360 Kick"
			3: return "540 Kick"
			4: return "Cheat 720" if moving else "720 Kick"
			5: return "900 Kick"
			_: return "1080 Kick"
	return ""

## Identifica el truco realizado a partir de las rotaciones acumuladas.
func evaluate() -> Dictionary:
	var c := counts()
	var tq := -1
	if twist_manual:
		tq = twist_quarters()
		c.th = tq / 2
	var name := trick_name(c.pn, c.rn, c.sn, c.th, total.pitch > 0.0, takeoff_speed > 4.0, takeoff_kind == "wall",
		style, takeoff_kind, takeoff_detail)
	if name == "":
		return {}
	if tq > 0 and tq % 2 == 1:
		name += " Hyper" if tq == 1 else " +¼"    # cuarto de vuelta: aterriza de lado
	var difficulty: float = 1.0 + (c.pn - 1) * 1.8 + c.th * 0.6
	if c.pn == 0:
		difficulty = 0.9 + (c.rn + c.sn - 1) * 1.6 + c.th * 0.6
	if style == "kick":
		difficulty = 0.6 + (c.th - 2) * 0.55
	var ground_diff := {"cartwheel": 0.5, "roundoff": 0.7, "fhs": 0.8, "bhs": 0.9}
	if ground_diff.has(style):
		difficulty = ground_diff[style]
	if linked:
		difficulty += 0.5                    # enlace (rondada → mortal, hook → cork...)
	if takeoff_kind == "vault":
		difficulty += 0.5
	if takeoff_speed > 4.0:
		difficulty += 0.15
	if takeoff_kind == "wall":
		difficulty += 0.4
	if tq > 0 and tq % 2 == 1:
		difficulty += 0.3
	return {"name": name, "difficulty": difficulty, "chain": linked, "from": takeoff_detail if linked else "", "flips": c.pn, "rolls": c.rn, "spins": c.sn,
		"twist_halves": c.th, "twist_quarters": tq if tq >= 0 else c.th * 2, "air_time": air_time}

## Nombre en directo para el HUD (lo que se está ejecutando ahora mismo).
func live_name() -> String:
	var e := evaluate()
	if not e.is_empty():
		return e.name
	match style:
		"back": return "Gainer" if takeoff_speed > 4.0 else "Backflip"
		"front": return "Webster" if takeoff_speed > 4.0 else "Frontflip"
		"side": return "Sideflip"
		"aerial": return "Aerial"
		"cartwheel": return "Cartwheel"
		"roundoff": return "Round-off"
		"bhs": return "Back Handspring"
		"fhs": return "Front Handspring"
		"cork": return "Cork"
		"butterfly": return "Butterfly Kick"
		"kick": return "Tornado Kick" if takeoff_speed > 4.0 else "360 Kick"
	return ""
