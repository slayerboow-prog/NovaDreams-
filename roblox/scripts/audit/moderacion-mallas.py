#!/usr/bin/env python3
"""Revisión de las mallas ANTES de subirlas a Roblox (docs/bugs/moderacion/).

Por qué: el 20 oct 2026 la moderación de Roblox retiró dos mallas de la v124 por «Contenido sexual»
(136955064198663 y 138746120321894). Eran segmentos sueltos de los Vórtidos de cristal (el antebrazo y la
pierna): Roblox revisa CADA malla por separado, sola, gris y sin textura, y un tubo liso alargado con la
punta redondeada (o una bola en un extremo) se confunde con contenido sexual. Cada aviso es una falta en
la cuenta del dueño: esto busca esas formas antes de subir nada.

Para cada malla que se subiría (cada objeto de cada FBX: cada uno es una MeshPart y una malla de Roblox),
mira la forma de la malla entera y la de su trozo principal:
    alargamiento   largo / ancho (ejes principales)
    sección        ancho / grueso (redonda ≈ 1; una tabla o una hoja, mucho más)
    tubo           el radio varía poco a lo largo y cada sección es UN anillo (un cilindro o una cápsula;
                   un personaje entero no: sus piernas y brazos dan secciones partidas)
    puntas         los extremos se estrechan (redondeados, una tapa o una bola)
    lisa           casi todas las aristas suaves (sin facetas, placas ni cristales)
y la marca:
    ALTO   tubo redondo alargado (≥ 2,2), liso, con alguna punta redondeada   -> NO se sube
    MEDIO  muy alargado (≥ 3,5), de sección redonda y algo liso o con punta redonda -> NO se sube
    ok     lo demás
Las marcadas se dibujan solas, grises y sin textura (como la miniatura de la moderación) en
docs/bugs/moderacion/revision/.

Uso (desde la carpeta roblox/; necesita Blender como módulo: pip install bpy; Blender 4.2 o 5.x):
    python3 scripts/audit/moderacion-mallas.py                     revisa todos los kits y escribe el informe
    python3 scripts/audit/moderacion-mallas.py --kits mar,puerto    solo esos kits
    python3 scripts/audit/moderacion-mallas.py --check a.fbx b.fbx  (los scripts de subida) sale con 2 si
                                                                    alguna está marcada, 3 si no puede revisar
    --sin-dibujos     sin las imágenes
    --vista-gris DIR  además, CADA malla (marcada o no) sola, gris y sin textura desde 6 lados (frente,
                      espalda, izquierda, derecha, 3/4 y arriba) en DIR/<archivo>__<malla>.jpg: la revisión
                      a ojo antes de subir (estilo bloque: docs/personajes/estilo-bloque/revision-gris/)
Los scripts de subida (scripts/upload-{mar,puerto,invasion,asteroides,nave}.sh) lo llaman con --check y no
suben nada marcado, salvo que se nombre cada archivo en MODERACION_PERMITIR="Nombre1,Nombre2" tras
revisarlo a mano (no hay un «permitir todo»).
"""
import argparse
import glob
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "docs", "bugs", "moderacion", "revision")

KITS = {
    "mar": "assets/mar/*.fbx",
    "puerto": "assets/puerto/*.fbx",
    "invasion": "assets/invasion/*.fbx",
    "asteroides": "assets/asteroides/*.fbx",
    "nave": "assets/nave/*.fbx",
    "bloque": "assets/bloque/*.fbx",
}

# Umbrales (calibrados con las dos mallas retiradas: antebrazo ≈ 2,7 y pierna ≈ 3,1 de alargamiento)
ELONG_HIGH = 2.2
ELONG_MED = 3.5
ROUND_MAX = 2.0  # ancho / grueso: por encima es plana (hoja, tabla, aleta)
TUBE_CV = 0.42  # variación del radio en el tramo central
RING_MAX = 0.3  # la sección es UN anillo (tubo); un cuerpo entero (dos piernas, brazos al lado) da ≥ 0,4
CAP_RATIO = 0.8  # el extremo más estrecho que esto (respecto al tramo central) = punta redondeada
SMOOTH_MIN = 0.6  # parte de las aristas (por área) con menos de 25° entre caras
BINS = 16


def log(msg):
    print(msg, flush=True)


