#!/usr/bin/env python3
"""Mide las zonas verdes libres de Valmar a partir de la ciudad construida (export.luau).

Uso (desde roblox/; DIR = la carpeta de scripts/map/export.luau):
    python3 scripts/map/zonas-verdes/1_mascaras.py DIR      máscaras (construido, agua, playa, montes)
    python3 scripts/map/zonas-verdes/2_manchas.py DIR       manchas libres de al menos 64 studs de ancho
    python3 scripts/map/zonas-verdes/3_manzanas.py DIR      parques, huertas y pistas que ya existen
    python3 scripts/map/zonas-verdes/4_zonas.py DIR src/shared/CityPlan.luau   zonas con nombre -> DIR/zones.json
    python3 scripts/map/zonas-verdes/5_dibujo.py DIR textures/mapa/preview.jpg OUT.png OUT_RENDER.jpg
Resultado: docs/zonas-verdes/ (plan.md, zonas-verdes.png, zonas.json)."""
import json, math, sys
import numpy as np, cv2
from scipy import ndimage

D = sys.argv[1]
S = 8.0  # studs por pixel
X0, X1, Z0, Z1 = -5000, 5000, -4400, 4300
W, H = int((X1 - X0) / S), int((Z1 - Z0) / S)
plan = json.load(open(f"{D}/plan.json"))

def px(x, z):
    return ((x - X0) / S, (z - Z0) / S)

TREE = {"Leaves", "Branch", "Trunk", "Root", "Frond", "Flower", "Bush", "Hedge", "Grass", "Crown", "Canopy"}
built = np.zeros((H, W), np.uint8)
garden = np.zeros((H, W), np.uint8)
trees = np.zeros((H, W), np.uint8)
n = 0
with open(f"{D}/parts.tsv") as f:
    for line in f:
        c = line.rstrip("\n").split("\t")
        if len(c) < 10:
            continue
        top = float(c[1]); mat = c[4]; name = c[8]
        pts = []
        for k in c[7].split(";"):
            x, y, z = map(float, k.split(","))
            pts.append(px(x, z))
        hull = np.round(cv2.convexHull(np.array(pts, np.float32))).astype(np.int32)
        if name == "BlockGround" and c[9] != "Town":
            # manzanas y parcelas de los barrios: ya tienen uso (parques incluidos: van aparte)
            cv2.fillConvexPoly(built, hull, 255)
            cv2.fillConvexPoly(garden, hull, 255)
        elif name in TREE:
            cv2.fillConvexPoly(trees, hull, 255)
        elif mat in ("Grass", "LeafyGrass") and top < 1.5:
            cv2.fillConvexPoly(garden, hull, 255)
        else:
            cv2.fillConvexPoly(built, hull, 255)
        n += 1
print("piezas", n)

def poly_mask(poly):
    m = np.zeros((H, W), np.uint8)
    cv2.fillPoly(m, [np.round(np.array([px(*p) for p in poly], np.float32)).astype(np.int32)], 255)
    return m > 0

land = poly_mask(plan["Coast"])
dist_sea = ndimage.distance_transform_edt(land) * S
beach = land & (dist_sea < 70)
water = ~land
# Río y lagos (+ orilla de arena)
riv = np.zeros((H, W), np.uint8)
pts = plan["River"]["Points"]
for a, b in zip(pts, pts[1:]):
    cv2.line(riv, tuple(map(int, px(*a))), tuple(map(int, px(*b))), 255, int((plan["River"]["Width"] + 40) / S))
for L in plan["Lakes"]:
    cx, cz = px(L["X"], L["Z"])
    cv2.circle(riv, (int(cx), int(cz)), int((L["R"] + 24) / S), 255, -1)
water = water | (riv > 0)
# Alturas de montes
yy, xx = np.mgrid[0:H, 0:W]
WX = X0 + (xx + 0.5) * S
WZ = Z0 + (yy + 0.5) * S
height = np.zeros((H, W), np.float32)
for m in plan["Mountains"]:
    d2 = (WX - m["X"]) ** 2 + (WZ - m["Z"]) ** 2
    h = np.where(d2 < m["R"] ** 2, m["H"] - m["R"] + np.sqrt(np.maximum(m["R"] ** 2 - d2, 0)), -99)
    height = np.maximum(height, h)
gy, gx = np.gradient(height, S)
slope = np.hypot(gx, gy)
# Aeropuerto (tierra ganada): ya ocupado
ap = plan["Airport"]["Land"]
blocked = built > 0
if "X0" in ap:
    x0, z0 = px(ap["X0"], ap["Z0"]); x1, z1 = px(ap["X1"], ap["Z1"])
    blocked[int(z0):int(z1), int(x0):int(x1)] = True
blocked_d = ndimage.binary_dilation(blocked, iterations=2)  # 16 studs de margen
free = land & ~water & ~beach & ~blocked_d
np.save(f"{D}/free.npy", free)
np.save(f"{D}/garden.npy", garden > 0)
np.save(f"{D}/trees.npy", trees > 0)
np.save(f"{D}/built.npy", blocked)
np.save(f"{D}/height.npy", height)
np.save(f"{D}/slope.npy", slope)
np.save(f"{D}/beach.npy", beach)
np.save(f"{D}/water.npy", water)
print("libre (km2 de studs^2/1e6):", free.sum() * S * S / 1e6, " tierra:", land.sum() * S * S / 1e6)
