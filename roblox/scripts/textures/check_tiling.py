"""Comprueba que todas las texturas de roblox/textures se repiten SIN COSTURA.

Para cada PNG compara el salto entre la última y la primera columna (y fila) —lo que se ve al
repetirse la baldosa— con los saltos entre columnas vecinas del interior. Si la costura salta más que
casi todas las columnas de dentro, se notaría una línea cada vez que se repite: falla.
También comprueba tamaños (potencia de 2, cuadradas), mapas que faltan y el peso total.

Uso (desde roblox/):   python3 scripts/textures/check_tiling.py
Sale con código 1 si algo falla (lo lanza scripts/test-textures.luau).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
TEX = ROOT / "textures"
MAX_TOTAL_MB = 25
REQUIRED = ("color", "normal", "roughness")


def seam_ok(a: np.ndarray, axis: int) -> tuple[bool, float, float]:
    if axis == 0:
        a = np.swapaxes(a, 0, 1)
    diffs = np.abs(np.diff(a, axis=1)).reshape(a.shape[0], a.shape[1] - 1, -1).mean(axis=(0, 2))
    seam = float(np.abs(a[:, -1] - a[:, 0]).mean())
    limit = float(np.quantile(diffs, 0.995)) * 1.1 + 0.5
    return seam <= limit, seam, limit


def main() -> int:
    failures = 0
    folders = sorted(p for p in TEX.iterdir() if p.is_dir()) if TEX.exists() else []
    if not folders:
        print("❌ No hay texturas en textures/. Créalas con: python3 scripts/textures/gen.py")
        return 1
    for folder in folders:
        for need in REQUIRED:
            if not (folder / f"{need}.png").exists():
                print(f"  ❌ {folder.name}: falta {need}.png")
                failures += 1
        for png in sorted(folder.glob("*.png")):
            img = Image.open(png)
            w, h = img.size
            a = np.asarray(img).astype(np.float64)
            problems = []
            if w != h or w & (w - 1) or w > 1024 or w < 64:
                problems.append(f"tamaño {w}x{h} (debe ser cuadrada, potencia de 2, ≤ 1024)")
            for axis, label in ((1, "izquierda-derecha"), (0, "arriba-abajo")):
                ok, seam, limit = seam_ok(a, axis)
                if not ok:
                    problems.append(f"costura {label}: salto {seam:.2f} > {limit:.2f}")
            if png.stem == "normal":
                n = a / 255 * 2 - 1
                if n[..., 2].min() < 0.05:
                    problems.append("normales que miran hacia dentro")
            if problems:
                failures += 1
                print(f"  ❌ {folder.name}/{png.name}: " + "; ".join(problems))
            else:
                print(f"  ✅ {folder.name}/{png.name} ({w}²) sin costura")
    total = sum(p.stat().st_size for p in TEX.rglob("*.png")) / 1024 / 1024
    if total > MAX_TOTAL_MB:
        print(f"  ❌ textures/ pesa {total:.1f} MB (máximo {MAX_TOTAL_MB})")
        failures += 1
    else:
        print(f"  ✅ textures/ pesa {total:.1f} MB (≤ {MAX_TOTAL_MB})")
    print("✅ Todas se repiten sin costura" if failures == 0 else f"❌ {failures} problemas")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
