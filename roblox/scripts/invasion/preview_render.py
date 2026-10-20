#!/usr/bin/env python3
"""Vistas previas de la Invasión de la Grieta (Blender como módulo de Python, Cycles en CPU).

Dibuja las piezas DE VERDAD (las exporta scripts/invasion/preview-export.luau con el código del juego:
World/Kit/AlienModels y shared/Invasion/Races). Reutiliza el estudio, los materiales y la cámara de
scripts/aircombat/preview_render.py. No es una captura de Roblox: materiales aproximados.

Uso (desde la carpeta roblox/):
    lune run scripts/invasion/preview-export.luau DIR
    python3 scripts/invasion/preview_render.py DIR docs/invasion [--samples 32]

Salida: <Raza>.png (sus 4 tropas, el dron, el caza y la nave de desembarco), reyes.png y criaturas.png.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "aircombat"))

import preview_render as base  # noqa: E402

RACES = ["Vortidos", "Morfagos", "Ferrocefalos", "Luminidos", "Brumaridos"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("out")
    ap.add_argument("--samples", type=int, default=32)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    rb = base.roblox_to_blender
    for race in RACES:
        parts = base.load_parts(os.path.join(args.dir, race + ".json"))
        scene = base.reset_scene(args.samples, 1600, 640)
        base.studio(scene)
        base.build(parts, name=race)
        base.camera(scene, rb(44, 18, -92), rb(44, 7, 0), lens=30)
        base.render(scene, os.path.join(args.out, race + ".png"))
    scene = base.reset_scene(args.samples, 1600, 640)
    base.studio(scene)
    base.build(base.load_parts(os.path.join(args.dir, "reyes.json")), name="reyes")
    base.camera(scene, rb(80, 40, -190), rb(80, 22, 0), lens=30, clip_end=5000)
    base.render(scene, os.path.join(args.out, "reyes.png"))
    scene = base.reset_scene(args.samples, 1600, 640)
    base.studio(scene)
    base.build(base.load_parts(os.path.join(args.dir, "criaturas.json")), name="criaturas")
    base.camera(scene, rb(26, 12, -40), rb(26, 2, 2), lens=34)
    base.render(scene, os.path.join(args.out, "criaturas.png"))


if __name__ == "__main__":
    main()
