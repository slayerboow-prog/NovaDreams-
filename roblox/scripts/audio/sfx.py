"""Sintetiza los efectos de sonido del juego y los guarda en roblox/audio/sfx/.

Igual que la música (compose.py): todo sale de código (ruido filtrado, tonos, voces inventadas),
así que los sonidos son 100 % nuestros y se pueden subir a Roblox sin problemas de derechos.

Uso (desde roblox/):   python3 scripts/audio/sfx.py
Necesita:              pip install numpy soundfile

Archivos (mono, 44.1 kHz, ogg vorbis, pico a -3 dBFS):
  motor.ogg        motor en bucle (el juego le sube el tono con la velocidad)     · bucle 2 s
  claxon.ogg       claxon de coche de dos tonos                                  0.6 s
  timbre.ogg       timbre de bici "ring ring"                                    0.8 s
  tele.ogg         tele de fondo: voces bajitas y música                          · bucle 4 s
  multitud.ogg     murmullo de gente                                             · bucle 6 s
  metro_tren.ogg   traqueteo del tren (rumor y clac-clac de las vías)            · bucle 4 s
  metro_freno.ogg  frenazo suave del metro y soplido del aire                     2 s
  metro_anden.ogg  ambiente del andén: rumor lejano y gente                       · bucle 6 s
  lluvia.ogg       lluvia                                                        · bucle 6 s
  trueno.ogg       trueno                                                          4 s
  pajaros.ogg      pájaros (pocos cantos, sueltos)                               · bucle 8 s
  viento.ogg       viento                                                        · bucle 8 s

Los bucles no hacen "clic" al repetirse: el final se funde con el principio.
"""

from pathlib import Path

import numpy as np
import soundfile as sf

SR = 44100
OUT = Path(__file__).resolve().parents[2] / "audio" / "sfx"
PEAK = 10 ** (-3 / 20)  # -3 dBFS
RNG = np.random.default_rng(7)  # semilla fija: siempre salen los mismos sonidos


# ---------------------------------------------------------------------------
# Herramientas
# ---------------------------------------------------------------------------

def n_of(seconds: float) -> int:
    return int(round(seconds * SR))


def t_of(seconds: float) -> np.ndarray:
    return np.arange(n_of(seconds)) / SR


def noise(seconds: float) -> np.ndarray:
    return RNG.normal(0, 1, n_of(seconds))


def lowpass_gain(f: np.ndarray, fc: float, order: int = 2) -> np.ndarray:
    return 1 / np.sqrt(1 + (f / fc) ** (2 * order))


def highpass_gain(f: np.ndarray, fc: float, order: int = 2) -> np.ndarray:
    f = np.maximum(f, 1e-6)
    return 1 / np.sqrt(1 + (fc / f) ** (2 * order))


def spectral(x: np.ndarray, gain, pad: bool = True) -> np.ndarray:
    """Filtra con la FFT. gain(f) da la ganancia para cada frecuencia (Hz).
    pad=False: filtro circular (el final empalma con el principio; bueno para bucles)."""
    n = len(x)
    size = 1 << int(np.ceil(np.log2(n * 2))) if pad else n
    spec = np.fft.rfft(x, size)
    f = np.fft.rfftfreq(size, 1 / SR)
    return np.fft.irfft(spec * gain(f), size)[:n]


def band(x: np.ndarray, lo: float, hi: float, order: int = 2, pad: bool = True) -> np.ndarray:
    return spectral(x, lambda f: highpass_gain(f, lo, order) * lowpass_gain(f, hi, order), pad)


def pink(seconds: float) -> np.ndarray:
    return spectral(noise(seconds), lambda f: 1 / np.sqrt(np.maximum(f, 20)), pad=False)


def brown(seconds: float) -> np.ndarray:
    return spectral(noise(seconds), lambda f: 1 / np.maximum(f, 15), pad=False)


