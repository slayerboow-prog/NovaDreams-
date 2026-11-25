class_name BodyRig
extends Node3D
## Personaje 3D estilizado construido por código (sin assets externos) y animado
## de forma procedural a partir del estado físico del PlayerController:
## ciclo de carrera ligado a la velocidad real, poses de vault, wall run, colgado,
## agrupado/abierto en acrobacias, recepción, rodar y caída.
## La rotación de acrobacias se aplica en `pivot` (centro de masas).

signal footstep(strength: float)

const COM_HEIGHT := 0.95

var player: PlayerController
var pivot: Node3D
var body: Node3D
var joints := {}
var pose := {}            # rotación actual por articulación
var phase := 0.0
var body_drop := 0.0
var _tilt := Basis()
var _yaw := 0.0
var _serial := -1
var _prev_spd := 0.0
var grab_w := 0.0                 # agrupado: cuánto se agarran las manos a las espinillas (IK)
var wrap_w := 0.0                 # tirabuzón: brazos cruzados pegados al pecho (IK)
const GRAB_KINDS := ["back", "front", "side", "gainer", "chutada"]
var _accel := 0.0                 # aceleración suavizada (inclinación al arrancar/frenar)
# Apoyos (IK): punto del suelo donde está plantada cada mano/pie y peso del apoyo
var plants := {}
var contact_w := {"hl": 0.0, "hr": 0.0, "fl": 0.0, "fr": 0.0}
var ground_y := 0.0
var ik_enabled := true
const ARM_L1 := 0.29
const ARM_L2 := 0.28
const HAND_R := 0.055
const LEG_L1 := 0.43
const LEG_L2 := 0.45
const SOLE := 0.05

# Paleta de identidad propia: sudadera turquesa, pantalón carbón, zapatillas naranja.
# Sudadera negra sin mangas con capucha y logo blanco, jogger cargo negro con franjas blancas,
# muñequeras y zapatillas negras con suela blanca
const COL_HOODIE := Color(0.075, 0.075, 0.085)
const COL_HOODIE_DARK := Color(0.045, 0.045, 0.05)
const COL_PANTS := Color(0.065, 0.065, 0.075)
const COL_PANTS_DARK := Color(0.04, 0.04, 0.045)
const COL_SKIN := Color(0.8, 0.58, 0.44)
const COL_SKIN_DARK := Color(0.68, 0.47, 0.35)
const COL_HAIR := Color(0.05, 0.04, 0.035)
const COL_EYE := Color(0.08, 0.07, 0.07)
const COL_SHOES := Color(0.07, 0.07, 0.08)
const COL_STRIPE := Color(0.92, 0.92, 0.9)
const COL_SOLE := Color(0.95, 0.95, 0.92)
const COL_CAP := Color(0.95, 0.95, 0.92)

## Capturas de movimiento reales (CMU) que sustituyen a la animación hecha a mano.
const MOCAP_FLIPS := {"back": "res://assets/mocap/backflip.json"}
const MOCAP_PREP := 30.0                  # fotogramas de la captura que dura la flexión antes de despegar
var mocap := {}                           # tipo de mortal -> MocapClip
var mocap_active := ""                    # clip que manda en la pose este fotograma
var _force_blend := 0.0
var _mocap_recent := 0.0                  # tras una captura, la pose siguiente entra deprisa (sin arrastrar la pierna)

func setup(p: PlayerController) -> void:
	player = p
	for k in MOCAP_FLIPS.keys():
		var c := MocapClip.load_clip(MOCAP_FLIPS[k])
		if c:
			mocap[k] = c
	# El muñeco se anima en cada fotograma (_process): sin interpolación física, para que las piezas
	# rígidas (cabeza, manos, zapatillas) y la piel se dibujen en la misma pose. Con interpolación
	# las piezas iban un paso por detrás de la piel y en movimientos rápidos se separaban.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	pivot = Node3D.new()
	pivot.position.y = COM_HEIGHT
	add_child(pivot)
	body = Node3D.new()
	body.position.y = -COM_HEIGHT
	pivot.add_child(body)
	_build()

var _mats := {}
func _mat(c: Color, rough := 0.7) -> StandardMaterial3D:
	var key := "%s_%.2f" % [c.to_html(), rough]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	_mats[key] = m
	return m

