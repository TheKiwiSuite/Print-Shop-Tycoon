"""DTF reference reconstruction v2. Built from the user-supplied front/side views.
Fresh background Blender process only. All dimensions are relative, not manufacturer specs.
Preserves original source images. One rigid assembly supplies every rendered direction.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "dtf-reference-v2"
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
# Wide printer. Sloping lid, front opening and rigid T-leg frame.
profile=[(-1.53,1.22),(-1.53,1.86),(-1.23,1.92),(-.78,1.70),(-.69,1.31),(-.69,1.22)]
extrude("Teal angular printer enclosure",-1.63,1.63,profile,"teal",.025)
# Dark straps are extruded on the same profile and remain on the original sides.
strap=[(y-.003 if y< -1.2 else y+.008,z+.012) for y,z in profile]
for x in [-1.36,1.36]:
    extrude("Black housing strap",x-.105,x+.105,strap,"black",.012)
box("Rear top black hinge strip",(0,-1.38,1.917),(2.85,.27,.035),"black",.012)
# Sloped inspection window, flush to the hood plane.
win=box("Long inspection window",(0,-1.004,1.818),(2.08,.24,.012),"darkwindow",.035)
win.rotation_euler.x=math.radians(-26)
fascia=box("Front charcoal print beam",(0,-.707,1.445),(2.66,.052,.24),"gray",.008)
box("Deep print slot",(0,-.683,1.244),(2.72,.045,.15),"black",.008)
for i in range(10):
    screw("Fascia fastener",(-1.21+i*.27,-.674,1.46),r=.012)
    box("Pinch roller bracket",(-1.20+i*.267,-.61,1.254),(.105,.09,.026),"steel",.005)
    cylinder("Pinch roller",(-1.20+i*.267,-.568,1.225),.025,.085,"rubber","X")
cylinder("Golden print transport roller",(0,-.64,1.12),.063,2.78,"gold","X")
cylinder("Lower aluminum feed roller",(0,-.60,1.015),.047,2.9,"steel","X")
for x in [-1.48,1.48]:
    box("Printer black main upright",(x,-1.13,.72),(.19,.27,.96),"black",.018)
    box("Printer T foot",(x,-1.13,.235),(.28,1.15,.105),"black",.025)
    for y in [-1.57,-.68]:wheel("Printer caster",x,y)
    for z in [.42,.83,1.09]:
        for xx in [-.06,.06]:screw("Stand rivet",(x+xx,-.987,z),"Y","gold",.009)
    box("Printer print-bay bracket",(x,-1.05,1.15),(.28,.73,.19),"black",.015)
box("Stand lower cross rail",(0,-1.19,.39),(2.9,.11,.16),"black",.012)
box("Rear lower stand rail",(0,-1.43,.87),(2.85,.09,.09),"gray",.008)
cylinder("Rear film supply roll",(0,-1.60,1.04),.105,2.54,"paper","X")
# Control panel on physical right end.
panel=box("Angled black control panel",(1.36,-.985,1.805),(.22,.38,.035),"black",.015)
panel.rotation_euler.x=math.radians(-26)
screen=box("Amber control touchscreen",(1.36,-.992,1.826),(.155,.19,.008),"amber",.007)
screen.rotation_euler.x=math.radians(-26)
cylinder("Control jog bezel",(1.36,-.709,1.57),.053,.023,"black","Y")
ring("Yellow jog dial",(1.36,-.692,1.57),.028,.008,"yellow","Y")
box("Blue maintenance access",(1.36,-.707,1.38),(.13,.03,.18),"blue",.008)
cylinder("Emergency stop base",(1.35,-1.34,1.966),.073,.064,"black")
cylinder("Red emergency stop",(1.35,-1.34,2.014),.067,.045,"red")
# Left ink reservoir, white/cyan/magenta/yellow/black in fixed order.
box("Ink rack floor",(-.93,-1.43,1.99),(1.12,.30,.045),"black")
for i,mat in enumerate(["white","cyan","magenta","yellow","black"]):
    x=-1.36+i*.215
    box("Ink bottle "+mat,(x,-1.43,2.14),(.177,.18,.265),mat,.04)
    cylinder("Bottle shoulder "+mat,(x,-1.43,2.275),.066,.05,mat)
    cylinder("Bottle cap "+mat,(x,-1.43,2.318),.073,.045,"black")
box("Ink rack front wall",(-.93,-1.25,2.075),(1.15,.035,.23),"black",.008)
box("Ink rack front label",(-.93,-1.228,2.085),(.43,.006,.076),"white",.01)
for x in [-1.52,-.345]:box("Ink rack end",(x,-1.43,2.065),(.035,.32,.21),"black",.008)
for x in [-.48,.23,.8]:
    box("Top hinge",(x,-1.45,1.952),(.12,.13,.025),"black",.005)
    cylinder("Top hinge pin",(x,-1.49,1.973),.016,.14,"steel","X")
# side access panels and louvers.
for sign in [-1,1]:
    x=sign*1.642
    box("Teal side service inset",(x,-1.12,1.475),(.012,.48,.30),"teal",.028)
    for zz in range(5):
        for yy in [-1.33,-.92]:
            box("Side ventilation slit",(x+sign*.009,yy,1.35+zz*.026),(.008,.078,.009),"black",.003)
    for yy in [-1.31,-.93]:
        for z in [1.35,1.59]:screw("Side panel screw",(x+sign*.012,yy,z),"X",r=.008)
# Real rear face details; fans do not move between views.
box("Printer rear service panel",(0,-1.544,1.53),(2.73,.025,.43),"black",.015)
for x in [-.65,.65]:
    cylinder("Rear fan recess",(x,-1.566,1.52),.13,.016,"black","Y")
    for r in [.035,.066,.095,.125]:ring("Rear fan grill",(x,-1.58,1.52),r,.0035,"steel","Y")
    for dx,dz in [(-.14,-.14),(-.14,.14),(.14,-.14),(.14,.14)]:
        screw("Rear fan screw",(x+dx,-1.58,1.52+dz),"Y",r=.008)
box("Rear power socket",(1.22,-1.57,1.39),(.09,.025,.095),"black",.004)
box("Rear rocker switch",(1.22,-1.591,1.31),(.065,.014,.04),"red",.004)
tube("Rear power cable",[(1.21,-1.60,1.39),(1.23,-1.69,1.20),(1.36,-1.67,.99),(1.44,-1.50,.89)],.018,"black")
# White narrower shaker / curing cabinet.
active=assemblies["Shaker"]
box("Curing cabinet base",(0,.70,.67),(1.92,1.78,.77),"white",.018)
# Thin black seams establish separate panels instead of a featureless box.
for sign in [-1,1]:
    x=sign*.969
    box("Side panel seam",(x,.70,.63),(.008,1.67,.018),"gray",.001)
    box("Side service door border",(x,.97,.55),(.012,.65,.44),"gray",.018)
    box("Side service door",(x+sign*.007,.97,.55),(.012,.625,.415),"white",.014)
    box("Recessed door handle",(x+sign*.018,.97,.61),(.018,.20,.07),"black",.008)
    fan("Shaker cooling fan",x+sign*.014,.20,.58,.145)
    for yy in [-.1,.55,1.48]:
        for zz in [.35,.92]:screw("Cabinet side fastener",(x+sign*.013,yy,zz),"X",r=.009)
    for y in [-.04,1.39]:wheel("Shaker caster",sign*.82,y,.078)
    for y in [1.68]:
        cylinder("Leveling foot",(sign*.88,y,.035),.07,.055,"black")
        cylinder("Leveling foot stem",(sign*.88,y,.17),.022,.23,"gold")
# Shaker lid: flat roof, shallow slanted front fascia, full front output below.
hood=[(-.19,1.04),(-.19,1.34),(1.18,1.34),(1.61,1.13),(1.61,.98)]
extrude("White curing hood",-.99,.99,hood,"white",.018)
box("Rear teal viewing window",(0,-.012,1.355),(1.22,.19,.012),"teal",.018)
box("Rear feed slot",(0,-.208,1.104),(1.52,.018,.094),"black",.007)
box("Front cured film opening",(0,1.615,.939),(1.47,.025,.16),"black",.006)
# Hollow chimney, with dark inner opening and polished rim.
cylinder("Exhaust base flange",(0,.54,1.367),.14,.028,"steel")
cylinder("Exhaust neck",(0,.54,1.485),.102,.22,"steel")
cylinder("Dark open exhaust",(0,.54,1.597),.087,.007,"black")
ring("Exhaust rim",(0,.54,1.601),.099,.009,"steel")
tube("Front hood handle",[(-.27,1.63,1.10),(-.27,1.69,1.10),(-.22,1.72,1.10),(.22,1.72,1.10),(.27,1.69,1.10),(.27,1.63,1.10)],.025,"black")
for sign in [-1,1]:
    x=sign*1.02
    tube("Side black hood grip",[(x,.35,1.09),(x+sign*.035,.39,1.09),(x+sign*.035,.89,1.09),(x,.93,1.09)],.026,"black")
    cylinder("Hood latch axle",(x,.94,1.09),.045,.07,"black","X")
    cylinder("Red hood latch end",(x+sign*.04,.94,1.09),.017,.009,"red","X")
    tube("Red latch rod",[(x,.94,1.09),(x,1.22,1.09)],.008,"red")
    for y in [-.12,.10,1.19,1.50]:
        screw("Hood side fastener",(sign*1.004,y,1.12),"X",r=.009)
for x in [-.89,.89]:
    for z in [1.025,1.095]:screw("Hood front fastener",(x,1.624,z),"Y",r=.01)
# Front take-up roll on two black cheek plates, silver end caps and lever.
for sign in [-1,1]:
    extrude("Take-up cheek",sign*.91-.055,sign*.91+.055,[(1.57,.24),(1.57,.68),(1.82,.76),(2.15,.40),(2.15,.20)],"black",.035)
    screw("Take-up cheek gold fastener",(sign*.978,1.78,.54),"X","gold",.021)
    cylinder("Take-up hub",(sign*.99,1.97,.30),.074,.055,"steel","X")
    lever=box("Orange tension lever",(sign*1.025,1.90,.36),(.035,.18,.04),"red",.012)
    lever.rotation_euler.x=math.radians(-26)
cylinder("Lower take-up polished roller",(0,2.08,.235),.07,2.13,"steel","X")
cylinder("Winding paper core",(0,1.96,.34),.15,1.73,"paper","X")
for x in [-.98,.98]:
    cylinder("Take-up black end cap",(x,1.96,.34),.17,.12,"black","X")
    cylinder("Roller end silver",(x*1.12,2.08,.235),.085,.032,"steel","X")
# Printed film uses the exact supplied artwork through UVs; source PNG stays unchanged.
active=assemblies["Transfer film"]
ref=ROOT.parent/"source"/"assets"/"dtf-line-front.png"
image=bpy.data.images.load(str(ref));image.pack()
film=bpy.data.materials.new("User supplied crown transfer artwork");film.use_nodes=True
nodes=film.node_tree.nodes
bsdf=next(n for n in nodes if n.type=="BSDF_PRINCIPLED")
bsdf.inputs["Roughness"].default_value=.42
tex=nodes.new("ShaderNodeTexImage");tex.image=image;tex.interpolation="Linear";tex.extension="EXTEND"
film.node_tree.links.new(tex.outputs["Color"],bsdf.inputs["Base Color"])
# A central rectangular portion of the approved front image's white printed film.
# UV region avoids machine body and includes the exact printed crown artwork.
def ribbon(name,ys,zs,width,repeat=1):
    verts=[]
    for y,z in zip(ys,zs):verts.extend([(-width/2,y,z),(width/2,y,z)])
    faces=[(2*i,2*i+1,2*i+3,2*i+2) for i in range(len(ys)-1)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);active.objects.link(obj);obj.data.materials.append(film)
    uv=mesh.uv_layers.new()
    # Map the front image film rectangle, from ~x .38.. .62, y .69.. .86.
    # Blender UV origin is bottom left.
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            vi=mesh.loops[li].vertex_index
            row=vi//2
            uv.data[li].uv=(.38 if vi%2==0 else .62, .31-(row/(len(ys)-1))*.17)
    solid=obj.modifiers.new("Film thickness","SOLIDIFY");solid.thickness=.0015
    return obj
ribbon("Unbroken printed film entering shaker",[-.61,-.46,-.28,-.19],[1.15,1.14,1.08,1.10],1.43)
ribbon("Cured printed film to front take-up",[1.61,1.68,1.80,1.93,2.04,2.11,2.105],[.985,.88,.69,.51,.45,.34,.285],1.43)
# Consistent physically based finish with gentle illustration-like highlight rolloff.
for name,loc,power,size in [
 ("Large soft key",(-3,4,6),650,4.0),
 ("Broad cool fill",(4,1,4),450,3.5),
 ("Rear rim",(-1,-4,5),550,3.0)]:
    d=bpy.data.lights.new(name,"AREA");d.energy=power;d.shape="DISK";d.size=size
    o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc
    o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat("-Z","Y").to_euler()
# Match the approved frontal reference: reservoir at screen-left and controls
# screen-right. Reflection changes the source assembly once, never per view.
root=bpy.data.objects.new("DTF connected assembly",None)
scene.collection.objects.link(root)
for collection in assemblies.values():
    for obj in list(collection.objects): obj.parent=root
root.scale.x=-1
bpy.context.view_layer.update()
# Beveled edges and material contrast supply the illustrated finish.
# Freestyle is disabled: its stroke pass rejects some mirrored small parts.
scene.render.use_freestyle=False
bpy.ops.object.camera_add(location=(-6,8,5))
camera=bpy.context.object;camera.name="Reference inspection camera";scene.camera=camera
camera.data.type="ORTHO";camera.data.ortho_scale=5.5
camera.rotation_euler=(Vector((0,.12,1.1))-camera.location).to_track_quat("-Z","Y").to_euler()
scene.render.filepath=str(OUT/"reference-preview.png")
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"DTF-Reference-v2.blend"))
bpy.ops.render.render(write_still=True)
print("DTF_REFERENCE_V2_BUILT",len(scene.objects),flush=True)