def smooth(x: np.ndarray, seconds: float) -> np.ndarray:
    k = max(1, n_of(seconds))
    return np.convolve(x, np.ones(k) / k, mode="same")


def reverb(x: np.ndarray, seconds: float = 1.2, wet: float = 0.3, bright: float = 5000) -> np.ndarray:
    """Reverberación sencilla: ruido que se apaga (sala), un poco oscurecido."""
    t = t_of(seconds)
    ir = RNG.normal(0, 1, len(t)) * np.exp(-t / (seconds / 5))
    ir = spectral(ir, lambda f: lowpass_gain(f, bright, 1))
    ir /= np.sqrt(np.sum(ir**2))
    size = 1 << int(np.ceil(np.log2(len(x) + len(ir))))
    w = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
    return x * (1 - wet * 0.5) + w * wet


def adsr(n: int, attack: float, release: float) -> np.ndarray:
    env = np.ones(n)
    a, r = min(n, n_of(attack)), min(n, n_of(release))
    if a:
        env[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    if r:
        env[n - r:] *= np.cos(np.linspace(0, np.pi / 2, r)) ** 2
    return env


def add_at(buf: np.ndarray, sig: np.ndarray, start: float, wrap: bool = False):
    """Suma sig en buf desde start (s). wrap=True: lo que sobra al final vuelve al principio (bucles)."""
    i = n_of(start) % len(buf) if wrap else n_of(start)
    idx = np.arange(i, i + len(sig))
    if wrap:
        np.add.at(buf, idx % len(buf), sig)
    else:
        keep = idx < len(buf)
        buf[idx[keep]] += sig[keep]


def make_loop(sig: np.ndarray, length: float, fade: float) -> np.ndarray:
    """sig dura length + fade. El trozo final (fade) se funde con el principio: el bucle empalma sin clic
    (la última muestra del bucle va seguida de la que la seguía en la señal original)."""
    n, f = n_of(length), n_of(fade)
    out = sig[:n].copy()
    tail = sig[n:n + f]
    w = np.linspace(0, np.pi / 2, f)
    out[:f] = out[:f] * np.sin(w) + tail * np.cos(w)  # potencia constante (ruido sin bajón)
    return out


def write(name: str, sig: np.ndarray, loop: bool):
    sig = sig - np.mean(sig) if loop else sig
    if not loop:
        # entrada y salida suaves (sin clic)
        sig = sig * adsr(len(sig), 0.002, 0.03)
    sig = sig * (PEAK / (np.max(np.abs(sig)) + 1e-12))
    OUT.mkdir(parents=True, exist_ok=True)
    sf.write(OUT / name, sig.astype(np.float32), SR, format="OGG", subtype="VORBIS", compression_level=0.55)


# ---------------------------------------------------------------------------
# Voces inventadas (murmullo sin palabras: vocales con formantes, como gente hablando lejos)
# ---------------------------------------------------------------------------

VOWELS = [  # formantes (Hz) de a, e, i, o, u
    (800, 1200, 2500),
    (450, 1900, 2500),
    (300, 2200, 3000),
    (500, 900, 2400),
    (330, 750, 2400),
]


def voice(seconds: float, f0: float, talk: float = 0.7, bright: float = 3200) -> np.ndarray:
    """Una persona hablando bajito (sin palabras). talk = parte del tiempo que habla (0..1)."""
    n = n_of(seconds)
    env = np.zeros(n)
    pitch = np.full(n, f0)
    formants = np.zeros((3, n))
    scale = 1.12 if f0 > 160 else 1.0
    t = RNG.uniform(0, 0.6)
    last = RNG.integers(len(VOWELS))
    for i in range(3):
        formants[i, :] = VOWELS[last][i] * scale
    while t < seconds:
        # una frase: unas cuantas sílabas seguidas y luego una pausa
        syllables = RNG.integers(3, 9)
        rise = RNG.uniform(-0.12, 0.12)
        for s in range(syllables):
            d = RNG.uniform(0.11, 0.24)
            a, b = n_of(t), min(n, n_of(t + d))
            if a >= n:
                break
            m = b - a
            env[a:b] = np.maximum(env[a:b], np.sin(np.linspace(0, np.pi, m)) ** 0.7 * RNG.uniform(0.6, 1))
            last = RNG.integers(len(VOWELS))
            for i in range(3):
                formants[i, a:] = VOWELS[last][i] * scale * RNG.uniform(0.93, 1.07)
            # la entonación baja un poco al final de la frase
            pitch[a:b] = f0 * (1 + rise * s / syllables - 0.08 * (s == syllables - 1)) * RNG.uniform(0.95, 1.05)
            t += d
        t += RNG.uniform(0.2, 1.2) / max(talk, 0.05) * (1 - talk + 0.15)
    pitch = smooth(pitch, 0.05)
    env = smooth(env, 0.015)
    formants = np.array([smooth(formants[i], 0.04) for i in range(3)])
    out = np.zeros(n)
    phase0 = 2 * np.pi * np.cumsum(pitch) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.1 * np.arange(n) / SR)
    for k in range(1, int(bright / (f0 * 0.85)) + 1):
        h = k * pitch
        g = 1.0 / (1 + ((h - formants[0]) / 90) ** 2)
        g += 0.55 / (1 + ((h - formants[1]) / 130) ** 2)
        g += 0.2 / (1 + ((h - formants[2]) / 200) ** 2)
        g *= (h < bright) / k**0.6
        out += g * np.sin(k * phase0 * vib)
    return out * env


