#!/usr/bin/env python3
# Texturas de la Grieta del cielo (Controllers/SkyRift) a partir de la imagen de referencia del dueño
# (scripts/rift/referencia.png: la encargó él para su juego, está autorizado usarla como textura).
#
# Uso (desde la carpeta roblox/):
#   python3 scripts/rift/gen.py
# Hace falta: pip install pillow numpy scipy opencv-python-headless
#
# Escribe en textures/rift/:
#   rift_interior.png  2048x1024 RGBA  la rasgadura con el espacio dentro (galaxia, planeta, nebulosa,
#                                      estrellas y el borde eléctrico); transparente fuera de la silueta
#   rift_rays.png      2048x1024 RGBA  los rayos azul/morado que salen del borde (sacados de la
#                                      referencia sin el cielo de detrás: solo lo que brilla de más)
#   rift_glow.png      2048x1024 RGBA  halo azul/morado difuso con la misma silueta, más grande
#   rift_galaxy.png    512x512   RGBA  la galaxia sola, con borde suave (el juego la hace girar)
#   bolt_1..4.png      512x256   RGBA  rayos ramificados (azul-blanco y morado) para el parpadeo
#   rift_s2/s3/s4/s6/s7.png  RGBA      las otras etapas de la grieta (scripts/rift/etapas.png, las 7
#                                      etapas que encargó el dueño): 2 la primera anomalía (estrella y
#                                      raya violeta), 3 la grieta crece, 4 la gran fractura, 6 la grieta
#                                      colosal, 7 el evento final (la 5, el portal, es rift_interior)
#   rift_s6_galaxy / rift_s7_galaxy    la galaxia de esas etapas, sola (gira)
#   preview.png, preview-1..7.png      vistas previas sobre un cielo azul (todo junto y cada etapa)
#
# Y src/shared/SkyRiftArt.luau (generado): la silueta para dibujarla sin texturas y el marco de cada
# etapa (proporción, de dónde salen los rayos, dónde está la galaxia).
#
# Las cuatro capas grandes (interior, rayos, halo) comparten el mismo marco (REGION de la referencia):
# en el juego van una encima de otra en el mismo plano. GALAXY dice dónde va la galaxia (en fracciones
# del marco); los mismos números están en shared/SkyRift.luau (SkyRift.Texture).

import os
import sys

import cv2
import numpy as np
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
SRC = os.path.join(HERE, "referencia.png")
STAGES_SRC = os.path.join(HERE, "etapas.png")
OUT = os.path.join(ROOT, "textures", "rift")

# Marco de la grieta en la referencia (x0, y0, x1, y1), proporción 2:1
REGION = (290, 22, 1530, 642)
OUT_W, OUT_H = 2048, 1024
# Galaxia: centro (en píxeles de la referencia) y radio
GALAXY_C = (985, 326)
GALAXY_R = 105
# Planeta (para que la máscara lo incluya entero)
PLANET_C = (826, 273)
PLANET_R = 64

# Lo que NO es la grieta en la referencia (rótulos, recuadros, personaje, farola): no entra en los rayos
EXCLUDE = [
    (0, 0, 600, 175),  # título y texto de arriba a la izquierda
    (1300, 25, 1846, 190),  # recuadro «INTERIOR DE LA GRIETA»
    (1400, 318, 1846, 490),  # recuadro «PARTÍCULAS Y ROCAS»
    (1360, 525, 1846, 700),  # recuadro «NUBES Y LUZ»
    (0, 240, 305, 530),  # recuadro «DETALLE DE LA GRIETA»
    (735, 462, 1030, 852),  # personaje y farola
]
# Líneas y puntos de los rótulos que cruzan la grieta (se borran y se rellenan con lo de alrededor)
CALLOUT_LINES = [
    [(305, 327), (356, 327), (396, 289), (525, 289), (598, 279)],
    [(604, 276), (619, 283), (712, 316)],
    [(1026, 322), (1074, 280), (1249, 118), (1305, 108)],
    [(1256, 372), (1361, 405), (1410, 405)],
    [(1097, 500), (1101, 505), (1270, 610), (1362, 610)],
]
CALLOUT_DOTS = [(305, 327, 9), (604, 276, 7), (619, 283, 7), (1026, 322, 9), (1256, 372, 9), (1097, 500, 7)]


def load():
    im = cv2.imread(SRC, cv2.IMREAD_COLOR)
    if im is None:
        sys.exit("No encuentro " + SRC)
    return im


def clean_callouts(im):
    """Borra las líneas y puntos de los rótulos (inpainting con lo de alrededor)."""
    mask = np.zeros(im.shape[:2], np.uint8)
    for line in CALLOUT_LINES:
        pts = np.array(line, np.int32)
        cv2.polylines(mask, [pts], False, 255, 6, cv2.LINE_AA)
    for x, y, r in CALLOUT_DOTS:
        cv2.circle(mask, (x, y), r + 2, 255, -1, cv2.LINE_AA)
    mask = cv2.dilate(mask, np.ones((3, 3), np.uint8))
    return cv2.inpaint(im, mask, 5, cv2.INPAINT_TELEA)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def silhouette(im, grow=10):
    """Máscara (0..1) de la rasgadura: la zona oscura azul-violeta del centro (sin el cielo), con su
    borde eléctrico (grow píxeles más)."""
    f = im.astype(np.float32) / 255
    dark = (cv2.GaussianBlur(f[..., 1], (0, 0), 1.2) < 0.28).astype(np.uint8)
    # Solo cerca de la grieta
    box = np.zeros_like(dark)
    box[140:530, 320:1450] = 1
    dark &= box
    dark = cv2.morphologyEx(dark, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11)))
    cv2.circle(dark, PLANET_C, PLANET_R, 1, -1)
    cv2.circle(dark, GALAXY_C, 60, 1, -1)
    # Fuera los pelos finos (el borde queda dentado, no deshilachado)
    dark = cv2.morphologyEx(dark, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7)))
    _, lab = cv2.connectedComponents(dark, connectivity=8)
    keep = ndimage.binary_fill_holes(lab == lab[GALAXY_C[1], GALAXY_C[0]]).astype(np.uint8)
    if grow > 0:
        keep = cv2.dilate(keep, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * grow + 1, 2 * grow + 1)))
    soft = cv2.GaussianBlur(keep.astype(np.float32), (0, 0), 1.3)
    return np.clip((soft - 0.2) / 0.6, 0, 1)


