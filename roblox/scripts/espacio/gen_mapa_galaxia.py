"""Fondo del MAPA GALÁCTICO (assets/espacio/mapa_galaxia.jpg), 100 % nuestro, hecho con código.

Uso (desde roblox/):   python3 -I scripts/espacio/gen_mapa_galaxia.py
Necesita:              pip install numpy pillow

Una galaxia en espiral vista algo inclinada (como el dibujo de referencia del dueño,
docs/espacio-aaa/referencia-mapa-galactico.png, pero sin copiar nada): núcleo dorado que brilla, dos
brazos azules y morados con polvo oscuro, nebulosas de colores alrededor y estrellas. 1024x576 (16:9; el
máximo de Roblox son 1024 px por lado). Se sube con scripts/upload-espacio.sh como el resto de
assets/espacio (licencia: CC0, ver assets/espacio/LICENCIAS.md). Mientras no esté subida, el juego pinta
un degradado con estrellas (Controllers/GalaxyMapUI).
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "espacio" / "mapa_galaxia.jpg"
W, H = 1024, 576
RNG = np.random.default_rng(42)


def blurred_noise(scale: int, radius: float) -> np.ndarray:
    """Ruido suave en [0,1] del tamaño de la imagen (ruido pequeño ampliado y difuminado)."""
    small = (RNG.random((H // scale + 2, W // scale + 2)) * 255).astype(np.uint8)
    img = Image.fromarray(small).resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(radius))
    a = np.asarray(img).astype(np.float32) / 255.0
    return (a - a.min()) / max(1e-6, a.max() - a.min())


def fractal() -> np.ndarray:
    total = np.zeros((H, W), np.float32)
    amp = 1.0
    for scale, radius in ((64, 18), (32, 10), (16, 5), (8, 2.5)):
        total += blurred_noise(scale, radius) * amp
        amp *= 0.55
    return total / total.max()


def main() -> None:
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    cx, cy = W / 2, H * 0.52
    # Vista inclinada: el disco se aplasta en vertical y se gira un poco
    tilt = np.radians(-14)
    dx, dy = x - cx, (y - cy)
    rx = dx * np.cos(tilt) - dy * np.sin(tilt)
    ry = (dx * np.sin(tilt) + dy * np.cos(tilt)) / 0.55
    r = np.sqrt(rx**2 + ry**2) / (W * 0.42)
    theta = np.arctan2(ry, rx)

    noise = fractal()
    noise2 = fractal()

    # Fondo: azul noche con un poco de morado
    img = np.zeros((H, W, 3), np.float32)
    img[..., 0] = 0.02 + 0.05 * noise2
    img[..., 1] = 0.03 + 0.03 * noise2
    img[..., 2] = 0.10 + 0.10 * noise2

    # Brazos en espiral logarítmica (dos), con grosor que se abre hacia fuera
    arms = 2
    k = 3.2
    phase = (theta - k * np.log(r + 0.05)) * arms / 2
    arm = np.cos(phase) ** 2
    arm = arm ** (1.8 + 2.0 * (1 - np.clip(r, 0, 1)))
    disk = np.exp(-(r / 0.75) ** 2)
    arms_light = arm * disk * (0.25 + 1.1 * noise) + 0.18 * disk * noise2
    dust = np.clip((noise - 0.55) * 3, 0, 1) * arm * disk  # polvo oscuro en los brazos
    blue = np.array([0.45, 0.62, 1.0])
    purple = np.array([0.72, 0.42, 1.0])
    mix = np.clip(r * 1.4, 0, 1)[..., None]
    arm_color = blue * (1 - mix) + purple * mix
    img += arms_light[..., None] * arm_color * 0.9
    img *= (1 - 0.5 * dust)[..., None]

    # Núcleo dorado que brilla
    core = np.exp(-(r / 0.09) ** 2)
    halo = np.exp(-(r / 0.28) ** 2)
    img += core[..., None] * np.array([1.0, 0.92, 0.75]) * 1.6
    img += halo[..., None] * np.array([1.0, 0.62, 0.32]) * 0.55

    # Nebulosas de colores lejos del centro
    for (nx, ny, col, size) in ((0.12, 0.25, (0.6, 0.25, 0.9), 0.22), (0.85, 0.2, (0.25, 0.4, 1.0), 0.2),
                                (0.82, 0.82, (0.9, 0.3, 0.6), 0.2), (0.15, 0.8, (0.3, 0.6, 0.95), 0.18)):
        d = np.sqrt(((x / W - nx) / size) ** 2 + ((y / H - ny) / (size * 1.4)) ** 2)
        neb = np.exp(-d**2) * np.clip(noise2 * 1.4 - 0.25, 0, 1)
        img += neb[..., None] * np.array(col) * 0.45

    # Estrellas: muchas pequeñas, algunas grandes con brillo, más en el disco
    stars = np.zeros((H, W), np.float32)
    n = 2600
    sx = RNG.integers(0, W, n)
    sy = RNG.integers(0, H, n)
    stars[sy, sx] = RNG.random(n) ** 3 * 1.5
    extra = 1800
    t = RNG.random(extra) * np.pi * 2
    rr = np.abs(RNG.normal(0, 0.35, extra))
    ex = (cx + np.cos(t) * rr * W * 0.42).astype(int)
    ey = (cy + np.sin(t) * rr * W * 0.42 * 0.55).astype(int)
    ok = (ex >= 0) & (ex < W) & (ey >= 0) & (ey < H)
    stars[ey[ok], ex[ok]] += RNG.random(ok.sum()) * 0.9
    glow = np.asarray(Image.fromarray(np.clip(stars * 255, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 255
    img += (stars * 0.9 + glow * 1.6)[..., None] * np.array([0.92, 0.95, 1.0])

    # Viñeta suave (los paneles van en los bordes)
    v = np.sqrt(((x - cx) / (W * 0.62)) ** 2 + ((y - cy) / (H * 0.7)) ** 2)
    img *= np.clip(1.15 - 0.45 * v, 0.45, 1)[..., None]

    out = np.clip(img, 0, 1) ** (1 / 1.1)
    Image.fromarray((out * 255).astype(np.uint8)).save(OUT, quality=88, optimize=True)
    print(f"✅ {OUT.relative_to(ROOT)} ({W}x{H})")


if __name__ == "__main__":
    main()
