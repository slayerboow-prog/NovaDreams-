import bpy, bmesh, addon_utils, os
from mathutils import Vector
addon_utils.enable("bl_ext.user_default.mpfb", default_set=True)
bpy.ops.wm.open_mainfile(filepath="/opt/mh/out/athlete.blend")
O = bpy.data.objects
body, suit, shoes, rig = O["Human"], O["Human.male_casualsuit06"], O["Human.shoes06"], O["Human.rig"]
ua = rig.matrix_world @ rig.data.bones["upperarm_l"].head_local
xs = abs(ua.x) - 0.012
print("shoulder x", ua)
# 1. Sin mangas: corte limpio (plano vertical por la sisa) solo en la parte alta de la camiseta
bm = bmesh.new(); bm.from_mesh(suit.data)
for sgn in (1, -1):
    geom = [f for f in bm.faces if f.calc_center_median().z > ua.z - 0.2]
    geom = list({v for f in geom for v in f.verts}) + list({e for f in geom for e in f.edges}) + geom
    bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(sgn * xs, 0, 0), plane_no=(sgn, 0, 0), clear_outer=True)
bm.to_mesh(suit.data); bm.free()
# 2. Brazos del cuerpo visibles
g = body.vertex_groups.get("Delete.male_casualsuit06")
rm = [v.index for v in body.data.vertices if abs(v.co.x) > xs - 0.045 and v.co.z > ua.z - 0.25]
g.remove(rm)
print("arm verts shown", len(rm))
# 3. Texturas
def swap(obj, key, path):
    for mat in obj.data.materials:
        for nd in mat.node_tree.nodes:
            if nd.type == "TEX_IMAGE" and nd.image and key in os.path.basename(nd.image.filepath):
                nd.image = bpy.data.images.load(path)
swap(suit, "diffuse", "/opt/mh/tex/suit_diffuse.png")
swap(shoes, "diffuse", "/opt/mh/tex/shoes_diffuse.png")
swap(body, "diffuse", "/opt/mh/tex/skin_diffuse.png")
for im in bpy.data.images:
    if im.size[0] > 1024:
        im.scale(1024, 1024)
bpy.ops.wm.save_as_mainfile(filepath="/opt/mh/out/athlete2.blend")
for o in O: o.select_set(o.type in ("MESH", "ARMATURE"))
bpy.ops.export_scene.gltf(filepath="/opt/mh/out/athlete.glb", export_format="GLB", use_selection=True, export_apply=True,
    export_animations=False, export_image_format="JPEG", export_jpeg_quality=88, export_yup=True)
print("EXPORTED", os.path.getsize("/opt/mh/out/athlete.glb"))
