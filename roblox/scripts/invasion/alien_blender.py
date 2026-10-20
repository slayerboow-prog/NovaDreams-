#!/usr/bin/env python3
"""Los alienígenas v2 de la Invasión de la Grieta hechos en Blender con Python (docs/invasion.md, «v2»):
tropas (4 por raza), el rey, las naves (caza, dron, nave de desembarco) y la gente transformada de las
5 razas, como MALLAS con texturas PBR horneadas. Mismo camino que la nave (scripts/nave/nave_blender.py):
modelado procedural, materiales procedurales horneados a color / normal / rugosidad / metal, FBX para
subir a Roblox, versión lejana (LOD) y vistas previas.

Necesita Blender como módulo de Python:   pip install bpy==4.2.0   (Python 3.11; todo en CPU)

Uso (desde la carpeta roblox/):
    python3 scripts/invasion/alien_blender.py                 todo (mallas, texturas, LOD, Luau, imágenes)
    python3 scripts/invasion/alien_blender.py --no-render     sin las imágenes
    python3 scripts/invasion/alien_blender.py --only Vortidos (una raza: para probar; no escribe el Luau)

Salida (--out, por defecto assets/invasion):
    <Raza>2_<Tipo>.fbx    un FBX por modelo: UNA malla con esqueleto (Cuerpo y CuerpoBrillo = Neon, un
                          hueso por segmento: Body, Head, ArmL…) y LOD / LODBrillo (la versión lejana);
                          ≤ 20.000 triángulos por malla. Nunca un segmento suelto: Roblox revisa cada malla
                          sola y gris, y retiró un antebrazo y una pierna sueltos (docs/bugs/moderacion/)
    tex/<juego>_<mapa>.png  <Raza>2_tropas (1024) y <Raza>2_naves (512): color, normal, rugosidad, metal
    manifest.json         modelos, segmentos (centro, tamaño, pivote, padre), triángulos y texturas
y src/shared/Invasion/AlienMallas.luau (lo mismo para el juego) y docs/invasion/v2/*.jpg.
"""
import argparse
import json
import math
import os
import sys
import time

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "nave"))

import alien_diseno as D  # noqa: E402
import nave_blender as NB  # noqa: E402  (horneado, UV, exportar: lo mismo que la nave)
from geo import to_blender  # noqa: E402

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

MAX_TRIS = 20000  # por malla (MeshPart)
BUDGET = {"Troop": 10000, "King": 15000, "Ship": 12000, "Dropship": 16000, "Creature": 5000}  # por modelo (sin LOD; los Vórtidos de cristal: vortidos_blender.py)
LOD_MAX = {"Troop": 1800, "King": 2600, "Ship": 2000, "Dropship": 3000, "Creature": 1200}
LOD_MIN = 1500  # por debajo de esto el modelo no lleva LOD (no ahorra nada)
SET_SIZE = {"tropas": 1024, "naves": 512}
STYLE = {"Vortidos": "facets", "Morfagos": "veins", "Ferrocefalos": "rust", "Luminidos": "porcelain", "Brumaridos": "stone"}
RBX_MATERIAL = {"Vortidos": "SmoothPlastic", "Morfagos": "SmoothPlastic", "Ferrocefalos": "Metal", "Luminidos": "SmoothPlastic", "Brumaridos": "SmoothPlastic"}
BEVEL = {"Ferrocefalos": 0.03}


def log(msg):
    print(f"[aliens {time.strftime('%H:%M:%S')}] {msg}", flush=True)


