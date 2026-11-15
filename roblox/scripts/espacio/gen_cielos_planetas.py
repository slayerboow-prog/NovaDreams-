"""Cielos propios de los seis planetas (la hoja de estética del dueño): cada uno con su color y un planeta
gigante, lunas o soles al fondo. Salen en assets/espacio/cielo_<nombre de archivo>_{ft,bk,lf,rt,up,dn}.jpg
(con el nombre viejo del planeta: shared/Cosmos/EspacioLook.FileAlias) y una vista previa en
docs/planetas/cielos-planetas.jpg.

Uso (desde roblox/):   python -I scripts/espacio/gen_cielos_planetas.py            (los seis)
                       python -I scripts/espacio/gen_cielos_planetas.py siroco     (solo uno)
Después:               bash scripts/upload-espacio.sh   (sube los que no tienen id)

Las caras siguen la convención comprobada en Studio (gen.py FACES; EspacioLook.SkyFaces cruza lf/rt).
Todo sale de código (ruido fractal): sin problemas de derechos.
"""

from __future__ import annotations

import importlib.util
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("gen_espacio", HERE / "gen.py")
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)

col, fbm, warp, smooth, mix_palette = G.col, G.fbm, G.warp, G.smooth, G.mix_palette
FACES, face_dirs = G.FACES, G.face_dirs


def unit(*v):
    a = np.array(v, np.float32)
    return a / np.linalg.norm(a)


# ---------------------------------------------------------------------------
# Piezas del cielo
# ---------------------------------------------------------------------------
def sky_gradient(d, stops):
    return mix_palette(stops, d[..., 1])


def add_sun(img, d, sdir, color, size, glow, strength=1.0):
    c = np.clip(d @ sdir, -1, 1)
    ang = np.arccos(c)
    disc = smooth(size * 1.05, size * 0.9, ang)
    halo = np.exp(-ang / glow) * 0.55 + np.exp(-ang / (glow * 4)) * 0.18
    img += (disc[..., None] * 1.6 + halo[..., None]) * color * strength
    return img


def add_clouds(img, d, color, amount, seed, low=0.0, high=0.55, stretch=6.0, shadow=None):
    y = d[..., 1]
    q = (d[..., 0] * 2.0, d[..., 1] * stretch, d[..., 2] * 2.0)
    n = fbm(warp(q, 0.9, 1.2, seed), 6, 1.6, seed=seed + 3)
    k = smooth(1 - amount, 1 - amount + 0.25, n) * smooth(low, low + 0.08, y) * (1 - smooth(high * 0.7, high, y))
    base = shadow if shadow is not None else color * 0.6
    tone = base + (color - base) * smooth(0.4, 0.9, n)[..., None]
    return img * (1 - 0.85 * k[..., None]) + tone * k[..., None] * 0.85


def add_horizon_haze(img, d, color, width=0.12, strength=0.7):
    y = d[..., 1]
    h = np.exp(-np.abs(y) / width) * strength
    return img * (1 - h[..., None]) + color * h[..., None]


def add_stars(img, d, name, count, seed, scale=0.8, fade_low=0.05):
    stars = G.star_list(count, seed)
    layer = np.zeros_like(img)
    G.splat_stars(layer, d, name, stars, scale)
    vis = smooth(fade_low, fade_low + 0.3, d[..., 1])
    img += layer * vis[..., None]
    return img


def add_aurora(img, d, colors, seed):
    az = np.arctan2(d[..., 0], -d[..., 2])
    y = d[..., 1]
    out = img
    for i, (a0, c) in enumerate(zip((0.4, -1.1, 2.3), colors)):
        wave = np.sin(az * 3 + a0 * 2 + i) * 0.06 + fbm((d[..., 0] * 3, d[..., 2] * 3, np.full_like(y, i * 1.7)), 4, 1.0, seed=seed + i) * 0.12
        base = 0.28 + i * 0.07 + wave
        curtain = np.exp(-((y - base) ** 2) / 0.0035) * 0.5 + smooth(base - 0.02, base + 0.18, y) * smooth(base + 0.32, base + 0.06, y) * 0.55
        streak = 0.45 + 0.55 * fbm((az * 9, y * 2, np.full_like(y, i)), 3, 1.0, seed=seed + 11 + i)
        side = np.clip(np.cos(az - a0), 0, 1) ** 1.5
        out = out + (curtain * streak * side)[..., None] * c * 0.7
    return out


