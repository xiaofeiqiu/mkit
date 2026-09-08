-- Run in Aseprite. The editable timeline is the authoritative composite.
-- Geometry is projected by the shared city camera; water/frost/shards are
-- separate, individually authored cels. No frame resizing or recentering.
local root=assert(app.params["root"], "Pass --script-param root=/absolute/project")
local dir=root.."/game/whispering_forest/art/combat/ice-16/"
local file=assert(io.open(dir.."base/projection.json", "r"))
local meta=json.decode(file:read("*a")); file:close()
local W,H=384,384
local cx,cy=meta.pivot[1],meta.pivot[2]
local pc=app.pixelColor
local function rgba(r,g,b,a) return pc.rgba(r,g,b,math.floor(math.max(0,math.min(255,a or 255)))) end
local function pixel(img,x,y,c)
  x,y=math.floor(x+0.5),math.floor(y+0.5)
  if x>=0 and x<W and y>=0 and y<H then img:drawPixel(x,y,c) end
end
local function disk(img,x,y,r,c)
  for yy=math.floor(y-r),math.ceil(y+r) do
    for xx=math.floor(x-r),math.ceil(x+r) do
      if (xx-x)^2+(yy-y)^2<=r*r then pixel(img,xx,yy,c) end
    end
  end
end
local function line(img,x0,y0,x1,y1,r,c)
  local steps=math.ceil(math.max(math.abs(x1-x0),math.abs(y1-y0))*1.5)
  for s=0,steps do
    local t=s/math.max(1,steps)
    disk(img,x0+(x1-x0)*t,y0+(y1-y0)*t,r,c)
  end
