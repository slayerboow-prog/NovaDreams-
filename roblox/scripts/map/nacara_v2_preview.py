#!/usr/bin/env python3
"""Vistas previas de NÁCARA v2 (docs/mar/nacara-v2/diseno.md) en Blender. NO es Roblox.

Lo que dibuja:
  * Las PIEZAS DE VERDAD de lo que ya existe y del prototipo: la plaza de la fase 0, los barrios de la fase 1, el
    decorado de NacaraDecor (respaldo de piezas) y el Palacio Real + Plaza Central de World/NacaraV2Builder,
    volcados por scripts/map/nacara-export.luau (… fase1 x v2).
  * Los otros 14 barrios del mapa del dueño, que AÚN NO EXISTEN: islas de roca en su sitio (shared/Sea/NacaraV2) con
    una MASA APROXIMADA de cada edificio (cúpulas, torres, puestos…) y las pasarelas y tubos de cristal. Se marcan
    «aprox.» en la vista general.
  * La luz y la bruma bajo el agua de la Llanura a 38 m (OceanBiomes.look + Nacara.lookNear, del mismo volcado).

Uso (desde roblox/; bpy 4.2):
    lune run scripts/map/nacara-export.luau /tmp/nacara.json fase1 x v2
    python3 scripts/map/nacara_v2_preview.py /tmp/nacara.json docs/mar/nacara-v2 [--muestras 24] [--ancho 1280]
Salen vista-1…4.jpg (cámara del móvil, a la altura del jugador), vista-general.jpg y comparacion.jpg (el mapa del
dueño al lado de la vista general).
"""
import argparse
import json
import math
import os
import random

import bpy
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
REF = os.path.join(ROOT, "docs", "mar", "referencia", "ciudad-marina-dueno.png")


def rb(x, y, z):
    """Roblox (x, y, z) -> Blender (x, -z, y)."""
    return Vector((x, -z, y))


def lin1(v):
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def lin(c, scale=1.0):
    """sRGB (0..1 o 0..255) -> lineal."""
    k = 255.0 if max(c[:3]) > 1.0 else 1.0
    return [lin1(v / k) * scale for v in c[:3]]


_mats = {}


def material(key, color, rough=0.6, emission=0.0, alpha=1.0, glass=False):
    name = f"{key}_{tuple(round(v, 3) for v in color)}_{emission}_{alpha}"
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*lin(color), 1)
    b.inputs["Roughness"].default_value = rough
    if emission > 0:
        b.inputs["Emission Color"].default_value = (*lin(color), 1)
        b.inputs["Emission Strength"].default_value = emission
    if glass:
        b.inputs["Transmission Weight"].default_value = 0.9
        b.inputs["Roughness"].default_value = 0.08
        b.inputs["IOR"].default_value = 1.05
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
        m.blend_method = "BLEND"
    _mats[name] = m
    return m


def part_material(p):
    mat = p["Material"]
    c = p["Color"]
    t = p.get("Transparency", 0) or 0
    if mat == "Neon":
        return material("neon", c, emission=6.0, alpha=max(0.15, 1 - t))
    if mat == "Glass":
        return material("glass", c, glass=True, alpha=max(0.12, 1 - t))
    rough = {"SmoothPlastic": 0.35, "Plastic": 0.5, "Fabric": 0.9, "Salt": 0.95, "Rock": 0.9}.get(mat, 0.6)
    return material(mat, c, rough=rough, alpha=max(0.1, 1 - t))


_proto = {}


def proto(kind):
    if kind in _proto:
        return _proto[kind]
    if kind == "Block":
        bpy.ops.mesh.primitive_cube_add(size=1)
    elif kind == "Cylinder":
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.5, depth=1)
        o = bpy.context.active_object
        o.data.transform(Matrix.Rotation(math.radians(90), 4, "Y"))  # eje X (como Roblox)
    elif kind in ("Ball", "Ellipsoid"):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=0.5)
    elif kind == "Wedge":
        bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.active_object
        # cuña de Roblox: alta atrás (+Z de Roblox = −Y de Blender), la rampa baja hacia delante
        for v in o.data.vertices:
            if v.co.z > 0 and v.co.y > 0:
                v.co.z = -0.5
    o = bpy.context.active_object
    for poly in o.data.polygons:
        poly.use_smooth = kind != "Block" and kind != "Wedge"
    me = o.data
    me.materials.append(material("base", (200, 200, 200)))
    bpy.data.objects.remove(o)
    _proto[kind] = me
    return me


