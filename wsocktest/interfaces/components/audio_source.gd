extends "res://interfaces/component.gd"
class_name DCL_AudioSource


const _classid = 201

var audio_player := AudioStreamPlayer.new()
var audio_clip: AudioStreamMP3


# Unused in test scene
func _init(_name, _scene, _id).(_name, _scene, _id):
	audio_player.name = name
	print("Component name is", name)


# Unused in test scene
func update(data):
	var json = JSON.parse(data).result
	print("Audio source data: ", json)


# Unused in test scene
func attach_to(entity):
	entity.add_child(audio_player.duplicate())


static func update_component_in_entity(data, entity, scene):
	var player: AudioStreamPlayer
	var json = JSON.parse(data).result
	if json.has("playing"):
		player = entity.get_node_or_null("AudioSource")
		if not player:
			player = AudioStreamPlayer.new()
			player.name = "AudioSource"
			entity.add_child(player)

		if json.playing == false:
			player.stop()
		else:
			player.stream = scene.components[json.audioClipId].audio_clip.duplicate()
			player.stream.loop = json.loop
			player.volume_db = linear2db(json.volume)
			player.pitch_scale = json.pitch
			# What should we do with json.timestamp?
			player.play()
