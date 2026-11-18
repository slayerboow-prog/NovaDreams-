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


def background(inner, outer, ray_color, seed):
    base = radial(inner, outer).convert("RGBA")
    base.alpha_composite(rays(ray_color, seed=seed))
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
    # línea fina interior oscura (separa el marco del icono)
    inner_line = ImageChops.subtract(m_in.filter(ImageFilter.MaxFilter(13)), m_in)
    il = Image.new("RGBA", (S, S), (40, 22, 4, 0))
    il.putalpha(inner_line)
    img.alpha_composite(il)
    img.resize((FINAL, FINAL), Image.LANCZOS).save(os.path.join(OUT, name + ".png"))
    print("  ", name)


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
    frame("marco_hab", False)
    frame("marco_hab_redondo", True)
