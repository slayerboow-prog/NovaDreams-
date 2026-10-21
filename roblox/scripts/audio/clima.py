"""Sonidos del tiempo de Valmar (v126, docs/clima/estaciones.md): variantes de lluvia, truenos y viento.

Como sfx.py y zonas.py: síntesis (ruido filtrado, gotas, golpes), todo 100 % nuestro y sin derechos de
nadie. Los usa client/Controllers/Weather (lluvia y viento) y Controllers/Relampagos (truenos); si aún no
están subidos (SoundIds), suenan los de siempre (lluvia, trueno, viento).

Uso (desde roblox/):   python3 scripts/audio/clima.py             (todos)
                       python3 scripts/audio/clima.py trueno_cerca (solo ese)
Subir:                 bash scripts/upload-audio.sh --clima      (solo estos)
Necesita:              pip install numpy soundfile

Archivos (audio/sfx, mono, 44.1 kHz, ogg vorbis):
  lluvia_suave.ogg     llovizna: siseo fino y gotitas sueltas                    · bucle 6 s
  lluvia_fuerte.ogg    chaparrón: cortina densa, más grave y gotas gordas        · bucle 6 s
  lluvia_tejado.ogg    lluvia en un tejado o un toldo: tamborileo apagado        · bucle 6 s
  lluvia_coche.ogg     dentro del coche: golpeteo en el techo de chapa, sordo    · bucle 6 s
  trueno_cerca.ogg     rayo cerca: «crac» seco y estampido que retumba           5 s
  trueno_lejos.ogg     trueno lejano: retumbar grave, sin crac                    6 s
  viento_tormenta.ogg  viento de tormenta: rachas fuertes que van y vienen        · bucle 8 s
"""

import sys
from pathlib import Path

import numpy as np
import soundfile as sf

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import sfx as S  # noqa: E402  (ruidos, filtros, gotas y bucles de los efectos)

SR = S.SR


def norm(x: np.ndarray) -> np.ndarray:
    return x / (np.std(x) + 1e-9)


def drops(total: float, per_second: float, big_share: float, lo: float = 0.2) -> np.ndarray:
    buf = np.zeros(S.n_of(total))
    for _ in range(int(total * per_second)):
        big = S.RNG.uniform() < big_share
        S.add_at(buf, S.drop_sound(big) * S.RNG.uniform(lo, 1), S.RNG.uniform(0, total), wrap=True)
    return norm(buf)


def lluvia_suave():
    S._seed(301)
    length, fade = 6.0, 0.6
    total = length + fade
    bed = norm(S.band(S.pink(total), 1200, 10000, pad=False))
    sig = 0.55 * bed + 0.6 * drops(total, 90, 0.02)
    sig = S.spectral(sig, lambda f: S.lowpass_gain(f, 6500, 2) * S.highpass_gain(f, 500))
    S.write("lluvia_suave.ogg", S.make_loop(sig, length, fade), loop=True)


def lluvia_fuerte():
    S._seed(302)
    length, fade = 6.0, 0.6
    total = length + fade
    t = S.t_of(total)
    bed = norm(S.band(S.pink(total), 250, 7000, pad=False))
    roar = norm(S.band(S.brown(total), 120, 900, pad=False))
    swell = 1 + 0.12 * np.sin(2 * np.pi * t / 3.3)
    sig = (bed + 0.45 * roar) * swell + 0.4 * drops(total, 420, 0.06)
    sig = S.spectral(sig, lambda f: S.lowpass_gain(f, 4800, 2) * S.highpass_gain(f, 120))
    S.write("lluvia_fuerte.ogg", S.make_loop(sig, length, fade), loop=True)


def knock(strength: float, bright: float) -> np.ndarray:
    """Una gota que golpea algo duro (tejado, toldo, chapa): golpecito corto y apagado."""
    d = S.RNG.uniform(0.015, 0.035)
    t = S.t_of(d)
    hit = S.RNG.normal(0, 1, len(t)) * np.exp(-t / (d / 5))
    return S.band(hit, 200, bright) * strength


def tapping(total: float, per_second: float, bright: float) -> np.ndarray:
    buf = np.zeros(S.n_of(total))
    for _ in range(int(total * per_second)):
        S.add_at(buf, knock(S.RNG.uniform(0.2, 1), bright), S.RNG.uniform(0, total), wrap=True)
    return norm(buf)


def lluvia_tejado():
    S._seed(303)
    length, fade = 6.0, 0.6
    total = length + fade
    bed = norm(S.band(S.pink(total), 200, 3500, pad=False))
    sig = 0.5 * bed + 0.85 * tapping(total, 340, 2600)
    sig = S.spectral(sig, lambda f: S.lowpass_gain(f, 2800, 2) * S.highpass_gain(f, 90))
    S.write("lluvia_tejado.ogg", S.make_loop(sig, length, fade), loop=True)


