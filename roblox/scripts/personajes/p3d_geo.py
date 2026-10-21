"""Herramientas compartidas de los personajes 3D (scripts/personajes/personajes3d_blender.py).

Coordenadas: las de Blender, en studs de Roblox: X = derecha del personaje, Y = hacia donde mira (su
frente), Z = arriba; los pies en Z = 0. El FBX se exporta con axis_forward=-Z, axis_up=Y (como
scripts/invasion/alien_blender.py): en Roblox el personaje mira a -Z, su derecha es +X.

Las articulaciones son las del R15 de Roblox (scripts/lib/R15Rig.luau, raíz a 3 studs del suelo): la malla
se construye alrededor de ellas para que se doble justo donde se doblan las piezas del personaje.

Piezas:
    loft(...)          un tubo de anillos (superelipse) a lo largo de un camino: torso, mangas, perneras,
                       zapatos, mechones… con hueco delante (batas y rebecas abiertas) y tapas
    blob(...)          una esfera deformada (cabeza, nariz, ojos, orejas, moño…)
    rbox(...)          una caja redondeada (hebillas, aparatos, mochilas)
    materiales         procedurales para hornear: piel, tela (lisa, vaquera, punto), cuero, goma,
                       pelo, metal, cristal, brillo, ojo, boca
    uv_islands_scaled / pack_uv   UV de cada pieza en UN atlas, con más resolución en la cara
    bake(...)          color / normal / rugosidad / oclusión horneados al atlas (la malla ya junta; cada
                       pieza guarda sus coordenadas en el atributo p3d_local para sus dibujos)
    pesos(...)         pesos de huesos por pieza (cápsulas por hueso; reglas para faldones y la cara)
    esqueleto(...)     el esqueleto R15 (+ huesos de la cara) y el FBX
"""
import math
import os
import time

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree


def log(msg):
    print(f"[personajes3d {time.strftime('%H:%M:%S')}] {msg}", flush=True)


# ====================================================================== R15
# Articulaciones del R15 de bloques a escala 1 (scripts/lib/R15Rig.luau) en Blender: Roblox (x, y, z) ->
# Blender (x, -z, y). Raíz (HumanoidRootPart) en (0, 0, 3).
def rb(x, y, z):
    return Vector((x, -z, y))


R15_JOINTS = {  # hueso -> (punto de la articulación, padre)
    "HumanoidRootPart": (Vector((0, 0, 3.0)), "Root"),
    "LowerTorso": (Vector((0, 0, 2.0)), "HumanoidRootPart"),
    "UpperTorso": (Vector((0, 0, 2.4)), "LowerTorso"),
    "Head": (Vector((0, 0, 4.0)), "UpperTorso"),
    "RightUpperArm": (Vector((1.0, 0, 3.76)), "UpperTorso"),
    "RightLowerArm": (Vector((1.5, 0, 3.04)), "RightUpperArm"),
    "RightHand": (Vector((1.5, 0, 2.28)), "RightLowerArm"),
    "LeftUpperArm": (Vector((-1.0, 0, 3.76)), "UpperTorso"),
    "LeftLowerArm": (Vector((-1.5, 0, 3.04)), "LeftUpperArm"),
    "LeftHand": (Vector((-1.5, 0, 2.28)), "LeftLowerArm"),
    "RightUpperLeg": (Vector((0.5, 0, 2.0)), "LowerTorso"),
    "RightLowerLeg": (Vector((0.5, 0, 1.17)), "RightUpperLeg"),
    "RightFoot": (Vector((0.5, 0, 0.18)), "RightLowerLeg"),
    "LeftUpperLeg": (Vector((-0.5, 0, 2.0)), "LowerTorso"),
    "LeftLowerLeg": (Vector((-0.5, 0, 1.17)), "LeftUpperLeg"),
    "LeftFoot": (Vector((-0.5, 0, 0.18)), "LeftLowerLeg"),
}
R15_ORDER = ["HumanoidRootPart", "LowerTorso", "UpperTorso", "Head", "RightUpperArm", "RightLowerArm", "RightHand",
             "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperLeg", "RightLowerLeg", "RightFoot",
             "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"]
# Huesos de la cara (cuelgan de Head): la expresión se pone moviéndolos (una sola boca: la de la malla)
FACE_BONES = ["FaceJaw", "FaceMouthL", "FaceMouthR", "FaceBrowL", "FaceBrowR", "FaceLidL", "FaceLidR"]

# Cápsulas de cada hueso para los pesos: (desde, hasta, radio). Se ajustan por personaje (escala de
# grosor) en pesos().
CAPS = {
    "LowerTorso": ((0, 0, 1.9), (0, 0, 2.45), 0.72),
    "UpperTorso": ((0, 0, 2.45), (0, 0, 3.72), 0.86),
    "Head": ((0, 0, 4.12), (0, 0, 5.4), 0.62),
    "RightUpperArm": ((1.2, 0, 3.7), (1.5, 0, 3.04), 0.27),
    "RightLowerArm": ((1.5, 0, 3.04), (1.5, 0, 2.3), 0.24),
    "RightHand": ((1.5, 0, 2.26), (1.5, 0.04, 1.82), 0.17),
    "LeftUpperArm": ((-1.2, 0, 3.7), (-1.5, 0, 3.04), 0.27),
    "LeftLowerArm": ((-1.5, 0, 3.04), (-1.5, 0, 2.3), 0.24),
    "LeftHand": ((-1.5, 0, 2.26), (-1.5, 0.04, 1.82), 0.17),
    "RightUpperLeg": ((0.5, 0, 2.0), (0.5, 0, 1.17), 0.38),
    "RightLowerLeg": ((0.5, 0, 1.17), (0.5, 0, 0.24), 0.34),
    "RightFoot": ((0.5, -0.12, 0.12), (0.5, 0.36, 0.1), 0.17),
    "LeftUpperLeg": ((-0.5, 0, 2.0), (-0.5, 0, 1.17), 0.38),
    "LeftLowerLeg": ((-0.5, 0, 1.17), (-0.5, 0, 0.24), 0.34),
    "LeftFoot": ((-0.5, -0.12, 0.12), (-0.5, 0.36, 0.1), 0.17),
}

