extends "res://interfaces/component.gd"
class_name DCL_GLTFShape

const _classid = 54

var meshes = [] #MeshInstance
var colliders = [] #PhysicsBody
var animations = {} #Animation
var src = ""

func _init(_name, _scene, _id):
	super(_name, _scene, _id)


func update(data):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var json = parser.get_data()
	if json.has("src") and src != json.src:
		src = json.src
		for m in meshes:
			if is_instance_valid(m):
				m.queue_free()

		#meshes.clear()

		var ext = json.src.get_extension()
		if ext in ["glb", "gltf"]:
			var content = ContentManager.get_instance(json.src)
			if is_instance_valid(content):

				for child in content.get_children():
					if child is MeshInstance3D:
						if str(child.name).ends_with("_collider"):
							child.create_trimesh_collision()
							var collider = child.get_child(0)
							collider.name = child.name
							colliders.push_back(collider)
						else:
							meshes.push_back(child)

					if child is Node3D and child.get_child_count() > 0:
						if child.get_child(0) is Skeleton3D:
							meshes.push_back(child)

					if child is AnimationPlayer:
						for anim_name in child.get_animation_list():
							animations[anim_name] = child.get_animation(anim_name).duplicate()

	if json.has("withCollisions"):
		if colliders.is_empty():
			for m in meshes:
				if m is MeshInstance3D:
					m.create_trimesh_collision()
					var c = m.get_child(0)
					if is_instance_valid(c):
						c.name = m.name
						colliders.push_back(c)

		if json.has("isPointerBlocker"):
			for c in colliders:
				if is_instance_valid(c):
					c.collision_layer = int(pow(2, 10) + pow(2, 11) + pow(2, 12))

	if json.has("visible"):
		for m in meshes:
			m.visible = json.visible


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

	super.attach_to(entity)


func detach_from(entity):
	for m in meshes:
		if entity.has_child(m.name):
			entity.get_node(m.name).queue_free()

	if animations.size() > 0:
		entity.get_node("AnimationPlayer").queue_free()
		entity.get_node("AnimationTree").queue_free()

	super.detach_from(entity)
