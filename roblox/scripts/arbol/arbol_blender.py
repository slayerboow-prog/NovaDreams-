"""El ÁRBOL ANCESTRAL del Santuario del Bosque, hecho en Blender con Python (17-11-2026, el dueño: «reconstruye
completamente el Santuario del Bosque y su Árbol Ancestral», referencia docs/mapa/santuario-referencia.png).

Geometría propia y procedural (siempre igual: semilla fija), con UV cilíndricas para que la corteza y las hojas se
repitan sin costuras:
  * Tronco  tronco gigante e irregular (contrafuertes en la base, surcos de corteza retorcidos, protuberancias) y
            raíces enormes que salen en arco y se hunden en el suelo
  * Ramas   ramas gruesas que se abren y se entrelazan (tres niveles)
  * Copa1..4 masas de follaje abultadas y orgánicas (no bolas lisas), más arriba que abajo
  * Venas   vetas de energía que suben retorciéndose por el tronco y las raíces (Neon en Roblox)
Cada pieza ≤ 20.000 triángulos (límite de una MeshPart).

Uso (desde la carpeta roblox/):
  "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P scripts/arbol/arbol_blender.py
Salida: assets/arbol/<Pieza>.fbx y assets/arbol/manifest.json (centro y tamaño en studs respecto al pie del árbol,
triángulos y material). Las texturas: scripts/arbol/texturas.py. Subir: scripts/upload-arbol.sh.
"""
import json
import math
import os
import random

import bmesh
import bpy
from mathutils import Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "assets", "arbol")
os.makedirs(OUT, exist_ok=True)

random.seed(20261117)
MAX_TRIS = 19500


def V(x, y, z):
    return Vector((x, y, z))


def to_blender(p):
    # Roblox (x derecha, y arriba, z) -> Blender (x, -z, y); el FBX se exporta con Y arriba y -Z delante
    return Vector((p.x, -p.z, p.y))


class Mesh:
    def __init__(self):
        self.verts = []
        self.uvs = []
        self.faces = []  # (índices, uvs)

    def tube(self, pts, radii, segs, urep=2.0, rough=0.0, ridges=0, twist=0.0, flare=None, seed=0.0, cap=False):
        """Un tubo a lo largo de pts (Roblox) con radios por anillo. Devuelve la lista de anillos (posiciones)."""
        n = len(pts)
        # marcos por transporte paralelo
        tangents = []
        for i in range(n):
            a = pts[max(i - 1, 0)]
            b = pts[min(i + 1, n - 1)]
            t = (b - a)
            tangents.append(t.normalized() if t.length > 1e-6 else V(0, 1, 0))
        ref = V(1, 0, 0) if abs(tangents[0].x) < 0.9 else V(0, 0, 1)
        n1 = tangents[0].cross(ref).normalized()
        frames = []
        for i in range(n):
            t = tangents[i]
            n1 = (n1 - t * n1.dot(t))
            if n1.length < 1e-6:
                n1 = t.cross(V(1, 0, 0))
            n1.normalize()
            n2 = t.cross(n1).normalized()
            frames.append((n1, n2))
        base = len(self.verts)
        length = 0.0
        rings = []
        avg_r = sum(radii) / len(radii)
        for i in range(n):
            if i > 0:
                length += (pts[i] - pts[i - 1]).length
            n1, n2 = frames[i]
            ring = []
            for s in range(segs + 1):
                th = s / segs * math.tau
                ang = th + twist * length
                r = radii[i]
                if rough > 0:
                    q = V(math.cos(th) * 1.3, length * 0.035, math.sin(th) * 1.3) + V(seed, seed * 0.7, 0)
                    r *= 1.0 + rough * noise.noise(q)
                if ridges > 0:
                    r *= 1.0 + 0.045 * math.sin(ang * ridges + noise.noise(V(th * 2, length * 0.05, seed)) * 2.5)
                if flare:
                    r *= flare(th, i / max(n - 1, 1))
                p = pts[i] + (n1 * math.cos(th) + n2 * math.sin(th)) * r
                self.verts.append(p)
                self.uvs.append((s / segs * urep, length / (math.tau * avg_r) * urep))
                ring.append(p)
            rings.append(ring)
        w = segs + 1
        for i in range(n - 1):
            for s in range(segs):
                a = base + i * w + s
                b = a + 1
                c = a + w + 1
                d = a + w
                self.faces.append((a, b, c))
                self.faces.append((a, c, d))
        if cap:
            ci = len(self.verts)
            self.verts.append(pts[-1])
            self.uvs.append((0.5, 0.5))
            last = base + (n - 1) * w
            for s in range(segs):
                self.faces.append((last + s, last + s + 1, ci))
        return rings

    def blob(self, c, rx, ry, rz, segs=18, rings=11, lump=0.28, seed=0.0, urep=3.0):
        """Una masa de follaje abultada (esfera deformada con ruido)."""
        base = len(self.verts)
        for j in range(rings + 1):
            ph = j / rings * math.pi
            for s in range(segs + 1):
                th = s / segs * math.tau
                d = V(math.sin(ph) * math.cos(th), math.cos(ph), math.sin(ph) * math.sin(th))
                k = 1.0 + lump * noise.noise(d * 1.6 + V(seed, seed * 1.3, seed * 0.4)) + 0.12 * noise.noise(d * 4.5 + V(seed, 0, 0))
                # (la parte de abajo, más plana: la copa se ve apoyada en las ramas)
                yk = 0.65 if d.y < 0 else 1.0
                self.verts.append(c + V(d.x * rx * k, d.y * ry * k * yk, d.z * rz * k))
                self.uvs.append((s / segs * urep, j / rings * urep * 0.6))
        w = segs + 1
        for j in range(rings):
            for s in range(segs):
                a = base + j * w + s
                self.faces.append((a, a + w, a + w + 1))
                self.faces.append((a, a + w + 1, a + 1))

    def tris(self):
        return len(self.faces)

    def build(self, name):
        me = bpy.data.meshes.new(name)
        bm = bmesh.new()
        bverts = [bm.verts.new(to_blender(v)) for v in self.verts]
        uvl = bm.loops.layers.uv.new("UVMap")
        for f in self.faces:
            try:
                face = bm.faces.new([bverts[i] for i in f])
            except ValueError:
                continue
            for loop, idx in zip(face.loops, f):
                loop[uvl].uv = self.uvs[idx]
        # (Roblox pinta una sola cara: todas las caras, mirando hacia fuera)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.normal_update()
        bm.to_mesh(me)
        bm.free()
        for poly in me.polygons:
            poly.use_smooth = True
        obj = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def bezier(p0, p1, p2, p3, n):
    out = []
    for i in range(n):
        t = i / (n - 1)
        u = 1 - t
        out.append(p0 * u ** 3 + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t ** 3)
    return out


