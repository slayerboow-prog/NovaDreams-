"""Maquetas del HUD de vuelo CON los sprites (assets/hud), en las zonas de verdad (UI/ShipHudLayout).

Componen cada zona como UI/AirCombatHud cuando hay ids (shared/HudTextureIds): marcos 9-slice, arcos
de los atlas teñidos, iconos del atlas, radar con barrido, brújula… No son capturas de Roblox (allí
la letra es otra), pero usan las mismas imágenes, posiciones y tamaños.

    lune run scripts/hud/hud-dump.luau > /tmp/hud.json
    python3 -I scripts/hud/hud_fidelidad.py /tmp/hud.json docs/espacio-aaa

Salen hud-fidelidad-{nave,avion}-{1920x1080,844x390}.jpg y hud-fidelidad-comparacion.jpg (al lado de
docs/espacio-aaa/referencia-hud.png).
"""
import json
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
HUD = os.path.join(ROOT, "assets", "hud")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_R = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
MANIFEST = json.load(open(os.path.join(HUD, "manifest.json"), encoding="utf-8"))

CYAN = (110, 230, 255)
EDGE = (70, 200, 255)
WHITE = (235, 248, 255)
MUTED = (140, 175, 205)
ORANGE = (255, 150, 40)
RED = (255, 70, 70)
GOLD = (255, 205, 70)
GREEN = (120, 240, 170)
VIOLET = (200, 130, 255)
MONEY = (120, 240, 140)
G_SHIELD = (90, 200, 255)
G_WARN = (255, 160, 50)
G_DANGER = (255, 64, 56)

_cache = {}


def sprite(name):
    if name not in _cache:
        _cache[name] = Image.open(os.path.join(HUD, name + ".png")).convert("RGBA")
    return _cache[name]


