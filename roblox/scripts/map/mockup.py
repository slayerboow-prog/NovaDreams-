#!/usr/bin/env python3
"""Montaje de la pantalla del MAPA GRANDE tal y como la dibuja el juego (Controllers/MapUI), para
compararla con el dibujo de referencia sin abrir Roblox.

Uso (desde la carpeta roblox/):
    lune run scripts/map/layout.luau DIR/layout.json 1846x852 932x430
    python3 scripts/map/mockup.py DIR/layout.json docs/mapa [--reference IMAGEN]

Usa lo mismo que el juego: el sitio de cada pieza (shared/MapScreen.layout), «Lugares importantes» con
los lugares de la ciudad construida (docs/mapa/lugares.json), el arte de la isla (textures/mapa, el que
sube scripts/upload-map.sh) encajado como MapUI.fitAll y tu flecha puesta con la deformación. Escribe:
    OUT/mapa-<ancho>x<alto>.png   la pantalla a ese tamaño (móvil apaisado: paneles en pestañas)
    OUT/comparacion-<ancho>x<alto>.png  referencia (si se pasa) y el montaje, uno encima del otro
Los colores, tamaños de letra y radios son los de MapUI; las letras son Liberation Sans (Roblox usa
Gotham) y los emojis, Noto (en el juego, los del sistema).
"""
import argparse
import json
import math
import os

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SS = 2  # supermuestreo
FONT_BOLD = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
EMOJI = "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf"

PANEL = (8, 18, 46)
ROW = (16, 32, 72)
EDGE = (70, 150, 255)
GLOW = (110, 200, 255)
SUB = (186, 198, 222)
PIN = (14, 26, 58)

_fonts = {}


def font(size, bold=True):
    key = (round(size), bold)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(FONT_BOLD if bold else FONT, max(6, round(size)))
    return _fonts[key]


_emoji_cache = {}


def emoji(ch, size):
    """Un emoji de Noto a `size` píxeles (o None si la fuente no lo tiene)."""
    ch = ch.replace("️", "")
    key = (ch, round(size))
    if key in _emoji_cache:
        return _emoji_cache[key]
    try:
        f = ImageFont.truetype(EMOJI, 109)
        im = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
        ImageDraw.Draw(im).text((80, 80), ch, font=f, embedded_color=True, anchor="mm")
        box = im.getbbox()
        if not box:
            raise ValueError
        im = im.crop(box)
        k = size / max(im.size)
        im = im.resize((max(1, round(im.size[0] * k)), max(1, round(im.size[1] * k))), Image.LANCZOS)
    except Exception:
        im = None
    _emoji_cache[key] = im
    return im


