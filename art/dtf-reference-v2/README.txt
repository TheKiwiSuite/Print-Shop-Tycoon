DTF LINE - MEASURED ROTATION REVIEW

Status: user-approved artwork on October 16, 2026; not installed.
The original supplied images remain authoritative and unchanged.

Open index.html for the reference comparison, manual direction selection,
automatic rotation, and all 16 views. all-16-angles.png is the static sheet.

DTF-Reference-v2.blend is the editable Blender 5.2.1 model. It contains one
connected assembly and packed supplied crown artwork. Geometry was rebuilt
from the supplied front and side images; dimensions are relative estimates,
not manufacturer measurements. Unseen details are reconstructions.

Current render set: rotations-v2. Exact 22.5-degree camera steps, 30-degree
elevation, fixed orthographic scale, transparent 900x900 PNGs. All objects
stay fixed while the camera orbits. The script verifies mesh transforms.
rotations-v1 is a superseded internal check with misplaced hood fasteners;
it is not linked from the review. Earlier imagegen rotation sheets remain
rejected because their labeled directions were duplicated or inconsistent.

Rebuild source: ../build_reference_dtf_v2.py
Render tool: ../render_measured_rotations.py
Validation: check_rotations.py and review-check.cjs
Evidence: rotation-check.json, review-ui-check.json, rotation-render.log

No game code, executable, player save, or approved source sprite was replaced.
This DTF review is the first equipment milestone. The other equipment models,
game sprite pivots, rotated footprints/collision checks, and deployment remain
pending. A valid geometric turntable does not itself establish art approval.
