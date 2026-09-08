"""Editable cottage with real wall openings and curved, overlapping roof solids.

Blender 4.1 --background --python build_cottage.py
Final shaded pixels are organized into editable Aseprite layers by a second script.
"""
import bpy, bmesh, math, random, json
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parent
R=random.Random(15091)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for material in list(bpy.data.materials): bpy.data.materials.remove(material)
GROUPS={1:'01 Stone footing',2:'02 Plaster walls and reveals',3:'03 Foundation masonry',
        4:'04 Oak framing',5:'05 Recessed windows',6:'06 Stone door arch',7:'07 Oak door and ironwork',
        8:'08 Main curved roof tiles',9:'09 Dormer',10:'10 Chimney',11:'11 Entry and lantern',
        12:'12 Garden and pots',13:'13 Fence and barrel'}
COLS={i:bpy.data.collections.new(name) for i,name in GROUPS.items()}
for col in COLS.values(): bpy.context.scene.collection.children.link(col)
CURRENT=1
MATS={}

def linear(c): return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
def color(hex): return tuple(linear(int(hex[i:i+2],16)/255) for i in (0,2,4))+(1,)
def mat(name,dark,light,kind='stone',axis=2):
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=m.node_tree.nodes;l=m.node_tree.links
    bs=n.get('Principled BSDF');bs.inputs['Roughness'].default_value=.94
    bs.inputs['Specular IOR Level'].default_value=.08
    coord=n.new('ShaderNodeTexCoord')
    scale=n.new('ShaderNodeVectorMath');scale.operation='MULTIPLY'
    if kind=='wood':
        factors=[5.5,5.5,5.5];factors[axis]=.45
    else: factors=[1.8,1.8,1.8]
    scale.inputs[1].default_value=factors;l.new(coord.outputs['Generated'],scale.inputs[0])
    noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=2.4
    noise.inputs['Detail'].default_value=3;noise.inputs['Roughness'].default_value=.73
    l.new(scale.outputs['Vector'],noise.inputs['Vector'])
    ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.15;ramp.color_ramp.elements[0].color=color(dark)
    ramp.color_ramp.elements[1].position=.83;ramp.color_ramp.elements[1].color=color(light)
    l.new(noise.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs['Color'],bs.inputs['Base Color'])
    grain=n.new('ShaderNodeTexNoise');grain.inputs['Scale'].default_value=88 if kind!='wood' else 8
    grain.inputs['Detail'].default_value=2;l.new(scale.outputs['Vector'],grain.inputs['Vector'])
    bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.30 if kind!='wood' else .43
    bump.inputs['Distance'].default_value=.014 if kind!='wood' else .009
    l.new(grain.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],bs.inputs['Normal'])
    MATS[name]=m;return m

mat('limewash','b7ab89','e6dbc0','plaster')
mat('reveal','817862','b8ad91','plaster')
mat('mortar','6e6b59','a59c82')
for i in range(9):
    base=R.randint(-15,13)
    def h(c):return ''.join(f'{max(0,min(255,v+base)):02x}' for v in c)
    mat(f'stone{i}',h((118,116,99)),h((188,180,150)))
for axis in range(3):
    mat(f'oak{axis}','4b3b27','9d784b','wood',axis)
    mat(f'oldwood{axis}','665639','b39c67','wood',axis)
    mat(f'shutter{axis}','384b3c','788464','wood',axis)
mat('iron','272c27','626351','metal')
mat('brass','7d6939','b9a160','metal')
mat('glass','223b39','4e6b60','glass')
mat('glass_light','526e60','9bb49a','glass')
mat('soil','343c25','665a37')
mat('pot','75432a','b47745')
mat('rope','746344','afa073','wood')
for i in range(15):
    v=R.randint(-16,15)
    def h(c):return ''.join(f'{max(0,min(255,a+v)):02x}' for a in c)
    mat(f'clay{i}',h((124,57,34)),h((204,126,66)),'tile')
for i in range(5): mat(f'leaf{i}',('33462c','425536','455b30','566b38','667642')[i],('647942','809247','758d46','91a458','a0b068')[i],'leaf')
mat('flower','9f716f','d1ab91','leaf')
mat('petal','afa567','d8c77d','leaf')
mat('warm_glass','b47a2e','e8bd69','glass')
bs=MATS['warm_glass'].node_tree.nodes.get('Principled BSDF')
bs.inputs['Emission Color'].default_value=color('e9b967');bs.inputs['Emission Strength'].default_value=.32

def assign(obj,material):
    if isinstance(material,str): material=MATS[material]
    obj.data.materials.append(material);obj.pass_index=CURRENT
    for c in list(obj.users_collection):c.objects.unlink(obj)
    COLS[CURRENT].objects.link(obj)
    return obj

