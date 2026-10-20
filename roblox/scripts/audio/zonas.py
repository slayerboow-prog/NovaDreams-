"""Sonido por zona (espacio, Tefra, el mar y Nácara): ambientes y música, todo hecho por código.

Como compose.py y sfx.py: síntesis (ruido filtrado, tonos, voces inventadas sin palabras, instrumentos
de compose.py), así que todo es 100 % nuestro y se puede subir a Roblox sin problemas de derechos.
Ver docs/audio/zonas.md (qué suena en cada zona) y audio/README.md.

Uso (desde roblox/):   python3 scripts/audio/zonas.py            (todos)
                       python3 scripts/audio/zonas.py amb_espacio espacio_crucero   (solo esos)
Necesita:              pip install numpy soundfile

Ambientes (audio/sfx, mono, bucles que empalman sin clic):
  amb_espacio.ogg     zumbido grave del espacio profundo, muy lento                · bucle 12 s
  amb_cabina.ogg      zumbido suave de la cabina de la nave (ventilación y 50 Hz)    · bucle 8 s
  amb_radio.ogg       radio lejana de una estación: voces inventadas, chasquidos     · bucle 10 s
  amb_tefra.ogg       Tefra: rumor de la lava, burbujeo y viento de ceniza            · bucle 12 s
  amb_fundicion.ogg   fundiciones a lo lejos: golpes de metal y una prensa            · bucle 10 s
  sirena_tefra.ogg    sirena de bombardeo (sube y baja), lejana                       · bucle 8 s
  amb_submarino.ogg   bajo el agua: rumor apagado y burbujas                          · bucle 10 s
  ballena_lejos.ogg   canto de ballena muy lejos (golpe suelto)                         6 s

Música (audio/, estéreo, bucles; StoryAudio la cruza con fundido):
  espacio_crucero.ogg   crucero tranquilo: colchones en re lidio y estrellas de caja de música
  espacio_deriva.ogg    deriva: la menor con novena, cuerdas y piano suelto (la otra del crucero)
  espacio_combate.ogg   combate: pulso en mi menor a 120, tambores sintéticos, sin melodía
  espacio_estacion.ogg  estación atracada: acordes cálidos, bajo suave y platillo muy fino
  tefra_guerra.ogg      Tefra: tambores de guerra apagados, yunque lejano y un bordón grave
  tefra_refugio.ogg     Tefra en un refugio / tras la tregua: cuerdas graves y piano, esperanza
  nacara.ogg            Nácara: arpegios de cristal con mucha reverberación, etéreo
"""

import sys
from pathlib import Path

import numpy as np
import soundfile as sf

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import compose as C  # noqa: E402  (instrumentos y mezcla de la música)
import sfx as S  # noqa: E402  (ruidos, filtros, voces inventadas y bucles de los efectos)

SR = S.SR
MUSIC_OUT = HERE.parents[1] / "audio"


def seed(n: int):
    S._seed(n)
    C._seed(n)


def rms(x: np.ndarray) -> np.ndarray:
    return S.unit_rms(x)


def periodic_sines(length: float, freqs: list[tuple[float, float]]) -> np.ndarray:
    """Tonos que caben un número entero de veces en el bucle (empalman solos)."""
    t = S.t_of(length)
    out = np.zeros(len(t))
    for f, amp in freqs:
        f = round(f * length) / length
        out += amp * np.sin(2 * np.pi * f * t + S.RNG.uniform(0, 6.28))
    return out


def lfo(length: float, cycles: int, depth: float, phase: float = 0.0) -> np.ndarray:
    """Subida y bajada lenta que da `cycles` vueltas justas en el bucle."""
    t = S.t_of(length)
    return 1 + depth * np.sin(2 * np.pi * cycles * t / length + phase)


def circ(x: np.ndarray, gain) -> np.ndarray:
    return S.spectral(x, gain, pad=False)


