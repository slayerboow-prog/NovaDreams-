"""El diseño de la nave por PARÁMETROS (scripts/nave/nave_blender.py lo convierte en mallas).

PRESETS["hx7"] es el caza del jugador, el «HX-7 Halcón» (diseño propio inspirado en la referencia del
dueño, docs/espacio-aaa/referencia-nave.png): blindaje blanco en capas sobre un casco gris grafito,
alas en flecha anchas con puntas rojas que brillan y franjas azules en el borde de ataque, lomo
elevado con la cabina de cristal tintado, tomas de aire laterales, DOS motores redondos grandes con
brillo azul y dos cañones bajo los costados.

Para otra nave (p. ej. las alienígenas de la grieta) basta con otro preset: mismas claves con otras
secciones, otro número de motores, otra paleta, otra semilla de «greebles»… (ver PRESETS["ejemplo_alien"]).

Coordenadas de Roblox: X derecha, Y arriba, Z hacia atrás (el morro mira a -Z). 1 unidad = 1 stud.
"""
import math
import random

from mathutils import Vector

from geo import MeshBuilder, V, merge, poly_point, resample_stations, surface_normal

PRESETS = {
    "hx7": {
        "Name": "HX-7 Halcón",
        "Designation": "HX-7",
        "Subtitle": "HALCÓN",
        "Seed": 7,
        # Fuselaje: (z, medio ancho, arriba, abajo)
        "Hull": [
            (-16.4, 0.06, 0.02, -0.12),
            (-14.5, 0.55, 0.32, -0.55),
            (-11.5, 1.2, 0.72, -0.98),
            (-8.0, 1.75, 1.02, -1.3),
            (-5.0, 2.15, 1.22, -1.5),
            (-2.0, 2.4, 1.32, -1.6),
            (1.5, 2.5, 1.42, -1.6),
            (5.0, 2.35, 1.48, -1.5),
            (8.0, 2.0, 1.35, -1.3),
            (10.2, 1.6, 1.1, -1.05),
        ],
        # Lomo elevado detrás de la cabina: (z, medio ancho, altura de arriba)
        "Spine": [(0.6, 0.95, 2.5), (3.0, 1.0, 2.42), (6.0, 0.95, 2.2), (9.0, 0.8, 1.85), (10.4, 0.6, 1.45)],
        # Cabina: (z, medio ancho, base, arriba)
        "Canopy": [(-5.2, 0.35, 1.16, 1.28), (-4.4, 0.95, 1.2, 2.0), (-3.0, 1.22, 1.27, 2.7), (-1.0, 1.28, 1.34, 2.98), (0.6, 1.2, 1.4, 2.92), (1.6, 0.95, 1.42, 2.55)],
        # Alas: (x, z borde de ataque, z borde de salida, grosor, y)
        "Wing": [(2.0, -5.6, 8.9, 0.58, -0.5), (4.5, -2.6, 8.9, 0.5, -0.55), (7.5, 1.1, 9.0, 0.38, -0.6), (10.5, 4.9, 9.3, 0.25, -0.66), (13.6, 8.6, 9.7, 0.09, -0.72)],
        "Strake": [(0.9, -11.8, -4.0, 0.2, -0.45), (2.4, -6.5, -4.0, 0.14, -0.5)],
        # Motores: centros (x, y), radio y largo
        "Engines": [(2.45, -0.25)],  # (se reflejan en X: dos motores)
        "EngineRadius": 1.6,
        "NozzleZ": 10.45,  # dónde va el brillo (la pieza «Escape» de Roblox)
        "Cannons": [(2.6, -1.85)],  # (reflejados) bajo los costados; la boca en z = -11
        "MuzzleZ": -11.0,
        "Fins": [(0.75, 1.55, 22.0)],  # derivas en el lomo: (x, y base, inclinación en grados)
        "Gear": [(0.0, -6.5, -1.3), (2.7, 4.2, -1.7), (-2.7, 4.2, -1.7)],  # (x, z, y de arriba)
        "GearBottom": -4.55,
        "Seat": (0.0, -1.25, -0.3),
        "Greebles": 1.0,  # densidad
        "Palette": {
            "blanco": (0.72, 0.74, 0.77),
            "grafito": (0.07, 0.075, 0.085),
            "oscuro": (0.02, 0.02, 0.025),
            "acero": (0.32, 0.33, 0.35),
            "rojo": (0.55, 0.03, 0.02),
            "naranja": (0.8, 0.25, 0.02),
            "pantalla": (0.05, 0.35, 0.9),
            "brillo_azul": (0.25, 0.6, 1.0),
            "brillo_rojo": (1.0, 0.08, 0.05),
        },
    },
}

