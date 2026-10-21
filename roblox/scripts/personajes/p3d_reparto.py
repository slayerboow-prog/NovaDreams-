"""Fichas de los personajes 3D del piloto (encargo «Modelos 3D propios»): Cosme (el más importante, hoja
docs/cosme/cosme-hoja.png), Mamá, Papá, Pip, Abu Rosa, Abu Tomás, Profe Lucía y Nico. Colores del
reparto (shared/LifeStory/Cast) y rasgos de shared/LifeStory/CastLook (gafas, barba, ropa).

Cada ficha: Key (la de CastLook: Familia_Mama…), Name, Hero (≤ 12.000 triángulos y textura de 1024;
si no, ≤ 8.000 y 512), Skin/Hair/Eye, Head (forma de la cara), Body (anchuras), y build(B) que pone el
pelo, la ropa y los complementos. Todo vestido: manga larga, pantalón largo, zapatos.

EXPRESSIONS: las caras (los huesos de la cara en los ejes del personaje, en Blender: x derecha, y
delante, z arriba). Las mismas van al juego (shared/Personajes3DMallas, convertidas a Roblox).
"""
import math
import random

from mathutils import Matrix, Vector

import p3d_cuerpo as C
import p3d_geo as G

rnd = random.Random(7)


# ====================================================================== expresiones
def _side(d):
    """Para el lado derecho (R); el izquierdo es su espejo."""
    out = {}
    for bone, (loc, rot) in d.items():
        out[bone] = (loc, rot)
        if bone.endswith("R"):
            lb = bone[:-1] + "L"
            if lb not in d:
                out[lb] = ((-loc[0], loc[1], loc[2]), (rot[0], -rot[1], -rot[2]))
    return out


EXPRESSIONS = {
    "Neutral": {},
    "Happy": _side({"FaceMouthR": ((0.02, 0.0, 0.045), (0, 0, 0)), "FaceJaw": ((0, 0, -0.025), (0, 0, 0)),
                    "FaceBrowR": ((0, 0, 0.03), (0, 4, 0)), "FaceLidR": ((0, 0, 0), (-6, 0, 0))}),
    "Laugh": _side({"FaceMouthR": ((0.03, 0.0, 0.05), (0, 0, 0)), "FaceJaw": ((0, -0.01, -0.12), (0, 0, 0)),
                    "FaceBrowR": ((0, 0, 0.05), (0, 6, 0)), "FaceLidR": ((0, 0, 0), (-22, 0, 0))}),
    "Talk": _side({"FaceJaw": ((0, -0.005, -0.085), (0, 0, 0)), "FaceMouthR": ((-0.008, 0, 0.0), (0, 0, 0))}),
    "Sad": _side({"FaceMouthR": ((-0.01, 0.0, -0.035), (0, 0, 0)), "FaceBrowR": ((0, 0, 0.02), (0, 18, 0)),
                  "FaceLidR": ((0, 0, 0), (-16, 0, 0)), "FaceJaw": ((0, 0, 0.0), (0, 0, 0))}),
    "Angry": _side({"FaceMouthR": ((-0.012, 0.0, -0.022), (0, 0, 0)), "FaceBrowR": ((0, 0.01, -0.035), (0, -22, 0)),
                    "FaceLidR": ((0, 0, 0), (-12, 0, 0))}),
    "Scared": _side({"FaceMouthR": ((-0.03, 0.0, -0.01), (0, 0, 0)), "FaceJaw": ((0, -0.01, -0.075), (0, 0, 0)),
                     "FaceBrowR": ((0, 0, 0.075), (0, 12, 0)), "FaceLidR": ((0, 0, 0), (14, 0, 0))}),
    # las de Cosme (CosmeLook: Grin «sonrisa loca», Skeptic, Laugh, Scared)
    "Grin": {"FaceMouthR": ((0.03, 0.0, 0.06), (0, 0, 0)), "FaceMouthL": ((-0.03, 0.0, 0.05), (0, 0, 0)),
             "FaceJaw": ((0, 0, -0.035), (0, 0, 0)), "FaceBrowR": ((0, 0, 0.06), (0, 6, 0)),
             "FaceBrowL": ((0, 0, -0.01), (0, 8, 0)), "FaceLidR": ((0, 0, 0), (8, 0, 0)), "FaceLidL": ((0, 0, 0), (-8, 0, 0))},
    "Skeptic": {"FaceMouthR": ((0.012, 0.0, 0.025), (0, 0, 0)), "FaceMouthL": ((0.01, 0.0, -0.02), (0, 0, 0)),
                "FaceBrowR": ((0, 0, 0.065), (0, -6, 0)), "FaceBrowL": ((0, 0.01, -0.03), (0, 16, 0)),
                "FaceLidR": ((0, 0, 0), (2, 0, 0)), "FaceLidL": ((0, 0, 0), (-16, 0, 0))},
}


# ====================================================================== cuerpos
BODY_M = {"chest": 0.98, "waist": 0.86, "hips": 0.82, "depth": 0.52, "shoulder": 1.0, "arm": 0.27, "leg": 0.39}
BODY_F = {"chest": 0.9, "waist": 0.78, "hips": 0.84, "depth": 0.48, "shoulder": 0.92, "arm": 0.245, "leg": 0.37, "hand": 0.92}
BODY_KID = {"chest": 0.84, "waist": 0.8, "hips": 0.78, "depth": 0.46, "shoulder": 0.88, "arm": 0.235, "leg": 0.35, "hand": 0.95}


def M(B, key, fn, *a, **kw):
    return B.mat(key, fn, *a, **kw)


def sole_mat(B, color=(0.92, 0.91, 0.88)):
    return M(B, "suela", G.mat_plain, color, 0.7)


# ====================================================================== pelos
def hairline_fn(front=0.42, side=0.08, back=-0.42, ear=0.18):
    def f(p):
        # p: esfera unidad (x derecha, y delante, z arriba)
        t = (p.y + 1) / 2  # 0 atrás, 1 delante
        lim = back + (front - back) * (t ** 1.6)
        if abs(p.x) > 0.6 and -0.35 < p.y < 0.45:
            lim = max(lim, ear)
        return p.z > lim
    return f


