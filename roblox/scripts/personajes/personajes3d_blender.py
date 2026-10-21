#!/usr/bin/env python3
"""Personajes 3D propios hechos en Blender (encargo del dueño «Modelos 3D propios», oct 2026): el piloto
del reparto de la historia —Cosme, Mamá, Papá, Pip, Abu Rosa, Abu Tomás, Profe Lucía y Nico— como UNA
malla con esqueleto R15 por personaje (cuerpo, ropa, pelo y complementos en la misma malla), con la cara
modelada (ojos, párpados, cejas, nariz, UNA boca) que se mueve con huesos de la cara, texturas PBR
horneadas y su versión lejana (LOD).

Seguridad de moderación (docs/bugs/moderacion/): nunca una pieza del cuerpo suelta; todos vestidos del
todo (manga larga, pantalón largo, zapatos), cuerpo neutro bajo la ropa; cada malla pasa
scripts/audit/moderacion-mallas.py (0 marcas) y la «vista gris» (6 vistas, sola, gris, sin textura) en
docs/personajes/3d/revision-gris/.

Necesita Blender como módulo de Python:   pip install bpy==4.2.0   (Python 3.11; todo en CPU)

Uso (desde la carpeta roblox/):
    python3 scripts/personajes/personajes3d_blender.py                  todo
    python3 scripts/personajes/personajes3d_blender.py --solo Cosme     uno (o varios: Cosme,Nico)
    python3 scripts/personajes/personajes3d_blender.py --no-bake        sin hornear (prueba de geometría)
    python3 scripts/personajes/personajes3d_blender.py --no-render      sin las vistas previas
    python3 scripts/personajes/personajes3d_blender.py --hojas          solo rehace las hojas (con los PNG)

Salida:
    assets/personajes3d/Personaje3D_<Key>.fbx    esqueleto R15 (+ huesos Face*) con Cuerpo (≤ 12.000 / 8.000
                                                 triángulos) y CuerpoLOD (≤ 3.000 / 2.000)
    assets/personajes3d/tex/Personaje3D_<Key>_{color,normal,rugosidad}.png   1024 (héroes) / 512
    assets/personajes3d/manifest.json
    src/shared/Personajes3DMallas.luau           (lo mismo para el juego; lo usa World/CharacterMeshLoader)
    docs/personajes/3d/<key>-*.jpg, reparto-3d-antes-despues.jpg   vistas previas (VISTA PREVIA, NO ES ROBLOX)
Subir: bash scripts/upload-personajes3d.sh (pasa la revisión de moderación antes; solo la sesión que publica).
"""
import argparse
import json
import math
import os
import shutil
import sys
import time

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

import p3d_cuerpo as C  # noqa: E402
import p3d_geo as G  # noqa: E402
import p3d_reparto as R  # noqa: E402

OUT = os.path.join(ROOT, "assets", "personajes3d")
TEX = os.path.join(OUT, "tex")
DOCS = os.path.join(ROOT, "docs", "personajes", "3d")
LUAU = os.path.join(ROOT, "src", "shared", "Personajes3DMallas.luau")
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
PREFIX = "Personaje3D_"
BUDGET = {True: (12000, 3000, 1024), False: (8000, 2000, 512)}  # héroe: (tris, LOD, textura)

log = G.log


