"""Read-only render validation; writes only the check report beside the review."""
import hashlib
import json
import math
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent
folder = root / 'rotations-v2'
manifest = json.loads((folder / 'rotation-manifest.json').read_text())
frames = manifest['frames']
assert len(frames) == 16
assert len({f['sha256'] for f in frames}) == 16
assert len({f['ortho_scale'] for f in frames}) == 1
assert abs(manifest['bounds'][0][2]) < .0001
assert hashlib.sha256((root / 'DTF-Reference-v2.blend').read_bytes()).hexdigest() == manifest['source_sha256']
rows = []
for i, frame in enumerate(frames):
    file = folder / frame['file']
    with Image.open(file) as im:
        assert im.size == (900, 900) and im.mode == 'RGBA'
        bounds = im.getchannel('A').getbbox()
        assert bounds and min(bounds[:2]) > 10 and max(bounds[2:]) < 890
    direction = frame['view_direction']
    angle = math.degrees(math.atan2(direction[0], direction[1])) % 360
    assert abs(angle - i * 22.5) < .001
    assert abs(math.degrees(math.asin(direction[2])) - 30) < .001
    assert hashlib.sha256(file.read_bytes()).hexdigest() == frame['sha256']
    rows.append({'angle': frame['azimuth_degrees'], 'alpha_bounds': bounds})
report = {'passed': True, 'checks': ['16 unique file hashes', 'exact 22.5-degree directions',
    'fixed 30-degree elevation', 'constant orthographic scale', '900x900 RGBA',
    'no clipped alpha bounds', 'assembly ground at zero', 'source hash matches'], 'frames': rows}
(root / 'rotation-check.json').write_text(json.dumps(report, indent=2))
print('PASS: 16 measured views, transparent bounds clear, source verified')
