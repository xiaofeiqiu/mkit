"""Reference-driven city meshes. Blender edits; shared Godot stage final pixels.

Blender --background --python this_file -- --assets baker_house,wall_long,linden
Every asset is saved separately. This script does not touch the active city pack.
"""
import bpy
import math
import random
import json
import sys
import hashlib
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
BASELINE = json.loads((ROOT / 'baseline.json').read_text())
PROFILE = json.loads((ROOT / 'render-profile.json').read_text())
ARGS = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
SELECTED = ARGS[ARGS.index('--assets')+1].split(',') if '--assets' in ARGS else list(BASELINE)
BUCKETS = {}
MATS = {}
RNG = random.Random(1)

def srgb(v):
    return v/12.92 if v <= .04045 else ((v+.055)/1.055)**2.4

def rgba(value):
    return tuple(srgb(int(value[i:i+2],16)/255) for i in (0,2,4))+(1,)

def point(p):
    return (p[0],-p[2],p[1])

def material(role, color, texture=None):
    m = bpy.data.materials.new(role)
    m.use_nodes=True
    shader=m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=rgba(color)
    shader.inputs['Roughness'].default_value=.93
    shader.inputs['Specular IOR Level'].default_value=.08
    # Godot restores the same named base color with this painted texture. The
    # Blender preview retains the image as an editable node, and GLB embeds it.
    if texture:
        node=m.node_tree.nodes.new('ShaderNodeTexImage')
        node.image=bpy.data.images.load(str(ROOT/'materials'/texture),check_existing=True)
        m.node_tree.links.new(node.outputs['Color'],shader.inputs['Base Color'])
    MATS[role]=(m,color,texture)
    return role

def palette(roof):
    material('limestone','d5d0b9','limestone.png')
    material('limestone_light','e0dac8','limestone.png')
    material('limestone_dark','a3a590','limestone.png')
    material('mortar','9a9885')
    material('plaster','d0c5ad','limewash-weathered.png')
    material('plaster_edge','ddd1b6','limestone.png')
    material('plaster_undercoat','a99c84','limestone.png')
    material('exposed_stone','9e9e8b','limestone.png')
    material('oak','bc9870','oak.png')
    material('oak_dark','82664c','oak.png')
    material('roof',roof,'roof-mineral-painted.png')
    material('roof_edge','64716b','limestone.png')
    material('iron','3e4544')
    material('brass','b69350')
    material('glass','526864')
    material('glass_light','879b90')
    material('recess','343d37')
    material('cloth','e5d3ad')
    material('awning','a5533d')
    material('leaf','648b5b')
    material('leaf_dark','4b7055')
    material('flower','cdad98')
    material('bread','c69a5d')
    material('ember','e8a052')
    material('banner','516e88')

def poly(name,verts,faces,mat,tone=1,edge=0,grain=None):
    key=(name,mat,edge)
    bucket=BUCKETS.setdefault(key,{'v':[],'f':[],'tone':[],'grain':[]})
    offset=len(bucket['v'])
    bucket['v'] += [point(v) for v in verts]
    for face in faces:
        bucket['f'].append(tuple(offset+i for i in face))
        bucket['tone'].append(tone)
        bucket['grain'].append(point(grain) if grain is not None else None)