def add_part(p, coll):
    shape = p["Shape"]
    if shape == "Mesh":
        shape = "Block"
    me = proto(shape)
    ob = bpy.data.objects.new("p", me)
    coll.objects.link(ob)
    x, y, z = p["Pos"]
    r = p["Rot"]
    sx, sy, sz = p["Size"]
    if shape == "Ball":
        s = min(sx, sy, sz)
        sx = sy = sz = s
    C = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))  # Roblox -> Blender
    R = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8])))
    S = Matrix.Diagonal((sx, sy, sz))
    m3 = C @ R @ S @ C.inverted()
    m4 = m3.to_4x4()
    m4.translation = rb(x, y, z)
    ob.matrix_world = m4
    ob.material_slots[0].link = "OBJECT"
    ob.material_slots[0].material = part_material(p)
    return ob


# ---------------------------------------------------------------------------
# Lo que aún no existe: islas y masas aproximadas
# ---------------------------------------------------------------------------
NACRE = (236, 230, 244)
NACRE_B = (206, 232, 244)
PINK = (246, 214, 230)
CYAN = (110, 236, 255)
GOLD = (255, 214, 140)
VIOLET = (190, 140, 255)
ROCK = (70, 82, 104)
CORAL = [(255, 128, 160), (255, 176, 96), (184, 128, 255), (120, 226, 255), (140, 240, 180), (255, 220, 120)]


class Kit:
    def __init__(self, coll, center, floor):
        self.coll = coll
        self.cx, self.cz = center[0], center[2]
        self.floor = floor

    def w(self, x, z, y=0.0):
        return (self.cx + x, self.floor + y, self.cz + z)

    def cyl(self, x, z, y0, h, r, color, emission=0.0, alpha=1.0, glass=False, verts=24):
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=rb(*self.w(x, z, y0 + h / 2)))
        o = bpy.context.active_object
        o.data.materials.append(material("m", color, emission=emission, alpha=alpha, glass=glass))
        self._move(o)
        return o

    def cone(self, x, z, y0, h, r, color, emission=0.0):
        bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=r, radius2=0, depth=h, location=rb(*self.w(x, z, y0 + h / 2)))
        o = bpy.context.active_object
        o.data.materials.append(material("m", color, emission=emission))
        self._move(o)
        return o

    def dome(self, x, z, y0, r, h, color, emission=0.0, alpha=1.0, glass=False):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1, location=rb(*self.w(x, z, y0)))
        o = bpy.context.active_object
        o.scale = (r, r, h)
        for p_ in o.data.polygons:
            p_.use_smooth = True
        o.data.materials.append(material("m", color, emission=emission, alpha=alpha, glass=glass))
        self._move(o)
        return o

    def box(self, x, z, y0, sx, sy, sz, color, yaw=0.0, emission=0.0):
        bpy.ops.mesh.primitive_cube_add(size=1, location=rb(*self.w(x, z, y0 + sy / 2)))
        o = bpy.context.active_object
        o.scale = (sx, sz, sy)
        o.rotation_euler = (0, 0, yaw)
        o.data.materials.append(material("m", color, emission=emission))
        self._move(o)
        return o

    def _move(self, o):
        for c in o.users_collection:
            c.objects.unlink(o)
        self.coll.objects.link(o)


def island(k, d, rnd):
    """Isla de roca con borde irregular y coral por encima del borde."""
    r = d["R"]
    top = 4.0
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=r, depth=18, location=rb(*k.w(d["X"], d["Z"], top - 9)))
    o = bpy.context.active_object
    for v in o.data.vertices:
        a = math.atan2(v.co.y, v.co.x)
        wob = 1 + 0.08 * math.sin(a * 5 + d["X"]) + 0.05 * math.sin(a * 11 + d["Z"])
        if v.co.z < 0:
            wob *= 1.12
        v.co.x *= wob
        v.co.y *= wob
    o.data.materials.append(material("roca", ROCK, rough=0.95))
    k._move(o)
    # la cara de arriba: grano claro
    k.cyl(d["X"], d["Z"], top - 0.4, 0.6, r * 0.93, (226, 220, 206))
    # coral al borde
    for i in range(int(r * 0.5)):
        a = rnd.uniform(0, math.tau)
        rr = r * rnd.uniform(0.86, 1.02)
        x, z = d["X"] + math.cos(a) * rr, d["Z"] + math.sin(a) * rr
        c = rnd.choice(CORAL)
        h = rnd.uniform(2.0, 5.5)
        if rnd.random() < 0.5:
            k.cone(x, z, top - 0.5, h, rnd.uniform(0.8, 1.6), c, emission=1.2 if rnd.random() < 0.4 else 0.0)
        else:
            k.dome(x, z, top, rnd.uniform(1.2, 2.4), rnd.uniform(0.8, 1.6), c, emission=0.8 if rnd.random() < 0.3 else 0.0)


