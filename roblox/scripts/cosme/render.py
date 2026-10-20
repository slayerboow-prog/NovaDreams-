#!/usr/bin/env python3
"""Hoja de vista previa de Cosme (docs/cosme/cosme-hoja.png): delante, detrás y de lado, en pose de
héroe, y sus 4 caras. Dibuja las piezas de verdad de shared/CosmeLook (exportadas con
scripts/cosme/export.luau) con un rasterizador pequeño (numpy): bloques, cuñas, cilindros, bolas y la
cabeza clásica redondeada, con las caras (assets/cosme/cosme_face_*.png) y la ropa clásica
(cosme_shirt.png / cosme_pants.png) puestas como en Roblox, luz de estudio, neón con resplandor y
sombra en el suelo.

Uso (desde roblox/):
    lune run scripts/cosme/export.luau
    python3 scripts/cosme/render.py [scripts/cosme/out/cosme.json] [docs/cosme/cosme-hoja.png]
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ASSETS = os.path.join(ROOT, "assets", "cosme")
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_IT = "/usr/share/fonts/truetype/freefont/FreeSansBoldOblique.ttf"


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


# ---------------------------------------------------------------------------
# Texturas
# ---------------------------------------------------------------------------


def load_rgba(name):
    path = os.path.join(ASSETS, name + ".png")
    if not os.path.exists(path):
        return None
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.float32) / 255.0


SHIRT = load_rgba("cosme_shirt")
PANTS = load_rgba("cosme_pants")
FACES = {k: load_rgba("cosme_face_" + k) for k in ("grin", "skeptic", "laugh", "scared")}

TORSO = {"U": (231, 8, 128, 64), "F": (231, 74, 128, 128), "R": (165, 74, 64, 128), "L": (361, 74, 64, 128), "B": (427, 74, 128, 128), "D": (231, 204, 128, 64)}
RIGHT = {"L": (19, 355, 64, 128), "B": (85, 355, 64, 128), "R": (151, 355, 64, 128), "F": (217, 355, 64, 128), "U": (217, 289, 64, 64), "D": (217, 485, 64, 64)}
LEFT = {"F": (308, 355, 64, 128), "L": (374, 355, 64, 128), "B": (440, 355, 64, 128), "R": (506, 355, 64, 128), "U": (308, 289, 64, 64), "D": (308, 485, 64, 64)}

# Qué trozo de la plantilla va a cada pieza R15 (en vertical, por proporción de alturas)
ARM = (1.17, 1.05, 0.3)
LEG = (1.22, 1.19, 0.3)


def slices(parts):
    total = sum(parts)
    out, acc = [], 0.0
    for p in parts:
        out.append((acc / total, (acc + p) / total))
        acc += p
    return out


ARM_S = slices(ARM)
LEG_S = slices(LEG)
CLOTH = {
    "UpperTorso": (SHIRT, TORSO, (0.0, 0.8)),
    "LowerTorso": (PANTS, TORSO, (0.8, 1.0)),
    "RightUpperArm": (SHIRT, RIGHT, ARM_S[0]),
    "RightLowerArm": (SHIRT, RIGHT, ARM_S[1]),
    "RightHand": (SHIRT, RIGHT, ARM_S[2]),
    "LeftUpperArm": (SHIRT, LEFT, ARM_S[0]),
    "LeftLowerArm": (SHIRT, LEFT, ARM_S[1]),
    "LeftHand": (SHIRT, LEFT, ARM_S[2]),
    "RightUpperLeg": (PANTS, RIGHT, LEG_S[0]),
    "RightLowerLeg": (PANTS, RIGHT, LEG_S[1]),
    "RightFoot": (PANTS, RIGHT, LEG_S[2]),
    "LeftUpperLeg": (PANTS, LEFT, LEG_S[0]),
    "LeftLowerLeg": (PANTS, LEFT, LEG_S[1]),
    "LeftFoot": (PANTS, LEFT, LEG_S[2]),
}

# ---------------------------------------------------------------------------
# Mallas (en coordenadas de la pieza; tamaño ya aplicado)
# Cada triángulo: (3 posiciones, 3 normales, 3 uv o None, clave de cara)
# ---------------------------------------------------------------------------

FACE_DIRS = {
    "R": (np.array([1, 0, 0]), np.array([0, 0, -1])),  # (normal, «derecha» de quien la mira)
    "L": (np.array([-1, 0, 0]), np.array([0, 0, 1])),
    "U": (np.array([0, 1, 0]), np.array([-1, 0, 0])),
    "D": (np.array([0, -1, 0]), np.array([-1, 0, 0])),
    "B": (np.array([0, 0, 1]), np.array([1, 0, 0])),
    "F": (np.array([0, 0, -1]), np.array([-1, 0, 0])),
}


def box_mesh(size, sub=1):
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    h = np.array([hx, hy, hz])
    tris = []
    for key, (n, right) in FACE_DIRS.items():
        n = n.astype(float)
        right = right.astype(float)
        # «arriba» en la plantilla: +Y en los lados; la cara U tiene detrás arriba y la D, delante
        up = np.array([0, 0, 1.0]) if key == "U" else np.array([0, 0, -1.0]) if key == "D" else np.array([0, 1.0, 0])
        center = n * h
        ex = right * h
        ey = up * h
        ex = np.abs(ex).sum() * right
        ey = np.abs(ey).sum() * up
        for i in range(sub):
            for j in range(sub):
                u0, u1 = i / sub, (i + 1) / sub
                v0, v1 = j / sub, (j + 1) / sub

                def pt(u, v):
                    return center + ex * (2 * u - 1) + ey * (1 - 2 * v)

                a, b, c, d = pt(u0, v0), pt(u1, v0), pt(u1, v1), pt(u0, v1)
                ua, ub, uc, ud = (u0, v0), (u1, v0), (u1, v1), (u0, v1)
                tris.append(([a, b, c], [n, n, n], [ua, ub, uc], key))
                tris.append(([a, c, d], [n, n, n], [ua, uc, ud], key))
    return tris


def wedge_mesh(size):
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    v = {
        "bl0": np.array([-hx, -hy, -hz]), "bl1": np.array([-hx, -hy, hz]), "tl": np.array([-hx, hy, hz]),
        "br0": np.array([hx, -hy, -hz]), "br1": np.array([hx, -hy, hz]), "tr": np.array([hx, hy, hz]),
    }
    tris = []

    centroid = np.array([0, -hy / 3, hz / 3])

    def outward(n, p):
        n = n / (np.linalg.norm(n) + 1e-9)
        return n if np.dot(n, p - centroid) > 0 else -n

    def quad(a, b, c, d):
        n = outward(np.cross(v[b] - v[a], v[c] - v[a]), (v[a] + v[c]) / 2)
        tris.append(([v[a], v[b], v[c]], [n] * 3, None, "W"))
        tris.append(([v[a], v[c], v[d]], [n] * 3, None, "W"))

    def tri(a, b, c):
        n = outward(np.cross(v[b] - v[a], v[c] - v[a]), (v[a] + v[b] + v[c]) / 3)
        tris.append(([v[a], v[b], v[c]], [n] * 3, None, "W"))

    quad("bl0", "br0", "br1", "bl1")  # abajo
    quad("bl1", "br1", "tr", "tl")  # detrás
    quad("bl0", "tl", "tr", "br0")  # la cuesta
    tri("bl0", "bl1", "tl")
    tri("br0", "tr", "br1")
    return tris


def cylinder_mesh(size, seg=28):
    L = size[0]
    r = min(size[1], size[2]) / 2
    tris = []
    for i in range(seg):
        a0 = 2 * math.pi * i / seg
        a1 = 2 * math.pi * (i + 1) / seg
        p = [np.array([x, r * math.cos(a), r * math.sin(a)]) for x, a in ((-L / 2, a0), (L / 2, a0), (L / 2, a1), (-L / 2, a1))]
        n0 = np.array([0, math.cos(a0), math.sin(a0)])
        n1 = np.array([0, math.cos(a1), math.sin(a1)])
        tris.append(([p[0], p[1], p[2]], [n0, n0, n1], None, "S"))
        tris.append(([p[0], p[2], p[3]], [n0, n1, n1], None, "S"))
        for x, sign in ((L / 2, 1), (-L / 2, -1)):
            c = np.array([x, 0, 0])
            q0 = np.array([x, r * math.cos(a0), r * math.sin(a0)])
            q1 = np.array([x, r * math.cos(a1), r * math.sin(a1)])
            n = np.array([sign, 0, 0.0])
            tris.append(([c, q0, q1], [n] * 3, None, "C"))
    return tris


def sphere_mesh(size, seg=20, rings=12):
    r = min(size) / 2
    tris = []

    def pt(i, j):
        th = math.pi * j / rings
        ph = 2 * math.pi * i / seg
        n = np.array([math.sin(th) * math.cos(ph), math.cos(th), math.sin(th) * math.sin(ph)])
        return n * r, n

    for j in range(rings):
        for i in range(seg):
            a, na = pt(i, j)
            b, nb = pt(i + 1, j)
            c, nc = pt(i + 1, j + 1)
            d, nd = pt(i, j + 1)
            tris.append(([a, b, c], [na, nb, nc], None, "S"))
            tris.append(([a, c, d], [na, nc, nd], None, "S"))
    return tris


def head_mesh(size, seg=40):
    """La cabeza clásica: un cilindro achatado (sección de supercírculo) con los bordes redondeados."""
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    bevel = 0.22 * hy
    rows = []
    for k in range(7):
        a = (math.pi / 2) * k / 6  # 0 = arriba del todo
        rows.append((hy - bevel + bevel * math.cos(a), 1 - 0.22 + 0.22 * math.sin(a)))
    rows += [(-y, s) for y, s in reversed(rows)]

    def ring(y, s):
        pts = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            c, sn = math.cos(a), math.sin(a)
            e = 0.55  # supercírculo (más cuadrado que un círculo)
            x = hx * s * np.sign(c) * abs(c) ** e
            z = hz * s * np.sign(sn) * abs(sn) ** e
            pts.append(np.array([x, y, z]))
        return pts

    grid = [ring(y, s) for y, s in rows]
    # normales por vértice (media de las caras)
    verts = {}
    tris_idx = []
    for j in range(len(grid) - 1):
        for i in range(seg):
            a, b, c, d = (j, i), (j, (i + 1) % seg), (j + 1, (i + 1) % seg), (j + 1, i)
            tris_idx.append((a, b, c))
            tris_idx.append((a, c, d))
    normals = {}
    for t in tris_idx:
        p = [grid[k[0]][k[1]] for k in t]
        n = np.cross(p[1] - p[0], p[2] - p[0])
        for k in t:
            normals[k] = normals.get(k, 0) + n
    tris = []
    for t in tris_idx:
        p = [grid[k[0]][k[1]] for k in t]
        ns = []
        for k in t:
            n = normals[k]
            n = n / (np.linalg.norm(n) + 1e-9)
            ns.append(n)
        uv = [(0.5 - q[0] / size[0], 0.5 - q[1] / size[1]) for q in p]
        tris.append((p, ns, uv, "H"))
    # tapas
    for y, sign in ((rows[0][0], 1), (rows[-1][0], -1)):
        r0 = grid[0] if sign > 0 else grid[-1]
        c = np.array([0, y, 0])
        n = np.array([0, sign, 0.0])
        for i in range(seg):
            tris.append(([c, r0[i], r0[(i + 1) % seg]], [n] * 3, None, "C"))
    return tris


# ---------------------------------------------------------------------------
# Rasterizador
# ---------------------------------------------------------------------------

MATERIAL = {
    "SmoothPlastic": (0.18, 30),
    "Plastic": (0.15, 20),
    "Fabric": (0.03, 8),
    "Metal": (0.55, 40),
    "Leather": (0.22, 18),
    "Wood": (0.08, 10),
    "Glass": (0.8, 60),
    "Neon": (0.0, 1),
}


def normalize(v):
    return v / (np.linalg.norm(v, axis=-1, keepdims=True) + 1e-9)


class Camera:
    def __init__(self, eye, target, fov, w, h):
        self.eye = np.array(eye, float)
        f = normalize(np.array(target, float) - self.eye)
        r = normalize(np.cross(f, [0, 1, 0]))
        u = np.cross(r, f)
        self.f, self.r, self.u = f, r, u
        self.w, self.h = w, h
        self.scale = (h / 2) / math.tan(math.radians(fov) / 2)

    def project(self, p):
        d = p - self.eye
        z = d @ self.f
        x = d @ self.r
        y = d @ self.u
        sx = self.w / 2 + x / z * self.scale
        sy = self.h / 2 - y / z * self.scale
        return np.stack([sx, sy, z], axis=-1)


LIGHTS = [
    (normalize(np.array([-0.55, 0.75, -0.6])), np.array([1.0, 0.97, 0.92]) * 0.85),  # principal
    (normalize(np.array([0.8, 0.25, -0.35])), np.array([0.65, 0.78, 1.0]) * 0.32),  # relleno frío
    (normalize(np.array([0.2, 0.9, 0.6])), np.array([0.6, 0.8, 1.0]) * 0.18),  # cenital frío
]
RIM = np.array([0.55, 0.8, 1.0]) * 0.45


def shade(base, n, view, spec, shin):
    sky = np.array([0.55, 0.62, 0.78])
    ground = np.array([0.3, 0.27, 0.26])
    t = (n[..., 1:2] * 0.5 + 0.5)
    col = base * (ground * (1 - t) + sky * t) * 0.8
    for ldir, lcol in LIGHTS:
        diff = np.clip(n @ ldir, 0, 1)[..., None]
        col = col + base * diff * lcol
        h = normalize(ldir + view)
        s = np.clip((n * h).sum(-1), 0, 1)[..., None] ** shin
        col = col + spec * s * lcol
    # borde de luz (como un contraluz de estudio, sin teñir de azul toda la espalda)
    fres = np.clip(1 - (n * view).sum(-1), 0, 1)[..., None] ** 3
    return col + fres * RIM


def render(parts, cam, face=None, ss=2, transparent_bg=True):
    W, H = cam.w, cam.h
    depth = np.full((H, W), np.inf, np.float32)
    color = np.zeros((H, W, 3), np.float32)
    emit = np.zeros((H, W, 3), np.float32)
    ids = np.full((H, W), -1, np.int32)
    glass = []
    for pid, part in enumerate(parts):
        size = part["Size"]
        shape = part["Shape"]
        name = part["Name"]
        if part.get("Transparency", 0) >= 0.99:
            continue
        if name == "Head":
            mesh = head_mesh(size)
        elif shape == "Wedge":
            mesh = wedge_mesh(size)
        elif shape == "Cylinder":
            mesh = cylinder_mesh(size)
        elif shape == "Ball":
            mesh = sphere_mesh(size)
        else:
            mesh = box_mesh(size, 4 if part["Body"] else 1)
        if shape != "Wedge":
            fixed = []
            for (pts, ns, uvs, key) in mesh:
                ns = [n if np.dot(n, p) >= 0 else -n for n, p in zip(ns, pts)]
                fixed.append((pts, ns, uvs, key))
            mesh = fixed
        R = np.array(part["Rot"], float).reshape(3, 3)
        P = np.array(part["Pos"], float)
        base = np.array(part["Color"], float) / 255.0
        mat = part["Material"]
        spec, shin = MATERIAL.get(mat, (0.15, 20))
        neon = mat == "Neon"
        is_glass = mat == "Glass" or part.get("Transparency", 0) > 0.4
        cloth = CLOTH.get(name) if part["Body"] else None
        for (pts, ns, uvs, key) in mesh:
            wp = np.array([R @ p + P for p in pts])
            wn = np.array([R @ n for n in ns])
            sp = cam.project(wp)
            if np.any(sp[:, 2] <= 0.1):
                continue
            # descarta las caras de espaldas (la normal plana)
            e1 = sp[1, :2] - sp[0, :2]
            e2 = sp[2, :2] - sp[0, :2]
            area = e1[0] * e2[1] - e1[1] * e2[0]
            if abs(area) < 1e-6:
                continue
            fn = wn.sum(axis=0)
            if np.dot(fn, wp.mean(axis=0) - cam.eye) >= 0 and not is_glass:
                continue
            x0 = max(int(math.floor(sp[:, 0].min())), 0)
            x1 = min(int(math.ceil(sp[:, 0].max())), W - 1)
            y0 = max(int(math.floor(sp[:, 1].min())), 0)
            y1 = min(int(math.ceil(sp[:, 1].max())), H - 1)
            if x1 < x0 or y1 < y0:
                continue
            xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            w0 = ((sp[1, 0] - xs) * (sp[2, 1] - ys) - (sp[2, 0] - xs) * (sp[1, 1] - ys)) / area
            w1 = ((sp[2, 0] - xs) * (sp[0, 1] - ys) - (sp[0, 0] - xs) * (sp[2, 1] - ys)) / area
            w2 = 1 - w0 - w1
            inside = (w0 >= -1e-4) & (w1 >= -1e-4) & (w2 >= -1e-4)
            if not inside.any():
                continue
            z = w0 * sp[0, 2] + w1 * sp[1, 2] + w2 * sp[2, 2]
            sub = depth[y0 : y1 + 1, x0 : x1 + 1]
            mask = inside & (z < sub)
            if not mask.any():
                continue
            n = normalize(w0[..., None] * wn[0] + w1[..., None] * wn[1] + w2[..., None] * wn[2])
            wpos = w0[..., None] * wp[0] + w1[..., None] * wp[1] + w2[..., None] * wp[2]
            view = normalize(cam.eye - wpos)
            col = np.broadcast_to(base, n.shape).copy()
            if uvs is not None and (cloth is not None and cloth[0] is not None and key in "FBLRUD") :
                tex, rects, (s0, s1) = cloth
                rx, ry, rw, rh = rects[key]
                u = w0 * uvs[0][0] + w1 * uvs[1][0] + w2 * uvs[2][0]
                v = w0 * uvs[0][1] + w1 * uvs[1][1] + w2 * uvs[2][1]
                if key in ("U", "D"):
                    tv = v
                else:
                    tv = s0 + (s1 - s0) * v
                px = np.clip((rx + u * rw).astype(int), 0, tex.shape[1] - 1)
                py = np.clip((ry + tv * rh).astype(int), 0, tex.shape[0] - 1)
                texel = tex[py, px]
                a = texel[..., 3:4]
                col = col * (1 - a) + texel[..., :3] * a
            if key == "H" and face is not None and uvs is not None:
                u = w0 * uvs[0][0] + w1 * uvs[1][0] + w2 * uvs[2][0]
                v = w0 * uvs[0][1] + w1 * uvs[1][1] + w2 * uvs[2][1]
                front = n @ -R[:, 2] > 0.15  # (solo por delante, como el Decal Front)
                px = np.clip((u * face.shape[1]).astype(int), 0, face.shape[1] - 1)
                py = np.clip((v * face.shape[0]).astype(int), 0, face.shape[0] - 1)
                texel = face[py, px]
                a = texel[..., 3:4] * front[..., None]
                col = col * (1 - a) + texel[..., :3] * a
            if neon:
                lit = np.clip(col * 1.05 + 0.12, 0, 1)
                em = col * 1.0
            else:
                lit = shade(col, n, view, spec, shin)
                em = np.zeros_like(lit)
            if is_glass:
                glass.append((y0, x0, mask, z, lit, 1 - max(0.35, part.get("Transparency", 0.5))))
                continue
            sub[mask] = z[mask]
            color[y0 : y1 + 1, x0 : x1 + 1][mask] = lit[mask]
            emit[y0 : y1 + 1, x0 : x1 + 1][mask] = em[mask]
            ids[y0 : y1 + 1, x0 : x1 + 1][mask] = pid
    for (y0, x0, mask, z, lit, alpha) in glass:
        h, w = mask.shape
        sub = depth[y0 : y0 + h, x0 : x0 + w]
        m = mask & (z < sub)
        region = color[y0 : y0 + h, x0 : x0 + w]
        region[m] = region[m] * (1 - alpha) + lit[m] * alpha
    covered = np.isfinite(depth)
    # contornos suaves entre piezas y en la silueta (se lee mejor, estilo hoja de personaje)
    edge = np.zeros((H, W), bool)
    for dy, dx in ((0, 1), (1, 0)):
        a = ids[: H - dy, : W - dx]
        b = ids[dy:, dx:]
        da = depth[: H - dy, : W - dx]
        db = depth[dy:, dx:]
        jump = (a != b) & (np.abs(np.nan_to_num(da, posinf=1e6) - np.nan_to_num(db, posinf=1e6)) > 0.08)
        edge[: H - dy, : W - dx] |= jump
        edge[dy:, dx:] |= jump
    color[edge] *= 0.55
    alpha = covered.astype(np.float32)
    alpha[edge & ~covered] = 0.7
    color[edge & ~covered] = 0.08
    img = np.concatenate([np.clip(color, 0, 1), alpha[..., None]], axis=-1)
    out = Image.fromarray((img * 255).astype(np.uint8), "RGBA")
    em = Image.fromarray((np.clip(emit, 0, 1) * 255).astype(np.uint8), "RGB")
    if ss > 1:
        out = out.resize((W // ss, H // ss), Image.LANCZOS)
        em = em.resize((W // ss, H // ss), Image.BILINEAR)
    return out, em


def bloom(img, em, radius=10, strength=1.3):
    glow = em.filter(ImageFilter.GaussianBlur(radius))
    glow2 = em.filter(ImageFilter.GaussianBlur(radius * 3))
    g = (np.asarray(glow, np.float32) * strength + np.asarray(glow2, np.float32) * strength * 0.6) / 255.0
    return g


# ---------------------------------------------------------------------------
# Hoja
# ---------------------------------------------------------------------------


def bounds(parts):
    lo = np.array([1e9] * 3)
    hi = np.array([-1e9] * 3)
    for p in parts:
        R = np.array(p["Rot"]).reshape(3, 3)
        h = np.array(p["Size"]) / 2
        for sx in (-1, 1):
            for sy in (-1, 1):
                for sz in (-1, 1):
                    w = R @ (h * np.array([sx, sy, sz])) + np.array(p["Pos"])
                    lo = np.minimum(lo, w)
                    hi = np.maximum(hi, w)
    return lo, hi


def view(parts, yaw_deg, w, h, face, dist=16.0, fov=30, focus=None, pitch=4, ss=2):
    lo, hi = bounds(parts)
    center = (lo + hi) / 2 if focus is None else np.array(focus)
    yaw = math.radians(yaw_deg)
    pit = math.radians(pitch)
    # yaw 0 = desde delante (-Z), 90 = desde su derecha (+X)… la cámara mira hacia el centro
    eye = center + np.array([math.sin(yaw) * math.cos(pit), math.sin(pit), -math.cos(yaw) * math.cos(pit)]) * dist
    cam = Camera(eye, center, fov, w * ss, h * ss)
    img, em = render(parts, cam, face, ss)
    return img, em, cam


def composite(canvas, img, em, xy, shadow=None):
    x, y = xy
    if shadow is not None:
        canvas.alpha_composite(shadow, (x, y))
    g = bloom(img, em)
    glow = Image.fromarray(np.clip(g * 255, 0, 255).astype(np.uint8), "RGB")
    base = canvas.crop((x, y, x + img.width, y + img.height)).convert("RGB")
    lighter = np.clip(np.asarray(base, np.float32) + np.asarray(glow, np.float32) * 0.85, 0, 255).astype(np.uint8)
    canvas.paste(Image.fromarray(lighter, "RGB"), (x, y))
    canvas.alpha_composite(img, (x, y))
    over = np.clip(np.asarray(canvas.crop((x, y, x + img.width, y + img.height)).convert("RGB"), np.float32) + np.asarray(glow, np.float32) * 0.35, 0, 255).astype(np.uint8)
    canvas.paste(Image.fromarray(over, "RGB"), (x, y))


def ground_shadow(w, h, cx, cy, rx, ry):
    s = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(s)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=(0, 0, 0, 120))
    return s.filter(ImageFilter.GaussianBlur(ry * 0.6))


def feet_y(cam_parts, cam, ss=2):
    lo, hi = bounds(cam_parts)
    p = cam.project(np.array([[(lo[0] + hi[0]) / 2, lo[1], (lo[2] + hi[2]) / 2]]))[0]
    return p[0] / ss, p[1] / ss


def background(W, H):
    y = np.linspace(0, 1, H)[:, None]
    x = np.linspace(0, 1, W)[None, :]
    top = np.array([16, 28, 58])
    bot = np.array([6, 12, 28])
    g = top * (1 - y[..., None]) + bot * y[..., None]
    g = np.broadcast_to(g, (H, W, 3)).copy()
    # resplandor a la izquierda (donde está el héroe)
    r = np.sqrt(((x - 0.2) * 1.6) ** 2 + (y - 0.45) ** 2)
    g += (np.array([40, 90, 160]) * np.clip(1 - r, 0, 1)[..., None] ** 2)
    img = Image.fromarray(np.clip(g, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(img)
    # cuadrícula de plano de inventor
    for gx in range(0, W, 48):
        d.line([(gx, 0), (gx, H)], fill=(60, 110, 180, 22))
    for gy in range(0, H, 48):
        d.line([(0, gy), (W, gy)], fill=(60, 110, 180, 22))
    return img


def panel(canvas, box, title=None, accent=(90, 190, 255)):
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, radius=22, fill=(10, 22, 48, 190), outline=accent + (150,), width=3)
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle(box, radius=22, outline=accent + (120,), width=8)
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(8)))
    canvas.alpha_composite(layer)
    if title:
        d = ImageDraw.Draw(canvas)
        f = font(FONT_BOLD, 26)
        tw = d.textlength(title, font=f)
        d.rounded_rectangle([x0 + 16, y0 + 14, x0 + 16 + tw + 28, y0 + 54], radius=12, fill=(14, 30, 64, 235))
        d.text((x0 + 30, y0 + 19), title, font=f, fill=(235, 244, 255))


def title_block(canvas):
    d = ImageDraw.Draw(canvas)
    big = font(FONT_IT, 132)
    sub = font(FONT_IT, 50)
    # trazo de pincel detrás
    brush = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(brush)
    bd.polygon([(30, 70), (540, 40), (560, 190), (60, 215)], fill=(8, 16, 36, 230))
    bd.polygon([(70, 205), (520, 180), (530, 262), (90, 280)], fill=(8, 16, 36, 230))
    canvas.alpha_composite(brush.filter(ImageFilter.GaussianBlur(2)))
    for off, colr in (((5, 6), (20, 60, 120, 255)), ((0, 0), (236, 246, 255, 255))):
        d.text((62 + off[0], 50 + off[1]), "COSME", font=big, fill=colr)
    d.text((96, 206), "EL INVENTOR LOCO", font=sub, fill=(120, 205, 255, 255))
    q = font(FONT_IT, 30)
    d.text((70, 300), "«El mundo es un laboratorio gigante…", font=q, fill=(220, 232, 250))
    d.text((70, 338), " …y yo soy el científico.»", font=q, fill=(220, 232, 250))


def element_list(canvas, box, colors):
    d = ImageDraw.Draw(canvas)
    x0, y0, x1, y1 = box
    f = font(FONT_BOLD, 21)
    fs = font(FONT, 17)
    items = [
        ("Pelo de científico", "plateado, toque frío suave", colors["Hair"]),
        ("Gafas de laboratorio", "cristal verde azulado, en la frente", colors["Lens"]),
        ("Bata blanca", "algo sucia, bolis en el bolsillo", colors["Coat"]),
        ("Camiseta negra", "con colgante que brilla", colors["Pendant"]),
        ("Pantalón cargo", "marrón, cinturón y hebilla", colors["Pants"]),
        ("Botas", "negras, suela blanca", colors["Boot"]),
        ("Mochila de inventor", "pantalla y tubos de luz", colors["Screen"]),
        ("Aparato de muñeca", "pantalla en el antebrazo izq.", colors["Screen"]),
        ("Pistola de rayos", "retro, latón y tubo MORADO", colors["GunTube"]),
    ]
    for i, (name, desc, c) in enumerate(items):
        cx = x0 + 28
        cy = y0 + 70 + i * 44
        d.rounded_rectangle([cx, cy + 4, cx + 30, cy + 34], radius=8, fill=tuple(c) + (255,), outline=(255, 255, 255, 140), width=2)
        d.text((cx + 44, cy + 6), name, font=f, fill=(238, 246, 255))
        d.text((cx + 300, cy + 9), desc, font=fs, fill=(150, 185, 225))


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "scripts", "cosme", "out", "cosme.json")
    dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "docs", "cosme", "cosme-hoja.png")
    data = json.load(open(src))
    idle = data["Poses"]["idle"]
    hero = data["Poses"]["hero"]
    colors = data.get("Colors") or {}

    W, H = 2600, 1500
    canvas = background(W, H)
    title_block(canvas)

    # Héroe (3/4 por delante)
    hw, hh = 820, 1180
    img, em, cam = view(hero, -24, hw, hh, FACES["grin"], dist=15.5, fov=31, pitch=6)
    fx, fy = feet_y(hero, cam)
    shadow = ground_shadow(hw, hh, fx, fy - 6, 190, 34)
    composite(canvas, img, em, (40, 300), shadow)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle([60, 1370, 420, 1470], radius=18, fill=(10, 24, 54, 230), outline=(90, 190, 255, 160), width=2)
    d.text((84, 1380), "Cosme", font=font(FONT_BOLD, 44), fill=(120, 205, 255))
    d.text((86, 1434), "Vecino inventor · NPC", font=font(FONT, 22), fill=(220, 232, 250))

    # Vistas: frente, detrás, lado
    px0 = 880
    pw, ph = 520, 690
    views = [("Vista frontal", 0, (px0, 40)), ("Vista trasera", 180, (px0 + pw + 20, 40)), ("Vista lateral", -90, (px0, 40 + ph + 20))]
    for title, yaw, (x, y) in views:
        panel(canvas, (x, y, x + pw, y + ph), title)
        img, em, cam = view(idle, yaw, pw - 20, ph - 70, FACES["grin"], dist=17, fov=28, pitch=5)
        fx, fy = feet_y(idle, cam)
        shadow = ground_shadow(img.width, img.height, fx, fy - 4, 110, 18)
        composite(canvas, img, em, (x + 10, y + 60), shadow)

    # Las 4 caras (primer plano de la cabeza)
    ex0, ey0 = px0 + pw + 20, 40 + ph + 20
    ew, eh = pw, ph
    panel(canvas, (ex0, ey0, ex0 + ew, ey0 + eh), "Expresiones")
    head = [p for p in idle if p["Name"] in ("Head",) or p["Name"].startswith(("Hair", "Goggle"))]
    lo, hi = bounds([p for p in idle if p["Name"] == "Head"])
    focus = ((lo + hi) / 2 + np.array([0, 0.2, 0])).tolist()
    labels = [("grin", "Sonrisa loca"), ("skeptic", "Escéptico"), ("laugh", "Riéndose"), ("scared", "Asustado")]
    cw, ch = (ew - 60) // 2, (eh - 100) // 2
    for i, (key, label) in enumerate(labels):
        cx = ex0 + 20 + (i % 2) * (cw + 20)
        cy = ey0 + 70 + (i // 2) * (ch + 10)
        d = ImageDraw.Draw(canvas)
        d.rounded_rectangle([cx, cy, cx + cw, cy + ch], radius=16, fill=(22, 44, 86, 255), outline=(90, 190, 255, 110), width=2)
        img, em, cam = view(head, -14, cw, ch - 30, FACES[key], dist=6.0, fov=30, focus=focus, pitch=3)
        composite(canvas, img, em, (cx, cy))
        f = font(FONT_BOLD, 22)
        tw = d.textlength(label, font=f)
        d = ImageDraw.Draw(canvas)
        d.text((cx + (cw - tw) / 2, cy + ch - 32), label, font=f, fill=(235, 244, 255))

    # Elementos (a la derecha)
    lx0 = px0 + 2 * pw + 40
    panel(canvas, (lx0, 40, W - 40, H - 40), "Elementos")
    # tarjetas de detalle: gafas, pistola, mochila, muñeca
    detail = [
        ("Gafas", [p for p in idle if p["Name"].startswith(("Goggle", "Head", "Hair"))], "Head", -35, 5.2, (0, 0.35, 0)),
        ("Pistola de rayos", [p for p in idle if p["Name"].startswith("Gun")], None, -70, 3.6, None),
        ("Mochila inventora", [p for p in idle if p["Name"].startswith(("Pack", "Backpack", "UpperTorso"))], None, 150, 7.0, None),
        ("Aparato de muñeca", [p for p in idle if p["Name"].startswith("Wrist")], None, -100, 3.4, None),
    ]
    dw = (W - 40 - lx0 - 60) // 2
    dh = 300
    for i, (label, parts, _, yaw, dist, off) in enumerate(detail):
        cx = lx0 + 20 + (i % 2) * (dw + 20)
        cy = 110 + (i // 2) * (dh + 20)
        d = ImageDraw.Draw(canvas)
        d.rounded_rectangle([cx, cy, cx + dw, cy + dh], radius=16, fill=(22, 44, 86, 255), outline=(90, 190, 255, 110), width=2)
        if not parts:
            continue
        lo, hi = bounds(parts)
        focus = (lo + hi) / 2
        if off is not None:
            focus = focus + np.array(off)
        img, em, cam = view(parts, yaw, dw, dh - 34, FACES["grin"], dist=dist, fov=30, focus=focus.tolist(), pitch=12)
        composite(canvas, img, em, (cx, cy))
        f = font(FONT_BOLD, 21)
        d = ImageDraw.Draw(canvas)
        tw = d.textlength(label, font=f)
        d.text((cx + (dw - tw) / 2, cy + dh - 32), label, font=f, fill=(235, 244, 255))
    element_list(canvas, (lx0, 700, W - 40, 1120), colors)
    d = ImageDraw.Draw(canvas)
    notes = [
        "Piezas soldadas (shared/CosmeLook): se mueven",
        "con las animaciones y no chocan con nada.",
        "Caras: risa en los chistes · miedo en peligro ·",
        "escéptico al hablar · sonrisa loca cuando calla.",
    ]
    f = font(FONT, 20)
    for i, line in enumerate(notes):
        d.text((lx0 + 30, 1205 + i * 30), line, font=f, fill=(190, 212, 240))
    big = font(FONT_IT, 44)
    d.text((lx0 + 30, H - 140), "GRANDES IDEAS…", font=big, fill=(110, 200, 255))
    d.text((lx0 + 120, H - 92), "LOCAS SOLUCIONES", font=big, fill=(110, 200, 255))

    os.makedirs(os.path.dirname(dst), exist_ok=True)
    canvas.convert("RGB").save(dst, optimize=True)
    print("✅", dst)


if __name__ == "__main__":
    main()