def crowd(seconds: float, people: int, bright: float) -> np.ndarray:
    buf = np.zeros(n_of(seconds))
    for _ in range(people):
        f0 = RNG.uniform(95, 135) if RNG.random() < 0.5 else RNG.uniform(175, 235)
        v = voice(seconds, f0, talk=RNG.uniform(0.5, 0.85), bright=bright)
        buf += v / (np.sqrt(np.mean(v**2)) + 1e-9) * RNG.uniform(0.3, 1.0)
    return buf


# ---------------------------------------------------------------------------
# Efectos
# ---------------------------------------------------------------------------

def motor():
    # Bucle de 2 s: todas las frecuencias dan un número entero de vueltas en 2 s (empalma perfecto)
    length, fade = 2.0, 0.25
    t = t_of(length + fade)
    f0 = 44.0  # zumbido grave (el juego sube el tono al acelerar)
    wobble = 1 + 0.12 * np.sin(2 * np.pi * 1.5 * t) + 0.06 * np.sin(2 * np.pi * 4.0 * t + 1)
    sig = np.zeros(len(t))
    for k in range(1, 16):
        amp = 1 / k**1.1 * (1.4 if k in (2, 4) else 1)  # un motor de 4 tiempos: pares más fuertes
        sig += amp * np.sin(2 * np.pi * f0 * k * t + RNG.uniform(0, 2 * np.pi))
    sig *= wobble
    # un poco de "aire" grave (ruido suave), como el escape
    sig += 0.35 * band(noise(length + fade), 60, 500, pad=False) * wobble / 3
    sig = np.tanh(sig * 0.8)  # algo de saturación: suena más a motor, menos a órgano
    sig = spectral(sig, lambda f: lowpass_gain(f, 900, 2), pad=False)
    write("motor.ogg", make_loop(sig, length, fade), loop=True)