def massing(k, d, rnd):
    """Una masa APROXIMADA del barrio (aún no existe), como en el mapa del dueño."""
    X, Z, R, i = d["X"], d["Z"], d["R"], d["Id"]
    y = 4.0
    if i == "Residencias":
        for n in range(8):
            a = n / 8 * math.tau
            x, z = X + math.cos(a) * R * 0.6, Z + math.sin(a) * R * 0.6
            k.cyl(x, z, y, 5, 6, NACRE_B)
            k.dome(x, z, y + 5, 6.2, 5, (150, 220, 255), alpha=0.55, glass=True)
            k.box(x, z + 6, y, 2.6, 4, 0.4, GOLD, emission=3.0)
        for x, z, h in ((X - 8, Z - 4, 34), (X + 9, Z + 6, 28)):
            k.cyl(x, z, y, h, 4.5, PINK)
            k.cyl(x, z, y + h, 2, 5.2, CYAN, emission=4)
            k.cone(x, z, y + h + 2, 8, 3, NACRE)
    elif i == "Universidad":
        k.cyl(X, Z, y, 12, 26, NACRE)
        k.cyl(X, Z, y + 12, 1, 27, CYAN, emission=4)
        k.dome(X, Z, y + 12, 22, 16, (140, 200, 255), alpha=0.5, glass=True)
        for n in range(12):
            a = n / 12 * math.tau
            k.cyl(X + math.cos(a) * 34, Z + math.sin(a) * 34, y, 10, 1.2, NACRE_B)
        k.cyl(X, Z, y + 28, 10, 2, GOLD, emission=2)
    elif i == "Hospital":
        k.cyl(X, Z, y, 14, 18, (240, 246, 250))
        k.dome(X, Z, y + 14, 16, 10, (160, 240, 230), alpha=0.6, glass=True)
        k.cyl(X + 20, Z - 6, y, 22, 6, (240, 246, 250))
        k.box(X, Z + 18.2, y + 8, 6, 2, 0.4, (80, 230, 200), emission=4)  # signo de concha verde (no la cruz roja)
        k.box(X, Z + 18.2, y + 6, 2, 6, 0.4, (80, 230, 200), emission=4)
    elif i == "Mercado":
        for n in range(16):
            a = rnd.uniform(0, math.tau)
            rr = rnd.uniform(6, R * 0.8)
            x, z = X + math.cos(a) * rr, Z + math.sin(a) * rr
            c = rnd.choice(CORAL)
            k.box(x, z, y, 6, 4, 5, NACRE, yaw=a)
            k.box(x, z, y + 4, 7, 0.6, 6, c, yaw=a)
            k.box(x, z, y + 4.6, 0.5, 0.5, 0.5, GOLD, emission=6)
    elif i == "Comercios":
        k.cyl(X, Z, y, 9, 24, PINK)
        k.cyl(X, Z, y + 9, 1, 25, (255, 170, 230), emission=4)
        k.dome(X, Z, y + 9, 20, 12, (210, 160, 255), alpha=0.55, glass=True)
        for n in range(6):
            a = n / 6 * math.tau
            k.box(X + math.cos(a) * 32, Z + math.sin(a) * 32, y, 8, 6, 6, rnd.choice(CORAL), yaw=a)
    elif i == "Biblioteca":
        for s, h in enumerate((8, 7, 6)):
            k.cyl(X, Z, y + s * 7, h, 26 - s * 6, NACRE_B if s % 2 == 0 else NACRE)
            k.cyl(X, Z, y + s * 7 + h - 0.6, 0.6, 26.4 - s * 6, GOLD, emission=3)
        k.dome(X, Z, y + 21, 8, 7, (160, 210, 255), alpha=0.55, glass=True)
    elif i == "Cueva":
        k.dome(X, Z, y, 30, 22, (60, 50, 90))
        k.dome(X, Z + 22, y + 6, 12, 10, (20, 16, 40))
        k.dome(X, Z + 24, y + 4, 4, 4, (220, 180, 255), emission=8)
        for n in range(10):
            a = rnd.uniform(0, math.tau)
            k.cone(X + math.cos(a) * 30, Z + math.sin(a) * 30, y, rnd.uniform(4, 9), 1.5, VIOLET, emission=2.5)
    elif i == "Templo":
        k.cyl(X, Z, y, 16, 22, NACRE)
        k.dome(X, Z, y + 16, 20, 14, (255, 220, 170), emission=0.4)
        for n in range(6):
            a = n / 6 * math.tau
            x, z = X + math.cos(a) * 26, Z + math.sin(a) * 26
            k.cyl(x, z, y, 24, 2.2, NACRE_B)
            k.cone(x, z, y + 24, 9, 2.2, GOLD, emission=1.5)
        k.box(X, Z + 22.5, y, 8, 12, 0.6, GOLD, emission=3)
    elif i == "Santuario":
        k.cyl(X, Z, y, 2, 22, NACRE)
        k.cyl(X, Z, y + 2, 30, 2.2, CYAN, emission=6)
        for s in (-1, 1):
            k.cyl(X + s * 4, Z, y + 26, 6, 0.8, CYAN, emission=6)
        for n in range(8):
            a = n / 8 * math.tau
            k.cyl(X + math.cos(a) * 20, Z + math.sin(a) * 20, y, 14, 1.4, NACRE_B)
            k.dome(X + math.cos(a) * 20, Z + math.sin(a) * 20, y + 14, 1.6, 1.6, CYAN, emission=6)
    elif i == "Torre":
        k.cyl(X, Z, y, 6, 16, NACRE)
        k.cyl(X, Z, y + 6, 44, 5, NACRE_B)
        k.dome(X, Z, y + 52, 9, 7, (150, 225, 255), alpha=0.5, glass=True)
        k.cyl(X, Z, y + 50, 1, 9.5, CYAN, emission=5)
        k.dome(X + 20, Z + 4, y + 6, 10, 9, (160, 220, 255), alpha=0.55, glass=True)
    elif i == "Entrenamiento":
        for n, (dx, dz, r) in enumerate(((0, 0, 16), (24, 14, 10), (-22, 16, 9))):
            k.cyl(X + dx, Z + dz, y, 1.6, r, NACRE)
            k.cyl(X + dx, Z + dz, y + 1.6, 0.4, r + 0.4, CYAN, emission=5)
            k.cyl(X + dx, Z + dz, y + 0.8, 1.0, r * 0.85, (60, 160, 220), alpha=0.6)
        for n in range(5):
            k.cyl(X - 30 + n * 6, Z - 26, y, 8, 0.6, GOLD, emission=2)
    elif i == "Acuario":
        k.cyl(X, Z, y, 3, 44, NACRE)
        k.cyl(X, Z, y + 3, 0.8, 44.5, CYAN, emission=4)
        k.dome(X, Z, y + 3, 42, 30, (150, 220, 255), alpha=0.35, glass=True)
        for n in range(9):
            a = rnd.uniform(0, math.tau)
            rr = rnd.uniform(5, 30)
            k.dome(X + math.cos(a) * rr, Z + math.sin(a) * rr, y + rnd.uniform(8, 24), rnd.uniform(2.5, 5), 1.2, rnd.choice(CORAL), emission=0.6)
    elif i == "Puerto":
        for n in range(4):
            k.box(X - 24 + n * 14, Z + 6, y, 3, 1.2, 46, NACRE_B)
            k.box(X - 24 + n * 14, Z + 6, y + 1.2, 0.6, 0.6, 0.6, GOLD, emission=6)
        for n, dx in enumerate((-17, 11)):
            # submarino (casco, torreta y ventanas de luz)
            bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1, location=rb(*k.w(X + dx, Z + 8, y + 7)))
            o = bpy.context.active_object
            o.scale = (4, 13, 4)
            for p_ in o.data.polygons:
                p_.use_smooth = True
            o.data.materials.append(material("m", (255, 196, 90) if n == 0 else (120, 200, 255)))
            k._move(o)
            k.cyl(X + dx, Z + 5, y + 10, 4, 2.2, NACRE)
            for w in (-6, 0, 6):
                k.dome(X + dx + 4, Z + 8 + w, y + 7.5, 0.9, 0.9, GOLD, emission=6)
        k.cyl(X + 20, Z - 22, y, 10, 10, NACRE)
        k.dome(X + 20, Z - 22, y + 10, 10, 6, (150, 225, 255), alpha=0.55, glass=True)
    elif i == "Jardines":
        for n in range(60):
            a = rnd.uniform(0, math.tau)
            rr = R * math.sqrt(rnd.random()) * 0.9
            x, z = X + math.cos(a) * rr, Z + math.sin(a) * rr
            c = rnd.choice(CORAL)
            if rnd.random() < 0.55:
                k.cone(x, z, y, rnd.uniform(3, 9), rnd.uniform(1, 2.4), c, emission=1.5 if rnd.random() < 0.4 else 0)
            else:
                k.dome(x, z, y, rnd.uniform(1.5, 3.5), rnd.uniform(1, 2.5), c, emission=0.8 if rnd.random() < 0.3 else 0)
        k.cyl(X, Z, y, 6, 8, NACRE_B)
        k.dome(X, Z, y + 6, 8, 5, (150, 240, 200), alpha=0.6, glass=True)


