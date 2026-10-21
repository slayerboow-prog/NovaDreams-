#!/usr/bin/env python3
"""Vista previa de los 6 planos del fondo marino v3 (docs/mar/v3-objetivo.md) en Blender. NO es Roblox.

Lo que dibuja sale del MISMO código del juego, volcado por scripts/map/orillas-export.luau (shared/Sea/ShoreReef:
relieve del terreno y decorado que plantaría el MÓVIL alrededor de la cámara, con su LOD; los peces como los pone
SeaLife; la luz y la bruma de shared/Sea/OceanBiomes.look). Las mallas son las del kit subido (assets/mar/*.fbx) con
sus texturas (assets/mar/tex); las que van con la paleta («Tint»), con el color de la paleta y el grano del
material Salt de Roblox (corales) o liso (plantas). La cámara es la del móvil: 70° vertical, 16:9.

Imitaciones (lo que en Roblox se verá distinto, docs/mar/v3/revision.md):
  * la bruma del agua de Roblox: aquí, mezcla lineal hacia el color Fog de la zona entre FogStart y Visibility
  * las cáusticas: la textura subida proyectada sobre el suelo en 45 studs alrededor de la cámara (en el juego,
    9 láminas a la altura del suelo: Controllers/ReefZoneFx)
  * los haces de sol (Beam) y las motas (ParticleEmitter): tiras transparentes y puntos
  * la superficie vista desde abajo, el Bloom y la exposición de Roblox: aproximados

Uso (desde la carpeta roblox/; bpy 4.2):
    lune run scripts/map/orillas-export.luau /tmp/v3/despues.json
    lune run scripts/map/orillas-export.luau /tmp/v3/antes.json --antes
    lune run scripts/map/nacara-export.luau /tmp/v3/nacara.json
    python3 scripts/map/orillas_preview.py /tmp/v3/despues.json docs/mar/v3/plano --nacara /tmp/v3/nacara.json
      [--solo 1,2] [--muestras 32] [--ancho 1280] [--etiqueta "ronda 1"]
"""
import argparse
import json
import math
import os
import random

import bpy  # noqa: I001
import bmesh
import numpy as np
from mathutils import Vector, Matrix, Euler
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MAR = os.path.join(ROOT, "assets", "mar")


def rb(x, y, z):
    """Roblox (x, y, z) -> Blender (x, -z, y)."""
    return Vector((x, -z, y))


def lin(c):
    """sRGB 0..255 -> lineal 0..1 (los colores de Blender)."""
    out = []
    for v in c[:3]:
        v = v / 255.0
        out.append(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4)
    return out


def lst(v):
    """(una tabla vacía de Luau sale como {} en JSON)"""
    return v if isinstance(v, list) else []


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


# ---------------------------------------------------------------------------
# Materiales
# ---------------------------------------------------------------------------
_mats = {}
_caustic_img = None
CAUSTIC = {"on": False, "cx": 0.0, "cy": 0.0, "r": 45.0, "k": 0.5}


