"""Efectos de respuesta del juego (interfaz, recompensas, deporte, mundo) -> roblox/audio/sfx/.

Como sfx.py y compose.py: todo sale de código, así que son 100 % nuestros (sin derechos de nadie).
No son "pitidos": cada uno se construye por capas como en un juego grande:
  * transitorio (el "clic" del ataque: ruido muy corto filtrado),
  * cuerpo (resonancias modales de madera, metal, cristal o campana FM con parciales inarmónicos),
  * aire (barridos de ruido con filtro que se mueve: whoosh),
  * cola (sala o reverb con reflexiones tempranas, nunca seca),
y al final se igualan de sonoridad por categoría (RMS de la parte activa) para que la interfaz, las
recompensas y los golpes del mundo suenen parejos entre sí y por debajo de las voces.

Uso (desde roblox/):   python3 scripts/audio/sfx_feedback.py            (todos)
                       python3 scripts/audio/sfx_feedback.py dinero xp  (solo esos)
Necesita:              pip install numpy soundfile

Se suben con el resto de audio/sfx: bash scripts/upload-audio.sh (solo sube los que faltan).
Mientras un archivo no esté subido, su sonido de Config.Sounds no suena (o suena el de Roblox de
siempre si ya lo tenía): nunca hay errores.
"""

from pathlib import Path
import sys

import numpy as np
import soundfile as sf

SR = 44100
OUT = Path(__file__).resolve().parents[2] / "audio" / "sfx"
CEILING = 10 ** (-1 / 20)  # pico máximo -1 dBFS

# Sonoridad objetivo (dBFS RMS de la parte que suena) por categoría: la interfaz más baja que las
# recompensas; los golpes del mundo, parejos con los choques y pasos que ya hay.
TARGET = {"ui": -24.0, "reward": -20.0, "sting": -19.0, "world": -20.0, "loop": -26.0}


# ---------------------------------------------------------------------------
# Herramientas
# ---------------------------------------------------------------------------

def n_of(s: float) -> int:
    return int(round(s * SR))


def t_of(s: float) -> np.ndarray:
    return np.arange(n_of(s)) / SR


class Gen:
    """Cada sonido con su propia semilla: rehacer uno no cambia los demás."""

    def __init__(self, seed: int):
        self.rng = np.random.default_rng(seed)

    def noise(self, s: float) -> np.ndarray:
        return self.rng.normal(0, 1, n_of(s))

    def u(self, a: float, b: float) -> float:
        return float(self.rng.uniform(a, b))


def fft_filter(x: np.ndarray, gain) -> np.ndarray:
    n = len(x)
    size = 1 << int(np.ceil(np.log2(max(2, n * 2))))
    f = np.fft.rfftfreq(size, 1 / SR)
    return np.fft.irfft(np.fft.rfft(x, size) * gain(f), size)[:n]


def lp(f, fc, order=2):
    return 1 / np.sqrt(1 + (f / fc) ** (2 * order))


def hp(f, fc, order=2):
    f = np.maximum(f, 1e-6)
    return 1 / np.sqrt(1 + (fc / f) ** (2 * order))


def bandpass(x, lo, hi, order=2):
    return fft_filter(x, lambda f: hp(f, lo, order) * lp(f, hi, order))


def peak_eq(f, fc, q, db):
    """Campana de ecualizador (aprox. en magnitud)."""
    g = 10 ** (db / 20)
    return 1 + (g - 1) / (1 + (q * (f / fc - fc / np.maximum(f, 1e-6))) ** 2)


def svf_sweep(x: np.ndarray, fc: np.ndarray, q: float = 1.2, mode: str = "bp") -> np.ndarray:
    """Filtro de estado variable con la frecuencia moviéndose muestra a muestra (whoosh, swish)."""
    out = np.zeros_like(x)
    low = band = 0.0
    damp = 1.0 / q
    fc = np.clip(fc, 20, SR * 0.22)
    coef = 2 * np.sin(np.pi * fc / SR)
    for i in range(len(x)):
        f = coef[i]
        low += f * band
        high = x[i] - low - damp * band
        band += f * high
        out[i] = band if mode == "bp" else (low if mode == "lp" else high)
    return out


