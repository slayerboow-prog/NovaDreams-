#!/usr/bin/env python3
"""El kit del mar hecho en Blender con Python (encargo v2 del dueño; docs/mar/diseno-v2.md).

1. Mallas: las 23 piezas de shared/Sea/MarKit (7 corales, 4 rocas, kelp gigante, pradera, alga ancha, seta y
   anémona de luz, estrella, concha, erizo, cangrejo, pilote, pirámide y columna). Cada una con su forma de
   verdad (ramas que se bifurcan hechas con un esqueleto y el modificador Skin, surcos del coral cerebro
   con una textura de vetas, la red del abanico, tubos huecos, agujeros de la roca porosa con booleanas,
   hojas curvas con grosor —de dos caras—, escalones y vetas de la pirámide…), reducida a su presupuesto
   de triángulos de móvil (MarKit.Pieces[].Tri) y medida a su tamaño (Size). Las que no van con el color
   de la paleta (rocas, vida pequeña, pilote y ruinas) llevan textura horneada de color y de normales de
   512 px. Salen en assets/mar (FBX para subir a Roblox), con manifest.json, y la textura de cáusticas
   (tex/causticas.png, hecha a mano con ruido de Voronoi: se repite sin costuras).
   Subir: bash scripts/upload-mar.sh (lo hace la sesión que publica; mientras, el juego usa el respaldo).
2. Vistas previas (docs/mar/v2-*.jpg, todas con «VISTA PREVIA, NO ES ROBLOX»):
   - v2-kit-vista-previa.jpg: todas las piezas en fila, con su nombre
   - v2-vista-<n>.jpg y v2-vistas.jpg: el Cañón de Dorada desde las MISMAS cámaras de la revisión por
     rayos (ReefZone.Cameras), con la geometría que construye el juego (scripts/map/canon-export.luau:
     vóxeles de 2 studs) y el kit puesto como lo pone World/ReefZoneBuilder. La luz es una aproximación
     (sol, bruma por distancia, oscurece con la profundidad); NO es una captura de Roblox.

Necesita Blender como módulo de Python:   pip install bpy==4.2.0 numpy scikit-image pillow   (Python 3.11)

Uso (desde la carpeta roblox/):
    python3 scripts/map/mar_kit_blender.py                          (mallas, texturas y vista del kit)
    lune run scripts/map/canon-export.luau /tmp/canon.json /tmp/canon.vox
    python3 scripts/map/mar_kit_blender.py --zona /tmp/canon.json   (además, las vistas del cañón)
    python3 scripts/map/mar_kit_blender.py --solo-zona /tmp/canon.json --muestras 24
"""
import argparse
import json
import math
import os
import random
import re
import sys
import time
import zlib

import bpy  # noqa: I001 (bpy antes que bmesh)
import bmesh
from mathutils import Vector, Matrix

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
T0 = time.time()


def log(msg):
    print(f"[{time.time() - T0:6.1f}s] {msg}", flush=True)


# ---------------------------------------------------------------------------
# El catálogo (lo lee de shared/Sea/MarKit.luau: una sola fuente de tamaños y presupuestos)
# ---------------------------------------------------------------------------
def read_kit():
    src = open(os.path.join(ROOT, "src/shared/Sea/MarKit.luau"), encoding="utf-8").read()
    kit = {}
    for m in re.finditer(r"^\t(\w+) = \{ Size = \{ ([\d.]+), ([\d.]+), ([\d.]+) \},(.*)\},\s*$", src, re.M):
        name = m.group(1)
        rest = m.group(5)
        tri = int(re.search(r"Tri = (\d+)", rest).group(1))
        kit[name] = {
            "Size": (float(m.group(2)), float(m.group(3)), float(m.group(4))),
            "Tri": tri,
            "Tint": "Tint = true" in rest,
            "Glow": "Glow = true" in rest,
            "Group": re.search(r'Group = "(\w+)"', rest).group(1),
            "Label": re.search(r'Label = "([^"]+)"', rest).group(1),
        }
    return kit


# ---------------------------------------------------------------------------
# Utilidades de escena
# ---------------------------------------------------------------------------
def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def select_only(objs, active=None):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or objs[0]


def new_obj(name, mesh):
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def apply_all(obj):
    select_only([obj])
    for m in list(obj.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=m.name)
        except RuntimeError as e:
            log(f"  (modificador {m.name} de {obj.name}: {e})")
            obj.modifiers.remove(m)


def join(objs, name):
    for o in objs:
        apply_all(o)
    select_only(objs, objs[0])
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


def prim(kind, name, **kw):
    if kind == "ico":
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=kw.get("sub", 3), radius=kw.get("r", 1))
    elif kind == "uv":
        bpy.ops.mesh.primitive_uv_sphere_add(segments=kw.get("seg", 16), ring_count=kw.get("rings", 10), radius=kw.get("r", 1))
    elif kind == "cyl":
        bpy.ops.mesh.primitive_cylinder_add(vertices=kw.get("seg", 12), radius=kw.get("r", 1), depth=kw.get("h", 1), end_fill_type=kw.get("fill", "NGON"))
    elif kind == "cone":
        bpy.ops.mesh.primitive_cone_add(vertices=kw.get("seg", 8), radius1=kw.get("r1", 1), radius2=kw.get("r2", 0), depth=kw.get("h", 1))
    elif kind == "cube":
        bpy.ops.mesh.primitive_cube_add(size=1)
    elif kind == "plane":
        bpy.ops.mesh.primitive_plane_add(size=1)
    elif kind == "grid":
        bpy.ops.mesh.primitive_grid_add(x_subdivisions=kw.get("nx", 8), y_subdivisions=kw.get("ny", 8), size=1)
    o = bpy.context.view_layer.objects.active
    o.name = name
    o.location = kw.get("at", (0, 0, 0))
    o.rotation_euler = kw.get("rot", (0, 0, 0))
    o.scale = kw.get("scale", (1, 1, 1))
    select_only([o])
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return o


def displace(obj, tex_type, strength, size=1.0, seed=0, **props):
    tex = bpy.data.textures.new(f"{obj.name}_{tex_type}_{seed}", tex_type)
    tex.noise_scale = size
    for k, v in props.items():
        setattr(tex, k, v)
    m = obj.modifiers.new("disp", "DISPLACE")
    m.texture = tex
    m.texture_coords = "LOCAL"
    m.strength = strength
    m.mid_level = 0.5
    return m


