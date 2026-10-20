#!/usr/bin/env python3
"""Texturas de Cosme, el vecino inventor (shared/CosmeLook): sus 4 caras y su ropa clásica.

Dibuja en assets/cosme/:
  cosme_face_grin.png     sonrisa loca (un ojo muy abierto, el otro entornado, una ceja arriba)
  cosme_face_skeptic.png  escéptico (párpados caídos, mirada de lado, una ceja levantada)
  cosme_face_laugh.png    riéndose (ojos cerrados de risa, boca abierta)
  cosme_face_scared.png   asustado (ojos enormes, pupilas pequeñas, cejas arriba)
  cosme_shirt.png         plantilla Shirt 585x559: bata blanca algo sucia (manchas, una quemadura)
  cosme_pants.png         plantilla Pants 585x559: pantalón cargo marrón con costuras y bolsillos

Las caras son de dibujo animado, fondo transparente (Decal «face» de la cabeza clásica), con las reglas
del dueño: cejas pobladas SEPARADAS (nada de una sola ceja), dientes normales (fila limpia, un poco
torcida, sin huecos) y nada de babas ni moco verde.

Solo hace falta Pillow. Uso (desde roblox/):
    python3 scripts/cosme/gen.py
Después: bash scripts/upload-cosme.sh (las sube y escribe src/shared/CosmeTextureIds.luau).
"""

import math
import os
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "assets", "cosme")

S = 2048  # se dibuja grande y se reduce (bordes suaves)
FINAL = 512

INK = (40, 28, 26, 255)
SKIN = (240, 204, 168, 255)  # Cast.People.Cosme.Skin (el párpado tapa el ojo con el color de la piel)
WHITE = (252, 251, 246, 255)
BROW = (222, 230, 239, 255)  # pelo plateado con un toque frío
BROW_INK = (120, 132, 148, 255)
MOUTH = (98, 26, 34, 255)
TEETH = (250, 248, 238, 255)
TEETH_LINE = (196, 190, 178, 255)
TONGUE = (228, 104, 110, 255)
WRINKLE = (176, 118, 92, 200)


def P(x, y):
    return (x * S, y * S)


def lw(k):
    return max(1, int(k * S))


def ellipse(d, cx, cy, rx, ry, fill=None, outline=None, width=0):
    d.ellipse([(cx - rx) * S, (cy - ry) * S, (cx + rx) * S, (cy + ry) * S], fill=fill, outline=outline, width=lw(width) if width else 0)


def arc_points(cx, cy, rx, ry, a0, a1, n=48):
    pts = []
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        pts.append(P(cx + rx * math.cos(a), cy + ry * math.sin(a)))
    return pts


def thick_line(d, pts, width, fill):
    d.line(pts, fill=fill, width=lw(width), joint="curve")
    r = width / 2
    for x, y in (pts[0], pts[-1]):
        d.ellipse([x - r * S, y - r * S, x + r * S, y + r * S], fill=fill)


