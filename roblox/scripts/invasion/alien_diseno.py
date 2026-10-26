"""Diseños de los alienígenas de la Invasión de la Grieta (v2, mallas de Blender): tropas, élite, rey,
naves y la gente transformada de las 5 razas (shared/Invasion/Races). Diseños ORIGINALES.

Cada modelo es un «rig» de segmentos rígidos (sin huesos): Body, Head, ArmL, ArmR, LegL, LegR… Cada
segmento tiene su pivote (hombro, cadera, cuello) y su padre; en Roblox se une con un Motor6D y el
cliente lo anima (shared/Invasion/AlienPose: andar, correr, atacar, encajar un golpe, deshacerse).
Cada segmento tiene dos mallas: la principal (texturas PBR horneadas) y la de brillo (Neon, del color
Glow de la raza: ojos, núcleos, venas, farolillos).

Coordenadas de Roblox (X derecha, Y arriba, el frente a -Z). Las tropas y criaturas se diseñan con los
pies en y = 0 y al exportar se bajan media altura (el raíz de Roblox va en el centro, como antes).

Siluetas (de un vistazo, también de lejos):
    Vórtidos     caballeros de cristal: pecho de geoda, hombros de púas, patas de ave de bronce
    Mórfagos     sacos de membrana sobre tentáculos, un ojo enorme verde, volantes
    Ferrocéfalos autómatas cuadrados de chatarra, visera amarilla, chimeneas y pistones
    Lumínidos    túnicas de porcelana dorada que flotan, cabeza de luna creciente, halo
    Brumáridos   marineros encorvados con caparazón de pizarra y farolillo de pescador
"""
import math

from mathutils import Matrix, Vector

from geo import MeshBuilder
import alien_geo as G

RACES = ["Vortidos", "Morfagos", "Ferrocefalos", "Luminidos", "Brumaridos"]


def rgb(r, g, b):
    return (r / 255.0, g / 255.0, b / 255.0)


# Colores (los de shared/Invasion/Races.Palette + los de detalle que solo usa la malla)
PALETTE = {
    "Vortidos": {"Body": rgb(70, 200, 210), "Trim": rgb(170, 120, 60), "Glow": rgb(140, 255, 250), "Dark": rgb(24, 70, 84), "Accent": rgb(210, 250, 255)},
    "Morfagos": {"Body": rgb(170, 60, 170), "Trim": rgb(60, 30, 80), "Glow": rgb(120, 255, 120), "Dark": rgb(40, 14, 52), "Accent": rgb(240, 150, 210)},
    "Ferrocefalos": {"Body": rgb(190, 95, 40), "Trim": rgb(40, 40, 44), "Glow": rgb(255, 210, 60), "Dark": rgb(70, 52, 40), "Accent": rgb(230, 190, 40)},
    "Luminidos": {"Body": rgb(250, 220, 140), "Trim": rgb(130, 80, 200), "Glow": rgb(255, 250, 210), "Dark": rgb(70, 40, 110), "Accent": rgb(255, 255, 245)},
    "Brumaridos": {"Body": rgb(90, 120, 150), "Trim": rgb(220, 230, 235), "Glow": rgb(120, 200, 255), "Dark": rgb(36, 46, 60), "Accent": rgb(170, 200, 210)},
}

# Alturas (studs) como World/Kit/AlienModels.Heights (el raíz y la vida no cambian)
HEIGHTS = {"Grunt": 6, "Heavy": 9, "Ranged": 7, "Elite": 11, "King": 11}
WIDE = {"Grunt": 1.0, "Heavy": 1.18, "Ranged": 0.92, "Elite": 1.0, "King": 1.0}

CREATURES = {
    "Vortidos": [("CaminanteCristal", "Biped", 4.6), ("CiervoCuarzo", "Quad", 3.6)],
    "Morfagos": [("BichoTentacular", "Crawl", 2.4), ("BabosaBrillante", "Slither", 1.6)],
    "Ferrocefalos": [("AutomataChatarra", "Biped", 3.8), ("PerroTostadora", "Quad", 2.6)],
    "Luminidos": [("ZorroLuz", "Quad", 2.6), ("BuhoEstelar", "Hop", 2.4)],
    "Brumaridos": [("RanaNiebla", "Hop", 2.2), ("PezCaminante", "Biped", 3.0)],
}

GAIT = {"Vortidos": "Biped", "Morfagos": "Crawl", "Ferrocefalos": "Biped", "Luminidos": "Float", "Brumaridos": "Biped"}


class Seg:
    def __init__(self, rig, name, pivot, parent):
        self.rig = rig
        self.name = name
        self.pivot = Vector(pivot)
        self.parent = parent
        R = rig.race
        self.B, self.T, self.D, self.X = f"{R}_cuerpo", f"{R}_detalle", f"{R}_oscuro", f"{R}_acento"
        self.m = MeshBuilder([self.B, self.T, self.D, self.X])
        self.g = MeshBuilder(["brillo"])
        self.GL = "brillo"


class Rig:
    """Un modelo: segmentos (en orden: los padres antes que los hijos)."""

    def __init__(self, race, kind, height, gait, category, root=None):
        self.race = race
        self.kind = kind
        self.height = height
        self.gait = gait
        self.category = category  # Troop | King | Ship | Creature
        self.segs = {}
        self.root = root
        self.extra = {}

    @property
    def id(self):
        return f"{self.race}_{self.kind}"

    def seg(self, name, pivot=(0, 0, 0), parent="Root"):
        if name not in self.segs:
            self.segs[name] = Seg(self, name, pivot, parent)
        return self.segs[name]

    def transform(self, fn):
        """Aplica fn(Vector) -> Vector a todos los vértices y pivotes."""
        for s in self.segs.values():
            s.m.verts = [fn(v) for v in s.m.verts]
            s.g.verts = [fn(v) for v in s.g.verts]
            s.pivot = fn(s.pivot)


# ====================================================================== utilidades de diseño
def mirror_side(p, side):
    return Vector((p[0] * side, p[1], p[2]))


def ring_of(mb, center, axis, r, count, size, mat, fn):
    """count piezas alrededor de un eje (fn(mb, punto, dirección radial, mat, size))."""
    e1, e2 = G.frame_for(axis)
    for i in range(count):
        a = 2 * math.pi * i / count
        d = e1 * math.cos(a) + e2 * math.sin(a)
        fn(mb, Vector(center) + d * r, d, mat, size)


