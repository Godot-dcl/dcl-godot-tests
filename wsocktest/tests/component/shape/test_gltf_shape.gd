extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_gltf_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Cache a GLTF file containing 3 shapes

	var payload = {
		"contents": [{
			"file": "shapes.gltf",
			"hash": "test_gltf.gltf",
		}],
		"baseUrl": "",
	}
	utils.cache_test_files(payload)

	var content_inst = ContentManager.get_instance(payload.contents[0].file)
	assert_not_null(content_inst, "GLTF file cached")
	assert_eq(content_inst.get_child_count(), 3)

	# Create and attach a GLTF shape component to the entity

	var component_id = "0"
	utils.create_component(scene, component_id, DCL_GLTFShape._classid, component_id)

	utils.update_component(
			scene, component_id, '{"src": "' + payload.contents[0].file + '"}')

	utils.attach_component_to_entity(scene, component_id, entity_id)
	assert_eq(entity.get_child_count(), 3)

	var index = 0
	for i in entity.get_children():
		assert_is(i, MeshInstance3D)
		assert_eq(i.mesh, content_inst.get_child(index).mesh)
		assert_not_null(i.mesh)

		index += 1

	content_inst.queue_free()


func test_glb_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Cache a GLB file containing 3 shapes

	var payload = {
		"contents": [{
			"file": "shapes.glb",
			"hash": "test_glb.glb",
		}],
		"baseUrl": "",
	}
	utils.cache_test_files(payload)

	var content_inst = ContentManager.get_instance(payload.contents[0].file)
	assert_not_null(content_inst, "GLB file cached")
	assert_eq(content_inst.get_child_count(), 3)

	# Create and attach a GLTF shape component to the entity

	var component_id = "0"
	utils.create_component(scene, component_id, DCL_GLTFShape._classid, component_id)

	utils.update_component(
			scene, component_id, '{"src": "' + payload.contents[0].file + '"}')

	utils.attach_component_to_entity(scene, component_id, entity_id)
	assert_eq(entity.get_child_count(), 3)

	var index = 0
	for i in entity.get_children():
		assert_true(i is MeshInstance3D)
		assert_eq(i.mesh, content_inst.get_child(index).mesh)
		assert_not_null(i.mesh)

		index += 1

	content_inst.queue_free()
