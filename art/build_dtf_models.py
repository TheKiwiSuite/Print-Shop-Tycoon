"""Original editable DTF assets, measured by the supplied illustration's proportions.
Runs in a fresh background Blender process; does not touch the user's open scene.
"""
import bpy, math
from mathutils import Vector
from pathlib import Path

root=Path(__file__).resolve().parent.parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.render.engine='BLENDER_WORKBENCH'
scene.render.resolution_x=768; scene.render.resolution_y=768
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.image_settings.color_mode='RGBA'
scene.render.film_transparent=True
scene.display.shading.light='STUDIO'
scene.display.shading.studio_light='paint.sl'
scene.display.shading.color_type='MATERIAL'
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.display.shading.cavity_type='BOTH'
scene.display.shading.show_object_outline=True
scene.display.shading.object_outline_color=(.015,.035,.07)
scene.display.shading.cavity_ridge_factor=1.6
scene.display.shading.cavity_valley_factor=1.2
scene.view_settings.view_transform='Standard'
scene.view_settings.exposure=.45
scene.world.color=(.7,.7,.7)
materials={}
for name,color in {'green':(.08,.66,.43,1),'mint':(.38,.89,.67,1),'black':(.025,.047,.068,1),'steel':(.38,.43,.50,1),'white':(.93,.93,.96,1),'paper':(1,.97,.88,1),'window':(.02,.13,.13,1),'cyan':(.01,.7,.96,1),'magenta':(.96,.025,.39,1),'yellow':(1,.78,.04,1),'orange':(1,.42,.1,1),'red':(.88,.05,.07,1)}.items():
 m=bpy.data.materials.new(name); m.diffuse_color=color; materials[name]=m

def cube(name,loc,size,mat,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
 o=bpy.context.object; o.name=name; o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(materials[mat])
 if bevel:
  mod=o.modifiers.new('Manufactured edge','BEVEL'); mod.width=bevel; mod.segments=2
  o.modifiers.new('Weighted surfaces','WEIGHTED_NORMAL')
 return o

def cylinder(name,loc,radius,depth,mat,axis='Z',vertices=24):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc)
 o=bpy.context.object; o.name=name
 if axis=='X': o.rotation_euler[1]=math.pi/2
 if axis=='Y': o.rotation_euler[0]=math.pi/2
 o.data.materials.append(materials[mat]); bevel=o.modifiers.new('Round rim','BEVEL'); bevel.width=.012; bevel.segments=2
 o.modifiers.new('Weighted surfaces','WEIGHTED_NORMAL')
 return o

def collection(name):
 c=bpy.data.collections.new(name); scene.collection.children.link(c); return c

def move_to(objects,col):
 for o in objects:
  for c in list(o.users_collection): c.objects.unlink(o)
  col.objects.link(o)

def printer():
 before=set(bpy.data.objects)
 # Reference: wide green top, inset dark window, stout black sides and visible work frame.
 cube('Green printer upper housing',(0,0,1.80),(3.24,.91,.57),'green',.08)
 cube('Mint flat top lid',(0,-.025,2.12),(2.97,.86,.13),'mint',.05)
 cube('Long dark inspection window',(0,-.025,2.20),(2.24,.36,.025),'window',.025)
 cube('Charcoal front print beam',(0,.487,1.87),(2.65,.12,.32),'steel',.025)
 cube('Printer output mouth',(0,.559,1.59),(2.70,.075,.22),'black',.01)
 cylinder('Output roller',(0,.56,1.47),.09,2.7,'steel','X')
 for x in [-1.46,1.46]:
  cube('Black side console',(x,0,1.61),(.32,1.07,.66),'black',.04)
  cube('Side mint end cap',(x,.16,1.85),(.38,.79,.54),'green',.06)
  for y in [-.34,.34]:
   cube('Tall printer leg',(x,y,.75),(.14,.15,1.25),'black',.02)
   cylinder('Printer caster',(x,y,.115),.095,.10,'black','X')
  cube('Printer base foot',(x,0,.22),(.25,1.1,.14),'black',.025)
  cube('Printer side rail',(x,0,.60),(.12,.77,.12),'steel',.01)
 cube('Rear roll support',(0,-.30,.97),(2.70,.12,.14),'black')
 cylinder('Rear loading film spool',(0,-.34,1.04),.17,2.65,'paper','X')
 cube('Black control console',(1.70,.39,1.64),(.28,.38,.42),'black',.03)
 cube('Operator display',(1.855,.41,1.73),(.015,.21,.12),'cyan',.005)
 for y in [.35,.47]: cube('Amber keypad',(1.865,y,1.58),(.025,.065,.055),'yellow',.005)
 for i,mat in enumerate(['cyan','magenta','yellow','white']):
  cylinder('Ink tank '+mat,(1.69,-.31+i*.14,1.29),.065,.31,mat)
  cylinder('Ink cap',(1.69,-.31+i*.14,1.47),.044,.055,'black')
 cube('Rear ink rack',(0,-.43,2.30),(1.3,.21,.13),'black',.02)
 for x in [-.50,-.25,0,.25,.5]: cylinder('White ink circulation bottle',(x,-.43,2.47),.065,.25,'white')
 for x in [-1.1,-.65,-.2,.25,.7,1.15]: cylinder('Small beam fastener',(x,.56,1.95),.025,.017,'white','Y',12)
 return set(bpy.data.objects)-before