# ------------------------------------------------------------------ el árbol
H = 165.0
trunk_pts = []
trunk_r = []
for i in range(46):
    t = i / 45
    y = t * H
    sway = V(math.sin(t * 2.4 + 0.8) * 9 * t, 0, math.cos(t * 1.9 + 0.3) * 7 * t)
    trunk_pts.append(V(0, y, 0) + sway)
    trunk_r.append(40 - 22 * t ** 0.75)


def trunk_flare(th, t):
    # contrafuertes en la base (seis lóbulos) que se pierden hacia arriba
    lobes = max(0.0, math.cos(th * 6 + 0.4)) ** 2.5
    base = math.exp(-t * 9)
    return 1.0 + base * (0.55 + 0.7 * lobes)


tronco = Mesh()
# el alma del tronco (más fina) y, alrededor, cuatro troncos que se ENTRELAZAN en espiral, como en la referencia
tronco.tube(trunk_pts, [r * 0.72 for r in trunk_r], 40, urep=4.0, rough=0.14, ridges=18, twist=0.012, flare=trunk_flare, seed=1.7, cap=True)
STRANDS = 4
strand_paths = []
for k in range(STRANDS):
    pts, radii = [], []
    for i, c in enumerate(trunk_pts):
        t = i / 45
        ang = k / STRANDS * math.tau + t * 1.55 * math.tau
        spread = trunk_r[i] * 0.48 * (1 + 0.9 * math.exp(-t * 7))
        pts.append(c + V(math.cos(ang) * spread, 0, math.sin(ang) * spread))
        radii.append(trunk_r[i] * 0.5 * (1 + 0.35 * math.exp(-t * 7)))
    tronco.tube(pts, radii, 24, urep=2.0, rough=0.18, ridges=10, twist=0.02, seed=7.3 + k, cap=True)
    strand_paths.append(pts)

# RAÍCES: muchas, largas y bajas, que serpentean por el suelo del patio (cada una con raíces hijas), como en la
# referencia del dueño; van en su propia pieza
raices = Mesh()
roots_center = []


