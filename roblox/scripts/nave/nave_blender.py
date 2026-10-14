#!/usr/bin/env python3
"""La nave realista del jugador («HX-7 Halcón») hecha en Blender con Python: modelado procedural de
superficie dura, texturas PBR horneadas, exportación por piezas (FBX para subir a Roblox + OBJ para las
pruebas), versión lejana (LOD) y las imágenes de vista previa. Documentación: docs/espacio-aaa/nave-realista.md

Necesita Blender como módulo de Python:   pip install bpy==4.2.0   (Python 3.11; todo en CPU)

Uso (desde la carpeta roblox/):
    python3 scripts/nave/nave_blender.py                      todo (mallas, texturas, LOD, imágenes)
    python3 scripts/nave/nave_blender.py --no-render          sin las imágenes de vista previa
    python3 scripts/nave/nave_blender.py --preset ejemplo_alien --out /tmp/alien --no-luau
                                                              (otra nave con el mismo generador)

Salida (--out, por defecto assets/nave):
    <Pieza>.fbx y <Pieza>.obj   Fuselaje, CabinaFrente, Cabina, Alas, Armas, Motores, TrenPata,
                                BrilloAzul, BrilloRojo y NaveLOD (triangulados; ≤ 20.000 triángulos cada una)
    tex/<juego>_<mapa>.png      casco / alas / motores (1024 px): color, normal, rugosidad, metal;
                                lod (512 px): color
    manifest.json               piezas, triángulos, centro y tamaño (studs), material y juego de texturas
y src/shared/AirCombat/NaveMalla.luau (lo mismo para el juego) y docs/espacio-aaa/nave-realista-*.jpg.
"""
import argparse
import json
import math
import os
import sys
import time

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import diseno  # noqa: E402
from geo import to_blender  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

# Piezas: nombre -> (función, juego de texturas, material de Roblox, bisel)
PIECES = [
    ("Fuselaje", lambda P: diseno.build_hull(P), "casco", "Metal", 0.035),
    ("CabinaFrente", lambda P: diseno.build_canopy_frame(P), "casco", "Metal", 0.0),
    ("Alas", lambda P: diseno.build_wings(P), "alas", "Metal", 0.03),
    ("Armas", lambda P: diseno.build_cannons(P), "alas", "Metal", 0.025),
    ("Motores", lambda P: diseno.build_engines(P), "motores", "Metal", 0.03),
    ("TrenPata", lambda P: diseno.build_gear(P), "motores", "Metal", 0.0),
    ("Cabina", lambda P: diseno.build_canopy(P), None, "Glass", 0.0),
    ("BrilloAzul", lambda P: diseno.build_glow(P, "brillo_azul"), None, "Neon", 0.0),
    ("BrilloRojo", lambda P: diseno.build_glow(P, "brillo_rojo"), None, "Neon", 0.0),
    ("NaveLOD", lambda P: diseno.build_lod(P), "lod", "Metal", 0.0),
]
MAX_TRIS = 20000
LOD_TRIS = (3000, 5000)
SETS = {"casco": 1024, "alas": 1024, "motores": 1024, "lod": 512}
MAPS = ["color", "normal", "rugosidad", "metal"]


def log(msg):
    print(f"[nave {time.strftime('%H:%M:%S')}] {msg}", flush=True)


