"""Compone la música original de la historia de vida y la guarda en roblox/audio/.

Todo se genera con código (síntesis de instrumentos + reverberación), así que la música es
100 % propia: no hay derechos de terceros y se puede subir a Roblox sin problemas.

Uso (desde roblox/):   python3 scripts/audio/compose.py
Necesita:              pip install numpy soundfile

Piezas:
  nacimiento.ogg         nana de caja de música (el nacimiento, la casa del bebé)   · bucle
  tema_valmar.ogg        tema principal de Valmar (ventanal, llegada a la ciudad)    · bucle
  pasan_los_anos.ogg     el paso del tiempo (transiciones de etapa)
  vida_adulta.ogg        esperanza, empieza la vida adulta                          · bucle
  sting_momento.ogg      campanitas para cada "momento de vida"
  sting_capitulo.ogg     entrada de capítulo
  sting_primeros_pasos.ogg  ¡primeros pasos!
"""

from pathlib import Path

import numpy as np
import soundfile as sf

SR = 44100
OUT = Path(__file__).resolve().parents[2] / "audio"
RNG = np.random.default_rng(200)  # semilla fija: siempre sale la misma música

NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name: str) -> int:
    letter, rest = name[0], name[1:]
    shift = 0
    while rest and rest[0] in "#b":
        shift += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + NOTE_INDEX[letter] + shift


def freq(name: str) -> float:
    return 440.0 * 2 ** ((midi(name) - 69) / 12)


# ---------------------------------------------------------------------------
# Instrumentos (devuelven una señal mono con su cola)
# ---------------------------------------------------------------------------

def _t(seconds: float) -> np.ndarray:
    return np.arange(int(seconds * SR)) / SR


def _release(sig: np.ndarray, hold: float, release: float) -> np.ndarray:
    n_hold = int(hold * SR)
    if n_hold < len(sig):
        tail = len(sig) - n_hold
        env = np.ones(len(sig))
        env[n_hold:] = np.exp(-np.arange(tail) / (release * SR) * 5)
        sig = sig * env
    return sig


