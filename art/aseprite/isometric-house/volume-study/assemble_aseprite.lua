-- Assemble the physically shaded beauty image into semantic Aseprite layers.
-- Every source RGBA pixel belongs to one layer; compositor shadows are preserved.
local base=app.params.output
local input=Image{fromFile=app.fs.joinPath(base,'cottage-volume.png')}
local W,H=input.width,input.height
local spr=Sprite(W,H,ColorMode.RGB)
spr.layers[1].name='00 · Review background (optional)'
local bg=Image(W,H,ColorMode.RGB);bg:clear(Color{r=231,g=227,b=214,a=255})
spr.cels[1].image=bg;spr.layers[1].isVisible=false
local names={'Stone paving','Thick plaster walls / window reveals','Foundation blocks',
  'Projecting oak framing','Recessed glass / frames / sills','Solid stone arch / jambs',
  'Inset oak door / ironwork','Curved overlapping clay tiles','Solid dormer',
  'Hollow stone chimney','Entry steps / lantern','Garden / flower boxes','Fence / barrel'}
local masks,images,layers={},{},{}
for i,name in ipairs(names) do
  masks[i]=Image{fromFile=app.fs.joinPath(base,'masks',string.format('mask_%02d_0001.png',i))}
  images[i]=Image(W,H,ColorMode.RGB);images[i]:clear()
  layers[i]=spr:newLayer();layers[i].name=string.format('%02d · %s',i,name)
end
local edges=Image(W,H,ColorMode.RGB);edges:clear()
local edgeLayer=spr:newLayer();edgeLayer.name='14 · Antialiased silhouette pixels'
local counts={};for i=1,#names do counts[i]=0 end
local unmatched=0
for y=0,H-1 do for x=0,W-1 do
  local p=input:getPixel(x,y)
  if app.pixelColor.rgbaA(p)>0 then
    local found=false
    for i,mask in ipairs(masks) do
      local q=mask:getPixel(x,y)
      local v=mask.colorMode==ColorMode.GRAY and app.pixelColor.grayaV(q) or app.pixelColor.rgbaR(q)
      if v>127 then images[i]:drawPixel(x,y,p);counts[i]=counts[i]+1;found=true;break end
    end
    if not found then edges:drawPixel(x,y,p);unmatched=unmatched+1 end
  end
end end
for i,img in ipairs(images) do spr:newCel(layers[i],1,img,Point(0,0)) end
spr:newCel(edgeLayer,1,edges,Point(0,0))
local palette=Palette(40)
local colors={'00000000','333d30','546849','728258','899565','beb597','e1d5b9','bcb29a',
'928970','6d6c5a','8a744f','6a5134','443a2b','b79969','6e785a','4b5c4a',
'29433c','687f6c','91a78c','d1b575','75452e','a25a36','bb7241','ce8c51',
'daa563','8e5737','523b2b','393b31','8e7d4e','b9a272','d5b88d','e8d6ab',
'826660','b18680','dab399','65543b','92916c','c8c0a1','e7e3d6','ffffff'}
for i,c in ipairs(colors) do
  palette:setColor(i-1,Color{r=tonumber(c:sub(1,2),16),g=tonumber(c:sub(3,4),16),b=tonumber(c:sub(5,6),16),a=i==1 and 0 or 255})
end
spr:setPalette(palette)
spr.filename=app.fs.joinPath(base,'hearth-cottage-volume.aseprite')
spr:saveAs(spr.filename)
spr:saveCopyAs(app.fs.joinPath(base,'hearth-cottage-volume.png'))
spr.layers[1].isVisible=true
spr:saveCopyAs(app.fs.joinPath(base,'hearth-cottage-volume-preview.png'))
spr.layers[1].isVisible=false;spr:saveAs(spr.filename)
-- Reopening verifies that serialization preserves all layers and all pixels.
spr:close()
local loaded=app.open(app.fs.joinPath(base,'hearth-cottage-volume.aseprite'))
assert(#loaded.layers==15 and not loaded.layers[1].isVisible)
local composite=Image(loaded.spec);composite:drawSprite(loaded,1)
local minx,miny,maxx,maxy=W,H,0,0
for y=0,H-1 do for x=0,W-1 do
  local original=input:getPixel(x,y);local actual=composite:getPixel(x,y)
  local alpha=app.pixelColor.rgbaA(original)
  if alpha>0 then
    assert(actual==original,'Composite mismatch at '..x..','..y)
    minx=math.min(minx,x);miny=math.min(miny,y);maxx=math.max(maxx,x);maxy=math.max(maxy,y)
  else assert(app.pixelColor.rgbaA(actual)==0,'Unexpected opaque background') end
end end
assert(minx>0 and miny>0 and maxx<W-1 and maxy<H-1,'Clipped silhouette')
print(string.format('PASS %dx%d, 15 layers, RGBA round-trip matches beauty image; bounds [%d,%d]-[%d,%d]',W,H,minx,miny,maxx,maxy))
for i,name in ipairs(names) do print(string.format('%02d %s: %d pixels',i,name,counts[i])) end
print('Antialiasing fringe: '..unmatched..' pixels')
loaded:close()