# Un ejemplo de cómo reutilizarlo para otra nave (no se exporta: es la plantilla para la grieta)
PRESETS["ejemplo_alien"] = dict(PRESETS["hx7"], Name="Nave de la grieta", Designation="R-1", Subtitle="GRIETA", Seed=99, Engines=[(1.6, 0.0)], Palette=dict(PRESETS["hx7"]["Palette"], blanco=(0.25, 0.08, 0.35), brillo_azul=(0.9, 0.2, 1.0)))

MATERIALS = ["blanco", "grafito", "oscuro", "acero", "rojo", "naranja", "pantalla", "cristal", "brillo_azul", "brillo_rojo"]


# ---------------------------------------------------------------------- fuselaje
def hull_section(z, w, yt, yb):
    h = yt - yb
    pts = [(-0.5 * w, yt), (0, yt + 0.06 * h), (0.5 * w, yt), (w, yt - 0.28 * h), (w, yb + 0.38 * h), (0.55 * w, yb), (0, yb - 0.03 * h), (-0.55 * w, yb), (-w, yb + 0.38 * h), (-w, yt - 0.28 * h)]
    return [V(x, y, z) for x, y in pts]


class Hull:
    def __init__(self, P, step):
        self.st = resample_stations(P["Hull"], 0, step)
        self.z0, self.z1 = self.st[0][0], self.st[-1][0]

    def params(self, z):
        st = self.st
        z = min(max(z, self.z0), self.z1)
        for i in range(len(st) - 1):
            if st[i][0] <= z <= st[i + 1][0]:
                f = (z - st[i][0]) / max(st[i + 1][0] - st[i][0], 1e-6)
                return tuple(st[i][k] + (st[i + 1][k] - st[i][k]) * f for k in range(4))
        return st[-1]

    def point(self, z, s):
        _, w, yt, yb = self.params(z)
        return poly_point(hull_section(z, w, yt, yb), s)

    def surf(self, z, s):
        return surface_normal(self.point, z, s, outward_hint=lambda p: V(p.x, p.y * 0.6, 0) + V(0, 0.01, 0))


def hull_mat(center, i, j):
    # j: cara entre el punto j y el j+1 de la sección (0-1 arriba, 2 chaflán, 3 costado, 4 chaflán bajo, 5-6 panza)
    if j in (0, 1, 2, 9):
        return "blanco"
    if j in (3, 8):
        return "blanco" if center.z < -6 else "grafito"
    return "grafito"


# ---------------------------------------------------------------------- ala
class Wing:
    def __init__(self, stations, step):
        self.st = resample_stations(stations, 0, step)

    def chord(self, u):
        st = self.st
        t = min(max(u, 0), 1) * (len(st) - 1)
        i = min(int(t), len(st) - 2)
        f = t - i
        return tuple(st[i][k] + (st[i + 1][k] - st[i][k]) * f for k in range(5))

    def section(self, u):
        x, zle, zte, t, y0 = self.chord(u)
        c = zte - zle
        return [V(x, y0, zle), V(x, y0 + t / 2, zle + 0.38 * c), V(x, y0 + 0.12 * t, zte), V(x, y0 - 0.12 * t, zte), V(x, y0 - t / 2, zle + 0.38 * c)]

    def point(self, u, v, top=True):
        s = self.section(u)
        if top:
            return s[0].lerp(s[1], v / 0.38) if v <= 0.38 else s[1].lerp(s[2], (v - 0.38) / 0.62)
        return s[0].lerp(s[4], v / 0.38) if v <= 0.38 else s[4].lerp(s[3], (v - 0.38) / 0.62)

    def surf_top(self, u, v):
        return surface_normal(lambda a, b: self.point(a, b, True), u, v, outward_hint=lambda p: V(0, 1, 0))

    def surf_bot(self, u, v):
        return surface_normal(lambda a, b: self.point(a, b, False), u, v, outward_hint=lambda p: V(0, -1, 0))

    def loft(self, mb, mat, n):
        rings = [self.section(i / n) for i in range(n + 1)]
        mb.loft(rings, mat)


