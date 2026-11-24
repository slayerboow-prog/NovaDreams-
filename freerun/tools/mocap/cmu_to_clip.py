#!/usr/bin/env python3
"""Convierte capturas de movimiento del CMU Graphics Lab Motion Capture Database (ASF/AMC,
http://mocap.cs.cmu.edu, uso libre también comercial) en clips para el BodyRig del juego.

Para cada fotograma calcula, con cinemática directa, la posición de cada hueso de la captura y
de ahí la rotación LOCAL de cada articulación del BodyRig (pelvis, spine, neck, shoulder_*,
elbow_*, hip_*, knee_*) en su propio convenio (extremidades en reposo hacia -Y, delante = -Z,
rodilla = flexión en X negativa, codo = flexión en X positiva). Guarda también el giro acumulado
de la pelvis (para sincronizar la captura con el giro del mortal en el juego) y la altura.

Uso: cmu_to_clip.py sujeto.asf toma.amc salida.json [--start N] [--end N]
"""
import json, math, sys
import numpy as np

def rx(a):
    c, s = math.cos(a), math.sin(a); return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
def ry(a):
    c, s = math.cos(a), math.sin(a); return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
def rz(a):
    c, s = math.cos(a), math.sin(a); return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])
def euler_xyz(x, y, z):
    return rz(z) @ ry(y) @ rx(x)

def parse_asf(path):
    bones = {}
    hier = {}
    root_order = []
    lines = open(path).read().split("\n")
    i = 0
    section = ""
    cur = None
    while i < len(lines):
        ln = lines[i].strip()
        if ln.startswith(":"):
            section = ln.split()[0]
            if section == ":root":
                pass
        elif section == ":root" and ln.startswith("order"):
            root_order = ln.split()[1:]
        elif section == ":bonedata":
            if ln == "begin":
                cur = {"dof": []}
            elif ln == "end":
                bones[cur["name"]] = cur
                cur = None
            elif cur is not None:
                p = ln.split()
                if not p:
                    pass
                elif p[0] == "name":
                    cur["name"] = p[1]
                elif p[0] == "direction":
                    cur["dir"] = np.array([float(v) for v in p[1:4]])
                elif p[0] == "length":
                    cur["len"] = float(p[1])
                elif p[0] == "axis":
                    cur["axis"] = [math.radians(float(v)) for v in p[1:4]]
                elif p[0] == "dof":
                    cur["dof"] = p[1:]
        elif section == ":hierarchy":
            p = ln.split()
            if p and p[0] not in ("begin", "end"):
                hier[p[0]] = p[1:]
        i += 1
    for b in bones.values():
        b["C"] = euler_xyz(*b["axis"])
        b["Ci"] = b["C"].T
    return bones, hier, root_order

def parse_amc(path):
    frames = []
    cur = None
    for ln in open(path):
        ln = ln.strip()
        if not ln or ln.startswith("#") or ln.startswith(":"):
            continue
        p = ln.split()
        if p[0].isdigit() and len(p) == 1:
            cur = {}
            frames.append(cur)
        elif cur is not None:
            cur[p[0]] = [float(v) for v in p[1:]]
    return frames

def fk(bones, hier, root_order, fr):
    """Posiciones de inicio/fin de cada hueso y matriz global de la raíz."""
    rv = fr["root"]
    vals = dict(zip(root_order, rv))
    rot = euler_xyz(math.radians(vals.get("RX", 0)), math.radians(vals.get("RY", 0)), math.radians(vals.get("RZ", 0)))
    pos = np.array([vals.get("TX", 0), vals.get("TY", 0), vals.get("TZ", 0)])
    mats = {"root": rot}
    end = {"root": pos}
    start = {"root": pos}
    order = ["root"]
    k = 0
    while k < len(order):
        parent = order[k]
        for child in hier.get(parent, []):
            b = bones[child]
            ang = [0.0, 0.0, 0.0]
            if child in fr:
                for dof, v in zip(b["dof"], fr[child]):
                    ang["rx ry rz".split().index(dof)] = math.radians(v)
            R = euler_xyz(*ang)
            M = mats[parent] @ b["C"] @ R @ b["Ci"]
            mats[child] = M
            start[child] = end[parent]
            end[child] = end[parent] + b["len"] * (M @ b["dir"])
            order.append(child)
        k += 1
    return start, end, mats

def nrm(v):
    n = np.linalg.norm(v)
    return v / n if n > 1e-9 else v

def basis_from(y, z_hint):
    """Base (columnas X, Y, Z) con Y dado y Z lo más parecido posible a z_hint."""
    y = nrm(y)
    z = z_hint - np.dot(z_hint, y) * y
    if np.linalg.norm(z) < 1e-6:
        z = np.cross(np.array([1.0, 0, 0]), y)
    z = nrm(z)
    x = np.cross(y, z)
    return np.column_stack([x, y, z])

def quat(m):
    # matriz de rotación -> cuaternión (x, y, z, w)
    t = np.trace(m)
    if t > 0:
        s = math.sqrt(t + 1.0) * 2
        w = 0.25 * s; x = (m[2, 1] - m[1, 2]) / s; y = (m[0, 2] - m[2, 0]) / s; z = (m[1, 0] - m[0, 1]) / s
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = math.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
        w = (m[2, 1] - m[1, 2]) / s; x = 0.25 * s; y = (m[0, 1] + m[1, 0]) / s; z = (m[0, 2] + m[2, 0]) / s
    elif m[1, 1] > m[2, 2]:
        s = math.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
        w = (m[0, 2] - m[2, 0]) / s; x = (m[0, 1] + m[1, 0]) / s; y = 0.25 * s; z = (m[1, 2] + m[2, 1]) / s
    else:
        s = math.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
        w = (m[1, 0] - m[0, 1]) / s; x = (m[0, 2] + m[2, 0]) / s; y = (m[1, 2] + m[2, 1]) / s; z = 0.25 * s
    return [round(x, 5), round(y, 5), round(z, 5), round(w, 5)]

