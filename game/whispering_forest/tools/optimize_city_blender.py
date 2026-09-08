"""Refine editable city geometry in Blender; Godot owns all final rendering.

Run with Blender --background --python this_file -- --asset baker_house
or omit --asset to refine every prepared input. Sources stay in blender/*.blend.
"""
import bpy
import json
import math
import hashlib
import random
import sys
from pathlib import Path
from mathutils import Vector

ART = Path(__file__).resolve().parents[1] / "art" / "city"
ROOT = ART / "blender"
(ROOT/"editable").mkdir(exist_ok=True)
INPUT = json.loads((ROOT / "source-map.json").read_text())
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SELECTED = ARGS[ARGS.index("--asset") + 1].split(",") if "--asset" in ARGS else []

def srgb(value):
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4

def color(hex_value):
    return tuple(srgb(int(hex_value[i:i+2], 16)/255) for i in (0,2,4)) + (1,)

def material(name, hex_value):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    shader = m.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color(hex_value)
    shader.inputs["Roughness"].default_value = 0.96
    shader.inputs["Specular IOR Level"].default_value = 0.0
    return m

def position(p):
    # glTF/Godot: X/Z ground, Y up. Blender: X/Y ground, Z up.
    return Vector((p[0], -p[2], p[1]))

def bevel(obj, width=0.018):
    mod = obj.modifiers.new("Worn edge radius — metres", "BEVEL")
    mod.width = width
    mod.segments = 2
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(38)
    mod.harden_normals = True
    mod.use_clamp_overlap = True
    normal = obj.modifiers.new("Weighted planar normals", "WEIGHTED_NORMAL")
    normal.keep_sharp = True

