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

var style : int = PictureFrameStyle.Classic setget _set_style
var material : SpatialMaterial
var color : Color

func _set_style(s):
	style = s
	match s:
		#Implement all the different styles
		_:
			mesh = CubeMesh.new()
			mesh.size = Vector3( 1.0,1.0,0.1 )
			translate_object_local( Vector3(0,0,0.02) )
			material = SpatialMaterial.new()
			mesh.surface_set_material(0, material)
			material.flags_unshaded = true
			update_color(color)
			
func update_color(c : Color):
	material.albedo_color = c
	material.emission = c