# ====================================================================== geometría (numpy puro)
def shape_metrics(pts, tris):
    """pts (N,3), tris (M,3) -> dict con las medidas de la forma."""
    import numpy as np

    if len(pts) < 8 or len(tris) < 4:
        return None
    a, b, c = pts[tris[:, 0]], pts[tris[:, 1]], pts[tris[:, 2]]
    cr = np.cross(b - a, c - a)
    area = np.linalg.norm(cr, axis=1) / 2
    tot = area.sum()
    if tot <= 1e-9:
        return None
    # puntos de muestra: los centros de los triángulos con su área (así no pesa más la zona con más vértices)
    cen = (a + b + c) / 3
    mu = (cen * area[:, None]).sum(0) / tot
    q = cen - mu
    cov = (q * area[:, None]).T @ q / tot
    w, v = np.linalg.eigh(cov)
    v = v[:, ::-1]
    allp = (pts - mu) @ v
    ext = allp.max(0) - allp.min(0)
    rest = sorted((float(ext[1]), float(ext[2])), reverse=True)
    L, W, T = float(ext[0]), max(rest[0], 1e-6), max(rest[1], 1e-6)
    elong = L / W
    flat = W / T
    # perfil del radio a lo largo del eje principal: con puntos repartidos POR LA SUPERFICIE (no solo los
    # vértices). Un cilindro de pocos polígonos (un bastón, un tubo) solo tiene vértices en las puntas: su
    # tramo central quedaba sin medir y la malla salía «sin datos» = ok sin mirarla (oct 2026).
    rng = np.random.default_rng(0)
    ns = int(min(8000, max(1500, len(tris) * 6)))
    pick = rng.choice(len(tris), size=ns, p=area / tot)
    r1 = rng.random(ns)
    r2 = rng.random(ns)
    flip = r1 + r2 > 1
    r1[flip], r2[flip] = 1 - r1[flip], 1 - r2[flip]
    samp = a[pick] + (b[pick] - a[pick]) * r1[:, None] + (c[pick] - a[pick]) * r2[:, None]
    allp = np.vstack([allp, (samp - mu) @ v])
    x = allp[:, 0]
    lo, hi = x.min(), x.max()
    edges = np.linspace(lo, hi, BINS + 1)
    radii = []
    ring = []
    for i in range(BINS):
        m = (x >= edges[i]) & (x <= edges[i + 1])
        if m.sum() < 3:
            radii.append(np.nan)
            continue
        yz = allp[m][:, 1:]
        cc = (yz.max(0) + yz.min(0)) / 2
        dd = np.linalg.norm(yz - cc, axis=1)
        radii.append(float(np.percentile(dd, 95)))
        # (en un tubo los puntos de la sección están todos a la misma distancia del centro: un anillo; en un
        # cuerpo entero, las dos piernas o los brazos al lado del tronco dan distancias muy distintas)
        if i >= 3 and i < BINS - 3:
            ring.append(float(np.std(dd) / max(np.mean(dd), 1e-6)))
    r = np.array(radii)
    mid = r[3:BINS - 3]
    mid = mid[~np.isnan(mid)]
    if len(mid) == 0:
        return None
    rmid = float(np.median(mid))
    cv = float(np.std(mid) / max(np.mean(mid), 1e-6))

    def end(seq):
        seq = [s for s in seq if not np.isnan(s)]
        return seq[0] if seq else rmid

    caps = sum(1 for e in (end(r[:2]), end(r[::-1][:2])) if e < CAP_RATIO * rmid)
    # una bola o una tapa más ANCHA que el tubo en un extremo (el codo, la rodilla) también cuenta
    knob = sum(1 for e in (np.nanmax(r[:2]) if not np.all(np.isnan(r[:2])) else 0, np.nanmax(r[-2:]) if not np.all(np.isnan(r[-2:])) else 0) if e > 1.18 * rmid)
    # suavidad: aristas entre caras con poco ángulo, pesadas por el área de sus caras
    fn = cr / np.maximum(np.linalg.norm(cr, axis=1)[:, None], 1e-12)
    ek = {}
    smooth_area = 0.0
    sharp_area = 0.0
    keyed = np.sort(np.stack([tris[:, [0, 1]], tris[:, [1, 2]], tris[:, [2, 0]]], 1), axis=2)
    for fi in range(len(tris)):
        for e in keyed[fi]:
            k = (int(e[0]), int(e[1]))
            o = ek.get(k)
            if o is None:
                ek[k] = fi
            else:
                ang = math.degrees(math.acos(max(-1.0, min(1.0, float(fn[fi] @ fn[o])))))
                wgt = area[fi] + area[o]
                if ang < 25:
                    smooth_area += wgt
                else:
                    sharp_area += wgt
    smooth = smooth_area / max(smooth_area + sharp_area, 1e-9)
    ringcv = float(np.median(ring)) if ring else 1.0
    return {"ring": round(ringcv, 2), "L": round(L, 3), "W": round(W, 3), "T": round(T, 3), "elong": round(elong, 2), "flat": round(flat, 2),
            "cv": round(cv, 2), "caps": int(caps), "knob": int(knob), "smooth": round(smooth, 2), "tris": int(len(tris))}


