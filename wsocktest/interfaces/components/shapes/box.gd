extends "res://interfaces/components/shape.gd"
class_name DCL_BoxShape

const _classid = 16


func _init(_name, _scene, _id):
	super(_name, _scene, _id)
	var box = BoxMesh.new()
	box.size = Vector3.ONE
	mesh_instance.mesh = box
	mesh_instance.mesh.surface_set_material(0, material)
