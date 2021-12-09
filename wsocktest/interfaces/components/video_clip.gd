extends "res://interfaces/component.gd"
class_name DCL_VideoClip

const _classid = 70

var url : String

var video_clip : VideoStream

var error = true

func _init(_name, _scene, _id).(_name, _scene, _id):
	pass

func update(data):
	var json = JSON.parse(data).result
	if json.has("url"):
		url = json.url
		if url.begins_with("http"):
			push_error("Error loading VideoClip. Real time streaming not supported by Godot")
		else:
			video_clip = ContentManager.get_instance(url)
			error = false
