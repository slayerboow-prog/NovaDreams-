"""Piezas de los personajes 3D: cabeza con cara (ojos, párpados, cejas, nariz, boca, orejas), pelo,
cuerpo vestido (camisa, bata, rebeca, frac, pantalón, zapatos, manos) y complementos (gafas, cinturón,
mochila…). Las usa scripts/personajes/personajes3d_blender.py con las fichas de p3d_reparto.py.

Reglas (docs/bugs/moderacion/, encargo «Modelos 3D propios»): todos van vestidos del todo (manga larga,
pantalón largo hasta el zapato, nada de piel salvo la cara, el cuello y las manos), el cuerpo bajo la
ropa es neutro (sin ninguna forma anatómica) y todo es UNA malla por personaje.
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

import p3d_geo as G


class Part:
    def __init__(self, obj, mat, rule, texel=1.0, tag=""):
        self.obj = obj
        self.mat = mat
        self.rule = rule
        self.obj["texel"] = texel
        self.tag = tag


class Builder:
    """Junta las piezas de un personaje: cada una con su material, su regla de pesos y su resolución."""

    def __init__(self, spec):
        self.s = spec
        self.parts = []
        self.face = {}  # puntos de los huesos de la cara
        self.mats = {}
        self.head_obj = None
        self.head_c = None

    def add(self, obj, mat, rule, texel=1.0, tag=""):
        G.assign(obj, mat)
        G.smooth(obj)
        self.parts.append(Part(obj, mat, rule, texel, tag))
        return obj

    def mat(self, key, fn, *a, **kw):
        if key not in self.mats:
            self.mats[key] = fn(f"{self.s['Key']}_{key}", *a, **kw)
        return self.mats[key]


AUTO_TORSO = ("auto", ["LowerTorso", "UpperTorso", "RightUpperArm", "LeftUpperArm"], 0.06)


def _sm(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


# ====================================================================== cabeza
def head_shape(p, H):
    """Deforma la esfera unidad en una cabeza estilizada (H: parámetros de la ficha)."""
    x, y, z = p.x, p.y, p.z
    jaw = H.get("jaw", 0.3)
    if z < 0:
        k = 1 - jaw * (-z) ** 1.8
        x *= k
        if y < 0:
            y *= 1 - 0.25 * (-z) ** 2
    if y < 0:
        y *= H.get("back", 1.04)
    # mejillas
    for sx in (-1, 1):
        d = Vector((x - sx * 0.52, y - 0.62, z + 0.28)).length
        bulge = H.get("cheek", 0.07) * math.exp(-(d / 0.32) ** 2)
        x += sx * bulge * 0.6
        y += bulge * 0.7
    # cuencas de los ojos
    for sx in (-1, 1):
        d = Vector((x - sx * H.get("eye_x", 0.4) * 1.0, (y - 0.9) * 1.4, z - H.get("eye_z", 0.1))).length
        y -= 0.07 * math.exp(-(d / 0.22) ** 2)
    # barbilla
    d = Vector((x, y - 0.7, z + 0.82)).length
    y += H.get("chin", 0.06) * math.exp(-(d / 0.3) ** 2)
    z -= H.get("chin", 0.06) * 0.6 * math.exp(-(d / 0.3) ** 2)
    if z > 0.75:
        z = 0.75 + (z - 0.75) * H.get("top", 0.9)
    return Vector((x, y, z))


def build_head(B):
    s = B.s
    H = s["Head"]
    hc = Vector((0, H.get("y", 0.03), H.get("z", 4.86)))
    w, d, h = H.get("w", 0.68), H.get("d", 0.66), H.get("h", 0.76)
    B.head_c = hc
    B.head_r = (w, d, h)
    skin = G.lin(s["Skin"])
    blush = [((sx * w * 0.62, d * 0.74, -h * 0.3), 0.2) for sx in (-1, 1)]
    stubble = None
    if s.get("Beard") == "Stubble":
        stubble = (G.shade(G.lin(s["Hair"]), 0.75), -h * 0.28, d * 0.15)
    mskin = B.mat("piel_cara", G.mat_skin, skin, blush=blush, freckles=s.get("Freckles", False),
                  wrinkles=s.get("Wrinkles", 1.0 if s.get("Age") == "Old" else 0.0), stubble=stubble, head=((0, d * 0.85, -h * 0.05), w * 0.55))
    head = G.blob("Cabeza", (0, 0, 0), (w, d, h), segs=32, rings=20, deform=lambda p: head_shape(p, H))
    head.location = hc
    bpy.context.view_layer.update()
    B.head_obj = head
    B.add(head, mskin, ("rigid", "Head"), texel=3.0, tag="cabeza")
    surf = G.Surface(head)

    def front(x, z):
        loc, nor = surf.front(x, hc.z + z)
        if loc is None:
            return Vector((x, hc.y + d * 0.9, hc.z + z)), Vector((0, 1, 0))
        return loc, nor

    # ---- ojos
    ex, ez = H.get("eye_x", 0.4) * w, H.get("eye_z", 0.1) * h
    re = H.get("eye_r", 0.135)
    iris = G.lin(s.get("Eye", (92, 60, 38)))
    meye = B.mat("ojo", G.mat_eye, iris, glow=s.get("Robot", False))
    lid_mat = B.mat("parpado", mat_lid, skin, G.shade(G.lin(s.get("Lash", (40, 28, 22))), 1.0))
    for side, sx in (("R", 1), ("L", -1)):
        loc, nor = front(sx * ex, ez)
        c = loc - nor * re * 0.42 + Vector((0, -0.01, 0))
        eye = G.blob(f"Ojo{side}", (0, 0, 0), (re, re * 0.92, re), segs=14, rings=9)
        # el globo mira algo hacia fuera (como la cara): el iris va delante (+Y)
        eye.location = c
        eye.rotation_euler = (0, 0, -sx * math.radians(H.get("eye_turn", 6)))
        B.add(eye, meye, ("rigid", "Head"), texel=2.5, tag="ojo")
        B.face[f"FaceLid{side}"] = c.copy()
        # párpado de arriba: casquete un poco mayor que el globo
        lid = lid_cap(f"Parpado{side}", re * 1.07, H.get("lid", 0.34))
        lid.location = c
        lid.rotation_euler = (math.radians(H.get("lid_tilt", 4)), 0, -sx * math.radians(H.get("eye_turn", 6)))
        B.add(lid, lid_mat, ("rigid", f"FaceLid{side}"), texel=2.0, tag="parpado")
    # ---- cejas
    hair_c = G.lin(s.get("BrowColor", s["Hair"]))
    mbrow = B.mat("ceja", G.mat_hair, G.shade(hair_c, 0.85), "X")
    bw = H.get("brow_w", 0.05)
    for side, sx in (("R", 1), ("L", -1)):
        pts = []
        n = 6
        for i in range(n):
            t = i / (n - 1)
            x = sx * (ex - re * 1.05 + t * re * 2.3)
            z = ez + re * 1.32 + H.get("brow_arch", 0.05) * math.sin(math.pi * t) - 0.02 * t + H.get("brow_up", 0.0)
            loc, nor = front(x, z)
            pts.append(loc + nor * 0.022)
        rings = []
        for i, p in enumerate(pts):
            t = i / (n - 1)
            thick = bw * (1.15 - 0.55 * t) * (0.6 if i == 0 else 1.0)
            rings.append({"c": p, "rx": 0.03, "ry": thick, "sq": 2.6, "ref": Vector((0, 1, 0))})
        brow = G.loft(f"Ceja{side}", rings, segs=8)
        mid = pts[n // 2]
        B.face[f"FaceBrow{side}"] = mid.copy()
        B.add(brow, mbrow, ("rigid", f"FaceBrow{side}"), texel=1.5, tag="ceja")
    # ---- nariz
    nz = H.get("nose_z", -0.12) * h
    loc, nor = front(0, nz)
    ns = H.get("nose", (0.11, 0.12, 0.11))
    nose = G.blob("Nariz", (0, 0, 0), ns, segs=16, rings=10, deform=lambda p: nose_shape(p, H.get("nose_kind", "round")))
    nose.location = loc + Vector((0, ns[1] * 0.35, 0))
    B.add(nose, mskin, ("rigid", "Head"), texel=2.0, tag="nariz")
    # ---- boca (el hueco: una sola boca, la mueven FaceJaw y FaceMouthL/R)
    mz = H.get("mouth_z", -0.4) * h
    mw = H.get("mouth_w", 0.2)
    loc, nor = front(0, mz)
    mouth = mouth_lens("Boca", mw, H.get("mouth_h", 0.03), H.get("smile", 0.35), d)
    mouth.location = loc
    conform(mouth, surf, 0.012, -0.03)
    mmouth = B.mat("boca", G.mat_mouth)
    mc = mouth.location.copy()
    B.face["FaceJaw"] = mc + Vector((0, -0.02, -0.04))
    B.face["FaceMouthR"] = mc + Vector((mw * 0.95, -0.03, 0.0))
    B.face["FaceMouthL"] = mc + Vector((-mw * 0.95, -0.03, 0.0))
    B.add(mouth, mmouth, ("fn", lambda p, mc=mc, mw=mw: mouth_weights(p, mc, mw)), texel=2.0, tag="boca")
    if H.get("teeth"):
        teeth = teeth_strip("Dientes", mw * 0.8, H.get("teeth_h", 0.022), H.get("smile", 0.35), mw)
        teeth.location = mc + Vector((0, 0.0, H.get("mouth_h", 0.03) * 0.45))
        conform(teeth, surf, 0.016, 0.004)
        B.add(teeth, B.mat("dientes", G.mat_plain, (0.93, 0.92, 0.86), 0.3), ("rigid", "Head"), texel=1.0, tag="dientes")
    # ---- orejas
    for side, sx in (("R", 1), ("L", -1)):
        loc, nor = surf.hit((sx * 3.0, hc.y - 0.04 * d, hc.z + H.get("ear_z", 0.0) * h), (-sx, 0, 0))
        if loc is None:
            loc = Vector((sx * w, hc.y, hc.z))
        es = H.get("ear", (0.06, 0.12, 0.17))
        ear = G.blob(f"Oreja{side}", (0, 0, 0), es, segs=12, rings=8, deform=lambda p, sx=sx: ear_shape(p, sx))
        ear.location = loc + Vector((sx * es[0] * 0.4, -0.02, 0))
        ear.rotation_euler = (0, 0, sx * math.radians(-12))
        B.add(ear, mskin, ("rigid", "Head"), texel=1.2, tag="oreja")
    # ---- cuello
    neck = G.loft("Cuello", G.path_rings([(0, 0.0, 3.82), (0, 0.0, 4.15), (0, 0.02, 4.45)], [H.get("neck", 0.22)] * 3), segs=14)
    B.add(neck, B.mat("piel", G.mat_skin, skin), ("auto", ["UpperTorso", "Head"], 0.1), texel=0.8, tag="cuello")
    return surf


def conform(o, surf, front, back):
    """Pega una pieza fina (boca, dientes) a la cara: cada vértice a la altura de la piel que tiene
    delante, más `front` (su cara de delante) o `back` (la de detrás)."""
    bpy.context.view_layer.update()
    mw = o.matrix_world.copy()
    inv = mw.inverted()
    for v in o.data.vertices:
        w = mw @ v.co
        loc, nor = surf.front(w.x, w.z)
        if loc is None:
            continue
        off = front if v.co.y >= 0 else back
        w.y = loc.y + off * (abs(v.co.y) / 0.025 if v.co.y >= 0 else 1.0)
        v.co = inv @ w
    o.data.update()


def mat_lid(name, skin, lash):
    mat, K, bsdf = G._base(name)
    P = K.coord("Object")
    S = K.sep(P)
    # el borde de abajo del casquete (z bajo) es la línea de las pestañas
    col = K.mix(K.ramp(S[2], 0.035, 0.02), skin, lash)
    return G._finish(mat, K, bsdf, col, 0.5)


def lid_cap(name, r, low):
    """Casquete de esfera (párpado de arriba): de arriba hasta z = low·r (más el borde de pestañas)."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=18, v_segments=12, radius=r)
    kill = [v for v in bm.verts if v.co.z < low * r - 1e-6]
    bmesh.ops.delete(bm, geom=kill, context="VERTS")
    # borde un poco hacia dentro (que no se vea el canto fino)
    for v in bm.verts:
        if v.co.z < (low + 0.12) * r and v.co.y > 0:
            v.co.y += 0.004
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return G.new_obj(name, me)


