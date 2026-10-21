#!/usr/bin/env python3
"""Hojas de comparación de las vistas previas del fondo marino v3 (docs/mar/v3/).

    python3 scripts/map/orillas_hojas.py DIR_RONDAS docs/mar/v3
      DIR_RONDAS: carpeta con antes-N.jpg y rN-M.jpg (N = ronda, M = plano)
Escribe docs/mar/v3/antes-despues.jpg (cada plano: antes | después) y docs/mar/v3/rondas.jpg (cada plano: las
rondas en fila). Las imágenes llevan ya «VISTA PREVIA, NO ES ROBLOX».
"""
import glob
import os
import re
import sys

from PIL import Image, ImageDraw


def grid(rows, cell_w, out, titles=None):
    if not rows:
        return
    h = None
    lines = []
    for row in rows:
        ims = [Image.open(p).convert("RGB") for p in row]
        ims = [im.resize((cell_w, int(im.height * cell_w / im.width))) for im in ims]
        h = ims[0].height
        lines.append(ims)
    cols = max(len(r) for r in lines)
    sheet = Image.new("RGB", (cols * cell_w, len(lines) * h + (24 if titles else 0)), (12, 18, 28))
    d = ImageDraw.Draw(sheet)
    y0 = 0
    if titles:
        for i, t in enumerate(titles):
            d.text((i * cell_w + 8, 6), t, fill=(255, 255, 255))
        y0 = 24
    for j, ims in enumerate(lines):
        for i, im in enumerate(ims):
            sheet.paste(im, (i * cell_w, y0 + j * h))
    sheet.save(out, quality=86)
    print("->", out)


def main():
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(dst, exist_ok=True)
    rounds = sorted({int(m.group(1)) for p in glob.glob(os.path.join(src, "r*-*.jpg")) if (m := re.match(r"r(\d+)-\d+\.jpg", os.path.basename(p)))})
    last = max(rounds)
    pairs = []
    for k in range(1, 7):
        a, b = os.path.join(src, f"antes-{k}.jpg"), os.path.join(src, f"r{last}-{k}.jpg")
        if os.path.exists(a) and os.path.exists(b):
            pairs.append([a, b])
    grid(pairs, 800, os.path.join(dst, "antes-despues.jpg"), ["ANTES (v125, aprox.)", f"DESPUÉS (ronda {last})"])
    rows = []
    for k in range(1, 7):
        row = [os.path.join(src, f"r{r}-{k}.jpg") for r in rounds if os.path.exists(os.path.join(src, f"r{r}-{k}.jpg"))]
        if row:
            rows.append(row)
    grid(rows, 520, os.path.join(dst, "rondas.jpg"), [f"ronda {r}" for r in rounds])


if __name__ == "__main__":
    main()
