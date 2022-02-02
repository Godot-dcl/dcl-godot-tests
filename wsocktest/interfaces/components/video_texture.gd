extends "res://interfaces/component.gd"  #TODO: Extend DCL_Texture when implemented
class_name DCL_VideoTexture


const _classid = 71

var volume := 1.0
var playbackRate := 1.0
var loop := false
var seek := -1.0
var playing := false
var videoClipId: String

var video_player: VideoStreamPlayer

const VIEWPORT_SCENE = preload("res://ui/video_texture/video_texture_placeholder.tscn")
var viewport: SubViewport

var texture: Texture
signal texture_changed(new_texture)


func _init(_name, _scene, _id):
	super(_name, _scene, _id)
	video_player = VideoStreamPlayer.new()
	video_player.connect("finished", Callable(self, "_on_finished"))
	video_player.hide()
	video_player.name = name + str(get_instance_id())
	viewport = VIEWPORT_SCENE.instantiate()
	scene.add_child(viewport)
	scene.add_child(video_player)
	


func update(data):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var json = parser.get_data()
	
	var clip: DCL_VideoClip
	if json.has("videoClipId"):
		videoClipId = json.videoClipId
		clip = scene.components[videoClipId]

		if clip.status == DCL_VideoClip.STATUS_PREPARING:
			texture = _update_viewport("Buffering...")
			emit_signal("texture_changed", texture)

		while clip.status == DCL_VideoClip.STATUS_PREPARING:
			await scene.get_tree().process_frame

		if clip.status == DCL_VideoClip.STATUS_ERRORED:
			texture = _update_viewport("Could not load: \n" + clip.url)
			emit_signal("texture_changed", texture)

		elif clip.status == DCL_VideoClip.STATUS_READY and videoClipId == json.videoClipId:
			texture = _update_viewport("")
			emit_signal("texture_changed", texture)
			pass


	if json.has("playing"):
		playing = json.playing
		if playing:
			video_player.stream = clip.video_clip
			texture = video_player.get_video_texture()
			emit_signal("texture_changed", texture)
			video_player.play()
		else:
			texture = _update_viewport("")
			emit_signal("texture_changed", texture)
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
	else:
		texture = _update_viewport("")
		emit_signal("texture_changed", texture)

func _update_viewport(text : String) -> ViewportTexture:
	viewport.get_node("bg/text").set_text(text)
	return viewport.get_texture()

