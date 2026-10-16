"""DTF reference reconstruction v2. Built from the user-supplied front/side views.
Fresh background Blender process only. All dimensions are relative, not manufacturer specs.
Preserves original source images. One rigid assembly supplies every rendered direction.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "equipment-review-v1"
OUT.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "Standard"
scene.view_settings.exposure = -.65
scene.world = bpy.data.worlds.new("Soft studio ambient")
scene.world.use_nodes = True
scene.world.node_tree.nodes.get("Background").inputs["Color"].default_value = (.68,.77,.86,1)
scene.world.node_tree.nodes.get("Background").inputs["Strength"].default_value = .55
M = {}
def material(name, color, metallic=0, roughness=.35):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color,1)
    m.use_nodes = True
    node = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    node.inputs["Base Color"].default_value = (*color,1)
    node.inputs["Metallic"].default_value = metallic
    node.inputs["Roughness"].default_value = roughness
    M[name] = m
    return m
for n,c,metal,rough in [
 ("teal",(.008,.66,.48),.15,.29),("mint",(.08,.83,.63),.1,.3),
 ("black",(.018,.023,.03),.25,.3),("rubber",(.009,.012,.016),0,.65),
 ("gray",(.19,.21,.26),.5,.3),("steel",(.59,.65,.72),.78,.25),
 ("white",(.88,.9,.94),.1,.3),("paper",(.97,.97,.98),0,.38),
 ("gold",(.67,.43,.13),.78,.24),("darkwindow",(.008,.06,.055),.25,.19),
 ("cyan",(.005,.54,.95),.05,.27),("magenta",(.9,.006,.35),.05,.3),
 ("yellow",(.98,.76,.008),.05,.3),("red",(.85,.015,.009),.15,.28),
 ("blue",(.005,.13,.65),.1,.24),("amber",(.62,.29,.008),.3,.3)]:
    material(n,c,metal,rough)

assemblies = {}
for name in ["Printer", "Shaker", "Transfer film"]:
    c=bpy.data.collections.new(name);scene.collection.children.link(c);assemblies[name]=c
active = assemblies["Printer"]
def finish(o,name,mat,bevel=0):
    o.name=name
    for c in list(o.users_collection): c.objects.unlink(o)
    active.objects.link(o)
    o.data.materials.append(M[mat] if isinstance(mat,str) else mat)
    if bevel:
        mod=o.modifiers.new("Soft manufactured edge","BEVEL");mod.width=bevel;mod.segments=3
        o.modifiers.new("Weighted surface normals","WEIGHTED_NORMAL")
    return o
def box(name,loc,size,mat,bevel=.015):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.object;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,mat,bevel)
def cylinder(name,loc,r,depth,mat,axis="Z",verts=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=loc)
    o=bpy.context.object
    if axis=="X":o.rotation_euler.y=math.pi/2
    elif axis=="Y":o.rotation_euler.x=math.pi/2
    for p in o.data.polygons:p.use_smooth=True
    return finish(o,name,mat,.006)
def tube(name,points,r,mat):
    curve=bpy.data.curves.new(name,"CURVE");curve.dimensions="3D";curve.bevel_depth=r;curve.bevel_resolution=3
    s=curve.splines.new("POLY");s.points.add(len(points)-1)
    for p,co in zip(s.points,points):p.co=(*co,1)
    o=bpy.data.objects.new(name,curve);active.objects.link(o);o.data.materials.append(M[mat])
    return o
def ring(name,loc,major,minor,mat,axis="Z"):
    bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=48,minor_segments=10,location=loc)
    o=bpy.context.object
    if axis=="X":o.rotation_euler.y=math.pi/2
    elif axis=="Y":o.rotation_euler.x=math.pi/2
    for p in o.data.polygons:p.use_smooth=True
    return finish(o,name,mat)
def extrude(name,x0,x1,profile,mat,bevel=.012):
    verts=[(x,y,z) for x in (x0,x1) for y,z in profile];n=len(profile)
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);active.objects.link(o)
    return finish(o,name,mat,bevel)
def screw(name,loc,axis="Y",mat="steel",r=.013):
    cylinder(name+" head",loc,r,.009,mat,axis,16)
    d={"X":(.006,.018,.003),"Y":(.018,.006,.003),"Z":(.018,.003,.006)}[axis]
    box(name+" slot",loc,d,"black",.001)
def wheel(name,x,y,r=.09):
    cylinder(name+" tire",(x,y,r),r,.065,"rubber","X")
    cylinder(name+" metal hub",(x+.036,y,r),r*.58,.012,"steel","X")
    cylinder(name+" bolt",(x+.044,y,r),r*.16,.016,"gold","X")
    box(name+" caster fork",(x,y,r*1.75),(.078,.06,.1),"steel",.008)
    cylinder(name+" swivel",(x,y,r*2.15),.035,.05,"steel")
def fan(name,x,y,z,r=.14):
    sign=1 if x>0 else -1
    cylinder(name+" recess",(x,y,z),r,.012,"black","X")
    for rr in [.035,.065,.095,.125]:
        if rr<r:ring(name+" wire", (x+sign*.014,y,z),rr,.0035,"steel","X")
    for a in range(0,360,45):
        a=math.radians(a)
        tube(name+" spoke",[(x+sign*.021,y-r*math.cos(a),z-r*math.sin(a)),(x+sign*.021,y+r*math.cos(a),z+r*math.sin(a))],.0035,"steel")
    cylinder(name+" hub",(x+sign*.023,y,z),.022,.012,"steel","X")
    for yy in [-1,1]:
        for zz in [-1,1]:screw(name+" mount",(x+sign*.018,y+yy*r*.85,z+zz*r*.85),"X",r=.008)
