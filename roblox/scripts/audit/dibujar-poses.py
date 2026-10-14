"""Dibuja las posturas de los golpes (scripts/audit/out/poses-golpes.json) desde 4 lados.

Uso (desde la carpeta roblox/, después de `lune run scripts/audit/poses-golpes.luau`):
    python3 scripts/audit/dibujar-poses.py

Una hoja PNG por golpe en scripts/audit/out/: filas = anticipación, impacto y retroceso;
columnas = frente, lado (desde su derecha), detrás y arriba. El personaje mira hacia -Z; el
cuadrado rojo claro es donde estaría el rival (4 studs delante).
"""
import json
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.patches import Polygon  # noqa: E402

OUT = os.path.join("scripts", "audit", "out")

COLORS = {
    "Right": "#d9534f",  # brazo/pierna derecha: rojo
    "Left": "#3f7fd9",  # izquierda: azul
    "Head": "#f0c27b",
    "UpperTorso": "#8a8a8a",
    "LowerTorso": "#6f6f6f",
}

# vista: (eje x de la pantalla, eje y de la pantalla, profundidad hacia quien mira)
VIEWS = {
    "Frente": (np.array([-1, 0, 0]), np.array([0, 1, 0]), np.array([0, 0, -1])),
    "Lado (derecha)": (np.array([0, 0, -1]), np.array([0, 1, 0]), np.array([1, 0, 0])),
    "Detrás": (np.array([1, 0, 0]), np.array([0, 1, 0]), np.array([0, 0, 1])),
    "Arriba": (np.array([1, 0, 0]), np.array([0, 0, -1]), np.array([0, 1, 0])),
}

FACES = [(0, 1, 3, 2), (4, 5, 7, 6), (0, 1, 5, 4), (2, 3, 7, 6), (0, 2, 6, 4), (1, 3, 7, 5)]


def color_of(name):
    for key, color in COLORS.items():
        if name.startswith(key) or name == key:
            return color
    return "#999999"


def corners(part):
    p = np.array(part["pos"])
    r = np.array(part["rot"]).reshape(3, 3)
    s = np.array(part["size"]) / 2
    out = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                out.append(p + r @ (s * np.array([sx, sy, sz])))
    return np.array(out)


def draw(ax, parts, view):
    ex, ey, ez = VIEWS[view]
    polys = []
    target = {"name": "Rival", "pos": [0, 3, -4.5], "rot": [1, 0, 0, 0, 1, 0, 0, 0, 1], "size": [2, 5, 1]}
    extra = [target] if view in ("Lado (derecha)", "Arriba") else []
    for part in parts + extra:
        if part["name"] == "HumanoidRootPart":
            continue
        c = corners(part)
        for face in FACES:
            pts = c[list(face)]
            depth = float(np.mean(pts @ ez))
            xy = np.stack([pts @ ex, pts @ ey], axis=1)
            polys.append((depth, xy, part["name"]))
    polys.sort(key=lambda item: item[0])
    for _, xy, name in polys:
        if name == "Rival":
            ax.add_patch(Polygon(xy, closed=True, facecolor="#f4cccc", edgecolor="#e0a0a0", linewidth=0.4, alpha=0.35))
        else:
            ax.add_patch(Polygon(xy, closed=True, facecolor=color_of(name), edgecolor="#222222", linewidth=0.5))
    if view == "Arriba":
        ax.set_xlim(-4, 4)
        ax.set_ylim(-3, 6)
    else:
        ax.set_xlim(-4.5, 4.5)
        ax.set_ylim(-0.5, 6)
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    ax.axhline(0, color="#cccccc", linewidth=0.5) if view != "Arriba" else None


def main():
    with open(os.path.join(OUT, "poses-golpes.json"), encoding="utf-8") as f:
        data = json.load(f)
    for move in data["moves"]:
        frames = move["frames"]
        fig, axes = plt.subplots(len(frames), len(VIEWS), figsize=(10, 2.6 * len(frames)), dpi=60)
        for row, frame in enumerate(frames):
            for col, view in enumerate(VIEWS):
                ax = axes[row][col]
                draw(ax, frame["parts"], view)
                if row == 0:
                    ax.set_title(view, fontsize=9)
                if col == 0:
                    ax.set_ylabel("%s\nt=%.2f" % (frame["label"], frame["t"]), fontsize=9)
        fig.suptitle("%s (%.2f s, impacto t=%.2f)" % (move["name"], move["duration"], move["impact"]), fontsize=11)
        fig.tight_layout()
        path = os.path.join(OUT, "%s.png" % move["name"])
        fig.savefig(path)
        plt.close(fig)
        print(path)


if __name__ == "__main__":
    main()
