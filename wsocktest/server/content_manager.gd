tool
extends Node

var httprequests : Dictionary
var contents : Dictionary
var loading_scenes : Dictionary

func load_contents(scene, payload):
	if payload.contents.size() < 1:
		scene.contents_loaded()
		return

	loading_scenes[scene.id] = {"contents": [], "scene": scene, "loaded": 0}
	for i in range(payload.contents.size()):
		var content = payload.contents[i]

		# for now, just filter content
		if content.file.get_extension() in ["gltf", "glb", "bin", "png", "mp3", "ogg", "ogv", "webm"]:
			content.hash = content.hash.trim_suffix(content.file.get_extension())
			loading_scenes[scene.id].contents.push_back(content)

	for i in range(loading_scenes[scene.id].contents.size()):
		var content = loading_scenes[scene.id].contents[i]
		if file_downloaded(content):
			cache_file(content)
		else:
			var http = HTTPRequest.new()
			http.use_threads = true
			var func_name = "download_" + content.file.get_extension()
			http.connect("request_completed", self, func_name, [content])
			add_child(http)

			var file : String = payload.baseUrl + content.hash
			var res = http.request(file)
			if res != OK:
				printerr("****** error creating the glb request: ", res)
				http.queue_free()
			else:
				httprequests[content.hash] = http


func file_downloaded(content):
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
	return f.file_exists(file_name)


func cache_file(content):
	var f = content.file.to_lower()
	if not f in contents:
		var ext = content.file.get_extension()
		match ext:
			"glb", "gltf":
				var l = DynamicGLTFLoader.new()
				contents[f] = l.import_scene("user://%s.%s" % [content.hash, ext], 1, 1)
			"mp3":
				var s := AudioStreamMP3.new()
				var file = File.new()
				file.open("user://%s.%s" % [content.hash, ext],File.READ)
				s.data = file.get_buffer(file.get_len())
				file.close()
				contents[f] = s
			"ogv", "ogg":  #TODO: handle ogg being an audio file
				var v := VideoStreamTheora.new()
				v.set_file("user://%s.%s" % [content.hash, ext])
				contents[f] = v
			"webm":
				var v := VideoStreamWebm.new()
				v.set_file("user://%s.%s" % [content.hash, ext])
				contents[f] = v
			"png":
				var i := Image.new()
				var file = File.new()
				file.open("user://%s" % content.file.right(content.file.rfind("/") + 1),File.READ)
				i.load_png_from_buffer(file.get_buffer(file.get_len()))
				file.close()
				contents[f] = i
				
				

	for scene in loading_scenes.keys():
		if content in loading_scenes[scene].contents:
			loading_scenes[scene].loaded += 1
			if loading_scenes[scene].loaded == loading_scenes[scene].contents.size():
				loading_scenes[scene].scene.contents_loaded()


func download_binary_file_with_hash(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s.%s" % [content.hash, content.file.get_extension()]
		if f.open(file_name, File.WRITE) == OK:
			f.store_buffer(body)
			f.close()

	if httprequests.has(content.hash):
		httprequests[content.hash].queue_free()
		httprequests.erase(content.hash)
	cache_file(content)

func download_png(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var image = Image.new()
		if image.load_png_from_buffer(body) != OK:
			pass
		var file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
		image.save_png(file_name)


	if httprequests.has(content.hash):
		httprequests[content.hash].queue_free()
		httprequests.erase(content.hash)
	cache_file(content)


func download_gltf(_result, response_code, _headers, body, content):
	download_glb(_result, response_code, _headers, body, content)


func download_glb(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s.%s" % [content.hash, content.file.get_extension()]
		if f.open(file_name, File.WRITE) == OK:
			f.store_buffer(body)
			f.close()

	if httprequests.has(content.hash):
		httprequests[content.hash].queue_free()
		httprequests.erase(content.hash)

	cache_file(content)


func download_bin(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
		if f.open(file_name, File.WRITE) == OK:
			f.store_buffer(body)
			f.close()

	if httprequests.has(content.hash):
		httprequests[content.hash].queue_free()
		httprequests.erase(content.hash)
	cache_file(content)

func download_mp3(_result, response_code, _headers, body, content):
	download_binary_file_with_hash(_result, response_code, _headers, body, content)

func download_ogg(_result, response_code, _headers, body, content):
	download_binary_file_with_hash(_result, response_code, _headers, body, content)

func download_ogv(_result, response_code, _headers, body, content):
	download_binary_file_with_hash(_result, response_code, _headers, body, content)

func download_webm(_result, response_code, _headers, body, content):
	download_binary_file_with_hash(_result, response_code, _headers, body, content)

func get_instance(file_hash):
	var f = file_hash.to_lower()
	if f in contents:
		if !is_instance_valid(contents[f]):
			printerr("content null %s" % f)
			return null

		var instance = contents[f].duplicate()
		return instance
	else:
		printerr("content not found %s" % f)
		return null
