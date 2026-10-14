"""Genera las texturas del espacio, de los planetas y de la nave (assets/espacio/), 100 % nuestras.

Uso (desde roblox/):   python3 -I scripts/espacio/gen.py            (todas)
                       python3 -I scripts/espacio/gen.py cielo      (solo las que empiezan así)
                       python3 -I scripts/espacio/gen.py --preview  (y las vistas previas de docs/planetas/)
Necesita:              pip install numpy pillow

Por qué aquí y no descargadas: la red de la sesión que las hizo no dejaba bajar nada de Poly Haven,
ambientCG ni de la NASA, así que TODO sale de código (ruido fractal 3D sobre la esfera, celdas,
trazos). Se pueden usar y subir sin problemas de derechos (LICENCIAS.md: dominio público, CC0).

Lo que sale (todas ≤ 1024 px por lado, el máximo de Roblox):
  cielo_espacio_{bk,dn,ft,lf,rt,up}.jpg   Sky del espacio: nebulosa, Vía Láctea y estrellas (1024)
  cielo_lontana_{...}.jpg                  Sky de Lontana: cielo malva, la luna Ovilla enorme, humo (1024)
  planeta_<id>.jpg                         superficie de cada planeta (equirrectangular 1024x512)
  nubes_<id>.png                           capa de nubes con transparencia (Lontana, Marena, Fronda)
  halo_atmosfera.png                       aro de la atmósfera (blanco: el juego lo tiñe por planeta)
  nave_casco_{color,normal,roughness,metalness}.png   chapa de la nave (MaterialVariant NaveCasco)
  roca_lontana_{color,normal,roughness}.png           roca de Lontana (MaterialVariant LontanaRoca)

Caras del Sky (convención de las piezas de Roblox: Front = -Z, Back = +Z, Left = -X, Right = +X).
Si al subirlas se ve una costura, se cambia FACE_FLIP abajo y se vuelven a generar.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "espacio"
DOCS = ROOT / "docs" / "planetas"

SKY = 1024
PLANET_W, PLANET_H = 1024, 512

# ---------------------------------------------------------------------------
# Ruido 3D (valor, con interpolación quíntica) y fractal
# ---------------------------------------------------------------------------
_rng = np.random.default_rng(7)
PERM = _rng.permutation(256).astype(np.int32)
PERM = np.concatenate([PERM, PERM])
VALS = _rng.random(256).astype(np.float32)


def _fade(t):
    return t * t * t * (t * (t * 6 - 15) + 10)


def vnoise(x, y, z, seed=0):
    """Ruido de valor 3D en [0,1]. x, y, z: arrays float32 del mismo tamaño."""
    xi = np.floor(x).astype(np.int32)
    yi = np.floor(y).astype(np.int32)
    zi = np.floor(z).astype(np.int32)
    xf, yf, zf = x - xi, y - yi, z - zi
    u, v, w = _fade(xf), _fade(yf), _fade(zf)
    xi = (xi + seed * 31) & 255
    yi = (yi + seed * 17) & 255
    zi = (zi + seed * 7) & 255

    def h(a, b, c):
        return VALS[PERM[PERM[PERM[a] + b] + c] & 255]

    x1 = (xi + 1) & 255
    y1 = (yi + 1) & 255
    z1 = (zi + 1) & 255
    c000 = h(xi, yi, zi)
    c100 = h(x1, yi, zi)
    c010 = h(xi, y1, zi)
    c110 = h(x1, y1, zi)
    c001 = h(xi, yi, z1)
    c101 = h(x1, yi, z1)
    c011 = h(xi, y1, z1)
    c111 = h(x1, y1, z1)
    a = c000 + (c100 - c000) * u
    b = c010 + (c110 - c010) * u
    c = c001 + (c101 - c001) * u
    d = c011 + (c111 - c011) * u
    e = a + (b - a) * v
    f = c + (d - c) * v
    return e + (f - e) * w


def fbm(p, octaves=6, freq=1.0, lac=2.03, gain=0.5, seed=0):
    x, y, z = p
    total = np.zeros_like(x)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        total += amp * vnoise(x * freq, y * freq, z * freq, seed + o * 13)
        norm += amp
        amp *= gain
        freq *= lac
    return total / norm


def ridged(p, octaves=5, freq=1.0, seed=0):
    x, y, z = p
    total = np.zeros_like(x)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        n = vnoise(x * freq, y * freq, z * freq, seed + o * 19)
        total += amp * (1 - np.abs(n * 2 - 1)) ** 2
        norm += amp
        amp *= 0.5
        freq *= 2.1
    return total / norm


def warp(p, amount, freq, seed):
    x, y, z = p
    qx = fbm(p, 3, freq, seed=seed) - 0.5
    qy = fbm(p, 3, freq, seed=seed + 5) - 0.5
    qz = fbm(p, 3, freq, seed=seed + 9) - 0.5
    return (x + qx * amount, y + qy * amount, z + qz * amount)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    t = t[..., None] if np.ndim(t) == np.ndim(a) - 1 else t
    return a + (b - a) * t


def col(*rgb):
    return np.array(rgb, dtype=np.float32) / 255.0


def mix_palette(stops, t):
    """stops: [(pos, col)], t array -> (..., 3)"""
    out = np.zeros(t.shape + (3,), np.float32)
    out[...] = stops[0][1]
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        k = np.clip((t - p0) / max(p1 - p0, 1e-6), 0, 1)
        sel = t >= p0
        out[sel] = (c0 + (c1 - c0) * k[sel][:, None])
    return out


def save(img, name, quality=92):
    OUT.mkdir(parents=True, exist_ok=True)
    arr = np.clip(img * 255 + 0.5, 0, 255).astype(np.uint8)
    path = OUT / name
    if name.endswith(".jpg"):
        Image.fromarray(arr).save(path, quality=quality, optimize=True, subsampling=0)
    else:
        Image.fromarray(arr).save(path, optimize=True)
    print("  ✓", path.relative_to(ROOT), arr.shape[1], "x", arr.shape[0])
    return path


# ---------------------------------------------------------------------------
# Direcciones de las caras del Sky y de la esfera
# ---------------------------------------------------------------------------
FACES = {
    # nombre: (dirección del centro, derecha de la imagen, arriba de la imagen)
    "ft": ((0, 0, -1), (1, 0, 0), (0, 1, 0)),
    "bk": ((0, 0, 1), (-1, 0, 0), (0, 1, 0)),
    "lf": ((-1, 0, 0), (0, 0, -1), (0, 1, 0)),
    "rt": ((1, 0, 0), (0, 0, 1), (0, 1, 0)),
    "up": ((0, 1, 0), (1, 0, 0), (0, 0, 1)),
    "dn": ((0, -1, 0), (1, 0, 0), (0, 0, -1)),
}
FACE_FLIP = {}  # p. ej. {"up": "rot90"} si hiciera falta


def face_dirs(name, n=SKY):
    c, r, u = (np.array(v, np.float32) for v in FACES[name])
    s = (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1
    xs, ys = np.meshgrid(s, -s)
    d = c[None, None] + xs[..., None] * r[None, None] + ys[..., None] * u[None, None]
    d /= np.linalg.norm(d, axis=-1, keepdims=True)
    return d


def sphere_dirs(w=PLANET_W, h=PLANET_H):
    lon = ((np.arange(w, dtype=np.float32) + 0.5) / w) * 2 * np.pi - np.pi
    lat = np.pi / 2 - ((np.arange(h, dtype=np.float32) + 0.5) / h) * np.pi
    lon, lat = np.meshgrid(lon, lat)
    x = np.cos(lat) * np.sin(lon)
    y = np.sin(lat)
    z = np.cos(lat) * np.cos(lon)
    return np.stack([x, y, z], -1).astype(np.float32), lat


# ---------------------------------------------------------------------------
# Estrellas (puntos repartidos en la esfera: sin costuras entre caras)
# ---------------------------------------------------------------------------
def star_list(count, seed, band_axis=None, band_boost=0.0):
    r = np.random.default_rng(seed)
    v = r.normal(size=(count * 2, 3)).astype(np.float32)
    v /= np.linalg.norm(v, axis=1, keepdims=True)
    if band_axis is not None:
        a = np.array(band_axis, np.float32)
        a /= np.linalg.norm(a)
        keep = r.random(len(v)) < (1 - band_boost) + band_boost * np.exp(-((v @ a) ** 2) / 0.02)
        v = v[keep]
    v = v[:count]
    mag = r.pareto(2.2, len(v)).astype(np.float32)
    temp = r.random(len(v)).astype(np.float32)
    return v, mag, temp


def splat_stars(img, dirs_face, name, stars, scale=1.0):
    c, rr, uu = (np.array(x, np.float32) for x in FACES[name])
    v, mag, temp = stars
    dc = v @ c
    sel = dc > 0.05
    v, mag, temp, dc = v[sel], mag[sel], temp[sel], dc[sel]
    px = (v @ rr) / dc
    py = (v @ uu) / dc
    inside = (np.abs(px) < 1.02) & (np.abs(py) < 1.02)
    v, mag, temp, px, py = v[inside], mag[inside], temp[inside], px[inside], py[inside]
    n = img.shape[0]
    fx = (px + 1) / 2 * n - 0.5
    fy = (1 - (py + 1) / 2) * n - 0.5
    tints = np.stack([
        np.interp(temp, [0, 0.3, 0.6, 1], [0.65, 0.85, 1.0, 1.0]),
        np.interp(temp, [0, 0.3, 0.6, 1], [0.78, 0.9, 0.98, 0.82]),
        np.interp(temp, [0, 0.3, 0.6, 1], [1.0, 1.0, 0.93, 0.62]),
    ], -1)
    for x, y, m, t in zip(fx, fy, mag, tints):
        b = min(1.6, 0.18 + m * 0.22) * scale
        rad = 1 if b < 0.6 else (2 if b < 1.1 else 3)
        x0, y0 = int(round(x)), int(round(y))
        for dy in range(-rad, rad + 1):
            for dx in range(-rad, rad + 1):
                xx, yy = x0 + dx, y0 + dy
                if 0 <= xx < n and 0 <= yy < n:
                    d2 = (xx - x) ** 2 + (yy - y) ** 2
                    k = b * math.exp(-d2 / (0.35 + 0.25 * rad))
                    img[yy, xx] += t * k
        if b > 1.2:  # destello en cruz de las más brillantes
            for d in range(-9, 10):
                k = b * 0.12 * math.exp(-abs(d) / 3.2)
                for xx, yy in ((x0 + d, y0), (x0, y0 + d)):
                    if 0 <= xx < n and 0 <= yy < n:
                        img[yy, xx] += t * k


# ---------------------------------------------------------------------------
# Cielo del espacio
# ---------------------------------------------------------------------------
GALAXY_AXIS = np.array([0.32, 0.86, 0.4], np.float32)
GALAXY_AXIS /= np.linalg.norm(GALAXY_AXIS)


def space_color(d):
    p = (d[..., 0] * 2.2, d[..., 1] * 2.2, d[..., 2] * 2.2)
    q = warp(p, 1.4, 1.1, 3)
    neb = fbm(q, 7, 1.6, seed=11)
    neb2 = fbm(q, 6, 2.7, seed=23)
    dust = fbm(p, 6, 4.0, seed=41)
    gal = np.abs(d @ GALAXY_AXIS)
    band = np.exp(-(gal ** 2) / 0.05)
    band_core = np.exp(-(gal ** 2) / 0.012)
    # Polvo oscuro a lo largo de la banda (grietas oscuras de la Vía Láctea)
    lanes = smooth(0.5, 0.75, fbm(p, 6, 3.0, seed=57)) * band * 0.7
    img = np.zeros(d.shape, np.float32)
    img += col(4, 5, 12)
    # Nebulosa de emisión (magenta y azul) en dos zonas, tenue fuera
    a = smooth(0.52, 0.8, neb) * (0.35 + 0.65 * smooth(0.3, 0.7, neb2))
    focus1 = np.clip(d @ np.array([0.7, 0.2, -0.68], np.float32), 0, 1) ** 2.2
    focus2 = np.clip(d @ np.array([-0.55, -0.1, 0.83], np.float32), 0, 1) ** 2.6
    img += a[..., None] * (focus1[..., None] * col(150, 50, 140) + focus2[..., None] * col(40, 100, 170)) * 0.75
    img += (smooth(0.62, 0.9, neb2) * focus1)[..., None] * col(255, 120, 90) * 0.18
    img += (smooth(0.6, 0.85, neb) * focus2)[..., None] * col(90, 200, 230) * 0.16
    # Vía Láctea
    milky = band * (0.25 + 0.75 * dust) * (1 - 0.8 * lanes)
    img += milky[..., None] * col(120, 112, 128) * 0.42
    img += (band_core * (0.4 + 0.6 * dust) * (1 - lanes))[..., None] * col(220, 196, 170) * 0.22
    # (cerca del cenit y del nadir, oscuro: si las caras Up/Dn van giradas no se nota la costura)
    pole = np.abs(d[..., 1])
    img *= (1 - 0.55 * smooth(0.8, 1.0, pole))[..., None]
    return img


def gen_space_sky():
    stars = star_list(16000, 101, GALAXY_AXIS, 0.55)
    for name in FACES:
        d = face_dirs(name)
        img = space_color(d)
        splat_stars(img, d, name, stars)
        img = 1 - np.exp(-img * 1.25)  # tono suave (sin quemar)
        save(img, f"cielo_espacio_{name}.jpg", 93)


# ---------------------------------------------------------------------------
# Cielo de Lontana (malva, la luna Ovilla, humo en el horizonte)
# ---------------------------------------------------------------------------
OVILLA_DIR = np.array([0.55, 0.42, -0.72], np.float32)
OVILLA_DIR /= np.linalg.norm(OVILLA_DIR)
OVILLA_RAD = math.radians(11)


def lontana_sky_color(d):
    y = d[..., 1]
    img = mix_palette([
        (-1.0, col(70, 58, 72)),
        (-0.05, col(150, 126, 140)),
        (0.0, col(226, 196, 206)),
        (0.08, col(206, 170, 196)),
        (0.3, col(160, 128, 178)),
        (0.7, col(104, 82, 142)),
        (1.0, col(80, 62, 120)),
    ], y)
    p = (d[..., 0] * 3, d[..., 1] * 3, d[..., 2] * 3)
    # Nubes altas, finas (estiradas en horizontal)
    q = (d[..., 0] * 2.2, d[..., 1] * 7.0, d[..., 2] * 2.2)
    cl = fbm(warp(q, 0.8, 1.3, 5), 6, 1.5, seed=71)
    cloud = smooth(0.5, 0.75, cl) * smooth(0.02, 0.18, y) * (1 - smooth(0.55, 0.9, y))
    img = img * (1 - 0.5 * cloud[..., None]) + cloud[..., None] * col(240, 214, 222) * 0.5
    # Humo de la guerra: columnas oscuras en el horizonte
    az = np.arctan2(d[..., 0], -d[..., 2])
    plumes = np.zeros_like(y)
    for a0, w, hgt in ((0.9, 0.05, 0.22), (2.4, 0.08, 0.3), (-1.7, 0.04, 0.16), (-2.8, 0.06, 0.2)):
        da = np.angle(np.exp(1j * (az - a0 - y * 0.6)))
        sway = fbm(p, 4, 2.5, seed=91) - 0.5
        plumes = np.maximum(plumes, np.exp(-((da + sway * 0.12) ** 2) / (w * (1 + y * 3)) ** 2) * smooth(hgt, -0.02, y) * smooth(-0.03, 0.02, y))
    smoke = plumes * (0.55 + 0.45 * fbm(p, 5, 4.0, seed=93))
    img = img * (1 - 0.6 * smoke[..., None]) + smoke[..., None] * col(70, 60, 66) * 0.6
    # Ovilla
    cosang = d @ OVILLA_DIR
    ang = np.arccos(np.clip(cosang, -1, 1))
    disc = ang < OVILLA_RAD
    if disc.any():
        # coordenadas sobre el disco para el relieve
        rr = np.clip(ang / OVILLA_RAD, 0, 1)
        mp = (d[..., 0] * 40, d[..., 1] * 40, d[..., 2] * 40)
        mare = fbm(mp, 5, 0.25, seed=101)
        crat = ridged(mp, 4, 0.7, seed=103)
        shade = np.sqrt(np.clip(1 - rr ** 2, 0, 1))
        light = np.clip(0.35 + 0.75 * shade - 0.25 * rr, 0, 1)
        moon = mix_palette([(0, col(120, 128, 150)), (0.5, col(186, 188, 204)), (1, col(226, 222, 232))], mare * 0.8 + crat * 0.35)
        moon *= light[..., None]
        # fogonazos de la guerra en la luna (puntos naranjas)
        flash = smooth(0.86, 0.93, fbm(mp, 3, 2.2, seed=107)) * 0.9
        moon += flash[..., None] * col(255, 150, 70)
        edge = smooth(1.0, 0.97, rr)
        img[disc] = img[disc] * (1 - edge[disc, None]) + moon[disc] * edge[disc, None]
    halo = np.exp(-np.clip(ang - OVILLA_RAD, 0, None) / 0.08) * 0.22
    img += halo[..., None] * col(230, 220, 240)
    # Ceniza: suelo de abajo (por si se ve el horizonte bajo)
    img = np.clip(img, 0, 1)
    return img


def gen_lontana_sky():
    for name in FACES:
        d = face_dirs(name)
        save(lontana_sky_color(d), f"cielo_lontana_{name}.jpg", 92)


# ---------------------------------------------------------------------------
# Planetas (equirrectangular)
# ---------------------------------------------------------------------------
def planet_lontana(d, lat):
    p = (d[..., 0] * 1.6, d[..., 1] * 1.6, d[..., 2] * 1.6)
    e = fbm(warp(p, 0.6, 1.2, 1), 7, 1.0, seed=201)
    detail = fbm(p, 6, 6.0, seed=203)
    sea = e < 0.47
    land = mix_palette([
        (0.47, col(132, 116, 120)),
        (0.53, col(166, 140, 150)),
        (0.62, col(188, 160, 176)),
        (0.72, col(150, 130, 156)),
        (0.85, col(206, 196, 210)),
    ], e + (detail - 0.5) * 0.06)
    water = mix_palette([(0.25, col(42, 48, 86)), (0.44, col(76, 86, 132)), (0.47, col(110, 120, 160))], e)
    img = np.where(sea[..., None], water, land)
    # ceniza gris (manchas grandes) y cicatrices quemadas de la guerra
    ash = smooth(0.55, 0.75, fbm(p, 5, 2.3, seed=207))
    img = img * (1 - 0.45 * ash[..., None]) + ash[..., None] * col(150, 146, 150) * 0.45
    scar = smooth(0.78, 0.9, ridged(p, 5, 2.0, seed=209)) * (~sea)
    img *= (1 - 0.55 * scar)[..., None]
    img += (scar * smooth(0.88, 0.95, detail))[..., None] * col(255, 120, 60) * 0.25
    # casquetes
    pole = smooth(1.15, 1.42, np.abs(lat) + (detail - 0.5) * 0.3)
    img = img * (1 - pole[..., None]) + pole[..., None] * col(222, 218, 230)
    return img


def planet_ocrea(d, lat):
    p = (d[..., 0] * 1.8, d[..., 1] * 1.8, d[..., 2] * 1.8)
    e = fbm(warp(p, 0.7, 1.0, 2), 7, 1.2, seed=301)
    canyon = smooth(0.82, 0.95, ridged(warp(p, 0.4, 2.0, 3), 6, 1.6, seed=303))
    strata = 0.5 + 0.5 * np.sin((e * 22 + fbm(p, 3, 3, seed=305) * 4))
    img = mix_palette([(0.2, col(110, 40, 26)), (0.45, col(176, 76, 40)), (0.6, col(214, 120, 60)), (0.8, col(232, 170, 104))], e)
    img *= (0.85 + 0.15 * strata)[..., None]
    img *= (1 - 0.6 * canyon)[..., None]
    img += canyon[..., None] * col(60, 20, 14) * 0.3
    dunes = smooth(0.6, 0.8, fbm(p, 4, 8, seed=307))
    img += dunes[..., None] * col(40, 26, 10) * 0.15
    return img


def planet_marena(d, lat):
    p = (d[..., 0] * 1.5, d[..., 1] * 1.5, d[..., 2] * 1.5)
    e = fbm(warp(p, 0.5, 1.4, 4), 7, 1.1, seed=401)
    reef = smooth(0.56, 0.62, e)
    island = e > 0.68
    img = mix_palette([(0.2, col(8, 46, 82)), (0.45, col(14, 92, 128)), (0.56, col(30, 150, 160)), (0.64, col(80, 210, 196))], e)
    reefc = fbm(p, 5, 9, seed=403)
    img += (reef * smooth(0.5, 0.7, reefc))[..., None] * col(220, 120, 160) * 0.25
    img = np.where(island[..., None], mix_palette([(0.68, col(214, 204, 160)), (0.75, col(90, 150, 90))], e), img)
    # plaga de coral negro que se extiende
    plague = smooth(0.62, 0.72, fbm(warp(p, 0.9, 2.0, 6), 6, 1.8, seed=405)) * smooth(0.5, 0.58, e)
    img *= (1 - 0.82 * plague)[..., None]
    img += plague[..., None] * col(30, 10, 40) * 0.2
    return img


def planet_velaria(d, lat):
    p = (d[..., 0] * 1.7, d[..., 1] * 1.7, d[..., 2] * 1.7)
    e = fbm(warp(p, 0.6, 1.3, 7), 7, 1.1, seed=501)
    img = mix_palette([(0.3, col(10, 16, 34)), (0.48, col(30, 44, 78)), (0.6, col(120, 150, 190)), (0.75, col(214, 232, 250))], e)
    lakes = smooth(0.42, 0.38, e)
    img = img * (1 - lakes[..., None]) + lakes[..., None] * col(40, 90, 120)
    glow = smooth(0.7, 0.9, fbm(p, 5, 7, seed=503)) * smooth(0.55, 0.7, e)
    img += glow[..., None] * col(150, 230, 255) * 0.35
    cracks = smooth(0.88, 0.96, ridged(p, 5, 3.0, seed=505))
    img *= (1 - 0.4 * cracks)[..., None]
    return img


def planet_fronda(d, lat):
    p = (d[..., 0] * 1.6, d[..., 1] * 1.6, d[..., 2] * 1.6)
    e = fbm(warp(p, 0.6, 1.2, 8), 7, 1.0, seed=601)
    canopy = fbm(p, 6, 10, seed=603)
    img = mix_palette([(0.3, col(14, 60, 40)), (0.45, col(30, 96, 44)), (0.6, col(70, 132, 50)), (0.75, col(150, 160, 70))], e * 0.8 + canopy * 0.2)
    rivers = smooth(0.93, 0.98, ridged(warp(p, 0.3, 2.0, 9), 5, 1.8, seed=605))
    img = img * (1 - rivers[..., None]) + rivers[..., None] * col(40, 90, 110)
    burnt = smooth(0.7, 0.8, fbm(p, 5, 2.2, seed=607))
    img = img * (1 - 0.75 * burnt[..., None]) + burnt[..., None] * col(90, 74, 60) * 0.75
    pollen = smooth(0.6, 0.85, fbm(p, 4, 3, seed=609))
    img += pollen[..., None] * col(220, 190, 80) * 0.12
    return img


def planet_zefira(d, lat):
    p = (d[..., 0] * 2.0, d[..., 1] * 2.0, d[..., 2] * 2.0)
    turb = fbm(warp(p, 0.5, 2.4, 10), 6, 2.0, seed=701)
    y = d[..., 1] + (turb - 0.5) * 0.16
    bands = 0.5 + 0.5 * np.sin(y * 18 + np.sin(y * 7) * 2)
    t = (y + 1) / 2
    base = mix_palette([(0.0, col(230, 120, 50)), (0.35, col(240, 170, 100)), (0.55, col(200, 120, 170)), (0.8, col(130, 70, 190)), (1.0, col(80, 40, 140))], t)
    img = base * (0.75 + 0.35 * bands)[..., None]
    # tormentas (óvalos) con rayos
    for cdir, s in (((0.6, -0.25, 0.76), 0.012), ((-0.8, 0.3, -0.5), 0.006), ((0.1, 0.5, -0.86), 0.004)):
        c = np.array(cdir, np.float32)
        c /= np.linalg.norm(c)
        dd = 1 - d @ c
        spot = np.exp(-dd / s) * (0.7 + 0.3 * turb)
        img = img * (1 - 0.6 * spot[..., None]) + spot[..., None] * col(250, 230, 220) * 0.6
    return np.clip(img, 0, 1)


def planet_mercadia(d, lat):
    p = (d[..., 0], d[..., 1], d[..., 2])
    # rejilla de barrios: celdas en lat/long
    lon = np.arctan2(d[..., 0], d[..., 2])
    gx = lon / np.pi * 48
    gy = lat / (np.pi / 2) * 24
    fx, fy = gx - np.floor(gx), gy - np.floor(gy)
    street = (np.minimum(fx, 1 - fx) < 0.06) | (np.minimum(fy, 1 - fy) < 0.06)
    cell = vnoise(np.floor(gx) * 1.0, np.floor(gy) * 1.0, np.zeros_like(gx), 801)
    base = mix_palette([(0.0, col(200, 204, 214)), (0.4, col(232, 234, 240)), (0.7, col(170, 176, 196)), (1.0, col(250, 240, 220))], cell)
    neon = smooth(0.8, 0.9, cell)
    hue = vnoise(np.floor(gx) * 2.0, np.floor(gy) * 2.0, np.ones_like(gx), 803)
    neonc = mix_palette([(0, col(255, 80, 160)), (0.5, col(80, 220, 255)), (1, col(255, 220, 60))], hue)
    img = base * (1 - neon[..., None]) + neonc * neon[..., None]
    img = np.where(street[..., None], col(120, 124, 140) * (0.9 + 0.2 * fbm(p, 3, 20, seed=805))[..., None], img)
    parks = smooth(0.72, 0.8, fbm(p, 4, 3, seed=807))
    img = img * (1 - parks[..., None] * 0.6) + parks[..., None] * col(120, 200, 140) * 0.6
    return np.clip(img, 0, 1)


PLANETS = {
    "lontana": planet_lontana,
    "ocrea": planet_ocrea,
    "marena": planet_marena,
    "velaria": planet_velaria,
    "fronda": planet_fronda,
    "zefira": planet_zefira,
    "mercadia": planet_mercadia,
}

CLOUDS = {
    "lontana": (col(236, 226, 232), 0.52, 211),
    "marena": (col(250, 252, 255), 0.5, 411),
    "fronda": (col(250, 240, 210), 0.56, 611),
}


def gen_planets():
    d, lat = sphere_dirs()
    for pid, fn in PLANETS.items():
        save(fn(d, lat), f"planeta_{pid}.jpg", 92)
    for pid, (c, thr, seed) in CLOUDS.items():
        p = (d[..., 0] * 2.0, d[..., 1] * 2.0, d[..., 2] * 2.0)
        q = warp(p, 1.0, 1.4, seed)
        n = fbm(q, 7, 1.4, seed=seed)
        a = smooth(thr, thr + 0.18, n) * 0.92
        rgba = np.zeros(d.shape[:2] + (4,), np.float32)
        rgba[..., :3] = c * (0.85 + 0.15 * fbm(p, 4, 6, seed=seed + 2))[..., None]
        rgba[..., 3] = a
        save(rgba, f"nubes_{pid}.png")


def gen_halo():
    n = 512
    s = (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(s, s)
    r = np.sqrt(x * x + y * y)
    core = 0.8  # radio del planeta dentro de la imagen (el juego lo dibuja así: Planet.HaloScale)
    rim = np.exp(-np.abs(r - core) / 0.035) * (r > core * 0.92)
    glow = np.exp(-np.clip(r - core, 0, None) / 0.07) * (r >= core)
    inner = smooth(core * 0.75, core, r) * (r < core) * 0.35
    a = np.clip(rim * 0.9 + glow * 0.7 + inner, 0, 1) * (r < 1)
    rgba = np.ones((n, n, 4), np.float32)
    rgba[..., 3] = a
    save(rgba, "halo_atmosfera.png")


# ---------------------------------------------------------------------------
# Chapa de la nave y roca de Lontana (enlosables)
# ---------------------------------------------------------------------------
def _pvnoise(n, period, seed):
    """Ruido de valor 2D PERIÓDICO (enlosable): la rejilla da la vuelta cada `period` celdas."""
    r = np.random.default_rng(seed)
    grid = r.random((period, period)).astype(np.float32)
    t = (np.arange(n, dtype=np.float32) + 0.5) / n * period
    i0 = np.floor(t).astype(int)
    f = _fade(t - i0)
    i0 %= period
    i1 = (i0 + 1) % period
    a = grid[np.ix_(i0, i0)]
    b = grid[np.ix_(i0, i1)]
    c = grid[np.ix_(i1, i0)]
    d = grid[np.ix_(i1, i1)]
    fy, fx = f[:, None], f[None, :]
    return (a + (b - a) * fx) + ((c + (d - c) * fx) - (a + (b - a) * fx)) * fy


def tile_noise(n, freq, octaves, seed):
    """Fractal enlosable (cada octava con un número entero de celdas por baldosa)."""
    total = np.zeros((n, n), np.float32)
    amp, norm = 1.0, 0.0
    period = max(2, int(round(freq * 4)))
    for o in range(octaves):
        total += amp * _pvnoise(n, period, seed + o * 101)
        norm += amp
        amp *= 0.5
        period *= 2
    return total / norm


def normal_from_height(h, strength):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    nx, ny, nz = -dx * strength, dy * strength, np.ones_like(h)
    l = np.sqrt(nx * nx + ny * ny + nz * nz)
    return np.stack([nx / l, ny / l, nz / l], -1) * 0.5 + 0.5


def gen_hull():
    n = 1024
    rng = np.random.default_rng(909)
    height = np.zeros((n, n), np.float32)
    panel_id = np.zeros((n, n), np.float32)
    grooves = np.zeros((n, n), np.float32)
    rivets = np.zeros((n, n), np.float32)
    rects = []

    def split(x0, y0, w, h, depth):
        if depth >= 4 or (depth >= 2 and rng.random() < 0.3) or min(w, h) < 96:
            rects.append((x0, y0, w, h))
            return
        if w >= h:
            cut = int(w * rng.uniform(0.3, 0.7))
            split(x0, y0, cut, h, depth + 1)
            split(x0 + cut, y0, w - cut, h, depth + 1)
        else:
            cut = int(h * rng.uniform(0.3, 0.7))
            split(x0, y0, w, cut, depth + 1)
            split(x0, y0 + cut, w, h - cut, depth + 1)

    split(0, 0, n, n, 0)
    yy, xx = np.mgrid[0:n, 0:n]
    for i, (x0, y0, w, h) in enumerate(rects):
        sl = (slice(y0, y0 + h), slice(x0, x0 + w))
        panel_id[sl] = rng.random()
        lx = xx[sl] - x0
        ly = yy[sl] - y0
        edge = np.minimum(np.minimum(lx, w - 1 - lx), np.minimum(ly, h - 1 - ly)).astype(np.float32)
        grooves[sl] = np.maximum(grooves[sl], np.exp(-edge / 1.6))
        # bisel suave del panel y un poco de abombado
        height[sl] = smooth(0, 10, edge) * 0.6 + rng.uniform(-0.05, 0.05)
        # remaches a lo largo del borde, cada 26 px
        step = 26
        for t in range(step // 2, w, step):
            for cy in (y0 + 7, y0 + h - 8):
                cx = x0 + t
                y1, y2, x1, x2 = max(cy - 4, 0), min(cy + 5, n), max(cx - 4, 0), min(cx + 5, n)
                d2 = (xx[y1:y2, x1:x2] - cx) ** 2 + (yy[y1:y2, x1:x2] - cy) ** 2
                rivets[y1:y2, x1:x2] = np.maximum(rivets[y1:y2, x1:x2], np.clip(1 - d2 / 9.0, 0, 1))
        # algunos paneles con rejilla de ventilación
        if rng.random() < 0.08 and w > 140 and h > 120:
            gx0, gy0 = x0 + w // 4, y0 + h // 3
            for k in range(6):
                yk = gy0 + k * 9
                if yk + 4 < y0 + h:
                    height[yk:yk + 4, gx0:gx0 + w // 2] -= 0.5
    wear = tile_noise(n, 2.0, 6, 911)
    scratch = tile_noise(n, 9.0, 3, 913)
    grime = smooth(0.4, 1.0, grooves) * (0.6 + 0.4 * wear)
    height = height - grooves * 0.9 + rivets * 0.5 + (wear - 0.5) * 0.08
    base = 0.80 + (panel_id - 0.5) * 0.08 + (wear - 0.5) * 0.08
    color = np.stack([base, base * 0.995, base * 1.01], -1)
    color *= (1 - 0.45 * grime)[..., None]
    streak = smooth(0.62, 0.8, tile_noise(n, 1.4, 4, 915)) * 0.08
    color -= streak[..., None]
    color = np.clip(color, 0, 1)
    rough = np.clip(0.38 + (wear - 0.5) * 0.25 + grime * 0.35 + smooth(0.75, 0.85, scratch) * -0.12 + panel_id * 0.08, 0, 1)
    metal = np.clip(0.82 - grime * 0.35 + (panel_id - 0.5) * 0.12, 0, 1)
    save(color, "nave_casco_color.png")
    save(normal_from_height(height, 3.0), "nave_casco_normal.png")
    save(np.repeat(rough[..., None], 3, -1), "nave_casco_roughness.png")
    save(np.repeat(metal[..., None], 3, -1), "nave_casco_metalness.png")


def gen_rock():
    n = 1024
    h1 = tile_noise(n, 1.5, 7, 951)
    cr = tile_noise(n, 3.5, 5, 953)
    ridges = 1 - np.abs(tile_noise(n, 2.5, 6, 955) - 0.5) * 2
    crack = smooth(0.9, 0.98, ridges) * smooth(0.45, 0.6, tile_noise(n, 1.0, 3, 956))
    pores = smooth(0.72, 0.8, tile_noise(n, 16, 3, 957))
    height = h1 * 1.0 - crack * 0.6 - pores * 0.15 + tile_noise(n, 12, 4, 959) * 0.25
    ash = smooth(0.55, 0.75, h1 + (tile_noise(n, 6, 4, 961) - 0.5) * 0.3)
    base = 0.62 + (h1 - 0.5) * 0.3
    color = np.stack([base * 1.0, base * 0.95, base * 1.02], -1)
    color *= (1 - 0.5 * crack)[..., None]
    color = color * (1 - ash[..., None] * 0.6) + ash[..., None] * np.array([0.86, 0.84, 0.86], np.float32) * 0.6
    rough = np.clip(0.82 + crack * 0.1 - (1 - ash) * 0.08 + (pores - 0.5) * 0.05, 0, 1)
    save(np.clip(color + (cr[..., None] - 0.5) * 0.04, 0, 1), "roca_lontana_color.png")
    save(normal_from_height(height, 6.0), "roca_lontana_normal.png")
    save(np.repeat(rough[..., None], 3, -1), "roca_lontana_roughness.png")


# ---------------------------------------------------------------------------
# Vistas previas (docs/planetas/)
# ---------------------------------------------------------------------------
def render_sphere(albedo, clouds=None, size=300, light=(-0.55, 0.45, 0.7), halo=(1, 1, 1), spin=0.0):
    s = (np.arange(size, dtype=np.float32) + 0.5) / size * 2 - 1
    x, y = np.meshgrid(s, -s)
    r2 = x * x + y * y
    inside = r2 < 1
    z = np.sqrt(np.clip(1 - r2, 0, 1))
    lon = np.arctan2(x, z) + spin
    lat = np.arcsin(np.clip(y, -1, 1))
    H, W = albedo.shape[:2]
    u = ((lon + np.pi) / (2 * np.pi) % 1 * W).astype(int) % W
    v = np.clip(((np.pi / 2 - lat) / np.pi * H).astype(int), 0, H - 1)
    alb = albedo[v, u]
    if clouds is not None:
        ca = clouds[v, u, 3:4]
        alb = alb * (1 - ca) + clouds[v, u, :3] * ca
    L = np.array(light, np.float32)
    L /= np.linalg.norm(L)
    ndl = np.clip(x * L[0] + y * L[1] + z * L[2], 0, 1)
    shade = 0.05 + 0.95 * ndl
    img = alb * shade[..., None]
    rim = np.exp(-np.clip(np.sqrt(r2) - 1, 0, None) / 0.035) * (np.sqrt(r2) > 0.9)
    rimc = np.array(halo, np.float32)
    out = np.zeros((size, size, 3), np.float32)
    out[inside] = img[inside]
    out += (rim * (0.35 + 0.65 * np.clip((x * L[0] + y * L[1]) * 0.7 + 0.5, 0, 1)))[..., None] * rimc * 0.8
    return np.clip(out, 0, 1)


def load(name):
    return np.asarray(Image.open(OUT / name), np.float32) / 255.0


HALO_COLORS = {
    "lontana": (1.0, 0.72, 0.88),
    "ocrea": (1.0, 0.55, 0.3),
    "marena": (0.4, 0.95, 0.95),
    "velaria": (0.7, 0.85, 1.0),
    "fronda": (0.6, 1.0, 0.55),
    "zefira": (0.9, 0.6, 1.0),
    "mercadia": (1.0, 0.92, 0.5),
}


def gen_previews():
    DOCS.mkdir(parents=True, exist_ok=True)
    tiles = []
    for pid in PLANETS:
        alb = load(f"planeta_{pid}.jpg")
        cl = load(f"nubes_{pid}.png") if pid in CLOUDS else None
        tiles.append(render_sphere(alb, cl, 300, halo=HALO_COLORS[pid], spin=0.6))
    pad = 20
    sheet = np.zeros((300 + pad * 2, (300 + pad) * len(tiles) + pad, 3), np.float32)
    sheet[...] = col(6, 7, 14)
    for i, t in enumerate(tiles):
        x0 = pad + i * (300 + pad)
        sheet[pad:pad + 300, x0:x0 + 300] = np.maximum(sheet[pad:pad + 300, x0:x0 + 300], t)
    Image.fromarray((sheet * 255).astype(np.uint8)).save(DOCS / "planetas.jpg", quality=90)
    print("  ✓ docs/planetas/planetas.jpg")
    # Cielos: cruz desplegada a 256 por cara
    for sky in ("espacio", "lontana"):
        f = 256
        cross = np.zeros((f * 3, f * 4, 3), np.float32)
        place = {"up": (0, 1), "lf": (1, 0), "ft": (1, 1), "rt": (1, 2), "bk": (1, 3), "dn": (2, 1)}
        for name, (r, c) in place.items():
            img = Image.open(OUT / f"cielo_{sky}_{name}.jpg").resize((f, f), Image.LANCZOS)
            cross[r * f:(r + 1) * f, c * f:(c + 1) * f] = np.asarray(img, np.float32) / 255
        Image.fromarray((cross * 255).astype(np.uint8)).save(DOCS / f"cielo-{sky}.jpg", quality=88)
        print(f"  ✓ docs/planetas/cielo-{sky}.jpg")
    # Texturas de la nave y de la roca, con luz rasante
    out = []
    for prefix in ("nave_casco", "roca_lontana"):
        c = np.asarray(Image.open(OUT / f"{prefix}_color.png").resize((384, 384), Image.LANCZOS), np.float32) / 255
        nrm = np.asarray(Image.open(OUT / f"{prefix}_normal.png").resize((384, 384), Image.LANCZOS), np.float32) / 255 * 2 - 1
        L = np.array([-0.6, 0.5, 0.62], np.float32)
        L /= np.linalg.norm(L)
        lit = c * (0.25 + 0.95 * np.clip(nrm @ L, 0, 1))[..., None]
        out.append(np.clip(c, 0, 1))
        out.append(np.clip(lit, 0, 1))
    row = np.concatenate([np.pad(t, ((8, 8), (8, 8), (0, 0))) for t in out], 1)
    Image.fromarray((row * 255).astype(np.uint8)).save(DOCS / "texturas-nave-roca.jpg", quality=88)
    print("  ✓ docs/planetas/texturas-nave-roca.jpg")


JOBS = {
    "cielo_espacio": gen_space_sky,
    "cielo_lontana": gen_lontana_sky,
    "planetas": gen_planets,
    "halo": gen_halo,
    "nave": gen_hull,
    "roca": gen_rock,
}

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    for key, fn in JOBS.items():
        if not args or any(key.startswith(a) or a.startswith(key) for a in args):
            print("·", key)
            fn()
    if "--preview" in sys.argv:
        gen_previews()