def cube(name,at,size,material='oak',bevel=.015):
    if material in ('oak','oldwood','shutter'): material+=str(max(range(3),key=lambda i:size[i]))
    x,y,z=(d/2 for d in size)
    verts=[(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]
    obj=mesh(name,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],material,bevel)
    obj.location=at
    return obj

def mesh(name,verts,faces,material,bevel=0):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);COLS[CURRENT].objects.link(obj)
    obj.pass_index=CURRENT;obj.data.materials.append(MATS[material])
    if bevel:
        mod=obj.modifiers.new('Edge wear','BEVEL');mod.width=bevel;mod.segments=2
        obj.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return obj

def beam(name,a,b,width,depth=None,material='oak'):
    a,b=Vector(a),Vector(b);mid=(a+b)/2
    obj=cube(name,mid,(width,depth or width,(b-a).length),material,.012)
    obj.rotation_mode='QUATERNION';obj.rotation_quaternion=(b-a).to_track_quat('Z','Y')
    return obj

ICOS={}
def sphere(name,at,scale,material,sub=1):
    if sub not in ICOS:
        bm=bmesh.new();bmesh.ops.create_icosphere(bm,subdivisions=sub,radius=1)
        data=bpy.data.meshes.new('Icosphere template');bm.to_mesh(data);bm.free();ICOS[sub]=data
    data=ICOS[sub].copy();obj=bpy.data.objects.new(name,data)
    obj.location=at;obj.scale=scale;obj.pass_index=CURRENT;COLS[CURRENT].objects.link(obj)
    obj.data.materials.append(MATS[material])
    return obj

def arch(name,cx,yfront,yback,bottom,spring,radius,material):
    pts=[(cx-radius,bottom),(cx+radius,bottom),(cx+radius,spring)]
    pts += [(cx+radius*math.cos(i*math.pi/16),spring+radius*math.sin(i*math.pi/16)) for i in range(1,17)]
    n=len(pts);v=[(x,y,z) for y in (yfront,yback) for x,z in pts]
    f=[tuple(range(n)),tuple(reversed(range(n,n*2)))]+[(i+n,(i+1)%n+n,(i+1)%n,i) for i in range(n)]
    return mesh(name,v,f,material)

