extends "res://interfaces/component.gd"
class_name DCL_AudioClip


const _classid = 200

var audio_clip: AudioStreamMP3
var volume := 1.0


func _init(_name, _scene, _id).(_name, _scene, _id):
	audio_clip = AudioStreamMP3.new()


func update(data):
	var json = JSON.parse(data).result
	if json.has("url"):
		audio_clip = ContentManager.get_instance(json.url)
	if json.has("volume"):
		volume = json.volume
	if json.has("loop"):
		audio_clip.loop = json.loop
