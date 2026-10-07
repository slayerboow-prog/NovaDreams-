#!/usr/bin/env python3
"""Dibuja los planos de la auditoría de cinemáticas (scripts/audit/cine-planos.luau).

Uso:  python3 scripts/audit/cine-render.py DIR/escenas.json DIR/img [--max N]

Por cada plano con fallos (y hasta 3 planos de cada escena buena de la muestra) genera un PNG con tres
vistas, todas con las piezas del mapa como cajas:
  1. ARRIBA: planta (solo la «rebanada» de alturas donde están los personajes y la cámara, para que los
     techos no lo tapen todo). La cámara es un triángulo con su campo de visión.
  2. LADO: corte vertical por el plano cámara-sujeto (se ve la altura de la cámara, suelos y techos).
  3. CÁMARA: lo que vería la cámara (proyección en perspectiva de las cajas, de lejos a cerca).
Personajes: cajas de 2x5x1 (escaladas); quien tiene que salir, en naranja; el resto, en azul; tú, verde.
Las imágenes no se suben al repositorio (van a la carpeta que se le diga).
"""
import json
import math
import os
import sys
import unicodedata

import cv2
import numpy as np

W, H = 520, 400  # cada vista
ASPECT = 16 / 9


def ascii(s):
    s = unicodedata.normalize("NFKD", str(s))
    return "".join(c for c in s if ord(c) < 128)


def box_corners(p, r, s):
    """Esquinas de una caja: centro p, ejes r (9 números: right, up, back), tamaño s."""
    c = np.array(p, float)
    rx = np.array(r[0:3], float)
    ry = np.array(r[3:6], float)
    rz = np.array(r[6:9], float)
    hx, hy, hz = s[0] / 2, s[1] / 2, s[2] / 2
    out = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                out.append(c + rx * hx * sx + ry * hy * sy + rz * hz * sz)
    return np.array(out)


# Caras de la caja (índices de esquinas: bit 0 = z, bit 1 = y, bit 2 = x)
FACES = [
    (0, 1, 3, 2),  # x-
    (4, 6, 7, 5),  # x+
    (0, 4, 5, 1),  # y-
    (2, 3, 7, 6),  # y+
    (0, 2, 6, 4),  # z-
    (1, 5, 7, 3),  # z+
]


def person_box(person):
    f = np.array(person["Facing"], float)
    f[1] = 0
    n = np.linalg.norm(f)
    f = f / n if n > 1e-3 else np.array([0, 0, -1.0])
    up = np.array([0, 1.0, 0])
    right = np.cross(f, up)
    s = person["Scale"]
    feet = np.array(person["Feet"], float)
    center = feet + up * 2.0 * s
    r = list(right) + list(up) + list(-f)
    return center, r, [2 * s, 4 * s, 1.1 * s]


def color_for(name, base=(170, 170, 170)):
    h = abs(hash(name)) % 40 - 20
    return tuple(int(max(40, min(230, c + h))) for c in base)


class Scene:
    def __init__(self, data):
        self.data = data
        self.parts = []
        for p in data["Parts"]:
            corners = box_corners(p["P"], p["R"], p["S"])
            self.parts.append((p, corners))


def to_px(x, y, bounds):
    (x0, x1, y0, y1) = bounds
    sx = (x - x0) / (x1 - x0) * (W - 20) + 10
    sy = H - ((y - y0) / (y1 - y0) * (H - 40) + 10)
    return int(sx), int(sy)


def fit_bounds(points, pad=4.0, square=True):
    pts = np.array(points)
    x0, y0 = pts.min(axis=0) - pad
    x1, y1 = pts.max(axis=0) + pad
    if square:
        # misma escala en los dos ejes
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        span = max(x1 - x0, (y1 - y0) * (W - 20) / (H - 40))
        span = max(span, 16)
        hx = span / 2
        hy = span * (H - 40) / (W - 20) / 2
        return cx - hx, cx + hx, cy - hy, cy + hy
    return x0, x1, y0, y1


