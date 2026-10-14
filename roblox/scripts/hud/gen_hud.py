"""Sprites del HUD de vuelo (nave y avión): arcos con brillo, marcos, iconos, radar, brújula…

Hechos con código (PIL + numpy), con suavizado (se dibuja a 4x y se reduce) y brillo (desenfoque).
Salen a assets/hud/*.png (cada uno ≤ 1024 px) y a assets/hud/manifest.json (tamaños de los atlas, los
recortes 9-slice y el orden de los iconos; UI/HudArt.luau usa los mismos números y
scripts/test-espacio-aaa.luau comprueba que coinciden).

    python3 -I scripts/hud/gen_hud.py            (desde la carpeta roblox/)

Después: bash scripts/upload-hud.sh (solo en la sesión que publica) escribe src/shared/HudTextureIds.luau.
Mientras ese archivo esté vacío el HUD se ve con marcos y rayitas de Roblox (el aspecto de siempre).
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "assets", "hud")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

SS = 4  # se dibuja a 4x y se reduce (bordes suaves)

CYAN = (110, 230, 255)
EDGE = (70, 200, 255)
WHITE = (240, 250, 255)
NAVY = (6, 18, 38)

# ---------------------------------------------------------------------------
# Ayudantes
# ---------------------------------------------------------------------------


def mask(w, h):
    return Image.new("L", (w * SS, h * SS), 0)


def S(pts, ox=0, oy=0):
    return [((x + ox) * SS, (y + oy) * SS) for x, y in pts]


def solid(m, color, alpha=1.0):
    """Capa RGBA del color con la forma de la máscara"""
    img = Image.new("RGBA", m.size, color + (0,))
    a = np.asarray(m, dtype=np.float32) * alpha
    img.putalpha(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)))
    return img


def gradient(m, top, bottom, alpha=1.0, y0=None, y1=None):
    """Capa con degradado vertical (de top a bottom) dentro de la máscara"""
    w, h = m.size
    y0 = 0 if y0 is None else y0 * SS
    y1 = h if y1 is None else y1 * SS
    ys = np.clip((np.arange(h, dtype=np.float32) - y0) / max(1, y1 - y0), 0, 1)[:, None]
    t = np.asarray(top, np.float32)
    b = np.asarray(bottom, np.float32)
    rgb = t[None, None, :] * (1 - ys[..., None]) + b[None, None, :] * ys[..., None]
    rgb = np.broadcast_to(rgb, (h, w, 3))
    a = np.asarray(m, dtype=np.float32) * alpha
    arr = np.dstack([rgb, a[..., None]]).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def glow(m, color, radius, strength=1.0):
    blurred = m.filter(ImageFilter.GaussianBlur(radius * SS))
    a = np.asarray(blurred, dtype=np.float32) * strength
    img = Image.new("RGBA", m.size, color + (0,))
    img.putalpha(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)))
    return img


def edge(m, width):
    """El borde (por dentro) de una máscara"""
    k = max(3, int(width * SS) * 2 + 1)
    inner = m.filter(ImageFilter.MinFilter(k))
    a = np.asarray(m, dtype=np.int16) - np.asarray(inner, dtype=np.int16)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def stack(size, *layers):
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    for layer in layers:
        if layer is not None:
            out = Image.alpha_composite(out, layer)
    return out


def down(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


def union(*ms):
    out = Image.new("L", ms[0].size, 0)
    for m in ms:
        out = Image.fromarray(np.maximum(np.asarray(out), np.asarray(m)))
    return out


def minus(a, b):
    return Image.fromarray(np.clip(np.asarray(a, np.int16) - np.asarray(b, np.int16), 0, 255).astype(np.uint8))


def sector(d, cx, cy, r0, r1, a0, a1, steps=None):
    """Trozo de aro (grados de pantalla: 0 = derecha, 90 = abajo)"""
    n = steps or max(4, int(abs(a1 - a0) / 1.5))
    pts = []
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        pts.append((cx + math.cos(a) * r1, cy + math.sin(a) * r1))
    for i in range(n, -1, -1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        pts.append((cx + math.cos(a) * r0, cy + math.sin(a) * r0))
    d.polygon(S(pts), fill=255)


def ring(d, cx, cy, r, width):
    d.ellipse(S([(cx - r, cy - r), (cx + r, cy + r)]), outline=255, width=max(1, int(width * SS)))


def disc(d, cx, cy, r):
    d.ellipse(S([(cx - r, cy - r), (cx + r, cy + r)]), fill=255)


def line(d, a, b, width):
    d.line(S([a, b]), fill=255, width=max(1, int(width * SS)))
    for p in (a, b):  # puntas redondas
        r = width / 2
        d.ellipse(S([(p[0] - r, p[1] - r), (p[0] + r, p[1] + r)]), fill=255)


def save(img, name):
    path = os.path.join(OUT, name + ".png")
    img.save(path, optimize=True)
    return path


# ---------------------------------------------------------------------------
# Arcos (velocidad e impulso a la izquierda; escudo y estructura a la derecha)
# ---------------------------------------------------------------------------
ARC = {
    "FrameW": 128,
    "FrameH": 256,
    "Cols": 8,
    "Frames": 21,  # 0 %, 5 %, … 100 %
    "Segments": 20,
    "From": 112,  # grados (pantalla): abajo a la izquierda…
    "To": 248,  # …arriba a la izquierda
}
ARC_CX, ARC_CY = 146, 128
ARC_KINDS = {
    # nombre: radio interior, exterior, hueco entre segmentos (grados)
    "grueso": (108, 124, 1.8),
    "medio": (95, 104, 1.4),
    "fino": (98, 102, 0.7),
}


def arc_mask(kind, lit):
    r0, r1, gap = ARC_KINDS[kind]
    n = ARC["Segments"]
    span = (ARC["To"] - ARC["From"]) / n
    m = mask(ARC["FrameW"], ARC["FrameH"])
    d = ImageDraw.Draw(m)
    for i in range(lit):
        # se llena de abajo (From) arriba (To)
        a0 = ARC["From"] + i * span + gap / 2
        a1 = ARC["From"] + (i + 1) * span - gap / 2
        sector(d, ARC_CX, ARC_CY, r0, r1, a0, a1, 6)
    return m


def arc_frame(kind, lit):
    """Un estado del arco: los segmentos encendidos en blanco con brillo (se tiñe con ImageColor3)"""
    m = arc_mask(kind, lit)
    size = m.size
    if lit == 0:
        return Image.new("RGBA", (ARC["FrameW"], ARC["FrameH"]), (0, 0, 0, 0))
    core = gradient(m, (255, 255, 255), (215, 235, 245))
    img = stack(size, glow(m, (255, 255, 255), 7, 0.55), glow(m, (255, 255, 255), 2.5, 0.6), core)
    # la punta (el último segmento) un poco más brillante: se ve que se mueve
    tip = minus(arc_mask(kind, lit), arc_mask(kind, lit - 1))
    img = stack(size, img, glow(tip, (255, 255, 255), 5, 0.7))
    return down(img, ARC["FrameW"], ARC["FrameH"])


def arc_atlas(kind, mirror):
    cols = ARC["Cols"]
    rows = math.ceil(ARC["Frames"] / cols)
    atlas = Image.new("RGBA", (cols * ARC["FrameW"], rows * ARC["FrameH"]), (0, 0, 0, 0))
    for i in range(ARC["Frames"]):
        lit = round(i * ARC["Segments"] / (ARC["Frames"] - 1))
        f = arc_frame(kind, lit)
        if mirror:
            f = f.transpose(Image.FLIP_LEFT_RIGHT)
        atlas.paste(f, ((i % cols) * ARC["FrameW"], (i // cols) * ARC["FrameH"]))
    return atlas


def arc_base(kinds, mirror):
    """El fondo de los arcos: segmentos apagados, rayitas de escala y un filo fino (a 2x del marco)"""
    w, h = ARC["FrameW"], ARC["FrameH"]
    k = 2
    W, H = w * k, h * k
    m_seg = Image.new("L", (W * SS, H * SS), 0)
    m_tick = Image.new("L", (W * SS, H * SS), 0)
    m_major = Image.new("L", (W * SS, H * SS), 0)
    m_line = Image.new("L", (W * SS, H * SS), 0)
    ds, dt, dm, dl = (ImageDraw.Draw(x) for x in (m_seg, m_tick, m_major, m_line))
    cx, cy = ARC_CX * k, ARC_CY * k
    n = ARC["Segments"]
    span = (ARC["To"] - ARC["From"]) / n
    for kind in kinds:
        r0, r1, gap = ARC_KINDS[kind]
        for i in range(n):
            a0 = ARC["From"] + i * span + gap / 2
            a1 = ARC["From"] + (i + 1) * span - gap / 2
            sector(ds, cx, cy, r0 * k, r1 * k, a0, a1, 6)
    # escala por fuera del arco grueso: una rayita por segmento, larga cada 5
    outer = max(ARC_KINDS[x][1] for x in kinds) * k
    for i in range(n + 1):
        a = math.radians(ARC["From"] + i * span)
        major = i % 5 == 0
        r0, r1 = outer + 4 * k, outer + (11 if major else 7) * k
        line(dm if major else dt, (cx + math.cos(a) * r0, cy + math.sin(a) * r0), (cx + math.cos(a) * r1, cy + math.sin(a) * r1), (1.6 if major else 1.0) * k)
    # filo fino por fuera y remates en las puntas
    sector(dl, cx, cy, outer + 2 * k, outer + 2.8 * k, ARC["From"] - 4, ARC["To"] + 4, 90)
    inner = min(ARC_KINDS[x][0] for x in kinds) * k
    sector(dl, cx, cy, inner - 6 * k, inner - 5.4 * k, ARC["From"] + 10, ARC["To"] - 10, 90)
    for a_deg in (ARC["From"] - 4, ARC["To"] + 4):
        a = math.radians(a_deg)
        line(dl, (cx + math.cos(a) * (inner - 2 * k), cy + math.sin(a) * (inner - 2 * k)), (cx + math.cos(a) * (outer + 3 * k), cy + math.sin(a) * (outer + 3 * k)), 2 * k)
    size = m_seg.size
    img = stack(
        size,
        solid(m_seg, (30, 80, 120), 0.55),
        glow(m_line, EDGE, 3 * k, 0.5),
        solid(m_line, CYAN, 0.75),
        solid(m_tick, (150, 210, 240), 0.7),
        glow(m_major, CYAN, 2.5 * k, 0.6),
        solid(m_major, WHITE, 0.95),
    )
    img = down(img, W, H)
    return img.transpose(Image.FLIP_LEFT_RIGHT) if mirror else img


# ---------------------------------------------------------------------------
# Recarga de las ranuras: barrido de reloj (21 estados)
# ---------------------------------------------------------------------------
COOL = {"Frame": 96, "Cols": 8, "Frames": 21}


def cool_atlas():
    f = COOL["Frame"]
    cols = COOL["Cols"]
    rows = math.ceil(COOL["Frames"] / cols)
    atlas = Image.new("RGBA", (cols * f, rows * f), (0, 0, 0, 0))
    for i in range(COOL["Frames"]):
        left = i / (COOL["Frames"] - 1)  # lo que falta (0 = listo, 1 = recién usado)
        if left <= 0:
            continue
        m = mask(f, f)
        d = ImageDraw.Draw(m)
        c = f / 2
        a0 = -90 + 360 * (1 - left)
        if left >= 1:
            d.rectangle(S([(0, 0), (f, f)]), fill=255)
        else:
            sector(d, c, c, 0, f, a0, 270, max(8, int(360 * left / 4)))
        e = mask(f, f)
        de = ImageDraw.Draw(e)
        a = math.radians(a0)
        if left < 1:
            line(de, (c, c), (c + math.cos(a) * f * 0.7, c + math.sin(a) * f * 0.7), 2)
        img = stack(m.size, solid(m, (0, 6, 16), 0.62), glow(e, CYAN, 2, 0.8), solid(e, WHITE, 0.8))
        atlas.paste(down(img, f, f), ((i % cols) * f, (i // cols) * f))
    return atlas


# ---------------------------------------------------------------------------
# Marcos (9-slice)
# ---------------------------------------------------------------------------
FRAMES = {
    # nombre: tamaño, recorte central (x0, y0, x1, y1), margen del brillo por fuera
    "marco_panel": {"Size": [96, 96], "Slice": [30, 30, 66, 66], "Pad": 6},
    "marco_ranura": {"Size": [96, 96], "Slice": [26, 26, 70, 70], "Pad": 6},
    "marco_ranura_sel": {"Size": [96, 96], "Slice": [26, 26, 70, 70], "Pad": 6},
    "marco_cabecera": {"Size": [128, 32], "Slice": [20, 4, 100, 28], "Pad": 0},
    "barra": {"Size": [48, 16], "Slice": [8, 3, 40, 13], "Pad": 2},
}


def chamfer_poly(x0, y0, x1, y1, tl, tr, br, bl):
    return [(x0 + tl, y0), (x1 - tr, y0), (x1, y0 + tr), (x1, y1 - br), (x1 - br, y1), (x0 + bl, y1), (x0, y1 - bl), (x0, y0 + tl)]


def panel_frame():
    w, h = FRAMES["marco_panel"]["Size"]
    p = FRAMES["marco_panel"]["Pad"]
    poly = chamfer_poly(p, p, w - p, h - p, 14, 0, 14, 0)
    m = mask(w, h)
    ImageDraw.Draw(m).polygon(S(poly), fill=255)
    rim = edge(m, 1.2)
    inner_glow = minus(edge(m, 7).filter(ImageFilter.GaussianBlur(3 * SS)), Image.new("L", m.size, 0))
    inner_glow = Image.fromarray((np.asarray(inner_glow, np.float32) * (np.asarray(m, np.float32) / 255)).astype(np.uint8))
    # acentos de las esquinas: el chaflán de arriba a la izquierda y el de abajo a la derecha, más gruesos
    acc = mask(w, h)
    da = ImageDraw.Draw(acc)
    line(da, (p, p + 14), (p + 14, p), 3)
    line(da, (p + 14, p), (p + 30, p), 3)
    line(da, (w - p, h - p - 14), (w - p - 14, h - p), 3)
    line(da, (w - p - 14, h - p), (w - p - 30, h - p), 3)
    line(da, (w - p, p), (w - p, p + 10), 2.2)  # remate arriba a la derecha
    img = stack(
        m.size,
        glow(m, EDGE, 4, 0.45),
        gradient(m, (12, 34, 66), (4, 12, 28), 0.82, p, h - p),
        solid(inner_glow, (60, 170, 240), 0.35),
        solid(rim, CYAN, 0.9),
        glow(acc, CYAN, 3, 0.9),
        solid(acc, WHITE, 1.0),
    )
    return down(img, w, h)


def slot_frame(selected):
    w, h = FRAMES["marco_ranura"]["Size"]
    p = FRAMES["marco_ranura"]["Pad"]
    poly = chamfer_poly(p, p, w - p, h - p, 10, 10, 10, 10)
    m = mask(w, h)
    ImageDraw.Draw(m).polygon(S(poly), fill=255)
    rim = edge(m, 2.2 if selected else 1.3)
    under = mask(w, h)
    du = ImageDraw.Draw(under)
    line(du, (p + 16, h - p - 3), (w - p - 16, h - p - 3), 3)
    inner_glow = edge(m, 9).filter(ImageFilter.GaussianBlur(4 * SS))
    inner_glow = Image.fromarray((np.asarray(inner_glow, np.float32) * (np.asarray(m, np.float32) / 255)).astype(np.uint8))
    top, bottom = ((24, 70, 120), (8, 26, 56)) if selected else ((14, 36, 70), (4, 14, 32))
    img = stack(
        m.size,
        glow(m, CYAN if selected else EDGE, 5 if selected else 3, 0.75 if selected else 0.35),
        gradient(m, top, bottom, 0.9, p, h - p),
        solid(inner_glow, (80, 200, 255), 0.55 if selected else 0.3),
        solid(rim, WHITE if selected else CYAN, 0.95 if selected else 0.75),
        glow(under, CYAN, 4, 1.0),
        solid(under, WHITE, 0.95),
    )
    return down(img, w, h)


def header_frame():
    w, h = FRAMES["marco_cabecera"]["Size"]
    m = mask(w, h)
    ImageDraw.Draw(m).polygon(S([(0, 2), (w - 12, 2), (w, h - 4), (0, h - 4)]), fill=255)
    fade = np.linspace(1, 0.1, w * SS, dtype=np.float32)[None, :]
    a = (np.asarray(m, np.float32) * fade).astype(np.uint8)
    m2 = Image.fromarray(a)
    hair = mask(w, h)
    dh = ImageDraw.Draw(hair)
    line(dh, (0, h - 3), (w - 2, h - 3), 1.2)
    notch = mask(w, h)
    ImageDraw.Draw(notch).rectangle(S([(0, 2), (3, h - 4)]), fill=255)
    hair_a = Image.fromarray((np.asarray(hair, np.float32) * np.linspace(1, 0.2, w * SS, dtype=np.float32)[None, :]).astype(np.uint8))
    img = stack(m.size, gradient(m2, (40, 120, 190), (16, 60, 110), 0.55), solid(hair_a, CYAN, 0.9), glow(notch, CYAN, 2, 0.9), solid(notch, WHITE, 1))
    return down(img, w, h)


def bar_frame():
    w, h = FRAMES["barra"]["Size"]
    p = FRAMES["barra"]["Pad"]
    m = mask(w, h)
    ImageDraw.Draw(m).rounded_rectangle(S([(p, p + 1), (w - p, h - p - 1)]), radius=(h / 2 - p - 1) * SS, fill=255)
    hi = mask(w, h)
    ImageDraw.Draw(hi).rounded_rectangle(S([(p + 3, p + 2), (w - p - 3, p + 4)]), radius=SS, fill=255)
    img = stack(m.size, glow(m, (255, 255, 255), 2, 0.5), gradient(m, (255, 255, 255), (200, 210, 220)), solid(hi, (255, 255, 255), 0.9))
    return down(img, w, h)


# ---------------------------------------------------------------------------
# Radar, aros, mira, brújula, vórtice y siluetas
# ---------------------------------------------------------------------------


def radar_disc():
    s = 512
    c = s / 2
    R = 236
    m = mask(s, s)
    disc(ImageDraw.Draw(m), c, c, R)
    yy, xx = np.mgrid[0 : s * SS, 0 : s * SS].astype(np.float32)
    r = np.sqrt((xx - c * SS) ** 2 + (yy - c * SS) ** 2) / (R * SS)
    k = np.clip(r, 0, 1)[..., None]
    rgb = np.array([16, 52, 84], np.float32) * (1 - k) + np.array([4, 14, 30], np.float32) * k
    a = np.asarray(m, np.float32) * 0.8
    fill = Image.fromarray(np.dstack([rgb, a[..., None]]).astype(np.uint8), "RGBA")
    grid = mask(s, s)
    dg = ImageDraw.Draw(grid)
    for f in (0.33, 0.66):
        ring(dg, c, c, R * f, 1.6)
    line(dg, (c - R * 0.94, c), (c + R * 0.94, c), 1.2)
    line(dg, (c, c - R * 0.94), (c, c + R * 0.94), 1.2)
    for a_deg in (45, 135, 225, 315):
        a = math.radians(a_deg)
        line(dg, (c + math.cos(a) * R * 0.12, c + math.sin(a) * R * 0.12), (c + math.cos(a) * R * 0.9, c + math.sin(a) * R * 0.9), 0.8)
    rim = mask(s, s)
    dr = ImageDraw.Draw(rim)
    ring(dr, c, c, R, 4)
    ring(dr, c, c, R + 10, 1.4)
    ticks = mask(s, s)
    dt = ImageDraw.Draw(ticks)
    for deg in range(0, 360, 5):
        a = math.radians(deg)
        major = deg % 30 == 0
        r0, r1 = R - (16 if major else 9), R - 3
        line(dt, (c + math.cos(a) * r0, c + math.sin(a) * r0), (c + math.cos(a) * r1, c + math.sin(a) * r1), 2.2 if major else 1.2)
    # cono de delante (arriba)
    cone = mask(s, s)
    sector(ImageDraw.Draw(cone), c, c, 0, R * 0.95, -90 - 30, -90 + 30, 30)
    img = stack(
        m.size,
        glow(m, EDGE, 10, 0.5),
        fill,
        solid(cone, (60, 170, 240), 0.1),
        solid(grid, CYAN, 0.35),
        solid(ticks, CYAN, 0.6),
        glow(rim, CYAN, 6, 0.8),
        solid(rim, (170, 240, 255), 0.95),
    )
    return down(img, s, s)


def radar_sweep():
    s = 256
    c = s / 2
    yy, xx = np.mgrid[0 : s * SS, 0 : s * SS].astype(np.float32)
    ang = (np.degrees(np.arctan2(yy - c * SS, xx - c * SS)) + 90) % 360  # 0 = arriba, sentido horario
    r = np.sqrt((xx - c * SS) ** 2 + (yy - c * SS) ** 2) / (c * SS)
    trail = 70.0
    behind = (360 - ang) % 360  # grados por detrás del borde (que mira arriba)
    a = np.clip(1 - behind / trail, 0, 1) ** 1.6 * (r <= 0.97) * 150
    rgb = np.zeros((s * SS, s * SS, 3), np.float32) + np.array(CYAN, np.float32)
    img = Image.fromarray(np.dstack([rgb, a[..., None]]).astype(np.uint8), "RGBA")
    lead = mask(s, s)
    line(ImageDraw.Draw(lead), (c, c), (c, c - c * 0.96), 2)
    img = stack(img.size, img, glow(lead, CYAN, 3, 0.9), solid(lead, WHITE, 0.9))
    return down(img, s, s)


def avatar_ring():
    s = 256
    c = s / 2
    m = mask(s, s)
    d = ImageDraw.Draw(m)
    ring(d, c, c, 104, 4)
    arcs = mask(s, s)
    da = ImageDraw.Draw(arcs)
    for a0, a1 in ((-160, -100), (-80, -20), (20, 70), (110, 160)):
        sector(da, c, c, 114, 119, a0, a1, 30)
    dots = mask(s, s)
    dd = ImageDraw.Draw(dots)
    for deg in range(0, 360, 10):
        a = math.radians(deg)
        disc(dd, c + math.cos(a) * 124, c + math.sin(a) * 124, 1.3)
    img = stack(m.size, glow(m, EDGE, 8, 0.9), solid(m, (190, 245, 255), 1), glow(arcs, CYAN, 4, 0.8), solid(arcs, CYAN, 0.95), solid(dots, CYAN, 0.6))
    return down(img, s, s)


def widget_ring():
    """El aro de la nave en planta (abajo a la izquierda) y de los atajos: casi blanco (se tiñe)"""
    s = 512
    c = s / 2
    base = mask(s, s)
    d = ImageDraw.Draw(base)
    ring(d, c, c, 236, 2)
    ring(d, c, c, 196, 1.2)
    arcs = mask(s, s)
    da = ImageDraw.Draw(arcs)
    for a0, a1 in ((-150, -95), (-80, -30), (25, 80), (100, 155)):
        sector(da, c, c, 214, 226, a0, a1, 40)
    cross = mask(s, s)
    dc = ImageDraw.Draw(cross)
    for a_deg in range(0, 360, 90):
        a = math.radians(a_deg)
        line(dc, (c + math.cos(a) * 150, c + math.sin(a) * 150), (c + math.cos(a) * 190, c + math.sin(a) * 190), 1.5)
    fill = mask(s, s)
    disc(ImageDraw.Draw(fill), c, c, 234)
    img = stack(
        base.size,
        solid(fill, (4, 14, 30), 0.55),
        glow(base, (200, 240, 255), 6, 0.6),
        solid(base, (200, 240, 255), 0.8),
        solid(cross, (200, 240, 255), 0.4),
        glow(arcs, (255, 255, 255), 6, 0.8),
        solid(arcs, (255, 255, 255), 1),
    )
    return down(img, s, s)


def reticle():
    s = 256
    c = s / 2
    m = mask(s, s)
    d = ImageDraw.Draw(m)
    ring(d, c, c, 34, 3)
    for a0 in (-80, 10, 100, 190):
        sector(d, c, c, 96, 99, a0, a0 + 70, 30)
    for a_deg in (0, 90, 180, 270):
        a = math.radians(a_deg)
        line(d, (c + math.cos(a) * 22, c + math.sin(a) * 22), (c + math.cos(a) * 52, c + math.sin(a) * 52), 3)
    disc(d, c, c, 5)
    chev = mask(s, s)
    dch = ImageDraw.Draw(chev)
    line(dch, (c - 10, 8), (c, 20), 3)
    line(dch, (c + 10, 8), (c, 20), 3)
    img = stack(m.size, glow(m, CYAN, 6, 0.9), solid(m, (190, 245, 255), 1), glow(chev, CYAN, 4, 0.8), solid(chev, CYAN, 1))
    return down(img, s, s)


COMPASS = {"W": 960, "H": 48, "PxPerDeg": 2, "Window": 120}


def compass_tape():
    w, h = COMPASS["W"], COMPASS["H"]
    k = COMPASS["PxPerDeg"]
    small, mid, big, base = mask(w, h), mask(w, h), mask(w, h), mask(w, h)
    ds, dm, db = ImageDraw.Draw(small), ImageDraw.Draw(mid), ImageDraw.Draw(big)
    for deg in range(0, w // k + 1, 5):
        x = deg * k
        if deg % 45 == 0:
            line(db, (x, h - 26), (x, h - 6), 2.4)
        elif deg % 15 == 0:
            line(dm, (x, h - 18), (x, h - 6), 1.8)
        else:
            line(ds, (x, h - 12), (x, h - 6), 1.2)
    line(ImageDraw.Draw(base), (0, h - 5), (w, h - 5), 1.2)
    img = stack(small.size, solid(base, EDGE, 0.55), solid(small, (150, 200, 230), 0.6), glow(mid, CYAN, 2, 0.5), solid(mid, CYAN, 0.9), glow(big, CYAN, 4, 0.9), solid(big, WHITE, 1))
    return down(img, w, h)


def vortex():
    s = 256
    c = s / 2
    yy, xx = np.mgrid[0:s, 0:s].astype(np.float32)
    dx, dy = (xx - c) / c, (yy - c) / c
    r = np.sqrt(dx * dx + dy * dy)
    th = np.arctan2(dy, dx)
    arms = 0.5 + 0.5 * np.cos(4 * th + 9 * r)
    arms = arms ** 3
    fall = np.clip(1 - r, 0, 1)
    core = np.exp(-(r / 0.16) ** 2)
    a = np.clip((arms * fall * 1.4 + core) * 255 * (r < 1), 0, 255)
    col1 = np.array([120, 90, 255], np.float32)
    col2 = np.array([110, 230, 255], np.float32)
    t = np.clip(r * 1.3, 0, 1)[..., None]
    rgb = col2 * (1 - t) + col1 * t
    rgb = rgb + core[..., None] * 120
    img = Image.fromarray(np.dstack([np.clip(rgb, 0, 255), a[..., None]]).astype(np.uint8), "RGBA")
    return img.filter(ImageFilter.GaussianBlur(0.8))


def silhouette(kind):
    w, h = 256, 320
    m = mask(w, h)
    d = ImageDraw.Draw(m)
    detail = mask(w, h)
    dd = ImageDraw.Draw(detail)
    cock = mask(w, h)
    dc = ImageDraw.Draw(cock)
    cx = w / 2
    if kind == "nave":
        body = [(cx, 14), (cx + 16, 60), (cx + 22, 120), (cx + 30, 150), (cx + 112, 214), (cx + 112, 236), (cx + 40, 226), (cx + 34, 288), (cx + 14, 300), (cx - 14, 300), (cx - 34, 288), (cx - 40, 226), (cx - 112, 236), (cx - 112, 214), (cx - 30, 150), (cx - 22, 120), (cx - 16, 60)]
        d.polygon(S(body), fill=255)
        for sx in (-1, 1):
            d.polygon(S([(cx + sx * 44, 170), (cx + sx * 58, 176), (cx + sx * 58, 296), (cx + sx * 44, 306)]), fill=255)
            line(dd, (cx + sx * 26, 150), (cx + sx * 100, 216), 1.4)
            line(dd, (cx + sx * 51, 190), (cx + sx * 51, 290), 1.2)
        line(dd, (cx, 60), (cx, 280), 1.2)
        dc.ellipse(S([(cx - 9, 70), (cx + 9, 112)]), fill=255)
        for sx in (-1, 0, 1):
            disc(dc, cx + sx * 20, 300, 5)
    else:
        body = [(cx, 20), (cx + 12, 40), (cx + 14, 120), (cx + 118, 124), (cx + 118, 146), (cx + 14, 154), (cx + 10, 250), (cx + 52, 262), (cx + 52, 278), (cx + 8, 282), (cx, 300), (cx - 8, 282), (cx - 52, 278), (cx - 52, 262), (cx - 10, 250), (cx - 14, 154), (cx - 118, 146), (cx - 118, 124), (cx - 14, 120), (cx - 12, 40)]
        d.polygon(S(body), fill=255)
        line(dd, (cx - 110, 135), (cx + 110, 135), 1.2)
        line(dd, (cx, 50), (cx, 280), 1.2)
        line(dd, (cx - 30, 22), (cx + 30, 22), 2)  # hélice
        dc.ellipse(S([(cx - 8, 70), (cx + 8, 108)]), fill=255)
    rim = edge(m, 1.8)
    img = stack(m.size, glow(m, CYAN, 8, 0.45), gradient(m, (30, 90, 140), (10, 40, 80), 0.55), solid(detail, CYAN, 0.6), glow(rim, CYAN, 3, 0.9), solid(rim, (190, 245, 255), 1), glow(cock, CYAN, 4, 1), solid(cock, WHITE, 1))
    return down(img, w, h)


def emblem():
    s = 128
    c = s / 2
    m = mask(s, s)
    d = ImageDraw.Draw(m)
    ring(d, c, c, 56, 3)
    for a0 in (-130, -40, 50, 140):
        sector(d, c, c, 44, 47, a0, a0 + 60, 20)
    img = stack(m.size, glow(m, CYAN, 6, 0.9), solid(m, (180, 245, 255), 1))
    return down(img, s, s)


# ---------------------------------------------------------------------------
# Iconos (atlas de 8 x 4, 128 px): de colores, con brillo
# ---------------------------------------------------------------------------
ICON = 128
ICONS = [
    "escudo", "energia", "cristal", "cubo", "mineral", "misil", "laser", "camuflaje",
    "salto", "hiper", "dron", "tren", "flaps", "frenos", "camara", "armas",
    "moneda", "corazon", "emblema", "rombo", "rombo_rojo", "aviso", "avion", "bajarse",
    "motor_max", "motor_0", "palanca", "combustible", "rango", "objetivo", "estructura", "chispas",
]

C_TOP, C_BOT = (190, 245, 255), (40, 140, 230)


def icon_shape(m, top=C_TOP, bottom=C_BOT, rim=WHITE, glow_c=CYAN, glow_k=0.9, rim_w=1.6, fill_a=0.95):
    return [glow(m, glow_c, 7, glow_k * 0.6), glow(m, glow_c, 2.5, glow_k * 0.5), gradient(m, top, bottom, fill_a, 16, 112), solid(edge(m, rim_w), rim, 0.95)]


def icon_cell(name):
    s = ICON
    c = s / 2
    L = []

    def M():
        m = mask(s, s)
        return m, ImageDraw.Draw(m)

    if name in ("escudo", "estructura"):
        m, d = M()
        shield = [(c, 14), (c + 40, 28), (c + 38, 70), (c, 114), (c - 38, 70), (c - 40, 28)]
        d.polygon(S(shield), fill=255)
        L += icon_shape(m)
        h, dh = M()
        dh.polygon(S([(c, 24), (c - 30, 34), (c - 28, 68), (c, 102)]), fill=255)
        L.append(solid(h, (255, 255, 255), 0.35))
        inner, di = M()
        di.polygon(S([(c, 26), (c + 30, 36), (c + 28, 68), (c, 102), (c - 28, 68), (c - 30, 36)]), fill=255)
        L.append(solid(edge(inner, 1.4), (255, 255, 255), 0.7))
        if name == "estructura":
            bars, db = M()
            for y in (52, 66, 80):
                line(db, (c - 16, y), (c + 16, y), 4)
            L.append(solid(bars, (20, 60, 110), 0.9))
    elif name == "energia":
        m, d = M()
        d.polygon(S([(c + 10, 10), (c - 26, 70), (c - 2, 70), (c - 12, 118), (c + 28, 52), (c + 4, 52), (c + 18, 10)]), fill=255)
        L += icon_shape(m, (255, 250, 200), (255, 190, 40), WHITE, (255, 200, 60))
    elif name == "cristal":
        for (x, y0, y1, wd, tone) in ((c - 22, 40, 100, 14, 0.8), (c + 22, 44, 100, 13, 0.85), (c, 14, 110, 18, 1.0)):
            m, d = M()
            d.polygon(S([(x, y0), (x + wd, y0 + wd), (x + wd, y1 - 8), (x, y1), (x - wd, y1 - 8), (x - wd, y0 + wd)]), fill=255)
            L += icon_shape(m, (200, 240, 255), (40, 110, 240), WHITE, (90, 170, 255), 0.7 * tone)
            fa, dfa = M()
            dfa.polygon(S([(x, y0), (x - wd, y0 + wd), (x - wd, y1 - 8), (x, y1)]), fill=255)
            L.append(solid(fa, (255, 255, 255), 0.3))
    elif name == "cubo":
        top_face = [(c, 18), (c + 40, 38), (c, 58), (c - 40, 38)]
        left_face = [(c - 40, 38), (c, 58), (c, 110), (c - 40, 88)]
        right_face = [(c + 40, 38), (c, 58), (c, 110), (c + 40, 88)]
        allm, da = M()
        for f in (top_face, left_face, right_face):
            da.polygon(S(f), fill=255)
        L.append(glow(allm, (255, 170, 60), 6, 0.7))
        for f, col in ((top_face, (255, 225, 140)), (left_face, (230, 140, 40)), (right_face, (180, 95, 25))):
            m, d = M()
            d.polygon(S(f), fill=255)
            L.append(solid(m, col, 1))
        L.append(solid(edge(allm, 1.4), (255, 240, 200), 0.9))
        inner, di = M()
        di.polygon(S([(c, 32), (c + 20, 42), (c, 52), (c - 20, 42)]), fill=255)
        L.append(solid(inner, (255, 250, 220), 0.5))
    elif name == "mineral":
        m, d = M()
        d.polygon(S([(c, 14), (c + 46, 104), (c - 46, 104)]), fill=255)
        L += icon_shape(m, (255, 220, 140), (200, 110, 30), (255, 240, 200), (255, 160, 60))
        core, dc = M()
        dc.polygon(S([(c, 54), (c + 16, 88), (c - 16, 88)]), fill=255)
        L.append(solid(core, (60, 30, 10), 0.85))
        L.append(glow(core, (255, 240, 120), 3, 0.8))
    elif name == "misil":
        m, d = M()
        # cuerpo en diagonal (abajo-izquierda → arriba-derecha)
        line(d, (c - 26, c + 26), (c + 26, c - 26), 18)
        d.polygon(S([(c + 20, c - 34), (c + 46, c - 46), (c + 34, c - 20)]), fill=255)
        for sx, sy in ((-1, 1), (1, -1)):
            pass
        d.polygon(S([(c - 30, c + 10), (c - 44, c + 8), (c - 26, c + 26)]), fill=255)
        d.polygon(S([(c - 10, c + 30), (c - 8, c + 44), (c - 26, c + 26)]), fill=255)
        L += icon_shape(m, (240, 250, 255), (120, 170, 220))
        fl, df = M()
        df.polygon(S([(c - 30, c + 30), (c - 56, c + 50), (c - 50, c + 56)]), fill=255)
        L.append(glow(fl, (255, 90, 60), 6, 1))
        L.append(solid(fl, (255, 200, 120), 1))
        st, ds = M()
        line(ds, (c - 6, c + 6), (c + 6, c - 6), 6)
        L.append(solid(st, (255, 70, 70), 0.95))
    elif name == "laser":
        m, d = M()
        line(d, (16, 112), (104, 24), 7)
        L.append(glow(m, CYAN, 8, 1))
        L.append(solid(m, CYAN, 1))
        core, dc = M()
        line(dc, (16, 112), (104, 24), 2.5)
        L.append(solid(core, WHITE, 1))
        tip, dt = M()
        for a_deg in range(0, 360, 45):
            a = math.radians(a_deg)
            r = 18 if a_deg % 90 == 0 else 10
            line(dt, (104, 24), (104 + math.cos(a) * r, 24 + math.sin(a) * r), 2.5)
        disc(dt, 104, 24, 6)
        L.append(glow(tip, CYAN, 5, 1))
        L.append(solid(tip, WHITE, 1))
    elif name in ("camuflaje", "objetivo"):
        m, d = M()
        ring(d, c, c, 38, 5)
        for a0 in (-60, 30, 120, 210):
            sector(d, c, c, 48, 54, a0, a0 + 30, 10)
        for a_deg in (0, 90, 180, 270):
            a = math.radians(a_deg)
            line(d, (c + math.cos(a) * 26, c + math.sin(a) * 26), (c + math.cos(a) * 46, c + math.sin(a) * 46), 4)
        disc(d, c, c, 7)
        if name == "objetivo":
            L += icon_shape(m, (255, 160, 140), (230, 40, 40), (255, 220, 210), (255, 60, 60))
        else:
            L += icon_shape(m, (200, 245, 255), (60, 150, 240))
            dots, dd = M()
            for a_deg in range(15, 360, 30):
                a = math.radians(a_deg)
                disc(dd, c + math.cos(a) * 56, c + math.sin(a) * 56, 2.2)
            L.append(solid(dots, CYAN, 0.7))
    elif name == "salto":
        m, d = M()
        for i, (rx, ry, wd) in enumerate(((50, 24, 5), (36, 16, 4), (22, 10, 4))):
            el = Image.new("L", (s * SS, s * SS), 0)
            ImageDraw.Draw(el).ellipse(S([(c - rx, c - ry), (c + rx, c + ry)]), outline=255, width=wd * SS)
            el = el.rotate(-35, resample=Image.BICUBIC, center=(c * SS, c * SS))
            m = union(m, el)
        L += icon_shape(m, (220, 220, 255), (90, 110, 255), WHITE, (120, 140, 255))
        core, dc = M()
        disc(dc, c, c, 9)
        L.append(glow(core, (200, 220, 255), 6, 1))
        L.append(solid(core, WHITE, 1))
    elif name == "hiper":
        m, d = M()
        d.polygon(S([(c, 12), (c + 34, 96), (c, 78), (c - 34, 96)]), fill=255)
        L += icon_shape(m)
        st, ds = M()
        for x, y0 in ((c - 40, 70), (c + 40, 70), (c - 22, 92), (c + 22, 92)):
            line(ds, (x, y0), (x, y0 + 26), 3)
        L.append(glow(st, (255, 160, 60), 4, 0.9))
        L.append(solid(st, (255, 210, 140), 1))
    elif name == "dron":
        m, d = M()
        for sx, sy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
            line(d, (c, c), (c + sx * 34, c + sy * 34), 6)
            ring(d, c + sx * 38, c + sy * 38, 14, 4)
        disc(d, c, c, 18)
        L += icon_shape(m)
        eye, de = M()
        disc(de, c, c, 6)
        L.append(glow(eye, (255, 80, 80), 4, 1))
        L.append(solid(eye, (255, 140, 140), 1))
    elif name == "tren":
        m, d = M()
        line(d, (c, 18), (c, 72), 8)
        line(d, (c - 28, 18), (c + 28, 18), 7)
        ring(d, c, 88, 22, 8)
        L += icon_shape(m)
        hub, dh = M()
        disc(dh, c, 88, 6)
        L.append(solid(hub, WHITE, 1))
    elif name == "flaps":
        m, d = M()
        d.polygon(S([(12, 54), (40, 40), (86, 42), (92, 54), (86, 60), (12, 60)]), fill=255)
        L += icon_shape(m)
        fl, df = M()
        df.polygon(S([(96, 58), (118, 84), (110, 90), (90, 64)]), fill=255)
        L.append(glow(fl, (255, 160, 60), 4, 0.9))
        L.append(solid(fl, (255, 180, 80), 1))
    elif name == "frenos":
        m, d = M()
        ring(d, c, c, 40, 9)
        for a_deg in range(0, 360, 60):
            a = math.radians(a_deg)
            disc(d, c + math.cos(a) * 22, c + math.sin(a) * 22, 4)
        L += icon_shape(m)
        cal, dc = M()
        sector(dc, c, c, 34, 52, -40, 40, 16)
        L.append(glow(cal, (255, 120, 60), 4, 0.9))
        L.append(solid(cal, (255, 150, 70), 1))
    elif name == "camara":
        m, d = M()
        d.rounded_rectangle(S([(16, 38), (112, 102)]), radius=10 * SS, fill=255)
        d.rectangle(S([(40, 26), (70, 40)]), fill=255)
        L += icon_shape(m)
        lens, dl = M()
        ring(dl, c, 70, 20, 6)
        L.append(solid(lens, (10, 40, 80), 1))
        L.append(solid(edge(lens, 1), WHITE, 1))
    elif name == "armas":
        m, d = M()
        for off in (-9, 9):
            line(d, (24 + off, 96 + off), (96 + off, 24 + off), 7)
        d.polygon(S([(14, 92), (36, 114), (46, 104), (24, 82)]), fill=255)
        L += icon_shape(m)
        tips, dt = M()
        for off in (-9, 9):
            disc(dt, 96 + off, 24 + off, 5)
        L.append(glow(tips, CYAN, 5, 1))
        L.append(solid(tips, WHITE, 1))
    elif name == "moneda":
        m, d = M()
        disc(d, c, c, 46)
        L += icon_shape(m, (170, 255, 190), (30, 170, 90), (220, 255, 230), (80, 230, 140))
        sym, ds = M()
        ring(ds, c, c, 36, 3)
        f = ImageFont.truetype(FONT, 58 * SS)
        ds.text((c * SS, c * SS + 2 * SS), "€", font=f, fill=255, anchor="mm")
        L.append(solid(sym, (10, 70, 40), 0.85))
    elif name == "corazon":
        m, d = M()
        disc(d, c - 20, 46, 25)
        disc(d, c + 20, 46, 25)
        d.polygon(S([(c - 44, 54), (c + 44, 54), (c, 108)]), fill=255)
        L += icon_shape(m, (255, 170, 170), (220, 40, 60), (255, 220, 220), (255, 70, 90))
    elif name == "rango":
        m, d = M()
        for y in (30, 58):
            d.polygon(S([(c - 44, y), (c, y + 26), (c + 44, y), (c + 44, y + 16), (c, y + 42), (c - 44, y + 16)]), fill=255)
        L += icon_shape(m, (255, 240, 170), (220, 150, 30), (255, 250, 220), (255, 200, 70))
        st, dst = M()
        dst.polygon(S([(c, 4), (c + 6, 16), (c + 18, 16), (c + 8, 23), (c + 12, 34), (c, 27), (c - 12, 34), (c - 8, 23), (c - 18, 16), (c - 6, 16)]), fill=255)
        L.append(glow(st, (255, 230, 120), 3, 0.9))
        L.append(solid(st, (255, 250, 220), 1))
    elif name == "emblema":
        m, d = M()
        d.polygon(S([(c, 26), (c + 22, 52), (c + 10, 52), (c + 10, 96), (c, 108), (c - 10, 96), (c - 10, 52), (c - 22, 52)]), fill=255)
        for sx in (-1, 1):
            d.polygon(S([(c + sx * 16, 66), (c + sx * 58, 34), (c + sx * 50, 56), (c + sx * 60, 54), (c + sx * 46, 80), (c + sx * 18, 90)]), fill=255)
        L += icon_shape(m, (255, 240, 170), (220, 150, 30), (255, 250, 220), (255, 200, 70))
    elif name in ("rombo", "rombo_rojo"):
        m, d = M()
        d.polygon(S([(c, 14), (c + 46, c), (c, 114), (c - 46, c)]), fill=255)
        hole, dh = M()
        dh.polygon(S([(c, 38), (c + 22, c), (c, 90), (c - 22, c)]), fill=255)
        ringm = minus(m, hole)
        if name == "rombo":
            L += icon_shape(ringm, (255, 240, 170), (230, 160, 30), (255, 250, 220), (255, 200, 70))
            L.append(solid(hole, (255, 220, 120), 0.9))
        else:
            L += icon_shape(ringm, (255, 150, 140), (220, 30, 40), (255, 210, 200), (255, 60, 60))
            L.append(solid(hole, (255, 90, 80), 0.9))
    elif name == "aviso":
        m, d = M()
        d.polygon(S([(c, 14), (c + 52, 108), (c - 52, 108)]), fill=255)
        L += icon_shape(m, (255, 240, 160), (240, 160, 30), (255, 250, 220), (255, 200, 70))
        ex, de = M()
        line(de, (c, 46), (c, 78), 9)
        disc(de, c, 94, 6)
        L.append(solid(ex, (60, 30, 0), 0.9))
    elif name == "avion":
        m, d = M()
        d.polygon(S([(c, 10), (c + 8, 24), (c + 8, 52), (c + 56, 64), (c + 56, 74), (c + 8, 70), (c + 6, 98), (c + 24, 106), (c + 24, 114), (c, 110), (c - 24, 114), (c - 24, 106), (c - 6, 98), (c - 8, 70), (c - 56, 74), (c - 56, 64), (c - 8, 52), (c - 8, 24)]), fill=255)
        L += icon_shape(m)
    elif name == "bajarse":
        m, d = M()
        d.rectangle(S([(20, 16), (60, 112)]), outline=255, width=7 * SS)
        line(d, (56, 64), (104, 64), 8)
        line(d, (104, 64), (86, 46), 8)
        line(d, (104, 64), (86, 82), 8)
        L += icon_shape(m)
    elif name in ("motor_max", "motor_0"):
        m, d = M()
        d.rounded_rectangle(S([(c - 8, 14), (c + 8, 114)]), radius=6 * SS, fill=255)
        L += icon_shape(m, (120, 170, 210), (40, 80, 120), (190, 230, 255), EDGE, 0.5)
        y = 30 if name == "motor_max" else 96
        hd, dh = M()
        dh.rounded_rectangle(S([(c - 34, y - 10), (c + 34, y + 10)]), radius=8 * SS, fill=255)
        L += icon_shape(hd, (255, 220, 150), (240, 130, 30), (255, 245, 220), (255, 160, 60))
    elif name == "palanca":
        m, d = M()
        disc(d, c, 34, 18)
        line(d, (c, 50), (c, 96), 9)
        d.rounded_rectangle(S([(c - 36, 94), (c + 36, 110)]), radius=6 * SS, fill=255)
        L += icon_shape(m)
        ar, da = M()
        line(da, (c + 44, 40), (c + 44, 82), 6)
        line(da, (c + 44, 84), (c + 32, 70), 6)
        line(da, (c + 44, 84), (c + 56, 70), 6)
        L.append(glow(ar, (255, 160, 60), 3, 0.9))
        L.append(solid(ar, (255, 190, 100), 1))
    elif name == "combustible":
        m, d = M()
        disc(d, c, 78, 32)
        d.polygon(S([(c, 12), (c + 30, 66), (c - 30, 66)]), fill=255)
        L += icon_shape(m, (255, 230, 150), (240, 140, 30), (255, 245, 220), (255, 170, 60))
        hi, dh = M()
        dh.ellipse(S([(c - 18, 66), (c - 6, 92)]), fill=255)
        L.append(solid(hi, (255, 255, 255), 0.6))
    elif name == "chispas":
        m, d = M()
        d.polygon(S([(c, 16), (c + 11, c - 11), (112, c), (c + 11, c + 11), (c, 112), (c - 11, c + 11), (16, c), (c - 11, c - 11)]), fill=255)
        L += icon_shape(m, (255, 250, 200), (255, 190, 40), WHITE, (255, 210, 80))
    img = stack((s * SS, s * SS), *L) if L else Image.new("RGBA", (s * SS, s * SS), (0, 0, 0, 0))
    return down(img, s, s)


def icon_atlas():
    cols = 8
    rows = math.ceil(len(ICONS) / cols)
    atlas = Image.new("RGBA", (cols * ICON, rows * ICON), (0, 0, 0, 0))
    for i, name in enumerate(ICONS):
        atlas.paste(icon_cell(name), ((i % cols) * ICON, (i // cols) * ICON))
    return atlas


# ---------------------------------------------------------------------------


def main():
    os.makedirs(OUT, exist_ok=True)
    files = {}
    files["arco_grueso_izq"] = save(arc_atlas("grueso", False), "arco_grueso_izq")
    files["arco_fino_izq"] = save(arc_atlas("fino", False), "arco_fino_izq")
    files["arco_grueso_der"] = save(arc_atlas("grueso", True), "arco_grueso_der")
    files["arco_medio_der"] = save(arc_atlas("medio", True), "arco_medio_der")
    files["arco_base_izq"] = save(arc_base(["grueso", "fino"], False), "arco_base_izq")
    files["arco_base_der"] = save(arc_base(["grueso", "medio"], True), "arco_base_der")
    files["recarga"] = save(cool_atlas(), "recarga")
    files["marco_panel"] = save(panel_frame(), "marco_panel")
    files["marco_ranura"] = save(slot_frame(False), "marco_ranura")
    files["marco_ranura_sel"] = save(slot_frame(True), "marco_ranura_sel")
    files["marco_cabecera"] = save(header_frame(), "marco_cabecera")
    files["barra"] = save(bar_frame(), "barra")
    files["radar"] = save(radar_disc(), "radar")
    files["radar_barrido"] = save(radar_sweep(), "radar_barrido")
    files["aro_avatar"] = save(avatar_ring(), "aro_avatar")
    files["aro_widget"] = save(widget_ring(), "aro_widget")
    files["mira"] = save(reticle(), "mira")
    files["brujula_cinta"] = save(compass_tape(), "brujula_cinta")
    files["vortice"] = save(vortex(), "vortice")
    files["silueta_nave"] = save(silhouette("nave"), "silueta_nave")
    files["silueta_avion"] = save(silhouette("avion"), "silueta_avion")
    files["emblema"] = save(emblem(), "emblema")
    files["iconos"] = save(icon_atlas(), "iconos")
    manifest = {
        "Arc": ARC,
        "Cool": COOL,
        "Compass": COMPASS,
        "Icon": {"Size": ICON, "Cols": 8, "Names": ICONS},
        "Frames": FRAMES,
        "Files": {},
    }
    total = 0
    for name, path in sorted(files.items()):
        im = Image.open(path)
        size = os.path.getsize(path)
        total += size
        manifest["Files"][name] = {"W": im.width, "H": im.height, "Bytes": size}
    manifest["TotalBytes"] = total
    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1, sort_keys=True)
    print(f"{len(files)} sprites en assets/hud ({total / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
