"""Ropa de los oficios y de la gente de la calle en el estilo bloque (plantillas clásicas Shirt/Pants de
585x559, como scripts/personajes/bloque_ropa.py). Referencia del dueño: docs/personajes/referencia/
npcs-dueno.png (solo inspiración). Sin marcas reales: los textos son genéricos y en español («POLICÍA»,
«BOMBEROS», «REPARTO»).

    shirt(kind, colors, seed) -> Image     kinds: ver SHIRTS
    pants(kind, colors, seed) -> Image     kinds: ver PANTS (los de bloque_ropa también valen)
"""
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import bloque_ropa as RO
import gen as GEN

TORSO, RIGHT, LEFT, HAND = RO.TORSO, RO.RIGHT, RO.LEFT, RO.HAND
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def dk(c, k=0.7):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


def font(size):
    try:
        return ImageFont.truetype(FONT_BOLD, size)
    except OSError:
        return ImageFont.load_default()


def text_c(d, cx, cy, txt, size, fill):
    f = font(size)
    b = d.textbbox((0, 0), txt, font=f)
    d.text((cx - (b[2] - b[0]) / 2 - b[0], cy - (b[3] - b[1]) / 2 - b[1]), txt, font=f, fill=fill)


def base(colors, seed, sleeves="long", weave="plain", arm_color=None):
    """Tronco y brazos del color principal. sleeves: long | short | none (de manga corta, lo de debajo
    queda transparente: se ve la piel del R15)."""
    img = Image.new("RGBA", (RO.TW, RO.TH), (0, 0, 0, 0))
    tile = RO.tinted_tile(128, 128, seed, colors["main"], weave)
    for rect in TORSO.values():
        RO.paint_rect(img, rect, tile)
    atile = RO.tinted_tile(128, 128, seed + 3, arm_color or colors["main"], weave)
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            if key == "D":
                continue
            if sleeves == "none":
                continue
            if sleeves == "short" and key != "U":
                x, y, w, h = rect
                sub = (x, y, w, int(h * 0.36))
                RO.paint_rect(img, sub, atile)
                continue
            RO.paint_rect(img, rect, atile, alpha_bottom=0 if key == "U" else HAND)
    return img, ImageDraw.Draw(img)


def cuffs(d, color, short=False, h=10):
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            if key in ("U", "D"):
                continue
            x, y, w, hh = rect
            yy = y + int(hh * 0.36) - h if short else y + hh - HAND - h
            d.rectangle([x, yy, x + w - 1, yy + h - 1], fill=color)


def collar_v(img, x, y, under, depth=60, half=26, seed=0):
    u = RO.tinted_tile(128, 128, seed + 11, under)
    m = Image.new("L", (128, 128), 0)
    ImageDraw.Draw(m).polygon([(64 - half, 0), (64 + half, 0), (64, depth)], fill=255)
    u.putalpha(m)
    img.alpha_composite(u, (x, y))


