#!/usr/bin/env python3
"""Vistas previas de NÁCARA v2 (docs/mar/nacara-v2/diseno.md) en Blender. NO es Roblox.

Lo que dibuja sale del MISMO código del juego, volcado por scripts/map/nacara-export.luau (… fase1 x v2):
  * las piezas de la plaza de la fase 0, de los barrios de la fase 1 y de NacaraDecor (respaldo de piezas);
  * los 16 barrios de World/NacaraV2Builder.plan({ All = true }): sus piezas (SmoothPlastic, Glass, Neon, Fabric,
    con sus luces), las MALLAS del kit del mar (assets/mar/*.fbx: coral, rocas, kelp, plantas que brillan) y los
    rellenos de terreno de las islas (basalto, peñascos, grano claro y la cueva);
  * la luz y la bruma de la Llanura a 38 m de NOCHE (OceanBiomes.look + Nacara.lookNear).
Lo que NO sale del juego (ambiente para que se lea la escena; en el juego lo ponen otros sistemas o no está):
  * bancos de peces, medusas y mantas (en el juego: SeaLife/NacaraLife, con las mallas de MarFauna);
  * haces de luz de luna (en el juego: Beams de ReefZoneFx, más tenues de noche);
  * el agua de Roblox, su bruma y el Bloom: aquí, niebla de composición y brillo de Cycles.

Uso (desde roblox/; bpy 4.2 con Python 3.11):
    lune run scripts/map/nacara-export.luau /tmp/nacara.json fase1 x v2
    python3 scripts/map/nacara_v2_preview.py /tmp/nacara.json docs/mar/nacara-v2 [--muestras 48] [--ancho 1920] [--solo general,1]
Salen vista-general.jpg (el ángulo del mapa del dueño), vista-1…5.jpg (cámara del móvil, a la altura del jugador)
y comparacion.jpg (el mapa del dueño al lado de la vista general).
"""
import argparse
import json
import math
import os
import random

import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MAR = os.path.join(ROOT, "assets", "mar")
REF = os.path.join(ROOT, "docs", "mar", "referencia", "ciudad-marina-dueno.png")


def rb(x, y, z):
    """Roblox (x, y, z) -> Blender (x, -z, y)."""
    return Vector((x, -z, y))


def lin1(v):
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def lin(c):
    k = 255.0 if max(c[:3]) > 1.0 else 1.0
    return [lin1(v / k) for v in c[:3]]


_mats = {}


def material(key, color, rough=0.6, emission=0.0, alpha=1.0, glass=False, image=None, normal=None):
    name = f"{key}|{tuple(round(v, 3) for v in color) if color else None}|{emission}|{alpha}|{glass}"
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    if image and os.path.exists(image):
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(image, check_existing=True)
        nt.links.new(tex.outputs["Color"], b.inputs["Base Color"])
        if normal and os.path.exists(normal):
            nm = nt.nodes.new("ShaderNodeTexImage")
            nm.image = bpy.data.images.load(normal, check_existing=True)
            nm.image.colorspace_settings.name = "Non-Color"
            nn = nt.nodes.new("ShaderNodeNormalMap")
            nt.links.new(nm.outputs["Color"], nn.inputs["Color"])
            nt.links.new(nn.outputs["Normal"], b.inputs["Normal"])
    else:
        b.inputs["Base Color"].default_value = (*lin(color or (200, 200, 200)), 1)
    b.inputs["Roughness"].default_value = rough
    if emission > 0:
        b.inputs["Emission Color"].default_value = (*lin(color), 1)
        b.inputs["Emission Strength"].default_value = emission
    if glass:
        b.inputs["Transmission Weight"].default_value = 1.0
        b.inputs["Roughness"].default_value = 0.05
        b.inputs["IOR"].default_value = 1.03
        b.inputs["Coat Weight"].default_value = 0.5
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
        m.blend_method = "BLEND"
    _mats[name] = m
    return m


