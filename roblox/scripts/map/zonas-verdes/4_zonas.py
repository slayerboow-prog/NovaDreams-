#!/usr/bin/env python3
"""Zonas verdes libres de Valmar: agrupa las manchas libres (comps.py) en zonas con nombre, mide cada
una y escribe zones.json (para el plan) con lo que tiene cerca."""
import json, math, re, sys
import numpy as np
from scipy import ndimage

D = sys.argv[1]
CITYPLAN = sys.argv[2]
S = 8.0; X0 = -5000; Z0 = -4400
lab = np.load(f'{D}/lab.npy'); free = np.load(f'{D}/free.npy'); h = np.load(f'{D}/height.npy')
garden = np.load(f'{D}/garden.npy'); trees = np.load(f'{D}/trees.npy')
H, W = lab.shape
yy, xx = np.mgrid[0:H, 0:W]
WX = X0 + (xx + 0.5) * S
WZ = Z0 + (yy + 0.5) * S

def box(x0, x1, z0, z1):
    return (WX >= x0) & (WX < x1) & (WZ >= z0) & (WZ < z1)

def at(*pts):
    """Las manchas libres que contienen estos puntos (x, z) del mundo."""
    ids = []
    for x, z in pts:
        i, j = int((z - Z0) / S), int((x - X0) / S)
        win = lab[max(0, i - 3):i + 4, max(0, j - 3):j + 4]
        vals = win[win > 0]
        if len(vals) == 0:
            print("¡sin mancha en!", x, z)
            continue
        ids.append(int(np.bincount(vals).argmax()))
    return np.isin(lab, ids)

C1 = at((-2648, -2904))
# id, nombre, máscara
ZONES = [
    (1, "Prados de Poniente", C1 & (WX < -2900) & (WZ > -2350)),
    (2, "Montes de Villaverde y Lago de Montaña", C1 & (WX < -1250) & (WZ <= -2350)),
    (3, "Ladera del Mirador", (C1 & (WX >= -1250) & (WX < 700) & (WZ < -2300)) | at((-1048, -2568))),
    (4, "Fuentes del Río", C1 & (WX >= 700) & (WX < 1450)),
    (5, "Colinas de Levante", C1 & (WX >= 1560)),
    (6, "Costa de Levante", at((3888, -312), (3624, -1520))),
    (7, "Explanada del Este", at((1936, -208))),
    (8, "Prado del Campus Norte", at((2120, 208), (3624, 208))),
    (9, "Ribera Universitaria", at((1696, 2200))),
    (10, "Ribera del Puerto", at((1336, 1488))),
    (11, "Orillas del río", at((1328, -1608), (1616, -2216), (1624, -808), (1384, -144), (1624, 648), (1376, 1120))),
    (12, "Paseo del Puerto", at((160, 3328))),
    (13, "Llanura de San Roque Sur", at((-1352, 3104), (-160, 2744))),
    (14, "Entrada de San Roque", at((-1288, 1528))),
    (15, "Costa Suroeste", at((-2560, 2464), (-2624, 1984))),
    (16, "Prado de la Marina", at((-3480, 528), (-3536, 1280))),
    (17, "Orilla del Lago del Parque Natural", at((-2992, -80))),
    (18, "Linde Oeste de la Ronda", at((-1456, -880), (-1488, 1248))),
    (19, "Puerta de Villaverde", at((-1528, -1768))),
    (20, "Paseo del Norte", at((-160, -1744), (-160, -2216))),
    (21, "Jardines de la Plaza Mayor", at((440, -184), (-440, -184))),
    (22, "Rincones del Campus", at((2976, 1824), (2496, 3000), (3488, 1264))),
]

# Carreteras de CityPlan
src = open(CITYPLAN).read()
roads = []
for m in re.finditer(r'\{ Name = "([^"]+)", Kind = "(\w+)", Points = (.*)$', src, re.M):
    pts = [(int(a), int(b)) for a, b in re.findall(r'\{ (-?\d+), (-?\d+) \}', m.group(3))]
    roads.append((m.group(1), m.group(2), pts))

def segd(x, z, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    L2 = dx * dx + dz * dz
    t = max(0, min(1, ((x - a[0]) * dx + (z - a[1]) * dz) / L2)) if L2 else 0
    return math.hypot(x - a[0] - t * dx, z - a[1] - t * dz)

plan = json.load(open(f'{D}/plan.json'))
def inside(poly, x, z):
    c = False; j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]; xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            c = not c
        j = i
    return c

lm = json.load(open(f'{D}/landmarks.json'))
SKIP = {"ParadaBus", "BocaMetro"}
dt = ndimage.distance_transform_edt(free) * S
out = []
for zid, name, m in ZONES:
    m = m & free
    n = int(m.sum())
    ys, xs = np.nonzero(m)
    cx, cz = X0 + xs.mean() * S, Z0 + ys.mean() * S
    k = np.argmax(np.where(m, dt, 0)); ky, kx = np.unravel_index(k, m.shape)
    bx, bz, br = X0 + kx * S, Z0 + ky * S, dt[ky, kx]
    flat = m & (h < 6)
    # mayor círculo llano
    dtf = ndimage.distance_transform_edt(flat) * S
    k2 = np.argmax(dtf); fy, fx = np.unravel_index(k2, m.shape)
    dist = []
    for name_r, kind, pts in roads:
        d = min(segd(bx, bz, a, b) for a, b in zip(pts, pts[1:]))
        dist.append((d, name_r))
    dist.sort()
    near = sorted(((math.hypot(p['X'] - cx, p['Z'] - cz), p['Name'], p['Kind']) for p in lm if p['Kind'] not in SKIP))
    near = [f"{nm} ({int(d)})" for d, nm, k in near[:5] if d < 900]
    dname = next((d['Name'] for d in plan['Districts'] if inside(d['Poly'], cx, cz)), "Campo (fuera de distrito)")
    out.append(dict(id=zid, name=name, district=dname, area=int(n * S * S), x0=int(X0 + xs.min() * S), x1=int(X0 + xs.max() * S),
                    z0=int(Z0 + ys.min() * S), z1=int(Z0 + ys.max() * S), cx=int(cx), cz=int(cz), best=(int(bx), int(bz), int(br * 2)),
                    flat_pct=int(100 * flat.sum() / max(n, 1)), flat_circle=(int(X0 + fx * S), int(Z0 + fy * S), int(dtf[fy, fx] * 2)),
                    hill_max=int(h[m].max()), trees_pct=int(100 * (m & trees).sum() / max(n, 1)), garden_pct=int(100 * (m & garden).sum() / max(n, 1)),
                    roads=[f"{r} ({int(d)})" for d, r in dist[:2]], near=near))
for o in out:
    print(o)
json.dump(out, open(f'{D}/zones.json', 'w'), ensure_ascii=False, indent=1)
masks = np.zeros((H, W), np.int16)
for zid, name, m in ZONES:
    masks[m & free] = zid
np.save(f'{D}/zones.npy', masks)
