extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_shape_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create all basic shape components

	var basic_shapes = {
		DCL_BoxShape._classid: CubeMesh,
		DCL_SphereShape._classid: SphereMesh
	}

	var component_id = 0
	for i in basic_shapes.keys():
		var comp_mesh_inst = utils.create_component(scene, str(component_id),
				i, str(component_id)).mesh_instance

		assert_not_null(comp_mesh_inst.mesh)
		assert_true(comp_mesh_inst.mesh is basic_shapes[i],
				comp_mesh_inst.mesh.get_class() + " mesh generated")

		# Attach the component to the entity

		utils.attach_component_to_entity(
				scene, str(component_id), entity_id)

		assert_eq(entity.get_child_count(), component_id + 1)

		var entity_mesh_inst = entity.get_child(component_id)
		assert_true(entity_mesh_inst is MeshInstance,
				"'MeshInstance' attached to the entity")

		assert_not_null(entity_mesh_inst.mesh)
		assert_eq(entity_mesh_inst.mesh, comp_mesh_inst.mesh,
				"Entity's mesh matches the component's")

		component_id += 1


func test_single_entity_multi_shape_collision():
	# Create a scene with the entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create and attach 3 shapes to the entity, 2 of them with collision

	var component_id_0 = "0"
	utils.create_component(
			scene, component_id_0, DCL_BoxShape._classid, component_id_0)
	utils.update_component(scene, component_id_0,
			"{\"withCollisions\": true, \"isPointerBlocker\": true}")
	utils.attach_component_to_entity(scene, component_id_0, entity_id)

	var component_id_1 = "1"
	utils.create_component(
			scene, component_id_1, DCL_BoxShape._classid, component_id_1)
	utils.attach_component_to_entity(scene, component_id_1, entity_id)

	var component_id_2 = "2"
	utils.create_component(
			scene, component_id_2, DCL_BoxShape._classid, component_id_2)
	utils.update_component(scene, component_id_2,
			"{\"withCollisions\": true, \"isPointerBlocker\": true}")
	utils.attach_component_to_entity(scene, component_id_2, entity_id)

	# TODO: Implement the test once a proper character scene is made


func test_multi_entity_single_shape_collision():
	pass # TODO: Implement the test once a proper character scene is made
