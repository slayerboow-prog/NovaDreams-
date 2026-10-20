#!/usr/bin/env python3
"""Puerto de Valmar con Blender (como módulo de Python: pip install bpy==4.2.0, Python 3.11, todo en CPU).

Dos cosas (docs/mapa/puerto.md):

1) MALLAS «estrella» del puerto (por defecto): grúa pórtico de muelle (STS) con pluma de celosía,
   contenedor de 40 y de 20 pies (chapa ondulada, puertas con barras de cierre), tetrápodo y bolardo.
   Se exportan en coordenadas de Roblox (studs) a assets/puerto/<Kind>.fbx (para subir) y .obj (pruebas),
   con assets/puerto/manifest.json y src/shared/Port/PuertoMalla.luau (centro y tamaño de cada malla,
   para colocarlas en el juego: World/PuertoMeshes) y una hoja de muestra docs/mapa/puerto-mallas.jpg.
   Después: bash scripts/upload-puerto.sh (escribe shared/Port/PuertoAssetIds.luau).

       python3 scripts/puerto/puerto_blender.py [--out assets/puerto] [--no-render]

2) VISTA PREVIA en perspectiva del puerto construido (NO es Roblox: formas y colores de las piezas
   con una luz de tarde hecha en Blender):

       lune run scripts/puerto/puerto-export.luau X.rbxl /tmp/puerto.json
       python3 scripts/puerto/puerto_blender.py --vista /tmp/puerto.json docs/mapa/puerto-vista-previa.jpg
"""
import argparse
import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def to_blender(p):
    """Roblox (X, Y arriba, Z sur) -> Blender (X, -Z, Y)."""
    return Vector((p[0], -p[2], p[1]))


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, rgb, metal=0.0, rough=0.6, alpha=1.0, emit=0.0):
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    col = (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1)
    bsdf.inputs["Base Color"].default_value = col
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    if alpha < 1:
        bsdf.inputs["Alpha"].default_value = alpha
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = emit
    return m


# ----------------------------------------------------------------------------------------------------
# Constructor de mallas en coordenadas de Roblox
# ----------------------------------------------------------------------------------------------------
class Mesh:
    def __init__(self):
        self.v = []
        self.f = []

    def box(self, c, size, R=None):
        """Caja de centro c y tamaño size; R = matriz 3x3 (columnas = ejes locales) en Roblox."""
        R = R or Matrix.Identity(3)
        hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
        base = len(self.v)
        for dx in (-hx, hx):
            for dy in (-hy, hy):
                for dz in (-hz, hz):
                    p = Vector(c) + R @ Vector((dx, dy, dz))
                    self.v.append(p)
        # índices: (x, y, z) -> base + ix*4 + iy*2 + iz
        def i(ix, iy, iz):
            return base + ix * 4 + iy * 2 + iz

        self.f += [
            (i(0, 0, 0), i(0, 0, 1), i(0, 1, 1), i(0, 1, 0)),
            (i(1, 0, 0), i(1, 1, 0), i(1, 1, 1), i(1, 0, 1)),
            (i(0, 0, 0), i(1, 0, 0), i(1, 0, 1), i(0, 0, 1)),
            (i(0, 1, 0), i(0, 1, 1), i(1, 1, 1), i(1, 1, 0)),
            (i(0, 0, 0), i(0, 1, 0), i(1, 1, 0), i(1, 0, 0)),
            (i(0, 0, 1), i(1, 0, 1), i(1, 1, 1), i(0, 1, 1)),
        ]

    def bar(self, a, b, t):
        """Barra de sección cuadrada t entre a y b."""
        a, b = Vector(a), Vector(b)
        d = b - a
        L = d.length
        z = d.normalized()
        up = Vector((0, 1, 0)) if abs(z.y) < 0.95 else Vector((1, 0, 0))
        x = up.cross(z).normalized()
        y = z.cross(x)
        R = Matrix((x, y, z)).transposed()
        self.box((a + b) / 2, (t, t, L), R)

    def cyl(self, c, r, h, n=12, axis="y", r2=None):
        """Cilindro (o tronco de cono si r2) de centro c, eje Y (o X)."""
        r2 = r if r2 is None else r2
        base = len(self.v)
        for k, (rr, yy) in enumerate(((r, -h / 2), (r2, h / 2))):
            for j in range(n):
                a = j / n * math.tau
                if axis == "y":
                    self.v.append(Vector(c) + Vector((math.cos(a) * rr, yy, math.sin(a) * rr)))
                else:
                    self.v.append(Vector(c) + Vector((yy, math.cos(a) * rr, math.sin(a) * rr)))
        for j in range(n):
            j2 = (j + 1) % n
            self.f.append((base + j, base + j2, base + n + j2, base + n + j))
        self.f.append(tuple(base + j for j in reversed(range(n))))
        self.f.append(tuple(base + n + j for j in range(n)))

    def cone_between(self, a, b, r1, r2, n=10):
        a, b = Vector(a), Vector(b)
        d = b - a
        z = d.normalized()
        up = Vector((0, 1, 0)) if abs(z.y) < 0.95 else Vector((1, 0, 0))
        x = up.cross(z).normalized()
        y = z.cross(x)
        base = len(self.v)
        for rr, p in ((r1, a), (r2, b)):
            for j in range(n):
                t = j / n * math.tau
                self.v.append(p + x * math.cos(t) * rr + y * math.sin(t) * rr)
        for j in range(n):
            j2 = (j + 1) % n
            self.f.append((base + j, base + j2, base + n + j2, base + n + j))
        self.f.append(tuple(base + j for j in reversed(range(n))))
        self.f.append(tuple(base + n + j for j in range(n)))

    def tris(self):
        return sum(len(f) - 2 for f in self.f)

    def obj(self, name, mat):
        me = bpy.data.meshes.new(name)
        me.from_pydata([to_blender(p) for p in self.v], [], self.f)
        me.update()
        o = bpy.data.objects.new(name, me)
        o.data.materials.append(mat)
        bpy.context.scene.collection.objects.link(o)
        return o