# ====================================================================== construir
def build(spec, bake=True):
    G.reset()
    B = C.Builder(spec)
    spec["build"](B)
    objs = [p.obj for p in B.parts]
    bpy.context.view_layer.update()
    for p in B.parts:
        G.set_weights(p.obj, p.rule, G.CAPS)
    tris = sum(G.tris(o) for o in objs)
    hero = spec["Hero"]
    maxt, lodt, size = BUDGET[hero]
    log(f"{spec['Key']}: {len(objs)} piezas, {tris} triángulos (tope {maxt})")
    G.uv_islands_scaled(objs)
    name = PREFIX + spec["Key"]
    # juntar en UNA malla (cada pieza guarda sus coordenadas para los dibujos de su material)
    for o in objs:
        G.store_local(o)
        G.select_only([o])
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    G.select_only(objs, objs[0])
    bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    body.name = "Cuerpo"
    body.data.name = name + "_Cuerpo"
    # por encima del tope: se simplifica toda la malla un poco (silueta igual)
    t_now = G.tris(body)
    if t_now > maxt * 0.98:
        dec = body.modifiers.new("Tope", "DECIMATE")
        dec.decimate_type = "COLLAPSE"
        dec.ratio = (maxt * 0.95) / t_now
        dec.use_collapse_triangulate = True
        G.apply_mods(body)
        log(f"  simplificada: {t_now} -> {G.tris(body)} triángulos")
    G.pack_uv(body)
    paths = None
    if bake:
        os.makedirs(TEX, exist_ok=True)
        paths = G.bake([body], name, size, TEX)
    mat = G.pbr_material(name, paths) if paths else None
    body.data.materials.clear()
    if mat:
        body.data.materials.append(mat)
    else:
        body.data.materials.append(B.parts[0].mat)
    for p in body.data.polygons:
        p.material_index = 0
    # pesos: como mucho 4 huesos por vértice, normalizados (Roblox)
    G.select_only([body])
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
    arm = G.make_armature(name, B.face)
    G.bind(body, arm)
    # LOD
    lod = body.copy()
    lod.data = body.data.copy()
    lod.name = "CuerpoLOD"
    lod.data.name = name + "_CuerpoLOD"
    G.coll().objects.link(lod)
    for m in list(lod.modifiers):
        lod.modifiers.remove(m)
    dec = lod.modifiers.new("LOD", "DECIMATE")
    dec.decimate_type = "COLLAPSE"
    dec.ratio = min(1.0, (lodt * 0.92) / max(G.tris(body), 1))
    dec.use_collapse_triangulate = True
    G.apply_mods(lod)
    G.bind(lod, arm)
    return B, body, lod, arm, paths


def rb_vec(v):
    """Blender -> Roblox, respecto a la raíz (HumanoidRootPart a 3 studs del suelo)."""
    return [round(v.x, 4), round(v.z - 3.0, 4), round(-v.y, 4)]


def bbox_rb(obj):
    pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    c = (lo + hi) / 2
    s = hi - lo
    return rb_vec(c), [round(s.x, 4), round(s.z, 4), round(s.y, 4)]


def manifest_entry(spec, B, body, lod, arm):
    hero = spec["Hero"]
    maxt, lodt, size = BUDGET[hero]
    bones = []
    for b in arm.data.bones:
        bones.append({"Name": b.name, "Parent": b.parent.name if b.parent else "", "Pos": rb_vec(b.head_local)})
    c, s = bbox_rb(body)
    lc, ls = bbox_rb(lod)
    name = PREFIX + spec["Key"]
    return {
        "Key": spec["Key"], "Name": spec["Name"], "Cast": spec["Cast"], "Variant": spec.get("Variant"), "Asset": name,
        "Hero": hero, "Kid": bool(spec.get("Kid")), "Robot": bool(spec.get("Robot")),
        "Tris": G.tris(body), "LodTris": G.tris(lod), "MaxTris": maxt, "MaxLodTris": lodt, "TextureSize": size,
        "Center": c, "Size": s, "LodCenter": lc, "LodSize": ls, "Bones": bones, "Faces": spec["Faces"],
        "Textures": {k: f"{name}_{k}" for k in ("color", "normal", "rugosidad")},
        "Pieces": sorted({p.tag for p in B.parts}),
    }


# ====================================================================== posturas (vistas previas)
def rx(deg):
    return Matrix.Rotation(math.radians(deg), 3, "X")


