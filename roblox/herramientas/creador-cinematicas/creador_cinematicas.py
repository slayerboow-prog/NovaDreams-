"""Creador de cinemáticas de Heroes of History.

Pegas los diálogos y lo que pasa en cada escena (como quieras escribirlo) y una IA lo convierte en
el guion de la misión con el formato que entiende el juego (formato.md). Después el programa lo
comprueba y lo mete en el juego con la herramienta de siempre:
    lune run scripts/audit/aplicar-reescritura.luau <IdMision>
que genera src/shared/LifeStory/Guiones/<IdMision>.luau (cinemáticas, conversaciones, planos, gestos).

Dos formas de usar la IA:
  * Claude (automático): necesita una clave de la API de Anthropic (console.anthropic.com). Se guarda
    en %APPDATA%\\CreadorCinematicas\\clave.txt, nunca en el proyecto.
  * ChatGPT (gratis, a mano): «Copiar petición para ChatGPT», la pegas allí y pegas su respuesta aquí.

Se abre con «Creador de Cinematicas.bat».
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import threading
import time
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, scrolledtext, simpledialog, ttk

HERE = Path(__file__).resolve().parent
ROBLOX = HERE.parent.parent  # .../roblox
GUIONES_MD = ROBLOX / "docs" / "historia" / "reescritura"
TOOL = "scripts/audit/aplicar-reescritura.luau"
COPIAS = HERE / "copias"
FORMATO = HERE / "formato.md"
CONFIG_DIR = Path(os.environ.get("APPDATA", str(Path.home()))) / "CreadorCinematicas"
CLAVE = CONFIG_DIR / "clave.txt"

MODEL = "claude-opus-5-5"
MAX_ARREGLOS = 2  # veces que la IA corrige sola los errores del comprobador


# ---------------------------------------------------------------------------
# Herramienta del juego (lune)
# ---------------------------------------------------------------------------
def lune_exe() -> str | None:
    found = shutil.which("lune")
    if found:
        return found
    for cand in (Path.home() / "bin" / "lune.exe", Path.home() / "bin" / "lune"):
        if cand.exists():
            return str(cand)
    return None


def run_tool(*args: str) -> tuple[int, str]:
    exe = lune_exe()
    if not exe:
        return 1, "❌ No encuentro «lune» (la herramienta del juego). Debe estar en la carpeta bin de tu usuario."
    proc = subprocess.run(
        [exe, "run", TOOL, *args],
        cwd=ROBLOX,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    )
    return proc.returncode, (proc.stdout + proc.stderr).strip()


def missions() -> list[str]:
    ids = sorted(p.stem for p in GUIONES_MD.glob("*.md") if not p.stem.endswith(".informe"))
    return ids


def md_path(mission: str) -> Path:
    return GUIONES_MD / f"{mission}.md"


class GuionTemporal:
    """Pone el guion nuevo en su sitio mientras dura el bloque y, si no se queda, deja el de antes."""

    def __init__(self, mission: str, text: str):
        self.path = md_path(mission)
        self.informe = GUIONES_MD / f"{mission}.informe.md"  # la herramienta lo reescribe aunque falle
        self.text = text
        self.before: bytes | None = None
        self.informe_before: bytes | None = None
        self.keep = False

    def __enter__(self):
        if self.path.exists():
            self.before = self.path.read_bytes()
        if self.informe.exists():
            self.informe_before = self.informe.read_bytes()
        # mismos saltos de línea que el archivo que había (en este PC, git los deja en CRLF)
        crlf = self.before is None or b"\r\n" in self.before
        body = self.text.replace("\r\n", "\n")
        if crlf:
            body = body.replace("\n", "\r\n")
        self.path.write_bytes(body.encode("utf-8"))
        return self

    def __exit__(self, *exc):
        if self.keep:
            if self.before is not None:
                COPIAS.mkdir(exist_ok=True)
                stamp = time.strftime("%Y%m%d-%H%M%S")
                (COPIAS / f"{self.path.stem}-{stamp}.md").write_bytes(self.before)
            return False
        for path, old in ((self.path, self.before), (self.informe, self.informe_before)):
            if old is None:
                path.unlink(missing_ok=True)
            else:
                path.write_bytes(old)
        return False


def check(mission: str, text: str) -> tuple[bool, str]:
    with GuionTemporal(mission, text):
        code, out = run_tool(mission, "--check")
    return code == 0, out


def apply(mission: str, text: str) -> tuple[bool, str]:
    with GuionTemporal(mission, text) as tmp:
        code, out = run_tool(mission)
        tmp.keep = code == 0
    return code == 0, out


# ---------------------------------------------------------------------------
# Petición a la IA
# ---------------------------------------------------------------------------
SYSTEM = """Eres guionista y director de cine de un juego de Roblox («Heroes of History»), una película \
interactiva en español de España. Tu trabajo: convertir el material que te da el dueño del juego \
(diálogos y detalles de las escenas, escritos de cualquier manera) en el guion de UNA misión con el \
formato exacto que entiende el juego. Respeta su historia, sus personajes y sus frases; mejora solo lo \
necesario para que suene natural y se vea como una película (planos, gestos, pausas). Responde SOLO con \
el guion, sin explicaciones ni bloques de código.

