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
    "BengalasNave": ("BENGALAS", (170, 110, 40)),
    "ObjetivoNave": ("OBJETIVO", (150, 50, 60)),
}

SLOTS = [("Cañones", "∞"), ("Misiles", "6"), ("Láser", "∞"), ("Sobrecarga", ""), ("Camuflaje", ""), ("Salto", ""), ("Hiper", ""), ("Dron", "")]
LOCKED = {7}  # (el dron, hasta comprar uno en el taller de una estación)
LOCKED_NOTE = "Desbloquear en estación"


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
    # planeta (Tefra, malva) a la izquierda
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


def arc_ticks(d, x, y, w, h, n, a0, a1, radius, k, lit, col, right=False):
    """Rayitas de un arco en un cuadrado del alto del marco (como ShipHudLayout.arc)."""
    side = h
    ox = x + w - side if right else x
    for i in range(n):
        a = math.radians(a0 + (a1 - a0) * (i / (n - 1)))
        cx, cy = ox + side * (0.5 + math.cos(a) * radius), y + side * (0.5 + math.sin(a) * radius)
        dx, dy = math.cos(a) * 6 * k, math.sin(a) * 6 * k
        c = col if i < lit else (40, 60, 90)
        d.line([(cx - dx, cy - dy), (cx + dx, cy + dy)], fill=c, width=max(1, int(4 * k)))


def key_chip(d, x, y, w, h, text, k, size=11):
    d.rounded_rectangle([x, y, x + w, y + h], radius=4 * k, fill=(20, 40, 70), outline=EDGE)
    d.text((x + w / 2, y + h / 2), text, font=font(size * k), fill=WHITE, anchor="mm")


def plan_ship(d, cx, cy, s, col=(170, 200, 230)):
    """La nave en planta (esquema de abajo a la izquierda y los atajos)."""
    d.rectangle([cx - 0.05 * s, cy - 0.45 * s, cx + 0.05 * s, cy + 0.45 * s], fill=col)
    d.polygon([(cx - 0.45 * s, cy + 0.2 * s), (cx, cy - 0.05 * s), (cx + 0.45 * s, cy + 0.2 * s), (cx + 0.45 * s, cy + 0.25 * s), (cx - 0.45 * s, cy + 0.25 * s)], fill=col)
    for sx in (-0.2, 0.2):
        d.polygon([(cx + sx * s, cy - 0.3 * s), (cx + (sx - 0.04) * s, cy + 0.35 * s), (cx + (sx + 0.04) * s, cy + 0.35 * s)], fill=col)
    d.ellipse([cx - 0.06 * s, cy - 0.27 * s, cx + 0.06 * s, cy - 0.13 * s], fill=CYAN)


