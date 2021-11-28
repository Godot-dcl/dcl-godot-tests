extends Control


var scene_current


func set_scene(scene):
	scene_current = scene
	$PanelContainer.set_visible(scene_current != null)
	if scene_current == null:
		return

	$PanelContainer/VBoxContainer/SceneName.text = scene_current.name

	var events = $PanelContainer/VBoxContainer/Panel/ScrollContainer/Events
	for i in events.get_children():
		i.queue_free()

	if not scene_current.has_meta("events"):
		return

	for i in scene_current.get_meta("events"):
		var button = Button.new()
		button.text = i["hoverText"]
		button.connect("pressed", self, "_on_event_pressed", [i])
		events.add_child(button)


func _on_event_pressed(event):
	event.send_request()
