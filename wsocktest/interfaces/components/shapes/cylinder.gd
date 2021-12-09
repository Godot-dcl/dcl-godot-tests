extends "res://interfaces/components/shape.gd"
class_name DCL_CylinderShape

const _classid = 20


func _init(_name, _scene, _id).(_name, _scene, _id):
	var cylinder = CylinderMesh.new()
	cylinder.height = 1.0
	cylinder.top_radius = 1.0
	cylinder.bottom_radius = 1.0
	mesh_instance.mesh = cylinder
