#!/usr/bin/env python3
"""Vistas previas del reparto ANTES y DESPUÉS del pase de texturas (docs/personajes/*.jpg). Todas llevan
la marca «VISTA PREVIA, NO ES ROBLOX»: es el rasterizador del proyecto (scripts/cosme/render.py) con las
piezas de verdad de World/Npc.dress (scripts/personajes/export-cuerpos.luau) y las PNG de
assets/personajes puestas como en Roblox (Shirt/Pants teñidas con Clothing.Color3, Decal «face»).
Los mechones del pelo (Texture) no se dibujan aquí.

  ANTES    colores lisos y la cara de la cabeza por defecto
  DESPUÉS  ropa con textura teñida, cara del personaje (expresión `--expresion`, Neutral por defecto)

Uso (desde roblox/):
    lune run scripts/personajes/export.luau
    lune run scripts/personajes/export-cuerpos.luau
    python3 scripts/personajes/gen.py
    python3 scripts/personajes/render.py
"""

import argparse
import importlib.util
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("cosme_render", os.path.join(HERE, "..", "cosme", "render.py"))
R = importlib.util.module_from_spec(spec)
spec.loader.exec_module(R)

ROOT = R.ROOT
ASSETS = os.path.join(ROOT, "assets", "personajes")
OUT = os.path.join(ROOT, "docs", "personajes")
MARK = "VISTA PREVIA, NO ES ROBLOX"

SAGA1 = ["Familia_Mama", "Familia_Papa", "Abu_Rosa", "Abu_Tomas", "Lucia", "Javier", "Carmen", "Ramon", "Pip",
         "Nico", "Sara", "Omar", "Mateo", "Dani", "Alex", "Vega", "Iker", "Bruno", "Ruben", "Hugo", "Leire", "Rayo", "Nerea", "Cosimo"]
SAGA2 = ["DaliaRenn", "GeneralCorvo", "TobiRenn", "DoctoraFermina", "MadreHollin", "Brasa", "IngenieroOrsi", "GaloPadre",
         "SargentoMurria", "ErnestoPanadero", "EscribanoLumo", "CapitanaFerra", "Varkun", "NILDA"]


def load_rgba(path):
    if not os.path.exists(path):
        return None
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.float32) / 255.0


def tinted(path, color):
    tex = load_rgba(path)
    if tex is None:
        return None
    out = tex.copy()
    out[..., :3] = out[..., :3] * (np.array(color, np.float32) / 255.0)
    return out


