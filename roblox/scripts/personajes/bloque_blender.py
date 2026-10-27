#!/usr/bin/env python3
"""Estilo bloque «premium» (encargo del dueño, referencias en docs/personajes/referencia/): el cuerpo de
bloques de Roblox (R15, como hoy) y la identidad de cada personaje con ACCESORIOS 3D propios hechos en
Blender (pelo, gafas, batas y chaquetas por piezas, mochilas, botas, objetos), ropa con textura en las
plantillas clásicas (Shirt/Pants) y caras dibujadas a mano por expresión (una sola boca, FaceKit).

Piloto: Cosme (contra docs/personajes/referencia/cosme-estilo-dueno.png) y la familia del jugador y el
reparto principal: Mamá, Papá, Abu Rosa, Abu Tomás, Pip, Profe Lucía y Nico.

Seguridad de moderación: cada accesorio es un objeto (pelo, gafas, bota, bata…), nunca una parte del
cuerpo, y cada malla pasa scripts/audit/moderacion-mallas.py (0 marcas) y su vista gris de 6 lados.

Necesita Blender como módulo (pip install bpy==4.2.0), Pillow y numpy. Uso (desde roblox/):
    python3 scripts/personajes/bloque_blender.py                 todo
    python3 scripts/personajes/bloque_blender.py --solo Cosme     uno (o varios: Cosme,Nico)
    python3 scripts/personajes/bloque_blender.py --no-render      sin las vistas previas

Salida:
    assets/bloque/Bloque_<Key>.fbx                  los accesorios del personaje (una MeshPart por accesorio,
                                                    con su nombre; las grandes con su versión lejana …LOD)
    assets/bloque/tex/Bloque_<Key>_{color,normal,rugosidad}.png   atlas de sus accesorios (1024/512)
    assets/bloque/ropa/bloque_<key>_{camisa,pantalon}.png        plantillas clásicas 585x559
    assets/bloque/caras/bloque_<key>_cara_<expresión>.png        caras (512, fondo transparente)
    assets/bloque/manifest.json, src/shared/EstiloBloque.luau    (lo mismo para el juego)
    docs/personajes/estilo-bloque/*.jpg                         vistas previas (VISTA PREVIA, NO ES ROBLOX)
Subir: bash scripts/upload-estilo-bloque.sh (revisión de moderación antes; solo la sesión que publica).
"""
import argparse
import json
import math
import os
import sys
import tempfile
import time

import bpy  # noqa: I001  (bpy antes que bmesh)
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

import bloque_accesorios as A  # noqa: E402
import bloque_ropa as RO  # noqa: E402
import p3d_geo as G  # noqa: E402

OUT = os.path.join(ROOT, "assets", "bloque")
TEX = os.path.join(OUT, "tex")
DOCS = os.path.join(ROOT, "docs", "personajes", "estilo-bloque")
LUAU = os.path.join(ROOT, "src", "shared", "EstiloBloque.luau")
REF = os.path.join(ROOT, "docs", "personajes", "referencia", "cosme-estilo-dueno.png")
WORK = os.path.join(tempfile.gettempdir(), "estilo-bloque-vistas")
PREFIX = "Bloque_"
MAX_TRIS = 10000  # todos los accesorios de un personaje (móvil)
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
log = G.log

CAST_FACES = ["Neutral", "Happy", "Sad", "Angry", "Scared", "Talk"]
COSME_FACES = ["Grin", "Skeptic", "Laugh", "Scared", "Talk"]
FACE_NAMES = {"Neutral": "Normal", "Happy": "Contento", "Sad": "Triste", "Angry": "Enfadado", "Scared": "Asustado", "Talk": "Hablando",
              "Grin": "Sonrisa loca", "Skeptic": "Escéptico", "Laugh": "Riéndose"}

