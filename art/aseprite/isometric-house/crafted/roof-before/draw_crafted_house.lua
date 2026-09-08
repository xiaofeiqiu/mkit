-- Hand-authored 2:1 cottage, material and weathering study in native Aseprite.
-- All surfaces are painted through Aseprite Image:drawPixel; no raster input is traced.
local W,H,S=512,480,2
local out=app.params.output or app.fs.filePath(app.scriptPath)
app.fs.makeAllDirectories(out)
local spr=Sprite(W,H,ColorMode.RGB)
local im,layer
local pi=math.pi
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function round(v) return math.floor(v+.5) end
local function rgb(r,g,b,a) return app.pixelColor.rgba(clamp(round(r),0,255),clamp(round(g),0,255),clamp(round(b),0,255),a or 255) end
local function shade(c,n) return rgb(c[1]+n,c[2]+n*.94,c[3]+n*.78) end
local function hash(x,y,k)
  local n=math.sin(x*127.1+y*311.7+(k or 0)*73.19)*43758.5453123
  return n-math.floor(n)
end
local function noise(x,y,k)
  local ix,iy=math.floor(x),math.floor(y)
  local fx,fy=x-ix,y-iy; fx=fx*fx*(3-2*fx); fy=fy*fy*(3-2*fy)
  return (hash(ix,iy,k)*(1-fx)+hash(ix+1,iy,k)*fx)*(1-fy)+(hash(ix,iy+1,k)*(1-fx)+hash(ix+1,iy+1,k)*fx)*fy
end
local seed=1087
local function rand(a,b) seed=(seed*48271)%2147483647; return a+seed%(b-a+1) end
local ink=rgb(53,49,40)
local stone={157,148,123}; local mortar={87,84,70}
local oak={96,77,51}; local plaster={195,187,153}
local terracotta={156,78,43}; local teal={70,89,72}
local function px(x,y,c)
  x,y=round(x),round(y)
  if x>=0 and y>=0 and x<W and y<H then
    local a=app.pixelColor.rgbaA(c)
    if a<255 then
      local old=im:getPixel(x,y);local oa=app.pixelColor.rgbaA(old)
      if oa>0 then
        local fa=a/255;local ba=oa/255*(1-fa);local alpha=fa+ba
        c=rgb((app.pixelColor.rgbaR(c)*fa+app.pixelColor.rgbaR(old)*ba)/alpha,(app.pixelColor.rgbaG(c)*fa+app.pixelColor.rgbaG(old)*ba)/alpha,(app.pixelColor.rgbaB(c)*fa+app.pixelColor.rgbaB(old)*ba)/alpha,round(alpha*255))
      end
    end
    im:drawPixel(x,y,c)
  end
end
local function line(a,b,c,width)
  local x,y,x2,y2=round(a[1]),round(a[2]),round(b[1]),round(b[2])
  local dx,dy=math.abs(x2-x),-math.abs(y2-y); local sx,sy=x<x2 and 1 or -1,y<y2 and 1 or -1; local err=dx+dy
  while true do
    for u=0,(width or 1)-1 do for v=0,(width or 1)-1 do px(x+u,y+v,c) end end
    if x==x2 and y==y2 then break end
    local e=2*err; if e>=dy then err=err+dy; x=x+sx end; if e<=dx then err=err+dx; y=y+sy end
  end
