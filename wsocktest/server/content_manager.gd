tool
extends Node


var contents : Dictionary
var available_extensions = ["gltf", "glb", "bin", "png", "mp3", "ogg", "ogv", "webm"]


func load_contents(payload):
	for i in range(payload.contents.size()):
		var content = payload.contents[i]
		if not contents.has(content.file.to_lower()) and \
		  content.file.get_extension() in available_extensions:

			content.thread = Thread.new()
			content.hash = content.hash.trim_suffix(content.file.get_extension())
			content.base_url = payload.baseUrl

			contents[content.file.to_lower()] = content

			var ext = content.file.get_extension()
			var file_name : String
			match ext:
				"glb", "gltf", "mp3", "ogv", "ogg", "webm":
					file_name = "user://%s.%s" % [content.hash, ext]
				"png", "bin":
					file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
				_:
					push_warning("*** undefined extension")

			var f = File.new()
			if f.file_exists(file_name):
				content.thread.start(self, "cache_file", content)
			else:
				content.thread.start(self, "download_file", content)


func download_file(info):
	var http = HTTPRequest.new()
	http.use_threads = true
	add_child(http)

	if http.request(info.base_url + info.hash) != OK:
		http.queue_free()
		printerr("*** error creating the download request for ", info.file)
		return null

	var result = yield(http, "request_completed")
	result.push_back(info)
	callv("downloaded_" + info.file.get_extension(), result)
	http.queue_free()

	return cache_file(info)


func downloaded_gltf(_result, response_code, _headers, body, content):
	downloaded_binary_file_with_hash(_result, response_code, _headers, body, content)

func downloaded_glb(_result, response_code, _headers, body, content):
	downloaded_binary_file_with_hash(_result, response_code, _headers, body, content)

func downloaded_mp3(_result, response_code, _headers, body, content):
	downloaded_binary_file_with_hash(_result, response_code, _headers, body, content)

func downloaded_ogg(_result, response_code, _headers, body, content):
	downloaded_binary_file_with_hash(_result, response_code, _headers, body, content)

func downloaded_ogv(_result, response_code, _headers, body, content):
	downloaded_binary_file_with_hash(_result, response_code, _headers, body, content)

func downloaded_webm(_result, response_code, _headers, body, content):
	downloaded_binary_file_with_hash(_result, response_code, _headers, body, content)


func downloaded_binary_file_with_hash(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s.%s" % [content.hash, content.file.get_extension()]
		if f.open(file_name, File.WRITE) == OK:
			f.store_buffer(body)
			f.close()


func downloaded_png(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var image = Image.new()
		if image.load_png_from_buffer(body) != OK:
			pass
		var file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
		image.save_png(file_name)


func downloaded_bin(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
		if f.open(file_name, File.WRITE) == OK:
			f.store_buffer(body)
			f.close()


func cache_file(content):
	var f = content.file.to_lower()
	if not f in contents:
		var ext = content.file.get_extension()
		match ext:
			"glb", "gltf":
				var l = DynamicGLTFLoader.new()
				contents[f].asset = l.import_scene("user://%s.%s" % [content.hash, ext], 1, 1)

			"mp3":
				var s := AudioStreamMP3.new()
				var file = File.new()
				file.open("user://%s.%s" % [content.hash, ext],File.READ)
				s.data = file.get_buffer(file.get_len())
				file.close()
				contents[f].asset = s

			"ogv", "ogg":  #TODO: handle ogg being an audio file
				var v := VideoStreamTheora.new()
				v.set_file("user://%s.%s" % [content.hash, ext])
				contents[f].asset = v

			"webm":
				var v := VideoStreamWebm.new()
				v.set_file("user://%s.%s" % [content.hash, ext])
				contents[f].asset = v

			_:
				printerr("Content Manager: Unknown file type for caching")
				return null

	return contents[f].asset


func get_instance(file_hash):
	var f = file_hash.to_lower()
	if contents[f].thread.is_active():
		return contents[f].thread.wait_to_finish()

	return contents[f].asset