# ----------------------------------------------------------------------------------------------------
# Las mallas (mismas medidas que World/Kit/PuertoKit, con el pivote en el suelo entre los carriles)
# ----------------------------------------------------------------------------------------------------
def crane():
    m = Mesh()
    zs, zl = 15.0, -15.0  # carril de mar / de tierra (relativo)
    half = 11.0
    top, upper = 36.0, 44.0
    boomY = 47.5
    b0, b1 = 3232 - 3277, 3372 - 3277
    for z in (zs, zl):
        for s in (-1, 1):
            x = s * half
            m.box((x, upper / 2, z), (2.4, upper, 2.4))
            m.box((x, 1, z), (3.4, 2, 6))
        m.box((0, top, z), (24.4, 2.6, 2.6))
        m.box((0, upper - 1, z), (24.4, 2, 2))
    for s in (-1, 1):
        x = s * half
        m.box((x, 6, 0), (1.8, 1.8, zs - zl))
        m.box((x, top, 0), (2.4, 2.4, zs - zl))
        m.bar((x, 7, zl), (x, top - 1, zs), 1)
        m.bar((x, 7, zs), (x, top - 1, zl), 1)
    # pluma de celosía de verdad: cordones arriba y abajo, montantes y diagonales a los dos lados
    for s in (-1, 1):
        x = s * 5
        m.box((x, boomY, (b0 + b1) / 2), (1.8, 3.2, b1 - b0))
        m.box((x, boomY + 5, (b0 + b1) / 2 - 2), (1, 1, b1 - b0 - 4))
        z = b0 + 2
        up = True
        while z + 6 <= b1 - 2:
            m.bar((x, boomY + 1.6, z), (x, boomY + 5, z), 0.5)
            m.bar((x, boomY + (1.6 if up else 5), z), (x, boomY + (5 if up else 1.6), z + 6), 0.5)
            z += 6
            up = not up
    for z in range(int(b0) + 6, int(b1) - 6, 12):
        m.box((0, boomY + 5, z), (10, 0.8, 0.8))
        m.box((0, boomY - 1.4, z), (10, 0.6, 0.6))
    apex = Vector((0, upper + 26, zs - 8))
    for s in (-1, 1):
        a = apex + Vector((s * 3, 0, 0))
        m.bar((s * half, upper, zs), a, 1.8)
        m.bar((s * half, upper, zl), a, 1.4)
        m.bar(a, (s * 5, boomY + 5, b1 - 4), 0.5)
        m.bar(a, (s * 5, boomY + 5, (zs + b1) / 2 + 6), 0.5)
        m.bar(a, (s * 5, boomY + 5, b0 + 6), 0.5)
    m.box(apex, (8, 1.6, 1.6))
    m.box((0, boomY + 5.5, b0 + 12), (13, 7, 18))
    # escalera y ascensor en una pata
    m.box((half + 2.2, upper / 2, zl), (1.6, upper, 1.6))
    for y in range(4, int(upper), 8):
        m.box((half + 1.4, y, zl + 2.2), (3, 0.3, 3))
    return m


