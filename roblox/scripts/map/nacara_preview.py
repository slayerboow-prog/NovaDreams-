"""Vista previa APROXIMADA de la plaza de prueba de Nácara (no es una captura del juego).

Uso (desde la carpeta roblox/):
    lune run scripts/map/nacara-export.luau /tmp/nacara.json
    python3 scripts/map/nacara_preview.py /tmp/nacara.json docs/mar/nacara-prueba-vista-previa.png

Un trazador de rayos pequeño con numpy: bloques, bolas, elipsoides (bloque con malla de esfera) y
cilindros (eje X, como en Roblox), con las piezas de verdad de World/NacaraBuilder y de la gente de
Services/NacaraService. La luz y la bruma bajo el agua son las de shared/Sea/OceanBiomes.look +
Nacara.lookNear, pero el agua, la niebla propia del terreno y el Bloom de Roblox NO se pueden imitar:
por eso el dueño hace las capturas de verdad en su móvil (docs/mar/civilizacion-marina.md, Fase 0).
"""
import json
import math
import sys

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

W, H = 640, 360
FOV = math.radians(70)


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def camera_rays(at, look):
    at = np.array(at, float)
    fwd = np.array(look, float) - at
    fwd /= np.linalg.norm(fwd)
    right = np.cross(fwd, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    tan = math.tan(FOV / 2)
    xs = (np.arange(W) + 0.5) / W * 2 - 1
    ys = 1 - (np.arange(H) + 0.5) / H * 2
    gx, gy = np.meshgrid(xs * tan * W / H, ys * tan)
    d = fwd[None, None, :] + gx[..., None] * right + gy[..., None] * up
    d /= np.linalg.norm(d, axis=-1, keepdims=True)
    return at, d.reshape(-1, 3)


def intersect(prim, o, d):
    """t (N,) y normal (N,3) en el mundo; t = inf si no toca."""
    R = np.array(prim["Rot"], float).reshape(3, 3)
    p = np.array(prim["Pos"], float)
    half = np.array(prim["Size"], float) / 2
    lo = (o - p) @ R  # (3,)  R^T (o - p)
    ld = d @ R  # (N,3)
    n = ld.shape[0]
    t = np.full(n, np.inf)
    nl = np.zeros((n, 3))
    shape = prim["Shape"]
    if shape in ("Ball", "Ellipsoid"):
        if shape == "Ball":
            r = min(half)
            half = np.array([r, r, r])
        so = lo / half
        sd = ld / half
        a = np.einsum("ij,ij->i", sd, sd)
        b = 2 * sd @ so
        c = so @ so - 1
        disc = b * b - 4 * a * c
        ok = disc > 0
        sq = np.sqrt(np.where(ok, disc, 0))
        t0 = (-b - sq) / (2 * a)
        t1 = (-b + sq) / (2 * a)
        tt = np.where(t0 > 1e-3, t0, t1)
        ok &= tt > 1e-3
        t = np.where(ok, tt, np.inf)
        hit = lo + ld * np.where(ok, tt, 0)[:, None]
        nl = hit / (half * half)
    elif shape == "Cylinder":
        r = min(half[1], half[2])
        oy, oz = lo[1], lo[2]
        dy, dz = ld[:, 1], ld[:, 2]
        a = dy * dy + dz * dz
        b = 2 * (oy * dy + oz * dz)
        c = oy * oy + oz * oz - r * r
        disc = b * b - 4 * a * c
        ok = (disc > 0) & (a > 1e-12)
        sq = np.sqrt(np.where(ok, disc, 0))
        aa = np.where(a > 1e-12, a, 1)
        t0 = (-b - sq) / (2 * aa)
        x0 = lo[0] + ld[:, 0] * t0
        side = ok & (t0 > 1e-3) & (np.abs(x0) <= half[0])
        t = np.where(side, t0, np.inf)
        hit = lo + ld * np.where(side, t0, 0)[:, None]
        nl = np.stack([np.zeros(n), hit[:, 1], hit[:, 2]], axis=1)
        # tapas
        for s in (-1, 1):
            dx = np.where(np.abs(ld[:, 0]) > 1e-9, ld[:, 0], 1e-9)
            tc = (s * half[0] - lo[0]) / dx
            hc = lo + ld * tc[:, None]
            capok = (tc > 1e-3) & (hc[:, 1] ** 2 + hc[:, 2] ** 2 <= r * r) & (tc < t)
            t = np.where(capok, tc, t)
            nl = np.where(capok[:, None], np.array([s, 0, 0], float), nl)
    else:  # Block y Wedge (como bloque)
        dd = np.where(np.abs(ld) > 1e-9, ld, 1e-9)
        t1 = (-half - lo) / dd
        t2 = (half - lo) / dd
        tmin = np.minimum(t1, t2)
        tmax = np.maximum(t1, t2)
        tn = tmin.max(axis=1)
        tf = tmax.min(axis=1)
        ok = (tn <= tf) & (tf > 1e-3)
        tt = np.where(tn > 1e-3, tn, tf)
        t = np.where(ok, tt, np.inf)
        axis = tmin.argmax(axis=1)
        sign = -np.sign(dd[np.arange(n), axis])
        nl[np.arange(n), axis] = sign
    nw = nl @ R.T
    norm = np.linalg.norm(nw, axis=1, keepdims=True)
    nw = nw / np.where(norm > 0, norm, 1)
    return t, nw


def render(data, spot, mood):
    at, d = camera_rays(spot["At"], spot["Look"])
    o = np.array(at, float)
    n = d.shape[0]
    look = data[mood]
    fog = np.array(look["Fog"])
    ambient = np.array(look["Ambient"])
    tint = np.array(look["Tint"])
    vis = max(60.0, float(look["Visibility"]))
    exposure = 2 ** float(look["Exposure"])
    zbuf = np.full(n, np.inf)
    col = np.zeros((n, 3))
    glow = np.zeros((n, 3))
    # el fondo del mar (plano, grano blanco azulado)
    floor_y = data["FloorY"] - 0.2
    tf = np.where(d[:, 1] < -1e-6, (floor_y - o[1]) / np.where(d[:, 1] < -1e-6, d[:, 1], -1), np.inf)
    tf = np.where(tf > 0, tf, np.inf)
    zbuf = tf
    hitp = o + d * np.where(np.isfinite(tf), tf, 0)[:, None]
    grain = 0.9 + 0.1 * np.sin(hitp[:, 0] * 0.7) * np.cos(hitp[:, 2] * 0.6)
    col[:] = (np.array([0.80, 0.84, 0.88]) * grain[:, None]) * (ambient * 0.9 + 0.12)
    lights = data["Lights"]
    sun = np.array([0.3, 1.0, 0.2])
    sun /= np.linalg.norm(sun)
    sun_k = 0.25 if mood == "Day" else 0.05
    transparent = []
    for prim in data["Parts"]:
        tr = prim["Transparency"]
        if tr >= 0.05:
            transparent.append(prim)
            continue
        t, nw = intersect(prim, o, d)
        closer = t < zbuf
        if not closer.any():
            continue
        zbuf = np.where(closer, t, zbuf)
        c = np.array(prim["Color"])
        if prim["Material"] == "Neon":
            shade = np.tile(c * 1.25, (n, 1))
            glow = np.where(closer[:, None], c[None, :] * 0.9, glow)
        else:
            lam = np.clip(nw @ sun, 0, 1)
            shade = c[None, :] * (ambient[None, :] * 0.85 + 0.18 + sun_k * lam[:, None])
            p = o + d * np.where(closer, t, 0)[:, None]
            for lt in lights:
                lp = np.array(lt["Pos"])
                v = lp - p
                dist = np.linalg.norm(v, axis=1)
                k = np.clip(1 - dist / lt["Range"], 0, 1) * lt["Brightness"]
                lam2 = np.clip(np.einsum("ij,ij->i", nw, v / np.maximum(dist, 1e-3)[:, None]), 0, 1)
                shade += c[None, :] * np.array(lt["Color"])[None, :] * (k * lam2)[:, None] * 0.9
            if prim["Material"] == "SmoothPlastic":
                shade += 0.05 * np.clip(nw[:, 1:2], 0, 1)
            glow = np.where(closer[:, None], 0, glow)
        col = np.where(closer[:, None], shade, col)
    # lo transparente encima (membrana de la cúpula, columna de luz, anillos)
    for prim in transparent:
        t, nw = intersect(prim, o, d)
        front = t < zbuf
        if not front.any():
            continue
        c = np.array(prim["Color"])
        a = (1 - prim["Transparency"])
        if prim["Material"] == "Neon":
            col = np.where(front[:, None], col + c[None, :] * a * 0.9, col)
            glow = np.where(front[:, None], glow + c[None, :] * a * 0.6, glow)
        else:
            rim = 1 - np.abs(np.einsum("ij,ij->i", nw, d))
            alpha = (a * 0.5 + 0.45 * rim ** 2)[:, None]
            col = np.where(front[:, None], col * (1 - alpha) + c[None, :] * alpha, col)
    # bruma del agua y el color de lo hondo
    dist = np.where(np.isfinite(zbuf), zbuf, 1e4)
    f = np.exp(-dist / vis)[:, None]
    col = col * tint[None, :] * exposure
    col = col * f + fog[None, :] * (1 - f) * 1.1
    img = col.reshape(H, W, 3)
    g = (glow * f).reshape(H, W, 3)
    # «bloom»: lo Neon se derrama un poco
    k = 9
    for axis in (0, 1):
        cs = np.cumsum(np.pad(g, [(k, k) if a == axis else (0, 0) for a in range(3)], mode="edge"), axis=axis)
        if axis == 0:
            g = (cs[2 * k:, :, :] - cs[:-2 * k, :, :]) / (2 * k)
        else:
            g = (cs[:, 2 * k:, :] - cs[:, :-2 * k, :]) / (2 * k)
    img = img + g[: H, : W] * (0.5 + 0.6 * float(look["Glow"]))
    return np.clip(img, 0, 1)


def main():
    data = load(sys.argv[1])
    out = sys.argv[2]
    spots = {s["Id"]: s for s in data["Spots"]}
    panels = [
        ("Fuera40", "Night", "Fuera de la plaza, a 40 m · noche"),
        ("Gente", "Day", "Mirando a la gente · día"),
        ("Torres", "Night", "Mirando arriba, a las torres · noche"),
        ("Cupula", "Day", "Hacia la Lonja Honda (cúpula de aire) · día"),
    ]
    fig, axes = plt.subplots(2, 2, figsize=(12.8, 7.6), dpi=100)
    fig.patch.set_facecolor("#0a1424")
    for ax, (sid, mood, title) in zip(axes.flat, panels):
        img = render(data, spots[sid], mood)
        ax.imshow(img)
        ax.set_axis_off()
        ax.set_title(title, color="white", fontsize=11)
        ax.text(8, H - 10, "VISTA PREVIA aproximada · no es una captura del juego", color="#ffd27a", fontsize=8, va="bottom")
    fig.suptitle("Nácara · plaza de prueba (fase 0) — VISTA PREVIA, NO ES ROBLOX", color="#ffd27a", fontsize=14, fontweight="bold")
    plt.tight_layout(rect=(0, 0, 1, 0.95))
    plt.savefig(out, facecolor=fig.get_facecolor())
    print("vista previa ->", out)


if __name__ == "__main__":
    main()