# ---------------------------------------------------------------------- piezas
def build_hull(P, lod=False):
    """El fuselaje con el lomo, las tomas de aire, las derivas, las placas y los «greebles»."""
    rng = random.Random(P["Seed"])
    hull = Hull(P, 0.6 if lod else 0.8)
    mb = MeshBuilder(MATERIALS)
    rings = [hull_section(s[0], s[1], s[2], s[3]) for s in hull.st]
    mb.loft(rings, "blanco", matfn=hull_mat)
    # Lomo elevado
    sp = resample_stations(P["Spine"], 0, 1.5 if lod else 1.0)
    rings = []
    for z, hw, top in sp:
        base = hull.params(z)[2] - 0.2
        rings.append([V(-hw, base, z), V(hw, base, z), V(hw, top - 0.35, z), V(0.55 * hw, top, z), V(-0.55 * hw, top, z), V(-hw, top - 0.35, z)])
    mb.loft(rings, "blanco", matfn=lambda c, i, j: "blanco" if j in (2, 3, 4) else "grafito")
    half = MeshBuilder(MATERIALS)
    # Tomas de aire laterales (sponsons) con la boca oscura
    rings = []
    for z, x0, x1, y0, y1 in ((-5.3, 1.9, 2.9, -1.2, -0.35), (-4.6, 1.7, 3.3, -1.45, -0.05), (1.8, 1.7, 3.3, -1.45, -0.05), (2.6, 1.8, 3.1, -1.3, -0.2)):
        rings.append([V(x0, y0, z), V(x1, y0, z), V(x1, y1, z), V(x0, y1, z)])
    half.loft(rings, "grafito", matfn=lambda c, i, j: "blanco" if j == 2 else None)
    half.box((2.4, -0.72, -5.32), (0.82, 0.68, 0.1), "oscuro")
    # Strake (borde que va del morro a la raíz del ala)
    Wing(P["Strake"], 0.8).loft(half, "blanco", 1 if lod else 3)
    if not lod:
        # El ala (la chapa) va con el fuselaje: solo, gris y sin textura, el fuselaje era un tubo largo y liso
        # con la punta redondeada, lo que la moderación de Roblox malinterpreta (docs/bugs/moderacion/). Con
        # las alas se lee como lo que es: un avión. La pieza «Alas» lleva las placas, alerones y puntas.
        Wing(P["Wing"], 0.9).loft(half, "grafito", 12)
    # Derivas inclinadas en el lomo, con la punta roja
    for fx, fy, cant in P["Fins"]:
        a = math.radians(cant)
        out, up = V(math.sin(a), math.cos(a), 0), V(math.cos(a), -math.sin(a), 0)
        rings = []
        for h, zle, zte, t in ((0.0, 5.4, 9.8, 0.16), (1.75, 8.6, 9.95, 0.08)):
            base = V(fx, fy, 0) + out * h
            rings.append([base + V(0, 0, zle), base + up * (t / 2) + V(0, 0, (zle + zte) / 2), base + V(0, 0, zte), base - up * (t / 2) + V(0, 0, (zle + zte) / 2)])
        half.loft(rings, "blanco", matfn=lambda c, i, j: "rojo" if c.y > fy + 1.2 else None)
    if not lod:
        # Placas de blindaje en capas (encima del casco)
        for z0, z1, s0, s1, m in ((-13.2, -8.7, 0.12, 1.88, "blanco"), (-8.4, -5.5, 0.15, 1.85, "blanco"), (-12.6, -6.4, 2.08, 2.95, "blanco"), (-4.0, 1.6, 3.08, 3.94, "blanco"), (2.0, 7.6, 3.08, 3.94, "grafito"), (-11.8, -6.8, 3.1, 3.9, "blanco"), (-5.0, 2.0, 4.05, 4.9, "grafito")):
            nseg = max(2, int((z1 - z0) / 0.8))
            if s0 < 2 and s1 <= 2:
                mb.slab(hull.surf, z0, z1, s0, s1, nseg, 0.045, m, vbreaks=(1,))
            else:
                half.slab(hull.surf, z0, z1, s0, s1, nseg, 0.045, m, vbreaks=(3, 4))
        # Rejillas en el lomo (lamas) y tomas NACA
        for k in range(7):
            z = 3.0 + k * 0.28
            mb.box((0, 2.42 - 0.02 * k, z), (0.9, 0.08, 0.12), "oscuro")
        mb.box((0, 2.33, 5.6), (0.5, 0.18, 1.2), "grafito", taper=(0.7, 0.5))
        # Antenas y sonda del morro
        mb.cylinder((0, 0.0, -16.3), (0, 0.0, -17.4), 0.045, 6, "acero")
        mb.cylinder((0.35, 2.3, 4.2), (0.42, 3.35, 4.9), 0.035, 6, "acero")
        mb.cylinder((-0.3, 2.05, 7.2), (-0.34, 2.9, 7.6), 0.03, 6, "acero")
        mb.box((0.42, 3.38, 4.92), (0.12, 0.12, 0.12), "rojo")
        # Greebles: cajitas y tubos en los costados del lomo, encima de las tomas y en los flancos
        dens = P["Greebles"]
        for k in range(int(26 * dens)):
            z = rng.uniform(1.5, 9.4)
            hw = 0.95 - 0.35 * max(0, (z - 3) / 7.4)
            y = rng.uniform(1.55, 2.0 - 0.04 * z)
            sx, sy, sz = rng.uniform(0.08, 0.2), rng.uniform(0.12, 0.35), rng.uniform(0.25, 0.9)
            half.box((hw + sx / 2 - 0.02, y, z), (sx, sy, sz), rng.choice(["grafito", "acero", "oscuro"]))
        for k in range(int(18 * dens)):
            z = rng.uniform(-4.2, 1.4)
            x = rng.uniform(1.85, 3.1)
            sx, sy, sz = rng.uniform(0.15, 0.45), rng.uniform(0.05, 0.14), rng.uniform(0.2, 0.7)
            half.box((x, -0.05 + sy / 2 - 0.01, z), (sx, sy, sz), rng.choice(["grafito", "acero", "blanco"]))
        for k in range(3):  # tubos por el flanco
            y = -0.55 - k * 0.18
            half.cylinder((2.2 + 0.05 * k, y, -2.5 - k), (2.25, y, 6.5), 0.055, 6, "acero")
        # Marcas de luz (posición) en la panza y el lomo
        mb.box((0, -1.6, 2.0), (0.6, 0.06, 0.6), "acero")
    half_m = MeshBuilder(MATERIALS)
    merge(half_m, half)
    half_m.mirror_x()
    return merge(mb, half_m)