def caustic_mix(nt, base_socket, out_input):
    """Suma las cáusticas (textura subida, 18 studs por baldosa, alrededor de la cámara) a un color."""
    global _caustic_img
    if not CAUSTIC["on"]:
        nt.links.new(base_socket, out_input)
        return
    if _caustic_img is None:
        _caustic_img = bpy.data.images.load(os.path.join(MAR, "tex", "causticas.png"))
    n = nt.nodes
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Position"], sep.inputs[0])
    comb = n.new("ShaderNodeCombineXYZ")
    for i, axis in enumerate(("X", "Y")):
        m = n.new("ShaderNodeMath")
        m.operation = "DIVIDE"
        m.inputs[1].default_value = 18.0
        nt.links.new(sep.outputs[axis], m.inputs[0])
        nt.links.new(m.outputs[0], comb.inputs[i])
    tex = n.new("ShaderNodeTexImage")
    tex.image = _caustic_img
    nt.links.new(comb.outputs[0], tex.inputs["Vector"])
    # máscara: radio alrededor de la cámara y solo caras que miran arriba
    dx = n.new("ShaderNodeVectorMath")
    dx.operation = "DISTANCE"
    dx.inputs[1].default_value = (CAUSTIC["cx"], CAUSTIC["cy"], 0)
    flat = n.new("ShaderNodeCombineXYZ")
    nt.links.new(sep.outputs["X"], flat.inputs[0])
    nt.links.new(sep.outputs["Y"], flat.inputs[1])
    nt.links.new(flat.outputs[0], dx.inputs[0])
    ramp = n.new("ShaderNodeMapRange")
    ramp.inputs["From Min"].default_value = CAUSTIC["r"] * 0.75
    ramp.inputs["From Max"].default_value = CAUSTIC["r"]
    ramp.inputs["To Min"].default_value = CAUSTIC["k"]
    ramp.inputs["To Max"].default_value = 0.0
    nt.links.new(dx.outputs["Value"], ramp.inputs["Value"])
    up = n.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Normal"], up.inputs[0])
    upm = n.new("ShaderNodeMath")
    upm.operation = "MULTIPLY"
    nt.links.new(up.outputs["Z"], upm.inputs[0])
    nt.links.new(ramp.outputs[0], upm.inputs[1])
    tint = n.new("ShaderNodeMix")
    tint.data_type = "RGBA"
    tint.blend_type = "ADD"
    nt.links.new(upm.outputs[0], tint.inputs["Factor"])
    nt.links.new(base_socket, tint.inputs["A"])
    nt.links.new(tex.outputs["Color"], tint.inputs["B"])
    nt.links.new(tint.outputs["Result"], out_input)


def material(key, color, rough=0.85, grain=None, emission=None, alpha=1.0, image=None, normal=None):
    """grain: None | 'salt' (cristal agrietado, como el Salt de Roblox) | 'sand' | 'rock' | 'plants'."""
    if key in _mats:
        return _mats[key]
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes
    bsdf = n["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rough
    base = None
    if image:
        t = n.new("ShaderNodeTexImage")
        t.image = bpy.data.images.load(image)
        base = t.outputs["Color"]
        if normal:
            tn = n.new("ShaderNodeTexImage")
            tn.image = bpy.data.images.load(normal)
            tn.image.colorspace_settings.name = "Non-Color"
            nm = n.new("ShaderNodeNormalMap")
            nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
            nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    else:
        rgb = n.new("ShaderNodeRGB")
        rgb.outputs[0].default_value = (*lin(color), 1)
        base = rgb.outputs[0]
        if grain:
            tc = n.new("ShaderNodeTexCoord")
            scale = {"salt": 0.9, "sand": 0.9, "rock": 0.35, "plants": 2.0, "mud": 0.4, "snow": 2.6}[grain]
            vor = n.new("ShaderNodeTexVoronoi")
            vor.feature = "DISTANCE_TO_EDGE"
            vor.inputs["Scale"].default_value = scale
            nt.links.new(tc.outputs["Object" if grain in ("plants",) else "Object"], vor.inputs["Vector"])
            noi = n.new("ShaderNodeTexNoise")
            noi.inputs["Scale"].default_value = scale * 6
            nt.links.new(tc.outputs["Object"], noi.inputs["Vector"])
            crack = n.new("ShaderNodeMapRange")
            crack.inputs["From Min"].default_value = 0.0
            crack.inputs["From Max"].default_value = 0.06 if grain == "salt" else 0.12
            # (Snow de Roblox: grano blando, sin grietas: casi no se marcan los bordes)
            crack.inputs["To Min"].default_value = 0.72 if grain == "salt" else (0.95 if grain == "snow" else 0.82)
            crack.inputs["To Max"].default_value = 1.0
            nt.links.new(vor.outputs["Distance"], crack.inputs["Value"])
            mul = n.new("ShaderNodeMix")
            mul.data_type = "RGBA"
            mul.blend_type = "MULTIPLY"
            mul.inputs["Factor"].default_value = 1.0
            nt.links.new(base, mul.inputs["A"])
            g = n.new("ShaderNodeCombineColor")
            nt.links.new(crack.outputs[0], g.inputs[0])
            nt.links.new(crack.outputs[0], g.inputs[1])
            nt.links.new(crack.outputs[0], g.inputs[2])
            nt.links.new(g.outputs[0], mul.inputs["B"])
            mul2 = n.new("ShaderNodeMix")
            mul2.data_type = "RGBA"
            mul2.blend_type = "MULTIPLY"
            mul2.inputs["Factor"].default_value = 0.35
            nt.links.new(mul.outputs["Result"], mul2.inputs["A"])
            nt.links.new(noi.outputs["Color"], mul2.inputs["B"])
            base = mul2.outputs["Result"]
            bump = n.new("ShaderNodeBump")
            bump.inputs["Strength"].default_value = 0.35
            nt.links.new(crack.outputs[0], bump.inputs["Height"])
            nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    caustic_mix(nt, base, bsdf.inputs["Base Color"])
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*lin(emission[0]), 1)
        bsdf.inputs["Emission Strength"].default_value = emission[1]
    if alpha < 1:
        bsdf.inputs["Alpha"].default_value = alpha
        m.blend_method = "BLEND"
    _mats[key] = m
    return m


