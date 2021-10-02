tool
extends Spatial


func _init():
	name = "DebuggerDump"


func _ready():
	connect("tree_exited", self, "_on_tree_exited", [], CONNECT_ONESHOT)
	Server.connect("server_state_changed", self, "_on_server_state_changed",
			[], CONNECT_ONESHOT)


# Nodes don't get freed when removed from the Scene dock, but instead kept into
# the undo/redo history. They need to be removed from the dump node in order to
# be dumped somewhere else, even if it affects undo/redo operations.
func _on_tree_exited():
	for i in get_children():
		remove_child(i)

	Server.disconnect(
			"server_state_changed", self, "_on_server_state_changed")


# If the server is offline, then the children are not bound to it anymore, so
# no need to free them when exiting the tree.
func _on_server_state_changed(is_listening):
	if not is_listening:
		disconnect("tree_exited", self, "_on_tree_exited")