def build_wings(P, lod=False):
    mb = MeshBuilder(MATERIALS)
    # (de lejos, el ala entera; de cerca, la chapa va con el fuselaje —build_hull— y aquí las placas encima)
    wing = Wing(P["Wing"], 1.5 if lod else 0.9)
    n = 8 if lod else 12
    if lod:
        wing.loft(mb, "blanco", n)
    if not lod:
        top, bot = wing.surf_top, wing.surf_bot
        for u0, u1, v0, v1 in ((0.03, 0.40, 0.10, 0.80), (0.42, 0.70, 0.14, 0.84), (0.72, 0.88, 0.22, 0.86), (0.08, 0.36, 0.02, 0.085)):
            mb.slab(top, u0, u1, v0, v1, 5, 0.05, "blanco", vbreaks=(0.38,))
        for u0, u1 in ((0.05, 0.30), (0.32, 0.60), (0.62, 0.86)):
            mb.slab(top, u0, u1, 0.87, 0.985, 3, 0.03, "grafito")
        mb.slab(top, 0.9, 0.995, 0.06, 0.95, 2, 0.035, "rojo", vbreaks=(0.38,))
        mb.slab(bot, 0.9, 0.995, 0.06, 0.95, 2, 0.03, "rojo", vbreaks=(0.38,))
        for u0, u1, v0, v1 in ((0.05, 0.5, 0.15, 0.8), (0.55, 0.85, 0.2, 0.8)):
            mb.slab(bot, u0, u1, v0, v1, 4, 0.03, "grafito", vbreaks=(0.38,))
        # Bisagras de los alerones y un sensor en la punta
        for u in (0.18, 0.46, 0.74):
            p, nrm = top(u, 0.86)
            mb.box(p + nrm * 0.03, (0.35, 0.08, 0.16), "acero")
    else:
        mb.slab(wing.surf_top, 0.9, 0.995, 0.06, 0.95, 1, 0.03, "rojo", vbreaks=(0.38,))
    mb.mirror_x()
    return mb


