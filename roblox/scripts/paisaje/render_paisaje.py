#!/usr/bin/env python3
"""Vista aérea de Valmar para COMPARAR el paisaje antes y después (docs/paisaje/paisaje.md).

No es una captura del juego: es el mapa construido (las piezas de workspace.Town y el terreno que pone
TerrainBuilder al arrancar, con o sin el relieve nuevo) dibujado con Blender (Cycles) desde un ángulo
parecido al de la imagen de referencia del dueño (avión sobre la costa, mirando la isla). La luz, la
bruma, el color y el agua imitan los ajustes del juego de cada versión (shared/DayGrade, Atmosphere,
Terrain.Water*, shared/Seasons), así que sirve para comparar el CAMBIO, no el render de Roblox.

Necesita Blender como módulo de Python (pip install bpy==4.2.0), numpy y opencv.

Uso (desde la carpeta roblox/):
    rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
    lune run scripts/map/export.luau X.rbxl DIR
    lune run scripts/paisaje/export-relief.luau X.rbxl DIR
    python3 scripts/paisaje/render_paisaje.py DIR OUT.png --look antes|despues [--width 1600] [--samples 32]
                                                         [--view noreste|sur]
"""
import argparse
import json
import math
import os
import sys
import time

import cv2
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "map"))
import blender_render as BR  # noqa: E402  (read_parts, MeshBuilder, unit_sphere, make_mesh, parts_material)

# ----------------------------------------------------------------------------------------------------
# Cómo se ve cada versión (los valores del juego: DayGrade a las 12:30 y la estación de la captura)
# ----------------------------------------------------------------------------------------------------
LOOKS = {
    # v117 (la captura del dueño): bruma densa azul pálido, colores apagados, invierno grisáceo
    "antes": {
        "haze_color": (204, 214, 230), "haze_strength": 0.9, "haze_depth": 3600.0, "haze_start": 150.0,
        "saturation": 0.92 - 0.08, "contrast": 1.21, "exposure": -0.1,
        "grass": (111, 134, 85), "leafy": (99, 125, 76), "rock": (132, 124, 112), "sand": (230, 212, 170), "ground": (138, 120, 88),
        "water": (28, 104, 124), "water_clear": 0.55,
        "sky": "nishita_palido", "sun_strength": 3.6, "cloud_density": 0.52, "relief": False, "forests": False,
    },
    # v118 (paisaje): aire limpio, bruma solo en el horizonte, color vivo, verdes del invierno mediterráneo
    "despues": {
        "haze_color": (199, 216, 238), "haze_strength": 0.6, "haze_depth": 11000.0, "haze_start": 600.0,
        "saturation": 1.08 + 0.05, "contrast": 1.17, "exposure": -0.06,
        "grass": (88, 132, 63), "leafy": (79, 120, 53), "rock": (124, 117, 106), "sand": (232, 214, 172), "ground": (130, 110, 80),
        "water": (18, 98, 138), "water_clear": 0.62,
        "sky": "propio", "sun_strength": 4.2, "cloud_density": 0.62, "relief": True, "forests": True,
    },
}

VIEWS = {
    # cámara (Roblox: X, Y, Z) y punto al que mira; campo de visión horizontal
    "noreste": {"eye": (5200, 760, -4700), "at": (1600, -120, -1700), "fov": 62},
    "sur": {"eye": (300, 820, 6200), "at": (0, -200, 1200), "fov": 62},
}


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("out")
    ap.add_argument("--look", choices=sorted(LOOKS), default="despues")
    ap.add_argument("--view", choices=sorted(VIEWS), default="noreste")
    ap.add_argument("--width", type=int, default=1600)
    ap.add_argument("--samples", type=int, default=32)
    return ap.parse_args()


def lin(c):
    return BR.srgb_to_linear(c)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


# ----------------------------------------------------------------------------------------------------
# Terreno: alturas (export-relief) y colores (como TerrainBuilder + shared/Relief.material)
# ----------------------------------------------------------------------------------------------------
def load_relief(d):
    meta = json.load(open(os.path.join(d, "relief.json")))
    h = np.fromfile(os.path.join(d, "relief.f32"), np.float32).reshape(meta["NZ"], meta["NX"])
    return meta, h