def tail_fade(s: float) -> np.ndarray:
    """Fundido final (el último 25 %, mínimo 10 ms): una resonancia cortada da un clic de banda ancha."""
    n = n_of(s)
    f = min(n, max(n_of(0.01), n // 4))
    e = np.ones(n)
    e[n - f:] = np.cos(np.linspace(0, np.pi / 2, f)) ** 2
    return e


def env_exp(s: float, tau: float, attack: float = 0.001) -> np.ndarray:
    t = t_of(s)
    a = np.clip(t / max(attack, 1e-5), 0, 1)
    return np.exp(-t / tau) * (np.sin(a * np.pi / 2) ** 2)


def env_ar(s: float, attack: float, release: float, shape: float = 2.0) -> np.ndarray:
    """Sube en attack y baja hasta el final (curva suave)."""
    t = t_of(s)
    up = np.clip(t / max(attack, 1e-5), 0, 1) ** shape
    down = np.clip((s - t) / max(release, 1e-5), 0, 1) ** shape
    return np.minimum(up, down)


def add(buf: np.ndarray, sig: np.ndarray, at: float, gain: float = 1.0):
    i = n_of(at)
    j = min(len(buf), i + len(sig))
    if j > i:
        part = sig[: j - i] * gain
        if j - i < len(sig):  # no cabe entero: se funde al final (sin clic)
            f = min(len(part), n_of(0.03))
            part[len(part) - f:] *= np.cos(np.linspace(0, np.pi / 2, f)) ** 2
        buf[i:j] += part


def rms_db(x):
    return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12)


def unit(x):
    return x / (np.max(np.abs(x)) + 1e-12)


# --- fuentes -------------------------------------------------------------

def transient(g: Gen, s: float = 0.006, lo: float = 1500, hi: float = 9000) -> np.ndarray:
    """El ataque: ruido de unos milisegundos, filtrado (el "tic" que hace que un golpe se sienta)."""
    x = bandpass(g.noise(s + 0.004), lo, hi)[: n_of(s)]
    return x * env_exp(s, s / 3, 0.0002)


def modal(g: Gen, s: float, parts, detune: float = 0.004) -> np.ndarray:
    """Resonancias: parts = [(Hz, amp, tau)]. Fases al azar y desafinado mínimo (nada robótico)."""
    t = t_of(s)
    sig = np.zeros(len(t))
    for f, a, tau in parts:
        f *= 1 + g.u(-detune, detune)
        sig += a * np.sin(2 * np.pi * f * t + g.u(0, 2 * np.pi)) * np.exp(-t / tau)
    return sig * tail_fade(s) * np.clip(t / 0.0006, 0, 1)  # (sin escalón al empezar: lo pone el transitorio)


def fm_bell(s: float, f0: float, ratio: float = 3.5, index: float = 2.2, tau: float = 0.8,
            index_tau: float | None = None) -> np.ndarray:
    """Campana FM (la de los sintes clásicos): el brillo se apaga antes que el tono."""
    t = t_of(s)
    itau = index_tau or tau * 0.35
    mod = index * np.exp(-t / itau) * np.sin(2 * np.pi * f0 * ratio * t)
    car = np.sin(2 * np.pi * f0 * t + mod)
    attack = np.clip(t / 0.0015, 0, 1)
    return car * np.exp(-t / tau) * attack * tail_fade(s)


GLOCK = [(1.0, 1.0, 1.0), (2.76, 0.42, 0.45), (5.40, 0.22, 0.2), (8.93, 0.10, 0.09)]
MARIMBA = [(1.0, 1.0, 1.0), (3.93, 0.32, 0.22), (9.2, 0.08, 0.06)]
CELESTA = [(1.0, 1.0, 1.0), (2.0, 0.28, 0.6), (3.0, 0.12, 0.35), (4.16, 0.07, 0.2)]


def mallet(g: Gen, s: float, f0: float, kind=GLOCK, tau: float = 0.6, hard: float = 0.5) -> np.ndarray:
    parts = [(f0 * r, a, tau * d) for r, a, d in kind]
    body = modal(g, s, parts, 0.0015)
    click = transient(g, 0.004, 2000, 10000) * hard * 0.6
    out = body
    out[: len(click)] += click
    return out


def sparkle(g: Gen, s: float, count: int, lo: float = 3000, hi: float = 8000, start: float = 0.0,
            spread: float | None = None, tau: float = 0.12, grow: bool = False) -> np.ndarray:
    """Destellos: muchas campanitas agudas muy cortas (el "brillo" de las recompensas)."""
    buf = np.zeros(n_of(s))
    spread = spread if spread is not None else s * 0.6
    for k in range(count):
        at = start + (g.u(0, 1) ** (0.6 if grow else 1.4)) * spread
        f = np.exp(g.u(np.log(lo), np.log(min(hi, 9000))))
        grain = modal(g, min(0.5, tau * 5), [(f, 1, tau * g.u(0.6, 1.2)), (f * 2.01, 0.25, tau * 0.4)])
        add(buf, grain * g.u(0.3, 1.0), at)
    return buf


def whoosh(g: Gen, s: float, f_from: float, f_to: float, q: float = 1.6, attack: float | None = None,
           release: float | None = None) -> np.ndarray:
    """Aire que pasa: ruido con un filtro que barre de f_from a f_to (curva exponencial)."""
    n = n_of(s)
    x = g.noise(s)
    k = np.linspace(0, 1, n)
    fc = f_from * (f_to / f_from) ** k
    y = svf_sweep(x, fc, q, "bp")
    e = env_ar(s, attack if attack is not None else s * 0.6, release if release is not None else s * 0.4)
    # (el ruido blanco filtrado deja mucho siseo arriba: se inclina hacia los medios)
    return fft_filter(y * e, lambda f: lp(f, 6500, 2) * peak_eq(f, 9000, 0.7, -4))


def reverb(g: Gen, x: np.ndarray, seconds: float, wet: float, bright: float = 6000,
           pre: float = 0.012, early: int = 6) -> np.ndarray:
    """Sala con reflexiones tempranas + cola difusa (ruido que se apaga, más oscuro al final)."""
    t = t_of(seconds)
    tail = g.noise(seconds) * np.exp(-t / (seconds / 6.9))
    # la cola se oscurece con el tiempo: mezcla de versión clara y oscura
    dark = fft_filter(tail, lambda f: lp(f, bright * 0.35, 1))
    clear = fft_filter(tail, lambda f: lp(f, bright, 1))
    mixk = np.clip(t / seconds * 2, 0, 1)
    ir = clear * (1 - mixk) + dark * mixk
    ir[: n_of(pre)] = 0
    for _ in range(early):
        i = n_of(pre + g.u(0.002, 0.04))
        if i < len(ir):
            ir[i] += g.u(-1, 1) * 3.0
    ir = fft_filter(ir, lambda f: hp(f, 180, 1))
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-12
    size = 1 << int(np.ceil(np.log2(len(x) + len(ir))))
    w = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x) + len(ir)]
    dry = np.concatenate([x, np.zeros(len(ir))])
    w *= np.sqrt(np.mean(x ** 2)) / (np.sqrt(np.mean(w[: len(x)] ** 2)) + 1e-12)
    return dry + w * wet


def soft_clip(x, drive=1.0):
    return np.tanh(x * drive) / np.tanh(drive)


def note(semi_from_a4: float) -> float:
    return 440.0 * 2 ** (semi_from_a4 / 12)


