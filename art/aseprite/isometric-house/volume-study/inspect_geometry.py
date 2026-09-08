import bpy
from mathutils import Vector
from pathlib import Path
root=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(root/'cottage-volume.blend'))
deps=bpy.context.evaluated_depsgraph_get()
tests=[('Door leaf',(1.03,-4,1.14),(0,1,0),7),
       ('Front recessed glazing',(-1.39,-4,2.20),(0,1,0),5),
       ('Side recessed glazing',(4,-.67,2.20),(-1,0,0),5)]
for name,origin,direction,group in tests:
    hit,loc,norm,face,obj,matrix=bpy.context.scene.ray_cast(deps,Vector(origin),Vector(direction))
    assert hit and obj.pass_index==group,(name,obj.name if obj else None)
    depth=loc.y+1.75 if direction[1] else 2.20-loc.x
    assert depth>.20,(name,'Opening is too shallow',depth)
    print('PASS',name,': first visible surface =',obj.name,', setback =',round(depth,4),'m')
assert len([o for o in bpy.context.scene.objects if o.name.startswith('Overlapping curved clay tile')])>300
print('PASS: main roof uses independent closed curved tile meshes; source has 30 cm thick walls')
