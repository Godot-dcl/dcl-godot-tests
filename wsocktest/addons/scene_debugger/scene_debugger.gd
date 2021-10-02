tool
extends Control


var _editor_interface
var _editor_undoredo

var peer_current = -1

onready var peers = $VBoxContainer/TabContainer/VBoxContainer/Peers
onready var scenes = $VBoxContainer/TabContainer/VBoxContainer2/Scenes


func _ready():
	$VBoxContainer/TabContainer/VBoxContainer2/HBoxContainer/Back.icon =\
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

		peers.clear()
		scenes.clear()

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
				$VBoxContainer/TabContainer.current_tab = 0
			else:
				peers.update() # Needs to re-trigger a draw call manually.

			break

		item = item.get_next()


func _on_peer_selected():
	peer_current = peers.get_selected().get_metadata(0)
	_update_scenes_list()

	$VBoxContainer/TabContainer.current_tab = 1
	$VBoxContainer/TabContainer/VBoxContainer2/DumpSelIntoScene.disabled = true
	$VBoxContainer/TabContainer/VBoxContainer2/DumpAllIntoScene.disabled =\
			scenes.get_root().get_children() == null


func _on_scene_created(scene):
	# Check if the scene list is opened.
	if $VBoxContainer/TabContainer.current_tab == 1:
		if scene.peer != Server.peers[peer_current]:
			return

		var item = scenes.create_item()
		item.set_text(0, scene.name)
		item.set_metadata(0, scene)


func _update_scenes_list():
	scenes.clear()
	scenes.create_item() # Create root item.

	for i in Server.global_scenes.values() + Server.parcel_scenes.values():
		var scene = i[0]
		if scene.peer != Server.peers[peer_current]:
			continue

		var item = scenes.create_item()
		item.set_text(0, scene.name)
		item.set_metadata(0, scene)


func _on_StartServer_pressed():
	if not Server.is_listening():
		Server.start_server()
	else:
		Server.stop_server()


func _on_Scenes_multi_selected(_item, _column, _selected):
	$VBoxContainer/TabContainer/VBoxContainer2/DumpSelIntoScene.disabled = false


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