SALUDO_REF = "SALUDO"
REPARTO = [
    {"Key": "Cosme", "Name": "Cosme", "Title": "El inventor loco", "Cast": "Cosme", "Hero": True, "Kit": A.kit_cosme,
     "Skin": (238, 200, 162), "Hair": (172, 208, 244), "Coat": (236, 236, 230), "Faces": COSME_FACES,
     "Shirt": ("labcoat", {"main": (236, 236, 230), "under": (30, 30, 34)}), "Pants": ("cargo", {"main": (66, 48, 36)}),
     "Quote": "«El mundo es un laboratorio gigante… ¡y yo soy el científico!»"},
    {"Key": "Familia_Mama", "Name": "Mamá", "Title": "Cariñosa y siempre con prisas", "Cast": "Familia", "Variant": "NPC.MAMA", "Hero": True, "Kit": A.kit_mama,
     "Skin": (198, 150, 112), "Hair": (110, 70, 40), "Coat": (232, 150, 172), "Eye": (92, 60, 38), "Faces": CAST_FACES,
     "Face": {"Lash": True, "Lip": (200, 90, 100), "EyeR": 0.12},
     "Shirt": ("cardigan", {"main": (232, 150, 172), "under": (236, 226, 206)}), "Pants": ("jeans", {"main": (60, 72, 104)})},
    {"Key": "Familia_Papa", "Name": "Papá", "Pose": SALUDO_REF, "Title": "Tranquilo y trabajador", "Cast": "Familia", "Variant": "NPC.PAPA", "Hero": True, "Kit": A.kit_papa,
     "Skin": (198, 150, 112), "Hair": (52, 36, 26), "Coat": (32, 32, 36), "Eye": (92, 60, 38), "Faces": CAST_FACES,
     "Face": {"Stubble": True, "BrowThick": 0.05},
     "Shirt": ("cardigan", {"main": (32, 32, 36), "under": (240, 240, 238)}), "Pants": ("jeans", {"main": (44, 54, 80)})},
    {"Key": "Abu_Rosa", "Name": "Abu Rosa", "Title": "Sabia, divertida y con mil historias", "Cast": "Abu", "Variant": "NPC.ABU_ROSA", "Hero": False, "Kit": A.kit_abu_rosa,
     "Skin": (234, 196, 160), "Hair": (236, 236, 240), "Coat": (176, 146, 206), "Eye": (70, 110, 70), "Faces": CAST_FACES,
     "Face": {"Wrinkles": True, "Lip": (190, 100, 110), "Brow": (190, 188, 192)},
     "Shirt": ("cardigan", {"main": (176, 146, 206), "under": (240, 232, 215)}), "Pants": ("trousers", {"main": (112, 102, 98)})},
    {"Key": "Abu_Tomas", "Name": "Abu Tomás", "Title": "Tranquilo y con buenos consejos", "Cast": "Abu", "Variant": "NPC.ABU_TOMAS", "Hero": False, "Kit": A.kit_abu_tomas,
     "Skin": (234, 196, 160), "Hair": (240, 240, 242), "Coat": (78, 116, 66), "Eye": (100, 110, 120), "Faces": CAST_FACES,
     "Face": {"Wrinkles": True, "Brow": (225, 225, 228), "BrowThick": 0.05},
     "Shirt": ("plaid", {"main": (168, 64, 52)}), "Pants": ("trousers", {"main": (100, 90, 76)})},
    {"Key": "Pip", "Name": "Pip", "Title": "El robot mayordomo de Cosme", "Cast": "Pip", "Hero": True, "Kit": A.kit_pip, "Robot": True,
     "Skin": (170, 180, 195), "Hair": (120, 130, 150), "Coat": (110, 120, 142), "Glow": (90, 200, 255), "Faces": CAST_FACES, "FaceOn": "Pantalla",
     "Face": {"Glow": (90, 210, 255), "EyeR": 0.1},
     "Shirt": ("tailcoat", {"main": (110, 120, 142), "under": (240, 240, 240)}), "Pants": ("trousers", {"main": (90, 100, 120)})},
    {"Key": "Lucia", "Name": "Profe Lucía", "Title": "Tutora de 1.º A", "Cast": "Lucia", "Hero": False, "Kit": A.kit_lucia,
     "Skin": (226, 186, 150), "Hair": (128, 58, 34), "Coat": (230, 180, 52), "Eye": (120, 96, 52), "Faces": CAST_FACES,
     "Face": {"Lash": True, "Lip": (190, 95, 95)},
     "Shirt": ("cardigan", {"main": (230, 180, 52), "under": (244, 244, 242)}), "Pants": ("trousers", {"main": (60, 70, 100)})},
    {"Key": "Nico", "Name": "Nico", "Pose": SALUDO_REF, "Title": "Deportista e impulsivo", "Cast": "Nico", "Hero": True, "Kit": A.kit_nico, "Kid": True,
     "Skin": (236, 196, 160), "Hair": (92, 58, 30), "Backpack": (200, 50, 50), "Eye": (92, 60, 38), "Faces": CAST_FACES,
     "Face": {"Freckles": True, "EyeR": 0.13},
     "Shirt": ("sport", {"main": (220, 60, 50), "stripe": (245, 245, 245)}), "Pants": ("track", {"main": (40, 60, 120), "stripe": (245, 245, 245)})},
]


def by_key(k):
    for s in REPARTO:
        if s["Key"] == k:
            return s
    return None


def lkey(spec):
    return spec["Key"].lower()


# ====================================================================== ropa y caras (PIL)
def draw_textures(spec):
    k = lkey(spec)
    out = {}
    kind, cols = spec["Shirt"]
    out["Shirt"] = RO.save(RO.shirt_template(kind, cols, hash(k) % 1000), os.path.join(OUT, "ropa", f"bloque_{k}_camisa.png"))
    kind, cols = spec["Pants"]
    out["Pants"] = RO.save(RO.pants_template(kind, cols, hash(k) % 1000 + 7), os.path.join(OUT, "ropa", f"bloque_{k}_pantalon.png"))
    faces = {}
    for e in spec["Faces"]:
        path = os.path.join(OUT, "caras", f"bloque_{k}_cara_{e.lower()}.png")
        if spec["Key"] == "Cosme":
            RO.cosme_face(e, path)
        else:
            RO.person_face(spec, e, path)
        faces[e] = path
    out["Faces"] = faces
    return out