def lluvia_coche():
    S._seed(304)
    length, fade = 6.0, 0.6
    total = length + fade
    t = S.t_of(total)
    # golpeteo en la chapa del techo (sordo y con algo de cuerpo) y el rumor del agua en el cristal
    taps = tapping(total, 260, 1800)
    body = S.spectral(taps, lambda f: 1 + 1.4 / (1 + ((f - 320) / 90) ** 2))  # resonancia de la chapa
    hum = norm(S.band(S.brown(total), 60, 400, pad=False))
    sig = norm(body) + 0.35 * hum * (1 + 0.1 * np.sin(2 * np.pi * t / 6))
    sig = S.spectral(sig, lambda f: S.lowpass_gain(f, 1600, 2) * S.highpass_gain(f, 60))
    S.write("lluvia_coche.ogg", S.make_loop(sig, length, fade), loop=True)


def thunder(total: float, crack: float, rolls, cutoff: float, decay: float) -> np.ndarray:
    t = S.t_of(total)
    c = S.band(S.noise(total), 400, 6000) * np.exp(-t / 0.05) * np.clip(t / 0.004, 0, 1)
    c /= np.max(np.abs(c)) + 1e-9
    rumble = norm(S.band(S.brown(total), 22, 260))
    env = np.zeros(len(t))
    for start, amp, width in rolls:
        env += amp * np.exp(-(((t - start - width / 2) / (width / 2)) ** 2))
    env = env * np.exp(-t / decay) + 0.12 * np.exp(-t / (decay * 0.8))
    sig = crack * c + rumble * env
    sig = S.spectral(sig, lambda f: S.lowpass_gain(f, cutoff, 2))
    return sig * S.adsr(len(t), 0.003, 0.8)


def trueno_cerca():
    S._seed(305)
    sig = thunder(5.0, 0.9, ((0.0, 1.0, 0.35), (0.3, 0.9, 0.5), (0.9, 0.6, 0.7), (1.7, 0.4, 1.0)), 3200, 1.9)
    S.write("trueno_cerca.ogg", sig, loop=False)


def trueno_lejos():
    S._seed(306)
    sig = thunder(6.0, 0.0, ((0.2, 0.6, 1.0), (1.1, 0.9, 1.2), (2.3, 0.6, 1.4), (3.6, 0.35, 1.6)), 700, 2.6)
    S.write("trueno_lejos.ogg", sig, loop=False)


def viento_tormenta():
    S._seed(307)
    length, fade = 8.0, 0.8
    total = length + fade
    t = S.t_of(total)
    base = S.noise(total)
    # rachas fuertes que dan vueltas enteras en 8 s (el bucle empalma solo)
    gust = 0.45 + 0.3 * np.sin(2 * np.pi * t / 8 + 1.1) + 0.2 * np.sin(2 * np.pi * 2 * t / 8 + 0.4) + 0.12 * np.sin(2 * np.pi * 7 * t / 8)
    g = (gust - gust.min()) / (gust.max() - gust.min())
    low = norm(S.band(base, 40, 300, pad=False))
    mid = norm(S.band(base, 250, 1200, pad=False))
    howl = norm(S.spectral(base, lambda f: 1 / (1 + ((f - 520) / 40) ** 2) + 0.7 / (1 + ((f - 880) / 70) ** 2), pad=False))
    sig = low * (0.7 + 0.3 * g) + mid * 0.7 * g + howl * 0.35 * g**2
    sig *= 0.6 + 0.6 * g
    S.write("viento_tormenta.ogg", S.make_loop(sig, length, fade), loop=True)


TODOS = (lluvia_suave, lluvia_fuerte, lluvia_tejado, lluvia_coche, trueno_cerca, trueno_lejos, viento_tormenta)

if __name__ == "__main__":
    wanted = {a.removesuffix(".ogg") for a in sys.argv[1:]}
    known = {f.__name__ for f in TODOS}
    unknown = wanted - known
    if unknown:
        sys.exit(f"No conozco: {', '.join(sorted(unknown))}")
    print("Sonidos del tiempo en audio/sfx")
    for make in TODOS:
        if not wanted or make.__name__ in wanted:
            make()
            path = S.OUT / f"{make.__name__}.ogg"
            print(f"  {path.name:22s} {sf.info(path).duration:5.1f} s  {path.stat().st_size // 1024:4d} KB")
    print("Listo.")
