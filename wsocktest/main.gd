extends Spatial


func _ready():
	Server.loading_screen = $Control/Loading
	Server.player = $CameraRig