def nose_shape(p, kind):
    x, y, z = p.x, p.y, p.z
    if kind == "long":  # la de Cosme: larga, con la punta algo caída
        if y > 0:
            z -= 0.25 * y * y
        if z < -0.2:
            x *= 1.12
    elif kind == "button":
        if z < 0:
            x *= 1.15
            y *= 1.05
    elif kind == "robot":
        return p
    else:  # redonda, con aletas
        if z < -0.1:
            x *= 1.18
    return Vector((x, y, z))


def ear_shape(p, sx):
    x, y, z = p.x, p.y, p.z
    if x * sx > 0:  # la cara de fuera algo cóncava
        x -= sx * 0.35 * math.exp(-((y * 1.2) ** 2 + (z * 1.1) ** 2) * 2.5)
    if z < -0.4:
        y *= 0.8
    return Vector((x, y, z))


def mouth_lens(name, mw, mh, smile, head_d):
    """El hueco de la boca: una lente aplanada que sigue la curva de la cara, con las comisuras algo
    arriba (smile). Cerrada es una línea; abierta (FaceJaw abajo), el hueco oscuro con la lengua."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=8, radius=1.0)
    for v in bm.verts:
        x, y, z = v.co.x * mw, v.co.y * 0.025, v.co.z * mh
        z += smile * 1.2 * (x * x) / mw  # comisuras
        v.co = Vector((x, y, z))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return G.new_obj(name, me)


def teeth_strip(name, w, h, smile, mw):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=6, radius=1.0)
    for v in bm.verts:
        x, y, z = v.co.x * w, v.co.y * 0.025, v.co.z * h
        z += smile * 1.2 * (x * x) / mw
        v.co = Vector((x, y, z))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return G.new_obj(name, me)


def mouth_weights(p, mc, mw):
    q = p - mc
    side = _sm((abs(q.x) - mw * 0.25) / (mw * 0.6))
    low = _sm((-q.z) / 0.02 + 0.5)
    corner = "FaceMouthR" if q.x > 0 else "FaceMouthL"
    ws = [(corner, side), ("FaceJaw", low * (1 - side * 0.7)), ("Head", (1 - low) * (1 - side) + 0.001)]
    return ws


# ====================================================================== pelo
def scalp_dir(B, theta, phi):
    """Punto y normal sobre la cabeza (ángulos: theta alrededor desde el frente, phi desde arriba)."""
    w, d, h = B.head_r
    x = math.sin(phi) * math.sin(theta)
    y = math.sin(phi) * math.cos(theta)
    z = math.cos(phi)
    p = Vector((x * w, y * d, z * h)) + B.head_c
    n = Vector((x / w, y / d, z / h)).normalized()
    return p, n


def hair_cap(B, name, hairline, scale=1.07, segs=34, rings=22, lift=0.0):
    """Casquete de pelo: la cabeza algo mayor, solo por encima de la línea del pelo hairline(p unidad)
    -> bool. El borde se mete hasta la piel (sin canto fino)."""
    H = B.s["Head"]
    w, d, h = B.head_r
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0)
    unit = {}
    for v in bm.verts:
        unit[v] = Vector(v.co)
    kill = [f for f in bm.faces if not all(hairline(unit[v]) for v in f.verts)]
    bmesh.ops.delete(bm, geom=kill, context="FACES")
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    boundary = {v for e in bm.edges if e.is_boundary for v in e.verts}
    near = set()
    for v in boundary:
        for e in v.link_edges:
            near.add(e.other_vert(v))
    for v in bm.verts:
        p = head_shape(unit[v], H)
        k = 1.0 if v in boundary else ((1 + (scale - 1) * 0.5) if v in near else scale)
        top = max(0.0, unit[v].z) * lift
        v.co = Vector((p.x * w * k, p.y * d * k, p.z * h * k + top)) + B.head_c
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return G.new_obj(name, me)


def lock(name, root, direction, length, width, thick, normal, bend=0.0, n=6, segs=6, curl=None, tip=0.12, twist=0.0):
    """Mechón: una lámina gruesa que sale de root hacia direction, ancha en la raíz y en punta (tip
    = anchura relativa en la punta), doblándose hacia «normal·bend» (hacia fuera o hacia la cabeza)."""
    root = Vector(root)
    dv = Vector(direction).normalized()
    nv = Vector(normal).normalized()
    pts = []
    for i in range(n):
        t = i / (n - 1)
        p = root + dv * (length * t) + nv * (bend * length * t * t)
        if curl is not None:
            p += Vector(curl) * (t ** 3) * length
        pts.append(p)
    rings = []
    for i, p in enumerate(pts):
        t = i / (n - 1)
        tang = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        side = tang.cross(nv).normalized()
        if twist:
            side = (Matrix.Rotation(twist * t, 3, tang) @ side).normalized()
        wt = width * (1 - (1 - tip) * t ** 1.3) * (0.85 if i == 0 else 1.0)
        th = thick * (1 - 0.6 * t)
        rings.append({"c": p, "rx": wt, "ry": th, "sq": 2.2, "u": side})
    return G.loft(name, rings, segs=segs)


# ====================================================================== cuerpo
def torso_rings(T, z0=1.95, z1=4.0, grow=0.0, extra_low=None):
    """Anillos del tronco (camisa) según la ficha: T = {chest, waist, hips, depth, belly, shoulder}."""
    ch, wa, hi, de = T.get("chest", 0.95), T.get("waist", 0.82), T.get("hips", 0.8), T.get("depth", 0.5)
    be = T.get("belly", 0.0)
    sh = T.get("shoulder", 0.98)
    prof = [
        (z0, hi, de * 0.98, 0.0),
        (2.2, hi * 1.01, de * 1.0, be * 0.4),
        (2.5, wa, de * 0.98 + be * 0.25, be * 0.9),
        (2.85, wa * 1.03, de * 1.0 + be * 0.15, be * 0.6),
        (3.2, ch * 0.97, de * 1.04, 0.02),
        (3.5, ch, de * 1.04, 0.02),
        (3.7, sh * 1.06, de * 0.95, 0.0),
        (3.84, sh * 0.92, de * 0.82, -0.02),
        (3.94, sh * 0.62, de * 0.62, -0.03),
        (z1, 0.34, 0.3, -0.02),
    ]
    rings = []
    for z, rx, ry, fy in prof:
        rings.append({"c": Vector((0, fy * 0.5, z)), "rx": rx + grow, "ry": ry + grow, "sq": 2.5})
    return rings


def build_torso(B, mat, z0=2.25, grow=0.0, gap=None, segs=26, name="Camisa", texel=1.0, cap1=True):
    T = B.s["Body"]
    o = G.loft(name, torso_rings(T, z0, grow=grow), segs=segs, cap0=False, cap1=cap1 and gap is None, gap=gap)
    return B.add(o, mat, AUTO_TORSO, texel=texel, tag="torso")


def sleeve_path(sx, T, z_end=2.32):
    sh = T.get("shoulder", 0.98)
    return [(sx * (sh * 0.9), 0, 3.48), (sx * 1.18, 0, 3.5), (sx * 1.42, 0, 3.44), (sx * 1.5, 0, 3.2), (sx * 1.5, 0, 3.04),
            (sx * 1.5, 0.01, 2.75), (sx * 1.5, 0.02, 2.5), (sx * 1.5, 0.02, z_end)]


def build_sleeves(B, mat, grow=0.0, cuff=None, name="Manga", texel=1.0, z_end=2.32):
    T = B.s["Body"]
    a = T.get("arm", 0.26)
    for side, sx in (("R", 1), ("L", -1)):
        pts = sleeve_path(sx, T, z_end)
        rad = [a * 0.95, a * 1.08, a * 1.05, a * 0.98, a * 0.93, a * 0.88, a * 0.86, a * 0.9]
        rad = [r + grow for r in rad]
        o = G.loft(f"{name}{side}", G.path_rings(pts, rad, sq=2.2), segs=14, cap0=True, cap1=True, ref=Vector((0, 1, 0)))
        arm = ARM_R_ if sx > 0 else ARM_L_
        B.add(o, mat, ("auto", ["UpperTorso"] + arm, 0.06), texel=texel, tag="manga")
        if cuff:
            cm, ch = cuff
            c = G.loft(f"Puno{side}", G.path_rings([(sx * 1.5, 0.02, z_end + ch), (sx * 1.5, 0.02, z_end - 0.01)], [a * 0.95 + grow + 0.02] * 2, sq=2.2), segs=14)
            B.add(c, cm, ("rigid", "RightLowerArm" if sx > 0 else "LeftLowerArm"), texel=0.6, tag="puño")


ARM_R_ = ["RightUpperArm", "RightLowerArm", "RightHand"]
ARM_L_ = ["LeftUpperArm", "LeftLowerArm", "LeftHand"]


def build_hands(B, mat, glove=False):
    T = B.s["Body"]
    k = T.get("hand", 1.0)
    for side, sx in (("R", 1), ("L", -1)):
        bone = "RightHand" if sx > 0 else "LeftHand"
        wx = sx * 1.5
        # palma: mira hacia el cuerpo (su grosor en X), ancha en Y
        palm = G.loft(f"Palma{side}", [
            {"c": Vector((wx, 0.02, 2.36)), "rx": 0.085 * k, "ry": 0.12 * k, "sq": 2.4},
            {"c": Vector((wx, 0.02, 2.2)), "rx": 0.09 * k, "ry": 0.145 * k, "sq": 2.8},
            {"c": Vector((wx - sx * 0.01, 0.02, 2.04)), "rx": 0.085 * k, "ry": 0.15 * k, "sq": 2.8},
            {"c": Vector((wx - sx * 0.015, 0.02, 1.97)), "rx": 0.07 * k, "ry": 0.135 * k, "sq": 2.6},
        ], segs=12)
        B.add(palm, mat, ("auto", [bone, "RightLowerArm" if sx > 0 else "LeftLowerArm"], 0.04), texel=1.2, tag="mano")
        # cuatro dedos un poco doblados hacia la palma (hacia el cuerpo)
        for i, fy in enumerate((-0.105, -0.035, 0.035, 0.1)):
            ln = (0.17, 0.2, 0.21, 0.19)[i] * k
            top = Vector((wx - sx * 0.012, 0.02 + fy * k, 2.0))
            pts = [top + Vector((-sx * 0.05 * (t ** 2) * 1.6, 0, -ln * t)) for t in (0, 0.35, 0.7, 1.0)]
            rr = [0.042 * k, 0.04 * k, 0.037 * k, 0.03 * k]
            f = G.loft(f"Dedo{side}{i}", G.path_rings(pts, rr), segs=6)
            B.add(f, mat, ("rigid", bone), texel=0.8, tag="mano")
        # pulgar: hacia delante y abajo
        base = Vector((wx - sx * 0.045, 0.14 * k, 2.2))
        pts = [base, base + Vector((-sx * 0.03, 0.07, -0.06)) * k, base + Vector((-sx * 0.05, 0.1, -0.14)) * k]
        th = G.loft(f"Pulgar{side}", G.path_rings(pts, [0.05 * k, 0.045 * k, 0.036 * k]), segs=6)
        B.add(th, mat, ("rigid", bone), texel=0.8, tag="mano")


def build_trousers(B, mat, flare=0.0, hem=0.24, name="Pantalon", texel=1.0, wide=0.0):
    T = B.s["Body"]
    hi, de = T.get("hips", 0.8), T.get("depth", 0.5)
    wa = T.get("waist", 0.82)
    be = T.get("belly", 0.0)
    pel = G.loft(f"{name}Cadera", [
        {"c": Vector((0, be * 0.45, 2.62)), "rx": wa * 1.03 + 0.035, "ry": de * 1.0 + be * 0.25 + 0.035, "sq": 2.5},
        {"c": Vector((0, be * 0.2, 2.4)), "rx": (wa + hi) / 2 + 0.04, "ry": de * 1.0 + 0.04, "sq": 2.5},
        {"c": Vector((0, 0, 2.15)), "rx": hi * 1.0 + 0.03, "ry": de * 1.0 + 0.02, "sq": 2.8},
        {"c": Vector((0, 0, 1.95)), "rx": hi * 1.0 + 0.02, "ry": de * 0.98, "sq": 3.0},
        {"c": Vector((0, 0, 1.72)), "rx": hi * 0.98, "ry": de * 0.9, "sq": 3.2},
        {"c": Vector((0, 0, 1.66)), "rx": hi * 0.9, "ry": de * 0.8, "sq": 3.2},
    ], segs=24, cap0=False, cap1=True)
    # (cadera de pantalón recta, como una caja: sin redondeces que, gris y sin textura, se lean como cuerpo)
    B.add(pel, mat, ("auto", ["LowerTorso", "RightUpperLeg", "LeftUpperLeg"], 0.05), texel=texel, tag="pantalón")
    L = T.get("leg", 0.38) + wide
    for side, sx in (("R", 1), ("L", -1)):
        x = sx * 0.5
        pts = [(x, 0, 2.08), (x, 0, 1.75), (x, 0.0, 1.45), (x, 0.01, 1.17), (x, 0.0, 0.85), (x, -0.01, 0.55), (x, -0.01, hem + 0.06), (x, -0.01, hem)]
        rad = [L * 0.95, L * 0.97, L * 0.95, L * 0.88, L * 0.85, L * 0.84 + flare * 0.5, L * 0.86 + flare, L * 0.87 + flare]
        o = G.loft(f"{name}{side}", G.path_rings(pts, rad, sq=2.2), segs=16, cap0=False, cap1=False)
        leg = ["RightUpperLeg", "RightLowerLeg", "RightFoot"] if sx > 0 else ["LeftUpperLeg", "LeftLowerLeg", "LeftFoot"]
        B.add(o, mat, ("auto", ["LowerTorso"] + leg[:2], 0.06), texel=texel, tag="pernera")
        # el bajo por dentro (que no se vea hueco al levantar el pie)
        inner = G.loft(f"{name}Bajo{side}", [{"c": Vector((x, -0.01, hem + 0.12)), "rx": L * 0.82 + flare, "ry": L * 0.82 + flare, "sq": 2.2},
                                             {"c": Vector((x, -0.01, hem + 0.01)), "rx": L * 0.86 + flare, "ry": L * 0.86 + flare, "sq": 2.2}], segs=14, cap0=True, cap1=False)
        B.add(inner, B.mat("oscuro", G.mat_plain, (0.05, 0.05, 0.06), 0.9), ("rigid", leg[1]), texel=0.2, tag="pernera")


def build_shoes(B, mat, sole_mat, kind="shoe"):
    for side, sx in (("R", 1), ("L", -1)):
        x = sx * 0.5
        bone = "RightFoot" if sx > 0 else "LeftFoot"
        low = "RightLowerLeg" if sx > 0 else "LeftLowerLeg"
        if kind == "boot":
            prof = [(-0.22, 0.2, 0.15, 0.17), (-0.2, 0.22, 0.22, 0.24), (-0.05, 0.23, 0.22, 0.24), (0.12, 0.225, 0.16, 0.17), (0.28, 0.21, 0.12, 0.12), (0.4, 0.17, 0.09, 0.1), (0.46, 0.1, 0.06, 0.09)]
        elif kind == "sneaker":
            prof = [(-0.21, 0.17, 0.13, 0.15), (-0.19, 0.2, 0.17, 0.18), (-0.02, 0.21, 0.17, 0.18), (0.15, 0.21, 0.13, 0.14), (0.3, 0.2, 0.1, 0.11), (0.42, 0.16, 0.08, 0.09), (0.47, 0.09, 0.05, 0.08)]
        else:
            prof = [(-0.2, 0.15, 0.12, 0.14), (-0.18, 0.19, 0.15, 0.17), (0.0, 0.2, 0.15, 0.16), (0.16, 0.2, 0.11, 0.13), (0.3, 0.19, 0.085, 0.1), (0.42, 0.15, 0.065, 0.085), (0.47, 0.08, 0.04, 0.075)]
        rings = [{"c": Vector((x, y, zc)), "rx": rx, "ry": h, "sq": 2.6} for y, rx, h, zc in prof]
        o = G.loft(f"Zapato{side}", rings, segs=12)
        B.add(o, mat, ("auto", [bone, low], 0.05), texel=0.8, tag="zapato")
        if kind == "boot":  # caña de la bota bajo el pantalón
            c = G.loft(f"Cana{side}", G.path_rings([(x, -0.03, 0.2), (x, -0.03, 0.55)], [0.25, 0.27], sq=2.3), segs=14, cap0=False)
            B.add(c, mat, ("auto", [low, bone], 0.05), texel=0.5, tag="zapato")
        sole = G.loft(f"Suela{side}", [{"c": Vector((x, y, 0.035)), "rx": rx + 0.018, "ry": 0.04, "sq": 3.0} for y, rx, h, zc in prof[1:]], segs=12)
        B.add(sole, sole_mat, ("rigid", bone), texel=0.5, tag="suela")


def build_buttons(B, mat, pts, r=0.035, bone_rule=None):
    for i, p in enumerate(pts):
        b = G.blob(f"Boton{i}", (0, 0, 0), (r, r * 0.5, r), segs=10, rings=6)
        b.location = Vector(p)
        B.add(b, mat, bone_rule or AUTO_TORSO, texel=0.15, tag="botón")


def torso_front(T, z, grow=0.0):
    """El punto de delante del tronco a la altura z (para botones, colgantes, bolsillos)."""
    rings = torso_rings(T, grow=grow)
    for a, b in zip(rings, rings[1:]):
        if a["c"].z <= z <= b["c"].z:
            t = (z - a["c"].z) / max(b["c"].z - a["c"].z, 1e-6)
            ry = a["ry"] + (b["ry"] - a["ry"]) * t
            cy = a["c"].y + (b["c"].y - a["c"].y) * t
            return Vector((0, cy + ry, z))
    return Vector((0, T.get("depth", 0.5), z))


def build_collar(B, mat, open_v=0.5, h=0.16, grow=0.03, name="Cuello", points=True):
    """Cuello de camisa: banda alrededor del cuello, abierta delante, con las puntas caídas."""
    T = B.s["Body"]
    rings = [{"c": Vector((0, -0.01, 3.93)), "rx": 0.42 + grow, "ry": 0.36 + grow, "sq": 2.2},
             {"c": Vector((0, -0.02, 3.93 + h)), "rx": 0.36 + grow, "ry": 0.31 + grow, "sq": 2.2}]
    o = G.loft(name, rings, segs=20, cap0=False, cap1=False, gap=((0, 1, 0), open_v))
    sol = o.modifiers.new("Grosor", "SOLIDIFY")
    sol.thickness = 0.025
    G.apply_mods(o)
    B.add(o, mat, ("auto", ["UpperTorso", "Head"], 0.08), texel=0.5, tag="cuello")
    # puntas del cuello sobre el pecho
    for side, sx in ((("R", 1), ("L", -1)) if points else ()):
        p0 = Vector((sx * 0.17, 0.3, 3.99))
        pts = [p0, p0 + Vector((sx * 0.05, 0.05, -0.08)), p0 + Vector((sx * 0.08, 0.07, -0.16))]
        tipo = G.loft(f"{name}Punta{side}", [{"c": pts[0], "rx": 0.07, "ry": 0.012, "sq": 2.5, "u": Vector((1, 0, 0))},
                                            {"c": pts[1], "rx": 0.06, "ry": 0.012, "sq": 2.5, "u": Vector((1, -0.5, 0))},
                                            {"c": pts[2], "rx": 0.02, "ry": 0.01, "sq": 2.0, "u": Vector((1, -0.5, 0))}], segs=6)
        B.add(tipo, mat, ("rigid", "UpperTorso"), texel=0.4, tag="cuello")


def build_pocket(B, mat, center, size, normal_y=1.0, rule=None, name="Bolsillo", flap=True):
    p = G.rbox(name, center, size, bevel=0.012, segs=1)
    B.add(p, mat, rule or AUTO_TORSO, texel=0.3, tag="bolsillo")
    if flap:
        f = G.rbox(name + "Solapa", Vector(center) + Vector((0, size[1] * 0.4 * normal_y, size[2] * 0.42)), (size[0] * 1.06, size[1] * 1.2, size[2] * 0.26), bevel=0.01, segs=1)
        B.add(f, mat, rule or AUTO_TORSO, texel=0.2, tag="bolsillo")


def build_belt(B, mat, buckle_mat, z=2.55, grow=0.03):
    T = B.s["Body"]
    wa, hi, de = T.get("waist", 0.82), T.get("hips", 0.8), T.get("depth", 0.5)
    be = T.get("belly", 0.0)
    rx = (wa * 1.03 + 0.035 + (wa + hi) / 2 + 0.04) / 2 + grow
    ry = de + be * 0.15 + 0.035 + grow
    o = G.loft("Cinturon", [{"c": Vector((0, be * 0.3, z - 0.065)), "rx": rx, "ry": ry, "sq": 2.5},
                            {"c": Vector((0, be * 0.35, z + 0.065)), "rx": rx - 0.005, "ry": ry, "sq": 2.5}], segs=24, cap0=False, cap1=False)
    sol = o.modifiers.new("Grosor", "SOLIDIFY")
    sol.thickness = 0.02
    G.apply_mods(o)
    B.add(o, mat, ("rigid", "LowerTorso"), texel=0.4, tag="cinturón")
    b = G.rbox("Hebilla", (0, be * 0.33 + ry + 0.02, z), (0.17, 0.035, 0.13), bevel=0.02, segs=2)
    B.add(b, buckle_mat, ("rigid", "LowerTorso"), texel=0.2, tag="cinturón")
