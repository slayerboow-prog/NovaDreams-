#!/usr/bin/env python3
"""Hojas de contactos «antes / después» de los planos de la auditoría de cinemáticas.

Uso:  python3 scripts/audit/cine-hoja.py ANTES_DIR DESPUES_DIR SALIDA_DIR [--por-hoja 4]

ANTES_DIR y DESPUES_DIR: lo que deja scripts/audit/cine-vista.luau (N.ppm + vistas.json), con los mismos
planos en el mismo orden (el de antes con --antes o con el código de antes). Cada fila: la vista de la
cámara antes (izquierda) y después (derecha), con el plano, sus fallos y una cuadrícula de tercios.
Escribe SALIDA_DIR/hoja-1.jpg, hoja-2.jpg… y una imagen por plano (plano-NN.jpg).
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont


def font(size):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def load(folder):
    meta = json.load(open(os.path.join(folder, "vistas.json"), encoding="utf-8"))
    out = {}
    for m in meta:
        out[(m["Escena"], m["Plano"])] = m
    return meta, out


def thirds(img):
    d = ImageDraw.Draw(img)
    w, h = img.size
    for k in (1, 2):
        d.line([(w * k // 3, 0), (w * k // 3, h)], fill=(255, 255, 255), width=1)
        d.line([(0, h * k // 3), (w, h * k // 3)], fill=(255, 255, 255), width=1)
    return img


def wrap(text, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        if len(cur) + len(w) + 1 > width:
            lines.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    if cur:
        lines.append(cur)
    return lines


def main():
    antes_dir, despues_dir, out_dir = sys.argv[1], sys.argv[2], sys.argv[3]
    per = 4
    if "--por-hoja" in sys.argv:
        per = int(sys.argv[sys.argv.index("--por-hoja") + 1])
    os.makedirs(out_dir, exist_ok=True)
    antes, antes_by = load(antes_dir)
    _, despues_by = load(despues_dir)
    f_title, f_text = font(17), font(13)
    rows = []
    for i, a in enumerate(antes, 1):
        d = despues_by.get((a["Escena"], a["Plano"]))
        if not d:
            continue
        ia = thirds(Image.open(a["Imagen"]).convert("RGB"))
        idd = thirds(Image.open(d["Imagen"]).convert("RGB"))
        w, h = ia.size
        text_h = 104
        row = Image.new("RGB", (w * 2 + 30, h + text_h + 34), (24, 24, 28))
        dr = ImageDraw.Draw(row)
        spec = a["Spec"] if a["Spec"] == d["Spec"] else f"{a['Spec']} → {d['Spec']}"
        dr.text((10, 6), f"{i}. {a['Escena']} · plano {a['Plano']} ({spec})", fill=(255, 255, 255), font=f_title)
        row.paste(ia, (10, 30))
        row.paste(idd, (w + 20, 30))
        dr.text((14, 34), "ANTES", fill=(255, 90, 90), font=f_title)
        dr.text((w + 24, 34), "DESPUÉS", fill=(110, 230, 120), font=f_title)
        for col, m, color in ((10, a, (255, 170, 170)), (w + 20, d, (170, 240, 170))):
            lines = []
            for p in (m["Fallos"] or ["sin fallos"])[:4]:
                lines += wrap(p, 62)
            for k, line in enumerate(lines[:6]):
                dr.text((col, h + 36 + k * 16), line, fill=color, font=f_text)
        name = os.path.join(out_dir, f"plano-{i:02d}.jpg")
        row.save(name, quality=88)
        rows.append(row)
    for s in range(0, len(rows), per):
        chunk = rows[s : s + per]
        sheet = Image.new("RGB", (max(r.size[0] for r in chunk), sum(r.size[1] for r in chunk)), (24, 24, 28))
        y = 0
        for r in chunk:
            sheet.paste(r, (0, y))
            y += r.size[1]
        sheet.save(os.path.join(out_dir, f"hoja-{s // per + 1}.jpg"), quality=85)
    print(f"{len(rows)} planos en {out_dir}")


if __name__ == "__main__":
    main()