def cut(obj,cutter):
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('True opening through wall','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter,do_unlink=True)

# Ground, with separate visible limestone pavers and shallow earth edge.
CURRENT=1
cube('Shallow stone footing',(0,-.12,.035),(6.3,5.6,.12),'mortar',.13)
for row in range(17):
    y=-2.76+row*.32
    for col in range(18):
        x=-3.1+col*.35+(row%2)*.17
        if x>3.1 or (abs(x)>2.7 and abs(y+.1)>2.35):continue
        ob=cube('Worn paving stone',(x,y,.109+R.uniform(-.012,.007)),(.334+R.uniform(-.015,.008),.301,.09),f'stone{R.randrange(9)}',.025)
        ob.rotation_euler[2]=R.uniform(-.018,.018)

# Four substantial walls. Front and right openings go through actual geometry.
print('Ground complete; cutting thick walls',flush=True)
CURRENT=2
front=cube('Front wall, 30 cm thick',(0,-1.60,1.75),(4.4,.30,3.10),'limewash',0)
right=cube('Right wall, 30 cm thick',(2.05,0,1.75),(.30,3.20,3.10),'limewash',0)
cube('Rear wall',(0,1.60,1.75),(4.4,.30,3.10),'limewash',.01)
cube('Left wall',(-2.05,0,1.75),(.30,3.20,3.10),'limewash',.01)
door_cx=.97
cut(front,arch('Door opening',door_cx,-2.2,-1.0,.18,1.96,.58,'reveal'))
cut(front,cube('Front window cutter',(-1.12,-1.6,1.94),(1.16,.9,1.40),'reveal',0))
for yc in (-.85,.90):cut(right,cube('Side window cutter',(2.05,yc,1.96),(.9,.90,1.28),'reveal',0))
for ob in (front,right):
    bevel=ob.modifiers.new('Soft plaster opening edges','BEVEL');bevel.width=.018;bevel.segments=2
    ob.modifiers.new('Wall normals','WEIGHTED_NORMAL')
# Closed gable prisms, with a true attic vent cut through the front one.
gverts=[(-2.2,-1.75,3.3),(2.2,-1.75,3.3),(0,-1.75,4.72),(-2.2,-1.47,3.3),(2.2,-1.47,3.3),(0,-1.47,4.72)]
gable=mesh('Front gable',gverts,[(0,1,2),(3,5,4),(3,4,1,0),(4,5,2,1),(5,3,0,2)],'limewash',.006)
cut(gable,cube('Attic vent cutter',(0,-1.60,3.87),(.47,.9,.57),'reveal',0))
cube('Attic vent deep shadow',(0,-1.45,3.87),(.48,.04,.58),'iron',0)
for x in (-.18,-.09,0,.09,.18):cube('Attic vent oak slat',(x,-1.54,3.87),(.04,.05,.52),'oak',.008)
mesh('Rear gable',[(x,-y,z) for x,y,z in gverts],[(0,2,1),(3,4,5),(1,4,3,0),(2,5,4,1),(0,3,5,2)],'limewash',.01)

# Lower stone facing consists of blocks with actual proud faces and bevels.
CURRENT=3
for side in ('front','right'):
    lo,hi=(-2.2,2.2) if side=='front' else (-1.75,1.75)
    for row in range(3):
        z=.21+row*.21
        x=lo-(.21 if row%2 else 0)
        while x<hi:
            width=R.uniform(.35,.55);a,b=max(lo,x),min(hi,x+width)
            intervals=[(a,b)]
            if side=='front':
                intervals=[]
                for l,r in ((a,min(b,door_cx-.59)),(max(a,door_cx+.59),b)):
                    if r-l>.04:intervals.append((l,r))
            for a,b in intervals:
                if b-a<.025:continue
                dep=R.uniform(.10,.14)
                if side=='front':at=((a+b)/2,-1.765,z+.10);size=(b-a-.009,dep,.198)
                else:at=(2.22,(a+b)/2,z+.10);size=(dep,b-a-.009,.198)
                cube('Individual limestone block',at,size,f'stone{R.randrange(9)}',.018)
            x+=width

CURRENT=4
for x in (-2.15,-.04,2.15):cube('Front oak upright',(x,-1.815,1.78),(.15,.18,3.04),'oak',.018)
for y in (-1.69,0,1.69):cube('Side oak upright',(2.25,y,1.78),(.18,.15,3.04),'oak',.018)
for z in (.23,.88,3.18):
    if z>2.70:
        cube('Front continuous timber',(0,-1.82,z),(4.43,.20,.14),'oak',.018)
    else:
        for a,b in ((-2.215,door_cx-.79),(door_cx+.79,2.215)):
            cube('Front timber ending at door jamb',((a+b)/2,-1.82,z),(b-a,.20,.14),'oak',.018)
    cube('Side continuous timber',(2.25,0,z),(.20,3.50,.14),'oak',.018)
for a,b in (((-2.12,-1.82,3.26),(0,-1.82,4.72)),((2.12,-1.82,3.26),(0,-1.82,4.72))):beam('Gable raking timber',a,b,.12,.14)
beam('Gable king post',(0,-1.82,4.18),(0,-1.82,4.70),.13,.13)
beam('Gable lower post',(0,-1.82,3.30),(0,-1.82,3.51),.13,.13)
for x,sign in ((-2.12,1),(2.12,-1)):
    beam('Shouldered oak brace',(x,-1.83,2.69),(x+sign*.57,-1.83,3.16),.10,.13)
for y,sign in ((-1.65,1),(1.65,-1)):
    beam('Side oak brace',(2.29,y,2.77),(2.29,y+sign*.45,3.16),.085,.10)

def wallpos(side,u,d,z): return (u,-1.75-d,z) if side=='front' else (2.20+d,u,z)
def wallbox(name,side,u,d,z,w,depth,h,matname,bevel=.01):
    return cube(name,wallpos(side,u,d,z),(w,depth,h) if side=='front' else (depth,w,h),matname,bevel)
def window(side,u,z,w,h,shutters=False):
    # Exterior wall d=0. The glazing plane sits 28 cm inside it.
    wallbox('Deep window interior',side,u,-.325,z,w+.035,.025,h+.035,'iron',0)
    wallbox('Old glass',side,u,-.284,z,w-.08,.025,h-.07,'glass',.005)
    for s in (-1,1):
        wallbox('Solid recessed oak jamb',side,u+s*(w/2-.025),-.125,z,.095,.35,h+.11,'oak',.012)
    for s in (-1,1):
        wallbox('Solid frame cross member',side,u,-.125,z+s*(h/2-.02),w+.12,.35,.095,'oak',.012)
    wallbox('Projecting stone window sill',side,u,.095,z-h/2-.095,w+.38,.67,.16,'stone6',.027)
    wallbox('Window lintel cap',side,u,.055,z+h/2+.10,w+.30,.44,.13,'oak',.018)
    # Small support blocks beneath the stone sill.
    for s in (-1,1):wallbox('Stone sill corbel',side,u+s*w*.32,.04,z-h/2-.24,.16,.33,.22,'stone4',.025)
    ww,hh=w-.13,h-.14
    for col in range(2):
        for row in range(2):
            if (col+row)%2==0:wallbox('Uneven green glass pane',side,u+(col-.5)*ww/2,-.263,z+(row-.5)*hh/2,ww/2-.015,.014,hh/2-.015,'glass_light',0)
    for slope in (-1,1):
        for shift in [i*.25 for i in range(-8,10)]:
            # z_local = slope * u_local + shift, clipped to the rectangular aperture.
            points=[]
            for xx in (-ww/2,ww/2):
                zz=slope*xx+shift
                if -hh/2<=zz<=hh/2:points.append((xx,zz))
            for zz in (-hh/2,hh/2):
                xx=(zz-shift)/slope
                if -ww/2<=xx<=ww/2:points.append((xx,zz))
            if len(points)>=2:
                a,b=points[0],points[1]
                if (a[0]-b[0])**2+(a[1]-b[1])**2>.0001:
                    beam('Raised lead glazing strip',wallpos(side,u+a[0],-.246,z+a[1]),wallpos(side,u+b[0],-.246,z+b[1]),.015,.018,'iron')
    wallbox('Central carved window mullion',side,u,-.195,z,.041,.12,h-.07,'oak',.007)
    wallbox('Window transom',side,u,-.19,z-.02,w-.06,.13,.040,'oak',.007)
    if shutters:
        for s in (-1,1):
            center=u+s*(w/2+.25)
            for plank in range(3):
                uu=center+(plank-1)*.103
                ob=wallbox('Open shutter board',side,uu,.13+abs(uu-center)*.6,z,.10,.085,h-.08,'shutter',.011)
                ob.rotation_euler[2]=s*.30*(1 if side=='front' else -1)
            for zz in (z-h*.34,z+h*.34):wallbox('Forged shutter hinge',side,center,.203,zz,.34,.025,.043,'iron',.005)
            beam('Diagonal shutter brace',wallpos(side,center-.14,.205,z-h*.35),wallpos(side,center+.14,.205,z+h*.35),.047,.048,'oldwood')

CURRENT=5
window('front',-1.12,1.94,1.14,1.38,True)
window('right',-.85,1.96,.88,1.26)
window('right',.90,1.96,.88,1.26)

CURRENT=6
for s in (-1,1):
    for row in range(7):
        h=(1.96-.20)/7
        wallbox('Individual arch jamb block','front',door_cx+s*.68,.015,.20+(row+.5)*h,.20,.45+R.uniform(-.014,.015),h-.008,f'stone{R.randrange(9)}',.019)
for i in range(11):
    a=i*math.pi/11+.008;b=(i+1)*math.pi/11-.008
    pts=[(door_cx+r*math.cos(t),1.96+r*math.sin(t)) for r,t in ((.58,a),(.58,b),(.79,b),(.79,a))]
    verts=[(x,y,z) for y in (-1.98,-1.48) for x,z in pts]
    mesh('Cut arch voussoir',verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],f'stone{R.randrange(9)}',.018)
