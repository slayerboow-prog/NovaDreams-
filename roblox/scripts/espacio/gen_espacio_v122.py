"""Texturas nuevas del espacio para parecerse a la referencia del dueño (docs/espacio-aaa/referencia-espacio-v121.png).

Uso (desde roblox/):   python3 -I scripts/espacio/gen_espacio_v122.py            (todas)
                       python3 -I scripts/espacio/gen_espacio_v122.py cielo      (solo las que empiezan así)
                       python3 -I scripts/espacio/gen_espacio_v122.py --mock     (y la maqueta de docs/espacio-aaa/)
Necesita:              pip install numpy pillow

Todo sale de código (ruido fractal sobre la esfera, como scripts/espacio/gen.py, del que se usan las
mismas funciones): nada copiado, CC0 (assets/espacio/LICENCIAS.md). Nombres NUEVOS para no pisar los
ids ya subidos; el juego usa el nuevo si está subido y, si no, el de antes (shared/Cosmos/EspacioLook):

  cielo_nebulosa_{bk,dn,ft,lf,rt,up}.jpg  cielo del espacio más vivo: nebulosas moradas, azules y rosas,
                                          Vía Láctea brillante y muchas más estrellas (1024)
  planeta_tefra.jpg                       Tefra: corteza de basalto negro con grietas de lava (1024x512)
  planeta_vertice.jpg                     Vértice: gigante gaseoso a franjas beige y marrones (1024x512)
  valmar_tierra.jpg                       Valmar como la Tierra: la isla de verdad en el polo de arriba
                                          (de valmar_planeta.jpg) y más continentes, mares y hielo (1024x512)
  nubes_valmar.png                        nubes de Valmar con transparencia (1024x512)
  anillos_vertice.png, anillos_miasma.png anillos con bandas finas y huecos, con transparencia (1024)
"""

from __future__ import annotations

import importlib.util
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("espacio_gen", HERE / "gen.py")
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)  # type: ignore[union-attr]

ROOT = G.ROOT
OUT = G.OUT
DOCS = ROOT / "docs" / "espacio-aaa"
col, fbm, ridged, warp, smooth, mix_palette, save = G.col, G.fbm, G.ridged, G.warp, G.smooth, G.mix_palette, G.save


# ---------------------------------------------------------------------------
# Cielo: nebulosas de color en todas direcciones (nunca un suelo azul)
# ---------------------------------------------------------------------------
GAL = np.array([0.25, 0.55, -0.8], np.float32)
GAL /= np.linalg.norm(GAL)


def nebula_color(d):
    p = (d[..., 0] * 2.0, d[..., 1] * 2.0, d[..., 2] * 2.0)
    q = warp(p, 1.6, 1.0, 13)
    n1 = fbm(q, 7, 1.5, seed=111)
    n2 = fbm(warp(p, 1.2, 1.6, 17), 6, 2.4, seed=123)
    dust = fbm(p, 6, 4.5, seed=141)
    img = np.zeros(d.shape, np.float32)
    img += col(5, 7, 22)  # azul marino muy oscuro (nunca negro plano)
    # Nebulosas grandes: morada, azul y rosa, repartidas por todo el cielo (también abajo)
    focos = [
        ((0.75, 0.25, -0.6), col(150, 60, 210), 1.8),
        ((-0.6, -0.35, -0.7), col(60, 110, 235), 1.6),
        ((0.2, -0.7, 0.65), col(225, 70, 160), 1.7),
        ((-0.8, 0.45, 0.4), col(90, 70, 220), 1.9),
        ((0.55, -0.2, 0.8), col(40, 150, 230), 2.0),
        ((0.0, 0.95, -0.2), col(170, 80, 200), 2.4),
        ((-0.2, -0.95, -0.1), col(120, 60, 200), 2.2),
    ]
    a = smooth(0.52, 0.84, n1) ** 1.4 * (0.3 + 0.7 * smooth(0.35, 0.8, n2))
    for v, c, k in focos:
        v = np.array(v, np.float32)
        v /= np.linalg.norm(v)
        f = np.clip(d @ v, 0, 1) ** k
        img += (a * f)[..., None] * c * 0.85
        img += (smooth(0.68, 0.92, n2) * a * f)[..., None] * (c * 0.5 + col(255, 255, 255) * 0.25) * 0.4
    # Vía Láctea: banda brillante con grietas de polvo
    g = np.abs(d @ GAL)
    band = np.exp(-(g ** 2) / 0.045)
    core = np.exp(-(g ** 2) / 0.01)
    lanes = smooth(0.52, 0.76, fbm(p, 6, 3.2, seed=157)) * band
    img += (band * (0.3 + 0.7 * dust) * (1 - 0.75 * lanes))[..., None] * col(150, 140, 190) * 0.55
    img += (core * (0.4 + 0.6 * dust) * (1 - lanes))[..., None] * col(255, 225, 200) * 0.38
    return img