def draw_people(img, people, subjects, project, depth_sort=None):
    items = []
    for person in people:
        center, r, s = person_box(person)
        corners = box_corners(center, r, s)
        pid = person["Id"]
        if pid in subjects:
            col = (40, 140, 255)
        elif pid == "Yo":
            col = (60, 190, 60)
        else:
            col = (220, 140, 60)
        items.append((pid, corners, col, person))
    return items


def view_top(sc, shot, cam):
    people = shot["People"]
    subj = set(shot["Subjects"])
    pos = np.array(cam["Pos"])
    pts = [(pos[0], pos[2])] + [(p["Feet"][0], p["Feet"][2]) for p in people if np.linalg.norm(np.array(p["Feet"]) - pos) < 60]
    b = fit_bounds(pts, pad=6)
    img = np.full((H, W, 3), 245, np.uint8)
    feet_y = min(p["Feet"][1] for p in people) if people else pos[1]
    top_y = max([pos[1]] + [p["Feet"][1] + 5 for p in people]) + 1
    polys = []
    for p, corners in sc.parts:
        ys = corners[:, 1]
        if ys.max() < feet_y - 1.5 or ys.min() > top_y:
            continue
        hull = cv2.convexHull(np.array([to_px(c[0], c[2], b) for c in corners], np.int32))
        floor = ys.max() < feet_y + 0.6
        polys.append((ys.max(), hull, floor, p["N"]))
    polys.sort(key=lambda t: t[0])
    for _, hull, floor, name in polys:
        col = (225, 225, 215) if floor else color_for(name, (150, 150, 150))
        cv2.fillPoly(img, [hull], col)
        cv2.polylines(img, [hull], True, (120, 120, 120) if not floor else (200, 200, 190), 1)
    for pid, corners, col, person in draw_people(img, people, subj, None):
        hull = cv2.convexHull(np.array([to_px(c[0], c[2], b) for c in corners], np.int32))
        cv2.fillPoly(img, [hull], col)
        fx, fz = person["Feet"][0], person["Feet"][2]
        f = person["Facing"]
        cv2.arrowedLine(img, to_px(fx, fz, b), to_px(fx + f[0] * 2, fz + f[2] * 2, b), (0, 0, 0), 1)
        cv2.putText(img, ascii(pid), to_px(fx + 0.8, fz + 0.8, b), cv2.FONT_HERSHEY_SIMPLEX, 0.38, (0, 0, 0), 1)
    # cámara (y su recorrido)
    for c in shot["Cams"]:
        cv2.circle(img, to_px(c["Pos"][0], c["Pos"][2], b), 2, (0, 0, 200), -1)
    look = np.array(cam["Look"])
    fl = np.array([look[0], 0, look[2]])
    if np.linalg.norm(fl) > 1e-3:
        fl /= np.linalg.norm(fl)
        half = math.atan(math.tan(math.radians(shot["Fov"]) / 2) * ASPECT)
        for a in (-half, half):
            d = np.array([fl[0] * math.cos(a) - fl[2] * math.sin(a), 0, fl[0] * math.sin(a) + fl[2] * math.cos(a)])
            e = pos + d * 25
            cv2.line(img, to_px(pos[0], pos[2], b), to_px(e[0], e[2], b), (0, 0, 220), 1)
    cv2.circle(img, to_px(pos[0], pos[2], b), 5, (0, 0, 220), -1)
    cv2.putText(img, "ARRIBA", (8, H - 8), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 0), 1)
    return img