def build_glow(P, color, lod=False):
    """Las tiras que brillan (Neon en Roblox): azul en el borde de ataque y los costados; rojo en las puntas."""
    mb = MeshBuilder(MATERIALS)
    wing = Wing(P["Wing"], 0.9)
    hull = Hull(P, 0.8)
    if color == "brillo_azul":
        mb.slab(wing.surf_top, 0.26, 0.88, 0.012, 0.05, 6, 0.025, color)
        mb.slab(wing.surf_bot, 0.2, 0.88, 0.02, 0.07, 6, 0.025, color)
        if not lod:
            mb.slab(hull.surf, -10.5, -3.5, 3.42, 3.56, 6, 0.03, color)
            mb.slab(hull.surf, 1.0, 8.5, 3.6, 3.7, 6, 0.06, color)
            for cx, cy in P["Cannons"]:
                mb.lathe([(0.24, -6.6), (0.27, -6.5), (0.27, -6.1), (0.24, -6.0)], (cx, cy, 0), 10, color)
    else:
        mb.slab(wing.surf_top, 0.935, 0.998, 0.0, 0.28, 2, 0.045, color)
        mb.slab(wing.surf_bot, 0.935, 0.998, 0.0, 0.28, 2, 0.045, color)
        x, zle, zte, t, y0 = wing.chord(1.0)
        mb.box((x + 0.02, y0, zte - 0.15), (0.12, 0.12, 0.35), color)
    mb.mirror_x()
    return mb