def add_planet(img, d, pdir, radius, bands, light, rings=None, atmo=None, bands_freq=7.0, seed=1, craters=False, glow_lights=None, night=0.03, front=0.9):
    """Planeta de verdad (esfera a distancia 1, rayo desde la cámara). bands: paleta por latitud.
    rings: (r0, r1, normal, color, alpha). atmo: color del aro. glow_lights: color de luces en la cara de noche."""
    C = pdir.astype(np.float32)
    R = math.tan(radius)
    # (la luz del sol, pero un poco desde la cámara: si no, el planeta se ve casi todo de noche)
    light = light - C * front
    light = (light / np.linalg.norm(light)).astype(np.float32)
    b = d @ C
    cc = 1.0 - R * R
    disc = b * b - cc
    hit = disc > 0
    t = np.where(hit, b - np.sqrt(np.clip(disc, 0, None)), 0)
    P = d * t[..., None]
    N = (P - C) / R
    # ejes del planeta (polo un poco inclinado)
    pole = unit(0.25, 1.0, 0.15)
    lat = N @ pole
    ex = np.cross(pole, C)
    ex /= np.linalg.norm(ex)
    ez = np.cross(ex, pole)
    lon = np.arctan2(N @ ex, N @ ez)
    q = (N[..., 0] * 2.5, N[..., 1] * 2.5, N[..., 2] * 2.5)
    turb = fbm(warp(q, 0.6, 1.5, seed), 5, 1.5, seed=seed + 1) - 0.5
    tt = np.clip(0.5 + 0.5 * np.sin(lat * bands_freq + turb * 2.2 + np.sin(lon * 2 + lat * 4) * 0.15), 0, 1)
    tt = np.clip(tt * 0.8 + 0.2 * fbm((lat * 30, lon * 2, turb), 3, 1.0, seed=seed + 4), 0, 1)
    surf = mix_palette(bands, tt)
    if craters:
        cr = G.ridged(q, 4, 1.6, seed=seed + 7)
        surf = surf * (0.75 + 0.35 * cr)[..., None]
    lam = np.clip(N @ light, 0, 1)
    term = smooth(-0.08, 0.35, N @ light)
    shade = 0.06 + 0.94 * (lam ** 0.8) * term
    body = surf * shade[..., None] + surf * night
    if glow_lights is not None:
        cities = smooth(0.72, 0.85, fbm((N[..., 0] * 12, N[..., 1] * 12, N[..., 2] * 12), 4, 1.0, seed=seed + 9))
        body += (cities * (1 - term))[..., None] * glow_lights * 0.8
    mu = np.clip(-(N * d).sum(-1), 0, 1)  # 1 en el centro, 0 en el borde
    if atmo is not None:
        rim = (1 - mu) ** 3 * (0.3 + 0.7 * term)
        body += rim[..., None] * atmo * 0.9
    edge = smooth(0.0, 0.02, disc / max(R * R, 1e-6))
    out = img.copy()
    mask = hit
    out[mask] = img[mask] * (1 - edge[mask, None]) + body[mask] * edge[mask, None]
    # halo exterior de la atmósfera
    ang = np.arccos(np.clip(b, -1, 1))
    if atmo is not None:
        outside = np.clip(ang - radius, 0, None)
        out += (np.exp(-outside / (radius * 0.08)) * (~hit))[..., None] * atmo * 0.45
    if rings is not None:
        r0, r1, rn, rcol, ralpha = rings
        rn = rn / np.linalg.norm(rn)
        den = d @ rn
        tr = np.where(np.abs(den) > 1e-4, (C @ rn) / np.where(np.abs(den) > 1e-4, den, 1), -1)
        H = d * tr[..., None]
        dist = np.linalg.norm(H - C, axis=-1) / R
        on = (tr > 0) & (dist > r0) & (dist < r1)
        rr = (dist - r0) / (r1 - r0)
        bandsr = 0.55 + 0.45 * np.sin(rr * 60 + np.sin(rr * 13) * 2) * (0.6 + 0.4 * np.sin(rr * 7))
        gap = 1 - 0.85 * np.exp(-((rr - 0.62) ** 2) / 0.0008)
        a = ralpha * bandsr * gap * smooth(0, 0.05, rr) * smooth(1, 0.9, rr)
        # sombra del planeta sobre los anillos
        toC = H - C
        along = toC @ light
        perp = np.linalg.norm(toC - along[..., None] * light, axis=-1)
        shadowed = (along < 0) & (perp < R)
        lit = np.where(shadowed, 0.18, 1.0)
        behind = hit & (tr > t)
        a = np.where(on & ~behind, a, 0)
        out = out * (1 - a[..., None]) + (rcol * lit[..., None]) * a[..., None]
    return out