def components(n, tris):
    """Trozos sueltos (vértices conectados por triángulos) -> lista de arrays de índices de triángulos."""
    import numpy as np

    parent = list(range(n))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for t in tris:
        a, b, c = find(int(t[0])), find(int(t[1])), find(int(t[2]))
        parent[b] = a
        parent[find(c)] = a
    roots = np.array([find(int(t[0])) for t in tris])
    out = {}
    for i, r in enumerate(roots):
        out.setdefault(int(r), []).append(i)
    return [np.array(v) for v in out.values()]


def verdict(m):
    if m is None:
        return "ok", ""
    round_ = m["flat"] < ROUND_MAX
    tube = m["cv"] < TUBE_CV and m.get("ring", 0) < RING_MAX
    capped = m["caps"] + m["knob"] >= 1
    smooth = m["smooth"] >= SMOOTH_MIN
    if m["elong"] >= ELONG_HIGH and round_ and tube and capped and smooth:
        return "ALTO", "tubo redondo alargado, liso y con la punta redondeada (o una bola en el extremo)"
    # (una caja larga de aristas vivas —un contenedor— no: le hace falta ser algo lisa o acabar en punta redonda)
    if m["elong"] >= ELONG_MED and m["flat"] < 2.5 and m.get("ring", 0) < RING_MAX and (m["smooth"] >= 0.45 or capped):
        return "MEDIO", "muy alargado, de sección redonda y liso o con la punta redondeada"
    return "ok", ""


RANK = {"ok": 0, "MEDIO": 1, "ALTO": 2}


def analyse_mesh(pts, tris):
    """La malla entera y su trozo principal (si llena casi todo el largo, es lo que se ve en la miniatura)."""
    import numpy as np

    whole = shape_metrics(pts, tris)
    level, why = verdict(whole)
    worst = {"level": level, "why": why, "metrics": whole, "scope": "malla"}
    comps = components(len(pts), tris)
    if len(comps) > 1 and whole and level != "ok":
        # (un tubo es UNA pieza seguida: unos puntos o unas rayas de brillo sueltos en fila no lo son. Si el
        # trozo más largo no llega a la mitad del largo de la malla, la malla entera no cuenta como tubo;
        # cada trozo sí se mira abajo)
        longest = 0.0
        for c in comps:
            sub = tris[c]
            used = np.unique(sub)
            q = pts[used] - pts[used].mean(0)
            if len(q) >= 2:
                longest = max(longest, float(np.linalg.norm(q.max(0) - q.min(0))))
        diag = float(np.linalg.norm(pts.max(0) - pts.min(0)))
        if longest < 0.5 * diag:
            worst = {"level": "ok", "why": "", "metrics": whole, "scope": "malla"}
            level = "ok"
        # se juntan los trozos que se tocan casi (un codo pegado al tubo cuenta como parte del tubo): se
        # mira el trozo más grande y, si llena al menos el 60 % del largo y del ancho de la malla (es lo que se
        # ve en la miniatura; el casco de una nave con alas grandes no), cuenta él solo
        big = max(comps, key=len)
        sub = tris[big]
        used = np.unique(sub)
        remap = -np.ones(len(pts), dtype=int)
        remap[used] = np.arange(len(used))
        m = shape_metrics(pts[used], remap[sub])
        if m and whole and m["L"] >= 0.6 * whole["L"] and m["W"] >= 0.6 * whole["W"]:
            lv, wy = verdict(m)
            if RANK[lv] > RANK[level]:
                worst = {"level": lv, "why": wy + " (su trozo principal)", "metrics": m, "scope": "trozo"}
    worst["pieces"] = len(comps)
    return worst


