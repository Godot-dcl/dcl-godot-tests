extends "res://interfaces/components/shape.gd"
class_name DCL_BoxShape

const _classid = 16


func _init(_name).(_name):
	var box = CubeMesh.new()
	box.size = Vector3.ONE
	mesh_instance.mesh = box
