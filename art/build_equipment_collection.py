"""Editable equipment models using the approved DTF materials and render finish.
Run a fresh Blender process with --kind ID. Never modifies gameplay assets.
Reference: existing shop-atlas.png and the user's expanded shop illustration.
"""
import sys, math, argparse, json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import equipment_geometry as g
from equipment_geometry import bpy, Vector, box, cylinder, tube, ring, extrude, screw, wheel, material, finish, M, scene

parser=argparse.ArgumentParser();parser.add_argument('--kind',required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
KIND=args.kind
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'equipment-review-v1'/KIND;OUT.mkdir(parents=True,exist_ok=True)
g.active.name='Equipment assembly'
for n,c,metal,rough in [('wood',(.64,.32,.095),0,.38),('woodedge',(.85,.48,.16),0,.35),('cardboard',(.50,.27,.105),0,.65),('tape',(.78,.59,.32),0,.38),('leaf',(.09,.39,.018),0,.4),('leaflight',(.30,.62,.025),0,.42),('navy',(.016,.06,.15),0,.5),('mintplastic',(.20,.66,.40),.08,.32),('screen',(.012,.045,.08),.1,.23),('orange',(.93,.19,.012),.05,.35)]: material(n,c,metal,rough)
# Fine directional wood grain, kept subtle at gameplay size.
nodes=M['wood'].node_tree.nodes;links=M['wood'].node_tree.links
tex=nodes.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=6;tex.inputs['Detail'].default_value=2
mapping=nodes.new('ShaderNodeVectorMath');mapping.operation='MULTIPLY';mapping.inputs[1].default_value=(2,45,3)
coords=nodes.new('ShaderNodeTexCoord');links.new(coords.outputs['Generated'],mapping.inputs[0]);links.new(mapping.outputs[0],tex.inputs['Vector'])
ramp=nodes.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.18;ramp.color_ramp.elements[0].color=(.42,.19,.047,1);ramp.color_ramp.elements[1].position=.82;ramp.color_ramp.elements[1].color=(.8,.44,.14,1)
links.new(tex.outputs['Fac'],ramp.inputs[0]);links.new(ramp.outputs[0],nodes.get('Principled BSDF').inputs['Base Color'])

def text(label,loc,size=.07,color='black',rot=(0,0,0)):
    curve=bpy.data.curves.new('Label '+label,'FONT');curve.body=label;curve.size=size;curve.extrude=.0005;curve.align_x='CENTER'
    ob=bpy.data.objects.new('Label '+label,curve);g.active.objects.link(ob);ob.location=loc;ob.rotation_euler=rot;ob.scale.x=-1;curve.materials.append(M[color]);return ob

def plank(name,loc,size):return box(name,loc,size,'wood',.025)
def table(w=2.4,d=1.25,h=.94,metal=False):
    plank('Solid maple worktop',(0,0,h),(w,d,.13))
    for x in [-w/2+.09,w/2-.09]:
        for y in [-d/2+.09,d/2-.09]:
            box('Bench leg',(x,y,(h-.06)/2),(.105,.105,h-.06),'black' if metal else 'wood',.014)
            box('Floor-contact foot',(x,y,.025),(.12,.12,.05),'rubber',.009)
            screw('Bench corner bolt',(x,y+d*.055,h-.16),'Y',r=.013)
    plank('Lower storage shelf',(0,0,.22),(w-.10,d-.13,.085))
    for y in [-d/2+.08,d/2-.08]:box('Apron rail',(0,y,h-.14),(w-.08,.06,.15),'woodedge',.013)
    for x in [-w/2+.08,w/2-.08]:box('Shelf side frame',(x,0,.25),(.06,d-.08,.10),'black' if metal else 'woodedge',.01)
    return h+.065

def carton(x,y,z,w=.36,d=.32,h=.29):
    box('Corrugated shipping box',(x,y,z+h/2),(w,d,h),'cardboard',.012)
    box('Box lid joint',(x,y,z+h+.001),(.006,d-.012,.002),'wood',0)
    box('Packing tape top',(x,y,z+h+.003),(.065,d+.002,.004),'tape',.001)
    box('Packing tape face',(x,y+d/2+.003,z+h*.72),(.065,.004,h*.55),'tape',.001)
    box('Shipping label',(x+w*.20,y+d/2+.005,z+h*.54),(w*.29,.004,h*.23),'paper',.001)
    for k in range(5):box('Parcel barcode',(x+w*.10+k*w*.035,y+d/2+.009,z+h*.53),(.004,.003,h*.11),'black',0)

def stack(x,y,z,w=.45,d=.34,n=9,mat='paper'):
    for j in range(n):box('Stacked sheets',(x+(j%3)*.002,y,z+j*.011+.005),(w,d,.009),mat,.004)

def bottle(x,y,z,c='cyan',s=1):
    cylinder('Ink bottle body',(x,y,z+.11*s),.058*s,.22*s,c)
    cylinder('Ink bottle shoulder',(x,y,z+.24*s),.043*s,.045*s,c)
    cylinder('Ink bottle neck',(x,y,z+.277*s),.026*s,.035*s,c)
    cylinder('Ink bottle cap',(x,y,z+.30*s),.030*s,.025*s,'black')
    box('Ink bottle label',(x,y+.059*s,z+.15*s),(.065*s,.004,.10*s),'paper',.004)

def roll(x,y,z,h=.6,r=.07,c='paper',axis='Z'):
    cylinder('Material roll',(x,y,z+h/2 if axis=='Z' else z),r,h,c,axis)
    end=(x,y,z+h+.003) if axis=='Z' else ((x+h/2+.003,y,z) if axis=='X' else (x,y+h/2+.003,z))
    cylinder('Cardboard roll core',end,r*.43,.009,'cardboard',axis)
    cylinder('Dark hollow roll core',tuple(v+(.005 if i=={'Z':2,'X':0,'Y':1}[axis] else 0) for i,v in enumerate(end)),r*.28,.010,'black',axis)

def plant(x,y,z,s=.8):
    cylinder('Glazed plant pot',(x,y,z+.095*s),.12*s,.19*s,'gold')
    cylinder('Pot soil',(x,y,z+.192*s),.109*s,.008,'cardboard')
    for i in range(9):
        a=i*2.399;ex=x+math.cos(a)*.18*s;ey=y+math.sin(a)*.18*s;ez=z+(.29+(i%3)*.06)*s
        tube('Plant stem',[(x,y,z+.18*s),(ex,ey,ez)],.008*s,'leaf')
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=(ex,ey,ez))
        o=bpy.context.object;o.scale=(.065*s,.12*s,.035*s);o.rotation_euler=(.3,(-.3+i*.05),a);finish(o,'Glossy leaf','leaflight' if i%3 else 'leaf')

