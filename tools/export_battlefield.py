"""Run with Blender -b SOURCE.blend --python tools/export_battlefield.py.

Exports the supplied battlefield only; never saves over the source file.
"""
import bpy
import json
from pathlib import Path
import sys
import os

ROOT = Path(__file__).resolve().parents[1]
(ROOT / ".local/battlefield").mkdir(parents=True, exist_ok=True)
OUT = ROOT / "assets/environment/battlefield"
scene = bpy.data.scenes["Medieval_Battlefield"]
bpy.context.window.scene = scene
art = [o for o in scene.objects if o.type == "MESH"
       and any(c.name in {"Map_Terrain", "Map_Ruins", "Map_Rocks", "Map_Vegetation"}
               or c.name.startswith("Bush_") for c in o.users_collection)
       and not o.get("overlap_only", False)]
# Three decorative groundcover tiles contain intersecting coplanar blades.
# Omit those tiles from the engine copy; keep the supplied source untouched.
art = [o for o in art if o.name not in {"SM_GrassWeedsFlowers_Tile_4_0",
       "SM_GrassWeedsFlowers_Tile_0_1", "SM_GrassWeedsFlowers_Tile_2_1"}]
proxies = list(bpy.data.collections["Gameplay_Collision"].objects)
zones = []
for o in bpy.data.collections["Gameplay_Triggers"].objects:
    if not o.get("is_bush"):
        continue
    corners = [o.matrix_world @ __import__('mathutils').Vector(v) for v in o.bound_box]
    zones.append({"name": o.get("bush_id", o.name),
                  "center": [o.location.x, (min(v.z for v in corners) + max(v.z for v in corners)) / 2, -o.location.y],
                  "radius": float(o.get("radius_m", 3.6)),
                  "height": max(v.z for v in corners) - min(v.z for v in corners)})

# Check representative unique meshes separately: detached props are intentional
# across a 100 m environment, rather than pieces of a single connected prop.
sys.path.insert(0, os.environ["BLENDER_QA_SCRIPTS"])
import qa_check
reps = {}
for o in art:
    if o.data not in reps:
        reps[o.data] = o
reports = {}
for o in reps.values():
    # Batched flowers/grass are intentionally separate open islands.
    qa_check.PROFILES['game']['fl'] = 'w' if o.get('engine_role') == 'decorative_groundcover' else 'e'
    reports[o.name] = qa_check.run(objects=[o.name], uv=False)
(ROOT / ".local/battlefield/qa.json").write_text(json.dumps(reports, indent=2))
errors = {n: r["errors"] for n, r in reports.items() if r["errors"]}
if errors:
    raise RuntimeError(errors)

export_scene = bpy.data.scenes.new("Battlefield_Export")
bpy.context.window.scene = export_scene
for o in art + proxies:
    export_scene.collection.objects.link(o)
    o.hide_set(False)
    o.hide_viewport = False
    o.select_set(True)
for o in proxies:
    # Import hints on shared meshes can otherwise add collision to the art too.
    o.data = o.data.copy()
    o.data.name = o.name + "_ProxyMesh"
    o.name += "-colonly"
    o.hide_render = False
bpy.ops.export_scene.gltf(filepath=str(OUT / "battlefield.glb"), export_format="GLB",
    use_selection=True, export_extras=True, export_animations=False,
    use_active_scene=True, export_skins=False,
    export_cameras=False, export_lights=False, export_yup=True)
(OUT / "zones.json").write_text(json.dumps(sorted(zones, key=lambda z: z['name']), indent=2) + "\n")
triangles = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in art)
print("BATTLEFIELD EXPORT", json.dumps({"objects": len(art), "unique_meshes": len(reps),
      "triangles": triangles, "proxies": len(proxies), "zones": len(zones),
      "bytes": (OUT / "battlefield.glb").stat().st_size}))