# Proud central keystone catches light and casts a distinct shadow on the door.
wallbox('Projecting keystone','front',door_cx,.14,2.65,.24,.50,.27,'stone7',.018)

CURRENT=7
arch('Door backing darkness',door_cx,-1.438,-1.40,.19,1.96,.572,'iron')
for i in range(8):
    a=door_cx-.548+i*.137+.002;b=a+.132
    xs=[a+(b-a)*j/3 for j in range(4)]
    pts=[(a,.215),(b,.215)]+[(x,1.96+math.sqrt(max(0,.552**2-(x-door_cx)**2))) for x in reversed(xs)]
    n=len(pts);verts=[(x,y,z) for y in (-1.512,-1.444) for x,z in pts]
    mesh('Arched green oak door plank',verts,[tuple(range(n)),tuple(reversed(range(n,2*n)))]+[(j+n,(j+1)%n+n,(j+1)%n,j) for j in range(n)],'shutter2',.005)
for z in (.69,1.79):
    wallbox('Long forged door strap','front',door_cx-.18,-.232,z,.61,.035,.065,'iron',.009)
    for xx in (-.42,-.22,.02):sphere('Door iron rivet',wallpos('front',door_cx+xx,-.20,z),(.025,.015,.025),'brass',2)
    sphere('Hinge fleur end',wallpos('front',door_cx+.13,-.21,z),(.05,.018,.05),'iron',2)