ALL_BODY = [b for b in R15_ORDER if b != "HumanoidRootPart"]
TORSO = ["LowerTorso", "UpperTorso"]
ARM_R = ["RightUpperArm", "RightLowerArm", "RightHand"]
ARM_L = ["LeftUpperArm", "LeftLowerArm", "LeftHand"]
LEG_R = ["RightUpperLeg", "RightLowerLeg", "RightFoot"]
LEG_L = ["LeftUpperLeg", "LeftLowerLeg", "LeftFoot"]


# ====================================================================== escena
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.objects):
        for x in list(block):
            try:
                block.remove(x)
            except Exception:
                pass


def coll():
    return bpy.context.scene.collection


def new_obj(name, me):
    o = bpy.data.objects.new(name, me)
    coll().objects.link(o)
    return o


def select_only(objs, active=None):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or objs[0]


def apply_mods(o):
    select_only([o])
    for m in list(o.modifiers):
        try:
            bpy.ops.object.modifier_apply(modifier=m.name)
        except Exception as e:  # (un modificador que no aplica: se quita)
            log(f"  aviso: {o.name}/{m.name}: {e}")
            o.modifiers.remove(m)


def subdivide(o, levels=1):
    if levels <= 0:
        return o
    m = o.modifiers.new("Sub", "SUBSURF")
    m.levels = levels
    m.render_levels = levels
    m.quality = 2
    apply_mods(o)
    return o


def smooth(o, auto=None):
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def tris(o):
    o.data.calc_loop_triangles()
    return len(o.data.loop_triangles)


def transform(o, fn):
    for v in o.data.vertices:
        v.co = fn(Vector(v.co))
    o.data.update()


def mirror_x(o, name):
    c = o.copy()
    c.data = o.data.copy()
    c.name = name
    coll().objects.link(c)
    me = c.data
    for v in me.vertices:
        v.co.x = -v.co.x
    me.flip_normals()
    me.update()
    for k, val in o.items():
        c[k] = val
    return c


# ====================================================================== loft
def _frame(t, ref=None):
    t = t.normalized()
    r = ref or Vector((1, 0, 0))
    if abs(t.dot(r)) > 0.92:
        r = Vector((0, 0, 1)) if abs(t.z) < 0.92 else Vector((0, 1, 0))
    u = (r - t * r.dot(t)).normalized()
    v = t.cross(u).normalized()
    return u, v


def loft(name, rings, segs=16, cap0=True, cap1=True, gap=None, ref=None, closed_path=False):
    """rings: lista de dicts {c: centro (Vector), rx, ry (semiejes en u/v), sq (2 = elipse, más = más
    cuadrado), dx/dy (desplazamientos opcionales en u/v), u/v (ejes forzados), fold: f(theta)->escala}.
    gap: (dirección (Vector), semiancho en radianes, opcional f(i)->semiancho por anillo): sin caras en ese
    lado (abierto). Devuelve el objeto (sin subdividir)."""
    bm = bmesh.new()
    n = len(rings)
    cs = [Vector(r["c"]) for r in rings]
    grid = []
    for i, r in enumerate(rings):
        if closed_path:
            t = cs[(i + 1) % n] - cs[(i - 1) % n]
        elif i == 0:
            t = cs[1] - cs[0]
        elif i == n - 1:
            t = cs[-1] - cs[-2]
        else:
            t = cs[i + 1] - cs[i - 1]
        u, v = _frame(t, r.get("ref", ref))
        if "u" in r:
            u = Vector(r["u"]).normalized()
            v = t.normalized().cross(u).normalized()
        sq = r.get("sq", 2.0)
        e = 2.0 / sq
        row = []
        # con hueco: los vértices del anillo se reparten SOLO por la parte cerrada (borde limpio, sin
        # escalones); el hueco de cada anillo es la media de los de las caras de encima y de debajo
        hr = 0.0
        if gap:
            if len(gap) > 2 and gap[2] is not None:
                a0 = gap[2](i - 1) if i > 0 else gap[2](i)
                a1 = gap[2](i) if i < n - 1 else a0
                hr = max(0.0, (a0 + a1) / 2)
            else:
                hr = gap[1]
            dg = Vector(gap[0]).normalized()
            thf = math.atan2(dg.dot(v), dg.dot(u))
        for k in range(segs):
            if gap:
                th = thf + hr + (2 * math.pi - 2 * hr) * k / (segs - 1)
            else:
                th = 2 * math.pi * k / segs
            ct, st = math.cos(th), math.sin(th)
            x = math.copysign(abs(ct) ** e, ct)
            y = math.copysign(abs(st) ** e, st)
            f = r["fold"](th) if "fold" in r else 1.0
            p = cs[i] + u * (r["rx"] * x * f + r.get("dx", 0.0)) + v * (r["ry"] * y * f + r.get("dy", 0.0))
            row.append(bm.verts.new(p))
        grid.append((row, u, v))
    bm.verts.ensure_lookup_table()

    last = n if closed_path else n - 1
    for i in range(last):
        a, b = grid[i][0], grid[(i + 1) % n][0]
        for k in range(segs - 1 if gap else segs):
            k2 = (k + 1) % segs
            bm.faces.new((a[k], a[k2], b[k2], b[k]))
    if not closed_path:
        for idx, flip in ((0, True), (n - 1, False)):
            if (idx == 0 and not cap0) or (idx == n - 1 and not cap1):
                continue
            row = grid[idx][0]
            if gap:
                continue  # (abierto: sin tapas)
            ctr = bm.verts.new(cs[idx])
            for k in range(segs):
                k2 = (k + 1) % segs
                f = (ctr, row[k2], row[k]) if not flip else (ctr, row[k], row[k2])
                bm.faces.new(f)
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = new_obj(name, me)
    return o