def claxon():
    # Dos tonos a la vez (como un claxon de coche normal), un pelín nasal pero no chillón
    t = t_of(0.6)
    sig = np.zeros(len(t))
    for f0 in (392.0, 494.0):  # sol y si: intervalo de tercera, suena "amable"
        for k in range(1, 12):
            if f0 * k > 5000:
                break
            sig += np.sin(2 * np.pi * f0 * k * t * (1 + 0.002 * np.sin(2 * np.pi * 6 * t))) / k
    sig = spectral(sig, lambda f: highpass_gain(f, 250) * lowpass_gain(f, 2600, 2) * (1 + 1.5 / (1 + ((f - 1100) / 400) ** 2)))
    sig = np.tanh(sig / np.max(np.abs(sig)) * 1.2)  # (saturación ligera: timbre de bocina)
    write("claxon.ogg", sig * adsr(len(t), 0.015, 0.08), loop=False)


def bell_strike(seconds: float, f0: float) -> np.ndarray:
    t = t_of(seconds)
    sig = np.zeros(len(t))
    # parciales de una campanita metálica (no armónicos) y cada uno se apaga a su ritmo
    for ratio, amp, decay in ((1.0, 1.0, 0.45), (1.004, 0.6, 0.5), (2.32, 0.45, 0.22), (3.1, 0.25, 0.14), (4.4, 0.12, 0.08)):
        sig += amp * np.sin(2 * np.pi * f0 * ratio * t + RNG.uniform(0, 6)) * np.exp(-t / decay)
    click = band(noise(0.01), 3000, 9000) * np.exp(-np.arange(n_of(0.01)) / (0.002 * SR)) * 0.3
    sig[: len(click)] += click
    return sig


def timbre():
    buf = np.zeros(n_of(0.8))
    add_at(buf, bell_strike(0.8, 2100), 0.0)
    add_at(buf, bell_strike(0.6, 2100) * 0.8, 0.22)  # "ring ring"
    write("timbre.ogg", buf * adsr(len(buf), 0.001, 0.12), loop=False)


def tele():
    length, fade = 4.0, 0.4
    total = length + fade
    t = t_of(total)
    # voces (dos personas hablando en la tele), con sonido de altavoz pequeño
    talk = voice(total, 118, talk=0.8, bright=3500) + 0.8 * voice(total, 205, talk=0.7, bright=3500)
    talk /= np.sqrt(np.mean(talk**2)) + 1e-9
    # música suave de fondo: dos acordes (do - la menor), notas largas con ataque suave
    music = np.zeros(len(t))
    chords = [(261.63, 329.63, 392.0), (220.0, 261.63, 329.63)]
    for c, chord in enumerate(chords + chords[:1]):
        start = c * 2.0
        seg = t_of(2.2)
        for f in chord:
            tone = np.sin(2 * np.pi * f * seg) + 0.3 * np.sin(4 * np.pi * f * seg)
            add_at(music, tone * adsr(len(seg), 0.3, 0.6) * 0.33, start)
    music /= np.sqrt(np.mean(music**2)) + 1e-9
    sig = talk + 0.45 * music + 0.05 * pink(total) / 30
    sig = spectral(sig, lambda f: highpass_gain(f, 220, 2) * lowpass_gain(f, 3800, 2))  # altavoz de tele
    sig = reverb(sig, 0.5, 0.2)  # (una salita)
    write("tele.ogg", make_loop(sig, length, fade), loop=True)


def multitud():
    length, fade, pre = 6.0, 0.8, 0.8
    total = pre + length + fade
    sig = crowd(total, 14, bright=3000)
    sig /= np.sqrt(np.mean(sig**2)) + 1e-9
    sig += 0.25 * band(pink(total), 150, 2500) / (np.std(band(pink(total), 150, 2500)) + 1e-9)
    sig = spectral(sig, lambda f: highpass_gain(f, 120) * lowpass_gain(f, 2600, 2))  # lejos: sin agudos
    sig = reverb(sig, 1.4, 0.4, bright=3000)
    write("multitud.ogg", make_loop(sig[n_of(pre):], length, fade), loop=True)