{formato}"""


def build_request(mission: str, material: str) -> str:
    _, pasos = run_tool(mission, "--pasos")
    current = md_path(mission).read_text(encoding="utf-8") if md_path(mission).exists() else "(todavía no tiene guion)"
    return (
        f"Misión: {mission}\n\n"
        f"Pasos del juego y del guion actual (no cambies el número ni el orden de los pasos jugables):\n{pasos}\n\n"
        f"Guion actual de la misión (úsalo de base: mismos nombres de personajes y lugares):\n{current}\n\n"
        f"Material nuevo del dueño (diálogos y detalles de las escenas):\n{material}\n\n"
        "Escribe el guion completo de la misión con el formato."
    )


def chatgpt_prompt(mission: str, material: str) -> str:
    formato = FORMATO.read_text(encoding="utf-8")
    return SYSTEM.format(formato=formato) + "\n\n---\n\n" + build_request(mission, material)


def load_key() -> str | None:
    if os.environ.get("ANTHROPIC_API_KEY"):
        return os.environ["ANTHROPIC_API_KEY"]
    if CLAVE.exists():
        key = CLAVE.read_text(encoding="utf-8").strip()
        return key or None
    return None


def strip_fences(text: str) -> str:
    t = text.strip()
    if t.startswith("```"):
        t = t.split("\n", 1)[1] if "\n" in t else ""
        if t.rstrip().endswith("```"):
            t = t.rstrip()[:-3]
    return t.strip() + "\n"


def ask_claude(key: str, messages: list[dict]) -> str:
    import anthropic

    client = anthropic.Anthropic(api_key=key)
    system = SYSTEM.format(formato=FORMATO.read_text(encoding="utf-8"))
    with client.beta.messages.stream(
        model=MODEL,
        max_tokens=64000,
        thinking={"type": "adaptive"},
        output_config={"effort": "high"},
        betas=["server-side-fallback-2026-07-01"],
        fallbacks="default",
        system=system,
        messages=messages,
    ) as stream:
        msg = stream.get_final_message()
    if msg.stop_reason == "refusal":
        raise RuntimeError("La IA no ha querido escribir este guion. Prueba a cambiar el texto.")
    text = "".join(b.text for b in msg.content if b.type == "text")
    if msg.stop_reason == "max_tokens":
        raise RuntimeError("El guion era demasiado largo y se ha cortado. Pásalo en trozos más pequeños.")
    return strip_fences(text)


# ---------------------------------------------------------------------------
# Ventana
# ---------------------------------------------------------------------------
class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Creador de cinemáticas · Heroes of History")
        self.geometry("1200x800")
        self.minsize(900, 600)
        style = ttk.Style(self)
        style.configure("Big.TButton", font=("Segoe UI", 11, "bold"), padding=8)
        style.configure("TLabel", font=("Segoe UI", 10))
        style.configure("Title.TLabel", font=("Segoe UI", 11, "bold"))

        top = ttk.Frame(self, padding=8)
        top.pack(fill="x")
        ttk.Label(top, text="Misión:", style="Title.TLabel").pack(side="left")
        self.mission = ttk.Combobox(top, values=missions(), width=40, font=("Segoe UI", 11))
        self.mission.pack(side="left", padx=6)
        ttk.Button(top, text="Ver pasos de la misión", command=self.show_steps).pack(side="left", padx=4)
        ttk.Button(top, text="Cargar su guion actual", command=self.load_current).pack(side="left", padx=4)
        ttk.Button(top, text="Clave de Claude…", command=self.set_key).pack(side="right")

        panes = ttk.PanedWindow(self, orient="horizontal")
        panes.pack(fill="both", expand=True, padx=8)

        left = ttk.Frame(panes)
        ttk.Label(left, text="1 · Pega aquí los diálogos y lo que pasa en cada escena (como quieras)", style="Title.TLabel").pack(anchor="w")
        self.material = scrolledtext.ScrolledText(left, wrap="word", font=("Segoe UI", 11), undo=True)
        self.material.pack(fill="both", expand=True)
        row = ttk.Frame(left)
        row.pack(fill="x", pady=6)
        ttk.Button(row, text="2 · Crear guion con IA (Claude)", style="Big.TButton", command=self.with_claude).pack(side="left")
        ttk.Button(row, text="…o copiar petición para ChatGPT", command=self.copy_for_chatgpt).pack(side="left", padx=8)
        panes.add(left, weight=1)

        right = ttk.Frame(panes)
        ttk.Label(right, text="3 · Guion para el juego (puedes retocarlo o pegar aquí la respuesta de ChatGPT)", style="Title.TLabel").pack(anchor="w")
        self.guion = scrolledtext.ScrolledText(right, wrap="word", font=("Consolas", 10), undo=True)
        self.guion.pack(fill="both", expand=True)
        row2 = ttk.Frame(right)
        row2.pack(fill="x", pady=6)
        ttk.Button(row2, text="Comprobar", command=self.do_check).pack(side="left")
        ttk.Button(row2, text="4 · Meter en el juego", style="Big.TButton", command=self.do_apply).pack(side="left", padx=8)
        panes.add(right, weight=1)

        ttk.Label(self, text="Resultado", style="Title.TLabel").pack(anchor="w", padx=8)
        self.log = scrolledtext.ScrolledText(self, height=10, wrap="word", font=("Consolas", 10), state="disabled")
        self.log.pack(fill="x", padx=8, pady=(0, 8))
        self.busy = False
        self.say("Elige una misión, pega tu texto a la izquierda y pulsa «Crear guion con IA».")

    # -- utilidades
    def say(self, text: str, clear: bool = False):
        self.log.configure(state="normal")
        if clear:
            self.log.delete("1.0", "end")
        self.log.insert("end", text.rstrip() + "\n")
        self.log.see("end")
        self.log.configure(state="disabled")

    def later(self, fn, *args):
        self.after(0, fn, *args)

    def current_mission(self) -> str | None:
        m = self.mission.get().strip()
        if not m:
            messagebox.showwarning("Falta la misión", "Elige primero una misión de la lista.")
            return None
        return m

    def background(self, label: str, work):
        if self.busy:
            return
        self.busy = True
        self.config(cursor="watch")
        self.say(f"⏳ {label}…", clear=True)

        def runner():
            try:
                work()
            except Exception as e:  # mostrar cualquier fallo en la ventana, no en una consola
                self.later(self.say, f"❌ {e}")
            finally:
                self.later(self.done)

        threading.Thread(target=runner, daemon=True).start()

    def done(self):
        self.busy = False
        self.config(cursor="")

    # -- botones
    def show_steps(self):
        m = self.current_mission()
        if m:
            self.background("Leyendo los pasos", lambda: self.later(self.say, run_tool(m, "--pasos")[1]))

    def load_current(self):
        m = self.current_mission()
        if not m:
            return
        p = md_path(m)
        if not p.exists():
            self.say("Esta misión todavía no tiene guion.", clear=True)
            return
        self.guion.delete("1.0", "end")
        self.guion.insert("1.0", p.read_text(encoding="utf-8"))
        self.say("Cargado el guion actual a la derecha. Puedes retocarlo y pulsar «Meter en el juego».", clear=True)

    def set_key(self):
        key = simpledialog.askstring(
            "Clave de Claude",
            "Pega tu clave de la API de Anthropic (empieza por sk-ant-).\nSe crea en console.anthropic.com → API Keys.\nSe guarda solo en este ordenador.",
            parent=self,
            show="•",
        )
        if key and key.strip():
            CONFIG_DIR.mkdir(parents=True, exist_ok=True)
            CLAVE.write_text(key.strip(), encoding="utf-8")
            self.say("✅ Clave guardada.", clear=True)

    def copy_for_chatgpt(self):
        m = self.current_mission()
        material = self.material.get("1.0", "end").strip()
        if not m or not material:
            if m:
                messagebox.showwarning("Falta el texto", "Pega primero los diálogos y las escenas a la izquierda.")
            return
        text = chatgpt_prompt(m, material)
        self.clipboard_clear()
        self.clipboard_append(text)
        self.say(
            "📋 Petición copiada. Abre ChatGPT, pégala (Ctrl+V) y envíala.\n"
            "Copia su respuesta, pégala en el cuadro de la derecha y pulsa «Comprobar» o «Meter en el juego».",
            clear=True,
        )

    def with_claude(self):
        m = self.current_mission()
        material = self.material.get("1.0", "end").strip()
        if not m:
            return
        if not material:
            messagebox.showwarning("Falta el texto", "Pega primero los diálogos y las escenas a la izquierda.")
            return
        key = load_key()
        if not key:
            self.set_key()
            key = load_key()
            if not key:
                self.say("Sin clave de Claude no puedo usar la IA automática. Usa «copiar petición para ChatGPT».", clear=True)
                return
        try:
            import anthropic  # noqa: F401
        except ImportError:
            self.say("❌ Falta instalar la librería de Claude. Cierra y abre el programa con «Creador de Cinematicas.bat».", clear=True)
            return

        def work():
            messages = [{"role": "user", "content": build_request(m, material)}]
            guion = ask_claude(key, messages)
            for intento in range(MAX_ARREGLOS + 1):
                ok, out = check(m, guion)
                self.later(self.show_guion, guion)
                if ok:
                    self.later(self.say, "✅ Guion creado y comprobado. Revísalo a la derecha y pulsa «Meter en el juego».\n\n" + out)
                    return
                if intento == MAX_ARREGLOS:
                    self.later(self.say, "⚠️ El guion tiene errores que la IA no ha sabido arreglar. Míralos aquí debajo y retócalo a mano:\n\n" + out)
                    return
                self.later(self.say, f"🔧 El comprobador ha encontrado errores; la IA los corrige (intento {intento + 1})…")
                messages += [
                    {"role": "assistant", "content": guion},
                    {"role": "user", "content": "El comprobador del juego dice esto. Corrige los errores y devuelve el guion completo:\n\n" + out},
                ]
                guion = ask_claude(key, messages)

        self.background("La IA está escribiendo el guion (puede tardar uno o dos minutos)", work)

    def show_guion(self, text: str):
        self.guion.delete("1.0", "end")
        self.guion.insert("1.0", text)

    def guion_text(self) -> str | None:
        t = self.guion.get("1.0", "end").strip()
        if not t:
            messagebox.showwarning("Falta el guion", "El cuadro de la derecha está vacío.")
            return None
        return strip_fences(t)

    def do_check(self):
        m = self.current_mission()
        t = self.guion_text() if m else None
        if m and t:
            def work():
                ok, out = check(m, t)
                self.later(self.say, ("✅ Todo correcto.\n\n" if ok else "⚠️ Hay errores:\n\n") + out)

            self.background("Comprobando", work)

    def do_apply(self):
        m = self.current_mission()
        t = self.guion_text() if m else None
        if not (m and t):
            return
        if not messagebox.askyesno("Meter en el juego", f"¿Meter este guion en la misión {m}?\n(El guion anterior se guarda en una copia.)"):
            return

        def work():
            ok, out = apply(m, t)
            if ok:
                self.later(
                    self.say,
                    f"✅ Hecho. La misión {m} ya tiene las cinemáticas nuevas.\n"
                    "Para verlas en Roblox hay que publicar una versión nueva del juego.\n\n" + out,
                )
            else:
                self.later(self.say, "⚠️ No se ha metido nada (hay errores). Corrígelos y vuelve a probar:\n\n" + out)

        self.background("Metiendo el guion en el juego", work)


if __name__ == "__main__":
    if not GUIONES_MD.exists():
        print("No encuentro la carpeta del juego:", GUIONES_MD)
        sys.exit(1)
    App().mainloop()