def add_moon(img, d, mdir, radius, palette, light, seed, atmo=None):
    return add_planet(img, d, mdir, radius, palette, light, atmo=atmo, bands_freq=2.0, seed=seed, craters=True)


def tone(img, exposure=1.2):
    return np.clip(1 - np.exp(-img * exposure), 0, 1)


# ---------------------------------------------------------------------------
# Los seis cielos
# ---------------------------------------------------------------------------
def siroco(d, name):
    # Desierto: cielo naranja quemado, dos soles bajos, un gigante pálido con anillos sobre las dunas
    sun1, sun2 = unit(0.75, 0.12, -0.65), unit(0.55, 0.22, -0.8)
    img = sky_gradient(d, [(-1, col(90, 46, 30)), (-0.02, col(214, 120, 64)), (0.0, col(255, 196, 120)), (0.1, col(236, 140, 74)),
                           (0.35, col(176, 88, 58)), (0.7, col(96, 52, 62)), (1, col(56, 34, 58))])
    img = add_planet(img, d, unit(-0.55, 0.38, -0.74), math.radians(17),
                     [(0, col(214, 176, 138)), (0.4, col(236, 206, 166)), (0.7, col(186, 134, 96)), (1, col(244, 222, 190))],
                     sun1, rings=(1.35, 2.25, unit(0.15, 1.0, 0.35), col(236, 206, 170), 0.75), atmo=col(255, 190, 140), seed=21)
    img = add_moon(img, d, unit(-0.1, 0.6, -0.8), math.radians(2.6), [(0, col(160, 140, 130)), (1, col(220, 205, 190))], sun1, 31)
    img = add_clouds(img, d, col(255, 196, 140), 0.32, 41, low=0.03, high=0.35, stretch=9, shadow=col(150, 80, 60))
    img = add_horizon_haze(img, d, col(240, 160, 100), 0.08, 0.55)
    img = add_sun(img, d, sun1, col(255, 220, 160), math.radians(2.2), 0.05)
    img = add_sun(img, d, sun2, col(255, 160, 110), math.radians(1.4), 0.035, 0.8)
    return tone(img, 1.25)


def talasa(d, name):
    # Océano: turquesa limpio, tres lunas (como las de TalasaKit) y nubes altas
    sun = unit(0.3, 0.55, 0.78)
    img = sky_gradient(d, [(-1, col(20, 70, 90)), (-0.02, col(110, 190, 200)), (0.0, col(210, 245, 240)), (0.1, col(150, 216, 226)),
                           (0.4, col(70, 160, 200)), (1, col(30, 90, 160))])
    img = add_planet(img, d, unit(0.36, 0.42, -0.83), math.radians(12),
                     [(0, col(70, 140, 200)), (0.4, col(150, 210, 230)), (0.6, col(240, 250, 250)), (1, col(60, 120, 190))],
                     sun, atmo=col(190, 240, 255), bands_freq=4.0, seed=51)
    img = add_moon(img, d, unit(-0.55, 0.42, -0.72), math.radians(4.5), [(0, col(170, 196, 220)), (1, col(236, 244, 250))], sun, 61)
    img = add_moon(img, d, unit(0.1, 0.62, -0.78), math.radians(2.6), [(0, col(220, 200, 180)), (1, col(250, 240, 226))], sun, 63)
    img = add_clouds(img, d, col(255, 255, 255), 0.42, 71, low=0.02, high=0.6, stretch=5, shadow=col(150, 190, 210))
    img = add_horizon_haze(img, d, col(220, 250, 248), 0.07, 0.5)
    img = add_sun(img, d, sun, col(255, 250, 230), math.radians(2.0), 0.05)
    return tone(img, 1.15)


