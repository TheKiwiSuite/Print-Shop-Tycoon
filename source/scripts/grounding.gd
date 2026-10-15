extends RefCounted

# Pixel positions on the artwork's soles, feet, or wheels. The centroid is the
# floor origin, rather than the bottom of the rectangular image canvas.
const ATLAS_CONTACTS = {
 0:[Vector2(59,248),Vector2(239,332),Vector2(322,286)],
 1:[Vector2(407,245),Vector2(582,316),Vector2(735,236)],
 2:[Vector2(799,267),Vector2(1038,346),Vector2(1130,297)],
 3:[Vector2(1183,270),Vector2(1415,358),Vector2(1496,325)],
 4:[Vector2(29,559),Vector2(245,669),Vector2(350,618)],
 5:[Vector2(472,580),Vector2(584,650),Vector2(709,594)],
 6:[Vector2(800,587),Vector2(1071,677),Vector2(1145,617)],
 7:[Vector2(1240,629),Vector2(1398,693),Vector2(1490,642)],
 8:[Vector2(212,996)],
 9:[Vector2(524,991),Vector2(601,1009)],
 10:[Vector2(902,996),Vector2(976,1008)],
 11:[Vector2(1244,955),Vector2(1373,977),Vector2(1465,868)]
}
# Blender camera projection of z=0 and actual caster contact heights. Coordinates
# are normalized to the transparent texture's used rectangle, not its canvas.
const PRINTER_ORIGIN = Vector2((384.0004-155)/462.0,(520.8281-119)/483.0)
const PRINTER_CONTACTS = [Vector2(503.2602,438.0474),Vector2(575.6679,468.2863),Vector2(192.3328,567.8968),Vector2(264.7405,598.1357)]
const PRINTER_OUTLET = Vector2((443.6303-155)/462.0,(344.594-119)/483.0)
const SHAKER_ORIGIN = Vector2((384.0004-110)/588.0,(520.8281-172)/462.0)
const SHAKER_CONTACTS = [Vector2(459.6026,416.5996),Vector2(618.2607,482.8585),Vector2(150.8049,545.5597),Vector2(309.4629,611.8185)]
const SHAKER_INLET = Vector2((283.9074-110)/588.0,(288.8367-172)/462.0)

static func atlas_contacts(index:int, region:Rect2) -> Array:
 var points=[]
 for pixel in ATLAS_CONTACTS[index]: points.append((pixel-region.position)/region.size)
 return points

static func atlas_origin(index:int, region:Rect2) -> Vector2:
 var result=Vector2.ZERO
 var contacts=atlas_contacts(index,region)
 # The left and right supports are opposite footprint corners; their midpoint
 # includes the hidden rear leg instead of biasing a three-leg centroid forward.
 if index in [2,3,4,5,6,7]: return (contacts[0]+contacts[2])*0.5
 for point in contacts: result+=point
 return result/contacts.size()

static func texture_origin(kind:String) -> Vector2:
 return PRINTER_ORIGIN if kind=="dtf" else SHAKER_ORIGIN

static func texture_contacts(kind:String) -> Array:
 var points=[]
 var crop=Rect2(155,119,462,483) if kind=="dtf" else Rect2(110,172,588,462)
 var contacts=PRINTER_CONTACTS if kind=="dtf" else SHAKER_CONTACTS
 for pixel in contacts: points.append((pixel-crop.position)/crop.size)
 return points

static func rect_at(floor:Vector2, size:Vector2, origin:Vector2, flipped:bool=false) -> Rect2:
 if flipped: origin.x=1.0-origin.x
 return Rect2(floor-size*origin,size)

static func point_at(floor:Vector2, size:Vector2, origin:Vector2, point:Vector2, flipped:bool=false) -> Vector2:
 var delta=(point-origin)*size
 if flipped: delta.x=-delta.x
 return floor+delta