# notas útiles (Re mayor, como la música de la historia)
D5, FS5, A5, B5, D6, E6, FS6, A6 = (note(x) for x in (5, 9, 12, 14, 17, 19, 21, 24))
A4, D4, FS4, E5, G5, CS6 = note(0), note(-7), note(-3), note(7), note(10), note(16)


def finish(name: str, sig: np.ndarray, cat: str, loop: bool = False, fade_out: float = 0.02):
    """Recorta el silencio, igualan sonoridad por categoría, techo -1 dBFS y guarda en ogg mono."""
    sig = sig - np.mean(sig)
    if not loop:
        # recorta la cola por debajo de -70 dB del pico
        thr = np.max(np.abs(sig)) * 10 ** (-70 / 20)
        idx = np.nonzero(np.abs(sig) > thr)[0]
        if len(idx):
            sig = sig[: idx[-1] + 1]
        sig = sig * env_ar(len(sig) / SR, 0.0008, fade_out, 1)
    # sonoridad: RMS de las ventanas que suenan (por encima de -40 dB del pico)
    w = n_of(0.02)
    frames = sig[: len(sig) // w * w].reshape(-1, w) if len(sig) >= w else sig.reshape(1, -1)
    fr = np.sqrt(np.mean(frames ** 2, axis=1))
    active = fr[fr > np.max(fr) * 0.01]
    level = 20 * np.log10(np.sqrt(np.mean(active ** 2)) + 1e-12)
    sig = sig * 10 ** ((TARGET[cat] - level) / 20)
    if np.max(np.abs(sig)) > CEILING:
        # limitador de picos: por debajo del umbral no toca nada (la sonoridad se mantiene)
        thr = CEILING * 0.6
        mag = np.abs(sig)
        over = mag > thr
        sig[over] = np.sign(sig[over]) * (thr + (CEILING - thr) * np.tanh((mag[over] - thr) / (CEILING - thr)))
    OUT.mkdir(parents=True, exist_ok=True)
    sf.write(OUT / f"{name}.ogg", sig.astype(np.float32), SR, format="OGG", subtype="VORBIS", compression_level=0.5)


def make_loop(sig: np.ndarray, length: float, fade: float) -> np.ndarray:
    n, f = n_of(length), n_of(fade)
    out = sig[:n].copy()
    tail = sig[n:n + f]
    w = np.linspace(0, np.pi / 2, f)
    out[:f] = out[:f] * np.sin(w) + tail * np.cos(w)
    return out


# ---------------------------------------------------------------------------
# Interfaz (2D)
# ---------------------------------------------------------------------------

def ui_toque():
    """Toque de botón: "tock" de madera fina muy corto + clic de ataque. Nada de pitido."""
    g = Gen(1001)
    body = modal(g, 0.09, [(1180, 1, 0.012), (2890, 0.35, 0.006), (4630, 0.12, 0.003)])
    click = transient(g, 0.003, 3000, 12000) * 0.5
    sig = body
    sig[: len(click)] += click
    sig = fft_filter(sig, lambda f: hp(f, 300, 2))
    finish("ui_toque", reverb(g, sig, 0.25, 0.08, 7000), "ui")


def ui_seleccion():
    """Elegir en la barra: tick de madera un poco más grave y redondo que el toque."""
    g = Gen(1002)
    body = modal(g, 0.12, [(760, 1, 0.02), (1960, 0.3, 0.009), (3400, 0.1, 0.004)])
    click = transient(g, 0.0035, 2500, 10000) * 0.45
    body[: len(click)] += click
    finish("ui_seleccion", reverb(g, fft_filter(body, lambda f: hp(f, 250)), 0.3, 0.1, 6000), "ui")


def ui_abrir():
    """Abrir un panel: soplo de aire que sube + un tick suave al final (el panel "asienta")."""
    g = Gen(1003)
    s = 0.26
    air = whoosh(g, s, 700, 4200, 1.3, attack=0.17, release=0.09)
    buf = np.zeros(n_of(0.4))
    add(buf, air, 0, 0.9)
    tick = modal(g, 0.08, [(1650, 1, 0.01), (3900, 0.3, 0.004)])
    add(buf, tick, 0.16, 0.35)
    finish("ui_abrir", reverb(g, buf, 0.35, 0.12, 7000), "ui")


def ui_cerrar():
    """Cerrar: el mismo aire pero bajando y más corto, con un tick más grave."""
    g = Gen(1004)
    s = 0.2
    air = whoosh(g, s, 3600, 650, 1.3, attack=0.05, release=0.14)
    buf = np.zeros(n_of(0.34))
    add(buf, air, 0, 0.85)
    tick = modal(g, 0.08, [(980, 1, 0.012), (2300, 0.3, 0.005)])
    add(buf, tick, 0.13, 0.35)
    finish("ui_cerrar", reverb(g, buf, 0.3, 0.1, 6000), "ui")


def movil_abrir():
    """Sacar el móvil: roce de tela (sacarlo del bolsillo) y dos toques de cristal suaves."""
    g = Gen(1005)
    buf = np.zeros(n_of(0.6))
    cloth = bandpass(g.noise(0.22), 900, 5000) * env_ar(0.22, 0.08, 0.12)
    cloth *= 1 + 0.6 * np.sin(2 * np.pi * 23 * t_of(0.22))  # textura del roce
    add(buf, cloth, 0, 0.35)
    for at, f in ((0.2, E6), (0.29, A6)):
        add(buf, mallet(g, 0.4, f, CELESTA, tau=0.18, hard=0.3), at, 0.55)
    finish("movil_abrir", reverb(g, buf, 0.6, 0.18, 8000), "ui")


def notificacion():
    """Notificación: dos notas de marimba-celesta (quinta justa) con una pizca de brillo. Amable."""
    g = Gen(1006)
    buf = np.zeros(n_of(0.9))
    add(buf, mallet(g, 0.8, A5, MARIMBA, tau=0.35, hard=0.4), 0.0, 0.8)
    add(buf, mallet(g, 0.8, E6, MARIMBA, tau=0.4, hard=0.4), 0.11, 0.9)
    add(buf, mallet(g, 0.8, E6 * 2, CELESTA, tau=0.25, hard=0.1), 0.11, 0.12)
    finish("notificacion", reverb(g, buf, 0.9, 0.22, 8000), "ui")


def error_suave():
    """Denegado: dos golpes de madera grave descendentes y apagados (claro pero nada estridente)."""
    g = Gen(1007)
    buf = np.zeros(n_of(0.5))
    for at, f in ((0.0, 392.0), (0.1, 311.1)):
        hit = modal(g, 0.3, [(f, 1, 0.07), (f * 2.42, 0.35, 0.03), (f * 4.1, 0.1, 0.012)])
        click = transient(g, 0.004, 1200, 6000) * 0.5
        hit[: len(click)] += click
        add(buf, hit, at, 0.9)
    buf = fft_filter(buf, lambda f: lp(f, 3500, 2) * hp(f, 160, 2))
    finish("error_suave", reverb(g, buf, 0.35, 0.12, 4000), "ui")


# ---------------------------------------------------------------------------
# Recompensas (2D)
# ---------------------------------------------------------------------------

def dinero():
    """«Ka-ching»: clac mecánico del cajón + campanilla de caja (FM, inarmónica) + monedas."""
    g = Gen(2001)
    buf = np.zeros(n_of(1.3))
    # "ka": el cajón/palanca (golpe metálico seco con cuerpo)
    ka = modal(g, 0.12, [(410, 1, 0.025), (1230, 0.6, 0.015), (2650, 0.35, 0.008), (5100, 0.2, 0.004)])
    ka[: n_of(0.004)] += transient(g, 0.004, 1500, 9000) * 0.8
    add(buf, fft_filter(ka, lambda f: hp(f, 200)), 0.0, 0.7)
    # "ching": campanilla (dos golpes de campana muy seguidos, como la de una caja registradora)
    for at, f, a in ((0.075, 2093.0, 1.0), (0.085, 2637.0, 0.55)):
        bell = fm_bell(1.1, f, ratio=2.76, index=1.6, tau=0.45, index_tau=0.08)
        add(buf, bell, at, a * 0.55)
    # monedas: tintineos metálicos pequeños y desordenados
    for _ in range(9):
        f = g.u(3500, 7500)
        coin = modal(g, 0.18, [(f, 1, 0.03), (f * 1.47, 0.5, 0.02), (f * 2.13, 0.25, 0.012)])
        add(buf, coin, 0.09 + g.u(0, 0.22) ** 1.3, g.u(0.08, 0.2))
    finish("dinero", reverb(g, buf, 0.8, 0.18, 9000), "reward")


def xp():
    """Experiencia: destello corto que sube (tres campanitas rápidas + chispas)."""
    g = Gen(2002)
    buf = np.zeros(n_of(0.8))
    for i, f in enumerate((A5, CS6, E6 * 1.0)):
        add(buf, mallet(g, 0.5, f * 2, GLOCK, tau=0.2, hard=0.2), i * 0.045, 0.35)
    add(buf, sparkle(g, 0.6, 14, 5000, 11000, start=0.03, spread=0.25, tau=0.05), 0, 0.25)
    finish("xp", reverb(g, buf, 0.7, 0.22, 10000), "reward")


def nivel_sube():
    """Subir de nivel (fanfarria grande): riser de aire + golpe suave + acorde de campanas en Re mayor
    que se abre (Re-Fa#-La-Re) + colchón de cuerdas (sierras filtradas) + cascada de chispas."""
    g = Gen(2003)
    s = 3.0
    buf = np.zeros(n_of(s))
    hit_t = 0.42
    # riser
    add(buf, whoosh(g, 0.5, 400, 6000, 1.1, attack=0.42, release=0.08), 0.0, 0.7)
    # golpe de bombo suave (cuerpo, sin subgrave)
    t = t_of(0.5)
    kick = np.sin(2 * np.pi * (70 + 90 * np.exp(-t / 0.03)) * t) * np.exp(-t / 0.13)
    kick = fft_filter(kick, lambda f: hp(f, 55, 2))
    add(buf, kick, hit_t, 0.55)
    # acorde arpegiado de campanas
    for i, f in enumerate((D5, FS5, A5, D6, FS6)):
        add(buf, mallet(g, 2.4, f, GLOCK, tau=0.9, hard=0.35), hit_t + i * 0.055, 0.42)
        add(buf, fm_bell(2.4, f, 3.5, 1.4, 1.2, 0.15), hit_t + i * 0.055, 0.18)
    # colchón de cuerdas: sierras desafinadas, filtro que abre
    pad_s = 2.4
    tp = t_of(pad_s)
    pad = np.zeros(len(tp))
    for f in (D4, A4, D5, FS5):
        for d in (-0.006, 0.0, 0.007):
            ph = g.u(0, 1)
            saw = 2 * ((f * (1 + d) * tp + ph) % 1) - 1
            pad += saw
    pad = fft_filter(pad, lambda f: lp(f, 2600, 2) * hp(f, 120, 2))
    pad *= env_ar(pad_s, 0.25, 1.6, 1.5)
    add(buf, pad, hit_t - 0.02, 0.05)
    # chispas que caen
    add(buf, sparkle(g, 2.2, 40, 3500, 10000, start=0.0, spread=1.3, tau=0.09), hit_t, 0.22)
    finish("nivel_sube", reverb(g, buf, 2.2, 0.32, 9000), "sting", fade_out=0.4)


def mision_empieza():
    """Empieza una misión: golpe grave cinematográfico suave + dos notas que suben (cuarta) + aire."""
    g = Gen(2004)
    buf = np.zeros(n_of(2.0))
    t = t_of(1.2)
    boom = np.sin(2 * np.pi * (55 + 40 * np.exp(-t / 0.05)) * t) * np.exp(-t / 0.35)
    boom = fft_filter(boom + 0.25 * bandpass(g.noise(1.2), 80, 900) * np.exp(-t / 0.08), lambda f: hp(f, 45, 3))
    add(buf, boom, 0.0, 0.6)
    add(buf, whoosh(g, 0.35, 300, 2500, 1.0, attack=0.03, release=0.3), 0.0, 0.25)
    for at, f in ((0.08, A4), (0.3, D5)):
        add(buf, mallet(g, 1.3, f, MARIMBA, tau=0.6, hard=0.5), at, 0.6)
        add(buf, fm_bell(1.3, f * 2, 3.0, 1.0, 0.7), at, 0.15)
    finish("mision_empieza", reverb(g, buf, 1.8, 0.3, 7000), "sting", fade_out=0.3)


def mision_completa():
    """Misión cumplida (triunfal): arpegio ascendente rápido de campanas, acorde final con "metales"
    (sierras con filtro que se abre, ataque de embocadura) y chispas."""
    g = Gen(2005)
    s = 3.2
    buf = np.zeros(n_of(s))
    arp = (D5, FS5, A5, D6)
    for i, f in enumerate(arp):
        add(buf, mallet(g, 1.6, f, GLOCK, tau=0.5, hard=0.4), i * 0.07, 0.4)
    chord_t = 0.3
    br_s = 2.3
    tb = t_of(br_s)
    brass = np.zeros(len(tb))
    for f in (D4, A4, D5, FS5, A5):
        for d in (-0.004, 0.004):
            saw = 2 * ((f * (1 + d) * tb + g.u(0, 1)) % 1) - 1
            brass += saw
    # filtro que se abre al soplar (lo que hace que suene a metal y no a sinte)
    cutoff = 600 + 2600 * (1 - np.exp(-tb / 0.08)) * np.exp(-tb / 1.6)
    brass = svf_sweep(brass * 0.2, cutoff, 0.9, "lp")
    brass = fft_filter(brass, lambda f: hp(f, 110, 2) * peak_eq(f, 1400, 1.2, 4))
    brass *= env_ar(br_s, 0.04, 1.4, 1.3)
    add(buf, brass, chord_t, 0.5)
    for f in (D6, FS6, A6):
        add(buf, fm_bell(2.2, f, 3.5, 1.3, 0.9, 0.12), chord_t, 0.22)
    t = t_of(0.4)
    kick = fft_filter(np.sin(2 * np.pi * (75 + 80 * np.exp(-t / 0.025)) * t) * np.exp(-t / 0.12), lambda f: hp(f, 55, 2))
    add(buf, kick, chord_t, 0.5)
    add(buf, sparkle(g, 2.2, 34, 4000, 11000, spread=1.2, tau=0.08), chord_t + 0.02, 0.2)
    finish("mision_completa", reverb(g, buf, 2.4, 0.34, 9000), "sting", fade_out=0.4)


def logro():
    """Logro desbloqueado: "whoosh" corto + golpe de cristal brillante + acorde de celesta (La mayor)."""
    g = Gen(2006)
    buf = np.zeros(n_of(2.2))
    add(buf, whoosh(g, 0.28, 1200, 9000, 1.2, attack=0.24, release=0.04), 0.0, 0.5)
    hit = 0.26
    for i, f in enumerate((A5, CS6, E6, A6)):
        add(buf, mallet(g, 1.8, f, CELESTA, tau=0.7, hard=0.4), hit + i * 0.03, 0.4)
    add(buf, fm_bell(1.8, A6, 2.76, 1.8, 0.9, 0.1), hit, 0.25)
    add(buf, sparkle(g, 1.6, 26, 5000, 12000, spread=0.9, tau=0.07), hit, 0.22)
    finish("logro", reverb(g, buf, 1.8, 0.3, 10000), "sting", fade_out=0.3)


def descubrimiento_fx():
    """Descubrir algo / un sitio nuevo: aire que crece (reverse-swell) y se abre en una campana suave."""
    g = Gen(2007)
    buf = np.zeros(n_of(2.6))
    sw = 0.7
    swell = whoosh(g, sw, 900, 5000, 2.2, attack=0.68, release=0.02)
    add(buf, swell, 0.0, 0.45)
    shimmer = sparkle(g, sw, 30, 4000, 9000, spread=sw * 0.95, tau=0.05, grow=True)
    shimmer *= np.linspace(0.1, 1, len(shimmer)) ** 2
    add(buf, shimmer, 0.0, 0.25)
    for i, f in enumerate((D5, A5, E6)):
        add(buf, fm_bell(2.0, f, 3.5, 1.2, 0.9, 0.15), sw + i * 0.04, 0.35)
        add(buf, mallet(g, 2.0, f * 2, CELESTA, tau=0.5, hard=0.2), sw + i * 0.04, 0.18)
    finish("descubrimiento_fx", reverb(g, buf, 2.0, 0.36, 8000), "sting", fade_out=0.3)


def tension_golpe():
    """Tensión en la historia: impacto grave de tráiler controlado (cuerpo de 50-90 Hz, sin retumbar
    eterno), con un cluster disonante de cuerdas que se apaga y una cola larga y oscura."""
    g = Gen(2008)
    s = 3.2
    buf = np.zeros(n_of(s))
    t = t_of(1.6)
    boom = np.sin(2 * np.pi * (48 + 50 * np.exp(-t / 0.06)) * t) * np.exp(-t / 0.5)
    thud = bandpass(g.noise(1.6), 60, 1200) * np.exp(-t / 0.05)
    hit = fft_filter(soft_clip(boom * 1.4 + 0.5 * thud, 1.2), lambda f: hp(f, 38, 3))
    add(buf, hit, 0.0, 0.8)
    tc = t_of(2.6)
    cl = np.zeros(len(tc))
    for f in (note(-17), note(-16), note(-10), note(-9)):  # E-F y B-C: semitonos que rozan
        for d in (-0.003, 0.003):
            cl += 2 * ((f * (1 + d) * tc + g.u(0, 1)) % 1) - 1
    cl = fft_filter(cl, lambda f: lp(f, 1400, 2) * hp(f, 90, 2))
    cl *= env_ar(2.6, 0.02, 2.2, 1.3) * (1 + 0.15 * np.sin(2 * np.pi * 5.5 * tc))
    add(buf, cl, 0.0, 0.07)
    finish("tension_golpe", reverb(g, buf, 2.6, 0.4, 3500), "sting", fade_out=0.6)


# ---------------------------------------------------------------------------
# Interacciones (3D)
# ---------------------------------------------------------------------------

def caja_registradora():
    """Cobrar en la tienda: pitido del lector de verdad (onda casi senoidal ~2.9 kHz con el armónico del
    altavocito) y, detrás, el golpe del cajón al abrirse."""
    g = Gen(3001)
    buf = np.zeros(n_of(0.7))
    t = t_of(0.11)
    f = 2930
    beep = (np.sin(2 * np.pi * f * t) + 0.18 * np.sin(2 * np.pi * 2 * f * t)) * env_ar(0.11, 0.004, 0.01, 1)
    add(buf, beep, 0.0, 0.45)
    drawer = modal(g, 0.25, [(220, 1, 0.05), (640, 0.6, 0.03), (1500, 0.3, 0.015), (3300, 0.15, 0.006)])
    drawer[: n_of(0.005)] += transient(g, 0.005, 800, 7000)
    slide = bandpass(g.noise(0.12), 1500, 6000) * env_ar(0.12, 0.02, 0.08)
    add(buf, slide, 0.17, 0.12)
    add(buf, fft_filter(drawer, lambda f: hp(f, 120)), 0.28, 0.6)
    finish("caja_registradora", reverb(g, buf, 0.4, 0.12, 6000), "world")


def puerta_madera():
    """Puerta de madera que se cierra: pestillo metálico + golpe de madera con cuerpo + sala."""
    g = Gen(3002)
    buf = np.zeros(n_of(0.8))
    t = t_of(0.35)
    wood = modal(g, 0.35, [(95, 1, 0.07), (180, 0.7, 0.05), (410, 0.4, 0.03), (930, 0.2, 0.012)])
    wood += bandpass(g.noise(0.35), 100, 2500) * np.exp(-t / 0.02) * 0.6
    add(buf, fft_filter(wood, lambda f: hp(f, 65, 2)), 0.0, 0.9)
    latch = modal(g, 0.1, [(2400, 1, 0.012), (4100, 0.6, 0.008), (6200, 0.3, 0.004)])
    latch[: n_of(0.003)] += transient(g, 0.003, 3000, 12000)
    add(buf, latch, 0.008, 0.3)
    finish("puerta_madera", reverb(g, buf, 0.6, 0.25, 5000), "world")


def coger_objeto():
    """Coger algo: roce rápido (mano y tela) + un "tock" suave de objeto."""
    g = Gen(3003)
    buf = np.zeros(n_of(0.35))
    rustle = bandpass(g.noise(0.14), 1200, 7000) * env_ar(0.14, 0.03, 0.1)
    rustle *= 1 + 0.7 * np.abs(np.sin(2 * np.pi * 31 * t_of(0.14)))
    add(buf, rustle, 0.0, 0.4)
    tock = modal(g, 0.15, [(520, 1, 0.02), (1340, 0.4, 0.01), (2900, 0.15, 0.005)])
    tock[: n_of(0.003)] += transient(g, 0.003, 2000, 9000) * 0.6
    add(buf, tock, 0.09, 0.7)
    finish("coger_objeto", reverb(g, buf, 0.3, 0.1, 6000), "world")


# ---------------------------------------------------------------------------
# Deporte (3D)
# ---------------------------------------------------------------------------

def balon_patada():
    """Chute: el pie contra el cuero (golpe sordo con cuerpo de 120-250 Hz) + la "piel" (chasquido
    de cuero de 2-4 kHz) + un poco de aire del balón que sale."""
    g = Gen(4001)
    buf = np.zeros(n_of(0.5))
    t = t_of(0.25)
    thump = np.sin(2 * np.pi * (140 + 110 * np.exp(-t / 0.008)) * t) * np.exp(-t / 0.035)
    leather = bandpass(g.noise(0.25), 1600, 5000) * np.exp(-t / 0.006)
    body = modal(g, 0.25, [(230, 0.6, 0.03), (470, 0.25, 0.02)])
    add(buf, fft_filter(thump + 0.55 * leather + body, lambda f: hp(f, 90, 2)), 0.0, 1.0)
    add(buf, whoosh(g, 0.2, 1800, 600, 1.0, attack=0.01, release=0.18), 0.01, 0.08)
    finish("balon_patada", reverb(g, buf, 0.35, 0.12, 6000), "world")


def balon_bote():
    """Bote de balón de baloncesto: golpe con el "ping" hueco de la cámara de aire (parcial ~ 380 Hz que
    resuena) y la goma contra el suelo."""
    g = Gen(4002)
    buf = np.zeros(n_of(0.45))
    t = t_of(0.3)
    hit = np.sin(2 * np.pi * (170 + 60 * np.exp(-t / 0.006)) * t) * np.exp(-t / 0.03)
    ping = modal(g, 0.3, [(385, 0.55, 0.06), (812, 0.18, 0.03), (1490, 0.08, 0.015)])
    slap = bandpass(g.noise(0.3), 900, 4000) * np.exp(-t / 0.004)
    add(buf, fft_filter(hit + ping + 0.5 * slap, lambda f: hp(f, 90, 2)), 0.0, 1.0)
    finish("balon_bote", reverb(g, buf, 0.6, 0.22, 5000), "world")


def aro_rebote():
    """Balón contra el aro: metal (modos inarmónicos de un aro de acero) + golpe del balón + vibración."""
    g = Gen(4003)
    buf = np.zeros(n_of(1.2))
    ring = modal(g, 1.1, [(520, 1, 0.25), (1415, 0.6, 0.16), (2710, 0.35, 0.09), (4430, 0.18, 0.05), (6300, 0.08, 0.03)])
    ring *= 1 + 0.12 * np.sin(2 * np.pi * 9 * t_of(1.1))  # el aro vibra en su soporte
    t = t_of(0.2)
    ball = np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.025) + bandpass(g.noise(0.2), 800, 4000) * np.exp(-t / 0.004) * 0.5
    add(buf, ring, 0.0, 0.55)
    add(buf, ball, 0.0, 0.8)
    finish("aro_rebote", reverb(g, buf, 0.8, 0.22, 7000), "world")


