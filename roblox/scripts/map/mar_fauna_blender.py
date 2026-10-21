#!/usr/bin/env python3
"""La fauna del mar hecha en Blender con Python (v125, queja del dueño: «los animales marinos no tienen textura
ni nada, son cuadrados o círculos»).

Ocho mallas (shared/Sea/MarFauna.Pieces): tres peces de arrecife (PezCirujano, PezLoro, PezAngel), el pez de
banco (PezBanco), la medusa (Medusa: campana y tentáculos de cinta EN LA MISMA malla), la manta (Manta), la
ballena (Ballena) y la tortuga (Tortuga). El cangrejo y la estrella ya están en el kit del mar (MarKit).

Cada animal:
  * cuerpo con secciones (ancho y alto a lo largo del cuerpo) y aletas como prismas finos, UNIDOS con
    booleanas en UNA sola pieza conectada (sin trozos sueltos: la moderación de Roblox mira cada malla sola,
    gris y sin textura, y un trozo alargado liso suelto se confunde; scripts/audit/moderacion-mallas.py)
  * estilo de facetas (sombreado plano), dentro de su presupuesto de triángulos (MarFauna.Pieces[].Tri)
  * textura de color de 512×256 pintada con su dibujo (rayas, manchas, vientre claro, ojo): un atlas con
    la vista de lado (u 0–0,5), el lomo (arriba a la derecha) y la tripa (abajo a la derecha); cada cara
    toma la vista según hacia dónde mira
Salen en assets/mar/<Nombre>.fbx y assets/mar/tex/<nombre>_color.png (las sube scripts/upload-mar.sh junto
al kit; World/MarMeshes las carga en ReplicatedStorage.MarMallas) y una vista previa
docs/mar/v125-fauna-vista-previa.jpg («VISTA PREVIA, NO ES ROBLOX»).

Necesita Blender como módulo de Python:   pip install bpy==4.2.0 numpy pillow   (Python 3.11)
Uso (desde la carpeta roblox/):   python3 scripts/map/mar_fauna_blender.py [--sin-vista]
"""
import argparse
import json
import math
import os
import re
import sys

import bpy  # noqa: I001
import bmesh
import numpy as np
from mathutils import Vector
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "mar")
TEX = os.path.join(OUT, "tex")
TW, TH = 512, 256


def read_fauna():
    src = open(os.path.join(ROOT, "src/shared/Sea/MarFauna.luau"), encoding="utf-8").read()
    out = {}
    for m in re.finditer(r"^\t(\w+) = \{ Size = \{ ([\d.]+), ([\d.]+), ([\d.]+) \},(.*)\},\s*$", src, re.M):
        rest = m.group(5)
        out[m.group(1)] = {
            "Size": (float(m.group(2)), float(m.group(3)), float(m.group(4))),
            "Tri": int(re.search(r"Tri = (\d+)", rest).group(1)),
        }
    return out


# ---------------------------------------------------------------------------
# Geometría
# ---------------------------------------------------------------------------
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mesh_object(name, verts, faces):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.validate()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def loft(name, length, profile, n_len=18, n_ring=12, y0=0.0, bend=None):
    """Cuerpo a lo largo de +Y (cola en y0, cabeza en y0+length). profile(s) -> (medio ancho, medio alto, z del centro)."""
    verts, faces = [], []
    for i in range(n_len + 1):
        s = i / n_len
        w, h, zc = profile(s)
        w, h = max(w, 1e-3), max(h, 1e-3)
        y = y0 + s * length
        xoff = bend(s) if bend else 0.0
        for j in range(n_ring):
            a = 2 * math.pi * j / n_ring
            c, sn = math.cos(a), math.sin(a)
            # superelipse algo cuadrada (los peces son de lado plano, no tubos)
            ex = 2.6
            x = w * math.copysign(abs(c) ** (2 / ex), c)
            z = h * math.copysign(abs(sn) ** (2 / ex), sn)
            verts.append((x + xoff, y, zc + z))
    for i in range(n_len):
        for j in range(n_ring):
            a = i * n_ring + j
            b = i * n_ring + (j + 1) % n_ring
            faces.append((a, b, b + n_ring, a + n_ring))
    # tapas
    tail_c = len(verts)
    w, h, zc = profile(0.0)
    verts.append(((bend(0) if bend else 0.0), y0, zc))
    head_c = len(verts)
    w, h, zc = profile(1.0)
    verts.append(((bend(1) if bend else 0.0), y0 + length, zc))
    for j in range(n_ring):
        faces.append((tail_c, (j + 1) % n_ring, j))
        top = n_len * n_ring
        faces.append((head_c, top + j, top + (j + 1) % n_ring))
    return mesh_object(name, verts, faces)