def path_rings(pts, radii, sq=2.0, ry=None, **extra):
    """Anillos para loft a lo largo de unos puntos con radio (o (rx, ry)) por punto."""
    out = []
    for i, p in enumerate(pts):
        r = radii[i]
        rx, ry_ = (r if isinstance(r, (tuple, list)) else (r, r if ry is None else ry[i]))
        d = {"c": Vector(p), "rx": rx, "ry": ry_, "sq": sq if not isinstance(sq, (list, tuple)) else sq[i]}
        d.update(extra)
        out.append(d)
    return out


def bezier(p0, p1, p2, n):
    p0, p1, p2 = Vector(p0), Vector(p1), Vector(p2)
    return [(1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t ** 2 * p2 for t in [i / (n - 1) for i in range(n)]]


# ====================================================================== esferas y cajas
def blob(name, center, radii, segs=24, rings=14, deform=None):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=rings, radius=1.0)
    for v in bm.verts:
        p = Vector(v.co)
        if deform:
            p = deform(p)
        v.co = Vector((p.x * radii[0], p.y * radii[1], p.z * radii[2])) + Vector(center)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return new_obj(name, me)


def rbox(name, center, size, bevel=0.04, segs=2, rot=None):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = new_obj(name, me)
    if bevel > 0:
        m = o.modifiers.new("Bisel", "BEVEL")
        m.width = min(bevel, min(size) * 0.45)
        m.segments = segs
        m.limit_method = "NONE"
        apply_mods(o)
    if rot is not None:
        transform(o, lambda p: rot @ p)
    transform(o, lambda p: p + Vector(center))
    return o


def cyl(name, p0, p1, r, segs=12, caps=True, sq=2.0):
    return loft(name, [{"c": Vector(p0), "rx": r, "ry": r, "sq": sq}, {"c": Vector(p1), "rx": r, "ry": r, "sq": sq}], segs, caps, caps)


def torus(name, center, axis, R, r, segs=24, tsegs=8, sx=1.0, sy=1.0):
    """Anillo (aro de gafas, cinturón): R radio mayor (en el plano perpendicular a axis), r del tubo."""
    axis = Vector(axis).normalized()
    u, v = _frame(axis)
    pts = [Vector(center) + (u * math.cos(a) * sx + v * math.sin(a) * sy) * R for a in [2 * math.pi * i / segs for i in range(segs)]]
    return loft(name, path_rings(pts, [r] * segs), tsegs, closed_path=True)


# ====================================================================== superficie
class Surface:
    """Para poner cosas sobre una malla (la cabeza): rayos desde fuera."""

    def __init__(self, obj):
        bpy.context.view_layer.update()
        mw = obj.matrix_world
        verts = [mw @ v.co for v in obj.data.vertices]
        polys = [tuple(p.vertices) for p in obj.data.polygons]
        self.bvh = BVHTree.FromPolygons(verts, polys)  # (en coordenadas del mundo)

    def hit(self, origin, direction):
        loc, nor, idx, dist = self.bvh.ray_cast(Vector(origin), Vector(direction).normalized())
        return (loc, nor) if loc is not None else (None, None)

    def front(self, x, z, y0=5.0):
        return self.hit((x, y0, z), (0, -1, 0))


# ====================================================================== materiales
LOCAL_ATTR = "p3d_local"


def store_local(o):
    """Guarda en cada vértice su posición en la pieza (para los materiales: ver NodeKit.coord)."""
    me = o.data
    at = me.attributes.get(LOCAL_ATTR) or me.attributes.new(LOCAL_ATTR, "FLOAT_VECTOR", "POINT")
    at.data.foreach_set("vector", [c for v in me.vertices for c in v.co])


