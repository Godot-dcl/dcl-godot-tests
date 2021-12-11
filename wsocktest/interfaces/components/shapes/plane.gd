extends "res://interfaces/components/shape.gd"
class_name DCL_PlaneShape

const _classid = 18

var width : float = 1
var height : float = 1

func _init(_name, _scene, _id).(_name, _scene, _id):
	# QuadMesh seems to be a better Godot equivalent
	# than Plane. Appears with the correct orientation
	var plane = QuadMesh.new()
	plane.size = Vector2(width,height)
	mesh_instance.mesh = plane

func update(data):
	var json = JSON.parse(data).result
	width = json.get("width", width)
	height = json.get("height", height)
	mesh_instance.mesh.size = Vector2(width,height)
	.update(data)
