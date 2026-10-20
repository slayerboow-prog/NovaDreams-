"""Los Vórtidos «de cristal» (hojas del dueño: docs/invasion/referencia-cristal/soldado-360.png y
lider-y-nave.png): el soldado, sus variantes, el líder y la nave «Clase: Guardián», como rigs de
segmentos rígidos (lo mismo que scripts/invasion/alien_diseno.py, que hizo los Vórtidos de antes).

Lo que manda la hoja (y se comprueba con las hojas de comparación, scripts/invasion/vortidos_blender.py):
    * humanoide alto y delgado, sin género: traje acorazado NEGRO mate con costuras de neón cian
    * cabeza: máscara negra sin cara con un visor estrecho en «V» que brilla, coronada por un racimo de
      esquirlas de cristal cian pálido que suben y se echan atrás como una llama
    * un racimo grande de cristal en la espalda (alas a los lados de la cabeza y puntas hacia atrás)
    * antebrazos con esquirla y manos de 3 garras de cristal; pies de cristal (3 dedos y espolón),
      esquirla en la rodilla; un faldón negro en punta delante
    * proporciones del soldado (alto 6 con la corona): suela 0 · tobillo 0,56 · rodilla 1,2 ·
      entrepierna 1,92 · cintura 2,72 · hombros 3,6 · barbilla 4,05 · visor 4,45 · corona hasta 6

Cada segmento lleva TRES mallas: la principal (textura PBR horneada: armadura negra, juntas, blanco del
líder y la nave, capa), la de cristal («<Seg>Cristal»: Glass cian pálido en Roblox, facetada) y la de
brillo («<Seg>Brillo»: Neon cian: costuras, visor, núcleos dentro de los cristales, motores).

Segmentos de las tropas: Body, Head, ArmL/ArmR (brazo), ForeArmL/ForeArmR (antebrazo y mano: el codo),
LegL/LegR (muslo), LowerLegL/LowerLegR (pierna y pie: la rodilla). El líder además: Cape, Cape2, Cape3
(la capa en 3 bandas encadenadas que se mecen) y Scepter (el cetro, colgado de la mano derecha).
Coordenadas de Roblox (X derecha, Y arriba, el frente a -Z); las tropas, con los pies en y = 0.
"""
import math

from mathutils import Vector

from geo import MeshBuilder, catmull
import alien_geo as G
import alien_diseno as D

RACE = "Vortidos"
ASSET = "VortidosCristal"  # prefijo de los archivos y de los ids subidos (los de antes eran «Vortidos_*»)

# Paleta de la hoja (cristal principal #8EE6FF, secundario #C9F2FF, cuerpo #1A1D22, neón #2FD8FF)
def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


PAL = {
    "Cristal": hexc("8EE6FF"),
    "Cristal2": hexc("C9F2FF"),
    "Cuerpo": hexc("1A1D22"),
    "Junta": hexc("2A2F37"),
    "Neon": hexc("2FD8FF"),
    "Visor": hexc("7FF4FF"),
    "Blanco": hexc("E6EEF3"),
    "Capa": hexc("EAF3FA"),
    "CapaAzul": hexc("1E5FA8"),
    "Cabina": hexc("0A1430"),
}

# Materiales (nombres de Blender: se hornean al atlas de su juego de texturas)
M_CUERPO, M_JUNTA, M_BLANCO, M_CAPA, M_CAPA_AZUL, M_CABINA = "VC_cuerpo", "VC_junta", "VC_blanco", "VC_capa", "VC_capa_azul", "VC_cabina"
M_CRISTAL, M_BRILLO = "VC_cristal", "brillo"

HEIGHTS = {"Grunt": 6, "Heavy": 9, "Ranged": 7, "Elite": 11, "King": 11}
WIDE = {"Grunt": 1.0, "Heavy": 1.2, "Ranged": 0.94, "Elite": 1.04, "King": 1.0}
ATTACK = {"Grunt": "Claw", "Heavy": "Claw", "Ranged": "Rifle", "Elite": "Claw", "King": "Scepter"}


class Seg(D.Seg):
    def __init__(self, rig, name, pivot, parent):
        super().__init__(rig, name, pivot, parent)
        self.B, self.T = M_CUERPO, M_JUNTA
        self.m = MeshBuilder([M_CUERPO, M_JUNTA, M_BLANCO, M_CAPA, M_CAPA_AZUL, M_CABINA])
        self.c = MeshBuilder([M_CRISTAL])
        self.g = MeshBuilder([M_BRILLO])


class Rig(D.Rig):
    def __init__(self, kind, height, gait, category):
        super().__init__(RACE, kind, height, gait, category)
        self.attack = ATTACK.get(kind, "")
        self.extra = {}

    @property
    def asset(self):
        return f"{ASSET}_{self.kind}"

    def seg(self, name, pivot=(0, 0, 0), parent="Root"):
        if name not in self.segs:
            self.segs[name] = Seg(self, name, pivot, parent)
        return self.segs[name]

    def transform(self, fn):
        for s in self.segs.values():
            s.m.verts = [fn(v) for v in s.m.verts]
            s.c.verts = [fn(v) for v in s.c.verts]
            s.g.verts = [fn(v) for v in s.g.verts]
            s.pivot = fn(s.pivot)


def xform_seg(seg, fn):
    seg.m.verts = [fn(v) for v in seg.m.verts]
    seg.c.verts = [fn(v) for v in seg.c.verts]
    seg.g.verts = [fn(v) for v in seg.g.verts]
    seg.pivot = fn(seg.pivot)


# ====================================================================== geometría
def spow(x, e):
    return math.copysign(abs(x) ** e, x)


def ring_v(c, hx, hzf, hzb, segs, p=2.4, mod=None):
    """Sección horizontal (superelipse) alrededor de c: a = 0 delante (-Z), crece hacia +X."""
    out = []
    for k in range(segs):
        a = 2 * math.pi * k / segs
        s, co = math.sin(a), math.cos(a)
        hz = hzf if co > 0 else hzb
        f = mod(a) if mod else 1.0
        out.append(Vector(c) + Vector((hx * spow(s, 2 / p) * f, 0, -hz * spow(co, 2 / p) * f)))
    return out


def vertical_loft(mb, stations, mat, segs=24, step=0.06, mod=None, matfn=None):
    """stations: (y, cz, hx, hzf, hzb, p) de abajo arriba -> anillos suaves (Catmull-Rom). Devuelve los
    anillos y los centros (para poner costuras y placas encima)."""
    dense = []
    for i in range(len(stations) - 1):
        n = max(1, int(math.ceil(abs(stations[i + 1][0] - stations[i][0]) / step)))
        for k in range(n):
            dense.append(catmull(stations, i + k / n))
    dense.append(tuple(stations[-1]))
    rings, centers = [], []
    for y, cz, hx, hzf, hzb, p in dense:
        c = Vector((0, y, cz))
        rings.append(ring_v(c, max(hx, 0.004), max(hzf, 0.004), max(hzb, 0.004), segs, p, (lambda a, y=y: mod(a, y)) if mod else None))
        centers.append(c)
    mb.loft(rings, mat, True, True, matfn)
    return rings, centers


def path_frames(pts, hint):
    hint = Vector(hint).normalized()
    out = []
    for i, p in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        t = (b - a).normalized()
        f = hint - t * hint.dot(t)
        if f.length < 1e-4:
            f, _ = G.frame_for(t)
        f.normalize()
        s = t.cross(f).normalized()
        out.append((t, f, s))
    return out


