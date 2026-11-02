#!/usr/bin/env python3
"""Los ornamentos de Nácara v2 (docs/mar/nacara-v2/diseno.md §3 bis) en Blender: cuatro mallas pequeñas que
comparten UN atlas de 1024 × 1024 (color, normal y rugosidad: 2 × 2 cuadros con las texturas de
nacara_v2_texturas.py). En el juego son MeshParts con SurfaceAppearance (World/NacaraV2Look); si aún no están
subidas, el constructor pone su respaldo de piezas.

    Concha     abanico de concha con costillas (encima de puertas y arcos)      cuadro nácar
    Relieve    panel tallado con olas y una espiral (frisos de los edificios)     cuadro coral tallado
    Percebes   racimo de percebes (crecen en las paredes, abajo)                  cuadro roca gastada
    Capitel    capitel de columna con volutas                                    cuadro oro

Ninguna es un tubo liso alargado (lo revisa scripts/audit/moderacion-mallas.py --check, 0 avisos).

Uso (desde roblox/; bpy 4.2): python3 scripts/map/nacara_v2_ornamentos.py [assets/nacara-v2]
Antes: python3 scripts/map/nacara_v2_texturas.py (las texturas del atlas).
"""
import json
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/nacara-v2"
TEX = os.path.join(OUT, "tex")
QUAD = {"Concha": (0, 0, "nacar"), "Relieve": (1, 0, "coraltallado"), "Percebes": (0, 1, "rocagastada"), "Capitel": (1, 1, "oro")}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def finish(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    # UV: proyección «inteligente» y al cuadro del atlas que le toca
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    qx, qy, _ = QUAD[name]
    for loop in me.uv_layers.active.data:
        u, v = loop.uv
        loop.uv = ((qx + 0.02 + u * 0.96) / 2, (qy + 0.02 + v * 0.96) / 2)
    for p in me.polygons:
        p.use_smooth = True
    return ob


def concha():
    """Abanico: 13 costillas de un semicírculo, con relieve (alto 2,4, ancho 3,2, grueso ~0,5)."""
    bm = bmesh.new()
    rings, spokes = 8, 52
    verts = []
    for r in range(rings + 1):
        row = []
        for s in range(spokes + 1):
            a = math.pi * s / spokes
            t = r / rings
            rib = 0.5 + 0.5 * math.cos(2 * math.pi * 13 * s / spokes)
            rad = 0.15 + 1.45 * t
            z = 0.12 + 0.28 * rib * t + 0.12 * math.sin(math.pi * t)
            row.append(bm.verts.new((math.cos(a) * rad, z, math.sin(a) * rad * 1.5)))
        verts.append(row)
    for r in range(rings):
        for s in range(spokes):
            bm.faces.new((verts[r][s], verts[r][s + 1], verts[r + 1][s + 1], verts[r + 1][s]))
    # espalda plana (para que sea sólida)
    back = [bm.verts.new((v.co.x, -0.05, v.co.z)) for v in verts[rings]]
    bm.faces.new([*verts[rings], *reversed(back)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return finish("Concha", bm)


def relieve():
    """Panel 6 × 3 con olas y una espiral talladas (grueso 0,3–0,6)."""
    bm = bmesh.new()
    nx, ny = 72, 36
    grid = []
    for j in range(ny + 1):
        row = []
        for i in range(nx + 1):
            x, y = i / nx * 6 - 3, j / ny * 3
            wave = 0.5 + 0.5 * math.sin(x * 2.2 + 1.4 * math.sin(y * 2.0))
            band = 1.0 if 0.6 < y < 2.4 else 0.0
            sx, sy = x - 1.6, y - 1.5
            r = math.hypot(sx, sy)
            spiral = 0.5 + 0.5 * math.cos(r * 9 - math.atan2(sy, sx) * 2) if r < 1.1 else 0.0
            frame = 1.0 if (abs(x) > 2.7 or y < 0.3 or y > 2.7) else 0.0
            z = 0.3 + 0.18 * wave * band * (1 if r >= 1.1 else 0.3) + 0.2 * spiral + 0.25 * frame
            row.append(bm.verts.new((x, z, y)))
        grid.append(row)
    for j in range(ny):
        for i in range(nx):
            bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
    edge = [*grid[0], *[grid[j][nx] for j in range(1, ny + 1)], *reversed(grid[ny][:nx]), *reversed([grid[j][0] for j in range(1, ny)])]
    back = [bm.verts.new((v.co.x, 0.0, v.co.z)) for v in edge]
    for k in range(len(edge)):
        a, b = edge[k], edge[(k + 1) % len(edge)]
        bm.faces.new((a, b, back[(k + 1) % len(edge)], back[k]))
    bm.faces.new(list(reversed(back)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return finish("Relieve", bm)


def percebes():
    """Racimo de 9 percebes (conos truncados con boca) sobre una base irregular (2 × 2, alto 0,8)."""
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, segments=20, radius=1.0)
    for v in bm.verts:
        a = math.atan2(v.co.y, v.co.x)
        k = 1 + 0.15 * math.sin(a * 5)
        v.co = Vector((v.co.x * k, v.co.y * k, 0.0))
    ext = bmesh.ops.extrude_face_region(bm, geom=list(bm.faces))
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.z += 0.12
    spots = [(0, 0, 0.42), (0.55, 0.2, 0.32), (-0.5, 0.35, 0.3), (0.2, -0.6, 0.3), (-0.35, -0.45, 0.26), (0.7, -0.35, 0.22), (-0.75, -0.05, 0.22), (0.15, 0.7, 0.24), (-0.1, 0.25, 0.2)]
    for x, y, r in spots:
        h = r * 1.5
        res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=10, radius1=r, radius2=r * 0.45, depth=h)
        for v in res["verts"]:
            v.co += Vector((x, y, 0.12 + h / 2))
        # la boca: se hunde el centro de la tapa de arriba
        top = [v for v in res["verts"] if v.co.z > 0.12 + h * 0.99]
        if top:
            c = sum((v.co for v in top), Vector()) / len(top)
            bmesh.ops.scale(bm, vec=(0.7, 0.7, 1), space=__import__("mathutils").Matrix.Translation(-c), verts=top)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for v in bm.verts:
        v.co = Vector((v.co.x, v.co.z, v.co.y))  # de cara a la pared: crecen hacia +Y de Blender (−Z de Roblox, el frente)
    return finish("Percebes", bm)


def capitel():
    """Capitel: anillo, cuerpo que se abre como una flor y ábaco cuadrado con volutas (ancho 3, alto 2)."""
    bm = bmesh.new()
    prof = [(0.8, 0.0), (0.95, 0.08), (0.95, 0.25), (0.85, 0.35), (1.0, 0.8), (1.25, 1.25), (1.45, 1.5), (1.5, 1.6)]
    seg = 32
    rings = []
    for r, z in prof:
        row = []
        for s in range(seg):
            a = 2 * math.pi * s / seg
            leaf = 1 + (0.08 * math.cos(a * 8) if z > 0.4 else 0)
            row.append(bm.verts.new((math.cos(a) * r * leaf, math.sin(a) * r * leaf, z)))
        rings.append(row)
    for k in range(len(rings) - 1):
        for s in range(seg):
            bm.faces.new((rings[k][s], rings[k][(s + 1) % seg], rings[k + 1][(s + 1) % seg], rings[k + 1][s]))
    bm.faces.new(list(reversed(rings[0])))
    res = bmesh.ops.create_cube(bm, size=1)
    for v in res["verts"]:
        v.co = Vector((v.co.x * 3.0, v.co.y * 3.0, 1.6 + (v.co.z + 0.5) * 0.4))
    for sx in (-1, 1):
        for sy in (-1, 1):
            t = bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=0.38)
            for v in t["verts"]:
                v.co = Vector((v.co.x * 1.0 + sx * 1.3, v.co.y * 0.6 + sy * 1.3, v.co.z + 1.55))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return finish("Capitel", bm)


def atlas():
    """El atlas 1024 × 1024 (2 × 2 cuadros de 512) de color, normal y rugosidad."""
    for mapa in ("color", "normal", "roughness"):
        sheet = Image.new("RGB", (1024, 1024))
        for name, (qx, qy, tex) in QUAD.items():
            f = os.path.join(TEX, f"{tex}_{mapa}.png")
            im = Image.open(f).convert("RGB").resize((512, 512))
            # (v de Blender va hacia arriba; la imagen, hacia abajo)
            sheet.paste(im, (qx * 512, (1 - qy) * 512))
        sheet.save(os.path.join(TEX, f"ornamentos_{mapa}.png"))


def main():
    atlas()
    info = {}
    for fn in (concha, relieve, percebes, capitel):
        reset()
        ob = fn()
        bpy.context.view_layer.update()
        dims = ob.dimensions
        # Blender (x, y, z) con Y arriba en el FBX (axis_up = Y): tamaño en studs (x, alto, hondo)
        info[ob.name] = {"Size": [round(dims.x, 3), round(dims.z, 3), round(dims.y, 3)], "Tris": sum(len(p.vertices) - 2 for p in ob.data.polygons), "Atlas": "ornamentos"}
        bpy.ops.object.select_all(action="DESELECT")
        ob.select_set(True)
        bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, ob.name + ".fbx"), use_selection=True, axis_forward="-Z", axis_up="Y", apply_unit_scale=True, bake_space_transform=True, mesh_smooth_type="FACE")
        print(f"  {ob.name}: {info[ob.name]}")
    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"Ornamentos": info, "Texturas": sorted(os.listdir(TEX))}, f, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    main()
