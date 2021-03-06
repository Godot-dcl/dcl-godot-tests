extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_video_components():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	utils.create_entity(scene, entity_id)

	# Cache a WebM audio file

	var payload = {
		"contents": [{
			"file": "video.webm",
			"hash": "test_webm.webm",
		}],
		"baseUrl": "",
	}
	utils.cache_test_files(payload)

	var content_inst = ContentManager.get_instance(payload.contents[0].file)
	assert_not_null(content_inst)
	assert_is(content_inst, VideoStreamWebm, "WebM file cached")

	# Create and update a video clip component

	var clip_comp_id = "0"
	var clip_comp = utils.create_component(
			scene, clip_comp_id, DCL_VideoClip._classid, clip_comp_id)

	utils.update_component(
			scene, clip_comp_id, '{"url": "' + payload.contents[0].file + '"}')
	assert_eq(content_inst, clip_comp.video_clip)

	# Create and add a video texture component to the scene

	var texture_comp_id = "1"
	var texture_comp = utils.create_component(
			scene, texture_comp_id, DCL_VideoTexture._classid, texture_comp_id)

	assert_eq(scene, texture_comp.video_player.get_parent(),
			"VideoPlayer attached to scene")

	var data = {
		"videoClipId": clip_comp_id,
		"playing": true,
		"volume": 0.63,
		#"playbackRate", # Not supported
		#"seek", # Not supported
		"loop": true,
	}
	utils.update_component(scene, texture_comp_id, to_json(data))

	assert_eq(texture_comp.video_player.stream, clip_comp.video_clip)
	assert_eq(texture_comp.video_player.is_playing(), data.playing)
	assert_almost_eq(texture_comp.video_player.volume, data.volume,
			utils.FLOAT_ERROR_MARGIN)
	assert_eq(texture_comp.loop, data.loop)

	# Attach the video texture to a material component

	var material_comp_id = "2"
	var material_comp = utils.create_component(scene, material_comp_id,
			DCL_Material._classid, material_comp_id)

	utils.update_component(scene, material_comp_id, '{"albedoTexture": "' +
			texture_comp_id + '", "emissiveTexture": "' + texture_comp_id + '"}')
	assert_eq(material_comp.material.albedo_texture, texture_comp.texture)
	assert_eq(material_comp.material.emission_texture, texture_comp.texture)
