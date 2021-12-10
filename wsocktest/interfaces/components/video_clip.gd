extends "res://interfaces/component.gd"
class_name DCL_VideoClip

const _classid = 70

const SUPPORTED_EXTENSIONS = ["ogg", "ogv", "webm"]

var url : String

var video_clip : VideoStream

enum { STATUS_READY, STATUS_ERRORED, STATUS_PREPARING }
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

		if not is_https:
			status = STATUS_ERRORED
			push_error("DCL_VideoClip: http is unsupported. Please use https" % ext)
			return

		if is_external:
			status = STATUS_PREPARING
			var download = _get_external_video(url)
			if download is GDScriptFunctionState:
				yield(download,"completed")
			if not url == json.url: #If it doesn't match a new url was set and we no longer want the file
				return

		video_clip = ContentManager.get_instance(url)
		status = STATUS_READY

func _get_external_video(url: String):
	var content = {"file": url, "hash" : str(url.hash())}
	if ContentManager.file_downloaded(content):
		ContentManager.cache_file(content)
		return
	
	var http = HTTPRequest.new()
	http.use_threads = false
	scene.add_child(http)
	var res = http.request(url)
	var response = yield(http,"request_completed")
	if res != OK:
		printerr("****** error creating the request: ", res)
		return

	response.append(content)
	callv("download_file", response)
	http.queue_free()


func download_file(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s.%s" % [content.hash, content.file.get_extension()]
		if f.open(file_name, File.WRITE) == OK:
			f.store_buffer(body)
			f.close()
	ContentManager.cache_file(content)
