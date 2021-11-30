extends Reference
class_name DCL_Component

var name : String


func _init(_name):
	name = _name

func update(data):
	pass

func attach_to(entity):
	pass

static func update_component_in_entity(data, entity, scene):
	pass
