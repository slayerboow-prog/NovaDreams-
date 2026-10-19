"""Vistas submarinas del mar de Valmar (vista previa con Blender, como el mapa: Blender como módulo
de Python, `pip install bpy==4.2.0`). El fondo sale de shared/Sea/Ocean (scripts/map/mar-export.luau
con una caja); lo demás (corales, kelp, pecio, criaturas…) es una aproximación con formas sencillas
de lo que ponen World/OceanBuilder, Controllers/SeaBiome y Controllers/SeaLife, con la luz y la
niebla de cada zona (shared/Sea/OceanBiomes). Sirve para ver el ambiente, no es una captura del juego.

Uso (desde la carpeta roblox/):
    lune run scripts/map/mar-export.luau 4 /tmp/v-arrecife.json 4240 -900 4740 -400
    python3 scripts/map/mar_blender.py /tmp/v-arrecife.json arrecife docs/mar/vista-arrecife.png
Vistas: arrecife, pecio, abismo, sima y catedrales (mar enorme, v120: el Cañón de las Catedrales con
Valmar Hundida, medusas, coral de luz y una ballena a lo lejos):
    lune run scripts/map/mar-export.luau 4 /tmp/v-cat.json -2950 5120 -1650 5720
    python3 scripts/map/mar_blender.py /tmp/v-cat.json catedrales docs/mar/vista-catedrales.png
"""
import json
import math
import random
import sys

import bpy

S = 0.1  # studs -> unidades de Blender


def to_b(x, y, z):
    return (x * S, -z * S, y * S)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.cycles.volume_step_rate = 4.0
    scene.cycles.volume_max_steps = 256
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    return scene


def material(name, color, emission=None, strength=0.0, rough=0.7, alpha=1.0, transmission=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Roughness"].default_value = rough
    if emission:
        p.inputs["Emission Color"].default_value = (*emission, 1)
        p.inputs["Emission Strength"].default_value = strength
    if transmission:
        p.inputs["Transmission Weight"].default_value = transmission
    if alpha < 1:
        p.inputs["Alpha"].default_value = alpha
    return m


def srgb(r, g, b):
    def c(v):
        v = v / 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return (c(r), c(g), c(b))


def seabed(g, colors):
    nx, nz, step = g["NX"], g["NZ"], g["Step"]
    verts, faces, zones = [], [], []
    for j in range(nz):
        for i in range(nx):
            y = g["Floors"][j][i]
            if y >= 900:
                y = -14
            x = g["MinX"] + i * step
            z = g["MinZ"] + j * step
            # textura de rocas: un poco de ruido
            y += (random.random() - 0.5) * 0.8
            verts.append(to_b(x, y, z))
            zones.append(g["Zones"][j][i])
    for j in range(nz - 1):
        for i in range(nx - 1):
            a = j * nx + i
            faces.append((a, a + 1, a + nx + 1, a + nx))
    mesh = bpy.data.meshes.new("Fondo")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Fondo", mesh)
    bpy.context.collection.objects.link(obj)
    mat = bpy.data.materials.new("FondoMat")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 6.0
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*colors[0], 1)
    ramp.color_ramp.elements[1].color = (*colors[1], 1)
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.6
    links.new(noise.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = 0.95
    obj.data.materials.append(mat)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()
    return obj


def floor_at(g, x, z):
    i = int(round((x - g["MinX"]) / g["Step"]))
    j = int(round((z - g["MinZ"]) / g["Step"]))
    i = max(0, min(g["NX"] - 1, i))
    j = max(0, min(g["NZ"] - 1, j))
    y = g["Floors"][j][i]
    return -14 if y >= 900 else y


WATER_BOX = {}


def water(fog, density, sun):
    # El fondo del cielo, del color de la niebla; el agua es una caja con volumen (si fuera el «mundo»,
    # la luz del sol llegaría desde el infinito y no quedaría nada)
    world = bpy.data.worlds.new("Mar")
    bpy.context.scene.world = world
    world.use_nodes = True
    nodes = world.node_tree.nodes
    nodes["Background"].inputs["Color"].default_value = (*fog, 1)
    nodes["Background"].inputs["Strength"].default_value = 0.6 * sun
    g = WATER_BOX["g"]
    x0, x1 = g["MinX"], g["MinX"] + (g["NX"] - 1) * g["Step"]
    z0, z1 = g["MinZ"], g["MinZ"] + (g["NZ"] - 1) * g["Step"]
    low = min(min(r) for r in g["Floors"]) - 10
    cx, cz, cy = (x0 + x1) / 2, (z0 + z1) / 2, (low - 2.2) / 2
    bpy.ops.mesh.primitive_cube_add(size=1, location=to_b(cx, cy, cz))
    cube = bpy.context.object
    cube.name = "Agua"
    cube.scale = ((x1 - x0) * S * 1.6, (z1 - z0) * S * 1.6, (-2.2 - low) * S)
    m = bpy.data.materials.new("AguaVol")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Color"].default_value = (*fog, 1)
    vol.inputs["Density"].default_value = density
    vol.inputs["Anisotropy"].default_value = 0.6
    vol.inputs["Absorption Color"].default_value = (*fog, 1)
    nt.links.new(vol.outputs["Volume"], nt.nodes["Material Output"].inputs["Volume"])
    cube.data.materials.append(m)


def light_from_above(strength, color=(0.85, 0.95, 1.0)):
    bpy.ops.object.light_add(type="SUN", rotation=(math.radians(14), math.radians(8), 0))
    sun = bpy.context.object
    sun.data.energy = strength
    sun.data.color = color
    sun.data.angle = math.radians(4)


def shafts(center, depth_top, n, power):
    for k in range(n):
        x = center[0] + (random.random() - 0.5) * 60
        z = center[2] + (random.random() - 0.5) * 60
        bpy.ops.object.light_add(type="SPOT", location=to_b(x, depth_top, z), rotation=(math.radians(random.uniform(-8, 8)), math.radians(random.uniform(-8, 8)), 0))
        spot = bpy.context.object
        spot.data.energy = power
        spot.data.spot_size = math.radians(12)
        spot.data.spot_blend = 0.6
        spot.data.color = (0.75, 0.95, 1.0)


def sphere(loc, scale, mat, name="Pieza"):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=loc)
    o = bpy.context.object
    o.name = name
    o.scale = scale
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def cyl(loc, radius, depth, rot, mat, name="Pieza"):
    bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=radius, depth=depth, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def box(loc, size, rot, mat, name="Pieza"):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.object
    o.name = name
    o.scale = size
    o.data.materials.append(mat)
    return o


