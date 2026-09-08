local base=app.params.output
local spr=app.open(app.fs.joinPath(base,'hearth-cottage.aseprite'))
assert(spr.width==256 and spr.height==240,'Unexpected canvas size')
assert(#spr.layers==12,'Expected 12 editable layers')
assert(#spr.frames==1,'Expected one still frame')
assert(not spr.layers[1].isVisible,'Optional backdrop must be hidden')
local flat=Image(spr.spec)
flat:drawSprite(spr,1)
local png=Image{fromFile=app.fs.joinPath(base,'hearth-cottage.png')}
local opaque,transparent=0,0
local minX,minY,maxX,maxY=256,240,-1,-1
for y=0,239 do for x=0,255 do
  local p=flat:getPixel(x,y)
  local a=app.pixelColor.rgbaA(p)
  assert(a==0 or a==255,'Unexpected semi-transparent pixel')
  assert(p==png:getPixel(x,y),'PNG differs from the Aseprite composite')
  if a==255 then
    opaque=opaque+1
    minX=math.min(minX,x); minY=math.min(minY,y)
    maxX=math.max(maxX,x); maxY=math.max(maxY,y)
  else transparent=transparent+1 end
end end
assert(minX>0 and minY>0 and maxX<255 and maxY<239,'Artwork clipped at canvas edge')
print(string.format('PASS: 256x240, %d layers, RGBA alpha 0/255, %d painted / %d transparent pixels, bounds [%d,%d]-[%d,%d], PNG exact match',#spr.layers,opaque,transparent,minX,minY,maxX,maxY))
for _,layer in ipairs(spr.layers) do print((layer.isVisible and 'visible ' or 'hidden  ')..layer.name) end
spr:close()
