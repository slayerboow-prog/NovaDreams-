"""Estilo bloque de los OFICIOS (trabajadores con nombre) y de la GENTE DE LA CALLE (encargo del dueño:
docs/personajes/referencia/npcs-dueno.png, solo inspiración). Mismas piezas que bloque_accesorios.py:
cada accesorio es un objeto rígido soldado a una parte del R15 (pelo, gorra, casco, delantal, botas, un
objeto en la mano), nunca una parte del cuerpo; nada largo y redondo (ni cañas, ni porras, ni bastones,
ni bombonas): la revisión de moderación (scripts/audit/moderacion-mallas.py) tiene que dar 0 marcas.

Oficios: los nombres son los que el juego ya usa (CityErrands: Enfermera Carmen, Farmacéutico Julio,
Bombero Nacho, Barista Dani, Pescador Chema, Dependienta Vero, Ejecutivo Borja, Frutero Ramón…) y, si
no había, uno nuevo que no repite a nadie del reparto (no hay otra Lucía).

Gente de la calle (MULTITUD): UNA malla por pieza compartida por todos (cabeza, 10 pelos, gorras,
gafas, bolsos…), SIN textura (se tiñe con el color de la MeshPart: un solo juego de mallas para todos) y
cada persona con su ropa y su cara (plantillas) y como mucho 3 accesorios además de la cabeza.
"""
import math
import random

import bpy  # noqa: F401,I001  (bpy antes que bmesh)
from mathutils import Vector

import bloque_accesorios as A
import p3d_geo as G

HEAD_C = A.HEAD_C
lin = A.lin
WORKER_FACES = ["Neutral", "Happy", "Talk"]


# ====================================================================== piezas reutilizables
def hp(i):
    return Vector(A.PARTS[i][0])


def hair_short(K, hm, seed=5, forward=True, length=0.36, name="Pelo", label="Pelo corto"):
    base = A.hair_base("PeloBase", back=-0.5, side=0.0, front=0.42, grow=0.08, lift=0.06)
    G.assign(base, hm)
    parts = [base]
    r = random.Random(seed)
    k = 0
    for ph, n in ((16, 4), (36, 7), (56, 8)):
        for i in range(n):
            th = 360 * i / n + r.uniform(-14, 14)
            fr = math.cos(math.radians(th))
            p, nrm = A.head_point(th, ph, 1.04)
            dirv = Vector((0, 0.7, 0.35)) if (fr > 0.2 and forward) else Vector((0, -0.4, 0.35))
            d = (nrm * 0.5 + dirv + Vector((r.uniform(-0.25, 0.25), 0, 0))).normalized()
            o = A.lock(f"Mechon{k}", p, d, r.uniform(length * 0.8, length * 1.15), r.uniform(0.17, 0.22), 0.08, nrm, bend=-0.25, n=4, segs=5, tip=0.18)
            G.assign(o, hm)
            parts.append(o)
            k += 1
    return K.add(name, parts, "Head", lod=True, texel=1.2, label=label)


def hair_swept(K, hm, name="Pelo", label="Pelo peinado"):
    base = A.hair_base("PeloBase", back=-0.5, side=0.05, front=0.5, grow=0.1, lift=0.16)
    G.assign(base, hm)
    parts = [base]
    for i in range(6):
        p, n = A.head_point(-40 + i * 16, 28, 1.1)
        o = A.lock(f"Onda{i}", p + Vector((0, 0.08, 0.05)), Vector((0.2, -0.7, 0.55)), 0.66, 0.22, 0.1, n, bend=-0.25, n=5, segs=5, tip=0.45)
        G.assign(o, hm)
        parts.append(o)
    return K.add(name, parts, "Head", lod=True, texel=1.2, label=label)


def hair_long(K, hm, name="Pelo", label="Melena", wavy=0.0, length=1.25, fringe=True):
    base = A.hair_base("PeloBase", back=-0.6, side=-0.2, front=0.48, grow=0.08, lift=0.05)
    G.assign(base, hm)
    zs = ((0.3, 0.72, 0.7), (-0.2, 0.76, 0.72), (-0.7, 0.8, 0.62), (-length, 0.78, 0.45), (-length - 0.15, 0.7, 0.4))
    mane = G.loft("Melena", [{"c": HEAD_C + Vector((0, -0.08, z)), "rx": rx * (1 + wavy * math.sin(z * 7)), "ry": ry, "sq": 3.2} for z, rx, ry in zs],
                  segs=22, cap0=False, cap1=False, gap=((0, 1, 0), 1.35))
    mm = mane.modifiers.new("Grosor", "SOLIDIFY")
    mm.thickness = 0.07
    G.apply_mods(mane)
    G.assign(mane, hm)
    parts = [base, mane]
    if fringe:
        for i in range(4):
            p, n = A.head_point(-36 + i * 16, 40, 1.06)
            o = A.lock(f"Flequillo{i}", p, Vector((0.6, 0.35, -0.7)), 0.4 - i * 0.03, 0.18, 0.05, n, bend=0.15, n=4, segs=5, tip=0.35)
            G.assign(o, hm)
            parts.append(o)
    return K.add(name, parts, "Head", lod=True, texel=1.3, label=label)


def hair_bun(K, hm, name="Pelo", label="Moño", high=True):
    base = A.hair_base("PeloBase", back=-0.55, side=-0.15, front=0.45, grow=0.07, lift=0.05)
    G.assign(base, hm)
    pos = HEAD_C + (Vector((0, -0.15, 0.85)) if high else Vector((0, -0.6, 0.35)))
    bun = G.blob("Mono", pos, (0.34, 0.32, 0.3), segs=14, rings=9)
    G.assign(bun, hm)
    return K.add(name, [base, bun], "Head", lod=True, texel=1.2, label=label)


def hair_ponytail(K, hm, name="Pelo", label="Coleta"):
    base = A.hair_base("PeloBase", back=-0.55, side=-0.15, front=0.45, grow=0.07, lift=0.04)
    G.assign(base, hm)
    tie = G.blob("Gomilla", HEAD_C + Vector((0, -0.7, 0.25)), (0.16, 0.12, 0.16), segs=10, rings=6)
    G.assign(tie, hm)
    # coleta ancha y plana (una «hoja» de pelo, no un tubo)
    tail = G.loft("Coleta", [{"c": HEAD_C + Vector((0, -0.74, z)), "rx": rx, "ry": 0.12, "u": Vector((1, 0, 0)), "sq": 2.4}
                             for z, rx in ((0.2, 0.24), (-0.2, 0.3), (-0.6, 0.26), (-0.85, 0.14))], segs=10)
    G.assign(tail, hm)
    return K.add(name, [base, tie, tail], "Head", lod=True, texel=1.2, label=label)


def hair_curly(K, hm, name="Pelo", label="Pelo rizado", n=18, seed=8, size=0.17):
    base = A.hair_base("PeloBase", back=-0.5, side=-0.05, front=0.45, grow=0.09, lift=0.08)
    G.assign(base, hm)
    parts = [base]
    r = random.Random(seed)
    for i in range(n):
        th = r.uniform(-180, 180)
        ph = r.uniform(12, 85)
        if math.cos(math.radians(th)) > 0.5 and ph > 40:
            continue
        p, _ = A.head_point(th, ph, 1.08)
        b = G.blob(f"Rizo{i}", p, (size, size, size * 0.9), segs=8, rings=6)
        G.assign(b, hm)
        parts.append(b)
    return K.add(name, parts, "Head", lod=True, texel=1.2, label=label)


