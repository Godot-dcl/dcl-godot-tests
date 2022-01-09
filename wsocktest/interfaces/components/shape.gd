extends "res://interfaces/component.gd"

var mesh_instance = MeshInstance.new()
var material : SpatialMaterial


func _init(_name, _scene, _id).(_name, _scene, _id):
	material = SpatialMaterial.new()
	mesh_instance.name = name
	# This needs to be set in the children classes since the surface count
	# for an MeshInstance with no mesh is 0
	#mesh_instance.set("material/0", material)


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

	.attach_to(entity)

func detach_from(entity):
	entity.get_node(name).queue_free()

	.detach_from(entity)