def limb_loft(mb, pts, rads, mat, segs=12, hint=(0, 0, -1), p=2.2, steps=3, caps=True):
    """Brazo, pierna o cuello: tubo suave por los puntos (Catmull-Rom) con secciones de superelipse
    (rw de lado, rd de delante, orientadas con hint). rads: [(rw, rd)] o [(rw, rdf, rdb)] por punto."""
    pts = [Vector(q) for q in pts]
    rads = [tuple(r) if len(r) == 3 else (r[0], r[1], r[1]) for r in rads]
    dense, drad = [], []
    for i in range(len(pts) - 1):
        for k in range(steps):
            t = i + k / steps
            dense.append(Vector(catmull([tuple(q) for q in pts], t)))
            drad.append(catmull(rads, t))
    dense.append(pts[-1])
    drad.append(rads[-1])
    frames = path_frames(dense, hint)
    rings = []
    for (t, f, s), c, (rw, rdf, rdb) in zip(frames, dense, drad):
        ring = []
        for k in range(segs):
            a = 2 * math.pi * k / segs
            sa, ca = math.sin(a), math.cos(a)
            rd = rdf if ca > 0 else rdb
            ring.append(c + s * (rw * spow(sa, 2 / p)) + f * (rd * spow(ca, 2 / p)))
        rings.append(ring)
    mb.loft(rings, mat, caps, caps)
    return rings, dense


def on_rings(rings, centers, i, a, off=0.02):
    """Punto de la superficie (anillo i, ángulo a en vueltas 0..1) un poco hacia fuera."""
    ring = rings[max(0, min(i, len(rings) - 1))]
    n = len(ring)
    s = (a % 1.0) * n
    k = int(math.floor(s))
    f = s - k
    p = ring[k % n].lerp(ring[(k + 1) % n], f)
    c = centers[max(0, min(i, len(centers) - 1))]
    d = p - c
    d.y *= 0.0
    if d.length < 1e-5:
        return p
    return p + d.normalized() * off


def seam(g, pts, r=0.022, segs=4):
    """Costura de neón (tubo fino) por unos puntos de la superficie."""
    if len(pts) < 2:
        return
    G.tube(g, pts, [r] * len(pts), M_BRILLO, segs)


def seam_rings(g, rings, centers, i0, i1, a0, a1=None, r=0.016, off=0.016, step=2):
    a1 = a0 if a1 is None else a1
    idx = list(range(i0, i1 + 1, step)) if i1 >= i0 else list(range(i0, i1 - 1, -step))
    if len(idx) < 2:
        idx = [i0, i1]
    pts = [on_rings(rings, centers, i, a0 + (a1 - a0) * (j / max(1, len(idx) - 1)), off) for j, i in enumerate(idx)]
    seam(g, pts, r)


def plate(mb, rings, centers, i0, i1, a0, a1, mat, lift=0.03, thick=0.035, na=6):
    """Placa de armadura que sigue la superficie (anillos i0..i1, ángulos a0..a1 en vueltas): una losa
    con canto, un poco por encima (se ve la junta entre placas)."""
    rows = list(range(i0, i1 + 1))
    top, bot = [], []
    for i in rows:
        rt, rb = [], []
        for j in range(na + 1):
            a = a0 + (a1 - a0) * j / na
            rt.append(on_rings(rings, centers, i, a, lift + thick))
            rb.append(on_rings(rings, centers, i, a, lift - 0.01))
        top.append(rt)
        bot.append(rb)
    T = [[mb.v(p) for p in r] for r in top]
    B = [[mb.v(p) for p in r] for r in bot]
    for i in range(len(rows) - 1):
        for j in range(na):
            mb.face([T[i][j], T[i][j + 1], T[i + 1][j + 1], T[i + 1][j]], mat)
            mb.face([B[i][j], B[i + 1][j], B[i + 1][j + 1], B[i][j + 1]], mat)
    for i in range(len(rows) - 1):
        mb.face([T[i][0], T[i + 1][0], B[i + 1][0], B[i][0]], mat)
        mb.face([T[i][-1], B[i][-1], B[i + 1][-1], T[i + 1][-1]], mat)
    for j in range(na):
        mb.face([T[0][j], B[0][j], B[0][j + 1], T[0][j + 1]], mat)
        mb.face([T[-1][j], T[-1][j + 1], B[-1][j + 1], B[-1][j]], mat)


def shard(c, g, a, b, r, sides=5, tip=0.42, base=0.16, twist=0.0, flat=1.0, core=False):
    """Esquirla de cristal facetada (c = malla de cristal) y, si core, un núcleo que brilla dentro.
    (las pequeñas, de 4 caras: no se nota y ahorra triángulos)"""
    if r < 0.16 and sides > 4:
        sides = 4
    G.crystal(c, a, b, r, M_CRISTAL, sides=sides, tip=tip, base=base, twist=twist, flat=flat)
    if core and g is not None:
        a, b = Vector(a), Vector(b)
        G.crystal(g, a + (b - a) * 0.12, a + (b - a) * 0.8, r * 0.38, M_BRILLO, sides=4, tip=0.5, base=0.2, twist=twist, flat=flat)


def mirror(p, side):
    return Vector((p[0] * side, p[1], p[2]))


# ====================================================================== el soldado (y sus variantes)
TORSO = [  # (y, cz, hx, hzf, hzb, p): de la entrepierna al cuello (alto 6); pecho adelante, cadera atrás
    (1.93, 0.05, 0.10, 0.10, 0.10, 2.0),
    (2.02, 0.06, 0.32, 0.20, 0.22, 2.2),
    (2.15, 0.07, 0.45, 0.24, 0.33, 2.3),
    (2.32, 0.06, 0.46, 0.25, 0.32, 2.3),
    (2.50, 0.03, 0.40, 0.23, 0.27, 2.4),
    (2.70, 0.00, 0.34, 0.23, 0.24, 2.4),
    (2.90, -0.03, 0.40, 0.27, 0.25, 2.4),
    (3.10, -0.06, 0.50, 0.31, 0.26, 2.5),
    (3.30, -0.08, 0.58, 0.33, 0.27, 2.6),
    (3.48, -0.07, 0.64, 0.31, 0.28, 2.8),
    (3.62, -0.05, 0.58, 0.26, 0.27, 2.6),
    (3.73, -0.04, 0.38, 0.20, 0.22, 2.3),
    (3.79, -0.04, 0.18, 0.15, 0.15, 2.0),
    (3.81, -0.04, 0.02, 0.02, 0.02, 2.0),
]
HEAD = [  # (y, cz, hx, hzf, hzb, p): de la barbilla a la coronilla
    (3.99, -0.42, 0.04, 0.04, 0.04, 2.0),
    (4.06, -0.40, 0.21, 0.19, 0.19, 2.2),
    (4.18, -0.36, 0.35, 0.31, 0.29, 2.4),
    (4.32, -0.33, 0.46, 0.37, 0.35, 2.6),
    (4.46, -0.31, 0.50, 0.39, 0.38, 2.6),
    (4.60, -0.29, 0.49, 0.38, 0.39, 2.4),
    (4.72, -0.27, 0.42, 0.35, 0.37, 2.2),
    (4.82, -0.25, 0.31, 0.28, 0.31, 2.0),
    (4.89, -0.24, 0.16, 0.15, 0.17, 2.0),
    (4.91, -0.24, 0.02, 0.02, 0.02, 2.0),
]


def chest_mod(a, y):
    """Pectorales y el surco del esternón (solo delante, a la altura del pecho)."""
    w = max(0.0, 1 - abs(y - 3.28) / 0.28)
    if w <= 0:
        return 1.0
    ca = math.cos(a)
    if ca <= 0:
        return 1.0
    pecs = 0.05 * math.exp(-((abs(math.sin(a)) - 0.42) / 0.25) ** 2) * ca
    groove = -0.035 * math.exp(-(math.sin(a) / 0.1) ** 2) * ca
    return 1.0 + w * (pecs + groove)


