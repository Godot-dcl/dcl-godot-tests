extends "res://interfaces/component.gd"
class_name DCL_Material

const _classid = 65

var material : SpatialMaterial


func _init(_name, _scene, _id).(_name, _scene, _id):
	material = SpatialMaterial.new()


func update(data):
	var json = JSON.parse(data).result
	if json.has("albedoColor"):
		material.albedo_color = Color(
			json.albedoColor.r,
			json.albedoColor.g,
			json.albedoColor.b
		)

	if json.has("albedoTexture"):
		var tex_component = scene.components[json.albedoTexture]
		if tex_component is DCL_VideoTexture:
			material.params_cull_mode = SpatialMaterial.CULL_DISABLED
		# the texture reference in the component can change after it was assigned. Keep it up to date
		tex_component.connect("texture_changed", self, "_on_albedo_texture_changed")
		material.albedo_texture = tex_component.texture

	if json.has("alpha"):
		var new_color = material.albedo_color
		material.flags_transparent = true
		new_color.a = json.alpha

	if json.has("hasAlpha"):
		material.flags_transparent = json.hasAlpha

	if json.has("disableLighting"):
		material.flags_unshaded = json.disableLighting

	if json.has("emissiveTexture"):
		material.emission_enabled = true
		var tex_component = scene.components[json.emissiveTexture]
		if tex_component is DCL_VideoTexture:
			material.params_cull_mode = SpatialMaterial.CULL_DISABLED
			material.emission_operator = SpatialMaterial.EMISSION_OP_MULTIPLY
		# the texture reference in the component can change after it was assigned. Keep it up to date
		tex_component.connect("texture_changed", self, "_on_emissive_texture_changed")
		material.emission_texture = tex_component.texture

	if json.has("emissiveIntensity"):
		material.emission_enabled = true
		material.emission_energy = json.get("emissiveIntensity", material.emission_energy)

	if json.has("emissiveColor"):
		material.emission_enabled = true
		var color_dict = json.emissiveColor
		material.emission = Color(color_dict.r, color_dict.g, color_dict.b)

	if json.has("metallic"):
		material.metallic = json.metallic

	if json.has("roughness"):
		material.roughness = json.roughness

	if json.has("alphaTest"):
		material.flags_transparent = true
		material.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
		material.params_use_alpha_scissor = true
		material.params_alpha_scissor_threshold = json.alphaTest


func attach_to(entity):
	if entity.has_node("shape"):
		entity.get_node("shape").set("material/0", material)

	.attach_to(entity)

func detach_from(entity):
	if entity.has_node("shape"):
		entity.get_node("shape").set("material/0", SpatialMaterial.new())

	.detach_from(entity)

func _on_albedo_texture_changed(value):
	material.albedo_texture = value

func _on_emissive_texture_changed(value):
	material.emission_texture = value
