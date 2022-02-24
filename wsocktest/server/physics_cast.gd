extends Node

const PROTO = preload("res://server/engineinterface.gd")

var _layer_mask_target
var _raycast_handler

enum RaycastType { HIT_FIRST, HIT_ALL }

class RaycastQuery:
	var ray
	var origin : Vector3
	var target : Vector3
	var scene : Node3D
	func _init(ray_, scene_):
		ray = ray_
		var ray_origin = ray.get_origin()
		var ray_direction = ray.get_direction()
		origin = Vector3(ray_origin.get_x(), ray_origin.get_y(), ray_origin.get_z())
		target = Vector3(ray_direction.get_x(), ray_direction.get_y(), ray_direction.get_z()) * ray.get_distance()
		scene = scene_

var _raycast_parameters = PhysicsRayQueryParameters3D.new()

var _raycast_queue := []

func _ready():
	_raycast_parameters.collide_with_areas = true
	_raycast_parameters.hit_from_inside = true



func Query(query, scene):
	match query.get_queryType():
		"HitFirst":
			_hit_first(query, scene)
		"HitAll":
			_hit_all(query, scene)

func _hit_first(query, scene):
	print_debug("*** unimplemented")


func _hit_all(query, scene):
	var ray = query.get_ray()
	_raycast_queue.append(RaycastQuery.new(ray, scene))

func _physics_process(delta):
	while not _raycast_queue.is_empty():
		var raycast = _raycast_queue.pop_front()
		var space_state : PhysicsDirectSpaceState3D = raycast.scene.get_world_3d().direct_space_state
		_raycast_parameters.from = raycast.scene.to_global(raycast.origin)
		_raycast_parameters.to = raycast.scene.to_global(raycast.target)
		var result : Dictionary = space_state.intersect_ray(_raycast_parameters)
		EventManager.report_raycast_hitall_result(raycast, result)
		printt("Casting from %s to %s with result: %s" % [_raycast_parameters.from, _raycast_parameters.to, result])