def binbox(x,y,z,w=.45,d=.38,h=.29):
    box('Storage tub',(x,y,z+h/2),(w,d,h),'gray',.025)
    box('Tub lid',(x,y,z+h),(w+.025,d+.025,.035),'black',.014)
    box('Tub front label',(x,y+d/2+.004,z+h*.55),(w*.5,.008,h*.32),'paper',.005)
    box('Tub front handle',(x,y+d/2+.012,z+h*.82),(w*.32,.025,.035),'black',.006)

def atlas_material():
    mat=bpy.data.materials.new('Original shop illustration print artwork');mat.use_nodes=True
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ROOT.parent/'source/assets/shop-atlas.png'));tex.image.pack()
    shader=mat.node_tree.nodes.get('Principled BSDF');shader.inputs['Roughness'].default_value=.5
    mat.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color']);return mat
ART=atlas_material()
def art_quad(name,corners,region='stickers'):
    # Artwork sampled using quadrilateral UVs from existing illustration, no source edits.
    uv={'stickers':[(807,190),(858,215),(889,162),(833,142)],'banner':[(49,545),(240,643),(279,505),(81,444)]}[region]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(corners,[],[(0,1,2,3)]);mesh.update()
    o=bpy.data.objects.new(name,mesh);g.active.objects.link(o);mesh.materials.append(ART);layer=mesh.uv_layers.new()
    for i,(x,y) in enumerate(uv):layer.data[i].uv=(x/1536,1-y/1024)
    solid=o.modifiers.new('Media thickness','SOLIDIFY');solid.thickness=.002
    return o

