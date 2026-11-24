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
## Hacia dónde va el segmento desde cada articulación (en su espacio local, reposo).
const DIR := {"pelvis": Vector3.UP, "spine": Vector3.UP, "neck": Vector3.UP}

var skeleton: Skeleton3D
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
			_links.append([j, bi, jg.basis.inverse() * target])
			if bn == "pelvis":
				_pelvis_bone = bi
				_pelvis_off = jg.affine_inverse() * bg.origin
	return true

## Llamar después de la IK, cada frame.
func sync() -> void:
	if skeleton == null:
		return
	var sk_inv := skeleton.global_transform.affine_inverse()
	var sk_rot := skeleton.global_basis.orthonormalized().inverse()
	for l in _links:
		var j: Node3D = l[0]
		var bi: int = l[1]
		var jg := j.global_transform.orthonormalized()
		var b: Basis = sk_rot * (jg.basis * (l[2] as Basis))
		var origin := skeleton.get_bone_global_pose(bi).origin
		if bi == _pelvis_bone:
			origin = sk_inv * (jg * _pelvis_off)
		skeleton.set_bone_global_pose(bi, Transform3D(b.orthonormalized(), origin))
