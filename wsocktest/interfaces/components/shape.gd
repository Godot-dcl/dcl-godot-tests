extends "res://interfaces/component.gd"

var mesh_instance = MeshInstance3D.new()
var material : StandardMaterial3D


func _init(_name, _scene, _id):
	super(_name, _scene, _id)

	material = StandardMaterial3D.new()
	mesh_instance.name = name
	# This needs to be set in the children classes since the surface count
	# for an MeshInstance with no mesh is 0
	#mesh_instance.set("material/0", material)


func update(data):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		# handle error
		return

	var json = parser.get_data()
	if json.has("withCollisions"):
		mesh_instance.create_trimesh_collision()
		var collider = mesh_instance.get_child(mesh_instance.get_child_count() -1 )
		collider.name = name
		if json.has("isPointerBlocker"):
			collider.collision_layer = int(pow(2, 10) + pow(2, 11) + pow(2, 12))


func attach_to(entity):
	entity.add_child(mesh_instance.duplicate())
