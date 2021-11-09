extends Node

signal pointer_down(entity)
signal pointer_up(entity)

signal primary_down(entity)
signal primary_up(entity)

signal secondary_down(entity)
signal secondary_up(entity)

# entity can be null here!
signal entity_hover_changed(entity)

var last_entity_hovered : Node
var raycast : RayCast

# Called when the node enters the scene tree for the first time.
func _init():
	pass # Replace with function body.


func _process(_delta):
	if is_instance_valid(raycast):
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			var entity = collider.get_parent().get_parent()
			if entity != last_entity_hovered:
				last_entity_hovered = entity

				emit_signal("entity_hover_changed", entity)
		else:
			if last_entity_hovered != null:
				last_entity_hovered = null

				emit_signal("entity_hover_changed", null)
				return


func _input(event):
	if last_entity_hovered != null:
		if Input.is_action_just_pressed("Pointer"):
			emit_signal("pointer_down", last_entity_hovered)
		if Input.is_action_just_released("Pointer"):
			emit_signal("pointer_up", last_entity_hovered)

		if Input.is_action_just_pressed("Primary"):
			emit_signal("primary_down", last_entity_hovered)
		if Input.is_action_just_released("Primary"):
			emit_signal("primary_up", last_entity_hovered)

		if Input.is_action_just_pressed("Secondary"):
			emit_signal("secondary_down", last_entity_hovered)
		if Input.is_action_just_released("Secondary"):
			emit_signal("secondary_up", last_entity_hovered)