# ====================================================================== materiales procedurales
def organic_material(name, color, alt, metal, rough, pattern, scale=1.0):
    """Material para hornear: tono base con variación (patrón de la raza), rugosidad y relieve."""
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    K = NB.NodeKit(nt)
    out = K.new("ShaderNodeOutputMaterial")
    bsdf = K.new("ShaderNodeBsdfPrincipled")
    bsdf.name = "BSDF"
    K.link(bsdf.outputs[0], out.inputs["Surface"])
    mv = K.new("ShaderNodeValue")
    mv.name = "MetalVal"
    mv.outputs[0].default_value = metal
    K.link(mv.outputs[0], bsdf.inputs["Metallic"])
    bake = K.new("ShaderNodeTexImage")
    bake.name = "BakeTarget"
    tc = K.new("ShaderNodeTexCoord")
    P = tc.outputs["Object"]

    def noise(sc, detail=6.0, rough_=0.55):
        n = K.new("ShaderNodeTexNoise")
        K.link(P, n.inputs["Vector"])
        n.inputs["Scale"].default_value = sc * scale
        n.inputs["Detail"].default_value = detail
        n.inputs["Roughness"].default_value = rough_
        return n.outputs["Fac"]

    def voronoi(sc, feature="F1"):
        v = K.new("ShaderNodeTexVoronoi")
        v.feature = feature
        K.link(P, v.inputs["Vector"])
        v.inputs["Scale"].default_value = sc * scale
        return v

    def ramp(fac, lo, hi):
        mr = K.new("ShaderNodeMapRange")
        K.link(fac, mr.inputs["Value"])
        mr.inputs["From Min"].default_value = lo
        mr.inputs["From Max"].default_value = hi
        return mr.outputs["Result"]

    col = (*color, 1.0)
    altc = (*alt, 1.0)
    height = None
    rough_out = rough
    if pattern == "facets":  # cristal: cada faceta con su tono y aristas que brillan
        v = voronoi(3.0)
        cell = K.new("ShaderNodeSeparateColor")
        K.link(v.outputs["Color"], cell.inputs[0])
        f = K.math("MULTIPLY", cell.outputs[0], 0.55)
        edge = voronoi(3.0, "DISTANCE_TO_EDGE")
        edges = K.math("SUBTRACT", 1.0, ramp(edge.outputs["Distance"], 0.0, 0.06))
        f = K.math("MAXIMUM", f, K.math("MULTIPLY", edges, 0.9))
        color_out = K.mix(f, col, altc)
        height = K.math("MULTIPLY", cell.outputs[0], 0.6)
        rough_out = K.math("ADD", rough, K.math("MULTIPLY", noise(6.0), 0.12))
    elif pattern == "veins":  # membrana: venas oscuras y manchas
        e = voronoi(4.5, "DISTANCE_TO_EDGE")
        veins = K.math("SUBTRACT", 1.0, ramp(e.outputs["Distance"], 0.0, 0.05))
        mott = ramp(noise(2.2), 0.35, 0.75)
        base = K.mix(K.math("MULTIPLY", mott, 0.45), col, altc)
        color_out = K.mix(K.math("MULTIPLY", veins, 0.7), base, (color[0] * 0.35, color[1] * 0.3, color[2] * 0.4, 1))
        height = K.math("ADD", K.math("MULTIPLY", veins, -0.6), K.math("MULTIPLY", noise(8.0), 0.4))
        rough_out = K.math("ADD", rough, K.math("MULTIPLY", veins, 0.2))
    elif pattern == "rust":  # chatarra: pintura con óxido, arañazos y paneles
        rust = ramp(noise(1.6, 8.0, 0.65), 0.48, 0.62)
        scratches = ramp(noise(24.0, 2.0, 0.3), 0.62, 0.7)
        rust_col = (0.32, 0.14, 0.06, 1)
        base = K.mix(rust, col, rust_col)
        color_out = K.mix(K.math("MULTIPLY", scratches, 0.5), base, (0.55, 0.55, 0.55, 1))
        bricks = K.new("ShaderNodeTexBrick")
        K.link(P, bricks.inputs["Vector"])
        bricks.inputs["Scale"].default_value = 1.4 * scale
        bricks.inputs["Mortar Size"].default_value = 0.015
        bricks.inputs["Color1"].default_value = (1, 1, 1, 1)
        bricks.inputs["Color2"].default_value = (0.9, 0.9, 0.9, 1)
        lines = bricks.outputs["Fac"]
        color_out = K.mix(K.math("MULTIPLY", lines, 0.5), color_out, (0.08, 0.06, 0.05, 1))
        height = K.math("ADD", K.math("MULTIPLY", lines, -0.7), K.math("MULTIPLY", rust, 0.3))
        rough_out = K.math("ADD", rough, K.math("MULTIPLY", rust, 0.35))
    elif pattern == "porcelain":  # porcelana dorada con vetas finas
        veins = ramp(noise(5.0, 10.0, 0.7), 0.55, 0.6)
        color_out = K.mix(K.math("MULTIPLY", veins, 0.6), col, altc)
        height = K.math("MULTIPLY", noise(12.0, 4.0), 0.2)
        rough_out = K.math("ADD", rough, K.math("MULTIPLY", veins, -0.08))
    else:  # stone: pizarra con estratos
        wave = K.new("ShaderNodeTexWave")
        K.link(P, wave.inputs["Vector"])
        wave.inputs["Scale"].default_value = 2.5 * scale
        wave.inputs["Distortion"].default_value = 6.0
        wave.inputs["Detail"].default_value = 4.0
        strata = ramp(wave.outputs["Fac"], 0.2, 0.9)
        color_out = K.mix(K.math("MULTIPLY", strata, 0.5), col, altc)
        speck = ramp(noise(30.0, 2.0), 0.6, 0.7)
        color_out = K.mix(K.math("MULTIPLY", speck, 0.4), color_out, (0.85, 0.88, 0.9, 1))
        height = K.math("ADD", K.math("MULTIPLY", strata, 0.5), K.math("MULTIPLY", noise(14.0), 0.3))
        rough_out = K.math("ADD", rough, K.math("MULTIPLY", strata, 0.08))
    K.link(color_out, bsdf.inputs["Base Color"])
    if hasattr(rough_out, "is_output"):
        K.link(rough_out, bsdf.inputs["Roughness"])
    else:
        bsdf.inputs["Roughness"].default_value = rough_out
    if height is not None:
        bump = K.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.6
        bump.inputs["Distance"].default_value = 0.02
        K.link(height, bump.inputs["Height"])
        K.link(bump.outputs["Normal"], bsdf.inputs["Normal"])
    nt.nodes.active = bake
    return mat


