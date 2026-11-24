STARTER EQUIPMENT ART - owner approved 2026-11-20

Vinyl cutter bench (2 x 1 tiles) and desktop DTF kit (3 x 1 tiles).

Method: editable Blender models built with the same helpers and material palette
as the approved equipment (../equipment_geometry.py), rendered in Blender 5.2
Eevee with banded cartoon shading and thick dark outlines. 16 views, 0-337.5
degrees in 22.5 degree steps, same camera convention as the approved sheets.
No AI repaint: these will look a little cleaner than the painted set.

Rebuild (short background run, about 30 seconds per machine):
  blender -b --factory-startup --python build_starter_equipment.py -- --kind cutter --out <new folder>

final/<kind>/<kind>.png         runtime sheet, copied unchanged to source/assets/equipment
final/<kind>/<kind>-hero.png    larger 45 degree view for review
final/<kind>/<kind>-manifest.json  frame regions, floor anchors and runtime metadata
final/<kind>/<kind>.blend       editable model