def crop(a):
    x0, y0, x1, y1 = REGION
    return a[y0:y1, x0:x1]


def big(a):
    """Del marco de la referencia (1240x620) al tamaño de salida (2048x1024)."""
    return cv2.resize(a, (OUT_W, OUT_H), interpolation=cv2.INTER_CUBIC)


def rgba(bgr01, alpha01):
    out = np.dstack([np.clip(bgr01, 0, 1), np.clip(alpha01, 0, 1)])
    return (out * 255 + 0.5).astype(np.uint8)


def write(name, img):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    cv2.imwrite(path, img)
    print("  " + os.path.relpath(path, ROOT), img.shape[1], "x", img.shape[0])
    return path


def saturate(bgr, amount):
    grey = bgr.mean(axis=2, keepdims=True)
    return np.clip(grey + (bgr - grey) * amount, 0, 1)


def frame_uv(x, y):
    """De píxeles de la referencia a fracciones del marco (0..1)."""
    x0, y0, x1, y1 = REGION
    return (x - x0) / (x1 - x0), (y - y0) / (y1 - y0)


# ---------------------------------------------------------------------------
# Capas sacadas de la referencia
# ---------------------------------------------------------------------------
def interior(f, mask):
    """La rasgadura con el espacio dentro; fuera, transparente."""
    col = saturate(f, 1.12)
    # Un poco más de contraste en lo oscuro: el espacio, más profundo
    col = np.clip((col - 0.02) * 1.06, 0, 1)
    return rgba(big(crop(col)), big(crop(mask)))


def electric(f):
    """Cuánto es rayo/energía cada píxel (0..1): cian brillante, morado brillante o blanco fino."""
    B, G, R = f[..., 0], f[..., 1], f[..., 2]
    ss = smoothstep
    cyan = ss(0.78, 0.97, B) * ss(0.55, 0.85, G) * ss(0.2, 0.45, B - R)
    purple = ss(0.75, 0.95, B) * ss(0.45, 0.7, R) * ss(0.06, 0.2, R - G)
    mn = f.min(axis=2)
    op = cv2.morphologyEx(mn, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7)))
    white = ss(0.8, 0.95, mn) * ss(0.05, 0.15, mn - op)
    return np.maximum(np.maximum(cyan, purple), white)


def allowed_zone(shape):
    """Dónde puede haber rayos: alrededor de la grieta, sin rótulos ni personaje, con borde suave."""
    h, w = shape
    zone = np.zeros((h, w), np.float32)
    cx, cy = 905, 330
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = ((xx - cx) / 640) ** 2 + ((yy - cy) / 330) ** 2
    zone = np.clip(1.25 - d, 0, 1)
    for x0, y0, x1, y1 in EXCLUDE:
        zone[y0:y1, x0:x1] = 0
    zone = cv2.GaussianBlur(zone, (0, 0), 6)
    # Y a 0 en el borde del marco
    x0, y0, x1, y1 = REGION
    edge = np.zeros_like(zone)
    edge[y0 + 12 : y1 - 12, x0 + 12 : x1 - 12] = 1
    return zone * cv2.GaussianBlur(edge, (0, 0), 8)


def rays(f, inner):
    """Los rayos del borde (sin el cielo de detrás): color del rayo y alfa = cuánto brilla de más."""
    e = electric(f) * allowed_zone(f.shape[:2])
    e *= 1 - inner  # dentro ya está la textura del interior
    # Color: el del rayo, más vivo y llevado a brillo máximo (encima del cielo se ve como luz)
    peak = np.maximum(f.max(axis=2, keepdims=True), 1e-3)
    col = saturate(f / peak, 1.25)
    col = np.clip(col * 0.85 + 0.15, 0, 1)
    a = np.clip(e * 1.15, 0, 1) ** 0.85
    return rgba(big(crop(col)), big(crop(a)))


def glow(f, mask):
    """Halo azul/morado: la silueta más grande y borrosa (tiñe el cielo y las nubes de alrededor de
    azul profundo y morado) + la luz que sueltan los rayos."""
    near = cv2.GaussianBlur(cv2.dilate(mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (31, 31))), (0, 0), 18)
    far = cv2.GaussianBlur(cv2.dilate(mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (91, 91))), (0, 0), 70)
    e = cv2.GaussianBlur(electric(f) * allowed_zone(f.shape[:2]), (0, 0), 12)
    h, w = mask.shape
    yy = np.mgrid[0:h, 0:w][0].astype(np.float32)
    # Arriba más azul eléctrico, abajo más morado
    k = np.clip((yy - 230) / 220, 0, 1)[..., None]
    deep = np.array([0.42, 0.13, 0.05]) * (1 - k) + np.array([0.45, 0.07, 0.3]) * k  # BGR
    bright = np.array([1.0, 0.78, 0.4]) * (1 - k) + np.array([1.0, 0.5, 0.78]) * k
    light = np.clip(near * 0.55 + e * 1.5, 0, 1)[..., None]
    col = deep * (1 - light) + bright * light
    a = np.clip(far * 1.05 + near * 0.3 + e * 1.2, 0, 0.9)
    return rgba(big(crop(col)), big(crop(a)))


