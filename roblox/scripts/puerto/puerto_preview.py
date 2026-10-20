#!/usr/bin/env python3
"""Plano DESDE ARRIBA del Puerto de Valmar (sin Blender), a partir de lo que exporta
scripts/puerto/puerto-export.luau. Dibuja el mar, la tierra (CityPlan.Coast), la dársena, y cada pieza
del mapa construido desde la más baja a la más alta, con nombres de las zonas.

Uso (desde roblox/):
    lune run scripts/puerto/puerto-export.luau X.rbxl /tmp/puerto.json
    python3 scripts/puerto/puerto_preview.py /tmp/puerto.json docs/mapa/puerto-plano.png
"""
import json
import sys

from PIL import Image, ImageDraw, ImageFont

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
SCALE = 1.6  # píxeles por stud

LABELS = [
    ("DÁRSENA", 660, 3445),
    ("Muelle de contenedores", 640, 3355),
    ("Patio de contenedores", 615, 3186),
    ("Naves", 396, 3200),
    ("Control (aduana)", 495, 3168),
    ("Oficinas y torre", 836, 3205),
    ("Lonja", 404, 3337),
    ("Hielo", 347, 3360),
    ("Estación marítima", 373, 3437),
    ("Pantalán de pesca", 530, 3436),
    ("Pantalán deportivo", 520, 3528),
    ("Dique de abrigo", 790, 3640),
    ("Baliza", 712, 3576),
    ("Barca a la isla", 400, 3570),
    ("Barco de pesca (alta mar)", 640, 3746),
    ("Metro", 836, 3165),
    ("Calle del Puerto", 300, 3140),
]


def rot(cf):
    # cf = [x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22]
    return cf[0:3], [cf[3:6], cf[6:9], cf[9:12]]


def corners(p):
    (x, y, z), r = rot(p["cf"])
    sx, sy, sz = p["size"]
    pts = []
    for dx in (-0.5, 0.5):
        for dz in (-0.5, 0.5):
            lx, lz = dx * sx, dz * sz
            # mundo = R * local (sin la Y)
            wx = x + r[0][0] * lx + r[0][2] * lz
            wz = z + r[2][0] * lx + r[2][2] * lz
            pts.append((wx, wz))
    # orden del contorno
    return [pts[0], pts[1], pts[3], pts[2]]


def top_y(p):
    (_, y, _), r = rot(p["cf"])
    sx, sy, sz = p["size"]
    return y + abs(r[1][0]) * sx / 2 + abs(r[1][1]) * sy / 2 + abs(r[1][2]) * sz / 2


def main():
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    out = sys.argv[2]
    plan = data["plan"]
    x0, x1, z0, z1 = plan["Box"]
    w, h = int((x1 - x0) * SCALE), int((z1 - z0) * SCALE)
    img = Image.new("RGB", (w, h), (40, 120, 160))
    d = ImageDraw.Draw(img, "RGBA")

    def px(x, z):
        return ((x - x0) * SCALE, (z - z0) * SCALE)

    # Tierra (la costa de siempre) con una franja de arena
    coast = [px(p[0], p[1]) for p in plan["Coast"]]
    d.polygon(coast, fill=(214, 200, 160))
    # (dentro, la hierba: el mismo polígono «encogido» a ojo con la arena en la orilla)
    d.line(coast + [coast[0]], fill=(236, 222, 180), width=int(20 * SCALE))
    # Dársena (agua de verdad junto a los muelles)
    b = plan["Basin"]
    d.rectangle([px(b["X0"], b["Z0"]), px(b["X1"], b["Z1"])], fill=(34, 110, 150))

    parts = sorted(data["parts"], key=top_y)
    for p in parts:
        if p["s"] == "Ball" or p["s"] == "Cylinder":
            (x, _, z), _ = rot(p["cf"])
            r = max(p["size"][1], p["size"][2]) / 2 if p["s"] == "Cylinder" else p["size"][0] / 2
            r = max(r, 0.5)
            a, bb = px(x - r, z - r), px(x + r, z + r)
            fill = tuple(p["c"]) + (int(255 * (1 - p["t"])),)
            d.ellipse([a, bb], fill=fill)
            continue
        fill = tuple(p["c"]) + (int(255 * (1 - p["t"])),)
        ty = top_y(p)
        shade = min(1.0, 0.75 + ty / 120)
        fill = (int(fill[0] * shade), int(fill[1] * shade), int(fill[2] * shade), fill[3])
        d.polygon([px(*c) for c in corners(p)], fill=fill)

    # Rótulos
    try:
        font = ImageFont.truetype(FONT, 15)
        big = ImageFont.truetype(FONT, 24)
    except OSError:
        font = big = ImageFont.load_default()
    for text, x, z in LABELS:
        tx, tz = px(x, z)
        f = big if text == "DÁRSENA" else font
        bw = d.textlength(text, font=f)
        d.rectangle([tx - bw / 2 - 4, tz - 10, tx + bw / 2 + 4, tz + 12], fill=(0, 0, 0, 130))
        d.text((tx - bw / 2, tz - 9), text, font=f, fill=(255, 255, 255))
    title = "PUERTO DE VALMAR · plano desde arriba (mapa construido) · norte arriba"
    d.rectangle([0, 0, w, 34], fill=(0, 0, 0, 170))
    d.text((12, 6), title, font=font, fill=(255, 255, 255))
    # Escala
    d.rectangle([12, h - 26, 12 + 100 * SCALE, h - 20], fill=(255, 255, 255))
    d.text((12, h - 46), "100 studs", font=font, fill=(255, 255, 255))
    img.save(out)
    print("->", out, img.size)


if __name__ == "__main__":
    main()
