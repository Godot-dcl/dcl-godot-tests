extends MarginContainer


const B_TO_MB = pow(1024, 2)

var info = """
	FPS: %d
	Process: %.2f ms
	Static Memory: %.2f MB
	Dynamic Memory: %.2f MB
	Rendered Objects: %d
	Rendered Vertices: %d
	Draw Calls: %d
	"""

onready var label = $Label


func _ready():
	visible = OS.is_debug_build()
	set_physics_process(OS.is_debug_build())


func _physics_process(_delta):
	label.text = info % [
		Performance.get_monitor(Performance.TIME_FPS),
		Performance.get_monitor(Performance.TIME_PROCESS),
		OS.get_static_memory_usage() / B_TO_MB,
		OS.get_dynamic_memory_usage() / B_TO_MB,
		Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME),
	]