def soldier(rig, kind):
    heavy, ranged, elite, king = kind == "Heavy", kind == "Ranged", kind in ("Elite", "King"), kind == "King"
    # ---------------------------------------------------------------- tronco
    body = rig.seg("Body", (0, 2.1, 0.03))
    rings, cen = vertical_loft(body.m, TORSO, M_CUERPO, segs=18, step=0.1, mod=chest_mod)
    yi = lambda y: min(range(len(cen)), key=lambda i: abs(cen[i].y - y))
    # placas: pecho, abdomen (2), pelvis, espalda
    plate(body.m, rings, cen, yi(3.08), yi(3.55), -0.2, 0.2, M_CUERPO, lift=0.012, thick=0.03, na=6)
    plate(body.m, rings, cen, yi(2.78), yi(2.97), -0.12, 0.12, M_JUNTA, lift=0.01, thick=0.025, na=5)
    plate(body.m, rings, cen, yi(2.52), yi(2.7), -0.11, 0.11, M_JUNTA, lift=0.01, thick=0.025, na=5)
    plate(body.m, rings, cen, yi(2.12), yi(2.42), 0.3, 0.7, M_CUERPO, lift=0.01, thick=0.03, na=5)
    plate(body.m, rings, cen, yi(3.0), yi(3.5), 0.36, 0.64, M_CUERPO, lift=0.01, thick=0.03, na=4)
    for side in (-1, 1):  # placas de la cadera
        a = 0.25 if side > 0 else 0.75
        plate(body.m, rings, cen, yi(2.08), yi(2.4), a - 0.07, a + 0.07, M_JUNTA, lift=0.012, thick=0.03, na=4)
    # faldón negro en punta delante
    G.fin(body.m, [Vector((-0.15, 2.08, -0.29)), Vector((0.15, 2.08, -0.29)), Vector((0.02, 1.56, -0.27)), Vector((-0.02, 1.56, -0.27))], (0, 0, 1), 0.05, M_JUNTA)
    # costuras de neón: esternón, abdomen, costados, ingle en V, columna, puntos del pecho
    seam_rings(body.g, rings, cen, yi(2.98), yi(3.6), 0.0, r=0.02, step=1)
    seam_rings(body.g, rings, cen, yi(2.6), yi(2.74), 0.0, r=0.018, off=0.035, step=1)
    for side in (-1, 1):
        a = 0.25 if side > 0 else 0.75
        seam_rings(body.g, rings, cen, yi(2.55), yi(3.15), a + side * -0.03, a + side * 0.02, r=0.014)
        G.blob(body.g, on_rings(rings, cen, yi(3.48), 0.08 * side % 1.0, 0.03), (0.04, 0.04, 0.04), M_BRILLO, nu=6, nv=4)
        seam_rings(body.g, rings, cen, yi(3.18), yi(3.42), (0.13 * side) % 1.0, (0.2 * side) % 1.0, r=0.016)
    seam_rings(body.g, rings, cen, yi(2.4), yi(3.3), 0.5, r=0.022)
    # ---------------------------------------------------------------- racimo de cristal de la espalda
    k = 1.22 if heavy else (1.1 if elite else 1.0)
    root = Vector((0, 3.5, 0.28))
    back = [  # (base, punta, radio, núcleo): alas a los lados de la cabeza y puntas hacia atrás
        ((0.30, 3.56, 0.30), (1.00, 4.78, 0.58), 0.30, True),
        ((0.34, 3.46, 0.30), (1.10, 4.22, 0.62), 0.26, False),
        ((0.34, 3.36, 0.30), (0.98, 3.86, 0.56), 0.22, False),
        ((0.42, 3.50, 0.30), (1.22, 4.52, 0.36), 0.18, False),
        ((0.15, 3.62, 0.34), (0.38, 5.05, 0.95), 0.26, True),
        ((0.20, 3.72, 0.30), (0.56, 5.22, 0.62), 0.22, False),
        ((0.22, 3.40, 0.30), (0.48, 3.92, 1.22), 0.22, False),
        ((0.25, 3.70, 0.26), (0.64, 4.45, 0.42), 0.16, False),
        ((0.12, 3.44, 0.27), (0.22, 3.80, 0.55), 0.26, False),
    ]
    center = [
        ((0.0, 3.62, 0.36), (0.0, 5.35, 0.75), 0.32, True),
        ((0.0, 3.50, 0.33), (0.0, 4.24, 1.34), 0.28, True),
        ((0.0, 3.48, 0.31), (0.0, 2.98, 0.58), 0.25, False),
        ((0.0, 3.40, 0.30), (0.0, 3.70, 0.70), 0.30, False),
    ]

    def grow(p):
        return root + (Vector(p) - root) * k

    if king:  # (el líder no lleva racimo: capa y capucha)
        back, center = [], [((0.0, 3.5, 0.3), (0.0, 4.05, 0.62), 0.2, False)]
    for side in (-1, 1):
        for i, (a, b, r, core) in enumerate(back):
            shard(body.c, body.g, grow(mirror(a, side)), grow(mirror(b, side)), r * k, sides=5 + (i % 2), twist=0.3 * i + (0.2 if side > 0 else 0), flat=0.8, core=core)
    for i, (a, b, r, core) in enumerate(center):
        shard(body.c, body.g, grow(a), grow(b), r * k, sides=6, twist=0.5 * i, flat=0.85, core=core)
    if heavy:  # Monolito: placas de cristal en el pecho
        for side in (-1, 1):
            shard(body.c, body.g, (side * 0.24, 3.0, -0.33), (side * 0.3, 3.58, -0.37), 0.17, sides=4, tip=0.3, base=0.25, flat=0.38)
    if elite and not king:  # Custodio: emblema de cristal en el pecho
        shard(body.c, body.g, (0, 3.0, -0.36), (0, 3.52, -0.4), 0.13, sides=4, tip=0.45, base=0.4, flat=0.4, core=True)
    # ---------------------------------------------------------------- cabeza: máscara, visor y corona
    head = rig.seg("Head", (0, 3.78, 0.0), "Body")
    limb_loft(head.m, [(0, 3.7, -0.03), (0, 3.86, -0.1), (0, 4.04, -0.25)], [(0.15, 0.14), (0.13, 0.12), (0.12, 0.11)], M_JUNTA, segs=10, hint=(0, 0, -1))
    hr, hc = vertical_loft(head.m, HEAD, M_CUERPO, segs=18, step=0.075)
    G.blob(body.m, (0, 3.76, -0.03), (0.27, 0.12, 0.24), M_JUNTA, nu=12, nv=5)
    hyi = lambda y: min(range(len(hc)), key=lambda i: abs(hc[i].y - y))
    # visor en «V»: dos rendijas que bajan hacia el centro
    for side in (-1, 1):
        pts = []
        for j in range(7):
            t = j / 6
            a = (0.025 + 0.12 * t) * side
            y = 4.395 + 0.1 * t
            i = hyi(y)
            pts.append(on_rings(hr, hc, i, a % 1.0, 0.012) + Vector((0, y - hc[i].y, 0)))
        G.tube(head.g, pts, [0.05 + 0.012 * math.sin(math.pi * j / 6) for j in range(7)], M_BRILLO, 6, squash=0.55)
    # mentón de cristal (la parte baja de la cara, pálida)
    shard(head.c, None, (0, 4.03, -0.53), (0, 4.31, -0.67), 0.22, sides=4, tip=0.3, base=0.35, flat=0.35)
    # corona: esquirlas que suben desde la frente y se echan atrás como una llama
    s = 1.18 if elite and not king else 1.0
    base_c = Vector((0, 4.62, -0.33))
    crown = [  # (base, punta, radio, núcleo)
        ((0.0, 4.58, -0.55), (0.0, 6.0, 0.08), 0.27, True),
        ((0.20, 4.62, -0.47), (0.37, 5.78, 0.10), 0.23, True),
        ((0.34, 4.58, -0.34), (0.60, 5.40, -0.02), 0.20, False),
        ((0.44, 4.50, -0.20), (0.72, 5.06, 0.06), 0.17, False),
        ((0.14, 4.80, -0.14), (0.25, 5.62, 0.76), 0.22, True),
        ((0.29, 4.70, -0.04), (0.52, 5.10, 0.88), 0.18, False),
        ((0.33, 4.48, 0.00), (0.60, 4.66, 0.74), 0.15, False),
        ((0.47, 4.40, -0.18), (0.68, 4.80, 0.22), 0.13, False),
        ((0.10, 4.70, -0.40), (0.16, 5.45, -0.30), 0.18, False),
        ((0.46, 4.32, -0.30), (0.74, 4.95, -0.22), 0.12, False),
    ]
    mid = [((0.0, 4.76, -0.06), (0.0, 5.42, 0.98), 0.22, False)]
    if elite and not king:
        crown += [((0.08, 4.7, -0.34), (0.15, 6.28, -0.08), 0.17, True), ((0.44, 4.6, -0.34), (0.82, 5.66, -0.18), 0.14, False)]

    def crown_p(p):
        return base_c + (Vector(p) - base_c) * s

    for side in (-1, 1):
        for i, (a, b, r, core) in enumerate(crown):
            if abs(a[0]) < 1e-6 and side < 0:
                continue
            shard(head.c, head.g, crown_p(mirror(a, side)), crown_p(mirror(b, side)), r * s, sides=5 + (i % 2), twist=0.35 * i, flat=0.75, core=core)
    for a, b, r, core in mid:
        shard(head.c, head.g, crown_p(a), crown_p(b), r * s, sides=5, twist=0.2, flat=0.8, core=core)
    # ---------------------------------------------------------------- brazos (hombro, codo, mano de 3 garras)
    for side, an, fn in ((-1, "ArmL", "ForeArmL"), (1, "ArmR", "ForeArmR")):
        sp = Vector((side * 0.68, 3.55, -0.04))
        el = Vector((side * 0.98, 2.86, 0.02))
        armed = ranged and side == 1
        holds = king and side == 1
        if armed:  # el tirador apunta: el antebrazo hacia delante
            wr = el + Vector((side * -0.08, 0.06, -0.52))
        elif holds:  # el líder sujeta el cetro
            wr = el + Vector((side * 0.06, -0.3, -0.42))
        else:
            wr = Vector((side * 1.16, 2.38, -0.1))
        arm = rig.seg(an, sp, "Body")
        limb_loft(arm.m, [sp + Vector((side * -0.04, 0.05, 0)), sp.lerp(el, 0.5) + Vector((side * 0.02, 0, 0)), el], [(0.18, 0.17), (0.15, 0.15), (0.12, 0.115)], M_CUERPO, segs=10, hint=(0, 0, -1))
        G.blob(arm.m, sp + Vector((side * 0.03, 0.05, 0)), (0.21, 0.19, 0.21), M_JUNTA, nu=10, nv=5, bottom=-0.3)
        G.blob(arm.m, sp + Vector((side * 0.06, 0.1, 0.0)), (0.2, 0.13, 0.23), M_CUERPO, nu=10, nv=4, top=1.0, bottom=0.0)
        seam(arm.g, [sp + Vector((side * 0.16, -0.12, -0.08)), sp.lerp(el, 0.6) + Vector((side * 0.09, 0, -0.08))], 0.018)
        G.blob(arm.g, sp + Vector((side * 0.18, 0.02, -0.06)), (0.035, 0.035, 0.035), M_BRILLO, nu=6, nv=4)
        if (heavy or elite) and not king:  # hombreras de cristal
            shard(arm.c, arm.g, sp + Vector((side * 0.05, 0.12, 0.02)), sp + Vector((side * 0.32, 0.62, 0.14)), 0.12, sides=5, core=heavy)
            shard(arm.c, None, sp + Vector((side * 0.1, 0.05, -0.04)), sp + Vector((side * 0.5, 0.3, -0.12)), 0.1, sides=5)
        fore = rig.seg(fn, el, an)
        G.blob(fore.m, el, (0.125, 0.125, 0.125), M_JUNTA, nu=10, nv=6)
        mid_ = el.lerp(wr, 0.45)
        fr, fd = limb_loft(fore.m, [el, mid_, wr], [(0.12, 0.11), (0.165, 0.155), (0.125, 0.115)], M_CUERPO, segs=10, hint=(0, 0, -1) if not (armed or holds) else (0, 1, 0))
        d = (wr - el).normalized()
        out = Vector((side, 0, 0))
        # brazal y su costura
        seam(fore.g, [el.lerp(wr, 0.2) + out * 0.11 + Vector((0, 0, -0.06)), el.lerp(wr, 0.85) + out * 0.1 + Vector((0, 0, -0.06))], 0.018)
        # esquirla del antebrazo (hacia el codo)
        blade = 1.45 if heavy else (1.2 if elite else 1.0)
        shard(fore.c, fore.g, el.lerp(wr, 0.7) + out * 0.1, el.lerp(wr, 0.7) + out * 0.2 - d * 0.55 * blade + Vector((0, 0, 0.16)), 0.075 * blade, sides=4, tip=0.55, flat=0.6, core=heavy)
        # mano: palma y 3 garras de cristal (y el pulgar)
        palm = wr + d * 0.08
        if holds:
            rig.extra["hand_r"] = Vector(palm)
        G.blob(fore.m, palm, (0.1, 0.12, 0.11), M_JUNTA, nu=10, nv=6)
        if armed:
            rifle(fore, palm, side)
        elif holds:
            for j in range(3):  # garras cerradas alrededor del cetro
                e = Vector((side * 0.06, -0.04 + j * 0.06, 0))
                shard(fore.c, None, palm + e, palm + e + Vector((side * -0.12, -0.05, -0.08)), 0.03, sides=4, tip=0.6)
        else:
            L = 0.66 if not heavy else 0.76
            for j, dx in enumerate((-0.085, 0.0, 0.085)):
                b0 = palm + Vector((side * (0.03 + dx * 0.4), -0.06, -0.04 + dx * 0.7))
                tip = b0 + Vector((side * (0.06 + dx * 1.5), -L, -0.12 + dx * 1.1))
                shard(fore.c, fore.g if j == 1 else None, b0, tip, 0.075, sides=4, tip=0.6, base=0.12, twist=0.4, flat=0.6, core=(j == 1))
            th = palm + Vector((side * -0.07, -0.02, -0.09))
            shard(fore.c, None, th, th + Vector((side * -0.1, -0.3, -0.16)), 0.055, sides=4, tip=0.6)
            # placa de cristal en el dorso de la mano
            shard(fore.c, None, palm + Vector((side * 0.09, 0.1, 0.0)), palm + Vector((side * 0.13, -0.16, -0.03)), 0.08, sides=4, tip=0.5, base=0.3, flat=0.45)
    # ---------------------------------------------------------------- piernas (muslo, rodilla, pie de cristal)
    for side, ln, sn in ((-1, "LegL", "LowerLegL"), (1, "LegR", "LowerLegR")):
        hp = Vector((side * 0.27, 2.1, 0.04))
        kn = Vector((side * 0.44, 1.27, -0.16))
        an_ = Vector((side * 0.6, 0.52, 0.12))
        leg = rig.seg(ln, hp, "Root")
        lr, ld = limb_loft(leg.m, [hp + Vector((side * 0.02, 0.06, 0.0)), hp.lerp(kn, 0.45) + Vector((side * 0.03, 0, -0.03)), kn], [(0.24, 0.25, 0.27), (0.21, 0.22, 0.22), (0.145, 0.145, 0.135)], M_CUERPO, segs=10, hint=(0, 0, -1), steps=4)
        n_ = len(lr)
        plate(leg.m, lr, ld, 2, n_ - 3, 0.88, 1.12, M_CUERPO, lift=0.01, thick=0.03, na=5)
        seam_rings(leg.g, lr, ld, 2, n_ - 3, (1.0 - 0.17 * side) % 1.0, r=0.02)
        seam_rings(leg.g, lr, ld, 3, n_ - 2, (0.25 * side) % 1.0, r=0.018)
        low = rig.seg(sn, kn, ln)
        G.blob(low.m, kn + Vector((0, 0, -0.04)), (0.145, 0.15, 0.135), M_JUNTA, nu=10, nv=6)
        G.blob(low.m, kn + Vector((0, 0.02, -0.14)), (0.12, 0.14, 0.065), M_CUERPO, nu=10, nv=6)  # rodillera
        sr, sd = limb_loft(low.m, [kn, kn.lerp(an_, 0.4) + Vector((side * 0.01, 0, 0.05)), an_, an_ + Vector((0, -0.24, 0.02))], [(0.145, 0.14, 0.14), (0.135, 0.12, 0.18), (0.09, 0.085, 0.085), (0.095, 0.1, 0.095)], M_CUERPO, segs=10, hint=(0, 0, -1), steps=4)
        seam_rings(low.g, sr, sd, 2, len(sr) - 5, 0.0, r=0.018)
        # esquirla de la rodilla (baja hacia delante)
        shard(low.c, low.g, kn + Vector((side * 0.02, -0.08, -0.16)), kn + Vector((side * 0.05, -0.55, -0.3)), 0.075, sides=4, tip=0.5, flat=0.6, core=True)
        # pie de cristal: planta, 3 dedos, espolón y púas del tobillo
        foot = Vector((an_.x, 0.24, an_.z - 0.02))
        shard(low.c, None, foot + Vector((0, 0.08, 0.1)), foot + Vector((0, -0.18, -0.46)), 0.22, sides=5, tip=0.35, base=0.2, flat=0.45)
        for j, dx in enumerate((-0.18, 0.0, 0.18)):
            b0 = foot + Vector((dx * 0.35, -0.08, -0.1))
            shard(low.c, low.g if j == 1 else None, b0, Vector((foot.x + dx * 1.2, 0.04, foot.z - 0.74 + abs(dx) * 0.6)), 0.1, sides=5, tip=0.5, flat=0.55, core=(j == 1))
        shard(low.c, None, foot + Vector((0, -0.04, 0.06)), Vector((foot.x, 0.05, foot.z + 0.46)), 0.09, sides=4, tip=0.55, flat=0.6)
        for j, (dx, dz) in enumerate(((0.09, 0.06), (-0.08, 0.08))):
            b0 = an_ + Vector((side * dx, -0.08, dz))
            shard(low.c, None, b0, b0 + Vector((side * dx * 1.8, 0.32, 0.18)), 0.045, sides=4, tip=0.6)
        if king:  # botas blancas del líder
            limb_loft(low.m, [an_ + Vector((0, 0.28, -0.02)), an_ + Vector((0, -0.05, 0)), an_ + Vector((0, -0.28, -0.08))], [(0.12, 0.12, 0.13), (0.11, 0.12, 0.11), (0.12, 0.17, 0.1)], M_BLANCO, segs=10, hint=(0, 0, -1))
    if king:
        leader_extras(rig)


