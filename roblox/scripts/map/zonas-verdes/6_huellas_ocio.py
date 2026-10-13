#!/usr/bin/env python3
"""Huellas de la ciudad alrededor de los sitios de ocio (src/shared/OcioSitios.luau).

Uso (desde roblox/; DIR = la carpeta de 1_mascaras.py, hecha con la ciudad SIN los sitios de ocio: por ejemplo,
quitando un momento la línea de Kit/ZonasVerdes/Ocio de TownBuilder; si no, sus piezas salen como ocupado):
    python3 scripts/map/zonas-verdes/6_huellas_ocio.py DIR [docs/zonas-verdes/huellas-ocio.json]

Para cada sitio guarda un recorte de la máscara (1 cuadro = 8 studs) con lo que está ocupado: calle, acera,
manzana, parcela, edificio (built.npy), agua (mar, río, lagos) y playa. scripts/test-ocio.luau construye los
sitios y comprueba que ninguna pieza cae en un cuadro ocupado. También dice si el rectángulo de cada sitio está
en la zona libre del plan (free.npy: con 16 studs de margen y llano)."""
import json, re, sys
import numpy as np

D = sys.argv[1]
OUT = sys.argv[2] if len(sys.argv) > 2 else "docs/zonas-verdes/huellas-ocio.json"
S = 8.0; X0 = -5000; Z0 = -4400
MARGIN = 96
built = np.load(f"{D}/built.npy"); water = np.load(f"{D}/water.npy"); beach = np.load(f"{D}/beach.npy")
free = np.load(f"{D}/free.npy")
occupied = built | water | beach
src = open("src/shared/OcioSitios.luau", encoding="utf-8").read()
sites = re.findall(r'Id = "(\w+)", Zone = (\d+).*?Center = \{ (-?\d+), (-?\d+) \}, Size = \{ (\d+), (\d+) \}', src)
out = {"S": S, "Sites": {}}
ok_all = True
for sid, zone, cx, cz, w, d in sites:
    cx, cz, w, d = map(float, (cx, cz, w, d))
    gx0 = int(np.floor((cx - w / 2 - MARGIN - X0) / S)); gx1 = int(np.ceil((cx + w / 2 + MARGIN - X0) / S))
    gz0 = int(np.floor((cz - d / 2 - MARGIN - Z0) / S)); gz1 = int(np.ceil((cz + d / 2 + MARGIN - Z0) / S))
    crop = occupied[gz0:gz1, gx0:gx1]
    rows = ["".join("1" if v else "0" for v in row) for row in crop]
    out["Sites"][sid] = {"Zone": int(zone), "X0": X0 + gx0 * S, "Z0": Z0 + gz0 * S, "Cols": gx1 - gx0, "Rows": rows}
    rx0 = int((cx - w / 2 - X0) / S); rx1 = int(np.ceil((cx + w / 2 - X0) / S))
    rz0 = int((cz - d / 2 - Z0) / S); rz1 = int(np.ceil((cz + d / 2 - Z0) / S))
    inside_free = free[rz0:rz1, rx0:rx1].mean()
    hit = occupied[rz0:rz1, rx0:rx1].sum()
    print(f"{sid:8s} zona {zone:>2s}: libre {inside_free * 100:5.1f} %  cuadros ocupados {hit}")
    ok_all = ok_all and hit == 0
json.dump(out, open(OUT, "w"), separators=(",", ":"))
print("escrito", OUT)
sys.exit(0 if ok_all else 1)