def nivalis(d, name):
    # Hielo: noche azul polar, aurora verde y violeta, un gigante azul helado con anillos finos
    light = unit(-0.6, 0.15, 0.78)
    img = sky_gradient(d, [(-1, col(10, 16, 30)), (-0.02, col(70, 100, 150)), (0.0, col(130, 170, 214)), (0.12, col(46, 72, 124)),
                           (0.45, col(18, 30, 70)), (1, col(6, 10, 30))])
    img = add_stars(img, d, name, 9000, 211, 0.9)
    img = add_aurora(img, d, [col(60, 255, 170), col(120, 200, 255), col(190, 110, 255)], 221)
    img = add_planet(img, d, unit(0.5, 0.3, -0.81), math.radians(20),
                     [(0, col(120, 170, 220)), (0.35, col(200, 230, 250)), (0.6, col(80, 130, 200)), (1, col(230, 244, 255))],
                     light, rings=(1.3, 2.0, unit(-0.25, 1.0, 0.1), col(210, 230, 255), 0.6), atmo=col(150, 210, 255), bands_freq=6.0, seed=231, night=0.06)
    img = add_moon(img, d, unit(-0.35, 0.5, -0.79), math.radians(3.2), [(0, col(170, 180, 200)), (1, col(240, 244, 250))], light, 241)
    img = add_horizon_haze(img, d, col(120, 160, 210), 0.06, 0.5)
    return tone(img, 1.3)


def umbria(d, name):
    # Jungla: verde azulado húmedo con calima dorada, un planeta verde enorme y una luna
    sun = unit(-0.4, 0.5, 0.77)
    img = sky_gradient(d, [(-1, col(30, 56, 40)), (-0.02, col(120, 170, 120)), (0.0, col(220, 236, 190)), (0.1, col(150, 206, 170)),
                           (0.4, col(80, 160, 160)), (1, col(36, 96, 120))])
    img = add_planet(img, d, unit(0.6, 0.35, -0.72), math.radians(19),
                     [(0, col(60, 120, 70)), (0.35, col(120, 170, 90)), (0.55, col(60, 110, 150)), (0.75, col(200, 220, 200)), (1, col(70, 130, 80))],
                     sun, atmo=col(190, 255, 210), bands_freq=3.0, seed=301)
    img = add_moon(img, d, unit(-0.3, 0.58, -0.76), math.radians(3.0), [(0, col(180, 170, 150)), (1, col(240, 236, 220))], sun, 311)
    img = add_clouds(img, d, col(240, 250, 230), 0.5, 321, low=0.0, high=0.5, stretch=4, shadow=col(120, 160, 140))
    img = add_horizon_haze(img, d, col(210, 236, 200), 0.1, 0.65)
    img = add_sun(img, d, sun, col(255, 240, 190), math.radians(2.0), 0.06)
    return tone(img, 1.15)