wallbox('Door handle escutcheon','front',door_cx+.31,-.21,1.25,.09,.035,.19,'iron',.012)
for i in range(16):
    a=i*math.tau/16;b=(i+1)*math.tau/16
    beam('Iron door ring',wallpos('front',door_cx+.31+math.cos(a)*.055,-.177,1.25+math.sin(a)*.07),wallpos('front',door_cx+.31+math.cos(b)*.055,-.177,1.25+math.sin(b)*.07),.018,.018,'brass')

CURRENT=11
for i in range(3):
    top=.285-i*.064
    cube('Solid worn entry step',(door_cx,-1.94-i*.23,(top+.065)/2),(1.67,.30,top-.065),f'stone{6-i}',.034)

def curved_tile(mapper,s0,s1,t0,t1,small=False):
    nu,nv=4,8
    lift=R.uniform(.012,.020)*(0.72 if small else 1)
    thickness=.025 if not small else .018
    warp=R.uniform(-.008,.008)
    chipped=R.random()<.10
    verts=[]
    for bottom in (False,True):
        for i in range(nu+1):
            u=i/nu
            for j in range(nv+1):
                v=j/nv
                s=s0+(s1-s0)*u
                if chipped and u>.75 and v>.72:s-=(u-.75)*(v-.72)*.15
                t=(t0+t1)/2+(v-.5)*(t1-t0)*(1-.035*u)
                # The upper course's underside clears the crown of the next one.
                # Adequate lap lift prevents intersecting tiles and a waffle silhouette.
                h=.012+.088*u+lift*math.sin(v*math.pi)+warp*u*v-(thickness if bottom else 0)
                verts.append(mapper(s,t,h))
    n=(nu+1)*(nv+1);faces=[]
    for i in range(nu):
        for j in range(nv):
            a=i*(nv+1)+j;b=a+nv+1
            faces.append((a,b,b+1,a+1))
            faces.append((a+n,a+1+n,b+1+n,b+n))
    boundary=list(range(nv+1))+[i*(nv+1)+nv for i in range(1,nu+1)]+[nu*(nv+1)+j for j in range(nv-1,-1,-1)]+[i*(nv+1) for i in range(nu-1,0,-1)]
    for i,a in enumerate(boundary):
        b=boundary[(i+1)%len(boundary)];faces.append((a,b,b+n,a+n))
    if (Vector(verts[nv+1])-Vector(verts[0])).cross(Vector(verts[1])-Vector(verts[0])).z<0:faces=[tuple(reversed(f)) for f in faces]
    obj=mesh('Overlapping curved clay tile',verts,faces,f'clay{R.randrange(15)}')
    for p in obj.data.polygons[:nu*nv*2]:p.use_smooth=True
    return obj

def roof_solid(name,cx,cy,width,length,eave,ridge,material='oak2'):
    verts=[(cx-width/2,cy-length/2,eave),(cx-width/2,cy+length/2,eave),
           (cx+width/2,cy+length/2,eave),(cx+width/2,cy-length/2,eave),
           (cx,cy-length/2,ridge),(cx,cy+length/2,ridge)]
    lower=[(x,y,z-.115) for x,y,z in verts]
    faces=[(0,1,5,4),(4,5,2,3),(6,10,11,7),(10,9,8,11),(0,4,10,6),(4,3,9,10),(1,7,11,5),(5,11,8,2),(0,6,7,1),(3,2,8,9)]
    return mesh(name,verts+lower,faces,material,.012)

CURRENT=8
print('Doors and recessed windows complete; shaping roof tiles',flush=True)
roof_solid('Thick main roof deck',0,0,5.02,4.10,3.28,4.90)
# Individual rafter tails emerge from beneath the eave.
for y in [i*.43 for i in range(-4,5)]:
    beam('Exposed rafter end',(2.05,y,3.30),(2.52,y,3.13),.10,.11)
for sign in (-1,1):
    def mapper(s,t,h):return (sign*s,t,4.90-s*(1.62/2.51)+h)
    for row in range(12):
        s0=row*.21;s1=min(2.54,s0+.32)
        t=-2.05-(row%2)*.14
        while t<2.05:
            t0,t1=max(-2.065,t+.004),min(2.065,t+.277)
            if t1-t0>.025:curved_tile(mapper,s0,s1,t0,t1)
            t+=.28
for y in [i*.27-2.07 for i in range(16)]:
    verts=[]
    for yy in (y,y+.287):
        for j in range(9):
            a=j*math.pi/8;verts.append((math.cos(a)*.118,yy,4.937+math.sin(a)*.107))
    faces=[(j,j+1,j+10,j+9) for j in range(8)]+[tuple(reversed(range(9))),tuple(range(9,18))]
    ob=mesh('Rounded overlapping ridge cap',verts,faces,f'clay{R.randrange(15)}',.003)
    for p in ob.data.polygons[:8]:p.use_smooth=True
