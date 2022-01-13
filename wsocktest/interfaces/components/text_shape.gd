extends "res://interfaces/component.gd"
class_name DCL_TextShape


const WAYPOINT = preload("res://ui/waypoint/waypoint.tscn")
const PROTO = preload("res://server/engineinterface.gd")
const _classid = 21


static func update_component_in_entity(data, entity, _scene):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var parsed = parser.get_data()

	if parsed.has("outlineWidth"):
		var w = WAYPOINT.instance()
		var label = w.get_node("Label") as Label
		var font = label.get("custom_fonts/font") as Font
		w.text = parsed.value
		label.set("custom_colors/font_color", Color(parsed.color.r, parsed.color.g, parsed.color.b))
		font.outline_color = Color(parsed.outlineColor.r, parsed.outlineColor.g, parsed.outlineColor.b)
		font.outline_size = parsed.outlineWidth
		entity.add_child(w)
