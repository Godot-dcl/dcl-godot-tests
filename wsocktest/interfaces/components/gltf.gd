extends "res://interfaces/component.gd"
class_name DCL_GLTFShape

const _classid = 54

var meshes = [] #MeshInstance
var colliders = [] #PhysicsBody
var animations = {} #Animation

func _init(_name).(_name):
	pass


func update(data):
	var json = JSON.parse(data).result
	if json.has("src"):
		for m in meshes:
			m.queue_free()

		meshes.clear()

		var ext = json.src.get_extension()
		if ext in ["glb", "gltf"]:
			var content = ContentManager.get_instance(json.src)
			if is_instance_valid(content):

				for child in content.get_children():
					if child is MeshInstance:
						if child.name.ends_with("_collider"):
							child.create_trimesh_collision()
							var collider = child.get_child(0)
							collider.name = child.name
							colliders.push_back(collider)
						else:
							meshes.push_back(child)

					if child is Spatial and child.get_child_count() > 0:
						if child.get_child(0) is Skeleton:
							meshes.push_back(child)

					if child is AnimationPlayer:
						for anim_name in child.get_animation_list():
							animations[anim_name] = child.get_animation(anim_name).duplicate()

	if json.has("withCollisions"):
		if colliders.empty():
			for m in meshes:
				if m is MeshInstance:
					m.create_trimesh_collision()
					var c = m.get_child(0)
					if is_instance_valid(c):
						c.name = m.name
						colliders.push_back(c)

		if json.has("isPointerBlocker"):
			for collider in colliders:
				collider.collision_layer = int(pow(2, 10) + pow(2, 11) + pow(2, 12))


func attach_to(entity):
	for m in meshes:
		entity.add_child(m.duplicate())

	if animations.size() > 0:
		var anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		for anim_name in animations.keys():
			if anim_player.add_animation(anim_name, animations[anim_name].duplicate()) != OK:
				printerr("Error adding animation to AnimationPlayer")
		entity.add_child(anim_player)

		var anim_tree = AnimationTree.new()
		anim_tree.name = "AnimationTree"
		entity.add_child(anim_tree)

		anim_tree.anim_player = anim_tree.get_path_to(anim_player)
		anim_tree.tree_root = AnimationRootNode.new() # set a default root node
		anim_tree.set_active(true)