def curve_tube(points, radius, mat, taper=True):
    cu = bpy.data.curves.new("Tubo", "CURVE")
    cu.dimensions = "3D"
    sp = cu.splines.new("NURBS")
    sp.points.add(len(points) - 1)
    for k, p in enumerate(points):
        w = 1 - (k / max(1, len(points) - 1)) * 0.85 if taper else 1
        sp.points[k].co = (*p, 1)
        sp.points[k].radius = w
    sp.use_endpoint_u = True
    cu.bevel_depth = radius
    cu.bevel_resolution = 3
    o = bpy.data.objects.new("Tubo", cu)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    return o


def fish_school(center, n, color, spread=3.0):
    mat = material("Pez", color, rough=0.35)
    for _ in range(n):
        d = (random.gauss(0, spread), random.gauss(0, spread * 0.4), random.gauss(0, spread))
        o = sphere((center[0] + d[0], center[1] + d[1], center[2] + d[2]), (0.035, 0.11, 0.05), mat, "Pez")
        o.rotation_euler = (0, 0, math.radians(30 + random.uniform(-10, 10)))


def diver(loc, look_rot):
    suit = material("Traje", srgb(20, 26, 36), rough=0.4)
    accent = material("Filo", srgb(40, 160, 255), emission=srgb(40, 160, 255), strength=3)
    body = sphere(loc, (0.12, 0.42, 0.12), suit, "Buceador")
    body.rotation_euler = look_rot
    sphere((loc[0], loc[1] - 0.42, loc[2] + 0.05), (0.1, 0.1, 0.1), suit)
    cyl((loc[0] + 0.1, loc[1] + 0.05, loc[2] + 0.1), 0.06, 0.4, (math.radians(90), 0, 0), accent)
    bpy.ops.object.light_add(type="SPOT", location=(loc[0] + 0.12, loc[1] - 0.45, loc[2]), rotation=(math.radians(95), 0, 0))
    lamp = bpy.context.object
    lamp.data.energy = 60
    lamp.data.spot_size = math.radians(30)
    lamp.data.color = (0.85, 0.95, 1.0)


