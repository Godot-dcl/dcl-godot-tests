extends "res://interfaces/components/shape.gd"
class_name DCL_NFTShape

const _classid = 22
const OPENSEA_API_ENDPOINT = "https://api.opensea.io/api/v1/asset/"

var src : String
var color := Color(0.6404918, 0.611472, 0.8584906)
var style := 0

var nft_data : Dictionary
var image := Image.new()

func _init(_name, _scene, _id):
	super(_name, _scene, _id)

	var plane = QuadMesh.new()
	plane.size = Vector2(1,1)
	mesh_instance.mesh = plane
	mesh_instance.mesh.surface_set_material(0, material)

	material.params_cull_mode = StandardMaterial3D.CULL_DISABLED
	material.flags_transparent = true

	#material.albedo_color = color  # Do not use for now or it'll tint the texture
	name = "NFT Shape"
	pass

func update(data):
	super.update(data)
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		# handle error
		return
	var json = parser.get_data()
	if json.has("src"):
		src = json.src

		var data_download_error = await _get_ntf_data(src)
		# Wait for nft_data
		#if data_download_error is GDScriptFunctionState:
		#	data_download_error = await data_download_error.completed

		if data_download_error != OK:
			push_error("Error downloading nft_data: %s" % data_download_error)
			return

		if not nft_data.has("image_url"):
			push_error("image_url not found in dictionary: %s" % nft_data)
			return

		var filename = nft_data.image_url.right(nft_data.image_url.rfind("/") + 1).to_lower()
		ContentManager.load_external_contents(nft_data.image_url)
		var new_image = ContentManager.get_instance(filename + ".png")

		# No need to recreate the texture if the image doesn't change
		if image != new_image:
			image = new_image
			var tex = ImageTexture.new()
			tex.create_from_image(image)
			material.albedo_texture = tex


func _get_ntf_data(url: String) -> int:
	if not url.begins_with("ethereum://"):
		printerr("malformed url")
		return ERR_FILE_BAD_PATH

	var http = HTTPRequest.new()
	scene.add_child(http)

	var res = http.request(OPENSEA_API_ENDPOINT + url.trim_prefix("ethereum://"))
	var response = await http.request_completed

	if res != OK:
		printerr("****** error creating the request: ", res)
		return res
	var body : PackedByteArray = response[3] #body
	var data = body.get_string_from_utf8()
	http.queue_free()
	
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return ERR_INVALID_DATA

	var data_dict = parser.get_data()
	if typeof(data_dict) == TYPE_DICTIONARY:
		nft_data = data_dict
		return OK
	else:
		return ERR_INVALID_DATA


func _get_external_image(url: String, filename: String) -> int:
	var content = {"file": filename, "hash" : url.sha1_text() }
	if ContentManager.contents.has(filename):
		ContentManager.cache_file(content)
		return OK

	var http = HTTPRequest.new()
	scene.add_child(http)
	var res = http.request(url)
	var response = await http.request_completed
	if res != OK:
		printerr("****** error creating the request: ", res)
		return res

	response.append(content)
	ContentManager.callv("downloaded_png", response)
	ContentManager.cache_file(content)
	http.queue_free()
	return OK