def terrain_colors(meta, h, look, coast_inside):
    nz, nx = h.shape
    step = meta["Step"]
    rng = np.random.default_rng(3)
    # pendiente
    gz, gx = np.gradient(h, step)
    slope = np.sqrt(gx * gx + gz * gz)
    height = h + 1.0
    # manchas (como las de TerrainBuilder: tierra seca) y variación de verde
    n1 = BR.noise(nz, nx, 18, 11)
    n2 = BR.noise(nz, nx, 6, 12)
    grass = np.array(look["grass"], np.float32)
    leafy = np.array(look["leafy"], np.float32)
    rock = np.array(look["rock"], np.float32)
    sand = np.array(look["sand"], np.float32)
    groundc = np.array(look["ground"], np.float32)
    col = np.empty((nz, nx, 3), np.float32)
    col[:] = leafy if look["relief"] else grass
    # variación suave del césped
    col = col * (0.92 + 0.16 * n1[..., None])
    patches = (n2 > 0.72)
    col[patches] = col[patches] * 0.5 + groundc * 0.5
    if look["relief"]:
        hills = height > 2.5
        g = grass * (0.9 + 0.2 * n2[..., None])
        col[hills] = g[hills]
        mid = hills & (slope > 0.5)
        col[mid] = (col[mid] * 0.4 + groundc * 0.6)
        steep = slope > 0.85
        col[steep] = rock * (0.9 + 0.2 * n1[steep][..., None])
        high = height > 175
        col[high] = col[high] * 0.3 + rock * 0.7
    else:
        # las montañas de siempre: hierba y roca en la cumbre
        steep = slope > 1.0
        col[steep] = col[steep] * 0.5 + rock * 0.5
    # playa (70 studs desde la costa) y fondo del mar
    dist = cv2.distanceTransform(coast_inside.astype(np.uint8), cv2.DIST_L2, 5) * step
    beach = coast_inside & (dist < 70)
    col[beach] = sand
    col[~coast_inside] = sand * 0.85
    return np.clip(col, 0, 255) / 255.0


def grid_mesh(bpy, name, xs, zs, ys, cols, material):
    nz, nx = ys.shape
    gx, gz = np.meshgrid(xs, zs)
    verts = np.stack([gx.reshape(-1), -gz.reshape(-1), ys.reshape(-1)], 1).astype(np.float32)
    idx = np.arange(nx * nz).reshape(nz, nx)
    a, b, c, d = idx[:-1, :-1], idx[:-1, 1:], idx[1:, 1:], idx[1:, :-1]
    quads = np.stack([a, d, c, b], -1).reshape(-1, 4)
    mesh = bpy.data.meshes.new(name)
    mesh.vertices.add(len(verts))
    mesh.vertices.foreach_set("co", verts.reshape(-1))
    mesh.loops.add(quads.size)
    mesh.loops.foreach_set("vertex_index", quads.reshape(-1).astype(np.int32))
    mesh.polygons.add(len(quads))
    mesh.polygons.foreach_set("loop_start", np.arange(0, quads.size, 4, dtype=np.int32))
    mesh.polygons.foreach_set("loop_total", np.full(len(quads), 4, np.int32))
    mesh.update(calc_edges=True)
    if cols is not None:
        lc = BR.srgb_to_linear(cols.reshape(-1, 3) * 255.0)
        rgba = np.hstack([lc, np.ones((len(lc), 1), np.float32)])
        attr = mesh.attributes.new("tcol", "FLOAT_COLOR", "POINT")
        attr.data.foreach_set("color", rgba.reshape(-1))
    mesh.polygons.foreach_set("use_smooth", np.ones(len(quads), bool))
    obj = bpy.data.objects.new(name, mesh)
    obj.data.materials.append(material)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def terrain_material(bpy):
    m = bpy.data.materials.new("Terreno")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    a = nt.nodes.new("ShaderNodeAttribute")
    a.attribute_name = "tcol"
    # textura fina (hierba/roca a escala de unos studs): ruido que oscurece y aclara un poco
    tex = nt.nodes.new("ShaderNodeTexNoise")
    tex.inputs["Scale"].default_value = 0.08
    tex.inputs["Detail"].default_value = 6
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "OVERLAY"
    mix.inputs["Factor"].default_value = 0.25
    nt.links.new(a.outputs["Color"], mix.inputs["A"])
    nt.links.new(tex.outputs["Color"], mix.inputs["B"])
    nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.92
    bsdf.inputs["Specular IOR Level"].default_value = 0.2
    return m