def monitor(x,y,z,w=.62):
    box('Monitor foot',(x,y,z+.022),(w*.44,.25,.04),'black',.02)
    box('Monitor riser',(x,y-.025,z+.16),(.06,.06,.28),'black',.012)
    box('Monitor back shell',(x,y,z+.43),(w,.055,w*.66),'black',.025)
    box('Monitor blue screen',(x,y+.031,z+.43),(w-.045,.008,w*.66-.047),'screen',.008)
    # Visible layout panels, not illegible text.
    box('Application top bar',(x,y+.037,z+.43+w*.25),(w*.88,.003,.035),'teal',.002)
    box('Artwork canvas',(x-.04,y+.04,z+.43),(w*.45,.004,w*.40),'paper',.002)
    for j,c in enumerate(['cyan','magenta','yellow']):box('Artwork color swatch',(x-.14+j*.08,y+.045,z+.44),(.065,.003,.095),c,.008)
    for j in range(4):box('Properties row',(x+w*.33,y+.04,z+.50-j*.045),(w*.15,.004,.015),'gray',.001)
    box('Monitor rear vent',(x,y-.03,z+.43),(w*.55,.01,.08),'gray',.006)
    tube('Monitor power lead',[(x,y-.04,z+.28),(x+.10,y-.06,z+.10),(x+.22,y-.12,z+.005)],.009,'black')
    box('Keyboard base',(x,y+.37,z+.018),(.51,.18,.03),'black',.015)
    for row in range(4):
        for col in range(11):box('Keyboard key',(x-.223+col*.044,y+.31+row*.038,z+.037),(.033,.027,.008),'gray',.003)
    box('Mouse',(x+.37,y+.36,z+.028),(.09,.14,.055),'black',.034)

def tools_cup(x,y,z):
    cylinder('Tool cup',(x,y,z+.075),.062,.15,'black')
    for i,c in enumerate(['red','cyan','yellow','steel']):
        ob=cylinder('Bench pen',(x-.032+i*.021,y,z+.17),.007,.22,c);ob.rotation_euler.y=(i-1.5)*.1
    for dx in [-.025,.025]:ring('Scissor grip',(x+dx,y+.02,z+.26),.027,.007,'cyan','Y')

def tape_dispenser(x,y,z):
    box('Tape gun body',(x,y,z+.04),(.09,.23,.08),'red',.018)
    ring('Packing tape roll',(x,y-.03,z+.10),.060,.023,'tape','X')
    cylinder('Tape core',(x,y-.03,z+.10),.031,.07,'cardboard','X')
    box('Tape cutting blade',(x,y+.12,z+.08),(.12,.018,.025),'steel',.002)

def lower_supplies(z=.263):
    stack(-.72,.08,z,w=.46,d=.68,n=15)
    binbox(-.12,0,z,.45,.7,.29)
    carton(.47,.03,z,.44,.60,.32)
    carton(.93,.04,z,.28,.60,.27)

def sticker():
    z=table(metal=True)
    binbox(-.12,0,.263,.45,.7,.29)
    carton(.47,.03,.263,.44,.60,.32)
    carton(.93,.04,.263,.28,.60,.27)
    # Desktop mint printer with actual rear cover, media slot and side ventilation.
    x=-.51;y=-.12
    profile=[(y-.30,z+.04),(y-.30,z+.45),(y-.06,z+.50),(y+.28,z+.36),(y+.28,z+.06)]
    extrude('Desktop print-cut housing',x-.51,x+.51,profile,'mintplastic',.035)
    box('Printer ivory rear hood',(x,y-.13,z+.467),(.90,.30,.05),'white',.028)
    box('Printer feed mouth',(x,y+.291,z+.22),(.83,.022,.22),'black',.015)
    cylinder('Desktop silver guide',(x,y+.32,z+.28),.018,.84,'steel','X')
    for dx in [-.44,.44]:box('Printer end trim',(x+dx,y+.23,z+.25),(.12,.15,.36),'mintplastic',.035)
    box('Status display',(x-.44,y+.315,z+.38),(.06,.01,.055),'screen',.004)
    for dx in [-.32,-.16,0,.16,.32]:box('Pinch block',(x+dx,y+.31,z+.25),(.07,.05,.04),'gray',.004)
    for yy in range(5):box('Desktop side vents',(x+.516,y-.1+yy*.04,z+.21),(.005,.025,.085),'black',.002)
    box('Rear connection panel',(x,y-.309,z+.17),(.24,.012,.085),'black',.005)
    art_quad('Printed sticker output',[(x-.34,y+.71,z+.01),(x+.34,y+.71,z+.01),(x+.34,y+.32,z+.25),(x-.34,y+.32,z+.25)])
    for i,c in enumerate(['cyan','magenta','yellow','black','paper']):roll(.18+i*.17,-.40,z,.65,.067,c)
    box('Vinyl roll caddy',(0.53,-.40,z+.045),(.93,.19,.09),'woodedge',.01)
    art_quad('Cutting mat sticker sheet',[(.08,.49,z+.01),(.96,.49,z+.01),(.96,.02,z+.01),(.08,.02,z+.01)])
    tools_cup(1.03,-.04,z);ring('Masking tape',(.98,.29,z+.035),.07,.025,'tape')
    for i,c in enumerate(['cyan','magenta','yellow']):roll(-.76,-.28,.33+i*.14,.5,.067,c,'X')