def clack(strength: float) -> np.ndarray:
    t = t_of(0.12)
    hit = band(noise(0.12), 150, 1800) * np.exp(-t / 0.018)
    thump = np.sin(2 * np.pi * 75 * t) * np.exp(-t / 0.04)
    return (0.5 * hit / (np.max(np.abs(hit)) + 1e-9) + thump) * strength


def metro_tren():
    length, fade = 4.0, 0.3
    total = length + fade
    t = t_of(total)
    rumble = band(brown(total), 25, 260, pad=False)
    rumble /= np.std(rumble) + 1e-9
    hum = sum(np.sin(2 * np.pi * 60 * k * t) / k for k in (1, 2, 3))  # motor eléctrico (grave)
    swell = 1 + 0.15 * np.sin(2 * np.pi * 0.5 * t)
    whine = 0.04 * np.sin(2 * np.pi * 740 * t) * (1 + 0.3 * np.sin(2 * np.pi * 0.25 * t))  # rueda en la vía, muy bajito
    air = band(pink(total), 300, 3000, pad=False)
    air /= np.std(air) + 1e-9
    sig = rumble * swell + 0.25 * hum + whine + 0.15 * air
    clacks = np.zeros(n_of(length))
    # clac-clac (las dos ruedas del bogie pasando por la junta del raíl), dos veces por bucle
    for start in (0.3, 2.3):
        add_at(clacks, clack(1.0), start, wrap=True)
        add_at(clacks, clack(0.8), start + 0.14, wrap=True)
        add_at(clacks, clack(0.55), start + 0.95, wrap=True)
        add_at(clacks, clack(0.45), start + 1.09, wrap=True)
    clacks = np.concatenate([clacks, clacks[: n_of(fade)]])  # (el bucle de clacs ya es periódico)
    sig = sig / (np.std(sig) + 1e-9) + 2.2 * clacks
    sig = spectral(sig, lambda f: lowpass_gain(f, 2500, 2))
    write("metro_tren.ogg", make_loop(sig, length, fade), loop=True)


def metro_freno():
    total = 2.0
    t = t_of(total)
    # chirrido suave de los frenos: sube despacio, baja un poco de tono y se apaga
    f = 1650 * (1 - 0.06 * t / total) * (1 + 0.004 * np.sin(2 * np.pi * 7 * t))
    phase = 2 * np.pi * np.cumsum(f) / SR
    squeal = np.sin(phase) + 0.25 * np.sin(2 * phase) + 0.1 * np.sin(3 * phase)
    squeal_env = np.clip(t / 0.35, 0, 1) ** 2 * np.clip((1.35 - t) / 0.35, 0, 1)
    squeal *= squeal_env * (0.8 + 0.2 * np.sin(2 * np.pi * 3.3 * t))
    # rozamiento (grave) mientras frena
    rub = band(noise(total), 80, 900) * np.clip((1.3 - t) / 1.3, 0, 1)
    rub /= np.std(rub) + 1e-9
    # "psshh" del aire al final (se suelta la presión)
    hiss = band(noise(total), 2500, 9000) * np.clip((t - 1.05) / 0.08, 0, 1) * np.exp(-np.maximum(t - 1.1, 0) / 0.35)
    hiss /= np.max(np.abs(hiss)) + 1e-9
    sig = 0.45 * squeal + 0.25 * rub + 0.5 * hiss
    write("metro_freno.ogg", sig, loop=False)


def metro_anden():
    length, fade, pre = 6.0, 0.8, 1.0
    total = pre + length + fade
    t = t_of(total)
    rumble = band(brown(total), 20, 140)
    rumble /= np.std(rumble) + 1e-9
    rumble *= 1 + 0.35 * np.sin(2 * np.pi * t / 6.0)  # un tren lejos que va y viene
    people = crowd(total, 6, bright=2200)
    people /= np.std(people) + 1e-9
    air = band(pink(total), 200, 2000)
    air /= np.std(air) + 1e-9
    sig = 0.9 * rumble + 0.55 * people + 0.2 * air
    sig = reverb(sig, 2.2, 0.55, bright=2500)  # túnel grande: mucho eco
    sig = spectral(sig, lambda f: lowpass_gain(f, 2400, 2))
    write("metro_anden.ogg", make_loop(sig[n_of(pre):], length, fade), loop=True)


