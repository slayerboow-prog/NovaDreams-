"""Genera el cielo de DÍA de Valmar (assets/paisaje/cielo_dia_*.jpg), 100 % nuestro (docs/paisaje/paisaje.md).

Uso (desde roblox/):   python3 -I scripts/paisaje/gen_cielo.py [--preview]
Necesita:              pip install numpy pillow

Por qué: el cielo de día era el de un pack de la Tienda («Simple Lighting Pack»): azul claro de dibujo y
nubes pintadas que no se mueven. La referencia del dueño tiene un cielo azul intenso arriba, horizonte
claro y luminoso y nubes de verdad (esas las pone el juego: nubes volumétricas de Roblox, Clouds, que se
mueven con el viento). Aquí sale un cielo físico sencillo, sin nubes pintadas grandes:

  * Arriba azul profundo (como el cielo del Mediterráneo con aire limpio), que se aclara hacia el
    horizonte; una franja de bruma blanca-azulada en el horizonte (luz dispersa).
  * Unos cirros muy finos y altos (velos de hielo) para que el azul no sea plano; ninguno cerca del
    horizonte (allí van las nubes de verdad).
  * Bajo el horizonte NO hay suelo ni negro: mar lejano en bruma (azul que se oscurece hacia abajo). Así
    lo que queda más allá de lo cargado del mapa se ve como mar a lo lejos (con el suelo lejano,
    shared/Horizon, y la bruma de Atmosphere encima).
  * Sin sol pintado: el sol (y su brillo) lo pone el juego, que se mueve con la hora.

Caras del Sky: la misma convención que scripts/espacio/gen.py (Front = -Z, Back = +Z, Left = -X,
Right = +X). Salen 6 caras de 1024 px (el máximo de Roblox). Se suben con scripts/upload-paisaje.sh
(escribe src/shared/PaisajeTextureIds.luau); mientras no estén subidas, el juego usa el cielo de siempre.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "paisaje"
DOCS = ROOT / "docs" / "paisaje"
SKY = 1024

FACES = {
    # nombre: (dirección del centro, derecha de la imagen, arriba de la imagen)
    "ft": ((0, 0, -1), (1, 0, 0), (0, 1, 0)),
    "bk": ((0, 0, 1), (-1, 0, 0), (0, 1, 0)),
    "lf": ((-1, 0, 0), (0, 0, -1), (0, 1, 0)),
    "rt": ((1, 0, 0), (0, 0, 1), (0, 1, 0)),
    "up": ((0, 1, 0), (1, 0, 0), (0, 0, 1)),
    "dn": ((0, -1, 0), (1, 0, 0), (0, 0, -1)),
}

# ---------------------------------------------------------------------------
# Ruido 3D de valor (sobre la esfera: sin costuras entre caras)
# ---------------------------------------------------------------------------
_rng = np.random.default_rng(118)
PERM = _rng.permutation(256).astype(np.int32)
PERM = np.concatenate([PERM, PERM])
VALS = _rng.random(256).astype(np.float32)


def vnoise(p):
    x, y, z = p[..., 0], p[..., 1], p[..., 2]
    xi, yi, zi = np.floor(x).astype(np.int32), np.floor(y).astype(np.int32), np.floor(z).astype(np.int32)
    xf, yf, zf = x - xi, y - yi, z - zi
    u, v, w = (t * t * t * (t * (t * 6 - 15) + 10) for t in (xf, yf, zf))
    xi, yi, zi = xi & 255, yi & 255, zi & 255

    def h(a, b, c):
        return VALS[PERM[PERM[PERM[(xi + a) & 255] + ((yi + b) & 255)] + ((zi + c) & 255)]]

    x00 = h(0, 0, 0) * (1 - u) + h(1, 0, 0) * u
    x10 = h(0, 1, 0) * (1 - u) + h(1, 1, 0) * u
    x01 = h(0, 0, 1) * (1 - u) + h(1, 0, 1) * u
    x11 = h(0, 1, 1) * (1 - u) + h(1, 1, 1) * u
    return (x00 * (1 - v) + x10 * v) * (1 - w) + (x01 * (1 - v) + x11 * v) * w


def fbm(p, octaves=5, freq=1.0, gain=0.5):
    total, amp, norm = 0.0, 1.0, 0.0
    for i in range(octaves):
        total = total + amp * vnoise(p * freq + i * 17.3)
        norm += amp
        amp *= gain
        freq *= 2.03
    return total / norm


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def col(*rgb):
    return np.array(rgb, np.float32) / 255.0


def face_dirs(name, n=SKY):
    c, r, u = (np.array(v, np.float32) for v in FACES[name])
    s = (np.arange(n, dtype=np.float32) + 0.5) / n * 2 - 1
    xs, ys = np.meshgrid(s, -s)
    d = c[None, None] + xs[..., None] * r[None, None] + ys[..., None] * u[None, None]
    d /= np.linalg.norm(d, axis=-1, keepdims=True)
    return d


# ---------------------------------------------------------------------------
# El cielo
# ---------------------------------------------------------------------------
ZENITH = col(34, 98, 196)
MID = col(74, 146, 226)
HORIZON = col(196, 222, 244)
HAZE = col(226, 236, 246)
SEA_HAZE = col(160, 196, 222)
SEA = col(40, 104, 150)
DEEP = col(22, 70, 112)


def day_sky(d):
    y = d[..., 1]
    e = np.arcsin(np.clip(y, -1, 1))  # elevación (rad)
    up = np.clip(e / (np.pi / 2), 0, 1)
    # Arriba: horizonte claro -> azul medio -> cénit profundo (curva tipo dispersión de Rayleigh)
    t1 = smooth(0.0, 0.32, up) ** 0.85
    t2 = smooth(0.18, 1.0, up) ** 0.9
    sky = HORIZON * (1 - t1[..., None]) + MID * t1[..., None]
    sky = sky * (1 - t2[..., None]) + ZENITH * t2[..., None]
    # Franja de bruma luminosa en el horizonte (0-5°)
    band = np.exp(-np.maximum(e, 0) / np.radians(2.6))[..., None]
    sky = sky * (1 - 0.65 * band) + HAZE * 0.65 * band
    # Cirros finos y altos (estirados en una dirección), solo por encima de ~18°
    # (sobre un «techo» plano de nubes altas: en perspectiva, como de verdad, sin remolinos en el cénit)
    yy = np.maximum(y, 0.05)
    plane = np.stack([d[..., 0] / yy * 1.6, d[..., 2] / yy * 0.45, np.full_like(y, 3.7)], -1).astype(np.float32)
    streak = fbm(plane, 5, 1.0)
    cirrus = smooth(0.6, 0.84, streak) * smooth(np.radians(16), np.radians(40), e) * 0.15
    sky = sky * (1 - cirrus[..., None]) + col(250, 252, 255) * cirrus[..., None]
    # Bajo el horizonte: mar lejano en bruma (no suelo, no negro)
    down = np.clip(-e / (np.pi / 2), 0, 1)
    s1 = smooth(0.0, 0.16, down) ** 0.8
    s2 = smooth(0.06, 0.6, down)
    sea = SEA_HAZE * (1 - s1[..., None]) + SEA * s1[..., None]
    sea = sea * (1 - s2[..., None]) + DEEP * s2[..., None]
    below = (e < 0)[..., None]
    out = np.where(below, sea, sky)
    # Grano muy fino (evita bandas de color en el JPG)
    grain = (vnoise(d * 600.0) - 0.5) * (1.5 / 255)
    return np.clip(out + grain[..., None], 0, 1)


def save(img, name, quality=94):
    OUT.mkdir(parents=True, exist_ok=True)
    arr = np.clip(img * 255 + 0.5, 0, 255).astype(np.uint8)
    path = OUT / name
    Image.fromarray(arr).save(path, quality=quality, optimize=True, subsampling=0)
    print("  ✓", path.relative_to(ROOT), arr.shape[1], "x", arr.shape[0])
    return arr


def main():
    preview = "--preview" in sys.argv
    faces = {}
    for name in FACES:
        faces[name] = save(day_sky(face_dirs(name)), f"cielo_dia_{name}.jpg")
    if preview:
        # Tira horizontal (lf, ft, rt, bk) + arriba, para la documentación
        small = {k: np.asarray(Image.fromarray(v).resize((256, 256), Image.LANCZOS)) for k, v in faces.items()}
        strip = np.zeros((512, 1024, 3), np.uint8)
        for i, k in enumerate(("lf", "ft", "rt", "bk")):
            strip[256:, i * 256:(i + 1) * 256] = small[k]
        strip[:256, 256:512] = small["up"]
        DOCS.mkdir(parents=True, exist_ok=True)
        Image.fromarray(strip).save(DOCS / "cielo-dia-caras.jpg", quality=90)
        print("  ✓", (DOCS / "cielo-dia-caras.jpg").relative_to(ROOT))


if __name__ == "__main__":
    main()
