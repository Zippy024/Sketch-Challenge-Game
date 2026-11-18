extends SceneTree
const Model=preload("res://Stage3Assets/Model/KitchenModel.gd")
const Progress=preload("res://GameProgress.gd")
const Parts=preload("res://Stage3Assets/Model/JapaneseParts.gd")
var chosen: Array[int]=[]
func _initialize() -> void:call_deferred("_run")
func _wait() -> void:await create_timer(0.08).timeout
func _run() -> void:
 var old:=ConfigFile.new()
 old.set_value("session","stage",3)
 old.set_value("session","step",4)
 old.set_value("session","parts_version",1)
 old.set_value("session","parts_answers",["カウンター","","","腰壁",""])
 old.set_value("session","parts_solved",[true,false,false,true,false])
 old.save(Progress.SAVE_PATH)
 Progress._loaded=false
 assert(Progress.kitchen_step()==4 and Progress.kitchen_parts().solved.size()==8)
 assert(Progress.kitchen_parts().answers[3]=="腰壁")
 old.set_value("progress","stage3_cleared",true)
 old.set_value("session","step",7)
 old.save(Progress.SAVE_PATH)
 Progress._loaded=false
 assert(Progress.kitchen_step()==10 and Progress.is_completed(3))
 Progress.open_stage(3)
 Progress._loaded=false
 assert(Progress.kitchen_step()==0 and Progress.kitchen_parts().solved.count(true)==0)
 var model=Model.new()
 model.size=Vector2(860,450)
 root.add_child(model)
 model.part_selected.connect(func(i: int):chosen.append(i))
 await _wait()
 assert(model.find_children("PartMarker*","Button",true,false).is_empty())
 assert(model._groups.size()==Parts.COUNT and model._pointers.size()==8)
 for pointer in model._pointers:assert(model.get_rect().encloses(pointer.get_rect()))
 assert(model.find_child("RoomBackWall",true,false)==null and model.find_child("RoomSideWall",true,false)==null)
 var targets=[Vector3(0.0,0.851,0.20),Vector3(0.28,1.08,-0.315),Vector3(-0.84,2.0,0.0),Vector3(0.45,0.5,-0.49),Vector3(0.75,0.855,0.02),Vector3(0.75,1.24,-0.18),Vector3(-1.0,0.862,0.06),Vector3(0.71,0.65,0.34)]
 for i in range(Parts.COUNT):
  model.set_view("rear" if i==3 else "perspective")
  await _wait()
  var point: Vector2=model.camera.unproject_position(model.installation.to_global(targets[i]))*model.size/Vector2(model.viewport.size)
  var hit: int=model._ray_part(point)
  print("DIRECT_HIT ",i," = ",hit)
  assert(hit==i)
  var hover:=InputEventMouseMotion.new()
  hover.position=point
  model._gui_input(hover)
  await _wait()
  assert(model.hovered==i)
  if model._materials[i][0].material is ShaderMaterial:
   assert(model._materials[i][0].material.get_shader_parameter("highlighted")==1.0)
  else:assert(model._materials[i][0].material.emission_enabled)
  var press:=InputEventMouseButton.new()
  press.position=point
  press.button_index=MOUSE_BUTTON_LEFT
  press.pressed=true
  model._gui_input(press)
  press.pressed=false
  model._gui_input(press)
  await _wait()
  assert(chosen.back()==i and model.selected==i)
 var previous_center: Vector2=model._pointers[0].position
 model.rotate_by(PI/4)
 assert(not model._pointers[0].position.is_equal_approx(previous_center))
 model._pointers[3].pressed.emit()
 assert(chosen.back()==3)
 var original: float=model.yaw
 for i in range(8):model.rotate_by(PI/4)
 assert(absf(wrapf(model.yaw-original,-PI,PI))<0.0001)
 assert(absf(model.camera.position.distance_to(Model.LOOK_TARGET)-6.0)<0.001)
 # Keep the original floor and place the complete installation near its rear-left
 # corner. Pointer anchors stay local to their corresponding kitchen parts.
 var floor=model.find_child("RoomOakFloor",true,false)
 assert(floor.mesh.get_aabb().size.is_equal_approx(Vector3(5.0,0.045,3.42)))
 assert(floor.position.is_equal_approx(Vector3(0,-0.025,0.59)))
 for child in model.scene.get_children():
  if child is MeshInstance3D:assert(child==floor) # No detached cabinet details.
 var floor_corner: Vector3=floor.position-floor.mesh.get_aabb().size*0.5
 var kitchen_corner: Vector3=model.installation.to_global(Model.KITCHEN_BOUNDS.position)
 assert(kitchen_corner.x-floor_corner.x>0 and kitchen_corner.x-floor_corner.x<0.25)
 assert(kitchen_corner.z-floor_corner.z>0 and kitchen_corner.z-floor_corner.z<0.25)
 for i in range(Parts.COUNT):
  assert(model._groups[i].get_parent()==model.installation)
  assert(model.part_center(i).distance_to(model.camera.unproject_position(model.installation.to_global(model._anchors[i]))*model.size/Vector2(model.viewport.size))<1)
 # Kitchen, hood and complete floor must fit short/wide/tall viewport shapes
 # at normal zoom. Their projected silhouette stays centered in the viewport.
 var anchors: Array=model._anchors.duplicate()
 for dimensions in [Vector2(1172,512),Vector2(860,450),Vector2(420,620)]:
  model.size=dimensions
  for preset in ["perspective","front","rear"]:
   model.set_view(preset)
   await _wait()
   assert(model._anchors==anchors)
   var points=model._framing_points()
   for vertex in points:
    var point: Vector2=model.camera.unproject_position(vertex)
    assert(Rect2(Vector2.ZERO,Vector2(model.viewport.size)).has_point(point))
   var frame: Rect2=model._projected_bounds(points)
   assert(frame.get_center().distance_to(Vector2(model.viewport.size)*0.5)<1)
   assert(absf(maxf(frame.size.x/model.viewport.size.x,frame.size.y/model.viewport.size.y)-0.88)<0.005)
 model.size=Vector2(860,450)
 model.set_view("perspective")
 original=model.yaw
 var before: int=chosen.size()
 var press:=InputEventMouseButton.new()
 press.button_index=MOUSE_BUTTON_LEFT
 press.pressed=true
 model._gui_input(press)
 var drag:=InputEventMouseMotion.new()
 drag.relative=Vector2(TAU/0.009,0)
 model._gui_input(drag)
 press.pressed=false
 model._gui_input(press)
 await _wait()
 assert(chosen.size()==before and absf(wrapf(model.yaw-original,-PI,PI))<0.0001)
 model.apply_view_state({"yaw":2.6,"pitch":0.5,"zoom":3.8})
 assert(is_equal_approx(model.view_state().yaw,2.6))
 assert(Parts.is_correct(5,"蛇口") and Parts.is_correct(6,"ｉｈ") and Parts.is_correct(7,"引き出し"))
 assert(Parts.conversion_candidates("すいせん")==["水栓","推薦"])
 assert(Parts.conversion_candidates("あいえいち")==["IH"])
 assert(Parts.conversion_candidates("ひきだし")==["引き出し","引出し"])
 assert(Parts.reading("シンク")=="しんく" and Parts.reading("蛇口")=="じゃぐち")
 assert(Parts.reading("引き出し")=="ひきだし" and Parts.reading("IH")=="あいえいち")
 print("DIRECT_KITCHEN_PARTS_OK: eight mesh hits, visible hover, click selection, eight pointer guides, full 360 drag/buttons, aliases and conversion")
 quit()
