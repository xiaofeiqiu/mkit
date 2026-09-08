-- Hearth Cottage. Original pixel art drawn with Aseprite's Lua API.
-- Run: aseprite -b --script-param output=/absolute/output --script draw_house.lua
-- Projection: two pixels horizontally per one pixel vertically on both ground axes.
local W, H = 256, 240
local out = app.params.output or app.fs.filePath(app.scriptPath)
app.fs.makeAllDirectories(out)
local sprite = Sprite(W, H, ColorMode.RGB)
local image, layer
local colors = {
  ink='383949', deep='484254', earth='765647', earthLight='a47450',
  earthDark='614b4a', soilTop='be9360', stoneDark='65636e', stone='9a9388',
  stoneLight='c7baa0', stoneTop='e0d2b4', grassDark='3e6e58', grassShade='54815b',
  grass='78a667', grassLight='9bbd75', grassHigh='bed38c', moss='66855b',
  plaster='efd9b0', plasterLight='fae8c6', plasterMark='ddbf95',
  plasterShade='bbaa9d', plasterCool='a39392', plasterRim='d7c5ac',
  woodDark='655052', wood='926850', woodLight='bb8a5d', woodHigh='ddaf78',
  roofDark='784650', roofShade='a75752', roof='c76d58', roofLight='dd8966',
  roofHigh='efa67a', roofHot='f3bc88', roofPatch='b46056',
  tealDark='315b60', teal='467e79', tealLight='66a095', tealHigh='8cbcaf',
  glassDark='47666f', glass='739a9c', glassLight='a8d3c7',
  gold='dfad64', goldLight='ffe4a0', flower='da8586', flowerLight='ffb9a0',
  leafDark='345e50', leaf='4e8258', leafLight='7ca761', leafHigh='a8c477',
  smoke='c4c3bb', smokeLight='dedace', backdrop='eee7d9'
}
local C = {}
for name,hex in pairs(colors) do
  C[name] = app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255)
end
local function round(n) return math.floor(n + .5) end
local function px(x,y,c)
  x,y=round(x),round(y)
  if x>=0 and y>=0 and x<W and y<H then image:drawPixel(x,y,C[c] or c) end
end
local function line(a,b,c,width)
  local x,y,x2,y2=round(a[1]),round(a[2]),round(b[1]),round(b[2])
  local dx,dy=math.abs(x2-x),-math.abs(y2-y)
  local sx,sy=x<x2 and 1 or -1,y<y2 and 1 or -1
  local err=dx+dy
  while true do
    for xx=0,(width or 1)-1 do for yy=0,(width or 1)-1 do px(x+xx,y+yy,c) end end
    if x==x2 and y==y2 then break end
    local e2=2*err
    if e2>=dy then err=err+dy; x=x+sx end
    if e2<=dx then err=err+dx; y=y+sy end
  end
