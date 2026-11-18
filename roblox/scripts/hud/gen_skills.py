"""Iconos PINTADOS de las habilidades, las pociones y el Atacar (18-11-2026, el dueño: «crea los botones más
profesionales, son muy cutres los botones de habilidad»). Sustituyen a los emojis.

Cada icono: fondo con degradado radial del color de la habilidad, rayos suaves, el símbolo con brillo (glow),
relleno degradado y borde oscuro, y un reflejo de cristal arriba. Más dos marcos dorados (cuadrado y redondo)
que se ponen encima. Todo se dibuja a 4x y se reduce (bordes suaves).

Uso (desde roblox/):  python -I scripts/hud/gen_skills.py   -> assets/hud/hab_*.png, pocion_*.png, marco_hab*.png
Subir: bash scripts/upload-hud.sh   (escribe src/shared/HudTextureIds.luau)
"""
import math
import os
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "..", "assets", "hud"))
os.makedirs(OUT, exist_ok=True)
S = 1024  # lienzo de trabajo (4x)
FINAL = 256
C = S / 2


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def radial(inner, outer, power=1.4):
    img = Image.new("RGB", (S, S))
    px = img.load()
    for y in range(0, S, 2):
        for x in range(0, S, 2):
            d = min(1.0, math.hypot(x - C, y - C * 0.9) / (S * 0.72)) ** power
            c = lerp(inner, outer, d)
            px[x, y] = c
            if x + 1 < S:
                px[x + 1, y] = c
            if y + 1 < S:
                px[x, y + 1] = c
                if x + 1 < S:
                    px[x + 1, y + 1] = c
    return img


def rays(color, n=14, alpha=34, seed=1):
    random.seed(seed)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(n):
        a = i / n * math.tau + random.uniform(-0.1, 0.1)
        w = random.uniform(0.05, 0.11)
        pts = [(C, C), (C + math.cos(a - w) * S, C + math.sin(a - w) * S), (C + math.cos(a + w) * S, C + math.sin(a + w) * S)]
        d.polygon(pts, fill=color + (alpha,))
    return layer.filter(ImageFilter.GaussianBlur(18))


def vgrad(top, bottom):
    g = Image.new("RGB", (1, S))
    for y in range(S):
        g.putpixel((0, y), lerp(top, bottom, y / (S - 1)))
    return g.resize((S, S))


def emboss(base, mask, light, main, glow, outline=(20, 14, 30), glow_r=38, glow_a=1.0):
    """Pone el símbolo (mask L) sobre base: brillo, borde oscuro, relleno degradado y luz arriba."""
    g = mask.filter(ImageFilter.GaussianBlur(glow_r))
    g = g.point(lambda v: min(255, int(v * 1.6 * glow_a)))
    glow_layer = Image.new("RGBA", (S, S), glow + (0,))
    glow_layer.putalpha(g)
    base.alpha_composite(glow_layer)
    edge = mask.filter(ImageFilter.MaxFilter(17))
    ol = Image.new("RGBA", (S, S), outline + (0,))
    ol.putalpha(edge)
    base.alpha_composite(ol)
    fill = vgrad(light, main).convert("RGBA")
    fill.putalpha(mask)
    base.alpha_composite(fill)
    # (luz arriba a la izquierda: el borde de arriba del símbolo más claro)
    shifted = ImageChops.offset(mask, 10, 14)
    rim = ImageChops.subtract(mask, shifted).filter(ImageFilter.GaussianBlur(3))
    hl = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    hl.putalpha(rim.point(lambda v: int(v * 0.8)))
    base.alpha_composite(hl)


def poly_mask(polys, ellipses=(), cut=()):
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    for p in polys:
        d.polygon(p, fill=255)
    for e in ellipses:
        d.ellipse(e, fill=255)
    for c in cut:
        if len(c) == 4 and not isinstance(c[0], tuple):
            d.ellipse(c, fill=0)
        else:
            d.polygon(c, fill=0)
    return m


def rot(pts, ang, cx=C, cy=C):
    ca, sa = math.cos(ang), math.sin(ang)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in pts]


def sparkles(base, color, n=18, seed=3, r=(4, 10)):
    random.seed(seed)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(n):
        a = random.uniform(0, math.tau)
        dist = random.uniform(0.18, 0.42) * S
        x, y = C + math.cos(a) * dist, C + math.sin(a) * dist
        rr = random.uniform(*r)
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=color + (220,))
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(2)))
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(10)))


