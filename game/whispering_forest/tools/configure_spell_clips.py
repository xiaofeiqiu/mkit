"""Register eight reviewed poses; leave source PNGs and their alpha untouched.

Ground-based animation pivots are exported from the 3D model. The fire sprite
is an airborne sphere with a deliberately fixed explosion centre, and keeps
its authored small-to-large size rather than filling each frame's canvas.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / 'assets/combat-vfx'
pages=[]
for name,indices in [('fire-grow-32.png',[0,4,9,12]),('fire-fade-32.png',[3,7,11,15])]:
    image=Image.open(ROOT/name)
    assert image.mode=='RGBA'
    alpha=np.asarray(image)[:,:,3]
    regions=[];pivots=[]
    for index in indices:
        left,right=[round(x*image.width/4) for x in [index%4,index%4+1]]
        top,bottom=[round(y*image.height/4) for y in [index//4,index//4+1]]
        cell=alpha[top:bottom,left:right]
        # Reject a clipped/overlapping candidate rather than accepting a cut tip.
        assert max(cell[0,:].max(),cell[-1,:].max(),cell[:,0].max(),cell[:,-1].max())<25,(name,index)
        ys,xs=np.nonzero(cell>10)
        x0=max(0,int(xs.min())-2);x1=min(right-left,int(xs.max())+3)
        y0=max(0,int(ys.min())-2);y1=min(bottom-top,int(ys.max())+3)
        regions.append([left+x0,top+y0,x1-x0,y1-y0])
        pivots.append([(x1-x0)/2,(y1-y0)/2])
    pages.append(dict(file=name,columns=4,rows=4,count=4,source_indices=indices,
                      canvas=[320,320],regions=regions,pivots=pivots,
                      source_sha256=hashlib.sha256((ROOT/name).read_bytes()).hexdigest()))
manifest={'fire':dict(frame_count=8,pages=pages,times=[0,.15,.36,.65,1.05,1.40,1.85,2.4]),
          'wind':dict(frame_count=8,type='model_frames'),
          'ice':dict(frame_count=8,type='model_frames'),
          'earth':dict(frame_count=8,type='model_frames',variants=6),
          'ultimate':dict(frame_count=8,shares=['earth','fire'])}
(ROOT/'clips.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('WF_SPELL_CLIPS_OK: eight frames per clip; fixed model roots and unclipped fire key poses')
