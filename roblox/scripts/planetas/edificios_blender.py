#!/usr/bin/env python3
"""Edificios y objetos de calle de las ciudades de los planetas, con Blender (detalle «de cerca»).

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python scripts/planetas/edificios_blender.py -- [--solo Nombre] [--no-render]

Hace, para cada pieza:
  * assets/ciudades/<Nombre>.fbx con VARIAS mallas: <Nombre>_<Seccion>_<Grupo>
      Seccion  Base (planta baja), Medio (un tramo de pisos que se REPITE hasta la altura del solar), Tope (azotea)
      Grupo    Cuerpo, Cristal, Luz, Metal, Techo, Nieve, Toldo, Hoja  (World/PlanetCityMeshes les pone el material
               y el color del planeta)
    Coordenadas de Roblox en studs. El frente (la puerta) mira a -Y de Blender.
  * assets/ciudades/manifest.json y src/shared/Cosmos/CiudadMalla.luau (medidas de cada sección y una malla de
    «prueba» para saber hacia dónde quedó el frente al importarla)
  * docs/planetas/edificios/<Nombre>.jpg (vista previa)
Después: bash scripts/upload-ciudades.sh (escribe src/shared/Cosmos/CiudadAssetIds.luau).
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
OUT = os.path.join(ROOT, "assets", "ciudades")
DOCS = os.path.join(ROOT, "docs", "planetas", "edificios")
MAX_TRIS = 9000
PI = math.pi

G = {}  # "Seccion_Grupo" -> [objetos]
SEC = ["Base"]
ENTER = [None]  # la planta baja en la que se entra (la pone enter() en cada edificio)

PREVIEW = {
    "Cuerpo": ((0.8, 0.82, 0.86), 0.0, 0.6, 0.0),
    "Cristal": ((0.25, 0.5, 0.75), 0.3, 0.08, 0.0),
    "Luz": ((0.3, 0.85, 1.0), 0.0, 0.3, 5.0),
    "Metal": ((0.3, 0.33, 0.38), 0.85, 0.4, 0.0),
    "Techo": ((0.4, 0.3, 0.28), 0.0, 0.7, 0.0),
    "Nieve": ((0.95, 0.97, 1.0), 0.0, 0.9, 0.0),
    "Toldo": ((0.75, 0.3, 0.2), 0.0, 0.9, 0.0),
    "Hoja": ((0.2, 0.5, 0.25), 0.0, 0.85, 0.0),
    "Forro": ((0.78, 0.74, 0.68), 0.0, 0.9, 0.0),
}
TINTS = {
    "Tefra": {"Cuerpo": (0.2, 0.17, 0.17), "Luz": (1.0, 0.35, 0.08), "Metal": (0.1, 0.09, 0.09), "Techo": (0.13, 0.11, 0.12), "Cristal": (0.3, 0.12, 0.06)},
    "Siroco": {"Cuerpo": (0.82, 0.62, 0.42), "Luz": (0.3, 0.8, 1.0), "Metal": (0.4, 0.26, 0.16), "Techo": (0.3, 0.6, 0.65), "Toldo": (0.75, 0.25, 0.15)},
    "Talasa": {"Cuerpo": (0.9, 0.93, 0.96), "Luz": (0.2, 0.85, 1.0), "Metal": (0.55, 0.62, 0.7), "Techo": (0.85, 0.9, 0.95)},
    "Nivalis": {"Cuerpo": (0.52, 0.56, 0.64), "Luz": (0.6, 0.9, 1.0), "Metal": (0.25, 0.28, 0.36), "Techo": (0.2, 0.25, 0.4)},
    "Miasma": {"Cuerpo": (0.36, 0.4, 0.36), "Luz": (0.45, 1.0, 0.2), "Metal": (0.22, 0.24, 0.22), "Techo": (0.3, 0.33, 0.3)},
    "Vertice": {"Cuerpo": (0.16, 0.16, 0.24), "Luz": (1.0, 0.2, 0.75), "Metal": (0.1, 0.1, 0.15), "Techo": (0.1, 0.1, 0.14), "Cristal": (0.15, 0.3, 0.55)},
    "Umbria": {"Cuerpo": (0.45, 0.32, 0.2), "Luz": (0.6, 1.0, 0.5), "Metal": (0.3, 0.2, 0.12), "Techo": (0.2, 0.42, 0.18)},
    "Calle": {"Cuerpo": (0.7, 0.3, 0.2), "Luz": (0.3, 0.9, 1.0), "Metal": (0.3, 0.32, 0.36), "Toldo": (0.2, 0.45, 0.6)},
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    G.clear()
    SEC[0] = "Base"
    ENTER[0] = None


def sec(name):
    SEC[0] = name


def _keep(o, group):
    G.setdefault(f"{SEC[0]}_{group}", []).append(o)
    return o


def _bevel(o, width, segments=1):
    if width <= 0:
        return
    m = o.modifiers.new("bisel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(40)


def box(c, size, group, rot=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=c, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    _bevel(o, bevel)
    return _keep(o, group)


def cyl(c, r, h, group, n=16, rot=(0, 0, 0), r2=None, bevel=0.0):
    """Cilindro (o cono si r2) con la BASE en c; el eje es +Z girado con rot."""
    # (ligero para el móvil: lo fino, con pocas caras)
    big = max(r, r2 or 0)
    n = min(n, 6) if big < 0.9 else min(n, 8) if big < 2 else min(n, 12) if big < 6 else min(n, 20)
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=n, radius=r, depth=h, location=(0, 0, 0))
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=n, radius1=r, radius2=r2, depth=h, location=(0, 0, 0))
    o = bpy.context.active_object
    o.location = (0, 0, h / 2)
    bpy.ops.object.transform_apply(location=True)
    o.rotation_euler = rot
    o.location = c
    _bevel(o, bevel)
    return _keep(o, group)


def sphere(c, r, group, seg=20, rings=10, hemi=False, squash=(1, 1, 1)):
    if seg > 4:
        seg, rings = (min(seg, 8), min(rings, 5)) if r < 1.6 else (min(seg, 10), min(rings, 6)) if r < 4 else (min(seg, 16), min(rings, 8))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=r, location=c)
    o = bpy.context.active_object
    if squash != (1, 1, 1):
        o.scale = squash
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if hemi:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        cut = [v for v in bm.verts if v.co.z < -0.01]
        bmesh.ops.delete(bm, geom=cut, context="VERTS")
        bmesh.ops.holes_fill(bm, edges=bm.edges)
        bm.to_mesh(o.data)
        bm.free()
    return _keep(o, group)


def torus(c, R, r, group, n=32, m=8, rot=(0, 0, 0)):
    n, m = (min(n, 12), 4) if R < 6 else (min(n, 20), 4)
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=n, minor_segments=m, location=c, rotation=rot)
    return _keep(bpy.context.active_object, group)


def mesh_obj(verts, faces, group, at=(0, 0, 0)):
    me = bpy.data.meshes.new("m")
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new("o", me)
    bpy.context.scene.collection.objects.link(o)
    o.location = at
    return _keep(o, group)


def frustum(c, w0, d0, w1, d1, h, group):
    """Tronco de pirámide de base rectangular con la BASE centrada en c (muros en talud, tejados a cuatro aguas)."""
    w1, d1 = max(w1, 0.02), max(d1, 0.02)
    v = [(-w0 / 2, -d0 / 2, 0), (w0 / 2, -d0 / 2, 0), (w0 / 2, d0 / 2, 0), (-w0 / 2, d0 / 2, 0),
         (-w1 / 2, -d1 / 2, h), (w1 / 2, -d1 / 2, h), (w1 / 2, d1 / 2, h), (-w1 / 2, d1 / 2, h)]
    f = [(3, 2, 1, 0), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return mesh_obj(v, f, group, c)


def gable(c, w, d, h, group):
    """Tejado a dos aguas: la cumbrera va a lo largo de X. BASE centrada en c."""
    v = [(-w / 2, -d / 2, 0), (w / 2, -d / 2, 0), (w / 2, d / 2, 0), (-w / 2, d / 2, 0), (-w / 2, 0, h), (w / 2, 0, h)]
    f = [(3, 2, 1, 0), (0, 1, 5, 4), (2, 3, 4, 5), (1, 2, 5), (3, 0, 4)]
    return mesh_obj(v, f, group, c)


def ledge(z, w, d, t=0.6, out=0.5, group="Metal"):
    box((0, 0, z), (w + 2 * out, d + 2 * out, t), group)


def parapet(z, w, d, hgt=1.4, t=0.5, group="Metal"):
    for s in (-1, 1):
        box((0, s * (d / 2 - t / 2), z + hgt / 2), (w, t, hgt), group)
        box((s * (w / 2 - t / 2), 0, z + hgt / 2), (t, d - 2 * t, hgt), group)


def merlons(z, w, d, n=6, size=(2.2, 1.2, 2.2), group="Cuerpo"):
    for i in range(n):
        u = i / (n - 1) - 0.5
        for s in (-1, 1):
            box((u * (w - size[0]), s * (d / 2 - size[1] / 2), z + size[2] / 2), size, group)
            if 0 < i < n - 1:
                box((s * (w / 2 - size[1] / 2), u * (d - size[0]), z + size[2] / 2), (size[1], size[0], size[2]), group)


def faces4(w, d):
    """Las cuatro fachadas: (cx, cy, giro z, ancho) con el frente primero."""
    return [(0, -d / 2, 0, w), (0, d / 2, PI, w), (-w / 2, 0, -PI / 2, d), (w / 2, 0, PI / 2, d)]


def on_face(face, u, z, out, size, group, bevel=0.0):
    """Una caja pegada a una fachada: u a lo largo, out hacia fuera (centro de la caja)."""
    cx, cy, a, _ = face
    # eje a lo largo de la fachada y normal hacia fuera
    ax, ay = math.cos(a), math.sin(a)
    nx, ny = math.sin(a), -math.cos(a)
    return box((cx + ax * u + nx * out, cy + ay * u + ny * out, z), size, group, rot=(0, 0, a), bevel=bevel)


def windows(w, d, z, cols, ww, wh, group="Cristal", faces=(0, 1, 2, 3), depth=0.3, arch=False, point=False):
    fs = faces4(w, d)
    for fi in faces:
        face = fs[fi]
        span = face[3]
        for i in range(cols):
            u = (i + 0.5) / cols * span - span / 2
            on_face(face, u, z, depth / 2 - 0.05, (ww, depth, wh), group)
            if arch or point:
                cx, cy, a, _ = face
                ax, ay = math.cos(a), math.sin(a)
                nx, ny = math.sin(a), -math.cos(a)
                px, py = cx + ax * u + nx * (depth / 2 - 0.05), cy + ay * u + ny * (depth / 2 - 0.05)
                if arch:
                    o = cyl((px - nx * depth / 2, py - ny * depth / 2, z + wh / 2), ww / 2, depth, group, n=12, rot=(PI / 2, 0, a))
                else:
                    o = frustum((px, py, z + wh / 2), ww, depth, 0.05, depth, ww * 0.9, group)
                    o.rotation_euler = (0, 0, a)


def pipe_v(x, y, z0, h, r=0.5, group="Metal", flanges=True):
    cyl((x, y, z0), r, h, group, n=8)
    if flanges:
        for t in (0.15, 0.85):
            cyl((x, y, z0 + h * t), r * 1.45, 0.35, group, n=8)


def pipe_x(x0, x1, y, z, r=0.5, group="Metal", flanges=2):
    cyl((x0, y, z), r, x1 - x0, group, n=8, rot=(0, PI / 2, 0))
    for i in range(flanges):
        t = (i + 0.5) / flanges
        cyl((x0 + (x1 - x0) * t - 0.2, y, z), r * 1.45, 0.4, group, n=8, rot=(0, PI / 2, 0))


def ac_unit(x, y, z, a=0.0):
    box((x, y, z), (2.6, 1.6, 2.0), "Metal", rot=(0, 0, a), bevel=0.1)


def antenna(x, y, z, h, light=True):
    cyl((x, y, z), 0.3, h, "Metal", n=6, r2=0.08)
    for t in (0.35, 0.6):
        box((x, y, z + h * t), (2.4 * (1 - t), 0.15, 0.15), "Metal")
    if light:
        sphere((x, y, z + h), 0.55, "Luz", seg=8, rings=6)


def dish(x, y, z, r=2.0):
    cyl((x, y, z), 0.25, 1.8, "Metal", n=6)
    o = sphere((x, y, z + 2.2), r, "Metal", seg=12, rings=8, hemi=True, squash=(1, 1, 0.45))
    o.rotation_euler = (math.radians(125), 0, math.radians(30))


def tank(x, y, z, r, h, group="Metal", legs=True):
    cyl((x, y, z + (0.8 if legs else 0)), r, h, group, n=12)
    sphere((x, y, z + h + (0.8 if legs else 0)), r, group, seg=12, rings=6, hemi=True, squash=(1, 1, 0.5))
    if legs:
        for a in range(3):
            cyl((x + math.cos(a * 2.1) * r * 0.7, y + math.sin(a * 2.1) * r * 0.7, z), 0.25, 0.9, "Metal", n=6)

def body(o):
    """Marca el CUERPO de la planta baja: se vacía por dentro (se entra) y se le abre la puerta."""
    o["body"] = 1
    return o


def enter(style, hx, y0, y1, top, floor=0.3, dw=8.0, dh=9.0, t=1.2, round_=False, ramp=False, home=False):
    """La planta baja en la que se entra: hueco de hx (medio ancho) × [y0, y1] (frente y fondo, por fuera) entre
    floor y top, con la puerta (dw × dh) en el centro del frente. La amuebla y lo apunta para el manifiesto."""
    E = dict(hx=hx, y0=y0, y1=y1, top=top, floor=floor, dw=dw, dh=dh, t=t, round=round_, ramp=ramp, solids=[])
    ENTER[0] = E
    prev = SEC[0]
    sec("Base")
    furnish(E, style, home)
    sec(prev)


def gem(c, r, group="Luz", tall=1.5):
    """Cristal flotante (un octaedro)."""
    return sphere(c, r, group, seg=4, rings=2, squash=(1, 1, tall))


def hover(c, r, h, group="Metal", n=14):
    """Algo que flota: un disco con su anillo de luz por debajo."""
    cyl(c, r, h, group, n=n)
    cyl((c[0], c[1], c[2] - 0.18), r * 0.8, 0.12, "Luz", n=n)


def furnish(E, style, home):
    """Decoración de otra galaxia: nada de camas, mesas ni estanterías de la Tierra. Lámpara que flota, círculo
    de luz en el suelo, cápsula de descanso o consola con hologramas, celdas hexagonales, mesa y asientos que
    levitan y la máquina propia del planeta."""
    t = E["t"]
    hx, y0, y1, z, top = E["hx"] - t, E["y0"] + t, E["y1"] - t, E["floor"], E["top"]
    if E["round"]:
        k = 0.7
        cy, hy = (y0 + y1) / 2, (y1 - y0) / 2 * k
        hx, y0, y1 = hx * k, cy - hy, cy + hy
    S = E["solids"]

    def solid(c, size):
        S.append([round(v, 2) for v in (*c, *size)])

    cy = (y0 + y1) / 2
    # lámpara: un anillo y un núcleo que flotan bajo el techo
    torus((0, cy, top - 1.7), 2.3, 0.22, "Luz", n=24, m=6)
    gem((0, cy, top - 1.7), 0.8, "Luz")
    torus((0, cy, top - 0.5), 1.2, 0.15, "Metal", n=16, m=6)
    # el suelo: un círculo de luz con su placa
    cyl((0, cy - 1, z + 0.02), 3.6, 0.08, "Luz", n=24)
    cyl((0, cy - 1, z + 0.03), 3.3, 0.1, "Metal", n=24)
    cyl((0, cy - 1, z + 0.04), 1.2, 0.12, "Luz", n=16)
    if home:
        # cápsula de descanso: base con borde de luz y cúpula de cristal
        bx, by = -hx + 4.4, y1 - 2.8
        box((bx, by, z + 0.75), (7.8, 4.2, 1.1), "Metal", bevel=0.45)
        box((bx, by, z + 0.25), (8.1, 4.5, 0.2), "Luz")
        sphere((bx, by, z + 1.3), 2, "Cristal", seg=16, rings=8, hemi=True, squash=(1.85, 0.98, 0.95))
        box((bx + 0.2, by, z + 1.45), (6.4, 3, 0.4), "Toldo", bevel=0.2)
        cyl((bx - 4.6, by, z), 0.5, 4.4, "Metal", n=8)
        gem((bx - 4.6, by, z + 5.3), 0.6, "Luz")
        solid((bx, by, z + 1.5), (7.8, 4.2, 3))
    else:
        # consola inclinada con hologramas flotando encima y una pantalla grande al fondo
        cw, by = hx * 1.1, y1 - 4.2
        frustum((0, by, z + 0.5), cw, 2.4, cw - 1, 1.3, 2.7, "Metal")
        box((0, by, z + 0.3), (cw + 0.4, 2.8, 0.25), "Luz")
        box((0, by - 0.95, z + 2.2), (cw - 2, 0.12, 1.2), "Luz", rot=(math.radians(-22), 0, 0))
        for i in range(3):
            gem((-cw * 0.3 + i * cw * 0.3, by, z + 4.6 + (i % 2) * 0.5), 0.55, ("Luz", "Cristal", "Luz")[i])
            cyl((-cw * 0.3 + i * cw * 0.3, by, z + 3.25), 0.5, 0.12, "Luz", n=10)
        solid((0, by, z + 1.7), (cw, 2.4, 3.4))
        box((0, y1 - 0.2, z + 7.4), (8.4, 0.3, 3.6), "Metal", bevel=0.1)
        box((0, y1 - 0.4, z + 7.4), (7.6, 0.12, 2.9), "Luz")
    # celdas hexagonales en la pared izquierda, con núcleos de luz y de cristal
    sx_, sl = -hx + 0.7, min(9, (y1 - y0) * 0.4)
    sy = cy - 1.5
    for r_ in range(3):
        for i in range(3):
            yy = sy - sl / 2 + (i + 0.5 + (r_ % 2) * 0.5) * sl / 3.5
            zz = z + 1.5 + r_ * 2.25
            cyl((sx_ - 0.7, yy, zz), 1.3, 1.5, "Metal", n=6, rot=(0, PI / 2, 0))
            cyl((sx_ + 0.75, yy, zz), 0.85, 0.15, ("Luz", "Cristal", "Hoja")[(i + r_) % 3], n=6, rot=(0, PI / 2, 0))
    solid((sx_, sy, z + 3.8), (1.5, sl, 7.6))
    # mesa y asientos que levitan, con un cristal girando encima
    tx, ty = hx - 4.4, y0 + 5.2
    hover((tx, ty, z + 2.3), 2.3, 0.25, "Cristal")
    torus((tx, ty, z + 2.3), 2.35, 0.14, "Metal", n=20, m=6)
    gem((tx, ty, z + 3.7), 0.6, "Luz")
    for a in (0.4, 2.5, 4.6):
        px_, py_ = tx + math.cos(a) * 3.3, ty + math.sin(a) * 3.3
        sphere((px_, py_, z + 1.25), 0.95, "Metal", seg=12, rings=8, squash=(1, 1, 0.5))
        cyl((px_, py_, z + 0.55), 0.6, 0.12, "Luz", n=10)
    solid((tx, ty, z + 1.3), (4.4, 4.4, 2.6))
    # la máquina propia del planeta, al fondo a la derecha
    px, py = hx - 2.5, y1 - 2.4
    if style == "Tefra":  # crisol de magma con su brazo
        cyl((px, py, z), 2.1, 2.6, "Cuerpo", n=8, r2=1.6)
        cyl((px, py, z + 2.6), 1.9, 0.5, "Luz", n=8)
        cyl((px, py, z + 2.4), 2.2, 0.5, "Metal", n=8)
        cyl((px, py, z + 5.4), 0.9, top - z - 5.4, "Metal", n=8, r2=1.5)
        for i in range(3):
            gem((px - 3 - i * 0.8, py + 0.8 - i * 0.7, z + 0.7 + i * 0.25), 0.55 + i * 0.1, "Luz", 1.2)
    elif style == "Siroco":  # urnas de energía con aros de luz
        for i, (dx, dy, r) in enumerate(((0, 0, 1.5), (-2.7, 0.4, 1.1), (0.3, -2.5, 0.9))):
            sphere((px + dx, py + dy, z + r * 1.25), r, "Techo", seg=10, rings=8, squash=(1, 1, 1.3))
            torus((px + dx, py + dy, z + r * 1.25), r * 1.02, 0.12, "Luz", n=14, m=6)
            gem((px + dx, py + dy, z + r * 2.9), r * 0.28, "Luz")
    elif style == "Talasa":  # tubo de vida marina
        cyl((px, py, z), 2, 0.6, "Metal", n=14)
        cyl((px, py, z + 0.6), 1.8, 5.6, "Cristal", n=14)
        cyl((px, py, z + 0.8), 1.3, 4.6, "Luz", n=12)
        cyl((px, py, z + 6.2), 2, 0.5, "Metal", n=14)
        torus((px, py, z + 3.4), 2.1, 0.12, "Luz", n=16, m=6)
    elif style == "Nivalis":  # racimo de cristales que da calor
        cyl((px, py, z), 2.2, 0.6, "Metal", n=6)
        for i in range(6):
            a = i * 1.05
            rr = 0 if i == 0 else 1.2
            o = cyl((px + math.cos(a) * rr, py + math.sin(a) * rr, z + 0.5), 0.75 - (i % 3) * 0.12, 5.4 - (i % 4) * 0.9, "Cristal", n=6, r2=0.05)
            if i > 0:
                o.rotation_euler = (math.sin(a) * 0.3, -math.cos(a) * 0.3, 0)
        gem((px, py, z + 1.6), 1.0, "Luz", 1.0)
        torus((px, py, z + 0.7), 2.3, 0.12, "Luz", n=16, m=6)
    elif style == "Miasma":  # depósito de filtrado
        cyl((px, py, z), 2.1, 0.7, "Metal", n=14)
        cyl((px, py, z + 0.7), 1.8, 5, "Cristal", n=14)
        cyl((px, py, z + 0.9), 1.4, 3.6, "Luz", n=12)
        cyl((px, py, z + 5.7), 2.1, 0.6, "Metal", n=14)
        cyl((px, py, z + 6.3), 0.5, top - z - 6.3, "Metal", n=8)
    elif style == "Nave":  # carga apilada: botes hexagonales con juntas de luz
        for i, (dx, dy, zz) in enumerate(((0, 0, 0), (-3.2, 0.3, 0), (-1.6, 0.2, 3.1), (0.2, -3.2, 0))):
            cyl((px + dx, py + dy, z + zz), 1.5, 3, "Cuerpo", n=6, rot=(0, 0, i * 0.4))
            cyl((px + dx, py + dy, z + zz + 1.4), 1.56, 0.2, "Luz", n=6, rot=(0, 0, i * 0.4))
            cyl((px + dx, py + dy, z + zz + 3), 1.3, 0.2, "Metal", n=6, rot=(0, 0, i * 0.4))
    elif style == "Umbria":  # semillero: vainas que brillan colgadas de un tallo
        cyl((px, py, z), 1.6, 0.6, "Metal", n=8)
        o = cyl((px, py, z + 0.5), 0.35, 5.4, "Hoja", n=6, r2=0.15)
        for i in range(5):
            a = i * 1.26
            sphere((px + math.cos(a) * 1.3, py + math.sin(a) * 1.3, z + 2 + i * 0.8), 0.6, "Luz", seg=8, rings=5, squash=(1, 1, 1.5))
            sphere((px + math.cos(a) * 1.3, py + math.sin(a) * 1.3, z + 2.9 + i * 0.8), 0.8, "Hoja", seg=8, rings=5, squash=(1, 1, 0.3))
    else:  # Vértice: proyector de hologramas
        cyl((px, py, z), 1.7, 1, "Metal", n=14)
        cyl((px, py, z + 1), 0.3, 4.4, "Luz", n=8, r2=1.5)
        torus((px, py, z + 3.4), 1.5, 0.14, "Luz", n=20, m=6)
        gem((px, py, z + 6.4), 0.9, "Luz")
    solid((px, py, z + 2.5), (4, 3.6, 5))


# ---------------------------------------------------------------------------
# VÉRTICE: neón y cristal
# ---------------------------------------------------------------------------
def vertice_bloque():
    sec("Base")
    body(body(box((0, 0, 7), (30, 30, 14), "Cuerpo", bevel=0.25)))
    box((0, -15.1, 5.2), (17, 0.4, 9), "Cristal")
    box((0, -15.25, 4.6), (5.4, 0.5, 8.6), "Metal")
    box((0, -15.4, 4.4), (4.2, 0.4, 7.6), "Cristal")
    box((0, -17.2, 10.4), (19, 4.4, 0.5), "Metal")
    box((0, -19.45, 10.4), (19.4, 0.3, 0.8), "Luz")
    box((0, -15.35, 12.4), (12, 0.4, 2.0), "Luz")
    box((0, -15.2, 12.4), (13, 0.5, 2.8), "Metal")
    for sx in (-1, 1):
        box((sx * 9, -19, 5.2), (0.6, 0.6, 10.2), "Metal")
        box((sx * 15.15, -15.15, 7), (0.5, 0.5, 14), "Luz")
        ac_unit(sx * 15.8, 5, 3.2, PI / 2)
        pipe_v(sx * 15.6, 11, 0, 14, 0.5)
        box((sx * 12.2, -15.6, 1.2), (4, 1.6, 2.4), "Metal", bevel=0.15)  # jardineras de acero
        sphere((sx * 12.2, -15.6, 2.9), 1.5, "Hoja", seg=10, rings=6, squash=(1.2, 0.5, 0.8))
    ledge(13.7, 30, 30, 0.6, 0.6)

    sec("Medio")
    box((0, 0, 24), (29, 29, 20), "Cuerpo")
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((sx * 14.5, sy * 14.5, 24), (1.4, 1.4, 20), "Metal")
        box((sx * 15.35, -15.35, 24), (0.45, 0.45, 20), "Luz")
    for z in (14.3, 24.3):
        ledge(z, 29, 29, 0.5, 0.7)
        for bx in (-7.5, 7.5):
            box((bx, -16, z + 0.3), (8.4, 3, 0.4), "Metal")
            box((bx, -17.4, z + 1.6), (8.4, 0.15, 2.2), "Cristal")
            box((bx, -17.4, z + 2.8), (8.6, 0.25, 0.25), "Metal")
    box((14.9, 0, 26), (0.5, 12.6, 7.6), "Metal")
    box((15.3, 0, 26), (0.25, 11.6, 6.6), "Luz")
    for z in (18, 28):
        ac_unit(-15.6, 6, z, PI / 2)
        ac_unit(-15.6, -6, z + 1.2, PI / 2)
    pipe_v(-15.5, 11.5, 14, 20, 0.45)
    pipe_v(4, 15.5, 14, 20, 0.45)
    box((-4, 15.2, 24), (0.4, 0.4, 20), "Luz")

    sec("Tope")
    box((0, 0, 34.5), (30.6, 30.6, 1), "Metal")
    parapet(35, 30, 30, 1.3, 0.5)
    box((0, 0, 38.6), (20, 20, 7.2), "Cuerpo", bevel=0.25)
    box((0, 0, 42.3), (20.8, 20.8, 0.7), "Luz")
    box((0, 0, 43.1), (20.4, 20.4, 1), "Metal")
    box((-10.2, -3, 39), (0.4, 9, 4.6), "Luz")
    box((9, 11.4, 36.5), (6, 4.4, 3), "Metal", bevel=0.15)
    cyl((9, 11.4, 38), 1.5, 0.5, "Metal", n=10)
    tank(-11.5, 11, 35, 2.2, 4.2)
    antenna(-5, -4, 43.6, 15)
    antenna(5, 3, 43.6, 9, light=False)
    dish(5, -5, 43.6, 2.2)
    for i in range(3):
        box((-12 + i * 2.2, -12.5, 35.9), (1.8, 3.6, 1.8), "Metal", bevel=0.1)
    enter("Vertice", 15, -15, 15, 12.4)


def vertice_torre():
    sec("Base")
    body(box((0, 0, 8), (30, 30, 16), "Cuerpo", bevel=0.3))
    fs = faces4(30, 30)
    for fi in (0, 2, 3):
        on_face(fs[fi], 0, 6.6, 0.15, (22, 0.4, 11.4), "Cristal")
        for u in (-11.4, -3.8, 3.8, 11.4):
            on_face(fs[fi], u, 6.6, 0.3, (0.5, 0.5, 11.6), "Metal")
    for x in (-9, -3, 3, 9):
        cyl((x, -18.6, 0), 0.85, 13, "Metal", n=10)
    box((0, -17.4, 13.3), (24, 5.4, 0.7), "Metal")
    box((0, -20.15, 13.3), (24.4, 0.3, 1.0), "Luz")
    box((0, -15.4, 14.6), (15, 0.4, 2.2), "Luz")
    for sx in (-1, 1):
        box((sx * 15.2, -15.2, 8), (0.55, 0.55, 16), "Luz")
        box((sx * 15.2, 15.2, 8), (0.55, 0.55, 16), "Luz")
        box((sx * 13.5, -18, 0.9), (2.6, 2.6, 1.8), "Metal", bevel=0.15)
        cyl((sx * 13.5, -18, 1.8), 0.5, 3.2, "Hoja", n=6, r2=1.4)
    ledge(15.6, 30, 30, 0.8, 0.8)

    sec("Medio")
    cyl((0, 0, 16), 16.0, 30, "Cuerpo", n=8, rot=(0, 0, PI / 8))
    for i in range(4):
        a = i * PI / 2
        nx, ny = math.sin(a), -math.cos(a)
        box((nx * 14.85, ny * 14.85, 31), (11.6, 0.4, 28.4), "Cristal", rot=(0, 0, a))
        for u in (-3.9, 0, 3.9):
            box((nx * 15 + math.cos(a) * u, ny * 15 + math.sin(a) * u, 31), (0.3, 0.5, 28.4), "Metal", rot=(0, 0, a))
    for i in range(8):
        a = i * PI / 4 + PI / 8
        box((math.cos(a) * 16.05, math.sin(a) * 16.05, 31), (0.5, 0.5, 30), "Luz", rot=(0, 0, a))
    for z in (16, 31):
        cyl((0, 0, z), 16.5, 0.9, "Metal", n=8, rot=(0, 0, PI / 8))
    for sx in (-1, 1):
        box((sx * 15.6, 0, 31), (2.6, 0.6, 30), "Metal")
        box((sx * 16.95, 0, 31), (0.25, 0.7, 30), "Luz")

    sec("Tope")
    cyl((0, 0, 46), 16.6, 1, "Metal", n=8, rot=(0, 0, PI / 8))
    z = 47
    for r, h in ((13.5, 6), (10.4, 5), (7.2, 5)):
        cyl((0, 0, z), r, h, "Cuerpo", n=8, rot=(0, 0, PI / 8))
        cyl((0, 0, z + h * 0.25), r * 1.012, h * 0.45, "Cristal", n=8, rot=(0, 0, PI / 8))
        cyl((0, 0, z + h - 0.5), r + 0.35, 0.5, "Luz", n=8, rot=(0, 0, PI / 8))
        z += h
    cyl((0, 0, z), 1.3, 30, "Metal", n=8, r2=0.15)
    torus((0, 0, z + 7), 4.6, 0.35, "Luz", n=24, m=6)
    torus((0, 0, z + 13), 3.2, 0.3, "Luz", n=24, m=6)
    sphere((0, 0, z + 30), 0.9, "Luz", seg=8, rings=6)
    for i in range(4):
        a = i * PI / 2 + PI / 4
        cyl((math.cos(a) * 12.5, math.sin(a) * 12.5, 47), 0.3, 7, "Metal", n=6, r2=0.1)
        sphere((math.cos(a) * 12.5, math.sin(a) * 12.5, 54), 0.5, "Luz", seg=8, rings=6)
    enter("Vertice", 15, -15, 15, 14)


def vertice_casa():
    sec("Base")
    body(box((0, 0, 10), (26, 26, 20), "Cuerpo", bevel=0.25))
    box((0, -13.1, 4.6), (20, 0.4, 8), "Cristal")
    box((0, -13.3, 4.2), (4.6, 0.5, 8.2), "Metal")
    box((0, -14.8, 9.6), (22, 3.6, 0.4), "Toldo", rot=(math.radians(-10), 0, 0))
    box((0, -13.5, 12.2), (16, 0.5, 3.4), "Metal")
    box((0, -13.75, 12.2), (15, 0.3, 2.6), "Luz")
    windows(26, 26, 16.6, 4, 3.4, 3.2, faces=(0,))
    windows(26, 26, 16.6, 3, 3.4, 3.2, faces=(2, 3))
    windows(26, 26, 6, 3, 3.4, 4, faces=(2, 3))
    for sx in (-1, 1):
        box((sx * 13.15, -13.15, 10), (0.45, 0.45, 20), "Luz")
        ac_unit(sx * 13.8, 5, 14, PI / 2)
    ledge(19.8, 26, 26, 0.6, 0.5)
    parapet(20.1, 26, 26, 1.2, 0.5)
    box((0, 9.5, 24), (16, 0.6, 6), "Metal")
    box((0, 9.1, 24), (15, 0.3, 5), "Luz")
    for sx in (-1, 1):
        box((sx * 6, 9.9, 21.5), (0.5, 0.5, 2.6), "Metal")
    tank(-8, 0, 20.1, 1.8, 3.2)
    box((6, -3, 21.4), (5, 4, 2.6), "Metal", bevel=0.15)
    antenna(9, 4, 20.1, 9)
    pipe_v(-13.5, 10, 0, 20, 0.45)
    enter("Vertice", 13, -13, 13, 10.4, dw=7, dh=8.4, home=True)


# ---------------------------------------------------------------------------
# TEFRA: basalto, hierro y lava
# ---------------------------------------------------------------------------
def tefra_bloque():
    sec("Base")
    body(frustum((0, 0, 0), 32, 32, 30, 30, 14, "Cuerpo"))
    box((0, -15.7, 4.6), (8, 0.8, 9.2), "Metal", bevel=0.2)
    box((0, -16.15, 4.6), (0.3, 0.3, 9), "Cuerpo")
    for sx in (-1, 1):
        box((sx * 4.8, -15.8, 5), (1.4, 1.4, 10), "Cuerpo", bevel=0.15)
        frustum((sx * 14.6, -14.6, 0), 5.4, 5.4, 3.2, 3.2, 14, "Cuerpo")
        frustum((sx * 14.6, 14.6, 0), 5.4, 5.4, 3.2, 3.2, 14, "Cuerpo")
        box((sx * 10.4, -16, 2.6), (2.2, 0.5, 0.9), "Luz")  # rejillas de brasa
        pipe_v(sx * 16.2, 6, 0, 14, 0.7)
    box((0, -15.75, 10.6), (9.4, 0.5, 0.9), "Luz")
    box((0, -15.6, 11.8), (11, 1.2, 1.4), "Cuerpo", bevel=0.15)
    box((0, -18, 0.5), (12, 4, 1), "Cuerpo", bevel=0.1)
    ledge(13.6, 30, 30, 0.9, 0.7)

    sec("Medio")
    box((0, 0, 24), (30, 30, 20), "Cuerpo")
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((sx * 14.4, sy * 14.4, 24), (3.2, 3.2, 20), "Cuerpo", bevel=0.2)
    fs = faces4(30, 30)
    for fi in range(4):
        on_face(fs[fi], 0, 24, 0.4, (2.6, 0.9, 20), "Cuerpo")
        on_face(fs[fi], 0, 24, 0.9, (0.5, 0.3, 19), "Luz")
    for z in (19.4, 29.4):
        for fi in range(4):
            for u in (-9.6, -5.4, 5.4, 9.6):
                on_face(fs[fi], u, z, 0.1, (1.3, 0.3, 5), "Cristal")
                on_face(fs[fi], u, z - 3, 0.3, (2, 0.7, 0.6), "Cuerpo")
    for z in (14.5, 24.2, 33.6):
        ledge(z, 30, 30, 0.8, 0.5)
    pipe_v(-16, -8, 14, 20, 0.7)
    pipe_v(16, 8, 14, 20, 0.7)

    sec("Tope")
    box((0, 0, 34.8), (32.4, 32.4, 1.6), "Cuerpo", bevel=0.2)
    merlons(35.6, 32.4, 32.4, 7)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl((sx * 15, sy * 15, 34), 2.8, 6.5, "Cuerpo", n=8)
            cyl((sx * 15, sy * 15, 40.5), 3.3, 0.6, "Metal", n=8)
            cyl((sx * 15, sy * 15, 41.1), 3.0, 8, "Techo", n=8, r2=0.1)
    box((0, 0, 39), (15, 15, 7), "Cuerpo", bevel=0.2)
    frustum((0, 0, 42.5), 16.4, 16.4, 1.5, 1.5, 9, "Techo")
    box((0, -7.6, 39.4), (5, 0.3, 2.4), "Luz")
    cyl((9.5, 9.5, 35.6), 1.7, 13, "Metal", n=10)
    cyl((9.5, 9.5, 47.6), 1.95, 0.9, "Luz", n=10)
    cyl((9.5, 9.5, 41), 2.1, 0.5, "Metal", n=10)
    enter("Tefra", 15, -15, 15, 12.4)


def tefra_casa():
    sec("Base")
    body(frustum((0, 0, 0), 27.5, 27.5, 26, 26, 20, "Cuerpo"))
    box((0, -13.7, 4), (5, 0.7, 8), "Metal", bevel=0.2)
    box((0, -13.9, 8.9), (6.4, 0.9, 1.2), "Cuerpo", bevel=0.1)
    box((0, -13.75, 9.9), (4, 0.4, 0.6), "Luz")
    fs = faces4(26, 26)
    for fi in range(4):
        for u in (-8, 8):
            on_face(fs[fi], u, 14.4, 0.1, (1.4, 0.4, 4.4), "Cristal")
            on_face(fs[fi], u, 11.7, 0.3, (2.2, 0.7, 0.6), "Cuerpo")
    for u in (-8, 8):
        on_face(fs[0], u, 5.4, 0.3, (1.4, 0.4, 3.6), "Cristal")
    for sx in (-1, 1):
        frustum((sx * 12.8, -12.8, 0), 4.4, 4.4, 2.6, 2.6, 20, "Cuerpo")
        frustum((sx * 12.8, 12.8, 0), 4.4, 4.4, 2.6, 2.6, 20, "Cuerpo")
    ledge(19.7, 26, 26, 0.9, 0.9, "Metal")
    frustum((0, 0, 20.1), 28, 28, 6, 6, 9, "Techo")
    frustum((0, 0, 29.1), 6, 6, 0.3, 0.3, 7, "Techo")
    box((8.5, 7, 25), (3, 3, 12), "Cuerpo", bevel=0.15)
    box((8.5, 7, 31.2), (3.5, 3.5, 0.7), "Luz")
    box((8.5, 7, 31.9), (3.8, 3.8, 0.6), "Metal")
    pipe_v(-13.9, 6, 0, 20, 0.6)
    box((-9, -15, 1.3), (3, 3, 2.6), "Metal", bevel=0.15)
    cyl((9, -15, 0), 1.3, 3.2, "Metal", n=10)
    enter("Tefra", 13, -13, 13, 10.6, dw=7, dh=8.4, home=True)


# ---------------------------------------------------------------------------
# SIROCO: arenisca, arcos, cúpulas y toldos
# ---------------------------------------------------------------------------
def arch_door(y, w, h, group="Metal", depth=0.6):
    box((0, y, (h - w / 2) / 2), (w, depth, h - w / 2), group)
    cyl((0, y + depth / 2, h - w / 2), w / 2, depth, group, n=16, rot=(PI / 2, 0, 0))


def siroco_bloque():
    sec("Base")
    body(box((0, 0, 7), (30, 30, 14), "Cuerpo", bevel=0.4))
    body(box((0, 0, 0.7), (31.4, 31.4, 1.4), "Cuerpo", bevel=0.2))
    arch_door(-15.25, 6, 10)
    box((0, -15.5, 5), (7.6, 0.5, 10.6), "Cuerpo")
    cyl((0, -15.25, 7), 3.8, 0.5, "Cuerpo", n=16, rot=(PI / 2, 0, 0))
    arch_door(-15.55, 6, 10)
    for sx in (-1, 1):
        cyl((sx * 4.6, -16, 0), 0.8, 10.4, "Cuerpo", n=12)
        box((sx * 4.6, -16, 10.8), (2.2, 2.2, 0.8), "Cuerpo")
        box((sx * 10.4, -17.6, 8.6), (7.4, 4.6, 0.25), "Toldo", rot=(math.radians(-16), 0, 0))
        box((sx * 7, -19.6, 4), (0.3, 0.3, 8), "Metal")
        box((sx * 13.8, -19.6, 4), (0.3, 0.3, 8), "Metal")
        box((sx * 10.4, -15.2, 4.4), (4.4, 0.4, 4.4), "Cristal")
        box((sx * 10.4, -16.2, 1.6), (6, 2, 0.5), "Metal")  # mostrador
        sphere((sx * 13.6, -16.6, 1.2), 1.2, "Techo", seg=10, rings=8, squash=(1, 1, 1.3))  # tinajas
    windows(30, 30, 7, 3, 2.2, 3.4, faces=(1, 2, 3), arch=True)
    ledge(13.6, 30, 30, 0.8, 0.5, "Cuerpo")

    sec("Medio")
    box((0, 0, 24), (29, 29, 20), "Cuerpo")
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl((sx * 14.2, sy * 14.2, 14), 1.4, 20, "Cuerpo", n=10)
    for z in (19, 29):
        windows(29, 29, z, 3, 2.3, 3.6, arch=True)
        fs = faces4(29, 29)
        for fi in range(4):
            for i in range(3):
                u = (i + 0.5) / 3 * 29 - 14.5
                on_face(fs[fi], u, z - 2.4, 0.35, (3.2, 0.7, 0.5), "Cuerpo")
    box((0, -15.7, 29.4), (7.4, 2.6, 5.4), "Metal", bevel=0.15)  # mirador de madera
    box((0, -17.05, 29.8), (6, 0.2, 3), "Cristal")
    box((0, -15.7, 32.3), (8.2, 3.2, 0.4), "Toldo")
    for z in (14.3, 24.2, 33.6):
        ledge(z, 29, 29, 0.6, 0.45, "Cuerpo")
    for sx in (-1, 1):
        box((sx * 14.7, -3, 26), (0.2, 3.4, 7), "Toldo")  # colgaduras

    sec("Tope")
    box((0, 0, 34.6), (31, 31, 1.2), "Cuerpo", bevel=0.2)
    merlons(35.2, 31, 31, 9, (1.7, 0.9, 1.7))
    cyl((0, 0, 35.2), 8.4, 3.2, "Cuerpo", n=20)
    cyl((0, 0, 38.2), 8.8, 0.5, "Luz", n=20)
    sphere((0, 0, 38.7), 8.2, "Techo", seg=20, rings=10, hemi=True)
    cyl((0, 0, 46.6), 0.35, 3, "Metal", n=6)
    sphere((0, 0, 49.8), 0.7, "Luz", seg=8, rings=6)
    for sx in (-1, 1):
        cyl((sx * 11.5, -11.5, 35.2), 3, 1.6, "Cuerpo", n=12)
        sphere((sx * 11.5, -11.5, 36.8), 2.9, "Techo", seg=12, rings=8, hemi=True)
    box((10, 10.5, 40.2), (6, 6, 10), "Cuerpo", bevel=0.2)  # torre de viento
    for i in range(4):
        box((10, 7.4, 41.5 + i * 1.5), (4.6, 0.3, 0.6), "Metal")
        box((6.9, 10.5, 41.5 + i * 1.5), (0.3, 4.6, 0.6), "Metal")
    box((10, 10.5, 45.5), (7, 7, 0.7), "Cuerpo")
    enter("Siroco", 15, -15, 15, 12.4, dh=9.6)


def siroco_casa():
    sec("Base")
    body(box((0, 0, 10), (26, 26, 20), "Cuerpo", bevel=0.45))
    body(box((0, 0, 0.6), (27.2, 27.2, 1.2), "Cuerpo", bevel=0.2))
    arch_door(-13.3, 5, 8.6)
    box((0, -13.2, 4.4), (6.4, 0.5, 9.2), "Cuerpo")
    cyl((0, -12.95, 6.1), 3.2, 0.5, "Cuerpo", n=16, rot=(PI / 2, 0, 0))
    arch_door(-13.5, 5, 8.6)
    box((0, -15.6, 10.6), (12, 4.6, 0.25), "Toldo", rot=(math.radians(-14), 0, 0))
    for sx in (-1, 1):
        box((sx * 5.6, -17.6, 5), (0.3, 0.3, 10), "Metal")
    windows(26, 26, 15.4, 3, 2.1, 3, faces=(0, 1, 2), arch=True)
    windows(26, 26, 6, 2, 2.1, 3, faces=(1, 2), arch=True)
    # escalera exterior a la azotea (lado derecho)
    for i in range(10):
        box((14.6, -11 + i * 2.2, 1 + i * 2), (3, 2.2, 2 + i * 0.001), "Cuerpo")
    ledge(19.7, 26, 26, 0.7, 0.4, "Cuerpo")
    merlons(20, 26, 26, 7, (1.6, 0.8, 1.5))
    cyl((-5, 4, 20), 6.6, 2.4, "Cuerpo", n=16)
    sphere((-5, 4, 22.4), 6.4, "Techo", seg=16, rings=8, hemi=True)
    cyl((-5, 4, 28.6), 0.3, 2.2, "Metal", n=6)
    sphere((-5, 4, 31), 0.55, "Luz", seg=8, rings=6)
    box((8, 7, 21.5), (6.6, 5, 0.25), "Toldo", rot=(0, math.radians(8), 0))
    for dx, dy in ((5, 5), (11, 5), (5, 9.4), (11, 9.4)):
        box((dx, dy, 20.8), (0.3, 0.3, 1.8), "Metal")
    for sx in (-1, 1):
        sphere((sx * 9.6, -14.6, 1.2), 1.15, "Techo", seg=10, rings=8, squash=(1, 1, 1.3))
    box((-9.6, -14.4, 3.6), (0.3, 0.3, 2), "Hoja")
    sphere((-9.6, -14.6, 4.6), 1.3, "Hoja", seg=8, rings=6, squash=(1, 1, 0.7))
    enter("Siroco", 13, -13, 13, 10.6, dw=7, dh=8.4, home=True)


# ---------------------------------------------------------------------------
# TÁLASA: blanco, redondo, anillos de cristal y luz azul
# ---------------------------------------------------------------------------
def talasa_bloque():
    sec("Base")
    body(cyl((0, 0, 0), 16.4, 3, "Cuerpo", n=32, r2=15))
    body(cyl((0, 0, 3), 15, 11, "Cuerpo", n=32))
    body(cyl((0, 0, 4.2), 15.15, 6.4, "Cristal", n=32))
    box((0, -15.1, 4.8), (6.4, 1.4, 8.4), "Metal", bevel=0.5)
    box((0, -15.75, 4.4), (4.6, 0.4, 7), "Cristal")
    box((0, -15.8, 9.4), (7, 0.4, 0.5), "Luz")
    cyl((0, 0, 12.5), 15.35, 0.5, "Luz", n=32)
    for i in range(8):
        a = i * PI / 4 + PI / 8
        box((math.cos(a) * 15.3, math.sin(a) * 15.3, 7), (1.0, 0.9, 14), "Metal", rot=(0, 0, a), bevel=0.15)
    cyl((0, -17.4, 0), 4.6, 0.6, "Metal", n=20)
    for sx in (-1, 1):
        cyl((sx * 5.4, -19, 0), 0.25, 3.4, "Metal", n=6)
        sphere((sx * 5.4, -19, 3.6), 0.6, "Luz", seg=8, rings=6)

    sec("Medio")
    cyl((0, 0, 14), 14, 20, "Cuerpo", n=32)
    cyl((0, 0, 19.6), 14.15, 7.6, "Cristal", n=32)
    cyl((0, 0, 14.3), 14.3, 0.4, "Luz", n=32)
    cyl((0, 0, 29.6), 15.6, 0.6, "Metal", n=32)
    cyl((0, 0, 30.2), 15.7, 0.3, "Luz", n=32)
    for i in range(8):
        a = i * PI / 4 + PI / 8
        box((math.cos(a) * 14.2, math.sin(a) * 14.2, 24), (0.9, 0.9, 20), "Metal", rot=(0, 0, a), bevel=0.12)
    for i in range(4):
        a = i * PI / 2
        box((math.cos(a) * 15.2, math.sin(a) * 15.2, 31.2), (4.2, 3.4, 1.6), "Cuerpo", rot=(0, 0, a + PI / 2), bevel=0.4)  # balcones cápsula

    sec("Tope")
    cyl((0, 0, 34), 14, 1, "Cuerpo", n=32)
    cyl((0, 0, 35), 14, 2.6, "Cuerpo", n=32, r2=17.4)
    cyl((0, 0, 37.6), 17.4, 1.2, "Cuerpo", n=32)
    cyl((0, 0, 37.9), 17.6, 0.45, "Luz", n=32)
    sphere((0, 0, 38.8), 11.5, "Cristal", seg=24, rings=10, hemi=True, squash=(1, 1, 0.75))
    cyl((0, 0, 38.8), 12, 0.6, "Metal", n=32)
    cyl((0, 0, 38.8), 1.1, 7.4, "Luz", n=10)
    cyl((0, 0, 47.2), 0.3, 9, "Metal", n=6, r2=0.08)
    sphere((0, 0, 56.3), 0.6, "Luz", seg=8, rings=6)
    for i in range(3):
        a = i * 2.1 + 0.5
        dish(math.cos(a) * 14.8, math.sin(a) * 14.8, 38.8, 1.5)
    enter("Talasa", 15, -15, 15, 12, round_=True)


def talasa_casa():
    sec("Base")
    body(cyl((0, 0, 0), 13.6, 2, "Cuerpo", n=28, r2=12.6))
    body(cyl((0, 0, 2), 12.6, 12, "Cuerpo", n=28))
    body(cyl((0, 0, 5), 12.75, 5.4, "Cristal", n=28))
    box((0, -12.7, 4.4), (5.4, 1.4, 7.6), "Metal", bevel=0.5)
    box((0, -13.35, 4), (3.8, 0.4, 6.2), "Cristal")
    cyl((0, 0, 13.6), 12.9, 0.45, "Luz", n=28)
    for i in range(6):
        a = i * PI / 3 + PI / 6
        box((math.cos(a) * 12.8, math.sin(a) * 12.8, 7), (0.9, 0.9, 14), "Metal", rot=(0, 0, a), bevel=0.12)
    sphere((0, 0, 14), 12.6, "Techo", seg=28, rings=10, hemi=True, squash=(1, 1, 0.62))
    cyl((0, -5, 17.6), 3.2, 0.5, "Cristal", n=16, rot=(math.radians(-50), 0, 0))  # claraboya
    cyl((0, 0, 21.7), 1.6, 0.6, "Metal", n=12)
    cyl((0, 0, 22.3), 0.9, 1.2, "Luz", n=10)
    cyl((0, 0, 23.5), 0.2, 6, "Metal", n=6, r2=0.06)
    cyl((0, -15.4, 0), 4, 0.5, "Metal", n=18)
    for sx in (-1, 1):
        box((sx * 9.5, -11.2, 1.3), (3.6, 2, 2.6), "Cuerpo", rot=(0, 0, sx * 0.5), bevel=0.6)
        sphere((sx * 9.5, -11.2, 3.1), 1.4, "Hoja", seg=8, rings=6, squash=(1.1, 0.7, 0.8))
    enter("Talasa", 12.6, -12.6, 12.6, 11.4, dw=7, dh=8.4, round_=True, home=True)


# ---------------------------------------------------------------------------
# NIVALIS: piedra, ojivas, tejados de pico y nieve
# ---------------------------------------------------------------------------
def lancet(face, u, z, ww, wh, depth=0.3):
    on_face(face, u, z, depth / 2 - 0.05, (ww, depth, wh), "Cristal")
    cx, cy, a, _ = face
    ax, ay = math.cos(a), math.sin(a)
    nx, ny = math.sin(a), -math.cos(a)
    o = frustum((cx + ax * u + nx * (depth / 2 - 0.05), cy + ay * u + ny * (depth / 2 - 0.05), z + wh / 2), ww, depth, 0.05, depth, ww * 1.1, "Cristal")
    o.rotation_euler = (0, 0, a)


def nivalis_bloque():
    sec("Base")
    box((0, 0, 7), (30, 30, 14), "Cuerpo", bevel=0.25)
    body(box((0, 0, 0.8), (31.6, 31.6, 1.6), "Cuerpo", bevel=0.2))
    box((0, -15.25, 3.6), (6, 0.6, 7.2), "Metal")
    frustum((0, -15.25, 7.2), 6, 0.6, 0.05, 0.6, 3.6, "Metal")
    box((0, -15.5, 3.9), (7.4, 0.5, 7.8), "Cuerpo")
    frustum((0, -15.5, 7.8), 7.4, 0.5, 0.05, 0.5, 4.4, "Cuerpo")
    box((0, -15.8, 3.6), (5.2, 0.4, 7.2), "Metal")
    frustum((0, -15.8, 7.2), 5.2, 0.4, 0.05, 0.4, 3.1, "Metal")
    for sx in (-1, 1):
        for y in (-14.4, 0, 14.4):
            frustum((sx * 15.4, y, 0), 3, 4, 1.6, 2.6, 14, "Cuerpo")
        frustum((sx * 9, -15.6, 0), 3.4, 2.6, 2.2, 1.4, 14, "Cuerpo")
        box((sx * 4.6, -16.2, 7.2), (0.25, 1.2, 0.25), "Metal")
        box((sx * 4.6, -16.8, 6.4), (0.9, 0.9, 1.3), "Luz")
        box((sx * 4.6, -16.8, 7.2), (1.2, 1.2, 0.3), "Metal")
        box((sx * 12.4, -17.2, 0.5), (6.6, 3.6, 1.0), "Nieve", bevel=0.4, rot=(0, 0, sx * 0.1))
    fs = faces4(30, 30)
    for fi in (1, 2, 3):
        for u in (-6.6, 6.6):
            lancet(fs[fi], u, 6.4, 1.9, 5)
    ledge(13.6, 30, 30, 0.8, 0.6, "Cuerpo")
    box((0, -15.6, 14.15), (31, 1.0, 0.35), "Nieve")

    sec("Medio")
    box((0, 0, 24), (29, 29, 20), "Cuerpo")
    fs = faces4(29, 29)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((sx * 14.2, sy * 14.2, 24), (2.6, 2.6, 20), "Cuerpo", bevel=0.2)
    for fi in range(4):
        for u in (-4.6, 4.6):
            on_face(fs[fi], u, 24, 0.25, (1.2, 0.6, 20), "Cuerpo")
        for u in (-9, 0, 9):
            lancet(fs[fi], u, 22.6, 2.0, 9)
            on_face(fs[fi], u, 17.4, 0.4, (3, 0.9, 0.5), "Cuerpo")
            on_face(fs[fi], u, 17.75, 0.45, (3, 0.9, 0.25), "Nieve")
    for z in (14.4, 33.5):
        ledge(z, 29, 29, 0.7, 0.55, "Cuerpo")
    box((0, 0, 33.95), (30.1, 30.1, 0.3), "Nieve")
    box((-14.9, 6, 26), (0.8, 3.2, 3.4), "Metal", bevel=0.1)  # balcón de hierro
    box((-15.4, 6, 24.4), (1.8, 4, 0.3), "Metal")

    sec("Tope")
    box((0, 0, 34.6), (31, 31, 1.2), "Cuerpo", bevel=0.2)
    frustum((0, 0, 35.2), 30.4, 30.4, 3.4, 3.4, 17, "Techo")
    frustum((0, 0, 42.6), 17.9, 17.9, 3.9, 3.9, 9.9, "Nieve")
    cyl((0, 0, 52), 0.35, 5, "Techo", n=6, r2=0.08)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl((sx * 14.6, sy * 14.6, 35.2), 1.5, 4.4, "Cuerpo", n=6)
            cyl((sx * 14.6, sy * 14.6, 39.6), 1.9, 6, "Techo", n=6, r2=0.05)
            cyl((sx * 14.6, sy * 14.6, 43), 0.95, 2.7, "Nieve", n=6, r2=0.05)
    # buhardilla al frente
    box((0, -11.4, 38.2), (5, 4, 5), "Cuerpo")
    o = gable((0, -11.4, 40.7), 4.6, 5.6, 2.6, "Techo")
    o.rotation_euler = (0, 0, PI / 2)
    box((0, -13.45, 38.4), (2.4, 0.3, 3), "Cristal")
    box((9, 6, 41), (3, 3, 9), "Cuerpo", bevel=0.15)
    box((9, 6, 45.7), (3.6, 3.6, 0.5), "Nieve", bevel=0.15)
    enter("Nivalis", 15, -15, 15, 12.4)


def nivalis_casa():
    sec("Base")
    body(box((0, 0, 10), (26, 26, 20), "Cuerpo", bevel=0.2))
    body(box((0, 0, 0.7), (27.4, 27.4, 1.4), "Cuerpo", bevel=0.2))
    box((0, -13.25, 3.6), (4.6, 0.6, 7.2), "Metal")
    frustum((0, -13.25, 7.2), 4.6, 0.6, 0.05, 0.6, 2.8, "Metal")
    box((0, -15, 9.6), (8, 3.6, 0.4), "Techo", rot=(math.radians(-22), 0, 0))
    box((0, -15, 9.95), (8.2, 3.7, 0.3), "Nieve", rot=(math.radians(-22), 0, 0))
    for sx in (-1, 1):
        box((sx * 3.6, -16.4, 4.4), (0.4, 0.4, 8.8), "Metal")
        box((sx * 13, -13, 10), (1.2, 1.2, 20), "Metal")  # vigas de madera
        box((sx * 13, 13, 10), (1.2, 1.2, 20), "Metal")
        box((sx * 4.6, -13.9, 6), (0.8, 0.8, 1.2), "Luz")
        box((sx * 9, -15, 0.45), (5.4, 3.4, 0.9), "Nieve", bevel=0.35)
    fs = faces4(26, 26)
    for fi in range(4):
        on_face(fs[fi], 0, 10.6, 0.15, (26, 0.5, 0.9), "Metal")
        for u in (-7.6, 7.6):
            if fi != 0:
                lancet(fs[fi], u, 5.4, 2, 3.4)
            lancet(fs[fi], u, 14.6, 2, 3.4)
            on_face(fs[fi], u, 12.3, 0.4, (3, 0.8, 0.4), "Metal")
            on_face(fs[fi], u, 12.6, 0.45, (3, 0.8, 0.22), "Nieve")
    ledge(19.7, 26, 26, 0.6, 0.6, "Metal")
    gable((0, 0, 20), 28, 28.4, 13, "Techo")
    gable((0, 0, 20.7), 28.3, 26, 12.7, "Nieve")
    box((0, 0, 20.1), (25.6, 26.6, 0.2), "Cuerpo")
    # hastiales de piedra (cierran el tejado por los lados)
    for sx in (-1, 1):
        o = gable((sx * 13.4, 0, 20), 0.8, 26, 12, "Cuerpo")
        box((sx * 13.9, 0, 24.4), (0.3, 2.2, 3.2), "Cristal")
    box((7, 6, 30), (3.2, 3.2, 12), "Cuerpo", bevel=0.15)
    box((7, 6, 36.2), (3.8, 3.8, 0.5), "Nieve", bevel=0.15)
    box((-12, -14.6, 1.2), (2.4, 2.4, 2.4), "Metal", bevel=0.1)
    cyl((-9, -14.8, 0), 1.1, 2.8, "Metal", n=10)
    box((-10.6, -14.7, 2.9), (5.6, 3, 0.35), "Nieve", bevel=0.12)
    enter("Nivalis", 13, -13, 13, 10.2, dw=7, dh=8.4, home=True)


# ---------------------------------------------------------------------------
# MIASMA: chapa, tuberías, depósitos y luz verde
# ---------------------------------------------------------------------------
def miasma_bloque():
    sec("Base")
    body(box((0, 0, 7.6), (30, 30, 12.8), "Cuerpo", bevel=0.15))
    for sx in (-1, 1):
        for sy in (-1, 1):
            box((sx * 13.4, sy * 13.4, 0.8), (4.4, 4.4, 1.6), "Metal", bevel=0.15)
        pipe_v(sx * 15.9, -12, 0, 14, 0.9)
    box((0, 0, 0.9), (26, 26, 0.6), "Metal")
    box((0, -15.2, 5.4), (6.4, 0.6, 7.6), "Metal", bevel=0.2)
    cyl((0, -15.4, 6), 1.3, 0.4, "Cristal", n=12, rot=(PI / 2, 0, 0))
    box((0, -15.5, 9.8), (7.4, 0.4, 0.6), "Luz")
    box((0, -17.2, 1.3), (8, 4, 0.4), "Metal")
    box((0, -18.6, 0.6), (8, 1.4, 0.35), "Metal", rot=(math.radians(28), 0, 0))
    pipe_x(-15, 15, -16.2, 11.6, 1.1, flanges=4)
    for sx in (-1, 1):
        cyl((sx * 10, -17.4, 1.2), 2.5, 7, "Cristal", n=14)
        cyl((sx * 10, -17.4, 1.5), 2.1, 4.6 + sx * 0.8, "Luz", n=12)
        cyl((sx * 10, -17.4, 0.6), 2.8, 0.8, "Metal", n=14)
        cyl((sx * 10, -17.4, 8.2), 2.8, 0.7, "Metal", n=14)
        cyl((sx * 10, -17.4, 8.9), 0.6, 2.2, "Metal", n=8)
        box((sx * 15.4, 4, 5), (0.8, 6, 4), "Metal", bevel=0.1)
        for i in range(4):
            box((sx * 15.9, 4, 3.6 + i * 0.9), (0.3, 5.4, 0.3), "Cuerpo")
    ledge(13.7, 30, 30, 0.6, 0.5)

    sec("Medio")
    box((0, 0, 24), (29, 29, 20), "Cuerpo")
    fs = faces4(29, 29)
    for fi in range(4):
        for u in (-14.2, -7.1, 0, 7.1, 14.2):
            on_face(fs[fi], u, 24, 0.2, (0.8, 0.7, 20), "Metal")
        on_face(fs[fi], 0, 24.4, 0.25, (29, 0.5, 0.45), "Luz")
    for z in (19.4, 29.6):
        for fi in (0, 1):
            cx, cy, a, _ = fs[fi]
            for u in (-10.6, -3.5, 3.5, 10.6):
                ny = -math.cos(a)
                cyl((cx + math.cos(a) * u, cy + ny * 0.3, z), 1.5, 0.4, "Cristal", n=12, rot=(PI / 2 * (1 if fi == 0 else -1), 0, 0))
                torus((cx + math.cos(a) * u, cy + ny * 0.35, z), 1.6, 0.22, "Metal", n=12, m=6, rot=(PI / 2, 0, 0))
        for fi in (2, 3):
            for u in (-7, 7):
                on_face(fs[fi], u, z, 0.3, (4.4, 0.7, 2.6), "Metal", bevel=0.1)
    pipe_v(-11.6, -15.6, 14, 20, 0.75)
    pipe_v(11.6, -15.6, 14, 20, 0.75)
    pipe_v(15.7, 10, 14, 20, 0.9)
    box((-16, 0, 20.2), (2.4, 29, 0.3), "Metal")  # pasarela de servicio
    box((-17.1, 0, 22.4), (0.2, 29, 0.25), "Metal")
    for i in range(6):
        box((-17.1, -13.5 + i * 5.4, 21.3), (0.2, 0.2, 2.2), "Metal")
    for z in (14.4, 33.5):
        ledge(z, 29, 29, 0.5, 0.45)

    sec("Tope")
    box((0, 0, 34.5), (30.4, 30.4, 1), "Metal")
    for s in (-1, 1):
        box((0, s * 15, 37.2), (30.4, 0.2, 0.25), "Metal")
        box((s * 15, 0, 37.2), (0.2, 30.4, 0.25), "Metal")
        for i in range(6):
            box((-15 + i * 6, s * 15, 36.1), (0.2, 0.2, 2.2), "Metal")
            box((s * 15, -15 + i * 6, 36.1), (0.2, 0.2, 2.2), "Metal")
    tank(-7.5, 6.5, 35, 4.4, 6.4, "Techo")
    tank(4, 8.5, 35, 3, 4.6, "Techo")
    cyl((-7.5, 6.5, 37.4), 4.55, 0.7, "Luz", n=12)
    for x, h in ((9.5, 15), (12.6, 11)):
        cyl((x, -7, 35), 1.5, h, "Metal", n=10)
        cyl((x, -7, 35 + h - 1.1), 1.72, 0.8, "Luz", n=10)
        cyl((x, -7, 35 + h * 0.5), 1.8, 0.5, "Metal", n=10)
    box((-6, -8, 37.2), (9, 6.4, 4.4), "Cuerpo", bevel=0.15)
    for i in range(2):
        cyl((-8.4 + i * 4.8, -8, 39.4), 1.7, 0.6, "Metal", n=12)
    pipe_x(-10, 9.5, -2.4, 36.2, 0.7, flanges=3)
    cyl((0, 0, 35), 0.3, 17, "Metal", n=6, r2=0.08)
    sphere((0, 0, 52.4), 1.1, "Luz", seg=8, rings=6)
    enter("Miasma", 15, -15, 15, 12.6, floor=1.5, dh=8.6, ramp=True)


def miasma_casa():
    sec("Base")
    for sx in (-1, 1):
        for sy in (-1, 1):
            cyl((sx * 11, sy * 11, 0), 0.8, 3, "Metal", n=8)
            box((sx * 11, sy * 11, 0.3), (2.6, 2.6, 0.6), "Metal")
    box((0, 0, 3.3), (27, 27, 0.6), "Metal")
    body(box((0, 1, 8.4), (26, 22, 9.6), "Cuerpo", bevel=0.15))  # contenedor de abajo
    box((-3, -1, 16.6), (20, 20, 6.8), "Cuerpo", bevel=0.15)  # contenedor de arriba, desplazado
    for i in range(9):
        box((-12 + i * 3, -10.1, 8.4), (0.5, 0.4, 9.2), "Metal")
        box((-12 + i * 3, 12.1, 8.4), (0.5, 0.4, 9.2), "Metal")
    for i in range(7):
        box((-12 + i * 3, -11.1, 16.6), (0.5, 0.4, 6.4), "Metal")
    box((0, -10.3, 7.6), (5, 0.6, 7.6), "Metal", bevel=0.2)
    cyl((0, -10.5, 8.4), 1.1, 0.4, "Cristal", n=12, rot=(PI / 2, 0, 0))
    box((0, -10.5, 11.9), (6, 0.4, 0.5), "Luz")
    box((0, -12.6, 3.5), (8, 4.2, 0.35), "Metal")
    box((0, -15.8, 1.9), (4, 4.6, 0.35), "Metal", rot=(math.radians(36), 0, 0))
    for sx in (-1, 1):
        box((sx * 3.9, -14.6, 5.2), (0.2, 0.2, 3.2), "Metal")
        box((sx * 3.9, -12.6, 6.7), (0.2, 4.2, 0.2), "Metal")
        cyl((sx * 8, -10.3, 8), 1.5, 0.4, "Cristal", n=12, rot=(PI / 2, 0, 0))
        torus((sx * 8, -10.35, 8), 1.6, 0.22, "Metal", n=12, m=6, rot=(PI / 2, 0, 0))
    cyl((-7, -11.3, 17), 1.5, 0.4, "Cristal", n=12, rot=(PI / 2, 0, 0))
    box((2, -11.2, 17), (5.4, 0.3, 3), "Cristal")
    tank(9.5, 4, 13.2, 2.8, 4.4, "Techo")
    cyl((9.5, 4, 15), 2.92, 0.6, "Luz", n=12)
    pipe_v(13.6, -6, 0, 13, 0.7)
    pipe_x(-13, 13, 12.6, 5, 0.8, flanges=3)
    cyl((-8, 4, 20), 1.1, 7, "Metal", n=8)
    cyl((-8, 4, 26.2), 1.3, 0.6, "Luz", n=8)
    antenna(2, 3, 20, 8)
    box((4, 9.5, 14), (7, 5, 0.3), "Metal")  # terraza
    box((7.4, 9.5, 15.3), (0.2, 5, 0.2), "Metal")
    enter("Miasma", 13, -10, 12, 12.6, floor=3.9, dw=7, dh=8, ramp=True, home=True)


# ---------------------------------------------------------------------------
# Objetos de calle (para todos los planetas; el color lo pone cada uno)
# ---------------------------------------------------------------------------
def calle_vehiculo():
    """Deslizador aparcado (12 de largo a lo largo de X)."""
    sec("Base")
    box((0, 0, 2.1), (11, 5, 1.5), "Cuerpo", bevel=0.5)
    frustum((-3.6, 0, 2.6), 4, 4.6, 2.6, 3.4, 1.0, "Cuerpo")
    o = sphere((0.6, 0, 2.7), 2.4, "Cristal", seg=14, rings=8, hemi=True, squash=(1.5, 0.85, 0.62))
    frustum((4.6, 0, 2.6), 2.4, 4.4, 0.4, 3.6, 0.5, "Cuerpo")
    box((5.3, 0, 3.6), (0.3, 4.6, 0.25), "Metal")
    for sy in (-1, 1):
        box((5.3, sy * 2.1, 3.2), (0.3, 0.3, 1), "Metal")
        box((-5.5, sy * 1.6, 2.2), (0.3, 1.1, 0.45), "Luz")
        box((5.5, sy * 1.6, 2.3), (0.3, 1.3, 0.3), "Luz")
        for x in (-3.4, 3.4):
            cyl((x, sy * 2.9, 1.0), 1.15, 1.3, "Metal", n=12)
            cyl((x, sy * 2.9, 0.8), 0.95, 0.25, "Luz", n=12)
            box((x, sy * 2.5, 1.9), (1.4, 1, 0.5), "Metal")
    box((0, 0, 1.3), (9, 3.4, 0.4), "Metal")
    for x in (-3.6, 3.6):
        box((x, 0, 0.5), (0.5, 4.4, 0.25), "Metal")  # patines
        for sy in (-1, 1):
            box((x, sy * 1.6, 0.9), (0.3, 0.3, 0.8), "Metal")


def calle_cajas():
    """Contenedores de carga de otra galaxia: botes hexagonales con juntas de luz, cápsulas y un dron de carga."""
    sec("Base")
    for (x, y, r, h, a) in ((0, 0, 1.7, 3.4, 0), (3.3, 0.5, 1.4, 2.8, 0.4), (-3.2, 0.7, 1.5, 3.0, 0.2)):
        cyl((x, y, 0), r, h, "Cuerpo", n=6, rot=(0, 0, a), bevel=0.1)
        cyl((x, y, h * 0.5 - 0.1), r * 1.03, 0.2, "Luz", n=6, rot=(0, 0, a))
        cyl((x, y, h), r * 0.85, 0.3, "Metal", n=6, rot=(0, 0, a))
        cyl((x, y, 0), r * 1.06, 0.3, "Metal", n=6, rot=(0, 0, a))
    cyl((0.2, 0.3, 3.7), 1.2, 2.2, "Cuerpo", n=6, rot=(0, 0, 0.5), bevel=0.1)
    cyl((0.2, 0.3, 4.7), 1.24, 0.16, "Luz", n=6, rot=(0, 0, 0.5))
    for y in (-2.7, 2.9):  # cápsulas tumbadas
        cyl((-2.2, y, 0.9), 0.85, 4.4, "Metal", n=10, rot=(0, PI / 2, 0))
        sphere((-2.2, y, 0.9), 0.85, "Metal", seg=10, rings=6)
        sphere((2.2, y, 0.9), 0.85, "Metal", seg=10, rings=6)
        cyl((-0.6, y, 0.9), 0.9, 1.2, "Cristal", n=10, rot=(0, PI / 2, 0))
        cyl((-0.4, y, 0.9), 0.6, 0.8, "Luz", n=8, rot=(0, PI / 2, 0))
    # dron de carga flotando
    sphere((3.6, -1.6, 5), 0.9, "Metal", seg=12, rings=8, squash=(1.3, 1.3, 0.6))
    cyl((3.6, -1.6, 4.5), 0.5, 0.15, "Luz", n=10)
    sphere((3.6, -2.7, 5), 0.3, "Luz", seg=8, rings=6)


def calle_tuberias():
    sec("Base")
    box((0, 0, 0.3), (12, 3.6, 0.6), "Metal", bevel=0.1)
    for i, (z, r) in enumerate(((1.6, 0.8), (3.5, 0.6), (5.1, 0.45))):
        pipe_x(-6, 6, -0.6 + i * 0.5, z, r, flanges=3)
    for x in (-5, 0, 5):
        box((x, 0, 2.9), (0.5, 3, 5.4), "Metal")
    for x in (-2.6, 2.6):
        cyl((x, -1.5, 1.6), 0.3, 1.4, "Metal", n=6, rot=(PI / 2, 0, 0))
        torus((x, -2.9, 1.6), 0.9, 0.16, "Luz", n=12, m=6, rot=(PI / 2, 0, 0))
        for k in range(2):
            box((x, -2.9, 1.6), (1.7, 0.14, 0.14), "Luz", rot=(0, k * PI / 2, 0))
    tank(4.4, 1.8, 0.6, 1.3, 3.6)
    cyl((-4.4, 1.6, 0.6), 0.45, 7.4, "Metal", n=8)
    cyl((-4.4, 1.6, 7.6), 0.9, 0.5, "Metal", n=8)
    box((0.8, 1.9, 2.2), (2, 0.8, 2.6), "Metal", bevel=0.1)
    box((0.8, 1.45, 2.6), (1.4, 0.15, 1.2), "Luz")


def calle_generador():
    """Celda de energía: un núcleo de luz dentro de cristal, sujeto por tres garras, con cristales cargándose."""
    sec("Base")
    cyl((0, 0, 0), 2.6, 0.7, "Metal", n=6, bevel=0.1)
    cyl((0, 0, 0.7), 1.5, 5, "Cristal", n=12)
    cyl((0, 0, 0.9), 1.0, 4.6, "Luz", n=10)
    cyl((0, 0, 5.7), 1.9, 0.6, "Metal", n=6)
    gem((0, 0, 7.2), 0.7, "Luz")
    torus((0, 0, 3.2), 2.1, 0.16, "Luz", n=20, m=6)
    for i in range(3):
        a = i * 2.094 + 0.5
        cx, cy = math.cos(a) * 2.1, math.sin(a) * 2.1
        box((cx, cy, 3.2), (0.5, 0.7, 5.6), "Cuerpo", rot=(0, 0, a), bevel=0.12)
        box((math.cos(a) * 1.75, math.sin(a) * 1.75, 6), (1.2, 0.6, 0.5), "Cuerpo", rot=(0, 0, a))
    for i, (x, y, h) in enumerate(((3.9, 0.6, 2.4), (4.6, -0.9, 1.7), (-4.2, 0.4, 2.0))):
        cyl((x, y, 0), 0.75, 0.4, "Metal", n=6)
        cyl((x, y, 0.4), 0.5, h, "Toldo", n=6, r2=0.05)
        cyl((x, y, 0.4), 0.56, 0.12, "Luz", n=6)
    cyl((1.2, 1.2, 0.15), 0.14, 3.2, "Metal", n=6, rot=(0, PI / 2, 0.2))
    cyl((-1.2, -1.0, 0.15), 0.14, 3.2, "Metal", n=6, rot=(0, -PI / 2, 0.15))


def calle_puesto():
    """Puesto de hologramas: columna central, techo que flota y pantallas de luz alrededor."""
    sec("Base")
    cyl((0, 0, 0), 3.4, 0.4, "Metal", n=8)
    cyl((0, 0, 0.4), 3.1, 0.12, "Luz", n=8)
    cyl((0, 0, 0.4), 0.9, 5.2, "Cuerpo", n=8, r2=0.6)
    cyl((0, 0, 2.6), 2.6, 0.35, "Cuerpo", n=8, bevel=0.08)  # mostrador en anillo
    cyl((0, 0, 2.45), 2.7, 0.12, "Luz", n=8)
    cyl((0, 0, 6.6), 3.8, 0.4, "Toldo", n=8, r2=1.2)  # techo que flota
    cyl((0, 0, 6.45), 3.5, 0.12, "Luz", n=8)
    gem((0, 0, 7.9), 0.6, "Luz")
    for i in range(4):
        a = i * PI / 2 + PI / 4
        box((math.cos(a) * 2.9, math.sin(a) * 2.9, 4.6), (0.1, 2.4, 1.6), "Luz", rot=(0, 0, a))
        gem((math.cos(a + 0.8) * 1.8, math.sin(a + 0.8) * 1.8, 3.4), 0.3, ("Cristal", "Luz")[i % 2])
    hover((4.6, 0.8, 1.3), 1.0, 0.5)  # asiento flotante


def calle_jardinera():
    """Planta de otro mundo en su vaina, con bulbos que brillan, y un banco que levita."""
    sec("Base")
    sphere((0, 0.6, 0.9), 2.4, "Cuerpo", seg=14, rings=8, squash=(1.5, 0.8, 0.5))
    cyl((0, 0.6, 1.2), 2.6, 0.2, "Luz", n=16)
    cyl((0, 0.6, 1.25), 2.4, 0.25, "Metal", n=16)
    for i, (dx, lean, h) in enumerate(((-2.2, -0.35, 4.2), (-0.7, -0.1, 5.6), (0.9, 0.15, 4.8), (2.3, 0.4, 3.6))):
        o = cyl((dx, 0.6, 1.3), 0.28, h, "Hoja", n=6, r2=0.1)
        o.rotation_euler = (0, lean, 0)
        tx, tz = dx + math.sin(lean) * h, 1.3 + math.cos(lean) * h
        sphere((tx, 0.6, tz), 0.55 + (i % 2) * 0.15, "Luz", seg=10, rings=6)
        sphere((tx, 0.6, tz - 0.5), 0.9, "Hoja", seg=8, rings=6, squash=(1.2, 1.2, 0.25))
    for dx in (-3.2, 3.2):
        sphere((dx, 0.6, 1.9), 0.8, "Hoja", seg=8, rings=6, squash=(1, 1, 1.4))
    # banco que levita
    box((0, -2.6, 1.4), (7, 1.8, 0.35), "Metal", bevel=0.15)
    box((0, -2.6, 1.15), (6.2, 1.2, 0.12), "Luz")
    box((0, -1.75, 2.3), (7, 0.25, 1.2), "Cristal")


def half_pipe(c, r, L, hz, group, n=10):
    """Bóveda de medio cañón a lo largo de Y (largo L), ancho 2r y alto hz, con la BASE centrada en c."""
    v = []
    for y in (-L / 2, L / 2):
        for i in range(n + 1):
            a = PI * i / n
            v.append((r * math.cos(a), y, hz * math.sin(a)))
    f = []
    for i in range(n):
        f.append((i, i + 1, n + 1 + i + 1, n + 1 + i))
    f.append(tuple(range(n, -1, -1)))
    f.append(tuple(range(n + 1, 2 * n + 2)))
    f.append((0, n + 1, 2 * n + 1, n))
    return mesh_obj(v, f, group, c)


# ---------------------------------------------------------------------------
# Para todos los planetas (el color y el material los pone cada uno)
# ---------------------------------------------------------------------------
def ciudad_nave():
    """Nave industrial / hangar: portón grande abierto, bóveda, costillas, tuberías y luces de pista."""
    sec("Base")
    body(box((0, 0, 7), (30, 30, 14), "Cuerpo", bevel=0.2))
    half_pipe((0, 0, 14), 15, 30.6, 6.4, "Techo")
    for y in (-15.2, -7.6, 0, 7.6, 15.2):
        for sx in (-1, 1):
            box((sx * 15.25, y, 7), (0.7, 0.9, 14), "Metal")
        half_pipe((0, y, 14.05), 15.35, 0.9, 6.75, "Metal", n=8)
    # el marco del portón, con balizas
    for sx in (-1, 1):
        box((sx * 6.9, -15.5, 5.6), (1.4, 1.2, 11.2), "Metal", bevel=0.15)
        box((sx * 6.9, -16.15, 5.6), (0.4, 0.2, 10), "Luz")
        box((sx * 11.6, -15.3, 3.4), (4, 0.5, 2.6), "Metal", bevel=0.1)  # rejillas
        for i in range(3):
            box((sx * 11.6, -15.6, 2.6 + i * 0.8), (3.4, 0.2, 0.25), "Cuerpo")
        pipe_v(sx * 15.9, 11, 0, 14, 0.7)
        cyl((sx * 9, -19, 0), 0.5, 0.25, "Luz", n=8)  # luces de pista
        cyl((sx * 9, -23, 0), 0.5, 0.25, "Luz", n=8)
    box((0, -15.5, 11.8), (15.2, 1.2, 1.4), "Metal", bevel=0.15)
    box((0, -16.15, 11.8), (12, 0.2, 0.7), "Luz")
    box((0, -15.4, 16.4), (10, 0.5, 2.4), "Metal")
    box((0, -15.7, 16.4), (9, 0.2, 1.7), "Luz")
    pipe_x(-15, 15, 15.9, 9, 0.8, flanges=3)
    for x in (-6, 6):
        cyl((x, 6, 19.2), 1.3, 3, "Metal", n=8)
        cyl((x, 6, 22), 1.5, 0.5, "Luz", n=8)
    tank(-17.6, -4, 0, 2, 5)
    enter("Nave", 15, -15, 15, 13, dw=12, dh=10.4)


def ciudad_cupula():
    """Edificio de cúpula: tambor redondo con anillo de cristal, cúpula con nervios y aguja de luz."""
    sec("Base")
    body(cyl((0, 0, 0), 16.2, 2.4, "Cuerpo", n=20, r2=15))
    body(cyl((0, 0, 2.4), 15, 11.6, "Cuerpo", n=20))
    cyl((0, 0, 13), 15.5, 1, "Metal", n=20)
    cyl((0, 0, 12.6), 15.6, 0.35, "Luz", n=20)
    for i in range(8):
        a = i * PI / 4 + PI / 8
        box((math.cos(a) * 15.2, math.sin(a) * 15.2, 7), (1.3, 1.1, 14), "Metal", rot=(0, 0, a), bevel=0.15)
    for sx in (-1, 1):
        box((sx * 4.9, -15.3, 5), (1.2, 1.6, 10), "Metal", bevel=0.2)
        box((sx * 4.9, -16.15, 5), (0.35, 0.2, 9), "Luz")
        cyl((sx * 7, -18.5, 0), 0.9, 1.2, "Metal", n=8)
        gem((sx * 7, -18.5, 2.6), 0.6, "Luz")
    box((0, -15.3, 10.4), (11, 1.6, 1.2), "Metal", bevel=0.2)
    box((0, -16.15, 10.4), (8, 0.2, 0.5), "Luz")
    sec("Medio")
    cyl((0, 0, 14), 14.6, 10, "Cuerpo", n=20)
    cyl((0, 0, 16.6), 14.75, 4.6, "Cristal", n=20)
    cyl((0, 0, 23), 15.2, 0.8, "Metal", n=20)
    cyl((0, 0, 14.2), 14.85, 0.3, "Luz", n=20)
    for i in range(8):
        a = i * PI / 4 + PI / 8
        box((math.cos(a) * 14.8, math.sin(a) * 14.8, 19), (1.0, 0.9, 10), "Metal", rot=(0, 0, a), bevel=0.12)
    sec("Tope")
    cyl((0, 0, 24), 15.4, 1, "Metal", n=20)
    cyl((0, 0, 24.9), 15.5, 0.3, "Luz", n=20)
    sphere((0, 0, 25), 14.4, "Techo", seg=16, rings=8, hemi=True, squash=(1, 1, 0.9))
    for i in range(8):
        a = i * PI / 4
        for k in range(4):
            t0, t1 = k / 4 * PI / 2 * 0.92, (k + 1) / 4 * PI / 2 * 0.92
            p0 = Vector((math.cos(a) * math.cos(t0) * 14.5, math.sin(a) * math.cos(t0) * 14.5, 25 + math.sin(t0) * 13.05))
            p1 = Vector((math.cos(a) * math.cos(t1) * 14.5, math.sin(a) * math.cos(t1) * 14.5, 25 + math.sin(t1) * 13.05))
            d = p1 - p0
            o = box(((p0 + p1) / 2)[:], (0.6, 0.6, d.length + 0.2), "Metal")
            o.rotation_mode = "QUATERNION"
            o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    cyl((0, 0, 37.6), 1.8, 1, "Metal", n=8)
    cyl((0, 0, 38.6), 0.5, 6, "Luz", n=6, r2=0.08)
    torus((0, 0, 40.6), 1.6, 0.14, "Luz")
    enter("Vertice", 15, -15, 15, 12, round_=True)


def ciudad_torre():
    """Torre redonda: zócalo con contrafuertes, tramos con anillo de ventanas y balcón, y remate en aguja."""
    sec("Base")
    body(cyl((0, 0, 0), 16.4, 3, "Cuerpo", n=16, r2=15))
    body(cyl((0, 0, 3), 15, 11, "Cuerpo", n=16))
    for i in range(6):
        a = i * PI / 3
        o = frustum((math.cos(a) * 15.6, math.sin(a) * 15.6, 0), 3, 3.4, 1.6, 2, 14, "Cuerpo")
        o.rotation_euler = (0, 0, a + PI / 2)
    cyl((0, 0, 13.2), 15.5, 0.8, "Metal", n=16)
    for sx in (-1, 1):
        box((sx * 4.8, -15.3, 5), (1.2, 1.6, 10), "Metal", bevel=0.2)
        box((sx * 4.8, -16.15, 6.6), (0.5, 0.3, 1.6), "Luz")
    box((0, -15.3, 10.4), (10.8, 1.6, 1.2), "Metal", bevel=0.2)
    sec("Medio")
    cyl((0, 0, 14), 14.4, 16, "Cuerpo", n=16)
    cyl((0, 0, 19.4), 14.55, 3.4, "Cristal", n=16)
    cyl((0, 0, 18.8), 14.9, 0.5, "Metal", n=16)
    cyl((0, 0, 22.8), 14.9, 0.5, "Metal", n=16)
    cyl((0, 0, 28.6), 16.4, 0.6, "Metal", n=16)  # balcón en anillo
    cyl((0, 0, 28.4), 16.5, 0.2, "Luz", n=16)
    for i in range(8):
        a = i * PI / 4
        box((math.cos(a) * 16.2, math.sin(a) * 16.2, 29.8), (0.3, 0.3, 2), "Metal", rot=(0, 0, a))
        box((math.cos(a) * 14.5, math.sin(a) * 14.5, 22), (0.9, 0.9, 16), "Metal", rot=(0, 0, a))
    sec("Tope")
    cyl((0, 0, 30), 14.4, 1.4, "Cuerpo", n=16)
    cyl((0, 0, 31.4), 14.4, 2.4, "Cuerpo", n=16, r2=17)
    cyl((0, 0, 33.8), 17, 1.2, "Metal", n=16)
    cyl((0, 0, 34.2), 17.15, 0.35, "Luz", n=16)
    cyl((0, 0, 35), 15.6, 15, "Techo", n=16, r2=2)
    cyl((0, 0, 45.2), 5.4, 4.9, "Nieve", n=16, r2=2.05)
    cyl((0, 0, 50), 2.2, 0.8, "Metal", n=8)
    cyl((0, 0, 50.8), 0.5, 8, "Luz", n=6, r2=0.08)
    for i in range(4):
        a = i * PI / 2 + PI / 4
        cyl((math.cos(a) * 15.4, math.sin(a) * 15.4, 35), 1.2, 5, "Techo", n=6, r2=0.05)
    enter("Talasa", 15, -15, 15, 12, round_=True)


def umbria_choza():
    """Choza de Raíz Honda: sobre zancos, de madera viva, con tejado de hojas, lianas y farolillos de bulbo."""
    sec("Base")
    for i in range(6):
        a = i * PI / 3 + PI / 6
        o = cyl((math.cos(a) * 10.5, math.sin(a) * 10.5, -1), 0.8, 7.2, "Metal", n=6)
        o.rotation_euler = (math.sin(a) * 0.08, -math.cos(a) * 0.08, 0)
    cyl((0, 0, 5.2), 13.4, 0.8, "Metal", n=14)
    cyl((0, 0, 5.05), 13.5, 0.15, "Luz", n=14)
    body(cyl((0, 0, 6), 11, 9, "Cuerpo", n=14))
    for z in (7.2, 13.6):
        cyl((0, 0, z), 11.25, 0.5, "Metal", n=14)
    for i in range(3):  # ojos de buey
        a = PI / 2 + (i - 1) * 2.1 + 1.05
        cyl((math.cos(a) * 10.9, math.sin(a) * 10.9, 10.4), 1.4, 0.4, "Cristal", n=8, rot=(PI / 2, 0, a - PI / 2))
    for sx in (-1, 1):
        box((sx * 4.4, -11, 10.4), (0.9, 1.2, 8.8), "Metal", bevel=0.2)
        o = cyl((sx * 5.6, -12.2, 6), 0.12, 6, "Hoja", n=6)
        sphere((sx * 5.6, -12.2, 12.4), 0.7, "Luz", seg=8, rings=5, squash=(1, 1, 1.3))
        sphere((sx * 5.6, -12.2, 13.3), 0.9, "Hoja", seg=8, rings=5, squash=(1, 1, 0.3))
    # tejado de hojas en tres faldones y su remate
    for i, (r0, r1, zz, hh) in enumerate(((14.4, 9.4, 15, 3.4), (10.6, 5.6, 17.8, 3.4), (6.6, 0.3, 20.6, 4.6))):
        cyl((0, 0, zz), r0, hh, "Techo", n=14, r2=r1)
    cyl((0, 0, 14.6), 14.5, 0.3, "Hoja", n=14)
    sphere((0, 0, 25.6), 0.8, "Luz", seg=8, rings=5, squash=(1, 1, 1.4))
    for i in range(5):  # lianas
        a = i * 1.26 + 0.6
        cyl((math.cos(a) * 13.8, math.sin(a) * 13.8, 9 + (i % 2)), 0.14, 6 - (i % 2), "Hoja", n=6)
        sphere((math.cos(a) * 13.8, math.sin(a) * 13.8, 9 + (i % 2)), 0.5, "Hoja", seg=8, rings=5)
    enter("Umbria", 11, -11, 11, 14.4, floor=6.2, dw=7, dh=7.6, round_=True, home=True)


# nombre, función, estilo de la vista previa, medidas nominales (W, D y la altura de cada sección)
ASSETS = [
    ("VerticeBloque", vertice_bloque, "Vertice", dict(W=30, D=30, Base=14, Mid=20, Top=10)),
    ("VerticeTorre", vertice_torre, "Vertice", dict(W=30, D=30, Base=16, Mid=30, Top=17)),
    ("VerticeCasa", vertice_casa, "Vertice", dict(W=26, D=26, Base=20, Mid=0, Top=0)),
    ("TefraBloque", tefra_bloque, "Tefra", dict(W=30, D=30, Base=14, Mid=20, Top=8)),
    ("TefraCasa", tefra_casa, "Tefra", dict(W=26, D=26, Base=20, Mid=0, Top=0)),
    ("SirocoBloque", siroco_bloque, "Siroco", dict(W=30, D=30, Base=14, Mid=20, Top=4)),
    ("SirocoCasa", siroco_casa, "Siroco", dict(W=26, D=26, Base=20, Mid=0, Top=0)),
    ("TalasaBloque", talasa_bloque, "Talasa", dict(W=30, D=30, Base=14, Mid=20, Top=5)),
    ("TalasaCasa", talasa_casa, "Talasa", dict(W=26, D=26, Base=20, Mid=0, Top=0)),
    ("NivalisBloque", nivalis_bloque, "Nivalis", dict(W=30, D=30, Base=14, Mid=20, Top=4)),
    ("NivalisCasa", nivalis_casa, "Nivalis", dict(W=26, D=26, Base=20, Mid=0, Top=0)),
    ("MiasmaBloque", miasma_bloque, "Miasma", dict(W=30, D=30, Base=14, Mid=20, Top=4)),
    ("MiasmaCasa", miasma_casa, "Miasma", dict(W=26, D=26, Base=20, Mid=0, Top=0)),
    ("CiudadNave", ciudad_nave, "Miasma", dict(W=30, D=30, Base=16, Mid=0, Top=0)),
    ("CiudadCupula", ciudad_cupula, "Talasa", dict(W=30, D=30, Base=14, Mid=10, Top=1)),
    ("CiudadTorre", ciudad_torre, "Nivalis", dict(W=30, D=30, Base=14, Mid=16, Top=5)),
    ("UmbriaChoza", umbria_choza, "Umbria", dict(W=28, D=28, Base=22, Mid=0, Top=0)),
    ("CalleVehiculo", calle_vehiculo, "Calle", dict(W=12, D=7, Base=4, Mid=0, Top=0)),
    ("CalleCajas", calle_cajas, "Calle", dict(W=9, D=7, Base=5, Mid=0, Top=0)),
    ("CalleTuberias", calle_tuberias, "Calle", dict(W=12, D=6, Base=8, Mid=0, Top=0)),
    ("CalleGenerador", calle_generador, "Calle", dict(W=10, D=5, Base=7, Mid=0, Top=0)),
    ("CallePuesto", calle_puesto, "Calle", dict(W=8, D=6, Base=7, Mid=0, Top=0)),
    ("CalleJardinera", calle_jardinera, "Calle", dict(W=9, D=5, Base=7, Mid=0, Top=0)),
]


# ---------------------------------------------------------------------------
# Juntar, exportar, vista previa
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


def _only(o):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o


def _cutter(lo, hi, radius=None):
    if radius:
        bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=radius, depth=hi[2] - lo[2], location=(0, 0, (lo[2] + hi[2]) / 2))
        return bpy.context.active_object
    bpy.ops.mesh.primitive_cube_add(size=1, location=[(a + b) / 2 for a, b in zip(lo, hi)])
    o = bpy.context.active_object
    o.scale = [b - a for a, b in zip(lo, hi)]
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return o


def _boolean(o, cutter):
    _only(o)
    m = o.modifiers.new("corte", "BOOLEAN")
    m.operation = "DIFFERENCE"
    m.object = cutter
    m.solver = "EXACT"
    bpy.ops.object.modifier_apply(modifier=m.name)


def carve(E):
    """Vacía la planta baja (los cuerpos marcados) y abre la puerta en todo lo que la tape. Las caras de dentro
    pasan al grupo «Forro» (las paredes de la habitación)."""
    t, z0, z1 = E["t"], E["floor"], E["top"]
    hx, y0, y1 = E["hx"], E["y0"], E["y1"]
    deep = t + (1.6 if E["round"] else 0.3)
    dlo, dhi = (-E["dw"] / 2, y0 - 1.0, z0), (E["dw"] / 2, y0 + deep, z0 + E["dh"])
    door = _cutter(dlo, dhi)
    if E["round"]:
        cav = _cutter((0, 0, z0), (0, 0, z1), radius=hx - t)
    else:
        cav = _cutter((-hx + t, y0 + t, z0), (hx - t, y1 - t, z1))

    def inside(c):
        if not (z0 - 0.02 <= c.z <= z1 + 0.02):
            return False
        if E["round"]:
            return math.hypot(c.x, c.y) <= hx - t + 0.02
        return abs(c.x) <= hx - t + 0.02 and y0 + t - 0.02 <= c.y <= y1 - t + 0.02

    lining = []
    for key in [k for k in G if k.startswith("Base_")]:
        keep = []
        for o in G[key]:
            _only(o)
            bpy.ops.object.convert(target="MESH")
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            is_body = bool(o.get("body"))
            if is_body:
                _boolean(o, cav)
            lo, hi = bounds([o])
            if is_body or all(lo[i] < dhi[i] and hi[i] > dlo[i] for i in range(3)):
                _boolean(o, door)
            if len(o.data.polygons) == 0:
                bpy.data.objects.remove(o, do_unlink=True)
                continue
            if is_body:
                copy = o.copy()
                copy.data = o.data.copy()
                bpy.context.scene.collection.objects.link(copy)
                for obj, want in ((o, False), (copy, True)):
                    bm = bmesh.new()
                    bm.from_mesh(obj.data)
                    drop = [f for f in bm.faces if inside(f.calc_center_median()) != want]
                    bmesh.ops.delete(bm, geom=drop, context="FACES")
                    bm.to_mesh(obj.data)
                    bm.free()
                if len(copy.data.polygons) > 0:
                    lining.append(copy)
                else:
                    bpy.data.objects.remove(copy, do_unlink=True)
            keep.append(o)
        G[key] = keep
    if lining:
        G["Base_Forro"] = lining
    bpy.data.objects.remove(door, do_unlink=True)
    bpy.data.objects.remove(cav, do_unlink=True)


def finish(kind, tint):
    if ENTER[0]:
        carve(ENTER[0])
    joined = []
    for key, objs in G.items():
        if not objs:
            continue
        group = key.split("_")[1]
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.object.convert(target="MESH")
        if len(objs) > 1:
            bpy.ops.object.join()
        o = bpy.context.active_object
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        o.name = f"{kind}_{key}"
        o.data.name = o.name
        if group != "Forro":
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.mesh.normals_make_consistent(inside=False)
            bpy.ops.object.mode_set(mode="OBJECT")
        t = tris_of(o)
        if t > MAX_TRIS:
            dec = o.modifiers.new("simplificar", "DECIMATE")
            dec.ratio = MAX_TRIS / t * 0.97
            bpy.ops.object.convert(target="MESH")
        try:
            bpy.ops.object.shade_smooth_by_angle(angle=math.radians(38), keep_sharp_edges=True)
            bpy.ops.object.convert(target="MESH")
        except Exception:
            bpy.ops.object.shade_smooth()
        base, metal, rough, emit = PREVIEW[group]
        col = tint.get(group, base)
        o.data.materials.clear()
        o.data.materials.append(material(f"{kind}_{key}_m", col, metal, rough, emit))
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


def render(path, lo, hi):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in [e.identifier for e in type(sc.render).bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE_NEXT"
    sc.render.resolution_x, sc.render.resolution_y = 900, 900
    world = bpy.data.worlds.new("cielo")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.3, 0.36, 0.5, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    sc.world = world
    sun = bpy.data.objects.new("sol", bpy.data.lights.new("sol", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(52), 0, math.radians(-35))
    sc.collection.objects.link(sun)
    size = hi - lo
    center = (lo + hi) / 2
    dist = max(size.x, size.y, size.z) * 1.5
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.lens = 40
    cam.data.clip_end = 5000
    cam.location = (center.x + dist * 0.6, center.y - dist * 0.95, lo.z + size.z * 0.55 + dist * 0.2)
    direction = Vector((center.x, center.y, lo.z + size.z * 0.48)) - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(cam)
    sc.camera = cam
    bpy.ops.mesh.primitive_plane_add(size=600, location=(0, 0, lo.z - 0.02))
    bpy.context.active_object.data.materials.append(material("suelo", (0.32, 0.32, 0.34), 0, 0.9, 0))
    sc.render.filepath = path
    sc.render.image_settings.file_format = "JPEG"
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    solo = argv[argv.index("--solo") + 1].split(",") if "--solo" in argv else None
    do_render = "--no-render" not in argv
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DOCS, exist_ok=True)
    man_path = os.path.join(OUT, "manifest.json")
    manifest = json.load(open(man_path, encoding="utf-8")) if os.path.exists(man_path) else {}
    for kind, fn, style, dims in ASSETS:
        if solo and kind not in solo:
            continue
        reset()
        fn()
        objs = finish(kind, TINTS[style])
        lo, hi = bounds(objs)
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, kind + ".fbx"), use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0, axis_forward="-Z", axis_up="Y", mesh_smooth_type="EDGE", add_leaf_bones=False, path_mode="STRIP")
        parts = {}
        probe, probe_score = None, 0.0
        for o in objs:
            key = o.name.split("_", 1)[1]
            plo, phi = bounds([o])
            # (Roblox: X igual, Y arriba = Z de Blender, Z = -Y de Blender: el frente queda en +Z)
            c = [round((plo.x + phi.x) / 2, 3), round((plo.z + phi.z) / 2, 3), round(-(plo.y + phi.y) / 2, 3)]
            s = [round(phi.x - plo.x, 3), round(phi.z - plo.z, 3), round(phi.y - plo.y, 3)]
            parts[key] = {"c": c, "s": s, "tris": tris_of(o)}
            score = abs(c[2] - (-(lo.y + hi.y) / 2))
            if score > probe_score:
                probe, probe_score = key, score
        center = [round((lo.x + hi.x) / 2, 3), round((lo.z + hi.z) / 2, 3), round(-(lo.y + hi.y) / 2, 3)]
        size = [round(hi.x - lo.x, 3), round(hi.z - lo.z, 3), round(hi.y - lo.y, 3)]
        tris = sum(p["tris"] for p in parts.values())
        manifest[kind] = {"parts": parts, "center": center, "size": size, "tris": tris, "dims": dims, "probe": probe, "enter": ENTER[0]}
        print(f"  {kind}: {tris} triángulos en {len(parts)} mallas, tamaño {size}, prueba {probe} ({probe_score:.1f})")
        if do_render:
            render(os.path.join(DOCS, kind + ".jpg"), lo, hi)
    with open(man_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    lua = ["-- CiudadMalla: GENERADO por scripts/planetas/edificios_blender.py (no editar a mano).",
           "-- Por pieza: Center y Size de todo (studs, respecto al centro de la base; el frente queda en +Z), las medidas",
           "-- nominales (W, D y la altura de las secciones Base, Mid y Top), y de cada malla «<Seccion>_<Grupo>» su centro",
           "-- (C) y tamaño (S). Probe: la malla más descentrada en Z (para saber hacia dónde quedó el frente al importar).",
           "-- Enter: la planta baja en la que se entra, en coordenadas de Blender (x, y = fondo con el frente en -y, z = alto):",
           "-- medio ancho HX, frente Y0 y fondo Y1 (por fuera), suelo y techo, puerta, grosor del muro y los muebles que chocan",
           "-- (Solids: centro x, y, z y tamaño x, y, z).",
           "-- Lo usa World/PlanetCityMeshes.",
           "return {"]
    for kind in sorted(manifest):
        m = manifest[kind]
        c, s, d = m["center"], m["size"], m["dims"]
        lua.append(f"\t{kind} = {{")
        lua.append(f"\t\tCenter = Vector3.new({c[0]}, {c[1]}, {c[2]}), Size = Vector3.new({s[0]}, {s[1]}, {s[2]}), Tris = {m['tris']},")
        lua.append(f"\t\tW = {d['W']}, D = {d['D']}, Base = {d['Base']}, Mid = {d['Mid']}, Top = {d['Top']}, Probe = \"{m['probe']}\",")
        e = m.get("enter")
        if e:
            solids = ", ".join("{ " + ", ".join(str(v) for v in sd) + " }" for sd in e["solids"])
            lua.append(f"\t\tEnter = {{ HX = {e['hx']}, Y0 = {e['y0']}, Y1 = {e['y1']}, Floor = {e['floor']}, Top = {e['top']}, DoorW = {e['dw']}, DoorH = {e['dh']}, T = {e['t']}, Round = {'true' if e['round'] else 'false'}, Ramp = {'true' if e['ramp'] else 'false'},")
            lua.append(f"\t\t\tSolids = {{ {solids} }} }},")
        lua.append("\t\tParts = {")
        for key in sorted(m["parts"]):
            p = m["parts"][key]
            lua.append(f"\t\t\t{key} = {{ C = Vector3.new({p['c'][0]}, {p['c'][1]}, {p['c'][2]}), S = Vector3.new({p['s'][0]}, {p['s'][1]}, {p['s'][2]}) }},")
        lua.append("\t\t},")
        lua.append("\t},")
    lua.append("}")
    with open(os.path.join(ROOT, "src", "shared", "Cosmos", "CiudadMalla.luau"), "w", encoding="utf-8") as f:
        f.write("\n".join(lua) + "\n")


main()
