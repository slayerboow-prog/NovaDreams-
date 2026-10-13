#!/usr/bin/env python3
"""Dibuja la isla de Valmar vista desde arriba para el mapa grande (Controllers/MapUI).

Uso (desde la carpeta roblox/):
    rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
    lune run scripts/map/export.luau X.rbxl DIR
    python3 scripts/map/render.py DIR [--out textures/mapa] [--size 3072]

Es una vista ORTOGRÁFICA de la ciudad de verdad: cada pieza de workspace.Town se pinta con su huella
vista desde arriba, su color y su altura (sombra hacia el sureste y luz en lo alto). El terreno (mar,
playas, hierba, montañas, río y lagos) no está en el archivo (lo pone TerrainBuilder al arrancar):
se rehace con los mismos datos de shared/CityPlan. Estilo ilustrado de juego de móvil: verdes
saturados, mar azul con bajíos turquesa, playas claras, tejados de colores, calles grises y relieve.
Los bordes de los distritos NO van en la imagen: los dibuja la interfaz (siguen nítidos al acercar).

Salida (Roblox admite 1024x1024 como mucho por imagen: va en trozos):
    OUT/mapa_<fila>_<columna>.png   3x3 trozos (1024 de ancho) que cubren CityPlan.Bounds
    OUT/preview.jpg                 la imagen entera, más pequeña (para docs/ y para comprobarla)
Después: bash scripts/upload-map.sh (escribe src/shared/MapTextureIds.luau) y publicar.
"""
import argparse
import json
import math
import os
import sys

import cv2
import numpy as np

GROUND = 2.5  # lo que no pasa de esta altura es suelo: se pinta antes que las sombras
TILES = 3  # trozos por lado (MapUI y shared/MapScreen dan por hecho 3x3)


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("--out", default="textures/mapa")
    ap.add_argument("--size", type=int, default=3072, help="ancho de la imagen entera (px)")
    ap.add_argument("--ss", type=int, default=2, help="supermuestreo")
    return ap.parse_args()


def noise(h, w, scale, seed):
    """Ruido suave (varias octavas de ruido blanco ampliado): 0..1."""
    rng = np.random.default_rng(seed)
    out = np.zeros((h, w), np.float32)
    amp, total = 1.0, 0.0
    s = scale
    for _ in range(4):
        gh, gw = max(2, int(h / s) + 2), max(2, int(w / s) + 2)
        g = rng.random((gh, gw)).astype(np.float32)
        out += amp * cv2.resize(g, (w, h), interpolation=cv2.INTER_CUBIC)
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


