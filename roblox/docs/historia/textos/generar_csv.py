"""Genera la tabla de traducción de Roblox a partir de ../08-dialogos.md.

Uso (desde esta carpeta):  python3 generar_csv.py
Crea dialogos.csv con las columnas Key, Source, Context, Example, en.
La columna "en" queda vacía para que la rellene quien traduzca.
"""

import csv
import re
from pathlib import Path

HERE = Path(__file__).parent
SOURCE = HERE.parent / "08-dialogos.md"
OUTPUT = HERE / "dialogos.csv"

# Ejemplos de valores para cada variable (ayudan al traductor a entender la frase)
EXAMPLES = {
    "nombre": "Lucía",
    "mascota": "Toby",
    "sueno": "bombero",
    "profesion": "médica",
    "zona": "San Roque",
    "familiar": "mamá",
    "estadio": "Estadio Altamar",
    "titulo": "Medicina",
    "negocio": "Café del Valle",
    "proyecto": "Encender el Faro",
    "porcentaje": "73",
    "apellido": "García",
}

# Frases que cambian según la forma (femenina o masculina) que el jugador elige para su personaje
GENDER_VARIANTS = {
    "DLG.ABU.SUENO.R1": "¡Bombera! ¡Apagar fuegos!",
    "DLG.ABU.SUENO.R2": "¡Médica! ¡Curar a la gente!",
    "DLG.ABU.SUENO.R3": "¡Cocinera! ¡Hacer comida rica!",
    "DLG.ABU.SUENO.R5": "¡Inventora! ¡Hacer robots!",
    "DLG.ABU.FIN.01": "Mañana hay carrera de bicis con Nico. ¡Descansa, campeona del día!",
    "DLG.VICTORIA.EXITO.01": "Tu negocio ha salido en Radio Valmar. Bien jugado, emprendedora. Ahora no te relajes.",
}

ROW = re.compile(r"^\|\s*(DLG\.[A-Z0-9_.]+)\s*\|\s*([^|]*?)\s*\|\s*([^|]+?)\s*\|\s*$")
SECTION = re.compile(r"^#{2,3}\s+(.*)$")


def example_for(text: str) -> str:
    names = re.findall(r"\{(\w+)\}", text)
    return ", ".join(f"{{{n}}}={EXAMPLES.get(n, '?')}" for n in dict.fromkeys(names))


def main() -> None:
    rows = []
    section = ""
    for line in SOURCE.read_text(encoding="utf-8").splitlines():
        heading = SECTION.match(line)
        if heading:
            section = heading.group(1)
            continue
        match = ROW.match(line)
        if not match:
            continue
        key, who, text = match.groups()
        who = "Respuesta del jugador" if who.startswith(">") else who
        context = f"{section} · {who}".strip(" ·")
        if key in GENDER_VARIANTS:
            rows.append([key + "_M", text, context + " (forma masculina)", example_for(text), ""])
            female = GENDER_VARIANTS[key]
            rows.append([key + "_F", female, context + " (forma femenina)", example_for(female), ""])
        else:
            rows.append([key, text, context, example_for(text), ""])

    keys = [r[0] for r in rows]
    duplicates = {k for k in keys if keys.count(k) > 1}
    if duplicates:
        raise SystemExit(f"Claves repetidas: {sorted(duplicates)}")

    with OUTPUT.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["Key", "Source", "Context", "Example", "en"])
        writer.writerows(rows)
    print(f"{len(rows)} textos escritos en {OUTPUT.name}")


if __name__ == "__main__":
    main()