def link(k, a, b, kind):
    ax, az, bx, bz = a["X"], a["Z"], b["X"], b["Z"]
    dx, dz = bx - ax, bz - az
    L = math.hypot(dx, dz)
    ux, uz = dx / L, dz / L
    x0, z0 = ax + ux * a["R"] * 0.85, az + uz * a["R"] * 0.85
    x1, z1 = bx - ux * b["R"] * 0.85, bz - uz * b["R"] * 0.85
    L2 = math.hypot(x1 - x0, z1 - z0)
    mx, mz = (x0 + x1) / 2, (z0 + z1) / 2
    yaw = math.atan2(-(z1 - z0), x1 - x0)
    if kind == "Walk":
        k.box(mx, mz, 3.0, L2, 1.0, 5, (214, 206, 186), yaw=yaw)
        k.box(mx, mz, 4.0, L2, 0.25, 0.3, CYAN, yaw=yaw, emission=3)
    else:
        k.box(mx, mz, 3.0, L2, 0.6, 5, NACRE, yaw=yaw)
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=5.5, depth=L2, location=rb(*k.w(mx, mz, 7.6)))
        o = bpy.context.active_object
        o.rotation_euler = (0, math.radians(90), yaw)
        o.data.materials.append(material("tubo", (150, 220, 255), glass=True, alpha=0.3))
        k._move(o)
        for s in (-1, 1):
            k.box(mx - uz * s * 3.6, mz + ux * s * 3.6, 11.4, L2, 0.35, 0.35, CYAN, yaw=yaw, emission=4)