TERRAIN_COLORS = {
    # TerrainPalette / TerrainBuilder.Colors (lo que sale en el juego)
    "Salt": ((204, 186, 146), "salt"),
    "Snow": ((204, 186, 146), "snow"),
    "Sandstone": ((190, 166, 122), "sand"),
    "Limestone": ((200, 192, 166), "rock"),
    "Slate": ((100, 98, 94), "rock"),
    "Basalt": ((46, 52, 66), "rock"),
    "Rock": ((124, 117, 106), "rock"),
    "Mud": ((74, 70, 58), "mud"),
    "Sand": ((214, 190, 140), "sand"),  # (la playa: textura de arena del dueño; aquí, arena)
    "LeafyGrass": ((82, 124, 52), "plants"),
    "Ground": ((130, 110, 80), "mud"),
}


# ---------------------------------------------------------------------------
# Escena de un plano
# ---------------------------------------------------------------------------
def build_terrain(fr):
    """El terreno con su relieve. El material de cada cara es el que más se repite en 6×6 studs alrededor (Roblox
    mezcla los vóxeles de 4 studs; un material por cara de 2 studs dibujaba bordes de polígono que no existen)."""
    t = fr["Terrain"]
    n, step, x0, z0 = t["N"], t["Step"], t["X0"], t["Z0"]
    H = np.array(t["H"]).reshape(n, n)
    M = np.array(t["M"]).reshape(n, n)
    names = t["Materials"]
    # moda en 3×3 vértices, dos veces
    for _ in range(2):
        pad = np.pad(M, 1, mode="edge")
        stack = np.stack([pad[1 + dy: 1 + dy + n, 1 + dx: 1 + dx + n] for dy in (-1, 0, 1) for dx in (-1, 0, 1)])
        best = np.zeros_like(M)
        bestc = np.zeros_like(M)
        for v in np.unique(M):
            c = (stack == v).sum(0)
            upd = c > bestc
            best[upd] = v
            bestc[upd] = c[upd]
        M = best
    verts, faces, fmat = [], [], []
    for j in range(n):
        for i in range(n):
            verts.append(tuple(rb(x0 + i * step, H[j, i], z0 + j * step)))
    for j in range(n - 1):
        for i in range(n - 1):
            a = j * n + i
            faces.append((a, a + 1, a + 1 + n, a + n))
            cs = [M[j, i], M[j, i + 1], M[j + 1, i], M[j + 1, i + 1]]
            fmat.append(max(set(cs), key=cs.count))
    me = bpy.data.meshes.new("terreno")
    me.from_pydata(verts, [], faces)
    ob = bpy.data.objects.new("terreno", me)
    bpy.context.scene.collection.objects.link(ob)
    for idx, name in enumerate(names):
        col, grain = TERRAIN_COLORS.get(name, ((200, 200, 200), "sand"))
        ob.data.materials.append(material("T_" + name, col, grain=grain))
    for p, mi in zip(me.polygons, fmat):
        p.material_index = int(mi) - 1
        p.use_smooth = True
    return ob


