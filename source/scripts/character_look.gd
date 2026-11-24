extends RefCounted
# Visual variety for staff and customers, drawn from the approved character sheet.
# The sheet is drawn untouched, then tinted grayscale layers (skin, hair, cap,
# shirt, overalls; see art/characters-v1) are drawn over it. Sam keeps his exact
# look; everyone else gets a stable look derived from their id. No saved state.
const LAYERS=["skin","hair","hat","shirt","pants"]
const SKIN=[Color(1.0,.86,.74),Color(.96,.76,.6),Color(.82,.6,.43),Color(.62,.42,.28),Color(.45,.3,.2)]
const HAIR=[Color(.18,.16,.16),Color(.36,.24,.16),Color(.6,.28,.14),Color(.92,.76,.45),Color(.72,.72,.74),Color(.95,.5,.7),Color(.12,.1,.1)]
const HAT=[Color(.85,.18,.2),Color(.15,.25,.6),Color(.6,.3,.8),Color(1,.62,.1),Color(.1,.55,.55),Color(.2,.2,.22),Color(.95,.85,.25),Color(.95,.45,.6)]
const SHIRT=[Color(1,.86,.3),Color(.6,.85,1),Color(1,.6,.75),Color(.55,.9,.7),Color(.75,.75,.78),Color(.35,.35,.4),Color(1,1,1)]
const PANTS=[Color(.3,.3,.35),Color(.75,.65,.45),Color(.3,.5,.85),Color(.2,.2,.22),Color(.7,.2,.25),Color(.35,.55,.3),Color(.55,.4,.7)]
const BAGS=[Color("f4d35e"),Color("8fd3ff"),Color("ff9fc4"),Color("b7e4a3")]
static var textures={}

static func load_layers() -> void:
 if not textures.is_empty(): return
 for name in LAYERS:
  var path="res://assets/characters/character-%s.png" % name
  if ResourceLoader.exists(path): textures[name]=load(path)

# Stable look from a text seed. Staff keep their outfit's clothes (no pants
# layer); customers vary everything and sometimes carry a tote bag.
static func look(seed_text:String, customer:bool) -> Dictionary:
 var h=absi(seed_text.hash())
 var result={"skin":SKIN[h%SKIN.size()],"hair":HAIR[(h>>3)%HAIR.size()],"hat":HAT[(h>>6)%HAT.size()],"shirt":SHIRT[(h>>9)%SHIRT.size()],"scale":0.93+float((h>>12)%12)*0.01,"phase":float((h>>16)%628)/100.0}
 if customer:
  result["pants"]=PANTS[(h>>19)%PANTS.size()]
  if (h>>22)%3==0: result["bag"]=BAGS[(h>>24)%BAGS.size()]
 return result

static func draw(g, base:Texture2D, rect:Rect2, region:Rect2, look:Dictionary, skip:Array=[]) -> void:
 g.draw_texture_rect_region(base,rect,region,Color.WHITE)
 for name in LAYERS:
  if look.has(name) and textures.has(name) and name not in skip:
   g.draw_texture_rect_region(textures[name],rect,region,look[name])

# Facing row (0..3, same rule as the simulation) for a direction in grid space.
static func face_toward(direction:Vector2, current:int) -> int:
 if direction.length()<0.01: return current
 var sx=direction.x-direction.y
 var sy=direction.x+direction.y
 return (0 if sx<0 else 1) if sy>=0 else (2 if sx<0 else 3)

static func draw_bag(g, p:Vector2, face:int, color:Color, z:float) -> void:
 var side=-1.0 if face in [0,3] else 1.0
 var at=p+Vector2(19*side,-44)*z
 g.draw_line(at+Vector2(-4,-1)*z,at+Vector2(-1*side,-15)*z,g.NAVY,1.6*z)
 g.draw_line(at+Vector2(4,-1)*z,at+Vector2(-1*side,-15)*z,g.NAVY,1.6*z)
 g._panel(Rect2(at+Vector2(-7,-1)*z,Vector2(14,15)*z),color,g.NAVY,2)

# Small hand-held tool for the station being worked, moved by the task clock.
static func draw_tool(g, kind:String, hand:Vector2, t:float, z:float) -> void:
 match kind:
  "cutter","sticker","embroidery":
   # Weeding hook lifting vinyl.
   var tip=hand+Vector2(6+sin(t*5)*3,10)*z
   g.draw_line(hand,tip,g.NAVY,2.4*z)
   g.draw_arc(tip+Vector2(-2,0)*z,2.5*z,0,PI,6,g.NAVY,1.6*z)
   g.draw_rect(Rect2(hand+Vector2(-2,-3)*z,Vector2(5,6)*z),g.YELLOW)
  "heat","mug":
   # Peeling a warm transfer sheet.
   var lift=(sin(t*2.2)+1)*0.5
   g._poly([hand+Vector2(-9,4)*z,hand+Vector2(9,4)*z,hand+Vector2(9,4-10*lift)*z,hand+Vector2(-9,4-6*lift)*z],g.CREAM,g.BLUE,1)
  "pack","dock":
   # Tape gun sweeping across a box seam.
   var x=sin(t*3)*7
   g._panel(Rect2(hand+Vector2(-11,2)*z,Vector2(22,14)*z),Color("d5a467"),g.NAVY,2)
   g.draw_rect(Rect2(hand+Vector2(x-4,-6)*z,Vector2(8,7)*z),g.RED)
   g.draw_circle(hand+Vector2(x,-6)*z,3.2*z,Color("c9a46a"))
  "art":
   # Stylus on a tablet.
   g._panel(Rect2(hand+Vector2(-10,-1)*z,Vector2(20,14)*z),g.NAVY,g.BLUE,1)
   var pen=hand+Vector2(cos(t*3)*5,5+sin(t*3)*3)*z
   g.draw_line(pen,pen+Vector2(7,-9)*z,g.MAGENTA,2.2*z)
  "finish":
   # Magnifier sweeping over the output.
   var lens=hand+Vector2(sin(t*1.8)*6,2)*z
   g.draw_arc(lens,6*z,0,TAU,14,g.NAVY,2*z)
   g.draw_line(lens+Vector2(4,4)*z,lens+Vector2(9,9)*z,g.NAVY,2.4*z)
  _:
   # Printed film sheet gently flexing.
   var flex=sin(t*2.5)*2
   g._poly([hand+Vector2(-10,-6)*z,hand+Vector2(10,-6+flex)*z,hand+Vector2(10,8+flex)*z,hand+Vector2(-10,8)*z],g.CREAM,g.BLUE,1)
   for n in 3: g.draw_line(hand+Vector2(-7+n*6,-2)*z,hand+Vector2(-4+n*6,4)*z,[g.CYAN,g.MAGENTA,g.YELLOW][n],2*z)