def hair_sides(K, hm, name="Pelo", label="Pelo a los lados"):
    base = A.hair_base("PeloLados", back=-0.6, side=-0.3, front=0.9, grow=0.07, max_z=0.4)
    G.assign(base, hm)
    return K.add(name, [base], "Head", texel=0.8, label=label)


def hair_buzz(K, hm, name="Pelo", label="Pelo rapado"):
    base = A.hair_base("PeloBase", back=-0.45, side=0.0, front=0.55, grow=0.03, lift=0.0)
    G.assign(base, hm)
    return K.add(name, [base], "Head", texel=0.8, label=label)


def cap_baseball(K, mat, name="Gorra", label="Gorra", back=False):
    c = HEAD_C
    crown = G.blob(name + "Copa", c + Vector((0, -0.02, 0.42)), (0.72, 0.7, 0.42), segs=18, rings=8,
                   deform=lambda p: Vector((p.x, p.y, max(p.z, -0.05))))
    G.assign(crown, mat)
    s = -1 if back else 1
    visor = G.loft(name + "Visera", [{"c": c + Vector((0, s * 0.62, 0.4)), "rx": 0.55, "ry": 0.03, "u": Vector((1, 0, 0)), "sq": 2.2},
                                     {"c": c + Vector((0, s * 1.0, 0.36)), "rx": 0.46, "ry": 0.025, "u": Vector((1, 0, 0)), "sq": 2.2}], segs=10)
    G.assign(visor, mat)
    btn = G.blob(name + "Boton", c + Vector((0, 0, 0.84)), (0.07, 0.07, 0.04), segs=8, rings=4)
    G.assign(btn, mat)
    return K.add(name, [crown, visor, btn], "Head", lod=True, texel=0.8, label=label)


def sunglasses(K, name="GafasSol", label="Gafas de sol"):
    frame = K.mat("gafas_sol", G.mat_plain, (0.03, 0.03, 0.035), 0.25)
    lens_m = K.mat("cristal_sol", G.mat_plain, (0.05, 0.06, 0.08), 0.08)
    gp = []
    for sx in (-1, 1):
        lns = G.rbox(f"LenteSol{sx}", (sx * 0.27, 0.66, 4.63), (0.42, 0.06, 0.3), bevel=0.07, segs=2)
        G.assign(lns, lens_m)
        t = G.rbox(f"Patilla{sx}", (sx * 0.64, 0.15, 4.72), (0.05, 1.0, 0.06), bevel=0.02, segs=1)
        G.assign(t, frame)
        gp += [lns, t]
    br = G.rbox("PuenteSol", (0, 0.68, 4.7), (0.16, 0.05, 0.05), bevel=0.02, segs=1)
    G.assign(br, frame)
    return K.add(name, gp + [br], "Head", texel=0.4, label=label)


def glasses(K, color=(40, 30, 36), round_=False, name="Gafas", label="Gafas"):
    rim = K.mat("montura_" + name, G.mat_plain, lin(color), 0.3)
    gp = []
    for sx in (-1, 1):
        if round_:
            f = G.torus(f"Lente{sx}", (sx * 0.24, 0.66, 4.62), (0, 1, 0), 0.19, 0.03, segs=16, tsegs=5)
        else:
            f = G.loft(f"Montura{sx}", [{"c": Vector((sx * 0.26, 0.64, 4.62)), "rx": 0.2, "ry": 0.15, "sq": 3.4, "u": Vector((1, 0, 0))},
                                        {"c": Vector((sx * 0.26, 0.67, 4.62)), "rx": 0.2, "ry": 0.15, "sq": 3.4, "u": Vector((1, 0, 0))}], segs=12, cap0=False, cap1=False)
        G.assign(f, rim)
        t = G.rbox(f"Patilla{sx}", (sx * 0.64, 0.15, 4.72), (0.045, 1.0, 0.045), bevel=0.015, segs=1)
        G.assign(t, rim)
        gp += [f, t]
    br = G.rbox("Puente", (0, 0.67, 4.65), (0.12, 0.04, 0.04), bevel=0.015, segs=1)
    G.assign(br, rim)
    return K.add(name, gp + [br], "Head", texel=0.3, label=label)


def apron(K, color, name="Delantal", label="Delantal", long_=False, bib=False):
    m = K.mat("delantal_" + name, G.mat_cloth, lin(color), "canvas", 1.0)
    bottom = 0.75 if long_ else 1.3
    ap = G.loft(name + "Falda", [{"c": Vector((0, 0.56, z)), "rx": w, "ry": 0.03, "u": Vector((1, 0, 0)), "sq": 4.0} for z, w in ((2.42, 0.62), (2.0, 0.68), (bottom, 0.72))], segs=8)
    G.assign(ap, m)
    tie = A.box_shell(name + "Cinta", (0, 0), (1.04, 0.54), 2.3, 2.42, sq=4.2, segs=20, thick=0.03)
    G.assign(tie, m)
    K.add(name, [ap, tie], "LowerTorso", texel=0.7, label=label)
    if bib:
        b = G.loft(name + "Peto", [{"c": Vector((0, 0.56, z)), "rx": w, "ry": 0.03, "u": Vector((1, 0, 0)), "sq": 4.0} for z, w in ((2.44, 0.6), (3.2, 0.5), (3.7, 0.46))], segs=8)
        G.assign(b, m)
        straps = []
        for sx in (-1, 1):
            st = G.loft(f"{name}Tirante{sx}", G.path_rings([(sx * 0.42, 0.57, 3.7), (sx * 0.5, 0.2, 4.03), (sx * 0.5, -0.4, 3.9), (sx * 0.45, -0.56, 2.5)], [(0.07, 0.025)] * 4, sq=3.0), segs=6)
            G.assign(st, m)
            straps.append(st)
        K.add(name + "Peto", [b] + straps, "UpperTorso", texel=0.7, label=label)


def vest_shell(K, mat, name="Chaleco", label="Chaleco", pockets=None):
    parts = A.torso_shell(K, mat, name, open_low=0.3, open_top=0.6, collar=False, segs=24)
    if pockets is not None:
        for i, (x, z) in enumerate(((-0.55, 3.0), (0.55, 3.0), (-0.55, 3.5), (0.55, 3.5))):
            pk = G.rbox(f"{name}Bolsillo{i}", (x, 0.62, z), (0.36, 0.1, 0.32), bevel=0.04, segs=1)
            G.assign(pk, pockets)
            parts.append(pk)
    return K.add(name, parts, "UpperTorso", lod=True, texel=1.0, label=label)


def hand_box(K, part, size, color, name, label, kind="leather", offset=(0, 0.45, -0.2)):
    h = hp(part)
    o = G.rbox(name, h + Vector(offset), size, bevel=0.05, segs=1)
    mat = K.mat(name, G.mat_leather if kind == "leather" else G.mat_plain, lin(color), 0.45)
    G.assign(o, mat)
    return o, mat


