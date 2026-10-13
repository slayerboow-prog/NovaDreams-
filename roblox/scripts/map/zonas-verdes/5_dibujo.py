#!/usr/bin/env python3
"""Dibuja el mapa de las zonas verdes libres (vista desde arriba) y, encima del render del mapa grande,
los mismos números. Uso: render_map.py DIR PREVIEW.jpg OUT_TOP.png OUT_RENDER.png"""
import json, math, sys
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont

D, PREVIEW, OUT_TOP, OUT_RENDER = sys.argv[1:5]
S = 8.0; X0 = -5000; Z0 = -4400
FB = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
FR = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
font = lambda s, b=True: ImageFont.truetype(FB if b else FR, s)

zones = json.load(open(f'{D}/zones.json'))
zmask = np.load(f'{D}/zones.npy')
built = np.load(f'{D}/built.npy'); water = np.load(f'{D}/water.npy'); beach = np.load(f'{D}/beach.npy')
h = np.load(f'{D}/height.npy'); trees = np.load(f'{D}/trees.npy')
blocks = json.load(open(f'{D}/blocks.json'))
lm = json.load(open(f'{D}/landmarks.json'))
plan = json.load(open(f'{D}/plan.json'))

# Zona -> color según su prioridad (fase del plan)
PHASE = {21: 1, 17: 1, 20: 1, 7: 1, 16: 1, 19: 1, 11: 1,
         9: 2, 13: 2, 6: 2, 3: 2, 8: 2, 14: 2, 12: 2, 18: 2, 10: 2,
         2: 3, 5: 3, 1: 3, 4: 3, 15: 3, 22: 3}
PCOL = {1: (232, 86, 60), 2: (240, 170, 30), 3: (70, 130, 220)}

# Recorte a la isla
x0w, x1w, z0w, z1w = -4300, 4700, -4050, 3800
c0, c1 = int((x0w - X0) / S), int((x1w - X0) / S)
r0, r1 = int((z0w - Z0) / S), int((z1w - Z0) / S)
K = 2  # escala de salida (px por celda)
sl = (slice(r0, r1), slice(c0, c1))

def crop(a):
    return a[sl]

Hh, Ww = r1 - r0, c1 - c0
img = np.zeros((Hh, Ww, 3), np.uint8)
land = ~crop(water)
img[:] = (64, 140, 196)  # mar
img[land] = (196, 222, 160)
img[crop(beach) & land] = (238, 224, 180)
hh = crop(h)
hill = land & (hh > 4)
shade = np.clip(hh / 200, 0, 1)
img[hill] = (np.array([196, 222, 160]) * (1 - shade[hill, None] * 0.45) + np.array([120, 110, 90]) * shade[hill, None] * 0.45).astype(np.uint8)
lakes = crop(water) & np.zeros_like(crop(water))
img[crop(trees) & land & ~crop(built)] = (120, 170, 110)
img[crop(built)] = (168, 168, 172)
# Zonas: relleno con transparencia
zm = crop(zmask)
over = img.astype(np.float32)
for z in zones:
    m = zm == z['id']
    col = np.array(PCOL[PHASE[z['id']]], np.float32)
    over[m] = over[m] * 0.45 + col * 0.55
img = over.astype(np.uint8)
img = cv2.resize(img, (Ww * K, Hh * K), interpolation=cv2.INTER_NEAREST)
# Contornos
for z in zones:
    m = (zm == z['id']).astype(np.uint8)
    m = cv2.resize(m, (Ww * K, Hh * K), interpolation=cv2.INTER_NEAREST)
    cnts, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    col = tuple(int(c * 0.6) for c in PCOL[PHASE[z['id']]])
    cv2.drawContours(img, cnts, -1, col, 2)

pil = Image.fromarray(img)
dr = ImageDraw.Draw(pil)

def P(x, z):
    return ((x - X0) / S - c0) * K, ((z - Z0) / S - r0) * K

