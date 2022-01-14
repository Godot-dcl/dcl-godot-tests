extends "res://interfaces/component.gd"
class_name DCL_AnimationState

const PROTO = preload("res://server/engineinterface.gd")
const _classid = 33

static func update_component_in_entity(data, entity, _scene):
	var json = JSON.new()
	var err = json.parse(data)
	if err != OK:
		return
	var parsed = json.get_data()
	if not parsed.has("states") or parsed.states.is_empty():
		return

	var anim_player = entity.get_node("AnimationPlayer")
	var anim_tree = entity.get_node("AnimationTree")

	var tree = AnimationNodeBlendTree.new()
	tree.add_node("Transition", AnimationNodeTransition.new())
	var last_animation_node = "Transition"
	for anim in parsed.states:
		if not anim.playing: continue
		assert(anim_player.has_animation(anim.clip))

		var animation_node = AnimationNodeAnimation.new()
		var animation = anim_player.get_animation(anim.clip) as Animation
		#animation.loop = anim.looping
		animation_node.animation = anim.clip
		tree.add_node(anim.name, animation_node)

		var node_name = "%s_blend" % anim.name
		var blend_node = AnimationNodeOneShot.new()
		blend_node.autorestart = anim.looping
		blend_node.autorestart_delay = 0.0
		anim_tree.call_deferred("set", "parameters/%s/active" % node_name, true)

		# filter used bones only
		var used_bones = []
		for i in animation.get_track_count():
			used_bones.push_back(animation.track_get_path(i))
		blend_node.filter_enabled = true
		blend_node.filters = used_bones

		tree.add_node(node_name, blend_node)
		tree.connect_node(node_name, 0, last_animation_node)
		if anim.speed == 1:
			tree.connect_node(node_name, 1, anim.name)
		else:
			var speed_node = AnimationNodeTimeScale.new()
			var speed_node_name = "%s_speed" % anim.name

			tree.add_node(speed_node_name, speed_node)
			tree.connect_node(speed_node_name, 0, anim.name)
			tree.connect_node(node_name, 1, speed_node_name)
			anim_tree.call_deferred("set", "parameters/%s/scale" % speed_node_name, anim.speed)

		last_animation_node = node_name

	tree.connect_node("output", 0, last_animation_node)
	anim_tree.tree_root = tree

