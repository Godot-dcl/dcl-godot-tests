extends Reference


#enum MaterialTransparencyMode {
#	OPAQUE,
#	ALPHA_TEST,
#	ALPHA_BLEND,
#	ALPHA_TEST_AND_BLEND,
#	AUTO
#}

var name : String
var animation : AnimationPlayer
var meshes = [] #MeshInstance
var colliders = [] #PhysicsBody
var material : SpatialMaterial
#var material_transparency_mode = 4


func _init(_name):
	name = _name
	match name:
		"shape":
			var m = MeshInstance.new()
			m.mesh = CubeMesh.new()
			m.mesh.size = Vector3.ONE
			m.name = name

			material = SpatialMaterial.new()
			#material.flags_unshaded = true
			m.set("material/0", material)
			meshes.push_back(m)

		"material":
			material = SpatialMaterial.new()


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

					if child is Spatial and child.get_child_count() > 0 :
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

	if json.has("albedoColor"):
		material.albedo_color = Color(
			json.albedoColor.r,
			json.albedoColor.g,
			json.albedoColor.b
		)

	if json.has("metallic"):
		material.metallic = json.metallic

	if json.has("roughness"):
		material.roughness = json.roughness

#	if json.has("transparencyMode"):
#		material_transparency_mode = json.transparencyMode

	if json.has("alphaTest"):
		material.flags_transparent = true
		material.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
		material.params_use_alpha_scissor = true
		material.params_alpha_scissor_threshold = json.alphaTest

#	if json.has("castShadows"):
#		mesh.cast_shadow = json.castShadows
#
#	if json.has("visible"):
#		mesh.visible = json.visible

func attach_to(entity):
	if name == "material":
		if entity.has_node("shape"):
			entity.get_node("shape").set("material/0", material)
	else:
		for m in meshes:
			entity.add_child(m.duplicate())

	if is_instance_valid(animation):
		var a = animation.duplicate()
		entity.add_child(a)
		a.root_node = entity.get_path()
		a.clear_caches()
