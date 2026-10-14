"""Geometría procedural de superficie dura para las naves (scripts/nave/nave_blender.py).

Todo se escribe en coordenadas de ROBLOX (X derecha, Y arriba, Z hacia atrás: el morro mira a -Z) y se
pasa a Blender (X, -Z, Y) al crear el objeto. Con el FBX exportado con axis_forward='-Z', axis_up='Y'
(lo de siempre), el archivo vuelve a quedar en coordenadas de Roblox.

Piezas: lofts (secciones cerradas a lo largo de un eje), tornos (perfil que gira), cajas orientadas,
cilindros entre dos puntos y «placas» (losas que siguen una superficie paramétrica: blindaje en capas).
No depende de la nave: lo puede usar cualquier generador (naves alienígenas de la grieta, etc.).
"""
import math

import bmesh
import bpy
from mathutils import Vector


def to_blender(p):
    return Vector((p[0], -p[2], p[1]))


def V(x, y=None, z=None):
    if y is None:
        return Vector(x)
    return Vector((x, y, z))


class MeshBuilder:
    """Acumula vértices y caras (con índice de material) en coordenadas de Roblox."""

    def __init__(self, materials):
        self.materials = list(materials)  # nombres
        self.verts = []
        self.faces = []
        self.mats = []

    def mat(self, name):
        if name not in self.materials:
            self.materials.append(name)
        return self.materials.index(name)

    def v(self, p):
        self.verts.append(Vector(p))
        return len(self.verts) - 1

    def face(self, idx, mat):
        self.faces.append(list(idx))
        self.mats.append(self.mat(mat) if isinstance(mat, str) else mat)

    # ------------------------------------------------------------------ primitivas
    def loft(self, rings, mat, cap0=True, cap1=True, matfn=None):
        """rings: lista de anillos (mismo número de puntos, cerrados). matfn(centro, i_anillo, j) -> material"""
        n = len(rings[0])
        ids = [[self.v(p) for p in ring] for ring in rings]
        for i in range(len(rings) - 1):
            for j in range(n):
                a, b = ids[i][j], ids[i][(j + 1) % n]
                c, d = ids[i + 1][(j + 1) % n], ids[i + 1][j]
                m = mat
                if matfn:
                    center = (rings[i][j] + rings[i][(j + 1) % n] + rings[i + 1][j] + rings[i + 1][(j + 1) % n]) / 4
                    m = matfn(center, i, j) or mat
                self.face([a, b, c, d], m)
        if cap0:
            self.face(list(reversed(ids[0])), mat)
        if cap1:
            self.face(ids[-1], mat)
        return ids

    def lathe(self, profile, center, segs, mat, axis="z", matfn=None, cap0=True, cap1=True, phase=0.0):
        """profile: [(r, t)] a lo largo del eje; center: punto del eje en t=0."""
        cx, cy, cz = center
        rings = []
        for r, t in profile:
            ring = []
            for k in range(segs):
                a = phase + 2 * math.pi * k / segs
                ca, sa = math.cos(a) * r, math.sin(a) * r
                if axis == "z":
                    ring.append(V(cx + ca, cy + sa, cz + t))
                elif axis == "y":
                    ring.append(V(cx + ca, cy + t, cz + sa))
                else:
                    ring.append(V(cx + t, cy + ca, cz + sa))
            rings.append(ring)
        return self.loft(rings, mat, cap0, cap1, matfn)

    def box(self, center, size, mat, right=(1, 0, 0), up=(0, 1, 0), taper=None):
        """Caja orientada. taper=(sx, sy): escala de la cara de delante (-fwd) para cuñas/chaflanes."""
        c = Vector(center)
        r = Vector(right).normalized()
        u = Vector(up).normalized()
        f = r.cross(u).normalized()  # (r x u = -fwd en Roblox: hacia el morro es -Z; aquí f apunta a +Z)
        hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
        rings = []
        for sz, scale in ((-hz, taper or (1, 1)), (hz, (1, 1))):
            ring = []
            for sx_, sy_ in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                ring.append(c + r * (sx_ * hx * scale[0]) + u * (sy_ * hy * scale[1]) + f * sz)
            rings.append(ring)
        return self.loft(rings, mat)

    def cylinder(self, p0, p1, radius, segs, mat, r1=None, caps=True):
        p0, p1 = Vector(p0), Vector(p1)
        axis = (p1 - p0).normalized()
        helper = Vector((0, 1, 0)) if abs(axis.y) < 0.9 else Vector((1, 0, 0))
        a = axis.cross(helper).normalized()
        b = axis.cross(a).normalized()
        rings = []
        for p, r in ((p0, radius), (p1, radius if r1 is None else r1)):
            rings.append([p + (a * math.cos(2 * math.pi * k / segs) + b * math.sin(2 * math.pi * k / segs)) * r for k in range(segs)])
        return self.loft(rings, mat, caps, caps)

    def slab(self, surf, u0, u1, v0, v1, nu, height, mat, vbreaks=(), inset=0.015, side_mat=None):
        """Placa (losa) que sigue la superficie surf(u, v) -> (punto, normal). Las vbreaks (pliegues de
        la superficie) se muestrean siempre para que la placa no corte por dentro."""
        us = [u0 + (u1 - u0) * i / nu for i in range(nu + 1)]
        vs = sorted({v0, v1, *[b for b in vbreaks if v0 < b < v1]})
        top, bot = [], []
        for u in us:
            rt, rb = [], []
            for v in vs:
                p, n = surf(u, v)
                rt.append(p + n * height)
                rb.append(p - n * inset)
            top.append(rt)
            bot.append(rb)
        nv = len(vs)
        T = [[self.v(p) for p in row] for row in top]
        Bt = [[self.v(p) for p in row] for row in bot]
        sm = side_mat or mat
        for i in range(len(us) - 1):
            for j in range(nv - 1):
                self.face([T[i][j], T[i][j + 1], T[i + 1][j + 1], T[i + 1][j]], mat)
                self.face([Bt[i][j], Bt[i + 1][j], Bt[i + 1][j + 1], Bt[i][j + 1]], sm)
        for i in range(len(us) - 1):  # bordes v0 y v1
            self.face([T[i][0], T[i + 1][0], Bt[i + 1][0], Bt[i][0]], sm)
            self.face([T[i][-1], Bt[i][-1], Bt[i + 1][-1], T[i + 1][-1]], sm)
        for j in range(nv - 1):  # bordes u0 y u1
            self.face([T[0][j], Bt[0][j], Bt[0][j + 1], T[0][j + 1]], sm)
            self.face([T[-1][j], T[-1][j + 1], Bt[-1][j + 1], Bt[-1][j]], sm)

    def mirror_x(self):
        """Duplica todo lo construido hasta ahora reflejado en X (la otra mitad)."""
        nv = len(self.verts)
        for i in range(nv):
            p = self.verts[i]
            self.verts.append(Vector((-p.x, p.y, p.z)))
        for f, m in list(zip(self.faces, self.mats)):
            self.faces.append([i + nv for i in reversed(f)])
            self.mats.append(m)

    # ------------------------------------------------------------------ al objeto de Blender
    def build(self, name, collection=None):
        me = bpy.data.meshes.new(name)
        me.from_pydata([to_blender(p) for p in self.verts], [], self.faces)
        for i, f in enumerate(me.polygons):
            f.material_index = self.mats[i]
        me.update()
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me)
        bm.free()
        obj = bpy.data.objects.new(name, me)
        (collection or bpy.context.scene.collection).objects.link(obj)
        for m in self.materials:
            me.materials.append(bpy.data.materials.get(m) or bpy.data.materials.new(m))
        return obj