def gen_sky():
    stars = G.star_list(42000, 202, GAL, 0.5)
    for name in G.FACES:
        d = G.face_dirs(name)
        img = nebula_color(d)
        G.splat_stars(img, d, name, stars, 1.35)
        img = 1 - np.exp(-img * 1.35)
        save(img, f"cielo_nebulosa_{name}.jpg", 93)


# ---------------------------------------------------------------------------
# Planetas
# ---------------------------------------------------------------------------
def planet_tefra(d, lat):
    p = (d[..., 0] * 1.7, d[..., 1] * 1.7, d[..., 2] * 1.7)
    e = fbm(warp(p, 0.7, 1.2, 21), 7, 1.0, seed=901)
    crust = fbm(p, 6, 7.0, seed=903)
    heat = fbm(warp(p, 0.5, 1.8, 27), 6, 1.6, seed=911)
    # Roca fundida (rojo y naranja) debajo de placas de corteza negra y marrón
    molten = mix_palette([(0.0, col(120, 20, 8)), (0.35, col(196, 52, 14)), (0.6, col(240, 104, 28)), (0.85, col(255, 176, 60)), (1.0, col(255, 222, 120))], heat * 0.8 + crust * 0.2)
    plates = mix_palette([(0.0, col(14, 9, 9)), (0.5, col(40, 24, 20)), (1.0, col(78, 46, 34))], crust)
    r1 = ridged(warp(p, 0.35, 2.2, 23), 6, 2.2, seed=905)
    r2 = ridged(warp(p, 0.25, 4.0, 29), 5, 4.5, seed=907)
    # dónde hay corteza: las placas (fuera de las grietas y de los mares de lava)
    crack = np.maximum(smooth(0.72, 0.9, r1), smooth(0.8, 0.95, r2) * 0.85)
    sea = smooth(0.46, 0.38, e)
    cover = np.clip(smooth(0.35, 0.6, e) * (1 - crack) * (1 - sea), 0, 1) * 0.92
    img = molten * (1 - cover[..., None]) + plates * cover[..., None]
    # borde de las placas: brasa
    rim = smooth(0.55, 0.8, r1) * (1 - crack) * cover
    img += rim[..., None] * col(200, 50, 10) * 0.35
    return np.clip(img, 0, 1)


def planet_vertice(d, lat):
    p = (d[..., 0] * 2.0, d[..., 1] * 2.0, d[..., 2] * 2.0)
    turb = fbm(warp(p, 0.55, 2.6, 31), 6, 2.2, seed=1001)
    fine = fbm(p, 5, 9.0, seed=1003)
    y = d[..., 1] + (turb - 0.5) * 0.12
    b1 = 0.5 + 0.5 * np.sin(y * 21 + np.sin(y * 6.5) * 2.2)
    b2 = 0.5 + 0.5 * np.sin(y * 57 + turb * 6)
    t = np.clip((y + 1) / 2, 0, 1)
    base = mix_palette([
        (0.0, col(150, 112, 80)), (0.18, col(214, 180, 140)), (0.32, col(170, 120, 82)), (0.45, col(236, 214, 178)),
        (0.55, col(196, 150, 104)), (0.68, col(240, 222, 190)), (0.82, col(160, 116, 80)), (1.0, col(206, 176, 140)),
    ], t)
    img = base * (0.72 + 0.22 * b1[..., None] + 0.1 * b2[..., None]) * (0.92 + 0.12 * fine[..., None])
    # Gran mancha (tormenta ovalada)
    c = np.array([0.7, -0.32, 0.64], np.float32)
    c /= np.linalg.norm(c)
    dd = 1 - d @ c
    spot = np.exp(-dd / 0.01) * (0.7 + 0.3 * turb)
    img = img * (1 - 0.7 * spot[..., None]) + spot[..., None] * col(196, 96, 60) * 0.75
    return np.clip(img, 0, 1)


