extends "res://addons/gut/test.gd"


var utils = TestUtils.new()


func test_material_creation():
	# Create a scene with a entity

	var scene = autoqfree(Server.SCENE.instance())
	add_child(scene)

	var entity_id = "1"
	var entity = utils.create_entity(scene, entity_id)

	# Create and attach a cube shape to the entity

	var shape_comp_id = "0"
	utils.create_component(scene, shape_comp_id, DCL_BoxShape._classid, "shape")
	utils.attach_component_to_entity(scene, shape_comp_id, entity_id)

	# Create and attach a material to the entity

	var material_comp_id = "1"
	var material_comp = utils.create_component(scene, material_comp_id,
			DCL_Material._classid, material_comp_id)

	assert_not_null(material_comp.material)

	var mat_vars = {
		"albedoColor": {
			"r": 1, "g": 0.5, "b": 0.25
		},
		"emissiveIntensity": 0.6,
		"emissiveColor": {
			"r": 0.25, "g": 1, "b": 0.5
		},
		"metallic": 0.75,
		"roughness": 0.4,
		"alphaTest": 0.05
	}
	utils.update_component(scene, material_comp_id, to_json(mat_vars))

	assert_eq(material_comp.material.albedo_color,
			Color(mat_vars["albedoColor"]["r"], mat_vars["albedoColor"]["g"],
					mat_vars["albedoColor"]["b"]))

	assert_eq(
			material_comp.material.emission_enabled, true, "Emission enabled")
	assert_almost_eq(material_comp.material.emission_energy,
			mat_vars["emissiveIntensity"], utils.FLOAT_ERROR_MARGIN)

	assert_eq(material_comp.material.emission,
			Color(mat_vars["emissiveColor"]["r"], mat_vars["emissiveColor"]["g"],
					mat_vars["emissiveColor"]["b"]))

	assert_almost_eq(material_comp.material.metallic, mat_vars["metallic"],
			utils.FLOAT_ERROR_MARGIN)

	assert_almost_eq(material_comp.material.roughness, mat_vars["roughness"],
			utils.FLOAT_ERROR_MARGIN)

	assert_true(material_comp.material.flags_transparent,
			"Alpha test value modified (1/4)")
	assert_eq(material_comp.material.params_depth_draw_mode,
			SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS,
			"Alpha test value modified (2/4)")
	assert_true(material_comp.material.params_use_alpha_scissor,
			"Alpha test value modified (3/4)")
	assert_almost_eq(material_comp.material.params_alpha_scissor_threshold,
			mat_vars["alphaTest"], utils.FLOAT_ERROR_MARGIN,
			"Alpha test value modified (4/4)")

	utils.attach_component_to_entity(scene, material_comp_id, entity_id)

	assert_eq(entity.get_node("shape").get("material/0"),
			material_comp.material, "Material attached to mesh")
