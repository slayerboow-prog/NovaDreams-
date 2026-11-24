import bpy, os, sys
import addon_utils
addon_utils.enable("bl_ext.user_default.mpfb", default_set=True)
from bl_ext.user_default.mpfb.services.humanservice import HumanService
from bl_ext.user_default.mpfb.services.locationservice import LocationService
D = LocationService.get_user_data()
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
macro = {"gender": 1.0, "age": 0.45, "muscle": 1.0, "weight": 0.48, "proportions": 0.85, "height": 0.55,
         "cupsize": 0.5, "firmness": 0.5, "race": {"asian": 0.15, "caucasian": 0.55, "african": 0.3}}
bm = HumanService.create_human(macro_detail_dict=macro, feet_on_ground=True, scale=0.1)
rig = HumanService.add_builtin_rig(bm, "game_engine")
HumanService.set_character_skin(os.path.join(D, "skins/young_caucasian_male/young_caucasian_male.mhmat"), bm, skin_type="GAMEENGINE")
def add(rel, kind):
    p = os.path.join(D, rel)
    print("ADD", rel, os.path.exists(p))
    return HumanService.add_mhclo_asset(p, bm, asset_type=kind, subdiv_levels=0, material_type="GAMEENGINE")
add("eyes/high-poly/high-poly.mhclo", "Eyes")
add("eyebrows/eyebrow001/eyebrow001.mhclo", "Eyebrows")
add("eyelashes/eyelashes01/eyelashes01.mhclo", "Eyelashes")
add("hair/short02/short02.mhclo", "Hair")
add("clothes/male_casualsuit06/male_casualsuit06.mhclo", "Clothes")
add("clothes/shoes06/shoes06.mhclo", "Clothes")
bpy.ops.wm.save_as_mainfile(filepath="/opt/mh/out/athlete.blend")
for o in bpy.data.objects:
    print("OBJ", o.name, o.type, len(o.data.vertices) if o.type == "MESH" else "", [m.name for m in o.data.materials] if o.type == "MESH" else "")
print("BONES", [b.name for b in rig.data.bones])
