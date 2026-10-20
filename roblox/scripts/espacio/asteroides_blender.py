#!/usr/bin/env python3
"""Asteroides «AAA» hechos en Blender con Python (docs/espacio-aaa/asteroides.md).

1. Mallas: 6 rocas (una por variante de shared/Cosmos/Asteroids: Patata, Losa, Bloque, Doble, Astilla,
   Piña) a partir de una icoesfera con relieve de ruido fractal, cráteres con su borde y la forma de la
   variante; diezmadas a unos 2.400 triángulos (móvil) y con textura horneada (color y normal, 512 px).
   Salen en assets/asteroides (FBX para subir a Roblox + OBJ para las pruebas), con manifest.json y
   src/shared/Cosmos/AsteroidMalla.luau (la «Medida» de cada una en radios, la usa AsteroidBuild).
   Subir: bash scripts/upload-asteroides.sh (lo hace el dueño; mientras tanto el juego usa las de piezas).
2. Imagen antes / después (docs/espacio-aaa/asteroides-antes-despues.jpg): el mismo grupo de asteroides
   del Cinturón de Hierro (scripts/espacio/asteroides-dump.luau, la forma de verdad del juego) como era
   (bolas lisas), con piezas (lo que se ve ya, sin subir nada), con la malla de Blender y uno rompiéndose.

Necesita Blender como módulo de Python:   pip install bpy==4.2.0   (Python 3.11; todo en CPU)

Uso (desde la carpeta roblox/):
    lune run scripts/espacio/asteroides-dump.luau > /tmp/asteroides.json
    python3 scripts/espacio/asteroides_blender.py --dump /tmp/asteroides.json
    python3 scripts/espacio/asteroides_blender.py --no-render          (solo las mallas)
"""
import argparse
import json
import math
import os
import random
import sys
import time

import bpy  # noqa: I001 (bpy antes que bmesh)
import bmesh
from mathutils import Matrix, Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# (nombre, medias medidas en radios: X, Y, Z de Roblox) — las de Asteroids.VARIANT_BOX, más o menos
VARIANTS = [
    ("Patata", (1.0, 0.66, 0.76)),
    ("Losa", (1.0, 0.42, 0.82)),
    ("Bloque", (1.0, 0.72, 0.84)),
    ("Doble", (1.0, 0.56, 0.6)),
    ("Astilla", (1.0, 0.42, 0.46)),
    ("Pina", (1.0, 0.68, 0.78)),
]
TARGET_TRIS = 2400
M_RB = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # Roblox -> Blender (x, -z, y)


def log(msg):
    print(f"[asteroides] {msg}", flush=True)


def to_b(p):
    return Vector((p[0], -p[2], p[1]))


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def select_only(objs, active=None):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or objs[0]


# ====================================================================== mallas
def rock_mesh(index, name, half, seed):
    """Icoesfera deformada (en coordenadas de Roblox) -> objeto de Blender"""
    rnd = random.Random(seed)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=5, radius=1.0)
    off = Vector((rnd.uniform(0, 100), rnd.uniform(0, 100), rnd.uniform(0, 100)))
    craters = []
    for _ in range(rnd.randint(7, 12)):
        c = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))).normalized()
        craters.append((c, rnd.uniform(0.12, 0.42), rnd.uniform(0.035, 0.11)))
    lobe = Vector((1, 0, 0))
    for v in bm.verts:
        d = v.co.normalized()  # (las coordenadas del bmesh las tratamos como de Roblox)
        r = 1.0
        r += 0.16 * noise.fractal(d * 1.2 + off, 0.65, 2.0, 4)
        r += 0.05 * noise.fractal(d * 5.5 + off * 1.7, 0.5, 2.1, 3)
        # (caras rotas: un ruido de celdas aplana trozos y deja aristas, como roca partida)
        cell = noise.cell(d * 2.2 + off)
        r -= 0.05 * cell
        for c, ang, dep in craters:
            a = d.angle(c)
            x = a / ang
            if x < 1.0:
                r -= dep * (1.0 - x * x)
            elif x < 1.45:
                t = (x - 1.0) / 0.45
                r += dep * 0.4 * (1.0 - t) * (1.0 - t)
        if name == "Doble":
            k = abs(d.dot(lobe))
            r *= 0.78 + 0.42 * k ** 1.5
        p = Vector((d.x * half[0], d.y * half[1], d.z * half[2])) * r
        v.co = p
    # Normalizar: el punto más lejano a 1 radio del centro de la caja
    lo = Vector((min(v.co.x for v in bm.verts), min(v.co.y for v in bm.verts), min(v.co.z for v in bm.verts)))
    hi = Vector((max(v.co.x for v in bm.verts), max(v.co.y for v in bm.verts), max(v.co.z for v in bm.verts)))
    mid = (lo + hi) / 2
    far = max((v.co - mid).length for v in bm.verts)
    for v in bm.verts:
        v.co = to_b((v.co - mid) / far)
    me = bpy.data.meshes.new(f"Asteroide{index}")
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(f"Asteroide{index}", me)
    bpy.context.scene.collection.objects.link(obj)
    # Diezmar (facetas de roca y pocos triángulos para el móvil)
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    dec = obj.modifiers.new("Diezmar", "DECIMATE")
    dec.ratio = min(1.0, TARGET_TRIS / max(tris, 1))
    select_only([obj])
    bpy.ops.object.modifier_apply(modifier=dec.name)
    tri = obj.modifiers.new("Triangular", "TRIANGULATE")
    bpy.ops.object.modifier_apply(modifier=tri.name)
    for p in obj.data.polygons:
        p.use_smooth = False
    return obj