# ====================================================================== VÓRTIDOS (cristal y bronce)
def vortido(rig, kind):
    heavy, ranged, elite = kind == "Heavy", kind in ("Ranged", "Elite", "King"), kind in ("Elite", "King")
    sw = 1.25 if heavy else 1.0  # anchura de hombros
    hip, sh, neck = 2.6, 4.3, 4.65
    body = rig.seg("Body", (0, hip, 0))
    m, g = body.m, body.g
    # pelvis y columna de bronce
    G.torus(m, (0, hip + 0.1, 0), (0, 1, 0), 0.5, 0.16, body.T, n=14, m=6)
    G.tube(m, [(0, hip, 0.05), (0, hip + 0.8, 0.12), (0, sh - 0.2, 0.05)], [0.28, 0.24, 0.3], body.T, 8)
    # pecho: geoda de cristal (prisma ancho) y cristales de la espalda
    G.crystal(m, (0, hip + 0.25, 0.05), (0, sh + 0.75, -0.12), 0.95 * sw, body.B, sides=6, tip=0.32, base=0.18, flat=0.72, twist=0.26)
    for i, (x, y, z, tx, ty, tz, r) in enumerate(((0.45, 3.6, 0.55, 0.9, 5.4, 1.35, 0.26), (-0.42, 3.4, 0.6, -0.95, 5.0, 1.4, 0.22), (0.0, 3.9, 0.6, 0.1, 5.7, 1.1, 0.24))):
        G.crystal(m, (x, y, z), (tx, ty, tz), r * sw, body.B, sides=5, tip=0.45, twist=i)
    # hombreras: racimos de púas
    for side in (-1, 1):
        base = Vector((side * 0.95 * sw, sh, 0))
        G.blob(m, base, (0.42 * sw, 0.32, 0.42), body.T, nu=10, nv=6)
        for j, (dx, dy, dz, L) in enumerate(((0.35, 0.9, 0.0, 1.0), (0.55, 0.5, 0.25, 0.8), (0.2, 0.75, -0.3, 0.7))):
            d = Vector((side * dx, dy, dz)).normalized()
            G.crystal(m, base + d * 0.15, base + d * (L * (1.5 if heavy else 1.0)), 0.17 * sw * (1.4 if heavy else 1.0), body.B, sides=5, tip=0.5)
    if heavy:  # placas monolito delante
        for side in (-1, 1):
            G.crystal(m, (side * 0.55, hip + 0.3, -0.55), (side * 0.7, sh + 0.2, -0.75), 0.42, body.B, sides=4, tip=0.25, flat=0.45)
    # núcleo que brilla (se ve en el pecho)
    G.crystal(g, (0, 3.35, -0.55), (0, 4.15, -0.78), 0.3, "brillo", sides=6, tip=0.4)
    G.blob(g, (0, 3.75, -0.5), (0.2, 0.28, 0.2), "brillo", nu=8, nv=6)
    # collar de bronce
    G.torus(m, (0, sh + 0.05, 0), (0, 1, 0.15), 0.62 * sw, 0.12, body.T, n=16, m=6)
    # cabeza: un cristal facetado con mandíbula de bronce y la mirada que brilla
    head = rig.seg("Head", (0, neck, 0), "Body")
    G.crystal(head.m, (0, neck + 0.05, 0.2), (0, neck + 1.35, -0.25), 0.44, head.B, sides=5, tip=0.42, base=0.25, twist=0.6)
    G.blob(head.m, (0, neck + 0.18, -0.18), (0.3, 0.2, 0.32), head.T, nu=10, nv=6)
    G.crystal(head.m, (0.12, neck + 0.9, 0.05), (0.42, neck + 1.6, 0.35), 0.12, head.B, sides=4, tip=0.5)
    G.crystal(head.m, (-0.12, neck + 0.9, 0.05), (-0.42, neck + 1.6, 0.35), 0.12, head.B, sides=4, tip=0.5)
    G.crystal(head.g, (0, neck + 0.62, -0.42), (0, neck + 0.62, -0.55), 0.33, "brillo", sides=6, tip=0.3, flat=0.32)
    if elite:
        for i in range(5):
            a = -math.pi / 2 + (i - 2) * 0.42
            base = Vector((math.cos(a) * 0.25, neck + 1.1, math.sin(a) * 0.25 + 0.05))
            G.crystal(head.g, base, base + Vector((math.cos(a) * 0.35, 0.9 - abs(i - 2) * 0.18, math.sin(a) * 0.2)), 0.08, "brillo", sides=4, tip=0.5)
        G.torus(head.m, (0, neck + 1.05, 0.05), (0, 1, 0), 0.4, 0.07, head.T, n=14, m=5)
    # brazos: bronce y antebrazo de cuchilla de cristal
    for side, name in ((-1, "ArmL"), (1, "ArmR")):
        sp = Vector((side * 1.05 * sw, sh - 0.05, 0))
        arm = rig.seg(name, sp, "Body")
        armed = ranged and side == 1
        elbow = sp + Vector((side * 0.25, -0.95, -0.15 if not armed else -0.45))
        hand = elbow + (Vector((side * 0.05, -0.85, -0.35)) if not armed else Vector((side * -0.1, -0.15, -0.95)))
        G.limb(arm.m, [sp, elbow, hand], [0.22 * sw, 0.17, 0.15], arm.T, 8)
        G.blob(arm.m, elbow, (0.2, 0.2, 0.2), arm.T, nu=8, nv=5)
        if armed:
            # cañón prisma: cristal largo con anillos de bronce y la boca que brilla
            fwd = Vector((0, -0.05, -1)).normalized()
            G.crystal(arm.m, hand - fwd * 0.3, hand + fwd * 2.1, 0.22, arm.B, sides=6, tip=0.25, base=0.1)
            for t in (0.2, 0.9, 1.5):
                G.torus(arm.m, hand + fwd * t, fwd, 0.27, 0.06, arm.T, n=12, m=5)
            G.blob(arm.g, hand + fwd * 2.05, (0.16, 0.16, 0.16), "brillo", nu=8, nv=6)
        else:
            blade_dir = (hand - elbow).normalized()
            G.crystal(arm.m, elbow + blade_dir * 0.2, hand + blade_dir * (0.9 if heavy else 0.7), 0.2 * sw, arm.B, sides=4, tip=0.55, flat=0.5)
            G.crystal(arm.g, hand - blade_dir * 0.1, hand + blade_dir * 0.35, 0.07, "brillo", sides=4, tip=0.5)
    # patas de ave (digitígradas) con dedos de cristal
    for side, name in ((-1, "LegL"), (1, "LegR")):
        hp = Vector((side * 0.45 * sw, hip, 0))
        leg = rig.seg(name, hp, "Root")
        knee = hp + Vector((side * 0.12, -1.05, -0.5))
        ankle = Vector((hp.x + side * 0.05, 0.62, 0.38))
        foot = Vector((hp.x, 0.12, -0.08))
        G.limb(leg.m, [hp, knee, ankle, foot], [0.3 * sw, 0.22, 0.16, 0.13], leg.T, 8)
        G.blob(leg.m, knee, (0.22, 0.22, 0.22), leg.B, nu=8, nv=5)
        for dx in (-0.22, 0.0, 0.22):
            G.crystal(leg.m, foot + Vector((dx * 0.5, -0.04, 0)), foot + Vector((dx, -0.1, -0.62)), 0.09, leg.B, sides=4, tip=0.5)
        G.crystal(leg.m, ankle, ankle + Vector((0, 0.1, 0.45)), 0.08, leg.B, sides=4, tip=0.5)
    if kind == "King":
        cape = rig.seg("Cape", (0, sh, 0.55), "Body")
        outline = [Vector((x, y, 0.62 + (sh - y) * 0.12)) for x, y in ((-1.1, sh), (1.1, sh), (1.6, 0.6), (0.8, 0.3), (0.0, 0.5), (-0.8, 0.3), (-1.6, 0.6))]
        G.fin(cape.m, outline, (0, 0, 1), 0.08, cape.D)
        for x in (-1.0, 0.0, 1.0):
            G.crystal(cape.g, (x, 1.2, 0.72), (x * 1.1, 0.6, 0.75), 0.06, "brillo", sides=4)


# ====================================================================== MÓRFAGOS (membrana y tentáculos)
def morfago(rig, kind):
    heavy, ranged, elite = kind == "Heavy", kind in ("Ranged", "Elite", "King"), kind in ("Elite", "King")
    w = 1.2 if heavy else 1.0
    body = rig.seg("Body", (0, 2.3, 0))
    m, g = body.m, body.g
    sac = Vector((0, 3.0, 0.25))
    G.blob(m, sac, (1.25 * w, 1.15, 1.45 * w), body.B, nu=20, nv=12, noise=0.07, seed=3, freq=2.2,
           shape=lambda u, v: 1.0 + 0.09 * math.sin(u * math.pi * 10) * max(0.0, v))
    # vientre más oscuro y una corona de volantes alrededor del frente
    G.blob(m, (0, 2.25, 0.1), (0.95 * w, 0.45, 1.05 * w), body.D, nu=16, nv=6, noise=0.05, seed=5)
    for i in range(7):
        a = math.pi * (0.15 + 0.7 * i / 6)
        base = Vector((math.cos(a) * 1.05 * w, 3.35 + math.sin(a) * 0.65, -0.65))
        tip = base + Vector((math.cos(a) * 0.55, math.sin(a) * 0.5, -0.25))
        G.fin(m, [base + Vector((0, -0.18, 0)), tip, base + Vector((0, 0.18, 0.05))], (0, 0, 1), 0.06, body.X)
    # manchas que brillan en la espalda
    for i, (x, y, z, r) in enumerate(((0.55, 3.9, 0.5, 0.2), (-0.6, 3.75, 0.7, 0.17), (0.1, 4.05, 0.95, 0.15), (0.7, 3.4, 1.05, 0.14), (-0.45, 3.3, 1.2, 0.16))):
        G.blob(g, (x * w, y, z * w), (r, r * 0.7, r), "brillo", nu=8, nv=5)
    if heavy:  # placas de caparazón sobre la espalda
        for i in range(4):
            G.shell(m, (0, 3.5 + i * 0.12, 0.9 - i * 0.55), 0.85 - i * 0.08, 0.35, body.D, nu=14, nv=4, axis=(0, 0.75, 0.6), thickness=0.08)
    if ranged:  # saco escupidor con boquilla
        G.blob(m, (0, 4.1, 0.75), (0.6, 0.55, 0.7), body.X, nu=14, nv=8, noise=0.05, seed=9)
        G.tube(m, [(0, 4.35, 0.4), (0, 4.6, -0.3), (0.0, 4.45, -1.05)], [0.22, 0.18, 0.2], body.B, 8)
        G.blob(g, (0, 4.43, -1.12), (0.16, 0.16, 0.12), "brillo", nu=8, nv=5)
    if elite:  # volantes de matriarca (alas de membrana) a la espalda
        for side in (-1, 1):
            outline = [Vector((side * 0.6, 3.8, 0.9)), Vector((side * 2.3, 5.0, 1.2)), Vector((side * 2.6, 3.9, 1.6)), Vector((side * 1.9, 3.1, 1.5)), Vector((side * 0.9, 3.0, 1.1))]
            G.fin(m, outline, (0, 0.2, 1), 0.07, body.X)
            G.tube(g, [outline[0], outline[1]], [0.05, 0.03], "brillo", 5)
            G.tube(g, [outline[0], outline[2]], [0.05, 0.03], "brillo", 5)
    # el ojo: bulbo delante con párpado, pupila oscura y el globo verde que brilla
    head = rig.seg("Head", (0, 3.2, -0.9), "Body")
    G.blob(head.m, (0, 3.35, -1.05), (0.78, 0.72, 0.6), head.B, nu=16, nv=10, noise=0.04, seed=11)
    G.blob(head.g, (0, 3.4, -1.48), (0.6, 0.6, 0.45), "brillo", nu=16, nv=10)
    G.blob(head.m, (0, 3.4, -1.92), (0.16, 0.34, 0.05), head.D, nu=10, nv=6)
    G.shell(head.m, (0, 3.62, -1.2), 0.62, 0.35, head.X, nu=16, nv=4, axis=(0, 1, -0.25), thickness=0.07)
    if elite:
        for i in range(5):
            a = math.pi * (0.2 + 0.6 * i / 4)
            base = Vector((math.cos(a) * 0.55, 3.75 + math.sin(a) * 0.35, -1.0))
            G.crystal(head.g, base, base + Vector((math.cos(a) * 0.25, 0.7, 0.1)), 0.09, "brillo", sides=5, tip=0.6)
    # dos tentáculos de delante (los «brazos») con ventosas que brillan
    for side, name in ((-1, "ArmL"), (1, "ArmR")):
        sp = Vector((side * 0.95 * w, 2.85, -0.75))
        arm = rig.seg(name, sp, "Body")
        pts = G.bezier(sp, sp + Vector((side * 0.6, -0.2, -0.6)), sp + Vector((side * 0.5, -1.0, -1.4)), sp + Vector((side * 0.15, -0.6, -1.9)), 9)
        G.tube(arm.m, pts, [0.3 - 0.025 * i for i in range(len(pts))], arm.B, 9)
        for i in (3, 5, 7):
            G.blob(arm.g, pts[i] + Vector((0, -0.2, 0)), (0.07, 0.05, 0.07), "brillo", nu=6, nv=4)
    # cuatro tentáculos de andar
    for name, sx, sz in (("LegL", -1, -0.35), ("LegR", 1, -0.35), ("LegBL", -1, 0.7), ("LegBR", 1, 0.7)):
        hp = Vector((sx * 0.6 * w, 2.15, sz * w))
        leg = rig.seg(name, hp, "Root")
        out = Vector((sx * 0.9, 0, sz * 0.8)).normalized()
        pts = G.bezier(hp, hp + out * 0.6 + Vector((0, -0.6, 0)), Vector((hp.x, 0.2, hp.z)) + out * 1.4, Vector((hp.x, 0.08, hp.z)) + out * 2.0, 10)
        G.tube(leg.m, pts, [0.34 * w - 0.028 * i for i in range(len(pts))], leg.B, 9)
    if kind == "King":
        cape = rig.seg("Cape", (0, 3.6, 0.9), "Body")
        G.shell(cape.m, (0, 3.6, 1.0), 1.9, 1.5, cape.X, nu=20, nv=6, axis=(0, 0.3, 1), thickness=0.1, noise=0.06, seed=4)