# (los textos de las teclas, como ShipKeys.groupHints)
FLIGHT = [("W/S", "Motor (acelerar / frenar)"), ("A/D", "Lateral"), ("Espacio/Alt", "Subir / bajar"), ("Shift", "Impulso / hipervelocidad"), ("Ctrl", "Frenar (doble: emergencia)"), ("Q", "Giro izquierda"), ("E", "Giro derecha"), ("Clic", "Disparar"), ("2", "Misil"), ("R", "Recargar armas"), ("Tab", "Cambiar de objetivo"), ("F", "Interactuar / atracar")]
SPECIAL = [("C", "Esquivar / rodar"), ("X", "Salto cuántico"), ("7", "Hipervelocidad"), ("Z", "Camuflaje"), ("4", "Sobrecarga del escudo"), ("8", "Dron"), ("K", "Bengalas"), ("T", "Modo combate / crucero / …"), ("Y", "Asistencia de vuelo"), ("B", "Salir / abandonar nave")]


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
    ex, ey = W * up * 0.47, H * up * 0.33
    d.polygon([(ex - 14 * k, ey), (ex, ey - 8 * k), (ex + 14 * k, ey), (ex, ey + 6 * k)], fill=(120, 60, 150))
    box = 50 * k
    L = 15 * k
    for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
        cx, cy = ex + sx * box / 2, ey + sy * box / 2
        d.line([(cx, cy), (cx - sx * L, cy)], fill=RED, width=max(1, int(3 * k)))
        d.line([(cx, cy), (cx, cy - sy * L)], fill=RED, width=max(1, int(3 * k)))
    d.text((ex - box / 2, ey - box / 2 - 12 * k), "Caza · Nv. 3", font=font(13 * k), fill=RED, anchor="ls")
    bar(d, ex - box / 2, ey - box / 2 - 9 * k, 90 * k, 5 * k, 0.7, RED)
    d.text((ex + box / 2 + 6 * k, ey), "340 m", font=font(12 * k), fill=WHITE, anchor="lm")
    d.text((ex, ey + box / 2 + 4 * k), "FIJADO · MISIL", font=font(12 * k), fill=RED, anchor="ma")
    # Mira con su aro
    mx, my = W * up / 2, H * up * 0.45
    for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
        d.line([(mx + dx * 14 * k, my + dy * 14 * k), (mx + dx * 26 * k, my + dy * 26 * k)], fill=CYAN, width=max(1, int(2 * k)))
    d.ellipse([mx - 16 * k, my - 16 * k, mx + 16 * k, my + 16 * k], outline=CYAN, width=max(1, int(2 * k)))
    d.ellipse([mx - 42 * k, my - 42 * k, mx + 42 * k, my + 42 * k], outline=CYAN + (70,), width=1)
    # A · piloto
    x, y, w, h = panel(layer, Z["A"], k)
    av = h - 20 * k
    d.ellipse([x + 10 * k, y + 10 * k, x + 10 * k + av, y + 10 * k + av], fill=(30, 60, 100), outline=CYAN, width=max(1, int(3 * k)))
    d.text((x + 10 * k + av / 2, y + 10 * k + av / 2), "☺", font=font(av * 0.6), fill=WHITE, anchor="mm")
    tx = x + (104 if touch else 120) * k
    d.text((tx, y + 6 * k), "Nv. 12", font=font(20 * k), fill=CYAN)
    d.text((tx + 80 * k, y + 6 * k), "Piloto", font=font(20 * k), fill=WHITE)
    d.text((x + w - 12 * k, y + 6 * k), "$4.200", font=font(19 * k), fill=(120, 240, 140), anchor="ra")
    by, step, bw = (36, 13, 150) if touch else (40, 15, 180)
    for i, (icon, col, frac) in enumerate((("♥", (255, 80, 80), 0.87), ("◈", BLUE, 0.92), ("⚡", (230, 230, 80), 0.82))):
        yy = y + (by + i * step) * k
        d.text((tx, yy - 3 * k), icon, font=font(11 * k), fill=col)
        bar(d, tx + 16 * k, yy, bw * k, 7 * k, frac, col)
    if touch:
        d.text((x + w - 12 * k, y + by * k), "14:27", font=font(14 * k), fill=MUTED, anchor="ra")
    else:
        d.text((tx + (bw + 26) * k, y + (by - 4) * k), "CAZA · COMBATE", font=font(12 * k, False), fill=MUTED)
    ry = y + (76 if touch else 90) * k
    rw = (w - (tx - x) - 12 * k) / 3
    for i, (txt, col) in enumerate((("✨ 7", GOLD), ("⛏ 3/40", (200, 210, 225)), ("💎 2", (150, 210, 255)))):
        rx = tx + i * rw
        d.rounded_rectangle([rx, ry, rx + rw - 6 * k, ry + 24 * k], radius=6 * k, fill=(10, 26, 50), outline=EDGE + (120,))
        d.text((rx + (rw - 6 * k) / 2, ry + 12 * k), txt.replace("💎", "◆").replace("⛏", "▲").replace("✨", "✦"), font=font(15 * k), fill=col, anchor="mm")
    if "Help" in Z:
        hx, hy, hw, hh = panel(layer, Z["Help"], k)
        d.text((hx + hw / 2, hy + hh / 2), "?", font=font(30 * k), fill=CYAN, anchor="mm")
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
    for bx, col, s in ((25, GOLD, 7), (-14, RED, 5), (48, CYAN, 5)):
        tpx = x + 10 * k + (0.5 + bx / 120) * (w - 20 * k)
        d.polygon([(tpx, y + 18 * k), (tpx + s * k, y + 25 * k), (tpx, y + 32 * k), (tpx - s * k, y + 25 * k)], fill=col)
    d.line([(x + w / 2, y + 40 * k), (x + w / 2, y + 52 * k)], fill=WHITE, width=max(1, int(3 * k)))
    d.text((x + w / 2, y + 46 * k), "◆ Sistema Valmar", font=font(22 * k), fill=CYAN, anchor="ma")
    fz = font(15 * k, False)
    d.text((x + w / 2, y + 71 * k), fit(d, "Cinturón de Hierro · Campo de asteroides", fz, w - 24 * k), font=fz, fill=WHITE, anchor="ma")
    d.text((x + w / 2, y + 91 * k), "▶ Estación Alba · 1,2 km", font=font(13 * k), fill=GOLD, anchor="ma")
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
    for (bx, by2, col, shape) in ((0.0, -0.55, (255, 210, 60), "r"), (0.35, -0.3, RED, "r"), (-0.2, -0.65, RED, "r"), (0.6, 0.2, (110, 255, 190), "s"), (-0.5, 0.35, (170, 170, 185), "o"), (-0.35, -0.1, (90, 170, 255), "c")):
        px, py = cx + bx * w * 0.44, cy + by2 * h * 0.44
        s = 6 * k
        if shape == "r":
            d.polygon([(px, py - s), (px + s, py), (px, py + s), (px - s, py)], fill=col)
        elif shape == "s":
            d.rectangle([px - s, py - s, px + s, py + s], fill=col)
        elif shape == "o":
            d.ellipse([px - s * 1.4, py - s * 1.4, px + s * 1.4, py + s * 1.4], outline=col, width=2)
        else:
            d.ellipse([px - s * 0.8, py - s * 0.8, px + s * 0.8, py + s * 0.8], fill=col)
    for letter, off in (("N", 0), ("E", 90), ("S", 180), ("O", 270)):
        a = math.radians(off - heading)
        d.text((cx + math.sin(a) * w * 0.43, cy - math.cos(a) * h * 0.43), letter, font=font((16 if letter == "N" else 12) * k), fill=WHITE if letter == "N" else MUTED, anchor="mm")
    d.text((cx, y + h - 10 * k), "RADAR 0,4 km", font=font(11 * k), fill=CYAN, anchor="md")
    # E · misiones (principal, secundaria, evento global con reloj)
    x, y, w, h = panel(layer, Z["E"], k)
    mrows = [("PRINCIPAL", GOLD, "Rumbo a Tefra", "Vuela a la órbita de Tefra", "12 km"), ("SECUNDARIA", CYAN, "Limpieza de drones", "2/6 · Sector Brasa", "3,1 km"), ("EVENTO GLOBAL", RED, "Tormenta de asteroides en Campo Brasa", "Termina en 03:10 · minar da el doble", "03:10")]
    rh = (h - 8 * k - (0 if touch else 16 * k)) / 3
    for i, (kind, col, title, stp, right) in enumerate(mrows):
        ry2 = y + 4 * k + i * rh
        d.polygon([(x + 17 * k, ry2 + 8 * k), (x + 22 * k, ry2 + 13 * k), (x + 17 * k, ry2 + 18 * k), (x + 12 * k, ry2 + 13 * k)], fill=col)
        d.text((x + 30 * k, ry2 + 2 * k), kind, font=font(12 * k), fill=col)
        ft = font(15 * k)
        d.text((x + 30 * k, ry2 + 19 * k), fit(d, title, ft, w - 120 * k), font=ft, fill=WHITE)
        d.text((x + w - 10 * k, ry2 + 19 * k), right, font=font(13 * k), fill=MUTED, anchor="ra")
        if rh >= 54 * k:
            d.text((x + 30 * k, ry2 + 38 * k), stp, font=font(12 * k, False), fill=MUTED)
    # Speed · arco de velocidad
    x, y, w, h = [v * k for v in Z["Speed"]]
    arc_ticks(d, x, y, w, h, 18 if touch else 22, 110, 250, 0.46, k, 13 if touch else 16, CYAN)
    d.text((x + w * 0.6, y + h * 0.31), "1.284", font=font((30 if touch else 36) * k), fill=WHITE, anchor="mm")
    d.text((x + w * 0.6, y + h * 0.465), "KM/H", font=font(13 * k), fill=WHITE, anchor="mm")
    d.text((x + w * 0.6, y + h * 0.55), "VELOCIDAD", font=font(10 * k), fill=MUTED, anchor="mm")
    d.text((x + w * 0.26, y + h * 0.62), "IMPULSO", font=font(10 * k), fill=ORANGE)
    bar(d, x + w * 0.26, y + h * 0.71, w * 0.7, 6 * k, 0.7, ORANGE)
    d.rounded_rectangle([x + w * 0.24, y + h * 0.8, x + w * 0.98, y + h * 0.94], radius=6 * k, fill=(12, 34, 60), outline=EDGE)
    d.text((x + w * 0.61, y + h * 0.87), "COMBATE", font=font(11 * k), fill=CYAN, anchor="mm")
    # Defense · escudo y estructura
    x, y, w, h = [v * k for v in Z["Defense"]]
    arc_ticks(d, x, y, w, h, 16 if touch else 20, 70, -70, 0.46, k, 15 if touch else 18, BLUE, right=True)
    arc_ticks(d, x, y, w, h, 14 if touch else 18, 64, -64, 0.38, k, 12 if touch else 16, GREEN, right=True)
    for i, (cap, col, val, frac) in enumerate((("ESCUDO", CYAN, "◈ 92%", 0.92), ("ESTRUCTURA", WHITE, "⬢ 87%", 0.87))):
        yy = y + h * (0.5 * i)
        d.text((x + w * 0.05, yy + h * 0.04), cap, font=font(13 * k), fill=col)
        d.text((x + w * 0.05, yy + h * 0.17), val, font=font((16 if touch else 18) * k), fill=WHITE)
        bar(d, x + w * 0.05, yy + h * 0.34, w * 0.67, 7 * k, frac, BLUE if i == 0 else GREEN)
    # Jump · salto cuántico
    x, y, w, h = panel(layer, Z["Jump"], k)
    for f in (0.9, 0.62, 0.34):
        r = h * f / 2
        d.ellipse([x + w * 0.8 - r, y + h / 2 - r, x + w * 0.8 + r, y + h / 2 + r], outline=VIOLET + (150,), width=max(1, int(2 * k)))
    d.text((x + 14 * k, y + 6 * k), "SALTO CUÁNTICO", font=font(17 * k), fill=VIOLET)
    d.text((x + 14 * k, y + 30 * k), "Destino: Estación Cénit", font=font(14 * k), fill=WHITE)
    d.text((x + 14 * k, y + 50 * k), "2,4 km · SALTO LISTO", font=font(12 * k, False), fill=MUTED)
    if touch:
        d.text((x + 14 * k, y + h - 26 * k), "Toca para elegir destino", font=font(12 * k), fill=WHITE)
    else:
        key_chip(d, x + 14 * k, y + h - 30 * k, 28 * k, 22 * k, "X", k, 12)
        d.text((x + 50 * k, y + h - 19 * k), "Activar", font=font(14 * k), fill=WHITE, anchor="lm")
    # Target · objetivo
    x, y, w, h = panel(layer, Z["Target"], k)
    d.text((x + 14 * k, y + 4 * k), "⚠ OBJETIVO", font=font(12 * k), fill=GOLD)
    d.polygon([(x + 26 * k, y + 36 * k), (x + 34 * k, y + 44 * k), (x + 26 * k, y + 52 * k), (x + 18 * k, y + 44 * k)], fill=RED)
    d.text((x + 44 * k, y + 24 * k), "Caza", font=font(14 * k), fill=WHITE)
    d.text((x + w - 12 * k, y + 24 * k), "Nv. 3", font=font(12 * k), fill=MUTED, anchor="ra")
    d.text((x + 44 * k, y + 44 * k), "340 m  ·  FIJADO", font=font(12 * k), fill=WHITE)
    bar(d, x + 44 * k, y + h - 16 * k, w - 60 * k, 7 * k, 0.7, RED)
    # Keys / Moves (ordenador)
    for zname, title, rows_ in (("Keys", "COMANDOS DE VUELO", FLIGHT), ("Moves", "MANIOBRAS ESPECIALES", SPECIAL)):
        if zname not in Z:
            continue
        x, y, w, h = panel(layer, Z[zname], k)
        d.text((x + 12 * k, y + 6 * k), title, font=font(13 * k), fill=CYAN)
        for i, (key, txt) in enumerate(rows_):
            cy2 = y + 28 * k + i * 21 * k
            key_chip(d, x + 12 * k, cy2 + 1 * k, 78 * k, 18 * k, key, k, 10)
            d.text((x + 98 * k, cy2 + 10 * k), txt, font=font(12 * k, False), fill=WHITE, anchor="lm")
    # Ship · la nave en planta (ordenador)
    if "Ship" in Z:
        x, y, w, h = panel(layer, Z["Ship"], k)
        cx2, cy2 = x + 85 * k, y + 90 * k
        d.ellipse([cx2 - 75 * k, cy2 - 75 * k, cx2 + 75 * k, cy2 + 75 * k], outline=EDGE, width=max(1, int(2 * k)))
        d.ellipse([cx2 - 60 * k, cy2 - 60 * k, cx2 + 60 * k, cy2 + 60 * k], outline=CYAN + (80,), width=1)
        plan_ship(d, cx2, cy2, 110 * k)
        rx = x + 172 * k
        for i, (icon, col, val) in enumerate((("◈", BLUE, "100%"), ("⬢", GREEN, "100%"), ("⚡", (230, 230, 80), "100%"))):
            d.text((rx, y + (10 + 26 * i) * k), icon, font=font(17 * k), fill=col)
            d.text((rx + 28 * k, y + (10 + 26 * i) * k), val, font=font(17 * k), fill=WHITE)
        bar(d, rx, y + 88 * k, 140 * k, 6 * k, 1, (230, 230, 80))
        d.text((rx, y + 102 * k), "MISILES 6/6", font=font(12 * k), fill=ORANGE)
        d.text((x + w - 10 * k, y + 102 * k), "🎇4".replace("🎇", "✶ "), font=font(12 * k), fill=(255, 210, 140), anchor="ra")
        d.text((rx, y + 126 * k), "CAÑONES", font=font(12 * k), fill=CYAN)
        bar(d, rx, y + 150 * k, 140 * k, 6 * k, 0.3, RED)
    # Quick · atajos, modo combate y reloj (ordenador)
    if "Quick" in Z:
        x, y, w, h = panel(layer, Z["Quick"], k)
        cx2, cy2 = x + 62 * k, y + 72 * k
        d.ellipse([cx2 - 52 * k, cy2 - 52 * k, cx2 + 52 * k, cy2 + 52 * k], outline=EDGE, width=max(1, int(2 * k)))
        d.arc([cx2 - 42 * k, cy2 - 42 * k, cx2 + 42 * k, cy2 + 42 * k], 120, 420, fill=GREEN, width=max(1, int(3 * k)))
        plan_ship(d, cx2, cy2, 60 * k)
        for i, (key, txt) in enumerate((("Q", "Giro izq."), ("E", "Giro der."), ("C", "Esquivar"), ("Z", "Camuflaje"))):
            yy = y + (8 + 30 * i) * k
            key_chip(d, x + 124 * k, yy + 2 * k, 26 * k, 22 * k, key, k, 12)
            d.text((x + 158 * k, yy + 13 * k), txt, font=font(14 * k), fill=WHITE, anchor="lm")
        d.text((x + 12 * k, y + 153 * k), "▸ Modo Combate", font=font(13 * k), fill=WHITE, anchor="lm")
        d.rounded_rectangle([x + w - 78 * k, y + 140 * k, x + w - 14 * k, y + 166 * k], radius=13 * k, fill=(16, 60, 100), outline=EDGE)
        d.text((x + w - 46 * k, y + 153 * k), "ON", font=font(13 * k), fill=CYAN, anchor="mm")
        d.text((x + w - 40 * k, y + h - 8 * k), "14:27", font=font(15 * k), fill=WHITE, anchor="rd")
        for i in range(1, 5):
            bx2 = x + w - 34 * k + i * 5 * k
            d.rectangle([bx2, y + h - 10 * k - (3 + 3 * i) * k, bx2 + 3 * k, y + h - 10 * k], fill=CYAN)
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
            glyph = ["≡", "➚", "╱", "◈", "◌", "◎", "»»", "✦"][i]
            d.text((sx + sz / 2, sy + sz * 0.45), glyph, font=font(sz * 0.38), fill=CYAN, anchor="mm")
        if not touch:
            d.text((sx + 6 * k, sy + 3 * k), str(i + 1), font=font(13 * k), fill=MUTED)
        if count:
            d.text((sx + sz - 6 * k, sy + 3 * k), count, font=font(13 * k), fill=WHITE, anchor="ra")
        if locked:
            fl = font(9 * k)
            d.text((sx + sz / 2, sy + sz + 4 * k), fit(d, LOCKED_NOTE, fl, sz + gap), font=fl, fill=MUTED, anchor="ma")
        else:
            d.text((sx + sz / 2, sy + sz + 4 * k), name, font=font(11 * k), fill=WHITE, anchor="ma")
    # Letrero (hipervelocidad)
    x, y, w, h = panel(layer, Z["Prompt"], k)
    d.text((x + 16 * k, y + 4 * k), "HIPERVELOCIDAD", font=font(19 * k), fill=ORANGE)
    d.text((x + 16 * k, y + 28 * k), "Mantén Shift para activar" if not touch else "Toca la ranura 7", font=font(13 * k, False), fill=WHITE)
    bar(d, x + 16 * k, y + h - 8 * k, w - 32 * k, 4 * k, 0.45, ORANGE)
    # Táctil: botones grandes y palanca
    for bid, r in case.get("Buttons", {}).items():
        label, col = BUTTON_LABELS.get(bid, (bid, (40, 60, 90)))
        bx, by3, bw2, bh = [v * k for v in r]
        d.ellipse([bx, by3, bx + bw2, by3 + bh], fill=col + (200,), outline=CYAN, width=max(1, int(3 * k)))
        d.text((bx + bw2 / 2, by3 + bh / 2), label, font=font(min(min(bw2, bh) * 0.17, bw2 * 0.8 / (0.68 * len(label)))), fill=WHITE, anchor="mm")
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
