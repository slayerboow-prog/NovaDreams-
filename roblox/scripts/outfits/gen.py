#!/usr/bin/env python3
"""Plantillas de ropa clásica de Roblox (Shirt / Pants, 585×559) para los 30 conjuntos del pase.

Lee los datos de src/shared/Outfits.luau (lanzando scripts/outfits/export.luau con Lune, o un JSON
ya exportado con --json) y dibuja, para cada conjunto, assets/outfits/oNN_shirt.png y oNN_pants.png:
colores con textura de tela, sombras suaves, costuras, cremalleras, bolsillos, rayas, bandas
reflectantes, neón, acolchado, estampados (flores tropicales, grafiti, étnico, cachemira) y textos
(el «VALMAR 23» de la camiseta de baloncesto, espaldas…). Lo que no tapa la ropa queda transparente:
ahí se ve el color de la piel del personaje.

Solo hace falta Pillow (pip install pillow). Uso (desde roblox/):
    python3 scripts/outfits/gen.py                 # todas
    python3 scripts/outfits/gen.py O05 O13         # solo esas
    python3 scripts/outfits/gen.py --sheet out.png # además, una hoja con todas para revisarlas
Después: bash scripts/upload-outfits.sh (las sube y escribe src/shared/OutfitIds.luau).
"""

import json
import math
import os
import random
import subprocess
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "assets", "outfits")
W, H = 585, 559

# Plantilla clásica de Roblox: (x, y, ancho, alto) de cada cara
TORSO = {"U": (231, 8, 128, 64), "F": (231, 74, 128, 128), "R": (165, 74, 64, 128), "L": (361, 74, 64, 128), "B": (427, 74, 128, 128), "D": (231, 204, 128, 64)}
RIGHT = {"L": (19, 355, 64, 128), "B": (85, 355, 64, 128), "R": (151, 355, 64, 128), "F": (217, 355, 64, 128), "U": (217, 289, 64, 64), "D": (217, 485, 64, 64)}
LEFT = {"F": (308, 355, 64, 128), "L": (374, 355, 64, 128), "B": (440, 355, 64, 128), "R": (506, 355, 64, 128), "U": (308, 289, 64, 64), "D": (308, 485, 64, 64)}
LIMBS = (("Right", RIGHT, "R", "L"), ("Left", LEFT, "L", "R"))  # (lado, caras, cara de fuera, cara de dentro)
SIDES4 = ("F", "R", "B", "L")

FONT_PATHS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    "/Library/Fonts/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "C:/Windows/Fonts/arialbd.ttf",
]


def font(size):
    for path in FONT_PATHS:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def c(rgb, alpha=255):
    return (int(rgb[0]), int(rgb[1]), int(rgb[2]), alpha)


def shade(rgb, k):
    if k >= 0:
        return tuple(int(v + (255 - v) * k) for v in rgb[:3])
    return tuple(int(v * (1 + k)) for v in rgb[:3])


def lum(rgb):
    return 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]


