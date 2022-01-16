tool
extends Node


var contents : Dictionary
var available_extensions = ["gltf", "glb", "bin", "png", "mp3", "ogg", "ogv", "webm"]

class Result:
	var error : int = ERR_BUG
	var error_text : String = "Unknown error"
	var value = null


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
					file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
				_:
					push_warning("*** undefined extension")

			var f = File.new()
			if f.file_exists(file_name):
				content.thread.start(self, "cache_file", content)
			else:
				content.thread.start(self, "download_file", content)


func load_external_contents(url):
	var ret = Result.new()
	var file_name = url.right(url.rfind("/") + 1).to_lower() + ".png"
	
	if contents.has(file_name.to_lower()):
		ret.value = get_instance(file_name)
		ret.error = OK
		ret.error_text = "Sucess"
		return ret
	
	if file_name.get_extension() in available_extensions:
		contents[file_name] = {
			"file": file_name,
			"thread" : Thread.new(),
			"url": url
		}

		var f = File.new()
		if f.file_exists("user://%s" % file_name):
			contents[file_name].thread.start(self, "cache_file", contents[file_name])
		else:
			contents[file_name].thread.start(self, "download_external_file", contents[file_name])
			
		# Avoid blocking the main thread
		while contents[file_name].thread.is_alive():
			yield(get_tree(),"idle_frame")
		return contents[file_name].thread.wait_to_finish()
		
	return ret


func download_external_file(info) -> Result:
	var ret = Result.new()
	var http = HTTPRequest.new()
	http.use_threads = true
	add_child(http)
	var request_error = http.request(info.url)
	if request_error != OK:
		http.queue_free()
		ret.error = request_error
		ret.error_text = "*** error creating the download request for " + str(info.file)
		printerr(ret.error_text)
		return ret

	var result = yield(http, "request_completed")
	result.push_back(info)
	callv("downloaded_" + info.file.get_extension(), result)
	http.queue_free()

	return cache_file(info)


func download_file(info) -> Result:
	var ret = Result.new()
	var http = HTTPRequest.new()
	http.use_threads = true
	add_child(http)

	var request_error = http.request(info.base_url + info.hash)
	if request_error != OK:
		http.queue_free()
		ret.error = request_error
		ret.error_text = "*** error creating the download request for " + str(info.file)
		printerr(ret.error_text)
		return ret

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
		# Accept image files with the wrong extention but always save as png
		for ext in ["png", "jpg", "webp"]:
			if image.call("load_" + ext + "_from_buffer",body) == OK:
				var file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
				image.save_png(file_name)
				break


func downloaded_bin(_result, response_code, _headers, body, content):
	if response_code >= 200 and response_code < 300:
		var f = File.new()
		var file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
		if f.open(file_name, File.WRITE) == OK:
			f.store_buffer(body)
			f.close()


func cache_file(content) -> Result:
	var ret = Result.new()
	var f = content.file.to_lower()
	if "asset" in contents[f]:
		ret.error = OK
		ret.error_text = "Sucess"
		ret.value = contents[f].asset
	else:
		var ext = content.file.get_extension()
		match ext:
			"glb", "gltf":
				var l = DynamicGLTFLoader.new()
				contents[f].asset = l.import_scene("user://%s.%s" % [content.hash, ext], 1, 1)
				ret.value = contents[f].asset
				ret.error = OK
				ret.error_text = "Sucess"
				
			"mp3":
				var s := AudioStreamMP3.new()
				var file = File.new()
				file.open("user://%s.%s" % [content.hash, ext], File.READ)
				s.data = file.get_buffer(file.get_len())
				file.close()
				contents[f].asset = s
				ret.value = contents[f].asset
				ret.error = OK
				ret.error_text = "Sucess"

			"ogv", "ogg":  #TODO: handle ogg being an audio file
				var v := VideoStreamTheora.new()
				v.set_file("user://%s.%s" % [content.hash, ext])
				contents[f].asset = v
				ret.value = contents[f].asset
				ret.error = OK
				ret.error_text = "Sucess"

			"webm":
				var v := VideoStreamWebm.new()
				v.set_file("user://%s.%s" % [content.hash, ext])
				contents[f].asset = v
				ret.value = contents[f].asset
				ret.error = OK
				ret.error_text = "Sucess"

			"png":
				var i = Image.new()
				i.load("user://%s" % content.file.right(content.file.rfind("/") + 1))
				contents[f].asset = i
				ret.value = contents[f].asset
				ret.error = OK
				ret.error_text = "Sucess"

			# dont cache this
			"bin":
				ret.error = ERR_FILE_UNRECOGNIZED
				ret.error_text = ".bin files don't get cached"

			_:
				ret.error_text = "Content Manager: Unknown file type for caching " + ext + " - " + str(content)
				ret.error = ERR_FILE_UNRECOGNIZED
				printerr(ret.error_text)
	
	return ret


func get_instance(file_hash):
	var f = file_hash.to_lower()
	if contents.has(f):
		if contents[f].thread.is_active():
			contents[f].thread.wait_to_finish()

		if contents[f].has("asset"):
			return contents[f].asset

	printerr("Content Manager: Asset not found " + f)