def red_swish():
    """«Swish» de la red de baloncesto: roce de cuerdas de nylon (ruido de banda que baja) muy rápido."""
    g = Gen(4004)
    s = 0.42
    buf = np.zeros(n_of(0.6))
    sw = whoosh(g, s, 5200, 1400, 2.4, attack=0.05, release=0.33)
    grit = bandpass(g.noise(s), 3000, 9000) * env_ar(s, 0.04, 0.3) * (1 + np.sign(np.sin(2 * np.pi * 60 * t_of(s)))) * 0.5
    add(buf, sw, 0.0, 1.0)
    add(buf, grit, 0.0, 0.18)
    finish("red_swish", reverb(g, buf, 0.4, 0.15, 8000), "world")


def silbato():
    """Silbato de árbitro (de bolita): tono de ~3.1 kHz con el trino rápido de la bolita (AM + FM a
    ~40 Hz), soplo de aire y ataque con lengua. Un pitido largo y uno corto delante, como en el campo."""
    g = Gen(4005)
    buf = np.zeros(n_of(1.2))

    def blow(dur: float):
        t = t_of(dur)
        trill = 0.5 + 0.5 * np.sin(2 * np.pi * (38 + 4 * np.sin(2 * np.pi * 1.3 * t)) * t)
        f = 3100 + 70 * np.sin(2 * np.pi * 39 * t) + 40 * t
        ph = 2 * np.pi * np.cumsum(f) / SR
        tone = np.sin(ph) + 0.22 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
        tone *= 0.55 + 0.45 * trill
        breath = bandpass(g.noise(dur), 2200, 7000) * 0.18
        e = env_ar(dur, 0.012, 0.05, 1.2)
        return (tone + breath) * e

    add(buf, blow(0.16), 0.0, 0.8)
    add(buf, blow(0.62), 0.24, 1.0)
    finish("silbato", reverb(g, buf, 0.9, 0.2, 9000), "world")


