#!/usr/bin/env python3
"""El arte del MAPA GRANDE sale del dibujo de referencia del dueño (su propia imagen).

Uso (desde la carpeta roblox/):
    python3 scripts/map/art.py REFERENCIA.png [--out textures/mapa]

1. Recorta la isla del dibujo (x 376..1505 de 1846x852): fuera los paneles y el logo de la referencia.
   Lo que la referencia pinta encima del mar (botones de arriba, brújula, + / − / ◎, la pista) se
   rellena con mar (inpaint) y alrededor se añade mar hasta el borde, para que el mapa llene la pantalla.
2. Lo amplía x2 (Lanczos) y lo parte en 4x3 trozos de 965x768 (≤ 1024, límite de Roblox):
   OUT/arte_<fila>_<columna>.png (los sube scripts/upload-map.sh).
3. Ajusta la deformación mundo -> dibujo (thin-plate spline con suavizado) con puntos de control: los
   lugares de verdad (docs/mapa/lugares.json) y dónde los pinta el dibujo, y el centro de cada distrito.
   Escribe src/shared/MapWarp.luau (ida y vuelta) y enseña el error de cada punto.
Las coordenadas del "dibujo" son píxeles de la referencia (1846x852): el arte las cubre de AX0..AX1 y
AY0..AY1 (con el mar añadido).
"""
import argparse
import json
import math
import os

import cv2
import numpy as np

# Recorte de la isla en la referencia y mar añadido alrededor (en píxeles de la referencia)
CROP = (376, 0, 1505, 852)  # x0, y0, x1, y1
PAD_X, PAD_Y = 400, 150
UPSCALE = 2
COLS, ROWS = 4, 3
DEEP = (10, 46, 104)  # RGB del mar lejano: el fondo de la pantalla del mapa (MapScreen.Colors.Sea)

# Lo que la referencia pinta encima del mar dentro del recorte (se rellena con mar)
MASKS = [
    ("rect", 368, 6, 545, 78),  # botones de arriba de la referencia
    ("circle", 1436, 80, 74),  # brújula
    ("rect", 1436, 548, 1505, 762),  # + / − / ◎
    ("rect", 1412, 776, 1505, 842),  # pista de abajo a la derecha
]

# Puntos de control: (nombre, X, Z del mundo, x, y en la referencia, ¿entra en el ajuste?)
# Mundo: docs/mapa/lugares.json y los centros de los distritos (shared/CityPlan)
CONTROL = [
    ("Aeródromo de las Gaviotas", 2898, -3989, 1103, 42, True),
    ("Aeropuerto de Valmar", -3010, 3088, 540, 703, True),
    ("Isla del Faro", 4427, 2650, 1332, 722, True),
    ("Puerto de Valmar", 681, 3500, 957, 772, True),
    ("Puerto Deportivo", -3940, 1248, 485, 528, True),
    ("Estación Central", 750, 523, 862, 452, True),
    ("Estación de Autobuses", -742, 776, 793, 513, True),
    ("Hotel (Oeste, el del norte)", -3533, -2087, 476, 230, True),
    ("Gimnasio (Este)", 3450, -710, 1163, 387, True),
    ("Ayuntamiento", -750, 286, 946, 310, False),  # (pintado al noreste del centro; el de verdad está al suroeste)
    ("Distrito Centro", 0, 0, 862, 362, True),
    ("Distrito Norte", -12, -2118, 865, 148, True),
    ("Distrito Oeste", -2889, -168, 575, 313, True),
    ("Distrito Este", 3100, -1593, 1220, 272, True),
    ("Distrito Universitario", 3006, 1838, 1195, 533, True),
    ("Distrito Sur", -21, 2751, 905, 641, True),
    # Costa (extremos de la isla de verdad y del dibujo): sujetan los bordes
    ("Costa oeste", -4100, -500, 395, 360, True),
    ("Costa este", 4200, -300, 1405, 335, True),
    ("Costa sur", 0, 3550, 870, 805, True),
    ("Costa noroeste", -3600, -2850, 440, 150, True),
    ("Costa noreste", 3400, -2850, 1320, 125, True),
    ("Costa suroeste", -2700, 2650, 500, 640, True),
]

WORLD_K = 1000.0  # (normalización: studs / 1000 y píxeles / 100)
ART_K = 100.0