_proto = {}
_data = {}


def proto(name, kind):
    """La malla importada del FBX (una vez); kind: 'kit' | 'fauna'."""
    key = name
    if key in _proto:
        return _proto[key]
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(MAR, name + ".fbx"), axis_forward="-Z", axis_up="Y")
    new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    ob = new[0]
    for o in bpy.data.objects:
        if o not in before and o is not ob:
            bpy.data.objects.remove(o, do_unlink=True)
    # al origen, con su caja en el centro
    bpy.context.view_layer.update()
    ob.data.transform(ob.matrix_world)
    ob.matrix_world = Matrix.Identity(4)
    co = np.array([v.co[:] for v in ob.data.vertices])
    lo, hi = co.min(0), co.max(0)
    c = (lo + hi) / 2
    ob.data.transform(Matrix.Translation(Vector((-c[0], -c[1], -lo[2]))))  # pie en z = 0
    ob.hide_render = True
    ob.hide_viewport = True
    _proto[key] = (ob, hi - lo)
    return _proto[key]


def kit_material(name, info, tint, night, glow_color=None):
    lower = name.lower()
    col = os.path.join(MAR, "tex", lower + "_color.png")
    nor = os.path.join(MAR, "tex", lower + "_normal.png")
    if info.get("Tint") or not os.path.exists(col):
        c = tint or (200, 200, 200)
        if info.get("Glow") and night:
            return material(f"G_{name}_{c}", c, emission=(glow_color or c, 4.0))
        plant = name in ("Pradera", "AlgaAncha", "KelpGigante")
        return material(f"K_{name}_{c}", c, rough=0.7, grain=None if plant else "salt")
    return material("X_" + name, None, rough=0.9, image=col, normal=nor if os.path.exists(nor) else None)


def place(name, kind, x, y, z, height=None, length=None, yaw=0.0, mat=None, sizeinfo=None):
    ob0, ext = proto(name, kind)
    ob = ob0.copy()
    ob.hide_render = False
    ob.hide_viewport = False
    bpy.context.scene.collection.objects.link(ob)
    if height is not None:
        k = height / max(ext[2], 1e-6)
    else:
        k = length / max(ext[1], 1e-6)
    ob.scale = (k, k, k)
    ob.location = rb(x, y, z)
    ob.rotation_euler = Euler((0, 0, yaw))
    # (en el juego el decorado y los peces no dan sombra: CastShadow = false)
    ob.visible_shadow = False
    if mat is not None:
        key = (name, mat.name)
        data = _data.get(key)
        if data is None:
            data = ob0.data.copy()
            data.materials.clear()
            data.materials.append(mat)
            _data[key] = data
        ob.data = data
    return ob


def diver(p, look):
    """El buceador: un R15 de bloques tumbado, mirando hacia look (tripa abajo)."""
    yaw = math.atan2(-look[0], -look[2])
    root = Matrix.Translation(rb(*p)) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(math.radians(-85), 4, "X")
    # (tronco, cabeza, brazos estirados delante de la cabeza —braza—, piernas, botella amarilla a la espalda)
    parts = [((2, 1, 2), (0, 0, 0), (52, 60, 78)), ((1.2, 1.2, 1.2), (0, 0, 1.7), (210, 170, 140)), ((0.8, 0.8, 2.2), (-0.7, 0, 3.1), (52, 60, 78)),
             ((0.8, 0.8, 2.2), (0.7, 0, 3.1), (52, 60, 78)), ((0.9, 0.9, 2.4), (-0.5, 0, -2.2), (34, 36, 48)), ((0.9, 0.9, 2.4), (0.5, 0, -2.2), (34, 36, 48)),
             ((0.8, 0.7, 1.6), (0, -0.85, 0.2), (240, 200, 60))]
    for size, off, col in parts:
        bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.active_object
        o.scale = Vector((size[0], size[1], size[2]))
        o.matrix_world = root @ Matrix.Translation(Vector((off[0], off[1], off[2]))) @ Matrix.Diagonal((size[0], size[1], size[2], 1))
        o.data.materials.append(material(f"D{col}", col, rough=0.6))