def heat():
    z=table(w=2.45,d=1.3)
    stack(-.75,.03,.263,.6,.8,19);stack(0,.03,.263,.6,.8,17);binbox(.80,.02,.263,.55,.8,.28)
    x=-.56;y=-.05
    box('Heat press base',(x,y,z+.06),(.95,.79,.11),'black',.025)
    box('Silicone lower platen',(x,y+.10,z+.14),(.82,.60,.09),'rubber',.02)
    box('Open red heater',(x,y-.05,z+.36),(.90,.66,.12),'red',.035)
    box('Heater underside',(x,y-.05,z+.292),(.85,.62,.025),'steel',.012)
    for dx in [-.27,.27]:
        tube('Press lever linkage',[(x+dx,y-.29,z+.15),(x+dx,y-.30,z+.57),(x+dx,y-.02,z+.75)],.027,'black')
        cylinder('Hinge pin',(x+dx,y-.30,z+.37),.045,.07,'steel','X')
    tube('Heat press handle',[(x-.27,y-.02,z+.75),(x-.27,y+.19,z+.90),(x+.27,y+.19,z+.90),(x+.27,y-.02,z+.75)],.028,'black')
    cylinder('Pressure adjustment spindle',(x,y-.30,z+.52),.018,.24,'steel')
    cylinder('Pressure knob',(x,y-.30,z+.65),.05,.08,'black')
    box('Temperature control',(x+.42,y-.27,z+.43),(.20,.18,.23),'red',.018)
    box('Heat timer screen',(x+.42,y-.17,z+.46),(.145,.012,.07),'screen',.004)
    text('165',(x+.42,y-.161,z+.445),.045,'yellow',(math.pi/2,0,math.pi))
    for dx in [-.04,.04]:cylinder('Timer button',(x+.42+dx,y-.16,z+.385),.018,.014,'yellow','Y')
    # Distinct compact blue cap press.
    box('Cap press blue base',(.65,-.27,z+.07),(.57,.45,.14),'blue',.025)
    cylinder('Curved cap platen',(.65,-.19,z+.22),.14,.34,'black','X')
    box('Cap heater shell',(.65,-.28,z+.38),(.36,.28,.14),'blue',.04)
    tube('Cap press handle',[(.65,-.43,z+.20),(.65,-.43,z+.53),(.65,-.24,z+.66),(.65,-.06,z+.66)],.023,'black')
    box('Cap press controller',(.96,-.31,z+.24),(.14,.18,.26),'blue',.015)
    box('Cap display',(.96,-.211,z+.29),(.10,.008,.065),'screen',.004)
    for j in range(5):
        box('Folded shirt body',(.60,.34,z+.015+j*.025),(.56,.40,.025),'paper',.015)
        box('Folded shirt sleeve',(.91,.33,z+.015+j*.025),(.12,.20,.023),'paper',.014)
    ring('Shirt collar',(.60,.21,z+.143),.060,.012,'white')
    bottle(1.35,.43,0,'cyan',.85)

def artwork():
    z=table(w=2.2,d=1.2)
    monitor(-.22,-.23,z,.91);tools_cup(.87,-.36,z);plant(-.86,-.34,z,.65)
    stack(.73,.26,z,.36,.43,7)
    box('Pen tablet',(-.69,.26,z+.02),(.38,.30,.035),'gray',.02)
    box('Tablet active area',(-.69,.26,z+.041),(.32,.24,.004),'black',.005)
    tube('Tablet stylus',[(-.81,.15,z+.054),(-.57,.22,z+.054)],.009,'black')
    box('Tower computer',(.78,-.12,.493),(.32,.65,.46),'black',.025)
    for j in range(6):box('PC ventilation',(.78,.212,.56+j*.022),(.23,.006,.008),'gray',.002)
    cylinder('Computer power light',(.88,.22,.40),.012,.008,'cyan','Y')
    stack(-.65,0,.263,.58,.75,14);binbox(.02,0,.263,.47,.7,.26)