def piano(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
    t = _t(dur + 1.8)
    sig = np.zeros_like(t)
    for n in range(1, 9):
        fn = f * n * np.sqrt(1 + 0.0004 * n * n)
        if fn > SR / 2.2:
            break
        amp = 1 / n**1.3
        decay = 0.9 + 0.55 * n + f / 900
        sig += amp * np.sin(2 * np.pi * fn * t + RNG.uniform(0, 6.28)) * np.exp(-t * decay)
    attack = np.minimum(t / 0.004, 1)
    hammer = RNG.normal(0, 1, len(t)) * np.exp(-t * 90) * 0.03
    sig = (sig * attack + hammer) * vel * 0.32
    return _release(sig, dur, 0.25)


def musicbox(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
    t = _t(max(dur, 0.1) + 2.2)
    parts = [(1, 1.0, 2.4), (2, 0.28, 4.0), (3, 0.08, 6.0), (4.17, 0.12, 7.0), (5.4, 0.05, 9.0)]
    sig = np.zeros_like(t)
    for ratio, amp, decay in parts:
        sig += amp * np.sin(2 * np.pi * f * ratio * t) * np.exp(-t * decay)
    sig *= np.minimum(t / 0.002, 1)
    return sig * vel * 0.26


def pad(f: float, dur: float, vel: float = 0.5) -> np.ndarray:
    t = _t(dur + 1.6)
    sig = np.zeros_like(t)
    for detune in (-0.004, 0.0, 0.005):
        fd = f * (1 + detune)
        for n in range(1, 10):
            if fd * n > 6000:
                break
            sig += (1 / n**1.6) * np.sin(2 * np.pi * fd * n * t + RNG.uniform(0, 6.28))
    env = np.minimum(t / 1.1, 1)
    sig = sig * env / 3
    return _release(sig, dur, 1.4) * vel * 0.16


def strings(f: float, dur: float, vel: float = 0.6) -> np.ndarray:
    t = _t(dur + 0.9)
    vib = 1 + 0.003 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(t / 0.5, 1)
    phase = 2 * np.pi * f * np.cumsum(vib) / SR
    sig = np.zeros_like(t)
    for n in range(1, 8):
        sig += (1 / n**1.5) * np.sin(n * phase + RNG.uniform(0, 6.28))
    env = np.minimum(t / 0.35, 1)
    return _release(sig * env, dur, 0.5) * vel * 0.2


def bass(f: float, dur: float, vel: float = 0.7) -> np.ndarray:
    t = _t(dur + 0.4)
    sig = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t)
    env = np.minimum(t / 0.01, 1) * (0.7 + 0.3 * np.exp(-t * 3))
    return _release(sig * env, dur, 0.15) * vel * 0.3


def pluck(f: float, dur: float, vel: float = 0.6) -> np.ndarray:
    t = _t(dur + 1.2)
    sig = np.zeros_like(t)
    for n in range(1, 12):
        if f * n > SR / 2.2:
            break
        sig += (1 / n) * np.sin(2 * np.pi * f * n * t) * np.exp(-t * (2.5 + 1.4 * n))
    sig *= np.minimum(t / 0.002, 1)
    return _release(sig, dur, 0.2) * vel * 0.22


INSTRUMENTS = {"piano": piano, "musicbox": musicbox, "pad": pad, "strings": strings, "bass": bass, "pluck": pluck}
PAN = {"piano": 0.0, "musicbox": 0.25, "pad": 0.0, "strings": -0.2, "bass": 0.0, "pluck": -0.3}


# ---------------------------------------------------------------------------
# Mezcla
# ---------------------------------------------------------------------------

class Track:
    def __init__(self, seconds: float):
        self.buf = np.zeros((int((seconds + 4) * SR), 2))

    def note(self, inst: str, name: str, start: float, dur: float, vel: float = 0.8):
        sig = INSTRUMENTS[inst](freq(name), dur, vel)
        i = int(start * SR)
        end = min(len(self.buf), i + len(sig))
        pan = PAN[inst]
        self.buf[i:end, 0] += sig[: end - i] * np.sqrt((1 - pan) / 2)
        self.buf[i:end, 1] += sig[: end - i] * np.sqrt((1 + pan) / 2)

    def chord(self, inst: str, names: list[str], start: float, dur: float, vel: float = 0.6):
        for name in names:
            self.note(inst, name, start, dur, vel)


def reverb(buf: np.ndarray, seconds: float = 2.4, wet: float = 0.28) -> np.ndarray:
    n = int(seconds * SR)
    t = np.arange(n) / SR
    out = np.empty_like(buf)
    for ch in range(2):
        ir = RNG.normal(0, 1, n) * np.exp(-t / (seconds / 5))
        ir = np.convolve(ir, np.ones(8) / 8, mode="same")  # un poco más suave (sin agudos ásperos)
        ir /= np.sqrt(np.sum(ir**2))
        size = 1 << int(np.ceil(np.log2(len(buf) + n)))
        spec = np.fft.rfft(buf[:, ch], size) * np.fft.rfft(ir, size)
        wet_sig = np.fft.irfft(spec, size)[: len(buf)]
        out[:, ch] = buf[:, ch] * (1 - wet * 0.5) + wet_sig * wet
    return out


def finish(track: Track, name: str, length: float, loop: bool, tail: float = 2.5):
    buf = reverb(track.buf)
    n = int(length * SR)
    if loop:
        # La cola que sobra se suma al principio: el bucle suena continuo, sin corte
        tail = buf[n:]
        buf = buf[:n].copy()
        k = min(len(tail), n)
        buf[:k] += tail[:k]
    else:
        fade = int(0.8 * SR)
        buf = buf[: n + int(tail * SR)]
        buf[-fade:] *= np.linspace(1, 0, fade)[:, None]
    buf *= 0.85 / (np.max(np.abs(buf)) + 1e-9)
    OUT.mkdir(parents=True, exist_ok=True)
    sf.write(OUT / name, buf.astype(np.float32), SR, format="OGG", subtype="VORBIS")
    print(f"  {name:28s} {len(buf) / SR:5.1f} s")


def melody(track: Track, inst: str, notes: list[tuple[str, float]], start: float, beat: float, vel: float = 0.8):
    t = start
    for name, beats in notes:
        if name != "-":
            track.note(inst, name, t, beats * beat * 0.95, vel)
        t += beats * beat
    return t


# ---------------------------------------------------------------------------
# Piezas
# ---------------------------------------------------------------------------

CHORDS = {
    "C": ["C", "E", "G"], "Dm": ["D", "F", "A"], "Em": ["E", "G", "B"], "F": ["F", "A", "C"],
    "G": ["G", "B", "D"], "Am": ["A", "C", "E"], "Bb": ["Bb", "D", "F"], "Gm": ["G", "Bb", "D"],
    "D": ["D", "F#", "A"], "A": ["A", "C#", "E"], "Bm": ["B", "D", "F#"], "F#m": ["F#", "A", "C#"],
}


def voicing(chord: str, octave: int) -> list[str]:
    return [f"{n}{octave}" for n in CHORDS[chord]]


def nacimiento():
    bpm, beats_per_bar = 66, 3
    beat = 60 / bpm
    prog = ["F", "Dm", "Bb", "C", "F", "Dm", "Gm", "C", "Bb", "F", "Gm", "C", "F", "Bb", "C", "F"]
    tune = [
        [("A5", 2), ("G5", 0.5), ("F5", 0.5)], [("A5", 1), ("D6", 1), ("C6", 1)],
        [("Bb5", 2), ("A5", 0.5), ("G5", 0.5)], [("G5", 3)],
        [("A5", 2), ("G5", 0.5), ("F5", 0.5)], [("A5", 1), ("D6", 1), ("F6", 1)],
        [("D6", 1.5), ("C6", 0.5), ("Bb5", 1)], [("C6", 3)],
        [("D6", 2), ("C6", 0.5), ("Bb5", 0.5)], [("C6", 1), ("A5", 1), ("F5", 1)],
        [("Bb5", 1), ("A5", 1), ("G5", 1)], [("E5", 1.5), ("G5", 1.5)],
        [("A5", 2), ("C6", 1)], [("D6", 1), ("C6", 1), ("Bb5", 1)],
        [("A5", 1.5), ("G5", 1.5)], [("F5", 3)],
    ]
    length = len(prog) * beats_per_bar * beat
    tr = Track(length)
    for bar, chord in enumerate(prog):
        t0 = bar * beats_per_bar * beat
        root = CHORDS[chord][0]
        tr.note("piano", f"{root}3", t0, beat * 2.8, 0.45)
        tr.chord("piano", voicing(chord, 4)[1:], t0 + beat, beat * 0.9, 0.3)
        tr.chord("piano", voicing(chord, 4)[1:], t0 + 2 * beat, beat * 0.9, 0.28)
        tr.chord("pad", voicing(chord, 4), t0, beats_per_bar * beat, 0.5)
        melody(tr, "musicbox", tune[bar], t0, beat, 0.85)
    finish(tr, "nacimiento.ogg", length, loop=True)


def tema_valmar():
    bpm = 90
    beat = 60 / bpm
    prog = ["D", "A", "Bm", "G", "D", "A", "G", "A", "Bm", "F#m", "G", "D", "Em", "A", "D", "D"]
    tune = [
        [("F#5", 1), ("A5", 1), ("D6", 2)], [("C#6", 1.5), ("B5", 0.5), ("A5", 2)],
        [("B5", 1), ("A5", 1), ("F#5", 2)], [("G5", 1), ("A5", 1), ("B5", 2)],
        [("A5", 1), ("F#5", 1), ("D6", 2)], [("E6", 1.5), ("D6", 0.5), ("C#6", 2)],
        [("B5", 1), ("D6", 1), ("E6", 2)], [("C#6", 4)],
        [("D6", 1), ("C#6", 1), ("B5", 2)], [("C#6", 1), ("A5", 1), ("F#5", 2)],
        [("G5", 1), ("B5", 1), ("D6", 2)], [("F#5", 1), ("A5", 1), ("D6", 2)],
        [("E6", 1.5), ("D6", 0.5), ("B5", 2)], [("C#6", 1), ("D6", 1), ("E6", 2)],
        [("F#6", 2), ("E6", 1), ("D6", 1)], [("D6", 4)],
    ]
    length = len(prog) * 4 * beat
    tr = Track(length)
    for bar, chord in enumerate(prog):
        t0 = bar * 4 * beat
        notes = CHORDS[chord]
        pattern = [f"{notes[0]}3", f"{notes[2]}3", f"{notes[1]}4", f"{notes[2]}4"] * 2
        for i, name in enumerate(pattern):
            tr.note("piano", name, t0 + i * beat / 2, beat * 0.6, 0.32 if i % 4 else 0.42)
        tr.note("bass", f"{notes[0]}2", t0, beat * 1.9, 0.6)
        tr.note("bass", f"{notes[0]}2", t0 + 2 * beat, beat * 1.9, 0.5)
        tr.chord("pad", voicing(chord, 4), t0, 4 * beat, 0.45)
        lead = "piano" if bar < 8 else "strings"
        melody(tr, lead, tune[bar], t0, beat, 0.9 if lead == "piano" else 0.8)
        if bar >= 8:
            melody(tr, "musicbox", [(n[:-1] + str(int(n[-1]) + 1) if n != "-" else n, b) for n, b in tune[bar]], t0, beat, 0.35)
    finish(tr, "tema_valmar.ogg", length, loop=True)


def pasan_los_anos():
    bpm = 104
    beat = 60 / bpm
    prog = ["C", "Am", "F", "G", "C", "Am", "F", "G", "D", "Bm", "G", "A"]
    tr = Track(len(prog) * 4 * beat + 8 * beat)
    for bar, chord in enumerate(prog):
        t0 = bar * 4 * beat
        notes = CHORDS[chord]
        octave = 4 if bar < 4 else 5
        up = [f"{notes[0]}{octave}", f"{notes[1]}{octave}", f"{notes[2]}{octave}", f"{notes[0]}{octave + 1}"]
        run = up + up[::-1][1:] + up[1:] + up[::-1][1:3]  # 16 semicorcheas, sube y baja
        for i, name in enumerate(run[:16]):
            tr.note("musicbox", name, t0 + i * beat / 4, beat / 4, 0.5 + 0.02 * bar)
        tr.chord("pad", voicing(chord, 3), t0, 4 * beat, 0.5 + 0.03 * bar)
        tr.note("strings", f"{notes[1]}5", t0, 4 * beat * 0.95, 0.5 + 0.03 * bar)
        tr.note("bass", f"{notes[0]}2", t0, 4 * beat, 0.5)
    t_end = len(prog) * 4 * beat
    tr.chord("piano", ["D3", "A3", "D4", "F#4", "A4", "D5"], t_end, 6 * beat, 0.5)
    tr.chord("pad", voicing("D", 4), t_end, 7 * beat, 0.6)
    for i, name in enumerate(["D6", "F#6", "A6", "D7"]):
        tr.note("musicbox", name, t_end + i * 0.12, 1.5, 0.6)
    finish(tr, "pasan_los_anos.ogg", t_end + 6 * beat, loop=False)


def vida_adulta():
    bpm = 96
    beat = 60 / bpm
    prog = ["G", "D", "Em", "C", "G", "D", "C", "D", "Em", "C", "G", "D", "C", "D", "G", "G"]
    tune = [
        [("B4", 1), ("D5", 1), ("G5", 2)], [("F#5", 1), ("E5", 1), ("D5", 2)],
        [("E5", 1), ("G5", 1), ("B5", 2)], [("A5", 1.5), ("G5", 0.5), ("E5", 2)],
        [("D5", 1), ("G5", 1), ("B5", 2)], [("A5", 1), ("F#5", 1), ("D5", 2)],
        [("E5", 1), ("G5", 1), ("C6", 2)], [("B5", 1), ("A5", 1), ("F#5", 2)],
        [("G5", 2), ("B5", 2)], [("C6", 1.5), ("B5", 0.5), ("A5", 2)],
        [("B5", 1), ("A5", 1), ("G5", 2)], [("A5", 4)],
        [("E5", 1), ("G5", 1), ("C6", 2)], [("D6", 1), ("C6", 1), ("A5", 2)],
        [("B5", 2), ("A5", 1), ("G5", 1)], [("G5", 4)],
    ]
    length = len(prog) * 4 * beat
    tr = Track(length)
    for bar, chord in enumerate(prog):
        t0 = bar * 4 * beat
        notes = CHORDS[chord]
        strum = voicing(chord, 3) + [f"{notes[0]}4"]
        for i in range(8):
            accent = 0.55 if i % 2 == 0 else 0.35
            for j, name in enumerate(strum):
                tr.note("pluck", name, t0 + i * beat / 2 + j * 0.012, beat * 0.45, accent)
        tr.note("bass", f"{notes[0]}2", t0, beat * 3.8, 0.55)
        tr.chord("pad", voicing(chord, 4), t0, 4 * beat, 0.4)
        melody(tr, "piano", tune[bar], t0, beat, 0.85)
    finish(tr, "vida_adulta.ogg", length, loop=True)


def sting_momento():
    tr = Track(4)
    for i, name in enumerate(["C6", "E6", "G6", "C7"]):
        tr.note("musicbox", name, 0.05 + i * 0.13, 1.2, 0.8)
    tr.chord("pad", ["C4", "E4", "G4", "C5"], 0, 2.2, 0.6)
    tr.chord("piano", ["C4", "G4", "E5"], 0.05, 2.2, 0.35)
    finish(tr, "sting_momento.ogg", 2.6, loop=False, tail=1.2)


def sting_capitulo():
    tr = Track(7)
    tr.chord("pad", ["F3", "C4", "E4", "G4", "A4"], 0, 4.5, 0.8)
    tr.chord("piano", ["F2", "C3", "A3", "E4", "G4"], 0.3, 4, 0.55)
    melody(tr, "musicbox", [("A5", 0.5), ("C6", 0.5), ("E6", 0.5), ("G6", 2)], 1.4, 0.5, 0.7)
    tr.note("strings", "C6", 1.4, 3.2, 0.5)
    finish(tr, "sting_capitulo.ogg", 5.2, loop=False, tail=1.2)


def sting_primeros_pasos():
    tr = Track(4)
    melody(tr, "musicbox", [("C6", 1), ("D6", 1), ("E6", 1), ("G6", 1), ("E6", 1), ("G6", 1), ("C7", 3)], 0, 0.16, 0.8)
    tr.chord("pluck", ["C4", "E4", "G4"], 0, 0.3, 0.5)
    tr.chord("pluck", ["C4", "E4", "G4", "C5"], 0.96, 1.5, 0.5)
    tr.chord("pad", ["C4", "E4", "G4"], 0.9, 1.6, 0.5)
    finish(tr, "sting_primeros_pasos.ogg", 2.6, loop=False, tail=1.2)


if __name__ == "__main__":
    print(f"Componiendo en {OUT}")
    nacimiento()
    tema_valmar()
    pasan_los_anos()
    vida_adulta()
    sting_momento()
    sting_capitulo()
    sting_primeros_pasos()
    print("Listo.")
