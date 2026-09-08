local base=app.params.output
local spr=app.open(app.fs.joinPath(base,'hearth-cottage-crafted.aseprite'))
assert(spr.width==512 and spr.height==480)
assert(#spr.layers==13 and #spr.frames==1)
assert(not spr.layers[1].isVisible)
local flat=Image(spr.spec);flat:drawSprite(spr,1)
local png=Image{fromFile=app.fs.joinPath(base,'hearth-cottage-crafted.png')}
local minx,miny,maxx,maxy=512,480,-1,-1
local clear,painted,partial=0,0,0
for y=0,479 do for x=0,511 do
  local p=flat:getPixel(x,y);assert(p==png:getPixel(x,y),'PNG composite mismatch')
  local a=app.pixelColor.rgbaA(p)
  if a>0 then
    minx=math.min(minx,x);miny=math.min(miny,y);maxx=math.max(maxx,x);maxy=math.max(maxy,y)
    painted=painted+1;if a<255 then partial=partial+1 end
  else clear=clear+1 end
end end
assert(minx>0 and miny>0 and maxx<511 and maxy<479,'Clipped artwork')
print(string.format('PASS: %dx%d, %d editable layers, exact RGBA match after reopening, content bounds [%d,%d]-[%d,%d], %d transparent / %d painted pixels (%d partial alpha)',spr.width,spr.height,#spr.layers,minx,miny,maxx,maxy,clear,painted,partial))
for _,l in ipairs(spr.layers) do print((l.isVisible and 'visible ' or 'hidden  ')..l.name) end
spr:close()
