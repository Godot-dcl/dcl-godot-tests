extends "res://interfaces/component.gd"
class_name DCL_VideoClip


const _classid = 70

const SUPPORTED_EXTENSIONS = ["ogg", "ogv", "webm"]

var url: String

var video_clip: VideoStream

enum {STATUS_READY, STATUS_ERRORED, STATUS_PREPARING}
var status = STATUS_ERRORED


func _init(_name, _scene, _id).(_name, _scene, _id):
	pass


func update(data):
	var json = JSON.parse(data).result
	if json.has("url"):
		url = json.url
		status = STATUS_ERRORED
		var ext = url.get_extension()
		var is_external = url.begins_with("http")
		var is_https = url.begins_with("https")

		if not ext in SUPPORTED_EXTENSIONS:
			status = STATUS_ERRORED
			push_error("DCL_VideoClip: Unsupported extention: %s" % ext)
			return

		if is_external:
			if not is_https:
				status = STATUS_ERRORED
				push_error("DCL_VideoClip: http is unsupported. Please use https")
				return

			status = STATUS_PREPARING
			var download = _load_external_video(url)
			if download is GDScriptFunctionState:
				yield(download,"completed")
			
		else:
			video_clip = ContentManager.get_instance(url)
		status = STATUS_READY


func _load_external_video(_url: String)-> void:
	var ret : VideoStream
	var file_name : String
	var ext = _url.get_extension()
	if ext in ["ogv", "ogg"]:
		ret = VideoStreamTheora.new()
		ext = "ogv"
	elif ext == "webm":
		ret = VideoStreamWebm.new()
	else:
		push_error("wrong format for external video")
		return
	
	file_name = "user://" + url.sha1_text() + "." + ext
	
	var http = HTTPRequest.new()
	http.use_threads = false
		
	
	http.download_file = file_name
	scene.add_child(http)
	
	# Fetch the file
	var fetch_res = http.request(_url)
	var fetch_response = yield(http,"request_completed")
	if fetch_res != OK:
		printerr("****** error creating the request: ", fetch_res)
	else:
		ret.set_file(http.download_file)
	
	http.queue_free()
	if url == _url: #If it doesn't match a new url was set and we no longer want the file
		video_clip = ret
