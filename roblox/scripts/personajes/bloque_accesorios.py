"""Accesorios 3D del estilo bloque (encargo del dueño: avatar de bloques de Roblox «premium»): pelo,
gafas, batas y chaquetas por piezas, mochilas, botas, cinturones y objetos en la mano de cada personaje.
Cada accesorio es una pieza RÍGIDA soldada a UNA parte del R15 (como un sombrero de Roblox), nunca una
parte del cuerpo: un mechón de pelo, una gafa, una bota… Los usa scripts/personajes/bloque_blender.py.

Coordenadas de Blender en studs (x derecha del personaje, y delante, z arriba; pies en z = 0) sobre el
R15 de bloques en reposo (raíz a 3 studs): PARTS da el centro y el tamaño de cada parte.
Cada accesorio: Acc(nombre, objeto, parte, glow=None, lod=False, texel=1).
"""
import math
import random

import bpy  # noqa: I001  (bpy antes que bmesh)
import bmesh
from mathutils import Matrix, Vector

import p3d_geo as G

# Partes del R15 de bloques en reposo: centro (Blender) y tamaño (ancho x, fondo y, alto z)
PARTS = {
    "Head": ((0, 0, 4.6), (1.2, 1.2, 1.2)),
    "UpperTorso": ((0, 0, 3.2), (2, 1, 1.6)),
    "LowerTorso": ((0, 0, 2.2), (2, 1, 0.4)),
    "RightUpperArm": ((1.5, 0, 3.37), (1, 1, 1.17)),
    "RightLowerArm": ((1.5, 0, 2.78), (1, 1, 1.05)),
    "RightHand": ((1.5, 0, 2.16), (1, 1, 0.3)),
    "LeftUpperArm": ((-1.5, 0, 3.37), (1, 1, 1.17)),
    "LeftLowerArm": ((-1.5, 0, 2.78), (1, 1, 1.05)),
    "LeftHand": ((-1.5, 0, 2.16), (1, 1, 0.3)),
    "RightUpperLeg": ((0.5, 0, 1.58), (1, 1, 1.22)),
    "RightLowerLeg": ((0.5, 0, 0.73), (1, 1, 1.19)),
    "RightFoot": ((0.5, 0, 0.08), (1, 1, 0.3)),
    "LeftUpperLeg": ((-0.5, 0, 1.58), (1, 1, 1.22)),
    "LeftLowerLeg": ((-0.5, 0, 0.73), (1, 1, 1.19)),
    "LeftFoot": ((-0.5, 0, 0.08), (1, 1, 0.3)),
}
HEAD_C = Vector(PARTS["Head"][0])


class Acc:
    def __init__(self, name, obj, part, glow=None, lod=False, texel=1.0, label=None):
        self.name = name
        self.obj = obj
        obj.name = name
        self.part = part
        self.glow = glow  # color (0..1) si es una pieza de luz (Neon en Roblox)
        self.lod = lod
        self.texel = texel
        self.label = label or name


class Kit:
    def __init__(self, spec):
        self.s = spec
        self.accs = []
        self.mats = {}

    def mat(self, key, fn, *a, **kw):
        if key not in self.mats:
            self.mats[key] = fn(f"{self.s['Key']}_{key}", *a, **kw)
        return self.mats[key]

    def add(self, name, objs, part, mat=None, glow=None, lod=False, texel=1.0, label=None):
        """Junta las piezas (cada una ya con su material) en UN accesorio."""
        if not isinstance(objs, (list, tuple)):
            objs = [objs]
        for o in objs:
            if mat is not None and not o.data.materials:
                G.assign(o, mat)
            G.smooth(o)
        bpy.context.view_layer.update()
        for o in objs:
            G.store_local(o)
            G.select_only([o])
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        if len(objs) > 1:
            G.select_only(objs, objs[0])
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active if len(objs) > 1 else objs[0]
        a = Acc(name, o, part, glow, lod, texel, label)
        self.accs.append(a)
        return a

    def glow(self, name, objs, part, color, label=None):
        m = self.mat("luz_" + name, G.mat_glow, color, 3.0)
        for o in (objs if isinstance(objs, (list, tuple)) else [objs]):
            G.assign(o, m)
        return self.add(name, objs, part, glow=color, texel=0.2, label=label)


def mats_cloth(K, key, color, kind="canvas", **kw):
    return K.mat(key, G.mat_cloth, color, kind, 1.0, **kw)


def lin(c):
    return G.lin(c)


# ====================================================================== piezas comunes
def head_block(K, skin):
    """La cabeza de bloque (un cubo redondeado del color de la piel): la cara va encima con un Decal."""
    c, s = PARTS["Head"]
    o = G.rbox("CabezaBloque", c, (1.26, 1.22, 1.22), bevel=0.2, segs=3)
    return K.add("CabezaBloque", o, "Head", K.mat("piel", G.mat_plain, lin(skin), 0.55, noise=0.06), texel=0.6, label="Cabeza de bloque")


def box_shell(name, center, half, z0, z1, sq=4.0, segs=24, gap=None, top=None, cap0=False, cap1=False, thick=0.05):
    """Funda de tela alrededor de una parte (manga, torso…): anillos de superelipse casi cuadrada."""
    rings = []
    for z, k in ((z0, 1.0), (z1, 1.0)) if top is None else top:
        rings.append({"c": Vector((center[0], center[1], z)), "rx": half[0] * k, "ry": half[1] * k, "sq": sq})
    o = G.loft(name, rings, segs=segs, cap0=cap0, cap1=cap1, gap=gap)
    if thick:
        m = o.modifiers.new("Grosor", "SOLIDIFY")
        m.thickness = thick
        m.offset = 1.0
        G.apply_mods(o)
    return o


