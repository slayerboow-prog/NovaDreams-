#!/usr/bin/env python3
"""Texturas PBR de Nácara v2 (docs/mar/nacara-v2/diseno.md §3 bis), hechas con cuentas (numpy): sin fotos ni
texturas de nadie, y que se repiten sin costuras (todo el ruido es periódico).

Para cada material: <nombre>_color.png, <nombre>_normal.png (OpenGL, Y hacia arriba, como Roblox),
<nombre>_roughness.png y, el oro, <nombre>_metalness.png. 512 × 512 (lo que pide el móvil; el atlas de los
ornamentos, 1024, lo hace nacara_v2_ornamentos.py). En el juego son los MaterialVariant «NV2_<Nombre>»
(World/NacaraV2Look) y en las vistas previas, las mismas imágenes.

    Nacar          nácar de concha con vetas irisadas (rosa, cian, lila)
    CoralTallado   piedra de coral tallada, porosa, con surcos
    Mosaico        teselas azul-verde con juntas
    Oro            remates de oro con volutas grabadas
    CristalMarco   paneles de cristal oscuro con marco de nácar y oro (ventanas y vidrieras)
    RocaGastada    roca en capas, gastada, con musgo en las grietas
    LosaArenisca   losas de arenisca irregulares
    TejadoKelp     tejado de kelp trenzado

Uso (desde roblox/): python3 scripts/map/nacara_v2_texturas.py [assets/nacara-v2/tex] [--lado 512]
"""
import argparse
import os

import numpy as np
from PIL import Image

RNG = np.random.default_rng(20261028)


def fbm(n, octaves=5, base=4, gain=0.5, seed=0):
    """Ruido fractal periódico (se repite sin costura): suma de ondas con fase al azar."""
    rng = np.random.default_rng(seed)
    out = np.zeros((n, n))
    y, x = np.mgrid[0:n, 0:n] / n
    amp, total = 1.0, 0.0
    for o in range(octaves):
        f = base * 2 ** o
        layer = np.zeros((n, n))
        for _ in range(6):
            kx, ky = rng.integers(-f, f + 1, 2)
            if kx == 0 and ky == 0:
                kx = f
            layer += np.sin(2 * np.pi * (kx * x + ky * y) + rng.uniform(0, 2 * np.pi))
        out += amp * layer / 6
        total += amp
        amp *= gain
    out /= total
    return (out - out.min()) / (out.max() - out.min() + 1e-9)