def limb(parent_basis_world, a, b, c, bend_sign):
    """Articulación de extremidad: segmento a→b, siguiente b→c. Devuelve (base local respecto al
    padre, ángulo de flexión). bend_sign: +1 la siguiente se dobla hacia +Z (rodilla), -1 hacia -Z (codo)."""
    u = nrm(b - a)
    f = nrm(c - b)
    perp = f - np.dot(f, u) * u
    if np.linalg.norm(perp) < 0.05:
        perp = parent_basis_world[:, 2] * bend_sign
    zb = nrm(perp) * bend_sign
    B = basis_from(-u, zb)
    ang = math.acos(max(-1.0, min(1.0, float(np.dot(u, f)))))
    return parent_basis_world.T @ B, ang

def convert(asf, amc, start=0, end=None):
    bones, hier, root_order = parse_asf(asf)
    frames = parse_amc(amc)[start:end]
    out = []
    prevP = None
    cum = 0.0
    for fr in frames:
        S, E, M = fk(bones, hier, root_order, fr)
        root = E["root"]
        lhip, rhip = E["lhipjoint"], E["rhipjoint"]
        lknee, rknee = E["lfemur"], E["rfemur"]
        lank, rank = E["ltibia"], E["rtibia"]
        chest = E["thorax"]
        head = E["head"]
        lsh, rsh = E["lclavicle"], E["rclavicle"]
        lel, rel = E["lhumerus"], E["rhumerus"]
        lwr, rwr = E["lradius"], E["rradius"]
        # Pelvis: Y arriba (hacia el pecho), X = derecha, Z = atrás
        left = nrm(lhip - rhip)
        P = basis_from(chest - root, np.cross(-left, nrm(chest - root)))
        # asegura X = derecha (−left)
        if np.dot(P[:, 0], -left) < 0:
            P[:, 0] *= -1; P[:, 2] *= -1
        # Tronco (spine): Y del pelvis al pecho, X por la línea de hombros
        sright = nrm(rsh - lsh)
        Sy = nrm(chest - root)
        Sb = basis_from(Sy, np.cross(sright, Sy))
        if np.dot(Sb[:, 0], sright) < 0:
            Sb[:, 0] *= -1; Sb[:, 2] *= -1
        Nb = basis_from(head - chest, Sb[:, 2])
        j = {}
        j["spine"] = quat(P.T @ Sb)
        j["neck"] = quat(Sb.T @ Nb)
        for sd, sh, el, wr, hp, kn, an in (("l", lsh, lel, lwr, lhip, lknee, lank), ("r", rsh, rel, rwr, rhip, rknee, rank)):
            sb, ea = limb(Sb, sh, el, wr, -1.0)
            j["shoulder_" + sd] = quat(sb)
            j["elbow_" + sd] = quat(rx(ea))
            hb, ka = limb(P, hp, kn, an, 1.0)
            j["hip_" + sd] = quat(hb)
            j["knee_" + sd] = quat(rx(-ka))
        # Giro acumulado de la pelvis alrededor de su eje lateral (mortal)
        if prevP is not None:
            dR = prevP.T @ P
            cum += math.atan2(dR[2, 1], dR[1, 1])
        prevP = P
        feet = min(lank[1], rank[1])
        out.append({"pitch": round(cum, 4), "h": round(float(root[1]), 3), "feet": round(float(feet), 3), "j": j})
    return out

if __name__ == "__main__":
    asf, amc, dst = sys.argv[1:4]
    args = sys.argv[4:]
    st = int(args[args.index("--start") + 1]) if "--start" in args else 0
    en = int(args[args.index("--end") + 1]) if "--end" in args else None
    clip = convert(asf, amc, st, en)
    json.dump({"source": "CMU Graphics Lab Motion Capture Database, " + amc.split("/")[-1], "fps": 120, "frames": clip}, open(dst, "w"))
    print(len(clip), "fotogramas")


def trim_flip(clip, prep_frames=36, land_frames=48, stand_h=None):
    """Recorta un mortal: preparación antes del despegue, vuelo y recepción. Marca los índices
    de despegue y aterrizaje (pies separados del suelo) y añade el descenso de cadera en metros."""
    fr = clip
    ground = sorted(f["feet"] for f in fr[:20])[10]
    air = [i for i, f in enumerate(fr) if f["feet"] > ground + 1.2]
    take = air[0]
    land = take
    for i in range(take, len(fr)):
        if fr[i]["feet"] <= ground + 1.0:
            land = i
            break
    hs = stand_h if stand_h else sorted(f["h"] for f in fr[:20])[10]
    a = max(0, take - prep_frames)
    b = min(len(fr), land + land_frames)
    out = []
    for f in fr[a:b]:
        g = dict(f)
        g["drop"] = round(max(0.0, (hs - f["h"]) / hs * 0.95), 3)
        out.append(g)
    return out, take - a, land - a

if __name__ == "__main__" and "--flip" in sys.argv:
    pass
