extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


### Shape Creation ###


func test_box_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create cube shape component

	var component_id = "0"

	var comp_mesh_inst = utils.create_component(scene, component_id,
			DCL_BoxShape._classid, component_id).mesh_instance

	assert_not_null(comp_mesh_inst.mesh)
	assert_true(comp_mesh_inst.mesh is BoxMesh, "Box mesh generated")

	# Attach the component to the entity

	utils.attach_component_to_entity(scene, component_id, entity_id)

	assert_eq(entity.get_child_count(), 1)

	var entity_mesh_inst = entity.get_child(0)
	assert_true(entity_mesh_inst is MeshInstance3D, "Mesh attached to the entity")

	assert_not_null(entity_mesh_inst.mesh)
	assert_eq(entity_mesh_inst.mesh, comp_mesh_inst.mesh,
			"Entity's mesh matches the component's")


func test_plane_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create plane shape component

	var component_id = "0"

	var comp_mesh_inst = utils.create_component(scene, component_id,
			DCL_PlaneShape._classid, component_id).mesh_instance

	assert_not_null(comp_mesh_inst.mesh)
	assert_true(comp_mesh_inst.mesh is QuadMesh, "Plane mesh generated")

	var plane_dimensions = {"width": 7.3, "height": 1.56}
	utils.update_component(scene, component_id, JSON.new().stringify(plane_dimensions))

	assert_eq(comp_mesh_inst.mesh.size,
			Vector2(plane_dimensions["width"], plane_dimensions["height"]),
			"Mesh values modified")

	# Attach the component to the entity

	utils.attach_component_to_entity(scene, component_id, entity_id)

	assert_eq(entity.get_child_count(), 1)

	var entity_mesh_inst = entity.get_child(0)
	assert_true(entity_mesh_inst is MeshInstance3D, "Mesh attached to the entity")

	assert_not_null(entity_mesh_inst.mesh)
	assert_eq(entity_mesh_inst.mesh, comp_mesh_inst.mesh,
			"Entity's mesh matches the component's")


func test_sphere_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create sphere shape component

	var component_id = "0"

	var comp_mesh_inst = utils.create_component(scene, component_id,
			DCL_SphereShape._classid, component_id).mesh_instance

	assert_not_null(comp_mesh_inst.mesh)
	assert_true(comp_mesh_inst.mesh is SphereMesh, "Sphere mesh generated")

	# Attach the component to the entity

	utils.attach_component_to_entity(scene, component_id, entity_id)

	assert_eq(entity.get_child_count(), 1)

	var entity_mesh_inst = entity.get_child(0)
	assert_true(entity_mesh_inst is MeshInstance3D, "Mesh attached to the entity")

	assert_not_null(entity_mesh_inst.mesh)
	assert_eq(entity_mesh_inst.mesh, comp_mesh_inst.mesh,
			"Entity's mesh matches the component's")


### Shape Collision ###


func test_single_entity_multi_shape_collision():
	# Create a scene with the entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create and attach 3 shapes to the entity, 2 of them with collision

	var component_id_0 = "0"
	utils.create_component(
			scene, component_id_0, DCL_BoxShape._classid, component_id_0)
	utils.update_component(scene, component_id_0,
			'{"withCollisions": true, "isPointerBlocker": true}')
	utils.attach_component_to_entity(scene, component_id_0, entity_id)

	var component_id_1 = "1"
	utils.create_component(
			scene, component_id_1, DCL_BoxShape._classid, component_id_1)
	utils.attach_component_to_entity(scene, component_id_1, entity_id)

	var component_id_2 = "2"
	utils.create_component(
			scene, component_id_2, DCL_BoxShape._classid, component_id_2)
	utils.update_component(scene, component_id_2,
			'{"withCollisions": true, "isPointerBlocker": true}')
	utils.attach_component_to_entity(scene, component_id_2, entity_id)

	# TODO: Implement the test once a proper character scene is made


func test_multi_entity_single_shape_collision():
	pass # TODO: Implement the test once a proper character scene is made