# ---------------------------------------------------------------------------
FRAMES = [
    # Id, título, cámara (coordenadas de la plaza: x, altura sobre el suelo, z), mira a
    ("1", "Plaza Central → Palacio Real (por el tubo de cristal)", (-4, 7, -28), (5, 18, -150)),
    ("2", "Llegando desde el sur: Plaza Central, Palacio y Torre de Observación", (40, 10, 90), (5, 20, -150)),
    ("3", "Desde el Mercado Submarino hacia el Palacio", (-300, 12, -90), (5, 18, -150)),
    ("4", "Puerto de Sirenas y Jardines de Coral hacia el centro", (330, 12, 210), (60, 16, -60)),
]


def scene_setup(look, args, mist_depth, overview=False):
    scene = bpy.context.scene
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (*lin(look["Ambient"]), 1)
    bg.inputs["Strength"].default_value = 0.9
    scene.world = world
    sun = bpy.data.lights.new("sol", "SUN")
    sun.energy = 3.2 * math.exp(-38 / 22) * (1.6 if overview else 1.0)
    sun.color = lin((235, 248, 255))
    sun.angle = math.radians(10)
    so = bpy.data.objects.new("sol", sun)
    so.rotation_euler = (math.radians(20), math.radians(10), math.radians(30))
    scene.collection.objects.link(so)
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.muestras
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.cycles.transparent_max_bounces = 8
    scene.render.resolution_x = args.ancho
    scene.render.resolution_y = args.ancho * 9 // 16
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.exposure = float(look.get("Exposure", 0)) + (0.2 if overview else 0.35)
    vl = scene.view_layers[0]
    vl.use_pass_mist = True
    world.mist_settings.start = 20.0 if not overview else 300.0
    world.mist_settings.depth = mist_depth
    world.mist_settings.falloff = "LINEAR"
    scene.use_nodes = True
    nt = scene.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    rl = nt.nodes.new("CompositorNodeRLayers")
    mix = nt.nodes.new("CompositorNodeMixRGB")
    mix.inputs[2].default_value = (*lin(look["Fog"]), 1)
    pw = nt.nodes.new("CompositorNodeMath")
    pw.operation = "POWER"
    pw.inputs[1].default_value = 0.8
    nt.links.new(rl.outputs["Mist"], pw.inputs[0])
    nt.links.new(pw.outputs[0], mix.inputs[0])
    nt.links.new(rl.outputs["Image"], mix.inputs[1])
    tint = nt.nodes.new("CompositorNodeMixRGB")
    tint.blend_type = "MULTIPLY"
    tint.inputs[0].default_value = 0.35
    tint.inputs[2].default_value = (*lin(look["Tint"]), 1)
    nt.links.new(mix.outputs[0], tint.inputs[1])
    comp = nt.nodes.new("CompositorNodeComposite")
    nt.links.new(tint.outputs[0], comp.inputs[0])
    return scene