def container(long):
    m = Mesh()
    W, H = 6.8, 7.2
    # cuerpo y marco
    m.box((0, H / 2, 0), (long - 0.6, H - 0.6, W - 0.6))
    for y in (0.25, H - 0.25):
        for z in (-W / 2 + 0.25, W / 2 - 0.25):
            m.box((0, y, z), (long, 0.5, 0.5))
        for x in (-long / 2 + 0.25, long / 2 - 0.25):
            m.box((x, y, 0), (0.5, 0.5, W))
    for x in (-long / 2 + 0.25, long / 2 - 0.25):
        for z in (-W / 2 + 0.25, W / 2 - 0.25):
            m.box((x, H / 2, z), (0.5, H, 0.5))
    # chapa ondulada en los costados (nervios)
    n = int(long / 0.9)
    for k in range(n):
        x = -long / 2 + 0.6 + k * (long - 1.2) / max(1, n - 1)
        for z in (-W / 2 + 0.25, W / 2 - 0.25):
            m.box((x, H / 2, z), (0.35, H - 1, 0.62))
    # puertas: barras de cierre
    for z in (-1.9, -0.6, 0.6, 1.9):
        m.box((long / 2 - 0.15, H / 2, z), (0.25, H - 1, 0.18))
    return m


def tetrapod(size=7.0):
    m = Mesh()
    dirs = [(0, 1, 0), (0.9428, -0.3333, 0), (-0.4714, -0.3333, 0.8165), (-0.4714, -0.3333, -0.8165)]
    for d in dirs:
        tip = Vector(d) * size * 0.55
        m.cone_between((0, 0, 0), tip, size * 0.22, size * 0.14, n=10)
    return m


def bollard():
    m = Mesh()
    m.cyl((0, 0.15, 0), 1.0, 0.3, n=14)
    m.cyl((0, 0.9, 0), 0.6, 1.3, n=14, r2=0.55)
    m.cyl((0, 1.65, 0), 0.85, 0.3, n=14)
    return m


KINDS = [
    ("GruaSTS", crane, (28, 92, 170), 0.6),
    ("Contenedor40", lambda: container(34), (176, 58, 44), 0.5),
    ("Contenedor20", lambda: container(17), (40, 96, 160), 0.5),
    ("Tetrapodo", tetrapod, (186, 182, 172), 0.0),
    ("Bolardo", bollard, (28, 28, 30), 0.7),
]


def bounds(m):
    xs = [p.x for p in m.v]
    ys = [p.y for p in m.v]
    zs = [p.z for p in m.v]
    lo = Vector((min(xs), min(ys), min(zs)))
    hi = Vector((max(xs), max(ys), max(zs)))
    return (lo + hi) / 2, hi - lo


def select_only(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]


