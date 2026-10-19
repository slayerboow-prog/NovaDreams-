"""Textura de Valmar como planeta (assets/espacio/valmar_planeta.jpg), hecha con el MAPA DE VERDAD.

Uso (desde roblox/):   python3 -I scripts/espacio/gen_valmar_planeta.py [--preview]
Necesita:              pip install numpy pillow

De dónde sale: las 12 teselas del mapa grande (textures/mapa/isla_<fila>_<col>.png, el render de la isla
de scripts/map/blender_render.py; cámara en shared/MapProjection). Se pasan a una imagen
equirrectangular de 1024x512 (el máximo de Roblox) para la esfera de Controllers/ValmarGlobeClient con
la MISMA cuenta que shared/Cosmos/ValmarGlobe.texelToWorld: el polo de arriba es el centro de la isla y
cada punto de Valmar a distancia d del centro queda a un arco d de la cima (acimutal equidistante,
Radius = 5000 studs). Fuera de la isla, mar (más claro junto a la costa, oscuro mar adentro).

Se sube con el resto: bash scripts/upload-espacio.sh valmar_planeta (lo hace la sesión que publica). Si
en el juego la isla sale girada o en espejo, se cambian ValmarGlobe.TexYaw / TexMirror (y aquí igual).
Licencia: propia (el mapa es del juego); ver assets/espacio/LICENCIAS.md.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "espacio" / "valmar_planeta.jpg"
PREVIEW = ROOT / "docs" / "planetas" / "valmar_planeta_preview.jpg"

# shared/Cosmos/ValmarGlobe (que coincidan)
RADIUS = 5000.0
CENTER_X, CENTER_Z = 0.0, 0.0
TEX_YAW = 0.0
TEX_MIRROR = False

# shared/MapProjection (generado por blender_render.py)
TILT = math.radians(52.0)
ORTHO_W = 10600.0
CX = 50.0
CS = 330.0
ART_W, ART_H = 4096, 2400
COLS, ROWS = 4, 3
SEA = np.array([0, 82, 175], dtype=np.float32)

W, H = 1024, 512


def stitch() -> np.ndarray:
    tile_w, tile_h = ART_W // COLS, ART_H // ROWS
    art = Image.new("RGB", (ART_W, ART_H))
    for r in range(ROWS):
        for c in range(COLS):
            tile = Image.open(ROOT / "textures" / "mapa" / f"isla_{r}_{c}.png").convert("RGB")
            if tile.size != (tile_w, tile_h):
                tile = tile.resize((tile_w, tile_h), Image.LANCZOS)
            art.paste(tile, (c * tile_w, r * tile_h))
    return np.asarray(art, dtype=np.float32)


def main() -> None:
    art = stitch()
    spp = ORTHO_W / ART_W
    v, u = np.mgrid[0:H, 0:W].astype(np.float32)
    u = (u + 0.5) / W
    v = (v + 0.5) / H
    theta = v * math.pi
    lon = np.radians(u * 360.0 + TEX_YAW)
    if TEX_MIRROR:
        lon = -lon
    d = theta * RADIUS
    x = CENTER_X + d * np.sin(lon)
    z = CENTER_Z - d * np.cos(lon)
    # mundo -> píxel del render (shared/MapScreen.toArt con y = 0)
    s = -z * math.cos(TILT)
    px = (x - CX) / spp + ART_W / 2
    py = ART_H / 2 - (s - CS) / spp
    inside = (px >= 0) & (px < ART_W - 1) & (py >= 0) & (py < ART_H - 1)
    # bilineal
    pxc = np.clip(px, 0, ART_W - 1.001)
    pyc = np.clip(py, 0, ART_H - 1.001)
    x0, y0 = np.floor(pxc).astype(int), np.floor(pyc).astype(int)
    fx, fy = (pxc - x0)[..., None], (pyc - y0)[..., None]
    c00 = art[y0, x0]
    c10 = art[y0, x0 + 1]
    c01 = art[y0 + 1, x0]
    c11 = art[y0 + 1, x0 + 1]
    sample = (c00 * (1 - fx) + c10 * fx) * (1 - fy) + (c01 * (1 - fx) + c11 * fx) * fy
    # Mar: el del render donde lo hay; fuera, mar adentro con algo de ruido (más oscuro lejos)
    rng = np.random.default_rng(7)
    noise = rng.normal(0, 1, (H // 8, W // 8)).astype(np.float32)
    noise = np.asarray(Image.fromarray(((noise * 20) + 128).clip(0, 255).astype(np.uint8)).resize((W, H), Image.BICUBIC), dtype=np.float32)
    noise = (noise - 128) / 128.0
    far = np.clip((d - 5200.0) / 9000.0, 0, 1)[..., None]
    deep = np.array([10, 44, 96], dtype=np.float32)
    ocean = SEA * (1 - far) + deep * far
    ocean = ocean + noise[..., None] * np.array([3, 6, 10], dtype=np.float32)
    # (el mar del render se funde con el de fuera: sin el borde cuadrado del render; la tierra y los
    # bajíos turquesa, que se apartan del azul del mar, se quedan)
    land = np.clip((np.linalg.norm(sample - SEA, axis=-1) - 22.0) / 40.0, 0, 1)[..., None]
    land = np.where(inside[..., None], land, 0.0)
    out = ocean * (1 - land) + sample * land
    # Junta suave entre el render y el mar de fuera
    img = Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGB")
    img = img.filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, quality=92)
    print(f"✅ {OUT.relative_to(ROOT)} ({W}x{H})")
    if "--preview" in sys.argv:
        # Vista del casquete de arriba (como se ve desde el espacio): polar
        n = 512
        yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
        dx, dz = (xx - n / 2) / (n / 2), (yy - n / 2) / (n / 2)
        rr = np.sqrt(dx * dx + dz * dz)
        th = np.clip(rr, 0, 1) * (math.pi / 2)
        lo = (np.degrees(np.arctan2(dx, -dz)) - TEX_YAW) % 360
        uu = (lo / 360 * W).astype(int) % W
        vv = np.clip((th / math.pi * H).astype(int), 0, H - 1)
        cap = out[vv, uu]
        cap[rr > 1] = 0
        PREVIEW.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(cap.clip(0, 255).astype(np.uint8)).save(PREVIEW, quality=88)
        print(f"✅ {PREVIEW.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