def rifle(fore, palm, side):
    """El rifle de cristal del Prisma (en la mano derecha, hacia -Z): cuerpo negro con cañones de
    esquirla, núcleo que brilla y la boca."""
    m, c, g = fore.m, fore.c, fore.g
    base = palm + Vector((0, 0.06, -0.05))
    m.box(base + Vector((0, 0.03, -0.25)), (0.16, 0.2, 0.75), M_JUNTA)
    m.box(base + Vector((0, 0.15, -0.1)), (0.1, 0.08, 0.5), M_CUERPO)
    m.box(base + Vector((0, -0.12, 0.06)), (0.09, 0.22, 0.12), M_CUERPO, up=(0, 1, 0.35))
    shard(c, g, base + Vector((0, 0.04, -0.5)), base + Vector((0, 0.04, -1.45)), 0.09, sides=6, tip=0.25, base=0.1, core=True)
    for dx in (-0.08, 0.08):
        shard(c, None, base + Vector((dx, 0.0, -0.35)), base + Vector((dx * 1.6, -0.02, -1.05)), 0.045, sides=4, tip=0.5)
    shard(c, None, base + Vector((0, 0.14, -0.2)), base + Vector((0, 0.32, 0.25)), 0.05, sides=4, tip=0.5)
    G.blob(g, base + Vector((0, 0.04, -1.5)), (0.08, 0.08, 0.08), M_BRILLO, nu=8, nv=5)
    G.torus(g, base + Vector((0, 0.04, -0.55)), (0, 0, 1), 0.11, 0.022, M_BRILLO, n=10, m=4)
    seam(g, [base + Vector((0.085, 0.06, 0.05)), base + Vector((0.085, 0.06, -0.55))], 0.016)
    seam(g, [base + Vector((-0.085, 0.06, 0.05)), base + Vector((-0.085, 0.06, -0.55))], 0.016)


