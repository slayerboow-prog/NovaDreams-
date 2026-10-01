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
#   preview.png                        vista previa: todo junto sobre un cielo azul con nubes
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


def galaxy(f):
    """La galaxia sola (512x512) con borde suave redondo: el juego la hace girar despacio."""
    x, y = GALAXY_C
    r = GALAXY_R
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


def bolt(seed, core_bgr, glow_bgr, w=512, h=256):
    """Un rayo ramificado de izquierda a derecha: núcleo blanco fino, borde del color y halo."""
    rng = np.random.default_rng(seed)
    acc_core = np.zeros((h, w), np.float32)
    acc_edge = np.zeros((h, w), np.float32)
    acc_glow = np.zeros((h, w), np.float32)

    def draw(points, width):
        pts = np.array(points, np.int32).reshape(-1, 1, 2)
        cv2.polylines(acc_glow, [pts], False, 1.0, int(width * 5 + 4), cv2.LINE_AA)
        cv2.polylines(acc_edge, [pts], False, 1.0, int(width * 2 + 1), cv2.LINE_AA)
        cv2.polylines(acc_core, [pts], False, 1.0, max(1, int(width * 0.6)), cv2.LINE_AA)

    main = bolt_path(rng, (10, h / 2 + rng.uniform(-30, 30)), (w - 10, h / 2 + rng.uniform(-70, 70)), 0.38, 7)
    draw(main, 2.2)
    for _ in range(int(rng.integers(6, 10))):
        i = int(rng.integers(len(main) // 8, len(main) * 4 // 5))
        start = main[i]
        ang = rng.uniform(-0.5, 0.5) + (0.65 if rng.random() < 0.5 else -0.65)
        length = rng.uniform(50, 180)
        end = np.clip(start + np.array([np.cos(ang), np.sin(ang)]) * length, 6, [w - 6, h - 6])
        br = bolt_path(rng, start, end, 0.4, 6)
        draw(br, 1.2)
        for _ in range(int(rng.integers(0, 3))):
            j = int(rng.integers(len(br) // 4, len(br) - 1))
            a2 = ang + rng.uniform(-0.9, 0.9)
            e2 = np.clip(br[j] + np.array([np.cos(a2), np.sin(a2)]) * rng.uniform(20, 70), 6, [w - 6, h - 6])
            draw(bolt_path(rng, br[j], e2, 0.4, 5), 0.7)
    core = np.clip(cv2.GaussianBlur(acc_core, (0, 0), 0.6) * 1.3, 0, 1)[..., None]
    edge = np.clip(cv2.GaussianBlur(acc_edge, (0, 0), 1.0), 0, 1)[..., None]
    gl = np.clip(cv2.GaussianBlur(acc_glow, (0, 0), 6) * 0.8, 0, 1)[..., None]
    a = np.clip(core + edge * 0.9 + gl * 0.55, 0, 1)
    col = np.ones(3) * core + np.array(core_bgr) * edge * (1 - core) + np.array(glow_bgr) * gl * (1 - edge)
    col = col / np.maximum(a, 1e-3)
    return rgba(np.clip(col, 0, 1), a[..., 0])


# ---------------------------------------------------------------------------
# Silueta para el dibujo sin texturas (shared/SkyRiftOutline.luau, generado)
# ---------------------------------------------------------------------------
def outline_luau(mask_core):
    m = crop((mask_core > 0.5).astype(np.uint8))
    h, w = m.shape
    contours, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    c = max(contours, key=cv2.contourArea)
    c = cv2.approxPolyDP(c, 2.2, True).reshape(-1, 2)
    # Como mucho ~90 puntos (el borde brillante se dibuja con un tramo por cada uno)
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
    lines = [
        "-- SkyRiftOutline: GENERADO por scripts/rift/gen.py (no editar a mano).",
        "-- La silueta de la rasgadura de la referencia, en fracciones del marco de las texturas",
        "-- (0..1; U a la derecha, V hacia abajo). Controllers/SkyRift la dibuja así cuando aún no",
        "-- están subidas las texturas (shared/RiftTextureIds vacío): relleno oscuro por columnas y",
        "-- borde eléctrico por tramos.",
        "return {",
        "\t-- Contorno cerrado (puntos en orden)",
        "\tRim = {",
    ]
    for x, y in c:
        lines.append("\t\t{ %.4f, %.4f }," % (x / w, y / h))
    lines.append("\t},")
    lines.append("\t-- Columnas de relleno: { U del centro, ancho, V de arriba, V de abajo }")
    lines.append("\tColumns = {")
    for u, cw, top, bot in cols:
        lines.append("\t\t{ %.4f, %.4f, %.4f, %.4f }," % (u, cw, top, bot))
    lines.append("\t},")
    lines.append("\tGalaxy = { %.4f, %.4f, %.4f }, -- U, V y radio (en fracción del ancho)" % (gu, gv, GALAXY_R / (x1 - x0)))
    lines.append("\tPlanet = { %.4f, %.4f, %.4f }," % (pu, pv, PLANET_R / (x1 - x0)))
    lines.append("}")
    path = os.path.join(ROOT, "src", "shared", "SkyRiftOutline.luau")
    with open(path, "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("  " + os.path.relpath(path, ROOT), len(c), "puntos de borde,", len(cols), "columnas")


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


def preview(layers, bolts):
    W, H = 1846, 852
    dst = sky_background(W, H)
    # El ambiente de la grieta abierta (DayLight.pushLayer con SkyMoods.GrietaAzul): más oscuro y
    # azul-violeta (nubes teñidas)
    dst = dst * np.array([0.92, 0.78, 0.74]) + np.array([0.04, 0.0, 0.02])
    x0, y0, x1, y1 = REGION
    fw, fh = x1 - x0, y1 - y0
    small = {k: cv2.resize(v, (fw, fh), interpolation=cv2.INTER_AREA) for k, v in layers.items() if k != "galaxy"}
    over(dst, small["glow"], x0, y0)
    over(dst, small["interior"], x0, y0)
    g = rotate(layers["galaxy"], 25)
    gs = GALAXY_R * 2
    over(dst, cv2.resize(g, (gs, gs), interpolation=cv2.INTER_AREA), GALAXY_C[0] - GALAXY_R, GALAXY_C[1] - GALAXY_R)
    over(dst, small["rays"], x0, y0)
    # Unos rayos que parpadean y rocas (como en el juego)
    rng = np.random.default_rng(7)
    spots = [(470, 300, 200), (1380, 300, -20), (560, 470, 140), (1200, 180, -50), (760, 190, -110), (1090, 470, 80)]
    for i, (x, y, ang) in enumerate(spots):
        b = bolts[i % len(bolts)]
        b = rotate(np.pad(b, ((128, 128), (0, 0), (0, 0))), ang, 0.6)
        over(dst, b, x - b.shape[1] // 2, y - b.shape[0] // 2)
    for _ in range(26):
        cx, cy = rng.uniform(380, 1450), rng.uniform(110, 560)
        r = rng.uniform(5, 26)
        pts = []
        for k in range(7):
            a = k / 7 * 2 * np.pi + rng.uniform(-0.3, 0.3)
            rr = r * rng.uniform(0.65, 1.15)
            pts.append((cx + np.cos(a) * rr, cy + np.sin(a) * rr * 0.85))
        pts = np.array(pts, np.int32)
        cv2.polylines(dst, [pts], True, (1.0, 0.8, 0.45), 3, cv2.LINE_AA)
        cv2.fillPoly(dst, [pts], (0.3, 0.22, 0.2), cv2.LINE_AA)
        # Cara iluminada por la grieta (arriba-izquierda, un poco más clara)
        cv2.fillPoly(dst, [((pts - pts.mean(0)) * 0.55 + pts.mean(0) - [r * 0.2, r * 0.2]).astype(np.int32)], (0.42, 0.3, 0.26), cv2.LINE_AA)
    out = (np.clip(dst, 0, 1) * 255).astype(np.uint8)
    write("preview.png", out)


if __name__ == "__main__":
    print("Grieta del cielo: texturas desde " + os.path.relpath(SRC, ROOT))
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
    outline_luau(core)
    preview(layers, bolts)
