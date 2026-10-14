"""Maquetas del HUD de la nave (Espacio AAA) a partir de las zonas de verdad (UI/ShipHudLayout).

No son capturas de Roblox: dibujan cada zona en su sitio y a su tamaño (las mismas cuentas que el
juego) con un contenido de ejemplo, para ver la composición en el móvil y en el ordenador.

    lune run scripts/espacio/hud-layout-dump.luau > /tmp/layout.json
    python3 scripts/espacio/hud_mockup.py /tmp/layout.json docs/espacio-aaa
"""
import json
import math
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_R = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

CYAN = (110, 230, 255)
EDGE = (70, 200, 255)
WHITE = (235, 248, 255)
MUTED = (140, 175, 205)
ORANGE = (255, 150, 40)
RED = (255, 70, 70)
GOLD = (255, 205, 70)
GREEN = (90, 235, 140)
BLUE = (80, 170, 255)
VIOLET = (200, 130, 255)
PANEL = (6, 16, 34, 175)

BUTTON_LABELS = {
    "Fuego": ("DISPARO", (200, 60, 50)),
    "Misil": ("MISIL", (200, 120, 30)),
    "Turbo": ("IMPULSO", (220, 120, 30)),
    "FrenoNave": ("FRENO", (90, 90, 110)),
    "EsquivaNave": ("ESQUIVA", (40, 150, 170)),
    "SalirNave": ("Salir", (40, 60, 90)),
    "ValmarNave": ("VALMAR", (40, 90, 60)),
    "AccionNave": ("ATRACAR", (40, 110, 80)),
}

SLOTS = [("Cañones", "∞"), ("Misiles", "6"), ("Láser", "∞"), ("Escudo", ""), ("Camuflaje", ""), ("Salto", ""), ("Hiper", ""), ("Dron", "")]
LOCKED = {3, 4, 7}


def font(size, bold=True):
    return ImageFont.truetype(FONT if bold else FONT_R, max(6, int(size)))


def background(w, h, seed=7):
    img = Image.new("RGB", (w, h), (4, 8, 22))
    d = ImageDraw.Draw(img)
    for y in range(h):
        k = y / h
        d.line([(0, y), (w, y)], fill=(int(8 + 20 * k), int(10 + 14 * k), int(30 + 30 * (1 - k))))
    rnd = random.Random(seed)
    # nebulosa
    neb = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    nd = ImageDraw.Draw(neb)
    for _ in range(14):
        cx, cy = rnd.uniform(0.3, 1) * w, rnd.uniform(0, 0.6) * h
        r = rnd.uniform(0.08, 0.25) * w
        col = rnd.choice([(150, 80, 230, 40), (60, 170, 220, 40), (80, 110, 240, 45)])
        nd.ellipse([cx - r, cy - r * 0.6, cx + r, cy + r * 0.6], fill=col)
    neb = neb.filter(ImageFilter.GaussianBlur(w / 30))
    img.paste(neb, (0, 0), neb)
    d = ImageDraw.Draw(img)
    for _ in range(int(w * h / 1800)):
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        b = rnd.randint(120, 255)
        d.point((x, y), fill=(b, b, b))
    # planeta (Lontana, malva) a la izquierda
    pr = h * 0.55
    pc = (-pr * 0.25, h * 0.75)
    planet = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    pd = ImageDraw.Draw(planet)
    pd.ellipse([pc[0] - pr * 1.04, pc[1] - pr * 1.04, pc[0] + pr * 1.04, pc[1] + pr * 1.04], fill=(255, 190, 225, 50))
    pd.ellipse([pc[0] - pr, pc[1] - pr, pc[0] + pr, pc[1] + pr], fill=(150, 120, 150, 255))
    img.paste(planet, (0, 0), planet)
    return img


