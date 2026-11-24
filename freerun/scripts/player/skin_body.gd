class_name SkinBody
extends Node3D
## Cuerpo continuo con "piel" (malla con esqueleto) generado por código, sin assets externos.
## Torso, cuello, brazos y piernas son UNA sola malla que se dobla en hombros, codos, caderas y
## rodillas (en vez de piezas sueltas que se separan al doblarse). Cada vértice pesa entre el hueso
## de arriba y el de abajo cerca de la articulación: los codos y rodillas se doblan con volumen.
## El esqueleto copia en cada fotograma la pose de las articulaciones de BodyRig (que siguen
## siendo las que animan, resuelven la IK y usan las pruebas).

const SEG := 18                       # vértices por anillo

var skeleton: Skeleton3D
var mesh_instance: MeshInstance3D
var _bone := {}                       # nombre de articulación -> índice de hueso
var _joints := {}

## Construye el esqueleto con el mismo árbol y las mismas posiciones de reposo que las articulaciones.
func build(joints: Dictionary, colors: Dictionary) -> void:
	_joints = joints
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	var order := ["pelvis", "spine", "neck", "shoulder_l", "elbow_l", "shoulder_r", "elbow_r",
		"hip_l", "knee_l", "hip_r", "knee_r"]
	var parent_of := {"spine": "pelvis", "neck": "spine", "shoulder_l": "spine", "elbow_l": "shoulder_l",
		"shoulder_r": "spine", "elbow_r": "shoulder_r", "hip_l": "pelvis", "knee_l": "hip_l",
		"hip_r": "pelvis", "knee_r": "hip_r"}
	for n in order:
		var i := skeleton.get_bone_count()
		skeleton.add_bone(n)
		_bone[n] = i
		if parent_of.has(n):
			skeleton.set_bone_parent(i, _bone[parent_of[n]])
		skeleton.set_bone_rest(i, Transform3D(Basis(), (joints[n] as Node3D).position))
	skeleton.reset_bone_poses()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Skin"
	mesh_instance.mesh = _make_mesh(colors)
	mesh_instance.material_override = _fabric_material()
	skeleton.add_child(mesh_instance)
	mesh_instance.skeleton = mesh_instance.get_path_to(skeleton)
	mesh_instance.skin = skeleton.create_skin_from_rest_transforms()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# Las piezas rígidas (cabeza, manos, zapatillas, capucha...) se enganchan a los huesos del
	# esqueleto: así se mueven exactamente a la vez que la piel (si siguieran a las articulaciones,
	# en movimientos rápidos la piel iría un instante por detrás y la mano o la zapatilla se separaban).
	for n in order:
		var j: Node3D = joints[n]
		var att := BoneAttachment3D.new()
		att.name = "Att_" + n
		att.bone_name = n
		skeleton.add_child(att)
		for c in j.get_children():
			if c is MeshInstance3D:
				var xf: Transform3D = (c as Node3D).transform
				j.remove_child(c)
				att.add_child(c)
				(c as Node3D).transform = xf

## Copia la pose actual de las articulaciones al esqueleto (después de la IK).
func sync() -> void:
	for n in _bone.keys():
		var j: Node3D = _joints[n]
		var i: int = _bone[n]
		skeleton.set_bone_pose_position(i, j.position)
		skeleton.set_bone_pose_rotation(i, j.quaternion)
	# Aplica la pose ya (no al final del fotograma): sin esto la piel iba un fotograma por detrás
	skeleton.force_update_all_bone_transforms()
	skeleton.notification(Skeleton3D.NOTIFICATION_UPDATE_SKELETON)   # sube la piel al render ya