def circ_reverb(x: np.ndarray, seconds: float, wet: float, bright: float = 3000) -> np.ndarray:
    """Reverberación circular: la cola del final vuelve al principio (para bucles)."""
    t = S.t_of(seconds)
    ir = S.RNG.normal(0, 1, len(t)) * np.exp(-t / (seconds / 5))
    ir = S.spectral(ir, lambda f: S.lowpass_gain(f, bright, 1))
    ir /= np.sqrt(np.sum(ir**2))
    n = len(x)
    pad = np.zeros(n)
    pad[: min(n, len(ir))] = ir[:n]
    w = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(pad), n)
    return x * (1 - wet * 0.5) + w * wet


def write_sfx(name: str, sig: np.ndarray, loop: bool):
    S.write(name, sig, loop)


# ---------------------------------------------------------------------------
# Ambientes
# ---------------------------------------------------------------------------

def amb_espacio():
    """Espacio profundo: un acorde muy grave que respira (sin viento ni pájaros) y un aire oscuro."""
    seed(601)
    L = 12.0
    drone = periodic_sines(L, [(36.7, 1.0), (55.0, 0.7), (73.4, 0.35), (82.5, 0.18), (110.0, 0.1)])
    drone *= lfo(L, 1, 0.25) * lfo(L, 3, 0.08, 1.3)
    air = rms(circ(S.noise(L), lambda f: S.highpass_gain(f, 30, 1) * S.lowpass_gain(f, 220, 2))) * lfo(L, 2, 0.35, 0.6)
    shimmer = rms(circ(S.noise(L), lambda f: S.highpass_gain(f, 1800, 2) * S.lowpass_gain(f, 4200, 2))) * lfo(L, 1, 0.6, 2.2)
    sig = rms(drone) + 0.45 * air + 0.03 * shimmer
    write_sfx("amb_espacio.ogg", sig, loop=True)


def amb_cabina():
    """Cabina de la nave: zumbido eléctrico suave, ventilación y un pitido muy flojo de los paneles."""
    seed(602)
    L = 8.0
    hum = periodic_sines(L, [(50, 1.0), (100, 0.5), (150, 0.22), (200, 0.12), (300, 0.05)]) * lfo(L, 2, 0.04)
    fan = rms(circ(S.noise(L), lambda f: S.highpass_gain(f, 120, 2) * S.lowpass_gain(f, 1300, 2))) * lfo(L, 4, 0.06)
    panel = periodic_sines(L, [(2400, 0.02)]) * (0.5 + 0.5 * lfo(L, 1, 1.0) / 2)
    sig = 0.55 * rms(hum) + 0.8 * fan + panel
    write_sfx("amb_cabina.ogg", circ(sig, lambda f: S.lowpass_gain(f, 2600, 2)), loop=True)


def amb_radio():
    """Radio de una estación, lejos: frases sueltas de voces inventadas (sin palabras) por un altavoz
    pequeño, chasquido al abrir y cerrar y un pitido corto de fin de mensaje. Entre medias, silencio."""
    seed(603)
    L = 10.0
    buf = np.zeros(S.n_of(L))
    hiss = rms(circ(S.noise(L), lambda f: S.highpass_gain(f, 400, 2) * S.lowpass_gain(f, 3000, 2))) * 0.04
    for start, dur, f0 in ((0.6, 1.8, 120), (3.9, 1.4, 205), (6.7, 2.0, 135)):
        v = S.voice(dur, f0, talk=0.9, bright=3200)
        v = rms(S.band(v, 350, 2800, order=3)) * 0.35
        v *= S.adsr(len(v), 0.03, 0.08)
        S.add_at(buf, v, start)
        click = S.band(S.noise(0.04), 1500, 6000) * np.exp(-S.t_of(0.04) / 0.006) * 0.25
        S.add_at(buf, click, start - 0.05)
        S.add_at(buf, click * 0.7, start + dur + 0.02)
        tb = S.t_of(0.12)
        beep = np.sin(2 * np.pi * 1240 * tb) * S.adsr(len(tb), 0.005, 0.03) * 0.08
        S.add_at(buf, beep, start + dur + 0.1)
    sig = buf + hiss
    # muy lejos y por un altavoz: sin graves ni agudos, y con eco de la sala de la estación
    sig = circ(sig, lambda f: S.highpass_gain(f, 300, 2) * S.lowpass_gain(f, 2600, 2))
    write_sfx("amb_radio.ogg", circ_reverb(sig, 1.4, 0.35, 2400), loop=True)


