extends "res://interfaces/component.gd"
class_name DCL_AnimationState

const PROTO = preload("res://server/engineinterface.gd")
const _classid = 33

static func update_component_in_entity(data, entity, scene):
	var parsed = JSON.parse(data).result
	if parsed.has("states") and entity.has_node("AnimationPlayer"):
		var anim_node = entity.get_node("AnimationPlayer") as AnimationPlayer
		for anim in parsed.states:
			# TODO Change this so it mixes (cross-fades) all active animations
			if anim.playing and anim_node.has_animation(anim.clip):
				anim_node.get_animation(anim.clip).loop = anim.looping
				anim_node.playback_speed = anim.speed
				anim_node.play(anim.clip)
				break