# ====================================================================== OFICIOS
def kit_ramon(K):
    """Frutero Ramón, la tienda de barrio: gorra gris, pelo canoso a los lados, bigote, delantal oscuro."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_sides(K, A.hair_mat(K, s["Hair"]), label="Pelo canoso")
    cap_baseball(K, K.mat("gorra", G.mat_cloth, lin((120, 120, 126)), "twill", 1.0), label="Gorra de la tienda")
    mus = K.mat("bigote", G.mat_hair, lin(s["Hair"]), "X")
    mp = []
    for sx in (-1, 1):
        pts = [Vector((sx * 0.02, 0.66, 4.42)), Vector((sx * 0.18, 0.67, 4.4)), Vector((sx * 0.3, 0.65, 4.34))]
        o = G.loft(f"Bigote{sx}", G.path_rings(pts, [(0.09, 0.05), (0.08, 0.05), (0.04, 0.03)], sq=2.2), segs=8)
        G.assign(o, mus)
        mp.append(o)
    K.add("Bigote", mp, "Head", texel=0.4, label="Bigote")
    apron(K, (52, 46, 44), bib=True, label="Delantal de la tienda")
    A.boots(K, (90, 60, 40), (50, 36, 26), name="Zapato")


def kit_dani(K):
    """Barista Dani, la cafetería: melena castaña, delantal blanco, bandeja con taza."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_long(K, A.hair_mat(K, s["Hair"]), label="Melena castaña", wavy=0.04)
    apron(K, (245, 245, 242), label="Delantal blanco")
    h = hp("LeftHand")
    tray = G.loft("Bandeja", [{"c": h + Vector((0, 0.55, -0.16)), "rx": 0.6, "ry": 0.6, "u": Vector((1, 0, 0))},
                              {"c": h + Vector((0, 0.55, -0.12)), "rx": 0.64, "ry": 0.64, "u": Vector((1, 0, 0))}], segs=18)
    G.assign(tray, K.mat("bandeja", G.mat_plain, lin((40, 40, 44)), 0.3))
    cup = G.cyl("Taza", h + Vector((0, 0.6, -0.12)), h + Vector((0, 0.6, 0.12)), 0.17, segs=14)
    G.assign(cup, K.mat("taza", G.mat_plain, (0.95, 0.94, 0.92), 0.3))
    plate = G.cyl("Platito", h + Vector((0, 0.6, -0.12)), h + Vector((0, 0.6, -0.09)), 0.27, segs=14)
    G.assign(plate, K.mat("taza", G.mat_plain, (0.95, 0.94, 0.92), 0.3))
    K.add("Bandeja", [tray, cup, plate], "LeftHand", texel=0.4, label="Bandeja con café")
    A.boots(K, (30, 30, 32), (20, 20, 22), name="Zapato")


def kit_sergio(K):
    """Policía Sergio: gorra de plato con placa, gafas de sol, cinturón con radio, botas."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_buzz(K, A.hair_mat(K, s["Hair"]))
    navy = K.mat("gorra", G.mat_cloth, lin((26, 34, 70)), "twill", 1.0)
    c = HEAD_C
    band = A.box_shell("GorraBanda", (0, 0), (0.7, 0.68), 4.95, 5.18, sq=3.4, segs=22, thick=0.04)
    G.assign(band, K.mat("negro", G.mat_leather, lin((20, 20, 24)), 0.4))
    top = G.loft("GorraPlato", [{"c": c + Vector((0, 0.02, z)), "rx": rx, "ry": ry, "sq": 3.0} for z, rx, ry in ((0.56, 0.7, 0.68), (0.72, 0.8, 0.8), (0.8, 0.74, 0.74))], segs=22, cap0=False, cap1=True)
    G.assign(top, navy)
    visor = G.loft("GorraVisera", [{"c": c + Vector((0, 0.62, 0.38)), "rx": 0.55, "ry": 0.03, "u": Vector((1, 0, 0)), "sq": 2.2},
                                   {"c": c + Vector((0, 0.9, 0.3)), "rx": 0.45, "ry": 0.025, "u": Vector((1, 0, 0)), "sq": 2.2}], segs=10)
    G.assign(visor, K.mat("negro", G.mat_leather, lin((20, 20, 24)), 0.4))
    plaque = G.rbox("GorraPlaca", c + Vector((0, 0.74, 0.6)), (0.22, 0.05, 0.22), bevel=0.04, segs=1)
    G.assign(plaque, K.mat("oro", G.mat_metal, lin((220, 180, 70)), 0.3))
    K.add("Gorra", [band, top, visor, plaque], "Head", lod=True, texel=0.9, label="Gorra de policía")
    sunglasses(K)
    blk = K.mat("cinturon", G.mat_leather, lin((22, 22, 26)), 0.4)
    belt = A.box_shell("Cinturon", (0, 0), (1.06, 0.56), 2.18, 2.42, sq=4.2, segs=24, thick=0.05)
    G.assign(belt, blk)
    pouches = []
    for i, (x, y) in enumerate(((-0.7, 0.5), (0.7, 0.5), (1.02, 0.0), (-1.02, 0.0))):
        p = G.rbox(f"Funda{i}", (x, y, 2.28), (0.26 if abs(y) > 0.1 else 0.14, 0.14 if abs(y) > 0.1 else 0.3, 0.3), bevel=0.04, segs=1)
        G.assign(p, blk)
        pouches.append(p)
    K.add("Cinturon", [belt] + pouches, "LowerTorso", texel=0.6, label="Cinturón de servicio")
    radio = G.rbox("Radio", (0.62, 0.58, 3.7), (0.24, 0.12, 0.34), bevel=0.04, segs=1)
    G.assign(radio, blk)
    K.add("Radio", radio, "UpperTorso", texel=0.3, label="Radio")
    A.boots(K, (22, 22, 26), (14, 14, 16), shaft=(22, 22, 26), name="Bota")


def kit_pedro(K):
    """Mecánico Pedro: gorra roja, pelo corto, lata de aceite, trapo en el bolsillo, botas."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_short(K, A.hair_mat(K, s["Hair"]), seed=11, length=0.3)
    cap_baseball(K, K.mat("gorra", G.mat_cloth, lin((200, 40, 40)), "twill", 1.0), label="Gorra roja")
    h = hp("RightHand")
    # lata de aceite cuadrada con asa (en vez de una llave inglesa: de frente, sola y gris, una llave es
    # un palo largo; la lata es un objeto que se lee de lejos)
    can = G.rbox("Lata", h + Vector((0, 0.15, -0.62)), (0.42, 0.72, 0.72), bevel=0.06, segs=1)
    G.assign(can, K.mat("lata", G.mat_metal, lin((200, 60, 40)), 0.4))
    cap = G.rbox("LataTapon", h + Vector((0, 0.42, -0.2)), (0.16, 0.16, 0.12), bevel=0.03, segs=1)
    G.assign(cap, K.mat("tapon", G.mat_plain, lin((240, 200, 60)), 0.4))
    grip = G.rbox("LataAsa", h + Vector((0, 0.0, -0.18)), (0.12, 0.42, 0.12), bevel=0.04, segs=1)
    G.assign(grip, K.mat("asa", G.mat_plain, lin((30, 30, 32)), 0.4))
    K.add("Lata", [can, cap, grip], "RightHand", texel=0.4, label="Lata de aceite")
    rag = G.rbox("Trapo", (0.62, -0.58, 2.1), (0.3, 0.06, 0.4), bevel=0.06, segs=1)
    G.assign(rag, K.mat("trapo", G.mat_cloth, lin((200, 70, 50)), "canvas", 1.0))
    K.add("Trapo", rag, "LowerTorso", texel=0.3, label="Trapo")
    A.boots(K, (60, 46, 36), (30, 26, 22), name="Bota", chunky=1.05)