def part_material(p, night):
    mat, c = p["Material"], p["Color"]
    t = p.get("Transparency", 0) or 0
    if mat == "Neon":
        return material("neon", c, emission=3.5 if night else 2.5, alpha=max(0.2, 1 - t))
    if mat == "Glass":
        return material("glass", c, glass=True, alpha=max(0.25, 1 - t * 0.7))
    rough = {"SmoothPlastic": 0.3, "Plastic": 0.5, "Fabric": 0.9, "Salt": 0.95, "Rock": 0.9, "Sandstone": 0.9}.get(mat, 0.6)
    return material(mat, c, rough=rough, alpha=max(0.1, 1 - t))


# ---------------------------------------------------------------------------
# Piezas de Roblox
# ---------------------------------------------------------------------------
_proto = {}


def prim(kind):
    if kind in _proto:
        return _proto[kind]
    if kind == "Block":
        bpy.ops.mesh.primitive_cube_add(size=1)
    elif kind == "Cylinder":
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.5, depth=1)
        bpy.context.active_object.data.transform(Matrix.Rotation(math.radians(90), 4, "Y"))
    elif kind in ("Ball", "Ellipsoid"):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=0.5)
    elif kind == "Wedge":
        bpy.ops.mesh.primitive_cube_add(size=1)
        for v in bpy.context.active_object.data.vertices:
            if v.co.z > 0 and v.co.y > 0:
                v.co.z = -0.5
    o = bpy.context.active_object
    for poly in o.data.polygons:
        poly.use_smooth = kind not in ("Block", "Wedge")
    me = o.data
    me.materials.append(material("base", (200, 200, 200)))
    bpy.data.objects.remove(o)
    _proto[kind] = me
    return me


C3 = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # Roblox -> Blender


def add_part(p, coll, night):
    shape = p["Shape"] if p["Shape"] != "Mesh" else "Block"
    me = prim(shape)
    ob = bpy.data.objects.new("p", me)
    coll.objects.link(ob)
    sx, sy, sz = p["Size"]
    if shape == "Ball":
        sx = sy = sz = min(sx, sy, sz)
    r = p["Rot"]
    R = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8])))
    m4 = (C3 @ R @ Matrix.Diagonal((sx, sy, sz)) @ C3.inverted()).to_4x4()
    m4.translation = rb(*p["Pos"])
    ob.matrix_world = m4
    ob.material_slots[0].link = "OBJECT"
    ob.material_slots[0].material = part_material(p, night)
    ob.visible_shadow = p["Material"] not in ("Glass", "Neon")
    return ob


# ---------------------------------------------------------------------------
# Mallas del kit y de la fauna (assets/mar/*.fbx)
# ---------------------------------------------------------------------------
_fbx = {}
_kitdata = {}


def fbx(name):
    if name in _fbx:
        return _fbx[name]
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(MAR, name + ".fbx"), axis_forward="-Z", axis_up="Y")
    new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    ob = new[0]
    for o in bpy.data.objects:
        if o not in before and o is not ob:
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.context.view_layer.update()
    ob.data.transform(ob.matrix_world)
    ob.matrix_world = Matrix.Identity(4)
    co = np.array([v.co[:] for v in ob.data.vertices])
    lo, hi = co.min(0), co.max(0)
    c = (lo + hi) / 2
    ob.data.transform(Matrix.Translation(Vector((-c[0], -c[1], -lo[2]))))
    ob.hide_render = True
    ob.hide_viewport = True
    _fbx[name] = (ob, hi - lo)
    return _fbx[name]


def kit_mat(kind, color, glow, night):
    lower = kind.lower()
    col = os.path.join(MAR, "tex", lower + "_color.png")
    nor = os.path.join(MAR, "tex", lower + "_normal.png")
    tint = kind not in ("RocaPorosa", "Canto", "RocaLaja", "RocaAguja", "AlmejaGigante", "Pilote", "ColumnaRuina", "PecioBarca", "Piramide")
    if tint or not os.path.exists(col):
        if glow:
            return material("G_" + kind, color, emission=3.0 if night else 1.5)
        plant = kind in ("Pradera", "AlgaAncha", "KelpGigante")
        # (los corales de la v4 llevan el grano del material Salt: rugosos y algo brillantes de noche)
        return material("K_" + kind, color, rough=0.7 if plant else 0.85, emission=0.25 if (night and not plant) else 0.0)
    return material("X_" + kind, None, rough=0.9, image=col, normal=nor)