# ====================================================================== el líder (lider-y-nave.png, arriba)
def leader_extras(rig):
    """Hombreras blancas con púas, cuello alto, emblema en «V» del pecho, cristales de los muslos, la capa
    (3 bandas encadenadas) y el cetro (de la mano derecha)."""
    body = rig.segs["Body"]
    # cuello alto blanco y el pecho: dos placas blancas en «V» y el emblema de cristal azul
    for side in (-1, 1):
        G.fin(body.m, [Vector((side * 0.06, 3.62, -0.36)), Vector((side * 0.42, 3.66, -0.3)), Vector((side * 0.3, 3.36, -0.36)), Vector((side * 0.06, 3.2, -0.4))], (0, 0.1, -1), 0.05, M_BLANCO)
        G.fin(body.m, [Vector((side * 0.12, 3.82, -0.12)), Vector((side * 0.3, 3.95, 0.02)), Vector((side * 0.33, 3.72, 0.12)), Vector((side * 0.16, 3.7, -0.16))], (side, 0.3, -0.2), 0.04, M_BLANCO)
    for side in (-1, 1):
        G.fin(body.c, [Vector((side * 0.27, 3.3, -0.4)), Vector((side * 0.15, 3.3, -0.42)), Vector((0.0, 2.86, -0.38)), Vector((0.0, 2.7, -0.35))], (0, 0, -1), 0.06, M_CRISTAL)
        seam(body.g, [Vector((side * 0.2, 3.26, -0.44)), Vector((0.0, 2.82, -0.4))], 0.016)
    for side in (-1, 1):  # cristales de los muslos (rombos)
        leg = rig.segs["LegL" if side < 0 else "LegR"]
        shard(leg.c, leg.g, (side * 0.32, 1.95, -0.25), (side * 0.36, 1.52, -0.28), 0.1, sides=4, tip=0.5, base=0.5, flat=0.45, core=True)
    for side, an in ((-1, "ArmL"), (1, "ArmR")):  # hombreras blancas con púas de cristal
        arm = rig.segs[an]
        sp = arm.pivot
        G.shell(arm.m, sp + Vector((side * 0.06, 0.08, 0)), 0.3, 0.2, M_BLANCO, nu=12, nv=4, axis=(side * 0.45, 1, 0), thickness=0.05, lip=0.15)
        for j, (dx, dy, dz) in enumerate(((0.25, 0.32, -0.12), (0.34, 0.12, 0.05), (0.18, 0.26, 0.18))):
            b0 = sp + Vector((side * 0.12, 0.12, dz * 0.5))
            shard(arm.c, None, b0, b0 + Vector((side * dx, dy, dz)), 0.06, sides=4, tip=0.55)
        G.fin(arm.g, [sp + Vector((side * 0.2, 0.2, -0.2)), sp + Vector((side * 0.34, 0.08, -0.22)), sp + Vector((side * 0.32, 0.12, -0.1))], (0, 0, -1), 0.02, M_BRILLO)
    # la capa: cae de los hombros hasta el suelo, blanca por fuera con un panel azul y líneas de luz
    top_y, bot_y = 3.62, 0.12
    bands = [("Cape", "Body", 0.0, 0.36), ("Cape2", "Cape", 0.36, 0.68), ("Cape3", "Cape2", 0.68, 1.0)]

    def cape_pt(u, v, off=0.0):
        """u: -1 (hombro izquierdo) .. 1 (derecho) rodeando la espalda; v: 0 arriba .. 1 abajo."""
        y = top_y + (bot_y - top_y) * v
        spread = 0.62 + 0.75 * v  # se abre hacia abajo
        ang = u * (1.25 + 0.25 * v)  # (radianes alrededor del eje: 0 = detrás)
        x = math.sin(ang) * spread
        z = 0.3 + 0.12 * v + math.cos(ang) * (0.18 + 0.32 * v) + 0.05 * math.sin(v * 9 + u * 4) * v
        r = Vector((x, y, z))
        n = Vector((math.sin(ang), 0, math.cos(ang)))
        return r + n * off

    for name, parent, v0, v1 in bands:
        piv = cape_pt(0, v0)
        seg = rig.seg(name, (0, piv.y, piv.z), parent)
        vv0 = max(0.0, v0 - 0.025)
        nu, nv = 14, 5
        outer = [[cape_pt(-1 + 2 * i / nu, vv0 + (v1 - vv0) * j / nv, 0.035) for i in range(nu + 1)] for j in range(nv + 1)]
        inner = [[cape_pt(-1 + 2 * i / nu, vv0 + (v1 - vv0) * j / nv, -0.035) for i in range(nu + 1)] for j in range(nv + 1)]
        O = [[seg.m.v(p) for p in r] for r in outer]
        I = [[seg.m.v(p) for p in r] for r in inner]
        for j in range(nv):
            for i in range(nu):
                u = -1 + 2 * (i + 0.5) / nu
                mo = M_CAPA_AZUL if abs(u) < 0.42 else M_CAPA
                seg.m.face([O[j][i], O[j][i + 1], O[j + 1][i + 1], O[j + 1][i]], mo)
                seg.m.face([I[j][i], I[j + 1][i], I[j + 1][i + 1], I[j][i + 1]], M_CAPA_AZUL)
        for j in range(nv):
            seg.m.face([O[j][0], O[j + 1][0], I[j + 1][0], I[j][0]], M_CAPA)
            seg.m.face([O[j][-1], I[j][-1], I[j + 1][-1], O[j + 1][-1]], M_CAPA)
        for i in range(nu):
            seg.m.face([O[0][i], I[0][i], I[0][i + 1], O[0][i + 1]], M_CAPA)
            seg.m.face([O[-1][i], O[-1][i + 1], I[-1][i + 1], I[-1][i]], M_CAPA)
        # líneas de luz: la del centro (con rombos) y dos ramas
        seam(seg.g, [cape_pt(0, vv0 + (v1 - vv0) * t / 4, 0.05) for t in range(5)], 0.022)
        for sgn in (-1, 1):
            seam(seg.g, [cape_pt(sgn * (0.12 + 0.18 * t / 4), vv0 + (v1 - vv0) * t / 4, 0.05) for t in range(5)], 0.016)
            seam(seg.g, [cape_pt(sgn * 0.44, vv0 + (v1 - vv0) * t / 4, 0.05) for t in range(5)], 0.014)
        mid = cape_pt(0, (v0 + v1) / 2, 0.06)
        n_ = Vector((0, 0, 1))
        G.fin(seg.g, [mid + Vector((0, 0.16, 0)), mid + Vector((0.08, 0, 0)), mid + Vector((0, -0.16, 0)), mid + Vector((-0.08, 0, 0))], n_, 0.02, M_BRILLO)
    # broches de cristal de la capa (en los hombros)
    for side in (-1, 1):
        shard(body.c, body.g, (side * 0.5, 3.62, 0.08), (side * 0.56, 3.62, -0.12), 0.07, sides=6, tip=0.4, base=0.4, core=True)
    # el cetro: asta negra con espiral de luz, estrella blanca y la gran gema en una jaula de garras
    wr = Vector(rig.extra["hand_r"])
    sc = rig.seg("Scepter", wr, "ForeArmR")
    bot = Vector((wr.x, 0.05, wr.z))
    top = Vector((wr.x, 6.0, wr.z))
    sc.m.cylinder(bot + Vector((0, 0.25, 0)), top - Vector((0, 0.85, 0)), 0.045, 8, M_CUERPO)
    shard(sc.c, None, bot + Vector((0, 0.28, 0)), bot - Vector((0, 0.02, 0)), 0.06, sides=4, tip=0.7)
    pts = []
    for i in range(41):
        t = i / 40
        y = bot.y + 0.4 + (top.y - 1.0 - bot.y - 0.4) * t
        a = t * math.pi * 9
        pts.append(Vector((wr.x + math.cos(a) * 0.052, y, wr.z + math.sin(a) * 0.052)))
    seam(sc.g, pts, 0.012, 4)
    hy = top.y - 0.75
    for j in range(5):  # estrella blanca
        a = 2 * math.pi * j / 5 + 0.3
        tip = Vector((wr.x + math.cos(a) * 0.26, hy - 0.05, wr.z + math.sin(a) * 0.26))
        sc.m.cylinder(Vector((wr.x, hy, wr.z)), tip, 0.04, 4, M_BLANCO, r1=0.008)
    for j in range(3):  # jaula de garras
        a = 2 * math.pi * j / 3
        pts = [Vector((wr.x + math.cos(a) * r, hy + h, wr.z + math.sin(a) * r)) for r, h in ((0.05, 0.0), (0.2, 0.25), (0.22, 0.5), (0.1, 0.78))]
        G.tube(sc.m, pts, [0.035, 0.03, 0.025, 0.01], M_BLANCO, 5)
    shard(sc.c, sc.g, Vector((wr.x, hy + 0.05, wr.z)), Vector((wr.x, top.y, wr.z)), 0.17, sides=6, tip=0.42, base=0.3, core=True)


