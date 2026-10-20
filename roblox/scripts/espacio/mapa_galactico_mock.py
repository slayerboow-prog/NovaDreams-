"""Vista previa del MAPA GALÁCTICO sin Roblox (para la documentación: docs/espacio-aaa/mapa-galactico-*.jpg).

Uso (desde roblox/):
    lune run scripts/test-mapagalactico.luau --dump        (escribe /tmp/mapa-galactico-dump.json)
    python3 -I scripts/espacio/mapa_galactico_mock.py      (dibuja las pantallas)

Dibuja, con las MISMAS medidas que el juego (UI/GalaxyMapLayout: paneles, anillo y sitios) y el fondo
assets/espacio/mapa_galaxia.jpg, una aproximación de lo que se ve. Las letras son DejaVu (en el juego,
Gotham): es una maqueta, no una captura.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
DUMP = Path("/tmp/mapa-galactico-dump.json")
OUT = ROOT / "docs" / "espacio-aaa"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
TEX = {
    "Tefra": "planeta_lontana", "Siroco": "planeta_ocrea", "Talasa": "planeta_marena", "Nivalis": "planeta_velaria",
    "Umbria": "planeta_fronda", "Miasma": "planeta_zefira", "Vertice": "planeta_mercadia", "Valmar": "valmar_planeta",
}
EDGE = (90, 200, 255)
PANEL = (8, 16, 42, 205)


def font(size: float, bold: bool = False):
    return ImageFont.truetype(BOLD if bold else FONT, max(6, int(size)))


def col(c, a=255):
    return (int(c[0] * 255), int(c[1] * 255), int(c[2] * 255), a)


def planet_disc(pid: str, size: int, hue) -> Image.Image:
    path = ROOT / "assets" / "espacio" / f"{TEX.get(pid, '')}.jpg"
    if path.exists():
        img = Image.open(path).convert("RGB")
        w, h = img.size
        img = img.crop((w // 4, 0, w // 4 + h, h)).resize((size, size))
    else:
        img = Image.new("RGB", (size, size), tuple(int(v * 255) for v in (hue or (0.6, 0.6, 0.8))))
    if pid == "Valmar" and not path.exists():
        img = Image.new("RGB", (size, size), (255, 210, 120))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    shade = Image.new("L", (size, size), 0)
    sd = ImageDraw.Draw(shade)
    for i in range(size):
        v = max(0, (i / size - 0.5) * 2)
        sd.line((i, 0, i - size // 3, size), fill=int(200 * v), width=2)
    dark = Image.new("RGB", (size, size), (0, 0, 0))
    img = Image.composite(dark, img, shade)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def draw_diamond(d: ImageDraw.ImageDraw, cx, cy, s, color):
    pts = [(cx, cy - s / 2), (cx + s / 2, cy), (cx, cy + s / 2), (cx - s / 2, cy)]
    d.polygon(pts, fill=(10, 18, 40, 255), outline=color)
    d.line(pts + [pts[0]], fill=color, width=max(2, int(s / 10)))
    q = s * 0.18
    d.polygon([(cx, cy - q), (cx + q, cy), (cx, cy + q), (cx - q, cy)], fill=color)


def render(name: str, data: dict) -> Path:
    s = data["Sizes"][name]
    k = s["Scale"]
    W, H = (int(round(v * k)) for v in s["Canvas"])
    T = data["Texts"][name]
    R = s["Rects"]
    bg = Image.open(ROOT / "assets" / "espacio" / "mapa_galaxia.jpg").convert("RGBA")
    # (cubrir la pantalla, recortando)
    sc = max(W / bg.width, H / bg.height)
    bg = bg.resize((int(bg.width * sc) + 1, int(bg.height * sc) + 1))
    bg = bg.crop(((bg.width - W) // 2, (bg.height - H) // 2, (bg.width - W) // 2 + W, (bg.height - H) // 2 + H))
    img = bg.copy()
    over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)

    def rr(r, fill=PANEL, outline=EDGE, radius=12, width=2):
        box = (r["X"] * k, r["Y"] * k, (r["X"] + r["W"]) * k, (r["Y"] + r["H"]) * k)
        d.rounded_rectangle(box, radius=radius * k, fill=fill, outline=outline + (150,) if len(outline) == 3 else outline, width=max(1, int(width * k)))
        return box

    def text(x, y, t, size, color=(235, 244, 255, 255), bold=False, anchor="la"):
        d.text((x, y), t, font=font(size * k, bold), fill=color, anchor=anchor)

    ring = s["Ring"]
    # La órbita
    cx, cy = ring["Cx"] * k, ring["Cy"] * k
    d.ellipse((cx - ring["Rx"] * k, cy - ring["Ry"] * k, cx + ring["Rx"] * k, cy + ring["Ry"] * k), outline=(170, 200, 255, 120), width=max(1, int(1.5 * k)))
    d.ellipse((cx - ring["Rx"] * 0.6 * k, cy - ring["Ry"] * 0.6 * k, cx + ring["Rx"] * 0.6 * k, cy + ring["Ry"] * 0.6 * k), outline=(170, 200, 255, 60), width=1)
    img = Image.alpha_composite(img, over)
    over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    E = data["Entries"]
    for it in s["Items"]:
        e = E[it["Id"]]
        t = it["Thumb"]
        size = int(t["W"] * k)
        x0, y0 = int(t["X"] * k), int(t["Y"] * k)
        color = col(e["Color"])
        if e["Kind"] in ("Planet", "Center"):
            disc = planet_disc(it["Id"], size, e.get("Hue"))
            img.alpha_composite(disc, (x0, y0))
            d.ellipse((x0, y0, x0 + size, y0 + size), outline=col(e.get("Hue") or (0.5, 0.8, 1), 160), width=max(1, int(2 * k)))
            draw_diamond(d, x0 + size * 0.08, y0 + size * 0.9, max(22, size * 0.34) * 1.0, color)
        else:
            draw_diamond(d, x0 + size / 2, y0 + size / 2, size, color)
        if e.get("Here"):
            text(x0 + size / 2, y0 - 4 * k, "▼", 24, (70, 190, 255, 255), True, "mb")
        lab = it["Label"]
        big = e["Kind"] in ("Planet", "Center")
        side = it["Side"]
        anchor_x = {"Left": "r", "Below": "m", "Right": "l"}[side]
        lx = (lab["X"] + (lab["W"] if side == "Left" else lab["W"] / 2 if side == "Below" else 0)) * k
        nsize = T["Name"] if big else T["Small"]
        text(lx, lab["Y"] * k, e["Name"], nsize, bold=True, anchor=anchor_x + "a")
        st = e["StatusText"]
        sc_ = (255, 75, 75, 255) if st == "Evento global" else (255, 200, 60, 255) if st in ("Misiones activas", "Misión principal") else (160, 180, 215, 255) if e["Locked"] else (70, 225, 150, 255)
        text(lx, (lab["Y"] + lab["H"] * 0.55) * k, st.replace("🔒", "").strip() + (" (cerrado)" if "🔒" in st else ""), T["Small"], sc_, anchor=anchor_x + "a")
    img = Image.alpha_composite(img, over)
    over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)

    # Paneles
    b = rr(R["Title"])
    text((b[0] + b[2]) / 2, b[1] + 6 * k, "MAPA GALÁCTICO", min(T["Title"], R["Title"]["H"] * 0.5), (120, 220, 255, 255), True, "ma")
    text((b[0] + b[2]) / 2, b[3] - 6 * k, "Explora el universo · Descubre nuevos mundos", T["Sub"] * 0.95, anchor="md")
    if R.get("Compass"):
        c = R["Compass"]
        box = (c["X"] * k, c["Y"] * k, (c["X"] + c["W"]) * k, (c["Y"] + c["H"]) * k)
        d.ellipse(box, fill=(8, 16, 42, 140), outline=EDGE + (220,), width=max(1, int(2 * k)))
        mx, my = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
        rad = (box[2] - box[0]) / 2
        fs = max(15, c["W"] * 0.15)
        for lbl, ax, ay in (("N", 0, -0.75), ("E", 0.75, 0), ("S", 0, 0.75), ("O", -0.75, 0)):
            text(mx + ax * rad, my + ay * rad, lbl, fs, bold=True, anchor="mm")
        text(mx, my, "▲", fs * 1.4, (120, 220, 255, 255), True, "mm")
    b = rr(R["Close"])
    text((b[0] + b[2]) / 2, (b[1] + b[3]) / 2, "✕", T["Title"] * 0.8, bold=True, anchor="mm")
    # Ficha
    p = R["Player"]
    b = rr(p, radius=14)
    face = (64 if not s["Wide"] else 92) * k
    fx, fy = b[0] + 8 * k, (b[1] + b[3]) / 2 - face / 2
    d.ellipse((fx, fy, fx + face, fy + face), fill=(40, 70, 120, 255), outline=EDGE + (255,), width=max(2, int(2.5 * k)))
    text(fx + face / 2, fy + face / 2, "☺", face * 0.6 / k, (230, 220, 200, 255), anchor="mm")
    tx = b[0] + face + 18 * k
    compact = not s["Wide"]
    text(tx, b[1] + 4 * k, "Nv. 12", 17 if compact else 20, bold=True)
    text(tx + (64 if compact else 80) * k, b[1] + 4 * k, "Sebas", 17 if compact else 20, bold=True)
    money = "4.250 €" + ("   ✨ 7  ⛏ 3/20  ◆ 1" if compact else "")
    text(tx, b[1] + (26 if compact else 30) * k, money, 16 if compact else 19, (110, 230, 120, 255), True)
    by = b[1] + (50 if compact else 56) * k
    bh = (6 if compact else 8) * k
    bw = (b[2] - tx - 10 * k) if compact else (b[2] - b[0]) * 0.6 - face - 18 * k
    for i, (cc, kk) in enumerate((((235, 60, 70), 0.9), ((60, 160, 255), 0.7), ((90, 220, 110), 0.3))):
        y = by + i * (bh + 4 * k)
        d.rounded_rectangle((tx, y, tx + bw, y + bh), radius=bh / 2, fill=(10, 14, 28, 255))
        d.rounded_rectangle((tx, y, tx + bw * kk, y + bh), radius=bh / 2, fill=cc + (255,))
    if not compact:
        for i, t_ in enumerate(("✨  7", "⛏  3/20", "◆  1")):
            cw = (b[2] - b[0]) * 0.4 - 14 * k
            y = b[1] + (30 + i * 27) * k
            d.rounded_rectangle((b[2] - 8 * k - cw, y, b[2] - 8 * k, y + 24 * k), radius=8 * k, fill=(12, 24, 54, 220), outline=EDGE + (100,))
            text(b[2] - 8 * k - cw + 6 * k, y + 3 * k, t_, 16, bold=True)

    def legend(r):
        b = rr(r)
        text(b[0] + 14 * k, b[1] + 8 * k, "✦ LEYENDA", T["Name"] + 2, (120, 220, 255, 255), True)
        rowh = (r["H"] - 50) / 7
        for i, row in enumerate(data["Legend"]):
            y = r["Y"] + 44 + i * rowh
            draw_diamond(d, (r["X"] + 28) * k, (y + rowh / 2) * k, min(26, rowh - 4) * k, col(row["Color"]))
            text((r["X"] + 52) * k, (y + rowh / 2) * k, row["Text"], T["Body"], anchor="lm")

    def missions(r):
        b = rr(r)
        h = (r["H"] - 12) / 3
        rows = (("◆ MISIÓN PRINCIPAL", (255, 200, 60), "La mochila desaparecida", "Ve al colegio antes de las 8:30", "850 m"),
                ("◆ MISIÓN SECUNDARIA", (70, 200, 255), "Carga para Cénit", "→ Estación Cénit", "Entregar"),
                ("◆ EVENTO GLOBAL", (255, 75, 75), "Tormenta de asteroides en Cinturón…", "Termina en 04:50 · minar da el doble", "04:50"))
        for i, (hd, cc, t1, t2, v) in enumerate(rows):
            y = r["Y"] + 6 + i * h
            text((r["X"] + 12) * k, (y + 2) * k, hd, min(T["Small"], h * 0.28), cc + (255,), True)
            text((r["X"] + 12) * k, (y + h * 0.36) * k, t1, min(T["Body"], h * 0.28), bold=True)
            text((r["X"] + 12) * k, (y + h * 0.68) * k, t2, min(T["Body"] * 0.9, h * 0.26), (160, 180, 215, 255))
            text((r["X"] + r["W"] - 10) * k, (y + h * 0.42) * k, v, min(T["Body"], h * 0.28), bold=True, anchor="ra")

    if s["Wide"]:
        legend(R["Legend"])
        missions(R["Missions"])
    else:
        for key, label in (("LegendBtn", "✦ LEYENDA"), ("MissionsBtn", "◆ MISIONES")):
            b = rr(R[key], radius=10)
            text((b[0] + b[2]) / 2, (b[1] + b[3]) / 2, label, T["Small"], bold=True, anchor="mm")
    # Tarjeta
    c = R["Card"]
    b = rr(c)
    img_s = min(c["H"] - 16, c["W"] * 0.34)
    over.alpha_composite(planet_disc("Tefra", int(img_s * k), None), (int(b[0] + 10 * k), int(b[1] + (c["H"] - img_s) / 2 * k)))
    x = c["X"] + img_s + 22
    text(x * k, b[1] + 8 * k, "Tefra", T["Name"] + 1, bold=True)
    lines = ["Bastión Ceniza", "Ciudad: Bastión Ceniza", "Misiones: 2", "Estado: Misiones activas"]
    for i, ln in enumerate(lines[: 4 if s["Wide"] else 3]):
        text(x * k, b[1] + (8 + T["Name"] + 8 + i * (T["Small"] + 4)) * k, ln, T["Small"], (160, 180, 215, 255))
    bh = max(56, 44 / k)
    bw = min(190, c["W"] - (img_s + 22) - 10)
    vb = ((c["X"] + c["W"] - 10 - bw) * k, (c["Y"] + c["H"] - 8 - bh) * k, (c["X"] + c["W"] - 10) * k, (c["Y"] + c["H"] - 8) * k)
    d.rounded_rectangle(vb, radius=10 * k, fill=(30, 110, 200, 255), outline=EDGE + (255,), width=max(2, int(2 * k)))
    text((vb[0] + vb[2]) / 2, (vb[1] + vb[3]) / 2, "VIAJAR ›", T["Name"] + 3, bold=True, anchor="mm")
    # Pestañas
    for tab, label, icon in (("Mapa", "MAPA GALÁCTICO", "🪐"), ("Misiones", "MISIONES", "◈"), ("Inventario", "INVENTARIO", "▣"), ("Personaje", "PERSONAJE", "☺"), ("Ajustes", "AJUSTES", "⚙")):
        r = R["Tab_" + tab]
        sel = tab == "Mapa"
        b = rr(r, fill=(24, 70, 150, 245) if sel else PANEL, outline=EDGE + ((255,) if sel else (110,)), radius=10, width=2.5 if sel else 1.2)
        text((b[0] + b[2]) / 2, b[1] + r["H"] * 0.3 * k, icon, r["H"] * 0.3, (120, 220, 255, 255), anchor="mm")
        text((b[0] + b[2]) / 2, b[1] + r["H"] * 0.75 * k, label, min(T["Small"], r["W"] / 9), (235, 244, 255, 255) if sel else (160, 180, 215, 255), True, "mm")
    if R.get("Logo"):
        r = R["Logo"]
        text(r["X"] * k + r["H"] * k / 2, (r["Y"] + r["H"] / 2) * k, "✦", r["H"] * 0.7, (120, 220, 255, 255), anchor="mm")
        text((r["X"] + r["H"] + 4) * k, (r["Y"] + r["H"] * 0.08) * k, "HEROES", r["H"] * 0.4, bold=True)
        text((r["X"] + r["H"] + 4) * k, (r["Y"] + r["H"] * 0.52) * k, "OF HISTORY", r["H"] * 0.34, (120, 220, 255, 255), True)
    img = Image.alpha_composite(img, over)
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"mapa-galactico-{name}.jpg"
    img.convert("RGB").save(path, quality=86)
    return path


def main() -> None:
    data = json.loads(DUMP.read_text())
    names = sys.argv[1:] or ["1920x1080", "844x390", "640x360"]
    for n in names:
        print("✅", render(n, data).relative_to(ROOT))


if __name__ == "__main__":
    main()