def raqueta_golpe():
    """Raqueta: el "ping" de las cuerdas tensas (modos agudos breves) + el golpe de la pelota (thock)."""
    g = Gen(4006)
    buf = np.zeros(n_of(0.4))
    t = t_of(0.2)
    thock = np.sin(2 * np.pi * (300 + 200 * np.exp(-t / 0.004)) * t) * np.exp(-t / 0.018)
    strings = modal(g, 0.2, [(1050, 0.5, 0.035), (1730, 0.3, 0.02), (2600, 0.2, 0.012)])
    pop = bandpass(g.noise(0.2), 2500, 9000) * np.exp(-t / 0.003)
    add(buf, fft_filter(thock + strings + 0.5 * pop, lambda f: hp(f, 150, 2)), 0.0, 1.0)
    finish("raqueta_golpe", reverb(g, buf, 0.5, 0.18, 7000), "world")


def pesas_golpe():
    """Discos de pesas que chocan: hierro pesado (modos graves inarmónicos), traqueteo corto."""
    g = Gen(4007)
    buf = np.zeros(n_of(1.0))
    for at, a in ((0.0, 1.0), (0.045, 0.45), (0.11, 0.2)):
        hit = modal(g, 0.8, [(310, 1, 0.12), (742, 0.7, 0.09), (1310, 0.45, 0.06), (2210, 0.25, 0.035), (3570, 0.12, 0.02)], 0.02)
        hit[: n_of(0.004)] += transient(g, 0.004, 1500, 9000) * 0.8
        add(buf, hit, at, a)
    finish("pesas_golpe", reverb(g, buf, 0.7, 0.28, 5000), "world")