def gen_planets():
    d, lat = G.sphere_dirs()
    save(planet_tefra(d, lat), "planeta_tefra.jpg", 92)
    save(planet_vertice(d, lat), "planeta_vertice.jpg", 92)


# ---------------------------------------------------------------------------
# Valmar como la Tierra (la isla de verdad arriba, más tierras y hielo)
# ---------------------------------------------------------------------------
def gen_valmar():
    base_path = OUT / "valmar_planeta.jpg"
    base = np.asarray(Image.open(base_path).convert("RGB"), np.float32) / 255.0
    H, W = base.shape[:2]
    d, lat = G.sphere_dirs(W, H)
    v = (np.arange(H, dtype=np.float32) + 0.5) / H
    vv = np.repeat(v[:, None], W, 1)
    p = (d[..., 0] * 1.5, d[..., 1] * 1.5, d[..., 2] * 1.5)
    e = fbm(warp(p, 0.65, 1.2, 41), 7, 1.0, seed=1101)
    detail = fbm(p, 6, 6.0, seed=1103)
    # Océano: azul profundo con bajíos más claros cerca de la costa
    ocean = mix_palette([(0.0, col(6, 34, 96)), (0.42, col(10, 64, 150)), (0.5, col(24, 100, 178))], e)
    land_mask = smooth(0.52, 0.54, e + (detail - 0.5) * 0.05)
    hum = fbm(p, 5, 2.4, seed=1105)
    land = mix_palette([(0.0, col(196, 168, 112)), (0.35, col(150, 140, 84)), (0.55, col(64, 112, 52)), (1.0, col(30, 82, 40))], hum)
    land *= (0.85 + 0.25 * detail)[..., None]
    mount = smooth(0.66, 0.78, e)
    land = land * (1 - 0.5 * mount[..., None]) + mount[..., None] * col(120, 104, 90) * 0.5
    world = ocean * (1 - land_mask[..., None]) + land * land_mask[..., None]
    # Hielo en el polo de abajo
    ice = smooth(0.9, 0.95, vv + (detail - 0.5) * 0.04)
    world = world * (1 - ice[..., None]) + ice[..., None] * col(236, 242, 250)
    # La isla de verdad (casquete de arriba) se queda tal cual; se funde hacia el mundo nuevo
    keep = smooth(0.48, 0.4, vv)
    # (el mar de la textura vieja junto a la isla se oscurece un poco para casar con el océano nuevo)
    out = base * keep[..., None] + world * (1 - keep[..., None])
    save(np.clip(out, 0, 1), "valmar_tierra.jpg", 92)
    # Nubes de Valmar (con transparencia): remolinos, más en las latitudes medias
    q = warp((d[..., 0] * 2.2, d[..., 1] * 2.2, d[..., 2] * 2.2), 1.2, 1.4, 1201)
    n = fbm(q, 7, 1.4, seed=1203)
    band = 0.75 + 0.25 * np.cos(lat * 3.0)
    a = smooth(0.5, 0.7, n * band) * 0.88
    rgba = np.zeros((H, W, 4), np.float32)
    rgba[..., :3] = 0.92 + 0.08 * fbm(q, 4, 6, seed=1205)[..., None]
    rgba[..., 3] = a
    save(rgba, "nubes_valmar.png")


