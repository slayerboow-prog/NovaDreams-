"""Maquetas del HUD de los aviones (el de la nave del espacio con Variant = "Plane") a partir de las
zonas de verdad (UI/ShipHudLayout, vehículo "Plane", con los botones MOTOR +, MOTOR − y FRENOS).

No son capturas de Roblox: dibujan cada zona en su sitio y a su tamaño (las mismas cuentas que el juego)
con un contenido de ejemplo (la avioneta en la pista de Valmar, a punto de despegar), para ver la
composición en el móvil y en el ordenador. Usa los ayudantes de scripts/espacio/hud_mockup.py.

    lune run scripts/avion/plane-hud-dump.luau > /tmp/plane-layout.json
    python3 scripts/avion/plane_hud_mockup.py /tmp/plane-layout.json docs/bugs/avion-video

También dibuja «hud-avion-hangar-*.jpg»: lo que ve el dueño al darle a «Pilotar» la avioneta EC-VAL1 en el
hangar del aeroclub (v117): la cámara de persecución DENTRO del hangar, debajo del tejado, viendo la
avioneta y la puerta (en v116 subía encima del tejado: captura-hud-avioneta.png), el perfil con el
avatar y el nivel y el dinero encogidos para caber, y el radar mirando al sur (la N abajo, sin pisar
«RADAR 0,7 km», que va fuera del aro).
"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "espacio"))
from hud_mockup import CYAN, EDGE, WHITE, MUTED, ORANGE, RED, GOLD, GREEN, BLUE, bar, fit, font, panel  # noqa: E402

BUTTONS = {"MotorMas": ("MOTOR +", (30, 120, 200)), "MotorMenos": ("MOTOR −", (40, 60, 90)), "Frenos": ("FRENOS", (90, 90, 110))}
SLOTS = [("FLAPS", "2", "⫽"), ("TREN ↓", "", "⊥"), ("CÁMARA", "", "▣"), ("A TOPE", "100%", "▔"), ("ACRO", "", "◎"), ("LOOPING", "", "↻"), ("TONEL", "", "⟲"), ("Para el avión", "", "⇥")]


def background(w, h):
    """Cielo al anochecer, el mar y la pista de Valmar en perspectiva."""
    img = Image.new("RGB", (w, h), (10, 16, 34))
    d = ImageDraw.Draw(img)
    horizon = int(h * 0.48)
    for y in range(horizon):
        k = y / horizon
        d.line([(0, y), (w, y)], fill=(int(14 + 40 * k), int(24 + 60 * k), int(52 + 70 * k)))
    for y in range(horizon, h):
        k = (y - horizon) / (h - horizon)
        d.line([(0, y), (w, y)], fill=(int(12 + 8 * k), int(30 + 10 * k), int(48 + 6 * k)))
    # tierra ganada al mar y la pista hacia el horizonte
    d.polygon([(w * 0.05, h), (w * 0.44, horizon + 2), (w * 0.56, horizon + 2), (w * 0.95, h)], fill=(26, 38, 30))
    d.polygon([(w * 0.25, h), (w * 0.48, horizon + 2), (w * 0.52, horizon + 2), (w * 0.75, h)], fill=(34, 36, 40))
    for i in range(10):
        t0, t1 = i / 10, (i + 0.5) / 10
        y0, y1 = h - (h - horizon) * t0 ** 0.6, h - (h - horizon) * t1 ** 0.6
        d.line([(w / 2, y0), (w / 2, y1)], fill=(220, 220, 220), width=max(1, int(4 * (1 - t0))))
    return img


def background_hangar(w, h):
    """Dentro del hangar del aeroclub: suelo de hormigón, paredes de chapa, el tejado arriba y la puerta
    abierta al fondo (la plataforma y el cielo); la cámara va detrás de la avioneta, a media altura."""
    img = Image.new("RGB", (w, h), (70, 72, 76))
    d = ImageDraw.Draw(img)
    vx, vy = w * 0.5, h * 0.42  # punto de fuga (la puerta)
    door = (w * 0.27, h * 0.22, w * 0.73, h * 0.56)
    # tejado (por dentro), paredes y suelo en perspectiva
    d.polygon([(0, 0), (w, 0), (door[2], door[1]), (door[0], door[1])], fill=(92, 96, 104))
    d.polygon([(0, 0), (door[0], door[1]), (door[0], door[3]), (0, h)], fill=(118, 86, 66))
    d.polygon([(w, 0), (door[2], door[1]), (door[2], door[3]), (w, h)], fill=(112, 82, 64))
    d.polygon([(0, h), (door[0], door[3]), (door[2], door[3]), (w, h)], fill=(150, 150, 146))
    for i in range(1, 7):  # vigas del tejado
        t = i / 7
        y = door[1] * (1 - t)
        d.line([(door[0] * (1 - t), y), (w - (w - door[2]) * (1 - t), y)], fill=(70, 74, 80), width=max(1, int(h / 200)))
    # la puerta abierta: cielo y la plataforma
    d.rectangle(door, fill=(120, 170, 220))
    d.rectangle([door[0], door[1] + (door[3] - door[1]) * 0.62, door[2], door[3]], fill=(96, 98, 100))
    d.line([(vx, door[3]), (vx, h)], fill=(230, 200, 60), width=max(2, int(h / 150)))
    return img


def plane(d, cx, cy, s):
    """La avioneta de ala alta vista desde atrás (cámara de persecución alta)."""
    body = (205, 210, 220)
    d.rectangle([cx - 60 * s, cy - 12 * s, cx + 60 * s, cy - 8 * s], fill=body)  # ala
    d.polygon([(cx - 6 * s, cy - 8 * s), (cx + 6 * s, cy - 8 * s), (cx + 4 * s, cy + 12 * s), (cx - 4 * s, cy + 12 * s)], fill=body)
    d.rectangle([cx - 20 * s, cy + 6 * s, cx + 20 * s, cy + 9 * s], fill=body)  # estabilizador
    d.polygon([(cx - 1.5 * s, cy - 2 * s), (cx + 1.5 * s, cy - 2 * s), (cx + 1.5 * s, cy + 8 * s), (cx - 1.5 * s, cy + 8 * s)], fill=(30, 90, 170))
    d.ellipse([cx - 61 * s, cy - 12 * s, cx - 57 * s, cy - 8 * s], fill=RED)
    d.ellipse([cx + 57 * s, cy - 12 * s, cx + 61 * s, cy - 8 * s], fill=(90, 235, 140))


def arc_ticks(d, x, y, w, h, n, a0, a1, r, lit, col, k):
    import math as m
    cx, cy = x + w / 2, y + h / 2
    for i in range(n):
        a = m.radians(a0 + (a1 - a0) * i / max(n - 1, 1))
        px, py = cx + m.cos(a) * r * w, cy + m.sin(a) * r * h
        c = col if i < lit else (40, 60, 80)
        d.ellipse([px - 3 * k, py - 3 * k, px + 3 * k, py + 3 * k], fill=c)


def text_in(d, x, y, text, size, width, fill, anchor="la"):
    """Como TextScaled + UITextSizeConstraint del juego: la letra encoge hasta caber en `width`."""
    size = float(size)
    while size > 6 and d.textlength(text, font=font(size)) > width:
        size -= 0.5
    d.text((x, y), text, font=font(size), fill=fill, anchor=anchor)


def render(case, out_path, scene="pista"):
    W, H = case["Size"]
    k = case["Scale"]
    touch = case["Touch"]
    up = 2 if W < 1000 else 1
    img = background_hangar(W * up, H * up) if scene == "hangar" else background(W * up, H * up)
    k *= up
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    Z = case["Zones"]
    plane(d, W * up / 2, H * up * (0.5 if scene == "hangar" else 0.6), (2.2 if scene == "hangar" else 1.6) * k)
    # A · piloto
    x, y, w, h = panel(layer, Z["A"], k)
    av = h - 20 * k
    d.ellipse([x + 10 * k, y + 10 * k, x + 10 * k + av, y + 10 * k + av], fill=(30, 60, 100), outline=CYAN, width=max(1, int(3 * k)))
    d.text((x + 10 * k + av / 2, y + 10 * k + av / 2), "☺", font=font(av * 0.6), fill=WHITE, anchor="mm")
    tx = x + (104 if touch else 120) * k
    text_in(d, tx, y + 6 * k, "Nv. 100", 20 * k, 78 * k, CYAN)
    d.text((tx + 80 * k, y + 6 * k), fit(d, "Sibila", font(20 * k), w - (tx - x) - 80 * k - 150 * k), font=font(20 * k), fill=WHITE)
    text_in(d, x + w - 12 * k, y + 6 * k, "10.000.014 €", 19 * k, 140 * k, (120, 240, 140), "ra")
    by = (36 if touch else 40) * k
    bar(d, tx + 16 * k, y + by, (150 if touch else 180) * k, 7 * k, 1.0, (255, 80, 80))
    bar(d, tx + 16 * k, y + by + 2 * (13 if touch else 15) * k, (150 if touch else 180) * k, 7 * k, 1.0, (230, 230, 80))
    ry = y + (76 if touch else 90) * k
    rw = (w - (tx - x) - 12 * k) / 3
    for i, t in enumerate(("✈ EC-VAL1", "⛽ 0%" if scene == "hangar" else "⛽ 100%", "🛬 ↓")):
        d.rounded_rectangle([tx + i * rw, ry, tx + (i + 1) * rw - 6 * k, ry + 24 * k], radius=6 * k, fill=(10, 26, 50), outline=EDGE)
        d.text((tx + i * rw + (rw - 6 * k) / 2, ry + 12 * k), t.replace("🛬", "TREN").replace("⛽", "MOTOR"), font=font(13 * k), fill=GOLD if i == 0 else WHITE, anchor="mm")
    # B · brújula
    x, y, w, h = panel(layer, Z["B"], k)
    heading = 180 if scene == "hangar" else 270
    for deg in range(0, 360, 15):
        dd = ((deg - heading + 540) % 360) - 180
        if abs(dd) <= 60:
            px = x + 10 * k + (0.5 + dd / 120) * (w - 20 * k)
            name = {0: "N", 45: "NE", 90: "E", 135: "SE", 180: "S", 225: "SO", 270: "O", 315: "NO"}.get(deg, "")
            if name:
                d.text((px, y + 6 * k), name, font=font((22 if deg % 90 == 0 else 16) * k), fill=WHITE, anchor="ma")
            else:
                d.line([(px, y + 30 * k), (px, y + 38 * k)], fill=CYAN, width=max(1, int(2 * k)))
    tpx = x + 10 * k + 0.5 * (w - 20 * k)
    d.polygon([(tpx, y + 18 * k), (tpx + 7 * k, y + 25 * k), (tpx, y + 32 * k), (tpx - 7 * k, y + 25 * k)], fill=GOLD)
    d.text((x + w / 2, y + 46 * k), "✈ Espacio aéreo de Valmar", font=font(20 * k), fill=CYAN, anchor="ma")
    d.text((x + w / 2, y + 72 * k), "Aeropuerto de Valmar  ·  ALT 0 m", font=font(14 * k, False), fill=WHITE, anchor="ma")
    d.text((x + w / 2, y + 92 * k), "▶ Pista de Valmar · 130 m", font=font(13 * k), fill=GOLD, anchor="ma")
    # Speed · arco de velocidad y MOTOR
    x, y, w, h = [v * k for v in Z["Speed"]]
    arc_ticks(d, x, y, w, h, 18 if touch else 22, 110, 250, 0.46, 8, CYAN, k)
    hangar = scene == "hangar"
    d.text((x + w * 0.6, y + h * 0.2), "0" if hangar else "58", font=font((30 if touch else 36) * k), fill=WHITE, anchor="ma")
    d.text((x + w * 0.6, y + h * 0.43), "KM/H · 0 KT" if hangar else "KM/H · 31 KT", font=font(11 * k), fill=WHITE, anchor="ma")
    d.text((x + w * 0.26, y + h * 0.62), "MOTOR", font=font(11 * k), fill=ORANGE)
    d.text((x + w * 0.96, y + h * 0.62), "0%" if hangar else "100%", font=font(11 * k), fill=WHITE, anchor="ra")
    bar(d, x + w * 0.26, y + h * 0.71, w * 0.7, 6 * k, 0.0 if hangar else 1.0, ORANGE)
    d.rounded_rectangle([x + w * 0.24, y + h * 0.8, x + w * 0.98, y + h * 0.94], radius=6 * k, fill=(12, 34, 60), outline=EDGE)
    d.text((x + w * 0.61, y + h * 0.87), "EN TIERRA", font=font(11 * k), fill=GOLD, anchor="mm")
    # Defense · estructura (sin escudo)
    x, y, w, h = [v * k for v in Z["Defense"]]
    arc_ticks(d, x, y, w, h, 14 if touch else 18, 64, -64, 0.38, 18, GREEN, k)
    d.text((x + w * 0.05, y + h * 0.54), "ESTRUCTURA", font=font(12 * k), fill=WHITE)
    d.text((x + w * 0.05, y + h * 0.66), "100%", font=font(16 * k), fill=WHITE)
    bar(d, x + w * 0.05, y + h * 0.86, w * 0.66, 7 * k, 1.0, GREEN)
    # J
    x, y, w, h = [v * k for v in Z["J"]]
    d.text((x + w / 2, y + h / 2), "", font=font(17 * k), fill=RED, anchor="mm")
    # D · radar
    x, y, w, h = [v * k for v in Z["D"]]
    d.ellipse([x, y, x + w, y + h], fill=(6, 20, 34, 200), outline=EDGE, width=max(1, int(3 * k)))
    for f in (0.66, 0.33):
        d.ellipse([x + w * (1 - f) / 2, y + h * (1 - f) / 2, x + w * (1 + f) / 2, y + h * (1 + f) / 2], outline=CYAN + (110,), width=1)
    cx, cy = x + w / 2, y + h / 2
    d.polygon([(cx, cy - 8 * k), (cx - 6 * k, cy + 6 * k), (cx + 6 * k, cy + 6 * k)], fill=WHITE)
    for (bx, by2, col, shape) in ((0.0, -0.4, WHITE, "s"), (0.0, 0.5, WHITE, "s"), (0.5, -0.3, (90, 170, 255), "r"), (-0.6, -0.5, GOLD, "o")):
        px, py = cx + bx * w * 0.44, cy + by2 * h * 0.44
        s = 6 * k
        if shape == "r":
            d.polygon([(px, py - s), (px + s, py), (px, py + s), (px - s, py)], fill=col)
        elif shape == "s":
            d.rectangle([px - s, py - s, px + s, py + s], fill=col)
        else:
            d.ellipse([px - s * 1.4, py - s * 1.4, px + s * 1.4, py + s * 1.4], outline=col, width=2)
    # (las letras giran con el rumbo; el alcance va fuera del aro, abajo a la izquierda, y no lo pisa la N)
    import math as m
    for letter, off in (("N", 0), ("E", 90), ("S", 180), ("O", 270)):
        a = m.radians(off - heading)
        d.text((cx + m.sin(a) * 0.43 * w, cy - m.cos(a) * 0.43 * h), letter, font=font((18 if letter == "N" else 14) * k), fill=WHITE if letter == "N" else MUTED, anchor="mm")
    d.text((x + 0.14 * w, y + h), "RADAR 0,7 km", font=font(11 * k), fill=CYAN, anchor="rd")
    # E · misiones
    x, y, w, h = panel(layer, Z["E"], k)
    mrows = [("PRINCIPAL", GOLD, "Clase práctica", "Despega y sube 120 m", "1,2 km"), ("VUELO", CYAN, "Pista de Valmar", "Despega a 52 km/h", "130 m")]
    rh = (h - 8 * k - (0 if touch else 16 * k)) / 3
    for i, (kind, col, title, step, right) in enumerate(mrows):
        ry = y + 4 * k + i * rh
        d.polygon([(x + 17 * k, ry + 8 * k), (x + 22 * k, ry + 13 * k), (x + 17 * k, ry + 18 * k), (x + 12 * k, ry + 13 * k)], fill=col)
        d.text((x + 30 * k, ry + 2 * k), kind, font=font(12 * k), fill=col)
        d.text((x + 30 * k, ry + 19 * k), fit(d, title, font(15 * k), w - 120 * k), font=font(15 * k), fill=WHITE)
        d.text((x + w - 10 * k, ry + 19 * k), right, font=font(13 * k), fill=MUTED, anchor="ra")
        if rh >= 54 * k:
            d.text((x + 30 * k, ry + 38 * k), fit(d, step, font(12 * k, False), w - 40 * k), font=font(12 * k, False), fill=MUTED)
    # Target · la PISTA que queda
    if "Target" in Z:
        x, y, w, h = panel(layer, Z["Target"], k)
        d.text((x + 14 * k, y + 4 * k), "✈ PISTA", font=font(13 * k), fill=GOLD)
        d.text((x + 44 * k, y + 24 * k), "Pista de Valmar", font=font(15 * k), fill=WHITE)
        d.text((x + 44 * k, y + 44 * k), "Quedan 130 m", font=font(14 * k), fill=WHITE)
        bar(d, x + 44 * k, y + h - 16 * k, w - 60 * k, 7 * k, 0.45, RED)
    # Keys / Moves (ordenador)
    for zn, title, rows in (("Keys", "MANDOS DEL AVIÓN", [("W / S", "Morro (W sube)"), ("A / D", "Alas (girar)"), ("Q / E", "Timón"), ("Shift", "Motor +"), ("Ctrl", "Motor −"), ("B", "Frenos"), ("F", "Flaps"), ("G", "Tren"), ("C", "Cámara"), ("Espacio", "Bajarse (parado)")]),
                            ("Moves", "DESPEGAR Y ATERRIZAR", [("Shift", "1. Motor a tope"), ("W", "2. Pasada Vr, sube el morro"), ("G", "3. Tren arriba (o solo)"), ("F", "Aterrizar: flaps 2, despacio"), ("B", "En la pista: frena"), ("H", "Plegar estas listas")])):
        if zn in Z:
            x, y, w, h = panel(layer, Z[zn], k)
            d.text((x + 12 * k, y + 5 * k), title, font=font(13 * k), fill=CYAN)
            for i, (key, txt) in enumerate(rows):
                cy = y + 28 * k + i * 21 * k
                d.rounded_rectangle([x + 12 * k, cy + 1 * k, x + 90 * k, cy + 19 * k], radius=5 * k, fill=(20, 40, 70), outline=EDGE)
                d.text((x + 51 * k, cy + 10 * k), key, font=font(10 * k), fill=WHITE, anchor="mm")
                d.text((x + 98 * k, cy + 10 * k), txt, font=font(12 * k, False), fill=WHITE, anchor="lm")
    # Ship (ordenador): el avión en planta con altitud, V/S, rumbo y flaps · tren
    if "Ship" in Z:
        x, y, w, h = panel(layer, Z["Ship"], k)
        d.ellipse([x + 10 * k, y + 15 * k, x + 160 * k, y + 165 * k], outline=EDGE, width=max(1, int(2 * k)))
        plane(d, x + 85 * k, y + 90 * k, 1.1 * k)
        for i, (ic, txt, col) in enumerate((("♥", "100%", GREEN), ("▲", "0 m", (230, 230, 80)))):
            d.text((x + 172 * k, y + (36 + i * 26) * k), ic + "  " + txt, font=font(16 * k), fill=col)
        d.text((x + 172 * k, y + 102 * k), "RUMBO 180° S" if scene == "hangar" else "RUMBO 270° O", font=font(12 * k), fill=CYAN)
        d.text((x + 172 * k, y + 126 * k), "FLAPS 0 · TREN ↓" if scene == "hangar" else "FLAPS 2 · TREN ↓", font=font(12 * k), fill=CYAN)
        d.text((x + 172 * k, y + 150 * k), "= 0.0 m/s", font=font(12 * k), fill=(255, 210, 140))
    # Quick (ordenador): atajos del avión
    if "Quick" in Z:
        x, y, w, h = panel(layer, Z["Quick"], k)
        for i, (key, txt) in enumerate((("F", "Flaps"), ("G", "Tren"), ("C", "Cámara"), ("Esp", "Bajarse"))):
            cy = y + (8 + i * 30) * k
            d.rounded_rectangle([x + 124 * k, cy + 2 * k, x + 150 * k, cy + 24 * k], radius=5 * k, fill=(20, 40, 70), outline=EDGE)
            d.text((x + 137 * k, cy + 13 * k), key, font=font(10 * k), fill=WHITE, anchor="mm")
            d.text((x + 158 * k, cy + 13 * k), txt, font=font(15 * k), fill=WHITE, anchor="lm")
        plane(d, x + 62 * k, y + 72 * k, 0.7 * k)
        d.text((x + 12 * k, y + 153 * k), "▸ Tirar ↓ para subir", font=font(14 * k), fill=WHITE, anchor="lm")
        d.rounded_rectangle([x + w - 78 * k, y + 140 * k, x + w - 14 * k, y + 166 * k], radius=13 * k, fill=(16, 60, 100), outline=EDGE)
        d.text((x + w - 46 * k, y + 153 * k), "SÍ", font=font(14 * k), fill=CYAN, anchor="mm")
        d.text((x + w - 40 * k, y + h - 8 * k), "06:56", font=font(16 * k), fill=WHITE, anchor="rd")
    if "Help" in Z:
        x, y, w, h = panel(layer, Z["Help"], k)
        d.text((x + w / 2, y + h / 2), "?", font=font(30 * k), fill=CYAN, anchor="mm")
    # H · ranuras del avión
    x, y, w, h = panel(layer, Z["H"], k)
    sz, gap = case["Slot"] * k, case["Gap"] * k
    keys = ["F", "G", "C", "", "T", "L", "R", "Esp"]
    slots = SLOTS if scene != "hangar" else [(n, {"2": "0", "100%": "0%"}.get(c, c), g) for (n, c, g) in SLOTS]
    for i, (name, count, glyph) in enumerate(slots):
        sx = x + 8 * k + i * (sz + gap)
        sy = y + 6 * k
        active = i in ((1,) if scene == "hangar" else (0, 1, 3))
        d.rounded_rectangle([sx, sy, sx + sz, sy + sz], radius=10 * k, fill=(16, 60, 100) if active else (8, 22, 44), outline=CYAN if active else EDGE, width=max(1, int((3 if active else 1.5) * k)))
        d.text((sx + sz / 2, sy + sz * 0.45), glyph, font=font(sz * 0.42), fill=MUTED if i == 7 else CYAN, anchor="mm")
        if not touch and keys[i]:
            d.text((sx + 6 * k, sy + 3 * k), keys[i], font=font(13 * k), fill=MUTED)
        if count:
            d.text((sx + sz - 6 * k, sy + 3 * k), count, font=font(12 * k), fill=WHITE, anchor="ra")
        fl = font(11 * k)
        d.text((sx + sz / 2, sy + sz + 4 * k), fit(d, name, fl, sz + gap), font=fl, fill=MUTED if i == 7 else WHITE, anchor="ma")
    # Letrero: la ayuda para despegar
    x, y, w, h = panel(layer, Z["Prompt"], k)
    if scene == "hangar":
        d.text((x + 16 * k, y + 4 * k), "PARA DESPEGAR: " + ("MOTOR +" if touch else "Shift") + " A TOPE", font=font(19 * k), fill=ORANGE)
        d.text((x + 16 * k, y + 28 * k), "En la pista, a 52 km/h, " + ("tira hacia abajo" if touch else "pulsa w"), font=font(13 * k, False), fill=WHITE)
        bar(d, x + 16 * k, y + h - 8 * k, w - 32 * k, 4 * k, 0.0, ORANGE)
    else:
        d.text((x + 16 * k, y + 4 * k), "TIRA HACIA ABAJO PARA DESPEGAR" if touch else "PULSA W PARA DESPEGAR", font=font(19 * k), fill=(120, 240, 140))
        d.text((x + 16 * k, y + 28 * k), "Ya vas a 58 km/h: sube el morro", font=font(13 * k, False), fill=WHITE)
        bar(d, x + 16 * k, y + h - 8 * k, w - 32 * k, 4 * k, 1.0, (120, 240, 140))
    # Táctil: botones grandes (como los de la nave) y la palanca con la flecha que late
    for bid, r in case.get("Buttons", {}).items():
        label, col = BUTTONS.get(bid, (bid, (40, 60, 90)))
        bx, by2, bw, bh = [v * k for v in r]
        d.ellipse([bx, by2, bx + bw, by2 + bh], fill=col + (200,), outline=CYAN, width=max(1, int(3 * k)))
        d.text((bx + bw / 2, by2 + bh / 2), label, font=font(min(min(bw, bh) * 0.17, bw * 0.8 / (0.68 * len(label)))), fill=WHITE, anchor="mm")
        if bid == "MotorMas":
            bar(d, bx + bw * 0.2, by2 + bh * 0.72, bw * 0.6, 6 * k, 1.0, ORANGE)
    st = case.get("Stick")
    if st:
        sx, sy, sw, sh = [v * k for v in st]
        d.ellipse([sx, sy, sx + sw, sy + sh], fill=(10, 24, 48, 140), outline=CYAN, width=max(1, int(3 * k)))
        d.ellipse([sx + sw * 0.3, sy + sh * 0.3, sx + sw * 0.7, sy + sh * 0.7], fill=(200, 240, 255, 220))
        if scene != "hangar":
            d.text((sx + sw / 2, sy + sh * 0.8), "▼", font=font(sh * 0.3), fill=(255, 180, 60), anchor="mm")
            d.text((sx + sw / 2, sy - 10 * k), "TIRA ↓ PARA SUBIR", font=font(22 * k), fill=(255, 210, 120), anchor="md")
        d.text((sx + sw / 2, sy + sh + 6 * k), "ABAJO = SUBIR · LADOS = GIRAR", font=font(16 * k), fill=(200, 240, 255), anchor="ma")
    img.paste(layer, (0, 0), layer)
    band = 24 * up
    full = Image.new("RGB", (img.size[0], img.size[1] + band), (0, 0, 0))
    full.paste(img, (0, 0))
    d2 = ImageDraw.Draw(full)
    title = "HUD del avión (el de la nave, vehículo Plane) · %dx%d (%s) · maqueta de las zonas de verdad (no es captura de Roblox)" % (W, H, "móvil" if touch else "ordenador")
    d2.text((8 * up, img.size[1] + band / 2), title, font=font(11 * up, False), fill=(200, 210, 220), anchor="lm")
    full.save(out_path, quality=88)
    print("ok", out_path, img.size)


if __name__ == "__main__":
    cases = json.load(open(sys.argv[1]))
    out_dir = sys.argv[2]
    for c in cases:
        if c["Clashes"]:
            print("¡se pisan!", c["Size"], c["Clashes"])
        render(c, os.path.join(out_dir, "hud-avion-%dx%d.jpg" % tuple(c["Size"])))
        if tuple(c["Size"]) in ((844, 390), (1920, 1080)):
            render(c, os.path.join(out_dir, "hud-avion-hangar-%dx%d.jpg" % tuple(c["Size"])), "hangar")