def build_engines(P, lod=False):
    mb = MeshBuilder(MATERIALS)
    rng = random.Random(P["Seed"] + 1)
    R = P["EngineRadius"]
    segs = 32 if lod else 40
    for ex, ey in P["Engines"]:
        k = R / 1.6
        prof = [(0.95, -0.2), (1.35, 0.6), (1.55, 1.6), (1.6, 6.4), (1.72, 6.6), (1.72, 7.3), (1.6, 7.5), (1.62, 9.0), (1.74, 9.2), (1.74, 9.6), (1.62, 10.9), (1.36, 10.95), (1.28, 10.3), (1.05, 10.15), (0.45, 10.05)]
        if lod:
            prof = [(1.35, 0.4), (1.6, 1.6), (1.6, 6.4), (1.72, 6.7), (1.6, 7.5), (1.74, 9.3), (1.6, 10.9), (1.3, 10.9), (0.5, 10.1)]
        prof = [(r * k, z) for r, z in prof]

        def emat(c, i, j, ex=ex, ey=ey):
            rad = math.hypot(c.x - ex, c.y - ey)
            if c.z > 9.95 and rad < 1.42 * k:
                return "oscuro"
            if c.z > 6.5:
                return "grafito"
            if 3.6 < c.z < 4.6:
                return "acero"
            return "blanco"

        mb.lathe(prof, (ex, ey, 0), segs, "blanco", matfn=emat)
        if not lod:
            # Pétalos de la tobera, anillo y tubos
            for q in range(16):
                a = 2 * math.pi * q / 16
                d = V(math.cos(a), math.sin(a), 0)
                c = V(ex, ey, 10.35) + d * (1.7 * k)
                mb.box(c, (0.32, 0.07, 0.75), "acero", right=d.cross(V(0, 0, 1)), up=d)
            mb.lathe([(1.6 * k, 3.75), (1.69 * k, 3.85), (1.69 * k, 4.45), (1.6 * k, 4.55)], (ex, ey, 0), segs, "acero")
            for a in (0.6, 1.1, 2.4):
                d = V(math.cos(a), math.sin(a), 0)
                p0 = V(ex, ey, 1.6) + d * (1.66 * k)
                mb.cylinder(p0, p0 + V(0, 0, 4.6), 0.07, 6, "acero")
            for q in range(10):
                a = rng.uniform(0.3, 2.8)
                z = rng.uniform(1.8, 6.0)
                d = V(math.cos(a), math.sin(a), 0)
                c = V(ex, ey, z) + d * (1.62 * k)
                sx, sy, sz = rng.uniform(0.15, 0.4), rng.uniform(0.06, 0.16), rng.uniform(0.25, 0.8)
                mb.box(c + d * (sy / 2), (sx, sy, sz), rng.choice(["grafito", "acero"]), right=d.cross(V(0, 0, 1)), up=d)
            # Cono interior de la tobera
            mb.lathe([(1.0 * k, 10.12), (0.55 * k, 9.75), (0.12 * k, 9.5)], (ex, ey, 0), 16, "oscuro", cap0=False)
    mb.mirror_x()
    return mb


def build_cannons(P, lod=False):
    mb = MeshBuilder(MATERIALS)
    mz = P["MuzzleZ"]
    for cx, cy in P["Cannons"]:
        rings = []
        for z, s in ((-5.0, 0.6), (-4.4, 1.0), (1.6, 1.0), (2.2, 0.7)):
            rings.append([V(cx - 0.36 * s, cy - 0.3 * s, z), V(cx + 0.36 * s, cy - 0.3 * s, z), V(cx + 0.36 * s, cy + 0.3 * s, z), V(cx - 0.36 * s, cy + 0.3 * s, z)])
        mb.loft(rings, "grafito")
        mb.box((cx, cy + 0.35, -1.0), (0.3, 0.3, 3.2), "grafito")  # pilón
        if lod:
            mb.cylinder((cx, cy, -4.6), (cx, cy, mz), 0.22, 10, "acero")
            continue
        prof = [(0.33, -4.6), (0.33, -5.4), (0.22, -5.6), (0.2, mz + 1.4), (0.29, mz + 1.2), (0.29, mz + 0.2), (0.25, mz), (0.12, mz)]
        mb.lathe([(r, z) for r, z in prof], (cx, cy, 0), 16, "acero", matfn=lambda c, i, j: "oscuro" if c.z < mz + 0.1 else None)
        mb.box((cx, cy - 0.42, -0.6), (0.5, 0.3, 1.8), "oscuro")  # caja de munición
        for z in (-3.6, -2.4, -1.2):
            mb.box((cx + 0.38, cy, z), (0.06, 0.4, 0.5), "acero")
        mb.box((cx, cy + 0.32, -3.9), (0.5, 0.06, 0.8), "rojo")  # marca de peligro
    mb.mirror_x()
    return mb


CANOPY_ARC = 5  # (cabina facetada, de pocas caras con aristas vivas: no una cápsula lisa; docs/bugs/moderacion/)


def canopy_rings(P, step, arc):
    st = resample_stations(P["Canopy"], 0, step)
    rings = []
    for z, hw, base, top in st:
        ring = []
        for k in range(arc + 1):
            a = math.pi * k / arc
            s = math.sin(a)
            ring.append(V(hw * math.cos(a), base + (top - base) * (s ** 0.75), z))
        rings.append(ring)
    return rings