def finishing():
    z=table(w=2.4,d=1.25);lower_supplies()
    box('Self healing cutting mat',(-.18,.05,z+.008),(1.22,.79,.016),'teal',.008)
    for i in range(13):box('Mat grid vertical',(-.74+i*.092,.05,z+.018),(.002,.73,.001),'mint',0)
    for j in range(9):box('Mat grid horizontal',(-.18,-.31+j*.09,z+.018),(1.14,.002,.001),'mint',0)
    art_quad('Inspection sticker sheet',[(-.53,.28,z+.022),(.12,.28,z+.022),(.12,-.18,z+.022),(-.53,-.18,z+.022)])
    box('Steel cutting ruler',(-.18,.48,z+.02),(1.40,.046,.022),'steel',.004)
    for i in range(35):box('Ruler scale',(-.83+i*.038,.475,z+.033),(.003,.022,.002),'black',0)
    box('Trimmer guide rail',(.68,.0,z+.05),(.05,.80,.09),'steel',.009)
    box('Rotary cutter carriage',(.68,.20,z+.12),(.17,.13,.12),'orange',.035)
    stack(.93,-.11,z,.32,.62,12);tools_cup(-.96,.0,z)
    tube('Inspection lamp arm',[(-.92,-.40,z+.02),(-.92,-.40,z+.5),(-.58,-.20,z+.76)],.018,'black')
    cylinder('Lamp base',(-.92,-.40,z+.018),.12,.036,'black')
    box('Lamp shade',(-.51,-.16,z+.73),(.27,.18,.08),'gray',.025)
    box('Lamp diffuser',(-.51,-.16,z+.684),(.23,.14,.008),'paper',.005)

def packing():
    z=table(w=2.6,d=1.35);lower_supplies()
    carton(-.78,-.17,z,.55,.45,.38);carton(-.25,-.28,z,.43,.40,.32);carton(-.78,-.17,z+.38,.45,.39,.31)
    carton(.00,.31,z,.35,.31,.26)
    monitor(.50,-.33,z,.46)
    box('Label printer',(.99,.20,z+.10),(.31,.32,.20),'black',.035)
    box('Label printer lid',(.99,.18,z+.205),(.27,.25,.05),'gray',.02)
    box('Thermal label exit',(.99,.37,z+.08),(.23,.008,.03),'black',.002)
    box('Emerging shipping label',(.99,.43,z+.035),(.20,.16,.004),'paper',.001)
    tape_dispenser(-.40,.43,z);roll(1.43,-.30,.0,.74,.09,'paper');roll(1.64,-.30,.0,.65,.09,'paper')
    stack(.43,.44,z,.28,.25,4)

def storage():
    w=2.1;d=.70
    for x in [-w/2,w/2]:
        for y in [-d/2,d/2]:
            box('Powder coated upright',(x,y,1.08),(.07,.07,2.16),'black',.012)
            box('Shelf floor shoe',(x,y,.025),(.095,.095,.05),'rubber',.009)
            for zz in range(12):box('Shelf post adjustment slot',(x,y+.038,.23+zz*.15),(.016,.005,.032),'gray',.001)
    for z in [.13,.67,1.22,1.78]:
        plank('Maple rack shelf',(0,0,z),(w+.04,d+.06,.07))
        for y in [-d/2,d/2]:box('Shelf steel support',(0,y,z-.045),(w,.04,.065),'black',.008)
    for i,c in enumerate(['cyan','magenta','yellow','black','white']):bottle(-.80+i*.39,-.03,1.815,c,1.40)
    for i,c in enumerate(['cyan','magenta','yellow','black','white']):bottle(-.83+i*.16,.12,1.255,c,.75)
    for x in [.25,.56,.87]:roll(x,0,1.36,.46,.11,'paper','Y')
    for x in [-.81,-.49,-.17]:roll(x,0,.82,.48,.12,'paper','Y')
    carton(.36,-.03,.705,.47,.54,.39);carton(.84,-.03,.705,.36,.54,.32)
    binbox(-.61,0,.165,.68,.59,.32);binbox(.16,0,.165,.68,.59,.32);carton(.80,0,.165,.38,.52,.30)
    # Back cross braces and shelf structure stay present through rotation.
    tube('Rear cross brace A',[(-1.0,-.397,.18),(1.0,-.397,1.74)],.013,'steel')
    tube('Rear cross brace B',[(1.0,-.405,.18),(-1.0,-.405,1.74)],.013,'steel')