def rock_material(name, seed):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    b.name = "BSDF"
    b.inputs["Roughness"].default_value = 0.88
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Location"].default_value = (seed * 0.37 % 10, seed * 0.71 % 10, seed * 0.13 % 10)
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    n1 = nt.nodes.new("ShaderNodeTexNoise")
    n1.inputs["Scale"].default_value = 3.5
    n1.inputs["Detail"].default_value = 10
    n1.inputs["Roughness"].default_value = 0.6
    nt.links.new(mp.outputs["Vector"], n1.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.35
    ramp.color_ramp.elements[0].color = (0.07, 0.064, 0.058, 1)
    ramp.color_ramp.elements[1].position = 0.72
    ramp.color_ramp.elements[1].color = (0.34, 0.31, 0.28, 1)
    mid = ramp.color_ramp.elements.new(0.55)
    mid.color = (0.18, 0.16, 0.14, 1)
    nt.links.new(n1.outputs["Fac"], ramp.inputs["Fac"])
    # Huecos más oscuros (cráteres y grietas: «pointiness» de Cycles)
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    cav = nt.nodes.new("ShaderNodeMapRange")
    cav.inputs["From Min"].default_value = 0.46
    cav.inputs["From Max"].default_value = 0.54
    cav.inputs["To Min"].default_value = 0.45
    cav.inputs["To Max"].default_value = 1.15
    nt.links.new(geo.outputs["Pointiness"], cav.inputs["Value"])
    mul = nt.nodes.new("ShaderNodeMix")
    mul.data_type = "RGBA"
    mul.blend_type = "MULTIPLY"
    mul.inputs["Factor"].default_value = 1.0
    nt.links.new(ramp.outputs["Color"], mul.inputs[6])
    nt.links.new(cav.outputs["Result"], mul.inputs[7])
    nt.links.new(mul.outputs[2], b.inputs["Base Color"])
    # Relieve fino (poros y estrías) para el mapa de normales
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 14
    nt.links.new(mp.outputs["Vector"], vor.inputs["Vector"])
    n2 = nt.nodes.new("ShaderNodeTexNoise")
    n2.inputs["Scale"].default_value = 22
    n2.inputs["Detail"].default_value = 8
    nt.links.new(mp.outputs["Vector"], n2.inputs["Vector"])
    add = nt.nodes.new("ShaderNodeMath")
    add.operation = "ADD"
    nt.links.new(vor.outputs["Distance"], add.inputs[0])
    nt.links.new(n2.outputs["Fac"], add.inputs[1])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.45
    bump.inputs["Distance"].default_value = 0.02
    nt.links.new(add.outputs[0], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    target = nt.nodes.new("ShaderNodeTexImage")
    target.name = "BakeTarget"
    nt.nodes.active = target
    return m


def unwrap(obj):
    select_only([obj])
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.01, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.object.mode_set(mode="OBJECT")


def bake(obj, mat, size, out_dir, base):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 4
    scene.render.bake.margin = 6
    paths = {}
    for kind in ("color", "normal"):
        img = bpy.data.images.new(f"{base}_{kind}", size, size, alpha=False)
        img.colorspace_settings.name = "sRGB" if kind == "color" else "Non-Color"
        node = mat.node_tree.nodes.get("BakeTarget")
        node.image = img
        mat.node_tree.nodes.active = node
        select_only([obj])
        if kind == "color":
            bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_clear=True, margin=6)
        else:
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT", use_clear=True, margin=6)
        path = os.path.join(out_dir, f"{base}_{kind}.png")
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
        paths[kind] = path
    return paths


def pbr_material(name, paths):
    mat = bpy.data.materials.new("PBR_" + name)
    mat.use_nodes = True
    nt = mat.node_tree
    b = nt.nodes.get("Principled BSDF")
    b.inputs["Roughness"].default_value = 0.85
    col = nt.nodes.new("ShaderNodeTexImage")
    col.image = bpy.data.images.load(paths["color"], check_existing=True)
    nt.links.new(col.outputs["Color"], b.inputs["Base Color"])
    nor = nt.nodes.new("ShaderNodeTexImage")
    nor.image = bpy.data.images.load(paths["normal"], check_existing=True)
    nor.image.colorspace_settings.name = "Non-Color"
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(nor.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return mat


def export(obj, out_dir):
    select_only([obj])
    fbx = os.path.join(out_dir, obj.name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=True, add_leaf_bones=False, path_mode="STRIP", embed_textures=False, use_custom_props=False)
    objp = os.path.join(out_dir, obj.name + ".obj")
    bpy.ops.wm.obj_export(filepath=objp, export_selected_objects=True, forward_axis="NEGATIVE_Z", up_axis="Y", export_normals=False, export_uv=True, export_materials=False, export_triangulated_mesh=True, apply_modifiers=True)


def bbox_roblox(obj):
    pts = [Vector((v.co.x, v.co.z, -v.co.y)) for v in obj.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    far = max(p.length for p in pts)
    return hi - lo, far


def write_luau(path, manifest):
    lines = [
        "-- AsteroidMalla: GENERADO por scripts/espacio/asteroides_blender.py (no editar a mano).",
        "-- Las mallas de asteroide de Blender (assets/asteroides; se suben con scripts/upload-asteroides.sh):",
        "-- una por variante de shared/Cosmos/Asteroids, con su caja («Medida») en radios de choque: la MeshPart",
        "-- se pone de tamaño Medida × radio (World/AsteroidMeshes, shared/Cosmos/AsteroidBuild).",
        "return {",
        "\tVariantes = {",
    ]
    for m in manifest["Mallas"]:
        s = m["Medida"]
        lines.append(f"\t\t{{ Name = \"{m['Nombre']}\", Variant = {m['Variante']}, Silueta = \"{m['Silueta']}\", Medida = Vector3.new({s[0]:.3f}, {s[1]:.3f}, {s[2]:.3f}), Tris = {m['Tris']} }},")
    lines += ["\t},", "}", ""]
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def build_meshes(out_dir, tex_size):
    os.makedirs(os.path.join(out_dir, "tex"), exist_ok=True)
    manifest = {"Mallas": []}
    objs = {}
    for i, (name, half) in enumerate(VARIANTS, start=1):
        t0 = time.time()
        obj = rock_mesh(i, name, half, 1000 + i * 77)
        unwrap(obj)
        mat = rock_material(f"Roca{i}", i)
        obj.data.materials.append(mat)
        paths = bake(obj, mat, tex_size, os.path.join(out_dir, "tex"), f"asteroide{i}")
        obj.data.materials.clear()
        obj.data.materials.append(pbr_material(f"Roca{i}", paths))
        export(obj, out_dir)
        size, far = bbox_roblox(obj)
        tris = len(obj.data.polygons)
        manifest["Mallas"].append({"Nombre": obj.name, "Variante": i, "Silueta": name, "Medida": [size.x, size.y, size.z], "Lejos": far, "Tris": tris, "FBX": obj.name + ".fbx", "OBJ": obj.name + ".obj", "Texturas": {k: os.path.relpath(v, out_dir) for k, v in paths.items()}})
        objs[i] = obj
        log(f"{obj.name} ({name}): {tris} triángulos, caja {size.x:.2f} × {size.y:.2f} × {size.z:.2f} radios ({time.time() - t0:.1f}s)")
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    write_luau(os.path.join(ROOT, "src", "shared", "Cosmos", "AsteroidMalla.luau"), manifest)
    return objs, manifest


# ====================================================================== render antes / después
def mat_cache():
    cache = {}

    def get(kind, color, tr=0.0):
        key = (kind, tuple(round(c, 3) for c in color), round(tr, 2))
        if key in cache:
            return cache[key]
        m = bpy.data.materials.new(f"{kind}_{len(cache)}")
        m.use_nodes = True
        nt = m.node_tree
        b = nt.nodes.get("Principled BSDF")
        b.inputs["Base Color"].default_value = (*[c ** 2.2 for c in color], 1)
        if kind == "Neon":
            b.inputs["Emission Color"].default_value = (*[c ** 2.2 for c in color], 1)
            b.inputs["Emission Strength"].default_value = 6.0 * (1 - tr)
            if tr > 0.05:
                b.inputs["Alpha"].default_value = max(0.25, 1 - tr)
        elif kind == "Metal":
            b.inputs["Metallic"].default_value = 0.9
            b.inputs["Roughness"].default_value = 0.35
        elif kind == "Glass":
            b.inputs["Transmission Weight"].default_value = 0.8
            b.inputs["Roughness"].default_value = 0.1
            b.inputs["Emission Color"].default_value = (*[c ** 2.2 for c in color], 1)
            b.inputs["Emission Strength"].default_value = 1.5
        elif kind == "Smooth":
            b.inputs["Roughness"].default_value = 0.55
        else:
            # Roca (Slate, Rock, Basalt, Glacier, CrackedLava): rugosa con grano (como los materiales de Roblox)
            b.inputs["Roughness"].default_value = 0.92
            tc = nt.nodes.new("ShaderNodeTexCoord")
            nz = nt.nodes.new("ShaderNodeTexNoise")
            nz.inputs["Scale"].default_value = 0.35
            nz.inputs["Detail"].default_value = 10
            nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
            bump = nt.nodes.new("ShaderNodeBump")
            bump.inputs["Strength"].default_value = 0.35
            nt.links.new(nz.outputs["Fac"], bump.inputs["Height"])
            nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
        cache[key] = m
        return m

    return get


ROCK_MATS = {"Slate", "Rock", "Basalt", "Glacier", "CrackedLava", "Sandstone", "Slate"}


def piece_geometry(kind, size):
    """Vértices locales (Roblox) y caras de una pieza"""
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    if kind == "Wedge":
        v = [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz), (-hx, hy, hz), (hx, hy, hz)]
        f = [(0, 3, 2, 1), (3, 4, 5, 2), (0, 1, 5, 4), (0, 4, 3), (1, 2, 5)]
        return v, f
    if kind == "CornerWedge":
        v = [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz), (hx, hy, -hz)]
        f = [(0, 3, 2, 1), (0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4)]
        return v, f
    if kind == "Cylinder":
        n = 20
        r = min(hy, hz)
        v = []
        for s in (-hx, hx):
            for i in range(n):
                a = i / n * math.tau
                v.append((s, math.cos(a) * r, math.sin(a) * r))
        f = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))]
        for i in range(n):
            j = (i + 1) % n
            f.append((i, j, n + j, n + i))
        return v, f
    v = [(sx * hx, sy * hy, sz * hz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return v, f


def cf_apply(cf, p):
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf
    return (x + r00 * p[0] + r01 * p[1] + r02 * p[2], y + r10 * p[0] + r11 * p[1] + r12 * p[2], z + r20 * p[0] + r21 * p[1] + r22 * p[2])


def add_mesh(name, verts_rb, faces, mat):
    me = bpy.data.meshes.new(name)
    me.from_pydata([to_b(v) for v in verts_rb], [], faces)
    me.update()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def build_parts(pieces, mats, tag):
    for i, p in enumerate(pieces):
        v, f = piece_geometry(p["K"], p["Size"])
        world = [cf_apply(p["CF"], q) for q in v]
        mname = p["Mat"]
        kind = "Neon" if mname == "Neon" else "Metal" if mname == "Metal" else "Glass" if mname == "Glass" else "Rock" if mname in ROCK_MATS else "Smooth"
        add_mesh(f"{tag}_{i}", world, f, mats(kind, p["Color"], p.get("Tr", 0)))


def build_sphere(center, radius, mat, name):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=radius, location=to_b(center))
    o = bpy.context.active_object
    o.name = name
    bpy.ops.object.shade_smooth()
    o.data.materials.append(mat)


def place_mesh(src, cf, radius, medida, name):
    me = src.data.copy()
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf
    R = Matrix(((r00, r01, r02), (r10, r11, r12), (r20, r21, r22)))
    A = M_RB @ R @ M_RB.inverted() @ Matrix.Diagonal((radius, radius, radius))
    m4 = A.to_4x4()
    m4.translation = to_b((x, y, z))
    me.transform(m4)
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def surface_pieces(rock, medida):
    """Como AsteroidBuild con malla: vetas, grietas y cristales sobre el elipsoide de la malla"""
    out = []
    cf = rock["CF"]
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf
    semi = [medida[0] * rock["Radius"] / 2, medida[1] * rock["Radius"] / 2, medida[2] * rock["Radius"] / 2]
    for p in rock["Pieces"]:
        role = p["Role"]
        if role in ("Core", "Facet", "Crater", "Rim"):
            continue
        q = dict(p)
        if role in ("Vein", "Crack", "Shard"):
            w = (p["CF"][0] - x, p["CF"][1] - y, p["CF"][2] - z)
            lp = (r00 * w[0] + r10 * w[1] + r20 * w[2], r01 * w[0] + r11 * w[1] + r21 * w[2], r02 * w[0] + r12 * w[1] + r22 * w[2])
            ln = math.sqrt(sum(c * c for c in lp))
            if ln > 1e-3:
                d = [c / ln for c in lp]
                k = 1 / math.sqrt(sum((d[i] / semi[i]) ** 2 for i in range(3)))
                np_ = cf_apply(cf, [c * k * 0.9 for c in d])
                q["CF"] = [np_[0], np_[1], np_[2]] + list(p["CF"][3:])
        out.append(q)
    return out


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
    vor.inputs["Scale"].default_value = 300
    nt.links.new(tc.outputs["Generated"], vor.inputs["Vector"])
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value = 0.0
    mr.inputs["From Max"].default_value = 0.06
    mr.inputs["To Min"].default_value = 1.0
    mr.inputs["To Max"].default_value = 0.0
    nt.links.new(vor.outputs["Distance"], mr.inputs["Value"])
    pw = nt.nodes.new("ShaderNodeMath")
    pw.operation = "POWER"
    pw.inputs[1].default_value = 16
    nt.links.new(mr.outputs["Result"], pw.inputs[0])
    neb = nt.nodes.new("ShaderNodeTexNoise")
    neb.inputs["Scale"].default_value = 1.4
    neb.inputs["Detail"].default_value = 6
    nt.links.new(tc.outputs["Generated"], neb.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.42
    ramp.color_ramp.elements[0].color = (0.002, 0.003, 0.01, 1)
    ramp.color_ramp.elements[1].position = 0.85
    ramp.color_ramp.elements[1].color = (0.03, 0.04, 0.12, 1)
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


def look_at(obj, eye, target):
    eye_b, tgt_b = to_b(eye), to_b(target)
    d = (tgt_b - eye_b).normalized()
    obj.location = eye_b
    obj.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


def setup_render(samples, w, h):
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
    try:
        scene.view_settings.look = "AgX - Punchy"
    except Exception:
        pass
    scene.render.resolution_x = w
    scene.render.resolution_y = h
    scene.render.film_transparent = False
    setup_world(scene)


def add_lights(focus):
    scene = bpy.context.scene
    sun = bpy.data.lights.new("Sol", "SUN")
    sun.energy = 6.0
    sun.angle = math.radians(1.5)
    sun.color = (1.0, 0.95, 0.88)
    so = bpy.data.objects.new("Sol", sun)
    scene.collection.objects.link(so)
    look_at(so, (focus[0] - 600, focus[1] + 500, focus[2] + 250), focus)
    rim = bpy.data.lights.new("Borde", "SUN")
    rim.energy = 2.8
    rim.angle = math.radians(3)
    rim.color = (0.45, 0.65, 1.0)
    ro = bpy.data.objects.new("Borde", rim)
    scene.collection.objects.link(ro)
    look_at(ro, (focus[0] + 500, focus[1] + 150, focus[2] - 700), focus)
    fill = bpy.data.lights.new("Relleno", "SUN")
    fill.energy = 0.25
    fill.color = (0.6, 0.5, 0.45)
    fo = bpy.data.objects.new("Relleno", fill)
    scene.collection.objects.link(fo)
    look_at(fo, (focus[0] + 300, focus[1] - 400, focus[2] + 500), focus)


def clear_objects():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)


def debris(center, radius, mats, rnd, n=26):
    rock = mats("Rock", (0.36, 0.34, 0.32))
    hot = mats("Neon", (1.0, 0.47, 0.18))
    for i in range(n):
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))).normalized()
        p = Vector(center) + d * radius * rnd.uniform(0.9, 2.2)
        s = radius * rnd.uniform(0.04, 0.12)
        v, f = piece_geometry("Block" if rnd.random() < 0.6 else "CornerWedge", (s, s * 0.7, s * 0.9))
        ang = [rnd.uniform(0, math.tau) for _ in range(3)]
        rot = Matrix.Rotation(ang[0], 3, "X") @ Matrix.Rotation(ang[1], 3, "Y") @ Matrix.Rotation(ang[2], 3, "Z")
        world = [tuple(Vector(q) @ rot + p) for q in v]
        add_mesh(f"Lasca{i}", world, f, hot if rnd.random() < 0.18 else rock)
    # Chispas (puntitos que brillan) y polvo (una nube suave)
    for i in range(40):
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))).normalized()
        p = Vector(center) + d * radius * rnd.uniform(1.0, 2.6)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=radius * 0.012, location=to_b(p))
        bpy.context.active_object.data.materials.append(mats("Neon", (1.0, 0.8, 0.5)))
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=radius * 1.35, location=to_b(center))
    cloud = bpy.context.active_object
    vm = bpy.data.materials.new("Polvo")
    vm.use_nodes = True
    nt = vm.node_tree
    nt.nodes.remove(nt.nodes.get("Principled BSDF"))
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Color"].default_value = (0.5, 0.46, 0.42, 1)
    vol.inputs["Density"].default_value = 0.0018
    nt.links.new(vol.outputs[0], nt.nodes.get("Material Output").inputs["Volume"])
    cloud.data.materials.append(vm)
    glow = bpy.data.lights.new("Brasa", "POINT")
    glow.energy = 2.0e5
    glow.color = (1.0, 0.5, 0.2)
    go = bpy.data.objects.new("Brasa", glow)
    go.location = to_b(center)
    bpy.context.scene.collection.objects.link(go)


