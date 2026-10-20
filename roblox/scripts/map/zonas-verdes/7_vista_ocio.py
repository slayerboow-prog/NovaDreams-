#!/usr/bin/env python3
"""Vista en perspectiva (isométrica) de cada sitio de ocio, hecha con las piezas de la ciudad construida.

Uso (desde roblox/; DIR = la carpeta de scripts/map/export.luau, de la ciudad CON los sitios de ocio):
    python3 scripts/map/zonas-verdes/7_vista_ocio.py DIR docs/zonas-verdes

Dibuja cada pieza (cajas, cuñas, cilindros y bolas como cajas o rombos) con sus caras de color y luz
plana, de lejos a cerca (algoritmo del pintor), alrededor del rectángulo de cada sitio de
src/shared/OcioSitios.luau. Escribe ocio-<sitio>.jpg y ocio-sitios.jpg (las cinco juntas)."""
import math, re, sys
import numpy as np, cv2

D = sys.argv[1]
OUT = sys.argv[2] if len(sys.argv) > 2 else "docs/zonas-verdes"
src = open("src/shared/OcioSitios.luau", encoding="utf-8").read()
sites = re.findall(r'Id = "(\w+)", Zone = (\d+), Name = "([^"]+)".*?Center = \{ (-?\d+), (-?\d+) \}, Size = \{ (\d+), (\d+) \}', src)

parts = []
with open(f"{D}/parts.tsv") as f:
    for line in f:
        c = line.rstrip("\n").split("\t")
        if len(c) < 10:
            continue
        pts = np.array([[float(v) for v in k.split(",")] for k in c[7].split(";")])
        col = tuple(int(v) for v in c[3].split(","))
        parts.append((c[0], pts, col, float(c[5]), c[4]))
print("piezas", len(parts))

# Caras de una caja (índices de esquinas: ix*4 + iy*2 + iz)
BOX = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
# Cuña: suelo, trasera (+Z), dos lados (triángulos) y la rampa
WEDGE = [(0, 4, 5, 1), (1, 5, 7, 3), (0, 1, 3), (4, 7, 5), (0, 3, 7, 4)]
LIGHT = np.array([-0.45, 0.8, -0.35]); LIGHT /= np.linalg.norm(LIGHT)


def render(sid, cx, cz, w, d, scale=2.2, yaw=math.radians(35), pitch=math.radians(42)):
    margin = 50
    x0, x1, z0, z1 = cx - w / 2 - margin, cx + w / 2 + margin, cz - d / 2 - margin, cz + d / 2 + margin
    fwd = np.array([math.sin(yaw) * math.cos(pitch), -math.sin(pitch), -math.cos(yaw) * math.cos(pitch)])  # hacia donde mira
    right = np.array([math.cos(yaw), 0, math.sin(yaw)])
    up = np.cross(right, fwd); up /= np.linalg.norm(up)
    faces = []
    for shape, pts, col, transp, mat in parts:
        mx, mz = pts[:, 0].mean(), pts[:, 2].mean()
        if not (x0 <= mx <= x1 and z0 <= mz <= z1) or transp >= 0.95:
            continue
        idx = WEDGE if shape == "Wedge" else BOX
        centre = pts.mean(axis=0)
        # Lo plano (suelos, asfalto, pistas, líneas) va en una capa de suelo, de abajo arriba: si no, una
        # losa grande taparía lo que tiene detrás (su centro queda más cerca que las cosas del fondo)
        flat = shape != "Wedge" and pts[:, 1].max() - pts[:, 1].min() < 1.6
        for face in idx:
            poly = pts[list(face)]
            n = np.cross(poly[1] - poly[0], poly[2] - poly[0])
            ln = np.linalg.norm(n)
            if ln < 1e-9:
                continue
            n /= ln
            if np.dot(n, poly.mean(axis=0) - centre) < 0:
                n = -n
            if np.dot(n, fwd) >= 0:
                continue  # (la cara no mira a la cámara)
            shade = 0.55 + 0.45 * max(0.0, float(np.dot(n, LIGHT)))
            if mat == "Neon":
                shade = 1.15
            c = tuple(min(255, int(v * shade)) for v in col)
            if flat:
                if n[1] < 0.5:
                    continue
                key = (0, float(pts[:, 1].max()), 0.0)
            else:
                key = (1, 0.0, -float(np.dot(poly.mean(axis=0), fwd)))
            faces.append((key, poly, c, transp))
    faces.sort(key=lambda t: t[0])
    # Encuadre: el rectángulo del sitio
    corners = np.array([[x, -1, z] for x in (x0, x1) for z in (z0, z1)])
    sx = corners @ right; sy = corners @ up
    W = int((sx.max() - sx.min()) * scale) + 40
    H = int((sy.max() - sy.min()) * scale) + 80
    img = np.zeros((H, W, 3), np.uint8)
    img[:] = (78, 128, 92)  # césped (BGR)
    ox, oy = sx.min(), sy.max()

    def proj(p):
        return np.stack([((p @ right) - ox) * scale + 20, (oy - (p @ up)) * scale + 60], axis=1).astype(np.int32)

    ground = proj(np.array([[x0, -1, z0], [x1, -1, z0], [x1, -1, z1], [x0, -1, z1]]))
    cv2.fillConvexPoly(img, ground, (92, 150, 104))
    for depth, poly, c, transp in faces:
        bgr = (c[2], c[1], c[0])
        p2 = proj(poly)
        if transp > 0.05:
            over = img.copy()
            cv2.fillPoly(over, [p2], bgr)
            img = cv2.addWeighted(over, 1 - transp, img, transp, 0)
        else:
            cv2.fillPoly(img, [p2], bgr)
            cv2.polylines(img, [p2], True, tuple(int(v * 0.75) for v in bgr), 1, cv2.LINE_AA)
    return img


tiles = []
for sid, zone, name, cx, cz, w, d in sites:
    img = render(sid, float(cx), float(cz), float(w), float(d))
    cv2.rectangle(img, (0, 0), (img.shape[1], 46), (30, 30, 30), -1)
    cv2.putText(img, f"Zona {zone} - {name}", (14, 32), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 255, 255), 2, cv2.LINE_AA)
    path = f"{OUT}/ocio-{sid.lower()}.jpg"
    cv2.imwrite(path, img, [cv2.IMWRITE_JPEG_QUALITY, 86])
    print("escrito", path, img.shape)
    tiles.append(img)
# Las cinco juntas (alto común)
h = 520
row = [cv2.resize(t, (int(t.shape[1] * h / t.shape[0]), h)) for t in tiles]
top = np.hstack(row[:3]); bottom = np.hstack(row[3:])
width = max(top.shape[1], bottom.shape[1])
pad = lambda im: np.hstack([im, np.full((im.shape[0], width - im.shape[1], 3), 30, np.uint8)])
sheet = np.vstack([pad(top), pad(bottom)])
cv2.imwrite(f"{OUT}/ocio-sitios.jpg", sheet, [cv2.IMWRITE_JPEG_QUALITY, 84])
print("escrito", f"{OUT}/ocio-sitios.jpg", sheet.shape)
