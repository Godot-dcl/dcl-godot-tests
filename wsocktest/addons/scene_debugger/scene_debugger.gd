tool
extends Control


var _editor_interface
var _editor_undoredo

var peer_current = -1
var scene_current = null

onready var peers = $VBoxContainer/TabContainer/Peers/Tree
onready var scenes = $VBoxContainer/TabContainer/Scenes/Tree
onready var events = $VBoxContainer/TabContainer/Events/Tree


func _ready():
	$VBoxContainer/TabContainer/Scenes/HBoxContainer/Back.icon =\
			get_icon("Back", "EditorIcons")
	$VBoxContainer/TabContainer/Scenes/HBoxContainer/Filter.icon =\
			get_icon("AnimationFilter", "EditorIcons")
	$VBoxContainer/TabContainer/Scenes/HBoxContainer/Filter.get_popup().\
			connect("index_pressed", self, "_on_filter_selected")

	$VBoxContainer/TabContainer/Events/HBoxContainer/Back.icon =\
			get_icon("Back", "EditorIcons")

	Server.connect("server_state_changed", self, "_on_server_state_changed")
	Server.connect("peer_connected", self, "_on_peer_connected")
	Server.connect("peer_disconnected", self, "_on_peer_disconnected")
	Server.connect("scene_created", self, "_on_scene_created")


func _on_server_state_changed(is_listening):
	$VBoxContainer/StartServer.text =\
			"Start Server" if not is_listening else "Stop Server"

	if is_listening:
		peers.create_item() # Create root item.
	else:
		peer_current = -1
		scene_current = null

		peers.clear()
		scenes.clear()
		events.clear()

		$VBoxContainer/TabContainer.current_tab = 0


func _on_peer_connected(id):
	var item = peers.create_item()
	item.set_text(0, str(id))
	item.set_metadata(0, id)


func _on_peer_disconnected(id):
	var item = peers.get_root().get_children()
	while item != null:
		if item.get_metadata(0) == id:
			peers.get_root().remove_child(item)

			if id == peer_current:
				peer_current = -1
				scene_current = null

				$VBoxContainer/TabContainer.current_tab = 0
			else:
				peers.update() # Needs to re-trigger a draw call manually.

			break

		item = item.get_next()


func _on_peer_activated():
	peer_current = peers.get_selected().get_metadata(0)
	_update_scenes_list()

	$VBoxContainer/TabContainer.current_tab = 1
	$VBoxContainer/TabContainer/Scenes/DumpSelIntoScene.disabled = true
	$VBoxContainer/TabContainer/Scenes/DumpAllIntoScene.disabled =\
			scenes.get_root().get_children() == null


func _on_scene_activated():
	scene_current = scenes.get_selected().get_metadata(0)
	_update_events_list()

	$VBoxContainer/TabContainer.current_tab = 2
	$VBoxContainer/TabContainer/Events/Send.disabled = true


func _on_scene_created(scene):
	# Check if the scene list is opened.
	if $VBoxContainer/TabContainer.current_tab == 1:
		if scene.peer != Server.peers[peer_current]:
			return

		var item = scenes.create_item()
		item.set_text(0, scene.name)
		item.set_metadata(0, scene)

		scene.connect("received_event", self, "_on_scene_received_event")


func _on_scene_received_event(scene):
	# Check if the scene list is opened.
	if $VBoxContainer/TabContainer.current_tab == 1:
		if $VBoxContainer/TabContainer/Scenes/HBoxContainer/Filter.\
				get_popup().is_item_checked(0):
			_update_scenes_list()
	# Check if the events list is opened.
	elif $VBoxContainer/TabContainer.current_tab == 2:
		if scene_current == scene:
			_update_events_list()


func _on_filter_selected(index):
	var filter = $VBoxContainer/TabContainer/Scenes/HBoxContainer/Filter.get_popup()
	filter.set_item_checked(index, not filter.is_item_checked(index))

	_update_scenes_list()


func _update_scenes_list():
	scenes.clear()
	scenes.create_item() # Create root item.

	var filter = $VBoxContainer/TabContainer/Scenes/HBoxContainer/Filter.get_popup()
	for i in Server.global_scenes.values() + Server.parcel_scenes.values():
		var scene = i[0]

		if scene.peer != Server.peers[peer_current]:
			continue
		if filter.is_item_checked(0) and not scene.has_meta("events"):
			continue

		var item = scenes.create_item()
		item.set_text(0, scene.name)
		item.set_metadata(0, scene)

		if not scene.is_connected("received_event", self, "_on_scene_received_event"):
			scene.connect("received_event", self, "_on_scene_received_event")