class Canvas:
    def __init__(self, w, h, k):
        self.k = k * SS  # píxeles por unidad del lienzo de Roblox
        self.img = Image.new("RGBA", (round(w * self.k), round(h * self.k)), (0, 0, 0, 255))

    def u(self, v):
        return v * self.k

    def layer(self):
        return Image.new("RGBA", self.img.size, (0, 0, 0, 0))

    def put(self, layer):
        self.img = Image.alpha_composite(self.img, layer)

    def rrect(self, r, radius, fill, alpha=255, edge=None, edge_w=2, glow=None, sheen=True):
        x, y, w, h = (self.u(r["X"]), self.u(r["Y"]), self.u(r["W"]), self.u(r["H"]))
        rad = min(self.u(radius), h / 2, w / 2)
        if glow:
            g = self.layer()
            ImageDraw.Draw(g).rounded_rectangle((x - 3, y - 3, x + w + 3, y + h + 3), rad + 3, outline=glow + (70,), width=round(self.u(6)))
            self.put(g.filter(ImageFilter.GaussianBlur(self.u(3))))
        lay = self.layer()
        d = ImageDraw.Draw(lay)
        d.rounded_rectangle((x, y, x + w, y + h), rad, fill=fill + (alpha,))
        if sheen:
            # Brillo arriba, más oscuro abajo (UIGradient de los paneles)
            grad = np.linspace(1.0, 0.68, max(2, round(h) + 2))[:, None, None]
            arr = np.array(lay).astype(np.float32)
            y0, y1 = max(0, round(y)), min(arr.shape[0], round(y + h))
            arr[y0:y1, :, :3] *= grad[: y1 - y0]
            lay = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
            d = ImageDraw.Draw(lay)
        if edge:
            d.rounded_rectangle((x, y, x + w, y + h), rad, outline=edge + (240,), width=max(1, round(self.u(edge_w))))
        self.put(lay)

    def circle(self, cx, cy, r, fill, outline=None, width=2, alpha=255):
        lay = self.layer()
        d = ImageDraw.Draw(lay)
        cx, cy, r = self.u(cx), self.u(cy), self.u(r)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill + (alpha,), outline=(outline + (240,)) if outline else None, width=max(1, round(self.u(width))))
        self.put(lay)

    def text(self, x, y, s, size, color=(255, 255, 255), bold=True, anchor="la", stroke=0, max_w=None):
        f = font(self.u(size), bold)
        if max_w is not None:
            limit = self.u(max_w)
            while f.getlength(s) > limit and len(s) > 1:
                s = s[:-2] + "…"
        lay = self.layer()
        ImageDraw.Draw(lay).text((self.u(x), self.u(y)), s, font=f, fill=color + (255,), anchor=anchor, stroke_width=round(self.u(stroke)), stroke_fill=(6, 14, 36, 230))
        self.put(lay)
        return f.getlength(s) / self.k

    def glyph(self, ch, cx, cy, size):
        im = emoji(ch, self.u(size))
        if im is None:
            self.text(cx, cy, ch, size * 0.8, anchor="mm")
            return
        self.img.alpha_composite(im, (round(self.u(cx) - im.size[0] / 2), round(self.u(cy) - im.size[1] / 2)))


def navy(c, r, radius=18):
    c.rrect(r, radius, PANEL, alpha=225, edge=EDGE, glow=GLOW)


def list_row(c, x, y, w, h, icon, color, title, sub, ts):
    c.rrect({"X": x, "Y": y, "W": w, "H": h}, 14, ROW, alpha=205, edge=EDGE, edge_w=1, sheen=False)
    d = h - 6
    cx, cy = x + 3 + d / 2, y + h / 2
    c.circle(cx, cy, d / 2, tuple(color), outline=tuple(min(255, int(v * 0.5 + 128)) for v in color), width=2)
    # brillo del círculo (UIGradient blanco -> gris)
    lay = c.layer()
    ImageDraw.Draw(lay).ellipse((c.u(cx - d / 2), c.u(cy - d / 2), c.u(cx + d / 2), c.u(cy)), fill=(255, 255, 255, 40))
    c.put(lay)
    c.glyph(icon, cx, cy, d * 0.5)
    c.text(x + d + 14, y + h / 2 - 21, title, ts["Title"], max_w=w - d - 20)
    c.text(x + d + 14, y + h / 2 + 2, sub, ts["Sub"], color=SUB, bold=False, max_w=w - d - 20)


def list_panel(c, r, title, rows, row_h, ts):
    navy(c, r, 20)
    size = ts["Header"]
    while size > 10 and font(c.u(size)).getlength(title) / c.k > r["W"] - 40:
        size -= 0.5  # (TextScaled con tope, como en el juego)
    c.text(r["X"] + 20, r["Y"] + 8 + (ts["Header"] - size) / 2, title, size)
    y = r["Y"] + 52 + 2
    for row in rows:
        h = row_h - 8
        if y + h > r["Y"] + r["H"] - 6:
            break
        list_row(c, r["X"] + 12, y, r["W"] - 14 - 12, h, *row, ts)
        y += h + 8


