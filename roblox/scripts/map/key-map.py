#!/usr/bin/env python3
"""Mapa de claves de edificios de una versión del mapa a la siguiente (para las partidas guardadas).

Las partidas guardan los edificios por su clave (InteriorService: "<Tipo>_<X>_<Z>"): viviendas
compradas, alquiladas o iniciales (data.Properties, data.Housing.Home) y negocios (BusinessService:
"L:<clave>", "H:x_z", "G:x_z"). Si una versión del mapa quita o mueve edificios, sus claves dejan de
existir. Este script compara las claves de dos mapas construidos y escribe, para cada clave que ya no
está, los edificios equivalentes de la versión nueva (mismo tipo, mismo distrito si se puede, el más
cercano primero). El juego (server/Migrations/BuildingKeyMigration) prueba esos candidatos en orden y, si no
hay sitio libre en ninguno, devuelve el dinero.

Uso (desde la carpeta roblox/):
  lune run scripts/map/building-keys.luau ANTES.rbxl antes.json      (el mapa publicado)
  lune run scripts/map/building-keys.luau DESPUES.rbxl despues.json  (el mapa nuevo)
  python3 scripts/map/key-map.py antes.json despues.json [--version 1] [--keep-old claves-viejas.json]

Escribe:
  src/server/Migrations/BuildingKeyMap.luau las claves quitadas y sus candidatos
  scripts/map/data/claves-<version>.json    todas las claves del mapa de antes (para la prueba
                                            scripts/test-buildingkeys.luau)
"""
import argparse
import json
import math
import os

CANDIDATES = 6
# Qué tipos de edificio valen como sustituto de cada uno (en orden de preferencia)
COMPATIBLE = {
    "Casa": ["Casa", "Villa"],
    "Villa": ["Villa", "Casa"],
    "Portal": ["Portal", "Local"],  # pisos: cualquier edificio con pisos arriba
    "Local": ["Local", "Portal"],
}


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def candidates(old, pool, kinds):
    out = []
    for rank, kind in enumerate(kinds):
        same = [b for b in pool if b["Kind"] == kind]
        same.sort(key=lambda b: (0 if b.get("District") == old.get("District") else 1, math.hypot(b["X"] - old["X"], b["Z"] - old["Z"])))
        for b in same:
            if b["Key"] not in out:
                out.append(b["Key"])
            if len(out) >= CANDIDATES * (rank + 1):
                break
    return out[:CANDIDATES]


def lua_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("before")
    ap.add_argument("after")
    ap.add_argument("--version", type=int, default=1)
    ap.add_argument("--out", default="src/server/Migrations/BuildingKeyMap.luau")
    ap.add_argument("--keys", default="scripts/map/data")
    args = ap.parse_args()
    before, after = load(args.before), load(args.after)
    new_b = {b["Key"]: b for b in after["Buildings"]}
    new_p = {p["Key"]: p for p in after["Premises"]}
    buildings, removed = {}, {}
    for old in before["Buildings"]:
        if old["Key"] in new_b:
            continue
        kinds = COMPATIBLE.get(old["Kind"], [old["Kind"]])
        buildings[old["Key"]] = candidates(old, after["Buildings"], kinds)
        removed[old["Key"]] = old
    premises = {}
    for old in before["Premises"]:
        if old["Key"] in new_p:
            continue
        premises[old["Key"]] = candidates(old, after["Premises"], [old["Kind"]])

    lines = [
        "-- BuildingKeyMap: GENERADO por scripts/map/key-map.py (no se edita a mano).",
        "-- Claves de edificios y negocios del mapa de antes que ya no existen, con sus sustitutos en orden",
        "-- (mismo tipo, mismo distrito si se puede, el más cercano primero). Lista vacía = sin sustituto",
        "-- (se devuelve el dinero). Removed: dónde estaba cada edificio quitado (X, Z, ancho W, fondo D).",
        "-- Lo usa Migrations/BuildingKeyMigration al cargar las partidas.",
        "",
        "return {",
        f"\tVersion = {args.version},",
        "\tBuildings = {",
    ]
    for key in sorted(buildings):
        lines.append(f"\t\t[{lua_string(key)}] = {{ " + ", ".join(lua_string(k) for k in buildings[key]) + " },")
    lines.append("\t},")
    lines.append("\tPremises = {")
    for key in sorted(premises):
        lines.append(f"\t\t[{lua_string(key)}] = {{ " + ", ".join(lua_string(k) for k in premises[key]) + " },")
    lines.append("\t},")
    lines.append("\tRemoved = {")
    for key in sorted(removed):
        b = removed[key]
        lines.append(f"\t\t[{lua_string(key)}] = {{ X = {b['X']}, Z = {b['Z']}, W = {b.get('W', 0)}, D = {b.get('D', 0)} }},")
    lines.append("\t},")
    lines.append("}")
    with open(args.out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    os.makedirs(args.keys, exist_ok=True)
    keys_path = os.path.join(args.keys, f"claves-v{args.version}.json")
    with open(keys_path, "w", encoding="utf-8") as f:
        json.dump({"Buildings": sorted(b["Key"] for b in before["Buildings"]), "Premises": sorted(p["Key"] for p in before["Premises"])}, f, indent=0)
    print(f"{len(buildings)} edificios y {len(premises)} negocios quitados -> {args.out}; claves de antes -> {keys_path}")
    empty = [k for k, v in buildings.items() if not v] + [k for k, v in premises.items() if not v]
    if empty:
        print("sin sustituto:", empty)


if __name__ == "__main__":
    main()
