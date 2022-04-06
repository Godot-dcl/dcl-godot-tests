extends "res://interfaces/component.gd"
class_name DCL_Transform

const _classid = 1
const PROTO = preload("res://server/engineinterface.gd")


static func update_component_in_entity(data, entity, _scene):
	var buf = Marshalls.base64_to_raw(data)

	var comp = PROTO.PB_Transform.new()
	var err = comp.from_bytes(buf)
	if err == PROTO.PB_ERR.NO_ERRORS:
		var rot = comp.get_rotation()
		var pos = comp.get_position()
		var sca = comp.get_scale()

		var q = Quaternion(
			rot.get_x(),
			rot.get_y(),
			rot.get_z(),
			rot.get_w()
		)
		var t = Transform3D(q).scaled(Vector3(-sca.get_x(), sca.get_y(), sca.get_z()))
		t.origin = Vector3(-pos.get_x(), pos.get_y(), pos.get_z())
		entity.transform = t
	else:
		push_warning("****** error decoding PB_Transform payload %s" % err)