# Parques, huertas y pistas que ya existen (manzanas): cuadradito con letra
for b in blocks:
    a = P(b['x0'], b['z0']); c = P(b['x1'], b['z1'])
    col = {"Parque": (40, 120, 50), "Campo": (150, 110, 40), "Deporte": (40, 90, 170)}[b['kind']]
    dr.rectangle([a, c], outline=col, width=3)
    cx, cy = (a[0] + c[0]) / 2, (a[1] + c[1]) / 2
    dr.text((cx, cy), {"Parque": "P", "Campo": "H", "Deporte": "D"}[b['kind']], fill=col, font=font(20), anchor="mm")

# Lugares de referencia
REF = {"Granja": "Granjas", "CampoAnimales": "Campos de Valmar", "Camping": "Camping", "Feria": "Parque de Atracciones",
       "Puerto": "Puerto", "Marina": "Puerto Deportivo", "Mirador": "Mirador", "Playa": "Playa Dorada", "Protectora": "Protectora",
       "Facultad": "Universidad", "Estadio": "Estadio", "Aeropuerto": "Aeropuerto", "Plaza": "Plaza Mayor", "ZonaPesca": "Pesca",
       "CentroPenitenciario": "Prisión", "CuartelEjercito": "Cuartel", "Colegio": "Colegio"}
seen = set()
for p in lm:
    if p['Kind'] in REF:
        name = REF[p['Kind']]
        x, y = P(p['X'], p['Z'])
        if p['Kind'] == 'Mirador' and p['Z'] > -2500:
            continue
        dr.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(30, 30, 40), outline=(255, 255, 255), width=2)
        dr.text((x + 9, y), name, fill=(20, 20, 30), font=font(17, False), anchor="lm", stroke_width=3, stroke_fill=(255, 255, 255))
# Barrios de la historia
for name, (x, z) in {"Valmar Centro": (0, 0), "Distrito Financiero": (0, -800), "Valmar Norte": (-700, -1900), "Los Pinos": (700, -1900),
                     "Villaverde": (-2700, -1850), "Playa Dorada": (3550, -1000), "Campus Valmar": (2650, 1300), "San Roque": (-650, 2250)}.items():
    px_, py_ = P(x, z)
    dr.text((px_, py_ - 40), name.upper(), fill=(70, 70, 90), font=font(19), anchor="mm", stroke_width=3, stroke_fill=(235, 235, 235))
for name, (x, z) in {"Lago del Parque Natural": (-2750, -520), "Lago de Montaña": (-1500, -2950), "Río de Valmar": (1500, 300)}.items():
    px_, py_ = P(x, z)
    dr.text((px_, py_), name, fill=(10, 50, 110), font=font(17), anchor="mm", stroke_width=3, stroke_fill=(255, 255, 255))

# Números de las zonas
LABEL_AT = {11: (1380, -1000), 3: (-300, -3150), 2: (-2300, -3000), 5: (2500, -2900), 4: (1050, -3100), 1: (-3650, -1650),
            6: (3950, 350), 21: (0, -250), 22: (2900, 2000)}
for z in zones:
    x, zz = LABEL_AT.get(z['id'], (z['best'][0], z['best'][1]))
    px_, py_ = P(x, zz)
    col = PCOL[PHASE[z['id']]]
    r = 22
    dr.ellipse([px_ - r, py_ - r, px_ + r, py_ + r], fill=(255, 255, 255), outline=tuple(int(c * 0.7) for c in col), width=5)
    dr.text((px_, py_), str(z['id']), fill=(20, 20, 30), font=font(24), anchor="mm")

# Leyenda y título
W2, H2 = pil.size
pad = 26
legend_h = 500
canvas = Image.new("RGB", (W2, H2 + legend_h), (250, 250, 247))
canvas.paste(pil, (0, legend_h))
d2 = ImageDraw.Draw(canvas)
d2.text((pad, 20), "Valmar · zonas verdes libres (medidas en la ciudad construida)", fill=(20, 20, 30), font=font(40))
d2.text((pad, 74), "Vista desde arriba, norte arriba. 1 cuadro del mapa = 8 studs. Libre = tierra sin calles, manzanas, edificios, agua ni playa (con 16 studs de margen) y de al menos 64 studs de ancho.",
        fill=(60, 60, 70), font=font(19, False))
