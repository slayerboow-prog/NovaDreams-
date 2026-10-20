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
  choque_leve.ogg  choque de coche flojo: "tunk" de chapa y algún trasto que suena  0.45 s
  choque_fuerte.ogg choque fuerte: crujido de chapa, traqueteo y cristalitos          0.9 s
  golpe_caida.ogg  caer al suelo desde alto: "pof" corto del cuerpo                0.26 s
  golpe_choque.ogg chocar corriendo con una pared / puñetazo: "tuc" seco          0.2 s
  disparo_pistola.ogg / _revolver / _escopeta / _subfusil / _fusil: disparos (chasquido + estampido
                   + cuerpo del arma + sala corta), cada uno con su carácter        0.28-0.85 s
  disparo_eco.ogg  eco del disparo rebotando en los edificios (apagado)            1.1 s

Ambiente por tipo de lugar (StoryAudio: Config.Audio.Ambience; nunca silencio absoluto):
  amb_sala.ogg     aire de una sala cerrada: climatizador y zumbido muy flojo     · bucle 8 s
  amb_casa.ogg     casa: nevera, la calle lejos por la ventana, algún crujido     · bucle 10 s
  amb_colegio.ogg  colegio: niños en el pasillo o el patio, pasos, alguna puerta  · bucle 10 s
  amb_universidad.ogg universidad: estudiantes, pasos en un vestíbulo grande, la máquina expendedora · bucle 10 s
  amb_hospital.ogg hospital: ventilación, murmullo bajo, ruedas de camilla lejos  · bucle 10 s
  amb_calle.ogg    calle: tráfico lejano que va y viene y gente a lo lejos         · bucle 10 s
  (Los ambientes llevan su propia semilla: se pueden rehacer solos sin cambiar los demás.)

Solo algunos:          python3 scripts/audio/sfx.py choque_leve choque_fuerte
Golpes y disparos: sin subgraves (corte fuerte por debajo de 75-140 Hz) y colas cortas.

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
# Golpes, choques y disparos
# Cada uno lleva su propia semilla (rng): así se pueden rehacer solos sin cambiar los demás.
# Nada de "bum" grave: se quita todo lo que está por debajo de ~70-90 Hz y las colas son cortas.
# ---------------------------------------------------------------------------

def rnoise(rng: np.random.Generator, seconds: float) -> np.ndarray:
    return rng.normal(0, 1, n_of(seconds))


def decay(seconds: float, tau: float, attack: float = 0.0008) -> np.ndarray:
    """Envolvente de golpe: sube en attack (s) y se apaga con constante tau (s)."""
    t = t_of(seconds)
    return np.exp(-t / tau) * np.clip(t / max(attack, 1e-6), 0, 1)


def modes(rng: np.random.Generator, seconds: float, parts) -> np.ndarray:
    """Resonancias (chapa, cristal, madera): parts = [(Hz, amplitud, tau)]. Cada una desafinada un pelín."""
    t = t_of(seconds)
    sig = np.zeros(len(t))
    for f, amp, tau in parts:
        f *= rng.uniform(0.97, 1.03)
        sig += amp * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi)) * np.exp(-t / tau)
    return sig


def unit(x: np.ndarray) -> np.ndarray:
    return x / (np.max(np.abs(x)) + 1e-12)


def room(rng: np.random.Generator, x: np.ndarray, seconds: float, wet: float, bright: float) -> np.ndarray:
    """Sala pequeña (como reverb() pero con su semilla): unas pocas reflexiones que se apagan rápido."""
    t = t_of(seconds)
    ir = rng.normal(0, 1, len(t)) * np.exp(-t / (seconds / 5))
    ir = spectral(ir, lambda f: lowpass_gain(f, bright, 1) * highpass_gain(f, 150, 1))
    ir /= np.sqrt(np.sum(ir**2))
    size = 1 << int(np.ceil(np.log2(len(x) + len(ir))))
    w = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
    return x * (1 - wet * 0.5) + w * wet * np.max(np.abs(x)) / (np.max(np.abs(w)) + 1e-12)


