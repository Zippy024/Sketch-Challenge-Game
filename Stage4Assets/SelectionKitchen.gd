extends "res://Stage3Assets/Model/KitchenModel.gd"
const Products=preload("res://Stage4Assets/ProductGeometry.gd")
var choices: Array[int]=[0,0,0,0]
var rotating: bool=false

func _ready() -> void:
	super._ready()
	for category in range(4):set_product(category,choices[category])
	for environment in scene.find_children("*","WorldEnvironment",true,false):environment.environment.background_color=Color("bceeff")
	# The Stage 3 shell includes fixed hood trim and cooktop controls outside its
	# selectable groups. Hide them here so replacements cannot leave ghost fittings.
	for child in installation.get_children():
		if child is MeshInstance3D:
			if child.position.distance_to(Vector3(-.825,1.715,.005))<.002:child.hide()
			if child.position.x<-.5 and child.position.y>.68 and child.position.y<.74 and child.position.z>.35:child.hide()
	# A small display plinth leaves the kitchen prominent at every selection state.
	var old_floor=scene.get_node("RoomOakFloor") as MeshInstance3D;old_floor.hide()
	var platform=_box(scene,Vector3(3.00,.065,1.05),installation.position+Vector3(0,-.045,.02),Color("d7b988"),-1,0.0,false)
	platform.name="Stage4OakPlatform";platform.material_override=old_floor.material_override
	_update_camera()

func _build_pointers() -> void:pass
func _ray_part(_point: Vector2) -> int:return -1

func _framing_points() -> PackedVector3Array:
	var points=PackedVector3Array()
	# Fixed bounds: changing a product never recomputes camera framing or scale.
	var bounds=AABB(Vector3(-1.50,-.09,-.51),Vector3(3.00,2.75,1.05))
	for i in range(8):points.append(installation.to_global(bounds.get_endpoint(i)))
	return points

func set_product(category: int,index: int) -> void:
	choices[category]=index
	var part=Products.PARTS[category];var group: Node3D=_groups[part]
	for child in group.get_children():group.remove_child(child);child.queue_free()
	_materials[part].clear()
	var product=Products.create(category,index);product.position=Products.ORIGINS[category];group.add_child(product)
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func _process(delta: float) -> void:
	if rotating and not _pressed:
		yaw+=delta*.25;_update_camera()
