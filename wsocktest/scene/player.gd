extends CharacterBody3D

const PARCEL_SIZE = preload("res://scene/scene.gd").parcel_size

@export var god_mode := false
@export var speed_walk := 5.0
@export var speed_jump := 4.0

# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var height = $CollisionShape3D.shape.height
@onready var camera_rig = $CameraRig
@onready var json = JSON.new()


func _ready():
	$CameraRig.add_raycast_exception(self)


func _physics_process(delta):
	# Fall down.
	if not is_on_floor() and not god_mode:
		motion_velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		motion_velocity.y = speed_jump

	var input_vector = Input.get_vector(
			"walk_left", "walk_right", "walk_down", "walk_up").normalized()

	if input_vector: # Move accordingly to where the camera is pointing.
		var cam_xform = camera_rig.get_global_transform()
		var direction = Vector3()
		direction += -cam_xform.basis.z * input_vector.y
		direction += cam_xform.basis.x * input_vector.x

		motion_velocity.x = direction.x * speed_walk
		motion_velocity.z = direction.z * speed_walk

		move_and_slide()
		report_position()
	elif motion_velocity: # Slow down if not moving anymore.
		motion_velocity.x = move_toward(motion_velocity.x, 0, speed_walk)
		motion_velocity.z = move_toward(motion_velocity.z, 0, speed_walk)

		move_and_slide()
		report_position()


func report_position():
	var rot = transform.basis.get_rotation_quaternion()
	var response = {
		"position": {
			"x": transform.origin.x,
			"y": transform.origin.y,
			"z": transform.origin.z
		},
		"rotation": {
			"x": rot.x,
			"y": rot.y,
			"z": rot.z,
			"w": rot.w
		},
		"playerHeight": height

	}
	Server.send({"type": "ReportPosition", "payload": json.stringify(response)})


func current_scene_id():
	for parcel in Server.parcel_scenes.values():
		var parcel_rect = Rect2(parcel[0].transform.origin.x,
				parcel[0].transform.origin.z, PARCEL_SIZE, PARCEL_SIZE)
		if parcel_rect.has_point(Vector2(transform.origin.x, transform.origin.z)):
			return parcel[0].id


func _on_camera_rig_third_person_changed(enabled):
	$MeshInstance3D.visible = enabled
