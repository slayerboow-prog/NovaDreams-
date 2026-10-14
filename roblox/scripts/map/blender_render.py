#!/usr/bin/env python3
"""La isla de Valmar en 3D (Blender, Cycles) para el MAPA GRANDE: la ciudad DE VERDAD con el estilo
ilustrado del dibujo de referencia del dueño (vista oblicua, verdes vivos, mar turquesa, sol cálido).

Necesita Blender como módulo de Python:   pip install bpy==4.2.0   (Python 3.11; renderiza en CPU)

Uso (desde la carpeta roblox/):
    rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
    lune run scripts/map/export.luau X.rbxl DIR
    python3 scripts/map/blender_render.py DIR [--out textures/mapa] [--width 4096] [--samples 48]

Escena (todo sale de la ciudad construida y de shared/CityPlan):
  * cada pieza visible de workspace.Town con su forma (caja, bola, cilindro), su color (más vivo) y su
    material: cristal que brilla, ventanas en las fachadas altas, tejados de colores;
  * el terreno: hierba con manchas, playas, rocas en los acantilados, montañas, río y lagos; el mar con
    bajíos turquesa, azul profundo y espuma en la costa (TerrainBuilder lo hace igual al arrancar);
  * árboles (copas redondas y pinos) en el campo, los montes, los parques y los jardines;
  * barcos en el puerto deportivo y en el de mercancías.
Cámara ortográfica inclinada TILT grados (mirando al norte), sol cálido con sombras suaves, oclusión
ambiental (Cycles), un poco de resplandor y color al final.

La proyección mundo -> imagen es EXACTA y sale de la cámara: se escribe en src/shared/MapProjection.luau
(la usan shared/MapScreen y Controllers/MapUI para tu flecha, los lugares, la ruta y los toques).
Salida: OUT/isla_<fila>_<columna>.png (4x3 trozos ≤ 1024, los sube scripts/upload-map.sh), OUT/preview.jpg
y OUT/meta.json.
"""
import argparse
import json
import math
import os
import sys
import time

import cv2
import numpy as np

# ----------------------------------------------------------------------------------------------------
# Cámara y proyección (la misma fórmula que shared/MapScreen.toArt)
# ----------------------------------------------------------------------------------------------------
TILT = 52.0  # grados desde la vertical (0 = desde arriba)
ORTHO_W = 10600.0  # studs de ancho que ve la cámara (la isla, con poco mar alrededor)
CX, CS = 50.0, 330.0  # centro de la imagen: X del mundo y coordenada «arriba» de la pantalla
COLS, ROWS = 4, 3
Y_EXAG = 2.0  # (las alturas de las piezas, x2: más volumen, como un mapa ilustrado; la planta es exacta)
TILE_H = 800  # (alto de cada trozo con 4096 de ancho)


def project(x, y, z, W, H):
    """Mundo de Roblox (X este, Y arriba, Z sur) -> píxel de la imagen (u, v)."""
    t = math.radians(TILT)
    spp = ORTHO_W / W
    s = -z * math.cos(t) + y * math.sin(t)
    return (x - CX) / spp + W / 2, H / 2 - (s - CS) / spp


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("--out", default="textures/mapa")
    ap.add_argument("--projection", default="src/shared/MapProjection.luau")
    ap.add_argument("--width", type=int, default=4096)
    ap.add_argument("--samples", type=int, default=48)
    ap.add_argument("--trees", type=float, default=1.0, help="densidad de árboles (1 = normal)")
    ap.add_argument("--preview", action="store_true", help="solo la imagen (sin trozos ni MapProjection)")
    return ap.parse_args()


# ----------------------------------------------------------------------------------------------------
# Utilidades
# ----------------------------------------------------------------------------------------------------
def noise(h, w, scale, seed):
    rng = np.random.default_rng(seed)
    out = np.zeros((h, w), np.float32)
    amp, total, s = 1.0, 0.0, scale
    for _ in range(4):
        gh, gw = max(2, int(h / s) + 2), max(2, int(w / s) + 2)
        out += amp * cv2.resize(rng.random((gh, gw)).astype(np.float32), (w, h), interpolation=cv2.INTER_CUBIC)
        total += amp
        amp *= 0.5
        s /= 2.2
    out /= total
    lo, hi = np.percentile(out, 1), np.percentile(out, 99)
    return np.clip((out - lo) / (hi - lo + 1e-6), 0, 1)


def lerp(a, b, t):
    t = t[..., None] if np.ndim(t) == 2 else t
    return a + (b - a) * t


def rgb(*c):
    return np.array(c, np.float32)


def srgb_to_linear(c):
    c = np.asarray(c, np.float32) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def stylise(col, mat):
    """El color de una pieza, con el estilo del dibujo: más vivo y cálido."""
    c = np.array([[col]], np.uint8)
    hsv = cv2.cvtColor(c, cv2.COLOR_RGB2HSV).astype(np.float32)[0, 0]
    s, v = 1.25, 1.0
    if mat in ("Grass", "LeafyGrass"):
        s, v = 1.35, 1.05
    elif mat == "Glass":
        s, v = 1.4, 1.0
    elif mat in ("ClayRoofTiles", "Slate", "Brick"):
        s, v = 1.45, 1.05
    elif mat in ("Asphalt",):
        s, v = 0.5, 0.95
    elif mat in ("Concrete", "Plaster", "SmoothPlastic", "Limestone", "Marble"):
        s, v = 1.1, 1.06
    hsv[1] = min(255, hsv[1] * s)
    hsv[2] = min(255, hsv[2] * v)
    return cv2.cvtColor(np.array([[hsv]], np.uint8), cv2.COLOR_HSV2RGB)[0, 0]


# ----------------------------------------------------------------------------------------------------
# Terreno (textura y alturas, a TEX studs por píxel)
# ----------------------------------------------------------------------------------------------------
TEX = 4.0
EXT = (-8000.0, 8000.0, -7000.0, 6500.0)  # X0, X1, Z0, Z1 del suelo (más allá de lo que ve la cámara)


