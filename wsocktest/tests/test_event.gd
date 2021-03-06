extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_uuid_callback_component():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create and attach a UUID callback component to the entity

	var component_id = "0"
	utils.create_component(
			scene, component_id, DCL_UUIDCallback._classid, component_id)
	utils.attach_component_to_entity(scene, component_id, entity_id)

	var data = {
		"uuid": "test",
		"type": "DOWN",
		"button": "POINTER",
		"hoverText": "something",
		"distance": 10,
		"showFeedback": true,
	}

	utils.update_entity_component(
			scene, entity_id, DCL_UUIDCallback._classid, to_json(data))

	assert_true(scene.has_meta("events"))

	var event = scene.get_meta("events")[0]

	assert_is(event, Event, "Event attached to scene")

	assert_eq(event.scene_id, scene.id)
	assert_eq(event.entity, entity)
	assert_eq(event.uuid, data.uuid)
	assert_eq(event.type, data.type)
	assert_eq(event.action, Event.Action.POINTER)
	assert_eq(event.text, data.hoverText)
	assert_eq(event.distance, data.distance)
	assert_eq(event.show_feedback, data.showFeedback)
