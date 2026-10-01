"""Genera las texturas PBR de los materiales de Valmar y las guarda en roblox/textures/<Nombre>/.

Igual que el audio (scripts/audio): todo sale de código (ruido espectral, celdas, trazos), así que
las texturas son 100 % nuestras y se pueden subir a Roblox sin problemas de derechos.

Uso (desde roblox/):   python3 scripts/textures/gen.py            (todas)
                       python3 scripts/textures/gen.py Asfalto Teja   (solo esas)
Necesita:              pip install numpy pillow

Cada material es un juego PBR para un MaterialVariant de Roblox (MaterialService):
  color.png      ColorMap. NEUTRO: Roblox lo multiplica por el Color de la pieza, así que aquí solo
                 va el detalle (variación de tono y luz alrededor de un gris claro ~0,8). El color de
                 cada edificio, acera o coche lo sigue poniendo el kit (Palette).
  normal.png     NormalMap, formato OpenGL (verde = arriba), como pide Roblox.
  roughness.png  RoughnessMap (gris; blanco = mate). A media resolución: es suave y pesa poco.
  metalness.png  MetalnessMap, solo en los metales y la pintura de coche.

Todas son ENLOSABLES (se repiten sin costura): el ruido se hace con la FFT (frecuencias enteras por
baldosa), las celdas y trazos dan la vuelta por los bordes. scripts/textures/check_tiling.py lo
comprueba (y scripts/test-textures.luau lo lanza).

Materiales (tamaño del color):
  Asfalto        1024  árido fino y grueso en betún, grietas finas, manchas de aceite suaves
  AceraBaldosa   1024  baldosas de acera de 33 cm con junta, desgaste, suciedad en las juntas
  Bordillo        512  granito gris abujardado (cuarzo, feldespato y mica negra)
  Hormigon        512  hormigón visto con poros, coqueras pequeñas y manchas suaves
  Ladrillo        512  ladrillo caravista a soga con llaga de mortero, piezas variadas
  Estuco          512  enfoscado / monocapa con grano de arena
  Teja            512  teja árabe: canales y cobijas solapadas
  MetalPintado    512  chapa pintada: piel de naranja, roces y desconchones
  MetalCepillado  512  acero inoxidable cepillado
  Madera          512  tablas de madera con veta, nudos y juntas
  Marmol          512  mármol blanco con vetas, en placas
  CespedSuelo    1024  césped visto de cerca: briznas, hojas secas y tierra
  Arena           512  arena de playa con rizos del viento
  Azulejo         512  azulejo vidriado con junta
  PinturaCoche    256  laca de coche: piel de naranja fina y purpurina metalizada
  PinturaVial     512  pintura de calzada gastada que deja ver el árido
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]  # roblox/
OUT = ROOT / "textures"
TAU = 2 * np.pi


# ---------------------------------------------------------------------------------------------
# Herramientas (todo periódico: lo que sale por la derecha entra por la izquierda)
# ---------------------------------------------------------------------------------------------
def freqs(n: int):
    f = np.fft.fftfreq(n) * n  # ciclos por baldosa (enteros)
    return np.meshgrid(f, f)  # fx (columnas), fy (filas)


def spectral(rng, n: int, beta: float, fmin: float = 1, fmax: float | None = None, aniso: float = 1.0):
    """Ruido fractal 1/f^beta (media 0, desviación 1). aniso > 1 estira en horizontal."""
    fx, fy = freqs(n)
    f = np.sqrt((fx / aniso) ** 2 + fy**2)
    f[0, 0] = 1
    amp = f ** (-beta / 2)
    amp[f < fmin] = 0
    if fmax:
        amp *= np.exp(-((f / fmax) ** 2))
    amp[0, 0] = 0
    w = np.fft.fft2(rng.standard_normal((n, n)))
    out = np.real(np.fft.ifft2(w * amp))
    return (out - out.mean()) / (out.std() + 1e-9)


def band(rng, n: int, f0: float, width: float):
    """Ruido de banda (alrededor de f0 ciclos por baldosa)."""
    fx, fy = freqs(n)
    f = np.sqrt(fx**2 + fy**2)
    amp = np.exp(-(((f - f0) / width) ** 2))
    amp[0, 0] = 0
    out = np.real(np.fft.ifft2(np.fft.fft2(rng.standard_normal((n, n))) * amp))
    return (out - out.mean()) / (out.std() + 1e-9)


def blur(img, sx: float, sy: float | None = None):
    """Desenfoque gaussiano periódico (sx, sy en píxeles; distintos = anisótropo)."""
    sy = sx if sy is None else sy
    n = img.shape[0]
    fx, fy = freqs(n)
    k = np.exp(-2 * np.pi**2 * ((sx * fx / n) ** 2 + (sy * fy / n) ** 2))
    if img.ndim == 3:
        return np.stack([np.real(np.fft.ifft2(np.fft.fft2(img[..., c]) * k)) for c in range(img.shape[2])], -1)
    return np.real(np.fft.ifft2(np.fft.fft2(img) * k))


def norm01(a):
    lo, hi = a.min(), a.max()
    return (a - lo) / (hi - lo + 1e-9)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def grid(n: int):
    y, x = np.mgrid[0:n, 0:n].astype(np.float64)
    return x, y


def sample(img, x, y):
    """Lectura bilineal con vuelta por los bordes (x, y en píxeles, del tamaño de la salida)."""
    n = img.shape[0]
    x0 = np.floor(x).astype(np.int64)
    y0 = np.floor(y).astype(np.int64)
    fx = x - x0
    fy = y - y0
    x0 %= n
    y0 %= n
    x1 = (x0 + 1) % n
    y1 = (y0 + 1) % n
    if img.ndim == 3:
        fx = fx[..., None]
        fy = fy[..., None]
    a = img[y0, x0] * (1 - fx) + img[y0, x1] * fx
    b = img[y1, x0] * (1 - fx) + img[y1, x1] * fx
    return a * (1 - fy) + b * fy


def warp(img, rng, amount: float, beta: float = 3.0):
    n = img.shape[0]
    x, y = grid(n)
    return sample(img, x + spectral(rng, n, beta) * amount, y + spectral(rng, n, beta) * amount)


def voronoi(rng, n: int, cells: int, jitter: float = 0.9):
    """Celdas de Voronoi enlosables (rejilla con puntos movidos). Devuelve F1, F2 (en píxeles) e id."""
    cs = n / cells
    jx = rng.random((cells, cells)) * jitter + (1 - jitter) / 2
    jy = rng.random((cells, cells)) * jitter + (1 - jitter) / 2
    x, y = grid(n)
    cx = np.floor(x / cs).astype(np.int64)
    cy = np.floor(y / cs).astype(np.int64)
    f1 = np.full((n, n), 1e9)
    f2 = np.full((n, n), 1e9)
    ids = np.zeros((n, n), np.int64)
    for dj in (-1, 0, 1):
        for di in (-1, 0, 1):
            gx = cx + di
            gy = cy + dj
            wx = gx % cells
            wy = gy % cells
            px = (gx + jx[wy, wx]) * cs
            py = (gy + jy[wy, wx]) * cs
            d = np.sqrt((x - px) ** 2 + (y - py) ** 2)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            ids = np.where(closer, wy * cells + wx, ids)
            f1 = np.where(closer, d, f1)
    return f1, f2, ids


def per_cell(rng, ids, count: int, lo=0.0, hi=1.0):
    return (rng.random(count) * (hi - lo) + lo)[ids]


def strokes(rng, n: int, count: int, length: tuple, step=1.0, wander=0.08, branch=0.0):
    """Trazos finos (grietas, arañazos) como camino aleatorio que da la vuelta por los bordes.
    Devuelve una máscara de densidad (0..1)."""
    acc = np.zeros((n, n))
    for _ in range(count):
        stack = [(rng.random() * n, rng.random() * n, rng.random() * TAU, rng.uniform(*length), 1.0)]
        while stack:
            x, y, a, left, w = stack.pop()
            a0 = a
            turn = 0.0
            pts = []
            while left > 0:
                # Ondula pero no se enrosca: el rumbo vuelve poco a poco a la dirección de salida
                turn = turn * 0.6 + rng.normal(0, wander)
                a += turn + (a0 - a) * 0.04
                x += np.cos(a) * step
                y += np.sin(a) * step
                left -= step
                pts.append((x, y))
                if branch and rng.random() < branch:
                    stack.append((x, y, a + rng.choice([-1, 1]) * rng.uniform(0.5, 1.2), left * rng.uniform(0.3, 0.6), w * 0.6))
            if pts:
                p = np.array(pts)
                xi = np.floor(p[:, 0]).astype(np.int64) % n
                yi = np.floor(p[:, 1]).astype(np.int64) % n
                np.maximum.at(acc, (yi, xi), w)
    return np.clip(blur(acc, 0.6) * 2.2, 0, 1)


def blobs(rng, n: int, count: int, radius: tuple, soft=0.6):
    """Manchas redondeadas (aceite, humedad) con distancia periódica."""
    x, y = grid(n)
    acc = np.zeros((n, n))
    for _ in range(count):
        cx, cy, r = rng.random() * n, rng.random() * n, rng.uniform(*radius)
        dx = (x - cx + n / 2) % n - n / 2
        dy = (y - cy + n / 2) % n - n / 2
        d = np.sqrt(dx**2 + dy**2) / r
        acc = np.maximum(acc, (1 - smooth(soft, 1.0, d)) * rng.uniform(0.6, 1.0))
    return acc


def cells(n: int, cols: int, rows: int, offset: float = 0.0):
    """Rejilla de piezas (ladrillos, baldosas, tablas). offset = desfase de las filas impares (en
    piezas). Devuelve: id de pieza, u, v (0..1 dentro de la pieza), ancho y alto en píxeles."""
    x, y = grid(n)
    pw, ph = n / cols, n / rows
    row = np.floor(y / ph).astype(np.int64)
    shift = (row % 2) * offset
    xc = x / pw + shift
    col = np.floor(xc).astype(np.int64) % cols
    u = xc - np.floor(xc)
    v = y / ph - row
    return row * cols + col, u, v, pw, ph


def edge_distance(u, v, pw, ph):
    """Distancia (en píxeles) al borde más cercano de la pieza."""
    return np.minimum(np.minimum(u, 1 - u) * pw, np.minimum(v, 1 - v) * ph)


def normal_map(h, strength: float):
    """Altura (0..1) -> mapa normal OpenGL (verde = arriba). strength ~ píxeles de relieve por unidad."""
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    nx, ny, nz = -gx, gy, np.ones_like(h)  # filas hacia abajo; v (verde) hacia arriba
    length = np.sqrt(nx**2 + ny**2 + nz**2)
    return np.stack([nx / length, ny / length, nz / length], -1) * 0.5 + 0.5


def lum(rgb):
    return rgb[..., 0] * 0.2126 + rgb[..., 1] * 0.7152 + rgb[..., 2] * 0.0722


def tintable(rgb, target: float = 0.82):
    """Quita el tono medio (lo pone la pieza con su Color) y deja la luminancia media en target."""
    rgb = np.clip(rgb, 1e-4, None)
    m = rgb.reshape(-1, 3).mean(0)
    rgb = rgb / m * lum(m[None, None, :]).item()
    rgb = rgb / lum(rgb).mean() * target
    return np.clip(rgb, 0, 1)


def colorize(base: tuple, v):
    return np.asarray(base, np.float64)[None, None, :] * v[..., None]


def down(img, factor: int = 2):
    n = img.shape[0] // factor
    return img.reshape(n, factor, n, factor, *img.shape[2:]).mean((1, 3))


# ---------------------------------------------------------------------------------------------
# Materiales
# ---------------------------------------------------------------------------------------------
def asfalto(rng, n):
    x, y = grid(n)
    # Árido grueso (piedras de ~3 cm) y fino, en betún
    f1, f2, ids = voronoi(rng, n, n // 9)
    cs = 9
    present = per_cell(rng, ids, (n // 9) ** 2) < 0.5
    rad = per_cell(rng, ids, (n // 9) ** 2, 0.32, 0.62) * cs
    dome = np.clip(1 - f1 / rad, 0, 1) ** 0.6 * present
    stone_tone = per_cell(rng, ids, (n // 9) ** 2, 0.55, 1.0)
    stone_warm = per_cell(rng, ids, (n // 9) ** 2, -0.04, 0.04)
    g1, _, ids2 = voronoi(rng, n, n // 4)
    present2 = per_cell(rng, ids2, (n // 4) ** 2) < 0.5
    dome2 = np.clip(1 - g1 / (per_cell(rng, ids2, (n // 4) ** 2, 0.3, 0.55) * 4), 0, 1) ** 0.7 * present2
    tone2 = per_cell(rng, ids2, (n // 4) ** 2, 0.5, 0.95)
    grain = blur(rng.standard_normal((n, n)), 0.7)
    low = spectral(rng, n, 2.6, fmin=1, fmax=40)
    wear = smooth(-0.6, 1.2, spectral(rng, n, 3.0, fmax=20))  # zonas más gastadas = más árido visto

    binder = 0.60 + grain * 0.035 + low * 0.03
    stones = np.maximum(dome > 0.02, 0) * 1.0
    stone_v = 0.70 + (stone_tone - 0.75) * 0.35
    v = binder * (1 - stones) + stone_v * stones * (0.75 + 0.25 * wear) + binder * stones * (0.25 - 0.25 * wear)
    fine = (dome2 > 0.05) * (1 - stones)
    v = v * (1 - fine * 0.35) + (0.66 + (tone2 - 0.7) * 0.2) * fine * 0.35
    rgb = np.stack([v * (1 + stone_warm * stones), v, v * (1 - stone_warm * stones * 0.8 + 0.01)], -1)

    # Grietas finas (pocas y largas, sin formas que llamen la atención al repetirse)
    crack = strokes(rng, n, 5, (160, 420), step=1.0, wander=0.03, branch=0.004)
    # Manchas de aceite: muchas, pequeñas y flojas
    oil = blobs(rng, n, 14, (10, 34), soft=0.2) * smooth(-1, 1, spectral(rng, n, 2.2)) * 0.9
    rgb *= (1 - oil[..., None] * 0.22) * (1 - crack[..., None] * 0.55)
    rgb *= (1 + low[..., None] * 0.02)

    h = 0.25 + grain * 0.03 + dome * 0.55 * (0.6 + 0.4 * wear) + dome2 * 0.25 - crack * 0.6
    rough = 0.9 - stones * 0.06 * wear - oil * 0.32 + crack * 0.06 + grain * 0.02
    return dict(color=tintable(rgb, 0.80), height=h, normal_strength=3.2, roughness=rough)


def acera(rng, n):
    cols = 8
    pid, u, v, pw, ph = cells(n, cols, cols)
    count = cols * cols
    e = edge_distance(u, v, pw, ph)
    tone = per_cell(rng, pid, count, -0.05, 0.05)
    hue = per_cell(rng, pid, count, -0.015, 0.015)
    tiltx = per_cell(rng, pid, count, -1, 1)
    tilty = per_cell(rng, pid, count, -1, 1)
    sink = per_cell(rng, pid, count, -0.05, 0.05)
    chip = smooth(0.2, 1.4, spectral(rng, n, 1.6, fmin=8)) * 3.0  # bordes mordidos
    grout = 1 - smooth(1.4, 2.6 + chip * 0.4, e + spectral(rng, n, 2.0, fmin=16) * 0.5)
    bevel = smooth(0, 7, e)

    # Superficie: cemento con granitos claros y oscuros (árido visto del terrazo de acera)
    f1, f2, ids = voronoi(rng, n, n // 5)
    specks = (f1 < per_cell(rng, ids, (n // 5) ** 2, 0.0, 2.2)) * per_cell(rng, ids, (n // 5) ** 2, -1, 1)
    grain = blur(rng.standard_normal((n, n)), 0.6)
    dirt_low = spectral(rng, n, 2.4, fmax=30)
    dirt_grout = blur(grout, 5)  # la suciedad se acumula junto a las juntas

    val = 0.86 + tone + specks * 0.07 + grain * 0.025 + dirt_low * 0.025 - dirt_grout * 0.15
    # Alguna baldosa con fisura
    crack = strokes(rng, n, 3, (50, 120), wander=0.03) * (grout < 0.5)
    val = val * (1 - crack * 0.45)
    val = val * (1 - grout) + (0.5 + grain * 0.03) * grout
    rgb = np.stack([val * (1 + hue), val, val * (1 - hue)], -1)

    h = 0.5 + (tiltx * (u - 0.5) + tilty * (v - 0.5)) * 0.06 + sink + bevel * 0.12 + grain * 0.012 + specks * 0.01
    h = h * (1 - grout) + 0.3 * grout - crack * 0.1
    rough = 0.82 + grain * 0.03 + grout * 0.12 - specks * 0.04 + dirt_low * 0.03
    return dict(color=tintable(rgb, 0.82), height=h, normal_strength=7, roughness=rough)


def bordillo(rng, n):
    f1, f2, ids = voronoi(rng, n, n // 6)
    count = (n // 6) ** 2
    kind = per_cell(rng, ids, count)
    quartz = kind < 0.42
    feld = (kind >= 0.42) & (kind < 0.84)
    mica = kind >= 0.84
    tone = per_cell(rng, ids, count, -0.06, 0.06)
    val = np.where(quartz, 0.70 + tone, np.where(feld, 0.86 + tone * 0.6, 0.22 + tone))
    edge = smooth(0.0, 1.6, f2 - f1)
    val = val * (0.92 + 0.08 * edge)
    pink = feld * per_cell(rng, ids, count, 0.0, 0.035)
    grain = blur(rng.standard_normal((n, n)), 0.6)
    val = val + grain * 0.03 + spectral(rng, n, 2.4, fmax=20) * 0.02
    rgb = np.stack([val * (1 + pink), val, val * (1 - pink * 0.6)], -1)
    # Abujardado: picado fino y algo de suciedad
    pick = blur(rng.standard_normal((n, n)), 1.2)
    h = 0.5 + pick * 0.12 + quartz * 0.03 - mica * 0.02
    rough = 0.62 + pick * 0.05 - mica * 0.15 - quartz * 0.06
    return dict(color=tintable(rgb, 0.80), height=h, normal_strength=4, roughness=rough)


def hormigon(rng, n):
    low = spectral(rng, n, 2.8, fmax=24)
    mid = spectral(rng, n, 1.9, fmin=6, fmax=90)
    grain = blur(rng.standard_normal((n, n)), 0.6)
    # Poros y coqueras pequeñas
    x, y = grid(n)
    pores = np.zeros((n, n))
    pts = rng.random((900, 2)) * n
    rads = rng.uniform(0.6, 1.8, 900) ** 1.3
    rads[:40] = rng.uniform(2.2, 3.4, 40)
    for (px, py), r in zip(pts, rads):
        x0, y0 = int(px), int(py)
        k = int(r + 3)
        ys = (np.arange(y0 - k, y0 + k + 1)) % n
        xs = (np.arange(x0 - k, x0 + k + 1)) % n
        dy = np.arange(y0 - k, y0 + k + 1) - py
        dx = np.arange(x0 - k, x0 + k + 1) - px
        d = np.sqrt(dx[None, :] ** 2 + dy[:, None] ** 2) / r
        pores[np.ix_(ys, xs)] = np.maximum(pores[np.ix_(ys, xs)], np.clip(1 - d, 0, 1) ** 0.7)
    stain = smooth(0.6, 2.4, spectral(rng, n, 3.0, fmax=12))
    val = 0.84 + low * 0.035 + mid * 0.02 + grain * 0.018 - pores * 0.28 - stain * 0.05
    warm = low * 0.008
    rgb = np.stack([val * (1 + warm), val, val * (1 - warm)], -1)
    h = 0.5 + mid * 0.03 + grain * 0.04 - pores * 0.5
    rough = 0.86 + grain * 0.03 + pores * 0.08 - stain * 0.05
    return dict(color=tintable(rgb, 0.82), height=h, normal_strength=3.5, roughness=rough)


def ladrillo(rng, n):
    cols, rows = 8, 24
    pid, u, v, pw, ph = cells(n, cols, rows, offset=0.5)
    count = cols * rows
    e = edge_distance(u, v, pw, ph)
    chip = smooth(0.0, 1.5, spectral(rng, n, 1.5, fmin=10)) * 1.6
    mortar = 1 - smooth(2.2, 3.4 + chip * 0.5, e + spectral(rng, n, 2.0, fmin=20) * 0.6)
    tone = per_cell(rng, pid, count, -0.13, 0.11)
    burnt = per_cell(rng, pid, count) < 0.08  # alguna pieza más tostada
    hue = per_cell(rng, pid, count, -0.05, 0.05)
    grain = blur(rng.standard_normal((n, n)), 0.7)
    sand = blur(rng.standard_normal((n, n)), 1.5)
    face_low = spectral(rng, n, 2.2, fmin=4, fmax=60)
    val = 0.78 + tone - burnt * 0.08 + grain * 0.035 + face_low * 0.035
    # Pieza: rojo-anaranjado relativo (luego se neutraliza; queda la variación entre piezas)
    r = val * (1.0 + hue)
    g = val * (0.60 - hue * 0.6 - burnt * 0.05)
    b = val * (0.50 - hue * 0.3)
    mortar_v = 1.0 + sand * 0.05
    rgb = np.stack([r, g, b], -1) * (1 - mortar[..., None]) + np.stack([mortar_v * 0.98, mortar_v * 0.96, mortar_v * 0.92], -1) * 0.95 * mortar[..., None]
    rgb *= (1 - blur(mortar, 2.5)[..., None] * 0.12)  # sombra de la llaga
    bevel = smooth(0, 6, e)
    h = 0.55 + bevel * 0.2 + grain * 0.02 + face_low * 0.02 - chip * 0.02
    h = h * (1 - mortar) + (0.25 + sand * 0.02) * mortar
    rough = 0.84 + grain * 0.03 + mortar * 0.1
    return dict(color=tintable(rgb, 0.80), height=h, normal_strength=8, roughness=rough)


def estuco(rng, n):
    grain = blur(rng.standard_normal((n, n)), 0.8)
    bumps = band(rng, n, n / 9, n / 24)
    bumps = np.maximum(bumps, 0) ** 1.4
    trowel = spectral(rng, n, 2.6, fmin=3, fmax=40, aniso=2.5)
    low = spectral(rng, n, 2.8, fmax=14)
    val = 0.86 + grain * 0.022 + bumps * 0.03 + low * 0.03 + trowel * 0.015
    tint = low * 0.006
    rgb = np.stack([val * (1 + tint), val, val * (1 - tint)], -1)
    h = 0.5 + grain * 0.06 + bumps * 0.12 + trowel * 0.04
    rough = 0.9 + grain * 0.03 - bumps * 0.03
    return dict(color=tintable(rgb, 0.84), height=h, normal_strength=4, roughness=rough)


def teja(rng, n):
    cols, rows = 16, 6  # 8 cobijas (arriba, curvas) y 8 canales (debajo)
    x, y = grid(n)
    pw, ph = n / cols, n / rows
    col = np.floor(x / pw).astype(np.int64)
    u = x / pw - col
    cover = (col % 2) == 0
    shift = np.where(cover, 0.0, 0.5)
    yy = y / ph + shift
    row = np.floor(yy).astype(np.int64) % rows
    v = yy - np.floor(yy)  # 0 arriba de la teja .. 1 abajo (borde que solapa a la siguiente)
    pid = row * cols + col
    count = rows * cols
    # Perfil: la cobija es una media caña (abombada) algo más ancha; el canal, cóncavo y hundido
    wide = 0.62
    uc = np.where(cover, (u - 0.5), np.where(u < 0.5, u + 0.5, u - 0.5) - 0.5)  # la cobija ocupa el centro
    across = np.clip(1 - (np.abs(uc) / wide) ** 2, 0, 1) ** 0.5
    taper = 0.86 + 0.14 * v  # la teja es más ancha por abajo
    prof_cover = np.clip(1 - (np.abs(u - 0.5) / (0.5 * taper)) ** 2, 0, 1) ** 0.5
    prof_chan = 1 - np.clip(1 - (np.abs(u - 0.5) / 0.5) ** 2, 0, 1) ** 0.5
    h = np.where(cover, 0.55 + prof_cover * 0.45, 0.12 + prof_chan * 0.18)
    h = h + v * 0.08  # cada teja sube hacia su borde inferior y ahí cae a la siguiente
    lip = smooth(0.92, 1.0, v)
    h -= lip * 0.06
    tone = per_cell(rng, pid, count, -0.12, 0.10)
    hue = per_cell(rng, pid, count, -0.05, 0.05)
    grain = blur(rng.standard_normal((n, n)), 0.8)
    weather = smooth(0.6, 2.2, spectral(rng, n, 2.2, fmin=3, fmax=60))  # líquenes y suciedad
    val = 0.8 + tone + grain * 0.03 - weather * 0.09
    occl = np.where(cover, 1 - (1 - prof_cover) * 0.35, 0.62 + prof_chan * 0.2) * (1 - smooth(0.0, 0.08, 1 - v) * 0.0)
    shade_under = np.where(cover, 1.0, 1 - smooth(0.05, 0.0, v) * 0.25 - (1 - smooth(0.0, 0.18, v)) * 0.2)
    val = val * occl * shade_under
    r = val * (1 + hue)
    g = val * (0.58 - hue * 0.4 - weather * 0.03)
    b = val * (0.44 - hue * 0.2 + weather * 0.02)
    rgb = np.stack([r, g, b], -1)
    h = h + grain * 0.01
    rough = 0.82 + grain * 0.03 + weather * 0.08
    return dict(color=tintable(rgb, 0.78), height=h, normal_strength=26, roughness=rough)


def metal_pintado(rng, n):
    peel = band(rng, n, n / 6, n / 14)
    low = spectral(rng, n, 2.6, fmax=24)
    dust = smooth(0.3, 2.2, spectral(rng, n, 2.2, fmax=40))
    chips_mask = smooth(1.2, 2.6, spectral(rng, n, 2.0, fmin=2, fmax=60)) * (smooth(1.1, 1.8, band(rng, n, n / 10, n / 20)))
    chips = chips_mask > 0.35
    scratch = strokes(rng, n, 45, (12, 70), step=1.0, wander=0.02)
    val = 0.86 + low * 0.02 + peel * 0.008 + dust * 0.05 + scratch * 0.06
    val = np.where(chips, 0.42 + low * 0.03, val)
    rgb = np.stack([val, val, val], -1)
    h = 0.5 + peel * 0.03 - chips * 0.08 - scratch * 0.04
    rough = 0.42 + dust * 0.22 + low * 0.03 - scratch * 0.1 + chips * 0.1
    metal = chips * 0.85 + scratch * 0.15
    return dict(color=tintable(rgb, 0.84), height=h, normal_strength=4, roughness=rough, metalness=metal)


def metal_cepillado(rng, n):
    streak = blur(rng.standard_normal((n, n)), 60, 0.5)
    streak = (streak - streak.mean()) / streak.std()
    fine = blur(rng.standard_normal((n, n)), 18, 0.4)
    fine = (fine - fine.mean()) / fine.std()
    low = spectral(rng, n, 2.6, fmax=16)
    scratch = strokes(rng, n, 14, (20, 80), step=1.0, wander=0.015)
    val = 0.9 + streak * 0.025 + fine * 0.012 + low * 0.015 + scratch * 0.04
    rgb = np.stack([val, val, val * 1.01], -1)
    h = 0.5 + streak * 0.05 + fine * 0.04 - scratch * 0.05
    rough = 0.3 + streak * 0.04 + low * 0.04 - scratch * 0.08
    metal = np.full((n, n), 0.95) - low * 0.02
    return dict(color=tintable(rgb, 0.86), height=h, normal_strength=3, roughness=rough, metalness=metal)


def madera(rng, n):
    rows = 8  # tablas en horizontal (veta a lo largo)
    x, y = grid(n)
    ph = n / rows
    row = np.floor(y / ph).astype(np.int64)
    v = y / ph - row
    offs = rng.random(rows) * n
    lens = n / 2
    xs = (x - offs[row]) % n
    seg = np.floor(xs / lens).astype(np.int64)
    u = (xs - seg * lens) / lens
    pid = row * 2 + seg
    count = rows * 2
    # Veta: anillos (seno) deformados por ruido estirado a lo largo de la tabla
    stretch = spectral(rng, n, 3.0, fmin=1, fmax=60, aniso=8)
    fine = blur(rng.standard_normal((n, n)), 14, 0.5)
    fine = (fine - fine.mean()) / fine.std()
    ring_f = per_cell(rng, pid, count, 7, 13)
    ring_p = per_cell(rng, pid, count, 0, 10)
    rings = np.sin(TAU * (v * ring_f * 0.35 + ring_p + stretch * 0.9))
    rings = smooth(-0.2, 1.0, rings)
    # Nudos (pocos)
    knots = np.zeros((n, n))
    for i in range(count):
        if rng.random() < 0.3:
            r = i // 2
            kx = (offs[r] + (i % 2) * lens + rng.uniform(0.15, 0.85) * lens) % n
            ky = (r + rng.uniform(0.3, 0.7)) * ph
            dx = (x - kx + n / 2) % n - n / 2
            dy = y - ky
            d = np.sqrt((dx / 1.6) ** 2 + dy**2)
            rr = rng.uniform(4, 9)
            knots = np.maximum(knots, np.clip(1 - d / rr, 0, 1) * (row == r))
    tone = per_cell(rng, pid, count, -0.12, 0.1)
    hue = per_cell(rng, pid, count, -0.04, 0.04)
    gap = 1 - smooth(0.6, 1.8, np.minimum(v, 1 - v) * ph)
    joint = 1 - smooth(0.6, 1.8, np.minimum(u, 1 - u) * lens)
    seams = np.maximum(gap, joint)
    val = 0.8 + tone + rings * 0.08 + fine * 0.035 - knots * 0.35
    r = val * (1 + hue)
    g = val * (0.72 - hue * 0.5 - rings * 0.02)
    b = val * (0.52 - hue * 0.3 - rings * 0.03)
    rgb = np.stack([r, g, b], -1) * (1 - seams[..., None] * 0.6)
    bevel = smooth(0, 3, np.minimum(np.minimum(v, 1 - v) * ph, np.minimum(u, 1 - u) * lens))
    h = 0.5 + bevel * 0.1 + fine * 0.02 + rings * 0.01 - seams * 0.2 + knots * 0.02
    rough = 0.55 + fine * 0.03 + rings * 0.05 + seams * 0.25 - knots * 0.05
    return dict(color=tintable(rgb, 0.78), height=h, normal_strength=7, roughness=rough)


def marmol(rng, n):
    slabs = 4
    pid, u, v, pw, ph = cells(n, slabs, slabs)
    count = slabs * slabs
    x, y = grid(n)
    # Cada placa con sus vetas (el mismo bloque, desplazado y girado de dirección)
    sx = per_cell(rng, pid, count, 0, n)
    sy = per_cell(rng, pid, count, 0, n)
    # Vetas: los ceros de un ruido suave y deformado forman una red de líneas largas (como el mármol)
    field = warp(spectral(rng, n, 3.4, fmin=1, fmax=10), rng, 26, beta=3.4)
    fine_field = warp(spectral(rng, n, 3.0, fmin=4, fmax=28), rng, 10, beta=3.0)
    def line_distance(f):  # distancia (px) a la línea donde f = 0: |f| / |gradiente|
        gx = (np.roll(f, -1, 1) - np.roll(f, 1, 1)) * 0.5
        gy = (np.roll(f, -1, 0) - np.roll(f, 1, 0)) * 0.5
        return np.abs(f) / (np.sqrt(gx**2 + gy**2) + 1e-4)

    width = 0.8 + smooth(-1, 1.5, spectral(rng, n, 2.6, fmax=12)) * 1.6  # vetas que engordan y adelgazan
    d = line_distance(sample(field, x + sx, y + sy))
    veins = 1 - smooth(0.0, width, d)
    halo = 1 - smooth(0.0, width * 9, d)
    fine_v = (1 - smooth(0.0, 0.8, line_distance(sample(fine_field, x + sx * 0.7, y + sy * 0.3)))) * smooth(-0.4, 0.8, spectral(rng, n, 2.4, fmax=16))
    tone = per_cell(rng, pid, count, -0.03, 0.03)
    cloud = spectral(rng, n, 2.6, fmax=30)
    val = 0.93 + tone + cloud * 0.02 - halo * 0.1 - veins * 0.32 - fine_v * 0.12
    warm = cloud * 0.01 + veins * 0.02
    rgb = np.stack([val * (1 + warm), val, val * (1 - warm * 1.5)], -1)
    e = edge_distance(u, v, pw, ph)
    joint = 1 - smooth(0.5, 1.4, e)
    rgb *= (1 - joint[..., None] * 0.35)
    pits = (rng.random((n, n)) < 0.0006) * 1.0
    h = 0.5 - joint * 0.3 - blur(pits, 0.6) * 0.15
    rough = 0.12 + veins * 0.06 + joint * 0.5 + blur(pits, 0.6) * 0.5 + cloud * 0.01
    return dict(color=tintable(rgb, 0.86), height=h, normal_strength=4, roughness=rough)


def cesped(rng, n):
    x, y = grid(n)
    # Fondo: tierra y hojarasca
    soil_n = spectral(rng, n, 2.0, fmin=4, fmax=200)
    soil = np.stack([0.36 + soil_n * 0.04, 0.29 + soil_n * 0.03, 0.2 + soil_n * 0.02], -1)
    color = soil.copy()
    height = np.zeros((n, n)) + soil_n * 0.02
    density = smooth(-2.0, 0.2, spectral(rng, n, 2.2, fmin=6, fmax=60))  # calvas pequeñas
    dry_zone = smooth(0.4, 2.0, spectral(rng, n, 2.2, fmin=6, fmax=60))
    total = int(n * n / 7.5)
    layers = 3
    for layer in range(layers):
        k = total // layers
        px = rng.random(k) * n
        py = rng.random(k) * n
        keep = rng.random(k) < density[py.astype(int) % n, px.astype(int) % n] * 0.85 + 0.15
        px, py = px[keep], py[keep]
        k = len(px)
        ang = rng.uniform(0, TAU, k)
        ln = rng.uniform(5, 14, k)
        dry = rng.random(k) < (0.05 + dry_zone[py.astype(int) % n, px.astype(int) % n] * 0.12)
        g = rng.uniform(0.75, 1.15, k)
        base = np.where(dry[:, None], np.array([0.72, 0.62, 0.34]) * g[:, None], np.array([0.30, 0.52, 0.18]) * g[:, None] * rng.uniform(0.85, 1.15, (k, 1)) ** np.array([1, 0, 1]))
        steps = 12
        t = np.linspace(0, 1, steps)
        for w in (0.0, 0.7):
            bx = px[:, None] + np.cos(ang)[:, None] * ln[:, None] * t[None, :] - np.sin(ang)[:, None] * w
            by = py[:, None] + np.sin(ang)[:, None] * ln[:, None] * t[None, :] + np.cos(ang)[:, None] * w
            xi = np.floor(bx).astype(np.int64).ravel() % n
            yi = np.floor(by).astype(np.int64).ravel() % n
            shade = (0.55 + 0.45 * t)[None, :, None] * (0.8 + 0.2 * layer / (layers - 1))
            col = (base[:, None, :] * shade).reshape(-1, 3)
            hh = ((0.3 + 0.7 * t)[None, :] * (0.5 + 0.5 * layer / (layers - 1)) * np.ones((k, 1))).ravel()
            order = np.argsort(hh)
            xi, yi, col, hh = xi[order], yi[order], col[order], hh[order]
            higher = hh > height[yi, xi]
            color[yi[higher], xi[higher]] = col[higher]
            height[yi[higher], xi[higher]] = hh[higher]
    color = blur(color, 0.45)
    height = blur(height, 0.6)
    occl = 0.7 + 0.3 * norm01(height)
    rgb = color * occl[..., None]
    rough = 0.82 + (1 - norm01(height)) * 0.12
    return dict(color=tintable(rgb, 0.80), height=height, normal_strength=5, roughness=rough)


def arena(rng, n):
    x, y = grid(n)
    grain = blur(rng.standard_normal((n, n)), 0.55)
    coarse = blur(rng.standard_normal((n, n)), 1.2)
    warp_n = spectral(rng, n, 3.0, fmax=12)
    amp = smooth(-1.2, 1.0, spectral(rng, n, 2.8, fmax=10))
    ripples = np.sin(TAU * (9 * x / n + 2 * y / n) + warp_n * 1.3)
    ripples = np.sign(ripples) * np.abs(ripples) ** 0.8
    dark = (rng.random((n, n)) < 0.02) * 1.0
    light = (rng.random((n, n)) < 0.015) * 1.0
    low = spectral(rng, n, 2.6, fmax=20)
    val = 0.86 + grain * 0.05 + coarse * 0.02 - blur(dark, 0.5) * 0.9 + blur(light, 0.5) * 0.5 + low * 0.03 - ripples * amp * 0.025
    warm = grain * 0.02 + blur(dark, 0.5) * -0.2
    rgb = np.stack([val * (1 + warm), val, val * (1 - warm * 1.5)], -1)
    h = 0.5 + ripples * amp * 0.14 + grain * 0.06 + coarse * 0.04
    rough = 0.94 + grain * 0.02
    return dict(color=tintable(rgb, 0.84), height=h, normal_strength=6, roughness=rough)


def azulejo(rng, n):
    cols = 8
    pid, u, v, pw, ph = cells(n, cols, cols)
    count = cols * cols
    e = edge_distance(u, v, pw, ph)
    grout = 1 - smooth(1.2, 2.4, e)
    bevel = smooth(0.0, 6.0, e) ** 0.6
    tone = per_cell(rng, pid, count, -0.025, 0.02)
    glaze = spectral(rng, n, 2.8, fmin=4, fmax=40)
    grain = blur(rng.standard_normal((n, n)), 0.7)
    val = 0.94 + tone + glaze * 0.008
    val = val * (1 - grout) + (0.66 + grain * 0.03) * grout
    rgb = np.stack([val, val, val * 1.005], -1)
    h = 0.5 + bevel * 0.35 + glaze * 0.01
    h = h * (1 - grout) + 0.2 * grout
    rough = 0.1 + np.abs(glaze) * 0.03 + grout * 0.75 + grain * 0.02 * grout
    return dict(color=tintable(rgb, 0.88), height=h, normal_strength=9, roughness=rough)


def pintura_coche(rng, n):
    peel = band(rng, n, n / 8, n / 16)
    flakes = rng.random((n, n))
    flake = (flakes > 0.985) * 1.0
    val = 0.95 + (flakes - 0.5) * 0.02 + flake * 0.04
    rgb = np.stack([val, val, val], -1)
    h = 0.5 + peel * 0.05
    rough = 0.16 + peel * 0.015 - flake * 0.06
    metal = 0.3 + flake * 0.5
    return dict(color=tintable(rgb, 0.94), height=h, normal_strength=2.0, roughness=rough, metalness=metal)


def pintura_vial(rng, n):
    f1, f2, ids = voronoi(rng, n, n // 8)
    count = (n // 8) ** 2
    dome = np.clip(1 - f1 / (per_cell(rng, ids, count, 0.3, 0.6) * 8), 0, 1) ** 0.6 * (per_cell(rng, ids, count) < 0.6)
    wear_field = spectral(rng, n, 2.0, fmin=4, fmax=90) * 0.6 + dome * 1.6
    worn = smooth(1.7, 2.3, wear_field)  # el árido asoma por la pintura en las crestas
    grain = blur(rng.standard_normal((n, n)), 0.6)
    tire = smooth(0.4, 1.6, spectral(rng, n, 2.6, fmax=16, aniso=4))  # marcas de rueda, suaves
    val = 0.95 + grain * 0.02 - tire * 0.08
    val = val * (1 - worn) + (0.22 + grain * 0.03) * worn
    rgb = np.stack([val, val, val], -1)
    h = 0.4 + dome * 0.5 + grain * 0.03
    rough = 0.62 + worn * 0.28 + tire * 0.05 + grain * 0.02
    return dict(color=tintable(rgb, 0.86), height=h, normal_strength=3, roughness=rough)


# nombre -> (función, tamaño, semilla)
MATERIALS = {
    "Asfalto": (asfalto, 1024, 11),
    "AceraBaldosa": (acera, 1024, 12),
    "Bordillo": (bordillo, 512, 13),
    "Hormigon": (hormigon, 512, 14),
    "Ladrillo": (ladrillo, 512, 15),
    "Estuco": (estuco, 512, 16),
    "Teja": (teja, 512, 17),
    "MetalPintado": (metal_pintado, 512, 18),
    "MetalCepillado": (metal_cepillado, 512, 19),
    "Madera": (madera, 512, 20),
    "Marmol": (marmol, 512, 21),
    "CespedSuelo": (cesped, 1024, 22),
    "Arena": (arena, 512, 23),
    "Azulejo": (azulejo, 512, 24),
    "PinturaCoche": (pintura_coche, 256, 25),
    "PinturaVial": (pintura_vial, 512, 26),
}


def to8(a):
    return (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)


def save(name: str, data: dict, n: int) -> dict:
    folder = OUT / name
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob("*.png"):
        old.unlink()
    files = {}
    color = data["color"]
    Image.fromarray(to8(color), "RGB").save(folder / "color.png", optimize=True)
    files["color"] = color
    h = data["height"]
    h = (h - h.min()) / (h.max() - h.min() + 1e-9)
    nm = normal_map(h, data["normal_strength"] * n / 512)
    Image.fromarray(to8(nm), "RGB").save(folder / "normal.png", optimize=True)
    rough = np.clip(data["roughness"], 0.02, 1)
    half = max(n // 2, 128)
    Image.fromarray(to8(down(rough, n // half)), "L").save(folder / "roughness.png", optimize=True)
    if "metalness" in data:
        Image.fromarray(to8(down(np.clip(data["metalness"], 0, 1), n // half)), "L").save(folder / "metalness.png", optimize=True)
    return {
        "size": n,
        "maps": sorted(p.stem for p in folder.glob("*.png")),
        "meanColor": round(float(lum(color).mean()), 3),
        "meanRoughness": round(float(rough.mean()), 3),
    }


def main(argv):
    names = argv or list(MATERIALS)
    manifest_path = OUT / "manifest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    for name in names:
        if name not in MATERIALS:
            print(f"❌ No existe el material {name}. Hay: {', '.join(MATERIALS)}")
            return 1
        fn, n, seed = MATERIALS[name]
        rng = np.random.default_rng(seed)
        data = fn(rng, n)
        manifest[name] = save(name, data, n)
        kb = sum(p.stat().st_size for p in (OUT / name).glob("*.png")) / 1024
        print(f"  ✅ {name:15s} {n}²  {', '.join(manifest[name]['maps'])}  ({kb:.0f} KB)")
    manifest = {k: manifest[k] for k in MATERIALS if k in manifest}
    manifest_path.write_text(json.dumps(manifest, indent=1, ensure_ascii=False) + "\n")
    total = sum(p.stat().st_size for p in OUT.rglob("*.png")) / 1024 / 1024
    print(f"📦 textures/: {total:.1f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