def estadio_ovacion():
    """Gol: ovación de grada. Cientos de voces (ruido con formantes de vocales "e"/"a" a distintas
    alturas, cada una con su arranque), que suben de golpe, y un "¡eeeh!" que se mantiene y baja."""
    g = Gen(4008)
    s = 3.6
    t = t_of(s)
    crowd = np.zeros(len(t))
    formants = [(730, 1090, 2440), (530, 1840, 2480), (660, 1700, 2400), (570, 840, 2410)]
    for k in range(70):
        f1, f2, f3 = formants[k % len(formants)]
        scale = g.u(0.85, 1.25)
        src = g.noise(s)
        # tono de la voz (pulsos glotales suavizados) mezclado con aire: grito colectivo
        f0 = g.u(140, 320)
        glott = np.sign(np.sin(2 * np.pi * f0 * (1 + 0.03 * np.sin(2 * np.pi * g.u(3, 6) * t)) * t)) * 0.5 + src * 0.6
        v = fft_filter(glott, lambda f, a=f1 * scale, b=f2 * scale, c=f3 * scale:
                       peak_eq(f, a, 3, 18) * peak_eq(f, b, 4, 14) * peak_eq(f, c, 5, 8) * lp(f, 4500, 2) * hp(f, 160, 2))
        start = g.u(0.0, 0.25)
        e = np.clip((t - start) / g.u(0.08, 0.25), 0, 1) * np.exp(-np.maximum(t - start - g.u(0.8, 1.6), 0) / g.u(0.6, 1.2))
        crowd += unit(v) * e * g.u(0.4, 1.0)
    # aplausos (impulsos densos de ruido)
    claps = np.zeros(len(t))
    for _ in range(600):
        at = g.u(0.3, 3.2)
        c = bandpass(g.noise(0.02), 900, 6000) * np.exp(-t_of(0.02) / 0.004)
        add(claps, c, at, g.u(0.2, 1.0) * np.exp(-(at - 0.3) / 1.8))
    sig = unit(crowd) + 0.35 * unit(claps)
    sig = reverb(g, sig, 1.8, 0.5, 5000)  # estadio abierto pero con grada
    finish("estadio_ovacion", sig, "world", fade_out=0.6)