def arc_shell(name, rings, a0, a1, segs=12, thick=0.06):
    """Trozo de anillo (de a0 a a1 en grados, en el plano XY desde +X): faldón de bata por mitades."""
    bm = bmesh.new()
    grid = []
    for r in rings:
        row = []
        for k in range(segs + 1):
            a = math.radians(a0 + (a1 - a0) * k / segs)
            ca, sa = math.cos(a), math.sin(a)
            e = 2.0 / r.get("sq", 2.6)
            x = math.copysign(abs(ca) ** e, ca) * r["rx"]
            y = math.copysign(abs(sa) ** e, sa) * r["ry"]
            row.append(bm.verts.new(Vector(r["c"]) + Vector((x, y, 0))))
        grid.append(row)
    for i in range(len(grid) - 1):
        for k in range(segs):
            bm.faces.new((grid[i][k], grid[i][k + 1], grid[i + 1][k + 1], grid[i + 1][k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = G.new_obj(name, me)
    if thick:
        m = o.modifiers.new("Grosor", "SOLIDIFY")
        m.thickness = thick
        G.apply_mods(o)
    return o


def boots(K, upper, sole, shaft=None, strap=None, chunky=1.0, name="Bota"):
    """Botas/zapatillas gruesas: el pie (sobre Foot) y, si shaft, la caña (sobre LowerLeg)."""
    mu = K.mat("bota_" + name, G.mat_leather, lin(upper), 0.5)
    ms = K.mat("suela_" + name, G.mat_plain, lin(sole), 0.6)
    for side, sx in (("R", 1), ("L", -1)):
        foot = "RightFoot" if sx > 0 else "LeftFoot"
        leg = "RightLowerLeg" if sx > 0 else "LeftLowerLeg"
        x = sx * 0.5
        prof = [(-0.56, 0.5, 0.28), (-0.5, 0.56, 0.38), (0.1, 0.57, 0.36), (0.4, 0.55, 0.26), (0.58, 0.48, 0.2), (0.66, 0.36, 0.16)]
        rings = [{"c": Vector((x, y, 0.06 + h * 0.5 * chunky)), "rx": rx * chunky, "ry": h * 0.5 * chunky, "sq": 3.2} for y, rx, h in prof]
        top = G.loft(f"{name}Pie{side}", rings, segs=14)
        G.assign(top, mu)
        so = G.loft(f"{name}Suela{side}", [{"c": Vector((x, y, 0.02)), "rx": rx * chunky + 0.04, "ry": 0.09, "sq": 4.0} for y, rx, h in prof], segs=14)
        G.assign(so, ms)
        parts = [top, so]
        if strap:
            st = G.rbox(f"{name}Correa{side}", (x, 0.15, 0.36 * chunky), (1.1 * chunky, 0.16, 0.1), bevel=0.03, segs=1)
            G.assign(st, K.mat("correa_" + name, G.mat_leather, lin(strap), 0.4))
            parts.append(st)
        K.add(f"{name}{side}", parts, foot, texel=0.7, label="Botas" if shaft else "Zapatos")
        if shaft:
            sh = box_shell(f"{name}Cana{side}", (x, 0.0), (0.56, 0.56), 0.22, 0.62, sq=3.6, segs=16, cap0=False, cap1=False, thick=0.05)
            G.assign(sh, K.mat("cana_" + name, G.mat_leather, lin(shaft), 0.5))
            band = box_shell(f"{name}Banda{side}", (x, 0.0), (0.6, 0.6), 0.5, 0.6, sq=3.6, segs=16, thick=0.04)
            G.assign(band, K.mat("banda_" + name, G.mat_plain, lin((200, 200, 205)), 0.5))
            K.add(f"{name}Cana{side}", [sh, band], leg, texel=0.5, label="Botas")


def sleeves(K, mat, cuff_mat=None, upper=True, lower=True, cuff_z=2.42, grow=0.06, name="Manga", rolled=True):
    """Mangas por piezas (rígidas en el brazo y el antebrazo): la tela con volumen y el puño remangado."""
    for side, sx in (("R", 1), ("L", -1)):
        x = sx * 1.5
        if upper:
            o = box_shell(f"{name}Brazo{side}", (x, 0), (0.5 + grow, 0.5 + grow), 2.86, 3.96, sq=4.0, segs=20, cap1=True, thick=0.04)
            K.add(f"{name}Brazo{side}", o, "RightUpperArm" if sx > 0 else "LeftUpperArm", mat, texel=0.8, label="Mangas")
        if lower:
            parts = [box_shell(f"{name}Ante{side}", (x, 0), (0.48 + grow, 0.48 + grow), cuff_z + 0.08, 3.0, sq=4.0, segs=20, thick=0.04)]
            G.assign(parts[0], mat)
            if rolled:
                pts = []
                n = 16
                for i in range(n):
                    a = 2 * math.pi * i / n
                    ca, sa = math.cos(a), math.sin(a)
                    e = 2 / 4.0
                    pts.append(Vector((x + math.copysign(abs(ca) ** e, ca) * (0.56 + grow), math.copysign(abs(sa) ** e, sa) * (0.56 + grow), cuff_z + 0.06)))
                ring = G.loft(f"{name}Puno{side}", G.path_rings(pts, [0.075] * n), segs=6, closed_path=True)
                G.assign(ring, cuff_mat or mat)
                parts.append(ring)
            K.add(f"{name}Ante{side}", parts, "RightLowerArm" if sx > 0 else "LeftLowerArm", texel=0.8, label="Mangas")


def torso_shell(K, mat, name, z0=2.32, z1=4.0, grow=0.07, open_low=0.0, open_top=0.0, lapel_mat=None, collar=True, segs=28):
    """Chaqueta/bata/rebeca: funda del tronco (UpperTorso) algo mayor, abierta delante (pico)."""
    hx, hy = 1.0 + grow, 0.5 + grow
    zs = [z0, 2.7, 3.1, 3.5, 3.85, z1, z1 + 0.05]
    ks = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.55]

    def half(i):
        z = (zs[i] + zs[min(i + 1, len(zs) - 1)]) / 2
        t = max(0.0, min(1.0, (z - 2.6) / (z1 - 2.6)))
        return open_low + (open_top - open_low) * t

    rings = [{"c": Vector((0, 0, z)), "rx": hx * k, "ry": hy * (k if k > 0.9 else 0.75), "sq": 4.2} for z, k in zip(zs, ks)]
    o = G.loft(name, rings, segs=segs, cap0=False, cap1=False, gap=((0, 1, 0), 0.3, half) if (open_low or open_top) else None)
    m = o.modifiers.new("Grosor", "SOLIDIFY")
    m.thickness = 0.05
    m.offset = 1.0
    G.apply_mods(o)
    G.assign(o, mat)
    parts = [o]
    if lapel_mat is not None and open_top > 0:
        for sx in (-1, 1):
            lr = []
            for z in (2.75, 3.15, 3.55, 3.85, 3.98):
                a = half(max(j for j, zz in enumerate(zs) if zz <= z)) + 0.02
                e = 2 / 4.2
                ex = Vector((sx * hx * abs(math.sin(a)) ** e, hy * abs(math.cos(a)) ** e, z))
                wdt = 0.04 + 0.16 * max(0.0, min(1.0, (z - 2.75) / 0.6))
                lr.append({"c": ex + Vector((sx * wdt, 0.045, 0)), "rx": wdt, "ry": 0.018, "sq": 2.2, "u": Vector((sx, 0.05, 0))})
            lap = G.loft(f"{name}Solapa{sx}", lr, segs=6)
            G.assign(lap, lapel_mat)
            parts.append(lap)
    if collar:
        col = G.loft(f"{name}Cuello", [{"c": Vector((0, -0.04, z1 - 0.02)), "rx": 0.55, "ry": 0.45, "sq": 3.0}, {"c": Vector((0, -0.07, z1 + 0.2)), "rx": 0.5, "ry": 0.42, "sq": 3.0}],
                     segs=20, cap0=False, cap1=False, gap=((0, 1, 0), 1.2))
        mm = col.modifiers.new("Grosor", "SOLIDIFY")
        mm.thickness = 0.05
        G.apply_mods(col)
        G.assign(col, lapel_mat or mat)
        parts.append(col)
    return parts


def coat_tails(K, mat, name, z_top=2.42, z_bot=1.0, flare=0.14, gap_deg=14, label="Faldón"):
    """Faldón largo por mitades (cada una en su pierna, con abertura detrás): bata, abrigo, frac."""
    for side, sx in (("R", 1), ("L", -1)):
        rings = []
        for z, k in ((z_top, 0.0), ((z_top + z_bot) / 2, 0.55), (z_bot, 1.0)):
            rings.append({"c": Vector((0, -0.02, z)), "rx": 1.08 + flare * k, "ry": 0.6 + flare * k, "sq": 3.4})
        if sx > 0:
            a0, a1 = -90 + 2, 90 - gap_deg
        else:
            a0, a1 = 90 + gap_deg, 270 - 2
        o = arc_shell(f"{name}{side}", rings, a0, a1, segs=12, thick=0.05)
        K.add(f"{name}{side}", o, "RightUpperLeg" if sx > 0 else "LeftUpperLeg", mat, lod=True, texel=1.0, label=label)


def belt(K, color, buckle=(200, 200, 205), z=2.3, name="Cinturon"):
    o = box_shell(name, (0, 0), (1.04, 0.54), z - 0.08, z + 0.08, sq=4.2, segs=24, thick=0.04)
    G.assign(o, K.mat("cinturon", G.mat_leather, lin(color), 0.45))
    b = G.rbox(name + "Hebilla", (0, 0.6, z), (0.32, 0.06, 0.2), bevel=0.03, segs=1)
    G.assign(b, K.mat("hebilla", G.mat_metal, lin(buckle), 0.3))
    hole = G.rbox(name + "Hueco", (0, 0.635, z), (0.18, 0.03, 0.08), bevel=0.01, segs=1)
    G.assign(hole, K.mat("cinturon", G.mat_leather, lin(color), 0.45))
    K.add(name, [o, b, hole], "LowerTorso", texel=0.5, label="Cinturón")


# ====================================================================== pelos (sobre una cabeza de bloque)
def hair_mat(K, color, scale=1.0):
    return K.mat("pelo", G.mat_hair, lin(color), "Z", scale)


def hair_base(name, top=0.25, back=-0.62, side=-0.1, front=0.38, grow=0.09, lift=0.0, max_z=None):
    """Casquete de pelo sobre el cubo de la cabeza: un cubo redondeado algo mayor, recortado por la línea
    del pelo (front/side/back: alturas relativas al centro de la cabeza, en medias cabezas)."""
    c, s = PARTS["Head"]
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=6, use_grid_fill=True)
    # redondear: cada vértice a una superelipse
    hx, hy, hz = 0.63 + grow, 0.61 + grow, 0.61 + grow
    for v in bm.verts:
        p = Vector(v.co) * 2
        n = (abs(p.x) ** 6 + abs(p.y) ** 6 + abs(p.z) ** 6) ** (1 / 6)
        p = p / max(n, 1e-6)
        v.co = Vector((p.x * hx, p.y * hy, p.z * hz + lift * max(0.0, p.z)))
    unit = {v: Vector((v.co.x / hx, v.co.y / hy, v.co.z / hz)) for v in bm.verts}

    def keep(u):
        t = (u.y + 1) / 2
        lim = back + (front - back) * (t ** 1.4)
        if abs(u.x) > 0.75 and -0.4 < u.y < 0.5:
            lim = max(lim, side)
        if max_z is not None and u.z > max_z:
            return False
        return u.z > lim

    kill = [f for f in bm.faces if not all(keep(unit[v]) for v in f.verts)]
    bmesh.ops.delete(bm, geom=kill, context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    for v in bm.verts:
        v.co = v.co + Vector(c)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = G.new_obj(name, me)
    m = o.modifiers.new("Grosor", "SOLIDIFY")
    m.thickness = 0.05
    G.apply_mods(o)
    return o


def head_point(theta_deg, phi_deg, k=1.0):
    """Punto sobre la «cabeza» (esfera que envuelve el cubo) y su normal: theta alrededor desde el frente
    (+ hacia la derecha del personaje), phi desde arriba."""
    th, ph = math.radians(theta_deg), math.radians(phi_deg)
    n = Vector((math.sin(ph) * math.sin(th), math.sin(ph) * math.cos(th), math.cos(ph)))
    p = HEAD_C + Vector((n.x * 0.66, n.y * 0.64, n.z * 0.66)) * k
    return p, n


def _lock(name, root, direction, length, width, thick, normal, bend, n, segs, tip, twist=0.0):
    root = Vector(root)
    dv = Vector(direction).normalized()
    nv = Vector(normal).normalized()
    pts = [root + dv * (length * t) + nv * (bend * length * t * t) for t in [i / (n - 1) for i in range(n)]]
    rings = []
    for i, p in enumerate(pts):
        t = i / (n - 1)
        tang = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        side = tang.cross(nv).normalized()
        if twist:
            side = (Matrix.Rotation(twist * t, 3, tang) @ side).normalized()
        wt = width * (1 - (1 - tip) * t ** 1.2)
        th = thick * (1 - 0.6 * t)
        rings.append({"c": p, "rx": wt, "ry": th, "sq": 2.3, "u": side})
    return G.loft(name, rings, segs=segs)


def lock(name, root, direction, length, width, thick, normal, bend=0.0, n=5, segs=6, tip=0.1, twist=0.0):
    return _lock(name, root, direction, length, width, thick, normal, bend, n, segs, tip, twist)


# ====================================================================== COSME
def kit_cosme(K):
    s = K.s
    head_block(K, s["Skin"])
    # --- pelo: una mata enorme y esponjosa de mechones anchos y curvados (plateado con un toque frío):
    # arriba, atrás y a los lados, con la frente libre para las gafas
    hm = K.mat("pelo", G.mat_hair, lin(s["Hair"]), "Z", 1.3, 0.45)
    base = hair_base("PeloBase", back=-0.82, side=-0.45, front=0.6, grow=0.16, lift=0.28)
    G.assign(base, hm)
    parts = [base]
    r = random.Random(21)
    k = 0
    up = Vector((0, 0, 1))
    for phi, n, ln, w in ((6, 3, 1.05, 0.46), (28, 7, 1.12, 0.46), (52, 9, 1.08, 0.44), (76, 9, 0.95, 0.42), (100, 8, 0.78, 0.4), (124, 6, 0.55, 0.36)):
        for i in range(n):
            th = 360 * (i + 0.5 * (phi // 20 % 2)) / n + r.uniform(-10, 10)
            fr = math.cos(math.radians(th))
            if phi >= 28 and fr > 0.5:
                continue  # la frente libre (gafas y cara)
            if phi >= 76 and fr > 0.05:
                continue
            p, nrm = head_point(th, phi + r.uniform(-5, 5), 1.02)
            d = (nrm * 0.75 + up * (0.55 if phi < 70 else 0.1) + Vector((0, -0.28, 0))).normalized()
            L = ln * r.uniform(0.85, 1.12)
            flat = up.cross(d).cross(d).normalized() if abs(d.z) < 0.95 else Vector((0, -1, 0))
            o = lock(f"Mechon{k}", p - d * 0.22, d, L + 0.22, w * r.uniform(0.88, 1.1), 0.17, flat, bend=0.22, n=4, segs=6, tip=0.12, twist=r.uniform(-0.5, 0.5))
            G.assign(o, hm)
            parts.append(o)
            k += 1
    # tupé alocado delante (hacia arriba y algo hacia delante, por encima de las gafas)
    for j, th in enumerate((-28, 0, 26)):
        p, nrm = head_point(th, 24, 1.02)
        d = (Vector((math.sin(math.radians(th)) * 0.4, 0.35, 1.0))).normalized()
        o = lock(f"Tupe{j}", p - d * 0.15, d, 0.72, 0.36, 0.14, Vector((0, 1, 0)), bend=0.25, n=4, segs=6, tip=0.12, twist=0.3 * (j - 1))
        G.assign(o, hm)
        parts.append(o)
    # mechones que caen junto a la cara (tapan las orejas)
    for sx in (-1, 1):
        for j, (ph, ln) in enumerate(((70, 0.62), (96, 0.5))):
            p, nrm = head_point(sx * 76, ph, 1.04)
            d = (Vector((sx * 0.6, 0.1, -0.75))).normalized()
            o = lock(f"Patilla{sx}{j}", p, d, ln, 0.3, 0.12, Vector((sx, 0, 0)), bend=0.15, n=4, segs=6, tip=0.15)
            G.assign(o, hm)
            parts.append(o)
    K.add("Pelo", parts, "Head", lod=True, texel=1.6, label="Pelo de científico")
    # --- gafas de laboratorio en la frente: montura gris oscura, cinta, cristales cian que brillan
    metal = K.mat("gafas_metal", G.mat_metal, lin((52, 56, 62)), 0.35)
    strap = K.mat("gafas_cinta", G.mat_leather, lin((28, 28, 32)), 0.5)
    zc = HEAD_C.z + 0.56
    pts = []
    n = 18
    for i in range(n):
        a = math.radians(-58 - (360 - 116) * i / (n - 1))
        x, y = math.sin(a), math.cos(a)
        e = 2 / 4.0
        pts.append(Vector((math.copysign(abs(x) ** e, x) * 0.7, math.copysign(abs(y) ** e, y) * 0.68, zc + 0.04 * max(0.0, -y))))
    band = G.loft("GafasCinta", G.path_rings(pts, [(0.05, 0.1)] * n, sq=3.0), segs=6)
    G.assign(band, strap)
    gparts = [band]
    tilt = Matrix.Rotation(math.radians(-28), 3, "X")
    axis = tilt @ Vector((0, 1, 0))
    lenses = []
    for sx in (-1, 1):
        c = Vector((sx * 0.3, 0.62, zc + 0.02))
        cup = G.loft(f"Copa{sx}", [{"c": c - axis * 0.05, "rx": 0.26, "ry": 0.24, "sq": 2.4}, {"c": c + axis * 0.16, "rx": 0.25, "ry": 0.23, "sq": 2.4},
                                   {"c": c + axis * 0.2, "rx": 0.21, "ry": 0.19, "sq": 2.4}], segs=16, cap0=True, cap1=False, ref=Vector((1, 0, 0)))
        G.assign(cup, metal)
        rim = G.loft(f"Aro{sx}", [{"c": c + axis * 0.17, "rx": 0.27, "ry": 0.25, "sq": 2.4}, {"c": c + axis * 0.23, "rx": 0.26, "ry": 0.24, "sq": 2.4}], segs=16, cap0=False, cap1=False, ref=Vector((1, 0, 0)))
        G.assign(rim, metal)
        gparts += [cup, rim]
        lens = G.blob(f"Lente{sx}", (0, 0, 0), (0.2, 0.05, 0.18), segs=12, rings=6)
        lens.location = c + axis * 0.19
        lens.rotation_euler = tilt.to_euler()
        lenses.append(lens)
    bridge = G.rbox("PuenteGafas", (0, 0.66, zc + 0.04), (0.2, 0.1, 0.1), bevel=0.03, segs=1)
    G.assign(bridge, metal)
    gparts.append(bridge)
    K.add("Gafas", gparts, "Head", texel=0.8, label="Gafas")
    K.glow("GafasCristal", lenses, "Head", lin((40, 235, 220)), label="Gafas")
    # --- bata blanca gastada: tronco con solapas y cuello, mangas remangadas y faldón hasta la rodilla
    coat = K.mat("bata", G.mat_cloth, lin(s["Coat"]), "canvas", 1.0, dirt=0.5, folds=0.8)
    cparts = torso_shell(K, coat, "Bata", open_low=0.42, open_top=0.62, lapel_mat=coat)
    K.add("Bata", cparts, "UpperTorso", lod=True, texel=1.0, label="Bata de laboratorio")
    sleeves(K, coat, coat, cuff_z=2.42, grow=0.06, name="Manga")
    coat_tails(K, coat, "Faldon", z_top=2.4, z_bot=0.95, flare=0.16, label="Bata de laboratorio")
    # bolsillo del pecho con bolígrafos gordos (verde, turquesa y morado: el toque de Cosme)
    pk = G.rbox("BolsilloPecho", (-0.55, 0.6, 3.35), (0.42, 0.08, 0.36), bevel=0.03, segs=1)
    G.assign(pk, coat)
    pens = [pk]
    for i, (col, dx) in enumerate((((40, 170, 80), -0.14), ((30, 170, 170), 0.0), ((130, 70, 190), 0.14))):
        pen = G.cyl(f"Boli{i}", (-0.55 + dx, 0.6, 3.38), (-0.55 + dx, 0.6, 3.68), 0.055, segs=8)
        G.assign(pen, K.mat(f"boli{i}", G.mat_plain, lin(col), 0.35))
        clip = G.rbox(f"Clip{i}", (-0.55 + dx, 0.66, 3.6), (0.03, 0.03, 0.12), bevel=0.01, segs=1)
        G.assign(clip, K.mat("clip", G.mat_metal, (0.8, 0.8, 0.8), 0.3))
        pens += [pen, clip]
    K.add("Bolis", pens, "UpperTorso", texel=0.4, label="Bata de laboratorio")
    # --- colgante que brilla (cordón y escudo azul)
    cord = K.mat("cordon", G.mat_plain, (0.04, 0.04, 0.05), 0.6)
    pts = [Vector((-0.32, 0.4, 3.98)), Vector((-0.2, 0.53, 3.6)), Vector((0, 0.54, 3.38)), Vector((0.2, 0.53, 3.6)), Vector((0.32, 0.4, 3.98))]
    c = G.loft("Cordon", G.path_rings(pts, [0.025] * 5), segs=6)
    G.assign(c, cord)
    frame = G.rbox("MarcoColgante", (0, 0.56, 3.3), (0.22, 0.06, 0.28), bevel=0.04, segs=2)
    G.assign(frame, K.mat("gafas_metal", G.mat_metal, lin((52, 56, 62)), 0.35))
    K.add("Colgante", [c, frame], "UpperTorso", texel=0.3, label="Colgante")
    gem = G.rbox("Gema", (0, 0.6, 3.3), (0.14, 0.04, 0.19), bevel=0.04, segs=2)
    K.glow("ColganteLuz", gem, "UpperTorso", lin((60, 160, 255)), label="Colgante")
    # --- cinturón y botas
    belt(K, (70, 48, 30), (190, 192, 196), z=2.28)
    boots(K, (36, 36, 40), (225, 225, 230), shaft=(46, 46, 52), strap=(120, 120, 126), chunky=1.05, name="Bota")
    # --- mochila de inventor: caja de metal oscura con circuitos verdes y pantalla cian
    dark = K.mat("mochila", G.mat_metal, lin((40, 46, 44)), 0.45)
    bag = G.rbox("MochilaCaja", (0, -0.98, 3.2), (1.5, 0.75, 1.55), bevel=0.1, segs=2)
    G.assign(bag, dark)
    frame2 = G.rbox("MochilaMarco", (0, -1.37, 3.2), (1.3, 0.08, 1.35), bevel=0.04, segs=1)
    G.assign(frame2, K.mat("mochila_panel", G.mat_metal, lin((26, 30, 30)), 0.4))
    bp = [bag, frame2]
    for sx in (-1, 1):
        st = G.loft(f"Correa{sx}", G.path_rings([(sx * 0.55, -0.62, 3.95), (sx * 0.55, -0.05, 4.08), (sx * 0.58, 0.55, 3.85), (sx * 0.6, 0.56, 3.0)], [(0.12, 0.035)] * 4, sq=3.0), segs=6)
        G.assign(st, K.mat("correa", G.mat_leather, lin((30, 30, 34)), 0.5))
        bp.append(st)
        for z in (2.7, 3.7):
            bolt = G.rbox(f"Tornillo{sx}{z}", (sx * 0.62, -1.42, z), (0.1, 0.05, 0.1), bevel=0.02, segs=1)
            G.assign(bolt, K.mat("laton", G.mat_metal, lin((170, 150, 110)), 0.3))
            bp.append(bolt)
    K.add("Mochila", bp, "UpperTorso", lod=True, texel=1.0, label="Mochila inventora")
    lights = [G.rbox("PantallaMochila", (0, -1.43, 3.25), (0.46, 0.04, 0.6), bevel=0.02, segs=1)]
    for sx in (-1, 1):
        lights.append(G.rbox(f"Circuito{sx}", (sx * 0.42, -1.42, 3.2), (0.07, 0.04, 0.95), bevel=0.02, segs=1))
        lights.append(G.rbox(f"CircuitoH{sx}", (sx * 0.3, -1.42, 3.62), (0.3, 0.04, 0.06), bevel=0.02, segs=1))
    K.glow("MochilaLuz", lights, "UpperTorso", lin((90, 255, 120)), label="Mochila inventora")
    # --- aparato de muñeca (antebrazo izquierdo) con pantalla azul
    dev = G.rbox("AparatoCaja", (-1.5, 0.05, 2.62), (1.24, 1.2, 0.5), bevel=0.06, segs=2)
    G.assign(dev, K.mat("aparato", G.mat_metal, lin((60, 66, 74)), 0.35))
    dev2 = G.rbox("AparatoTapa", (-1.5, 0.66, 2.64), (0.86, 0.12, 0.42), bevel=0.04, segs=1)
    G.assign(dev2, K.mat("aparato_osc", G.mat_metal, lin((24, 26, 30)), 0.35))
    K.add("Aparato", [dev, dev2], "LeftLowerArm", texel=0.6, label="Aparato de muñeca")
    scr = G.rbox("AparatoPantalla", (-1.5, 0.73, 2.64), (0.66, 0.04, 0.3), bevel=0.02, segs=1)
    K.glow("AparatoLuz", scr, "LeftLowerArm", lin((70, 170, 255)), label="Aparato de muñeca")
    # --- pistola de inventor en la mano derecha: empuñadura, cuerpo, depósito verde, antena y anillo morado
    h = Vector(PARTS["RightHand"][0]) + Vector((0, 0.0, -0.05))
    gun_m = K.mat("pistola", G.mat_metal, lin((44, 48, 52)), 0.35)
    grip = G.rbox("Empunadura", h + Vector((0, -0.05, 0.0)), (0.3, 0.32, 0.5), bevel=0.06, segs=2)
    G.assign(grip, gun_m)
    body = G.rbox("Cuerpo", h + Vector((0, 0.42, -0.2)), (0.42, 1.0, 0.42), bevel=0.08, segs=2)
    G.assign(body, gun_m)
    nozzle = G.loft("Boquilla", [{"c": h + Vector((0, 0.9, -0.2)), "rx": 0.2, "ry": 0.2}, {"c": h + Vector((0, 1.12, -0.2)), "rx": 0.25, "ry": 0.25},
                                  {"c": h + Vector((0, 1.18, -0.2)), "rx": 0.2, "ry": 0.2}], segs=12, ref=Vector((1, 0, 0)))
    G.assign(nozzle, gun_m)
    ring = G.torus("AnilloMorado", h + Vector((0, 0.92, -0.2)), (0, 1, 0), 0.24, 0.05, segs=14, tsegs=6)
    G.assign(ring, K.mat("morado", G.mat_plain, lin((140, 70, 210)), 0.35))
    ant = G.cyl("Antena", h + Vector((0, 0.15, 0.0)), h + Vector((0, 0.15, 0.45)), 0.035, segs=6)
    G.assign(ant, gun_m)
    K.add("Pistola", [grip, body, nozzle, ring, ant], "RightHand", texel=0.6, label="Pistola de inventor")
    tank = G.loft("Deposito", [{"c": h + Vector((0, 0.15, 0.06)), "rx": 0.17, "ry": 0.17}, {"c": h + Vector((0, 0.75, 0.06)), "rx": 0.17, "ry": 0.17}], segs=12, ref=Vector((1, 0, 0)))
    ball = G.blob("BolaAntena", h + Vector((0, 0.15, 0.5)), (0.08, 0.08, 0.08), segs=10, rings=6)
    K.glow("PistolaLuz", [tank, ball], "RightHand", lin((90, 255, 110)), label="Pistola de inventor")


# ====================================================================== LA FAMILIA (del jugador) Y LOS DEMÁS
def kit_mama(K):
    """Mamá: moño alto castaño con mechones, rebeca rosa sobre delantal, taza «La mejor mamá»."""
    s = K.s
    head_block(K, s["Skin"])
    hm = hair_mat(K, s["Hair"])
    base = hair_base("PeloBase", back=-0.55, side=-0.15, front=0.45, grow=0.07, lift=0.05)
    G.assign(base, hm)
    bun = G.blob("Mono", HEAD_C + Vector((0, -0.15, 0.85)), (0.36, 0.34, 0.3), segs=18, rings=12, deform=lambda p: Vector((p.x, p.y, p.z * (1 + 0.1 * math.sin(p.x * 8 + p.y * 5)))))
    G.assign(bun, hm)
    parts = [base, bun]
    # mechones sueltos a los lados y flequillo de lado
    for sx in (-1, 1):
        p, n = head_point(sx * 62, 72, 1.04)
        o = lock(f"Mechon{sx}", p, Vector((sx * 0.15, 0.2, -1)), 0.62, 0.13, 0.05, Vector((sx, 0, 0)), bend=0.12, n=5, segs=6, tip=0.3, twist=sx * 0.5)
        G.assign(o, hm)
        parts.append(o)
    for i in range(4):
        p, n = head_point(-32 + i * 15, 38, 1.05)
        o = lock(f"Flequillo{i}", p, Vector((0.7, 0.35, -0.6)), 0.4 - i * 0.03, 0.15, 0.05, n, bend=0.15, n=4, segs=6, tip=0.35)
        G.assign(o, hm)
        parts.append(o)
    K.add("Pelo", parts, "Head", lod=True, texel=1.4, label="Moño")
    knit = K.mat("rebeca", G.mat_cloth, lin(s["Coat"]), "knit", 1.0)
    cparts = torso_shell(K, knit, "Rebeca", open_low=0.55, open_top=0.7, lapel_mat=None, collar=False)
    K.add("Rebeca", cparts, "UpperTorso", texel=1.0, label="Rebeca rosa")
    sleeves(K, knit, knit, cuff_z=2.36, grow=0.05, name="Manga", rolled=True)
    apron = K.mat("delantal", G.mat_cloth, lin((236, 226, 206)), "canvas", 1.0)
    ap = G.loft("Delantal", [{"c": Vector((0, 0.56, z)), "rx": w, "ry": 0.03, "u": Vector((1, 0, 0)), "sq": 4.0} for z, w in ((2.42, 0.62), (2.0, 0.66), (1.3, 0.7))], segs=8)
    G.assign(ap, apron)
    tie = box_shell("CintaDelantal", (0, 0), (1.04, 0.54), 2.32, 2.42, sq=4.2, segs=24, thick=0.03)
    G.assign(tie, apron)
    K.add("Delantal", [ap, tie], "LowerTorso", texel=0.7, label="Delantal")
    # taza «La mejor mamá» (en la mano derecha; el texto va en la vista previa y en la textura)
    h = Vector(PARTS["RightHand"][0])
    mug = G.cyl("Taza", h + Vector((0, 0.52, -0.25)), h + Vector((0, 0.52, 0.2)), 0.22, segs=16)
    handle = G.torus("Asa", h + Vector((0, 0.24, -0.02)), (1, 0, 0), 0.12, 0.035, segs=12, tsegs=5)
    G.assign(mug, K.mat("taza", G.mat_plain, (0.95, 0.94, 0.92), 0.3))
    G.assign(handle, K.mat("taza", G.mat_plain, (0.95, 0.94, 0.92), 0.3))
    heart = G.blob("Corazon", h + Vector((0, 0.74, -0.05)), (0.08, 0.02, 0.07), segs=10, rings=6)
    G.assign(heart, K.mat("rojo", G.mat_plain, lin((210, 50, 70)), 0.4))
    K.add("Taza", [mug, handle, heart], "RightHand", texel=0.5, label="Taza «La mejor mamá»")
    boots(K, (230, 150, 170), (245, 245, 245), name="Zapatilla")


def kit_papa(K):
    """Papá: pelo castaño oscuro peinado hacia atrás con raya, barba de tres días (cara), gafas de sol,
    chaqueta negra sobre camiseta blanca, reloj."""
    s = K.s
    head_block(K, s["Skin"])
    hm = hair_mat(K, s["Hair"])
    base = hair_base("PeloBase", back=-0.5, side=0.05, front=0.5, grow=0.1, lift=0.18)
    G.assign(base, hm)
    parts = [base]
    for i in range(7):
        p, n = head_point(-45 + i * 15, 28, 1.1)
        o = lock(f"Onda{i}", p + Vector((0, 0.08, 0.05)), Vector((0.2, -0.7, 0.55)), 0.7, 0.22, 0.1, n, bend=-0.25, n=5, segs=6, tip=0.45)
        G.assign(o, hm)
        parts.append(o)
    K.add("Pelo", parts, "Head", lod=True, texel=1.3, label="Pelo peinado")
    frame = K.mat("gafas_sol", G.mat_plain, (0.03, 0.03, 0.035), 0.25)
    lens_m = K.mat("cristal_sol", G.mat_plain, (0.05, 0.06, 0.08), 0.08)
    gp = []
    for sx in (-1, 1):
        l = G.rbox(f"LenteSol{sx}", (sx * 0.27, 0.66, 4.63), (0.42, 0.06, 0.32), bevel=0.07, segs=2)
        G.assign(l, lens_m)
        f = G.loft(f"MonturaSol{sx}", [{"c": Vector((sx * 0.27, 0.66, 4.63)), "rx": 0.23, "ry": 0.18, "sq": 3.0, "u": Vector((1, 0, 0))}, {"c": Vector((sx * 0.27, 0.69, 4.63)), "rx": 0.23, "ry": 0.18, "sq": 3.0, "u": Vector((1, 0, 0))}], segs=14, cap0=False, cap1=False)
        G.assign(f, frame)
        t = G.rbox(f"Patilla{sx}", (sx * 0.64, 0.15, 4.72), (0.05, 1.0, 0.06), bevel=0.02, segs=1)
        G.assign(t, frame)
        gp += [l, f, t]
    br = G.rbox("PuenteSol", (0, 0.68, 4.7), (0.16, 0.05, 0.05), bevel=0.02, segs=1)
    G.assign(br, frame)
    K.add("GafasSol", gp + [br], "Head", texel=0.5, label="Gafas de sol")
    jacket = K.mat("chaqueta", G.mat_leather, lin(s["Coat"]), 0.5)
    cparts = torso_shell(K, jacket, "Chaqueta", open_low=0.5, open_top=0.55, lapel_mat=jacket, collar=True)
    K.add("Chaqueta", cparts, "UpperTorso", texel=1.0, label="Chaqueta negra")
    sleeves(K, jacket, jacket, cuff_z=2.4, grow=0.06, name="Manga", rolled=False)
    watch = box_shell("Reloj", (-1.5, 0), (0.54, 0.54), 2.36, 2.48, sq=4.0, segs=16, thick=0.04)
    G.assign(watch, K.mat("reloj", G.mat_metal, lin((170, 172, 178)), 0.25))
    face = G.rbox("Esfera", (-1.5, 0.6, 2.42), (0.22, 0.05, 0.2), bevel=0.03, segs=1)
    G.assign(face, K.mat("esfera", G.mat_plain, (0.1, 0.12, 0.16), 0.2))
    K.add("Reloj", [watch, face], "LeftLowerArm", texel=0.3, label="Reloj")
    boots(K, (240, 240, 240), (60, 60, 64), name="Zapatilla")


def A_PART(name):
    return PARTS[name][0]


def kit_abu_rosa(K):
    """Abuela: moño de rizos blanco, gafas redondas, rebeca lila de punto, collar de perlas, bolso."""
    s = K.s
    head_block(K, s["Skin"])
    hm = hair_mat(K, s["Hair"], 2.0)
    base = hair_base("PeloBase", back=-0.5, side=-0.05, front=0.45, grow=0.09, lift=0.08)
    G.assign(base, hm)
    parts = [base]
    r = random.Random(8)
    for i in range(16):  # rizos
        th = r.uniform(-180, 180)
        ph = r.uniform(15, 85)
        if math.cos(math.radians(th)) > 0.5 and ph > 40:
            continue
        p, n = head_point(th, ph, 1.08)
        b = G.blob(f"Rizo{i}", p, (0.17, 0.17, 0.15), segs=10, rings=7)
        G.assign(b, hm)
        parts.append(b)
    bun = G.blob("Mono", HEAD_C + Vector((0, -0.35, 0.75)), (0.34, 0.3, 0.3), segs=14, rings=9, deform=lambda p: Vector((p.x, p.y, p.z)) * (1 + 0.12 * math.sin(p.x * 10) * math.cos(p.z * 9)))
    G.assign(bun, hm)
    parts.append(bun)
    K.add("Pelo", parts, "Head", lod=True, texel=1.3, label="Moño de rizos")
    rim = K.mat("montura", G.mat_metal, lin((150, 115, 70)), 0.3)
    gp = []
    for sx in (-1, 1):
        o = G.torus(f"Lente{sx}", (sx * 0.24, 0.66, 4.62), (0, 1, 0), 0.19, 0.025, segs=20, tsegs=6)
        G.assign(o, rim)
        t = G.rbox(f"Patilla{sx}", (sx * 0.64, 0.15, 4.72), (0.04, 1.0, 0.04), bevel=0.015, segs=1)
        G.assign(t, rim)
        gp += [o, t]
    br = G.rbox("Puente", (0, 0.67, 4.66), (0.12, 0.04, 0.04), bevel=0.015, segs=1)
    G.assign(br, rim)
    K.add("Gafas", gp + [br], "Head", texel=0.3, label="Gafas redondas")
    knit = K.mat("rebeca", G.mat_cloth, lin(s["Coat"]), "knit", 1.0)
    cparts = torso_shell(K, knit, "Rebeca", open_low=0.25, open_top=0.6, collar=False)
    K.add("Rebeca", cparts, "UpperTorso", texel=1.0, label="Rebeca lila")
    sleeves(K, knit, knit, cuff_z=2.35, grow=0.06, name="Manga", rolled=True)
    pearl = K.mat("perla", G.mat_plain, (0.92, 0.9, 0.86), 0.2)
    beads = []
    for i in range(13):
        a = math.radians(-70 + 140 * i / 12)
        p = Vector((math.sin(a) * 0.36, 0.5 + math.cos(a) * 0.05, 3.95 - math.cos(a) * 0.32))
        b = G.blob(f"Perla{i}", p, (0.055, 0.055, 0.055), segs=8, rings=6)
        G.assign(b, pearl)
        beads.append(b)
    K.add("Collar", beads, "UpperTorso", texel=0.2, label="Collar de perlas")
    # bolso de mano (en vez de bastón: un palo largo y redondo, solo y gris, es justo lo que la revisión de
    # moderación no quiere; docs/bugs/moderacion/)
    h = Vector(A_PART("RightHand"))
    bag = G.rbox("Bolso", h + Vector((0.0, 0.1, -0.55)), (0.3, 0.75, 0.6), bevel=0.1, segs=2)
    G.assign(bag, K.mat("bolso", G.mat_leather, lin((120, 60, 90)), 0.4))
    clasp = G.rbox("Cierre", h + Vector((0.0, 0.1, -0.24)), (0.34, 0.5, 0.06), bevel=0.02, segs=1)
    G.assign(clasp, K.mat("cierre", G.mat_metal, lin((200, 170, 90)), 0.3))
    handle = G.torus("Asa", h + Vector((0.0, 0.1, -0.12)), (1, 0, 0), 0.2, 0.035, segs=14, tsegs=5)
    G.assign(handle, K.mat("bolso", G.mat_leather, lin((120, 60, 90)), 0.4))
    K.add("Bolso", [bag, clasp, handle], "RightHand", texel=0.5, label="Bolso de mano")
    boots(K, (120, 80, 60), (70, 50, 40), name="Zapato")


def kit_abu_tomas(K):
    """Abuelo: gorra plana de tweed, pelo blanco a los lados, bigote blanco, chaleco verde, periódico."""
    s = K.s
    head_block(K, s["Skin"])
    hm = hair_mat(K, s["Hair"])
    base = hair_base("PeloLados", back=-0.6, side=-0.3, front=0.9, grow=0.07, max_z=0.4)
    # solo los lados y la nuca (arriba va la gorra)
    G.assign(base, hm)
    K.add("Pelo", [base], "Head", texel=0.8, label="Pelo blanco")
    tweed = K.mat("gorra", G.mat_cloth, lin((96, 86, 70)), "twill", 1.0)
    cap = G.loft("Gorra", [{"c": HEAD_C + Vector((0, -0.02, z)), "rx": rx, "ry": ry, "sq": 3.2} for z, rx, ry in ((0.3, 0.7, 0.68), (0.5, 0.71, 0.72), (0.66, 0.62, 0.66), (0.72, 0.4, 0.45))], segs=24, cap0=False, cap1=True)
    G.assign(cap, tweed)
    visor = G.loft("Visera", [{"c": HEAD_C + Vector((0, 0.62, 0.36)), "rx": 0.6, "ry": 0.03, "u": Vector((1, 0, 0)), "sq": 2.4},
                              {"c": HEAD_C + Vector((0, 0.86, 0.3)), "rx": 0.5, "ry": 0.025, "u": Vector((1, 0, 0)), "sq": 2.4}], segs=10)
    G.assign(visor, tweed)
    btn = G.blob("BotonGorra", HEAD_C + Vector((0, 0.1, 0.74)), (0.06, 0.06, 0.03), segs=8, rings=5)
    G.assign(btn, tweed)
    K.add("Gorra", [cap, visor, btn], "Head", lod=True, texel=0.9, label="Gorra de tweed")
    mus = K.mat("bigote", G.mat_hair, lin(s["Hair"]), "X")
    mp = []
    for sx in (-1, 1):
        pts = [Vector((sx * 0.02, 0.66, 4.42)), Vector((sx * 0.18, 0.67, 4.4)), Vector((sx * 0.32, 0.65, 4.33))]
        o = G.loft(f"Bigote{sx}", G.path_rings(pts, [(0.09, 0.05), (0.08, 0.05), (0.03, 0.03)], sq=2.2), segs=8)
        G.assign(o, mus)
        mp.append(o)
    K.add("Bigote", mp, "Head", texel=0.4, label="Bigote")
    vest = K.mat("chaleco", G.mat_cloth, lin(s["Coat"]), "knit", 1.0)
    cparts = torso_shell(K, vest, "Chaleco", open_low=0.25, open_top=0.6, collar=False)
    K.add("Chaleco", cparts, "UpperTorso", texel=1.0, label="Chaleco verde")
    # periódico doblado bajo la mano (en vez de bastón: ver Abu Rosa)
    h = Vector(A_PART("LeftHand"))
    paper = G.rbox("Periodico", h + Vector((0.0, 0.25, -0.3)), (0.14, 0.75, 0.95), bevel=0.03, segs=1)
    G.assign(paper, K.mat("periodico", G.mat_cloth, (0.85, 0.84, 0.8), "plain", stripes=((0.35, 0.35, 0.36), "Z", 18.0, 0.12)))
    K.add("Periodico", [paper], "LeftHand", texel=0.5, label="Periódico")
    boots(K, (90, 60, 40), (50, 36, 26), name="Zapato")


def kit_pip(K):
    """Pip, el robot mayordomo de Cosme: cabeza de robot con pantalla (la cara va en la pantalla),
    antena, pajarita, faldón de frac, zapatos de charol y bandeja."""
    s = K.s
    c = HEAD_C
    shell = K.mat("carcasa", G.mat_metal, lin(s["Skin"]), 0.3)
    head = G.rbox("CabezaBloque", c, (1.34, 1.22, 1.24), bevel=0.22, segs=3)
    G.assign(head, shell)
    screen = G.rbox("Pantalla", c + Vector((0, 0.58, 0)), (1.04, 0.08, 0.86), bevel=0.08, segs=2)
    G.assign(screen, K.mat("pantalla", G.mat_plain, (0.02, 0.03, 0.05), 0.12))
    ears = []
    for sx in (-1, 1):
        e = G.loft(f"Oreja{sx}", [{"c": c + Vector((sx * 0.66, 0, 0)), "rx": 0.24, "ry": 0.24, "u": Vector((0, 1, 0))}, {"c": c + Vector((sx * 0.78, 0, 0)), "rx": 0.2, "ry": 0.2, "u": Vector((0, 1, 0))}], segs=14)
        G.assign(e, K.mat("metal_osc", G.mat_metal, lin((70, 76, 86)), 0.35))
        ears.append(e)
    ant = G.cyl("Antena", c + Vector((0, 0, 0.6)), c + Vector((0, 0, 1.0)), 0.035, segs=8)
    G.assign(ant, shell)
    K.add("CabezaBloque", [head, ant] + ears, "Head", texel=1.0, label="Cabeza de robot")
    K.add("Pantalla", screen, "Head", texel=0.4, label="Cabeza de robot")  # (la cara de luz va encima: Decal)
    ball = G.blob("BolaAntena", c + Vector((0, 0, 1.06)), (0.09, 0.09, 0.09), segs=10, rings=6)
    K.glow("AntenaLuz", ball, "Head", lin(s["Glow"]), label="Cabeza de robot")
    satin = K.mat("frac", G.mat_cloth, lin(s["Coat"]), "satin", 1.0)
    cparts = torso_shell(K, satin, "Frac", open_low=0.3, open_top=0.62, lapel_mat=K.mat("solapa", G.mat_cloth, G.shade(lin(s["Coat"]), 0.6), "satin"), collar=True)
    K.add("Frac", cparts, "UpperTorso", texel=1.0, label="Frac")
    sleeves(K, satin, satin, cuff_z=2.4, grow=0.05, name="Manga", rolled=False)
    coat_tails(K, satin, "Faldon", z_top=2.38, z_bot=1.15, flare=0.05, gap_deg=60, label="Frac")
    bow = K.mat("pajarita", G.mat_cloth, (0.05, 0.05, 0.08), "satin")
    bp = []
    for sx in (-1, 1):
        o = G.loft(f"Lazo{sx}", [{"c": Vector((0, 0.56, 3.9)), "rx": 0.06, "ry": 0.06}, {"c": Vector((sx * 0.22, 0.56, 3.9)), "rx": 0.13, "ry": 0.05, "u": Vector((0, 0, 1))}, {"c": Vector((sx * 0.3, 0.56, 3.9)), "rx": 0.11, "ry": 0.05, "u": Vector((0, 0, 1))}], segs=8)
        G.assign(o, bow)
        bp.append(o)
    k = G.blob("Nudo", Vector((0, 0.58, 3.9)), (0.08, 0.06, 0.08), segs=10, rings=6)
    G.assign(k, bow)
    K.add("Pajarita", bp + [k], "UpperTorso", texel=0.3, label="Pajarita")
    h = Vector(PARTS["LeftHand"][0])
    tray = G.loft("Bandeja", [{"c": h + Vector((0, 0.55, -0.16)), "rx": 0.62, "ry": 0.62, "u": Vector((1, 0, 0))}, {"c": h + Vector((0, 0.55, -0.12)), "rx": 0.66, "ry": 0.66, "u": Vector((1, 0, 0))}], segs=20)
    G.assign(tray, K.mat("plata", G.mat_metal, lin((200, 200, 205)), 0.2))
    K.add("Bandeja", tray, "LeftHand", texel=0.4, label="Bandeja")
    boots(K, (20, 20, 24), (20, 20, 24), name="Zapato")


def kit_lucia(K):
    """Profe Lucía: melena larga caoba con raya al lado, gafas finas, rebeca mostaza, acreditación,
    libro bajo el brazo."""
    s = K.s
    head_block(K, s["Skin"])
    hm = hair_mat(K, s["Hair"])
    base = hair_base("PeloBase", back=-0.6, side=-0.2, front=0.48, grow=0.08, lift=0.05)
    G.assign(base, hm)
    mane = G.loft("Melena", [{"c": HEAD_C + Vector((0, -0.08, z)), "rx": rx, "ry": ry, "sq": 3.2} for z, rx, ry in ((0.3, 0.72, 0.7), (-0.2, 0.76, 0.72), (-0.7, 0.8, 0.62), (-1.25, 0.78, 0.45), (-1.4, 0.7, 0.4))],
                  segs=26, cap0=False, cap1=False, gap=((0, 1, 0), 1.35))
    mm = mane.modifiers.new("Grosor", "SOLIDIFY")
    mm.thickness = 0.07
    G.apply_mods(mane)
    G.assign(mane, hm)
    parts = [base, mane]
    for i in range(5):
        p, n = head_point(-40 + i * 13, 40, 1.06)
        o = lock(f"Flequillo{i}", p, Vector((0.65, 0.35, -0.7)), 0.42 - i * 0.03, 0.17, 0.05, n, bend=0.15, n=4, segs=6, tip=0.35)
        G.assign(o, hm)
        parts.append(o)
    K.add("Pelo", parts, "Head", lod=True, texel=1.4, label="Melena larga")
    rim = K.mat("montura", G.mat_plain, lin((40, 30, 36)), 0.3)
    gp = []
    for sx in (-1, 1):
        f = G.loft(f"Montura{sx}", [{"c": Vector((sx * 0.26, 0.64, 4.62)), "rx": 0.2, "ry": 0.15, "sq": 3.4, "u": Vector((1, 0, 0))}, {"c": Vector((sx * 0.26, 0.67, 4.62)), "rx": 0.2, "ry": 0.15, "sq": 3.4, "u": Vector((1, 0, 0))}], segs=14, cap0=False, cap1=False)
        G.assign(f, rim)
        t = G.rbox(f"Patilla{sx}", (sx * 0.64, 0.15, 4.72), (0.04, 1.0, 0.04), bevel=0.015, segs=1)
        G.assign(t, rim)
        gp += [f, t]
    K.add("Gafas", gp, "Head", texel=0.3, label="Gafas")
    knit = K.mat("rebeca", G.mat_cloth, lin(s["Coat"]), "knit", 1.0)
    cparts = torso_shell(K, knit, "Rebeca", open_low=0.4, open_top=0.6, collar=False)
    K.add("Rebeca", cparts, "UpperTorso", texel=1.0, label="Rebeca mostaza")
    sleeves(K, knit, knit, cuff_z=2.35, grow=0.06, name="Manga", rolled=True)
    cord = K.mat("cordon", G.mat_plain, lin((40, 90, 170)), 0.5)
    pts = [Vector((-0.3, 0.4, 3.98)), Vector((-0.18, 0.54, 3.5)), Vector((0, 0.55, 3.15)), Vector((0.18, 0.54, 3.5)), Vector((0.3, 0.4, 3.98))]
    c = G.loft("Cinta", G.path_rings(pts, [0.03] * 5), segs=6)
    G.assign(c, cord)
    card = G.rbox("Tarjeta", (0, 0.58, 3.0), (0.3, 0.04, 0.4), bevel=0.03, segs=1)
    G.assign(card, K.mat("tarjeta", G.mat_plain, (0.93, 0.93, 0.95), 0.3))
    K.add("Acreditacion", [c, card], "UpperTorso", texel=0.3, label="Acreditación del colegio")
    h = Vector(PARTS["LeftHand"][0])
    book = G.rbox("Libro", h + Vector((0.0, 0.5, 0.1)), (0.18, 0.8, 1.0), bevel=0.04, segs=1)
    G.assign(book, K.mat("libro", G.mat_leather, lin((40, 70, 130)), 0.5))
    pages = G.rbox("Hojas", h + Vector((0.0, 0.53, 0.1)), (0.14, 0.76, 0.94), bevel=0.01, segs=1)
    G.assign(pages, K.mat("hojas", G.mat_plain, (0.94, 0.92, 0.86), 0.7))
    K.add("Libro", [book, pages], "LeftHand", texel=0.4, label="Libro")
    boots(K, (60, 36, 30), (40, 26, 22), name="Zapato")


def kit_nico(K):
    """Nico: pelo corto castaño despeinado hacia delante, sudadera deportiva roja, mochila del cole,
    zapatillas, muñequera."""
    s = K.s
    head_block(K, s["Skin"])
    hm = hair_mat(K, s["Hair"])
    base = hair_base("PeloBase", back=-0.5, side=0.0, front=0.4, grow=0.08, lift=0.06)
    G.assign(base, hm)
    parts = [base]
    r = random.Random(5)
    k = 0
    for ph, n in ((14, 4), (34, 8), (55, 9)):
        for i in range(n):
            th = 360 * i / n + r.uniform(-14, 14)
            fr = math.cos(math.radians(th))
            p, nrm = head_point(th, ph, 1.04)
            d = (nrm * 0.5 + (Vector((0, 0.7, 0.35)) if fr > 0.2 else Vector((0, -0.4, 0.35))) + Vector((r.uniform(-0.25, 0.25), 0, 0))).normalized()
            o = lock(f"Mechon{k}", p, d, r.uniform(0.3, 0.42), r.uniform(0.17, 0.22), 0.08, nrm, bend=-0.25, n=4, segs=6, tip=0.15)
            G.assign(o, hm)
            parts.append(o)
            k += 1
    K.add("Pelo", parts, "Head", lod=True, texel=1.3, label="Pelo despeinado")
    red = K.mat("mochila", G.mat_cloth, lin(s["Backpack"]), "canvas", 1.0)
    dk = K.mat("mochila_osc", G.mat_cloth, G.shade(lin(s["Backpack"]), 0.55), "canvas", 1.0)
    bag = G.rbox("MochilaCole", (0, -0.85, 3.15), (1.4, 0.55, 1.4), bevel=0.2, segs=3)
    G.assign(bag, red)
    pocket = G.rbox("BolsilloMochila", (0, -1.14, 2.85), (1.0, 0.16, 0.6), bevel=0.08, segs=2)
    G.assign(pocket, dk)
    bp = [bag, pocket]
    for sx in (-1, 1):
        st = G.loft(f"Asa{sx}", G.path_rings([(sx * 0.55, -0.6, 3.85), (sx * 0.55, -0.05, 4.05), (sx * 0.58, 0.55, 3.85), (sx * 0.6, 0.56, 2.9)], [(0.12, 0.035)] * 4, sq=3.0), segs=6)
        G.assign(st, dk)
        bp.append(st)
    K.add("Mochila", bp, "UpperTorso", lod=True, texel=0.9, label="Mochila del cole")
    band = box_shell("Muneca", (1.5, 0), (0.55, 0.55), 2.32, 2.48, sq=4.0, segs=16, thick=0.05)
    G.assign(band, K.mat("munequera", G.mat_cloth, (0.92, 0.92, 0.9), "knit"))
    K.add("Munequera", band, "RightLowerArm", texel=0.3, label="Muñequera")
    boots(K, (245, 245, 245), (210, 50, 45), strap=(210, 50, 45), name="Zapatilla")
