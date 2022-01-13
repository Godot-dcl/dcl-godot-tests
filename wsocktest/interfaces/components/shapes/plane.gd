extends "res://interfaces/components/shape.gd"
class_name DCL_PlaneShape

const _classid = 18

var width : float = 1
var height : float = 1


func _init(_name, _scene, _id):
	super(_name, _scene, _id)
	# Planes are double-sided in the reference implementation
	material.params_cull_mode = material.CULL_DISABLED
	
	# QuadMesh seems to be a better Godot equivalent
	# than Plane. Appears with the correct orientation
	var plane = QuadMesh.new()
	plane.size = Vector2(width,height)
	mesh_instance.mesh = plane
	mesh_instance.set("material/0", material)
	


func update(data):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var json = parser.get_data()
	width = json.get("width", width)
	height = json.get("height", height)
	mesh_instance.mesh.size = Vector2(width,height)

	super.update(data)