def skeleton(name, nodes, edges, radii, subsurf=1):
    """Ramas con el modificador Skin: nodes (x, y, z), edges (i, j), radii por nodo."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(nodes, edges, [])
    obj = new_obj(name, mesh)
    obj.modifiers.new("skin", "SKIN")
    for i, v in enumerate(obj.data.skin_vertices[0].data):
        v.radius = (radii[i], radii[i])
    obj.data.skin_vertices[0].data[0].use_root = True
    if subsurf:
        s = obj.modifiers.new("sub", "SUBSURF")
        s.levels = subsurf
        s.render_levels = subsurf
    return obj


def tris_of(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def finish(obj, info):
    """Aplica todo, reduce a su presupuesto, mide al tamaño de MarKit (X ancho, Y fondo, Z alto) con el pie en 0."""
    apply_all(obj)
    select_only([obj])
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.0005)
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    target = info["Tri"]
    n = tris_of(obj)
    if n > target:
        d = obj.modifiers.new("dec", "DECIMATE")
        d.ratio = max(0.02, target / n * 0.97)
        apply_all(obj)
    tri = obj.modifiers.new("tri", "TRIANGULATE")
    apply_all(obj)
    # medir: el alto de MarKit (Roblox Y = Blender z), sin deformar (la misma escala en los tres ejes);
    # el ancho y el fondo que salen van al manifest y MarKit.Size tiene que decir lo mismo (lo prueba
    # scripts/test-reefzone.luau: si no, Roblox estiraría la malla)
    W, H, D = info["Size"]
    vs = [v.co for v in obj.data.vertices]
    lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    ext = hi - lo
    k = H / max(ext.z, 1e-4)
    cx, cy = (lo.x + hi.x) / 2, (lo.y + hi.y) / 2
    for v in obj.data.vertices:
        v.co = Vector(((v.co.x - cx) * k, (v.co.y - cy) * k, (v.co.z - lo.z) * k))
    obj["medida"] = (round(ext.x * k, 2), round(H, 2), round(ext.y * k, 2))
    for p in obj.data.polygons:
        p.use_smooth = True
    obj.data.update()
    return obj


# ---------------------------------------------------------------------------
# Las piezas (cada función devuelve un objeto sin terminar; finish lo mide)
# ---------------------------------------------------------------------------
def branchy(name, rnd, levels, spread, n0, r0, length, up=0.8):
    nodes, edges, radii = [(0, 0, 0)], [], [r0]

    def grow(i, dirv, lvl, rad, ln):
        if lvl == 0:
            return
        for k in range(2 if lvl < levels else n0):
            a = rnd.uniform(0, math.tau) if lvl == levels else rnd.uniform(-1, 1)
            if lvl == levels:
                d = Vector((math.cos(a) * spread, math.sin(a) * spread, up)).normalized()
            else:
                side = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), 0)).normalized() * spread * 0.8
                d = (dirv + side + Vector((0, 0, 0.25))).normalized()
            p = Vector(nodes[i]) + d * ln * rnd.uniform(0.8, 1.15)
            nodes.append(tuple(p))
            radii.append(rad * 0.72)
            j = len(nodes) - 1
            edges.append((i, j))
            grow(j, d, lvl - 1, rad * 0.72, ln * 0.78)

    grow(0, Vector((0, 0, 1)), levels, r0, length)
    return skeleton(name, nodes, edges, radii, subsurf=1)


def make_piece(name, rnd):
    if name == "CoralCuerno":
        return branchy(name, rnd, 3, 0.85, 5, 0.16, 0.6)
    if name == "CoralCerebro":
        o = prim("ico", name, sub=5, r=1, scale=(1, 0.95, 0.62))
        displace(o, "MARBLE", 0.16, size=0.11, seed=1, marble_type="SHARPER", noise_basis_2="SIN", turbulence=9.0)
        displace(o, "CLOUDS", 0.06, size=0.6, seed=2)
        return o
    if name == "CoralMesa":
        stem = prim("cyl", name + "_pie", seg=10, r=0.1, h=0.6, at=(0, 0, 0.3))
        parts = [stem]
        for k, (r, z) in enumerate(((1.0, 0.62), (0.62, 0.78))):
            plate = prim("cyl", f"{name}_plato{k}", seg=32, r=r, h=0.05, at=(0.1 * k, 0.05 * k, z))
            for v in plate.data.vertices:
                a = math.atan2(v.co.y, v.co.x)
                d = math.hypot(v.co.x, v.co.y)
                v.co.z += 0.06 * math.sin(a * 9) * d + 0.1 * d * d
            plate.data.update()
            sub = plate.modifiers.new("sub", "SUBSURF")
            sub.levels = 1
            displace(plate, "STUCCI", 0.04, size=0.06, seed=3 + k)
            parts.append(plate)
        return join(parts, name)
    if name == "Abanico":
        nodes, edges, radii = [(0, 0, 0)], [], [0.05]
        # nervios en abanico que se bifurcan y se unen con travesaños (la red)
        rows = []
        for r in range(1, 7):
            ring = []
            cnt = 3 + r * 2
            for k in range(cnt):
                a = (k / (cnt - 1) - 0.5) * 2.0
                p = (math.sin(a) * r * 0.11, rnd.uniform(-0.02, 0.02), math.cos(a) * r * 0.17 + 0.05)
                nodes.append(p)
                radii.append(0.022)
                ring.append(len(nodes) - 1)
            rows.append(ring)
        for k in rows[0]:
            edges.append((0, k))
        for a_ring, b_ring in zip(rows, rows[1:]):
            for k, j in enumerate(b_ring):
                i = a_ring[min(len(a_ring) - 1, round(k * (len(a_ring) - 1) / max(1, len(b_ring) - 1)))]
                edges.append((i, j))
            for k in range(len(b_ring) - 1):
                if (k + len(b_ring)) % 2 == 0:
                    edges.append((b_ring[k], b_ring[k + 1]))
        o = skeleton(name, nodes, edges, radii, subsurf=0)
        bend = o.modifiers.new("curva", "SIMPLE_DEFORM")
        bend.deform_method = "BEND"
        bend.angle = 0.5
        bend.deform_axis = "Z"
        return o
    if name == "Esponjas":
        parts = []
        for k in range(4):
            a = k * math.tau / 4 + rnd.uniform(-0.3, 0.3)
            h = rnd.uniform(0.6, 1.0)
            c = prim("cyl", f"{name}{k}", seg=14, r=0.2, h=h, at=(math.cos(a) * 0.25, math.sin(a) * 0.25, h / 2), fill="NOTHING")
            sol = c.modifiers.new("grosor", "SOLIDIFY")
            sol.thickness = 0.05
            displace(c, "CLOUDS", 0.03, size=0.15, seed=10 + k)
            parts.append(c)
        return join(parts, name)
    if name == "CoralBlando":
        o = branchy(name, rnd, 2, 0.6, 4, 0.14, 0.5)
        tips = [Vector(v.co) for v in o.data.vertices if o.data.vertices and len([e for e in o.data.edges if v.index in e.vertices]) == 1 and v.co.z > 0.1]
        polyps = [o]
        for k, t in enumerate(tips):
            for j in range(3):
                off = Vector((rnd.uniform(-0.08, 0.08), rnd.uniform(-0.08, 0.08), rnd.uniform(-0.02, 0.08)))
                polyps.append(prim("ico", f"{name}_p{k}_{j}", sub=1, r=0.085, at=tuple(t + off)))
        return join(polyps, name)
    if name == "CoralPilar":
        parts = []
        for k in range(6):
            a = k * math.tau / 6
            h = rnd.uniform(0.6, 1.0)
            c = prim("cyl", f"{name}{k}", seg=10, r=0.12, h=h, at=(math.cos(a) * 0.18 * (k > 0), math.sin(a) * 0.18 * (k > 0), h / 2))
            cap = prim("uv", f"{name}c{k}", seg=10, rings=6, r=0.12, at=(c.location.x, c.location.y, h))
            parts += [c, cap]
        o = join(parts, name)
        displace(o, "STUCCI", 0.02, size=0.05, seed=12)
        return o
    if name in ("RocaPorosa", "Canto", "RocaLaja", "RocaAguja"):
        scale = {"RocaPorosa": (1.2, 1, 0.8), "Canto": (1, 0.95, 0.85), "RocaLaja": (1.5, 1, 0.35), "RocaAguja": (0.45, 0.45, 1.6)}[name]
        o = prim("ico", name, sub=4, r=1, scale=scale)
        displace(o, "CLOUDS", 0.35 if name != "Canto" else 0.18, size=0.7, seed=20)
        displace(o, "VORONOI", 0.12, size=0.35, seed=21)
        if name == "RocaAguja":
            taper = o.modifiers.new("punta", "SIMPLE_DEFORM")
            taper.deform_method = "TAPER"
            taper.factor = -0.5
            taper.deform_axis = "Z"
        if name == "RocaPorosa":
            apply_all(o)
            for k in range(7):
                v = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-0.3, 0.8))).normalized()
                v = Vector((v.x * 1.2, v.y, v.z * 0.8))
                hole = prim("uv", f"{name}_h{k}", seg=10, rings=8, r=rnd.uniform(0.14, 0.26), at=tuple(v * 0.98))
                b = o.modifiers.new(f"hueco{k}", "BOOLEAN")
                b.operation = "DIFFERENCE"
                b.object = hole
                b.solver = "EXACT"
                apply_all(o)
                bpy.data.objects.remove(hole, do_unlink=True)
        return o
    if name == "KelpGigante":
        nodes, edges, radii = [], [], []
        segs = 14
        for k in range(segs + 1):
            z = k / segs * 10
            nodes.append((math.sin(k * 0.6) * 0.25, math.cos(k * 0.45) * 0.2, z))
            radii.append(0.12 * (1 - k / segs * 0.5))
            if k:
                edges.append((k - 1, k))
        stalk = skeleton(name + "_tallo", nodes, edges, radii, subsurf=0)
        parts = [stalk]
        for k in range(1, segs + 1):
            if k % 1 == 0:
                side = 1 if k % 2 else -1
                # la hoja: larga y estrecha desde el tallo (x de 0 a 2,2), que se estrecha y cae; se
                # curva y se le da grosor EN SU SITIO (en el origen) y luego se lleva al tallo
                blade = prim("grid", f"{name}_h{k}", nx=8, ny=2, scale=(2.2, 0.5, 1))
                for v in blade.data.vertices:
                    t = v.co.x / 2.2 + 0.5
                    v.co = Vector((t * 2.2, v.co.y * (1 - 0.6 * t), -0.5 * t * t))
                blade.data.update()
                sol = blade.modifiers.new("grosor", "SOLIDIFY")
                sol.thickness = 0.02
                apply_all(blade)
                blade.rotation_euler = (rnd.uniform(-0.2, 0.2), 0, k * 2.4 + rnd.uniform(-0.3, 0.3))
                blade.location = (nodes[k][0], nodes[k][1], nodes[k][2] - 0.1)
                select_only([blade])
                bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
                parts.append(blade)
                if k > segs - 4:
                    parts.append(prim("uv", f"{name}_v{k}", seg=8, rings=6, r=0.14, at=(nodes[k][0] + side * 0.2, nodes[k][1], nodes[k][2])))
        return join(parts, name)
    if name in ("Pradera", "AlgaAncha"):
        parts = []
        n = 9 if name == "Pradera" else 5
        for k in range(n):
            a = k * math.tau / n + rnd.uniform(-0.3, 0.3)
            w = 0.09 if name == "Pradera" else 0.35
            blade = prim("grid", f"{name}{k}", nx=2, ny=8, scale=(w, 1, 1))
            # tumbar la hoja de pie (Y -> Z) y que se estreche hacia la punta
            for v in blade.data.vertices:
                t = v.co.y + 0.5
                v.co = Vector((v.co.x * (1 - t * 0.85), 0, t))
            blade.data.update()
            bend = blade.modifiers.new("curva", "SIMPLE_DEFORM")
            bend.deform_method = "BEND"
            bend.angle = rnd.uniform(0.5, 1.0)
            bend.deform_axis = "X"
            sol = blade.modifiers.new("grosor", "SOLIDIFY")
            sol.thickness = 0.015
            apply_all(blade)
            blade.rotation_euler = (0, 0, a)
            blade.location = (math.cos(a) * 0.12, math.sin(a) * 0.12, 0)
            blade.scale = (1, 1, rnd.uniform(0.6, 1.0))
            select_only([blade])
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            parts.append(blade)
        return join(parts, name)
    if name == "SetaLuz":
        stem = prim("cyl", name + "_pie", seg=12, r=0.13, h=0.75, at=(0, 0, 0.37))
        cap = prim("uv", name + "_sombrero", seg=20, rings=10, r=0.5, at=(0, 0, 0.78), scale=(1, 1, 0.42))
        gill = prim("cyl", name + "_laminas", seg=20, r=0.42, h=0.05, at=(0, 0, 0.7))
        return join([stem, cap, gill], name)
    if name == "AnemonaLuz":
        base = prim("uv", name + "_base", seg=14, rings=8, r=0.28, at=(0, 0, 0.25), scale=(1, 1, 1.2))
        nodes, edges, radii = [(0, 0, 0.45)], [], [0.06]
        for k in range(14):
            a = k * math.tau / 14
            prev = 0
            for s in range(1, 5):
                nodes.append((math.cos(a) * 0.1 * s, math.sin(a) * 0.1 * s, 0.45 + s * 0.22 - (s * s) * 0.02))
                radii.append(0.045 * (1 - s * 0.2))
                edges.append((prev, len(nodes) - 1))
                prev = len(nodes) - 1
        t = skeleton(name + "_tent", nodes, edges, radii, subsurf=0)
        return join([base, t], name)
    if name == "Estrella":
        bm = bmesh.new()
        pts = []
        for k in range(10):
            a = k * math.tau / 10
            r = 1.0 if k % 2 == 0 else 0.38
            pts.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, 0)))
        f = bm.faces.new(pts)
        ext = bmesh.ops.extrude_face_region(bm, geom=[f])
        for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
            v.co.z += 0.18
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        o = new_obj(name, mesh)
        s = o.modifiers.new("sub", "SUBSURF")
        s.levels = 2
        displace(o, "STUCCI", 0.03, size=0.05, seed=30)
        return o
    if name == "Concha":
        o = prim("uv", name, seg=24, rings=10, r=1, scale=(1, 0.9, 0.35))
        for v in o.data.vertices:
            a = math.atan2(v.co.y, v.co.x)
            v.co.z += 0.06 * abs(math.sin(a * 7)) * (1 if v.co.z > 0 else 0)
        o.data.update()
        return o
    if name == "Erizo":
        body = prim("ico", name + "_cuerpo", sub=2, r=0.5, at=(0, 0, 0.4), scale=(1, 1, 0.8))
        parts = [body]
        for k, v in enumerate(body.data.vertices):
            if k % 2 or v.co.z < 0.25:
                continue
            d = (v.co - Vector((0, 0, 0.4))).normalized()
            sp = prim("cone", f"{name}_p{k}", seg=4, r1=0.04, r2=0, h=0.55)
            sp.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
            sp.location = v.co + d * 0.25
            select_only([sp])
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            parts.append(sp)
        return join(parts, name)
    if name == "Cangrejo":
        body = prim("uv", name + "_cuerpo", seg=18, rings=10, r=0.6, at=(0, 0, 0.4), scale=(1, 0.75, 0.45))
        parts = [body]
        for side in (-1, 1):
            nodes = [(side * 0.45, 0, 0.4)]
            edges, radii = [], [0.07]
            for k in range(3):
                y = (k - 1) * 0.3
                nodes += [(side * 0.75, y, 0.45), (side * 0.95, y * 1.2, 0.0)]
                radii += [0.05, 0.03]
                i = len(nodes) - 2
                edges += [(0, i), (i, i + 1)]
            nodes += [(side * 0.55, -0.45, 0.45), (side * 0.75, -0.8, 0.5)]
            radii += [0.08, 0.11]
            i = len(nodes) - 2
            edges += [(0, i), (i, i + 1)]
            parts.append(skeleton(f"{name}_patas{side}", nodes, edges, radii, subsurf=1))
            for k in (1,):
                parts.append(prim("uv", f"{name}_ojo{side}", seg=8, rings=6, r=0.06, at=(side * 0.15, -0.38, 0.7)))
        return join(parts, name)
    if name == "Pilote":
        pile = prim("cyl", name, seg=16, r=0.5, h=8, at=(0, 0, 4))
        sub = pile.modifiers.new("sub", "SUBSURF")
        sub.levels = 1
        displace(pile, "WOOD", 0.03, size=0.25, seed=40, wood_type="RINGNOISE")
        parts = [pile]
        for k in range(40):
            a = rnd.uniform(0, math.tau)
            z = rnd.uniform(0.3, 3.0)
            parts.append(prim("cone", f"{name}_p{k}", seg=6, r1=0.1, r2=0.05, h=0.12, at=(math.cos(a) * 0.5, math.sin(a) * 0.5, z), rot=(0, math.pi / 2, a)))
        return join(parts, name)
    if name == "Piramide":
        parts = []
        steps = 6
        for k in range(steps):
            w = 1 - k / steps * 0.85
            s = prim("cube", f"{name}{k}", at=(0, 0, k / steps + 0.5 / steps), scale=(w, w, 1 / steps * 0.96))
            bev = s.modifiers.new("bisel", "BEVEL")
            bev.width = 0.01
            bev.segments = 1
            parts.append(s)
            # ranuras (glifos) en cada escalón
            for side in range(4):
                g = prim("cube", f"{name}g{k}{side}", scale=(w * 0.6, 0.02, 0.4 / steps))
                g.rotation_euler = (0, 0, side * math.pi / 2)
                g.location = (math.cos(side * math.pi / 2 + math.pi / 2) * -w / 2 * 0 + 0, 0, 0)
                select_only([g])
                bpy.ops.object.transform_apply(rotation=True)
                off = Vector((0, w / 2 + 0.005, k / steps + 0.5 / steps))
                rot = Matrix.Rotation(side * math.pi / 2, 3, "Z")
                g.location = rot @ off
                select_only([g])
                bpy.ops.object.transform_apply(location=True)
                parts.append(g)
        tip = prim("cone", name + "_punta", seg=4, r1=0.1, r2=0, h=0.18, at=(0, 0, 1.08), rot=(0, 0, math.pi / 4))
        parts.append(tip)
        return join(parts, name)
    if name == "ColumnaRuina":
        col = prim("cyl", name, seg=24, r=0.5, h=3, at=(0, 0, 1.5))
        for v in col.data.vertices:
            a = math.atan2(v.co.y, v.co.x)
            f = 1 - 0.06 * (0.5 + 0.5 * math.cos(a * 12))
            v.co.x *= f
            v.co.y *= f
        col.data.update()
        # rota arriba (corte inclinado)
        cut = prim("cube", name + "_corte", at=(0, 0, 3.35), rot=(0.4, 0.15, 0), scale=(2, 2, 0.8))
        b = col.modifiers.new("rota", "BOOLEAN")
        b.operation = "DIFFERENCE"
        b.object = cut
        b.solver = "EXACT"
        apply_all(col)
        bpy.data.objects.remove(cut, do_unlink=True)
        base = prim("cube", name + "_base", at=(0, 0, 0.12), scale=(1.25, 1.25, 0.24))
        cap = prim("cube", name + "_anillo", at=(0, 0, 0.32), scale=(1.1, 1.1, 0.12))
        return join([col, base, cap], name)
        return join([col, base], name)
    raise ValueError(name)


# ---------------------------------------------------------------------------
# Materiales (para hornear y para las vistas previas)
# ---------------------------------------------------------------------------
PALETTE = {
    "Warm": [(238, 98, 128), (248, 146, 74), (250, 204, 92), (232, 120, 160)],
    "Cool": [(150, 98, 214), (92, 200, 196), (118, 140, 232), (196, 110, 220)],
    "Glow": [(90, 245, 255), (150, 255, 190), (255, 130, 230), (170, 150, 255)],
    "Kelp": [(118, 132, 52), (96, 118, 44), (140, 128, 54)],
    "Grass": [(78, 150, 92), (104, 164, 76), (66, 132, 108)],
}


def srgb(c):
    def lin(x):
        x = x / 255
        return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4
    return (lin(c[0]), lin(c[1]), lin(c[2]), 1)


def depth_mix(nt, color_socket, surface_z):
    """Oscurece y azula el color con la profundidad (z en studs; la superficie en surface_z)."""
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Position"], sep.inputs["Vector"])
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value = surface_z
    mr.inputs["From Max"].default_value = surface_z - 120
    mr.inputs["To Min"].default_value = 0
    mr.inputs["To Max"].default_value = 0.85
    nt.links.new(sep.outputs["Z"], mr.inputs["Value"])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MIX"
    nt.links.new(mr.outputs["Result"], mix.inputs["Factor"])
    nt.links.new(color_socket, mix.inputs[6])
    mix.inputs[7].default_value = (0.004, 0.03, 0.07, 1)
    return mix.outputs[2]


def bake_material(name, kind):
    m = bpy.data.materials.new("B_" + name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    b.name = "BSDF"
    b.inputs["Roughness"].default_value = 0.85
    tc = nt.nodes.new("ShaderNodeTexCoord")
    n1 = nt.nodes.new("ShaderNodeTexNoise")
    n1.inputs["Scale"].default_value = {"rock": 3.5, "wood": 2, "ruin": 1.5, "life": 6}[kind]
    n1.inputs["Detail"].default_value = 8
    nt.links.new(tc.outputs["Object"], n1.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    cols = {
        "rock": [(0.35, (0.12, 0.115, 0.105)), (0.72, (0.42, 0.40, 0.36))],
        "wood": [(0.3, (0.10, 0.07, 0.045)), (0.75, (0.30, 0.22, 0.15))],
        "ruin": [(0.3, (0.04, 0.07, 0.09)), (0.75, (0.12, 0.17, 0.2))],
        "life": [(0.3, (0.6, 0.35, 0.25)), (0.75, (0.95, 0.75, 0.6))],
    }[kind]
    ramp.color_ramp.elements[0].position, ramp.color_ramp.elements[0].color = cols[0][0], (*cols[0][1], 1)
    ramp.color_ramp.elements[1].position, ramp.color_ramp.elements[1].color = cols[1][0], (*cols[1][1], 1)
    nt.links.new(n1.outputs["Fac"], ramp.inputs["Fac"])
    color = ramp.outputs["Color"]
    if kind in ("rock", "wood"):
        # musgo y percebes: manchas verdes y blancas
        n3 = nt.nodes.new("ShaderNodeTexNoise")
        n3.inputs["Scale"].default_value = 9
        nt.links.new(tc.outputs["Object"], n3.inputs["Vector"])
        cr = nt.nodes.new("ShaderNodeMapRange")
        cr.inputs["From Min"].default_value = 0.58
        cr.inputs["From Max"].default_value = 0.66
        nt.links.new(n3.outputs["Fac"], cr.inputs["Value"])
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        nt.links.new(cr.outputs["Result"], mix.inputs["Factor"])
        nt.links.new(color, mix.inputs[6])
        mix.inputs[7].default_value = (0.09, 0.2, 0.08, 1) if kind == "rock" else (0.55, 0.52, 0.45, 1)
        color = mix.outputs[2]
    if kind == "ruin":
        # vetas que brillan (cian) en las ranuras: en la textura, claras
        wave = nt.nodes.new("ShaderNodeTexWave")
        wave.inputs["Scale"].default_value = 3
        nt.links.new(tc.outputs["Object"], wave.inputs["Vector"])
        cr = nt.nodes.new("ShaderNodeMapRange")
        cr.inputs["From Min"].default_value = 0.93
        cr.inputs["From Max"].default_value = 0.97
        nt.links.new(wave.outputs["Fac"], cr.inputs["Value"])
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        nt.links.new(cr.outputs["Result"], mix.inputs["Factor"])
        nt.links.new(color, mix.inputs[6])
        mix.inputs[7].default_value = (0.25, 0.85, 1.0, 1)
        color = mix.outputs[2]
    nt.links.new(color, b.inputs["Base Color"])
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 12
    nt.links.new(tc.outputs["Object"], vor.inputs["Vector"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.5
    bump.inputs["Distance"].default_value = 0.02
    nt.links.new(vor.outputs["Distance"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    target = nt.nodes.new("ShaderNodeTexImage")
    target.name = "BakeTarget"
    nt.nodes.active = target
    return m


KIND = {"RocaPorosa": "rock", "Canto": "rock", "RocaLaja": "rock", "RocaAguja": "rock", "Pilote": "wood", "Piramide": "ruin", "ColumnaRuina": "ruin", "Estrella": "life", "Concha": "life", "Erizo": "life", "Cangrejo": "life"}


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
    obj.data.materials.clear()
    obj.data.materials.append(mat)
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


def export(obj, out_dir):
    select_only([obj])
    fbx = os.path.join(out_dir, obj.name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=True, add_leaf_bones=False, path_mode="STRIP", embed_textures=False, use_custom_props=False)
    return fbx


def caustics(path, size=512, seed=7):
    """Textura de cáusticas que se repite sin costuras: bordes de celdas de Voronoi (numpy)."""
    import numpy as np
    from PIL import Image, ImageFilter

    rng = np.random.default_rng(seed)
    pts = rng.random((48, 2)) * size
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    d1 = np.full((size, size), 1e9, np.float32)
    d2 = np.full((size, size), 1e9, np.float32)
    for px, py in pts:
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d = np.hypot(xx - (px + ox), yy - (py + oy))
                closer = d < d1
                d2 = np.where(closer, d1, np.minimum(d2, d))
                d1 = np.where(closer, d, d1)
    edge = d2 - d1
    v = np.clip(1 - edge / 9.0, 0, 1) ** 2.2
    img = Image.fromarray((v * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.6))
    Image.merge("RGBA", (img, img, img, img)).save(path)


def build_kit(out_dir, tex_size):
    kit = read_kit()
    os.makedirs(os.path.join(out_dir, "tex"), exist_ok=True)
    manifest = {"Piezas": []}
    objs = {}
    for name in sorted(kit):
        info = kit[name]
        rnd = random.Random(zlib.crc32(name.encode()) % 10000 + 7)
        log(f"pieza {name}")
        obj = make_piece(name, rnd)
        obj.name = name
        obj = finish(obj, info)
        entry = {"Nombre": name, "Tris": tris_of(obj), "Size": list(obj["medida"]), "Tint": info["Tint"], "FBX": name + ".fbx"}
        want = info["Size"]
        got = obj["medida"]
        if abs(got[0] - want[0]) > 0.06 * want[0] + 0.05 or abs(got[2] - want[2]) > 0.06 * want[2] + 0.05:
            log(f"  ⚠️ {name}: MarKit.Size = {{ {want[0]}, {want[1]}, {want[2]} }} pero la malla mide {{ {got[0]}, {got[1]}, {got[2]} }}")
        if not info["Tint"]:
            unwrap(obj)
            mat = bake_material(name, KIND.get(name, "rock"))
            paths = bake(obj, mat, tex_size, os.path.join(out_dir, "tex"), name.lower())
            entry["Texturas"] = {k: os.path.relpath(v, out_dir) for k, v in paths.items()}
            obj["baked"] = paths
        export(obj, out_dir)
        manifest["Piezas"].append(entry)
        objs[name] = obj
    caustics(os.path.join(out_dir, "tex", "causticas.png"))
    manifest["Causticas"] = "tex/causticas.png"
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    log(f"kit: {len(objs)} piezas en {out_dir}")
    return kit, objs


# ---------------------------------------------------------------------------
# Render (vistas previas)
# ---------------------------------------------------------------------------
def preview_material(name, info, color, surface_z, baked=None):
    m = bpy.data.materials.new("P_" + name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    b.inputs["Roughness"].default_value = 0.6
    if baked:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(baked["color"], check_existing=True)
        col = tex.outputs["Color"]
        nor = nt.nodes.new("ShaderNodeTexImage")
        nor.image = bpy.data.images.load(baked["normal"], check_existing=True)
        nor.image.colorspace_settings.name = "Non-Color"
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(nor.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    else:
        rgb = nt.nodes.new("ShaderNodeRGB")
        rgb.outputs[0].default_value = srgb(color)
        col = rgb.outputs[0]
        # un poco de variación (punta más clara)
        geo = nt.nodes.new("ShaderNodeNewGeometry")
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.inputs["Factor"].default_value = 0.0
        pt = nt.nodes.new("ShaderNodeMapRange")
        pt.inputs["From Min"].default_value = 0.45
        pt.inputs["From Max"].default_value = 0.6
        pt.inputs["To Max"].default_value = 0.35
        nt.links.new(geo.outputs["Pointiness"], pt.inputs["Value"])
        nt.links.new(pt.outputs["Result"], mix.inputs["Factor"])
        nt.links.new(col, mix.inputs[6])
        mix.inputs[7].default_value = (1, 0.95, 0.9, 1)
        col = mix.outputs[2]
    nt.links.new(depth_mix(nt, col, surface_z), b.inputs["Base Color"])
    if info and (info.get("Glow") and info["Group"] == "Luz"):
        b.inputs["Emission Color"].default_value = srgb(color)
        b.inputs["Emission Strength"].default_value = 3.0
    return m


def label(path, title, sub=None):
    from PIL import Image, ImageDraw, ImageFont

    im = Image.open(path).convert("RGB")
    d = ImageDraw.Draw(im)
    try:
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
        f2 = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
    except OSError:
        f = f2 = ImageFont.load_default()
    w, h = im.size
    d.rectangle([0, 0, w, 34], fill=(10, 14, 22))
    d.text((10, 6), "VISTA PREVIA, NO ES ROBLOX", fill=(255, 210, 80), font=f)
    x0 = 20 + int(d.textlength("VISTA PREVIA, NO ES ROBLOX", font=f))
    d.text((x0, 9), "· " + title, fill=(230, 240, 250), font=f2)
    if sub:
        d.rectangle([0, h - 26, w, h], fill=(10, 14, 22))
        d.text((10, h - 22), sub, fill=(200, 220, 235), font=f2)
    im.save(path, quality=88)


def setup_render(w, h, samples, fog, vis):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.render.resolution_x = w
    scene.render.resolution_y = h
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 92
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("Agua")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (*fog[:3], 1)
    bg.inputs["Strength"].default_value = 0.7
    world.mist_settings.start = 0
    world.mist_settings.depth = vis
    world.mist_settings.falloff = "LINEAR"
    scene.view_layers[0].use_pass_mist = True
    # Composición: bruma = 1 - exp(-k·distancia)
    scene.use_nodes = True
    nt = scene.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    rl = nt.nodes.new("CompositorNodeRLayers")
    m1 = nt.nodes.new("CompositorNodeMath")
    m1.operation = "MULTIPLY"
    m1.inputs[1].default_value = -2.6
    nt.links.new(rl.outputs["Mist"], m1.inputs[0])
    ex = nt.nodes.new("CompositorNodeMath")
    ex.operation = "EXPONENT"
    nt.links.new(m1.outputs[0], ex.inputs[0])
    inv = nt.nodes.new("CompositorNodeMath")
    inv.operation = "SUBTRACT"
    inv.inputs[0].default_value = 1.0
    nt.links.new(ex.outputs[0], inv.inputs[1])
    mix = nt.nodes.new("CompositorNodeMixRGB")
    nt.links.new(inv.outputs[0], mix.inputs["Fac"])
    nt.links.new(rl.outputs["Image"], mix.inputs[1])
    mix.inputs[2].default_value = (*fog[:3], 1)
    comp = nt.nodes.new("CompositorNodeComposite")
    nt.links.new(mix.outputs[0], comp.inputs["Image"])


def sun(direction=(0.3, 0.2, -1), strength=3.2, color=(1, 0.97, 0.9)):
    light = bpy.data.lights.new("Sol", "SUN")
    light.energy = strength
    light.color = color
    light.angle = math.radians(3)
    o = new_obj("Sol", light)
    o.rotation_euler = Vector(direction).to_track_quat("-Z", "Y").to_euler()
    return o


def camera_at(pos, forward, fov_v=70):
    cam = bpy.data.cameras.new("Camara")
    cam.sensor_fit = "VERTICAL"
    cam.angle_y = math.radians(fov_v)
    cam.clip_end = 2000
    o = new_obj("Camara", cam)
    o.location = pos
    o.rotation_euler = Vector(forward).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = o
    return o


def rb(x, y, z):
    """Roblox (X, Y arriba, Z) -> Blender (x, -z, y)"""
    return (x, -z, y)


def render_kit(kit, objs, out_img, samples):
    log("vista previa del kit")
    names = sorted(objs, key=lambda n: (kit[n]["Group"], n))
    surface = 40.0
    floor = bpy.data.meshes.new("Arena")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=2, y_segments=2, size=200)
    bm.to_mesh(floor)
    fo = new_obj("Arena", floor)
    fm = bpy.data.materials.new("ArenaM")
    fm.use_nodes = True
    fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = srgb((204, 186, 146))
    fo.data.materials.append(fm)
    cols = 6
    spacing = 9.5
    rows = math.ceil(len(names) / cols)
    marks = []
    for i, n in enumerate(names):
        info = kit[n]
        o = objs[n]
        r, c = divmod(i, cols)
        x = (c - (cols - 1) / 2) * spacing
        y = (r - (rows - 1) / 2) * spacing * 1.2
        H = info["Size"][1]
        k = 6.5 / max(H, max(info["Size"][0], info["Size"][2]))
        if n == "KelpGigante":
            k = 9.0 / H
        inst = o.copy()
        inst.data = o.data
        bpy.context.scene.collection.objects.link(inst)
        inst.location = (x, y, 0)
        inst.scale = (k, k, k)
        palette = PALETTE["Glow"] if info["Group"] == "Luz" else PALETTE["Kelp"] if n == "KelpGigante" else PALETTE["Grass"] if info["Group"] == "Planta" else PALETTE["Warm"]
        color = palette[i % len(palette)]
        mat = preview_material(n, info, color, surface, o.get("baked") and dict(o["baked"]))
        inst.data = o.data.copy()
        inst.data.materials.clear()
        inst.data.materials.append(mat)
        marks.append((n, Vector((x, y - 1.0, 0))))
    for o in objs.values():
        o.hide_render = True
    setup_render(1600, 900, samples, (0.03, 0.16, 0.2), 400)
    sun((0.4, 0.5, -1), 3.5)
    cam = camera_at((0, -48, 34), Vector((0, 48, -40)), fov_v=42)
    bpy.context.scene.render.filepath = out_img
    bpy.ops.render.render(write_still=True)
    # nombres
    from bpy_extras.object_utils import world_to_camera_view
    from PIL import Image, ImageDraw, ImageFont

    im = Image.open(out_img).convert("RGB")
    d = ImageDraw.Draw(im)
    try:
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    except OSError:
        f = ImageFont.load_default()
    W, Hh = im.size
    for n, p in marks:
        v = world_to_camera_view(bpy.context.scene, cam, p)
        x, y = v.x * W, (1 - v.y) * Hh
        d.text((x - 4 * len(n), y + 6), n, fill=(255, 255, 255), font=f, stroke_width=2, stroke_fill=(0, 0, 0))
    im.save(out_img, quality=88)
    label(out_img, "Kit del mar (Blender): 23 piezas", "Corales, plantas y luz van con el color de la paleta de la zona; rocas, vida pequeña, pilote y ruinas, con su textura horneada")


def voxel_mesh(meta, vox_path):
    import numpy as np
    from skimage import measure

    nx, nz, ny = meta["NX"], meta["NZ"], meta["NY"]
    raw = np.frombuffer(open(vox_path, "rb").read(), dtype=np.uint8).reshape((ny, nz, nx))
    from skimage.filters import gaussian

    solid = (raw > 0).astype(np.float32)
    # bordes cerrados (el fondo y los lados de la caja) y suavizado (el terreno de Roblox también es liso)
    pad = np.pad(solid, 1, mode="constant", constant_values=0)
    pad[0, :, :] = 1  # debajo de todo, sólido
    pad = gaussian(pad, sigma=0.9, preserve_range=True)
    verts, faces, _, _ = measure.marching_cubes(pad, 0.5)
    step = meta["Step"]
    out_v = []
    mats = []
    for (j, k, i) in verts:
        jj, kk, ii = j - 1, k - 1, i - 1
        X = meta["X0"] + (ii + 0.5) * step
        Y = meta["Y0"] + (jj + 0.5) * step
        Z = meta["Z0"] + (kk + 0.5) * step
        out_v.append(rb(X, Y, Z))
        # material: el vóxel sólido más cercano por debajo o al lado
        best = 1
        for dj, dk, di in ((0, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1), (-2, 0, 0)):
            a, b, c = int(round(jj)) + dj, int(round(kk)) + dk, int(round(ii)) + di
            if 0 <= a < ny and 0 <= b < nz and 0 <= c < nx and raw[a, b, c] > 0:
                best = int(raw[a, b, c])
                break
        mats.append(best)
    mesh = bpy.data.meshes.new("Terreno")
    mesh.from_pydata(out_v, [], [tuple(f[::-1]) for f in faces])
    mesh.update()
    obj = new_obj("Terreno", mesh)
    # color por vértice (material)
    colors = {
        1: (204, 186, 146),  # arena dorada clara
        2: (118, 116, 110),  # roca
        3: (198, 190, 166),  # caliza
        4: (190, 166, 122),  # arenisca (ondas)
        5: (130, 110, 80),  # tierra
        6: (78, 74, 64),  # fango
        7: (232, 214, 172),  # playa
    }
    ca = mesh.color_attributes.new("Mat", "FLOAT_COLOR", "POINT")
    for i, m in enumerate(mats):
        ca.data[i].color = srgb(colors.get(m, (150, 150, 150)))
    for p in mesh.polygons:
        p.use_smooth = True
    log(f"terreno: {len(out_v)} vértices, {len(faces)} triángulos")
    return obj


def terrain_material(surface_z):
    m = bpy.data.materials.new("TerrenoM")
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    b.inputs["Roughness"].default_value = 0.9
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Mat"
    # grano (ruido) para que la roca no sea lisa
    tc = nt.nodes.new("ShaderNodeTexCoord")
    nz = nt.nodes.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 0.35
    nz.inputs["Detail"].default_value = 10
    nt.links.new(tc.outputs["Object"], nz.inputs["Vector"])
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["To Min"].default_value = 0.7
    mr.inputs["To Max"].default_value = 1.15
    nt.links.new(nz.outputs["Fac"], mr.inputs["Value"])
    mul = nt.nodes.new("ShaderNodeMix")
    mul.data_type = "RGBA"
    mul.blend_type = "MULTIPLY"
    mul.inputs["Factor"].default_value = 1.0
    nt.links.new(attr.outputs["Color"], mul.inputs[6])
    nt.links.new(mr.outputs["Result"], mul.inputs[7])
    nt.links.new(depth_mix(nt, mul.outputs[2], surface_z), b.inputs["Base Color"])
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 0.6
    nt.links.new(tc.outputs["Object"], vor.inputs["Vector"])
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.35
    nt.links.new(vor.outputs["Distance"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m


def render_zone(kit, objs, zone_json, docs_dir, samples, only=None):
    data = json.load(open(zone_json, encoding="utf-8"))
    meta = data["Voxels"]
    surface = data["Surface"]
    terr = voxel_mesh(meta, meta["File"])
    terr.data.materials.append(terrain_material(surface))
    # la superficie del agua (vista desde abajo: un espejo turquesa claro)
    sm = bpy.data.meshes.new("Superficie")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=2, y_segments=2, size=1200)
    bm.to_mesh(sm)
    so = new_obj("Superficie", sm)
    so.location = (4570, 300, surface)
    smat = bpy.data.materials.new("SuperficieM")
    smat.use_nodes = True
    bs = smat.node_tree.nodes["Principled BSDF"]
    bs.inputs["Base Color"].default_value = (0.2, 0.7, 0.75, 1)
    bs.inputs["Emission Color"].default_value = (0.25, 0.75, 0.8, 1)
    bs.inputs["Emission Strength"].default_value = 0.9
    so.data.materials.append(smat)
    so.visible_shadow = False
    # las piezas del kit (como World/ReefZoneBuilder con las mallas subidas)
    mat_cache = {}
    for o in objs.values():
        if len(o.data.materials) == 0:
            o.data.materials.append(None)
    for p in data["Placements"]:
        n = p["Kind"]
        o = objs.get(n)
        if not o:
            continue
        info = kit[n]
        k = p["Scale"] / info["Size"][1]
        key = (n, tuple(p["Color"]))
        if key not in mat_cache:
            mat_cache[key] = preview_material(f"{n}_{len(mat_cache)}", info, p["Color"], surface, o.get("baked") and dict(o["baked"]))
        inst = bpy.data.objects.new(f"i_{n}", o.data)
        bpy.context.scene.collection.objects.link(inst)
        inst.location = rb(p["X"], p["Y"], p["Z"])
        rot = Matrix.Rotation(-p["Yaw"], 4, "Z")
        if p.get("Tilt"):
            rot = rot @ Matrix.Rotation(p["Tilt"], 4, "Y")
        inst.rotation_euler = rot.to_euler()
        inst.scale = (k, k, k)
        slot = inst.material_slots[0]
        slot.link = "OBJECT"
        slot.material = mat_cache[key]
    for o in objs.values():
        o.hide_render = True
    # luces de la zona y haces
    for l in data["Lights"]:
        ld = bpy.data.lights.new("Luz", "POINT")
        ld.energy = l["Brightness"] * 4000
        ld.color = tuple(c / 255 for c in l["Color"])
        ld.shadow_soft_size = 1
        lo = new_obj("Luz", ld)
        lo.location = rb(l["X"], l["Y"], l["Z"])
    hm = bpy.data.materials.new("Haz")
    hm.use_nodes = True
    nt = hm.node_tree
    for n_ in list(nt.nodes):
        nt.nodes.remove(n_)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (0.7, 0.92, 1, 1)
    em.inputs["Strength"].default_value = 0.12
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    add = nt.nodes.new("ShaderNodeAddShader")
    nt.links.new(em.outputs[0], add.inputs[0])
    nt.links.new(tr.outputs[0], add.inputs[1])
    nt.links.new(add.outputs[0], out.inputs["Surface"])
    for s in data["Shafts"]:
        h = s["Top"] - s["Bottom"]
        bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=s["R"], depth=h)
        c = bpy.context.view_layer.objects.active
        c.location = rb(s["X"], (s["Top"] + s["Bottom"]) / 2, s["Z"])
        c.rotation_euler = (s.get("Tilt", 0), 0, 0)
        c.data.materials.append(hm)
        c.visible_shadow = False
    fog = (0.012, 0.11, 0.16)
    setup_render(1280, 720, samples, fog, 200)
    sun((0.25, 0.35, -1), 2.6, (0.9, 0.97, 1.0))
    paths = []
    for idx, cam in enumerate(data["Cameras"]):
        if only and (idx + 1) not in only:
            continue
        yaw, pitch = math.radians(cam["Yaw"]), math.radians(cam["Pitch"])
        fwd = (math.cos(pitch) * math.cos(yaw), math.sin(pitch), math.cos(pitch) * math.sin(yaw))
        c = camera_at(rb(cam["X"], cam["Y"], cam["Z"]), rb(*fwd))
        # bruma más oscura cuanto más hondo está la cámara
        depth = max(0.0, surface - cam["Y"])
        k = min(1.0, depth / 90)
        f = (fog[0] * (1 - k) + 0.004 * k, fog[1] * (1 - k) + 0.035 * k, fog[2] * (1 - k) + 0.08 * k)
        bpy.context.scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (*f, 1)
        mixn = [n for n in bpy.context.scene.node_tree.nodes if n.bl_idname == "CompositorNodeMixRGB"][0]
        mixn.inputs[2].default_value = (*f, 1)
        path = os.path.join(docs_dir, f"v2-vista-{idx + 1:02d}.jpg")
        bpy.context.scene.render.filepath = path
        bpy.context.scene.render.image_settings.file_format = "JPEG"
        log(f"vista {cam['Name']}")
        bpy.ops.render.render(write_still=True)
        res = None
        for r in data.get("Results", []):
            if r["Name"] == cam["Name"]:
                res = r
        label(path, f"Cañón de Dorada · {cam['Name']}", f"cámara de 3ª persona en X={cam['X']:.0f} Y={cam['Y']:.0f} Z={cam['Z']:.0f} (prof. {depth / 3.57:.0f} m) · geometría del juego, kit de Blender, luz aproximada")
        paths.append(path)
        bpy.data.objects.remove(c, do_unlink=True)
    return paths


def contact_sheet(paths, out, cols=3):
    from PIL import Image

    ims = [Image.open(p) for p in paths]
    w, h = 640, 360
    rows = math.ceil(len(ims) / cols)
    sheet = Image.new("RGB", (w * cols, h * rows), (8, 12, 18))
    for i, im in enumerate(ims):
        sheet.paste(im.resize((w, h)), ((i % cols) * w, (i // cols) * h))
    sheet.save(out, quality=86)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "assets/mar"))
    ap.add_argument("--docs", default=os.path.join(ROOT, "docs/mar"))
    ap.add_argument("--tex", type=int, default=512)
    ap.add_argument("--muestras", type=int, default=32)
    ap.add_argument("--zona", default=None, help="JSON de scripts/map/canon-export.luau: también las vistas del cañón")
    ap.add_argument("--solo-zona", default=None, help="solo las vistas del cañón (sin volver a exportar el kit)")
    ap.add_argument("--vistas", default=None, help="solo estas cámaras (1,3,7)")
    ap.add_argument("--no-render", action="store_true")
    args = ap.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:])
    reset_scene()
    out = args.out
    if args.solo_zona:
        out = os.path.join("/dev/shm", "mar-kit-tmp")
    kit, objs = build_kit(out, args.tex)
    if args.no_render:
        return
    zone = args.zona or args.solo_zona
    if not args.solo_zona:
        # (la vista del kit en una escena aparte)
        render_kit(kit, objs, os.path.join(args.docs, "v2-kit-vista-previa.jpg"), args.muestras)
        for o in list(bpy.context.scene.objects):
            if o.name not in objs:
                bpy.data.objects.remove(o, do_unlink=True)
    if zone:
        only = [int(x) for x in args.vistas.split(",")] if args.vistas else None
        paths = render_zone(kit, objs, zone, args.docs, args.muestras, only)
        if not only:
            contact_sheet(paths, os.path.join(args.docs, "v2-vistas.jpg"))
    log("listo")


if __name__ == "__main__":
    main()