def place(kind, coll, x, y, z, height=None, length=None, yaw=0.0, mat=None):
    ob0, ext = fbx(kind)
    ob = ob0.copy()
    ob.hide_render = False
    ob.hide_viewport = False
    coll.objects.link(ob)
    k = (height / max(ext[2], 1e-6)) if height is not None else (length / max(ext[1], 1e-6))
    ob.scale = (k, k, k)
    ob.location = rb(x, y, z)
    ob.rotation_euler = Euler((0, 0, yaw))
    ob.visible_shadow = False
    if mat is not None:
        key = (kind, mat.name)
        data = _kitdata.get(key)
        if data is None:
            data = ob0.data.copy()
            data.materials.clear()
            data.materials.append(mat)
            _kitdata[key] = data
        ob.data = data
    return ob


# ---------------------------------------------------------------------------
# Terreno de las islas (los rellenos de NacaraV2Builder)
# ---------------------------------------------------------------------------
ROCK = {"Basalt": (52, 62, 84), "Rock": (78, 84, 98), "Salt": (112, 120, 134)}


def noisy(o, amp, scale, seed):
    tex = bpy.data.textures.new(f"n{seed}", "CLOUDS")
    tex.noise_scale = scale
    md = o.modifiers.new("d", "DISPLACE")
    md.texture = tex
    md.strength = amp
    md.mid_level = 0.5


_rocks = []


def rock_mesh(i):
    """Una de 8 mallas de peñasco (icosfera con ruido aplicado), radio 1, compartidas por todos los peñascos."""
    if not _rocks:
        for k in range(8):
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1)
            o = bpy.context.active_object
            noisy(o, 0.45, 0.7 + k * 0.05, 500 + k)
            bpy.ops.object.modifier_apply(modifier="d")
            for p_ in o.data.polygons:
                p_.use_smooth = True
            me = o.data
            bpy.data.objects.remove(o)
            _rocks.append(me)
    return _rocks[i % len(_rocks)]


def terrain(ops, coll, rnd):
    caves = []
    for i, op in enumerate(ops):
        mat = op["Material"]
        if mat == "Water":
            caves.append(op)
            continue
        if op["Op"] == "Cylinder":
            bpy.ops.mesh.primitive_cylinder_add(vertices=96, radius=op["R"], depth=op["H"], location=rb(*op["Pos"]))
            o = bpy.context.active_object
        elif op["Op"] == "Ball":
            r = op["R"]
            if r > 15:
                # (la cueva: una bola propia, porque se vacía)
                bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=4, radius=r, location=rb(*op["Pos"]))
                o = bpy.context.active_object
                noisy(o, r * 0.12, r * 0.5, i)
            else:
                o = bpy.data.objects.new("roca", rock_mesh(i).copy() if False else rock_mesh(i))
                coll.objects.link(o)
                o.location = rb(*op["Pos"])
                o.scale = (r * (1.0 + rnd.uniform(-0.15, 0.25)), r * (1.0 + rnd.uniform(-0.15, 0.25)), r * (0.75 + rnd.uniform(0, 0.3)))
                o.rotation_euler = (0, 0, rnd.uniform(0, math.tau))
        else:
            sx, sy, sz = op["Size"]
            bpy.ops.mesh.primitive_cube_add(size=1, location=rb(*op["Pos"]))
            o = bpy.context.active_object
            o.scale = (sx, sz, sy)
        for c in o.users_collection:
            c.objects.unlink(o)
        coll.objects.link(o)
        if not o.data.materials:
            o.data.materials.append(material("T_base", ROCK["Basalt"], rough=0.95))
        o.material_slots[0].link = "OBJECT"
        o.material_slots[0].material = material("T_" + mat, ROCK.get(mat, (90, 90, 100)), rough=0.95)
        o["terrain"] = op
        if o.data.users == 1:
            for p_ in o.data.polygons:
                p_.use_smooth = True
    # la cueva: se vacía la bola de basalto grande que la contiene
    for cv in caves:
        target = None
        for o in coll.objects:
            t = o.get("terrain")
            if t and t["Op"] == "Ball" and t["Material"] == "Basalt" and t["R"] > 15 and (Vector(t["Pos"]) - Vector(cv["Pos"])).length < t["R"]:
                target = o
        if target is None:
            continue
        if cv["Op"] == "Ball":
            bpy.ops.mesh.primitive_uv_sphere_add(radius=cv["R"], location=rb(*cv["Pos"]))
        else:
            sx, sy, sz = cv["Size"]
            bpy.ops.mesh.primitive_cube_add(size=1, location=rb(*cv["Pos"]))
            bpy.context.active_object.scale = (sx, sz, sy)
        cutter = bpy.context.active_object
        cutter.hide_render = True
        md = target.modifiers.new("cueva", "BOOLEAN")
        md.operation = "DIFFERENCE"
        md.object = cutter
        target.modifiers.move(len(target.modifiers) - 1, 0)