def build_meshes(out_dir, render):
    reset()
    os.makedirs(out_dir, exist_ok=True)
    manifest = {}
    objs = []
    for kind, fn, rgb, metal in KINDS:
        m = fn()
        center, size = bounds(m)
        o = m.obj(kind, material("puerto_" + kind, rgb, metal=metal))
        select_only([o])
        bpy.ops.export_scene.fbx(filepath=os.path.join(out_dir, kind + ".fbx"), use_selection=True, object_types={"MESH"}, apply_unit_scale=True, global_scale=1.0, axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", add_leaf_bones=False, path_mode="STRIP")
        bpy.ops.wm.obj_export(filepath=os.path.join(out_dir, kind + ".obj"), export_selected_objects=True, forward_axis="NEGATIVE_Z", up_axis="Y", export_normals=False, export_uv=False, export_materials=False, export_triangulated_mesh=True)
        manifest[kind] = {"tris": m.tris(), "center": [round(c, 3) for c in center], "size": [round(s, 3) for s in size]}
        objs.append((o, size))
        print(f"  {kind}: {m.tris()} triángulos, {size.x:.1f} × {size.y:.1f} × {size.z:.1f} studs")
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    # Para el juego: centro y tamaño de cada malla respecto a su pivote (World/PuertoMeshes)
    lua = ["-- PuertoMalla: GENERADO por scripts/puerto/puerto_blender.py (no editar a mano).",
           "-- Centro y tamaño (studs) de cada malla del puerto respecto a su pivote: grúa = suelo entre los",
           "-- carriles; contenedor = centro de la base; tetrápodo = su centro (tamaño 7); bolardo = pie.",
           "return {"]
    for kind in manifest:
        c, s = manifest[kind]["center"], manifest[kind]["size"]
        lua.append(f"\t{kind} = {{ Center = Vector3.new({c[0]}, {c[1]}, {c[2]}), Size = Vector3.new({s[0]}, {s[1]}, {s[2]}), Tris = {manifest[kind]['tris']} }},")
    lua.append("}")
    with open(os.path.join(ROOT, "src", "shared", "Port", "PuertoMalla.luau"), "w", encoding="utf-8") as f:
        f.write("\n".join(lua) + "\n")
    if render:
        sheet(objs, os.path.join(ROOT, "docs", "mapa", "puerto-mallas.jpg"))


def sun_and_world(strength=3.0):
    sc = bpy.context.scene
    world = bpy.data.worlds.new("cielo")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.62, 0.76, 0.92, 1)
    bg.inputs["Strength"].default_value = 0.55
    sc.world = world
    sun = bpy.data.lights.new("sol", "SUN")
    sun.energy = strength
    sun.angle = math.radians(3)
    so = bpy.data.objects.new("sol", sun)
    so.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    sc.collection.objects.link(so)


def camera_look(pos, target, lens=35, ortho=None):
    cam = bpy.data.cameras.new("cam")
    cam.lens = lens
    cam.clip_end = 20000
    if ortho:
        cam.type = "ORTHO"
        cam.ortho_scale = ortho
    co = bpy.data.objects.new("cam", cam)
    co.location = pos
    d = Vector(target) - Vector(pos)
    co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(co)
    bpy.context.scene.camera = co