# ====================================================================== FERROCÉFALOS (chatarra)
def rivets(mb, center, right, up, w, h, mat, nx=3, ny=2, normal=None, r=0.05):
    n = Vector(normal) if normal else Vector(right).cross(Vector(up)).normalized()
    for i in range(nx):
        for j in range(ny):
            p = Vector(center) + Vector(right) * (-w / 2 + w * (i + 0.5) / nx) + Vector(up) * (-h / 2 + h * (j + 0.5) / ny)
            mb.cylinder(p, p + n * 0.05, r, 6, mat)


def ferro(rig, kind):
    heavy, ranged, elite = kind == "Heavy", kind in ("Ranged", "Elite", "King"), kind in ("Elite", "King")
    w = 1.3 if heavy else 1.0
    hip, sh, neck = 2.7, 4.25, 4.6
    body = rig.seg("Body", (0, hip, 0))
    m, g = body.m, body.g
    m.box((0, hip + 0.15, 0), (1.3 * w, 0.5, 0.9), body.T)
    m.box((0, 3.55, 0), (2.3 * w, 1.6, 1.45), body.B, taper=(0.92, 0.95))  # cajón del pecho
    m.box((0, 3.6, -0.76), (1.6 * w, 1.0, 0.12), body.D)  # placa del pecho
    rivets(m, (0, 3.6, -0.83), (1, 0, 0), (0, 1, 0), 1.4 * w, 0.8, body.T, 4, 2, normal=(0, 0, -1))
    m.cylinder((0, 3.0, 0), (0, 2.8, 0), 0.55 * w, 12, body.T)
    # chimeneas a la espalda (escape)
    for side in (-1, 1):
        G.tube(m, [(side * 0.45 * w, 3.3, 0.75), (side * 0.5 * w, 4.3, 0.85), (side * 0.55 * w, 5.0, 0.8)], [0.17, 0.17, 0.2], body.T, 10, caps=False)
        m.cylinder((side * 0.55 * w, 4.95, 0.8), (side * 0.55 * w, 5.15, 0.8), 0.26, 10, body.D)
    # indicador del pecho (brilla)
    G.blob(g, (0, 3.75, -0.86), (0.22, 0.22, 0.05), "brillo", nu=10, nv=5)
    for x in (-0.45, 0.45):
        g.box((x * w, 3.35, -0.85), (0.22, 0.12, 0.04), "brillo")
    if heavy:
        for side in (-1, 1):
            m.box((side * 1.35 * w, sh + 0.15, 0), (0.9, 0.55, 1.3), body.D, taper=(0.8, 0.7))
            rivets(m, (side * 1.35 * w, sh + 0.43, 0), (1, 0, 0), (0, 0, 1), 0.6, 0.9, body.T, 2, 3, normal=(0, 1, 0))
    # cabeza: caja con visera amarilla y antena
    head = rig.seg("Head", (0, neck, 0), "Body")
    head.m.box((0, neck + 0.55, 0), (1.35, 1.0, 1.25), head.B, taper=(0.9, 0.85))
    head.m.box((0, neck + 0.62, -0.62), (1.2, 0.42, 0.1), head.T)
    head.g.box((0, neck + 0.62, -0.69), (1.0, 0.18, 0.06), "brillo")
    head.m.cylinder((0.68, neck + 0.55, 0), (0.78, neck + 0.55, 0), 0.22, 10, head.T)
    head.m.cylinder((-0.68, neck + 0.55, 0), (-0.78, neck + 0.55, 0), 0.22, 10, head.T)
    head.m.cylinder((0.35, neck + 1.05, 0.2), (0.4, neck + 2.0, 0.25), 0.05, 6, head.T)
    G.blob(head.g, (0.4, neck + 2.05, 0.25), (0.11, 0.11, 0.11), "brillo", nu=8, nv=5)
    if elite:  # chimeneas de capataz en la cabeza
        for x in (-0.38, 0.0, 0.38):
            head.m.cylinder((x, neck + 1.0, 0.1), (x, neck + 1.75 + (0.3 if x == 0 else 0), 0.1), 0.13, 8, head.D)
            head.g.cylinder((x, neck + 1.74 + (0.3 if x == 0 else 0), 0.1), (x, neck + 1.8 + (0.3 if x == 0 else 0), 0.1), 0.1, 8, "brillo")
    # brazos de pistón con pinza (el pesado: martinete; el tirador: fusil largo)
    for side, name in ((-1, "ArmL"), (1, "ArmR")):
        sp = Vector((side * 1.3 * w, sh, 0))
        arm = rig.seg(name, sp, "Body")
        armed = ranged and side == 1
        arm.m.cylinder(sp + Vector((side * -0.15, 0, 0)), sp + Vector((side * 0.3, 0, 0)), 0.35, 10, arm.T)
        elbow = sp + Vector((side * 0.2, -1.0, -0.1 if not armed else -0.35))
        hand = elbow + (Vector((0, -0.95, -0.25)) if not armed else Vector((side * -0.1, -0.1, -0.95)))
        arm.m.cylinder(sp, elbow, 0.2, 8, arm.T)
        arm.m.cylinder(elbow, hand, 0.27 if not heavy else 0.36, 10, arm.B)
        G.blob(arm.m, elbow, (0.24, 0.24, 0.24), arm.D, nu=8, nv=5)
        d = (hand - elbow).normalized()
        if heavy and side == 1:
            arm.m.cylinder(hand, hand + d * 0.9, 0.55, 12, arm.D)  # martinete
            arm.m.cylinder(hand + d * 0.85, hand + d * 1.05, 0.62, 12, arm.T)
            arm.g.cylinder(hand + d * 0.4, hand + d * 0.45, 0.57, 12, "brillo")
        elif armed:
            arm.m.box(hand + d * 0.3, (0.35, 0.45, 0.9), arm.D, right=(1, 0, 0), up=(0, 1, 0))
            arm.m.cylinder(hand + d * 0.6, hand + d * 2.6, 0.09, 8, arm.T)
            arm.m.cylinder(hand + d * 0.5 + Vector((0, 0.32, 0)), hand + d * 1.3 + Vector((0, 0.32, 0)), 0.11, 8, arm.T)
            arm.g.cylinder(hand + d * 1.28 + Vector((0, 0.32, 0)), hand + d * 1.32 + Vector((0, 0.32, 0)), 0.1, 8, "brillo")
            arm.g.cylinder(hand + d * 2.58, hand + d * 2.66, 0.11, 8, "brillo")
        else:
            for k in range(3):
                a = 2 * math.pi * k / 3
                e1, e2 = G.frame_for(d)
                off = (e1 * math.cos(a) + e2 * math.sin(a)) * 0.18
                arm.m.box(hand + d * 0.3 + off * 1.3, (0.12, 0.12, 0.5), arm.D, right=tuple(e1), up=tuple(d.cross(e1)))
    # piernas: muslo de caja, pistón y pie plano
    for side, name in ((-1, "LegL"), (1, "LegR")):
        hp = Vector((side * 0.62 * w, hip, 0))
        leg = rig.seg(name, hp, "Root")
        knee = Vector((hp.x, 1.35, -0.12))
        leg.m.box((hp + knee) / 2, (0.55 * w, 1.25, 0.6), leg.B)
        leg.m.cylinder(knee, Vector((hp.x, 0.35, 0.05)), 0.2, 8, leg.T)
        leg.m.cylinder(knee + Vector((0, -0.1, 0)), knee + Vector((0, -0.55, 0)), 0.27, 8, leg.D)
        leg.m.box((hp.x, 0.15, -0.15), (0.75 * w, 0.3, 1.15), leg.D, taper=(0.85, 0.8))
        rivets(leg.m, (hp.x, 2.0, -0.31), (1, 0, 0), (0, 1, 0), 0.35, 0.7, leg.T, 2, 2, normal=(0, 0, -1))
    if kind == "King":
        cape = rig.seg("Cape", (0, sh, 0.75), "Body")
        for i in range(5):
            cape.m.box((-1.0 + i * 0.5, 2.6, 0.82 + (i % 2) * 0.05), (0.45, 2.6, 0.08), cape.D)
            rivets(cape.m, (-1.0 + i * 0.5, 2.6, 0.88), (1, 0, 0), (0, 1, 0), 0.25, 2.0, cape.T, 1, 4, normal=(0, 0, 1))