# ====================================================================== accesorios: atlas, horneado, LOD, FBX
def build_accessories(spec, bake=True):
    G.reset()
    K = A.Kit(spec)
    spec["Kit"](K)
    name = PREFIX + spec["Key"]
    size = 1024 if spec["Hero"] else 512
    solid = [a for a in K.accs if a.glow is None]
    tris = sum(G.tris(a.obj) for a in K.accs)
    log(f"{spec['Key']}: {len(K.accs)} accesorios, {tris} triángulos (tope {MAX_TRIS}): " + ", ".join(f"{a.name} {G.tris(a.obj)}" for a in K.accs))
    # UV de cada accesorio con su resolución, todos juntos en un atlas
    for a in solid:
        a.obj["texel"] = a.texel
    G.uv_islands_scaled([a.obj for a in solid])
    for a in solid:
        vg = a.obj.vertex_groups.new(name="acc:" + a.name)
        vg.add(list(range(len(a.obj.data.vertices))), 1.0, "REPLACE")
    copies = []
    for a in solid:
        c = a.obj.copy()
        c.data = a.obj.data.copy()
        G.coll().objects.link(c)
        copies.append(c)
    G.select_only(copies, copies[0])
    bpy.ops.object.join()
    atlas = bpy.context.view_layer.objects.active
    atlas.name = "Atlas"
    G.pack_uv(atlas)
    paths = None
    if bake:
        os.makedirs(TEX, exist_ok=True)
        for a in solid:
            a.obj.hide_render = True
        paths = G.bake([atlas], name, size, TEX)
    pbr = G.pbr_material(name, paths) if paths else None
    # separar el atlas otra vez en accesorios (con sus UV del atlas)
    for a in solid:
        old = a.obj
        c = atlas.copy()
        c.data = atlas.data.copy()
        G.coll().objects.link(c)
        gi = c.vertex_groups["acc:" + a.name].index
        bm = bmesh.new()
        bm.from_mesh(c.data)
        dl = bm.verts.layers.deform.active
        kill = [v for v in bm.verts if gi not in v[dl]]
        bmesh.ops.delete(bm, geom=kill, context="VERTS")
        bm.to_mesh(c.data)
        bm.free()
        c.vertex_groups.clear()
        c.data.materials.clear()
        if pbr:
            c.data.materials.append(pbr)
        for p in c.data.polygons:
            p.material_index = 0
        me = old.data
        bpy.data.objects.remove(old)
        bpy.data.meshes.remove(me)
        c.name = a.name
        c.data.name = name + "_" + a.name
        c.hide_render = False
        a.obj = c
    me = atlas.data
    bpy.data.objects.remove(atlas)
    bpy.data.meshes.remove(me)
    for a in K.accs:
        if a.glow is not None:
            a.obj.data.name = name + "_" + a.name
    # versiones lejanas de los grandes
    lods = []
    for a in K.accs:
        if a.lod:
            lo = a.obj.copy()
            lo.data = a.obj.data.copy()
            lo.name = a.name + "LOD"
            lo.data.name = name + "_" + a.name + "LOD"
            G.coll().objects.link(lo)
            d = lo.modifiers.new("LOD", "DECIMATE")
            d.decimate_type = "COLLAPSE"
            d.ratio = 0.3
            G.apply_mods(lo)
            lo.hide_render = True
            a.lod_obj = lo
            lods.append(lo)
    return K, paths, size, lods


def rb(v):
    return [round(v.x, 4), round(v.z, 4), round(-v.y, 4)]


def bbox(obj):
    pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return (lo + hi) / 2, hi - lo


def manifest_entry(spec, K, size):
    accs = []
    for a in K.accs:
        c, s = bbox(a.obj)
        pc = Vector(A.PARTS[a.part][0])
        e = {"Name": a.name, "Part": a.part, "Offset": rb(c - pc), "Size": [round(s.x, 4), round(s.z, 4), round(s.y, 4)], "Tris": G.tris(a.obj), "Label": a.label}
        if a.glow is not None:
            e["Glow"] = [int(round(((x ** (1 / 2.2)) if x > 0 else 0) * 255)) for x in a.glow]
        if a.lod:
            e["Lod"] = a.name + "LOD"
            e["LodTris"] = G.tris(a.lod_obj)
        accs.append(e)
    k = lkey(spec)
    return {
        "Key": spec["Key"], "Name": spec["Name"], "Cast": spec["Cast"], "Variant": spec.get("Variant"), "Asset": PREFIX + spec["Key"],
        "Hero": spec["Hero"], "Kid": bool(spec.get("Kid")), "TextureSize": size, "Tris": sum(x["Tris"] for x in accs), "MaxTris": MAX_TRIS,
        "FaceOn": spec.get("FaceOn", "CabezaBloque"), "Skin": list(spec["Skin"]),
        "Faces": {e: f"bloque_{k}_cara_{e.lower()}" for e in spec["Faces"]}, "Shirt": f"bloque_{k}_camisa", "Pants": f"bloque_{k}_pantalon",
        "Textures": {m: f"{PREFIX}{spec['Key']}_{m}" for m in ("color", "normal", "rugosidad")}, "Accessories": accs,
    }


def export(spec, K, lods):
    os.makedirs(OUT, exist_ok=True)
    objs = [a.obj for a in K.accs] + lods
    path = os.path.join(OUT, PREFIX + spec["Key"] + ".fbx")
    G.select_only(objs)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0, axis_forward="-Z", axis_up="Y",
                             mesh_smooth_type="FACE", use_mesh_modifiers=True, add_leaf_bones=False, path_mode="STRIP", embed_textures=False, use_custom_props=False)
    return path


# ====================================================================== cuerpo de bloques (vista previa)
FACES_ORDER = ("F", "B", "R", "L", "U", "D")