## Tela: color por vértice (sudadera, pantalón, piel), relieve de tejido y borde de luz suave.
func _fabric_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true            # los colores de la paleta están en sRGB, como albedo_color
	m.roughness = 0.88
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.09
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.as_normal_map = true
	tex.bump_strength = 3.0
	tex.noise = noise
	m.normal_enabled = true
	m.normal_texture = tex
	m.normal_scale = 0.35
	m.uv1_scale = Vector3(9.0, 9.0, 1.0)
	m.rim_enabled = true
	m.rim = 0.25
	m.rim_tint = 0.6
	return m

# ------------------------------------------------------------------ malla

## Anillo: [y, rx, rz, desplazamiento z, {hueso: peso}, color]. Delante = -z.
func _make_mesh(c: Dictionary) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hood: Color = c.hoodie
	var hood_d: Color = c.hoodie_dark
	var pants: Color = c.pants
	var pants_d: Color = c.pants_dark
	var skin: Color = c.skin
	var sock: Color = c.sock
	var band: Color = c.get("band", c.pants_dark)
	var wrist: Color = c.get("wrist", c.skin)
	# Torso (de la entrepierna al cuello): cadera, cintura, pecho, hombros
	_loft(st, Vector3.ZERO, [
		[0.80, 0.12, 0.095, 0.01, {"pelvis": 1.0}, pants],
		[0.86, 0.163, 0.113, 0.014, {"pelvis": 1.0}, pants],
		[0.93, 0.172, 0.116, 0.012, {"pelvis": 1.0}, pants],
		[0.955, 0.17, 0.114, 0.01, {"pelvis": 0.9, "spine": 0.1}, pants],
		[0.955, 0.176, 0.12, 0.01, {"pelvis": 0.9, "spine": 0.1}, hood_d],      # bajo de la sudadera
		[0.985, 0.17, 0.115, 0.008, {"pelvis": 0.75, "spine": 0.25}, hood_d],
		[0.99, 0.166, 0.112, 0.008, {"pelvis": 0.7, "spine": 0.3}, hood],
		[1.05, 0.155, 0.106, 0.004, {"pelvis": 0.35, "spine": 0.65}, hood],
		[1.12, 0.155, 0.105, 0.0, {"spine": 1.0}, hood],
		[1.22, 0.166, 0.112, -0.004, {"spine": 1.0}, hood],
		[1.31, 0.178, 0.121, -0.008, {"spine": 1.0}, hood],
		[1.39, 0.193, 0.117, -0.003, {"spine": 1.0}, hood],
		[1.455, 0.198, 0.104, 0.004, {"spine": 1.0}, hood],
		[1.505, 0.176, 0.092, 0.01, {"spine": 1.0}, hood],
		[1.54, 0.1, 0.076, 0.012, {"spine": 0.85, "neck": 0.15}, hood],
		[1.555, 0.082, 0.072, 0.012, {"spine": 0.7, "neck": 0.3}, hood_d],        # cuello de la sudadera
		[1.585, 0.072, 0.068, 0.012, {"spine": 0.4, "neck": 0.6}, hood_d],
		[1.59, 0.06, 0.058, 0.01, {"spine": 0.35, "neck": 0.65}, hood_d],
	], true, false)
	# Cuello
	_loft(st, Vector3.ZERO, [
		[1.53, 0.055, 0.052, 0.008, {"spine": 0.5, "neck": 0.5}, skin],
		[1.60, 0.051, 0.049, 0.006, {"neck": 1.0}, skin],
		[1.70, 0.049, 0.047, 0.004, {"neck": 1.0}, skin],
	], false, false)
	for side in [["l", -1.0], ["r", 1.0]]:
		var sd: String = side[0]
		var x: float = side[1]
		var sh := "shoulder_" + sd
		var el := "elbow_" + sd
		# Brazo al descubierto (sudadera sin mangas): sisa en el hombro, deltoides, bíceps marcado,
		# codo, antebrazo musculado que se afina y muñequera
		_loft(st, Vector3(0.23 * x, 0, 0), [
			[1.535, 0.0, 0.0, 0.0, {sh: 1.0}, skin],                 # hombro redondeado (cúpula)
			[1.53, 0.034, 0.034, 0.0, {sh: 1.0}, skin],
			[1.512, 0.058, 0.056, 0.0, {sh: 1.0}, skin],
			[1.48, 0.069, 0.066, 0.0, {sh: 1.0}, skin],               # deltoides
			[1.42, 0.066, 0.064, 0.0, {sh: 1.0}, skin],
			[1.35, 0.062, 0.066, -0.01, {sh: 1.0}, skin],             # bíceps
			[1.275, 0.054, 0.056, -0.005, {sh: 1.0}, skin],
			[1.205, 0.046, 0.047, 0.0, {sh: 0.55, el: 0.45}, skin],
			[1.16, 0.05, 0.049, 0.0, {sh: 0.15, el: 0.85}, skin],
			[1.1, 0.05, 0.045, -0.004, {el: 1.0}, skin],            # antebrazo
			[1.03, 0.034, 0.03, 0.0, {el: 1.0}, skin],
			[1.0, 0.031, 0.027, 0.0, {el: 1.0}, skin],
			[0.995, 0.036, 0.032, 0.0, {el: 1.0}, wrist],            # muñequera
			[0.96, 0.036, 0.032, 0.0, {el: 1.0}, wrist],
			[0.955, 0.029, 0.024, 0.0, {el: 1.0}, skin],
			[0.95, 0.029, 0.023, 0.0, {el: 1.0}, skin],
		], false, false)
		var hp := "hip_" + sd
		var kn := "knee_" + sd
		# Pierna: muslo, rodilla, gemelo, tobillo (calcetín dentro de la zapatilla)
		_loft(st, Vector3(0.1 * x, 0, 0), [
			[1.0, 0.092, 0.092, 0.005, {"pelvis": 0.55, hp: 0.45}, pants],
			[0.93, 0.101, 0.102, 0.005, {"pelvis": 0.15, hp: 0.85}, pants],
			[0.84, 0.1, 0.099, 0.0, {hp: 1.0}, pants],
			[0.74, 0.092, 0.092, -0.004, {hp: 1.0}, pants],
			[0.62, 0.081, 0.081, -0.004, {hp: 1.0}, pants],
			[0.535, 0.073, 0.075, -0.004, {hp: 0.55, kn: 0.45}, pants],
			[0.49, 0.072, 0.075, 0.0, {hp: 0.2, kn: 0.8}, pants],
			[0.485, 0.075, 0.078, 0.0, {hp: 0.15, kn: 0.85}, band],   # correa de la rodilla
			[0.455, 0.075, 0.078, 0.0, {hp: 0.05, kn: 0.95}, band],
			[0.45, 0.071, 0.075, 0.0, {kn: 1.0}, pants],
			[0.38, 0.07, 0.075, 0.01, {kn: 1.0}, pants],
			[0.28, 0.064, 0.067, 0.008, {kn: 1.0}, pants],
			[0.18, 0.054, 0.055, 0.0, {kn: 1.0}, pants],
			[0.15, 0.044, 0.046, 0.0, {kn: 1.0}, pants_d],          # puño elástico del jogger
			[0.105, 0.043, 0.045, 0.0, {kn: 1.0}, pants_d],
			[0.105, 0.038, 0.04, 0.0, {kn: 1.0}, sock],
			[0.05, 0.036, 0.038, 0.0, {kn: 1.0}, sock],
		], false, false)
	st.index()
	return st.commit()

