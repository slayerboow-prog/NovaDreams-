#!/usr/bin/env python3
"""Los Vórtidos «de cristal» hechos en Blender (hojas del dueño en docs/invasion/referencia-cristal/):
soldado (Esquirla) y variantes (Monolito, Prisma con rifle, Custodio de Kael), el líder Kael-Ithra
(capa en 3 bandas y cetro) y la nave «Clase: Guardián» (Fragata Prisma) con sus derivadas (Astilla,
Geoda). Mismo camino que scripts/invasion/alien_blender.py (que hizo los alienígenas v2), con tres mallas
por segmento: la principal (textura PBR horneada), la de cristal (Glass cian pálido en Roblox) y la de
brillo (Neon). Diseños: scripts/invasion/vortidos_diseno.py.

Necesita Blender como módulo de Python:   pip install bpy==4.2.0   (Python 3.11; todo en CPU)

Uso (desde la carpeta roblox/):
    python3 scripts/invasion/vortidos_blender.py              mallas, texturas, LOD, manifest, Luau y hojas
    python3 scripts/invasion/vortidos_blender.py --no-bake    sin hornear (para probar la geometría)
    python3 scripts/invasion/vortidos_blender.py --no-render  sin las imágenes

Salida:
    assets/invasion/VortidosCristal2_<Tipo>.fbx  un FBX por modelo: UNA malla con esqueleto (Cuerpo, y con el
                                                 mismo esqueleto CuerpoCristal y CuerpoBrillo; un hueso por
                                                 segmento: Body, Head, ArmL…) y LOD, LODCristal, LODBrillo.
                                                 Nunca un segmento suelto (docs/bugs/moderacion/: la v124
                                                 subía un antebrazo y una pierna sueltos y Roblox los retiró)
    assets/invasion/tex/VortidosCristal2_{tropas,naves}_{color,normal,rugosidad,metal}.png
    assets/invasion/manifest.json                (se cambian solo las entradas de los Vórtidos)
    src/shared/Invasion/AlienMallas.luau         (regenerado con todo el manifest)
    docs/invasion/referencia-cristal/comparacion-*.png   la hoja del dueño al lado de las vistas del modelo
    docs/invasion/referencia-cristal/vortidos-*.jpg      poses y la familia completa
Revisar: python3 scripts/audit/moderacion-mallas.py --kits invasion (el script de subida lo comprueba solo).
Subir: bash scripts/upload-invasion.sh --solo VortidosCristal2 (solo la sesión que publica).
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

import alien_blender as AB  # noqa: E402
import nave_blender as NB  # noqa: E402
import vortidos_diseno as VD  # noqa: E402

REF = os.path.join(ROOT, "docs", "invasion", "referencia-cristal")
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
SET_SIZE = 1024
LOD_MAX = {"Troop": 2400, "King": 3600, "Ship": 2600, "Dropship": 3600}


def log(msg):
    print(f"[vórtidos {time.strftime('%H:%M:%S')}] {msg}", flush=True)


# ====================================================================== materiales
def lin(c):
    return tuple(x ** 2.2 for x in c)


def vc_material(name, color, metal, rough, pattern, alt=None, scale=1.0):
    """Material procedural para hornear (como alien_blender.organic_material): armadura negra con
    paneles, juntas, blanco de placas, capa con símbolos, cabina."""
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

    def noise(sc, detail=5.0, r=0.55):
        n = K.new("ShaderNodeTexNoise")
        K.link(P, n.inputs["Vector"])
        n.inputs["Scale"].default_value = sc * scale
        n.inputs["Detail"].default_value = detail
        n.inputs["Roughness"].default_value = r
        return n.outputs["Fac"]

    def edges(sc, width):
        v = K.new("ShaderNodeTexVoronoi")
        v.feature = "DISTANCE_TO_EDGE"
        K.link(P, v.inputs["Vector"])
        v.inputs["Scale"].default_value = sc * scale
        mr = K.new("ShaderNodeMapRange")
        K.link(v.outputs["Distance"], mr.inputs["Value"])
        mr.inputs["From Min"].default_value = 0.0
        mr.inputs["From Max"].default_value = width
        return K.math("SUBTRACT", 1.0, mr.outputs["Result"])

    # (la paleta de la hoja está en sRGB; los nodos de Blender trabajan en lineal)
    color = lin(color)
    alt = lin(alt) if alt else None
    col = (*color, 1.0)
    altc = (*(alt or tuple(c * 0.6 for c in color)), 1.0)
    if pattern == "armor":  # paneles con juntas finas y un poco de desgaste
        seams = edges(2.2, 0.03)
        wear = noise(9.0)
        base = K.mix(K.math("MULTIPLY", wear, 0.35), col, altc)
        color_out = K.mix(K.math("MULTIPLY", seams, 0.35), base, (0.004, 0.005, 0.007, 1))
        height = K.math("ADD", K.math("MULTIPLY", seams, -0.6), K.math("MULTIPLY", wear, 0.15))
        rough_out = K.math("ADD", rough, K.math("MULTIPLY", wear, 0.12))
    elif pattern == "white":  # placas blancas: líneas de panel grises
        seams = edges(1.4, 0.025)
        dirt = noise(6.0)
        base = K.mix(K.math("MULTIPLY", dirt, 0.25), col, altc)
        color_out = K.mix(K.math("MULTIPLY", seams, 0.7), base, (0.42, 0.47, 0.52, 1))
        height = K.math("MULTIPLY", seams, -0.7)
        rough_out = K.math("ADD", rough, K.math("MULTIPLY", dirt, 0.08))
    elif pattern == "cape":  # tela con símbolos ancestrales (líneas azules finas)
        wave = K.new("ShaderNodeTexWave")
        K.link(P, wave.inputs["Vector"])
        wave.wave_type = "RINGS"
        wave.inputs["Scale"].default_value = 1.6 * scale
        wave.inputs["Distortion"].default_value = 2.5
        wave.inputs["Detail"].default_value = 1.0
        mr = K.new("ShaderNodeMapRange")
        K.link(wave.outputs["Fac"], mr.inputs["Value"])
        mr.inputs["From Min"].default_value = 0.88
        mr.inputs["From Max"].default_value = 0.98
        sym = K.math("MAXIMUM", mr.outputs["Result"], K.math("MULTIPLY", edges(1.2, 0.02), 0.8))
        color_out = K.mix(K.math("MULTIPLY", sym, 0.85), col, (*(alt or lin((0.45, 0.68, 0.95))), 1.0))
        height = K.math("MULTIPLY", sym, 0.3)
        rough_out = rough
    elif pattern == "cape_blue":  # el panel azul de la capa: venas más claras
        n = noise(3.0, 8.0, 0.6)
        mr = K.new("ShaderNodeMapRange")
        K.link(n, mr.inputs["Value"])
        mr.inputs["From Min"].default_value = 0.49
        mr.inputs["From Max"].default_value = 0.51
        vein = K.math("SUBTRACT", 1.0, K.math("ABSOLUTE", K.math("SUBTRACT", K.math("MULTIPLY", mr.outputs["Result"], 2.0), 1.0)))
        color_out = K.mix(K.math("MULTIPLY", vein, 0.6), col, (*(alt or lin((0.35, 0.65, 0.95))), 1.0))
        height = K.math("MULTIPLY", vein, 0.2)
        rough_out = rough
    else:  # glossy: cabina
        n = noise(4.0)
        color_out = K.mix(K.math("MULTIPLY", n, 0.3), col, altc)
        height = None
        rough_out = rough
    K.link(color_out, bsdf.inputs["Base Color"])
    if hasattr(rough_out, "is_output"):
        K.link(rough_out, bsdf.inputs["Roughness"])
    else:
        bsdf.inputs["Roughness"].default_value = rough_out
    if height is not None:
        bump = K.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.5
        bump.inputs["Distance"].default_value = 0.01
        K.link(height, bump.inputs["Height"])
        K.link(bump.outputs["Normal"], bsdf.inputs["Normal"])
    nt.nodes.active = bake
    return mat


def make_materials():
    P = VD.PAL
    vc_material(VD.M_CUERPO, P["Cuerpo"], 0.5, 0.42, "armor", alt=(0.07, 0.08, 0.095), scale=1.0)
    vc_material(VD.M_JUNTA, P["Junta"], 0.75, 0.48, "armor", alt=(0.05, 0.055, 0.065), scale=2.4)
    vc_material(VD.M_BLANCO, P["Blanco"], 0.1, 0.34, "white", alt=(0.62, 0.68, 0.75))
    vc_material(VD.M_CAPA, P["Capa"], 0.0, 0.7, "cape", alt=(0.45, 0.7, 0.95))
    vc_material(VD.M_CAPA_AZUL, P["CapaAzul"], 0.0, 0.62, "cape_blue", alt=(0.35, 0.7, 1.0))
    vc_material(VD.M_CABINA, P["Cabina"], 0.4, 0.08, "glossy", alt=(0.02, 0.05, 0.14))
    crystal_render_material()
    for n in (VD.M_CRISTAL, VD.M_BRILLO):
        if not bpy.data.materials.get(n):
            bpy.data.materials.new(n)


def crystal_render_material():
    """Para las imágenes: cristal cian que brilla (en Roblox: Glass con núcleos de Neon). Cada faceta con
    su tono (de cian hondo a casi blanco según mira a la cámara), como en la hoja."""
    name = "R_cristal"
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    b = nt.nodes.new("ShaderNodeBsdfPrincipled")
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.5
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.42, 0.86, 1.0, 1)
    ramp.color_ramp.elements[1].position = 0.85
    ramp.color_ramp.elements[1].color = (0.02, 0.3, 0.75, 1)
    mid = ramp.color_ramp.elements.new(0.4)
    mid.color = (0.1, 0.62, 1.0, 1)
    nt.links.new(lw.outputs["Facing"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(ramp.outputs["Color"], b.inputs["Emission Color"])
    b.inputs["Emission Strength"].default_value = 0.75
    b.inputs["Roughness"].default_value = 0.1
    b.inputs["Specular IOR Level"].default_value = 0.8
    b.inputs["Coat Weight"].default_value = 0.5
    nt.links.new(b.outputs[0], out.inputs["Surface"])
    return m


# ====================================================================== construir
class Built:
    def __init__(self, rig):
        self.rig = rig
        self.objs = {}
        self.info = {}
        self.shift = Vector((0, rig.height / 2, 0)) if rig.category in ("Troop", "King") else Vector((0, 0, 0))

    @property
    def set_name(self):
        return f"{VD.ASSET}_{'naves' if self.rig.category == 'Ship' else 'tropas'}"

    @property
    def budget_key(self):
        if self.rig.category == "Ship":
            return "Dropship" if self.rig.kind == "Dropship" else "Ship"
        return self.rig.category


def finish_crystal(obj):
    """Cristal: facetado (todas las aristas vivas) y triangulado."""
    me = obj.data
    for p in me.polygons:
        p.use_smooth = False
    t = obj.modifiers.new("Triangular", "TRIANGULATE")
    dg = bpy.context.evaluated_depsgraph_get()
    new = bpy.data.meshes.new_from_object(obj.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
    obj.modifiers.clear()
    old = obj.data
    obj.data = new
    bpy.data.meshes.remove(old)
    new.set_sharp_from_angle(angle=math.radians(1))
    return len(new.polygons)


def build_rig(rig, coll):
    b = Built(rig)
    for name, seg in rig.segs.items():
        for suffix, mb, kind in (("", seg.m, "main"), ("Cristal", seg.c, "crystal"), ("Brillo", seg.g, "glow")):
            if not mb.faces:
                continue
            mb.verts = [v - b.shift for v in mb.verts]
            part = name + suffix
            obj = mb.build(f"{rig.id}__{part}", coll)
            tris = finish_crystal(obj) if kind == "crystal" else AB.finish(obj, 0.0)
            b.objs[part] = obj
            b.info[part] = {"Name": part, "Joint": name, "Parent": seg.parent, "Glow": kind == "glow", "Crystal": kind == "crystal", "Tris": tris,
                            "Pivot": [round(c, 3) for c in (seg.pivot - b.shift)]}
            if name == "Scepter":
                b.info[part]["NoHit"] = True
    return b


def make_lod(b, coll):
    main = sum(i["Tris"] for i in b.info.values() if not i.get("Lod"))
    target = min(LOD_MAX[b.budget_key], int(main * 0.3))
    groups = (("main", "LOD"), ("crystal", "LODCristal"), ("glow", "LODBrillo"))
    share = {"main": 0.55, "crystal": 0.3, "glow": 0.15}
    for kind, part in groups:
        src = [o for n, o in b.objs.items() if not b.info[n].get("Lod") and ((kind == "glow") == b.info[n]["Glow"]) and ((kind == "crystal") == b.info[n]["Crystal"])]
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
        goal = max(120, int(target * share[kind]))
        if tris > goal:
            m = lod.modifiers.new("Simplificar", "DECIMATE")
            m.ratio = max(0.02, goal / tris)
            t = lod.modifiers.new("Triangular", "TRIANGULATE")
            dg = bpy.context.evaluated_depsgraph_get()
            new = bpy.data.meshes.new_from_object(lod.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
            lod.modifiers.clear()
            old = lod.data
            lod.data = new
            bpy.data.meshes.remove(old)
        b.objs[part] = lod
        b.info[part] = {"Name": part, "Joint": "Root", "Parent": "Root", "Glow": kind == "glow", "Crystal": kind == "crystal", "Tris": len(lod.data.polygons), "Lod": True, "Pivot": [0, 0, 0]}


# ====================================================================== poses (para las imágenes)
POSES = {
    "idle": {},
    "run": {"Body": (-0.32, 0.08, 0), "Head": (0.22, -0.05, 0), "LegL": (0.95, 0, 0), "LowerLegL": (-0.25, 0, 0), "LegR": (-0.75, 0, 0), "LowerLegR": (-1.15, 0, 0),
            "ArmL": (-0.85, 0, -0.15), "ForeArmL": (0.9, 0, 0), "ArmR": (0.9, 0, 0.15), "ForeArmR": (0.7, 0, 0)},
    "attack": {"Body": (-0.15, -0.45, 0), "Head": (0.1, 0.3, 0), "ArmR": (1.7, 0.2, 0.55), "ForeArmR": (0.35, 0, 0), "ArmL": (-0.5, 0, -0.35), "ForeArmL": (1.0, 0, 0),
               "LegL": (0.45, 0, -0.1), "LowerLegL": (-0.5, 0, 0), "LegR": (-0.35, 0, 0.1), "LowerLegR": (-0.35, 0, 0)},
    "aim": {"Body": (-0.06, -0.2, 0), "Head": (0.05, 0.18, 0), "ArmR": (0.55, 0.15, 0.0), "ForeArmR": (-0.4, 0, 0), "ArmL": (0.9, -0.35, -0.35), "ForeArmL": (0.9, 0.0, 0.3),
            "LegL": (0.3, 0, -0.08), "LowerLegL": (-0.35, 0, 0), "LegR": (-0.25, 0, 0.06), "LowerLegR": (-0.2, 0, 0)},
    "cape": {"Cape": (0.12, 0, 0), "Cape2": (0.15, 0, 0.05), "Cape3": (0.2, 0, 0.08)},
}


def place(b, at=(0, 0, 0), yaw=0.0, pose="idle"):
    p = POSES.get(pose, {})
    world = {}
    lift = b.shift.y if b.rig.category != "Ship" else 0.0
    base = Matrix.Translation(Vector(at) + Vector((0, lift, 0))) @ AB.rb_rot(yaw=yaw)
    for name, seg in b.rig.segs.items():
        parent = world.get(seg.parent, base)
        piv = Vector(seg.pivot) - b.shift
        r = p.get(name, (0, 0, 0))
        world[name] = parent @ (Matrix.Translation(piv) @ AB.rb_rot(*r) @ Matrix.Translation(-piv))
    for part, obj in b.objs.items():
        info = b.info[part]
        if info.get("Lod"):
            obj.hide_render = True
            continue
        obj.hide_render = False
        obj.matrix_world = AB.C @ world.get(info["Joint"], base) @ AB.CI


def hide_all(built):
    for b in built.values():
        for o in b.objs.values():
            o.hide_render = True


def stage(scene):
    """Fondo azul noche como el de la hoja, luz principal fría, contraluz cian y relleno."""
    world = bpy.data.worlds.get("Hoja") or bpy.data.worlds.new("Hoja")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (0.002, 0.007, 0.02, 1)
    bg.inputs["Strength"].default_value = 1.0
    nt.links.new(bg.outputs[0], out.inputs["Surface"])
    for name, kind, energy, size, color, eye in (
        ("Clave", "AREA", 300, 6, (0.85, 0.92, 1.0), (-8, 10, -14)),
        ("Contra", "AREA", 1600, 6, (0.35, 0.85, 1.0), (10, 9, 14)),
        ("Contra2", "AREA", 1300, 6, (0.35, 0.8, 1.0), (-12, 6, 10)),
        ("Relleno", "AREA", 450, 12, (0.6, 0.75, 1.0), (12, 3, -10)),
        ("Abajo", "AREA", 500, 12, (0.2, 0.6, 1.0), (0, -8, -6)),
    ):
        if bpy.data.objects.get(name):
            continue
        ld = bpy.data.lights.new(name, kind)
        ld.energy = energy
        ld.size = size
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
    scene.cycles.max_bounces = 6
    scene.cycles.transmission_bounces = 4
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.use_nodes = True
    ct = scene.node_tree
    ct.nodes.clear()
    rl = ct.nodes.new("CompositorNodeRLayers")
    gl = ct.nodes.new("CompositorNodeGlare")
    gl.glare_type = "FOG_GLOW"
    gl.quality = "HIGH"
    gl.threshold = 0.85
    gl.size = 7
    comp = ct.nodes.new("CompositorNodeComposite")
    ct.links.new(rl.outputs["Image"], gl.inputs["Image"])
    ct.links.new(gl.outputs["Image"], comp.inputs["Image"])


def cam_sun(scene, eye, target):
    sun = bpy.data.objects.get("SolCamara")
    if not sun:
        ld = bpy.data.lights.new("SolCamara", "SUN")
        ld.energy = 2.4
        ld.angle = math.radians(20)
        ld.color = (0.92, 0.96, 1.0)
        sun = bpy.data.objects.new("SolCamara", ld)
        scene.collection.objects.link(sun)
    e = Vector(eye)
    t = Vector(target)
    d = e - t
    side = d.cross(Vector((0, 1, 0)))
    if side.length < 1e-3:
        side = Vector((1, 0, 0))
    src = t + d.normalized() * 10 + Vector((0, 6, 0)) + side.normalized() * 4
    NB.look_at(sun, tuple(src), tuple(t))


def ortho(scene, cam, direction, target, scale, up=(0, 1, 0), path=None):
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = scale
    d = Vector(direction).normalized()
    eye = Vector(target) + d * 60
    NB.look_at(cam, tuple(eye), tuple(target), up)
    cam_sun(scene, eye, target)
    cam.data.clip_end = 500
    scene.render.filepath = path
    t0 = time.time()
    bpy.ops.render.render(write_still=True)
    log(f"  {os.path.basename(path)} en {time.time() - t0:.0f}s")


def persp(scene, cam, eye, target, lens, path):
    cam.data.type = "PERSP"
    cam.data.lens = lens
    NB.look_at(cam, eye, target)
    cam_sun(scene, eye, target)
    scene.render.filepath = path
    t0 = time.time()
    bpy.ops.render.render(write_still=True)
    log(f"  {os.path.basename(path)} en {time.time() - t0:.0f}s")


# Las vistas de la hoja del soldado (dirección de la cámara desde el modelo; el frente es -Z) y dónde
# está cada figura en soldado-360.png (x0, y0, x1, y1)
S = 0.7071
SOLDIER_VIEWS = [
    ("FRENTE", (0, 0.06, -1), (25, 128, 230, 528), (0, 1, 0)),
    ("FRONTAL DERECHA", (S, 0.06, -S), (210, 128, 405, 528), (0, 1, 0)),
    ("PERFIL DERECHO", (1, 0.04, 0), (395, 128, 585, 528), (0, 1, 0)),
    ("ESPALDA", (0, 0.06, 1), (565, 128, 760, 528), (0, 1, 0)),
    ("PERFIL IZQUIERDO", (-1, 0.04, 0), (750, 128, 935, 528), (0, 1, 0)),
    ("FRONTAL IZQUIERDA", (-S, 0.06, -S), (925, 128, 1105, 528), (0, 1, 0)),
    ("VISTA SUPERIOR", (0, 1, 0.0001), (1120, 160, 1320, 520), (0, 0, -1)),
    ("VISTA INFERIOR", (0, -1, 0.0001), (1310, 160, 1515, 520), (0, 0, -1)),
]
LEADER_VIEWS = [
    ("VISTA FRONTAL", (0, 0.04, -1), (12, 100, 330, 590)),
    ("VISTA LATERAL", (-1, 0.03, 0), (345, 140, 470, 570)),
    ("VISTA TRASERA", (0, 0.04, 1), (470, 140, 668, 570)),
]
SHIP_VIEWS = [
    ("VISTA FRONTAL", "front", (627, 672, 833, 806)),
    ("VISTA SUPERIOR", "top", (838, 672, 1060, 806)),
    ("VISTA TRASERA", "back", (627, 832, 833, 962)),
    ("VISTA LATERAL", "side", (838, 832, 1060, 962)),
    ("VISTA ISOMÉTRICA", "iso", (10, 670, 620, 975)),
]


def render_views(built, out_dir, samples, groups=("soldier", "leader", "ship", "extra")):
    scene = bpy.context.scene
    stage(scene)
    cam = bpy.data.objects.get("Camara") or bpy.data.objects.new("Camara", bpy.data.cameras.new("Camara"))
    if cam.name not in scene.collection.objects:
        scene.collection.objects.link(cam)
    scene.camera = cam
    tmp = os.path.join(out_dir, "_tmp")
    os.makedirs(tmp, exist_ok=True)
    paths = {"soldier": [], "leader": [], "ship": []}
    # --- el soldado en las 8 vistas
    if "soldier" not in groups:
        pass
    else:
        render_soldier(scene, cam, built, tmp, samples, paths)
    if "leader" in groups:
        render_leader(scene, cam, built, tmp, samples, paths)
    if "ship" in groups:
        render_ship(scene, cam, built, tmp, samples, paths)
    if "extra" in groups:
        render_extra(scene, cam, built, out_dir, samples, paths)
    return paths


def render_soldier(scene, cam, built, tmp, samples, paths):
    hide_all(built)
    place(built["Vortidos_Grunt"])
    setup_render(scene, samples, (400, 800))
    for i, (label, d, box, up) in enumerate(SOLDIER_VIEWS):
        p = os.path.join(tmp, f"s{i}.png")
        ortho(scene, cam, d, (0, 3.0, 0), 6.9 if up[1] else 6.4, up, p)
        paths["soldier"].append((label, p, box))


def render_leader(scene, cam, built, tmp, samples, paths):
    hide_all(built)
    place(built["Vortidos_King"])
    setup_render(scene, samples, (480, 760))
    for i, (label, d, box) in enumerate(LEADER_VIEWS):
        p = os.path.join(tmp, f"l{i}.png")
        ortho(scene, cam, d, (0, 5.6, 0), 12.4, (0, 1, 0), p)
        paths["leader"].append((label, p, box))


def render_ship(scene, cam, built, tmp, samples, paths):
    hide_all(built)
    place(built["Vortidos_Fighter"])
    for i, (label, kind, box) in enumerate(SHIP_VIEWS):
        p = os.path.join(tmp, f"n{i}.png")
        if kind == "iso":
            setup_render(scene, samples, (900, 480))
            persp(scene, cam, (13, 9, -15), (0, -0.4, 0.2), 45, p)
        else:
            setup_render(scene, samples, (640, 420))
            d, up = {"front": ((0, 0.12, -1), (0, 1, 0)), "top": ((0, 1, 0.0001), (0, 0, -1)), "back": ((0, 0.12, 1), (0, 1, 0)), "side": ((-1, 0.05, 0), (0, 1, 0))}[kind]
            ortho(scene, cam, d, (0, -0.2, -0.3), 17.5, up, p)
        paths["ship"].append((label, p, box))


def render_extra(scene, cam, built, out_dir, samples, paths):
    hide_all(built)
    # (una imagen por pose: el mismo modelo no puede estar en dos sitios a la vez)
    setup_render(scene, samples, (375, 640))
    strip = []
    for i, (kind, pose) in enumerate((("Grunt", "idle"), ("Grunt", "run"), ("Grunt", "attack"), ("Ranged", "aim"))):
        hide_all(built)
        place(built[f"Vortidos_{kind}"], (0, 0, 0), yaw=math.radians(-35), pose=pose)
        p = os.path.join(out_dir, "_tmp", f"pose{i}.png")
        persp(scene, cam, (0, 4.2, -15), (0, 3.0, 0), 40, p)
        strip.append(p)
    from PIL import Image
    sheet = Image.new("RGB", (375 * 4, 640))
    for i, p in enumerate(strip):
        sheet.paste(Image.open(p).convert("RGB"), (i * 375, 0))
    paths["poses"] = os.path.join(out_dir, "vortidos-poses.jpg")
    sheet.save(paths["poses"] + ".png")
    hide_all(built)
    setup_render(scene, samples, (1700, 800))
    row = [("Grunt", -9.0, 0), ("Ranged", -5.0, 0), ("Heavy", 0.0, 0), ("Elite", 6.0, 0)]
    for kind, x, _ in row:
        place(built[f"Vortidos_{kind}"], (x, 0, 0), yaw=math.radians(-15 if x < 0 else 15))
    place(built["Vortidos_Fighter"], (-3, 13, 14), yaw=math.radians(-30))
    place(built["Vortidos_Drone"], (-12, 10, 6), yaw=math.radians(20))
    paths["family"] = os.path.join(out_dir, "vortidos-familia.jpg")
    persp(scene, cam, (0, 7, -34), (0, 5.5, 0), 34, paths["family"] + ".png")
    hide_all(built)
    setup_render(scene, samples, (1700, 800))
    place(built["Vortidos_Dropship"], (0, 9, 0), yaw=math.radians(30))
    place(built["Vortidos_King"], (-14, 0, -12), yaw=math.radians(-20), pose="cape")
    paths["geoda"] = os.path.join(out_dir, "vortidos-lider-y-geoda.jpg")
    persp(scene, cam, (-6, 14, -68), (-3, 8, 0), 34, paths["geoda"] + ".png")


def compose(paths, out_dir, stats):
    from PIL import Image, ImageDraw, ImageFont

    fb = lambda s: ImageFont.truetype(FONT_BOLD, s)
    fr = lambda s: ImageFont.truetype(FONT, s)
    bg = (6, 14, 30)
    soldier_ref = Image.open(os.path.join(REF, "soldado-360.png")).convert("RGB")
    leader_ref = Image.open(os.path.join(REF, "lider-y-nave.png")).convert("RGB")

    def fit(im, w, h):
        k = min(w / im.width, h / im.height)
        im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.LANCZOS)
        out = Image.new("RGB", (w, h), bg)
        out.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
        return out

    def pair_sheet(title, sub, items, ref, cols, cell, out):
        cw, ch = cell
        rows = (len(items) + cols - 1) // cols
        W = cols * (cw * 2 + 30) + 30
        H = 110 + rows * (ch + 50) + 20
        sheet = Image.new("RGB", (W, H), bg)
        d = ImageDraw.Draw(sheet)
        d.text((30, 20), title, font=fb(30), fill=(235, 245, 255))
        d.text((30, 62), sub, font=fr(17), fill=(150, 190, 225))
        for i, (label, p, box) in enumerate(items):
            x = 30 + (i % cols) * (cw * 2 + 30)
            y = 110 + (i // cols) * (ch + 50)
            sheet.paste(fit(ref.crop(box), cw, ch), (x, y))
            sheet.paste(fit(Image.open(p).convert("RGB"), cw, ch), (x + cw, y))
            d.rectangle((x, y, x + 2 * cw, y + ch), outline=(40, 90, 140), width=2)
            d.line((x + cw, y, x + cw, y + ch), fill=(40, 90, 140), width=2)
            d.text((x + 6, y + ch + 6), f"{label} · hoja", font=fb(15), fill=(160, 210, 240))
            d.text((x + cw + 6, y + ch + 6), "modelo (Blender)", font=fb(15), fill=(120, 240, 255))
        sheet.save(out)
        return out

    outs = {}
    if paths["soldier"]:
        outs["soldado"] = pair_sheet("VÓRTIDOS · SOLDADO (ESQUIRLA) · las 8 vistas de la hoja", f"Izquierda: la hoja del dueño (soldado-360.png). Derecha: la malla de Blender en la misma vista. {stats['Vortidos_Grunt']:,} triángulos.".replace(",", "."),
                                 paths["soldier"], soldier_ref, 4, (230, 420), os.path.join(out_dir, "comparacion-soldado.png"))
    if paths["leader"]:
        outs["lider"] = pair_sheet("VÓRTIDOS · LÍDER (KAEL-ITHRA, LA VOZ DE LA GEODA) · frente, lado y espalda", f"Izquierda: lider-y-nave.png. Derecha: la malla (capa en 3 bandas que se mecen y cetro en la mano derecha). {stats['Vortidos_King']:,} triángulos.".replace(",", "."),
                               paths["leader"], leader_ref, 3, (300, 470), os.path.join(out_dir, "comparacion-lider.png"))
    if not paths["ship"]:
        return outs
    outs["nave"] = pair_sheet("VÓRTIDOS · NAVE «CLASE: GUARDIÁN» (FRAGATA PRISMA) · 5 vistas", f"Izquierda: lider-y-nave.png. Derecha: la malla. {stats['Vortidos_Fighter']:,} triángulos.".replace(",", "."),
                              paths["ship"][:4], leader_ref, 2, (420, 280), os.path.join(out_dir, "comparacion-nave.png"))
    iso = paths["ship"][4]
    im = Image.open(outs["nave"])
    iw = (im.width - 60) // 2
    ih = int(iw * 0.55)
    big = Image.new("RGB", (im.width, im.height + ih + 70), bg)
    big.paste(im, (0, 0))
    d = ImageDraw.Draw(big)
    big.paste(fit(leader_ref.crop(iso[2]), iw, ih), (30, im.height + 10))
    big.paste(fit(Image.open(iso[1]).convert("RGB"), iw, ih), (30 + iw, im.height + 10))
    d.text((36, im.height + ih + 16), "VISTA ISOMÉTRICA · hoja", font=fb(15), fill=(160, 210, 240))
    d.text((36 + iw, im.height + ih + 16), "modelo (Blender)", font=fb(15), fill=(120, 240, 255))
    big.save(outs["nave"])
    for key in ("poses", "family", "geoda"):
        if key not in paths:
            continue
        img = Image.open(paths[key] + ".png").convert("RGB")
        dd = ImageDraw.Draw(img)
        if key == "poses":
            for i, lab in enumerate(("QUIETO", "CORRER", "ATACAR (garras)", "PRISMA: APUNTAR")):
                dd.text((20 + i * img.width // 4, 20), lab, font=fb(22), fill=(220, 240, 255))
        img.save(paths[key], quality=88)
        os.remove(paths[key] + ".png")
    return outs


# ====================================================================== main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "invasion"))
    ap.add_argument("--docs", default=REF)
    ap.add_argument("--luau", default=os.path.join(ROOT, "src", "shared", "Invasion", "AlienMallas.luau"))
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--no-bake", action="store_true")
    ap.add_argument("--no-write", action="store_true", help="no toca el manifest ni el Luau (para probar)")
    ap.add_argument("--samples", type=int, default=40)
    ap.add_argument("--views", default="soldier,leader,ship,extra", help="qué imágenes: soldier, leader, ship, extra")
    args = ap.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else None)
    out_dir = os.path.abspath(args.out)
    tex_dir = os.path.join(out_dir, "tex")
    os.makedirs(tex_dir, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    t0 = time.time()
    make_materials()
    coll = bpy.data.collections.new("Vortidos")
    bpy.context.scene.collection.children.link(coll)
    built = {}
    for rig in VD.build_all():
        b = build_rig(rig, coll)
        built[rig.id] = b
        log(f"{rig.id}: {sum(i['Tris'] for i in b.info.values())} triángulos en {len(b.objs)} mallas")
    sets = {}
    for b in built.values():
        for part, o in b.objs.items():
            if not b.info[part]["Glow"] and not b.info[part]["Crystal"]:
                sets.setdefault(b.set_name, []).append(o)
    baked = {}
    for name, members in sets.items():
        NB.unwrap(members)
        if not args.no_bake:
            baked[name] = NB.bake_set(name, members, SET_SIZE, tex_dir, NB.MAPS)
    for name, paths in baked.items():
        mat = NB.pbr_material(name, paths)
        for o in sets[name]:
            NB.single_material(o, mat)
    for b in built.values():
        make_lod(b, coll)
    glow = NB.emission_mat("E_vortidos", lin(VD.PAL["Neon"]), 4.5)
    crystal = bpy.data.materials["R_cristal"]
    for b in built.values():
        for part, o in b.objs.items():
            if b.info[part]["Glow"]:
                NB.single_material(o, glow)
            elif b.info[part]["Crystal"]:
                NB.single_material(o, crystal)
    # Exportar y el manifest
    models = []
    stats = {}
    for rid, b in built.items():
        # UNA malla con esqueleto por modelo (+ su cristal y su brillo), nunca un segmento suelto: los
        # antebrazos y piernas sueltos de la v124 se los llevó la moderación (docs/bugs/moderacion/)
        fbx = os.path.join(out_dir, b.rig.asset + ".fbx")
        parts, bones = AB.skin_export(b, fbx, coll)
        tris = sum(p["Tris"] for p in parts if not p.get("Lod"))
        lod = sum(p["Tris"] for p in parts if p.get("Lod"))
        stats[rid] = tris
        rig = b.rig
        models.append({"Id": rid, "Asset": rig.asset, "Race": "Vortidos", "Kind": rig.kind, "Category": rig.category, "Gait": rig.gait, "Height": round(rig.height, 3),
                       "Set": b.set_name, "Material": "SmoothPlastic", "Fbx": os.path.basename(fbx), "Tris": tris, "LodTris": lod,
                       "Budget": AB.BUDGET[b.budget_key], "Attack": rig.attack, "Pulse": True, "CrystalColor": [round(c * 255) for c in VD.PAL["Cristal"]], "Skinned": True, "Bones": bones, "Parts": parts})
        log(f"  {rig.asset}.fbx: {tris} triángulos (+{lod} LOD)")
    if not args.no_write:
        mpath = os.path.join(out_dir, "manifest.json")
        with open(mpath) as f:
            manifest = json.load(f)
        ours = {m["Id"] for m in models}
        manifest["Models"] = [m for m in manifest["Models"] if m["Id"] not in ours] + models
        manifest["Models"].sort(key=lambda m: m["Id"])
        for name, paths in baked.items():
            manifest["Textures"][name] = {k: os.path.relpath(p, out_dir) for k, p in paths.items()}
        manifest["TotalTris"] = sum(m["Tris"] for m in manifest["Models"])
        manifest["Budget"] = {"MaxTrisPerMesh": AB.MAX_TRIS, **AB.BUDGET}
        with open(mpath, "w") as f:
            json.dump(manifest, f, indent=1, ensure_ascii=False)
        AB.write_luau(args.luau, manifest)
        log(f"manifest y {os.path.relpath(args.luau, ROOT)} escritos")
    over = [m["Id"] for m in models if m["Tris"] > m["Budget"]]
    log(f"listo en {time.time() - t0:.0f}s" + (f" ⚠️ fuera de presupuesto: {over}" if over else ""))
    if args.no_render:
        return
    paths = render_views(built, os.path.abspath(args.docs), args.samples, tuple(args.views.split(",")))
    outs = compose(paths, os.path.abspath(args.docs), stats)
    import shutil
    if not args.no_write:
        shutil.rmtree(os.path.join(os.path.abspath(args.docs), "_tmp"), ignore_errors=True)
    log(f"hojas: {', '.join(os.path.basename(p) for p in outs.values())} ({time.time() - t0:.0f}s)")


if __name__ == "__main__":
    main()