def snake(p0, d, L, r0, n, seed, rise=10.0, sink=-9.0):
    side = V(0, 1, 0).cross(d).normalized()
    pts, radii = [], []
    for j in range(n):
        t = j / (n - 1)
        wig = math.sin(t * 5.0 + seed) * 0.12 * L * t + noise.noise(V(seed, t * 3, 0)) * 0.06 * L
        hgt = rise * math.sin(min(t * 1.6, 1.0) * math.pi * 0.9) * (1 - t) + sink * t ** 2.2
        pts.append(p0 + d * (L * t) + side * wig + V(0, hgt, 0))
        radii.append(r0 * (1 - 0.86 * t) + 0.9)
    return pts, radii


for i in range(16):
    a = i / 16 * math.tau + random.uniform(-0.1, 0.1)
    # (el camino de la entrada, hacia la ciudad = −Z, queda libre: por ahí se llega al altar del núcleo y al guardián)
    if abs(((a - 1.5 * math.pi) + math.pi) % math.tau - math.pi) < math.radians(28):
        continue
    d = V(math.cos(a), 0, math.sin(a))
    L = random.uniform(120, 175)
    p0 = d * 34 + V(0, 16, 0)
    pts, radii = snake(p0, d, L, random.uniform(13, 18), 20, i * 1.37, rise=random.uniform(6, 13))
    raices.tube(pts, radii, 14, urep=2.0, rough=0.2, ridges=7, twist=0.02, seed=3.1 + i, cap=True)
    roots_center.append(pts)
    # una o dos raíces hijas que salen de la mitad
    for c in range(random.choice((1, 2))):
        j = random.randint(6, 11)
        turn = random.choice((-1, 1)) * random.uniform(0.5, 0.9)
        cd = (d * math.cos(turn) + V(0, 1, 0).cross(d) * math.sin(turn)).normalized()
        cpts, crad = snake(pts[j], cd, L * random.uniform(0.35, 0.5), radii[j] * 0.65, 10, i * 3.1 + c, rise=3, sink=-6)
        raices.tube(cpts, crad, 8, urep=1.5, rough=0.2, seed=9.0 + i + c, cap=True)

# ramas (tres niveles)
ramas = Mesh()
tips = []
branch_paths = []


def branch(p, d, L, r, depth, seed):
    up = V(0, 1, 0)
    side = d.cross(up)
    if side.length < 1e-3:
        side = V(1, 0, 0)
    side.normalize()
    bend = (d + up * 0.25).normalized()
    p3 = p + bend * L
    p1 = p + d * L * 0.35 + side * random.uniform(-0.12, 0.12) * L
    p2 = p + (d * 0.6 + up * 0.35).normalized() * L * 0.7
    pts = bezier(p, p1, p2, p3, 8 if depth >= 2 else 5)
    radii = [r * (1 - 0.38 * (j / (len(pts) - 1))) for j in range(len(pts))]
    ramas.tube(pts, radii, 12 if depth >= 2 else 7, urep=2.0, rough=0.12, ridges=8 if depth >= 2 else 0, twist=0.02, seed=seed, cap=True)
    branch_paths.append(pts)
    if depth == 0:
        tips.append(p3)
        return
    kids = 3 if depth == 3 else random.choice((2, 3))
    for c in range(kids):
        spin = c / kids * math.tau + random.uniform(-0.5, 0.5)
        sd = (d * 0.55 + V(math.cos(spin), 0, math.sin(spin)) * 0.6 + up * random.uniform(0.25, 0.5)).normalized()
        branch(p3, sd, L * random.uniform(0.6, 0.72), radii[-1] * 0.9, depth - 1, seed + c * 1.7)


for i in range(7):
    j = 26 + int(i * 2.6)
    a = i / 7 * math.tau + random.uniform(-0.25, 0.25)
    d = (V(math.cos(a), 0, math.sin(a)) * 0.9 + V(0, random.uniform(0.22, 0.4), 0)).normalized()
    branch(trunk_pts[j], d, random.uniform(72, 88), trunk_r[j] * 0.5, 3, 10.0 + i)
# la guía de arriba
branch(trunk_pts[-1], V(0.1, 1, 0.05).normalized(), 40, trunk_r[-1] * 0.7, 2, 40.0)

# copa: masas grandes sobre una cúpula y masas en cada punta
blobs = []
top = trunk_pts[-1] + V(0, 30, 0)
for q in range(46):
    a = random.uniform(0, math.tau)
    e = math.acos(1 - random.uniform(0, 1.1))
    shell = random.uniform(0.7, 1.0)
    c = top + V(math.sin(e) * math.cos(a) * 118 * shell, math.cos(e) * 44 * shell - 6, math.sin(e) * math.sin(a) * 118 * shell)
    s = random.uniform(30, 44)
    blobs.append((c, s * random.uniform(1.0, 1.25), s * 0.72, s * random.uniform(1.0, 1.25)))
