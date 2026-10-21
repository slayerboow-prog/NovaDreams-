#!/usr/bin/env python3
"""Las texturas del MaterialVariant «MarCoral» del mar v4 (docs/mar/v4-objetivo.md: «nada de corales de tiza»).

Un coral de verdad de cerca: pólipos (copitas redondas con el centro hundido y un borde claro), poros entre
ellos y algo de variación de tono. Tres mapas de 512×512 que se repiten sin costuras (celdas de Voronoi en un
toro), en GRISES CLAROS: en Roblox el color de cada coral (Part.Color, la paleta de la zona) tiñe el ColorMap.

    assets/mar/tex/coralv4_color.png      gris claro con los pólipos un poco más oscuros por dentro
    assets/mar/tex/coralv4_normal.png     normales (espacio tangente, OpenGL: verde hacia arriba)
    assets/mar/tex/coralv4_roughness.png  rugosidad (los bordes de los pólipos algo más brillantes)

Los sube scripts/upload-mar.sh con las demás texturas (tex/*.png) y scripts/build-place.luau crea el
MaterialVariant con ellas (base Limestone). Uso (desde roblox/):  python3 scripts/map/mar_coral_textura.py
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TEX = os.path.join(ROOT, "assets", "mar", "tex")
N = 512


def voronoi_torus(n_points, seed):
    rnd = np.random.default_rng(seed)
    pts = rnd.random((n_points, 2))
    yy, xx = np.mgrid[0:N, 0:N] / N
    d1 = np.full((N, N), 9.0)
    d2 = np.full((N, N), 9.0)
    for px, py in pts:
        dx = np.abs(xx - px)
        dy = np.abs(yy - py)
        dx = np.minimum(dx, 1 - dx)
        dy = np.minimum(dy, 1 - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < d1
        d2 = np.where(closer, d1, np.minimum(d2, d))
        d1 = np.where(closer, d, d1)
    return d1, d2


def periodic_noise(seed, octaves=4):
    rnd = np.random.default_rng(seed)
    out = np.zeros((N, N))
    amp = 1.0
    for o in range(octaves):
        f = 4 * 2 ** o
        g = rnd.random((f, f))
        # interpolación bilineal periódica
        yy, xx = np.mgrid[0:N, 0:N] / N * f
        x0, y0 = np.floor(xx).astype(int), np.floor(yy).astype(int)
        tx, ty = xx - x0, yy - y0
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        x1, y1 = (x0 + 1) % f, (y0 + 1) % f
        x0, y0 = x0 % f, y0 % f
        v = (g[y0, x0] * (1 - tx) + g[y0, x1] * tx) * (1 - ty) + (g[y1, x0] * (1 - tx) + g[y1, x1] * tx) * ty
        out += v * amp
        amp *= 0.5
    return out / out.max()


def main():
    os.makedirs(TEX, exist_ok=True)
    # (primera prueba: 170 celdas con bordes marcados parecían BALDOSAS. Muchas y pequeñas, con el borde
    # entre pólipos blando y deformadas con ruido: de cerca son pólipos, de lejos un grano)
    d1, d2 = voronoi_torus(900, 7)
    warp = periodic_noise(5, 3) - 0.5
    cell = (d2 - d1) + warp * 0.004  # 0 en los bordes entre pólipos
    r = np.clip(2 * d1 / (d1 + d2) + warp * 0.15, 0, 1)  # 0 en el centro del pólipo, 1 en su borde
    # altura: copita (borde alto, centro hundido) y surcos entre pólipos
    cup = np.exp(-((r - 0.6) ** 2) / 0.04) * 0.7 - np.exp(-(r ** 2) / 0.05) * 0.6
    groove = -np.exp(-(cell ** 2) / 0.00001) * 0.35
    fine = periodic_noise(3) - 0.5
    height = cup + groove + fine * 0.25
    # color (gris claro): centros algo más oscuros, bordes claros, manchas suaves
    tone = 0.84 + 0.1 * (periodic_noise(11, 3) - 0.5)
    col = tone - 0.16 * np.exp(-(r ** 2) / 0.05) + 0.06 * np.exp(-((r - 0.6) ** 2) / 0.04) - 0.06 * np.exp(-(cell ** 2) / 0.00002)
    col = np.clip(col, 0, 1)
    rgb = np.stack([col * 0.99, col * 0.97, col * 0.93], -1)
    Image.fromarray((rgb * 255).astype(np.uint8)).save(os.path.join(TEX, "coralv4_color.png"))
    # normales desde la altura (periódicas)
    k = 3.0
    gx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * k
    gy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * k
    nz = 1.0 / np.sqrt(1 + gx * gx + gy * gy)
    nx, ny = -gx * nz, gy * nz
    nrm = np.stack([nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5], -1)
    Image.fromarray((nrm * 255).astype(np.uint8)).save(os.path.join(TEX, "coralv4_normal.png"))
    rough = np.clip(0.78 - 0.18 * np.exp(-((r - 0.6) ** 2) / 0.04) + 0.1 * fine, 0, 1)
    Image.fromarray((rough * 255).astype(np.uint8)).save(os.path.join(TEX, "coralv4_roughness.png"))
    print("-> assets/mar/tex/coralv4_{color,normal,roughness}.png")


if __name__ == "__main__":
    main()
