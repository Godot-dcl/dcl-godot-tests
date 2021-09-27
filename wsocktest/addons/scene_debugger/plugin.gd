tool
extends EditorPlugin


var _scene_debugger =\
		preload("res://addons/scene_debugger/scene_debugger.tscn").instance()


func _enter_tree():
	_scene_debugger._editor_interface = get_editor_interface()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, _scene_debugger)


func _exit_tree():
	remove_control_from_docks(_scene_debugger)
	_scene_debugger.queue_free()
