"""Starter equipment art: vinyl cutter bench and desktop DTF bench.

Run in a fresh background Blender process (never touches gameplay assets):
  blender -b --factory-startup --python build_starter_equipment.py -- --kind cutter --out <new folder>

Builds an editable model with the same helpers/material palette as the approved
equipment (../equipment_geometry.py, ../build_equipment_collection.py), renders
16 views (0..337.5 degrees, 22.5 steps, same camera convention as
../render_measured_rotations.py) with a light cartoon finish (banded shading plus
thick dark outlines), and packs them into a 4x4 transparent sheet with the
region / floor-anchor metadata the game reads from source/assets/equipment.

These are candidates for owner approval, not approved art.
"""
import sys, math, json, argparse
from pathlib import Path
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import equipment_geometry as g
from equipment_geometry import bpy, Vector, box, cylinder, tube, ring, extrude, material, finish, M, scene
from bpy_extras.object_utils import world_to_camera_view
import numpy as np

p = argparse.ArgumentParser()
p.add_argument('--kind', required=True, choices=['cutter', 'dtfmini', 'mug', 'embroidery'])
p.add_argument('--out', required=True)
p.add_argument('--cell', type=int, default=320)
p.add_argument('--hero', type=int, default=640)
args = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
KIND = args.kind
OUT = Path(args.out).resolve()
OUT.mkdir(parents=True, exist_ok=True)
TILES = {'cutter': (2, 1), 'dtfmini': (3, 1), 'mug': (2, 1), 'embroidery': (2, 1)}[KIND]
g.active.name = 'Equipment assembly'

# Palette: same values as the approved collection, plus a few starter accents.
for n, c, metal, rough in [('wood', (.80, .42, .10), 0, .38), ('woodedge', (.92, .56, .17), 0, .35),
                           ('cardboard', (.50, .27, .105), 0, .65), ('tape', (.78, .59, .32), 0, .38),
                           ('mintplastic', (.20, .66, .40), .08, .32), ('screen', (.012, .045, .08), .1, .23),
                           ('orange', (.93, .19, .012), .05, .35), ('lilac', (.42, .22, .78), .05, .3),
                           ('matgreen', (.30, .72, .55), 0, .5), ('glow', (1.0, .45, .05), 0, .5),
                           ('powder', (.95, .95, .97), 0, .7), ('pink', (.95, .30, .55), 0, .35),
                           ('lime', (.30, .64, .035), .05, .3), ('lightmat', (.36, .64, .86), 0, .5),
                           ('navy', (.02, .05, .16), 0, .6), ('cutterwhite', (.93, .94, .93), .02, .3),
                           ('cmint', (.43, .80, .64), .02, .3), ('cmintdark', (.27, .60, .47), .02, .3)]:
    material(n, c, metal, rough)
# Subtle directional wood grain, as in the approved collection.
_wn = M['wood'].node_tree.nodes
_wl = M['wood'].node_tree.links
_tex = _wn.new('ShaderNodeTexNoise')
_tex.inputs['Scale'].default_value = 6
_tex.inputs['Detail'].default_value = 2
_mp = _wn.new('ShaderNodeVectorMath')
_mp.operation = 'MULTIPLY'
_mp.inputs[1].default_value = (2, 45, 3)
_co = _wn.new('ShaderNodeTexCoord')
_wl.new(_co.outputs['Generated'], _mp.inputs[0])
_wl.new(_mp.outputs[0], _tex.inputs['Vector'])
_rp = _wn.new('ShaderNodeValToRGB')
_rp.color_ramp.elements[0].position = .2
_rp.color_ramp.elements[0].color = (.66, .33, .07, 1)
_rp.color_ramp.elements[1].position = .8
_rp.color_ramp.elements[1].color = (.86, .48, .13, 1)
_wl.new(_tex.outputs['Fac'], _rp.inputs[0])
_wl.new(_rp.outputs[0], _wn.get('Principled BSDF').inputs['Base Color'])


def plank(name, loc, size):
    return box(name, loc, size, 'wood', .025)