def finish(base, name):
    # reflejo de cristal arriba y viñeta
    gloss = Image.new("L", (S, S), 0)
    ImageDraw.Draw(gloss).ellipse((-S * 0.25, -S * 0.75, S * 1.25, S * 0.42), fill=58)
    gloss = gloss.filter(ImageFilter.GaussianBlur(30))
    gl = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    gl.putalpha(gloss)
    base.alpha_composite(gl)
    vig = Image.new("L", (S, S), 0)
    ImageDraw.Draw(vig).rectangle((0, 0, S, S), fill=150)
    ImageDraw.Draw(vig).ellipse((S * 0.06, S * 0.06, S * 0.94, S * 0.94), fill=0)
    vig = vig.filter(ImageFilter.GaussianBlur(70))
    vl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    vl.putalpha(vig)
    base.alpha_composite(vl)
    base.resize((FINAL, FINAL), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))
    print("  ", name)


def grain(seed, alpha=26):
    random.seed(seed)
    small = Image.new("L", (S // 4, S // 4))
    small.putdata([random.randint(0, 255) for _ in range((S // 4) ** 2)])
    n = small.resize((S, S), Image.BICUBIC).filter(ImageFilter.GaussianBlur(1.5))
    light = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    light.putalpha(n.point(lambda v: max(0, v - 150) * alpha // 60))
    dark = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dark.putalpha(n.point(lambda v: max(0, 105 - v) * alpha // 60))
    return light, dark


def rune_ring(color, alpha=70, seed=0):
    """Anillo grabado con runas y rombos (detalle del fondo)."""
    random.seed(seed + 99)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    col = color + (alpha,)
    for r, w in ((430, 6), (395, 3), (300, 3)):
        d.ellipse((C - r, C - r, C + r, C + r), outline=col, width=w)
    for i in range(36):
        a = i / 36 * math.tau
        if i % 3 == 0:
            cx, cy = C + math.cos(a) * 413, C + math.sin(a) * 413
            for _ in range(random.choice((2, 3))):
                b = a + random.choice((0, math.pi / 2, math.pi / 4, -math.pi / 4))
                ln = random.uniform(8, 13)
                d.line((cx - math.cos(b) * ln, cy - math.sin(b) * ln, cx + math.cos(b) * ln, cy + math.sin(b) * ln), fill=col, width=4)
        else:
            d.line((C + math.cos(a) * 398, C + math.sin(a) * 398, C + math.cos(a) * 408, C + math.sin(a) * 408), fill=col, width=3)
    for i in range(8):
        a = i / 8 * math.tau
        cx, cy = C + math.cos(a) * 300, C + math.sin(a) * 300
        d.polygon([(cx, cy - 14), (cx + 9, cy), (cx, cy + 14), (cx - 9, cy)], fill=col)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.alpha_composite(layer.filter(ImageFilter.GaussianBlur(6)))
    out.alpha_composite(layer)
    return out


def background(inner, outer, ray_color, seed):
    base = radial(inner, outer).convert("RGBA")
    base.alpha_composite(rays(ray_color, seed=seed))
    light, dark = grain(seed)
    base.alpha_composite(dark)
    base.alpha_composite(light)
    base.alpha_composite(rune_ring(ray_color, seed=seed))
    return base


# ------------------------------------------------------------------ símbolos
def crescent(cx, cy, r, ang, thick=0.34):
    m = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(m)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    off = r * thick
    ox, oy = cx + math.cos(ang) * off, cy + math.sin(ang) * off
    r2 = r * 0.93
    d.ellipse((ox - r2, oy - r2, ox + r2, oy + r2), fill=0)
    return m


def sym_tajo():
    base = background((255, 120, 70), (60, 8, 12), (255, 200, 140), 11)
    m = Image.new("L", (S, S), 0)
    for k in range(3):
        a = k / 3 * math.tau
        cx, cy = C + math.cos(a) * 70, C + math.sin(a) * 70
        m = ImageChops.lighter(m, crescent(cx, cy, 300, a + 2.3, 0.3))
    hole = Image.new("L", (S, S), 0)
    ImageDraw.Draw(hole).ellipse((C - 70, C - 70, C + 70, C + 70), fill=255)
    m = ImageChops.lighter(m, hole)
    emboss(base, m, (255, 250, 230), (255, 120, 60), (255, 90, 40))
    sparkles(base, (255, 220, 160), seed=4)
    finish(base, "hab_tajo")


def sym_embestida():
    base = background((90, 220, 255), (6, 26, 70), (180, 240, 255), 12)
    polys = []
    # flecha doble hacia la derecha
    for dx in (-60, 150):
        polys.append([(C - 230 + dx, C - 260), (C - 40 + dx, C), (C - 230 + dx, C + 260), (C - 120 + dx, C + 260), (C + 70 + dx, C), (C - 120 + dx, C - 260)])
    # líneas de velocidad
    for i, y in enumerate((-180, -60, 60, 180)):
        x0 = C - 420 + (i % 2) * 60
        polys.append([(x0, C + y - 18), (C - 300 + (i % 2) * 40, C + y - 18), (C - 300 + (i % 2) * 40, C + y + 18), (x0, C + y + 18)])
    emboss(base, poly_mask(polys), (240, 255, 255), (60, 190, 255), (60, 200, 255))
    sparkles(base, (200, 250, 255), seed=5)
    finish(base, "hab_embestida")


def flame(cx, cy, w, h, seed):
    random.seed(seed)
    pts = []
    n = 26
    for i in range(n + 1):
        t = i / n
        a = math.pi * t
        # contorno de gota invertida con lenguas
        r = math.sin(a) ** 0.8
        tongue = 1 + 0.18 * math.sin(t * math.pi * 6) * (1 - abs(0.5 - t) * 2)
        x = cx + (t - 0.5) * 2 * w * r * tongue
        y = cy + h * 0.45 - (math.sin(a) ** 0.6) * h * 0.9 * (0.55 + 0.45 * math.cos((t - 0.5) * math.pi * 3) ** 2)
        pts.append((x, y))
    # base redonda
    for i in range(1, 14):
        a = math.pi * i / 14
        pts.append((cx + math.cos(a) * w, cy + h * 0.45 + math.sin(a) * w * 0.85))
    pts.append((cx, cy - h * 0.62))
    pts.sort(key=lambda p: math.atan2(p[1] - (cy + h * 0.2), p[0] - cx))
    return pts


def sym_furia():
    base = background((255, 150, 40), (70, 10, 4), (255, 210, 120), 13)
    outer = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(outer)
    # llama: tres lenguas (polígonos) y base redonda
    d.ellipse((C - 230, C - 20, C + 230, C + 360), fill=255)
    d.polygon([(C - 230, C + 160), (C - 120, C - 330), (C - 20, C - 60), (C + 60, C - 420), (C + 150, C - 80), (C + 210, C - 250), (C + 235, C + 170)], fill=255)
    outer = outer.filter(ImageFilter.GaussianBlur(22)).point(lambda v: 255 if v > 128 else 0)
    emboss(base, outer, (255, 240, 120), (255, 80, 20), (255, 110, 20))
    inner = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(inner)
    d.ellipse((C - 120, C + 90, C + 120, C + 320), fill=255)
    d.polygon([(C - 120, C + 210), (C - 40, C - 80), (C + 30, C + 60), (C + 90, C - 160), (C + 125, C + 210)], fill=255)
    inner = inner.filter(ImageFilter.GaussianBlur(16)).point(lambda v: 255 if v > 128 else 0)
    emboss(base, inner, (255, 255, 235), (255, 210, 80), (255, 230, 150), glow_r=20, glow_a=0.6)
    sparkles(base, (255, 210, 120), seed=6)
    finish(base, "hab_furia")


def sym_sismico():
    base = background((255, 190, 80), (60, 26, 6), (255, 220, 150), 14)
    random.seed(8)
    polys = []
    # estallido en el suelo
    star = []
    for i in range(24):
        a = i / 24 * math.tau
        r = 250 if i % 2 == 0 else 120
        star.append((C + math.cos(a) * r * 1.25, C + 130 + math.sin(a) * r * 0.55))
    polys.append(star)
    # grietas
    for a in (-2.6, -2.1, -1.0, -0.5, 0.0, math.pi):
        x, y = C, C + 130
        pts_l, pts_r = [], []
        for k in range(5):
            nx = x + math.cos(a) * 85 + random.uniform(-25, 25)
            ny = y + math.sin(a) * 40 + random.uniform(-14, 14) + 18
            w = 16 * (1 - k / 5) + 3
            pts_l.append((nx, ny - w))
            pts_r.append((nx, ny + w))
            x, y = nx, ny
        polys.append([(C, C + 120)] + pts_l + pts_r[::-1] + [(C, C + 140)])
    # puño que baja: flecha gruesa
    polys.append([(C - 110, C - 380), (C + 110, C - 380), (C + 110, C - 120), (C + 210, C - 120), (C, C + 70), (C - 210, C - 120), (C - 110, C - 120)])
    emboss(base, poly_mask(polys), (255, 250, 210), (255, 150, 30), (255, 160, 40))
    sparkles(base, (255, 230, 170), seed=7, n=24)
    finish(base, "hab_sismico")


def sword(cx, cy, length, ang, width=58):
    blade = [(cx - width / 2, cy - length * 0.62), (cx, cy - length * 0.72), (cx + width / 2, cy - length * 0.62), (cx + width / 2, cy + length * 0.12), (cx - width / 2, cy + length * 0.12)]
    guard = [(cx - width * 2.2, cy + length * 0.12), (cx + width * 2.2, cy + length * 0.12), (cx + width * 2.2, cy + length * 0.2), (cx - width * 2.2, cy + length * 0.2)]
    grip = [(cx - width * 0.34, cy + length * 0.2), (cx + width * 0.34, cy + length * 0.2), (cx + width * 0.34, cy + length * 0.4), (cx - width * 0.34, cy + length * 0.4)]
    pommel = [(cx + math.cos(a) * width * 0.6, cy + length * 0.45 + math.sin(a) * width * 0.6) for a in [i / 12 * math.tau for i in range(12)]]
    return [rot(p, ang, cx, cy) for p in (blade, guard, grip, pommel)]


def sym_tormenta():
    base = background((170, 130, 255), (22, 8, 60), (220, 200, 255), 15)
    # remolino detrás
    swirl = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(swirl)
    for k in range(3):
        a0 = k / 3 * 360
        d.arc((C - 390, C - 390, C + 390, C + 390), a0, a0 + 80, fill=255, width=40)
        d.arc((C - 300, C - 300, C + 300, C + 300), a0 + 50, a0 + 120, fill=255, width=26)
    emboss(base, swirl, (230, 220, 255), (140, 100, 255), (150, 110, 255), glow_r=26, glow_a=0.8)
    polys = sword(C, C + 40, 700, math.radians(40)) + sword(C, C + 40, 700, math.radians(-40))
    emboss(base, poly_mask(polys), (255, 255, 255), (150, 170, 210), (200, 180, 255))
    sparkles(base, (230, 210, 255), seed=8)
    finish(base, "hab_tormenta")


def shield_pts(cx, cy, w, h):
    pts = [(cx - w, cy - h * 0.55), (cx, cy - h * 0.68), (cx + w, cy - h * 0.55)]
    for i in range(1, 15):
        t = i / 15
        x = cx + w * (1 - t) ** 0.7
        y = cy - h * 0.55 + (h * 1.2) * t
        pts.append((x, y))
    pts.append((cx, cy + h * 0.7))
    for i in range(14, 0, -1):
        t = i / 15
        pts.append((cx - w * (1 - t) ** 0.7, cy - h * 0.55 + (h * 1.2) * t))
    return pts


def sym_coraza():
    base = background((255, 210, 90), (60, 34, 4), (255, 235, 170), 16)
    outer = poly_mask([shield_pts(C, C, 290, 600)])
    emboss(base, outer, (255, 245, 190), (220, 140, 20), (255, 190, 60))
    inner = poly_mask([shield_pts(C, C + 10, 200, 430)])
    emboss(base, inner, (90, 160, 255), (20, 50, 140), (120, 180, 255), outline=(60, 34, 4), glow_r=12, glow_a=0.4)
    gem = poly_mask([[(C, C - 150), (C + 95, C), (C, C + 160), (C - 95, C)]])
    emboss(base, gem, (255, 255, 255), (130, 220, 255), (170, 230, 255), glow_r=30)
    sparkles(base, (255, 240, 190), seed=9)
    finish(base, "hab_coraza")


def sym_ataque():
    base = background((120, 180, 255), (10, 22, 60), (200, 225, 255), 17)
    emboss(base, poly_mask(sword(C, C + 30, 780, math.radians(45), 70)), (255, 255, 255), (150, 175, 220), (130, 190, 255))
    sparkles(base, (210, 230, 255), seed=10)
    finish(base, "hab_ataque")


def potion(name, liquid_light, liquid, bg_in, bg_out, glow):
    base = background(bg_in, bg_out, liquid_light, 18 if "hp" in name else 19)
    glass = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(glass)
    d.ellipse((C - 280, C - 120, C + 280, C + 420), fill=255)
    d.rectangle((C - 95, C - 330, C + 95, C - 60), fill=255)
    d.rounded_rectangle((C - 140, C - 360, C + 140, C - 300), radius=20, fill=255)
    emboss(base, glass, (225, 240, 255), (120, 140, 170), (255, 255, 255), glow_r=16, glow_a=0.35)
    liq = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(liq)
    d.ellipse((C - 240, C - 80, C + 240, C + 380), fill=255)
    d.rectangle((C - 240, C - 80, C + 240, C + 60), fill=0)
    d.chord((C - 240, C - 80, C + 240, C + 380), 0, 360, fill=None)
    liq2 = Image.new("L", (S, S), 0)
    ImageDraw.Draw(liq2).ellipse((C - 240, C - 80, C + 240, C + 380), fill=255)
    cutter = Image.new("L", (S, S), 0)
    ImageDraw.Draw(cutter).rectangle((0, C + 40, S, S), fill=255)
    liq = ImageChops.multiply(liq2, cutter)
    emboss(base, liq, liquid_light, liquid, glow, outline=(30, 20, 40), glow_r=40)
    cork = poly_mask([[(C - 80, C - 470), (C + 80, C - 470), (C + 95, C - 360), (C - 95, C - 360)]])
    emboss(base, cork, (220, 170, 110), (120, 70, 30), (0, 0, 0), glow_r=4, glow_a=0.0)
    # brillo del cristal
    hl = poly_mask([], ellipses=[(C - 200, C - 40, C - 120, C + 200)])
    hl_l = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    hl_l.putalpha(hl.filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.55)))
    base.alpha_composite(hl_l)
    # burbujas
    sparkles(base, liquid_light, n=10, seed=21, r=(10, 20))
    finish(base, name)


def frame(name, round_):
    """Marco dorado con bisel (centro transparente), para poner encima del icono."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    m_out = Image.new("L", (S, S), 0)
    m_in = Image.new("L", (S, S), 0)
    if round_:
        ImageDraw.Draw(m_out).ellipse((8, 8, S - 8, S - 8), fill=255)
        ImageDraw.Draw(m_in).ellipse((70, 70, S - 70, S - 70), fill=255)
    else:
        ImageDraw.Draw(m_out).rounded_rectangle((8, 8, S - 8, S - 8), radius=170, fill=255)
        ImageDraw.Draw(m_in).rounded_rectangle((66, 66, S - 66, S - 66), radius=120, fill=255)
    ring = ImageChops.subtract(m_out, m_in)
    gold = vgrad((255, 240, 170), (150, 90, 20)).convert("RGBA")
    # bandas del bisel: claro arriba-izquierda, oscuro abajo-derecha
    gold.putalpha(ring)
    img.alpha_composite(gold)
    shade = ImageChops.subtract(ring, ImageChops.offset(ring, -14, -14)).filter(ImageFilter.GaussianBlur(4))
    sl = Image.new("RGBA", (S, S), (60, 30, 0, 0))
    sl.putalpha(shade.point(lambda v: int(v * 0.8)))
    img.alpha_composite(sl)
    light = ImageChops.subtract(ring, ImageChops.offset(ring, 14, 14)).filter(ImageFilter.GaussianBlur(4))
    ll = Image.new("RGBA", (S, S), (255, 255, 230, 0))
    ll.putalpha(light.point(lambda v: int(v * 0.9)))
    img.alpha_composite(ll)
    # grabado: muescas a lo largo del marco, y gemas azules engastadas
    eng = ImageDraw.Draw(img)
    if round_:
        for i in range(48):
            a = i / 48 * math.tau
            eng.line((C + math.cos(a) * (S / 2 - 52), C + math.sin(a) * (S / 2 - 52), C + math.cos(a) * (S / 2 - 30), C + math.sin(a) * (S / 2 - 30)), fill=(120, 70, 10, 150), width=4)
        gems = [(C + math.cos(a) * (S / 2 - 39), C + math.sin(a) * (S / 2 - 39)) for a in (-math.pi / 2, 0, math.pi / 2, math.pi)]
    else:
        for i in range(1, 12):
            t = 66 + i * (S - 132) / 12
            for (x0, y0, x1, y1) in ((t, 24, t, 50), (t, S - 50, t, S - 24), (24, t, 50, t), (S - 50, t, S - 24, t)):
                eng.line((x0, y0, x1, y1), fill=(120, 70, 10, 140), width=4)
        gems = [(70, 70), (S - 70, 70), (70, S - 70), (S - 70, S - 70)]
    for gx, gy in gems:
        gl = Image.new("L", (S, S), 0)
        ImageDraw.Draw(gl).ellipse((gx - 40, gy - 40, gx + 40, gy + 40), fill=255)
        glow = Image.new("RGBA", (S, S), (90, 200, 255, 0))
        glow.putalpha(gl.filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.8)))
        img.alpha_composite(glow)
        gm = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        dd = ImageDraw.Draw(gm)
        dd.ellipse((gx - 30, gy - 30, gx + 30, gy + 30), fill=(70, 40, 6, 255))
        dd.ellipse((gx - 23, gy - 23, gx + 23, gy + 23), fill=(40, 140, 230, 255))
        dd.ellipse((gx - 16, gy - 18, gx + 8, gy + 2), fill=(170, 230, 255, 255))
        dd.ellipse((gx - 10, gy - 14, gx - 2, gy - 6), fill=(255, 255, 255, 255))
        img.alpha_composite(gm)
    # línea fina interior oscura (separa el marco del icono)
    inner_line = ImageChops.subtract(m_in.filter(ImageFilter.MaxFilter(13)), m_in)
    il = Image.new("RGBA", (S, S), (40, 22, 4, 0))
    il.putalpha(inner_line)
    img.alpha_composite(il)
    img.resize((FINAL, FINAL), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))
    print("  ", name)


def sym_correr():
    base = background((120, 230, 160), (6, 40, 26), (190, 255, 210), 31)
    # bota alada
    boot = [(C - 150, C - 300), (C + 30, C - 300), (C + 40, C + 60), (C + 300, C + 150), (C + 320, C + 250), (C - 170, C + 250), (C - 175, C + 60)]
    sole = [(C - 190, C + 250), (C + 330, C + 250), (C + 320, C + 300), (C - 190, C + 300)]
    cuff = [(C - 175, C - 330), (C + 50, C - 330), (C + 50, C - 260), (C - 175, C - 260)]
    emboss(base, poly_mask([boot, sole, cuff]), (230, 255, 240), (40, 170, 110), (90, 255, 160))
    wing = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(wing)
    # plumas en abanico que salen del talón hacia atrás y arriba
    hx, hy = C - 150, C - 120
    for k in range(5):
        a = math.radians(200 + k * 14)
        ln = 330 - k * 35
        w = 46 - k * 4
        tip = (hx + math.cos(a) * ln, hy + math.sin(a) * ln)
        nx, ny = -math.sin(a) * w, math.cos(a) * w
        mid = (hx + math.cos(a) * ln * 0.55, hy + math.sin(a) * ln * 0.55)
        d.polygon([(hx, hy), (mid[0] + nx, mid[1] + ny), tip, (mid[0] - nx * 0.4, mid[1] - ny * 0.4)], fill=255)
    emboss(base, wing, (255, 255, 255), (180, 220, 240), (200, 255, 230), glow_r=24)
    for i, y in enumerate((C + 40, C + 130, C + 210)):
        line = poly_mask([[(C - 470 + i * 40, y - 12), (C - 230, y - 12), (C - 230, y + 12), (C - 470 + i * 40, y + 12)]])
        emboss(base, line, (230, 255, 240), (120, 230, 170), (120, 255, 180), glow_r=14, glow_a=0.6)
    sparkles(base, (200, 255, 220), seed=32)
    finish(base, "btn_correr")


def chevrons(up, n, y0, gap):
    polys = []
    for k in range(n):
        y = y0 + k * gap
        sg = -1 if up else 1
        polys.append([(C - 260, y), (C, y + sg * 230), (C + 260, y), (C + 260, y - sg * 110), (C, y + sg * 120), (C - 260, y - sg * 110)])
    return polys


def sym_saltar():
    base = background((110, 190, 255), (8, 22, 66), (190, 230, 255), 33)
    ring = Image.new("L", (S, S), 0)
    ImageDraw.Draw(ring).ellipse((C - 300, C + 260, C + 300, C + 380), outline=255, width=26)
    emboss(base, ring, (220, 240, 255), (90, 160, 255), (100, 180, 255), glow_r=20)
    emboss(base, poly_mask(chevrons(True, 2, C + 110, -230)), (255, 255, 255), (80, 170, 255), (100, 200, 255))
    sparkles(base, (210, 235, 255), seed=34)
    finish(base, "btn_saltar")


def sym_agacharse():
    base = background((150, 140, 200), (16, 12, 44), (210, 200, 255), 35)
    emboss(base, poly_mask(chevrons(False, 2, C - 260, 210)), (255, 255, 255), (140, 120, 230), (170, 150, 255))
    bar = poly_mask([[(C - 300, C + 300), (C + 300, C + 300), (C + 300, C + 340), (C - 300, C + 340)]])
    emboss(base, bar, (230, 220, 255), (140, 120, 230), (170, 150, 255), glow_r=16)
    sparkles(base, (220, 210, 255), seed=36)
    finish(base, "btn_agacharse")


def sym_defensa():
    base = background((110, 170, 255), (8, 18, 60), (200, 225, 255), 37)
    emboss(base, poly_mask([shield_pts(C, C, 300, 620)]), (235, 240, 255), (130, 150, 190), (130, 190, 255))
    inner = poly_mask([shield_pts(C, C + 10, 220, 450)])
    emboss(base, inner, (90, 150, 255), (16, 40, 120), (100, 160, 255), outline=(20, 30, 60), glow_r=10, glow_a=0.3)
    cross = poly_mask([[(C - 30, C - 200), (C + 30, C - 200), (C + 30, C + 230), (C - 30, C + 230)], [(C - 150, C - 50), (C + 150, C - 50), (C + 150, C + 10), (C - 150, C + 10)]])
    emboss(base, cross, (255, 245, 200), (220, 160, 40), (255, 210, 100), glow_r=18)
    sparkles(base, (210, 230, 255), seed=38)
    finish(base, "btn_defensa")


def sym_esquivar():
    base = background((120, 240, 230), (4, 40, 50), (190, 255, 250), 39)
    arc = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(arc)
    d.arc((C - 330, C - 260, C + 330, C + 400), 190, 350, fill=255, width=90)
    d.polygon([(C + 250, C - 160), (C + 430, C + 40), (C + 180, C + 70)], fill=255)
    emboss(base, arc, (240, 255, 255), (40, 200, 200), (80, 255, 240))
    ghost = Image.new("L", (S, S), 0)
    ImageDraw.Draw(ghost).arc((C - 330, C - 120, C + 330, C + 540), 200, 300, fill=150, width=40)
    emboss(base, ghost, (180, 255, 250), (60, 180, 190), (80, 220, 220), glow_r=20, glow_a=0.5)
    sparkles(base, (200, 255, 250), seed=40)
    finish(base, "btn_esquivar")


def sym_telefono():
    base = background((120, 160, 255), (10, 14, 50), (200, 210, 255), 41)
    body = Image.new("L", (S, S), 0)
    ImageDraw.Draw(body).rounded_rectangle((C - 200, C - 360, C + 200, C + 360), radius=70, fill=255)
    emboss(base, body, (90, 100, 130), (20, 22, 34), (120, 160, 255), outline=(10, 10, 20))
    screen = Image.new("L", (S, S), 0)
    ImageDraw.Draw(screen).rounded_rectangle((C - 160, C - 290, C + 160, C + 270), radius=34, fill=255)
    emboss(base, screen, (130, 200, 255), (40, 70, 200), (90, 150, 255), outline=(10, 10, 20), glow_r=14, glow_a=0.5)
    apps = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(apps)
    for r_ in range(3):
        for c_ in range(3):
            x, y = C - 105 + c_ * 105, C - 200 + r_ * 115
            d.rounded_rectangle((x - 36, y - 36, x + 36, y + 36), radius=14, fill=255)
    emboss(base, apps, (255, 255, 255), (190, 220, 255), (200, 230, 255), outline=(20, 30, 90), glow_r=8, glow_a=0.4)
    emboss(base, poly_mask([], ellipses=[(C - 26, C + 296, C + 26, C + 342)]), (200, 200, 220), (90, 90, 110), (0, 0, 0), glow_r=2, glow_a=0)
    finish(base, "btn_telefono")


def sym_inventario():
    base = background((230, 170, 90), (50, 22, 6), (255, 220, 160), 43)
    body = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((C - 270, C - 190, C + 270, C + 360), radius=90, fill=255)
    d.arc((C - 130, C - 380, C + 130, C - 120), 180, 360, fill=255, width=46)
    emboss(base, body, (230, 160, 90), (120, 60, 20), (255, 180, 90))
    flap = Image.new("L", (S, S), 0)
    ImageDraw.Draw(flap).rounded_rectangle((C - 270, C - 190, C + 270, C + 40), radius=90, fill=255)
    emboss(base, flap, (200, 130, 70), (100, 50, 16), (0, 0, 0), glow_r=4, glow_a=0)
    pocket = Image.new("L", (S, S), 0)
    ImageDraw.Draw(pocket).rounded_rectangle((C - 170, C + 120, C + 170, C + 320), radius=40, fill=255)
    emboss(base, pocket, (210, 140, 80), (110, 56, 18), (0, 0, 0), glow_r=4, glow_a=0)
    buckle = Image.new("L", (S, S), 0)
    ImageDraw.Draw(buckle).rounded_rectangle((C - 50, C - 10, C + 50, C + 90), radius=14, fill=255)
    emboss(base, buckle, (255, 245, 180), (220, 160, 40), (255, 220, 120), glow_r=16)
    sparkles(base, (255, 230, 170), seed=44)
    finish(base, "btn_inventario")


def sym_hablar():
    base = background((130, 210, 255), (8, 30, 64), (200, 240, 255), 45)
    bub = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(bub)
    d.ellipse((C - 360, C - 280, C + 360, C + 220), fill=255)
    d.polygon([(C - 220, C + 120), (C - 300, C + 360), (C - 40, C + 190)], fill=255)
    for k in (-1, 0, 1):
        d.ellipse((C + k * 180 - 50, C - 80, C + k * 180 + 50, C + 20), fill=0)
    emboss(base, bub, (255, 255, 255), (150, 200, 240), (140, 210, 255))
    sparkles(base, (210, 240, 255), seed=46)
    finish(base, "btn_hablar")


def sym_interactuar():
    base = background((255, 210, 110), (50, 30, 6), (255, 235, 170), 47)
    star = []
    for i in range(8):
        a = i / 8 * math.tau - math.pi / 2
        r = 380 if i % 2 == 0 else 110
        star.append((C + math.cos(a) * r, C + math.sin(a) * r))
    emboss(base, poly_mask([star]), (255, 255, 230), (255, 180, 40), (255, 210, 90))
    ring = Image.new("L", (S, S), 0)
    ImageDraw.Draw(ring).ellipse((C - 200, C - 200, C + 200, C + 200), outline=255, width=22)
    emboss(base, ring, (255, 250, 220), (230, 170, 50), (255, 220, 120), glow_r=18, glow_a=0.6)
    sparkles(base, (255, 240, 190), seed=48, n=26)
    finish(base, "btn_interactuar")


def sym_base():
    """Medallón vacío para los botones sin icono pintado: su icono de siempre va encima."""
    base = background((60, 100, 190), (6, 10, 34), (150, 190, 255), 49)
    finish(base, "btn_base")


if __name__ == "__main__":
    print("iconos de habilidades:")
    sym_tajo()
    sym_embestida()
    sym_furia()
    sym_sismico()
    sym_tormenta()
    sym_coraza()
    sym_ataque()
    potion("pocion_hp", (255, 160, 160), (200, 20, 40), (150, 30, 40), (40, 4, 10), (255, 60, 80))
    potion("pocion_mp", (170, 220, 255), (30, 90, 230), (40, 80, 170), (6, 14, 50), (80, 160, 255))
    for f in (sym_correr, sym_saltar, sym_agacharse, sym_defensa, sym_esquivar, sym_telefono, sym_inventario, sym_hablar, sym_interactuar, sym_base):
        f()
    frame("marco_hab", False)
    frame("marco_hab_redondo", True)
