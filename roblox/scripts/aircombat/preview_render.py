#!/usr/bin/env python3
"""Vistas previas del combate aéreo (Blender como módulo de Python, Cycles en CPU).

Dibuja las piezas DE VERDAD (las exporta scripts/aircombat/preview-export.luau con el código del juego:
shared/AirCombat/ShipModel y World/AirArena). No es una captura de Roblox: materiales aproximados
(neón = emisión, cristal = transparente, roca con algo de ruido), cielo y bruma parecidos a los que pone
el cliente en la arena.

Uso (desde la carpeta roblox/):
    lune run scripts/aircombat/preview-export.luau DIR
    python3 scripts/aircombat/preview_render.py DIR docs/combate-aereo [--samples 48]

Salida: nave.png (3/4 delante, con un piloto de muestra sentado), nave-vistas.png (lado, arriba,
detrás), enemigos.png, arena-canon.png y arena-espacio.png (en docs/combate-aereo van en .jpg).
"""
import argparse
import json
import math
import os

import bpy
from mathutils import Matrix, Vector


def roblox_to_blender(x, y, z):
    return Vector((x, -z, y))


P = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))


def part_matrix(cf):
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf
    R = Matrix(((r00, r01, r02), (r10, r11, r12), (r20, r21, r22)))
    Rb = P @ R @ P.transposed()
    M = Rb.to_4x4()
    M.translation = roblox_to_blender(x, y, z)
    return M


def local_vertices(shape, sx, sy, sz):
    """Vértices y caras en ejes de Roblox (X, Y, Z) del objeto."""
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    if shape == "Wedge":
        # WedgePart: base y cara de atrás (+Z) enteras; la rampa baja hacia delante (-Z)
        v = [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz), (-hx, hy, hz), (hx, hy, hz)]
        f = [(0, 1, 2, 3), (3, 2, 5, 4), (0, 4, 5, 1), (0, 3, 4), (1, 5, 2)]
        return v, f
    v = [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz), (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)]
    f = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (3, 2, 6, 7), (0, 3, 7, 4), (1, 5, 6, 2)]
    return v, f


_materials = {}


def material(color, mat, transparency):
    key = (tuple(round(c, 3) for c in color), mat, round(transparency, 2))
    if key in _materials:
        return _materials[key]
    m = bpy.data.materials.new(f"m{len(_materials)}")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    rgba = (color[0] ** 2.2, color[1] ** 2.2, color[2] ** 2.2, 1)
    bsdf.inputs["Base Color"].default_value = rgba
    rough = {"Metal": 0.35, "SmoothPlastic": 0.45, "Glass": 0.05, "Neon": 0.5}.get(mat, 0.92)
    bsdf.inputs["Roughness"].default_value = rough
    if mat == "Metal":
        bsdf.inputs["Metallic"].default_value = 0.55
    if mat == "Neon":
        bsdf.inputs["Emission Color"].default_value = rgba
        bsdf.inputs["Emission Strength"].default_value = 6.0
    if mat in ("Rock", "Slate", "Basalt", "Sandstone", "Sand", "Ground"):
        # (un poco de ruido de color y relieve: se lee como roca)
        noise = nt.nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 0.08 if mat in ("Sand", "Ground", "Sandstone") else 0.18
        noise.inputs["Detail"].default_value = 6
        coord = nt.nodes.new("ShaderNodeTexCoord")
        nt.links.new(coord.outputs["Object"], noise.inputs["Vector"])
        ramp = nt.nodes.new("ShaderNodeMixRGB")
        ramp.blend_type = "MULTIPLY"
        ramp.inputs["Fac"].default_value = 0.45
        ramp.inputs["Color1"].default_value = rgba
        nt.links.new(noise.outputs["Color"], ramp.inputs["Color2"])
        nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
        bump = nt.nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.35
        nt.links.new(noise.outputs["Fac"], bump.inputs["Height"])
        nt.links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    alpha = 1 - transparency
    if mat == "Glass":
        alpha = min(alpha, 0.55)
        bsdf.inputs["Coat Weight"].default_value = 0.6
    if alpha < 0.999:
        bsdf.inputs["Alpha"].default_value = max(alpha, 0.05)
    _materials[key] = m
    return m


def add_part(p, collection):
    shape = p["shape"]
    sx, sy, sz = p["size"]
    M = part_matrix(p["cf"])
    if shape == "Ball":
        r = min(sx, sy, sz) / 2
        bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=14, radius=r)
        obj = bpy.context.active_object
        bpy.ops.object.shade_smooth()
    elif shape == "Cylinder":
        r = min(sy, sz) / 2
        bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=r, depth=sx)
        obj = bpy.context.active_object
        # (el cilindro de Blender va en Z; el de Roblox en X)
        obj.data.transform(Matrix.Rotation(math.pi / 2, 4, "Y"))
    else:
        v, f = local_vertices(shape, sx, sy, sz)
        mesh = bpy.data.meshes.new(p["name"])
        mesh.from_pydata([tuple(roblox_to_blender(*xyz)) for xyz in v], [], f)
        mesh.update()
        obj = bpy.data.objects.new(p["name"], mesh)
        collection.objects.link(obj)
    for c in obj.users_collection:
        if c is not collection:
            c.objects.unlink(obj)
            if obj.name not in collection.objects:
                collection.objects.link(obj)
    # (los vértices ya están en ejes de Blender: la matriz pone el giro y la posición)
    obj.matrix_world = M
    obj.data.materials.append(material(p["color"], p["material"], p["transparency"]))
    return obj