def camera(scene, data, cam, tgt, fov=70):
    cx, cz = data["Center"][0], data["Center"][2]
    fy = data["FloorY"]
    cd = bpy.data.cameras.new("cam")
    cd.sensor_fit = "VERTICAL"
    cd.angle_y = math.radians(fov)
    cd.clip_end = 3000
    co = bpy.data.objects.new("cam", cd)
    scene.collection.objects.link(co)
    co.location = rb(cx + cam[0], fy + cam[1], cz + cam[2])
    d = rb(cx + tgt[0], fy + tgt[1], cz + tgt[2]) - co.location
    co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    scene.camera = co
    return co


def build_world(data, args):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()
    _proto.clear()
    coll = bpy.context.scene.collection
    cx, cy, cz = data["Center"]
    fy = data["FloorY"]
    # el fondo (arena clara de la llanura)
    bpy.ops.mesh.primitive_plane_add(size=4000, location=rb(cx, fy - 0.6, cz))
    bpy.context.active_object.data.materials.append(material("fondo", (196, 188, 168), rough=1.0))
    k = Kit(coll, data["Center"], fy)
    rnd = random.Random(7)
    v2 = data["V2"]
    by = {d["Id"]: d for d in v2["List"]}
    for d in v2["List"]:
        if d["Id"] == "Plaza":
            continue
        island(k, d, rnd)
        if not d["Built"]:
            massing(k, d, rnd)
    for l in v2["Links"]:
        a, b = by[l[0] if isinstance(l, list) else l["1"]], by[l[1] if isinstance(l, list) else l["2"]]
        kind = l[2] if isinstance(l, list) and len(l) > 2 else (l.get("Kind") if isinstance(l, dict) else "Walk")
        if {a["Id"], b["Id"]} == {"Plaza", "Palacio"}:
            continue  # (ese tubo es de verdad: está en las piezas)
        link(k, a, b, kind)
    # las piezas de verdad (fase 0, fase 1, decorado, prototipo v2)
    for p in data["Parts"]:
        if (p["Pos"][0] - cx) ** 2 + (p["Pos"][2] - cz) ** 2 > 700 ** 2:
            continue  # (las boyas lejanas)
        add_part(p, coll)
    for li in data["Lights"]:
        L = bpy.data.lights.new("l", "POINT")
        L.energy = li["Brightness"] * li["Range"] * 120
        L.color = lin(li["Color"])
        L.shadow_soft_size = 1
        o = bpy.data.objects.new("l", L)
        o.location = rb(*li["Pos"])
        coll.objects.link(o)
    return k