def banner():
    for x in [-1.38,1.38]:
        box('Printer pedestal',(x,-.05,.53),(.17,.22,.85),'black',.018)
        box('Printer T foot',(x,0,.15),(.24,.95,.12),'black',.025)
        for y in [-.36,.36]:wheel('Printer caster',x,y,.08)
    box('Rear brace',(0,-.09,.35),(2.78,.13,.12),'black',.015)
    profile=[(-.42,.97),(-.42,1.68),(-.17,1.76),(.30,1.60),(.40,1.04)]
    extrude('Blue roll-to-roll enclosure',-1.57,1.57,profile,'blue',.035)
    for x in [-1.39,1.39]:extrude('Black end housings',x-.12,x+.12,[(y+.01,z+.014) for y,z in profile],'black',.015)
    box('Long inspection panel',(0,.24,1.63),(2.35,.18,.012),'darkwindow',.016).rotation_euler.x=-.3
    box('Print opening',(0,.408,1.22),(2.70,.025,.30),'black',.012)
    cylinder('Silver transport roller',(0,.43,1.14),.055,2.75,'steel','X')
    for i in range(12):box('Pinch roller bracket',(-1.23+i*.224,.445,1.33),(.09,.05,.05),'gray',.008)
    art_quad('Sunset banner output',[(-1.21,.76,.20),(1.21,.76,.20),(1.21,.445,1.24),(-1.21,.445,1.24)],'banner')
    cylinder('Takeup silver roller',(0,.77,.19),.055,2.74,'steel','X')
    for x in [-1.32,1.32]:tube('Takeup mount',[(x,0,.35),(x,.77,.19)],.025,'black')
    box('Printer console',(1.49,.43,1.45),(.25,.12,.23),'blue',.018)
    box('Console screen',(1.49,.495,1.49),(.18,.008,.10),'screen',.004)
    for dx in [-.055,0,.055]:cylinder('Console buttons',(1.49+dx,.50,1.405),.015,.008,'yellow','Y')
    box('Ink reservoir rack base',(-.055,-.20,1.781),(1.01,.22,.078),'black',.012)
    box('Ink reservoir rack rear',(-.055,-.30,1.90),(1.01,.035,.22),'black',.009)
    for i,c in enumerate(['cyan','magenta','yellow','black']):bottle(-.40+i*.23,-.20,1.82,c,.73)
    box('Rear maintenance panel',(0,-.434,1.34),(2.54,.028,.40),'black',.012)
    for x in [-.8,.8]:
        for r in [.04,.07,.10]:ring('Rear cooling fan',(x,-.454,1.34),r,.004,'steel','Y')
    roll(0,-.35,.80,2.5,.095,'paper','X')

