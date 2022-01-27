extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_text_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instantiate())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create and attach a text shape component to the entity

	var component_id = "0"
	utils.create_component(
			scene, component_id, DCL_TextShape._classid, component_id)
	utils.attach_component_to_entity(scene, component_id, entity_id)

	var label_dict = {
		"value": "Test",
		"color": {"r": 1, "g": 0.5, "b": 0.25},
		"outlineWidth": 3,
		"outlineColor": {"r": 0.5, "g": 0.25, "b": 1},
	}

	utils.update_entity_component(
			scene, entity_id, DCL_TextShape._classid, JSON.new().stringify(label_dict))

	assert_eq(entity.get_child_count(), 1)

	var waypoint = entity.get_child(0)
	assert_is(waypoint, Control)
	assert_not_null(waypoint.label, "Label attached to the entity")

	assert_eq(waypoint.text, label_dict.value)
	assert_eq(waypoint.label.get("custom_colors/font_color"),
			Color(label_dict.color.r, label_dict.color.g, label_dict.color.b))

	var font = waypoint.label.get("custom_fonts/font")
	assert_is(font, Font)
#	assert_eq(font.outline_size, label_dict.outlineWidth)
#	assert_eq(font.outline_color, Color(label_dict.outlineColor.r,
#			label_dict.outlineColor.g, label_dict.outlineColor.b))