def mesh(name, vertices, faces, mat, edge=0):
    data = bpy.data.meshes.new(name)
    data.from_pydata([position(v) for v in vertices], [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    if edge:
        bevel(obj, edge)
    return obj

def box(name, at, size, mat, edge=0.015):
    x,y,z = at
    a,b,c = (v/2 for v in size)
    vertices = [(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh(name,vertices,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,edge)

def beam(name,a,b,r,mat,sides=8):
    a,b = Vector(a),Vector(b)
    direction = (b-a).normalized()
    across = direction.cross(Vector((0,0,1)))
    if across.length<0.01:
        across = direction.cross(Vector((1,0,0)))
    across.normalize()
    other = direction.cross(across).normalized()
    vertices = [tuple(p+(across*math.cos(i*math.tau/sides)+other*math.sin(i*math.tau/sides))*r) for p in (a,b) for i in range(sides)]
    faces = [tuple(reversed(range(sides))),tuple(range(sides,sides*2))]
    faces += [(i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides)]
    return mesh(name,vertices,faces,mat)

def ellipsoid(name,at,size,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=position(at))
    obj=bpy.context.object
    obj.name=name
    obj.scale=(size[0],size[2],size[1])
    obj.data.materials.append(mat)
    for p in obj.data.polygons:
        p.use_smooth=True
    return obj

def cone(name,at,r,height,mat,sides=12):
    x,y,z=at
    vertices=[(x+math.cos(i*math.tau/sides)*r,y,z+math.sin(i*math.tau/sides)*r) for i in range(sides)]+[(x,y+height,z)]
    return mesh(name,vertices,[tuple(reversed(range(sides)))]+[(i,(i+1)%sides,sides) for i in range(sides)],mat)

def details(asset, spec):
	# (Geometry dimensions below remain in the shared metre scale.)
    if asset.startswith("wall_"):
        span=spec["module_spec"]["length"]/32
        damp=material("Blender localized limestone patina","9ea88f")
        for side in (-1,1):
            for index,x in enumerate((-span*0.32,span*0.20)):
                z=side*0.556
                vertices=[(x-0.20,0.16,z),(x+0.18,0.16,z),(x+0.16,0.24,z),(x+0.06,0.37,z),(x-0.06,0.27,z),(x-0.16,0.34,z)]
                mesh("Blender wall-foot mineral stain",vertices,[(0,1,2,3,4,5)],damp)
        return
    if spec["type"] != "building":
        return
    base = "garden_house" if asset.startswith("garden_house") else ("townhouse" if asset.startswith("townhouse") else asset)
    lotx,lotz=spec["lot_metres"]
    w,d=spec["body_width"],spec["body_depth"]
    front=d/2-0.30
    h=spec["floors"]*INPUT["render_profile"]["storey_metres"]
    wood=material("Blender aged oak","756049")
    dark=material("Blender dark end grain","574c40")
    pale=material("Blender light sandstone","d5d0bb")
    iron=material("Blender iron fittings","58666a")
    gold=material("Blender muted brass","b49a62")
    green=material("Blender garden sage","789476")
    bread=material("Blender baked wheat","c09664")
    accent=material("Blender shop accent",{"baker_house":"b98258","apothecary":"6d8d79","inn":"897487","guild":"557593","market_hall":"a77c62"}.get(base,"789084"))
    # Upper timber frames and corbels are structural, aligned to the walls.
    if base in {"inn","townhouse","baker_house","apothecary"}:
        for side in (-1,1):
            x=side*(w/2-0.12)
            box("Blender upper timber post",(x,h-1.49,front+0.055),(0.14,2.85,0.16),wood)
            beam("Blender eave corbel",(x-side*0.45,h-0.12,front+0.04),(x,h-0.65,front+0.04),0.065,wood,4)
        box("Blender facade lintel",(0,h-0.08,front+0.055),(w,0.17,0.17),wood)
    # Pictorial shop signs stay language-neutral; no tiny unreadable labels.
    if base in {"baker_house","apothecary","inn","forge","pet_lodge"}:
        x=-w*0.37
        y=2.78
        z=front+0.54
        beam("Blender sign bracket",(x,y+0.65,front),(x,y+0.65,z+0.04),0.035,iron)
        for dx in (-0.19,0.19):
            beam("Blender sign suspension",(x+dx,y+0.52,z),(x+dx,y+0.34,z),0.012,iron)
        box("Blender carved sign rim",(x,y,z),(0.74,0.57,0.10),dark,0.03)
        box("Blender painted sign",(x,y,z+0.057),(0.65,0.47,0.03),accent,0.025)
        if base=="baker_house":
            ellipsoid("Blender bakery loaf emblem",(x,y,z+0.09),(0.25,0.105,0.035),bread)
            for dx in (-0.12,0,0.12): beam("Blender bread scoring",(x+dx-0.02,y-0.04,z+0.128),(x+dx+0.03,y+0.055,z+0.128),0.011,pale)
        elif base=="apothecary":
            beam("Blender herb stem",(x,y-0.16,z+0.09),(x,y+0.15,z+0.09),0.013,pale)
            for side in (-1,1):
                ellipsoid("Blender herb leaves",(x+side*0.10,y+0.02,z+0.095),(0.105,0.055,0.018),pale)
        elif base=="forge":
            box("Blender anvil emblem top",(x,y+0.05,z+0.09),(0.46,0.08,0.035),pale,0)
            box("Blender anvil emblem waist",(x,y-0.05,z+0.09),(0.14,0.13,0.035),pale,0)
        elif base=="pet_lodge":
            ellipsoid("Blender paw pad",(x,y-0.045,z+0.09),(0.10,0.085,0.02),pale)
            for dx in (-0.13,0,0.13): ellipsoid("Blender paw toes",(x+dx,y+0.10,z+0.09),(0.045,0.05,0.02),pale)
        else:
            box("Blender bed emblem",(x,y-0.04,z+0.09),(0.42,0.10,0.035),pale,0)
            for dx in (-0.18,0.18): box("Blender bed posts",(x+dx,y-0.015,z+0.09),(0.04,0.27,0.035),pale,0)
    if base=="baker_house":
        # Rounded entrance nosing and a deep display counter give the bakery a
        # broad shopfront after the narrow original model is widened.
        for side in (-1,1):
            x=side*w*0.30
            box("Blender bakery display sill",(x,0.96,front+0.26),(1.25,0.13,0.40),wood)
            for i in range(4): ellipsoid("Blender window bread",(x+(i-1.5)*0.25,1.08,front+0.33),(0.12,0.055,0.07),bread)
        for side in (-1,1):
            ellipsoid("Blender flour sack",(side*w*0.43,0.42,front+0.41),(0.23,0.29,0.20),pale)
    elif base=="apothecary":
        for side in (-1,1):
            x=side*w*0.32
            for i in range(4):
                bottle=material("Blender glazed herb bottle",["769b96","a0a473","9a8196","7593a3"][i])
                beam("Blender herb bottle",(x+(i-1.5)*0.16,1.02,front+0.30),(x+(i-1.5)*0.16,1.19+(i%2)*0.08,front+0.30),0.055,bottle,10)
        # A shallow wall trellis with restrained climbing foliage.
        z=front+0.06
        x=w*0.43
        for dx in (-0.15,0.15): beam("Blender herb trellis",(x+dx,0.4,z),(x+dx,2.4,z),0.02,wood,4)
        for i in range(7):
            ellipsoid("Blender trellis leaves",(x+math.sin(i*2.1)*0.17,0.65+i*0.25,z+0.06),(0.14,0.12,0.07),green)
    elif base=="inn":
        for side in (-1,1):
            x=side*w*0.39
            beam("Blender balcony knee brace",(x,2.10,front),(x,3.35,front+0.53),0.065,wood,4)
            box("Blender balcony post foot",(x,3.39,front+0.53),(0.17,0.20,0.17),dark)
    elif base=="guild":
        # Two shorter roof lanterns frame the civic clock tower and establish
        # a public-building silhouette distinct from the residential roofs.
        for side in (-1,1):
            x=side*w*0.37
            z=-0.70
            beam("Blender civic lantern drum",(x,h-0.4,z),(x,h+1.13,z),0.46,pale,8)
            for angle in range(4):
                a=angle*math.pi/2
                box("Blender lantern window",(x+math.cos(a)*0.45,h+0.71,z+math.sin(a)*0.45),(0.11,0.48,0.11),accent)
            cone("Blender civic lantern roof",(x,h+1.12,z),0.68,0.90,accent,8)
            beam("Blender lantern finial",(x,h+2.00,z),(x,h+2.40,z),0.025,gold,8)
    elif base=="forge":
        for side in (-1,1):
            x=side*w*0.45
            for row in range(6):
                box("Blender forge buttress stone",(x,0.38+row*0.31,front+0.16),(0.45,0.29,0.40),pale)
    elif base=="garden_house":
        for side in (-1,1):
            x=side*w*0.36
            for i in range(4): ellipsoid("Blender garden creeper",(x+math.sin(i*1.7)*0.10,0.50+i*0.22,front+0.14),(0.13,0.11,0.06),green)

def shared_preview_scene(profile):
    scene=bpy.context.scene
    scene.render.engine="BLENDER_EEVEE"
    scene.render.resolution_x=profile["canvas"]
    scene.render.resolution_y=profile["canvas"]
    scene.render.resolution_percentage=100
    scene.render.film_transparent=True
    scene.view_settings.view_transform="Standard"
    scene.view_settings.exposure=0
    scene.world=bpy.data.worlds.new("Shared city daylight preview")
    scene.world.color=(0.34,0.38,0.40)
    camera=bpy.data.cameras.new("Fixed 30 degree 2 to 1 camera")
    camera.type="ORTHO"
    camera.ortho_scale=profile["canvas"]/profile["pixels_per_metre"]
    obj=bpy.data.objects.new(camera.name,camera)
    scene.collection.objects.link(obj)
    target=position(profile["camera_target"])
    obj.location=target+position(profile["camera_offset"])
    obj.rotation_euler=(target-obj.location).to_track_quat("-Z","Y").to_euler()
    scene.camera=obj
    # Preview sun uses the same world ray. Final pixels are always rendered
    # by render_stage.gd with the recorded engine, not by this preview setup.
    for name,rotation,energy,hex_value in [("Shared upper-left sun",profile["key_rotation"],profile["key_energy"],profile["key_color"]),("Shared cool fill",profile["fill_rotation"],profile["fill_energy"],profile["fill_color"])]:
        rx,ry,_=(math.radians(v) for v in rotation)
        ray=position((-math.sin(ry)*math.cos(rx),math.sin(rx),-math.cos(ry)*math.cos(rx)))
        light=bpy.data.lights.new(name,"SUN")
        light.energy=energy
        light.color=color(hex_value)[:3]
        light.angle=math.radians(3)
        light_obj=bpy.data.objects.new(name,light)
        scene.collection.objects.link(light_obj)
        light_obj.rotation_euler=ray.to_track_quat("-Z","Y").to_euler()
    scene["final_render_config_sha256"]=profile["sha256"]
    scene["final_renderer"]="Godot render_stage.gd; Blender stores editable geometry"

def run(asset,spec):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/"input"/f"{asset}.glb"))
    overridden=[]
    shutter_color={"baker_house":"65877f","apothecary":"89758c","inn":"758981","townhouse":"7b8580"}.get(asset.split("_mauve")[0],"789187")
    for obj in list(bpy.context.scene.objects):
        if obj.type!="MESH":
            continue
        source_part=spec["material_source_paths"].get(obj.name,"")
        obj["editable_source_part"]=source_part
        role=spec.get("material_roles",{}).get(obj.name,"")
        if "Shutter" in source_part or (spec["type"]=="building" and asset!="guild" and role in {"blue","blue_dark"}):
            obj.data.materials.clear()
            paint=material("Blender district shutter",shutter_color)
            if role=="blue_dark":
                rgba=paint.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value
                for i in range(3): rgba[i]*=0.63
            obj.data.materials.append(paint)
            overridden.append(obj.name)
        if role in {"stone","stone_shadow","shade","cap"} and min(obj.dimensions)>0.10:
            # Stone wear is model geometry/vertex paint, preserved in the blend.
            # Keep modular endpoints and foundation dimensions exact.
            rng=random.Random(int(hashlib.sha256((asset+obj.name).encode()).hexdigest()[:12],16))
            tone=rng.uniform(0.86,1.0)
            attr=obj.data.color_attributes.get("StonePatina") or obj.data.color_attributes.new(name="StonePatina",type="FLOAT_COLOR",domain="CORNER")
            for corner in attr.data:
                corner.color=(tone,tone,tone,1)
            obj.data.color_attributes.active_color=attr
            if "Foundation" not in source_part and "Threshold" not in source_part and len(obj.data.vertices)<100:
                for vertex in obj.data.vertices:
                    # Millimetres of localized edge wear, not a crooked building.
                    if rng.random()<0.18:
                        vertex.co.z-=rng.uniform(0.004,0.014)
        if "FoliageMass" in source_part:
            for vertex in obj.data.vertices:
                p=vertex.co
                p*=1+0.035*math.sin(p.x*7.1+p.y*3.7)*math.sin(p.z*6.3)
            for polygon in obj.data.polygons:
                polygon.use_smooth=True
        elif min(obj.dimensions)>0.055 and len(obj.data.polygons)<160:
            bevel(obj,min(0.024,min(obj.dimensions)*0.12))
    before_details=set(bpy.context.scene.objects)
    details(asset,spec)
    if spec["type"]=="building":
        offset=position(spec.get("body_offset",[0,0,0]))
        for obj in set(bpy.context.scene.objects)-before_details:
            obj.location+=offset
    shared_preview_scene(INPUT["render_profile"])
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/"editable"/f"{asset}.blend"))
    # Selection deliberately contains model meshes only: no preview camera,
    # sun or world can leak into the final common-stage render.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        obj.select_set(obj.type=="MESH")
    bpy.ops.export_scene.gltf(filepath=str(ROOT/f"{asset}.glb"),export_format="GLB",use_selection=True,export_apply=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    return {"blend":f"res://game/whispering_forest/art/city/blender/editable/{asset}.blend","geometry":f"res://game/whispering_forest/art/city/blender/{asset}.glb","base_source":spec["base_source"],"material_source_paths":spec["material_source_paths"],"overridden_materials":overridden,"blender_version":bpy.app.version_string,"render_config_sha256":INPUT["render_profile"]["sha256"]}

record_path=ROOT/"optimized-models.json"
record=json.loads(record_path.read_text()) if record_path.exists() else {}
for asset,spec in INPUT["assets"].items():
    if SELECTED and asset not in SELECTED:
        continue
    record[asset]=run(asset,spec)
    record_path.write_text(json.dumps(record,ensure_ascii=False,indent=2)+"\n")
    print(f"WF_BLENDER_OPTIMIZED: {asset}",flush=True)
print("WF_BLENDER_OPTIMIZATION_OK",flush=True)
