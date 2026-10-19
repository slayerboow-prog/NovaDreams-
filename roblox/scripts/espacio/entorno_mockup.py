"""Maquetas del ENTORNO POR ZONA (docs/espacio-aaa/entorno.md): antes y después, con los cielos de
verdad del juego (assets/espacio/cielo_*.jpg) vistos con una cámara en perspectiva.

Uso (desde roblox/):   python3 -I scripts/espacio/entorno_mockup.py
Necesita:              pip install numpy pillow

Sale (docs/espacio-aaa/):
  entorno-espacio.jpg         el espacio después: negro, estrellas, nebulosa, los planetas y el sol
  entorno-tefra.jpg           Tefra después: su cielo malva con la luna Ovilla, bruma de ceniza
  entorno-antes-despues.jpg   hoja: antes (fotograma del vídeo del dueño en Tefra y reconstrucción del
                              espacio «azul» de v117) y después

Son maquetas (no capturas del juego): lo que enseñan es QUÉ cielo y qué luz pone cada zona.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SKIES = ROOT / "assets" / "espacio"
OUT = ROOT / "docs" / "espacio-aaa"
FRAMES = ROOT / "docs" / "bugs" / "video-tefra"
W, H = 960, 540

FACES = {
    "ft": ((0, 0, -1), (1, 0, 0), (0, 1, 0)),
    "bk": ((0, 0, 1), (-1, 0, 0), (0, 1, 0)),
    "lf": ((-1, 0, 0), (0, 0, -1), (0, 1, 0)),
    "rt": ((1, 0, 0), (0, 0, 1), (0, 1, 0)),
    "up": ((0, 1, 0), (1, 0, 0), (0, 0, 1)),
    "dn": ((0, -1, 0), (1, 0, 0), (0, 0, -1)),
}


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype(f"/usr/share/fonts/truetype/dejavu/{name}", size)
    except OSError:
        return ImageFont.load_default()


def camera_dirs(yaw_deg, pitch_deg, fov_deg=70, w=W, h=H):
    yaw, pitch = math.radians(yaw_deg), math.radians(pitch_deg)
    fwd = np.array([math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)], np.float32)
    right = np.cross(fwd, [0, 1, 0]).astype(np.float32)
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    t = math.tan(math.radians(fov_deg) / 2)
    xs = (np.arange(w, dtype=np.float32) + 0.5) / w * 2 - 1
    ys = (np.arange(h, dtype=np.float32) + 0.5) / h * 2 - 1
    x, y = np.meshgrid(xs * t * w / h, -ys * t)
    d = fwd[None, None] + x[..., None] * right[None, None] + y[..., None] * up[None, None]
    d /= np.linalg.norm(d, axis=-1, keepdims=True)
    return d, fwd, right, up, t


def sample_sky(prefix, d):
    faces = {n: np.asarray(Image.open(SKIES / f"{prefix}_{n}.jpg").convert("RGB"), np.float32) / 255 for n in FACES}
    out = np.zeros(d.shape, np.float32)
    best = np.full(d.shape[:2], -1.0, np.float32)
    pick = np.empty(d.shape[:2], dtype=object)
    for n, (c, _, _) in FACES.items():
        dot = d @ np.array(c, np.float32)
        m = dot > best
        best[m] = dot[m]
        pick[m] = n
    for n, (c, r, u) in FACES.items():
        m = pick == n
        if not m.any():
            continue
        dd = d[m]
        cd = dd @ np.array(c, np.float32)
        s = (dd @ np.array(r, np.float32)) / cd
        t = (dd @ np.array(u, np.float32)) / cd
        img = faces[n]
        size = img.shape[0]
        px = np.clip(((s + 1) / 2 * size).astype(int), 0, size - 1)
        py = np.clip(((1 - t) / 2 * size).astype(int), 0, size - 1)
        out[m] = img[py, px]
    return out


def project(world_dir, fwd, right, up, t):
    v = np.array(world_dir, np.float32)
    v /= np.linalg.norm(v)
    z = v @ fwd
    if z <= 0.05:
        return None
    x = (v @ right) / z / (t * W / H)
    y = (v @ up) / z / t
    return ((x + 1) / 2 * W, (1 - y) / 2 * H)


def sphere(img, center, radius, albedo, light=(-0.6, 0.45, 0.66), halo=(1, 0.8, 0.9), spin=0.7):
    cx, cy = center
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    x = (xx - cx) / radius
    y = -(yy - cy) / radius
    r2 = x * x + y * y
    inside = r2 < 1
    z = np.sqrt(np.clip(1 - r2, 0, 1))
    lon = np.arctan2(x, z) + spin
    lat = np.arcsin(np.clip(y, -1, 1))
    Ha, Wa = albedo.shape[:2]
    u = ((lon + np.pi) / (2 * np.pi) % 1 * Wa).astype(int) % Wa
    v = np.clip(((np.pi / 2 - lat) / np.pi * Ha).astype(int), 0, Ha - 1)
    L = np.array(light, np.float32)
    L /= np.linalg.norm(L)
    ndl = np.clip(x * L[0] + y * L[1] + z * L[2], 0, 1)
    lit = albedo[v, u] * (0.03 + 0.97 * ndl)[..., None]
    img[inside] = lit[inside]
    rr = np.sqrt(r2)
    rim = np.exp(-np.clip(rr - 1, 0, None) / 0.05) * (rr > 0.94) * np.clip((x * L[0] + y * L[1]) * 0.8 + 0.45, 0, 1)
    img += rim[..., None] * np.array(halo, np.float32) * 0.7
    return img


def glow(img, center, radius, color, strength):
    cx, cy = center
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / radius
    img += (np.exp(-d * d) * strength)[..., None] * np.array(color, np.float32)
    return img


def label(im, title, sub, good):
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, 64], fill=(8, 10, 18))
    d.text((18, 8), title, font=font(26, True), fill=(120, 230, 150) if good else (255, 120, 110))
    d.text((18, 40), sub, font=font(15), fill=(210, 214, 230))
    return im


def to_img(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def space_after():
    d, fwd, right, up, t = camera_dirs(25, 6)
    img = sample_sky("cielo_espacio", d)
    # Tefra cerca (esfera con su textura), dos planetas lejos como estrellas y el sol
    tefra = np.asarray(Image.open(SKIES / "planeta_lontana.jpg").convert("RGB"), np.float32) / 255
    p = project((0.55, 0.08, -0.83), fwd, right, up, t)
    if p:
        img = sphere(img, p, 150, tefra, halo=(1, 0.72, 0.88))
    for dirv, colr in (((0.1, 0.28, -1), (1, 0.6, 0.35)), ((-0.35, 0.12, -1), (0.45, 0.95, 0.95))):
        q = project(dirv, fwd, right, up, t)
        if q:
            img = glow(img, q, 5, colr, 1.4)
            img = glow(img, q, 16, colr, 0.25)
    s = project((-0.75, 0.32, -0.6), fwd, right, up, t)
    if s:
        img = glow(img, s, 10, (1, 1, 0.96), 3.0)
        img = glow(img, s, 70, (1, 0.95, 0.85), 0.45)
        img = glow(img, s, 220, (0.9, 0.85, 0.8), 0.08)
    return label(to_img(img), "DESPUÉS · espacio", "Negro, nebulosa y estrellas (Sky «EspacioProfundo»), sin bruma ni nubes, planetas nítidos, el sol con su brillo", True)


def space_before():
    # Reconstrucción del fallo de v117: el cielo azul de Valmar con nubes, bruma y la Grieta encima
    yy = np.linspace(0, 1, H, dtype=np.float32)[:, None, None]
    sky = (1 - yy) * np.array([0.28, 0.55, 0.85], np.float32) + yy * np.array([0.7, 0.82, 0.92], np.float32)
    img = np.repeat(np.repeat(sky, W, 1), 1, 2)
    rng = np.random.default_rng(3)
    noise = Image.fromarray((rng.random((H // 8, W // 8)) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(14))
    n = np.asarray(noise, np.float32)[..., None] / 255
    clouds = np.clip((n - 0.5) * 3.2, 0, 1) * np.clip(1.3 - yy * 1.2, 0, 1)
    img = img * (1 - clouds * 0.8) + clouds * 0.8 * np.array([0.96, 0.97, 1.0], np.float32)
    img = glow(img, (640, 110), 90, (0.45, 0.35, 1.0), 0.55)
    img = glow(img, (640, 110), 26, (0.85, 0.8, 1.0), 0.9)
    img = glow(img, (230, 300), 6, (1, 0.7, 0.8), 0.25)
    haze = np.clip(yy * 1.4 - 0.25, 0, 1) * 0.45
    img = img * (1 - haze) + haze * np.array([0.78, 0.86, 0.95], np.float32)
    return label(to_img(img), "ANTES · espacio (reconstrucción)", "Cielo azul de Valmar con nubes, bruma y la Grieta: «parece que estamos dentro de un planeta»", False)


def tefra_after():
    d, *_ = camera_dirs(30, 4)
    img = sample_sky("cielo_lontana", d)
    rng = np.random.default_rng(11)
    for _ in range(120):
        x, y = rng.integers(0, W), rng.integers(70, H)
        img = glow(img, (x, y), rng.uniform(1.2, 2.6), (0.85, 0.8, 0.85), 0.35)
    return label(to_img(img), "DESPUÉS · Tefra", "Su cielo malva con la luna Ovilla (Sky «CieloTefra»), bruma de ceniza y luz volcánica; sin la Grieta ni el HUD de Valmar", True)


def tefra_before():
    f = Image.open(FRAMES / "f00.jpg").convert("RGB").resize((W, H), Image.LANCZOS)
    return label(f, "ANTES · Tefra (vídeo del dueño, v117)", "El cielo azul de Valmar con su Grieta y sus nubes; avisos amontonados; HUD de Valmar", False)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sa, ta = space_after(), tefra_after()
    sa.save(OUT / "entorno-espacio.jpg", quality=88)
    ta.save(OUT / "entorno-tefra.jpg", quality=88)
    sheet = Image.new("RGB", (W * 2 + 30, H * 2 + 30), (14, 16, 26))
    for i, im in enumerate((space_before(), sa, tefra_before(), ta)):
        sheet.paste(im, (10 + (i % 2) * (W + 10), 10 + (i // 2) * (H + 10)))
    sheet.save(OUT / "entorno-antes-despues.jpg", quality=86)
    print("  ✓ docs/espacio-aaa/entorno-espacio.jpg, entorno-tefra.jpg, entorno-antes-despues.jpg")


if __name__ == "__main__":
    main()