def nacara_parts(path, frame, kit=None, night=False):
    data = json.load(open(path, encoding="utf-8"))
    for p in data["Parts"]:
        pos = p["Pos"]
        if (pos[0] - frame["Player"][0]) ** 2 + (pos[2] - frame["Player"][2]) ** 2 > 360 ** 2:
            continue
        if p["Shape"] == "Mesh" and p.get("Kind"):
            # (las mallas del kit de World/NacaraDecor, como en el juego publicado)
            name = p["Kind"]
            info = (kit or {}).get(name, {})
            r = p["Rot"]
            col = tuple(int(c * 255) for c in p["Color"])
            if name == "AgujaNacar":
                # (las agujas de nácar de NacaraDecor.skyline: la malla de la aguja de roca, sin textura, con brillo)
                ob = place("RocaAguja", "kit", pos[0], pos[1] - p["Size"][1] / 2, pos[2], height=p["Size"][1], yaw=math.atan2(r[2], r[0]),
                           mat=material(f"nacar{col}", col, rough=0.25))
                ob.scale = (ob.scale[0] * 0.55, ob.scale[1] * 0.55, ob.scale[2])
                continue
            place(name, "kit", pos[0], pos[1] - p["Size"][1] / 2, pos[2], height=p["Size"][1], yaw=math.atan2(r[2], r[0]),
                  mat=kit_material(name, info, col, night))
            continue
        r = p["Rot"]
        R = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8])))
        conv = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
        RB = conv @ R @ conv.transposed()
        sx, sy, sz = p["Size"]
        shape = p["Shape"]
        if shape in ("Ball", "Ellipsoid"):
            bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=0.5)
        elif shape == "Cylinder":
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.5, depth=1)
            bpy.context.active_object.data.transform(Matrix.Rotation(math.pi / 2, 4, "Y"))
        else:
            bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.active_object
        o.matrix_world = Matrix.Translation(rb(*pos)) @ RB.to_4x4() @ Matrix.Diagonal((sx, sz, sy, 1))
        col = [int(c * 255) for c in p["Color"]]
        neon = p.get("Material") == "Neon"
        o.data.materials.append(material(f"N{col}{neon}{p.get('Transparency', 0):.1f}", col, rough=0.5, emission=(col, 3.0) if neon else None,
                                         alpha=1 - p.get("Transparency", 0)))
    for lt in data.get("Lights", []):
        if (lt["Pos"][0] - frame["Player"][0]) ** 2 + (lt["Pos"][2] - frame["Player"][2]) ** 2 > 260 ** 2:
            continue
        ld = bpy.data.lights.new("l", "POINT")
        ld.energy = 900 * lt.get("Brightness", 1)
        ld.color = lin([c * 255 for c in lt["Color"]])
        ld.shadow_soft_size = 2
        lo = bpy.data.objects.new("l", ld)
        lo.location = rb(*lt["Pos"])
        bpy.context.scene.collection.objects.link(lo)


