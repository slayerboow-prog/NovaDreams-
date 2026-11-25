class_name HumanModel
extends Node3D
## Atleta realista (malla esculpida, piel, pelo, ropa y texturas CC0 de MakeHuman, montado con
## MPFB en Blender: assets/characters/athlete.glb). Sus huesos siguen a las articulaciones del
## BodyRig, así que usa exactamente las mismas animaciones, IK y físicas que el cuerpo procedural.

const MODEL := "res://assets/characters/athlete.glb"
## articulación del BodyRig -> huesos del modelo que la siguen (el resto conserva su pose de reposo)
const MAP := {
	"pelvis": ["pelvis"], "spine": ["spine_01", "spine_02", "spine_03"], "neck": ["neck_01", "head"],
	"shoulder_l": ["upperarm_l"], "elbow_l": ["lowerarm_l"], "shoulder_r": ["upperarm_r"], "elbow_r": ["lowerarm_r"],
	"hip_l": ["thigh_l"], "knee_l": ["calf_l"], "hip_r": ["thigh_r"], "knee_r": ["calf_r"],
}
## Columna: cada vértebra toma una parte del giro de la espalda (curva redonda, no un bloque).
const SPINE_FRAC := {"spine_01": 0.35, "spine_02": 0.7, "spine_03": 1.0}
## Hacia dónde va el segmento desde cada articulación (en su espacio local, reposo).
const DIR := {"pelvis": Vector3.UP, "spine": Vector3.UP, "neck": Vector3.UP}

var skeleton: Skeleton3D
const FINGER_SIGN := 1.0
var _joints: Dictionary
var _links := []          # [articulación, hueso, base de corrección C]
var _pelvis_off := Vector3.ZERO
var _pelvis_bone := -1

func build(joints: Dictionary) -> bool:
	_joints = joints
	var scn := load(MODEL) as PackedScene
	if scn == null:
		return false
	var inst := scn.instantiate()
	add_child(inst)
	var found := inst.find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		return false
	skeleton = found[0]
	skeleton.reset_bone_poses()
	# El modelo mira a +z; el BodyRig mira a -z. Escala para que la cadera coincida.
	inst.rotation.y = PI
	var pb := skeleton.find_bone("pelvis")
	var hip_y := (skeleton.global_transform * skeleton.get_bone_global_rest(pb)).origin.y - global_position.y
	var rig_hip := (joints["pelvis"] as Node3D).global_position.y - global_position.y
	if hip_y > 0.01:
		inst.scale = Vector3.ONE * (rig_hip / hip_y)
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_tune_materials(mi as MeshInstance3D)
	# Calibración en reposo: base del hueso = base de la articulación * C
	for jn in MAP.keys():
		var j: Node3D = joints[jn]
		var jg := j.global_transform.orthonormalized()
		var dir_w: Vector3 = (jg.basis * DIR.get(jn, Vector3.DOWN)).normalized()
		for bn in MAP[jn]:
			var bi := skeleton.find_bone(bn)
			if bi < 0:
				continue
			var bg := skeleton.global_transform * skeleton.get_bone_global_rest(bi)
			var bb := bg.basis.orthonormalized()
			var align := Basis(Quaternion(bb.y.normalized(), dir_w)) if bb.y.normalized().dot(dir_w) > -0.999 else Basis(Vector3.RIGHT, PI)
			var target := align * bb
			_links.append([j, bi, jg.basis.inverse() * target, SPINE_FRAC.get(bn, 1.0)])
			if bn == "pelvis":
				_pelvis_bone = bi
				_pelvis_off = jg.affine_inverse() * bg.origin
	return true