def table(w=2.3, d=1.2, h=.94, metal=False):
    plank('Solid maple worktop', (0, 0, h), (w, d, .13))
    for x in [-w / 2 + .09, w / 2 - .09]:
        for y in [-d / 2 + .09, d / 2 - .09]:
            box('Bench leg', (x, y, (h - .06) / 2), (.105, .105, h - .06), 'black' if metal else 'wood', .014)
            box('Floor-contact foot', (x, y, .025), (.12, .12, .05), 'rubber', .009)
    plank('Lower storage shelf', (0, 0, .22), (w - .10, d - .13, .085))
    for y in [-d / 2 + .08, d / 2 - .08]:
        box('Apron rail', (0, y, h - .14), (w - .08, .06, .15), 'woodedge', .013)
    for x in [-w / 2 + .08, w / 2 - .08]:
        box('Shelf side frame', (x, 0, .25), (.06, d - .08, .10), 'black' if metal else 'woodedge', .01)
    return h + .065


def roll(x, y, z, h=.6, r=.07, c='paper', axis='Z'):
    cylinder('Material roll', (x, y, z + h / 2 if axis == 'Z' else z), r, h, c, axis)
    end = (x, y, z + h + .003) if axis == 'Z' else ((x + h / 2 + .003, y, z) if axis == 'X' else (x, y + h / 2 + .003, z))
    cylinder('Cardboard roll core', end, r * .43, .009, 'cardboard', axis)


def stack(x, y, z, w=.45, d=.34, n=9, mat='paper'):
    for j in range(n):
        box('Stacked sheets', (x + (j % 3) * .002, y, z + j * .011 + .005), (w, d, .009), mat, .004)


def binbox(x, y, z, w=.45, d=.38, h=.29):
    box('Storage tub', (x, y, z + h / 2), (w, d, h), 'gray', .025)
    box('Tub lid', (x, y, z + h), (w + .025, d + .025, .035), 'black', .014)
    box('Tub front label', (x, y + d / 2 + .004, z + h * .55), (w * .5, .008, h * .32), 'paper', .005)


def carton(x, y, z, w=.36, d=.32, h=.29):
    box('Corrugated shipping box', (x, y, z + h / 2), (w, d, h), 'cardboard', .012)
    box('Packing tape top', (x, y, z + h + .003), (.065, d + .002, .004), 'tape', .001)
    box('Shipping label', (x + w * .20, y + d / 2 + .005, z + h * .54), (w * .29, .004, h * .23), 'paper', .001)


def bottle(x, y, z, c='cyan', s=1):
    cylinder('Ink bottle body', (x, y, z + .11 * s), .058 * s, .22 * s, c)
    cylinder('Ink bottle shoulder', (x, y, z + .24 * s), .043 * s, .045 * s, c)
    cylinder('Ink bottle cap', (x, y, z + .285 * s), .030 * s, .04 * s, 'black')


def tools_cup(x, y, z):
    cylinder('Tool cup', (x, y, z + .075), .062, .15, 'black')
    for i, c in enumerate(['red', 'cyan', 'yellow', 'steel']):
        ob = cylinder('Weeding tool', (x - .032 + i * .021, y, z + .17), .008, .22, c)
        ob.rotation_euler.y = (i - 1.5) * .1


def decal(x, y, z, c, shape='star', s=.07):
    if shape == 'circle':
        cylinder('Finished vinyl decal', (x, y, z + .004), s, .008, c)
    else:
        verts = []
        for k in range(10):
            r = s if k % 2 == 0 else s * .45
            a = math.pi / 2 + k * math.pi / 5
            verts.append((x + r * math.cos(a), y + r * math.sin(a)))
        mesh = bpy.data.meshes.new('Finished vinyl star decal')
        v3 = [(vx, vy, z + .001) for vx, vy in verts] + [(vx, vy, z + .009) for vx, vy in verts]
        faces = [tuple(reversed(range(10))), tuple(range(10, 20))] + [(i, (i + 1) % 10, (i + 1) % 10 + 10, i + 10) for i in range(10)]
        mesh.from_pydata(v3, [], faces)
        mesh.update()
        o = bpy.data.objects.new('Finished vinyl star decal', mesh)
        g.active.objects.link(o)
        finish(o, 'Finished vinyl star decal', c)


