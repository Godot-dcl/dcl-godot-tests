extends Node3D


const ActionsMap = {
	Event.Action.POINTER: "[P] ",
	Event.Action.PRIMARY: "[E] ",
	Event.Action.SECONDARY: "[F] ",
	Event.Action.ANY: "",
}

var last_hovered_event

func _ready():
	Server.loading_screen = $Control/Loading
	Server.player = $CameraRig

	EventManager.connect("entity_hover_changed", Callable(self, "_on_entity_hovered_changed"))


func _process(_delta):
	$Control/EntityHovered.visible = is_instance_valid(last_hovered_event) and last_hovered_event.is_near_player()


func _on_entity_hovered_changed(entity, _collider):
	if is_instance_valid(entity):
		if entity.get_parent().has_meta("events"):
			for i in entity.get_parent().get_meta("events"):
				if i.entity == entity:
					last_hovered_event = i
					$Control/EntityHovered/Action.text = "%s %s" % [ActionsMap[i.action], i.text]
					return

	last_hovered_event = null