# ====================================================================== construir
def scale_rig(rig, height, wide):
    top = max(v.y for s in rig.segs.values() for v in (s.m.verts + s.c.verts + s.g.verts))
    sy = height / top
    sxz = sy * wide
    rig.transform(lambda v: Vector((v.x * sxz, v.y * sy, v.z * sxz)))


# Las proporciones del líder (su hoja: más alto, cabeza más pequeña, piernas largas, hombros anchos):
# se construye con el cuerpo del soldado y se recoloca cada segmento.
LEG_SY, BODY_SY, BODY_SX, HEAD_S, ARM_SY = 1.25, 1.08, 1.08, 0.78, 1.12
HIP_Y = 2.1
NECK = Vector((0, 3.78, 0.0))


def _body_map(v):
    return Vector((v.x * BODY_SX, HIP_Y * LEG_SY + (v.y - HIP_Y) * BODY_SY, v.z))


def _arm_map(v, side):
    sh = Vector((side * 0.63, 3.55, 0))
    d = v - sh
    return _body_map(sh) + Vector((d.x - side * 0.1, d.y * ARM_SY, d.z))


def leader_proportions(rig):
    neck_new = _body_map(NECK)
    cape_top = 3.62
    cape_new = _body_map(Vector((0, cape_top, 0))).y
    hand_old = Vector(rig.extra["hand_r"])
    hand_new = _arm_map(hand_old, 1)
    k_sc = hand_new.y / hand_old.y
    for name, seg in rig.segs.items():
        if name.startswith("Leg") or name.startswith("LowerLeg"):
            sx = -1 if name.endswith("L") else 1
            fn = lambda v, sx=sx: Vector((v.x - sx * 0.1, v.y * LEG_SY, v.z))
        elif name == "Head":
            fn = lambda v: neck_new + (v - NECK) * HEAD_S
        elif name == "Body":
            fn = _body_map
        elif name in ("ArmL", "ForeArmL"):
            fn = lambda v: _arm_map(v, -1)
        elif name in ("ArmR", "ForeArmR"):
            fn = lambda v: _arm_map(v, 1)
        elif name.startswith("Cape"):
            fn = lambda v: Vector((v.x * BODY_SX, 0.12 + (v.y - 0.12) * (cape_new - 0.12) / (cape_top - 0.12), v.z))
        elif name == "Scepter":
            fn = lambda v: Vector((v.x - hand_old.x + hand_new.x, v.y * k_sc, v.z - hand_old.z + hand_new.z))
        else:
            continue
        xform_seg(seg, fn)
    rig.extra["hand_r"] = hand_new