def view_side(sc, shot, cam):
    people = shot["People"]
    subj = set(shot["Subjects"])
    pos = np.array(cam["Pos"])
    look = np.array(cam["Look"])
    fl = np.array([look[0], 0, look[2]])
    fl = fl / np.linalg.norm(fl) if np.linalg.norm(fl) > 1e-3 else np.array([0, 0, -1.0])
    side = np.cross(fl, [0, 1, 0])  # hacia la derecha de la cámara

    def proj(p):
        d = np.array(p) - pos
        return float(d @ fl), float(p[1])

    targets = [p for p in people if p["Id"] in subj] or people
    pts = [proj(pos)] + [proj(np.array(p["Feet"]) + [0, 5 * p["Scale"], 0]) for p in targets] + [proj(p["Feet"]) for p in targets]
    b = fit_bounds(pts, pad=5)
    img = np.full((H, W, 3), 245, np.uint8)
    polys = []
    for p, corners in sc.parts:
        dd = (corners - pos) @ side
        if dd.min() > 5 or dd.max() < -5:
            continue
        hull = cv2.convexHull(np.array([to_px(*proj(c), b) for c in corners], np.int32))
        polys.append((-abs(float(np.mean(dd))), hull, p["N"]))
    polys.sort(key=lambda t: t[0])
    for _, hull, name in polys:
        cv2.fillPoly(img, [hull], color_for(name, (165, 165, 160)))
        cv2.polylines(img, [hull], True, (110, 110, 110), 1)
    for pid, corners, col, person in draw_people(img, people, subj, None):
        dd = (corners - pos) @ side
        if dd.min() > 8 or dd.max() < -8:
            continue
        hull = cv2.convexHull(np.array([to_px(*proj(c), b) for c in corners], np.int32))
        cv2.fillPoly(img, [hull], col)
        x, y = proj(np.array(person["Feet"]) + [0, 5.2 * person["Scale"], 0])
        cv2.putText(img, ascii(pid), to_px(x, y, b), cv2.FONT_HERSHEY_SIMPLEX, 0.38, (0, 0, 0), 1)
    for c in shot["Cams"]:
        cv2.circle(img, to_px(*proj(c["Pos"]), b), 2, (0, 0, 200), -1)
    p0 = to_px(*proj(pos), b)
    e = pos + look * 8
    cv2.arrowedLine(img, p0, to_px(*proj(e), b), (0, 0, 220), 2)
    cv2.circle(img, p0, 5, (0, 0, 220), -1)
    cv2.putText(img, "LADO (corte por la camara)", (8, H - 8), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 0), 1)
    return img


def view_camera(sc, shot, cam):
    people = shot["People"]
    subj = set(shot["Subjects"])
    pos = np.array(cam["Pos"], float)
    look = np.array(cam["Look"], float)
    up = np.array(cam["Up"], float)
    right = np.cross(look, up)
    fov = math.radians(shot["Fov"])
    ty = math.tan(fov / 2)
    tx = ty * ASPECT
    near = 0.1
    img = np.full((H, W, 3), (235, 215, 190), np.uint8)  # cielo
    polys = []

    def cam_space(pts):
        d = pts - pos
        return np.stack([d @ right, d @ up, d @ look], axis=1)

    def clip(poly):
        out = []
        n = len(poly)
        for i in range(n):
            a, b = poly[i], poly[(i + 1) % n]
            ain, bin_ = a[2] >= near, b[2] >= near
            if ain:
                out.append(a)
            if ain != bin_:
                t = (near - a[2]) / (b[2] - a[2])
                out.append(a + (b - a) * t)
        return out

    def screen(p):
        x = p[0] / (p[2] * tx)
        y = p[1] / (p[2] * ty)
        return [int((x + 1) / 2 * W), int((1 - y) / 2 * H)]

    def add(corners, col, light=True):
        cs = cam_space(corners)
        if cs[:, 2].max() < near:
            return
        center = corners.mean(axis=0)
        for f in FACES:
            poly = [cs[i] for i in f]
            # cara hacia la cámara (normal hacia fuera desde el centro de la caja)
            fc = corners[list(f)].mean(axis=0)
            nrm = fc - center
            if np.dot(nrm, fc - pos) > 0 and np.linalg.norm(nrm) > 1e-4:
                continue
            poly = clip(poly)
            if len(poly) < 3:
                continue
            depth = float(np.mean([p[2] for p in poly]))
            nrm_u = nrm / (np.linalg.norm(nrm) + 1e-9)
            shade = 0.65 + 0.35 * abs(nrm_u[1]) if light else 1
            c = tuple(int(v * shade) for v in col)
            pts = np.array([screen(p) for p in poly], np.int32)
            pts = np.clip(pts, -20000, 20000)
            polys.append((depth, pts, c))

    for p, corners in sc.parts:
        add(corners, color_for(p["N"], (170, 165, 155)))
    for pid, corners, col, person in draw_people(img, people, subj, None):
        add(corners, col)
        # cabeza
        s = person["Scale"]
        head = np.array(person["Feet"]) + [0, 4.5 * s, 0]
        hc = box_corners(head, [1, 0, 0, 0, 1, 0, 0, 0, 1], [1.2 * s, 1.2 * s, 1.2 * s])
        add(hc, (90, 200, 250) if pid in subj else (200, 210, 220))
    polys.sort(key=lambda t: -t[0])
    for _, pts, c in polys:
        cv2.fillPoly(img, [pts], c)
        cv2.polylines(img, [pts], True, tuple(int(v * 0.7) for v in c), 1)
    # nombres de los sujetos
    for person in people:
        s = person["Scale"]
        head = np.array(person["Feet"]) + [0, 5.4 * s, 0]
        cs = cam_space(head[None, :])[0]
        if cs[2] > near:
            x, y = screen(cs)
            if 0 <= x < W and 0 <= y < H:
                cv2.putText(img, ascii(person["Id"]), (x - 10, y), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 0), 1)
    cv2.rectangle(img, (0, 0), (W - 1, H - 1), (0, 0, 0), 1)
    cv2.putText(img, "CAMARA (fov %d)" % shot["Fov"], (8, H - 8), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 0), 1)
    return img