def kit_carmen(K):
    """Enfermera Carmen: moño, fonendoscopio al cuello (un aro y un disco), portapapeles, zuecos."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_bun(K, A.hair_mat(K, s["Hair"]))
    tube = K.mat("goma", G.mat_plain, lin((40, 44, 56)), 0.4)
    ring = G.torus("Fonendo", Vector((0, 0.1, 3.95)), (0, 0, 1), 0.62, 0.04, segs=24, tsegs=5, sx=1.0, sy=0.85)
    G.assign(ring, tube)
    disc = G.cyl("FonendoDisco", (0.32, 0.62, 3.55), (0.32, 0.7, 3.55), 0.13, segs=14)
    G.assign(disc, K.mat("metal", G.mat_metal, lin((190, 192, 198)), 0.3))
    drop = G.rbox("FonendoTubo", (0.32, 0.6, 3.75), (0.06, 0.06, 0.34), bevel=0.02, segs=1)
    G.assign(drop, tube)
    K.add("Fonendo", [ring, disc, drop], "UpperTorso", texel=0.3, label="Fonendoscopio")
    o, _ = hand_box(K, "LeftHand", (0.12, 0.7, 0.9), (150, 110, 70), "Portapapeles", "Portapapeles", kind="plain", offset=(0, 0.45, 0.05))
    paper = G.rbox("Hoja", hp("LeftHand") + Vector((0.07, 0.45, 0.02)), (0.02, 0.6, 0.75), bevel=0.005, segs=1)
    G.assign(paper, K.mat("hoja", G.mat_plain, (0.94, 0.94, 0.92), 0.6))
    K.add("Portapapeles", [o, paper], "LeftHand", texel=0.4, label="Portapapeles")
    A.boots(K, (240, 240, 245), (200, 200, 205), name="Zueco")


def kit_nacho(K):
    """Bombero Nacho: casco con escudo, chaquetón con bandas (textura), linterna al pecho, botas altas."""
    s = K.s
    A.head_block(K, s["Skin"])
    c = HEAD_C
    shell = K.mat("casco", G.mat_plain, lin((30, 30, 34)), 0.25)
    dome = G.blob("Casco", c + Vector((0, -0.02, 0.4)), (0.74, 0.74, 0.5), segs=18, rings=9, deform=lambda p: Vector((p.x, p.y, max(p.z, -0.02))))
    G.assign(dome, shell)
    brim = G.loft("CascoAla", [{"c": c + Vector((0, -0.12, 0.36)), "rx": 0.86, "ry": 0.86, "sq": 2.4},
                               {"c": c + Vector((0, -0.3, 0.28)), "rx": 1.02, "ry": 1.1, "sq": 2.4}], segs=22, cap0=True, cap1=True)
    G.assign(brim, shell)
    crest = G.rbox("CascoCresta", c + Vector((0, 0, 0.88)), (0.12, 1.0, 0.1), bevel=0.04, segs=1)
    G.assign(crest, shell)
    shield = G.rbox("CascoEscudo", c + Vector((0, 0.74, 0.62)), (0.36, 0.06, 0.34), bevel=0.06, segs=1)
    G.assign(shield, K.mat("escudo", G.mat_metal, lin((220, 180, 60)), 0.3))
    K.add("Casco", [dome, brim, crest, shield], "Head", lod=True, texel=0.9, label="Casco de bombero")
    lamp = G.rbox("Linterna", (-0.55, 0.62, 3.6), (0.26, 0.16, 0.34), bevel=0.05, segs=1)
    G.assign(lamp, K.mat("linterna", G.mat_plain, lin((240, 190, 40)), 0.4))
    K.add("Linterna", lamp, "UpperTorso", texel=0.3, label="Linterna")
    lens = G.rbox("LinternaLuz", (-0.55, 0.71, 3.66), (0.16, 0.03, 0.14), bevel=0.02, segs=1)
    K.glow("LinternaLuz", lens, "UpperTorso", lin((255, 240, 180)), label="Linterna")
    A.boots(K, (26, 26, 28), (14, 14, 16), shaft=(26, 26, 28), name="Bota", chunky=1.08)


def kit_raul(K):
    """Barman Raúl: pelo peinado, gafas de sol, delantal largo negro, vaso ancho en la mano."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_swept(K, A.hair_mat(K, s["Hair"]))
    sunglasses(K)
    apron(K, (24, 24, 26), long_=True, label="Delantal de barra")
    h = hp("RightHand")
    glass = G.cyl("Vaso", h + Vector((0, 0.5, -0.25)), h + Vector((0, 0.5, 0.15)), 0.22, segs=14)
    G.assign(glass, K.mat("vaso", G.mat_plain, lin((190, 220, 230)), 0.08))
    drink = G.cyl("Bebida", h + Vector((0, 0.5, -0.2)), h + Vector((0, 0.5, 0.0)), 0.19, segs=14)
    G.assign(drink, K.mat("bebida", G.mat_plain, lin((200, 60, 90)), 0.2))
    K.add("Vaso", [glass, drink], "RightHand", texel=0.3, label="Vaso")
    A.boots(K, (20, 20, 22), (14, 14, 16), name="Zapato")