## Tubo de anillos horizontales (en reposo todo el cuerpo está vertical). cap_bottom/cap_top
## cierran el extremo con un abanico.
func _loft(st: SurfaceTool, base: Vector3, rings: Array, cap_bottom: bool, cap_top: bool) -> void:
	var nr := rings.size()
	var vcount_before := 0
	# Distancia acumulada a lo largo del tubo (coordenada v de la textura)
	var vacc := [0.0]
	for k in range(1, nr):
		vacc.append(float(vacc[k - 1]) + absf(float(rings[k][0]) - float(rings[k - 1][0])))
	for k in nr - 1:
		var a: Array = rings[k]
		var b: Array = rings[k + 1]
		if is_equal_approx(float(a[0]), float(b[0])) and float(a[1]) == float(b[1]):
			continue
		for j in SEG:
			var q := [[a, j, k], [b, j, k + 1], [b, j + 1, k + 1], [a, j + 1, k]]
			# dos triángulos por cuadrado, con la cara hacia fuera (el orden depende de si el tubo
			# se recorre hacia arriba, como el tronco, o hacia abajo, como brazos y piernas)
			var up := float(b[0]) > float(a[0])
			for idx in ([0, 2, 1, 0, 3, 2] if up else [0, 1, 2, 0, 2, 3]):
				var e: Array = q[idx]
				_vertex(st, base, rings, int(e[2]), int(e[1]), vacc)
	if cap_bottom:
		_cap(st, base, rings[0], true)
	if cap_top:
		_cap(st, base, rings[nr - 1], false)

