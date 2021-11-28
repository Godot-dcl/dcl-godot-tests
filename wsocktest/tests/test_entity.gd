extends "res://addons/gut/test.gd"


const Scene = preload("res://scene/scene.tscn")


func test_entity_creation():
	# Create the first entity

	var scene = autoqfree(Scene.instance())

	var msg = scene.PROTO.PB_SendSceneMessage.new()

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

	var scene = autoqfree(Scene.instance())
	add_child(scene)

	var msg = scene.PROTO.PB_SendSceneMessage.new()

	msg.new_createEntity().set_id(entity_id)
	scene.message(msg)

	msg.get_createEntity().set_id(parent_entity_id)
	scene.message(msg)

	assert_true(scene.entities[entity_id].get_parent() == scene,
			"parent is set to the scene root")

	var parent_entity = scene.entities[parent_entity_id]

	msg = scene.PROTO.PB_SendSceneMessage.new()

	msg.new_setEntityParent().set_entityId(entity_id)
	msg.get_setEntityParent().set_parentId(parent_entity_id)
	scene.message(msg)

	assert_true(scene.entities[entity_id].get_parent() == parent_entity,
			"parent is set to parent_entity")

	msg.get_setEntityParent().set_entityId(entity_id)
	msg.get_setEntityParent().set_parentId("0")
	scene.message(msg)

	assert_true(scene.entities[entity_id].get_parent() == scene,
			"parent is set back to the scene root")


func test_entity_removal():
	var scene = autoqfree(Scene.instance())
	assert_not_null(scene)

	var msg = scene.PROTO.PB_SendSceneMessage.new()

	var entity_id = "2"
	msg.new_createEntity().set_id(entity_id)
	scene.message(msg)

	assert_true(scene.entities.has(entity_id))

	var entity = scene.entities[entity_id]

	msg = scene.PROTO.PB_SendSceneMessage.new()
	msg.new_removeEntity().set_id(entity_id)

	yield(get_tree(), "idle_frame")

	assert_false(scene.entities.has(entity_id))
	assert_null(entity, "Entity has been freed")
