#!/usr/bin/env python3
"""Hoja de contactos del ciclo de demostración de la Grieta del cielo (aproximación, fuera de Roblox).

Uso (desde la carpeta roblox/):
    lune run scripts/rift/demo-sheet.luau > /tmp/grieta.json
    python3 scripts/rift/demo-sheet.py /tmp/grieta.json docs/arte/grieta-ciclo-demo.png

Fila 1-2: cada hueco del ciclo (las 7 etapas y la de cierre) a su hora, de día o de noche.
Fila 3: la transición en directo 4 -> 5 (se carga, la vieja se rasga y se apaga, nace la nueva,
destello y onda). Fila 4: el cierre 4 -> 1 (se cose y se encoge).

Es un montaje 2D con las texturas de verdad (textures/rift) y las cuentas del juego (tamaño a 650
studs con la cámara de 70 grados, apertura, intensidad, luz teñida, línea de tiempo); no es una
captura de Roblox: sin rocas 3D ni partículas, el cielo y la ciudad son un degradado y siluetas.
"""
import json
import math
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FW, FH = 480, 270
FOCAL = (FH / 2) / math.tan(math.radians(35))
DIST = 650
TEX = "textures/rift/"
_cache = {}


def tex(name):
    if name not in _cache:
        _cache[name] = Image.open(TEX + name + ".png").convert("RGBA")
    return _cache[name]


def font(size):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()


def lerp(a, b, k):
    return tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))


def is_night(h):
    h %= 24
    return h >= 19 or h < 6


def sky(hour, mood, weight, flash=0.0):
    night = is_night(hour)
    top, bottom = ((10, 14, 40), (34, 40, 80)) if night else ((70, 130, 210), (170, 205, 240))
    tint = (60, 50, 150) if mood == "GrietaAzul" else (110, 50, 170)
    top, bottom = lerp(top, tint, weight * 0.55), lerp(bottom, tint, weight * 0.45)
    img = Image.new("RGBA", (FW, FH))
    d = ImageDraw.Draw(img)
    for y in range(FH):
        c = lerp(top, bottom, y / FH)
        if flash > 0:
            c = lerp(c, (235, 220, 255), flash * 0.35)
        d.line([(0, y), (FW, y)], fill=c + (255,))
    return img


def skyline(img, night, weight):
    d = ImageDraw.Draw(img)
    base = (18, 18, 30) if night else (60, 70, 90)
    base = lerp(base, (50, 30, 80), weight * 0.5)
    x = 0
    k = 7
    while x < FW:
        k = (k * 48271) % 2147483647
        w = 22 + k % 40
        h = 30 + (k // 7) % 70
        d.rectangle([x, FH - h, x + w, FH], fill=base + (255,))
        if night:
            for wy in range(FH - h + 6, FH - 4, 9):
                for wx in range(x + 4, x + w - 4, 8):
                    if (wx * 7 + wy * 3 + k) % 5 == 0:
                        d.rectangle([wx, wy, wx + 2, wy + 3], fill=(250, 220, 140, 255))
        x += w + 2


def size_of(open_):
    open_ = max(0.0, min(1.0, open_))
    return 0.3 + 0.7 * open_, max(0.035, open_ ** 1.6)


def paste_rift(img, info, open_, vis, sx=1.0, sy=1.0, alpha=1.0, glow=0.0, seam=0.0):
    if info["Stage"] <= 1 or vis <= 0.01 or alpha <= 0.01:
        return
    wpx = info["Width"] / DIST * FOCAL
    hpx = wpx / info["Aspect"]
    w, h = size_of(open_)
    tw, th = max(2, int(wpx * w * sx)), max(2, int(hpx * h * sy))
    cx = FW / 2
    cy = FH / 2 - FOCAL * math.tan(math.radians(14))
    cy = max(cy, th * 0.45 - 10) if th < FH * 1.6 else cy
    layer = tex(info["Texture"]).resize((tw, th), Image.LANCZOS)
    a = layer.getchannel("A").point(lambda p: int(p * min(1.0, vis * alpha)))
    layer.putalpha(a)
    if glow > 0:
        halo = layer.copy().filter(ImageFilter.GaussianBlur(10))
        halo.putalpha(halo.getchannel("A").point(lambda p: int(min(255, p * glow))))
        img.alpha_composite(halo, (int(cx - tw / 2), int(cy - th / 2)))
    img.alpha_composite(layer, (int(cx - tw / 2), int(cy - th / 2)))
    if seam > 0:
        d = ImageDraw.Draw(img)
        y = int(cy)
        d.line([(cx - tw * 0.45, y), (cx + tw * 0.45, y)], fill=(245, 230, 255, int(255 * seam)), width=3)
        for i in range(7):
            x = cx - tw * 0.4 + tw * 0.8 * i / 6
            d.line([(x - 4, y - 8), (x + 4, y + 8)], fill=(205, 170, 255, int(230 * seam)), width=2)
    return cx, cy, tw


def label(img, text, sub=None):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, FW, 22], fill=(0, 0, 0, 150))
    d.text((6, 3), text, font=font(14), fill=(255, 255, 255, 255))
    if sub:
        d.text((6, FH - 20), sub, font=font(12), fill=(230, 220, 255, 255))


