extends "res://interfaces/component.gd"
class_name DCL_BasicMaterial

const _classid = 64

var material : StandardMaterial3D


func _init(_name, _scene, _id):
	super(_name, _scene, _id)
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func update(data):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var json = parser.get_data()

	if json.has("texture"):
		var tex_component = scene.components[json.texture]
		# the texture reference in the component can change after it was assigned. Keep it up to date
		if tex_component is DCL_VideoTexture:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if tex_component.has_signal("texture_changed"):
			tex_component.texture_changed.connect(_on_texture_changed)
		material.albedo_texture = tex_component.texture

	if json.has("alphaTest"):
		material.flags_transparent = true
		material.params_depth_draw_mode = StandardMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		material.params_use_alpha_scissor = true
		material.params_alpha_scissor_threshold = json.alphaTest


func attach_to(entity):
	if entity.has_node("shape"):
		entity.get_node("shape").mesh.surface_set_material(0, material)

	super.attach_to(entity)


func detach_from(entity):
	if entity.has_node("shape"):
		entity.get_node("shape").set("material/0", StandardMaterial3D.new())

	super.detach_from(entity)

func _on_texture_changed(texture):
	material.albedo_texture = texture
