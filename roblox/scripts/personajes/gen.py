#!/usr/bin/env python3
"""Texturas del reparto de la historia (pase «AAA», shared/LifeStory/CastLook). Arte original, 13+.

Lee scripts/personajes/out/personajes.json (lune run scripts/personajes/export.luau) y dibuja en
assets/personajes/:
  caras/pj_cara_<clave>_<expresión>.png  una cara por personaje y expresión (Neutral, Happy, Talk, Sad,
                                         Angry, Scared; los secundarios solo Neutral, Happy y Talk). Fondo
                                         transparente: es el Decal «face» de la cabeza clásica. Ojos con
                                         iris en degradado, pupila y dos brillos, párpados y pestañas,
                                         cejas con pelos, nariz y boca con sombras suaves, mejillas, y lo
                                         de cada uno (gafas, barba, pecas, arrugas). Una sola boca siempre.
                                         512 px el reparto principal, 256 px el resto (móvil).
  ropa/pj_ropa_<estilo>.png              plantillas Shirt de Roblox (585x559) COMPARTIDAS por estilo, casi
  ropa/pj_pantalon_<estilo>.png          blancas (el juego las tiñe con Clothing.Color3): tejido con grano,
                                         costuras, pliegues y detalles del mismo tono. Sin logos de marcas.
                                         Las manos y la piel quedan transparentes (nada de piel pintada).
  pelo/pj_pelo.png                       mechones grises con transparencia (256, se repite), teñidos.

Solo hace falta Pillow y numpy. Uso (desde roblox/):
    lune run scripts/personajes/export.luau
    python3 scripts/personajes/gen.py [--solo clave1,clave2]
Después: bash scripts/upload-personajes.sh (sube y escribe src/shared/PersonajesTextureIds.luau).
"""

import argparse
import json
import math
import os
import random

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "assets", "personajes")
DATA = os.path.join(ROOT, "scripts", "personajes", "out", "personajes.json")

S = 1024  # se dibuja grande y se reduce (bordes suaves)
INK = (38, 28, 26, 255)
WHITE = (247, 245, 240, 255)


def P(x, y):
    return (x * S, y * S)


def lw(k):
    return max(1, int(k * S))


def bezier(p0, p1, p2, n=40):
    out = []
    for i in range(n + 1):
        t = i / n
        out.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0], (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]))
    return out


def line(d, pts, width, fill):
    px = [P(*p) for p in pts]
    d.line(px, fill=fill, width=lw(width), joint="curve")
    r = width / 2 * S
    for x, y in (px[0], px[-1]):
        d.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def ellipse(d, cx, cy, rx, ry, **kw):
    d.ellipse([(cx - rx) * S, (cy - ry) * S, (cx + rx) * S, (cy + ry) * S], **kw)


def layer():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def soft(img, radius):
    return img.filter(ImageFilter.GaussianBlur(radius * S))


def rgba(c, a=255):
    return (int(c[0]), int(c[1]), int(c[2]), int(a))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


# ---------------------------------------------------------------------------
# Rasgos
# ---------------------------------------------------------------------------

EXPR = {
    #          lidTop lidBot pupil  gazeX gazeY  browIn browOut browY  mouth
    "Neutral": (0.05, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, "neutral"),
    "Happy": (0.06, 0.32, 1.0, 0.0, 0.0, -0.01, 0.01, -0.012, "smile"),
    "Talk": (0.06, 0.04, 1.0, 0.0, 0.0, -0.005, 0.0, -0.006, "talk"),
    "Sad": (0.34, 0.0, 1.0, 0.0, 0.18, -0.045, 0.02, 0.0, "sad"),
    "Angry": (0.36, 0.08, 0.9, 0.0, 0.0, 0.05, -0.025, 0.012, "angry"),
    "Scared": (0.0, 0.0, 0.62, 0.0, 0.0, -0.05, -0.02, -0.035, "scared"),
}


def almond(cx, cy, w, h, n=40):
    """Contorno del ojo (almendra): arriba más curvo, abajo más plano."""
    top = bezier((cx - w, cy + h * 0.1), (cx - w * 0.1, cy - h * 1.55), (cx + w, cy - h * 0.05), n)
    bot = bezier((cx + w, cy - h * 0.05), (cx + w * 0.05, cy + h * 1.15), (cx - w, cy + h * 0.1), n)
    return top, bot