func _vertex(st: SurfaceTool, base: Vector3, rings: Array, k: int, j: int, vacc: Array) -> void:
	var r: Array = rings[k]
	var ang := TAU * float(j % SEG) / float(SEG)
	var y := float(r[0])
	var rx := float(r[1])
	var rz := float(r[2])
	var ca := cos(ang)
	var sa := sin(ang)
	var p := base + Vector3(ca * rx, y, sa * rz + float(r[3]))
	# Normal de la elipse con la pendiente del radio (anillo anterior y siguiente)
	var k0 := maxi(k - 1, 0)
	var k1 := mini(k + 1, rings.size() - 1)
	var dy := float(rings[k1][0]) - float(rings[k0][0])
	var dr := (float(rings[k1][1]) + float(rings[k1][2])) * 0.5 - (float(rings[k0][1]) + float(rings[k0][2])) * 0.5
	var slope := 0.0 if absf(dy) < 0.0001 else -dr / dy * 0.45
	var n := Vector3(ca / maxf(rx, 0.001), slope / maxf((rx + rz) * 0.5, 0.001), sa / maxf(rz, 0.001)).normalized()
	_weights(st, r[4])
	st.set_color(r[5])
	st.set_uv(Vector2(float(j) / float(SEG) * PI * (rx + rz), float(vacc[k])))
	st.set_normal(n)
	st.add_vertex(p)

func _cap(st: SurfaceTool, base: Vector3, r: Array, bottom: bool) -> void:
	var y := float(r[0])
	var c := base + Vector3(0, y, float(r[3]))
	var n := Vector3.DOWN if bottom else Vector3.UP
	for j in SEG:
		var a0 := TAU * float(j) / float(SEG)
		var a1 := TAU * float(j + 1) / float(SEG)
		var p0 := base + Vector3(cos(a0) * float(r[1]), y, sin(a0) * float(r[2]) + float(r[3]))
		var p1 := base + Vector3(cos(a1) * float(r[1]), y, sin(a1) * float(r[2]) + float(r[3]))
		var tri := [c, p0, p1] if bottom else [c, p1, p0]
		for p in tri:
			_weights(st, r[4])
			st.set_color(r[5])
			st.set_uv(Vector2.ZERO)
			st.set_normal(n)
			st.add_vertex(p)

func _weights(st: SurfaceTool, w: Dictionary) -> void:
	var bones := PackedInt32Array([0, 0, 0, 0])
	var ws := PackedFloat32Array([0, 0, 0, 0])
	var i := 0
	var total := 0.0
	for name in w.keys():
		if i >= 4:
			break
		bones[i] = int(_bone[name])
		ws[i] = float(w[name])
		total += ws[i]
		i += 1
	for t in 4:
		ws[t] = ws[t] / maxf(total, 0.0001)
	st.set_bones(bones)
	st.set_weights(ws)