def reflective(d, rect, ys, h=8, color=(250, 210, 40, 255), silver=(205, 210, 215, 255)):
    x, y, w, hh = rect
    for t in ys:
        yy = y + int(hh * t)
        d.rectangle([x, yy, x + w - 1, yy + h], fill=color)
        d.rectangle([x, yy + h // 2 - 2, x + w - 1, yy + h // 2 + 1], fill=silver)


def badge(d, cx, cy, r, color=(222, 186, 70, 255)):
    pts = []
    import math

    for i in range(10):
        a = math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.55
        pts.append((cx + rr * math.cos(a), cy - rr * math.sin(a)))
    d.polygon(pts, fill=color, outline=(120, 90, 30, 255))


def pocket(d, x, y, w, h, color, flap=True):
    d.rectangle([x, y, x + w, y + h], outline=color, width=2)
    if flap:
        d.rectangle([x, y, x + w, y + 7], fill=color)


def name_tag(d, x, y, color=(245, 245, 245, 255)):
    d.rectangle([x, y, x + 20, y + 8], fill=color, outline=(90, 90, 90, 255))
    d.line([(x + 3, y + 4), (x + 16, y + 4)], fill=(80, 80, 80, 255), width=1)


def finish(img, folds=True, seed=0):
    if folds:
        for key in ("F", "B"):
            GEN.shade_folds(img, TORSO[key], seed + len(key), n=3, vertical=True, strength=24)
    for rect in TORSO.values():
        RO.edge_shade(img, rect, 32)
    return img


# ---------------------------------------------------------------- camisas de oficio
def s_policia(c, seed):
    img, d = base(c, seed, "short")
    x, y, w, h = TORSO["F"]
    d.line([(x + 64, y), (x + 64, y + h)], fill=dk(c["main"], 0.6), width=2)
    for k in range(4):
        GEN.button(d, x + 68, y + 16 + k * 22, 3)
    pocket(d, x + 14, y + 30, 28, 26, dk(c["main"], 0.6))
    pocket(d, x + 86, y + 30, 28, 26, dk(c["main"], 0.6))
    badge(d, x + 100, y + 22, 9)
    text_c(d, x + 28, y + 24, "POLICÍA", 8, (240, 240, 240, 255))
    d.rectangle([x, y + h - 16, x + w - 1, y + h - 4], fill=(24, 24, 28, 255))  # cinturón
    d.rectangle([x + 58, y + h - 16, x + 70, y + h - 4], fill=(190, 190, 195, 255))
    bx, by, bw, bh = TORSO["B"]
    text_c(d, bx + 64, by + 40, "POLICÍA", 20, (240, 240, 240, 255))
    text_c(d, bx + 64, by + 62, "VALMAR", 11, (220, 220, 225, 255))
    d.rectangle([bx, by + bh - 16, bx + bw - 1, by + bh - 4], fill=(24, 24, 28, 255))
    for arm in (RIGHT, LEFT):  # escudo en el hombro
        x2, y2, w2, h2 = arm["F"] if "F" in arm else arm["R"]
    for arm in (RIGHT, LEFT):
        for key in ("L", "R"):
            if key in arm:
                ax, ay, aw, ah = arm[key]
                d.rectangle([ax + 18, ay + 10, ax + 46, ay + 34], fill=(200, 170, 60, 255), outline=(30, 30, 40, 255))
    cuffs(d, dk(c["main"], 0.75), short=True, h=6)
    return finish(img, seed=seed)


def s_mono(c, seed):
    """Mono de mecánico (con las mangas largas y manchas de grasa)."""
    img, d = base(c, seed, "long", "twill")
    x, y, w, h = TORSO["F"]
    d.line([(x + 64, y + 4), (x + 64, y + h)], fill=(180, 180, 185, 255), width=2)  # cremallera
    pocket(d, x + 14, y + 26, 30, 28, dk(c["main"], 0.6))
    d.polygon([(x + 44, y), (x + 64, y + 18), (x + 84, y)], fill=dk(c["main"], 0.8))
    name_tag(d, x + 88, y + 30)
    for key in ("F", "B", "R", "L"):
        RO.stains(img, TORSO[key], seed + len(key) * 7, 7, color=(30, 30, 30), alpha=85, size=(3, 9))
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            if key not in ("U", "D"):
                RO.stains(img, rect, seed + rect[0], 3, color=(30, 30, 30), alpha=80)
    d = ImageDraw.Draw(img)
    cuffs(d, dk(c["main"], 0.82), h=14)
    return finish(img, seed=seed)


def s_pijama(c, seed):
    """Pijama sanitario (manga corta, cuello en pico, bolsillo con bolígrafo)."""
    img, d = base(c, seed, "short")
    x, y, w, h = TORSO["F"]
    collar_v(img, x, y, c.get("under", (240, 240, 240)), depth=40, half=22, seed=seed)
    d.line([(x + 42, y), (x + 64, y + 40), (x + 86, y)], fill=dk(c["main"], 0.6), width=3)
    pocket(d, x + 86, y + 50, 26, 24, dk(c["main"], 0.65), flap=False)
    d.rectangle([x + 92, y + 44, x + 96, y + 56], fill=(40, 60, 160, 255))
    name_tag(d, x + 14, y + 48)
    d.rectangle([x + 30, y + 20, x + 44, y + 34], fill=(245, 245, 245, 255))  # cruz sanitaria
    d.rectangle([x + 35, y + 22, x + 39, y + 32], fill=(210, 50, 50, 255))
    d.rectangle([x + 32, y + 25, x + 42, y + 29], fill=(210, 50, 50, 255))
    cuffs(d, dk(c["main"], 0.85), short=True, h=6)
    return finish(img, seed=seed)


def s_bombero(c, seed):
    img, d = base(c, seed, "long", "twill")
    x, y, w, h = TORSO["F"]
    d.line([(x + 64, y), (x + 64, y + h)], fill=(30, 30, 30, 255), width=3)
    for k in range(4):
        d.rectangle([x + 60, y + 14 + k * 26, x + 68, y + 20 + k * 26], fill=(190, 190, 190, 255))
    for key in ("F", "B", "R", "L"):
        reflective(d, TORSO[key], (0.42, 0.86))
    bx, by, bw, bh = TORSO["B"]
    d.rectangle([bx + 10, by + 10, bx + bw - 10, by + 40], fill=c["main"] + (255,))
    text_c(d, bx + 64, by + 24, "BOMBEROS", 14, (250, 210, 40, 255))
    for arm in (RIGHT, LEFT):
        for key, rect in arm.items():
            if key not in ("U", "D"):
                reflective(d, rect, (0.62,), h=7)
    cuffs(d, (30, 30, 30, 255), h=8)
    return finish(img, seed=seed)


def s_camarera(c, seed):
    """Camisa negra de manga corta, cuello blanco y chapita (el delantal es un accesorio 3D)."""
    img, d = base(c, seed, "short")
    x, y, w, h = TORSO["F"]
    d.polygon([(x + 40, y), (x + 64, y + 18), (x + 88, y)], fill=(245, 245, 245, 255), outline=(150, 150, 150, 255))
    d.line([(x + 64, y + 18), (x + 64, y + h)], fill=dk(c["main"], 0.5), width=2)
    for k in range(4):
        GEN.button(d, x + 64, y + 30 + k * 20, 3)
    name_tag(d, x + 86, y + 34)
    cuffs(d, (245, 245, 245, 255), short=True, h=5)
    return finish(img, seed=seed)


def s_barman(c, seed):
    """Camisa negra arremangada con chaleco oscuro."""
    img, d = base(c, seed, "long")
    x, y, w, h = TORSO["F"]
    vest = RO.tinted_tile(128, 128, seed + 5, c.get("vest", (40, 40, 46)), "twill")
    m = Image.new("L", (128, 128), 0)
    md = ImageDraw.Draw(m)
    md.polygon([(0, 0), (40, 0), (64, 70), (64, 128), (0, 128)], fill=255)
    md.polygon([(128, 0), (88, 0), (64, 70), (64, 128), (128, 128)], fill=255)
    vest.putalpha(m)
    img.alpha_composite(vest, (x, y))
    for k in range(3):
        GEN.button(d, x + 60, y + 78 + k * 14, 3)
    for arm in (RIGHT, LEFT):  # remangada: el antebrazo, piel
        for key, rect in arm.items():
            if key in ("U", "D"):
                continue
            ax, ay, aw, ah = rect
            d.rectangle([ax, ay + int(ah * 0.5), ax + aw - 1, ay + ah - 1], fill=(0, 0, 0, 0))
            d.rectangle([ax, ay + int(ah * 0.5) - 10, ax + aw - 1, ay + int(ah * 0.5)], fill=dk(c["main"], 1.25))
    return finish(img, seed=seed)


def s_pescador(c, seed):
    """Camiseta de manga larga (el chaleco de pesca es un accesorio 3D)."""
    img, d = base(c, seed, "long", "knit")
    x, y, w, h = TORSO["F"]
    d.arc([x + 40, y - 16, x + 88, y + 18], 0, 180, fill=dk(c["main"], 0.6), width=4)
    cuffs(d, dk(c["main"], 0.8), h=10)
    return finish(img, seed=seed)


def s_reparto(c, seed):
    img, d = base(c, seed, "short")
    x, y, w, h = TORSO["F"]
    st = c.get("stripe", (90, 200, 90))
    d.polygon([(x + 42, y), (x + 64, y + 20), (x + 86, y)], fill=st + (255,))
    for k in range(2):
        GEN.button(d, x + 64, y + 26 + k * 14, 3)
    d.rectangle([x + 88, y + 30, x + 112, y + 50], fill=st + (255,))  # caja
    d.line([(x + 88, y + 40), (x + 112, y + 40)], fill=dk(st, 0.6), width=2)
    bx, by, bw, bh = TORSO["B"]
    text_c(d, bx + 64, by + 40, "REPARTO", 17, st + (255,))
    for key in ("F", "B", "R", "L"):
        rx, ry, rw, rh = TORSO[key]
        d.rectangle([rx, ry + 64, rx + rw - 1, ry + 70], fill=st + (255,))
    cuffs(d, st + (255,), short=True, h=6)
    return finish(img, seed=seed)


def s_traje(c, seed):
    img, d = base(c, seed, "long", "twill")
    x, y, w, h = TORSO["F"]
    shirt = RO.tinted_tile(128, 128, seed + 1, c.get("under", (245, 245, 245)))
    m = Image.new("L", (128, 128), 0)
    ImageDraw.Draw(m).polygon([(36, 0), (92, 0), (64, 74)], fill=255)
    shirt.putalpha(m)
    img.alpha_composite(shirt, (x, y))
    tie = c.get("tie", (30, 30, 34))
    d.polygon([(x + 58, y + 4), (x + 70, y + 4), (x + 67, y + 12), (x + 72, y + 62), (x + 64, y + 72), (x + 56, y + 62), (x + 61, y + 12)], fill=tie + (255,))
    for s in (-1, 1):
        d.line([(x + 64 + s * 28, y), (x + 64 + s * 6, y + 74)], fill=dk(c["main"], 0.55), width=4)
    GEN.button(d, x + 64, y + 86, 4)
    GEN.button(d, x + 64, y + 104, 4)
    d.line([(x + 92, y + 30), (x + 112, y + 30)], fill=dk(c["main"], 0.55), width=3)
    cuffs(d, c.get("under", (245, 245, 245)) + (255,), h=5)
    return finish(img, seed=seed)


def s_bata(c, seed):
    """Bata blanca limpia (farmacia, consulta) sobre camisa de color."""
    img, d = base(c, seed, "long")
    x, y, w, h = TORSO["F"]
    under = RO.tinted_tile(128, 128, seed + 1, c.get("under", (90, 160, 160)))
    m = Image.new("L", (128, 128), 0)
    ImageDraw.Draw(m).polygon([(40, 0), (88, 0), (64, 64)], fill=255)
    under.putalpha(m)
    img.alpha_composite(under, (x, y))
    for s in (-1, 1):
        d.line([(x + 64 + s * 24, y), (x + 64, y + 64)], fill=(170, 170, 175, 255), width=3)
    d.line([(x + 64, y + 64), (x + 64, y + h)], fill=(170, 170, 175, 255), width=2)
    for k in range(3):
        GEN.button(d, x + 68, y + 72 + k * 18, 3)
    pocket(d, x + 90, y + 40, 24, 24, (170, 170, 175, 255), flap=False)
    for px in (x + 8, x + 94):
        pocket(d, px, y + 92, 26, 24, (170, 170, 175, 255), flap=False)
    name_tag(d, x + 14, y + 40)
    d.rectangle([x + 20, y + 20, x + 32, y + 32], fill=(60, 170, 90, 255))  # cruz de farmacia
    d.rectangle([x + 24, y + 14, x + 28, y + 38], fill=(60, 170, 90, 255))
    d.rectangle([x + 14, y + 24, x + 38, y + 28], fill=(60, 170, 90, 255))
    cuffs(d, (225, 225, 228, 255), h=8)
    return finish(img, seed=seed)


def s_obra(c, seed):
    """Camiseta y chaleco naranja de alta visibilidad con bandas."""
    img, d = base(c, seed, "short", arm_color=c.get("shirt", (60, 70, 120)))
    x, y, w, h = TORSO["F"]
    sh = RO.tinted_tile(128, 128, seed + 2, c.get("shirt", (60, 70, 120)))
    m = Image.new("L", (128, 128), 0)
    ImageDraw.Draw(m).polygon([(44, 0), (84, 0), (64, 36)], fill=255)
    sh.putalpha(m)
    img.alpha_composite(sh, (x, y))
    d.line([(x + 64, y + 36), (x + 64, y + h)], fill=dk(c["main"], 0.6), width=2)
    for key in ("F", "B", "R", "L"):
        reflective(d, TORSO[key], (0.5, 0.8), h=8, color=(215, 215, 220, 255), silver=(240, 240, 245, 255))
    pocket(d, x + 14, y + 40, 26, 22, dk(c["main"], 0.65))
    return finish(img, seed=seed)


def s_delantal(c, seed):
    """Camisa de cuadros pequeños de manga corta (el delantal de la tienda es un accesorio 3D)."""
    img, d = base(c, seed, "short")
    lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dl = ImageDraw.Draw(lay)
    dark = dk(c["main"], 0.75)[:3] + (90,)
    for xx in range(0, RO.TW, 12):
        dl.line([(xx, 0), (xx, RO.TH)], fill=dark, width=3)
    for yy in range(0, RO.TH, 12):
        dl.line([(0, yy), (RO.TW, yy)], fill=dark, width=3)
    a = np.array(img)[..., 3]
    cc = Image.new("RGBA", img.size, (0, 0, 0, 0))
    cc.paste(lay, (0, 0), Image.fromarray(a))
    img.alpha_composite(cc)
    d = ImageDraw.Draw(img)
    x, y, w, h = TORSO["F"]
    d.polygon([(x + 40, y), (x + 64, y + 20), (x + 88, y)], fill=dk(c["main"], 1.1), outline=dk(c["main"], 0.6))
    for k in range(4):
        GEN.button(d, x + 64, y + 26 + k * 22, 3)
    cuffs(d, dk(c["main"], 0.85), short=True, h=6)
    return finish(img, seed=seed)


def s_moda(c, seed):
    """Blusa clara con chaleco vaquero (dependienta de ropa)."""
    img, d = base(c, seed, "long", arm_color=c.get("under", (245, 240, 235)))
    x, y, w, h = TORSO["F"]
    under = RO.tinted_tile(128, 128, seed + 1, c.get("under", (245, 240, 235)))
    m = Image.new("L", (128, 128), 0)
    ImageDraw.Draw(m).rectangle([38, 0, 90, 128], fill=255)
    under.putalpha(m)
    img.alpha_composite(under, (x, y))
    for s in (-1, 1):
        d.line([(x + 64 + s * 26, y), (x + 64 + s * 26, y + h)], fill=(200, 180, 120, 255), width=2)
    for px in (x + 10, x + 96):
        pocket(d, px, y + 26, 22, 20, (200, 180, 120, 255))
    d.ellipse([x + 56, y + 8, x + 72, y + 22], outline=(210, 180, 90, 255), width=2)  # collar
    return finish(img, seed=seed)


# ---------------------------------------------------------------- camisetas de la calle
def s_camiseta(c, seed):
    img, d = base(c, seed, "short", "knit")
    x, y, w, h = TORSO["F"]
    d.arc([x + 40, y - 16, x + 88, y + 18], 0, 180, fill=dk(c["main"], 0.65), width=4)
    deco = c.get("deco")
    if deco == "raya":
        st = c.get("stripe", (245, 245, 245))
        for key in ("F", "B", "R", "L"):
            rx, ry, rw, rh = TORSO[key]
            d.rectangle([rx, ry + 44, rx + rw - 1, ry + 58], fill=st + (255,))
    elif deco == "estrella":
        badge(d, x + 64, y + 56, 22, c.get("stripe", (250, 220, 80)) + (255,))
    elif deco == "circulo":
        st = c.get("stripe", (245, 245, 245))
        d.ellipse([x + 40, y + 34, x + 88, y + 82], outline=st + (255,), width=6)
    elif deco == "hoja":
        st = c.get("stripe", (90, 180, 90))
        d.polygon([(x + 64, y + 30), (x + 86, y + 56), (x + 64, y + 84), (x + 42, y + 56)], fill=st + (255,))
        d.line([(x + 64, y + 34), (x + 64, y + 82)], fill=dk(st, 0.6), width=2)
    cuffs(d, dk(c["main"], 0.85), short=True, h=5)
    return finish(img, seed=seed)


def s_sudadera(c, seed):
    img, d = base(c, seed, "long", "fleece")
    x, y, w, h = TORSO["F"]
    d.polygon([(x + 36, y), (x + 64, y + 26), (x + 92, y)], fill=dk(c["main"], 0.8))
    for s in (-1, 1):
        d.line([(x + 64 + s * 8, y + 26), (x + 64 + s * 10, y + 52)], fill=(235, 235, 235, 255), width=2)
    d.rounded_rectangle([x + 30, y + 74, x + 98, y + 108], 8, outline=dk(c["main"], 0.6), width=3)  # bolsillo canguro
    st = c.get("stripe")
    if st:
        d.rectangle([x + 34, y + 40, x + 94, y + 50], fill=st + (255,))
    cuffs(d, dk(c["main"], 0.8), h=10)
    for key in ("F", "B", "L", "R"):
        rx, ry, rw, rh = TORSO[key]
        d.rectangle([rx, ry + rh - 12, rx + rw - 1, ry + rh - 1], fill=dk(c["main"], 0.82))
    return finish(img, seed=seed)


def s_camisa(c, seed):
    img, d = base(c, seed, c.get("sleeves", "long"))
    x, y, w, h = TORSO["F"]
    d.polygon([(x + 40, y), (x + 64, y + 22), (x + 88, y)], fill=dk(c["main"], 1.08), outline=dk(c["main"], 0.6))
    d.line([(x + 64, y + 22), (x + 64, y + h)], fill=dk(c["main"], 0.65), width=2)
    for k in range(5):
        GEN.button(d, x + 68, y + 28 + k * 20, 3)
    if c.get("deco") == "rayas":
        lay = Image.new("RGBA", img.size, (0, 0, 0, 0))
        dl = ImageDraw.Draw(lay)
        st = c.get("stripe", (245, 245, 245)) + (120,)
        for xx in range(0, RO.TW, 9):
            dl.line([(xx, 0), (xx, RO.TH)], fill=st, width=2)
        a = np.array(img)[..., 3]
        cc = Image.new("RGBA", img.size, (0, 0, 0, 0))
        cc.paste(lay, (0, 0), Image.fromarray(a))
        img.alpha_composite(cc)
        d = ImageDraw.Draw(img)
    pocket(d, x + 18, y + 32, 24, 22, dk(c["main"], 0.62), flap=False)
    cuffs(d, dk(c["main"], 0.88), short=c.get("sleeves") == "short", h=8)
    return finish(img, seed=seed)


def s_chaqueta(c, seed):
    img, d = base(c, seed, "long", "twill")
    x, y, w, h = TORSO["F"]
    collar_v(img, x, y, c.get("under", (240, 240, 240)), depth=80, half=30, seed=seed)
    d.line([(x + 64, y + 80), (x + 64, y + h)], fill=(190, 190, 195, 255), width=2)
    for s in (-1, 1):
        d.line([(x + 64 + s * 30, y), (x + 64 + s * 2, y + 80)], fill=dk(c["main"], 0.55), width=4)
    for px in (x + 10, x + 94):
        d.line([(px, y + 90), (px + 22, y + 84)], fill=dk(c["main"], 0.55), width=3)
    cuffs(d, dk(c["main"], 0.8), h=10)
    return finish(img, seed=seed)


def s_vestido(c, seed):
    """Vestido de tirantes sobre camiseta (la falda la da el pantalón «falda»)."""
    img, d = base(c, seed, "short", arm_color=c.get("under", (245, 245, 245)))
    x, y, w, h = TORSO["F"]
    under = RO.tinted_tile(128, 128, seed + 1, c.get("under", (245, 245, 245)))
    m = Image.new("L", (128, 128), 0)
    ImageDraw.Draw(m).polygon([(30, 0), (98, 0), (90, 34), (38, 34)], fill=255)
    under.putalpha(m)
    img.alpha_composite(under, (x, y))
    st = c.get("stripe")
    if st:
        rr = random.Random(seed)
        for _ in range(40):
            for key in ("F", "B"):
                rx, ry, rw, rh = TORSO[key]
                px, py = rx + rr.uniform(4, rw - 4), ry + rr.uniform(38, rh - 4)
                d.ellipse([px - 3, py - 3, px + 3, py + 3], fill=st + (255,))
    d.rectangle([x, y + 92, x + w - 1, y + 100], fill=dk(c["main"], 0.7))
    return finish(img, seed=seed)


def s_rebeca_mayor(c, seed):
    img = RO.shirt_template("cardigan", {"main": c["main"], "under": c.get("under", (240, 235, 225))}, seed)
    return img


def s_chaleco_mayor(c, seed):
    """Camisa clara y chaleco de punto (señor mayor)."""
    img, d = base({"main": c.get("under", (225, 225, 220))}, seed, "long")
    x, y, w, h = TORSO["F"]
    vest = RO.tinted_tile(128, 128, seed + 5, c["main"], "knit")
    for key in ("F", "B", "L", "R"):
        rx, ry, rw, rh = TORSO[key]
        m = Image.new("L", (rw, rh), 0)
        md = ImageDraw.Draw(m)
        if key == "F":
            md.polygon([(0, 0), (36, 0), (64, 64), (92, 0), (128, 0), (128, 128), (0, 128)], fill=255)
        else:
            md.rectangle([0, 0, rw, rh], fill=255)
        v = vest.crop((0, 0, rw, rh))
        v.putalpha(m)
        img.alpha_composite(v, (rx, ry))
    d = ImageDraw.Draw(img)
    for k in range(4):
        GEN.button(d, x + 64, y + 70 + k * 14, 3)
    return finish(img, seed=seed)


SHIRTS = {
    "policia": s_policia, "mono": s_mono, "pijama": s_pijama, "bombero": s_bombero, "camarera": s_camarera,
    "barman": s_barman, "pescador": s_pescador, "reparto": s_reparto, "traje": s_traje, "bata": s_bata,
    "obra": s_obra, "tienda": s_delantal, "moda": s_moda,
    "camiseta": s_camiseta, "sudadera": s_sudadera, "camisa": s_camisa, "chaqueta": s_chaqueta, "vestido": s_vestido,
    "rebeca_mayor": s_rebeca_mayor, "chaleco_mayor": s_chaleco_mayor,
}


def shirt(kind, colors, seed):
    return SHIRTS[kind](colors, seed)


# ---------------------------------------------------------------- pantalones
def p_falda(c, seed):
    """Falda hasta la rodilla (el resto de la pierna, transparente: piel) y zapatos aparte."""
    img = Image.new("RGBA", (RO.TW, RO.TH), (0, 0, 0, 0))
    tile = RO.tinted_tile(128, 128, seed, c["main"], "plain")
    for rect in TORSO.values():
        RO.paint_rect(img, rect, tile)
    d = ImageDraw.Draw(img)
    for leg in (RIGHT, LEFT):
        for key, rect in leg.items():
            if key == "D":
                continue
            x, y, w, h = rect
            if key == "U":
                RO.paint_rect(img, rect, tile)
                continue
            sub = (x, y, w, int(h * 0.42))
            RO.paint_rect(img, sub, tile)
            d.rectangle([x, y + int(h * 0.42) - 5, x + w - 1, y + int(h * 0.42) - 1], fill=dk(c["main"], 0.7))
    return img


def p_mono(c, seed):
    img = RO.pants_template("cargo", c, seed)
    for leg in (RIGHT, LEFT):
        for key, rect in leg.items():
            if key not in ("U", "D"):
                RO.stains(img, rect, seed + rect[0] + 9, 4, color=(30, 30, 30), alpha=80)
    return img


def p_bombero(c, seed):
    img = RO.pants_template("trousers", c, seed)
    d = ImageDraw.Draw(img)
    for leg in (RIGHT, LEFT):
        for key, rect in leg.items():
            if key not in ("U", "D"):
                reflective(d, rect, (0.7,), h=7)
    return img


PANTS = {"falda": p_falda, "mono": p_mono, "bombero": p_bombero}


def pants(kind, colors, seed):
    if kind in PANTS:
        return PANTS[kind](colors, seed)
    return RO.pants_template(kind, colors, seed)
