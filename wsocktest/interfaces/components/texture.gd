extends "res://interfaces/component.gd"
class_name DCL_Texture

const _classid = 68

var has_alpha: bool = true
var sampling_mode : int  # 0 : NEAREST, 1: BILINEAR, 2: TRILINEAR
var src : String
var wrap : int # 0 : CLAMP, 1 : WRAP, 2: MIRROR

var texture: Texture

func update(data):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var json = parser.get_data()

	var clip: DCL_VideoClip
	if json.has("src"):
		src = json.src
		var img : Image = ContentManager.get_instance(json.src).duplicate()
		var tex = ImageTexture.new()
		
		if json.has("samplingMode"):
			sampling_mode = json.samplingMode
			printerr("*** Texture.sampling_mode unimplemented")
		
		if json.has("wrap"):
			wrap = json.wrap
			printerr("*** Texture.wrap unimplemented")
			
		if json.has("hasAlpha"):
			has_alpha = json.hasAlpha
			printerr("*** Texture.has_alpha unimplemented")
			
		tex.create_from_image(img)
		texture = tex