def main():
    args = parse_args()
    plan = json.load(open(os.path.join(args.dir, "plan.json")))
    b = plan["Bounds"]
    W = args.size
    world_w, world_h = b["MaxX"] - b["MinX"], b["MaxZ"] - b["MinZ"]
    H = int(round(W * world_h / world_w))
    H -= H % TILES
    ppu = W / world_w  # píxeles por stud

    def px(x, z, k=1.0):
        return ((x - b["MinX"]) * ppu * k, (z - b["MinZ"]) * ppu * k)

    def poly_px(points, k=1.0):
        return np.array([px(p[0], p[1], k) for p in points], np.float32)

    # -----------------------------------------------------------------
    # 1. Terreno (a 1x): mar, bajíos, playa, hierba, montañas, río, lagos
    # -----------------------------------------------------------------
    print(f"▶ Terreno {W}x{H} ({1 / ppu:.2f} studs por píxel)")
    land = np.zeros((H, W), np.uint8)
    cv2.fillPoly(land, [np.round(poly_px(plan["Coast"])).astype(np.int32)], 255)
    for isl in plan["Islands"]:
        cx, cz = px(isl["X"], isl["Z"])
        cv2.circle(land, (int(cx), int(cz)), int(isl["R"] * ppu), 255, -1, cv2.LINE_AA)
    A = plan["Airport"]["Land"]
    x0, z0 = px(A["X0"], A["Z0"])
    x1, z1 = px(A["X1"], A["Z1"])
    cv2.rectangle(land, (int(x0), int(z0)), (int(x1), int(z1)), 255, -1)
    is_land = land > 127

    dist_in = cv2.distanceTransform(land, cv2.DIST_L2, 5) / ppu  # studs hasta el mar (en tierra)
    dist_out = cv2.distanceTransform(255 - land, cv2.DIST_L2, 5) / ppu  # studs hasta la costa (en el mar)

    n1 = noise(H, W, 220, 1)
    n2 = noise(H, W, 60, 2)
    n3 = noise(H, W, 18, 3)

    # Mar: profundo lejos, azul medio cerca y bajíos turquesa junto a la costa (con ondas)
    deep, mid, shallow, foam = rgb(12, 46, 112), rgb(22, 98, 178), rgb(64, 196, 214), rgb(225, 248, 250)
    t_far = np.clip(dist_out / 900.0, 0, 1) ** 0.7
    sea = lerp(mid, deep, t_far)
    t_sh = np.clip(1 - (dist_out + (n2 - 0.5) * 60) / 160.0, 0, 1) ** 1.6
    sea = lerp(sea, shallow, t_sh * 0.95)
    sea *= (0.94 + 0.12 * n2)[..., None]
    t_foam = np.clip(1 - np.abs(dist_out - 6) / 7.0, 0, 1) * (0.55 + 0.45 * n3)
    sea = lerp(sea, foam, t_foam * 0.8)

    # Hierba: verdes vivos con manchas (prados más claros, bosque más oscuro)
    grass_a, grass_b, forest = rgb(78, 164, 62), rgb(108, 186, 70), rgb(44, 118, 52)
    g = lerp(grass_a, grass_b, n2)
    g = lerp(g, forest, np.clip((n1 - 0.55) * 2.6, 0, 1) * 0.75)
    g *= (0.93 + 0.12 * n3)[..., None]

    # Relieve: altura de las montañas (casquetes de esfera) y sombreado con luz del noroeste
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    wx = xx / ppu + b["MinX"]
    wz = yy / ppu + b["MinZ"]
    height = np.zeros((H, W), np.float32)
    rock = np.zeros((H, W), np.float32)
    for m in plan["Mountains"]:
        d2 = (wx - m["X"]) ** 2 + (wz - m["Z"]) ** 2
        cap = np.sqrt(np.maximum(0, m["R"] ** 2 - d2)) - (m["R"] - m["H"])
        cap = np.maximum(cap, 0)
        height = np.maximum(height, cap)
        if m.get("Rock"):
            r = m["R"] * 0.42
            rd2 = (wx - m["X"]) ** 2 + (wz - (m["Z"])) ** 2
            rock = np.maximum(rock, np.clip(1 - np.sqrt(rd2) / (r * 1.15), 0, 1))
    del d2
    height += (n2 - 0.5) * 6 * (height > 0)
    gy, gx = np.gradient(cv2.GaussianBlur(height, (0, 0), 2) * ppu)
    light = np.array([-0.6, -0.7, 0.9])
    light /= np.linalg.norm(light)
    nx, nz, ny = -gx, -gy, np.ones_like(gx) * 1.0
    norm = np.sqrt(nx * nx + ny * ny + nz * nz)
    shade = (nx * light[0] + nz * light[1] + ny * light[2]) / norm
    shade = np.clip(shade / light[2], 0.45, 1.25)
    hn = np.clip(height / 200.0, 0, 1)
    mountain = lerp(g, rgb(70, 140, 64), np.clip(hn * 2, 0, 1) * 0.7)
    mountain = lerp(mountain, rgb(150, 142, 128), np.clip((rock - 0.15) * 2.5, 0, 1) * (0.6 + 0.4 * n3))
    g = np.where((height > 0)[..., None], mountain, g)
    g *= shade[..., None]
    del gx, gy, nx, nz, ny, norm

    # Playa (70 studs, como TerrainBuilder) con arena mojada junto al agua; acantilados en el norte
    sand, wet = rgb(244, 226, 172), rgb(214, 196, 146)
    beach_w = 70 + (n2 - 0.5) * 24
    t_beach = np.clip((beach_w - dist_in) / 8.0, 0, 1)
    land_col = lerp(g, sand, t_beach)
    land_col = lerp(land_col, wet, np.clip(1 - dist_in / 10.0, 0, 1) * 0.6)
    coast = plan["Coast"]
    cliff = np.zeros((H, W), np.uint8)
    for a, c in plan["Cliffs"]:
        pts = [coast[(i - 1) % len(coast)] for i in range(a, c + 1)]
        cv2.polylines(cliff, [np.round(poly_px(pts)).astype(np.int32)], False, 255, max(2, int(110 * ppu)))
    cliff_t = (cv2.GaussianBlur(cliff, (0, 0), 3).astype(np.float32) / 255.0) * np.clip(1 - dist_in / 90.0, 0, 1)
    land_col = lerp(land_col, rgb(128, 118, 102) * (0.8 + 0.3 * n3)[..., None], np.clip(cliff_t * 1.6, 0, 1))

    img = np.where(is_land[..., None], land_col, sea)
    del land_col, sea, g, mountain

    # Río y lagos: orilla de arena y agua
    water = rgb(40, 150, 210)
    river = plan["River"]
    rpts = np.round(poly_px(river["Points"])).astype(np.int32)
    bank = np.zeros((H, W), np.uint8)
    wet_mask = np.zeros((H, W), np.uint8)
    cv2.polylines(bank, [rpts], False, 255, max(2, int((river["Width"] + 40) * ppu)), cv2.LINE_AA)
    cv2.polylines(wet_mask, [rpts], False, 255, max(2, int(river["Width"] * ppu)), cv2.LINE_AA)
    for lake in plan["Lakes"]:
        cx, cz = px(lake["X"], lake["Z"])
        cv2.circle(bank, (int(cx), int(cz)), int((lake["R"] + 24) * ppu), 255, -1, cv2.LINE_AA)
        cv2.circle(wet_mask, (int(cx), int(cz)), int(lake["R"] * ppu), 255, -1, cv2.LINE_AA)
    bank_t = (bank.astype(np.float32) / 255.0) * is_land
    img = lerp(img, sand, bank_t)
    wet_d = cv2.distanceTransform(wet_mask, cv2.DIST_L2, 5) / ppu
    river_col = lerp(rgb(70, 190, 210), water, np.clip(wet_d / 30.0, 0, 1))
    img = lerp(img, river_col, (wet_mask.astype(np.float32) / 255.0) * (is_land | (dist_out < 200)))
    del bank, wet_mask, wet_d, river_col, xx, yy, wx, wz

    img = np.clip(img, 0, 255).astype(np.uint8)

    # -----------------------------------------------------------------
    # 2. La ciudad (a SS veces el tamaño): cada pieza de workspace.Town
    # -----------------------------------------------------------------
    ss = args.ss
    big = cv2.resize(img, (W * ss, H * ss), interpolation=cv2.INTER_CUBIC)
    del img
    print("▶ Leyendo las piezas")
    parts = []
    with open(os.path.join(args.dir, "parts.tsv"), encoding="utf-8") as fh:
        for line in fh:
            f = line.rstrip("\n").split("\t")
            if len(f) < 8:
                continue
            shape, top, bottom = f[0], float(f[1]), float(f[2])
            col = tuple(int(v) for v in f[3].split(","))
            mat, transp = f[4], float(f[5])
            cx, cz, r1, r2 = (float(v) for v in f[6].split(","))
            corners = [tuple(float(v) for v in c.split(",")) for c in f[7].split(";")]
            name = f[8] if len(f) > 8 else ""
            parts.append((top, bottom, shape, col, mat, transp, cx, cz, r1, r2, corners, name))
    parts.sort(key=lambda p: p[0])
    print(f"  {len(parts)} piezas")

    k = ss * ppu  # píxeles (grandes) por stud

    def stylise(col, mat, top):
        c = np.array([[col]], np.uint8)
        hsv = cv2.cvtColor(c, cv2.COLOR_RGB2HSV).astype(np.float32)[0, 0]
        s_boost, v_boost = 1.3, 1.0
        if mat in ("Grass", "LeafyGrass"):
            s_boost, v_boost = 1.12, 0.96
        elif mat == "Glass":
            s_boost, v_boost = 1.5, 1.05
        elif mat in ("ClayRoofTiles", "Slate", "Brick"):
            s_boost, v_boost = 1.4, 1.08
        elif mat in ("Asphalt",):
            s_boost, v_boost = 0.6, 1.05
        hsv[1] = min(255, hsv[1] * s_boost)
        # Lo alto, un poco más claro (le da la luz); lo bajo, como está
        hsv[2] = min(255, hsv[2] * v_boost * (0.94 + 0.16 * min(1.0, max(0.0, top) / 90.0)))
        out = cv2.cvtColor(np.array([[hsv]], np.uint8), cv2.COLOR_HSV2RGB)[0, 0]
        return tuple(int(v) for v in out)

    def draw(batch):
        for top, bottom, shape, col, mat, transp, cx, cz, r1, r2, corners, name in batch:
            c = stylise(col, mat, top)
            if mat == "Water":
                c = (52, 160, 220)
            elif mat == "Neon":
                continue  # (letreros y luces: desde arriba son rayitas que ensucian)
            if shape in ("Ball", "Disc"):
                x, z = px(cx, cz, ss)
                r = max(1, int((r2 if shape == "Disc" else r1) * k))
                leafy = mat in ("Grass", "LeafyGrass") or (col[1] > col[0] + 10 and col[1] > col[2] + 10)
                if leafy and r >= 3:
                    # Copa de árbol ilustrada: borde oscuro, cuerpo y brillo arriba a la izquierda
                    dark = tuple(int(v * 0.62) for v in c)
                    cv2.circle(big, (int(x), int(z)), r, dark, -1, cv2.LINE_AA)
                    cv2.circle(big, (int(x), int(z)), max(1, int(r * 0.86)), c, -1, cv2.LINE_AA)
                    hi = tuple(min(255, int(v * 1.22 + 18)) for v in c)
                    cv2.circle(big, (int(x - r * 0.28), int(z - r * 0.3)), max(1, int(r * 0.42)), hi, -1, cv2.LINE_AA)
                else:
                    cv2.circle(big, (int(x), int(z)), r, c, -1, cv2.LINE_AA)
                continue
            pts = np.array([px(p[0], p[1], ss) for p in corners], np.float32)
            hull = np.round(cv2.convexHull(pts)).astype(np.int32)
            if transp > 0.3:
                # Cristal o agua translúcida: mezclado con lo de debajo
                x0, z0 = hull[:, 0, 0].min(), hull[:, 0, 1].min()
                x1, z1 = hull[:, 0, 0].max() + 1, hull[:, 0, 1].max() + 1
                x0, z0 = max(0, x0), max(0, z0)
                x1, z1 = min(W * ss, x1), min(H * ss, z1)
                if x1 <= x0 or z1 <= z0:
                    continue
                sub = big[z0:z1, x0:x1]
                mask = np.zeros(sub.shape[:2], np.uint8)
                cv2.fillConvexPoly(mask, hull - np.array([x0, z0]), 255)
                a = (1 - transp) * (mask.astype(np.float32) / 255.0)
                sub[:] = (sub * (1 - a[..., None]) + np.array(c, np.float32) * a[..., None]).astype(np.uint8)
                continue
            cv2.fillConvexPoly(big, hull, c, cv2.LINE_AA)
            area = cv2.contourArea(hull)
            if top > 6 and area > (14 * k) ** 2:
                # Borde del tejado (aire de dibujo): un poco más oscuro
                edge = tuple(int(v * 0.72) for v in c)
                cv2.polylines(big, [hull], True, edge, max(1, ss), cv2.LINE_AA)


    print("▶ Piezas del suelo (calles, aceras, césped)")
    low = [p for p in parts if p[0] <= GROUND]
    high = [p for p in parts if p[0] > GROUND]
    draw(low)
    # Sombras (luz del noroeste: sombra hacia el sureste, más larga cuanto más alta la pieza)
    print("▶ Sombras")
    shadow = np.zeros((H * ss, W * ss), np.uint8)
    for top, bottom, shape, col, mat, transp, cx, cz, r1, r2, corners, name in parts:
        h = top - max(bottom, 0)
        if top < 4 or h < 3:
            continue
        L = min(top, 160) * 0.55
        dx, dz = L * 0.55 * k, L * 0.8 * k
        if shape in ("Ball", "Disc"):
            x, z = px(cx, cz, ss)
            cv2.circle(shadow, (int(x + dx), int(z + dz)), max(1, int((r2 if shape == "Disc" else r1) * k)), 255, -1, cv2.LINE_AA)
        else:
            pts = np.array([px(c[0], c[1], ss) for c in corners], np.float32)
            hull = cv2.convexHull(pts)
            for frac in (0.0, 0.5, 1.0):
                cv2.fillConvexPoly(shadow, np.round(hull + np.array([dx * frac, dz * frac], np.float32)).astype(np.int32), 255, cv2.LINE_AA)
    shadow = cv2.GaussianBlur(shadow, (0, 0), 1.2 * ss)
    big = (big.astype(np.float32) * (1 - 0.5 * shadow[..., None].astype(np.float32) / 255.0)).astype(np.uint8)
    del shadow

    print("▶ Piezas")
    draw(high)

    # -----------------------------------------------------------------
    # 3. Acabado: un poco más de color y contraste, y a su tamaño
    # -----------------------------------------------------------------
    print("▶ Acabado")
    out = cv2.resize(big, (W, H), interpolation=cv2.INTER_AREA)
    del big
    # Textura suave en todo (que el césped y los tejados no sean planos del todo)
    grain = noise(H, W, 40, 7) * 0.6 + noise(H, W, 8, 8) * 0.4
    out = np.clip(out.astype(np.float32) * (0.95 + 0.1 * grain)[..., None], 0, 255).astype(np.uint8)
    hsv = cv2.cvtColor(out, cv2.COLOR_RGB2HSV).astype(np.float32)
    hsv[..., 1] = np.clip(hsv[..., 1] * 1.08, 0, 255)
    out = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2RGB)
    out = np.clip((out.astype(np.float32) - 128) * 1.06 + 131, 0, 255).astype(np.uint8)
    bgr = cv2.cvtColor(out, cv2.COLOR_RGB2BGR)

    os.makedirs(args.out, exist_ok=True)
    tw, th = W // TILES, H // TILES
    for r in range(TILES):
        for c in range(TILES):
            tile = bgr[r * th:(r + 1) * th, c * tw:(c + 1) * tw]
            assert tile.shape[0] <= 1024 and tile.shape[1] <= 1024
            path = os.path.join(args.out, f"mapa_{r}_{c}.png")
            cv2.imwrite(path, tile, [cv2.IMWRITE_PNG_COMPRESSION, 9])
            print(f"  {path} {tile.shape[1]}x{tile.shape[0]} ({os.path.getsize(path) // 1024} KB)")
    preview = cv2.resize(bgr, (1536, int(1536 * H / W)), interpolation=cv2.INTER_AREA)
    cv2.imwrite(os.path.join(args.out, "preview.jpg"), preview, [cv2.IMWRITE_JPEG_QUALITY, 88])
    meta = {"Width": W, "Height": H, "Tiles": TILES, "TileWidth": tw, "TileHeight": th, "Bounds": b}
    json.dump(meta, open(os.path.join(args.out, "meta.json"), "w"), indent=1)
    print("✅ " + args.out)


if __name__ == "__main__":
    sys.exit(main())