# ====================================================================== LUMÍNIDOS (luz y porcelana)
def lumi(rig, kind):
    heavy, ranged, elite = kind == "Heavy", kind in ("Ranged", "Elite", "King"), kind in ("Elite", "King")
    w = 1.15 if heavy else 1.0
    body = rig.seg("Body", (0, 2.8, 0))
    m, g = body.m, body.g
    # túnica acampanada (flota: el borde no toca el suelo)
    prof = [(0.72, 0.55), (1.0, 0.75), (0.85, 1.4), (0.55, 2.4), (0.45, 2.9), (0.62, 3.6), (0.7, 4.05), (0.5, 4.45), (0.22, 4.6)]
    pts = [Vector((0, y, 0)) for _, y in prof]
    G.tube(m, pts, [r * w for r, _ in prof], body.B, 18, caps=True, squash=0.85,
           matfn=lambda c, i, j: body.X if i in (1, 4) else None)
    for y, r in ((0.95, 0.98), (2.55, 0.5), (3.85, 0.72)):
        G.torus(m, (0, y, 0), (0, 1, 0), r * w, 0.07, body.T, n=20, m=6, squash=1.0)
    # bajo de la túnica que brilla (la luz con la que flotan) y el núcleo del pecho
    G.torus(g, (0, 0.62, 0), (0, 1, 0), 0.66 * w, 0.08, "brillo", n=20, m=6)
    G.blob(g, (0, 0.5, 0), (0.45 * w, 0.12, 0.4 * w), "brillo", nu=12, nv=4)
    G.crystal(g, (0, 3.05, -0.5), (0, 3.95, -0.62), 0.24, "brillo", sides=4, tip=0.5, base=0.5, flat=0.6)
    if heavy:  # faro: hombreras de porcelana y un aro de luz
        for side in (-1, 1):
            G.shell(m, (side * 0.75, 4.0, 0), 0.45, 0.35, body.B, nu=12, nv=4, axis=(side * 0.5, 1, 0), thickness=0.06)
        G.torus(g, (0, 3.3, 0), (0, 1, 0), 1.0, 0.05, "brillo", n=24, m=5)
    # cabeza: luna creciente con una esfera de luz dentro
    head = rig.seg("Head", (0, 4.5, 0), "Body")
    arc = [Vector((math.cos(a) * 0.62, 5.25 + math.sin(a) * 0.62, -0.05)) for a in [math.radians(t) for t in range(-60, 241, 15)]]
    G.tube(head.m, arc, [0.06 + 0.2 * math.sin(math.pi * i / (len(arc) - 1)) for i in range(len(arc))], head.B, 8, squash=0.6)
    G.blob(head.g, (0, 5.15, -0.05), (0.32, 0.32, 0.32), "brillo", nu=12, nv=8)
    head.m.cylinder((0, 4.5, 0), (0, 4.75, 0), 0.16, 8, head.T)
    if kind == "Heavy":  # faro: linterna en vez de luna
        head.m.cylinder((0, 4.7, 0), (0, 5.9, 0), 0.6, 12, head.T)
        G.blob(head.g, (0, 5.3, 0), (0.48, 0.55, 0.48), "brillo", nu=12, nv=8)
        G.blob(head.m, (0, 6.05, 0), (0.7, 0.35, 0.7), head.X, nu=12, nv=6, top=1.0, bottom=-0.2)
    halo = rig.seg("Halo", (0, 5.25, 0.4), "Head")
    G.torus(halo.g, (0, 5.25, 0.42), (0, 0.15, 1), 0.95 if not elite else 1.15, 0.06, "brillo", n=28, m=5)
    if elite:
        for i in range(8):
            a = 2 * math.pi * i / 8
            p = Vector((math.cos(a) * 1.15, 5.25 + math.sin(a) * 1.15, 0.42))
            G.crystal(halo.g, p, p + Vector((math.cos(a), math.sin(a), 0)) * 0.35, 0.06, "brillo", sides=4, tip=0.6)
    # brazos largos y finos con dedos de cristal y esquirlas flotando
    for side, name in ((-1, "ArmL"), (1, "ArmR")):
        sp = Vector((side * 0.72 * w, 4.1, 0))
        arm = rig.seg(name, sp, "Body")
        armed = ranged and side == 1
        elbow = sp + Vector((side * 0.35, -1.0, -0.05 if not armed else -0.4))
        hand = elbow + (Vector((side * 0.1, -0.95, -0.2)) if not armed else Vector((0, 0.05, -0.95)))
        G.limb(arm.m, [sp, elbow, hand], [0.15, 0.11, 0.09], arm.B, 8)
        G.torus(arm.m, elbow + (hand - elbow) * 0.4, (hand - elbow), 0.14, 0.04, arm.T, n=10, m=4)
        d = (hand - elbow).normalized()
        for k in range(3):
            e1, e2 = G.frame_for(d)
            a = (k - 1) * 0.5
            fp = hand + (e1 * math.cos(a) * 0.08)
            G.crystal(arm.m, fp, fp + d * 0.42 + e1 * (k - 1) * 0.08, 0.04, arm.X, sides=4, tip=0.6)
        for k in range(2):
            p = elbow + (hand - elbow) * (0.3 + 0.4 * k) + Vector((side * 0.32, 0.05, 0))
            G.crystal(arm.g, p, p + d * 0.3, 0.05, "brillo", sides=4, tip=0.5, base=0.5)
        if armed:  # lanza solar
            G.tube(arm.m, [hand - Vector((0, 0, -1.3)), hand + Vector((0, 0, -2.4))], [0.06, 0.05], arm.T, 6)
            G.crystal(arm.g, hand + Vector((0, 0, -2.3)), hand + Vector((0, 0, -3.2)), 0.16, "brillo", sides=4, tip=0.6, base=0.3)
    if elite:  # alas de plumas de luz (Heraldo)
        wings = rig.seg("Wings", (0, 4.0, 0.45), "Body")
        for side in (-1, 1):
            for i in range(5):
                a = math.radians(15 + i * 17)
                base = Vector((side * 0.3, 4.0, 0.5))
                tip = base + Vector((side * math.cos(a) * (2.6 - i * 0.25), math.sin(a) * 2.2 - 0.3, 0.4))
                mid = (base + tip) / 2 + Vector((0, 0.15, 0.05))
                G.fin(wings.m, [base, mid + Vector((0, 0.18, 0)), tip, mid - Vector((0, 0.18, 0))], (0, 0, 1), 0.05, wings.B)
                G.tube(wings.g, [base + Vector((0, 0, 0.04)), tip + Vector((0, 0, 0.04))], [0.035, 0.02], "brillo", 4)
    if kind == "King":
        cape = rig.seg("Cape", (0, 4.2, 0.4), "Body")
        G.shell(cape.m, (0, 4.25, 0.35), 1.2, 3.6, cape.X, nu=18, nv=7, axis=(0, -1, 0.18), thickness=0.08)


# ====================================================================== BRUMÁRIDOS (caparazón y farolillo)
def bruma(rig, kind):
    heavy, ranged, elite = kind == "Heavy", kind in ("Ranged", "Elite", "King"), kind in ("Elite", "King")
    w = 1.3 if heavy else 1.0
    body = rig.seg("Body", (0, 2.1, 0))
    m, g = body.m, body.g
    # caparazón encorvado (concha de pizarra con costillas) y vientre claro
    G.shell(m, (0, 2.5, 0.25), 1.3 * w, 1.7, body.B, nu=22, nv=8, axis=(0, 0.55, 0.85), thickness=0.14, lip=0.15, noise=0.05, seed=7, inner_mat=body.D)
    for i in range(5):
        t = 0.2 + 0.15 * i
        G.torus(m, Vector((0, 2.5, 0.25)) + Vector((0, 0.55, 0.85)).normalized() * (1.7 * math.sin(t * math.pi / 2)), (0, 0.55, 0.85), 1.25 * w * math.cos(t * math.pi / 2) + 0.05, 0.06, body.T, n=20, m=5)
    G.blob(m, (0, 2.6, -0.15), (0.85 * w, 1.0, 0.7 * w), body.T, nu=16, nv=10, noise=0.03, seed=2)
    for i in range(6):  # percebes
        a = 0.6 + i * 0.55
        G.blob(m, (math.cos(a) * 0.9 * w, 3.3 + 0.25 * math.sin(i * 1.3), 1.0 + 0.2 * math.sin(a)), (0.13, 0.1, 0.13), body.X, nu=8, nv=5)
    for i in range(7):  # puntos de luz por el borde de la concha
        a = math.radians(-70 + i * 23)
        G.blob(g, (math.sin(a) * 1.32 * w, 2.0 + math.cos(a) * 0.5, 0.9 - math.cos(a) * 0.4), (0.07, 0.07, 0.07), "brillo", nu=6, nv=4)
    if elite or heavy:
        for i in range(5 if elite else 3):
            a = math.radians(-50 + i * (25 if elite else 50))
            base = Vector((math.sin(a) * 0.9 * w, 3.9 + math.cos(a) * 0.3, 1.0))
            G.crystal(g if elite else m, base, base + Vector((math.sin(a) * 0.4, 0.9, 0.5)), 0.12, "brillo" if elite else body.D, sides=5, tip=0.6)
    # cabeza de pez con mandíbulas y el farolillo colgado de una antena
    head = rig.seg("Head", (0, 3.35, -0.55), "Body")
    G.blob(head.m, (0, 3.45, -0.95), (0.62, 0.52, 0.72), head.B, nu=14, nv=9, noise=0.04, seed=8)
    for side in (-1, 1):
        G.fin(head.m, [Vector((side * 0.45, 3.2, -0.7)), Vector((side * 0.55, 2.95, -1.55)), Vector((side * 0.2, 3.05, -1.7)), Vector((side * 0.25, 3.25, -0.9))], (side, 0, 0), 0.08, head.T)
        G.blob(head.g, (side * 0.38, 3.65, -1.45), (0.1, 0.12, 0.08), "brillo", nu=8, nv=5)
    stalk = G.bezier((0, 3.85, -0.85), (0, 4.8, -0.7), (0, 5.0, -1.6), (0, 4.4, -2.0), 8)
    G.tube(head.m, stalk, [0.07 - 0.004 * i for i in range(len(stalk))], head.D, 6)
    G.blob(head.g, stalk[-1] + Vector((0, -0.2, 0)), (0.26, 0.3, 0.26), "brillo", nu=10, nv=8)
    if elite:  # cresta de almirante
        G.fin(head.m, [Vector((0, 3.85, -0.6)), Vector((0, 4.9, 0.1)), Vector((0, 4.6, 0.5)), Vector((0, 3.9, 0.2))], (1, 0, 0), 0.08, head.X)
    # brazos de aleta (el tirador: arpón)
    for side, name in ((-1, "ArmL"), (1, "ArmR")):
        sp = Vector((side * 0.95 * w, 2.95, -0.3))
        arm = rig.seg(name, sp, "Body")
        armed = ranged and side == 1
        elbow = sp + Vector((side * 0.3, -0.8, -0.2 if not armed else -0.45))
        hand = elbow + (Vector((side * 0.1, -0.7, -0.2)) if not armed else Vector((0, -0.05, -0.85)))
        G.limb(arm.m, [sp, elbow, hand], [0.22 * w, 0.17, 0.14], arm.B, 8)
        d = (hand - elbow).normalized()
        e1, _ = G.frame_for(d)
        G.fin(arm.m, [hand, hand + d * 0.9 + Vector((side * 0.35, 0, 0)), hand + d * 1.1, hand + d * 0.8 - Vector((side * 0.3, 0, 0))], Vector((0, 0, 1)).cross(d), 0.06, arm.T)
        if armed:
            arm.m.cylinder(hand, hand + Vector((0, 0, -2.0)), 0.12, 8, arm.D)
            arm.m.cylinder(hand + Vector((0, 0.15, -0.2)), hand + Vector((0, 0.15, -0.9)), 0.16, 8, arm.T)
            G.crystal(arm.g, hand + Vector((0, 0, -1.95)), hand + Vector((0, 0, -2.65)), 0.14, "brillo", sides=4, tip=0.6, base=0.2)
    # patas cortas con pies de membrana
    for side, name in ((-1, "LegL"), (1, "LegR")):
        hp = Vector((side * 0.55 * w, 2.0, 0.1))
        leg = rig.seg(name, hp, "Root")
        knee = Vector((hp.x + side * 0.15, 1.0, -0.15))
        ankle = Vector((hp.x + side * 0.1, 0.25, 0.05))
        G.limb(leg.m, [hp, knee, ankle], [0.3 * w, 0.24, 0.16], leg.B, 8)
        G.fin(leg.m, [ankle + Vector((-0.35, -0.2, -0.5)), ankle + Vector((0.35, -0.2, -0.5)), ankle + Vector((0.2, -0.15, 0.15)), ankle + Vector((-0.2, -0.15, 0.15))], (0, 1, 0), 0.08, leg.T)
    if kind == "King":
        cape = rig.seg("Cape", (0, 3.2, 1.2), "Body")
        G.shell(cape.m, (0, 3.0, 1.25), 1.7, 1.2, cape.X, nu=20, nv=5, axis=(0, 0.2, 1), thickness=0.1, noise=0.05, seed=12)