end
local function poly(pts,c,border)
  local lo,hi=H,0; for _,p in ipairs(pts) do lo=math.min(lo,p[2]);hi=math.max(hi,p[2]) end
  for y=math.max(0,math.ceil(lo)),math.min(H-1,math.floor(hi)) do
    local xs={}
    for i,a in ipairs(pts) do local b=pts[i%#pts+1]
      if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]) end
    end
    table.sort(xs); for i=1,#xs-1,2 do for x=math.ceil(xs[i]),math.floor(xs[i+1]) do px(x,y,c) end end
  end
  if border then for i,a in ipairs(pts) do line(a,pts[i%#pts+1],border) end end
end
local function ellipse(x,y,rx,ry,c,border)
  local pts={};for i=0,47 do local a=i*pi/24;pts[#pts+1]={round(x+math.cos(a)*rx),round(y+math.sin(a)*ry)} end;poly(pts,c,border)
end
local function P(x,y,z) return {256+(x-y)*S,296+(x+y)*S/2-(z or 0)*S} end
local function world(ps,c,border) local pts={};for _,p in ipairs(ps) do pts[#pts+1]=P(table.unpack(p)) end;poly(pts,c,border) end
local function edge(a,b,c,w) line(P(table.unpack(a)),P(table.unpack(b)),c,w) end
local function begin(name) layer=spr:newLayer();layer.name=name;im=Image(W,H,ColorMode.RGB);im:clear() end
local function finish() spr:newCel(layer,1,im,Point(0,0)) end

-- Affine material painter. UVs follow each actual surface, including roof slopes.
local function face(a,b,d,uw,vh,material,base,k,lit)
  local ex,ey=b[1]-a[1],b[2]-a[2];local fx,fy=d[1]-a[1],d[2]-a[2]
  local det=ex*fy-ey*fx;if math.abs(det)<.001 then return end
  local c={b[1]+fx,b[2]+fy}
  local minx=math.max(0,math.floor(math.min(a[1],b[1],c[1],d[1])))
  local maxx=math.min(W-1,math.ceil(math.max(a[1],b[1],c[1],d[1])))
  local miny=math.max(0,math.floor(math.min(a[2],b[2],c[2],d[2])))
  local maxy=math.min(H-1,math.ceil(math.max(a[2],b[2],c[2],d[2])))
  k=k or 1;lit=lit or 0
  for y=miny,maxy do for x=minx,maxx do
    local dx,dy=x+.5-a[1],y+.5-a[2]
    local u=(dx*fy-dy*fx)/det;local v=(ex*dy-ey*dx)/det
    if u>=0 and u<=1 and v>=0 and v<=1 then
      local tx,ty=u*uw*S,v*vh*S
      local grain=(hash(x,y,k)-.5)*5
      local n=(noise(tx/7,ty/7,k)-.5)*14+(noise(tx/2.5,ty/2.5,k+1)-.5)*6+grain+lit
      local rr,gg,bb=0,0,0
      if material=='stone' or material=='paver' then
        n=n+(noise(tx/18,ty/12,k+4)-.5)*20+(noise(tx/3.2,ty/3.2,k+12)-.5)*18
        local bevel=math.min(u*uw*S,(1-u)*uw*S,v*vh*S,(1-v)*vh*S)
        if bevel<1.4 then n=n+(v>.85 and 17 or -18) end
        if u<.045 then n=n+9 end
        if hash(math.floor(tx/2),math.floor(ty/2),k+3)>.975 then n=n-14 end
        if k%8==0 and ty>vh*S*.4 and math.abs(tx-uw*S*.53-math.sin(ty*.63)*1.2)<.43 then n=n-35 end
        if k%7==0 and noise(tx/2,ty/2,k+3)>.69 then n=n+17 end
        if material=='paver' and v<.09 then n=n+28 end
      elseif material=='plaster' then
        n=n+(noise(tx/25,ty/18,k)-.5)*21
        local stain=noise(tx/5,ty/45,k+6)
        n=n-12*math.max(0,.5-v)*stain
        if k%3==0 and v<.28 and noise(tx/5,ty/6,k+7)>.64 then n=n-18 end
      elseif material=='wood' then
        local wave=tx+noise(tx/8,ty/24,k)*2.3
        local fiber=noise(wave*1.4,ty/18,k+2)
        n=n+(fiber-.5)*27
        if fiber<.27 then n=n-15 end
        if u<.09 then n=n+18 end
        if u>.88 or v<.06 then n=n-16 end
        if hash(math.floor(tx),math.floor(ty/8),k+8)>.968 then n=n-16 end
        local knot=math.sqrt(((tx-uw*S*.55)*1.8)^2+((ty-vh*S*.36)*.55)^2)
        if k%3==0 and knot<3.7 then n=n-14+math.sin(knot*4)*14 end
      elseif material=='roof' then
        n=n+math.sin(v*pi)*8
        if u>.86 then n=n+18 elseif u<.13 then n=n-14 end
        if v<.08 or v>.94 then n=n-15 end
        local striation=noise(tx/12,ty/1.7,k+5)
        n=n+(striation-.5)*10
        if hash(math.floor(tx/2),math.floor(ty/2),k+4)>.978 then n=n-15 end
        if k%17==0 and u>.35 then
          local moss=noise(tx/3,ty/3,k)
          if moss>.5 then rr=-18;gg=15;bb=4 end
        end
      elseif material=='glass' then
        n=n+(u-v)*14
        if v>.55 and u<.48 then n=n+22 end
        if u<.1 or v>.88 then n=n-20 end
      end
      n=round(n/2)*2
      px(x,y,rgb(base[1]+n+rr,base[2]+n*.93+gg,base[3]+n*.8+bb))
    end
  end end
end
local function worldface(a,b,d,uw,vh,material,base,k,lit) face(P(table.unpack(a)),P(table.unpack(b)),P(table.unpack(d)),uw,vh,material,base,k,lit) end
local function box(x1,y1,x2,y2,z1,z2,base,mat,k)
  worldface({x1,y2,z1},{x2,y2,z1},{x1,y2,z2},x2-x1,z2-z1,mat,base,k,8)
  worldface({x2,y1,z1},{x2,y2,z1},{x2,y1,z2},y2-y1,z2-z1,mat,base,k+2,-17)
  worldface({x1,y1,z2},{x2,y1,z2},{x1,y2,z2},x2-x1,y2-y1,mat,base,k+4,18)
  edge({x1,y2,z1},{x2,y2,z1},shade(base,-40));edge({x2,y1,z1},{x2,y2,z1},shade(base,-48))
  edge({x1,y2,z2},{x2,y2,z2},shade(base,29));edge({x2,y1,z2},{x2,y2,z2},shade(base,8))
end
local function surface(side,u,z,offset)
  if side=='front' then return P(u,32+(offset or 0),z) end
  return P(40+(offset or 0),u,z)
end
local function wallRect(side,u,z,w,h,mat,base,k,lit,offset)
  face(surface(side,u,z,offset),surface(side,u+w,z,offset),surface(side,u,z+h,offset),w,h,mat,base,k,(lit or 0)+(side=='right' and -20 or 8))
end
local function wallLine(side,u,z,v,zz,c,width,off) line(surface(side,u,z,off),surface(side,v,zz,off),c,width) end
local function wallPoly(side,ps,c,border,off) local pp={};for _,p in ipairs(ps) do pp[#pp+1]=surface(side,p[1],p[2],off) end;poly(pp,c,border) end
local function masonry(side,u0,u1,z0,z1,size)
  wallRect(side,u0,z0,u1-u0,z1-z0,'plaster',mortar,73)
  local row=0;local z=z0
  while z<z1 do
    local h=math.min(rand(4,6),z1-z);local u=u0-(row%2)*4
    while u<u1 do
      local w=rand(size-2,size+3);local l,r=math.max(u0,u),math.min(u1,u+w)
      if r-l>1 then
        local k=rand(1,700);local b={stone[1]+rand(-14,14),stone[2]+rand(-9,9),stone[3]+rand(-8,8)}
        wallRect(side,l+.25,z+.3,r-l-.5,h-.6,'stone',b,k)
      end
      u=u+w
    end
    z=z+h;row=row+1
  end
end

-- Artwork layers follow below.
spr.layers[1].name='00 · Warm paper (optional)'
im=Image(W,H,ColorMode.RGB);im:clear(Color{r=230,g=226,b=213,a=255});spr.cels[1].image=im;spr.layers[1].isVisible=false

begin('01 · Irregular cobbled footing')
local outline={{-55,-46,-9},{-46,-55,-9},{44,-55,-9},{55,-44,-9},{55,44,-9},{44,55,-9},{-44,55,-9},{-55,44,-9}}
local lower={};for _,p in ipairs(outline) do lower[#lower+1]={p[1],p[2],-12} end
world(lower,rgb(91,85,64),rgb(66,67,49))
world(outline,rgb(98,99,74))
for y=-52,49,5.5 do
  for x=-52,49,7.5 do
    local xx=x+((round(y*2)%2)*2)
    if math.abs(xx)+math.abs(y)<98 then
      local b={stone[1]+rand(-16,8),stone[2]+rand(-14,8),stone[3]+rand(-9,8)}
      worldface({xx,y,-8.8},{xx+6.8,y,-8.8},{xx,y+4.7,-8.8},6.8,4.7,'paver',b,rand(1,600),0)
    end
  end
end
for i=1,105 do
  local x,y=rand(-54,54),rand(-54,54)
  if math.abs(x)+math.abs(y)<99 and (math.abs(x)>40 or math.abs(y)>36) then
    local p=P(x,y,-8)
    for j=1,rand(2,5) do
      local dx,dy=rand(-3,3),rand(-2,2)
      px(p[1]+dx,p[2]+dy,rgb(98+rand(-16,12),113+rand(-14,15),65+rand(-10,9)))
    end
  end
end
finish()


begin('02 · Ground shadow and contact')
world({{-35,-31,-8},{43,-31,-8},{55,-17,-8},{54,41,-8},{31,51,-8},{-26,39,-8}},rgb(43,47,38,90))
world({{-39,30,-8},{41,30,-8},{41,36,-8},{-39,36,-8}},rgb(35,38,30,110))
finish()

begin('03 · Weathered limestone and limewash')
box(-41,-33,41,33,-8,3,stone,'stone',8)
wallRect('front',-40,3,80,62,'plaster',plaster,41,7)
wallRect('right',-32,3,64,62,'plaster',plaster,45,-4)
masonry('front',-40,40,3,22,8)
masonry('right',-32,32,3,22,8)
wallPoly('front',{{-40,65},{0,94},{40,65}},shade(plaster,14),ink)
-- Plaster chips expose a few stones where rain and splashing occur.
for _,r in ipairs({{-36,24,8,3},{-28,24,7,2},{28,25,9,4},{-36,28,6,3}}) do
  wallRect('front',r[1],r[2],r[3],r[4],'stone',stone,rand(1,800))
end
-- Soft stains run down from eaves and sills, in the plane of the wall.
for sidei,side in ipairs({'front','right'}) do
  for i=1,55 do
    local u=side=='front' and rand(-38,38) or rand(-30,30)
    local z=rand(23,57);local p=surface(side,u,z)
    if i%3==0 then line(p,{p[1],p[2]+rand(1,5)},rgb(128,121,88,rand(25,65))) end
  end
end
-- Graded occlusion under the long eaves and darker drip lines beneath sills.
for i=0,6 do
  local alpha=round(67-i*8)
  wallPoly('right',{{-32,64-i},{32,64-i},{32,65-i},{-32,65-i}},rgb(47,47,32,alpha))
  wallPoly('front',{{-40,63-i},{40,63-i},{40,64-i},{-40,64-i}},rgb(71,61,37,round(alpha*.6)))
end
for _,s in ipairs({{'front',-29,25,20},{'right',-24,25,18},{'right',8,25,17}}) do
  for i=0,5 do
    wallPoly(s[1],{{s[2],s[3]-i},{s[2]+s[4],s[3]-i},{s[2]+s[4],s[3]+1-i},{s[2],s[3]+1-i}},rgb(62,63,39,round(45-i*6)))
  end
end
finish()

local function hbeam(side,u,z,w,h,k)
  face(surface(side,u,z),surface(side,u,z+h),surface(side,u+w,z),h,w,'wood',oak,k,side=='front' and 6 or -9)
  wallLine(side,u,z+h,u+w,z+h,rgb(143,118,78))
  wallLine(side,u,z,u+w,z,rgb(57,50,36))
end
begin('04 · Aged oak posts, braces and joinery')
for _,x in ipairs({-40,-4,37}) do
  wallRect('front',x-.6,3,4.6,62,'plaster',{69,61,43},78)
  wallRect('front',x,3,3.4,62,'wood',oak,rand(1,800))
  wallLine('front',x,4,x,63,rgb(151,129,91))
end
for _,y in ipairs({-32,-1,29}) do wallRect('right',y,3,3.2,62,'wood',oak,rand(1,800)) end
for _,z in ipairs({3,22,61}) do hbeam('front',-40,z,80,3,rand(1,800));hbeam('right',-32,z,64,3,rand(1,800)) end
wallRect('front',-1.5,65,3,27,'wood',oak,244)
for _,u in ipairs({-36,23}) do
  local ps=u<0 and {{u,56},{u+12,64},{u+15,64},{u,53}} or {{u,64},{u+3,64},{u+15,54},{u+15,51}}
  wallPoly('front',ps,shade(oak,-4),shade(oak,-35))
end
for _,t in ipairs({{-40,5},{-39,25},{-3,24},{38,24},{-39,59},{38,59}}) do
  local p=surface('front',t[1]+1,t[2]+1)
  px(p[1],p[2],rgb(45,43,37));px(p[1]+1,p[2]-1,rgb(165,147,104))
end
finish()

local function window(side,u,z,w,h,shutters)
  wallRect(side,u-2.5,z-3,w+5,h+6,'wood',{62,55,41},61,-4,1)
  wallRect(side,u-1.5,z-1.5,w+3,h+3,'wood',{139,117,79},62,2,1.2)
  wallRect(side,u,z,w,h,'glass',{73,89,77},63,0,1.4)
  -- Individual panes and diamond lead lines.
  wallRect(side,u+1,z+1,w/2-1.8,h-2,'glass',{110,123,98},64,5,1.6)
  wallRect(side,u+w/2+.8,z+1,w/2-1.8,h-2,'glass',{91,108,90},67,0,1.6)
  for dz=-w,h,5 do
    local x1=math.max(0,-dz);local x2=math.min(w,h-dz)
    if x2>x1 then wallLine(side,u+x1,z+dz+x1,u+x2,z+dz+x2,rgb(64,66,50),1,1.7) end
  end
  for dz=0,w+h,5 do
    local x1=math.max(0,dz-h);local x2=math.min(w,dz)
    if x2>x1 then wallLine(side,u+x1,z+dz-x1,u+x2,z+dz-x2,rgb(67,70,53),1,1.7) end
  end
  wallRect(side,u+w/2-.6,z,1.2,h,'wood',{157,134,91},87,0,1.8)
  wallRect(side,u,z+h*.52,w,1.2,'wood',{137,114,73},88,0,1.8)
  if shutters then
    for _,s in ipairs({u-9,u+w+3}) do
      wallRect(side,s,z-1,5.7,h+2,'wood',teal,rand(1,600),0,1.2)
      for a=s+1.8,s+5.7,1.8 do wallLine(side,a,z,a,z+h,shade(teal,-22),1,1.3) end
      for _,zz in ipairs({z+3,z+h-3}) do wallLine(side,s,zz,s+5.7,zz,rgb(101,106,74),2,1.4) end
      wallLine(side,s+.8,z+4,s+4.6,z+h-4,rgb(93,99,69),2,1.5)
    end
  end
  if side=='front' then box(u-3,33,u+w+3,36,z-5,z-2,stone,'stone',137)
  else box(41,u-3,44,u+w+3,z-5,z-2,stone,'stone',139) end
end
begin('05 · Recessed leaded windows and shutters')
window('front',-28,31,16,24,true)
window('right',-23,31,14,23,false)
window('right',9,31,14,23,false)
-- Carved attic vent.
wallRect('front',-5,73,10,13,'wood',{70,59,40},432)
for i=-4,4,2 do wallRect('front',i,74,1,11,'wood',{148,131,92},400+i) end
hbeam('front',-6,72,12,1.5,47);hbeam('front',-6,86,12,1.5,48)
finish()

begin('06 · Oak arch, ironwork and worn entry stones')
wallPoly('front',{{7,3},{32,3},{32,37},{30,44},{25,49},{19,51},{13,48},{8,43},{7,37}},rgb(54,48,36),ink,1)
wallPoly('front',{{10,4},{29,4},{29,36},{27,43},{23,47},{19,48},{14,44},{11,39},{10,34}},rgb(99,91,63),nil,1.1)
wallRect('front',11,5,17,31,'wood',{88,96,69},132,3,1.2)
for x=11,27,3 do wallLine('front',x,6,x,35,rgb(54,65,46),1,1.4) end
wallPoly('front',{{12,33},{27,33},{27,36},{25,41},{21,45},{18,44},{14,40},{12,36}},rgb(171,158,100),rgb(56,52,38),1.3)
for x=14,25,3 do wallLine('front',x,34,math.min(26,x+5),39,rgb(78,73,47),1,1.4) end
wallLine('front',12,33,27,33,rgb(156,132,85),2,1.5)
-- Individually cut arch stones; each voussoir has a darker joint and a chipped lip.
for i=0,8 do
  local a=i*pi/8;local b=(i+1)*pi/8-.04
  if i<8 then
    local pts={{19.5+12.5*math.cos(a),37+14*math.sin(a)},{19.5+12.5*math.cos(b),37+14*math.sin(b)},{19.5+10*math.cos(b),37+11.4*math.sin(b)},{19.5+10*math.cos(a),37+11.4*math.sin(a)}}
    wallPoly('front',pts,shade(stone,rand(-4,21)),shade(stone,-50),1.7)
  end
end
for z=4,33,6 do
  wallRect('front',7.4,z,2.3,5.5,'stone',stone,z,12,1.5)
  wallRect('front',29.3,z,2.3,5.5,'stone',stone,z+1,0,1.5)
end
for _,z in ipairs({12,28}) do
  wallLine('front',12,z,18,z,rgb(42,43,33),2,1.6)
  for x=13,17,3 do local p=surface('front',x,z+.3,1.7);px(p[1],p[2],rgb(147,137,100)) end
end
local kn=surface('front',25,22,1.8);ellipse(kn[1],kn[2],2,3,rgb(57,53,37),ink);px(kn[1]-1,kn[2]-2,rgb(196,161,79))
box(6,33,34,37,-8,3,stone,'stone',87)
box(6,38,34,41,-8,0,stone,'stone',89)
box(6,42,34,45,-8,-3,stone,'stone',91)
for z=0,2 do
  local p=P(13+z*4,42-z*4,-3+z*3)
  line(p,{p[1]+13,p[2]+6},rgb(186,176,148))
end
finish()

local function roofP(x,y,lift) return P(x,y,96-math.abs(x)*30/48+(lift or 0)) end
begin('07 · Overlapping clay tiles / eave carpentry')
for y=-36,36,8 do box(39,y,48,y+1.5,59,62,oak,'wood',round(y+90)) end
world({{-48,40,62},{0,40,92},{48,40,62},{48,40,66},{0,40,96},{-48,40,66}},shade(oak,-20),ink)
worldface({48,-40,62},{48,40,62},{48,-40,66},80,4,'wood',oak,310,-16)
local function roofTile(x1,y1,x2,y2,k,far,row)
  local v=rand(-15,15)
  local b={terracotta[1]+v,terracotta[2]+v*.6,terracotta[3]+v*.35}
  if k%19==0 then b={122+v,109+v,76+v*.5} end
  face(roofP(x1,y1),roofP(x2,y1),roofP(x1,y2),math.abs(x2-x1)*1.18,y2-y1,'roof',b,k,(far and 26 or 9)-row*.8)
  line(roofP(x2,y1),roofP(x2,y2),shade(b,-36))
  line(roofP(x2-.45,y1+.3),roofP(x2-.45,y2-.4),shade(b,30))
  if k%9==0 then
    local p=roofP(x2-.7,y1+1)
    px(p[1],p[2],shade(b,46));px(p[1]+1,p[2]+1,shade(b,-35))
  end
end
for side=1,2 do
  for row=0,11 do
    local x1=side==1 and -48+row*4 or row*4
    local x2=x1+4
    for j=0,14 do
      local y1=math.max(-40,-43+j*6+(row%2)*3)
      local y2=math.min(40,-37+j*6+(row%2)*3)
      if y2>y1 then roofTile(x1,y1,x2,y2,rand(1,1000),side==1,row) end
    end
  end
end
line(roofP(-48,40),roofP(0,40),shade(oak,-17),2)
line(roofP(0,40),roofP(48,40),shade(oak,-17),2)
line(roofP(-48,40),roofP(0,40),rgb(173,133,81))
line(roofP(0,40),roofP(48,40),rgb(180,132,83))
line(roofP(48,-40),roofP(48,40),rgb(67,48,34))
for y=-40,36,5 do
  world({{-1.8,y,95.7},{0,y,98.2},{1.8,y,95.7},{1.8,y+5,95.7},{0,y+5,98.2},{-1.8,y+5,95.7}},rgb(177+rand(-9,9),106+rand(-5,5),60),rgb(110,63,38))
  edge({0,y+.4,98.2},{0,y+4,98.2},rgb(211,151,92))
end
-- The chimney casts a shadow onto the sloped surface.
poly({roofP(18,-24),roofP(29,-24),roofP(43,-5),roofP(44,5),roofP(28,-10)},rgb(40,43,32,62))
finish()

begin('08 · Gabled dormer and carved window')
world({{17,24,85.4},{36,24,73.5},{36,24,95},{17,24,95}},shade(plaster,-25),rgb(62,56,40))
worldface({36,6,74},{36,24,74},{36,6,95},18,21,'plaster',plaster,567,-15)
world({{36,6,95},{36,15,106},{36,24,95}},shade(plaster,-1),rgb(63,56,42))
worldface({36,6,74},{36,8,74},{36,6,95},2,21,'wood',oak,92,-10)
worldface({36,22,74},{36,24,74},{36,22,95},2,21,'wood',oak,93,-10)
worldface({36,9,80},{36,21,80},{36,9,94},12,14,'wood',{67,59,43},94,-10)
worldface({36.4,10,81},{36.4,20,81},{36.4,10,93},10,12,'glass',{124,135,103},95,-5)
edge({36.5,15,81},{36.5,15,93},rgb(144,128,84),2)
edge({36.5,10,87},{36.5,20,87},rgb(125,112,70),2)
box(36,8,38,22,78,80,stone,'stone',133)
edge({17,24,95},{36,24,95},rgb(111,89,56),3)
edge({17,24,85},{36,24,74},rgb(85,74,48),3)
edge({18,24,86},{18,24,94},rgb(95,77,48),3)
edge({35,24,75},{35,24,94},rgb(82,70,45),3)
edge({27,24,80},{27,24,94},rgb(111,91,56),2)
edge({19,24,86},{34,24,94},rgb(115,95,58),2)
local function DP(x,y) return P(x,y,106-math.abs(y-15)*1.05) end
for side=1,2 do
  for row=0,2 do
    local y1=side==1 and 4+row*3.7 or 15+row*3.7;local y2=y1+3.7
    for x=15,37,5 do
      local b={143+rand(-9,13),83+rand(-6,8),47+rand(-3,5)}
      face(DP(x,y1),DP(x+5,y1),DP(x,y2),5,3.7,'roof',b,rand(1,700),side==1 and 17 or -2)
      line(DP(x,y2),DP(x+5,y2),shade(b,23))
    end
  end
end
line(DP(41,4),DP(41,15),rgb(89,65,40),2)
line(DP(41,15),DP(41,26),rgb(89,65,40),2)
line(DP(41,4),DP(41,15),rgb(189,145,89))
line(DP(41,15),DP(41,26),rgb(179,132,76))
line(DP(15,15),DP(41,15),rgb(183,125,69),2)
finish()

begin('09 · Soot-darkened masonry chimney')
box(14,-23,27,-11,81,116,stone,'stone',124)
for row=0,6 do
  local z=81+row*5
  for j=0,2 do
    local u=14+j*5-(row%2)*2.5
    local l,r=math.max(14,u),math.min(27,u+4.65)
    if r>l then
      local v=rand(-15,14);local b={150+v,142+v,115+v*.8}
      worldface({l,-11,z+.2},{r,-11,z+.2},{l,-11,z+4.7},r-l,4.5,'stone',b,rand(1,700),8)
    end
    local yy=-23+j*4.8-(row%2)*2.4
    local yl,yr=math.max(-23,yy),math.min(-11,yy+4.4)
    if yr>yl then
      local v=rand(-12,12);local b={141+v,135+v,110+v*.8}
      worldface({27,yl,z+.2},{27,yr,z+.2},{27,yl,z+4.7},yr-yl,4.5,'stone',b,rand(1,700),-5)
    end
  end
end
for z=83,113,5 do
  edge({14,-11,z+3},{27,-11,z+3},rgb(105,99,77))
  edge({27,-23,z+3},{27,-11,z+3},rgb(91,88,68))
end
box(13,-24,28,-10,114,117,stone,'stone',143)
box(11.5,-25.5,29.5,-8.5,117,120,{165,155,126},'stone',147)
worldface({15,-22,120},{26,-22,120},{15,-12,120},11,10,'stone',{63,62,48},164,-7)
world({{17,-20,120},{24,-20,120},{24,-14,120},{17,-14,120}},rgb(40,40,34))
for i=1,30 do
  local p=P(rand(16,26),-10.5,rand(110,116))
  px(p[1],p[2],rgb(66,63,46,rand(55,100)))
end
finish()

local function leaves(cx,cy,rx,ry,k,count)
  -- Small asymmetrical leaf clusters with visible gaps, lit from the upper left.
  local points={}
  for i=1,count do
    local a=hash(i,2,k)*pi*2;local r=math.sqrt(hash(i,3,k));local x=cx+math.cos(a)*rx*r;local y=cy+math.sin(a)*ry*r
    points[#points+1]={x,y,rand(1,3)}
  end
  table.sort(points,function(a,b) return a[2]<b[2] end)
  for i,p in ipairs(points) do
    local light=clamp(-(p[1]-cx)*.6-(p[2]-cy)*.8,-15,22)+rand(-12,12)
    local c=rgb(76+light,94+light,47+light*.7)
    line({p[1],p[2]+1},{p[1]+p[3],p[2]+1},rgb(45+light*.4,61+light*.4,35))
    line(p,{p[1]+p[3],p[2]-1},c)
    if i%3==0 then px(p[1],p[2]-1,rgb(120+light,136+light,72+light*.7)) end
  end
end
begin('10 · Wrought lantern and overflowing window box')
local l=surface('front',3,48,2)
local metal=rgb(50,49,37)
line({l[1],l[2]-2},{l[1],l[2]+9},metal,2)
line({l[1],l[2]-1},{l[1]+11,l[2]-1},metal)
ellipse(l[1]+7,l[2]+2,3,3,rgb(92,83,51),metal)
local x,y=l[1]+10,l[2]+17
poly({{x-5,y-8},{x,y-12},{x+5,y-8}},rgb(96,82,47),metal)
poly({{x-5,y-7},{x+5,y-7},{x+4,y+7},{x-4,y+7}},rgb(176,139,65),metal)
poly({{x-2,y-5},{x+1,y-5},{x+2,y+4},{x-2,y+4}},rgb(233,197,105))
line({x-5,y-1},{x+5,y-1},metal)
line({x,y-7},{x,y+7},rgb(90,76,40))
line({x-5,y+8},{x+5,y+8},metal,2)
box(-29,33,-10,38,22,27,{112,84,48},'wood',721)
worldface({-28,34,27},{-11,34,27},{-28,37,27},17,3,'stone',{55,56,36},722)
for u=-28,-11,3 do edge({u,38,23},{u,38,26},rgb(69,56,35)) end
for u=-28,-11,4 do
  local p=P(u,36,29+rand(-1,1));leaves(p[1],p[2],8,5,rand(1,500),32)
  if u%3~=0 then
    for i=1,3 do local xx,yy=p[1]+rand(-5,5),p[2]+rand(-6,-2)
      ellipse(xx,yy,2,1,rgb(168+rand(0,20),116,109),rgb(117,79,67));px(xx,yy-1,rgb(218,179,141))
    end
  end
end
finish()

begin('11 · Garden herbs, ivy and grass fringe')
local function herb(x,y,h,k,flower)
  local p=P(x,y,-7)
  ellipse(p[1]+3,p[2]+2,14,5,rgb(44,49,31,110))
  for i=1,8 do
    local q={p[1]+rand(-7,7),p[2]-rand(h,h*2)}
    line({p[1],p[2]},q,rgb(66,66,37))
  end
  leaves(p[1],p[2]-h,12,h,k,105)
  leaves(p[1]-3,p[2]-h*1.5,8,h*.6,k+4,56)
  if flower then
    for i=1,8 do
      local xx,yy=p[1]+rand(-8,8),p[2]-rand(h,h*2)
      px(xx,yy,rgb(176,154,107));px(xx-1,yy-1,rgb(211,197,144))
    end
  end
end
herb(-46,36,14,135,true)
herb(-34,44,13,137,false)
herb(-19,42,12,138,true)
herb(46,-6,10,139,false)
herb(47,38,8,141,false)
for z=10,57,5 do
  local y=27+math.sin(z*.31)*2
  local p=P(41.3,y,z)
  local q=P(41.3,27+math.sin((z+5)*.31)*2,z+5)
  line(p,q,rgb(53,63,35))
  leaves(p[1]+3,p[2],6,4,z+333,16)
end
for i=1,100 do
  local x,y=rand(-54,54),rand(-54,54)
  if math.abs(x)+math.abs(y)>72 and math.abs(x)+math.abs(y)<103 and not (x>3 and x<36 and y>39) then
    local p=P(x,y,-8)
    for j=1,3 do
      local dx,dy=rand(-3,3),rand(-6,-2)
      line(p,{p[1]+dx,p[2]+dy},rgb(95+rand(-15,12),110+rand(-10,18),58+rand(-12,12)))
    end
  end
end
finish()

begin('12 · Oak garden fence / barrel / terracotta pots')
-- Low fence along the planted edge, with each post sunk into the paving.
box(-49,49,-7,50,-2,0,{106,86,54},'wood',810)
box(-49,49,-7,50,5,7,{106,86,54},'wood',812)
for x=-49,-7,7 do
  box(x,48.5,x+1.7,50.5,-8,10,{122,102,69},'wood',round(x+900))
  world({{x,50.5,10},{x+.85,50.5,12},{x+1.7,50.5,10}},rgb(135,116,79),rgb(67,59,40))
  local n=P(x+.8,50.6,6);px(n[1],n[2],rgb(56,54,38));px(n[1]+1,n[2]-1,rgb(177,157,103))
end
local b=P(48,-29,-7);local bx,by=b[1],b[2]
ellipse(bx+3,by+1,14,5,rgb(45,47,33,100))
for xx=-11,11 do
  local edgeY=math.sqrt(math.max(0,1-(xx/11)^2))*4
  for yy=-25-edgeY,edgeY do
    local n=(noise(xx*2,yy/8,2)-.5)*22-xx*1.8
    if (xx+12)%4==0 then n=n-25 end
    px(bx+xx,by+yy,rgb(110+n,83+n*.85,46+n*.55))
  end
end
ellipse(bx,by-25,11,4,rgb(97,78,45),rgb(52,49,34))
ellipse(bx,by-25,8,2,rgb(132,105,60),rgb(72,61,39))
for _,yy in ipairs({by-18,by-5}) do
  for xx=-11,11 do
    local curve=math.sqrt(math.max(0,1-(xx/11)^2))*3
    px(bx+xx,yy+curve,rgb(51,54,43));px(bx+xx,yy+curve+1,rgb(109,112,88))
  end
end
local pot=P(-3,43,-7)
ellipse(pot[1]+2,pot[2]+1,10,4,rgb(47,49,31,105))
poly({{pot[1]-8,pot[2]-16},{pot[1]+8,pot[2]-16},{pot[1]+5,pot[2]},{pot[1]-5,pot[2]}},rgb(139,79,46),rgb(73,55,34))
line({pot[1]-6,pot[2]-13},{pot[1]-4,pot[2]-3},rgb(177,113,65),2)
ellipse(pot[1],pot[2]-16,9,3,rgb(92,66,38),rgb(161,98,56))
ellipse(pot[1],pot[2]-17,7,2,rgb(58,57,33))
for i=1,7 do
  local q={pot[1]+rand(-8,8),pot[2]-rand(22,38)}
  line({pot[1],pot[2]-16},q,rgb(67,78,40))
  line({q[1],q[2]+8},{q[1]+4,q[2]+4},rgb(114,130,60))
  for j=0,4 do px(q[1]+rand(-1,1),q[2]+j,rgb(143+rand(-14,12),133+rand(-6,8),153+rand(-5,8))) end
end
finish()

local palette=Palette(1);palette:setColor(0,Color{r=0,g=0,b=0,a=0})
local families={stone,oak,plaster,terracotta,teal,{102,119,60},{181,158,97},{76,83,65}}
palette:resize(1+#families*10)
local index=1
for _,c in ipairs(families) do for n=-40,32,8 do palette:setColor(index,Color(shade(c,n)));index=index+1 end end
spr:setPalette(palette)
spr.filename=app.fs.joinPath(out,'hearth-cottage-crafted.aseprite')
spr:saveAs(spr.filename)
spr:saveCopyAs(app.fs.joinPath(out,'hearth-cottage-crafted.png'))
spr.layers[1].isVisible=true
spr:saveCopyAs(app.fs.joinPath(out,'hearth-cottage-crafted-preview.png'))
spr.layers[1].isVisible=false
spr:saveAs(spr.filename)
print('Saved crafted cottage: '..spr.filename..' / '..#spr.layers..' layers / '..W..'x'..H)
app.refresh()