## Materiales del atleta: el exportador los deja todos semitransparentes (orden de dibujo
## incorrecto y piel de plástico). Piel, ropa y zapatillas opacas con su rugosidad real y un leve
## contraluz en la ropa que despega la silueta del fondo.
func _tune_materials(mi: MeshInstance3D) -> void:
	for i in mi.mesh.get_surface_count():
		var src := mi.mesh.surface_get_material(i) as StandardMaterial3D
		if src == null:
			continue
		var m := src.duplicate() as StandardMaterial3D
		var nm := String(src.resource_name).to_lower()
		if nm.ends_with("body"):
			m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			m.roughness = 0.6
			m.metallic_specular = 0.3
		elif nm.contains("suit"):
			m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			m.roughness = 0.9
			m.metallic_specular = 0.25
			# La textura es negro absoluto (silueta plana); una tela negra real refleja algo de luz
			# y se le ven los pliegues: ~8 veces más clara (la franja y la estrella siguen blancas)
			m.albedo_color = Color(2.4, 2.4, 2.45)
			m.normal_scale = 1.4
			m.rim_enabled = true
			m.rim = 0.35
			m.rim_tint = 0.2
		elif nm.contains("shoe"):
			m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			m.roughness = 0.58
			m.metallic_specular = 0.4
			m.albedo_color = Color(2.1, 2.1, 2.1)
			m.rim_enabled = true
			m.rim = 0.2
			m.rim_tint = 0.3
		elif nm.contains("short02"):
			# Pelo: recorte por alfa (sin problemas de orden) y brillo suave
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.35
			m.roughness = 0.55
			m.metallic_specular = 0.45
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		elif nm.contains("eye") and not nm.contains("brow") and not nm.contains("lash"):
			m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			m.roughness = 0.15
			m.metallic_specular = 0.7
		mi.set_surface_override_material(i, m)

const FINGERS := ["index", "middle", "ring", "pinky"]
var _finger_bones := []    # [hueso, rotación de reposo, curva]

## Llamar después de la IK, cada frame. grip: 0..1 cuánto cierran las manos (agarrar las rodillas).
func sync(grip := 0.0) -> void:
	if skeleton == null:
		return
	if _finger_bones.is_empty():
		for sd in ["l", "r"]:
			for f in FINGERS:
				for k in [1, 2, 3]:
					var bi := skeleton.find_bone("%s_0%d_%s" % [f, k, sd])
					if bi >= 0:
						_finger_bones.append([bi, skeleton.get_bone_rest(bi).basis.get_rotation_quaternion(), 1.15 if k == 1 else 1.3])
			for k in [2, 3]:
				var tb := skeleton.find_bone("thumb_0%d_%s" % [k, sd])
				if tb >= 0:
					_finger_bones.append([tb, skeleton.get_bone_rest(tb).basis.get_rotation_quaternion(), 0.6])
	var g := clampf(grip, 0.0, 1.0) * 0.72 + 0.28        # en reposo, dedos algo curvados (mano relajada)
	for fb in _finger_bones:
		skeleton.set_bone_pose_rotation(fb[0], (fb[1] as Quaternion) * Quaternion(Vector3.RIGHT, FINGER_SIGN * float(fb[2]) * g))
	var sk_inv := skeleton.global_transform.affine_inverse()
	var sk_rot := skeleton.global_basis.orthonormalized().inverse()
	for l in _links:
		var j: Node3D = l[0]
		var bi: int = l[1]
		var jg := j.global_transform.orthonormalized()
		var jb := jg.basis
		var frac: float = l[3]
		if frac < 1.0:
			# Parte del giro de la espalda respecto a la pelvis
			var pq := (_joints["pelvis"] as Node3D).global_transform.orthonormalized().basis.get_rotation_quaternion()
			var rel := pq.inverse() * jb.get_rotation_quaternion()
			jb = Basis(pq * Quaternion.IDENTITY.slerp(rel, frac))
		var b: Basis = sk_rot * (jb * (l[2] as Basis))
		var origin := skeleton.get_bone_global_pose(bi).origin
		if bi == _pelvis_bone:
			origin = sk_inv * (jg * _pelvis_off)
		skeleton.set_bone_global_pose(bi, Transform3D(b.orthonormalized(), origin))
