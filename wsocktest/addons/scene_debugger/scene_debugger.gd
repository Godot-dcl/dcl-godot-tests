tool
extends Control


var _count = 0
var _messages = [
	{
		"type": "SystemInfoReport",
		"payload": JSON.print(
			{
				"graphicsDeviceName": "Mocked",
				"graphicsDeviceVersion": "Mocked",
				"graphicsMemorySize": 512,
				"processorType": "n/a",
				"processorCount": 1,
				"systemMemorySize": 256
			}
		)
	},
	{
		"type": "ControlEvent",
		"payload": JSON.print({"eventType": "ActivateRenderingACK"})
	},
]
var _editor_interface


func _ready():
	Server.connect("server_status_updated", self, "_on_server_status_updated")


func _on_server_status_updated(is_listening):
	$VBoxContainer/StartServer.text =\
			"Start Server" if not is_listening else "Stop Server"
	$VBoxContainer/SendMessage.disabled = not is_listening
	$VBoxContainer/DumpIntoScene.disabled = not is_listening


func _on_StartServer_pressed():
	if not Server.is_listening():
		Server.start_server()
	else:
		_count = 0
		Server.stop_server()


func _on_SendMessage_pressed():
	Server.send(_messages[_count])
	_count = (_count + 1) % _messages.size()


func _on_DumpIntoScene_pressed():
	var scene_root = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		printerr("Couldn't get root of active scene")
		return

	var dump_node = Spatial.new()
	dump_node.name = "DebuggerDump"
	scene_root.add_child(dump_node)
	dump_node.owner = scene_root

	for i in Server.global_scenes.values() + Server.parcel_scenes.values():
		var scene = i[0]
		if scene.owner != null:
			print("\"" + scene.name + "\" has already been dumped. " +
					"Remove from the scene to dump it again")
			continue

		dump_node.add_child(scene)
		_completely_own_node(scene, scene_root)


func _completely_own_node(node, new_owner):
	node.owner = new_owner
	for i in node.get_children():
		_completely_own_node(i, new_owner)