func _joint(name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.name = name
	j.position = pos
	parent.add_child(j)
	joints[name] = j
	pose[name] = Vector3.ZERO
	return j

func _capsule(parent: Node3D, radius: float, length: float, color: Color, offset := Vector3.ZERO, scl := Vector3.ONE, rot := Vector3.ZERO, rough := 0.75) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = maxf(length, radius * 2.0)
	m.radial_segments = 12
	m.rings = 4
	mi.mesh = m
	mi.material_override = _mat(color, rough)
	mi.position = offset
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi

func _box(parent: Node3D, size: Vector3, color: Color, offset := Vector3.ZERO, rot := Vector3.ZERO, rough := 0.75) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = _mat(color, rough)
	mi.position = offset
	mi.rotation = rot
	parent.add_child(mi)
	return mi

## Elipsoide (esfera escalada): cabeza, pecho, glúteos, músculos...
func _ellipsoid(parent: Node3D, radii: Vector3, color: Color, offset := Vector3.ZERO, rot := Vector3.ZERO, rough := 0.75, seg := 14) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 1.0
	m.height = 2.0
	m.radial_segments = seg
	m.rings = maxi(6, seg / 2)
	mi.mesh = m
	mi.material_override = _mat(color, rough)
	mi.position = offset
	mi.rotation = rot
	mi.scale = radii
	parent.add_child(mi)
	return mi

## Personaje con proporciones humanas (~1,78 m): cabeza con cara, cuello, tronco con pecho y
## hombros, brazos con bíceps y antebrazo afinado, manos con dedos, muslos, gemelos y zapatillas
## con suela. Mismo esqueleto (articulaciones y longitudes) que usan las animaciones y la IK.
func _build() -> void:
	var details: Array[MeshInstance3D] = []       # piezas pequeñas: sin sombra (rendimiento móvil)
	var pelvis := _joint("pelvis", body, Vector3(0, 0.95, 0))
	var spine := _joint("spine", pelvis, Vector3(0, 0.06, 0))
	# Sudadera: bolsillo canguro, capucha a la espalda y cordones (el tronco es la malla con piel)
	details.append(_box(spine, Vector3(0.2, 0.085, 0.006), COL_HOODIE.lerp(COL_HOODIE_DARK, 0.45), Vector3(0, 0.085, -0.104), Vector3(-0.08, 0, 0), 0.9))
	_ellipsoid(spine, Vector3(0.13, 0.085, 0.07), COL_HOODIE_DARK, Vector3(0, 0.47, 0.095), Vector3(0.35, 0, 0), 0.9)
	# Logo blanco en la espalda: estrella de cuatro puntas con una punta larga hacia abajo
	for k in 4:
		var ang := float(k) * PI * 0.5
		var ln := 0.11 if k == 2 else 0.06
		details.append(_box(spine, Vector3(0.02, ln, 0.004), COL_STRIPE, Vector3(sin(ang) * ln * 0.5, 0.32 + cos(ang) * ln * 0.5, 0.122), Vector3(0, 0, -ang), 0.7))
		details.append(_box(spine, Vector3(0.012, 0.045, 0.004), COL_STRIPE, Vector3(sin(ang + 0.785) * 0.022, 0.32 + cos(ang + 0.785) * 0.022, 0.122), Vector3(0, 0, -ang - 0.785), 0.7))
	details.append(_capsule(spine, 0.006, 0.12, COL_SOLE, Vector3(-0.035, 0.385, -0.118), Vector3.ONE, Vector3(0.1, 0, 0)))
	details.append(_capsule(spine, 0.006, 0.12, COL_SOLE, Vector3(0.035, 0.385, -0.118), Vector3.ONE, Vector3(0.1, 0, 0)))
	var neck := _joint("neck", spine, Vector3(0, 0.54, 0))
	# Cabeza: cráneo, mandíbula y mentón, pómulos, nariz, ojos con blanco e iris, cejas, labios,
	# orejas y pelo con volumen (corte corto con tupé)
	var skin_mat_r := 0.55
	_ellipsoid(neck, Vector3(0.094, 0.124, 0.106), COL_SKIN, Vector3(0, 0.168, -0.006), Vector3.ZERO, skin_mat_r, 24)
	details.append(_ellipsoid(neck, Vector3(0.068, 0.05, 0.07), COL_SKIN, Vector3(0, 0.104, -0.03), Vector3.ZERO, skin_mat_r, 18))     # mandíbula
	details.append(_ellipsoid(neck, Vector3(0.028, 0.02, 0.024), COL_SKIN, Vector3(0, 0.072, -0.072), Vector3.ZERO, skin_mat_r, 10))   # mentón
	for x in [-1.0, 1.0]:
		details.append(_ellipsoid(neck, Vector3(0.017, 0.012, 0.008), Color(0.96, 0.95, 0.93), Vector3(0.036 * x, 0.193, -0.099), Vector3.ZERO, 0.3, 10))
		details.append(_ellipsoid(neck, Vector3(0.0085, 0.0095, 0.006), COL_EYE, Vector3(0.036 * x, 0.193, -0.105), Vector3.ZERO, 0.2, 8))
		details.append(_ellipsoid(neck, Vector3(0.02, 0.0055, 0.007), COL_HAIR, Vector3(0.037 * x, 0.214, -0.103), Vector3(0, 0, -0.15 * x), 0.9, 8))
		details.append(_ellipsoid(neck, Vector3(0.012, 0.03, 0.02), COL_SKIN_DARK, Vector3(0.099 * x, 0.172, 0.006), Vector3(0, 0.25 * x, 0), skin_mat_r, 10))   # oreja
	details.append(_ellipsoid(neck, Vector3(0.011, 0.024, 0.014), COL_SKIN, Vector3(0, 0.163, -0.108), Vector3(0.35, 0, 0), skin_mat_r, 10))   # nariz
	details.append(_ellipsoid(neck, Vector3(0.017, 0.009, 0.011), COL_SKIN, Vector3(0, 0.146, -0.11), Vector3.ZERO, skin_mat_r, 8))     # punta y aletas
	details.append(_ellipsoid(neck, Vector3(0.024, 0.0065, 0.01), Color(0.66, 0.4, 0.36), Vector3(0, 0.122, -0.1), Vector3.ZERO, 0.5, 10))   # labios
	_ellipsoid(neck, Vector3(0.103, 0.075, 0.114), COL_HAIR, Vector3(0, 0.238, 0.004), Vector3(-0.12, 0, 0), 0.95, 18)
	details.append(_ellipsoid(neck, Vector3(0.085, 0.03, 0.05), COL_HAIR, Vector3(0, 0.275, -0.062), Vector3(-0.45, 0, 0), 0.95, 12))   # flequillo hacia arriba
	_ellipsoid(neck, Vector3(0.1, 0.065, 0.05), COL_HAIR, Vector3(0, 0.2, 0.072), Vector3.ZERO, 0.95, 12)              # nuca
	for x in [-1.0, 1.0]:
		details.append(_ellipsoid(neck, Vector3(0.012, 0.045, 0.04), COL_HAIR, Vector3(0.096 * x, 0.215, 0.02), Vector3.ZERO, 0.95, 8))   # patillas
	# Brazos y manos (la manga y el antebrazo son la malla con piel; la mano va en el codo)
	for side in [["l", -1.0], ["r", 1.0]]:
		var sd: String = side[0]
		var x: float = side[1]
		var sh := _joint("shoulder_" + sd, spine, Vector3(0.23 * x, 0.47, 0))
		var el := _joint("elbow_" + sd, sh, Vector3(0, -0.29, 0))
		_ellipsoid(el, Vector3(0.037, 0.048, 0.017), COL_SKIN, Vector3(0, -0.282, -0.002), Vector3.ZERO, skin_mat_r, 12)   # palma
		for f in 4:
			var fx := (-0.024 + 0.016 * f) * x
			var fl := 0.05 if f in [1, 2] else 0.042
			details.append(_capsule(el, 0.0085, fl, COL_SKIN, Vector3(fx, -0.335 - (0.004 if f in [1, 2] else 0.0), -0.01), Vector3.ONE, Vector3(0.35, 0, 0), skin_mat_r))
		details.append(_capsule(el, 0.01, 0.05, COL_SKIN, Vector3(-0.038 * x, -0.275, -0.02), Vector3.ONE, Vector3(0.4, 0, 0.55 * x), skin_mat_r))   # pulgar
	# Piernas y zapatillas (pantalón y piernas son la malla con piel; la zapatilla va en la rodilla)
	for side in [["l", -1.0], ["r", 1.0]]:
		var sd: String = side[0]
		var x: float = side[1]
		var hip := _joint("hip_" + sd, pelvis, Vector3(0.1 * x, -0.02, 0))
		var knee := _joint("knee_" + sd, hip, Vector3(0, -0.43, 0))
		# Jogger cargo: franja blanca por fuera del muslo y de la pierna, bolsillo cargo y correa en la rodilla
		details.append(_box(hip, Vector3(0.012, 0.32, 0.014), COL_STRIPE, Vector3(0.1 * x, -0.22, 0.0), Vector3(0, 0, 0.084 * x), 0.8))
		details.append(_box(knee, Vector3(0.011, 0.23, 0.013), COL_STRIPE, Vector3(0.066 * x, -0.185, 0.004), Vector3(0, 0, 0.08 * x), 0.8))
		details.append(_box(hip, Vector3(0.03, 0.13, 0.1), COL_PANTS_DARK, Vector3(0.095 * x, -0.27, -0.005), Vector3(0, 0, 0.05 * x), 0.9))
		details.append(_box(hip, Vector3(0.033, 0.012, 0.104), COL_STRIPE, Vector3(0.097 * x, -0.205, -0.005), Vector3(0, 0, 0.05 * x), 0.8))
		# Zapatilla redondeada: talón, empeine, puntera, suela con canto y cordones
		_ellipsoid(knee, Vector3(0.05, 0.05, 0.065), COL_SHOES, Vector3(0, -0.425, 0.03), Vector3.ZERO, 0.6, 14)
		_ellipsoid(knee, Vector3(0.052, 0.04, 0.11), COL_SHOES, Vector3(0, -0.445, -0.06), Vector3.ZERO, 0.6, 14)
		_ellipsoid(knee, Vector3(0.05, 0.03, 0.05), COL_SHOES, Vector3(0, -0.455, -0.14), Vector3.ZERO, 0.6, 12)
		_box(knee, Vector3(0.112, 0.026, 0.285), COL_SOLE, Vector3(0, -0.482, -0.045), Vector3.ZERO, 0.8)
		details.append(_box(knee, Vector3(0.114, 0.006, 0.287), Color(0.25, 0.25, 0.27), Vector3(0, -0.495, -0.045)))   # canto de la suela
		details.append(_box(knee, Vector3(0.045, 0.01, 0.085), COL_SOLE, Vector3(0, -0.41, -0.075), Vector3(-0.35, 0, 0)))  # cordones
		details.append(_ellipsoid(knee, Vector3(0.052, 0.012, 0.045), COL_SOLE, Vector3(0, -0.385, 0.03), Vector3.ZERO, 0.7, 10))  # cuello acolchado
	# Tronco, cuello, brazos y piernas: una malla continua con piel que se dobla en las articulaciones
	skin_body = SkinBody.new()
	skin_body.name = "SkinBody"
	body.add_child(skin_body)
	skin_body.build(joints, {"hoodie": COL_HOODIE, "hoodie_dark": COL_HOODIE_DARK, "pants": COL_PANTS,
		"pants_dark": COL_PANTS_DARK, "skin": COL_SKIN, "sock": Color(0.92, 0.92, 0.9), "band": COL_STRIPE,
		"wrist": Color(0.06, 0.06, 0.07)})
	for mi in find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for mi in details:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Atleta realista: si el modelo carga, sustituye a la vista procedural (que sigue existiendo
	# por debajo como esqueleto de referencia, invisible)
	human = HumanModel.new()
	human.name = "Human"
	body.add_child(human)
	if human.build(joints):
		for mi in find_children("*", "MeshInstance3D", true, false):
			if not human.is_ancestor_of(mi):
				(mi as MeshInstance3D).visible = false
	else:
		human.queue_free()
		human = null

var skin_body: SkinBody
var human: HumanModel

# ------------------------------------------------------------------ animación

## Muelle de la pose: frecuencia relativa a blend_speed y amortiguamiento (<1 = leve rebote).
const SPRING_W := 1.9
const SPRING_ZETA := 0.86
# Las rodillas van algo por DELANTE de la cadera (en un mortal suben dobladas hacia el pecho, no
# salen estiradas hacia delante); codos y cuello van un poco por detrás del tronco.
const JOINT_LAG := {"elbow_l": 0.8, "elbow_r": 0.8, "knee_l": 1.25, "knee_r": 1.25, "neck": 0.75}
var _pose_vel := {}

func _base_pose() -> Dictionary:
	var d := {}
	for k in joints.keys():
		d[k] = Vector3.ZERO
	return d

func _process(dt: float) -> void:
	if player == null:
		return
	var st := player.state
	var spd := player.speed()
	grab_w = 0.0
	wrap_w = 0.0
	if dt > 0.0:
		_accel = lerpf(_accel, (spd - _prev_spd) / dt, 1.0 - exp(-8.0 * dt))
	_prev_spd = spd
	var target := _base_pose()
	var tilt := Basis()
	var drop := 0.0
	var blend_speed := 14.0
	mocap_active = ""
	_force_blend = 0.0

	# Orientación horizontal
	var fwd := player.facing
	var yaw_target := atan2(-fwd.x, -fwd.z)
	if player.skill_serial != _serial:
		# Empieza o termina una habilidad: la orientación de salida ya va incluida en su giro
		# (rondada, raiz...), así que se reorienta de golpe en vez de dar una vuelta extra.
		_serial = player.skill_serial
		_yaw = yaw_target
		if st != PlayerController.State.SKILL:
			_tilt = Basis()
	_yaw = lerp_angle(_yaw, yaw_target, 1.0 - exp(-20.0 * dt))
	rotation.y = _yaw
	var smp := {}
	var ground_contacts := {}

	match st:
		PlayerController.State.GROUND:
			if spd > 0.3:
				_run_pose(target, spd, dt)
				# Naturalidad: el tronco se inclina al acelerar y se echa atrás al frenar, y cada
				# zancada sube y baja un poco el cuerpo (más cuanto más rápido)
				var amt := clampf(spd / 9.0, 0.0, 1.0)
				target.spine.x -= clampf(_accel * 0.035, -0.35, 0.4)
				drop += 0.045 * amt * (0.5 + 0.5 * cos(phase * 2.0))      # más bajo a mitad del apoyo
			else:
				_idle_pose(target)
			if player.stun > 0.0:
				drop = 0.18
				target.spine.x = -0.5
				target.hip_l.x = 0.9; target.hip_r.x = 0.7
				target.knee_l.x = -1.4; target.knee_r.x = -1.2
			if player.jump_load > 0.0:
				drop = _load_pose(target)
				blend_speed = 34.0
			var c := player.land_impact
			var big := float(player.last_landing.get("impact", 0.0)) > 9.0 and player.land_timer < 0.7 \
				and player.land_quality in ["perfect", "clean"]
			if c > 0.0 and big:
				# Caída grande: recepción a cuatro apoyos (como en el vídeo de referencia). Cuclillas
				# profundas, tronco adelante, mirada al frente y las dos manos clavadas en el suelo.
				var k4 := _smooth(c / 0.35)
				drop += 0.66 * k4
				_apply(target, {"spine": Vector3(-1.15, 0, 0), "neck": Vector3(0.7, 0, 0),
					"hip_l": Vector3(1.75, 0, -0.18), "hip_r": Vector3(1.7, 0, 0.18),
					"knee_l": Vector3(-2.3, 0, 0), "knee_r": Vector3(-2.25, 0, 0),
					"shoulder_l": Vector3(1.0, 0, -0.2), "shoulder_r": Vector3(1.0, 0, 0.2),
					"elbow_l": Vector3(0.25, 0, 0), "elbow_r": Vector3(0.25, 0, 0)}, k4)
				var hw := _smooth((c - 0.15) / 0.25)
				ground_contacts = {"hl": hw, "hr": hw}
				c = 0.0
			if c > 0.0:
				# Recepción: piernas y tronco absorben el impacto (más profunda cuanto más fuerte).
				drop += 0.34 * c
				target.hip_l.x += 1.15 * c; target.hip_r.x += 1.1 * c
				target.knee_l.x -= 2.0 * c; target.knee_r.x -= 1.95 * c
				target.spine.x -= 0.6 * c
				target.neck.x += 0.25 * c
				match player.land_quality:
					"perfect":
						# Clavada: brazos delante, quieto y firme
						target.shoulder_l.x += 1.3 * c; target.shoulder_r.x += 1.3 * c
						target.shoulder_l.z -= 0.25 * c; target.shoulder_r.z += 0.25 * c
					"clean":
						target.shoulder_l.x += 0.9 * c; target.shoulder_r.x += 0.9 * c
						target.shoulder_l.z -= 0.7 * c; target.shoulder_r.z += 0.7 * c
					_:
						# Torcida o dura: brazos buscando el equilibrio y tronco desplazado
						var w := sin(player.land_timer * 22.0)
						target.shoulder_l.x += (1.6 + 0.8 * w) * c; target.shoulder_r.x += (0.4 - 0.8 * w) * c
						target.shoulder_l.z -= 1.1 * c; target.shoulder_r.z += 1.1 * c
						target.spine.z = 0.25 * w * c
						target.spine.x -= 0.3 * c
			# Tras recibir: brazos abiertos a los lados buscando el equilibrio (oscilan y se recogen)
			var lt := player.land_timer
			var shaky := float(player.last_landing.get("impact", 0.0)) > 9.0 or player.land_quality in ["sloppy", "hard"]
			if shaky and lt > 0.08 and lt < 1.1 and spd < 4.0 and player.jump_load <= 0.0:
				var wb := _smooth((lt - 0.08) / 0.18) * _smooth((1.1 - lt) / 0.45)
				var wob := sin(lt * 9.0) * 0.18 * (1.1 - lt)
				_apply(target, {"shoulder_l": Vector3(0.35 + wob, 0, -1.2 - wob), "shoulder_r": Vector3(0.3 - wob, 0, 1.2 - wob),
					"elbow_l": Vector3(0.25, 0, 0), "elbow_r": Vector3(0.25, 0, 0)}, wb)
				target.spine.z += wob * 0.4 * wb
		PlayerController.State.AIR:
			_air_pose(target)
			blend_speed = 22.0
		PlayerController.State.VAULT:
			tilt = _vault_pose(target)
			blend_speed = 20.0
		PlayerController.State.WALLRUN:
			_run_pose(target, maxf(spd, 6.0) * 1.15, dt)
			var side: float = player.wall.get("side", 1.0)
			tilt = Basis(Vector3.BACK, 0.42 * side)
			target.shoulder_l.z -= 0.5; target.shoulder_r.z += 0.5
		PlayerController.State.WALLCLIMB:
			phase += dt * 14.0
			target.hip_l.x = 0.9 + sin(phase) * 0.6; target.hip_r.x = 0.9 - sin(phase) * 0.6
			target.knee_l.x = -1.3; target.knee_r.x = -1.3
			target.shoulder_l.x = 2.6 - sin(phase) * 0.4; target.shoulder_r.x = 2.6 + sin(phase) * 0.4
			target.spine.x = 0.1
		PlayerController.State.HANG:
			var sw := sin(Time.get_ticks_msec() * 0.003) * 0.12
			target.shoulder_l.x = 3.0; target.shoulder_r.x = 3.0
			target.shoulder_l.z = -0.15; target.shoulder_r.z = 0.15
			target.elbow_l.x = 0.25; target.elbow_r.x = 0.25
			target.hip_l.x = 0.25 + sw; target.hip_r.x = 0.1 + sw
			target.knee_l.x = -0.35; target.knee_r.x = -0.2
		PlayerController.State.CLIMB_UP:
			var s := clampf(player.state_time / maxf(player.climb.get("duration", 0.4), 0.01), 0.0, 1.0)
			target.shoulder_l.x = lerpf(3.0, 0.4, s); target.shoulder_r.x = lerpf(3.0, 0.4, s)
			target.elbow_l.x = sin(s * PI) * 1.6; target.elbow_r.x = sin(s * PI) * 1.6
			target.hip_l.x = sin(s * PI) * 1.7; target.hip_r.x = sin(s * PI) * 0.6
			target.knee_l.x = -sin(s * PI) * 2.0; target.knee_r.x = -sin(s * PI) * 1.0
			target.spine.x = -sin(s * PI) * 0.6
			blend_speed = 22.0
		PlayerController.State.ROLL:
			_tuck_pose(target, 1.0)
			var s := player.roll_progress()
			tilt = Basis(Vector3.RIGHT, -TAU * _ease_in_out(s))
			drop = sin(s * PI) * 0.45
			blend_speed = 25.0
		PlayerController.State.SKILL:
			smp = player.skill_sample()
			if not smp.is_empty():
				_apply(target, smp.pose, 1.0)
				tilt = smp.basis
				drop = COM_HEIGHT - float(smp.com)
				last_phase = String(smp.phase)
				last_kind = String(player.skill.get("id", ""))
			blend_speed = 30.0
		PlayerController.State.CRASH:
			# Cae de espaldas (desde ahí sale el kip-up)
			var s := clampf(player.state_time / 0.35, 0.0, 1.0)
			tilt = Basis(Vector3.RIGHT, 1.45 * s)
			drop = 0.78 * s
			target.shoulder_l.z = -1.3; target.shoulder_r.z = 1.2
			target.shoulder_l.x = 0.4; target.hip_l.x = 0.3; target.knee_l.x = -0.6
			target.hip_r.x = -0.1
			if player.state_time > player.t.crash_time - 0.4:
				var g := clampf((player.state_time - (player.t.crash_time - 0.4)) / 0.4, 0.0, 1.0)
				tilt = Basis(Vector3.RIGHT, 1.45 * (1.0 - g))
				drop = 0.78 * (1.0 - g)
		PlayerController.State.SWIM:
			phase += dt * 4.0
			target.shoulder_l.x = 1.6 + sin(phase) * 1.2; target.shoulder_r.x = 1.6 - sin(phase) * 1.2
			target.hip_l.x = sin(phase * 1.3) * 0.4; target.hip_r.x = -sin(phase * 1.3) * 0.4
			tilt = Basis(Vector3.RIGHT, -0.9 if player.speed() > 0.6 else -0.2)

	if mocap_active != "":
		_mocap_recent = 0.25
	elif _mocap_recent > 0.0:
		_mocap_recent -= dt
		_force_blend = maxf(_force_blend, 38.0)
	if _force_blend > 0.0:
		blend_speed = _force_blend          # captura real: se sigue casi al instante
	# Mezcla hacia la pose objetivo con un muelle amortiguado por articulación: arranca y frena
	# con suavidad (sin tirones de velocidad) y se pasa un pelín al final, como un cuerpo real.
	# Codos, rodillas, cuello y muñecas van un instante por detrás del tronco (inercia de las
	# extremidades): el movimiento "sigue" en vez de moverse todo a la vez.
	for name in joints.keys():
		var cur: Vector3 = pose[name]
		var vel: Vector3 = _pose_vel.get(name, Vector3.ZERO)
		var tgt: Vector3 = target[name]
		var wj: float = blend_speed * SPRING_W * float(JOINT_LAG.get(name, 1.0))
		if dt <= 0.0:
			continue
		var steps := maxi(1, int(ceil(dt * wj / 0.45)))
		var h := dt / float(steps)
		for i in steps:
			var acc := (tgt - cur) * (wj * wj) - vel * (2.0 * SPRING_ZETA * wj)
			vel += acc * h
			cur += vel * h
		pose[name] = cur
		_pose_vel[name] = vel
		(joints[name] as Node3D).rotation = cur
	var direct := st in [PlayerController.State.ROLL, PlayerController.State.VAULT, PlayerController.State.SKILL]
	body_drop = drop if st == PlayerController.State.SKILL else lerpf(body_drop, drop, 1.0 - exp(-18.0 * dt))
	_tilt = tilt if direct else _tilt.slerp(tilt, 1.0 - exp(-22.0 * dt))
	var trick_basis := player.tricks.basis if st in [PlayerController.State.AIR, PlayerController.State.SWIM] else Basis()
	pivot.basis = (trick_basis * _tilt).orthonormalized()
	pivot.position.y = COM_HEIGHT - body_drop
	if st == PlayerController.State.VAULT:
		_vault_support()
	else:
		_solve_contacts(smp.get("contacts", ground_contacts), dt)
	if st == PlayerController.State.AIR and grab_w > 0.01:
		_grab_shins(grab_w)
	if st == PlayerController.State.AIR and wrap_w > 0.01:
		_wrap_chest(wrap_w)
	if skin_body:
		skin_body.sync()
	if human:
		human.sync(grab_w)

## Punto de agarre en la espinilla (delante del hueso, algo por debajo de la rodilla).
func shin_grip(side: String) -> Vector3:
	return (joints["knee_" + side] as Node3D).global_transform * Vector3(0.0, -0.1, -0.09)   # manos sobre las rodillas

## Puntos de las manos con los brazos cruzados: la izquierda al pecho derecho y la derecha al
## izquierdo (una algo más alta que la otra).
func chest_grip(side: String) -> Vector3:
	var spine: Node3D = joints.spine
	return spine.global_transform * (Vector3(0.07, 0.37, -0.175) if side == "l" else Vector3(-0.07, 0.3, -0.18))

func _wrap_chest(w: float) -> void:
	var spine: Node3D = joints.spine
	for sd in ["l", "r"]:
		var sign := -1.0 if sd == "l" else 1.0
		var pole := (spine.global_basis.x * sign * 0.6 - spine.global_basis.y * 0.8).normalized()   # codos abajo y fuera
		_ik(joints["shoulder_" + sd], joints["elbow_" + sd], chest_grip(sd), ARM_L1, ARM_L2, pole, 1.0, w)

## Las manos rodean y agarran las espinillas (IK de brazo); los codos se abren hacia fuera.
func _grab_shins(w: float) -> void:
	var spine: Node3D = joints.spine
	for sd in ["l", "r"]:
		var sign := -1.0 if sd == "l" else 1.0
		# Codos flexionados hacia atrás y algo afuera (se ve el brazo doblado, como al agarrarse)
		var pole := (spine.global_basis.x * sign * 0.45 + spine.global_basis.z * 0.9).normalized()
		_ik(joints["shoulder_" + sd], joints["elbow_" + sd], shin_grip(sd), ARM_L1, ARM_L2, pole, 1.0, w)

## Apoyos de manos de cada vault sobre el obstáculo: [mano, desde, hasta, avance sobre el
## obstáculo (0 = borde de delante, 1 = borde de detrás), lateral]. La mano se clava en la
## superficie de arriba y el cuerpo se coloca con los hombros a la longitud del brazo.
const VAULT_HANDS := {
	"Kong Vault": [["hl", 0.28, 0.55, 0.25, -0.17], ["hr", 0.28, 0.55, 0.25, 0.17]],
	"Double Kong": [["hl", 0.18, 0.38, 0.15, -0.17], ["hr", 0.18, 0.38, 0.15, 0.17],
		["hl", 0.55, 0.74, 0.85, -0.17], ["hr", 0.55, 0.74, 0.85, 0.17]],
	"Dive Kong": [["hl", 0.12, 0.45, 0.2, -0.17], ["hr", 0.12, 0.45, 0.2, 0.17]],
	"Kong Up": [["hl", 0.12, 0.5, 0.25, -0.17], ["hr", 0.12, 0.5, 0.25, 0.17]],
	"Kash Vault": [["hl", 0.22, 0.45, 0.25, -0.17], ["hr", 0.22, 0.45, 0.25, 0.17]],
	"Speed Vault": [["hl", 0.3, 0.58, 0.45, -0.12]],
	"Lazy Vault": [["hl", 0.25, 0.52, 0.35, -0.15], ["hr", 0.48, 0.74, 0.7, 0.1]],
	"Step Vault": [["hr", 0.22, 0.55, 0.3, 0.15]],
	"Thief Vault": [["hr", 0.35, 0.66, 0.2, 0.15]],
	"Turn Vault": [["hl", 0.25, 0.85, 0.5, -0.2], ["hr", 0.25, 0.85, 0.5, 0.2]],
	"Reverse Vault": [["hl", 0.3, 0.65, 0.45, -0.1]],
}
const VAULT_SHOULDER_H := 0.5

func _vault_support() -> void:
	var v: Dictionary = player.vault
	var defs: Array = VAULT_HANDS.get(v.get("kind", ""), [])
	var s := player.vault_progress()
	var dir: Vector3 = v.get("dir", player.facing)
	var right := dir.cross(Vector3.UP).normalized()
	var p0: Vector3 = v.get("p0", player.global_position)
	var top: float = v.get("top_y", 0.0)
	var front: float = v.get("front", 0.5)
	var depth: float = v.get("depth", 0.6)
	var contacts := {}
	var targets := {}
	var body_w := 0.0
	for h in defs:
		var x0: float = h[1]
		var x1: float = h[2]
		var ramp := 0.05
		var w := 0.0
		if s >= x0 and s <= x1: w = 1.0
		elif s < x0 and s > x0 - ramp: w = (s - (x0 - ramp)) / ramp
		elif s > x1 and s < x1 + ramp: w = 1.0 - (s - x1) / ramp
		# El cuerpo entra y sale del apoyo de forma gradual (sin saltos de la pose)
		var bw := 0.0
		var br := 0.18
		if s >= x0 and s <= x1: bw = 1.0
		elif s < x0 and s > x0 - br: bw = _smooth((s - (x0 - br)) / br)
		elif s > x1 and s < x1 + br: bw = _smooth(1.0 - (s - x1) / br)
		body_w = maxf(body_w, bw)
		if bw > 0.0 and not targets.has(h[0] + "_body"):
			targets[h[0] + "_body"] = true
		if w > contacts.get(h[0], 0.0) or (bw > 0.0 and not targets.has(h[0])):
			contacts[h[0]] = w
			# Punto de apoyo: donde está el cuerpo a mitad del apoyo, dentro de la superficie
			var along: float = float(v.get("length", 1.0)) * (x0 + x1) * 0.5
			along = clampf(lerpf(along, front + depth * float(h[3]), 0.35), front + 0.08, front + maxf(depth - 0.08, 0.1))
			var pt := p0 + dir * along + right * float(h[4])
			targets[h[0]] = Vector3(pt.x, top + HAND_R, pt.z)
	# El cuerpo se apoya en los brazos: se desplaza para que los hombros queden sobre las manos
	var sum_w := 0.0
	var delta := Vector3.ZERO
	for c in contacts.keys():
		var sh := (joints["shoulder_" + c.substr(1, 1)] as Node3D).global_position
		var want: Vector3 = targets[c] + Vector3.UP * VAULT_SHOULDER_H
		delta += want - sh
		sum_w += 1.0
	if sum_w > 0.0:
		delta = (delta / sum_w).limit_length(0.7) * body_w
		pivot.global_position += delta
	var ik := {}
	for c in contacts.keys():
		if float(contacts[c]) > 0.0:
			ik[c] = contacts[c]
	_solve_contacts({}, 0.0, ik, targets)

# ------------------------------------------------------------------ apoyos (IK)

## Apoyos reales: una mano/pie apoyado se fija en un punto del suelo y el brazo/pierna se
## resuelve con IK de dos huesos mientras el cuerpo gira por encima. Además, ninguna mano ni
## pie puede quedar por debajo del suelo en ningún estado.
func _solve_contacts(contacts: Dictionary, _dt: float, extra := {}, extra_targets := {}) -> void:
	if not ik_enabled:
		return
	var gy := player.sensor.ground_below(player.global_position + Vector3.UP * 0.5)
	ground_y = gy if gy != -INF else player.global_position.y - 100.0
	for c in extra.keys():
		# Apoyos fuera del suelo (manos sobre un obstáculo): punto fijado por el movimiento
		contact_w[c] = extra[c]
		plants[c] = extra_targets[c]
		_limb_ik(c, extra_targets[c], float(extra[c]))
	for c in ["hl", "hr", "fl", "fr"]:
		if extra.has(c):
			continue
		var w: float = contacts.get(c, 0.0)
		contact_w[c] = w
		var end := limb_end(c)
		if w > 0.0:
			# Mientras la mano baja el punto de apoyo se sigue buscando; queda clavado al cargar peso
			if not plants.has(c) or (c.begins_with("h") and w < 0.99):
				var lift := HAND_R if c.begins_with("h") else SOLE
				var pt := end
				if c.begins_with("h"):
					# La mano se apoya delante del hombro, en la dirección a la que apunta el brazo
					var sh := (joints["shoulder_" + c.substr(1, 1)] as Node3D).global_position
					var off := Vector2(end.x - sh.x, end.z - sh.z).limit_length(0.08)
					pt = Vector3(sh.x + off.x, 0.0, sh.z + off.y)
				plants[c] = Vector3(pt.x, ground_y + lift, pt.z)
			if c.begins_with("f"):
				# Pie apoyado: sigue la horizontal del cuerpo pero baja hasta el suelo
				plants[c] = Vector3(end.x, ground_y + SOLE, end.z)
			_limb_ik(c, plants[c], w)
		else:
			plants.erase(c)
		# Nunca por debajo del suelo (en el aire solo al bajar: al despegar el cuerpo sube y gira,
		# y fijar el pie al suelo estiraba una pierna hacia atrás como si se quedara enganchada)
		if player.state == PlayerController.State.AIR and player.velocity.y > -1.0:
			continue
		end = limb_end(c)
		var floor_y := ground_y + (HAND_R if c.begins_with("h") else SOLE * 0.6)
		if end.y < floor_y:
			_limb_ik(c, Vector3(end.x, floor_y, end.z), 1.0)

## Posición en el mundo del extremo (centro de la mano / suela) de cada miembro.
func limb_end(c: String) -> Vector3:
	match c:
		"hl": return (joints.elbow_l as Node3D).global_transform * Vector3(0, -ARM_L2, 0)
		"hr": return (joints.elbow_r as Node3D).global_transform * Vector3(0, -ARM_L2, 0)
		"fl": return (joints.knee_l as Node3D).global_transform * Vector3(0, -LEG_L2, 0)
		"fr": return (joints.knee_r as Node3D).global_transform * Vector3(0, -LEG_L2, 0)
	return Vector3.ZERO

func _limb_ik(c: String, target: Vector3, w: float) -> void:
	var side := "l" if c.ends_with("l") else "r"
	if c.begins_with("h"):
		var spine: Node3D = joints.spine
		# El codo apunta hacia atrás del tronco (el antebrazo se flexiona hacia delante)
		_ik(joints["shoulder_" + side], joints["elbow_" + side], target, ARM_L1, ARM_L2, spine.global_basis.z, 1.0, w)
	else:
		var pelvis: Node3D = joints.pelvis
		# La rodilla apunta hacia delante (la pierna se flexiona hacia atrás)
		_ik(joints["hip_" + side], joints["knee_" + side], target, LEG_L1, LEG_L2, -pelvis.global_basis.z, -1.0, w)

## IK analítico de dos huesos. bend_sign +1: el segundo hueso se dobla hacia -Z local (codo);
## -1: hacia +Z (rodilla). El resultado se mezcla con la pose (peso w).
func _ik(upper: Node3D, lower: Node3D, target: Vector3, l1: float, l2: float, pole: Vector3, bend_sign: float, w: float) -> void:
	var parent := upper.get_parent() as Node3D
	var pg := parent.global_transform
	var root := pg * upper.position
	var v := target - root
	if v.length() < 0.0001:
		return
	var dir := v.normalized()
	var d := clampf(v.length(), 0.05, (l1 + l2) * 0.999)
	var a := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	var bend := PI - acos(clampf((l1 * l1 + l2 * l2 - d * d) / (2.0 * l1 * l2), -1.0, 1.0))
	var p := pole - dir * pole.dot(dir)
	if p.length() < 0.001:
		p = pg.basis.x - dir * pg.basis.x.dot(dir)
	p = p.normalized()
	var u := (dir * cos(a) + p * sin(a)).normalized()
	var y := -u
	var z := (p - u * p.dot(u)).normalized() * bend_sign
	var x := y.cross(z).normalized()
	var local := pg.basis.orthonormalized().inverse() * Basis(x, y, z)
	upper.basis = upper.basis.orthonormalized().slerp(local.orthonormalized(), clampf(w, 0.0, 1.0))
	var lr := lower.rotation
	lower.rotation = Vector3(lerpf(lr.x, bend * bend_sign, w), lr.y * (1.0 - w), lr.z * (1.0 - w))

func _ease_in_out(s: float) -> float:
	return s * s * (3.0 - 2.0 * s)

## De pie relajado: respiración, peso algo más en una pierna, brazos sueltos con los codos
## ligeramente flexionados y un leve balanceo.
func _idle_pose(p: Dictionary) -> void:
	var tm := Time.get_ticks_msec() * 0.001
	var b := sin(tm * 2.5)
	var sway := sin(tm * 0.7)
	# De pie natural (medido en el modelo): oreja, hombro y cadera en la misma vertical. Con la
	# columna a cero el tórax del atleta queda inclinado hacia delante (cabeza 10 cm por delante
	# de la cadera, como encorvado con la tripa fuera), así que se endereza un poco.
	p.spine.x = 0.18 + 0.02 * b
	p.spine.z = 0.025 * sway
	p.neck.x = -0.04 - 0.015 * b
	# Brazos relajados: caen junto al cuerpo con la mano al lado del muslo (no por delante) y los
	# codos apenas flexionados
	p.shoulder_l.x = -0.24 + 0.02 * b; p.shoulder_r.x = -0.22 + 0.02 * b
	p.shoulder_l.z = -0.035; p.shoulder_r.z = 0.035
	p.elbow_l.x = 0.16; p.elbow_r.x = 0.14
	p.hip_l.x = 0.04; p.hip_r.x = 0.08
	p.hip_l.z = -0.05; p.hip_r.z = 0.04 + 0.02 * sway
	p.knee_l.x = -0.05; p.knee_r.x = -0.16

func _run_pose(p: Dictionary, spd: float, dt: float) -> void:
	var step_len := 0.55 + 0.085 * spd
	var prev_half := floori(phase / PI)
	phase += TAU * spd / (2.0 * step_len) * dt
	if floori(phase / PI) != prev_half:
		footstep.emit(clampf(spd / 9.0, 0.2, 1.0))
	var amt := clampf(spd / 9.0, 0.0, 1.0)
	var amp := 0.35 + 0.65 * amt
	var s := sin(phase)
	p.hip_l.x = s * amp + 0.15 * amt
	p.hip_r.x = -s * amp + 0.15 * amt
	# Rodilla: casi recta en el apoyo (pequeña flexión al recibir el peso) y muy doblada en el
	# balanceo, justo después de despegar el pie (el talón sube hacia el glúteo al correr rápido)
	var swing_l := pow(maxf(0.0, cos(phase + 0.35)), 1.3)
	var swing_r := pow(maxf(0.0, cos(phase + 0.35 + PI)), 1.3)
	p.knee_l.x = -(0.2 + (0.55 + 1.35 * amt) * swing_l + 0.22 * amt * maxf(0.0, -cos(phase)))
	p.knee_r.x = -(0.2 + (0.55 + 1.35 * amt) * swing_r + 0.22 * amt * maxf(0.0, cos(phase)))
	p.shoulder_l.x = -s * (0.4 + 0.7 * amt)
	p.shoulder_r.x = s * (0.4 + 0.7 * amt)
	p.shoulder_l.z = -0.12; p.shoulder_r.z = 0.12
	p.elbow_l.x = 0.6 + 0.9 * amt; p.elbow_r.x = 0.6 + 0.9 * amt
	p.spine.x = -0.06 - 0.3 * amt
	# Cadera y hombros giran en sentidos opuestos en cada zancada; la cabeza compensa y mira al frente
	p.pelvis.y = -s * 0.16 * amt
	p.spine.y = s * 0.26 * amt
	p.pelvis.z = 0.04 * cos(phase) * amt
	p.neck.y = -s * 0.12 * amt
	p.neck.x = 0.15 * amt

func _tuck_pose(p: Dictionary, amount: float) -> void:
	p.spine.x = -0.7 * amount
	p.neck.x = -0.35 * amount
	p.hip_l.x = 2.45 * amount; p.hip_r.x = 2.35 * amount
	p.knee_l.x = -2.55 * amount; p.knee_r.x = -2.5 * amount
	p.hip_l.z = -0.12 * amount; p.hip_r.z = 0.12 * amount
	p.shoulder_l.x = 1.3 * amount; p.shoulder_r.x = 1.3 * amount
	p.shoulder_l.z = -0.25 * amount; p.shoulder_r.z = 0.25 * amount
	p.elbow_l.x = 1.7 * amount; p.elbow_r.x = 1.7 * amount

func _air_pose(p: Dictionary) -> void:
	var tr := player.tricks
	if tr.active:
		_trick_pose(p, tr)
		return
	var vy := player.velocity.y
	var rising := clampf(vy / 8.0, -1.0, 1.0)
	# Despegue sin truco: extensión explosiva y brazos arriba; después piernas preparadas.
	var imp := clampf(1.0 - tr.air_time / 0.14, 0.0, 1.0)
	p.hip_l.x = 0.7 + 0.3 * rising
	p.hip_r.x = 0.15
	p.knee_l.x = -1.1
	p.knee_r.x = -0.5 - 0.4 * maxf(0.0, -rising)
	p.shoulder_l.x = 0.6 + 1.0 * rising
	p.shoulder_r.x = -0.2 + 1.0 * rising
	p.shoulder_l.z = -0.7; p.shoulder_r.z = 0.7
	p.elbow_l.x = 0.5; p.elbow_r.x = 0.5
	p.spine.x = -0.15
	if imp > 0.0:
		_apply(p, {"hip_l": Vector3(-0.1, 0, 0), "hip_r": Vector3(0.2, 0, 0), "knee_l": Vector3(-0.1, 0, 0),
			"knee_r": Vector3(-0.3, 0, 0), "shoulder_l": Vector3(2.4, 0, -0.3), "shoulder_r": Vector3(2.4, 0, 0.3),
			"spine": Vector3(0.1, 0, 0)}, imp)
	var ttg := player.time_to_ground()
	if vy < 0.0 and ttg < 0.25:
		_apply(p, RECEPTION, clampf(1.0 - ttg / 0.25, 0.0, 1.0) * 0.8)

## Variante visual de la acrobacia en curso (cada truco tiene su propia ejecución).
func trick_kind(tr: TrickSystem) -> String:
	var moving := tr.takeoff_speed > 4.0
	var twisting: bool = tr.dir.get("twist", 0) != 0
	match tr.style:
		"back":
			if twisting:
				return "twist"
			return "gainer" if moving else "back"
		"front":
			if twisting:
				return "twist"
			return "webster" if moving else "front"
		"side":
			if twisting:
				return "twist"
			return "side"   # lateral siempre encogido (rodillas al pecho)
		"aerial":
			return "twist" if twisting else "aerial"   # rueda sin manos: piernas abiertas
		"cork":
			return "cork"
		"chutada":
			return "chutada"
		"butterfly":
			return "butterfly"
		"kick":
			return "kick"
		"cartwheel", "roundoff", "bhs", "fhs":
			return tr.style
	return "back"

const V0 := Vector3.ZERO

## Fase 2 · IMPULSO: extensión explosiva al despegar (distinta en cada truco).
func _impulse_pose(kind: String, rs: float) -> Dictionary:
	match kind:
		"front":
			return {"spine": Vector3(-0.35, 0, 0), "neck": Vector3(-0.35, 0, 0),
				"shoulder_l": Vector3(2.75, 0, -0.2), "shoulder_r": Vector3(2.75, 0, 0.2),
				"elbow_l": Vector3(0.15, 0, 0), "elbow_r": Vector3(0.15, 0, 0),
				"hip_l": Vector3(0.1, 0, 0), "hip_r": Vector3(0.1, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)}
		"webster":
			return {"spine": Vector3(-0.75, 0, 0), "neck": Vector3(-0.3, 0, 0),
				"shoulder_l": Vector3(0.5, 0, -0.35), "shoulder_r": Vector3(0.5, 0, 0.35),
				"elbow_l": Vector3(0.3, 0, 0), "elbow_r": Vector3(0.3, 0, 0),
				"hip_l": Vector3(-0.95, 0, 0), "knee_l": Vector3(-0.25, 0, 0),      # pierna de atrás patea arriba
				"hip_r": Vector3(0.55, 0, 0), "knee_r": Vector3(-0.4, 0, 0)}
		"side":
			return {"spine": Vector3(0.1, 0, 0.25 * rs), "neck": Vector3(0.1, 0, 0.2 * rs),
				"shoulder_l": Vector3(2.5, 0, -0.25 + 0.35 * rs), "shoulder_r": Vector3(2.5, 0, 0.25 + 0.35 * rs),
				"elbow_l": Vector3(0.2, 0, 0), "elbow_r": Vector3(0.2, 0, 0),
				"hip_l": Vector3(-0.05, 0, 0), "hip_r": Vector3(-0.05, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)}
		"aerial":
			# Tronco tumbado hacia delante, brazos lanzados abajo y atrás, pierna de atrás arriba
			return {"spine": Vector3(-1.05, 0.35 * rs, 0), "neck": Vector3(0.45, 0, 0),
				"shoulder_l": Vector3(-0.5, 0, -0.5), "shoulder_r": Vector3(-0.5, 0, 0.5),
				"elbow_l": Vector3(0.4, 0, 0), "elbow_r": Vector3(0.4, 0, 0),
				"hip_l": Vector3(-0.9, 0, -0.3), "knee_l": Vector3(-0.15, 0, 0),
				"hip_r": Vector3(0.35, 0, 0.1), "knee_r": Vector3(-0.2, 0, 0)}
		"gainer":
			return {"spine": Vector3(0.3, 0, 0), "neck": Vector3(0.4, 0, 0),
				"shoulder_l": Vector3(2.9, 0, -0.25), "shoulder_r": Vector3(2.9, 0, 0.25),
				"elbow_l": Vector3(0.1, 0, 0), "elbow_r": Vector3(0.1, 0, 0),
				"hip_r": Vector3(1.6, 0, 0), "knee_r": Vector3(-0.35, 0, 0),         # pierna libre lanzada arriba
				"hip_l": Vector3(-0.2, 0, 0), "knee_l": Vector3(-0.05, 0, 0)}
		"cork", "chutada":
			return _cork_legs(CORK_KICK)
		"twist":
			return {"spine": Vector3(0.2, 0.55 * rs, 0), "neck": Vector3(0.3, 0.3 * rs, 0),
				"shoulder_l": Vector3(2.5, 0, -0.7), "shoulder_r": Vector3(1.7, 0, 0.9),
				"elbow_l": Vector3(0.2, 0, 0), "elbow_r": Vector3(0.6, 0, 0),
				"hip_l": Vector3(-0.1, 0, 0), "hip_r": Vector3(0.4, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.5, 0, 0)}
		"kick":
			# Patada giratoria: brazos lanzados hacia el giro, pierna de impulso empujando
			return {"spine": Vector3(-0.15, 0.6 * rs, 0), "neck": Vector3(0.1, 0.4 * rs, 0),
				"shoulder_l": Vector3(1.6, 0, -1.0), "shoulder_r": Vector3(1.2, 0, 1.2),
				"elbow_l": Vector3(0.6, 0, 0), "elbow_r": Vector3(0.6, 0, 0),
				"hip_l": Vector3(-0.1, 0, 0), "knee_l": Vector3(-0.1, 0, 0),
				"hip_r": Vector3(1.2, 0, 0), "knee_r": Vector3(-1.5, 0, 0)}
		"butterfly":
			return {"spine": Vector3(-0.75, 0.6 * rs, 0), "neck": Vector3(0.4, 0, 0),
				"shoulder_l": Vector3(1.5, 0, -1.0), "shoulder_r": Vector3(1.5, 0, 1.0),
				"elbow_l": Vector3(0.5, 0, 0), "elbow_r": Vector3(0.5, 0, 0),
				"hip_l": Vector3(-0.85, 0, -0.2), "knee_l": Vector3(-0.15, 0, 0),
				"hip_r": Vector3(0.3, 0, 0), "knee_r": Vector3(-0.3, 0, 0)}
		"cartwheel", "roundoff":
			# Zancada de entrada: pierna delantera flexionada, brazos arriba, tronco cayendo de lado
			var lean := 0.35 if kind == "cartwheel" else 0.6
			return {"spine": Vector3(-lean, 0, 0.35 * rs), "neck": Vector3(0.2, 0, 0.2 * rs),
				"shoulder_l": Vector3(2.95, 0, -0.15), "shoulder_r": Vector3(2.95, 0, 0.15),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_r": Vector3(0.75, 0, 0), "knee_r": Vector3(-0.7, 0, 0),
				"hip_l": Vector3(-0.45, 0, 0), "knee_l": Vector3(-0.05, 0, 0)}
		"bhs":
			# Flic-flac: tras sentarse, extensión explosiva con brazos atrás-arriba y cabeza atrás
			return {"spine": Vector3(0.5, 0, 0), "neck": Vector3(0.6, 0, 0),
				"shoulder_l": Vector3(3.05, 0, -0.2), "shoulder_r": Vector3(3.05, 0, 0.2),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(-0.3, 0, 0), "hip_r": Vector3(-0.3, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)}
		"fhs":
			# Paloma: tronco lanzado adelante buscando el suelo con las manos, pierna de atrás pateando
			return {"spine": Vector3(-0.75, 0, 0), "neck": Vector3(-0.15, 0, 0),
				"shoulder_l": Vector3(2.9, 0, -0.15), "shoulder_r": Vector3(2.9, 0, 0.15),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(-0.8, 0, 0), "knee_l": Vector3(-0.1, 0, 0),
				"hip_r": Vector3(0.55, 0, 0), "knee_r": Vector3(-0.45, 0, 0)}
	# Backflip: brazos arriba, pecho y cabeza atrás, piernas estiradas empujando el suelo
	return {"spine": Vector3(0.3, 0, 0), "neck": Vector3(0.45, 0, 0),
		"shoulder_l": Vector3(2.95, 0, -0.25), "shoulder_r": Vector3(2.95, 0, 0.25),
		"elbow_l": Vector3(0.1, 0, 0), "elbow_r": Vector3(0.1, 0, 0),
		"hip_l": Vector3(-0.15, 0, 0), "hip_r": Vector3(-0.15, 0, 0), "knee_l": Vector3(-0.05, 0, 0), "knee_r": Vector3(-0.05, 0, 0)}

## Fases 3-4 · AGRUPACIÓN y ROTACIÓN: forma del cuerpo durante el giro.
func _gather_pose(kind: String, rs: float, ph: float) -> Dictionary:
	match kind:
		"front":
			# Agrupado cerrado, cabeza metida, manos abrazando las espinillas
			return {"spine": Vector3(-0.6, 0, 0), "neck": Vector3(-0.6, 0, 0),
				"hip_l": Vector3(2.0, 0, -0.06), "hip_r": Vector3(1.98, 0, 0.06), "knee_l": Vector3(-2.2, 0, 0), "knee_r": Vector3(-2.18, 0, 0),
				"shoulder_l": Vector3(0.75, 0, 0.12), "shoulder_r": Vector3(0.75, 0, -0.12),
				"elbow_l": Vector3(1.75, 0, 0), "elbow_r": Vector3(1.75, 0, 0)}
		"webster":
			# Mortal adelante a una pierna: tijera, la pierna de atrás llega tarde
			return {"spine": Vector3(-0.5, 0, 0), "neck": Vector3(-0.45, 0, 0),
				"hip_r": Vector3(2.0, 0, 0.05), "knee_r": Vector3(-2.2, 0, 0),
				"hip_l": Vector3(0.6, 0, -0.05), "knee_l": Vector3(-1.9, 0, 0),
				"shoulder_l": Vector3(0.9, 0, 0.1), "shoulder_r": Vector3(0.9, 0, -0.1),
				"elbow_l": Vector3(1.5, 0, 0), "elbow_r": Vector3(1.5, 0, 0)}
		"side":
			# Sideflip real: bola cerrada. Rodillas al pecho, talones a los glúteos, manos
			# agarrando las rodillas y cabeza metida; la pierna de atrás sube primero.
			return {"spine": Vector3(-0.5, 0, 0.15 * rs), "neck": Vector3(-0.4, 0, 0.2 * rs),
				"hip_l": Vector3(2.1, 0, 0.08 * rs), "hip_r": Vector3(2.08, 0, 0.08 * rs),
				"knee_l": Vector3(-2.2, 0, 0), "knee_r": Vector3(-2.2, 0, 0),
				"shoulder_l": Vector3(1.15, 0, 0.18), "shoulder_r": Vector3(1.15, 0, -0.18),
				"elbow_l": Vector3(1.05, 0, 0), "elbow_r": Vector3(1.05, 0, 0)}
		"aerial":
			# Rueda sin manos: tronco carpado, piernas abiertas en el plano del giro, brazos pegados
			return {"spine": Vector3(-1.1, 0, 0), "neck": Vector3(0.45, 0, 0),
				"hip_l": Vector3(0.15, 0, -1.05), "hip_r": Vector3(0.3, 0, 0.9),
				"knee_l": Vector3(-0.2, 0, 0), "knee_r": Vector3(-0.35, 0, 0),
				"shoulder_l": Vector3(0.45, 0, 0.45), "shoulder_r": Vector3(0.45, 0, -0.45),
				"elbow_l": Vector3(1.95, 0, 0), "elbow_r": Vector3(1.95, 0, 0)}
		"gainer":
			# Mortal atrás a una pierna: la pierna libre agrupa primero, la de impulso llega después
			return {"spine": Vector3(-0.5, 0, 0), "neck": Vector3(0.2, 0, 0),
				"hip_r": Vector3(2.5, 0, 0.08), "knee_r": Vector3(-2.6, 0, 0),
				"hip_l": Vector3(1.7, 0, -0.1), "knee_l": Vector3(-2.0, 0, 0),
				"shoulder_l": Vector3(1.1, 0, -0.15), "shoulder_r": Vector3(1.1, 0, 0.15),
				"elbow_l": Vector3(1.2, 0, 0), "elbow_r": Vector3(1.2, 0, 0)}
		"chutada":
			# Mortal chutado: tras la patada (impulso) es un backflip normal, agrupado
			return _gather_pose("back", rs, ph)
		"cork":
			# Tirabuzón: piernas juntas y casi rectas (eje recto y rápido), brazos cerrados al pecho
			# y la cabeza mirando por encima del hombro hacia el giro
			return {"spine": Vector3(-0.08, 0, 0), "neck": Vector3(0.15, 0.45 * rs, 0),
				"hip_l": Vector3(0.28, 0, 0.07), "hip_r": Vector3(0.3, 0, -0.07),
				"knee_l": Vector3(-0.22, 0, 0), "knee_r": Vector3(-0.25, 0, 0),
				"shoulder_l": Vector3(0.6, 0, 0.6), "shoulder_r": Vector3(0.6, 0, -0.6),
				"elbow_l": Vector3(2.35, 0, 0), "elbow_r": Vector3(2.35, 0, 0)}
		"twist":
			# Mortal con tirabuzón: cuerpo largo para girar rápido sobre el eje largo, pero no
			# rígido: cadera y rodillas un poco flexionadas (natural, y desde ahí agruparse otra
			# vez es inmediato) y brazos cerrados al pecho
			return {"spine": Vector3(-0.08, 0, 0), "neck": Vector3(0.1, 0, 0),
				"hip_l": Vector3(0.38, 0, 0.03), "hip_r": Vector3(0.42, 0, -0.03),
				"knee_l": Vector3(-0.55, 0, 0), "knee_r": Vector3(-0.6, 0, 0),
				"shoulder_l": Vector3(0.55, 0, 0.6), "shoulder_r": Vector3(0.55, 0, -0.6),
				"elbow_l": Vector3(2.35, 0, 0), "elbow_r": Vector3(2.35, 0, 0)}
		"kick":
			# Giro vertical con brazos cerrados; a mitad de vuelta sale la patada (pierna extendida)
			var kf := sin(ph * 0.5)
			var kick := clampf(kf * 1.4, 0.0, 1.0)
			return {"spine": Vector3(-0.2 - 0.3 * kick, 0, 0.35 * kick * rs), "neck": Vector3(0.15, 0, 0),
				"shoulder_l": Vector3(0.6, 0, 0.55), "shoulder_r": Vector3(0.6, 0, -0.55),
				"elbow_l": Vector3(2.2, 0, 0), "elbow_r": Vector3(2.2, 0, 0),
				"hip_l": Vector3(0.3 + 1.2 * kick, 0, -0.9 * kick), "knee_l": Vector3(-1.2 + 1.05 * kick, 0, 0),
				"hip_r": Vector3(0.9 - 0.5 * kick, 0, 0.05), "knee_r": Vector3(-1.4 + 0.6 * kick, 0, 0)}
		"butterfly":
			# Cuerpo tumbado, patada de tijera continua, brazos a la altura del hombro y flexionados
			var k := sin(ph)
			return {"spine": Vector3(0.15, 0.25 * k, 0), "neck": Vector3(0.4, 0, 0),
				"hip_l": Vector3(-0.15 + 1.05 * k, 0, -0.3), "hip_r": Vector3(-0.15 - 1.05 * k, 0, 0.3),
				"knee_l": Vector3(-0.15 - 0.3 * maxf(0.0, -k), 0, 0), "knee_r": Vector3(-0.15 - 0.3 * maxf(0.0, k), 0, 0),
				"shoulder_l": Vector3(1.35 + 0.35 * k, 0, -0.75), "shoulder_r": Vector3(1.35 - 0.35 * k, 0, 0.75),
				"elbow_l": Vector3(1.1, 0, 0), "elbow_r": Vector3(1.1, 0, 0)}
		"cartwheel":
			# Rueda con apoyo: brazos estirados por encima de la cabeza (al suelo), cuerpo recto
			# en el plano del giro, piernas en straddle amplio
			return {"spine": Vector3(0.0, 0, 0), "neck": Vector3(0.3, 0, 0),
				"shoulder_l": Vector3(3.05, 0, -0.2), "shoulder_r": Vector3(3.05, 0, 0.2),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(0.05, 0, -1.15), "hip_r": Vector3(0.05, 0, 1.15),
				"knee_l": Vector3(-0.05, 0, 0), "knee_r": Vector3(-0.05, 0, 0)}
		"roundoff":
			# Rondada: en la vertical las piernas se juntan y la cadera carpa para el golpe al suelo
			return {"spine": Vector3(-0.35, 0, 0), "neck": Vector3(0.35, 0, 0),
				"shoulder_l": Vector3(3.0, 0, -0.15), "shoulder_r": Vector3(3.0, 0, 0.15),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(0.6, 0, -0.08), "hip_r": Vector3(0.6, 0, 0.08),
				"knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)}
		"bhs":
			# Puente en el aire: espalda arqueada, cabeza atrás buscando las manos, piernas juntas
			return {"spine": Vector3(0.75, 0, 0), "neck": Vector3(0.7, 0, 0),
				"shoulder_l": Vector3(3.05, 0, -0.18), "shoulder_r": Vector3(3.05, 0, 0.18),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(-0.45, 0, -0.04), "hip_r": Vector3(-0.45, 0, 0.04),
				"knee_l": Vector3(-0.15, 0, 0), "knee_r": Vector3(-0.15, 0, 0)}
		"fhs":
			# Vuelo extendido y arqueado sobre las manos, piernas ligeramente separadas
			return {"spine": Vector3(0.45, 0, 0), "neck": Vector3(0.6, 0, 0),
				"shoulder_l": Vector3(3.05, 0, -0.18), "shoulder_r": Vector3(3.05, 0, 0.18),
				"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
				"hip_l": Vector3(-0.5, 0, 0), "hip_r": Vector3(-0.15, 0, 0),
				"knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.15, 0, 0)}
	# Backflip real: espalda algo redonda, rodillas a un palmo del pecho (muslo-tronco ~30°),
	# rodillas flexionadas ~123° y las manos agarrando rodillas / espinillas con los codos
	# flexionados; la cabeza neutra
	return {"spine": Vector3(-0.45, 0, 0), "neck": Vector3(0.05, 0, 0),
		"hip_l": Vector3(2.1, 0, -0.1), "hip_r": Vector3(2.07, 0, 0.1), "knee_l": Vector3(-2.15, 0, 0), "knee_r": Vector3(-2.12, 0, 0),
		"shoulder_l": Vector3(0.75, 0, -0.2), "shoulder_r": Vector3(0.75, 0, 0.2),
		"elbow_l": Vector3(1.4, 0, 0), "elbow_r": Vector3(1.4, 0, 0)}

## Cork: patada de la pierna de atrás (derecha si cork_side = 1) con los brazos arriba.
const CORK_KICK := {"spine": Vector3(0.22, 0, 0), "neck": Vector3(0.35, 0, 0),
	"shoulder_l": Vector3(2.85, 0, -0.3), "shoulder_r": Vector3(2.85, 0, 0.3),
	"elbow_l": Vector3(0.1, 0, 0), "elbow_r": Vector3(0.1, 0, 0),
	"hip_r": Vector3(2.0, 0, -0.25), "knee_r": Vector3(-0.1, 0, 0), "hip_l": Vector3(0.1, 0, 0), "knee_l": Vector3(-0.1, 0, 0)}
## Cork: apertura, la pierna de patada baja primero (estirada al suelo), la otra llega después.
const CORK_OPEN := {"hip_r": Vector3(0.05, 0, 0.04), "knee_r": Vector3(-0.08, 0, 0),
	"hip_l": Vector3(0.65, 0, -0.04), "knee_l": Vector3(-0.75, 0, 0),
	"shoulder_l": Vector3(1.4, 0, -0.9), "shoulder_r": Vector3(1.4, 0, 0.9)}

## Intercambia izquierda/derecha según la pierna de patada del cork.
func _cork_legs(v: Dictionary) -> Dictionary:
	if player.cork_side >= 0:
		return v
	var o := {}
	for k in v.keys():
		var n: String = k
		if n.ends_with("_l"):
			n = n.trim_suffix("_l") + "_r"
		elif n.ends_with("_r"):
			n = n.trim_suffix("_r") + "_l"
		var x: Vector3 = v[k]
		o[n] = Vector3(x.x, -x.y, -x.z)
	return o

## Fase 5 · APERTURA: el cuerpo se alarga (frena el giro) y las piernas buscan el suelo.
const OPEN_POSE := {"spine": Vector3(-0.05, 0, 0), "neck": Vector3(0.1, 0, 0),
	"hip_l": Vector3(0.22, 0, -0.05), "hip_r": Vector3(0.18, 0, 0.05), "knee_l": Vector3(-0.22, 0, 0), "knee_r": Vector3(-0.18, 0, 0),
	"shoulder_l": Vector3(0.95, 0, -1.0), "shoulder_r": Vector3(0.95, 0, 1.0),
	"elbow_l": Vector3(0.45, 0, 0), "elbow_r": Vector3(0.45, 0, 0)}

## Fase 6 · RECEPCIÓN: piernas flexionadas listas para absorber, brazos delante para equilibrar.
const RECEPTION := {"spine": Vector3(-0.3, 0, 0), "neck": Vector3(0.15, 0, 0),
	"hip_l": Vector3(0.8, 0, -0.08), "hip_r": Vector3(0.7, 0, 0.08), "knee_l": Vector3(-1.1, 0, 0), "knee_r": Vector3(-1.0, 0, 0),
	"shoulder_l": Vector3(1.3, 0, -0.55), "shoulder_r": Vector3(1.3, 0, 0.55),
	"elbow_l": Vector3(0.5, 0, 0), "elbow_r": Vector3(0.5, 0, 0)}

func _apply(p: Dictionary, vals: Dictionary, w: float) -> void:
	if w <= 0.0:
		return
	w = minf(w, 1.0)
	for k in vals.keys():
		p[k] = (p[k] as Vector3).lerp(vals[k], w)

func _smooth(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

## Pose de acrobacia por fases: impulso → agrupación → rotación → apertura → recepción.
## Las fases salen del estado físico real del giro (no de una animación fija).
var last_phase := ""          # para pruebas/depuración: fase visible actual
var last_kind := ""

func _mocap_for_kind(kind: String) -> MocapClip:
	if kind == "back" and not Settings.backflip_real():
		return null                          # el de captura real es una versión desbloqueable
	return mocap.get(kind, null)

func _trick_pose(p: Dictionary, tr: TrickSystem) -> void:
	var kind := trick_kind(tr)
	var mc := _mocap_for_kind("back" if kind in ["back", "gainer"] and not tr.all_settled() else "")
	if mc and absf(tr.total_pitch) < float(maxi(int(tr.goal.get("pitch", 1)), 1)) * TAU - 0.12:
		# Captura real: la forma del cuerpo sigue el giro del mortal (agrupa y abre en el mismo
		# ángulo que el atleta de verdad). En dobles, las primeras vueltas van agrupadas.
		var goal := maxi(int(tr.goal.get("pitch", 1)), 1)
		var tot := absf(tr.total_pitch)
		var prog := 0.0
		if tot < float(goal - 1) * TAU:
			prog = 0.45
		else:
			prog = clampf((tot - float(goal - 1) * TAU) / TAU, 0.0, 1.0)
		var mp := mc.pose_at(mc.flight_frame(prog))
		for k in mp.keys():
			p[k] = mp[k]
		# Cerca del suelo pasa a la recepción con las dos piernas (la captura cae a un pie)
		if player.velocity.y < 0.0 and prog > 0.6:
			_apply(p, RECEPTION, _smooth(1.0 - player.time_to_ground() / 0.25))
		grab_w = 0.0                         # las manos ya van donde las llevaba el atleta
		mocap_active = kind
		_force_blend = 60.0
		return
	var ax := tr.primary_axis()
	var s: int = tr.dir.get(ax, 1)
	var rs := float(tr.dir.get("roll", 0)) if kind in ["side", "aerial", "cartwheel", "roundoff"] else float(tr.dir.get("twist", 0))
	if rs == 0.0:
		rs = float(tr.dir.get("spin", 1))
	var period := tr.twist_period if ax == "twist" else TAU
	var prog: float = absf(tr.total.get(ax, 0.0))
	var goal_turns := maxi(int(tr.goal.get(ax, 1)), 1)
	# Agrupación: empieza en cuanto termina el impulso; manteniendo el dedo es inmediata y más cerrada.
	var early := kind in ["side", "back", "front", "gainer", "cartwheel", "roundoff", "bhs", "fhs"]
	var gather := _smooth((tr.air_time - (0.03 if early else 0.06)) / (0.07 if tr.tucked or early else 0.1))
	# Apertura: al acercarse la última vuelta pedida (sin mantener) el cuerpo se alarga y frena.
	var open := 0.0
	if tr.all_settled():
		open = 1.0
	elif tr.spotting or not tr.tucked:
		var next_stop := (floorf(prog / period + 0.0001) + 1.0) * period
		if next_stop >= goal_turns * period - 0.001 or tr.spotting:
			# Se abre solo en el último tramo de la vuelta (~290°-330°): agrupado durante casi todo el giro
			open = _smooth((period * 0.2 - (next_stop - prog)) / (period * 0.11))
	var imp := _smooth(1.0 - tr.air_time / (0.1 if early else 0.13))
	var ttg := player.time_to_ground()
	var rec := 0.0
	if open >= 0.99 and player.velocity.y < 0.0:
		rec = _smooth(1.0 - ttg / 0.24)

	var ph := absf(tr.total_spin) * 2.0 + tr.air_time * 9.0
	if kind == "kick":
		ph = absf(tr.total_twist)
	var g := _gather_pose(kind, rs, ph)
	# Base abierta → agrupado → impulso (inicio) → recepción (final)
	_apply(p, OPEN_POSE, 1.0)
	if kind == "butterfly":
		_apply(p, g, 1.0 - open * 0.6)       # la tijera sigue hasta casi aterrizar
	else:
		_apply(p, g, gather * (1.0 - open))
		if kind == "twist" and tr.tuck_amount > 0.01:
			# Botón de mortal durante un tirabuzón: se agrupa (rodillas al pecho) para ganar
			# velocidad de mortal; al girar con GIRO vuelve a estirarse
			var bk: String = {"front": "front", "side": "side"}.get(tr.style, "back")
			_apply(p, _gather_pose(bk, rs, ph), tr.tuck_amount * gather * (1.0 - open))
		# Vuelta completada: se abre estirando las piernas hacia el suelo (no se queda "sentado"
		# en el aire); las rodillas solo se flexionan justo antes de tocar el suelo (RECEPTION).
	_apply(p, _impulse_pose(kind, rs), imp)
	# Mirada: al final del giro la cabeza busca el suelo (atrás en los mortales hacia atrás, el
	# mentón abajo en los de delante) y se endereza al recibir
	var spot := open * (1.0 - rec)
	if kind in ["back", "gainer", "cork", "chutada", "twist", "bhs", "roundoff"]:
		p.neck.x += 0.38 * spot
	elif kind in ["front", "webster", "fhs", "aerial", "side"]:
		p.neck.x -= 0.32 * spot
	_apply(p, RECEPTION, rec)
	# Agrupado de verdad: las manos agarran las espinillas mientras el cuerpo está cerrado
	if kind in GRAB_KINDS:
		grab_w = clampf(gather * (1.0 - open) * (1.0 - imp) * (1.0 - rec), 0.0, 1.0)
	elif kind in ["twist", "cork"] and tr.dir.get("twist", 0) != 0:
		# Mientras gira el tirabuzón los brazos se cierran cruzados sobre el pecho (gira más rápido);
		# se abren al terminar el giro para aterrizar
		var twisting := 0.0 if tr.settled.get("twist", true) else 1.0
		var pre := 0.0
		if kind == "cork":
			# Antes de cerrar el giro: patada arriba, brazos arriba, cadera que sube (inversión)
			pre = clampf(1.0 - absf(float(tr.total.get("twist", 0.0))) / 0.9, 0.0, 1.0) * twisting
			_apply(p, _cork_legs(CORK_KICK), pre * (1.0 - rec))
			# Apertura: se separan los brazos y baja primero la pierna de patada para frenar
			_apply(p, _cork_legs(CORK_OPEN), open * (1.0 - rec))
		wrap_w = clampf(gather * (1.0 - imp) * (1.0 - rec) * (1.0 - pre) * maxf(twisting, 1.0 - open), 0.0, 1.0)
		if kind == "twist":
			# Agrupado: las manos pasan del pecho a las espinillas
			var tk := tr.tuck_amount * gather * (1.0 - open) * (1.0 - imp) * (1.0 - rec)
			grab_w = clampf(tk, 0.0, 1.0)
			wrap_w *= 1.0 - tr.tuck_amount
	last_kind = kind
	if imp > 0.5:
		last_phase = "impulso"
	elif rec > 0.3:
		last_phase = "recepcion"
	elif open > 0.5:
		last_phase = "apertura"
	elif gather > 0.6:
		last_phase = "agrupado"
	else:
		last_phase = "agrupando"

## Fase 1 · PREPARACIÓN (en el suelo, antes de despegar): flexión de piernas, brazos atrás.
## Cada mortal tiene su preparación: contramovimiento de piernas y balanceo de brazos que
## empieza atrás/abajo y se lanza hacia arriba justo antes de despegar (p = progreso 0..1).
func _load_pose(p: Dictionary) -> float:
	var f := player.flick_buffer if player.flick_timer > 0.0 else Vector2.ZERO
	var sec := TouchControls.sector_of(f) if f != Vector2.ZERO else 99
	var kind := player.jump_flip
	var prog := clampf(1.0 - player.jump_load / maxf(player.jump_load_total, 0.01), 0.0, 1.0)
	var mc := _mocap_for_kind("back" if kind in ["back", "double_back", "gainer"] else "")
	if mc:
		# Captura real: flexión y braceo del atleta de verdad hasta el despegue
		var fr := lerpf(float(mc.takeoff) - MOCAP_PREP, float(mc.takeoff), prog)
		var mp := mc.pose_at(fr)
		for k in mp.keys():
			p[k] = mp[k]
		mocap_active = kind
		_force_blend = 60.0
		return mc.drop_at(fr)
	var down := _smooth(prog / 0.65)                    # bajada (flexión)
	var swing := _smooth((prog - 0.6) / 0.4)            # brazos lanzados arriba al final
	var depth := 1.0
	if kind.begins_with("double"):
		depth = 1.2
	elif kind == "jump":
		depth = 0.75
	var arm_x := lerpf(lerpf(0.3, -1.15, down), 2.2, swing)
	var vals := {"spine": Vector3(-0.42 * down * depth, 0, 0), "neck": Vector3(0.2, 0, 0),
		"hip_l": Vector3(1.1 * down * depth, 0, -0.06), "hip_r": Vector3(1.05 * down * depth, 0, 0.06),
		"knee_l": Vector3(-1.8 * down * depth, 0, 0), "knee_r": Vector3(-1.75 * down * depth, 0, 0),
		"shoulder_l": Vector3(arm_x, 0, -0.18), "shoulder_r": Vector3(arm_x, 0, 0.18),
		"elbow_l": Vector3(0.35, 0, 0), "elbow_r": Vector3(0.35, 0, 0)}
	var side := 1.0 if sec in [0, 1, -1] else -1.0
	match kind:
		"front", "double_front":
			# Pecho delante y brazos muy atrás arriba: se proyecta adelante
			vals.spine = Vector3(-0.7 * down, 0, 0)
			vals.neck = Vector3(-0.1, 0, 0)
			var fx := lerpf(lerpf(0.4, -1.5, down), 2.6, swing)
			vals.shoulder_l = Vector3(fx, 0, -0.15); vals.shoulder_r = Vector3(fx, 0, 0.15)
		"side", "double_side":
			# Tronco cargado girado hacia el lado del giro, un brazo cruza y el otro abre
			vals.spine = Vector3(-0.5 * down, 0.55 * side * down, 0.15 * side * down)
			vals.shoulder_l = Vector3(lerpf(-0.4, 2.3, swing), 0, lerpf(-0.9, -0.3, swing))
			vals.shoulder_r = Vector3(lerpf(0.9, 2.3, swing), 0, lerpf(0.4, 0.3, swing))
		"aerial":
			# Zancada: pierna delantera flexionada, la de atrás estirada, tronco que cae y brazos barriendo
			vals.spine = Vector3(-0.85 * down, 0.2 * down, 0)
			vals.hip_r = Vector3(0.95 * down, 0, 0.05); vals.knee_r = Vector3(-1.0 * down, 0, 0)
			vals.hip_l = Vector3(-0.45 * down, 0, -0.05); vals.knee_l = Vector3(-0.15 * down, 0, 0)
			var ax := lerpf(lerpf(2.4, 0.4, down), -0.6, swing)
			vals.shoulder_l = Vector3(ax, 0, -0.5); vals.shoulder_r = Vector3(ax, 0, 0.5)
		"cork":
			# Cork: carga girada (hombros contra cadera) para lanzar el tirabuzón fuera de eje
			var cs := float(player.cork_side)
			vals.spine = Vector3(-0.4 * down, 0.6 * cs * down, 0)
			vals.shoulder_l = Vector3(lerpf(0.9, 2.6, swing), 0, lerpf(-0.9 if cs > 0 else 0.2, -0.4, swing))
			vals.shoulder_r = Vector3(lerpf(-0.6, 2.2, swing), 0, lerpf(0.9 if cs < 0 else -0.2, 0.5, swing))
		"butterfly":
			# Carga baja y girada, brazos lanzados hacia el lado del giro
			vals.spine = Vector3(-0.9 * down, 0.6 * down, 0)
			vals.shoulder_l = Vector3(lerpf(0.4, 1.4, swing), 0, lerpf(-1.2, -0.6, swing))
			vals.shoulder_r = Vector3(lerpf(0.4, 1.4, swing), 0, lerpf(1.2, 0.6, swing))
		_:
			if sec in [-1, -3]:
				vals.spine.y = 0.35 * side * down       # cork: carga ligeramente girada
	_apply(p, vals, 1.0)
	return (0.24 * depth) * down
## Salida del kong: las piernas pasan por delante recogidas, listas para recibir.
const KONG_EXIT_LEGS := {"hip_l": Vector3(1.0, 0, -0.06), "hip_r": Vector3(0.9, 0, 0.06),
	"knee_l": Vector3(-0.9, 0, 0), "knee_r": Vector3(-0.8, 0, 0), "spine": Vector3(-0.35, 0, 0)}

func _vault_pose(p: Dictionary) -> Basis:
	var s := player.vault_progress()
	var kind: String = player.vault.get("kind", "Speed Vault")
	var arc := sin(s * PI)
	match kind:
		"Kong Vault":
			_tuck_pose(p, arc)
			p.shoulder_l.x = lerpf(2.8, 0.3, s); p.shoulder_r.x = lerpf(2.8, 0.3, s)
			p.elbow_l.x = 0.2; p.elbow_r.x = 0.2
			_apply(p, KONG_EXIT_LEGS, _smooth((s - 0.5) / 0.3))
			# Tronco casi horizontal: hombros sobre las manos, cadera alta y piernas pasando entre los brazos
			return Basis(Vector3.RIGHT, -1.4 * arc)
		"Dive Kong", "Kong Up":
			# Llega en plancha con los brazos estirados por delante; recoge las piernas entre los
			# brazos sobre el obstáculo y se endereza para caer (o quedar de pie arriba)
			_tuck_pose(p, sin(clampf(s * 1.25, 0.0, 1.0) * PI) * 0.95)
			p.shoulder_l.x = lerpf(3.0, 0.4, _smooth(s / 0.7)); p.shoulder_r.x = p.shoulder_l.x
			p.elbow_l.x = 0.12; p.elbow_r.x = 0.12
			p.neck.x = 0.45 * (1.0 - s)
			_apply(p, KONG_EXIT_LEGS, _smooth((s - 0.55) / 0.3))
			# Se tumba en plancha en el primer cuarto (sin saltos de orientación) y se endereza al final
			return Basis(Vector3.RIGHT, -1.45 * minf(_smooth(s / 0.22), sin(PI * (0.3 + 0.7 * s))))
		"Double Kong":
			# Dos apoyos de manos: dos arcos de agrupado sobre el obstáculo
			var a2 := absf(sin(s * TAU))
			_tuck_pose(p, a2)
			p.shoulder_l.x = 2.6 - 1.2 * a2; p.shoulder_r.x = 2.6 - 1.2 * a2
			p.elbow_l.x = 0.2; p.elbow_r.x = 0.2
			return Basis(Vector3.RIGHT, -0.9 * a2)
		"Kash Vault":
			# Kong al principio, dash (piernas delante) al final
			if s < 0.5:
				_tuck_pose(p, sin(s * TAU) * 0.9)
				p.shoulder_l.x = 2.7; p.shoulder_r.x = 2.7
				return Basis(Vector3.RIGHT, -0.9 * sin(s * TAU))
			var k2 := sin((s - 0.5) * TAU)
			p.hip_l.x = 1.5 * k2; p.hip_r.x = 1.4 * k2
			p.knee_l.x = -0.2; p.knee_r.x = -0.3
			p.shoulder_l.x = -0.6 * k2; p.shoulder_r.x = -0.6 * k2
			return Basis(Vector3.RIGHT, 0.5 * k2)
		"Reverse Vault":
			# Giro completo de espaldas sobre el obstáculo, apoyando una mano
			p.hip_l.x = 1.0 * arc; p.hip_r.x = 0.8 * arc
			p.knee_l.x = -0.9 * arc; p.knee_r.x = -1.1 * arc
			p.shoulder_r.x = 1.2 * arc; p.shoulder_r.z = 0.6 * arc
			p.shoulder_l.z = -1.0 * arc
			p.spine.x = -0.3 * arc
			return Basis(Vector3.UP, -TAU * _ease_in_out(s)) * Basis(Vector3.BACK, 0.35 * arc)
		"Thief Vault":
			arc = clampf(sin(s * PI) * 1.7, 0.0, 1.0)    # la postura se forma ya al despegar
			# Piernas primero, juntas y rasantes; una mano atrás sobre el obstáculo, la otra delante
			# para equilibrar; tronco algo girado hacia la mano de apoyo
			p.hip_l.x = 1.35 * arc; p.hip_r.x = 1.2 * arc
			p.knee_l.x = -0.35 * arc; p.knee_r.x = -0.5 * arc
			p.shoulder_r.x = -0.9 * arc; p.shoulder_r.z = 0.35 * arc
			p.shoulder_l.x = 1.3 * arc; p.shoulder_l.z = -0.4 * arc
			p.spine.x = 0.2 * arc
			return Basis(Vector3.UP, 0.45 * arc) * Basis(Vector3.RIGHT, 0.32 * arc)
		"Turn Vault":
			# Dos manos sobre el obstáculo, cadera arriba y piernas recogidas a un lado mientras el
			# cuerpo gira media vuelta; cae mirando al obstáculo
			arc = clampf(sin(s * PI) * 1.7, 0.0, 1.0)
			var turn := _ease_in_out(clampf((s - 0.15) / 0.7, 0.0, 1.0))
			p.shoulder_l.x = 1.25; p.shoulder_r.x = 1.25
			p.elbow_l.x = 0.15; p.elbow_r.x = 0.15
			p.hip_l.x = 1.3 * arc; p.hip_r.x = 1.15 * arc
			p.knee_l.x = -1.5 * arc; p.knee_r.x = -1.3 * arc
			p.spine.x = -0.35 * arc
			return Basis(Vector3.UP, PI * turn) * Basis(Vector3.RIGHT, -0.55 * arc) * Basis(Vector3.BACK, 0.35 * arc)
		"Dash Vault":
			p.hip_l.x = 1.5 * arc; p.hip_r.x = 1.4 * arc
			p.knee_l.x = -0.2; p.knee_r.x = -0.3
			p.shoulder_l.x = -0.7 * arc; p.shoulder_r.x = -0.7 * arc
			return Basis(Vector3.RIGHT, 0.6 * arc)
		"Step Vault", "Step Up", "Climb Up":
			p.hip_r.x = 1.6 * arc; p.knee_r.x = -1.9 * arc
			p.hip_l.x = 0.6 * arc; p.knee_l.x = -0.9 * arc
			p.shoulder_l.x = 1.0 * arc; p.shoulder_r.x = 0.6 * arc
			p.spine.x = -0.35 * arc
			return Basis()
		_:
			# Speed / Lazy vault: cuerpo de lado, mano de apoyo abajo, piernas por encima
			p.hip_l.x = 1.3 * arc; p.hip_r.x = 1.1 * arc
			p.knee_l.x = -0.35 * arc; p.knee_r.x = -0.6 * arc
			p.shoulder_l.z = -0.2 * arc; p.shoulder_r.z = 1.4 * arc
			p.shoulder_l.x = 0.4 * arc
			var roll := 0.85 if kind == "Speed Vault" else 1.05
			return Basis(Vector3.BACK, roll * arc) * Basis(Vector3.UP, (0.5 if kind == "Lazy Vault" else 0.2) * arc)