def no_boom(x: np.ndarray, fc: float) -> np.ndarray:
    """Quita los graves de debajo de fc (el "bum" de bomba) con un corte fuerte."""
    return spectral(x, lambda f: highpass_gain(f, fc, 4))


def debris(rng: np.random.Generator, seconds: float, count: int, start: float, spread: float, lo: float, hi: float) -> np.ndarray:
    """Trozos de plástico / tornillos que traquetean: clics cortos cada vez más flojos y separados."""
    buf = np.zeros(n_of(seconds))
    at = start
    for i in range(count):
        d = rng.uniform(0.004, 0.012)
        click = band(rnoise(rng, d + 0.01), lo, hi) * decay(d + 0.01, d / 3)
        click += modes(rng, d + 0.01, [(rng.uniform(lo, hi), 0.5 * np.std(click) * 3, d / 2)])
        add_at(buf, unit(click) * (1 - i / count) ** 1.5 * rng.uniform(0.4, 1), at)
        at += rng.exponential(spread) * (1 + i / count)
        if at > seconds - 0.02:
            break
    return buf


def glass(rng: np.random.Generator, seconds: float, count: int, start: float) -> np.ndarray:
    """Cristalitos que caen: "tintineos" agudos, flojos y cortos (nada de estruendo)."""
    buf = np.zeros(n_of(seconds))
    for i in range(count):
        at = start + rng.uniform(0, seconds - start - 0.1) * (i / count) ** 0.7
        f = rng.uniform(3200, 7500)
        d = rng.uniform(0.05, 0.14)
        ping = modes(rng, d, [(f, 1.0, d / 4), (f * 1.52, 0.5, d / 6), (f * 2.31, 0.25, d / 8)])
        ping[: n_of(0.002)] += rnoise(rng, 0.002) * 0.4
        add_at(buf, ping * rng.uniform(0.3, 1) * (1 - 0.6 * i / count), at)
    return buf


def choque(strong: bool):
    rng = np.random.default_rng(1101 if strong else 1102)
    total = 0.9 if strong else 0.45
    n = n_of(total)
    # 1) el golpe seco del parachoques (medio-grave, muy corto: "tunk", no "bum")
    thump = band(rnoise(rng, total), 110, 900) * decay(total, 0.035 if strong else 0.025)
    thump += 0.6 * modes(rng, total, [(150, 1, 0.03), (230, 0.6, 0.025)])
    # 2) la chapa: resonancias metálicas que se apagan enseguida
    metal = modes(rng, total, [(420, 1.0, 0.09), (780, 0.8, 0.07), (1330, 0.6, 0.05), (2080, 0.45, 0.035), (3150, 0.3, 0.025)])
    metal *= 1 if strong else 0.6
    # 3) el crujido: ráfaga de micro-golpes (la chapa que se arruga), solo en el fuerte suena largo
    crunch_len = 0.16 if strong else 0.05
    grains = (rng.random(n) < (0.03 if strong else 0.015)).astype(float) * rng.uniform(0.3, 1, n)
    grains = band(grains + 0.15 * rnoise(rng, total), 500, 6000) * decay(total, crunch_len / 2.5)
    sig = unit(thump) * (0.8 if strong else 0.9) + unit(metal) * (0.8 if strong else 0.6) + unit(grains) * (1.0 if strong else 0.5)
    # 4) traqueteo de trozos sueltos y (el fuerte) cristalitos
    sig += debris(rng, total, 14 if strong else 5, 0.06, 0.035, 1500, 6000) * (0.22 if strong else 0.14)
    if strong:
        sig += glass(rng, total, 16, 0.07) * 0.16
    sig = np.tanh(unit(sig) * 1.6)  # algo de saturación: suena más "de verdad"
    sig = no_boom(sig, 90)
    sig = spectral(sig, lambda f: lowpass_gain(f, 11000, 2))
    sig = room(rng, sig, 0.25, 0.12, 5000)
    sig *= adsr(n, 0.0005, total * 0.35)
    write("choque_fuerte.ogg" if strong else "choque_leve.ogg", sig, loop=False)