def make_materials(races):
    for race in races:
        P = D.PALETTE[race]
        pat = STYLE[race]
        light = tuple(min(1.0, c * 1.35 + 0.05) for c in P["Body"])
        dark = tuple(c * 0.6 for c in P["Body"])
        if race == "Vortidos":
            organic_material(f"{race}_cuerpo", P["Body"], P["Accent"], 0.1, 0.12, "facets")
            organic_material(f"{race}_detalle", P["Trim"], tuple(c * 0.6 for c in P["Trim"]), 0.95, 0.32, "rust", 0.6)
            organic_material(f"{race}_oscuro", P["Dark"], dark, 0.3, 0.5, "facets", 1.5)
            organic_material(f"{race}_acento", P["Accent"], P["Body"], 0.1, 0.1, "facets", 2.0)
        elif race == "Morfagos":
            organic_material(f"{race}_cuerpo", P["Body"], light, 0.0, 0.42, "veins")
            organic_material(f"{race}_detalle", P["Trim"], P["Body"], 0.0, 0.55, "veins", 1.6)
            organic_material(f"{race}_oscuro", P["Dark"], P["Trim"], 0.0, 0.6, "veins", 2.0)
            organic_material(f"{race}_acento", P["Accent"], P["Body"], 0.0, 0.35, "veins", 2.5)
        elif race == "Ferrocefalos":
            organic_material(f"{race}_cuerpo", P["Body"], dark, 0.55, 0.5, "rust")
            organic_material(f"{race}_detalle", P["Trim"], (0.2, 0.2, 0.22), 0.9, 0.4, "rust", 1.3)
            organic_material(f"{race}_oscuro", P["Dark"], P["Trim"], 0.7, 0.6, "rust", 1.6)
            organic_material(f"{race}_acento", P["Accent"], (0.1, 0.1, 0.1), 0.4, 0.45, "rust", 1.0)
        elif race == "Luminidos":
            organic_material(f"{race}_cuerpo", P["Body"], (1.0, 0.97, 0.88), 0.25, 0.3, "porcelain")
            organic_material(f"{race}_detalle", P["Trim"], tuple(c * 0.7 for c in P["Trim"]), 0.3, 0.35, "porcelain", 2.0)
            organic_material(f"{race}_oscuro", P["Dark"], P["Trim"], 0.2, 0.4, "porcelain", 2.0)
            organic_material(f"{race}_acento", P["Accent"], P["Body"], 0.8, 0.18, "porcelain", 3.0)
        else:
            organic_material(f"{race}_cuerpo", P["Body"], tuple(c * 0.75 for c in P["Body"]), 0.05, 0.75, "stone")
            organic_material(f"{race}_detalle", P["Trim"], (0.75, 0.8, 0.8), 0.0, 0.55, "stone", 1.8)
            organic_material(f"{race}_oscuro", P["Dark"], P["Body"], 0.05, 0.8, "stone", 1.4)
            organic_material(f"{race}_acento", P["Accent"], P["Trim"], 0.1, 0.5, "stone", 2.4)
    glow = bpy.data.materials.get("brillo") or bpy.data.materials.new("brillo")
    glow.use_nodes = True


# ====================================================================== construir
ASSET_GEN = "2"  # la generación de los assets subidos (2: una malla con esqueleto por modelo)


class Built:
    def __init__(self, rig):
        self.rig = rig
        self.objs = {}  # nombre de la pieza -> objeto
        self.info = {}  # nombre -> datos del manifest
        self.shift = Vector((0, rig.height / 2, 0)) if rig.category in ("Troop", "King", "Creature") else Vector((0, 0, 0))

    @property
    def asset(self):
        # (prefijo nuevo «<Raza>2»: una malla con esqueleto por modelo; los ids viejos «<Raza>_*» —un
        # segmento por malla— no se pueden montar con estos datos. docs/bugs/moderacion/)
        return f"{self.rig.race}{ASSET_GEN}_{self.rig.kind}"

    @property
    def set_name(self):
        return f"{self.rig.race}{ASSET_GEN}_{'naves' if self.rig.category == 'Ship' else 'tropas'}"

    @property
    def budget_key(self):
        if self.rig.category == "Ship":
            return "Dropship" if self.rig.kind == "Dropship" else "Ship"
        return self.rig.category