def camera(loc, target, lens=24):
    bpy.ops.object.camera_add(location=loc)
    cam = bpy.context.object
    direction = (target[0] - loc[0], target[1] - loc[1], target[2] - loc[2])
    import mathutils
    rot = mathutils.Vector(direction).to_track_quat("-Z", "Y").to_euler()
    cam.rotation_euler = rot
    cam.data.lens = lens
    cam.data.clip_end = 400
    bpy.context.scene.camera = cam


def surface(z_top, extent):
    bpy.ops.mesh.primitive_plane_add(size=extent, location=(extent * 0, 0, z_top))
    plane = bpy.context.object
    m = material("Superficie", srgb(150, 220, 240), rough=0.05, transmission=1.0)
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["IOR"].default_value = 1.33
    plane.data.materials.append(m)
    mod = plane.modifiers.new("Olas", "DISPLACE")
    tex = bpy.data.textures.new("Olas", "CLOUDS")
    tex.noise_scale = 1.5
    mod.texture = tex
    mod.strength = 0.08
    bpy.ops.object.modifier_add(type="SUBSURF")
    plane.modifiers["Subdivision"].levels = 4
    return plane


# ----------------------------------------------------------------------------------------------
def view_arrecife(g):
    poi = next(p for p in g["Pois"] if p["Id"] == "ArcoCoral")
    seabed(g, (srgb(222, 206, 168), srgb(190, 170, 130)))
    water(srgb(40, 150, 175), 0.11, 1.0)
    light_from_above(6)
    cx, cz = poi["X"], poi["Z"]
    fy = floor_at(g, cx, cz)
    shafts((cx, 0, cz), -2, 6, 3000)
    surface(-0.2, 80)
    # arco de roca con costra de coral
    rock = material("Roca", srgb(120, 112, 100), rough=0.9)
    pts = []
    for k in range(13):
        a = math.pi * k / 12
        pts.append(to_b(cx + math.cos(a) * 18, fy - 2 + math.sin(a) * 18, cz + math.sin(a) * 0))
    arch = curve_tube(pts, 0.55, rock, taper=False)
    corals = [srgb(240, 70, 90), srgb(255, 150, 60), srgb(180, 80, 210), srgb(255, 210, 90), srgb(90, 200, 210)]
    cmats = [material("Coral%d" % k, c, rough=0.6) for k, c in enumerate(corals)]
    random.seed(4)
    for _ in range(170):
        x = cx + random.uniform(-80, 80)
        z = cz + random.uniform(-70, 70)
        y = floor_at(g, x, z)
        m = random.choice(cmats)
        kind = random.random()
        if kind < 0.35:
            sphere(to_b(x, y + 0.5, z), (random.uniform(0.15, 0.3),) * 2 + (random.uniform(0.1, 0.22),), m, "Cerebro")
        elif kind < 0.75:
            for b in range(5):
                a = random.uniform(0, math.pi * 2)
                h = random.uniform(0.2, 0.5)
                cyl(to_b(x + math.cos(a) * 0.4, y + h * 5, z + math.sin(a) * 0.4), 0.03, h, (random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), 0), m, "Rama")
        else:
            box(to_b(x, y + 0.8, z), (0.18, 0.015, 0.16), (0, 0, random.uniform(0, 3)), m, "Abanico")
    for _ in range(4):
        fish_school(to_b(cx + random.uniform(-30, 30), fy + random.uniform(5, 12), cz + random.uniform(-30, 30)), 40, random.choice([srgb(250, 205, 70), srgb(80, 160, 235), srgb(245, 130, 60)]))
    diver(to_b(cx - 20, fy + 9, cz + 26), (math.radians(80), 0, math.radians(40)))
    camx, camz = cx - 60, cz + 64
    camera(to_b(camx, max(floor_at(g, camx, camz), fy) + 16, camz), to_b(cx, fy + 6, cz))
    return arch


