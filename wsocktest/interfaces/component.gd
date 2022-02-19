extends RefCounted
class_name DCL_Component

var name : String
var scene : Node
var id : String
var attached_entities : Array

func _init(_name, _scene, _id):
	name = _name
	scene = _scene
	id = _id

	init_ref()

func update(_data):
	pass

func attach_to(_entity):
	reference()
	attached_entities.push_back(_entity)

func detach_from(_entity):
	if _entity in attached_entities:
		unreference()
		attached_entities.erase(_entity)

func dispose():
	for e in attached_entities:
		detach_from(e)

	# TODO destroy the resource in the content manager

static func update_component_in_entity(_data, _entity, _scene):
	pass
