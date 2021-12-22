extends "res://interfaces/components/shape.gd"
class_name DCL_NFTShape

const _classid = 22
const OPENSEA_API_ENDPOINT = "https://api.opensea.io/api/v1/asset/"

var src : String
var color := Color(0.6404918, 0.611472, 0.8584906)
var style := 0

var nft_data : Dictionary

func _init(_name, _scene, _id).(_name, _scene, _id):
	var plane = QuadMesh.new()
	plane.size = Vector2(1,1)
	mesh_instance.mesh = plane
	mesh_instance.set_surface_material(0, material)
	
	material.params_cull_mode = SpatialMaterial.CULL_DISABLED
	material.flags_transparent = true
	
	#material.albedo_color = color  # Do not use for now or it'll tint the texture
	name = "NFT Shape"
	pass
	
func update(data):
	.update(data)
	var json = JSON.parse(data).result
	if json.has("src"):
		src = json.src
		var data_download = _get_ntf_data(src)
		if data_download is GDScriptFunctionState:
				nft_data = yield(data_download,"completed")
		var filename = nft_data.image_url.sha1_text() + "_" + Array((nft_data.image_original_url as String).split("/")).pop_back()

		var texture_download = _get_external_image(nft_data.image_url, filename)
		if texture_download is GDScriptFunctionState:
			yield(texture_download, "completed")
		var image = ContentManager.get_instance(filename)
		var tex = ImageTexture.new()
		tex.create_from_image(image)
		material.albedo_texture = tex


func _get_ntf_data(url: String) -> Dictionary:
	if not url.begins_with("ethereum://"):
		printerr("malformed url")
	var http = HTTPRequest.new()
	http.use_threads = false 
	scene.add_child(http)
	
	var res = http.request(OPENSEA_API_ENDPOINT + url.trim_prefix("ethereum://"))
	var response = yield(http,"request_completed")
	if res != OK:
		printerr("****** error creating the request: ", res)
		return
	var body : PoolByteArray = response[3] #body
	var data = body.get_string_from_utf8()
	http.queue_free()
	return JSON.parse(data).result


func _get_external_image(url: String, filename: String):
	# Get ETag and Last-Modified headers
	var http = HTTPRequest.new()
	http.use_threads = false 
	scene.add_child(http)
	
	var content = {"file": filename, "hash" : url.sha1_text() }
	if ContentManager.file_downloaded(content):
		ContentManager.cache_file(content)
		return
	
	# Fetch the file
	var fetch_res = http.request(url)
	var fetch_response = yield(http,"request_completed")
	if fetch_res != OK:
		printerr("****** error creating the request: ", fetch_res)
		return

	fetch_response.append(content)
	ContentManager.callv("download_png", fetch_response)
	http.queue_free()