# ---------------------------------------------------------------------------
# Anillos (el juego los pone en una pieza plana con un SurfaceGui; el agujero del centro es transparente)
# ---------------------------------------------------------------------------
RINGS = {
    # (radio interior / exterior como en shared/Cosmos/PlanetBodies.Rings, colores, semilla)
    "vertice": (1.3 / 1.95, [col(236, 214, 172), col(188, 150, 110), col(250, 236, 206), col(150, 116, 86)], 71),
    "miasma": (1.35 / 2.25, [col(214, 170, 236), col(150, 110, 200), col(240, 210, 250), col(120, 90, 170)], 73),
}


def gen_rings():
    n = 1024
    s = (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(s, s)
    r = np.sqrt(x * x + y * y)
    for pid, (inner, cols, seed) in RINGS.items():
        rng = np.random.default_rng(seed)
        t = np.clip((r - inner) / (1 - inner), 0, 1)
        # muchas bandas finas con su densidad; dos huecos claros
        k = 220
        dens = rng.random(k).astype(np.float32)
        dens = np.convolve(dens, np.ones(3) / 3, mode="same")
        idx = np.clip((t * (k - 1)).astype(int), 0, k - 1)
        a = 0.35 + 0.6 * dens[idx]
        for g0, g1 in ((0.42, 0.47), (0.78, 0.8)):
            a *= 1 - 0.9 * smooth(g0 - 0.01, g0, t) * smooth(g1 + 0.01, g1, t)
        a *= smooth(0.0, 0.03, t) * smooth(1.0, 0.96, t)
        a *= (r >= inner) & (r <= 1)
        ci = np.clip(t * (len(cols) - 1), 0, len(cols) - 1.001)
        i0 = ci.astype(int)
        f = (ci - i0)[..., None]
        c = np.stack(cols)[i0] * (1 - f) + np.stack(cols)[np.minimum(i0 + 1, len(cols) - 1)] * f
        c *= (0.85 + 0.3 * dens[idx])[..., None]
        rgba = np.zeros((n, n, 4), np.float32)
        rgba[..., :3] = np.clip(c, 0, 1)
        rgba[..., 3] = np.clip(a, 0, 1)
        save(rgba, f"anillos_{pid}.png")


# ---------------------------------------------------------------------------
# Maqueta (no es una captura del juego): cómo deberían verse juntas las texturas nuevas con la luz del
# espacio, los marcadores nuevos y sin suelo azul. Se compara con la referencia del dueño.
# ---------------------------------------------------------------------------
def _sky_view(w, h, fov=70.0, yaw=0.0, pitch=-0.08):
    faces = {name: np.asarray(Image.open(OUT / f"cielo_nebulosa_{name}.jpg").convert("RGB"), np.float32) / 255 for name in G.FACES}
    xs = (np.arange(w, dtype=np.float32) + 0.5) / w * 2 - 1
    ys = (np.arange(h, dtype=np.float32) + 0.5) / h * 2 - 1
    X, Y = np.meshgrid(xs, -ys)
    k = math.tan(math.radians(fov) / 2)
    dirs = np.stack([X * k * w / h, Y * k, -np.ones_like(X)], -1)
    cy, sy, cp, sp = math.cos(yaw), math.sin(yaw), math.cos(pitch), math.sin(pitch)
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]], np.float32)
    Rx = np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]], np.float32)
    dirs = dirs @ (Ry @ Rx).T
    dirs /= np.linalg.norm(dirs, axis=-1, keepdims=True)
    out = np.zeros((h, w, 3), np.float32)
    best = np.full((h, w), -1.0, np.float32)
    n = faces["ft"].shape[0]
    for name, (c, r, u) in G.FACES.items():
        c, r, u = (np.array(v, np.float32) for v in (c, r, u))
        dc = dirs @ c
        sel = (dc > best) & (dc > 0)
        px = (dirs @ r) / np.maximum(dc, 1e-6)
        py = (dirs @ u) / np.maximum(dc, 1e-6)
        ix = np.clip(((px + 1) / 2 * n).astype(int), 0, n - 1)
        iy = np.clip(((1 - (py + 1) / 2) * n).astype(int), 0, n - 1)
        out[sel] = faces[name][iy[sel], ix[sel]]
        best = np.where(sel, dc, best)
    return out


