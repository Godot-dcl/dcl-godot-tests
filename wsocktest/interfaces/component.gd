extends Reference
class_name DCL_Component

var name : String
var scene : Node
var id : String

func _init(_name, _scene, _id):
	name = _name
	scene = _scene
	id = _id

func update(_data):
	pass

func attach_to(_entity):
	pass

static func update_component_in_entity(_data, _entity, _scene):
	pass
