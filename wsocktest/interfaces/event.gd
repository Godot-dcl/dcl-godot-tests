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
	uuid = data.uuid
	type = 0 # TODO add rest of types
	action = 0 # TODO add rest of actions
	text = data.hoverText
	distance = data.distance
	show_feedback = data.showFeedback

func is_near_player():
	return entity.transform.origin.distance_to(Server.player.transform.origin) < distance

func check(event : InputEvent):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		if is_near_player():# and is_facing_player():
			send_request()

func send_request():
	var response = {
		"eventType":"uuidEvent",
		"sceneId": scene_id,
		"payload": {
			"uuid": uuid,
			"payload": { "buttonId": 0 }
		}
	}

	Server.send({"type": "SceneEvent", "payload": JSON.print(response)})
