extends "res://interfaces/component.gd"
class_name DCL_VideoTexture

const _classid = 71

var volume : float = 1
var playbackRate : float = 1
var loop : bool = false
var seek : float = -1
var playing : float = false
var videoClipId : String

var video_player : VideoPlayer
var texture : Texture

func _init(_name, _scene, _id).(_name, _scene, _id):
	video_player = VideoPlayer.new()
	video_player.connect("finished", self, "_on_finished")
	video_player.hide()
	video_player.name = name + str(get_instance_id())

	scene.add_child(video_player)

func update(data):
	var json = JSON.parse(data).result
	if json.has("videoClipId"):
		videoClipId = json.videoClipId
		var clip = scene.components[videoClipId]
		if clip.error:
			texture = _create_error_texture("Could not load: \n" + clip.url, scene)
		else:
			video_player.stream = clip.video_clip
			texture = video_player.get_video_texture()

	if json.has("playing"):
		playing = json.playing
		if playing:
			video_player.play()
		else:
			video_player.stop()

	if json.has("volume"):
		volume = json.volume
		video_player.volume = volume
	
	if json.has("playbackRate"):
		push_warning("VideoTexture.playbackRate not supported in Godot")
	
	if json.has("seek"):
		seek = json.seek
		video_player.stream_position = seek
	
	loop = json.get("loop", loop)


func _on_finished():
	if loop:
		video_player.play()

static func _create_error_texture(text : String, scene) -> Texture:
	var ret : Texture
	var vport_name = "error_texture" + str(text.hash())
	if Server.get_tree().current_scene.has_node(vport_name):
		ret = Server.get_tree().current_scene.get_node(vport_name).get_texture()
	else:
		var font = load("res://fonts/inter/default_text.tres")
		
		var vport = Viewport.new()
		vport.name = vport_name
		vport.size = Vector2(640,480)
		vport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		vport.render_target_v_flip = true
		
		scene.add_child(vport)
		
		var label = Label.new()
		vport.add_child(label)
		
		label.add_font_override("font", font)
		label.rect_min_size = vport.size
		label.autowrap = true
		label.align = Label.ALIGN_CENTER
		label.valign = Label.VALIGN_CENTER
		label.text = text
		ret = vport.get_texture()
	
	return ret