def tint(img, color, alpha=1.0):
    r, g, b, a = img.split()
    r = r.point(lambda v: v * color[0] // 255)
    g = g.point(lambda v: v * color[1] // 255)
    b = b.point(lambda v: v * color[2] // 255)
    if alpha < 1:
        a = a.point(lambda v: int(v * alpha))
    return Image.merge("RGBA", (r, g, b, a))


def font(size, bold=True):
    return ImageFont.truetype(FONT if bold else FONT_R, max(6, int(round(size))))


class Canvas:
    def __init__(self, img, scale):
        self.img = img
        self.k = scale
        self.layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.layer)

    def p(self, v):
        return v * self.k

    def paste(self, im, x, y, w, h, rot=0):
        w, h = max(1, int(round(self.p(w)))), max(1, int(round(self.p(h))))
        im = im.resize((w, h), Image.LANCZOS)
        if rot:
            im = im.rotate(-rot, resample=Image.BICUBIC, expand=False)
        self.layer.alpha_composite(im, (int(round(self.p(x))), int(round(self.p(y)))))

    def nine(self, name, x, y, w, h, color=None):
        """9-slice como Roblox (con UIScale: las esquinas también escalan)"""
        f = MANIFEST["Frames"][name]
        pad = f["Pad"]
        x0, y0, x1, y1 = f["Slice"]
        src = sprite(name)
        if color:
            src = tint(src, color)
        W, H = src.size
        X, Y = self.p(x - pad), self.p(y - pad)
        DW, DH = self.p(w + 2 * pad), self.p(h + 2 * pad)
        k = self.k
        cols = [(0, x0, 0, x0 * k), (x0, x1, x0 * k, DW - (W - x1) * k), (x1, W, DW - (W - x1) * k, DW)]
        rows = [(0, y0, 0, y0 * k), (y0, y1, y0 * k, DH - (H - y1) * k), (y1, H, DH - (H - y1) * k, DH)]
        for sx0, sx1, dx0, dx1 in cols:
            for sy0, sy1, dy0, dy1 in rows:
                dw, dh = int(round(dx1)) - int(round(dx0)), int(round(dy1)) - int(round(dy0))
                if dw <= 0 or dh <= 0:
                    continue
                piece = src.crop((sx0, sy0, sx1, sy1)).resize((dw, dh), Image.LANCZOS)
                self.layer.alpha_composite(piece, (int(round(X + dx0)), int(round(Y + dy0))))

    def icon(self, name, x, y, size, color=None, alpha=1.0):
        names = MANIFEST["Icon"]["Names"]
        i = names.index(name)
        s = MANIFEST["Icon"]["Size"]
        cell = sprite("iconos").crop(((i % 8) * s, (i // 8) * s, (i % 8 + 1) * s, (i // 8 + 1) * s))
        if color or alpha < 1:
            cell = tint(cell, color or (255, 255, 255), alpha)
        self.paste(cell, x, y, size, size)

    def arc(self, name, k, x, y, w, h, color):
        A = MANIFEST["Arc"]
        idx = max(0, min(A["Frames"] - 1, int(math.floor(k * (A["Frames"] - 1) + 0.5))))
        fw, fh = A["FrameW"], A["FrameH"]
        cell = sprite(name).crop(((idx % A["Cols"]) * fw, (idx // A["Cols"]) * fh, (idx % A["Cols"] + 1) * fw, (idx // A["Cols"] + 1) * fh))
        self.paste(tint(cell, color), x, y, w, h)

    def text(self, x, y, s, size, color=WHITE, anchor="la", bold=True, glow=False):
        f = font(self.p(size), bold)
        pos = (self.p(x), self.p(y))
        if glow:
            g = Image.new("RGBA", self.layer.size, (0, 0, 0, 0))
            ImageDraw.Draw(g).text(pos, s, font=f, fill=EDGE + (200,), anchor=anchor)
            self.layer.alpha_composite(g.filter(ImageFilter.GaussianBlur(max(1, self.p(4)))))
        self.d.text(pos, s, font=f, fill=color + (255,), anchor=anchor, stroke_width=max(1, int(self.p(1.2))), stroke_fill=(0, 10, 20, 150))

    def fit(self, x, y, s, size, width, color=WHITE, anchor="la", bold=True):
        while size > 7 and font(self.p(size), bold).getlength(s) > self.p(width):
            size -= 0.5
        self.text(x, y, s, size, color, anchor, bold)

    def bar(self, x, y, w, h, frac, color):
        self.d.rounded_rectangle([self.p(x), self.p(y), self.p(x + w), self.p(y + h)], radius=self.p(h / 2), fill=(10, 20, 36, 230), outline=color + (90,))
        if frac > 0:
            fill = Image.new("RGBA", (max(1, int(self.p(w * frac))), max(1, int(self.p(h)))), color + (255,))
            m = Image.new("L", fill.size, 0)
            ImageDraw.Draw(m).rounded_rectangle([0, 0, fill.size[0] - 1, fill.size[1] - 1], radius=self.p(h / 2), fill=255)
            g = Image.new("RGBA", self.layer.size, (0, 0, 0, 0))
            g.paste(fill, (int(self.p(x)), int(self.p(y))), m)
            self.layer.alpha_composite(g.filter(ImageFilter.GaussianBlur(self.p(3))))
            self.layer.paste(fill, (int(self.p(x)), int(self.p(y))), m)

    def chip(self, x, y, w, h, s, size=12):
        self.d.rounded_rectangle([self.p(x), self.p(y), self.p(x + w), self.p(y + h)], radius=self.p(5), fill=(20, 40, 70, 220), outline=EDGE + (170,))
        self.fit(x + w / 2, y + h / 2, s, size, w - 4, WHITE, "mm")

    def finish(self):
        self.img.alpha_composite(self.layer)
        self.layer = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.layer)


# ---------------------------------------------------------------------------
# Fondos (espacio para la nave; cielo y campo para el avión)
# ---------------------------------------------------------------------------


def space_bg(w, h, seed=7):
    img = Image.new("RGB", (w, h), (4, 8, 22))
    d = ImageDraw.Draw(img)
    for y in range(h):
        k = y / h
        d.line([(0, y), (w, y)], fill=(int(6 + 18 * k), int(10 + 16 * k), int(34 + 26 * (1 - k))))
    rnd = random.Random(seed)
    neb = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    nd = ImageDraw.Draw(neb)
    for _ in range(16):
        cx, cy = rnd.uniform(0.35, 1) * w, rnd.uniform(0, 0.55) * h
        r = rnd.uniform(0.08, 0.26) * w
        col = rnd.choice([(150, 80, 230, 46), (60, 170, 230, 50), (80, 110, 240, 52)])
        nd.ellipse([cx - r, cy - r * 0.55, cx + r, cy + r * 0.55], fill=col)
    img.paste(neb.filter(ImageFilter.GaussianBlur(w / 28)), (0, 0), neb.filter(ImageFilter.GaussianBlur(w / 28)))
    d = ImageDraw.Draw(img)
    for _ in range(int(w * h / 1500)):
        x, y = rnd.uniform(0, w), rnd.uniform(0, h)
        b = rnd.randint(110, 255)
        d.point((x, y), fill=(b, b, b))
    # planeta a la izquierda
    pr = h * 0.62
    pc = (-pr * 0.32, h * 0.62)
    pl = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pl)
    pd.ellipse([pc[0] - pr * 1.05, pc[1] - pr * 1.05, pc[0] + pr * 1.05, pc[1] + pr * 1.05], fill=(120, 190, 255, 60))
    pl = pl.filter(ImageFilter.GaussianBlur(h / 60))
    pd = ImageDraw.Draw(pl)
    pd.ellipse([pc[0] - pr, pc[1] - pr, pc[0] + pr, pc[1] + pr], fill=(40, 70, 120, 255))
    pd.ellipse([pc[0] - pr * 0.96, pc[1] - pr * 1.0, pc[0] + pr * 0.9, pc[1] + pr * 0.92], fill=(60, 100, 160, 255))
    img.paste(pl, (0, 0), pl)
    # asteroides
    d = ImageDraw.Draw(img)
    for _ in range(26):
        x, y = rnd.uniform(0.05, 0.98) * w, rnd.uniform(0.35, 0.95) * h
        r = rnd.uniform(0.004, 0.02) * w
        pts = [(x + math.cos(a) * r * rnd.uniform(0.7, 1.1), y + math.sin(a) * r * rnd.uniform(0.7, 1.1)) for a in [i / 7 * math.tau for i in range(7)]]
        d.polygon(pts, fill=(rnd.randint(50, 80), rnd.randint(46, 66), rnd.randint(50, 70)))
    # la nave por detrás (tres motores encendidos)
    sx, sy, s = w * 0.5, h * 0.78, h / 520
    body = (150, 160, 178)
    dark = (60, 66, 80)
    d.polygon([(sx - 20 * s, sy), (sx - 150 * s, sy + 34 * s), (sx - 140 * s, sy + 44 * s), (sx - 12 * s, sy + 22 * s)], fill=dark)
    d.polygon([(sx + 20 * s, sy), (sx + 150 * s, sy + 34 * s), (sx + 140 * s, sy + 44 * s), (sx + 12 * s, sy + 22 * s)], fill=dark)
    for x, top, wd in ((-36, -40, 20), (36, -40, 20), (0, -90, 26)):
        d.polygon([(sx + x * s, sy + top * s), (sx + (x - wd) * s, sy + 30 * s), (sx + (x + wd) * s, sy + 30 * s)], fill=body)
    gl = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gl)
    for x in (-36, 0, 36):
        r = 15 * s
        gd.ellipse([sx + x * s - r * 2, sy + 30 * s - r * 2, sx + x * s + r * 2, sy + 30 * s + r * 2], fill=(90, 170, 255, 160))
    gl = gl.filter(ImageFilter.GaussianBlur(10 * s))
    img.paste(gl, (0, 0), gl)
    d = ImageDraw.Draw(img)
    for x in (-36, 0, 36):
        r = 11 * s
        d.ellipse([sx + x * s - r, sy + 30 * s - r, sx + x * s + r, sy + 30 * s + r], fill=(220, 240, 255))
    return img.convert("RGBA")


def sky_bg(w, h, seed=3):
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    horizon = int(h * 0.52)
    for y in range(horizon):
        k = y / horizon
        d.line([(0, y), (w, y)], fill=(int(70 + 90 * k), int(130 + 80 * k), int(200 + 40 * k)))
    for y in range(horizon, h):
        k = (y - horizon) / (h - horizon)
        d.line([(0, y), (w, y)], fill=(int(96 - 30 * k), int(130 - 40 * k), int(80 - 30 * k)))
    rnd = random.Random(seed)
    cl = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cl)
    for _ in range(18):
        cx, cy = rnd.uniform(0, w), rnd.uniform(0.05, 0.45) * h
        r = rnd.uniform(0.03, 0.09) * w
        cd.ellipse([cx - r, cy - r * 0.35, cx + r, cy + r * 0.35], fill=(255, 255, 255, 130))
    cl = cl.filter(ImageFilter.GaussianBlur(w / 120))
    img.paste(cl, (0, 0), cl)
    d = ImageDraw.Draw(img)
    # pista en perspectiva
    cx = w / 2
    d.polygon([(cx - w * 0.04, horizon), (cx + w * 0.04, horizon), (cx + w * 0.3, h), (cx - w * 0.3, h)], fill=(70, 72, 78))
    for i in range(10):
        t0, t1 = (i + 0.2) / 10, (i + 0.6) / 10
        y0, y1 = horizon + (h - horizon) * t0 ** 1.6, horizon + (h - horizon) * t1 ** 1.6
        d.polygon([(cx - 2 - 8 * t0 * w / 1000, y0), (cx + 2 + 8 * t0 * w / 1000, y0), (cx + 2 + 8 * t1 * w / 1000, y1), (cx - 2 - 8 * t1 * w / 1000, y1)], fill=(235, 235, 225))
    return img.convert("RGBA")


# ---------------------------------------------------------------------------
# Zonas
# ---------------------------------------------------------------------------
SHIP_SLOTS = [("armas", "Cañones", "∞"), ("misil", "Misiles", "12"), ("laser", "Láser", "∞"), ("escudo", "Escudo", "∞"), ("camuflaje", "Camuflaje", "3"), ("salto", "Salto Cuántico", "2"), ("hiper", "Hipervelocidad", "∞"), ("dron", "Dron", "4")]
PLANE_SLOTS = [("flaps", "FLAPS", "1"), ("tren", "TREN ↓", ""), ("frenos", "FRENO APARC.", ""), ("camara", "CÁMARA", ""), ("palanca", "↓ SUBE", ""), ("motor_0", "RALENTÍ", ""), ("motor_max", "A TOPE", ""), ("bajarse", "BAJARSE", "")]
SHIP_KEYS = [("W/S", "Motor / Avanzar"), ("A/D", "Lateral"), ("Espacio", "Subir"), ("Shift", "Impulso"), ("Ctrl", "Frenar / Emergencia"), ("Q", "Giro izquierda"), ("E", "Giro derecha"), ("Clic", "Disparar"), ("2", "Misil"), ("R", "Recargar armas"), ("Tab", "Siguiente objetivo"), ("F", "Interactuar")]
SHIP_MOVES = [("C", "Esquivar / Rodar"), ("X", "Salto cuántico"), ("7", "Hipervelocidad"), ("Z", "Camuflaje"), ("4", "Escudo"), ("8", "Modo dron"), ("V", "Bengalas"), ("T", "Modo de vuelo"), ("Y", "Asistencia"), ("B", "Salir de la nave")]
PLANE_KEYS = [("W / S", "Morro (W sube)"), ("A / D", "Alas (girar)"), ("Q / E", "Timón"), ("Shift", "Motor +"), ("Ctrl", "Motor −"), ("B", "Frenos"), ("F", "Flaps"), ("G", "Tren"), ("C", "Cámara"), ("Espacio", "Bajarse (parado)")]
PLANE_MOVES = [("Shift", "1. Motor a tope"), ("S", "2. Pasada Vr, tira"), ("G", "3. Tren arriba"), ("F", "Aterrizar: flaps 2"), ("B", "En la pista: frena")]
BUTTON_ART = {"MotorMas": ("motor_max", (60, 150, 255)), "MotorMenos": ("motor_0", (90, 110, 150)), "Frenos": ("frenos", (90, 120, 170)), "CanonAvion": ("misil", (200, 60, 60)),
              "Fuego": ("armas", (200, 60, 50)), "Misil": ("misil", (200, 120, 30)), "Turbo": ("hiper", (220, 120, 30)), "FrenoNave": ("frenos", (90, 90, 110)), "EsquivaNave": ("camuflaje", (40, 150, 170)), "ObjetivoNave": ("objetivo", (150, 50, 60)), "BengalasNave": ("chispas", (170, 110, 40))}
TOUCH_BUTTONS = {
    "CanonAvion": "CAÑÓN",
    "Fuego": "DISPARO", "Misil": "MISIL", "Turbo": "IMPULSO", "FrenoNave": "FRENO", "EsquivaNave": "ESQUIVA", "SalirNave": "Salir",
    "ValmarNave": "VALMAR", "AccionNave": "ATRACAR", "BengalasNave": "BENGALAS", "ObjetivoNave": "OBJETIVO",
    "MotorMas": "MOTOR +", "MotorMenos": "MOTOR −", "Frenos": "FRENOS",
}


def avatar(c, x, y, size):
    """Retrato de ejemplo (en el juego: tu cabeza de Roblox, Players:GetUserThumbnailAsync)"""
    s = int(c.p(size))
    face = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    fd = ImageDraw.Draw(face)
    fd.ellipse([0, 0, s - 1, s - 1], fill=(14, 36, 66, 255))
    fd.ellipse([s * 0.22, s * 0.16, s * 0.78, s * 0.74], fill=(234, 190, 150, 255))
    fd.pieslice([s * 0.18, s * 0.08, s * 0.82, s * 0.6], 180, 360, fill=(60, 40, 30, 255))
    fd.ellipse([s * 0.36, s * 0.4, s * 0.44, s * 0.48], fill=(30, 30, 40, 255))
    fd.ellipse([s * 0.56, s * 0.4, s * 0.64, s * 0.48], fill=(30, 30, 40, 255))
    fd.arc([s * 0.4, s * 0.5, s * 0.6, s * 0.64], 20, 160, fill=(120, 60, 50, 255), width=max(1, s // 40))
    fd.pieslice([s * 0.12, s * 0.7, s * 0.88, s * 1.3], 180, 360, fill=(40, 90, 160, 255))
    m = Image.new("L", (s, s), 0)
    ImageDraw.Draw(m).ellipse([0, 0, s - 1, s - 1], fill=255)
    face.putalpha(m)
    c.layer.alpha_composite(face, (int(c.p(x)), int(c.p(y))))


def zone_profile(c, r, plane, touch):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    av = H - 24
    avatar(c, X + 12, Y + 12, av)
    c.paste(sprite("aro_avatar"), X + 12 - av * 0.1, Y + 12 - av * 0.1, av * 1.2, av * 1.2)
    c.icon("rango", X + 12 + av / 2 - av * 0.18, Y + 12 + av * 1.02 - av * 0.18, av * 0.36)
    x = X + (104 if touch else 120)
    money_w = 132 if touch else 168
    c.fit(x, Y + 8, "Nv. 100", 20, 66, CYAN)
    c.fit(x + 70, Y + 8, "Sibila", 20, W - (x - X + 70) - money_w - 18)
    c.icon("moneda", X + W - 12 - money_w, Y + 8, 22)
    c.fit(X + W - 12, Y + 8, "10.000.014 €", 19, money_w - 26, MONEY, "ra")
    bar_w = 150 if touch else 180
    by = 38 if touch else 42
    step = 13 if touch else 15
    rows = [("corazon", (255, 80, 80), 0.92), ("escudo", (80, 170, 255), 0.0 if plane else 0.84), ("energia", (230, 230, 80), 0.75 if plane else 0.66)]
    for i, (icon, col, k) in enumerate(rows):
        if plane and icon == "escudo":
            continue
        yy = Y + by + i * step
        c.icon(icon, x - 1, yy - 4, 16)
        c.bar(x + 16, yy, bar_w, 7, k, col)
    if not touch:
        c.fit(x + bar_w + 26, Y + by - 2, ("AVIONETA EC-VAL · EN VUELO" if plane else "CAZA · COMBATE"), 13, W - (x - X + bar_w + 38), MUTED)
    else:
        c.text(X + W - 12, Y + by - 2, "17:26", 15, MUTED, "ra")
    ry = Y + (78 if touch else 90)
    rw = (W - (x - X) - 12) // 3
    res = [("avion", "EC-VAL"), ("combustible", "75%"), ("tren", "↓")] if plane else [("chispas", "5.432"), ("mineral", "12/40"), ("cristal", "820")]
    for i, (icon, txt) in enumerate(res):
        cx0 = x + i * rw
        c.d.rounded_rectangle([c.p(cx0), c.p(ry), c.p(cx0 + rw - 6), c.p(ry + 24)], radius=c.p(6), fill=(10, 26, 50, 200), outline=EDGE + (110,))
        c.icon(icon, cx0 + 2, ry, 24)
        c.fit(cx0 + 28 + (rw - 6 - 32) / 2, ry + 12, txt, 16, rw - 38, WHITE, "mm")


def zone_nav(c, r, plane, heading=30):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    C = MANIFEST["Compass"]
    off = ((heading - C["Window"] / 2) % 360) * C["PxPerDeg"]
    tape = sprite("brujula_cinta").crop((int(off), 0, int(off) + C["Window"] * C["PxPerDeg"], C["H"]))
    c.paste(tape, X + 10, Y + 4 + 34 - 24, W - 20, 24)
    names = {0: "N", 45: "NE", 90: "E", 135: "SE", 180: "S", 225: "SO", 270: "O", 315: "NO"}
    for deg in range(0, 360, 15):
        d = ((deg - heading + 540) % 360) - 180
        if abs(d) <= 60 and deg in names:
            fx = X + 10 + (0.5 + d / 120) * (W - 20)
            major = deg % 90 == 0
            c.text(fx, Y + 4, names[deg], 22 if major else 16, CYAN if deg == 0 else (WHITE if major else MUTED), "ma", glow=major)
    # destino (rombo dorado) y la marca del centro
    c.icon("rombo", X + 10 + (0.5 + 18 / 120) * (W - 20) - 12, Y + 4 + 17 - 12, 24)
    c.d.rectangle([c.p(X + W / 2 - 1.5), c.p(Y + 40), c.p(X + W / 2 + 1.5), c.p(Y + 52)], fill=WHITE + (255,))
    sys_text = "✈ Espacio aéreo de Valmar" if plane else "◆ Sistema Valmar"
    c.text(X + W / 2, Y + 45, sys_text, 22, CYAN, "ma", glow=True)
    c.text(X + W / 2, Y + 71, "Aeropuerto de Valmar  ·  ALT 420 m" if plane else "Cinturón de Hierro  ·  Campo de asteroides", 16, WHITE, "ma")
    c.text(X + W / 2, Y + 91, "▶ El vecino del garaje · 680 m" if plane else "▶ Estación Alba · 2,4 km", 14, GOLD, "ma")


def c_len(c, s, size):
    return font(c.p(size)).getlength(s) / c.k


def zone_radar(c, r, plane, heading=30):
    X, Y, S_, _ = r
    c.paste(sprite("radar"), X, Y, S_, S_)
    c.paste(sprite("radar_barrido"), X + S_ * 0.04, Y + S_ * 0.04, S_ * 0.92, S_ * 0.92, rot=-40)
    rnd = random.Random(5)
    blips = [((0.1, -0.55), (255, 70, 70), "rombo_rojo"), ((-0.4, -0.2), (255, 70, 70), "rombo_rojo"), ((0.5, 0.3), (110, 255, 190), None), ((-0.3, 0.45), (90, 170, 255), None), ((0.35, -0.2), (255, 205, 70), "rombo")]
    if plane:
        blips = [((0.0, -0.6), (235, 248, 255), None), ((0.3, -0.3), (255, 205, 70), "rombo"), ((-0.4, 0.2), (90, 170, 255), None)]
    for (bx, by), col, icon in blips:
        px, py = X + S_ * (0.5 + bx * 0.44), Y + S_ * (0.5 + by * 0.44)
        if icon:
            c.icon(icon, px - 9, py - 9, 18)
        else:
            g = Image.new("RGBA", c.layer.size, (0, 0, 0, 0))
            ImageDraw.Draw(g).ellipse([c.p(px - 7), c.p(py - 7), c.p(px + 7), c.p(py + 7)], fill=col + (200,))
            c.layer.alpha_composite(g.filter(ImageFilter.GaussianBlur(c.p(3))))
            c.d.ellipse([c.p(px - 4), c.p(py - 4), c.p(px + 4), c.p(py + 4)], fill=col + (255,))
    c.icon("avion" if plane else "hiper", X + S_ / 2 - 14, Y + S_ / 2 - 14, 28)
    for letter, off in (("N", 0), ("E", 90), ("S", 180), ("O", 270)):
        a = math.radians(off - heading)
        c.text(X + S_ * (0.5 + math.sin(a) * 0.43), Y + S_ * (0.5 - math.cos(a) * 0.43), letter, 18 if letter == "N" else 14, WHITE if letter == "N" else MUTED, "mm", glow=letter == "N")
    c.text(X + S_ * 0.14, Y + S_, "RADAR 1,4 km" if not plane else "RADAR 0,7 km", 12, CYAN, "rd")


def zone_missions(c, r, plane, touch):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    rows = [("emblema", "PRINCIPAL", GOLD, "El vecino del garaje", "Vuela hasta su casa", "680 m"), ("rombo", "VUELO", CYAN, "Pista de Valmar", "Aterriza con flaps 2", "50 m"), ("rombo_rojo", "EVENTO GLOBAL", RED, "Tormenta sobre la costa", "Termina en 12:34", "")]
    if not plane:
        rows = [("emblema", "MISIÓN PRINCIPAL", GOLD, "El Origen de la Grieta", "Dirígete al núcleo del sistema", "2,4 km"), ("rombo", "MISIÓN SECUNDARIA", CYAN, "Fragmentos de la llave", "Encuentra los 3 fragmentos", "1/3"), ("rombo_rojo", "EVENTO GLOBAL", RED, "Tormenta de asteroides", "Termina en 12:34", "")]
    row_h = (H - 8 - (0 if touch else 16)) // 3
    for i, (icon, kind, col, title, step, right) in enumerate(rows):
        y = Y + 4 + i * row_h
        c.nine("marco_cabecera", X + 2, y + 1, W * 0.7, 20)
        c.icon(icon, X + 4, y - 1, 24)
        c.text(X + 30, y + 3, kind, 13, col)
        c.fit(X + 30, y + 20, title, 16, W - 110)
        if right:
            c.text(X + W - 10, y + 20, right, 14, MUTED, "ra")
        if row_h >= 54:
            c.fit(X + 30, y + 39, "• " + step, 13, W - 40, MUTED, bold=False)
    if not touch:
        c.text(X + 12, Y + H - 18, "⛰ Vuelo libre  ·  1.250 pts" if not plane else "✈ Vuelo libre", 12, MUTED)


def zone_speed(c, r, plane, touch):
    X, Y, W, H = r
    # esfera redonda detrás del número (centrada donde el arco)
    rr = H * 0.4
    cx, cy = X + H * 0.616, Y + H / 2
    g = Image.new("RGBA", c.layer.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(g)
    gd.ellipse([c.p(cx - rr), c.p(cy - rr), c.p(cx + rr), c.p(cy + rr)], fill=(10, 30, 60, 150), outline=EDGE + (120,), width=max(1, int(c.p(1.5))))
    c.layer.alpha_composite(g)
    hh = H * 1.08
    aw = hh / 2
    ay = Y + H / 2 - hh / 2
    c.paste(sprite("arco_base_izq"), X, ay, aw, hh)
    c.arc("arco_grueso_izq", 0.42 if plane else 0.66, X, ay, aw, hh, CYAN)
    c.arc("arco_fino_izq", 0.75 if plane else 0.8, X, ay, aw, hh, ORANGE)
    c.text(X + W * 0.65, Y + H * 0.2, "196" if plane else "1.284", 30 if touch else 40, WHITE, "ma", glow=True)
    c.text(X + W * 0.65, Y + H * 0.43, "KM/H · 106 KT" if plane else "KM/H", 13, WHITE, "ma")
    c.text(X + W * 0.65, Y + H * 0.52, "VELOCIDAD", 11, MUTED, "ma")
    c.text(X + W * 0.34, Y + H * 0.62, "MOTOR" if plane else "IMPULSO", 11, ORANGE)
    c.text(X + W * 0.96, Y + H * 0.62, "75%" if plane else "80%", 11, WHITE, "ra")
    c.bar(X + W * 0.34, Y + H * 0.71, W * 0.62, 6, 0.75 if plane else 0.8, ORANGE)
    bx, by, bw, bh = X + W * 0.34, Y + H * 0.8, W * 0.64, H * 0.14
    c.d.rounded_rectangle([c.p(bx), c.p(by), c.p(bx + bw), c.p(by + bh)], radius=c.p(6), fill=(12, 34, 60, 200), outline=EDGE + (150,))
    c.fit(bx + bw / 2, by + bh / 2, "EN VUELO" if plane else "COMBATE", 12, bw - 6, CYAN, "mm")


def zone_defense(c, r, plane, touch):
    X, Y, W, H = r
    hh = H * 1.08
    aw = hh / 2
    ay = Y + H / 2 - hh / 2
    c.paste(sprite("arco_base_der"), X + W - aw, ay, aw, hh)
    if not plane:
        c.arc("arco_grueso_der", 0.92, X + W - aw, ay, aw, hh, G_SHIELD)
    c.arc("arco_medio_der", 0.87 if not plane else 0.45, X + W - aw, ay, aw, hh, GREEN if not plane else G_WARN)
    rows = [("ESCUDO", "escudo", "92%", 0.92, G_SHIELD, CYAN, 0.0), ("ESTRUCTURA", "estructura", "87%" if not plane else "45%", 0.87 if not plane else 0.45, GREEN if not plane else G_WARN, WHITE, 0.5)]
    for title, icon, val, k, col, tcol, oy in rows:
        if plane and title == "ESCUDO":
            continue
        rx, ry, rw, rh = X, Y + H * oy, W * 0.78, H * 0.46
        c.text(rx + rw * 0.06, ry + rh * 0.08, title, 14 if title == "ESCUDO" else 13, tcol, glow=title == "ESCUDO")
        c.icon(icon, rx + rw * 0.04, ry + rh * 0.33, 26)
        c.text(rx + rw * 0.06 + 30, ry + rh * 0.36, val, 16 if touch else 18)
        c.bar(rx + rw * 0.06, ry + rh * 0.74, rw * 0.7, 7, k, col)


def zone_jump(c, r):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    v = H * 1.15
    c.paste(sprite("vortice"), X + W * 0.82 - v / 2, Y + H / 2 - v / 2, v, v)
    c.text(X + 14, Y + 6, "SALTO CUÁNTICO", 18, VIOLET, glow=True)
    c.text(X + 14, Y + 30, "Destino: Estación Cénit", 15)
    c.text(X + 14, Y + 50, "2,4 km · ⚡ 30", 13, MUTED)
    c.chip(X + 14, Y + H - 30, 28, 22, "X")
    c.text(X + 50, Y + H - 28, "Activar", 14)


def zone_target(c, r, plane):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    c.nine("marco_cabecera", X + 6, Y + 3, W * 0.75, 20)
    c.icon("aviso", X + 10, Y + 3, 18)
    c.text(X + 32, Y + 4, "PISTA" if plane else "OBJETIVO", 13, GOLD)
    c.icon("rombo_rojo", X + 26 - 15, Y + 44 - 15, 30)
    c.fit(X + 44, Y + 24, "Pista de Valmar" if plane else "Pirata Espacial", 15, W - 130)
    if not plane:
        c.text(X + W - 12, Y + 24, "Nv. 42", 13, MUTED, "ra")
    c.text(X + 44, Y + 44, "50 m" if plane else "1,2 km  ·  FIJADO", 14)
    c.bar(X + 44, Y + H - 16, W - 60, 7, 0.82 if plane else 0.7, RED)


def zone_keys(c, r, title, rows):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    c.nine("marco_cabecera", X + 4, Y + 4, W * 0.8, 22)
    c.text(X + 12, Y + 6, title, 14, CYAN)
    for i, (k, t) in enumerate(rows):
        y = Y + 28 + i * 21
        if y + 20 > Y + H:
            break
        c.chip(X + 12, y + 1, 78, 18, k, 11)
        c.fit(X + 98, y + 2, t, 13, W - 110)


def zone_ship(c, r, plane):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    c.paste(tint(sprite("aro_widget"), (150, 225, 255)), X + 85 - 84, Y + 90 - 84, 168, 168)
    c.paste(sprite("silueta_avion" if plane else "silueta_nave"), X + 85 - 52, Y + 90 - 65, 104, 130)
    x = X + 172
    rows = [("estructura", "100%" if not plane else "92%", 36), ("avion" if plane else "energia", "420 m" if plane else "100%", 62)]
    if not plane:
        rows.insert(0, ("escudo", "100%", 10))
    for icon, val, y in rows:
        c.icon(icon, x - 3, Y + y - 3, 28)
        c.text(x + 28, Y + y, val, 18, CYAN if icon == "escudo" else WHITE)
    c.bar(x, Y + 88, 140, 6, 0.6 if plane else 0.8, (230, 230, 80))
    c.text(x, Y + 102, "RUMBO" if plane else "MISILES", 12, ORANGE)
    c.text(x + 70, Y + 100, "030° NE" if plane else "6/6", 16)
    c.fit(x, Y + 126, "FLAPS 1 · TREN ↑" if plane else "LÁSER", 13, 140, CYAN)
    if not plane:
        c.bar(x, Y + 150, 140, 6, 0.35, RED)


def zone_quick(c, r, plane):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    c.paste(tint(sprite("aro_widget"), (110, 240, 200)), X + 62 - 58, Y + 72 - 58, 116, 116)
    c.paste(sprite("silueta_avion" if plane else "silueta_nave"), X + 62 - 30, Y + 72 - 37, 60, 75)
    rows = [("F", "Flaps"), ("G", "Tren"), ("C", "Cámara"), ("Esp", "Bajarse")] if plane else [("Q", "Giro Izq."), ("E", "Giro Der."), ("C", "Esquivar"), ("Z", "Camuflaje")]
    for i, (k, t) in enumerate(rows):
        y = Y + 8 + i * 30
        c.chip(X + 124, y + 2, 26, 22, k, 12)
        c.text(X + 158, y + 3, t, 15)
    c.text(X + 12, Y + 143, "▸ Tirar ↓ para subir" if plane else "▸ Modo Combate", 14)
    px, py = X + W - 14 - 64, Y + 140
    c.d.rounded_rectangle([c.p(px), c.p(py), c.p(px + 64), c.p(py + 26)], radius=c.p(13), fill=(16, 60, 100, 255), outline=EDGE + (255,), width=max(1, int(c.p(1.5))))
    c.text(px + 32, py + 13, "SÍ" if plane else "ON", 14, CYAN, "mm")
    c.text(X + W - 40, Y + H - 8, "14:27", 16, WHITE, "rd")
    for i in range(1, 5):
        c.d.rectangle([c.p(X + W - 34 + i * 5), c.p(Y + H - 10 - 3 - i * 3), c.p(X + W - 31 + i * 5), c.p(Y + H - 10)], fill=CYAN + (255,))


def zone_slots(c, r, slot, gap, plane, touch):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    slots = PLANE_SLOTS if plane else SHIP_SLOTS
    for i, (icon, name, count) in enumerate(slots):
        x = X + 8 + i * (slot + gap)
        y = Y + 6
        sel = (i == 0) if plane else (i == 5)
        c.nine("marco_ranura_sel" if sel else "marco_ranura", x, y, slot, slot)
        c.icon(icon, x + slot * 0.14, y + slot * 0.1, slot * 0.72)
        if not plane and i == 1:
            # recarga (barrido de reloj, 40 % por recargar)
            C = MANIFEST["Cool"]
            idx = 8
            f = C["Frame"]
            cell = sprite("recarga").crop(((idx % C["Cols"]) * f, (idx // C["Cols"]) * f, (idx % C["Cols"] + 1) * f, (idx // C["Cols"] + 1) * f))
            c.paste(cell, x, y, slot, slot)
        if not touch:
            c.text(x + 6, y + 3, str(i + 1), 14, MUTED)
        if count:
            c.text(x + slot - 6, y + 3, count, 14, WHITE, "ra")
        c.fit(x + slot / 2, y + slot + 2, name, 12, slot + 8, CYAN if sel else WHITE, "ma")


def zone_prompt(c, r, plane):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    e = H * 1.35
    c.paste(sprite("emblema"), X - 10, Y + H / 2 - e / 2, e, e)
    c.icon("palanca" if plane else "hiper", X - 10 + e * 0.19, Y + H / 2 - e * 0.31, e * 0.62)
    inset = e - 2
    if plane:
        c.fit(X + inset, Y + 4, "PARA DESPEGAR: MOTOR + A TOPE", 20, W - inset - 12, ORANGE)
        c.fit(X + inset, Y + 28, "En la pista, a 52 km/h, tira hacia abajo", 14, W - inset - 12)
    else:
        c.text(X + inset, Y + 4, "HIPERVELOCIDAD", 20, CYAN, glow=True)
        lw = c_len(c, "Mantén ", 14)
        c.text(X + inset, Y + 28, "Mantén", 14)
        c.chip(X + inset + lw, Y + 27, 46, 18, "Shift", 11)
        c.text(X + inset + lw + 52, Y + 28, "para activar", 14)
    c.bar(X + 16, Y + H - 8, W - 32, 4, 0.3, ORANGE)


def zone_help(c, r):
    X, Y, W, H = r
    c.nine("marco_panel", X, Y, W, H)
    c.text(X + W / 2, Y + H / 2, "?", 40, CYAN, "mm", glow=True)


def touch_controls(c, case):
    for name, (x, y, w, h) in case["Buttons"].items():
        cx, cy, rr = x + w / 2, y + h / 2, min(w, h) / 2
        art, tint_c = BUTTON_ART.get(name, (None, (40, 80, 140)))
        c.d.ellipse([c.p(cx - rr), c.p(cy - rr), c.p(cx + rr), c.p(cy + rr)], fill=(8, 22, 44, 200))
        c.d.ellipse([c.p(cx - rr * 0.84), c.p(cy - rr * 0.84), c.p(cx + rr * 0.84), c.p(cy + rr * 0.84)], fill=tint_c + (110,))
        ring_c = tuple(int(v + (255 - v) * 0.35) for v in tint_c)
        c.paste(tint(sprite("aro_widget"), ring_c), cx - rr * 1.16, cy - rr * 1.16, rr * 2.32, rr * 2.32)
        if art:
            c.icon(art, cx - rr * 0.62, cy - rr * 0.2 - rr * 0.62, rr * 1.24)
        c.fit(cx, cy + rr * 0.32 + 0.1 * rr, TOUCH_BUTTONS.get(name, name), 22, w * 0.85, WHITE, "ma")
    st = case.get("Stick")
    if st:
        x, y, w, h = st
        cx, cy, rr = x + w / 2, y + h / 2, min(w, h) / 2
        c.d.ellipse([c.p(cx - rr), c.p(cy - rr), c.p(cx + rr), c.p(cy + rr)], fill=(8, 22, 44, 120), outline=CYAN + (200,), width=max(1, int(c.p(4))))
        c.paste(tint(sprite("aro_widget"), (130, 220, 255)), cx - rr * 1.14, cy - rr * 1.14, rr * 2.28, rr * 2.28)
        c.d.ellipse([c.p(cx - rr * 0.4), c.p(cy - rr * 0.4), c.p(cx + rr * 0.4), c.p(cy + rr * 0.4)], fill=(120, 190, 240, 220))


def invasion_banner(img, case):
    """El panel EVENTO GLOBAL pilotando (UI/InvasionHud + TopStack: justo bajo la brújula y los avisos)"""
    k = case["Scale"]
    touch = case["Touch"]
    S = {"W": 560, "Row": 30, "Pad": 6, "Bar": 12} if touch else {"W": 500, "Row": 24, "Pad": 6, "Bar": 8}
    top = 1e9
    bottom = 0
    for name in ("B", "J"):
        z = case["Zones"].get(name)
        if z:
            bottom = max(bottom, z[1] + z[3])
    w, h = S["W"], S["Pad"] * 2 + S["Row"] * 2 + S["Bar"] + 6
    y_px = bottom * k + 8
    x_px = img.width / 2 - w * k / 2
    c = Canvas(img, k)
    X, Y = x_px / k, y_px / k
    c.nine("marco_panel", X, Y, w, h)
    e = S["Row"] * 2 - 4
    c.paste(sprite("emblema"), X + 8, Y + S["Pad"] + 2, e, e)
    c.icon("rombo_rojo", X + 8 + e * 0.2, Y + S["Pad"] + 2 + e * 0.2, e * 0.6)
    x = X + 14 + e
    c.fit(x, Y + S["Pad"] + 2, "EVENTO GLOBAL · INVASIÓN", 24 if touch else 17, w * 0.62 - (x - X), (120, 255, 230))
    c.fit(X + w - 14, Y + S["Pad"] + 2, "Oleada 1 de 4  ⏱ 3:20", 23 if touch else 16, w * 0.38 - 4, WHITE, "ra")
    c.fit(x, Y + S["Pad"] + S["Row"] + 2, "Ferrocéfalos, Lumínidos y Vórtidos · San Roque: EN DISPUTA", 23 if touch else 15, w - (x - X) - 14, WHITE, bold=False)
    c.bar(x, Y + S["Pad"] + S["Row"] * 2 + 2, w - (x - X) - 14, S["Bar"], 0.62, (255, 190, 60))
    c.finish()


def render(case, out_path, banner=False):
    w, h = case["Size"]
    plane = case["Vehicle"] == "Plane"
    touch = case["Touch"]
    img = sky_bg(w, h) if plane else space_bg(w, h)
    c = Canvas(img, case["Scale"])
    Z = case["Zones"]
    zone_profile(c, Z["A"], plane, touch)
    zone_nav(c, Z["B"], plane)
    zone_radar(c, Z["D"], plane)
    zone_missions(c, Z["E"], plane, touch)
    zone_speed(c, Z["Speed"], plane, touch)
    zone_defense(c, Z["Defense"], plane, touch)
    if "Jump" in Z:
        zone_jump(c, Z["Jump"])
    zone_target(c, Z["Target"], plane)
    if not touch:
        zone_keys(c, Z["Keys"], "MANDOS DEL AVIÓN" if plane else "COMANDOS DE VUELO", PLANE_KEYS if plane else SHIP_KEYS)
        zone_keys(c, Z["Moves"], "DESPEGAR Y ATERRIZAR" if plane else "MANIOBRAS ESPECIALES", PLANE_MOVES if plane else SHIP_MOVES)
        zone_ship(c, Z["Ship"], plane)
        zone_quick(c, Z["Quick"], plane)
    else:
        zone_help(c, Z["Help"])
    zone_slots(c, Z["H"], case["Slot"], case["Gap"], plane, touch)
    zone_prompt(c, Z["Prompt"], plane)
    c.finish()
    if banner:
        invasion_banner(img, case)
    # la mira (capa encima, en píxeles de la pantalla): la nave y el avión con el CAÑÓN armado
    m = sprite("mira")
    s = int(52 * (1.8 if touch else 2.6))
    img.alpha_composite(m.resize((s, s), Image.LANCZOS), (int(w / 2 - s / 2), int(h * 0.45 - s / 2)))
    if touch:
        touch_controls(c, case)
        c.finish()
    img.convert("RGB").save(out_path, quality=90)
    return img


def compare(ref_path, ours, out_path):
    ref = Image.open(ref_path).convert("RGB")
    # (los nombres de la imagen de referencia no son nuestros: se tapan; el juego es Heroes of History)
    sx, sy = ref.width / 1671, ref.height / 941
    for box in ((740, 52, 960, 90), (0, 882, 420, 925)):
        bx = tuple(int(v * (sx if i % 2 == 0 else sy)) for i, v in enumerate(box))
        ref.paste(ref.crop(bx).filter(ImageFilter.GaussianBlur(14)), bx[:2])
    W = 1280
    a = ref.resize((W, int(ref.height * W / ref.width)), Image.LANCZOS)
    b = ours.convert("RGB").resize((W, int(ours.height * W / ours.width)), Image.LANCZOS)
    H = max(a.height, b.height)
    out = Image.new("RGB", (W * 2 + 30, H + 70), (10, 14, 24))
    out.paste(a, (10, 60))
    out.paste(b, (W + 20, 60))
    d = ImageDraw.Draw(out)
    f = ImageFont.truetype(FONT, 30)
    d.text((10 + W / 2, 30), "Referencia (imagen del encargo)", font=f, fill=(235, 248, 255), anchor="mm")
    d.text((W + 20 + W / 2, 30), "Nuestro HUD con los sprites (zonas de verdad, 1920x1080)", font=f, fill=(110, 230, 255), anchor="mm")
    out.save(out_path, quality=88)


def compare_plane(ref_path, ours, out_path):
    ref = Image.open(ref_path).convert("RGB")
    # (el pie de la referencia lleva un nombre que no es el nuestro: se tapa)
    sx, sy = ref.width / 1846, ref.height / 852
    bx = (0, int(770 * sy), int(480 * sx), int(840 * sy))
    ref.paste(ref.crop(bx).filter(ImageFilter.GaussianBlur(16)), bx[:2])
    W = 1300
    a = ref.resize((W, int(ref.height * W / ref.width)), Image.LANCZOS)
    b = ours.convert("RGB").resize((W, int(ours.height * W / ours.width)), Image.LANCZOS)
    H = a.height + b.height + 120
    out = Image.new("RGB", (W + 20, H), (10, 14, 24))
    d = ImageDraw.Draw(out)
    f = ImageFont.truetype(FONT, 28)
    d.text((10 + W / 2, 28), "Referencia del avión (referencia-hud-avion.png)", font=f, fill=(235, 248, 255), anchor="mm")
    out.paste(a, (10, 52))
    d.text((10 + W / 2, 52 + a.height + 32), "Nuestro HUD del avión (zonas de verdad, 844x390, invasión)", font=f, fill=(110, 230, 255), anchor="mm")
    out.paste(b, (10, 52 + a.height + 60))
    out.save(out_path, quality=88)


def main():
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    out_dir = sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    ship_pc = None
    for case in data:
        size = "%dx%d" % tuple(case["Size"])
        if size not in ("1920x1080", "844x390"):
            continue
        name = "hud-fidelidad-%s-%s.jpg" % ("avion" if case["Vehicle"] == "Plane" else "nave", size)
        img = render(case, os.path.join(out_dir, name))
        if case["Vehicle"] == "Ship" and size == "1920x1080":
            ship_pc = img
        print(name, "choques:", case["Clashes"] or "ninguno")
    for case in data:
        if case["Vehicle"] == "Plane" and tuple(case["Size"]) == (844, 390):
            v2 = render(case, os.path.join(out_dir, "hud-avion-v2-844x390.jpg"), banner=True)
            compare_plane(os.path.join(ROOT, "docs", "espacio-aaa", "referencia-hud-avion.png"), v2, os.path.join(out_dir, "hud-avion-v2-comparacion.jpg"))
            print("hud-avion-v2-844x390.jpg, hud-avion-v2-comparacion.jpg")
    if ship_pc is not None:
        compare(os.path.join(ROOT, "docs", "espacio-aaa", "referencia-hud.png"), ship_pc, os.path.join(out_dir, "hud-fidelidad-comparacion.jpg"))
        print("hud-fidelidad-comparacion.jpg")


if __name__ == "__main__":
    main()