# ---------------------------------------------------------------------------
# Ambiente (no sale del juego: ver la cabecera)
# ---------------------------------------------------------------------------
def ambience(data, coll, rnd, night):
    cx, cz, fy = data["Center"][0], data["Center"][2], data["FloorY"]
    v2 = data["V2"]["List"]
    # bancos de peces entre las islas
    for s in range(14):
        d = rnd.choice(v2)
        bx = cx + d["X"] + rnd.uniform(-1, 1) * (d["R"] + 25)
        bz = cz + d["Z"] + rnd.uniform(-1, 1) * (d["R"] + 25)
        by = fy + rnd.uniform(18, 42)
        yaw = rnd.uniform(0, math.tau)
        m = material("pez", None, rough=0.5, image=os.path.join(MAR, "tex", "pezbanco_color.png"))
        for i in range(rnd.randint(10, 22)):
            place("PezBanco", coll, bx + rnd.uniform(-7, 7), by + rnd.uniform(-3, 3), bz + rnd.uniform(-7, 7), length=rnd.uniform(1.0, 1.5), yaw=yaw + rnd.uniform(-0.2, 0.2), mat=m)
    # medusas que brillan
    for i in range(22):
        d = rnd.choice(v2)
        a = rnd.uniform(0, math.tau)
        rr = d["R"] + rnd.uniform(5, 30)
        c = rnd.choice([(255, 130, 230), (150, 200, 255), (190, 140, 255)])
        place("Medusa", coll, cx + d["X"] + math.cos(a) * rr, fy + rnd.uniform(20, 55), cz + d["Z"] + math.sin(a) * rr, height=rnd.uniform(3, 6), yaw=a,
              mat=material("medusa", c, emission=4.0 if night else 1.5, alpha=0.75))
    # mantas y tortugas
    for kind, n, L in (("Manta", 3, 14), ("Tortuga", 3, 4)):
        for i in range(n):
            d = rnd.choice(v2)
            place(kind, coll, cx + d["X"] + rnd.uniform(-60, 60), fy + rnd.uniform(30, 60), cz + d["Z"] + rnd.uniform(-60, 60), length=L, yaw=rnd.uniform(0, math.tau),
                  mat=material("F_" + kind, None, image=os.path.join(MAR, "tex", kind.lower() + "_color.png")))
    # haces de luz de luna (tenues)
    for i in range(9):
        x = cx + rnd.uniform(-380, 420)
        z = cz + rnd.uniform(-380, 260)
        bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=rnd.uniform(14, 26), radius2=rnd.uniform(4, 8), depth=150, location=rb(x, fy + 70, z))
        o = bpy.context.active_object
        o.rotation_euler = (math.radians(rnd.uniform(-8, 8)), math.radians(rnd.uniform(-8, 8)), 0)
        o.data.materials.append(material("haz", (150, 210, 255), emission=0.35 if night else 0.8, alpha=0.035))
        o.visible_shadow = False
        for c in o.users_collection:
            c.objects.unlink(o)
        coll.objects.link(o)
    # motas de plancton que brillan
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1)
    mo = bpy.context.active_object
    mote = mo.data
    mote.materials.append(material("mota0", (90, 240, 255), emission=6.0))
    bpy.data.objects.remove(mo)
    for i in range(500):
        d = rnd.choice(v2)
        q = (cx + d["X"] + rnd.uniform(-90, 90), fy + rnd.uniform(4, 60), cz + d["Z"] + rnd.uniform(-90, 90))
        o = bpy.data.objects.new("mota", mote)
        coll.objects.link(o)
        o.location = rb(*q)
        rr = rnd.uniform(0.12, 0.3)
        o.scale = (rr, rr, rr)
        c = rnd.choice([(90, 240, 255), (180, 120, 255), (255, 140, 220), (160, 255, 200)])
        o.material_slots[0].link = "OBJECT"
        o.material_slots[0].material = material("mota", c, emission=6.0)


