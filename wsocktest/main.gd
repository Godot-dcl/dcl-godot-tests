extends Spatial


const ActionsMap = {
	Event.Action.POINTER: "[P] ",
	Event.Action.PRIMARY: "[E] ",
	Event.Action.SECONDARY: "[F] ",
	Event.Action.ANY: "",
}


func _ready():
	Server.loading_screen = $Control/Loading
	Server.player = $CameraRig

	EventManager.connect("entity_hover_changed", self, "_on_entity_hovered_changed")


func _on_entity_hovered_changed(entity):
	if entity == null:
		$Control/EntityHovered.hide()
		return

	$Control/EntityHovered.show()

	if entity.get_parent().has_meta("events"):
		for i in entity.get_parent().get_meta("events"):
			if i.entity == entity:
				$Control/EntityHovered/Action.text = "%s %s" % [ActionsMap[i.action], i.text]
				return