def miasma(d, name):
    # Radiación: cielo verde ácido y violeta tóxico, nubes pesadas, un planeta verde brillante agrietado
    light = unit(0.2, 0.3, -0.93)
    img = sky_gradient(d, [(-1, col(26, 34, 18)), (-0.02, col(120, 150, 60)), (0.0, col(200, 230, 110)), (0.1, col(130, 170, 70)),
                           (0.35, col(80, 90, 70)), (0.7, col(60, 44, 80)), (1, col(30, 22, 46))])
    img = add_planet(img, d, unit(-0.45, 0.4, -0.8), math.radians(16),
                     [(0, col(70, 110, 30)), (0.4, col(160, 230, 60)), (0.55, col(40, 60, 20)), (0.8, col(200, 255, 120)), (1, col(90, 140, 40))],
                     light, atmo=col(180, 255, 90), bands_freq=5.0, seed=401, glow_lights=col(200, 255, 80), night=0.08)
    img = add_moon(img, d, unit(0.45, 0.55, -0.7), math.radians(2.8), [(0, col(120, 110, 130)), (1, col(200, 190, 210))], light, 411)
    img = add_clouds(img, d, col(170, 200, 110), 0.55, 421, low=0.0, high=0.6, stretch=5, shadow=col(50, 50, 40))
    img = add_horizon_haze(img, d, col(180, 220, 90), 0.09, 0.6)
    img = add_sun(img, d, light, col(220, 255, 150), math.radians(1.6), 0.07, 0.8)
    return tone(img, 1.2)


def vertice(d, name):
    # Neón / tecnológico: anochecer violeta y magenta, gigante a franjas con anillos, muchas estrellas
    light = unit(-0.7, 0.05, -0.7)
    img = sky_gradient(d, [(-1, col(20, 10, 30)), (-0.02, col(150, 60, 140)), (0.0, col(255, 120, 170)), (0.08, col(170, 70, 170)),
                           (0.3, col(80, 36, 120)), (0.7, col(30, 16, 64)), (1, col(10, 6, 30))])
    img = add_stars(img, d, name, 11000, 501, 0.9, fade_low=0.12)
    img = add_planet(img, d, unit(0.42, 0.33, -0.84), math.radians(22),
                     [(0, col(120, 60, 170)), (0.3, col(230, 150, 210)), (0.5, col(80, 50, 140)), (0.7, col(250, 200, 230)), (1, col(140, 70, 180))],
                     light, rings=(1.4, 2.4, unit(0.3, 1.0, -0.2), col(255, 170, 230), 0.7), atmo=col(255, 140, 220), bands_freq=9.0, seed=511,
                     glow_lights=col(120, 230, 255), night=0.07)
    img = add_moon(img, d, unit(-0.5, 0.45, -0.74), math.radians(3.4), [(0, col(130, 120, 170)), (1, col(220, 210, 240))], light, 521)
    img = add_clouds(img, d, col(255, 150, 200), 0.25, 531, low=0.02, high=0.25, stretch=10, shadow=col(90, 40, 100))
    img = add_horizon_haze(img, d, col(255, 110, 180), 0.06, 0.55)
    return tone(img, 1.25)


# nombre del planeta → (archivo con el nombre viejo, función)
SKIES = {
    "siroco": ("ocrea", siroco),
    "talasa": ("marena", talasa),
    "nivalis": ("velaria", nivalis),
    "umbria": ("fronda", umbria),
    "miasma": ("zefira", miasma),
    "vertice": ("mercadia", vertice),
}


def preview(files):
    # vista hacia el frente (−Z, donde están los planetas) de cada cielo: la cara ft
    tiles = [Image.open(G.OUT / f"cielo_{f}_ft.jpg").resize((360, 360)) for f in files]
    sheet = Image.new("RGB", (360 * len(tiles), 360))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * 360, 0))
    G.DOCS.mkdir(parents=True, exist_ok=True)
    sheet.save(G.DOCS / "cielos-planetas.jpg", quality=88)
    print("  ✓ docs/planetas/cielos-planetas.jpg")


if __name__ == "__main__":
    only = [a.lower() for a in sys.argv[1:] if not a.startswith("--")]
    done = []
    for key, (file, fn) in SKIES.items():
        if only and key not in only:
            continue
        print("·", key)
        for face in FACES:
            G.save(fn(face_dirs(face), face), f"cielo_{file}_{face}.jpg", 92)
        done.append(file)
    if done:
        preview([f for _, (f, _) in SKIES.items() if (G.OUT / f"cielo_{f}_ft.jpg").exists()])
