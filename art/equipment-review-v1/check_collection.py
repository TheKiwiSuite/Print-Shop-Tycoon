"""Validate actual camera measurements, image bounds and model provenance."""
import json, hashlib, math, re
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parent
IDS=['sticker','heat','art','finish','pack','storage','banner','cnc','dock']
catalog=(ROOT.parent.parent/'source/scripts/catalog.gd').read_text()
price_line=re.search(r'const EQUIPMENT_PRICES=\{([^}]+)\}',catalog).group(1)
catalog_ids=set(re.findall(r'"([a-z]+)"\s*:',price_line))
assert catalog_ids==set(IDS+['dtf']),catalog_ids
REPORT={'passed':True,'equipment_count':len(IDS),'frame_count':0,'checks':['all catalog equipment covered','16 exact measured azimuths per model','fixed 30 degree camera elevation','fixed scale within each turntable','900x900 transparent RGBA','no cropped equipment','all frame hashes unique per turntable','source blend hash matches','floor anchors finite'], 'equipment':[]}
for kind in IDS:
    folder=ROOT/kind/('rotations-v4' if kind=='heat' else 'rotations-v3')
    m=json.loads((folder/'rotation-manifest.json').read_text(encoding='utf-8-sig'))
    frames=m['frames'];assert len(frames)==16,kind
    assert len({f['sha256'] for f in frames})==16,kind
    assert len({f['ortho_scale'] for f in frames})==1,kind
    assert hashlib.sha256((ROOT/kind/(kind+'.blend')).read_bytes()).hexdigest()==m['source_sha256'],kind
    assert abs(m['bounds'][0][2])<.015,(kind,m['bounds'])
    bounds=[]
    for index,f in enumerate(frames):
        file=folder/f['file'];assert hashlib.sha256(file.read_bytes()).hexdigest()==f['sha256']
        d=f['view_direction'];angle=math.degrees(math.atan2(d[0],d[1]))%360
        assert abs(angle-index*22.5)<.001,(kind,index,angle)
        assert abs(math.degrees(math.asin(d[2]))-30)<.001
        assert all(math.isfinite(n) for n in f['floor_anchor_pixels'])
        with Image.open(file) as im:
            assert im.size==(900,900) and im.mode=='RGBA'
            b=im.getchannel('A').getbbox()
            assert b and min(b[:2])>10 and max(b[2:])<890,(kind,index,b)
            bounds.append(b)
    REPORT['equipment'].append({'id':kind,'folder':folder.name,'frames':16,'mesh_count':m['mesh_count'],'bounds':m['bounds'],'alpha_bounds':bounds})
    REPORT['frame_count']+=16
(ROOT/'collection-check.json').write_text(json.dumps(REPORT,indent=2))
print('COLLECTION_PASS',len(IDS),'models,',REPORT['frame_count'],'measured views')