def ry(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Y")


def rz(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Z")


def walk_pose(phase):
    s = math.sin(phase)
    c = math.cos(phase)
    rot = {
        "RightUpperLeg": rx(32 * s), "LeftUpperLeg": rx(-32 * s),
        "RightLowerLeg": rx(-max(0.0, -s) * 50 - 6), "LeftLowerLeg": rx(-max(0.0, s) * 50 - 6),
        "RightFoot": rx(8 * s), "LeftFoot": rx(-8 * s),
        "RightUpperArm": rx(-28 * s), "LeftUpperArm": rx(28 * s),
        "RightLowerArm": rx(14 + 8 * max(0, -s)), "LeftLowerArm": rx(14 + 8 * max(0, s)),
        "UpperTorso": rz(-6 * s), "Head": rz(4 * s),
    }
    loc = {"LowerTorso": Vector((0, 0, 0.06 * abs(c) - 0.03))}
    return rot, loc


def idle_pose(t):
    b = math.sin(t)
    return {"UpperTorso": rx(-2 * b), "Head": rx(3 * b) @ rz(4 * b), "RightUpperArm": ry(-4 - 2 * b), "LeftUpperArm": ry(4 + 2 * b),
            "RightLowerArm": rx(8), "LeftLowerArm": rx(8)}, {}


GESTURES = {
    "Saludar": ({"RightUpperArm": ry(-150), "RightLowerArm": ry(20), "Head": rz(-8) @ rx(4), "LeftUpperArm": ry(6)}, {}),
    "Señalar": ({"RightUpperArm": rx(84) @ ry(-6), "Head": rz(-10), "UpperTorso": rz(-8)}, {}),
    "Pensar": ({"RightUpperArm": rx(30) @ ry(30), "RightLowerArm": rx(115), "LeftUpperArm": rx(25) @ ry(-28), "LeftLowerArm": rx(80), "Head": rx(-8) @ ry(6)}, {}),
    "Encogerse": ({"RightUpperArm": ry(-28) @ rx(10), "LeftUpperArm": ry(28) @ rx(10), "RightLowerArm": rx(70) @ ry(-30), "LeftLowerArm": rx(70) @ ry(30), "Head": ry(10)}, {}),
}


def face_pose(arm, expr):
    rot, loc = {}, {}
    for bone, (l, r) in R.EXPRESSIONS.get(expr, {}).items():
        loc[bone] = Vector(l)
        rot[bone] = (rz(r[2]) @ ry(r[1]) @ rx(r[0]))
    return rot, loc


def merge(a, b):
    ra, la = a
    rb_, lb = b
    r = dict(ra)
    r.update(rb_)
    l_ = dict(la)
    l_.update(lb)
    return r, l_


# ====================================================================== estudio y fotos
def studio(scene, samples=48):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    try:
        scene.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    scene.cycles.max_bounces = 4
    scene.view_settings.view_transform = "Standard"  # (como Roblox: el color tal cual)
    scene.render.film_transparent = True
    w = bpy.data.worlds.new("estudio")
    scene.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.34, 0.42, 0.6, 1)
    bg.inputs[1].default_value = 0.55

    def area(name, loc, energy, size, color=(1, 1, 1)):
        L = bpy.data.lights.new(name, "AREA")
        L.energy = energy
        L.size = size
        L.color = color
        o = bpy.data.objects.new(name, L)
        o.location = Vector(loc)
        o.rotation_euler = (Vector((0, 0, 3.2)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        G.coll().objects.link(o)
        return o

    area("Clave", (5.5, 8.5, 9.0), 1900, 5.0, (1.0, 0.96, 0.9))
    area("Relleno", (-8.0, 6.0, 4.0), 600, 7.0, (0.8, 0.88, 1.0))
    area("Contra", (-3.0, -9.0, 8.0), 1500, 4.0, (0.75, 0.85, 1.0))
    floor = G.blob("Suelo", (0, 0, -0.5), (6, 6, 0.5), segs=48, rings=12)
    m = G.mat_plain("suelo", (0.18, 0.2, 0.26), 0.8)
    G.assign(floor, m)
    floor.is_shadow_catcher = True
    cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    G.coll().objects.link(cam)
    scene.camera = cam
    return cam


def shoot(scene, cam, eye, target, lens, path, res=(760, 980)):
    scene.render.resolution_x, scene.render.resolution_y = res
    cam.location = Vector(eye)
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    bpy.ops.render.render(write_still=True)
    return path


def render_all(spec, arm, lod, work, samples):
    scene = bpy.context.scene
    lod.hide_render = True
    cam = studio(scene, samples)
    key = spec["Key"].lower()
    out = {}
    G.rest_pose(arm)
    rest_face = spec["Faces"][0]
    G.pose_bones(arm, *face_pose(arm, rest_face))
    hz = 3.1
    out["frente"] = shoot(scene, cam, (0, 15.5, 3.3), (0, 0, hz), 50, os.path.join(work, f"{key}_frente.png"))
    out["34"] = shoot(scene, cam, (8.5, 12.5, 3.6), (0, 0, hz), 50, os.path.join(work, f"{key}_34.png"))
    out["lado"] = shoot(scene, cam, (15.5, 0.6, 3.3), (0, 0, hz), 50, os.path.join(work, f"{key}_lado.png"))
    out["espalda"] = shoot(scene, cam, (-7.5, -13.5, 3.8), (0, 0, hz), 50, os.path.join(work, f"{key}_espalda.png"))
    # primeros planos de la cara con sus expresiones
    hc = 4.86 if not spec.get("Head", {}).get("z") else spec["Head"]["z"]
    faces = []
    for expr in spec["Faces"][:5]:
        G.pose_bones(arm, *face_pose(arm, expr))
        faces.append((expr, shoot(scene, cam, (0.9, 4.6, hc + 0.1), (0, 0, hc), 60, os.path.join(work, f"{key}_cara_{expr}.png"), (520, 600))))
    out["caras"] = faces
    # animación: andar, quieto y gestos (comprueba los huesos R15 en la malla)
    anim = []
    lowres = (360, 480)
    scene.cycles.samples = max(8, samples // 2)
    for i, ph in enumerate((0.0, math.pi / 2, math.pi, 3 * math.pi / 2)):
        G.pose_bones(arm, *merge(walk_pose(ph), face_pose(arm, rest_face)))
        anim.append((f"Andar {i + 1}", shoot(scene, cam, (8.0, 11.5, 3.4), (0, 0, 2.9), 50, os.path.join(work, f"{key}_andar{i}.png"), lowres)))
    G.pose_bones(arm, *merge(idle_pose(1.0), face_pose(arm, rest_face)))
    anim.append(("Quieto", shoot(scene, cam, (8.0, 11.5, 3.4), (0, 0, 2.9), 50, os.path.join(work, f"{key}_quieto.png"), lowres)))
    for gname, pose in GESTURES.items():
        G.pose_bones(arm, *merge(pose, face_pose(arm, "Happy" if "Happy" in spec["Faces"] else rest_face)))
        anim.append((gname, shoot(scene, cam, (6.0, 13.0, 3.6), (0, 0, 3.2), 50, os.path.join(work, f"{key}_{gname}.png"), lowres)))
    out["anim"] = anim
    scene.cycles.samples = samples
    G.rest_pose(arm)
    G.pose_bones(arm, *face_pose(arm, rest_face))
    out["fila"] = shoot(scene, cam, (3.0, 15.5, 3.3), (0, 0, 3.1), 50, os.path.join(work, f"{key}_fila.png"), (520, 980))
    lod.hide_render = False
    arm_body = bpy.data.objects.get("Cuerpo")
    arm_body.hide_render = True
    out["lod"] = shoot(scene, cam, (8.5, 12.5, 3.6), (0, 0, hz), 50, os.path.join(work, f"{key}_lod.png"), (520, 680))
    arm_body.hide_render = False
    return out


# ====================================================================== hojas (PIL)
def fonts(size, bold=True):
    from PIL import ImageFont

    return ImageFont.truetype(FONT_BOLD if bold else FONT, size)


def backdrop(w, h):
    from PIL import Image, ImageDraw

    img = Image.new("RGB", (w, h), (14, 22, 48))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=(int(24 + 18 * (1 - t)), int(40 + 30 * (1 - t)), int(86 + 50 * (1 - t))))
    for x in range(0, w, 48):
        d.line([(x, 0), (x, h)], fill=(40, 70, 130))
    for y in range(0, h, 48):
        d.line([(0, y), (w, y)], fill=(40, 70, 130))
    return img


def tag_preview(img):
    from PIL import ImageDraw

    d = ImageDraw.Draw(img)
    f = fonts(22)
    text = "VISTA PREVIA, NO ES ROBLOX"
    tw = d.textlength(text, font=f)
    x1, y1 = img.width - 18, img.height - 16
    d.rounded_rectangle([x1 - tw - 32, y1 - 40, x1, y1], 10, fill=(170, 28, 40))
    d.text((x1 - tw - 16, y1 - 34), text, font=f, fill=(255, 255, 255))
    return img


def paste_fit(dst, src_path, box, label=None, crop=True):
    from PIL import Image, ImageDraw

    im = Image.open(src_path).convert("RGBA")
    if crop:
        bb = im.split()[3].point(lambda a: 255 if a > 200 else 0).getbbox()
        if bb:
            pad = 12
            im = im.crop((max(0, bb[0] - pad), max(0, bb[1] - pad), min(im.width, bb[2] + pad), min(im.height, bb[3] + pad)))
    x0, y0, x1, y1 = box
    k = min((x1 - x0) / im.width, (y1 - y0 - (34 if label else 0)) / im.height)
    im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
    dst.paste(im, (x0 + (x1 - x0 - im.width) // 2, y0 + (y1 - y0 - (34 if label else 0) - im.height) // 2), im)
    if label:
        d = ImageDraw.Draw(dst)
        f = fonts(22)
        tw = d.textlength(label, font=f)
        d.text((x0 + (x1 - x0 - tw) / 2, y1 - 30), label, font=f, fill=(235, 240, 255))


def character_sheet(spec, shots, entry, path):
    from PIL import ImageDraw

    W, H = 2400, 1500
    img = backdrop(W, H)
    d = ImageDraw.Draw(img)
    d.text((36, 22), f"{spec['Name']} · modelo 3D propio", font=fonts(46), fill=(240, 245, 255))
    d.text((38, 84), f"Una malla con esqueleto R15 · {entry['Tris']} triángulos (tope {entry['MaxTris']}) · LOD {entry['LodTris']} · "
                     f"texturas {entry['TextureSize']} px (color, normal, rugosidad)", font=fonts(22, False), fill=(190, 205, 235))
    cols = [("Frente", shots["frente"]), ("3/4", shots["34"]), ("Lado", shots["lado"]), ("Espalda", shots["espalda"])]
    for i, (lab, p) in enumerate(cols):
        paste_fit(img, p, (20 + i * 300, 130, 20 + (i + 1) * 300, 900), lab)
    n = len(shots["caras"])
    cw = (W - 1240) // max(n, 1)
    names = {"Neutral": "Normal", "Happy": "Contenta", "Sad": "Triste", "Angry": "Enfadada", "Scared": "Asustada", "Talk": "Hablando",
             "Grin": "Sonrisa loca", "Skeptic": "Escéptico", "Laugh": "Riéndose"}
    for i, (expr, p) in enumerate(shots["caras"]):
        paste_fit(img, p, (1230 + i * cw, 130, 1230 + (i + 1) * cw, 560), names.get(expr, expr))
    paste_fit(img, shots["lod"], (1230, 580, 1530, 900), f"LOD ({entry['LodTris']})")
    d.text((1560, 600), "Huesos de la cara (una sola boca):", font=fonts(22), fill=(235, 240, 255))
    d.text((1560, 634), "FaceJaw, FaceMouthL/R, FaceBrowL/R, FaceLidL/R", font=fonts(20, False), fill=(190, 205, 235))
    pieces = entry["Pieces"]
    for j in range(0, len(pieces), 7):
        d.text((1560, 670 + j // 7 * 24), ("Piezas: " if j == 0 else "        ") + ", ".join(pieces[j:j + 7]), font=fonts(18, False), fill=(190, 205, 235))
    d.text((1560, 770), "Todo vestido: manga larga, pantalón largo,", font=fonts(20, False), fill=(190, 205, 235))
    d.text((1560, 798), "zapatos. Ninguna pieza del cuerpo suelta.", font=fonts(20, False), fill=(190, 205, 235))
    d.text((36, 915), "Animación con el esqueleto R15 (andar, quieto y gestos): la malla se dobla en las articulaciones de Roblox", font=fonts(24), fill=(235, 240, 255))
    m = len(shots["anim"])
    aw = W // max(m, 1)
    for i, (lab, p) in enumerate(shots["anim"]):
        paste_fit(img, p, (i * aw, 950, (i + 1) * aw, 1440), lab)
    tag_preview(img)
    img.save(path, quality=88)
    return path


def lineup(entries, shots_by_key, path):
    """Antes (CastLook: bloques con textura) / después (modelo 3D) de todo el piloto."""
    from PIL import Image, ImageDraw

    before = before_crops()
    n = len(entries)
    cw = 300
    W, H = cw * n + 40, 1500
    img = backdrop(W, H)
    d = ImageDraw.Draw(img)
    d.text((28, 18), "Reparto 3D (piloto) · ANTES: CastLook (bloques con textura) · DESPUÉS: modelo 3D propio", font=fonts(36), fill=(240, 245, 255))
    d.text((28, 78), "ANTES", font=fonts(30), fill=(255, 200, 120))
    d.text((28, 640), "DESPUÉS", font=fonts(30), fill=(140, 230, 170))
    for i, e in enumerate(entries):
        x0 = 20 + i * cw
        b = before.get(e["Key"])
        if b is not None:
            tmp = os.path.join(WORK, f"antes_{e['Key']}.png")
            b.save(tmp)
            paste_fit(img, tmp, (x0, 115, x0 + cw, 620), None)
        paste_fit(img, shots_by_key[e["Key"]]["fila"], (x0, 670, x0 + cw, 1440), e["Name"])
    tag_preview(img)
    img.save(path, quality=88)
    return path


def before_crops():
    """Los recortes de las vistas previas de CastLook (docs/personajes/reparto-saga1-despues.jpg, 8×3) y
    de Cosme (docs/personajes/cosme/revision/cosme-frente.jpg)."""
    from PIL import Image

    out = {}
    sheet = os.path.join(ROOT, "docs", "personajes", "reparto-saga1-despues.jpg")
    if os.path.exists(sheet):
        im = Image.open(sheet).convert("RGB")
        k = im.width / 1880.0
        cells = {"Familia_Mama": (0, 0), "Familia_Papa": (1, 0), "Abu_Rosa": (2, 0), "Abu_Tomas": (3, 0), "Lucia": (4, 0), "Pip": (0, 1), "Nico": (1, 1)}
        for key, (cx, cy) in cells.items():
            x0, y0 = int((20 + cx * 230) * k), int((100 + cy * 440) * k)
            out[key] = im.crop((x0, y0, x0 + int(230 * k), y0 + int(370 * k)))
    cos = os.path.join(ROOT, "docs", "personajes", "cosme", "revision", "cosme-frente.jpg")
    if os.path.exists(cos):
        im = Image.open(cos).convert("RGB")
        out["Cosme"] = im.crop((int(im.width * 0.08), int(im.height * 0.08), int(im.width * 0.92), int(im.height * 0.95)))
    return out


# ====================================================================== Luau
def cf_luau(loc, rot_deg):
    """Pose de un hueso de la cara (Blender, ejes del personaje) -> CFrame de Roblox en los ejes de la
    cabeza: posición (x, z, -y) y la rotación conjugada por el cambio de ejes."""
    Rb = (rz(rot_deg[2]) @ ry(rot_deg[1]) @ rx(rot_deg[0]))
    Cm = Matrix(((1, 0, 0), (0, 0, 1), (0, -1, 0)))
    Rr = Cm @ Rb @ Cm.transposed()
    x, y, z = loc[0], loc[2], -loc[1]
    vals = [x, y, z] + [Rr[i][j] for i in range(3) for j in range(3)]
    return "CFrame.new(" + ", ".join(f"{v:.4f}" for v in vals) + ")"


def v3(v):
    return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"


def write_luau(manifest):
    L = [
        "-- Personajes3DMallas: GENERADO por scripts/personajes/personajes3d_blender.py (no editar a mano).",
        "-- Los personajes 3D propios del reparto (encargo «Modelos 3D propios»): UNA malla con esqueleto R15",
        "-- por personaje (Cuerpo y su LOD CuerpoLOD; ropa, pelo y complementos en la misma malla) y huesos de",
        "-- la cara (Face*) para las expresiones: una sola boca, la de la malla. Lo usan World/CharacterMeshLoader",
        "-- (monta la malla en el actor; sin ids o si la moderación la retira, sigue CastLook) y",
        "-- Controllers/Personaje3DAnim (los huesos siguen a las piezas del R15 y la cara a la expresión).",
        "--   Models[key]   Key = la de CastLook (Familia_Mama…; Cosme), Asset = nombre al subir, Center/Size",
        "--                 de la malla respecto a la raíz (HumanoidRootPart), Bones con su punto en reposo.",
        "--   Expressions   pose de cada hueso de la cara (CFrame en los ejes de la cabeza) por expresión.",
        "",
        "return {",
        "\tVersion = 1,",
        f"\tPrefix = \"{PREFIX}\",",
        "\tR15 = { " + ", ".join(f"\"{b}\"" for b in G.R15_ORDER) + " },",
        "\tFaceBones = { " + ", ".join(f"\"{b}\"" for b in G.FACE_BONES) + " },",
        "\t-- Pieza del R15 a la que sigue cada hueso (los de la cara siguen a la cabeza)",
        "\tFollow = {",
        "\t\tRoot = \"HumanoidRootPart\",",
    ]
    for b in G.R15_ORDER:
        L.append(f"\t\t{b} = \"{b}\",")
    for b in G.FACE_BONES:
        L.append(f"\t\t{b} = \"Head\",")
    L += ["\t},", "\tExpressions = {"]
    for name, bones in R.EXPRESSIONS.items():
        if not bones:
            L.append(f"\t\t{name} = {{}},")
            continue
        L.append(f"\t\t{name} = {{")
        for bone in sorted(bones):
            loc, rot = bones[bone]
            L.append(f"\t\t\t{bone} = {cf_luau(loc, rot)},")
        L.append("\t\t},")
    L += ["\t},", "\tModels = {"]
    for e in manifest["Models"]:
        L.append(f"\t\t{e['Key']} = {{")
        L.append(f"\t\t\tName = \"{e['Name']}\", Cast = \"{e['Cast']}\"," + (f" Variant = \"{e['Variant']}\"," if e.get("Variant") else "")
                 + f" Asset = \"{e['Asset']}\", Hero = {str(e['Hero']).lower()}, Kid = {str(e['Kid']).lower()}, Robot = {str(e['Robot']).lower()},")
        L.append(f"\t\t\tTris = {e['Tris']}, LodTris = {e['LodTris']}, MaxTris = {e['MaxTris']}, MaxLodTris = {e['MaxLodTris']}, TextureSize = {e['TextureSize']},")
        L.append(f"\t\t\tCenter = {v3(e['Center'])}, Size = {v3(e['Size'])}, LodCenter = {v3(e['LodCenter'])}, LodSize = {v3(e['LodSize'])},")
        L.append("\t\t\tFaces = { " + ", ".join(f"\"{f}\"" for f in e["Faces"]) + " },")
        L.append(f"\t\t\tTextures = {{ Color = \"{e['Textures']['color']}\", Normal = \"{e['Textures']['normal']}\", Roughness = \"{e['Textures']['rugosidad']}\" }},")
        L.append("\t\t\tBones = {")
        for b in e["Bones"]:
            L.append(f"\t\t\t\t{{ Name = \"{b['Name']}\", Parent = \"{b['Parent']}\", Pos = {v3(b['Pos'])} }},")
        L.append("\t\t\t},")
        L.append("\t\t},")
    L += ["\t},", "}", ""]
    with open(LUAU, "w") as f:
        f.write("\n".join(L))


# ====================================================================== main
WORK = os.path.join(__import__("tempfile").gettempdir(), "personajes3d-vistas")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--solo", default="")
    ap.add_argument("--no-bake", action="store_true")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--samples", type=int, default=40)
    args = ap.parse_args()
    keys = [k.strip() for k in args.solo.split(",") if k.strip()]
    specs = [s for s in R.REPARTO if not keys or s["Key"] in keys]
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(DOCS, exist_ok=True)
    os.makedirs(WORK, exist_ok=True)
    man_path = os.path.join(OUT, "manifest.json")
    manifest = {"Models": []}
    if os.path.exists(man_path):
        with open(man_path) as f:
            manifest = json.load(f)
    shots_path = os.path.join(WORK, "shots.json")
    all_shots = {}
    if os.path.exists(shots_path):
        with open(shots_path) as f:
            all_shots = json.load(f)
    for spec in specs:
        t0 = time.time()
        B, body, lod, arm, paths = build(spec, bake=not args.no_bake)
        entry = manifest_entry(spec, B, body, lod, arm)
        if entry["Tris"] > entry["MaxTris"] or entry["LodTris"] > entry["MaxLodTris"]:
            raise SystemExit(f"❌ {spec['Key']}: {entry['Tris']} / LOD {entry['LodTris']} triángulos (tope {entry['MaxTris']} / {entry['MaxLodTris']})")
        fbx = os.path.join(OUT, entry["Asset"] + ".fbx")
        G.export_fbx(fbx, arm, [body, lod])
        manifest["Models"] = [m for m in manifest["Models"] if m["Key"] != spec["Key"]] + [entry]
        with open(man_path, "w") as f:  # (después de cada uno: si se corta, no se pierde lo hecho)
            json.dump(manifest, f, indent=1, ensure_ascii=False)
        log(f"{spec['Key']}: {entry['Tris']} triángulos, LOD {entry['LodTris']} -> {os.path.relpath(fbx, ROOT)} ({time.time() - t0:.0f}s)")
        if not args.no_render:
            shots = render_all(spec, arm, lod, WORK, args.samples)
            character_sheet(spec, shots, entry, os.path.join(DOCS, f"{spec['Key'].lower()}-3d.jpg"))
            all_shots[spec["Key"]] = shots
            with open(shots_path, "w") as f:
                json.dump(all_shots, f)
    order = [s["Key"] for s in R.REPARTO]
    manifest["Models"].sort(key=lambda m: order.index(m["Key"]) if m["Key"] in order else 99)
    with open(man_path, "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    write_luau(manifest)
    if all(m["Key"] in all_shots for m in manifest["Models"]) and manifest["Models"]:
        p = lineup(manifest["Models"], all_shots, os.path.join(DOCS, "reparto-3d-antes-despues.jpg"))
        log(f"hoja: {os.path.relpath(p, ROOT)}")
    log("listo")


if __name__ == "__main__":
    main()