def draw_screen(data, screen, map_img, drawer=None):
    W, H = screen["Canvas"]
    k = screen["Scale"]
    c = Canvas(W, H, k)
    R = screen["Rects"]
    ts = screen["TextSizes"]
    # Mar de fondo: el azul del borde del arte (MapScreen.Colors.Sea)
    c.img = Image.new("RGBA", c.img.size, tuple(data["Sea"]) + (255,))

    # El arte con el zoom 1 (MapUI.fitAll): la isla del dibujo (IslandBox) en el centro del hueco libre
    art, box = data["Art"], data["IslandBox"]
    area = screen["Map"]
    scale = screen["Fit"]  # píxeles de la imagen por unidad del lienzo (MapScreen.fitScale)
    cx, cy = area["X"] + area["W"] / 2, area["Y"] + area["H"] / 2
    bx, by = (box["X0"] + box["X1"]) / 2, (box["Y0"] + box["Y1"]) / 2

    def P(u, v):
        return (cx + (u - bx) / scale, cy + (v - by) / scale)

    x0, y0 = P(art["AX0"], art["AY0"])
    x1, y1 = P(art["AX1"], art["AY1"])
    m = map_img.resize((round(c.u(x1 - x0)), round(c.u(y1 - y0))), Image.LANCZOS).convert("RGBA")
    c.img.alpha_composite(m, (round(c.u(x0)), round(c.u(y0))))

    # Distritos: tinte (polígono exacto) y borde que brilla (redondeado), como MapUI (proyectados)
    for d in data["Districts"]:
        col = tuple(d["Color"])
        lay = c.layer()
        ImageDraw.Draw(lay).polygon([tuple(c.u(v) for v in P(*p)) for p in d["Poly"]], fill=col + (31,))
        c.put(lay)
        pts = [tuple(c.u(v) for v in P(*p)) for p in d["Smooth"]]
        pts.append(pts[0])
        light = tuple(int(v + (255 - v) * 0.45) for v in col)
        for width, colr, alpha, blur in ((12, col, 56, 3), (5.5, col, 190, 0), (2, light, 255, 0)):
            lay = c.layer()
            ImageDraw.Draw(lay).line(pts, fill=colr + (alpha,), width=max(1, round(c.u(width))), joint="curve")
            c.put(lay.filter(ImageFilter.GaussianBlur(c.u(blur))) if blur else lay)

    LS = screen["LabelScale"]
    # Lugares con nombre (uno de cada tipo con el zoom 1), con el mismo «¿cabe el nombre?» que MapUI
    labels = []
    for lab in screen["Labels"].values():
        x, y = P(lab[0], lab[1])
        w, h = lab[2] / scale, lab[3] / scale
        labels.append((x - w / 2, y - h / 2, x + w / 2, y + h / 2))
    size = 34 * LS
    icons = [(pin["Model"],) + P(pin["U"], pin["V"]) for pin in data["Pins"]]
    for pin in data["Pins"]:
        x, y = P(pin["U"], pin["V"])
        c.circle(x, y, size / 2, PIN, outline=(255, 255, 255), width=2 * LS, alpha=250)
        c.glyph(pin["Icon"], x, y, size * 0.6)
        # (como MapUI: debajo, encima, a la derecha o a la izquierda, donde no pise nada)
        half = min(80, len(pin["Name"]) * 3.8) * LS
        r, lh = size / 2, 18 * LS
        candidates = [
            ((x - half, y + r + 2, x + half, y + r + lh), (x, y + r + 2 * LS), "ma"),
            ((x - half, y - r - lh, x + half, y - r - 2), (x, y - r - 2 * LS), "md"),
            ((x + r + 3, y - lh / 2, x + r + 3 + half * 2, y + lh / 2), (x + r + 3, y), "lm"),
            ((x - r - 3 - half * 2, y - lh / 2, x - r - 3, y + lh / 2), (x - r - 3, y), "rm"),
        ]

        def clear(rect):
            for o in labels:
                if not (rect[2] <= o[0] or o[2] <= rect[0] or rect[3] <= o[1] or o[3] <= rect[1]):
                    return False
            for model, ix, iy in icons:
                if model != pin["Model"] and not (rect[2] <= ix - r or ix + r <= rect[0] or rect[3] <= iy - r or iy + r <= rect[1]):
                    return False
            return True

        for rect, at, anchor in candidates:
            if clear(rect):
                labels.append(rect)
                c.text(at[0], at[1], pin["Name"], 14 * LS, anchor=anchor, stroke=1.2 * LS)
                break

    # Etiquetas de los distritos, donde las deja MapScreen.districtLabels (sin pisarse)
    for d in data["Districts"]:
        lab = screen["Labels"][d["Id"]]
        x, y = P(lab[0], lab[1])
        col = tuple(d["Color"])
        name = d["Name"].upper()
        wname = font(c.u(16 * LS)).getlength(name) / c.k
        wsub = font(c.u(13 * LS), False).getlength(d["Sub"]) / c.k
        w = (46 + 14) * LS + max(wname, wsub)
        hh = 46 * LS
        dark = tuple(int(v * 0.45) for v in col)
        c.rrect({"X": x - w / 2, "Y": y - hh / 2, "W": w, "H": hh}, 14 * LS, dark, alpha=232, edge=tuple(int(v + (255 - v) * 0.25) for v in col), glow=col)
        c.circle(x - w / 2 + 23 * LS, y, 19 * LS, col, outline=(255, 255, 255), width=1.5 * LS)
        c.glyph(d["Icon"], x - w / 2 + 23 * LS, y, 20 * LS)
        c.text(x - w / 2 + 46 * LS, y - hh / 2 + 4 * LS, name, 16 * LS, stroke=0.5)
        c.text(x - w / 2 + 46 * LS, y - hh / 2 + 24 * LS, d["Sub"], 13 * LS, color=(236, 240, 250), bold=False)

    # Tu flecha: en la Plaza Mayor, puesta en la imagen con la proyección (MapScreen.toArt)
    ax, ay = P(*data["Arrow"])
    lay = c.layer()
    s = 18
    tri = [(c.u(ax), c.u(ay - s)), (c.u(ax + s * 0.75), c.u(ay + s * 0.8)), (c.u(ax), c.u(ay + s * 0.35)), (c.u(ax - s * 0.75), c.u(ay + s * 0.8))]
    ImageDraw.Draw(lay).polygon(tri, fill=(70, 225, 120, 255), outline=(255, 255, 255, 255), width=round(c.u(2.5)))
    c.put(lay)

    # Botones de Roblox (arriba a la izquierda: los pone Roblox, no el juego)
    for i in range(3):
        bx = (12 + i * 50) / k
        c.rrect({"X": bx, "Y": 10 / k, "W": 44 / k, "H": 44 / k}, 10 / k, (20, 22, 28), alpha=150, sheen=False)

    # Logo
    r = R["Logo"]
    navy(c, r, 20)
    c.rrect({"X": r["X"] + 8, "Y": r["Y"] + r["H"] / 2 - 22, "W": 44, "H": 44}, 12, (80, 130, 255), sheen=False)
    c.text(r["X"] + 30, r["Y"] + r["H"] / 2, "RL", 22, anchor="mm")
    size = 21
    while size > 10 and font(c.u(size)).getlength(data["Text"]["Title"]) / c.k > r["W"] - 68:
        size -= 0.5  # (TextScaled, como en el juego)
    c.text(r["X"] + 60, r["Y"] + r["H"] / 2 - 22 + (21 - size) / 2, data["Text"]["Title"], size)
    c.text(r["X"] + 61, r["Y"] + r["H"] / 2 + 4, data["Text"]["Tagline"], 15, color=SUB, bold=False)

    # ✖, hora y tiempo, brújula
    r = R["Close"]
    c.circle(r["X"] + r["W"] / 2, r["Y"] + r["H"] / 2, r["W"] / 2, PANEL, outline=EDGE, width=2, alpha=245)
    c.text(r["X"] + r["W"] / 2, r["Y"] + r["H"] / 2, "X", 26, anchor="mm")
    r = R["Clock"]
    navy(c, r, 26)
    cx = r["X"] + r["W"] / 2
    c.glyph("☀", cx - 76, r["Y"] + r["H"] / 2, 28)
    c.text(cx - 26, r["Y"] + r["H"] / 2, "10:27", 24, anchor="mm")
    c.glyph("⛅", cx + 22, r["Y"] + r["H"] / 2, 28)
    c.text(cx + 68, r["Y"] + r["H"] / 2, "22°C", 22, anchor="mm")
    r = R["Compass"]
    cx, cy, rad = r["X"] + r["W"] / 2, r["Y"] + r["H"] / 2, r["W"] / 2
    g = c.layer()
    ImageDraw.Draw(g).ellipse((c.u(cx - rad - 5), c.u(cy - rad - 5), c.u(cx + rad + 5), c.u(cy + rad + 5)), outline=GLOW + (90,), width=round(c.u(8)))
    c.put(g.filter(ImageFilter.GaussianBlur(c.u(4))))
    c.circle(cx, cy, rad, PANEL, outline=EDGE, width=3, alpha=235)
    lay = c.layer()
    d = ImageDraw.Draw(lay)
    for ang, length, wid, colr in ((0, 0.66, 0.09, (235, 245, 255)), (90, 0.66, 0.09, (235, 245, 255)), (45, 0.44, 0.05, (120, 200, 255)), (-45, 0.44, 0.05, (120, 200, 255))):
        a = math.radians(ang)
        L, Wd = rad * length, rad * wid * 2
        pts = [(0, -L), (Wd / 2, 0), (0, L), (-Wd / 2, 0)]
        rot = [(cx + px * math.cos(a) - py * math.sin(a), cy + px * math.sin(a) + py * math.cos(a)) for px, py in pts]
        d.polygon([(c.u(px), c.u(py)) for px, py in rot], fill=colr + (255,))
    c.put(lay)
    c.circle(cx, cy, rad * 0.14, (40, 120, 255), outline=(255, 255, 255), width=2)
    for letter, fx, fy in (("N", 0.5, 0.11), ("S", 0.5, 0.89), ("E", 0.89, 0.5), ("O", 0.11, 0.5)):
        c.text(r["X"] + r["W"] * fx, r["Y"] + r["H"] * fy, letter, r["W"] * 0.16, anchor="mm")

    # + − ◎
    r = R["Zoom"]
    for i, sym in enumerate(("+", "−", "📍")):
        by = r["Y"] + r["H"] - (3 - i) * 56 - (2 - i) * (r["H"] - 168) / 2
        c.circle(r["X"] + 28, by + 28, 28, PANEL, outline=EDGE, width=2, alpha=245)
        if sym == "📍":
            c.glyph(sym, r["X"] + 28, by + 28, 28)
        else:
            c.text(r["X"] + 28, by + 26, sym, 34, anchor="mm")

    # Dónde estás, la pista y las pestañas
    r = R["Location"]
    navy(c, r, 20)
    c.glyph("📍", r["X"] + 31, r["Y"] + r["H"] / 2, 32)
    c.text(r["X"] + 60, r["Y"] + r["H"] / 2 - 24, data["Text"]["Region"], 21)
    c.text(r["X"] + 60, r["Y"] + r["H"] / 2 + 2, data["Text"]["Coords"], 16, color=SUB, bold=False)
    if "Hint" in R:
        r = R["Hint"]
        navy(c, r, 26)
        c.glyph("🎮", r["X"] + 30, r["Y"] + r["H"] / 2, 28)
        c.text(r["X"] + 54, r["Y"] + r["H"] / 2, data["Text"]["Hint"], 16, color=(225, 232, 248), bold=False, anchor="lm", max_w=r["W"] - 64)

    districts = [(d["Icon"], d["Color"], d["Name"], d["Sub"]) for d in data["Districts"]]
    places = [(p["Icon"], p["Color"], p["Title"], p["Sub"]) for p in data["Places"]]
    if screen["Wide"]:
        list_panel(c, R["Districts"], "Distritos", districts, screen["Row"], ts)
        list_panel(c, R["Places"], "Lugares importantes", places, screen["Row"], ts)
    else:
        for name, label, active in (("TabDistricts", "🏙  Distritos", drawer == "Districts"), ("TabPlaces", "📍  Lugares", drawer == "Places")):
            r = R[name]
            c.rrect(r, 28, (24, 104, 255) if active else PANEL, alpha=240, edge=EDGE, sheen=False)
            icon, word = label.split("  ")
            tw = font(c.u(18)).getlength(word) / c.k
            c.glyph(icon, r["X"] + r["W"] / 2 - tw / 2 - 14, r["Y"] + r["H"] / 2, 20)
            c.text(r["X"] + r["W"] / 2 + 6, r["Y"] + r["H"] / 2, word, 18, anchor="mm")
        if drawer == "Places":
            list_panel(c, R["Places"], "Lugares importantes", places, screen["Row"], ts)
        elif drawer == "Districts":
            list_panel(c, R["Districts"], "Distritos", districts, screen["Row"], ts)

    out = c.img.resize((round(W * k), round(H * k)), Image.LANCZOS).convert("RGB")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("layout")
    ap.add_argument("out")
    ap.add_argument("--tiles", default="textures/mapa")
    ap.add_argument("--reference")
    args = ap.parse_args()
    data = json.load(open(args.layout, encoding="utf-8"))
    meta = json.load(open(os.path.join(args.tiles, "meta.json")))
    cols, rows, tw, th = meta["Cols"], meta["Rows"], meta["TileWidth"], meta["TileHeight"]
    full = Image.new("RGB", (tw * cols, th * rows))
    for r in range(rows):
        for col in range(cols):
            full.paste(Image.open(os.path.join(args.tiles, f"isla_{r}_{col}.png")).convert("RGB"), (col * tw, r * th))
    os.makedirs(args.out, exist_ok=True)
    shots = []
    for screen in data["Screens"]:
        img = draw_screen(data, screen, full)
        w, h = screen["Viewport"]
        path = os.path.join(args.out, f"mapa-{w}x{h}.png")
        img.save(path, optimize=True)
        shots.append(img)
        print("  " + path)
        if not screen["Wide"]:
            # En el móvil, también con la pestaña «Lugares» abierta
            path = os.path.join(args.out, f"mapa-{w}x{h}-lugares.png")
            draw_screen(data, screen, full, "Places").save(path, optimize=True)
            print("  " + path)
    if args.reference and shots:
        # Lado a lado (uno encima del otro) con la referencia, a cada tamaño con su forma (2,17:1)
        for screen, shot in zip(data["Screens"], shots):
            w, h = screen["Viewport"]
            if abs(w / h - 1846 / 852) > 0.02:
                continue
            ref = Image.open(args.reference).convert("RGB")
            # (el logo de la referencia lleva otro nombre: se tapa; el juego se llama Real Life Simulator)
            ImageDraw.Draw(ref).rounded_rectangle((100, 12, 290, 52), 8, fill=(8, 18, 46))
            ImageDraw.Draw(ref).text((110, 18), "(logo)", font=ImageFont.truetype(FONT_BOLD, 24), fill=(150, 160, 190))
            ref = ref.resize((shot.width, shot.height), Image.LANCZOS)
            pad = max(26, round(40 * w / 1846))
            sheet = Image.new("RGB", (shot.width, shot.height * 2 + pad * 2), (10, 14, 24))
            d = ImageDraw.Draw(sheet)
            f = ImageFont.truetype(FONT_BOLD, max(14, round(26 * w / 1846)))
            d.text((10, 4), "Referencia", font=f, fill=(255, 255, 255))
            sheet.paste(ref, (0, pad))
            d.text((10, pad + shot.height + 4), f"Juego ({w}x{h}: montaje con shared/MapScreen y el arte de textures/mapa)", font=f, fill=(255, 255, 255))
            sheet.paste(shot, (0, shot.height + pad * 2))
            path = os.path.join(args.out, f"comparacion-{w}x{h}.png")
            sheet.save(path, optimize=True)
            print("  " + path)

if __name__ == "__main__":
    main()