def terrain(plan, parts_masks):
    x0, x1, z0, z1 = EXT
    W, H = int((x1 - x0) / TEX), int((z1 - z0) / TEX)

    def px(x, z):
        return ((x - x0) / TEX, (z - z0) / TEX)

    def poly_px(points):
        return np.array([px(p[0], p[1]) for p in points], np.float32)

    land = np.zeros((H, W), np.uint8)
    cv2.fillPoly(land, [np.round(poly_px(plan["Coast"])).astype(np.int32)], 255)
    for isl in plan["Islands"]:
        cx, cz = px(isl["X"], isl["Z"])
        cv2.circle(land, (int(cx), int(cz)), int(isl["R"] / TEX), 255, -1, cv2.LINE_AA)
    A = plan["Airport"]["Land"]
    ax0, az0 = px(A["X0"], A["Z0"])
    ax1, az1 = px(A["X1"], A["Z1"])
    cv2.rectangle(land, (int(ax0), int(az0)), (int(ax1), int(az1)), 255, -1)
    is_land = land > 127
    dist_in = cv2.distanceTransform(land, cv2.DIST_L2, 5) * TEX
    dist_out = cv2.distanceTransform(255 - land, cv2.DIST_L2, 5) * TEX

    n1, n2, n3 = noise(H, W, 300, 1), noise(H, W, 70, 2), noise(H, W, 20, 3)
    # Mar: azul profundo lejos, azul medio, bajíos turquesa y espuma en la orilla
    deep, mid, shallow, reef, foam = rgb(14, 76, 164), rgb(22, 132, 220), rgb(40, 210, 214), rgb(110, 232, 214), rgb(240, 252, 252)
    sea = lerp(mid, deep, np.clip(dist_out / 1800.0, 0, 1) ** 0.8)
    # (bajíos anchos y turquesa, con manchas, y un borde más claro de arrecife junto a la playa)
    sea = lerp(sea, shallow, np.clip(1 - (dist_out + (n2 - 0.5) * 160) / 420.0, 0, 1) ** 1.1)
    sea = lerp(sea, reef, np.clip(1 - (dist_out + (n3 - 0.5) * 40) / 90.0, 0, 1) * 0.7)
    waves = np.clip(noise(H, W, 9, 11) - 0.62, 0, 1) * 2.2
    sea = lerp(sea, rgb(200, 236, 250), waves * 0.25)
    sea *= (0.94 + 0.12 * n2)[..., None]
    for ring, width, amount in ((8, 8, 1.0), (30, 7, 0.5), (56, 7, 0.28), (90, 8, 0.14)):
        t = np.clip(1 - np.abs(dist_out - ring - (n2 - 0.5) * 12) / width, 0, 1) * (0.5 + 0.5 * n3)
        sea = lerp(sea, foam, t * amount)
    # Hierba con manchas (prados claros, bosque oscuro) y un poco de tierra seca
    g = lerp(rgb(70, 160, 52), rgb(112, 188, 62), n2)
    g = lerp(g, rgb(42, 120, 44), np.clip((n1 - 0.55) * 2.5, 0, 1) * 0.7)
    g = lerp(g, rgb(150, 150, 80), np.clip((n3 - 0.82) * 4, 0, 1) * 0.35)
    # Montañas: altura de los casquetes de esfera (como TerrainBuilder) y roca en las cumbres
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    wx, wz = xx * TEX + x0, yy * TEX + z0
    height = np.zeros((H, W), np.float32)
    rock = np.zeros((H, W), np.float32)
    for m in plan["Mountains"]:
        d2 = (wx - m["X"]) ** 2 + (wz - m["Z"]) ** 2
        height = np.maximum(height, np.maximum(np.sqrt(np.maximum(0, m["R"] ** 2 - d2)) - (m["R"] - m["H"]), 0))
        if m.get("Rock"):
            rock = np.maximum(rock, np.clip(1 - np.sqrt(d2) / (m["R"] * 0.42 * 1.1), 0, 1))
    g = lerp(g, rgb(140, 132, 118) * (0.85 + 0.3 * n3)[..., None], np.clip((rock - 0.45) * 2.5, 0, 1) * 0.8)
    # Playa (70 studs), arena mojada en la orilla, acantilados de roca en el norte
    sand = rgb(246, 226, 168)
    beach = np.clip((70 + (n2 - 0.5) * 24 - dist_in) / 10.0, 0, 1)
    land_col = lerp(g, sand, beach)
    land_col = lerp(land_col, rgb(214, 194, 140), np.clip(1 - dist_in / 12.0, 0, 1) * 0.6)
    coast = plan["Coast"]
    cliff = np.zeros((H, W), np.uint8)
    for a, c in plan["Cliffs"]:
        pts = [coast[(i - 1) % len(coast)] for i in range(a, c + 1)]
        cv2.polylines(cliff, [np.round(poly_px(pts)).astype(np.int32)], False, 255, int(120 / TEX))
    cliff_t = cv2.GaussianBlur(cliff, (0, 0), 4).astype(np.float32) / 255 * np.clip(1 - dist_in / 100, 0, 1)
    land_col = lerp(land_col, rgb(120, 112, 100) * (0.8 + 0.35 * n3)[..., None], np.clip(cliff_t * 1.8, 0, 1))
    col = np.where(is_land[..., None], land_col, sea)
    water = (~is_land).astype(np.float32)
    # Río y lagos (orilla de arena, agua turquesa)
    river = plan["River"]
    rpts = np.round(poly_px(river["Points"])).astype(np.int32)
    bank = np.zeros((H, W), np.uint8)
    wet = np.zeros((H, W), np.uint8)
    cv2.polylines(bank, [rpts], False, 255, int((river["Width"] + 40) / TEX), cv2.LINE_AA)
    cv2.polylines(wet, [rpts], False, 255, int(river["Width"] / TEX), cv2.LINE_AA)
    bank[~is_land] = 0  # (el río acaba en la costa)
    wet[~is_land] = 0
    for lake in plan["Lakes"]:
        cx, cz = px(lake["X"], lake["Z"])
        cv2.circle(bank, (int(cx), int(cz)), int((lake["R"] + 24) / TEX), 255, -1, cv2.LINE_AA)
        cv2.circle(wet, (int(cx), int(cz)), int(lake["R"] / TEX), 255, -1, cv2.LINE_AA)
    col = lerp(col, sand, bank.astype(np.float32) / 255 * is_land)
    wet_d = cv2.distanceTransform(wet, cv2.DIST_L2, 5) * TEX
    col = lerp(col, lerp(rgb(70, 200, 210), rgb(30, 140, 205), np.clip(wet_d / 35, 0, 1)), wet.astype(np.float32) / 255)
    water = np.maximum(water, wet.astype(np.float32) / 255)
    # Alturas: tierra a -1, montañas encima, mar a -4 (la playa baja suave), cauce del río a -3
    h = np.where(is_land, -1.0 + height, -1.0 - np.clip(dist_out / 30.0, 0, 1) * 3.0)
    h = np.where(wet > 127, -3.0, h)
    h = cv2.GaussianBlur(h.astype(np.float32), (0, 0), 1.0)
    return {
        "color": np.clip(col, 0, 255).astype(np.uint8),
        "water": water,
        "height": h,
        "is_land": is_land,
        "dist_in": dist_in,
        "beach": beach,
        "rock": rock,
        "cliff": cliff_t,
        "forest": n1,
        "meadow": n2,
        "px": px,
        "size": (W, H),
    }