y = 116
for ph, txt in ((1, "Fase 1 · primero (barato y cerca de la gente)"), (2, "Fase 2 · después"), (3, "Fase 3 · campo y montes (más adelante)")):
    d2.rectangle([pad, y, pad + 34, y + 26], fill=PCOL[ph], outline=(60, 60, 60))
    d2.text((pad + 46, y + 13), txt, fill=(20, 20, 30), font=font(21), anchor="lm")
    y += 38
x2 = 760
y = 116
for letter, col, txt in (("P", (40, 120, 50), "Parque que ya existe (manzana)"), ("H", (150, 110, 40), "Huerta que ya existe (manzana)"), ("D", (40, 90, 170), "Pista deportiva que ya existe")):
    d2.rectangle([x2, y, x2 + 30, y + 26], outline=col, width=3)
    d2.text((x2 + 15, y + 13), letter, fill=col, font=font(18), anchor="mm")
    d2.text((x2 + 44, y + 13), txt, fill=(20, 20, 30), font=font(21), anchor="lm")
    y += 38
x3 = 1450; y = 116
d2.rectangle([x3, y, x3 + 30, y + 26], fill=(168, 168, 172)); d2.text((x3 + 44, y + 13), "Construido (calles, manzanas, edificios)", fill=(20, 20, 30), font=font(21), anchor="lm")
# Lista de zonas (tres columnas)
col_w = (W2 - 2 * pad) // 3
for i, z in enumerate(zones):
    cx_ = pad + 16 + (i // 8) * col_w
    cy_ = 250 + (i % 8) * 30
    d2.text((cx_, cy_), f"{z['id']}. {z['name']} · {z['area'] / 1e6:.2f} M studs²", fill=PCOL[PHASE[z['id']]] if False else (30, 30, 40), font=font(20, False))
    d2.rectangle([cx_ - 14, cy_ + 5, cx_ - 4, cy_ + 15], fill=PCOL[PHASE[z['id']]])
canvas.save(OUT_TOP, optimize=True)
print("top", canvas.size)

# ---- Sobre el render del mapa grande (vista inclinada 52°) ----
TILT, ORTHO_W, CX, CS = 52.0, 10600.0, 50.0, 330.0
rim = Image.open(PREVIEW).convert("RGB")
RW, RH = rim.size
def project(x, yv, z):
    t = math.radians(TILT)
    spp = ORTHO_W / RW
    s = -z * math.cos(t) + yv * math.sin(t)
    return (x - CX) / spp + RW / 2, RH / 2 - (s - CS) / spp
ov = Image.new("RGBA", rim.size, (0, 0, 0, 0))
do = ImageDraw.Draw(ov)
for z in zones:
    m = (zmask == z['id']).astype(np.uint8)
    cnts, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    col = PCOL[PHASE[z['id']]]
    for c in cnts:
        pts = []
        for (u, v) in c[:, 0, :]:
            wx, wz = X0 + (u + 0.5) * S, Z0 + (v + 0.5) * S
            pts.append(project(wx, max(0, float(h[v, u])) * 2.0, wz))
        if len(pts) > 2:
            do.polygon(pts, fill=col + (70,), outline=col + (255,))
for z in zones:
    x, zz = LABEL_AT.get(z['id'], (z['best'][0], z['best'][1]))
    v, u = int((zz - Z0) / S), int((x - X0) / S)
    px_, py_ = project(x, max(0, float(h[v, u])) * 2.0, zz)
    r = 15
    do.ellipse([px_ - r, py_ - r, px_ + r, py_ + r], fill=(255, 255, 255, 235), outline=PCOL[PHASE[z['id']]] + (255,), width=4)
    do.text((px_, py_), str(z['id']), fill=(20, 20, 30, 255), font=font(17), anchor="mm")
out = Image.alpha_composite(rim.convert("RGBA"), ov).convert("RGB")
out.save(OUT_RENDER, quality=90)
print("render", out.size)