TROOP = {"Vortidos": vortido, "Morfagos": morfago, "Ferrocefalos": ferro, "Luminidos": lumi, "Brumaridos": bruma}


def build_troop(race, kind):
    """Una tropa (Grunt, Heavy, Ranged, Elite) o el rey (King: el diseño de la élite con manto; en el
    juego se escala ×AlienModels.KingScale). Diseñada con 6 studs de alto; se escala a HEIGHTS[kind]."""
    rig = Rig(race, kind, HEIGHTS[kind], GAIT[race], "King" if kind == "King" else "Troop")
    TROOP[race](rig, kind)
    natural = natural_height(rig)
    sy = HEIGHTS[kind] / natural
    sxz = sy * WIDE[kind]
    rig.transform(lambda v: Vector((v.x * sxz, v.y * sy, v.z * sxz)))
    return rig


def natural_height(rig):
    top = 0.0
    for s in rig.segs.values():
        for v in s.m.verts + s.g.verts:
            top = max(top, v.y)
    # (la élite y el rey cuentan su corona: se diseñan algo más altos que el soldado)
    return max(top, 5.0)


# ====================================================================== CRIATURAS (la gente transformada)
def quad_legs(rig, body_y, half_len, half_w, length, radius, mat_fn, foot=None, knee_back=True):
    for name, sx, sz in (("LegL", -1, -1), ("LegR", 1, -1), ("LegBL", -1, 1), ("LegBR", 1, 1)):
        hp = Vector((sx * half_w, body_y, sz * half_len))
        leg = rig.seg(name, hp, "Root")
        bend = 0.18 if (sz > 0) == knee_back else -0.12
        knee = hp + Vector((0, -length * 0.5, bend))
        foot_p = Vector((hp.x, 0.08, hp.z - 0.05))
        G.limb(leg.m, [hp, knee, foot_p], [radius, radius * 0.75, radius * 0.6], mat_fn(leg), 7)
        if foot:
            foot(leg, foot_p)