def load_parts(path):
    with open(path) as fh:
        return json.load(fh)


def reset_scene(samples, width, height):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _materials.clear()
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    return scene


def world(scene, top, bottom, strength=1.0, stars=False):
    w = bpy.data.worlds.new("w")
    scene.world = w
    w.use_nodes = True
    nt = w.node_tree
    bg = nt.nodes["Background"]
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    nt.links.new(coord.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    ramp.color_ramp.elements[0].position = 0.45
    ramp.color_ramp.elements[0].color = (*bottom, 1)
    ramp.color_ramp.elements[1].position = 0.75
    ramp.color_ramp.elements[1].color = (*top, 1)
    out = ramp.outputs["Color"]
    if stars:
        voro = nt.nodes.new("ShaderNodeTexVoronoi")
        voro.inputs["Scale"].default_value = 260
        voro.feature = "F1"
        mapr = nt.nodes.new("ShaderNodeMapRange")
        mapr.inputs["From Min"].default_value = 0.0
        mapr.inputs["From Max"].default_value = 0.05
        mapr.inputs["To Min"].default_value = 6.0
        mapr.inputs["To Max"].default_value = 0.0
        mapr.clamp = True
        nt.links.new(coord.outputs["Generated"], voro.inputs["Vector"])
        nt.links.new(voro.outputs["Distance"], mapr.inputs["Value"])
        add = nt.nodes.new("ShaderNodeMixRGB")
        add.blend_type = "ADD"
        add.inputs["Fac"].default_value = 1
        nt.links.new(out, add.inputs["Color1"])
        nt.links.new(mapr.outputs["Result"], add.inputs["Color2"])
        out = add.outputs["Color"]
    nt.links.new(out, bg.inputs["Color"])
    bg.inputs["Strength"].default_value = strength


def sun(scene, rot, strength, color=(1, 0.95, 0.88)):
    light = bpy.data.lights.new("sol", "SUN")
    light.energy = strength
    light.color = color
    light.angle = math.radians(3)
    obj = bpy.data.objects.new("sol", light)
    scene.collection.objects.link(obj)
    obj.rotation_euler = rot
    return obj


def camera(scene, at, target, lens=40, clip_end=20000):
    cam = bpy.data.cameras.new("cam")
    cam.lens = lens
    cam.clip_end = clip_end
    obj = bpy.data.objects.new("cam", cam)
    scene.collection.objects.link(obj)
    obj.location = at
    direction = Vector(target) - Vector(at)
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = obj
    return obj


def mist(scene, start, depth, color):
    """Bruma: mezcla con un color según la distancia (pase de niebla)."""
    scene.view_layers[0].use_pass_mist = True
    scene.world.mist_settings.start = start
    scene.world.mist_settings.depth = depth
    scene.world.mist_settings.falloff = "QUADRATIC"
    scene.use_nodes = True
    nt = scene.node_tree
    rl = nt.nodes.new("CompositorNodeRLayers")
    comp = nt.nodes.new("CompositorNodeComposite")
    mix = nt.nodes.new("CompositorNodeMixRGB")
    mix.inputs[2].default_value = (*color, 1)
    nt.links.new(rl.outputs["Image"], mix.inputs[1])
    # (el cielo, lejísimos, solo un poco: arriba se sigue viendo azul)
    k = nt.nodes.new("CompositorNodeMath")
    k.operation = "MULTIPLY"
    k.inputs[1].default_value = 0.8
    nt.links.new(rl.outputs["Mist"], k.inputs[0])
    nt.links.new(k.outputs[0], mix.inputs[0])
    nt.links.new(mix.outputs[0], comp.inputs["Image"])


def render(scene, path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("✔", path)


def build(parts, offset=(0, 0, 0), name="col", filt=None):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    for p in parts:
        if filt and not filt(p):
            continue
        q = dict(p)
        cf = list(q["cf"])
        cf[0] += offset[0]
        cf[1] += offset[1]
        cf[2] += offset[2]
        q["cf"] = cf
        add_part(q, col)
    return col


def pilot(col):
    """Un piloto de muestra sentado en ShipSeat (cabeza y hombros en la burbuja)."""
    seat_top = -1.25 + 0.2
    hrp = seat_top + 1.5
    for name, size, at, color in (
        ("Torso", (2, 1.6, 1), (0, hrp + 0.6, -0.3), (0.15, 0.3, 0.6)),
        ("Cabeza", (1.2, 1.2, 1.2), (0, hrp + 2.0, -0.35), (0.95, 0.8, 0.6)),
        ("Casco", (1.32, 0.7, 1.32), (0, hrp + 2.4, -0.3), (0.95, 0.95, 0.98)),
    ):
        add_part({"name": name, "shape": "Block", "size": size, "cf": [*at, 1, 0, 0, 0, 1, 0, 0, 0, 1], "color": color, "material": "SmoothPlastic", "transparency": 0}, col)


def studio(scene):
    world(scene, (0.32, 0.42, 0.6), (0.06, 0.07, 0.1), 0.7)
    sun(scene, (math.radians(50), math.radians(10), math.radians(140)), 3.2)
    sun(scene, (math.radians(-60), math.radians(0), math.radians(-30)), 0.8, (0.6, 0.75, 1))
    bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, -6))
    floor = bpy.context.active_object
    floor.data.materials.append(material((0.16, 0.17, 0.2), "SmoothPlastic", 0))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("out")
    ap.add_argument("--samples", type=int, default=48)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    nave = load_parts(os.path.join(args.dir, "nave.json"))

    # 1) La nave, 3/4 de frente, con el piloto
    scene = reset_scene(args.samples, 1600, 900)
    studio(scene)
    col = build(nave, name="nave")
    pilot(col)
    camera(scene, roblox_to_blender(-19, 9, -21), roblox_to_blender(0, 0.5, 0.5), lens=42)
    render(scene, os.path.join(args.out, "nave.png"))

    # 2) Tres vistas (lado, arriba y detrás) en una sola imagen
    tiles = []
    for name, at in (("lado", (40, 0.01, 0.5)), ("arriba", (0.01, 40, 0.5)), ("atras", (0.01, 2, 40))):
        scene = reset_scene(args.samples, 700, 460)
        studio(scene)
        col = build(nave, name="nave")
        pilot(col)
        cam = camera(scene, roblox_to_blender(*at), roblox_to_blender(0, 0.5 if name != "arriba" else 0, 0.5), lens=50)
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = 26
        path = os.path.join(args.dir, f"vista-{name}.png")
        render(scene, path)
        tiles.append(path)
    try:
        from PIL import Image

        imgs = [Image.open(t) for t in tiles]
        sheet = Image.new("RGB", (sum(i.width for i in imgs), max(i.height for i in imgs)))
        x = 0
        for i in imgs:
            sheet.paste(i, (x, 0))
            x += i.width
        sheet.save(os.path.join(args.out, "nave-vistas.png"))
    except ImportError:
        pass

    # 3) Los enemigos
    scene = reset_scene(args.samples, 1600, 700)
    studio(scene)
    build(load_parts(os.path.join(args.dir, "dron.json")), offset=(-16, 0, 0), name="dron")
    build(load_parts(os.path.join(args.dir, "caza.json")), offset=(0, 0, 0), name="caza")
    build(load_parts(os.path.join(args.dir, "torreta.json")), offset=(16, 1, 0), name="torreta")
    camera(scene, roblox_to_blender(-4, 16, -30), roblox_to_blender(0, 0, 0), lens=34)
    render(scene, os.path.join(args.out, "enemigos.png"))

    # 4) La arena: el cañón desde el punto de control
    arena = load_parts(os.path.join(args.dir, "arena.json"))
    O = (24000, 0, 24000)
    scene = reset_scene(args.samples, 1600, 900)
    world(scene, (0.32, 0.5, 0.82), (0.95, 0.78, 0.6), 1.0)
    sun(scene, (math.radians(62), 0, math.radians(-35)), 3.6, (1, 0.88, 0.72))
    build(arena, name="arena", filt=lambda p: p["cf"][1] < 3300 and p["name"] != "Nubes")
    cp = (O[0], 1200 + 240, O[2] + 1350)
    ship_at = (cp[0] + 6, cp[1] - 3, cp[2] - 30)
    build(nave, offset=ship_at, name="nave")
    camera(scene, roblox_to_blender(cp[0] - 4, cp[1] + 7, cp[2] + 2), roblox_to_blender(O[0] + 150, 1330, O[2] - 400), lens=24)
    mist(scene, 300, 4200, (0.95, 0.82, 0.68))
    render(scene, os.path.join(args.out, "arena-canon.png"))

    # 5) El espacio de la arena: asteroides, cristales y el planeta
    scene = reset_scene(args.samples, 1600, 900)
    world(scene, (0.004, 0.004, 0.012), (0.02, 0.01, 0.04), 1.0, stars=True)
    sun(scene, (math.radians(40), 0, math.radians(60)), 3.0, (1, 0.95, 0.9))
    build(arena, name="espacio", filt=lambda p: p["cf"][1] >= 3300)
    cps = (O[0], 4600, O[2] + 1350)
    build(nave, offset=(cps[0] + 4, cps[1] - 2, cps[2] - 34), name="nave")
    camera(scene, roblox_to_blender(cps[0] - 6, cps[1] + 5, cps[2] - 6), roblox_to_blender(O[0] - 700, 5000, O[2] - 2000), lens=24, clip_end=40000)
    render(scene, os.path.join(args.out, "arena-espacio.png"))


if __name__ == "__main__":
    main()