def view_pecio(g):
    poi = next(p for p in g["Pois"] if p["Id"] == "Pecio")
    seabed(g, (srgb(128, 120, 108), srgb(96, 92, 86)))
    water(srgb(18, 80, 130), 0.2, 0.6)
    light_from_above(3)
    cx, cz = poi["X"], poi["Z"]
    fy = floor_at(g, cx, cz)
    shafts((cx, 0, cz), -2, 4, 2500)
    wood = material("Madera", srgb(92, 70, 52), rough=0.9)
    dark = material("MaderaOscura", srgb(58, 44, 34), rough=0.95)
    import mathutils
    base = mathutils.Matrix.Translation(to_b(cx, fy + 5, cz)) @ mathutils.Euler((math.radians(14), 0, math.radians(25))).to_matrix().to_4x4()
    def put(offset, size, rot, mat):
        o = box((0, 0, 0), size, rot, mat)
        o.matrix_world = base @ mathutils.Matrix.Translation(offset) @ mathutils.Euler(rot).to_matrix().to_4x4()
        o.scale = size
        return o
    L, W, H = 6.4, 1.6, 1.1
    put((0, 0, -H / 2), (W, L, 0.12), (0, 0, 0), dark)
    for side in (-1, 1):
        for i in range(8):
            if side == 1 and i in (3, 4):
                continue
            put((side * W / 2, -L / 2 + 0.4 + i * 0.8, 0), (0.1, 0.82, H), (0, math.radians(side * 8), 0), wood if i % 2 else dark)
    for i in range(8):
        if i not in (3, 4):
            put((0, -L / 2 + 0.4 + i * 0.8, H / 2), (W - 0.1, 0.76, 0.06), (0, 0, 0), wood)
    cyl(to_b(cx + 18, fy + 2, cz + 6), 0.08, 4.6, (math.radians(84), 0, math.radians(70)), dark)
    gold = material("Oro", srgb(255, 210, 90), emission=srgb(255, 200, 90), strength=6)
    sphere(to_b(cx + 2, fy + 1, cz - 2), (0.2, 0.14, 0.14), gold, "Cofre")
    rock = material("Roca", srgb(90, 92, 96), rough=0.95)
    random.seed(7)
    for _ in range(40):
        x, z = cx + random.uniform(-60, 60), cz + random.uniform(-60, 60)
        sphere(to_b(x, floor_at(g, x, z), z), (random.uniform(0.2, 0.9),) * 2 + (random.uniform(0.15, 0.5),), rock)
    fish_school(to_b(cx - 6, fy + 14, cz - 10), 60, srgb(200, 215, 230), 4)
    diver(to_b(cx - 10, fy + 8, cz + 14), (math.radians(80), 0, math.radians(-20)))
    camera(to_b(cx - 30, max(floor_at(g, cx - 30, cz + 40), fy) + 14, cz + 40), to_b(cx, fy + 4, cz))


def megalodon(loc, yaw):
    grey = material("Megalodon", srgb(78, 92, 104), rough=0.55)
    belly = material("Vientre", srgb(200, 205, 210), rough=0.6)
    body = sphere(loc, (0.7, 2.8, 0.7), grey, "Megalodon")
    body.rotation_euler = (0, 0, yaw)
    import mathutils
    rot = mathutils.Euler((0, 0, yaw)).to_matrix()
    def at(off):
        v = rot @ mathutils.Vector(off)
        return (loc[0] + v.x, loc[1] + v.y, loc[2] + v.z)
    b2 = sphere(at((0, 0.2, -0.3)), (0.55, 2.4, 0.4), belly)
    b2.rotation_euler = (0, 0, yaw)
    fin = box(at((0, 0.3, 0.85)), (0.05, 0.55, 0.6), (math.radians(-25), 0, yaw), grey)
    tail = box(at((0, 3.0, 0.4)), (0.05, 0.5, 0.95), (math.radians(30), 0, yaw), grey)
    tail2 = box(at((0, 3.0, -0.35)), (0.05, 0.4, 0.6), (math.radians(-30), 0, yaw), grey)
    for s in (-1, 1):
        f = sphere(at((s * 0.75, -0.5, -0.35)), (0.6, 0.25, 0.05), grey)
        f.rotation_euler = (0, math.radians(s * 20), yaw)
    eye = material("Ojo", (0.0, 0.0, 0.0), rough=0.1)
    for s in (-1, 1):
        sphere(at((s * 0.45, -2.2, 0.15)), (0.05, 0.05, 0.05), eye)
    teeth = material("Dientes", srgb(240, 240, 230))
    box(at((0, -2.55, -0.28)), (0.4, 0.04, 0.04), (0, 0, yaw), teeth)
    return body, fin, tail, tail2