# ----------------------------------------------------------------------------------------------------
# Piezas
# ----------------------------------------------------------------------------------------------------
# Caras de una caja: esquinas por índice (x * 4 + y * 2 + z, como export.luau: x, y, z en -0.5 / 0.5)
BOX_FACES = np.array([
    (0, 1, 3, 2),  # x-
    (4, 6, 7, 5),  # x+
    (0, 4, 5, 1),  # y-
    (2, 3, 7, 6),  # y+
    (0, 2, 6, 4),  # z-
    (1, 5, 7, 3),  # z+
], np.int64)
SKIP_NAMES = {"Book", "Product", "Flower", "Crack", "Drain", "Manhole", "Lens", "Light"}
WALL_MATS = {"Concrete", "Plaster", "SmoothPlastic", "Limestone", "Marble", "Brick", "Granite", "Pavement", "Plastic"}


def read_parts(path):
    parts = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            f = line.rstrip("\n").split("\t")
            if len(f) < 8:
                continue
            name = f[8] if len(f) > 8 else ""
            if name in SKIP_NAMES:
                continue
            transp = float(f[5])
            if transp > 0.6 or f[4] == "Neon" and transp > 0.2:
                continue
            g = [float(v) for v in f[6].split(",")]
            corners = np.array([[float(v) for v in c.split(",")] for c in f[7].split(";")], np.float32)
            parts.append({
                "shape": f[0], "top": float(f[1]), "bottom": float(f[2]),
                "col": tuple(int(v) for v in f[3].split(",")), "mat": f[4], "transp": transp,
                "center": g[0:3], "axis": g[3:6], "length": g[6], "radius": g[7], "ball": g[8],
                "corners": corners, "name": name,
            })
    return parts