def ship(d, cx, cy, s):
    """Silueta de la nave de tres cascos vista desde atrás y arriba (como la referencia)."""
    body = (150, 160, 178)
    dark = (60, 66, 80)
    # alas
    d.polygon([(cx - 14 * s, cy + 2 * s), (cx - 60 * s, cy + 14 * s), (cx - 58 * s, cy + 18 * s), (cx - 10 * s, cy + 10 * s)], fill=dark)
    d.polygon([(cx + 14 * s, cy + 2 * s), (cx + 60 * s, cy + 14 * s), (cx + 58 * s, cy + 18 * s), (cx + 10 * s, cy + 10 * s)], fill=dark)
    # cascos laterales y central (morro largo hacia arriba)
    for x, top, wdt in ((-16, -18, 9), (16, -18, 9), (0, -46, 12)):
        d.polygon([(cx + x * s, cy + top * s), (cx + (x - wdt) * s, cy + 12 * s), (cx + (x + wdt) * s, cy + 12 * s)], fill=body)
    d.ellipse([cx - 5 * s, cy - 14 * s, cx + 5 * s, cy - 4 * s], fill=(120, 200, 255))
    # tres motores azules
    for x in (-16, 0, 16):
        r = 7 * s if x == 0 else 6 * s
        glow = Image.new("RGBA", (1, 1))
        d.ellipse([cx + x * s - r * 1.8, cy + 12 * s - r * 1.8, cx + x * s + r * 1.8, cy + 12 * s + r * 1.8], fill=(60, 140, 255))
        d.ellipse([cx + x * s - r, cy + 12 * s - r, cx + x * s + r, cy + 12 * s + r], fill=(220, 245, 255))


def panel(layer, r, k, radius=10):
    d = ImageDraw.Draw(layer)
    x, y, w, h = [v * k for v in r]
    d.rounded_rectangle([x, y, x + w, y + h], radius=radius * k, fill=PANEL, outline=EDGE + (210,), width=max(1, int(2 * k)))
    d.rectangle([x, y, x + 22 * k, y + 3 * k], fill=CYAN + (255,))
    d.rectangle([x + w - 22 * k, y + h - 3 * k, x + w, y + h], fill=CYAN + (255,))
    return x, y, w, h


def fit(d, text, f, width):
    """Corta el texto con «…» si no cabe (como TextTruncate en Roblox)."""
    if d.textlength(text, font=f) <= width:
        return text
    while text and d.textlength(text + "…", font=f) > width:
        text = text[:-1]
    return text + "…"


def padlock(d, cx, cy, s, col):
    d.arc([cx - s * 0.35, cy - s * 0.75, cx + s * 0.35, cy - s * 0.05], 180, 360, fill=col, width=max(1, int(s * 0.12)))
    d.rounded_rectangle([cx - s * 0.5, cy - s * 0.3, cx + s * 0.5, cy + s * 0.45], radius=s * 0.1, fill=col)


def star(d, cx, cy, r, col):
    pts = []
    for i in range(8):
        a = math.pi / 4 * i - math.pi / 2
        rr = r if i % 2 == 0 else r * 0.38
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d.polygon(pts, fill=col)


def bar(d, x, y, w, h, frac, color):
    d.rounded_rectangle([x, y, x + w, y + h], radius=h / 2, fill=(10, 20, 36), outline=color, width=1)
    d.rounded_rectangle([x, y, x + max(h, w * frac), y + h], radius=h / 2, fill=color)


