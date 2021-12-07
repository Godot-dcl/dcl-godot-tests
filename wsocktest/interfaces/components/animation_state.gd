extends "res://interfaces/component.gd"
class_name DCL_AnimationState

const PROTO = preload("res://server/engineinterface.gd")
const _classid = 33

static func update_component_in_entity(data, entity, _scene):
	var parsed = JSON.parse(data).result
	if not parsed.has("states"):
		return

	var anim_player = entity.get_node("AnimationPlayer")
	var anim_tree = entity.get_node("AnimationTree")

	var tree = AnimationNodeBlendTree.new()
	var last_animation_node : String
	for anim in parsed.states:
		if not anim.playing: continue

		var animation_node = AnimationNodeAnimation.new()
		var animation = anim_player.get_animation(anim.clip) as Animation
		animation.loop = anim.looping
		animation_node.animation = anim.clip
		tree.add_node(anim.name, animation_node)

		if last_animation_node.empty():
			last_animation_node = anim.name
		else:
			var node_name = "%s_blend" % anim.name
			var blend_node : AnimationNode
			if anim.looping:
				blend_node = AnimationNodeBlend2.new()
				tree.call_deferred("set", "parameters/%s/blend_amount" % node_name, 0.5)
			else:
				blend_node = AnimationNodeOneShot.new()
				tree.call_deferred("set", "parameters/%s/active" % node_name, true)

			# filter used bones only
			var used_bones = []
			for i in animation.get_track_count():
				used_bones.push_back(animation.track_get_path(i))
			blend_node.filter_enabled = true
			blend_node.filters = used_bones

			tree.add_node(node_name, blend_node)
			tree.connect_node(node_name, 0, last_animation_node)
			tree.connect_node(node_name, 1, anim.name)

			last_animation_node = node_name

	if not last_animation_node.empty():
		tree.connect_node("output", 0, last_animation_node)
		anim_tree.tree_root = tree