def voronoi(n, cells, seed=0):
    """Distancia al punto más cercano y al segundo (celdas periódicas) e índice de celda."""
    rng = np.random.default_rng(seed)
    pts = rng.uniform(0, 1, (cells, 2))
    y, x = np.mgrid[0:n, 0:n] / n
    d1 = np.full((n, n), 9.0)
    d2 = np.full((n, n), 9.0)
    idx = np.zeros((n, n), dtype=int)
    for i, (px, py) in enumerate(pts):
        dx = np.abs(x - px)
        dy = np.abs(y - py)
        dx = np.minimum(dx, 1 - dx)
        dy = np.minimum(dy, 1 - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < d1
        d2 = np.where(closer, d1, np.minimum(d2, d))
        idx = np.where(closer, i, idx)
        d1 = np.where(closer, d, d1)
    return d1, d2, idx


def normal_from(h, strength):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * strength
    nx, ny, nz = -dx, dy, np.ones_like(h)
    l = np.sqrt(nx * nx + ny * ny + nz * nz)
    return np.stack([nx / l, ny / l, nz / l], -1) * 0.5 + 0.5


def lerp(a, b, t):
    t = t[..., None] if np.ndim(t) == 2 else t
    return np.asarray(a) * (1 - t) + np.asarray(b) * t


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def save(out, name, color, height, rough, strength=6.0, metal=None):
    Image.fromarray((np.clip(color, 0, 1) * 255).astype(np.uint8)).save(os.path.join(out, f"{name}_color.png"))
    Image.fromarray((normal_from(height, strength) * 255).astype(np.uint8)).save(os.path.join(out, f"{name}_normal.png"))
    Image.fromarray((np.clip(rough, 0, 1) * 255).astype(np.uint8)).save(os.path.join(out, f"{name}_roughness.png"))
    if metal is not None:
        Image.fromarray((np.clip(metal, 0, 1) * 255).astype(np.uint8)).save(os.path.join(out, f"{name}_metalness.png"))


def nacar(n):
    w = fbm(n, 4, 2, seed=1)
    bands = 0.5 + 0.5 * np.sin(2 * np.pi * (6 * w + 3 * fbm(n, 3, 3, seed=2)))
    hue = fbm(n, 3, 2, seed=3)
    pink, cyan, lilac, pearl = (0.97, 0.86, 0.90), (0.80, 0.93, 0.97), (0.88, 0.84, 0.97), (0.96, 0.95, 0.93)
    c = lerp(lerp(pink, cyan, smooth(0.3, 0.7, hue)), lilac, smooth(0.55, 0.9, fbm(n, 3, 3, seed=4)) * 0.6)
    c = lerp(pearl, c, 0.55 + 0.35 * bands)
    c = c * (0.92 + 0.08 * bands[..., None])
    return c, bands * 0.5 + fbm(n, 6, 8, seed=5) * 0.2, 0.22 + 0.12 * (1 - bands), 3.0


def coral_tallado(n):
    d1, d2, _ = voronoi(n, 46, seed=11)
    pores = smooth(0.62, 0.78, fbm(n, 6, 16, seed=12))
    grooves = 0.5 + 0.5 * np.sin(2 * np.pi * (8 * np.mgrid[0:n, 0:n][0] / n + 2.5 * fbm(n, 3, 2, seed=13)))
    h = 0.6 * smooth(0.0, 0.08, d2 - d1) + 0.25 * grooves - 0.5 * pores + 0.2 * fbm(n, 6, 12, seed=14)
    base = lerp((0.86, 0.66, 0.62), (0.94, 0.80, 0.72), fbm(n, 4, 4, seed=15))
    c = base * (0.75 + 0.25 * smooth(-0.2, 0.8, h))[..., None]
    c = lerp(c, (0.55, 0.36, 0.38), pores * 0.8)
    return c, h, 0.78 + 0.15 * pores, 5.0


def mosaico(n):
    tiles = 16
    y, x = np.mgrid[0:n, 0:n] / n * tiles
    fx, fy = x - np.floor(x), y - np.floor(y)
    grout = 1 - smooth(0.0, 0.07, np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy)))
    ix, iy = np.floor(x).astype(int) % tiles, np.floor(y).astype(int) % tiles
    rng = np.random.default_rng(21)
    pal = np.array([(0.10, 0.55, 0.62), (0.12, 0.42, 0.66), (0.16, 0.66, 0.58), (0.24, 0.74, 0.78), (0.08, 0.34, 0.52), (0.85, 0.80, 0.62)])
    pick = rng.choice(len(pal), (tiles, tiles), p=[0.24, 0.22, 0.2, 0.16, 0.12, 0.06])
    c = pal[pick[iy, ix]] * (0.85 + 0.3 * fbm(n, 5, 16, seed=22))[..., None]
    c = lerp(c, (0.82, 0.80, 0.74), grout)
    h = (1 - grout) * 0.8 + 0.1 * fbm(n, 5, 32, seed=23)
    return c, h, 0.25 + 0.6 * grout, 4.0


def oro(n):
    y, x = np.mgrid[0:n, 0:n] / n
    # volutas: ondas que se enroscan, grabadas
    s = np.sin(2 * np.pi * (4 * x + 0.35 * np.sin(2 * np.pi * 4 * y)))
    scroll = smooth(0.75, 0.95, np.abs(s)) * smooth(0.2, 0.5, 0.5 + 0.5 * np.sin(2 * np.pi * 8 * y))
    border = smooth(0.0, 0.03, np.minimum(np.abs(y - 0.0), np.abs(1 - y))) * 0 + smooth(0.45, 0.5, np.abs(((y * 2) % 1) - 0.5))
    scratch = fbm(n, 6, 24, seed=31)
    h = 0.6 - 0.45 * scroll - 0.3 * border + 0.08 * scratch
    gold = lerp((0.78, 0.56, 0.20), (1.0, 0.84, 0.45), smooth(0.2, 0.9, h + 0.1 * scratch))
    c = lerp(gold, (0.45, 0.30, 0.10), scroll * 0.7)
    return c, h, 0.28 + 0.25 * scroll + 0.1 * scratch, 5.0, 0.95 - 0.2 * scroll


def cristal_marco(n):
    y, x = np.mgrid[0:n, 0:n] / n
    panes = 4
    fx, fy = (x * panes) % 1, (y * panes) % 1
    frame = 1 - smooth(0.04, 0.09, np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy)))
    outer = 1 - smooth(0.02, 0.05, np.minimum(np.minimum(x, 1 - x), np.minimum(y, 1 - y)))
    glassc = lerp((0.06, 0.20, 0.30), (0.20, 0.50, 0.62), fbm(n, 4, 4, seed=41))
    glassc = glassc + 0.25 * smooth(0.7, 1.0, 1 - fy)[..., None] * np.array([0.6, 0.8, 0.9])  # brillo arriba de cada panel
    c = lerp(glassc, (0.93, 0.90, 0.86), frame)
    c = lerp(c, (0.95, 0.78, 0.40), outer)
    h = 0.2 + 0.6 * np.maximum(frame, outer)
    return c, h, 0.08 + 0.4 * np.maximum(frame, outer), 6.0