def amb_tefra():
    """Tefra: el rumor grave de la lava, algún burbujeo espeso, crujidos de roca y viento de ceniza."""
    seed(604)
    L = 12.0
    rumble = rms(circ(S.noise(L), lambda f: S.highpass_gain(f, 25, 1) * S.lowpass_gain(f, 110, 3))) * lfo(L, 1, 0.3) * lfo(L, 5, 0.12, 0.8)
    wind = rms(circ(S.noise(L), lambda f: S.highpass_gain(f, 300, 2) * S.lowpass_gain(f, 1400, 2))) * lfo(L, 2, 0.45, 2.0)
    events = np.zeros(S.n_of(L))
    for _ in range(7):  # burbujas de lava (un «blop» grave que baja)
        tb = S.t_of(0.35)
        f = S.RNG.uniform(70, 120) * (1 - 0.35 * tb / 0.35)
        blop = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tb / 0.09)
        S.add_at(events, blop * S.RNG.uniform(0.4, 0.8), S.RNG.uniform(0, L), wrap=True)
    for _ in range(14):  # crujidos de roca caliente
        tc = S.t_of(0.03)
        crack = S.band(S.noise(0.03), 1200, 5000) * np.exp(-tc / 0.004)
        S.add_at(events, crack * S.RNG.uniform(0.05, 0.15), S.RNG.uniform(0, L), wrap=True)
    sig = rumble + 0.35 * wind + 0.8 * rms(events) * 0.4
    write_sfx("amb_tefra.ogg", circ(sig, lambda f: S.lowpass_gain(f, 4000, 2)), loop=True)


def amb_fundicion():
    """Fundiciones a lo lejos: golpes de metal con su eco, una prensa que late y el soplo del horno."""
    seed(605)
    L = 10.0
    events = np.zeros(S.n_of(L))
    partials = (1.0, 2.76, 5.4, 8.93)
    for start in (0.4, 1.7, 3.1, 5.6, 6.3, 8.2):  # martillazos (metal inarmónico)
        f0 = S.RNG.uniform(180, 260)
        th = S.t_of(1.2)
        hit = sum(np.sin(2 * np.pi * f0 * p * th) * np.exp(-th * (3 + 2.5 * p)) / p for p in partials)
        S.add_at(events, hit * S.RNG.uniform(0.5, 1.0), start, wrap=True)
    for start in (0.0, 2.5, 5.0, 7.5):  # la prensa grande (golpe sordo)
        tp = S.t_of(0.6)
        press = np.sin(2 * np.pi * 42 * tp) * np.exp(-tp / 0.12)
        S.add_at(events, press * 0.9, start, wrap=True)
    furnace = rms(circ(S.noise(L), lambda f: S.highpass_gain(f, 60, 2) * S.lowpass_gain(f, 500, 2))) * lfo(L, 1, 0.2)
    sig = rms(events) + 0.5 * furnace
    sig = circ(sig, lambda f: S.lowpass_gain(f, 1500, 2))  # (lejos: sin brillo)
    write_sfx("amb_fundicion.ogg", circ_reverb(sig, 2.2, 0.45, 1500), loop=True)


def sirena_tefra():
    """Sirena de bombardeo: sube cuatro segundos y baja otros cuatro (como las de verdad), lejana."""
    seed(606)
    L = 8.0
    t = S.t_of(L)
    sweep = 0.5 - 0.5 * np.cos(2 * np.pi * t / L)
    f = 290 + 380 * sweep
    cycles = np.sum(f) / SR
    f *= round(cycles) / cycles  # (vueltas enteras: empalma sin clic)
    phase = 2 * np.pi * np.cumsum(f) / SR
    tone = np.sin(phase) + 0.4 * np.sin(2 * phase) + 0.15 * np.sin(3 * phase)
    sig = circ(tone, lambda f_: S.lowpass_gain(f_, 1600, 2))
    write_sfx("sirena_tefra.ogg", circ_reverb(sig, 2.5, 0.55, 1800), loop=True)