def hair_cosme(B):
    s = B.s
    col = G.lin(s["Hair"])
    mh = M(B, "pelo", G.mat_hair, col)
    cap = C.hair_cap(B, "PeloBase", hairline_fn(front=0.6, side=0.05, back=-0.78, ear=0.1), scale=1.12, lift=0.05, segs=28, rings=18)
    B.add(cap, mh, ("rigid", "Head"), texel=1.4, tag="pelo")
    w, d, h = B.head_r
    up = Vector((0, 0, 1))
    k = 0
    r = random.Random(11)
    # pinchos gordos alrededor de la coronilla, hacia arriba, los lados y atrás (la frente libre: las gafas)
    for phi_deg, n, ln in ((10, 3, 0.6), (36, 7, 0.72), (62, 8, 0.66), (88, 7, 0.52), (110, 5, 0.38)):
        for i in range(n):
            theta = math.radians(360 * (i + 0.5 * (phi_deg // 20 % 2)) / n + r.uniform(-8, 8))
            front = math.cos(theta)
            if phi_deg >= 36 and front > 0.5:
                continue
            if phi_deg >= 88 and front > 0.0:
                continue
            phi = math.radians(phi_deg + r.uniform(-5, 5))
            p, nrm = C.scalp_dir(B, theta, phi)
            dirv = (nrm * 0.75 + up * (0.55 if phi_deg < 70 else 0.15) + Vector((0, -0.25, 0))).normalized()
            L = ln * r.uniform(0.85, 1.15)
            flat = up.cross(dirv).cross(dirv).normalized() if abs(dirv.z) < 0.95 else Vector((0, -1, 0))
            o = C.lock(f"Pincho{k}", p - dirv * 0.14, dirv, L + 0.14, r.uniform(0.25, 0.31), 0.13, flat,
                       bend=-0.12, n=5, segs=5, tip=0.1, twist=r.uniform(-0.5, 0.5))
            B.add(o, mh, ("rigid", "Head"), texel=0.45, tag="pelo")
            k += 1
    # dos mechones sobre las sienes (enmarcan la cara, como en la hoja)
    for sx in (-1, 1):
        p, nrm = C.scalp_dir(B, math.radians(sx * 70), math.radians(70))
        dirv = (nrm + Vector((0, 0.1, 0.35))).normalized()
        o = C.lock(f"Sien{sx}", p, dirv, 0.4, 0.15, 0.06, Vector((0, 0, 1)), bend=0.1, n=5, segs=6, tip=0.1)
        B.add(o, mh, ("rigid", "Head"), texel=0.5, tag="pelo")


def hair_short(B, quiff=True):
    col = G.lin(B.s["Hair"])
    mh = M(B, "pelo", G.mat_hair, col)
    cap = C.hair_cap(B, "PeloBase", hairline_fn(front=0.4, back=-0.38, ear=0.2), scale=1.1, lift=0.05)
    B.add(cap, mh, ("rigid", "Head"), texel=1.4, tag="pelo")
    if quiff:
        r = random.Random(3)
        for i in range(6):
            sx = -0.3 + i * 0.12
            p, nrm = C.scalp_dir(B, math.radians(sx * 60), math.radians(32 + r.uniform(-4, 4)))
            dirv = (Vector((0.35, -0.6, 0.55)) + nrm * 0.3).normalized()
            o = C.lock(f"Tupe{i}", p + nrm * 0.03, dirv, 0.32, 0.17, 0.07, nrm, bend=-0.25, n=5, segs=6, tip=0.25)
            B.add(o, mh, ("rigid", "Head"), texel=0.5, tag="pelo")


def hair_bob(B):
    """Media melena hasta la mandíbula con flequillo de lado (Mamá)."""
    col = G.lin(B.s["Hair"])
    mh = M(B, "pelo", G.mat_hair, col)
    cap = C.hair_cap(B, "PeloBase", hairline_fn(front=0.36, back=-0.5, ear=-0.1), scale=1.1, lift=0.05)
    B.add(cap, mh, ("rigid", "Head"), texel=1.4, tag="pelo")
    w, d, h = B.head_r
    hc = B.head_c
    rings = []
    for z, k in ((0.45, 1.08), (0.2, 1.13), (-0.1, 1.16), (-0.4, 1.17), (-0.62, 1.15), (-0.7, 1.08)):
        rings.append({"c": Vector((0, hc.y - 0.06, hc.z + z * h)), "rx": w * k, "ry": d * k * 0.98, "sq": 2.1})
    o = G.loft("Melena", rings, segs=28, cap0=False, cap1=False, gap=((0, 1, 0), 1.25))
    sol = o.modifiers.new("Grosor", "SOLIDIFY")
    sol.thickness = 0.05
    G.apply_mods(o)
    B.add(o, mh, ("rigid", "Head"), texel=1.0, tag="pelo")
    # flequillo de lado
    for i in range(5):
        p, nrm = C.scalp_dir(B, math.radians(-36 + i * 14), math.radians(40))
        dirv = (Vector((0.55, 0.35, -0.75)) + nrm * 0.15).normalized()
        o = C.lock(f"Flequillo{i}", p + nrm * 0.05, dirv, 0.34 - i * 0.025, 0.16, 0.055, nrm, bend=0.15, n=5, segs=6, tip=0.3)
        B.add(o, mh, ("rigid", "Head"), texel=0.5, tag="pelo")
    # mechones de las puntas (hacia dentro)
    for i, th in enumerate((-110, -80, 80, 110, 150, -150, 180)):
        p, nrm = C.scalp_dir(B, math.radians(th), math.radians(115))
        p = Vector((p.x * 1.12 - hc.x * 0.12, p.y * 1.0, p.z)) + nrm * 0.05
        o = C.lock(f"Punta{i}", p, Vector((0, 0, -1)) + nrm * 0.15, 0.22, 0.17, 0.06, nrm, bend=-0.4, n=4, segs=6, tip=0.35)
        B.add(o, mh, ("rigid", "Head"), texel=0.4, tag="pelo")


def hair_long(B):
    """Melena larga hasta media espalda con raya al lado (Lucía)."""
    col = G.lin(B.s["Hair"])
    mh = M(B, "pelo", G.mat_hair, col)
    cap = C.hair_cap(B, "PeloBase", hairline_fn(front=0.38, back=-0.5, ear=-0.1), scale=1.09, lift=0.05)
    B.add(cap, mh, ("rigid", "Head"), texel=1.4, tag="pelo")
    w, d, h = B.head_r
    hc = B.head_c
    rings = []
    for z, k, dy in ((0.45, 1.07, -0.06), (0.1, 1.12, -0.07), (-0.3, 1.12, -0.1), (-0.7, 1.08, -0.16), (-1.1, 1.05, -0.24), (-1.45, 0.98, -0.3), (-1.62, 0.9, -0.31)):
        rings.append({"c": Vector((0, hc.y + dy, hc.z + z * h)), "rx": w * k, "ry": d * k * (0.95 if z > -0.5 else 0.7), "sq": 2.2})
    o = G.loft("Melena", rings, segs=28, cap0=False, cap1=False, gap=((0, 1, 0), 1.35))
    sol = o.modifiers.new("Grosor", "SOLIDIFY")
    sol.thickness = 0.06
    G.apply_mods(o)
    # (abajo, detrás del cuello y la espalda: se mueve con la cabeza y un poco con el pecho)
    B.add(o, mh, ("fn", lambda p, hc=hc: [("Head", C._sm((p.z - 3.7) / 0.6)), ("UpperTorso", 1 - C._sm((p.z - 3.7) / 0.6))]), texel=1.0, tag="pelo")
    for i in range(6):
        p, nrm = C.scalp_dir(B, math.radians(-40 + i * 13), math.radians(40))
        dirv = (Vector((0.55, 0.35, -0.75)) + nrm * 0.15).normalized()
        o = C.lock(f"Flequillo{i}", p + nrm * 0.05, dirv, 0.36 - i * 0.025, 0.16, 0.055, nrm, bend=0.15, n=5, segs=6, tip=0.3)
        B.add(o, mh, ("rigid", "Head"), texel=0.5, tag="pelo")


def hair_bun(B):
    """Pelo recogido en moño (Abu Rosa), con ondas."""
    col = G.lin(B.s["Hair"])
    mh = M(B, "pelo", G.mat_hair, col, "Z", 1.4)
    cap = C.hair_cap(B, "PeloBase", hairline_fn(front=0.42, back=-0.45, ear=0.12), scale=1.1, lift=0.06)
    B.add(cap, mh, ("rigid", "Head"), texel=1.4, tag="pelo")
    w, d, h = B.head_r
    hc = B.head_c
    bun = G.blob("Mono", (0, 0, 0), (0.27, 0.24, 0.24), segs=18, rings=12, deform=lambda p: Vector((p.x, p.y, p.z * (1 + 0.08 * math.sin(p.x * 9)))))
    bun.location = Vector((0, hc.y - d * 0.78, hc.z + h * 0.55))
    B.add(bun, mh, ("rigid", "Head"), texel=0.7, tag="pelo")
    # ondas sobre las sienes
    for sx in (-1, 1):
        for j in range(3):
            p, nrm = C.scalp_dir(B, math.radians(sx * (40 + j * 22)), math.radians(48 + j * 6))
            dirv = (Vector((0, -1, 0.15)) + nrm * 0.2).normalized()
            o = C.lock(f"Onda{sx}{j}", p + nrm * 0.05, dirv, 0.34, 0.14, 0.06, nrm, bend=-0.2, n=5, segs=6, tip=0.4)
            B.add(o, mh, ("rigid", "Head"), texel=0.4, tag="pelo")


def hair_kid(B):
    """Pelo corto despeinado de niño (Nico)."""
    col = G.lin(B.s["Hair"])
    mh = M(B, "pelo", G.mat_hair, col)
    cap = C.hair_cap(B, "PeloBase", hairline_fn(front=0.32, back=-0.42, ear=0.15), scale=1.1, lift=0.06)
    B.add(cap, mh, ("rigid", "Head"), texel=1.4, tag="pelo")
    r = random.Random(5)
    k = 0
    for phi_deg, n in ((12, 4), (30, 8), (48, 10), (66, 9)):
        for i in range(n):
            theta = math.radians(360 * i / n + r.uniform(-12, 12))
            front = math.cos(theta)
            phi = math.radians(phi_deg + r.uniform(-4, 4))
            p, nrm = C.scalp_dir(B, theta, phi)
            if phi_deg >= 48 and front > 0.3:
                continue
            fwd = Vector((0, 0.5, 0.2)) if front > 0.2 else Vector((0, -0.35, 0.25))
            dirv = (nrm * 0.6 + fwd + Vector((r.uniform(-0.2, 0.2), 0, 0))).normalized()
            o = C.lock(f"Mechon{k}", p + nrm * 0.04, dirv, r.uniform(0.22, 0.32), r.uniform(0.14, 0.18), 0.07, nrm, bend=-0.25, n=4, segs=6, tip=0.15)
            B.add(o, mh, ("rigid", "Head"), texel=0.4, tag="pelo")
            k += 1


def hair_sides(B):
    """Solo los lados y la nuca (Abu Tomás lleva gorra)."""
    col = G.lin(B.s["Hair"])
    mh = M(B, "pelo", G.mat_hair, col)
    cap = C.hair_cap(B, "PeloBase", lambda p: p.z > -0.35 and p.z < 0.42 and p.y < 0.35 and not (abs(p.x) < 0.5 and p.y > 0.2), scale=1.06)
    B.add(cap, mh, ("rigid", "Head"), texel=1.0, tag="pelo")


# ====================================================================== complementos
def goggles(B):
    """Las gafas de laboratorio de Cosme, en la frente: cinta, dos aros de latón y cristal verde azulado."""
    w, d, h = B.head_r
    hc = B.head_c
    zc = hc.z + h * 0.7
    strap_m = M(B, "cinta", G.mat_leather, (0.03, 0.03, 0.035))
    brass = M(B, "laton", G.mat_metal, (0.75, 0.52, 0.2), 0.3)
    glass = M(B, "cristal_gafas", G.mat_glow, (0.25, 0.95, 0.85), 2.0)
    pts = []
    n = 16
    # la cinta va por detrás, de un aro al otro (delante no pasa por encima de los cristales)
    for i in range(n):
        a = math.radians(-62 - (360 - 124) * i / (n - 1))
        x, y = math.sin(a), math.cos(a)
        z = zc + 0.06 * max(0.0, -y)
        pts.append(Vector((x * w * 1.08, hc.y + y * d * 1.09, z)))
    strap = G.loft("Cinta", G.path_rings(pts, [(0.035, 0.07)] * n, sq=2.6, ref=None), segs=5)
    B.add(strap, strap_m, ("rigid", "Head"), texel=0.6, tag="gafas")
    tilt = Matrix.Rotation(math.radians(-35), 3, "X")
    for sx in (-1, 1):
        c = Vector((sx * 0.24, hc.y + d * 0.9, zc + 0.03))
        axis = tilt @ Vector((0, 1, 0))
        rim = G.loft(f"Aro{sx}", [{"c": c - axis * 0.06, "rx": 0.15, "ry": 0.15}, {"c": c + axis * 0.09, "rx": 0.16, "ry": 0.16}, {"c": c + axis * 0.11, "rx": 0.13, "ry": 0.13}], segs=14, cap0=True, cap1=False)
        B.add(rim, brass, ("rigid", "Head"), texel=0.8, tag="gafas")
        lens = G.blob(f"Lente{sx}", (0, 0, 0), (0.125, 0.04, 0.125), segs=12, rings=6)
        lens.location = c + axis * 0.085
        lens.rotation_euler = tilt.to_euler()
        B.add(lens, glass, ("rigid", "Head"), texel=0.6, tag="gafas")
    bridge = G.cyl("Puente", (-0.1, hc.y + d * 0.95, zc + 0.05), (0.1, hc.y + d * 0.95, zc + 0.05), 0.03, segs=8)
    B.add(bridge, brass, ("rigid", "Head"), texel=0.2, tag="gafas")


def round_glasses(B, color=(0.55, 0.42, 0.25)):
    w, d, h = B.head_r
    hc = B.head_c
    H = B.s["Head"]
    rim = M(B, "montura", G.mat_metal, color, 0.3)
    ez = hc.z + H.get("eye_z", 0.1) * h
    ex = H.get("eye_x", 0.4) * w
    for sx in (-1, 1):
        c = Vector((sx * ex, hc.y + d * 1.0, ez))
        o = G.torus(f"Lente{sx}", c, (0, 1, 0), 0.17, 0.014, segs=22, tsegs=6)
        B.add(o, rim, ("rigid", "Head"), texel=0.3, tag="gafas")
        temple = G.cyl(f"Patilla{sx}", (sx * (ex + 0.17), hc.y + d * 0.98, ez), (sx * w * 1.02, hc.y - d * 0.1, ez + 0.02), 0.013, segs=6)
        B.add(temple, rim, ("rigid", "Head"), texel=0.2, tag="gafas")
    br = G.loft("Puente", G.path_rings([(-ex + 0.17, hc.y + d * 1.0, ez), (0, hc.y + d * 1.04, ez + 0.03), (ex - 0.17, hc.y + d * 1.0, ez)], [0.013] * 3), segs=6)
    B.add(br, rim, ("rigid", "Head"), texel=0.2, tag="gafas")


def mustache(B):
    w, d, h = B.head_r
    hc = B.head_c
    H = B.s["Head"]
    m = M(B, "bigote", G.mat_hair, G.shade(G.lin(B.s["Hair"]), 0.95), "X")
    z = hc.z + (H.get("mouth_z", -0.4) * h + H.get("nose_z", -0.12) * h) / 2 - 0.02
    surf = G.Surface(B.head_obj)
    for sx in (-1, 1):
        pts = []
        for t in (0.0, 0.33, 0.66, 1.0):
            x = sx * (0.02 + t * 0.2)
            loc, nor = surf.front(x, z - t * t * 0.07)
            pts.append(loc + nor * 0.045)
        o = G.loft(f"Bigote{sx}", G.path_rings(pts, [(0.055, 0.045), (0.06, 0.05), (0.05, 0.04), (0.02, 0.02)], sq=2.2), segs=8)
        B.add(o, m, ("rigid", "Head"), texel=0.5, tag="bigote")


def flat_cap(B, color):
    """Gorra plana de paño (Abu Tomás)."""
    w, d, h = B.head_r
    hc = B.head_c
    m = M(B, "gorra", G.mat_cloth, color, "twill", 1.0)
    rings = [{"c": Vector((0, hc.y - 0.04, hc.z + h * 0.5)), "rx": w * 1.06, "ry": d * 1.08, "sq": 2.2},
             {"c": Vector((0, hc.y + 0.0, hc.z + h * 0.72)), "rx": w * 1.04, "ry": d * 1.1, "sq": 2.2},
             {"c": Vector((0, hc.y + 0.04, hc.z + h * 0.9)), "rx": w * 0.9, "ry": d * 1.0, "sq": 2.2},
             {"c": Vector((0, hc.y + 0.04, hc.z + h * 1.0)), "rx": w * 0.58, "ry": d * 0.68, "sq": 2.2}]
    o = G.loft("Gorra", rings, segs=26, cap0=False, cap1=True)
    B.add(o, m, ("rigid", "Head"), texel=0.8, tag="gorra")
    visor = G.loft("Visera", [{"c": Vector((0, hc.y + d * 0.9, hc.z + h * 0.56)), "rx": w * 0.82, "ry": 0.02, "sq": 2.0, "u": Vector((1, 0, 0))},
                              {"c": Vector((0, hc.y + d * 1.15, hc.z + h * 0.52)), "rx": w * 0.7, "ry": 0.018, "sq": 2.0, "u": Vector((1, 0, 0))},
                              {"c": Vector((0, hc.y + d * 1.28, hc.z + h * 0.49)), "rx": w * 0.45, "ry": 0.015, "sq": 2.0, "u": Vector((1, 0, 0))}], segs=10)
    B.add(visor, m, ("rigid", "Head"), texel=0.4, tag="gorra")


def school_backpack(B, color):
    T = B.s["Body"]
    de = T.get("depth", 0.5)
    m = M(B, "mochila", G.mat_cloth, color, "canvas", 1.0)
    dark = M(B, "mochila_osc", G.mat_cloth, G.shade(color, 0.55), "canvas")
    bag = G.loft("Mochila", [{"c": Vector((0, -de - 0.2, z)), "rx": rx, "ry": ry, "sq": 3.2} for z, rx, ry in ((2.55, 0.6, 0.16), (2.65, 0.66, 0.22), (3.3, 0.66, 0.23), (3.62, 0.56, 0.18), (3.68, 0.4, 0.1))], segs=18)
    B.add(bag, m, ("rigid", "UpperTorso"), texel=0.8, tag="mochila")
    pocket = G.rbox("BolsilloMochila", (0, -de - 0.44, 2.85), (0.8, 0.12, 0.4), bevel=0.05, segs=2)
    B.add(pocket, dark, ("rigid", "UpperTorso"), texel=0.4, tag="mochila")
    for sx in (-1, 1):
        pts = [(sx * 0.45, -de + 0.02, 3.75), (sx * 0.5, de * 0.2, 3.92), (sx * 0.55, de + 0.06, 3.6), (sx * 0.6, de + 0.05, 3.0), (sx * 0.62, de - 0.02, 2.75)]
        o = G.loft(f"Asa{sx}", G.path_rings(pts, [(0.09, 0.025)] * 5, sq=2.6), segs=6)
        B.add(o, dark, AUTO_STRAP, texel=0.3, tag="mochila")


AUTO_STRAP = ("auto", ["UpperTorso"], 0.06)


# ====================================================================== ropa compuesta
def coat_rule(p):
    if p.z > 2.3:
        return G.weights_for(p, ["LowerTorso", "UpperTorso", "RightUpperArm", "LeftUpperArm"], G.CAPS, 0.06)
    t = max(0.0, min(1.0, (2.15 - p.z) / 1.1))
    side = max(0.0, min(1.0, (p.x + 0.35) / 0.7))
    side = side * side * (3 - 2 * side)
    k = 0.62 * t
    low = max(0.0, min(1.0, (1.35 - p.z) / 0.5)) * 0.25
    up = max(0.0, min(1.0, (p.z - 2.15) / 0.15))
    ws = [("LowerTorso", (1 - k) * (1 - up) + up * 0.8), ("UpperTorso", up * 0.2), ("RightUpperLeg", k * side * (1 - low)), ("LeftUpperLeg", k * (1 - side) * (1 - low)),
          ("RightLowerLeg", k * side * low), ("LeftLowerLeg", k * (1 - side) * low)]
    return ws


def long_coat(B, mat, length_z=1.1, grow=0.07, open_top=0.95, open_mid=0.32, open_low=0.42, name="Bata", lapel_mat=None):
    """Bata o abrigo largo abierto delante: el tronco algo mayor que la camisa y un faldón hasta length_z."""
    T = B.s["Body"]
    hi, de = T.get("hips", 0.8), T.get("depth", 0.5)
    rings = []
    for z, rx, ry in ((length_z, hi + 0.22, de + 0.2), (length_z + 0.35, hi + 0.17, de + 0.15), (1.85, hi + 0.12, de + 0.12), (2.15, hi + 0.08, de + 0.09)):
        rings.append({"c": Vector((0, -0.01, z)), "rx": rx, "ry": ry, "sq": 2.4})
    for r in C.torso_rings(T, 2.4, grow=grow)[1:]:
        if r["c"].z >= 2.4:
            rings.append(r)
    zs = [r["c"].z for r in rings]

    def half(i):
        z = (zs[i] + zs[min(i + 1, len(zs) - 1)]) / 2
        if z < 2.2:
            return open_low - (open_low - open_mid) * max(0.0, (z - length_z) / (2.2 - length_z))
        if z < 3.0:
            return open_mid
        return open_mid + (open_top - open_mid) * min(1.0, (z - 3.0) / 0.95)

    o = G.loft(name, rings, segs=26, cap0=False, cap1=False, gap=((0, 1, 0), 0.4, half))
    sol = o.modifiers.new("Grosor", "SOLIDIFY")
    sol.thickness = 0.03
    sol.offset = 1.0
    G.apply_mods(o)
    B.add(o, mat, ("fn", coat_rule), texel=1.2, tag="bata")
    lm = lapel_mat or mat
    # solapas: tiras dobladas hacia fuera a lo largo del borde de la abertura (pecho)
    lm = lapel_mat or mat
    for sx in (-1, 1):
        lrings = []
        for z in (2.95, 3.25, 3.55, 3.8, 3.92):
            i = max(j for j, zz in enumerate(zs) if zz <= z) if z >= zs[0] else 0
            a = half(i) + 0.02
            rr = _ring_at(rings, z)
            ex = Vector((sx * rr[0] * math.sin(a), rr[2] + rr[1] * math.cos(a), z))
            tang = Vector((sx * rr[0] * math.cos(a), -rr[1] * math.sin(a), 0)).normalized()
            nrm = Vector((sx * math.sin(a) / max(rr[0], 1e-3), math.cos(a) / max(rr[1], 1e-3), 0)).normalized()
            wdt = 0.02 + 0.11 * C._sm((z - 2.95) / 0.5) * (1 - 0.5 * C._sm((z - 3.7) / 0.25))
            lrings.append({"c": ex + tang * wdt + nrm * 0.035, "rx": wdt, "ry": 0.014, "sq": 2.2, "u": tang})
        o = G.loft(f"Solapa{sx}", lrings, segs=6)
        B.add(o, lm, AUTO_TORSO_SOFT, texel=0.4, tag="bata")
    # cuello de la bata detrás
    col = G.loft(f"{name}Cuello", [{"c": Vector((0, -0.03, 3.95)), "rx": 0.5, "ry": 0.43, "sq": 2.2}, {"c": Vector((0, -0.05, 4.13)), "rx": 0.44, "ry": 0.38, "sq": 2.2}],
                 segs=20, cap0=False, cap1=False, gap=((0, 1, 0), 1.25))
    s2 = col.modifiers.new("Grosor", "SOLIDIFY")
    s2.thickness = 0.03
    G.apply_mods(col)
    B.add(col, mat, ("auto", ["UpperTorso", "Head"], 0.1), texel=0.4, tag="bata")


AUTO_TORSO_SOFT = ("auto", ["UpperTorso", "LowerTorso"], 0.08)


def _ring_at(rings, z):
    """(rx, ry, cy) del tronco a la altura z (interpolado entre anillos)."""
    for a, b in zip(rings, rings[1:]):
        if a["c"].z <= z <= b["c"].z:
            t = (z - a["c"].z) / max(b["c"].z - a["c"].z, 1e-6)
            return (a["rx"] + (b["rx"] - a["rx"]) * t, a["ry"] + (b["ry"] - a["ry"]) * t, a["c"].y + (b["c"].y - a["c"].y) * t)
    r = rings[-1]
    return (r["rx"], r["ry"], r["c"].y)


def cardigan(B, mat, under_mat, button_mat, length_z=2.05, grow=0.06, v_open=0.55):
    """Rebeca de punto con escote de pico y botones, sobre una blusa o camisa (que asoma en el pico)."""
    T = B.s["Body"]
    C.build_torso(B, under_mat, z0=2.25, name="Blusa")
    rings = []
    for r in C.torso_rings(T, length_z, grow=grow):
        rings.append(r)
    rings[0]["c"].z = length_z
    zs = [r["c"].z for r in rings]

    def half(i):
        z = (zs[i] + zs[min(i + 1, len(zs) - 1)]) / 2
        if z < 3.05:
            return 0.0
        return v_open * min(1.0, (z - 3.05) / 0.85)

    o = G.loft("Rebeca", rings, segs=30, cap0=False, cap1=False, gap=((0, 1, 0), 0.4, half))
    sol = o.modifiers.new("Grosor", "SOLIDIFY")
    sol.thickness = 0.03
    sol.offset = 1.0
    G.apply_mods(o)
    B.add(o, mat, ("fn", lambda p: G.weights_for(p, ["LowerTorso", "UpperTorso", "RightUpperArm", "LeftUpperArm"], G.CAPS, 0.06) if p.z > 2.25 else [("LowerTorso", 1.0)]), texel=1.2, tag="rebeca")
    # borde del pico y botones
    pts = [C.torso_front(T, z, grow + 0.025) for z in (2.3, 2.6, 2.9)]
    C.build_buttons(B, button_mat, pts, 0.038)
    # dobladillo de abajo (canalé)
    hem = G.loft("Canale", [{"c": Vector((0, 0, length_z - 0.02)), "rx": rings[0]["rx"] + 0.035, "ry": rings[0]["ry"] + 0.035, "sq": 2.5},
                            {"c": Vector((0, 0, length_z + 0.13)), "rx": rings[0]["rx"] + 0.03, "ry": rings[0]["ry"] + 0.03, "sq": 2.5}], segs=30, cap0=False, cap1=False)
    s2 = hem.modifiers.new("Grosor", "SOLIDIFY")
    s2.thickness = 0.03
    G.apply_mods(hem)
    B.add(hem, mat, ("rigid", "LowerTorso"), texel=0.4, tag="rebeca")


# ====================================================================== personajes
def build_cosme(B):
    s = B.s
    C.build_head(B)
    hair_cosme(B)
    goggles(B)
    coat = M(B, "bata", G.mat_cloth, (0.86, 0.86, 0.84), "canvas", 1.0, dirt=0.35)
    tee = M(B, "camiseta", G.mat_cloth, (0.025, 0.025, 0.03), "plain")
    C.build_torso(B, tee, z0=2.25, name="Camiseta")
    # colgante que brilla
    T = s["Body"]
    cord = M(B, "cordon", G.mat_plain, (0.05, 0.05, 0.06), 0.6)
    pend = M(B, "colgante", G.mat_glow, (0.25, 0.95, 0.85), 2.5)
    front = C.torso_front(T, 3.25, 0.012)
    pts = [Vector((-0.28, 0.12, 3.97)), Vector((-0.2, front.y - 0.02, 3.55)), front + Vector((0, 0.0, 0.12)), Vector((0.2, front.y - 0.02, 3.55)), Vector((0.28, 0.12, 3.97))]
    o = G.loft("Cordon", G.path_rings(pts, [0.014] * 5), segs=6)
    B.add(o, cord, AUTO_TORSO_SOFT, texel=0.2, tag="colgante")
    p = G.rbox("Colgante", front + Vector((0, 0.03, 0)), (0.11, 0.035, 0.15), bevel=0.02, segs=2)
    B.add(p, pend, ("rigid", "UpperTorso"), texel=0.3, tag="colgante")
    # pantalón cargo, cinturón, botas
    pants = M(B, "pantalon", G.mat_cloth, G.lin(s["Pants"]), "canvas", 1.2)
    C.build_trousers(B, pants, flare=0.02, hem=0.42)
    belt = M(B, "cinturon", G.mat_leather, (0.16, 0.09, 0.05))
    buckle = M(B, "hebilla", G.mat_metal, (0.8, 0.8, 0.78), 0.25)
    C.build_belt(B, belt, buckle)
    for sx in (-1, 1):
        leg = "RightUpperLeg" if sx > 0 else "LeftUpperLeg"
        C.build_pocket(B, pants, (sx * 0.86, 0.02, 1.5), (0.1, 0.34, 0.36), rule=("rigid", leg), name=f"BolsilloCargo{sx}")
    boot = M(B, "bota", G.mat_leather, (0.03, 0.03, 0.035), 0.4)
    C.build_shoes(B, boot, sole_mat(B), "boot")
    # bata blanca con manga larga, bolsillos y bolígrafos
    long_coat(B, coat, length_z=1.12)
    C.build_sleeves(B, coat, grow=0.03, cuff=(coat, 0.1))
    skin = M(B, "piel", G.mat_skin, G.lin(s["Skin"]))
    C.build_hands(B, skin)
    for sx in (-1, 1):
        C.build_pocket(B, coat, (sx * 0.72, 0.62, 1.6), (0.36, 0.06, 0.34), rule=("fn", coat_rule), name=f"BolsilloBata{sx}", flap=False)
    bp = C.torso_front(T, 3.3, 0.1) + Vector((-0.5, -0.05, 0))
    C.build_pocket(B, coat, bp, (0.3, 0.05, 0.28), rule=("rigid", "UpperTorso"), name="BolsilloPecho", flap=False)
    for i, (col, dx) in enumerate((((0.7, 0.05, 0.05), -0.08), ((0.05, 0.15, 0.6), 0.0), ((0.03, 0.03, 0.03), 0.08))):
        pen = G.cyl(f"Boli{i}", bp + Vector((dx, 0.0, 0.05)), bp + Vector((dx, 0.0, 0.3)), 0.022, segs=8)
        B.add(pen, M(B, f"boli{i}", G.mat_plain, col, 0.35), ("rigid", "UpperTorso"), texel=0.1, tag="bolis")
    # mochila de inventor
    de = T.get("depth", 0.5)
    metal = M(B, "mochila", G.mat_metal, (0.42, 0.44, 0.47), 0.4)
    screen = M(B, "pantalla", G.mat_glow, (0.25, 0.95, 0.9), 2.5, True)
    bag = G.rbox("Mochila", (0, -de - 0.3, 3.15), (1.0, 0.4, 1.05), bevel=0.08, segs=2)
    B.add(bag, metal, ("rigid", "UpperTorso"), texel=0.8, tag="mochila")
    scr = G.rbox("PantallaMochila", (0, -de - 0.51, 3.2), (0.5, 0.04, 0.52), bevel=0.02, segs=1)
    B.add(scr, screen, ("rigid", "UpperTorso"), texel=0.3, tag="mochila")
    for sx in (-1, 1):
        tube = G.cyl(f"Tubo{sx}", (sx * 0.38, -de - 0.54, 2.78), (sx * 0.38, -de - 0.54, 3.6), 0.05, segs=10)
        B.add(tube, screen, ("rigid", "UpperTorso"), texel=0.2, tag="mochila")
        strap = G.loft(f"Correa{sx}", G.path_rings([(sx * 0.45, -de - 0.1, 3.62), (sx * 0.5, -0.05, 3.95), (sx * 0.52, de * 0.75, 3.75)], [(0.08, 0.025)] * 3, sq=2.6), segs=6)
        B.add(strap, M(B, "correa", G.mat_leather, (0.05, 0.05, 0.06)), AUTO_STRAP, texel=0.2, tag="mochila")
    ant = G.cyl("Antena", (0.32, -de - 0.3, 3.65), (0.32, -de - 0.3, 3.95), 0.018, segs=6)
    B.add(ant, metal, ("rigid", "UpperTorso"), texel=0.1, tag="mochila")
    ball = G.blob("Bolita", (0.32, -de - 0.3, 3.98), (0.045, 0.045, 0.045), segs=10, rings=6)
    B.add(ball, M(B, "rojo", G.mat_glow, (1.0, 0.15, 0.1), 2.0), ("rigid", "UpperTorso"), texel=0.1, tag="mochila")
    # aparato de muñeca (antebrazo izquierdo) con pantalla
    dev = G.rbox("Aparato", (-1.5, 0.0, 2.62), (0.56, 0.56, 0.32), bevel=0.06, segs=2)
    B.add(dev, M(B, "aparato", G.mat_metal, (0.12, 0.13, 0.15), 0.35), ("rigid", "LeftLowerArm"), texel=0.5, tag="aparato")
    sc2 = G.rbox("PantallaAparato", (-1.79, 0.02, 2.62), (0.03, 0.36, 0.2), bevel=0.01, segs=1)
    B.add(sc2, screen, ("rigid", "LeftLowerArm"), texel=0.2, tag="aparato")
    # pistola de rayos en la mano derecha (latón, tubo morado)
    hand = Vector((1.48, 0.06, 2.06))
    copper = M(B, "cobre", G.mat_metal, (0.62, 0.3, 0.16), 0.3)
    purple = M(B, "tubo_morado", G.mat_glow, (0.75, 0.3, 1.0), 2.5)
    grip = G.rbox("Empunadura", hand + Vector((0, -0.02, 0.0)), (0.1, 0.14, 0.26), bevel=0.03, segs=2)
    B.add(grip, copper, ("rigid", "RightHand"), texel=0.2, tag="pistola")
    body = G.loft("Canon", G.path_rings([hand + Vector((0, -0.12, -0.13)), hand + Vector((0, 0.15, -0.13)), hand + Vector((0, 0.36, -0.13)), hand + Vector((0, 0.42, -0.13))],
                                       [0.075, 0.085, 0.065, 0.085]), segs=10)
    B.add(body, brass_mat(B), ("rigid", "RightHand"), texel=0.4, tag="pistola")
    tube = G.cyl("TuboRayos", hand + Vector((0, -0.06, -0.02)), hand + Vector((0, 0.28, -0.02)), 0.045, segs=10)
    B.add(tube, purple, ("rigid", "RightHand"), texel=0.2, tag="pistola")
    for i, y in enumerate((0.05, 0.22)):
        ring = G.torus(f"Anillo{i}", hand + Vector((0, y, -0.13)), (0, 1, 0), 0.09, 0.02, segs=12, tsegs=5)
        B.add(ring, copper, ("rigid", "RightHand"), texel=0.1, tag="pistola")


def brass_mat(B):
    return M(B, "laton", G.mat_metal, (0.75, 0.52, 0.2), 0.3)


def build_mama(B):
    s = B.s
    C.build_head(B)
    hair_bob(B)
    shirt = M(B, "camisa", G.mat_cloth, G.lin(s["Shirt"]), "plain", 1.0)
    C.build_torso(B, shirt, z0=2.25)
    C.build_sleeves(B, shirt, cuff=(shirt, 0.09))
    C.build_collar(B, shirt, 0.55, 0.12)
    T = s["Body"]
    btn = M(B, "boton", G.mat_plain, (0.92, 0.92, 0.9), 0.3)
    C.build_buttons(B, btn, [C.torso_front(T, z, 0.012) for z in (3.15, 3.45)], 0.03)
    jeans = M(B, "vaquero", G.mat_cloth, G.lin(s["Pants"]), "twill", 1.0)
    C.build_trousers(B, jeans, flare=0.0, hem=0.22)
    C.build_belt(B, M(B, "cinturon", G.mat_leather, (0.35, 0.22, 0.12)), M(B, "hebilla", G.mat_metal, (0.85, 0.75, 0.45)))
    C.build_shoes(B, M(B, "zapato", G.mat_leather, (0.35, 0.14, 0.1)), sole_mat(B, (0.25, 0.2, 0.18)), "shoe")
    C.build_hands(B, M(B, "piel", G.mat_skin, G.lin(s["Skin"])))


def build_papa(B):
    s = B.s
    C.build_head(B)
    hair_short(B)
    base = G.lin(s["Shirt"])
    shirt = M(B, "camisa", G.mat_cloth, base, "plain", 1.0, stripes=(G.shade(base, 0.6), "X", 5.0, 0.14, "Z"))
    C.build_torso(B, shirt, z0=2.25)
    C.build_sleeves(B, shirt, cuff=(shirt, 0.09))
    C.build_collar(B, shirt, 0.5, 0.13)
    T = s["Body"]
    btn = M(B, "boton", G.mat_plain, (0.9, 0.9, 0.88), 0.3)
    C.build_buttons(B, btn, [C.torso_front(T, z, 0.012) for z in (2.75, 3.05, 3.35, 3.62)], 0.03)
    C.build_pocket(B, shirt, C.torso_front(T, 3.35, 0.01) + Vector((-0.42, -0.02, 0)), (0.28, 0.04, 0.26), rule=("rigid", "UpperTorso"), name="BolsilloCamisa")
    jeans = M(B, "vaquero", G.mat_cloth, G.lin(s["Pants"]), "twill", 1.0)
    C.build_trousers(B, jeans, flare=0.0, hem=0.22)
    C.build_belt(B, M(B, "cinturon", G.mat_leather, (0.12, 0.07, 0.04)), M(B, "hebilla", G.mat_metal, (0.8, 0.8, 0.8)))
    C.build_shoes(B, M(B, "zapatilla", G.mat_cloth, (0.85, 0.85, 0.83), "canvas"), sole_mat(B), "sneaker")
    C.build_hands(B, M(B, "piel", G.mat_skin, G.lin(s["Skin"])))


def build_abu_rosa(B):
    s = B.s
    C.build_head(B)
    hair_bun(B)
    round_glasses(B)
    knit = M(B, "rebeca", G.mat_cloth, G.lin(s["Shirt"]), "knit", 1.0)
    blouse = M(B, "blusa", G.mat_cloth, (0.85, 0.8, 0.72), "plain")
    btn = M(B, "boton", G.mat_plain, (0.95, 0.9, 0.8), 0.25)
    cardigan(B, knit, blouse, btn, length_z=1.95)
    C.build_collar(B, blouse, 0.7, 0.1, grow=0.0, name="CuelloBlusa", points=False)
    C.build_sleeves(B, knit, grow=0.03, cuff=(knit, 0.12))
    pants = M(B, "pantalon", G.mat_cloth, G.lin(s["Pants"]), "plain", 1.0)
    C.build_trousers(B, pants, flare=0.02, hem=0.2, wide=0.02)
    C.build_shoes(B, M(B, "zapato", G.mat_leather, (0.2, 0.12, 0.08)), sole_mat(B, (0.15, 0.1, 0.07)), "shoe")
    C.build_hands(B, M(B, "piel", G.mat_skin, G.lin(s["Skin"])))


def build_abu_tomas(B):
    s = B.s
    C.build_head(B)
    hair_sides(B)
    flat_cap(B, (0.22, 0.2, 0.18))
    mustache(B)
    knit = M(B, "rebeca", G.mat_cloth, G.shade(G.lin(s["Shirt"]), 0.8), "knit", 1.0)
    shirt = M(B, "camisa", G.mat_cloth, (0.82, 0.84, 0.86), "plain", stripes=((0.55, 0.62, 0.75), "X", 9.0, 0.08))
    btn = M(B, "boton", G.mat_plain, (0.3, 0.2, 0.14), 0.3)
    cardigan(B, knit, shirt, btn, length_z=2.0, v_open=0.5)
    C.build_collar(B, shirt, 0.55, 0.12, grow=0.0, name="CuelloCamisa")
    C.build_sleeves(B, knit, grow=0.03, cuff=(knit, 0.12))
    pants = M(B, "pantalon", G.mat_cloth, G.lin(s["Pants"]), "plain", 1.0)
    C.build_trousers(B, pants, flare=0.02, hem=0.2, wide=0.02)
    C.build_belt(B, M(B, "cinturon", G.mat_leather, (0.1, 0.06, 0.04)), M(B, "hebilla", G.mat_metal, (0.7, 0.68, 0.6)), z=2.5)
    C.build_shoes(B, M(B, "zapato", G.mat_leather, (0.08, 0.05, 0.04)), sole_mat(B, (0.1, 0.08, 0.06)), "shoe")
    C.build_hands(B, M(B, "piel", G.mat_skin, G.lin(s["Skin"])))


def build_lucia(B):
    s = B.s
    C.build_head(B)
    hair_long(B)
    knit = M(B, "rebeca", G.mat_cloth, G.lin(s["Shirt"]), "knit", 1.0)
    blouse = M(B, "blusa", G.mat_cloth, (0.93, 0.92, 0.9), "plain")
    btn = M(B, "boton", G.mat_plain, (0.95, 0.95, 0.92), 0.25)
    cardigan(B, knit, blouse, btn, length_z=2.0, v_open=0.6)
    C.build_collar(B, blouse, 0.75, 0.1, grow=0.0, name="CuelloBlusa", points=False)
    C.build_sleeves(B, knit, grow=0.03, cuff=(knit, 0.12))
    pants = M(B, "pantalon", G.mat_cloth, G.lin(s["Pants"]), "plain", 1.0)
    C.build_trousers(B, pants, flare=0.0, hem=0.22)
    C.build_shoes(B, M(B, "zapato", G.mat_leather, (0.12, 0.08, 0.06)), sole_mat(B, (0.1, 0.07, 0.05)), "shoe")
    C.build_hands(B, M(B, "piel", G.mat_skin, G.lin(s["Skin"])))


def build_nico(B):
    s = B.s
    C.build_head(B)
    hair_kid(B)
    base = G.lin(s["Shirt"])
    top = M(B, "camiseta", G.mat_cloth, base, "plain", 1.0)
    stripe = M(B, "franja", G.mat_cloth, (0.92, 0.92, 0.9), "plain")
    C.build_torso(B, top, z0=2.25)
    C.build_sleeves(B, top, cuff=(stripe, 0.1))
    T = s["Body"]
    # cuello redondo blanco
    ring = G.loft("CuelloRedondo", [{"c": Vector((0, -0.01, 3.92)), "rx": 0.42, "ry": 0.36, "sq": 2.2}, {"c": Vector((0, -0.02, 4.0)), "rx": 0.38, "ry": 0.33, "sq": 2.2}], segs=20, cap0=False, cap1=False)
    sol = ring.modifiers.new("Grosor", "SOLIDIFY")
    sol.thickness = 0.03
    G.apply_mods(ring)
    B.add(ring, stripe, ("auto", ["UpperTorso", "Head"], 0.08), texel=0.3, tag="cuello")
    track = M(B, "chandal", G.mat_cloth, G.lin(s["Pants"]), "plain", 1.0)
    C.build_trousers(B, track, flare=0.0, hem=0.22)
    for sx in (-1, 1):  # franja blanca del chándal
        x = sx * (0.5 + T.get("leg", 0.35) * 0.98)
        o = G.loft(f"FranjaPierna{sx}", G.path_rings([(x, 0, 2.3), (x, 0, 1.2), (sx * (0.5 + T.get("leg", 0.35) * 0.9), 0, 0.3)], [(0.012, 0.045)] * 3, sq=2.5), segs=6)
        B.add(o, stripe, ("auto", ["LowerTorso", "RightUpperLeg" if sx > 0 else "LeftUpperLeg", "RightLowerLeg" if sx > 0 else "LeftLowerLeg"], 0.06), texel=0.2, tag="franja")
    C.build_shoes(B, M(B, "zapatilla", G.mat_cloth, (0.92, 0.92, 0.9), "canvas"), M(B, "suela_roja", G.mat_plain, (0.75, 0.12, 0.1), 0.6), "sneaker")
    C.build_hands(B, M(B, "piel", G.mat_skin, G.lin(s["Skin"])))
    school_backpack(B, G.lin(s["Backpack"]))


def build_pip(B):
    """Pip, el robot mayordomo de Cosme: cabeza de robot con pantalla (ojos y boca de luz), frac,
    pajarita y guantes blancos."""
    s = B.s
    robot_head(B)
    jacket = M(B, "frac", G.mat_cloth, G.lin(s["Shirt"]), "satin", 1.0)
    shirt = M(B, "pechera", G.mat_cloth, (0.92, 0.92, 0.9), "plain")
    C.build_torso(B, shirt, z0=2.25, name="Pechera")
    long_coat(B, jacket, length_z=1.3, open_top=0.7, open_mid=0.38, open_low=1.6, name="Frac", lapel_mat=M(B, "solapa", G.mat_cloth, G.shade(G.lin(s["Shirt"]), 0.6), "satin"))
    C.build_sleeves(B, jacket, grow=0.03, cuff=(shirt, 0.08))
    T = s["Body"]
    btn = M(B, "boton", G.mat_metal, (0.75, 0.6, 0.3), 0.3)
    C.build_buttons(B, btn, [C.torso_front(T, z, 0.075) + Vector((sx * 0.3, 0, 0)) for z in (2.7, 3.0) for sx in (-1, 1)], 0.04)
    # pajarita
    bow = M(B, "pajarita", G.mat_cloth, (0.08, 0.08, 0.12), "satin")
    ctr = Vector((0, 0.33, 3.92))
    for sx in (-1, 1):
        o = G.loft(f"Lazo{sx}", [{"c": ctr, "rx": 0.04, "ry": 0.04}, {"c": ctr + Vector((sx * 0.12, 0, 0)), "rx": 0.09, "ry": 0.03, "u": Vector((0, 0, 1))}, {"c": ctr + Vector((sx * 0.16, 0, 0)), "rx": 0.07, "ry": 0.03, "u": Vector((0, 0, 1))}], segs=8)
        B.add(o, bow, ("rigid", "UpperTorso"), texel=0.2, tag="pajarita")
    knot = G.blob("Nudo", ctr, (0.045, 0.04, 0.045), segs=10, rings=6)
    B.add(knot, bow, ("rigid", "UpperTorso"), texel=0.1, tag="pajarita")
    pants = M(B, "pantalon", G.mat_cloth, G.lin(s["Pants"]), "satin", 1.0)
    C.build_trousers(B, pants, flare=0.0, hem=0.22)
    C.build_shoes(B, M(B, "zapato", G.mat_leather, (0.04, 0.04, 0.05), 0.25), sole_mat(B, (0.05, 0.05, 0.05)), "shoe")
    C.build_hands(B, M(B, "guante", G.mat_cloth, (0.93, 0.93, 0.9), "plain"))


def robot_head(B):
    s = B.s
    H = s["Head"]
    hc = Vector((0, 0.02, H.get("z", 4.82)))
    w, d, h = H.get("w", 0.62), H.get("d", 0.56), H.get("h", 0.6)
    B.head_c, B.head_r = hc, (w, d, h)
    shell = M(B, "carcasa", G.mat_metal, G.lin(s["Skin"]), 0.3)
    rings = [{"c": hc + Vector((0, 0, z * h)), "rx": w * k, "ry": d * k, "sq": 3.6} for z, k in ((-1.0, 0.75), (-0.92, 0.92), (-0.6, 1.0), (0.6, 1.0), (0.92, 0.9), (1.0, 0.7))]
    head = G.loft("Cabeza", rings, segs=28)
    B.head_obj = head
    B.add(head, shell, ("rigid", "Head"), texel=2.0, tag="cabeza")
    visor = M(B, "visor", G.mat_plain, (0.02, 0.03, 0.05), 0.15)
    pane = G.loft("Visor", [{"c": hc + Vector((0, d * 0.86, z * h)), "rx": w * 0.82, "ry": 0.09, "sq": 3.4, "u": Vector((1, 0, 0))} for z in (-0.7, -0.6, 0.55, 0.65)], segs=20)
    B.add(pane, visor, ("rigid", "Head"), texel=1.5, tag="visor")
    glow = M(B, "luz", G.mat_glow, G.lin(s.get("Glow", (90, 200, 255))), 3.0)
    yv = hc.y + d * 0.86 + 0.095
    for side, sx in (("R", 1), ("L", -1)):
        c = Vector((sx * 0.24, yv, hc.z + 0.08))
        eye = G.blob(f"Ojo{side}", (0, 0, 0), (0.11, 0.03, 0.13), segs=16, rings=8)
        eye.location = c
        B.add(eye, glow, ("rigid", "Head"), texel=0.6, tag="ojo")
        B.face[f"FaceLid{side}"] = c.copy()
        lid = C.lid_cap(f"Parpado{side}", 0.15, 0.3)
        lid.location = c + Vector((0, -0.07, 0))
        lid.scale = (1.0, 0.6, 1.0)
        B.add(lid, visor, ("rigid", f"FaceLid{side}"), texel=0.3, tag="parpado")
        brow = G.rbox(f"Ceja{side}", c + Vector((0, 0.0, 0.2)), (0.2, 0.03, 0.04), bevel=0.012, segs=1)
        B.face[f"FaceBrow{side}"] = c + Vector((0, 0.0, 0.2))
        B.add(brow, glow, ("rigid", f"FaceBrow{side}"), texel=0.2, tag="ceja")
    mc = Vector((0, yv, hc.z - 0.26))
    mouth = C.mouth_lens("Boca", 0.17, 0.025, 0.4, d)
    mouth.location = mc
    B.add(mouth, glow, ("fn", lambda p, mc=mc: C.mouth_weights(p, mc, 0.17)), texel=0.4, tag="boca")
    B.face["FaceJaw"] = mc + Vector((0, -0.02, -0.04))
    B.face["FaceMouthR"] = mc + Vector((0.16, -0.03, 0.0))
    B.face["FaceMouthL"] = mc + Vector((-0.16, -0.03, 0.0))
    for sx in (-1, 1):
        ear = G.loft(f"Oreja{sx}", [{"c": hc + Vector((sx * w * 0.95, 0, 0)), "rx": 0.17, "ry": 0.17, "u": Vector((0, 1, 0))}, {"c": hc + Vector((sx * (w + 0.08), 0, 0)), "rx": 0.14, "ry": 0.14, "u": Vector((0, 1, 0))}], segs=16)
        B.add(ear, M(B, "metal_osc", G.mat_metal, (0.25, 0.27, 0.3), 0.35), ("rigid", "Head"), texel=0.3, tag="oreja")
    ant = G.cyl("Antena", hc + Vector((0, -0.05, h * 0.95)), hc + Vector((0, -0.05, h * 0.95 + 0.3)), 0.02, segs=6)
    B.add(ant, shell, ("rigid", "Head"), texel=0.1, tag="antena")
    ball = G.blob("BolaAntena", hc + Vector((0, -0.05, h * 0.95 + 0.34)), (0.06, 0.06, 0.06), segs=10, rings=6)
    B.add(ball, glow, ("rigid", "Head"), texel=0.1, tag="antena")
    neck = G.loft("Cuello", G.path_rings([(0, 0, 3.82), (0, 0, 4.0), (0, 0.01, 4.3)], [0.17, 0.15, 0.17]), segs=12)
    B.add(neck, M(B, "metal_osc", G.mat_metal, (0.25, 0.27, 0.3), 0.35), ("auto", ["UpperTorso", "Head"], 0.1), texel=0.3, tag="cuello")


# ====================================================================== el reparto
REPARTO = [
    {"Key": "Cosme", "Name": "Cosme", "Cast": "Cosme", "Hero": True, "Skin": (240, 204, 168), "Hair": (226, 233, 241), "Eye": (70, 52, 40),
     "Pants": (74, 55, 42), "Wrinkles": 0.7, "Lash": (60, 50, 45),
     "Head": {"w": 0.68, "d": 0.66, "h": 0.78, "jaw": 0.38, "cheek": 0.08, "nose_kind": "long", "nose": (0.1, 0.2, 0.12), "nose_z": -0.1,
              "teeth": True, "teeth_h": 0.03, "smile": 0.75, "mouth_w": 0.25, "mouth_h": 0.045, "mouth_z": -0.43, "brow_w": 0.08, "brow_arch": 0.05,
              "brow_up": 0.02, "eye_r": 0.14, "lid": 0.28, "lid_tilt": -4, "neck": 0.21},
     "Body": dict(BODY_M, chest=0.94, waist=0.84, hips=0.8, shoulder=0.98, arm=0.25, leg=0.37), "build": build_cosme,
     "Faces": ["Grin", "Skeptic", "Laugh", "Scared", "Talk"]},
    {"Key": "Familia_Mama", "Name": "Mamá", "Cast": "Familia", "Variant": "NPC.MAMA", "Hero": True, "Skin": (198, 150, 112), "Hair": (70, 45, 25),
     "Eye": (92, 60, 38), "Shirt": (70, 120, 170), "Pants": (50, 50, 60),
     "Head": {"w": 0.64, "d": 0.63, "h": 0.74, "jaw": 0.42, "cheek": 0.07, "nose_kind": "button", "nose": (0.075, 0.08, 0.075), "smile": 0.45,
              "mouth_w": 0.17, "mouth_h": 0.03, "brow_w": 0.04, "eye_r": 0.14, "lash": True, "neck": 0.19},
     "Body": dict(BODY_F), "build": build_mama, "Faces": ["Neutral", "Happy", "Sad", "Angry", "Scared", "Talk"], "Lash": (20, 12, 10)},
    {"Key": "Familia_Papa", "Name": "Papá", "Cast": "Familia", "Variant": "NPC.PAPA", "Hero": True, "Skin": (198, 150, 112), "Hair": (70, 45, 25),
     "Eye": (92, 60, 38), "Shirt": (70, 120, 170), "Pants": (50, 50, 60), "Beard": "Stubble",
     "Head": {"w": 0.67, "d": 0.65, "h": 0.76, "jaw": 0.25, "cheek": 0.05, "chin": 0.08, "nose_kind": "round", "nose": (0.1, 0.1, 0.1), "smile": 0.35,
              "mouth_w": 0.19, "mouth_h": 0.03, "brow_w": 0.055, "eye_r": 0.13, "neck": 0.23},
     "Body": dict(BODY_M, belly=0.05), "build": build_papa, "Faces": ["Neutral", "Happy", "Sad", "Angry", "Scared", "Talk"]},
    {"Key": "Pip", "Name": "Pip", "Cast": "Pip", "Hero": True, "Robot": True, "Skin": (170, 180, 195), "Hair": (120, 130, 150), "Glow": (90, 200, 255),
     "Shirt": (120, 130, 150), "Pants": (90, 100, 120),
     "Head": {"z": 4.8, "w": 0.62, "d": 0.55, "h": 0.6}, "Body": dict(BODY_M, chest=0.92, waist=0.8, hips=0.78, arm=0.24, leg=0.35),
     "build": build_pip, "Faces": ["Neutral", "Happy", "Sad", "Angry", "Scared", "Talk"]},
    {"Key": "Abu_Rosa", "Name": "Abu Rosa", "Cast": "Abu", "Variant": "NPC.ABU_ROSA", "Hero": False, "Age": "Old", "Skin": (234, 196, 160),
     "Hair": (200, 200, 205), "BrowColor": (170, 165, 165), "Eye": (70, 110, 70), "Shirt": (150, 90, 120), "Pants": (90, 80, 70),
     "Head": {"w": 0.65, "d": 0.63, "h": 0.74, "jaw": 0.3, "cheek": 0.09, "nose_kind": "round", "nose": (0.085, 0.09, 0.085), "smile": 0.5,
              "mouth_w": 0.17, "mouth_h": 0.028, "brow_w": 0.035, "eye_r": 0.12, "neck": 0.19},
     "Body": dict(BODY_F, belly=0.04, waist=0.84), "build": build_abu_rosa, "Faces": ["Neutral", "Happy", "Sad", "Angry", "Scared", "Talk"]},
    {"Key": "Abu_Tomas", "Name": "Abu Tomás", "Cast": "Abu", "Variant": "NPC.ABU_TOMAS", "Hero": False, "Age": "Old", "Skin": (234, 196, 160),
     "Hair": (200, 200, 205), "BrowColor": (190, 188, 190), "Eye": (100, 110, 120), "Shirt": (150, 90, 120), "Pants": (90, 80, 70),
     "Head": {"w": 0.67, "d": 0.65, "h": 0.75, "jaw": 0.28, "cheek": 0.07, "nose_kind": "round", "nose": (0.12, 0.12, 0.12), "nose_z": -0.1, "smile": 0.3,
              "mouth_w": 0.18, "mouth_h": 0.028, "mouth_z": -0.45, "brow_w": 0.06, "brow_arch": 0.03, "eye_r": 0.12, "neck": 0.22},
     "Body": dict(BODY_M, belly=0.07, chest=0.95), "build": build_abu_tomas, "Faces": ["Neutral", "Happy", "Sad", "Angry", "Scared", "Talk"]},
    {"Key": "Lucia", "Name": "Profe Lucía", "Cast": "Lucia", "Hero": False, "Skin": (226, 186, 150), "Hair": (120, 80, 40), "Eye": (120, 96, 52),
     "Shirt": (240, 196, 60), "Pants": (60, 70, 100), "Lash": (25, 15, 10),
     "Head": {"w": 0.64, "d": 0.63, "h": 0.75, "jaw": 0.4, "cheek": 0.06, "nose_kind": "button", "nose": (0.075, 0.085, 0.075), "smile": 0.3,
              "mouth_w": 0.16, "mouth_h": 0.028, "brow_w": 0.04, "brow_arch": 0.04, "eye_r": 0.135, "neck": 0.19},
     "Body": dict(BODY_F), "build": build_lucia, "Faces": ["Neutral", "Happy", "Sad", "Angry", "Scared", "Talk"]},
    {"Key": "Nico", "Name": "Nico", "Cast": "Nico", "Hero": True, "Kid": True, "Skin": (236, 196, 160), "Hair": (70, 45, 25), "Eye": (92, 60, 38),
     "Shirt": (220, 60, 50), "Pants": (40, 60, 120), "Backpack": (200, 50, 50), "Freckles": True,
     "Head": {"z": 4.88, "w": 0.74, "d": 0.7, "h": 0.8, "jaw": 0.42, "cheek": 0.1, "nose_kind": "button", "nose": (0.07, 0.07, 0.065), "smile": 0.6,
              "mouth_w": 0.17, "mouth_h": 0.03, "brow_w": 0.045, "eye_r": 0.165, "eye_z": 0.06, "neck": 0.18, "nose_z": -0.18, "mouth_z": -0.45},
     "Body": dict(BODY_KID), "build": build_nico, "Faces": ["Neutral", "Happy", "Sad", "Angry", "Scared", "Talk"]},
]


def by_key(key):
    for s in REPARTO:
        if s["Key"] == key:
            return s
    return None
