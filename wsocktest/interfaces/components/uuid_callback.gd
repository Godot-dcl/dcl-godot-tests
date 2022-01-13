extends "res://interfaces/component.gd"
class_name DCL_UUIDCallback


const EVENT = preload("res://interfaces/event.gd")
const PROTO = preload("res://server/engineinterface.gd")
const _classid = 8


static func update_component_in_entity(data, entity, scene):

	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var parsed = parser.get_data()

	if parsed.has("uuid"):
		if scene.has_meta("events"):
			scene.get_meta("events").append(EVENT.new(scene.id, entity, parsed))
		else:
			scene.set_meta("events", [EVENT.new(scene.id, entity, parsed)])