def amb_submarino():
    """Bajo el agua: un rumor apagado que va y viene (el mar encima) y burbujas pequeñas que suben."""
    seed(607)
    L = 10.0
    bed = rms(circ(S.noise(L), lambda f: S.highpass_gain(f, 20, 1) * S.lowpass_gain(f, 260, 3))) * lfo(L, 1, 0.3) * lfo(L, 3, 0.1, 1.1)
    bubbles = np.zeros(S.n_of(L))
    for _ in range(26):
        d = S.RNG.uniform(0.02, 0.06)
        tb = S.t_of(d)
        f = S.RNG.uniform(500, 1400) * (1 + 1.5 * tb / d)  # (la burbuja sube de tono)
        b = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tb / (d / 3))
        S.add_at(bubbles, b * S.RNG.uniform(0.2, 0.6), S.RNG.uniform(0, L), wrap=True)
    sig = bed + 0.12 * rms(bubbles)
    write_sfx("amb_submarino.ogg", circ(sig, lambda f: S.lowpass_gain(f, 1800, 2)), loop=True)


def ballena_lejos():
    """Canto de ballena muy lejos: un tono que sube y baja despacio, con armónicos y mucho eco."""
    seed(608)
    D = 6.0
    t = S.t_of(D)
    curve = np.interp(t, [0, 1.2, 2.6, 4.2, 6.0], [170, 320, 250, 150, 140])
    phase = 2 * np.pi * np.cumsum(curve) / SR
    env = np.interp(t, [0, 0.6, 3.6, 4.6, 6.0], [0, 1, 0.8, 0, 0])
    call = (np.sin(phase) + 0.35 * np.sin(2 * phase) + 0.12 * np.sin(3 * phase)) * env * lfo(D, 9, 0.2)
    call = S.spectral(call, lambda f: S.lowpass_gain(f, 700, 2))
    S.write("ballena_lejos.ogg", S.reverb(call, 2.4, 0.6, 900), loop=False)


# ---------------------------------------------------------------------------
# Música (instrumentos de compose.py + tambores propios)
# ---------------------------------------------------------------------------

