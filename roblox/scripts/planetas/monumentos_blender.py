#!/usr/bin/env python3
"""Monumentos de las ciudades de los planetas con Blender (mallas «estrella», hoja de estética del dueño).

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python scripts/planetas/monumentos_blender.py -- [--solo Kind] [--no-render]

Hace, para cada monumento (Landmark.Kind de shared/Cosmos/MetroStyles):
  * assets/planetas/<Kind>.fbx  con VARIAS mallas, una por material: <Kind>_Cuerpo, _Cristal, _Luz, _Metal,
    _Roca, _Agua, _Hoja, _Tronco (cada una se convierte en una MeshPart; World/PlanetMetroMeshes les pone el
    material y el color del planeta). Coordenadas de Roblox en studs; el frente mira a -Z (hacia el barrio).
  * assets/planetas/manifest.json y src/shared/Cosmos/MonumentoMalla.luau (centro, tamaño y triángulos)
  * docs/planetas/monumentos/<Kind>.jpg  (vista previa renderizada, para revisar antes de subir)
Después: bash scripts/upload-planetas.sh (escribe src/shared/Cosmos/MetroAssetIds.luau).

Cada malla, como mucho ~19 500 triángulos (el tope de Roblox es 20 000): si se pasa, se simplifica.
"""
import json
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "assets", "planetas")
DOCS = os.path.join(ROOT, "docs", "planetas", "monumentos")
MAX_TRIS = 19500

G = {}  # grupo -> [objetos]

# Colores de la vista previa (en el juego los pone el planeta)
PREVIEW = {
    "Cuerpo": ((0.86, 0.9, 0.95), 0.0, 0.45, 0.0),
    "Cristal": ((0.35, 0.65, 0.9), 0.2, 0.05, 0.0),
    "Luz": ((0.3, 0.85, 1.0), 0.0, 0.3, 6.0),
    "Metal": ((0.35, 0.4, 0.48), 0.9, 0.35, 0.0),
    "Roca": ((0.45, 0.42, 0.4), 0.0, 0.9, 0.0),
    "Agua": ((0.6, 0.85, 1.0), 0.0, 0.05, 0.4),
    "Hoja": ((0.18, 0.45, 0.2), 0.0, 0.8, 0.0),
    "Tronco": ((0.35, 0.25, 0.17), 0.0, 0.85, 0.0),
}
TINT = {}  # por monumento: colores de vista previa propios


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    G.clear()


def _keep(o, group):
    G.setdefault(group, []).append(o)
    return o