for t in tips:
    s = random.uniform(18, 26)
    blobs.append((t + V(0, 4, 0), s * 1.2, s * 0.75, s * 1.2))

copas = [Mesh() for _ in range(4)]
for i, (c, rx, ry, rz) in enumerate(blobs):
    copas[i % 4].blob(c, rx, ry, rz, segs=18, rings=10, lump=0.3, seed=i * 0.73)

# venas de energía: suben retorciéndose por el tronco y siguen por algunas raíces
venas = Mesh()
for k, sp in enumerate(strand_paths):
    for side in (1,):
        pts, radii = [], []
        for i in range(0, 40):
            t = i / 45
            c = trunk_pts[i]
            off = sp[i] - c
            ln = off.length
            outward = off.normalized() if ln > 1e-3 else V(1, 0, 0)
            tang = V(0, 1, 0).cross(outward).normalized()
            rr = trunk_r[i] * 0.5 * (1 + 0.35 * math.exp(-t * 7))
            pts.append(sp[i] + outward * rr * 0.86 + tang * side * rr * 0.45)
            radii.append(0.55 if i % 9 else 0.85)
        venas.tube(pts, radii, 6, urep=1.0)
for i in range(0, len(roots_center), 2):
    rp = roots_center[i]
    pts = [p + V(0, 14 * (1 - 0.86 * (j / 19)) + 1.6, 0) for j, p in enumerate(rp[:15])]
    venas.tube(pts, [0.5] * len(pts), 6, urep=1.0)

# ------------------------------------------------------------------ exportar
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)

pieces = [("Tronco", tronco, "Wood", "corteza"), ("Raices", raices, "Wood", "corteza"), ("Ramas", ramas, "Wood", "corteza")]
for i, m in enumerate(copas):
    pieces.append((f"Copa{i + 1}", m, "Grass", "hojas"))
pieces.append(("Venas", venas, "Neon", None))

manifest = {"Name": "Árbol Ancestral", "Height": H, "Pieces": []}
for name, mesh, material, tset in pieces:
    tris = mesh.tris()
    if tris > MAX_TRIS:
        raise SystemExit(f"{name}: {tris} triángulos (máximo {MAX_TRIS})")
    obj = mesh.build(name)
    xs = [v.x for v in mesh.verts]
    ys = [v.y for v in mesh.verts]
    zs = [v.z for v in mesh.verts]
    center = [(min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2]
    size = [max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)]
    for o in bpy.context.scene.objects:
        if o is not None:
            o.select_set(o == obj)
    bpy.context.view_layer.objects.active = obj
    fbx = os.path.join(OUT, name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", add_leaf_bones=False, path_mode="STRIP")
    manifest["Pieces"].append({"Name": name, "Tris": tris, "Material": material, "Set": tset, "Center": center, "Size": size})
    print(f"{name}: {tris} triángulos, tamaño {size[0]:.0f} x {size[1]:.0f} x {size[2]:.0f}")

with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf8") as f:
    json.dump(manifest, f, indent=1, ensure_ascii=False)
print("listo:", OUT)

# ------------------------------------------------------------------ vista previa (ARBOL_RENDER=1)
if os.environ.get("ARBOL_RENDER"):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "OBJECT"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.display.shading.cavity_type = "BOTH"
    scene.render.resolution_x, scene.render.resolution_y = 1280, 720
    cols = {"Tronco": (0.42, 0.29, 0.19, 1), "Raices": (0.4, 0.28, 0.18, 1), "Ramas": (0.45, 0.31, 0.2, 1), "Venas": (0.3, 0.85, 1, 1)}
    for o in scene.objects:
        o.color = cols.get(o.name, (0.22, 0.52, 0.26, 1))
    # suelo
    bpy.ops.mesh.primitive_plane_add(size=900, location=(0, 0, 0))
    bpy.context.active_object.color = (0.3, 0.45, 0.25, 1)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = 28
    for tag, eye, target in (("lejos", (380, -380, 130), (0, 0, 110)), ("cerca", (150, -170, 30), (0, 0, 80))):
        cam.location = Vector(eye)
        d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(ROOT, "docs", "mapa", f"arbol-blender-{tag}.png")
        bpy.ops.render.render(write_still=True)
    print("vistas previas hechas")
