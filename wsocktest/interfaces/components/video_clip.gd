extends "res://interfaces/component.gd"
class_name DCL_VideoClip


const _classid = 70

const SUPPORTED_EXTENSIONS = ["ogg", "ogv", "webm"]

var url: String

var video_clip

# status is still necessary because the FFMPEG video clip will have a load_async method
enum {STATUS_READY, STATUS_ERRORED, STATUS_PREPARING}
var status = STATUS_ERRORED


func _init(_name, _scene, _id):
	super(_name, _scene, _id)


func update(data):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var json = parser.get_data()

	# TODO: figure out the full url when the clip is a local path
	if json.has("url"):
		printt("json url is ", url)
		url = json.url
		status = STATUS_READY
		video_clip = url
