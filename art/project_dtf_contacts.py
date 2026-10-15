import bpy, json, math
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
root=Path(__file__).resolve().parent.parent
scene=bpy.context.scene
camera=scene.camera
# Reproduce the camera used for the existing separate equipment textures.
camera.location=(8,8,6.2)
camera.data.ortho_scale=5.1
camera.rotation_euler=(Vector((0,0,1))-camera.location).to_track_quat('-Z','Y').to_euler()
bpy.context.view_layer.update()
def project(point):
 p=world_to_camera_view(scene,camera,Vector(point))
 return [round(p.x*768,4),round((1-p.y)*768,4)]
metadata={
 'printer':{'floor_center':project((0,0,0)),
            'contacts':[project((x,y,.02)) for x in [-1.46,1.46] for y in [-.34,.34]],
            'outlet':project((0,.56,1.47))},
 'shaker':{'floor_center':project((0,0,0)),
           'contacts':[project((x,y,.05)) for x in [-1.45,1.45] for y in [-.74,.75]],
           'inlet':project((0,-.94,1.39))}
}
(root/'art/dtf-floor-contacts.json').write_text(json.dumps(metadata,indent=2))
print(json.dumps(metadata))