func _update_events_list():
	events.clear()
	events.create_item() # Create root item.

	if not scene_current.has_meta("events"):
		return

	for i in scene_current.get_meta("events"):
		var item = events.create_item()
		item.set_text(0, i.text if i.text != "" else "[Nameless Event]")
		item.set_metadata(0, i)


func _on_StartServer_pressed():
	if not Server.is_listening():
		Server.start_server()
	else:
		Server.stop_server()


func _on_Scenes_multi_selected(_item, _column, _selected):
	$VBoxContainer/TabContainer/Scenes/DumpSelIntoScene.disabled = false


func _on_DumpSelIntoScene_pressed():
	var scene_root = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		printerr("Couldn't get root of active scene")
		return

	var dump_node = _generate_dump_node(scene_root)
	var item = scenes.get_selected()
	while item != null:
		var scene = item.get_metadata(0)
		if scene.is_inside_tree():
			printerr("\"" + scene.name + "\" has already been dumped. " +
					"Remove from the scene to dump it again")

			item = item.get_next()
			continue

		dump_node.add_child(scene)
		_completely_own_node(scene, scene_root)

		item = scenes.get_next_selected(item)

	if $VBoxContainer/TabContainer/Scenes/ForceOrigin.pressed:
		_calculate_dump_origin(dump_node)


func _on_DumpAllIntoScene_pressed():
	var scene_root = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		printerr("Couldn't get root of active scene")
		return

	var dump_node = _generate_dump_node(scene_root)
	var item = scenes.get_root().get_children()
	while item != null:
		var scene = item.get_metadata(0)
		if scene.is_inside_tree():
			printerr("\"" + scene.name + "\" has already been dumped. " +
					"Remove from the scene to dump it again")

			item = item.get_next()
			continue

		dump_node.add_child(scene)
		_completely_own_node(scene, scene_root)

		item = item.get_next()

	if $VBoxContainer/TabContainer/Scenes/ForceOrigin.pressed:
		_calculate_dump_origin(dump_node)


func _on_Send_pressed():
	events.get_selected().get_metadata(0).check(0)


func _generate_dump_node(parent):
	var dump_node = Spatial.new()
	dump_node.set_script(
			preload("res://addons/scene_debugger/debugger_dump.gd"))

	_editor_undoredo.create_action("Dump scene nodes")
	_editor_undoredo.add_do_method(parent, "add_child", dump_node)
	_editor_undoredo.add_do_property(dump_node, "owner", parent)
	_editor_undoredo.add_undo_method(parent, "remove_child", dump_node)
	_editor_undoredo.commit_action()

	return dump_node


func _completely_own_node(node, new_owner):
	node.owner = new_owner
	for i in node.get_children():
		_completely_own_node(i, new_owner)


func _calculate_dump_origin(dump_node):
	var pos_min = null
	var pos_max = null

	# Get the furthest opposite values.
	for scene in dump_node.get_children():
		if pos_min == null:
			pos_min = scene.translation
			pos_max = scene.translation

			continue

		pos_min.x = min(scene.translation.x, pos_min.x)
		pos_min.y = min(scene.translation.y, pos_min.y)
		pos_min.z = min(scene.translation.z, pos_min.z)

		pos_max.x = max(scene.translation.x, pos_max.x)
		pos_max.y = max(scene.translation.y, pos_max.y)
		pos_max.z = max(scene.translation.z, pos_max.z)

	# Calculate the center point of each Vector3 element (x, y, z).
	for i in 3:
		if pos_min[i] >= 0:
			dump_node.translation[i] -= pos_min[i]

			var size = pos_max[i] - pos_min[i]
			if size > 0:
				dump_node.translation[i] -= size / 2

		elif pos_max[i] < 0:
			dump_node.translation[i] += abs(pos_max[i])

			var size = abs(pos_min[i] + abs(pos_max[i]))
			if size > 0:
				dump_node.translation[i] += size / 2

		else:
			dump_node.translation[i] += pos_min[i]

			var size = pos_max[i] + abs(pos_min[i])
			if size > 0:
				dump_node.translation[i] -= size / 2