def view_abismo(g):
    poi = next(p for p in g["Pois"] if p["Id"] == "JardinLuz")
    seabed(g, (srgb(60, 56, 48), srgb(34, 32, 36)))
    # (mar enorme, v120: bruma azul que deja ver lejos, no negra; OceanBiomes.Zones.Abismo.Look)
    water(srgb(10, 42, 98), 0.07, 1.2)
    light_from_above(0.45, (0.5, 0.7, 1.0))
    cx, cz = poi["X"], poi["Z"]
    fy = floor_at(g, cx, cz)
    glows = [srgb(60, 240, 255), srgb(140, 90, 255), srgb(60, 255, 170), srgb(255, 90, 210)]
    gm = [material("Luz%d" % k, c, emission=c, strength=25) for k, c in enumerate(glows)]
    random.seed(11)
    for _ in range(140):
        a = random.uniform(0, math.pi * 2)
        d = random.uniform(2, 60)
        x, z = cx + math.cos(a) * d, cz + math.sin(a) * d
        y = floor_at(g, x, z)
        h = random.uniform(0.2, 0.9)
        m = random.choice(gm)
        cyl(to_b(x, y + h * 5, z), 0.04, h, (random.uniform(-0.2, 0.2), random.uniform(-0.2, 0.2), 0), m, "Tubo")
        if random.random() < 0.1:
            bpy.ops.object.light_add(type="POINT", location=to_b(x, y + 3, z))
            l = bpy.context.object
            l.data.energy = 25
            l.data.color = m.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value[:3]
    # nieve marina
    snow = material("Nieve", (1, 1, 1), emission=(0.8, 0.9, 1.0), strength=1.5)
    for _ in range(260):
        sphere(to_b(cx + random.uniform(-40, 40), fy + random.uniform(1, 40), cz + random.uniform(-40, 40)), (0.012,) * 3, snow)
    # campo de medusas que brillan (Ocean.JellyFields «Jardín de Luz») y coral de luz
    for _ in range(45):
        jx, jz = cx + random.uniform(-70, 70), cz + random.uniform(-90, 20)
        jelly(to_b(jx, fy + random.uniform(10, 70), jz), random.uniform(1.6, 5), random.choice([srgb(255, 110, 200), srgb(90, 230, 255), srgb(170, 110, 255)]))
    for _ in range(14):
        tx, tz = cx + random.uniform(-50, 50), cz + random.uniform(-50, 30)
        light_tree(tx, floor_at(g, tx, tz), tz, random.uniform(4, 10), random.choice([srgb(235, 250, 255), srgb(110, 235, 255), srgb(255, 130, 215)]))
    # una ballena que pasa a lo lejos
    whale(to_b(cx + 40, fy + 70, cz - 110), math.radians(100), 90)
    megalodon(to_b(cx + 4, fy + 22, cz - 18), math.radians(35))
    diver(to_b(cx - 14, fy + 8, cz + 16), (math.radians(80), 0, math.radians(30)))
    camera(to_b(cx - 34, max(floor_at(g, cx - 34, cz + 38), fy) + 12, cz + 38), to_b(cx, fy + 14, cz - 10), lens=22)


