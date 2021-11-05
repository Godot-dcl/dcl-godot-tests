extends Reference


enum Action {
	POINTER,
	PRIMARY,
	SECONDARY,
	ANY
}

enum Type {
	DOWN,
	UP
}

var scene_id
var entity
var uuid : String
var type
var action
var text : String
var distance : int
var show_feedback : bool


func _init(_scene_id, _entity, json):
	scene_id = _scene_id
	entity = _entity
	var data = JSON.parse(json).result
	uuid = data.uuid if data.has("uuid") else ""
	type = 0 # TODO add rest of types
	action = 0 # TODO add rest of actions
	text = data.hoverText if data.has("hoverText") else ""
	distance = data.distance if data.has("distance") else 0
	show_feedback = data.showFeedback if data.has("showFeedback") else false


func is_near_player():
	return entity.global_transform.origin.distance_to(
			Server.player.global_transform.origin) < distance


func is_facing_player():
	return Server.player.last_entity_clicked == entity


func check(event : InputEvent):
	if not is_near_player() or not is_facing_player():
		return

	if event.is_action_pressed("Pointer"):
		send_request(Action.POINTER)
	elif event.is_action_pressed("Primary"):
		send_request(Action.PRIMARY)
	elif event.is_action_pressed("Secondary"):
		send_request(Action.SECONDARY)


func send_request(event_action):
	var response = {
		"eventType":"uuidEvent",
		"sceneId": scene_id,
		"payload": {
			"uuid": uuid,
			"payload": {"buttonId": event_action}
		}
	}

	Server.send({"type": "SceneEvent", "payload": JSON.print(response)})
