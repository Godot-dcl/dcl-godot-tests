extends Spatial


func _ready():
	Server.loading_screen = $Control/Loading
	Server.player = $CameraRig


func _on_CameraRig_entity_hovered_changed(entity):
	if entity == null:
		$Control/EntityHovered.hide()
		return

	$Control/EntityHovered.show()

	if entity.get_parent().has_meta("events"):
		for i in entity.get_parent().get_meta("events"):
			if i.entity == entity:
				$Control/EntityHovered/Action.text = i.text
				return