def template_box(name, center, size, region, v0, v1, img_mats, up=True, down=True):
    """Caja de una parte del R15 con las UV de la plantilla clásica (como hace Roblox con Shirt/Pants):
    region = dict F/B/R/L/U/D -> (x, y, w, h) en píxeles; v0..v1 = el trozo de alto de esta parte."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=0.03, segments=2, affect="EDGES")
    uv = bm.loops.layers.uv.new("UVMap")
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    TW, TH = 585.0, 559.0
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        if ax == 1:
            key = "F" if n.y > 0 else "B"
        elif ax == 0:
            key = "R" if n.x > 0 else "L"
        else:
            key = "U" if n.z > 0 else "D"
        rect = region.get(key)
        for l in f.loops:
            p = l.vert.co
            if rect is None:
                l[uv].uv = (0.0, 0.0)
                continue
            x, y, w, h = rect
            if key == "F":
                u, t = (hx - p.x) / (2 * hx), (hz - p.z) / (2 * hz)
            elif key == "B":
                u, t = (p.x + hx) / (2 * hx), (hz - p.z) / (2 * hz)
            elif key == "R":
                u, t = (p.y + hy) / (2 * hy), (hz - p.z) / (2 * hz)
            elif key == "L":
                u, t = (hy - p.y) / (2 * hy), (hz - p.z) / (2 * hz)
            elif key == "U":
                u, t = (hx - p.x) / (2 * hx), (p.y + hy) / (2 * hy)
            else:
                u, t = (hx - p.x) / (2 * hx), (hy - p.y) / (2 * hy)
            if key in ("F", "B", "R", "L"):
                t = v0 + (v1 - v0) * t
            px = x + u * w
            py = y + t * h
            l[uv].uv = (px / TW, 1 - py / TH)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = G.new_obj(name, me)
    o.location = Vector(center)
    for m in img_mats:
        o.data.materials.append(m)
    return o


def clothing_mat(name, base_rgb, layers):
    """Material de vista previa: color del cuerpo + capas de plantilla (pantalón, camisa) por su alfa."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    b = nt.nodes.get("Principled BSDF")
    b.inputs["Roughness"].default_value = 0.7
    col = None
    base = (*G.lin(base_rgb), 1.0)
    cur_socket = None
    for path in layers:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(path, check_existing=True)
        tex.interpolation = "Closest" if False else "Linear"
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        nt.links.new(tex.outputs["Alpha"], mix.inputs[0])
        if cur_socket is None:
            mix.inputs[6].default_value = base
        else:
            nt.links.new(cur_socket, mix.inputs[6])
        nt.links.new(tex.outputs["Color"], mix.inputs[7])
        cur_socket = mix.outputs[2]
    if cur_socket is None:
        b.inputs["Base Color"].default_value = base
    else:
        nt.links.new(cur_socket, b.inputs["Base Color"])
    return mat


def build_body(spec, tex):
    """El R15 de bloques del personaje con su ropa (plantillas), en reposo. Devuelve {parte: objeto}."""
    skin = spec["Skin"]
    shirt, pants = tex["Shirt"], tex["Pants"]
    m_upper = clothing_mat("cuerpo_arriba", skin, [shirt])
    m_lower = clothing_mat("cuerpo_cadera", skin, [pants, shirt])
    m_leg = clothing_mat("cuerpo_pierna", skin, [pants])
    T, Rr, Ll = RO.TORSO, RO.RIGHT, RO.LEFT
    parts = {}
    arm_split = {"Upper": (0.0, 0.464), "Lower": (0.464, 0.881), "Hand": (0.881, 1.0)}
    leg_split = {"Upper": (0.0, 0.45), "Lower": (0.45, 0.889), "Foot": (0.889, 1.0)}
    # (en la vista previa las cajas no se solapan: cada parte de articulación a articulación, como se ve en
    # Roblox; si no, las caras que coinciden salen negras)
    SPAN = {"UpperTorso": (2.4, 4.0), "LowerTorso": (2.0, 2.4), "UpperArm": (3.04, 3.955), "LowerArm": (2.28, 3.04), "Hand": (2.01, 2.28),
            "UpperLeg": (1.17, 2.19), "LowerLeg": (0.18, 1.17), "Foot": (-0.07, 0.18)}
    for name, (c, s) in A.PARTS.items():
        if name == "Head":
            continue
        tag = name.replace("Right", "").replace("Left", "")
        if tag in SPAN:
            z0, z1 = SPAN[tag]
            c = (c[0], c[1], (z0 + z1) / 2)
            s = (s[0], s[1], z1 - z0)
        if name == "UpperTorso":
            reg = {k: v for k, v in T.items() if k != "D"}
            o = template_box(name, c, s, reg, 0.0, 0.8, [m_upper])
        elif name == "LowerTorso":
            reg = {k: v for k, v in T.items() if k != "U"}
            o = template_box(name, c, s, reg, 0.8, 1.0, [m_lower])
        else:
            side = Rr if name.startswith("Right") else Ll
            arm = "Arm" in name or "Hand" in name
            seg = "Upper" if "Upper" in name else ("Lower" if "Lower" in name else ("Hand" if "Hand" in name else "Foot"))
            v0, v1 = (arm_split if arm else leg_split)[seg]
            reg = {k: v for k, v in side.items() if (k not in ("U", "D")) or (k == "U" and seg == "Upper") or (k == "D" and seg in ("Hand", "Foot"))}
            o = template_box(name, c, s, reg, v0, v1, [m_upper if arm else m_leg])
        parts[name] = o
    return parts


def face_plane(spec, K, face_png):
    """El Decal de la cara (vista previa): un plano delante de la cara del accesorio donde va la cara
    (CabezaBloque o la pantalla de Pip), del tamaño de su cara delantera, como hace Roblox."""
    target = None
    for a in K.accs:
        if a.name == spec.get("FaceOn", "CabezaBloque"):
            target = a.obj
    if target is None:
        for a in K.accs:
            if a.name == "CabezaBloque":
                target = a.obj
    c, s = bbox(target)
    if spec.get("FaceOn") == "Pantalla":
        s = Vector((1.0, s.y, 0.82))
        c = Vector((c.x, c.y, A.HEAD_C.z))
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.5)
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        for l in f.loops:
            l[uv].uv = (0.5 - l.vert.co.x, l.vert.co.y + 0.5)
    for v in bm.verts:
        v.co = Vector((v.co.x * s.x, 0, v.co.y * s.z))
    me = bpy.data.meshes.new("Cara")
    bm.to_mesh(me)
    bm.free()
    o = G.new_obj("CaraDecal", me)
    o.location = Vector((c.x, c.y + s.y / 2 + 0.004, c.z))
    mat = bpy.data.materials.new("cara")
    mat.use_nodes = True
    mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else None
    nt = mat.node_tree
    b = nt.nodes.get("Principled BSDF")
    tx = nt.nodes.new("ShaderNodeTexImage")
    tx.image = bpy.data.images.load(face_png, check_existing=False)
    tx.name = "CaraTex"
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    out = nt.nodes.get("Material Output")
    nt.links.new(tx.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.6
    if spec.get("Robot"):
        nt.links.new(tx.outputs["Color"], b.inputs["Emission Color"])
        b.inputs["Emission Strength"].default_value = 2.5
    nt.links.new(tx.outputs["Alpha"], mix.inputs[0])
    nt.links.new(tr.outputs[0], mix.inputs[1])
    nt.links.new(b.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])
    o.data.materials.append(mat)
    return o, tx


