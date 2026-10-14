"""Vista cenital rápida (sin Blender) de la ciudad YA CONSTRUIDA, con los problemas de la auditoría
de coherencia del mapa encima (scripts/test-mapcoherence.luau --json).

Uso (desde la carpeta roblox/):
  lune run scripts/map/export.luau X.rbxl DIR                  # DIR/parts.tsv
  lune run scripts/test-mapcoherence.luau X.rbxl --json DIR/coherencia.json
  python3 scripts/map/vista_cenital.py DIR/parts.tsv SALIDA.png [--issues DIR/coherencia.json]
          [--box X0,Z0,X1,Z1] [--scale STUDS_POR_PIXEL] [--heat] [--title "texto"]

  --box     la zona a dibujar en studs (por defecto, toda la isla)
  --scale   studs por píxel (por defecto 2 para la isla entera; usa 0.5 para un barrio)
  --heat    mapa de calor de los problemas (en vez de solo los círculos)

Las piezas se dibujan de abajo arriba (por su altura), con su color y un poco de sombra según la
altura: así se ven las calles, las manzanas y los edificios como desde un avión.
"""

import argparse
import json
import math
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SEVERITY_COLOR = {
    "critical": (230, 30, 40),
    "warning": (255, 170, 0),
    "info": (40, 140, 255),
}


def load_parts(path, box):
    x0, z0, x1, z1 = box
    out = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 8:
                continue
            shape, top, bottom, color = cols[0], float(cols[1]), float(cols[2]), cols[3]
            if top > 400:
                continue
            corners = [tuple(map(float, c.split(","))) for c in cols[7].split(";")]
            xs = [c[0] for c in corners]
            zs = [c[2] for c in corners]
            if max(xs) < x0 or min(xs) > x1 or max(zs) < z0 or min(zs) > z1:
                continue
            rgb = tuple(int(v) for v in color.split(","))
            transp = float(cols[5])
            center = cols[6].split(",")
            out.append((top, shape, rgb, transp, corners, center))
    out.sort(key=lambda p: p[0])
    return out


def hull(points):
    pts = sorted(set(points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def shade(rgb, top):
    # más claro cuanto más alto (como el sol de mediodía), y las cosas a ras de suelo tal cual
    k = 1.0 + max(0.0, min(top, 120.0)) / 400.0
    return tuple(max(0, min(255, int(c * k))) for c in rgb)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tsv")
    ap.add_argument("out")
    ap.add_argument("--issues")
    ap.add_argument("--box")
    ap.add_argument("--scale", type=float)
    ap.add_argument("--heat", action="store_true")
    ap.add_argument("--title")
    ap.add_argument("--only", help="solo estos tipos de problema (separados por comas)")
    args = ap.parse_args()

    box = (-5000.0, -4400.0, 5000.0, 4300.0)
    if args.box:
        box = tuple(float(v) for v in args.box.split(","))
    scale = args.scale or (2.0 if (box[2] - box[0]) > 3000 else 0.5)
    x0, z0, x1, z1 = box
    W, H = int((x1 - x0) / scale), int((z1 - z0) / scale)
    img = Image.new("RGB", (W, H), (58, 112, 150))
    draw = ImageDraw.Draw(img)

    def px(x, z):
        return ((x - x0) / scale, (z - z0) / scale)

    # La isla (el terreno lo pone TerrainBuilder al arrancar: no está en parts.tsv): plan.json al lado
    import os

    plan_path = os.path.join(os.path.dirname(os.path.abspath(args.tsv)), "plan.json")
    if os.path.exists(plan_path):
        with open(plan_path, encoding="utf-8") as f:
            plan = json.load(f)
        draw.polygon([px(p[0], p[1]) for p in plan["Coast"]], fill=(122, 150, 96))
        for isl in plan.get("Islands", []):
            cx, cy = px(isl["X"], isl["Z"])
            r = isl["R"] / scale
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(122, 150, 96))
        for lake in plan.get("Lakes", []):
            cx, cy = px(lake["X"], lake["Z"])
            r = lake["R"] / scale
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(70, 130, 170))
        riv = plan.get("River")
        if riv:
            draw.line([px(p[0], p[1]) for p in riv["Points"]], fill=(70, 130, 170), width=max(1, int(riv["Width"] / scale)))

    parts = load_parts(args.tsv, box)
    for top, shape, rgb, transp, corners, center in parts:
        color = shade(rgb, top)
        if transp > 0.05:
            # agua y cristales: mezcla con lo de debajo (aprox.: más claro)
            color = tuple(int(c * (1 - transp * 0.5) + 200 * transp * 0.5) for c in color)
        if shape in ("Disc", "Ball"):
            cx, cy = px(float(center[0]), float(center[2]))
            r = float(center[8] if shape == "Ball" else center[7]) / scale
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
            continue
        poly = hull([(round(c[0], 1), round(c[2], 1)) for c in corners])
        if len(poly) < 3:
            continue
        draw.polygon([px(p[0], p[1]) for p in poly], fill=color)

    issues = []
    if args.issues:
        with open(args.issues, encoding="utf-8") as f:
            data = json.load(f)
        issues = data.get("issues", [])
        if args.only:
            keep = set(args.only.split(","))
            issues = [i for i in issues if i["kind"] in keep]

    if args.heat and issues:
        # acumulado: cada problema suma un disco suave
        r = max(6, int(90 / scale))
        heat = Image.new("F", (W, H), 0.0)
        disc = Image.new("F", (2 * r + 1, 2 * r + 1), 0.0)
        dd = disc.load()
        for yy in range(2 * r + 1):
            for xx in range(2 * r + 1):
                d = math.hypot(xx - r, yy - r) / r
                dd[xx, yy] = max(0.0, 1.0 - d) ** 1.5
        hp = heat.load()
        for i in issues:
            w = {"critical": 3.0, "warning": 1.5, "info": 0.5}.get(i["severity"], 1.0)
            cx, cy = px(i["x"], i["z"])
            cx, cy = int(cx), int(cy)
            for yy in range(-r, r + 1, 1):
                py = cy + yy
                if py < 0 or py >= H:
                    continue
                for xx in range(-r, r + 1, 1):
                    pxx = cx + xx
                    if 0 <= pxx < W:
                        v = dd[xx + r, yy + r]
                        if v > 0:
                            hp[pxx, py] += v * w
        mx = max(1e-6, max(heat.getdata()))
        lvl = heat.point(lambda v: min(255, v / mx * 255 * 1.6)).convert("L")
        red = Image.new("RGB", (W, H), (255, 40, 20))
        img = Image.composite(red, img, lvl.point(lambda v: int(v * 0.75)))
        draw = ImageDraw.Draw(img)

    for i in issues:
        cx, cy = px(i["x"], i["z"])
        col = SEVERITY_COLOR.get(i["severity"], (255, 255, 255))
        r = max(4, (i.get("r", 20)) / scale)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=max(2, int(3 / max(scale, 0.5))))

    if args.title:
        try:
            font = ImageFont.truetype("DejaVuSans-Bold.ttf", max(14, W // 60))
        except OSError:
            font = ImageFont.load_default()
        draw.rectangle([0, 0, W, max(24, W // 60) + 16], fill=(20, 24, 30))
        draw.text((10, 6), args.title, fill=(255, 255, 255), font=font)

    img.save(args.out, quality=88)
    print("ok", args.out, W, H, len(parts), "piezas", len(issues), "problemas")


if __name__ == "__main__":
    sys.exit(main())