def water_material(bpy, look):
    """Agua de Roblox (Terrain.WaterColor / WaterTransparency): superficie que refleja y deja ver el fondo;
    el color se lo da la absorción del volumen (bajíos turquesa, mar hondo azul oscuro)."""
    m = bpy.data.materials.new("Agua")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    out = nt.nodes["Material Output"]
    bsdf.inputs["Base Color"].default_value = (*lin(look["water"]), 1)
    bsdf.inputs["Roughness"].default_value = 0.06
    bsdf.inputs["IOR"].default_value = 1.33
    bsdf.inputs["Transmission Weight"].default_value = 1.0
    vol = nt.nodes.new("ShaderNodeVolumeAbsorption")
    wc = np.array(look["water"], np.float32) / 255.0
    absorb = np.clip(1.0 - wc, 0.05, 1.0)
    vol.inputs["Color"].default_value = (*np.clip(wc * 1.35, 0, 1), 1)
    vol.inputs["Density"].default_value = 0.012 * (1.0 - look["water_clear"]) / 0.4
    nt.links.new(vol.outputs[0], out.inputs["Volume"])
    _ = absorb
    return m


# ----------------------------------------------------------------------------------------------------
# Piezas de la ciudad (sin el estilo «ilustrado» del mapa grande: colores tal cual)
# ----------------------------------------------------------------------------------------------------
SKIP = {"Copa"}


def build_parts(parts, builder, sphere):
    sv, sf = sphere
    for p in parts:
        if p["name"] in SKIP:
            continue
        cs = p["corners"]
        ext = np.ptp(cs, 0)
        if ext.max() < 1.6:
            continue
        mat = p["mat"]
        col = lin(p["col"])
        rough = 0.15 if mat == "Glass" else 0.75
        if p["shape"] == "Ball":
            c = np.array(p["center"], np.float32)
            builder.add(sv * p["ball"] + c, sf, col, 0.0, rough)
            continue
        if p["shape"] in ("Cylinder", "Disc"):
            c = np.array(p["center"], np.float32)
            axis = np.array(p["axis"], np.float32)
            axis /= np.linalg.norm(axis) + 1e-9
            ref = np.array([0, 1, 0], np.float32) if abs(axis[1]) < 0.9 else np.array([1, 0, 0], np.float32)
            u = np.cross(axis, ref)
            u /= np.linalg.norm(u)
            w = np.cross(axis, u)
            k = 8
            ang = np.linspace(0, 2 * np.pi, k, endpoint=False)
            ring = (np.cos(ang)[:, None] * u + np.sin(ang)[:, None] * w) * p["radius"]
            half = axis * p["length"] / 2
            verts = np.vstack([c - half + ring, c + half + ring])
            faces = [(i, (i + 1) % k, k + (i + 1) % k, k + i) for i in range(k)]
            builder.add(verts, faces, col, 0.0, rough)
            continue
        faces = BR.BOX_FACES.copy()
        center = cs.mean(0)
        fc = cs[faces].mean(1)
        nrm = np.cross(cs[faces[:, 1]] - cs[faces[:, 0]], cs[faces[:, 2]] - cs[faces[:, 0]])
        flip = (nrm * (fc - center)).sum(1) < 0
        faces[flip] = faces[flip][:, ::-1]
        height = p["top"] - max(p["bottom"], 0)
        win = 0.0
        if height > 14 and mat in BR.WALL_MATS:
            unit = nrm / (np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-9)
            win = (np.abs(unit[:, 1]) < 0.3).astype(np.float32)
        builder.add(cs, faces, col, win, rough)


