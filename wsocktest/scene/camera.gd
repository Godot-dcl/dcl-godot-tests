extends Node3D

signal third_person_changed(enabled)

const RAYCAST_DISTANCE = 8
const THIRD_PERSON_SHOLDER_DISTANCE = 1

@export var third_person := false:
	set = set_third_person
@export var third_person_distance: int:
	set(value):
		third_person_distance = value
		set_third_person(third_person)

@export var mouse_sensitivity: float

@onready var spring = $SpringArm3D
@onready var raycast = $SpringArm3D/Base/Camera/RayCast
@onready var json = JSON.new()


func _ready():
	EventManager.raycast = raycast


func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed("toggle_third_person_view"):
		third_person = not third_person

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		spring.rotate_x(deg2rad(event.relative.y * mouse_sensitivity))
		rotate_y(deg2rad(event.relative.x * mouse_sensitivity * -1))

		var camera_rot = spring.rotation
		camera_rot.x = clamp(camera_rot.x, deg2rad(-70), deg2rad(70))
		spring.rotation = camera_rot


func set_third_person(enabled):
	third_person = enabled

	if spring == null:
		await ready

	spring.spring_length = third_person_distance if enabled else 0

	if enabled:
		raycast.target_position.z =\
				RAYCAST_DISTANCE + position.distance_to(spring.position)
		$SpringArm3D/Base/Camera.transform.origin.x =\
				THIRD_PERSON_SHOLDER_DISTANCE
	else:
		raycast.target_position.z = RAYCAST_DISTANCE
		$SpringArm3D/Base/Camera.transform.origin.x = 0

	emit_signal("third_person_changed", enabled)


func add_raycast_exception(object):
	raycast.add_exception(object)
	spring.add_excluded_object(object.get_rid())