# ---------------------------------------------------------------------------
# Lienzo: capas de color (RGBA) y de sombras (L, 128 = neutro)
# ---------------------------------------------------------------------------
class Canvas:
    def __init__(self, seed):
        self.img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.img)
        self.shadow = Image.new("L", (W, H), 128)
        self.sdraw = ImageDraw.Draw(self.shadow)
        self.glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        self.gdraw = ImageDraw.Draw(self.glow)
        self.rng = random.Random(seed)

    def rect(self, face, x0, y0, x1, y1, color, alpha=255):
        """Rectángulo en coordenadas de la cara (0..ancho, 0..alto)."""
        fx, fy, fw, fh = face
        x0, x1 = max(0, x0), min(fw, x1)
        y0, y1 = max(0, y0), min(fh, y1)
        if x1 <= x0 or y1 <= y0:
            return
        self.draw.rectangle([fx + x0, fy + y0, fx + x1 - 1, fy + y1 - 1], fill=c(color, alpha))

    def clear(self, face, x0, y0, x1, y1):
        fx, fy, fw, fh = face
        x0, x1 = max(0, x0), min(fw, x1)
        y0, y1 = max(0, y0), min(fh, y1)
        if x1 <= x0 or y1 <= y0:
            return
        self.draw.rectangle([fx + x0, fy + y0, fx + x1 - 1, fy + y1 - 1], fill=(0, 0, 0, 0))

    def poly(self, face, points, color, alpha=255):
        fx, fy, _, _ = face
        self.draw.polygon([(fx + x, fy + y) for x, y in points], fill=c(color, alpha))

    def clear_poly(self, face, points):
        fx, fy, _, _ = face
        self.draw.polygon([(fx + x, fy + y) for x, y in points], fill=(0, 0, 0, 0))

    def line(self, face, points, color, width=1, alpha=255):
        fx, fy, fw, fh = face
        self.draw.line([(fx + x, fy + y) for x, y in points], fill=c(color, alpha), width=width)

    def ellipse(self, face, box, color, alpha=255, outline=None):
        fx, fy, _, _ = face
        x0, y0, x1, y1 = box
        self.draw.ellipse([fx + x0, fy + y0, fx + x1, fy + y1], fill=c(color, alpha), outline=c(outline) if outline else None)

    def soft(self, face, points, value, width):
        """Arruga / sombra suave (se difumina al final)."""
        fx, fy, _, _ = face
        self.sdraw.line([(fx + x, fy + y) for x, y in points], fill=value, width=width)

    def neon(self, face, points, color, width=2):
        fx, fy, _, _ = face
        pts = [(fx + x, fy + y) for x, y in points]
        self.draw.line(pts, fill=c(color), width=width)
        self.gdraw.line(pts, fill=c(color, 200), width=width + 6)

    def text(self, face, cx, cy, text, color, size, outline=None, max_w=None):
        fx, fy, fw, _ = face
        max_w = max_w or fw - 6
        f = font(size)
        while size > 7:
            box = self.draw.textbbox((0, 0), text, font=f)
            if box[2] - box[0] <= max_w:
                break
            size -= 1
            f = font(size)
        box = self.draw.textbbox((0, 0), text, font=f)
        x = fx + cx - (box[2] - box[0]) / 2 - box[0]
        y = fy + cy - (box[3] - box[1]) / 2 - box[1]
        if outline:
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, 1), (-1, 1), (1, -1)):
                self.draw.text((x + dx, y + dy), text, font=f, fill=c(outline))
        self.draw.text((x, y), text, font=f, fill=c(color))

    def finish(self):
        """Tela (ruido), sombras difuminadas y brillo de neón, solo donde hay ropa."""
        # Solo dentro de las caras de la plantilla (los estampados no se salen)
        mask = Image.new("L", (W, H), 0)
        mdraw = ImageDraw.Draw(mask)
        for faces in (TORSO, RIGHT, LEFT):
            for x, y, w, h in faces.values():
                mdraw.rectangle([x, y, x + w - 1, y + h - 1], fill=255)
        alpha = ImageChops.multiply(self.img.getchannel("A"), mask)
        rgb = self.img.convert("RGB")
        # (ruido con semilla: la misma plantilla cada vez que se genera, sin cambios falsos en git)
        raw = Image.frombytes("L", (W, H), self.rng.randbytes(W * H)).filter(ImageFilter.BoxBlur(1))
        noise = raw.point(lambda v: max(0, min(255, int(128 + (v - 128) * 1.4)))).convert("RGB")
        textured = ImageChops.overlay(rgb, noise)
        rgb = Image.blend(rgb, textured, 0.35)
        shadow = self.shadow.filter(ImageFilter.GaussianBlur(3))
        shadow_rgb = Image.merge("RGB", (shadow, shadow, shadow))
        rgb = Image.blend(rgb, ImageChops.overlay(rgb, shadow_rgb), 0.9)
        out = Image.merge("RGBA", (*rgb.split(), alpha))
        glow = self.glow.filter(ImageFilter.GaussianBlur(3))
        glow_alpha = ImageChops.multiply(glow.getchannel("A"), alpha)
        glow.putalpha(glow_alpha.point(lambda v: int(v * 0.55)))
        out = Image.alpha_composite(out, glow)
        # (el neón ensucia los píxeles transparentes: se vuelve a poner el alfa original)
        out.putalpha(alpha)
        return out


# ---------------------------------------------------------------------------
# Rellenos: liso con volumen, o con estampado
# ---------------------------------------------------------------------------
def fill(cv, face, color, y0=0, y1=None, pattern=None, x0=0, x1=None, folds=True):
    fx, fy, fw, fh = face
    y1 = fh if y1 is None else y1
    x1 = fw if x1 is None else x1
    cv.rect(face, x0, y0, x1, y1, color)
    if pattern:
        draw_pattern(cv, face, pattern, x0, y0, x1, y1)
    # Volumen: más oscuro en los bordes y abajo
    cv.soft(face, [(x0 + 1, y0), (x0 + 1, y1)], 108, 3)
    cv.soft(face, [(x1 - 2, y0), (x1 - 2, y1)], 108, 3)
    cv.soft(face, [(x0, y1 - 2), (x1, y1 - 2)], 112, 3)
    if folds and fh >= 100 and y1 - y0 > 40:
        for _ in range(2):
            ax = cv.rng.uniform(x0 + 8, x1 - 8)
            ay = cv.rng.uniform(y0 + 10, y1 - 20)
            cv.soft(face, [(ax, ay), (ax + cv.rng.uniform(-10, 10), ay + cv.rng.uniform(12, 24))], 110, 2)


