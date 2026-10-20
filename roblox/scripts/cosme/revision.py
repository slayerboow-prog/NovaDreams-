#!/usr/bin/env python3
"""Revisión a detalle de Cosme (docs/personajes/cosme/revision/): delante, 3/4, de lado, primer plano de
la cara con sus 5 caras (las 4 de emoción y la de hablar) y el «antes / después» del bug de las dos
bocas. Usa el mismo rasterizador que la hoja (scripts/cosme/render.py) con las piezas de verdad de
shared/CosmeLook (scripts/cosme/export.luau). Todo lleva la marca «VISTA PREVIA, NO ES ROBLOX».

Uso (desde roblox/):
    lune run scripts/cosme/export.luau
    python3 scripts/cosme/revision.py
"""

import importlib.util
import json
import os

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("cosme_render", os.path.join(HERE, "render.py"))
R = importlib.util.module_from_spec(spec)
spec.loader.exec_module(R)

ROOT = R.ROOT
OUT = os.path.join(ROOT, "docs", "personajes", "cosme", "revision")
MARK = "VISTA PREVIA, NO ES ROBLOX"


def stamp(canvas, title):
    d = ImageDraw.Draw(canvas)
    f = R.font(R.FONT_BOLD, 26)
    d.text((24, 18), title, font=f, fill=(235, 244, 255))
    m = R.font(R.FONT_BOLD, 18)
    tw = d.textlength(MARK, font=m)
    d.rounded_rectangle([canvas.width - tw - 44, canvas.height - 44, canvas.width - 14, canvas.height - 12], radius=8, fill=(160, 30, 40, 230))
    d.text((canvas.width - tw - 29, canvas.height - 40), MARK, font=m, fill=(255, 255, 255))


def shot(parts, yaw, w, h, face, name, title, dist=16.5, fov=28, pitch=5, focus=None):
    canvas = R.background(w, h)
    img, em, cam = R.view(parts, yaw, w, h - 40, face, dist=dist, fov=fov, pitch=pitch, focus=focus)
    if focus is None:
        fx, fy = R.feet_y(parts, cam)
        shadow = R.ground_shadow(img.width, img.height, fx, fy - 4, w * 0.2, 18)
    else:
        shadow = None
    R.composite(canvas, img, em, (0, 40), shadow)
    stamp(canvas, title)
    path = os.path.join(OUT, name)
    canvas.convert("RGB").save(path, quality=88)
    print("✅", os.path.relpath(path, ROOT))


def default_dynamic_face(size=512):
    """Lo que trae la cabeza dinámica por defecto de Roblox pintado en su textura (aproximado): dos ojos
    ovalados y una SONRISA. Solo para enseñar el bug en el «antes»."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size
    for cx in (0.38, 0.62):
        d.ellipse([s * (cx - 0.03), s * 0.56, s * (cx + 0.03), s * 0.64], fill=(25, 25, 25, 255))
    d.arc([s * 0.36, s * 0.74, s * 0.64, s * 0.96], 20, 160, fill=(25, 25, 25, 255), width=int(s * 0.024))
    return np.asarray(img, dtype=np.float32) / 255.0


def over(a, b):
    """b encima de a (las dos RGBA en 0..1)."""
    ab = b[..., 3:4]
    rgb = a[..., :3] * (1 - ab) * a[..., 3:4] + b[..., :3] * ab
    alpha = a[..., 3:4] * (1 - ab) + ab
    return np.concatenate([np.where(alpha > 0, rgb / np.maximum(alpha, 1e-6), 0), alpha], axis=-1)


def main():
    src = os.path.join(ROOT, "scripts", "cosme", "out", "cosme.json")
    data = json.load(open(src))
    idle = data["Poses"]["idle"]
    os.makedirs(OUT, exist_ok=True)
    talk = R.load_rgba("cosme_face_talk")
    faces = dict(R.FACES)
    faces["talk"] = talk

    shot(idle, 0, 760, 980, faces["grin"], "cosme-frente.jpg", "Cosme · de frente")
    shot(idle, -35, 760, 980, faces["grin"], "cosme-tres-cuartos.jpg", "Cosme · 3/4")
    shot(idle, -90, 760, 980, faces["grin"], "cosme-lado.jpg", "Cosme · de lado")

    # Primer plano: las 5 caras (la de hablar es la que se alterna al decir una frase)
    head = [p for p in idle if p["Name"] == "Head" or p["Name"].startswith(("Hair", "Goggle"))]
    lo, hi = R.bounds([p for p in idle if p["Name"] == "Head"])
    focus = ((lo + hi) / 2 + np.array([0, 0.25, 0])).tolist()
    labels = [("grin", "Sonrisa loca"), ("skeptic", "Escéptico"), ("laugh", "Riéndose"), ("scared", "Asustado"), ("talk", "Hablando (boca abierta)")]
    cw, ch = 360, 400
    canvas = R.background(cw * 5 + 60, ch + 130)
    for i, (key, label) in enumerate(labels):
        img, em, cam = R.view(head, -12, cw, ch - 20, faces[key], dist=5.6, fov=30, focus=focus, pitch=3)
        R.composite(canvas, img, em, (10 + i * (cw + 10), 50))
        d = ImageDraw.Draw(canvas)
        f = R.font(R.FONT_BOLD, 20)
        tw = d.textlength(label, font=f)
        d.text((10 + i * (cw + 10) + (cw - tw) / 2, ch + 36), label, font=f, fill=(235, 244, 255))
    stamp(canvas, "Cosme · primer plano: una sola boca en cada cara")
    path = os.path.join(OUT, "cosme-primer-plano.jpg")
    canvas.convert("RGB").save(path, quality=88)
    print("✅", os.path.relpath(path, ROOT))

    # Antes / después del bug: cabeza dinámica (su cara con boca pintada) + el Decal de Cosme encima
    before = over(default_dynamic_face(faces["grin"].shape[0]), faces["grin"])
    canvas = R.background(2 * cw + 90, ch + 130)
    for i, (face, label) in enumerate(((before, "ANTES: 2 bocas"), (faces["grin"], "DESPUÉS: 1 boca"))):
        img, em, cam = R.view(head, -12, cw, ch - 20, face, dist=5.6, fov=30, focus=focus, pitch=3)
        R.composite(canvas, img, em, (10 + i * (cw + 10), 50))
        d = ImageDraw.Draw(canvas)
        f = R.font(R.FONT_BOLD, 16)
        tw = d.textlength(label, font=f)
        d.text((10 + i * (cw + 10) + (cw - tw) / 2, ch + 36), label, font=f, fill=(255, 210, 120) if i == 0 else (160, 255, 170))
    stamp(canvas, "El bug de las dos bocas (simulado)")
    path = os.path.join(OUT, "cosme-dos-bocas-antes-despues.jpg")
    canvas.convert("RGB").save(path, quality=88)
    print("✅", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