def roca_gastada(n):
    y, x = np.mgrid[0:n, 0:n] / n
    warp = fbm(n, 4, 2, seed=51)
    strata = 0.5 + 0.5 * np.sin(2 * np.pi * (7 * y + 1.2 * warp))
    d1, d2, _ = voronoi(n, 14, seed=52)
    cracks = 1 - smooth(0.0, 0.025, d2 - d1)
    detail = fbm(n, 6, 16, seed=53)
    h = 0.55 * strata + 0.35 * detail - 0.25 * cracks
    rock = lerp((0.24, 0.29, 0.36), (0.46, 0.50, 0.56), smooth(0.2, 0.9, 0.6 * strata + 0.4 * detail))
    moss = smooth(0.55, 0.75, fbm(n, 5, 6, seed=54)) * smooth(0.3, 0.7, 1 - strata + cracks * 0.5)
    c = lerp(rock, (0.22, 0.44, 0.30), moss * 0.85)
    c = c * (1 - 0.22 * cracks)[..., None]
    return c, h, 0.85 + 0.1 * detail, 7.0


def losa_arenisca(n):
    d1, d2, idx = voronoi(n, 20, seed=61)
    joint = 1 - smooth(0.0, 0.02, d2 - d1)
    rng = np.random.default_rng(62)
    tone = rng.uniform(0.85, 1.1, 20)[idx]
    grain = fbm(n, 6, 24, seed=63)
    base = lerp((0.80, 0.70, 0.54), (0.90, 0.82, 0.66), fbm(n, 4, 4, seed=64))
    c = base * (tone * (0.9 + 0.12 * grain))[..., None]
    c = lerp(c, (0.58, 0.52, 0.42), joint)
    h = (1 - joint) * 0.7 + 0.15 * grain + 0.1 * smooth(0.0, 0.2, d2 - d1)
    return c, h, 0.8 + 0.1 * grain, 5.0


def tejado_kelp(n):
    y, x = np.mgrid[0:n, 0:n] / n
    k = 8
    u, v = (x * k) % 1, (y * k) % 1
    cell = (np.floor(x * k) + np.floor(y * k)) % 2
    strand = np.where(cell == 0, np.sin(np.pi * u), np.sin(np.pi * v))  # tiras que se cruzan (cesta)
    under = np.where(cell == 0, np.sin(np.pi * v), np.sin(np.pi * u))
    fib = 0.5 + 0.5 * np.sin(2 * np.pi * np.where(cell == 0, v * 10, u * 10) + 3 * fbm(n, 3, 8, seed=71))
    h = 0.65 * strand * (0.6 + 0.4 * under) + 0.12 * fib
    kelp = lerp((0.22, 0.32, 0.14), (0.50, 0.58, 0.24), smooth(0.1, 0.9, h + 0.2 * fbm(n, 4, 6, seed=72)))
    c = lerp(kelp, (0.42, 0.34, 0.18), smooth(0.6, 0.9, fbm(n, 4, 4, seed=73)) * 0.4)
    c = c * (0.6 + 0.4 * strand)[..., None]
    return c, h, 0.7 + 0.15 * (1 - strand), 6.0


SETS = {
    "Nacar": nacar, "CoralTallado": coral_tallado, "Mosaico": mosaico, "Oro": oro, "CristalMarco": cristal_marco,
    "RocaGastada": roca_gastada, "LosaArenisca": losa_arenisca, "TejadoKelp": tejado_kelp,
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out", nargs="?", default="assets/nacara-v2/tex")
    ap.add_argument("--lado", type=int, default=512)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    tiles = []
    for name, fn in SETS.items():
        r = fn(a.lado)
        color, height, rough, strength = r[0], r[1], r[2], r[3]
        metal = r[4] if len(r) > 4 else None
        save(a.out, name.lower(), color, height, rough, strength, metal)
        tiles.append((name, color))
        print(f"  {name}: {a.lado}×{a.lado}")
    # hoja de muestra (para el dueño y para revisar a ojo que se repiten sin costura: 2×2 de cada una)
    s = 256
    sheet = Image.new("RGB", (s * 4, s * 2))
    for i, (name, color) in enumerate(tiles):
        im = Image.fromarray((np.clip(np.tile(color, (2, 2, 1)), 0, 1) * 255).astype(np.uint8)).resize((s, s))
        sheet.paste(im, ((i % 4) * s, (i // 4) * s))
    sheet.save(os.path.join(os.path.dirname(a.out.rstrip("/")), "texturas-muestra.jpg"), quality=88)


if __name__ == "__main__":
    main()