def render_frame(fr, kit, fauna, out, args):
    reset()
    _mats.clear()
    _proto.clear()
    _data.clear()
    global _caustic_img
    _caustic_img = None
    scene = bpy.context.scene
    look = fr["Look"]
    night = fr["Night"] > 0.5
    cam = fr["Cam"]
    # (como ReefZoneFx: 1 − transparencia = (0,15 + 0,3·día)·(1 − (hondo/40)²), hondo = studs de agua sobre el fondo)
    water = max(0.0, -2 - (fr["Player"][1] - 7))
    fade = min(water / 40.0, 1.0)
    CAUSTIC.update(on=bool(fr["Caustics"]), cx=cam[0], cy=-cam[2], r=45.0, k=0.45 * max(0.0, 1 - fade * fade))
    build_terrain(fr)
    # decorado
    for it in lst(fr["Items"]):
        info = kit.get(it["Piece"], {})
        tint = tuple(it["Tint"]) if it.get("Tint") else None
        gl = None
        if night and it["Piece"] in ("AnemonaLuz", "SetaLuz"):
            gl = random.Random(int(it["X"] * 7 + it["Z"])).choice([(90, 245, 255), (255, 130, 230), (150, 255, 190)])
            tint = gl
            info = dict(info, Glow=True)
        ob = place(it["Piece"], "kit", it["X"], it["Y"], it["Z"], height=it["H"], yaw=it["Yaw"], mat=kit_material(it["Piece"], info, tint, night, gl))
        if it.get("Up"):
            # (v4) en la cara del veril: crece hacia fuera (como SeaBiome: CFrame.fromMatrix con «up» = la cara)
            u = it["Up"]
            up = rb(u[0], u[1], u[2]) - rb(0, 0, 0)
            q = Vector((0, 0, 1)).rotation_difference(up.normalized())
            ob.rotation_euler = (q.to_matrix() @ Matrix.Rotation(it["Yaw"], 3, "Z")).to_euler()
    # (v4) la roca del veril: bolas de roca (Roblox: FillBall) y las bocas de las cuevas (oscuras)
    for r in lst(fr.get("Rocks", [])):
        if (r["X"] - cam[0]) ** 2 + (r["Z"] - cam[2]) ** 2 > 260 ** 2:
            continue
        bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=20, radius=r["R"], location=rb(r["X"], r["Y"], r["Z"]))
        o = bpy.context.active_object
        col, grain = TERRAIN_COLORS.get(r["Material"], ((124, 117, 106), "rock"))
        o.data.materials.append(material("T_" + r["Material"], col, grain=grain))
        for poly in o.data.polygons:
            poly.use_smooth = True
    for c in lst(fr.get("Caves", [])):
        if (c["X"] - cam[0]) ** 2 + (c["Z"] - cam[2]) ** 2 > 220 ** 2:
            continue
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=c["R"] * 0.85, location=rb(c["X"], c["Y"], c["Z"]))
        o = bpy.context.active_object
        o.data.materials.append(material("cueva", (6, 14, 26), rough=1.0))
    for f in lst(fr["Fish"]) + lst(fr["Big"]):
        name = f["Piece"]
        lower = name.lower()
        m = material("F_" + name + ("g" if f.get("Glow") else ""), (240, 160, 220) if f.get("Glow") else None,
                     image=None if f.get("Glow") else os.path.join(MAR, "tex", lower + "_color.png"),
                     emission=((240, 150, 230), 3.0) if f.get("Glow") else None, alpha=0.75 if name == "Medusa" else 1.0)
        yaw = math.atan2(-f["DX"], f["DZ"])
        place(name, "fauna", f["X"], f["Y"], f["Z"], length=f["Length"], yaw=yaw, mat=m)
        if f.get("Trail"):
            # (v4: pista de movimiento —NO está en el juego—: una estela tenue detrás de cada pez)
            dx, dz = f["DX"], f["DZ"]
            mm = math.hypot(dx, dz) or 1.0
            dx, dz = dx / mm, dz / mm
            L = f["Length"] * 1.8
            bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=f["Length"] * 0.18, radius2=0.0, depth=L,
                                            location=rb(f["X"] - dx * (L / 2 + f["Length"] * 0.4), f["Y"], f["Z"] - dz * (L / 2 + f["Length"] * 0.4)))
            o = bpy.context.active_object
            d = rb(-dx, 0, -dz) - rb(0, 0, 0)
            o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
            o.visible_shadow = False
            o.data.materials.append(material("estela", (220, 240, 255), emission=((220, 240, 255), 0.3), alpha=0.07))
    p = fr["Player"]
    tgt = fr["Target"]
    diver(p, (tgt[0] - cam[0], 0, tgt[2] - cam[2]))
    if fr.get("Nacara") and args.nacara:
        nacara_parts(args.nacara, fr, kit, night)
    # superficie del agua (vista desde abajo: brillante y con olas)
    if fr["Meters"] < 30:
        bpy.ops.mesh.primitive_plane_add(size=900, location=rb(cam[0], -2, cam[2]))
        sp = bpy.context.active_object
        tintc = look["Tint"]
        sm = material("superficie", tintc, rough=0.2, emission=(tintc, 0.9 if not night else 0.25))
        sp.data.materials.append(sm)
    # haces de sol (Beam) de día
    rays = look.get("Rays", 0)
    if not night and rays > 0.05:
        rnd = random.Random(3)
        for i in range(10):
            ang = rnd.uniform(-0.9, 0.9)
            d = rnd.uniform(25, 110)
            dx, dz = tgt[0] - cam[0], tgt[2] - cam[2]
            m_ = math.hypot(dx, dz)
            dx, dz = dx / m_, dz / m_
            cx = cam[0] + (dx * math.cos(ang) - dz * math.sin(ang)) * d
            cz = cam[2] + (dz * math.cos(ang) + dx * math.sin(ang)) * d
            bpy.ops.mesh.primitive_plane_add(size=1)
            o = bpy.context.active_object
            length = 60
            o.scale = (rnd.uniform(5, 12), length, 1)
            o.location = rb(cx, -2 - length / 2 * 0.9, cz)
            o.rotation_euler = Euler((math.radians(90 + 18), 0, math.atan2(dx, dz) + rnd.uniform(-0.3, 0.3)))
            o.data.materials.append(material(f"rayo{i}", (200, 245, 255), emission=((200, 245, 255), 0.5 * rays), alpha=0.07 * rays + 0.02))
    # motas / plancton cerca de la cámara
    rnd = random.Random(5)
    for i in range(120):
        q = Vector((cam[0] + rnd.uniform(-22, 22), cam[1] + rnd.uniform(-10, 8), cam[2] + rnd.uniform(-22, 22)))
        if (q - Vector(cam)).length < 4:
            continue  # (una mota pegada a la cámara salía como un cubo blanco enorme: ronda 1 y 2)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.05 if not night else 0.08, location=rb(q.x, q.y, q.z))
        o = bpy.context.active_object
        c = (220, 240, 230) if not night else rnd.choice([(90, 240, 255), (180, 120, 255), (255, 120, 210)])
        o.data.materials.append(material(f"mota{c}", c, emission=(c, 1.5 if not night else 6.0)))
    # luz: sol (de día) o luna, y el ambiente del agua (Lighting.Ambient)
    sun = bpy.data.lights.new("sol", "SUN")
    # (la luz baja con la profundidad: Roblox oscurece con OceanBiomes.look —Exposure, DarkFog—; aquí, el sol)
    sun.energy = (3.2 if not night else 0.35) * math.exp(-max(fr["Meters"], 0) / 22)
    sun.color = lin((255, 250, 235) if not night else (150, 188, 255))
    sun.angle = math.radians(8)
    so = bpy.data.objects.new("sol", sun)
    so.rotation_euler = Euler((math.radians(25), math.radians(15), math.radians(30)))
    scene.collection.objects.link(so)
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    amb = look.get("Ambient", look["Fog"])
    bg.inputs["Color"].default_value = (*lin(amb), 1)
    bg.inputs["Strength"].default_value = (0.9 if not night else 0.55) * (0.55 + 0.45 * math.exp(-max(fr["Meters"], 0) / 22))
    scene.world = world
    # cámara del móvil
    cd = bpy.data.cameras.new("cam")
    cd.sensor_fit = "VERTICAL"
    cd.angle_y = math.radians(70)
    cd.clip_end = 600
    co = bpy.data.objects.new("cam", cd)
    scene.collection.objects.link(co)
    co.location = rb(*cam)
    direction = rb(*tgt) - rb(*cam)
    co.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = co
    # render
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.muestras
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 3
    scene.render.resolution_x = args.ancho
    scene.render.resolution_y = args.ancho * 9 // 16
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.exposure = float(look.get("Exposure", 0)) + (0.3 if night else 0.0)
    # bruma (pasada de niebla + composición): de FogStart a Visibility, al color Fog de la zona
    vl = scene.view_layers[0]
    vl.use_pass_mist = True
    vis = float(look.get("Visibility", 180))
    world.mist_settings.start = min(30.0, vis * 0.2)
    world.mist_settings.depth = vis - world.mist_settings.start
    world.mist_settings.falloff = "LINEAR"
    scene.use_nodes = True
    nt = scene.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    rl = nt.nodes.new("CompositorNodeRLayers")
    mix = nt.nodes.new("CompositorNodeMixRGB")
    mix.inputs[2].default_value = (*lin(look["Fog"]), 1)
    pw = nt.nodes.new("CompositorNodeMath")
    pw.operation = "POWER"
    pw.inputs[1].default_value = 0.8
    nt.links.new(rl.outputs["Mist"], pw.inputs[0])
    nt.links.new(pw.outputs[0], mix.inputs[0])
    nt.links.new(rl.outputs["Image"], mix.inputs[1])
    # tinte del agua (ColorCorrection «Tint» de Roblox)
    tint = nt.nodes.new("CompositorNodeMixRGB")
    tint.blend_type = "MULTIPLY"
    tint.inputs[0].default_value = 0.45
    tint.inputs[2].default_value = (*lin(look["Tint"]), 1)
    nt.links.new(mix.outputs[0], tint.inputs[1])
    comp = nt.nodes.new("CompositorNodeComposite")
    nt.links.new(tint.outputs[0], comp.inputs[0])
    scene.render.filepath = out
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 90
    bpy.ops.render.render(write_still=True)
    label(out, fr, args)


