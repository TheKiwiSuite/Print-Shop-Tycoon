"""Run in background Blender after builds. Does not save or modify any model."""
import bpy, json, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
results=[]
for kind in ['sticker','heat','art','finish','pack','storage','banner','cnc','dock']:
    path=ROOT/kind/(kind+'.blend')
    before=hashlib.sha256(path.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(path))
    scene=bpy.context.scene
    root=scene.objects.get(kind+' floor anchor')
    assert root is not None,kind
    assert list(root.location)==[0,0,0],kind
    assert list(root.scale)==[-1,1,1],kind
    assert scene['catalog_id']==kind,kind
    assert scene.render.engine=='CYCLES',kind
    assert not scene.render.use_freestyle,kind
    objs=[o for o in scene.objects if o.type in {'MESH','CURVE','FONT'} and not o.hide_render]
    assert all(o.parent==root for o in objs),kind
    zmin=min((o.matrix_world @ Vector(c)).z for o in objs for c in o.bound_box)
    assert abs(zmin)<.015,(kind,zmin)
    assert hashlib.sha256(path.read_bytes()).hexdigest()==before
    results.append({'id':kind,'geometry_objects':len(objs),'root_at_floor':True,'reference_orientation':True,'source_unchanged':True,'lowest_point':zmin})
(ROOT/'model-source-check.json').write_text(json.dumps({'passed':True,'models':results},indent=2))
print('MODEL_SOURCE_PASS',len(results),'rigid assemblies, ground anchors, reference orientation')