def kit_chema(K):
    """Pescador Chema: sombrero de pesca, barba canosa, chaleco con bolsillos, cubo, botas de agua."""
    s = K.s
    A.head_block(K, s["Skin"])
    c = HEAD_C
    hat = K.mat("sombrero", G.mat_cloth, lin((150, 130, 90)), "canvas", 1.0)
    crown = G.loft("SombreroCopa", [{"c": c + Vector((0, 0, z)), "rx": rx, "ry": rx, "sq": 2.6} for z, rx in ((0.3, 0.72), (0.6, 0.66), (0.8, 0.55))], segs=20, cap0=False, cap1=True)
    G.assign(crown, hat)
    brim = G.loft("SombreroAla", [{"c": c + Vector((0, 0, 0.32)), "rx": 0.7, "ry": 0.7, "sq": 2.2}, {"c": c + Vector((0, 0, 0.14)), "rx": 1.0, "ry": 1.0, "sq": 2.2}], segs=20, cap0=False, cap1=False)
    m = brim.modifiers.new("Grosor", "SOLIDIFY")
    m.thickness = 0.05
    G.apply_mods(brim)
    G.assign(brim, hat)
    K.add("Sombrero", [crown, brim], "Head", lod=True, texel=0.9, label="Sombrero de pesca")
    # barba cuadrada y pegada a la cara (un bloque con bigote, no una pieza redonda y alargada)
    bm_ = K.mat("barba", G.mat_hair, lin(s["Hair"]), "Z", 2.0)
    beard = G.rbox("Barba", c + Vector((0, 0.6, -0.42)), (1.0, 0.16, 0.4), bevel=0.06, segs=1)
    chin = G.rbox("BarbaMenton", c + Vector((0, 0.64, -0.6)), (0.5, 0.14, 0.2), bevel=0.05, segs=1)
    mus = []
    for sx in (-1, 1):
        m_ = G.rbox(f"Bigote{sx}", c + Vector((sx * 0.17, 0.68, -0.2)), (0.3, 0.1, 0.12), bevel=0.04, segs=1)
        mus.append(m_)
    for o_ in [beard, chin] + mus:
        G.assign(o_, bm_)
    K.add("Barba", [beard, chin] + mus, "Head", texel=0.5, label="Barba")
    vest = K.mat("chaleco", G.mat_cloth, lin((96, 100, 80)), "canvas", 1.0)
    vest_shell(K, vest, label="Chaleco de pesca", pockets=K.mat("chaleco_osc", G.mat_cloth, G.shade(lin((96, 100, 80)), 0.7), "canvas", 1.0))
    h = hp("RightHand")
    pail = G.loft("Cubo", [{"c": h + Vector((0, 0.15, z)), "rx": rx, "ry": rx, "sq": 2.0} for z, rx in ((-0.95, 0.3), (-0.4, 0.38))], segs=16, cap0=True, cap1=False)
    m2 = pail.modifiers.new("Grosor", "SOLIDIFY")
    m2.thickness = 0.04
    G.apply_mods(pail)
    G.assign(pail, K.mat("cubo", G.mat_plain, lin((40, 110, 170)), 0.4))
    handle = G.torus("CuboAsa", h + Vector((0, 0.15, -0.36)), (1, 0, 0), 0.36, 0.03, segs=16, tsegs=4)
    G.assign(handle, K.mat("acero", G.mat_metal, lin((170, 172, 178)), 0.3))
    K.add("Cubo", [pail, handle], "RightHand", texel=0.4, label="Cubo")
    A.boots(K, (230, 190, 40), (40, 40, 40), shaft=(230, 190, 40), name="BotaAgua")


def kit_kevin(K):
    """Repartidor Kevin: gorra, pelo corto, bandolera y paquete en la mano."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_short(K, A.hair_mat(K, s["Hair"]), seed=21, length=0.3)
    cap_baseball(K, K.mat("gorra", G.mat_cloth, lin((30, 60, 50)), "twill", 1.0), label="Gorra de reparto")
    bag_m = K.mat("bandolera", G.mat_cloth, lin((40, 46, 44)), "canvas", 1.0)
    bag = G.rbox("Bandolera", (-0.95, 0.15, 2.3), (0.3, 0.8, 0.62), bevel=0.08, segs=2)
    G.assign(bag, bag_m)
    strap = G.loft("Correa", G.path_rings([(-0.95, 0.1, 2.6), (-0.6, 0.56, 3.3), (0.4, 0.56, 3.95), (0.62, 0.0, 4.05), (0.4, -0.56, 3.6), (-0.9, -0.3, 2.62)], [(0.09, 0.025)] * 6, sq=3.0), segs=6)
    G.assign(strap, bag_m)
    K.add("Bandolera", [bag, strap], "UpperTorso", lod=True, texel=0.6, label="Bandolera")
    box, _ = hand_box(K, "RightHand", (0.7, 0.8, 0.6), (190, 150, 100), "Paquete", "Paquete", kind="plain", offset=(0, 0.35, -0.25))
    tape = G.rbox("Cinta", hp("RightHand") + Vector((0, 0.35, 0.06)), (0.72, 0.18, 0.02), bevel=0.005, segs=1)
    G.assign(tape, K.mat("cinta", G.mat_plain, lin((220, 200, 150)), 0.4))
    K.add("Paquete", [box, tape], "RightHand", texel=0.4, label="Paquete")
    A.boots(K, (240, 240, 240), (50, 120, 60), name="Zapatilla")


def kit_borja(K):
    """Ejecutivo Borja (traje de concesionario y oficina): pelo peinado, gafas de sol, carpeta, zapatos."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_swept(K, A.hair_mat(K, s["Hair"]))
    sunglasses(K)
    o, _ = hand_box(K, "LeftHand", (0.14, 0.8, 1.0), (30, 30, 36), "Carpeta", "Carpeta", offset=(0, 0.45, 0.05))
    K.add("Carpeta", [o], "LeftHand", texel=0.4, label="Carpeta")
    A.boots(K, (24, 22, 24), (14, 14, 16), name="Zapato")