def set_face(tx_node, path):
    tx_node.image = bpy.data.images.load(path, check_existing=True)


def rig(body, K, face):
    """Para posar: cada parte gira en su articulación (R15) y lleva sus accesorios."""
    joints = {n: G.R15_JOINTS[n] for n in G.R15_ORDER if n != "HumanoidRootPart"}
    for name, o in body.items():
        piv = joints[name][0]
        me = o.data
        shift = o.location - piv
        for v in me.vertices:
            v.co = v.co + shift
        o.location = piv
    bpy.context.view_layer.update()
    for name, o in body.items():
        parent = joints[name][1]
        if parent in body:
            mw = o.matrix_world.copy()
            o.parent = body[parent]
            o.matrix_world = mw
    for a in K.accs:
        for ob in [a.obj] + ([a.lod_obj] if getattr(a, "lod_obj", None) else []):
            mw = ob.matrix_world.copy()
            ob.parent = body[a.part] if a.part != "Head" else body["UpperTorso"]
            ob.matrix_world = mw
    # la cabeza (accesorios de la cabeza y la cara) gira con un vacío en el cuello
    neck = bpy.data.objects.new("Cuello", None)
    G.coll().objects.link(neck)
    neck.location = joints["Head"][0]
    bpy.context.view_layer.update()
    mw = neck.matrix_world.copy()
    neck.parent = body["UpperTorso"]
    neck.matrix_world = mw
    for a in K.accs:
        if a.part == "Head":
            for ob in [a.obj] + ([a.lod_obj] if getattr(a, "lod_obj", None) else []):
                mw = ob.matrix_world.copy()
                ob.parent = neck
                ob.matrix_world = mw
    mw = face.matrix_world.copy()
    face.parent = neck
    face.matrix_world = mw
    body["Head"] = neck
    return body


def pose(body, rots):
    for name, o in body.items():
        e = rots.get(name, (0, 0, 0))
        o.rotation_euler = tuple(math.radians(x) for x in e)
    bpy.context.view_layer.update()


HERO = {"RightUpperArm": (40, -40, 0), "RightLowerArm": (60, 0, 0), "LeftUpperArm": (35, 0, 15), "LeftLowerArm": (70, 0, -20),
        "RightUpperLeg": (-6, -8, 0), "LeftUpperLeg": (8, 6, 0), "LeftLowerLeg": (-8, 0, 0), "Head": (4, 0, 8), "UpperTorso": (0, 0, -6)}
# (los que no llevan nada en la mano saludan)
SALUDO = {"RightUpperArm": (10, -150, 0), "RightLowerArm": (0, -25, 0), "LeftUpperArm": (6, 0, 0), "LeftLowerArm": (20, 0, 0),
          "RightUpperLeg": (-4, -6, 0), "LeftUpperLeg": (6, 5, 0), "Head": (2, 0, 10), "UpperTorso": (0, 0, -6)}
WALK = {"RightUpperLeg": (28, 0, 0), "LeftUpperLeg": (-28, 0, 0), "RightLowerLeg": (-10, 0, 0), "LeftLowerLeg": (-35, 0, 0),
        "RightUpperArm": (-24, 0, 0), "LeftUpperArm": (24, 0, 0), "RightLowerArm": (12, 0, 0), "LeftLowerArm": (12, 0, 0)}