# ---------------------------------------------------------------------------
def build(data, night, focus=None, radius=None):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()
    _proto.clear()
    _fbx.clear()
    _kitdata.clear()
    _rocks.clear()
    coll = bpy.context.scene.collection
    rnd = random.Random(11)
    cx, cy, cz = data["Center"]
    fy = data["FloorY"]

    def keep(x, z):
        return focus is None or (x - focus[0]) ** 2 + (z - focus[1]) ** 2 < radius ** 2

    # el fondo: la llanura (grano claro, oscuro de noche) con relieve suave
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=160, y_subdivisions=160, size=2600, location=rb(cx + 50, fy - 0.8, cz - 50))
    g = bpy.context.active_object
    noisy(g, 3.5, 40.0, 999)
    g.data.materials.append(material("fondo", (70, 78, 92), rough=1.0))
    v2 = data["V2"]
    terrain([op for op in v2["Terrain"] if keep(op["Pos"][0], op["Pos"][2])], coll, rnd)
    night_glow = night
    for p in data["Parts"]:
        x, z = p["Pos"][0], p["Pos"][2]
        if (x - cx) ** 2 + (z - cz) ** 2 > 760 ** 2 or not keep(x, z):
            continue
        add_part(p, coll, night_glow)
    for k in v2["Kit"]:
        if not keep(k["X"], k["Z"]):
            continue
        c = k.get("Color") or [200, 200, 200]
        place(k["Kind"], coll, k["X"], k["Y"], k["Z"], height=k["Scale"], yaw=k["Yaw"], mat=kit_mat(k["Kind"], c, k.get("Glow"), night))
    for li in data["Lights"]:
        if not keep(li["Pos"][0], li["Pos"][2]):
            continue
        L = bpy.data.lights.new("l", "POINT")
        L.energy = li["Brightness"] * li["Range"] * 160
        L.color = lin(li["Color"])
        L.shadow_soft_size = 1.5
        o = bpy.data.objects.new("l", L)
        o.location = rb(*li["Pos"])
        coll.objects.link(o)
    ambience(data, coll, rnd, night)