class NodeKit:
    def __init__(self, nt):
        self.nt = nt
        self.x = 0

    def new(self, kind, **props):
        n = self.nt.nodes.new(kind)
        n.location = (self.x, 0)
        self.x -= 200
        for k, v in props.items():
            setattr(n, k, v)
        return n

    def link(self, a, b):
        self.nt.links.new(a, b)

    def math(self, op, a, b=0.0, clamp=False):
        n = self.new("ShaderNodeMath", operation=op)
        n.use_clamp = clamp
        for i, val in enumerate((a, b)):
            if hasattr(val, "is_output") or hasattr(val, "links"):
                self.link(val, n.inputs[i])
            else:
                n.inputs[i].default_value = val
        return n.outputs[0]

    def mix(self, fac, a, b):
        n = self.new("ShaderNodeMix", data_type="RGBA")
        for sock, val in ((n.inputs[0], fac), (n.inputs[6], a), (n.inputs[7], b)):
            if hasattr(val, "is_output") or hasattr(val, "links"):
                self.link(val, sock)
            else:
                sock.default_value = val if not isinstance(val, tuple) or len(val) == 4 else (*val, 1.0)
        return n.outputs[2]

    def ramp(self, fac, lo, hi):
        mr = self.new("ShaderNodeMapRange")
        self.link(fac, mr.inputs["Value"])
        mr.inputs["From Min"].default_value = lo
        mr.inputs["From Max"].default_value = hi
        return mr.outputs["Result"]

    def coord(self, kind="Object", scale=1.0):
        if kind == "Object":
            # las coordenadas de cada pieza antes de juntarlas (atributo guardado por store_local): así se
            # hornea UNA malla ya junta con los dibujos de cada pieza en su sitio
            at = self.new("ShaderNodeAttribute")
            at.attribute_name = LOCAL_ATTR
            out = at.outputs["Vector"]
        else:
            tc = self.new("ShaderNodeTexCoord")
            out = tc.outputs[kind]
        if scale != 1.0:
            vm = self.new("ShaderNodeVectorMath", operation="SCALE")
            self.link(out, vm.inputs[0])
            vm.inputs["Scale"].default_value = scale
            out = vm.outputs[0]
        return out

    def noise(self, vec, scale, detail=4.0, rough=0.5):
        n = self.new("ShaderNodeTexNoise")
        self.link(vec, n.inputs["Vector"])
        n.inputs["Scale"].default_value = scale
        n.inputs["Detail"].default_value = detail
        n.inputs["Roughness"].default_value = rough
        return n.outputs["Fac"]

    def wave(self, vec, scale, kind="BANDS", direction="X", distortion=0.0, profile="SIN", detail=0.0):
        n = self.new("ShaderNodeTexWave")
        n.wave_type = kind
        if kind == "BANDS":
            n.bands_direction = direction
        else:
            n.rings_direction = direction
        n.wave_profile = profile
        self.link(vec, n.inputs["Vector"])
        n.inputs["Scale"].default_value = scale
        n.inputs["Distortion"].default_value = distortion
        n.inputs["Detail"].default_value = detail
        return n.outputs["Fac"]

    def sep(self, vec):
        n = self.new("ShaderNodeSeparateXYZ")
        self.link(vec, n.inputs[0])
        return n.outputs

    def length(self, vec):
        n = self.new("ShaderNodeVectorMath", operation="LENGTH")
        self.link(vec, n.inputs[0])
        return n.outputs["Value"]

    def vsub(self, vec, c):
        n = self.new("ShaderNodeVectorMath", operation="SUBTRACT")
        self.link(vec, n.inputs[0])
        n.inputs[1].default_value = c
        return n.outputs[0]

    def vmul(self, vec, s):
        n = self.new("ShaderNodeVectorMath", operation="MULTIPLY")
        self.link(vec, n.inputs[0])
        n.inputs[1].default_value = s
        return n.outputs[0]

    def spot(self, vec, center, radius, soft=0.5):
        """1 dentro de una esfera (centro, radio) que se difumina hacia fuera."""
        d = self.length(self.vsub(vec, center))
        return self.ramp(d, radius, radius * (1 - soft))


def _base(name):
    mat = bpy.data.materials.get(name)
    if mat:
        bpy.data.materials.remove(mat)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    K = NodeKit(nt)
    out = K.new("ShaderNodeOutputMaterial")
    bsdf = K.new("ShaderNodeBsdfPrincipled")
    bsdf.name = "BSDF"
    K.link(bsdf.outputs[0], out.inputs["Surface"])
    bake = K.new("ShaderNodeTexImage")
    bake.name = "BakeTarget"
    nt.nodes.active = bake
    return mat, K, bsdf


def _rgba(c):
    return (*c, 1.0) if len(c) == 3 else c


def lin(c255):
    """sRGB 0..255 -> lineal (los colores de Cast)."""
    def f(x):
        x = x / 255.0
        return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4
    return tuple(f(x) for x in c255)


def shade(c, k):
    return tuple(max(0.0, min(1.0, x * k)) for x in c)


def _finish(mat, K, bsdf, color, rough, height=None, bump=0.4, dist=0.01, metal=0.0, emission=None):
    K.link(color, bsdf.inputs["Base Color"]) if not isinstance(color, tuple) else setattr(bsdf.inputs["Base Color"], "default_value", _rgba(color))
    if hasattr(rough, "is_output"):
        K.link(rough, bsdf.inputs["Roughness"])
    else:
        bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if height is not None:
        b = K.new("ShaderNodeBump")
        b.inputs["Strength"].default_value = bump
        b.inputs["Distance"].default_value = dist
        K.link(height, b.inputs["Height"])
        K.link(b.outputs["Normal"], bsdf.inputs["Normal"])
    if emission:
        bsdf.inputs["Emission Color"].default_value = _rgba(emission[0])
        bsdf.inputs["Emission Strength"].default_value = emission[1]
    mat["metal"] = metal
    return mat


