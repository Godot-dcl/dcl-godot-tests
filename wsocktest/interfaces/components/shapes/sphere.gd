extends "res://interfaces/components/shape.gd"
class_name DCL_SphereShape

const _classid = 17


func _init(_name, _scene, _id).(_name, _scene, _id):
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	mesh_instance.mesh = sphere
	mesh_instance.set_surface_material(0, material)