def eye(img, cx, cy, w, h, iris_col, ex, side, fem, kid, old, glow=None):
    lid_top, lid_bot, pupil_k, gx, gy = ex[0], ex[1], ex[2], ex[3], ex[4]
    top, bot = almond(cx, cy, w, h)
    poly = [P(*p) for p in top + bot]
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    # párpados (lo que tapan): arriba baja `lid_top`, abajo sube `lid_bot`
    cover = Image.new("L", (S, S), 255)
    cd = ImageDraw.Draw(cover)
    ytop = cy - h * 1.1 + 2.2 * h * lid_top
    tilt = (0.0 if side == 0 else (0.25 * h if lid_top > 0.3 else 0.0))
    if lid_top > 0:
        # (enfado: el párpado baja por dentro; tristeza: por fuera)
        cd.polygon([P(cx - w * 1.2, cy - h * 2), P(cx + w * 1.2, cy - h * 2), P(cx + w * 1.2, ytop + side * tilt), P(cx - w * 1.2, ytop - side * tilt)], fill=0)
    if lid_bot > 0:
        ybot = cy + h * 1.0 - 2.0 * h * lid_bot
        cd.polygon([P(cx - w * 1.2, cy + h * 2), P(cx + w * 1.2, cy + h * 2), P(cx + w * 1.2, ybot), P(cx - w * 1.2, ybot)], fill=0)
    m = ImageChops.multiply(mask, cover)
    eyel = layer()
    ed = ImageDraw.Draw(eyel)
    ed.polygon(poly, fill=WHITE)
    # sombra del párpado sobre el blanco
    sh = layer()
    ellipse(ImageDraw.Draw(sh), cx, cy - h * 0.9, w * 1.1, h * 0.8, fill=(120, 90, 80, 90))
    eyel.alpha_composite(soft(sh, 0.012))
    # iris con degradado, anillo oscuro, pupila y brillos
    ir = h * 0.95 * (1.12 if kid else 1.0)
    ix, iy = cx + gx * w * 0.4, cy + gy * h * 0.5 + h * 0.05
    steps = 14
    for i in range(steps):
        t = i / (steps - 1)
        col = mix(mix(iris_col, (20, 16, 14), 0.45), mix(iris_col, (255, 255, 255), 0.28), t)
        r = ir * (1 - 0.55 * t)
        ellipse(ed, ix, iy + (0.12 * ir * t), r, r, fill=rgba(col))
    ellipse(ed, ix, iy, ir, ir, outline=rgba(mix(iris_col, (10, 8, 8), 0.7)), width=lw(0.006))
    # rayitas del iris
    for k in range(14):
        a = 2 * math.pi * k / 14
        x0, y0 = ix + math.cos(a) * ir * 0.45, iy + math.sin(a) * ir * 0.45
        x1, y1 = ix + math.cos(a) * ir * 0.9, iy + math.sin(a) * ir * 0.9
        ed.line([P(x0, y0), P(x1, y1)], fill=rgba(mix(iris_col, (255, 255, 255), 0.35), 120), width=lw(0.003))
    pr = ir * 0.42 * pupil_k
    ellipse(ed, ix, iy, pr, pr, fill=(12, 10, 10, 255))
    if glow:
        g = layer()
        ellipse(ImageDraw.Draw(g), ix, iy, ir * 1.1, ir * 1.1, fill=rgba(glow, 170))
        eyel.alpha_composite(soft(g, 0.01))
    ellipse(ed, ix - ir * 0.38, iy - ir * 0.4, ir * 0.3, ir * 0.3, fill=(255, 255, 255, 245))
    ellipse(ed, ix + ir * 0.35, iy + ir * 0.32, ir * 0.13, ir * 0.13, fill=(255, 255, 255, 200))
    clipped = layer()
    clipped.paste(eyel, (0, 0), m)
    img.alpha_composite(clipped)
    d = ImageDraw.Draw(img)
    # línea de las pestañas (arriba, gruesa) siguiendo el párpado
    if lid_top > 0.02:
        line(d, [(cx - w * 1.02, ytop + h * 0.15 - side * tilt), (cx, ytop - h * 0.05), (cx + w * 1.02, ytop + h * 0.15 + side * tilt)], 0.011, INK)
    else:
        line(d, top, 0.011, INK)
    line(d, bot[len(bot) // 6 : -len(bot) // 6], 0.004, rgba((90, 60, 52), 200))
    # pliegue del párpado
    crease = bezier((cx - w * 0.85, cy - h * 1.15), (cx, cy - h * (1.9 if not old else 1.75)), (cx + w * 0.85, cy - h * 1.15))
    line(d, crease, 0.0045, rgba((120, 80, 66), 150))
    # pestañas (más en ellas)
    outer = cx + side * w * 1.0 if side != 0 else cx + w
    n = 3 if fem else 1
    for k in range(n):
        y0 = cy - h * (0.25 + 0.28 * k) if lid_top < 0.3 else ytop + h * 0.15
        line(d, [(outer - side * w * 0.05 * k, y0), (outer + side * w * (0.28 - 0.04 * k), y0 - h * (0.4 + 0.12 * k))], 0.006, INK)
    if old:
        for k in (-1, 0, 1):
            line(d, [(cx + side * w * 1.2, cy + k * h * 0.35), (cx + side * w * 1.55, cy + k * h * 0.55)], 0.004, rgba((130, 90, 76), 150))
        line(d, bezier((cx - w * 0.7, cy + h * 1.5), (cx, cy + h * 1.9), (cx + w * 0.7, cy + h * 1.5)), 0.004, rgba((130, 90, 76), 120))


def brow(img, cx, cy, length, thick, angle_in, angle_out, side, color, seed):
    """Ceja con forma (gruesa por dentro, fina por fuera) y pelitos. side: -1 izquierda de la imagen."""
    rnd = random.Random(seed)
    inner = (cx - side * length * 0.5, cy + angle_in)
    outer = (cx + side * length * 0.5, cy + angle_out)
    mid = ((inner[0] + outer[0]) / 2, (inner[1] + outer[1]) / 2 - thick * 0.9)
    top = bezier((inner[0], inner[1] - thick * 0.5), mid, outer)
    bot = bezier(outer, (mid[0], mid[1] + thick * 1.3), (inner[0], inner[1] + thick * 0.55))
    lay = layer()
    ld = ImageDraw.Draw(lay)
    ld.polygon([P(*p) for p in top + bot], fill=rgba(color))
    dark = mix(color, (0, 0, 0), 0.35)
    for i in range(int(length * 260)):
        t = rnd.random()
        x = inner[0] + (outer[0] - inner[0]) * t
        y = inner[1] + (outer[1] - inner[1]) * t - thick * 0.9 * 4 * t * (1 - t) + rnd.uniform(-0.4, 0.5) * thick * (1 - 0.5 * t)
        ang = math.radians(-25 + 40 * t) * side
        L = thick * rnd.uniform(0.6, 1.1)
        ld.line([P(x, y), P(x + side * L * math.cos(ang), y - L * abs(math.sin(ang)) - L * 0.2)], fill=rgba(dark if rnd.random() < 0.6 else mix(color, (255, 255, 255), 0.15), 210), width=lw(0.0028))
    img.alpha_composite(lay.filter(ImageFilter.GaussianBlur(0.6)))


def nose(img, cy, skin_shadow):
    d = ImageDraw.Draw(img)
    sh = layer()
    sd = ImageDraw.Draw(sh)
    ellipse(sd, 0.535, cy + 0.0, 0.035, 0.07, fill=rgba(skin_shadow, 80))
    img.alpha_composite(soft(sh, 0.012))
    line(d, bezier((0.52, cy - 0.08), (0.56, cy + 0.03), (0.515, cy + 0.05)), 0.007, rgba((110, 70, 58), 210))
    for x in (0.468, 0.535):
        ellipse(d, x, cy + 0.055, 0.015, 0.009, fill=rgba((110, 66, 56), 150))


LIP = (172, 92, 88)
MOUTH = (96, 30, 36)
TEETH = (250, 248, 240)
TONGUE = (214, 102, 108)


def mouth(img, kind, cy, wide, seed):
    d = ImageDraw.Draw(img)
    cx = 0.5
    w = 0.1 * wide
    if kind == "neutral":
        line(d, bezier((cx - w, cy), (cx, cy + 0.022), (cx + w, cy - 0.004)), 0.008, rgba((80, 40, 38), 235))
        lip = layer()
        ellipse(ImageDraw.Draw(lip), cx, cy + 0.03, w * 0.6, 0.016, fill=rgba(LIP, 80))
        img.alpha_composite(soft(lip, 0.006))
        return
    if kind == "sad":
        line(d, bezier((cx - w * 0.85, cy + 0.02), (cx, cy - 0.022), (cx + w * 0.85, cy + 0.02)), 0.008, rgba((80, 40, 38), 235))
        lip = layer()
        ellipse(ImageDraw.Draw(lip), cx, cy + 0.032, w * 0.5, 0.014, fill=rgba(LIP, 70))
        img.alpha_composite(soft(lip, 0.006))
        return
    if kind == "smile":
        top = bezier((cx - w * 1.15, cy - 0.01), (cx, cy + 0.02), (cx + w * 1.15, cy - 0.01))
        bot = bezier((cx + w * 1.15, cy - 0.01), (cx, cy + 0.13), (cx - w * 1.15, cy - 0.01))
        teeth_h, tongue = 0.034, (cx, cy + 0.085, w * 0.55, 0.03)
    elif kind == "talk":
        top = bezier((cx - w * 0.85, cy + 0.005), (cx, cy - 0.035), (cx + w * 0.85, cy + 0.005))
        bot = bezier((cx + w * 0.85, cy + 0.005), (cx, cy + 0.13), (cx - w * 0.85, cy + 0.005))
        teeth_h, tongue = 0.022, (cx, cy + 0.075, w * 0.45, 0.025)
    elif kind == "angry":
        top = bezier((cx - w * 0.95, cy + 0.02), (cx, cy - 0.012), (cx + w * 0.95, cy + 0.02))
        bot = bezier((cx + w * 0.95, cy + 0.02), (cx, cy + 0.07), (cx - w * 0.95, cy + 0.02))
        teeth_h, tongue = 0.03, None
    else:  # scared
        n = 30
        top = [(cx + w * 0.45 * math.cos(a), cy + 0.03 + 0.045 * math.sin(a)) for a in [math.pi + math.pi * i / n for i in range(n + 1)]]
        bot = [(cx + w * 0.45 * math.cos(a), cy + 0.03 + 0.055 * math.sin(a)) for a in [math.pi * i / n for i in range(n + 1)]]
        teeth_h, tongue = 0.012, None
    poly = [P(*p) for p in top + bot]
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    lay = layer()
    ld = ImageDraw.Draw(lay)
    ld.polygon(poly, fill=rgba(MOUTH))
    if tongue:
        ellipse(ld, *tongue, fill=rgba(TONGUE))
    # dientes de arriba (fila limpia) y, enfadado, también los de abajo (apretados)
    xs = [p[0] for p in top]
    ld.polygon([P(x, y - 0.01) for x, y in top] + [P(x, y + teeth_h) for x, y in reversed(top)], fill=rgba(TEETH))
    rnd = random.Random(seed)
    for k in range(1, 6):
        x = min(xs) + (max(xs) - min(xs)) * k / 6
        yy = min(top, key=lambda p: abs(p[0] - x))[1]
        ld.line([P(x, yy), P(x + rnd.uniform(-0.002, 0.002), yy + teeth_h * 0.9)], fill=(205, 200, 190, 255), width=lw(0.0025))
    if kind == "angry":
        ld.polygon([P(x, y + 0.01) for x, y in bot] + [P(x, y - teeth_h * 0.6) for x, y in reversed(bot)], fill=rgba(TEETH))
        mid = [(x, (yt + yb) / 2) for (x, yt), (_, yb) in zip(top, reversed(bot))]
        ld.line([P(*p) for p in mid], fill=rgba((150, 140, 136)), width=lw(0.004))
    clipped = layer()
    clipped.paste(lay, (0, 0), mask)
    # labio de abajo (sombra suave)
    lip = layer()
    ellipse(ImageDraw.Draw(lip), cx, max(p[1] for p in bot) + 0.012, w * 0.55, 0.014, fill=rgba(LIP, 90))
    img.alpha_composite(soft(lip, 0.006))
    img.alpha_composite(clipped)
    d = ImageDraw.Draw(img)
    d.line(poly + [poly[0]], fill=rgba((70, 32, 32)), width=lw(0.007), joint="curve")


def cheeks(img, strength, color=(232, 120, 120)):
    lay = layer()
    ld = ImageDraw.Draw(lay)
    for x in (0.27, 0.73):
        ellipse(ld, x, 0.64, 0.07, 0.04, fill=rgba(color, int(70 * strength)))
    img.alpha_composite(soft(lay, 0.025))


def freckles(img, seed):
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img)
    for x0 in (0.3, 0.7):
        for _ in range(9):
            x = x0 + rnd.uniform(-0.06, 0.06)
            y = 0.6 + rnd.uniform(-0.03, 0.035)
            r = rnd.uniform(0.003, 0.006)
            ellipse(d, x, y, r, r, fill=(150, 90, 60, 150))


def glasses(img, kind, eyes, w, h, color=(46, 40, 44)):
    d = ImageDraw.Draw(img)
    lens = layer()
    ld = ImageDraw.Draw(lens)
    for (cx, cy) in eyes:
        box = [P(cx - w * 1.45, cy - h * 1.9), P(cx + w * 1.45, cy + h * 1.7)]
        if kind == "Round":
            ld.ellipse(box, fill=(220, 236, 255, 34))
            d.ellipse(box, outline=rgba(color), width=lw(0.011))
        else:
            ld.rounded_rectangle(box, radius=0.03 * S, fill=(220, 236, 255, 34))
            d.rounded_rectangle(box, radius=0.03 * S, outline=rgba(color), width=lw(0.012))
        # brillo del cristal
        d.line([P(cx - w * 0.9, cy - h * 1.1), P(cx - w * 0.3, cy - h * 1.6)], fill=(255, 255, 255, 170), width=lw(0.006))
    img.alpha_composite(lens)
    (lx, ly), (rx, ry) = eyes
    line(d, bezier((lx + w * 1.45, ly - h * 0.6), (0.5, ly - h * 1.1), (rx - w * 1.45, ry - h * 0.6)), 0.009, rgba(color))
    line(d, [(lx - w * 1.45, ly - h * 0.6), (0.06, ly - h * 0.9)], 0.009, rgba(color))
    line(d, [(rx + w * 1.45, ry - h * 0.6), (0.94, ry - h * 0.9)], 0.009, rgba(color))


def beard(img, kind, hair, mouth_y, seed):
    rnd = random.Random(seed)
    col = mix(hair, (0, 0, 0), 0.15)
    lay = layer()
    ld = ImageDraw.Draw(lay)
    if kind in ("Stubble", "Full"):
        n = 2600 if kind == "Stubble" else 0
        for _ in range(n):
            x = rnd.uniform(0.2, 0.8)
            y = rnd.uniform(mouth_y - 0.05, 0.99)
            # (solo mandíbula y barbilla: ni mejillas altas ni la boca)
            if abs(x - 0.5) < 0.13 and abs(y - mouth_y - 0.03) < 0.06:
                continue
            if y < 0.62 + abs(x - 0.5) * 0.25:
                continue
            ellipse(ld, x, y, 0.0022, 0.0022, fill=rgba(col, 120))
    if kind == "Full":
        # barba cerrada: toda la parte de abajo de la cara (mejillas, mandíbula y barbilla) con pelos; la
        # boca se dibuja encima (una sola). Sin hueco en forma de media luna: parecía otra boca.
        outer = bezier((0.15, 0.6), (0.5, 1.2), (0.85, 0.6), 50)
        top = bezier((0.85, 0.6), (0.5, 0.66), (0.15, 0.6), 50)
        ld.polygon([P(*p) for p in outer + top], fill=rgba(col, 225))
        for _ in range(1400):
            x = rnd.uniform(0.17, 0.83)
            y = rnd.uniform(0.62, 0.97)
            shade = mix(col, (0, 0, 0), 0.3) if rnd.random() < 0.6 else mix(col, (255, 255, 255), 0.18)
            ld.line([P(x, y), P(x + (x - 0.5) * 0.05 + rnd.uniform(-0.004, 0.004), y + 0.022)], fill=rgba(shade, 150), width=lw(0.003))
    if kind in ("Mustache", "Goatee", "Full"):
        y = mouth_y - 0.035
        pts = bezier((0.35, y + 0.045), (0.42, y - 0.05), (0.5, y - 0.02)) + bezier((0.5, y - 0.02), (0.58, y - 0.05), (0.65, y + 0.045)) + bezier((0.65, y + 0.045), (0.5, y + 0.01), (0.35, y + 0.045))
        ld.polygon([P(*p) for p in pts], fill=rgba(col, 245))
        for _ in range(220):
            x = rnd.uniform(0.37, 0.63)
            ld.line([P(x, y - 0.025 + abs(x - 0.5) * 0.1), P(x + (x - 0.5) * 0.12, y + 0.025)], fill=rgba(mix(col, (0, 0, 0), 0.3), 170), width=lw(0.0025))
    if kind == "Goatee":
        pts = bezier((0.44, mouth_y + 0.07), (0.5, mouth_y + 0.2), (0.56, mouth_y + 0.07))
        ld.polygon([P(*p) for p in pts], fill=rgba(col, 240))
    img.alpha_composite(lay.filter(ImageFilter.GaussianBlur(0.8)))


def hondario_scales(img, scales, crest):
    lay = layer()
    ld = ImageDraw.Draw(lay)
    for side in (-1, 1):
        for row in range(3):
            for k in range(3 - row):
                x = 0.5 + side * (0.36 + 0.035 * k + 0.02 * row)
                y = 0.5 + 0.05 * row
                ld.chord([P(x - 0.022, y - 0.022), P(x + 0.022, y + 0.022)], 0, 180, fill=rgba(scales, 150), outline=rgba(crest, 200), width=lw(0.003))
    img.alpha_composite(lay)


# ---------------------------------------------------------------------------
# Caras especiales
# ---------------------------------------------------------------------------


def robot_face(expr):
    img = layer()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([P(0.14, 0.3), P(0.86, 0.86)], radius=0.08 * S, fill=(26, 32, 44, 245), outline=(120, 140, 160, 255), width=lw(0.012))
    glow = layer()
    gd = ImageDraw.Draw(glow)
    cyan = (90, 220, 255)
    for cx in (0.34, 0.66):
        if expr == "Happy":
            line(gd, bezier((cx - 0.07, 0.5), (cx, 0.42), (cx + 0.07, 0.5)), 0.022, rgba(cyan))
        elif expr == "Sad":
            line(gd, [(cx - 0.07, 0.46 + (0.03 if cx < 0.5 else -0.0)), (cx + 0.07, 0.46 + (0.0 if cx < 0.5 else 0.03))], 0.022, rgba(cyan))
            ellipse(gd, cx, 0.52, 0.035, 0.035, fill=rgba(cyan))
        elif expr == "Angry":
            gd.polygon([P(cx - 0.07, 0.44 + (0.0 if cx < 0.5 else 0.04)), P(cx + 0.07, 0.44 + (0.04 if cx < 0.5 else 0.0)), P(cx + 0.06, 0.55), P(cx - 0.06, 0.55)], fill=rgba(cyan))
        elif expr == "Scared":
            ellipse(gd, cx, 0.49, 0.06, 0.06, outline=rgba(cyan), width=lw(0.016))
            ellipse(gd, cx, 0.49, 0.015, 0.015, fill=rgba(cyan))
        else:
            gd.rounded_rectangle([P(cx - 0.06, 0.44), P(cx + 0.06, 0.55)], radius=0.03 * S, fill=rgba(cyan))
    if expr == "Talk":
        for i, hgt in enumerate((0.02, 0.05, 0.035, 0.06, 0.03, 0.045, 0.02)):
            x = 0.38 + i * 0.04
            gd.rectangle([P(x - 0.012, 0.72 - hgt), P(x + 0.012, 0.72 + hgt)], fill=rgba(cyan))
    elif expr == "Happy":
        line(gd, bezier((0.38, 0.68), (0.5, 0.78), (0.62, 0.68)), 0.018, rgba(cyan))
    elif expr == "Sad":
        line(gd, bezier((0.4, 0.76), (0.5, 0.69), (0.6, 0.76)), 0.018, rgba(cyan))
    elif expr == "Scared":
        ellipse(gd, 0.5, 0.73, 0.04, 0.05, outline=rgba(cyan), width=lw(0.014))
    else:
        line(gd, [(0.4, 0.72), (0.6, 0.72)], 0.018, rgba(cyan))
    img.alpha_composite(soft(glow, 0.012))
    img.alpha_composite(glow)
    # tornillos
    for x, y in ((0.18, 0.34), (0.82, 0.34), (0.18, 0.82), (0.82, 0.82)):
        ellipse(d, x, y, 0.012, 0.012, fill=(150, 160, 170, 255))
    return img


def mask_face(expr, spec):
    """Varkun: máscara de hilo tejido (retales) sobre ojos y cejas, ojos que brillan violeta."""
    img = layer()
    base = (70, 60, 86)
    d = ImageDraw.Draw(img)
    d.polygon([P(0.1, 0.3), P(0.9, 0.3), P(0.86, 0.6), P(0.62, 0.66), P(0.5, 0.6), P(0.38, 0.66), P(0.14, 0.6)], fill=rgba(base, 250))
    rnd = random.Random(5)
    for i in range(46):
        y = 0.31 + i * 0.0068
        d.line([P(0.12, y), P(0.88, y + rnd.uniform(-0.004, 0.004))], fill=rgba(mix(base, (200, 190, 220), 0.25 if i % 2 else 0.1), 200), width=lw(0.003))
    for i in range(30):
        x = 0.13 + i * 0.026
        d.line([P(x, 0.31), P(x + 0.004, 0.6)], fill=rgba(mix(base, (0, 0, 0), 0.3), 110), width=lw(0.0025))
    # costuras de retales
    for (a, b) in (((0.3, 0.31), (0.26, 0.6)), ((0.7, 0.31), (0.74, 0.6))):
        line(d, [a, b], 0.004, (200, 186, 220, 230))
        for k in range(8):
            t = (k + 0.5) / 8
            x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            d.line([P(x - 0.012, y), P(x + 0.012, y + 0.004)], fill=(220, 210, 236, 255), width=lw(0.004))
    glow = layer()
    gd = ImageDraw.Draw(glow)
    ex = EXPR[expr]
    for side, cx in ((-1, 0.36), (1, 0.64)):
        hgt = 0.03 * (1 - ex[0] * 0.8) * (1.3 if expr == "Scared" else 1)
        ellipse(d, cx, 0.47, 0.065, 0.045, fill=(18, 12, 26, 255))
        ellipse(gd, cx, 0.47, 0.04, max(0.008, hgt), fill=(200, 140, 255, 255))
    img.alpha_composite(soft(glow, 0.012))
    img.alpha_composite(glow)
    mouth(img, ex[8], 0.78, 0.9, 3)
    return img


def holo_face(expr):
    img = layer()
    teal = (236, 255, 250)  # (líneas claras: su «piel» ya es verde agua)
    d = ImageDraw.Draw(img)
    ex = EXPR[expr]
    for cx in (0.35, 0.65):
        top, bot = almond(cx, 0.5, 0.07, 0.035 * (1.4 if expr == "Scared" else 1))
        d.line([P(*p) for p in top + bot], fill=rgba(teal, 230), width=lw(0.008))
        ellipse(d, cx, 0.505, 0.02, 0.02, fill=rgba(teal, 230))
    for cx, side in ((0.35, -1), (0.65, 1)):
        line(d, [(cx - side * 0.07, 0.4 + ex[5]), (cx + side * 0.07, 0.4 + ex[6])], 0.007, rgba(teal, 220))
    mk = ex[8]
    if mk == "smile":
        line(d, bezier((0.41, 0.74), (0.5, 0.8), (0.59, 0.74)), 0.009, rgba(teal, 230))
    elif mk in ("talk", "scared"):
        ellipse(d, 0.5, 0.75, 0.07 if mk != "scared" else 0.035, 0.04, outline=rgba(teal, 230), width=lw(0.008))
    else:
        line(d, bezier((0.42, 0.75), (0.5, 0.75 + (0.02 if mk == "neutral" else -0.02)), (0.58, 0.75)), 0.008, rgba(teal, 230))
    for i in range(0, 60):
        y = 0.25 + i * 0.012
        d.line([P(0.18, y), P(0.82, y)], fill=rgba(teal, 26), width=1)
    # contorno oscuro para que se lea sobre el verde agua
    alpha = img.split()[3].filter(ImageFilter.MaxFilter(9))
    edge = Image.new("RGBA", img.size, (20, 80, 76, 0))
    edge.putalpha(alpha.point(lambda v: int(v * 0.8)))
    g = soft(img, 0.006)
    edge.alpha_composite(g)
    edge.alpha_composite(img)
    return edge


# ---------------------------------------------------------------------------
# La cara de una persona
# ---------------------------------------------------------------------------


def human_face(spec, expr, eye_colors):
    face = spec["Face"]
    colors = spec["Colors"] or {}
    age = face["Age"]
    fem = face["Fem"]
    kid = age in ("Kid", "Teen") and age == "Kid"
    young = age in ("Kid", "Teen")
    old = age == "Old"
    seed = sum(ord(c) for c in spec["Key"])
    hair = tuple(colors.get("Hair") or (70, 50, 36))
    skin = tuple(colors.get("Skin") or (220, 180, 140))
    browc = mix(hair, (40, 30, 26), 0.25) if not old else mix(hair, (120, 116, 112), 0.2)
    if face.get("Generic"):
        browc = (70, 52, 40) if not old else (170, 166, 160)
    iris = tuple(eye_colors[(face.get("Eye") or 1) - 1])
    if spec["Kind"] == "Hondario" and face.get("Crest"):
        iris = mix(tuple(face["Crest"]), (40, 60, 80), 0.25)
    ex = EXPR[expr]
    img = layer()
    # mejillas y sombras suaves (alfa: valen para cualquier piel)
    cheeks(img, 1.0 if (young or fem) else 0.55)
    if spec["Kind"] == "Hondario":
        hondario_scales(img, tuple(face.get("Scales") or (40, 160, 180)), tuple(face.get("Crest") or (120, 220, 230)))
    eye_y = 0.5
    w, h = (0.092, 0.066) if young else (0.088, 0.06)
    if kid:
        w, h = 0.098, 0.076
    if old:
        w, h = 0.086, 0.054
    eyes = [(0.325, eye_y), (0.675, eye_y)]
    for side, (cx, cy) in zip((-1, 1), eyes):
        eye(img, cx, cy, w, h, iris, ex, side, fem, kid, old)
    thick = (0.032 if not fem else 0.022) * (0.85 if young else 1.0)
    for side, (cx, cy) in zip((-1, 1), eyes):
        by = cy - h * 2.1 - 0.035 + ex[7]
        brow(img, cx + side * 0.008, by, 0.19, thick, ex[5] * 1.3, ex[6] * 1.3, side, browc, seed + side)
    nose(img, 0.625, mix(skin, (90, 50, 40), 0.5))
    if old:
        d = ImageDraw.Draw(img)
        for side in (-1, 1):
            line(d, bezier((0.5 + side * 0.07, 0.6), (0.5 + side * 0.13, 0.68), (0.5 + side * 0.12, 0.76)), 0.004, rgba((130, 88, 74), 120))
        line(d, bezier((0.36, 0.3), (0.5, 0.285), (0.64, 0.3)), 0.004, rgba((130, 88, 74), 90))
    if face.get("Freckles"):
        freckles(img, seed)
    mouth_y = 0.755
    if face.get("Beard"):
        beard(img, face["Beard"], hair, mouth_y, seed)
    mouth(img, ex[8], mouth_y, 1.25 if fem else 1.35, seed)
    if face.get("Glasses"):
        glasses(img, face["Glasses"], eyes, w, h)
    return img


def draw_face(spec, expr, eye_colors):
    kind = spec["Kind"]
    if kind == "Robot":
        return robot_face(expr)
    if kind == "Mask":
        return mask_face(expr, spec)
    if kind == "Holo":
        return holo_face(expr)
    return human_face(spec, expr, eye_colors)


# ---------------------------------------------------------------------------
# Ropa (plantillas clásicas 585x559, compartidas y teñidas en el juego)
# ---------------------------------------------------------------------------

W, H = 585, 559
TORSO = {"U": (231, 8, 128, 64), "F": (231, 74, 128, 128), "R": (165, 74, 64, 128), "L": (361, 74, 64, 128), "B": (427, 74, 128, 128), "D": (231, 204, 128, 64)}
RIGHT = {"L": (19, 355, 64, 128), "B": (85, 355, 64, 128), "R": (151, 355, 64, 128), "F": (217, 355, 64, 128), "U": (217, 289, 64, 64), "D": (217, 485, 64, 64)}
LEFT = {"F": (308, 355, 64, 128), "L": (374, 355, 64, 128), "B": (440, 355, 64, 128), "R": (506, 355, 64, 128), "U": (308, 289, 64, 64), "D": (308, 485, 64, 64)}
HAND = 18  # lo de abajo de cada cara del brazo es la mano en R15: transparente (se ve la piel)
SHORT = 56  # manga corta: hasta aquí

BASE = 236


def fabric_tile(w, h, seed, base=BASE, weave="plain"):
    rnd = np.random.default_rng(seed)
    n = rnd.normal(0, 4.0, (h, w))
    yy, xx = np.mgrid[0:h, 0:w]
    if weave == "denim":
        n += 7 * ((xx + yy) % 4 < 2)  # sarga en diagonal
    elif weave == "knit":
        n += 6 * np.sin(xx * 1.6) * (yy % 3 < 2)  # punto
    elif weave == "fleece":
        n = rnd.normal(0, 6.0, (h, w))
    else:
        n += 3 * ((xx % 2) ^ (yy % 2))
    v = np.clip(base + n, 0, 255).astype(np.uint8)
    rgb = np.stack([v, v, v, np.full_like(v, 255)], axis=-1)
    return Image.fromarray(rgb, "RGBA")


def fill(img, rect, tile, alpha_bottom=0, top_only=None):
    x, y, w, h = rect
    t = tile.crop((0, 0, w, h)).copy()
    if alpha_bottom or top_only:
        a = np.array(t)
        if alpha_bottom:
            a[h - alpha_bottom :, :, 3] = 0
        if top_only:
            a[top_only:, :, 3] = 0
        t = Image.fromarray(a, "RGBA")
    img.alpha_composite(t, (x, y))


def shade_folds(img, rect, seed, n=3, vertical=True, strength=26):
    """Pliegues: franjas suaves más oscuras y más claras (la tela no es plana)."""
    x, y, w, h = rect
    rnd = random.Random(seed)
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for _ in range(n):
        if vertical:
            cx = x + rnd.uniform(0.15, 0.85) * w
            d.line([(cx, y + rnd.uniform(0.2, 0.5) * h), (cx + rnd.uniform(-6, 6), y + h)], fill=(0, 0, 0, strength), width=rnd.randint(3, 6))
            d.line([(cx + 4, y + rnd.uniform(0.3, 0.6) * h), (cx + 6, y + h)], fill=(255, 255, 255, strength // 2), width=2)
        else:
            cy = y + rnd.uniform(0.2, 0.8) * h
            d.arc([x + 4, cy - 6, x + w - 4, cy + 6], 0, 180, fill=(0, 0, 0, strength), width=3)
    lay = lay.filter(ImageFilter.GaussianBlur(2.2))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rectangle([x, y, x + w - 1, y + h - 1], fill=255)
    a = np.array(img)[..., 3]
    mask = ImageChops.multiply(mask, Image.fromarray(a))
    clipped = Image.new("RGBA", img.size, (0, 0, 0, 0))
    clipped.paste(lay, (0, 0), mask)
    img.alpha_composite(clipped)


def seam(d, pts, dark=150, dashed=True):
    d.line(pts, fill=(dark, dark, dark, 255), width=1)
    if dashed:
        (x0, y0), (x1, y1) = pts[0], pts[-1]
        L = max(1, int(math.hypot(x1 - x0, y1 - y0) / 4))
        for k in range(L):
            t = (k + 0.5) / L
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            nx, ny = (y1 - y0), -(x1 - x0)
            m = math.hypot(nx, ny) or 1
            ox, oy = nx / m * 2, ny / m * 2
            d.point((x + ox, y + oy), fill=(dark + 30, dark + 30, dark + 30, 255))


def button(d, x, y, r=3):
    d.ellipse([x - r, y - r, x + r, y + r], fill=(205, 205, 205, 255), outline=(140, 140, 140, 255))
    d.point((x - 1, y), fill=(120, 120, 120, 255))
    d.point((x + 1, y), fill=(120, 120, 120, 255))


def arms(img, tile, short=False, cuff=True, seed=0):
    d = ImageDraw.Draw(img)
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            rx, ry, rw, rh = rect
            if key == "D":
                continue
            if key == "U":
                fill(img, rect, tile)
                continue
            if short:
                fill(img, rect, tile, top_only=SHORT)
                d.line([(rx, ry + SHORT - 6), (rx + rw, ry + SHORT - 6)], fill=(200, 200, 200, 255), width=2)
                seam(d, [(rx, ry + SHORT - 3), (rx + rw - 1, ry + SHORT - 3)], 170)
            else:
                fill(img, rect, tile, alpha_bottom=HAND)
                if cuff:
                    d.rectangle([rx, ry + rh - HAND - 12, rx + rw - 1, ry + rh - HAND - 1], fill=(226, 226, 226, 255))
                    seam(d, [(rx, ry + rh - HAND - 12), (rx + rw - 1, ry + rh - HAND - 12)], 160)
                shade_folds(img, (rx, ry + 60, rw, rh - HAND - 60), seed + rx, n=2, vertical=False, strength=30)
            seam(d, [(rx + 2, ry), (rx + 2, ry + (SHORT if short else rh - HAND))], 175, dashed=False)


def torso_all(img, tile):
    for key, rect in TORSO.items():
        fill(img, rect, tile)


def shirt_camiseta(seed):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tile = fabric_tile(128, 128, seed)
    torso_all(img, tile)
    arms(img, tile, short=True, seed=seed)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    d.arc([x + 34, y - 26, x + w - 34, y + 22], 0, 180, fill=(200, 200, 200, 255), width=6)  # cuello redondo canalé
    seam(d, [(x + 2, y + h - 10), (x + w - 2, y + h - 10)], 170)
    bx, by, bw, bh = TORSO["B"]
    d.line([(bx + 30, by + 4), (bx + bw - 30, by + 4)], fill=(205, 205, 205, 255), width=4)
    seam(d, [(bx + 2, by + bh - 10), (bx + bw - 2, by + bh - 10)], 170)
    for k in ("F", "B"):
        shade_folds(img, TORSO[k], seed + 3, n=3)
    return img


def shirt_sudadera(seed):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tile = fabric_tile(128, 128, seed, weave="fleece")
    torso_all(img, tile)
    arms(img, tile, seed=seed)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    # bolsillo canguro y cordones; capucha caída detrás
    d.polygon([(x + 22, y + 74), (x + w - 22, y + 74), (x + w - 12, y + h - 14), (x + 12, y + h - 14)], fill=(226, 226, 226, 255))
    seam(d, [(x + 22, y + 74), (x + w - 22, y + 74)], 160)
    for sx in (x + 22, x + w - 22):
        d.line([(sx, y + 74), (sx + (10 if sx < x + w / 2 else -10), y + h - 14)], fill=(170, 170, 170, 255), width=2)
    for cx in (x + 52, x + 76):
        d.line([(cx, y + 6), (cx + 1, y + 44)], fill=(200, 200, 200, 255), width=3)
        d.rectangle([cx - 2, y + 42, cx + 3, y + 48], fill=(170, 170, 170, 255))
    d.arc([x + 30, y - 30, x + w - 30, y + 20], 0, 180, fill=(196, 196, 196, 255), width=8)
    d.rectangle([x, y + h - 12, x + w, y + h], fill=(222, 222, 222, 255))  # elástico
    bx, by, bw, bh = TORSO["B"]
    d.ellipse([bx + 20, by - 10, bx + bw - 20, by + 58], fill=(224, 224, 224, 255), outline=(176, 176, 176, 255), width=2)
    seam(d, [(bx + bw // 2, by + 4), (bx + bw // 2, by + 50)], 165)
    d.rectangle([bx, by + bh - 12, bx + bw, by + bh], fill=(222, 222, 222, 255))
    for k in ("F", "B"):
        shade_folds(img, TORSO[k], seed + 5, n=3)
    return img


def shirt_camisa(seed, tucked=True):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tile = fabric_tile(128, 128, seed)
    for key, rect in TORSO.items():
        fill(img, rect, tile, alpha_bottom=(24 if tucked and key in ("F", "B", "L", "R") else 0))
    arms(img, tile, seed=seed)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    # cuello de camisa, tapeta con botones y bolsillo
    d.polygon([(x + 40, y), (x + 64, y + 22), (x + 52, y + 30), (x + 34, y + 8)], fill=(246, 246, 246, 255), outline=(170, 170, 170, 255))
    d.polygon([(x + w - 40, y), (x + 64, y + 22), (x + w - 52, y + 30), (x + w - 34, y + 8)], fill=(246, 246, 246, 255), outline=(170, 170, 170, 255))
    d.rectangle([x + 60, y + 22, x + 68, y + h - 24], fill=(228, 228, 228, 255))
    seam(d, [(x + 60, y + 22), (x + 60, y + h - 24)], 165)
    seam(d, [(x + 68, y + 22), (x + 68, y + h - 24)], 165)
    for by in range(y + 34, y + h - 26, 18):
        button(d, x + 64, by, 2)
    d.rectangle([x + 76, y + 36, x + 104, y + 62], outline=(170, 170, 170, 255), width=1)
    seam(d, [(x + 76, y + 40), (x + 104, y + 40)], 175)
    bx, by, bw, bh = TORSO["B"]
    seam(d, [(bx + 6, by + 20), (bx + bw - 6, by + 20)], 165)  # canesú
    for k in ("F", "B"):
        shade_folds(img, (TORSO[k][0], TORSO[k][1], TORSO[k][2], TORSO[k][3] - (24 if tucked else 0)), seed + 7, n=3)
    return img


def shirt_chaqueta(seed):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tile = fabric_tile(128, 128, seed, weave="denim", base=228)
    torso_all(img, tile)
    arms(img, tile, seed=seed)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    inner = fabric_tile(40, 128, seed + 1, base=250)
    img.alpha_composite(inner, (x + 44, y))  # camiseta de debajo (más clara)
    d = ImageDraw.Draw(img)
    for sx, sgn in ((x + 44, 1), (x + 84, -1)):
        d.polygon([(sx, y), (sx + sgn * 14, y), (sx, y + 60)], fill=(214, 214, 214, 255), outline=(150, 150, 150, 255))  # solapas
        seam(d, [(sx, y + 60), (sx, y + h)], 150)
    for by in (y + 72, y + 98):
        button(d, x + 38, by, 3)
    for px in (x + 8, x + 96):
        d.line([(px, y + 92), (px + 24, y + 92)], fill=(150, 150, 150, 255), width=2)  # bolsillos de solapa
    bx, by, bw, bh = TORSO["B"]
    seam(d, [(bx + bw // 2, by), (bx + bw // 2, by + bh)], 160)
    for k in ("F", "B"):
        shade_folds(img, TORSO[k], seed + 9, n=4, strength=30)
    return img


def shirt_rebeca(seed):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tile = fabric_tile(128, 128, seed, weave="knit")
    torso_all(img, tile)
    arms(img, tile, seed=seed)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    d.polygon([(x + 40, y), (x + 88, y), (x + 64, y + 46)], fill=(250, 250, 250, 255))  # escote en V
    d.line([(x + 40, y), (x + 64, y + 46), (x + 88, y)], fill=(196, 196, 196, 255), width=5)
    d.line([(x + 64, y + 46), (x + 64, y + h)], fill=(196, 196, 196, 255), width=5)
    for by in range(y + 56, y + h - 6, 16):
        button(d, x + 64, by, 3)
    for px in (x + 14, x + 84):
        d.rectangle([px, y + 82, px + 30, y + 108], outline=(190, 190, 190, 255), width=2)
    d.rectangle([x, y + h - 10, x + w, y + h], fill=(220, 220, 220, 255))
    for k in ("F", "B"):
        shade_folds(img, TORSO[k], seed + 11, n=3)
    return img


def shirt_uniforme(seed):
    img = shirt_camisa(seed, tucked=True)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    for px in (x + 14, x + 80):  # bolsillos de pecho con solapa
        d.rectangle([px, y + 30, px + 34, y + 62], outline=(150, 150, 150, 255), width=2, fill=(226, 226, 226, 255))
        d.polygon([(px - 2, y + 28), (px + 36, y + 28), (px + 34, y + 40), (px, y + 40)], fill=(214, 214, 214, 255), outline=(140, 140, 140, 255))
        button(d, px + 17, y + 36, 2)
    for key in ("L", "R"):
        rx, ry, rw, rh = TORSO[key]
    for arm in (RIGHT, LEFT):
        ux, uy, uw, uh = arm["U"]
        d.rectangle([ux + 8, uy + 10, ux + uw - 8, uy + uh - 10], fill=(214, 214, 214, 255), outline=(140, 140, 140, 255), width=2)  # hombreras
        button(d, ux + uw // 2, uy + 18, 3)
        fx, fy, fw, fh = arm["R"] if arm is RIGHT else arm["L"]
        d.rectangle([fx + 14, fy + 18, fx + fw - 14, fy + 40], fill=(200, 200, 200, 255), outline=(140, 140, 140, 255))  # parche (sin logos)
    return img


def shirt_bata(seed):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tile = fabric_tile(128, 128, seed, base=246)
    torso_all(img, tile)
    arms(img, tile, seed=seed)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    inner = fabric_tile(30, 128, seed + 2, base=200)
    img.alpha_composite(inner, (x + 49, y))
    d = ImageDraw.Draw(img)
    for sx, sgn in ((x + 49, 1), (x + 79, -1)):
        d.polygon([(sx, y), (sx + sgn * 16, y), (sx, y + 52)], fill=(250, 250, 250, 255), outline=(170, 170, 170, 255))
    for by in (y + 70, y + 98):
        button(d, x + 44, by, 3)
    d.rectangle([x + 86, y + 34, x + 110, y + 58], outline=(176, 176, 176, 255), width=2)
    d.line([(x + 92, y + 30), (x + 92, y + 44)], fill=(150, 150, 150, 255), width=3)  # un bolígrafo (sin marca)
    for px in (x + 8, x + 90):
        d.rectangle([px, y + 96, px + 30, y + 122], outline=(176, 176, 176, 255), width=2)
    for k in ("F", "B"):
        shade_folds(img, TORSO[k], seed + 13, n=3, strength=20)
    return img


def shirt_delantal(seed):
    img = shirt_camiseta(seed)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    apron = fabric_tile(96, 110, seed + 3, base=252)
    img.alpha_composite(apron, (x + 16, y + 18))
    d = ImageDraw.Draw(img)
    d.rectangle([x + 16, y + 18, x + w - 16, y + h], outline=(180, 180, 180, 255), width=2)
    for sx in (x + 22, x + w - 22):
        d.line([(sx, y + 18), (sx + (8 if sx < x + w / 2 else -8), y)], fill=(190, 190, 190, 255), width=4)  # tirantes
    d.rectangle([x + 36, y + 80, x + w - 36, y + 106], outline=(180, 180, 180, 255), width=2)  # bolsillo
    seam(d, [(x + 64, y + 80), (x + 64, y + 106)], 170)
    for side in ("L", "R"):
        rx, ry, rw, rh = TORSO[side]
        d.line([(rx, ry + 92), (rx + rw, ry + 92)], fill=(200, 200, 200, 255), width=4)  # lazada
    bx, by, bw, bh = TORSO["B"]
    d.line([(bx, by + 92), (bx + bw, by + 92)], fill=(200, 200, 200, 255), width=4)
    d.line([(bx + bw // 2, by + 92), (bx + bw // 2 - 10, by + 118)], fill=(200, 200, 200, 255), width=3)
    d.line([(bx + bw // 2, by + 92), (bx + bw // 2 + 10, by + 118)], fill=(200, 200, 200, 255), width=3)
    return img


def shirt_mono(seed):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tile = fabric_tile(128, 128, seed, weave="denim", base=226)
    torso_all(img, tile)
    arms(img, tile, seed=seed)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    d.line([(x + 64, y + 14), (x + 64, y + h)], fill=(160, 160, 160, 255), width=3)  # cremallera
    for k in range(y + 16, y + h, 6):
        d.line([(x + 62, k), (x + 66, k)], fill=(190, 190, 190, 255), width=1)
    d.rectangle([x + 14, y + 30, x + 44, y + 56], outline=(150, 150, 150, 255), width=2)
    d.rectangle([x + 84, y + 30, x + 114, y + 56], outline=(150, 150, 150, 255), width=2)
    d.rectangle([x, y + h - 22, x + w, y + h - 12], fill=(212, 212, 212, 255))  # cinturilla
    d.polygon([(x + 40, y), (x + 64, y + 14), (x + 88, y)], fill=(218, 218, 218, 255), outline=(150, 150, 150, 255))
    for k in ("F", "B"):
        shade_folds(img, TORSO[k], seed + 15, n=4, strength=30)
    return img


SHIRTS = {
    "Camiseta": shirt_camiseta,
    "Sudadera": shirt_sudadera,
    "Camisa": shirt_camisa,
    "Chaqueta": shirt_chaqueta,
    "Rebeca": shirt_rebeca,
    "Uniforme": shirt_uniforme,
    "Bata": shirt_bata,
    "Delantal": shirt_delantal,
    "Mono": shirt_mono,
}


def pants_base(seed, weave="plain", base=BASE):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tile = fabric_tile(128, 128, seed, weave=weave, base=base)
    torso_all(img, tile)
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            fill(img, rect, tile)
    d = ImageDraw.Draw(img)
    # cinturilla con trabillas
    for key in ("F", "B", "L", "R"):
        x, y, w, h = TORSO[key]
        d.rectangle([x, y + h - 26, x + w, y + h - 16], fill=(210, 210, 210, 255))
        seam(d, [(x, y + h - 16), (x + w - 1, y + h - 16)], 160)
        for k in range(1, 4):
            lx = x + w * k // 4
            d.rectangle([lx - 2, y + h - 28, lx + 2, y + h - 12], fill=(196, 196, 196, 255))
    for arm in (RIGHT, LEFT):
        for key in ("F", "B", "L", "R"):
            rx, ry, rw, rh = arm[key]
            seam(d, [(rx + 3, ry), (rx + 3, ry + rh)], 170, dashed=False)
            seam(d, [(rx + rw - 4, ry), (rx + rw - 4, ry + rh)], 170, dashed=False)
            shade_folds(img, (rx, ry + 40, rw, 70), seed + rx, n=2, vertical=False, strength=34)  # rodilla
            d.rectangle([rx, ry + rh - 10, rx + rw - 1, ry + rh - 1], fill=(214, 214, 214, 255))  # bajo
    return img


def pants_vaqueros(seed):
    img = pants_base(seed, weave="denim", base=226)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    d.line([(x + 64, y + h - 16), (x + 64, y + h)], fill=(150, 150, 150, 255), width=2)
    for sx, sgn in ((x + 10, 1), (x + w - 10, -1)):
        d.arc([sx - 24, y + h - 30, sx + 24, y + h + 18], 270 if sgn > 0 else 180, 360 if sgn > 0 else 270, fill=(160, 160, 160, 255), width=2)
        d.ellipse([sx + sgn * 14 - 2, y + h - 14, sx + sgn * 14 + 2, y + h - 10], fill=(190, 190, 190, 255))  # remache (sin marca)
    bx, by, bw, bh = TORSO["B"]
    for px in (bx + 14, bx + 74):
        d.polygon([(px, by + bh - 12), (px + 40, by + bh - 12), (px + 36, by + bh), (px + 4, by + bh)], outline=(160, 160, 160, 255))
    # pespuntes dobles por fuera de la pierna
    for arm, outer in ((RIGHT, "R"), (LEFT, "L")):
        rx, ry, rw, rh = arm[outer]
        seam(d, [(rx + rw // 2 - 2, ry), (rx + rw // 2 - 2, ry + rh)], 150)
        seam(d, [(rx + rw // 2 + 2, ry), (rx + rw // 2 + 2, ry + rh)], 150)
    return img


def pants_pantalon(seed):
    img = pants_base(seed)
    d = ImageDraw.Draw(img)
    for arm in (RIGHT, LEFT):
        rx, ry, rw, rh = arm["F"]
        d.line([(rx + rw // 2, ry), (rx + rw // 2, ry + rh - 10)], fill=(214, 214, 214, 255), width=2)  # raya
        d.line([(rx + rw // 2 + 2, ry), (rx + rw // 2 + 2, ry + rh - 10)], fill=(250, 250, 250, 255), width=1)
    x, y, w, h = TORSO["F"]
    d.line([(x + 64, y + h - 16), (x + 64, y + h)], fill=(160, 160, 160, 255), width=2)
    return img


def pants_cargo(seed):
    img = pants_base(seed, weave="denim", base=230)
    d = ImageDraw.Draw(img)
    for arm, outer in ((RIGHT, "R"), (LEFT, "L")):
        rx, ry, rw, rh = arm[outer]
        d.rectangle([rx + 10, ry + 30, rx + rw - 10, ry + 64], fill=(220, 220, 220, 255), outline=(150, 150, 150, 255), width=2)
        d.rectangle([rx + 8, ry + 26, rx + rw - 8, ry + 38], fill=(206, 206, 206, 255), outline=(140, 140, 140, 255), width=2)
        button(d, rx + rw // 2, ry + 32, 2)
        seam(d, [(rx + 12, ry + 60), (rx + rw - 12, ry + 60)], 170)
    return img


def pants_chandal(seed):
    img = pants_base(seed, weave="fleece", base=238)
    d = ImageDraw.Draw(img)
    for arm, outer in ((RIGHT, "R"), (LEFT, "L")):
        rx, ry, rw, rh = arm[outer]
        d.rectangle([rx + rw // 2 - 5, ry, rx + rw // 2 + 5, ry + rh], fill=(252, 252, 252, 255))  # franja (sin marca)
        d.rectangle([rx + rw // 2 - 5, ry, rx + rw // 2 - 4, ry + rh], fill=(200, 200, 200, 255))
        d.rectangle([rx + rw // 2 + 4, ry, rx + rw // 2 + 5, ry + rh], fill=(200, 200, 200, 255))
        for key in ("F", "B", "L", "R"):
            fx, fy, fw, fh = arm[key]
            d.rectangle([fx, fy + fh - 14, fx + fw - 1, fy + fh - 1], fill=(220, 220, 220, 255))  # puño elástico
    x, y, w, h = TORSO["F"]
    for cx in (x + 56, x + 72):
        d.line([(cx, y + h - 20), (cx + (-3 if cx < x + 64 else 3), y + h - 4)], fill=(190, 190, 190, 255), width=2)
    return img


def pants_mono(seed):
    img = pants_base(seed, weave="denim", base=226)
    d = ImageDraw.Draw(img)
    for arm in (RIGHT, LEFT):
        rx, ry, rw, rh = arm["F"]
        d.rectangle([rx + 10, ry + 64, rx + rw - 10, ry + 84], fill=(212, 212, 212, 255), outline=(150, 150, 150, 255))  # rodillera
    return img


PANTS = {"Vaqueros": pants_vaqueros, "Pantalon": pants_pantalon, "Cargo": pants_cargo, "Chandal": pants_chandal, "Mono": pants_mono}


def hair_tile(seed=3, size=256):
    rnd = random.Random(seed)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for _ in range(520):
        x = rnd.uniform(0, size)
        a = rnd.randint(60, 190)
        w = rnd.choice((1, 1, 2, 2, 3))
        bend = rnd.uniform(-10, 10)
        pts = [(x + bend * math.sin(t / size * math.pi) + dx, t) for t, dx in ((0, 0), (size / 2, 0), (size, 0))]
        for dx in (-size, 0, size):  # (se repite sin costura)
            d.line([(p[0] + dx, p[1]) for p in pts], fill=(255, 255, 255, a), width=w)
    return img.filter(ImageFilter.GaussianBlur(0.6))


def save(img, path, size=None, colors=None):
    """Guarda (reducida a `size`). Con `colors`, PNG de paleta con transparencia: pesa ~4 veces menos
    (repo y descarga en el móvil) y en una cara de dibujo no se nota."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if size and img.size != (size, size):
        img = img.reduce(img.size[0] // size) if img.size[0] % size == 0 else img.resize((size, size), Image.LANCZOS)
    if colors:
        img = img.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    img.save(path, optimize=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solo", default="", help="claves de cara separadas por comas (las demás no se tocan)")
    ap.add_argument("--sin-ropa", action="store_true")
    args = ap.parse_args()
    data = json.load(open(DATA))
    only = {k for k in args.solo.split(",") if k}
    done = set()
    n = 0
    groups = {}  # nombre de imagen -> grupo (orden de subida: scripts/upload-personajes.sh --grupo)
    for spec in data["Characters"]:
        key = spec["Key"]
        if not spec["Faces"] or key in done or (only and key not in only):
            continue
        done.add(key)
        size = 512 if len(spec["Faces"]) == len(data["Full"]) else 256
        for expr in spec["Faces"]:
            img = draw_face(spec, expr, data["EyeColors"])
            name = "pj_cara_%s_%s" % (key.lower(), expr.lower())
            groups[name] = spec.get("Group") or "Otros"
            save(img, os.path.join(OUT, "caras", name + ".png"), size, colors=160)
            n += 1
    print("  ✅ %d caras de %d personajes" % (n, len(done)))
    if not only:
        names = sorted(groups)
        for style in SHIRTS:
            names.append("pj_ropa_%s" % style.lower())
        for style in PANTS:
            names.append("pj_pantalon_%s" % style.lower())
        names.append(data["HairFile"])
        with open(os.path.join(OUT, "grupos.txt"), "w") as f:
            f.write("# GENERADO por scripts/personajes/gen.py: <imagen> <grupo> (Ropa, Saga1, Saga2, Nacara, Otros)\n")
            for name in sorted(names):
                f.write("%s %s\n" % (name, groups.get(name, "Ropa")))
    if args.sin_ropa:
        return
    for style, fn in SHIRTS.items():
        save(fn(11 + len(style)), os.path.join(OUT, "ropa", "pj_ropa_%s.png" % style.lower()))
    for style, fn in PANTS.items():
        save(fn(21 + len(style)), os.path.join(OUT, "ropa", "pj_pantalon_%s.png" % style.lower()))
    print("  ✅ %d plantillas de ropa compartidas" % (len(SHIRTS) + len(PANTS)))
    save(hair_tile(), os.path.join(OUT, "pelo", data["HairFile"] + ".png"))
    print("  ✅ mechones del pelo")


if __name__ == "__main__":
    main()