def cutter():
    z = table(w=2.3, d=1.2)
    # The home cutter most crafters know: an all-mint shell with a pale base
    # strip, the lid standing open, a tool cup on the left tower, a dial on the
    # right tower and the front door folded down as a tray. No logos or names.
    x, y = -.28, -.02
    L = 1.08
    prof = [(y - .16, z + .02), (y - .16, z + .16), (y - .12, z + .22), (y + .12, z + .22), (y + .17, z + .15), (y + .17, z + .02)]
    extrude('Cutter mint body', x - L / 2 + .11, x + L / 2 - .11, prof, 'cmint', .03)
    box('Pale base strip', (x, y + .005, z + .03), (L - .02, .385, .05), 'cutterwhite', .012)
    for side in [-1, 1]:
        cx = x + side * (L / 2 - .06)
        box('Cutter end tower', (cx, y, z + .15), (.13, .37, .22), 'cmint', .05)
        box('Tower seam', (cx - side * .067, y, z + .15), (.008, .34, .19), 'cmintdark', .003)
    cylinder('Tool cup rim', (x - (L / 2 - .06), y - .03, z + .263), .046, .01, 'cmintdark')
    cylinder('Tool cup opening', (x - (L / 2 - .06), y - .03, z + .268), .034, .006, 'black')
    for k, c in enumerate(['gray', 'black']):
        ob = cylinder('Tool in cup', (x - (L / 2 - .06) - .012 + k * .024, y - .03, z + .305), .008, .11, c)
        ob.rotation_euler.y = (k - .5) * .25
    box('Open button', (x - (L / 2 - .06), y + .09, z + .266), (.05, .035, .012), 'cutterwhite', .008)
    cylinder('Smart dial', (x + (L / 2 - .06), y + .03, z + .272), .05, .024, 'cmint')
    ring('Dial grip ring', (x + (L / 2 - .06), y + .03, z + .274), .05, .008, 'gray')
    cylinder('Dial cap', (x + (L / 2 - .06), y + .03, z + .288), .03, .008, 'cutterwhite')
    lid = box('Open mint lid', (x, y - .215, z + .37), (.80, .028, .30), 'cmint', .014)
    lid.rotation_euler.x = math.radians(-14)
    box('Inner bed', (x, y + .02, z + .225), (.82, .26, .01), 'gray', .004)
    cylinder('Carriage rail', (x, y - .02, z + .26), .014, .80, 'steel', 'X')
    cylinder('Roller bar', (x, y + .11, z + .245), .012, .80, 'steel', 'X')
    box('Tool head', (x + .08, y + .02, z + .27), (.13, .09, .11), 'cutterwhite', .025)
    cylinder('Blade clamp', (x + .052, y + .07, z + .27), .017, .08, 'black')
    cylinder('Pen clamp', (x + .108, y + .07, z + .27), .017, .08, 'gray')
    box('Front door tray', (x, y + .34, z + .035), (.80, .32, .014), 'cmint', .008)
    # Light-grip mat carrying black heat-transfer vinyl with a weeded shirt design.
    box('Light-grip cutting mat', (x, y + .14, z + .05), (.62, .92, .01), 'lightmat', .005)
    box('Black heat-transfer vinyl', (x, y + .38, z + .057), (.46, .30, .005), 'black', .003)
    for k, (dx, dy) in enumerate([(-.13, .36), (0, .42), (.13, .36)]):
        decal(x + dx, y + dy, z + .061, 'cutterwhite', 'circle' if k == 1 else 'star', .05)
    # Folded T-shirts with a pressed vinyl design, ready for the heat press.
    for k in range(2):
        box('Folded T-shirt', (.42, .26, z + .03 + k * .055), (.40, .32, .05), 'navy' if k == 0 else 'cutterwhite', .02)
    decal(.42, .26, z + .115, 'pink', 'star', .07)
    # Vinyl roll rack at the back right.
    box('Roll rack base', (.62, -.36, z + .03), (.86, .32, .06), 'woodedge', .01)
    for i, c in enumerate(['cyan', 'magenta', 'yellow', 'black', 'paper', 'gold']):
        roll(.62, -.42 + (i % 2) * .12, z + .12 + (i // 2) * .13, .78, .058, c, 'X')
    for dx in [.21, 1.03]:
        box('Roll rack upright', (dx, -.36, z + .25), (.04, .32, .44), 'woodedge', .008)
    # Tools, transfer tape and finished decals at the front right.
    tools_cup(.94, .34, z)
    ring('Transfer tape roll', (.90, .04, z + .045), .075, .036, 'paper')
    cylinder('Transfer tape core', (.90, .04, z + .045), .04, .065, 'cardboard')
    # Lower shelf: vinyl sheets, a tub and a parcel.
    stack(-.70, .03, .263, .55, .7, 9, 'magenta')
    stack(-.70, .03, .37, .55, .7, 6, 'cyan')
    binbox(-.02, .0, .263, .5, .7, .29)
    carton(.66, .03, .263, .5, .6, .32)


def dtfmini():
    z = table(w=3.3, d=1.2, metal=True)
    # Desktop DTF printer: compact teal body with white-ink tanks and film output.
    x, y = -1.0, -.10
    prof = [(y - .26, z + .03), (y - .26, z + .36), (y - .14, z + .44), (y + .20, z + .42), (y + .26, z + .30), (y + .26, z + .05)]
    extrude('Desktop DTF printer body', x - .45, x + .45, prof, 'teal', .03)
    box('Printer black top cover', (x, y - .05, z + .445), (.78, .26, .04), 'black', .02)
    box('Printer window', (x, y + .10, z + .40), (.62, .10, .03), 'darkwindow', .01)
    box('Film output mouth', (x, y + .265, z + .16), (.70, .02, .06), 'black', .008)
    art = g.M.get('Original shop illustration print artwork')
    out = box('Printed transfer film', (x, y + .48, z + .015), (.56, .46, .006), 'paper', .002)
    out.rotation_euler.x = math.radians(4)
    for k, c in enumerate(['pink', 'cyan', 'yellow', 'orange']):
        box('Printed transfer artwork', (x - .18 + (k % 2) * .36, y + .40 + (k // 2) * .18, z + .022), (.20, .13, .004), c, .003)
    for k, c in enumerate(['cyan', 'magenta', 'yellow', 'black', 'paper']):
        box('Ink tank', (x + .52, y - .20 + k * .09, z + .15), (.08, .07, .24), c, .012)
    box('Ink tank frame', (x + .52, y + .0, z + .03), (.10, .50, .05), 'black', .01)
    box('Printer control panel', (x - .34, y + .22, z + .36), (.14, .05, .06), 'screen', .008)
    roll(x, y - .30, z + .52, .72, .05, 'paper', 'X')
    # Powder tray with a sheet in it and a scoop.
    tx, ty = -.12, .05
    box('Powder tray base', (tx, ty, z + .03), (.62, .48, .05), 'gray', .012)
    for dx, dy, sx, sy in [(-.30, 0, .03, .5), (.30, 0, .03, .5), (0, -.235, .62, .03), (0, .235, .62, .03)]:
        box('Powder tray wall', (tx + dx, ty + dy, z + .075), (sx, sy, .09), 'gray', .008)
    box('Hot-melt powder bed', (tx, ty, z + .065), (.55, .42, .02), 'powder', .01)
    box('Film sheet in powder', (tx - .03, ty + .02, z + .078), (.38, .28, .004), 'paper', .002)
    for k, c in enumerate(['pink', 'cyan']):
        box('Powdered print', (tx - .11 + k * .17, ty + .02, z + .082), (.13, .16, .004), c, .003)
    cylinder('Powder jar', (tx + .42, ty - .12, z + .11), .07, .2, 'powder')
    cylinder('Powder jar lid', (tx + .42, ty - .12, z + .22), .074, .03, 'cyan')
    sc = box('Powder scoop', (tx + .40, ty + .14, z + .03), (.18, .07, .03), 'cyan', .012)
    sc.rotation_euler.z = math.radians(30)
    # Small curing oven with a warm window.
    ox, oy = .92, -.06
    box('Curing oven body', (ox, oy, z + .21), (.66, .52, .40), 'black', .03)
    box('Curing oven door', (ox - .04, oy + .265, z + .21), (.50, .02, .30), 'gray', .01)
    box('Oven glow window', (ox - .04, oy + .278, z + .23), (.38, .01, .17), 'glow', .008)
    cylinder('Oven door handle', (ox - .04, oy + .30, z + .35), .015, .40, 'steel', 'X')
    box('Oven control strip', (ox + .27, oy + .27, z + .21), (.08, .02, .30), 'gray', .006)
    for k in range(3):
        cylinder('Oven dial', (ox + .27, oy + .29, z + .32 - k * .09), .025, .025, 'orange' if k == 0 else 'steel', 'Y')
    box('Oven top vent', (ox, oy - .05, z + .413), (.40, .20, .01), 'gray', .004)
    # Front of the bench: a stack of finished transfers and a sheet trimmer.
    stack(.05, .40, z, .44, .30, 6)
    for k, c in enumerate(['pink', 'cyan', 'yellow']):
        box('Finished transfer print', (-.07 + k * .12, .40, z + .072), (.10, .14, .004), c, .002)
    box('Sheet trimmer base', (.85, .36, z + .02), (.52, .34, .04), 'gray', .01)
    box('Trimmer cutting grid', (.83, .36, z + .043), (.44, .30, .004), 'matgreen', .002)
    arm = box('Trimmer blade arm', (.85, .20, z + .06), (.54, .04, .03), 'steel', .008)
    arm.rotation_euler.z = math.radians(-12)
    cylinder('Trimmer handle', (1.10, .17, z + .07), .025, .09, 'red', 'X')
    # Lower shelf: film roll, ink bottles, transfer stacks.
    roll(-1.15, .0, .37, 1.0, .09, 'paper', 'X')
    for k, c in enumerate(['cyan', 'magenta', 'yellow', 'black', 'paper']):
        bottle(-.25 + k * .15, .1, .263, c, .9)
    stack(.62, .03, .263, .55, .7, 12)
    carton(1.25, .05, .263, .40, .55, .30)


def cone(name, loc, r1, r2, depth, mat):
    bpy.ops.mesh.primitive_cone_add(vertices=20, radius1=r1, radius2=r2, depth=depth, location=loc)
    o = bpy.context.object
    for poly in o.data.polygons:
        poly.use_smooth = True
    return finish(o, name, mat, .003)


def ball(name, loc, radius, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=10, radius=radius, location=loc)
    o = bpy.context.object
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for poly in o.data.polygons:
        poly.use_smooth = True
    return finish(o, name, mat)


def mug_shape(x, y, z, body='cutterwhite', band='pink', s=1.0):
    cylinder('Mug body', (x, y, z + .06 * s), .05 * s, .12 * s, body)
    cylinder('Mug print band', (x, y, z + .06 * s), .052 * s, .06 * s, band)
    cylinder('Mug inside', (x, y, z + .121 * s), .042 * s, .004, 'gray')
    ring('Mug handle', (x + .06 * s, y, z + .06 * s), .032 * s, .009 * s, body, 'Y')


def cap_shape(x, y, z, c='navy', s=1.0):
    ball('Cap crown', (x, y, z + .035 * s), .085 * s, (1, 1, .78), c)
    box('Cap brim', (x, y + .085 * s, z + .012 * s), (.14 * s, .12 * s, .014), c, .006)
    cylinder('Cap button', (x, y, z + .102 * s), .012 * s, .01, 'cutterwhite')


def mug():
    """Mug and tumbler bench: a small sublimation printer and a clamp mug press."""
    z = table(w=2.3, d=1.2)
    # Sublimation printer at the back left with a printed sheet coming out.
    x, y = -.66, -.24
    box('Sublimation printer body', (x, y, z + .12), (.70, .44, .22), 'cutterwhite', .03)
    box('Printer top panel', (x, y - .04, z + .235), (.64, .30, .02), 'gray', .008)
    feed = box('Paper feed tray', (x, y - .23, z + .33), (.46, .02, .28), 'cutterwhite', .008)
    feed.rotation_euler.x = math.radians(18)
    box('Printer output slot', (x, y + .222, z + .09), (.54, .012, .045), 'black', .004)
    box('Printed transfer sheet', (x, y + .44, z + .012), (.46, .36, .006), 'paper', .002)
    for k, c in enumerate(['pink', 'cyan', 'yellow']):
        box('Mug wrap print', (x - .145 + k * .145, y + .44, z + .018), (.11, .27, .004), c, .002)
    box('Printer status light', (x + .28, y + .222, z + .17), (.03, .01, .02), 'cyan', .003)
    # Clamp-style mug press, large enough to read: base, heating wrap, red handle.
    px, py = .36, -.22
    box('Mug press base', (px, py, z + .05), (.62, .44, .10), 'black', .025)
    box('Mug press control box', (px - .19, py - .06, z + .21), (.22, .26, .22), 'black', .025)
    box('Mug press display', (px - .19, py + .072, z + .25), (.14, .008, .07), 'glow', .004)
    cylinder('Heating wrap', (px + .14, py, z + .23), .115, .24, 'gray', 'Y')
    cylinder('Heater band', (px + .14, py, z + .23), .119, .13, 'orange', 'Y')
    cylinder('Mug in the press', (px + .14, py, z + .23), .082, .28, 'cutterwhite', 'Y')
    handle = box('Press handle', (px + .14, py + .04, z + .43), (.05, .42, .045), 'red', .018)
    handle.rotation_euler.x = math.radians(-24)
    cylinder('Handle grip', (px + .14, py + .22, z + .52), .036, .13, 'black', 'X')
    # Finished mugs and a steel tumbler along the front.
    for k, c in enumerate(['pink', 'cyan', 'yellow', 'lilac']):
        mug_shape(-.02 + k * .22, .36, z, 'cutterwhite', c, 1.5)
    cylinder('Steel tumbler', (.92, .30, z + .16), .062, .32, 'steel')
    cylinder('Tumbler lid', (.92, .30, z + .33), .065, .025, 'black')
    cylinder('Tumbler print band', (.92, .30, z + .16), .065, .14, 'cmint')
    ring('Heat tape roll', (.95, -.08, z + .035), .07, .03, 'tape')
    # Lower shelf: boxed blanks.
    carton(-.72, .03, .263, .52, .6, .34)
    carton(-.10, .03, .263, .5, .6, .3)
    binbox(.62, .0, .263, .5, .7, .29)


def embroidery():
    """Single-head embroidery machine with a cap frame and a rack of thread."""
    z = table(w=2.3, d=1.2, metal=True)
    x, y, k = -.36, -.14, 1.35
    box('Embroidery machine base', (x, y, z + .06 * k), (.6 * k, .5 * k, .12 * k), 'cutterwhite', .03)
    box('Machine pillar', (x - .2 * k, y - .14 * k, z + .33 * k), (.18 * k, .2 * k, .44 * k), 'cutterwhite', .03)
    box('Machine arm', (x + .02 * k, y - .14 * k, z + .5 * k), (.62 * k, .2 * k, .16 * k), 'cutterwhite', .035)
    box('Sewing head', (x + .26 * k, y, z + .44 * k), (.2 * k, .26 * k, .26 * k), 'cutterwhite', .03)
    box('Head colour panel', (x + .26 * k, y + .132 * k, z + .47 * k), (.16 * k, .01, .16 * k), 'cmint', .004)
    box('Touch screen', (x - .2 * k, y - .03 * k, z + .47 * k), (.02, .16 * k, .12 * k), 'screen', .006)
    cylinder('Needle bar', (x + .26 * k, y + .06 * k, z + .27 * k), .008 * k, .12 * k, 'steel')
    cylinder('Cap driver', (x + .26 * k, y + .12 * k, z + .2 * k), .07 * k, .18 * k, 'gray', 'Y')
    cap_shape(x + .26 * k, y + .2 * k, z + .15 * k, 'navy', .95 * k)
    box('Stitched patch', (x + .26 * k, y + .2 * k, z + .245 * k), (.07 * k, .05 * k, .01), 'yellow', .004)
    # Thread stand behind the machine: six cones on steel pegs.
    box('Thread rack bar', (x + .05 * k, y - .34 * k, z + .62 * k), (.74 * k, .06, .03), 'gray', .008)
    for sx in (-.3, .4):
        cylinder('Thread rack post', (x + sx * k, y - .34 * k, z + .31 * k), .012, .62 * k, 'steel')
    for i, c in enumerate(['red', 'yellow', 'cmint', 'cyan', 'lilac', 'pink']):
        cx = x + (-.26 + i * .125) * k
        cone('Thread cone', (cx, y - .34 * k, z + .7 * k), .042 * k, .014 * k, .13 * k, c)
        cylinder('Thread peg', (cx, y - .34 * k, z + .66 * k), .006, .1 * k, 'steel')
    # Finished hats, a spare hoop and snips along the front and right.
    cap_shape(.52, .30, z, 'red', 1.35)
    cap_shape(.84, .32, z, 'cmint', 1.35)
    cap_shape(.68, .06, z, 'yellow', 1.35)
    ring('Spare hoop', (.96, -.28, z + .012), .1, .012, 'steel')
    tools_cup(1.0, -.02, z)
    # Lower shelf: boxed caps and backing rolls.
    carton(-.72, .03, .263, .5, .6, .32)
    roll(-.05, .05, .33, .7, .08, 'paper', 'X')
    binbox(.72, .0, .263, .5, .7, .29)


{'cutter': cutter, 'dtfmini': dtfmini, 'mug': mug, 'embroidery': embroidery}[KIND]()

# Curves and text become meshes so they can carry outlines.
bpy.ops.object.select_all(action='DESELECT')
for ob in list(g.active.objects):
    if ob.type in {'CURVE', 'FONT'}:
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        bpy.ops.object.convert(target='MESH')
        ob.select_set(False)

# ---------- cartoon finish ----------
def toonify(mat):
    if mat is None or not mat.use_nodes:
        return
    nt = mat.node_tree
    bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    out = next((n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL'), None)
    if bsdf is None or out is None:
        return
    base_in = bsdf.inputs['Base Color']
    if base_in.is_linked:
        color_socket = base_in.links[0].from_socket
    else:
        rgb = nt.nodes.new('ShaderNodeRGB')
        rgb.outputs[0].default_value = base_in.default_value
        color_socket = rgb.outputs[0]
    diff = nt.nodes.new('ShaderNodeBsdfDiffuse')
    diff.inputs['Color'].default_value = (1, 1, 1, 1)
    s2r = nt.nodes.new('ShaderNodeShaderToRGB')
    nt.links.new(diff.outputs[0], s2r.inputs[0])
    bw = nt.nodes.new('ShaderNodeRGBToBW')
    nt.links.new(s2r.outputs['Color'], bw.inputs[0])
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.interpolation = 'EASE'
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = .10, (.56, .56, .62, 1)
    els[1].position, els[1].color = .34, (.86, .86, .88, 1)
    e = els.new(.60)
    e.color = (1.06, 1.06, 1.04, 1)
    nt.links.new(bw.outputs[0], ramp.inputs[0])
    mul = nt.nodes.new('ShaderNodeMix')
    mul.data_type = 'RGBA'
    mul.blend_type = 'MULTIPLY'
    mul.inputs['Factor'].default_value = 1.0
    sock = {s.identifier: s for s in mul.inputs}
    nt.links.new(color_socket, sock['A_Color'])
    nt.links.new(ramp.outputs['Color'], sock['B_Color'])
    em = nt.nodes.new('ShaderNodeEmission')
    nt.links.new({s.identifier: s for s in mul.outputs}['Result_Color'], em.inputs['Color'])
    em.inputs['Strength'].default_value = 1.0
    if mat.name == 'glow':
        em.inputs['Strength'].default_value = 1.6
    nt.links.new(em.outputs[0], out.inputs['Surface'])


for mat in list(bpy.data.materials):
    toonify(mat)

outline = bpy.data.materials.new('Cartoon outline')
outline.use_nodes = True
onodes = outline.node_tree.nodes
for n in list(onodes):
    if n.type != 'OUTPUT_MATERIAL':
        onodes.remove(n)
oem = onodes.new('ShaderNodeEmission')
oem.inputs['Color'].default_value = (.012, .014, .022, 1)
outline.node_tree.links.new(oem.outputs[0], next(n for n in onodes if n.type == 'OUTPUT_MATERIAL').inputs['Surface'])
outline.use_backface_culling = True
# The outline shell must not shadow the object it surrounds.
outline.use_backface_culling_shadow = True
for ob in list(g.active.objects):
    if ob.type != 'MESH':
        continue
    dims = sorted(ob.dimensions)
    # Thin sheets and small decals get fine lines; large bodies get bold ones.
    thick = max(.004, min(.034, dims[0] * .6 + dims[1] * .04))
    ob.data.materials.append(outline)
    mod = ob.modifiers.new('Cartoon outline shell', 'SOLIDIFY')
    mod.thickness = thick
    mod.offset = 1.0
    mod.use_flip_normals = True
    mod.use_even_offset = True
    mod.use_rim = False
    mod.material_offset = len(ob.data.materials) - 1
    mod.material_offset_rim = len(ob.data.materials) - 1

# ---------- render ----------
for eng in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT'):
    try:
        scene.render.engine = eng
        break
    except TypeError:
        pass
try:
    scene.eevee.taa_render_samples = 16
except Exception:
    pass
scene.view_settings.view_transform = 'Standard'
scene.view_settings.exposure = 0
scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value = .15
sun_data = bpy.data.lights.new('Cartoon key sun', 'SUN')
sun_data.energy = 3.14
sun_data.angle = math.radians(8)
sun = bpy.data.objects.new('Cartoon key sun', sun_data)
scene.collection.objects.link(sun)

objs = [o for o in scene.objects if o.type == 'MESH']
pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
lo = Vector(tuple(min(p_[a] for p_ in pts) for a in range(3)))
hi = Vector(tuple(max(p_[a] for p_ in pts) for a in range(3)))
center = (lo + hi) / 2
radius = max((p_ - center).length for p_ in pts)
cam_data = bpy.data.cameras.new('Starter equipment camera')
cam = bpy.data.objects.new('Starter equipment camera', cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
cam_data.type = 'ORTHO'
cam_data.ortho_scale = radius * 2.25
cam_data.clip_start = .001
cam_data.clip_end = radius * 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.resolution_percentage = 100
floor_point = Vector((center.x, center.y, 0.0))


def place(az_deg, size):
    az = math.radians(az_deg)
    el = math.radians(30)
    d = Vector((math.sin(az) * math.cos(el), math.cos(az) * math.cos(el), math.sin(el)))
    cam.location = center + d * radius * 6
    cam.rotation_euler = (center - cam.location).to_track_quat('-Z', 'Y').to_euler()
    # Key light stays fixed relative to the viewer: upper left, slightly in front.
    key = Vector((math.sin(az + math.radians(50)), math.cos(az + math.radians(50)), 1.6)).normalized()
    sun.rotation_euler = (-key).to_track_quat('-Z', 'Y').to_euler()
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    bpy.context.view_layer.update()
    a = world_to_camera_view(scene, cam, floor_point)
    return [a.x * size, (1 - a.y) * size]


frames_dir = OUT / 'frames'
frames_dir.mkdir(exist_ok=True)
cell = args.cell
sheet = np.zeros((cell * 4, cell * 4, 4), dtype=np.float32)
frames = []
for i in range(16):
    deg = i * 22.5
    anchor = place(deg, cell)
    path = frames_dir / ('angle-%03d-%05.1f.png' % (i, deg))
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(str(path))
    px = np.array(img.pixels[:], dtype=np.float32).reshape(cell, cell, 4)[::-1]
    bpy.data.images.remove(img)
    alpha = px[:, :, 3] >= .5
    ys, xs = np.nonzero(alpha)
    x0, x1, y0, y1 = int(xs.min()), int(xs.max()) + 1, int(ys.min()), int(ys.max()) + 1
    r, c = divmod(i, 4)
    sheet[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell] = px
    frames.append({'index': i, 'angle': deg, 'cell': [c * cell, r * cell], 'bbox': [x0, y0, x1 - x0, y1 - y0],
                   'floor_anchor_px': anchor, 'ortho_scale': cam_data.ortho_scale,
                   'touches_edge': bool(x0 == 0 or y0 == 0 or x1 == cell or y1 == cell)})
    print('STARTER_FRAME', KIND, i, deg, flush=True)

simg = bpy.data.images.new(KIND + '-sheet', cell * 4, cell * 4, alpha=True)
simg.pixels = sheet[::-1].ravel().tolist()
simg.filepath_raw = str(OUT / (KIND + '.png'))
simg.file_format = 'PNG'
simg.save()

# Hero view for the approval board.
place(45.0, args.hero)
scene.render.filepath = str(OUT / (KIND + '-hero.png'))
bpy.ops.render.render(write_still=True)

# Runtime metadata, same formula as cartoon-style-v1/prepare_game_assets.py.
tx, ty = TILES
unit = min(tx / (hi.x - lo.x), ty / (hi.y - lo.y))
scale = cam_data.ortho_scale / cell * unit * 48 * math.sqrt(2)
runtime = []
for f in frames:
    x0, y0, w, h = f['bbox']
    ax, ay = f['floor_anchor_px']
    runtime.append({'region': [f['cell'][0] + x0, f['cell'][1] + y0, w, h], 'size': [w * scale, h * scale],
                    'origin': [(ax - x0) / w, (ay - y0) / h], 'angle': f['angle']})
manifest = {'kind': KIND, 'tiles': [tx, ty], 'bounds': [list(lo), list(hi)], 'cell': cell,
            'frames': frames, 'runtime_frames': runtime, 'status': 'candidate - awaiting owner approval'}
(OUT / (KIND + '-manifest.json')).write_text(json.dumps(manifest, indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / (KIND + '.blend')))
print('STARTER_DONE', KIND, 'edge-touching frames:', sum(f['touches_edge'] for f in frames), flush=True)