def cnc():
    w=3.1;d=2.15
    box('CNC enclosed base',(0,0,.55),(w,d,.84),'white',.035)
    for x in [-1.37,1.37]:
        for y in [-.9,.9]:
            cylinder('Adjustable CNC foot',(x,y,.055),.12,.11,'rubber')
            cylinder('CNC foot stem',(x,y,.155),.045,.17,'steel')
    box('Vacuum flatbed',(0,0,1.00),(2.87,1.93,.12),'black',.012)
    for x in range(18):
        for y in range(11):cylinder('Vacuum bed perforation',(-1.32+x*.156,-.83+y*.166,1.064),.009,.002,'gray',verts=8)
    for x in [-1.49,1.49]:
        box('Linear guide',(x,0,1.11),(.065,2.10,.06),'steel',.008)
        box('Gantry saddle',(x,-.33,1.20),(.19,.32,.23),'white',.018)
        box('Gantry upright',(x,-.33,1.42),(.17,.23,.45),'white',.025)
        for y in [-.40,-.26]:screw('Gantry bolts',(x+.098,y,1.3),'X',r=.016)
    box('Cross gantry',(0,-.33,1.59),(3.06,.22,.19),'steel',.018)
    box('Gantry dark rail',(0,-.205,1.59),(2.85,.045,.08),'black',.008)
    box('Tool carriage',(.38,-.16,1.54),(.35,.19,.36),'black',.02)
    cylinder('Cutting tool body',(.38,-.04,1.40),.065,.27,'steel')
    cylinder('Knife tool tip',(.38,-.04,1.22),.014,.10,'gold')
    box('Cable chain support tray',(0,-.43,1.70),(2.90,.13,.07),'black',.008)
    for i in range(17):
        box('Cable chain link',(-1.29+i*.145,-.43,1.77),(.13,.095,.09),'black',.012)
        cylinder('Cable chain pivot',(-1.29+i*.145,-.375,1.77),.016,.009,'yellow','Y')
    box('Rigid cutting panel',(-.05,.22,1.077),(2.28,1.19,.022),'woodedge',.007)
    for x in [-.80,-.05,.70]:
        for y in [-.08,.48]:
            # Four separate connected lines make the rectangular cut visible.
            tube('Panel cut contour',[(x-.28,y-.20,1.092),(x+.28,y-.20,1.092),(x+.28,y+.20,1.092),(x-.28,y+.20,1.092),(x-.28,y-.20,1.092)],.006,'wood')
    for x in [-.9,0,.9]:
        box('Front access panel',(x,1.086,.59),(.83,.02,.66),'white',.01)
        box('Cabinet vertical seam',(x+.43,1.10,.58),(.012,.005,.69),'gray',.001)
        box('Access panel handle',(x+.28,1.11,.68),(.035,.035,.14),'black',.009)
    box('Operator console',(1.64,.57,1.13),(.28,.40,.20),'white',.02)
    box('Operator LCD',(1.64,.57,1.237),(.22,.28,.01),'screen',.008)
    cylinder('Emergency stop',(1.64,.85,1.17),.04,.04,'red')
    for x in [-.7,.7]:box('Rear service grille',(x,-1.084,.58),(.46,.015,.26),'gray',.008)