def view_sima(g):
    lair = g["Lair"]
    seabed(g, (srgb(40, 36, 44), srgb(22, 20, 26)))
    water(srgb(10, 4, 30), 0.08, 0.3)
    light_from_above(0.6, (0.6, 0.5, 1.0))
    lx, ly, lz = lair["X"], lair["Y"], lair["Z"]
    rock = material("Basalto", srgb(36, 32, 40), rough=0.95)
    massif = sphere(to_b(lx, ly + 10, lz - 40), (10, 10, 10), rock, "Mole")
    hole = material("Cueva", (0, 0, 0), rough=1)
    sphere(to_b(lx, ly - 4, lz + 52), (2.2, 1.0, 1.6), hole, "Boca")
    body = material("Kraken", srgb(120, 40, 60), rough=0.5)
    sphere(to_b(lx, ly - 4, lz + 46), (2.0, 1.4, 1.6), body, "Manto")
    eye = material("OjoKraken", srgb(255, 210, 60), emission=srgb(255, 200, 80), strength=30)
    for s in (-1, 1):
        sphere(to_b(lx + s * 6, ly + 1, lz + 56), (0.25, 0.12, 0.25), eye)
    random.seed(5)
    for t in range(5):
        pts = []
        base = (lx + random.uniform(-8, 8), ly - 6, lz + 58)
        ang = random.uniform(-0.8, 0.8)
        for k in range(8):
            u = k / 7
            pts.append(to_b(base[0] + math.sin(ang) * 60 * u + math.sin(u * 7 + t) * 6, base[1] - 10 * u + math.sin(u * 4 + t) * 12 + 18 * u * (t == 0), base[2] + 70 * u))
        curve_tube(pts, 0.32, body)
    eggs = material("Huevo", srgb(150, 60, 220), emission=srgb(150, 60, 220), strength=15)
    for k in range(7):
        sphere(to_b(lx + math.cos(k) * 12, ly - 30, lz + 70 + math.sin(k) * 9), (0.12, 0.12, 0.16), eggs)
    glows = [srgb(140, 90, 255), srgb(60, 240, 255)]
    for _ in range(60):
        x, z = lx + random.uniform(-60, 60), lz + random.uniform(20, 160)
        y = floor_at(g, x, z)
        c = random.choice(glows)
        cyl(to_b(x, y + 2, z), 0.04, 0.4, (0, 0, 0), material("Luz", c, emission=c, strength=20))
    bpy.ops.object.light_add(type="POINT", location=to_b(lx, ly + 4, lz + 60))
    bpy.context.object.data.energy = 25000
    bpy.context.object.data.color = (0.7, 0.35, 1.0)
    bpy.ops.object.light_add(type="AREA", location=to_b(lx + 20, ly + 60, lz + 120))
    fill = bpy.context.object
    fill.data.energy = 40000
    fill.data.size = 8
    fill.data.color = (0.45, 0.4, 1.0)
    fy = floor_at(g, lx, lz + 110)
    diver(to_b(lx + 10, fy + 30, lz + 120), (math.radians(80), 0, math.radians(190)))
    camera(to_b(lx + 30, fy + 40, lz + 160), to_b(lx, ly + 2, lz + 50), lens=20)
    return massif


# ----------------------------------------------------------------------------------------------
# Mar enorme (v120): piezas de la vida grande y de la luz
def whale(loc, yaw, length=80):
    skin = material("Ballena", srgb(40, 52, 66), rough=0.5)
    belly = material("Vientre", srgb(140, 150, 156), rough=0.6)
    L = length * S
    body = sphere(loc, (L * 0.11, L * 0.5, L * 0.1), skin, "Ballena")
    body.rotation_euler = (0, 0, yaw)
    fwd = (-math.sin(yaw), math.cos(yaw))
    sphere((loc[0] + fwd[0] * L * 0.32, loc[1] + fwd[1] * L * 0.32, loc[2] - 0.2), (L * 0.09, L * 0.16, L * 0.08), skin).rotation_euler = (0, 0, yaw)
    sphere((loc[0], loc[1], loc[2] - L * 0.06), (L * 0.08, L * 0.36, L * 0.04), belly).rotation_euler = (0, 0, yaw)
    tail = (loc[0] - fwd[0] * L * 0.55, loc[1] - fwd[1] * L * 0.55, loc[2] + 0.4)
    sphere(tail, (L * 0.2, L * 0.06, L * 0.012), skin).rotation_euler = (0, 0, yaw)
    for sd in (-1, 1):
        side = (math.cos(yaw) * sd, math.sin(yaw) * sd)
        fin = sphere((loc[0] + side[0] * L * 0.12 + fwd[0] * L * 0.15, loc[1] + side[1] * L * 0.12 + fwd[1] * L * 0.15, loc[2] - 0.5), (L * 0.1, L * 0.035, L * 0.01), skin)
        fin.rotation_euler = (0, sd * 0.4, yaw)


def manta(loc, yaw, span=30):
    skin = material("Manta", srgb(28, 36, 50), rough=0.5)
    w = span * S
    o = sphere(loc, (w * 0.5, w * 0.28, w * 0.04), skin, "Manta")
    o.rotation_euler = (0, 0, yaw)