def frame_cycle(data, slot):
    info = data["Stages"][slot["Stage"] - 1]
    weight = info["Ambient"] * slot["Open"] * slot["Intensity"]
    img = sky(slot["Hour"], info.get("Mood"), weight)
    paste_rift(img, info, slot["Open"], slot["Intensity"])
    skyline(img, is_night(slot["Hour"]), weight)
    to = slot["To"] if slot["To"] else 24
    label(img, "%02d-%02d h  etapa %d  %s" % (slot["From"], to, slot["Stage"], slot["Phase"]), info["Name"] + (" (de noche)" if is_night(slot["Hour"]) else " (de dia)"))
    return img


def frame_transition(data, tr, f):
    new, old = f.get("New"), f.get("Old")
    mood_info = data["Stages"][(new or old or {"Stage": tr["To"]})["Stage"] - 1]
    weight = 0
    if new:
        weight = data["Stages"][new["Stage"] - 1]["Ambient"] * new["Open"] * new["Vis"]
    if old:
        ow = data["Stages"][old["Stage"] - 1]["Ambient"] * old["Open"] * old["Vis"] * old["Alpha"]
        weight = max(weight, ow)
    img = sky(tr["Hour"] + 1, mood_info.get("Mood") or "GrietaAzul", weight, f["Flash"])
    glow = 1.2 * f["Build"] + 2 * f["Flash"]
    pos = None
    if old:
        info = data["Stages"][old["Stage"] - 1]
        pos = paste_rift(img, info, old["Open"], old["Vis"], old["Sx"], old["Sy"], old["Alpha"], glow, old.get("Seam", 0))
    if new:
        info = data["Stages"][new["Stage"] - 1]
        pos = paste_rift(img, info, new["Open"], new["Vis"], 1, 1, 1, glow) or pos
    if f["Ring"] >= 0 and pos:
        cx, cy, tw = pos
        u = f["Ring"]
        s = u * u * (3 - 2 * u)
        wpx = max(tw, 120)
        r = wpx * (0.3 + 2.2 * s) / 2 if tr["Kind"] == "Abre" else wpx * (1.3 - 1.2 * s) / 2
        ring = Image.new("RGBA", (FW, FH))
        ImageDraw.Draw(ring).ellipse([cx - r, cy - r, cx + r, cy + r], outline=(215, 195, 255, int(255 * (0.9 - 0.9 * u))), width=6)
        img.alpha_composite(ring.filter(ImageFilter.GaussianBlur(1.5)))
    skyline(img, is_night(tr["Hour"] + 1), weight)
    what = "se carga" if f["T"] < 5 else ("destello y onda" if f["Flash"] > 0.05 else ("cambia" if f["Morph"] < 1 else "se calma"))
    if tr["Kind"] == "Cierra" and 5 <= f["T"] < 9.5:
        what = "se cose y se encoge"
    label(img, "%d -> %d   t = %.1f s" % (tr["From"], tr["To"], f["T"]), what)
    return img


def main():
    data = json.load(open(sys.argv[1]))
    out = sys.argv[2]
    frames = [frame_cycle(data, s) for s in data["Cycle"]]
    rows = [frames[0:4], frames[4:8]]
    for tr in data["Transitions"]:
        fr = [frame_transition(data, tr, f) for f in tr["Frames"]]
        for i in range(0, len(fr), 4):
            rows.append(fr[i:i + 4])
    pad, head = 6, 34
    sheet = Image.new("RGB", (4 * FW + 5 * pad, head + len(rows) * (FH + pad) + pad), (20, 18, 30))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 8), "Grieta del cielo - ciclo de demostracion (un dia de juego = 20 min) y transiciones en directo (montaje 2D aproximado)", font=font(18), fill=(235, 225, 255))
    for r, row in enumerate(rows):
        for c, im in enumerate(row):
            sheet.paste(im.convert("RGB"), (pad + c * (FW + pad), head + r * (FH + pad)))
    sheet.save(out, optimize=True)
    print("hoja:", out, sheet.size)


if __name__ == "__main__":
    main()