def choque_leve():
    choque(False)


def choque_fuerte():
    choque(True)


def golpe_caida():
    # El cuerpo que cae al suelo: "pof" corto y apagado (ropa + cuerpo), con un roce de zapatilla
    rng = np.random.default_rng(1201)
    total = 0.26
    body = band(rnoise(rng, total), 80, 700) * decay(total, 0.032, 0.002)
    body += 0.8 * modes(rng, total, [(115, 1, 0.035), (190, 0.6, 0.03), (310, 0.35, 0.02)])
    scuff = band(rnoise(rng, total), 1200, 4500) * decay(total, 0.012, 0.001) * 0.25
    step = np.zeros(n_of(total))
    add_at(step, band(rnoise(rng, 0.05), 300, 2500) * decay(0.05, 0.01) * 0.3, 0.035)  # el segundo pie
    sig = unit(body) + unit(scuff) * 0.3 + unit(step + 1e-12) * 0.25
    sig = np.tanh(unit(sig) * 1.3)
    sig = no_boom(sig, 75)
    sig = spectral(sig, lambda f: lowpass_gain(f, 5000, 2))
    write("golpe_caida.ogg", sig * adsr(len(sig), 0.0005, 0.08), loop=False)


def golpe_choque():
    # Chocar corriendo con una pared (y los puñetazos): "tuc" más ligero y seco
    rng = np.random.default_rng(1202)
    total = 0.2
    body = band(rnoise(rng, total), 180, 2200) * decay(total, 0.022, 0.001)
    body += 0.7 * modes(rng, total, [(260, 1, 0.03), (520, 0.5, 0.02), (880, 0.25, 0.012)])
    slap = band(rnoise(rng, total), 1500, 6000) * decay(total, 0.006, 0.0005) * 0.5
    sig = np.tanh(unit(unit(body) + unit(slap) * 0.35) * 1.4)
    sig = no_boom(sig, 110)
    sig = spectral(sig, lambda f: lowpass_gain(f, 7000, 2))
    write("golpe_choque.ogg", sig * adsr(len(sig), 0.0005, 0.06), loop=False)