def creature(race, cid, gait, height):
    rig = Rig(race, cid, height, gait, "Creature")
    if cid == "CaminanteCristal":
        # un muñeco de cristal rechoncho: cuerpo de geoda redonda, cabeza grande que tintinea, sin armas
        b = rig.seg("Body", (0, 1.6, 0))
        G.blob(b.m, (0, 2.1, 0), (0.85, 0.95, 0.75), b.B, nu=7, nv=6, noise=0.05, seed=2)
        G.crystal(b.g, (0, 1.6, -0.55), (0, 2.6, -0.72), 0.25, "brillo", sides=5, tip=0.4)
        for i in range(5):
            a = 0.5 + i * 0.55
            base = Vector((math.cos(a) * 0.6, 2.4 + 0.2 * math.sin(i), 0.4))
            G.crystal(b.m, base, base + Vector((math.cos(a) * 0.45, 0.6, 0.35)), 0.13, b.X, sides=4, tip=0.5)
        G.torus(b.m, (0, 2.95, 0), (0, 1, 0), 0.45, 0.09, b.T, n=12, m=5)
        h = rig.seg("Head", (0, 3.0, 0), "Body")
        G.crystal(h.m, (0, 2.95, 0.1), (0, 4.45, -0.05), 0.7, h.B, sides=6, tip=0.38, base=0.3, twist=0.3)
        for side in (-1, 1):
            G.blob(h.g, (side * 0.25, 3.65, -0.55), (0.12, 0.15, 0.06), "brillo", nu=8, nv=5)
        for side, name in ((-1, "ArmL"), (1, "ArmR")):
            sp = Vector((side * 0.85, 2.6, 0))
            a = rig.seg(name, sp, "Body")
            G.limb(a.m, [sp, sp + Vector((side * 0.3, -0.6, -0.1)), sp + Vector((side * 0.35, -1.1, -0.15))], [0.14, 0.12, 0.1], a.T, 7)
            G.blob(a.m, sp + Vector((side * 0.38, -1.25, -0.15)), (0.22, 0.22, 0.22), a.B, nu=6, nv=4)
        for side, name in ((-1, "LegL"), (1, "LegR")):
            hp = Vector((side * 0.4, 1.4, 0))
            l = rig.seg(name, hp, "Root")
            G.limb(l.m, [hp, Vector((hp.x, 0.7, -0.05)), Vector((hp.x, 0.15, 0))], [0.2, 0.17, 0.15], l.T, 7)
            G.crystal(l.m, (hp.x, 0.05, 0.2), (hp.x, 0.08, -0.45), 0.2, l.B, sides=5, tip=0.4, flat=0.5)
    elif cid == "CiervoCuarzo":
        b = rig.seg("Body", (0, 2.2, 0))
        G.crystal(b.m, (0, 2.3, 1.2), (0, 2.45, -1.0), 0.6, b.B, sides=6, tip=0.25, base=0.25, flat=0.85)
        G.blob(b.m, (0, 2.25, 0.1), (0.5, 0.45, 1.1), b.T, nu=12, nv=8)
        G.crystal(b.g, (0, 2.6, -0.2), (0, 2.85, 0.3), 0.18, "brillo", sides=5)
        h = rig.seg("Head", (0, 2.6, -1.0), "Body")
        G.tube(h.m, [(0, 2.5, -1.0), (0, 3.1, -1.35)], [0.22, 0.17], h.T, 8)
        G.crystal(h.m, (0, 3.2, -1.15), (0, 2.95, -2.05), 0.25, h.B, sides=5, tip=0.35)
        G.blob(h.g, (0.16, 3.25, -1.55), (0.06, 0.06, 0.06), "brillo", nu=6, nv=4)
        G.blob(h.g, (-0.16, 3.25, -1.55), (0.06, 0.06, 0.06), "brillo", nu=6, nv=4)
        for side in (-1, 1):  # cornamenta de cristal
            base = Vector((side * 0.15, 3.35, -1.3))
            G.crystal(h.m, base, base + Vector((side * 0.5, 1.0, 0.1)), 0.08, h.B, sides=4, tip=0.5)
            G.crystal(h.g, base + Vector((side * 0.25, 0.5, 0.05)), base + Vector((side * 0.75, 0.9, -0.15)), 0.06, "brillo", sides=4, tip=0.5)
            G.crystal(h.m, base + Vector((side * 0.35, 0.7, 0.07)), base + Vector((side * 0.3, 1.4, 0.35)), 0.06, h.B, sides=4, tip=0.5)
        quad_legs(rig, 2.0, 0.85, 0.33, 2.0, 0.16, lambda s: s.T)
        t = rig.seg("Tail", (0, 2.4, 1.2), "Body")
        G.crystal(t.g, (0, 2.45, 1.2), (0, 2.9, 1.6), 0.1, "brillo", sides=4)
    elif cid == "BichoTentacular":
        b = rig.seg("Body", (0, 1.1, 0))
        G.blob(b.m, (0, 1.35, 0.1), (0.65, 0.6, 0.75), b.B, nu=16, nv=10, noise=0.06, seed=21)
        G.blob(b.g, (0, 1.45, -0.55), (0.32, 0.32, 0.2), "brillo", nu=12, nv=8)
        G.blob(b.m, (0, 1.45, -0.72), (0.1, 0.17, 0.04), b.D, nu=8, nv=5)
        for i in range(4):
            G.blob(b.g, (math.cos(i * 1.6) * 0.45, 1.7, 0.2 + math.sin(i * 1.6) * 0.4), (0.07, 0.05, 0.07), "brillo", nu=6, nv=4)
        for name, a in (("LegL", 2.3), ("LegR", 0.85), ("LegBL", 3.6), ("LegBR", -0.45), ("ArmL", 2.95), ("ArmR", 0.2)):
            hp = Vector((math.cos(a) * 0.4, 0.95, math.sin(a) * 0.4 * -1))
            s = rig.seg(name, hp, "Root")
            out = Vector((math.cos(a), 0, -math.sin(a)))
            pts = G.bezier(hp, hp + out * 0.4 + Vector((0, -0.4, 0)), Vector((hp.x, 0.1, hp.z)) + out * 0.9, Vector((hp.x, 0.05, hp.z)) + out * 1.3, 7)
            G.tube(s.m, pts, [0.16 - 0.018 * i for i in range(len(pts))], s.B, 7)
    elif cid == "BabosaBrillante":
        # babosa ancha y plana (tipo caracol sin concha): manto ovalado, joroba baja con crestas
        # segmentadas y dos ojos grandes sobre pedúnculos cortos. Nada alargado ni tubular.
        b = rig.seg("Body", (0, 0.6, 0))
        G.blob(b.m, (0, 0.18, 0.05), (0.82, 0.16, 1.15), b.D, nu=14, nv=6, top=1.0, bottom=-0.6)
        G.blob(b.m, (0, 0.38, 0.12), (0.6, 0.3, 0.92), b.B, nu=14, nv=7, noise=0.03, seed=7, top=1.0, bottom=-0.3)
        for i in range(5):
            z = -0.45 + i * 0.3
            w = 0.5 - abs(i - 2) * 0.07
            G.blob(b.m, (0, 0.62 - abs(i - 2) * 0.05, z), (w, 0.1, 0.13), b.T, nu=10, nv=4, top=1.0, bottom=-0.2)
            for side in (-1, 1):
                G.blob(b.g, (side * w * 0.55, 0.66 - abs(i - 2) * 0.05, z), (0.09, 0.05, 0.08), "brillo", nu=5, nv=3)
        h = rig.seg("Head", (0, 0.6, -0.9), "Body")
        G.blob(h.m, (0, 0.34, -0.95), (0.52, 0.26, 0.36), h.B, nu=12, nv=6, top=1.0, bottom=-0.5)
        G.blob(h.m, (0, 0.2, -1.12), (0.3, 0.07, 0.12), h.D, nu=10, nv=4)
        for side in (-1, 1):
            G.blob(h.m, (side * 0.24, 0.66, -0.98), (0.08, 0.14, 0.08), h.B, nu=6, nv=4)
            G.blob(h.g, (side * 0.26, 0.86, -1.0), (0.16, 0.15, 0.15), "brillo", nu=10, nv=6)
            G.blob(h.m, (side * 0.27, 0.87, -1.14), (0.07, 0.07, 0.03), h.D, nu=8, nv=5)
    elif cid == "AutomataChatarra":
        # un cubo de basura con patitas y una escoba: barre la acera
        b = rig.seg("Body", (0, 1.2, 0))
        b.m.cylinder((0, 1.0, 0), (0, 2.9, 0), 0.75, 12, b.B, r1=0.85)
        for y in (1.4, 2.0, 2.6):
            G.torus(b.m, (0, y, 0), (0, 1, 0), 0.8, 0.05, b.T, n=12, m=4)
        b.m.cylinder((-0.95, 1.6, 0.1), (0.95, 1.6, 0.1), 0.06, 6, b.D)
        b.g.box((0, 2.2, -0.82), (0.5, 0.1, 0.05), "brillo")
        h = rig.seg("Head", (0, 2.9, 0), "Body")
        G.blob(h.m, (0, 3.05, 0), (0.9, 0.3, 0.9), h.D, nu=12, nv=6, top=1.0, bottom=-0.2)
        h.m.box((0, 3.45, 0), (0.6, 0.2, 0.2), h.T)
        h.m.cylinder((0.3, 3.3, 0), (0.35, 3.9, 0.05), 0.04, 6, h.T)
        G.blob(h.g, (0.35, 3.95, 0.05), (0.09, 0.09, 0.09), "brillo", nu=6, nv=4)
        for side, name in ((-1, "ArmL"), (1, "ArmR")):
            sp = Vector((side * 0.85, 2.3, 0))
            a = rig.seg(name, sp, "Body")
            a.m.cylinder(sp, sp + Vector((side * 0.25, -0.75, -0.3)), 0.07, 6, a.T)
            if side == 1:  # la escoba
                hand = sp + Vector((0.25, -0.75, -0.3))
                a.m.cylinder(hand + Vector((0, 0.8, 0)), hand + Vector((0, -1.3, -0.3)), 0.05, 6, a.D)
                a.m.box(hand + Vector((0, -1.45, -0.32)), (0.5, 0.3, 0.12), a.X, taper=(1.2, 1.0))
        for side, name in ((-1, "LegL"), (1, "LegR")):
            hp = Vector((side * 0.35, 1.0, 0))
            l = rig.seg(name, hp, "Root")
            l.m.cylinder(hp, Vector((hp.x, 0.2, 0)), 0.09, 6, l.T)
            l.m.box((hp.x, 0.1, -0.12), (0.35, 0.2, 0.55), l.D)
    elif cid == "PerroTostadora":
        b = rig.seg("Body", (0, 1.7, 0))
        b.m.box((0, 1.7, 0), (1.1, 0.9, 1.6), b.B, taper=(0.95, 0.95))
        for x in (-0.22, 0.22):
            b.g.box((x, 2.16, 0.05), (0.12, 0.04, 1.1), "brillo")
        b.m.box((0.6, 1.8, 0.4), (0.08, 0.3, 0.12), b.T)
        b.m.cylinder((0.6, 1.7, -0.3), (0.72, 1.7, -0.3), 0.12, 8, b.T)
        h = rig.seg("Head", (0, 2.0, -0.8), "Body")
        h.m.box((0, 2.15, -1.05), (0.75, 0.6, 0.6), h.D, taper=(0.85, 0.85))
        h.g.box((0, 2.2, -1.36), (0.5, 0.12, 0.04), "brillo")
        for side in (-1, 1):
            h.m.box((side * 0.32, 2.55, -1.0), (0.12, 0.35, 0.22), h.T)
        quad_legs(rig, 1.3, 0.55, 0.42, 1.3, 0.09, lambda s: s.T)
        t = rig.seg("Tail", (0, 1.9, 0.8), "Body")
        coil = [Vector((math.cos(a) * 0.12, 1.9 + a * 0.07, 0.85 + a * 0.06)) for a in [i * 0.6 for i in range(12)]]
        G.tube(t.m, coil, 0.03, t.T, 5)
        G.blob(t.g, coil[-1], (0.07, 0.07, 0.07), "brillo", nu=6, nv=4)
    elif cid == "ZorroLuz":
        b = rig.seg("Body", (0, 1.7, 0))
        G.blob(b.m, (0, 1.7, 0.05), (0.38, 0.38, 0.85), b.B, nu=14, nv=9)
        G.torus(b.m, (0, 1.75, -0.5), (0, 0, 1), 0.36, 0.05, b.T, n=14, m=4)
        h = rig.seg("Head", (0, 2.0, -0.75), "Body")
        G.blob(h.m, (0, 2.15, -1.0), (0.3, 0.27, 0.32), h.B, nu=12, nv=8)
        G.crystal(h.m, (0, 2.08, -1.15), (0, 2.0, -1.6), 0.13, h.B, sides=5, tip=0.5)
        for side in (-1, 1):
            G.crystal(h.m, (side * 0.15, 2.3, -0.95), (side * 0.22, 2.75, -0.9), 0.09, h.T, sides=3, tip=0.6)
            G.blob(h.g, (side * 0.13, 2.22, -1.27), (0.05, 0.04, 0.03), "brillo", nu=6, nv=4)
        quad_legs(rig, 1.55, 0.5, 0.2, 1.5, 0.07, lambda s: s.B)
        t = rig.seg("Tail", (0, 1.85, 0.8), "Body")
        tail = G.bezier((0, 1.85, 0.8), (0, 2.1, 1.4), (0, 2.8, 1.6), (0, 3.1, 1.3), 8)
        G.tube(t.g, tail, [0.1, 0.22, 0.32, 0.36, 0.34, 0.28, 0.2, 0.12, 0.03], "brillo", 10)
    elif cid == "BuhoEstelar":
        b = rig.seg("Body", (0, 0.8, 0))
        G.blob(b.m, (0, 1.25, 0), (0.6, 0.75, 0.55), b.B, nu=14, nv=10)
        G.blob(b.m, (0, 1.1, -0.25), (0.45, 0.55, 0.35), b.X, nu=12, nv=8)
        for side in (-1, 1):
            b.m.cylinder((side * 0.2, 0.55, -0.05), (side * 0.22, 0.05, -0.1), 0.06, 6, b.T)
        h = rig.seg("Head", (0, 1.8, 0), "Body")
        G.blob(h.m, (0, 2.1, -0.02), (0.5, 0.42, 0.45), h.B, nu=14, nv=9)
        for side in (-1, 1):
            G.torus(h.m, (side * 0.2, 2.15, -0.42), (0, 0, 1), 0.15, 0.04, h.T, n=12, m=4)
            G.blob(h.g, (side * 0.2, 2.15, -0.42), (0.12, 0.12, 0.05), "brillo", nu=8, nv=5)
            G.crystal(h.m, (side * 0.3, 2.4, -0.1), (side * 0.42, 2.8, 0.0), 0.07, h.T, sides=3, tip=0.6)
        G.crystal(h.m, (0, 2.02, -0.42), (0, 1.88, -0.62), 0.06, h.T, sides=4, tip=0.6)
        for side, name in ((-1, "ArmL"), (1, "ArmR")):
            w_ = rig.seg(name, (side * 0.55, 1.6, 0), "Body")
            G.fin(w_.m, [Vector((side * 0.5, 1.65, -0.2)), Vector((side * 0.65, 1.6, 0.3)), Vector((side * 0.6, 0.8, 0.45)), Vector((side * 0.52, 0.85, -0.1))], (1, 0, 0), 0.08, w_.T)
            G.tube(w_.g, [Vector((side * 0.62, 1.5, 0.1)), Vector((side * 0.62, 0.95, 0.35))], [0.03, 0.02], "brillo", 4)
    elif cid == "RanaNiebla":
        b = rig.seg("Body", (0, 0.9, 0))
        G.blob(b.m, (0, 1.05, 0.15), (0.75, 0.55, 0.8), b.B, nu=16, nv=10, noise=0.05, seed=31)
        G.blob(b.m, (0, 0.85, -0.15), (0.6, 0.35, 0.6), b.T, nu=12, nv=6)
        for side in (-1, 1):
            G.blob(b.g, (side * 0.62, 0.95, -0.35), (0.18, 0.16, 0.18), "brillo", nu=8, nv=6)
        h = rig.seg("Head", (0, 1.2, -0.45), "Body")
        G.blob(h.m, (0, 1.3, -0.65), (0.6, 0.35, 0.45), h.B, nu=14, nv=8)
        for side in (-1, 1):
            G.blob(h.m, (side * 0.32, 1.65, -0.6), (0.18, 0.18, 0.18), h.B, nu=10, nv=6)
            G.blob(h.g, (side * 0.33, 1.68, -0.74), (0.1, 0.1, 0.06), "brillo", nu=8, nv=5)
        for name, sx, sz, length in (("LegL", -1, -0.4, 0.8), ("LegR", 1, -0.4, 0.8), ("LegBL", -1, 0.55, 1.2), ("LegBR", 1, 0.55, 1.2)):
            hp = Vector((sx * 0.55, 0.85, sz))
            s = rig.seg(name, hp, "Root")
            knee = hp + Vector((sx * 0.45, (0.2 if sz > 0 else -0.25), -0.2 if sz > 0 else -0.1))
            foot = Vector((hp.x + sx * 0.4, 0.06, hp.z - 0.3))
            G.limb(s.m, [hp, knee, foot], [0.17 if sz > 0 else 0.12, 0.12, 0.08], s.B, 7)
            G.fin(s.m, [foot + Vector((-0.25, 0, -0.3)), foot + Vector((0.25, 0, -0.3)), foot + Vector((0.08, 0, 0.1)), foot + Vector((-0.08, 0, 0.1))], (0, 1, 0), 0.05, s.T)
    elif cid == "PezCaminante":
        b = rig.seg("Body", (0, 1.4, 0))
        pts = [Vector((0, 1.9 + 0.1 * math.sin(i * 0.5), -1.0 + i * 0.28)) for i in range(9)]
        G.tube(b.m, pts, [0.25, 0.5, 0.62, 0.66, 0.62, 0.5, 0.36, 0.2, 0.08], b.B, 12, squash=0.6)
        G.fin(b.m, [pts[-2], pts[-1] + Vector((0, 0.6, 0.5)), pts[-1] + Vector((0, -0.5, 0.5))], (1, 0, 0), 0.05, b.T)
        G.fin(b.m, [pts[2] + Vector((0, 0.55, 0)), pts[3] + Vector((0, 1.1, 0.3)), pts[5] + Vector((0, 0.5, 0))], (1, 0, 0), 0.05, b.T)
        for i in range(2, 7):
            G.blob(b.g, pts[i] + Vector((0.42, 0, 0)), (0.04, 0.06, 0.06), "brillo", nu=6, nv=4)
            G.blob(b.g, pts[i] + Vector((-0.42, 0, 0)), (0.04, 0.06, 0.06), "brillo", nu=6, nv=4)
        h = rig.seg("Head", (0, 1.9, -0.9), "Body")
        for side in (-1, 1):
            G.blob(h.m, (side * 0.3, 2.05, -0.95), (0.13, 0.13, 0.13), h.T, nu=8, nv=6)
            G.blob(h.g, (side * 0.34, 2.07, -1.0), (0.07, 0.07, 0.07), "brillo", nu=6, nv=4)
        for side, name in ((-1, "LegL"), (1, "LegR")):
            hp = Vector((side * 0.25, 1.4, 0))
            s = rig.seg(name, hp, "Root")
            G.limb(s.m, [hp, hp + Vector((side * 0.05, -0.7, -0.1)), Vector((hp.x, 0.1, 0.0))], [0.13, 0.1, 0.08], s.D, 7)
            G.fin(s.m, [Vector((hp.x - 0.2, 0.05, -0.35)), Vector((hp.x + 0.2, 0.05, -0.35)), Vector((hp.x, 0.05, 0.15))], (0, 1, 0), 0.05, s.T)
    natural = natural_height(rig) if cid not in ("BabosaBrillante",) else 1.2
    sy = height / natural
    rig.transform(lambda v: Vector((v.x * sy, v.y * sy, v.z * sy)))
    rig.height = height
    return rig


