extends "res://interfaces/components/shape.gd"
class_name DCL_NFTShape

const _classid = 22
const OPENSEA_API_ENDPOINT = "https://api.opensea.io/api/v1/asset/"

const PictureFrameStyle = NFTPictureFrame.PictureFrameStyle
const PICTURE_FRAME_SCENE = preload("res://ui/nftshape/NFTPictureFrame.tscn")


var src : String
var color := {"r": 0.6404918, "g": 0.611472, "b": 0.8584906 }
var style : int = PictureFrameStyle.Classic

var nft_data : Dictionary
var image := Image.new()
var aspect_ratio := 1.0

var frame : NFTPictureFrame

func _init(_name, _scene, _id).(_name, _scene, _id):
	var plane := QuadMesh.new()
	plane.size = Vector2(1,1)
	mesh_instance.mesh = plane
	mesh_instance.set_surface_material(0, material)

	material.params_cull_mode = SpatialMaterial.CULL_DISABLED
	material.flags_unshaded = true
	material.flags_transparent = true

	frame = PICTURE_FRAME_SCENE.instance()
	mesh_instance.add_child(frame)
	_update_picture_frame()

	name = "NFT Shape"


func update(data):
	.update(data)
	var json = JSON.parse(data).result

	if json.has("color"):
		self.color = json.color
		_update_picture_frame()

	if json.has("style"):
		style = int(json.style)
		_update_picture_frame()

	if json.has("src"):
		src = json.src

		var data_download_error = _get_ntf_data(src)
		# Wait for nft_data
		if data_download_error is GDScriptFunctionState:
			data_download_error = yield(data_download_error,"completed")

		if data_download_error != OK:
			push_error("Error downloading nft_data: %s" % data_download_error)
			return

		if not nft_data.has("image_url"):
			push_error("image_url not found in dictionary: %s" % nft_data)
			return

		var load_result = ContentManager.load_external_contents(nft_data.image_url)
		while load_result is GDScriptFunctionState:
			load_result = yield(load_result, "completed")

		if not load_result is ContentManager.Result:
			return

		if load_result.error != OK:
			push_error("Error %s loading external content: %s" % [load_result.error, load_result.error_text])
			return

		var new_image = load_result.value

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
	var response = yield(http,"request_completed")
	if res != OK:
		printerr("****** error creating the request: ", res)
		return res
	var body : PoolByteArray = response[3] #body
	var data = body.get_string_from_utf8()
	http.queue_free()
	var json : JSONParseResult = JSON.parse(data)
	if json.error != OK:
		return json.error
	if typeof(json.result) == TYPE_DICTIONARY:
		nft_data = json.result
		return json.error
	else:
		return ERR_INVALID_DATA

func attach_to(entity):
	entity.add_child(mesh_instance)

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

