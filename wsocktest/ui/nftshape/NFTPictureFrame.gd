extends MeshInstance3D
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

var meshes : Dictionary = {
	PictureFrameStyle.Classic : preload("res://3d/NFTShape/Classic.gltf"),
	PictureFrameStyle.Baroque_Ornament : preload("res://3d/NFTShape/Barroque_01.gltf"),
	PictureFrameStyle.Diamond_Ornament : preload("res://3d/NFTShape/Barroque_02.gltf"),
	PictureFrameStyle.Minimal_Wide : preload("res://3d/NFTShape/Basic_01.gltf"),
	PictureFrameStyle.Minimal_Grey : preload("res://3d/NFTShape/Basic_02.gltf"),
	PictureFrameStyle.Blocky : preload("res://3d/NFTShape/Blocky_01.gltf"),
	PictureFrameStyle.Gold_Edges : preload("res://3d/NFTShape/Golden_01.gltf"),
	PictureFrameStyle.Gold_Carved : preload("res://3d/NFTShape/Golden_02.gltf"),
	PictureFrameStyle.Gold_Wide : preload("res://3d/NFTShape/Golden_03.gltf"),
	PictureFrameStyle.Gold_Rounded : preload("res://3d/NFTShape/Golden_04.gltf"),
	PictureFrameStyle.Metal_Medium : preload("res://3d/NFTShape/Metal_01.gltf"),
	PictureFrameStyle.Metal_Wide : preload("res://3d/NFTShape/Metal_02.gltf"),
	PictureFrameStyle.Metal_Slim : preload("res://3d/NFTShape/Metal_03.gltf"),
	PictureFrameStyle.Metal_Rounded : preload("res://3d/NFTShape/Metal_04.gltf"),
	PictureFrameStyle.Pins : preload("res://3d/NFTShape/Pin.gltf"),
	PictureFrameStyle.Minimal_Black : preload("res://3d/NFTShape/SimpleBlack.gltf"),
	PictureFrameStyle.Minimal_White : preload("res://3d/NFTShape/SimpleWhite.gltf"),
	PictureFrameStyle.Tape : preload("res://3d/NFTShape/Tapper.gltf"),
	PictureFrameStyle.Wood_Slim : preload("res://3d/NFTShape/Wood.gltf"),
	PictureFrameStyle.Wood_Wide : preload("res://3d/NFTShape/Wood_02.gltf"),
	PictureFrameStyle.Wood_Twigs : preload("res://3d/NFTShape/WoodSticks.gltf"),
	PictureFrameStyle.Canvas: preload("res://3d/NFTShape/SimpleCanvas.gltf"),
	PictureFrameStyle.None : preload("res://3d/NFTShape/SimpleWhite.gltf") #Anything goes, it just simplifies code
}

var _style : int = PictureFrameStyle.Classic
var material : StandardMaterial3D
var color : Color

enum { BORDER, BACKGROUND, DETAIL } # Not all styles obey this

func _init():
	mesh = ArrayMesh.new()
	translate_object_local( Vector3(0,0,0.031) )

func set_style(style : int, size : Vector2):
	_style = style
	var model = meshes[style].instantiate()
	var new_mesh = model.get_child(0).mesh.duplicate(true)
	mesh = new_mesh

	match style:
		PictureFrameStyle.Classic:
			mesh.surface_get_material(BORDER).albedo_color = color
			mesh.surface_get_material(BORDER).emission = color
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(BACKGROUND).emission = color
			mesh.surface_get_material(DETAIL).emission_energy = 10

		PictureFrameStyle.Canvas:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color

		PictureFrameStyle.Baroque_Ornament:
			mesh.surface_get_material(BORDER).albedo_color = Color.GOLDENROD
			mesh.surface_get_material(BORDER).emission = Color.GOLDENROD
			mesh.surface_get_material(BACKGROUND).albedo_color = Color.GOLDENROD
			mesh.surface_get_material(DETAIL).albedo_color = Color.GOLDENROD

		PictureFrameStyle.Diamond_Ornament:
			mesh.surface_get_material(BORDER).albedo_color = Color.GOLDENROD
			mesh.surface_get_material(BORDER).emission = Color.CHOCOLATE
			mesh.surface_get_material(BACKGROUND).albedo_color = Color.GOLDENROD
			mesh.surface_get_material(DETAIL).albedo_color = Color.GOLDENROD

		PictureFrameStyle.Minimal_Wide:
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(DETAIL).albedo_color = color

		PictureFrameStyle.Minimal_Grey:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(DETAIL).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color

		PictureFrameStyle.Minimal_Black:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BORDER).albedo_color = color
			mesh.surface_get_material(BORDER).shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(BACKGROUND).shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			mesh.surface_get_material(DETAIL).emission_enabled = false
			mesh.surface_get_material(DETAIL).albedo_color = Color.BLACK

		PictureFrameStyle.Minimal_White:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(DETAIL).emission_enabled = false

		PictureFrameStyle.Wood_Slim, PictureFrameStyle.Wood_Wide:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BORDER).albedo_texture = preload("res://3d/NFTShape/Floor_Wood01.png")
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(DETAIL).emission_enabled = false

		PictureFrameStyle.Wood_Twigs:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_texture = preload("res://3d/NFTShape/Genesis_TX.png")

		PictureFrameStyle.Tape:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(DETAIL).emission_enabled = false

		PictureFrameStyle.Metal_Medium, PictureFrameStyle.Metal_Wide, PictureFrameStyle.Metal_Slim, PictureFrameStyle.Metal_Rounded:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			
		PictureFrameStyle.Pins:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BORDER).albedo_texture = preload("res://3d/NFTShape/Genesis_TX.png")
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(BACKGROUND).shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			mesh.surface_get_material(BACKGROUND).emission_enabled = false
			mesh.surface_get_material(DETAIL).albedo_color = color
			mesh.surface_get_material(DETAIL).emission_enabled = false
			mesh.surface_get_material(DETAIL).shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED

		PictureFrameStyle.Blocky:
			mesh.surface_get_material(BORDER).albedo_color = color
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(BACKGROUND).emission_enabled = false

		PictureFrameStyle.Gold_Carved, PictureFrameStyle.Gold_Edges, PictureFrameStyle.Gold_Wide, PictureFrameStyle.Gold_Rounded:
			mesh.surface_get_material(BORDER).emission_enabled = false
			mesh.surface_get_material(BACKGROUND).albedo_color = color
			mesh.surface_get_material(BACKGROUND).emission = color
			mesh.surface_get_material(DETAIL).albedo_color = color
			mesh.surface_get_material(DETAIL).emission = color

		PictureFrameStyle.None:
			mesh = null

		_:
			printerr("Unimplemented PictureStyle %s" % PictureFrameStyle.keys()[style])

	scale = Vector3(size.x, size.y, 1.0)
	

func update_color(c : Color):
	material.albedo_color = c
	material.emission = c
	
