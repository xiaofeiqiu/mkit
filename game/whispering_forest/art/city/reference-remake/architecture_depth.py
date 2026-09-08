"""Occupied fantasy architecture: real openings and interlocking volumes.

Called by the Blender authoring entry point. Coordinates are metres in the
shared Godot Y-up world; all rotations happen on meshes before final baking.
"""
import math
from types import SimpleNamespace
from mathutils import Vector
from mathutils.bvhtree import BVHTree


class Architecture:
    def __init__(self, api, kind, record):
        self.a = SimpleNamespace(**api)
        self.kind, self.record = kind, record
        self.w = record['footprint'][0] / 32 - .46
        self.d = record['footprint'][1] / 32 - .60
        self.door_x = record['door'][0] / 32 + record['footprint'][0] / 64
        self.features = []
        self.openings = 0
        self.opening_ray_checks = 0

    def group(self, action, x=0, y=0, z=0, angle=0):
        before = {k: len(v['v']) for k, v in self.a.BUCKETS.items()}
        action()
        self.a.rotate_new_geometry(before, angle)
        for key, data in self.a.BUCKETS.items():
            for i in range(before.get(key, 0), len(data['v'])):
                px, pz, py = data['v'][i]
                data['v'][i] = (px+x, pz-z, py+y)

    def wall(self, name, width, bottom, top, z, holes, stone=False):
        """Panel with genuine through-openings, thick reveals and lime skin."""
        b, p = self.a.box, self.a.poly
        start={k:len(v['v']) for k,v in self.a.BUCKETS.items()}
        for x,y,w,h,*_ in holes:
            assert w>0 and h>0 and x-w/2>=-width/2-.002 and x+w/2<=width/2+.002 and y>=bottom-.002 and y+h<=top+.002, (self.kind,name,'opening outside wall',x,y,w,h,width,bottom,top)
        holes = [(x-w/2, y, x+w/2, y+h) for x, y, w, h, *_ in holes]
        xs = sorted(set([-width/2, width/2] + [max(-width/2, min(width/2, x)) for h in holes for x in (h[0], h[2])]))
        ys = sorted(set([bottom, top] + [max(bottom, min(top, y)) for h in holes for y in (h[1], h[3])]))
        phase = self.a.RNG.uniform(0, 6.28)
        solids=[]
        for l, r in zip(xs, xs[1:]):
            for lo, hi in zip(ys, ys[1:]):
                if r-l < .002 or hi-lo < .002: continue
                if any(a < (l+r)/2 < c and bb < (lo+hi)/2 < dd for a, bb, c, dd in holes): continue
                solids.append(((l+r)/2,(lo+hi)/2))
                b(name+' thick wall backing', ((l+r)/2, (lo+hi)/2, z-.15), (r-l, hi-lo, .27), 'plaster_undercoat', 0, 1)
                if stone: continue
                # Shared vertices, a gently trowelled face, and a continuous
                # metre-space UV: no texture reset at window borders.
                nx, ny = max(1, math.ceil((r-l)/.18)), max(1, math.ceil((hi-lo)/.18))
                vs, fs = [], []
                for j in range(ny+1):
                    yy = lo+(hi-lo)*j/ny
                    for i in range(nx+1):
                        xx = l+(r-l)*i/nx
                        relief = .018+.018*math.sin(xx*3.7+phase)*math.sin(yy*3.1)+.005*math.sin(xx*11+yy*8)
                        vs.append((xx, yy, z+relief))
                for j in range(ny):
                    for i in range(nx):
                        n = j*(nx+1)+i
                        fs += [(n, n+1, n+nx+2), (n, n+nx+2, n+nx+1)]
                p(name+' Wavy lime plaster surface', vs, fs, 'plaster', 1)
        if stone:
            # Bonded courses share a global row datum across door/window
            # boundaries. Each opening clips blocks rather than covering them.
            def subtract(rect, hole):
                l,b,r,t=rect;a,c,e,f=hole
                il,ib,ir,it=max(l,a),max(b,c),min(r,e),min(t,f)
                if il>=ir or ib>=it:return [rect]
                return [q for q in [(l,b,il,t),(ir,b,r,t),(il,b,ir,ib),(il,it,ir,t)] if q[2]-q[0]>.018 and q[3]-q[1]>.018]
            rows=math.ceil((top-bottom)/.27)
            for j in range(rows):
                lo=bottom+j*(top-bottom)/rows;hi=bottom+(j+1)*(top-bottom)/rows
                cuts=[-width/2];xx=-width/2+(.23 if j%2 else .46)
                while xx<width/2-.04:cuts.append(xx);xx+=self.a.RNG.uniform(.40,.49)
                cuts.append(width/2)
                for l,r in zip(cuts,cuts[1:]):
                    parts=[(l,lo,r,hi)]
                    for hole in holes:parts=[q for part in parts for q in subtract(part,hole)]
                    for a,b,c,e in parts:
                        self.a.dressed_stone(name+' hand laid stone face',((a+c)/2,(b+e)/2,z-.055),(c-a-.012,e-b-.012,.16),self.a.RNG.uniform(.80,1.07))
        # Independent ray queries against the emitted wall mesh catch a
        # solid backing accidentally left behind a decorative window/door.
        vs,fs=[],[]
        for key,data in self.a.BUCKETS.items():
            offset=start.get(key,0)
            if len(data['v'])==offset:continue
            shift=len(vs)-offset
            vs.extend(data['v'][offset:])
            fs.extend(tuple(i+shift for i in face) for face in data['f'] if min(face)>=offset)
        tree=BVHTree.FromPolygons(vs,fs)
        direction=Vector(self.a.point((0,0,-1)))
        for l,b,r,t in holes:
            for fx,fy in ((.38,.41),(.62,.68)):
                origin=Vector(self.a.point((l+(r-l)*fx,b+(t-b)*fy,z+1)))
                assert tree.ray_cast(origin,direction,1.5)[0] is None,(self.kind,name,'blocked through-opening')
                self.opening_ray_checks+=1
        if solids:
            xx,yy=solids[0]
            assert tree.ray_cast(Vector(self.a.point((xx,yy,z+1))),direction,1.5)[0] is not None,(self.kind,name,'missing solid wall')
        self.openings += len(holes)

    def window(self, name, x, y, z, w=.85, h=1.18, shutters=True, flowers=False):
        b, beam = self.a.box, self.a.beam
        # Glazing is 20 cm behind the plaster, with visible jamb returns.
        b(name+' dark pocket', (x, y+h/2, z-.265), (w+.04, h+.04, .03), 'recess', 0)
        b(name+' recessed glazing', (x, y+h/2, z-.215), (w-.12, h-.12, .025), 'glass', .006)
        for side in (-1, 1):
            b(name+' deep jamb return', (x+side*(w/2+.01), y+h/2, z-.07), (.13, h+.20, .39), 'oak_dark')
        for dy in (0, h):
            b(name+' frame and reveal', (x, y+dy, z-.06), (w+.20, .13, .40), 'oak')
        b(name+' projecting stone sill', (x, y-.11, z+.13), (w+.38, .16, .58), 'limestone_light', .028)
        b(name+' rain hood', (x, y+h+.14, z+.12), (w+.39, .11, .47), 'oak_dark')
        for dx in (-w/6, w/6): b(name+' inner mullion', (x+dx, y+h/2, z-.17), (.034, h-.05, .06), 'oak')
        b(name+' inner transom', (x, y+h*.57, z-.17), (w-.02, .045, .06), 'oak_dark')
        if shutters:
            for side in (-1, 1):
                def shutter():
                    for j in range(3): b(name+' hinged shutter plank', (side*(j+.5)*.105, y+h/2, 0), (.099, h-.02, .065), 'oak', .009)
                    for yy in (y+.20, y+h-.20): b(name+' shutter iron strap', (side*.16, yy, .042), (.29, .035, .023), 'iron', .002)
                    beam(name+' shutter diagonal', (side*.03, y+.14, .043), (side*.29, y+h-.14, .043), .025, 'oak_dark', 4)
                self.group(shutter, x=x+side*(w/2+.12), z=z+.12, angle=-side*.25)
        if flowers:
            b(name+' supported flower box', (x, y-.34, z+.23), (w+.12, .25, .34), 'oak_dark')
            for side in (-1, 1): beam(name+' flower box bracket', (x+side*w*.32, y-.56, z+.03), (x+side*w*.32, y-.31, z+.32), .035, 'iron', 4)
            for j in range(7):
                at=(x+(j-3)*w*.13, y-.18, z+.26)
                self.a.leaf_spray(name+' window herbs', at, .14, 10)

    def door(self, x, z, y=.24, w=1.02, h=2.08):
        b, beam = self.a.box, self.a.beam
        b('Entrance dark vestibule', (x, y+h/2, z-.34), (w+.12, h+.1, .06), 'recess')
        for j in range(7): b('Recessed door boards', (x-w/2+(j+.5)*w/7, y+h/2, z-.28), (w/7-.01, h, .09), 'oak_dark', .008)
        for side in (-1, 1):
            b('Entrance full-depth reveal', (x+side*(w/2+.095), y+h/2, z-.105), (.19, h+.23, .54), 'limestone_light', .035)
        b('Entrance projecting lintel', (x, y+h+.14, z+.02), (w+.56, .25, .68), 'oak_dark', .026)
        for yy in (y+.37, y+1.57): b('Door iron hinge', (x-w*.20, yy, z-.216), (w*.46, .045, .025), 'iron')
        beam('Door brass handle', (x+w*.30, y+.88, z-.22), (x+w*.30, y+1.04, z-.22), .023, 'brass', 8)
        for j in range(3): b('Entrance worn stair', (x, .035+j*.035, z+.50-j*.18), (w+.64-j*.06, .07+j*.07, .33), 'limestone_light', .025)
        b('Entrance recessed threshold', (x, .12, z-.11), (w+.24, .24, .48), 'limestone_light', .019)

    def volume(self, name, cx, cz, w, d, bottom, top, front_holes=None, upper=False, timber=True):
        b, beam = self.a.box, self.a.beam
        def body():
            if bottom<.50:
                self.a.stone_courses(name+' grounded stone plinth',(0,0,0),(w+.035,bottom,d+.035),.47,.24)
            b(name+' floor plate', (0, bottom+.045, 0), (w, .09, d), 'oak_dark')
            b(name+' ceiling plate', (0, top-.05, 0), (w, .10, d), 'oak_dark')
            for side in range(4):
                width, depth = (w, d) if side%2==0 else (d, w)
                holes = front_holes if side==0 and front_holes is not None else ([(0, bottom+.77, min(.88,width*.32), min(1.16,top-bottom-1.05), 'window')] if top-bottom>1.6 else [])
                def facade():
                    self.wall(name+' facade '+str(side), width, bottom, top, depth/2, holes,stone=not timber)
                    if timber:
                        for x in (-width/2, width/2): b(name+' corner posts', (x, (bottom+top)/2, depth/2+.045), (.17, top-bottom, .20), 'oak_dark')
                        b(name+' load-bearing header', (0, top-.09, depth/2+.075), (width+.22, .23, .25), 'oak_dark')
                        if upper:
                            b(name+' jettied floor beam', (0, bottom+.10, depth/2+.08), (width+.22, .23, .29), 'oak_dark')
                            for x in (-width*.35, 0, width*.35):
                                beam(name+' jetty corbel', (x, bottom-.36, depth/2-.17), (x, bottom+.03, depth/2+.16), .075, 'oak_dark', 4)
                    for x, y, ww, hh, kind in holes:
                        if kind=='door': self.door(x, depth/2, y, ww, hh)
                        elif kind=='bay': self.bay(name+' projecting shop bay', x, y, depth/2, ww, hh)
                        else: self.window(name+' inset window', x, y, depth/2, ww, hh, side!=0 or kind!='plain', kind=='flowers')
                self.group(facade, angle=side*math.pi/2)
        self.group(body, x=cx, z=cz)
        self.features.append({'volume':name,'bounds_metres':[cx-w/2,bottom,cz-d/2,cx+w/2,top,cz+d/2]})

    def bay(self, name, x, y, z, w, h):
        b, beam, p = self.a.box, self.a.beam, self.a.poly
        # A trapezoidal oriel has three glazed faces, two diagonal cheeks,
        # an actual wall opening behind it, and a projecting hood/stone base.
        plan=[(-w/2,0),(-w*.37,.46),(w*.37,.46),(w/2,0)]
        for j in range(3):
            a,c=plan[j],plan[j+1]
            p(name+' three glazed faces',[(x+a[0],y,z+a[1]),(x+c[0],y,z+c[1]),(x+c[0],y+h,z+c[1]),(x+a[0],y+h,z+a[1])],[(0,1,2,3)],'glass',1)
            for dy in (0,h*.60,h): beam(name+' horizontal framing',(x+a[0],y+dy,z+a[1]+.02),(x+c[0],y+dy,z+c[1]+.02),.045,'oak_dark',4)
            for t in (.0,.5,1.):
                xx=a[0]+(c[0]-a[0])*t;zz=a[1]+(c[1]-a[1])*t
                beam(name+' bay mullions',(x+xx,y,z+zz+.02),(x+xx,y+h,z+zz+.02),.038,'oak',4)
        for yy, mat in [(y-.16,'limestone_light'),(y+h+.10,'oak_dark')]:
            vs=[(x+xx,yy+dy,z+zz) for dy in (-.08,.08) for xx,zz in [(-w/2-.12,-.07),(-w*.37-.12,.58),(w*.37+.12,.58),(w/2+.12,-.07)]]
            p(name+' shaped cornice',vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,1,.02)
        for dx in (-w*.30,w*.30): beam(name+' timber brackets',(x+dx,y-.64,z+.01),(x+dx,y-.21,z+.43),.075,'oak_dark',4)

    def roof(self, name, cx, y, cz, w, d, rise, angle=0):
        b, beam, p = self.a.box, self.a.beam, self.a.poly
        def geometry():
            vs=[(-w/2,y,-d/2),(w/2,y,-d/2),(w/2,y,d/2),(-w/2,y,d/2),(-w/2,y+rise,0),(w/2,y+rise,0)]
            p(name+' closed roof deck',vs,[(0,1,5,4),(4,5,2,3),(0,4,3),(1,2,5),(0,3,2,1)],'oak_dark')
            cols=max(4,round(w/.245));rows=max(3,round(math.hypot(d/2,rise)/.235))
            for side in (-1,1):
                for row in range(rows):
                    t0=row/rows;t1=min(1,(row+1.24)/rows)
                    cuts=sorted(set([-w/2]+[-w/2+(i+(.5 if row%2 else 1))*w/cols+self.a.RNG.uniform(-.015,.015) for i in range(cols) if -w/2+(i+(.5 if row%2 else 1))*w/cols<w/2-.035]+[w/2]))
                    for left,right in zip(cuts,cuts[1:]):
                        left+=.008;right-=.008
                        if right-left<.015:continue
                        lip=self.a.RNG.uniform(-.020,.020);lift=self.a.RNG.uniform(-.008,.008)
                        verts=[]
                        for level in (0,.036):
                            for v in (0,.5,1):
                                t=t0+(t1-t0)*v
                                for u in (0,.25,.5,.75,1):
                                    # Curved tile crown, thick lower lip, and
                                    # overlap normal to the roof plane.
                                    # A small eroded notch changes the lip
                                    # silhouette without making every tile puffy.
                                    notch=.017 if u==.25 and v==0 and (row+int(left*43))%9==0 else 0
                                    yy=y+t*rise+.043+level+.038*(1-v)+.020*math.sin(math.pi*u)+lift-notch
                                    verts.append((left+(right-left)*u,yy,side*(d/2*(1-t)+lip*(1-v))))
                        faces=[]
                        for j in range(2):
                            for i in range(4):
                                n=j*5+i
                                faces.extend([(n,n+5,n+6,n+1),(n+15,n+16,n+21,n+20)])
                        border=[0,1,2,3,4,9,14,13,12,11,10,5]
                        faces += [(a,c,c+15,a+15) for a,c in zip(border,border[1:]+border[:1])]
                        if side<0:faces=[tuple(reversed(f)) for f in faces]
                        p(name+' curved overlapping solid tiles',verts,faces,'roof',self.a.RNG.uniform(.77,1.10),.006)
                beam(name+' deep eave fascia',(-w/2,y-.04,side*d/2),(w/2,y-.04,side*d/2),.105,'oak_dark',4)
                for i in range(max(3,int(w/.48))):
                    xx=-w/2+.18+i*(w-.36)/max(1,int(w/.48)-1)
                    beam(name+' exposed rafter tails',(xx,y-.16,side*(d/2-.34)),(xx,y-.13,side*(d/2+.08)),.045,'oak',4)
            for side in (-1,1):
                xx=side*(w/2+.012)
                p(name+' inset plaster gable',[(xx,y+.035,-d/2+.13),(xx,y+.035,d/2-.13),(xx,y+rise-.11,0)],[(0,2,1) if side>0 else (0,1,2)],'plaster',.91)
                for zz in (-1,1):beam(name+' sculpted barge board',(xx,y-.07,zz*d/2),(xx,y+rise+.09,0),.10,'oak_dark',4)
                beam(name+' gable king post',(xx,y+.04,0),(xx,y+rise-.02,0),.067,'oak_dark',4)
                beam(name+' gable tie beam',(xx,y+.13,-d/2+.07),(xx,y+.13,d/2-.07),.073,'oak_dark',4)
            for j in range(max(2,round(w/.29))):
                xx=-w/2+(j+.5)*w/max(2,round(w/.29))
                beam(name+' rounded ridge cap',(xx-.16,y+rise+.11,0),(xx+.16,y+rise+.11,0),.12,'roof',10)
        self.group(geometry,x=cx,z=cz,angle=angle)

    def dormer(self, name, cx, cz, bottom, top, w=.95):
        self.volume(name,cx,cz,w,.87,bottom,top,[(0,bottom+.08,w*.65,top-bottom-.19,'plain')],timber=True)
        self.roof(name+' cross gable',cx,top,cz,.99,w+.30,.55,math.pi/2)

    def balcony(self, cx, y, z, w, depth=.72):
        b, beam = self.a.box,self.a.beam
        for j in range(7): b('Balcony projecting planks',(cx,y,z+(j+.5)*depth/7),(w,.09,depth/7-.007),'oak')
        for xx in (cx-w/2,cx+w/2):
            b('Balcony supported newel',(xx,y+.48,z+depth),(.13,1.04,.13),'oak_dark')
            beam('Balcony diagonal load support',(xx,y-.76,z-.08),(xx,y-.07,z+depth-.10),.082,'oak_dark',4)
            b('Balcony side handrail',(xx,y+.93,z+depth/2),(.11,.10,depth),'oak_dark')
            for zz in (.20,.44,.64):b('Balcony side spindles',(xx,y+.46,z+zz),(.055,.85,.055),'oak')
        b('Balcony front handrail',(cx,y+.93,z+depth),(w+.20,.13,.15),'oak_dark')
        for j in range(max(4,round(w/.22))):
            xx=cx-w/2+.08+j*(w-.16)/(max(4,round(w/.22))-1)
            b('Balcony turned spindle',(xx,y+.46,z+depth),(.047,.83,.055),'oak')

    def lantern(self,x,y,z):
        b,beam=self.a.box,self.a.beam
        beam('Wall lantern bent bracket',(x,y+.25,z),(x,y+.25,z+.34),.024,'iron',6)
        b('Lantern warm panes',(x,y-.03,z+.32),(.15,.27,.15),'brass',.01)
        for dy in (-.20,.14):b('Lantern iron cap',(x,y+dy,z+.32),(.24,.06,.24),'iron')
        for sx in (-1,1):
            for sz in (-1,1):b('Lantern frame',(x+sx*.085,y-.025,z+.32+sz*.085),(.02,.29,.02),'iron')

    def build(self):
        a=self.a;w,d=self.w,self.d;front=d/2
        base=self.kind.split('_sage')[0].split('_clay')[0].split('_ash')[0].split('_mauve')[0]
        if base in ('forge','market_hall'):
            self.workplace(base)
        elif base=='guild':
            cw=w*.53
            self.volume('Guild central hall',0,-.08,cw,d-.16,.24,5.65,[(0,.24,1.18,2.26,'door'),(-cw*.30,3.35,.93,1.53,'plain'),(cw*.30,3.35,.93,1.53,'plain')],timber=False)
            self.roof('Guild main roof',0,5.65,-.08,cw+.49,d+.25,1.90)
            for side in (-1,1):
                aw=w*.25;cx=side*(w/2-aw/2);az=-d*.12;ah=3.25 if side<0 else 3.85
                self.volume('Guild stepped side wing',cx,az,aw,d*.72,.24,ah,[(0,1.12,.97,1.55,'plain')],timber=False)
                self.roof('Guild wing roof',cx,ah,az,aw+.30,d*.72+.32,1.10)
            a.civic_clock_tower(cw,5.65,front-.16)
            self.record['entry_metres']=[0,0,front-.16]
        else:
            annex=base in ('inn','garden_house','pet_lodge','apothecary')
            two=base in ('baker_house','inn','apothecary','townhouse')
            split=(.80 if base=='apothecary' else .71) if annex else 1
            sign=-1 if self.kind=='garden_house_ash' else 1
            mw=w*split;cx=-sign*w*(1-split)/2;cz=-.17 if annex else -.09
            md=d-.46;lower_front=cz+md/2
            low_w=mw-.28;low_d=md-.23
            low_front=cz+low_d/2
            local_door=self.door_x-cx
            holes=[(local_door,.24,1.00,2.05,'door')]
            if base=='baker_house':
                holes += [(-mw*.28,1.02,1.15,1.38,'bay'),(mw*.28,1.02,1.15,1.38,'bay')]
            elif not annex:
                holes += [(-mw*.29,1.02,.83,1.17,'flowers'),(mw*.29,1.02,.83,1.17,'flowers')]
            else:
                wx=-mw*.27 if local_door>=0 else mw*.27
                if abs(wx-local_door)>1.01:holes += [(wx,1.04,.72,1.15,'flowers')]
            self.volume('Recessed ground storey',cx,cz,low_w,low_d,.24,2.93,holes)
            top=5.27 if two else 3.07
            if two:
                upper_holes=[(-mw*.27,3.38,.81,1.26,'flowers'),(mw*.27,3.38,.81,1.26,'flowers')]
                if base=='townhouse':upper_holes=[(0,3.40,1.54,1.35,'bay')]
                self.volume('Projecting upper storey',cx,cz,mw,md,2.93,top,upper_holes,True)
            self.roof('Main dwelling roof',cx,top,cz,mw+.51,md+.56,1.65 if two else 1.38)
            if annex:
                aw=w-mw+.15;ax=sign*(w/2-aw/2);ad=d*.67;az=front-ad/2-.05;ah=2.55 if base!='apothecary' else 3.37
                self.volume('Lower attached side room',ax,az,aw,ad,.24,ah,[(0,.99,min(.82,aw*.65),1.12,'plain')])
                self.roof('Annex cross roof',ax,ah,az,ad+.34,aw+.34,.72,math.pi/2)
                self.features.append({'feature':'attached lower side room','height_difference':top-ah})
            if base=='inn':
                self.balcony(cx,3.03,lower_front+.05,mw*.94,.79)
                for dx in (-mw*.22,mw*.22): self.dormer('Inn paired dormer',cx+dx,cz+.63,6.18,7.01,.73)
                a.shop_sign(cx-mw*.43,2.39,low_front+.44,base)
            elif base=='baker_house':
                a.awning(cx,2.91,low_front+.13,mw*.90,1.02)
                self.dormer('Bakery attic dormer',cx+mw*.10,cz+.68,6.18,7.04,1.08)
                for dx in (-mw*.28,mw*.28):
                    a.box('Bakery deep display ledge',(cx+dx,.89,low_front+.47),(1.33,.14,.56),'oak_dark')
                    for j in range(6):a.ellipsoid('Bakery fresh loaves',(cx+dx+(j-2.5)*.18,1.04,low_front+.46),(.12,.07,.09),'bread')
                a.shop_sign(cx-mw*.44,2.39,low_front+.56,base)
            elif base=='apothecary':
                a.shop_sign(cx-mw*.40,2.50,low_front+.43,base)
                for j in range(8):
                    at=(cx-mw*.45+.07*math.sin(j),.40+j*.44,lower_front+.06)
                    a.leaf_spray('Herbalist climbing trellis',at,.17,18)
            elif base=='townhouse':
                self.dormer('Townhouse cross gable',cx,cz+.66,6.18,7.04,1.48)
            else:
                self.roof('Sheltered entrance porch',self.door_x,2.64,low_front+.39,1.84,1.29,.51)
                for dx in (-.75,.75):
                    a.box('Porch support posts',(self.door_x+dx,1.31,low_front+.83),(.12,2.62,.12),'oak_dark')
                    a.beam('Porch knee brace',(self.door_x+dx,2.00,low_front+.83),(self.door_x+dx*.55,2.57,low_front+.83),.061,'oak',4)
            chimney_x=cx-mw*.25
            a.chimney(chimney_x,cz-.42,top+.58,1.73,.61)
            self.lantern(self.door_x-.77,1.98,low_front)
            self.record['entry_metres']=[self.door_x,0,low_front+.13]
        self.record['structure_revision']='occupied-volumes-v1'
        self.record['structure_features']=self.features
        self.record['through_opening_count']=self.openings
        self.record['opening_mesh_ray_checks']=self.opening_ray_checks
        self.record['opening_depth_metres']=.28
        # The visible threshold may recede beneath the upper-floor footprint.
        # Keep its true position but put the interaction landing outside the
        # collision envelope; frontage paving spans that full recess.
        self.record['entrance_approach_metres']=max(.75,self.record['footprint'][1]/64+.40-self.record['entry_metres'][2])
        return self.record

    def workplace(self,base):
        a=self.a;w,d=self.w,self.d;front=d/2
        if base=='forge':
            cw=w*.46;cx=-w/2+cw/2
            self.volume('Smith enclosed workroom',cx,-.16,cw,d-.34,.24,3.12,[(0,.96,.82,1.20,'plain')],timber=False)
            self.roof('Smith taller roof',cx,3.12,-.16,cw+.30,d+.10,1.45)
            bw=w-cw;bx=w/2-bw/2
            a.stone_courses('Forge recessed back wall',(bx,0,-d/2+.16),(bw,2.84,.28),.44,.27)
            a.stone_courses('Forge side pier',(w/2-.16,0,front-.1),(.32,2.84,.34),.42,.26)
            a.box('Forge grounded work paving',(bx,.055,0),(bw,.11,d),'limestone_dark',.018)
            self.roof('Forge lower work canopy',bx,2.85,.06,bw+.22,d+.23,.69)
            a.box('Forge canopy post',(cw-w/2,1.44,front-.03),(.16,2.88,.16),'oak_dark')
            a.beam('Forge diagonal brace',(cw-w/2,2.11,front-.03),(cw-w/2+.60,2.79,front-.03),.083,'oak_dark',4)
            a.box('Forge hearth',(bx+.28,.43,-d*.10),(1.03,.86,.80),'limestone_dark')
            for j in range(12):a.ellipsoid('Forge glowing coals',(bx+.28+a.RNG.uniform(-.36,.36),.92,-d*.10+a.RNG.uniform(-.25,.25)),(.07,.04,.08),'ember')
            a.box('Smith anvil stump',(bx-.12,.40,front-.46),(.51,.70,.47),'oak_dark')
            a.box('Smith iron anvil',(bx-.12,.81,front-.46),(.75,.15,.35),'iron')
            a.chimney(cx-.20,-.41,3.60,2.75,.88)
            a.shop_sign(cx-.56,2.36,front-.05,base)
        else:
            self.wall('Market backing',w,.20,2.82,-d/2+.10,[])
            # The city uses this hall in its rear-facing orientation. Give
            # the outside its own finish and structural frame as well.
            self.group(lambda:self.wall('Market exterior backing',w,.20,2.82,d/2+.19,[]),angle=math.pi)
            a.stone_courses('Market wall grounded base',(0,0,-d/2-.03),(w,.27,.39),.47,.27)
            for xx in (-w/2,-w/6,w/6,w/2):
                a.box('Market exterior timber uprights',(xx,1.43,-d/2-.23),(.15,2.86,.17),'oak_dark')
            for yy in (.39,2.75):a.box('Market exterior binding beam',(0,yy,-d/2-.24),(w+.13,.18,.18),'oak_dark')
            for xx in (-w/3,0,w/3):
                a.beam('Market exterior diagonal framing',(xx-w*.125,.48,-d/2-.24),(xx+w*.125,2.65,-d/2-.24),.065,'oak_dark',4)
            for xx in (-w/2,-w/6,w/6,w/2):
                for zz in (-d/2,front):
                    a.box('Market arcade column',(xx,1.47,zz),(.17,2.94,.17),'oak_dark')
                    a.beam('Market arcade brace',(xx,2.16,zz),(xx+(.41 if xx<0 else -.41),2.77,zz),.08,'oak_dark',4)
            self.roof('Market lower arcade roof',0,2.94,0,w+.40,d+.40,1.14)
            self.volume('Raised market clerestory',0,-.06,w*.40,d*.42,3.57,4.15,[(0,3.64,w*.24,.35,'plain')])
            self.roof('Market monitor roof',0,4.15,-.06,w*.40+.22,d*.42+.22,.54)
            for j in range(3):
                xx=(j-1)*w*.29
                a.box('Market projecting counter',(xx,.91,front-.19),(w*.24,.16,.75),'oak')
                for dx in (-w*.09,w*.09):
                    for zz in (front-.48,front+.07):a.box('Market counter legs',(xx+dx,.43,zz),(.08,.86,.08),'oak_dark')
                for k in range(8):a.ellipsoid('Market produce',(xx+a.RNG.uniform(-.40,.40),1.06,front-.18+a.RNG.uniform(-.21,.21)),(.09,.07,.08),'bread' if j%2 else 'leaf')
        self.record['entry_metres']=[0,0,front+.12]
        self.features.append({'feature':'open workplace with unequal roof heights'})


def build(kind, record, api):
    return Architecture(api, kind, record).build()
