extends "res://addons/gut/test.gd"


func test_entity_creation():
	# Create a scene with the first entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var msg = Server.PROTO.PB_SendSceneMessage.new()

	var entity_id = "1"
	msg.new_createEntity().set_id(entity_id)
	scene.message(msg)

	var entity = scene.entities[entity_id]

	assert_not_null(scene)
	assert_eq(entity_id, entity.name)

	# Create the second entity

	entity_id = "2"
	msg.get_createEntity().set_id(entity_id)
	scene.message(msg)

	entity = scene.entities[entity_id]

	assert_not_null(scene)
	assert_eq(entity_id, entity.name)


func test_entity_parenting():
	var entity_id = "2"
	var parent_entity_id = "3"

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var msg = Server.PROTO.PB_SendSceneMessage.new()

	msg.new_createEntity().set_id(entity_id)
	scene.message(msg)

	msg.get_createEntity().set_id(parent_entity_id)
	scene.message(msg)

	assert_true(scene.entities[entity_id].get_parent() == scene,
			"Parent is set to the scene root")

	var parent_entity = scene.entities[parent_entity_id]

	msg = Server.PROTO.PB_SendSceneMessage.new()

	msg.new_setEntityParent().set_entityId(entity_id)
	msg.get_setEntityParent().set_parentId(parent_entity_id)
	scene.message(msg)

	assert_true(scene.entities[entity_id].get_parent() == parent_entity,
			"Parent is set to parent_entity")

	msg.get_setEntityParent().set_entityId(entity_id)
	msg.get_setEntityParent().set_parentId("0")
	scene.message(msg)

	assert_true(scene.entities[entity_id].get_parent() == scene,
			"Parent is set back to the scene root")


func test_entity_removal():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	assert_not_null(scene)

	var entity_id = "2"
	var msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_createEntity().set_id(entity_id)
	scene.message(msg)

	assert_true(scene.entities.has(entity_id))

	# Remove the entity

	var entity = scene.entities[entity_id]

	msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_removeEntity().set_id(entity_id)

	await get_tree().process_frame

	assert_false(scene.entities.has(entity_id),
			"Entity was removed from the list of entities")
	assert_null(entity, "Entity has been freed")