def mat_skin(name, color, blush=None, freckles=False, wrinkles=0.0, stubble=None, head=None):
    """Piel: tono con variación suave, colorete (blush: lista de (centro, radio) en coordenadas del
    objeto), pecas, arrugas (mayores) y barba de tres días (stubble: (color, z_max, y_min))."""
    mat, K, bsdf = _base(name)
    P = K.coord("Object")
    n = K.noise(P, 6.0, 3.0)
    c0 = color
    col = K.mix(K.math("MULTIPLY", n, 0.35), c0, shade(c0, 0.9))
    if blush:
        warm = (min(1, c0[0] * 1.08 + 0.03), c0[1] * 0.78, c0[2] * 0.78)
        for ctr, rad in blush:
            col = K.mix(K.math("MULTIPLY", K.spot(P, ctr, rad, 0.9), 0.55), col, warm)
    if freckles:
        v = K.new("ShaderNodeTexVoronoi")
        K.link(P, v.inputs["Vector"])
        v.inputs["Scale"].default_value = 38.0
        dots = K.ramp(v.outputs["Distance"], 0.16, 0.06)
        mask = K.spot(P, (0, 0.62, 0.08), 0.42, 0.6) if head is None else K.spot(P, head[0], head[1], 0.6)
        col = K.mix(K.math("MULTIPLY", K.math("MULTIPLY", dots, mask), 0.5), col, shade(c0, 0.62))
    height = K.math("MULTIPLY", K.noise(P, 40.0, 2.0), 0.15)
    if wrinkles > 0:
        S = K.sep(P)
        # líneas de la frente (bandas horizontales arriba y delante)
        bands = K.wave(P, 9.0, "BANDS", "Z", 1.5, "SIN")
        lines = K.ramp(bands, 0.9, 1.0)
        fore = K.math("MULTIPLY", K.ramp(S[2], 0.18, 0.32), K.ramp(S[1], 0.35, 0.6))
        fore = K.math("MULTIPLY", fore, K.ramp(S[2], 0.5, 0.4))
        w = K.math("MULTIPLY", K.math("MULTIPLY", lines, fore), wrinkles)
        col = K.mix(K.math("MULTIPLY", w, 0.45), col, shade(c0, 0.72))
        height = K.math("SUBTRACT", height, K.math("MULTIPLY", w, 0.8))
    if stubble:
        st_col, zmax, ymin = stubble
        S = K.sep(P)
        v = K.new("ShaderNodeTexVoronoi")
        K.link(P, v.inputs["Vector"])
        v.inputs["Scale"].default_value = 120.0
        dots = K.ramp(v.outputs["Distance"], 0.35, 0.1)
        region = K.math("MULTIPLY", K.ramp(S[2], zmax, zmax - 0.12), K.ramp(S[1], ymin, ymin + 0.15))
        amt = K.math("MULTIPLY", K.math("ADD", K.math("MULTIPLY", dots, 0.5), 0.35), region)
        col = K.mix(K.math("MULTIPLY", amt, 0.75), col, st_col)
    rough = K.math("ADD", 0.48, K.math("MULTIPLY", n, 0.1))
    return _finish(mat, K, bsdf, col, rough, height, 0.25, 0.004)


def mat_cloth(name, color, kind="plain", scale=1.0, alt=None, stripes=None, dirt=0.0, rough=0.8):
    """Tela: plain (algodón), twill (vaquero), knit (punto de rebeca), canvas (bata/cargo), satin.
    stripes: (color, eje "X"/"Z", escala, ancho) rayas o cuadros; dirt: manchas suaves (la bata)."""
    mat, K, bsdf = _base(name)
    P = K.coord("Object", scale)
    n = K.noise(P, 3.5, 4.0, 0.55)
    col = K.mix(K.math("MULTIPLY", n, 0.28), color, shade(color, 0.86))
    if kind == "twill":
        wv = K.wave(K.coord("Object", scale), 70.0, "BANDS", "DIAGONAL", 0.0)
        height = K.math("MULTIPLY", wv, 0.5)
        col = K.mix(K.math("MULTIPLY", wv, 0.18), col, shade(color, 1.25))
        fade = K.ramp(K.noise(P, 1.6, 2.0), 0.45, 0.75)
        col = K.mix(K.math("MULTIPLY", fade, 0.35), col, shade(color, 1.35))
    elif kind == "knit":
        a = K.wave(P, 26.0, "BANDS", "X", 0.0, "SIN")
        b = K.wave(P, 60.0, "BANDS", "Z", 0.0, "SAW")
        rib = K.math("MULTIPLY", a, K.math("ADD", 0.6, K.math("MULTIPLY", b, 0.4)))
        height = K.math("MULTIPLY", rib, 0.8)
        col = K.mix(K.math("MULTIPLY", rib, 0.22), shade(color, 0.92), shade(color, 1.12))
    elif kind == "canvas":
        a = K.wave(P, 90.0, "BANDS", "X", 0.0)
        b = K.wave(P, 90.0, "BANDS", "Z", 0.0)
        height = K.math("MULTIPLY", K.math("ADD", a, b), 0.25)
    elif kind == "satin":
        height = K.math("MULTIPLY", n, 0.1)
        rough = 0.42
    else:
        a = K.wave(P, 120.0, "BANDS", "X", 0.0)
        b = K.wave(P, 120.0, "BANDS", "Z", 0.0)
        height = K.math("MULTIPLY", K.math("ADD", a, b), 0.18)
    if stripes:
        sc, axis, ssc, width = stripes[:4]
        w = K.wave(K.coord("Object"), ssc, "BANDS", axis, 0.0, "TRI")
        m = K.ramp(w, 1 - width, 1 - width + 0.04)
        col = K.mix(m, col, sc)
        if len(stripes) > 4:  # cuadros: la otra dirección
            w2 = K.wave(K.coord("Object"), ssc, "BANDS", stripes[4], 0.0, "TRI")
            m2 = K.ramp(w2, 1 - width, 1 - width + 0.04)
            col = K.mix(K.math("MULTIPLY", m2, 0.6), col, sc)
    if dirt > 0:
        d = K.ramp(K.noise(K.coord("Object"), 2.2, 6.0, 0.6), 0.58, 0.72)
        col = K.mix(K.math("MULTIPLY", d, dirt), col, (0.55, 0.5, 0.42))
    r = K.math("ADD", rough, K.math("MULTIPLY", n, 0.08))
    return _finish(mat, K, bsdf, col, r, height, 0.35, 0.006)