def gunshot(name: str, seed: int, total: float, crack: float, blast_tau: float, lo: float, hi: float,
            body: list, tail: float, tail_wet: float, low_cut: float, drive: float, supersonic: bool = False):
    """Un disparo: chasquido (onda en N, muy agudo) + estampido (ruido que se apaga en decenas de ms)
    + cuerpo del arma (resonancias) + reflexiones cortas. Nada de subgraves."""
    rng = np.random.default_rng(seed)
    n = n_of(total)
    sig = np.zeros(n)
    # chasquido: una onda en N de pocos cientos de microsegundos (lo que da el "crack")
    w = max(4, n_of(crack))
    nwave = np.linspace(1, -1, w)
    sig[:w] += nwave * 1.2
    if supersonic:  # la bala que rompe la barrera del sonido: un segundo chasquido seco justo antes
        sig[:w // 2] += np.linspace(0.8, -0.8, w // 2)
    # estampido: ruido con la envolvente del gas saliendo del cañón
    blast = band(rnoise(rng, total), lo, hi) * decay(total, blast_tau, 0.0003)
    blast += 0.12 * band(rnoise(rng, total), hi * 0.6, 12000) * decay(total, blast_tau / 4, 0.0002)
    # el "pum" del gas: medios (200-1200 Hz), que es lo que da peso al disparo sin ser un bombazo
    thud = band(rnoise(rng, total), max(lo, 180), 1200) * decay(total, blast_tau * 1.4, 0.0006)
    sig += unit(blast) * 0.8 + unit(thud) * 0.9
    # cuerpo (corredera, cañón, cartucho)
    sig += unit(modes(rng, total, body)) * 0.35
    sig = np.tanh(unit(sig) * drive)
    sig = no_boom(sig, low_cut)
    sig = spectral(sig, lambda f: lowpass_gain(f, 13000, 2))
    # las paredes de alrededor (el eco largo lo pone EcoDisparo aparte)
    sig = room(rng, sig, tail, tail_wet, 4000)
    sig *= adsr(n, 0.0002, total * 0.4)
    write(name, sig, loop=False)


def disparo_pistola():
    gunshot("disparo_pistola.ogg", 1301, 0.45, 0.0004, 0.022, 250, 7000,
            [(1100, 1, 0.012), (2300, 0.6, 0.008), (3700, 0.3, 0.006)], 0.35, 0.22, 110, 2.2)


def disparo_revolver():
    # más grave y "gordo" que la pistola, con más cola
    gunshot("disparo_revolver.ogg", 1302, 0.65, 0.0006, 0.04, 160, 5500,
            [(620, 1, 0.02), (1450, 0.6, 0.014), (2900, 0.3, 0.008)], 0.55, 0.3, 90, 2.6)


def disparo_escopeta():
    # estampido ancho y largo (muchos perdigones y mucha pólvora), pero sin bajo retumbante
    gunshot("disparo_escopeta.ogg", 1303, 0.85, 0.0008, 0.07, 110, 4200,
            [(380, 1, 0.03), (900, 0.7, 0.02), (1900, 0.35, 0.012)], 0.7, 0.35, 80, 3.0)


def disparo_subfusil():
    # corto y seco (dispara en ráfaga: cada tiro tiene que acabar antes del siguiente)
    gunshot("disparo_subfusil.ogg", 1304, 0.28, 0.0003, 0.013, 350, 8000,
            [(1500, 1, 0.008), (3100, 0.5, 0.006)], 0.2, 0.15, 140, 2.0)


def disparo_fusil():
    # chasquido supersónico muy agudo y estampido medio (también vale para el francotirador, más lento)
    gunshot("disparo_fusil.ogg", 1305, 0.7, 0.0003, 0.03, 220, 9000,
            [(800, 1, 0.015), (1900, 0.6, 0.01), (4200, 0.3, 0.006)], 0.6, 0.3, 100, 2.8, supersonic=True)


def disparo_eco():
    # Eco del disparo (lo que se oye rebotar en los edificios): difuso, apagado y que se va
    rng = np.random.default_rng(1306)
    total = 1.1
    t = t_of(total)
    sig = np.zeros(n_of(total))
    # unas cuantas reflexiones (cada vez más flojas y más apagadas) sobre un fondo difuso
    for i, at in enumerate(np.sort(rng.uniform(0.0, 0.5, 9))):
        hit = band(rnoise(rng, 0.25), 200, 3000 - i * 220) * decay(0.25, 0.05, 0.004)
        add_at(sig, unit(hit) * (0.9 ** i) * rng.uniform(0.5, 1), at)
    diffuse = band(rnoise(rng, total), 180, 1800) * np.exp(-t / 0.28) * np.clip(t / 0.05, 0, 1)
    sig = unit(sig) * 0.6 + unit(diffuse) * 0.8
    sig = no_boom(sig, 120)
    sig *= adsr(len(sig), 0.01, 0.35)
    write("disparo_eco.ogg", sig, loop=False)


# ---------------------------------------------------------------------------
# Ambiente por tipo de lugar (bucles largos y flojos: el juego los pone muy bajos, por capas)
# Cada uno reinicia la semilla: se pueden rehacer solos sin cambiar los demás.
# ---------------------------------------------------------------------------

def _seed(n: int):
    global RNG
    RNG = np.random.default_rng(n)


def unit_rms(x: np.ndarray) -> np.ndarray:
    return x / (np.sqrt(np.mean(x**2)) + 1e-9)


def hum(seconds: float, f0: float, parts: int = 6, wobble: float = 0.0) -> np.ndarray:
    """Zumbido eléctrico (nevera, climatizador, máquina): f0 y sus armónicos, que van bajando."""
    t = t_of(seconds)
    sig = np.zeros(len(t))
    for k in range(1, parts + 1):
        sig += np.sin(2 * np.pi * f0 * k * t + RNG.uniform(0, 6.28)) / k**1.3
    if wobble:
        sig *= 1 + wobble * np.sin(2 * np.pi * 0.25 * t)
    return sig


def step(heavy: float = 0.5) -> np.ndarray:
    """Un paso en suelo duro: chasquido de suela y un golpecito sordo."""
    t = t_of(0.12)
    tap = band(noise(0.12), 300, 3000) * np.exp(-t / 0.01)
    thud = np.sin(2 * np.pi * RNG.uniform(85, 120) * t) * np.exp(-t / 0.03)
    return unit_rms(tap) * 0.5 + unit_rms(thud) * heavy


def footsteps(buf: np.ndarray, start: float, count: int, gap: float, amp: float):
    for i in range(count):
        add_at(buf, step() * amp * RNG.uniform(0.7, 1), start + i * gap * RNG.uniform(0.93, 1.07), wrap=True)


def door(amp: float) -> np.ndarray:
    """Una puerta que se cierra lejos: el pestillo y el golpe de madera, apagado."""
    t = t_of(0.5)
    latch = band(noise(0.5), 1500, 5000) * np.exp(-t / 0.004)
    wood = band(noise(0.5), 70, 900) * np.exp(-np.maximum(t - 0.03, 0) / 0.07) * (t > 0.03)
    body = np.sin(2 * np.pi * 95 * t) * np.exp(-np.maximum(t - 0.03, 0) / 0.09) * (t > 0.03)
    sig = 0.25 * unit_rms(latch) + unit_rms(wood) + 0.6 * unit_rms(body)
    return spectral(sig, lambda f: lowpass_gain(f, 1800, 2)) * amp


def roll(seconds: float, amp: float) -> np.ndarray:
    """Ruedas (camilla, carrito) que pasan por un pasillo: rumor con traqueteo, sube y baja."""
    t = t_of(seconds)
    bed = band(noise(seconds), 150, 1400)
    rattle = 1 + 0.5 * np.sin(2 * np.pi * RNG.uniform(14, 20) * t) * np.sin(2 * np.pi * 3.1 * t)
    env = np.sin(np.pi * t / seconds) ** 2
    return unit_rms(bed) * rattle * env * amp


def amb_sala():
    """Aire de una sala cerrada (la base de todos los interiores): climatizador suave y un zumbido."""
    _seed(401)
    length, fade = 8.0, 0.8
    total = length + fade
    air = unit_rms(band(pink(total), 90, 1400, pad=False))
    ac = unit_rms(hum(total, 60, 5, wobble=0.05))
    sig = air + 0.12 * ac
    sig = spectral(sig, lambda f: lowpass_gain(f, 1600, 2), pad=False)
    write("amb_sala.ogg", make_loop(sig, length, fade), loop=True)


def amb_casa():
    """Casa: la nevera que zumba, la calle lejos (por la ventana) y algún crujido de la casa."""
    _seed(402)
    length, fade = 10.0, 0.8
    total = length + fade
    t = t_of(total)
    fridge = unit_rms(hum(total, 50, 8, wobble=0.03)) * (0.9 + 0.1 * np.sin(2 * np.pi * t / 5))
    street = unit_rms(band(brown(total), 40, 600, pad=False)) * (1 + 0.4 * np.sin(2 * np.pi * t / 10))
    room = unit_rms(band(pink(total), 100, 1200, pad=False))
    sig = 0.35 * fridge + 0.5 * street + 0.35 * room
    events = np.zeros(len(t))
    # un crujido de madera y, más tarde, algo que se deja en la cocina (lejos)
    add_at(events, door(0.5) * 0.6, 2.7)
    creak_t = t_of(0.35)
    creak = np.sin(2 * np.pi * np.cumsum(180 + 60 * creak_t / 0.35) / SR) * np.exp(-creak_t / 0.12)
    add_at(events, unit_rms(band(creak, 120, 900)) * 0.25, 7.1)
    sig = sig + events * 0.6
    sig = reverb(sig, 0.6, 0.2, bright=2500)
    sig = spectral(sig, lambda f: lowpass_gain(f, 2200, 2))
    write("amb_casa.ogg", make_loop(sig, length, fade), loop=True)


def amb_colegio():
    """Colegio: niños hablando y riendo en el pasillo o el patio (lejos), pasos y alguna puerta."""
    _seed(403)
    length, fade, pre = 10.0, 0.8, 1.0
    total = pre + length + fade
    kids = np.zeros(n_of(total))
    for _ in range(10):
        f0 = RNG.uniform(250, 340)  # voces de niño
        v = voice(total, f0, talk=RNG.uniform(0.45, 0.8), bright=4200)
        kids += unit_rms(v) * RNG.uniform(0.3, 1.0)
    kids = unit_rms(kids)
    hall = unit_rms(band(pink(total), 150, 2500))
    events = np.zeros(n_of(total))
    footsteps(events, pre + 0.8, 6, 0.32, 0.5)  # alguien corre por el pasillo
    footsteps(events, pre + 5.6, 5, 0.45, 0.35)
    add_at(events, door(0.8), pre + 3.9)
    add_at(events, door(0.5), pre + 8.6)
    sig = 0.9 * kids + 0.2 * hall + 0.5 * events
    sig = reverb(sig, 1.3, 0.45, bright=3200)  # pasillo con eco
    sig = spectral(sig, lambda f: highpass_gain(f, 110) * lowpass_gain(f, 3200, 2))
    write("amb_colegio.ogg", make_loop(sig[n_of(pre):], length, fade), loop=True)


def amb_universidad():
    """Universidad: estudiantes (adultos) en un vestíbulo grande, pasos y la máquina expendedora."""
    _seed(404)
    length, fade, pre = 10.0, 0.8, 1.0
    total = pre + length + fade
    people = unit_rms(crowd(total, 9, bright=3000))
    machine = unit_rms(hum(total, 120, 6) + 0.4 * band(pink(total), 300, 900))  # compresor de la máquina
    events = np.zeros(n_of(total))
    footsteps(events, pre + 1.4, 7, 0.5, 0.45)
    footsteps(events, pre + 6.5, 6, 0.55, 0.3)
    add_at(events, door(0.6), pre + 4.8)
    # la lata cae en la máquina (golpe metálico apagado)
    can_t = t_of(0.4)
    can = sum(np.sin(2 * np.pi * f * can_t) * np.exp(-can_t / d) for f, d in ((420, 0.08), (1130, 0.05), (2470, 0.03)))
    add_at(events, unit_rms(can) * 0.35, pre + 8.2)
    sig = 0.75 * people + 0.12 * machine + 0.5 * events
    sig = reverb(sig, 1.8, 0.5, bright=3000)  # vestíbulo alto
    sig = spectral(sig, lambda f: highpass_gain(f, 90) * lowpass_gain(f, 3000, 2))
    write("amb_universidad.ogg", make_loop(sig[n_of(pre):], length, fade), loop=True)


def amb_hospital():
    """Hospital: ventilación constante, murmullo bajo, una camilla que pasa lejos y pasos suaves.
    (Los pitidos del monitor van aparte en el juego: Config.Sounds.Monitor, así se oyen nítidos.)"""
    _seed(405)
    length, fade, pre = 10.0, 0.8, 1.0
    total = pre + length + fade
    vent = unit_rms(band(pink(total), 120, 1800)) + 0.15 * unit_rms(hum(total, 100, 4))
    people = unit_rms(crowd(total, 4, bright=2400))
    events = np.zeros(n_of(total))
    add_at(events, roll(3.2, 0.7), pre + 1.5)
    footsteps(events, pre + 6.0, 6, 0.6, 0.25)
    add_at(events, door(0.4), pre + 8.9)
    sig = 0.55 * unit_rms(vent) + 0.35 * people + 0.5 * events
    sig = reverb(sig, 1.1, 0.4, bright=2800)  # pasillo de azulejo
    sig = spectral(sig, lambda f: highpass_gain(f, 90) * lowpass_gain(f, 2800, 2))
    write("amb_hospital.ogg", make_loop(sig[n_of(pre):], length, fade), loop=True)


def amb_calle():
    """Calle: tráfico lejano (coches que pasan y se van, rumor de ciudad) y gente a lo lejos."""
    _seed(406)
    length, fade, pre = 10.0, 0.8, 1.0
    total = pre + length + fade
    t = t_of(total)
    city = unit_rms(band(brown(total), 35, 700))
    cars = np.zeros(len(t))
    for start, dur, amp in ((0.5, 3.5, 1.0), (3.2, 4.2, 0.7), (6.4, 3.0, 0.9), (8.5, 3.8, 0.6)):
        seg = t_of(dur)
        whoosh = unit_rms(band(noise(dur), 80, 1600)) * np.exp(-((seg - dur / 2) / (dur / 4)) ** 2) * amp
        add_at(cars, whoosh, pre + start - 1.0)
    people = unit_rms(crowd(total, 5, bright=2000))
    sig = 0.7 * city + 0.6 * cars + 0.25 * people
    sig = reverb(sig, 1.0, 0.3, bright=2500)
    sig = spectral(sig, lambda f: highpass_gain(f, 45) * lowpass_gain(f, 2400, 2))
    write("amb_calle.ogg", make_loop(sig[n_of(pre):], length, fade), loop=True)


AMBIENCE = (amb_sala, amb_casa, amb_colegio, amb_universidad, amb_hospital, amb_calle)


# ---------------------------------------------------------------------------
# Comprobación (no se puede escuchar aquí, así que se miran los números)
# ---------------------------------------------------------------------------

LOOPS = {"motor", "tele", "multitud", "metro_tren", "metro_anden", "lluvia", "pajaros", "viento"} | {a.__name__ for a in AMBIENCE}


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


ALL = (motor, claxon, timbre, tele, multitud, metro_tren, metro_freno, metro_anden, lluvia, trueno, pajaros, viento,
       choque_leve, choque_fuerte, golpe_caida, golpe_choque,
       disparo_pistola, disparo_revolver, disparo_escopeta, disparo_subfusil, disparo_fusil, disparo_eco) + AMBIENCE
# (los ambientes, al final: reinician la semilla y así los de antes salen igual que siempre)


if __name__ == "__main__":
    import sys

    # Sin nombres: todos. Con nombres (python3 scripts/audio/sfx.py choque_leve disparo_pistola): solo esos
    # (los que ya están subidos no se tocan).
    wanted = {a.removesuffix(".ogg") for a in sys.argv[1:]}
    unknown = wanted - {m.__name__ for m in ALL}
    if unknown:
        sys.exit(f"No conozco: {', '.join(sorted(unknown))}")
    print(f"Sintetizando efectos en {OUT}")
    for make in ALL:
        if wanted and make.__name__ not in wanted:
            continue
        make()
        print(f"  {make.__name__}")
    check()
