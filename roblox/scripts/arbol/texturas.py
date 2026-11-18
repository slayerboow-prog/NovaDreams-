"""Las TEXTURAS del Árbol Ancestral (17-11-2026): corteza y hojas, que se repiten sin costuras (las mallas de
scripts/arbol/arbol_blender.py llevan UV cilíndricas). Cada una con su mapa de color y su mapa de relieve (normal).

Uso (desde la carpeta roblox/):  python3 scripts/arbol/texturas.py
Salida: assets/arbol/tex/corteza_color.png, corteza_normal.png, hojas_color.png, hojas_normal.png (1024 px)
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "arbol", "tex")
os.makedirs(OUT, exist_ok=True)
S = 1024
random.seed(7)


def tile_noise(scale, octaves=4, seed=0):
    """Ruido suave que se repite (suma de senos con fases al azar en una rejilla periódica)."""
    rnd = random.Random(seed)
    img = Image.new("L", (S, S))
    px = img.load()
    waves = []
    for o in range(octaves):
        for _ in range(6):
            kx = rnd.randint(1, scale * (2 ** o))
            ky = rnd.randint(-scale * (2 ** o), scale * (2 ** o))
            waves.append((kx, ky, rnd.uniform(0, math.tau), 0.5 ** o))
    norm = sum(w[3] for w in waves)
    for y in range(S):
        for x in range(S):
            v = 0.0
            for kx, ky, ph, amp in waves:
                v += math.sin((kx * x + ky * y) / S * math.tau + ph) * amp
            px[x, y] = int(128 + 127 * v / norm)
    return img


def normal_from_height(h, strength=3.0):
    w, hgt = h.size
    src = h.load()
    out = Image.new("RGB", (w, hgt))
    dst = out.load()
    for y in range(hgt):
        for x in range(w):
            l = src[(x - 1) % w, y]
            r = src[(x + 1) % w, y]
            u = src[x, (y - 1) % hgt]
            d = src[x, (y + 1) % hgt]
            dx = (r - l) / 255.0 * strength
            dy = (d - u) / 255.0 * strength
            nz = 1.0
            ln = math.sqrt(dx * dx + dy * dy + nz * nz)
            dst[x, y] = (int((-dx / ln * 0.5 + 0.5) * 255), int((dy / ln * 0.5 + 0.5) * 255), int((nz / ln * 0.5 + 0.5) * 255))
    return out


# ------------------------------------------------------------------ corteza: surcos verticales, grietas y musgo
print("corteza…")
h = Image.new("L", (S, S), 128)
d = ImageDraw.Draw(h)
# surcos: franjas verticales que ondulan (el tronco: v sube por el tronco)
for i in range(70):
    x0 = random.uniform(0, S)
    w = random.uniform(5, 16)
    shade = random.randint(30, 80)
    pts = []
    for y in range(0, S + 32, 32):
        pts.append((x0 + math.sin(y / S * math.tau * random.choice((1, 2)) + i) * random.uniform(6, 22), y))
    for dx in (-S, 0, S):
        d.line([(p[0] + dx, p[1]) for p in pts], fill=shade, width=int(w))
# placas de corteza (más claras) entre surcos
for i in range(320):
    x = random.uniform(0, S)
    y = random.uniform(0, S)
    ww, hh = random.uniform(7, 15), random.uniform(70, 200)
    for dx in (-S, 0, S):
        for dy in (-S, 0, S):
            d.ellipse([x - ww / 2 + dx, y - hh / 2 + dy, x + ww / 2 + dx, y + hh / 2 + dy], fill=random.randint(140, 175))
h = h.filter(ImageFilter.GaussianBlur(2.2))
n = tile_noise(3, 3, 11).resize((S, S))
h = Image.blend(h, n, 0.25)
color = Image.new("RGB", (S, S))
cp = color.load()
hp = h.load()
moss = tile_noise(2, 3, 23)
mp = moss.load()
for y in range(S):
    for x in range(S):
        v = hp[x, y] / 255.0
        m = max(0.0, (mp[x, y] / 255.0 - 0.62) * 3.2)
        r = 70 + 95 * v
        g = 48 + 70 * v
        b = 32 + 45 * v
        r, g, b = r * (1 - m) + 64 * m, g * (1 - m) + 110 * m, b * (1 - m) + 52 * m
        cp[x, y] = (int(min(255, r)), int(min(255, g)), int(min(255, b)))
color.save(os.path.join(OUT, "corteza_color.png"))
normal_from_height(h, 4.0).save(os.path.join(OUT, "corteza_normal.png"))

# ------------------------------------------------------------------ hojas: muchas hojas pequeñas en varios verdes
print("hojas…")
col = Image.new("RGB", (S, S), (36, 78, 40))
hh = Image.new("L", (S, S), 60)
dc = ImageDraw.Draw(col)
dh = ImageDraw.Draw(hh)
greens = [(52, 120, 58), (70, 146, 66), (88, 164, 76), (44, 104, 60), (110, 178, 86), (60, 138, 96)]
for i in range(5200):
    x = random.uniform(0, S)
    y = random.uniform(0, S)
    L = random.uniform(16, 30)
    W = L * random.uniform(0.35, 0.5)
    a = random.uniform(0, math.tau)
    g = random.choice(greens)
    light = random.uniform(0.75, 1.2)
    c = tuple(int(min(255, ch * light)) for ch in g)
    pts = []
    for k in range(10):
        t = k / 9 * math.pi
        px = math.cos(t) * L / 2
        py = math.sin(t) * W / 2
        pts.append((px, py))
    for k in range(10):
        t = math.pi + k / 9 * math.pi
        pts.append((math.cos(t) * L / 2, math.sin(t) * W / 2))
    rot = [(x + px * math.cos(a) - py * math.sin(a), y + px * math.sin(a) + py * math.cos(a)) for px, py in pts]
    for dx in (-S, 0, S):
        for dy in (-S, 0, S):
            poly = [(p[0] + dx, p[1] + dy) for p in rot]
            dc.polygon(poly, fill=c)
            dh.polygon(poly, fill=int(110 + 120 * (light - 0.75) / 0.45))
col = col.filter(ImageFilter.GaussianBlur(0.6))
hh = hh.filter(ImageFilter.GaussianBlur(1.2))
col.save(os.path.join(OUT, "hojas_color.png"))
normal_from_height(hh, 3.0).save(os.path.join(OUT, "hojas_normal.png"))
print("listo:", os.path.abspath(OUT))