def galaxy(f, center=GALAXY_C, r=GALAXY_R):
    """Una galaxia sola (512x512) con borde suave redondo: el juego la hace girar despacio."""
    x, y = center
    patch = f[y - r : y + r, x - r : x + r]
    patch = cv2.resize(saturate(patch, 1.1), (512, 512), interpolation=cv2.INTER_CUBIC)
    yy, xx = np.mgrid[0:512, 0:512].astype(np.float32)
    d = np.sqrt((xx - 255.5) ** 2 + (yy - 255.5) ** 2) / 256
    a = smoothstep(1.0, 0.55, d)
    return rgba(patch, a)


# ---------------------------------------------------------------------------
# Rayos ramificados (hechos por código)
# ---------------------------------------------------------------------------
def bolt_path(rng, a, b, rough, depth):
    """Desplazamiento del punto medio: una línea quebrada de a a b."""
    pts = [np.array(a, np.float32), np.array(b, np.float32)]
    for _ in range(depth):
        out = [pts[0]]
        for p, q in zip(pts[:-1], pts[1:]):
            d = q - p
            n = np.array([-d[1], d[0]])
            m = (p + q) / 2 + n * rng.uniform(-rough, rough)
            out += [m, q]
        pts = out
        rough *= 0.62
    return pts