def dock():
    # Current catalog art is a delivery truck; model it with an accessible rear bay.
    box('Truck ladder chassis',(0,0,.43),(1.30,3.15,.21),'black',.035)
    for y in [-1.04,.98]:
        cylinder('Truck axle',(0,y,.34),.065,1.54,'steel','X')
        for x in [-.74,.74]:
            cylinder('Truck tire',(x,y,.30),.30,.20,'rubber','X')
            cylinder('Truck wheel rim',(x+math.copysign(.105,x),y,.30),.19,.014,'steel','X')
            cylinder('Truck hub',(x+math.copysign(.119,x),y,.30),.085,.022,'black','X')
            for a in range(0,360,60):
                rad=math.radians(a);cylinder('Wheel lug',(x+math.copysign(.13,x),y+math.cos(rad)*.13,.30+math.sin(rad)*.13),.018,.014,'gray','X',12)
    # Cab faces +Y, cargo at rear -Y.
    cab=[(.52,.49),(.52,1.63),(.77,1.83),(1.33,1.75),(1.69,1.25),(1.71,.49)]
    extrude('White truck cab',-.76,.76,cab,'white',.055)
    # Sloped windshield sits on front cab roof plane.
    windshield=[(-.66,1.677,1.29),(.66,1.677,1.29),(.66,1.389,1.69),(-.66,1.389,1.69)]
    mesh=bpy.data.meshes.new('Windshield');mesh.from_pydata(windshield,[],[(0,1,2,3)]);mesh.update()
    o=bpy.data.objects.new('Dark blue windshield',mesh);g.active.objects.link(o);o.data.materials.append(M['darkwindow'])
    tube('Windshield rubber gasket',windshield+[windshield[0]],.012,'black')
    for x in [-.773,.773]:
        box('Cab side window',(x,1.00,1.43),(.015,.48,.36),'darkwindow',.04)
        box('Cab door panel',(x,1.02,.93),(.016,.76,.46),'white',.02)
        box('Door handle',(x+math.copysign(.018,x),.77,1.15),(.025,.12,.035),'black',.009)
        tube('Mirror arm',[(x,1.40,1.43),(x*1.22,1.44,1.43),(x*1.22,1.44,1.28)],.017,'black')
        box('Side mirror',(x*1.22,1.44,1.25),(.10,.07,.19),'black',.025)
        box('Side step',(x,1.03,.52),(.18,.58,.06),'steel',.014)
    box('Truck front grille',(0,1.732,.86),(.88,.025,.16),'black',.015)
    for z in [.81,.86,.91]:box('Grille chrome rail',(0,1.753,z),(.84,.015,.012),'steel',.003)
    box('Front bumper',(0,1.76,.57),(1.55,.13,.13),'white',.025)
    box('Front license plate',(0,1.835,.57),(.27,.008,.09),'navy',.003)
    for x in [-.60,.60]:
        box('Headlamp',(x,1.724,.96),(.25,.035,.15),'paper',.02)
        box('Amber indicator',(x,1.736,.84),(.17,.03,.055),'orange',.008)
    for x in [-.26,0,.26]:box('Roof clearance lamp',(x,1.18,1.82),(.065,.10,.038),'orange',.018)
    tube('Windshield wiper left',[(-.59,1.69,1.31),(-.16,1.51,1.55)],.012,'black')
    tube('Windshield wiper right',[(.1,1.69,1.31),(.53,1.51,1.55)],.012,'black')
    # Open rear cargo bay: enclosed roof and sides, open back at -1.75.
    plank('Cargo bed',(0,-.65,.61),(1.63,2.20,.13))
    for x in [-.83,.83]:
        box('Cargo side panel',(x,-.65,1.32),(.07,2.25,1.42),'white',.018)
        for y in [-1.76,.46]:box('Cargo corner extrusion',(x,y,1.34),(.09,.07,1.48),'steel',.012)
        box('Cargo side lower rail',(x,-.65,.68),(.085,2.24,.09),'steel',.008)
        for y in [-1.6,-1.2,-.8,-.4,0,.4]:screw('Cargo rail rivet',(x+math.copysign(.045,x),y,.69),'X',r=.011)
    box('Cargo front wall',(0,.46,1.31),(1.67,.07,1.40),'white',.02)
    box('Cargo roof',(0,-.66,2.035),(1.76,2.31,.095),'white',.025)
    box('Rolled rear shutter',(0,-1.76,1.91),(1.58,.12,.22),'steel',.012)
    for j in range(5):box('Rear shutter slat',(0,-1.83,1.83+j*.04),(1.55,.012,.005),'gray',.001)
    for x in [-.77,.77]:box('Rear tail lamp',(x,-1.81,.68),(.09,.035,.14),'red',.01)
    box('Rear loading step',(0,-1.91,.48),(1.55,.22,.07),'black',.015)
    for row,y in enumerate([-.05,-.65,-1.27]):
        for col,x in enumerate([-.44,.10,.52]):
            carton(x,y,.68,.43 if col<2 else .32,.48,.39)
            if not(row==2 and col==2):carton(x,y,1.07,.40 if col<2 else .30,.45,.34)
    carton(-.44,-.12,1.41,.40,.42,.32)

BUILDERS={'sticker':sticker,'heat':heat,'art':artwork,'finish':finishing,'pack':packing,'storage':storage,'banner':banner,'cnc':cnc,'dock':dock}
if KIND not in BUILDERS:raise ValueError(KIND)
BUILDERS[KIND]()
# Identical soft studio illumination and finish as the user-approved DTF model.
for name,loc,power,size in [('Large soft key',(-3,4,6),650,4.0),('Broad cool fill',(4,1,4),450,3.5),('Rear rim',(-1,-4,5),550,3.0)]:
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=loc;ob.rotation_euler=(Vector((0,0,1))-ob.location).to_track_quat('-Z','Y').to_euler()
scene.render.use_freestyle=False
bpy.context.view_layer.update()
# A shared floor root and model-local axes make later in-game pivots explicit.
root=bpy.data.objects.new(KIND+' floor anchor',None);scene.collection.objects.link(root);root.location=(0,0,0)
for ob in list(g.active.objects):ob.parent=root
# Align the source assembly with the front-view left/right arrangement in the
# illustration atlas, as in the approved DTF reconstruction. Never flip a frame.
root.scale.x=-1
bpy.context.view_layer.update()
scene['catalog_id']=KIND;scene['art_status']='candidate';scene['floor_anchor']=[0.0,0.0,0.0]
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(KIND+'.blend')))
print('EQUIPMENT_MODEL_BUILT',KIND,len(scene.objects),flush=True)