def label(path, fr, args):
    im = Image.open(path).convert("RGB")
    W, H = im.size
    d = ImageDraw.Draw(im, "RGBA")
    # zonas del HUD del móvil (franja de arriba y esquinas de abajo): solo un borde
    d.rectangle((0, 0, W, int(H * 0.12)), outline=(255, 255, 255, 70), width=2)
    d.rectangle((0, int(H * 0.68), int(W * 0.22), H), outline=(255, 255, 255, 70), width=2)
    d.rectangle((int(W * 0.78), int(H * 0.68), W, H), outline=(255, 255, 255, 70), width=2)
    try:
        font = ImageFont.truetype("DejaVuSans.ttf", max(14, W // 64))
    except OSError:
        font = ImageFont.load_default()
    txt = f"VISTA PREVIA, NO ES ROBLOX · plano {fr['Id']}: {fr['Name']} · zona {fr['Zone']} · {fr['Meters']:.1f} m · {len(lst(fr['Items']))} mallas"
    if args.etiqueta:
        txt += " · " + args.etiqueta
    d.rectangle((0, H - int(H * 0.05), W, H), fill=(0, 0, 0, 140))
    d.text((10, H - int(H * 0.045)), txt, fill=(255, 255, 255), font=font)
    im.save(path, quality=90)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("datos")
    ap.add_argument("salida", help="prefijo: <salida>-<n>.jpg")
    ap.add_argument("--nacara", default=None)
    ap.add_argument("--solo", default=None)
    ap.add_argument("--muestras", type=int, default=24)
    ap.add_argument("--ancho", type=int, default=1280)
    ap.add_argument("--etiqueta", default="")
    args = ap.parse_args()
    data = json.load(open(args.datos, encoding="utf-8"))
    os.makedirs(os.path.dirname(os.path.abspath(args.salida)), exist_ok=True)
    for fr in data["Frames"]:
        if args.solo and fr["Id"] not in args.solo.split(","):
            continue
        out = f"{args.salida}-{fr['Id']}.jpg"
        render_frame(fr, data["Kit"], data["Fauna"], out, args)
        print("->", out, flush=True)


if __name__ == "__main__":
    main()