end
local function polygon(img,points,c)
  local y0,y1=H,0
  for _,p in ipairs(points) do y0=math.min(y0,p[2]); y1=math.max(y1,p[2]) end
  for y=math.floor(y0),math.ceil(y1) do
    local nodes={}
    for i,p in ipairs(points) do
      local q=points[i%#points+1]
      if (p[2]<=y and q[2]>y) or (q[2]<=y and p[2]>y) then
        nodes[#nodes+1]=p[1]+(y-p[2])/(q[2]-p[2])*(q[1]-p[1])
      end
    end
    table.sort(nodes)
    for i=1,#nodes-1,2 do
      for x=math.ceil(nodes[i]),math.floor(nodes[i+1]) do pixel(img,x,y,c) end
    end
  end
end
local function arc(img,r,start,finish,phase,alpha,width)
  local last=nil
  for j=0,110 do
    local a=start+(finish-start)*j/110
    local rr=r*(1+0.025*math.sin(a*5+phase))
    local p={cx+math.cos(a)*rr,cy+math.sin(a)*rr*0.5}
    if last then line(img,last[1],last[2],p[1],p[2],width,rgba(232,242,247,alpha)) end
    last=p
  end
end
local function shard(img,x,y,size,angle,alpha)
  local dx,dy=math.cos(angle)*size,math.sin(angle)*size
  local px,py=-math.sin(angle)*size*0.30,math.cos(angle)*size*0.30
  polygon(img,{{x-dx,y-dy},{x+px,y+py},{x+dx,y+dy}},rgba(194,208,218,alpha))
  polygon(img,{{x-dx,y-dy},{x-px,y-py},{x+dx,y+dy}},rgba(253,255,255,alpha))
end
local sprite=Sprite(W,H,ColorMode.RGB)
sprite:assignColorSpace(ColorSpace{sRGB=true})
local water=sprite.layers[1]; water.name="01 Water gathering / ground"
local ice=sprite:newLayer(); ice.name="02 Ice spear / fixed volume"
local glints=sprite:newLayer(); glints.name="03 Frost veins / facet glints"
local debris=sprite:newLayer(); debris.name="04 Splash crown / ice shards"
for i=2,16 do sprite:newEmptyFrame(i) end
for f=0,15 do
  local ms=math.floor(((meta.times[f+2] or meta.duration_seconds)-meta.times[f+1])*1000+0.5)
  sprite.frames[f+1].duration=(ms+0.01)/1000 -- Aseprite truncates to integer ms.
  local waterImg=Image(W,H,ColorMode.RGB)
  local frostImg=Image(W,H,ColorMode.RGB)
  local debrisImg=Image(W,H,ColorMode.RGB)
  local gather=math.min(1,f/6)
  local tail=math.max(0,(f-10)/5)
  -- An actual shallow pool: horizontal-plane 2:1 footprint, transparent
  -- desaturated shallow depth and a white frost rim, no blue watery body.
  local radius=(f<7 and (62-24*gather) or 42+math.min(f-7,3)*3)
  local fade=f<11 and 1 or 1-tail*0.88
  for y=math.floor(cy-radius*0.6-3),math.ceil(cy+radius*0.6+3) do
    for x=math.floor(cx-radius-3),math.ceil(cx+radius+3) do
      local dx,dy=x-cx,(y-cy)*2
      local a=math.atan(dy,dx)
      local r=math.sqrt(dx*dx+dy*dy)/radius
      local edge=1+0.04*math.sin(a*5+f*0.22)+0.025*math.cos(a*9-f*0.19)
      if r<edge then
        local rim=math.max(0,1-math.abs(r-0.90)*18)
        local caustic=math.max(0,math.sin(r*22-a*3+f*0.95))^9
        local alpha=(38+rim*75+caustic*27)*fade*(f==0 and 0.5 or 1)
        pixel(waterImg,x,y,rgba(168+rim*45+caustic*30,184+rim*48+caustic*22,195+rim*45+caustic*15,alpha))
      end
    end
  end
  if f<=6 then
    local r=76-f*9
    arc(waterImg,r,0.12,2.85,f,160,0.9)
    arc(waterImg,r,3.3,5.9,f,105,0.75)
    if f<5 then arc(waterImg,r+14,3.4,5.7,f,65,0.55) end
    -- Small streams flow inward before a central tension mound forms.
    for j=0,6 do
      local a=j*math.pi*2/7+0.2
      local reach=65-f*8
      local x,y=cx+math.cos(a)*reach,cy+math.sin(a)*reach*0.5
      line(waterImg,x,y,x-math.cos(a)*7,y-math.sin(a)*3.5,0.9,rgba(234,243,249,160))
    end
    if f>=3 then
      local h=3+(f-3)*4
      local w=15-(f-3)*1.3
      polygon(waterImg,{{cx-w,cy+2},{cx-w*0.65,cy-h*0.55},{cx-1,cy-h},{cx+w*0.6,cy-h*0.5},{cx+w,cy+2}},rgba(218,230,237,225))
      line(waterImg,cx-w*0.65,cy-h*0.55,cx-1,cy-h,1.0,rgba(253,255,255,245))
    end
  end
  local base=Image{fromFile=dir..string.format("base/ice-%02d.png",f)}
  if f>=7 and f<14 then
    local splash=f-7
    for j=0,8 do
      local a=j*math.pi*2/9+0.23
      local reach=23+splash*5.7
      local lift=(f<11 and (9+12*math.sin((f-7)/4*math.pi)) or 8)
      local x=cx+math.cos(a)*reach
      local y=cy+math.sin(a)*reach*0.5-lift-(j%3)*3
      shard(debrisImg,x,y,2.6+(j%3),-math.pi/2+math.cos(a)*0.65,255)
    end
    arc(waterImg,42+math.min(splash,7)*4,0.15,3.0,f,math.max(0,145-splash*18),0.7)
  end
  if f>=9 then
    local fadeIce=1 -- highlights overlay an opaque body; no body-alpha fade
    -- The highlights are clipped against the ice silhouette, preserving
    -- its camera-rendered volume and ground pivot.
    for y=58,math.floor(cy) do
      local spine=cx+5-(cy-y)*0.020
      local band=math.abs(y-(90+(f-9)*33))
      for x=math.floor(spine-1),math.ceil(spine+1) do
        if pc.rgbaA(base:getPixel(x,y))>100 then
          local alpha=(25+math.max(0,1-band/28)*120)*fadeIce
          pixel(frostImg,x,y,rgba(255,255,255,alpha))
        end
      end
    end
    if f>=10 then
      for j=0,4 do
        local y=131+j*30+(f%2)*3
        for k=0,18 do
          local x=cx-13+k
          local yy=y-k*0.6+math.sin(k*0.8)*2
          if pc.rgbaA(base:getPixel(math.floor(x),math.floor(yy)))>110 then
            pixel(frostImg,x,yy,rgba(244,250,254,140*fadeIce))
          end
        end
      end
    end
  end
  if f>=11 then
    local t=f-10
    for j=0,5 do
      local sign=j%2==0 and -1 or 1
      local x=cx+sign*(12+t*(3+j%3))
      local y=cy-40-j*28-t*3+t*t*0.85
      shard(debrisImg,x,y,2.8+j%3,-1.2+sign*t*0.24,255)
    end
  end
  if f>=11 then
    -- Split the intact, opaque cel into irregular pieces. Preserve every
    -- fragment's original size/alpha and move it; remove fallen pieces whole.
    -- Soft outer coverage is antialiasing, never a translucent ice interior.
    base:drawImage(frostImg,Point(0,0))
    frostImg:clear()
    local source=base
    base=Image(W,H,ColorMode.RGB)
    local t=f-10
    local seeds={}
    for row=0,5 do
      for side=0,1 do
        seeds[#seeds+1]={cx+(side==0 and -1 or 1)*(5+row*2),
          82+row*38+(side==0 and 0 or 12),row,side}
      end
    end
    for it in source:pixels() do
      local color=it()
      if pc.rgbaA(color)>0 then
        local nearest,best=1,math.huge
        for j,p in ipairs(seeds) do
          local d=(it.x-p[1])^2*2.3+(it.y-p[2])^2
          if d<best then nearest,best=j,d end
        end
        local p=seeds[nearest]
        -- Lower pieces fall out first. The final pose contains two small
        -- upper shards, still fully opaque, rather than a ghost silhouette.
        local retained=(t<=2 or (t==3 and p[3]<4) or (t==4 and p[3]<2) or (t==5 and p[3]==0))
        if retained then
          local sign=p[4]==0 and -1 or 1
          local dx=sign*math.floor(t*(3+p[3]*0.6))
          local dy=math.floor(t*t*1.9-t*5-p[3]*t*0.4)
          pixel(base,it.x+dx,it.y+dy,color)
        end
      end
    end
  end
  sprite:newCel(water,f+1,waterImg,Point(0,0))
  sprite:newCel(ice,f+1,base,Point(0,0))
  sprite:newCel(glints,f+1,frostImg,Point(0,0))
  sprite:newCel(debris,f+1,debrisImg,Point(0,0))
end
for _,t in ipairs({{1,6,"Gather"},{7,9,"Erupt"},{10,11,string.format("Peak / HIT %.2fs",meta.times[meta.peak_frame+1])},{12,16,"Opaque fracture / removal"}}) do
  local tag=sprite:newTag(t[1],t[2]); tag.name=t[3]
end
sprite.data=json.encode{groundPivot=meta.pivot,peakFrame=10,hitSeconds=meta.times[meta.peak_frame+1],authoring="Aseprite layered 16-frame timeline",motion="Fixed spear translated through the floor. Opaque ice breaks into solid moving pieces; no alpha fade, inflation or contraction."}
sprite:saveAs(dir.."ice-spear-16.aseprite")
assert(#sprite.frames==16 and #sprite.layers==4)
print("WF_ASEPRITE_ICE_OK: 16 frames, 4 editable layers, timed stage tags, fixed pivot")
