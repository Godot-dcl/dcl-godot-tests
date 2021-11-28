extends "res://interfaces/component.gd"
class_name DCL_GLTFShape

const _classid = 54

var meshes = [] #MeshInstance
var colliders = [] #PhysicsBody
var animation : AnimationPlayer

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
						animation = child

	if json.has("withCollisions"):
		if colliders.empty():
			for m in meshes:
				if m is MeshInstance:
					m.create_trimesh_collision()
					var c = m.get_child(0)
					c.name = m.name
					colliders.push_back(c)

		if json.has("isPointerBlocker"):
			for collider in colliders:
				collider.collision_layer = int(pow(2, 10) + pow(2, 11) + pow(2, 12))


func attach_to(entity):
	for m in meshes:
		entity.add_child(m.duplicate())