def studio(scene, samples):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.view_settings.view_transform = "Standard"
    scene.render.film_transparent = True
    w = bpy.data.worlds.new("estudio")
    scene.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.42, 0.58, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.6

    def area(name, loc, energy, size, color=(1, 1, 1)):
        L = bpy.data.lights.new(name, "AREA")
        L.energy, L.size, L.color = energy, size, color
        o = bpy.data.objects.new(name, L)
        o.location = Vector(loc)
        o.rotation_euler = (Vector((0, 0, 3.2)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        G.coll().objects.link(o)

    area("Clave", (6.0, 9.0, 9.5), 2300, 5.0, (1.0, 0.96, 0.9))
    area("Relleno", (-8.0, 7.0, 4.0), 750, 7.0, (0.8, 0.88, 1.0))
    area("Contra", (-3.0, -9.0, 8.0), 1900, 4.0, (0.7, 0.85, 1.0))
    floor = G.blob("Suelo", (0, 0, -0.57), (7, 7, 0.5), segs=48, rings=12)
    G.assign(floor, G.mat_plain("suelo", (0.2, 0.22, 0.28), 0.8))
    floor.is_shadow_catcher = True
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    G.coll().objects.link(cam)
    scene.camera = cam
    return cam


def shoot(scene, cam, eye, target, lens, path, res):
    scene.render.resolution_x, scene.render.resolution_y = res
    cam.location = Vector(eye)
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    bpy.ops.render.render(write_still=True)
    return path


def render_all(spec, K, tex, samples):
    scene = bpy.context.scene
    for a in K.accs:
        a.obj.hide_render = False
    body = build_body(spec, tex)
    first = spec["Faces"][0]
    face, tx = face_plane(spec, K, tex["Faces"][first])
    body = rig(body, K, face)
    cam = studio(scene, samples)
    k = lkey(spec)
    os.makedirs(WORK, exist_ok=True)
    out = {}
    pose(body, {})
    hz = 3.0
    out["frente"] = shoot(scene, cam, (0, 17, 3.4), (0, 0, hz), 50, os.path.join(WORK, f"{k}_frente.png"), (700, 980))
    out["espalda"] = shoot(scene, cam, (0, -17, 3.6), (0, 0, hz), 50, os.path.join(WORK, f"{k}_espalda.png"), (700, 980))
    out["lado"] = shoot(scene, cam, (-17, 0.5, 3.4), (0, 0, hz), 50, os.path.join(WORK, f"{k}_lado.png"), (700, 980))
    out["fila"] = shoot(scene, cam, (6.5, 15.5, 3.6), (0, 0, hz), 50, os.path.join(WORK, f"{k}_fila.png"), (600, 980))
    pose(body, SALUDO if spec.get("Pose") == "SALUDO" else HERO)
    out["heroe"] = shoot(scene, cam, (-5.0, 13.5, 4.3), (0.2, 0, 3.2), 45, os.path.join(WORK, f"{k}_heroe.png"), (900, 1100))
    pose(body, WALK)
    out["andar"] = shoot(scene, cam, (11.0, 11.0, 3.6), (0, 0, 2.9), 50, os.path.join(WORK, f"{k}_andar.png"), (600, 860))
    pose(body, {})
    faces = []
    hc = A.HEAD_C
    for e in spec["Faces"]:
        set_face(tx, tex["Faces"][e])
        faces.append((e, shoot(scene, cam, (0.9, 6.0, hc.z + 0.35), (0, 0, hc.z + 0.12), 55, os.path.join(WORK, f"{k}_cara_{e}.png"), (520, 560))))
    set_face(tx, tex["Faces"][first])
    out["caras"] = faces
    # despiece: cada grupo de accesorios solo (como en la hoja del dueño)
    for o in list(body.values()) + [face]:
        o.hide_render = True
    groups = {}
    for a in K.accs:
        groups.setdefault(a.label, []).append(a)
    pieces = []
    scene.cycles.samples = max(8, samples // 2)
    for label, accs in groups.items():
        for a in K.accs:
            a.obj.hide_render = a not in accs
        pts = []
        for a in accs:
            pts += [a.obj.matrix_world @ v.co for v in a.obj.data.vertices]
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        c = (lo + hi) / 2
        r = max((hi - lo).length / 2, 0.3)
        d = Vector((0.55, 1.0, 0.45)).normalized()
        pieces.append((label, shoot(scene, cam, c + d * r * 3.4, c, 50, os.path.join(WORK, f"{k}_pieza_{len(pieces)}.png"), (360, 360))))
    for a in K.accs:
        a.obj.hide_render = False
    for o in list(body.values()) + [face]:
        o.hide_render = False
    scene.cycles.samples = samples
    out["piezas"] = pieces
    return out


# ====================================================================== hojas (PIL)
def fonts(size, bold=True):
    from PIL import ImageFont

    return ImageFont.truetype(FONT_BOLD if bold else FONT, size)


def backdrop(w, h, top=(28, 70, 150), bottom=(10, 20, 50)):
    from PIL import Image, ImageDraw

    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)))
    for x in range(0, w, 48):
        d.line([(x, 0), (x, h)], fill=(36, 62, 120))
    for y in range(0, h, 48):
        d.line([(0, y), (w, y)], fill=(36, 62, 120))
    return img


def panel(img, box, title=None):
    from PIL import ImageDraw

    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle(box, 18, fill=(10, 22, 52, 170), outline=(60, 120, 220, 255), width=3)
    if title:
        d.rounded_rectangle([box[0] + 14, box[1] + 12, box[0] + 30 + d.textlength(title, font=fonts(26)), box[1] + 52], 10, fill=(14, 30, 70, 255))
        d.text((box[0] + 22, box[1] + 16), title, font=fonts(26), fill=(235, 242, 255))


def tag_preview(img):
    from PIL import ImageDraw

    d = ImageDraw.Draw(img)
    f = fonts(22)
    text = "VISTA PREVIA, NO ES ROBLOX"
    tw = d.textlength(text, font=f)
    x1, y1 = img.width - 18, img.height - 16
    d.rounded_rectangle([x1 - tw - 32, y1 - 40, x1, y1], 10, fill=(170, 28, 40))
    d.text((x1 - tw - 16, y1 - 34), text, font=f, fill=(255, 255, 255))


