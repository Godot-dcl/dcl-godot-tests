extends "res://interfaces/components/shape.gd"
class_name DCL_SphereShape

const _classid = 17


func _init(_name).(_name):
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	mesh_instance.mesh = sphere