#!/usr/bin/env python3
"""Mapa desde arriba del Cañón de Dorada (docs/mar/v2-mapa-canon.jpg): la altura de la roca y del fondo
(de scripts/map/canon-export.luau), las regiones A-E, las piezas del kit, las luces y las cámaras de la
revisión con su número. «VISTA PREVIA, NO ES ROBLOX»: es un plano, no una captura.

Uso (desde la carpeta roblox/):
    lune run scripts/map/canon-export.luau /tmp/canon.json /tmp/canon.vox
    python3 scripts/map/canon_mapa.py /tmp/canon.json docs/mar/v2-mapa-canon.jpg
"""
import json
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

data = json.load(open(sys.argv[1], encoding="utf-8"))
out = sys.argv[2]
m = data["Voxels"]
nx, nz, ny = m["NX"], m["NZ"], m["NY"]
raw = np.frombuffer(open(m["File"], "rb").read(), dtype=np.uint8).reshape((ny, nz, nx))
solid = raw > 0
# la altura de lo más alto sólido en cada columna, y su material
top = np.full((nz, nx), -1, int)
for j in range(ny):
    top[solid[j]] = j
mat = np.zeros((nz, nx), np.uint8)
kk, ii = np.nonzero(top >= 0)
mat[kk, ii] = raw[top[kk, ii], kk, ii]
height = m["Y0"] + (top + 0.5) * m["Step"]
colors = {0: (20, 60, 90), 1: (204, 186, 146), 2: (118, 116, 110), 3: (198, 190, 166), 4: (190, 166, 122), 5: (130, 110, 80), 6: (78, 74, 64), 7: (232, 214, 172)}
img = np.zeros((nz, nx, 3), np.float32)
for code, c in colors.items():
    img[mat == code] = c
# sombreado por altura (más hondo, más oscuro y azul) y relieve (luz del noroeste)
k = np.clip((height + 150) / 150, 0, 1)[..., None]
deep = np.array((8, 30, 60), np.float32)
img = img * (0.35 + 0.65 * k) + deep * (1 - k) * 0.5
gz, gx = np.gradient(height)
shade = np.clip(1 + (gx * -0.5 + gz * -0.5) * 0.08, 0.55, 1.35)[..., None]
img = np.clip(img * shade, 0, 255).astype(np.uint8)
im = Image.fromarray(img, "RGB")
S = 3
im = im.resize((nx * S, nz * S), Image.NEAREST)
d = ImageDraw.Draw(im)
try:
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
    f2 = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
except OSError:
    f = f2 = ImageFont.load_default()


def px(x, z):
    return ((x - m["X0"]) / m["Step"] * S, (z - m["Z0"]) / m["Step"] * S)


groups = {"Jardin": (255, 220, 120), "Labio": (255, 180, 120), "Paredes": (255, 130, 160), "Kelp": (150, 200, 90), "Cueva": (120, 255, 220), "Ruinas": (120, 220, 255), "Abismo": (180, 160, 255)}
for p in data["Placements"]:
    x, y = px(p["X"], p["Z"])
    c = groups.get(p["Group"], (255, 255, 255))
    r = 2 if p["Scale"] < 3 else 3
    if p["Kind"] == "Piramide":
        r = 12
    d.ellipse([x - r, y - r, x + r, y + r], fill=c)
for l in data["Lights"]:
    x, y = px(l["X"], l["Z"])
    d.ellipse([x - 7, y - 7, x + 7, y + 7], outline=(255, 255, 255), width=2)
for i, cam in enumerate(data["Cameras"]):
    x, y = px(cam["X"], cam["Z"])
    yaw = math.radians(cam["Yaw"])
    d.line([x, y, x + math.cos(yaw) * 26, y + math.sin(yaw) * 26], fill=(255, 255, 255), width=3)
    d.ellipse([x - 9, y - 9, x + 9, y + 9], fill=(20, 20, 30), outline=(255, 255, 255), width=2)
    d.text((x - 5 if i < 9 else x - 9, y - 9), str(i + 1), fill=(255, 255, 255), font=f2)
labels = [("B · jardín de coral", 4262, -420), ("A · arrecife exterior (pared norte)", 4420, -470), ("C · Cueva de la Luz", 4470, -200), ("E · Pirámide Hundida", 4620, -400), ("D · borde del abismo", 4770, -470), ("PLAYA DORADA", 4185, -60)]
for text, x, z in labels:
    X, Y = px(x, z)
    d.text((X, Y), text, fill=(255, 255, 255), font=f, stroke_width=3, stroke_fill=(0, 0, 0))
W, H = im.size
bar = Image.new("RGB", (W, 40), (10, 14, 22))
bd = ImageDraw.Draw(bar)
bd.text((10, 9), "VISTA PREVIA, NO ES ROBLOX · Cañón de Dorada desde arriba (norte arriba = Z menor; el mar abierto a la derecha)", fill=(255, 210, 80), font=f2)
foot = Image.new("RGB", (W, 30), (10, 14, 22))
fd = ImageDraw.Draw(foot)
fd.text((10, 7), "Color = material de arriba (arena dorada, roca, caliza, arenisca, fango) y oscuro = más hondo · puntos = piezas del kit · ○ = luces · números = cámaras de la revisión", fill=(200, 220, 235), font=f2)
final = Image.new("RGB", (W, H + 70))
final.paste(bar, (0, 0))
final.paste(im, (0, 40))
final.paste(foot, (0, H + 40))
final.save(out, quality=88)
print(out)