def label(path, text, tags=None):
    im = Image.open(path).convert("RGB")
    W, H = im.size
    d = ImageDraw.Draw(im, "RGBA")
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", max(14, W // 60))
        small = ImageFont.truetype("DejaVuSans.ttf", max(11, W // 95))
    except OSError:
        font = small = ImageFont.load_default()
    placed = []
    for (tx, ty, name, built) in sorted(tags or [], key=lambda t: -t[1]):
        x, y = int(tx * W), int((1 - ty) * H)
        if not (0 < x < W and 0 < y < H):
            continue
        t = name + ("" if built else " (aprox.)")
        bb = d.textbbox((0, 0), t, font=small)
        w_, h_ = bb[2] - bb[0], bb[3] - bb[1]
        for _ in range(12):
            box = (x - w_ // 2 - 8, y - h_ - 10, x + w_ // 2 + 8, y)
            if not any(not (box[2] < b[0] or box[0] > b[2] or box[3] < b[1] or box[1] > b[3]) for b in placed):
                break
            y += h_ + 8
        placed.append((x - w_ // 2 - 8, y - h_ - 10, x + w_ // 2 + 8, y))
        d.rounded_rectangle((x - w_ // 2 - 8, y - h_ - 10, x + w_ // 2 + 8, y), radius=8,
                            fill=(8, 24, 48, 200), outline=(120, 230, 255, 230) if built else (255, 255, 255, 120), width=2)
        d.text((x - w_ // 2, y - h_ - 6), t, fill=(255, 255, 255), font=small)
    d.rectangle((0, 0, W, int(H * 0.065)), fill=(0, 0, 0, 150))
    d.text((12, int(H * 0.012)), "VISTA PREVIA, NO ES ROBLOX", fill=(255, 220, 120), font=font)
    d.rectangle((0, H - int(H * 0.055), W, H), fill=(0, 0, 0, 150))
    d.text((12, H - int(H * 0.048)), text, fill=(255, 255, 255), font=small)
    im.save(path, quality=90)


def render(scene, out):
    scene.render.filepath = out
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 90
    bpy.ops.render.render(write_still=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("json")
    ap.add_argument("outdir")
    ap.add_argument("--muestras", type=int, default=24)
    ap.add_argument("--ancho", type=int, default=1280)
    ap.add_argument("--solo", default="")
    args = ap.parse_args()
    with open(args.json, encoding="utf-8") as f:
        data = json.load(f)
    os.makedirs(args.outdir, exist_ok=True)
    look = data["Day"]
    only = set(args.solo.split(",")) if args.solo else None
    for fid, title, cam, tgt in FRAMES:
        if only and fid not in only:
            continue
        build_world(data, args)
        scene = scene_setup(look, args, float(look.get("Visibility", 216)))
        camera(scene, data, cam, tgt)
        out = os.path.join(args.outdir, f"vista-{fid}.jpg")
        render(scene, out)
        label(out, f"Nácara v2 · vista {fid}: {title} · cámara del móvil (70°) a la altura del jugador · 38 m · día")
    if not only or "general" in only:
        build_world(data, args)
        scene = scene_setup(look, args, 900.0, overview=True)
        co = camera(scene, data, (30, 280, 430), (30, 0, -50), fov=55)
        out = os.path.join(args.outdir, "vista-general.jpg")
        render(scene, out)
        cx, cz, fy = data["Center"][0], data["Center"][2], data["FloorY"]
        tags = []
        for d in data["V2"]["List"]:
            v = world_to_camera_view(scene, co, rb(cx + d["X"], fy + 30, cz + d["Z"]))
            tags.append((v.x, v.y, d["Name"], d["Built"]))
        label(out, "Nácara v2 · vista general desde el sur (sin el agua de encima) · borde azul = piezas de verdad (fase 0, fase 1 y prototipo); «aprox.» = masa aproximada, aún no existe", tags)
        # la hoja de comparación: el mapa del dueño al lado de la vista general
        ref = Image.open(REF).convert("RGB")
        gen = Image.open(out).convert("RGB")
        h = 720
        ref = ref.resize((int(ref.width * h / ref.height), h))
        gen = gen.resize((int(gen.width * h / gen.height), h))
        sheet = Image.new("RGB", (ref.width + gen.width + 30, h + 70), (10, 18, 32))
        sheet.paste(ref, (10, 60))
        sheet.paste(gen, (ref.width + 20, 60))
        d = ImageDraw.Draw(sheet)
        try:
            font = ImageFont.truetype("DejaVuSans-Bold.ttf", 26)
        except OSError:
            font = ImageFont.load_default()
        d.text((14, 16), "El mapa del dueño (referencia, hecho con IA)", fill=(255, 255, 255), font=font)
        d.text((ref.width + 24, 16), "Nácara v2 · VISTA PREVIA, NO ES ROBLOX", fill=(255, 220, 120), font=font)
        sheet.save(os.path.join(args.outdir, "comparacion.jpg"), quality=88)


if __name__ == "__main__":
    main()