def mat_plain(name, color, rough=0.5, metal=0.0, bump_scale=0.0, emission=None, noise=0.15):
    mat, K, bsdf = _base(name)
    P = K.coord("Object")
    n = K.noise(P, 8.0, 3.0)
    col = K.mix(K.math("MULTIPLY", n, noise), color, shade(color, 0.82))
    height = K.math("MULTIPLY", K.noise(P, 30.0, 2.0), bump_scale) if bump_scale > 0 else None
    return _finish(mat, K, bsdf, col, K.math("ADD", rough, K.math("MULTIPLY", n, 0.08)), height, 0.3, 0.004, metal, emission)


def mat_hair(name, color, axis="Z", scale=1.0):
    """Pelo: mechones (bandas finas en la dirección del pelo), raíz más oscura, brillo."""
    mat, K, bsdf = _base(name)
    P = K.coord("Object", scale)
    w = K.wave(P, 38.0, "BANDS", "X" if axis == "Z" else "Z", 6.0, "SIN", 2.0)
    n = K.noise(P, 5.0, 4.0)
    col = K.mix(K.math("MULTIPLY", w, 0.42), shade(color, 0.72), shade(color, 1.12))
    col = K.mix(K.math("MULTIPLY", n, 0.3), col, shade(color, 0.85))
    height = K.math("MULTIPLY", w, 0.9)
    rough = K.math("ADD", 0.42, K.math("MULTIPLY", w, 0.15))
    return _finish(mat, K, bsdf, col, rough, height, 0.45, 0.01)


def mat_eye(name, iris, sclera=(0.92, 0.9, 0.86), pupil=(0.02, 0.02, 0.025), iris_r=0.52, pupil_r=0.24, glow=False):
    """Ojo: el globo mira a +Y (coordenadas del objeto, centro en el origen). Iris con degradado,
    pupila y un brillo arriba a la izquierda (horneado: queda vivo en Roblox sin reflejos)."""
    mat, K, bsdf = _base(name)
    P = K.coord("Object")
    vm = K.new("ShaderNodeVectorMath", operation="NORMALIZE")
    K.link(P, vm.inputs[0])
    S = K.sep(vm.outputs[0])
    # distancia angular al eje +Y ≈ sqrt(x² + z²) en la esfera unidad (delante)
    xz = K.math("SQRT", K.math("ADD", K.math("MULTIPLY", S[0], S[0]), K.math("MULTIPLY", S[2], S[2])))
    front = K.ramp(S[1], 0.0, 0.2)
    iris_m = K.math("MULTIPLY", K.ramp(xz, iris_r, iris_r - 0.04), front)
    pup_m = K.math("MULTIPLY", K.ramp(xz, pupil_r, pupil_r - 0.04), front)
    ring = K.ramp(xz, iris_r * 0.55, iris_r)
    iris_col = K.mix(ring, shade(iris, 1.35), shade(iris, 0.55))
    col = K.mix(iris_m, sclera, iris_col)
    col = K.mix(pup_m, col, pupil)
    # brillo
    hl = K.spot(vm.outputs[0], (-0.22, 0.95, 0.24), 0.13, 0.3)
    col = K.mix(K.math("MULTIPLY", hl, front), col, (1.0, 1.0, 1.0))
    # la parte de arriba algo sombreada (párpado)
    col = K.mix(K.math("MULTIPLY", K.ramp(S[2], 0.35, 0.9), 0.35), col, shade(sclera, 0.55))
    return _finish(mat, K, bsdf, col, 0.15, None, emission=((0.6, 0.9, 1.0), 2.0) if glow else None)


def mat_mouth(name, lip=None):
    """Boca (el hueco): oscura, lengua abajo. Coordenadas del objeto: el centro de la boca en el origen."""
    mat, K, bsdf = _base(name)
    P = K.coord("Object")
    S = K.sep(P)
    dark = (0.09, 0.025, 0.03)
    tongue = (0.55, 0.16, 0.18)
    col = K.mix(K.ramp(S[2], -0.012, -0.03), dark, tongue)
    if lip:
        col = K.mix(K.math("MULTIPLY", K.ramp(S[1], -0.004, 0.012), 0.0), col, lip)
    return _finish(mat, K, bsdf, col, 0.55)


def mat_glow(name, color, strength=3.0, pattern=False):
    """Pantallas, cristales y tubos que brillan (en Roblox: el color claro horneado)."""
    mat, K, bsdf = _base(name)
    P = K.coord("Object")
    col = color
    if pattern:
        w = K.wave(P, 30.0, "BANDS", "Z", 0.0, "SAW")
        col = K.mix(K.math("MULTIPLY", K.ramp(w, 0.85, 1.0), 0.6), color, shade(color, 1.5))
    return _finish(mat, K, bsdf, col, 0.2, None, emission=(color, strength))


def mat_metal(name, color, rough=0.32, scratches=True):
    mat, K, bsdf = _base(name)
    P = K.coord("Object")
    n = K.noise(P, 4.0, 5.0, 0.6)
    col = K.mix(K.math("MULTIPLY", n, 0.25), color, shade(color, 0.8))
    r = K.math("ADD", rough, K.math("MULTIPLY", n, 0.12))
    height = None
    if scratches:
        s = K.ramp(K.noise(K.coord("Object", 3.0), 30.0, 2.0, 0.3), 0.62, 0.68)
        r = K.math("SUBTRACT", r, K.math("MULTIPLY", s, 0.15))
        height = K.math("MULTIPLY", s, 0.2)
    return _finish(mat, K, bsdf, col, r, height, 0.2, 0.003, metal=0.9)


