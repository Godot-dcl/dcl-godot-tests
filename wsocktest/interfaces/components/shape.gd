extends "res://interfaces/component.gd"

var mesh_instance = MeshInstance.new()
var material : SpatialMaterial


func _init(_name).(_name):
	material = SpatialMaterial.new()
	mesh_instance.name = name
	mesh_instance.set("material/0", material)


func update(data):
	var json = JSON.parse(data).result
	if json.has("withCollisions"):
		mesh_instance.create_trimesh_collision()
		var collider = mesh_instance.get_child(0)
		collider.name = name
		if json.has("isPointerBlocker"):
			collider.collision_layer = int(pow(2, 10) + pow(2, 11) + pow(2, 12))


func attach_to(entity):
	entity.add_child(mesh_instance.duplicate())