def bezier(p0, p1, p2, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    return pts


# ---------------------------------------------------------------------------
# Rasgos
# ---------------------------------------------------------------------------


def eye(img, cx, cy, r, pupil=(0, 0), pupil_r=0.036, lid=0.0, lid_tilt=0.0):
    """Ojo grande redondo con borde; lid = parte de arriba tapada por el párpado (0..1)."""
    d = ImageDraw.Draw(img)
    ry = r * 1.04
    ellipse(d, cx, cy, r, ry, fill=WHITE)
    px, py = cx + pupil[0] * r, cy + pupil[1] * r
    ellipse(d, px, py, pupil_r, pupil_r, fill=INK)
    ellipse(d, px - pupil_r * 0.35, py - pupil_r * 0.4, pupil_r * 0.32, pupil_r * 0.32, fill=(255, 255, 255, 255))
    d.ellipse([(cx - r) * S, (cy - ry) * S, (cx + r) * S, (cy + ry) * S], outline=INK, width=lw(0.012))
    if lid > 0:
        # párpado: la parte de arriba del ojo (con su borde) se pinta de piel y se marca la línea
        grow = 0.009
        mask = Image.new("L", img.size, 0)
        ellipse(ImageDraw.Draw(mask), cx, cy, r + grow, ry + grow, fill=255)
        cover = Image.new("L", img.size, 0)
        top = cy - ry - grow
        y = cy - ry + 2 * ry * lid
        dy = lid_tilt * r
        ImageDraw.Draw(cover).polygon([P(cx - r - 0.03, top - 0.02), P(cx + r + 0.03, top - 0.02), P(cx + r + 0.03, y + dy), P(cx - r - 0.03, y - dy)], fill=255)
        img.paste(Image.new("RGBA", img.size, SKIN), (0, 0), ImageChops.multiply(mask, cover))
        d = ImageDraw.Draw(img)
        hw = math.sqrt(max(0.0, r * r - (y - cy) ** 2)) + 0.014
        thick_line(d, [P(cx - hw, y - dy * hw / r), P(cx + hw, y + dy * hw / r)], 0.018, INK)
        # pliegue del párpado por encima
        thick_line(d, bezier(P(cx - hw * 0.8, y - 0.03 - dy * 0.8), P(cx, y - 0.05), P(cx + hw * 0.8, y - 0.03 + dy * 0.8)), 0.007, WRINKLE)
    return img


def closed_eye(d, cx, cy, r):
    """Ojo cerrado de risa: un arco hacia arriba (^)."""
    pts = arc_points(cx, cy + r * 0.35, r * 0.95, r * 0.75, 200, 340)
    thick_line(d, pts, 0.02, INK)
    # pestañitas de risa
    for a in (205, 335):
        x = cx + r * 0.95 * math.cos(math.radians(a))
        y = cy + r * 0.35 + r * 0.75 * math.sin(math.radians(a))
        sx = -1 if a < 270 else 1
        thick_line(d, [P(x, y), P(x + sx * 0.03, y + 0.012)], 0.012, INK)


def brow(img, cx, cy, length, angle, thick=0.07, arch=0.02, seed=0):
    """Ceja poblada y despeinada (mechones redondeados), girada `angle` grados. Cada ceja va por separado
    (nunca una sola ceja de lado a lado)."""
    rnd = random.Random(seed)
    a = math.radians(angle)
    ca, sa = math.cos(a), math.sin(a)

    def rot(x, y):
        return (cx + x * ca - y * sa, cy + x * sa + y * ca)

    mask = Image.new("L", img.size, 0)
    md = ImageDraw.Draw(mask)
    n = 11
    for i in range(n):
        t = i / (n - 1)
        x = -length / 2 + length * t
        y = -arch * math.sin(math.pi * t)
        # más gruesa por dentro, afinando hacia fuera; mechones que se salen por arriba
        rr = thick * (0.42 + 0.22 * math.sin(math.pi * (0.25 + 0.6 * (1 - t))))
        ox, oy = rot(x, y)
        ellipse(md, ox, oy, rr * 1.1, rr * 0.8, fill=255)
        if i % 2 == 0:
            tx, ty = rot(x + length * 0.03, y - rr * (0.7 + 0.5 * rnd.random()))
            ellipse(md, tx, ty, rr * 0.45, rr * 0.55, fill=255)
    outline = mask.filter(ImageFilter.MaxFilter(lw(0.008) * 2 + 1))
    img.paste(Image.new("RGBA", img.size, BROW_INK), (0, 0), outline)
    img.paste(Image.new("RGBA", img.size, BROW), (0, 0), mask)
    d = ImageDraw.Draw(img)
    # pelitos (textura) hacia fuera
    for i in range(9):
        t = (i + 0.5) / 9
        x = -length / 2 + length * t
        y = -arch * math.sin(math.pi * t)
        p0 = rot(x, y + thick * 0.15)
        p1 = rot(x + length * 0.05, y - thick * 0.2)
        thick_line(d, [P(*p0), P(*p1)], 0.005, (176, 188, 204, 255))


def nose(d):
    pts = bezier(P(0.505, 0.585), P(0.46, 0.64), P(0.515, 0.655))
    thick_line(d, pts, 0.011, INK)


def wrinkles(d, cx, cy, r, side):
    # ojeras y patas de gallo de científico que no duerme
    pts = arc_points(cx, cy + r * 0.95, r * 0.7, r * 0.22, 20, 160, 24)
    thick_line(d, pts, 0.007, WRINKLE)
    ox = cx + side * (r + 0.03)
    for k in (-1, 0, 1):
        thick_line(d, [P(ox, cy + k * 0.022), P(ox + side * 0.03, cy + k * 0.03)], 0.006, WRINKLE)


def teeth_band(layer, curve, height, n, seed, down=True):
    """Fila de dientes normales pegada a la línea del labio (curve, en 0..1): una tira limpia, sin
    huecos, con las separaciones un pelín torcidas y algún diente un poco más largo."""
    rnd = random.Random(seed)
    d = ImageDraw.Draw(layer)
    sign = 1 if down else -1
    xs = [x for x, _ in curve]
    x0, x1 = min(xs), max(xs)

    def edge_y(x):
        best = min(curve, key=lambda p: abs(p[0] - x))
        return best[1]

    lengths = [height * (0.9 + 0.2 * rnd.random()) for _ in range(n)]

    def length_at(x):
        k = min(n - 1, max(0, int((x - x0) / (x1 - x0) * n)))
        return lengths[k]

    band = [P(x, y - sign * 0.02) for x, y in curve]
    lower = [P(x, y + sign * length_at(x)) for x, y in reversed(curve)]
    d.polygon(band + lower, fill=TEETH)
    for k in range(1, n):
        x = x0 + (x1 - x0) * k / n
        y = edge_y(x)
        tilt = rnd.uniform(-0.012, 0.012) + (0.01 if k == 3 else 0)
        thick_line(d, [P(x, y - sign * 0.01), P(x + tilt, y + sign * length_at(x) * 0.95)], 0.006, TEETH_LINE)
    # borde de los dientes (suave)
    thick_line(d, [P(x, y + sign * length_at(x)) for x, y in curve], 0.005, TEETH_LINE)


def mouth(img, top, bottom, teeth_top=None, teeth_bottom=None, tongue=None, seed=1):
    """Boca entre dos curvas (labio de arriba y de abajo, puntos en 0..1). teeth_top = (alto, n),
    teeth_bottom = (alto, n), tongue = (cx, cy, rx, ry)."""
    outline_pts = top + list(reversed(bottom))
    poly = [P(x, y) for x, y in outline_pts]
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.polygon(poly, fill=MOUTH)
    if tongue:
        cx, cy, rx, ry = tongue
        ellipse(ld, cx, cy, rx, ry, fill=TONGUE)
        thick_line(ld, [P(cx, cy - ry * 0.4), P(cx, cy + ry * 0.2)], 0.006, (196, 80, 88, 255))
    if teeth_top:
        h, n = teeth_top
        teeth_band(layer, top, h, n, seed)
    if teeth_bottom:
        h, n = teeth_bottom
        k = len(bottom)
        teeth_band(layer, bottom[k // 5 : k - k // 5], h, n, seed + 7, down=False)
    clipped = Image.new("RGBA", img.size, (0, 0, 0, 0))
    clipped.paste(layer, (0, 0), mask)
    img.alpha_composite(clipped)
    d = ImageDraw.Draw(img)
    d.line(poly + [poly[0]], fill=INK, width=lw(0.013), joint="curve")


def qb(p0, p1, p2, n=40):
    return bezier(p0, p1, p2, n)


# ---------------------------------------------------------------------------
# Las 4 caras
# ---------------------------------------------------------------------------

EYE_L = (0.335, 0.5)  # (izquierda de la imagen = ojo derecho de Cosme)
EYE_R = (0.665, 0.5)
R = 0.122


def face_grin():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wrinkles(d, EYE_L[0], EYE_L[1], R, -1)
    wrinkles(d, EYE_R[0], EYE_R[1], R, 1)
    eye(img, EYE_L[0], EYE_L[1], R * 1.06, pupil=(0.18, -0.05), pupil_r=0.036)
    eye(img, EYE_R[0], EYE_R[1], R, pupil=(-0.12, 0.25), pupil_r=0.034, lid=0.46, lid_tilt=-0.12)
    brow(img, 0.33, 0.315, 0.22, -9, arch=0.03, seed=3)
    brow(img, 0.67, 0.355, 0.22, 13, arch=0.012, seed=4)
    d = ImageDraw.Draw(img)
    nose(d)
    # sonrisa ancha y un poco torcida (más alta a la derecha de la imagen)
    top = qb((0.28, 0.715), (0.5, 0.75), (0.745, 0.68))
    bottom = qb((0.28, 0.715), (0.49, 1.0), (0.745, 0.68))
    mouth(img, top, bottom, teeth_top=(0.058, 8), teeth_bottom=(0.03, 5), tongue=(0.5, 0.875, 0.1, 0.04), seed=11)
    d = ImageDraw.Draw(img)
    # comisuras
    thick_line(d, [P(0.27, 0.70), P(0.285, 0.725)], 0.01, INK)
    thick_line(d, [P(0.755, 0.665), P(0.745, 0.695)], 0.01, INK)
    return img


def face_skeptic():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wrinkles(d, EYE_L[0], EYE_L[1], R, -1)
    wrinkles(d, EYE_R[0], EYE_R[1], R, 1)
    eye(img, EYE_L[0], EYE_L[1], R, pupil=(0.45, 0.28), pupil_r=0.034, lid=0.5, lid_tilt=0.08)
    eye(img, EYE_R[0], EYE_R[1], R, pupil=(0.45, 0.32), pupil_r=0.034, lid=0.56, lid_tilt=-0.05)
    brow(img, 0.33, 0.29, 0.22, -14, arch=0.035, seed=5)
    brow(img, 0.67, 0.37, 0.22, 4, arch=0.006, seed=6)
    d = ImageDraw.Draw(img)
    nose(d)
    # boca plana, ladeada, con la comisura metida (media sonrisa de «ya, claro»)
    pts = bezier(P(0.38, 0.775), P(0.52, 0.79), P(0.66, 0.755))
    thick_line(d, pts, 0.016, INK)
    thick_line(d, [P(0.66, 0.755), P(0.685, 0.735)], 0.012, INK)
    thick_line(d, bezier(P(0.47, 0.83), P(0.52, 0.845), P(0.57, 0.83)), 0.007, WRINKLE)
    return img


def face_laugh():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    closed_eye(d, EYE_L[0], EYE_L[1], R)
    closed_eye(d, EYE_R[0], EYE_R[1], R)
    # arruguitas de reírse
    for side, (cx, cy) in ((-1, EYE_L), (1, EYE_R)):
        ox = cx + side * (R + 0.02)
        for k in (-1, 0, 1):
            thick_line(d, [P(ox, cy + 0.03 + k * 0.025), P(ox + side * 0.035, cy + 0.03 + k * 0.035)], 0.007, WRINKLE)
    brow(img, 0.33, 0.3, 0.22, -6, arch=0.035, seed=7)
    brow(img, 0.67, 0.3, 0.22, 6, arch=0.035, seed=8)
    d = ImageDraw.Draw(img)
    nose(d)
    # boca muy abierta: arriba casi recta, abajo redonda
    top = qb((0.27, 0.69), (0.5, 0.71), (0.73, 0.69))
    bottom = qb((0.27, 0.69), (0.5, 1.02), (0.73, 0.69))
    mouth(img, top, bottom, teeth_top=(0.06, 8), tongue=(0.5, 0.9, 0.13, 0.065), seed=13)
    return img


def face_scared():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wrinkles(d, EYE_L[0], EYE_L[1] + 0.01, R * 1.18, -1)
    wrinkles(d, EYE_R[0], EYE_R[1] + 0.01, R * 1.18, 1)
    eye(img, EYE_L[0], EYE_L[1] + 0.01, R * 1.18, pupil=(0.05, 0.0), pupil_r=0.02)
    eye(img, EYE_R[0], EYE_R[1] + 0.01, R * 1.18, pupil=(-0.05, 0.0), pupil_r=0.02)
    # cejas muy arriba con la punta de dentro levantada (preocupado), cada una por su lado
    brow(img, 0.325, 0.27, 0.21, 14, arch=0.02, seed=9)
    brow(img, 0.675, 0.27, 0.21, -14, arch=0.02, seed=10)
    d = ImageDraw.Draw(img)
    nose(d)
    # boca pequeña abierta, temblorosa
    top = [(0.5 + 0.085 * math.cos(a), 0.81 + (0.07 + 0.006 * math.sin(a * 6)) * math.sin(a)) for a in [math.pi + math.pi * i / 30 for i in range(31)]]
    bottom = [(0.5 + 0.085 * math.cos(a), 0.81 + 0.07 * math.sin(a)) for a in [math.pi - math.pi * i / 30 for i in range(31)]]
    mouth(img, top, bottom, teeth_top=(0.025, 5), seed=17)
    # gota de sudor (azul clarito) en la sien
    d = ImageDraw.Draw(img)
    drop = [P(0.86, 0.3), P(0.835, 0.37), P(0.86, 0.39), P(0.885, 0.37)]
    d.polygon(drop, fill=(196, 228, 250, 255))
    ellipse(d, 0.86, 0.372, 0.025, 0.022, fill=(196, 228, 250, 255))
    d.line(drop[:2] + [P(0.84, 0.385), P(0.88, 0.385)] + drop[3:] + [drop[0]], fill=(90, 140, 190, 255), width=lw(0.005))
    return img


def face_talk():
    """Hablando: el fotograma de boca abierta que se alterna con la cara de su emoción mientras dice una
    frase (CosmeLook.flap). Ojos de su sonrisa loca, UNA boca abierta a media altura (nada más)."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wrinkles(d, EYE_L[0], EYE_L[1], R, -1)
    wrinkles(d, EYE_R[0], EYE_R[1], R, 1)
    eye(img, EYE_L[0], EYE_L[1], R * 1.04, pupil=(0.16, -0.02), pupil_r=0.036)
    eye(img, EYE_R[0], EYE_R[1], R, pupil=(-0.1, 0.2), pupil_r=0.034, lid=0.4, lid_tilt=-0.1)
    brow(img, 0.33, 0.31, 0.22, -9, arch=0.03, seed=3)
    brow(img, 0.67, 0.34, 0.22, 10, arch=0.014, seed=4)
    d = ImageDraw.Draw(img)
    nose(d)
    # boca abierta (una «o» ancha, un poco torcida como su sonrisa)
    top = qb((0.36, 0.735), (0.51, 0.7), (0.665, 0.715))
    bottom = qb((0.36, 0.735), (0.5, 0.93), (0.665, 0.715))
    mouth(img, top, bottom, teeth_top=(0.04, 6), tongue=(0.51, 0.87, 0.09, 0.04), seed=19)
    return img


FACES = {
    "cosme_face_grin": face_grin,
    "cosme_face_skeptic": face_skeptic,
    "cosme_face_laugh": face_laugh,
    "cosme_face_scared": face_scared,
    "cosme_face_talk": face_talk,
}

# ---------------------------------------------------------------------------
# Ropa clásica (plantillas de Roblox 585x559)
# ---------------------------------------------------------------------------

W, H = 585, 559
TORSO = {"U": (231, 8, 128, 64), "F": (231, 74, 128, 128), "R": (165, 74, 64, 128), "L": (361, 74, 64, 128), "B": (427, 74, 128, 128), "D": (231, 204, 128, 64)}
RIGHT = {"L": (19, 355, 64, 128), "B": (85, 355, 64, 128), "R": (151, 355, 64, 128), "F": (217, 355, 64, 128), "U": (217, 289, 64, 64), "D": (217, 485, 64, 64)}
LEFT = {"F": (308, 355, 64, 128), "L": (374, 355, 64, 128), "B": (440, 355, 64, 128), "R": (506, 355, 64, 128), "U": (308, 289, 64, 64), "D": (308, 485, 64, 64)}


def fabric(size, base, rnd, grain=10):
    w, h = size
    img = Image.new("RGBA", size, base + (255,))
    px = img.load()
    for y in range(h):
        for x in range(w):
            n = rnd.uniform(-grain, grain) + (4 if (x + y) % 3 == 0 else 0)
            r, g, b, a = px[x, y]
            px[x, y] = (max(0, min(255, int(r + n))), max(0, min(255, int(g + n))), max(0, min(255, int(b + n))), a)
    return img


def blot(img, x, y, r, color, rnd, alpha=110):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(6):
        ox, oy = rnd.uniform(-r, r) * 0.6, rnd.uniform(-r, r) * 0.6
        rr = r * rnd.uniform(0.4, 0.9)
        d.ellipse([x + ox - rr, y + oy - rr, x + ox + rr, y + oy + rr], fill=color + (alpha,))
    layer = layer.filter(ImageFilter.GaussianBlur(r * 0.35))
    img.alpha_composite(layer)


def rect_fill(img, rect, tile):
    x, y, w, h = rect
    img.alpha_composite(tile.crop((0, 0, w, h)), (x, y))


def shirt():
    rnd = random.Random(42)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    coat = fabric((128, 128), (236, 236, 230), rnd, 6)
    black = fabric((128, 128), (28, 29, 33), rnd, 4)
    for key, rect in TORSO.items():
        rect_fill(img, rect, coat)
    d = ImageDraw.Draw(img)
    # delante: camiseta negra en medio (la bata va abierta), cantos y solapas
    x, y, w, h = TORSO["F"]
    img.alpha_composite(black.crop((0, 0, 52, h)), (x + 38, y))
    d = ImageDraw.Draw(img)
    for sx in (x + 38, x + 90):
        d.line([(sx, y), (sx, y + h)], fill=(196, 196, 188, 255), width=2)
    d.polygon([(x + 38, y), (x + 54, y), (x + 38, y + 50)], fill=(226, 226, 220, 255))
    d.polygon([(x + 90, y), (x + 74, y), (x + 90, y + 50)], fill=(226, 226, 220, 255))
    # botones de la bata
    for by in (y + 70, y + 98):
        d.ellipse([x + 29, by - 3, x + 35, by + 3], fill=(205, 205, 198, 255), outline=(150, 150, 145, 255))
    # detrás: costura en medio y abertura abajo
    bx, by, bw, bh = TORSO["B"]
    d.line([(bx + bw // 2, by + 10), (bx + bw // 2, by + bh)], fill=(200, 200, 192, 255), width=2)
    d.line([(bx + 20, by + 20), (bx + bw - 20, by + 20)], fill=(210, 210, 202, 255), width=2)
    # mangas
    # mangas (lo de abajo de cada cara del brazo va a la mano en R15: transparente, se ve la piel)
    HAND = 18
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            rx, ry, rw, rh = rect
            if key == "D":
                continue
            if key == "U":
                rect_fill(img, rect, coat)
                continue
            rect_fill(img, (rx, ry, rw, rh - HAND), coat)
            d.rectangle([rx, ry + rh - HAND - 14, rx + rw - 1, ry + rh - HAND - 1], fill=(226, 226, 219, 255))  # puño
            d.line([(rx, ry + rh - HAND - 14), (rx + rw, ry + rh - HAND - 14)], fill=(190, 190, 182, 255), width=2)
            d.line([(rx, ry + 16), (rx + rw, ry + 16)], fill=(205, 205, 198, 255), width=2)
    # algo sucia: manchas, salpicaduras de aceite y una quemadura
    spots = [(TORSO["F"], 0.82, 0.78, 9), (TORSO["F"], 0.12, 0.3, 6), (TORSO["B"], 0.3, 0.7, 10), (TORSO["B"], 0.75, 0.35, 7),
             (RIGHT["F"], 0.5, 0.55, 8), (LEFT["R"], 0.4, 0.4, 7), (LEFT["F"], 0.6, 0.8, 6), (TORSO["L"], 0.5, 0.6, 7)]
    for rect, fx, fy, r in spots:
        rx, ry, rw, rh = rect
        blot(img, rx + rw * fx, ry + rh * fy, r, (176, 160, 128), rnd, 90)
    rx, ry, rw, rh = TORSO["F"]
    blot(img, rx + rw * 0.85, ry + rh * 0.25, 7, (90, 80, 72), rnd, 150)
    blot(img, rx + rw * 0.85, ry + rh * 0.25, 3, (40, 34, 30), rnd, 200)
    return img


def pants():
    rnd = random.Random(7)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cloth = fabric((128, 128), (74, 55, 42), rnd, 7)
    for key, rect in TORSO.items():
        rect_fill(img, rect, cloth)
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            rect_fill(img, rect, cloth)
    d = ImageDraw.Draw(img)
    dark = (52, 38, 30, 255)
    seam = (98, 76, 58, 255)
    # cintura con trabillas
    for key in ("F", "B", "L", "R"):
        x, y, w, h = TORSO[key]
        d.rectangle([x, y + h - 26, x + w, y + h - 16], fill=dark)
        for k in range(1, 4):
            lx = x + w * k // 4
            d.rectangle([lx - 2, y + h - 28, lx + 2, y + h - 12], fill=seam)
    x, y, w, h = TORSO["F"]
    d.line([(x + w // 2, y + h - 16), (x + w // 2, y + h)], fill=dark, width=2)  # bragueta
    # piernas: costuras, rodillas y bolsillos cargo a los lados
    for arm, outer in ((RIGHT, "R"), (LEFT, "L")):
        for key in ("F", "B", "L", "R"):
            rx, ry, rw, rh = arm[key]
            d.line([(rx + 3, ry), (rx + 3, ry + rh)], fill=seam, width=1)
            d.line([(rx + rw - 4, ry), (rx + rw - 4, ry + rh)], fill=seam, width=1)
            if key == "F":
                d.arc([rx + 12, ry + 70, rx + rw - 12, ry + 90], 0, 180, fill=dark, width=2)
                d.line([(rx + 14, ry + 108), (rx + rw - 14, ry + 108)], fill=dark, width=3)
        rx, ry, rw, rh = arm[outer]
        d.rectangle([rx + 10, ry + 30, rx + rw - 10, ry + 64], fill=(64, 47, 36, 255), outline=dark, width=2)
        d.rectangle([rx + 8, ry + 26, rx + rw - 8, ry + 38], fill=(80, 60, 46, 255), outline=dark, width=2)
        d.ellipse([rx + rw // 2 - 3, ry + 29, rx + rw // 2 + 3, ry + 35], fill=(150, 150, 150, 255))
    # polvo de taller en las rodillas
    for arm in (RIGHT, LEFT):
        rx, ry, rw, rh = arm["F"]
        blot(img, rx + rw * 0.5, ry + rh * 0.62, 9, (120, 100, 80), rnd, 70)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in FACES.items():
        img = fn().reduce(S // FINAL)  # (caja: sin halos en los bordes, como haría LANCZOS)
        img.save(os.path.join(OUT, name + ".png"))
        print("  ✅", name)
    shirt().save(os.path.join(OUT, "cosme_shirt.png"))
    print("  ✅ cosme_shirt")
    pants().save(os.path.join(OUT, "cosme_pants.png"))
    print("  ✅ cosme_pants")


if __name__ == "__main__":
    main()