# ---------------------------------------------------------------------------
# Mundo (bucles 3D/ambiente)
# ---------------------------------------------------------------------------

def grillos():
    """Grillos de noche: varios grillos (chirridos a ~4.2-4.9 kHz en ráfagas de 3-4 pulsos) a distintas
    distancias, más un fondo de insectos lejanos. Bucle de 8 s sin clic."""
    g = Gen(5001)
    length, fade = 8.0, 0.8
    s = length + fade
    buf = np.zeros(n_of(s))
    for k in range(7):
        f = g.u(4200, 4900)
        rate = g.u(1.4, 2.6)  # chirridos por segundo
        dist = g.u(0.15, 1.0)
        at = g.u(0, 0.5)
        while at < s:
            pulses = int(g.u(3, 5))
            for p in range(pulses):
                pd = 0.018
                tp = t_of(pd)
                chirp = np.sin(2 * np.pi * f * tp + g.u(0, 6)) * np.sin(np.pi * tp / pd) ** 2
                add(buf, chirp, at + p * 0.024, dist)
            at += 1 / rate * g.u(0.85, 1.15)
    bed = bandpass(g.noise(s), 3500, 7000) * 0.04
    sig = fft_filter(buf + bed, lambda f: lp(f, 7500, 2) * hp(f, 2000, 2))
    sig = reverb(g, sig, 0.8, 0.35, 6000)[: n_of(s)]
    finish("grillos", make_loop(sig, length, fade), "loop", loop=True)


