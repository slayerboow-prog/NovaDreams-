#!/usr/bin/env python3
"""Vista desde arriba de los sitios nuevos de las zonas verdes (fase 1), a partir de la ciudad
construida y exportada con scripts/map/export.luau.

Uso (desde roblox/):
    rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
    lune run scripts/map/export.luau X.rbxl DIR
    python3 scripts/map/zonas-verdes/6_sitios.py DIR docs/zonas-verdes/sitios-fase1.png

Pinta cada pieza con su color (de abajo arriba), con un poco de sombra según la altura, en seis
recuadros: Jardines de la Plaza Mayor (21), Huertos de la Puerta de Villaverde (19), Orilla del
Lago (17), Camping y dos parques vivos."""
import sys
import numpy as np, cv2

D, OUT = sys.argv[1], sys.argv[2]
PX = 4  # pixeles por stud
PANELS = [
    ("21 · Jardines de la Plaza Mayor", (-200, -16, -360, -198)),
    ("19 · Huertos de la Puerta de Villaverde", (-1590, -1410, -1862, -1738)),
    ("17 · Orilla del Lago: picnic y hoguera", (-3100, -2940, -146, -34)),
    ("Camping: tiendas, hoguera y parcelas", (-2600, -2390, -1080, -900)),
    ("Parque vivo (Oeste)", (-1855, -1631, 381, 605)),
    ("Parque vivo (Centro)", (888, 1112, 638, 862)),
]
rows = []
with open(f"{D}/parts.tsv") as f:
    for line in f:
        c = line.rstrip("\n").split("\t")
        if len(c) < 10:
            continue
        pts = [tuple(map(float, k.split(","))) for k in c[7].split(";")]
        rows.append((float(c[1]), tuple(int(v) for v in c[3].split(",")), float(c[5]), c[0], pts, c[6]))
rows.sort(key=lambda r: r[0])

def panel(title, box):
    x0, x1, z0, z1 = box
    w, h = int((x1 - x0) * PX), int((z1 - z0) * PX)
    img = np.full((h, w, 3), (60, 110, 70), np.uint8)
    for top, rgb, transp, shape, pts, center in rows:
        xs = [p[0] for p in pts]; zs = [p[2] for p in pts]
        if max(xs) < x0 or min(xs) > x1 or max(zs) < z0 or min(zs) > z1 or transp > 0.8 or top < -3:
            continue
        shade = min(1.25, 0.8 + max(0.0, top) / 40)
        col = tuple(int(min(255, v * shade)) for v in rgb[::-1])
        if shape in ("Disc", "Ball"):
            v = center.split(",")
            r = float(v[-1]) if shape == "Ball" else float(v[-2])
            cv2.circle(img, (int((float(v[0]) - x0) * PX), int((float(v[2]) - z0) * PX)), max(1, int(r * PX)), col, -1, cv2.LINE_AA)
        else:
            hull = cv2.convexHull(np.array([((p[0] - x0) * PX, (p[2] - z0) * PX) for p in pts], np.float32))
            cv2.fillConvexPoly(img, np.round(hull).astype(np.int32), col, cv2.LINE_AA)
    img = cv2.resize(img, (560, int(560 * h / w)), interpolation=cv2.INTER_AREA)
    bar = np.full((34, img.shape[1], 3), (32, 36, 44), np.uint8)
    cv2.putText(bar, title, (10, 23), cv2.FONT_HERSHEY_SIMPLEX, 0.58, (240, 240, 240), 1, cv2.LINE_AA)
    return np.vstack([bar, img])

tiles = [panel(t, b) for t, b in PANELS]
H = max(t.shape[0] for t in tiles)
tiles = [np.vstack([t, np.full((H - t.shape[0], t.shape[1], 3), (32, 36, 44), np.uint8)]) for t in tiles]
grid = np.vstack([np.hstack(tiles[i:i + 3]) for i in range(0, len(tiles), 3)])
cv2.imwrite(OUT, grid)
print("✅", OUT, grid.shape[1], "x", grid.shape[0])