def scene_setup(look, args, mist_start, mist_depth, w, h, exposure):
    scene = bpy.context.scene
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (*lin(look["Ambient"]), 1)
    bg.inputs["Strength"].default_value = 0.55
    scene.world = world
    moon = bpy.data.lights.new("luna", "SUN")
    moon.energy = 0.9
    moon.color = lin((150, 190, 255))
    moon.angle = math.radians(12)
    so = bpy.data.objects.new("luna", moon)
    so.rotation_euler = (math.radians(22), math.radians(12), math.radians(35))
    scene.collection.objects.link(so)
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.muestras
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 6
    scene.cycles.transmission_bounces = 6
    scene.cycles.transparent_max_bounces = 12
    scene.render.resolution_x = w
    scene.render.resolution_y = h
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = exposure
    vl = scene.view_layers[0]
    vl.use_pass_mist = True
    world.mist_settings.start = mist_start
    world.mist_settings.depth = mist_depth
    world.mist_settings.falloff = "QUADRATIC"
    scene.use_nodes = True
    nt = scene.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    rl = nt.nodes.new("CompositorNodeRLayers")
    # brillo (como el Bloom de Roblox, más suave)
    glare = nt.nodes.new("CompositorNodeGlare")
    glare.glare_type = "FOG_GLOW"
    glare.quality = "HIGH"
    glare.threshold = 1.4
    glare.size = 6
    nt.links.new(rl.outputs["Image"], glare.inputs["Image"])
    mix = nt.nodes.new("CompositorNodeMixRGB")
    mix.inputs[2].default_value = (*lin(look["Fog"]), 1)
    pw = nt.nodes.new("CompositorNodeMath")
    pw.operation = "MULTIPLY"
    pw.inputs[1].default_value = 0.85
    nt.links.new(rl.outputs["Mist"], pw.inputs[0])
    nt.links.new(pw.outputs[0], mix.inputs[0])
    nt.links.new(glare.outputs["Image"], mix.inputs[1])
    tint = nt.nodes.new("CompositorNodeMixRGB")
    tint.blend_type = "MULTIPLY"
    tint.inputs[0].default_value = 0.25
    tint.inputs[2].default_value = (*lin(look["Tint"]), 1)
    nt.links.new(mix.outputs[0], tint.inputs[1])
    comp = nt.nodes.new("CompositorNodeComposite")
    nt.links.new(tint.outputs[0], comp.inputs[0])
    return scene


def camera(scene, data, cam, tgt, fov):
    cx, cz, fy = data["Center"][0], data["Center"][2], data["FloorY"]
    cd = bpy.data.cameras.new("cam")
    cd.sensor_fit = "VERTICAL"
    cd.angle_y = math.radians(fov)
    cd.clip_end = 4000
    co = bpy.data.objects.new("cam", cd)
    scene.collection.objects.link(co)
    co.location = rb(cx + cam[0], fy + cam[1], cz + cam[2])
    d = rb(cx + tgt[0], fy + tgt[1], cz + tgt[2]) - co.location
    co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    scene.camera = co
    return co


def render(scene, out):
    scene.render.filepath = out
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 92
    bpy.ops.render.render(write_still=True)


def font(size, bold=False):
    try:
        return ImageFont.truetype("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf", size)
    except OSError:
        return ImageFont.load_default()