def tps_fit(src, dst, smooth):
    """Thin-plate spline src -> dst (2D) con suavizado `smooth`. Devuelve (pesos, afín)."""
    n = len(src)

    def U(r2):
        with np.errstate(divide="ignore", invalid="ignore"):
            return np.where(r2 > 0, r2 * np.log(r2), 0.0)

    d2 = ((src[:, None, :] - src[None, :, :]) ** 2).sum(-1)
    K = U(d2) + smooth * np.eye(n)
    P = np.hstack([np.ones((n, 1)), src])
    A = np.zeros((n + 3, n + 3))
    A[:n, :n] = K
    A[:n, n:] = P
    A[n:, :n] = P.T
    b = np.zeros((n + 3, 2))
    b[:n] = dst
    sol = np.linalg.solve(A, b)
    return sol[:n], sol[n:]


def tps_eval(src, w, a, p):
    d2 = ((p[:, None, :] - src[None, :, :]) ** 2).sum(-1)
    with np.errstate(divide="ignore", invalid="ignore"):
        u = np.where(d2 > 0, d2 * np.log(d2), 0.0)
    return a[0] + p @ a[1:] + u @ w


def lua_num(v):
    return repr(float(round(v, 9)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("reference")
    ap.add_argument("--out", default="textures/mapa")
    ap.add_argument("--warp", default="src/shared/MapWarp.luau")
    ap.add_argument("--smooth", type=float, default=0.02)
    args = ap.parse_args()

    ref = cv2.imread(args.reference, cv2.IMREAD_COLOR)
    assert ref.shape[:2] == (852, 1846), ref.shape
    # ------------------------------------------------------------------
    # 1. Recorte, relleno de mar y mar alrededor
    # ------------------------------------------------------------------
    mask = np.zeros(ref.shape[:2], np.uint8)
    for m in MASKS:
        if m[0] == "rect":
            cv2.rectangle(mask, (m[1], m[2]), (m[3], m[4]), 255, -1)
        else:
            cv2.circle(mask, (m[1], m[2]), m[3], 255, -1)
    filled = cv2.inpaint(ref, mask, 9, cv2.INPAINT_TELEA)
    # (el inpaint deja manchas lisas: un poco de grano del mar de alrededor)
    rng = np.random.default_rng(3)
    grain = cv2.GaussianBlur(rng.normal(0, 6, ref.shape).astype(np.float32), (0, 0), 1.2)
    soft = cv2.GaussianBlur(mask, (0, 0), 3).astype(np.float32)[..., None] / 255.0
    filled = np.clip(filled.astype(np.float32) + grain * soft, 0, 255).astype(np.uint8)
    x0, y0, x1, y1 = CROP
    crop = filled[y0:y1, x0:x1]
    ch, cw = crop.shape[:2]
    H, W = ch + PAD_Y * 2, cw + PAD_X * 2
    # Mar alrededor: el color del borde del recorte, cada vez más difuminado, hasta el azul de fondo
    deep_bgr = np.array(DEEP[::-1], np.float32)
    big = cv2.copyMakeBorder(crop, PAD_Y, PAD_Y, PAD_X, PAD_X, cv2.BORDER_CONSTANT, value=0).astype(np.float32)
    inside = np.zeros((H, W), np.uint8)
    inside[PAD_Y:PAD_Y + ch, PAD_X:PAD_X + cw] = 255
    dist = cv2.distanceTransform(255 - inside, cv2.DIST_L2, 5)  # píxeles fuera del recorte
    # Fuera del recorte: el color del borde extendido suave (inpaint a 1/8 y ampliado: sin rayas)
    k = 8
    small = cv2.resize(big.astype(np.uint8), (W // k, H // k), interpolation=cv2.INTER_AREA)
    hole = cv2.resize(255 - inside, (W // k, H // k), interpolation=cv2.INTER_NEAREST)
    hole = cv2.dilate(hole, np.ones((3, 3), np.uint8))
    small = cv2.inpaint(small, hole, 12, cv2.INPAINT_TELEA)
    small = cv2.GaussianBlur(small, (0, 0), 3)
    blurred = cv2.resize(small, (W, H), interpolation=cv2.INTER_CUBIC).astype(np.float32)
    blurred = cv2.GaussianBlur(blurred, (0, 0), 6)
    big = np.where(inside[..., None] > 0, big, blurred)
    # ¿El borde del recorte es mar? (azul): ahí el mar sigue; si es tierra (arriba), se funde antes
    sea_like = (blurred[..., 0] > blurred[..., 2] + 25).astype(np.float32)
    sea_like = cv2.GaussianBlur(sea_like, (0, 0), 25)
    out = big
    far = np.clip((dist - 30) / (PAD_X * 0.7), 0, 1)[..., None]
    far = np.maximum(far, (1 - sea_like[..., None]) * np.clip(dist / 40.0, 0, 1)[..., None])
    out = out * (1 - far) + deep_bgr * far
    # El borde de fuera, exactamente el azul de fondo (sin escalón con el fondo de la pantalla)
    edge = np.minimum.reduce([np.arange(W)[None, :].repeat(H, 0), (W - 1 - np.arange(W))[None, :].repeat(H, 0), np.arange(H)[:, None].repeat(W, 1), (H - 1 - np.arange(H))[:, None].repeat(W, 1)]).astype(np.float32)
    e = np.clip(edge / 50.0, 0, 1)[..., None]
    out = out * e + deep_bgr * (1 - e)
    # Olas: ruido estirado en horizontal (crestas cortas y claras), suave
    noise_a = cv2.GaussianBlur(rng.normal(0, 1, (H, W)).astype(np.float32), (0, 0), sigmaX=5, sigmaY=1.2)
    noise_b = cv2.GaussianBlur(rng.normal(0, 1, (H, W)).astype(np.float32), (0, 0), sigmaX=14, sigmaY=4)
    crest = np.clip(noise_a / (noise_a.std() + 1e-6) - 1.2, 0, None) * 14
    texture = (crest + noise_b / (noise_b.std() + 1e-6) * 5)[..., None] * np.array([1.0, 0.9, 0.7], np.float32)
    out = out + texture * (1 - far) * np.clip(dist / 20.0, 0, 1)[..., None]
    # Junto al borde del recorte (por dentro), el mar del dibujo se funde con el de fuera: sin costura
    dist_in = cv2.distanceTransform(inside, cv2.DIST_L2, 5)
    feather = (1 - np.clip(dist_in / 60.0, 0, 1)) * sea_like
    feather = np.where(inside > 0, feather, 0)[..., None]
    outside_col = blurred + texture
    out = np.where(inside[..., None] > 0, big * (1 - feather) + outside_col * feather, out)
    out = np.clip(out, 0, 255).astype(np.uint8)

    # ------------------------------------------------------------------
    # 2. Ampliar x2 y trocear
    # ------------------------------------------------------------------
    up = cv2.resize(out, (W * UPSCALE, H * UPSCALE), interpolation=cv2.INTER_LANCZOS4)
    # (un poco de nitidez tras ampliar)
    soft_up = cv2.GaussianBlur(up, (0, 0), 1.0)
    up = cv2.addWeighted(up, 1.35, soft_up, -0.35, 0)
    UH, UW = up.shape[:2]
    UW -= UW % COLS
    UH -= UH % ROWS
    up = up[:UH, :UW]
    tw, th = UW // COLS, UH // ROWS
    assert tw <= 1024 and th <= 1024, (tw, th)
    os.makedirs(args.out, exist_ok=True)
    for name in os.listdir(args.out):
        if name.startswith("mapa_") and name.endswith(".png"):
            os.remove(os.path.join(args.out, name))  # (la imagen de antes, hecha con render.py)
    for r in range(ROWS):
        for c in range(COLS):
            path = os.path.join(args.out, f"arte_{r}_{c}.png")
            cv2.imwrite(path, up[r * th:(r + 1) * th, c * tw:(c + 1) * tw], [cv2.IMWRITE_PNG_COMPRESSION, 9])
            print(f"  {path} {tw}x{th} ({os.path.getsize(path) // 1024} KB)")
    cv2.imwrite(os.path.join(args.out, "preview.jpg"), cv2.resize(up, (UW // 2, UH // 2), interpolation=cv2.INTER_AREA), [cv2.IMWRITE_JPEG_QUALITY, 90])
    # Qué parte de la referencia cubre el arte (píxeles de la referencia)
    AX0, AY0 = x0 - PAD_X, y0 - PAD_Y
    AX1, AY1 = AX0 + UW / UPSCALE, AY0 + UH / UPSCALE
    meta = {"Width": UW, "Height": UH, "Cols": COLS, "Rows": ROWS, "TileWidth": tw, "TileHeight": th, "AX0": AX0, "AY0": AY0, "AX1": AX1, "AY1": AY1}
    json.dump(meta, open(os.path.join(args.out, "meta.json"), "w"), indent=1)

    # ------------------------------------------------------------------
    # 3. Deformación mundo <-> dibujo
    # ------------------------------------------------------------------
    used = [c for c in CONTROL if c[5]]
    world = np.array([[c[1] / WORLD_K, c[2] / WORLD_K] for c in used])
    art = np.array([[c[3] / ART_K, c[4] / ART_K] for c in used])
    wf, af = tps_fit(world, art, args.smooth)
    wi, ai = tps_fit(art, world, args.smooth)
    print("\n▶ Error de la deformación en cada punto de control (píxeles de la referencia 1846x852)")
    report = []
    for c in CONTROL:
        p = np.array([[c[1] / WORLD_K, c[2] / WORLD_K]])
        got = tps_eval(world, wf, af, p)[0] * ART_K
        err = math.hypot(got[0] - c[3], got[1] - c[4])
        back = tps_eval(art, wi, ai, got[None, :] / ART_K)[0] * WORLD_K
        round_trip = math.hypot(back[0] - c[1], back[1] - c[2])
        line = f"  {'·' if c[5] else '✗'} {c[0]:<30} {err:6.1f} px   (ida y vuelta {round_trip:6.0f} studs)"
        print(line)
        report.append({"Name": c[0], "Used": c[5], "ErrorPx": round(err, 1), "RoundTripStuds": round(round_trip)})
    json.dump(report, open(os.path.join(args.out, "warp-error.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)

    def lua_points(pts, k):
        return ", ".join("{ %s, %s }" % (lua_num(p[0]), lua_num(p[1])) for p in pts)

    def lua_pairs(arr):
        return ", ".join("{ %s, %s }" % (lua_num(v[0]), lua_num(v[1])) for v in arr)

    with open(args.warp, "w", encoding="utf-8") as fh:
        fh.write("-- MapWarp: GENERADO por scripts/map/art.py (no editar a mano).\n")
        fh.write("-- Deformación del mundo (X, Z en studs) al dibujo del mapa grande (píxeles de la referencia, 1846x852)\n")
        fh.write("-- y vuelta: thin-plate spline ajustado con los lugares de verdad y dónde los pinta el dibujo.\n")
        fh.write("-- La usan shared/MapScreen y Controllers/MapUI (tu flecha, la ruta del GPS, los lugares, «Ir aquí»).\n")
        fh.write("return {\n")
        fh.write(f"\tWorldK = {lua_num(WORLD_K)},\n\tArtK = {lua_num(ART_K)},\n")
        fh.write("\t-- El arte (textures/mapa/arte_<fila>_<columna>.png): qué parte del dibujo cubre y sus trozos\n")
        fh.write(f"\tArt = {{ AX0 = {AX0}, AY0 = {AY0}, AX1 = {AX1}, AY1 = {AY1}, Width = {UW}, Height = {UH}, Cols = {COLS}, Rows = {ROWS} }},\n")
        fh.write("\tForward = {\n")
        fh.write(f"\t\tCenters = {{ {lua_points(world, 1)} }},\n")
        fh.write(f"\t\tWeights = {{ {lua_pairs(wf)} }},\n")
        fh.write(f"\t\tAffine = {{ {lua_pairs(af)} }},\n")
        fh.write("\t},\n")
        fh.write("\tInverse = {\n")
        fh.write(f"\t\tCenters = {{ {lua_points(art, 1)} }},\n")
        fh.write(f"\t\tWeights = {{ {lua_pairs(wi)} }},\n")
        fh.write(f"\t\tAffine = {{ {lua_pairs(ai)} }},\n")
        fh.write("\t},\n")
        fh.write("\tControl = {\n")
        for c in CONTROL:
            fh.write(f"\t\t{{ Name = \"{c[0]}\", X = {c[1]}, Z = {c[2]}, U = {c[3]}, V = {c[4]}, Used = {'true' if c[5] else 'false'} }},\n")
        fh.write("\t},\n")
        fh.write("}\n")
    print("✅ " + args.warp)


if __name__ == "__main__":
    main()
