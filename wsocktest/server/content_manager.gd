@tool
extends Node


var contents : Dictionary
var available_extensions = ["gltf", "glb", "bin", "png", "mp3", "ogg", "ogv", "webm"]


func load_contents(payload):
	for i in range(payload.contents.size()):
		var content = payload.contents[i]
		if not contents.has(content.file.to_lower()) and \
			content.file.get_extension() in available_extensions:

			content.thread = Thread.new()
			content.hash = content.hash.trim_suffix("." + content.file.get_extension())
			content.base_url = payload.baseUrl

			contents[content.file.to_lower()] = content

			var ext = content.file.get_extension()
			var file_name : String
			match ext:
				"glb", "gltf", "mp3", "ogv", "ogg", "webm":
					file_name = "user://%s.%s" % [content.hash, ext]
				"png", "bin":
					file_name = "user://%s" % content.file.get_file()
				_:
					push_warning("**** undefined extension")

			var f = File.new()
			if f.file_exists(file_name):
				content.thread.start(Callable(self, "cache_file"), content)
			else:
				content.thread.start(Callable(self, "download_file"), content)


func load_external_contents(url):
	var file_name = url.right(url.rfind("/") + 1).to_lower() + ".png"
	if not contents.has(file_name.to_lower()) and file_name.get_extension() in available_extensions:
			contents[file_name] = {
				"file": file_name,
				"thread" : Thread.new(),
				"url": url
			}

			var f = File.new()
			if f.file_exists("user://%s" % file_name):
				contents[file_name].thread.start(Callable(self, "cache_file"), contents[file_name])
			else:
				contents[file_name].thread.start(Callable(self, "download_external_file"), contents[file_name])


func download_external_file(info):
	var http = HTTPRequest.new()
	http.use_threads = true
	add_child(http)

	if http.request(info.url) != OK:
		http.queue_free()
		printerr("**** error creating the download request for ", info.file)
		return null

	var result = await http.request_completed
	result.push_back(info)
	callv("downloaded_" + info.file.get_extension(), result)
	http.queue_free()

	return cache_file(info)


func download_file(info):
	var http = HTTPRequest.new()
	http.use_threads = true
	add_child(http)

	if http.request(info.base_url + info.hash) != OK:
		http.queue_free()
		printerr("**** error creating the download request for ", info.file)
		return null

	var result = await http.request_completed
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
		# Accept image files with the wrong extention but always save as png
		for ext in ["png", "jpg", "webp"]:
			if image.call("load_" + ext + "_from_buffer",body) == OK:
				var file_name = "user://%s" % content.file.get_file()
				image.save_png(file_name)
				break


func downloaded_bin(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s" % content.file.get_file()
		if f.open(file_name, File.WRITE) == OK:
			f.store_buffer(body)
			f.close()


func cache_file(content):
	var f = content.file.to_lower()
	if not "asset" in contents[f]:
		var ext = content.file.get_extension()
		match ext:
			"glb", "gltf":
				var state = GLTFState.new()
				var gltf := GLTFDocument.new()
				gltf.append_from_file("user://%s.%s" % [content.hash, ext], state)

				var asset = gltf.generate_scene(state)
				for i in asset.get_children():
					if i is ImporterMeshInstance3D:
						var converted_node = MeshInstance3D.new()
						converted_node.name = i.name
						converted_node.mesh = i.mesh.get_mesh()
						converted_node.skeleton = i.skeleton_path
						converted_node.skin = i.skin
						converted_node.transform = i.transform

						i.free()
						asset.add_child(converted_node)

				contents[f].asset = asset

			"mp3":
				var s := AudioStreamMP3.new()
				var file = File.new()
				file.open("user://%s.%s" % [content.hash, ext], File.READ)
				s.data = file.get_buffer(file.get_length())
				file.close()
				contents[f].asset = s

			"ogv", "ogg":  #TODO: handle ogg being an audio file
				var v := VideoStreamTheora.new()
				v.set_file("user://%s.%s" % [content.hash, ext])
				contents[f].asset = v

			"webm":
				#var v := VideoStreamWebm.new()
				# did this because VideoStreamWebm doesn't seem to be there
				var v := VideoStreamTheora.new()
				v.set_file("user://%s.%s" % [content.hash, ext])
				contents[f].asset = v

			"png":
				var i = Image.new()
				i.load("user://%s" % content.file.get_file())
				contents[f].asset = i

			"bin":
				pass

			_:
				printerr("Content Manager: Unknown file type for caching " + ext + " - " + str(content))


func get_instance(file_hash):
	var f = file_hash.to_lower()
	if contents.has(f):
		if contents[f].thread.is_started():
			contents[f].thread.wait_to_finish()

		if contents[f].has("asset"):
			return contents[f].asset

	printerr("Content Manager: Asset not found " + f)