def label(path, text, tags=None, title=None):
    im = Image.open(path).convert("RGB")
    W, H = im.size
    d = ImageDraw.Draw(im, "RGBA")
    small = font(max(13, W // 85), True)
    placed = []
    for (tx, ty, name) in sorted(tags or [], key=lambda t: -t[1]):
        x, y = int(tx * W), int((1 - ty) * H)
        if not (0 < x < W and 0 < y < H):
            continue
        bb = d.textbbox((0, 0), name, font=small)
        w_, h_ = bb[2] - bb[0], bb[3] - bb[1]
        for _ in range(14):
            box = (x - w_ // 2 - 12, y - h_ - 14, x + w_ // 2 + 12, y)
            if not any(not (box[2] < b[0] or box[0] > b[2] or box[3] < b[1] or box[1] > b[3]) for b in placed):
                break
            y -= h_ + 10
        placed.append(box)
        d.rounded_rectangle(box, radius=(h_ + 14) // 2, fill=(6, 22, 52, 215), outline=(120, 220, 255, 240), width=2)
        d.text((x - w_ // 2, y - h_ - 9), name, fill=(240, 250, 255), font=small)
    big = font(max(16, W // 55), True)
    d.rectangle((0, 0, W, int(H * 0.06)), fill=(0, 0, 0, 150))
    d.text((14, int(H * 0.012)), "VISTA PREVIA, NO ES ROBLOX" + (f"  ·  {title}" if title else ""), fill=(255, 220, 120), font=big)
    d.rectangle((0, H - int(H * 0.045), W, H), fill=(0, 0, 0, 150))
    d.text((14, H - int(H * 0.04)), text, fill=(255, 255, 255), font=font(max(12, W // 100)))
    im.save(path, quality=92)


# Vistas a la altura del jugador (coordenadas de la plaza: x, altura sobre el suelo de la plaza, z)
FRAMES = [
    ("1", "Palacio Real desde la salida norte de la Plaza Central", (-34, 16, -62), (5, 44, -152), "Palacio", 230),
    ("2", "Mercado Submarino: puestos, toldos y farolillos", (-284, 18, -98), (-326, 14, -142), "Mercado", 170),
    ("3", "Acuario Gigante desde el este", (-36, 18, 176), (-117, 20, 158), "Acuario", 200),
    ("4", "Templo de los Sirenos desde la ciudad", (378, 16, -66), (444, 26, -87), "Templo", 190),
    ("5", "Puerto de Sirenas y Jardines de Coral", (268, 18, 92), (318, 10, 140), "Puerto", 220),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("json")
    ap.add_argument("outdir")
    ap.add_argument("--muestras", type=int, default=48)
    ap.add_argument("--ancho", type=int, default=1920)
    ap.add_argument("--solo", default="")
    args = ap.parse_args()
    with open(args.json, encoding="utf-8") as f:
        data = json.load(f)
    os.makedirs(args.outdir, exist_ok=True)
    look = data["Night"]
    only = set(args.solo.split(",")) if args.solo else None
    by = {d["Id"]: d for d in data["V2"]["List"]}
    if not only or "general" in only:
        build(data, True)
        W = args.ancho
        H = W * 2 // 3  # (como el mapa del dueño: 1536 × 1024)
        scene = scene_setup(look, args, 520.0, 1100.0, W, H, 0.2)
        co = camera(scene, data, (48, 370, 545), (48, 0, -125), 48)
        out = os.path.join(args.outdir, "vista-general.jpg")
        render(scene, out)
        cx, cz, fy = data["Center"][0], data["Center"][2], data["FloorY"]
        tags = []
        for d in data["V2"]["List"]:
            v = world_to_camera_view(scene, co, rb(cx + d["X"], fy + 34, cz + d["Z"] - d["R"] * 0.2))
            tags.append((v.x, v.y, d["Name"]))
        label(out, "Nácara v2 · vista general desde el sur, de noche (sin el agua de encima) · las piezas, las mallas del kit y el terreno salen de World/NacaraV2Builder; peces, medusas y haces de luz son ambiente", tags, "Nácara v2")
        ref = Image.open(REF).convert("RGB")
        gen = Image.open(out).convert("RGB")
        h = 900
        ref = ref.resize((int(ref.width * h / ref.height), h))
        gen = gen.resize((int(gen.width * h / gen.height), h))
        sheet = Image.new("RGB", (ref.width + gen.width + 30, h + 80), (8, 14, 28))
        sheet.paste(ref, (10, 70))
        sheet.paste(gen, (ref.width + 20, 70))
        dd = ImageDraw.Draw(sheet)
        dd.text((16, 18), "El mapa del dueño (referencia, hecho con IA)", fill=(255, 255, 255), font=font(30, True))
        dd.text((ref.width + 26, 18), "Nácara v2 · VISTA PREVIA, NO ES ROBLOX", fill=(255, 220, 120), font=font(30, True))
        sheet.save(os.path.join(args.outdir, "comparacion.jpg"), quality=90)
    for fid, title, cam, tgt, focus, radius in FRAMES:
        if only and fid not in only:
            continue
        d = by[focus]
        build(data, True, (data["Center"][0] + d["X"], data["Center"][2] + d["Z"]), radius + 160)
        W = args.ancho
        scene = scene_setup(look, args, 25.0, float(look.get("Visibility", 216)) * 1.15, W, W * 9 // 16, 1.1)
        camera(scene, data, cam, tgt, 70)
        out = os.path.join(args.outdir, f"vista-{fid}.jpg")
        render(scene, out)
        label(out, f"Nácara v2 · vista {fid}: {title} · cámara del móvil (70°) a la altura del jugador · 38 m · noche", None, d["Name"])


if __name__ == "__main__":
    main()