def mat_leather(name, color, rough=0.45):
    mat, K, bsdf = _base(name)
    P = K.coord("Object")
    v = K.new("ShaderNodeTexVoronoi")
    K.link(P, v.inputs["Vector"])
    v.inputs["Scale"].default_value = 60.0
    n = K.noise(P, 3.0, 4.0)
    col = K.mix(K.math("MULTIPLY", n, 0.35), color, shade(color, 1.3))
    height = K.math("MULTIPLY", v.outputs["Distance"], 0.4)
    return _finish(mat, K, bsdf, col, K.math("ADD", rough, K.math("MULTIPLY", n, 0.15)), height, 0.25, 0.004)


def assign(o, mat):
    o.data.materials.clear()
    o.data.materials.append(mat)
    return o


# ====================================================================== UV: atlas con más resolución en la cara
def uv_islands_scaled(objs):
    """UV de cada pieza (smart project) con la escala de su resolución: la propiedad «texel» (1 por
    defecto; la cara ×3). Luego, ya juntas, pack_uv las coloca en el atlas sin cambiar esa proporción."""
    for o in objs:
        select_only([o])
        if not o.data.uv_layers:
            o.data.uv_layers.new(name="UVMap")
        o.data.uv_layers[0].name = "UVMap"
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(58), island_margin=0.02, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
        bpy.ops.object.mode_set(mode="OBJECT")
        me = o.data
        uv = me.uv_layers[0].data
        a3 = 0.0
        auv = 0.0
        for p in me.polygons:
            a3 += p.area
            pts = [uv[i].uv for i in p.loop_indices]
            s_ = 0.0
            for k in range(len(pts)):
                x0, y0 = pts[k]
                x1, y1 = pts[(k + 1) % len(pts)]
                s_ += x0 * y1 - x1 * y0
            auv += abs(s_) / 2
        f = math.sqrt(max(a3, 1e-8) * o.get("texel", 1.0) / max(auv, 1e-8))
        for d in uv:
            d.uv = (d.uv[0] * f, d.uv[1] * f)


def pack_uv(o, margin=0.009):
    select_only([o])
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.context.scene.tool_settings.use_uv_select_sync = True
    try:
        bpy.ops.uv.pack_islands(rotate=True, scale=True, margin=margin, shape_method="CONCAVE")
    except TypeError:
        bpy.ops.uv.pack_islands(rotate=True, margin=margin)
    bpy.ops.object.mode_set(mode="OBJECT")


