extends Node

var httprequests : Dictionary
var contents : Dictionary
var loading_scenes : Dictionary

func load_contents(scene, payload):
	loading_scenes[scene.id] = {"contents": [], "scene": scene, "loaded": 0}
	var loaded_contents : Array
	for i in range(payload.contents.size()):
		var content = payload.contents[i]
		if content.file.get_extension() in ["glb", "png"]:
			loading_scenes[scene.id].contents.push_back(content)
	
	for i in range(loading_scenes[scene.id].contents.size()):
		var content = loading_scenes[scene.id].contents[i]
		if file_downloaded(content):
			cache_file(content)
		else:
			var http = HTTPRequest.new()
			http.use_threads = true
			http.connect("request_completed", self, "download_" + content.file.get_extension(), [content])

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
		"glb":
			file_name = "user://%s.glb" % content.hash
		"png":
			file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
		_:
			push_warning("*** undefined extension")

	var f = File.new()
	return f.file_exists(file_name)


func cache_file(content):
	if not content.file in contents:
		var ext = content.file.get_extension()
		match ext:
			"glb":
				var l = DynamicGLTFLoader.new()
				contents[content.file] = l.import_scene("user://%s.glb" % content.hash, 1, 1)
	
	for scene in loading_scenes.keys():
		if content in loading_scenes[scene].contents:
			loading_scenes[scene].loaded += 1
			if loading_scenes[scene].loaded == loading_scenes[scene].contents.size():
				loading_scenes[scene].scene.contents_loaded()


func download_png(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var image = Image.new()
		if image.load_png_from_buffer(body) != OK:
			pass
		var file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
		image.save_png(file_name)

	httprequests[content.hash].queue_free()
	httprequests.erase(content.hash)
	cache_file(content)


func download_glb(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s.glb" % content.hash
		f.open(file_name, File.WRITE)
		f.store_buffer(body)
		f.close()

	httprequests[content.hash].queue_free()
	httprequests.erase(content.hash)
	cache_file(content)


func get_instance(file_hash):
	if file_hash in contents:
		var instance = contents[file_hash].duplicate()
		return instance
	else:
		printerr("content not found %s" % file_hash)
		return null