def jelly(loc, size, color):
    jm = material("Medusa", color, emission=color, strength=10, alpha=0.55)
    sphere(loc, (size * S * 0.5, size * S * 0.5, size * S * 0.36), jm, "Medusa")
    tm = material("Tentaculo", color, emission=color, strength=5, alpha=0.4)
    for k in range(4):
        a = k * math.pi / 2
        cyl((loc[0] + math.cos(a) * size * S * 0.18, loc[1] + math.sin(a) * size * S * 0.18, loc[2] - size * S * 0.9), 0.012, size * S * 1.6, (random.uniform(-0.15, 0.15), random.uniform(-0.15, 0.15), 0), tm, "Tentaculo")


def light_tree(x, y, z, h, color):
    stem = material("TroncoLuz", srgb(200, 220, 230), rough=0.5)
    tip = material("RamaLuz", color, emission=color, strength=14)
    cyl(to_b(x, y + h / 2, z), 0.035, h * S, (0, 0, 0), stem, "Coral")
    for lv in range(3):
        yy = y + h * (0.45 + 0.27 * lv)
        ln = (3.4 - lv * 0.7) * S * 1.4
        for b in range(3):
            a = b * math.pi * 2 / 3 + lv * 0.9
            tilt = math.radians(48 + lv * 8)
            cx = x + math.cos(a) * math.sin(tilt) * ln / S / 2
            cz = z + math.sin(a) * math.sin(tilt) * ln / S / 2
            o = cyl(to_b(cx, yy + math.cos(tilt) * ln / S / 2, cz), 0.018, ln, (0, tilt, -a), tip, "Rama")
            o.rotation_mode = "XYZ"