beam('Front left bargeboard',(-2.49,-2.045,3.22),(0,-2.045,4.84),.12,.10)
beam('Front right bargeboard',(0,-2.045,4.84),(2.49,-2.045,3.22),.12,.10)

CURRENT=9
yc=-.48
# Dormer cheeks follow the main roof intersection instead of floating above it.
for y in (yc-.46,yc+.46):
    verts=[(1.00,y,4.22),(1.92,y,3.64),(1.92,y,4.34),(1.00,y,4.34)]
    mesh('Dormer plaster cheek',verts,[(0,1,2,3)],'limewash')
    beam('Dormer cheek lower timber',verts[0],verts[1],.075,.085)
    beam('Dormer cheek top timber',verts[2],verts[3],.075,.085)
    beam('Dormer cheek upright',(1.89,y,3.71),(1.89,y,4.34),.085,.085)
dormer=cube('Dormer solid front wall',(1.83,yc,4.00),(.20,.92,.68),'limewash',0)
cut(dormer,cube('Dormer actual window opening',(1.83,yc,4.00),(.65,.55,.50),'reveal',0))
mesh('Dormer front gable',[(1.93,yc-.46,4.34),(1.93,yc+.46,4.34),(1.93,yc,4.84)],[(0,1,2)],'limewash')
cube('Dormer deep glass',(1.741,yc,4.0),(.025,.54,.49),'glass_light',0)
for y in (yc-.302,yc+.302):cube('Dormer window jamb',(1.86,y,4.0),(.21,.068,.57),'oak',.008)
for z in (3.724,4.276):cube('Dormer window lintel',(1.86,yc,z),(.21,.67,.066),'oak',.008)
cube('Dormer central mullion',(1.802,yc,4.00),(.068,.035,.50),'oak',.005)
cube('Dormer cross mullion',(1.80,yc,4.00),(.07,.55,.034),'oak',.005)
cube('Dormer projecting stone sill',(1.97,yc,3.66),(.39,.77,.10),'stone6',.016)
for sign in (-1,1):
    def mapper(s,t,h):return (t,yc+sign*s,4.86-s*.90+h)
    for row in range(4):
        for col in range(5):
            t0=.98+col*.222
            curved_tile(mapper,row*.147,min(.605,row*.147+.225),t0,t0+.216,True)
beam('Dormer ridge',(1.00,yc,4.89),(2.11,yc,4.89),.07,.08,'oldwood')
beam('Dormer front rake',(2.09,yc-.60,4.29),(2.09,yc,4.84),.08,.08)
beam('Dormer front rake',(2.09,yc,4.84),(2.09,yc+.60,4.29),.08,.08)

CURRENT=10
cx,cy=.61,1.02
cube('Chimney mortar core',(cx,cy,4.875),(.47,.46,1.33),'mortar',.004)
for row in range(9):
    z=4.22+row*.14+.066
    for side in (-1,1):
        for j in range(2):
            cube('Chimney stone',(cx+(j-.5)*.247,cy+side*.247,z),(.239,.12,.133),f'stone{R.randrange(9)}',.012)
            cube('Chimney return stone',(cx+side*.247,cy+(j-.5)*.20,z),(.12,.193,.133),f'stone{R.randrange(9)}',.012)
cube('Chimney collar',(cx,cy,5.43),(.64,.64,.14),'stone5',.024)
for side in (-1,1):
    cube('Open chimney coping',(cx+side*.247,cy,5.545),(.17,.67,.14),'stone7',.025)
    cube('Open chimney coping',(cx,cy+side*.247,5.545),(.34,.17,.14),'stone7',.025)
cube('Soot-dark interior',(cx,cy,5.40),(.32,.32,.02),'iron',0)

CURRENT=11
# Hanging lantern sits off the wall, with a visible iron bracket and warm panes.
beam('Lantern wall plate',(.03,-1.85,2.26),(.03,-1.85,2.74),.048,.065,'iron')
beam('Lantern projecting bracket',(.03,-1.87,2.72),(.03,-2.12,2.72),.043,.043,'iron')
beam('Lantern hanging link',(.03,-2.12,2.72),(.03,-2.12,2.56),.025,.025,'iron')
cube('Lantern amber glass',(.03,-2.12,2.39),(.22,.21,.31),'warm_glass',.018)
for sx in (-1,1):
    for sy in (-1,1):beam('Lantern corner iron',(.03+sx*.12,-2.12+sy*.11,2.21),(.03+sx*.12,-2.12+sy*.11,2.57),.020,.020,'iron')
for z in (2.21,2.40,2.57):cube('Lantern iron rim',(.03,-2.12,z),(.27,.25,.027),'iron',.007)
verts=[(-.14,-2.26,2.59),(.20,-2.26,2.59),(.20,-1.98,2.59),(-.14,-1.98,2.59),(.03,-2.12,2.74)]
mesh('Lantern peaked cap',verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],'iron',.009)

