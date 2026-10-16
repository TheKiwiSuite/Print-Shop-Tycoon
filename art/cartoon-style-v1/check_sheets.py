"""Read-only analysis of imagegen sheets. Does not edit or export pixels."""
import hashlib,json
from collections import deque
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parent
guides=json.loads((root/'guide-manifest.json').read_text())
report={'method':'Read-only PNG and cell checks; uniqueness hashes do not certify correct camera angles. Visual comparison is also required.','engine_ready':False,'sets':[]}
for entry in guides:
    id=entry['id']; p=root/'sheets'/f'{id}.png'
    im=Image.open(p).convert('RGBA'); w,h=im.size
    a=im.getchannel('A'); cells=[]
    assert w==h, f'{id}: non-square sheet'
    assert a.getextrema()==(0,255), f'{id}: missing transparency'
    for i in range(16):
        col,row=i%4,i//4
        box=(round(col*w/4),round(row*h/4),round((col+1)*w/4),round((row+1)*h/4))
        cell=im.crop(box); alpha=cell.getchannel('A'); solid=alpha.point(lambda v:255 if v>=128 else 0)
        bounds=solid.getbbox(); assert bounds, f'{id}: empty cell {i}'
        cw,ch=cell.size
        touches=bounds[0]==0 or bounds[1]==0 or bounds[2]==cw or bounds[3]==ch
        cells.append({'index':i,'guide_angle_degrees':i*22.5,'bounds':list(bounds),'cell_size':[cw,ch],'touches_cell_edge':touches,'sha256':hashlib.sha256(cell.tobytes()).hexdigest()})
    assert len({c['sha256'] for c in cells})==16,f'{id}: exact duplicate cells'
    # Detect whole sprites rather than assuming generated layout is pixel-perfect.
    # This writes coordinates only; original PNG bytes remain untouched.
    mask=bytearray(1 if v>=128 else 0 for v in a.tobytes()); grouped=[[] for _ in range(16)]
    for start in range(w*h):
        if not mask[start]: continue
        mask[start]=0; todo=deque([start]); count=0; x0=w;y0=h;x1=y1=0; sx=sy=0
        while todo:
            pos=todo.pop(); y,x=divmod(pos,w);count+=1;sx+=x;sy+=y
            x0=min(x0,x);y0=min(y0,y);x1=max(x1,x+1);y1=max(y1,y+1)
            for nxt,valid in ((pos-1,x>0),(pos+1,x<w-1),(pos-w,y>0),(pos+w,y<h-1)):
                if valid and mask[nxt]:mask[nxt]=0;todo.append(nxt)
        if count>=4:
            col=min(3,int(sx/count/(w/4)));row=min(3,int(sy/count/(h/4)))
            grouped[row*4+col].append((x0,y0,x1,y1,count))
    regions=[]
    for i,parts in enumerate(grouped):
        assert parts, f'{id}: no sprite component {i}'
        x0=max(0,min(p[0] for p in parts)-3); y0=max(0,min(p[1] for p in parts)-3)
        x1=min(w,max(p[2] for p in parts)+3); y1=min(h,max(p[3] for p in parts)+3)
        regions.append({'index':i,'x':x0,'y':y0,'width':x1-x0,'height':y1-y0,'opaque_pixels':sum(p[4] for p in parts)})
    side=max(max(r['width'],r['height']) for r in regions)+12
    report['sets'].append({'id':id,'sheet':str(p.relative_to(root)),'size':[w,h],'rgba_transparency':True,'unique_pixel_cells':16,'integer_equal_cells':w%4==0,'edge_flags':[c['index'] for c in cells if c['touches_cell_edge']],'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'cells':cells,'regions':regions,'review_square_size':side})
report['set_count']=len(report['sets']);report['view_count']=16*report['set_count']
report['status']='art-review-candidates; not installed or game-ready'
(root/'quality-report.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'sets':report['set_count'],'views':report['view_count'],'edge_flags':{x['id']:x['edge_flags'] for x in report['sets'] if x['edge_flags']},'non_integer_cells':[x['id'] for x in report['sets'] if not x['integer_equal_cells']]}))