# ====================================================================== calcomanías (PIL)
def make_decals(P, folder):
    from PIL import Image, ImageDraw, ImageFont

    os.makedirs(folder, exist_ok=True)
    out = {}

    def text_img(name, text, size, color, font=FONT_BOLD, pad=10, box=None):
        f = ImageFont.truetype(font, size)
        l, t, r, b = f.getbbox(text)
        img = Image.new("RGBA", (r - l + pad * 2, b - t + pad * 2), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        if box:
            d.rectangle([2, 2, img.width - 3, img.height - 3], outline=box, width=4)
        d.text((pad - l, pad - t), text, font=f, fill=color)
        path = os.path.join(folder, name + ".png")
        img.save(path)
        out[name] = (path, img.width / img.height)

    text_img("designacion", P["Designation"], 160, (40, 44, 52, 235))
    text_img("nombre", P["Subtitle"], 110, (40, 44, 52, 225))
    text_img("aviso", "NO PISAR", 60, (200, 40, 30, 230), box=(200, 40, 30, 230), pad=16)
    text_img("escape", "PELIGRO · ESCAPE", 60, (30, 30, 34, 230), box=(30, 30, 34, 230), pad=16)
    # Franjas rojas y naranjas en diagonal
    img = Image.new("RGBA", (512, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k in range(-2, 9):
        x = k * 64
        d.polygon([(x, 160), (x + 32, 160), (x + 92, 0), (x + 60, 0)], fill=(190, 25, 18, 245) if k % 2 == 0 else (230, 110, 20, 245))
    path = os.path.join(folder, "franjas.png")
    img.save(path)
    out["franjas"] = (path, 512 / 160)
    return out


def decal_list(P, decals):
    """(imagen, centro, eje u (derecha del texto), eje v (arriba), ancho en studs, normal que debe mirar)"""
    L = []
    def add(name, c, u, v, width, n):
        path, aspect = decals[name]
        L.append((path, c, u, v, width, width / aspect, n))
    # El nombre en las alas (se lee desde arriba con el morro hacia arriba) y en los costados del morro
    add("designacion", (-7.3, -0.3, 4.6), (1, 0, 0), (0, 0, -1), 3.4, (0, 1, 0))
    add("nombre", (7.3, -0.3, 4.6), (1, 0, 0), (0, 0, -1), 3.0, (0, 1, 0))
    add("designacion", (-1.6, 0.25, -9.0), (0, 0, 1), (0, 1, 0), 2.2, (-1, 0, 0))
    add("designacion", (1.6, 0.25, -9.0), (0, 0, -1), (0, 1, 0), 2.2, (1, 0, 0))
    for s in (-1, 1):
        add("franjas", (s * 11.0, -0.4, 7.9), (1, 0, 0), (0, 0, -1), 2.2, (0, 1, 0))
        add("aviso", (s * 3.6, -0.2, 2.6), (1, 0, 0), (0, 0, -1), 1.0, (0, 1, 0))
        add("escape", (s * 2.45, 1.38, 5.6), (1, 0, 0), (0, 0, -1), 1.2, (0, 1, 0))
        add("franjas", (s * 2.45, 1.38, 2.6), (1, 0, 0), (0, 0, -1), 1.4, (0, 1, 0))
    return L


# ====================================================================== materiales procedurales
class NodeKit:
    def __init__(self, nt):
        self.nt = nt
        self.y = 0

    def new(self, kind, **props):
        n = self.nt.nodes.new(kind)
        for k, v in props.items():
            setattr(n, k, v)
        n.location = (0, self.y)
        self.y -= 40
        return n

    def link(self, a, b):
        self.nt.links.new(a, b)

    def set_in(self, node, idx, val):
        if hasattr(val, "is_output") or hasattr(val, "links"):
            self.link(val, node.inputs[idx])
        else:
            node.inputs[idx].default_value = val

    def math(self, op, a, b=0.0, clamp=False):
        n = self.new("ShaderNodeMath", operation=op, use_clamp=clamp)
        self.set_in(n, 0, a)
        self.set_in(n, 1, b)
        return n.outputs[0]

    def vmath(self, op, a, b=None, scale=None):
        n = self.new("ShaderNodeVectorMath", operation=op)
        self.set_in(n, 0, a)
        if b is not None:
            self.set_in(n, 1, b)
        if scale is not None:
            n.inputs["Scale"].default_value = scale
        return n.outputs["Value"] if op in ("DOT_PRODUCT", "LENGTH", "DISTANCE") else n.outputs["Vector"]

    def combine(self, x, y, z=0.0):
        n = self.new("ShaderNodeCombineXYZ")
        self.set_in(n, 0, x)
        self.set_in(n, 1, y)
        self.set_in(n, 2, z)
        return n.outputs[0]

    def mix(self, fac, a, b):
        n = self.new("ShaderNodeMix", data_type="RGBA", blend_type="MIX")
        self.set_in(n, "Factor", fac)
        self.link_or_set(n.inputs[6], a)
        self.link_or_set(n.inputs[7], b)
        return n.outputs[2]

    def link_or_set(self, sock, val):
        if hasattr(val, "is_output"):
            self.link(val, sock)
        else:
            sock.default_value = val


def proc_material(name, color, metal, rough, decals=(), panel=True, emission=None, scale=0.3):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    K = NodeKit(nt)
    out = K.new("ShaderNodeOutputMaterial")
    bsdf = K.new("ShaderNodeBsdfPrincipled")
    bsdf.name = "BSDF"
    K.link(bsdf.outputs[0], out.inputs["Surface"])
    metal_node = K.new("ShaderNodeValue")
    metal_node.name = "MetalVal"
    metal_node.outputs[0].default_value = metal
    K.link(metal_node.outputs[0], bsdf.inputs["Metallic"])
    bake = K.new("ShaderNodeTexImage")
    bake.name = "BakeTarget"
    base = (*color, 1.0)
    if emission:
        bsdf.inputs["Base Color"].default_value = base
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 0.0
        bsdf.inputs["Roughness"].default_value = rough
        nt.nodes.active = bake
        return mat
    tc = K.new("ShaderNodeTexCoord")
    P = tc.outputs["Object"]
    geo = K.new("ShaderNodeNewGeometry")
    N = geo.outputs["Normal"]
    sepP = K.new("ShaderNodeSeparateXYZ")
    K.link(P, sepP.inputs[0])
    sepN = K.new("ShaderNodeSeparateXYZ")
    K.link(N, sepN.inputs[0])
    ws = [K.math("POWER", K.math("ABSOLUTE", sepN.outputs[i]), 4.0) for i in range(3)]
    total = K.math("ADD", K.math("ADD", ws[0], ws[1]), ws[2])
    ws = [K.math("DIVIDE", w, total) for w in ws]
    projs = [K.combine(sepP.outputs[1], sepP.outputs[2]), K.combine(sepP.outputs[0], sepP.outputs[2]), K.combine(sepP.outputs[0], sepP.outputs[1])]

    def bricks(sc, mortar, width, height, tint):
        lines, tone = None, None
        for i in range(3):
            b = K.new("ShaderNodeTexBrick")
            K.link(projs[i], b.inputs["Vector"])
            b.inputs["Scale"].default_value = sc
            b.inputs["Mortar Size"].default_value = mortar
            b.inputs["Mortar Smooth"].default_value = 0.15
            b.inputs["Brick Width"].default_value = width
            b.inputs["Row Height"].default_value = height
            b.inputs["Color1"].default_value = (1, 1, 1, 1)
            b.inputs["Color2"].default_value = (tint, tint, tint, 1)
            b.inputs["Mortar"].default_value = (1, 1, 1, 1)
            b.inputs["Bias"].default_value = 0.0
            b.offset = 0.37
            l = K.math("MULTIPLY", b.outputs["Fac"], ws[i])
            t = K.math("MULTIPLY", b.outputs["Color"], ws[i])
            lines = l if lines is None else K.math("ADD", lines, l)
            tone = t if tone is None else K.math("ADD", tone, t)
        return lines, tone

    if panel:
        l1, t1 = bricks(scale, 0.012, 1.3, 0.72, 0.88)
        l2, t2 = bricks(scale * 2.6, 0.016, 1.05, 0.6, 0.95)
        lines = K.math("MAXIMUM", l1, K.math("MULTIPLY", l2, 0.32))
        tone = K.math("MULTIPLY", t1, K.math("ADD", K.math("MULTIPLY", t2, 0.3), 0.7))
    else:
        lines, tone = 0.0, 1.0
    noise = K.new("ShaderNodeTexNoise")
    K.link(P, noise.inputs["Vector"])
    noise.inputs["Scale"].default_value = 1.6
    noise.inputs["Detail"].default_value = 8.0
    noise.inputs["Roughness"].default_value = 0.62
    grime = K.new("ShaderNodeMapRange")
    K.link(noise.outputs["Fac"], grime.inputs["Value"])
    grime.inputs["From Min"].default_value = 0.42
    grime.inputs["From Max"].default_value = 0.78
    grime = grime.outputs["Result"]
    fine = K.new("ShaderNodeTexNoise")
    K.link(P, fine.inputs["Vector"])
    fine.inputs["Scale"].default_value = 28.0
    fine.inputs["Detail"].default_value = 4.0
    # factor de color: tono de cada placa, líneas de panel más oscuras, suciedad
    f = K.math("ADD", K.math("MULTIPLY", tone, 0.16), 0.84)
    f = K.math("MULTIPLY", f, K.math("SUBTRACT", 1.0, K.math("MULTIPLY", lines, 0.62)))
    f = K.math("MULTIPLY", f, K.math("SUBTRACT", 1.0, K.math("MULTIPLY", grime, 0.2)))
    f = K.math("MULTIPLY", f, K.math("ADD", K.math("MULTIPLY", fine.outputs["Fac"], 0.12), 0.94))
    scaled = K.new("ShaderNodeVectorMath", operation="SCALE")
    scaled.inputs[0].default_value = color
    K.link(f, scaled.inputs["Scale"])
    color_out = scaled.outputs["Vector"]
    # Calcomanías (proyección plana en coordenadas del objeto = del mundo)
    for path, c, u, v, sw, sh, nrm in decals:
        img = bpy.data.images.load(path, check_existing=True)
        cB, uB, vB, nB = to_blender(c), to_blender(u), to_blender(v), to_blender(nrm)
        d = K.vmath("SUBTRACT", P, tuple(cB))
        du = K.math("ADD", K.math("DIVIDE", K.vmath("DOT_PRODUCT", d, tuple(uB)), sw), 0.5)
        dv = K.math("ADD", K.math("DIVIDE", K.vmath("DOT_PRODUCT", d, tuple(vB)), sh), 0.5)
        tex = K.new("ShaderNodeTexImage", extension="CLIP", interpolation="Cubic")
        tex.image = img
        K.link(K.combine(du, dv), tex.inputs["Vector"])
        facing = K.math("GREATER_THAN", K.vmath("DOT_PRODUCT", N, tuple(nB)), 0.55)
        depth = K.math("LESS_THAN", K.math("ABSOLUTE", K.vmath("DOT_PRODUCT", d, tuple(nB))), 1.2)
        mask = K.math("MULTIPLY", K.math("MULTIPLY", tex.outputs["Alpha"], facing), depth)
        color_out = K.mix(mask, color_out, tex.outputs["Color"])
    K.link(color_out, bsdf.inputs["Base Color"])
    r = K.math("ADD", rough, K.math("ADD", K.math("MULTIPLY", lines, 0.18), K.math("MULTIPLY", grime, 0.14)))
    K.link(r, bsdf.inputs["Roughness"])
    bump = K.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.75
    bump.inputs["Distance"].default_value = 0.03
    K.link(K.math("SUBTRACT", 1.0, lines) if panel else fine.outputs["Fac"], bump.inputs["Height"])
    bump2 = K.new("ShaderNodeBump")
    bump2.inputs["Strength"].default_value = 0.08
    bump2.inputs["Distance"].default_value = 0.01
    K.link(fine.outputs["Fac"], bump2.inputs["Height"])
    K.link(bump2.outputs["Normal"], bump.inputs["Normal"])
    K.link(bump.outputs["Normal"], bsdf.inputs["Normal"])
    nt.nodes.active = bake
    return mat


def make_materials(P, decals):
    pal = P["Palette"]
    dl = decal_list(P, decals)
    proc_material("blanco", pal["blanco"], 0.25, 0.4, decals=dl)
    proc_material("grafito", pal["grafito"], 0.82, 0.36, scale=0.4)
    proc_material("oscuro", pal["oscuro"], 0.6, 0.55, scale=0.6)
    proc_material("acero", pal["acero"], 0.95, 0.28, panel=False)
    proc_material("rojo", pal["rojo"], 0.2, 0.4, scale=0.5)
    proc_material("naranja", pal["naranja"], 0.2, 0.4)
    proc_material("pantalla", pal["pantalla"], 0.0, 0.2, emission=pal["pantalla"])
    proc_material("brillo_azul", pal["brillo_azul"], 0.0, 0.3, emission=pal["brillo_azul"])
    proc_material("brillo_rojo", pal["brillo_rojo"], 0.0, 0.3, emission=pal["brillo_rojo"])
    glass = bpy.data.materials.get("cristal") or bpy.data.materials.new("cristal")
    glass.use_nodes = True
    b = glass.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (0.06, 0.09, 0.13, 1)
    b.inputs["Transmission Weight"].default_value = 0.55
    b.inputs["Roughness"].default_value = 0.04
    b.inputs["Metallic"].default_value = 0.0
    b.inputs["Coat Weight"].default_value = 1.0
    b.inputs["Specular IOR Level"].default_value = 0.9
    bake = glass.node_tree.nodes.new("ShaderNodeTexImage")
    bake.name = "BakeTarget"
    glass.node_tree.nodes.active = bake


# ====================================================================== mallas
def finish_object(obj, bevel):
    """Bisel (superficie dura), sombreado suave por ángulo y triangulado: se aplica todo."""
    me = obj.data
    me.shade_smooth()
    if bevel > 0:
        m = obj.modifiers.new("Bisel", "BEVEL")
        m.width = bevel
        m.segments = 2
        m.limit_method = "ANGLE"
        m.angle_limit = math.radians(32)
        m.miter_outer = "MITER_ARC"
    t = obj.modifiers.new("Triangular", "TRIANGULATE")
    t.quad_method = "BEAUTY"
    dg = bpy.context.evaluated_depsgraph_get()
    new = bpy.data.meshes.new_from_object(obj.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
    obj.modifiers.clear()
    old = obj.data
    obj.data = new
    bpy.data.meshes.remove(old)
    new.set_sharp_from_angle(angle=math.radians(34))
    return len(new.polygons)


def select_only(objs, active=None):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or objs[0]


def unwrap(objs):
    select_only(objs)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.006, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.object.mode_set(mode="OBJECT")


def bbox_roblox(obj):
    pts = [Vector((v.co.x, v.co.z, -v.co.y)) for v in obj.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return (lo + hi) / 2, hi - lo


# ====================================================================== horneado
def bake_set(name, objs, size, out_dir, maps):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 4
    scene.render.bake.margin = 6
    mats = {m for o in objs for m in o.data.materials if m}
    paths = {}
    for kind in maps:
        img = bpy.data.images.new(f"{name}_{kind}", size, size, alpha=False, float_buffer=False)
        img.colorspace_settings.name = "sRGB" if kind == "color" else "Non-Color"
        for m in mats:
            node = m.node_tree.nodes.get("BakeTarget")
            node.image = img
            m.node_tree.nodes.active = node
        select_only(objs)
        t0 = time.time()
        if kind == "color":
            bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_clear=True, margin=6)
        elif kind == "normal":
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT", use_clear=True, margin=6)
        elif kind == "rugosidad":
            bpy.ops.object.bake(type="ROUGHNESS", use_clear=True, margin=6)
        else:
            saved = []
            for m in mats:
                b = m.node_tree.nodes.get("BSDF") or m.node_tree.nodes.get("Principled BSDF")
                mv = m.node_tree.nodes.get("MetalVal")
                val = mv.outputs[0].default_value if mv else b.inputs["Metallic"].default_value
                links = [l for l in m.node_tree.links if l.to_socket == b.inputs["Emission Color"]]
                saved.append((m, b, tuple(b.inputs["Emission Color"].default_value), b.inputs["Emission Strength"].default_value, [(l.from_socket) for l in links]))
                for l in links:
                    m.node_tree.links.remove(l)
                b.inputs["Emission Color"].default_value = (val, val, val, 1)
                b.inputs["Emission Strength"].default_value = 1.0
            bpy.ops.object.bake(type="EMIT", use_clear=True, margin=6)
            for m, b, col, strength, froms in saved:
                b.inputs["Emission Color"].default_value = col
                b.inputs["Emission Strength"].default_value = strength
                for fs in froms:
                    m.node_tree.links.new(fs, b.inputs["Emission Color"])
        path = os.path.join(out_dir, f"{name}_{kind}.png")
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
        paths[kind] = path
        log(f"  horneado {name}_{kind} ({size}px) en {time.time() - t0:.1f}s")
    return paths


def pbr_material(name, paths):
    mat = bpy.data.materials.new("PBR_" + name)
    mat.use_nodes = True
    nt = mat.node_tree
    b = nt.nodes.get("Principled BSDF")

    def tex(kind, color=False):
        n = nt.nodes.new("ShaderNodeTexImage")
        n.image = bpy.data.images.load(paths[kind], check_existing=False)
        n.image.colorspace_settings.name = "sRGB" if color else "Non-Color"
        return n

    nt.links.new(tex("color", True).outputs["Color"], b.inputs["Base Color"])
    if "rugosidad" in paths:
        nt.links.new(tex("rugosidad").outputs["Color"], b.inputs["Roughness"])
    if "metal" in paths:
        nt.links.new(tex("metal").outputs["Color"], b.inputs["Metallic"])
    else:
        b.inputs["Metallic"].default_value = 0.5
        b.inputs["Roughness"].default_value = 0.45
    if "normal" in paths:
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(tex("normal").outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return mat


def single_material(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for p in obj.data.polygons:
        p.material_index = 0


# ====================================================================== exportar
def export(obj, out_dir):
    select_only([obj])
    fbx = os.path.join(out_dir, obj.name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=True, add_leaf_bones=False, path_mode="STRIP", embed_textures=False, use_custom_props=False)
    obj_path = os.path.join(out_dir, obj.name + ".obj")
    bpy.ops.wm.obj_export(filepath=obj_path, export_selected_objects=True, forward_axis="NEGATIVE_Z", up_axis="Y", export_normals=False, export_uv=True, export_materials=False, export_triangulated_mesh=True, apply_modifiers=True)
    return os.path.basename(fbx), os.path.basename(obj_path)


def write_luau(path, manifest, P):
    lines = [
        "-- NaveMalla: GENERADO por scripts/nave/nave_blender.py (no editar a mano).",
        f"-- La nave realista «{P['Name']}» hecha en Blender: sus piezas (MeshPart al subirlas con",
        "-- scripts/upload-nave.sh), con el centro y el tamaño en studs respecto al Root de la nave (ejes de",
        "-- shared/AirCombat/ShipModel: el morro a -Z), los triángulos, el material de Roblox y el juego de",
        "-- texturas (assets/nave/tex/<juego>_<mapa>.png). Lo usa shared/AirCombat/ShipModel (modo malla).",
        "",
        "return {",
        f"\tName = \"{P['Name']}\",",
        f"\tDesignation = \"{P['Designation']}\",",
        f"\tNozzleZ = {P['NozzleZ']},",
        f"\tMuzzleZ = {P['MuzzleZ']},",
    ]
    engines = []
    for ex, ey in P["Engines"]:
        for sx in (-1, 1):
            engines.append(f"Vector3.new({sx * ex:.3f}, {ey:.3f}, {P['NozzleZ']:.3f})")
    tip = P["Wing"][-1]
    spine = P["Spine"][-1]
    lines += [
        f"\tEngines = {{ {', '.join(engines)} }}, -- centro del brillo de cada tobera",
        f"\tEngineRadius = {P['EngineRadius']},",
        f"\tWingTip = Vector3.new({tip[0] - 0.1:.3f}, {tip[4]:.3f}, {tip[2] - 0.35:.3f}), -- punta del ala derecha (la izquierda: X negativa)",
        f"\tTailLight = Vector3.new(0, {spine[2] + 0.15:.3f}, {spine[0] - 0.4:.3f}),",
        f"\tSeat = Vector3.new({P['Seat'][0]}, {P['Seat'][1]}, {P['Seat'][2]}),",
        f"\tTotalTris = {manifest['TotalTris']},",
        "\tPieces = {",
    ]
    for p in manifest["Pieces"]:
        c, s = p["Center"], p["Size"]
        ts = f"\"{p['Set']}\"" if p["Set"] else "nil"
        color = p.get("Color")
        cs = f"Color3.fromRGB({color[0]}, {color[1]}, {color[2]})" if color else "nil"
        lines.append(f"\t\t{{ Name = \"{p['Name']}\", Center = Vector3.new({c[0]:.3f}, {c[1]:.3f}, {c[2]:.3f}), Size = Vector3.new({s[0]:.3f}, {s[1]:.3f}, {s[2]:.3f}), Tris = {p['Tris']}, Material = \"{p['Material']}\", Set = {ts}, Color = {cs}, Lod = {str(p['Lod']).lower()} }},")
    lines += ["\t},", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))


# ====================================================================== render
def look_at(cam, eye_rb, target_rb, up_rb=(0, 1, 0)):
    eye, tgt, up = to_blender(eye_rb), to_blender(target_rb), to_blender(up_rb)
    f = (tgt - eye).normalized()
    r = f.cross(up).normalized()
    u = r.cross(f).normalized()
    m = Matrix(((r.x, u.x, -f.x), (r.y, u.y, -f.y), (r.z, u.z, -f.z)))
    cam.matrix_world = Matrix.Translation(eye) @ m.to_4x4()


def setup_world(scene):
    world = bpy.data.worlds.new("Espacio")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 260
    nt.links.new(tc.outputs["Generated"], vor.inputs["Vector"])
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value = 0.0
    mr.inputs["From Max"].default_value = 0.07
    mr.inputs["To Min"].default_value = 1.0
    mr.inputs["To Max"].default_value = 0.0
    nt.links.new(vor.outputs["Distance"], mr.inputs["Value"])
    pw = nt.nodes.new("ShaderNodeMath")
    pw.operation = "POWER"
    pw.inputs[1].default_value = 14
    nt.links.new(mr.outputs["Result"], pw.inputs[0])
    neb = nt.nodes.new("ShaderNodeTexNoise")
    neb.inputs["Scale"].default_value = 1.6
    neb.inputs["Detail"].default_value = 6
    nt.links.new(tc.outputs["Generated"], neb.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.45
    ramp.color_ramp.elements[0].color = (0.002, 0.004, 0.012, 1)
    ramp.color_ramp.elements[1].position = 0.8
    ramp.color_ramp.elements[1].color = (0.02, 0.05, 0.14, 1)
    nt.links.new(neb.outputs["Fac"], ramp.inputs["Fac"])
    add = nt.nodes.new("ShaderNodeMix")
    add.data_type = "RGBA"
    add.blend_type = "ADD"
    add.inputs["Factor"].default_value = 1.0
    nt.links.new(ramp.outputs["Color"], add.inputs[6])
    nt.links.new(pw.outputs[0], add.inputs[7])
    nt.links.new(add.outputs[2], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 1.0
    nt.links.new(bg.outputs[0], out.inputs["Surface"])


def emission_mat(name, color, strength, soft=False):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*color, 1)
    em.inputs["Strength"].default_value = strength
    if soft:
        lw = nt.nodes.new("ShaderNodeLayerWeight")
        lw.inputs["Blend"].default_value = 0.35
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        mix = nt.nodes.new("ShaderNodeMixShader")
        fac = nt.nodes.new("ShaderNodeMath")
        fac.operation = "MULTIPLY_ADD"
        fac.inputs[1].default_value = 0.6
        fac.inputs[2].default_value = 0.4
        nt.links.new(lw.outputs["Facing"], fac.inputs[0])
        nt.links.new(fac.outputs[0], mix.inputs["Fac"])
        nt.links.new(em.outputs[0], mix.inputs[1])
        nt.links.new(tr.outputs[0], mix.inputs[2])
        nt.links.new(mix.outputs[0], out.inputs["Surface"])
        m.blend_method = "BLEND"
    else:
        nt.links.new(em.outputs[0], out.inputs["Surface"])
    return m


def render_extras(P, coll):
    """Brillo de las toberas y la llama del escape (solo en las imágenes: en Roblox son Neon y Trail)."""
    from geo import MeshBuilder

    objs = []
    for idx, (name, color, strength, soft, prof) in enumerate((
        ("ToberaBrillo", (0.75, 0.9, 1.0), 30.0, False, [(1.3, 0.0), (1.3, 0.05)]),
        ("Llama", (0.05, 0.3, 1.0), 2.6, True, [(1.25, 0.1), (1.0, 2.0), (0.6, 5.0), (0.1, 8.5)]),
        ("LlamaNucleo", (0.3, 0.6, 1.0), 5.0, True, [(0.9, 0.1), (0.5, 1.5), (0.1, 3.2)]),
    )):
        mb = MeshBuilder(["x"])
        for ex, ey in P["Engines"]:
            for sx in (1, -1):
                mb.lathe(prof, (sx * ex, ey, P["NozzleZ"]), 32, 0)
        o = mb.build(name, coll)
        for p in o.data.polygons:
            p.use_smooth = True
        single_material(o, emission_mat("M" + name, color, strength, soft))
        objs.append(o)
    return objs


def render_views(P, out_docs, samples, hi_objs, tag="nave-realista", only=None, percent=100):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    try:
        scene.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Punchy"
    scene.render.film_transparent = False
    setup_world(scene)
    # Luces: sol frío de frente-arriba, contraluz azul y relleno cálido
    sun = bpy.data.lights.new("Sol", "SUN")
    sun.energy = 4.0
    sun.angle = math.radians(2)
    so = bpy.data.objects.new("Sol", sun)
    scene.collection.objects.link(so)
    look_at(so, (-30, 40, -20), (0, 0, 0))
    rim = bpy.data.lights.new("Contraluz", "AREA")
    rim.energy = 9000
    rim.size = 12
    rim.color = (0.45, 0.65, 1.0)
    ro = bpy.data.objects.new("Contraluz", rim)
    scene.collection.objects.link(ro)
    look_at(ro, (35, 20, 30), (0, 0, 0))
    fill = bpy.data.lights.new("Relleno", "AREA")
    fill.energy = 2500
    fill.size = 20
    fill.color = (1.0, 0.85, 0.75)
    fo = bpy.data.objects.new("Relleno", fill)
    scene.collection.objects.link(fo)
    look_at(fo, (25, -15, -30), (0, 0, 0))
    low = bpy.data.lights.new("Rebote", "AREA")
    low.energy = 1800
    low.size = 25
    low.color = (0.35, 0.55, 1.0)
    lo = bpy.data.objects.new("Rebote", low)
    scene.collection.objects.link(lo)
    look_at(lo, (-10, -30, -25), (0, 0, 0))
    # Planeta para la vista de héroe
    bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=48, radius=1500, location=to_blender((900, -2300, -2600)))
    planet = bpy.context.active_object
    planet.name = "Planeta"
    pm = bpy.data.materials.new("Planeta")
    pm.use_nodes = True
    pb = pm.node_tree.nodes.get("Principled BSDF")
    nz = pm.node_tree.nodes.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 3.0
    nz.inputs["Detail"].default_value = 12
    rp = pm.node_tree.nodes.new("ShaderNodeValToRGB")
    rp.color_ramp.elements[0].color = (0.004, 0.02, 0.09, 1)
    rp.color_ramp.elements[1].position = 0.75
    rp.color_ramp.elements[1].color = (0.3, 0.4, 0.55, 1)
    pm.node_tree.links.new(nz.outputs["Fac"], rp.inputs["Fac"])
    pm.node_tree.links.new(rp.outputs["Color"], pb.inputs["Base Color"])
    pb.inputs["Roughness"].default_value = 0.8
    planet.data.materials.append(pm)
    for p in planet.data.polygons:
        p.use_smooth = True
    # Compositor: resplandor de las luces
    scene.use_nodes = True
    ct = scene.node_tree
    ct.nodes.clear()
    rl = ct.nodes.new("CompositorNodeRLayers")
    gl = ct.nodes.new("CompositorNodeGlare")
    gl.glare_type = "FOG_GLOW"
    gl.quality = "HIGH"
    gl.threshold = 0.9
    gl.size = 8
    comp = ct.nodes.new("CompositorNodeComposite")
    ct.links.new(rl.outputs["Image"], gl.inputs["Image"])
    ct.links.new(gl.outputs["Image"], comp.inputs["Image"])

    cam_data = bpy.data.cameras.new("Camara")
    cam = bpy.data.objects.new("Camara", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    views = [
        ("heroe", (-24, 15, 34), (0.5, -0.6, 0), 42, (1920, 1080), True),
        ("tresquartos", (-30, 17, -30), (0, 0, -1.5), 50, (1280, 720), False),
        ("frontal", (0, 5, -60), (0, 0, 0), 60, (1280, 720), False),
        ("trasera", (0, 7, 60), (0, 0, 0), 60, (1280, 720), False),
        ("lateral", (60, 3, -1.5), (0, 0, -1.5), 60, (1280, 720), False),
        ("superior", (0, 70, -1.5), (0, 0, -1.5), 60, (1280, 720), False),
        ("motores", (5, 3.5, 22), (0, -0.25, 10.0), 50, (1280, 720), False),
        ("cabina", (-7.5, 6.5, -9.5), (0, 1.8, -1.8), 50, (1280, 720), False),
        ("armas", (-8.0, -1.2, -17.0), (-2.6, -1.8, -8.0), 45, (1280, 720), False),
    ]
    paths = {}
    scene.render.resolution_percentage = percent
    for name, eye, tgt, lens, res, planet_on in views:
        if only and name not in only:
            continue
        planet.hide_render = not planet_on
        cam_data.lens = lens
        up = (0, 0, -1) if name == "superior" else (0, 1, 0)
        look_at(cam, eye, tgt, up)
        scene.render.resolution_x, scene.render.resolution_y = res
        scene.render.image_settings.file_format = "JPEG"
        scene.render.image_settings.quality = 90
        path = os.path.join(out_docs, f"{tag}-{name}.jpg")
        scene.render.filepath = path
        spot = None
        if name == "armas":  # (los cañones van a la sombra de las alas: una luz de estudio para el detalle)
            ld = bpy.data.lights.new("LuzArmas", "AREA")
            ld.energy = 4000
            ld.size = 10
            ld.color = (0.8, 0.88, 1.0)
            spot = bpy.data.objects.new("LuzArmas", ld)
            scene.collection.objects.link(spot)
            look_at(spot, (-9.0, -6.0, -11.0), (-2.6, -1.8, -6.0))
        t0 = time.time()
        bpy.ops.render.render(write_still=True)
        if spot:
            bpy.data.objects.remove(spot)
        paths[name] = path
        log(f"  vista {name} en {time.time() - t0:.0f}s")
    return paths


def compose_sheet(P, paths, ref, out_sheet, out_cmp, stats):
    from PIL import Image, ImageDraw, ImageFont

    W, H = 1920, 1080
    sheet = Image.new("RGB", (W, H), (6, 10, 22))
    d = ImageDraw.Draw(sheet)
    fb = lambda s: ImageFont.truetype(FONT_BOLD, s)
    fr = lambda s: ImageFont.truetype(FONT, s)
    hero = Image.open(paths["heroe"]).resize((1440, 810))
    sheet.paste(hero.crop((0, 120, 1440, 690)), (0, 0))
    d.text((40, 34), "HEROES OF HISTORY", font=fb(30), fill=(235, 245, 255))
    d.text((42, 74), "EXPLORA · LUCHA · CONSTRUYE · VIVE", font=fr(16), fill=(140, 190, 230))
    px = 1460
    d.text((px, 60), P["Designation"], font=fb(64), fill=(240, 248, 255))
    d.text((px, 138), P["Subtitle"] + " · NAVE ESPACIAL", font=fb(20), fill=(90, 190, 255))
    d.line((px, 172, W - 40, 172), fill=(60, 120, 180), width=2)
    y = 200
    for label, value in stats:
        d.text((px, y), label, font=fr(17), fill=(150, 180, 210))
        d.text((px, y + 24), value, font=fb(26), fill=(240, 248, 255))
        y += 78
    d.text((px, y + 10), "Diseño propio · malla y texturas", font=fr(15), fill=(120, 150, 180))
    d.text((px, y + 32), "PBR hechas con Blender", font=fr(15), fill=(120, 150, 180))
    tiles = [("VISTA FRONTAL", "frontal"), ("VISTA TRASERA", "trasera"), ("VISTA LATERAL", "lateral"), ("VISTA SUPERIOR", "superior")]
    tw, th = 400, 225
    for i, (label, key) in enumerate(tiles):
        x0 = 20 + (i % 2) * (tw + 12)
        y0 = 590 + (i // 2) * (th + 14)
        im = Image.open(paths[key]).resize((tw, th))
        sheet.paste(im, (x0, y0))
        d.rectangle((x0, y0, x0 + tw, y0 + th), outline=(40, 90, 140), width=2)
        d.text((x0 + 12, y0 + 10), label, font=fb(15), fill=(220, 235, 255))
    d.text((850, 590), "| DETALLES", font=fb(17), fill=(90, 190, 255))
    for i, (label, key) in enumerate((("CABINA", "cabina"), ("MOTORES", "motores"), ("ARMAS", "armas"))):
        x0, y0 = 850, 620 + i * 150
        im = Image.open(paths[key]).resize((250, 141))
        sheet.paste(im, (x0, y0))
        d.rectangle((x0, y0, x0 + 250, y0 + 141), outline=(40, 90, 140), width=2)
        d.text((x0 + 10, y0 + 115), label, font=fb(14), fill=(220, 235, 255))
    im = Image.open(paths["tresquartos"]).resize((780, 439))
    sheet.paste(im, (1120, 600))
    d.rectangle((1120, 600, 1900, 1039), outline=(40, 90, 140), width=2)
    d.text((1134, 610), "TRES CUARTOS", font=fb(15), fill=(220, 235, 255))
    d.text((40, H - 34), f"{P['Designation']}  ·  EXPLORACIÓN  ·  COMBATE  ·  LIBERTAD", font=fr(15), fill=(120, 150, 180))
    sheet.save(out_sheet, quality=90)
    # Comparación con la referencia del dueño
    if ref and os.path.exists(ref):
        r = Image.open(ref).convert("RGB")
        r = r.resize((960, int(960 * r.height / r.width)))
        s = Image.open(out_sheet).resize((960, 540))
        hgt = max(r.height, 540) + 60
        cmp_img = Image.new("RGB", (1920, hgt), (6, 10, 22))
        cmp_img.paste(r, (0, 60))
        cmp_img.paste(s, (960, 60))
        dc = ImageDraw.Draw(cmp_img)
        dc.text((20, 16), "REFERENCIA DEL DUEÑO", font=fb(24), fill=(255, 210, 120))
        dc.text((980, 16), f"{P['Name'].upper()} (Blender, malla y texturas PBR)", font=fb(24), fill=(140, 220, 255))
        cmp_img.save(out_cmp, quality=88)


# ====================================================================== main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preset", default="hx7")
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "nave"))
    ap.add_argument("--docs", default=os.path.join(ROOT, "docs", "espacio-aaa"))
    ap.add_argument("--luau", default=os.path.join(ROOT, "src", "shared", "AirCombat", "NaveMalla.luau"))
    ap.add_argument("--no-luau", action="store_true")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--tex", type=int, default=1024)
    ap.add_argument("--views", default="", help="solo estas vistas (separadas por comas), sin la hoja")
    ap.add_argument("--percent", type=int, default=100)
    args = ap.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else None)
    P = diseno.PRESETS[args.preset]
    out_dir = os.path.abspath(args.out)
    tex_dir = os.path.join(out_dir, "tex")
    os.makedirs(tex_dir, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    t_start = time.time()
    decals = make_decals(P, os.path.join(out_dir, "calcos"))
    make_materials(P, decals)
    coll = bpy.data.collections.new("Nave")
    bpy.context.scene.collection.children.link(coll)
    objs, info = {}, {}
    for name, fn, tset, rmat, bevel in PIECES:
        mb = fn(P)
        o = mb.build(name, coll)
        tris = finish_object(o, bevel)
        objs[name] = o
        info[name] = {"Set": tset, "Material": rmat, "Tris": tris}
        log(f"{name}: {tris} triángulos")
    # UV por juegos de texturas (las piezas de un juego comparten la misma imagen)
    sets = {}
    for name, (_, _, tset, _, _) in zip(objs, PIECES):
        if tset:
            sets.setdefault(tset, []).append(objs[name])
    for tset, members in sets.items():
        unwrap(members)
    baked = {}
    for tset, members in sets.items():
        size = SETS[tset] if tset != "lod" else max(256, args.tex // 2)
        if tset != "lod":
            size = args.tex
        maps = MAPS if tset != "lod" else ["color"]
        baked[tset] = bake_set(tset, members, size, tex_dir, maps)
    # Materiales finales (texturas horneadas) y exportación
    pal = P["Palette"]
    manifest = {"Name": P["Name"], "Designation": P["Designation"], "Pieces": [], "Textures": {}}
    for tset, paths in baked.items():
        mat = pbr_material(tset, paths)
        for o in sets[tset]:
            single_material(o, mat)
        manifest["Textures"][tset] = {k: os.path.relpath(v, out_dir) for k, v in paths.items()}
    for name, o in objs.items():
        if not info[name]["Set"]:
            m = bpy.data.materials.get({"Cabina": "cristal", "BrilloAzul": "brillo_azul", "BrilloRojo": "brillo_rojo"}[name])
            single_material(o, m)
        fbx, objf = export(o, out_dir)
        center, size = bbox_roblox(o)
        color = None
        if name == "BrilloAzul":
            color = [int(c * 255) for c in pal["brillo_azul"]]
        elif name == "BrilloRojo":
            color = [int(c * 255) for c in pal["brillo_rojo"]]
        elif name == "Cabina":
            color = [24, 32, 44]
        manifest["Pieces"].append({"Name": name, "Fbx": fbx, "Obj": objf, "Tris": info[name]["Tris"], "Set": info[name]["Set"], "Material": info[name]["Material"], "Center": [round(c, 3) for c in center], "Size": [round(s, 3) for s in size], "Color": color, "Lod": name == "NaveLOD"})
    total = sum(p["Tris"] for p in manifest["Pieces"] if not p["Lod"])
    manifest["TotalTris"] = total
    manifest["Budget"] = {"MaxTrisPerMesh": MAX_TRIS, "LodTris": list(LOD_TRIS)}
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    if not args.no_luau:
        write_luau(args.luau, manifest, P)
    log(f"mallas y texturas listas: {total} triángulos (alta) + {info['NaveLOD']['Tris']} (LOD) en {time.time() - t_start:.0f}s")
    bad = [p["Name"] for p in manifest["Pieces"] if p["Tris"] > MAX_TRIS]
    lod = info["NaveLOD"]["Tris"]
    if bad or not (LOD_TRIS[0] <= lod <= LOD_TRIS[1]):
        log(f"⚠️  fuera de presupuesto: {bad} / LOD {lod}")
    if args.no_render:
        return
    # Vista previa: la nave de alta con sus texturas horneadas + brillos
    objs["NaveLOD"].hide_render = True
    objs["TrenPata"].hide_render = True  # (en vuelo, el tren va recogido)
    for o in objs.values():
        if o.name in ("BrilloAzul", "BrilloRojo"):
            single_material(o, emission_mat("E" + o.name, pal[{"BrilloAzul": "brillo_azul", "BrilloRojo": "brillo_rojo"}[o.name]], 12.0))
    render_extras(P, coll)
    os.makedirs(args.docs, exist_ok=True)
    only = [v for v in args.views.split(",") if v]
    paths = render_views(P, args.docs, args.samples, objs, only=only, percent=args.percent)
    if only:
        return
    stats = [("VELOCIDAD MÁX.", "1.250 km/h"), ("ESCUDOS", "100%"), ("ESTRUCTURA", "100%"), ("CAPACIDAD DE CARGA", "12.000 kg")]
    compose_sheet(P, paths, os.path.join(args.docs, "referencia-nave.png"), os.path.join(args.docs, "nave-realista-hoja.jpg"), os.path.join(args.docs, "nave-realista-comparacion.jpg"), stats)
    log(f"todo listo en {time.time() - t_start:.0f}s")


if __name__ == "__main__":
    main()
