class_name TestUtils


const FLOAT_ERROR_MARGIN = 0.000001
const ASSETS_DIR = "res://tests/assets/"


# Entity manipulation

func create_entity(scene: Node, id: String) -> Node:
	var msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_createEntity().set_id(id)
	scene.message(msg)

	return scene.entities[id]


func reparent_entity(scene: Node, id: String, parent_id: String):
	var msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_setEntityParent().set_entityId(id)
	msg.get_setEntityParent().set_parentId(parent_id)
	scene.message(msg)


func remove_entity(scene: Node, id: String):
	var msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_removeEntity().set_id(id)
	scene.message(msg)


func update_entity_component(
		scene: Node, entity_id: String, class_id: int, data):
	var msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_updateEntityComponent()
	msg.get_updateEntityComponent().set_entityId(entity_id)
	msg.get_updateEntityComponent().set_classId(class_id)
	msg.get_updateEntityComponent().set_data(data)
	scene.message(msg)


# Component manipulation

func create_component(scene: Node, id: String, class_id: int, name: String):
	var msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_componentCreated().set_id(id)
	msg.get_componentCreated().set_classid(class_id)
	msg.get_componentCreated().set_name(name)
	scene.message(msg)

	return scene.components[id]


func update_component(scene: Node, id: String, json: String):
	var msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_componentUpdated().set_id(id)
	msg.get_componentUpdated().set_json(json)
	scene.message(msg)


func attach_component_to_entity(
		scene: Node, component_id: String, entity_id: String):
	var msg = Server.PROTO.PB_SendSceneMessage.new()
	msg.new_attachEntityComponent().set_id(component_id)
	msg.get_attachEntityComponent().set_entityId(entity_id)
	scene.message(msg)


# Misc

func cache_test_files(payload: Dictionary):
	var dir = Directory.new()
	for i in payload.contents:
		dir.copy(ASSETS_DIR + i.file, "user://" + i.hash)

	ContentManager.load_contents(payload)

	for i in payload.contents:
		if i.has("thread"):
			i.thread.wait_to_finish()
