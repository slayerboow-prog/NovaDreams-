#!/usr/bin/env python3
"""Texturas PBR enlosables de las ciudades de los planetas (MaterialVariant de shared/Cosmos/EspacioLook).

    python scripts/espacio/gen_ciudad.py [panel|fachada|piedra|suelo] [--preview]

Cuatro materiales (color, normal, roughness y metalness, 1024 px, se repiten sin costura). El color va en
gris claro: el color de cada pieza lo tiñe, así sirven para los siete planetas.

  ciudad_panel_*    chapa de ciencia ficción: paneles grandes con juntas hundidas, biseles, remaches,
                    trampillas, rejillas y tiras técnicas          -> MaterialVariant «CiudadPanel»
  ciudad_fachada_*  fachada de edificio: filas de ventanas hundidas de cristal oscuro entre montantes,
                    antepechos de panel y juntas de planta          -> «CiudadFachada»
  ciudad_piedra_*   sillares tallados con juntas, desgaste y un friso grabado  -> «CiudadPiedra»
  ciudad_suelo_*    losas hexagonales de plaza con juntas y tapas técnicas     -> «CiudadSuelo»

Después: bash scripts/upload-espacio.sh (sube las que falten) y publicar.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen import OUT, ROOT, normal_from_height, save, smooth, tile_noise  # noqa: E402

N = 1024


def grid():
    yy, xx = np.mgrid[0:N, 0:N]
    return xx.astype(np.float32), yy.astype(np.float32)


def rect_edge(xx, yy, x0, y0, w, h):
    """Distancia al borde dentro del rectángulo (0 en el borde), y la máscara."""
    lx, ly = xx - x0, yy - y0
    inside = (lx >= 0) & (lx < w) & (ly >= 0) & (ly < h)
    edge = np.minimum(np.minimum(lx, w - 1 - lx), np.minimum(ly, h - 1 - ly))
    return np.where(inside, edge, -1.0), inside


def stamp_disc(arr, cx, cy, r, value, soft=1.5):
    x0, x1 = int(cx - r - 2), int(cx + r + 3)
    y0, y1 = int(cy - r - 2), int(cy + r + 3)
    ys = np.arange(y0, y1) % N
    xs = np.arange(x0, x1) % N
    yy, xx = np.meshgrid(np.arange(y0, y1), np.arange(x0, x1), indexing="ij")
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    k = np.clip((r - d) / soft, 0, 1)
    sub = arr[np.ix_(ys, xs)]
    arr[np.ix_(ys, xs)] = np.maximum(sub, k * value)


def write(prefix, color, height, rough, metal, strength):
    save(np.clip(color, 0, 1), f"{prefix}_color.png")
    save(normal_from_height(height, strength), f"{prefix}_normal.png")
    save(np.repeat(np.clip(rough, 0, 1)[..., None], 3, -1), f"{prefix}_roughness.png")
    save(np.repeat(np.clip(metal, 0, 1)[..., None], 3, -1), f"{prefix}_metalness.png")


# ---------------------------------------------------------------------------
def gen_panel():
    rng = np.random.default_rng(4101)
    xx, yy = grid()
    height = np.zeros((N, N), np.float32)
    seams = np.zeros((N, N), np.float32)
    rivets = np.zeros((N, N), np.float32)
    tone = np.zeros((N, N), np.float32)
    dark = np.zeros((N, N), np.float32)  # rejillas y huecos
    rects = []

    def split(x0, y0, w, h, depth):
        if depth >= 5 or (depth >= 2 and rng.random() < 0.22) or min(w, h) < 110:
            rects.append((x0, y0, w, h))
            return
        if w >= h:
            cut = int(round(w * rng.choice([0.33, 0.5, 0.5, 0.66]) / 16) * 16)
            split(x0, y0, cut, h, depth + 1)
            split(x0 + cut, y0, w - cut, h, depth + 1)
        else:
            cut = int(round(h * rng.choice([0.33, 0.5, 0.5, 0.66]) / 16) * 16)
            split(x0, y0, w, cut, depth + 1)
            split(x0, y0 + cut, w, h - cut, depth + 1)

    split(0, 0, N, N, 0)
    for (x0, y0, w, h) in rects:
        edge, inside = rect_edge(xx, yy, x0, y0, w, h)
        e = np.where(inside, edge, 99)
        seams = np.maximum(seams, np.where(inside, np.exp(-e / 1.8), 0))
        lift = rng.uniform(-0.12, 0.12)
        height = np.where(inside, smooth(0, 7, e) * 0.7 + lift, height)
        tone = np.where(inside, rng.uniform(-1, 1), tone)
        # remaches en las esquinas y a lo largo del borde largo
        step = 32
        for t in range(step // 2, w, step):
            for cy in (y0 + 9, y0 + h - 10):
                stamp_disc(rivets, x0 + t, cy, 3.2, 1.0)
        kind = rng.random()
        if kind < 0.16 and w > 150 and h > 110:
            # rejilla de ventilación: lamas hundidas
            gx0, gy0, gw = x0 + w // 5, y0 + h // 4, int(w * 0.6)
            for k in range(max(3, (h // 2) // 12)):
                yk = gy0 + k * 12
                sl = (slice(yk, yk + 6), slice(gx0, gx0 + gw))
                height[sl] -= 0.9
                dark[sl] = 1.0
        elif kind < 0.3 and w > 120 and h > 120:
            # trampilla: un marco hundido dentro del panel con cuatro tornillos
            m = 22
            e2, in2 = rect_edge(xx, yy, x0 + m, y0 + m, w - 2 * m, h - 2 * m)
            groove = np.where(in2, np.exp(-np.where(in2, e2, 99) / 1.5), 0)
            seams = np.maximum(seams, groove * 0.8)
            height = np.where(in2, height + 0.18, height)
            for (cx, cy) in ((x0 + m + 10, y0 + m + 10), (x0 + w - m - 11, y0 + m + 10), (x0 + m + 10, y0 + h - m - 11), (x0 + w - m - 11, y0 + h - m - 11)):
                stamp_disc(rivets, cx, cy, 4.2, 1.0)
        elif kind < 0.42 and w > 160:
            # tira técnica: un canal horizontal con resaltes
            yk = y0 + h // 2 - 8
            height[yk:yk + 16, x0 + 14:x0 + w - 14] -= 0.6
            for t in range(x0 + 26, x0 + w - 30, 28):
                height[yk + 3:yk + 13, t:t + 14] += 0.75
            dark[yk:yk + 16, x0 + 14:x0 + w - 14] = np.maximum(dark[yk:yk + 16, x0 + 14:x0 + w - 14], 0.45)
    wear = tile_noise(N, 2.0, 6, 4111)
    fine = tile_noise(N, 16.0, 3, 4113)
    streak = smooth(0.6, 0.85, tile_noise(N, 1.2, 4, 4115))
    grime = np.clip(smooth(0.25, 1.0, seams) * (0.55 + 0.6 * wear) + dark * 0.5, 0, 1)
    height = height - seams * 1.1 + rivets * 0.55 + (wear - 0.5) * 0.06 + (fine - 0.5) * 0.03
    base = 0.86 + tone * 0.045 + (wear - 0.5) * 0.07 - streak * 0.05
    color = np.stack([base, base, base * 1.01], -1)
    color *= (1 - 0.55 * grime)[..., None]
    color *= (1 - 0.75 * dark)[..., None]
    color += (rivets * 0.06)[..., None]
    rough = 0.36 + (wear - 0.5) * 0.25 + grime * 0.4 + tone * 0.05
    metal = 0.78 - grime * 0.4 + tone * 0.06
    write("ciudad_panel", color, height, rough, metal, 3.4)


# ---------------------------------------------------------------------------
def gen_fachada():
    """4 plantas por baldosa (256 px cada una) y 8 vanos (128 px): con StudsPerTile = 40, plantas de 10 studs."""
    rng = np.random.default_rng(4201)
    xx, yy = grid()
    height = np.full((N, N), 0.6, np.float32)
    glass = np.zeros((N, N), np.float32)
    seams = np.zeros((N, N), np.float32)
    frame = np.zeros((N, N), np.float32)
    lit = np.zeros((N, N), np.float32)
    FH, BW = 256, 128
    for f in range(4):
        y0 = f * FH
        # junta de planta y cornisa fina
        seams[y0:y0 + 4, :] = 1
        height[y0 + 4:y0 + 18, :] += 0.35
        for b in range(8):
            x0 = b * BW
            seams[y0:y0 + FH, x0:x0 + 3] = np.maximum(seams[y0:y0 + FH, x0:x0 + 3], 0.8)
            # la ventana: hundida, con marco y un travesaño
            wx0, wy0, ww, wh = x0 + 16, y0 + 70, BW - 32, 150
            e, inside = rect_edge(xx, yy, wx0, wy0, ww, wh)
            ein = np.where(inside, e, 99)
            frame = np.maximum(frame, np.where(inside & (ein < 7), 1.0, 0))
            g = inside & (ein >= 7)
            glass = np.where(g, 1.0, glass)
            height = np.where(inside, 0.6 - 0.75 * smooth(0, 7, ein), height)
            # travesaño
            ty = wy0 + int(wh * 0.38)
            frame[ty:ty + 5, wx0 + 7:wx0 + ww - 7] = 1
            glass[ty:ty + 5, wx0 + 7:wx0 + ww - 7] = 0
            height[ty:ty + 5, wx0 + 7:wx0 + ww - 7] = 0.3
            # tono propio de cada cristal (reflejos distintos) y alguna persiana
            tone = rng.uniform(0.0, 1.0)
            lit = np.where(g, tone, lit)
            if rng.random() < 0.22:
                bh = int(wh * rng.uniform(0.25, 0.7))
                sl = (slice(wy0 + 7, wy0 + 7 + bh), slice(wx0 + 7, wx0 + ww - 7))
                lit[sl] = 1.6
                for k in range(0, bh, 8):
                    height[wy0 + 7 + k:wy0 + 9 + k, wx0 + 7:wx0 + ww - 7] += 0.12
            # antepecho con un panel resaltado bajo la ventana
            e2, in2 = rect_edge(xx, yy, x0 + 22, y0 + 26, BW - 44, 34)
            height = np.where(in2, height + 0.22 * smooth(0, 4, np.where(in2, e2, 0)), height)
            seams = np.maximum(seams, np.where(in2, np.exp(-np.where(in2, e2, 99) / 1.4) * 0.6, 0))
            # unidad de aire en algunas
            if rng.random() < 0.12:
                ax, ay = x0 + 40, y0 + 232
                height[ay:ay + 18, ax:ax + 48] += 0.5
                seams[ay:ay + 18:4, ax:ax + 48] = 0.7
    wear = tile_noise(N, 2.0, 6, 4211)
    drip = smooth(0.55, 0.9, tile_noise(N, 1.0, 4, 4213))
    grime = np.clip(seams * (0.5 + 0.6 * wear), 0, 1)
    height = height - seams * 0.5 + (wear - 0.5) * 0.04
    wall = 0.86 + (wear - 0.5) * 0.08 - drip * 0.05
    color = np.stack([wall, wall, wall], -1)
    color *= (1 - 0.5 * grime)[..., None]
    color = np.where(frame[..., None] > 0, color * 0.55, color)
    # cristal: oscuro azulado, con reflejo de cielo arriba; las persianas, claras
    gy = (yy % 256 - 70) / 150
    sky = np.clip(1 - gy, 0, 1) * 0.16
    gcol = np.stack([0.10 + sky * 0.6 + lit * 0.03, 0.14 + sky * 0.8 + lit * 0.04, 0.2 + sky + lit * 0.05], -1)
    blind = np.stack([np.full((N, N), 0.62), np.full((N, N), 0.62), np.full((N, N), 0.6)], -1)
    gcol = np.where((lit > 1.2)[..., None], blind, gcol)
    color = np.where(glass[..., None] > 0, gcol, color)
    rough = 0.6 + (wear - 0.5) * 0.2 + grime * 0.3
    rough = np.where(glass > 0, np.where(lit > 1.2, 0.7, 0.07 + lit * 0.05), rough)
    rough = np.where(frame > 0, 0.35, rough)
    metal = np.where(frame > 0, 0.85, 0.05)
    metal = np.where(glass > 0, np.where(lit > 1.2, 0.0, 0.5), metal)
    write("ciudad_fachada", color, height, rough, metal, 4.0)


# ---------------------------------------------------------------------------
def gen_piedra():
    rng = np.random.default_rng(4301)
    xx, yy = grid()
    height = np.zeros((N, N), np.float32)
    seams = np.zeros((N, N), np.float32)
    tone = np.zeros((N, N), np.float32)
    carve = np.zeros((N, N), np.float32)
    row_h = 128
    for r in range(8):
        y0 = r * row_h
        off = (r % 2) * 128 + int(rng.integers(0, 3)) * 64
        x = 0
        widths = []
        while x < N:
            w = int(rng.choice([192, 256, 256, 320]))
            if x + w > N:
                w = N - x
            widths.append((x, w))
            x += w
        for (bx, w) in widths:
            if w < 40:
                continue
            x0 = (bx + off) % N
            # (dibujado con vuelta: las coordenadas se envuelven)
            lx = (xx - x0) % N
            ly = yy - y0
            inside = (lx < w) & (ly >= 0) & (ly < row_h)
            edge = np.minimum(np.minimum(lx, w - 1 - lx), np.minimum(ly, row_h - 1 - ly))
            e = np.where(inside, edge, 99)
            seams = np.maximum(seams, np.where(inside, np.exp(-e / 2.6), 0))
            height = np.where(inside, smooth(0, 12, e) * 0.9 + rng.uniform(-0.15, 0.15), height)
            tone = np.where(inside, rng.uniform(-1, 1), tone)
        if r == 3:
            # un friso grabado: rombos y líneas a lo largo de la hilada
            cy = y0 + row_h // 2
            for cx in range(64, N, 128):
                d = np.abs(xx - cx) + np.abs(yy - cy)
                carve = np.maximum(carve, np.clip(1 - np.abs(d - 34) / 3.5, 0, 1))
                carve = np.maximum(carve, np.clip(1 - np.abs(d - 18) / 3.0, 0, 1))
            for dy in (-46, 46):
                carve[cy + dy - 2:cy + dy + 2, :] = 1
    grain = tile_noise(N, 3.0, 6, 4311)
    pits = smooth(0.7, 0.85, tile_noise(N, 22.0, 2, 4313))
    strata = tile_noise(N, 1.0, 3, 4315)
    height = height - seams * 1.3 - carve * 0.6 - pits * 0.35 + (grain - 0.5) * 0.25
    base = 0.84 + tone * 0.06 + (grain - 0.5) * 0.14 + (strata - 0.5) * 0.06
    color = np.stack([base, base * 0.985, base * 0.96], -1)
    color *= (1 - 0.6 * np.clip(seams * (0.6 + 0.6 * grain), 0, 1))[..., None]
    color *= (1 - 0.45 * carve)[..., None]
    color *= (1 - 0.25 * pits)[..., None]
    rough = 0.86 + (grain - 0.5) * 0.15 - carve * 0.1
    metal = np.zeros((N, N), np.float32)
    write("ciudad_piedra", color, height, rough, metal, 4.5)


# ---------------------------------------------------------------------------
def gen_suelo():
    rng = np.random.default_rng(4401)
    xx, yy = grid()
    # hexágonos enlosables: 8 columnas × 8 filas (128 × 128 por celda; filas alternas desplazadas)
    cw, ch = 128.0, 128.0
    row = np.floor(yy / ch)
    xs = (xx + (row % 2) * cw / 2) % N
    cx = (np.floor(xs / cw) + 0.5) * cw
    cy = (row + 0.5) * ch
    dx, dy = np.abs(xs - cx) / (cw / 2), np.abs(yy - cy) / (ch / 2)
    d = np.maximum(dx, dx * 0.5 + dy * 0.9)  # distancia hexagonal aproximada (1 en el borde)
    edge = np.clip((1 - d), 0, 1) * 64
    seams = np.exp(-edge / 2.2)
    cell = (np.floor(xs / cw) + row * 8).astype(int) % 64
    tones = rng.uniform(-1, 1, 64)
    tone = tones[cell]
    height = smooth(0, 9, edge) * 0.7 + tone * 0.06
    studs = np.zeros((N, N), np.float32)
    # tapas técnicas redondas en algunas losas
    for k in rng.choice(64, 5, replace=False):
        r_, c_ = divmod(int(k), 8)
        ccx = (c_ + 0.5) * cw - (r_ % 2) * cw / 2
        ccy = (r_ + 0.5) * ch
        dd = np.sqrt(((xx - ccx + N / 2) % N - N / 2) ** 2 + (yy - ccy) ** 2)
        ring = np.clip(1 - np.abs(dd - 30) / 2.5, 0, 1)
        seams = np.maximum(seams, ring * 0.9)
        height -= ring * 0.5
        for a in range(6):
            stamp_disc(studs, (ccx + np.cos(a * np.pi / 3) * 20) % N, ccy + np.sin(a * np.pi / 3) * 20, 3.5, 1.0)
    wear = tile_noise(N, 2.0, 6, 4411)
    speck = tile_noise(N, 24.0, 2, 4413)
    grime = np.clip(seams * (0.5 + 0.7 * wear), 0, 1)
    height = height - seams * 0.9 + studs * 0.5 + (speck - 0.5) * 0.05
    base = 0.8 + tone * 0.05 + (wear - 0.5) * 0.1 + (speck - 0.5) * 0.04
    color = np.stack([base, base, base], -1) * (1 - 0.6 * grime)[..., None]
    rough = 0.62 + (wear - 0.5) * 0.25 + grime * 0.25
    metal = 0.15 + studs * 0.6
    write("ciudad_suelo", color, height, rough, metal, 3.6)


JOBS = {"panel": gen_panel, "fachada": gen_fachada, "piedra": gen_piedra, "suelo": gen_suelo}


def preview():
    """docs/planetas/ciudad-texturas.jpg: las cuatro, iluminadas con su normal (para revisar de un vistazo)."""
    tiles = []
    L = np.array([-0.5, 0.55, 0.67])
    L = L / np.linalg.norm(L)
    for key in JOBS:
        c = np.asarray(Image.open(OUT / f"ciudad_{key}_color.png").convert("RGB"), np.float32) / 255
        nm = np.asarray(Image.open(OUT / f"ciudad_{key}_normal.png").convert("RGB"), np.float32) / 255 * 2 - 1
        lam = np.clip((nm * L).sum(-1), 0, 1)[..., None]
        img = np.clip(c * (0.35 + 0.9 * lam), 0, 1)
        tiles.append(Image.fromarray((img * 255).astype(np.uint8)).resize((512, 512), Image.LANCZOS))
    sheet = Image.new("RGB", (2048, 512))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * 512, 0))
    path = ROOT / "docs" / "planetas" / "ciudad-texturas.jpg"
    sheet.save(path, quality=88)
    print("  ✓", path.relative_to(ROOT))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    for key, fn in JOBS.items():
        if not args or key in args:
            print("·", key)
            fn()
    if "--preview" in sys.argv:
        preview()
