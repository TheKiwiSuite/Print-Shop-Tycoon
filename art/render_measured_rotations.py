"""Render measured orthographic equipment views from ONE editable Blender model.
Run in a separate Blender background process; never modifies the input blend.
Angle 0 observes from +Y. Positive angles orbit toward +X.
Candidate renders are not design approval.
"""
import argparse, hashlib, json, math, sys
from pathlib import Path
import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

def arguments():
    p = argparse.ArgumentParser()
    p.add_argument("--source", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--size", type=int, default=768)
    p.add_argument("--status", choices=["candidate", "pipeline-test"], default="candidate")
    return p.parse_args(sys.argv[sys.argv.index("--")+1:])

def main():
    args = arguments()
    source = Path(args.source).resolve()
    output = Path(args.output).resolve()
    if source.suffix.lower() != ".blend" or not source.is_file():
        raise ValueError("Source must be an existing editable .blend")
    if not 128 <= args.size <= 4096:
        raise ValueError("Size must be 128..4096")
    output.mkdir(parents=True, exist_ok=True)
    if list(output.glob("angle-*.png")) or (output/"rotation-manifest.json").exists():
        raise ValueError("Choose a new output directory; never overwrite an earlier review")
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    objects = [o for o in scene.objects if o.type in {"MESH", "CURVE", "FONT"} and not o.hide_render
               and not any(c.hide_render for c in o.users_collection)]
    if not objects:
        raise ValueError("No visible mesh geometry")
    points = [o.matrix_world @ Vector(c) for o in objects for c in o.bound_box]
    low = Vector(tuple(min(p[a] for p in points) for a in range(3)))
    high = Vector(tuple(max(p[a] for p in points) for a in range(3)))
    center = (low + high) / 2
    radius = max((p-center).length for p in points)
    if radius <= 0: raise ValueError("Empty model bounds")
    original_transforms = {o.name: list(sum((list(row) for row in o.matrix_world), [])) for o in objects}
    data = bpy.data.cameras.new("Measured rotation review camera")
    camera = bpy.data.objects.new("Measured rotation review camera", data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    data.type = "ORTHO"
    data.ortho_scale = radius * 2.25
    data.clip_start = .001
    data.clip_end = radius * 100
    scene.render.resolution_x = args.size
    scene.render.resolution_y = args.size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.use_file_extension = True
    frames = []
    for index in range(16):
        degrees = index * 22.5
        az = math.radians(degrees)
        elevation = math.radians(30)
        direction = Vector((math.sin(az)*math.cos(elevation),
                            math.cos(az)*math.cos(elevation), math.sin(elevation)))
        camera.location = center + direction * radius * 6
        camera.rotation_euler = (center-camera.location).to_track_quat("-Z","Y").to_euler()
        bpy.context.view_layer.update()
        anchor = world_to_camera_view(scene, camera, Vector((0,0,0)))
        name = "angle-%03d-%05.1f.png" % (index, degrees)
        scene.render.filepath = str(output/name)
        bpy.ops.render.render(write_still=True)
        image_hash = hashlib.sha256((output/name).read_bytes()).hexdigest()
        frames.append({"index":index, "azimuth_degrees":degrees, "elevation_degrees":30,
                       "file":name, "sha256":image_hash, "camera_position":list(camera.location),
                       "view_direction":list(direction), "ortho_scale":data.ortho_scale,
                       "floor_anchor_pixels":[anchor.x*args.size,(1-anchor.y)*args.size]})
        print("ROTATION_FRAME", index, degrees, flush=True)
    for o in objects:
        current = list(sum((list(row) for row in o.matrix_world), []))
        if current != original_transforms[o.name]:
            raise AssertionError("Geometry moved between views: "+o.name)
    if len({f["sha256"] for f in frames}) != 16:
        raise AssertionError("Repeated render output; inspect symmetry, visibility and camera")
    manifest = {"status":args.status, "design_approved":False,
                "method":"Single rigid Blender scene; measured orthographic camera orbit",
                "source_file":source.name, "source_sha256":hashlib.sha256(source.read_bytes()).hexdigest(),
                "angle_step_degrees":22.5, "frame_count":16,
                "mesh_count":sum(o.type == "MESH" for o in objects), "visible_geometry_count":len(objects),
                "bounds":[list(low),list(high)], "target":list(center), "frames":frames}
    (output/"rotation-manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
    print("MEASURED_ROTATION_PASS 16 distinct renders, fixed geometry, fixed scale", flush=True)

if __name__ == "__main__":
    main()