def bolt(seed, core_bgr, glow_bgr, w=1024, h=512):
    """Un rayo ramificado de izquierda a derecha, como los de la referencia: núcleo blanco muy fino,
    borde fino del color, halo ancho y difuso, y ramas que se abren y se afinan (fractal).
    Se dibuja al doble de tamaño y se reduce (bordes suaves)."""
    rng = np.random.default_rng(seed)
    S = 2
    W, H = w * S, h * S
    core = np.zeros((H, W), np.float32)
    edge = np.zeros((H, W), np.float32)
    halo = np.zeros((H, W), np.float32)

    def draw(points, width, energy):
        pts = (np.array(points) * S).astype(np.int32).reshape(-1, 1, 2)
        cv2.polylines(halo, [pts], False, energy, max(2, int(width * 7 * S)), cv2.LINE_AA)
        cv2.polylines(edge, [pts], False, energy, max(1, int(width * 2.2 * S)), cv2.LINE_AA)
        cv2.polylines(core, [pts], False, energy, max(1, int(width * 0.9 * S)), cv2.LINE_AA)

    def grow(a, b, width, energy, depth):
        path = bolt_path(rng, a, b, 0.42, 7 if depth == 0 else 6)
        draw(path, width, energy)
        if depth >= 3 or width < 0.35:
            return
        n = int(rng.integers(3, 7)) if depth == 0 else int(rng.integers(1, 4))
        d = np.array(b, np.float32) - np.array(a, np.float32)
        base = np.arctan2(d[1], d[0])
        length = np.hypot(d[0], d[1])
        for _ in range(n):
            i = int(rng.integers(len(path) // 8, len(path) * 7 // 8))
            start = path[i]
            ang = base + rng.choice([-1, 1]) * rng.uniform(0.35, 1.05)
            l = length * rng.uniform(0.18, 0.45) * (1 - i / len(path) * 0.5)
            end = np.clip(start + np.array([np.cos(ang), np.sin(ang)]) * l, 4, [w - 4, h - 4])
            grow(start, end, width * rng.uniform(0.45, 0.65), energy * rng.uniform(0.55, 0.8), depth + 1)

    grow((8, h / 2 + rng.uniform(-40, 40)), (w - 8, h / 2 + rng.uniform(-110, 110)), 2.2, 1.0, 0)
    core = cv2.resize(cv2.GaussianBlur(core, (0, 0), 0.6), (w, h), interpolation=cv2.INTER_AREA)
    edge = cv2.resize(cv2.GaussianBlur(edge, (0, 0), 1.6), (w, h), interpolation=cv2.INTER_AREA)
    halo = cv2.resize(cv2.GaussianBlur(halo, (0, 0), 9 * S), (w, h), interpolation=cv2.INTER_AREA)
    core = np.clip(core * 1.5, 0, 1)[..., None]
    edge = np.clip(edge * 1.2, 0, 1)[..., None]
    halo = np.clip(halo * 1.4, 0, 1)[..., None]
    a = np.clip(core + edge * 0.85 + halo * 0.5, 0, 1)
    col = np.ones(3) * core + np.array(core_bgr) * edge * (1 - core) + np.array(glow_bgr) * halo * 0.5 * (1 - edge)
    col = col / np.maximum(a, 1e-3)
    return rgba(np.clip(col, 0, 1), a[..., 0])


# ---------------------------------------------------------------------------
# Las otras etapas (scripts/rift/etapas.png: las 7 etapas que encargó el dueño)
# ---------------------------------------------------------------------------
# Coordenadas en píxeles de etapas.png. crop: el trozo de cielo; textbox: el rótulo del panel (se
# borra); kind: cómo se recorta (additive = solo lo que brilla, como la estrella; patch = un parche de
# cielo con borde suave alrededor de la fractura; sky = casi todo el cielo del panel); ellipse: centro,
# semiejes y ángulo del parche; spine: por dónde salen los rayos que parpadean; galaxy: centro y radio.
STAGE_DEFS = {
    2: dict(crop=(470, 40, 700, 300), kind="additive", textbox=(405, 12, 643, 92),
            ellipse=((591, 175), (135, 120), -40), star=(591, 175), spine=[(505, 265), (591, 175), (673, 70)]),
    3: dict(crop=(775, 40, 1150, 380), kind="patch", textbox=(770, 12, 1048, 108),
            ellipse=((930, 192), (215, 95), -41), star=(948, 200), spine=[(790, 305), (870, 250), (948, 200), (1010, 140), (1060, 70)]),
    4: dict(crop=(1160, 80, 1534, 360), kind="patch", textbox=(1176, 12, 1480, 108), exclude=[(1400, 255, 1536, 400)],
            ellipse=((1340, 230), (235, 130), -30), spine=[(1196, 300), (1260, 270), (1321, 235), (1400, 190), (1486, 140), (1530, 105)]),
    6: dict(crop=(514, 516, 1023, 848), kind="sky", textbox=(534, 506, 839, 571),
            galaxy=((829, 758), 70), ring=((779, 726), (205, 150))),
    7: dict(crop=(1026, 486, 1536, 856), kind="sky", textbox=(1046, 506, 1351, 561),
            galaxy=((1331, 726), 95), ring=((1300, 720), (230, 175))),
}


def load_stages():
    im = cv2.imread(STAGES_SRC, cv2.IMREAD_COLOR)
    if im is None:
        sys.exit("No encuentro " + STAGES_SRC)
    return im


def fix_textbox(im, box):
    """Borra el rótulo de un panel: inpainting de las letras y se quita el oscurecido del recuadro."""
    x0, y0, x1, y1 = box
    f = im.astype(np.float32) / 255
    region = f[y0:y1, x0:x1]
    letters = (region.max(axis=2) > 0.55).astype(np.uint8)
    letters = cv2.dilate(letters, np.ones((5, 5), np.uint8))
    mask = np.zeros(im.shape[:2], np.uint8)
    mask[y0:y1, x0:x1] = letters * 255
    out = cv2.inpaint(im, mask, 4, cv2.INPAINT_TELEA).astype(np.float32) / 255
    # El recuadro oscurece lo de detrás: se compara con la franja de justo debajo
    inside = out[y1 - 10 : y1 - 2, x0:x1].mean()
    below = out[y1 + 2 : y1 + 10, x0:x1].mean()
    k = float(np.clip(below / max(inside, 1e-3), 1.0, 2.2))
    gain = np.zeros(im.shape[:2], np.float32)
    gain[y0:y1, x0:x1] = 1
    gain = cv2.GaussianBlur(gain, (0, 0), 3)
    out = out * (1 + (k - 1) * gain[..., None])
    return (np.clip(out, 0, 1) * 255).astype(np.uint8)


def ellipse_mask(shape, center, axes, angle, inner=0.55):
    h, w = shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    a = np.deg2rad(angle)
    dx, dy = xx - center[0], yy - center[1]
    u = (dx * np.cos(a) + dy * np.sin(a)) / axes[0]
    v = (-dx * np.sin(a) + dy * np.cos(a)) / axes[1]
    d = np.sqrt(u * u + v * v)
    return smoothstep(1.0, inner, d)


def excess(f, sigma=10):
    v = f.max(axis=2)
    return np.clip(v - cv2.GaussianBlur(v, (0, 0), sigma), 0, 1)


def stage_size(cw, ch, longest=1024):
    k = longest / max(cw, ch)
    return int(round(cw * k / 4) * 4), int(round(ch * k / 4) * 4)


def stage_texture(f, d):
    x0, y0, x1, y1 = d["crop"]
    h, w = f.shape[:2]
    if d["kind"] == "additive":
        e = excess(f, 8)
        vig = ellipse_mask((h, w), *d["ellipse"], inner=0.35)
        glowing = cv2.GaussianBlur(e, (0, 0), 5)
        a = np.clip(smoothstep(0.02, 0.16, e) * 1.2 + glowing * 3.0, 0, 1) * vig
        peak = np.maximum(f.max(axis=2, keepdims=True), 1e-3)
        col = saturate(f / peak, 1.35)
    elif d["kind"] == "patch":
        vig = ellipse_mask((h, w), *d["ellipse"], inner=0.5)
        wide = ellipse_mask((h, w), d["ellipse"][0], (d["ellipse"][1][0] * 1.35, d["ellipse"][1][1] * 1.7), d["ellipse"][2], inner=0.6)
        e = electric(f)
        a = np.clip(np.maximum(vig * 0.95, e * wide), 0, 1)
        col = saturate(f, 1.12)
    else:
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        cw, ch = x1 - x0, y1 - y0
        fx = np.minimum((xx - x0) / (cw * 0.16), (x1 - xx) / (cw * 0.16))
        fy = np.minimum((yy - y0) / (ch * 0.14), (y1 - yy) / (ch * 0.26))
        a = smoothstep(0, 1, np.clip(np.minimum(fx, fy), 0, 1)) * 0.97
        col = saturate(f, 1.08)
    for ex0, ey0, ex1, ey1 in d.get("exclude", []):
        cut = np.ones((h, w), np.float32)
        cut[ey0:ey1, ex0:ex1] = 0
        a = a * cv2.GaussianBlur(cut, (0, 0), 10)
    col, a = col[y0:y1, x0:x1], a[y0:y1, x0:x1]
    # Nunca un corte recto en el borde del marco
    ch_, cw_ = a.shape
    yy, xx = np.mgrid[0:ch_, 0:cw_].astype(np.float32)
    edge = np.minimum(np.minimum(xx, cw_ - 1 - xx) / (cw_ * 0.05), np.minimum(yy, ch_ - 1 - yy) / (ch_ * 0.05))
    a = a * smoothstep(0, 1, np.clip(edge, 0, 1))
    size = stage_size(x1 - x0, y1 - y0)
    return rgba(cv2.resize(col, size, interpolation=cv2.INTER_CUBIC), cv2.resize(a, size, interpolation=cv2.INTER_CUBIC))


def stage_uv(d, x, y):
    x0, y0, x1, y1 = d["crop"]
    return (x - x0) / (x1 - x0), (y - y0) / (y1 - y0)


def stage_spawn(d):
    """De dónde salen los rayos que parpadean (fracciones del marco de la etapa)."""
    pts = []
    if "spine" in d:
        sp = d["spine"]
        for p, q in zip(sp[:-1], sp[1:]):
            for k in range(4):
                t = k / 4
                pts.append(stage_uv(d, p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
        pts.append(stage_uv(d, *sp[-1]))
    else:
        (cx, cy), (rx, ry) = d["ring"]
        for k in range(24):
            a = k / 24 * 2 * np.pi
            pts.append(stage_uv(d, cx + np.cos(a) * rx, cy + np.sin(a) * ry))
    return pts


def build_stages():
    """Las texturas de las etapas 2, 3, 4, 6 y 7 (y sus galaxias)."""
    im = load_stages()
    for d in STAGE_DEFS.values():
        im = fix_textbox(im, d["textbox"])
    f = im.astype(np.float32) / 255
    out = {}
    for n, d in STAGE_DEFS.items():
        tex = stage_texture(f, d)
        write("rift_s%d.png" % n, tex)
        info = {"Texture": "rift_s%d" % n, "Aspect": (d["crop"][2] - d["crop"][0]) / (d["crop"][3] - d["crop"][1]), "Spawn": stage_spawn(d), "Tex": tex}
        if "galaxy" in d:
            (gx, gy), gr = d["galaxy"]
            g = galaxy(f, (gx, gy), gr)
            write("rift_s%d_galaxy.png" % n, g)
            gu, gv = stage_uv(d, gx, gy)
            info["Galaxy"] = (gu, gv, gr / (d["crop"][2] - d["crop"][0]))
            info["GalaxyTexture"] = "rift_s%d_galaxy" % n
            info["GalaxyImg"] = g
        if "star" in d:
            info["Star"] = stage_uv(d, *d["star"])
        out[n] = info
    return out


# ---------------------------------------------------------------------------
# src/shared/SkyRiftArt.luau (generado): silueta y marcos de cada etapa
# ---------------------------------------------------------------------------
def art_luau(mask_core, stages):
    m = crop((mask_core > 0.5).astype(np.uint8))
    h, w = m.shape
    contours, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    c = max(contours, key=cv2.contourArea)
    c = cv2.approxPolyDP(c, 2.2, True).reshape(-1, 2)
    # Como mucho ~90 puntos (sin textura, el borde brillante se dibuja con un tramo por cada uno)
    while len(c) > 90:
        c = c[::2]
    cols = []
    n = 56
    xs = np.where(m.any(axis=0))[0]
    xa, xb = xs.min(), xs.max()
    for i in range(n):
        u0 = xa + (xb - xa) * i / n
        u1 = xa + (xb - xa) * (i + 1) / n
        band = m[:, int(u0) : max(int(u1), int(u0) + 1)]
        rows = np.where(band.any(axis=1))[0]
        if len(rows) == 0:
            continue
        cols.append(((u0 + u1) / 2 / w, (u1 - u0) / w, rows.min() / h, rows.max() / h))
    gu, gv = frame_uv(*GALAXY_C)
    pu, pv = frame_uv(*PLANET_C)
    x0, y0, x1, y1 = REGION
    L = [
        "-- SkyRiftArt: GENERADO por scripts/rift/gen.py (no editar a mano).",
        "-- Lo que sale de las imágenes del dueño (scripts/rift/referencia.png y etapas.png) para",
        "-- Controllers/SkyRift. Todo en fracciones del marco de cada textura (0..1; U a la derecha, V hacia",
        "-- abajo).",
        "--   * Rim / Columns: la silueta de la rasgadura (etapa 5, el portal). Sin texturas subidas",
        "--     (shared/RiftTextureIds vacío) se dibuja así: relleno oscuro por columnas y borde eléctrico.",
        "--   * Stages: el marco de cada etapa con textura: su proporción (ancho/alto), de dónde salen los",
        "--     rayos que parpadean (Spawn; sin él, del borde Rim) y dónde está su galaxia (U, V, radio en",
        "--     fracción del ancho) y su destello violeta (Star).",
        "return {",
        "\t-- Contorno cerrado de la rasgadura (puntos en orden)",
        "\tRim = {",
    ]
    for x, y in c:
        L.append("\t\t{ %.4f, %.4f }," % (x / w, y / h))
    L.append("\t},")
    L.append("\t-- Columnas de relleno: { U del centro, ancho, V de arriba, V de abajo }")
    L.append("\tColumns = {")
    for u, cw, top, bot in cols:
        L.append("\t\t{ %.4f, %.4f, %.4f, %.4f }," % (u, cw, top, bot))
    L.append("\t},")
    L.append("\tGalaxy = { %.4f, %.4f, %.4f }," % (gu, gv, GALAXY_R / (x1 - x0)))
    L.append("\tPlanet = { %.4f, %.4f, %.4f }," % (pu, pv, PLANET_R / (x1 - x0)))
    L.append("\tStages = {")
    for n in sorted(list(stages.keys()) + [5]):
        if n == 5:
            L.append('\t\t[5] = { Texture = "rift_interior", Aspect = 2, Galaxy = { %.4f, %.4f, %.4f }, GalaxyTexture = "rift_galaxy" },' % (gu, gv, GALAXY_R / (x1 - x0)))
            continue
        st = stages[n]
        parts = ['Texture = "%s"' % st["Texture"], "Aspect = %.4f" % st["Aspect"]]
        if "Galaxy" in st:
            parts.append("Galaxy = { %.4f, %.4f, %.4f }" % st["Galaxy"])
            parts.append('GalaxyTexture = "%s"' % st["GalaxyTexture"])
        if "Star" in st:
            parts.append("Star = { %.4f, %.4f }" % st["Star"])
        spawn = ", ".join("{ %.3f, %.3f }" % p for p in st["Spawn"])
        parts.append("Spawn = { %s }" % spawn)
        L.append("\t\t[%d] = { %s }," % (n, ", ".join(parts)))
    L.append("\t},")
    L.append("}")
    path = os.path.join(ROOT, "src", "shared", "SkyRiftArt.luau")
    with open(path, "w") as fh:
        fh.write("\n".join(L) + "\n")
    print("  " + os.path.relpath(path, ROOT), len(c), "puntos de borde,", len(cols), "columnas,", len(stages) + 1, "etapas")


# ---------------------------------------------------------------------------
# Vista previa: todo junto sobre un cielo azul con nubes (para compararla con la referencia)
# ---------------------------------------------------------------------------
def sky_background(w, h, seed=3):
    rng = np.random.default_rng(seed)
    yy = np.linspace(0, 1, h)[:, None, None]
    top = np.array([0.55, 0.28, 0.08])  # BGR: azul profundo arriba
    bottom = np.array([0.95, 0.72, 0.45])  # azul claro abajo
    sky = top * (1 - yy) + bottom * yy
    sky = np.broadcast_to(sky, (h, w, 3)).copy()
    noise = np.zeros((h, w), np.float32)
    for octave in range(5):
        s = 2 ** (octave + 2)
        n = rng.random((s, s * 2)).astype(np.float32)
        noise += cv2.resize(n, (w, h), interpolation=cv2.INTER_CUBIC) / (octave + 1)
    noise = (noise - noise.min()) / (noise.max() - noise.min())
    clouds = smoothstep(0.5, 0.85, noise)[..., None]
    cloud_col = np.array([0.98, 0.93, 0.9])
    return sky * (1 - clouds * 0.85) + cloud_col * clouds * 0.85


def over(dst, src_rgba, x, y):
    """Pega src (RGBA 0..255) encima de dst (BGR 0..1) en (x, y), con alfa."""
    h, w = src_rgba.shape[:2]
    H, W = dst.shape[:2]
    xa, ya, xb, yb = max(x, 0), max(y, 0), min(x + w, W), min(y + h, H)
    if xa >= xb or ya >= yb:
        return
    s = src_rgba[ya - y : yb - y, xa - x : xb - x].astype(np.float32) / 255
    a = s[..., 3:4]
    dst[ya:yb, xa:xb] = dst[ya:yb, xa:xb] * (1 - a) + s[..., :3] * a


def rotate(img, angle, scale=1.0):
    h, w = img.shape[:2]
    M = cv2.getRotationMatrix2D((w / 2, h / 2), angle, scale)
    return cv2.warpAffine(img, M, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))


def rock_sprite(rng, size):
    """Una roca 3D (512 px → size): casco convexo de una bola abollada, caras con luz (arriba, cálida y
    tenue), sombra profunda y un borde azul eléctrico que brilla del lado de la grieta (como en la
    referencia). Devuelve RGBA."""
    from scipy.spatial import ConvexHull

    n = 38
    v = rng.normal(size=(n, 3))
    v /= np.linalg.norm(v, axis=1, keepdims=True)
    v *= rng.uniform(0.55, 1.0, size=(n, 1)) * np.array([1.0, rng.uniform(0.6, 0.9), rng.uniform(0.7, 1.0)])
    # Girada al azar
    q = rng.normal(size=(3, 3))
    R, _ = np.linalg.qr(q)
    v = v @ R.T
    hull = ConvexHull(v)
    S = 512
    img = np.zeros((S, S, 3), np.float32)
    alpha = np.zeros((S, S), np.float32)
    light = np.array([-0.4, -0.7, 0.6])
    light /= np.linalg.norm(light)
    rim_dir = np.array([0.2, -0.9, 0.0])  # la grieta, arriba
    faces = []
    for simplex in hull.simplices:
        p = v[simplex]
        nrm = np.cross(p[1] - p[0], p[2] - p[0])
        nrm /= np.linalg.norm(nrm) + 1e-9
        if np.dot(nrm, p.mean(0)) < 0:
            nrm = -nrm
        if nrm[2] <= 0:
            continue  # de espaldas
        faces.append((p[:, 2].mean(), p, nrm))
    faces.sort(key=lambda t: t[0])
    for _, p, nrm in faces:
        pts = ((p[:, :2] * 0.45 + 0.5) * S).astype(np.int32)
        diff = max(0.0, float(np.dot(nrm, light)))
        fres = (1 - nrm[2]) ** 2.2
        rim = max(0.0, float(np.dot(nrm, rim_dir)) + 0.15) * fres ** 0.8
        base = np.array([0.2, 0.15, 0.16]) * (0.3 + 1.0 * diff)  # BGR: basalto oscuro
        col = base + np.array([1.0, 0.75, 0.35]) * rim * 2.4 + np.array([0.8, 0.3, 0.6]) * fres * 0.3
        cv2.fillPoly(img, [pts], tuple(float(c) for c in np.clip(col, 0, 1)), cv2.LINE_AA)
        cv2.fillPoly(alpha, [pts], 1.0, cv2.LINE_AA)
        # Aristas un poco más claras (se ven las caras)
        cv2.polylines(img, [pts], True, tuple(float(c) for c in np.clip(col * 1.25 + 0.02, 0, 1)), 1, cv2.LINE_AA)
    # Grietas/textura de roca
    noise = cv2.GaussianBlur(rng.random((S, S)).astype(np.float32), (0, 0), 2)
    img *= (0.8 + 0.4 * noise)[..., None]
    # Borde brillante azul (por fuera, difuso) del lado de la grieta
    edge = alpha - cv2.erode(alpha, np.ones((9, 9), np.uint8))
    yy = np.linspace(1.3, 0.45, S)[:, None]
    glow = cv2.GaussianBlur(edge * yy, (0, 0), 6) * 4.0 + cv2.GaussianBlur(edge * yy, (0, 0), 16) * 3.0
    halo_a = np.clip(glow, 0, 1)
    # La línea del borde, encendida (cian casi blanco arriba)
    line = cv2.GaussianBlur(edge, (0, 0), 1.2) * yy
    img = img + np.array([1.0, 0.92, 0.7]) * np.clip(line * 1.6, 0, 1)[..., None]
    out_a = np.clip(alpha + halo_a * 0.85, 0, 1)
    out = img * alpha[..., None] + np.array([1.0, 0.7, 0.35]) * halo_a[..., None] * (1 - alpha[..., None]) * 1.3
    out = out / np.maximum(out_a[..., None], 1e-3)
    small = cv2.resize(rgba(np.clip(out, 0, 1), out_a), (size, size), interpolation=cv2.INTER_AREA)
    return small


def draw_rocks(dst, rng, n, area, rmin, rmax):
    x0, y0, x1, y1 = area
    for _ in range(n):
        r = int(rng.uniform(rmin, rmax) * 2.6) + 4
        sp = rock_sprite(rng, r)
        over(dst, sp, int(rng.uniform(x0, x1)) - r // 2, int(rng.uniform(y0, y1)) - r // 2)


def add(dst, src_rgba, x, y, gain=1.0):
    """Suma src (luz) encima de dst: como un rayo con LightEmission o con el brillo del lienzo > 1."""
    h, w = src_rgba.shape[:2]
    H, W = dst.shape[:2]
    xa, ya, xb, yb = max(x, 0), max(y, 0), min(x + w, W), min(y + h, H)
    if xa >= xb or ya >= yb:
        return
    s = src_rgba[ya - y : yb - y, xa - x : xb - x].astype(np.float32) / 255
    a = s[..., 3:4]
    # Núcleo (casi opaco) encima; el halo, sumado
    dst[ya:yb, xa:xb] = dst[ya:yb, xa:xb] * (1 - a * a) + s[..., :3] * a * gain


def draw_bolts(dst, bolts, spots, scale=0.6):
    for i, (x, y, ang) in enumerate(spots):
        b = bolts[i % len(bolts)]
        b = rotate(np.pad(b, ((256, 256), (0, 0), (0, 0))), ang, scale * 0.5)
        add(dst, b, int(x - b.shape[1] // 2), int(y - b.shape[0] // 2))


def bloom(dst, threshold=0.82, sigma=6, strength=0.35):
    """El Bloom del juego: lo que pasa del umbral se derrama en un halo."""
    lum = dst.max(axis=2)
    bright = dst * np.clip((lum - threshold) / (1 - threshold), 0, 1)[..., None]
    halo = cv2.GaussianBlur(bright, (0, 0), sigma) + cv2.GaussianBlur(bright, (0, 0), sigma * 3) * 0.6
    return np.clip(dst + halo * strength, 0, 1)


# Ambiente de cada etapa en la vista previa (lo que hace DayLight.pushLayer con SkyMoods): BGR
AMBIENT = {
    1: ((1, 1, 1), (0, 0, 0)),
    2: ((0.97, 0.95, 0.95), (0.01, 0, 0.01)),
    3: ((0.9, 0.8, 0.78), (0.03, 0, 0.02)),
    4: ((0.85, 0.7, 0.7), (0.05, 0, 0.04)),
    5: ((0.92, 0.78, 0.74), (0.04, 0.0, 0.02)),
    6: ((0.85, 0.68, 0.68), (0.06, 0, 0.05)),
    7: ((0.8, 0.5, 0.72), (0.1, 0.0, 0.1)),
}


def tinted_sky(W, H, stage):
    mul, add = AMBIENT[stage]
    return sky_background(W, H) * np.array(mul) + np.array(add)


def preview(layers, bolts):
    """Vista previa de la etapa 5 (el portal, la referencia principal) con todas sus capas."""
    W, H = 1846, 852
    dst = tinted_sky(W, H, 5)
    x0, y0, x1, y1 = REGION
    fw, fh = x1 - x0, y1 - y0
    small = {k: cv2.resize(v, (fw, fh), interpolation=cv2.INTER_AREA) for k, v in layers.items() if k != "galaxy"}
    over(dst, small["glow"], x0, y0)
    over(dst, small["interior"], x0, y0)
    g = rotate(layers["galaxy"], 25)
    gs = GALAXY_R * 2
    over(dst, cv2.resize(g, (gs, gs), interpolation=cv2.INTER_AREA), GALAXY_C[0] - GALAXY_R, GALAXY_C[1] - GALAXY_R)
    over(dst, small["rays"], x0, y0)
    draw_bolts(dst, bolts, [(470, 300, 200), (1380, 300, -20), (560, 470, 140), (1200, 180, -50), (760, 190, -110), (1090, 470, 80)])
    draw_rocks(dst, np.random.default_rng(7), 26, (380, 110, 1450, 560), 5, 26)
    dst = bloom(dst)
    write("preview.png", (np.clip(dst, 0, 1) * 255).astype(np.uint8))
    return dst


def stage_previews(layers, stages, bolts):
    """preview-1..7.png: cada etapa sobre el cielo (1024x683, como un panel de etapas.png apaisado)."""
    W, H = 1024, 683
    # Ancho de la textura de cada etapa en la vista previa (fracción de la pantalla): como en el juego
    # (shared/SkyRift.Stages: Width a Distance, con la cámara de 70°)
    frac = {2: 0.3, 3: 0.75, 4: 0.95, 5: 0.92, 6: 1.25, 7: 1.7}
    rng = np.random.default_rng(5)
    for n in range(1, 8):
        dst = tinted_sky(W, H, n)
        cx, cy = W * 0.5, H * 0.42
        if n == 5:
            tw = int(W * frac[5])
            th = tw // 2
            x, y = int(cx - tw / 2), int(cy - th / 2)
            for key in ("glow", "interior"):
                over(dst, cv2.resize(layers[key], (tw, th), interpolation=cv2.INTER_AREA), x, y)
            gu, gv = frame_uv(*GALAXY_C)
            gs = int(tw * GALAXY_R * 2 / (REGION[2] - REGION[0]))
            over(dst, cv2.resize(rotate(layers["galaxy"], 40), (gs, gs), interpolation=cv2.INTER_AREA), int(x + gu * tw - gs / 2), int(y + gv * th - gs / 2))
            over(dst, cv2.resize(layers["rays"], (tw, th), interpolation=cv2.INTER_AREA), x, y)
        elif n > 1:
            st = stages[n]
            tex = st["Tex"]
            tw = int(W * frac[n])
            th = int(tw / st["Aspect"])
            x, y = int(cx - tw / 2), int(cy - th / 2)
            over(dst, cv2.resize(tex, (tw, th), interpolation=cv2.INTER_AREA if tw < tex.shape[1] else cv2.INTER_CUBIC), x, y)
            if "Galaxy" in st:
                gu, gv, gr = st["Galaxy"]
                gs = int(tw * gr * 2)
                over(dst, cv2.resize(rotate(st["GalaxyImg"], 40), (gs, gs), interpolation=cv2.INTER_AREA), int(x + gu * tw - gs / 2), int(y + gv * th - gs / 2))
        if n >= 3:
            count = {3: 3, 4: 5, 5: 6, 6: 7, 7: 8}[n]
            spots = [(rng.uniform(0.15, 0.85) * W, rng.uniform(0.2, 0.7) * H, rng.uniform(0, 360)) for _ in range(count)]
            draw_bolts(dst, bolts, spots, 0.45)
        if n >= 4:
            size = {4: (3, 12), 5: (4, 16), 6: (5, 22), 7: (8, 34)}[n]
            draw_rocks(dst, rng, {4: 14, 5: 18, 6: 20, 7: 16}[n], (60, 40, W - 60, H * 0.75), *size)
        # La ciudad (una franja oscura abajo, para ver la luz de la etapa en el suelo)
        city = np.array([0.18, 0.16, 0.14]) * np.array(AMBIENT[n][0]) + np.array(AMBIENT[n][1]) * 2
        dst[int(H * 0.86) :] = dst[int(H * 0.86) :] * 0.25 + city
        dst = bloom(dst)
        write("preview-%d.png" % n, (np.clip(dst, 0, 1) * 255).astype(np.uint8))


if __name__ == "__main__":
    print("Grieta del cielo: texturas desde " + os.path.relpath(SRC, ROOT) + " y " + os.path.relpath(STAGES_SRC, ROOT))
    im = clean_callouts(load())
    f = im.astype(np.float32) / 255
    mask = silhouette(im)
    core = silhouette(im, grow=0)
    inner = cv2.erode(core, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))
    layers = {
        "interior": interior(f, mask),
        "rays": rays(f, cv2.GaussianBlur(inner, (0, 0), 3)),
        "glow": glow(f, mask),
        "galaxy": galaxy(f),
    }
    write("rift_interior.png", layers["interior"])
    write("rift_rays.png", layers["rays"])
    write("rift_glow.png", layers["glow"])
    write("rift_galaxy.png", layers["galaxy"])
    BLUE_CORE, BLUE_GLOW = (1.0, 0.92, 0.55), (1.0, 0.6, 0.15)
    VIOLET_CORE, VIOLET_GLOW = (1.0, 0.7, 0.9), (1.0, 0.3, 0.7)
    bolts = [
        bolt(11, BLUE_CORE, BLUE_GLOW),
        bolt(23, BLUE_CORE, BLUE_GLOW),
        bolt(37, VIOLET_CORE, VIOLET_GLOW),
        bolt(51, VIOLET_CORE, (1.0, 0.45, 0.45)),
    ]
    for i, b in enumerate(bolts):
        write("bolt_%d.png" % (i + 1), b)
    stages = build_stages()
    art_luau(core, stages)
    preview(layers, bolts)
    stage_previews(layers, stages, bolts)
