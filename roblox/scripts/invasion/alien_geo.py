"""Geometría orgánica para los alienígenas de la Invasión de la Grieta (scripts/invasion/alien_blender.py).

Se apoya en el MeshBuilder de scripts/nave/geo.py (coordenadas de ROBLOX: X derecha, Y arriba, el frente a
-Z). Aquí van las piezas que necesitan los seres vivos y las naves de otras galaxias:

    blob      elipsoide con bultos (ruido determinista): cuerpos, cabezas, caparazones
    tube      tubo que sigue una línea con radios por punto: tentáculos, brazos, patas, tubos
    crystal   prisma facetado con punta: cristales, púas, cuernos
    torus     aro: halos, anillos de motor, collares
    shell     cuenco (media esfera hueca con borde): conchas, campanas, capuchas
    fin       aleta/hoja plana con grosor (contorno en un plano): alas, aletas, cuchillas

Todo es determinista (sin random): la misma entrada da la misma malla en cada ejecución.
"""
import math

from mathutils import Matrix, Vector


def V(x, y=None, z=None):
    if y is None:
        return Vector(x)
    return Vector((x, y, z))


def hnoise(p, seed=0.0, freq=1.0):
    """Ruido suave (-1..1) a partir de senos: barato, determinista y sin costuras."""
    x, y, z = p[0] * freq, p[1] * freq, p[2] * freq
    s = seed * 1.618
    n = math.sin(x * 1.7 + s * 3.1 + math.sin(y * 2.3 + s)) * 0.5
    n += math.sin(y * 2.9 - z * 1.3 + s * 1.7 + math.sin(x * 1.1)) * 0.3
    n += math.sin(z * 3.7 + x * 0.7 + s * 0.3 + math.sin(y * 1.9 + s * 2.0)) * 0.2
    return n


def frame_for(axis):
    """Dos vectores perpendiculares a axis (y entre sí)."""
    axis = Vector(axis).normalized()
    helper = Vector((0, 1, 0)) if abs(axis.y) < 0.9 else Vector((1, 0, 0))
    a = axis.cross(helper).normalized()
    b = axis.cross(a).normalized()
    return a, b


def rot_matrix(yaw=0.0, pitch=0.0, roll=0.0):
    """Rotación (radianes) en ejes de Roblox: yaw alrededor de Y, pitch alrededor de X, roll alrededor de Z."""
    return Matrix.Rotation(yaw, 3, "Y") @ Matrix.Rotation(pitch, 3, "X") @ Matrix.Rotation(roll, 3, "Z")


def blob(mb, center, radii, mat, nu=16, nv=10, noise=0.0, seed=0.0, freq=2.0, rot=None, shape=None, top=1.0, bottom=-1.0):
    """Elipsoide (de bottom a top en la vertical normalizada, -1..1) con ruido opcional.
    shape(u, v) -> factor de radio (u = 0..1 alrededor, v = -1..1 de abajo arriba)."""
    c = Vector(center)
    rx, ry, rz = radii
    R = rot or Matrix.Identity(3)
    rings = []
    steps = nv
    for i in range(steps + 1):
        v = bottom + (top - bottom) * i / steps
        phi = math.asin(max(-1.0, min(1.0, v)))
        ring_r = max(math.cos(phi), 0.02)
        y = math.sin(phi)
        ring = []
        for k in range(nu):
            u = k / nu
            a = 2 * math.pi * u
            local = Vector((math.cos(a) * ring_r * rx, y * ry, math.sin(a) * ring_r * rz))
            f = 1.0
            if shape:
                f *= shape(u, v)
            if noise:
                f *= 1.0 + noise * hnoise(local, seed, freq)
            ring.append(c + R @ (local * f))
        rings.append(ring)
    return mb.loft(rings, mat, cap0=True, cap1=True)


def tube(mb, pts, radii, mat, segs=8, caps=True, squash=1.0, twist=0.0, matfn=None):
    """Tubo por una línea de puntos con transporte paralelo del marco (no se retuerce solo)."""
    pts = [Vector(p) for p in pts]
    if isinstance(radii, (int, float)):
        radii = [radii] * len(pts)
    tangents = []
    for i in range(len(pts)):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        t = b - a
        tangents.append(t.normalized() if t.length > 1e-6 else Vector((0, 1, 0)))
    n, _ = frame_for(tangents[0])
    rings = []
    for i, p in enumerate(pts):
        t = tangents[i]
        n = (n - t * n.dot(t))
        if n.length < 1e-6:
            n, _ = frame_for(t)
        n.normalize()
        b = t.cross(n).normalized()
        r = radii[i]
        ring = []
        for k in range(segs):
            a = 2 * math.pi * k / segs + twist * i
            ring.append(p + n * (math.cos(a) * r) + b * (math.sin(a) * r * squash))
        rings.append(ring)
    return mb.loft(rings, mat, caps, caps, matfn)


def bezier(p0, p1, p2, p3, n):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append(Vector(p0) * (u ** 3) + Vector(p1) * (3 * u * u * t) + Vector(p2) * (3 * u * t * t) + Vector(p3) * (t ** 3))
    return out


