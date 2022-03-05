extends "res://interfaces/component.gd"
class_name DCL_VideoClip


const _classid = 70

const SUPPORTED_EXTENSIONS = ["ogg", "ogv", "webm"]

var url: String

var video_clip: VideoStream

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
			await _get_external_video(url)
			if url != json.url: #If it doesn't match a new url was set and we no longer want the file
				return

		video_clip = ContentManager.get_instance(url)
		status = STATUS_READY


func _get_external_video(url: String):
	# Get ETag and Last-Modified headers
	var http = HTTPRequest.new()
	http.use_threads = false
	scene.add_child(http)
	var check_res = http.request(url, [], true,HTTPClient.METHOD_HEAD)
	var check_response = await http.request_completed
	if check_res != OK:
		printerr("****** error creating the request: ", check_res)
		return

	var e_tag = ""
	var last_modified = ""
	for header in check_response[2]:
		if header.begins_with("ETag:"):
			e_tag = header
		if header.begins_with("Last-Modified:"):
			last_modified = header

	var content = {"file": url, "hash": (url + e_tag + last_modified).sha1_text()}
	if ContentManager.file_downloaded(content):
		ContentManager.cache_file(content)
		return

	# Fetch the file
	var fetch_res = http.request(url)
	var fetch_response = await http.request_completed
	if fetch_res != OK:
		printerr("****** error creating the request: ", fetch_res)
		return

	fetch_response.append(content)
	ContentManager.callv("download_binary_file_with_hash", fetch_response)
	http.queue_free()