def default_face(size=256):
    """La cara de la cabeza por defecto (aproximada): dos ojos ovalados y una sonrisa."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size
    for cx in (0.38, 0.62):
        d.ellipse([s * (cx - 0.035), s * 0.42, s * (cx + 0.035), s * 0.53], fill=(25, 25, 25, 255))
    d.arc([s * 0.33, s * 0.52, s * 0.67, s * 0.76], 20, 160, fill=(25, 25, 25, 255), width=int(s * 0.024))
    return np.asarray(img, dtype=np.float32) / 255.0


def cloth_for(body, shirt_tex, pants_tex, short):
    c = {}
    for name, (which, rects, sl) in R.CLOTH.items():
        tex = shirt_tex if which is R.SHIRT else pants_tex
        if which is R.SHIRT and short and name in ("RightLowerArm", "LeftLowerArm"):
            tex = shirt_tex  # (la plantilla deja el antebrazo transparente: se ve la piel pintada)
        c[name] = (tex, rects, sl)
    return c


def scaled(parts, k):
    # (en el R15 de bloques el brazo y el antebrazo se solapan en el codo: un pelín más estrechos los de
    # abajo para que el rasterizador no los mezcle a dientes de sierra; en Roblox no pasa)
    thin = []
    for p in parts:
        if p["Name"] in ("LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg") and p.get("Body"):
            q = dict(p)
            q["Size"] = [p["Size"][0] * 0.97, p["Size"][1], p["Size"][2] * 0.97]
            thin.append(q)
        else:
            thin.append(p)
    parts = thin
    if k == 1:
        return parts
    lo, hi = R.bounds(parts)
    base = np.array([0, lo[1], 0])
    out = []
    for p in parts:
        q = dict(p)
        q["Pos"] = (base + (np.array(p["Pos"]) - base) * k).tolist()
        q["Size"] = (np.array(p["Size"]) * k).tolist()
        out.append(q)
    return out


def figure(key, body, data_by_key, after, expr, w, h):
    parts = body["Parts"]
    if after:
        shirt = body.get("Shirt")
        pants = body.get("Pants")
        st = tinted(os.path.join(ASSETS, "ropa", "pj_ropa_%s.png" % shirt.lower()), body["ShirtColor"]) if shirt else None
        pt = tinted(os.path.join(ASSETS, "ropa", "pj_pantalon_%s.png" % pants.lower()), body["PantsColor"]) if pants else None
        short = shirt in ("Camiseta", "Delantal")
        parts = [dict(p) for p in parts]
        if short:
            for p in parts:
                if p["Name"] in ("LeftLowerArm", "RightLowerArm"):
                    p["Color"] = body["Skin"]
        R.CLOTH = {}
        for name, (which, rects, sl) in CLOTH_BASE.items():
            R.CLOTH[name] = ((st if which == "S" else pt), rects, sl)
        fk = body.get("FaceKey") or key
        face = load_rgba(os.path.join(ASSETS, "caras", "pj_cara_%s_%s.png" % (fk.lower(), expr.lower())))
        if face is None:
            face = load_rgba(os.path.join(ASSETS, "caras", "pj_cara_%s_neutral.png" % fk.lower()))
    else:
        R.CLOTH = {}
        face = DEFAULT_FACE
    parts = scaled(parts, body.get("Scale", 1))
    img, em, cam = R.view(parts, -18, w, h, face, dist=17, fov=28, pitch=5, focus=FOCUS)
    return img, em, cam, parts


def sheet(keys, bodies, data_by_key, title, path, after, expr):
    keys = [k for k in keys if k in bodies]
    cols = min(8, len(keys))
    rows = math.ceil(len(keys) / cols)
    cw, ch = 230, 400
    W, H = cols * cw + 40, rows * (ch + 40) + 110
    canvas = R.background(W, H)
    d = ImageDraw.Draw(canvas)
    d.text((24, 18), title, font=R.font(R.FONT_BOLD, 30), fill=(235, 244, 255))
    for i, key in enumerate(keys):
        x = 20 + (i % cols) * cw
        y = 70 + (i // cols) * (ch + 40)
        img, em, cam, parts = figure(key, bodies[key], data_by_key, after, expr, cw, ch)
        fx, fy = R.feet_y(parts, cam)
        shadow = R.ground_shadow(img.width, img.height, fx, fy - 4, 46, 10)
        R.composite(canvas, img, em, (x, y), shadow)
        name = (data_by_key.get(key) or {}).get("Name", key)
        if name.startswith("NPC."):
            name = {"Familia_Mama": "Mamá", "Familia_Papa": "Papá", "Abu_Rosa": "Abu Rosa", "Abu_Tomas": "Abu Tomás", "Lucia": "Profe Lucía"}.get(key, name[4:].capitalize())
        f = R.font(R.FONT_BOLD, 17)
        d = ImageDraw.Draw(canvas)
        tw = d.textlength(name, font=f)
        d.text((x + (cw - tw) / 2, y + ch + 4), name, font=f, fill=(235, 244, 255))
    m = R.font(R.FONT_BOLD, 20)
    tw = d.textlength(MARK, font=m)
    d.rounded_rectangle([W - tw - 50, H - 48, W - 16, H - 12], radius=8, fill=(160, 30, 40, 235))
    d.text((W - tw - 33, H - 44), MARK, font=m, fill=(255, 255, 255))
    canvas.convert("RGB").save(path, quality=86)
    print("✅", os.path.relpath(path, ROOT))


def faces_sheet(data, keys, title, path):
    chars = {c["Key"]: c for c in data["Characters"]}
    keys = [k for k in keys if k in chars]
    exprs = data["Full"]
    cell = 150
    W = len(exprs) * cell + 260
    H = len(keys) * cell + 110
    canvas = R.background(W, H)
    d = ImageDraw.Draw(canvas)
    d.text((24, 18), title, font=R.font(R.FONT_BOLD, 28), fill=(235, 244, 255))
    for r, key in enumerate(keys):
        c = chars[key]
        skin = tuple((c.get("Colors") or {}).get("Skin") or (220, 180, 140))
        y = 70 + r * cell
        d.text((20, y + cell / 2 - 10), c.get("Name", key)[:22], font=R.font(R.FONT_BOLD, 16), fill=(235, 244, 255))
        for i, e in enumerate(exprs):
            path_face = os.path.join(ASSETS, "caras", "pj_cara_%s_%s.png" % (key.lower(), e.lower()))
            x = 240 + i * cell
            if r == 0:
                d.text((x + 10, 50), e, font=R.font(R.FONT, 15), fill=(200, 220, 245))
            if not os.path.exists(path_face):
                continue
            tile = Image.new("RGBA", (cell - 12, cell - 12), (0, 0, 0, 0))
            ImageDraw.Draw(tile).rounded_rectangle([0, 0, cell - 13, cell - 13], radius=30, fill=skin + (255,))
            tile.alpha_composite(Image.open(path_face).convert("RGBA").resize((cell - 12, cell - 12), Image.LANCZOS))
            canvas.alpha_composite(tile, (x, y))
    m = R.font(R.FONT_BOLD, 18)
    d = ImageDraw.Draw(canvas)
    tw = d.textlength(MARK, font=m)
    d.rounded_rectangle([W - tw - 46, H - 42, W - 14, H - 10], radius=8, fill=(160, 30, 40, 235))
    d.text((W - tw - 30, H - 38), MARK, font=m, fill=(255, 255, 255))
    canvas.convert("RGB").save(path, quality=86)
    print("✅", os.path.relpath(path, ROOT))


CLOTH_BASE = {}
DEFAULT_FACE = None
FOCUS = None


def main():
    global CLOTH_BASE, DEFAULT_FACE, FOCUS
    ap = argparse.ArgumentParser()
    ap.add_argument("--expresion", default="Neutral")
    args = ap.parse_args()
    data = json.load(open(os.path.join(HERE, "out", "personajes.json")))
    bodies = json.load(open(os.path.join(HERE, "out", "cuerpos.json")))
    by_key = {c["Key"]: c for c in data["Characters"]}
    for name, (which, rects, sl) in R.CLOTH.items():
        CLOTH_BASE[name] = ("S" if which is R.SHIRT else "P", rects, sl)
    DEFAULT_FACE = default_face()
    lo, hi = R.bounds(bodies["Lucia"]["Parts"])
    FOCUS = ((lo + hi) / 2).tolist()
    os.makedirs(OUT, exist_ok=True)
    sheet(SAGA1, bodies, by_key, "Saga 1 · reparto principal — ANTES (colores lisos, cara por defecto)", os.path.join(OUT, "reparto-saga1-antes.jpg"), False, args.expresion)
    sheet(SAGA1, bodies, by_key, "Saga 1 · reparto principal — DESPUÉS (texturas de cara y ropa)", os.path.join(OUT, "reparto-saga1-despues.jpg"), True, args.expresion)
    sheet(SAGA2, bodies, by_key, "Saga 2 · Tefra y el espacio — ANTES", os.path.join(OUT, "reparto-saga2-antes.jpg"), False, args.expresion)
    sheet(SAGA2, bodies, by_key, "Saga 2 · Tefra y el espacio — DESPUÉS", os.path.join(OUT, "reparto-saga2-despues.jpg"), True, args.expresion)
    faces_sheet(data, ["Familia_Mama", "Nico", "Sara", "Abu_Tomas", "Julian", "Iker", "Pip", "DaliaRenn", "Cosimo"], "Expresiones (Neutral · Happy · Talk = boca al hablar · Sad · Angry · Scared)", os.path.join(OUT, "caras-expresiones.jpg"))
    nacara = [c["Key"] for c in data["Characters"] if c["Kind"] == "Hondario"]
    faces_sheet(data, nacara + ["Varkun", "NILDA"], "Nácara (Hondarios) y caras especiales", os.path.join(OUT, "caras-nacara-y-especiales.jpg"))


if __name__ == "__main__":
    main()
