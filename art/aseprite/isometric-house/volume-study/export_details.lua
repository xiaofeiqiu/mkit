local base=app.params.output
local source=Image{fromFile=app.fs.joinPath(base,'hearth-cottage-volume-preview.png')}
local board=Image(1236,504,ColorMode.RGB)
board:clear(Color{r=231,g=227,b=214,a=255})
for i,pos in ipairs({{212,104},{231,304}}) do
  local crop=Image(300,240,ColorMode.RGB)
  crop:drawImage(source,Point(-pos[1],-pos[2]))
  crop:resize(600,480)
  board:drawImage(crop,Point(12+(i-1)*612,12))
end
board:saveAs(app.fs.joinPath(base,'structure-details.png'))
print('Saved roof / door and window detail sheet (2x nearest-neighbor)')