def crystal(mb, a, b, r, mat, sides=6, tip=0.3, base=0.12, twist=0.0, flat=1.0):
    """Prisma facetado de a (base, con punta corta) a b (punta larga)."""
    a, b = Vector(a), Vector(b)
    axis = b - a
    L = axis.length
    d = axis.normalized()
    e1, e2 = frame_for(d)
    rings = []
    for t, rr in ((0.0, 0.001), (base, 1.0), (1.0 - tip, 0.92), (1.0, 0.001)):
        ring = []
        for k in range(sides):
            ang = 2 * math.pi * k / sides + twist
            ring.append(a + d * (L * t) + e1 * (math.cos(ang) * r * rr) + e2 * (math.sin(ang) * r * rr * flat))
        rings.append(ring)
    return mb.loft(rings, mat, True, True)


def torus(mb, center, axis, R, r, mat, n=24, m=8, squash=1.0):
    c = Vector(center)
    ax = Vector(axis).normalized()
    e1, e2 = frame_for(ax)
    rings = []
    for i in range(n + 1):
        a = 2 * math.pi * i / n
        radial = e1 * math.cos(a) + e2 * math.sin(a)
        ring = []
        for k in range(m):
            b = 2 * math.pi * k / m
            ring.append(c + radial * (R + math.cos(b) * r) + ax * (math.sin(b) * r * squash))
        rings.append(ring)
    return mb.loft(rings, mat, False, False)


def shell(mb, center, radius, depth, mat, nu=20, nv=6, axis=(0, 1, 0), thickness=0.12, lip=0.0, noise=0.0, seed=0.0, inner_mat=None):
    """Cuenco: casquete exterior (de la boca al polo) e interior, cerrados por el borde."""
    c = Vector(center)
    ax = Vector(axis).normalized()
    e1, e2 = frame_for(ax)
    outer, inner = [], []
    for i in range(nv + 1):
        t = i / nv  # 0 = boca, 1 = polo
        ang = t * math.pi / 2
        rr = math.cos(ang) * radius * (1 + lip * (1 - t) ** 4)
        h = math.sin(ang) * depth
        ro, ri = [], []
        for k in range(nu):
            a = 2 * math.pi * k / nu
            dirv = e1 * math.cos(a) + e2 * math.sin(a)
            f = 1.0 + (noise * hnoise(dirv * 3 + ax * h, seed) if noise else 0.0)
            ro.append(c + dirv * max(rr * f, 0.002) + ax * h)
            ri.append(c + dirv * max((rr - thickness) * f, 0.001) + ax * max(h - thickness, -thickness * 0.2))
        outer.append(ro)
        inner.append(ri)
    mb.loft(outer, mat, False, True)
    ids_i = mb.loft(list(reversed(inner)), inner_mat or mat, True, False)
    # borde (de la boca exterior a la interior)
    ids_o0 = [mb.v(p) for p in outer[0]]
    ids_i0 = [mb.v(p) for p in inner[0]]
    for k in range(nu):
        a, b2 = ids_o0[k], ids_o0[(k + 1) % nu]
        cc, d = ids_i0[(k + 1) % nu], ids_i0[k]
        mb.face([a, d, cc, b2], mat)
    return ids_i


def fin(mb, outline, normal, thickness, mat, center=None):
    """Aleta plana: contorno (puntos en 3D, casi en un plano) extruido a lo largo de normal."""
    nrm = Vector(normal).normalized() * (thickness / 2)
    ring_a = [Vector(p) + nrm for p in outline]
    ring_b = [Vector(p) - nrm for p in outline]
    return mb.loft([ring_b, ring_a], mat, True, True)


def capsule(mb, a, b, r, mat, segs=10, rings=3, r1=None):
    """Cápsula (tubo con tapas redondeadas) de a a b."""
    a, b = Vector(a), Vector(b)
    r1 = r if r1 is None else r1
    d = (b - a)
    L = d.length
    d = d.normalized()
    pts, radii = [], []
    for i in range(rings, 0, -1):
        ang = math.pi / 2 * i / rings
        pts.append(a - d * (math.sin(ang) * r))
        radii.append(max(math.cos(ang) * r, 0.002))
    for i in range(0, 5):
        t = i / 4
        pts.append(a + d * (L * t))
        radii.append(r + (r1 - r) * t)
    for i in range(1, rings + 1):
        ang = math.pi / 2 * i / rings
        pts.append(b + d * (math.sin(ang) * r1))
        radii.append(max(math.cos(ang) * r1, 0.002))
    return tube(mb, pts, radii, mat, segs, True)


def limb(mb, pts, radii, mat, segs=8):
    """Brazo o pata: tubo suave por los puntos con codos redondeados (Catmull-Rom entre puntos)."""
    from geo import catmull

    dense, rad = [], []
    n = len(pts)
    steps = 3
    for i in range(n - 1):
        for k in range(steps):
            t = i + k / steps
            dense.append(Vector(catmull([tuple(p) for p in pts], t)))
            rad.append(catmull(list(radii), t))
    dense.append(Vector(pts[-1]))
    rad.append(radii[-1])
    return tube(mb, dense, rad, mat, segs, True)