# ====================================================================== Blender
def load_fbx(path):
    import bpy
    import numpy as np

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=path)
    out = []
    dg = bpy.context.evaluated_depsgraph_get()
    for o in bpy.context.scene.objects:
        if o.type != "MESH":
            continue
        # (con armadura: la malla en reposo, como la ve Roblox en la miniatura)
        me = o.data
        me.calc_loop_triangles()
        pts = np.array([(o.matrix_world @ v.co)[:] for v in me.vertices], dtype=float)
        tris = np.array([t.vertices[:] for t in me.loop_triangles], dtype=int).reshape(-1, 3)
        out.append((o.name, pts, tris, len(o.material_slots)))
    return out


def render(path, objname, dest):
    """La malla sola, gris, sin textura, desde delante a 3/4 y de lado (como la miniatura de Roblox)."""
    import bpy
    from mathutils import Vector

    sc = bpy.context.scene
    target = None
    for o in sc.objects:
        if o.type == "MESH":
            o.hide_render = o.name != objname
            if o.name == objname:
                target = o
    if not target:
        return None
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 8
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 1
    sc.render.resolution_x, sc.render.resolution_y = 240, 240
    sc.view_settings.view_transform = "Standard"
    if not sc.world:
        sc.world = bpy.data.worlds.new("revision")
    sc.world.use_nodes = True
    bg = sc.world.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (0.75, 0.75, 0.75, 1)
    grey = bpy.data.materials.get("gris_revision") or bpy.data.materials.new("gris_revision")
    grey.diffuse_color = (0.45, 0.45, 0.45, 1)
    # Blender 5: los materiales siempre usan nodos; diffuse_color no llega al render
    bsdf = grey.node_tree.nodes.get("Principled BSDF") if grey.node_tree else None
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.45, 0.45, 0.45, 1)
    sc.view_layers[0].material_override = grey
    sun = bpy.data.objects.get("sol_revision")
    if not sun:
        sun = bpy.data.objects.new("sol_revision", bpy.data.lights.new("sol_revision", "SUN"))
        sun.data.energy = 2.5
        sc.collection.objects.link(sun)
    cam = bpy.data.objects.get("cam_revision")
    if not cam:
        cam = bpy.data.objects.new("cam_revision", bpy.data.cameras.new("cam_revision"))
        sc.collection.objects.link(cam)
    sc.camera = cam
    cam.data.type = "ORTHO"
    ws = [target.matrix_world @ Vector(c) for c in target.bound_box]
    lo = Vector((min(p.x for p in ws), min(p.y for p in ws), min(p.z for p in ws)))
    hi = Vector((max(p.x for p in ws), max(p.y for p in ws), max(p.z for p in ws)))
    ctr, rad = (lo + hi) / 2, max((hi - lo).length / 2, 0.01)
    files = []
    for tag, d in (("34", (0.55, -1.0, 0.35)), ("lado", (1.0, 0.0, 0.2))):
        dv = Vector(d).normalized()
        cam.location = ctr + dv * (rad * 4 + 1)
        cam.rotation_euler = (-dv).to_track_quat("-Z", "Z").to_euler()
        cam.data.ortho_scale = rad * 2.2
        cam.data.clip_end = rad * 10 + 10
        sun.rotation_euler = (-(dv + Vector((0.3, 0, 0.6))).normalized()).to_track_quat("-Z", "Z").to_euler()
        f = f"{dest}_{tag}.png"
        sc.render.filepath = f
        bpy.ops.render.render(write_still=True)
        files.append(f)
    try:
        from PIL import Image

        ims = [Image.open(f).convert("RGB") for f in files]
        sheet = Image.new("RGB", (sum(i.width for i in ims), ims[0].height), "white")
        x = 0
        for i in ims:
            sheet.paste(i, (x, 0))
            x += i.width
        sheet.save(dest + ".jpg", quality=80)
        for f in files:
            os.remove(f)
        return dest + ".jpg"
    except Exception:
        return files[0]