end
local function poly(points,c,border)
  local lo,hi=H,-1
  for _,p in ipairs(points) do lo=math.min(lo,p[2]); hi=math.max(hi,p[2]) end
  for y=math.max(0,math.ceil(lo)),math.min(H-1,math.floor(hi)) do
    local hits={}
    for i,a in ipairs(points) do
      local b=points[i%#points+1]
      if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then
        hits[#hits+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])
      end
    end
    table.sort(hits)
    for i=1,#hits-1,2 do for x=math.ceil(hits[i]),math.floor(hits[i+1]) do px(x,y,c) end end
  end
  if border then for i,a in ipairs(points) do line(a,points[i%#points+1],border) end end
end
local function ellipse(x,y,rx,ry,c,border)
  local pts={}
  for i=0,31 do local a=i*math.pi/16; pts[#pts+1]={round(x+math.cos(a)*rx),round(y+math.sin(a)*ry)} end
  poly(pts,c,border)
end
local function newLayer(name)
  layer=sprite:newLayer(); layer.name=name
  image=Image(W,H,ColorMode.RGB); image:clear()
end
local function finish() sprite:newCel(layer,1,image,Point(0,0)) end
local function P(x,y,z) return {128+x-y,145+(x+y)/2-(z or 0)} end
local function world(points,c,border)
  local pp={}; for _,p in ipairs(points) do pp[#pp+1]=P(table.unpack(p)) end
  poly(pp,c,border)
end
local function edge(a,b,c,w) line(P(table.unpack(a)),P(table.unpack(b)),c,w) end
local function box(x1,y1,x2,y2,z1,z2,top,left,right,border)
  border=border or 'ink'
  world({{x1,y2,z1},{x2,y2,z1},{x2,y2,z2},{x1,y2,z2}},left,border)
  world({{x2,y1,z1},{x2,y2,z1},{x2,y2,z2},{x2,y1,z2}},right,border)
  world({{x1,y1,z2},{x2,y1,z2},{x2,y2,z2},{x1,y2,z2}},top,border)
end
local seed=405
local function rand(a,b)
  seed=(seed*48271)%2147483647
  return a+seed%(b-a+1)
end

-- Optional solid background stays editable and hidden in the source sprite.
sprite.layers[1].name='00 · Backdrop (optional)'
image=Image(W,H,ColorMode.RGB)
image:clear(Color{r=238,g=231,b=217,a=255})
sprite.cels[1].image=image
sprite.layers[1].isVisible=false

newLayer('01 · Grass island / earth')
box(-56,-56,56,56,-20,-8,'grass','earthLight','earthDark')
edge({-56,56,-11},{56,56,-11},'soilTop')
edge({56,-56,-11},{56,56,-11},'earth')
for i=-50,50,10 do
  local z=-15+(i%3)
  edge({i,56,z},{i+4,56,z},i%20==10 and 'soilTop' or 'earth')
  edge({56,i,z},{56,i+4,z},'earthLight')
end
world({{-56,-56,-8},{-16,-56,-8},{-42,8,-8},{-56,32,-8}},'grassLight')
world({{56,-48,-8},{56,56,-8},{20,56,-8},{34,35,-8},{28,17,-8}},'grassShade')
edge({-56,-56,-8},{-56,56,-8},'grassHigh')
edge({-56,56,-8},{56,56,-8},'grassLight')
for i=1,65 do
  local x,y=rand(-52,52),rand(-52,52)
  local p=P(x,y,-8)
  if not (x>2 and x<37 and y>31) then
    line(p,{p[1]+2,p[2]+1},i%3==0 and 'grassLight' or 'grassShade')
    if i%3==0 then px(p[1]+1,p[2]-1,'grassLight') end
  end
end
finish()

newLayer('02 · Cast shadow / garden path')
world({{-33,-29,-7},{42,-24,-7},{54,-6,-7},{54,41,-7},{32,55,-7},{-27,39,-7}},'grassDark')
world({{5,44,-7},{32,44,-7},{32,56,-7},{5,56,-7}},'grassShade')
for _,s in ipairs({{9,47,19,53},{21,47,31,52},{12,54,24,56}}) do
  world({{s[1],s[2],-7},{s[3],s[2],-7},{s[3],s[4],-7},{s[1],s[4],-7}},'stoneLight','stone')
  edge({s[1],s[4],-7},{s[3],s[4],-7},'stoneTop')
end
finish()

newLayer('03 · Stone foundation')
box(-41,-33,41,33,-8,3,'stoneLight','stone','stoneDark')
edge({-41,33,0},{41,33,0},'stoneLight')
edge({41,-33,0},{41,33,0},'stone')
for u=-39,37,12 do edge({u,33,-7},{u,33,-1},'stoneDark') end
for v=-30,29,12 do edge({41,v,-7},{41,v,-1},'ink') end
finish()

newLayer('04 · Plaster walls / gable')
world({{-40,32,3},{40,32,3},{40,32,65},{-40,32,65}},'plaster','ink')
world({{40,-32,3},{40,32,3},{40,32,65},{40,-32,65}},'plasterShade','ink')
world({{-40,32,65},{0,32,94},{40,32,65}},'plasterLight','ink')
world({{-40,32,59},{40,32,59},{40,32,65},{-40,32,65}},'woodDark')
world({{40,-32,57},{40,32,57},{40,32,65},{40,-32,65}},'plasterCool')
for _,r in ipairs({{-33,10,7},{-22,13,5},{-37,24,4},{-3,11,6},{31,12,6},{33,47,3}}) do
  edge({r[1],32,r[2]},{r[1]+r[3],32,r[2]},'plasterMark')
end
for _,r in ipairs({{-24,12,7},{-15,16,3},{8,10,6},{22,14,4},{-25,54,4}}) do
  edge({40,r[1],r[2]},{40,r[1]+r[3],r[2]},'plasterCool')
end
finish()

newLayer('05 · Oak framing')
for _,x in ipairs({-39,-3,38}) do
  world({{x,32,3},{x+3,32,3},{x+3,32,64},{x,32,64}},'wood','woodDark')
  edge({x,32,5},{x,32,60},'woodHigh')
end
for _,y in ipairs({-31,0,30}) do
  world({{40,y,3},{40,y+3,3},{40,y+3,63},{40,y,63}},'woodDark')
  edge({40,y+2,4},{40,y+2,61},'wood')
end
for _,z in ipairs({5,19,63}) do
  edge({-40,32,z},{40,32,z},'woodDark',3)
  edge({-39,32,z+1},{39,32,z+1},'woodLight')
  edge({40,-32,z},{40,32,z},'woodDark',3)
  edge({40,-30,z+1},{40,30,z+1},'wood')
end
edge({0,32,67},{0,32,91},'wood',3)
edge({-35,32,65},{-4,32,89},'wood',2)
edge({35,32,65},{4,32,89},'wood',2)
edge({-32,32,66},{-20,32,66},'woodHigh')
finish()

local function surface(side,u,z)
  if side=='front' then return P(u,32,z) end
  return P(40,u,z)
end
local function wallPoly(side,pts,c,border)
  local pp={}; for _,p in ipairs(pts) do pp[#pp+1]=surface(side,p[1],p[2]) end
  poly(pp,c,border)
end
local function wallRect(side,u,z,w,h,c,border)
  wallPoly(side,{{u,z},{u+w,z},{u+w,z+h},{u,z+h}},c,border)
end
local function wallLine(side,u,z,v,zz,c,width)
  line(surface(side,u,z),surface(side,v,zz),c,width)
end
local function window(side,u,z,w,h,shutters)
  wallRect(side,u-2,z-2,w+4,h+4,'woodDark','ink')
  wallRect(side,u,z,w,h,'glassDark','woodHigh')
  wallRect(side,u+2,z+2,w-4,h-4,'glass')
  wallPoly(side,{{u+2,z+h-3},{u+w-3,z+h-3},{u+2,z+6}},'glassLight')
  wallRect(side,u+w/2-1,z,2,h,'woodHigh')
  wallRect(side,u,z+h/2-1,w,2,'woodLight')
  wallLine(side,u-2,z+h+2,u+w+2,z+h+2,'plasterLight')
  wallRect(side,u-3,z-4,w+6,3,'woodLight','woodDark')
  wallLine(side,u-3,z-2,u+w+3,z-2,'woodHigh')
  if shutters then
    for _,s in ipairs({u-9,u+w+3}) do
      wallRect(side,s,z-1,6,h+2,'teal','tealDark')
      wallLine(side,s+1,z,s+1,z+h,'tealLight')
      for zz=z+3,z+h-1,4 do wallLine(side,s+1,zz,s+5,zz,'tealDark') end
    end
  end
end
newLayer('06 · Windows / teal shutters')
window('front',-28,29,17,23,true)
window('right',-23,29,15,23,false)
window('right',9,29,14,23,false)
-- Small attic oculus, mapped onto the gable plane.
local ring={}; for i=0,31 do local a=i*math.pi/16; ring[#ring+1]=surface('front',math.cos(a)*7,79+math.sin(a)*7) end
poly(ring,'woodDark','ink')
ring={}; for i=0,31 do local a=i*math.pi/16; ring[#ring+1]=surface('front',math.cos(a)*5,79+math.sin(a)*5) end
poly(ring,'goldLight','woodHigh')
wallLine('front',0,74,0,84,'wood')
wallLine('front',-5,79,5,79,'wood')
finish()

newLayer('07 · Arched door / entry steps')
-- The door has a true arched silhouette, an inset glazed transom, and oak jambs.
local arch={{8,4},{31,4},{31,36},{29,43},{25,48},{19,50},{13,47},{9,42},{8,36}}
wallPoly('front',arch,'woodDark','ink')
wallPoly('front',{{11,4},{28,4},{28,36},{26,42},{23,45},{19,46},{15,43},{12,39},{11,35}},'teal','tealDark')
wallLine('front',12,7,12,36,'tealLight')
for u=16,25,4 do wallLine('front',u,7,u,30,'tealDark') end
wallPoly('front',{{13,32},{26,32},{26,36},{24,41},{20,43},{16,41},{13,36}},'goldLight','woodHigh')
wallLine('front',19,32,19,42,'wood')
wallLine('front',13,36,26,36,'wood')
wallLine('front',12,30,27,30,'woodHigh')
wallRect('front',24,17,2,4,'woodDark')
local knob=surface('front',25,20); ellipse(knob[1],knob[2],1,1,'goldLight')
box(7,33,33,37,-8,3,'stoneTop','stone','stoneDark')
box(7,38,33,41,-8,0,'stoneLight','stone','stoneDark')
box(7,42,33,45,-8,-3,'stoneLight','stone','stoneDark')
edge({8,37,3},{32,37,3},'plasterLight')
edge({8,41,0},{32,41,0},'stoneTop')
edge({8,45,-3},{32,45,-3},'stoneTop')
finish()

newLayer('08 · Roof / individual terracotta tiles')
local function roofPoint(x,y) return P(x,y,96-math.abs(x)*30/48) end
local function roofPoly(x1,y1,x2,y2,c,border)
  poly({roofPoint(x1,y1),roofPoint(x2,y1),roofPoint(x2,y2),roofPoint(x1,y2)},c,border)
end
-- Thick timber bargeboards and eaves underneath the tiled surfaces.
world({{-48,40,63},{0,40,93},{48,40,63},{48,40,66},{0,40,96},{-48,40,66}},'woodDark','ink')
world({{48,-40,62},{48,40,62},{48,40,66},{48,-40,66}},'woodDark','ink')
roofPoly(-48,-40,0,40,'roofLight','ink')
for row=0,5 do
  local x1,x2=-48+row*8,-40+row*8
  for j=0,7 do
    local y1=math.max(-40,-46+j*12+(row%2)*6)
    local y2=math.min(40,-34+j*12+(row%2)*6)
    if y2>y1 then
      roofPoly(x1,y1,x2,y2,(row+j)%4==0 and 'roofHigh' or 'roofLight','roof')
      line(roofPoint(x1+1,y1+1),roofPoint(x1+1,y2-1),'roofHigh')
    end
  end
end
roofPoly(0,-40,48,40,'roof','roofDark')
local tileColors={'roof','roof','roofLight','roofPatch','roof'}
for row=0,5 do
  local x1,x2=row*8,(row+1)*8
  for j=0,7 do
    local y1=math.max(-40,-46+j*12+(row%2)*6)
    local y2=math.min(40,-34+j*12+(row%2)*6)
    if y2>y1 then
      local c=tileColors[1+rand(0,#tileColors-1)]
      roofPoly(x1,y1,x2,y2,c,'roofShade')
      line(roofPoint(x2-1,y1+1),roofPoint(x2-1,y2-1),'roofLight')
      if (row+j)%4==0 then line(roofPoint(x1+2,y1+2),roofPoint(x1+2,y1+5),'roofHigh') end
    end
  end
end
-- Outline the silhouette after tiles; preserve continuous 2:1 eave lines.
line(roofPoint(0,-40),roofPoint(48,-40),'roofDark')
line(roofPoint(48,-40),roofPoint(48,40),'ink')
line(roofPoint(-48,-40),roofPoint(-48,40),'roofDark')
line(roofPoint(-48,40),roofPoint(0,40),'roofDark',2)
line(roofPoint(0,40),roofPoint(48,40),'roofDark',2)
line(roofPoint(-48,40),roofPoint(0,40),'roofHigh')
line(roofPoint(0,40),roofPoint(48,40),'roofHigh')
for y=-40,36,8 do
  world({{-2,y,95},{0,y,99},{2,y,95},{2,y+8,95},{0,y+8,99},{-2,y+8,95}},'roofLight','roofShade')
  edge({0,y,99},{0,y+7,99},'roofHot')
end
edge({48,-39,64},{48,39,64},'woodLight')
finish()

newLayer('09 · Brick chimney')
box(14,-23,27,-11,78,109,'stoneTop','roofLight','roofShade')
for z=82,106,6 do
  edge({14,-11,z},{27,-11,z},'roofDark')
  edge({27,-23,z},{27,-11,z},'roofDark')
  local split=z%12==10 and 18 or 23
  edge({split,-11,z},{split,-11,z+5},'roofShade')
  edge({27,-17,z},{27,-17,z+5},'roofDark')
end
box(12,-25,29,-9,108,112,'stoneTop','stoneLight','stone')
world({{16,-21,112},{25,-21,112},{25,-13,112},{16,-13,112}},'deep','stoneDark')
edge({12,-9,112},{29,-9,112},'plasterLight')
finish()

newLayer('10 · Lantern / flower boxes')
local lp=surface('front',4,46)
line({lp[1],lp[2]-3},{lp[1],lp[2]+3},'ink')
line({lp[1]-1,lp[2]-3},{lp[1]+4,lp[2]-3},'ink')
local lx,ly=lp[1]+4,lp[2]+4
poly({{lx-3,ly-4},{lx,ly-7},{lx+3,ly-4}},'woodDark','ink')
poly({{lx-3,ly-3},{lx+3,ly-3},{lx+2,ly+4},{lx-2,ly+4}},'gold','ink')
line({lx-1,ly-2},{lx-1,ly+2},'goldLight',2)
line({lx-3,ly+5},{lx+3,ly+5},'woodDark')
-- Window box sits proud of the front wall.
box(-29,33,-9,38,20,26,'earthDark','wood','woodDark')
edge({-29,38,26},{-9,38,26},'woodHigh')
for x=-27,-11,4 do edge({x,38,21},{x,38,24},'woodDark') end
for i=0,7 do
  local p=P(-28+i*2.5,36,28+rand(-1,2))
  ellipse(p[1],p[2],3,2,'leaf','leafDark')
  px(p[1]-1,p[2]-1,'leafLight')
  if i%2==0 then
    px(p[1],p[2]-3,'flowerLight'); px(p[1]-1,p[2]-2,'flower'); px(p[1]+1,p[2]-2,'flower'); px(p[1],p[2]-1,'goldLight')
  end
end
finish()

newLayer('11 · Garden plants / finishing pixels')
local function bush(x,y,scale)
  local p=P(x,y,-6)
  ellipse(p[1]+2,p[2]+1,10*scale,4*scale,'grassDark')
  ellipse(p[1]+4*scale,p[2]-4*scale,7*scale,6*scale,'leaf','leafDark')
  ellipse(p[1]-4*scale,p[2]-5*scale,8*scale,7*scale,'leafLight','leafDark')
  ellipse(p[1],p[2]-10*scale,6*scale,6*scale,'leafLight','leaf')
  line({p[1]-6*scale,p[2]-7*scale},{p[1]-3*scale,p[2]-9*scale},'leafHigh',2)
  line({p[1],p[2]-13*scale},{p[1]+2*scale,p[2]-13*scale},'leafHigh')
  px(p[1]+6*scale,p[2]-4*scale,'leafLight')
end
bush(-45,37,1)
bush(48,-17,.85)
bush(43,43,.7)
-- Terracotta pot with a small flowering plant next to the doorway.
local pot=P(-4,44,-5)
ellipse(pot[1],pot[2]+1,6,2,'grassDark')
poly({{pot[1]-5,pot[2]-9},{pot[1]+5,pot[2]-9},{pot[1]+3,pot[2]},{pot[1]-3,pot[2]}},'roof','roofDark')
line({pot[1]-4,pot[2]-8},{pot[1]-3,pot[2]-2},'roofHigh')
ellipse(pot[1],pot[2]-9,5,2,'earthDark','roofLight')
for i=1,5 do
  local x=pot[1]+rand(-4,4); local y=pot[2]-rand(13,20)
  line({pot[1],pot[2]-10},{x,y},'leafDark')
  line({x,y+4},{x-3,y+2},'leafLight')
  ellipse(x,y,2,2,i%2==0 and 'goldLight' or 'flower','flowerLight')
end
for _,s in ipairs({{-44,49},{-30,48},{44,51},{52,15},{-48,14},{-13,51}}) do
  local p=P(s[1],s[2],-8)
  line({p[1]-2,p[2]},{p[1]-3,p[2]-3},'grassDark')
  line(p,{p[1],p[2]-4},'grassLight')
  line({p[1]+1,p[2]},{p[1]+3,p[2]-2},'grassHigh')
end
finish()

-- Keep the final result crisp: fully opaque painted pixels and real transparency.
local palette=Palette(1)
palette:setColor(0,Color{r=0,g=0,b=0,a=0})
local names={}; for n in pairs(colors) do names[#names+1]=n end; table.sort(names)
palette:resize(#names+1)
for i,n in ipairs(names) do palette:setColor(i,Color(C[n])) end
sprite:setPalette(palette)
sprite.filename=app.fs.joinPath(out,'hearth-cottage.aseprite')
sprite:saveAs(sprite.filename)
sprite:saveCopyAs(app.fs.joinPath(out,'hearth-cottage.png'))
-- A house-only export is useful when the terrain is supplied by a game map.
for i=2,3 do sprite.layers[i].isVisible=false end
sprite:saveCopyAs(app.fs.joinPath(out,'hearth-cottage-no-ground.png'))
for i=2,3 do sprite.layers[i].isVisible=true end
sprite.layers[1].isVisible=true
sprite:saveCopyAs(app.fs.joinPath(out,'hearth-cottage-preview.png'))
sprite.layers[1].isVisible=false
sprite:saveAs(sprite.filename)
print('Saved Hearth Cottage: '..sprite.filename..' ('..#sprite.layers..' editable layers)')
app.refresh()
