extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_gltf_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Cache a GLTF file containing 3 shapes

	var content = {
		"file": "shapes.gltf",
		"hash": "test_gltf",
	}

	var dir = Directory.new()
	dir.copy(utils.ASSETS_DIR + "shapes.gltf", "user://" + content.hash + ".gltf")

	ContentManager.cache_file(content)

	var content_inst = ContentManager.get_instance(content.file)
	assert_not_null(content_inst, "GLTF file cached")
	assert_eq(content_inst.get_child_count(), 3)

	# Create and attach a GLTF shape component to the entity

	var component_id = "0"
	var component = utils.create_component(scene, component_id,
			DCL_GLTFShape._classid, component_id)

	utils.update_component(
			scene, component_id, '{"src": "' + content.file + '"}')

	utils.attach_component_to_entity(scene, component_id, entity_id)
	assert_eq(entity.get_child_count(), 3)

	var index = 0
	for i in entity.get_children():
		assert_true(i is MeshInstance)
		assert_eq(i.mesh, content_inst.get_child(index).mesh)
		assert_not_null(i.mesh)

		index += 1

	content_inst.queue_free()


func test_glb_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Cache a GLB file containing 3 shapes

	var content = {
		"file": "shapes.glb",
		"hash": "test_glb",
	}

	var dir = Directory.new()
	dir.copy(utils.ASSETS_DIR + "shapes.glb", "user://" + content.hash + ".glb")

	ContentManager.cache_file(content)

	var content_inst = ContentManager.get_instance(content.file)
	assert_not_null(content_inst, "GLB file cached")
	assert_eq(content_inst.get_child_count(), 3)

	# Create and attach a GLTF shape component to the entity

	var component_id = "0"
	var component = utils.create_component(scene, component_id,
			DCL_GLTFShape._classid, component_id)

	utils.update_component(
			scene, component_id, '{"src": "' + content.file + '"}')

	utils.attach_component_to_entity(scene, component_id, entity_id)
	assert_eq(entity.get_child_count(), 3)

	var index = 0
	for i in entity.get_children():
		assert_true(i is MeshInstance)
		assert_eq(i.mesh, content_inst.get_child(index).mesh)
		assert_not_null(i.mesh)

		index += 1

	content_inst.queue_free()
