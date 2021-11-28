extends "res://interfaces/components/shape.gd"
class_name DCL_ConeShape

const _classid = 19


func _init(_name).(_name):
	var cone = CylinderMesh.new()
	cone.height = 1.0
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	mesh_instance.mesh = cone
