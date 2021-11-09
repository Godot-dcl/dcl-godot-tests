extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func message(msg):
	#printt("*** loading screen message ***", JSON.print(msg))

	$Title.text = "loading..."
	$Message.text = msg.message
	visible = msg.isVisible
