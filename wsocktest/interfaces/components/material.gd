extends "res://interfaces/component.gd"
class_name DCL_Material

const _classid = 65

var material : SpatialMaterial


func _init(_name).(_name):
	material = SpatialMaterial.new()


func update(data):
	var json = JSON.parse(data).result
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

	if json.has("alphaTest"):
		material.flags_transparent = true
		material.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
		material.params_use_alpha_scissor = true
		material.params_alpha_scissor_threshold = json.alphaTest


func attach_to(entity):
	if entity.has_node("shape"):
		entity.get_node("shape").set("material/0", material)