def canopy_bars(mb, rings, mat):
    """Los largueros y arcos del marco, por fuera del cristal (en cada arista de la cabina facetada)."""
    def out(p):  # (un poco por fuera del cristal)
        base = V(0, p.y - 0.3, p.z)
        return p + (p - base).normalized() * 0.035

    n = len(rings)
    for i in sorted({int(n * 0.22), int(n * 0.55), n - 2}):  # tres arcos
        ring = rings[i]
        for k in range(len(ring) - 1):
            mb.cylinder(out(ring[k]), out(ring[k + 1]), 0.065, 6, mat)
    for k in range(len(rings[0])):  # un larguero en cada arista
        for i in range(n - 1):
            mb.cylinder(out(rings[i][k]), out(rings[i + 1][k]), 0.09 if k in (0, len(rings[0]) - 1) else 0.07, 6, mat)


def build_canopy(P, lod=False):
    """La cabina de cristal, facetada y con su marco en la misma malla: sola, gris y sin textura, una cabina
    lisa era una cápsula (docs/bugs/moderacion/); con el marco se lee como una cabina."""
    mb = MeshBuilder(MATERIALS)
    rings = canopy_rings(P, 0.9, 8 if lod else CANOPY_ARC)  # (la LOD, como antes)
    mb.loft(rings, "cristal")
    if not lod:
        canopy_bars(mb, rings, "cristal")
    return mb


def build_canopy_frame(P):
    """Marco de la cabina (aristas de una cabina de pocas caras, engordadas por un Wireframe) + el
    salpicadero con pantallas, consolas y el reposacabezas."""
    frame = MeshBuilder(MATERIALS)
    # (los largueros y arcos del marco van ahora con el cristal: build_canopy)
    # Salpicadero y pantallas (se ven por el cristal)
    frame.box((0, 1.62, -3.35), (2.0, 0.42, 0.85), "grafito", up=(0, 0.95, 0.3))
    for x, w in ((-0.62, 0.5), (0.0, 0.62), (0.62, 0.5)):
        frame.box((x, 1.86, -3.05), (w, 0.36, 0.04), "pantalla", up=(0, 0.6, 0.8))
    for side in (-1, 1):
        frame.box((side * 0.92, 1.5, -1.0), (0.32, 0.22, 2.6), "grafito")
        frame.box((side * 0.92, 1.62, -1.2), (0.2, 0.03, 0.5), "pantalla")
    frame.box((0, 2.0, 0.95), (0.95, 1.15, 0.32), "grafito")
    frame.cylinder((0.35, 1.4, -2.2), (0.35, 1.85, -2.35), 0.05, 6, "oscuro")
    return frame


def build_gear(P):
    mb = MeshBuilder(MATERIALS)
    bottom = P["GearBottom"]
    for x, z, ytop in P["Gear"]:
        mb.cylinder((x, ytop, z), (x, bottom + 0.35, z), 0.13, 10, "acero")
        mb.cylinder((x, ytop, z), (x, ytop - 1.4, z), 0.21, 10, "grafito")
        mb.cylinder((x, bottom, z), (x, bottom + 0.3, z), 0.72, 18, "oscuro")
        mb.box((x, ytop - 1.9, z + 0.25), (0.1, 0.9, 0.12), "acero")
        mb.box((x + 0.55, ytop - 0.55, z), (0.06, 1.1, 1.5), "grafito")  # compuerta
        mb.box((x - 0.55, ytop - 0.55, z), (0.06, 1.1, 1.5), "grafito")
    return mb


def build_lod(P):
    """Versión lejana (una sola malla, ≈ 3–5 mil triángulos)."""
    mb = MeshBuilder(MATERIALS)
    for b in (build_hull(P, True), build_wings(P, True), build_engines(P, True), build_cannons(P, True), build_canopy(P, True), build_glow(P, "brillo_azul", True), build_glow(P, "brillo_rojo", True)):
        merge(mb, b)
    return mb