def _bevel(o, width, segments=2):
    if width <= 0:
        return
    m = o.modifiers.new("bisel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(35)


def box(c, size, group, rot=(0, 0, 0), bevel=0.0):
    """c y size en coordenadas de Blender (Z arriba). Frente del monumento: -Y."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=c, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    _bevel(o, bevel)
    return _keep(o, group)


def cyl(c, r, h, group, n=24, rot=(0, 0, 0), r2=None, bevel=0.0):
    """Cilindro (o cono si r2) con la BASE en c."""
    rx, ry, rz = rot
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=n, radius=r, depth=h, location=(0, 0, 0))
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=n, radius1=r, radius2=r2, depth=h, location=(0, 0, 0))
    o = bpy.context.active_object
    o.location = (0, 0, h / 2)
    bpy.ops.object.transform_apply(location=True)
    o.rotation_euler = (rx, ry, rz)
    o.location = c
    _bevel(o, bevel)
    return _keep(o, group)


def sphere(c, r, group, seg=32, rings=16, hemi=False, squash=1.0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=r, location=c)
    o = bpy.context.active_object
    if squash != 1.0:
        o.scale = (1, 1, squash)
        bpy.ops.object.transform_apply(scale=True)
    if hemi:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        cut = [v for v in bm.verts if v.co.z < -0.01]
        bmesh.ops.delete(bm, geom=cut, context="VERTS")
        bm.to_mesh(o.data)
        bm.free()
    return _keep(o, group)


def torus(c, R, r, group, n=64, m=10, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=n, minor_segments=m, location=c, rotation=rot)
    return _keep(bpy.context.active_object, group)


def ring_of(n, radius, fn, phase=0.0):
    for i in range(n):
        a = phase + i / n * math.tau
        fn(i, a, math.cos(a) * radius, math.sin(a) * radius)


# ---------------------------------------------------------------------------
# Piezas que se repiten
# ---------------------------------------------------------------------------
def tier_tower(x, y, z0, radius, height, tiers, n=8, glow=True, glass=True, spire=True, fins=True, body="Cuerpo"):
    """Torre de ciencia ficción: pisos octogonales que se estrechan, con aletas, ventanales y juntas de luz."""
    z = z0
    for i in range(tiers):
        k = 1 - i / (tiers + 1)
        r = radius * k
        h = height / tiers
        cyl((x, y, z), r, h * 0.92, body, n=n, bevel=min(0.6, r * 0.08))
        if glass:
            cyl((x, y, z + h * 0.25), r * 1.015, h * 0.4, "Cristal", n=n)
        if glow:
            cyl((x, y, z + h * 0.9), r * 1.04, h * 0.06, "Luz", n=n)
        if fins:
            # aletas en las aristas: una de cada dos con su junta de luz
            ring_of(n, r * 1.0, lambda j, a, cx, cy: box((x + cx, y + cy, z + h * 0.46), (1.0, 1.0, h * 0.92), "Luz" if (glow and j % 2 == 0) else "Metal", rot=(0, 0, a)), phase=math.pi / n)
        z += h
    if spire:
        cyl((x, y, z), radius * 0.28, height * 0.22, body, n=n, r2=radius * 0.04)
        cyl((x, y, z + height * 0.22), radius * 0.05, height * 0.12, "Luz", n=8, r2=0.05)
    return z


def dome(x, y, z, r, ribs=12, body="Cuerpo"):
    sphere((x, y, z), r, "Cristal", hemi=True)
    ring_of(ribs, 0, lambda j, a, cx, cy: None)
    for j in range(ribs):
        a = j / ribs * math.tau
        # nervios: arcos aproximados por tramos
        for s in range(6):
            t0, t1 = s / 6 * math.pi / 2, (s + 1) / 6 * math.pi / 2
            p0 = Vector((math.cos(a) * math.cos(t0) * r, math.sin(a) * math.cos(t0) * r, math.sin(t0) * r))
            p1 = Vector((math.cos(a) * math.cos(t1) * r, math.sin(a) * math.cos(t1) * r, math.sin(t1) * r))
            mid = (p0 + p1) / 2
            d = p1 - p0
            o = box((x + mid.x, y + mid.y, z + mid.z), (0.7, 0.7, d.length + 0.3), "Metal")
            o.rotation_mode = "QUATERNION"
            o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    cyl((x, y, z - 0.6), r * 1.04, 1.2, body, n=32)
    cyl((x, y, z + 0.6), r * 1.06, 0.5, "Luz", n=32)


def bridge(p0, p1, z, width, rail=True):
    a, b = Vector((p0[0], p0[1], z)), Vector((p1[0], p1[1], z))
    d = b - a
    mid = (a + b) / 2
    ang = math.atan2(d.y, d.x)
    L = d.length
    box((mid.x, mid.y, mid.z), (L, width, 1.6), "Metal", rot=(0, 0, ang), bevel=0.2)
    box((mid.x, mid.y, mid.z - 1.1), (L, width * 0.6, 0.4), "Luz", rot=(0, 0, ang))
    if rail:
        for s in (-1, 1):
            ox, oy = -math.sin(ang) * s * width / 2, math.cos(ang) * s * width / 2
            box((mid.x + ox, mid.y + oy, mid.z + 1.6), (L, 0.3, 1.6), "Cristal", rot=(0, 0, ang))
            box((mid.x + ox, mid.y + oy, mid.z + 2.5), (L, 0.4, 0.3), "Metal", rot=(0, 0, ang))


def waterfall(x, y, z, width, height, group="Agua"):
    for i in range(4):
        box((x + (i - 1.5) * width * 0.22, y - i * 0.25, z + height / 2), (width * 0.2, 0.6 + i * 0.15, height), group)
    cyl((x, y - width * 0.4, z), width * 0.9, 0.6, group, n=24)


def terrace(r, h, steps=3):
    for i in range(steps):
        cyl((0, 0, -h + i * h / steps), r * (1 - i * 0.08), h / steps, "Cuerpo", n=48, bevel=0.4)
        cyl((0, 0, -h + (i + 1) * h / steps - 0.15), r * (1 - i * 0.08) + 0.2, 0.3, "Luz", n=48)
    # escalinata delantera
    for s in range(8):
        box((0, -r * 0.92 - s * 1.4, -h + (8 - s) * h / 9 - h / 18), (22, 1.4, h / 9), "Cuerpo")


# ---------------------------------------------------------------------------
# Los monumentos
# ---------------------------------------------------------------------------
def palacio():
    """Palacio de Hielo (Nivalis): aguja central de cristal, cuatro torres, anillo de puentes y cascada helada."""
    terrace(68, 6)
    tier_tower(0, 0, 0, 18, 200, 8, n=8)
    # racimos de cristal de hielo alrededor de la aguja y en la explanada
    for j in range(18):
        a = j / 18 * math.tau
        rr = 21 + (j % 3) * 3
        cyl((math.cos(a) * rr, math.sin(a) * rr, 0), 2.6 + (j % 2), 16 + (j % 4) * 7, "Cristal", n=6, r2=0.2, rot=(math.radians(12) * math.sin(a), math.radians(12) * math.cos(a) * -1, 0))
    for j in range(10):
        a = j / 10 * math.tau + 0.3
        rr = 58
        for k in range(3):
            cyl((math.cos(a) * rr + k * 2, math.sin(a) * rr - k * 1.5, 0), 1.8 - k * 0.4, 9 - k * 2, "Cristal", n=6, r2=0.1, rot=(0.25 * (k - 1), 0.2, a))
    towers = []
    for j in range(4):
        a = j * math.tau / 4 + math.pi / 4
        tx, ty = math.cos(a) * 42, math.sin(a) * 42
        towers.append((tx, ty))
        tier_tower(tx, ty, 0, 9, 120 + j * 8, 5, n=8)
        dome(tx, ty, 28, 9.5)
    for j in range(4):
        bridge(towers[j], towers[(j + 1) % 4], 64, 5)
        bridge(towers[j], (0, 0), 92, 4)
    # risco y cascada helada al fondo
    box((0, 66, 22), (60, 16, 50), "Roca", bevel=1.5)
    for i in range(6):
        box(((i - 2.5) * 10, 60 + (i % 2) * 3, 46 + (i % 3) * 3), (9, 9, 6), "Roca", rot=(0.2 * i, 0.1, 0.3 * i), bevel=1)
    waterfall(0, 57.5, 0, 18, 46)
    # torres de luz pequeñas alrededor
    ring_of(12, 60, lambda j, a, cx, cy: (cyl((cx, cy, 0), 1.2, 14, "Metal", n=8), sphere((cx, cy, 15), 1.4, "Luz", seg=12, rings=6)), phase=0.13)


def puerta():
    """Puerta del Sol (Siroco): dos pilonos de arenisca con agujas, arco, anillo de luz y la catedral detrás."""
    terrace(68, 4, steps=2)
    for s in (-1, 1):
        x = s * 26
        box((x, 0, 55), (20, 22, 110), "Cuerpo", bevel=1.2)
        for i in range(6):
            box((x, -11.4, 12 + i * 17), (16, 1.2, 1.2), "Metal")
            box((x, -11.3, 18 + i * 17), (10, 0.6, 7), "Cristal")
        box((x - s * 10.4, -11.5, 55), (1.4, 1.4, 104), "Luz")
        for k in range(4):
            box((x + (k % 2 - 0.5) * 16, (k // 2 - 0.5) * 18, 113), (4, 4, 6), "Cuerpo", bevel=0.4)
            cyl((x + (k % 2 - 0.5) * 16, (k // 2 - 0.5) * 18, 116), 2.2, 22, "Cuerpo", n=8, r2=0.3)
        tier_tower(x, 0, 110, 10, 60, 4, n=8, fins=False)
    # el arco con su remate en pico
    box((0, 0, 101), (72, 20, 12), "Cuerpo", bevel=1)
    for i in range(9):
        box(((i - 4) * 7.6, -10.6, 101), (5, 0.8, 9), "Cristal")
    cyl((0, 0, 107), 14, 26, "Cuerpo", n=4, r2=1, rot=(0, 0, math.pi / 4))
    # el anillo de luz (portal) con su marco
    torus((0, -1, 52), 20, 1.6, "Luz", n=72, m=12, rot=(math.pi / 2, 0, 0))
    torus((0, -1, 52), 23, 1.8, "Metal", n=72, m=12, rot=(math.pi / 2, 0, 0))
    cyl((0, 1, 52), 19, 0.6, "Cristal", n=64, rot=(math.pi / 2, 0, 0))
    ring_of(12, 23, lambda j, a, cx, cy: box((cx, -1.5, 52 + cy), (2.2, 2.4, 4), "Metal", rot=(0, a, 0)))
    # la catedral de detrás
    box((0, 44, 32), (44, 44, 64), "Cuerpo", bevel=1.2)
    for i in range(5):
        box(((i - 2) * 8, 21.6, 34), (4, 0.8, 40), "Cristal")
        box(((i - 2) * 8, 21.4, 56), (5, 1, 1), "Luz")
    tier_tower(0, 44, 64, 18, 90, 5, n=8)
    for s in (-1, 1):
        cyl((s * 34, 44, 0), 13, 26, "Cuerpo", n=32, bevel=0.6)
        dome(s * 34, 44, 26, 13)
        for k in range(8):
            a = k / 8 * math.tau
            box((s * 34 + math.cos(a) * 13.2, 44 + math.sin(a) * 13.2, 13), (0.8, 3, 8), "Cristal", rot=(0, 0, a))
    # palmeras de piedra (pilares con remate) delante
    for s in (-1, 1):
        for k in range(3):
            cyl((s * (44 + k * 8), -30 - k * 8, 0), 1.4, 18, "Tronco", n=8)
            for f in range(6):
                a = f / 6 * math.tau
                box((s * (44 + k * 8) + math.cos(a) * 4, -30 - k * 8 + math.sin(a) * 4, 18), (8, 2.4, 0.4), "Hoja", rot=(0.35, 0, a))


def arbol_madre():
    """Árbol Madre (Umbría): tronco gigante con raíces, copa enorme, plataformas con casas-cúpula y cascada."""
    cyl((0, 0, -6), 17, 206, "Tronco", n=24, r2=12, bevel=0)
    # corteza: costillas verticales
    ring_of(16, 16.5, lambda j, a, cx, cy: box((cx, cy, 80), (2.2, 2.2, 170), "Tronco", rot=(0, 0, a)))
    for j in range(8):
        a = j / 8 * math.tau
        for s in range(4):
            r0 = 18 + s * 6
            box((math.cos(a) * r0, math.sin(a) * r0, 10 - s * 3), (10, 5, 12 - s * 2), "Tronco", rot=(0, math.radians(40), a))
    for j in range(9):
        a = j / 9 * math.tau
        sphere((math.cos(a) * 34, math.sin(a) * 34, 196 + (j % 3) * 9), 34 + (j % 3) * 6, "Hoja", seg=20, rings=10, squash=0.7)
    sphere((0, 0, 224), 46, "Hoja", seg=24, rings=12, squash=0.7)
    for z, rr in ((70, 40), (130, 36)):
        cyl((0, 0, z), rr, 2.2, "Cuerpo", n=48, bevel=0.3)
        torus((0, 0, z + 2.6), rr, 0.35, "Luz", n=64, m=6)
        torus((0, 0, z + 3.6), rr, 0.25, "Metal", n=64, m=6)
        ring_of(24, rr, lambda j, a, cx, cy: box((cx, cy, z + 2.4), (0.3, 0.3, 2.4), "Metal"))
        for k in range(4):
            a = k / 4 * math.tau + (0 if z == 70 else math.pi / 4)
            hx, hy = math.cos(a) * 28, math.sin(a) * 28
            cyl((hx, hy, z + 2.2), 6.5, 8, "Cuerpo", n=24, bevel=0.3)
            dome(hx, hy, z + 10.2, 6.6, ribs=8)
            box((hx - math.cos(a) * 0.1, hy, z + 6), (3, 0.4, 2), "Luz", rot=(0, 0, a))
        # soportes en diagonal
        for k in range(6):
            a = k / 6 * math.tau
            box((math.cos(a) * (rr * 0.6), math.sin(a) * (rr * 0.6), z - 8), (rr * 0.8, 1.6, 1.6), "Metal", rot=(0, math.radians(-30), a))
    # escalera de caracol alrededor del tronco
    for s in range(60):
        a = s * 0.33
        box((math.cos(a) * 21, math.sin(a) * 21, 4 + s * 2.2), (6, 3, 0.6), "Cuerpo", rot=(0, 0, a))
    # roca, estanque y cascada
    box((-34, -44, 18), (26, 14, 40), "Roca", bevel=1.5)
    waterfall(-34, -51.5, 0, 12, 38)
    cyl((-34, -62, -0.4), 16, 0.8, "Agua", n=32)


def torre_anillos():
    """Torre del Crédito (Vértice): rascacielos de 330 con tres halos de neón, pantallas gigantes y aguja."""
    segs = [(54, 0, 110), (42, 110, 110), (30, 220, 80)]
    for w, z0, h in segs:
        box((0, 0, z0 + h / 2), (w, w, h), "Cristal", bevel=0.8)
        for z in range(int(z0) + 6, int(z0 + h) - 2, 6):
            box((0, 0, z), (w + 0.6, w + 0.6, 0.7), "Metal")
        for sx in (-1, 1):
            for sy in (-1, 1):
                box((sx * w / 2, sy * w / 2, z0 + h / 2), (1.4, 1.4, h), "Luz")
        # mástiles verticales en cada cara
        for f in range(4):
            a = f * math.pi / 2
            for k in (-1, 0, 1):
                ox = math.cos(a) * (w / 2 + 0.4) - math.sin(a) * k * w / 4
                oy = math.sin(a) * (w / 2 + 0.4) + math.cos(a) * k * w / 4
                box((ox, oy, z0 + h / 2), (0.6, 0.6, h), "Metal")
        box((0, 0, z0 + h - 1.5), (w + 3, w + 3, 3), "Cuerpo", bevel=0.4)
    cyl((0, 0, 300), 3, 70, "Metal", n=12, r2=0.6)
    sphere((0, 0, 372), 3, "Luz", seg=16, rings=8)
    for i, z in enumerate((120, 200, 270)):
        R = 48 - i * 6
        torus((0, 0, z), R, 2.4, "Luz", n=96, m=12)
        torus((0, 0, z), R + 3.2, 0.8, "Metal", n=96, m=8)
        ring_of(8, R * 0.5 + 10, lambda j, a, cx, cy: box((cx, cy, z), (R - 20, 1.4, 1.4), "Metal", rot=(0, 0, a)))
    # pantallas gigantes en el zócalo
    for f in range(4):
        a = f * math.pi / 2
        cx, cy = math.cos(a) * 27.8, math.sin(a) * 27.8
        box((cx, cy, 62), (36 if f % 2 else 1.2, 1.2 if f % 2 else 36, 30), "Luz", rot=(0, 0, 0))
    # base: plaza con podios
    box((0, 0, 4), (74, 74, 8), "Cuerpo", bevel=1)
    ring_of(4, 46, lambda j, a, cx, cy: box((cx, cy, 14), (10, 10, 28), "Cuerpo", bevel=0.6), phase=math.pi / 4)


def reactor():
    """Reactor de Mareas (Tálasa): disco blanco, núcleo de luz, halos y cuatro torres técnicas."""
    ring_of(8, 40, lambda j, a, cx, cy: cyl((cx, cy, 0), 3, 14, "Metal", n=12))
    cyl((0, 0, 14), 62, 8, "Cuerpo", n=96, bevel=1.2)
    torus((0, 0, 18), 62, 1.2, "Luz", n=96, m=8)
    cyl((0, 0, 22), 58, 0.6, "Cuerpo", n=96)
    for d in (20, 35, 50):
        torus((0, 0, 22.6), d, 0.5, "Luz", n=96, m=6)
    # paneles en el borde del disco
    ring_of(32, 61.5, lambda j, a, cx, cy: box((cx, cy, 18), (0.6, 6, 4), "Cristal", rot=(0, 0, a)))
    sphere((0, 0, 44), 13, "Luz", seg=32, rings=16)
    cyl((0, 0, 22), 16, 46, "Cristal", n=32)
    ring_of(8, 16.2, lambda j, a, cx, cy: box((cx, cy, 45), (1, 1, 46), "Metal", rot=(0, 0, a)))
    cyl((0, 0, 68), 18, 3, "Cuerpo", n=32, bevel=0.5)
    torus((0, 0, 50), 44, 2, "Luz", n=96, m=10)
    torus((0, 0, 34), 30, 1.4, "Luz", n=96, m=8)
    ring_of(4, 44, lambda j, a, cx, cy: box((cx * 0.75, cy * 0.75, 50), (1.6, 1.6, 2), "Metal"))
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        tx, ty = math.cos(a) * 66, math.sin(a) * 66
        box((tx, ty, 30), (14, 14, 60), "Cuerpo", rot=(0, 0, a), bevel=1)
        for z in range(8, 58, 8):
            box((tx, ty, z), (14.6, 14.6, 1), "Luz" if z % 16 == 0 else "Metal", rot=(0, 0, a))
        box((tx - math.cos(a) * 7.4, ty - math.sin(a) * 7.4, 34), (0.6, 10, 8), "Luz", rot=(0, 0, a))
        cyl((tx, ty, 60), 4, 10, "Metal", n=12, r2=1)


def ciudadela():
    """La Forja Mayor (Tefra): ciudadela negra de púas, foso de lava, cascadas de lava y su haz de luz."""
    cyl((0, 0, -1), 70, 1.2, "Luz", n=64)
    cyl((0, 0, -0.6), 60, 1.2, "Roca", n=64)
    for i in range(8):
        a = i / 8 * math.tau
        cx, cy = math.cos(a) * 52, math.sin(a) * 52
        box((cx, cy, 16), (10, 44, 32), "Cuerpo", rot=(0, 0, a + math.pi / 2), bevel=0.8)
        tier_tower(cx, cy, 32, 7, 50 + (i % 3) * 14, 3, n=6, glass=False)
        box((cx * 0.92, cy * 0.92, 14), (0.8, 4, 28), "Luz", rot=(0, 0, a))
    box((0, 0, 45), (46, 46, 90), "Cuerpo", bevel=1.5)
    for f in range(4):
        a = f * math.pi / 2
        for z in range(10, 90, 12):
            box((math.cos(a) * 23.4, math.sin(a) * 23.4, z), (1.2 if f % 2 == 0 else 30, 30 if f % 2 == 0 else 1.2, 2), "Luz" if z % 24 == 10 else "Metal")
    for sx in (-1, 1):
        for sy in (-1, 1):
            tier_tower(sx * 20, sy * 20, 90, 9, 70, 4, n=6, glass=False)
    tier_tower(0, 0, 90, 18, 80, 5, n=6, glass=False)
    # (el haz de luz hacia el cielo lo pone el juego aparte: World/PlanetMetroMeshes)
    # púas por la muralla
    for i in range(24):
        a = i / 24 * math.tau
        cyl((math.cos(a) * 60, math.sin(a) * 60, 0), 2, 16 + (i % 3) * 6, "Cuerpo", n=6, r2=0.2)
    for i in range(3):
        a = i * math.tau / 3
        waterfall(math.cos(a) * 24, math.sin(a) * 24, 0, 8, 80, "Luz")


def reactor_verde():
    """Reactor Verde (Miasma): tanques de cristal con el líquido que brilla, tuberías y el haz verde."""
    spots = [(0, 0, 15, 120), (32, 10, 9, 70), (-30, 14, 9, 64), (12, -34, 8, 56), (-18, -30, 7, 48)]
    cyl((0, 0, -0.4), 64, 0.6, "Luz", n=64)
    for i, (x, y, r, h) in enumerate(spots):
        cyl((x, y, 0), r + 2.5, 4, "Metal", n=24, bevel=0.4)
        cyl((x, y, 4), r * 0.86, h * 0.85, "Luz", n=24)
        cyl((x, y, 4), r, h, "Cristal", n=32)
        for z in (4, h * 0.5, h + 2):
            torus((x, y, z), r + 0.6, 0.8, "Metal", n=48, m=8)
        ring_of(6, r + 0.4, lambda j, a, cx, cy: box((x + cx, y + cy, h / 2 + 4), (0.8, 0.8, h), "Metal", rot=(0, 0, a)))
        sphere((x, y, h + 4), r, "Metal", seg=24, rings=12, hemi=True)
        cyl((x, y, h + 4 + r * 0.9), 1, 8, "Metal", n=8)
        sphere((x, y, h + 13 + r * 0.9), 1.4, "Luz", seg=12, rings=6)
        if i > 0:
            d = Vector((-x, -y, 0))
            mid = Vector((x, y, 0)) + d / 2
            ang = math.atan2(d.y, d.x)
            box((mid.x, mid.y, h * 0.4), (d.length, 3, 3), "Metal", rot=(0, 0, ang), bevel=0.4)
            box((mid.x, mid.y, h * 0.4 + 2.4), (d.length, 1, 1), "Luz", rot=(0, 0, ang))
    # (el haz verde lo pone el juego aparte: World/PlanetMetroMeshes)
    # pasarelas y barandillas alrededor
    for i in range(16):
        a = i / 16 * math.tau
        box((math.cos(a) * 50, math.sin(a) * 50, 1.2), (4, 18, 0.6), "Metal", rot=(0, 0, a))


KINDS = [
    ("Palacio", palacio, {"Cuerpo": (0.92, 0.95, 0.99), "Luz": (0.4, 0.85, 1.0)}),
    ("Puerta", puerta, {"Cuerpo": (0.85, 0.68, 0.48), "Luz": (0.3, 0.8, 1.0)}),
    ("ArbolMadre", arbol_madre, {"Cuerpo": (0.82, 0.78, 0.66), "Luz": (0.4, 0.9, 1.0)}),
    ("TorreAnillos", torre_anillos, {"Cuerpo": (0.22, 0.16, 0.36), "Cristal": (0.3, 0.2, 0.6), "Luz": (0.85, 0.3, 1.0)}),
    ("Reactor", reactor, {"Cuerpo": (0.92, 0.94, 0.97), "Luz": (0.25, 0.75, 1.0)}),
    ("Ciudadela", ciudadela, {"Cuerpo": (0.16, 0.14, 0.15), "Luz": (1.0, 0.4, 0.1), "Roca": (0.12, 0.1, 0.1)}),
    ("ReactorVerde", reactor_verde, {"Metal": (0.3, 0.33, 0.3), "Luz": (0.5, 1.0, 0.2), "Cristal": (0.4, 0.6, 0.4)}),
]


# ---------------------------------------------------------------------------
# Juntar, contar, simplificar, exportar
# ---------------------------------------------------------------------------
def material(name, rgb, metal, rough, emit):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1)
        bsdf.inputs["Emission Strength"].default_value = emit
    return m


def tris_of(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def finish(kind, tint):
    joined = []
    for group, objs in G.items():
        if not objs:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.object.convert(target="MESH")
        if len(objs) > 1:
            bpy.ops.object.join()
        o = bpy.context.active_object
        o.name = f"{kind}_{group}"
        o.data.name = o.name
        t = tris_of(o)
        if t > MAX_TRIS:
            dec = o.modifiers.new("simplificar", "DECIMATE")
            dec.ratio = MAX_TRIS / t * 0.97
            bpy.ops.object.convert(target="MESH")
        base, metal, rough, emit = PREVIEW[group]
        col = tint.get(group, base)
        o.data.materials.clear()
        o.data.materials.append(material(f"{kind}_{group}_m", col, metal, rough, emit))
        joined.append(o)
    return joined


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            lo = Vector((min(lo.x, p.x), min(lo.y, p.y), min(lo.z, p.z)))
            hi = Vector((max(hi.x, p.x), max(hi.y, p.y), max(hi.z, p.z)))
    return lo, hi


def render(objs, path, lo, hi):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 24
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = 1280, 720
    world = bpy.data.worlds.new("cielo")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.05, 0.07, 0.14, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    sc.world = world
    sun = bpy.data.objects.new("sol", bpy.data.lights.new("sol", "SUN"))
    sun.data.energy = 3
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    sc.collection.objects.link(sun)
    size = hi - lo
    center = (lo + hi) / 2
    dist = max(size.x, size.y, size.z) * 1.35
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.lens = 35
    cam.data.clip_end = 5000
    cam.location = (center.x + dist * 0.55, center.y - dist * 0.85, lo.z + size.z * 0.45 + dist * 0.12)
    direction = Vector((center.x, center.y, lo.z + min(size.z, 260) * 0.45)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(cam)
    sc.camera = cam
    sc.render.filepath = path
    sc.render.image_settings.file_format = "JPEG"
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    solo = argv[argv.index("--solo") + 1] if "--solo" in argv else None
    do_render = "--no-render" not in argv
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DOCS, exist_ok=True)
    man_path = os.path.join(OUT, "manifest.json")
    manifest = json.load(open(man_path, encoding="utf-8")) if os.path.exists(man_path) else {}
    for kind, fn, tint in KINDS:
        if solo and kind != solo:
            continue
        reset()
        fn()
        objs = finish(kind, tint)
        lo, hi = bounds(objs)
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, kind + ".fbx"), use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", add_leaf_bones=False, path_mode="STRIP")
        parts = {o.name.split("_", 1)[1]: tris_of(o) for o in objs}
        # (Roblox: X igual, Y arriba = Z de Blender, Z sur = -Y de Blender)
        center = [round((lo.x + hi.x) / 2, 2), round((lo.z + hi.z) / 2, 2), round(-(lo.y + hi.y) / 2, 2)]
        size = [round(hi.x - lo.x, 2), round(hi.z - lo.z, 2), round(hi.y - lo.y, 2)]
        manifest[kind] = {"parts": parts, "center": center, "size": size, "tris": sum(parts.values())}
        print(f"  {kind}: {sum(parts.values())} triángulos en {len(parts)} mallas {parts}  tamaño {size}")
        if do_render:
            render(objs, os.path.join(DOCS, kind + ".jpg"), lo, hi)
    with open(man_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    lua = ["-- MonumentoMalla: GENERADO por scripts/planetas/monumentos_blender.py (no editar a mano).",
           "-- Por monumento (Landmark.Kind): sus mallas (una por material) con sus triángulos, y el centro y el tamaño",
           "-- (studs, respecto al centro de la base; el frente mira a -Z). Lo usa World/PlanetMetroMeshes.",
           "return {"]
    for kind in sorted(manifest):
        m = manifest[kind]
        c, s = m["center"], m["size"]
        parts = ", ".join(f"{k} = {v}" for k, v in sorted(m["parts"].items()))
        lua.append(f"\t{kind} = {{ Center = Vector3.new({c[0]}, {c[1]}, {c[2]}), Size = Vector3.new({s[0]}, {s[1]}, {s[2]}), Parts = {{ {parts} }} }},")
    lua.append("}")
    with open(os.path.join(ROOT, "src", "shared", "Cosmos", "MonumentoMalla.luau"), "w", encoding="utf-8") as f:
        f.write("\n".join(lua) + "\n")


main()