# ---------------------------------------------------------------------- interpolación
def catmull(points, t):
    """Catmull-Rom sobre una lista de valores (escalares o tuplas) con t en [0, len-1]."""
    n = len(points)
    i = min(max(int(math.floor(t)), 0), n - 2)
    f = t - i
    p0 = points[max(i - 1, 0)]
    p1 = points[i]
    p2 = points[i + 1]
    p3 = points[min(i + 2, n - 1)]

    def cr(a, b, c, d):
        return 0.5 * ((2 * b) + (-a + c) * f + (2 * a - 5 * b + 4 * c - d) * f * f + (-a + 3 * b - 3 * c + d) * f * f * f)

    if isinstance(p1, (tuple, list)):
        return tuple(cr(p0[k], p1[k], p2[k], p3[k]) for k in range(len(p1)))
    return cr(p0, p1, p2, p3)


def resample_stations(stations, key, step):
    """stations: lista de tuplas (z, ...) ordenadas por z. Devuelve muchas más, suaves (Catmull-Rom)."""
    zs = [s[key] for s in stations]
    out = []
    for i in range(len(stations) - 1):
        steps = max(1, int(math.ceil(abs(zs[i + 1] - zs[i]) / step)))
        for k in range(steps):
            out.append(catmull(stations, i + k / steps))
    out.append(tuple(stations[-1]))
    return out


def poly_point(pts, s):
    """Punto en un polígono cerrado con parámetro s en [0, n): entre pts[floor(s)] y el siguiente."""
    n = len(pts)
    s = s % n
    i = int(math.floor(s))
    f = s - i
    a, b = pts[i], pts[(i + 1) % n]
    return a.lerp(b, f)


def merge(dst, src):
    """Añade el contenido de otro MeshBuilder (mapeando materiales por nombre)."""
    off = len(dst.verts)
    dst.verts.extend(src.verts)
    for f, m in zip(src.faces, src.mats):
        dst.faces.append([i + off for i in f])
        dst.mats.append(dst.mat(src.materials[m]))
    return dst


def surface_normal(fn, u, v, du=1e-3, dv=1e-3, outward_hint=None):
    p = fn(u, v)
    pu = fn(u + du, v) - fn(u - du, v)
    pv = fn(u, v + dv) - fn(u, v - dv)
    n = pu.cross(pv)
    if n.length < 1e-9:
        n = Vector((0, 1, 0))
    n.normalize()
    if outward_hint is not None and n.dot(outward_hint(p)) < 0:
        n = -n
    return p, n
