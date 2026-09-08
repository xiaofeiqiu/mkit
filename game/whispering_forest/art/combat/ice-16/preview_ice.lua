local root=assert(app.params["root"])
local dir=root.."/game/whispering_forest/"
local sprite=Sprite{fromFile=dir.."art/combat/ice-16/ice-spear-16.aseprite"}
local board=Sprite(1536,1536,ColorMode.RGB)
local img=Image(1536,1536,ColorMode.RGB)
img:clear(app.pixelColor.rgba(33,55,63,255))
for f=1,16 do
  local x,y=((f-1)%4)*384,math.floor((f-1)/4)*384
  local cel=Image(384,384,ColorMode.RGB)
  cel:drawSprite(sprite,f)
  img:drawImage(cel,Point(x,y))
  -- Quiet cell dividers; art stays at its actual exported resolution.
  for n=0,383 do
    img:drawPixel(x+n,y,app.pixelColor.rgba(62,83,90,255))
    img:drawPixel(x,y+n,app.pixelColor.rgba(62,83,90,255))
  end
end
board:newCel(board.layers[1],1,img)
board:saveAs(dir.."preview/ice-16-frames.png")
board:close()
local background=sprite:newLayer(); background.name="Preview background only"
background.stackIndex=1
local fill=Image(384,384,ColorMode.RGB)
fill:clear(app.pixelColor.rgba(33,55,63,255))
for f=1,16 do sprite:newCel(background,f,fill,Point(0,0)) end
sprite:saveCopyAs(dir.."preview/ice-16.gif")
sprite:close()
print("WF_ICE_PREVIEW_EXPORTED: frame board and timed Aseprite GIF")
