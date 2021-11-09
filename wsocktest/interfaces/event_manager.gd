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
var raycast : RayCast

# Called when the node enters the scene tree for the first time.
func _init():
	pass # Replace with function body.


func _process(_delta):
	if is_instance_valid(raycast):
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			var entity = collider.get_parent().get_parent()
			if entity != last_entity_hovered:
				last_entity_hovered = entity

				emit_signal("entity_hover_changed", entity)
		else:
			if last_entity_hovered != null:
				last_entity_hovered = null

				emit_signal("entity_hover_changed", null)
				return


func _input(event):
	if Input.is_action_just_pressed("Pointer"):
		send_request(Event.Action.POINTER, Event.Type.DOWN)
		if last_entity_hovered != null:
			emit_signal("pointer_down", last_entity_hovered)
	if Input.is_action_just_released("Pointer"):
		send_request(Event.Action.POINTER, Event.Type.UP)
		if last_entity_hovered != null:
			emit_signal("pointer_up", last_entity_hovered)

	if Input.is_action_just_pressed("Primary"):
		send_request(Event.Action.PRIMARY, Event.Type.DOWN)
		if last_entity_hovered != null:
			emit_signal("primary_down", last_entity_hovered)
	if Input.is_action_just_released("Primary"):
		send_request(Event.Action.PRIMARY, Event.Type.UP)
		if last_entity_hovered != null:
			emit_signal("primary_up", last_entity_hovered)

	if Input.is_action_just_pressed("Secondary"):
		send_request(Event.Action.SECONDARY, Event.Type.DOWN)
		if last_entity_hovered != null:
			emit_signal("secondary_down", last_entity_hovered)
	if Input.is_action_just_released("Secondary"):
		send_request(Event.Action.SECONDARY, Event.Type.UP)
		if last_entity_hovered != null:
			emit_signal("secondary_up", last_entity_hovered)


func send_request(action, type):
	var parcel_scenes = Server.parcel_scenes.keys()
	var response = {
		"eventType": "actionButtonEvent",
		"sceneId": Server.parcel_scenes[parcel_scenes[0]][0].id,
		"payload": {
			"payload": {
				"type": type,
				"buttonId": action,
				"origin": raycast.get_parent().get_parent().global_transform.origin,
				"direction": raycast.to_global(raycast.cast_to).normalized(),
				"hit": {
					"origin": parse_vector(Vector3.ZERO),
					"hitPoint": parse_vector(Vector3.ZERO),
					"length": 0.0,
					"normal": parse_vector(Vector3.ZERO),
					"worldNormal": parse_vector(Vector3.ZERO),
					"meshName": "",
					"entityId": "",
				}
			}
		}
	}
	Server.send({"type": "SceneEvent", "payload": JSON.print(response)})


func parse_vector(_in : Vector3):
	return {
		"x": _in.x,
		"y": _in.y,
		"z": _in.z,
	}