def render_grey6(path, objname, dest):
    """La malla sola, gris y sin textura desde 6 lados, en una hoja (la «vista gris» antes de subir)."""
    import bpy
    from mathutils import Vector

    sc = bpy.context.scene
    target = None
    for o in sc.objects:
        if o.type == "MESH":
            o.hide_render = o.name != objname
            if o.name == objname:
                target = o
    if not target:
        return None
    render(path, objname, dest + "__tmp")  # (prepara cámara, luz y gris; su hoja no se usa)
    for f in (dest + "__tmp.jpg", dest + "__tmp_34.png", dest + "__tmp_lado.png"):
        if os.path.exists(f):
            os.remove(f)
    sc.render.resolution_x, sc.render.resolution_y = 320, 320
    cam = bpy.data.objects.get("cam_revision")
    sun = bpy.data.objects.get("sol_revision")
    ws = [target.matrix_world @ Vector(c) for c in target.bound_box]
    lo = Vector((min(p.x for p in ws), min(p.y for p in ws), min(p.z for p in ws)))
    hi = Vector((max(p.x for p in ws), max(p.y for p in ws), max(p.z for p in ws)))
    ctr, rad = (lo + hi) / 2, max((hi - lo).length / 2, 0.01)
    # (el FBX entra con Y arriba convertido a Z arriba de Blender: el frente de Roblox, -Z, queda en +Y)
    views = (("frente", (0.0, 1.0, 0.08)), ("espalda", (0.0, -1.0, 0.08)), ("izquierda", (-1.0, 0.0, 0.08)),
             ("derecha", (1.0, 0.0, 0.08)), ("34", (0.6, 1.0, 0.35)), ("arriba", (0.05, 0.2, 1.0)))
    files = []
    for tag, d in views:
        dv = Vector(d).normalized()
        cam.location = ctr + dv * (rad * 4 + 1)
        cam.rotation_euler = (-dv).to_track_quat("-Z", "Y" if abs(dv.z) < 0.9 else "Z").to_euler()
        cam.data.ortho_scale = rad * 2.2
        cam.data.clip_end = rad * 10 + 10
        sun.rotation_euler = (-(dv + Vector((0.3, 0, 0.6))).normalized()).to_track_quat("-Z", "Z").to_euler()
        f = f"{dest}_{tag}.png"
        sc.render.filepath = f
        bpy.ops.render.render(write_still=True)
        files.append((tag, f))
    from PIL import Image, ImageDraw, ImageFont

    ims = [(t, Image.open(f).convert("RGB")) for t, f in files]
    w, h = ims[0][1].size
    sheet = Image.new("RGB", (w * 3, h * 2 + 30), "white")
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
    except Exception:
        font = None
    for i, (t, im) in enumerate(ims):
        x, y = (i % 3) * w, (i // 3) * h + 30
        sheet.paste(im, (x, y))
        d.text((x + 8, y + 6), t, fill=(30, 30, 30), font=font)
    d.text((8, 6), f"{os.path.basename(path)} · {objname} — sola, gris, sin textura (como la revisión de Roblox)", fill=(0, 0, 0), font=font)
    sheet.save(dest + ".jpg", quality=82)
    for _, f in files:
        os.remove(f)
    return dest + ".jpg"


def grey_review(files, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    made = []
    for path in files:
        try:
            meshes = load_fbx(path)
        except Exception as e:
            log(f"  ⚠️  {path}: {e}")
            continue
        base = os.path.splitext(os.path.basename(path))[0]
        for name, pts, tris, nmat in meshes:
            img = render_grey6(path, name, os.path.join(out_dir, f"{base}__{name}"))
            if img:
                made.append(img)
                log(f"  vista gris: {os.path.relpath(img, ROOT)}")
    return made


# ====================================================================== main
def review(files, draw, out_dir):
    rows = []
    for path in files:
        try:
            try:
                meshes = load_fbx(path)
            except Exception:  # (un segundo intento: el importador de FBX a veces falla una vez tras muchos)
                meshes = load_fbx(path)
        except Exception as e:  # (no se puede revisar = no se sube)
            rows.append({"file": os.path.relpath(path, ROOT), "mesh": "*", "level": "ERROR", "why": str(e)[-300:].replace("\n", " ")})
            continue
        base = os.path.splitext(os.path.basename(path))[0]
        for name, pts, tris, nmat in meshes:
            r = analyse_mesh(pts, tris)
            row = {"file": os.path.relpath(path, ROOT), "asset": base, "mesh": name, "level": r["level"], "why": r["why"],
                   "scope": r["scope"], "pieces": r["pieces"], "materials": nmat, **(r["metrics"] or {})}
            if draw and r["level"] != "ok":
                os.makedirs(out_dir, exist_ok=True)
                img = render(path, name, os.path.join(out_dir, f"{base}__{name}"))
                if img:
                    row["image"] = os.path.relpath(img, ROOT)
            rows.append(row)
    return rows


def write_report(rows, out_dir, kits):
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "informe.json"), "w") as f:
        json.dump(rows, f, indent=1, ensure_ascii=False)
    flagged = [r for r in rows if r["level"] != "ok"]
    L = ["# Revisión de mallas antes de subir (moderación)", "",
         "GENERADO por `scripts/audit/moderacion-mallas.py` (no editar a mano). Kits: " + ", ".join(kits) + ".", "",
         f"{len(rows)} mallas revisadas · **{sum(r['level'] == 'ALTO' for r in rows)} ALTO** · "
         f"{sum(r['level'] == 'MEDIO' for r in rows)} MEDIO · {sum(r['level'] == 'ERROR' for r in rows)} sin poder revisar.", "",
         "Las marcadas NO se suben (los scripts de subida lo comprueban). Imagen: la malla sola, gris y sin textura.", "",
         "| Nivel | Archivo | Malla | Alarg. | Sección | Var. radio | Puntas | Lisa | Trozos | Por qué |",
         "|---|---|---|---|---|---|---|---|---|---|"]
    for r in sorted(flagged, key=lambda r: (-RANK.get(r["level"], 3), r["file"], r["mesh"])):
        img = f" ([imagen]({os.path.relpath(os.path.join(ROOT, r['image']), out_dir)}))" if r.get("image") else ""
        L.append(f"| {r['level']} | {r['file']} | {r['mesh']}{img} | {r.get('elong', '')} | {r.get('flat', '')} | {r.get('cv', '')} | "
                 f"{r.get('caps', 0) + r.get('knob', 0) if 'caps' in r else ''} | {r.get('smooth', '')} | {r.get('pieces', '')} | {r['why']} |")
    with open(os.path.join(out_dir, "informe.md"), "w") as f:
        f.write("\n".join(L) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kits", default=",".join(KITS))
    ap.add_argument("--check", nargs="*", help="(scripts de subida) estos archivos; código 2 si hay alguna marcada")
    ap.add_argument("--sin-dibujos", action="store_true")
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--vista-gris", default="", help="carpeta: cada malla sola y gris desde 6 lados")
    args = ap.parse_args()
    try:
        import bpy  # noqa: F401
        import numpy  # noqa: F401
    except Exception:
        log("❌ Hace falta Blender como módulo de Python (pip install bpy==4.2.0) y numpy para revisar las mallas.")
        sys.exit(3)
    if args.check is not None:
        rows = review(args.check, False, args.out)
        if args.vista_gris:
            grey_review(args.check, args.vista_gris)
        allowed = {s.strip() for s in os.environ.get("MODERACION_PERMITIR", "").split(",") if s.strip()}
        bad = [r for r in rows if r["level"] != "ok" and r.get("asset", "") not in allowed]
        for r in rows:
            if r["level"] != "ok":
                tag = "permitida a mano" if r.get("asset", "") in allowed else r["level"]
                log(f"  ⛔ {r['file']} · {r['mesh']}: {tag} — {r['why']} (alarg. {r.get('elong')}, lisa {r.get('smooth')})")
        if any(r["level"] == "ERROR" for r in bad):
            sys.exit(3)
        sys.exit(2 if bad else 0)
    kits = [k.strip() for k in args.kits.split(",") if k.strip() in KITS]
    files = []
    for k in kits:
        files += sorted(glob.glob(os.path.join(ROOT, KITS[k])))
    rows = review(files, not args.sin_dibujos, args.out)
    write_report(rows, args.out, kits)
    if args.vista_gris:
        grey_review(files, args.vista_gris)
    flagged = [r for r in rows if r["level"] != "ok"]
    log(f"{len(rows)} mallas · {len(flagged)} marcadas -> {os.path.relpath(os.path.join(args.out, 'informe.md'), ROOT)}")
    for r in flagged:
        log(f"  {r['level']:5} {r['file']} · {r['mesh']}: elong {r.get('elong')} sección {r.get('flat')} cv {r.get('cv')} puntas {r.get('caps')}+{r.get('knob')} lisa {r.get('smooth')}")


if __name__ == "__main__":
    main()