# ====================================================================== NAVES
def ship(race, kind):
    """Fighter (≈10 studs), Drone (≈5) y Dropship (≈26 de ancho). Body (+Rotor que gira)."""
    rig = Rig(race, kind, 0, "Ship", "Ship")
    b = rig.seg("Body", (0, 0, 0))
    m, g = b.m, b.g
    if race == "Vortidos":
        if kind == "Fighter":
            G.crystal(m, (0, 0, 5.2), (0, 0, -5.5), 1.1, b.B, sides=6, tip=0.35, base=0.12, flat=0.6, twist=0.52)
            for side in (-1, 1):
                G.crystal(m, (side * 0.6, -0.1, 1.5), (side * 5.0, -0.5, 2.8), 0.7, b.B, sides=4, tip=0.4, base=0.2, flat=0.25)
                G.tube(m, [(side * 1.3, -0.2, 3.5), (side * 1.3, -0.2, 5.2)], [0.45, 0.42], b.T, 10)
                G.torus(g, (side * 1.3, -0.2, 5.25), (0, 0, 1), 0.33, 0.08, "brillo", n=12, m=5)
                G.blob(g, (side * 1.3, -0.2, 5.25), (0.3, 0.3, 0.06), "brillo", nu=10, nv=4)
            for z in (-2.0, 1.0, 3.6):
                G.torus(m, (0, 0, z), (0, 0, 1), 1.1 - abs(z) * 0.08, 0.13, b.T, n=16, m=6, squash=1.0)
            G.crystal(g, (0, 0.55, -1.2), (0, 0.65, 0.8), 0.32, "brillo", sides=6, tip=0.3)
        elif kind == "Drone":
            G.crystal(m, (0, 0, 2.4), (0, 0, -2.4), 0.6, b.B, sides=5, tip=0.45, base=0.45)
            r = rig.seg("Rotor", (0, 0, 0), "Body")
            G.torus(r.m, (0, 0, 0), (0, 0, 1), 1.4, 0.12, r.T, n=18, m=6)
            for i in range(3):
                a = 2 * math.pi * i / 3
                r.m.cylinder((0, 0, 0), (math.cos(a) * 1.35, math.sin(a) * 1.35, 0), 0.06, 6, r.T)
            G.blob(g, (0, 0, -0.1), (0.3, 0.3, 0.3), "brillo", nu=8, nv=6)
        else:  # Geoda: geoda de roca y bronce, abierta, con el cristal dentro
            G.shell(m, (0, 2.0, 0), 11.5, 7.5, b.D, nu=26, nv=8, axis=(0, -1, 0), thickness=0.8, lip=0.08, noise=0.12, seed=5, inner_mat=b.B)
            for i in range(9):
                a = 2 * math.pi * i / 9
                base = Vector((math.cos(a) * 5.5, 1.5, math.sin(a) * 5.5))
                G.crystal(m, base, base + Vector((math.cos(a) * 3.0, 6.5 + (i % 3), math.sin(a) * 3.0)), 1.1, b.B, sides=6, tip=0.35)
            G.crystal(g, (0, 1.0, 0), (0, 10.5, 0), 2.4, "brillo", sides=6, tip=0.4)
            G.torus(m, (0, 1.8, 0), (0, 1, 0), 11.2, 0.5, b.T, n=32, m=6)
            G.torus(g, (0, -2.2, 0), (0, 1, 0), 6.0, 0.25, "brillo", n=28, m=5)
            for i in range(4):
                a = 2 * math.pi * i / 4 + math.pi / 4
                m.cylinder((math.cos(a) * 7.0, -1.0, math.sin(a) * 7.0), (math.cos(a) * 9.5, -6.5, math.sin(a) * 9.5), 0.6, 8, b.T)
                m.box((math.cos(a) * 9.6, -6.6, math.sin(a) * 9.6), (2.2, 0.4, 2.2), b.T)
            m.box((0, -4.6, -9.2), (5.0, 0.4, 7.0), b.T, up=(0, 0.94, -0.33))
    elif race == "Morfagos":
        if kind == "Fighter":
            G.shell(m, (0, 0, 0), 3.3, 2.6, b.B, nu=22, nv=7, axis=(0, 0.35, -0.94), thickness=0.2, lip=0.2, noise=0.06, seed=3, inner_mat=b.D)
            for i in range(8):
                a = 2 * math.pi * i / 8
                base = Vector((math.cos(a) * 2.5, math.sin(a) * 2.2, 1.2))
                pts = G.bezier(base, base + Vector((0, 0, 2.0)), base * 0.6 + Vector((0, -0.5, 4.0)), base * 0.3 + Vector((0, -1.0, 7.0 + (i % 3))), 8)
                G.tube(m, pts, [0.32 - 0.035 * k for k in range(len(pts))], b.X, 7)
            G.blob(g, (0, 0.2, -1.6), (1.0, 1.0, 0.7), "brillo", nu=14, nv=8)
            G.blob(m, (0, 0.2, -2.25), (0.3, 0.45, 0.1), b.D, nu=8, nv=5)
        elif kind == "Drone":
            G.blob(m, (0, 0, 0), (1.4, 1.4, 1.4), b.B, nu=14, nv=10, noise=0.1, seed=9)
            for i in range(10):
                a = 2.399 * i
                y = 1 - 2 * (i + 0.5) / 10
                d = Vector((math.cos(a) * math.sqrt(1 - y * y), y, math.sin(a) * math.sqrt(1 - y * y)))
                G.crystal(m, d * 1.2, d * 2.2, 0.16, b.X, sides=4, tip=0.6)
            G.blob(g, (0, 0, -1.2), (0.6, 0.6, 0.4), "brillo", nu=10, nv=6)
        else:  # Vaina: semilla gigante con costillas y una costura que brilla
            G.blob(m, (0, 1.0, 0), (8.5, 9.0, 11.0), b.B, nu=26, nv=14, noise=0.05, seed=4,
                   shape=lambda u, v: 1.0 - 0.08 * abs(math.sin(u * math.pi * 6)))
            for i in range(6):
                t = -0.7 + i * 0.28
                G.torus(m, (0, 1.0 + t * 9.0, 0), (0, 1, 0), 8.5 * math.sqrt(max(1 - t * t, 0.05)), 0.35, b.D, n=26, m=5)
            G.torus(g, (0, 1.0, 0), (1, 0, 0), 10.6, 0.35, "brillo", n=36, m=5, squash=1.0)
            for i in range(5):
                a = 2 * math.pi * i / 5
                pts = G.bezier((math.cos(a) * 5, -6, math.sin(a) * 5), (math.cos(a) * 8, -8, math.sin(a) * 8), (math.cos(a) * 9, -9, math.sin(a) * 9), (math.cos(a) * 10.5, -10.5, math.sin(a) * 10.5), 7)
                G.tube(m, pts, [1.0 - 0.1 * k for k in range(len(pts))], b.X, 8)
    elif race == "Ferrocefalos":
        if kind == "Fighter":
            r = rig.seg("Rotor", (0, 0, 0.5), "Body")
            r.m.cylinder((0, -0.35, 0.5), (0, 0.35, 0.5), 4.4, 28, r.B)
            for i in range(12):
                a = 2 * math.pi * i / 12
                p = Vector((math.cos(a) * 4.6, 0, 0.5 + math.sin(a) * 4.6))
                t = Vector((-math.sin(a), 0, math.cos(a)))
                r.m.box(p, (0.6, 0.5, 1.1), r.T, right=tuple(t), up=(0, 1, 0), taper=(0.2, 1.0))
            m.box((0, 0.9, 0), (2.4, 1.3, 2.6), b.D, taper=(0.85, 0.85))
            g.box((0, 1.05, -1.32), (1.8, 0.3, 0.06), "brillo")
            m.cylinder((0, 0.4, 0.5), (0, 1.0, 0.5), 1.2, 16, b.T)
            for side in (-1, 1):
                m.cylinder((side * 0.8, 1.2, 1.2), (side * 0.8, 2.3, 1.4), 0.2, 8, b.T)
        elif kind == "Drone":
            G.tube(m, [(0, -0.45, 0), (0, 0.45, 0)], [1.3, 1.3], b.B, 6, caps=True)
            m.cylinder((0, -0.5, 0), (0, 0.5, 0), 0.5, 10, b.D)
            r = rig.seg("Rotor", (0, 0.9, 0), "Body")
            r.m.cylinder((0, 0.55, 0), (0, 1.0, 0), 0.12, 6, r.T)
            for i in range(2):
                a = math.pi * i
                r.m.box((math.cos(a) * 1.2, 1.0, math.sin(a) * 1.2), (2.2, 0.06, 0.35), r.T, right=(math.cos(a), 0, math.sin(a)))
            g.box((0, 0, -1.15), (0.9, 0.22, 0.12), "brillo")
        else:  # Tolva: embudo remachado sobre andamios
            G.tube(m, [(0, -3.0, 0), (0, 6.5, 0)], [4.0, 10.0], b.B, 8, caps=True)
            G.torus(m, (0, 6.6, 0), (0, 1, 0), 10.0, 0.5, b.T, n=8, m=6)
            G.torus(m, (0, 1.5, 0), (0, 1, 0), 7.0, 0.35, b.T, n=8, m=6)
            for i in range(8):
                a = 2 * math.pi * i / 8 + math.pi / 8
                m.cylinder((math.cos(a) * 6.5, 6.0, math.sin(a) * 6.5), (math.cos(a) * 9.0, -7.0, math.sin(a) * 9.0), 0.4, 6, b.T)
            for i in range(3):
                a = 2 * math.pi * i / 3
                m.cylinder((math.cos(a) * 3.5, 6.0, math.sin(a) * 3.5), (math.cos(a) * 3.5, 10.5, math.sin(a) * 3.5), 0.8, 10, b.D)
                g.cylinder((math.cos(a) * 3.5, 10.4, math.sin(a) * 3.5), (math.cos(a) * 3.5, 10.6, math.sin(a) * 3.5), 0.65, 10, "brillo")
            g.box((0, 2.0, -7.6), (6.0, 0.6, 0.2), "brillo", up=(0, 1, 0))
            m.box((0, -3.6, -4.8), (4.5, 0.4, 5.0), b.T, up=(0, 0.9, -0.42))
    elif race == "Luminidos":
        if kind == "Fighter":
            arc = [Vector((math.cos(a) * 4.0, 0, -math.sin(a) * 4.0 + 1.0)) for a in [math.radians(t) for t in range(-30, 211, 12)]]
            G.tube(m, arc, [0.15 + 0.8 * math.sin(math.pi * i / (len(arc) - 1)) for i in range(len(arc))], b.B, 10, squash=0.5)
            G.tube(m, [p * 1.02 + Vector((0, 0.25, 0)) for p in arc], [0.05 + 0.25 * math.sin(math.pi * i / (len(arc) - 1)) for i in range(len(arc))], b.X, 6, squash=0.5)
            G.blob(g, (0, 0, 1.6), (1.2, 1.2, 1.2), "brillo", nu=14, nv=10)
            for side in (-1, 1):
                G.fin(m, [Vector((side * 0.8, 0, 2.2)), Vector((side * 2.2, 0.2, 5.5)), Vector((side * 0.9, 0, 4.0))], (0, 1, 0), 0.08, b.T)
                G.tube(g, [Vector((side * 0.9, 0.06, 2.4)), Vector((side * 2.0, 0.08, 5.2))], [0.06, 0.03], "brillo", 4)
        elif kind == "Drone":
            G.blob(g, (0, 0, 0), (0.9, 0.9, 0.9), "brillo", nu=12, nv=8)
            for ax in ((0, 1, 0), (1, 0, 0), (0.7, 0, 0.7)):
                G.torus(m, (0, 0, 0), ax, 1.25, 0.08, b.B, n=18, m=5)
            m.cylinder((0, 1.2, 0), (0, 1.9, 0), 0.08, 6, b.T)
            G.crystal(m, (0, 1.9, 0), (0, 2.5, 0), 0.18, b.X, sides=4)
        else:  # Farol: linterna enorme
            G.tube(m, [(0, -7, 0), (0, -6, 0)], [5.5, 6.5], b.B, 8)
            G.tube(m, [(0, 5.5, 0), (0, 7.0, 0), (0, 9.0, 0), (0, 10.5, 0)], [7.0, 5.0, 2.0, 0.3], b.X, 8)
            for i in range(8):
                a = 2 * math.pi * i / 8
                m.cylinder((math.cos(a) * 6.2, -6.0, math.sin(a) * 6.2), (math.cos(a) * 6.7, 5.6, math.sin(a) * 6.7), 0.45, 6, b.B)
            G.tube(g, [(0, -6.0, 0), (0, 0, 0), (0, 5.6, 0)], [5.6, 6.2, 6.4], "brillo", 8)
            G.torus(m, (0, 0, 0), (0, 1, 0), 6.6, 0.35, b.T, n=8, m=5)
            G.torus(m, (0, 11, 0), (1, 0, 0), 1.2, 0.25, b.B, n=16, m=5)
    else:  # Brumáridos
        if kind == "Fighter":
            outline = [Vector((0, 0, -4.2)), Vector((2.5, 0, -2.0)), Vector((5.5, 0, 0.8)), Vector((3.2, 0, 1.6)), Vector((0.9, 0, 2.6)), Vector((-0.9, 0, 2.6)), Vector((-3.2, 0, 1.6)), Vector((-5.5, 0, 0.8)), Vector((-2.5, 0, -2.0))]
            G.fin(m, outline, (0, 1, 0), 0.45, b.B)
            G.blob(m, (0, 0.2, -0.5), (1.4, 0.7, 2.8), b.B, nu=14, nv=8)
            G.blob(m, (0, -0.25, -0.4), (1.2, 0.4, 2.5), b.T, nu=12, nv=6)
            G.tube(m, [(0, 0, 2.5), (0, 0.1, 5.0), (0, 0.4, 8.0)], [0.35, 0.18, 0.05], b.D, 6)
            for i in range(6):
                x = -2.8 + i * 1.12
                G.blob(g, (x, 0.25, 0.4 + abs(x) * 0.15), (0.15, 0.06, 0.15), "brillo", nu=6, nv=4)
            G.blob(g, (0.6, 0.45, -2.6), (0.2, 0.15, 0.2), "brillo", nu=6, nv=4)
            G.blob(g, (-0.6, 0.45, -2.6), (0.2, 0.15, 0.2), "brillo", nu=6, nv=4)
        elif kind == "Drone":
            G.shell(m, (0, 0, 0), 1.4, 1.1, b.B, nu=16, nv=5, axis=(0, 1, 0), thickness=0.1, lip=0.15, inner_mat=b.D)
            for i in range(6):
                a = 2 * math.pi * i / 6
                pts = G.bezier((math.cos(a) * 0.9, 0, math.sin(a) * 0.9), (math.cos(a) * 1.0, -1.0, math.sin(a) * 1.0), (math.cos(a) * 0.6, -1.8, math.sin(a) * 0.6), (math.cos(a) * 0.8, -2.6, math.sin(a) * 0.8), 6)
                G.tube(m, pts, [0.1 - 0.012 * k for k in range(len(pts))], b.T, 5)
            G.blob(g, (0, 0.3, 0), (0.6, 0.45, 0.6), "brillo", nu=10, nv=6)
        else:  # Concha: vieira gigante con una perla de luz
            for sgn in (1, -1):
                G.shell(m, (0, 0.5 * sgn, 0), 11.0, 3.5, b.B if sgn > 0 else b.T, nu=28, nv=6, axis=(0, sgn, 0.12 * sgn), thickness=0.5, lip=0.05,
                        noise=0.0, inner_mat=b.D)
            for i in range(9):
                a = math.radians(-80 + i * 20)
                G.tube(m, [(0, 3.2, -2.0), (math.sin(a) * 10.5, 0.9, math.cos(a) * 10.5 - 1.5)], [0.6, 0.3], b.X, 6)
            G.blob(g, (0, 0, -1.0), (2.8, 2.8, 2.8), "brillo", nu=16, nv=10)
            for i in range(4):
                a = 2 * math.pi * i / 4 + math.pi / 4
                m.cylinder((math.cos(a) * 6.0, -1.5, math.sin(a) * 6.0), (math.cos(a) * 8.0, -6.5, math.sin(a) * 8.0), 0.55, 8, b.T)
    return rig


# Razas cuyas tropas, rey y naves se rehicieron con su hoja (scripts/invasion/vortidos_blender.py; aquí
# solo quedan sus criaturas). El diseño de antes sigue abajo (vortido, ship) por si hace falta compararlo.
CRYSTAL_REDONE = {"Vortidos"}


def build_all(only=None):
    """Todos los modelos: tropas (4) + rey + naves (3) + criaturas (2) de cada raza."""
    out = []
    for race in RACES:
        if only and race not in only:
            continue
        if race in CRYSTAL_REDONE:
            pass  # (las tropas, el rey y las naves de los Vórtidos los hace ahora vortidos_blender.py)
        else:
            for kind in ("Grunt", "Heavy", "Ranged", "Elite", "King"):
                out.append(build_troop(race, kind))
            for kind in ("Fighter", "Drone", "Dropship"):
                out.append(ship(race, kind))
        for cid, gait, height in CREATURES[race]:
            out.append(creature(race, cid, gait, height))
    return out
