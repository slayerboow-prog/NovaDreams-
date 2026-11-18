"""El ÁRBOL ANCESTRAL del Santuario del Bosque, hecho en Blender con Python (17-11-2026, el dueño: «reconstruye
completamente el Santuario del Bosque y su Árbol Ancestral», referencia docs/mapa/santuario-referencia.png).

Geometría propia y procedural (siempre igual: semilla fija), con UV cilíndricas para que la corteza y las hojas se
repitan sin costuras:
  * Tronco  tronco gigante e irregular (contrafuertes en la base, surcos de corteza retorcidos, protuberancias) y
            raíces enormes que salen en arco y se hunden en el suelo
  * Ramas   ramas gruesas que se abren y se entrelazan (tres niveles)
  * Copa1..5 masas de follaje abultadas y orgánicas (no bolas lisas), más arriba que abajo
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
                k = 0.86 + lump * abs(noise.noise(d * 1.9 + V(seed, seed * 1.3, seed * 0.4))) * 1.5 + 0.16 * abs(noise.noise(d * 4.6 + V(seed, 0, 0)))
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
# (18-11-2026, el dueño manda la imagen del santuario: tronco GORDO y no muy alto, hecho de hebras que se retuercen
# y que arriba se ABREN y se convierten en las ramas maestras; copa enorme y ancha de racimos abultados)
H = 118.0
NT = 40
trunk_pts = []
trunk_r = []
for i in range(NT):
    t = i / (NT - 1)
    y = t * H
    sway = V(math.sin(t * 2.2 + 0.8) * 6 * t, 0, math.cos(t * 1.7 + 0.3) * 5 * t)
    trunk_pts.append(V(0, y, 0) + sway)
    trunk_r.append(46 - 15 * t ** 0.8)


def trunk_flare(th, t):
    # contrafuertes en la base (seis lóbulos) que se pierden hacia arriba
    lobes = max(0.0, math.cos(th * 6 + 0.4)) ** 2.5
    base = math.exp(-t * 9)
    return 1.0 + base * (0.5 + 0.6 * lobes)


def _sm(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


tronco = Mesh()
tronco.tube(trunk_pts, [r * 0.7 for r in trunk_r], 40, urep=4.0, rough=0.14, ridges=18, twist=0.012, flare=trunk_flare, seed=1.7, cap=True)
STRANDS = 5
strand_paths = []
strand_radii = []
for k in range(STRANDS):
    pts, radii = [], []
    for i, c in enumerate(trunk_pts):
        t = i / (NT - 1)
        ang = k / STRANDS * math.tau + t * 1.05 * math.tau
        # (abajo, abiertas en contrafuerte; arriba se separan para salir como ramas)
        spread = trunk_r[i] * 0.52 * (1 + 0.8 * math.exp(-t * 7)) * (1 + 0.45 * _sm((t - 0.7) / 0.3))
        pts.append(c + V(math.cos(ang) * spread, 0, math.sin(ang) * spread))
        radii.append(trunk_r[i] * 0.47 * (1 + 0.3 * math.exp(-t * 7)))
    tronco.tube(pts, radii, 26, urep=2.0, rough=0.2, ridges=10, twist=0.02, seed=7.3 + k, cap=True)
    strand_paths.append(pts)
    strand_radii.append(radii)

# RAÍCES REALISTAS (18-11-2026, el dueño: «haz las raíces más realistas»): junto al tronco salen como CONTRAFUERTES
# (tablones altos y delgados que suben por el tronco); al alejarse se APLANAN (más anchas que altas, con la panza
# plana contra el suelo); tienen nudos y bultos, se retuercen, se hunden en la tierra y vuelven a asomar en arco;
# se abren en raíces hijas y raicillas que acaban metiéndose en el suelo. Van en su propia pieza.
raices = Mesh()
roots_top = []


def root_tube(mesh, pts, prof, segs, seed, knots=0.22, urep=2.0):
    """Tubo de sección ELÍPTICA (ancho w en horizontal, alto h en vertical, panza aplastada) con nudos."""
    n = len(pts)
    up = V(0, 1, 0)
    base = len(mesh.verts)
    length = 0.0
    avg = sum(w + h for w, h in prof) / (2 * n)
    for i in range(n):
        if i > 0:
            length += (pts[i] - pts[i - 1]).length
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, n - 1)]
        t = (b - a).normalized()
        # (la sección se mide siempre en horizontal y en vertical: aunque la raíz baje en picado, no se vuelve
        # una losa de canto)
        th_ = V(t.x, 0, t.z)
        side = up.cross(th_.normalized()) if th_.length > 1e-4 else V(1, 0, 0)
        upv = up
        w, h = prof[i]
        # nudo: un bulto que engorda la raíz a trozos
        kn = 1.0 + knots * max(0.0, noise.noise(V(length * 0.045, seed, 0.3))) * 1.6
        for s in range(segs + 1):
            th = s / segs * math.tau
            cs, sn = math.cos(th), math.sin(th)
            hh = h if sn >= 0 else h * 0.42
            q = V(cs * 1.4, length * 0.05, sn * 1.4) + V(seed, seed * 0.6, 1.0)
            k = kn * (1.0 + 0.12 * noise.noise(q) + 0.05 * math.sin(th * 7 + length * 0.08))
            mesh.verts.append(pts[i] + side * (cs * w * k) + upv * (sn * hh * k))
            mesh.uvs.append((s / segs * urep, length / (math.tau * avg) * urep))
    wv = segs + 1
    for i in range(n - 1):
        for s in range(segs):
            a = base + i * wv + s
            mesh.faces.append((a, a + 1, a + wv + 1))
            mesh.faces.append((a, a + wv + 1, a + wv))
    ci = len(mesh.verts)
    mesh.verts.append(pts[-1])
    mesh.uvs.append((0.5, 0.5))
    last = base + (n - 1) * wv
    for s in range(segs):
        mesh.faces.append((last + s, last + s + 1, ci))


def smooth(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def rootlet(p0, d, L, r, seed):
    """Raicilla fina que se mete en el suelo."""
    pts, prof = [], []
    for j in range(6):
        t = j / 5
        sd = V(0, 1, 0).cross(d).normalized()
        pts.append(p0 + d * (L * t) + sd * (math.sin(t * 4 + seed) * L * 0.12) + V(0, -t ** 1.6 * (r * 3 + 3), 0))
        rr = r * (1 - 0.75 * t) + 0.25
        prof.append((rr * 1.2, rr * 0.8))
    root_tube(raices, pts, prof, 5, seed, knots=0.1, urep=1.0)


for i in range(16):
    a = i / 16 * math.tau + random.uniform(-0.1, 0.1)
    # (el camino de la entrada, hacia la ciudad = −Z, queda libre: por ahí se llega al altar del núcleo y al guardián)
    if abs(((a - 1.5 * math.pi) + math.pi) % math.tau - math.pi) < math.radians(30):
        continue
    d = V(math.cos(a), 0, math.sin(a))
    sd = V(0, 1, 0).cross(d).normalized()
    L = random.uniform(115, 170)
    r0 = random.uniform(12, 16)
    ph = random.uniform(0, math.tau)
    n = 22
    pts, prof = [], []
    for j in range(n):
        u = j / (n - 1)
        t = u ** 1.35  # anillos más juntos cerca del tronco (allí cambia la forma)
        f = math.exp(-t / 0.2)  # 1 = contrafuerte, 0 = raíz plana
        taper = 1 - 0.82 * t
        w = r0 * taper * (0.55 * f + 1.3 * (1 - f))
        h = r0 * taper * (2.3 * f ** 1.5 + 0.55 * (1 - f))
        # se hunde y vuelve a asomar (en arco), y al final se mete en la tierra
        amp = r0 * 0.38 * taper * smooth(t * 3)
        und = amp * math.sin(t * math.pi * 3.2 + ph)
        sink = -smooth((t - 0.82) / 0.18) * (h * 1.5 + 2)
        yc = 0.42 * h - 1.5 + und * (1 - f) + sink
        wig = math.sin(t * 4.5 + ph) * 0.1 * L * t + noise.noise(V(i * 1.7, t * 3, 0)) * 0.07 * L * t
        p = d * (12 + L * t) + sd * wig + V(0, yc, 0)
        pts.append(p)
        prof.append((w, h))
    root_tube(raices, pts, prof, 14, 3.1 + i, knots=0.25)
    roots_top.append([p + V(0, h * 1.02 + 0.5, 0) for p, (w, h) in zip(pts[:14], prof[:14])])
    # raíces hijas (planas) que se abren a los lados y raicillas al final
    for c in range(random.choice((2, 2, 3))):
        j = random.randint(7, 14)
        turn = random.choice((-1, 1)) * random.uniform(0.5, 1.0)
        cd = (d * math.cos(turn) + sd * math.sin(turn)).normalized()
        csd = V(0, 1, 0).cross(cd).normalized()
        cw, ch = prof[j]
        cL = L * random.uniform(0.3, 0.45)
        cph = random.uniform(0, math.tau)
        cpts, cprof = [], []
        start = pts[j] - V(0, 0.42 * ch - 0.42 * ch * 0.55, 0)
        for k in range(12):
            t = k / 11
            taper = 1 - 0.8 * t
            ww, hh = cw * 0.55 * taper + 0.4, ch * 0.55 * taper + 0.3
            und = hh * 0.6 * math.sin(t * math.pi * 2.4 + cph) * smooth(t * 3)
            sink = -smooth((t - 0.7) / 0.3) * (hh * 1.8 + 2)
            cpts.append(start + cd * (cL * t) + csd * (math.sin(t * 3 + cph) * cL * 0.12) + V(0, und * 0.5 + sink, 0))
            cprof.append((ww, hh))
        root_tube(raices, cpts, cprof, 8, 9.0 + i * 3 + c, knots=0.2, urep=1.5)
        rootlet(cpts[7], (cd + csd * random.uniform(-0.8, 0.8)).normalized(), cL * 0.35, cprof[7][1] * 0.35, i + c * 5.0)
    for c in range(2):
        j = random.randint(14, 19)
        cd = (d + sd * random.uniform(-0.9, 0.9)).normalized()
        rootlet(pts[j], cd, L * 0.22, prof[j][1] * 0.4, i * 2.3 + c)

# (las ramas y la copa no dependen del azar de las raíces)
random.seed(99171)

# RAMAS: cada hebra del tronco sigue hacia fuera como una RAMA MAESTRA gruesa que se abre casi en horizontal y luego
# sube; de ella salen ramas y ramitas que acaban dentro de la copa
ramas = Mesh()
tips = []
limb_paths = []
UP = V(0, 1, 0)


def branch(p, d, L, r, depth, seed):
    side = d.cross(UP)
    if side.length < 1e-3:
        side = V(1, 0, 0)
    side.normalize()
    p3 = p + (d + UP * 0.3).normalized() * L
    p1 = p + d * L * 0.35 + side * random.uniform(-0.15, 0.15) * L
    p2 = p + (d * 0.65 + UP * 0.3).normalized() * L * 0.72
    pts = bezier(p, p1, p2, p3, 7 if depth >= 2 else 5)
    radii = [r * (1 - 0.45 * (j / (len(pts) - 1))) for j in range(len(pts))]
    ramas.tube(pts, radii, 10 if depth >= 2 else 6, urep=2.0, rough=0.12, ridges=6 if depth >= 2 else 0, twist=0.02, seed=seed, cap=True)
    if depth == 0:
        tips.append((p3, d))
        return
    kids = random.choice((2, 3))
    for c in range(kids):
        spin = c / kids * math.tau + random.uniform(-0.6, 0.6)
        sd = (d * 0.7 + V(math.cos(spin), 0, math.sin(spin)) * 0.55 + UP * random.uniform(0.15, 0.4)).normalized()
        branch(p3, sd, L * random.uniform(0.55, 0.7), radii[-1] * 0.95, depth - 1, seed + c * 1.7)


for k, sp in enumerate(strand_paths):
    j0 = NT - 6  # (la rama arranca un poco por debajo de la punta de la hebra: no se ve la junta)
    s0 = sp[j0]
    c0 = trunk_pts[j0]
    o = V(s0.x - c0.x, 0, s0.z - c0.z).normalized()
    sd = UP.cross(o).normalized()
    L = random.uniform(105, 122)
    tw = random.uniform(-0.25, 0.25)
    od = (o + sd * tw).normalized()
    p1 = s0 + (od * 0.35 + UP * 0.9).normalized() * 34
    p2 = s0 + od * L * 0.55 + UP * L * 0.42
    p3 = s0 + od * L + UP * L * 0.62
    pts = bezier(s0, p1, p2, p3, 16)
    r0 = strand_radii[k][j0] * 0.98
    radii = [r0 * (1 - 0.62 * (j / 15)) for j in range(16)]
    ramas.tube(pts, radii, 16, urep=2.0, rough=0.16, ridges=8, twist=0.02, seed=20.0 + k, cap=True)
    limb_paths.append((pts, radii))
    # ramas que salen de la mitad y de la punta
    for jj, ln in ((8, 70), (11, 62), (15, 58)):
        q = pts[jj]
        tan = (pts[min(jj + 1, 15)] - pts[jj - 1]).normalized()
        h = V(tan.x, 0, tan.z).normalized()
        turn = random.choice((-1, 1)) * random.uniform(0.4, 0.9) if jj < 15 else random.uniform(-0.3, 0.3)
        bd = (h * math.cos(turn) + UP.cross(h).normalized() * math.sin(turn) + UP * 0.35).normalized()
        branch(q, bd, ln * random.uniform(0.9, 1.1), radii[jj] * 0.7, 2 if jj < 15 else 1, 30.0 + k * 3 + jj)
# la guía del centro, que sube entre las ramas maestras
branch(trunk_pts[-1], V(0.05, 1, 0.08).normalized(), 70, trunk_r[-1] * 0.45, 2, 40.0)

# COPA: una cúpula enorme y ancha hecha de muchos RACIMOS abultados (como coliflores), con los bordes que caen un
# poco y huecos oscuros entre racimos; un racimo en la punta de cada ramita
blobs = []
CC = V(0, 226, 0)
for q in range(175):
    a = random.uniform(0, math.tau)
    e = math.acos(1 - random.uniform(0, 1.25))  # de arriba hasta algo por debajo del ecuador
    shell = random.uniform(0.82, 1.0) if q < 150 else random.uniform(0.45, 0.7)
    c = CC + V(math.sin(e) * math.cos(a) * 168 * shell, math.cos(e) * 88 * shell, math.sin(e) * math.sin(a) * 168 * shell)
    if e > math.pi / 2:
        c.y -= (e - math.pi / 2) * 30  # (los bordes caen)
    s = random.uniform(25, 35) * (1.15 if e < 0.6 else 1.0)
    blobs.append((c, s * random.uniform(1.0, 1.2), s * 0.78, s * random.uniform(1.0, 1.2)))
for t, d in tips:
    s = random.uniform(17, 24)
    blobs.append((t + V(0, 5, 0), s * 1.15, s * 0.8, s * 1.15))
random.shuffle(blobs)
copas = [Mesh() for _ in range(5)]
for i, (c, rx, ry, rz) in enumerate(blobs):
    copas[i % 5].blob(c, rx, ry, rz, segs=16, rings=9, lump=0.34, seed=i * 0.73)

# VENAS de energía: cintas gruesas que suben retorciéndose por cada hebra (y otra que cruza la hebra en ondas),
# espirales grabadas en el tronco, y siguen por las ramas maestras y por algunas raíces
venas = Mesh()
for k, sp in enumerate(strand_paths):
    for wv in (0, 1):
        pts, radii = [], []
        for i in range(2, NT - 4):
            t = i / (NT - 1)
            c = trunk_pts[i]
            off = sp[i] - c
            outward = V(off.x, 0, off.z).normalized()
            tang = UP.cross(outward).normalized()
            rr = strand_radii[k][i]
            wob = math.sin(t * 9 + k * 1.3) * 0.55 if wv else 0.0
            dirv = (outward * math.cos(wob) + tang * math.sin(wob)).normalized()
            pts.append(sp[i] + dirv * rr * 1.0)
            radii.append(1.3 + 0.6 * math.sin(t * 11 + k + wv))
        venas.tube(pts, radii, 6, urep=1.0)
# espirales (como en la imagen: se enroscan sobre el tronco)
for k in range(STRANDS):
    i = 9 + (k * 5) % 18
    sp = strand_paths[k]
    c = trunk_pts[i]
    off = sp[i] - c
    outward = V(off.x, 0, off.z).normalized()
    tang = UP.cross(outward).normalized()
    rr = strand_radii[k][i]
    pts = []
    for s in range(34):
        th = s / 33 * math.tau * 1.6
        rad = 1.5 + s / 33 * rr * 0.55
        local = tang * math.cos(th) * rad + UP * math.sin(th) * rad
        # (se curva con la superficie de la hebra)
        bulge = math.sqrt(max(rr * rr - rad * rad * 0.5, 1.0))
        pts.append(sp[i] + outward * (bulge + 0.6) + local)
    venas.tube(pts, [1.0] * len(pts), 6, urep=1.0)
for pts, radii in limb_paths:
    vp = []
    for j in range(11):
        a = (pts[min(j + 1, 15)] - pts[max(j - 1, 0)]).normalized()
        sideh = UP.cross(a).normalized()
        upn = a.cross(sideh).normalized()
        if upn.y < 0:
            upn = -upn
        vp.append(pts[j] + upn * radii[j] * 1.0 + sideh * math.sin(j * 0.9) * radii[j] * 0.4)
    venas.tube(vp, [1.1] * len(vp), 6, urep=1.0)
for i in range(0, len(roots_top), 2):
    venas.tube(roots_top[i], [0.9] * len(roots_top[i]), 6, urep=1.0)

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
    for tag, eye, target in (("lejos", (430, -430, 120), (0, 0, 130)), ("cerca", (0, -330, 25), (0, 0, 110))):
        cam.location = Vector(eye)
        d = Vector(target) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(ROOT, "docs", "mapa", f"arbol-blender-{tag}.png")
        bpy.ops.render.render(write_still=True)
    print("vistas previas hechas")