CURRENT=12
print('Roof and hollow chimney complete; adding plants',flush=True)
def leaf_spray(name,at,radius=.23,count=33):
    x,y,z=at
    for i in range(count):
        a=R.random()*math.tau;r=radius*math.sqrt(R.random())
        zz=z+R.uniform(-radius*.3,radius*.6)
        xx,yy=x+math.cos(a)*r,y+math.sin(a)*r
        obj=sphere(name,(xx,yy,zz),(.065+R.random()*.03,.035+R.random()*.025,.025+R.random()*.02),f'leaf{R.randrange(5)}')
        obj.rotation_euler=(R.uniform(-.4,.4),R.uniform(-.4,.4),a)
def herb(at,rad=.24,height=.38):
    x,y,z=at
    for i in range(6):
        end=(x+R.uniform(-rad*.55,rad*.55),y+R.uniform(-rad*.55,rad*.55),z+height*R.uniform(.55,1.1))
        beam('Herb woody stem',(x,y,z),end,.015,.015,'oldwood')
        leaf_spray('Herb leaves',end,rad,12)

# The flower box is hollow, with separate boards and soil inside.
cube('Flower box back',(-1.12,-1.84,1.025),(1.28,.07,.28),'oldwood',.015)
cube('Flower box front',(-1.12,-2.13,1.025),(1.28,.065,.28),'oldwood',.016)
for x in (-1.75,-.49):cube('Flower box end',(x,-1.985,1.025),(.07,.35,.28),'oldwood',.012)
cube('Flower box soil',(-1.12,-1.98,1.135),(1.18,.25,.03),'soil',.01)
for x in (-1.58,-1.34,-1.10,-.86,-.62):
    leaf_spray('Window box leaves',(x,-2.0,1.22),.15,20)
    for j in range(3):sphere('Window box flower',(x+R.uniform(-.07,.07),-2.04+R.uniform(-.08,.08),1.31+R.uniform(-.02,.04)),(.038,.034,.025),'flower',2)
for at in ((-2.67,-1.35,.15),(-2.02,-2.20,.15),(-1.35,-2.28,.15),(-.69,-2.18,.15),(2.64,-.15,.15),(2.68,1.00,.15)):
    herb(at,.23,R.uniform(.32,.53))
for i in range(12):
    z=.56+i*.16;y=-1.43+math.sin(i*.9)*.06
    beam('Ivy stem',(2.27,y,z),(2.28,-1.43+math.sin((i+1)*.9)*.06,z+.16),.012,.012,'oldwood')
    leaf_spray('Ivy leaf cluster',(2.32,y,z),.075,7)
for i in range(50):
    x,y=R.uniform(-2.95,2.97),R.uniform(-2.58,2.52)
    if (abs(x)>2.35 or y<-2.10) and not (.1<x<1.95 and y<-1.7):
        z=.16
        for j in range(3):
            beam('Grass blade',(x,y,z),(x+R.uniform(-.05,.05),y+R.uniform(-.05,.05),z+R.uniform(.05,.12)),.008,.008,f'leaf{R.randrange(5)}')

def lathe(name,at,profile,material,sides=18):
    verts=[]
    for z,r in profile:
        for j in range(sides):
            a=j*math.tau/sides;verts.append((at[0]+r*math.cos(a),at[1]+r*math.sin(a),at[2]+z))
    faces=[]
    for i in range(len(profile)-1):
        for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
    return mesh(name,verts,faces,material)
lathe('Hollow terracotta herb pot',(-.12,-2.27,.15),[(0,.11),(.04,.14),(.29,.185),(.31,.19),(.34,.19),(.34,.153),(.30,.151),(.09,.10)],'pot')
cube('Pot soil',(-.12,-2.27,.44),(.21,.21,.03),'soil',.03)
herb((-.12,-2.27,.46),.14,.30)

CURRENT=13
for x in (-2.91,-2.46,-2.01,-1.56,-1.11,-.66):
    cube('Fence upright',(x,-2.54,.53),(.09,.10,.75),'oldwood',.015)
    mesh('Fence pointed cap',[(x-.045,-2.59,.905),(x+.045,-2.59,.905),(x+.045,-2.49,.905),(x-.045,-2.49,.905),(x,-2.54,1.00)],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],'oldwood2',.006)