def forest(builder, path, sphere):
    sv, sf = sphere
    if not os.path.isfile(path):
        return 0
    n = 0
    for line in open(path):
        f = line.rstrip("\n").split("\t")
        if len(f) < 4:
            continue
        c = np.array([float(v) for v in f[1].split(",")], np.float32)
        s = np.array([float(v) for v in f[2].split(",")], np.float32)
        col = lin(tuple(int(v) for v in f[3].split(",")))
        if f[0] == "C":
            builder.add(sv * (s / 2) + c, sf, col, 0.0, 0.85)
            n += 1
        else:
            h, w = s[0], s[1]
            box = np.array([[x, y, z] for x in (-w / 2, w / 2) for y in (-h / 2, h / 2) for z in (-w / 2, w / 2)], np.float32) + c
            builder.add(box, BR.BOX_FACES.copy(), col, 0.0, 0.9)
    return n


# ----------------------------------------------------------------------------------------------------
# Cielo y nubes
# ----------------------------------------------------------------------------------------------------
def cube_to_equirect(face_dir, w=2048):
    """Las 6 caras del cielo propio (assets/paisaje) a una imagen equirrectangular para Blender."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("gen_cielo", os.path.join(HERE, "gen_cielo.py"))
    gc = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gc)
    h = w // 2
    lon = (np.arange(w) + 0.5) / w * 2 * np.pi - np.pi
    lat = np.pi / 2 - (np.arange(h) + 0.5) / h * np.pi
    lon, lat = np.meshgrid(lon, lat)
    # Blender: equirect con +X al centro, longitud hacia +Y. Dirección en Roblox: (x, y, z) = (bx, bz, -by)
    bx, by, bz = np.cos(lat) * np.cos(lon), np.cos(lat) * np.sin(lon), np.sin(lat)
    d = np.stack([bx, bz, -by], -1).astype(np.float32)
    return np.clip(gc.day_sky(d), 0, 1)


def world(bpy, look, sun_dir):
    w = bpy.data.worlds.new("Cielo")
    bpy.context.scene.world = w
    w.use_nodes = True
    nt = w.node_tree
    bg = nt.nodes["Background"]
    if look["sky"] == "propio":
        img = cube_to_equirect(None)
        path = os.path.join(bpy.app.tempdir or "/tmp", "cielo_propio.hdr")
        cv2.imwrite(path, (img[..., ::-1] ** 2.2).astype(np.float32))
        tex = nt.nodes.new("ShaderNodeTexEnvironment")
        tex.image = bpy.data.images.load(path)
        nt.links.new(tex.outputs["Color"], bg.inputs["Color"])
        bg.inputs["Strength"].default_value = 1.0
    else:
        sky = nt.nodes.new("ShaderNodeTexSky")
        sky.sky_type = "NISHITA"
        sky.sun_elevation = math.asin(sun_dir[2])
        sky.sun_rotation = math.atan2(sun_dir[1], sun_dir[0])
        sky.air_density = 2.2
        sky.dust_density = 4.0
        sky.sun_disc = False
        nt.links.new(sky.outputs["Color"], bg.inputs["Color"])
        bg.inputs["Strength"].default_value = 0.35


def clouds(bpy, look, rng, view):
    """Cúmulos (volumen con ruido), a 900-1300 studs de altura, como las nubes de Roblox (Clouds)."""
    m = bpy.data.materials.new("Nube")
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Color"].default_value = (1, 1, 1, 1)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 1.6
    noise.inputs["Detail"].default_value = 8
    coord = nt.nodes.new("ShaderNodeTexCoord")
    nt.links.new(coord.outputs["Object"], noise.inputs["Vector"])
    grad = nt.nodes.new("ShaderNodeTexGradient")
    grad.gradient_type = "SPHERICAL"
    nt.links.new(coord.outputs["Object"], grad.inputs["Vector"])
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    nt.links.new(noise.outputs["Fac"], mul.inputs[0])
    nt.links.new(grad.outputs["Fac"], mul.inputs[1])
    ramp = nt.nodes.new("ShaderNodeMapRange")
    ramp.inputs["From Min"].default_value = 0.16
    ramp.inputs["From Max"].default_value = 0.3
    ramp.inputs["To Max"].default_value = 0.02 * look["cloud_density"] / 0.52
    nt.links.new(mul.outputs[0], ramp.inputs["Value"])
    nt.links.new(ramp.outputs[0], vol.inputs["Density"])
    nt.links.new(vol.outputs[0], out.inputs["Volume"])
    ex, ey, ez = view["eye"]
    ax, ay, az = view["at"]
    dirx, dirz = ax - ex, az - ez
    L = math.hypot(dirx, dirz)
    dirx, dirz = dirx / L, dirz / L
    n = 0
    for _ in range(46):
        # repartidas delante de la cámara, de cerca hasta muy lejos
        dist = rng.uniform(1800, 16000)
        side = rng.uniform(-0.75, 0.75) * dist
        x = ex + dirx * dist - dirz * side
        z = ez + dirz * dist + dirx * side
        y = rng.uniform(950, 1350)
        size = rng.uniform(500, 1200)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1, location=(x, -z, y))
        o = bpy.context.active_object
        o.scale = (size, size * rng.uniform(0.7, 1.3), size * 0.42)
        o.data.materials.append(m)
        n += 1
    return n


# ----------------------------------------------------------------------------------------------------
def main():
    args = parse_args()
    import bpy

    t0 = time.time()
    look = LOOKS[args.look]
    view = VIEWS[args.view]
    rng = np.random.default_rng(5)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene

    # Terreno
    meta, h = load_relief(args.dir)
    nz, nx = h.shape
    xs = meta["MinX"] + np.arange(nx) * meta["Step"]
    zs = meta["MinZ"] + np.arange(nz) * meta["Step"]
    inside = h > -10
    if not look["relief"]:
        print("  (antes: sin relieve)")
    cols = terrain_colors(meta, h, look, inside)
    # fondo del mar: más hondo lejos de la costa (plataforma a -14, luego hasta -80)
    dsea = cv2.distanceTransform((~inside).astype(np.uint8), cv2.DIST_L2, 5) * meta["Step"]
    ys = np.where(inside, h, -14 - 66 * smooth(300, 2200, dsea))
    grid_mesh(bpy, "Terreno", xs, zs, ys, cols, terrain_material(bpy))
    # Más allá de la rejilla: fondo del mar hondo
    big = 60000
    bpy.ops.mesh.primitive_plane_add(size=big, location=(0, 0, -82))
    floor = bpy.context.active_object
    fm = bpy.data.materials.new("FondoHondo")
    fm.diffuse_color = (*lin((60, 70, 80)), 1)
    floor.data.materials.append(fm)
    # Agua: caja de -82 a -2 (superficie a Y = -2, como el agua del terreno)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, (-2 - 82) / 2 - 0.0))
    water = bpy.context.active_object
    water.scale = (big, big, 80)
    water.data.materials.append(water_material(bpy, look))

    # Piezas
    parts = BR.read_parts(os.path.join(args.dir, "parts.tsv"))
    builder = BR.MeshBuilder()
    sphere = BR.unit_sphere(1)
    build_parts(parts, builder, sphere)
    BR.make_mesh(bpy, "Piezas", builder, BR.parts_material(bpy), 1.0)
    del parts
    if look["forests"]:
        fb = BR.MeshBuilder()
        n = forest(fb, os.path.join(args.dir, "copas.tsv"), BR.unit_sphere(1))
        if n:
            BR.make_mesh(bpy, "Bosques", fb, BR.parts_material(bpy), 1.0)
        print(f"  {n} copas de bosque")

    # Sol (de la tarde, del suroeste, como a las 13-14 h) y cielo
    elev, az = math.radians(48), math.radians(215)
    sun_dir = (math.cos(elev) * math.cos(az), math.cos(elev) * math.sin(az), math.sin(elev))
    bpy.ops.object.light_add(type="SUN", rotation=(0, 0, 0))
    sun = bpy.context.active_object
    sun.data.energy = look["sun_strength"]
    sun.data.angle = math.radians(1.2)
    sun.data.color = (1.0, 0.96, 0.9)
    # apuntar el sol: su -Z hacia -sun_dir
    import mathutils
    sun.rotation_euler = mathutils.Vector(sun_dir).to_track_quat("Z", "Y").to_euler()
    world(bpy, look, sun_dir)
    clouds(bpy, look, rng, view)

    # Cámara
    ex, ey, ez = view["eye"]
    ax, ay, az_ = view["at"]
    bpy.ops.object.camera_add(location=(ex, -ez, ey))
    cam = bpy.context.active_object
    direction = mathutils.Vector((ax - ex, -(az_ - ez), ay - ey))
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    cam.data.lens_unit = "FOV"
    cam.data.angle = math.radians(view["fov"])
    cam.data.clip_start = 2
    cam.data.clip_end = 80000
    scene.camera = cam

    # Render
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.cycles.max_bounces = 4
    scene.cycles.volume_bounces = 1
    scene.cycles.volume_step_rate = 4.0
    scene.render.resolution_x = args.width
    scene.render.resolution_y = int(args.width * 852 / 1846)
    scene.view_settings.view_transform = "AgX" if "AgX" in [v.identifier for v in scene.view_settings.bl_rna.properties["view_transform"].enum_items] else "Filmic"
    scene.view_settings.exposure = look["exposure"]
    scene.view_layers[0].use_pass_mist = True
    scene.world.mist_settings.start = look["haze_start"]
    scene.world.mist_settings.depth = look["haze_depth"]
    scene.world.mist_settings.falloff = "QUADRATIC"
    # Compositor: la imagen (con la curva AgX/Filmic de Blender) y el pase de niebla, en PNG
    tmp = args.out + ".tmp"
    os.makedirs(tmp, exist_ok=True)
    scene.use_nodes = True
    nt = scene.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    rl = nt.nodes.new("CompositorNodeRLayers")
    comp = nt.nodes.new("CompositorNodeComposite")
    nt.links.new(rl.outputs["Image"], comp.inputs["Image"])
    fo = nt.nodes.new("CompositorNodeOutputFile")
    fo.base_path = tmp
    fo.format.file_format = "PNG"
    fo.format.color_depth = "16"
    fo.format.color_mode = "BW"
    fo.file_slots[0].path = "mist"
    nt.links.new(rl.outputs["Mist"], fo.inputs[0])
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = os.path.join(tmp, "color.png")
    print(f"  escena lista en {time.time() - t0:.0f} s; render {scene.render.resolution_x}x{scene.render.resolution_y}, {args.samples} muestras")
    bpy.ops.render.render(write_still=True)
    print(f"  render en {time.time() - t0:.0f} s")
    mist_files = sorted(f for f in os.listdir(tmp) if f.startswith("mist"))
    grade(os.path.join(tmp, "color.png"), os.path.join(tmp, mist_files[-1]), args.out, look)
    for f in os.listdir(tmp):
        os.remove(os.path.join(tmp, f))
    os.rmdir(tmp)
    print(f"✅ {args.out} ({time.time() - t0:.0f} s)")


def grade(color_path, mist_path, out, look):
    """Bruma (perspectiva aérea con el pase de niebla) y etalonaje (saturación y contraste del juego)."""
    srgb = cv2.imread(color_path, cv2.IMREAD_UNCHANGED)[..., :3][..., ::-1].astype(np.float32) / 255.0
    mist = cv2.imread(mist_path, cv2.IMREAD_UNCHANGED).astype(np.float32)
    mist = mist / (65535.0 if mist.max() > 255 else 255.0)
    if mist.ndim == 3:
        mist = mist[..., 0]
    haze = np.array(look["haze_color"], np.float32) / 255.0
    a = np.clip(mist, 0, 1)[..., None] * look["haze_strength"]
    srgb = srgb * (1 - a) + haze * a
    # saturación y contraste (ColorCorrection del juego)
    lum = (srgb * np.array([0.299, 0.587, 0.114], np.float32)).sum(-1, keepdims=True)
    srgb = lum + (srgb - lum) * look["saturation"]
    srgb = (srgb - 0.5) * look["contrast"] + 0.5
    # resplandor suave en lo muy claro (Bloom)
    bright = np.clip(srgb - 0.82, 0, 1)
    glow = cv2.GaussianBlur(bright, (0, 0), 18)
    srgb = srgb + glow * 0.6
    cv2.imwrite(out, (np.clip(srgb, 0, 1)[..., ::-1] * 255 + 0.5).astype(np.uint8))


if __name__ == "__main__":
    main()
