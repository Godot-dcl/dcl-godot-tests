extends Reference


#enum MaterialTransparencyMode {
#	OPAQUE,
#	ALPHA_TEST,
#	ALPHA_BLEND,
#	ALPHA_TEST_AND_BLEND,
#	AUTO
#}

var name : String
var mesh = [] #MeshInstance.new()
var mesh_collider : MeshInstance
var collider : CollisionShape
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
			mesh.push_back(m)

		"material":
			material = SpatialMaterial.new()


func update(data):
	var json = JSON.parse(data).result
	if json.has("src"):
		mesh.clear()
		var ext = json.src.get_extension()
		if ext == "glb":
			var content = ContentManager.get_instance(json.src)

			if is_instance_valid(content):
				for child in content.get_children():
					if child.name.ends_with("_collider"):
						mesh_collider = child
					else:
						mesh.push_back(child)

	if json.has("withCollisions"):
		var static_body: StaticBody
		if is_instance_valid(mesh_collider):
			mesh_collider.create_trimesh_collision()
			static_body = mesh_collider.get_child(0)
			mesh_collider.remove_child(static_body)
			mesh[0].add_child(static_body)
		else:
			var m = mesh[0]
			m.create_trimesh_collision()
			static_body = m.get_child(0)

		if json.has("isPointerBlocker"):
			static_body.collision_layer = int(pow(2, 10) + pow(2, 11) + pow(2, 12))

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
		entity.get_node("shape").set("material/0", material)
	else:
		for m in mesh:
			entity.add_child(m.duplicate())