def build_troop(kind):
    rig = Rig(kind, HEIGHTS[kind], "Biped", "King" if kind == "King" else "Troop")
    soldier(rig, kind)
    if kind == "King":
        leader_proportions(rig)
    scale_rig(rig, HEIGHTS[kind], WIDE[kind])
    return rig


# ====================================================================== la nave «Clase: Guardián» (Fragata Prisma)
def z_loft(mb, stations, segs=8, p=1.6, matfn=None, mat=M_CUERPO, step=0.35):
    """Casco a lo largo de Z: stations (z, hw, ht, hb, cy). a = 0 arriba. Devuelve anillos y centros."""
    dense = []
    for i in range(len(stations) - 1):
        n = max(1, int(math.ceil(abs(stations[i + 1][0] - stations[i][0]) / step)))
        for k in range(n):
            dense.append(catmull(stations, i + k / n))
    dense.append(tuple(stations[-1]))
    rings, cens = [], []
    for z, hw, ht, hb, cy in dense:
        c = Vector((0, cy, z))
        ring = []
        for k in range(segs):
            a = 2 * math.pi * k / segs + math.pi / segs
            s, co = math.sin(a), math.cos(a)
            h = ht if co > 0 else hb
            ring.append(c + Vector((max(hw, 0.005) * spow(s, 2 / p), max(h, 0.005) * spow(co, 2 / p), 0)))
        rings.append(ring)
        cens.append(c)
    mb.loft(rings, mat, True, True, matfn)
    return rings, cens


def wing(seg, outline, thick=0.2, k=1.0, crystal_edge=True, glow_edge=True):
    """Ala en capas: base negra, placa blanca encima (algo más pequeña), tira de cristal y línea de luz
    en el borde de ataque (del punto 0 al 1 del contorno)."""
    pts = [Vector(p) for p in outline]
    G.fin(seg.m, pts, (0, 1, 0), thick * k, M_CUERPO)
    c = sum(pts, Vector()) / len(pts)
    inner = [c + (p - c) * 0.84 + Vector((0, thick * k * 0.5 + 0.03 * k, 0)) for p in pts]
    G.fin(seg.m, inner, (0, 1, 0), 0.07 * k, M_BLANCO)
    a, b = pts[0], pts[1]
    if crystal_edge:
        up = Vector((0, thick * k * 0.5 + 0.09 * k, 0))
        inward = c - a.lerp(b, 0.5)
        inward.y = 0
        inward = inward.normalized() * 0.42 * k
        p0, p1 = a.lerp(b, 0.12) + up, a.lerp(b, 0.9) + up
        G.fin(seg.c, [p0, p1, p1 + inward * 0.7, p0 + inward], (0, 1, 0), 0.06 * k, M_CRISTAL)
    if glow_edge:
        seam(seg.g, [a.lerp(b, t / 6) + Vector((0, 0.02 * k, 0)) for t in range(7)], 0.04 * k)


def side_plate(seg, rings, cens, k, z0, z1, a0, a1, lift, thick, na=3):
    i0 = min(range(len(cens)), key=lambda i: abs(cens[i].z - z0 * k))
    i1 = min(range(len(cens)), key=lambda i: abs(cens[i].z - z1 * k))
    plate(seg.m, rings, cens, i0, i1, a0, a1, M_BLANCO, lift=lift * k, thick=thick * k, na=na)


def blade(seg, root, tip, r, k, white=True, panel=True, spike=1.6, core=False, flat=0.2):
    """Hoja de ala de la Guardián: prisma aplanado (canto vivo, de rombo) blanco por arriba y negro por
    debajo, con un panel de cristal encima y la punta de cristal que sigue más allá."""
    root, tip = Vector(root) * k, Vector(tip) * k
    d = (tip - root).normalized()
    up = Vector((0, 1, 0))
    G.crystal(seg.m, root, tip, r * k, M_BLANCO if white else M_CUERPO, sides=4, tip=0.3, base=0.05, flat=flat)
    G.crystal(seg.m, root - up * (r * k * flat * 0.45), tip - up * (r * k * flat * 0.5) - d * 0.2 * k, r * k * 0.92, M_CUERPO, sides=4, tip=0.3, base=0.05, flat=flat * 0.8)
    if panel:
        a = root.lerp(tip, 0.18) + up * (r * k * flat * 0.62)
        b = root.lerp(tip, 0.8) + up * (r * k * flat * 0.5)
        shard(seg.c, seg.g if core else None, a, b, r * k * 0.5, sides=4, tip=0.3, base=0.2, flat=0.18, core=core)
    if spike:
        shard(seg.c, None, tip - d * 0.6 * k, tip + d * spike * k, r * k * 0.42, sides=4, tip=0.55, base=0.15, flat=0.4)
    seam(seg.g, [root.lerp(tip, 0.1) + up * (r * k * flat * 0.15) + (d.cross(up)).normalized() * r * k * 0.9 * (1 if (tip - root).x > 0 else -1), tip + up * 0.01], 0.035 * k)