def kick(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
    t = C._t(0.5)
    sweep = f * (1 + 2.5 * np.exp(-t * 30))
    return np.sin(2 * np.pi * np.cumsum(sweep) / C.SR) * np.exp(-t * 7) * vel * 0.6


def tom(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
    t = C._t(0.9)
    sweep = f * (1 + 0.6 * np.exp(-t * 18))
    body = np.sin(2 * np.pi * np.cumsum(sweep) / C.SR) * np.exp(-t * 4.5)
    skin = C.RNG.normal(0, 1, len(t)) * np.exp(-t * 40) * 0.25
    return (body + skin) * vel * 0.5


def snare(f: float, dur: float, vel: float = 0.6) -> np.ndarray:
    t = C._t(0.3)
    n = C.RNG.normal(0, 1, len(t))
    n = np.convolve(n, np.ones(3) / 3, mode="same")
    return (n * np.exp(-t * 22) * 0.6 + np.sin(2 * np.pi * 190 * t) * np.exp(-t * 30) * 0.4) * vel * 0.35


def hat(f: float, dur: float, vel: float = 0.4) -> np.ndarray:
    t = C._t(0.08)
    n = np.diff(C.RNG.normal(0, 1, len(t) + 1))
    return n * np.exp(-t * 70) * vel * 0.12


def anvil(f: float, dur: float, vel: float = 0.6) -> np.ndarray:
    t = C._t(2.0)
    sig = sum(np.sin(2 * np.pi * f * p * t) * np.exp(-t * (1.5 + 1.2 * p)) / p for p in (1.0, 2.76, 5.4))
    return sig * vel * 0.12


def glass(f: float, dur: float, vel: float = 0.5) -> np.ndarray:
    """Campanita de cristal (para Nácara): parciales suaves que tiemblan un poco."""
    t = C._t(dur + 3.0)
    sig = np.zeros_like(t)
    for ratio, amp, decay in ((1, 1.0, 1.2), (2.01, 0.35, 2.0), (3.98, 0.12, 3.5)):
        sig += amp * np.sin(2 * np.pi * f * ratio * t + 0.002 * np.sin(2 * np.pi * 4.5 * t)) * np.exp(-t * decay)
    sig *= np.minimum(t / 0.006, 1)
    return sig * vel * 0.2


for _name, _fn, _pan in (("kick", kick, 0.0), ("tom", tom, 0.1), ("snare", snare, -0.05), ("hat", hat, 0.3), ("anvil", anvil, -0.35), ("glass", glass, 0.3)):
    C.INSTRUMENTS[_name] = _fn
    C.PAN[_name] = _pan


def finish_music(track, name: str, length: float, wet: float = 0.28, rev: float = 2.4):
    """Como compose.finish (bucle: la cola de la reverberación vuelve al principio), algo más comprimido."""
    buf = C.reverb(track.buf, rev, wet)
    n = int(length * C.SR)
    tail = buf[n:]
    buf = buf[:n].copy()
    k = min(len(tail), n)
    buf[:k] += tail[:k]
    buf *= 0.8 / (np.max(np.abs(buf)) + 1e-9)
    data = buf.astype(np.float32)
    with sf.SoundFile(MUSIC_OUT / name, "w", C.SR, 2, format="OGG", subtype="VORBIS", compression_level=0.8) as out:
        for i in range(0, len(data), C.SR * 4):
            out.write(data[i:i + C.SR * 4])
    print(f"  {name:24s} {length:5.1f} s  {(MUSIC_OUT / name).stat().st_size // 1024:4d} KB")


C.CHORDS.update({
    "Dmaj7": ["D", "F#", "A", "C#"], "E/D": ["D", "E", "G#", "B"], "Gmaj7": ["G", "B", "D", "F#"],
    "Asus": ["A", "D", "E"], "Am9": ["A", "C", "E", "B"], "Fmaj7": ["F", "A", "C", "E"], "C6": ["C", "E", "G", "A"],
    "Gsus": ["G", "C", "D"], "Em7": ["E", "G", "B", "D"], "Dm7": ["D", "F", "A", "C"], "Cmaj7": ["C", "E", "G", "B"],
    "Ab": ["Ab", "C", "Eb"], "C#m": ["C#", "E", "G#"], "Amaj7": ["A", "C#", "E", "G#"], "B": ["B", "D#", "F#"],
})


def chord_notes(chord: str, octave: int) -> list[str]:
    return [f"{n}{octave}" for n in C.CHORDS[chord]]


def espacio_crucero():
    """Crucero tranquilo: colchones largos en re lidio (el «flotar»), bajo muy hondo y estrellas sueltas."""
    seed(701)
    bar = 6.0  # (sin pulso: cada acorde dura 6 s)
    prog = ["Dmaj7", "E/D", "Gmaj7", "Asus", "Dmaj7", "E/D", "Gmaj7", "Dmaj7"]
    length = len(prog) * bar
    tr = C.Track(length)
    stars = ["F#6", "A6", "C#7", "E6", "G#6", "B6", "D7", "A6"]
    for i, ch in enumerate(prog):
        t0 = i * bar
        tr.chord("pad", chord_notes(ch, 3), t0, bar, 0.42)
        tr.note("bass", f"{C.CHORDS[ch][0]}1", t0, bar * 0.9, 0.35)
        for k in range(3):
            if C.RNG.random() < 0.8:
                tr.note("musicbox", stars[(i * 3 + k) % len(stars)], t0 + 0.8 + k * 1.9 + C.RNG.uniform(-0.2, 0.2), 0.3, 0.22)
    finish_music(tr, "espacio_crucero.ogg", length, wet=0.4, rev=3.2)


def espacio_deriva():
    """Deriva: la menor con novena, cuerdas lentas y unas notas de piano con aire (la otra del crucero)."""
    seed(702)
    beat = 60 / 64
    prog = ["Am9", "Fmaj7", "C6", "Gsus", "Am9", "Fmaj7", "Dm7", "Gsus"]
    length = len(prog) * 4 * beat * 2
    tr = C.Track(length)
    line = ["E5", "C5", "G5", "D5", "B4", "A4", "F5", "D5"]
    for i, ch in enumerate(prog):
        t0 = i * 8 * beat
        tr.chord("strings", chord_notes(ch, 3), t0, 8 * beat, 0.3)
        tr.note("bass", f"{C.CHORDS[ch][0]}2", t0, 6 * beat, 0.28)
        tr.note("piano", line[i], t0 + 2 * beat, 2 * beat, 0.3)
        if i % 2 == 1:
            tr.note("piano", line[(i + 3) % len(line)], t0 + 5 * beat, 1.5 * beat, 0.22)
    finish_music(tr, "espacio_deriva.ogg", length, wet=0.38, rev=3.0)


def espacio_combate():
    """Combate: pulso de cuerdas graves en mi menor a 120, bombo y caja, un colchón que aprieta."""
    seed(703)
    beat = 60 / 120
    roots = ["E", "E", "C", "D", "E", "E", "C", "B"]
    length = len(roots) * 4 * beat * 2
    tr = C.Track(length)
    for i, r in enumerate(roots):
        t0 = i * 8 * beat
        for k in range(32):  # semicorcheas
            name = f"{r}2" if k % 4 != 2 else ("B2" if r == "E" else f"{r}3")
            tr.note("strings", name, t0 + k * beat / 4, beat * 0.2, 0.36 if k % 4 == 0 else 0.24)
        for k in range(8):
            tr.note("kick", "E1", t0 + k * beat, 0.3, 0.7 if k % 2 == 0 else 0.45)
            if k % 2 == 1:
                tr.note("snare", "E3", t0 + k * beat, 0.2, 0.5)
            tr.note("hat", "E6", t0 + k * beat + beat / 2, 0.05, 0.4)
        top = ["B3", "F#4"] if i % 2 == 0 else ["C4", "G4"]
        tr.chord("pad", [f"{r}3"] + top, t0, 8 * beat, 0.32)
    finish_music(tr, "espacio_combate.ogg", length, wet=0.22, rev=1.8)


def espacio_estacion():
    """Estación atracada: acordes cálidos con séptima, bajo que camina despacio y un platillo finísimo."""
    seed(704)
    beat = 60 / 84
    prog = ["Fmaj7", "Em7", "Dm7", "Cmaj7", "Fmaj7", "Em7", "Dm7", "Gsus"]
    length = len(prog) * 4 * beat * 2
    tr = C.Track(length)
    for i, ch in enumerate(prog):
        t0 = i * 8 * beat
        for k in (0, 3, 4, 7):
            tr.chord("piano", chord_notes(ch, 4), t0 + k * beat, beat * 1.2, 0.18 if k else 0.24)
        root = C.CHORDS[ch][0]
        fifth = C.CHORDS[ch][2]
        for k, name in enumerate((f"{root}2", f"{fifth}2", f"{root}2", f"{fifth}2")):
            tr.note("bass", name, t0 + k * 2 * beat, beat * 1.6, 0.32)
        for k in range(16):
            tr.note("hat", "E6", t0 + k * beat / 2, 0.05, 0.22 if k % 2 else 0.3)
        tr.chord("pad", chord_notes(ch, 3), t0, 8 * beat, 0.18)
    finish_music(tr, "espacio_estacion.ogg", length, wet=0.3, rev=2.2)


def tefra_guerra():
    """Tefra: tambores de guerra apagados (tom grave), yunque de las fundiciones y un bordón en do con la
    segunda menor encima. Sin melodía: la ciudad aguanta."""
    seed(705)
    beat = 60 / 72
    length = 8 * 4 * beat
    tr = C.Track(length)
    pattern = [(0, 0.8), (1.5, 0.45), (2, 0.65), (3, 0.4), (3.5, 0.5)]
    for bar in range(8):
        t0 = bar * 4 * beat
        for k, v in pattern:
            tr.note("tom", "C2" if k != 3.5 else "G2", t0 + k * beat, 0.4, v)
        if bar % 2 == 1:
            tr.note("anvil", "A4", t0 + 2.5 * beat, 1.0, 0.5)
        if bar % 4 == 0:
            tr.chord("pad", ["C2", "G2", "Db3"], t0, 16 * beat, 0.35)
            tr.note("strings", "C3", t0, 16 * beat, 0.25)
    finish_music(tr, "tefra_guerra.ogg", length, wet=0.3, rev=2.6)


def tefra_refugio():
    """Tefra en calma (refugio, tregua): cuerdas graves, piano lento en do menor que sube a mi bemol."""
    seed(706)
    beat = 60 / 60
    prog = ["Cm", "Ab", "Eb", "Bb", "Cm", "Ab", "Eb", "Eb"]
    length = len(prog) * 6 * beat
    tr = C.Track(length)
    tune = ["G4", "C5", "Bb4", "D5", "Eb5", "C5", "G5", "Eb5"]
    for i, ch in enumerate(prog):
        t0 = i * 6 * beat
        tr.chord("strings", chord_notes(ch, 3), t0, 6 * beat, 0.26)
        tr.note("bass", f"{C.CHORDS[ch][0]}2", t0, 5 * beat, 0.25)
        tr.note("piano", tune[i], t0 + 1.5 * beat, 2.5 * beat, 0.3)
        tr.note("piano", C.CHORDS[ch][1] + "4", t0 + 4 * beat, 1.5 * beat, 0.18)
    finish_music(tr, "tefra_refugio.ogg", length, wet=0.34, rev=2.8)


def nacara():
    """Nácara: arpegios de cristal en mi mayor que suben y bajan, colchón suave y mucha agua (eco)."""
    seed(707)
    beat = 60 / 70
    prog = ["E", "C#m", "Amaj7", "B", "E", "C#m", "Amaj7", "E"]
    length = len(prog) * 4 * beat * 2
    tr = C.Track(length)
    for i, ch in enumerate(prog):
        t0 = i * 8 * beat
        notes = C.CHORDS[ch]
        arp = [f"{notes[0]}5", f"{notes[1]}5", f"{notes[2]}5", f"{notes[0]}6", f"{notes[2]}5", f"{notes[1]}5"]
        for k in range(12):
            tr.note("glass", arp[k % len(arp)], t0 + k * beat * 2 / 3, beat * 0.5, 0.35 if k % 3 == 0 else 0.22)
        tr.chord("pad", chord_notes(ch, 3), t0, 8 * beat, 0.3)
        tr.note("bass", f"{notes[0]}2", t0, 7 * beat, 0.2)
    finish_music(tr, "nacara.ogg", length, wet=0.5, rev=3.6)


AMBIENTES = (amb_espacio, amb_cabina, amb_radio, amb_tefra, amb_fundicion, sirena_tefra, amb_submarino, ballena_lejos)
MUSICA = (espacio_crucero, espacio_deriva, espacio_combate, espacio_estacion, tefra_guerra, tefra_refugio, nacara)

if __name__ == "__main__":
    wanted = {a.removesuffix(".ogg") for a in sys.argv[1:]}
    known = {f.__name__ for f in AMBIENTES + MUSICA}
    unknown = wanted - known
    if unknown:
        sys.exit(f"No conozco: {', '.join(sorted(unknown))}")
    print("Ambientes por zona en audio/sfx")
    for make in AMBIENTES:
        if not wanted or make.__name__ in wanted:
            make()
            path = S.OUT / f"{make.__name__}.ogg"
            print(f"  {path.name:24s} {sf.info(path).duration:5.1f} s  {path.stat().st_size // 1024:4d} KB")
    print("Música por zona en audio/")
    for make in MUSICA:
        if not wanted or make.__name__ in wanted:
            make()
    print("Listo.")
