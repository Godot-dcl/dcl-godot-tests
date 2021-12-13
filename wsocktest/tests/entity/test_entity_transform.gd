extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_entity_transformation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Modify the transform of the entity

	var trans_comp = Server.PROTO.PB_Transform.new()

	var rotation = Quat(12, -9, 5, -2)
	trans_comp.new_rotation().set_x(rotation.x)
	trans_comp.get_rotation().set_y(rotation.y)
	trans_comp.get_rotation().set_z(rotation.z)
	trans_comp.get_rotation().set_w(rotation.w)

	var position = Vector3(10, -7, 3)
	trans_comp.new_position().set_x(position.x)
	trans_comp.get_position().set_y(position.y)
	trans_comp.get_position().set_z(position.z)

	var scale = Vector3(8, -6, 4)
	trans_comp.new_scale().set_x(scale.x)
	trans_comp.get_scale().set_y(scale.y)
	trans_comp.get_scale().set_z(scale.z)

	utils.update_entity_component(scene, entity_id, DCL_Transform._classid,
			Marshalls.raw_to_base64(trans_comp.to_bytes()))

	var trans = Transform(rotation).scaled(scale)
	trans.origin = position

	assert_eq(entity.transform, trans, "Transform values modified")

	# Attach a another entity to the previous one

	var child_entity_id = "2"
	var child_entity = utils.create_entity(scene, child_entity_id)

	utils.reparent_entity(scene, child_entity_id, entity_id)

	assert_eq(entity.transform, child_entity.global_transform,
			"Child inherits the transform of its parent")