def view_catedrales(g):
    poi = next(p for p in g["Pois"] if p["Id"] == "ValmarHundida")
    seabed(g, (srgb(70, 78, 92), srgb(40, 46, 60)))
    fog = srgb(16, 78, 132)
    water(fog, 0.045, 1.1)
    light_from_above(1.1, (0.7, 0.88, 1.0))
    random.seed(21)
    cx, cz = poi["X"], poi["Z"]
    fy = floor_at(g, cx, cz)
    d = (1.0, -0.064)
    n = math.hypot(*d)
    d = (d[0] / n, d[1] / n)
    side = (-d[1], d[0])

    def at(x, z):
        px, pz = cx + side[0] * x - d[0] * z, cz + side[1] * x - d[1] * z
        return px, floor_at(g, px, pz), pz

    stone = [material("Piedra%d" % k, srgb(*c), rough=0.85) for k, c in enumerate([(96, 104, 104), (82, 92, 98), (108, 102, 90), (74, 84, 80)])]
    roof = [material("Tejado%d" % k, srgb(*c), rough=0.8) for k, c in enumerate([(70, 92, 104), (96, 70, 60), (58, 82, 76)])]
    warm = material("Farol", srgb(255, 176, 84), emission=srgb(255, 176, 84), strength=60)
    warm2 = material("Ventana", srgb(255, 206, 140), emission=srgb(255, 190, 110), strength=45)
    yaw = math.atan2(d[1], d[0])
    k = 0
    for sd in (-1, 1):
        for row in (0, 1):
            for i in range(5):
                k += 1
                z = -60 + i * 30
                x = sd * (18 + random.random() * 6 if row == 0 else 62 + random.random() * 8)
                px, py, pz = at(x, z)
                w, dp, h = 12 + random.random() * 6, 11, 10 + random.random() * 8 + row * 4
                box(to_b(px, py + h / 2, pz), (dp * S, w * S, h * S), (0, 0, -yaw), stone[k % 4])
                box(to_b(px, py + h + 1.5, pz), (dp * S * 1.05, w * S * 1.05, 3 * S), (0, 0, -yaw), roof[k % 3])
                for wy in (-1, 1):
                    wx = px - side[0] * sd * 5.7
                    wz = pz - side[1] * sd * 5.7
                    box(to_b(wx + d[0] * wy * w * 0.3, py + h * 0.62, wz + d[1] * wy * w * 0.3), (0.6 * S, 3 * S, 3.4 * S), (0, 0, -yaw), warm2)
    # farolas y guirnaldas
    for i in range(6):
        z = -62 + i * 25
        for sd in (-1, 1):
            px, py, pz = at(sd * 9, z)
            cyl(to_b(px, py + 4.5, pz), 0.03, 9 * S, (0, 0, 0), stone[1])
            sphere(to_b(px, py + 9.4, pz), (0.12, 0.12, 0.12), warm)
    for gi in range(4):
        z = -48 + gi * 32
        ax_, ay, az = at(-13, z)
        bx, by, bz = at(13, z)
        for kk in range(9):
            t = kk / 8
            sag = math.sin(t * math.pi) * 5
            sphere(to_b(ax_ + (bx - ax_) * t, ay + 15 + (by - ay) * t - sag, az + (bz - az) * t), (0.07, 0.07, 0.08), warm)
    for kk in range(5):
        px, py, pz = at(random.uniform(-20, 20), random.uniform(-60, 60))
        bpy.ops.object.light_add(type="POINT", location=to_b(px, py + 10, pz))
        bpy.context.object.data.energy = 1200
        bpy.context.object.data.color = (1.0, 0.62, 0.3)
    # la torre del faro hundido
    px, py, pz = at(-40, 70)
    cyl(to_b(px, py + 23, pz), 5 * S, 46 * S, (0, 0, 0), stone[2])
    sphere(to_b(px, py + 50, pz), (0.3, 0.3, 0.3), warm)
    bpy.ops.object.light_add(type="POINT", location=to_b(px, py + 50, pz))
    bpy.context.object.data.energy = 20000
    bpy.context.object.data.color = (1.0, 0.75, 0.45)
    # coral de luz por el cañón
    tips = [srgb(235, 250, 255), srgb(110, 235, 255), srgb(255, 130, 215), srgb(190, 140, 255)]
    for _ in range(40):
        px, py, pz = at(random.uniform(-90, 90), random.uniform(-200, 220))
        light_tree(px, py, pz, random.uniform(4, 10), random.choice(tips))
    # campo de medusas (más allá, subiendo por la columna de agua)
    for _ in range(60):
        px, py, pz = at(random.uniform(-70, 70), random.uniform(-260, -80))
        jelly(to_b(px, py + random.uniform(12, 90), pz), random.uniform(1.6, 5), random.choice([srgb(255, 110, 200), srgb(90, 230, 255), srgb(170, 110, 255)]))
    # gigantes a lo lejos
    wx, wy, wz = at(-30, -125)
    whale(to_b(wx, wy + 62, wz), yaw + math.radians(80), 95)
    mx, my, mz = at(28, -70)
    manta(to_b(mx, my + 36, mz), yaw + math.radians(-30))
    fx, fyy, fz = at(10, -40)
    fish_school(to_b(fx, fyy + 22, fz), 60, srgb(250, 205, 70), spread=3.0)
    # agujas en lo alto de las paredes
    rock = material("Basalto", srgb(46, 52, 66), rough=0.95)
    for zz in (-180, -40, 120):
        for sd in (-1, 1):
            px, py, pz = at(sd * 140, zz)
            cyl(to_b(px, py + 40, pz), 12 * S, 80 * S, (random.uniform(-0.08, 0.08), random.uniform(-0.08, 0.08), 0), rock)
    shafts(to_b(cx, -2, cz), -3, 6, 4000)
    dx_, dy_, dz_ = at(4, 40)
    diver(to_b(dx_, dy_ + 26, dz_), (math.radians(80), 0, -yaw + math.radians(90)))
    camx, camy, camz = at(6, 165)
    tx, ty, tz = at(0, -160)
    camera(to_b(camx, camy + 52, camz), to_b(tx, ty + 32, tz), lens=18)


VIEWS = {"arrecife": view_arrecife, "pecio": view_pecio, "abismo": view_abismo, "sima": view_sima, "catedrales": view_catedrales}


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    src, view, out = args[0], args[1], args[2]
    with open(src) as f:
        g = json.load(f)
    WATER_BOX["g"] = g
    random.seed(1)
    scene = reset()
    if len(args) > 3:
        scene.cycles.samples = int(args[3])
    VIEWS[view](g)
    scene.render.filepath = out
    bpy.ops.render.render(write_still=True)
    print("ok", out)


if __name__ == "__main__":
    main()
