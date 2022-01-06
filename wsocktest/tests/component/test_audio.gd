extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_audio_source_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Cache an audio file

	var payload = {
		"contents": [{
			"file": "audio.mp3",
			"hash": "test_mp3.mp3",
		}],
		"baseUrl": "",
	}
	utils.cache_test_files(payload)

	# Create and attach an audio clip component to the entity

	var clip_comp_id = "0"
	utils.create_component(
			scene, clip_comp_id, DCL_AudioClip._classid, clip_comp_id)
	utils.update_component(
			scene, clip_comp_id, '{"url": "' + payload.contents[0].file + '"}')
	utils.attach_component_to_entity(scene, clip_comp_id, entity_id)

	# Create an audio source component

	var src_comp_id = "1"
	var component = utils.create_component(
			scene, src_comp_id, DCL_AudioSource._classid, src_comp_id)

	# Update and attach the audio source component to the entity

	var data = {
		"playing": true,
		"audioClipId": clip_comp_id,
		"loop": true,
		"volume": 0.4,
		"pitch": 0.75,
	}
	utils.update_entity_component(
			scene, entity_id, DCL_AudioSource._classid, to_json(data))
	assert_eq(entity.get_child_count(), 1)

	var entity_audio_src = entity.get_node("AudioSource")
	assert_is(entity_audio_src, AudioStreamPlayer)

	assert_not_null(entity_audio_src.stream)
	assert_eq(entity_audio_src.playing, data.playing)
	assert_eq(entity_audio_src.stream.loop, data.loop)
	assert_almost_eq(entity_audio_src.volume_db, linear2db(data.volume),
			utils.FLOAT_ERROR_MARGIN)
	assert_almost_eq(
			entity_audio_src.pitch_scale, data.pitch, utils.FLOAT_ERROR_MARGIN)

	component.audio_player.queue_free()


func test_audio_clip_mp3_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	utils.create_entity(scene, entity_id)

	# Cache a MP3 audio file

	var payload = {
		"contents": [{
			"file": "audio.mp3",
			"hash": "test_mp3.mp3",
		}],
		"baseUrl": "",
	}
	utils.cache_test_files(payload)

	var content_inst = ContentManager.get_instance(payload.contents[0].file)
	assert_not_null(content_inst)
	assert_is(content_inst, AudioStreamMP3, "MP3 file cached")

	# Create and update an audio clip component

	var component_id = "0"
	var component = utils.create_component(
			scene, component_id, DCL_AudioClip._classid, component_id)

	var data = {
		"url": payload.contents[0].file,
		"volume": 0.5,
		"loop": true,
	}
	utils.update_component(scene, component_id, to_json(data))
	assert_eq(content_inst, component.audio_clip)
	assert_eq(component.volume, data.volume)
	assert_eq(component.audio_clip.loop, data.loop)