def render_panels(dump, mesh_objs, manifest, out_img, samples, w, h):
    focus = dump["Focus"]
    rocks = dump["Rocks"]
    # Cámara: desde un lado y algo arriba, encuadrando el grupo
    cx = sum(r["Center"][0] for r in rocks) / len(rocks)
    cy = sum(r["Center"][1] for r in rocks) / len(rocks)
    cz = sum(r["Center"][2] for r in rocks) / len(rocks)
    center = (cx, cy, cz)
    span = max(math.dist(r["Center"], center) + r["Radius"] for r in rocks)
    eye = (cx + span * 1.15, cy + span * 0.45, cz + span * 1.55)
    medidas = {m["Variante"]: m["Medida"] for m in manifest["Mallas"]} if manifest else {}
    paths = []
    for panel in ("antes", "piezas", "malla", "rotura"):
        if panel == "malla" and not mesh_objs:
            continue
        t0 = time.time()
        # (las mallas de Blender se guardan fuera de la escena entre paneles)
        for o in list(bpy.context.scene.collection.objects):
            if o.name.startswith("Asteroide") and o.name[9:].isdigit():
                bpy.context.scene.collection.objects.unlink(o)
            else:
                bpy.data.objects.remove(o, do_unlink=True)
        setup_render(samples, w, h)
        mats = mat_cache()
        add_lights(center)
        cam = bpy.data.cameras.new("Camara")
        cam.lens = 32
        cam.clip_end = 100000
        co = bpy.data.objects.new("Camara", cam)
        bpy.context.scene.collection.objects.link(co)
        bpy.context.scene.camera = co
        look_at(co, eye, center)
        if panel == "antes":
            grey = mats("Smooth", (0.42, 0.42, 0.44))
            dark = mats("Smooth", (0.24, 0.24, 0.26))
            for r in rocks:
                build_sphere(r["Center"], r["Radius"], grey, "Bola_" + r["Id"])
                c = r["Center"]
                build_sphere((c[0] + r["Radius"] * 0.55, c[1] + r["Radius"] * 0.2, c[2] - r["Radius"] * 0.3), r["Radius"] * 0.55, dark, "Trozo_" + r["Id"])
        elif panel == "piezas":
            for r in rocks:
                build_parts(r["Pieces"], mats, r["Id"])
        elif panel == "malla":
            for r in rocks:
                src = mesh_objs[r["Variant"]]
                place_mesh(src, r["CF"], r["Radius"], medidas[r["Variant"]], "M_" + r["Id"])
                build_parts(surface_pieces(r, medidas[r["Variant"]]), mats, "S_" + r["Id"])
        else:
            rnd = random.Random(7)
            for r in rocks:
                if r["Id"] != dump["Broken"]:
                    build_parts(r["Pieces"], mats, r["Id"])
            for fr in dump["Fragments"]:
                build_parts(fr["Pieces"], mats, fr["Id"])
            debris(dump["BrokenCenter"], dump["BrokenRadius"], mats, rnd)
        path = os.path.join(out_img, f"asteroides-{panel}.png")
        bpy.context.scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        paths.append((panel, path))
        log(f"panel {panel}: {time.time() - t0:.1f}s")
    return paths