def paste_fit(dst, src, box, label=None, crop=True, sub=None, label_size=22):
    from PIL import Image, ImageDraw

    im = src if not isinstance(src, str) else Image.open(src).convert("RGBA")
    if crop:
        bb = im.split()[3].point(lambda a: 255 if a > 160 else 0).getbbox()
        if bb:
            pad = 10
            im = im.crop((max(0, bb[0] - pad), max(0, bb[1] - pad), min(im.width, bb[2] + pad), min(im.height, bb[3] + pad)))
    x0, y0, x1, y1 = box
    lab_h = (36 if label else 0) + (24 if sub else 0)
    k = min((x1 - x0) / im.width, (y1 - y0 - lab_h) / im.height)
    im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    dst.paste(im, (x0 + (x1 - x0 - im.width) // 2, y0 + (y1 - y0 - lab_h - im.height) // 2), im)
    d = ImageDraw.Draw(dst)
    if label:
        f = fonts(label_size)
        while d.textlength(label, font=f) > (x1 - x0) - 8 and label_size > 12:
            label_size -= 1
            f = fonts(label_size)
        tw = d.textlength(label, font=f)
        d.text((x0 + (x1 - x0 - tw) / 2, y1 - lab_h + 4), label, font=f, fill=(240, 244, 255))
    if sub:
        f = fonts(17, False)
        tw = d.textlength(sub, font=f)
        d.text((x0 + (x1 - x0 - tw) / 2, y1 - 24), sub, font=f, fill=(180, 196, 230))


def character_sheet(spec, shots, entry, path):
    """Hoja como la del dueño: el personaje grande con su título, espalda y lado, expresiones y el
    despiece de accesorios."""
    from PIL import ImageDraw

    W, H = 2600, 1500
    img = backdrop(W, H)
    d = ImageDraw.Draw(img)
    d.text((40, 30), spec["Name"].upper(), font=fonts(110), fill=(240, 248, 255))
    d.text((48, 160), spec["Title"].upper(), font=fonts(44), fill=(120, 200, 255))
    if spec.get("Quote"):
        d.text((48, 230), spec["Quote"], font=fonts(28, False), fill=(225, 235, 255))
    paste_fit(img, shots["heroe"], (40, 280, 860, 1440))
    panel(img, (880, 30, 1330, 1470), None)
    paste_fit(img, shots["espalda"], (900, 80, 1310, 740), "Vista trasera")
    paste_fit(img, shots["lado"], (900, 780, 1310, 1440), "Vista lateral")
    panel(img, (1350, 30, 1800, 1470), "Expresiones")
    n = len(shots["caras"])
    hgt = (1400 - 60) // max(n, 1)
    for i, (e, p) in enumerate(shots["caras"]):
        paste_fit(img, p, (1370, 90 + i * hgt, 1780, 90 + (i + 1) * hgt), FACE_NAMES.get(e, e))
    panel(img, (1820, 30, 2570, 1470), "Accesorios (modelos propios)")
    pcs = shots["piezas"]
    cols = 3
    rows = max(1, (len(pcs) + cols - 1) // cols)
    cw, chh = (2550 - 1840) // cols, min(330, (1300) // rows)
    for i, (lab, p) in enumerate(pcs):
        x0 = 1840 + (i % cols) * cw
        y0 = 90 + (i // cols) * chh
        paste_fit(img, p, (x0, y0, x0 + cw, y0 + chh), lab)
    d.text((1850, 1395), f"{len(entry['Accessories'])} mallas · {entry['Tris']} triángulos (tope {entry['MaxTris']}) · textura {entry['TextureSize']}", font=fonts(19, False), fill=(190, 205, 235))
    d.text((1850, 1422), "Ropa: plantillas Shirt/Pants con textura · cara: Decal (una boca)", font=fonts(19, False), fill=(190, 205, 235))
    tag_preview(img)
    img.save(path, quality=88)
    return path


def comparison(sheet_path, path):
    """La hoja del dueño (referencia) y la nuestra, una encima de la otra."""
    from PIL import Image, ImageDraw

    ref = Image.open(REF).convert("RGB")
    ours = Image.open(sheet_path).convert("RGB")
    W = 2400
    r1 = ref.resize((W, int(ref.height * W / ref.width)), Image.LANCZOS)
    r2 = ours.resize((W, int(ours.height * W / ours.width)), Image.LANCZOS)
    img = Image.new("RGB", (W, r1.height + r2.height + 140), (8, 14, 34))
    d = ImageDraw.Draw(img)
    d.text((24, 14), "REFERENCIA DEL DUEÑO (imagen hecha con IA: estilo e inspiración)", font=fonts(34), fill=(255, 210, 120))
    img.paste(r1, (0, 64))
    d.text((24, r1.height + 76), "NUESTRO COSME (accesorios propios en Blender + ropa con textura + caras dibujadas) — sin babas: arte original", font=fonts(34), fill=(140, 235, 170))
    img.paste(r2, (0, r1.height + 136))
    tag_preview(img)
    img.save(path, quality=86)
    return path


def lineup(entries, shots_by_key, path):
    from PIL import Image, ImageDraw

    before = before_crops()
    n = len(entries)
    cw = 300
    W, H = cw * n + 40, 1520
    img = backdrop(W, H)
    d = ImageDraw.Draw(img)
    d.text((28, 18), "Estilo bloque (piloto) · ANTES: CastLook · DESPUÉS: bloques + accesorios propios + ropa con textura", font=fonts(32), fill=(240, 245, 255))
    d.text((28, 70), "ANTES", font=fonts(30), fill=(255, 200, 120))
    d.text((28, 630), "DESPUÉS", font=fonts(30), fill=(140, 230, 170))
    for i, e in enumerate(entries):
        x0 = 20 + i * cw
        b = before.get(e["Key"])
        if b is not None:
            paste_fit(img, b.convert("RGBA"), (x0, 110, x0 + cw, 610), None, crop=False)
        paste_fit(img, shots_by_key[e["Key"]]["fila"], (x0, 670, x0 + cw, 1460), e["Name"])
    tag_preview(img)
    img.save(path, quality=88)
    return path


def before_crops():
    from PIL import Image

    out = {}
    sheet = os.path.join(ROOT, "docs", "personajes", "reparto-saga1-despues.jpg")
    if os.path.exists(sheet):
        im = Image.open(sheet).convert("RGB")
        k = im.width / 1880.0
        cells = {"Familia_Mama": (0, 0), "Familia_Papa": (1, 0), "Abu_Rosa": (2, 0), "Abu_Tomas": (3, 0), "Lucia": (4, 0), "Pip": (0, 1), "Nico": (1, 1)}
        for key, (cx, cy) in cells.items():
            x0, y0 = int((20 + cx * 230) * k), int((100 + cy * 440) * k)
            out[key] = im.crop((x0, y0, x0 + int(230 * k), y0 + int(370 * k)))
    cos = os.path.join(ROOT, "docs", "personajes", "cosme", "revision", "cosme-frente.jpg")
    if os.path.exists(cos):
        im = Image.open(cos).convert("RGB")
        out["Cosme"] = im.crop((int(im.width * 0.08), int(im.height * 0.08), int(im.width * 0.92), int(im.height * 0.95)))
    return out


# ====================================================================== Luau
def v3(v):
    return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"


def write_luau(manifest):
    L = [
        "-- EstiloBloque: GENERADO por scripts/personajes/bloque_blender.py (no editar a mano).",
        "-- El estilo bloque «premium» del reparto (encargo del dueño, docs/personajes/referencia/): el cuerpo de",
        "-- bloques de Roblox (R15) con ACCESORIOS 3D propios soldados a sus partes (pelo, gafas, batas por piezas,",
        "-- mochilas, botas…), ropa con textura (plantillas Shirt/Pants) y una cara dibujada por expresión (Decal",
        "-- en la cara del accesorio FaceOn: una sola boca). Lo monta World/EstiloBloqueLoader (sin ids o si la",
        "-- moderación retira algo, el personaje sigue con CastLook).",
        "--   Models[key].Accessories   { Name, Part (la parte del R15 a la que va soldado), Offset (del centro",
        "--                             de la parte al del accesorio, en reposo), Size, Tris, Glow (Neon), Lod }",
        "",
        "return {",
        "\tVersion = 1,",
        f"\tPrefix = \"{PREFIX}\",",
        f"\tMaxTris = {MAX_TRIS},",
        "\tModels = {",
    ]
    for e in manifest["Models"]:
        L.append(f"\t\t{e['Key']} = {{")
        L.append(f"\t\t\tName = \"{e['Name']}\", Cast = \"{e['Cast']}\"," + (f" Variant = \"{e['Variant']}\"," if e.get("Variant") else "")
                 + f" Asset = \"{e['Asset']}\", Hero = {str(e['Hero']).lower()}, Kid = {str(e['Kid']).lower()},")
        L.append(f"\t\t\tTris = {e['Tris']}, TextureSize = {e['TextureSize']}, FaceOn = \"{e['FaceOn']}\", Skin = Color3.fromRGB({e['Skin'][0]}, {e['Skin'][1]}, {e['Skin'][2]}),")
        L.append(f"\t\t\tShirt = \"{e['Shirt']}\", Pants = \"{e['Pants']}\",")
        L.append("\t\t\tFaces = { " + ", ".join(f"{k} = \"{v}\"" for k, v in e["Faces"].items()) + " },")
        L.append(f"\t\t\tTextures = {{ Color = \"{e['Textures']['color']}\", Normal = \"{e['Textures']['normal']}\", Roughness = \"{e['Textures']['rugosidad']}\" }},")
        L.append("\t\t\tAccessories = {")
        for a in e["Accessories"]:
            extra = ""
            if a.get("Glow"):
                g = a["Glow"]
                extra += f", Glow = Color3.fromRGB({g[0]}, {g[1]}, {g[2]})"
            if a.get("Lod"):
                extra += f", Lod = \"{a['Lod']}\", LodTris = {a['LodTris']}"
            L.append(f"\t\t\t\t{{ Name = \"{a['Name']}\", Part = \"{a['Part']}\", Offset = {v3(a['Offset'])}, Size = {v3(a['Size'])}, Tris = {a['Tris']}{extra}, Label = \"{a['Label']}\" }},")
        L.append("\t\t\t},")
        L.append("\t\t},")
    L += ["\t},", "}", ""]
    with open(LUAU, "w") as f:
        f.write("\n".join(L))


# ====================================================================== main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solo", default="")
    ap.add_argument("--no-bake", action="store_true")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--samples", type=int, default=24)
    args = ap.parse_args()
    keys = [k.strip() for k in args.solo.split(",") if k.strip()]
    specs = [s for s in REPARTO if not keys or s["Key"] in keys]
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DOCS, exist_ok=True)
    os.makedirs(WORK, exist_ok=True)
    man_path = os.path.join(OUT, "manifest.json")
    manifest = {"Models": []}
    if os.path.exists(man_path):
        with open(man_path) as f:
            manifest = json.load(f)
    shots_path = os.path.join(WORK, "shots.json")
    all_shots = json.load(open(shots_path)) if os.path.exists(shots_path) else {}
    order = [s["Key"] for s in REPARTO]
    for spec in specs:
        t0 = time.time()
        tex = draw_textures(spec)
        K, paths, size, lods = build_accessories(spec, bake=not args.no_bake)
        entry = manifest_entry(spec, K, size)
        if entry["Tris"] > MAX_TRIS:
            raise SystemExit(f"❌ {spec['Key']}: {entry['Tris']} triángulos de accesorios (tope {MAX_TRIS})")
        fbx = export(spec, K, lods)
        manifest["Models"] = [m for m in manifest["Models"] if m["Key"] != spec["Key"]] + [entry]
        manifest["Models"].sort(key=lambda m: order.index(m["Key"]) if m["Key"] in order else 99)
        with open(man_path, "w") as f:
            json.dump(manifest, f, indent=1, ensure_ascii=False)
        write_luau(manifest)
        log(f"{spec['Key']}: {len(K.accs)} accesorios, {entry['Tris']} triángulos -> {os.path.relpath(fbx, ROOT)} ({time.time() - t0:.0f}s)")
        if not args.no_render:
            shots = render_all(spec, K, tex, args.samples)
            sheet = character_sheet(spec, shots, entry, os.path.join(DOCS, f"{lkey(spec)}-bloque.jpg"))
            if spec["Key"] == "Cosme" and os.path.exists(REF):
                comparison(sheet, os.path.join(DOCS, "cosme-comparacion-referencia.jpg"))
            all_shots[spec["Key"]] = {"fila": shots["fila"]}
            with open(shots_path, "w") as f:
                json.dump(all_shots, f)
    if manifest["Models"] and all(m["Key"] in all_shots for m in manifest["Models"]):
        p = lineup(manifest["Models"], all_shots, os.path.join(DOCS, "reparto-bloque-antes-despues.jpg"))
        log(f"hoja: {os.path.relpath(p, ROOT)}")
    log("listo")


if __name__ == "__main__":
    main()
