extends "res://interfaces/components/shape.gd"
class_name DCL_PlaneShape

const _classid = 18


func _init(_name).(_name):
	var plane = PlaneMesh.new()
	plane.size = Vector3.ONE
	mesh_instance.mesh = plane
