#!/usr/bin/env python3
"""Estilo bloque (encargo del dueño, referencia docs/personajes/referencia/cosme-estilo-dueno.png): las
CARAS dibujadas a mano (una por expresión, una sola boca) y la ROPA con textura de las plantillas clásicas
de Roblox (Shirt/Pants 585x559: pliegues, costuras, manchas y sombras) de cada personaje del piloto.
Lo llama scripts/personajes/bloque_blender.py (también sirve solo: solo necesita Pillow y numpy).

Arte original: Cosme es un inventor loco de pelo de punta, gafas y bata, pero con detalles propios
(gafas cian, mochila, sus aparatos, el colgante azul y el tubo morado de su pistola). Nada de babas ni de
rasgos de ningún personaje conocido.

    caras:  assets/bloque/caras/bloque_<clave>_cara_<expresión>.png   512 px, fondo transparente
    ropa:   assets/bloque/ropa/bloque_<clave>_camisa.png / _pantalon.png   585x559
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

import gen as GEN  # noqa: E402  (plantilla clásica: TORSO, RIGHT, LEFT, HAND, tejido, costuras)

OUT = os.path.join(ROOT, "assets", "bloque")
S = 1024  # se dibuja a 1024 y se reduce a 512 (bordes suaves)
INK = (30, 24, 26, 255)


def P(x, y):
    return (x * S, y * S)


def W_(k):
    return max(1, int(k * S))


# ====================================================================== caras
def ellipse(d, cx, cy, rx, ry, fill, outline=None, width=0.0):
    d.ellipse([P(cx - rx, cy - ry), P(cx + rx, cy + ry)], fill=fill, outline=outline, width=W_(width) if outline else 0)


def poly(d, pts, fill, outline=None, width=0.0):
    d.polygon([P(*p) for p in pts], fill=fill)
    if outline:
        d.line([P(*p) for p in pts + [pts[0]]], fill=outline, width=W_(width), joint="curve")


def stroke(d, pts, width, fill):
    d.line([P(*p) for p in pts], fill=fill, width=W_(width), joint="curve")
    r = width / 2
    for p in (pts[0], pts[-1]):
        ellipse(d, p[0], p[1], r * 0.95, r * 0.95, fill)


def curve(p0, p1, p2, n=24):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0], (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]) for t in [i / n for i in range(n + 1)]]


def eye(d, cx, cy, r, iris=None, pupil=0.32, look=(0.0, 0.0), lid=0.0, lid_angle=0.0, lash=False, glow=None):
    """Ojo de dibujo: blanco con borde grueso, iris (si lo hay), pupila y brillo. lid = cuánto tapa el
    párpado de arriba (0..1); lid_angle inclina el párpado (escéptico, enfadado)."""
    if glow:  # (Pip: ojos de luz en su pantalla)
        ellipse(d, cx, cy, r * 1.25, r * 1.25, (glow[0], glow[1], glow[2], 70))
        ellipse(d, cx, cy, r, r * 1.08, (glow[0], glow[1], glow[2], 255))
        ellipse(d, cx - r * 0.3, cy - r * 0.35, r * 0.28, r * 0.22, (255, 255, 255, 230))
    else:
        ellipse(d, cx, cy, r, r * 1.04, (250, 250, 246, 255), INK, 0.016)
        px, py = cx + look[0] * r * 0.35, cy + look[1] * r * 0.35
        if iris:
            ellipse(d, px, py, r * 0.52, r * 0.55, iris + (255,))
            ellipse(d, px, py + r * 0.12, r * 0.42, r * 0.3, tuple(int(c * 0.75) for c in iris) + (255,))
        ellipse(d, px, py, r * pupil, r * pupil * 1.05, INK)
        ellipse(d, px - r * 0.18, py - r * 0.2, r * 0.12, r * 0.12, (255, 255, 255, 255))
    if lid > 0:
        # párpado: tapa la parte de arriba con color de piel... aquí con transparencia no se puede: se dibuja
        # la línea del párpado gruesa y se borra lo de encima (el que llama pasa el color de la piel)
        pass
    if lash:
        for k in (-1, 0):
            a = math.radians(205 + k * 18)
            x0, y0 = cx + math.cos(a) * r, cy + math.sin(a) * r
            stroke(d, [(x0, y0), (x0 - 0.035, y0 - 0.02)], 0.012, INK)


def lid_cover(d, cx, cy, r, amount, angle, skin):
    """Párpado de arriba (del color de la piel) que tapa `amount` del ojo, inclinado `angle` (grados)."""
    if amount <= 0:
        return
    h = r * 2 * amount
    a = math.radians(angle)
    top = cy - r * 1.15
    edge = cy - r + h
    dx = math.tan(a) * r
    poly(d, [(cx - r * 1.2, top), (cx + r * 1.2, top), (cx + r * 1.2, edge - dx), (cx - r * 1.2, edge + dx)], skin)
    stroke(d, [(cx - r * 1.02, edge + dx * 0.85), (cx + r * 1.02, edge - dx * 0.85)], 0.018, INK)


def brow(d, cx, cy, w, tilt, color, thick=0.05, arch=0.02):
    """Ceja gruesa con borde (tilt > 0: la punta de dentro abajo = enfadado)."""
    x0, x1 = cx - w / 2, cx + w / 2
    pts = curve((x0, cy + tilt), (cx, cy - arch * 2), (x1, cy - tilt))
    top = [(x, y - thick / 2) for x, y in pts]
    bot = [(x, y + thick / 2) for x, y in reversed(pts)]
    poly(d, top + bot, color + (255,), INK, 0.01)


def mouth_shape(kind, cx, cy, w, open_=0.0):
    """Puntos del contorno de la boca."""
    if kind == "grin":  # sonrisa ancha en D (abierta)
        top = curve((cx - w, cy - 0.02), (cx, cy + 0.02), (cx + w, cy - 0.03))
        bot = curve((cx + w, cy - 0.03), (cx, cy + 0.06 + open_), (cx - w, cy - 0.02))
        return top + bot
    if kind == "o":
        return [(cx + math.cos(a) * w, cy + math.sin(a) * (w * 1.3 + open_)) for a in [i * math.pi / 14 for i in range(28)]]
    if kind == "laugh":
        top = curve((cx - w, cy - 0.03), (cx, cy - 0.01), (cx + w, cy - 0.03))
        bot = curve((cx + w, cy - 0.03), (cx, cy + 0.11 + open_), (cx - w, cy - 0.03))
        return top + bot
    if kind == "talk":
        top = curve((cx - w, cy - 0.01), (cx, cy - 0.025), (cx + w, cy - 0.01))
        bot = curve((cx + w, cy - 0.01), (cx, cy + 0.07 + open_), (cx - w, cy - 0.01))
        return top + bot
    if kind == "sad":
        top = curve((cx - w, cy + 0.02), (cx, cy - 0.03), (cx + w, cy + 0.02))
        bot = curve((cx + w, cy + 0.02), (cx, cy + 0.0), (cx - w, cy + 0.02))
        return top + bot
    return None


def mouth(d, kind, cx, cy, w, teeth=None, tongue=True, lip=None, open_=0.0):
    if kind in ("line", "smile", "frown", "smirk"):
        if kind == "line":
            pts = curve((cx - w, cy), (cx, cy + 0.005), (cx + w, cy))
        elif kind == "smile":
            pts = curve((cx - w, cy - 0.015), (cx, cy + 0.035), (cx + w, cy - 0.015))
        elif kind == "frown":
            pts = curve((cx - w, cy + 0.02), (cx, cy - 0.025), (cx + w, cy + 0.02))
        else:
            pts = curve((cx - w, cy + 0.01), (cx + w * 0.2, cy + 0.01), (cx + w, cy - 0.03))
        stroke(d, pts, 0.018, INK)
        if lip:
            stroke(d, [(p[0], p[1] + 0.018) for p in pts[6:-6]], 0.01, lip + (150,))
        return
    pts = mouth_shape(kind, cx, cy, w, open_)
    poly(d, pts, (70, 14, 22, 255))
    # lengua
    if tongue:
        ys = [p[1] for p in pts]
        yb = max(ys)
        ellipse(d, cx, yb - 0.025, w * 0.55, 0.035, (215, 70, 80, 255))
    if teeth:
        ys = [p[1] for p in pts]
        ytop = min(ys)
        n = teeth
        for i in range(n):
            x0 = cx - w * 0.82 + i * (w * 1.64 / n)
            if i == n // 2 + 1:  # un hueco (dientes de inventor despistado, sin más)
                continue
            poly(d, [(x0 + 0.004, ytop + 0.006), (x0 + w * 1.64 / n - 0.004, ytop + 0.006), (x0 + w * 1.64 / n - 0.006, ytop + 0.05), (x0 + 0.006, ytop + 0.05)],
                 (252, 250, 240, 255), INK, 0.006)
    d.line([P(*p) for p in pts + [pts[0]]], fill=INK, width=W_(0.016), joint="curve")


def face_canvas():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def finish_face(img, path):
    img = img.resize((512, 512), Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    return path


def cosme_face(expr, path):
    """Las caras de Cosme (sonrisa loca, escéptico, riéndose, asustado y hablando)."""
    img, d = face_canvas()
    skin = (238, 200, 162, 255)
    browc = (176, 208, 240)
    L, R = (0.3, 0.5), (0.7, 0.5)
    r = 0.165
    # arrugas (pata de gallo y ojeras): de inventor que no duerme
    for cx, sx in ((L[0], -1), (R[0], 1)):
        stroke(d, curve((cx - 0.09, 0.66), (cx, 0.69), (cx + 0.09, 0.66)), 0.009, (120, 80, 60, 200))
    if expr == "Grin":
        eye(d, *L, r * 1.05, pupil=0.26, look=(0.15, 0.0))
        eye(d, *R, r * 0.95, pupil=0.3, look=(-0.2, 0.1))
        lid_cover(d, *R, r * 0.95, 0.42, -12, skin)
        brow(d, L[0], 0.29, 0.26, -0.035, browc, 0.07, 0.03)
        brow(d, R[0], 0.33, 0.26, 0.03, browc, 0.07, 0.0)
        mouth(d, "grin", 0.5, 0.78, 0.25, teeth=7, open_=0.05)
    elif expr == "Skeptic":
        eye(d, *L, r, pupil=0.3, look=(0.3, 0.1))
        eye(d, *R, r, pupil=0.3, look=(0.3, 0.1))
        lid_cover(d, *L, r, 0.45, 0, skin)
        lid_cover(d, *R, r, 0.55, 8, skin)
        brow(d, L[0], 0.28, 0.26, -0.02, browc, 0.07, 0.02)
        brow(d, R[0], 0.34, 0.26, 0.02, browc, 0.07, 0.0)
        mouth(d, "smirk", 0.53, 0.8, 0.13)
    elif expr == "Laugh":
        for c in (L, R):
            stroke(d, curve((c[0] - 0.1, c[1] + 0.02), (c[0], c[1] - 0.07), (c[0] + 0.1, c[1] + 0.02)), 0.025, INK)
        brow(d, L[0], 0.29, 0.26, -0.02, browc, 0.07, 0.03)
        brow(d, R[0], 0.29, 0.26, -0.02, browc, 0.07, 0.03)
        mouth(d, "laugh", 0.5, 0.76, 0.23, teeth=6, open_=0.04)
    elif expr == "Scared":
        eye(d, *L, r * 1.08, pupil=0.16, look=(0.0, -0.1))
        eye(d, *R, r * 1.08, pupil=0.16, look=(0.0, -0.1))
        brow(d, L[0], 0.27, 0.26, 0.04, browc, 0.065, 0.04)
        brow(d, R[0], 0.27, 0.26, 0.04, browc, 0.065, 0.04)
        mouth(d, "o", 0.5, 0.8, 0.055, tongue=False, open_=0.015)
        # gota de sudor (azul claro, en la sien)
        poly(d, [(0.86, 0.36), (0.89, 0.43), (0.86, 0.46), (0.83, 0.43)], (160, 210, 255, 230), INK, 0.006)
    else:  # Talk: la de hablar (boca abierta, ojos de la sonrisa)
        eye(d, *L, r * 1.05, pupil=0.26, look=(0.15, 0.0))
        eye(d, *R, r * 0.95, pupil=0.3, look=(-0.2, 0.1))
        lid_cover(d, *R, r * 0.95, 0.35, -12, skin)
        brow(d, L[0], 0.29, 0.26, -0.035, browc, 0.07, 0.03)
        brow(d, R[0], 0.33, 0.26, 0.03, browc, 0.07, 0.0)
        mouth(d, "talk", 0.5, 0.78, 0.18, teeth=5, open_=0.05)
    # nariz: una línea en C, sin más
    stroke(d, curve((0.52, 0.6), (0.47, 0.66), (0.52, 0.68)), 0.013, (110, 70, 55, 255))
    return finish_face(img, path)


def person_face(spec, expr, path):
    """Las caras de los demás: misma mano (borde grueso, ojos grandes), cada uno con lo suyo."""
    img, d = face_canvas()
    F = spec.get("Face", {})
    skin = tuple(spec["Skin"]) + (255,)
    browc = tuple(F.get("Brow", spec["Hair"]))
    iris = tuple(spec.get("Eye", (92, 60, 38)))
    L, R = (0.33, 0.48), (0.67, 0.48)
    r = F.get("EyeR", 0.115)
    lash = F.get("Lash", False)
    lip = tuple(F["Lip"]) if F.get("Lip") else None
    glow = tuple(F["Glow"]) if F.get("Glow") else None
    if glow:  # Pip: pantalla de robot (la pantalla oscura la pone la cabeza; aquí la luz)
        g = glow
        if expr == "Happy" or expr == "Talk":
            for c in (L, R):
                stroke(d, curve((c[0] - 0.09, c[1] + 0.02), (c[0], c[1] - 0.06), (c[0] + 0.09, c[1] + 0.02)), 0.04, g + (255,))
        elif expr == "Sad":
            for c, s in ((L, -1), (R, 1)):
                eye(d, c[0], c[1] + 0.02, r * 0.9, glow=g)
                stroke(d, [(c[0] - 0.1, c[1] - 0.12 - s * 0.03), (c[0] + 0.1, c[1] - 0.12 + s * 0.03)], 0.03, g + (255,))
        elif expr == "Angry":
            for c, s in ((L, -1), (R, 1)):
                eye(d, c[0], c[1] + 0.02, r * 0.85, glow=g)
                stroke(d, [(c[0] - 0.1, c[1] - 0.13 + s * 0.04), (c[0] + 0.1, c[1] - 0.13 - s * 0.04)], 0.03, g + (255,))
        elif expr == "Scared":
            for c in (L, R):
                eye(d, c[0], c[1], r * 1.2, glow=g)
                stroke(d, [(c[0] - 0.09, c[1] - 0.2), (c[0] + 0.09, c[1] - 0.2)], 0.025, g + (255,))
        else:
            for c in (L, R):
                eye(d, c[0], c[1], r, glow=g)
        if expr in ("Talk", "Scared"):
            ellipse(d, 0.5, 0.75, 0.07 if expr == "Talk" else 0.05, 0.05, (0, 0, 0, 0), g + (255,), 0.022)
        elif expr == "Sad" or expr == "Angry":
            stroke(d, curve((0.4, 0.78), (0.5, 0.72), (0.6, 0.78)), 0.025, g + (255,))
        else:
            stroke(d, curve((0.38, 0.73), (0.5, 0.8), (0.62, 0.73)), 0.025, g + (255,))
        return finish_face(img, path)
    # mejillas
    for c in (L, R):
        ellipse(d, c[0] + (0.03 if c is R else -0.03), 0.66, 0.07, 0.04, (230, 120, 110, 60))
    if F.get("Freckles"):
        rr = random.Random(4)
        for _ in range(14):
            x = rr.choice((rr.uniform(0.2, 0.38), rr.uniform(0.62, 0.8)))
            ellipse(d, x, rr.uniform(0.6, 0.68), 0.006, 0.006, (150, 90, 60, 200))
    if F.get("Wrinkles"):
        for c in (L, R):
            stroke(d, curve((c[0] - 0.07, 0.6), (c[0], 0.625), (c[0] + 0.07, 0.6)), 0.007, (130, 90, 70, 170))
        stroke(d, curve((0.4, 0.2), (0.5, 0.19), (0.6, 0.2)), 0.006, (130, 90, 70, 140))
    if F.get("Stubble"):
        rr = random.Random(9)
        for _ in range(420):
            a = rr.uniform(0, math.pi)
            rad = rr.uniform(0.3, 0.46)
            x, y = 0.5 + math.cos(a) * rad, 0.62 + math.sin(a) * rad * 0.7
            if 0.05 < x < 0.95 and y < 0.99 and not (0.36 < x < 0.64 and 0.66 < y < 0.82):
                ellipse(d, x, y, 0.004, 0.004, tuple(int(c * 0.7) for c in browc) + (120,))
    look = (0.0, 0.0)
    tilt = 0.0
    lidamt = 0.0
    mk = "smile"
    open_ = 0.0
    if expr == "Happy":
        mk, open_ = "laugh", -0.04
    elif expr == "Sad":
        tilt, mk, lidamt, look = -0.03, "frown", 0.25, (0.0, 0.3)
    elif expr == "Angry":
        tilt, mk, lidamt = 0.035, "frown", 0.2
    elif expr == "Scared":
        tilt, mk = -0.035, "o"
    elif expr == "Talk":
        mk = "talk"
    eye_r = r * (1.12 if expr == "Scared" else 1.0)
    for c, s in ((L, -1), (R, 1)):
        if expr == "Happy":
            stroke(d, curve((c[0] - 0.08, c[1] + 0.02), (c[0], c[1] - 0.06), (c[0] + 0.08, c[1] + 0.02)), 0.022, INK)
        else:
            eye(d, c[0], c[1], eye_r, iris=iris, pupil=0.24 if expr == "Scared" else 0.3, look=look, lash=lash)
            lid_cover(d, c[0], c[1], eye_r, lidamt + F.get("Lid", 0.0), (s * tilt * 300 if expr == "Angry" else -s * 8 if expr == "Sad" else 0), skin)
        by = c[1] - eye_r - 0.065 + (-0.03 if expr == "Scared" else 0)
        brow(d, c[0], by, 0.2, s * -tilt if expr != "Angry" else s * -tilt, browc, F.get("BrowThick", 0.04), 0.02)
    if F.get("Glasses"):
        for c in (L, R):
            ellipse(d, c[0], c[1], r * 1.45, r * 1.45, (0, 0, 0, 0), (120, 90, 60, 255), 0.014)
        stroke(d, curve((L[0] + r * 1.4, L[1]), (0.5, L[1] - 0.03), (R[0] - r * 1.4, R[1])), 0.012, (120, 90, 60, 255))
    # nariz
    stroke(d, curve((0.5, 0.57), (0.46, 0.63), (0.51, 0.645)), 0.011, (int(skin[0] * 0.55), int(skin[1] * 0.45), int(skin[2] * 0.4), 255))
    if F.get("Mustache"):
        mc = tuple(F["Mustache"]) + (255,)
        for s in (-1, 1):
            poly(d, [(0.5, 0.685), (0.5 + s * 0.14, 0.7), (0.5 + s * 0.17, 0.75), (0.5 + s * 0.06, 0.725), (0.5, 0.72)], mc, INK, 0.008)
    my = 0.77 if not F.get("Mustache") else 0.8
    if mk in ("laugh", "talk", "o"):
        mouth(d, mk, 0.5, my - (0.02 if mk == "laugh" else 0), 0.11 if mk != "o" else 0.04, teeth=4 if mk == "laugh" else None, tongue=mk != "o", open_=open_)
    else:
        mouth(d, mk, 0.5, my, 0.09, lip=lip)
    return finish_face(img, path)


# ====================================================================== ropa (plantillas clásicas)
TW, TH = GEN.W, GEN.H
TORSO, RIGHT, LEFT, HAND = GEN.TORSO, GEN.RIGHT, GEN.LEFT, GEN.HAND


def tinted_tile(w, h, seed, color, weave="plain", grain=1.0):
    t = np.array(GEN.fabric_tile(w, h, seed, 236, weave)).astype(np.float32)
    k = (t[..., :3] - 236) * grain
    col = np.array(color, dtype=np.float32)
    out = np.clip(col + k, 0, 255)
    a = np.full((h, w, 1), 255, dtype=np.float32)
    return Image.fromarray(np.concatenate([out, a], axis=-1).astype(np.uint8), "RGBA")


def paint_rect(img, rect, tile, alpha_bottom=0):
    GEN.fill(img, rect, tile, alpha_bottom=alpha_bottom)


def stains(img, rect, seed, n=6, color=(150, 135, 100), alpha=70, size=(3, 10)):
    x, y, w, h = rect
    rr = random.Random(seed)
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    for _ in range(n):
        cx, cy = x + rr.uniform(0.1, 0.9) * w, y + rr.uniform(0.1, 0.9) * h
        s = rr.uniform(*size)
        d.ellipse([cx - s, cy - s * rr.uniform(0.5, 1), cx + s, cy + s * rr.uniform(0.5, 1)], fill=color + (alpha,))
    lay = lay.filter(ImageFilter.GaussianBlur(1.6))
    a = np.array(img)[..., 3]
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).rectangle([x, y, x + w - 1, y + h - 1], fill=255)
    from PIL import ImageChops

    m = ImageChops.multiply(m, Image.fromarray(a))
    c = Image.new("RGBA", img.size, (0, 0, 0, 0))
    c.paste(lay, (0, 0), m)
    img.alpha_composite(c)


def edge_shade(img, rect, amount=40):
    """Sombreado de bordes: más oscuro en los lados (volumen de la tela sobre el bloque)."""
    x, y, w, h = rect
    a = np.array(img).astype(np.float32)
    xs = np.linspace(-1, 1, w)
    ys = np.linspace(-1, 1, h)
    g = 1 - (np.abs(xs)[None, :] ** 3 * 0.5 + np.abs(ys)[:, None] ** 4 * 0.3) * (amount / 100)
    a[y:y + h, x:x + w, :3] *= g[..., None]
    img.paste(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA"))


def shirt_template(kind, colors, seed, extra=None):
    """Plantillas de camisa: kind = labcoat (Cosme), blouse, plaid, cardigan, sport, tailcoat (Pip)."""
    img = Image.new("RGBA", (TW, TH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    main = colors["main"]
    weave = {"cardigan": "knit", "sport": "fleece"}.get(kind, "plain")
    tile = tinted_tile(128, 128, seed, main, weave)
    for key, rect in TORSO.items():
        paint_rect(img, rect, tile)
    arm_tile = tile
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            if key == "D":
                continue
            paint_rect(img, rect, arm_tile, alpha_bottom=0 if key == "U" else HAND)
    x, y, w, h = TORSO["F"]
    if kind == "labcoat":
        # camiseta negra en el centro, solapas de la bata y los bolsillos (bolis en el izquierdo)
        under = tinted_tile(128, 128, seed + 1, colors["under"])
        mid = Image.new("RGBA", (54, h), (0, 0, 0, 0))
        mid.alpha_composite(under.crop((0, 0, 54, h)))
        img.alpha_composite(mid, (x + 37, y))
        for s in (-1, 1):
            cx = x + 64 + s * 27
            d.polygon([(cx, y), (cx + s * 22, y), (cx + s * 10, y + 58), (cx, y + 70)], fill=tuple(int(c * 0.9) for c in main) + (255,))
            d.line([(cx, y), (cx, y + h)], fill=(150, 150, 150, 255), width=2)
            d.line([(cx + s * 22, y), (cx + s * 10, y + 58), (cx, y + 70)], fill=(165, 165, 165, 255), width=2)
        # cremallera / costura de la camiseta y el colgante (la luz va en 3D)
        d.line([(x + 64, y + 4), (x + 64, y + h)], fill=(45, 45, 50, 255), width=1)
        # bolsillo del pecho (izquierda del personaje = derecha de la plantilla de frente)
        px0 = x + 96
        d.rectangle([px0, y + 52, px0 + 24, y + 78], outline=(160, 160, 160, 255), width=2)
        # bolsillos de abajo
        for px in (x + 6, x + 98):
            d.rectangle([px, y + 98, px + 24, y + 124], outline=(160, 160, 160, 255), width=2)
            d.line([(px, y + 102), (px + 24, y + 102)], fill=(175, 175, 175, 255), width=2)
        stains(img, TORSO["F"], seed, 9)
        stains(img, TORSO["B"], seed + 2, 12)
        stains(img, TORSO["R"], seed + 3, 4)
        stains(img, TORSO["L"], seed + 4, 4)
        # quemadura pequeña
        bx, by_, bw, bh = TORSO["B"]
        d.ellipse([bx + 80, by_ + 90, bx + 96, by_ + 102], fill=(110, 95, 80, 200))
        # espalda: costura central y cinturilla
        d.line([(bx + 64, by_), (bx + 64, by_ + bh)], fill=(170, 170, 170, 255), width=2)
        d.line([(bx + 20, by_ + 84), (bx + 108, by_ + 84)], fill=(175, 175, 175, 255), width=3)
        # mangas remangadas: banda del puño (el puño en 3D es un accesorio) y manchas
        for arm in (RIGHT, LEFT):
            for key, rect in arm.items():
                if key in ("U", "D"):
                    continue
                rx, ry, rw, rh = rect
                d.rectangle([rx, ry + rh - HAND - 22, rx + rw - 1, ry + rh - HAND - 1], fill=tuple(int(c * 0.93) for c in main) + (255,))
                d.line([(rx, ry + rh - HAND - 22), (rx + rw, ry + rh - HAND - 22)], fill=(160, 160, 160, 255), width=2)
                stains(img, rect, seed + rx, 3, alpha=55)
    elif kind in ("blouse", "plaid", "tailcoat_shirt"):
        if kind == "plaid":
            lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
            dl = ImageDraw.Draw(lay)
            dark = tuple(int(c * 0.62) for c in main) + (110,)
            light = tuple(min(255, int(c * 1.25)) for c in main) + (70,)
            for xx in range(0, TW, 22):
                dl.rectangle([xx, 0, xx + 6, TH], fill=dark)
                dl.line([(xx + 13, 0), (xx + 13, TH)], fill=light, width=1)
            for yy in range(0, TH, 22):
                dl.rectangle([0, yy, TW, yy + 6], fill=dark)
                dl.line([(0, yy + 13), (TW, yy + 13)], fill=light, width=1)
            a = np.array(img)[..., 3]
            c = Image.new("RGBA", img.size, (0, 0, 0, 0))
            c.paste(lay, (0, 0), Image.fromarray(a))
            img.alpha_composite(c)
            d = ImageDraw.Draw(img)
        # tapeta con botones y cuello
        d.line([(x + 64, y), (x + 64, y + h)], fill=tuple(int(c * 0.7) for c in main) + (255,), width=2)
        for k in range(5):
            GEN.button(d, x + 68, y + 14 + k * 24, 3)
        d.polygon([(x + 40, y), (x + 64, y + 22), (x + 88, y)], fill=tuple(min(255, int(c * 1.1)) for c in main) + (255,), outline=tuple(int(c * 0.6) for c in main) + (255,))
        if kind == "plaid":
            d.rectangle([x + 18, y + 30, x + 42, y + 52], outline=tuple(int(c * 0.6) for c in main) + (255,), width=2)
        for arm in (RIGHT, LEFT):
            for key, rect in arm.items():
                if key in ("U", "D"):
                    continue
                rx, ry, rw, rh = rect
                d.rectangle([rx, ry + rh - HAND - 12, rx + rw - 1, ry + rh - HAND - 1], fill=tuple(int(c * 0.88) for c in main) + (255,))
                GEN.seam(d, [(rx, ry + rh - HAND - 12), (rx + rw - 1, ry + rh - HAND - 12)], 120)
        for key in ("F", "B"):
            GEN.shade_folds(img, TORSO[key], seed + len(key), n=3, vertical=True, strength=30)
    elif kind == "cardigan":
        under = tinted_tile(128, 128, seed + 1, colors["under"])
        v = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        dv = ImageDraw.Draw(v)
        dv.polygon([(34, 0), (94, 0), (64, 78)], fill=(255, 255, 255, 255))
        under.putalpha(v.split()[0])
        img.alpha_composite(under, (x, y))
        d.line([(x + 34, y), (x + 64, y + 78), (x + 64, y + h)], fill=tuple(int(c * 0.7) for c in main) + (255,), width=3)
        d.line([(x + 94, y), (x + 64, y + 78)], fill=tuple(int(c * 0.7) for c in main) + (255,), width=3)
        for k in range(3):
            GEN.button(d, x + 64, y + 86 + k * 14, 4)
        for px in (x + 10, x + 92):
            d.rectangle([px, y + 92, px + 26, y + 118], outline=tuple(int(c * 0.75) for c in main) + (255,), width=2)
        # canalé abajo y en los puños
        for key in ("F", "B", "L", "R"):
            rx, ry, rw, rh = TORSO[key]
            for xx in range(rx, rx + rw, 4):
                d.line([(xx, ry + rh - 12), (xx, ry + rh)], fill=tuple(int(c * 0.8) for c in main) + (255,), width=1)
        for arm in (RIGHT, LEFT):
            for key, rect in arm.items():
                if key in ("U", "D"):
                    continue
                rx, ry, rw, rh = rect
                for xx in range(rx, rx + rw, 4):
                    d.line([(xx, ry + rh - HAND - 14), (xx, ry + rh - HAND)], fill=tuple(int(c * 0.8) for c in main) + (255,), width=1)
    elif kind == "sport":
        st = colors.get("stripe", (240, 240, 240))
        for arm in (RIGHT, LEFT):
            for key, rect in arm.items():
                if key in ("U", "D"):
                    continue
                rx, ry, rw, rh = rect
                d.rectangle([rx + rw // 2 - 5, ry, rx + rw // 2 + 5, ry + rh - HAND - 1], fill=st + (255,))
                d.rectangle([rx, ry + rh - HAND - 10, rx + rw - 1, ry + rh - HAND - 1], fill=st + (255,))
        d.arc([x + 34, y - 26, x + w - 34, y + 22], 0, 180, fill=st + (255,), width=7)
        d.rectangle([x + 46, y + 40, x + 82, y + 70], outline=st + (255,), width=3)  # número
        d.text((x + 56, y + 44), "7", fill=st + (255,))
        for key in ("F", "B"):
            GEN.shade_folds(img, TORSO[key], seed + 5, n=3, vertical=True, strength=26)
    elif kind == "tailcoat":
        shirt = tinted_tile(128, 128, seed + 1, colors["under"])
        v = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        dv = ImageDraw.Draw(v)
        dv.polygon([(30, 0), (98, 0), (80, 100), (48, 100)], fill=(255, 255, 255, 255))
        shirt.putalpha(v.split()[0])
        img.alpha_composite(shirt, (x, y))
        for k in range(3):
            GEN.button(d, x + 64, y + 30 + k * 22, 3)
        for s in (-1, 1):
            d.line([(x + 64 + s * 34, y), (x + 64 + s * 16, y + 100)], fill=tuple(int(c * 0.55) for c in main) + (255,), width=4)
        # guantes blancos: la mano no se ve (en la plantilla: lo de abajo del brazo, blanco)
        for arm in (RIGHT, LEFT):
            for key, rect in arm.items():
                if key in ("U", "D"):
                    continue
                rx, ry, rw, rh = rect
                d.rectangle([rx, ry + rh - HAND - 10, rx + rw - 1, ry + rh - HAND - 1], fill=colors["under"] + (255,))
    for key, rect in TORSO.items():
        edge_shade(img, rect, 35)
    return img


def pants_template(kind, colors, seed):
    """Pantalones: cargo (Cosme, con correas en las rodillas), jeans, trousers, track (chándal), suit."""
    img = Image.new("RGBA", (TW, TH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    main = colors["main"]
    weave = {"jeans": "denim", "track": "fleece"}.get(kind, "plain")
    tile = tinted_tile(128, 128, seed, main, weave)
    for key, rect in TORSO.items():
        paint_rect(img, rect, tile)
    for leg in (RIGHT, LEFT):
        for key, rect in leg.items():
            paint_rect(img, rect, tile)
    for leg in (RIGHT, LEFT):
        for key, rect in leg.items():
            if key in ("U", "D"):
                continue
            rx, ry, rw, rh = rect
            GEN.seam(d, [(rx + 3, ry), (rx + 3, ry + rh)], int(main[0] * 0.6) + 30)
            GEN.shade_folds(img, rect, seed + rx, n=2, vertical=False, strength=34)
            d = ImageDraw.Draw(img)
            if kind == "cargo":
                if key in ("L", "R"):
                    d.rectangle([rx + 10, ry + 24, rx + rw - 10, ry + 52], outline=tuple(int(c * 0.55) for c in main) + (255,), width=2)
                    d.rectangle([rx + 10, ry + 24, rx + rw - 10, ry + 31], fill=tuple(int(c * 0.8) for c in main) + (255,))
                # correa de la rodilla (gris)
                d.rectangle([rx, ry + 62, rx + rw - 1, ry + 72], fill=(118, 118, 122, 255))
                d.rectangle([rx + rw // 2 - 4, ry + 62, rx + rw // 2 + 4, ry + 72], fill=(170, 170, 172, 255))
                stains(img, rect, seed + ry + rx, 3, color=(60, 50, 40), alpha=60)
            elif kind == "jeans":
                GEN.seam(d, [(rx + rw - 4, ry), (rx + rw - 4, ry + rh)], 190)
                d.rectangle([rx, ry + rh - 8, rx + rw - 1, ry + rh - 1], fill=tuple(int(c * 0.85) for c in main) + (255,))
            elif kind == "track":
                st = colors.get("stripe", (240, 240, 240))
                if key in ("L", "R"):
                    d.rectangle([rx + rw // 2 - 4, ry, rx + rw // 2 + 4, ry + rh], fill=st + (255,))
            else:
                d.line([(rx + rw // 2, ry), (rx + rw // 2, ry + rh)], fill=tuple(int(c * 0.75) for c in main) + (255,), width=1)  # raya
    x, y, w, h = TORSO["F"]
    if kind == "jeans":
        for s in (-1, 1):
            d.arc([x + 64 + s * 40 - 20, y + 84, x + 64 + s * 40 + 20, y + 120], 180 if s < 0 else 270, 270 if s < 0 else 360, fill=(200, 180, 120, 255), width=2)
    d.line([(x + 64, y + 96), (x + 64, y + h)], fill=tuple(int(c * 0.6) for c in main) + (255,), width=2)
    return img


def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    return path
