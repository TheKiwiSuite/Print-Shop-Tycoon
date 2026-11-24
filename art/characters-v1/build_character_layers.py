"""Split the approved character sheet into tintable layers (no repainting).

Run with Blender's bundled Python (numpy), never touching the original:
  blender -b --factory-startup --python build_character_layers.py -- --sheet <owner-walk.png> --out <folder>

For each region (skin, hair, cap, shirt, overalls) the script writes a PNG the
same size as the sheet: grayscale shading of that region's pixels only, with the
original alpha, everywhere else transparent. The game draws the untouched sheet
first, then each layer tinted with a colour, so Sam keeps his exact look while
customers and staff get different skin tones, hair, caps and clothes.
Also writes preview.png with sample looks for review.
"""
import sys, json, argparse
from pathlib import Path
import bpy
import numpy as np

p = argparse.ArgumentParser()
p.add_argument('--sheet', required=True)
p.add_argument('--out', required=True)
a = p.parse_args(sys.argv[sys.argv.index('--') + 1:])
out = Path(a.out)
out.mkdir(parents=True, exist_ok=True)

img = bpy.data.images.load(a.sheet)
img.colorspace_settings.name = 'Non-Color'  # keep stored sRGB values untouched
W, H = img.size
px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)[::-1].copy()  # top-down
rgb, alpha = px[:, :, :3], px[:, :, 3]
mx, mn = rgb.max(axis=2), rgb.min(axis=2)
v = mx
s = np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0)
r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
d = np.maximum(mx - mn, 1e-6)
h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6.0
h = np.where(mx - mn < 1e-6, 0, h)
cy = (np.arange(H) % (H // 4)) / (H // 4)          # row position inside each cell, 0 top .. 1 feet
row = np.repeat(cy[:, None], W, axis=1)
solid = alpha > .2


def components_keep_large(mask, min_area):
    """Drop small blobs (eyes, brows) from a mask with a simple flood fill."""
    keep = np.zeros_like(mask)
    seen = np.zeros_like(mask)
    ys, xs = np.nonzero(mask)
    for y0, x0 in zip(ys, xs):
        if seen[y0, x0]:
            continue
        stack = [(y0, x0)]
        seen[y0, x0] = True
        pts = []
        while stack:
            y, x = stack.pop()
            pts.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        if len(pts) >= min_area:
            for y, x in pts:
                keep[y, x] = True
    return keep


regions = {}
regions['hat'] = solid & (h > .25) & (h < .48) & (s > .25) & (row < .45)
hair = solid & ((h < .13) | (h > .95)) & (s > .25) & (v < .50) & (row < .60)
regions['hair'] = components_keep_large(hair, 900)
regions['skin'] = components_keep_large(solid & ((h < .12) | (h > .96)) & (s > .24) & (s < .68) & (v > .55) & (row > .14) & (row < .86) & ~regions['hair'], 400)
regions['shirt'] = components_keep_large(solid & (s < .16) & (v > .62) & (row > .36) & (row < .66), 300)
regions['pants'] = solid & (h > .50) & (h < .68) & (s > .18) & (row > .38)

stats = {}
for name, m in regions.items():
    vals = v[m]
    ref = float(np.percentile(vals, 92)) if vals.size else 1.0
    gray = np.clip(v / max(ref, 1e-3), 0, 1)
    layer = np.zeros((H, W, 4), dtype=np.float32)
    layer[:, :, 0] = layer[:, :, 1] = layer[:, :, 2] = gray
    layer[:, :, 3] = np.where(m, alpha, 0)
    out_img = bpy.data.images.new('layer-' + name, W, H, alpha=True)
    out_img.colorspace_settings.name = 'Non-Color'
    out_img.pixels = layer[::-1].ravel().tolist()
    out_img.filepath_raw = str(out / ('character-%s.png' % name))
    out_img.file_format = 'PNG'
    out_img.save()
    stats[name] = {'pixels': int(m.sum()), 'reference_value': ref}
    print('LAYER', name, int(m.sum()), round(ref, 3), flush=True)

# Preview: twelve looks on the first walk frame of each facing row.
looks = [
    {}, {'skin': (.82, .6, .43), 'hair': (.18, .16, .16), 'hat': (.85, .18, .2), 'shirt': (1, .86, .3), 'pants': (.3, .3, .35)},
    {'skin': (.62, .42, .28), 'hair': (.2, .17, .16), 'hat': (.15, .25, .6), 'shirt': (.6, .85, 1), 'pants': (.75, .65, .45)},
    {'skin': (1, .86, .74), 'hair': (.92, .76, .45), 'hat': (.6, .3, .8), 'shirt': (1, .6, .75), 'pants': (.3, .5, .85)},
    {'skin': (.45, .3, .2), 'hair': (.12, .1, .1), 'hat': (1, .62, .1), 'shirt': (.55, .9, .7), 'pants': (.2, .2, .22)},
    {'skin': (.96, .76, .6), 'hair': (.6, .28, .14), 'hat': (.1, .55, .55), 'shirt': (.75, .75, .78), 'pants': (.7, .2, .25)},
]
cell = W // 4
board = np.zeros((cell * 2, cell * len(looks), 4), dtype=np.float32)
for i, look in enumerate(looks):
    for k, (rowi, col) in enumerate([(0, 0), (2, 1)]):
        tile = px[rowi * cell:(rowi + 1) * cell, col * cell:(col + 1) * cell].copy()
        for name, color in look.items():
            m = regions[name][rowi * cell:(rowi + 1) * cell, col * cell:(col + 1) * cell]
            gray = np.clip(v[rowi * cell:(rowi + 1) * cell, col * cell:(col + 1) * cell] / stats[name]['reference_value'], 0, 1)
            for c in range(3):
                tile[:, :, c] = np.where(m, gray * color[c], tile[:, :, c])
        board[k * cell:(k + 1) * cell, i * cell:(i + 1) * cell] = tile
bg = np.array([.86, .9, .84], dtype=np.float32)
comp = board[:, :, :3] * board[:, :, 3:4] + bg * (1 - board[:, :, 3:4])
prev = bpy.data.images.new('preview', board.shape[1], board.shape[0], alpha=False)
prev.colorspace_settings.name = 'Non-Color'
full = np.ones((board.shape[0], board.shape[1], 4), dtype=np.float32)
full[:, :, :3] = comp
prev.pixels = full[::-1].ravel().tolist()
prev.filepath_raw = str(out / 'preview.png')
prev.file_format = 'PNG'
prev.save()
(out / 'layers.json').write_text(json.dumps({'sheet': str(a.sheet), 'size': [W, H], 'regions': stats}, indent=2))
print('CHARACTER_LAYERS_DONE', flush=True)
