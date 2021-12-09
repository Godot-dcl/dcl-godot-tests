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
		var tex = scene.components[json.albedoTexture].texture # TODO: Replace with proper equivalent of scene.GetSharedComponent(componentId)
		material.albedo_texture = tex
	
	if json.has("emissiveTexture"):
		material.emission_enabled = true
		var tex = scene.components[json.emissiveTexture].texture # TODO: Replace with proper equivalent of scene.GetSharedComponent(componentId)
		material.emission_texture = tex
	
	if json.has("emissiveIntensity"):
		material.emission_enabled = true
		material.emission_energy = json.get("emissiveIntensity", material.emission_energy)
		if json.has("emissiveColor"):
			var color_dict = json.emissiveColor
			var color = Color(color_dict.r, color_dict.g, color_dict.b)
	
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