def render_to(path, w, h, samples):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.render.image_settings.file_format = "JPEG"
    sc.render.image_settings.quality = 88
    sc.view_settings.view_transform = "Filmic" if "Filmic" in [i.identifier for i in sc.view_settings.bl_rna.properties["view_transform"].enum_items] else "AgX"
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def label(path, text):
    from PIL import Image, ImageDraw, ImageFont

    img = Image.open(path).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")
    try:
        f = ImageFont.truetype(FONT, max(18, img.width // 40))
    except OSError:
        f = ImageFont.load_default()
    pad = 10
    tw = d.textlength(text, font=f)
    d.rectangle([0, 0, tw + pad * 2, f.size + pad * 2], fill=(180, 20, 20, 220))
    d.text((pad, pad), text, font=f, fill=(255, 255, 255))
    img.save(path, quality=88)


def sheet(objs, path):
    """Las mallas en fila, para verlas (no es Roblox)."""
    x = 0
    for o, size in objs:
        o.location = Vector((x + size.x / 2, 0, 0)) + o.location
        x += size.x + 12
    ground = bpy.data.meshes.new("suelo")
    ground.from_pydata([(-40, -80, 0), (x + 40, -80, 0), (x + 40, 80, 0), (-40, 80, 0)], [], [(0, 1, 2, 3)])
    g = bpy.data.objects.new("suelo", ground)
    g.data.materials.append(material("suelo", (150, 148, 144)))
    bpy.context.scene.collection.objects.link(g)
    sun_and_world()
    camera_look((x * 0.5, -230, 80), (x * 0.5, 0, 30), lens=30)
    render_to(path, 1280, 600, 24)
    label(path, "VISTA PREVIA, NO ES ROBLOX · mallas del puerto (Blender)")


# ----------------------------------------------------------------------------------------------------
# Vista previa en perspectiva del puerto construido
# ----------------------------------------------------------------------------------------------------
def unit_wedge():
    me = bpy.data.meshes.new("cuña")
    # cuña de Roblox: alto atrás (+Z), bajo delante (-Z); en Roblox: (y, z) = (-1,-1), (-1, 1), (1, 1)
    v = []
    for x in (-0.5, 0.5):
        for (y, z) in ((-0.5, -0.5), (-0.5, 0.5), (0.5, 0.5)):
            v.append(to_blender((x, y, z)))
    f = [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (0, 2, 5, 3)]
    me.from_pydata(v, [], f)
    me.update()
    return me


def vista(json_path, out_path, samples):
    reset()
    data = json.load(open(json_path, encoding="utf-8"))
    plan = data["plan"]
    P = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
    bpy.ops.mesh.primitive_cube_add(size=1)
    cube = bpy.context.object.data
    bpy.data.objects.remove(bpy.context.object)
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.5, depth=1)
    cyl = bpy.context.object.data
    bpy.data.objects.remove(bpy.context.object)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.5)
    ball = bpy.context.object.data
    bpy.data.objects.remove(bpy.context.object)
    wedge = unit_wedge()
    for me in (cube, cyl, ball, wedge):
        me.materials.clear()
        me.materials.append(material("base", (128, 128, 128)))
    mats = {}
    sc = bpy.context.scene
    for p in data["parts"]:
        cf = p["cf"]
        pos = Vector(cf[0:3])
        R = Matrix((cf[3:6], cf[6:9], cf[9:12]))
        sx, sy, sz = p["size"]
        shape = p["s"]
        if shape == "Cylinder":
            # cilindro de Roblox: eje X local; el de Blender: eje Z local (Q lo lleva a la X de Roblox)
            Q = Matrix(((0, 0, 1), (1, 0, 0), (0, 1, 0)))
            mesh, M, scale = cyl, P @ R @ Q, Vector((sy, sz, sx))
        elif shape == "Ball":
            mesh, M, scale = ball, P @ R @ P.transposed(), Vector((sx, sz, sy))
        elif shape == "Wedge":
            mesh, M, scale = wedge, P @ R @ P.transposed(), Vector((sx, sz, sy))
        else:
            mesh, M, scale = cube, P @ R @ P.transposed(), Vector((sx, sz, sy))
        key = (tuple(p["c"]), p["m"], round(p["t"], 1))
        mat = mats.get(key)
        if not mat:
            metal = 0.6 if p["m"] in ("Metal", "DiamondPlate", "CorrodedMetal") else 0.0
            rough = 0.15 if p["m"] == "Glass" else 0.7
            emit = 1.5 if p["m"] == "Neon" else 0.0
            mat = material(f"m{len(mats)}", p["c"], metal=metal, rough=rough, alpha=1 - p["t"], emit=emit)
            mats[key] = mat
        o = bpy.data.objects.new(p["n"], mesh)
        o.matrix_world = Matrix.Translation(to_blender(pos)) @ M.to_4x4() @ Matrix.Diagonal(scale.to_4d())
        sc.collection.objects.link(o)
        # (la malla es compartida: el material va en el objeto, no en la malla)
        o.material_slots[0].link = "OBJECT"
        o.material_slots[0].material = mat
    # mar, tierra (costa de siempre) y dársena
    def flat(name, pts, y, rgb, rough=0.6):
        me = bpy.data.meshes.new(name)
        me.from_pydata([to_blender((x, y, z)) for x, z in pts], [], [tuple(range(len(pts)))])
        me.update()
        o = bpy.data.objects.new(name, me)
        o.data.materials.append(material(name, rgb, rough=rough))
        sc.collection.objects.link(o)
    x0, x1, z0, z1 = plan["Box"]
    flat("mar", [(x0 - 3000, z0 - 3000), (x1 + 3000, z0 - 3000), (x1 + 3000, z1 + 3000), (x0 - 3000, z1 + 3000)], plan["Sea"], (36, 110, 140), rough=0.08)
    flat("tierra", [(p[0], p[1]) for p in plan["Coast"]], -0.9, (120, 150, 90))
    b = plan["Basin"]
    # (la dársena se excava en la tierra: su agua va por encima del plano de tierra de este dibujo)
    flat("darsena", [(b["X0"], b["Z0"]), (b["X1"], b["Z0"]), (b["X1"], b["Z1"]), (b["X0"], b["Z1"])], -0.8, (34, 104, 132), rough=0.06)
    sun_and_world(3.2)
    camera_look(to_blender((1020, 150, 3830)), to_blender((620, 0, 3330)), lens=30)
    render_to(out_path, 1600, 900, samples)
    label(out_path, "VISTA PREVIA, NO ES ROBLOX · Puerto de Valmar")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "assets", "puerto"))
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--vista", nargs=2, metavar=("JSON", "SALIDA"))
    ap.add_argument("--samples", type=int, default=24)
    a = ap.parse_args()
    if a.vista:
        vista(a.vista[0], a.vista[1], a.samples)
    else:
        build_meshes(a.out, not a.no_render)


if __name__ == "__main__":
    main()