def prism(name, outline, thickness, plane="YZ", offset=(0, 0, 0), rot=None):
    """Aleta: un polígono (lista de (a, b)) con grosor. plane YZ: aleta vertical (dorsal, cola); XY: horizontal."""
    n = len(outline)
    verts = []
    for side in (-1, 1):
        for a, b in outline:
            if plane == "YZ":
                v = Vector((side * thickness / 2, a, b))
            else:
                v = Vector((a, b, side * thickness / 2))
            if rot is not None:
                v = rot @ v
            verts.append(v + Vector(offset))
    faces = [tuple(range(n))[::-1], tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    return mesh_object(name, verts, faces)


def union(base, others):
    """Une las aletas al cuerpo (booleana EXACTA): una sola pieza conectada. Si la booleana no deja UNA
    pieza (caras que se tocan justo en el borde…), se juntan y se rehacen con vóxeles (Remesh)."""
    backup = [base.copy()] + [o.copy() for o in others]
    for b, src in zip(backup, [base] + list(others)):
        b.data = src.data.copy()
    _boolean(base, others)
    if components(base) == 1 and len(base.data.polygons) > 60:
        for b in backup:
            bpy.data.objects.remove(b, do_unlink=True)
        return base
    print(f"  (booleana de {base.name} no unió todo: se rehace con vóxeles)", flush=True)
    name = base.name
    bpy.data.objects.remove(base, do_unlink=True)
    for b in backup:
        bpy.context.scene.collection.objects.link(b)
    bpy.ops.object.select_all(action="DESELECT")
    for b in backup:
        b.select_set(True)
    bpy.context.view_layer.objects.active = backup[0]
    bpy.ops.object.join()
    ob = backup[0]
    ob.name = name
    co = np.array([v.co[:] for v in ob.data.vertices])
    ext = co.max(0) - co.min(0)
    mod = ob.modifiers.new("R", "REMESH")
    mod.mode = "VOXEL"
    mod.voxel_size = float(max(ext)) / 140
    mod.adaptivity = 0.0
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return ob


def _boolean(base, others):
    for o in others:
        mod = base.modifiers.new("U", "BOOLEAN")
        mod.operation = "UNION"
        mod.solver = "EXACT"
        mod.object = o
        bpy.context.view_layer.objects.active = base
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(o, do_unlink=True)
    return base


def finish(ob, tri_budget, size):
    """Triangula, ajusta al presupuesto, sombreado plano y mide a su tamaño (Size: ancho X, alto Z, largo Y)."""
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    me = ob.data
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    if tris > tri_budget:
        mod = ob.modifiers.new("D", "DECIMATE")
        mod.ratio = max(0.02, tri_budget / tris * 0.85)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # medir y escalar al tamaño del catálogo
    co = np.array([v.co[:] for v in bm.verts])
    lo, hi = co.min(0), co.max(0)
    ext = hi - lo
    # (escala uniforme por el LARGO: las proporciones son las de la malla; el tamaño que sale va a
    # fauna.json y MarFauna.Size tiene que decir lo mismo —lo prueba scripts/test-mar.luau—)
    scale = size[2] / max(ext[1], 1e-6)
    center = (lo + hi) / 2
    for v in bm.verts:
        p = (np.array(v.co[:]) - center) * scale
        v.co = Vector(p)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    return ob


def components(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    seen, n = set(), 0
    for v in bm.verts:
        if v.index in seen:
            continue
        n += 1
        stack = [v]
        while stack:
            cur = stack.pop()
            if cur.index in seen:
                continue
            seen.add(cur.index)
            for e in cur.link_edges:
                stack.append(e.other_vert(cur))
    bm.free()
    return n


# ---------------------------------------------------------------------------
# UV: atlas de vistas (lado | lomo / tripa)
# ---------------------------------------------------------------------------
def atlas_uv(ob):
    me = ob.data
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    uv = me.uv_layers.active.data
    co = np.array([v.co[:] for v in me.vertices])
    lo, hi = co.min(0), co.max(0)
    ext = np.maximum(hi - lo, 1e-6)
    for p in me.polygons:
        n = p.normal
        for li in p.loop_indices:
            vi = me.loops[li].vertex_index
            x, y, z = (co[vi] - lo) / ext
            if n.z > 0.72:
                u, v = 0.5 + 0.5 * y, 0.5 + 0.5 * x
            elif n.z < -0.72:
                u, v = 0.5 + 0.5 * y, 0.5 * x
            else:
                u, v = 0.5 * y, z
            uv[li].uv = (min(max(u, 0.002), 0.998), min(max(v, 0.002), 0.998))


def paint(side, top, belly):
    """side(s, t), top(s, w), belly(s, w): arrays numpy 0..1 -> RGB (H, W, 3) 0..255. s: cola 0 → cabeza 1."""
    img = np.zeros((TH, TW, 3), dtype=np.float32)
    ys, xs = np.mgrid[0:TH, 0:TW // 2]
    s = (xs + 0.5) / (TW // 2)
    t = 1 - (ys + 0.5) / TH
    img[:, : TW // 2] = side(s, t)
    ys2, xs2 = np.mgrid[0: TH // 2, 0: TW // 2]
    s2 = (xs2 + 0.5) / (TW // 2)
    w2 = 1 - (ys2 + 0.5) / (TH // 2)
    img[: TH // 2, TW // 2:] = top(s2, w2)
    img[TH // 2:, TW // 2:] = belly(s2, w2)
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))


def C(*rgb):
    return np.array(rgb, dtype=np.float32)


def mix(a, b, k):
    k = np.clip(k, 0, 1)[..., None]
    return a * (1 - k) + b * k


def smooth(e0, e1, x):
    k = np.clip((x - e0) / (e1 - e0), 0, 1)
    return k * k * (3 - 2 * k)


def noise(s, t, f=23.0):
    return 0.5 + 0.5 * np.sin(s * f * 1.7 + np.sin(t * f) * 2.1) * np.cos(t * f * 1.3 + s * 3.1)


def eye(img_side, s, t, at_s, at_t, r=0.035):
    d = np.sqrt(((s - at_s) * 2.0) ** 2 + (t - at_t) ** 2)
    out = mix(img_side, C(250, 250, 240), smooth(r * 1.05, r * 0.9, d))
    return mix(out, C(12, 12, 16), smooth(r * 0.62, r * 0.5, d))


def fish_skin(back, belly_c, extra=None, eye_at=(0.86, 0.6), fin_tail=None):
    def side(s, t):
        base = mix(belly_c, back, smooth(0.35, 0.75, t))
        base = base * (0.92 + 0.08 * noise(s, t))[..., None]
        if fin_tail is not None:
            base = mix(base, fin_tail, smooth(0.16, 0.1, s))
        if extra:
            base = extra(base, s, t)
        return eye(base, s, t, *eye_at)

    def top(s, w):
        b = back * (0.9 + 0.1 * noise(s, w, 17))[..., None]
        if fin_tail is not None:
            b = mix(b, fin_tail, smooth(0.16, 0.1, s))
        return b

    def belly(s, w):
        return mix(belly_c, belly_c * 0.85, np.abs(w - 0.5) * 2)

    return side, top, belly


# ---------------------------------------------------------------------------
# Los animales
# ---------------------------------------------------------------------------
def fish(name, length=1.0, tall=0.42, thick=0.13, dorsal=0.18, tail=0.26, n_len=16):
    """Pez de lado plano: cuerpo, aleta dorsal, anal, caudal en horquilla y dos pectorales."""
    def prof(s):
        # de la cola (estrecha) a la cabeza (redondeada)
        k = math.sin(math.pi * (0.12 + 0.88 * s) ** 0.85)
        k = max(k, 0.12)
        head = 1 - float(smooth(0.85, 1.0, s)) * 0.55
        return thick * k * head, tall / 2 * k, 0.0
    body = loft(name, length, prof, n_len=n_len, n_ring=12)
    fins = []
    # cola en horquilla (vertical)
    fins.append(prism("cola", [(0.06, 0.0), (-tail * 0.9, tail * 0.95), (-tail * 0.55, 0.0), (-tail * 0.9, -tail * 0.95)], thick * 0.35))
    # dorsal y anal
    fins.append(prism("dorsal", [(length * 0.25, tall * 0.3), (length * 0.42, tall * 0.5 + dorsal), (length * 0.72, tall * 0.42), (length * 0.7, tall * 0.25)], thick * 0.3))
    fins.append(prism("anal", [(length * 0.22, -tall * 0.25), (length * 0.34, -tall * 0.45 - dorsal * 0.6), (length * 0.5, -tall * 0.3)], thick * 0.3))
    # pectorales (planas, pegadas al costado)
    for sx in (-1, 1):
        fins.append(prism("pect", [(0.0, 0.0), (-length * 0.16, tall * 0.08), (-length * 0.14, -tall * 0.14)], 0.02, plane="YZ",
                          offset=(sx * thick * 0.85, length * 0.68, -tall * 0.08)))
    return union(body, fins)


def build_pez_cirujano(info):
    ob = fish("PezCirujano", length=1.0, tall=0.62, thick=0.12, dorsal=0.1, tail=0.24)
    blue, dark, yellow = C(36, 92, 206), C(16, 22, 48), C(250, 210, 40)

    def extra(base, s, t):
        # la «paleta» oscura del costado y el borde oscuro de la dorsal
        band = smooth(0.06, 0.02, np.abs(t - (0.6 + 0.12 * np.sin(s * 5.0))) - 0.03 * (s > 0.25)) * (s > 0.22) * (s < 0.8)
        base = mix(base, dark, band)
        return mix(base, dark, smooth(0.9, 0.97, t))
    return ob, fish_skin(blue, C(70, 130, 220), extra, fin_tail=yellow)


def build_pez_loro(info):
    ob = fish("PezLoro", length=1.0, tall=0.5, thick=0.1, dorsal=0.12, tail=0.24)
    green, light, pink = C(40, 170, 140), C(150, 220, 200), C(240, 120, 170)

    def extra(base, s, t):
        scales = (np.sin(s * 70) * np.sin(t * 40) > 0.55) * 0.35
        base = mix(base, pink, scales * (s > 0.15))
        return mix(base, pink, smooth(0.9, 0.97, s) * smooth(0.35, 0.5, t) * 0.7)
    return ob, fish_skin(green, light, extra, fin_tail=pink * 0.9)


def build_pez_angel(info):
    ob = fish("PezAngel", length=0.85, tall=0.78, thick=0.1, dorsal=0.22, tail=0.2)
    yellow, black, white = C(250, 214, 50), C(20, 20, 24), C(250, 248, 236)

    def extra(base, s, t):
        bands = sum(smooth(0.03, 0.015, np.abs(s - c)) for c in (0.3, 0.52, 0.74))
        base = mix(base, black, bands)
        return mix(base, white, smooth(0.035, 0.02, np.abs(s - 0.63)) * 0.8)
    return ob, fish_skin(yellow, C(255, 235, 140), extra, fin_tail=black * 1.3, eye_at=(0.84, 0.58))


def build_pez_banco(info):
    ob = fish("PezBanco", length=1.0, tall=0.28, thick=0.09, dorsal=0.06, tail=0.17)
    back, belly_c, line = C(52, 86, 120), C(226, 232, 238), C(30, 40, 60)

    def extra(base, s, t):
        base = mix(base, line, smooth(0.02, 0.008, np.abs(t - 0.56)) * (s > 0.15))
        spots = (np.sin(s * 40) > 0.85) * smooth(0.6, 0.62, t) * smooth(0.75, 0.7, t)
        return mix(base, line, spots * 0.6)
    return ob, fish_skin(back, belly_c, extra, fin_tail=C(150, 170, 190))


def build_medusa(info):
    """Campana con faldón y ocho tentáculos de cinta ondulada, unidos a la campana (una sola malla)."""
    def prof(s):
        # campana: de la boca (s=0) a la cúspide (s=1); en Y sube (luego se gira para que Y sea arriba)
        r = 0.5 * math.sqrt(max(1 - s ** 2.2, 0.0)) + 0.02
        return r, r, 0.0
    bell = loft("Medusa", 0.62, prof, n_len=10, n_ring=16, y0=0.0)
    # girar: el eje de la campana a +Z
    bell.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.view_layer.objects.active = bell
    bell.select_set(True)
    bpy.ops.object.transform_apply(rotation=True)
    parts = []
    for k in range(8):
        a = 2 * math.pi * k / 8
        # cinta ondulada (plana: ancho 0,09, grosor 0,025) que cuelga de dentro de la campana
        pts = []
        for i in range(9):
            zz = 0.08 - i * 0.16
            off = 0.05 * math.sin(i * 1.3 + k)
            pts.append((0.3 + off, zz))
        outline = [(r - 0.045, z) for r, z in pts] + [(r + 0.045, z) for r, z in reversed(pts)]
        rot = Vector((math.cos(a), math.sin(a), 0))
        verts = []
        n = len(outline)
        for side in (-1, 1):
            for r, z in outline:
                p = rot * r + Vector((-math.sin(a), math.cos(a), 0)) * (side * 0.0125)
                verts.append((p.x * (0.8 if r > 0 else 1), p.y * 0.8, z))
        faces = [tuple(range(n))[::-1], tuple(range(n, 2 * n))]
        for i in range(n):
            j = (i + 1) % n
            faces.append((i, j, n + j, n + i))
        parts.append(mesh_object("tent", verts, faces))
    bell = union(bell, parts)
    pink, violet = C(240, 150, 210), C(170, 120, 240)

    def side(s, t):
        base = mix(violet, pink, t)
        ribs = 0.5 + 0.5 * np.cos(s * 2 * math.pi * 8)
        return mix(base, C(255, 230, 250), ribs * smooth(0.4, 0.9, t) * 0.35)

    def top(s, w):
        d = np.sqrt((s - 0.5) ** 2 + (w - 0.5) ** 2)
        base = mix(C(255, 210, 240), pink, smooth(0.05, 0.45, d))
        ang = np.arctan2(w - 0.5, s - 0.5)
        return mix(base, violet, (0.5 + 0.5 * np.cos(ang * 8)) * smooth(0.15, 0.45, d) * 0.4)

    def belly(s, w):
        return mix(violet, pink, 0.4 + 0 * s)
    return bell, (side, top, belly)


def build_manta(info):
    """Manta: cuerpo con las dos alas (un solo contorno plano engrosado), aletas cefálicas y cola corta."""
    outline = [(0.0, 0.62), (0.16, 0.66), (0.34, 0.52), (0.62, 0.36), (1.0, 0.22), (0.62, 0.1), (0.3, -0.04), (0.12, -0.18), (0.05, -0.26)]
    full = outline + [(-x, y) for x, y in reversed(outline[1:-1])]
    # dos capas con un abombado en el centro (cuerpo más grueso que las alas)
    n = len(full)
    verts = []
    for side in (-1, 1):
        for x, y in full:
            hump = 0.09 * max(0.0, 1 - abs(x) / 0.35)
            verts.append((x, y, side * (0.022 + hump * (0.6 if side < 0 else 1.0))))
    faces = [tuple(range(n))[::-1], tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    body = mesh_object("Manta", verts, faces)
    sub = body.modifiers.new("S", "SUBSURF")
    sub.levels = 1
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=sub.name)
    fins = []
    for sx in (-1, 1):
        fins.append(prism("cefalica", [(sx * 0.1, 0.6), (sx * 0.13, 0.78), (sx * 0.18, 0.76), (sx * 0.17, 0.58)], 0.03, plane="XY"))
    # cola corta y aplanada (no un tubo)
    fins.append(prism("cola", [(-0.03, -0.2), (-0.012, -0.62), (0.012, -0.62), (0.03, -0.2)], 0.02, plane="XY"))
    body = union(body, fins)
    top_c, belly_c = C(28, 36, 52), C(236, 238, 240)

    def side(s, t):
        return mix(belly_c, top_c, smooth(0.4, 0.6, t))

    def top(s, w):
        base = top_c * (0.9 + 0.1 * noise(s, w, 11))[..., None]
        # manchas claras de los hombros
        sh = np.exp(-(((s - 0.62) * 4) ** 2 + ((np.abs(w - 0.5) - 0.18) * 6) ** 2))
        return mix(base, C(200, 205, 210), sh * 0.8)

    def belly(s, w):
        spots = (np.sin(s * 37) * np.sin(w * 29) > 0.9) * 0.6
        return mix(belly_c, C(60, 64, 76), spots)
    return body, (side, top, belly)


def build_ballena(info):
    """Ballena jorobada: cuerpo, aletas pectorales largas (planas), aleta caudal y joroba dorsal."""
    def prof(s):
        k = math.sin(math.pi * (0.06 + 0.94 * s) ** 0.7)
        k = max(k, 0.1)
        return 0.13 * k, 0.12 * k * (1 - 0.25 * smooth(0.8, 1.0, s)), -0.01 * k
    body = loft("Ballena", 1.0, prof, n_len=22, n_ring=12)
    fins = [
        # caudal horizontal (contorno en x, y), metida en el pedúnculo de la cola para que quede unida
        prism("caudal", [(-0.04, 0.09), (0.2, -0.06), (0.17, -0.11), (0.0, -0.03), (-0.17, -0.11), (-0.2, -0.06), (0.04, 0.09)], 0.025, plane="XY"),
        prism("joroba", [(0.3, 0.04), (0.36, 0.14), (0.42, 0.05)], 0.04),
    ]
    for sx in (-1, 1):
        fins.append(prism("pectoral", [(sx * 0.04, 0.74), (sx * 0.42, 0.52), (sx * 0.43, 0.47), (sx * 0.05, 0.6)], 0.022, plane="XY", offset=(0, 0, -0.05)))
    body = union(body, fins)
    dark, light = C(40, 52, 70), C(196, 202, 206)

    def side(s, t):
        base = mix(light, dark, smooth(0.38, 0.6, t))
        grooves = (np.sin(t * 120) > 0.6) * smooth(0.35, 0.3, t) * smooth(0.45, 0.6, s) * 0.5
        base = mix(base, dark * 1.4, grooves)
        knobs = (np.sin(s * 160) * np.sin(t * 90) > 0.93) * smooth(0.88, 0.92, s)
        return eye(mix(base, light, knobs * 0.6), s, t, 0.8, 0.42, 0.02)

    def top(s, w):
        return dark * (0.9 + 0.1 * noise(s, w, 9))[..., None]

    def belly(s, w):
        return mix(light, dark, (np.sin(w * 60) > 0.7) * 0.25 * smooth(0.45, 0.6, s))
    return body, (side, top, belly)


def build_tortuga(info):
    """Tortuga marina: caparazón abombado, plastrón, cabeza corta, cuatro aletas planas y cola corta."""
    def prof(s):
        k = math.sin(math.pi * (0.04 + 0.92 * s))
        return 0.42 * max(k, 0.08) ** 0.6, 0.17 * max(k, 0.08) ** 0.7, 0.02
    shell = loft("Tortuga", 0.95, prof, n_len=14, n_ring=14)
    head = loft("cabeza", 0.26, lambda s: (0.1 * (0.7 + 0.3 * math.sin(math.pi * s)), 0.08 * (0.7 + 0.3 * math.sin(math.pi * s)), 0.0), n_len=5, n_ring=10, y0=0.86)
    parts = [head]
    for sx in (-1, 1):
        parts.append(prism("aleta_del", [(sx * 0.2, 0.7), (sx * 0.62, 0.52), (sx * 0.66, 0.44), (sx * 0.24, 0.56)], 0.04, plane="XY", offset=(0, 0, -0.02)))
        parts.append(prism("aleta_tras", [(sx * 0.18, 0.18), (sx * 0.36, 0.04), (sx * 0.32, -0.02), (sx * 0.14, 0.1)], 0.035, plane="XY", offset=(0, 0, -0.02)))
    parts.append(prism("cola", [(-0.03, 0.05), (0.0, -0.08), (0.03, 0.05)], 0.03, plane="XY"))
    shell = union(shell, parts)
    shell_c, skin, plate = C(104, 120, 64), C(170, 160, 112), C(60, 74, 40)

    def side(s, t):
        base = mix(skin, shell_c, smooth(0.45, 0.6, t))
        return eye(base, s, t, 0.96, 0.52, 0.02)

    def top(s, w):
        # escudos del caparazón: rejilla de hexágonos
        u, v = s * 7, w * 6
        hexd = np.abs(np.sin(u * math.pi) * np.sin(v * math.pi + (np.floor(u) % 2) * math.pi / 2))
        base = mix(plate, shell_c * 1.15, smooth(0.15, 0.4, hexd))
        head = smooth(0.88, 0.92, s)
        return mix(base, skin, head)

    def belly(s, w):
        return C(220, 206, 150) * (0.92 + 0.08 * noise(s, w, 13))[..., None]
    return shell, (side, top, belly)


# ---------------------------------------------------------------------------
# v4 (docs/mar/v4-objetivo.md: «mucha más actividad»): delfín, tiburón de arrecife y morena asomada
# ---------------------------------------------------------------------------
def build_delfin(info):
    """Delfín mular: cuerpo fusiforme con melón y pico corto, aleta dorsal en hoz, pectorales y aleta caudal
    horizontal (todo unido en una pieza)."""
    def prof(s):
        k = math.sin(math.pi * (0.05 + 0.95 * s) ** 0.75)
        k = max(k, 0.08)
        beak = 1 - 0.55 * float(smooth(0.9, 1.0, s))
        melon = 1 + 0.12 * float(np.exp(-((s - 0.86) * 14) ** 2))
        return 0.1 * k * beak, 0.105 * k * beak * melon, 0.004 * k
    # (revisión de moderación, 1.ª: liso y alargado. Cuerpo de facetas —8 lados, 12 tramos— y aletas más
    # grandes: pectorales y caudal anchas, dorsal alta)
    body = loft("Delfin", 1.0, prof, n_len=12, n_ring=8)
    fins = [
        prism("caudal", [(-0.03, 0.09), (0.24, -0.05), (0.22, -0.11), (0.0, -0.03), (-0.22, -0.11), (-0.24, -0.05), (0.03, 0.09)], 0.022, plane="XY"),
        prism("dorsal", [(0.38, 0.07), (0.47, 0.25), (0.53, 0.26), (0.56, 0.08)], 0.03),
    ]
    for sx in (-1, 1):
        fins.append(prism("pectoral", [(sx * 0.06, 0.68), (sx * 0.32, 0.54), (sx * 0.31, 0.5), (sx * 0.07, 0.6)], 0.02, plane="XY", offset=(0, 0, -0.045)))
    body = union(body, fins)
    back, belly_c, cape = C(96, 110, 128), C(222, 226, 232), C(66, 78, 96)

    def side(s, t):
        base = mix(belly_c, back, smooth(0.4, 0.58, t))
        base = mix(base, cape, smooth(0.62, 0.72, t) * smooth(0.25, 0.4, s) * smooth(0.85, 0.7, s))
        return eye(base, s, t, 0.9, 0.55, 0.018)

    def top(s, w):
        return mix(back, cape, smooth(0.25, 0.4, s) * smooth(0.85, 0.7, s)) * (0.95 + 0.05 * noise(s, w, 5))[..., None]

    def belly(s, w):
        return belly_c * (0.96 + 0.04 * noise(s, w, 6))[..., None]
    return body, (side, top, belly)


def build_tiburon(info):
    """Tiburón de arrecife de puntas negras (tranquilo): hocico en punta, primera dorsal alta, segunda pequeña,
    pectorales largas y cola con el lóbulo de arriba más largo."""
    def prof(s):
        k = math.sin(math.pi * (0.04 + 0.96 * s) ** 0.8)
        k = max(k, 0.07)
        snout = 1 - 0.5 * float(smooth(0.88, 1.0, s))
        return 0.085 * k * snout, 0.09 * k * snout, 0.0
    body = loft("Tiburon", 1.0, prof, n_len=22, n_ring=12)
    fins = [
        # cola vertical (lóbulo de arriba mayor)
        prism("caudal", [(0.06, 0.0), (-0.16, 0.2), (-0.12, 0.02), (-0.1, -0.11), (0.05, -0.02)], 0.022),
        prism("dorsal1", [(0.48, 0.06), (0.56, 0.21), (0.6, 0.2), (0.66, 0.07)], 0.024),
        prism("dorsal2", [(0.2, 0.04), (0.23, 0.08), (0.26, 0.04)], 0.016),
        prism("anal", [(0.18, -0.04), (0.21, -0.08), (0.25, -0.04)], 0.016),
    ]
    for sx in (-1, 1):
        fins.append(prism("pectoral", [(sx * 0.05, 0.68), (sx * 0.26, 0.54), (sx * 0.25, 0.5), (sx * 0.06, 0.6)], 0.016, plane="XY", offset=(0, 0, -0.05)))
    body = union(body, fins)
    back, belly_c, tip = C(122, 116, 100), C(232, 230, 222), C(24, 24, 28)

    def side(s, t):
        base = mix(belly_c, back, smooth(0.42, 0.55, t))
        base = mix(base, tip, smooth(0.93, 0.98, t))  # (las puntas negras de las aletas)
        base = mix(base, back * 0.8, (np.sin(s * 120) > 0.97) * smooth(0.6, 0.7, s) * smooth(0.5, 0.56, t) * 0.5)  # agallas
        return eye(base, s, t, 0.9, 0.55, 0.014)

    def top(s, w):
        return back * (0.93 + 0.07 * noise(s, w, 7))[..., None]

    def belly(s, w):
        return belly_c
    return body, (side, top, belly)


def build_morena(info):
    """Morena asomada: solo la parte de delante (la que sale de su agujero en la roca), con la cabeza ancha y alta,
    la cresta de la aleta dorsal a todo lo largo y el dibujo de manchas: no es un tubo liso."""
    def prof(s):
        head = float(smooth(0.72, 0.85, s)) * (1 - float(smooth(0.94, 1.0, s)) * 0.45)
        return 0.11 * (0.85 + 0.25 * head), 0.15 * (0.85 + 0.3 * head), 0.0
    # (revisión de moderación, 1.ª: tubo alargado. Más corta y alta —solo la cabeza y el cuello—, de facetas,
    # y sale de su ROCA: el borde del agujero va en la misma malla, ancho y áspero)
    body = loft("MorenaAsomada", 0.75, prof, n_len=10, n_ring=8, y0=0.25)
    fins = [
        # la cresta dorsal (alta y ondulada) de la nuca a la parte de atrás
        prism("cresta", [(0.0, 0.1), (0.1, 0.2), (0.25, 0.19), (0.4, 0.21), (0.55, 0.19), (0.7, 0.17), (0.76, 0.12), (0.0, 0.08)], 0.03),
        # la mandíbula: un escalón bajo la cabeza (boca entreabierta)
        prism("mandibula", [(0.84, -0.12), (0.99, -0.08), (0.99, -0.05), (0.86, -0.08)], 0.16),
    ]
    # la roca del agujero: un aro de roca áspero (bola aplanada con bultos) en la parte de atrás
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.36, location=(0, 0.27, 0))
    rock = bpy.context.active_object
    rock.name = "roca"
    rnd = np.random.default_rng(4)
    for v in rock.data.vertices:
        v.co.y *= 0.45
        v.co *= 1 + rnd.uniform(-0.12, 0.12)
    rock.data.update()
    fins.append(rock)
    body = union(body, fins)
    base_c, spot, dark = C(196, 176, 70), C(56, 48, 26), C(30, 26, 18)

    rock_c = C(104, 98, 86)

    def side(s, t):
        u = np.sin(s * 48 + np.sin(t * 9)) * np.sin(t * 22)
        base = mix(base_c, spot, (u > 0.45) * 0.85)
        base = mix(base, rock_c, smooth(0.36, 0.3, s))  # (la roca del agujero)
        base = mix(base, dark, smooth(0.015, 0.0, np.abs(t - 0.38)) * smooth(0.82, 0.86, s))  # la boca
        return eye(base, s, t, 0.9, 0.62, 0.02)

    def top(s, w):
        u = np.sin(s * 48) * np.sin(w * 20)
        return mix(mix(base_c * 0.95, spot, (u > 0.4) * 0.85), rock_c, smooth(0.36, 0.3, s))

    def belly(s, w):
        return mix(base_c * 1.05, spot, (np.sin(s * 40) * np.sin(w * 18) > 0.6) * 0.6)
    return body, (side, top, belly)


BUILDERS = {
    "PezCirujano": build_pez_cirujano,
    "PezLoro": build_pez_loro,
    "PezAngel": build_pez_angel,
    "PezBanco": build_pez_banco,
    "Medusa": build_medusa,
    "Manta": build_manta,
    "Ballena": build_ballena,
    "Tortuga": build_tortuga,
    "Delfin": build_delfin,
    "Tiburon": build_tiburon,
    "MorenaAsomada": build_morena,
}


def export(ob, name):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    path = os.path.join(OUT, name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=True, add_leaf_bones=False,
                             path_mode="STRIP", embed_textures=False, use_custom_props=False)
    return path


def preview(objs, path):
    """Vista previa con Cycles (CPU, pocas muestras; sin GPU): todas en fila. NO es Roblox."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.render.resolution_x, scene.render.resolution_y = 1600, 520
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.35, 0.6, 0.75, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.2
    scene.world = world
    sun = bpy.data.objects.new("sol", bpy.data.lights.new("sol", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(35), math.radians(-20), math.radians(10))
    scene.collection.objects.link(sun)
    x = 0.0
    for ob, size in objs:
        ob.location = (x + size[0] / 2, 0, 0)
        x += max(size[0], 1.2) + 0.6
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = x + 0.4
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    # (de lado y algo desde arriba: se ven el costado pintado y el lomo; los animales miran a −X)
    cam.location = (x / 2, -20, 7)
    cam.rotation_euler = (math.radians(70), 0, 0)
    scene.camera = cam
    scene.render.filepath = path
    scene.render.image_settings.file_format = "JPEG"
    bpy.ops.render.render(write_still=True)
    im = Image.open(path).convert("RGB")
    d = ImageDraw.Draw(im)
    d.text((12, 10), "VISTA PREVIA, NO ES ROBLOX - fauna del mar v125 (mar_fauna_blender.py)", fill=(255, 255, 255))
    im.save(path, quality=88)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sin-vista", action="store_true")
    ap.add_argument("--solo", default=None)
    args = ap.parse_args()
    fauna = read_fauna()
    assert set(fauna) == set(BUILDERS), f"MarFauna.Pieces y el script no coinciden: {sorted(fauna)} / {sorted(BUILDERS)}"
    os.makedirs(TEX, exist_ok=True)
    report = {}
    reset()
    shown = []
    for name, build in BUILDERS.items():
        if args.solo and name not in args.solo.split(","):
            continue
        info = fauna[name]
        ob, painters = build(info)
        ob.name = name
        finish(ob, info["Tri"], info["Size"])
        atlas_uv(ob)
        img = paint(*painters)
        tex_path = os.path.join(TEX, name.lower() + "_color.png")
        img.save(tex_path)
        n_tris = len(ob.data.polygons)
        comps = components(ob)
        export(ob, name)
        # material con la textura (solo para la vista previa)
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        tn = nodes.new("ShaderNodeTexImage")
        tn.image = bpy.data.images.load(tex_path)
        mat.node_tree.links.new(tn.outputs["Color"], nodes["Principled BSDF"].inputs["Base Color"])
        ob.data.materials.append(mat)
        co = np.array([v.co[:] for v in ob.data.vertices])
        ext = co.max(0) - co.min(0)
        real = [round(float(ext[0]), 2), round(float(ext[2]), 2), round(float(ext[1]), 2)]
        report[name] = {"SizeReal": real, "Tris": n_tris, "Trozos": comps, "Size": info["Size"], "FBX": name + ".fbx", "Textura": "tex/" + name.lower() + "_color.png"}
        print(f"{name}: {n_tris} triángulos, {comps} trozo(s)", flush=True)
        shown.append((ob, info["Size"]))
    mpath = os.path.join(OUT, "fauna.json")
    if args.solo and os.path.exists(mpath):
        old = json.load(open(mpath, encoding="utf-8")).get("Fauna", {})
        old.update(report)
        report = old
    with open(mpath, "w", encoding="utf-8") as f:
        json.dump({"Fauna": report}, f, indent=2, ensure_ascii=False)
    if not args.sin_vista and shown:
        # (escaladas para que se vean juntas: los grandes, más pequeños)
        for ob, size in shown:
            k = 1.6 / max(size)
            ob.scale = (k, k, k)
            ob.rotation_euler = (0, 0, math.radians(90))  # de lado a la cámara
        preview([(ob, tuple(v * 1.6 / max(size) for v in size)) for ob, size in shown], os.path.join(ROOT, "docs", "mar", "v125-fauna-vista-previa.jpg"))
    bad = [n for n, r in report.items() if r["Trozos"] != 1]
    if bad:
        print("❌ con trozos sueltos: " + ", ".join(bad))
        sys.exit(2)


if __name__ == "__main__":
    main()
