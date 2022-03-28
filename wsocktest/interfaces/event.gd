extends RefCounted
class_name Event


enum Action {
	POINTER,
	PRIMARY,
	SECONDARY,
	ANY
}
const ActionsMap = {
	"POINTER": Action.POINTER,
	"PRIMARY": Action.PRIMARY,
	"SECONDARY": Action.SECONDARY,
	"ANY": Action.ANY,
}

enum Type {
	DOWN,
	UP
}

var scene_id
var entity: Node
var uuid : String
var type
var action
var text: String
var distance: int
var show_feedback: bool


func _init(_scene_id, _entity, data):
	scene_id = _scene_id
	entity = _entity
	uuid = data.uuid if data.has("uuid") else ""
	type = data.type if data.has("type") else Type.DOWN
	action = ActionsMap[data.button] if data.has("button") else Action.ANY
	text = data.hoverText if data.has("hoverText") else ""
	distance = data.distance if data.has("distance") else 0
	show_feedback = data.showFeedback if data.has("showFeedback") else false

	match type:
		"pointerUp", "pointerDown":
			var t = data.type.trim_prefix("pointer").to_lower()
			if action == Action.ANY:
				for a in ActionsMap.keys():
					if a != "ANY":
						EventManager.connect("%s_%s" % [
							a.to_lower(),
							t
						], Callable(self, "check"))
			else:
				EventManager.connect("%s_%s" % [
					data.button.to_lower(),
					t
				], Callable(self, "check"))

				for c in entity.get_children():
					if c is PhysicsBody3D:
						c.collision_layer = int(pow(2, action + 9))

		"onClick":
			for a in ActionsMap.keys():
				if a != "ANY":
					EventManager.connect("%s_%s" % [
						a.to_lower(),
						"down"
					], Callable(self, "check"))

		"pointerHoverEnter", "pointerHoverExit":
			EventManager.connect("hover_%s" % [
				data.type.trim_prefix("pointerHover").to_lower()
			], Callable(self, "check"))


func is_near_player():
	return entity.global_transform.origin.distance_to(
			Server.player.global_transform.origin) < distance


func check(_entity, _collider=""):
	if (_entity is int and _entity == 0) or\
			(_entity == entity and is_near_player()):
		var response = {
			"eventType":"uuidEvent",
			"sceneId": scene_id,
			"payload": {
				"uuid": uuid,
				"payload": {
					"buttonId": action,
					"hit": {
						"meshName": _collider if _entity is int else _collider.name,
						"entityId": entity.name,
					}
				}
			}
		}

		var json = JSON.new()
		var message = {"type": "SceneEvent", "payload": json.stringify(response)}
		Server.send(message)
