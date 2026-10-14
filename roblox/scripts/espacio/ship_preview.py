"""Vista previa de la nave «Caza» (Espacio AAA) desde arriba, de lado y desde atrás, con las piezas de
verdad (shared/AirCombat/ShipModel.specs). Proyección ortográfica sencilla, no es una captura de Roblox.

    lune run scripts/espacio/ship-dump.luau > /tmp/ship.json
    python3 scripts/espacio/ship_preview.py /tmp/ship.json docs/espacio-aaa/nave-aaa.jpg
"""
import json
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def hull(points):
    pts = sorted(set(points))
    if len(pts) < 3:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def corners(part):
    c = part["Corners"]
    if part["Class"] == "WedgePart":
        # (la cuña: sin las dos esquinas de arriba-delante; orden de los bucles: x, y, z)
        return [c[i] for i in (0, 1, 3, 4, 5, 7)]
    return c


VIEWS = {
    "DESDE ARRIBA": (lambda p: (p[0], p[2]), lambda p: p[1]),
    "DE LADO": (lambda p: (p[2], -p[1]), lambda p: -p[0]),
    "DESDE ATRÁS": (lambda p: (p[0], -p[1]), lambda p: p[2]),
}


def draw_view(parts, proj, depth, size, scale):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    g = ImageDraw.Draw(glow)
    cx, cy = size[0] / 2, size[1] / 2
    order = sorted(parts, key=lambda p: depth(p["Center"]))
    for p in order:
        pts = [proj(c) for c in corners(p)]
        poly = hull([(cx + x * scale, cy + y * scale) for x, y in pts])
        col = tuple(p["Color"])
        if p["Glass"]:
            fill = col + (150,)
        else:
            fill = col + (255,)
        if p["Neon"]:
            g.polygon(poly, fill=(80, 170, 255, 255))
        d.polygon(poly, fill=fill, outline=(20, 24, 34, 255))
    glow = glow.filter(ImageFilter.GaussianBlur(scale * 1.2))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(glow)
    out.alpha_composite(img)
    return out


def main():
    parts = json.load(open(sys.argv[1]))
    W, H = 1500, 560
    bg = Image.new("RGB", (W, H), (8, 12, 26))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        d.line([(0, y), (W, y)], fill=(8 + y // 30, 12 + y // 40, 30 + y // 20))
    f = ImageFont.truetype(FONT, 22)
    x = 0
    widths = {"DESDE ARRIBA": 560, "DE LADO": 560, "DESDE ATRÁS": 380}
    for name, (proj, depth) in VIEWS.items():
        w = widths[name]
        view = draw_view(parts, proj, depth, (w, 480), 15 if name != "DESDE ATRÁS" else 13)
        bg.paste(view, (x, 40), view)
        d.text((x + w / 2, 20), name, font=f, fill=(120, 220, 255), anchor="mm")
        x += w
    d.text((W / 2, H - 18), "Heroes of History · nave «Caza» (Espacio AAA): tres cascos, morro largo, alas afiladas y tres motores azules · piezas de verdad, vista sencilla (no es captura de Roblox)", font=ImageFont.truetype(FONT, 14), fill=(190, 200, 215), anchor="mm")
    bg.save(sys.argv[2], quality=90)
    print("ok", sys.argv[2])


if __name__ == "__main__":
    main()