# ====================================================================== horneado
def bake(objs, name, size, out_dir, samples_ao=24):
    """Hornea al atlas color, normal, rugosidad y oclusión (que se multiplica en el color: más volumen
    en Roblox). Devuelve {mapa: ruta}."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.render.bake.margin = 3
    mats = {m for o in objs for m in o.data.materials if m}
    imgs = {}
    paths = {}
    for kind in ("color", "normal", "rugosidad", "ao", "emit"):
        img = bpy.data.images.new(f"{name}_{kind}", size, size, alpha=False, float_buffer=False)
        img.colorspace_settings.name = "sRGB" if kind in ("color", "emit") else "Non-Color"
        for m in mats:
            node = m.node_tree.nodes.get("BakeTarget")
            node.image = img
            m.node_tree.nodes.active = node
        select_only(objs)
        t0 = time.time()
        if kind == "color":
            scene.cycles.samples = 1
            bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_clear=True, margin=3)
        elif kind == "normal":
            scene.cycles.samples = 1
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT", use_clear=True, margin=3)
        elif kind == "rugosidad":
            scene.cycles.samples = 1
            bpy.ops.object.bake(type="ROUGHNESS", use_clear=True, margin=3)
        elif kind == "emit":
            scene.cycles.samples = 1
            bpy.ops.object.bake(type="EMIT", use_clear=True, margin=3)
        else:
            scene.cycles.samples = samples_ao
            scene.world = scene.world or bpy.data.worlds.new("w")
            scene.world.light_settings.distance = 0.45
            bpy.ops.object.bake(type="AO", use_clear=True, margin=3)
        imgs[kind] = img
        log(f"  horneado {name}_{kind} ({size}px) en {time.time() - t0:.1f}s")
    # color final = color × (oclusión suavizada) + brillo
    import numpy as np

    def arr(img):
        a = np.array(img.pixels[:], dtype=np.float32).reshape(size, size, 4)
        return a

    col = arr(imgs["color"])
    ao = arr(imgs["ao"])[:, :, :1]
    emit = arr(imgs["emit"])[:, :, :3]
    aok = 0.62 + 0.38 * np.clip(ao, 0, 1)
    out = col.copy()
    out[:, :, :3] = np.clip(col[:, :, :3] * aok + emit * 0.35, 0, 1)
    imgs["color"].pixels.foreach_set(out.ravel())
    for kind in ("color", "normal", "rugosidad"):
        img = imgs[kind]
        path = os.path.join(out_dir, f"{name}_{kind}.png")
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
        paths[kind] = path
    for kind in ("ao", "emit"):
        bpy.data.images.remove(imgs[kind])
    # (máscara de brillo: dónde la pieza emite, para el render de vista previa)
    return paths


def pbr_material(name, paths, emit_path=None):
    mat = bpy.data.materials.new("PBR_" + name)
    mat.use_nodes = True
    nt = mat.node_tree
    b = nt.nodes.get("Principled BSDF")

    def tex(kind, color=False):
        n = nt.nodes.new("ShaderNodeTexImage")
        n.image = bpy.data.images.load(paths[kind], check_existing=False)
        n.image.colorspace_settings.name = "sRGB" if color else "Non-Color"
        return n

    nt.links.new(tex("color", True).outputs["Color"], b.inputs["Base Color"])
    nt.links.new(tex("rugosidad").outputs["Color"], b.inputs["Roughness"])
    b.inputs["Metallic"].default_value = 0.0
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(tex("normal").outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return mat


# ====================================================================== pesos
def _seg_dist(p, a, b):
    a, b = Vector(a), Vector(b)
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.dot(ab), 1e-9)))
    return (p - (a + ab * t)).length, t


def weights_for(p, bones, caps, falloff=0.07):
    ds = []
    for b in bones:
        a, c, r = caps[b]
        d, _ = _seg_dist(p, a, c)
        ds.append((d - r, b))
    ds.sort()
    best = ds[0][0]
    ws = [(math.exp(-(d - best) / falloff), b) for d, b in ds[:4]]
    tot = sum(w for w, _ in ws)
    return [(b, w / tot) for w, b in ws if w / tot > 0.02]


def set_weights(o, rule, caps):
    """rule: ("rigid", hueso) | ("auto", [huesos], falloff) | ("skirt",) | ("fn", f(p)->[(hueso, peso)])."""
    groups = {}

    def g(name):
        if name not in groups:
            groups[name] = o.vertex_groups.get(name) or o.vertex_groups.new(name=name)
        return groups[name]

    kind = rule[0]
    for v in o.data.vertices:
        p = o.matrix_world @ v.co
        if kind == "rigid":
            ws = [(rule[1], 1.0)]
        elif kind == "auto":
            ws = weights_for(p, rule[1], caps, rule[2] if len(rule) > 2 else 0.07)
        elif kind == "skirt":
            # faldón de bata o abrigo: arriba con la cadera; abajo sigue a medias a la pierna de su lado
            t = max(0.0, min(1.0, (2.15 - p.z) / 1.1))
            side = max(0.0, min(1.0, (p.x + 0.35) / 0.7))
            side = side * side * (3 - 2 * side)
            k = 0.62 * t
            low = max(0.0, min(1.0, (1.35 - p.z) / 0.5)) * 0.25
            ws = [("LowerTorso", 1 - k), ("RightUpperLeg", k * side * (1 - low)), ("LeftUpperLeg", k * (1 - side) * (1 - low)),
                  ("RightLowerLeg", k * side * low), ("LeftLowerLeg", k * (1 - side) * low)]
        else:
            ws = rule[1](p)
        ws = [(b, w) for b, w in ws if w > 1e-3]
        ws.sort(key=lambda r: -r[1])
        ws = ws[:4]
        tot = sum(w for _, w in ws) or 1.0
        for b, w in ws:
            g(b).add([v.index], w / tot, "REPLACE")


# ====================================================================== esqueleto
def make_armature(name, face_points):
    """Esqueleto R15 (los nombres de las piezas de Roblox) + huesos de la cara. Cada hueso nace en su
    articulación y apunta hacia arriba (como scripts/invasion/alien_blender.py: Roblox lo importa sin
    girar). face_points: {hueso de la cara: punto}."""
    arm = bpy.data.objects.new(name, bpy.data.armatures.new(name + "_arm"))
    coll().objects.link(arm)
    select_only([arm])
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    L = 0.2
    root = eb.new("Root")
    root.head, root.tail = (0, 0, 0), (0, 0, L)
    done = {"Root": root}
    for bname in R15_ORDER:
        pos, parent = R15_JOINTS[bname]
        b = eb.new(bname)
        b.head, b.tail = pos, pos + Vector((0, 0, L))
        b.roll = 0.0
        b.parent = done[parent]
        b.use_connect = False
        done[bname] = b
    for fname in FACE_BONES:
        pos = face_points[fname]
        b = eb.new(fname)
        b.head, b.tail = pos, pos + Vector((0, 0, 0.08))
        b.roll = 0.0
        b.parent = done["Head"]
        b.use_connect = False
        done[fname] = b
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def bind(obj, arm):
    obj.parent = arm
    m = obj.modifiers.new("Esqueleto", "ARMATURE")
    m.object = arm
    return m


def pose_bones(arm, rotations, locations=None):
    """Postura: rotations {hueso: Matrix 3x3 (ejes del mundo, alrededor de su articulación)},
    locations {hueso: Vector (mundo)}. Cada hueso gira respecto a su padre ya girado (como un Motor6D)."""
    locations = locations or {}
    for pb in arm.pose.bones:
        L = pb.bone.matrix_local
        h = L.translation
        R = rotations.get(pb.name)
        local = Matrix.Identity(4)
        if R is not None:
            local = Matrix.Translation(h) @ R.to_4x4() @ Matrix.Translation(-h)
        if pb.name in locations:
            local = Matrix.Translation(locations[pb.name]) @ local
        pb.matrix_basis = L.inverted() @ local @ L
    bpy.context.view_layer.update()


def rest_pose(arm):
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()


def export_fbx(path, arm, meshes):
    select_only([arm] + meshes, arm)
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, object_types={"ARMATURE", "MESH"}, apply_unit_scale=True, global_scale=1.0,
                             axis_forward="-Z", axis_up="Y", mesh_smooth_type="FACE", use_mesh_modifiers=False, add_leaf_bones=False,
                             bake_anim=False, armature_nodetype="NULL", primary_bone_axis="Y", secondary_bone_axis="X",
                             path_mode="STRIP", embed_textures=False, use_custom_props=False, use_tspace=True)
