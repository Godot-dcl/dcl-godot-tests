extends MeshInstance
class_name NFTPictureFrame

enum PictureFrameStyle { 
    Classic, 
    Baroque_Ornament,
    Diamond_Ornament,
    Minimal_Wide,
    Minimal_Grey,
    Blocky, #5
    Gold_Edges,
    Gold_Carved,
    Gold_Wide,
    Gold_Rounded,
    Metal_Medium, #10
    Metal_Wide,
    Metal_Slim,
    Metal_Rounded,
    Pins,
    Minimal_Black, #15
    Minimal_White,
    Tape,
    Wood_Slim,
    Wood_Wide,
    Wood_Twigs, #20
    Canvas,
    None
 }

var _style : int = PictureFrameStyle.Classic
var material : SpatialMaterial
var color : Color

func _init():
	mesh = ArrayMesh.new()
	translate_object_local( Vector3(0,0,0.031) )

func set_style(style : int, size : Vector2):
	_style = style
	match style:
		#Implement all the different styles
		
		PictureFrameStyle.Classic:
			var model = preload("res://3d/NFTShape/Classic.gltf").instance()
			var new_mesh = model.get_child(0).mesh.duplicate(true)
			mesh = new_mesh
			mesh.surface_get_material(0).albedo_color = color
			mesh.surface_get_material(0).emission = color
			mesh.surface_get_material(1).albedo_color = color
			mesh.surface_get_material(1).emission = color
			mesh.surface_get_material(2).emission_energy = 10
		
		PictureFrameStyle.Blocky:
			var model = preload("res://3d/NFTShape/Blocky_01.gltf").instance()
			var new_mesh = model.get_child(0).mesh.duplicate(true)
			mesh = new_mesh
			mesh.surface_get_material(0).albedo_color = color
			mesh.surface_get_material(0).emission_enabled = false
			mesh.surface_get_material(1).albedo_color = color
			mesh.surface_get_material(1).emission_enabled = false
		
		PictureFrameStyle.Gold_Carved:
			var model = preload("res://3d/NFTShape/Golden_01.gltf").instance()
			var new_mesh = model.get_child(0).mesh.duplicate(true)
			mesh = new_mesh
			mesh.surface_get_material(0).emission_enabled = false
			mesh.surface_get_material(1).albedo_color = color
			mesh.surface_get_material(1).emission = color
			mesh.surface_get_material(2).albedo_color = color
			mesh.surface_get_material(2).emission = color
		
		PictureFrameStyle.Gold_Wide:
			var model = preload("res://3d/NFTShape/Golden_03.gltf").instance()
			var new_mesh = model.get_child(0).mesh.duplicate(true)
			mesh = new_mesh
			mesh.surface_get_material(0).emission_enabled = false
			mesh.surface_get_material(1).albedo_color = color
			mesh.surface_get_material(1).emission = color
			mesh.surface_get_material(2).albedo_color = color
			mesh.surface_get_material(2).emission = color
		_:
			printerr("Unimplemented PictureStyle %s" % PictureFrameStyle.keys()[style])
	scale = Vector3(size.x, size.y, 1.0)
	

func update_color(c : Color):
	material.albedo_color = c
	material.emission = c
	