def _paste_sphere(canvas, tile, cx, cy):
    """El disco del planeta, opaco (como la esfera del juego, Transparency 0); el brillo de borde, sumado."""
    s = tile.shape[0]
    x0, y0 = int(cx - s / 2), int(cy - s / 2)
    h, w = canvas.shape[:2]
    xa, ya, xb, yb = max(0, x0), max(0, y0), min(w, x0 + s), min(h, y0 + s)
    if xa >= xb or ya >= yb:
        return
    sub = tile[ya - y0:yb - y0, xa - x0:xb - x0]
    yy, xx = np.mgrid[ya - y0:yb - y0, xa - x0:xb - x0].astype(np.float32)
    r = np.sqrt((xx + 0.5 - s / 2) ** 2 + (yy + 0.5 - s / 2) ** 2) / (s / 2)
    body = np.clip((1 - r) * s / 2, 0, 1)[..., None]
    region = canvas[ya:yb, xa:xb]
    canvas[ya:yb, xa:xb] = region * (1 - body) + sub * body + sub * (1 - body) * (r[..., None] >= 1)


def _ring(canvas, cx, cy, radius, tilt, ring_img, front):
    h, w = canvas.shape[:2]
    n = ring_img.shape[0]
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    dx, dy = (xs - cx) / radius, (ys - cy) / (radius * tilt)
    rr = np.sqrt(dx * dx + dy * dy)
    sel = rr <= 1
    sel &= (dy > 0) if front else (dy <= 0)
    ix = np.clip(((dx + 1) / 2 * n).astype(int), 0, n - 1)
    iy = np.clip(((dy + 1) / 2 * n).astype(int), 0, n - 1)
    rgba = ring_img[iy, ix]
    a = rgba[..., 3:4] * sel[..., None]
    canvas[:] = canvas * (1 - a) + rgba[..., :3] * 0.95 * a