def unit_sphere(subdiv=1):
    t = (1 + 5 ** 0.5) / 2
    v = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
         (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    verts = [np.array(p, float) / np.linalg.norm(p) for p in v]
    faces = list(f)
    for _ in range(subdiv):
        cache = {}
        nf = []

        def mid(a, b):
            key = (min(a, b), max(a, b))
            if key not in cache:
                m = verts[a] + verts[b]
                verts.append(m / np.linalg.norm(m))
                cache[key] = len(verts) - 1
            return cache[key]

        for a, b, c in faces:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        faces = nf
    return np.array(verts, np.float32), np.array(faces, np.int64)


class MeshBuilder:
    """Va juntando vértices (coordenadas de Roblox) y caras con su color y sus datos de material."""

    def __init__(self):
        self.verts, self.faces, self.sizes = [], [], []
        self.col, self.win, self.rough, self.count = [], [], [], 0

    def add(self, verts, faces, col, win=0.0, rough=0.6):
        faces = np.asarray(faces, np.int64)
        self.verts.append(np.asarray(verts, np.float32))
        self.faces.append(faces.reshape(len(faces), -1) + self.count)
        self.count += len(verts)
        n = len(faces)
        self.col.append(np.repeat(np.asarray(col, np.float32)[None, :], n, 0) if np.ndim(col) == 1 else np.asarray(col, np.float32))
        self.win.append(np.full(n, win, np.float32) if np.ndim(win) == 0 else np.asarray(win, np.float32))
        self.rough.append(np.full(n, rough, np.float32))


def build_parts(parts, builder, sphere):
    sv, sf = sphere
    for p in parts:
        mat = p["mat"]
        col = srgb_to_linear(stylise(p["col"], mat))
        rough = 0.12 if mat == "Glass" else (0.05 if mat == "Water" else 0.7)
        if mat == "Water":
            col = srgb_to_linear((40, 170, 215))
        if p["shape"] == "Ball":
            c = np.array(p["center"], np.float32)
            r = p["ball"]
            builder.add(sv * r + c, sf, col, 0.0, rough)
            continue
        if p["shape"] in ("Cylinder", "Disc"):
            c = np.array(p["center"], np.float32)
            axis = np.array(p["axis"], np.float32)
            axis /= np.linalg.norm(axis) + 1e-9
            ref = np.array([0, 1, 0], np.float32) if abs(axis[1]) < 0.9 else np.array([1, 0, 0], np.float32)
            u = np.cross(axis, ref)
            u /= np.linalg.norm(u)
            w = np.cross(axis, u)
            k = 10
            ang = np.linspace(0, 2 * np.pi, k, endpoint=False)
            ring = (np.cos(ang)[:, None] * u + np.sin(ang)[:, None] * w) * p["radius"]
            half = axis * p["length"] / 2
            verts = np.vstack([c - half + ring, c + half + ring])
            faces = [(i, (i + 1) % k, k + (i + 1) % k, k + i) for i in range(k)]
            cap0 = list(range(k))[::-1]
            cap1 = list(range(k, 2 * k))
            builder.add(verts, faces, col, 0.0, rough)
            builder.add(np.vstack([verts[cap0]]), [tuple(range(k))], col, 0.0, rough)
            builder.add(np.vstack([verts[cap1]]), [tuple(range(k))], col, 0.0, rough)
            continue
        corners = p["corners"]
        faces = BOX_FACES.copy()
        # (que las normales miren hacia fuera)
        center = corners.mean(0)
        fc = corners[faces].mean(1)
        e1 = corners[faces[:, 1]] - corners[faces[:, 0]]
        e2 = corners[faces[:, 2]] - corners[faces[:, 0]]
        nrm = np.cross(e1, e2)
        flip = (nrm * (fc - center)).sum(1) < 0
        faces[flip] = faces[flip][:, ::-1]
        # Ventanas: en las caras de lado de las piezas altas de fachada
        height = p["top"] - max(p["bottom"], 0)
        win = 0.0
        if height > 14 and mat in WALL_MATS and p["name"] in ("Wall", "Body", "Tower", "Block", "Edificio", "Main", "Facade") or (height > 30 and mat in WALL_MATS):
            unit = nrm / (np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-9)
            win = (np.abs(unit[:, 1]) < 0.3).astype(np.float32)
            win = np.where(flip, win, win)
        # Tejados de colores (teja, azul pizarra, gris) y fachadas claras, como en un mapa ilustrado:
        # cada edificio (por su sitio) un color; las piezas de un mismo edificio comparten tejado
        unit = nrm / (np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-9)
        unit[flip] *= -1
        face_col = np.repeat(col[None, :], 6, 0)
        if mat in WALL_MATS or mat in ROOF_MATS:
            if height > 6 and mat not in ("Glass",) and p["name"] not in ROOF_SKIP:
                key = (int(math.floor(center[0] / 60)) * 73856093) ^ (int(math.floor(center[2] / 60)) * 19349663)
                roof = ROOF_PALETTE[key % len(ROOF_PALETTE)]
                up = unit[:, 1] > 0.7
                if mat != "ClayRoofTiles":
                    face_col[up] = roof
            side = np.abs(unit[:, 1]) < 0.3
            if mat in WALL_MATS:
                face_col[side] = face_col[side] * 0.65 + WALL_LIGHT * 0.35
        builder.add(corners, faces, face_col, win, rough)


ROOF_MATS = {"Slate", "ClayRoofTiles", "Wood", "WoodPlanks", "Metal", "DiamondPlate", "CorrugatedMetal"}
ROOF_SKIP = {"Road", "Sidewalk", "Curb", "Marking", "Zebra", "Pole", "Base", "Arm", "Head", "LampFoot", "LampBrace", "Trunk", "Branch", "Root"}
ROOF_PALETTE = [srgb_to_linear(c) for c in ((198, 96, 58), (176, 76, 50), (206, 112, 66), (92, 112, 146), (120, 126, 136), (188, 72, 60), (198, 96, 58), (72, 122, 136))]
WALL_LIGHT = srgb_to_linear((244, 236, 222))


# ----------------------------------------------------------------------------------------------------
# Árboles y barcos
# ----------------------------------------------------------------------------------------------------
def footprint_masks(parts, ter):
    W, H = ter["size"]
    px = ter["px"]
    built = np.zeros((H, W), np.uint8)
    garden = np.zeros((H, W), np.uint8)
    for p in parts:
        pts = np.array([px(c[0], c[2]) for c in p["corners"]], np.float32)
        hull = np.round(cv2.convexHull(pts)).astype(np.int32)
        grassy = p["mat"] in ("Grass", "LeafyGrass") and p["top"] < 1.5
        cv2.fillConvexPoly(garden if grassy else built, hull, 255)
    built = cv2.dilate(built, np.ones((3, 3), np.uint8))
    return built > 0, garden > 0


def plant_trees(ter, built, garden, density, rng, roads):
    """Árboles: bosque denso en el campo y los montes, más claros en los prados, jardines y parques de
    la ciudad (más pequeños) y avenidas con árboles a los dos lados de las calles. Nunca encima de
    una calle, una acera o un edificio (máscara `built`). Devuelve X, Z, suelo y tamaño (1 campo,
    0.65 ciudad, 0.8 avenida)."""
    W, H = ter["size"]
    x0, x1, z0, z1 = EXT
    step = 19.0 / math.sqrt(max(density, 0.05))
    xs = np.arange(x0, x1, step)
    zs = np.arange(z0, z1, step)
    gx, gz = np.meshgrid(xs, zs)
    gx = gx + rng.uniform(-step * 0.45, step * 0.45, gx.shape)
    gz = gz + rng.uniform(-step * 0.45, step * 0.45, gz.shape)

    def sample(x, z):
        ix = np.clip(((x - x0) / TEX).astype(int), 0, W - 1)
        iz = np.clip(((z - z0) / TEX).astype(int), 0, H - 1)
        ok = ter["is_land"][iz, ix] & (ter["beach"][iz, ix] < 0.2) & (ter["water"][iz, ix] < 0.5) & (ter["rock"][iz, ix] < 0.6) & (ter["cliff"][iz, ix] < 0.3) & ~built[iz, ix]
        return ix, iz, ok

    ix, iz, ok = sample(gx, gz)
    forest = ter["forest"][iz, ix]
    meadow = ter["meadow"][iz, ix]
    in_garden = garden[iz, ix]
    prob = np.where(in_garden, 0.55, np.where(forest > 0.42, 0.97, 0.3 + 0.35 * meadow))
    prob = np.where(ter["height"][iz, ix] > 8, np.maximum(prob, 0.85), prob)
    keep = ok & (rng.random(gx.shape) < prob)
    X, Z = list(gx[keep]), list(gz[keep])
    size = list(np.where(in_garden[keep], 0.65, 1.0))
    # Avenidas: a los dos lados de cada calle, pasada la acera, cada ~34 studs
    for (ax, az, bx, bz, half) in roads:
        length = math.hypot(bx - ax, bz - az)
        if length < 40:
            continue
        ux, uz = (bx - ax) / length, (bz - az) / length
        nx, nz = -uz, ux
        n = int(length / 34)
        t = (np.arange(n) + 0.5) / n
        for side in (-1, 1):
            off = half + 15
            px_ = ax + ux * length * t + nx * off * side
            pz_ = az + uz * length * t + nz * off * side
            _, _, okr = sample(px_, pz_)
            X += list(px_[okr])
            Z += list(pz_[okr])
            size += [0.8] * int(okr.sum())
    X, Z, size = np.array(X), np.array(Z), np.array(size)
    ix = np.clip(((X - x0) / TEX).astype(int), 0, W - 1)
    iz = np.clip(((Z - z0) / TEX).astype(int), 0, H - 1)
    return X, Z, ter["height"][iz, ix], size


def add_trees(builder, X, Z, ground, size, rng, sphere):
    sv, sf = sphere
    n = len(X)
    greens = np.array([(46, 132, 40), (64, 156, 48), (88, 172, 56), (40, 112, 44), (110, 176, 60), (128, 186, 66)], np.float32)
    kinds = rng.random(n)
    for i in range(n):
        g = greens[rng.integers(0, len(greens))] * rng.uniform(0.85, 1.12)
        col = srgb_to_linear(np.clip(g, 0, 255))
        base = np.array([X[i], ground[i], Z[i]], np.float32)
        k_size = size[i]
        if kinds[i] < 0.2 and k_size >= 1:
            # Pino: cono
            r, h = rng.uniform(12, 17), rng.uniform(55, 75)
            k = 7
            ang = np.linspace(0, 2 * np.pi, k, endpoint=False) + rng.uniform(0, 1)
            ring = np.stack([np.cos(ang) * r, np.full(k, h * 0.22), np.sin(ang) * r], 1)
            verts = np.vstack([ring, [[0, h, 0]]]) + base
            faces = [(j, (j + 1) % k, k) for j in range(k)]
            builder.add(verts, [(f[2], f[1], f[0]) for f in faces], col * 0.85)
        else:
            # Copa redonda (un poco aplastada); las grandes, con una segunda copa al lado
            r = rng.uniform(15, 25) * k_size  # (árboles más grandes que en el juego: se leen desde lejos, como en el dibujo)
            c = base + np.array([0, r * 0.9 + 5, 0], np.float32)
            builder.add(sv * np.array([r, r * 0.85, r], np.float32) + c, sf, col)
            if r > 18:
                c2 = c + np.array([rng.uniform(-r, r) * 0.5, -r * 0.2, rng.uniform(-r, r) * 0.5], np.float32)
                builder.add(sv * (r * 0.7) + c2, sf, col * 1.1)


def garden_dressing(builder, ter, built, garden, rng, sphere):
    """Setos y flores en el césped de las manzanas (jardines y parques): solo en el hueco libre."""
    sv, sf = sphere
    W, H = ter["size"]
    x0, x1, z0, z1 = EXT
    ys, xs = np.nonzero(garden[::3, ::3] & ~built[::3, ::3])
    pick = rng.random(len(xs)) < 0.05
    flowers = [(236, 70, 90), (250, 200, 60), (240, 120, 200), (255, 255, 255), (250, 140, 50)]
    for xi, yi in zip(xs[pick], ys[pick]):
        x, z = x0 + xi * 3 * TEX, z0 + yi * 3 * TEX
        if rng.random() < 0.55:
            # Mata de flores: tres bolitas de color
            col = srgb_to_linear(flowers[rng.integers(0, len(flowers))])
            for _ in range(3):
                c = np.array([x + rng.uniform(-5, 5), 1.5, z + rng.uniform(-5, 5)], np.float32)
                builder.add(sv * rng.uniform(2.2, 3.5) + c, sf, col)
        else:
            # Arbusto o seto bajo
            col = srgb_to_linear(np.array((52, 128, 46)) * rng.uniform(0.85, 1.15))
            c = np.array([x, 3, z], np.float32)
            builder.add(sv * np.array([rng.uniform(5, 9), 3.5, rng.uniform(3, 5)], np.float32) + c, sf, col)


def boat(builder, x, z, length, heading, rng, cargo=False):
    """Un barco: casco blanco (o rojo y negro si es de carga), cubierta y cabina; o contenedores."""
    width = length * (0.18 if cargo else 0.32)
    c, s = math.cos(heading), math.sin(heading)

    def box(cx, cz, lx, wz, y0, y1, col):
        pts = []
        for ix in (-0.5, 0.5):
            for iy in (y0, y1):
                for iz in (-0.5, 0.5):
                    lxp, lzp = ix * lx + cx, iz * wz + cz
                    pts.append((x + lxp * c - lzp * s, iy, z + lxp * s + lzp * c))
        corners = np.array(pts, np.float32)
        faces = BOX_FACES.copy()
        center = corners.mean(0)
        fcs = corners[faces].mean(1)
        nrm = np.cross(corners[faces[:, 1]] - corners[faces[:, 0]], corners[faces[:, 2]] - corners[faces[:, 0]])
        flip = (nrm * (fcs - center)).sum(1) < 0
        faces[flip] = faces[flip][:, ::-1]
        builder.add(corners, faces, srgb_to_linear(col), 0.0, 0.4)

    if cargo:
        box(0, 0, length, width, -2, 5, (170, 40, 40))
        box(0, 0, length * 0.96, width * 0.92, 5, 7, (40, 40, 48))
        box(length * 0.4, 0, length * 0.12, width * 0.8, 7, 20, (240, 240, 240))
        palette = [(220, 60, 50), (40, 110, 200), (240, 170, 40), (60, 160, 90), (230, 230, 230)]
        for i in range(8):
            for j in range(2):
                box(-length * 0.38 + i * length * 0.09, (j - 0.5) * width * 0.45, length * 0.085, width * 0.42, 7, 13, palette[rng.integers(0, len(palette))])
    else:
        box(0, 0, length, width, -1.5, 2.5, (246, 246, 250))
        box(-length * 0.1, 0, length * 0.4, width * 0.7, 2.5, 5.5, (232, 236, 244))
        box(-length * 0.05, 0, length * 0.15, width * 0.5, 5.5, 6.5, (40, 70, 110))


def wake(color_img, ter, x, z, length, heading):
    """Estela blanca detrás de un barco (pintada en el agua)."""
    px = ter["px"]
    c, s = math.cos(heading), math.sin(heading)
    # (una cuña que se abre y se desvanece detrás del barco)
    for k in range(10):
        t = k / 10
        d0, d1 = 0.5 + t * 1.2, 0.5 + (t + 0.1) * 1.2
        a, b = px(x - c * length * d0, z - s * length * d0), px(x - c * length * d1, z - s * length * d1)
        width = max(1, int(length * (0.12 + t * 0.25) / TEX))
        overlay = color_img.copy()
        cv2.line(overlay, (int(a[0]), int(a[1])), (int(b[0]), int(b[1])), (228, 246, 250), width, cv2.LINE_AA)
        alpha = 0.7 * (1 - t)
        color_img[:] = (color_img * (1 - alpha) + overlay * alpha).astype(np.uint8)


# ----------------------------------------------------------------------------------------------------
# Blender
# ----------------------------------------------------------------------------------------------------
def to_blender(v, exag=1.0):
    """Roblox (X este, Y arriba, Z sur) -> Blender (x este, y norte, z arriba)."""
    v = np.asarray(v, np.float32)
    y = np.where(v[:, 1] > 0, v[:, 1] * exag, v[:, 1])
    return np.stack([v[:, 0], -v[:, 2], y], 1)


def make_mesh(bpy, name, builder, material, exag=1.0):
    verts = to_blender(np.vstack(builder.verts), exag)
    # Caras de 3 y de 4 lados (y polígonos de los cilindros): por tamaños
    loops, sizes = [], []
    for f in builder.faces:
        loops.append(f.reshape(-1))
        sizes.append(np.full(len(f), f.shape[1], np.int32))
    loops = np.concatenate(loops)
    sizes = np.concatenate(sizes)
    starts = np.concatenate([[0], np.cumsum(sizes)[:-1]]).astype(np.int32)
    mesh = bpy.data.meshes.new(name)
    mesh.vertices.add(len(verts))
    mesh.vertices.foreach_set("co", verts.reshape(-1))
    mesh.loops.add(len(loops))
    mesh.loops.foreach_set("vertex_index", loops.astype(np.int32))
    mesh.polygons.add(len(sizes))
    mesh.polygons.foreach_set("loop_start", starts)
    mesh.polygons.foreach_set("loop_total", sizes)
    mesh.update(calc_edges=True)
    col = np.vstack(builder.col)
    rgba = np.hstack([col, np.ones((len(col), 1), np.float32)])
    a = mesh.attributes.new("col", "FLOAT_COLOR", "FACE")
    a.data.foreach_set("color", rgba.reshape(-1))
    w = mesh.attributes.new("win", "FLOAT", "FACE")
    w.data.foreach_set("value", np.concatenate(builder.win))
    r = mesh.attributes.new("rough", "FLOAT", "FACE")
    r.data.foreach_set("value", np.concatenate(builder.rough))
    obj = bpy.data.objects.new(name, mesh)
    obj.data.materials.append(material)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def parts_material(bpy):
    m = bpy.data.materials.new("Piezas")
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    col = nt.nodes.new("ShaderNodeAttribute")
    col.attribute_name = "col"
    win = nt.nodes.new("ShaderNodeAttribute")
    win.attribute_name = "win"
    rough = nt.nodes.new("ShaderNodeAttribute")
    rough.attribute_name = "rough"
    # Ventanas: pisos (cada 5 studs) y columnas (cada 4) en coordenadas del mundo
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Position"], sep.inputs[0])

    def stripes(value, period, duty):
        div = nt.nodes.new("ShaderNodeMath")
        div.operation = "DIVIDE"
        div.inputs[1].default_value = period
        nt.links.new(value, div.inputs[0])
        fr = nt.nodes.new("ShaderNodeMath")
        fr.operation = "FRACT"
        nt.links.new(div.outputs[0], fr.inputs[0])
        gt = nt.nodes.new("ShaderNodeMath")
        gt.operation = "GREATER_THAN"
        gt.inputs[1].default_value = duty
        nt.links.new(fr.outputs[0], gt.inputs[0])
        return gt.outputs[0]

    add = nt.nodes.new("ShaderNodeMath")
    add.operation = "ADD"
    nt.links.new(sep.outputs[0], add.inputs[0])
    nt.links.new(sep.outputs[1], add.inputs[1])
    floors = stripes(sep.outputs[2], 5.0, 0.45)
    columns = stripes(add.outputs[0], 4.0, 0.35)
    m1 = nt.nodes.new("ShaderNodeMath")
    m1.operation = "MULTIPLY"
    nt.links.new(floors, m1.inputs[0])
    nt.links.new(columns, m1.inputs[1])
    m2 = nt.nodes.new("ShaderNodeMath")
    m2.operation = "MULTIPLY"
    nt.links.new(m1.outputs[0], m2.inputs[0])
    nt.links.new(win.outputs["Fac"], m2.inputs[1])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    nt.links.new(m2.outputs[0], mix.inputs["Factor"])
    nt.links.new(col.outputs["Color"], mix.inputs["A"])
    mix.inputs["B"].default_value = (0.05, 0.12, 0.22, 1)
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    nt.links.new(rough.outputs["Fac"], bsdf.inputs["Roughness"])
    bsdf.inputs["Specular IOR Level"].default_value = 0.35
    nt.links.new(bsdf.outputs[0], out.inputs[0])
    return m


def ground_material(bpy, color_path, water_path):
    m = bpy.data.materials.new("Suelo")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(color_path)
    tex.interpolation = "Cubic"
    wtex = nt.nodes.new("ShaderNodeTexImage")
    wtex.image = bpy.data.images.load(water_path)
    wtex.image.colorspace_settings.name = "Non-Color"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    # Agua: brillante (reflejo del sol); tierra: mate
    ramp = nt.nodes.new("ShaderNodeMapRange")
    ramp.inputs["To Min"].default_value = 0.92
    ramp.inputs["To Max"].default_value = 0.18
    nt.links.new(wtex.outputs["Color"], ramp.inputs["Value"])
    nt.links.new(ramp.outputs[0], bsdf.inputs["Roughness"])
    bsdf.inputs["Specular IOR Level"].default_value = 0.4
    return m


def ground_mesh(bpy, ter, material):
    x0, x1, z0, z1 = EXT
    step = 16.0
    xs = np.arange(x0, x1 + step, step)
    zs = np.arange(z0, z1 + step, step)
    nx, nz = len(xs), len(zs)
    gx, gz = np.meshgrid(xs, zs)
    W, H = ter["size"]
    hmap = cv2.resize(ter["height"], (nx, nz), interpolation=cv2.INTER_AREA)
    verts = np.stack([gx.reshape(-1), -gz.reshape(-1), hmap.reshape(-1)], 1).astype(np.float32)
    idx = np.arange(nx * nz).reshape(nz, nx)
    a, b, c, d = idx[:-1, :-1], idx[:-1, 1:], idx[1:, 1:], idx[1:, :-1]
    # (la Z de Roblox va al revés que la y de Blender: el orden a, d, c, b mira hacia arriba)
    quads = np.stack([a, d, c, b], -1).reshape(-1, 4)
    mesh = bpy.data.meshes.new("Suelo")
    mesh.vertices.add(len(verts))
    mesh.vertices.foreach_set("co", verts.reshape(-1))
    mesh.loops.add(quads.size)
    mesh.loops.foreach_set("vertex_index", quads.reshape(-1).astype(np.int32))
    mesh.polygons.add(len(quads))
    mesh.polygons.foreach_set("loop_start", np.arange(0, quads.size, 4, dtype=np.int32))
    mesh.polygons.foreach_set("loop_total", np.full(len(quads), 4, np.int32))
    mesh.update(calc_edges=True)
    uv = mesh.uv_layers.new(name="UV")
    u = (gx.reshape(-1) - x0) / (x1 - x0)
    v = 1 - (gz.reshape(-1) - z0) / (z1 - z0)
    uvs = np.stack([u, v], 1)[quads.reshape(-1)]
    uv.data.foreach_set("uv", uvs.reshape(-1).astype(np.float32))
    mesh.shade_smooth() if hasattr(mesh, "shade_smooth") else None
    obj = bpy.data.objects.new("Suelo", mesh)
    obj.data.materials.append(material)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def main():
    args = parse_args()
    import bpy

    t0 = time.time()
    plan = json.load(open(os.path.join(args.dir, "plan.json")))
    landmarks = json.load(open("docs/mapa/lugares.json", encoding="utf-8"))
    rng = np.random.default_rng(7)
    W = args.width
    H = W * ROWS * TILE_H // (COLS * 1024)
    print(f"▶ {W}x{H}, inclinación {TILT}°, {ORTHO_W / W:.2f} studs por píxel")

    parts = read_parts(os.path.join(args.dir, "parts.tsv"))
    print(f"  {len(parts)} piezas")
    ter = terrain(plan, None)
    built, garden = footprint_masks(parts, ter)
    # Calles (las calzadas de asfalto): eje largo y medio ancho, para las avenidas con árboles
    roads = []
    for p in parts:
        if p["mat"] == "Asphalt" and p["name"] in ("Road", "Calzada", "Lane", "Avenue", "Carretera"):
            cs = p["corners"]
            xz = cs[:, [0, 2]]
            d = xz[:, None, :] - xz[None, :, :]
            i, j = np.unravel_index(np.argmax((d ** 2).sum(-1)), (8, 8))
            ext = np.ptp(xz @ np.array([[0, 1], [-1, 0]]) @ ((xz[j] - xz[i]) / (np.linalg.norm(xz[j] - xz[i]) + 1e-9)))
            mid = xz.mean(0)
            axis = (xz[j] - xz[i]) / (np.linalg.norm(xz[j] - xz[i]) + 1e-9)
            L = np.ptp(xz @ axis)
            a_, b_ = mid - axis * L / 2, mid + axis * L / 2
            roads.append((a_[0], a_[1], b_[0], b_[1], ext / 2))
    print(f"  {len(roads)} tramos de calle")
    X, Z, ground, size = plant_trees(ter, built, garden, args.trees, rng, roads)
    print(f"  {len(X)} árboles")
    # Barcos: en el puerto deportivo (oeste) y frente al puerto de mercancías (sur)
    color = ter["color"].copy()
    boats = []
    marina = plan["Places"]["Marina"]
    for i in range(7):
        boats.append((marina[0] - 260 - rng.uniform(0, 220), marina[1] + rng.uniform(-260, 260), rng.uniform(26, 44), rng.uniform(-0.4, 0.4) + math.pi, False))
    port = plan["Places"]["PuertoMercancias"]
    boats.append((port[0] + 350, port[1] + 380, 190, 0.05, True))
    boats.append((port[0] - 300, port[1] + 520, 160, -0.1, True))
    for i in range(6):
        boats.append((rng.uniform(-3500, 3800), rng.uniform(3900, 4300), rng.uniform(28, 46), rng.uniform(0, 2 * math.pi), False))
    for i in range(4):
        boats.append((rng.uniform(4500, 5600), rng.uniform(-2500, 1500), rng.uniform(28, 46), rng.uniform(0, 2 * math.pi), False))
    for b in boats:
        wake(color, ter, b[0], b[1], b[2], b[3])
    import tempfile
    work = tempfile.mkdtemp(prefix="mapa-blender-", dir=os.environ.get("TMPDIR"))
    color_path, water_path = os.path.join(work, "suelo.png"), os.path.join(work, "agua.png")
    cv2.imwrite(color_path, cv2.cvtColor(color, cv2.COLOR_RGB2BGR))
    cv2.imwrite(water_path, (ter["water"] * 255).astype(np.uint8))

    # -------------------------------------------------------------------------------------------
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    sphere = unit_sphere(1)
    print("▶ Geometría")
    b_parts = MeshBuilder()
    build_parts(parts, b_parts, sphere)
    for bt in boats:
        boat(b_parts, bt[0], bt[1], bt[2], bt[3], rng, bt[4])
    make_mesh(bpy, "Ciudad", b_parts, parts_material(bpy), Y_EXAG)
    b_trees = MeshBuilder()
    add_trees(b_trees, X, Z, ground, size, rng, unit_sphere(1))
    garden_dressing(b_trees, ter, built, garden, rng, unit_sphere(1))
    make_mesh(bpy, "Arboles", b_trees, parts_material(bpy))
    ground_mesh(bpy, ter, ground_material(bpy, color_path, water_path))
    print(f"  {time.time() - t0:.0f} s")

    # Cámara ortográfica inclinada, mirando al norte
    t = math.radians(TILT)
    cam = bpy.data.cameras.new("Camara")
    cam.type = "ORTHO"
    cam.ortho_scale = ORTHO_W
    cam.clip_start = 10
    cam.clip_end = 80000
    co = bpy.data.objects.new("Camara", cam)
    scene.collection.objects.link(co)
    scene.camera = co
    D = 30000.0
    by0 = CS / math.cos(t)  # (punto del suelo que cae en el centro de la imagen)
    co.location = (CX, by0 - math.sin(t) * D, math.cos(t) * D)
    co.rotation_euler = (t, 0, 0)
    # Sol cálido desde el suroeste, alto, con sombras suaves; cielo azul claro de ambiente
    sun = bpy.data.lights.new("Sol", "SUN")
    sun.energy = 5.0
    sun.color = (1.0, 0.84, 0.62)  # (luz dorada)
    sun.angle = math.radians(6)  # (sombras suaves)
    so = bpy.data.objects.new("Sol", sun)
    scene.collection.objects.link(so)
    so.rotation_euler = (math.radians(55), 0, math.radians(-30))
    world = bpy.data.worlds.new("Cielo")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.45, 0.66, 1.0, 1)  # (relleno frío del cielo)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    scene.world = world
    # Render
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.cycles.diffuse_bounces = 2
    scene.cycles.glossy_bounces = 1
    scene.cycles.transparent_max_bounces = 2
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Punchy"
    scene.render.resolution_x = W
    scene.render.resolution_y = H
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    raw = os.path.join(work, "render.png")
    scene.render.filepath = raw
    scene.render.image_settings.file_format = "PNG"
    print("▶ Render (Cycles, CPU)")
    bpy.ops.render.render(write_still=True)
    print(f"  {time.time() - t0:.0f} s")

    # -------------------------------------------------------------------------------------------
    # Acabado: un poco de resplandor (bloom), más color y calidez
    img = cv2.imread(raw).astype(np.float32) / 255.0
    lum = img.mean(2, keepdims=True)
    bright = np.clip(img * (lum > 0.72), 0, 1)
    bloom = cv2.GaussianBlur(bright, (0, 0), W / 500) * 0.35
    img = np.clip(img + bloom, 0, 1)
    hsv = cv2.cvtColor((img * 255).astype(np.uint8), cv2.COLOR_BGR2HSV).astype(np.float32)
    hsv[..., 1] = np.clip(hsv[..., 1] * 1.25, 0, 255)
    hsv[..., 2] = np.clip(255 * (hsv[..., 2] / 255) ** 0.88, 0, 255)  # (un poco más luminoso)
    out = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR).astype(np.float32) / 255
    out = np.clip(out + (out - 0.5) * 0.12 * (1 - np.abs(out - 0.5) * 2), 0, 1)  # (contraste en curva S suave)
    out = (out * 255).astype(np.uint8)
    os.makedirs(args.out, exist_ok=True)
    cv2.imwrite(os.path.join(args.out, "preview.jpg"), cv2.resize(out, (W // 2, H // 2), interpolation=cv2.INTER_AREA), [cv2.IMWRITE_JPEG_QUALITY, 90])
    if args.preview:
        print("✅ vista previa")
        return
    for name in os.listdir(args.out):
        if (name.startswith("arte_") or name.startswith("mapa_") or name.startswith("isla_")) and name.endswith(".png"):
            os.remove(os.path.join(args.out, name))
    tw, th = W // COLS, H // ROWS
    for r in range(ROWS):
        for c in range(COLS):
            path = os.path.join(args.out, f"isla_{r}_{c}.png")
            cv2.imwrite(path, out[r * th:(r + 1) * th, c * tw:(c + 1) * tw], [cv2.IMWRITE_PNG_COMPRESSION, 9])
    # Color del mar en el borde (el fondo de la pantalla del mapa: sin escalón)
    edge = np.concatenate([out[:4].reshape(-1, 3), out[-4:].reshape(-1, 3), out[:, :4].reshape(-1, 3), out[:, -4:].reshape(-1, 3)])
    sea = [int(v) for v in np.median(edge, 0)[::-1]]
    # La isla en la imagen (para encajarla con el zoom 1): costa, islas y aeropuerto proyectados
    pts = [project(p[0], 0, p[1], W, H) for p in plan["Coast"]]
    for isl in plan["Islands"]:
        for a in range(0, 360, 30):
            pts.append(project(isl["X"] + math.cos(math.radians(a)) * isl["R"], 0, isl["Z"] + math.sin(math.radians(a)) * isl["R"], W, H))
    for m in plan["Mountains"]:
        pts.append(project(m["X"], m["H"], m["Z"], W, H))
    A = plan["Airport"]["Land"]
    for x in (A["X0"], A["X1"]):
        for z in (A["Z0"], A["Z1"]):
            pts.append(project(x, 0, z, W, H))
    us, vs = [p[0] for p in pts], [p[1] for p in pts]
    box = (math.floor(min(us)) - 10, math.floor(min(vs)) - 10, math.ceil(max(us)) + 10, math.ceil(max(vs)) + 10)
    meta = {"Width": W, "Height": H, "Cols": COLS, "Rows": ROWS, "TileWidth": tw, "TileHeight": th, "Tilt": TILT, "OrthoWidth": ORTHO_W, "CX": CX, "CS": CS, "Sea": sea, "IslandBox": box}
    json.dump(meta, open(os.path.join(args.out, "meta.json"), "w"), indent=1)
    with open(args.projection, "w", encoding="utf-8") as fh:
        fh.write("-- MapProjection: GENERADO por scripts/map/blender_render.py (no editar a mano).\n")
        fh.write("-- La cámara con la que se hizo la imagen de la isla (textures/mapa/isla_*): ortográfica, inclinada Tilt\n")
        fh.write("-- grados mirando al norte. Del mundo (X, Y, Z) al píxel de la imagen: shared/MapScreen.toArt (exacto).\n")
        fh.write("return {\n")
        fh.write(f"\tTilt = {TILT}, -- grados desde la vertical\n")
        fh.write(f"\tOrthoWidth = {ORTHO_W}, -- studs que caben a lo ancho de la imagen\n")
        fh.write(f"\tCX = {CX}, -- X del mundo en el centro de la imagen\n")
        fh.write(f"\tCS = {CS}, -- «arriba» de la pantalla (-Z·cos + Y·sen) en el centro de la imagen\n")
        fh.write(f"\tWidth = {W},\n\tHeight = {H},\n\tCols = {COLS},\n\tRows = {ROWS},\n")
        fh.write(f"\tSea = {{ {sea[0]}, {sea[1]}, {sea[2]} }}, -- color del mar en el borde (fondo de la pantalla)\n")
        fh.write(f"\tIslandBox = {{ X0 = {box[0]}, Y0 = {box[1]}, X1 = {box[2]}, Y1 = {box[3]} }}, -- la isla en la imagen\n")
        fh.write("}\n")
    print(f"✅ {args.out} ({COLS}x{ROWS} trozos de {tw}x{th}) y {args.projection} en {time.time() - t0:.0f} s")


if __name__ == "__main__":
    sys.exit(main())