for z in (.38,.74):cube('Fence rail',(-1.78,-2.49,z),(2.42,.085,.09),'oldwood',.013)
# Barrel uses individual curved staves, and hoops stand clear of the timber.
bx,by,bz=2.70,.96,.16
profile=[(0,.175),(.06,.20),(.28,.228),(.48,.20),(.52,.178)]
for stave in range(14):
    verts=[]
    for z,r in profile:
        for a in (stave*math.tau/14+.006,(stave+1)*math.tau/14-.006):verts.append((bx+r*math.cos(a),by+r*math.sin(a),bz+z))
    faces=[(i*2,i*2+1,i*2+3,i*2+2) for i in range(4)]
    mesh('Barrel curved stave',verts,faces,'oldwood2',.003)
for z,r in ((.105,.213),(.42,.216)):
    lathe('Forged barrel hoop',(bx,by,bz),[(z-.02,r+.007),(z+.02,r+.007)],'iron',28)
lathe('Barrel top rim',(bx,by,bz),[(.50,.183),(.54,.183),(.54,.151),(.51,.151)],'oldwood2',24)
cube('Barrel lid',(bx,by,bz+.512),(.23,.23,.025),'oldwood',.035)

# Fixed orthographic 2:1 ground projection (30 degree elevation, 45 degree azimuth).
print('Geometry complete; preparing render',flush=True)
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.device='CPU'
scene.cycles.samples=64;scene.cycles.use_denoising=True
scene.cycles.max_bounces=5;scene.cycles.diffuse_bounces=3;scene.cycles.glossy_bounces=2
scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
scene.render.film_transparent=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.image_settings.color_depth='8'
scene.render.image_settings.compression=20
scene.view_settings.view_transform='Standard'
scene.view_settings.look='Medium High Contrast' if 'Medium High Contrast' in [x.identifier for x in scene.view_settings.bl_rna.properties['look'].enum_items] else 'None'
scene.view_settings.exposure=0;scene.view_settings.gamma=1
world=bpy.data.worlds.new('Soft cool daylight');scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.61,.67,.77,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.33
def light(name,kind,at,energy,colorvalue,size):
    data=bpy.data.lights.new(name,kind);obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj)
    obj.location=at;obj.rotation_euler=(Vector((0,0,1.8))-obj.location).to_track_quat('-Z','Y').to_euler()
    data.energy=energy;data.color=colorvalue
    if kind=='SUN':data.angle=size
    else:data.shape='DISK';data.size=size
    return obj
light('Upper-left sun','SUN',(-3.5,-5.5,9),2.5,(1.0,.91,.78),math.radians(4))
light('Soft camera fill','AREA',(5,-6,6),100,(.74,.84,1.0),5)
camera_data=bpy.data.cameras.new('Shared 2 to 1 orthographic camera');camera=bpy.data.objects.new('Camera',camera_data);scene.collection.objects.link(camera)
target=Vector((0,0,2.12));camera.location=target+Vector((10,-10,math.sqrt(200/3)))
camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.type='ORTHO';camera_data.ortho_scale=9.60
camera_data.lens=50;camera_data.clip_end=100;scene.camera=camera
scene.render.filepath=str(ROOT/'cottage-volume.png')

# Semantic masks preserve the beauty render's shadows when assembled in Aseprite.
scene.view_layers[0].use_pass_object_index=True
scene.use_nodes=True;nodes=scene.node_tree.nodes;links=scene.node_tree.links;nodes.clear()
rl=nodes.new('CompositorNodeRLayers');composite=nodes.new('CompositorNodeComposite');links.new(rl.outputs['Image'],composite.inputs[0])
for i,name in GROUPS.items():
    mask=nodes.new('CompositorNodeIDMask');mask.index=i;mask.use_antialiasing=False
    links.new(rl.outputs['IndexOB'],mask.inputs[0])
    output=nodes.new('CompositorNodeOutputFile');output.base_path=str(ROOT/'masks');output.file_slots[0].path=f'mask_{i:02d}_'
    output.format.file_format='PNG';output.format.color_mode='BW';output.format.color_depth='8'
    links.new(mask.outputs['Alpha'],output.inputs[0])

record={'canvas':[640,640],'orthographic_scale':9.60,'camera_elevation_degrees':30,'camera_azimuth_degrees':45,
        'front_wall_thickness_m':.30,'window_glass_setback_m':.284,'door_setback_m':.238,
        'tile_arch_height_m':[.012,.020],'tile_lap_lift_m':.088,'tile_thickness_m':.025,'renderer':'Blender Cycles CPU, 64 samples',
        'objects':sum(o.type=='MESH' for o in scene.objects),'groups':GROUPS,'source':'cottage-volume.blend'}
(ROOT/'geometry-record.json').write_text(json.dumps(record,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'cottage-volume.blend'))
bpy.ops.render.render(write_still=True)
print('COTTAGE_RENDER_COMPLETE',record['objects'])
