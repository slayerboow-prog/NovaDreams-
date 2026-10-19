"""Dibuja el mar de Valmar visto desde arriba (profundidad y zonas) con la rejilla de
scripts/map/mar-export.luau.

Uso (desde la carpeta roblox/):
    lune run scripts/map/mar-export.luau 32 /tmp/mar-grid.json
    python3 scripts/map/mar_render.py /tmp/mar-grid.json docs/mar/

Escribe mar-profundidad.png (fondo en metros, con relieve sombreado, sitios y zonas) y
mar-zonas.png (las siete zonas de colores) en la carpeta de salida.
"""
import json
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.colors import LightSource, LinearSegmentedColormap, ListedColormap  # noqa: E402

ZONE_COLORS = {
    "Orilla": "#9fe3e0",
    "Arrecife": "#ff5a6e",
    "Kelp": "#4f9a4a",
    "Llanura": "#e8d39a",
    "Talud": "#8c8f9c",
    "Garganta": "#3a3550",
    "Catedrales": "#1f8fa8",
    "Abismo": "#16326b",
    "Sima": "#6a1b8a",
}


def load(path):
    with open(path) as f:
        g = json.load(f)
    floors = np.array(g["Floors"], dtype=float)
    zones = np.array(g["Zones"], dtype=int)
    land = floors >= 900
    return g, floors, zones, land


def extent(g):
    x0, z0, s = g["MinX"], g["MinZ"], g["Step"]
    return [x0, x0 + (g["NX"] - 1) * s, z0 + (g["NZ"] - 1) * s, z0]


def depth_map(g, floors, land, out):
    meters = (g["Surface"] - floors) / g["StudsPerMeter"]
    meters[land] = np.nan
    cmap = LinearSegmentedColormap.from_list(
        "mar",
        [(0, "#d2fbf4"), (0.15, "#86e0e3"), (0.3, "#35b0d6"), (0.48, "#1d77b5"), (0.62, "#134a8a"), (0.8, "#0b2457"), (1, "#04051a")],
    )
    ls = LightSource(azdeg=315, altdeg=40)
    elev = np.where(land, 0, floors)
    shade = ls.hillshade(elev, vert_exag=6, dx=g["Step"], dy=g["Step"])
    rgb = cmap(np.sqrt(np.clip(np.nan_to_num(meters, nan=0) / 160.0, 0, 1)))[..., :3]
    rgb = rgb * (0.55 + 0.45 * shade[..., None])
    rgb[land] = np.array([0.42, 0.55, 0.33])
    fig, ax = plt.subplots(figsize=(13, 12.5), dpi=110)
    ax.imshow(rgb, extent=extent(g), interpolation="bilinear")
    levels = [3.5, 12, 25, 36, 50, 66, 100, 140]
    cs = ax.contour(
        np.linspace(g["MinX"], g["MinX"] + (g["NX"] - 1) * g["Step"], g["NX"]),
        np.linspace(g["MinZ"], g["MinZ"] + (g["NZ"] - 1) * g["Step"], g["NZ"]),
        np.nan_to_num(meters, nan=0),
        levels=levels,
        colors="white",
        linewidths=0.5,
        alpha=0.55,
    )
    ax.clabel(cs, fmt="%d m", fontsize=7, colors="white")
    for p in g["Pois"]:
        ax.plot(p["X"], p["Z"], marker="o", ms=6, mec="black", mfc="#ffd84a")
        d = (g["Surface"] - p["Y"]) / g["StudsPerMeter"]
        ax.annotate(f"{p['Name']} ({d:.0f} m)", (p["X"], p["Z"]), xytext=(6, 4), textcoords="offset points", fontsize=8, color="white",
                    bbox=dict(boxstyle="round,pad=0.2", fc="black", alpha=0.55, lw=0))
    for k in g["Keep"]:
        ax.add_patch(plt.Circle((k["X"], k["Z"]), k["R"], fill=False, ec="#ffffff", ls="--", lw=0.8, alpha=0.7))
    tr = np.array(g["Trench"])
    ax.plot(tr[:, 0], tr[:, 1], color="#d58cff", lw=1, ls=":")
    ca = np.array(g["Canyon"])
    ax.plot(ca[:, 0], ca[:, 1], color="#c0c0ff", lw=1, ls=":")
    if g.get("Cathedrals"):
        cc = np.array(g["Cathedrals"])
        ax.plot(cc[:, 0], cc[:, 1], color="#8ff3ff", lw=1, ls=":")
    for sp in g.get("Spires") or []:
        ax.plot(sp["X"], sp["Z"], marker="^", ms=4, mec="black", mew=0.4, mfc="#2b3242")
    for f in g.get("JellyFields") or []:
        ax.add_patch(plt.Circle((f["X"], f["Z"]), f["R"], fill=False, ec="#ff7ad9", lw=1.1, alpha=0.9))
    ax.set_title("Mar de Valmar: profundidad (m) · 1 m = 3,57 studs · norte arriba · ▲ agujas · ○ medusas", fontsize=12)
    ax.set_xlabel("X (studs, este →)")
    ax.set_ylabel("Z (studs, sur ↓)")
    sm = plt.cm.ScalarMappable(cmap=cmap, norm=matplotlib.colors.PowerNorm(0.5, 0, 160))
    cb = fig.colorbar(sm, ax=ax, shrink=0.6, pad=0.01)
    cb.set_label("profundidad (m)")
    fig.tight_layout()
    fig.savefig(out)
    plt.close(fig)


def zone_map(g, zones, land, out):
    ids = g["ZoneIds"]
    colors = ["#5b7a45"] + [ZONE_COLORS[i] for i in ids]
    cmap = ListedColormap(colors)
    fig, ax = plt.subplots(figsize=(13, 12.5), dpi=100)
    ax.imshow(zones, extent=extent(g), cmap=cmap, vmin=0, vmax=len(ids), interpolation="nearest")
    for i, zid in enumerate(ids):
        ax.plot([], [], "s", color=ZONE_COLORS[zid], ms=10, label=g["ZoneNames"][i])
    for p in g["Pois"]:
        ax.plot(p["X"], p["Z"], marker="*", ms=10, mec="black", mfc="#ffd84a")
    ax.legend(loc="lower left", fontsize=9, framealpha=0.85)
    ax.set_title("Mar de Valmar: zonas («Vida marina»)", fontsize=12)
    fig.tight_layout()
    fig.savefig(out)
    plt.close(fig)


def main():
    src = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "."
    g, floors, zones, land = load(src)
    depth_map(g, floors, land, os.path.join(outdir, "mar-profundidad.png"))
    zone_map(g, zones, land, os.path.join(outdir, "mar-zonas.png"))
    print("ok")


if __name__ == "__main__":
    main()