def box(name,at,size,mat='oak',edge=.018,tone=None):
    x,y,z=at;a,b,c=(v/2 for v in size)
    verts=[(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    grain=None
    if mat.startswith('oak'):
        longest=max(range(3),key=lambda i:size[i])
        grain=tuple(1 if i==longest else 0 for i in range(3))
    poly(name,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,tone or RNG.uniform(.90,1.04),edge,grain)

def beam(name,a,b,r,mat='oak',sides=8,r2=None):
    a,b=Vector(a),Vector(b);axis=(b-a).normalized()
    u=axis.cross(Vector((0,0,1)))
    if u.length<.01:u=axis.cross(Vector((1,0,0)))
    u.normalize();v=axis.cross(u).normalized()
    verts=[tuple(p+(u*math.cos(i*math.tau/sides)+v*math.sin(i*math.tau/sides))*(r if end==0 else (r2 if r2 is not None else r))) for end,p in enumerate((a,b)) for i in range(sides)]
    faces=[tuple(reversed(range(sides))),tuple(range(sides,sides*2))]+[(i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides)]
    poly(name,verts,faces,mat,RNG.uniform(.9,1.05),.007 if mat in ['oak','oak_dark'] else 0,tuple(axis) if mat.startswith('oak') else None)

def ellipsoid(name,at,radii,mat='leaf',rings=5,sides=10):
    verts=[]
    for j in range(rings+1):
        phi=math.pi*(.001+(1-.002)*j/rings)
        for i in range(sides):
            a=i*math.tau/sides
            verts.append((at[0]+math.sin(phi)*math.cos(a)*radii[0],at[1]+math.cos(phi)*radii[1],at[2]+math.sin(phi)*math.sin(a)*radii[2]))
    faces=[(j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i) for j in range(rings) for i in range(sides)]
    poly(name,verts,faces,mat)

def dressed_stone(name,at,size,tone):
    # Small unequal corners and a shallow dressed face catch daylight. These
    # are real surfaces; the block remains solid and fits its mortar course.
    x,y,z=at;a,b,c=(v/2 for v in size)
    verts=[]
    for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]:
        verts.append((x+sx*a+RNG.uniform(-.009,.009),y+sy*b+RNG.uniform(-.006,.006),z+sz*c+RNG.uniform(-.009,.009)))
    faces=[]
    for corners in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:
        center=sum((Vector(verts[i]) for i in corners),Vector())/4
        normal=(Vector(verts[corners[1]])-Vector(verts[corners[0]])).cross(Vector(verts[corners[2]])-Vector(verts[corners[0]])).normalized()
        center+=normal*RNG.uniform(.004,.017)
        middle=len(verts);verts.append(tuple(center))
        faces.extend((corners[i],corners[(i+1)%4],middle) for i in range(4))
    poly(name,verts,faces,'limestone',tone,.016)

def stone_courses(name,at,size,block=.48,row=.25):
    x,y,z=at;w,h,d=size
    # Mortar must sit behind the deepest worn face; otherwise it intersects
    # the shallow relief and hides parts of the stones as flat grey patches.
    box(name+' core',(x,y+h/2,z),(max(.025,w-.09),h,max(.025,d-.09)),'mortar',0,tone=1)
    count=math.ceil(h/row);rh=h/count
    for j in range(count):
        cuts=[-w/2];next_x=-w/2+block*(.5 if j%2 else 1)
        while next_x<w/2-.04:
            cuts.append(next_x);next_x+=block*RNG.uniform(.9,1.1)
        cuts.append(w/2)
        # Courses bond around the solid, including its side face. Stretching
        # one block through a long side wall produced visible horizontal bars.
        zcuts=[-d/2];next_z=-d/2+block*(1 if j%2 else .5)
        if d>.65:
            while next_z<d/2-.04:
                zcuts.append(next_z);next_z+=block*RNG.uniform(.9,1.1)
        zcuts.append(d/2)
        for ix,(a,b) in enumerate(zip(cuts,cuts[1:])):
            for iz,(za,zb) in enumerate(zip(zcuts,zcuts[1:])):
                if ix not in (0,len(cuts)-2) and iz not in (0,len(zcuts)-2):continue
                dressed_stone(name,(x+(a+b)/2,y+(j+.5)*rh,z+(za+zb)/2),(b-a-.018,rh-.018,zb-za-.018),RNG.uniform(.75,1.07))

def clip_surface_polygon(points,field,inside=True):
    """Clip a small facade cell against an irregular local plaster boundary."""
    result=[];sign=1 if inside else -1
    for a,b in zip(points,points[1:]+points[:1]):
        fa,fb=field(*a)*sign,field(*b)*sign
        if fa>=0:result.append(a)
        if (fa>=0)!=(fb>=0):
            left,right=0.,1.
            for i in range(12):
                t=(left+right)/2;q=(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t)
                if (field(*q)*sign>=0)==(fa>=0):left=t
                else:right=t
            t=(left+right)/2;result.append((a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t))
    return result

def plaster_facade(name,width,height,z,y0=0.58):
    # Centimetre-scale trowel relief plus a few real missing plaster patches.
    # Most wear lives in the painted surface. These local openings reveal a
    # recessed sandy coat and uneven stones, with solid chipped plaster rims.
    phase=RNG.random()*6.28
    patches=[(-width*.36,.26,.43,.30,phase),
             (width*.27,min(2.30,height*.52),.34,.25,phase+2.4),
             (-width*.09,height*.78,.26,.17,phase+4.1)]
    def patch_distance(x,y,p):
        dx=(x-p[0])/p[2];dy=(y-p[1])/p[3];a=math.atan2(dy,dx)
        return math.hypot(dx,dy)-1-.15*math.sin(a*5+p[4])-.085*math.sin(a*9-p[4])
    def field(x,y):return min(patch_distance(x,y,p) for p in patches)
    def relief(x,y):return .023+.013*math.sin(x*3.8+phase)*math.sin(y*3.1)+.006*math.sin(x*12.7+y*4.5)+.004*math.sin(y*21-x*9.1)
    box(name+' Sandy wall backing',(0,y0+height/2,z-.045),(width,height,.045),'plaster_undercoat',0,tone=1)
    vertices=[];faces=[];vertex_ids={}
    def add_vertex(p):
        key=tuple(round(a,6) for a in p)
        if key not in vertex_ids:vertex_ids[key]=len(vertices);vertices.append(p)
        return vertex_ids[key]
    nx=math.ceil(width/.10);ny=math.ceil(height/.10)
    for iy in range(ny):
        y=iy*height/ny;yy=(iy+1)*height/ny
        for ix in range(nx):
            x=-width/2+ix*width/nx;xx=-width/2+(ix+1)*width/nx
            polygon=clip_surface_polygon([(x,y),(xx,y),(xx,yy),(x,yy)],field)
            if len(polygon)<3:continue
            face=[add_vertex((px,y0+py,z+relief(px,py))) for px,py in polygon]
            # Triangles permit a gently uneven wall without twisting n-gons.
            faces += [(face[0],face[j],face[j+1]) for j in range(1,len(face)-1)]
    poly(name+' Wavy lime plaster surface',vertices,faces,'plaster',1)
    for patch in patches:
        # Recessed stones have varied ends and retain narrow mortar gaps.
        for row in range(5):
            low=patch[1]-patch[3]*1.25+row*patch[3]*.50
            high=low+patch[3]*.46
            for col in range(6):
                left=patch[0]-patch[2]*1.3+(col+.5*(row%2))*patch[2]*.48
                right=left+patch[2]*.44
                points=clip_surface_polygon([(left,max(0,low)),(right,max(0,low)),(right,min(height,high)),(left,min(height,high))],lambda x,y:patch_distance(x,y,patch),False)
                if len(points)<3 or high<=0 or low>=height:continue
                depth=RNG.uniform(-.014,-.001)
                vs=[(x,y0+y,z+dz) for dz in (-.035,depth) for x,y in points];n=len(points)
                fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
                poly(name+' Exposed rough masonry',vs,fs,'exposed_stone',RNG.uniform(.75,1.08),.012)
        # Actual edge thickness at the ragged plaster-to-stone boundary.
        rim=[]
        for i in range(72):
            a=i*math.tau/72
            radius=1+.15*math.sin(a*5+patch[4])+.085*math.sin(a*9-patch[4])
            rim.append((patch[0]+math.cos(a)*patch[2]*radius,patch[1]+math.sin(a)*patch[3]*radius))
        for a,b in zip(rim,rim[1:]+rim[:1]):
            if min(a[1],b[1])<0 or max(a[1],b[1])>height:continue
            poly(name+' Chipped plaster thickness',[(a[0],y0+a[1],z+relief(*a)),(b[0],y0+b[1],z+relief(*b)),(b[0],y0+b[1],z-.015),(a[0],y0+a[1],z-.015)],[(0,1,2,3)],'plaster_edge',RNG.uniform(.83,1.04))

def plaster_shell(width,depth,height):
    box('Solid wall under the lime coats',(0,(height+.58)/2,0),(width-.12,height-.58,depth-.12),'plaster_undercoat',.02)
    for side in range(4):
        before={k:len(v['v']) for k,v in BUCKETS.items()}
        plaster_facade('Facade %d'%side,width if side%2==0 else depth,height-.58,depth/2 if side%2==0 else width/2)
        rotate_new_geometry(before,side*math.pi/2)

def window(name,x,y,z,w=.9,h=1.32,shutters=True,flowers=False):
    box(name+' recess',(x,y+h/2,z),(w+.14,h+.12,.13),'recess',.012)
    box(name+' inset glass',(x,y+h/2,z+.05),(w,h,.035),'glass',0)
    for sx in (-1,1):box(name+' jamb',(x+sx*(w/2+.035),y+h/2,z+.14),(.085,h+.13,.13),'oak_dark')
    for dy in (0,h):box(name+' frame',(x,y+dy,z+.14),(w+.18,.11,.14),'oak')
    box(name+' sill',(x,y-.07,z+.13),(w+.29,.12,.32),'limestone_light',.025)
    for sx in (-1,1):box(name+' mullion',(x+sx*w/6,y+h/2,z+.15),(.025,h,.035),'oak')
    for dy in (.39,.83):box(name+' glazing bars',(x,y+dy*h,z+.16),(w,.025,.035),'oak_dark',.005)
    for dx in (-w*.30,w*.05):
        poly(name+' muted glass reflection',[(x+dx,y+.14,z+.151),(x+dx+.055,y+.14,z+.151),(x+dx+.11,y+h*.83,z+.151),(x+dx+.065,y+h*.83,z+.151)],[(0,1,2,3)],'glass_light',.75)
    if shutters:
        for sx in (-1,1):
            cx=x+sx*(w/2+.245)
            for plank in range(3):box(name+' shutter boards',(cx+(plank-1)*.10,y+h/2,z+.055),(.094,h,.09),'oak',.01)
            for dy in (.16,.80):box(name+' hinge straps',(cx,y+dy*h,z+.112),(.32,.035,.025),'iron',.004)
            beam(name+' shutter brace',(cx-.11,y+.22,z+.115),(cx+.11,y+h-.23,z+.115),.024,'oak_dark',4)
    if flowers:
        box(name+' flower trough',(x,y-.25,z+.24),(w+.22,.27,.32),'oak_dark')
        for i in range(9):
            at=(x+RNG.uniform(-w*.48,w*.48),y-.10+RNG.uniform(0,.1),z+RNG.uniform(.12,.39))
            leaf_spray(name+' window herbs',at,.18,12)
            if i%2==0:ellipsoid(name+' blossoms',(at[0],at[1]+.13,at[2]),(.055,.035,.055),'flower')

def door(name,x,z,w=1.08,h=2.35):
    box(name+' deep doorway',(x,h/2,z-.035),(w+.22,h+.17,.17),'recess',.02)
    for i in range(7):box(name+' oak door plank',(x-w/2+(i+.5)*w/7,h/2,z+.025),(w/7-.006,h,.08),'oak_dark',.008)
    for sx in (-1,1):
        stone_courses(name+' door jamb',(x+sx*(w/2+.115),0,z+.075),(.20,h+.12,.24),.5,.31)
    box(name+' door lintel',(x,h+.13,z+.08),(w+.54,.23,.34),'limestone_light',.035)
    for dy in (.43,1.73):box(name+' forged hinges',(x-w*.20,dy,z+.083),(w*.48,.055,.04),'iron',.01)
    beam(name+' handle pin',(x+w*.29,1.03,z+.08),(x+w*.29,1.03,z+.16),.032,'brass')
    # Ring, physically attached to the door.
    for i in range(12):
        a=i*math.tau/12;b=(i+1)*math.tau/12
        beam(name+' door ring',(x+w*.29+math.cos(a)*.055,.98+math.sin(a)*.075,z+.16),(x+w*.29+math.cos(b)*.055,.98+math.sin(b)*.075,z+.16),.011,'brass',6)
    box(name+' threshold',(x,.055,z+.13),(w+.60,.11,.45),'limestone_light',.027)

def roof(name,cx,y,cz,w,d,rise,mat='roof'):
    # Closed roof deck, then overlapping shallow slate/tile solids. Each row
    # follows the roof plane, with small controlled edge wear and tile overlap.
    v=[(cx-w/2,y,cz-d/2),(cx+w/2,y,cz-d/2),(cx+w/2,y,cz+d/2),(cx-w/2,y,cz+d/2),(cx-w/2,y+rise,cz),(cx+w/2,y+rise,cz)]
    poly(name+' roof deck',v,[(0,1,5,4),(4,5,2,3),(0,4,3),(1,2,5),(0,3,2,1)],'oak_dark')
    cols=max(5,round(w/.28));rows=max(4,round(math.hypot(d/2,rise)/.30))
    for side in (-1,1):
        for row in range(rows):
            t0=row/rows;t1=min(1,(row+1.18)/rows)
            cuts=[-w/2]+[-w/2+(i+(.5 if row%2 else 1))*w/cols for i in range(cols) if -w/2+(i+(.5 if row%2 else 1))*w/cols < w/2-.005]+[w/2]
            cuts=sorted(set(cuts))
            for left,right in zip(cuts,cuts[1:]):
                left+=.004;right-=.004
                lip=RNG.uniform(-.016,.012)
                verts=[]
                for lower in (0,.035):
                    for xx,t in [(left,t0),(right,t0),(right,t1),(left,t1)]:
                        verts.append((cx+xx,y+t*rise+.036+lower+(.008 if t==t0 else 0),cz+side*(d/2*(1-t)+lip*(1-t))))
                poly(name+' individual tiles',verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,RNG.uniform(.83,1.09),.008)
        beam(name+' carved eave',(cx-w/2,y-.035,cz+side*d/2),(cx+w/2,y-.035,cz+side*d/2),.095,'oak_dark',4)
    for side in (-1,1):
        xx=cx+side*w/2
        for zz in (-1,1):beam(name+' barge board',(xx,y-.035,cz+zz*d/2),(xx,y+rise+.10,cz),.080,'oak',4)
    for i in range(max(2,round(w/.30))):
        x=cx-w/2+(i+.5)*w/max(2,round(w/.30))
        beam(name+' ridge cap',(x-.155,y+rise+.06,cz),(x+.155,y+rise+.06,cz),.115,mat,8)

def leaf_spray(name,at,radius,count=35):
    for i in range(count):
        a=RNG.random()*math.tau;c=RNG.uniform(-1,1);s=math.sqrt(1-c*c)
        direction=Vector((s*math.cos(a),c,s*math.sin(a)))
        p=Vector(at)+direction*radius*RNG.uniform(.15,1)
        n=(direction+Vector((0,.65,0))).normalized()
        u=n.cross(Vector((0,0,1)))
        if u.length<.05:u=Vector((1,0,0))
        u.normalize();v=u.cross(n).normalized()
        length=RNG.uniform(.075,.14);width=length*RNG.uniform(.35,.60)
        points=[p-v*length,p-u*width,p+n*.012,p+v*length,p+u*width]
        poly(name,[tuple(q) for q in points],[(0,1,2),(1,3,2),(3,4,2),(4,0,2)],'leaf' if i%5 else 'leaf_dark',RNG.uniform(.85,1.08))

def finish(asset,record):
    for (name,role,edge),data in BUCKETS.items():
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata(data['v'],[],data['f']);mesh.update()
        if 'Wavy lime plaster surface' in name:
            for face in mesh.polygons:face.use_smooth=True
        obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
        obj.data.materials.append(MATS[role][0])
        obj['material_role']=role
        uv=mesh.uv_layers.new(name='Surface metres')
        colors=mesh.color_attributes.new(name='Material variation',type='FLOAT_COLOR',domain='CORNER')
        mesh.color_attributes.active_color_index=0
        mesh.color_attributes.render_color_index=0
        # Adding a corner colour layer reallocates Blender's CustomData. The
        # old UV RNA reference can then write into the colour buffer instead.
        # Reacquire both layers after allocation before filling either one.
        uv=mesh.uv_layers['Surface metres']
        colors=mesh.color_attributes['Material variation']
        for polyface,tone,grain in zip(mesh.polygons,data['tone'],data['grain']):
            axis=max(range(3),key=lambda i:abs(polyface.normal[i]))
            along=Vector(grain) if grain is not None else None
            across=polyface.normal.cross(along) if along is not None else None
            for loop in polyface.loop_indices:
                p=mesh.vertices[mesh.loops[loop].vertex_index].co
                axes=([1,2] if axis==0 else ([0,2] if axis==1 else [0,1]))
                if across is not None and across.length>.2:
                    uv.data[loop].uv=(p.dot(across.normalized())*.75,p.dot(along)*.45)
                elif role=='roof':
                    uv.data[loop].uv=(p[axes[0]]*1.3,p[axes[1]]*1.3)
                elif role=='plaster':
                    # One material repeat spans roughly three metres, so
                    # medium weathering survives actual gameplay downsampling.
                    uv.data[loop].uv=(p[axes[0]]*.32,p[axes[1]]*.32)
                else:
                    uv.data[loop].uv=(p[axes[0]]*.62,p[axes[1]]*.62)
                colors.data[loop].color=(tone,tone,tone,1)
        for polyface,tone in zip(mesh.polygons,data['tone']):
            sample=colors.data[polyface.loop_start].color
            assert all(abs(sample[i]-tone)<1e-5 for i in range(3)) and abs(sample[3]-1)<1e-5, (asset,name,'corrupt material colours')
        if edge:
            bevel=obj.modifiers.new('Small worn solid edges','BEVEL');bevel.width=edge;bevel.segments=2;bevel.limit_method='ANGLE';bevel.angle_limit=.65
            bevel.use_clamp_overlap=True
            normals=obj.modifiers.new('Weighted broad planes','WEIGHTED_NORMAL');normals.keep_sharp=True
    bpy.context.scene['reference_image']='codex-clipboard-ec4b9d39-2c40-4694-90ec-abe1e4089d89.png'
    bpy.context.scene['metres_per_unit']=1.0
    bpy.context.scene['final_render_config_source']='res://game/whispering_forest/art/city/render_config.gd'
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'editable'/f'{asset}.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'models'/f'{asset}.glb'),export_format='GLB',use_selection=False,export_apply=True,export_yup=True,export_extras=True)
    record=dict(record)
    record['geometry']=f'res://game/whispering_forest/art/city/reference-remake/models/{asset}.glb'
    record['blend']=f'res://game/whispering_forest/art/city/reference-remake/editable/{asset}.blend'
    record['materials']={k:{'color':v[1],'texture':v[2]} for k,v in MATS.items()}
    record['authoring_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    if record.get('structure_revision'):
        record['architecture_source']='res://game/whispering_forest/art/city/reference-remake/architecture_depth.py'
        record['architecture_sha256']=hashlib.sha256((ROOT/'architecture_depth.py').read_bytes()).hexdigest()
    return record

def chimney(x,z,y,h=1.7,w=.62):
    stone_courses('Chimney masonry',(x,y,z),(w,h,w),.30,.24)
    box('Chimney cap',(x,y+h+.06,z),(w+.16,.16,w+.16),'limestone_light',.024)
    box('Chimney dark throat',(x,y+h+.145,z),(w-.13,.025,w-.13),'recess',.008)

def awning(x,y,z,w,depth=1.0):
    strips=14
    for i in range(strips):
        left=x-w/2+i*w/strips;right=left+w/strips
        verts=[]
        for j in range(9):
            t=j/8
            for xx in (left,right):verts.append((xx,y-.27*t+.07*math.sin(t*math.pi),z+depth*t))
        faces=[(j*2,j*2+1,j*2+3,j*2+2) for j in range(8)]
        poly('Shop canvas canopy',verts,faces,'cloth' if i%2 else 'awning',RNG.uniform(.88,1.02))
        poly('Canopy scalloped valance',[(left,y-.27,z+depth),(right,y-.27,z+depth),(right,y-.41,z+depth),(left+w/strips*.5,y-.46,z+depth+.016),(left,y-.41,z+depth)],[(0,1,2,3,4)],'cloth' if i%2 else 'awning')
    for side in (-1,1):
        beam('Canopy support',(x+side*w/2,y+.02,z),(x+side*w/2,y-.28,z+depth),.027,'iron')
        beam('Canopy wall brace',(x+side*w/2,y-.72,z),(x+side*w/2,y-.29,z+depth*.92),.031,'oak_dark')

def shop_sign(x,y,z,kind):
    beam('Sign iron bracket',(x,y+.55,z-.45),(x,y+.55,z+.08),.025,'iron')
    for dx in (-.20,.20):beam('Sign suspension',(x+dx,y+.55,z),(x+dx,y+.22,z),.014,'iron')
    box('Carved sign board',(x,y,z),(.74,.53,.10),'oak_dark',.045)
    if kind=='baker_house':
        ellipsoid('Bread shop emblem',(x,y,z+.072),(.27,.105,.035),'bread')
        for dx in (-.12,0,.12):beam('Bread scoring',(x+dx-.035,y-.06,z+.109),(x+dx+.025,y+.06,z+.109),.012,'cloth',6)
    elif kind=='apothecary':
        beam('Herb emblem stem',(x,y-.16,z+.071),(x+.04,y+.15,z+.071),.013,'brass')
        for side in (-1,1):ellipsoid('Herb emblem leaves',(x+side*.10,y+.01,z+.08),(.105,.058,.016),'leaf')
    elif kind=='forge':
        box('Anvil sign',(x,y+.04,z+.07),(.44,.10,.04),'brass',.006)
        box('Anvil sign waist',(x,y-.065,z+.07),(.15,.15,.04),'brass',.006)
    else:
        # A hanging key is readable without a language-specific sign.
        beam('Inn key',(x-.13,y-.05,z+.072),(x+.14,y+.02,z+.072),.021,'brass')
        ellipsoid('Inn key bow',(x-.17,y-.045,z+.075),(.070,.075,.024),'brass')
        beam('Inn key tooth',(x+.09,y+.02,z+.075),(x+.09,y+.12,z+.075),.018,'brass')

def wall_timber(x,y,z,h,w,d):
    for sx in (-1,1):
        for sz in (-1,1):
            box('Corner timber posts',(x+sx*w/2,y+h/2,z+sz*d/2),(.14,h,.15),'oak_dark',.02)
    for dy in (y+.15,y+h-.05):
        for sz in (-1,1):box('Continuous timber sill',(x,dy,z+sz*d/2),(w+.16,.16,.15),'oak_dark')
        for sx in (-1,1):box('Side sill beam',(x+sx*w/2,dy,z),(.14,.16,d+.16),'oak_dark')

def balcony(cx,y,front,w):
    for j in range(6):box('Balcony floor planks',(cx,y,front+.15+j*.14),(w,.075,.13),'oak',.012)
    for x in (cx-w/2,cx+w/2):
        box('Balcony newel',(x,y+.50,front+.85),(.12,1.05,.12),'oak_dark')
        beam('Balcony knee brace',(x,y-1.0,front-.1),(x,y-.08,front+.65),.072,'oak_dark',4)
    for j in range(max(4,int(w/.25))):
        x=cx-w/2+.10+j*(w-.2)/(max(4,int(w/.25))-1)
        box('Balcony balusters',(x,y+.42,front+.85),(.055,.77,.065),'oak')
    box('Balcony handrail',(cx,y+.90,front+.85),(w+.15,.10,.14),'oak_dark')

def building(kind,record):
    lotx,lotz=[v/32 for v in record['footprint']]
    base=kind.split('_sage')[0].split('_clay')[0].split('_ash')[0].split('_mauve')[0]
    w=lotx-.46;d=lotz-.60;front=d/2
    two=base in ('baker_house','apothecary','inn','townhouse')
    wall_h=5.22 if two else 3.22
    rise=1.9 if two else 1.70
    if base=='guild':wall_h=6.7;rise=2.1
    if base=='forge':wall_h=3.32;rise=1.55
    if base=='market_hall':wall_h=3.30;rise=1.4
    # Broad occupied ground storey plus habitable roof storey; the eaves sit
    # below the attic ceiling. No tall stretched two-storey box silhouette.
    stone_courses('Stone footing',(0,0,0),(w+.16,.58,d+.15),.49,.25)
    if base=='market_hall':
        box('Market stone back wall',(0,1.2,-d*.43),(w,2.4,.24),'plaster')
        for x in (-w/2,0,w/2):
            for z in (-d/2,d/2):
                box('Market arcade posts',(x,wall_h/2,z),(.21,wall_h,.21),'oak_dark')
                beam('Market arcade knee brace',(x,wall_h-.80,z),(x+(.48 if x<=0 else -.48),wall_h-.15,z),.072,'oak',4)
        box('Market full arcade lintel',(0,wall_h-.08,front),(w+.22,.24,.24),'oak_dark')
    elif base=='forge':
        # Real open forge bay: front flanking piers and lintel leave a recess.
        stone_courses('Forge back wall',(0,.58,-d/2+.17),(w,wall_h-.58,.34),.44,.25)
        for side in (-1,1):
            stone_courses('Forge side walls',(side*(w/2-.18),.58,0),(.36,wall_h-.58,d),.48,.25)
        for side in (-1,1):stone_courses('Forge facade piers',(side*w*.39,.58,front),(w*.22,wall_h-.58,.34),.45,.25)
        stone_courses('Forge stone lintel',(0,2.8,front),(w,.52,.40),.52,.24)
        box('Dark forge interior',(0,1.6,-d*.12),(w*.70,2.1,.04),'recess')
        box('Raised hearth',(w*.22,.84,front-.60),(1.24,.48,.95),'limestone_dark')
        for i in range(18):ellipsoid('Banked forge coals',(w*.22+RNG.uniform(-.48,.48),1.10,front-.60+RNG.uniform(-.4,.3)),(.09,.045,.08),'ember')
        box('Anvil broad face',(-w*.16,1.05,front+.13),(.75,.14,.33),'iron')
        box('Anvil waist',(-w*.16,.86,front+.13),(.28,.31,.28),'iron')
        box('Anvil block',(-w*.16,.50,front+.13),(.50,.56,.47),'oak_dark')
    else:
        plaster_shell(w,d,wall_h)
        if base=='guild':
            for side in (-1,1):
                for x in (-w*.43,0,w*.43):stone_courses('Civic buttress',(x,.52,side*front),(.35,wall_h-.5,.40),.5,.34)
        else:
            wall_timber(0,.6,0,wall_h-.6,w,d)
            if two:
                for side in (-1,1):
                    box('Upper floor jetty',(0,3.26,side*(front+.045)),(w+.26,.25,.27),'oak_dark')
                    for x in (-w*.43,-w*.20,w*.20,w*.43):
                        beam('Carved jetty corbels',(x,2.77,side*front),(x,3.19,side*(front+.20)),.065,'oak',4)
                    for x in (-w*.28,w*.28):
                        beam('Upper wall diagonal bracing',(x-.36,3.49,side*(front+.025)),(x+.33,4.15,side*(front+.025)),.062,'oak_dark',4)
    roof('Main',0,wall_h,0,w+.54,d+.55,rise)
    # Every side has authored openings, framing and roof end structure.
    if base not in ('forge','market_hall'):
        doorx=record['door'][0]/32+lotx/2
        doorz=(record['door'][1]-24)/32+lotz/2
        door('Entrance',doorx,front+.07)
        record['entry_metres']=[doorx,0,front+.07]
        spacing=w*.29
        for x in (-spacing,spacing):
            if abs(x-doorx)>1.0:window('Lower front window',x,1.0,front+.055,.82,1.32,base!='guild',True)
        if two or base=='guild':
            for x in (-w*.27,w*.27):window('Upper front window',x,3.72,front+.065,.90,1.24,base!='guild',base!='guild')
        for side in (-1,1):
            # Side facades are authored by rotating their meshes around Y.
            before={k:len(v['v']) for k,v in BUCKETS.items()}
            for zoff in (-d*.24,d*.24):
                window('Side facade',zoff,1.03,w/2+.055,.80,1.25,True,base!='guild')
                if two or base=='guild':window('Upper side facade',zoff,3.76,w/2+.055,.78,1.22,True)
            rotate_new_geometry(before,side*math.pi/2)
        # Rear service door/window give true structure in all four rotations.
        before={k:len(v['v']) for k,v in BUCKETS.items()}
        window('Rear window',0,1.08,front+.055,.86,1.25,True)
        if two:window('Rear attic window',0,3.78,front+.055,.90,1.20,True)
        rotate_new_geometry(before,math.pi)
    else:
        record['entry_metres']=[0,0,front+.12]
    chimney(-w*.29,-d*.19,wall_h+.55,2.8 if base=='forge' else 1.60,.64 if base!='forge' else .90)
    if base=='baker_house':
        awning(0,3.12,front+.11,w*.78,.80)
        shop_sign(-w*.42,2.53,front+.53,base)
        for side in (-1,1):
            x=side*w*.27
            box('Baker display table',(x,.98,front+.25),(1.1,.12,.47),'oak_dark')
            for i in range(5):ellipsoid('Baker displayed loaves',(x+(i-2)*.18,1.10,front+.34),(.125,.072,.09),'bread')
        # The dormer rises through the roof plane, with a real cheek, glazing,
        # and perpendicular ridge. A roof laid below the main roof was hidden.
        cx=w*.10;cz=d*.24;bottom=wall_h+rise*.48;top=wall_h+rise*.92
        box('Dormer plaster cheeks',(cx,(bottom+top)/2,cz),(1.20,top-bottom,1.28),'plaster')
        window('Dormer recessed window',cx,bottom+.12,cz+.675,.68,.65,False)
        before={k:len(v['v']) for k,v in BUCKETS.items()}
        roof('Dormer',0,top,0,1.44,1.39,.64)
        rotate_new_geometry(before,math.pi/2)
        for key,data in BUCKETS.items():
            for i in range(before.get(key,0),len(data['v'])):
                x,y,z=data['v'][i];data['v'][i]=(x+cx,y-cz,z)
    elif base=='apothecary':
        shop_sign(-w*.42,2.61,front+.54,base)
        for side in (-1,1):
            x=side*w*.41
            for i in range(7):
                at=(x+math.sin(i*1.8)*.15,.40+i*.38,front+.11)
                beam('Climbing vine',at,(at[0]+.04,at[1]+.34,at[2]),.012,'oak_dark',5)
                leaf_spray('Herb trellis foliage',at,.20,20)
    elif base=='inn':
        balcony(0,3.31,front,w*.69)
        shop_sign(-w*.41,2.46,front+.55,base)
        roof('Inn side lean-to',w*.34,2.60,front+.07,w*.34,1.07,.62)
    elif base=='forge':
        shop_sign(-w*.43,2.43,front+.5,base)
        for row in range(4):
            for i in range(4-row):beam('Smithy stacked firewood',(w*.39+(i-(3-row)/2)*.15,.17+row*.14,front-.30),(w*.39+(i-(3-row)/2)*.15,.17+row*.14,front+.28),.077,'oak',8)
    elif base=='garden_house' or base=='pet_lodge':
        roof('Garden porch',w*.23,2.40,front+.11,w*.49,1.02,.62)
        for side in (-1,1):box('Garden porch pillars',(w*.23+side*w*.22,1.16,front+.54),(.11,2.31,.11),'oak_dark')
        for i in range(11):
            x=-w*.44+i*w*.088
            if abs(x-record['entry_metres'][0])<.72:continue
            leaf_spray('Occupied garden border',(x,.25,front+.25),.23,28)
    elif base=='guild':
        civic_clock_tower(w,wall_h,front)
    elif base=='market_hall':
        for i in range(3):
            x=(i-1)*w*.29
            box('Market stall',(x,.79,front-.10),(w*.24,.16,.68),'oak')
            for j in range(9):ellipsoid('Market produce',(x+RNG.uniform(-.4,.4),.91,front+RNG.uniform(-.31,.12)),(.09,.07,.085),'bread' if i%2 else 'leaf')
    return record

def rotate_new_geometry(before,angle):
    # Coordinates here are already Blender (X, -Z, Y): rotate about Blender Z.
    c=math.cos(angle);s=math.sin(angle)
    for key,data in BUCKETS.items():
        face_start=sum(1 for face in data['f'] if max(face)<before.get(key,0))
        for i in range(before.get(key,0),len(data['v'])):
            x,y,z=data['v'][i]
            data['v'][i]=(c*x-s*y,s*x+c*y,z)
        for i in range(face_start,len(data['grain'])):
            if data['grain'][i] is not None:
                x,y,z=data['grain'][i];data['grain'][i]=(c*x-s*y,s*x+c*y,z)

def civic_clock_tower(w,base,front):
    tw=1.8;bottom=base-1.5;h=4.0
    stone_courses('Guild clock tower',(0,bottom,front-.70),(tw,h,1.70),.42,.28)
    for side in (-1,1):
        for z in (front-1.5,front+.1):box('Clock tower corner pilaster',(side*.92,bottom+h/2,z),(.18,h,.18),'limestone_light')
    box('Belfry dark opening',(0,bottom+h-.55,front+.18),(.56,.73,.06),'recess')
    beam('Bell', (0,bottom+h-.63,front+.22),(0,bottom+h-.39,front+.22),.17,'brass',12,r2=.07)
    # Readable clock dial, real rim and hands, no baked letter graphics.
    cy=bottom+2.10
    beam('Clock face',(0,cy,front+.32),(0,cy,front+.40),.59,'cloth',32)
    for i in range(12):
        a=i*math.tau/12
        beam('Clock marks',(math.sin(a)*.46,cy+math.cos(a)*.46,front+.42),(math.sin(a)*.53,cy+math.cos(a)*.53,front+.42),.018,'iron',4)
    beam('Clock hour hand',(0,cy,front+.44),(-.18,cy+.22,front+.44),.023,'iron',4)
    beam('Clock minute hand',(0,cy,front+.445),(.32,cy+.23,front+.445),.016,'iron',4)
    spire('Main civic spire',(0,bottom+h,front-.70),1.25,2.40)
    for side in (-1,1):
        x=side*w*.39
        stone_courses('Guild side pinnacle',(x,base-.60,front-.1),(.54,1.80,.54),.30,.24)
        spire('Side civic spire',(x,base+1.20,front-.10),.52,1.1)

def spire(name,at,r,h):
    x,y,z=at;sides=8
    for row in range(8):
        low=row/8;high=(row+1)/8
        for i in range(sides):
            a=i*math.tau/sides;b=(i+1)*math.tau/sides
            verts=[(x+math.cos(a)*r*(1-low),y+h*low,z+math.sin(a)*r*(1-low)),(x+math.cos(b)*r*(1-low),y+h*low,z+math.sin(b)*r*(1-low)),(x+math.cos(b)*r*(1-high),y+h*high,z+math.sin(b)*r*(1-high)),(x+math.cos(a)*r*(1-high),y+h*high,z+math.sin(a)*r*(1-high))]
            poly(name+' slate courses',verts,[(0,1,2,3)],'roof',RNG.uniform(.84,1.05))
    beam(name+' finial',(x,y+h,z),(x,y+h+.40,z),.025,'brass',8)

def tree(kind,record):
    h={'linden':4.6,'linden_young':3.55,'linden_lean':4.8,'birch':4.55,'spruce':5.25,'cypress':5.25,'garden_tree':3.6}[kind]
    thin=kind in ('birch','linden_young');conifer=kind in ('spruce','cypress')
    lean=Vector((.30,0,-.16)) if kind=='linden_lean' else Vector((-.10,0,.09))
    trunk=[]
    for i in range(7):
        t=i/6;trunk.append(Vector((math.sin(t*3.2)*.06,h*t*.83,math.sin(t*5)*.045))+lean*t)
    for i in range(6):beam('Tapered curved trunk',trunk[i],trunk[i+1],(.095 if thin else .16)*(1-i/7), 'oak',10,r2=(.095 if thin else .16)*(1-(i+1)/7))
    for i in range(6):
        a=i*math.tau/6
        beam('Grounded buttress roots',(math.cos(a)*(.30 if thin else .43),.018,math.sin(a)*(.30 if thin else .43)),(0,.48,0),.055 if thin else .08,'oak_dark',7,r2=.105 if not thin else .062)
    if kind=='birch':
        # Narrow pale bark ribbons on a branching trunk, not a white cylinder.
        for i in range(10):
            y=.25+i*.30
            beam('Birch pale bark',(math.sin(y)*.018,y,0),(.03,y+.20,.025),.078,'limestone_light',10,r2=.07)
    if conifer:
        tiers=12 if kind=='cypress' else 9
        for row in range(tiers):
            y=.95+row*(h-1.15)/tiers
            spread=(.49 if kind=='cypress' else 1.10)*(1-row/(tiers+.6))**.64
            for branch in range(7):
                a=branch*math.tau/7+row*1.15
                tip=Vector((math.cos(a)*spread,y-.11,math.sin(a)*spread))+lean*.4
                beam('Conifer bough',(0,y+.22,0),tip,.031,'oak_dark',6,r2=.008)
                for segment in range(3):
                    p=Vector((0,y+.15,0)).lerp(tip,(segment+1)/3)
                    leaf_spray('Layered needle sprays',tuple(p),max(.12,spread*.35),40)
        leaf_spray('Conifer crown',(0,h-.18,0),.20,65)
    else:
        branches=11 if thin else 15
        spread=.92 if thin else (1.10 if kind=='garden_tree' else 1.31)
        for i in range(branches):
            a=i*2.39996;y=h*(.48+.35*i/branches)
            radial=spread*(.48+.52*math.sin(math.pi*(i+2)/(branches+3)))
            start=Vector((0,y-.75,0))+lean*.5
            middle=Vector((math.cos(a)*radial*.57,y-.09,math.sin(a)*radial*.57))+lean
            tip=Vector((math.cos(a)*radial,y+.21,math.sin(a)*radial))+lean
            beam('Primary angled limbs',start,middle,.055 if thin else .08,'oak',8,r2=.027)
            beam('Rising outer limbs',middle,tip,.027,'oak',7,r2=.009)
            for j in range(5):
                theta=a+(j-2)*.37
                twig=middle.lerp(tip,.22+j*.16)+Vector((math.cos(theta)*.23,.10+math.sin(j)*.13,math.sin(theta)*.23))
                beam('Visible fine twigs',middle.lerp(tip,.15+j*.15),twig,.013,'oak_dark',5,r2=.005)
                leaf_spray('Airy supported leaf sprays',tuple(twig),.32 if thin else .40,60 if thin else 83)
        leaf_spray('Asymmetric crown tuft',tuple(lean+Vector((-.12,h-.33,.03))),.39,150)
    record['entry_metres']=[0,0,0]
    return record

def curtain(kind,record):
    span=record['module_spec']['length']/32
    stone_courses('Hand-cut curtain masonry',(0,0,0),(span,3.36,1.10),.43,.25)
    box('Battered wall plinth',(0,.12,0),(span,.24,1.30),'limestone_dark',.035)
    box('Continuous wall walk',(0,3.40,0),(span,.16,1.22),'limestone_light',.025)
    for side in (-1,1):
        stone_courses('Parapet masonry',(0,3.43,side*.45),(span,.36,.23),.44,.18)
        n=max(2,round(span/.76))
        for i in range(n):
            x=-span/2+(i+.5)*span/n
            box('Battlement merlons',(x,4.02,side*.45),(.44,.48,.28),'limestone',.027)
            box('Weathered coping',(x,4.27,side*.45),(.50,.065,.35),'limestone_light',.023)
        # Proud structural buttress with stepped shoulders gives the face depth.
        stone_courses('Wall buttress',(0,.20,side*.53),(.39,2.69,.43),.45,.29)
        poly('Buttress sloped shoulder',[(-.22,2.89,side*.81),(.22,2.89,side*.81),(.18,3.22,side*.52),(-.18,3.22,side*.52)],[(0,1,2,3)],'limestone_light')
    return record

def ring_stones(name,y,h,r,depth=.20,segments=22,row_offset=0):
    for i in range(segments):
        a=(i+row_offset)*math.tau/segments+.004;b=(i+1+row_offset)*math.tau/segments-.004
        v=[]
        for yy in (y,y+h):
            for angle,rr in ((a,r-depth),(b,r-depth),(b,r),(a,r)):
                v.append((math.cos(angle)*rr,yy,math.sin(angle)*rr))
        poly(name,v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'limestone',RNG.uniform(.85,1.07),.012)

def tower(kind,record):
    r=record['module_spec']['radius']/32
    h=5.45 if kind=='tower_corner' else 5.15
    beam('Round tower core',(0,0,0),(0,h,0),r-.05,'mortar',32)
    ring_stones('Tower footing',.02,.25,r+.13,.32,24)
    for row in range(21):ring_stones('Dressed curved tower blocks',.27+row*(h-.27)/21,(h-.27)/21-.012,r,.17,24,.5*(row%2))
    for y in (h-.27,h-.03):ring_stones('Tower cornice bands',y,.14,r+.06,.24,24)
    for i in range(12):
        a=i*math.tau/12
        x=math.cos(a)*(r-.08);z=math.sin(a)*(r-.08)
        before={k:len(v['v']) for k,v in BUCKETS.items()}
        box('Tower battlements',(0,h+.31,r-.08),(.34,.54,.29),'limestone',.028)
        box('Tower coping stones',(0,h+.60,r-.08),(.40,.07,.36),'limestone_light',.024)
        rotate_new_geometry(before,-a+math.pi/2)
    for side in (-1,1):
        before={k:len(v['v']) for k,v in BUCKETS.items()}
        box('Tower arrow slit',(0,h*.65,r+.012),(.11,.80,.035),'recess',.01)
        for sx in (-1,1):box('Arrow slit depth',(sx*.094,h*.65,r+.012),(.055,.90,.10),'limestone_dark',.015)
        box('Arrow slit sill',(0,h*.65-.46,r+.022),(.30,.08,.16),'limestone_light')
        rotate_new_geometry(before,side*math.pi/2)
    return record

def gate(record):
    half=66/32;depth=62/32
    for side in (-1,1):stone_courses('Gate masonry piers',(0,0,side*(half+.385)),(depth,5.85,.77),.43,.26)
    # Closed voussoirs form a deep arched passage aligned to the existing road.
    for i in range(19):
        a=i*math.pi/19+.003;b=(i+1)*math.pi/19-.003
        outline=[(math.cos(a)*half,2.32+math.sin(a)*1.78),(math.cos(b)*half,2.32+math.sin(b)*1.78),(math.cos(b)*(half+.35),2.32+math.sin(b)*1.78+.43),(math.cos(a)*(half+.35),2.32+math.sin(a)*1.78+.43)]
        v=[(xx,yy,zz) for xx in (-depth/2,depth/2) for zz,yy in outline]
        poly('Carved arch voussoirs',v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'limestone_light',RNG.uniform(.89,1.06),.020)
        # Fill above the arch with small separate dressed stones on both faces.
        z0,z1=outline[3][0],outline[2][0]
        floor=max(outline[3][1],outline[2][1]);column_h=5.85-floor
        if column_h>.05:
            for side in (-1,1):stone_courses('Gate upper carved courses',(side*(depth/2-.14),floor,(z0+z1)/2),(.29,column_h,abs(z1-z0)+.015),.46,.26)
    box('Gate crown cornice',(0,5.91,0),(depth+.20,.18,5.68),'limestone_light',.025)
    for side in (-1,1):
        stone_courses('Gate top parapets',(side*(depth/2-.10),5.98,0),(.25,.30,5.65),.45,.15)
        for i in range(8):
            z=-2.54+i*5.08/7
            box('Gate tall battlements',(side*(depth/2-.10),6.52,z),(.32,.50,.43),'limestone',.025)
            box('Gate coping',(side*(depth/2-.10),6.80,z),(.38,.08,.49),'limestone_light',.025)
        for z in (-2.42,2.42):
            x=side*(depth/2+.085)
            # Banner is attached over solid pier, never across the opening.
            poly('Aged blue gate banners',[(x,5.62,z-.20),(x,5.62,z+.20),(x+side*.035,3.52,z+.20),(x+side*.042,3.40,z),(x+side*.035,3.52,z-.20)],[(0,1,2,3,4)],'banner')
            beam('Banner brass bar',(x,5.69,z-.30),(x,5.69,z+.30),.033,'brass')
            for j in range(8):
                a=j*math.tau/8;b=(j+1)*math.tau/8
                beam('Gate banner sun emblem',(x+side*.012,4.75+math.cos(a)*.16,z+math.sin(a)*.13),(x+side*.012,4.75+math.cos(b)*.16,z+math.sin(b)*.13),.014,'brass',5)
    for i in range(15):
        z=-half+.10+i*(2*half-.2)/14
        box('Raised portcullis bars',(.05,4.19,z),(.07,.57,.034),'iron',.005)
    box('Raised portcullis rail',(.05,4.24,0),(.08,.05,2*half),'iron',.005)
    return record

def run():
    sys.path.insert(0,str(ROOT))
    from architecture_depth import build as build_architecture
    registry_path=ROOT/'registry.json'
    registry=json.loads(registry_path.read_text()) if registry_path.exists() else {}
    roofs={'baker_house':'b6764e','apothecary':'718164','inn':'806378','guild':'526c85','forge':'657077','market_hall':'a7805f','pet_lodge':'7b886c','garden_house':'777e72','garden_house_sage':'7d8b76','garden_house_clay':'ab7558','garden_house_ash':'737e80','townhouse':'617680','townhouse_mauve':'886c7e'}
    for kind in SELECTED:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        BUCKETS.clear();MATS.clear();RNG.seed(int.from_bytes(hashlib.sha256(kind.encode()).digest()[:4],'big'))
        palette(roofs.get(kind,'687b79'))
        record=dict(BASELINE[kind])
        if kind in roofs:record=build_architecture(kind,record,globals())
        elif kind.startswith('wall_'):record=curtain(kind,record)
        elif kind.startswith('tower_'):record=tower(kind,record)
        elif kind=='gatehouse':record=gate(record)
        else:record=tree(kind,record)
        record['height_metres']=max(p[2] for b in BUCKETS.values() for p in b['v'])
        registry[kind]=finish(kind,record)
        print('WF_REFERENCE_MODEL_OK',kind,'height',round(record['height_metres'],3),flush=True)
    registry_path.write_text(json.dumps(registry,indent=2)+'\n')

if __name__=='__main__':run()