def olas():
    """Olas en la orilla: rompiente (ruido rosa que sube y estalla, más claro en la cresta), resaca
    (ruido agudo que se retira con burbujas) y el rumor del mar de fondo. Bucle de 12 s."""
    g = Gen(5002)
    length, fade = 12.0, 1.5
    s = length + fade
    n = n_of(s)
    t = t_of(s)
    base = fft_filter(g.noise(s), lambda f: 1 / np.sqrt(np.maximum(f, 30)) * lp(f, 1200, 1) * hp(f, 40, 1))
    sig = unit(base) * 0.25
    for start, dur in ((0.4, 5.0), (5.6, 5.5), (10.2, 4.8)):
        seg = t_of(dur)
        crest = np.clip(seg / (dur * 0.35), 0, 1) ** 2 * np.exp(-np.maximum(seg - dur * 0.35, 0) / (dur * 0.25))
        x = g.noise(dur)
        fc = 400 + 3800 * crest
        wave = svf_sweep(x, fc, 0.7, "lp") * crest
        wash = bandpass(g.noise(dur), 1200, 5000) * np.clip((seg - dur * 0.4) / (dur * 0.2), 0, 1) * np.exp(-np.maximum(seg - dur * 0.55, 0) / (dur * 0.2))
        part = unit(wave) + 0.15 * unit(wash)
        i = n_of(start)
        idx = (np.arange(len(part)) + i) % n
        np.add.at(sig, idx, part * g.u(0.7, 1.0))
    sig = fft_filter(reverb(g, sig, 1.2, 0.25, 5000)[:n], lambda f: lp(f, 3000, 3))
    finish("olas", make_loop(sig, length, fade), "loop", loop=True)


ALL = [ui_toque, ui_seleccion, ui_abrir, ui_cerrar, movil_abrir, notificacion, error_suave,
       dinero, xp, nivel_sube, mision_empieza, mision_completa, logro, descubrimiento_fx, tension_golpe,
       caja_registradora, puerta_madera, coger_objeto,
       balon_patada, balon_bote, aro_rebote, red_swish, silbato, raqueta_golpe, pesas_golpe, estadio_ovacion,
       grillos, olas]


def report(names):
    print(f"\n{'archivo':22s} {'dur':>5s} {'pico':>6s} {'RMS act':>8s} {'centroide':>9s}")
    for name in names:
        x, sr = sf.read(OUT / f"{name}.ogg", dtype="float64")
        spec = np.abs(np.fft.rfft(x))
        f = np.fft.rfftfreq(len(x), 1 / sr)
        centroid = float(np.sum(f * spec) / (np.sum(spec) + 1e-12))
        w = n_of(0.02)
        fr = np.sqrt(np.mean(x[: len(x) // w * w].reshape(-1, w) ** 2, axis=1))
        act = fr[fr > fr.max() * 0.01]
        print(f"{name + '.ogg':22s} {len(x) / sr:5.2f} {20 * np.log10(np.max(np.abs(x))):6.1f} "
              f"{20 * np.log10(np.sqrt(np.mean(act ** 2))):8.1f} {centroid:8.0f}Hz")


if __name__ == "__main__":
    wanted = {a.removesuffix(".ogg") for a in sys.argv[1:]}
    unknown = wanted - {m.__name__ for m in ALL}
    if unknown:
        sys.exit(f"No conozco: {', '.join(sorted(unknown))}")
    done = []
    for make in ALL:
        if wanted and make.__name__ not in wanted:
            continue
        make()
        done.append(make.__name__)
        print(f"  {make.__name__}")
    report(done)