def drop_sound(big: bool) -> np.ndarray:
    if big:
        # gota que cae en un charco: tono corto que sube (burbujita)
        d = RNG.uniform(0.02, 0.05)
        t = t_of(d)
        f = RNG.uniform(1200, 3200) * (1 + 1.5 * t / d)
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (d / 4))
    t = t_of(0.012)
    return band(RNG.normal(0, 1, len(t)), 1500, 9000) * np.exp(-t / 0.002)


def lluvia():
    length, fade = 6.0, 0.6
    total = length + fade
    bed = band(pink(total), 400, 9000, pad=False)
    bed /= np.std(bed) + 1e-9
    drops = np.zeros(n_of(total))
    for _ in range(int(total * 260)):  # muchas gotitas
        add_at(drops, drop_sound(False) * RNG.uniform(0.2, 1), RNG.uniform(0, total))
    for _ in range(int(total * 12)):  # alguna gota más gorda
        add_at(drops, drop_sound(True) * RNG.uniform(0.3, 1), RNG.uniform(0, total))
    drops /= np.std(drops) + 1e-9
    sig = bed + 0.5 * drops
    sig = spectral(sig, lambda f: lowpass_gain(f, 5000, 2) * highpass_gain(f, 200))  # nada de siseo agudo
    write("lluvia.ogg", make_loop(sig, length, fade), loop=True)


def trueno():
    total = 4.0
    t = t_of(total)
    # estallido inicial (suave) y luego el retumbar, que va y viene hasta apagarse
    crack = band(noise(total), 150, 4000) * np.exp(-t / 0.08) * np.clip(t / 0.01, 0, 1)
    crack /= np.max(np.abs(crack)) + 1e-9
    rumble = band(brown(total), 25, 220)
    rumble /= np.std(rumble) + 1e-9
    rolls = np.zeros(len(t))
    for start, amp, width in ((0.05, 1.0, 0.5), (0.7, 0.8, 0.6), (1.4, 0.6, 0.7), (2.1, 0.45, 0.9)):
        rolls += amp * np.exp(-(((t - start - width / 2) / (width / 2)) ** 2))
    env = rolls * np.exp(-t / 1.6) + 0.15 * np.exp(-t / 1.2)
    sig = 0.35 * crack + rumble * env
    sig = spectral(sig, lambda f: lowpass_gain(f, 1500, 2))
    sig *= adsr(len(t), 0.005, 0.6)
    write("trueno.ogg", sig, loop=False)


def chirp(kind: int) -> np.ndarray:
    if kind == 0:  # "tuit": sube rápido
        d = RNG.uniform(0.06, 0.1)
        t = t_of(d)
        f = 3000 + 1800 * (t / d) ** 1.5
    elif kind == 1:  # "tiu": baja
        d = RNG.uniform(0.1, 0.16)
        t = t_of(d)
        f = 4600 - 1700 * (t / d)
    else:  # trino: tono con vibrato rápido
        d = RNG.uniform(0.15, 0.25)
        t = t_of(d)
        f = 3600 + 400 * np.sin(2 * np.pi * 28 * t)
    f = f * RNG.uniform(0.9, 1.1)
    env = np.sin(np.pi * t / d) ** 2
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env


