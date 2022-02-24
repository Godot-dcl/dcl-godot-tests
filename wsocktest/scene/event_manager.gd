extends Node

signal pointer_down(entity)
signal pointer_up(entity)

signal primary_down(entity)
signal primary_up(entity)

signal secondary_down(entity)
signal secondary_up(entity)

# entity can be null here!
signal entity_hover_changed(entity)

var last_entity_hovered : Node
var last_entity_collider_hovered : PhysicsBody3D
var raycast : RayCast3D

@onready var json = JSON.new()

# Called when the node enters the scene tree for the first time.
func _init():
	pass # Replace with function body.


func _process(_delta):
	if is_instance_valid(raycast):
		if !raycast.is_colliding():
			if last_entity_hovered != null:
				last_entity_hovered = null
				last_entity_collider_hovered = null

				emit_signal("entity_hover_changed", null, null)
			return

		var collider = raycast.get_collider()
		last_entity_hovered = collider.get_parent().get_parent()
		if collider != last_entity_collider_hovered:
			last_entity_collider_hovered = collider

			emit_signal("entity_hover_changed", last_entity_hovered, collider)

	check_input()

func check_input():
	if Input.is_action_just_pressed("Pointer"):
		send_request(Event.Action.POINTER, Event.Type.DOWN)
		if last_entity_hovered != null:
			emit_signal("pointer_down", last_entity_hovered, last_entity_collider_hovered)
	if Input.is_action_just_released("Pointer"):
		send_request(Event.Action.POINTER, Event.Type.UP)
		if last_entity_hovered != null:
			emit_signal("pointer_up", last_entity_hovered, last_entity_collider_hovered)

	if Input.is_action_just_pressed("Primary"):
		send_request(Event.Action.PRIMARY, Event.Type.DOWN)
		if last_entity_hovered != null:
			emit_signal("primary_down", last_entity_hovered, last_entity_collider_hovered)
	if Input.is_action_just_released("Primary"):
		send_request(Event.Action.PRIMARY, Event.Type.UP)
		if last_entity_hovered != null:
			emit_signal("primary_up", last_entity_hovered, last_entity_collider_hovered)

	if Input.is_action_just_pressed("Secondary"):
		send_request(Event.Action.SECONDARY, Event.Type.DOWN)
		if last_entity_hovered != null:
			emit_signal("secondary_down", last_entity_hovered, last_entity_collider_hovered)
	if Input.is_action_just_released("Secondary"):
		send_request(Event.Action.SECONDARY, Event.Type.UP)
		if last_entity_hovered != null:
			emit_signal("secondary_up", last_entity_hovered, last_entity_collider_hovered)


func send_request(action, type):
	if Server.player == null:
		return

	var colliding = raycast.is_colliding()
	var collision_point = raycast.get_collision_point() if colliding else Vector3.ZERO
	var collision_normal = parse_vector(raycast.get_collision_normal() if colliding else Vector3.ZERO)
	var response = {
		"eventType": "actionButtonEvent",
		"sceneId": Server.player.current_scene_id(),
		"payload": {
			"payload": {
				"type": type,
				"buttonId": action,
				"origin": raycast.get_parent().get_parent().global_transform.origin,
				"direction": raycast.to_global(raycast.target_position).normalized(),
				"hit": {
					"origin": parse_vector(raycast.global_transform.origin if colliding else Vector3.ZERO),
					"hitPoint": parse_vector(collision_point),
					"length": raycast.global_transform.origin.distance_to(collision_point) if colliding else 0.0,
					"normal": collision_normal,
					"worldNormal": collision_normal,
					"meshName": last_entity_collider_hovered.name if colliding else "",
					"entityId": last_entity_hovered.name if colliding else "",
				}
			}
		}
	}
	Server.send({"type": "SceneEvent", "payload": json.stringify(response)})

func report_raycast_hitall_result(raycast, result):
		var did_hit = !result.is_empty()
		var entities = []
		var hit_point = parse_vector(Vector3())
		var hit_normal = parse_vector(Vector3())
		if did_hit:
			entities.append(result.collider.name)
			hit_point = parse_vector(result.position)
			hit_normal = parse_vector(result.normal)
		
		var response = {
			"sceneId": raycast.scene.id,
			"eventType":"raycastResponse",
			"payload": {
				"didHit":did_hit,
				"ray":raycast.ray.get_origin(),
				"direction":raycast.ray.get_direction(),
				"distance":raycast.ray.get_distance(),
				"hitPoint":hit_point,
				"hitNormal":hit_normal,
				"entities":entities
			}
		}
		Server.send({"type": "SceneEvent", "payload": json.stringify(response)})

func parse_vector(_in : Vector3):
	return {
		"x": _in.x,
		"y": _in.y,
		"z": _in.z,
	}