def shaker():
 before=set(bpy.data.objects)
 # Reference: broad flat white cabinet, matching width, low takeaway at its front.
 cube('Wide white curing cabinet',(0,0,.83),(3.1,1.85,1.17),'white',.035)
 cube('Flat white shaker hood',(0,-.03,1.54),(3.18,1.91,.36),'white',.035)
 cylinder('Small exhaust pipe',(.05,-.15,1.84),.115,.35,'steel')
 cylinder('Exhaust open rim',(.05,-.15,2.025),.13,.045,'black')
 cube('Hood perimeter seal',(0,.955,1.36),(3.12,.026,.031),'black',.0)
 for x in [-1.40,-.93,-.46,.02,.50,.97,1.43]:
  cube('Black lid fastener',(x,.975,1.39),(.09,.045,.15),'black',.022)
  cylinder('Amber fastener light',(x,1.0,1.40),.021,.019,'orange','Y',12)
 for x in [-1.45,1.45]:
  cube('Take-up support',(x,1.11,.37),(.16,.20,.48),'black',.025)
  for y in [-.74,.75]: cylinder('Shaker caster',(x,y,.13),.08,.09,'black','X')
 cylinder('Low front take-up axle',(0,1.17,.28),.15,3.03,'black','X')
 cylinder('Printed film winding roll',(0,1.17,.28),.165,2.65,'paper','X')
 cylinder('Upper front guide roller',(0,1.07,.62),.09,3.04,'black','X')
 for x in [-1.50,1.50]:
  cylinder('Low take-up end cap',(x,1.17,.28),.20,.13,'black','X')
  cylinder('Silver roller hub',(x,1.17,.28),.09,.145,'steel','X')
 # Unbroken film descends to the low roll; three original mascot marks identify printed output.
 paper=cube('Cured transfer film',(0,1.19,.48),(2.65,.032,.30),'paper',0)
 for x in [-.84,0,.84]:
  cylinder('Transfer cat head',(x,1.215,.48),.105,.015,'orange','Y',20)
  for side in [-1,1]:
   ear=cube('Transfer cat ear',(x+side*.075,1.23,.58),(.07,.018,.08),'orange',0)
   cylinder('Transfer cat eye',(x+side*.036,1.233,.49),.013,.012,'black','Y',12)
  cylinder('Transfer cat muzzle',(x,1.237,.44),.038,.012,'white','Y',20)
 for y in [-.50,-.25,0,.25]: cube('Side cooling slot',(1.56,y,.59),(.02,.075,.22),'black',.01)
 cube('Rear film inlet',(0,-.94,1.39),(2.70,.04,.13),'black',.01)
 return set(bpy.data.objects)-before

pc=collection('DTF Printer • separate machine')
sc=collection('Powder Shaker • separate machine')
po=printer(); move_to(po,pc)
so=shaker(); move_to(so,sc)
bpy.ops.object.camera_add(location=(8,8,6.2))
camera=bpy.context.object; camera.name='Reference angle camera'; scene.camera=camera
camera.data.type='ORTHO'; camera.data.ortho_scale=5.1
def aim(target):
 camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
aim((0,0,1.0))
sc.hide_render=True
scene.render.filepath=str(root/'source/assets/dtf-printer.png'); bpy.ops.render.render(write_still=True)
pc.hide_render=True; sc.hide_render=False
scene.render.filepath=str(root/'source/assets/dtf-shaker.png'); bpy.ops.render.render(write_still=True)
# Store the complete connected, editable assembly at real relative heights.
pc.hide_render=False
for o in so: o.location.y+=2.2
cube('Straight film between printer and rear shaker inlet',(0,.94,1.40),(2.67,.70,.028),'paper',0)
camera.location=(10,10,7.7); camera.data.ortho_scale=7.4; aim((0,1.25,1.1))
scene.render.filepath=str(root/'captures/dtf-model-line.png')
bpy.ops.wm.save_as_mainfile(filepath=str(root/'DTF-Line.blend'))
bpy.ops.render.render(write_still=True)
print('DTF_REFERENCE_GEOMETRY_COMPLETE')