def gen_mock():
    W, H = 1846, 852
    sky = _sky_view(W, H)
    canvas = sky.copy()
    light = (0.85, 0.15, 0.5)
    tefra = np.asarray(Image.open(OUT / "planeta_tefra.jpg"), np.float32) / 255
    vert = np.asarray(Image.open(OUT / "planeta_vertice.jpg"), np.float32) / 255
    valm = np.asarray(Image.open(OUT / "valmar_tierra.jpg"), np.float32) / 255
    nub = np.asarray(Image.open(OUT / "nubes_valmar.png"), np.float32) / 255
    ring = np.asarray(Image.open(OUT / "anillos_vertice.png"), np.float32) / 255
    # Vértice (detrás, con anillos)
    vs = 420
    _ring(canvas, 1110, 250, vs * 1.95 / 2 * 1.02, 0.22, ring, False)
    _paste_sphere(canvas, G.render_sphere(vert, None, vs, light=light, halo=(1.0, 0.85, 0.6), spin=0.3), 1110, 250)
    _ring(canvas, 1110, 250, vs * 1.95 / 2 * 1.02, 0.22, ring, True)
    # Tefra
    _paste_sphere(canvas, G.render_sphere(tefra, None, 270, light=light, halo=(1.0, 0.5, 0.25), spin=1.1), 715, 360)
    # Valmar (grande, abajo a la izquierda)
    _paste_sphere(canvas, G.render_sphere(valm, nub, 760, light=light, halo=(0.45, 0.75, 1.0), spin=2.4), 140, 640)
    # Lunas pequeñas
    moon = np.asarray(Image.open(OUT / "planeta_ocrea.jpg"), np.float32) / 255 * 0.6
    _paste_sphere(canvas, G.render_sphere(moon, None, 90, light=light, spin=0.5), 1310, 285)
    _paste_sphere(canvas, G.render_sphere(moon, None, 54, light=light, spin=2.0), 990, 430)
    # Destello del sol a la derecha
    ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
    rr = np.sqrt((xs - 1790) ** 2 + (ys - 352) ** 2)
    canvas += (np.exp(-rr / 22) * 1.4 + np.exp(-rr / 160) * 0.35)[..., None] * col(255, 236, 200)
    # Asteroides de primer plano (rocas oscuras)
    rng = np.random.default_rng(5)
    rock = np.asarray(Image.open(OUT / "roca_lontana_color.png").convert("RGB").resize((256, 128)), np.float32) / 255 * 0.55
    for _ in range(18):
        s = int(rng.uniform(12, 70))
        x = rng.uniform(0, W)
        y = rng.uniform(H * 0.35, H)
        _paste_sphere(canvas, G.render_sphere(rock, None, s, light=light, halo=(0.12, 0.1, 0.1), spin=rng.uniform(0, 6)), x, y)
    img = Image.fromarray((np.clip(canvas, 0, 1) * 255).astype(np.uint8))
    # Marcadores nuevos (icono + nombre en blanco + distancia + % + barra verde), como UI/SpaceMarkers
    dr = ImageDraw.Draw(img)
    try:
        bold = ImageFont.truetype("DejaVuSans-Bold.ttf", 24)
        reg = ImageFont.truetype("DejaVuSans.ttf", 18)
    except OSError:
        bold = reg = ImageFont.load_default()

    def marker(x, y, name, dist, color, shape):
        r = 13
        if shape == "rombo":
            dr.polygon([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], fill=color, outline=(255, 255, 255))
        elif shape == "aro":
            dr.ellipse([x - r, y - r, x + r, y + r], outline=color, width=4)
        else:
            dr.polygon([(x - r, y - r), (x + r, y - r), (x + r, y + 2), (x, y + r + 2), (x - r, y + 2)], fill=color, outline=(255, 255, 255))
        tx = x + r + 10
        dr.text((tx, y - 22), name, font=bold, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
        dr.text((tx, y + 4), dist, font=reg, fill=(220, 230, 245), stroke_width=2, stroke_fill=(0, 0, 0))
        dr.text((tx, y + 24), "100%", font=reg, fill=(255, 255, 255), stroke_width=2, stroke_fill=(0, 0, 0))
        dr.rectangle([tx, y + 48, tx + 90, y + 53], fill=(30, 40, 50))
        dr.rectangle([tx, y + 48, tx + 90, y + 53], fill=(70, 230, 120))

    marker(330, 405, "Valmar", "2,7 km", (60, 220, 200), "escudo")
    marker(735, 325, "Tefra", "1,5 km", (240, 60, 50), "rombo")
    marker(1060, 210, "Vértice", "1,5 km", (255, 200, 60), "aro")
    marker(1210, 395, "Escudo", "3,4 km", (110, 200, 255), "escudo")
    DOCS.mkdir(parents=True, exist_ok=True)
    img.save(DOCS / "mock-espacio-v122.jpg", quality=90)
    print("  ✓", (DOCS / "mock-espacio-v122.jpg").relative_to(ROOT))
    # Comparación: referencia | ahora (v121) | maqueta v122
    ref = Image.open(DOCS / "referencia-espacio-v121.png").convert("RGB").resize((924, 426))
    now = Image.open(ROOT / "docs" / "bugs" / "espacio-v121-actual.png").convert("RGB").resize((924, 426))
    mock = img.resize((924, 426))
    sheet = Image.new("RGB", (924, 426 * 3 + 60), (8, 10, 20))
    lab = ImageDraw.Draw(sheet)
    for i, (title, im) in enumerate((("Referencia del dueño (arte de IA)", ref), ("Ahora: v121 en el móvil", now), ("Maqueta v122 (texturas nuevas, sin suelo azul; no es captura del juego)", mock))):
        y = i * (426 + 20)
        sheet.paste(im, (0, y + 20))
        lab.text((8, y + 2), title, font=reg, fill=(255, 255, 255))
    sheet.save(DOCS / "comparacion-espacio-v122.jpg", quality=88)
    print("  ✓", (DOCS / "comparacion-espacio-v122.jpg").relative_to(ROOT))


JOBS = {"cielo": gen_sky, "planetas": gen_planets, "valmar": gen_valmar, "anillos": gen_rings}

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    for key, fn in JOBS.items():
        if not args or any(key.startswith(a) or a.startswith(key) for a in args):
            print("·", key)
            fn()
    if "--mock" in sys.argv:
        gen_mock()