def render_shot(sc, shot, idx, path, good):
    # fotograma: el primero de los que tienen problema... se usa el final del movimiento (lo que se queda)
    cam = shot["Cams"][-1]
    a = view_top(sc, shot, cam)
    b = view_side(sc, shot, cam)
    c = view_camera(sc, shot, cam)
    row = np.concatenate([a, b, c], axis=1)
    header = np.full((64, row.shape[1], 3), 255, np.uint8)
    title = "%s  | plano %d: %s" % (sc.data["Id"], idx, shot["Spec"])
    cv2.putText(header, ascii(title)[:150], (8, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1)
    probs = "; ".join("%s: %s" % (p["Kind"], p["Detail"]) for p in shot["Problems"]) or ("OK" if good else "")
    cv2.putText(header, ascii(probs)[:170], (8, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (0, 0, 180) if shot["Problems"] else (0, 130, 0), 1)
    line = shot.get("Line") or ""
    cv2.putText(header, ascii(line)[:170], (8, 58), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (80, 80, 80), 1)
    cv2.imwrite(path, np.concatenate([header, row], axis=0))


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    src, dst = sys.argv[1], sys.argv[2]
    limit = None
    if "--max" in sys.argv:
        limit = int(sys.argv[sys.argv.index("--max") + 1])
    os.makedirs(dst, exist_ok=True)
    data = json.load(open(src))
    count = 0
    for k, item in enumerate(data):
        sc = Scene(item)
        good = item.get("Good", False)
        safe = "".join(ch if ch.isalnum() else "_" for ch in ascii(item["Id"]))[:80]
        chosen = []
        for i, shot in enumerate(item["Shots"]):
            if shot["Problems"] or (good and len(chosen) < 3):
                chosen.append((i, shot))
        if not chosen and item["Shots"]:
            chosen.append((0, item["Shots"][0]))  # (escena con un actor mal puesto: su primer plano)
        for i, shot in chosen:
            name = "%s%03d_%s_p%02d.png" % ("ok_" if good else "", k, safe, i + 1)
            render_shot(sc, shot, i + 1, os.path.join(dst, name), good)
            count += 1
            if limit and count >= limit:
                print("%d imagenes en %s" % (count, dst))
                return
    print("%d imagenes en %s" % (count, dst))


if __name__ == "__main__":
    main()