def draw_pattern(cv, face, pattern, x0, y0, x1, y1):
    kind = pattern.get("Kind")
    colors = pattern.get("Colors") or [[128, 128, 128]]
    rng = cv.rng
    area = (x1 - x0) * (y1 - y0)
    if kind == "Tropical":
        for _ in range(max(2, area // 260)):
            cx, cy = rng.uniform(x0, x1), rng.uniform(y0, y1)
            col = rng.choice(colors[1:] or colors)
            if rng.random() < 0.6:
                # Hoja: elipse alargada con nervio
                ang = rng.uniform(0, math.pi)
                L, Wd = rng.uniform(12, 22), rng.uniform(5, 8)
                pts = []
                for k in range(16):
                    t = k / 16 * 2 * math.pi
                    px, py = math.cos(t) * L / 2, math.sin(t) * Wd / 2
                    pts.append((cx + px * math.cos(ang) - py * math.sin(ang), cy + px * math.sin(ang) + py * math.cos(ang)))
                cv.poly(face, pts, col)
                cv.line(face, [(cx - math.cos(ang) * L / 2, cy - math.sin(ang) * L / 2), (cx + math.cos(ang) * L / 2, cy + math.sin(ang) * L / 2)], shade(col, -0.35))
            else:
                # Flor de cinco pétalos
                r = rng.uniform(3, 5)
                for k in range(5):
                    t = k / 5 * 2 * math.pi
                    cv.ellipse(face, (cx + math.cos(t) * r - r, cy + math.sin(t) * r - r, cx + math.cos(t) * r + r, cy + math.sin(t) * r + r), col)
                cv.ellipse(face, (cx - 2, cy - 2, cx + 2, cy + 2), (250, 230, 120))
    elif kind == "Graffiti":
        for _ in range(max(2, area // 900)):
            col = rng.choice(colors[1:] or colors)
            pts = [(rng.uniform(x0, x1), rng.uniform(y0, y1))]
            for _ in range(4):
                pts.append((pts[-1][0] + rng.uniform(-14, 14), pts[-1][1] + rng.uniform(-8, 8)))
            cv.line(face, pts, col, width=rng.choice((2, 3, 4)))
            if rng.random() < 0.5:
                px, py = pts[-1]
                cv.line(face, [(px, py), (px, py + rng.uniform(4, 10))], col, width=1)
    elif kind == "Ethnic":
        y = y0 + 4
        k = 0
        while y < y1:
            col = colors[1 + k % max(1, len(colors) - 1)] if len(colors) > 1 else colors[0]
            cv.rect(face, x0, y, x1, y + 2, col)
            # Zigzag y rombos
            step = 8
            pts = []
            x = x0
            while x <= x1:
                pts.append((x, y + 5 + (3 if (x // step) % 2 else -1)))
                x += step / 2
            cv.line(face, pts, shade(col, 0.2), width=2)
            for x in range(int(x0) + 6, int(x1), 16):
                cv.poly(face, [(x, y + 9), (x + 4, y + 13), (x, y + 17), (x - 4, y + 13)], colors[(k + 2) % len(colors)])
            y += 20
            k += 1
    elif kind == "Paisley":
        for _ in range(max(2, area // 300)):
            cx, cy = rng.uniform(x0, x1), rng.uniform(y0, y1)
            col = rng.choice(colors[1:] or colors)
            r = rng.uniform(5, 8)
            cv.ellipse(face, (cx - r, cy - r, cx + r, cy + r), col)
            cv.poly(face, [(cx - r * 0.8, cy - r * 0.5), (cx + r * 1.6, cy - r * 1.8), (cx + r * 0.2, cy - r * 0.9)], col)
            cv.ellipse(face, (cx - r * 0.45, cy - r * 0.45, cx + r * 0.45, cy + r * 0.45), shade(col, 0.4))
            cv.ellipse(face, (cx - 1.5, cy - 1.5, cx + 1.5, cy + 1.5), colors[0])


# ---------------------------------------------------------------------------
# Camisa (Shirt)
# ---------------------------------------------------------------------------
def shirt(o):
    top = o["Top"]
    cv = Canvas(o["Number"] * 101)
    color = top["Color"]
    sleeve = top.get("Sleeve") or color
    trim = top.get("Trim") or shade(color, -0.25)
    pattern = top.get("Pattern")
    kind = top.get("Kind")
    midriff = top.get("Midriff")
    crop = 70 if kind != "Bra" else 50  # alto del top corto (de 128)
    bottom_y = crop if midriff else 128

    # --- Torso ---
    for name in SIDES4:
        fill(cv, TORSO[name], color, 0, bottom_y, pattern if kind != "Racing" else None)
    fill(cv, TORSO["U"], color, folds=False)
    if not midriff:
        fill(cv, TORSO["D"], shade(color, -0.1), folds=False)
    F, B, R, L, U = TORSO["F"], TORSO["B"], TORSO["R"], TORSO["L"], TORSO["U"]

    if kind == "Bra":
        # Tirantes cruzados en la espalda y franja elástica abajo
        for face in (F, B, R, L):
            cv.rect(face, 0, crop - 8, face[2], crop, trim)
        cv.clear_poly(B, [(30, 0), (98, 0), (64, 40)])
        cv.clear_poly(F, [(34, 0), (94, 0), (64, 22)])
        cv.clear(U, 18, 0, 46, 64)
        cv.clear(U, 82, 0, 110, 64)
    if kind in ("Tank", "Crop") and top.get("Sleeves") == "None":
        # Tirantes: hombros al aire
        cv.clear(U, 0, 0, 20, 64)
        cv.clear(U, 108, 0, 128, 64)
        cv.clear(U, 40, 0, 88, 64)
    if kind == "Jersey":
        cv.clear(U, 0, 0, 24, 64)
        cv.clear(U, 104, 0, 128, 64)
        cv.clear(U, 44, 0, 84, 64)
        for face in (R, L):
            cv.clear_poly(face, [(0, 0), (64, 0), (64, 22), (32, 34), (0, 22)])
            cv.line(face, [(0, 22), (32, 34), (64, 22)], trim, width=4)
        cv.clear_poly(F, [(46, 0), (82, 0), (64, 26)])
        cv.line(F, [(44, 0), (64, 28), (84, 0)], trim, width=4)
        cv.line(F, [(46, 0), (64, 24), (82, 0)], (245, 245, 245), width=1)
        for face in (F, B):
            cv.rect(face, 0, 122, face[2], 128, trim)
    if top.get("OneShoulder"):
        cv.clear_poly(F, [(0, 0), (70, 0), (0, 26)])
        cv.clear_poly(B, [(58, 0), (128, 0), (128, 26)])
        cv.clear(R, 0, 0, 64, 22)
        cv.clear(U, 0, 0, 64, 64)
        cv.line(F, [(70, 0), (0, 26)], trim, width=3)
        # Pliegues del satén
        for k in range(5):
            cv.soft(F, [(20 + k * 22, 30), (40 + k * 18, 128)], 160, 3)
            cv.soft(F, [(30 + k * 22, 30), (50 + k * 18, 128)], 100, 2)
    if kind == "Corset":
        cv.clear_poly(F, [(0, 0), (128, 0), (128, 10), (96, 18), (64, 8), (32, 18), (0, 10)])
        for face in (R, L, B):
            cv.clear(face, 0, 0, face[2], 10)
        cv.clear(U, 0, 0, 128, 64)
        for k in range(6):
            y = 24 + k * 15
            cv.line(F, [(56, y), (72, y + 12)], trim, width=2)
            cv.line(F, [(72, y), (56, y + 12)], trim, width=2)
        for x in (20, 40, 88, 108):
            cv.line(F, [(x, 14), (x, 126)], shade(color, -0.08), width=1)
        cv.line(F, [(0, 10), (32, 18), (64, 8), (96, 18), (128, 10)], trim, width=2)
    if top.get("Collar") == "V":
        cv.clear_poly(F, [(46, 0), (82, 0), (64, 30)])
        cv.line(F, [(44, 0), (64, 32), (84, 0)], trim, width=3)
    elif top.get("Collar") == "Round" and kind not in ("Corset",):
        cv.clear_poly(F, [(44, 0), (84, 0), (78, 8), (64, 11), (50, 8)])
        cv.line(F, [(44, 0), (50, 8), (64, 11), (78, 8), (84, 0)], shade(color, -0.15), width=2)
    elif top.get("Collar") == "High":
        for face in (F, B, R, L):
            cv.rect(face, 0, 0, face[2], 8, trim)
            cv.line(face, [(0, 8), (face[2], 8)], shade(trim, -0.3))

    # Colores en bloque
    if top.get("Panel"):
        panel = top["Panel"]
        if kind == "Racing":
            for face in (R, L):
                fill(cv, face, panel, 0, bottom_y, folds=False)
            for face in (F, B):
                cv.rect(face, 0, 0, 20, bottom_y, panel)
                cv.rect(face, 108, 0, 128, bottom_y, panel)
        else:
            for face in (F, B, R, L):
                cv.rect(face, 0, 0, face[2], 40, panel)
                cv.line(face, [(0, 40), (face[2], 40)], shade(panel, -0.3), width=2)
            cv.rect(U, 0, 0, 128, 64, panel)

    # Prenda abierta: camiseta de dentro
    inner = top.get("Inner")
    if top.get("Open") and inner:
        iy = crop if midriff else 128
        cv.rect(F, 42, 0, 86, iy, inner)
        if midriff:
            cv.clear(F, 42, iy, 86, 128)
        cv.soft(F, [(44, 0), (44, iy)], 90, 3)
        cv.soft(F, [(84, 0), (84, iy)], 90, 3)
        if kind in ("Tuxedo", "Coat"):
            # Solapas
            lapel = shade(color, 0.12) if kind == "Tuxedo" else shade(color, 0.06)
            cv.poly(F, [(42, 0), (30, 0), (24, 18), (42, 58)], lapel)
            cv.poly(F, [(86, 0), (98, 0), (104, 18), (86, 58)], lapel)
            cv.line(F, [(30, 0), (24, 18), (42, 58)], shade(color, 0.3) if kind == "Tuxedo" else shade(color, -0.3))
            cv.line(F, [(98, 0), (104, 18), (86, 58)], shade(color, 0.3) if kind == "Tuxedo" else shade(color, -0.3))
            if kind == "Tuxedo":
                for y in (30, 50, 70, 90):
                    cv.ellipse(F, (62, y, 66, y + 4), (30, 30, 34))
                cv.poly(F, [(52, 0), (64, 14), (76, 0)], shade(inner, -0.05))
            else:
                for y in (70, 96):
                    for x in (34, 94):
                        cv.ellipse(F, (x - 3, y - 3, x + 3, y + 3), shade(color, 0.25))
        else:
            for x in (41, 86):
                cv.line(F, [(x, 0), (x, 128)], trim, width=3)
                if top.get("Zip"):
                    for y in range(2, 128, 4):
                        cv.line(F, [(x - 1, y), (x + 1, y)], (150, 152, 158))
        ip = top.get("InnerPrint")
        if ip:
            cv.text(F, 64, 30 if not midriff else 28, ip["Text"], ip["Color"], 14, max_w=40)
    elif top.get("Zip"):
        cv.line(F, [(64, 6 if top.get("Collar") == "High" else 0), (64, bottom_y)], (130, 132, 138), width=2)
        for y in range(4, bottom_y, 4):
            cv.line(F, [(62, y), (66, y)], (100, 102, 108))
        cv.rect(F, 61, 10, 67, 22, (180, 182, 188))

    if top.get("Buttons") and not top.get("Open"):
        cv.line(F, [(66, 0), (66, bottom_y)], shade(color, -0.2))
        for y in range(16, bottom_y - 6, 22):
            cv.ellipse(F, (62, y, 68, y + 6), shade(color, 0.35))
    if top.get("Collar") == "Shirt" and kind not in ("Tuxedo", "Coat"):
        col = shade(color, 0.08)
        cv.poly(F, [(44, 0), (64, 12), (56, 22), (38, 6)], col)
        cv.poly(F, [(84, 0), (64, 12), (72, 22), (90, 6)], col)
        cv.line(F, [(38, 6), (56, 22), (64, 12), (72, 22), (90, 6)], shade(color, -0.3))
        if kind == "Polo":
            cv.rect(F, 60, 10, 68, 44, shade(color, -0.05))
            for y in (18, 32):
                cv.ellipse(F, (62, y, 66, y + 4), trim)
            for face in (R, L):
                cv.clear_poly(face, [(0, 0), (64, 0), (64, 18), (32, 30), (0, 18)])
                cv.line(face, [(0, 18), (32, 30), (64, 18)], trim, width=3)
            for face in (F, B):
                cv.rect(face, 0, 124, face[2], 128, trim)

    # Bolsillos
    if top.get("Pocket") == "Kangaroo":
        pts = [(28, 78), (100, 78), (108, 112), (20, 112)]
        cv.poly(F, pts, shade(color, -0.06))
        cv.line(F, pts + [pts[0]], shade(color, -0.3), width=2)
        cv.soft(F, [(28, 80), (100, 80)], 96, 3)
    elif top.get("Pocket") == "Chest":
        for x0 in ((80,) if kind != "Shirt" else (20, 80)):
            cv.rect(F, x0, 30, x0 + 26, 56, shade(color, -0.06))
            cv.line(F, [(x0, 30), (x0, 56), (x0 + 26, 56), (x0 + 26, 30)], shade(color, -0.35))
            cv.rect(F, x0 - 1, 28, x0 + 27, 36, shade(color, 0.04))
            cv.line(F, [(x0 - 1, 36), (x0 + 27, 36)], shade(color, -0.35))
    if kind == "Shirt" and top.get("Buttons"):
        # Hombreras (sin galones ni placa: es ropa de estilo)
        for x in (4, 106):
            cv.rect(U, x, 18, x + 18, 46, shade(color, -0.1))

    # Acolchado
    if top.get("Quilt"):
        for face in (F, B, R, L):
            for y in range(20, bottom_y, 22):
                cv.line(face, [(0, y), (face[2], y)], shade(color, -0.22), width=2)
                cv.soft(face, [(0, y + 6), (face[2], y + 6)], 150, 4)
                cv.soft(face, [(0, y + 1), (face[2], y + 1)], 96, 2)

    # Capucha caída (espalda) y cordones
    if top.get("Hood"):
        lining = trim if lum(trim) != lum(color) else shade(color, 0.2)
        cv.poly(B, [(22, 0), (106, 0), (100, 30), (84, 44), (44, 44), (28, 30)], shade(color, -0.08))
        cv.poly(B, [(36, 0), (92, 0), (86, 20), (74, 30), (54, 30), (42, 20)], lining)
        cv.soft(B, [(26, 40), (102, 40)], 88, 4)
        if not top.get("Open") and kind == "Hoodie":
            for x in (52, 76):
                cv.line(F, [(x, 6), (x + (2 if x > 64 else -2), 46)], (236, 236, 236), width=2)
                cv.ellipse(F, (x - 2, 44, x + 2, 50), (200, 200, 204))

    # Bajo y puños acanalados
    if kind in ("Hoodie", "Bomber", "Puffer", "Jacket") and not midriff:
        for face in (F, B, R, L):
            cv.rect(face, 0, 118, face[2], 128, shade(trim if kind == "Bomber" else color, -0.08))
            for x in range(0, face[2], 3):
                cv.line(face, [(x, 119), (x, 127)], shade(trim if kind == "Bomber" else color, -0.2))

    # Bandas reflectantes
    bands = top.get("Bands")
    if bands:
        for face in (F, B, R, L):
            for y in (58, 92):
                cv.rect(face, 0, y, face[2], y + 10, bands)
                cv.rect(face, 0, y + 4, face[2], y + 6, (225, 228, 230))
                cv.gdraw.rectangle([face[0], face[1] + y, face[0] + face[2], face[1] + y + 10], fill=c(bands, 120))

    # Neón
    neon = top.get("Neon")
    if neon:
        for x in (34, 94):
            cv.neon(F, [(x, 10), (x, bottom_y - 4)], neon)
        cv.neon(B, [(10, 60), (118, 60)], neon)

    # Correas
    if top.get("Straps"):
        cv.line(F, [(10, 0), (118, 110)], top["Straps"], width=6)
        cv.rect(F, 58, 50, 72, 62, (170, 172, 178))

    # Estampados de texto
    pr = top.get("Print")
    if top.get("Number"):
        cv.text(F, 64, 40, pr["Text"] if pr else "VALMAR", pr["Color"] if pr else (255, 255, 255), 17, outline=trim, max_w=96)
        cv.text(F, 64, 84, top["Number"], (255, 255, 255), 48, outline=trim)
    elif pr:
        if top.get("Open") or kind in ("Scrubs", "Racing"):
            cv.text(F, 108 if top.get("Open") else 96, 30, pr["Text"], pr["Color"], 14, max_w=30)
        else:
            cv.text(F, 64, 46 if not midriff else 34, pr["Text"], pr["Color"], 30 if len(pr["Text"]) <= 2 else 22, outline=shade(color, -0.4), max_w=90)
    back = top.get("Back")
    if back:
        y = 66 if top.get("Hood") else 46
        size = 44 if len(back["Text"]) <= 3 else 22
        cv.text(B, 64, y, back["Text"], back["Color"], size, outline=shade(color, -0.4), max_w=112)

    # --- Mangas ---
    length = {"Long": 112, "Short": 46, "None": 0}[top.get("Sleeves", "Long")]
    stripes = top.get("SleeveStripes")
    for side, faces, outer, inner_face in LIMBS:
        if length > 0:
            for name in SIDES4:
                face = faces[name]
                fill(cv, face, sleeve, 0, length, pattern if kind != "Racing" else None)
                if stripes:
                    for y in range(6, length, 12):
                        cv.rect(face, 0, y, face[2], y + 6, stripes[1])
                if top.get("Panel") and kind != "Racing":
                    cv.rect(face, 0, 0, face[2], 30, top["Panel"])
                # Codo
                if length > 60:
                    cv.soft(face, [(8, 58), (32, 62), (56, 58)], 104, 2)
                # Puño / bajo de la manga
                if length == 112:
                    cuff = shade(trim if kind in ("Bomber", "Jacket", "Racing") else sleeve, -0.1)
                    cv.rect(face, 0, 102, face[2], 112, cuff)
                    for x in range(0, face[2], 3):
                        cv.line(face, [(x, 103), (x, 111)], shade(cuff, -0.15))
                else:
                    cv.rect(face, 0, length - 5, face[2], length, shade(trim, 0))
            fill(cv, faces["U"], sleeve, folds=False)
            if top.get("Panel") and kind != "Racing":
                cv.rect(faces["U"], 0, 0, 64, 64, top["Panel"])
            if top.get("Stripe"):
                face = faces[outer]
                cv.rect(face, 22, 0, 28, length - 10, top["Stripe"])
                cv.rect(face, 36, 0, 42, length - 10, top["Stripe"])
            if bands and length > 60:
                for name in SIDES4:
                    cv.rect(faces[name], 0, 70, 64, 80, bands)
                    cv.rect(faces[name], 0, 74, 64, 76, (225, 228, 230))
            if neon:
                cv.neon(faces[outer], [(32, 4), (32, length - 12)], neon)
        # Guantes (lo de abajo del brazo es la mano en R15)
        gloves = o.get("Gloves")
        if gloves:
            for name in SIDES4:
                cv.rect(faces[name], 0, 112, 64, 128, gloves)
                cv.line(faces[name], [(0, 112), (64, 112)], shade(gloves, 0.2))
            cv.rect(faces["D"], 0, 0, 64, 64, gloves)
    return cv.finish()


# ---------------------------------------------------------------------------
# Pantalón (Pants)
# ---------------------------------------------------------------------------
def pants(o):
    bottom, shoes = o["Bottom"], o["Shoes"]
    cv = Canvas(o["Number"] * 211)
    color = bottom["Color"]
    trim = bottom.get("Trim") or shade(color, -0.25)
    pattern = bottom.get("Pattern")
    kind = bottom.get("Kind")
    F, B, R, L, D = TORSO["F"], TORSO["B"], TORSO["R"], TORSO["L"], TORSO["D"]

    # Cintura: lo de abajo del torso (en R15 es la cadera)
    for face in (F, B, R, L):
        fill(cv, face, color, 96, 128, pattern, folds=False)
        belt = bottom.get("Belt") or shade(color, -0.2)
        cv.rect(face, 0, 96, face[2], 102, belt)
        if kind in ("Jeans", "Cargo", "Trousers", "Shorts", "Flare", "Wide", "Racing"):
            for x in range(10, face[2], 30):
                cv.rect(face, x, 95, x + 4, 104, shade(color, -0.12))
    fill(cv, D, color, folds=False)
    if kind not in ("Leggings", "Gown", "Skirt", "Racing"):
        cv.line(F, [(70, 102), (70, 126), (62, 128)], shade(color, -0.3))
    if kind == "Jeans" or kind == "Flare":
        cv.line(F, [(8, 102), (24, 120)], (200, 140, 70))
        cv.line(F, [(120, 102), (104, 120)], (200, 140, 70))

    length = {"Long": 114, "Knee": 64, "Short": 40, "Mini": 18}[bottom.get("Length", "Long")]
    if kind == "Gown":
        length = 128
    for side, faces, outer, inner in LIMBS:
        for name in SIDES4:
            face = faces[name]
            fill(cv, face, color, 0, length, pattern)
            # Rodilla
            if length > 70:
                cv.soft(face, [(10, 62), (32, 66), (54, 62)], 104, 2)
            if kind in ("Jeans", "Flare"):
                # Vaquero: costuras y desgaste en los muslos
                cv.soft(face, [(32, 6), (32, 50)], 150, 10)
                cv.line(face, [(2, 0), (2, length)], (200, 140, 70))
                cv.line(face, [(62, 0), (62, length)], (200, 140, 70))
            if kind == "Leggings":
                cv.soft(face, [(22, 0), (22, length)], 158, 5)
            if kind == "Trousers":
                if name in ("F", "B"):
                    cv.line(face, [(32, 0), (32, length)], shade(color, 0.12))
            if kind == "Joggers" and length == 114:
                cv.rect(face, 0, 102, 64, 114, shade(color, -0.1))
                for x in range(0, 64, 3):
                    cv.line(face, [(x, 103), (x, 113)], shade(color, -0.22))
            if length < 114 and kind != "Gown":
                cv.rect(face, 0, length - 4, 64, length, trim if bottom.get("Trim") else shade(color, -0.15))
            if bottom.get("Bands"):
                for y in (84, 100):
                    cv.rect(face, 0, y, 64, y + 8, bottom["Bands"])
                    cv.rect(face, 0, y + 3, 64, y + 5, (225, 228, 230))
                    cv.gdraw.rectangle([face[0], face[1] + y, face[0] + 64, face[1] + y + 8], fill=c(bottom["Bands"], 120))
            if bottom.get("Straps"):
                for y in (30, 52):
                    cv.rect(face, 0, y, 64, y + 5, bottom["Straps"])
        fill(cv, faces["U"], color, folds=False)
        # Rayas por fuera
        if bottom.get("Stripe"):
            f = faces[outer]
            if kind == "Trousers":
                cv.rect(f, 29, 0, 35, length, bottom["Stripe"])
            else:
                cv.rect(f, 20, 0, 26, length - 4, bottom["Stripe"])
                cv.rect(f, 38, 0, 44, length - 4, bottom["Stripe"])
        if bottom.get("Panel"):
            f = faces[outer]
            cv.rect(f, 0, 0, 16, length, bottom["Panel"])
            cv.rect(f, 48, 0, 64, length, bottom["Panel"])
        # Bolsillos
        if bottom.get("Pockets") and kind == "Cargo":
            f = faces[outer]
            cv.rect(f, 10, 34, 54, 66, shade(color, 0.05))
            cv.line(f, [(10, 34), (10, 66), (54, 66), (54, 34)], shade(color, -0.35))
            cv.rect(f, 8, 30, 56, 40, shade(color, -0.08))
            cv.line(f, [(8, 40), (56, 40)], shade(color, -0.4))
            cv.soft(f, [(10, 67), (54, 67)], 92, 3)
        elif bottom.get("Pockets"):
            f = faces["F"]
            cv.line(f, [(4, 0), (20, 14)] if side == "Right" else [(60, 0), (44, 14)], shade(color, -0.35), width=2)
            b = faces["B"]
            cv.rect(b, 14, 6, 50, 30, shade(color, -0.04))
            cv.line(b, [(14, 6), (14, 30), (32, 34), (50, 30), (50, 6)], (200, 140, 70) if kind in ("Jeans", "Flare", "Shorts") else shade(color, -0.3))
        if bottom.get("Rips"):
            f = faces["F"]
            for y in (22, 30):
                cv.line(f, [(18, y), (46, y + 1)], (232, 232, 236), width=3)
        if bottom.get("Neon"):
            cv.neon(faces[outer], [(32, 2), (32, length - 6)], bottom["Neon"])
        if bottom.get("Fishnet"):
            # Medias de rejilla: red oscura sobre la piel (se ve la piel por los huecos)
            for name in SIDES4:
                face = faces[name]
                for k in range(-128, 128, 7):
                    cv.line(face, [(k, length), (k + 128, length + 128)], (24, 24, 26), alpha=235)
                    cv.line(face, [(k + 128, length), (k, length + 128)], (24, 24, 26), alpha=235)
                cv.clear(face, 0, 114, 64, 128)
        # Pies: el zapato (las sandalias dejan ver el pie)
        if shoes.get("Kind") != "Sandal":
            for name in SIDES4:
                cv.rect(faces[name], 0, 114, 64, 128, shoes["Color"])
                cv.rect(faces[name], 0, 124, 64, 128, shoes.get("Sole") or shade(shoes["Color"], -0.2))
            cv.rect(faces["D"], 0, 0, 64, 64, shoes.get("Sole") or shoes["Color"])
    return cv.finish()


# ---------------------------------------------------------------------------
def load_outfits(json_path=None):
    if json_path:
        with open(json_path, encoding="utf-8") as fh:
            return json.load(fh)
    out = subprocess.run(["lune", "run", "scripts/outfits/export.luau"], cwd=ROOT, capture_output=True, text=True, check=True)
    return json.loads(out.stdout)


def main(argv):
    only, sheet, json_path = [], None, None
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--sheet":
            sheet = argv[i + 1]
            i += 1
        elif arg == "--json":
            json_path = argv[i + 1]
            i += 1
        elif arg in ("-h", "--help"):
            print(__doc__)
            return 0
        else:
            only.append(arg.upper())
        i += 1
    outfits = load_outfits(json_path)
    os.makedirs(OUT, exist_ok=True)
    made = []
    for o in outfits:
        if only and o["Key"] not in only:
            continue
        base = o["Key"].lower()
        s, p = shirt(o), pants(o)
        s.save(os.path.join(OUT, base + "_shirt.png"))
        p.save(os.path.join(OUT, base + "_pants.png"))
        made.append((o, s, p))
    print(f"👕 {len(made)} conjuntos: {len(made) * 2} plantillas de {W}×{H} en {os.path.relpath(OUT, ROOT)}")
    if sheet:
        cols = 6
        tw, th = W // 3, H // 3
        rows = math.ceil(len(made) / cols)
        board = Image.new("RGBA", (cols * tw * 2, rows * (th + 14)), (60, 62, 70, 255))
        d = ImageDraw.Draw(board)
        for n, (o, s, p) in enumerate(made):
            x, y = (n % cols) * tw * 2, (n // cols) * (th + 14)
            board.alpha_composite(s.resize((tw, th)), (x, y + 14))
            board.alpha_composite(p.resize((tw, th)), (x + tw, y + 14))
            d.text((x + 4, y + 1), f"{o['Key']} {o['Name']}", fill=(255, 255, 255, 255), font=font(11))
        board.save(sheet)
        print(f"🗂  hoja de revisión: {sheet}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
