"""Hoja de muestras del fondo de la orilla (shared/Sea/ShoreDecor), a partir de lo que exporta
scripts/map/orilla-export.luau.

VISTA PREVIA APROXIMADA: formas y colores de las recetas con una luz turquesa de día y azul de noche
hecha a mano. No es el render de Roblox (ni su agua, ni su niebla, ni sus materiales).

Uso (desde roblox/):
    lune run scripts/map/orilla-export.luau /tmp/orilla.json
    python3 scripts/map/orilla_preview.py /tmp/orilla.json docs/mar/orilla-recetas.png
"""
import json
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

NAMES = {
    "CoralHead": "Coral cerebro",
    "Branch": "Coral de ramas",
    "Table": "Coral mesa",
    "Fan": "Abanico de mar",
    "Anemone": "Anémona",
    "Seagrass": "Pradera",
    "Rock": "Roca (sin malla)",
    "Shell": "Conchas",
    "Starfish": "Estrella de mar",
    "Crab": "Cangrejo",
    "Urchin": "Erizo",
}


def surface(kind, size, n=14):
    """Puntos (u, v) de la forma en sus ejes locales, de -0,5 a 0,5 del tamaño."""
    sx, sy, sz = size
    if kind in ("Ball", "Ellipsoid"):
        if kind == "Ball":
            d = min(sx, sy, sz)
            sx = sy = sz = d
        u = np.linspace(0, 2 * np.pi, n)
        v = np.linspace(0, np.pi, n)
        x = 0.5 * sx * np.outer(np.cos(u), np.sin(v))
        y = 0.5 * sy * np.outer(np.ones_like(u), np.cos(v))
        z = 0.5 * sz * np.outer(np.sin(u), np.sin(v))
        return x, y, z
    if kind in ("Cylinder", "MeshCylinder"):
        u = np.linspace(0, 2 * np.pi, n)
        t = np.linspace(-0.5, 0.5, 2)
        if kind == "Cylinder":  # a lo largo de X (Part.Shape = Cylinder)
            r = 0.5 * min(sy, sz)
            x = np.outer(np.ones_like(u), t * sx)
            y = np.outer(np.cos(u) * r, np.ones_like(t))
            z = np.outer(np.sin(u) * r, np.ones_like(t))
        else:  # a lo largo de Y (SpecialMesh Cylinder)
            x = np.outer(np.cos(u) * 0.5 * sx, np.ones_like(t))
            y = np.outer(np.ones_like(u), t * sy)
            z = np.outer(np.sin(u) * 0.5 * sz, np.ones_like(t))
        return x, y, z
    # bloque (las hojas de la pradera)
    u = np.array([-0.5, 0.5, 0.5, -0.5, -0.5])
    x = np.outer(u * sx, np.ones(2))
    y = np.outer(np.ones(5), np.array([-0.5, 0.5]) * sy)
    z = np.outer(np.array([-0.5, -0.5, 0.5, 0.5, -0.5]) * sz, np.ones(2))
    return x, y, z


def draw(ax, pieces, light, tint):
    for p in pieces:
        x, y, z = surface(p["Kind"], p["Size"])
        R = np.array(p["Axes"]).T  # columnas: ejes X, Y, Z del mundo
        pts = np.stack([x, y, z], axis=-1) @ R.T + np.array(p["Pos"])
        col = np.array(p["Color"]) * np.array(tint)
        shade = np.clip(light, 0, 1)
        ax.plot_surface(pts[..., 0], pts[..., 2], pts[..., 1], color=np.clip(col * shade, 0, 1), linewidth=0, antialiased=True, shade=True)


def main():
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    out = sys.argv[2]
    order = data["Order"]
    looks = data["Look"]
    day = looks["Orilla"]["Day"]
    night = looks["Orilla"]["Night"]
    cols = 4
    rows = (len(order) + cols - 1) // cols + 1
    fig = plt.figure(figsize=(cols * 4.2, rows * 3.9), dpi=110)
    fig.patch.set_facecolor((0.06, 0.2, 0.26))
    for i, kind in enumerate(order):
        for mode, (tint, light, bg) in enumerate([
            (day["Tint"], 1.0, day["Fog"]),
        ]):
            ax = fig.add_subplot(rows, cols, i + 1, projection="3d")
            ax.set_facecolor(tuple(np.clip(np.array(bg) * 0.75 + 0.2 * np.array([0.92, 0.91, 0.84]), 0, 1)))
            # (sin suelo dibujado: mplot3d no ordena bien las superficies y lo tapaba todo)
            allpts = []
            span = 0
            for pieces in data["Kinds"][kind]:
                for p in pieces:
                    span = max(span, abs(p["Pos"][0]) + max(p["Size"]), abs(p["Pos"][2]) + max(p["Size"]))
            step = max(2.0, span * 2.1)
            top = 0.5
            for v, pieces in enumerate(data["Kinds"][kind]):
                moved = []
                for p in pieces:
                    q = dict(p)
                    q["Pos"] = [p["Pos"][0] + (v - 1) * step, p["Pos"][1], p["Pos"][2]]
                    moved.append(q)
                    top = max(top, p["Pos"][1] + max(p["Size"]) * 0.6)
                draw(ax, moved, light, tint)
            half = step * 1.6
            ax.set_xlim(-half, half)
            ax.set_ylim(-half * 0.6, half * 0.6)
            ax.set_zlim(-0.1, max(top, half * 0.5))
            ax.set_box_aspect((2 * half, 1.2 * half, max(top, half * 0.5)))
            flat = top < 1.5
            ax.view_init(elev=48 if flat else 20, azim=-62)
            ax.set_axis_off()
            ax.set_title(NAMES.get(kind, kind), color="white", fontsize=12)
    # la luz bajo el agua en la orilla: día y noche
    ax = fig.add_subplot(rows, 1, rows)
    ax.set_axis_off()
    labels = [("Agua (día)", day["Water"]), ("Bruma (día)", day["Fog"]), ("Etalonaje (día)", day["Tint"]), ("Ambiente (día)", day["Ambient"]),
              ("Agua (noche)", night["Water"]), ("Bruma (noche)", night["Fog"]), ("Etalonaje (noche)", night["Tint"]), ("Ambiente (noche)", night["Ambient"])]
    for k, (name, c) in enumerate(labels):
        ax.add_patch(plt.Rectangle((k * 1.1, 0.25), 1.0, 0.55, color=tuple(c)))
        ax.text(k * 1.1 + 0.5, 0.08, name, color="white", ha="center", fontsize=10)
    ax.set_xlim(-0.1, len(labels) * 1.1)
    ax.set_ylim(0, 1)
    fig.suptitle("Fondo de la orilla v122 (shared/Sea/ShoreDecor) — VISTA PREVIA aproximada, no es el render de Roblox", color="white", fontsize=14)
    fig.savefig(out, facecolor=fig.get_facecolor(), bbox_inches="tight")
    print("Escrito", out)


if __name__ == "__main__":
    main()