def render(case, out_path):
    W, H = case["Size"]
    k = case["Scale"]
    touch = case["Touch"]
    up = 2 if W < 1000 else 1  # (los móviles, al doble para que se lean)
    img = background(W * up, H * up)
    k *= up
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    Z = case["Zones"]
    # Nave y un enemigo fijado (el centro queda libre)
    ship(d, W * up / 2, H * up * 0.72, 2.2 * k * (1 if not touch else 1.1))
    ex, ey = W * up * 0.47, H * up * 0.36
    d.polygon([(ex - 14 * k, ey), (ex, ey - 8 * k), (ex + 14 * k, ey), (ex, ey + 6 * k)], fill=(120, 60, 150))
    box = 50 * k
    d.rectangle([ex - box / 2, ey - box / 2, ex + box / 2, ey + box / 2], outline=RED, width=max(1, int(3 * k)))
    d.text((ex, ey - box / 2 - 4 * k), "Caza enemigo · 340 m\nAMENAZA ALTA", font=font(13 * k), fill=RED, anchor="md", align="center")
    d.text((ex, ey + box / 2 + 4 * k), "FIJADO · MISIL", font=font(13 * k), fill=RED, anchor="ma")
    # Mira (pequeña)
    mx, my = W * up / 2, H * up * 0.45
    for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
        d.line([(mx + dx * 12 * k, my + dy * 12 * k), (mx + dx * 22 * k, my + dy * 22 * k)], fill=CYAN, width=max(1, int(2 * k)))
    d.ellipse([mx - 15 * k, my - 15 * k, mx + 15 * k, my + 15 * k], outline=CYAN + (150,), width=1)
    # A · perfil
    x, y, w, h = panel(layer, Z["A"], k)
    av = h - 20 * k
    d.ellipse([x + 10 * k, y + 10 * k, x + 10 * k + av, y + 10 * k + av], fill=(30, 60, 100), outline=CYAN, width=max(1, int(3 * k)))
    d.text((x + 10 * k + av / 2, y + 10 * k + av / 2), "☺", font=font(av * 0.6), fill=WHITE, anchor="mm")
    tx = x + (112 if not touch else 100) * k
    d.text((tx, y + 8 * k), "Nv. 12", font=font(20 * k), fill=CYAN)
    d.text((tx + 86 * k, y + 8 * k), "Piloto", font=font(20 * k), fill=WHITE)
    d.text((tx, y + 40 * k), "$4.200", font=font(19 * k), fill=(120, 240, 140))
    sx0 = tx + (w - (tx - x)) / 2
    star(d, sx0 + 9 * k, y + 52 * k, 10 * k, GOLD)
    d.text((sx0 + 24 * k, y + 40 * k), "7", font=font(19 * k), fill=GOLD)
    d.text((tx, y + 68 * k), "CAZA · COMBATE · Bodega 3/40", font=font(14 * k, False), fill=MUTED)
    # B · navegación
    x, y, w, h = panel(layer, Z["B"], k)
    heading = 30
    for deg in range(0, 360, 15):
        dd = ((deg - heading + 540) % 360) - 180
        if abs(dd) <= 60:
            px = x + 10 * k + (0.5 + dd / 120) * (w - 20 * k)
            name = {0: "N", 45: "NE", 90: "E", 135: "SE", 180: "S", 225: "SO", 270: "O", 315: "NO"}.get(deg, "")
            if name:
                d.text((px, y + 6 * k), name, font=font((22 if deg % 90 == 0 else 16) * k), fill=CYAN if name == "N" else WHITE, anchor="ma")
            else:
                d.line([(px, y + 30 * k), (px, y + 38 * k)], fill=CYAN, width=max(1, int(2 * k)))
    tpx = x + 10 * k + (0.5 + 25 / 120) * (w - 20 * k)
    d.polygon([(tpx, y + 18 * k), (tpx + 7 * k, y + 25 * k), (tpx, y + 32 * k), (tpx - 7 * k, y + 25 * k)], fill=GOLD)
    d.line([(x + w / 2, y + 40 * k), (x + w / 2, y + 52 * k)], fill=WHITE, width=max(1, int(3 * k)))
    d.text((x + w / 2, y + 46 * k), "◆ Sistema Valmar", font=font(22 * k), fill=CYAN, anchor="ma")
    fz, fs = font(15 * k, False), font(12 * k)
    d.text((x + w / 2, y + 72 * k), fit(d, "Cinturón de Hierro · Campo de asteroides", fz, w * 0.54), font=fz, fill=WHITE, anchor="ma")
    d.text((x + 10 * k, y + 74 * k), fit(d, "▶ Estación Alba · 1,2 km", fs, w * 0.22 - 10 * k), font=fs, fill=GOLD)
    d.text((x + w - 10 * k, y + 74 * k), fit(d, "SALTO LISTO (X)", fs, w * 0.22 - 10 * k), font=fs, fill=VIOLET, anchor="ra")
    # C · estado
    x, y, w, h = panel(layer, Z["C"], k)
    d.text((x + 67 * k, y + 4 * k), "284", font=font(34 * k), fill=WHITE, anchor="ma")
    d.text((x + 67 * k, y + 42 * k), "KM/H", font=font(12 * k), fill=MUTED, anchor="ma")
    d.text((x + 67 * k, y + 58 * k), "COMBATE", font=font(12 * k), fill=CYAN, anchor="ma")
    colw = (w - 132 * k - (128 if touch else 148) * k - 10 * k) / 2
    rows = [("IMPULSO", ORANGE, 0.7, "70%"), ("ENERGÍA", CYAN, 0.82, "82%"), ("ESCUDO", BLUE, 0.92, "55"), ("CASCO", GREEN, 0.87, "87")]
    for i, (cap, col, frac, val) in enumerate(rows):
        cx = x + 132 * k + (i // 2) * (colw + 10 * k)
        cy = y + (6 + (i % 2) * 38) * k
        d.text((cx, cy), cap, font=font(12 * k), fill=col)
        d.text((cx + colw, cy), val, font=font(13 * k), fill=WHITE, anchor="ra")
        bar(d, cx, cy + 19 * k, colw, 9 * k, frac, col)
    rx = x + w - (108 if touch else 124) * k
    d.text((rx, y + 6 * k), "MISILES", font=font(12 * k), fill=ORANGE)
    d.text((rx, y + 22 * k), "6/6", font=font(18 * k), fill=WHITE)
    d.text((rx, y + 44 * k), "CAÑONES", font=font(12 * k), fill=CYAN)
    bar(d, rx, y + 64 * k, (96 if touch else 116) * k, 7 * k, 0.3, RED)
    # J · aviso
    x, y, w, h = [v * k for v in Z["J"]]
    d.text((x + w / 2, y + h / 2), "⚔ EN COMBATE", font=font(17 * k), fill=RED, anchor="mm")
    # D · radar
    x, y, w, h = [v * k for v in Z["D"]]
    d.ellipse([x, y, x + w, y + h], fill=(6, 20, 34, 200), outline=EDGE, width=max(1, int(3 * k)))
    for f in (0.66, 0.33):
        d.ellipse([x + w * (1 - f) / 2, y + h * (1 - f) / 2, x + w * (1 + f) / 2, y + h * (1 + f) / 2], outline=CYAN + (110,), width=1)
    cx, cy = x + w / 2, y + h / 2
    d.polygon([(cx, cy - 8 * k), (cx - 6 * k, cy + 6 * k), (cx + 6 * k, cy + 6 * k)], fill=WHITE)
    for (bx, by, col, shape) in ((0.0, -0.55, (255, 210, 60), "r"), (0.35, -0.3, RED, "r"), (-0.2, -0.65, RED, "r"), (0.6, 0.2, (110, 255, 190), "s"), (-0.5, 0.35, (170, 170, 185), "o"), (-0.35, -0.1, (90, 170, 255), "c")):
        px, py = cx + bx * w * 0.44, cy + by * h * 0.44
        s = 6 * k
        if shape == "r":
            d.polygon([(px, py - s), (px + s, py), (px, py + s), (px - s, py)], fill=col)
        elif shape == "s":
            d.rectangle([px - s, py - s, px + s, py + s], fill=col)
        elif shape == "o":
            d.ellipse([px - s * 1.4, py - s * 1.4, px + s * 1.4, py + s * 1.4], outline=col, width=2)
        else:
            d.ellipse([px - s * 0.8, py - s * 0.8, px + s * 0.8, py + s * 0.8], fill=col)
    d.text((cx + 0.3 * w * 0.43, y + 0.06 * h), "N", font=font(16 * k), fill=WHITE, anchor="mm")
    d.text((cx, y + h - 10 * k), "RADAR 0,4 km", font=font(11 * k), fill=CYAN, anchor="md")
    # E · misiones
    x, y, w, h = panel(layer, Z["E"], k)
    mrows = [("PRINCIPAL", GOLD, "Rumbo a Lontana", "Vuela a la órbita de Lontana", "12 km"), ("SECUNDARIA", CYAN, "Limpieza de drones", "2/6 · Sector Brasa", "3,1 km"), ("EVENTO", RED, "⚠ Patrullas en el Sector Brasa", "", ""), ("SECUNDARIA", CYAN, "Carga para Cénit", "Entregar · Estación Cénit", "5 km")]
    n = 3 if touch else 4
    rh = (h - 8 * k) / n
    for i in range(n):
        kind, col, title, step, right = mrows[i]
        ry = y + 4 * k + i * rh
        d.polygon([(x + 17 * k, ry + 8 * k), (x + 22 * k, ry + 13 * k), (x + 17 * k, ry + 18 * k), (x + 12 * k, ry + 13 * k)], fill=col)
        d.text((x + 30 * k, ry + 2 * k), kind, font=font(12 * k), fill=col)
        d.text((x + 30 * k, ry + 19 * k), title, font=font(15 * k), fill=WHITE)
        d.text((x + w - 10 * k, ry + 19 * k), right, font=font(13 * k), fill=MUTED, anchor="ra")
        if rh >= 54 * k and step:
            d.text((x + 30 * k, ry + 38 * k), step, font=font(12 * k, False), fill=MUTED)
    # G · teclas (ordenador)
    if "G" in Z:
        x, y, w, h = panel(layer, Z["G"], k)
        d.text((x + 12 * k, y + 6 * k), "MANDOS DE VUELO", font=font(13 * k), fill=CYAN)
        hints = [("W/S", "Motor"), ("A/D", "Lateral"), ("Espacio/Alt", "Subir / bajar"), ("Q/E", "Alabeo"), ("Clic", "Disparar"), ("2", "Misil"), ("Shift", "Impulso"), ("Ctrl", "Freno"), ("C", "Esquiva"), ("7", "Hipervelocidad"), ("X", "Salto cuántico"), ("B", "Bajarse")]
        cw = (w - 24 * k - 8 * k) / 2
        for i, (key, txt) in enumerate(hints):
            cx = x + 12 * k + (i % 2) * (cw + 8 * k)
            cy = y + 28 * k + (i // 2) * 30 * k
            d.rounded_rectangle([cx, cy + 2 * k, cx + 64 * k, cy + 26 * k], radius=5 * k, fill=(20, 40, 70), outline=EDGE)
            d.text((cx + 32 * k, cy + 14 * k), key, font=font(11 * k), fill=WHITE, anchor="mm")
            d.text((cx + 70 * k, cy + 14 * k), txt, font=font(12 * k, False), fill=WHITE, anchor="lm")
    if "I" in Z:
        x, y, w, h = panel(layer, Z["I"], k)
        for i, (key, txt) in enumerate((("Clic", "DISPARO"), ("2", "MISIL"), ("Shift", "IMPULSO"), ("Ctrl", "FRENO"), ("C", "ESQUIVA"), ("B", "Salir"))):
            d.text((x + 14 * k, y + (10 + i * 30) * k), key, font=font(13 * k), fill=CYAN)
            d.text((x + 90 * k, y + (10 + i * 30) * k), txt, font=font(13 * k), fill=WHITE)
    # H · ranuras
    x, y, w, h = panel(layer, Z["H"], k)
    sz, gap = case["Slot"] * k, case["Gap"] * k
    for i, (name, count) in enumerate(SLOTS):
        sx = x + 8 * k + i * (sz + gap)
        sy = y + 6 * k
        locked = i in LOCKED
        sel = i == 0
        d.rounded_rectangle([sx, sy, sx + sz, sy + sz], radius=10 * k, fill=(14, 18, 26) if locked else (8, 22, 44), outline=WHITE if sel else ((110, 120, 140) if locked else EDGE), width=max(1, int((3 if sel else 1.5) * k)))
        if locked:
            padlock(d, sx + sz / 2, sy + sz * 0.5, sz * 0.4, (110, 120, 140))
        else:
            glyph = ["≡", "➚", "╱", "", "", "◎", "»»", ""][i]
            d.text((sx + sz / 2, sy + sz * 0.45), glyph, font=font(sz * 0.38), fill=CYAN, anchor="mm")
        if not touch:
            d.text((sx + 6 * k, sy + 3 * k), str(i + 1), font=font(13 * k), fill=MUTED)
        if count:
            d.text((sx + sz - 6 * k, sy + 3 * k), count, font=font(13 * k), fill=WHITE, anchor="ra")
        if i == 6:
            d.rectangle([sx + 2, sy + sz * 0.6, sx + sz - 2, sy + sz - 2], fill=(0, 0, 0, 120))
        d.text((sx + sz / 2, sy + sz + 4 * k), "Próximamente" if locked else name, font=font(11 * k), fill=MUTED if locked else WHITE, anchor="ma")
    # Letrero (hipervelocidad)
    x, y, w, h = panel(layer, Z["Prompt"], k)
    d.text((x + 16 * k, y + 4 * k), "HIPERVELOCIDAD", font=font(19 * k), fill=ORANGE)
    d.text((x + 16 * k, y + 28 * k), "Mantén Shift para activar" if not touch else "Toca la ranura 7", font=font(13 * k, False), fill=WHITE)
    bar(d, x + 16 * k, y + h - 8 * k, w - 32 * k, 4 * k, 0.45, ORANGE)
    # Táctil: botones grandes y palanca
    for bid, r in case.get("Buttons", {}).items():
        label, col = BUTTON_LABELS.get(bid, (bid, (40, 60, 90)))
        bx, by, bw, bh = [v * k for v in r]
        d.ellipse([bx, by, bx + bw, by + bh], fill=col + (200,), outline=CYAN, width=max(1, int(3 * k)))
        d.text((bx + bw / 2, by + bh / 2), label, font=font(min(bw, bh) * 0.17), fill=WHITE, anchor="mm")
    st = case.get("Stick")
    if st:
        sx, sy, sw, sh = [v * k for v in st]
        d.ellipse([sx, sy, sx + sw, sy + sh], fill=(10, 24, 48, 140), outline=CYAN, width=max(1, int(3 * k)))
        d.ellipse([sx + sw * 0.3, sy + sh * 0.3, sx + sw * 0.7, sy + sh * 0.7], fill=(200, 240, 255, 220))
        d.text((sx + sw / 2, sy + sh + 6 * k), "ARRASTRA PARA DIRIGIR", font=font(16 * k), fill=(200, 240, 255), anchor="ma")
    img.paste(layer, (0, 0), layer)
    # pie de foto (debajo de la pantalla, sin tapar nada)
    band = 24 * up
    full = Image.new("RGB", (img.size[0], img.size[1] + band), (0, 0, 0))
    full.paste(img, (0, 0))
    d2 = ImageDraw.Draw(full)
    title = "Heroes of History · HUD de la nave · %dx%d (%s) · maqueta de las zonas de verdad (no es captura de Roblox)" % (W, H, "móvil" if touch else "ordenador")
    d2.text((8 * up, img.size[1] + band / 2), title, font=font(11 * up, False), fill=(200, 210, 220), anchor="lm")
    full.save(out_path, quality=88)
    print("ok", out_path, img.size)


if __name__ == "__main__":
    data = json.load(open(sys.argv[1]))
    out = sys.argv[2]
    for case in data:
        W, H = case["Size"]
        render(case, "%s/hud-%dx%d.jpg" % (out, W, H))