def kit_julio(K):
    """Farmacéutico Julio (y la consulta): bata blanca por piezas, gafas finas, pelo corto, acreditación."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_short(K, A.hair_mat(K, s["Hair"]), seed=31, forward=False, length=0.28)
    glasses(K, (50, 50, 60))
    coat = K.mat("bata", G.mat_cloth, lin((244, 244, 242)), "canvas", 1.0, folds=0.5)
    cparts = A.torso_shell(K, coat, "Bata", open_low=0.4, open_top=0.55, lapel_mat=coat, collar=True, segs=24)
    K.add("Bata", cparts, "UpperTorso", lod=True, texel=1.0, label="Bata blanca")
    A.sleeves(K, coat, coat, cuff_z=2.4, grow=0.06, name="Manga", rolled=False)
    A.coat_tails(K, coat, "Faldon", z_top=2.4, z_bot=1.3, flare=0.08, label="Bata blanca")
    A.boots(K, (60, 50, 44), (30, 26, 22), name="Zapato")


def kit_paco(K):
    """Paco, de la obra: casco de obra amarillo, pelo corto, caja de herramientas, botas de seguridad."""
    s = K.s
    A.head_block(K, s["Skin"])
    c = HEAD_C
    yel = K.mat("casco", G.mat_plain, lin((250, 200, 30)), 0.3)
    dome = G.blob("CascoObra", c + Vector((0, 0, 0.42)), (0.72, 0.72, 0.46), segs=18, rings=8, deform=lambda p: Vector((p.x, p.y, max(p.z, -0.02))))
    G.assign(dome, yel)
    brim = G.loft("CascoObraAla", [{"c": c + Vector((0, 0.06, 0.4)), "rx": 0.78, "ry": 0.8, "sq": 2.6}, {"c": c + Vector((0, 0.16, 0.36)), "rx": 0.84, "ry": 0.94, "sq": 2.6}], segs=20)
    G.assign(brim, yel)
    rib = G.rbox("CascoObraNervio", c + Vector((0, 0, 0.86)), (0.16, 1.1, 0.08), bevel=0.04, segs=1)
    G.assign(rib, yel)
    K.add("Casco", [dome, brim, rib], "Head", lod=True, texel=0.8, label="Casco de obra")
    h = hp("RightHand")
    red = K.mat("caja", G.mat_plain, lin((200, 50, 40)), 0.4)
    box = G.rbox("CajaHerramientas", h + Vector((0, 0.1, -0.6)), (0.4, 0.9, 0.5), bevel=0.06, segs=1)
    G.assign(box, red)
    lid = G.rbox("CajaTapa", h + Vector((0, 0.1, -0.32)), (0.42, 0.92, 0.08), bevel=0.03, segs=1)
    G.assign(lid, K.mat("tapa", G.mat_plain, lin((150, 30, 26)), 0.4))
    handle = G.rbox("CajaAsa", h + Vector((0, 0.1, -0.18)), (0.1, 0.6, 0.08), bevel=0.03, segs=1)
    G.assign(handle, K.mat("asa", G.mat_plain, lin((30, 30, 32)), 0.4))
    K.add("Caja", [box, lid, handle], "RightHand", texel=0.4, label="Caja de herramientas")
    A.boots(K, (120, 80, 40), (40, 30, 24), shaft=(120, 80, 40), name="Bota", chunky=1.06)


def kit_vero(K):
    """Dependienta Vero, la tienda de ropa: melena larga ondulada, gorra, bolso al hombro, zapatillas."""
    s = K.s
    A.head_block(K, s["Skin"])
    hair_long(K, A.hair_mat(K, s["Hair"]), wavy=0.08, length=1.35, fringe=False, label="Melena ondulada")
    cap_baseball(K, K.mat("gorra", G.mat_cloth, lin((30, 30, 34)), "twill", 1.0), label="Gorra")
    bag = G.rbox("Bolso", (1.1, 0.05, 2.35), (0.28, 0.7, 0.55), bevel=0.1, segs=2)
    G.assign(bag, K.mat("bolso", G.mat_leather, lin((150, 100, 70)), 0.4))
    strap = G.loft("BolsoCorrea", G.path_rings([(1.1, 0.0, 2.6), (1.05, 0.45, 3.4), (0.6, 0.3, 4.03), (0.6, -0.3, 4.03), (1.05, -0.45, 3.4), (1.1, -0.1, 2.6)], [(0.06, 0.02)] * 6, sq=3.0), segs=6)
    G.assign(strap, K.mat("bolso", G.mat_leather, lin((150, 100, 70)), 0.4))
    K.add("Bolso", [bag, strap], "UpperTorso", texel=0.5, label="Bolso")
    A.boots(K, (245, 245, 245), (220, 220, 222), name="Zapatilla")


def W(key, name, title, kit, skin, hair, shirt, pants, oficios, face=None, eye=(92, 60, 38)):
    return {"Key": "Oficio_" + key, "Name": name, "Title": title, "Cast": "Oficio", "Hero": False, "Kit": kit, "Skin": skin, "Hair": hair,
            "Coat": shirt[1]["main"], "Eye": eye, "Faces": WORKER_FACES, "Face": face or {}, "Shirt": shirt, "Pants": pants, "Oficios": oficios}


OFICIOS = [
    W("Ramon", "Frutero Ramón", "Tienda de barrio", kit_ramon, (226, 180, 140), (205, 205, 210), ("tienda", {"main": (150, 150, 160)}), ("trousers", {"main": (70, 64, 60)}),
      ["Frutero Ramón", "Npc_Dependiente", "Npc_Charcutero"], {"Wrinkles": True, "Brow": (205, 205, 210), "BrowThick": 0.05}),
    W("Dani", "Barista Dani", "Cafetería", kit_dani, (232, 190, 152), (120, 74, 40), ("camarera", {"main": (32, 32, 36)}), ("trousers", {"main": (30, 30, 34)}),
      ["Barista Dani", "Npc_Barista", "Npc_Camarero"], {"Lash": True, "Lip": (196, 96, 100)}),
    W("Sergio", "Policía Sergio", "Comisaría", kit_sergio, (214, 168, 128), (40, 30, 24), ("policia", {"main": (28, 38, 78)}), ("trousers", {"main": (24, 30, 60)}),
      ["Policía", "Agente"], {"BrowThick": 0.05}),
    W("Pedro", "Mecánico Pedro", "Taller", kit_pedro, (222, 176, 136), (40, 30, 24), ("mono", {"main": (40, 58, 104)}), ("mono", {"main": (40, 58, 104)}),
      ["Mecánico"], {"Stubble": True}),
    W("Carmen", "Enfermera Carmen", "Hospital", kit_carmen, (230, 190, 156), (110, 72, 44), ("pijama", {"main": (120, 180, 220)}), ("trousers", {"main": (120, 180, 220)}),
      ["Enfermera", "Enfermera Carmen"], {"Lash": True, "Lip": (200, 100, 110)}),
    W("Nacho", "Bombero Nacho", "Parque de bomberos", kit_nacho, (206, 160, 120), (40, 30, 24), ("bombero", {"main": (40, 40, 46)}), ("bombero", {"main": (40, 40, 46)}),
      ["Bombero Nacho", "Bombero"], {"BrowThick": 0.05}),
    W("Raul", "Barman Raúl", "Bar", kit_raul, (200, 150, 110), (26, 22, 20), ("barman", {"main": (26, 26, 30), "vest": (40, 40, 46)}), ("trousers", {"main": (26, 26, 30)}),
      ["Npc_Barman", "Barman (barra)"], {"Stubble": True}),
    W("Chema", "Pescador Chema", "Puerto", kit_chema, (210, 160, 118), (190, 186, 180), ("pescador", {"main": (110, 116, 124)}), ("jeans", {"main": (50, 62, 90)}),
      ["Pescador Chema", "Npc_Pescador", "Npc_TenderoPesca", "Marinero"], {"Wrinkles": True, "Brow": (190, 186, 180)}),
    W("Kevin", "Repartidor Kevin", "Mensajería", kit_kevin, (176, 126, 92), (30, 24, 20), ("reparto", {"main": (30, 60, 50), "stripe": (110, 200, 110)}), ("cargo", {"main": (40, 46, 44)}),
      ["Repartidor"], {}),
    W("Borja", "Ejecutivo Borja", "Concesionario y oficinas", kit_borja, (226, 184, 146), (34, 28, 24), ("traje", {"main": (30, 30, 36), "under": (245, 245, 245)}), ("trousers", {"main": (30, 30, 36)}),
      ["Ejecutivo Borja", "Recepcionista", "Npc_Recepcionista", "Funcionario"], {}),
    W("Julio", "Farmacéutico Julio", "Farmacia y consulta", kit_julio, (220, 176, 138), (70, 50, 36), ("bata", {"main": (244, 244, 242), "under": (90, 160, 160)}), ("trousers", {"main": (60, 64, 80)}),
      ["Farmacéutico Julio", "Médico", "Npc_Medico"], {}),
    W("Paco", "Paco, de la obra", "Obras", kit_paco, (204, 156, 116), (50, 36, 26), ("obra", {"main": (250, 130, 30), "shirt": (60, 70, 120)}), ("cargo", {"main": (60, 62, 70)}),
      ["Obrero", "Estibador"], {"Stubble": True}),
    W("Vero", "Dependienta Vero", "Tienda de ropa", kit_vero, (236, 198, 166), (150, 96, 50), ("moda", {"main": (70, 100, 150), "under": (245, 240, 235)}), ("jeans", {"main": (40, 44, 60)}),
      ["Dependienta Vero", "Dependiente"], {"Lash": True, "Lip": (200, 90, 110)}),
]


# ====================================================================== MULTITUD (mallas compartidas, sin textura)
CROWD_PARTS = {}  # nombre -> (parte, material de Roblox, etiqueta)


def kit_multitud(K):
    """Todas las piezas de la gente de la calle, UNA vez cada una (se tiñen en el juego)."""
    plain = K.mat("liso", G.mat_plain, (0.8, 0.8, 0.8), 0.6)
    A.head_block(K, (220, 220, 220))
    hm = plain
    styles = [
        ("PeloCorto", lambda n: hair_short(K, hm, seed=41, length=0.32, name=n, label="Pelo corto")),
        ("PeloPeinado", lambda n: hair_swept(K, hm, name=n, label="Pelo peinado")),
        ("PeloMelena", lambda n: hair_long(K, hm, name=n, label="Melena", length=1.15)),
        ("PeloMono", lambda n: hair_bun(K, hm, name=n, label="Moño")),
        ("PeloColeta", lambda n: hair_ponytail(K, hm, name=n, label="Coleta")),
        ("PeloRizado", lambda n: hair_curly(K, hm, name=n, label="Pelo rizado", n=20, seed=12)),
        ("PeloLados", lambda n: hair_sides(K, hm, name=n, label="Pelo a los lados")),
        ("PeloRapado", lambda n: hair_buzz(K, hm, name=n, label="Pelo rapado")),
        ("PeloAfro", lambda n: hair_curly(K, hm, name=n, label="Pelo afro", n=30, seed=17, size=0.22)),
        ("PeloMelenaCorta", lambda n: hair_long(K, hm, name=n, label="Melena corta", length=0.75, fringe=False)),
    ]
    for name, fn in styles:
        fn(name)
        CROWD_PARTS[name] = ("Head", "Fabric")
    cap_baseball(K, plain, name="Gorra", label="Gorra")
    CROWD_PARTS["Gorra"] = ("Head", "Fabric")
    sunglasses(K, name="GafasSol")
    CROWD_PARTS["GafasSol"] = ("Head", "SmoothPlastic")
    glasses(K, name="Gafas")
    CROWD_PARTS["Gafas"] = ("Head", "SmoothPlastic")
    glasses(K, round_=True, name="GafasRedondas", label="Gafas redondas")
    CROWD_PARTS["GafasRedondas"] = ("Head", "SmoothPlastic")
    # mochila
    bag = G.rbox("MochilaCuerpo", (0, -0.85, 3.15), (1.3, 0.5, 1.3), bevel=0.2, segs=2)
    G.assign(bag, plain)
    straps = []
    for sx in (-1, 1):
        st = G.loft(f"MochilaAsa{sx}", G.path_rings([(sx * 0.55, -0.6, 3.85), (sx * 0.55, -0.05, 4.05), (sx * 0.58, 0.55, 3.85), (sx * 0.6, 0.56, 2.9)], [(0.12, 0.035)] * 4, sq=3.0), segs=6)
        G.assign(st, plain)
        straps.append(st)
    K.add("Mochila", [bag] + straps, "UpperTorso", texel=0.6, label="Mochila")
    CROWD_PARTS["Mochila"] = ("UpperTorso", "Fabric")
    # bolso al hombro
    b = G.rbox("BolsoCuerpo", (1.1, 0.05, 2.35), (0.28, 0.7, 0.55), bevel=0.1, segs=2)
    G.assign(b, plain)
    s2 = G.loft("BolsoCorrea", G.path_rings([(1.1, 0.0, 2.6), (1.05, 0.45, 3.4), (0.6, 0.3, 4.03), (0.6, -0.3, 4.03), (1.05, -0.45, 3.4), (1.1, -0.1, 2.6)], [(0.06, 0.02)] * 6, sq=3.0), segs=6)
    G.assign(s2, plain)
    K.add("Bolso", [b, s2], "UpperTorso", texel=0.5, label="Bolso")
    CROWD_PARTS["Bolso"] = ("UpperTorso", "Fabric")
    # auriculares (diadema ancha y dos cascos)
    pts = [HEAD_C + Vector((math.sin(a) * 0.74, 0, 0.1 + math.cos(a) * 0.74)) for a in [math.radians(-80 + 160 * i / 8) for i in range(9)]]
    band = G.loft("AuricularDiadema", G.path_rings(pts, [(0.06, 0.1)] * 9, sq=3.0), segs=6)
    G.assign(band, plain)
    cups = []
    for sx in (-1, 1):
        cup = G.rbox(f"AuricularCasco{sx}", HEAD_C + Vector((sx * 0.72, 0, 0.0)), (0.16, 0.36, 0.42), bevel=0.07, segs=2)
        G.assign(cup, plain)
        cups.append(cup)
    K.add("Auriculares", [band] + cups, "Head", texel=0.4, label="Auriculares")
    CROWD_PARTS["Auriculares"] = ("Head", "SmoothPlastic")
    # bufanda
    sc = A.box_shell("BufandaVuelta", (0, 0), (0.62, 0.52), 3.86, 4.12, sq=3.2, segs=20, thick=0.08)
    G.assign(sc, plain)
    tail = G.rbox("BufandaCaida", (0.3, 0.6, 3.6), (0.26, 0.08, 0.5), bevel=0.04, segs=1)
    G.assign(tail, plain)
    K.add("Bufanda", [sc, tail], "UpperTorso", texel=0.4, label="Bufanda")
    CROWD_PARTS["Bufanda"] = ("UpperTorso", "Fabric")
    A.boots(K, (200, 200, 200), (60, 60, 60), name="Zapatilla")
    for nm in ("ZapatillaR", "ZapatillaL"):
        CROWD_PARTS[nm] = ("RightFoot" if nm.endswith("R") else "LeftFoot", "SmoothPlastic")
    CROWD_PARTS["CabezaBloque"] = ("Head", "SmoothPlastic")


MULTITUD_SPEC = {"Key": "Multitud", "Name": "Gente de la calle", "Cast": "Multitud", "Hero": False, "Kit": kit_multitud, "Skin": (220, 220, 220),
                 "Hair": (60, 40, 30), "Faces": [], "Untextured": True, "Shirt": None, "Pants": None}

SKINS = [(255, 219, 180), (241, 194, 150), (224, 172, 125), (198, 140, 100), (160, 110, 76), (120, 80, 54), (92, 60, 40)]
HAIRS = [(30, 24, 20), (70, 45, 25), (120, 80, 40), (200, 160, 90), (20, 20, 22), (150, 60, 30), (190, 190, 195), (230, 230, 232)]


def P(n, style, hair, skin, shirt, pants, extra=(), face=None, old=False, fem=False, shoes=(240, 240, 240)):
    return {"Key": f"Multitud_{n:02d}", "Style": style, "Hair": HAIRS[hair], "Skin": SKINS[skin], "Shirt": shirt, "Pants": pants,
            "Extra": list(extra), "Face": face or {}, "Old": old, "Fem": fem, "Shoes": shoes}


# (≤ 3 accesorios además de la cabeza: pelo + 2 como mucho; los zapatos van pintados en la plantilla)
PEOPLE = [
    P(1, "PeloCorto", 1, 1, ("camiseta", {"main": (200, 60, 60), "deco": "estrella"}), ("jeans", {"main": (50, 62, 100)}), [("Mochila", (40, 90, 160))]),
    P(2, "PeloMelena", 0, 2, ("vestido", {"main": (200, 80, 120), "stripe": (250, 250, 250)}), ("falda", {"main": (200, 80, 120)}), [("Bolso", (150, 100, 70))], {"Lash": True, "Lip": (200, 90, 100)}, fem=True),
    P(3, "PeloPeinado", 4, 4, ("camisa", {"main": (200, 220, 240), "deco": "rayas"}), ("trousers", {"main": (60, 60, 70)}), [("GafasSol", None)]),
    P(4, "PeloMono", 5, 0, ("sudadera", {"main": (90, 160, 120), "stripe": (240, 240, 240)}), ("track", {"main": (40, 40, 50), "stripe": (240, 240, 240)}), [("Auriculares", (30, 30, 34))], {"Lash": True, "Freckles": True}, fem=True),
    P(5, "PeloLados", 6, 1, ("chaleco_mayor", {"main": (90, 80, 70), "under": (225, 225, 220)}), ("trousers", {"main": (80, 76, 70)}), [("GafasRedondas", (60, 50, 40))], {"Wrinkles": True, "Mustache": (200, 200, 205), "Brow": (200, 200, 205)}, old=True),
    P(6, "PeloColeta", 3, 1, ("camiseta", {"main": (250, 200, 60), "deco": "circulo", "stripe": (250, 250, 250)}), ("jeans", {"main": (60, 80, 140)}), [("Gorra", (40, 90, 170))], {"Lash": True}, fem=True),
    P(7, "PeloRapado", 4, 5, ("chaqueta", {"main": (40, 40, 46), "under": (240, 240, 240)}), ("jeans", {"main": (30, 34, 50)}), [("Auriculares", (220, 60, 60))], {"Stubble": True}),
    P(8, "PeloRizado", 2, 2, ("camisa", {"main": (130, 160, 90), "sleeves": "short"}), ("cargo", {"main": (110, 96, 70)}), [("Mochila", (200, 120, 40))]),
    P(9, "PeloAfro", 4, 6, ("sudadera", {"main": (230, 120, 40)}), ("jeans", {"main": (40, 50, 80)}), [], {"Lash": True, "Lip": (150, 70, 70)}, fem=True),
    P(10, "PeloMelenaCorta", 0, 3, ("rebeca_mayor", {"main": (150, 120, 170), "under": (240, 235, 225)}), ("trousers", {"main": (90, 80, 90)}), [("Gafas", (120, 90, 60)), ("Bolso", (110, 60, 90))], {"Wrinkles": True, "Lip": (190, 100, 110)}, old=True, fem=True),
    P(11, "PeloCorto", 0, 0, ("camiseta", {"main": (60, 110, 200), "deco": "raya", "stripe": (245, 245, 245)}), ("jeans", {"main": (50, 62, 100)}), [("Gorra", (200, 50, 50))], {"Freckles": True}),
    P(12, "PeloMelena", 3, 0, ("chaqueta", {"main": (120, 80, 50), "under": (245, 240, 230)}), ("jeans", {"main": (40, 44, 60)}), [("GafasSol", None), ("Bolso", (40, 40, 44))], {"Lash": True, "Lip": (200, 90, 100)}, fem=True),
    P(13, "PeloPeinado", 1, 2, ("traje", {"main": (70, 80, 110), "under": (240, 240, 240), "tie": (150, 40, 50)}), ("trousers", {"main": (40, 44, 60)}), [("Gafas", (30, 30, 34))]),
    P(14, "PeloMono", 0, 5, ("camisa", {"main": (240, 240, 240)}), ("falda", {"main": (40, 50, 90)}), [("Bufanda", (200, 60, 70))], {"Lash": True, "Lip": (170, 70, 80)}, fem=True),
    P(15, "PeloLados", 7, 3, ("chaqueta", {"main": (70, 90, 70), "under": (230, 225, 210)}), ("trousers", {"main": (70, 64, 60)}), [("Gorra", (90, 86, 70))], {"Wrinkles": True, "Brow": (230, 230, 232)}, old=True),
    P(16, "PeloColeta", 5, 2, ("camiseta", {"main": (90, 180, 170), "deco": "hoja", "stripe": (250, 250, 250)}), ("track", {"main": (60, 60, 70), "stripe": (90, 180, 170)}), [("Mochila", (90, 180, 170))], {"Lash": True, "Freckles": True}, fem=True),
    P(17, "PeloRizado", 0, 6, ("camisa", {"main": (240, 200, 90)}), ("jeans", {"main": (50, 62, 100)}), [("GafasSol", None)], {"Stubble": True}),
    P(18, "PeloCorto", 3, 1, ("sudadera", {"main": (150, 80, 170), "stripe": (250, 210, 60)}), ("jeans", {"main": (40, 50, 80)}), [("Auriculares", (240, 240, 240))]),
    P(19, "PeloMelenaCorta", 1, 4, ("vestido", {"main": (60, 120, 190), "stripe": (250, 230, 120)}), ("falda", {"main": (60, 120, 190)}), [("Gafas", (200, 60, 90))], {"Lash": True, "Lip": (190, 80, 90)}, fem=True),
    P(20, "PeloPeinado", 2, 0, ("camiseta", {"main": (40, 40, 46), "deco": "estrella", "stripe": (240, 240, 240)}), ("cargo", {"main": (90, 100, 80)}), [("Bufanda", (210, 180, 60))]),
    P(21, "PeloAfro", 0, 5, ("chaqueta", {"main": (200, 60, 60), "under": (40, 40, 44)}), ("jeans", {"main": (30, 34, 50)}), [("GafasSol", None)]),
    P(22, "PeloMono", 6, 2, ("rebeca_mayor", {"main": (110, 140, 190), "under": (245, 240, 225)}), ("falda", {"main": (90, 80, 100)}), [("GafasRedondas", (150, 115, 70))], {"Wrinkles": True, "Lip": (190, 100, 110)}, old=True, fem=True),
    P(23, "PeloRapado", 0, 3, ("camiseta", {"main": (245, 245, 245), "deco": "raya", "stripe": (200, 50, 50)}), ("track", {"main": (40, 60, 120), "stripe": (245, 245, 245)}), [("Gorra", (30, 30, 34)), ("Mochila", (30, 30, 34))]),
    P(24, "PeloColeta", 4, 4, ("camisa", {"main": (220, 120, 140), "sleeves": "short"}), ("jeans", {"main": (60, 80, 140)}), [("Bolso", (240, 240, 240))], {"Lash": True, "Lip": (190, 80, 90)}, fem=True),
]
