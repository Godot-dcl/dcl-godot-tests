extends "res://interfaces/components/shape.gd"
class_name DCL_NFTShape

const _classid = 22
const OPENSEA_API_ENDPOINT = "https://api.opensea.io/api/v1/asset/"

var PictureFrameStyle = NFTPictureFrame.PictureFrameStyle
const PICTURE_FRAME_SCENE = preload("res://ui/nftshape/NFTPictureFrame.tscn")

var src : String
var color := {"r": 0.6404918, "g": 0.611472, "b": 0.8584906 }
var style : int = PictureFrameStyle.Classic

var nft_data : Dictionary
var image := Image.new()
var aspect_ratio := 1.0

var frame : NFTPictureFrame

func _init(_name, _scene, _id):
	super(_name, _scene, _id)

	var plane = QuadMesh.new()
	plane.size = Vector2(1,1)
	mesh_instance.mesh = plane
	mesh_instance.set_surface_override_material(0, material)

	material.params_cull_mode = StandardMaterial3D.CULL_DISABLED
	material.flags_unshaded = true
	material.flags_transparent = true

	frame = PICTURE_FRAME_SCENE.instantiate()
	mesh_instance.add_child(frame)
	_update_picture_frame()

	name = "NFT Shape"


func update(data):
	super.update(data)
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		# handle error
		return
	var json = parser.get_data()

	if json.has("color"):
		self.color = json.color
		_update_picture_frame()

	if json.has("style"):
		var _style = json.style
		if _style is String:
			style = PictureFrameStyle.keys().find(_style)
		else:
			style = int(_style)
		_update_picture_frame()

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
		if new_image != null and image != new_image:
			image = new_image
			var image_size = new_image.get_size()
			if image_size.y != 0:
				aspect_ratio = image_size.x / float(image_size.y)
			var tex = ImageTexture.new()
			tex.create_from_image(image)
			material.albedo_texture = tex
			_update_picture_frame()


func _get_ntf_data(url: String) -> int:
	if not url.begins_with("ethereum://"):
		printerr("malformed url")
		return ERR_FILE_BAD_PATH

	var http = HTTPRequest.new()
	scene.add_child(http)

	var res = http.request(OPENSEA_API_ENDPOINT + url.trim_prefix("ethereum://"), ["user-agent: Mozilla/5.0 (platform; rv:geckoversion) Gecko/geckotrail Firefox/firefoxversion"])
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


func attach_to(entity):
	entity.add_child(mesh_instance)

	super.attach_to(entity)


func detach_from(entity):
	entity.remove_child(mesh_instance)

	super.detach_from(entity)


func _update_picture_frame():
	var new_size : Vector2
	if aspect_ratio >= 1:
		new_size = Vector2(aspect_ratio, 1.0)
	else:
		new_size = Vector2(1.0, 1.0 / aspect_ratio)
	new_size *= 0.5 #I think the base size for the nft image is 0.5x0.5
	mesh_instance.mesh.size = new_size
	frame.color = Color(color.r, color.g, color.b)
	frame.set_style(style, new_size)


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