def finish(obj, bevel):
    """Como el de la nave pero con un solo segmento de bisel (la chatarra lleva muchas cajas)."""
    me = obj.data
    me.shade_smooth()
    if bevel > 0:
        m = obj.modifiers.new("Bisel", "BEVEL")
        m.width = bevel
        m.segments = 1
        m.limit_method = "ANGLE"
        m.angle_limit = math.radians(40)
    t = obj.modifiers.new("Triangular", "TRIANGULATE")
    t.quad_method = "BEAUTY"
    dg = bpy.context.evaluated_depsgraph_get()
    new = bpy.data.meshes.new_from_object(obj.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
    obj.modifiers.clear()
    old = obj.data
    obj.data = new
    bpy.data.meshes.remove(old)
    new.set_sharp_from_angle(angle=math.radians(38))
    return len(new.polygons)


def build_rig(rig, coll):
    b = Built(rig)
    bevel = BEVEL.get(rig.race, 0.0)
    for name, seg in rig.segs.items():
        for suffix, mb, glow in (("", seg.m, False), ("Brillo", seg.g, True)):
            if not mb.faces:
                continue
            mb.verts = [v - b.shift for v in mb.verts]
            part = name + suffix
            obj = mb.build(f"{rig.id}__{part}", coll)
            tris = finish(obj, 0.0 if glow else bevel)
            b.objs[part] = obj
            b.info[part] = {"Name": part, "Joint": name, "Parent": seg.parent, "Glow": glow, "Tris": tris,
                            "Pivot": [round(c, 3) for c in (seg.pivot - b.shift)]}
    return b


def make_lod(b, coll):
    """La versión lejana: copia de todo, unida y simplificada (conserva las UV del atlas)."""
    main = sum(i["Tris"] for i in b.info.values() if not i["Glow"])
    if main < LOD_MIN:
        return  # (ya es ligero: no hace falta)
    target = min(LOD_MAX[b.budget_key], int(main * 0.35))
    for glow, part in ((False, "LOD"), (True, "LODBrillo")):
        src = [o for n, o in b.objs.items() if b.info[n]["Glow"] == glow and not b.info[n].get("Lod")]
        if not src:
            continue
        copies = []
        for o in src:
            c = o.copy()
            c.data = o.data.copy()
            coll.objects.link(c)
            copies.append(c)
        NB.select_only(copies)
        bpy.ops.object.join()
        lod = bpy.context.view_layer.objects.active
        lod.name = f"{b.rig.id}__{part}"
        tris = len(lod.data.polygons)
        goal = target if not glow else max(200, target // 4)
        if tris > goal:
            m = lod.modifiers.new("Simplificar", "DECIMATE")
            m.ratio = max(0.02, goal / tris)
            dg = bpy.context.evaluated_depsgraph_get()
            new = bpy.data.meshes.new_from_object(lod.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
            lod.modifiers.clear()
            old = lod.data
            lod.data = new
            bpy.data.meshes.remove(old)
            t = lod.modifiers.new("Triangular", "TRIANGULATE")
            dg = bpy.context.evaluated_depsgraph_get()
            new = bpy.data.meshes.new_from_object(lod.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
            lod.modifiers.clear()
            old = lod.data
            lod.data = new
            bpy.data.meshes.remove(old)
        b.objs[part] = lod
        b.info[part] = {"Name": part, "Joint": "Root", "Parent": "Root", "Glow": glow, "Tris": len(lod.data.polygons), "Lod": True, "Pivot": [0, 0, 0]}


# ====================================================================== una malla con esqueleto
SKIN_NAMES = {"main": "Cuerpo", "crystal": "CuerpoCristal", "glow": "CuerpoBrillo"}


def kind_of(info):
    return "glow" if info.get("Glow") else ("crystal" if info.get("Crystal") else "main")


def skin_export(b, fbx, coll):
    """Exporta el modelo como UNA malla con esqueleto (más la de cristal y la de brillo, con el mismo
    esqueleto) en vez de una malla suelta por segmento: Roblox revisa cada malla subida sola, gris y sin
    textura, y un antebrazo o una pierna sueltos (tubo liso con la punta redondeada) se los llevó la
    moderación por «Contenido sexual» (docs/bugs/moderacion/). Así cada malla que se sube es el
    personaje entero: el cuerpo, su cristal o su brillo.

    Cada segmento es un hueso (con su nombre: Body, Head, ArmL…, colgando de «Raiz») en su pivote, y sus
    vértices pesan 1 en su hueso (como antes, rígido). En Roblox el FBX entra como MeshPart con Bone; el
    cliente mueve los Bone igual que movía los Motor6D (Controllers/AlienAnim). Las LOD van tal cual.
    Devuelve (parts, bones) para el manifest."""
    made = []
    for kind, part in SKIN_NAMES.items():
        src = [(n, o) for n, o in b.objs.items() if not b.info[n].get("Lod") and kind_of(b.info[n]) == kind]
        if not src:
            continue
        copies = []
        for n, o in src:
            c = o.copy()
            c.data = o.data.copy()
            coll.objects.link(c)
            vg = c.vertex_groups.new(name=b.info[n]["Joint"])
            vg.add(list(range(len(c.data.vertices))), 1.0, "REPLACE")
            copies.append(c)
        NB.select_only(copies)
        if len(copies) > 1:
            bpy.ops.object.join()
        obj = bpy.context.view_layer.objects.active
        obj.name = part
        made.append((part, kind, obj))
    # El esqueleto: un hueso por segmento en su pivote (de pie, sin girar), los padres antes que los hijos
    arm = bpy.data.objects.new("Esqueleto", bpy.data.armatures.new(f"{b.rig.id}__esqueleto"))
    coll.objects.link(arm)
    NB.select_only([arm])
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    L = max(0.15, b.rig.height * 0.03)
    root = eb.new("Raiz")
    root.head, root.tail = (0, 0, 0), (0, 0, L)
    done = {"Root": root}
    bones = []
    todo = list(b.rig.segs.items())
    while todo:
        rest = []
        for name, seg in todo:
            parent = seg.parent if seg.parent in b.rig.segs else "Root"
            if parent not in done:
                rest.append((name, seg))
                continue
            p = Vector(to_blender(seg.pivot - b.shift))
            bone = eb.new(name)
            bone.head, bone.tail = p, p + Vector((0, 0, L))
            bone.roll = 0.0
            bone.parent = done[parent]
            bone.use_connect = False
            done[name] = bone
            main = b.objs.get(name)
            center, size = NB.bbox_roblox(main) if main is not None else (seg.pivot - b.shift, Vector((0.05, 0.05, 0.05)))
            bones.append({"Name": name, "Parent": parent, "Pivot": [round(c, 3) for c in (seg.pivot - b.shift)],
                          "Center": [round(c, 3) for c in center], "Size": [round(max(s, 0.05), 3) for s in size]})
        if len(rest) == len(todo):
            raise RuntimeError(f"{b.rig.id}: segmentos sin padre: {[n for n, _ in rest]}")
        todo = rest
    bpy.ops.object.mode_set(mode="OBJECT")
    for _, _, obj in made:
        obj.parent = arm
        mod = obj.modifiers.new("Esqueleto", "ARMATURE")
        mod.object = arm
    lods = [(n, o) for n, o in b.objs.items() if b.info[n].get("Lod")]
    old_names = {n: o.name for n, o in lods}
    for n, o in lods:
        o.name = n
    NB.select_only([arm] + [o for _, _, o in made] + [o for _, o in lods], arm)
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, object_types={"ARMATURE", "MESH"}, apply_unit_scale=True, global_scale=1.0,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=False, add_leaf_bones=False,
                             bake_anim=False, armature_nodetype="NULL", primary_bone_axis="Y", secondary_bone_axis="X",
                             path_mode="STRIP", embed_textures=False, use_custom_props=False)
    parts = []
    for part, kind, obj in made:
        center, size = NB.bbox_roblox(obj)
        parts.append({"Name": part, "Joint": "Root", "Parent": "Root", "Glow": kind == "glow", "Crystal": kind == "crystal", "Skinned": True,
                      "Tris": len(obj.data.polygons), "Pivot": [0, 0, 0], "Center": [round(c, 3) for c in center],
                      "Size": [round(max(s, 0.05), 3) for s in size]})
    for n, o in lods:
        center, size = NB.bbox_roblox(o)
        info = dict(b.info[n])
        info["Center"] = [round(c, 3) for c in center]
        info["Size"] = [round(max(s, 0.05), 3) for s in size]
        parts.append(info)
        o.name = old_names[n]
    # (las copias y el esqueleto solo eran para el FBX: las imágenes siguen con los segmentos)
    for _, _, obj in made:
        me = obj.data
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(me)
    ad = arm.data
    bpy.data.objects.remove(arm)
    bpy.data.armatures.remove(ad)
    return parts, bones


# ====================================================================== Luau
def v3(v):
    return f"Vector3.new({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f})"


def write_luau(path, manifest):
    L = [
        "-- AlienMallas: GENERADO por scripts/invasion/alien_blender.py (no editar a mano).",
        "-- Los alienígenas v2 de la Invasión de la Grieta hechos en Blender (docs/invasion.md, «v2»): cada",
        "-- modelo, sus segmentos (MeshPart al subirlos con scripts/upload-invasion.sh), con el centro y el",
        "-- tamaño en studs respecto al raíz (el centro del modelo, como World/Kit/AlienModels; el frente a -Z),",
        "-- el pivote de su articulación (Motor6D: lo anima shared/Invasion/AlienPose), el padre, si brilla",
        "-- (Neon del color Glow de la raza), los triángulos y el juego de texturas. LOD = la versión lejana.",
        "-- Lo usan World/AlienMeshLoader y World/Kit/AlienModels (con respaldo: los modelos de piezas).",
        "",
        "return {",
        "\tVersion = 2,",
        f"\tTotalTris = {manifest['TotalTris']},",
        f"\tBudget = {{ MaxTrisPerMesh = {MAX_TRIS}, Troop = {BUDGET['Troop']}, King = {BUDGET['King']}, Ship = {BUDGET['Ship']}, Dropship = {BUDGET['Dropship']}, Creature = {BUDGET['Creature']} }},",
        "\tModels = {",
    ]
    for m in manifest["Models"]:
        L.append(f"\t\t{m['Id']} = {{")
        L.append(f"\t\t\tRace = \"{m['Race']}\", Kind = \"{m['Kind']}\", Category = \"{m['Category']}\", Gait = \"{m['Gait']}\", Height = {m['Height']}, Set = \"{m['Set']}\", Material = \"{m['Material']}\", Tris = {m['Tris']}, LodTris = {m['LodTris']},")
        if m.get("Asset"):  # (los Vórtidos de cristal: vortidos_blender.py; se suben con otro nombre)
            cc = m.get("CrystalColor") or [142, 230, 255]
            L.append(f"\t\t\tAsset = \"{m['Asset']}\", Attack = \"{m.get('Attack', '')}\", Pulse = {str(bool(m.get('Pulse'))).lower()}, CrystalColor = {{ {cc[0]}, {cc[1]}, {cc[2]} }},")
        if m.get("Skinned"):  # (una malla con esqueleto: skin_export; los huesos, con el centro y tamaño de su segmento)
            L.append("\t\t\tSkinned = true,")
            L.append("\t\t\tBones = {")
            for bn in m.get("Bones", []):
                L.append(f"\t\t\t\t{{ Name = \"{bn['Name']}\", Parent = \"{bn['Parent']}\", Pivot = {v3(bn['Pivot'])}, Center = {v3(bn['Center'])}, Size = {v3(bn['Size'])} }},")
            L.append("\t\t\t},")
        L.append("\t\t\tParts = {")
        for p in m["Parts"]:
            extra = (", Crystal = true" if p.get("Crystal") else "") + (", NoHit = true" if p.get("NoHit") else "") + (", Skinned = true" if p.get("Skinned") else "")
            L.append(f"\t\t\t\t{{ Name = \"{p['Name']}\", Joint = \"{p['Joint']}\", Parent = \"{p['Parent']}\", Glow = {str(p['Glow']).lower()}, Lod = {str(p.get('Lod', False)).lower()}{extra}, Center = {v3(p['Center'])}, Size = {v3(p['Size'])}, Pivot = {v3(p['Pivot'])}, Tris = {p['Tris']} }},")
        L.append("\t\t\t},")
        L.append("\t\t},")
    L += ["\t},", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(L))


# ====================================================================== poses (para las imágenes)
C = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))  # Roblox -> Blender
CI = C.inverted()


def rb_rot(pitch=0.0, yaw=0.0, roll=0.0):
    return (Matrix.Rotation(yaw, 4, "Y") @ Matrix.Rotation(pitch, 4, "X") @ Matrix.Rotation(roll, 4, "Z"))


POSES = {
    "idle": {},
    "walk": {"LegL": (0.45, 0, 0), "LegR": (-0.45, 0, 0), "ArmL": (-0.35, 0, 0), "ArmR": (0.3, 0, 0), "LegBL": (-0.35, 0, 0), "LegBR": (0.35, 0, 0)},
    "run": {"LegL": (0.8, 0, 0), "LegR": (-0.7, 0, 0), "ArmL": (-0.7, 0, 0.1), "ArmR": (0.7, 0, -0.1), "Body": (-0.18, 0, 0), "LegBL": (-0.6, 0, 0), "LegBR": (0.6, 0, 0)},
    "attack": {"ArmR": (0.5, 0.2, 0.3), "ArmL": (-0.4, 0, -0.2), "Body": (0.12, -0.3, 0), "Head": (0.1, 0.2, 0)},
    "hit": {"Body": (-0.3, 0.15, 0.12), "Head": (-0.35, 0, 0.1), "ArmL": (-0.5, 0, -0.5), "ArmR": (-0.4, 0, 0.5)},
    "die": {"Body": (-0.6, 0, 0.25), "Head": (-0.4, 0, 0), "ArmL": (-1.0, 0, -0.8), "ArmR": (-0.9, 0, 0.8), "LegL": (0.4, 0, 0), "LegR": (0.2, 0, 0)},
}


def place(b, at, yaw=0.0, pose="idle", scale=1.0, lift=0.0):
    """Pone el modelo en el mundo (Roblox: at = pies) con una pose."""
    p = POSES.get(pose, {})
    world = {}
    base = Matrix.Translation(Vector(at) + Vector((0, (b.shift.y if b.rig.category != "Ship" else 0) * scale + lift, 0))) @ rb_rot(yaw=yaw) @ Matrix.Scale(scale, 4)
    world["Root"] = base
    order = list(b.rig.segs.keys())
    for name in order:
        seg = b.rig.segs[name]
        parent = world.get(seg.parent, base)
        piv = Vector(seg.pivot) - b.shift
        r = p.get(name, (0, 0, 0))
        local = Matrix.Translation(piv) @ rb_rot(*r) @ Matrix.Translation(-piv)
        world[name] = parent @ local
    for part, obj in b.objs.items():
        info = b.info[part]
        if info.get("Lod"):
            obj.hide_render = True
            continue
        obj.hide_render = False
        obj.matrix_world = C @ world.get(info["Joint"], base) @ CI


# ====================================================================== render
def studio(scene, kind="ciudad"):
    world = bpy.data.worlds.new("Cielo") if not bpy.data.worlds.get("Cielo") else bpy.data.worlds["Cielo"]
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Generated"], sep.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.48
    ramp.color_ramp.elements[0].color = (0.05, 0.05, 0.09, 1)
    ramp.color_ramp.elements[1].position = 0.75
    ramp.color_ramp.elements[1].color = (0.16, 0.08, 0.24, 1)
    el = ramp.color_ramp.elements.new(0.56)
    el.color = (0.42, 0.22, 0.32, 1)
    nt.links.new(sep.outputs[2], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 0.8
    nt.links.new(bg.outputs[0], out.inputs["Surface"])
    # suelo: losas de una plaza
    if not bpy.data.objects.get("Suelo"):
        bpy.ops.mesh.primitive_plane_add(size=600, location=(0, 0, 0))
        ground = bpy.context.active_object
        ground.name = "Suelo"
        gm = bpy.data.materials.new("Suelo")
        gm.use_nodes = True
        gb = gm.node_tree.nodes.get("Principled BSDF")
        br = gm.node_tree.nodes.new("ShaderNodeTexBrick")
        br.inputs["Scale"].default_value = 0.35
        br.inputs["Color1"].default_value = (0.2, 0.19, 0.18, 1)
        br.inputs["Color2"].default_value = (0.16, 0.155, 0.15, 1)
        br.inputs["Mortar"].default_value = (0.08, 0.08, 0.08, 1)
        br.inputs["Mortar Size"].default_value = 0.01
        tc2 = gm.node_tree.nodes.new("ShaderNodeTexCoord")
        gm.node_tree.links.new(tc2.outputs["Object"], br.inputs["Vector"])
        gm.node_tree.links.new(br.outputs["Color"], gb.inputs["Base Color"])
        gb.inputs["Roughness"].default_value = 0.6
        ground.data.materials.append(gm)
    for name, kind_, energy, size, color, eye in (
        ("Sol", "SUN", 2.2, 0, (1.0, 0.86, 0.75), (-30, 40, -40)),
        ("Contraluz", "AREA", 14000, 30, (0.45, 0.6, 1.0), (30, 25, 50)),
        ("Relleno", "AREA", 5000, 40, (1.0, 0.8, 0.9), (40, 10, -60)),
        ("Grieta", "AREA", 9000, 50, (0.75, 0.35, 1.0), (-50, 60, 60)),
    ):
        if bpy.data.objects.get(name):
            continue
        ld = bpy.data.lights.new(name, kind_)
        ld.energy = energy
        if kind_ == "AREA":
            ld.size = size
        else:
            ld.angle = math.radians(3)
        ld.color = color
        o = bpy.data.objects.new(name, ld)
        scene.collection.objects.link(o)
        NB.look_at(o, eye, (0, 3, 0))


def setup_render(scene, samples, res):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    try:
        scene.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Punchy"
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 88
    scene.use_nodes = True
    ct = scene.node_tree
    ct.nodes.clear()
    rl = ct.nodes.new("CompositorNodeRLayers")
    gl = ct.nodes.new("CompositorNodeGlare")
    gl.glare_type = "FOG_GLOW"
    gl.quality = "HIGH"
    gl.threshold = 1.0
    gl.size = 7
    comp = ct.nodes.new("CompositorNodeComposite")
    ct.links.new(rl.outputs["Image"], gl.inputs["Image"])
    ct.links.new(gl.outputs["Image"], comp.inputs["Image"])


def shoot(scene, cam, eye, target, lens, path):
    cam.data.lens = lens
    NB.look_at(cam, eye, target)
    scene.render.filepath = path
    t0 = time.time()
    bpy.ops.render.render(write_still=True)
    log(f"  imagen {os.path.basename(path)} en {time.time() - t0:.0f}s")


def hide_all(built):
    for b in built.values():
        for o in b.objs.values():
            o.hide_render = True


def render_all(built, races, docs, samples):
    scene = bpy.context.scene
    studio(scene)
    cam = bpy.data.objects.get("Camara")
    if not cam:
        cam = bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    os.makedirs(docs, exist_ok=True)
    paths = {}
    setup_render(scene, samples, (1600, 900))
    races = [r for r in races if f"{r}_Grunt" in built]  # (los Vórtidos de cristal tienen sus hojas: vortidos_blender.py)
    for race in races:
        hide_all(built)
        row = [("Grunt", -9.5, "walk"), ("Heavy", -3.0, "idle"), ("Ranged", 3.6, "attack"), ("Elite", 10.5, "run")]
        for kind, x, pose in row:
            place(built[f"{race}_{kind}"], (x, 0, 0), yaw=math.radians(-20 if x < 0 else 20), pose=pose)
        place(built[f"{race}_Fighter"], (-14, 15, 18), yaw=math.radians(-35))
        place(built[f"{race}_Drone"], (-3, 12, 14), yaw=math.radians(30))
        place(built[f"{race}_Dropship"], (16, 18, 60), yaw=math.radians(20))
        path = os.path.join(docs, f"{race}.jpg")
        shoot(scene, cam, (0, 7.5, -34), (0.5, 6.5, 0), 30, path)
        paths[race] = path
    # Los reyes (con su manto), en fila
    hide_all(built)
    for i, race in enumerate(races):
        place(built[f"{race}_King"], ((i - (len(races) - 1) / 2) * 13, 0, 0), yaw=math.radians((i - 2) * 8), pose="idle")
    paths["reyes"] = os.path.join(docs, "reyes.jpg")
    shoot(scene, cam, (0, 9, -58), (0, 6, 0), 32, paths["reyes"])
    # La gente transformada
    hide_all(built)
    crs = [(race, cid) for race in races for cid, _, _ in D.CREATURES[race]]
    half = (len(crs) + 1) // 2
    for i, (race, cid) in enumerate(crs):
        row, col = (0, i // 2) if i % 2 == 0 else (1, i // 2)
        n = half
        place(built[f"{race}_{cid}"], ((col - (n - 1) / 2) * 3.6 + row * 1.6, 0, row * 4.5), yaw=math.radians(-30 + (i % 3) * 30), pose="walk")
    paths["criaturas"] = os.path.join(docs, "criaturas.jpg")
    shoot(scene, cam, (0, 5.5, -16), (0, 1.5, 2.2), 36, paths["criaturas"])
    # Las poses de la animación (un soldado de cada raza): quieto, andar, correr, atacar, golpe, caer
    poses = ["idle", "walk", "run", "attack", "hit", "die"]
    for race in races:
        hide_all(built)
        strip = []
        for i, pose in enumerate(poses):
            b = built[f"{race}_Grunt"]
            place(b, (0, 0, 0), yaw=math.radians(-35), pose=pose)
            p = os.path.join(docs, f"_pose_{race}_{pose}.jpg")
            setup_render(scene, max(16, samples // 2), (420, 520))
            shoot(scene, cam, (0, 4.5, -15), (0, 3.0, 0), 40, p)
            strip.append(p)
        paths[f"poses_{race}"] = strip
    # Las naves de cerca
    setup_render(scene, samples, (1600, 900))
    hide_all(built)
    for i, race in enumerate(races):
        x = (i - (len(races) - 1) / 2) * 13
        place(built[f"{race}_Fighter"], (x, 8, 0), yaw=math.radians(-30 + i * 12))
        place(built[f"{race}_Drone"], (x + 2.5, 2.8, -9), yaw=math.radians(20))
    paths["naves"] = os.path.join(docs, "naves.jpg")
    shoot(scene, cam, (0, 13, -46), (0, 5, 0), 30, paths["naves"])
    return paths


def compose_sheets(paths, races, docs, stats):
    from PIL import Image, ImageDraw, ImageFont

    fb = lambda s: ImageFont.truetype(FONT_BOLD, s)
    fr = lambda s: ImageFont.truetype(FONT, s)
    names = {"Vortidos": "VÓRTIDOS", "Morfagos": "MÓRFAGOS", "Ferrocefalos": "FERROCÉFALOS", "Luminidos": "LUMÍNIDOS", "Brumaridos": "BRUMÁRIDOS"}
    races = [r for r in races if r in paths]
    for race in races:
        img = Image.open(paths[race]).convert("RGB")
        d = ImageDraw.Draw(img)
        d.rectangle((0, 0, 1600, 70), fill=(8, 8, 16))
        d.text((24, 14), names[race], font=fb(34), fill=(240, 240, 250))
        d.text((420, 26), "soldado · pesado · tirador · élite · caza · dron · nave de desembarco", font=fr(18), fill=(170, 180, 200))
        d.text((1210, 26), f"{stats[race]['tris']:,} triángulos".replace(",", "."), font=fr(18), fill=(150, 200, 255))
        img.save(paths[race], quality=88)
        # Tira de poses
        strip = [Image.open(p) for p in paths[f"poses_{race}"]]
        W = sum(s.width for s in strip)
        sheet = Image.new("RGB", (W, strip[0].height + 50), (8, 8, 16))
        x = 0
        dd = ImageDraw.Draw(sheet)
        for s, label in zip(strip, ["QUIETO", "ANDAR", "CORRER", "ATACAR", "GOLPE", "CAER"]):
            sheet.paste(s, (x, 50))
            dd.text((x + 14, 12), label, font=fb(22), fill=(230, 235, 255))
            x += s.width
        out = os.path.join(docs, f"poses-{race}.jpg")
        sheet.save(out, quality=86)
        for p in paths[f"poses_{race}"]:
            os.remove(p)
    # Hoja resumen
    sheet = Image.new("RGB", (1920, 1080), (8, 8, 16))
    d = ImageDraw.Draw(sheet)
    d.text((32, 24), "INVASIÓN DE LA GRIETA · ALIENÍGENAS v2", font=fb(34), fill=(240, 240, 250))
    d.text((34, 70), "Mallas de Blender con texturas PBR horneadas, segmentos animables y LOD", font=fr(18), fill=(160, 175, 200))
    tiles = races + ["reyes", "criaturas", "naves"]
    tw, th = 616, 300
    for i, key in enumerate(tiles[:9]):
        x0 = 24 + (i % 3) * (tw + 12)
        y0 = 110 + (i // 3) * (th + 10)
        im = Image.open(paths[key]).convert("RGB").resize((tw, int(tw * 9 / 16)))
        sheet.paste(im.crop((0, (im.height - th) // 2, tw, (im.height - th) // 2 + th)), (x0, y0))
        d.rectangle((x0, y0, x0 + tw, y0 + th), outline=(60, 70, 110), width=2)
    sheet.save(os.path.join(docs, "hoja.jpg"), quality=88)


# ====================================================================== main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "invasion"))
    ap.add_argument("--docs", default=os.path.join(ROOT, "docs", "invasion", "v2"))
    ap.add_argument("--luau", default=os.path.join(ROOT, "src", "shared", "Invasion", "AlienMallas.luau"))
    ap.add_argument("--only", default="")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--no-bake", action="store_true", help="sin hornear (para probar: las imágenes salen con los materiales procedurales)")
    ap.add_argument("--samples", type=int, default=48)
    args = ap.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else None)
    races = [r for r in args.only.split(",") if r] or D.RACES
    out_dir = os.path.abspath(args.out)
    tex_dir = os.path.join(out_dir, "tex")
    os.makedirs(tex_dir, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    t0 = time.time()
    make_materials(races)
    coll = bpy.data.collections.new("Aliens")
    bpy.context.scene.collection.children.link(coll)
    built = {}
    for rig in D.build_all(races):
        b = build_rig(rig, coll)
        built[rig.id] = b
        total = sum(i["Tris"] for i in b.info.values())
        log(f"{rig.id}: {total} triángulos en {len(b.objs)} mallas")
    # UV y horneado por juego de texturas (las mallas principales; las de brillo son Neon sin textura)
    sets = {}
    for b in built.values():
        for part, o in b.objs.items():
            if not b.info[part]["Glow"]:
                sets.setdefault(b.set_name, []).append(o)
    baked = {}
    for name, members in sets.items():
        NB.unwrap(members)
        if args.no_bake:
            continue
        size = SET_SIZE["naves" if name.endswith("naves") else "tropas"]
        baked[name] = NB.bake_set(name, members, size, tex_dir, NB.MAPS)
    for name, paths in baked.items():
        mat = NB.pbr_material(name, paths)
        for o in sets[name]:
            NB.single_material(o, mat)
    # LOD (después del horneado: las copias se quedan con las UV y el material del atlas)
    for b in built.values():
        make_lod(b, coll)
    # Brillos: un material de emisión del color de la raza (solo para las imágenes; en Roblox, Neon)
    glow_mats = {race: NB.emission_mat("E_" + race, D.PALETTE[race]["Glow"], 3.5) for race in races}
    for b in built.values():
        for part, o in b.objs.items():
            if b.info[part]["Glow"]:
                NB.single_material(o, glow_mats[b.rig.race])
    # Exportar: un FBX por modelo, con los nombres de las piezas tal cual (Body, HeadBrillo, LOD…)
    manifest = {"Models": [], "Textures": {k: {m: os.path.relpath(p, out_dir) for m, p in v.items()} for k, v in baked.items()}}
    for rid, b in built.items():
        # UNA malla con esqueleto por modelo (+ su brillo), nunca un segmento suelto: docs/bugs/moderacion/
        fbx = os.path.join(out_dir, b.asset + ".fbx")
        parts, bones = skin_export(b, fbx, coll)
        tris = sum(p["Tris"] for p in parts if not p.get("Lod"))
        lod = sum(p["Tris"] for p in parts if p.get("Lod"))
        rig = b.rig
        manifest["Models"].append({"Id": rid, "Race": rig.race, "Kind": rig.kind, "Category": rig.category, "Gait": rig.gait, "Height": round(rig.height, 3),
                                   "Set": b.set_name, "Material": RBX_MATERIAL[rig.race], "Fbx": os.path.basename(fbx), "Tris": tris, "LodTris": lod,
                                   "Budget": BUDGET[b.budget_key], "Asset": b.asset, "Skinned": True, "Bones": bones, "Parts": parts})
    # (lo que no se ha hecho aquí —los Vórtidos de cristal de vortidos_blender.py— se queda como estaba)
    old_path = os.path.join(out_dir, "manifest.json")
    if os.path.exists(old_path):
        with open(old_path) as f:
            old = json.load(f)
        mine = {m["Id"] for m in manifest["Models"]}
        manifest["Models"] += [m for m in old.get("Models", []) if m["Id"] not in mine and m.get("Asset")]
        for k, v in old.get("Textures", {}).items():
            if k.split("_")[0] in races:
                continue  # (los juegos de texturas viejos de estas razas: ya no los usa nadie)
            manifest["Textures"].setdefault(k, v)
        manifest["Models"].sort(key=lambda m: m["Id"])
    manifest["TotalTris"] = sum(m["Tris"] for m in manifest["Models"])
    manifest["Budget"] = {"MaxTrisPerMesh": MAX_TRIS, **BUDGET}
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    if not args.only:
        write_luau(args.luau, manifest)
    over = [m["Id"] for m in manifest["Models"] if m["Tris"] > m["Budget"] or any(p["Tris"] > MAX_TRIS for p in m["Parts"])]
    log(f"listo: {len(manifest['Models'])} modelos, {manifest['TotalTris']} triángulos en {time.time() - t0:.0f}s" + (f" ⚠️ fuera de presupuesto: {over}" if over else ""))
    if args.no_render:
        return
    stats = {race: {"tris": sum(m["Tris"] for m in manifest["Models"] if m["Race"] == race)} for race in races}
    paths = render_all(built, races, os.path.abspath(args.docs), args.samples)
    compose_sheets(paths, races, os.path.abspath(args.docs), stats)
    log(f"imágenes listas en {time.time() - t0:.0f}s")


if __name__ == "__main__":
    main()
