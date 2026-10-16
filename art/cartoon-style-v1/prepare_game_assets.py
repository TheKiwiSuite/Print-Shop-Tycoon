"""Copy approved sheets intact and derive runtime atlas/ground calibration metadata."""
from pathlib import Path
from PIL import Image
import json,math,shutil
root=Path(__file__).resolve().parent
dest=root.parents[1]/'source/assets/equipment'
dest.mkdir(parents=True,exist_ok=True)
quality=json.loads((root/'quality-report.json').read_text())
guides={e['id']:e for e in json.loads((root/'guide-manifest.json').read_text())}
tiles={'dtf':(3,4),'sticker':(2,2),'heat':(2,2),'art':(2,1),'finish':(2,1),'pack':(3,2),'storage':(2,1),'banner':(3,2),'cnc':(4,3),'dock':(3,2)}
out={}
for entry in quality['sets']:
    id=entry['id']; manifestpath=(root/guides[id]['source_manifest']).resolve()
    manifest=json.loads(manifestpath.read_text(encoding='utf-8-sig'))
    lo,hi=manifest['bounds']; tx,ty=tiles[id]
    unit=min(tx/(hi[0]-lo[0]),ty/(hi[1]-lo[1]))
    frames=[]
    for i,region in enumerate(entry['regions']):
        src=Image.open(manifestpath.parent/manifest['frames'][i]['file']).convert('RGBA')
        bounds=src.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox()
        x0,y0,x1,y1=bounds; sw,sh=src.size
        ortho=manifest['frames'][i]['ortho_scale']
        floor=(sw/2,sh/2+manifest['target'][2]*math.cos(math.pi/6)*sh/ortho)
        origin=[(floor[0]-x0)/(x1-x0),(floor[1]-y0)/(y1-y0)]
        scale=ortho/sw*unit*48*math.sqrt(2)
        # Bounds mapping calibrates the painted frame against its measured source.
        frames.append({'region':[region['x'],region['y'],region['width'],region['height']],
                       'size':[(x1-x0)*scale,(y1-y0)*scale], 'origin':origin,'angle':i*22.5})
    shutil.copyfile(root/entry['sheet'],dest/f'{id}.png')
    out[id]={'frames':frames,'source_sha256':entry['sha256'],'approval':'User approved illustrated equipment on 2026-10-16'}
(dest/'equipment.json').write_text(json.dumps(out,indent=2))
print('PREPARED',len(out),'equipment sets, unchanged PNGs, 160 atlas regions')