def pajaros():
    length, fade = 8.0, 0.6
    buf = np.zeros(n_of(length))
    # pocas frases: 2 o 3 pájaros, cada uno a su distancia (más o menos fuerte)
    phrases = [(0.4, 0, 1.0), (1.9, 2, 0.45), (3.3, 1, 0.8), (5.0, 0, 0.55), (6.4, 1, 0.35), (7.2, 2, 0.6)]
    for start, kind, amp in phrases:
        at = start
        for _ in range(RNG.integers(2, 5)):
            c = chirp(kind) * amp
            add_at(buf, c, at, wrap=True)
            at += len(c) / SR + RNG.uniform(0.05, 0.12)
    buf = reverb(np.concatenate([buf, buf]), 0.8, 0.3)[n_of(length):]  # eco de parque (dos vueltas: sin corte)
    air = band(pink(length + fade), 300, 4000, pad=False)
    air = air / (np.std(air) + 1e-9) * 0.01  # hojas y aire, casi nada
    buf = np.concatenate([buf, buf[: n_of(fade)]]) + air
    write("pajaros.ogg", make_loop(buf, length, fade), loop=True)


def viento():
    length, fade = 8.0, 0.8
    total = length + fade
    t = t_of(total)
    base = noise(total)
    # rachas: ondas lentas que dan vueltas enteras en 8 s (el bucle empalma solo)
    gust = 0.55 + 0.25 * np.sin(2 * np.pi * t / 8 + 0.3) + 0.15 * np.sin(2 * np.pi * 3 * t / 8 + 2) + 0.08 * np.sin(2 * np.pi * 5 * t / 8)
    # el "silbido" del viento cambia de tono con las rachas: mezcla de bandas
    low = band(base, 60, 400, pad=False)
    mid = band(base, 300, 900, pad=False)
    high = spectral(base, lambda f: 1 / (1 + ((f - 700) / 60) ** 2) + 0.6 / (1 + ((f - 1050) / 80) ** 2), pad=False)
    low, mid, high = (x / (np.std(x) + 1e-9) for x in (low, mid, high))
    g = (gust - gust.min()) / (gust.max() - gust.min())
    sig = low * (0.6 + 0.4 * g) + mid * 0.5 * g + high * 0.25 * g**2
    sig *= gust
    write("viento.ogg", make_loop(sig, length, fade), loop=True)


# ---------------------------------------------------------------------------
# Comprobación (no se puede escuchar aquí, así que se miran los números)
# ---------------------------------------------------------------------------

LOOPS = {"motor", "tele", "multitud", "metro_tren", "metro_anden", "lluvia", "pajaros", "viento"}


def check():
    print(f"\n{'archivo':18s} {'dur':>5s} {'pico':>7s} {'RMS':>7s} {'KB':>5s}  empalme")
    for path in sorted(OUT.glob("*.ogg")):
        x, sr = sf.read(path, dtype="float64")
        peak = 20 * np.log10(np.max(np.abs(x)) + 1e-12)
        rms = 20 * np.log10(np.sqrt(np.mean(x**2)) + 1e-12)
        seam = ""
        if path.stem in LOOPS:
            # el salto del final al principio comparado con los saltos normales entre muestras
            jump = abs(x[0] - x[-1])
            typical = np.percentile(np.abs(np.diff(x)), 99)
            w = n_of(0.05)
            ends = 20 * np.log10((np.sqrt(np.mean(x[-w:] ** 2)) + 1e-12) / (np.sqrt(np.mean(x[:w] ** 2)) + 1e-12))
            ok = jump <= typical * 1.5
            seam = f"salto {jump:.4f} (p99 {typical:.4f}) nivel fin/inicio {ends:+.1f} dB {'OK' if ok else 'REVISAR'}"
        print(f"{path.name:18s} {len(x) / sr:5.2f} {peak:6.1f}  {rms:6.1f}  {path.stat().st_size / 1024:5.0f}  {seam}")


if __name__ == "__main__":
    print(f"Sintetizando efectos en {OUT}")
    for make in (motor, claxon, timbre, tele, multitud, metro_tren, metro_freno, metro_anden, lluvia, trueno, pajaros, viento):
        make()
        print(f"  {make.__name__}")
    check()