def compose(paths, out_jpg, w, h):
    from PIL import Image, ImageDraw, ImageFont

    titles = {
        "antes": "ANTES · bolas lisas",
        "piezas": "AHORA · rocas de piezas (sin subir nada)",
        "malla": "AHORA · malla de Blender (tras subirla)",
        "rotura": "ROTURA · trozos, lascas, chispas y polvo",
    }
    cols = 2
    rows = (len(paths) + 1) // 2
    sheet = Image.new("RGB", (w * cols, h * rows), (0, 0, 0))
    try:
        font = ImageFont.truetype(FONT_BOLD, max(18, h // 22))
    except Exception:
        font = ImageFont.load_default()
    for i, (panel, path) in enumerate(paths):
        img = Image.open(path).convert("RGB").resize((w, h))
        d = ImageDraw.Draw(img)
        d.rectangle([0, 0, w, h // 12 + 8], fill=(0, 0, 0))
        d.text((14, 6), titles.get(panel, panel), fill=(255, 255, 255) if panel != "antes" else (255, 170, 150), font=font)
        sheet.paste(img, ((i % cols) * w, (i // cols) * h))
    sheet.save(out_jpg, quality=88)
    log(f"imagen: {out_jpg}")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "asteroides"))
    ap.add_argument("--dump", default=None, help="JSON de scripts/espacio/asteroides-dump.luau (para la imagen)")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--samples", type=int, default=24)
    ap.add_argument("--tex", type=int, default=512)
    ap.add_argument("--width", type=int, default=960)
    ap.add_argument("--height", type=int, default=540)
    ap.add_argument("--docs", default=os.path.join(ROOT, "docs", "espacio-aaa"))
    args = ap.parse_args(argv)
    os.makedirs(args.out, exist_ok=True)
    reset_scene()
    mesh_objs, manifest = build_meshes(args.out, args.tex)
    if args.no_render or not args.dump:
        return
    with open(args.dump, encoding="utf-8") as f:
        dump = json.load(f)
    import tempfile

    tmp = tempfile.mkdtemp(prefix="asteroides-render-")
    paths = render_panels(dump, mesh_objs, manifest, tmp, args.samples, args.width, args.height)
    compose(paths, os.path.join(args.docs, "asteroides-antes-despues.jpg"), args.width, args.height)


if __name__ == "__main__":
    main()