def guardian(seg, k=1.0, drone=False):
    """La Guardián de la hoja: casco facetado en flecha (blanco arriba, negro abajo), morro de hoja de
    cristal, cabina oscura brillante, alas de varias hojas en flecha con paneles y puntas de cristal,
    aletas en «V», colas de púa y motores redondos que brillan. k: escala (1 = la Fragata Prisma, unos 15
    de largo y 13 de envergadura)."""
    S = lambda x, y, z: Vector((x * k, y * k, z * k))
    m, c, g = seg.m, seg.c, seg.g
    st = [(-6.6, 0.02, 0.02, 0.02, 0.0), (-5.6, 0.5, 0.36, 0.3, 0.0), (-4.0, 0.98, 0.74, 0.55, 0.02), (-2.0, 1.3, 1.0, 0.72, 0.05),
          (0.0, 1.42, 1.02, 0.76, 0.05), (2.0, 1.36, 0.9, 0.72, 0.02), (3.8, 1.12, 0.72, 0.6, 0.0), (5.0, 0.92, 0.6, 0.52, 0.0), (5.45, 0.8, 0.52, 0.46, 0.0)]
    st = [(z * k, hw * k, ht * k, hb * k, cy * k) for z, hw, ht, hb, cy in st]
    top_white = lambda cen, i, j: M_BLANCO if j in (0, 1, 2, 7, 8, 9) else None
    rings, cens = z_loft(m, st, segs=10, p=1.45, matfn=top_white, step=0.45 * k)
    for z0, z1, a0, a1 in ((-4.8, -3.0, -0.07, 0.07), (-0.4, 1.8, -0.09, 0.09), (2.2, 4.4, -0.08, 0.08)):
        side_plate(seg, rings, cens, k, z0, z1, a0, a1, 0.02, 0.1, 4)
    for side in (-1, 1):
        a = 0.25 if side > 0 else 0.75
        for z0, z1 in ((-4.2, -1.0), (0.4, 3.6)):
            side_plate(seg, rings, cens, k, z0, z1, a - 0.08, a + 0.04 if side > 0 else a + 0.08, 0.02, 0.08, 3)
        G.fin(c, [S(side * 1.0, 0.25, -3.6), S(side * 1.16, 0.28, -1.2), S(side * 1.14, -0.1, -1.4), S(side * 0.95, -0.1, -3.4)], (side, 0.2, 0), 0.1 * k, M_CRISTAL)
        seam(g, [S(side * 0.95, -0.3, -4.6), S(side * 1.16, -0.3, -1.0), S(side * 1.12, -0.28, 2.0), S(side * 0.84, -0.24, 4.8)], 0.035 * k)
    # morro de hoja de cristal y las «mandíbulas» (hojas delanteras)
    shard(c, g, S(0, 0.0, -5.4), S(0, -0.05, -8.6), 0.42 * k, sides=6, tip=0.55, base=0.15, flat=0.3, core=True)
    for sx in (-1, 1):
        blade(seg, (sx * 0.8, -0.25, -1.6), (sx * 1.7, -0.55, -6.2), 0.42, k, spike=1.2, flat=0.28)
    # cabina: cúpula oscura brillante con marco de luz
    G.blob(m, S(0, 0.72, -2.0), (0.62 * k, 0.5 * k, 1.9 * k), M_CABINA, nu=12, nv=5, bottom=0.0)
    for t in (-1.3, -0.3, 0.7):
        seam(g, [S(-0.58, 0.76, -2.0 + t), S(0, 1.24, -2.0 + t), S(0.58, 0.76, -2.0 + t)], 0.025 * k)
    seam(g, [S(0, 1.18, -3.7), S(0, 1.24, -2.0), S(0, 1.15, -0.3)], 0.025 * k)
    # gran cristal del lomo con su núcleo
    shard(c, g, S(0, 1.0, -0.4), S(0, 0.85, 4.0), 0.42 * k, sides=6, tip=0.25, base=0.2, flat=0.3, core=True)
    for sx in (-1, 1):
        # tres hojas por ala, en flecha y con caída (la de abajo, la más grande)
        blade(seg, (sx * 1.0, -0.3, -0.9), (sx * 6.2, -1.7, 2.6), 1.25, k, core=True, spike=2.0, flat=0.34)
        blade(seg, (sx * 0.95, 0.35, 0.7), (sx * 5.4, -0.55, 4.1), 1.0, k, spike=1.6, white=False, core=True, flat=0.36)
        blade(seg, (sx * 0.85, 0.05, 2.5), (sx * 4.3, -0.85, 5.7), 0.75, k, spike=1.3, flat=0.38)
        if not drone:
            # cañones con la lente que brilla delante
            G.tube(m, [S(sx * 1.45, -0.5, -3.4), S(sx * 1.5, -0.5, -1.0), S(sx * 1.5, -0.48, 0.8)], [0.26 * k, 0.3 * k, 0.26 * k], M_JUNTA, 8)
            G.blob(g, S(sx * 1.45, -0.5, -3.45), (0.18 * k, 0.18 * k, 0.06 * k), M_BRILLO, nu=10, nv=4)
            # aletas en «V» arriba
            blade(seg, (sx * 0.55, 0.7, 2.4), (sx * 1.5, 2.3, 5.0), 0.4, k, spike=0.9, panel=False, flat=0.3)
        shard(c, None, S(sx * 0.45, -0.1, 4.9), S(sx * 0.7, -0.25, 7.5), 0.16 * k, sides=5, tip=0.55, flat=0.5)
        G.torus(m, S(sx * 0.45, 0.04, 5.48), (0, 0, 1), 0.3 * k, 0.08 * k, M_JUNTA, n=14, m=5)
        G.blob(g, S(sx * 0.45, 0.04, 5.5), (0.28 * k, 0.28 * k, 0.07 * k), M_BRILLO, nu=12, nv=4)
    G.fin(m, [S(0, -0.55, -1.0), S(0, -0.55, 3.6), S(0, -1.3, 2.0)], (1, 0, 0), 0.16 * k, M_CUERPO)
    shard(c, g, S(0, 0.08, 4.3), S(0, 0.12, 6.4), 0.36 * k, sides=6, tip=0.4, base=0.3, flat=0.6, core=True)


def build_ship(kind):
    rig = Rig(kind, 0, "Ship", "Ship")
    b = rig.seg("Body", (0, 0, 0))
    if kind == "Fighter":
        guardian(b, 1.0)
    elif kind == "Drone":
        # Astilla: una Guardián pequeña (dron), sin cañones, con su anillo de cristal que gira
        guardian(b, 0.38, drone=True)
        r = rig.seg("Rotor", (0, 0, 0), "Body")
        G.torus(r.m, (0, 0, 0.2), (0, 0, 1), 0.95, 0.06, M_JUNTA, n=18, m=5)
        for i in range(3):
            a = 2 * math.pi * i / 3 + 0.5
            d = Vector((math.cos(a), math.sin(a), 0))
            p = d * 0.95 + Vector((0, 0, 0.2))
            shard(r.c, r.g, p - d * 0.1, p + d * 0.55, 0.1, sides=4, tip=0.5, core=(i == 0))
    else:
        # Geoda: la nave de desembarco, una Guardián enorme con la geoda de cristal en la panza, patas y rampa
        guardian(b, 2.05)
        m, c, g = b.m, b.c, b.g
        for i in range(9):
            a = 2 * math.pi * i / 9
            base = Vector((math.cos(a) * 1.0, -1.0, 0.5 + math.sin(a) * 1.4))
            tip = base + Vector((math.cos(a) * 1.9, -2.6 - (i % 3) * 0.5, math.sin(a) * 2.4))
            shard(c, g if i % 3 == 0 else None, base, tip, 0.55, sides=6, tip=0.35, core=(i % 3 == 0))
        shard(c, g, (0, -0.8, 0.5), (0, -5.2, 0.5), 1.0, sides=6, tip=0.4, core=True)
        G.torus(g, (0, -1.1, 0.5), (0, 1, 0), 2.6, 0.12, M_BRILLO, n=24, m=4)
        for i in range(4):
            a = 2 * math.pi * i / 4 + math.pi / 4
            top = Vector((math.cos(a) * 3.2, -0.9, 0.5 + math.sin(a) * 5.0))
            foot = Vector((math.cos(a) * 4.6, -6.2, 0.5 + math.sin(a) * 6.4))
            m.cylinder(top, foot, 0.32, 8, M_JUNTA)
            m.box(foot + Vector((0, -0.15, 0)), (1.6, 0.3, 1.6), M_BLANCO)
            shard(c, None, top + (foot - top) * 0.3, top + (foot - top) * 0.3 + Vector((math.cos(a) * 1.0, 0.8, math.sin(a) * 1.0)), 0.18, sides=4)
        m.box((0, -3.1, -7.2), (3.6, 0.3, 5.4), M_BLANCO, up=(0, 0.88, -0.47))
    return rig


def build_all():
    out = [build_troop(k) for k in ("Grunt", "Heavy", "Ranged", "Elite", "King")]
    out += [build_ship(k) for k in ("Fighter", "Drone", "Dropship")]
    return out
